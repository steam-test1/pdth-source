CopLogicDisarm = class(CopLogicBase)
function CopLogicDisarm.enter(data, new_logic_name, enter_params)
	CopLogicBase.enter(data, new_logic_name, enter_params)
	data.unit:brain():cancel_all_pathing_searches()
	local old_internal_data = data.internal_data
	local my_data = {
		unit = data.unit
	}
	data.internal_data = my_data
	my_data.ai_visibility_slotmask = managers.slot:get_mask("AI_visibility")
	my_data.detection = tweak_data.character[data.unit:base()._tweak_table].detection.guard
	my_data.enemy_detect_slotmask = managers.slot:get_mask("criminals")
	my_data.arrest_targets = {}
	my_data.rsrv_pos = {}
	if old_internal_data then
		my_data.suspected_enemies = old_internal_data.suspected_enemies or {}
		my_data.detected_enemies = old_internal_data.detected_enemies or {}
		my_data.focus_enemy = old_internal_data.focus_enemy
		my_data.focus_type = "disarm"
		managers.groupai:state():on_disarm_start(data.unit:key(), my_data.focus_enemy.unit:key())
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
	local key_str = tostring(data.unit:key())
	my_data.detection_task_key = "CopLogicDisarm._update_enemy_detection" .. key_str
	CopLogicBase.queue_task(my_data, my_data.detection_task_key, CopLogicDisarm._update_enemy_detection, data)
	if my_data.best_cover or my_data.nearest_cover then
		my_data.cover_update_task_key = "CopLogicDisarm._update_cover" .. key_str
		CopLogicBase.add_delayed_clbk(my_data, my_data.cover_update_task_key, callback(CopLogicTravel, CopLogicTravel, "_update_cover", data), data.t + 1)
	end
	CopLogicTravel.reset_actions(data, my_data, old_internal_data, CopLogicTravel.allowed_transitional_actions)
end
function CopLogicDisarm.exit(data, new_logic_name, enter_params)
	CopLogicBase.exit(data, new_logic_name, enter_params)
	local my_data = data.internal_data
	data.unit:brain():cancel_all_pathing_searches()
	CopLogicBase.cancel_queued_tasks(my_data)
	CopLogicBase.cancel_delayed_clbks(my_data)
	if my_data.best_cover then
		managers.navigation:release_cover(my_data.best_cover[1])
	end
	if my_data.nearest_cover then
		managers.navigation:release_cover(my_data.nearest_cover[1])
	end
	if my_data.focus_enemy and my_data.focus_type == "disarm" then
		managers.groupai:state():on_disarm_end(my_data.focus_enemy.unit:key())
	end
	local rsrv_pos = my_data.rsrv_pos
	if rsrv_pos.path then
		managers.navigation:unreserve_pos(rsrv_pos.path)
		rsrv_pos.path = nil
	end
	if rsrv_pos.move_dest then
		managers.navigation:unreserve_pos(rsrv_pos.move_dest)
		rsrv_pos.move_dest = nil
	end
end
function CopLogicDisarm.update(data)
	local exit_state
	local t = data.t
	local unit = data.unit
	local m_pos = data.m_pos
	local my_data = data.internal_data
	CopLogicDisarm._process_pathing_results(data, my_data)
	if my_data.focus_enemy then
		if my_data.focus_type == "disarm" then
			if not my_data.shooting and not unit:anim_data().reload and not data.unit:movement():chk_action_forbidden("action") then
				CopLogicBase._set_attention_on_unit(data, my_data.focus_enemy.unit)
				local shoot_action = {}
				shoot_action.type = "shoot"
				shoot_action.body_part = 3
				if data.unit:brain():action_request(shoot_action) then
					my_data.shooting = true
				end
			end
			if my_data.advancing then
				local criminal_key = my_data.focus_enemy.unit:key()
				local record = managers.groupai:state():criminal_record(criminal_key)
				local dis = mvector3.distance(my_data.focus_enemy.unit:movement():m_pos(), data.m_pos)
				local enemy_dmg = my_data.focus_enemy.unit:character_damage()
				if dis < 100 and record.status == nil then
					if not unit:anim_data().crouch then
						CopLogicAttack._chk_request_action_crouch(data)
					end
					managers.groupai:state():on_disarm_end(criminal_key)
					my_data.focus_enemy.unit:movement():on_disarmed()
					exit_state = "idle"
					data.unit:sound():say("_m01x_sin", true)
				elseif not my_data.approach_sound and dis > 300 and dis < 700 then
					my_data.approach_sound = true
					data.unit:sound():say("_i03x_sin", true)
				end
			elseif my_data.advance_path then
				if not unit:movement():chk_action_forbidden("walk") then
					local new_action_data = {
						type = "walk",
						nav_path = my_data.advance_path,
						variant = "run",
						body_part = 2
					}
					my_data.advance_path = nil
					my_data.advancing = unit:brain():action_request(new_action_data)
					if my_data.advancing and my_data.rsrv_pos.stand then
						managers.navigation:unreserve_pos(my_data.rsrv_pos.stand)
						my_data.rsrv_pos.stand = nil
					end
				end
			elseif my_data.processing_path then
				CopLogicDisarm._process_pathing_results(data, my_data)
			else
				my_data.path_search_id = tostring(unit:key()) .. "disarm"
				my_data.processing_path = true
				unit:brain():search_for_path_to_unit(my_data.path_search_id, my_data.focus_enemy.unit)
			end
		else
			exit_state = my_data.focus_type == "assault" and "attack" or my_data.focus_type
		end
	else
		exit_state = "idle"
	end
	if exit_state then
		CopLogicBase._reset_attention(data)
		if my_data.shooting then
			local new_action = {type = "idle", body_part = 3}
			data.unit:brain():action_request(new_action)
		end
		CopLogicBase._exit(data.unit, exit_state)
	end
end
function CopLogicDisarm._process_pathing_results(data, my_data)
	if data.pathing_results then
		for path_id, path in pairs(data.pathing_results) do
			if path_id == my_data.path_search_id then
				if path ~= "failed" then
					my_data.advance_path = path
				else
					print("CopLogicDisarm advance path failed")
				end
				my_data.processing_path = nil
				my_data.path_search_id = nil
			end
		end
		data.pathing_results = nil
	end
end
function CopLogicDisarm._update_enemy_detection(data)
	managers.groupai:state():on_unit_detection_updated(data.unit)
	local my_data = data.internal_data
	local delay = CopLogicAttack._detect_enemies(data, my_data)
	local focus_enemy, focus_enemy_key, focus_type
	local enemies = my_data.detected_enemies
	local my_pos = data.m_pos
	for key, enemy_data in pairs(enemies) do
		local reaction = CopLogicDisarm._chk_reaction_to_criminal(data, key, enemy_data)
		if reaction == "assault" then
			if enemy_data.verified then
				focus_enemy = enemy_data
				focus_type = reaction
				focus_enemy_key = key
			else
				elseif reaction then
					focus_enemy = enemy_data
					focus_type = reaction
					focus_enemy_key = key
				end
			end
	end
	if focus_enemy then
		if my_data.focus_enemy then
			if my_data.focus_enemy.unit:key() ~= focus_enemy_key then
				managers.groupai:state():on_disarm_end(my_data.focus_enemy.unit:key())
				managers.groupai:state():on_enemy_disengaging(data.unit, my_data.focus_enemy.unit:key())
				managers.groupai:state():on_enemy_engaging(data.unit, focus_enemy.unit:key())
			elseif focus_type ~= "disarm" then
				managers.groupai:state():on_disarm_end(my_data.focus_enemy.unit:key())
			end
		else
			managers.groupai:state():on_enemy_engaging(data.unit, focus_enemy_key)
		end
	elseif my_data.focus_enemy then
		managers.groupai:state():on_disarm_end(my_data.focus_enemy.unit:key())
		managers.groupai:state():on_enemy_disengaging(data.unit, my_data.focus_enemy.unit:key())
	end
	my_data.focus_enemy = focus_enemy
	my_data.focus_type = focus_type
	if focus_type ~= "disarm" then
		if focus_type == "assault" and focus_enemy.verified and data.t - managers.groupai:state():criminal_record(focus_enemy_key).det_t > 15 then
			data.unit:sound():say("_c01x_plu", true)
		end
		CopLogicBase._exit(data.unit, focus_type == "assault" and "attack" or focus_type or "idle")
	else
		CopLogicBase.queue_task(my_data, my_data.detection_task_key, CopLogicDisarm._update_enemy_detection, data, data.t + delay)
	end
	CopLogicBase._report_detections(enemies)
end
function CopLogicDisarm._chk_reaction_to_criminal(data, key_criminal, criminal_data)
	local u_criminal = criminal_data.unit
	local visible = criminal_data.verified
	local reaction
	local record = managers.groupai:state():criminal_record(key_criminal)
	local assault_mode = managers.groupai:state():get_assault_mode()
	if record.status == "disabled" then
		if record.assault_t - record.disabled_t > 0.6 and (record.engaged_force < 5 or CopLogicIdle._am_i_important_to_player(record, data.key)) then
			return "assault"
		end
	elseif record.is_deployable or data.t < record.arrest_timeout then
		reaction = "assault"
	elseif record.being_arrested then
		if record.being_disarmed == data.unit:key() then
			reaction = "disarm"
		end
	elseif not assault_mode and record.engaged_force == 0 and data.t - record.assault_t > 10 then
		local dis = mvector3.distance(u_criminal:movement():m_pos(), data.m_pos)
		if visible and dis < 2000 then
			reaction = "arrest"
		end
	else
		local criminal_fwd = u_criminal:movement():m_head_rot():y()
		local criminal_vec = u_criminal:movement():m_pos() - data.m_pos
		mvector3.normalize(criminal_vec)
		local criminal_look_dot = mvector3.dot(criminal_vec, criminal_fwd)
		if not assault_mode and criminal_look_dot > -0.2 then
			local dis = mvector3.distance(u_criminal:movement():m_pos(), data.m_pos)
			if visible and dis < 2000 then
				reaction = "arrest"
			end
		else
			reaction = "assault"
		end
	end
	return reaction
end
function CopLogicDisarm.action_complete_clbk(data, action)
	local my_data = data.internal_data
	local action_type = action:type()
	if action_type == "walk" then
		my_data.advancing = nil
	elseif action_type == "shoot" then
		my_data.shooting = nil
	elseif action_type == "turn" then
		my_data.turning = nil
	end
end
function CopLogicDisarm.damage_clbk(data, damage_info)
	CopLogicIdle.damage_clbk(data, damage_info)
end
function CopLogicDisarm.death_clbk(data, damage_info)
	local my_data = data.internal_data
	if my_data.focus_enemy then
		managers.groupai:state():on_enemy_disengaging(data.unit, my_data.focus_enemy.unit:key())
		if my_data.focus_type == "disarm" then
			managers.groupai:state():on_disarm_end(my_data.focus_enemy.unit:key())
		end
		my_data.focus_enemy = nil
	end
end
function CopLogicDisarm.can_deactivate(data)
	return false
end
function CopLogicDisarm.on_detected_enemy_destroyed(data, enemy_unit)
	CopLogicAttack.on_detected_enemy_destroyed(data, enemy_unit)
end
function CopLogicDisarm.on_criminal_neutralized(data, criminal_key)
	CopLogicIdle.on_criminal_neutralized(data, criminal_key)
	local my_data = data.internal_data
	if my_data.focus_enemy and my_data.focus_enemy.unit:key() == criminal_key then
		managers.groupai:state():on_enemy_disengaging(data.unit, criminal_key)
		if my_data.focus_type == "disarm" then
			managers.groupai:state():on_disarm_end(criminal_key)
		end
		my_data.focus_type = nil
		my_data.focus_enemy = nil
	end
end
function CopLogicDisarm.on_alert(...)
	CopLogicIdle.on_alert(...)
end
function CopLogicDisarm.is_available_for_assignment(data)
	return false
end
function CopLogicDisarm.on_intimidated(data, amount, aggressor_unit)
	CopLogicIdle.on_intimidated(data, amount, aggressor_unit)
end
function CopLogicDisarm.on_new_objective(data, old_objective)
	CopLogicIdle.on_new_objective(data, old_objective)
end
function CopLogicDisarm._get_all_paths(data)
	return {
		advance_path = data.internal_data.advance_path
	}
end
function CopLogicDisarm._set_verified_paths(data, verified_paths)
	data.internal_data.advance_path = verified_paths.advance_path
end
