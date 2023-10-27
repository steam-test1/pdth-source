TaserLogicAttack = class(CopLogicAttack)
function TaserLogicAttack.enter(data, new_logic_name, enter_params)
	CopLogicBase.enter(data, new_logic_name, enter_params)
	data.unit:brain():cancel_all_pathing_searches()
	local old_internal_data = data.internal_data
	local my_data = {
		unit = data.unit
	}
	data.internal_data = my_data
	my_data.ai_visibility_slotmask = managers.slot:get_mask("AI_visibility")
	my_data.detection = tweak_data.character[data.unit:base()._tweak_table].detection.combat
	my_data.tase_distance = data.char_tweak.weapon.m4.tase_distance
	my_data.enemy_detect_slotmask = managers.slot:get_mask("criminals")
	my_data.rsrv_pos = {}
	if old_internal_data then
		my_data.suspected_enemies = old_internal_data.suspected_enemies or {}
		my_data.detected_enemies = old_internal_data.detected_enemies or {}
		my_data.focus_enemy = old_internal_data.focus_enemy
		my_data.rsrv_pos = old_internal_data.rsrv_pos or my_data.rsrv_pos
		CopLogicAttack._set_best_cover(data, my_data, old_internal_data.best_cover)
		CopLogicAttack._set_nearest_cover(my_data, old_internal_data.nearest_cover)
	else
		my_data.suspected_enemies = {}
		my_data.detected_enemies = {}
	end
	local key_str = tostring(data.unit:key())
	my_data.update_task_key = "TaserLogicAttack.queued_update" .. key_str
	CopLogicBase.queue_task(my_data, my_data.update_task_key, TaserLogicAttack.queued_update, data, data.t)
	data.unit:brain():set_update_enabled_state(false)
	CopLogicTravel.reset_actions(data, my_data, old_internal_data, CopLogicTravel.allowed_transitional_actions)
	local objective = data.objective
	if objective then
		my_data.attitude = data.objective.attitude
	end
	local upper_body_action = data.unit:movement()._active_actions[3]
	if not upper_body_action or upper_body_action:type() ~= "shoot" then
		data.unit:movement():set_stance("hos")
	end
	data.tase_delay_t = data.tase_delay_t or -1
	TaserLogicAttack._chk_play_charge_weapon_sound(data, my_data, my_data.focus_enemy)
end
function TaserLogicAttack.exit(data, new_logic_name, enter_params)
	CopLogicBase.exit(data, new_logic_name, enter_params)
	local my_data = data.internal_data
	data.unit:brain():cancel_all_pathing_searches()
	TaserLogicAttack._cancel_tase_attempt(data, my_data)
	CopLogicBase.cancel_queued_tasks(my_data)
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
	data.unit:brain():set_update_enabled_state(true)
end
function TaserLogicAttack.queued_update(data)
	if CopLogicIdle._chk_relocate(data) then
		return
	end
	CopLogicAttack._update_cover(data)
	local t = TimerManager:game():time()
	data.t = t
	local unit = data.unit
	local my_data = data.internal_data
	local objective = data.objective
	TaserLogicAttack._upd_enemy_detection(data)
	local focus_type = my_data.focus_type
	if focus_type ~= "assault" and focus_type ~= "tase" then
		if not data.unit:movement():chk_action_forbidden("walk") then
			my_data.update_task_key = nil
			if focus_type then
				CopLogicBase._exit(data.unit, focus_type)
			elseif data.objective then
				CopLogicBase._exit(data.unit, "idle")
				CopLogicIdle.on_new_objective(data, nil)
			elseif not managers.groupai:state():on_cop_jobless(data.unit) then
				CopLogicBase._exit(data.unit, "idle", {scan = true})
			end
		end
		CopLogicBase._report_detections(my_data.detected_enemies)
		return
	end
	local focus_enemy = my_data.focus_enemy
	TaserLogicAttack._upd_aim(data, my_data)
	local action_taken = my_data.turning or data.unit:movement():chk_action_forbidden("walk") or my_data.moving_to_cover or my_data.walking_to_cover_shoot_pos or my_data.acting
	if my_data.tasing then
		action_taken = action_taken or CopLogicAttack._chk_request_action_turn_to_enemy(data, my_data, data.m_pos, focus_enemy.m_pos)
		CopLogicBase.queue_task(my_data, my_data.update_task_key, TaserLogicAttack.queued_update, data, data.t + 1)
		CopLogicBase._report_detections(my_data.detected_enemies)
		return
	end
	CopLogicAttack._process_pathing_results(data, my_data)
	local in_cover = my_data.in_cover
	local best_cover = my_data.best_cover
	if not my_data.processing_cover_path and not my_data.moving_to_cover and best_cover and (not in_cover or best_cover[2] ~= in_cover[2]) then
		local search_id = tostring(unit:key()) .. "cover"
		if data.unit:brain():search_for_path_to_cover(search_id, best_cover[1], best_cover[5]) then
			my_data.cover_path_search_id = search_id
			my_data.processing_cover_path = my_data.best_cover
		end
	end
	local enemy_visible = focus_enemy.verified
	local engage = my_data.attitude == "engage"
	local flank_cover
	if not action_taken then
		local move_to_cover
		if not engage or data.unit:anim_data().reload or my_data.under_fire then
			if in_cover then
				if not in_cover[4] and in_cover[3] and not unit:anim_data().crouch then
					action_taken = CopLogicAttack._chk_request_action_crouch(data)
				end
			elseif my_data.cover_path and not my_data.flank_cover then
				move_to_cover = true
			end
		elseif my_data.cover_path then
			local cover_dis = mvector3.distance(my_data.best_cover[1][1], focus_enemy.m_pos)
			if engage then
				if 400 < cover_dis and focus_enemy.verified_dis - cover_dis > 300 then
					move_to_cover = true
				end
			elseif cover_dis - focus_enemy.verified_dis > 300 then
				move_to_cover = true
			end
		end
		if move_to_cover then
			CopLogicAttack._chk_request_action_walk_to_cover(data, my_data)
			action_taken = true
		else
			local enemy_pos = enemy_visible and focus_enemy.unit:movement():m_pos() or focus_enemy.verified_pos
			action_taken = CopLogicAttack._chk_request_action_turn_to_enemy(data, my_data, data.m_pos, enemy_pos)
		end
		if not action_taken then
			if engage then
				if enemy_visible then
					my_data.cover_sideways_chk = nil
				end
				if not unit:anim_data().crouch then
					if in_cover and 1 < t - my_data.cover_enter_t and not my_data.cover_sideways_chk and not data.unit:anim_data().reload then
						my_data.cover_sideways_chk = true
						local my_tracker = unit:movement():nav_tracker()
						local shoot_from_pos = CopLogicAttack._peek_for_pos_sideways(data, my_data, my_tracker, focus_enemy.m_pos)
						if shoot_from_pos then
							local my_tracker = unit:movement():nav_tracker()
							local path = {
								mvector3.copy(data.m_pos),
								shoot_from_pos
							}
							CopLogicAttack._chk_request_action_walk_to_cover_shoot_pos(data, my_data, path)
						end
					elseif not in_cover or my_data.cover_sideways_chk then
						if my_data.flank_cover then
							local fl_cover = my_data.flank_cover
							if fl_cover.failed then
								if my_data.flank_pos then
									if my_data.flank_path then
										if data.unit:anim_data().reload then
											flank_cover = true
										else
											CopLogicAttack._chk_request_action_crouch(data)
											CopLogicAttack._chk_request_action_walk_to_cover_shoot_pos(data, my_data, my_data.flank_path, 300 < mvector3.distance(data.m_pos, my_data.flank_pos) and "run")
											my_data.flank_path = nil
										end
									elseif not my_data.flank_path_search_id then
										my_data.flank_path_search_id = tostring(unit:key()) .. "flank"
										unit:brain():search_for_path(my_data.flank_path_search_id, my_data.flank_pos)
									end
								else
									local flank_pos = CopLogicAttack._find_flank_pos(data, my_data, focus_enemy.unit:movement():nav_tracker())
									if not flank_pos then
										return
									end
									my_data.flank_pos = flank_pos
								end
							elseif fl_cover.found then
								CopLogicAttack._cancel_cover_pathing(data, my_data)
								local search_id = tostring(unit:key()) .. "cover"
								if data.unit:brain():search_for_path_to_cover(search_id, my_data.best_cover[1], my_data.best_cover[5]) then
									my_data.cover_path_search_id = search_id
									my_data.processing_cover_path = my_data.best_cover
								end
							elseif my_data.cover_path and not data.unit:anim_data().reload then
								CopLogicAttack._chk_request_action_walk_to_cover(data, my_data)
								action_taken = true
							elseif not my_data.processing_cover_path then
								flank_cover = true
							end
						else
							flank_cover = true
						end
					end
				end
				if not action_taken and unit:anim_data().crouch and (not my_data.alert_t or 4 < t - my_data.alert_t) and not data.unit:anim_data().reload then
					action_taken = CopLogicAttack._chk_request_action_stand(data)
				end
				if flank_cover then
					if not my_data.flank_cover then
						local sign = math.random() < 0.5 and -1 or 1
						local step = 30
						my_data.flank_cover = {
							step = step,
							angle = step * sign,
							sign = sign
						}
					end
				else
					my_data.flank_cover = nil
				end
			else
				if (enemy_visible or my_data.under_fire) and not unit:anim_data().crouch then
					action_taken = CopLogicAttack._chk_request_action_crouch(data)
				end
				if not action_taken then
					local enemy_pos = enemy_visible and focus_enemy.unit:movement():m_pos() or focus_enemy.verified_pos
					action_taken = CopLogicAttack._chk_request_action_turn_to_enemy(data, my_data, data.m_pos, enemy_pos)
				end
			end
		end
	end
	CopLogicBase.queue_task(my_data, my_data.update_task_key, TaserLogicAttack.queued_update, data, data.t + (data.important and 0.5 or 2))
	CopLogicBase._report_detections(my_data.detected_enemies)
end
function TaserLogicAttack._upd_enemy_detection(data)
	managers.groupai:state():on_unit_detection_updated(data.unit)
	local my_data = data.internal_data
	local delay = CopLogicAttack._detect_enemies(data, my_data)
	local focus_enemy, focus_type, focus_enemy_key
	local enemies = my_data.detected_enemies
	local under_fire, under_multiple_fire
	local alert_chk_t = data.t - 1.2
	local num_attacking = 0
	for key, enemy_data in pairs(enemies) do
		if enemy_data.dmg_t and alert_chk_t < enemy_data.dmg_t then
			under_fire = true
			num_attacking = num_attacking + 1
		end
	end
	if 2 < num_attacking then
		under_multiple_fire = true
	end
	my_data.under_fire = under_fire
	my_data.under_multiple_fire = under_multiple_fire
	local find_new_focus_enemy
	local tasing = my_data.tasing
	local tased_u_key = tasing and tasing.target_u_key
	local tase_in_effect = tasing and tasing.target_u_data.unit:movement():tased()
	if tase_in_effect or tasing and data.t - tasing.start_t < math.max(1, data.char_tweak.weapon.m4.aim_delay_tase[2] * 1.5) then
		if under_multiple_fire then
			find_new_focus_enemy = true
		end
	else
		find_new_focus_enemy = true
	end
	if find_new_focus_enemy then
		local target = CopLogicAttack._get_priority_enemy(data, my_data.detected_enemies, TaserLogicAttack._chk_reaction_to_criminal)
		if target then
			focus_enemy = target.enemy_data
			focus_type = target.reaction
			focus_enemy_key = target.key
		end
		if focus_enemy then
			if my_data.focus_enemy then
				if my_data.focus_enemy.unit:key() ~= focus_enemy_key then
					managers.groupai:state():on_enemy_disengaging(data.unit, my_data.focus_enemy.unit:key())
					managers.groupai:state():on_enemy_engaging(data.unit, focus_enemy_key)
					CopLogicAttack._cancel_flanking_attempt(data, my_data)
					if not focus_enemy.is_deployable and focus_type == "assault" and focus_enemy.verified and data.t - managers.groupai:state():criminal_record(focus_enemy_key).det_t > 15 then
						data.unit:sound():say("_c01x_plu", true)
					end
					if not focus_enemy.is_deployable then
						TaserLogicAttack._chk_play_charge_weapon_sound(data, my_data, focus_enemy)
					end
				end
			else
				managers.groupai:state():on_enemy_engaging(data.unit, focus_enemy_key)
				if not focus_enemy.is_deployable and (focus_type == "assault" or focus_type == "tase") and focus_enemy.verified and data.t - managers.groupai:state():criminal_record(focus_enemy_key).det_t > 15 then
					data.unit:sound():say("_c01x_plu", true)
				end
				if not focus_enemy.is_deployable then
					TaserLogicAttack._chk_play_charge_weapon_sound(data, my_data, focus_enemy)
				end
			end
		elseif my_data.focus_enemy then
			managers.groupai:state():on_enemy_disengaging(data.unit, my_data.focus_enemy.unit:key())
			CopLogicAttack._cancel_flanking_attempt(data, my_data)
		end
		my_data.focus_enemy = focus_enemy
		my_data.focus_type = focus_type
	end
end
function TaserLogicAttack._upd_aim(data, my_data)
	local shoot, aim
	local focus_enemy = my_data.focus_enemy
	local focus_type = my_data.focus_type
	local tase = focus_type == "tase"
	if focus_enemy then
		if tase then
			shoot = true
		elseif focus_enemy.verified then
			if focus_enemy.verified_dis < 1500 or my_data.alert_t and data.t - my_data.alert_t < 7 then
				shoot = true
				if focus_enemy.verified_dis > 800 and data.unit:anim_data().run then
					local walk_to_pos = data.unit:movement():get_walk_to_pos()
					if walk_to_pos then
						local move_vec = walk_to_pos - data.m_pos
						local enemy_vec = focus_enemy.m_pos - data.m_pos
						mvector3.normalize(enemy_vec)
						if mvector3.dot(enemy_vec, move_vec) < 0.6 then
							shoot = nil
						end
					end
				end
			end
		elseif focus_enemy.verified_t and data.t - focus_enemy.verified_t < 10 then
			aim = true
			if my_data.shooting and data.t - focus_enemy.verified_t < 3 then
				shoot = true
			end
		elseif focus_enemy.verified_dis < 600 and my_data.walking_to_cover_shoot_pos then
			aim = true
		end
	end
	if shoot and (my_data.walking_to_cover_shoot_pos or tase and my_data.moving_to_cover) and not data.unit:movement():chk_action_forbidden("walk") then
		local new_action = {type = "idle", body_part = 2}
		data.unit:brain():action_request(new_action)
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
		if not data.unit:anim_data().reload and not data.unit:movement():chk_action_forbidden("action") then
			if tase then
				if (not my_data.tasing or my_data.tasing.target_u_data ~= focus_enemy) and not data.unit:movement():chk_action_forbidden("walk") then
					local tase_action = {type = "tase", body_part = 3}
					if data.unit:brain():action_request(tase_action) then
						my_data.tasing = {
							target_u_data = focus_enemy,
							target_u_key = focus_enemy.unit:key(),
							start_t = data.t
						}
						CopLogicAttack._cancel_flanking_attempt(data, my_data)
						managers.groupai:state():on_tase_start(data.key, focus_enemy.unit:key())
					end
				end
			elseif shoot and not my_data.shooting then
				local shoot_action = {}
				shoot_action.type = "shoot"
				shoot_action.body_part = 3
				if data.unit:brain():action_request(shoot_action) then
					my_data.shooting = true
				end
			end
		end
	else
		if my_data.shooting or my_data.tasing then
			local new_action
			if data.unit:anim_data().reload then
				new_action = {type = "reload", body_part = 3}
			else
				new_action = {type = "idle", body_part = 3}
			end
			data.unit:brain():action_request(new_action)
		elseif not data.unit:anim_data().run then
			local ammo_max, ammo = data.unit:inventory():equipped_unit():base():ammo_info()
			if ammo / ammo_max < 0.5 then
				local new_action = {type = "reload", body_part = 3}
				data.unit:brain():action_request(new_action)
			end
		end
		if my_data.attention_unit then
			CopLogicBase._reset_attention(data)
			my_data.attention_unit = nil
		end
	end
	CopLogicAttack.aim_allow_fire(shoot, aim, data, my_data)
end
function TaserLogicAttack.action_complete_clbk(data, action)
	local my_data = data.internal_data
	local action_type = action:type()
	if action_type == "walk" then
		if my_data.moving_to_cover then
			if action:expired() then
				my_data.in_cover = my_data.moving_to_cover
				CopLogicAttack._set_nearest_cover(my_data, my_data.in_cover)
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
	elseif action_type == "tase" then
		if action:expired() and my_data.tasing then
			local record = managers.groupai:state():criminal_record(my_data.tasing.target_u_key)
			if record and record.status then
				data.tase_delay_t = TimerManager:game():time() + 45
			end
		end
		managers.groupai:state():on_tase_end(my_data.tasing.target_u_key)
		my_data.tasing = nil
	end
end
function TaserLogicAttack._cancel_tase_attempt(data, my_data)
	if my_data.tasing then
		local new_action = {type = "idle", body_part = 3}
		data.unit:brain():action_request(new_action)
	end
end
function TaserLogicAttack.on_criminal_neutralized(data, criminal_key)
	local my_data = data.internal_data
	if my_data.tasing and criminal_key == my_data.tasing.target_u_data.unit:key() then
		if not my_data.tasing.target_u_data.unit:movement():tased() then
			CopLogicAttack.on_criminal_neutralized(data, criminal_key)
			TaserLogicAttack._cancel_tase_attempt(data, my_data)
		end
	else
		CopLogicAttack.on_criminal_neutralized(data, criminal_key)
	end
end
function TaserLogicAttack.on_detected_enemy_destroyed(data, enemy_unit)
	CopLogicAttack.on_detected_enemy_destroyed(data, enemy_unit)
	local my_data = data.internal_data
	if my_data.tasing and enemy_unit:key() == my_data.tasing.target_u_data.unit:key() then
		TaserLogicAttack._cancel_tase_attempt(data, my_data)
	end
end
function TaserLogicAttack.damage_clbk(data, damage_info)
	CopLogicIdle.damage_clbk(data, damage_info)
end
function TaserLogicAttack._chk_reaction_to_criminal(data, key_criminal, criminal_data, stationary)
	local my_data = data.internal_data
	local record = managers.groupai:state():criminal_record(key_criminal)
	local visible = criminal_data.verified
	local can_tase = not criminal_data.unit:chk_action_forbidden("hurt") and data.t > data.tase_delay_t and criminal_data.verified and criminal_data.verified_dis < my_data.tase_distance * 0.9
	local assault_mode = managers.groupai:state():get_assault_mode()
	local can_arrest = not data.char_tweak.no_arrest
	if record.is_deployable then
		return "assault"
	elseif data.t < record.arrest_timeout then
		return can_tase and "tase" or "assault"
	end
	local u_criminal = criminal_data.unit
	if record.status == "disabled" then
		if record.assault_t - record.disabled_t > 0.6 and (record.engaged_force < 25 or CopLogicIdle._am_i_important_to_player(record, data.key)) then
			return "assault"
		end
	elseif record.being_arrested then
		if can_arrest then
			if record.being_disarmed then
				if not assault_mode and table.size(record.being_arrested) < 4 and visible and mvector3.distance(u_criminal:movement():m_pos(), data.m_pos) < 2000 then
					return "arrest"
				end
			elseif not stationary then
				return "disarm"
			end
		end
	elseif record.engaged_force == 0 and data.t - record.assault_t > 10 then
		if not assault_mode and can_arrest and visible and mvector3.distance(u_criminal:movement():m_pos(), data.m_pos) < 2000 then
			return "arrest"
		elseif record.engaged_force < 25 or data.important then
			return can_tase and "tase" or "assault"
		end
	else
		local criminal_fwd = u_criminal:movement():m_head_rot():y()
		local criminal_vec = data.m_pos - u_criminal:movement():m_pos()
		mvector3.normalize(criminal_vec)
		local criminal_look_dot = mvector3.dot(criminal_vec, criminal_fwd)
		if can_arrest and criminal_look_dot < 0 then
			if assault_mode and visible and mvector3.distance(u_criminal:movement():m_pos(), data.m_pos) < 2000 then
				return "arrest"
			elseif record.engaged_force < 25 or data.important then
				return can_tase and "tase" or "assault"
			end
		else
			return can_tase and "tase" or "assault"
		end
	end
end
function TaserLogicAttack._chk_play_charge_weapon_sound(data, my_data, focus_enemy)
	if not my_data.tasing and (not my_data.last_charge_snd_play_t or data.t - my_data.last_charge_snd_play_t > 30) and focus_enemy.verified_dis < 2000 and math.abs(data.m_pos.z - focus_enemy.m_pos.z) < 300 then
		my_data.last_charge_snd_play_t = data.t
		data.unit:sound():play("taser_charge", nil, true)
	end
end
