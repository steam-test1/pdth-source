CopLogicSniper = class(CopLogicBase)
function CopLogicSniper.enter(data, new_logic_name, enter_params)
	CopLogicBase.enter(data, new_logic_name, enter_params)
	local objective = data.objective
	data.unit:brain():cancel_all_pathing_searches()
	local old_internal_data = data.internal_data
	local my_data = {
		unit = data.unit
	}
	my_data.detection = tweak_data.character[data.unit:base()._tweak_table].detection.recon
	my_data.enemy_detect_slotmask = managers.slot:get_mask("criminals")
	my_data.ai_visibility_slotmask = managers.slot:get_mask("AI_visibility")
	if old_internal_data then
		my_data.suspected_enemies = old_internal_data.suspected_enemies or {}
		my_data.detected_enemies = old_internal_data.detected_enemies or {}
		if old_internal_data.focus_enemy then
			managers.groupai:state():on_enemy_disengaging(data.unit, old_internal_data.focus_enemy.unit:key())
		end
		my_data.rsrv_pos = old_internal_data.rsrv_pos
		if old_internal_data.nearest_cover then
			my_data.nearest_cover = old_internal_data.nearest_cover
			managers.navigation:reserve_cover(my_data.nearest_cover[1], data.pos_rsrv_id)
		end
		if old_internal_data.best_cover then
			my_data.best_cover = old_internal_data.best_cover
			managers.navigation:reserve_cover(my_data.best_cover[1], data.pos_rsrv_id)
		end
	else
		my_data.suspected_enemies = {}
		my_data.detected_enemies = {}
	end
	data.internal_data = my_data
	my_data.rsrv_pos = my_data.rsrv_pos or {}
	if not my_data.rsrv_pos.stand then
		local pos_rsrv = {
			position = mvector3.copy(data.m_pos),
			radius = 100,
			filter = data.pos_rsrv_id
		}
		my_data.rsrv_pos.stand = pos_rsrv
		managers.navigation:add_pos_reservation(pos_rsrv)
	end
	local key_str = tostring(data.unit:key())
	my_data.detection_task_key = "CopLogicSniper._update_enemy_detection" .. key_str
	CopLogicBase.queue_task(my_data, my_data.detection_task_key, CopLogicSniper._update_enemy_detection, data)
	CopLogicTravel.reset_actions(data, my_data, old_internal_data, CopLogicTravel.allowed_transitional_actions)
	CopLogicBase._reset_attention(data)
	if objective then
		my_data.interrupt_on = objective.interrupt_on
		my_data.wanted_stance = objective.stance
		my_data.wanted_pose = objective.pose
		my_data.attitude = objective.attitude
	end
end
function CopLogicSniper.exit(data, new_logic_name, enter_params)
	CopLogicBase.exit(data, new_logic_name, enter_params)
	local my_data = data.internal_data
	data.unit:brain():cancel_all_pathing_searches()
	CopLogicBase.cancel_queued_tasks(my_data)
	if my_data.nearest_cover then
		managers.navigation:release_cover(my_data.nearest_cover[1])
	end
	if my_data.best_cover then
		managers.navigation:release_cover(my_data.best_cover[1])
	end
end
function CopLogicSniper._update_enemy_detection(data)
	managers.groupai:state():on_unit_detection_updated(data.unit)
	data.t = TimerManager:game():time()
	local my_data = data.internal_data
	local delay = CopLogicAttack._detect_enemies(data, my_data)
	local enemies = my_data.detected_enemies
	local focus_enemy, focus_type, focus_enemy_key
	local target = CopLogicAttack._get_priority_enemy(data, enemies, CopLogicSniper._chk_reaction_to_criminal)
	if target then
		focus_enemy = target.enemy_data
		focus_type = target.reaction
		focus_enemy_key = target.key
	end
	if focus_enemy then
		managers.groupai:state():on_enemy_engaging(data.unit, focus_enemy.unit:key())
		my_data.focus_enemy = focus_enemy
		my_data.focus_type = focus_type
		local exit_state
		local interrupt = my_data.interrupt_on
		if interrupt == "contact" then
			exit_state = "attack"
		elseif interrupt == "obstructed" and focus_enemy.verified_dis < 500 then
			exit_state = "attack"
		end
		if exit_state then
			if data.objective then
				managers.groupai:state():on_objective_failed(data.unit, data.objective)
			else
				CopLogicBase._exit(data.unit, exit_state)
			end
			CopLogicBase._report_detections(my_data.detected_enemies)
			return
		end
	end
	CopLogicSniper._upd_aim(data, my_data)
	if data.important then
		delay = 0
	else
		delay = 0.5 + delay * 1.5
	end
	CopLogicBase.queue_task(my_data, my_data.detection_task_key, CopLogicSniper._update_enemy_detection, data, data.t + delay)
	CopLogicBase._report_detections(my_data.detected_enemies)
end
function CopLogicSniper._chk_stand_visibility(my_pos, target_pos, slotmask)
	local ray_from = my_pos:with_z(my_pos.z + 150)
	local ray_to = target_pos
	local ray = World:raycast("ray", ray_from, ray_to, "slot_mask", slotmask, "ray_type", "ai_vision")
	return ray
end
function CopLogicSniper._chk_crouch_visibility(my_pos, target_pos, slotmask)
	local ray_from = my_pos:with_z(my_pos.z + 50)
	local ray_to = target_pos
	local ray = World:raycast("ray", ray_from, ray_to, "slot_mask", slotmask, "ray_type", "ai_vision")
	return ray
end
function CopLogicSniper.action_complete_clbk(data, action)
	local action_type = action:type()
	local my_data = data.internal_data
	if action_type == "turn" then
		my_data.turning = nil
	elseif action_type == "shoot" then
		my_data.shooting = nil
	elseif action_type == "walk" then
		my_data.advacing = nil
		if action.expired then
			my_data.reposition = nil
		end
	elseif action_type == "hurt" and (action:body_part() == 1 or action:body_part() == 2) and data.objective and data.objective.pos then
		my_data.reposition = true
	end
end
function CopLogicSniper.damage_clbk(data, damage_info)
	CopLogicIdle.damage_clbk(data, damage_info)
end
function CopLogicSniper.death_clbk(data, damage_info)
	CopLogicAttack.death_clbk(data, damage_info)
end
function CopLogicSniper.can_deactivate(data)
	return false
end
function CopLogicSniper.on_detected_enemy_destroyed(data, enemy_unit)
	CopLogicAttack.on_detected_enemy_destroyed(data, enemy_unit)
end
function CopLogicSniper.on_criminal_neutralized(data, criminal_key)
	CopLogicAttack.on_criminal_neutralized(data, criminal_key)
end
function CopLogicSniper.is_available_for_assignment(data)
	if not data.internal_data.interrupt_on then
		return
	end
	return CopLogicAttack.is_available_for_assignment(data)
end
function CopLogicSniper.on_alert(data, alert_data)
	local enemy = alert_data[5] or alert_data[4]
	local my_data = data.internal_data
	local enemy_key = enemy:key()
	if managers.groupai:state():criminal_record(enemy_key) then
		local enemy_data = my_data.detected_enemies[enemy_key]
		local t = TimerManager:game():time()
		if enemy_data then
			enemy_data.verified_pos = mvector3.copy(enemy:movement():m_stand_pos())
			enemy_data.verified_dis = mvector3.distance(enemy_data.verified_pos, data.unit:movement():m_stand_pos())
			enemy_data.alert_t = t
		else
			local enemy_data = CopLogicAttack._create_detected_enemy_data(data, enemy)
			enemy_data.alert_t = t
			my_data.detected_enemies[enemy_key] = enemy_data
			my_data.suspected_enemies[enemy_key] = nil
		end
		my_data.alert_t = t
		managers.groupai:state():criminal_spotted(enemy)
		managers.groupai:state():report_aggression(enemy)
	end
end
function CopLogicSniper.on_intimidated(data, amount, aggressor_unit)
	local surrender = CopLogicIdle.on_intimidated(data, amount, aggressor_unit)
	if surrender and data.objective then
		managers.groupai:state():on_objective_failed(data.unit, data.objective)
	end
end
function CopLogicSniper.on_new_objective(data, old_objective)
	CopLogicIdle.on_new_objective(data, old_objective)
end
function CopLogicSniper._upd_aim(data, my_data)
	local shoot, aim
	local focus_enemy = my_data.focus_enemy
	if focus_enemy then
		if focus_enemy.verified then
			shoot = true
		elseif my_data.wanted_stance == "cbt" then
			aim = true
		elseif focus_enemy.verified_t and data.t - focus_enemy.verified_t < 20 then
			aim = true
		end
		if aim and not shoot and my_data.shooting and focus_enemy.verified_t and data.t - focus_enemy.verified_t < 2 then
			shoot = true
		end
	end
	local action_taken = my_data.turning or data.unit:movement():chk_action_forbidden("walk")
	if not action_taken then
		local anim_data = data.unit:anim_data()
		if anim_data.reload and not anim_data.crouch and data.char_tweak.allow_crouch then
			action_taken = CopLogicAttack._chk_request_action_crouch(data)
		end
		if action_taken then
		elseif my_data.attitude == "engage" then
			if focus_enemy then
				if not CopLogicAttack._chk_request_action_turn_to_enemy(data, my_data, data.m_pos, focus_enemy.verified_pos or focus_enemy.m_head_pos) and not focus_enemy.verified and not anim_data.reload then
					if anim_data.crouch then
						if not data.char_tweak.no_stand and not CopLogicSniper._chk_stand_visibility(data.m_pos, focus_enemy.unit:movement():m_detect_pos(), my_data.ai_visibility_slotmask) then
							CopLogicAttack._chk_request_action_stand(data)
						end
					elseif data.char_tweak.allow_crouch and not CopLogicSniper._chk_crouch_visibility(data.m_pos, focus_enemy.unit:movement():m_detect_pos(), my_data.ai_visibility_slotmask) then
						CopLogicAttack._chk_request_action_crouch(data)
					end
				end
			elseif my_data.wanted_pose and not anim_data.reload then
				if my_data.wanted_pose == "crouch" then
					if not anim_data.crouch and data.char_tweak.allow_crouch then
						action_taken = CopLogicAttack._chk_request_action_crouch(data)
					end
				elseif not anim_data.stand and not data.char_tweak.no_stand then
					action_taken = CopLogicAttack._chk_request_action_stand(data)
				end
			end
		elseif focus_enemy then
			if not CopLogicAttack._chk_request_action_turn_to_enemy(data, my_data, data.m_pos, focus_enemy.verified_pos or focus_enemy.m_head_pos) and focus_enemy.verified and anim_data.stand and data.char_tweak.allow_crouch and CopLogicSniper._chk_crouch_visibility(data.m_pos, focus_enemy.unit:movement():m_detect_pos(), my_data.ai_visibility_slotmask) then
				CopLogicAttack._chk_request_action_crouch(data)
			end
		elseif my_data.wanted_pose and not anim_data.reload then
			if my_data.wanted_pose == "crouch" then
				if not anim_data.crouch and data.char_tweak.allow_crouch then
					action_taken = CopLogicAttack._chk_request_action_crouch(data)
				end
			elseif not anim_data.stand and not data.char_tweak.no_stand then
				action_taken = CopLogicAttack._chk_request_action_stand(data)
			end
		end
	end
	if not action_taken and not my_data.advancing and my_data.reposition then
		local objective = data.objective
		if objective and objective.pos then
			my_data.advance_path = {
				mvector3.copy(data.m_pos),
				mvector3.copy(objective.pos)
			}
			if CopLogicTravel._chk_request_action_walk_to_advance_pos(data, my_data, objective.haste or "walk", objective.rot) then
				action_taken = true
			end
		else
			my_data.reposition = nil
		end
	end
	if aim or shoot then
		if focus_enemy.verified then
			if my_data.attention_unit ~= focus_enemy.unit:key() then
				CopLogicBase._set_attention_on_unit(data, focus_enemy.unit)
				my_data.attention_unit = focus_enemy.unit:key()
			end
		elseif my_data.attention_unit ~= focus_enemy.verified_pos then
			CopLogicBase._set_attention_on_pos(data, mvector3.copy(focus_enemy.verified_pos))
			my_data.attention_unit = mvector3.copy(focus_enemy.verified_pos)
		end
		if not my_data.shooting and not data.unit:anim_data().reload and not data.unit:movement():chk_action_forbidden("action") then
			local shoot_action = {type = "shoot", body_part = 3}
			if data.unit:brain():action_request(shoot_action) then
				my_data.shooting = true
			end
		end
	else
		if my_data.shooting then
			local new_action
			if data.unit:anim_data().reload then
				new_action = {type = "reload", body_part = 3}
			else
				new_action = {type = "idle", body_part = 3}
			end
			data.unit:brain():action_request(new_action)
		end
		if my_data.attention_unit then
			CopLogicBase._reset_attention(data)
			my_data.attention_unit = nil
		end
	end
	CopLogicAttack.aim_allow_fire(shoot, aim, data, my_data)
end
function CopLogicSniper._chk_reaction_to_criminal(data, key_criminal, criminal_data, stationary)
	local record = managers.groupai:state():criminal_record(key_criminal)
	if record.is_deployable or data.t < record.arrest_timeout then
		return "assault"
	end
	if record.status == "disabled" then
		if record.assault_t - record.disabled_t > 0.6 then
			return "assault"
		end
	elseif record.being_arrested then
	else
		return "assault"
	end
end
