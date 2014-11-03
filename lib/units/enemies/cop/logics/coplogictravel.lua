CopLogicTravel = class(CopLogicBase)
CopLogicTravel.allowed_transitional_actions = {
	{
		"idle",
		"hurt",
		"dodge"
	},
	{"idle", "turn"},
	{
		"idle",
		"shoot",
		"reload"
	},
	{
		"hurt",
		"stand",
		"crouch"
	}
}
CopLogicTravel.allowed_transitional_actions_nav_link = {
	{
		"idle",
		"hurt",
		"dodge"
	},
	{
		"idle",
		"turn",
		"walk"
	},
	{
		"idle",
		"shoot",
		"reload"
	},
	{
		"hurt",
		"stand",
		"crouch"
	}
}
function CopLogicTravel.enter(data, new_logic_name, enter_params)
	CopLogicBase.enter(data, new_logic_name, enter_params)
	data.unit:brain():cancel_all_pathing_searches()
	local old_internal_data = data.internal_data
	local my_data = {
		unit = data.unit
	}
	my_data.detection = tweak_data.character[data.unit:base()._tweak_table].detection.recon
	my_data.enemy_detect_slotmask = managers.slot:get_mask("criminals")
	my_data.ai_visibility_slotmask = managers.slot:get_mask("AI_visibility")
	my_data.rsrv_pos = {}
	if old_internal_data then
		my_data.suspected_enemies = old_internal_data.suspected_enemies or {}
		my_data.detected_enemies = old_internal_data.detected_enemies or {}
		my_data.focus_enemy = old_internal_data.focus_enemy
		my_data.rsrv_pos = old_internal_data.rsrv_pos or my_data.rsrv_pos
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
	if data.char_tweak.announce_incomming then
		my_data.announce_t = data.t + 2
	end
	data.internal_data = my_data
	local key_str = tostring(data.unit:key())
	my_data.upd_task_key = "CopLogicTravel.queued_update" .. key_str
	CopLogicTravel.queue_update(data, my_data)
	my_data.cover_update_task_key = "CopLogicTravel._update_cover" .. key_str
	if my_data.nearest_cover or my_data.best_cover then
		CopLogicBase.add_delayed_clbk(my_data, my_data.cover_update_task_key, callback(CopLogicTravel, CopLogicTravel, "_update_cover", data), data.t + 1)
	end
	local allowed_actions
	if data.unit:movement():chk_action_forbidden("walk") and data.unit:movement()._active_actions[2] then
		allowed_actions = CopLogicTravel.allowed_transitional_actions_nav_link
		my_data.wants_stop_old_walk_action = true
	else
		allowed_actions = CopLogicTravel.allowed_transitional_actions
	end
	CopLogicTravel.reset_actions(data, my_data, old_internal_data, allowed_actions)
	if data.char_tweak.no_stand and data.unit:anim_data().stand then
		CopLogicAttack._chk_request_action_crouch(data)
	end
	if data.objective.pose then
		if data.objective.pose == "crouch" then
			if not data.unit:anim_data().crouch and not data.unit:anim_data().crouching then
				CopLogicAttack._chk_request_action_crouch(data)
			end
		elseif not data.unit:anim_data().stand then
			CopLogicAttack._chk_request_action_stand(data)
		end
	end
	local objective = data.objective
	if objective then
		local path_data = objective.path_data
		local path_style = objective.path_style
		if path_data then
			if path_style == "precise" then
				local path = {
					mvector3.copy(data.m_pos)
				}
				for _, point in ipairs(path_data.points) do
					table.insert(path, mvector3.copy(point.position))
				end
				my_data.advance_path = path
				my_data.coarse_path_index = 1
				local start_seg = data.unit:movement():nav_tracker():nav_segment()
				local end_pos = mvector3.copy(path[#path])
				local end_seg = managers.navigation:get_nav_seg_from_pos(end_pos)
				my_data.coarse_path = {
					{start_seg},
					{end_seg, end_pos}
				}
				my_data.path_is_precise = true
			elseif path_style == "coarse" then
				my_data.coarse_path_index = 1
				local nav_manager = managers.navigation
				local f_get_nav_seg = nav_manager.get_nav_seg_from_pos
				local start_seg = data.unit:movement():nav_tracker():nav_segment()
				local path = {
					{start_seg}
				}
				for _, point in ipairs(path_data.points) do
					local pos = mvector3.copy(point.position)
					local nav_seg = f_get_nav_seg(nav_manager, pos)
					table.insert(path, {nav_seg, pos})
				end
				my_data.coarse_path = path
			end
		end
		if objective.stance then
			local upper_body_action = data.unit:movement()._active_actions[3]
			if not upper_body_action or upper_body_action:type() ~= "shoot" then
				data.unit:movement():set_stance(objective.stance)
			end
		end
	end
	my_data.interrupt_on = objective and objective.interrupt_on
	data.unit:brain():set_update_enabled_state(false)
end
function CopLogicTravel.reset_actions(data, internal_data, old_internal_data, allowed_actions)
	local busy_body_parts = {
		false,
		false,
		false,
		false
	}
	local active_actions = {}
	for body_part = 1, 4 do
		local active_action = data.unit:movement()._active_actions[body_part]
		if active_action then
			local aa_type = active_action:type()
			for _, allowed_action in ipairs(allowed_actions[body_part]) do
				if aa_type == allowed_action then
					busy_body_parts[body_part] = true
					table.insert(active_actions, aa_type)
				else
				end
			end
		end
	end
	local shoot_interrupted = true
	for _, active_action in ipairs(active_actions) do
		if active_action == "shoot" then
			internal_data.shooting = old_internal_data.shooting
			internal_data.firing = old_internal_data.firing
			shoot_interrupted = false
		elseif active_action == "turn" then
			internal_data.turning = old_internal_data.turning
		end
	end
	if shoot_interrupted then
		data.unit:movement():set_allow_fire(false)
		CopLogicBase._reset_attention(data)
		internal_data.attention_unit = nil
	end
	local idle_body_part
	if busy_body_parts[1] or busy_body_parts[2] and busy_body_parts[3] then
		idle_body_part = 0
	elseif busy_body_parts[2] then
		idle_body_part = 3
	elseif busy_body_parts[3] then
		idle_body_part = 2
	else
		idle_body_part = 1
	end
	if idle_body_part > 0 then
		local new_action = {
			type = "idle",
			body_part = idle_body_part,
			sync = true
		}
		data.unit:brain():action_request(new_action)
	end
	return idle_body_part
end
function CopLogicTravel.exit(data, new_logic_name, enter_params)
	CopLogicBase.exit(data, new_logic_name, enter_params)
	local my_data = data.internal_data
	data.unit:brain():cancel_all_pathing_searches()
	CopLogicBase.cancel_queued_tasks(my_data)
	CopLogicBase.cancel_delayed_clbks(my_data)
	if my_data.moving_to_cover then
		managers.navigation:release_cover(my_data.moving_to_cover[1])
	end
	if my_data.nearest_cover then
		managers.navigation:release_cover(my_data.nearest_cover[1])
	end
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
function CopLogicTravel.queued_update(data)
	local unit = data.unit
	local my_data = data.internal_data
	local objective = data.objective
	local t = TimerManager:game():time()
	data.t = t
	CopLogicTravel._upd_enemy_detection(data)
	if data.internal_data ~= my_data then
		return
	end
	if my_data.wants_stop_old_walk_action then
		if not data.unit:movement():chk_action_forbidden("walk") then
			data.unit:movement():action_request({type = "idle", body_part = 2})
			my_data.wants_stop_old_walk_action = nil
		end
	elseif my_data.advancing then
		if my_data.announce_t and t > my_data.announce_t then
			CopLogicTravel._try_anounce(data, my_data)
		end
	elseif my_data.processing_advance_path or my_data.processing_coarse_path or my_data.cover_leave_t or my_data.advance_path then
	elseif objective and objective.nav_seg then
		if my_data.coarse_path then
			if not data.unit:sound():speaking(data.t) and data.char_tweak.chatter.clear and data.unit:anim_data().idle and (not my_data.focus_enemy or not my_data.focus_enemy.verified_t or not (t - my_data.focus_enemy.verified_t < 10)) then
				managers.groupai:state():chk_say_enemy_chatter(data.unit, data.m_pos, "clear")
			end
			local coarse_path = my_data.coarse_path
			local cur_index = my_data.coarse_path_index
			local total_nav_points = #coarse_path
			if cur_index == total_nav_points then
				objective.in_place = true
				if objective.type == "investigate_area" or objective.type == "free" then
					managers.groupai:state():on_objective_complete(unit, objective)
					return
				elseif objective.type == "defend_area" then
					managers.groupai:state():on_defend_travel_end(unit, objective)
				end
				CopLogicTravel.on_new_objective(data)
				return
			else
				local start_pathing = true
				if data.char_tweak.leader and total_nav_points - cur_index < 4 then
					managers.groupai:state():find_followers_to_unit(data.key, data.char_tweak.leader)
					if managers.groupai:state():are_followers_ready(data.key) then
						if managers.groupai:state():chk_has_followers(data.key) and not data.unit:sound():speaking(t) and data.unit:anim_data().idle and data.char_tweak.chatter.follow_me then
							managers.groupai:state():chk_say_enemy_chatter(data.unit, data.m_pos, "follow_me")
						end
					else
						start_pathing = nil
					end
				else
					managers.groupai:state():dismiss_followers(data.key)
				end
				if start_pathing then
					local to_pos
					if cur_index == total_nav_points - 1 then
						local new_occupation = CopLogicTravel._determine_destination_occupation(data, objective)
						if new_occupation then
							if new_occupation.type == "guard" then
								local guard_door = new_occupation.door
								local guard_pos = CopLogicTravel._get_pos_accross_door(guard_door, objective.nav_seg)
								if guard_pos then
									local reservation = CopLogicTravel._reserve_pos_along_vec(guard_door.center, guard_pos)
									if reservation then
										if my_data.rsrv_pos.path then
											managers.navigation:unreserve_pos(my_data.rsrv_pos.path)
										end
										my_data.rsrv_pos.path = reservation
										local guard_object = {
											type = "door",
											door = guard_door,
											from_seg = new_occupation.from_seg
										}
										objective.guard_obj = guard_object
										to_pos = reservation.pos
									end
								end
							elseif new_occupation.type == "defend" then
								if new_occupation.cover then
									to_pos = new_occupation.cover[1][1]
									managers.navigation:reserve_cover(new_occupation.cover[1], data.pos_rsrv_id)
									my_data.moving_to_cover = new_occupation.cover
								elseif new_occupation.pos then
									to_pos = new_occupation.pos
									local reservation = {
										position = mvector3.copy(to_pos),
										radius = 60,
										filter = data.pos_rsrv_id
									}
									managers.navigation:add_pos_reservation(reservation)
									if my_data.rsrv_pos.path then
										managers.navigation:unreserve_pos(reservation)
									end
									my_data.rsrv_pos.path = reservation
								end
							else
								to_pos = new_occupation.pos
								if to_pos then
									local reservation = {
										position = mvector3.copy(to_pos),
										radius = 60,
										filter = data.pos_rsrv_id
									}
									managers.navigation:add_pos_reservation(reservation)
									if my_data.rsrv_pos.path then
										managers.navigation:unreserve_pos(my_data.rsrv_pos.path)
									end
									my_data.rsrv_pos.path = reservation
								end
							end
						end
						if not to_pos then
							to_pos = managers.navigation:find_random_position_in_segment(objective.nav_seg)
							to_pos = CopLogicTravel._get_pos_on_wall(to_pos)
							local reservation = {
								position = mvector3.copy(to_pos),
								radius = 60,
								filter = data.pos_rsrv_id
							}
							managers.navigation:add_pos_reservation(reservation)
							if my_data.rsrv_pos.path then
								managers.navigation:unreserve_pos(my_data.rsrv_pos.path)
							end
							my_data.rsrv_pos.path = reservation
						end
					else
						local end_pos = coarse_path[cur_index + 1][2]
						local walk_dir = end_pos - data.m_pos
						local walk_dis = mvector3.normalize(walk_dir)
						local cover_range = math.min(700, math.max(0, walk_dis - 100))
						local cover = managers.navigation:find_cover_near_pos_1(end_pos, end_pos + walk_dir * 700, cover_range, cover_range)
						if cover then
							managers.navigation:reserve_cover(cover, data.pos_rsrv_id)
							my_data.moving_to_cover = {cover}
							to_pos = cover[1]
						else
							to_pos = managers.navigation:find_random_position_in_segment(coarse_path[cur_index + 1][1])
							my_data.moving_to_cover = nil
						end
					end
					my_data.advance_path_search_id = tostring(unit:key()) .. "advance"
					my_data.processing_advance_path = true
					unit:brain():search_for_path(my_data.advance_path_search_id, to_pos)
				end
			end
		else
			local search_id = tostring(unit:key()) .. "coarse"
			local verify_clbk
			if not my_data.coarse_search_failed then
				verify_clbk = callback(CopLogicTravel, CopLogicTravel, "_investigate_coarse_path_verify_clbk")
			end
			if unit:brain():search_for_coarse_path(search_id, objective.nav_seg, verify_clbk) then
				my_data.coarse_path_search_id = search_id
				my_data.processing_coarse_path = true
			end
		end
	else
		CopLogicBase._exit(data.unit, "idle")
		return
	end
	if my_data.processing_advance_path or my_data.processing_coarse_path then
		CopLogicTravel._update_advance_path(data, my_data)
		if data.internal_data ~= my_data then
			return
		end
	end
	if my_data.advancing then
	elseif my_data.cover_leave_t then
		if not my_data.turning and not unit:movement():chk_action_forbidden("walk") then
			if t > my_data.cover_leave_t then
				my_data.cover_leave_t = nil
			elseif my_data.best_cover and not my_data.focus_enemy and not CopLogicTravel._chk_request_action_turn_to_cover(data, my_data) and not my_data.best_cover[4] and not unit:anim_data().crouch and data.char_tweak.allow_crouch then
				CopLogicAttack._chk_request_action_crouch(data)
			end
		end
	elseif my_data.advance_path and not data.unit:movement():chk_action_forbidden("walk") then
		local haste = objective and objective.haste or "run"
		local pose
		if not data.char_tweak.crouch_move then
			pose = "stand"
		elseif data.char_tweak.no_stand then
			pose = "crouch"
		else
			pose = objective and objective.pose or "stand"
		end
		if not unit:anim_data()[pose] then
			CopLogicAttack["_chk_request_action_" .. pose](data)
		end
		local end_rot
		if my_data.coarse_path_index == #my_data.coarse_path - 1 then
			end_rot = objective and objective.rot
		end
		local no_strafe = data.unit:movement():cool()
		CopLogicTravel._chk_request_action_walk_to_advance_pos(data, my_data, haste, end_rot, no_strafe, not no_strafe)
	end
	CopLogicTravel.queue_update(data, my_data)
end
function CopLogicTravel._upd_enemy_detection(data)
	managers.groupai:state():on_unit_detection_updated(data.unit)
	data.t = TimerManager:game():time()
	local my_data = data.internal_data
	local delay = CopLogicAttack._detect_enemies(data, my_data)
	local enemies = my_data.detected_enemies
	local focus_enemy, focus_type, focus_enemy_key
	local target = CopLogicAttack._get_priority_enemy(data, enemies)
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
	end
	my_data.focus_enemy = focus_enemy
	CopLogicAttack._upd_aim(data, my_data)
	if focus_enemy and not data.unit:movement():chk_action_forbidden("walk") then
		local exit_state
		local interrupt = my_data.interrupt_on
		local objective_interrupted
		if interrupt == "contact" then
			exit_state = focus_type == "assault" and "attack" or focus_type
			objective_interrupted = true
		elseif interrupt == "obstructed" then
			exit_state = CopLogicAttack.is_obstructed(data) and (focus_type == "assault" and "attack" or focus_type)
			objective_interrupted = true
		end
		if exit_state then
			if objective_interrupted then
				managers.groupai:state():on_objective_failed(data.unit, data.objective)
			else
				if not my_data.rsrv_pos.stand then
					local reservation = managers.navigation:reserve_pos(data.t, nil, data.m_pos, nil, 60, data.pos_rsrv_id)
					my_data.rsrv_pos.stand = reservation
				end
				CopLogicBase._exit(data.unit, exit_state)
			end
			CopLogicBase._report_detections(my_data.detected_enemies)
			return
		end
	end
	CopLogicBase._report_detections(my_data.detected_enemies)
end
function CopLogicTravel.chk_should_turn(data, my_data)
	return not my_data.advancing and not my_data.turning and not data.unit:movement():chk_action_forbidden("walk")
end
function CopLogicTravel._update_advance_path(data, my_data)
	if data.pathing_results then
		local pathing_results = data.pathing_results
		data.pathing_results = nil
		local path = pathing_results[my_data.advance_path_search_id]
		if path then
			my_data.processing_advance_path = nil
			my_data.advance_path_search_id = nil
			if path ~= "failed" then
				my_data.advance_path = path
			else
				print("[CopLogicTravel:_update_advance_path] advance_path failed", data.unit)
				managers.groupai:state():on_objective_failed(data.unit, data.objective)
				return
			end
		end
		path = pathing_results[my_data.coarse_path_search_id]
		if path then
			my_data.processing_coarse_path = nil
			my_data.coarse_path_search_id = nil
			if path ~= "failed" then
				my_data.coarse_path = path
				my_data.coarse_path_index = 1
			elseif my_data.coarse_search_failed then
				print("[CopLogicTravel:_update_advance_path] coarse_path failed unsafe", data.unit)
				managers.groupai:state():on_objective_failed(data.unit, data.objective)
				return
			else
				my_data.coarse_search_failed = true
			end
		end
	end
end
function CopLogicTravel._update_cover(ignore_this, data)
	local my_data = data.internal_data
	CopLogicBase.on_delayed_clbk(my_data, my_data.cover_update_task_key)
	local cover_release_dis = 100
	local nearest_cover = my_data.nearest_cover
	local best_cover = my_data.best_cover
	local m_pos = data.m_pos
	if not my_data.in_cover and nearest_cover and cover_release_dis < mvector3.distance(nearest_cover[1][1], m_pos) then
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
		CopLogicBase.add_delayed_clbk(my_data, my_data.cover_update_task_key, callback(CopLogicTravel, CopLogicTravel, "_update_cover", data), data.t + 1)
	end
end
function CopLogicTravel._chk_request_action_turn_to_cover(data, my_data)
	local fwd = data.unit:movement():m_rot():y()
	local target_vec = -my_data.best_cover[1][2]
	local error_spin = target_vec:to_polar_with_reference(fwd, math.UP).spin
	if math.abs(error_spin) > 25 then
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
function CopLogicTravel._chk_cover_height(data, cover, slotmask)
	local ray_from = math.UP * 110
	mvector3.add(ray_from, cover[1])
	local ray_to = cover[2] * 200
	mvector3.add(ray_to, ray_from)
	local ray = World:raycast("ray", ray_from, ray_to, "slot_mask", slotmask, "ray_type", "ai_vision")
	return ray
end
function CopLogicTravel.action_complete_clbk(data, action)
	local action_type = action:type()
	if action_type == "walk" then
		local my_data = data.internal_data
		my_data.advancing = nil
		if data.char_tweak.leader then
			managers.groupai:state():find_followers_to_unit(data.key, data.char_tweak.leader)
		end
		my_data.rsrv_pos.stand = my_data.rsrv_pos.move_dest
		my_data.rsrv_pos.move_dest = nil
		if action:expired() and not my_data.starting_advance_action and my_data.coarse_path_index then
			my_data.coarse_path_index = my_data.coarse_path_index + 1
		end
		if my_data.moving_to_cover then
			if action:expired() then
				if my_data.best_cover then
					managers.navigation:release_cover(my_data.best_cover[1])
				end
				my_data.best_cover = my_data.moving_to_cover
				CopLogicBase.chk_cancel_delayed_clbk(my_data, my_data.cover_update_task_key)
				local high_ray = CopLogicTravel._chk_cover_height(data, my_data.best_cover[1], my_data.ai_visibility_slotmask)
				my_data.best_cover[4] = high_ray
				my_data.in_cover = true
				if not my_data.cover_wait_t then
					local cover_wait_t = {0.7, 0.8}
				end
				my_data.cover_leave_t = data.t + cover_wait_t[1] + cover_wait_t[2] * math.random()
			else
				managers.navigation:release_cover(my_data.moving_to_cover[1])
				if my_data.best_cover then
					local dis = mvector3.distance(my_data.best_cover[1][1], data.unit:movement():m_pos())
					if dis > 100 then
						managers.navigation:release_cover(my_data.best_cover[1])
						my_data.best_cover = nil
					end
				end
			end
			my_data.moving_to_cover = nil
		elseif my_data.best_cover then
			local dis = mvector3.distance(my_data.best_cover[1][1], data.unit:movement():m_pos())
			if dis > 100 then
				managers.navigation:release_cover(my_data.best_cover[1])
				my_data.best_cover = nil
			end
		end
	elseif action_type == "turn" then
		data.internal_data.turning = nil
	elseif action_type == "shoot" then
		data.internal_data.shooting = nil
	elseif action_type == "dodge" and not data.unit:movement():chk_action_forbidden("walk") then
		CopLogicBase._exit(data.unit, "idle")
	end
end
function CopLogicTravel._get_pos_accross_door(guard_door, nav_seg)
	local rooms = guard_door.rooms
	local room_1_seg = guard_door.low_seg
	local accross_vec = guard_door.high_pos - guard_door.low_pos
	local rot_angle = 90
	if room_1_seg == nav_seg then
		if guard_door.low_pos.y == guard_door.high_pos.y then
			rot_angle = rot_angle * -1
		end
	elseif guard_door.low_pos.x == guard_door.high_pos.x then
		rot_angle = rot_angle * -1
	end
	mvector3.rotate_with(accross_vec, Rotation(rot_angle))
	local max_dis = 1500
	mvector3.set_length(accross_vec, 1500)
	local door_pos = guard_door.center
	local door_tracker = managers.navigation:create_nav_tracker(mvector3.copy(door_pos))
	local accross_positions = managers.navigation:find_walls_accross_tracker(door_tracker, accross_vec)
	if accross_positions then
		local optimal_dis = math.lerp(max_dis * 0.6, max_dis, math.random())
		local best_error_dis, best_pos, best_is_hit, best_is_miss, best_has_too_much_error
		for _, accross_pos in ipairs(accross_positions) do
			local error_dis = math.abs(mvector3.distance(accross_pos[1], door_pos) - optimal_dis)
			local too_much_error = error_dis / optimal_dis > 0.3
			local is_hit = accross_pos[2]
			if best_is_hit then
				if is_hit then
					if best_error_dis > error_dis then
						best_pos = accross_pos[1]
						best_error_dis = error_dis
						best_has_too_much_error = too_much_error
					end
				elseif best_has_too_much_error then
					best_pos = accross_pos[1]
					best_error_dis = error_dis
					best_is_miss = true
					best_is_hit = nil
				end
			elseif best_is_miss then
				if not too_much_error then
					best_pos = accross_pos[1]
					best_error_dis = error_dis
					best_has_too_much_error = nil
					best_is_miss = nil
					best_is_hit = true
				end
			else
				best_pos = accross_pos[1]
				best_is_hit = is_hit
				best_is_miss = not is_hit
				best_has_too_much_error = too_much_error
				best_error_dis = error_dis
			end
		end
		managers.navigation:destroy_nav_tracker(door_tracker)
		return best_pos
	end
	managers.navigation:destroy_nav_tracker(door_tracker)
end
function CopLogicTravel.damage_clbk(data, damage_info)
	CopLogicIdle.damage_clbk(data, damage_info)
end
function CopLogicTravel.death_clbk(data, damage_info)
	CopLogicAttack.death_clbk(data, damage_info)
end
function CopLogicTravel.can_deactivate(data)
	return false
end
function CopLogicTravel.on_detected_enemy_destroyed(data, enemy_unit)
	CopLogicAttack.on_detected_enemy_destroyed(data, enemy_unit)
end
function CopLogicTravel.on_criminal_neutralized(data, criminal_key)
	CopLogicAttack.on_criminal_neutralized(data, criminal_key)
end
function CopLogicTravel.is_available_for_assignment(data, new_objective)
	if data.objective and data.objective.type == "act" then
	elseif data.unit:movement():chk_action_forbidden("walk") then
	elseif not new_objective or new_objective.type == "free" then
		return true
	end
end
function CopLogicTravel.on_alert(...)
	CopLogicIdle.on_alert(...)
end
function CopLogicTravel.is_advancing(data)
	if data.internal_data.advancing then
		return data.internal_data.rsrv_pos.move_dest.position
	end
end
function CopLogicTravel._reserve_pos_along_vec(look_pos, wanted_pos)
	local step_vec = look_pos - wanted_pos
	local max_pos_mul = math.floor(mvector3.length(step_vec) / 65)
	mvector3.set_length(step_vec, 65)
	local data = {
		start_pos = wanted_pos,
		step_vec = step_vec,
		step_mul = max_pos_mul > 0 and 1 or -1,
		block = max_pos_mul == 0,
		max_pos_mul = max_pos_mul
	}
	local step_clbk = callback(CopLogicTravel, CopLogicTravel, "_rsrv_pos_along_vec_step_clbk", data)
	local res_data = managers.navigation:reserve_pos(nil, nil, wanted_pos, step_clbk, 40, data.pos_rsrv_id)
	return res_data
end
function CopLogicTravel._rsrv_pos_along_vec_step_clbk(shait, data, test_pos)
	local step_mul = data.step_mul
	local nav_manager = managers.navigation
	local step_vec = data.step_vec
	mvector3.set(test_pos, step_vec)
	mvector3.multiply(test_pos, step_mul)
	mvector3.add(test_pos, data.start_pos)
	local params = {
		pos_from = data.start_pos,
		pos_to = test_pos,
		allow_entry = false
	}
	local blocked = nav_manager:raycast(params)
	if blocked then
		if data.block then
			return false
		end
		data.block = true
		if step_mul > 0 then
			data.step_mul = -step_mul
		else
			data.step_mul = -step_mul + 1
			if data.step_mul > data.max_pos_mul then
				return
			end
		end
		return CopLogicTravel._rsrv_pos_along_vec_step_clbk(shait, data, test_pos)
	elseif data.block then
		data.step_mul = step_mul + math.sign(step_mul)
		if data.step_mul > data.max_pos_mul then
			return
		end
	elseif step_mul > 0 then
		data.step_mul = -step_mul
	else
		data.step_mul = -step_mul + 1
		if data.step_mul > data.max_pos_mul then
			data.block = true
			data.step_mul = -data.step_mul
		end
	end
	return true
end
function CopLogicTravel._investigate_coarse_path_verify_clbk(shait, data, nav_seg)
	return managers.groupai:state():is_area_safe(nav_seg)
end
function CopLogicTravel.on_intimidated(data, amount, aggressor_unit)
	local surrender = CopLogicIdle.on_intimidated(data, amount, aggressor_unit)
	if surrender and data.objective then
		managers.groupai:state():on_objective_failed(data.unit, data.objective)
	end
end
function CopLogicTravel._chk_request_action_walk_to_advance_pos(data, my_data, speed, end_rot, no_strafe, chatter_go_go)
	if not data.unit:movement():chk_action_forbidden("walk") or data.unit:anim_data().act_idle then
		CopLogicAttack._correct_path_start_pos(data, my_data.advance_path)
		local path = my_data.advance_path
		local new_action_data = {
			type = "walk",
			nav_path = path,
			variant = speed or "run",
			body_part = 2,
			end_rot = end_rot,
			path_simplified = my_data.path_is_precise,
			no_strafe = no_strafe
		}
		my_data.advance_path = nil
		my_data.starting_advance_action = true
		my_data.advancing = data.unit:brain():action_request(new_action_data)
		my_data.starting_advance_action = false
		if my_data.advancing then
			if my_data.rsrv_pos.path then
				my_data.rsrv_pos.move_dest = my_data.rsrv_pos.path
				my_data.rsrv_pos.path = nil
			else
				local end_pos = mvector3.copy(path[#path])
				local rsrv_desc = {
					filter = data.pos_rsrv_id,
					position = end_pos,
					radius = 30
				}
				managers.navigation:add_pos_reservation(rsrv_desc)
				my_data.rsrv_pos.move_dest = rsrv_desc
			end
			if my_data.rsrv_pos.stand then
				managers.navigation:unreserve_pos(my_data.rsrv_pos.stand)
				my_data.rsrv_pos.stand = nil
			end
			if my_data.nearest_cover and (not my_data.delayed_clbks or not my_data.delayed_clbks[my_data.cover_update_task_key]) then
				CopLogicBase.add_delayed_clbk(my_data, my_data.cover_update_task_key, callback(CopLogicTravel, CopLogicTravel, "_update_cover", data), data.t + 1)
			end
			if chatter_go_go then
				local my_pos = data.m_pos
				local max_dis_sq = 360000
				local my_key = data.key
				for u_key, u_data in pairs(managers.enemy:all_enemies()) do
					if u_key ~= my_key and tweak_data.character[u_data.unit:base()._tweak_table].chatter.go_go and max_dis_sq > mvector3.distance_sq(my_pos, u_data.m_pos) and not u_data.unit:sound():speaking(data.t) and (u_data.unit:anim_data().idle or u_data.unit:anim_data().move) then
						managers.groupai:state():chk_say_enemy_chatter(u_data.unit, u_data.m_pos, "go_go")
					else
					end
				end
			end
		end
	end
end
function CopLogicTravel._determine_destination_occupation(data, objective)
	local occupation
	if objective.type == "investigate_area" then
		if objective.guard_obj then
			occupation = managers.groupai:state():verify_occupation_in_area(objective) or objective.guard_obj
			occupation.type = "guard"
		else
			occupation = managers.groupai:state():find_occupation_in_area(objective.nav_seg)
		end
	elseif objective.type == "defend_area" then
		if objective.cover then
			occupation = {
				type = "defend",
				seg = objective.nav_seg,
				cover = objective.cover,
				radius = objective.radius
			}
		else
			local pos = objective.pos or managers.navigation._nav_segments[objective.nav_seg].pos
			local defend_dir
			local my_data = data.internal_data
			if my_data.focus_enemy then
				defend_dir = my_data.focus_enemy.m_head_pos - data.m_pos
				mvector3.set_z(defend_dir, 0)
				mvector3.normalize(defend_dir)
			end
			defend_dir = defend_dir or objective.defend_dir
			local cover = managers.navigation:find_cover_in_nav_seg_2(objective.nav_seg, pos, defend_dir)
			if cover then
				local cover_entry = {cover}
				occupation = {
					type = "defend",
					seg = objective.nav_seg,
					cover = cover_entry,
					radius = objective.radius
				}
			else
				occupation = {
					type = "defend",
					seg = objective.nav_seg,
					pos = objective.pos,
					radius = objective.radius
				}
			end
		end
	elseif objective.type == "act" then
		occupation = {
			type = "act",
			seg = objective.nav_seg,
			pos = objective.pos
		}
	elseif objective.type == "follow" then
		local follow_pos, follow_nav_seg
		local follow_unit_objective = objective.follow_unit:brain() and objective.follow_unit:brain():objective()
		if not follow_unit_objective or follow_unit_objective.in_place or not follow_unit_objective.nav_seg then
			follow_pos = objective.follow_unit:movement():m_pos()
			follow_nav_seg = objective.follow_unit:movement():nav_tracker():nav_segment()
		else
			follow_pos = follow_unit_objective.pos or objective.follow_unit:movement():m_pos()
			follow_nav_seg = follow_unit_objective.nav_seg
		end
		local distance = math.lerp(objective.distance * 0.5, objective.distance, math.random())
		local to_pos = CopLogicTravel._get_pos_on_wall(follow_pos, distance)
		occupation = {
			type = "defend",
			nav_seg = follow_nav_seg,
			pos = to_pos
		}
	else
		occupation = {
			seg = objective.nav_seg,
			pos = objective.pos
		}
	end
	return occupation
end
function CopLogicTravel._get_pos_on_wall(from_pos, max_dist, step_offset, is_recurse)
	local nav_manager = managers.navigation
	local nr_rays = 7
	local ray_dis = max_dist or 1000
	local step = 360 / nr_rays
	local offset = step_offset or math.random(360)
	local step_rot = Rotation(step)
	local offset_rot = Rotation(offset)
	local offset_vec = Vector3(ray_dis, 0, 0)
	mvector3.rotate_with(offset_vec, offset_rot)
	local to_pos = mvector3.copy(from_pos)
	mvector3.add(to_pos, offset_vec)
	local from_tracker = nav_manager:create_nav_tracker(from_pos)
	local ray_params = {
		tracker_from = from_tracker,
		allow_entry = false,
		pos_to = to_pos,
		trace = true
	}
	local rsrv_desc = {false, 60}
	local fail_position
	repeat
		to_pos = mvector3.copy(from_pos)
		mvector3.add(to_pos, offset_vec)
		ray_params.pos_to = to_pos
		local ray_res = nav_manager:raycast(ray_params)
		if ray_res then
			rsrv_desc.position = ray_params.trace[1]
			local is_free = nav_manager:is_pos_free(rsrv_desc)
			if is_free then
				managers.navigation:destroy_nav_tracker(from_tracker)
				return ray_params.trace[1]
			else
			end
		elseif not fail_position then
			rsrv_desc.position = ray_params.trace[1]
			local is_free = nav_manager:is_pos_free(rsrv_desc)
			if is_free then
				fail_position = to_pos
			end
		end
		mvector3.rotate_with(offset_vec, step_rot)
		nr_rays = nr_rays - 1
	until nr_rays == 0
	managers.navigation:destroy_nav_tracker(from_tracker)
	if fail_position then
		return fail_position
	end
	if not is_recurse then
		return CopLogicTravel._get_pos_on_wall(from_pos, ray_dis * 0.5, offset + step * 0.5, true)
	end
	return from_pos
end
function CopLogicTravel.dodge(data, hipshot)
	return CopLogicIdle.try_dodge(data, hipshot and "on_hit" or "scared")
end
function CopLogicTravel.on_new_objective(data, old_objective)
	CopLogicIdle.on_new_objective(data, old_objective)
end
function CopLogicTravel.queue_update(data, my_data)
	local delay
	if next(my_data.suspected_enemies) or not managers.groupai:state():enemy_weapons_hot() then
		delay = 0.1
	elseif my_data.focus_enemy then
		if my_data.focus_enemy.verified_dis < 700 and math.abs(my_data.focus_enemy.m_pos.z - data.m_pos.z) < 250 then
			delay = 0.5
		elseif data.important then
			delay = 1
		else
			delay = 2
		end
	else
		delay = data.important and 1 or 2
	end
	CopLogicBase.queue_task(my_data, my_data.upd_task_key, CopLogicTravel.queued_update, data, data.t + delay, true)
end
function CopLogicTravel._try_anounce(data, my_data)
	local my_pos = data.m_pos
	local max_dis_sq = 250000
	local my_key = data.key
	local announce_type = data.char_tweak.announce_incomming
	for u_key, u_data in pairs(managers.enemy:all_enemies()) do
		if u_key ~= my_key and tweak_data.character[u_data.unit:base()._tweak_table].chatter[announce_type] and max_dis_sq > mvector3.distance_sq(my_pos, u_data.m_pos) and not u_data.unit:sound():speaking(data.t) and (u_data.unit:anim_data().idle or u_data.unit:anim_data().move) then
			managers.groupai:state():chk_say_enemy_chatter(u_data.unit, u_data.m_pos, announce_type)
			my_data.announce_t = data.t + 15
		else
		end
	end
end
function CopLogicTravel._get_all_paths(data)
	return {
		advance_path = data.internal_data.advance_path
	}
end
function CopLogicTravel._set_verified_paths(data, verified_paths)
	data.internal_data.advance_path = verified_paths.advance_path
end
