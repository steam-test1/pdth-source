SpoocLogicAttack = class(CopLogicAttack)
function SpoocLogicAttack.enter(data, new_logic_name, enter_params)
	CopLogicBase.enter(data, new_logic_name, enter_params)
	data.unit:brain():cancel_all_pathing_searches()
	local old_internal_data = data.internal_data
	local my_data = {
		unit = data.unit
	}
	data.internal_data = my_data
	my_data.ai_visibility_slotmask = managers.slot:get_mask("AI_visibility")
	my_data.detection = tweak_data.character[data.unit:base()._tweak_table].detection.combat
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
	my_data.update_task_key = "SpoocLogicAttack.queued_update" .. key_str
	CopLogicBase.queue_task(my_data, my_data.update_task_key, SpoocLogicAttack.queued_update, data, data.t)
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
end
function SpoocLogicAttack.exit(data, new_logic_name, enter_params)
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
function SpoocLogicAttack.queued_update(data)
	if CopLogicIdle._chk_relocate(data) then
		return
	end
	CopLogicAttack._update_cover(data)
	local t = TimerManager:game():time()
	data.t = t
	local unit = data.unit
	local my_data = data.internal_data
	local objective = data.objective
	SpoocLogicAttack._upd_enemy_detection(data)
	if my_data.spooc_attack then
		CopLogicBase._report_detections(my_data.detected_enemies)
		CopLogicBase.queue_task(my_data, my_data.update_task_key, SpoocLogicAttack.queued_update, data, data.t + 2)
		return
	end
	local focus_type = my_data.focus_type
	if focus_type ~= "assault" then
		my_data.update_task_key = nil
		if focus_type then
			CopLogicBase._exit(data.unit, focus_type)
		elseif data.objective then
			CopLogicBase._exit(data.unit, "idle")
			CopLogicIdle.on_new_objective(data, nil)
		elseif not managers.groupai:state():on_cop_jobless(data.unit) then
			CopLogicBase._exit(data.unit, "idle", {scan = true})
		end
		CopLogicBase._report_detections(my_data.detected_enemies)
		return
	end
	local focus_enemy = my_data.focus_enemy
	local requeue_delay = 0
	CopLogicAttack._process_pathing_results(data, my_data)
	local in_cover = my_data.in_cover
	local best_cover = my_data.best_cover
	if not my_data.processing_cover_path and not my_data.moving_to_cover and not my_data.walking_to_cover_shoot_pos and not my_data.spooc_attack and not my_data.acting and best_cover and (not in_cover or best_cover[1] ~= in_cover[1]) then
		CopLogicAttack._cancel_cover_pathing(data, my_data)
		local search_id = tostring(unit:key()) .. "cover"
		if data.unit:brain():search_for_path_to_cover(search_id, best_cover[1], best_cover[5]) then
			my_data.cover_path_search_id = search_id
			my_data.processing_cover_path = my_data.best_cover
		end
	end
	local enemy_visible = focus_enemy.verified
	local engage = my_data.attitude == "engage"
	local flank_cover
	local action_taken = my_data.turning or data.unit:movement():chk_action_forbidden("walk") or my_data.moving_to_cover or my_data.walking_to_cover_shoot_pos or my_data.spooc_attack or my_data.acting
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
			action_taken = CopLogicAttack._chk_request_action_turn_to_enemy(data, my_data, unit:movement():m_pos(), enemy_pos)
		end
		if not action_taken then
			if engage then
				if enemy_visible then
					my_data.cover_sideways_chk = nil
					CopLogicAttack._cancel_flanking_attempt(data, my_data)
					action_taken = SpoocLogicAttack._upd_spooc_attack(data, my_data)
				elseif not unit:anim_data().crouch then
					if in_cover and 1 < t - my_data.cover_enter_t and not my_data.cover_sideways_chk and not data.unit:anim_data().reload then
						my_data.cover_sideways_chk = true
						local my_tracker = unit:movement():nav_tracker()
						local shoot_from_pos = CopLogicAttack._peek_for_pos_sideways(data, my_data, my_tracker, focus_enemy.unit:movement():m_pos())
						if shoot_from_pos then
							local my_tracker = unit:movement():nav_tracker()
							local path = {
								mvector3.copy(my_tracker.pos),
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
				action_taken = SpoocLogicAttack._upd_spooc_attack(data, my_data)
				if not action_taken and (enemy_visible or my_data.under_fire) and not unit:anim_data().crouch then
					action_taken = CopLogicAttack._chk_request_action_crouch(data)
				end
			end
		end
	end
	SpoocLogicAttack._upd_aim(data, my_data)
	CopLogicBase.queue_task(my_data, my_data.update_task_key, SpoocLogicAttack.queued_update, data, data.t + requeue_delay)
	CopLogicBase._report_detections(my_data.detected_enemies)
end
function SpoocLogicAttack._upd_enemy_detection(data)
	managers.groupai:state():on_unit_detection_updated(data.unit)
	local my_data = data.internal_data
	local delay = CopLogicAttack._detect_enemies(data, my_data)
	local focus_enemy, focus_type, focus_enemy_dis, focus_enemy_key, focus_enemy_verified, under_fire
	local dmg_chk_t = data.t - 1.5
	local target = CopLogicAttack._get_priority_enemy(data, my_data.detected_enemies)
	if target then
		focus_enemy = target.enemy_data
		focus_type = target.reaction
		focus_enemy_key = target.key
		focus_enemy_dis = focus_enemy.verified_dis
		focus_enemy_verified = focus_enemy.verified
		if focus_enemy.verified and focus_enemy.dmg_t and dmg_chk_t < focus_enemy.dmg_t then
			under_fire = true
		end
	end
	my_data.under_fire = under_fire
	if focus_enemy then
		if my_data.focus_enemy then
			if my_data.focus_enemy.unit:key() ~= focus_enemy_key then
				managers.groupai:state():on_enemy_disengaging(data.unit, my_data.focus_enemy.unit:key())
				managers.groupai:state():on_enemy_engaging(data.unit, focus_enemy_key)
				CopLogicAttack._cancel_flanking_attempt(data, my_data)
				if not focus_enemy.is_deployable and focus_type == "assault" and focus_enemy.verified and data.t - managers.groupai:state():criminal_record(focus_enemy_key).det_t > 15 then
					data.unit:sound():say("_c01x_plu", true)
				end
			end
		else
			managers.groupai:state():on_enemy_engaging(data.unit, focus_enemy_key)
			if not focus_enemy.is_deployable and focus_type == "assault" and focus_enemy.verified and data.t - managers.groupai:state():criminal_record(focus_enemy_key).det_t > 15 then
				data.unit:sound():say("_c01x_plu", true)
			end
		end
	elseif my_data.focus_enemy then
		managers.groupai:state():on_enemy_disengaging(data.unit, my_data.focus_enemy.unit:key())
		CopLogicAttack._cancel_flanking_attempt(data, my_data)
	end
	my_data.focus_enemy = focus_enemy
	my_data.focus_type = focus_type
end
function SpoocLogicAttack._upd_aim(data, my_data)
	local shoot, aim
	local focus_enemy = my_data.focus_enemy
	if my_data.spooc_attack then
		return
	elseif focus_enemy then
		if focus_enemy.verified then
			if focus_enemy.verified_dis < 2000 or my_data.alert_t and data.t - my_data.alert_t < 7 then
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
function SpoocLogicAttack.action_complete_clbk(data, action)
	local action_type = action:type()
	local my_data = data.internal_data
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
	elseif action_type == "spooc" and my_data.spooc_attack then
		my_data.spooc_attack = nil
	end
end
function SpoocLogicAttack._cancel_spooc_attempt(data, my_data)
	if my_data.spooc_attack then
		local new_action = {type = "idle", body_part = 2}
		data.unit:brain():action_request(new_action)
	end
end
function SpoocLogicAttack._upd_spooc_attack(data, my_data)
	local focus_enemy = my_data.focus_enemy
	local record = managers.groupai:state():criminal_record(focus_enemy.unit:key())
	if not record.is_deployable and not record.status and not my_data.spooc_attack and focus_enemy.verified and focus_enemy.verified_dis < (my_data.attitude == "engage" and 1500 or 900) and not data.unit:movement():chk_action_forbidden("walk") and (not my_data.last_dmg_t or data.t - my_data.last_dmg_t > 0.6) then
		local enemy_tracker = focus_enemy.unit:movement():nav_tracker()
		local ray_params = {
			tracker_from = data.unit:movement():nav_tracker(),
			tracker_to = enemy_tracker,
			trace = true
		}
		if enemy_tracker:lost() then
			ray_params.pos_to = enemy_tracker:field_position()
		end
		local col_ray = managers.navigation:raycast(ray_params)
		if not col_ray then
			local z_diff_abs = math.abs(ray_params.trace[1].z - focus_enemy.m_pos.z)
			if z_diff_abs < 200 and SpoocLogicAttack._chk_request_action_spooc_attack(data, my_data) then
				my_data.spooc_attack = {
					start_t = data.t,
					target_u_data = focus_enemy
				}
				return true
			end
		end
	end
end
function SpoocLogicAttack._chk_request_action_spooc_attack(data, my_data)
	if data.unit:anim_data().crouch then
		CopLogicAttack._chk_request_action_stand(data)
	end
	local new_action = {type = "idle", body_part = 3}
	data.unit:brain():action_request(new_action)
	if my_data.attention_unit ~= my_data.focus_enemy.unit:key() then
		CopLogicBase._set_attention_on_unit(data, my_data.focus_enemy.unit)
		my_data.attention_unit = my_data.focus_enemy.unit:key()
	end
	local new_action_data = {type = "spooc", body_part = 1}
	if data.unit:brain():action_request(new_action_data) then
		if my_data.rsrv_pos.stand then
			managers.navigation:unreserve_pos(my_data.rsrv_pos.stand)
			my_data.rsrv_pos.stand = nil
		end
		return true
	end
end
function SpoocLogicAttack.on_criminal_neutralized(data, criminal_key)
	CopLogicAttack.on_criminal_neutralized(data, criminal_key)
	local my_data = data.internal_data
end
function SpoocLogicAttack.on_detected_enemy_destroyed(data, enemy_unit)
	CopLogicAttack.on_detected_enemy_destroyed(data, enemy_unit)
	local my_data = data.internal_data
end
function SpoocLogicAttack.damage_clbk(data, damage_info)
	data.internal_data.last_dmg_t = TimerManager:game():time()
	CopLogicIdle.damage_clbk(data, damage_info)
end
function SpoocLogicAttack.is_available_for_assignment(data)
	if data.internal_data.spooc_attack then
		return
	end
	return CopLogicAttack.is_available_for_assignment(data)
end
