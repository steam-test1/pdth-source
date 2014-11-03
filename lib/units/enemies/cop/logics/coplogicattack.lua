local mvec3_set = mvector3.set
local mvec3_set_z = mvector3.set_z
local mvec3_sub = mvector3.subtract
local mvec3_dir = mvector3.direction
local mvec3_dot = mvector3.dot
local mvec3_dis = mvector3.distance
local mvec3_dis_sq = mvector3.distance_sq
local mvec3_lerp = mvector3.lerp
local temp_vec1 = Vector3()
local temp_vec2 = Vector3()
local temp_vec3 = Vector3()
CopLogicAttack = class(CopLogicBase)
function CopLogicAttack.enter(data, new_logic_name, enter_params)
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
		my_data.attention_unit = old_internal_data.attention_unit
		my_data.rsrv_pos = old_internal_data.rsrv_pos or my_data.rsrv_pos
		CopLogicAttack._set_best_cover(data, my_data, old_internal_data.best_cover)
	else
		my_data.suspected_enemies = {}
		my_data.detected_enemies = {}
	end
	local key_str = tostring(data.unit:key())
	my_data.detection_task_key = "CopLogicAttack._update_enemy_detection" .. key_str
	CopLogicBase.queue_task(my_data, my_data.detection_task_key, CopLogicAttack._update_enemy_detection, data, data.t)
	local allowed_actions
	if data.unit:movement():chk_action_forbidden("walk") and data.unit:movement()._active_actions[2] then
		allowed_actions = CopLogicTravel.allowed_transitional_actions_nav_link
		my_data.wants_stop_old_walk_action = true
	else
		allowed_actions = CopLogicTravel.allowed_transitional_actions
	end
	local idle_body_part = CopLogicTravel.reset_actions(data, my_data, old_internal_data, allowed_actions)
	local upper_body_action = data.unit:movement()._active_actions[3]
	if (not upper_body_action or upper_body_action:type() ~= "shoot") and idle_body_part == 1 then
		data.unit:movement():set_stance("hos")
	end
	my_data.attitude = data.objective and data.objective.attitude or "avoid"
	data.unit:brain():set_update_enabled_state(false)
	my_data.update_queue_id = "CopLogicAttack.queued_update" .. key_str
	CopLogicAttack.queue_update(data, my_data)
end
function CopLogicAttack.exit(data, new_logic_name, enter_params)
	CopLogicBase.exit(data, new_logic_name, enter_params)
	local my_data = data.internal_data
	data.unit:brain():cancel_all_pathing_searches()
	CopLogicBase.cancel_queued_tasks(my_data)
	CopLogicBase.cancel_delayed_clbks(my_data)
	if my_data.best_cover then
		managers.navigation:release_cover(my_data.best_cover[1])
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
function CopLogicAttack.update(data)
	local my_data = data.internal_data
	if my_data.wants_stop_old_walk_action then
		if not data.unit:movement():chk_action_forbidden("walk") then
			data.unit:movement():action_request({type = "idle", body_part = 2})
			my_data.wants_stop_old_walk_action = nil
		end
		return
	end
	CopLogicAttack._update_cover(data)
	local t = data.t
	local unit = data.unit
	local focus_enemy = my_data.focus_enemy
	local threat_enemy = my_data.threat_enemy
	if not focus_enemy and not threat_enemy then
		local objective = data.objective
		if objective then
			if objective.type == "investigate_area" or objective.type == "defend_area" then
				CopLogicBase._exit(data.unit, "travel")
				return
			elseif objective.guard_obj then
				CopLogicBase._exit(data.unit, "guard")
				return
			else
				CopLogicBase._exit(data.unit, "idle")
				return
			end
		else
			CopLogicBase._exit(data.unit, "idle")
			return
		end
	end
	if CopLogicIdle._chk_relocate(data) then
		return
	end
	CopLogicAttack._process_pathing_results(data, my_data)
	local in_cover = my_data.in_cover
	local best_cover = my_data.best_cover
	if not my_data.processing_cover_path and not my_data.moving_to_cover and not my_data.walking_to_cover_shoot_pos and not my_data.surprised and not my_data.cover_path and best_cover and (not in_cover or best_cover[1] ~= in_cover[1]) then
		CopLogicAttack._cancel_cover_pathing(data, my_data)
		local search_id = tostring(unit:key()) .. "cover"
		if data.unit:brain():search_for_path_to_cover(search_id, best_cover[1], best_cover[5]) then
			my_data.cover_path_search_id = search_id
			my_data.processing_cover_path = best_cover
		end
	end
	local enemy_who_we_want_to_turn_towards = focus_enemy or threat_enemy
	local enemy_visible = enemy_who_we_want_to_turn_towards.verified
	local engage = my_data.attitude == "engage"
	local flank_cover
	local action_taken = my_data.turning or data.unit:movement():chk_action_forbidden("walk") or my_data.moving_to_cover or my_data.walking_to_cover_shoot_pos or my_data.surprised
	if focus_enemy and not my_data.turning and not data.unit:movement():chk_action_forbidden("walk") and not my_data.surprised and focus_enemy.verified and mvector3.distance(focus_enemy.m_pos, data.m_pos) < 600 then
		local from_pos = mvector3.copy(data.m_pos)
		local threat_tracker = focus_enemy.unit:movement():nav_tracker()
		local threat_head_pos = focus_enemy.m_head_pos
		local max_walk_dis = engage and 400 or 1000
		local vis_required = engage
		local retreat_to = CopLogicAttack._find_retreat_position(from_pos, focus_enemy.m_pos, threat_head_pos, threat_tracker, max_walk_dis, vis_required)
		if retreat_to then
			CopLogicAttack._cancel_cover_pathing(data, my_data)
			local new_action_data = {
				type = "walk",
				nav_path = {from_pos, retreat_to},
				variant = "run",
				body_part = 2
			}
			if data.unit:brain():action_request(new_action_data) then
				my_data.surprised = true
				local reservation = {
					position = retreat_to,
					radius = 60,
					filter = data.pos_rsrv_id
				}
				managers.navigation:add_pos_reservation(reservation)
				my_data.rsrv_pos.move_dest = reservation
				if my_data.rsrv_pos.stand then
					managers.navigation:unreserve_pos(my_data.rsrv_pos.stand)
					my_data.rsrv_pos.stand = nil
				end
				action_taken = true
			end
		end
	end
	if not action_taken then
		local move_to_cover
		if data.unit:anim_data().reload then
			if in_cover then
				if not in_cover[4] and in_cover[3] and not unit:anim_data().crouch then
					action_taken = CopLogicAttack._chk_request_action_crouch(data)
				end
			elseif my_data.cover_path and not my_data.flank_cover then
				move_to_cover = true
			end
		elseif my_data.cover_path then
			move_to_cover = true
		end
		if move_to_cover then
			CopLogicAttack._chk_request_action_walk_to_cover(data, my_data)
			action_taken = true
		end
		if not action_taken then
			if engage then
				if focus_enemy then
					if not unit:anim_data().crouch then
						if in_cover and 1 < t - my_data.cover_enter_t and not my_data.cover_sideways_chk and not data.unit:anim_data().reload then
							my_data.cover_sideways_chk = true
							local my_tracker = unit:movement():nav_tracker()
							local shoot_from_pos = CopLogicAttack._peek_for_pos_sideways(data, my_data, my_tracker, focus_enemy.unit:movement():m_pos())
							if shoot_from_pos then
								local my_tracker = unit:movement():nav_tracker()
								local path = {
									my_tracker:position(),
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
												CopLogicAttack._chk_request_action_walk_to_cover_shoot_pos(data, my_data, my_data.flank_path, mvector3.distance(data.m_pos, my_data.flank_pos) > 300 and "run")
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
				end
			else
				my_data.cover_sideways_chk = nil
				CopLogicAttack._cancel_flanking_attempt(data, my_data)
				if enemy_visible or my_data.alert_t and t - my_data.alert_t < 10 then
					if not unit:anim_data().crouch then
						action_taken = CopLogicAttack._chk_request_action_crouch(data)
					end
				elseif unit:anim_data().crouch then
					action_taken = CopLogicAttack._chk_request_action_stand(data)
				end
			end
		end
	end
	if not action_taken then
		local my_tracker = unit:movement():nav_tracker()
		local reservation = {
			position = data.m_pos,
			radius = 30,
			filter = data.pos_rsrv_id
		}
		if not managers.navigation:is_pos_free(reservation) then
			local to_pos = CopLogicTravel._get_pos_on_wall(data.m_pos, 500)
			if to_pos then
				local rsrv_pos = my_data.rsrv_pos
				if rsrv_pos.stand then
					managers.navigation:unreserve_pos(rsrv_pos.stand)
					rsrv_pos.stand = nil
				end
				if rsrv_pos.move_dest then
					managers.navigation:unreserve_pos(rsrv_pos.move_dest)
					rsrv_pos.move_dest = nil
				end
				if rsrv_pos.path then
					managers.navigation:unreserve_pos(rsrv_pos.path)
				end
				local reservation = {
					position = to_pos,
					radius = 60,
					filter = data.pos_rsrv_id
				}
				managers.navigation:add_pos_reservation(reservation)
				rsrv_pos.path = reservation
				local path = {
					my_tracker:position(),
					to_pos
				}
				CopLogicAttack._chk_request_action_walk_to_cover_shoot_pos(data, my_data, path, "run")
			end
		end
	end
end
function CopLogicAttack.queued_update(data)
	local my_data = data.internal_data
	data.t = TimerManager:game():time()
	CopLogicAttack.update(data)
	if data.internal_data == my_data then
		CopLogicAttack.queue_update(data, data.internal_data)
	end
end
function CopLogicAttack._peek_for_pos_sideways(data, my_data, from_racker, peek_to_pos)
	local unit = data.unit
	local my_tracker = from_racker
	local enemy_pos = peek_to_pos
	local my_pos = unit:movement():m_pos()
	local back_vec = my_pos - enemy_pos
	mvector3.set_z(back_vec, 0)
	mvector3.set_length(back_vec, 75)
	local back_pos = my_pos + back_vec
	local ray_params = {
		tracker_from = my_tracker,
		allow_entry = true,
		pos_to = back_pos,
		trace = true
	}
	local ray_res = managers.navigation:raycast(ray_params)
	back_pos = ray_params.trace[1]
	local back_polar = back_pos - my_pos:to_polar()
	local right_polar = back_polar:with_spin(back_polar.spin + 90):with_r(100)
	local right_vec = right_polar:to_vector()
	local right_pos = back_pos + right_vec
	ray_params.pos_to = right_pos
	local ray_res = managers.navigation:raycast(ray_params)
	local shoot_from_pos
	if ray_res then
	else
		local stand_ray = World:raycast("ray", ray_params.trace[1] + math.UP * 150, enemy_pos, "slot_mask", my_data.ai_visibility_slotmask, "ray_type", "ai_vision")
		if not stand_ray then
			shoot_from_pos = ray_params.trace[1]
		end
	end
	if not shoot_from_pos then
		local left_pos = back_pos - right_vec
		ray_params.pos_to = left_pos
		local ray_res = managers.navigation:raycast(ray_params)
		if ray_res then
		else
			local stand_ray = World:raycast("ray", ray_params.trace[1] + math.UP * 150, enemy_pos, "slot_mask", my_data.ai_visibility_slotmask, "ray_type", "ai_vision")
			if not stand_ray then
				shoot_from_pos = ray_params.trace[1]
			end
		end
	end
	return shoot_from_pos
end
function CopLogicAttack._cancel_cover_pathing(data, my_data)
	if my_data.processing_cover_path then
		if data.active_searches[my_data.cover_path_search_id] then
			managers.navigation:cancel_pathing_search(my_data.cover_path_search_id)
			data.active_searches[my_data.cover_path_search_id] = nil
		elseif data.pathing_results then
			data.pathing_results[my_data.cover_path_search_id] = nil
		end
		my_data.processing_cover_path = nil
		my_data.cover_path_search_id = nil
	end
	my_data.cover_path = nil
end
function CopLogicAttack._cancel_flanking_attempt(data, my_data)
	my_data.flank_cover = nil
	my_data.flank_pos = nil
	my_data.flank_path = nil
	if my_data.flank_path_search_id then
		if data.active_searches[my_data.flank_path_search_id] then
			managers.navigation:cancel_pathing_search(my_data.flank_path_search_id)
			data.active_searches[my_data.flank_path_search_id] = nil
		elseif data.pathing_results then
			data.pathing_results[my_data.flank_path_search_id] = nil
		end
		my_data.flank_path_search_id = nil
	end
end
function CopLogicAttack._cancel_expected_pos_path(data, my_data)
	my_data.expected_pos_path = nil
	if my_data.expected_pos_path_search_id then
		if data.active_searches[my_data.expected_pos_path_search_id] then
			managers.navigation:cancel_pathing_search(my_data.expected_pos_path_search_id)
			data.active_searches[my_data.expected_pos_path_search_id] = nil
		elseif data.pathing_results then
			data.pathing_results[my_data.expected_pos_path_search_id] = nil
		end
		my_data.expected_pos_path_search_id = nil
	end
end
function CopLogicAttack._chk_request_action_turn_to_enemy(data, my_data, my_pos, enemy_pos)
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
function CopLogicAttack._cancel_walking_to_cover(data, my_data, skip_action)
	my_data.cover_path = nil
	if my_data.moving_to_cover then
		if not skip_action then
			local new_action = {type = "idle", body_part = 2}
			data.unit:brain():action_request(new_action)
		end
	elseif my_data.processing_cover_path then
		if my_data.rsrv_pos.path then
			managers.navigation:unreserve_pos(my_data.rsrv_pos.path)
			my_data.rsrv_pos.path = nil
		end
		data.unit:brain():cancel_all_pathing_searches()
		my_data.cover_path_search_id = nil
		my_data.processing_cover_path = nil
	end
end
function CopLogicAttack._chk_request_action_walk_to_cover(data, my_data)
	if not data.char_tweak.crouch_move and data.unit:anim_data().crouch then
		CopLogicAttack._chk_request_action_stand(data)
	end
	CopLogicAttack._correct_path_start_pos(data, my_data.cover_path)
	local new_action_data = {
		type = "walk",
		nav_path = my_data.cover_path,
		variant = "run",
		body_part = 2
	}
	my_data.cover_path = nil
	if data.unit:brain():action_request(new_action_data) then
		my_data.moving_to_cover = my_data.best_cover
		my_data.in_cover = nil
		my_data.rsrv_pos.move_dest = my_data.rsrv_pos.path
		my_data.rsrv_pos.path = nil
		if my_data.rsrv_pos.stand then
			managers.navigation:unreserve_pos(my_data.rsrv_pos.stand)
			my_data.rsrv_pos.stand = nil
		end
	end
end
function CopLogicAttack._correct_path_start_pos(data, path)
	local first_nav_point = path[1]
	local my_pos = data.m_pos
	if first_nav_point.x ~= my_pos.x or first_nav_point.y ~= my_pos.y then
		table.insert(path, 1, mvector3.copy(my_pos))
	end
end
function CopLogicAttack._chk_request_action_walk_to_cover_shoot_pos(data, my_data, path, speed)
	if not data.char_tweak.crouch_move and data.unit:anim_data().crouch then
		CopLogicAttack._chk_request_action_stand(data)
	end
	CopLogicAttack._correct_path_start_pos(data, path)
	local new_action_data = {
		type = "walk",
		nav_path = path,
		variant = speed or "walk",
		body_part = 2
	}
	my_data.cover_path = nil
	local res = data.unit:brain():action_request(new_action_data)
	if res then
		my_data.walking_to_cover_shoot_pos = res
		my_data.in_cover = nil
		my_data.rsrv_pos.move_dest = my_data.rsrv_pos.path
		my_data.rsrv_pos.path = nil
		if my_data.rsrv_pos.stand then
			managers.navigation:unreserve_pos(my_data.rsrv_pos.stand)
			my_data.rsrv_pos.stand = nil
		end
	end
end
function CopLogicAttack._chk_request_action_crouch(data)
	if data.unit:movement():chk_action_forbidden("crouch") then
		return
	end
	local new_action_data = {type = "crouch", body_part = 4}
	local res = data.unit:brain():action_request(new_action_data)
	return res
end
function CopLogicAttack._chk_request_action_stand(data)
	if data.unit:movement():chk_action_forbidden("stand") then
		return
	end
	local new_action_data = {type = "stand", body_part = 4}
	local res = data.unit:brain():action_request(new_action_data)
	return res
end
function CopLogicAttack._update_cover(data)
	local my_data = data.internal_data
	local cover_release_dis = 100
	local best_cover = my_data.best_cover
	local satisfied = true
	local my_pos = data.m_pos
	if my_data.focus_enemy then
		local find_new = not my_data.moving_to_cover and not my_data.walking_to_cover_shoot_pos and not my_data.surprised
		if find_new then
			local enemy_tracker = my_data.focus_enemy.unit:movement():nav_tracker()
			local threat_pos = enemy_tracker:field_position()
			if data.objective and data.objective.type == "follow" then
				local near_pos = data.objective.follow_unit:movement():m_pos()
				if (not best_cover or not CopLogicAttack._verify_follow_cover(best_cover[1], near_pos, threat_pos, 200, 1000)) and not my_data.processing_cover_path then
					local found_cover = managers.navigation:find_cover_near_pos_1(near_pos, threat_pos, data.objective.distance * 0.9, 300, true)
					if found_cover then
						satisfied = true
						local better_cover = {found_cover}
						CopLogicAttack._set_best_cover(data, my_data, better_cover)
						local offset_pos, yaw = CopLogicAttack._get_cover_offset_pos(data, better_cover, threat_pos)
						if offset_pos then
							better_cover[5] = offset_pos
							better_cover[6] = yaw
						end
					end
				end
			else
				local flank_cover = my_data.flank_cover
				local min_dis, max_dis
				if my_data.attitude == "engage" then
					min_dis = 400
					max_dis = 1600
				else
					min_dis = 1800
				end
				if (not best_cover or not CopLogicAttack._verify_cover(best_cover[1], threat_pos, min_dis, max_dis) or flank_cover) and not my_data.processing_cover_path then
					satisfied = false
					local my_vec = my_pos - threat_pos
					if flank_cover then
						mvector3.rotate_with(my_vec, Rotation(flank_cover.angle))
					end
					local my_vec_len = my_vec:length()
					local max_dis = my_vec_len + 800
					if my_data.attitude == "engage" then
						if my_vec_len > 600 then
							my_vec_len = 600
							mvector3.set_length(my_vec, my_vec_len)
						end
					elseif my_vec_len < 3000 then
						my_vec_len = my_vec_len + 500
						mvector3.set_length(my_vec, my_vec_len)
					end
					local my_side_pos = threat_pos + my_vec
					mvector3.set_length(my_vec, max_dis)
					local furthest_side_pos = threat_pos + my_vec
					if flank_cover then
						local angle = flank_cover.angle
						local sign = flank_cover.sign
						if math.sign(angle) ~= sign then
							angle = -angle + flank_cover.step * sign
							if math.abs(angle) > 90 then
								flank_cover.failed = true
							else
								flank_cover.angle = angle
							end
						else
							flank_cover.angle = -angle
						end
					end
					if my_side_pos then
						local min_threat_dis = 750
						local cone_angle
						if flank_cover then
							cone_angle = flank_cover.step
						else
							cone_angle = math.lerp(90, 30, math.min(1, my_vec_len / 3000))
						end
						local search_nav_seg
						if data.objective and data.objective.type == "defend_area" then
							search_nav_seg = data.objective.nav_seg
						end
						local found_cover = managers.navigation:find_cover_in_cone_from_threat_pos_1(threat_pos, furthest_side_pos, my_side_pos, nil, cone_angle, min_threat_dis, search_nav_seg)
						if found_cover and (not best_cover or CopLogicAttack._verify_cover(found_cover, threat_pos, min_dis, max_dis)) then
							satisfied = true
							local better_cover = {found_cover}
							CopLogicAttack._set_best_cover(data, my_data, better_cover)
							local offset_pos, yaw = CopLogicAttack._get_cover_offset_pos(data, better_cover, threat_pos)
							if offset_pos then
								better_cover[5] = offset_pos
								better_cover[6] = yaw
							end
						end
					end
				end
			end
		end
		local in_cover = my_data.in_cover
		if in_cover and my_data.focus_enemy then
			local threat_pos = my_data.focus_enemy.verified_pos
			in_cover[3], in_cover[4] = CopLogicAttack._chk_covered(data, my_pos, threat_pos, my_data.ai_visibility_slotmask)
		end
	elseif best_cover and cover_release_dis < mvector3.distance(best_cover[1][1], my_pos) then
		CopLogicAttack._set_best_cover(data, my_data, nil)
	end
end
function CopLogicAttack._verify_cover(cover, threat_pos, min_dis, max_dis)
	local threat_dis = mvector3.direction(temp_vec1, cover[1], threat_pos)
	if min_dis and min_dis > threat_dis or max_dis and max_dis < threat_dis then
		return
	end
	local cover_dot = mvector3.dot(temp_vec1, cover[2])
	if cover_dot < 0.67 then
		return
	end
	return true
end
function CopLogicAttack._verify_follow_cover(cover, near_pos, threat_pos, min_dis, max_dis)
	if CopLogicAttack._verify_cover(cover, threat_pos, min_dis, max_dis) and mvector3.distance(near_pos, cover[1]) < 600 then
		return true
	end
end
function CopLogicAttack._chk_covered(data, cover_pos, threat_pos, slotmask)
	local ray_from = math.UP * 80
	mvector3.add(ray_from, cover_pos)
	local ray_to_pos = math.step(ray_from, threat_pos, 300)
	local low_ray = World:raycast("ray", ray_from, ray_to_pos, "slot_mask", slotmask)
	local high_ray
	if low_ray then
		mvector3.set_z(ray_from, ray_from.z + 60)
		ray_to_pos = math.step(ray_from, threat_pos, 300)
		high_ray = World:raycast("ray", ray_from, ray_to_pos, "slot_mask", slotmask)
	end
	return low_ray, high_ray
end
function CopLogicAttack._process_pathing_results(data, my_data)
	if data.pathing_results then
		local pathing_results = data.pathing_results
		data.pathing_results = nil
		local path = pathing_results[my_data.cover_path_search_id]
		if path then
			if path ~= "failed" then
				my_data.cover_path = path
			else
				print("[CopLogicAttack._process_pathing_results] cover path failed", data.unit)
			end
			my_data.processing_cover_path = nil
			my_data.cover_path_search_id = nil
		end
		path = pathing_results[my_data.flank_path_search_id]
		if path then
			if path ~= "failed" then
				my_data.flank_path = path
			else
				print("[CopLogicAttack._process_pathing_results] flank path failed", data.unit)
			end
			my_data.flank_path_search_id = nil
		end
		path = pathing_results[my_data.expected_pos_path_search_id]
		if path then
			if path ~= "failed" then
				my_data.expected_pos_path = path
			end
			my_data.expected_pos_path_search_id = nil
		end
	end
end
function CopLogicAttack._get_priority_enemy(data, enemies, reaction_func)
	reaction_func = reaction_func or CopLogicIdle._chk_reaction_to_criminal
	local best_target, best_target_priority_slot, best_target_priority, best_threat, best_threat_priority_slot, best_threat_priority
	for key, enemy_data in pairs(enemies) do
		local record = managers.groupai:state():criminal_record(key)
		if not record then
			debug_pause("Invalid criminal in detected_enemies!", key)
		else
			local enemy_vec = mvector3.copy(enemy_data.m_pos)
			mvector3.subtract(enemy_vec, data.m_pos)
			local distance = mvector3.normalize(enemy_vec)
			local reaction = reaction_func(data, key, enemy_data, not CopLogicAttack._can_move(data))
			local alert_dt = enemy_data.alert_t and data.t - enemy_data.alert_t or 10000
			local dmg_dt = enemy_data.dmg_t and data.t - enemy_data.dmg_t or 10000
			local status = record.status
			local nr_enemies = record.engaged_force
			local near_threshold = data.char_tweak.weapon_range
			if data.internal_data.focus_enemy and data.internal_data.focus_enemy.unit:key() == key then
				alert_dt = alert_dt * 0.8
				dmg_dt = dmg_dt * 0.8
				distance = distance * 0.8
			end
			local assault_reaction = reaction == "tase"
			local visible = enemy_data.verified
			local near = near_threshold > distance
			local too_near = distance < 700 and math.abs(enemy_data.m_pos.z - data.m_pos.z) < 250
			local free_status = status == nil
			local has_alerted = alert_dt < 3.5
			local has_damaged = dmg_dt < 5
			local reviving = not enemy_data.is_deployable and enemy_data.unit:anim_data().revive
			if enemy_data.unit:key() == managers.player:player_unit() and managers.player:player_unit():key() then
				local iparams = enemy_data.unit:movement():current_state()._interact_params
				if managers.criminals:character_name_by_unit(iparams.object) ~= nil then
					reviving = true
				end
			end
			local target_priority = distance
			local target_priority_slot = 0
			if visible and not reviving then
				if free_status then
					if too_near then
						target_priority_slot = 1
					elseif near then
						target_priority_slot = 2
					elseif assault_reaction then
						target_priority_slot = 3
					else
						target_priority_slot = 4
					end
				elseif has_damaged then
					if near then
						target_priority_slot = 3
					else
						target_priority_slot = 5
					end
				elseif has_alerted then
					target_priority_slot = 6
				end
			elseif free_status then
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
			local threat_priority = distance * (1 + 0.1 * nr_enemies)
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
	end
	return best_target, best_target, best_target_priority_slot, best_target_priority_slot
end
function CopLogicAttack._update_enemy_detection(data)
	managers.groupai:state():on_unit_detection_updated(data.unit)
	data.t = TimerManager:game():time()
	local my_data = data.internal_data
	local focus_enemy_verified, focus_enemy_verified_t
	if my_data.focus_enemy then
		focus_enemy_verified = my_data.focus_enemy.verified
		focus_enemy_verified_t = my_data.focus_enemy.verified_t
	end
	local delay = CopLogicAttack._detect_enemies(data, my_data)
	local focus_enemy, focus_type, focus_enemy_key, threat_enemy
	local enemies = my_data.detected_enemies
	local target, threat, target_prio_slot = CopLogicAttack._get_priority_enemy(data, enemies)
	if target then
		focus_enemy = target.enemy_data
		focus_type = target.reaction
		focus_enemy_key = target.key
	end
	if threat then
		threat_enemy = threat.enemy_data
	end
	if focus_enemy then
		local t_since_detected = data.t - managers.groupai:state():criminal_record(focus_enemy_key).det_t
		if my_data.focus_enemy then
			if my_data.focus_enemy.unit:key() ~= focus_enemy_key then
				managers.groupai:state():on_enemy_disengaging(data.unit, my_data.focus_enemy.unit:key())
				managers.groupai:state():on_enemy_engaging(data.unit, focus_enemy_key)
				CopLogicAttack._cancel_flanking_attempt(data, my_data)
				if not data.unit:movement():chk_action_forbidden("walk") then
					CopLogicAttack._cancel_walking_to_cover(data, my_data)
				end
				CopLogicAttack._set_best_cover(data, my_data, nil)
				if not focus_enemy.is_deployable and focus_type == "assault" and focus_enemy.verified and t_since_detected > 15 then
					data.unit:sound():say("_c01x_plu", true)
					CopLogicAttack.dodge_attempt(data, "on_contact")
				end
			else
				local t_since_verified = focus_enemy_verified_t and data.t - focus_enemy_verified_t or 1000
				if focus_type == "assault" and focus_enemy.verified and not focus_enemy_verified and t_since_verified > 5 and t_since_detected > 2 then
					if not focus_enemy.is_deployable then
						data.unit:sound():say("_c01x_plu", true)
					end
					CopLogicAttack.dodge_attempt(data, "on_contact")
				end
			end
		else
			managers.groupai:state():on_enemy_engaging(data.unit, focus_enemy_key)
			if focus_type == "assault" and focus_enemy.verified and t_since_detected > 15 and not data.unit:sound():speaking(data.t) and (data.unit:anim_data().idle or data.unit:anim_data().move) then
				if not focus_enemy.is_deployable then
					data.unit:sound():say("_c01x_plu", true)
				end
				CopLogicAttack.dodge_attempt(data, "on_contact")
			end
		end
		if data.char_tweak.chatter.aggressive and focus_enemy.verified_dis < 1200 and focus_enemy.verified_t and data.t - focus_enemy.verified_t < 3 and not data.unit:sound():speaking(data.t) and (data.unit:anim_data().idle or data.unit:anim_data().move) then
			managers.groupai:state():chk_say_enemy_chatter(data.unit, data.m_pos, "aggressive")
		end
	elseif my_data.focus_enemy then
		managers.groupai:state():on_enemy_disengaging(data.unit, my_data.focus_enemy.unit:key())
		CopLogicAttack._cancel_flanking_attempt(data, my_data)
	end
	my_data.focus_enemy = focus_enemy
	my_data.threat_enemy = threat_enemy
	if focus_type ~= "assault" and not data.unit:movement():chk_action_forbidden("walk") then
		if focus_type then
			CopLogicBase._exit(data.unit, focus_type)
		elseif data.objective and (data.objective.type == "defend_area" or data.objective.type == "investigate_area") then
			CopLogicBase._exit(data.unit, "travel")
		elseif not threat_enemy and not managers.groupai:state():on_cop_jobless(data.unit) then
			CopLogicBase._exit(data.unit, "idle")
		end
	end
	if my_data == data.internal_data then
		CopLogicAttack._upd_aim(data, my_data)
		if data.important then
			delay = 0
		else
			delay = 0.5 + delay * 1.5
		end
		CopLogicBase.queue_task(my_data, my_data.detection_task_key, CopLogicAttack._update_enemy_detection, data, delay and data.t + delay, data.important and true)
	end
	CopLogicBase._report_detections(enemies)
end
function CopLogicAttack._confirm_retreat_position(retreat_pos, threat_pos, threat_head_pos, threat_tracker)
	local ray_params = {
		pos_from = retreat_pos,
		tracker_to = threat_tracker,
		trace = true
	}
	local walk_ray_res = managers.navigation:raycast(ray_params)
	if not walk_ray_res then
		return ray_params.trace[1]
	end
	local retreat_head_pos = mvector3.copy(retreat_pos)
	mvector3.add(retreat_head_pos, Vector3(0, 0, 150))
	local slotmask = managers.slot:get_mask("AI_visibility")
	local ray_res = World:raycast("ray", retreat_head_pos, threat_head_pos, "slot_mask", slotmask, "ray_type", "ai_vision")
	if not ray_res then
		return walk_ray_res or ray_params.trace[1]
	end
	return false
end
function CopLogicAttack._find_retreat_position(from_pos, threat_pos, threat_head_pos, threat_tracker, max_dist, vis_required)
	local nav_manager = managers.navigation
	local nr_rays = 5
	local ray_dis = max_dist or 1000
	local step = 180 / nr_rays
	local offset = math.random(step)
	local dir = math.random() < 0.5 and -1 or 1
	step = step * dir
	local step_rot = Rotation(step)
	local offset_rot = Rotation(offset)
	local offset_vec = mvector3.copy(threat_pos)
	mvector3.subtract(offset_vec, from_pos)
	mvector3.normalize(offset_vec)
	mvector3.multiply(offset_vec, ray_dis)
	mvector3.rotate_with(offset_vec, Rotation((90 + offset) * dir))
	local to_pos
	local from_tracker = nav_manager:create_nav_tracker(from_pos)
	local ray_params = {tracker_from = from_tracker, trace = true}
	local rsrv_desc = {radius = 60}
	local fail_position
	repeat
		to_pos = mvector3.copy(from_pos)
		mvector3.add(to_pos, offset_vec)
		ray_params.pos_to = to_pos
		local ray_res = nav_manager:raycast(ray_params)
		if ray_res then
			rsrv_desc.position = ray_params.trace[1]
			local is_free = nav_manager:is_pos_free(rsrv_desc)
			if is_free and (not vis_required or CopLogicAttack._confirm_retreat_position(ray_params.trace[1], threat_pos, threat_head_pos, threat_tracker)) then
				managers.navigation:destroy_nav_tracker(from_tracker)
				return ray_params.trace[1]
			else
			end
		elseif not fail_position then
			rsrv_desc.position = ray_params.trace[1]
			local is_free = nav_manager:is_pos_free(rsrv_desc)
			if is_free then
				fail_position = ray_params.trace[1]
			end
		end
		mvector3.rotate_with(offset_vec, step_rot)
		nr_rays = nr_rays - 1
	until nr_rays == 0
	managers.navigation:destroy_nav_tracker(from_tracker)
	if fail_position then
		return fail_position
	end
	return nil
end
function CopLogicAttack._create_detected_enemy_data(data, enemy_unit)
	local ext_brain = data.unit:brain()
	local destroy_clbk_key = "detected" .. tostring(data.unit:key())
	enemy_unit:base():add_destroy_listener(destroy_clbk_key, callback(ext_brain, ext_brain, "on_detected_enemy_destroyed"))
	local enemy_m_pos = enemy_unit:movement():m_pos()
	local enemy_m_head_pos = enemy_unit:movement():m_head_pos()
	local is_local_player = enemy_unit:base().is_local_player
	local is_husk_player = enemy_unit:base().is_husk_player
	local enemy_data = {
		unit = enemy_unit,
		m_pos = enemy_m_pos,
		m_head_pos = enemy_m_head_pos,
		verified_t = false,
		verified = false,
		verified_pos = mvector3.copy(enemy_m_head_pos),
		verified_dis = mvector3.distance(data.m_pos, enemy_m_pos),
		destroy_clbk_key = destroy_clbk_key,
		is_local_player = is_local_player,
		is_husk_player = is_husk_player,
		is_deployable = enemy_unit:base().sentry_gun
	}
	return enemy_data
end
function CopLogicAttack._detect_enemies(data, my_data)
	local delay = 1
	local criminal_dis = {}
	local t_ins = table.insert
	local my_pos = data.unit:movement():m_head_pos()
	local enemies = managers.groupai:state():whisper_mode() and managers.groupai:state():all_player_criminals() or managers.groupai:state():all_criminals()
	local my_tracker = data.unit:movement():nav_tracker()
	local chk_vis_func = my_tracker.check_visibility
	for e_key, e_data in pairs(enemies) do
		local enemy_unit = e_data.unit
		if enemy_unit:in_slot(my_data.enemy_detect_slotmask) then
			if my_data.detected_enemies[e_key] then
				local enemy_data = my_data.detected_enemies[e_key]
				local visible, vis_ray
				local enemy_pos = temp_vec3
				if enemy_unit:base().is_husk_player and enemy_unit:anim_data().crouch then
					mvector3.set(enemy_pos, enemy_data.m_pos)
					mvector3.add(enemy_pos, tweak_data.player.stances.default.crouched.head.translation)
				else
					mvector3.set(enemy_pos, enemy_data.m_head_pos)
				end
				if chk_vis_func(my_tracker, e_data.tracker) then
					vis_ray = World:raycast("ray", my_pos, enemy_pos, "slot_mask", my_data.ai_visibility_slotmask, "ray_type", "ai_vision", "report")
					if not vis_ray then
						visible = true
					end
				end
				enemy_data.verified = visible
				enemy_data.nearly_visible = nil
				if visible then
					delay = math.min(0.6, delay)
					enemy_data.verified_t = data.t
					mvector3.set(enemy_data.verified_pos, enemy_pos)
					enemy_data.verified_dis = mvec3_dis(enemy_pos, my_pos)
					enemy_data.last_verified_pos = mvector3.copy(enemy_pos)
				else
					local displacement = mvec3_dis(enemy_pos, e_data.pos)
					if displacement > 700 and not managers.groupai:state():is_detection_persistent() then
						enemy_unit:base():remove_destroy_listener(enemy_data.destroy_clbk_key)
						my_data.detected_enemies[e_key] = nil
					else
						delay = math.min(0.2, delay)
						enemy_data.verified_pos = mvector3.copy(e_data.pos)
						enemy_data.verified_dis = mvec3_dis(enemy_pos, my_pos)
					end
					local near_pos
					if vis_ray and enemy_data.verified_dis < 2000 and math.abs(enemy_pos.z - my_pos.z) < 300 then
						near_pos = temp_vec1
						mvec3_set(near_pos, enemy_pos)
						mvec3_set_z(near_pos, near_pos.z + 100)
						local near_vis_ray = World:raycast("ray", my_pos, near_pos, "slot_mask", my_data.ai_visibility_slotmask, "ray_type", "ai_vision", "report")
						if near_vis_ray then
							local side_vec = temp_vec2
							mvec3_set(side_vec, enemy_pos)
							mvec3_sub(side_vec, my_pos)
							mvector3.cross(side_vec, side_vec, math.UP)
							mvector3.set_length(side_vec, 150)
							mvector3.set(near_pos, enemy_pos)
							mvector3.add(near_pos, side_vec)
							local near_vis_ray = World:raycast("ray", my_pos, near_pos, "slot_mask", my_data.ai_visibility_slotmask, "ray_type", "ai_vision", "report")
							if near_vis_ray then
								mvector3.multiply(side_vec, -2)
								mvector3.add(near_pos, side_vec)
								local near_vis_ray = World:raycast("ray", my_pos, near_pos, "slot_mask", my_data.ai_visibility_slotmask, "ray_type", "ai_vision", "report")
								if not near_vis_ray then
									enemy_data.nearly_visible = true
									enemy_data.last_verified_pos = mvector3.copy(near_pos)
								end
							else
								enemy_data.nearly_visible = true
								enemy_data.last_verified_pos = mvector3.copy(near_pos)
							end
						else
							enemy_data.nearly_visible = true
							enemy_data.last_verified_pos = mvector3.copy(near_pos)
						end
					end
				end
			elseif my_data.suspected_enemies[e_key] then
				local suspect_data = my_data.suspected_enemies[e_key]
				local interval_dt = data.t - suspect_data.last_check_t
				suspect_data.last_check_t = data.t
				local visible
				local my_pos = data.unit:movement():m_head_pos()
				local enemy_pos = suspect_data.m_head_pos
				local enemy_vec = enemy_pos - my_pos
				local enemy_dis = mvector3.normalize(enemy_vec)
				local dis_multiplier, angle_multiplier
				dis_multiplier = enemy_dis / my_data.detection.dis_max
				if dis_multiplier < 1 then
					delay = 0
					local my_fwd = data.unit:movement():m_head_rot():z()
					local enemy_dot = mvector3.dot(my_fwd, enemy_vec)
					local enemy_angle = math.acos(enemy_dot)
					local max_angle = math.lerp(180, my_data.detection.angle_max, math.clamp((enemy_dis - 150) / 600, 0, 1))
					angle_multiplier = enemy_angle / max_angle
					if angle_multiplier < 1 and not World:raycast("ray", my_pos, enemy_pos, "slot_mask", my_data.ai_visibility_slotmask, "ray_type", "ai_vision") then
						visible = true
					end
				end
				if visible then
					local total_mult = 1 - math.min(1, dis_multiplier) * math.min(1, angle_multiplier)
					suspect_data.detection_countdown = suspect_data.detection_countdown - interval_dt * total_mult
					if 0 > suspect_data.detection_countdown then
						local enemy_data = CopLogicAttack._create_detected_enemy_data(data, enemy_unit)
						enemy_data.verified_t = data.t
						enemy_data.verified = true
						my_data.detected_enemies[e_key] = enemy_data
						my_data.suspected_enemies[e_key] = nil
					end
				else
					suspect_data.detection_countdown = suspect_data.detection_countdown + interval_dt
					if suspect_data.detection_countdown > suspect_data.initial_detection_countdown then
						my_data.suspected_enemies[e_key] = nil
					end
				end
			else
				local visible
				if chk_vis_func(my_tracker, e_data.tracker, e_data.tracker) then
					local my_pos = data.unit:movement():m_head_pos()
					local enemy_pos = enemy_unit:movement():m_head_pos()
					local enemy_vec = enemy_pos - my_pos
					local enemy_dis = mvector3.normalize(enemy_vec)
					local dis_multiplier, angle_multiplier
					dis_multiplier = enemy_dis / my_data.detection.dis_max
					if dis_multiplier < 1 then
						delay = math.min(delay, dis_multiplier)
						local my_fwd = data.unit:movement():m_head_rot():z()
						local enemy_dot = mvector3.dot(my_fwd, enemy_vec)
						local enemy_angle = math.acos(enemy_dot)
						local max_angle = math.lerp(180, my_data.detection.angle_max, math.clamp((enemy_dis - 150) / 600, 0, 1))
						angle_multiplier = enemy_angle / max_angle
						if angle_multiplier < 1 and not World:raycast("ray", my_pos, enemy_pos, "slot_mask", my_data.ai_visibility_slotmask, "ray_type", "ai_vision") then
							visible = true
						end
					end
				end
				if visible then
					local suspect_data = {}
					suspect_data.unit = enemy_unit
					suspect_data.m_head_pos = e_data.m_det_pos
					suspect_data.initial_detection_countdown = math.random(my_data.detection.delay.min, my_data.detection.delay.max)
					suspect_data.detection_countdown = suspect_data.initial_detection_countdown
					suspect_data.last_check_t = data.t
					my_data.suspected_enemies[e_key] = suspect_data
				end
			end
			if not e_data.ai and not e_data.is_deployable then
				local real_dis = mvec3_dir(temp_vec1, e_data.m_det_pos, my_pos)
				local e_fwd
				if enemy_unit:movement().detect_look_dir then
					e_fwd = enemy_unit:movement():detect_look_dir()
				else
					e_fwd = enemy_unit:movement():m_head_rot():y()
				end
				local dot = mvec3_dot(e_fwd, temp_vec1)
				real_dis = real_dis * real_dis * (1 - dot)
				t_ins(criminal_dis, e_key)
				t_ins(criminal_dis, real_dis)
			end
		end
	end
	managers.groupai:state():report_cop_to_criminal_dis(data.unit, criminal_dis)
	return delay
end
function CopLogicAttack.action_complete_clbk(data, action)
	local my_data = data.internal_data
	local action_type = action:type()
	if action_type == "walk" then
		if action:expired() then
			my_data.rsrv_pos.stand = my_data.rsrv_pos.move_dest
		else
			local reservation = managers.navigation:reserve_pos(data.t, nil, data.m_pos, nil, 60, data.pos_rsrv_id)
			my_data.rsrv_pos.stand = reservation
			if my_data.rsrv_pos.move_dest then
				managers.navigation:unreserve_pos(my_data.rsrv_pos.move_dest)
			end
		end
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
	elseif action_type == "hurt" then
		if action:expired() and not CopLogicAttack.dodge_attempt(data, "on_hurt") then
			CopLogicAttack._upd_aim(data, my_data)
		end
	elseif action_type == "dodge" then
		CopLogicAttack._cancel_cover_pathing(data, my_data)
		if my_data.rsrv_pos.stand then
			managers.navigation:unreserve_pos(my_data.rsrv_pos.stand)
		end
		local reservation = managers.navigation:reserve_pos(data.t, nil, data.m_pos, nil, 60, data.pos_rsrv_id)
		my_data.rsrv_pos.stand = reservation
	end
end
function CopLogicAttack._upd_aim(data, my_data)
	local shoot, aim, expected_pos
	local focus_enemy = my_data.focus_enemy
	if focus_enemy then
		if focus_enemy.verified or focus_enemy.nearly_visible then
			if not my_data.shooting and data.unit:anim_data().run then
				local enemy_vec = temp_vec1
				local dis = mvec3_dir(enemy_vec, data.m_pos, focus_enemy.m_pos)
				if dis > 2000 and mvec3_dot(enemy_vec, data.unit:movement():m_rot():y()) > 0 then
					aim = false
				end
			end
			if aim == nil then
				aim = true
				if focus_enemy.verified then
					if focus_enemy.alert_t and data.t - focus_enemy.alert_t < 7 then
						shoot = true
					elseif my_data.attitude == "engage" then
						if focus_enemy.verified_dis < 2500 then
							shoot = true
						end
					elseif focus_enemy.verified_dis < 1700 then
						shoot = true
					end
				elseif focus_enemy.alert_t and data.t - focus_enemy.alert_t < 3 and data.unit:anim_data().still then
					shoot = true
				end
			end
		elseif focus_enemy.verified_t then
			if data.t - focus_enemy.verified_t < 4 and focus_enemy.verified_dis < 800 and math.abs(focus_enemy.verified_pos.z - data.m_pos.z) < 250 then
				aim = true
				if my_data.shooting and 3 > data.t - focus_enemy.verified_t then
					shoot = true
				end
			else
				expected_pos = CopLogicAttack._get_expected_attention_position(data, my_data)
				if expected_pos then
					aim = true
				elseif data.t - focus_enemy.verified_t < 20 or focus_enemy.verified_dis < 1000 then
					aim = true
					if my_data.shooting and 3 > data.t - focus_enemy.verified_t then
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
	if data.logic.chk_should_turn(data, my_data) then
		local enemy_who_we_want_to_turn_towards = focus_enemy or my_data.threat_enemy
		if enemy_who_we_want_to_turn_towards or expected_pos then
			local enemy_pos = expected_pos or (enemy_who_we_want_to_turn_towards.verified or enemy_who_we_want_to_turn_towards.nearly_visible) and enemy_who_we_want_to_turn_towards.m_pos or enemy_who_we_want_to_turn_towards.verified_pos
			CopLogicAttack._chk_request_action_turn_to_enemy(data, my_data, data.m_pos, enemy_pos)
		end
	end
	if aim or shoot then
		if expected_pos then
			if my_data.attention_unit ~= expected_pos then
				CopLogicBase._set_attention_on_pos(data, mvector3.copy(expected_pos))
				my_data.attention_unit = mvector3.copy(expected_pos)
			end
		elseif focus_enemy.verified or focus_enemy.nearly_visible then
			if my_data.attention_unit ~= focus_enemy.unit:key() then
				CopLogicBase._set_attention_on_unit(data, focus_enemy.unit)
				my_data.attention_unit = focus_enemy.unit:key()
			end
		else
			local look_pos = focus_enemy.last_verified_pos or focus_enemy.verified_pos
			if my_data.attention_unit ~= look_pos then
				CopLogicBase._set_attention_on_pos(data, mvector3.copy(look_pos))
				my_data.attention_unit = mvector3.copy(look_pos)
			end
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
function CopLogicAttack.aim_allow_fire(shoot, aim, data, my_data)
	local focus_enemy = my_data.focus_enemy
	if not shoot and aim and focus_enemy.is_husk_player and my_data.firing then
		data.unit:movement():set_allow_fire(false)
		my_data.firing = nil
		my_data.firing_on_client = nil
	end
	if (shoot or aim and (focus_enemy.is_local_player or focus_enemy.is_husk_player)) and my_data.attention_unit == focus_enemy.unit:key() then
		local enemy_key = focus_enemy.unit:key()
		if not shoot and focus_enemy.is_husk_player then
			if my_data.firing_on_client ~= enemy_key then
				data.unit:movement():set_allow_fire_on_client(true, focus_enemy.unit)
				my_data.firing_on_client = enemy_key
			end
		elseif not my_data.firing then
			data.unit:movement():set_allow_fire(true)
			my_data.firing = true
		end
	elseif my_data.firing or my_data.firing_on_client then
		data.unit:movement():set_allow_fire(false)
		my_data.firing = nil
		my_data.firing_on_client = nil
	end
end
function CopLogicAttack.chk_should_turn(data, my_data)
	return not my_data.turning and not data.unit:movement():chk_action_forbidden("walk") and not my_data.moving_to_cover and not my_data.walking_to_cover_shoot_pos and not my_data.surprised
end
function CopLogicAttack._get_cover_offset_pos(data, cover_data, threat_pos)
	local threat_vec = threat_pos - cover_data[1][1]
	mvector3.set_z(threat_vec, 0)
	local threat_polar = threat_vec:to_polar_with_reference(cover_data[1][2], math.UP)
	local threat_spin = threat_polar.spin
	local rot
	if threat_spin < -20 then
		rot = Rotation(90)
	elseif threat_spin > 20 then
		rot = Rotation(-90)
	else
		rot = Rotation(180)
	end
	local offset_pos = mvector3.copy(cover_data[1][2])
	mvector3.rotate_with(offset_pos, rot)
	mvector3.set_length(offset_pos, 25)
	mvector3.add(offset_pos, cover_data[1][1])
	local ray_params = {
		tracker_from = cover_data[1][3],
		pos_to = offset_pos,
		trace = true
	}
	managers.navigation:raycast(ray_params)
	return ray_params.trace[1]
end
function CopLogicAttack._find_flank_pos(data, my_data, flank_tracker, max_dist)
	local pos = flank_tracker:position()
	local vec_to_pos = pos - data.m_pos
	mvector3.set_z(vec_to_pos, 0)
	local max_dis = max_dist or 1500
	mvector3.set_length(vec_to_pos, max_dis)
	local accross_positions = managers.navigation:find_walls_accross_tracker(flank_tracker, vec_to_pos, 160, 5)
	if accross_positions then
		local optimal_dis = max_dis
		local best_error_dis, best_pos, best_is_hit, best_is_miss, best_has_too_much_error
		for _, accross_pos in ipairs(accross_positions) do
			local error_dis = math.abs(mvector3.distance(accross_pos[1], pos) - optimal_dis)
			local too_much_error = error_dis / optimal_dis > 0.2
			local is_hit = accross_pos[2]
			if best_is_hit then
				if is_hit then
					if best_error_dis > error_dis then
						local reservation = {
							position = accross_pos[1],
							radius = 30,
							filter = data.pos_rsrv_id
						}
						if managers.navigation:is_pos_free(reservation) then
							best_pos = accross_pos[1]
							best_error_dis = error_dis
							best_has_too_much_error = too_much_error
						end
					end
				elseif best_has_too_much_error then
					local reservation = {
						position = accross_pos[1],
						radius = 30,
						filter = data.pos_rsrv_id
					}
					if managers.navigation:is_pos_free(reservation) then
						best_pos = accross_pos[1]
						best_error_dis = error_dis
						best_is_miss = true
						best_is_hit = nil
					end
				end
			elseif best_is_miss then
				if not too_much_error then
					local reservation = {
						position = accross_pos[1],
						radius = 30,
						filter = data.pos_rsrv_id
					}
					if managers.navigation:is_pos_free(reservation) then
						best_pos = accross_pos[1]
						best_error_dis = error_dis
						best_has_too_much_error = nil
						best_is_miss = nil
						best_is_hit = true
					end
				end
			else
				local reservation = {
					position = accross_pos[1],
					radius = 30,
					filter = data.pos_rsrv_id
				}
				if managers.navigation:is_pos_free(reservation) then
					best_pos = accross_pos[1]
					best_is_hit = is_hit
					best_is_miss = not is_hit
					best_has_too_much_error = too_much_error
					best_error_dis = error_dis
				end
			end
		end
		return best_pos
	end
end
function CopLogicAttack.damage_clbk(data, damage_info)
	CopLogicIdle.damage_clbk(data, damage_info)
end
function CopLogicAttack.death_clbk(data, damage_info)
	local my_data = data.internal_data
	if my_data.focus_enemy then
		managers.groupai:state():on_enemy_disengaging(data.unit, my_data.focus_enemy.unit:key())
		my_data.focus_enemy = nil
	end
end
function CopLogicAttack.can_deactivate(data)
	return false
end
function CopLogicAttack.is_available_for_assignment(data, new_objective)
	local my_data = data.internal_data
	if my_data.exiting then
		return
	end
	if data.unit:movement():chk_action_forbidden("walk") then
		return
	end
	if not my_data.focus_enemy then
		return true
	end
	if not new_objective or new_objective.type == "free" then
		return true
	end
	if my_data.focus_enemy.verified then
		return
	end
	if my_data.focus_enemy.verified_dis < 1500 and math.abs(my_data.focus_enemy.m_pos.z - data.m_pos.z) < 300 then
		return
	end
	if my_data.threat_enemy and 1500 > my_data.threat_enemy.verified_dis and 300 > math.abs(my_data.threat_enemy.m_pos.z - data.m_pos.z) then
		return
	end
	if not my_data.focus_enemy.verified_t then
		return true
	end
	if data.t - my_data.focus_enemy.verified_t > 10 then
		return true
	end
end
function CopLogicAttack.is_obstructed(data, objective)
	local my_data = data.internal_data
	if my_data.focus_enemy then
		local enemy_dis = my_data.focus_enemy.verified and my_data.focus_enemy.verified_dis or mvector3.distance(my_data.focus_enemy.m_pos, data.m_pos)
		local min_dis = my_data.focus_enemy.verified and 500 or my_data.focus_enemy.verified_t and 400 or 300
		if enemy_dis < min_dis and math.abs(my_data.focus_enemy.m_pos.z - data.m_pos.z) < 250 then
			return true
		end
		if my_data.focus_enemy.dmg_t and data.t - my_data.focus_enemy.dmg_t < 5 then
			if data.unit:character_damage():health_ratio() < (objective and objective.interrupt_dmg_ratio or 1) then
				return true
			end
		end
	end
	return false
end
function CopLogicAttack.on_detected_enemy_destroyed(data, enemy_unit)
	CopLogicIdle.on_detected_enemy_destroyed(data, enemy_unit)
	local my_data = data.internal_data
	if my_data.focus_enemy and my_data.focus_enemy.unit:key() == enemy_unit:key() then
		my_data.focus_enemy = nil
		if my_data.firing or my_data.firing_on_client then
			data.unit:movement():set_allow_fire(false)
			my_data.firing = nil
			my_data.firing_on_client = nil
		end
	elseif my_data.threat_enemy and my_data.threat_enemy.unit:key() == enemy_unit:key() then
		my_data.threat_enemy = nil
	end
end
function CopLogicAttack.on_criminal_neutralized(data, criminal_key)
	CopLogicIdle.on_criminal_neutralized(data, criminal_key)
	local my_data = data.internal_data
	if my_data.focus_enemy and my_data.focus_enemy.unit:key() == criminal_key then
		if my_data.attention_unit and my_data.attention_unit == criminal_key then
			CopLogicBase._set_attention_on_pos(data, mvector3.copy(my_data.focus_enemy.verified_pos))
			my_data.attention_unit = mvector3.copy(my_data.focus_enemy.verified_pos)
		end
		managers.groupai:state():on_enemy_disengaging(data.unit, criminal_key)
		my_data.focus_enemy = nil
		if my_data.firing or my_data.firing_on_client then
			data.unit:movement():set_allow_fire(false)
			my_data.firing = nil
			my_data.firing_on_client = nil
		end
	elseif my_data.threat_enemy and my_data.threat_enemy.unit:key() == criminal_key then
		my_data.threat_enemy = nil
	end
end
function CopLogicAttack.on_alert(...)
	CopLogicIdle.on_alert(...)
end
function CopLogicAttack._needs_cover(data, my_data, focus_enemy)
	if data.unit:anim_data().reload and (not my_data.in_cover or not my_data.in_cover[4]) then
		return true
	end
	if my_data.attitude ~= "engage" then
		return true
	end
	if focus_enemy and my_data.best_cover then
		local cover_dis = mvector3.distance(my_data.best_cover[1][1], focus_enemy.m_head_pos)
		if my_data.attitude == "engage" then
			if cover_dis > 400 and focus_enemy.verified_dis - cover_dis > 300 then
				return true
			end
		elseif cover_dis - focus_enemy.verified_dis > 300 then
			return true
		end
	end
end
function CopLogicAttack.on_intimidated(data, amount, aggressor_unit)
	CopLogicIdle.on_intimidated(data, amount, aggressor_unit)
end
function CopLogicAttack._set_best_cover(data, my_data, cover_data)
	local best_cover = my_data.best_cover
	if best_cover then
		managers.navigation:release_cover(best_cover[1])
		CopLogicAttack._cancel_cover_pathing(data, my_data)
	end
	if cover_data then
		managers.navigation:reserve_cover(cover_data[1], data.pos_rsrv_id)
		my_data.best_cover = cover_data
	else
		my_data.best_cover = nil
		my_data.flank_cover = nil
	end
end
function CopLogicAttack._set_nearest_cover(my_data, cover_data)
	local nearest_cover = my_data.nearest_cover
	if nearest_cover then
		managers.navigation:release_cover(nearest_cover[1])
	end
	if cover_data then
		local pos_rsrv_id = my_data.unit:movement():pos_rsrv_id()
		managers.navigation:reserve_cover(cover_data[1], pos_rsrv_id)
		my_data.nearest_cover = cover_data
	else
		my_data.nearest_cover = nil
	end
end
function CopLogicAttack._can_move(data)
	return not data.objective or not data.objective.in_place
end
function CopLogicAttack.on_new_objective(data, old_objective)
	CopLogicIdle.on_new_objective(data, old_objective)
end
function CopLogicAttack.queue_update(data, my_data)
	CopLogicBase.queue_task(my_data, my_data.update_queue_id, CopLogicAttack.queued_update, data, data.t + (data.important and 0.5 or 2), true)
end
function CopLogicAttack.dodge(data, hipshot)
	return CopLogicAttack.dodge_attempt(data, hipshot and "on_hit" or "scared")
end
function CopLogicAttack.dodge_attempt(data, dodge_type)
	if data.unit:movement():chk_action_forbidden("walk") then
		return
	end
	local action_data = CopLogicIdle.try_dodge(data, dodge_type)
	if action_data then
		local my_data = data.internal_data
		CopLogicAttack._cancel_cover_pathing(data, my_data)
		CopLogicAttack._cancel_flanking_attempt(data, my_data)
		CopLogicAttack._cancel_expected_pos_path(data, my_data)
		CopLogicAttack._cancel_walking_to_cover(data, my_data, true)
		if my_data.rsrv_pos.stand then
			managers.navigation:unreserve_pos(my_data.rsrv_pos.stand)
			my_data.rsrv_pos.stand = nil
		end
		return action_data
	end
	return nil
end
function CopLogicAttack._get_expected_attention_position(data, my_data)
	local my_nav_seg = data.unit:movement():nav_tracker():nav_segment()
	local main_enemy = my_data.focus_enemy or my_data.threat_enemy
	local e_pos = main_enemy.m_pos
	local e_nav_tracker = main_enemy.unit:movement():nav_tracker()
	local e_nav_seg = e_nav_tracker:nav_segment()
	if e_nav_seg == my_nav_seg then
		mvec3_set(temp_vec1, e_pos)
		mvec3_set_z(temp_vec1, temp_vec1.z + 140)
		return temp_vec1
	end
	local expected_path = my_data.expected_pos_path
	local from_nav_seg, to_nav_seg
	if expected_path then
		local i_from_seg
		for i, k in ipairs(expected_path) do
			if k[1] == my_nav_seg then
				i_from_seg = i
			else
			end
		end
		if i_from_seg then
			local function _find_aim_pos(from_nav_seg, to_nav_seg)
				local closest_dis = 1000000000
				local closest_door
				local min_point_dis_sq = 10000
				local found_doors = managers.navigation:find_segment_doors(from_nav_seg, callback(CopLogicAttack, CopLogicAttack, "_chk_is_right_segment", to_nav_seg))
				for _, door in pairs(found_doors) do
					mvec3_set(temp_vec1, door.center)
					local dis = mvec3_dis_sq(e_pos, temp_vec1)
					if closest_dis > dis then
						closest_dis = dis
						closest_door = door
					end
				end
				if closest_door then
					mvec3_set(temp_vec1, closest_door.center)
					mvec3_sub(temp_vec1, data.m_pos)
					mvec3_set_z(temp_vec1, 0)
					if min_point_dis_sq < mvector3.length_sq(temp_vec1) then
						mvec3_set(temp_vec1, closest_door.center)
						mvec3_set_z(temp_vec1, temp_vec1.z + 140)
						return temp_vec1
					else
						return false, true
					end
				end
			end
			local i = #expected_path
			while i > 0 do
				if expected_path[i][1] == e_nav_seg then
					to_nav_seg = expected_path[math.clamp(i, i_from_seg - 1, i_from_seg + 1)][1]
					local aim_pos, too_close = _find_aim_pos(my_nav_seg, to_nav_seg)
					if aim_pos then
						do return aim_pos end
						break
					end
					if too_close then
						local next_nav_seg = expected_path[math.clamp(i, i_from_seg - 2, i_from_seg + 2)][1]
						if next_nav_seg ~= to_nav_seg then
							local from_nav_seg = to_nav_seg
							to_nav_seg = next_nav_seg
							aim_pos = _find_aim_pos(from_nav_seg, to_nav_seg)
						end
						return aim_pos
					end
					break
				end
				i = i - 1
			end
		end
		if not i_from_seg or not to_nav_seg then
			expected_path = nil
			my_data.expected_pos_path = nil
		end
	end
	if not expected_path and not my_data.expected_pos_path_search_id then
		my_data.expected_pos_path_search_id = "ExpectedPos" .. tostring(data.key)
		data.unit:brain():search_for_coarse_path(my_data.expected_pos_path_search_id, e_nav_seg)
	end
end
function CopLogicAttack._chk_is_right_segment(ignore_this, enemy_nav_seg, test_nav_seg)
	return enemy_nav_seg == test_nav_seg
end
function CopLogicAttack.is_advancing(data)
	if data.internal_data.moving_to_cover then
		return data.internal_data.moving_to_cover[1][1]
	end
	if data.internal_data.walking_to_cover_shoot_pos then
		return data.internal_data.walking_to_cover_shoot_pos._last_pos
	end
end
function CopLogicAttack._get_all_paths(data)
	return {
		cover_path = data.internal_data.cover_path,
		flank_path = data.internal_data.flank_path
	}
end
function CopLogicAttack._set_verified_paths(data, verified_paths)
	data.internal_data.cover_path = verified_paths.cover_path
	data.internal_data.flank_path = verified_paths.flank_path
end
