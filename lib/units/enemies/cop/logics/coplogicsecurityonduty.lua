CopLogicSecurityOnDuty = class(CopLogicIdle)
function CopLogicSecurityOnDuty.enter(data, new_logic_name, enter_params)
	CopLogicBase.enter(data, new_logic_name, enter_params)
	local my_data = {
		unit = data.unit
	}
	my_data.detection = tweak_data.character[data.unit:base()._tweak_table].detection.idle
	my_data.suspicious = tweak_data.character[data.unit:base()._tweak_table].suspicious
	my_data.enemy_detect_slotmask = managers.slot:get_mask("criminals")
	my_data.curious_slotmask = managers.slot:get_mask("harmless_player_criminals")
	my_data.ai_visibility_slotmask = managers.slot:get_mask("AI_visibility")
	my_data.rsrv_pos = {}
	local old_internal_data = data.internal_data
	if old_internal_data then
		my_data.suspected_enemies = old_internal_data.suspected_enemies or {}
		my_data.detected_enemies = old_internal_data.detected_enemies or {}
		my_data.rsrv_pos = old_internal_data.rsrv_pos or my_data.rsrv_pos
	else
		my_data.suspected_enemies = {}
		my_data.detected_enemies = {}
	end
	data.internal_data = my_data
	if not my_data.rsrv_pos.stand then
		local pos_rsrv = {
			position = mvector3.copy(data.m_pos),
			radius = 200,
			filter = data.pos_rsrv_id
		}
		my_data.rsrv_pos.stand = pos_rsrv
		managers.navigation:add_pos_reservation(pos_rsrv)
	end
	local key_str = tostring(data.unit:key())
	my_data.detection_task_key = "CopLogicSecurityOnDuty._update_enemy_detection" .. key_str
	CopLogicBase.queue_task(my_data, my_data.detection_task_key, CopLogicSecurityOnDuty._update_enemy_detection, data, 3 + math.random() * 2)
	local entry_action
	if enter_params and enter_params.action then
		entry_action = data.unit:brain():action_request(enter_params.action)
		if enter_params.action.type == "act" then
			my_data.acting = true
		end
	end
	if not entry_action then
		CopLogicTravel.reset_actions(data, my_data, old_internal_data, CopLogicTravel.allowed_transitional_actions)
	else
		data.unit:movement():set_allow_fire(false)
	end
	my_data.original_fwd = data.unit:rotation():y()
	my_data.fwd_offset = nil
	CopLogicBase._reset_attention(data)
	data.unit:brain():set_update_enabled_state(false)
end
function CopLogicSecurityOnDuty.exit(data, new_logic_name, enter_params)
	CopLogicBase.exit(data, new_logic_name, enter_params)
	local my_data = data.internal_data
	CopLogicBase.cancel_queued_tasks(my_data)
	local rsrv_pos = my_data.rsrv_pos
	if rsrv_pos.move_dest then
		managers.navigation:unreserve_pos(rsrv_pos.move_dest)
		rsrv_pos.move_dest = nil
	end
	data.unit:brain():set_update_enabled_state(true)
end
function CopLogicSecurityOnDuty._update_enemy_detection(data)
	managers.groupai:state():on_unit_detection_updated(data.unit)
	data.t = TimerManager:game():time()
	local my_data = data.internal_data
	local focus_enemy, focus_type
	local delay = 1
	if not my_data.acting then
		delay = CopLogicAttack._detect_enemies(data, my_data)
		local enemies = my_data.detected_enemies
		CopLogicSecurityOnDuty._react_to_suspects(data, my_data)
		for key, enemy_data in pairs(enemies) do
			local reaction = CopLogicIdle._chk_reaction_to_criminal(data, key, enemy_data)
			if reaction then
				focus_enemy = enemy_data
				focus_type = reaction
			else
			end
		end
		if focus_enemy then
			managers.groupai:state():on_enemy_engaging(data.unit, focus_enemy.unit:key())
			my_data.focus_enemy = focus_enemy
			my_data.focus_type = focus_type
		end
	end
	if focus_enemy then
		managers.groupai:state():on_objective_failed(data.unit, data.objective)
	else
		CopLogicBase.queue_task(my_data, my_data.detection_task_key, CopLogicSecurityOnDuty._update_enemy_detection, data, data.t + delay)
	end
	CopLogicBase._report_detections(my_data.detected_enemies)
end
function CopLogicSecurityOnDuty._react_to_suspects(data, my_data)
	if my_data.turning or data.unit:movement():chk_action_forbidden("walk") then
		return
	end
	local unit = data.unit
	local my_pos = data.unit:movement():m_head_pos()
	local suspects = World:find_units_quick("sphere", my_pos, 500, my_data.curious_slotmask)
	local turn_dis = 250
	local turn_spin_neg = -70
	local turn_spin_pos = 70
	local closest_dis, closest_suspect_unit, closest_suspect_key, closest_suspect_spin
	for _, suspect_unit in ipairs(suspects) do
		local suspect_pos = suspect_unit:movement():m_head_pos()
		local visibile = not World:raycast("ray", my_pos, suspect_pos, "slot_mask", my_data.ai_visibility_slotmask, "ray_type", "ai_vision")
		if visibile then
			local suspect_vec = suspect_pos - my_pos
			local suspect_dis = mvector3.normalize(suspect_vec)
			local suspect_spin = suspect_vec:to_polar_with_reference(my_data.original_fwd, math.UP).spin
			if (turn_spin_pos > suspect_spin and turn_spin_neg < suspect_spin or suspect_dis < 250) and (not closest_dis or closest_dis > suspect_dis) then
				closest_suspect_unit = suspect_unit
				closest_suspect_key = suspect_unit:key()
				closest_suspect_spin = suspect_spin
				closest_dis = suspect_dis
			end
		end
	end
	if closest_dis then
		if not my_data.attention_unit_key or my_data.attention_unit_key ~= closest_suspect_key then
			CopLogicBase._set_attention_on_unit(data, closest_suspect_unit)
			my_data.attention_unit_key = closest_suspect_key
			my_data.discover_t = nil
			if my_data.suspicious then
				local member = managers.network:game():member_from_unit(closest_suspect_unit)
				if member then
					if member:peer():id() == 1 then
						managers.hint:show_hint("hint_guard_notice")
					else
						managers.network:session():send_to_peer(member:peer(), "sync_show_hint", "hint_guard_notice")
					end
				end
			end
		end
		local suspect_spin = closest_suspect_unit:movement():m_pos() - data.m_pos:to_polar_with_reference(data.unit:movement():m_rot():y(), math.UP).spin
		if turn_spin_pos < suspect_spin or turn_spin_neg > suspect_spin then
			CopLogicSecurityOnDuty._turn_by_spin(data, my_data, suspect_spin)
			my_data.fwd_offset = true
		elseif closest_dis < 150 then
			if my_data.discover_t then
				if my_data.suspicious and data.t > my_data.discover_t then
					local enemy_data = CopLogicAttack._create_detected_enemy_data(data, closest_suspect_unit)
					enemy_data.verified = true
					enemy_data.verified_t = data.t
					my_data.detected_enemies[closest_suspect_key] = enemy_data
					closest_suspect_unit:movement():on_discovered()
					managers.groupai:state():criminal_spotted(closest_suspect_unit)
				end
			else
				my_data.discover_t = data.t + 2
			end
		end
	else
		if my_data.fwd_offset then
			my_data.fwd_offset = nil
			local return_spin = my_data.original_fwd:to_polar_with_reference(data.unit:movement():m_rot():y(), math.UP).spin
			CopLogicSecurityOnDuty._turn_by_spin(data, my_data, return_spin)
		end
		if my_data.attention_unit_key then
			CopLogicBase._reset_attention(data)
			my_data.attention_unit_key = nil
			my_data.discover_t = nil
		end
	end
end
function CopLogicSecurityOnDuty._turn_by_spin(data, my_data, spin)
	local new_action_data = {
		type = "turn",
		body_part = 2,
		angle = spin
	}
	if data.unit:brain():action_request(new_action_data) then
		my_data.turning = spin
		return true
	end
end
