CopLogicArrest = class(CopLogicBase)
function CopLogicArrest.enter(data, new_logic_name, enter_params)
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
		if my_data.focus_enemy then
			my_data.arrest_targets[my_data.focus_enemy.unit:key()] = {
				unit = my_data.focus_enemy.unit
			}
			managers.groupai:state():on_arrest_start(data.key, my_data.focus_enemy.unit:key())
		end
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
	my_data.update_task_key = "CopLogicArrest.queued_update" .. key_str
	CopLogicBase.queue_task(my_data, my_data.update_task_key, CopLogicArrest.queued_update, data, data.t)
	if my_data.best_cover or my_data.nearest_cover then
		my_data.cover_update_task_key = "CopLogicArrest._update_cover" .. key_str
		CopLogicBase.queue_task(my_data, my_data.cover_update_task_key, CopLogicArrest._update_cover, data, data.t)
	end
	data.unit:brain():set_update_enabled_state(false)
	CopLogicTravel.reset_actions(data, my_data, old_internal_data, CopLogicTravel.allowed_transitional_actions)
	if not data.char_tweak.no_stand and not data.unit:anim_data().stand then
		CopLogicAttack._chk_request_action_stand(data)
	end
end
function CopLogicArrest.exit(data, new_logic_name, enter_params)
	CopLogicBase.exit(data, new_logic_name, enter_params)
	local my_data = data.internal_data
	data.unit:brain():cancel_all_pathing_searches()
	CopLogicBase.cancel_queued_tasks(my_data)
	if my_data.best_cover then
		managers.navigation:release_cover(my_data.best_cover[1])
	end
	if my_data.nearest_cover then
		managers.navigation:release_cover(my_data.nearest_cover[1])
	end
	for enemy_key, enemy_arrest_data in pairs(my_data.arrest_targets) do
		managers.groupai:state():on_arrest_end(data.unit:key(), enemy_key)
	end
	if new_logic_name ~= "inactive" then
		data.unit:brain():set_update_enabled_state(true)
		CopLogicBase._reset_attention(data)
	end
end
function CopLogicArrest.queued_update(data)
	data.t = TimerManager:game():time()
	local my_data = data.internal_data
	CopLogicArrest._update_enemy_detection(data)
	CopLogicAttack._process_pathing_results(data, my_data)
	local focus_enemy = my_data.focus_enemy
	if my_data.focus_type == "arrest" then
		local focus_data = my_data.arrest_targets[focus_enemy.unit:key()]
		if not my_data.shooting and not data.unit:anim_data().reload and not data.unit:movement():chk_action_forbidden("action") then
			CopLogicBase._set_attention_on_unit(data, focus_enemy.unit)
			local shoot_action = {}
			shoot_action.type = "shoot"
			shoot_action.body_part = 3
			if data.unit:brain():action_request(shoot_action) then
				my_data.shooting = true
			end
		end
		if not focus_data.intro_t then
			focus_data.intro_t = data.t
			data.unit:sound():say("_i01x_sin", true)
			if focus_enemy.unit:brain() then
				focus_enemy.unit:brain():on_intimidated(1, data.unit)
			end
			if not data.unit:movement():chk_action_forbidden("action") then
				local new_action = {
					type = "act",
					variant = "arrest",
					body_part = 1
				}
				if data.unit:brain():action_request(new_action) then
					my_data.gesture_arrest = true
				end
			end
		elseif not focus_data.intro_pos and data.t - focus_data.intro_t > 1 then
			focus_data.intro_pos = mvector3.copy(focus_enemy.m_pos)
		end
		local action_taken = my_data.turning or data.unit:movement():chk_action_forbidden("walk")
		if not action_taken then
			if 1 < data.t - focus_enemy.verified_t then
				if my_data.flank_pos then
					if my_data.flank_path then
						if not data.unit:anim_data().reload then
							CopLogicAttack._chk_request_action_walk_to_cover_shoot_pos(data, my_data, my_data.flank_path, mvector3.distance(data.m_pos, my_data.flank_pos) > 300 and "run")
							my_data.flank_path = nil
						end
					elseif not my_data.flank_path_search_id and not my_data.walking_to_cover_shoot_pos then
						my_data.flank_path_search_id = tostring(data.unit:key()) .. "flank"
						data.unit:brain():search_for_path(my_data.flank_path_search_id, my_data.flank_pos)
					end
				else
					local flank_pos = CopLogicAttack._find_flank_pos(data, my_data, focus_enemy.unit:movement():nav_tracker(), 500)
					if flank_pos then
						my_data.flank_pos = flank_pos
					end
				end
			else
				CopLogicAttack._cancel_flanking_attempt(data, my_data)
				my_data.turning = CopLogicArrest._chk_request_action_turn_to_enemy(data, my_data, data.m_pos, focus_enemy.m_pos)
			end
		end
		local delay = data.important and 0.4 or 1.2
		CopLogicBase.queue_task(my_data, my_data.update_task_key, CopLogicArrest.queued_update, data, data.t + delay)
	else
		local exit_state = my_data.focus_type == "assault" and "attack" or my_data.focus_type or "idle"
		CopLogicBase._exit(data.unit, exit_state)
	end
end
function CopLogicArrest._chk_request_action_turn_to_enemy(data, my_data, my_pos, enemy_pos)
	local fwd = data.unit:movement():m_rot():y()
	local target_vec = enemy_pos - my_pos
	local error_spin = target_vec:to_polar_with_reference(fwd, math.UP).spin
	if math.abs(error_spin) > 27 then
		local new_action_data = {}
		new_action_data.type = "turn"
		new_action_data.body_part = 2
		new_action_data.angle = error_spin
		if data.unit:brain():action_request(new_action_data) then
			my_data.turning = new_action_data.angle
			return true
		end
	end
end
function CopLogicArrest._update_cover(data)
	local my_data = data.internal_data
	local cover_release_dis = 100
	local best_cover = my_data.best_cover
	local nearest_cover = my_data.nearest_cover
	local m_pos = data.m_pos
	if nearest_cover and cover_release_dis < mvector3.distance(nearest_cover[1][1], m_pos) then
		managers.navigation:release_cover(nearest_cover[1])
		my_data.nearest_cover = nil
		nearest_cover = nil
	end
	if best_cover and cover_release_dis < mvector3.distance(best_cover[1][1], m_pos) then
		managers.navigation:release_cover(best_cover[1])
		my_data.best_cover = nil
		best_cover = nil
	end
	if nearest_cover or best_cover then
		CopLogicBase.queue_task(my_data, my_data.cover_update_task_key, CopLogicArrest._update_cover, data, data.t + 3)
	end
end
function CopLogicArrest._update_enemy_detection(data)
	managers.groupai:state():on_unit_detection_updated(data.unit)
	data.t = TimerManager:game():time()
	local my_data = data.internal_data
	local delay = CopLogicAttack._detect_enemies(data, my_data)
	local focus_enemy, focus_enemy_key, focus_type
	local enemies = my_data.detected_enemies
	local arrest_targets = my_data.arrest_targets
	CopLogicArrest._verify_arrest_targets(data, my_data, arrest_targets, enemies)
	if my_data.focus_enemy then
		local key = my_data.focus_enemy.unit:key()
		if arrest_targets[key] then
			focus_enemy = my_data.focus_enemy
			focus_enemy_key = key
			focus_type = "arrest"
		end
	end
	for key, enemy_data in pairs(enemies) do
		if not arrest_targets[key] then
			local reaction = CopLogicArrest._chk_reaction_to_criminal(data, key, enemy_data)
			if reaction == "assault" then
				if enemy_data.verified then
					focus_enemy = enemy_data
					focus_type = reaction
					focus_enemy_key = key
				else
					elseif reaction == "arrest" then
						focus_enemy = enemy_data
						focus_type = reaction
						focus_enemy_key = key
						arrest_targets[key] = {
							unit = enemy_data.unit
						}
						managers.groupai:state():on_arrest_start(data.key, key)
					end
				end
		end
	end
	if not focus_enemy or focus_type == "arrest" and arrest_targets[focus_enemy_key].intro_pos then
		for enemy_key, enemy_arrest_data in pairs(arrest_targets) do
			if not enemy_arrest_data.intro_pos then
				focus_enemy = enemies[enemy_key]
				focus_enemy_key = enemy_key
				focus_type = "arrest"
			else
			end
		end
		if not focus_enemy then
			for enemy_key, enemy_arrest_data in pairs(arrest_targets) do
				focus_enemy = enemies[enemy_key]
				focus_enemy_key = enemy_key
				focus_type = "arrest"
				break
			end
		end
	end
	if focus_enemy then
		if my_data.focus_enemy then
			if my_data.focus_enemy ~= focus_enemy then
				managers.groupai:state():on_enemy_disengaging(data.unit, my_data.focus_enemy.unit:key())
				managers.groupai:state():on_enemy_engaging(data.unit, focus_enemy_key)
				CopLogicBase._set_attention_on_unit(data, focus_enemy.unit)
			end
		else
			managers.groupai:state():on_enemy_engaging(data.unit, focus_enemy_key)
			CopLogicBase._set_attention_on_unit(data, focus_enemy.unit)
		end
	elseif my_data.focus_enemy then
		managers.groupai:state():on_enemy_disengaging(data.unit, my_data.focus_enemy.unit:key())
	end
	my_data.focus_enemy = focus_enemy
	my_data.focus_type = focus_type
	CopLogicBase._report_detections(enemies)
end
function CopLogicArrest._chk_reaction_to_criminal(data, key_criminal, criminal_data)
	local u_criminal = criminal_data.unit
	local visible = criminal_data.verified
	local reaction
	local record = managers.groupai:state():criminal_record(key_criminal)
	local assault_mode = managers.groupai:state():get_assault_mode()
	if record.is_deployable then
		return "assault"
	elseif record.status == "disabled" then
		if visible and record.assault_t - record.disabled_t > 0.6 and (record.engaged_force < 5 or CopLogicIdle._am_i_important_to_player(record, data.key)) then
			return "assault"
		end
	elseif record.being_arrested then
	elseif data.t < record.arrest_timeout then
		reaction = "assault"
	elseif visible and not assault_mode and record.engaged_force == 0 and data.t - record.assault_t > 10 and mvector3.distance(u_criminal:position(), data.m_pos) < 3000 then
		reaction = "arrest"
	else
		local criminal_fwd = u_criminal:movement():m_head_rot():y()
		local criminal_vec = u_criminal:movement():m_pos() - data.m_pos
		mvector3.normalize(criminal_vec)
		local criminal_look_dot = mvector3.dot(criminal_vec, criminal_fwd)
		if visible and not assault_mode and criminal_look_dot > -0.2 then
			reaction = "arrest"
		else
			reaction = "assault"
		end
	end
	return reaction
end
function CopLogicArrest._verify_arrest_targets(data, my_data, arrest_targets, enemies)
	local arrest_timeout = 60
	local group_ai = managers.groupai:state()
	for enemy_key, arrest_data in pairs(arrest_targets) do
		local arrest_terminated
		local record = group_ai:criminal_record(enemy_key)
		if record.status == "disabled" or data.t < record.arrest_timeout then
			group_ai:on_arrest_end(data.unit:key(), enemy_key)
			arrest_targets[enemy_key] = nil
		elseif enemies[enemy_key] then
			if arrest_data.intro_pos then
				local move_dis = mvector3.distance(enemies[enemy_key].m_pos, arrest_data.intro_pos)
				if move_dis > 200 then
					group_ai:on_arrest_end(data.unit:key(), enemy_key)
					arrest_targets[enemy_key] = nil
					record.arrest_timeout = data.t + arrest_timeout
					arrest_terminated = true
					data.unit:sound():say("_r01x_sin", true)
				elseif move_dis > 20 and not record.arrest_warn_timeout then
					record.arrest_warn_timeout = data.t + 2 + math.random(2)
					record.arrest_warn_pos = mvector3.copy(enemies[enemy_key].m_pos)
				end
			end
			if not arrest_terminated and arrest_data.intro_t and record.assault_t > arrest_data.intro_t + 0.6 then
				group_ai:on_arrest_end(data.unit:key(), enemy_key)
				arrest_targets[enemy_key] = nil
				record.arrest_timeout = data.t + arrest_timeout
			end
		else
			group_ai:on_arrest_end(data.unit:key(), enemy_key)
			if arrest_data.intro_pos then
				record.arrest_timeout = data.t + arrest_timeout
			end
			arrest_targets[enemy_key] = nil
		end
	end
end
function CopLogicArrest.action_complete_clbk(data, action)
	local my_data = data.internal_data
	local action_type = action:type()
	if action_type == "walk" then
		my_data.advancing = nil
		if my_data.walking_to_cover_shoot_pos then
			my_data.walking_to_cover_shoot_pos = nil
		end
	elseif action_type == "shoot" then
		my_data.shooting = nil
	elseif action_type == "turn" then
		my_data.turning = nil
	elseif action_type == "act" then
		my_data.gesture_arrest = nil
	end
end
function CopLogicArrest.damage_clbk(data, damage_info)
	CopLogicIdle.damage_clbk(data, damage_info)
	if data.name == "arrest" then
		local enemy = damage_info.attacker_unit
		if enemy then
			local my_data = data.internal_data
			local enemy_key = enemy:key()
			if my_data.arrest_targets[enemy_key] then
				managers.groupai:state():on_arrest_end(data.unit:key(), enemy_key)
				my_data.arrest_targets[enemy_key] = nil
				local record = managers.groupai:state():criminal_record(enemy_key)
				record.arrest_timeout = data.t + 60
			end
		end
	end
end
function CopLogicArrest.can_deactivate(data)
	return false
end
function CopLogicArrest.on_detected_enemy_destroyed(data, enemy_unit)
	local key = enemy_unit:key()
	local my_data = data.internal_data
	if my_data.focus_enemy and my_data.focus_enemy.unit:key() == key then
		my_data.focus_enemy = nil
		CopLogicBase._reset_attention(data)
	end
	my_data.detected_enemies[key] = nil
	my_data.arrest_targets[key] = nil
end
function CopLogicArrest.on_alert(...)
	CopLogicIdle.on_alert(...)
end
function CopLogicArrest.is_available_for_assignment(data)
	return false
end
function CopLogicArrest.on_criminal_neutralized(data, criminal_key)
	local record = managers.groupai:state():criminal_record(criminal_key)
	local my_data = data.internal_data
	if record.status == "dead" or record.status == "removed" then
		if my_data.arrest_targets[criminal_key] then
			managers.groupai:state():on_arrest_end(data.unit:key(), criminal_key)
		end
		my_data.arrest_targets[criminal_key] = nil
		my_data.detected_enemies[criminal_key] = nil
		my_data.suspected_enemies[criminal_key] = nil
		if my_data.focus_enemy and my_data.focus_enemy.unit:key() == criminal_key then
			managers.groupai:state():on_enemy_disengaging(data.unit, criminal_key)
			my_data.focus_enemy = nil
			CopLogicBase._reset_attention(data)
		end
	elseif my_data.arrest_targets[criminal_key] and my_data.arrest_targets[criminal_key].intro_pos then
		my_data.arrest_targets[criminal_key].intro_pos = mvector3.copy(my_data.detected_enemies[criminal_key].unit:movement():m_pos())
		my_data.arrest_targets[criminal_key].intro_t = TimerManager:game():time()
	end
end
function CopLogicArrest.on_intimidated(data, amount, aggressor_unit)
	CopLogicIdle.on_intimidated(data, amount, aggressor_unit)
end
function CopLogicArrest.on_new_objective(data, old_objective)
	CopLogicIdle.on_new_objective(data, old_objective)
end
