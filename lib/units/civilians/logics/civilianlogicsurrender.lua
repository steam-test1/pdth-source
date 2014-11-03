CivilianLogicSurrender = class(CopLogicBase)
function CivilianLogicSurrender.enter(data, new_logic_name, enter_params)
	CopLogicBase.enter(data, new_logic_name, enter_params)
	data.unit:brain():cancel_all_pathing_searches()
	local old_internal_data = data.internal_data
	local my_data = {
		unit = data.unit
	}
	data.internal_data = my_data
	my_data.rsrv_pos = {}
	if old_internal_data then
		my_data.has_outline = old_internal_data.has_outline
		my_data.been_outlined = old_internal_data.been_outlined
		my_data.rsrv_pos = old_internal_data.rsrv_pos or my_data.rsrv_pos
	end
	if data.unit:anim_data().tied then
		managers.groupai:state():on_hostage_state(true, data.key)
		my_data.is_hostage = true
	end
	if data.unit:anim_data().drop then
		data.unit:interaction():set_active(true, true)
	end
	if not data.unit:anim_data().move and managers.groupai:state():rescue_state() then
		CivilianLogicFlee._add_delayed_rescue_SO(data, my_data)
	end
	local scare_max = data.char_tweak.scare_max
	my_data.scare_max = math.lerp(scare_max[1], scare_max[2], math.random())
	local submission_max = data.char_tweak.submission_max
	my_data.submission_max = math.lerp(submission_max[1], submission_max[2], math.random())
	my_data.scare_meter = 0
	my_data.submission_meter = 0
	my_data.last_upd_t = data.t
	my_data.nr_random_screams = 0
	local start_pos = data.unit:brain():panic_pos()
	if not start_pos then
		start_pos = mvector3.copy(data.m_pos)
		data.unit:brain():set_panic_pos(start_pos)
	end
	my_data.start_pos = start_pos
	if not my_data.rsrv_pos.stand then
		local pos_rsrv = {
			position = mvector3.copy(data.m_pos),
			radius = 60,
			filter = data.pos_rsrv_id
		}
		my_data.rsrv_pos.stand = pos_rsrv
		managers.navigation:add_pos_reservation(pos_rsrv)
	end
	data.unit:brain():set_update_enabled_state(false)
	data.unit:movement():set_allow_fire(false)
	managers.groupai:state():add_to_surrendered(data.unit, callback(CivilianLogicSurrender, CivilianLogicSurrender, "queued_update", data))
	my_data.surrender_clbk_registered = true
	if enter_params and enter_params.aggressor_unit then
		if not enter_params.initial_act then
			CivilianLogicSurrender.on_intimidated(data, enter_params.amount, enter_params.aggressor_unit, true)
		else
			if enter_params.initial_act == "halt" then
				managers.groupai:state():register_fleeing_civilian(data.key, data.unit)
			end
			CivilianLogicSurrender._do_initial_act(data, enter_params.amount, enter_params.aggressor_unit, enter_params.initial_act)
		end
	end
	if not my_data.been_outlined and tweak_data.character[data.unit:base()._tweak_table].outline_on_discover then
		my_data.outline_detection_task_key = "CivilianLogicIdle._upd_outline_detection" .. tostring(data.key)
		CopLogicBase.queue_task(my_data, my_data.outline_detection_task_key, CivilianLogicIdle._upd_outline_detection, data, data.t + 2)
	end
end
function CivilianLogicSurrender.exit(data, new_logic_name, enter_params)
	CopLogicBase.exit(data, new_logic_name, enter_params)
	local my_data = data.internal_data
	if data.unit:anim_data().tied and new_logic_name ~= "trade" and new_logic_name ~= "inactive" then
		debug_pause_unit(data.unit, "[CivilianLogicSurrender.exit] tied civilian!!!", data.unit, "new_logic_name", new_logic_name)
	end
	CivilianLogicFlee._unregister_rescue_SO(data, my_data)
	managers.groupai:state():unregister_fleeing_civilian(data.key)
	if new_logic_name ~= "inactive" then
		data.unit:base():set_slot(data.unit, 21)
	end
	CopLogicBase.cancel_delayed_clbks(my_data)
	if new_logic_name ~= "trade" and data.unit:interaction() then
		data.unit:interaction():set_active(false, true)
		if my_data.has_outline then
			data.unit:base():set_contour(true)
		end
	end
	if my_data.surrender_clbk_registered then
		managers.groupai:state():remove_from_surrendered(data.unit)
	end
	CopLogicBase.cancel_queued_tasks(my_data)
	if my_data.is_hostage then
		managers.groupai:state():on_hostage_state(false, data.key)
		my_data.is_hostage = nil
	end
	CopLogicBase._reset_attention(data)
end
function CivilianLogicSurrender.queued_update(rubbish, data)
	local my_data = data.internal_data
	CivilianLogicSurrender._update_enemy_detection(data, my_data)
	if my_data.submission_meter == 0 and data.unit:anim_data().drop and not data.unit:anim_data().tied then
		local new_action = {
			type = "act",
			variant = "stand",
			body_part = 1
		}
		data.unit:brain():action_request(new_action)
		my_data.surrender_clbk_registered = false
		CivilianLogicIdle.switch_logic(data, {
			type = "free",
			flee_data = {}
		}, "flee", nil)
		return
	else
		managers.groupai:state():add_to_surrendered(data.unit, callback(CivilianLogicSurrender, CivilianLogicSurrender, "queued_update", data))
	end
	if data.unit:anim_data().act and my_data.rsrv_pos.stand then
		my_data.rsrv_pos.stand.position = mvector3.copy(data.m_pos)
		managers.navigation:move_pos_rsrv(my_data.rsrv_pos.stand)
	end
end
function CivilianLogicSurrender.on_tied(data, aggressor_unit, not_tied)
	local my_data = data.internal_data
	if my_data.is_hostage then
		return
	end
	if not_tied then
		if my_data.has_outline then
			data.unit:base():set_contour(false)
			my_data.has_outline = nil
		end
		data.unit:inventory():destroy_all_items()
		data.unit:interaction():set_active(false, true)
		data.unit:character_damage():drop_pickup()
		data.unit:character_damage():set_pickup(nil)
	else
		local action_data = {
			type = "act",
			body_part = 1,
			variant = "tied"
		}
		local action_res = data.unit:brain():action_request(action_data)
		if action_res then
			if my_data.surrender_clbk_registered then
				my_data.surrender_clbk_registered = nil
				managers.groupai:state():remove_from_surrendered(data.unit)
			end
			managers.groupai:state():on_hostage_state(true, data.key)
			my_data.is_hostage = true
			if my_data.has_outline then
				data.unit:base():set_contour(false)
				my_data.has_outline = nil
			end
			data.unit:inventory():destroy_all_items()
			managers.groupai:state():on_civilian_tied(data.unit:key())
			data.unit:base():set_slot(data.unit, 22)
			data.unit:interaction():set_active(false, true)
			data.unit:character_damage():drop_pickup()
			data.unit:character_damage():set_pickup(nil)
			if managers.groupai:state():rescue_state() then
				CivilianLogicFlee._add_delayed_rescue_SO(data, my_data)
			end
			if aggressor_unit == managers.player:player_unit() then
				managers.statistics:tied({
					name = data.unit:base()._tweak_table
				})
			else
				aggressor_unit:network():send_to_unit({
					"statistics_tied",
					data.unit:base()._tweak_table
				})
			end
		end
	end
end
function CivilianLogicSurrender._do_initial_act(data, amount, aggressor_unit, initial_act)
	local my_data = data.internal_data
	local adj_sumbission = amount * data.char_tweak.submission_intimidate
	my_data.submission_meter = math.min(my_data.submission_max, my_data.submission_meter + adj_sumbission)
	local adj_scare = amount * data.char_tweak.scare_intimidate
	my_data.scare_meter = math.max(0, my_data.scare_meter + adj_scare)
	local action_data = {
		type = "act",
		body_part = 1,
		variant = initial_act,
		clamp_to_graph = true
	}
	data.unit:brain():action_request(action_data)
end
function CivilianLogicSurrender.action_complete_clbk(data, action)
	local my_data = data.internal_data
	if action:type() == "walk" then
		if action:expired() then
			my_data.rsrv_pos.stand = my_data.rsrv_pos.move_dest
			my_data.rsrv_pos.move_dest = nil
		elseif my_data.rsrv_pos.move_dest then
			if not my_data.rsrv_pos.stand then
				my_data.rsrv_pos.stand = managers.navigation:add_pos_reservation({
					position = mvector3.copy(data.m_pos),
					radius = 45,
					filter = data.pos_rsrv_id
				})
			end
			managers.navigation:unreserve_pos(my_data.rsrv_pos.move_dest)
			my_data.rsrv_pos.move_dest = nil
		end
	end
end
function CivilianLogicSurrender.on_intimidated(data, amount, aggressor_unit, skip_delay)
	if data.unit:anim_data().tied then
		return
	end
	if not tweak_data.character[data.unit:base()._tweak_table].intimidateable or data.unit:base().unintimidateable or data.unit:anim_data().unintimidateable then
		return
	end
	local my_data = data.internal_data
	if not my_data.delayed_intimidate_id or not my_data.delayed_clbks or not my_data.delayed_clbks[my_data.delayed_intimidate_id] then
		if skip_delay then
			CivilianLogicSurrender._delayed_intimidate_clbk(nil, {
				data,
				amount,
				aggressor_unit
			})
		else
			my_data.delayed_intimidate_id = "intimidate" .. tostring(data.unit:key())
			local delay = 1 - amount + math.random() * 0.2
			CopLogicBase.add_delayed_clbk(my_data, my_data.delayed_intimidate_id, callback(CivilianLogicSurrender, CivilianLogicSurrender, "_delayed_intimidate_clbk", {
				data,
				amount,
				aggressor_unit
			}), TimerManager:game():time() + delay)
		end
	end
end
function CivilianLogicSurrender._delayed_intimidate_clbk(ignore_this, params)
	local data = params[1]
	local my_data = data.internal_data
	if my_data.delayed_intimidate_id then
		CopLogicBase.on_delayed_clbk(my_data, my_data.delayed_intimidate_id)
		my_data.delayed_intimidate_id = nil
	end
	if data.unit:movement():chk_action_forbidden("walk") then
		return
	end
	local amount = params[2]
	local anim_data = data.unit:anim_data()
	local adj_sumbission = amount * data.char_tweak.submission_intimidate
	my_data.submission_meter = math.min(my_data.submission_max, my_data.submission_meter + adj_sumbission)
	local adj_scare = amount * data.char_tweak.scare_intimidate
	my_data.scare_meter = math.max(0, my_data.scare_meter + adj_scare)
	if anim_data.drop or anim_data.react_enter then
	elseif anim_data.react and not anim_data.react_enter or anim_data.panic or anim_data.halt then
		local action_data = {
			type = "act",
			body_part = 1,
			clamp_to_graph = true,
			variant = anim_data.move and "halt" or "drop"
		}
		local action_res = data.unit:brain():action_request(action_data)
		if action_res and action_data.variant == "drop" then
			managers.groupai:state():unregister_fleeing_civilian(data.key)
			data.unit:interaction():set_active(true, true)
		end
	else
		local action_data = {
			type = "act",
			body_part = 1,
			variant = anim_data.peaceful and "react" or "panic",
			clamp_to_graph = true
		}
		data.unit:brain():action_request(action_data)
		data.unit:sound():say("_a02x_any", true)
		if data.unit:unit_data().mission_element then
			data.unit:unit_data().mission_element:event("panic", data.unit)
		end
	end
end
function CivilianLogicSurrender.on_alert(data, alert_data)
	if managers.groupai:state():whisper_mode() then
		return
	end
	if alert_data[1] == "voice" then
		return
	end
	local anim_data = data.unit:anim_data()
	if anim_data.tied then
		return
	end
	local my_data = data.internal_data
	my_data.scare_meter = math.min(my_data.scare_max, my_data.scare_meter + data.char_tweak.scare_shot)
	if my_data.scare_meter == my_data.scare_max then
		data.unit:sound():say("_a01x_any", true)
		local logic_params = {alert_data = alert_data}
		CivilianLogicIdle.switch_logic(data, {type = "free", flee_data = logic_params}, "flee", logic_params)
	elseif not data.unit:sound():speaking(TimerManager:game():time()) then
		local rand = math.random()
		local alert_dis_sq = mvector3.distance_sq(data.m_pos, alert_data[2])
		local max_scare_dis_sq = 4000000
		if alert_dis_sq < max_scare_dis_sq then
			rand = math.lerp(rand, rand * 2, math.min(alert_dis_sq) / 4000000)
			local scare_mul = (max_scare_dis_sq - alert_dis_sq) / max_scare_dis_sq
			local max_nr_random_screams = 8
			scare_mul = scare_mul * math.lerp(1, 0.3, my_data.nr_random_screams / max_nr_random_screams)
			local chance_voice_1 = 0.3 * scare_mul
			local chance_voice_2 = 0.3 * scare_mul
			if data.char_tweak.female then
				chance_voice_1 = chance_voice_1 * 1.2
				chance_voice_2 = chance_voice_2 * 1.2
			end
			if rand < chance_voice_1 then
				data.unit:sound():say("_a01x_any", true)
				my_data.nr_random_screams = math.min(my_data.nr_random_screams + 1, max_nr_random_screams)
			elseif rand < chance_voice_1 + chance_voice_2 then
				data.unit:sound():say("_a02x_any", true)
				my_data.nr_random_screams = math.min(my_data.nr_random_screams + 1, max_nr_random_screams)
			end
		end
	end
end
function CivilianLogicSurrender._update_enemy_detection(data, my_data)
	local t = TimerManager:game():time()
	local delta_t = t - my_data.last_upd_t
	local my_pos = data.unit:movement():m_head_pos()
	local enemies = managers.groupai:state():all_criminals()
	local visible, closest_dis, closest_enemy
	local my_tracker = data.unit:movement():nav_tracker()
	local chk_vis_func = my_tracker.check_visibility
	for e_key, record in pairs(enemies) do
		if not record.is_deployable and chk_vis_func(my_tracker, record.tracker) then
			local enemy_unit = record.unit
			local enemy_pos = record.m_det_pos
			local my_vec = my_pos - enemy_pos
			local dis = mvector3.normalize(my_vec)
			if dis < 700 then
				visible = true
			end
			if not closest_dis or closest_dis > dis then
				closest_dis = dis
				closest_enemy = enemy_unit
			end
			local look_dir = enemy_unit:movement():m_head_rot():y()
			local enemy_head_pos = enemy_unit:movement():m_head_pos()
			local focus = my_vec:dot(look_dir)
			if focus > 0.65 then
				visible = true
				if focus > 0.8 then
					my_data.submission_meter = math.min(my_data.submission_max, my_data.submission_meter + delta_t)
				end
			end
		end
	end
	local attention = data.unit:movement():attention()
	local attention_unit = attention and attention.unit or nil
	if not attention_unit then
		if closest_enemy and closest_dis < 700 and data.unit:anim_data().ik_type then
			CopLogicBase._set_attention_on_unit(data, closest_enemy)
		end
	elseif mvector3.distance(my_pos, attention_unit:movement():m_head_pos()) > 900 or not data.unit:anim_data().ik_type then
		CopLogicBase._reset_attention(data)
	end
	if not visible then
		my_data.submission_meter = math.max(0, my_data.submission_meter - delta_t)
	end
	my_data.scare_meter = math.max(0, my_data.scare_meter - delta_t)
	my_data.last_upd_t = t
end
function CivilianLogicSurrender.is_available_for_assignment(data, old_objective)
	return not data.unit:anim_data().tied and data.internal_data.submission_meter / data.internal_data.submission_max < 0.95
end
function CivilianLogicSurrender.on_new_objective(data, old_objective)
	CivilianLogicIdle.on_new_objective(data, old_objective)
end
function CivilianLogicSurrender.on_rescue_allowed_state(data, state)
	CivilianLogicFlee.on_rescue_allowed_state(data, state)
end
CivilianLogicSurrender.wants_rescue = CivilianLogicFlee.wants_rescue
