CivilianLogicIdle = class(CopLogicBase)
function CivilianLogicIdle.enter(data, new_logic_name, enter_params)
	CopLogicBase.enter(data, new_logic_name, enter_params)
	local my_data = {
		unit = data.unit
	}
	my_data.ai_visibility_slotmask = managers.slot:get_mask("AI_visibility")
	my_data.rsrv_pos = {}
	local old_internal_data = data.internal_data
	if old_internal_data then
		my_data.suspected_enemies = old_internal_data.suspected_enemies or {}
		my_data.detected_enemies = old_internal_data.detected_enemies or {}
		my_data.has_outline = old_internal_data.has_outline
		my_data.been_outlined = old_internal_data.been_outlined
		my_data.rsrv_pos = old_internal_data.rsrv_pos or my_data.rsrv_pos
	else
		my_data.suspected_enemies = {}
		my_data.detected_enemies = {}
	end
	data.internal_data = my_data
	if not my_data.rsrv_pos.stand then
		local pos_rsrv = {
			position = mvector3.copy(data.m_pos),
			radius = 45,
			filter = data.pos_rsrv_id
		}
		my_data.rsrv_pos.stand = pos_rsrv
		managers.navigation:add_pos_reservation(pos_rsrv)
	end
	CopLogicBase._reset_attention(data)
	data.unit:brain():set_update_enabled_state(false)
	local objective = data.objective
	if objective and objective.action and data.unit:brain():action_request(objective.action) and objective.action.type == "act" then
		my_data.acting = true
		if objective.action_start_clbk then
			objective.action_start_clbk(data.unit)
		end
	end
	if my_data ~= data.internal_data then
		return
	end
	my_data.tmp_vec3 = Vector3()
	local key_str = tostring(data.key)
	my_data.detection_task_key = "CivilianLogicIdle._upd_detection" .. key_str
	CopLogicBase.queue_task(my_data, my_data.detection_task_key, CivilianLogicIdle._upd_detection, data, data.t + 5)
	if not my_data.been_outlined and tweak_data.character[data.unit:base()._tweak_table].outline_on_discover then
		my_data.outline_detection_task_key = "CivilianLogicIdle._upd_outline_detection" .. tostring(data.key)
		CopLogicBase.queue_task(my_data, my_data.outline_detection_task_key, CivilianLogicIdle._upd_outline_detection, data, data.t + 2)
	end
	managers.groupai:state():register_fleeing_civilian(data.key, data.unit)
end
function CivilianLogicIdle.exit(data, new_logic_name, enter_params)
	CopLogicBase.exit(data, new_logic_name, enter_params)
	local my_data = data.internal_data
	my_data.delayed_alert_id = nil
	if my_data.idle_attention and alive(my_data.idle_attention.unit) then
		CopLogicBase._reset_attention(data)
	end
	CopLogicBase.cancel_delayed_clbks(my_data)
	CopLogicBase.cancel_queued_tasks(my_data)
	managers.groupai:state():unregister_fleeing_civilian(data.key)
end
function CivilianLogicIdle._upd_outline_detection(data)
	local my_data = data.internal_data
	if my_data.been_outlined or my_data.has_outline then
		return
	end
	local t = TimerManager:game():time()
	local visibility_slotmask = managers.slot:get_mask("AI_visibility")
	local seen = false
	local seeing_unit
	local my_tracker = data.unit:movement():nav_tracker()
	local chk_vis_func = my_tracker.check_visibility
	for e_key, record in pairs(managers.groupai:state():all_criminals()) do
		if chk_vis_func(my_tracker, record.tracker) then
			local enemy_pos = record.m_det_pos
			local my_pos = data.unit:movement():m_head_pos()
			if mvector3.distance_sq(enemy_pos, my_pos) < 1440000 then
				local not_hit = World:raycast("ray", my_pos, enemy_pos, "slot_mask", visibility_slotmask, "ray_type", "ai_vision", "report")
				if not not_hit then
					seen = true
					seeing_unit = record.unit
					break
				end
			end
		end
	end
	if seen then
		CivilianLogicIdle._enable_outline(data)
	else
		CopLogicBase.queue_task(my_data, my_data.outline_detection_task_key, CivilianLogicIdle._upd_outline_detection, data, t + 0.33)
	end
end
function CivilianLogicIdle._enable_outline(data)
	local my_data = data.internal_data
	data.unit:base():set_contour(true)
	my_data.has_outline = true
	my_data.been_outlined = true
	my_data.outline_detection_task_key = nil
end
function CivilianLogicIdle.on_alert(data, alert_data)
	if data.objective and not data.objective.interrupt_on and data.objective.type ~= "free" then
		return
	end
	if managers.groupai:state():whisper_mode() then
		return
	end
	local my_data = data.internal_data
	if not my_data.delayed_alert_id then
		my_data.delayed_alert_id = "alert" .. tostring(data.unit:key())
		CopLogicBase.add_delayed_clbk(my_data, my_data.delayed_alert_id, callback(CivilianLogicIdle, CivilianLogicIdle, "_delayed_alert_clbk", {data = data, alert_data = alert_data}), TimerManager:game():time() + math.random())
	end
end
function CivilianLogicIdle._delayed_alert_clbk(ignore_this, params)
	local data = params.data
	local alert_data = params.alert_data
	local my_data = data.internal_data
	CopLogicBase.on_delayed_clbk(my_data, my_data.delayed_alert_id)
	my_data.delayed_alert_id = nil
	if not alive(data.unit) then
		return
	end
	local logic_params = {alert_data = alert_data}
	CivilianLogicIdle.switch_logic(data, {type = "free", flee_data = logic_params}, "flee", logic_params)
end
function CivilianLogicIdle.switch_logic(data, new_obj, logic, logic_params)
	local objective = data.objective
	local brain = data.unit:brain()
	if objective then
		if objective.type ~= "free" then
			if objective.interrupt_on then
				brain:set_objective(new_obj)
			end
		elseif objective.interrupt_on then
			brain:set_objective(new_obj)
		else
			brain:set_logic(logic, logic_params)
		end
	else
		brain:set_logic(logic, logic_params)
	end
end
function CivilianLogicIdle.on_intimidated(data, amount, aggressor_unit)
	if data.objective and not data.objective.interrupt_on and data.objective.type ~= "free" then
		return
	end
	if not tweak_data.character[data.unit:base()._tweak_table].intimidateable or data.unit:base().unintimidateable or data.unit:anim_data().unintimidateable then
		return
	end
	local logic_params = {amount = amount, aggressor_unit = aggressor_unit}
	CivilianLogicIdle.switch_logic(data, {type = "free", surrender_data = logic_params}, "surrender", logic_params)
end
function CivilianLogicIdle.damage_clbk(data, damage_info)
	if data.objective and not data.objective.interrupt_on and data.objective.type ~= "free" then
		return
	end
	local logic_params = {dmg_info = damage_info}
	CivilianLogicIdle.switch_logic(data, {type = "free", flee_data = logic_params}, "flee", logic_params)
end
function CivilianLogicIdle.on_new_objective(data, old_objective)
	local new_objective = data.objective
	local my_data = data.internal_data
	if new_objective then
		if new_objective.type == "escort" then
			CopLogicBase._exit(data.unit, "escort")
		elseif new_objective.nav_seg and not new_objective.in_place then
			CopLogicBase._exit(data.unit, "travel")
		elseif new_objective.type == "free" and new_objective.flee_data then
			CopLogicBase._exit(data.unit, "flee", new_objective.flee_data)
		elseif new_objective.type == "free" and new_objective.surrender_data then
			CopLogicBase._exit(data.unit, "surrender", new_objective.surrender_data)
		else
			CopLogicBase._exit(data.unit, "idle")
		end
	else
		CopLogicBase._exit(data.unit, "idle")
	end
	if old_objective and old_objective.fail_clbk then
		old_objective.fail_clbk()
	end
end
function CivilianLogicIdle.action_complete_clbk(data, action)
	local my_data = data.internal_data
	if action:type() == "turn" then
		my_data.turning = nil
	elseif action:type() == "act" and my_data.acting and data.objective then
		my_data.acting = nil
		if action:expired() then
			managers.groupai:state():on_civilian_objective_complete(data.unit, data.objective)
		else
			managers.groupai:state():on_civilian_objective_failed(data.unit, data.objective)
		end
	end
end
function CivilianLogicIdle._upd_detection(data)
	local my_data = data.internal_data
	local t = TimerManager:game():time()
	local alert
	local criminals_slotmask = managers.slot:get_mask("criminals")
	local harmless_criminals_slotmask = managers.slot:get_mask("harmless_criminals")
	local visibility_slotmask = managers.slot:get_mask("AI_visibility")
	local criminals = managers.groupai:state():all_criminals()
	local my_tracker = data.unit:movement():nav_tracker()
	local chk_vis_func = my_tracker.check_visibility
	local anim_in_idle_attention = data.unit:anim_data().ik_type
	local idle_attention = my_data.idle_attention
	if idle_attention and (not alive(idle_attention.unit) or not anim_in_idle_attention) then
		idle_attention = nil
		my_data.idle_attention = nil
		CopLogicBase._reset_attention(data)
	end
	for e_key, record in pairs(criminals) do
		local enemy_unit = record.unit
		if enemy_unit:in_slot(criminals_slotmask) then
			if chk_vis_func(my_tracker, record.tracker) then
				local my_pos = data.unit:movement():m_head_pos()
				local enemy_pos = record.m_det_pos
				local my_vec = my_data.tmp_vec3
				mvector3.set(my_vec, my_pos)
				mvector3.subtract(my_vec, enemy_pos)
				local dif_z_abs = math.abs(my_vec.z)
				local dis = mvector3.normalize(my_vec)
				if dis < 700 and dif_z_abs < 300 then
					alert = {
						"voice",
						mvector3.copy(enemy_pos),
						dis,
						enemy_unit
					}
					break
				end
				if dif_z_abs < 300 or math.abs(my_vec.z) < 0.2 then
					local min_dis = 1000
					local max_dis = 10000 + min_dis
					local vis_chance = math.lerp(1, 0.2, math.clamp(dis - min_dis, 0, max_dis) / max_dis)
					if vis_chance > math.random() then
						local vis_ray = World:raycast("ray", my_pos, enemy_pos, "slot_mask", visibility_slotmask, "ray_type", "ai_vision")
						if not vis_ray then
							alert = {
								"voice",
								mvector3.copy(enemy_pos),
								dis,
								enemy_unit
							}
							break
						end
					end
				end
			end
		elseif anim_in_idle_attention and enemy_unit:in_slot(harmless_criminals_slotmask) and chk_vis_func(my_tracker, record.tracker) then
			local my_pos = data.unit:movement():m_head_pos()
			local enemy_pos = record.m_det_pos
			local my_vec = my_data.tmp_vec3
			mvector3.set(my_vec, enemy_pos)
			mvector3.subtract(my_vec, my_pos)
			local dif_z_abs = math.abs(my_vec.z)
			local dis = mvector3.normalize(my_vec)
			local fwd_dot = mvector3.dot(data.unit:movement():m_fwd(), my_vec)
			if dis < 400 and dif_z_abs < 250 and 0.2 < fwd_dot or idle_attention and idle_attention.unit:key() == e_key and dis < 650 and dif_z_abs < 330 and 0.15 < fwd_dot then
				local vis_ray = World:raycast("ray", my_pos, enemy_pos, "slot_mask", visibility_slotmask, "ray_type", "ai_vision")
				if not vis_ray then
					if idle_attention and idle_attention.unit:key() == e_key then
						idle_attention.dis = dis
						idle_attention.verified = true
					elseif not idle_attention or dis < idle_attention.dis * 0.5 then
						idle_attention = idle_attention or {}
						idle_attention.unit = enemy_unit
						idle_attention.dis = dis
						idle_attention.new = true
						idle_attention.verified = nil
					end
				end
			end
		end
	end
	if alert then
		idle_attention = nil
		my_data.idle_attention = nil
		CivilianLogicIdle.on_alert(data, alert)
	elseif idle_attention then
		if idle_attention.new then
			my_data.idle_attention = idle_attention
			idle_attention.new = nil
			data.unit:movement():set_attention({
				unit = idle_attention.unit
			})
		elseif idle_attention.verified then
			idle_attention.verified = nil
		else
			idle_attention = nil
			my_data.idle_attention = nil
			CopLogicBase._reset_attention(data)
		end
	end
	local delay = idle_attention and 1.5 or 5
	CopLogicBase.queue_task(my_data, my_data.detection_task_key, CivilianLogicIdle._upd_detection, data, t + delay)
end
function CivilianLogicIdle.is_available_for_assignment(data, objective)
	return (not data.internal_data.acting or data.unit:anim_data().act_idle) and not data.internal_data.exiting
end
function CivilianLogicIdle.anim_clbk(data, info_type)
	if info_type == "reset_attention" and data.internal_data.idle_attention then
		data.internal_data.idle_attention = nil
		CopLogicBase._reset_attention(data)
	end
end
