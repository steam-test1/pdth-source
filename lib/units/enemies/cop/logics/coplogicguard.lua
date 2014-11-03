CopLogicGuard = class(CopLogicIdle)
function CopLogicGuard.enter(data, new_logic_name, enter_params)
	CopLogicBase.enter(data, new_logic_name, enter_params)
	data.unit:brain():cancel_all_pathing_searches()
	local objective = data.objective
	local guard_obj = objective.guard_obj
	local my_data = {
		unit = data.unit
	}
	my_data.detection = tweak_data.character[data.unit:base()._tweak_table].detection.guard
	my_data.enemy_detect_slotmask = managers.slot:get_mask("criminals")
	my_data.rsrv_pos = {}
	my_data.ai_visibility_slotmask = managers.slot:get_mask("AI_visibility")
	my_data.guard_obj = guard_obj
	if guard_obj and guard_obj.type == "door" then
		CopLogicAttack._set_attention_on_pos(data, guard_obj.door.center + math.UP * 140)
	else
		CopLogicBase._reset_attention(data)
	end
	if managers.groupai:state():is_area_safe(guard_obj.from_seg) then
		my_data.from_seg_safe = true
	end
	local old_internal_data = data.internal_data
	if old_internal_data then
		my_data.suspected_enemies = old_internal_data.suspected_enemies or {}
		my_data.detected_enemies = old_internal_data.detected_enemies or {}
		my_data.rsrv_pos = old_internal_data.rsrv_pos or my_data.rsrv_pos
		if old_internal_data.best_cover then
			my_data.best_cover = old_internal_data.best_cover
			managers.navigation:reserve_cover(my_data.best_cover[1], data.pos_rsrv_id)
		end
		if old_internal_data.nearest_cover then
			my_data.nearest_cover = old_internal_data.nearest_cover
			managers.navigation:reserve_cover(my_data.nearest_cover[1], data.pos_rsrv_id)
		end
	else
		my_data.suspected_enemies = {}
		my_data.detected_enemies = {}
	end
	my_data.need_turn_check = true
	data.internal_data = my_data
	my_data.detection_task_key = "CopLogicGuard._update_enemy_detection" .. tostring(data.unit:key())
	CopLogicBase.queue_task(my_data, my_data.detection_task_key, CopLogicIdle._update_enemy_detection, data, data.t + 1)
	CopLogicTravel.reset_actions(data, my_data, old_internal_data, CopLogicTravel.allowed_transitional_actions)
end
function CopLogicGuard.update(data)
	local my_data = data.internal_data
	local guard_obj = my_data.guard_obj
	if my_data.focus_enemy then
		local exit_state = my_data.focus_type == "assault" and "attack" or my_data.focus_type or "idle"
		CopLogicBase._exit(data.unit, exit_state)
		return
	end
	if my_data.need_turn_check and not my_data.turning and not data.unit:movement():chk_action_forbidden("walk") then
		my_data.need_turn_check = CopLogicAttack._chk_request_action_turn_to_enemy(data, my_data, data.m_pos, guard_obj.door.center)
	end
	if guard_obj.type == "door" and not my_data.aiming and not my_data.from_seg_safe then
		local shoot_action = {}
		shoot_action.type = "shoot"
		shoot_action.body_part = 3
		CopLogicAttack._set_attention_on_pos(data, guard_obj.door.center + math.UP * 140)
		if data.unit:brain():action_request(shoot_action) then
			my_data.aiming = true
		end
	end
	if my_data.from_seg_safe and not my_data.need_turn_check and not my_data.turning then
		CopLogicBase._exit(data.unit, "idle")
	end
end
function CopLogicGuard.action_complete_clbk(data, action)
	local action_type = action:type()
	if action_type == "shoot" then
		data.internal_data.shooting = nil
	elseif action_type == "turn" then
		data.internal_data.turning = nil
	end
end
function CopLogicGuard.on_new_objective(data, old_objective)
	CopLogicIdle.on_new_objective(data, old_objective)
end
function CopLogicGuard.on_area_safety(data, nav_seg, safe, event)
	local objective = data.objective
	if objective.guard_obj.from_seg == nav_seg then
		local my_data = data.internal_data
		if safe then
			if my_data.need_turn_check or my_data.turning then
				my_data.from_seg_safe = true
			else
				CopLogicBase._exit(data.unit, "idle")
			end
			managers.groupai:state():on_objective_complete(data.unit, objective)
		else
			my_data.from_seg_safe = nil
		end
	elseif nav_seg == data.unit:movement():nav_tracker():nav_segment() then
		if not safe and event.reason == "criminal" then
			local my_data = data.internal_data
			local u_criminal = event.record.unit
			local key_criminal = u_criminal:key()
			local enemy_data = CopLogicAttack._create_detected_enemy_data(data, u_criminal)
			enemy_data.verified = true
			enemy_data.verified_t = data.t
			my_data.detected_enemies[key_criminal] = enemy_data
			my_data.suspected_enemies[key_criminal] = nil
			my_data.focus_enemy = enemy_data
			my_data.focus_type = "assault"
			managers.groupai:state():on_enemy_engaging(data.unit, key_criminal)
			CopLogicBase._exit(data.unit, "attack")
		end
	elseif event.reason == "criminal" then
		local new_occupation = managers.groupai:state():verify_occupation_in_area(objective)
		if new_occupation then
			new_occupation.type = "guard"
			local new_objective = {
				type = "investigate_area",
				nav_seg = objective.nav_seg,
				status = "in_progress",
				guard_obj = new_occupation,
				scan = true
			}
			data.unit:brain():set_objective(new_objective)
		end
	end
end
