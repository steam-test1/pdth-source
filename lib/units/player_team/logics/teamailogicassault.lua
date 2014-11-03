require("lib/units/enemies/cop/logics/CopLogicAttack")
TeamAILogicAssault = class(CopLogicAttack)
function TeamAILogicAssault.enter(data, new_logic_name, enter_params)
	TeamAILogicBase.enter(data, new_logic_name, enter_params)
	data.unit:brain():cancel_all_pathing_searches()
	local old_internal_data = data.internal_data
	local my_data = {
		unit = data.unit
	}
	data.internal_data = my_data
	my_data.ai_visibility_slotmask = managers.slot:get_mask("AI_visibility")
	my_data.detection = tweak_data.character[data.unit:base()._tweak_table].detection.combat
	my_data.enemy_detect_slotmask = managers.slot:get_mask("enemies")
	my_data.rsrv_pos = {}
	if old_internal_data then
		my_data.detected_enemies = old_internal_data.detected_enemies or {}
		my_data.focus_enemy = old_internal_data.focus_enemy
		my_data.rsrv_pos = old_internal_data.rsrv_pos or my_data.rsrv_pos
		CopLogicAttack._set_best_cover(data, my_data, old_internal_data.best_cover)
		CopLogicAttack._set_nearest_cover(my_data, old_internal_data.nearest_cover)
	else
		my_data.detected_enemies = {}
	end
	local key_str = tostring(data.unit:key())
	my_data.detection_task_key = "TeamAILogicAssault._update_enemy_detection" .. key_str
	CopLogicBase.queue_task(my_data, my_data.detection_task_key, TeamAILogicAssault._update_enemy_detection, data, data.t)
	my_data.cover_update_task_key = "TeamAILogicAssault._update_cover" .. key_str
	CopLogicBase.queue_task(my_data, my_data.cover_update_task_key, TeamAILogicAssault._update_cover, data, data.t)
	if data.objective then
		my_data.attitude = data.objective.attitude
	end
	data.unit:movement():set_stance("hos")
	TeamAILogicAssault._chk_change_weapon(data, my_data)
	CopLogicBase._reset_attention(data)
	TeamAILogicAssault._upd_aim(data, my_data)
end
function TeamAILogicAssault.exit(data, new_logic_name, enter_params)
	TeamAILogicBase.exit(data, new_logic_name, enter_params)
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
function TeamAILogicAssault.update(data)
	local unit = data.unit
	local t = data.t
	local my_data = data.internal_data
	CopLogicAttack._process_pathing_results(data, my_data)
	local focus_enemy = my_data.focus_enemy
	if focus_enemy then
		local enemy_visible = focus_enemy.verified
		my_data.want_cover = true
		local action_taken = my_data.turning or data.unit:movement():chk_action_forbidden("walk") or my_data.moving_to_cover or my_data.walking_to_cover_shoot_pos or my_data._turning_to_intimidate
		if not action_taken then
			local needs_cover = CopLogicAttack._needs_cover(data, my_data, focus_enemy)
			if needs_cover then
				local in_cover = my_data.in_cover
				local best_cover = my_data.best_cover
				if in_cover and in_cover[4] then
				elseif my_data.cover_path then
					CopLogicAttack._chk_request_action_walk_to_cover(data, my_data)
					action_taken = true
				elseif best_cover and (not in_cover or best_cover[1] ~= in_cover[1]) and not my_data.processing_cover_path then
					local search_id = tostring(unit:key()) .. "cover"
					if data.unit:brain():search_for_path_to_cover(search_id, best_cover[1], best_cover[5]) then
						my_data.cover_path_search_id = search_id
						my_data.processing_cover_path = my_data.best_cover
					end
				elseif in_cover and not unit:anim_data().crouch and t - my_data.cover_enter_t < 10 then
					action_taken = CopLogicAttack._chk_request_action_crouch(data)
				end
			elseif not my_data.in_cover and unit:anim_data().crouch then
				action_taken = CopLogicAttack._chk_request_action_stand(data)
			end
		end
		if enemy_visible then
		elseif not action_taken and my_data.in_cover then
			if my_data.attitude == "engage" and 1 < t - my_data.cover_enter_t or t - my_data.cover_enter_t > 10 then
				if not my_data.in_cover[4] and unit:anim_data().crouch then
					CopLogicAttack._chk_request_action_stand(data)
				else
					local shoot_from_pos
					if not my_data.sideways_chk_t or t > my_data.sideways_chk_t then
						local my_tracker = unit:movement():nav_tracker()
						shoot_from_pos = CopLogicAttack._peek_for_pos_sideways(data, my_data, my_tracker, focus_enemy.unit:movement():m_pos())
						my_data.sideways_chk_t = t + 1
					end
					if shoot_from_pos then
						local my_tracker = unit:movement():nav_tracker()
						local path = {
							my_tracker:position(),
							shoot_from_pos
						}
						CopLogicAttack._chk_request_action_walk_to_cover_shoot_pos(data, my_data, path)
					end
				end
			elseif not my_data.in_cover[4] and not unit:anim_data().crouch then
				CopLogicAttack._chk_request_action_crouch(data)
			end
		end
	elseif not next(my_data.detected_enemies) then
		local objective = data.objective
		if objective then
			if objective.type == "investigate_area" or objective.type == "defend_area" then
				CopLogicBase._exit(data.unit, "travel")
			elseif objective.guard_obj then
				CopLogicBase._exit(data.unit, "guard")
			else
				CopLogicBase._exit(data.unit, "idle", {scan = true})
			end
		else
			CopLogicBase._exit(data.unit, "idle", {scan = true})
		end
	end
	if not data.objective then
		managers.groupai:state():on_criminal_jobless(unit)
		return
	end
end
function TeamAILogicAssault._get_priority_enemy(data, enemies)
	local best_target, best_target_priority_slot, best_target_priority, best_threat, best_threat_priority_slot, best_threat_priority
	if managers.groupai:state():whisper_mode() then
		return
	end
	local has_revive = data.objective and data.objective.type == "revive"
	for key, enemy_data in pairs(enemies) do
		local enemy_vec = mvector3.copy(enemy_data.m_pos)
		mvector3.subtract(enemy_vec, data.m_pos)
		local distance = mvector3.normalize(enemy_vec)
		local reaction = "assault"
		local alert_dt = enemy_data.alert_t and data.t - enemy_data.alert_t or 10000
		local dmg_dt = enemy_data.dmg_t and data.t - enemy_data.dmg_t or 10000
		local mark_dt = enemy_data.mark_t and data.t - enemy_data.mark_t or 10000
		local near_threshold = 800
		if data.internal_data.focus_enemy and data.internal_data.focus_enemy.unit:key() == key then
			alert_dt = alert_dt * 0.8
			dmg_dt = dmg_dt * 0.8
			mark_dt = mark_dt * 0.8
			distance = distance * 0.8
		end
		local visible = enemy_data.verified
		local near = near_threshold > distance
		local has_alerted = alert_dt < 5
		local has_damaged = dmg_dt < 2
		local been_marked = mark_dt < 8
		local dangerous_special = enemy_data.unit:base()._tweak_table == "taser" or enemy_data.unit:base()._tweak_table == "spooc"
		local target_priority = distance
		local target_priority_slot = 0
		if visible and (dangerous_special or been_marked) and distance < 1600 then
			target_priority_slot = 1
		elseif visible and near and (has_alerted and has_damaged or been_marked) then
			target_priority_slot = 2
		elseif visible and near and has_alerted then
			target_priority_slot = 3
		elseif visible and has_alerted then
			target_priority_slot = 4
		elseif visible then
			target_priority_slot = 5
		elseif has_alerted then
			target_priority_slot = 6
		else
			target_priority_slot = 7
		end
		if target_priority_slot ~= 0 then
			local best = false
			if not best_target then
				best = true
			elseif best_target_priority_slot > target_priority_slot then
				best = true
			elseif target_priority_slot == best_target_priority_slot and best_target_priority > target_priority then
				best = true
			end
			if best then
				best_target = {
					enemy_data = enemy_data,
					reaction = reaction,
					key = key
				}
				best_target_priority_slot = target_priority_slot
				best_target_priority = target_priority
			end
		end
		enemy_vec = mvector3.copy(enemy_data.m_pos)
		mvector3.subtract(enemy_vec, data.m_pos)
		distance = mvector3.normalize(enemy_vec)
		alert_dt = enemy_data.alert_t and data.t - enemy_data.alert_t or 10000
		dmg_dt = enemy_data.dmg_t and data.t - enemy_data.dmg_t or 10000
		if data.internal_data.threat_enemy and data.internal_data.threat_enemy.unit:key() == key then
			alert_dt = alert_dt * 0.8
			dmg_dt = dmg_dt * 0.8
			distance = distance * 0.8
		end
		near = near_threshold > distance
		has_alerted = alert_dt < 7
		has_damaged = dmg_dt < 5
		local threat_priority = distance
		local threat_priority_slot = 0
		if near and has_alerted and has_damaged then
			threat_priority_slot = 1
		elseif near and has_alerted then
			threat_priority_slot = 2
		elseif has_alerted then
			threat_priority_slot = 3
		elseif near then
			threat_priority_slot = 4
		else
			threat_priority_slot = 5
		end
		if threat_priority_slot ~= 0 then
			local best = false
			if not best_threat then
				best = true
			elseif best_threat_priority_slot > threat_priority_slot then
				best = true
			elseif threat_priority_slot == best_threat_priority_slot and best_threat_priority > threat_priority then
				best = true
			end
			if best then
				best_threat = {
					enemy_data = enemy_data,
					reaction = reaction,
					key = key
				}
				best_threat_priority_slot = threat_priority_slot
				best_threat_priority = threat_priority
			end
		end
	end
	return best_target, best_threat, best_target_priority_slot, best_threat_priority_slot
end
function TeamAILogicAssault._update_enemy_detection(data)
	data.t = TimerManager:game():time()
	local my_data = data.internal_data
	local delay = TeamAILogicIdle._detect_enemies(data, my_data)
	local enemies = my_data.detected_enemies
	local focus_enemy, focus_type, focus_enemy_key
	local enemies = my_data.detected_enemies
	local target, threat, target_prio_slot = TeamAILogicAssault._get_priority_enemy(data, enemies)
	if target then
		focus_enemy = target.enemy_data
		focus_type = target.reaction
		focus_enemy_key = target.key
	end
	if focus_enemy then
		focus_enemy.nearly_visible = TeamAILogicIdle._chk_is_enemy_nearly_visible(data, focus_enemy)
		if my_data.focus_enemy and my_data.focus_enemy.unit:key() ~= focus_enemy_key then
			CopLogicAttack._cancel_flanking_attempt(data, my_data)
		end
	elseif my_data.focus_enemy then
		CopLogicAttack._cancel_flanking_attempt(data, my_data)
	end
	my_data.focus_enemy = focus_enemy
	if focus_type == "assault" then
		if data.objective and data.objective.type == "follow" and not data.unit:movement():chk_action_forbidden("walk") then
			local max_dist = managers.groupai:state():get_assault_mode() and 700 or 1500
			local dist = mvector3.distance(data.objective.follow_unit:movement():m_pos(), data.m_pos)
			local zdist = math.abs(data.objective.follow_unit:movement():m_pos().z - data.m_pos.z)
			if zdist > 300 or target_prio_slot > 3 and max_dist < dist or dist > max_dist * 2 then
				data.objective.called = true
				CopLogicBase._exit(data.unit, "travel")
				return
			end
		end
		TeamAILogicAssault._chk_change_weapon(data, my_data)
		TeamAILogicAssault._upd_aim(data, my_data)
		if not my_data._intimidate_t or my_data._intimidate_t + 2 < data.t and not my_data._turning_to_intimidate and data.unit:character_damage():health_ratio() > 0.5 then
			local can_turn = not data.unit:movement():chk_action_forbidden("walk") and target_prio_slot > 3
			local is_assault = managers.groupai:state():get_assault_mode()
			local civ = TeamAILogicIdle.find_civilian_to_intimidate(data.unit, can_turn and 180 or 60, is_assault and 800 or 1200)
			if civ and (not is_assault or civ:anim_data().run or civ:anim_data().stand) then
				my_data._intimidate_t = data.t
				if can_turn and CopLogicAttack._chk_request_action_turn_to_enemy(data, my_data, data.unit:movement():m_pos(), civ:movement():m_pos()) then
					my_data._turning_to_intimidate = true
					my_data._primary_intimidation_target = civ
				else
					TeamAILogicIdle.intimidate_civilians(data, data.unit, true, false)
				end
			end
		end
		CopLogicBase.queue_task(my_data, my_data.detection_task_key, TeamAILogicAssault._update_enemy_detection, data, data.t + delay)
	elseif focus_type then
		CopLogicBase._exit(data.unit, focus_type)
	elseif data.objective and data.objective.type == "follow" then
		CopLogicBase._exit(data.unit, "travel")
	else
		CopLogicBase._exit(data.unit, "idle", {scan = true})
	end
	if (not TeamAILogicAssault._mark_special_chk_t or TeamAILogicAssault._mark_special_chk_t + 0.75 < data.t) and (not TeamAILogicAssault._mark_special_t or TeamAILogicAssault._mark_special_t + 6 < data.t) and not my_data.acting and not data.unit:sound():speaking() then
		local nmy = TeamAILogicAssault.find_enemy_to_mark(data.unit)
		TeamAILogicAssault._mark_special_chk_t = data.t
		if nmy then
			TeamAILogicAssault._mark_special_t = data.t
			TeamAILogicAssault.mark_enemy(data, data.unit, nmy, true, true)
		end
	end
	TeamAILogicAssault._chk_request_combat_chatter(data, my_data)
end
function TeamAILogicAssault.find_enemy_to_mark(criminal)
	local head_pos = criminal:movement():m_head_pos()
	local look_vec = criminal:movement():m_rot():y()
	local best_nmy
	local best_nmy_wgt = false
	local my_tracker = criminal:movement():nav_tracker()
	local chk_vis_func = my_tracker.check_visibility
	for key, u_data in pairs(managers.enemy:all_enemies()) do
		local unit = u_data.unit
		if tweak_data.character[unit:base()._tweak_table].priority_shout and chk_vis_func(my_tracker, unit:movement():nav_tracker()) then
			local u_head_pos = unit:movement():m_head_pos() + math.UP * 30
			local vec = u_head_pos - head_pos
			local dis = mvector3.normalize(vec)
			local angle = vec:angle(look_vec)
			local max_angle = math.max(8, math.lerp(90, 30, dis / 1200))
			local max_dis = 1200
			if dis < max_dis and angle < max_angle then
				local slotmask = managers.slot:get_mask("AI_visibility")
				local ray = World:raycast("ray", head_pos, u_head_pos, "slot_mask", slotmask, "ray_type", "ai_vision")
				if not ray then
					local inv_wgt = dis * dis * (1 - vec:dot(look_vec))
					if not best_nmy_wgt or best_nmy_wgt > inv_wgt then
						best_nmy_wgt = inv_wgt
						best_nmy = unit
					end
				end
			end
		end
	end
	return best_nmy
end
function TeamAILogicAssault.mark_enemy(data, criminal, to_mark, play_sound, play_action)
	if play_sound then
		criminal:sound():say(tweak_data.character[to_mark:base()._tweak_table].priority_shout .. "x_any", true)
	end
	if play_action and not criminal:movement():chk_action_forbidden("action") then
		local new_action = {
			type = "act",
			variant = "arrest",
			body_part = 3,
			align_sync = true
		}
		if criminal:brain():action_request(new_action) then
			data.internal_data.gesture_arrest = true
		end
	end
	managers.game_play_central:add_enemy_contour(to_mark)
	managers.network:session():send_to_peers_synched("mark_enemy", to_mark)
end
function TeamAILogicAssault.action_complete_clbk(data, action)
	local my_data = data.internal_data
	local action_type = action:type()
	if action_type == "walk" then
		my_data.rsrv_pos.stand = my_data.rsrv_pos.move_dest
		my_data.rsrv_pos.move_dest = nil
		if my_data.surprised then
			my_data.surprised = false
		elseif my_data.moving_to_cover then
			if action:expired() then
				my_data.in_cover = my_data.moving_to_cover
				my_data.cover_enter_t = data.t
				my_data.cover_sideways_chk = nil
			end
			my_data.moving_to_cover = nil
		elseif my_data.walking_to_cover_shoot_pos then
			my_data.walking_to_cover_shoot_pos = nil
		end
	elseif action_type == "shoot" then
		my_data.shooting = nil
	elseif action_type == "turn" then
		my_data.turning = nil
		if my_data._turning_to_intimidate then
			my_data._turning_to_intimidate = nil
			TeamAILogicIdle.intimidate_civilians(data, data.unit, true, true, my_data._primary_intimidation_target)
			my_data._primary_intimidation_target = nil
		end
	elseif action_type == "hurt" then
		if action:expired() then
			TeamAILogicAssault._upd_aim(data, my_data)
		end
	elseif action_type == "dodge" then
		TeamAILogicAssault._upd_aim(data, my_data)
	end
end
function TeamAILogicAssault.damage_clbk(data, damage_info)
	TeamAILogicIdle.damage_clbk(data, damage_info)
end
function TeamAILogicAssault.death_clbk(data, damage_info)
	local my_data = data.internal_data
	if my_data.focus_enemy then
		my_data.focus_enemy = nil
	end
end
function TeamAILogicAssault.on_detected_enemy_destroyed(data, enemy_unit)
	TeamAILogicIdle.on_cop_neutralized(data, enemy_unit:key())
end
function TeamAILogicAssault.on_cop_neutralized(data, cop_key)
	TeamAILogicIdle.on_cop_neutralized(data, cop_key)
end
function TeamAILogicAssault.on_objective_unit_damaged(...)
	TeamAILogicIdle.on_objective_unit_damaged(...)
end
function TeamAILogicAssault.on_alert(...)
	TeamAILogicIdle.on_alert(...)
end
function TeamAILogicAssault._needs_cover(data, my_data, focus_enemy)
	if data.objective and data.objective.in_place then
		return
	end
	if data.unit:anim_data().reload or data.unit:inventory():equipped_unit():ammo_info() then
		return true
	end
	local ammo_max, ammo = data.unit:inventory():equipped_unit():base():ammo_info()
	if ammo / ammo_max < 0.2 then
		return true
	end
	if focus_enemy.verified and my_data.attitude ~= "engage" then
		return true
	end
end
function TeamAILogicAssault.on_intimidated(data, amount, aggressor_unit)
	TeamAILogicIdle.on_intimidated(data, amount, aggressor_unit)
end
function TeamAILogicAssault.on_long_dis_interacted(data, other_unit)
	TeamAILogicIdle.on_long_dis_interacted(data, other_unit)
end
function TeamAILogicAssault.on_new_objective(data, old_objective)
	TeamAILogicIdle.on_new_objective(data, old_objective)
end
function TeamAILogicAssault._upd_aim(data, my_data)
	local shoot, aim, expected_pos
	local focus_enemy = my_data.focus_enemy
	if focus_enemy then
		if focus_enemy.verified then
			aim = true
			if focus_enemy.alert_t and data.t - focus_enemy.alert_t < 4 then
				shoot = true
			elseif my_data.attitude == "engage" then
				if focus_enemy.verified_dis < 2500 then
					shoot = true
				end
			elseif focus_enemy.verified_dis < 1700 then
				shoot = true
			end
		elseif focus_enemy.verified_t then
			local weapons_down_delay = focus_enemy.nearly_visible and 4 or 1
			if weapons_down_delay > data.t - focus_enemy.verified_t and focus_enemy.verified_dis < 800 and math.abs(focus_enemy.verified_pos.z - data.m_pos.z) < 250 then
				aim = true
				if my_data.shooting and data.t - focus_enemy.verified_t < 3 then
					shoot = true
				end
			else
				expected_pos = CopLogicAttack._get_expected_attention_position(data, my_data)
				if expected_pos then
					aim = true
				elseif data.t - focus_enemy.verified_t < 20 or focus_enemy.verified_dis < 1000 then
					aim = true
					if my_data.shooting and data.t - focus_enemy.verified_t < 3 and data.unit:anim_data().still then
						shoot = true
					end
				end
			end
		else
			expected_pos = CopLogicAttack._get_expected_attention_position(data, my_data)
			if expected_pos then
				aim = true
			end
		end
	end
	if data.logic.chk_should_turn(data, my_data) and not my_data._turning_to_intimidate and (focus_enemy or expected_pos) then
		local enemy_pos = expected_pos or (focus_enemy.verified or focus_enemy.nearly_visible) and focus_enemy.m_pos or focus_enemy.verified_pos
		CopLogicAttack._chk_request_action_turn_to_enemy(data, my_data, data.m_pos, enemy_pos)
	end
	if aim or shoot then
		if expected_pos then
			if my_data.attention_unit ~= expected_pos then
				CopLogicBase._set_attention_on_pos(data, mvector3.copy(expected_pos))
				my_data.attention_unit = mvector3.copy(expected_pos)
			end
		elseif focus_enemy.verified then
			if my_data.attention ~= focus_enemy.unit:key() then
				CopLogicBase._set_attention_on_unit(data, focus_enemy.unit)
				my_data.attention = focus_enemy.unit:key()
			end
		elseif shoot or focus_enemy.nearly_visible then
			if my_data.attention ~= focus_enemy.verified_pos then
				CopLogicBase._set_attention_on_pos(data, mvector3.copy(focus_enemy.verified_pos))
				my_data.attention = mvector3.copy(focus_enemy.verified_pos)
			end
		elseif my_data.attention then
			CopLogicBase._reset_attention(data)
			my_data.attention = nil
		end
		if not my_data.shooting and not data.unit:anim_data().reload and not data.unit:movement():chk_action_forbidden("aim") then
			local shoot_action = {}
			shoot_action.type = "shoot"
			shoot_action.body_part = 3
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
		if my_data.attention then
			CopLogicBase._reset_attention(data)
			my_data.attention = nil
		end
	end
	if shoot then
		if not my_data.firing then
			data.unit:movement():set_allow_fire(true)
			my_data.firing = true
		end
	elseif my_data.firing then
		data.unit:movement():set_allow_fire(false)
		my_data.firing = nil
	end
end
function TeamAILogicAssault.on_objective_unit_destroyed(data, unit)
	TeamAILogicBase.on_objective_unit_destroyed(data, unit)
end
function TeamAILogicAssault.dodge(data)
	if not data.unit:movement():chk_action_forbidden("walk") then
		local action_data = TeamAILogicIdle.try_dodge(data)
		if action_data then
			local my_data = data.internal_data
			CopLogicAttack._cancel_cover_pathing(data, my_data)
			CopLogicAttack._cancel_flanking_attempt(data, my_data)
			CopLogicAttack._cancel_expected_pos_path(data, my_data)
			CopLogicAttack._cancel_walking_to_cover(data, my_data, true)
			return action_data
		end
	end
end
function TeamAILogicAssault.is_available_for_assignment(data, new_objective)
	if not new_objective then
		return true
	end
	if new_objective.type == "revive" then
		return true
	end
	local my_data = data.internal_data
	if not my_data.focus_enemy then
		return true
	end
	if my_data.focus_enemy.verified then
		return false
	end
	if not my_data.focus_enemy.verified_t then
		return true
	end
	if data.t - my_data.focus_enemy.verified_t > 10 then
		return true
	end
end
function TeamAILogicAssault._chk_change_weapon(data, my_data)
	local selection
	local inventory = data.unit:inventory()
	local equipped_selection = inventory:equipped_selection()
	if managers.groupai:state():enemy_weapons_hot() then
		if equipped_selection ~= 2 and equipped_selection ~= 4 then
			selection = TeamAILogicAssault._choose_between_weapon_selections(data, my_data, inventory, {2, 4})
		end
	elseif equipped_selection ~= 1 then
		selection = 1
	end
	if selection then
		data.unit:inventory():equip_selection(selection, true)
	end
end
function TeamAILogicAssault._choose_between_weapon_selections(data, my_data, inventory, selections)
	return selections[math.random(#selections)]
end
function TeamAILogicAssault.clbk_heat(data)
	TeamAILogicIdle.clbk_heat(data)
end
function TeamAILogicAssault._update_cover(data)
	local my_data = data.internal_data
	local cover_release_dis = 100
	local best_cover = my_data.best_cover
	local nearest_cover = my_data.nearest_cover
	local satisfied = true
	local want_cover = my_data.want_cover
	local my_pos = data.m_pos
	data.t = TimerManager:game():time()
	if want_cover then
		local find_new = my_data.focus_enemy and not my_data.moving_to_cover and (my_data.focus_enemy and (not best_cover or my_data.focus_enemy.dmg_t and data.t - my_data.focus_enemy.dmg_t < 4) or my_data.focus_enemy.verified_dis < 500)
		if find_new then
			local enemy_tracker = my_data.focus_enemy.unit:movement():nav_tracker()
			local threat_pos = enemy_tracker:field_position()
			local min_dis, max_dis
			if my_data.attitude == "engage" then
				min_dis = 400
			else
				min_dis = 700
			end
			if not best_cover or not CopLogicAttack._verify_cover(best_cover[1], threat_pos, min_dis, max_dis) then
				local my_vec = my_pos - threat_pos
				local my_vec_len = my_vec:length()
				local max_dis = my_vec_len + 800
				if my_data.attitude == "engage" then
					if my_vec_len > 700 then
						my_vec_len = 700
						mvector3.set_length(my_vec, my_vec_len)
					end
				elseif my_vec_len < 3000 then
					my_vec_len = my_vec_len + 500
					mvector3.set_length(my_vec, my_vec_len)
				end
				local my_side_pos = threat_pos + my_vec
				mvector3.set_length(my_vec, max_dis)
				local furthest_side_pos = threat_pos + my_vec
				local min_threat_dis = min_dis + 100
				local cone_angle
				cone_angle = math.lerp(90, 30, math.min(1, my_vec_len / 3000))
				local search_nav_seg
				if data.objective and data.objective.type == "defend_area" then
					search_nav_seg = data.objective.nav_seg
				end
				local found_cover = managers.navigation:find_cover_in_cone_from_threat_pos_1(threat_pos, furthest_side_pos, my_side_pos, nil, cone_angle, min_threat_dis, search_nav_seg)
				if found_cover then
					local better_cover = {found_cover}
					CopLogicAttack._set_best_cover(data, my_data, better_cover)
					local offset_pos, yaw = CopLogicAttack._get_cover_offset_pos(data, better_cover, threat_pos)
					if offset_pos then
						better_cover[5] = offset_pos
						better_cover[6] = yaw
					end
				else
					satisfied = false
				end
			end
		end
		local in_cover = my_data.in_cover
		if in_cover and my_data.focus_enemy then
			local threat_pos = my_data.focus_enemy.verified_pos
			in_cover[3], in_cover[4] = CopLogicAttack._chk_covered(data, my_pos, threat_pos, my_data.ai_visibility_slotmask)
		end
	else
		if nearest_cover and cover_release_dis < mvector3.distance(nearest_cover[1][1], my_pos) then
			CopLogicAttack._set_nearest_cover(my_data, nil)
		end
		if best_cover and cover_release_dis < mvector3.distance(best_cover[1][1], my_pos) then
			CopLogicAttack._set_best_cover(data, my_data, nil)
		end
	end
	local delay = satisfied and 4 or 1
	CopLogicBase.queue_task(my_data, my_data.cover_update_task_key, TeamAILogicAssault._update_cover, data, TimerManager:game():time() + delay)
end
function TeamAILogicAssault._chk_request_combat_chatter(data, my_data)
	local focus_enemy = my_data.focus_enemy
	if focus_enemy and focus_enemy.verified and (my_data.firing or data.unit:character_damage():health_ratio() < 1) and not data.unit:movement():chk_action_forbidden("walk") and not data.unit:sound():speaking() then
		managers.groupai:state():chk_say_teamAI_combat_chatter(data.unit)
	end
end
