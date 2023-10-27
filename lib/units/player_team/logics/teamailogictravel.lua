require("lib/units/enemies/cop/logics/CopLogicBase")
require("lib/units/enemies/cop/logics/CopLogicTravel")
require("lib/units/enemies/cop/logics/CopLogicAttack")
TeamAILogicTravel = class(TeamAILogicBase)
function TeamAILogicTravel.enter(data, new_logic_name, enter_params)
	CopLogicBase.enter(data, new_logic_name, enter_params)
	data.unit:brain():cancel_all_pathing_searches()
	local old_internal_data = data.internal_data
	local my_data = {
		unit = data.unit
	}
	my_data.detection = tweak_data.character[data.unit:base()._tweak_table].detection.recon
	my_data.enemy_detect_slotmask = managers.slot:get_mask("enemies")
	my_data.ai_visibility_slotmask = managers.slot:get_mask("AI_visibility")
	my_data.rsrv_pos = {}
	if old_internal_data then
		my_data.detected_enemies = old_internal_data.detected_enemies or {}
		my_data.focus_enemy = old_internal_data.focus_enemy
		my_data.focus_type = old_internal_data.focus_type
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
		my_data.detected_enemies = {}
	end
	data.internal_data = my_data
	local key_str = tostring(data.unit:key())
	if not data.unit:movement():cool() then
		my_data.detection_task_key = "TeamAILogicTravel._update_enemy_detection" .. key_str
		CopLogicBase.queue_task(my_data, my_data.detection_task_key, TeamAILogicTravel._update_enemy_detection, data, data.t)
	end
	my_data.cover_update_task_key = "CopLogicTravel._update_cover" .. key_str
	if my_data.nearest_cover or my_data.best_cover then
		CopLogicBase.add_delayed_clbk(my_data, my_data.cover_update_task_key, callback(CopLogicTravel, CopLogicTravel, "_update_cover", data), data.t + 1)
	end
	if data.objective then
		data.objective.called = false
		my_data.called = true
		if data.objective.follow_unit then
			my_data.cover_wait_t = {0, 0}
		end
		TeamAILogicTravel.trap_error(data)
	end
	CopLogicBase._reset_attention(data)
	data.unit:movement():set_allow_fire(false)
	TeamAILogicAssault._chk_change_weapon(data, my_data)
	TeamAILogicAssault._upd_aim(data, my_data)
	if not data.unit:movement():chk_action_forbidden("walk") then
		local new_action = {type = "idle", body_part = 2}
		data.unit:brain():action_request(new_action)
	end
end
function TeamAILogicTravel.exit(data, new_logic_name, enter_params)
	TeamAILogicBase.exit(data, new_logic_name, enter_params)
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
end
function TeamAILogicTravel.update(data)
	local unit = data.unit
	local objective = data.objective
	if not objective then
		managers.groupai:state():on_criminal_jobless(unit)
		return
	end
	local my_data = data.internal_data
	local t = data.t
	if my_data.processing_advance_path or my_data.processing_coarse_path then
		TeamAILogicTravel._upd_pathing(data, my_data)
	elseif my_data.advancing then
	elseif my_data.cover_leave_t then
		if not my_data.turning and not unit:movement():chk_action_forbidden("walk") then
			if t > my_data.cover_leave_t then
				my_data.cover_leave_t = nil
			elseif my_data.best_cover then
				local action_taken
				if not unit:movement():attention() then
					action_taken = CopLogicTravel._chk_request_action_turn_to_cover(data, my_data)
				end
				if not action_taken and not my_data.best_cover[4] and not unit:anim_data().crouch and not data.unit:movement():cool() then
					CopLogicAttack._chk_request_action_crouch(data)
				end
			end
		end
	elseif my_data.advance_path then
		if not unit:movement():chk_action_forbidden("walk") then
			local haste, no_strafe
			if objective and objective.haste then
				haste = objective.haste
				no_strafe = data.unit:movement():cool()
			elseif unit:movement():cool() then
				haste = "walk"
				no_strafe = true
			else
				haste = "run"
			end
			CopLogicTravel._chk_request_action_walk_to_advance_pos(data, my_data, haste, objective and objective.rot, no_strafe)
			if my_data.advancing then
				TeamAILogicTravel._check_start_path_ahead(data)
			end
		end
	elseif objective then
		if my_data.coarse_path then
			local coarse_path = my_data.coarse_path
			local cur_index = my_data.coarse_path_index
			local total_nav_points = #coarse_path
			if cur_index == total_nav_points then
				objective.in_place = true
				CopLogicBase._exit(data.unit, "idle", {scan = true})
				return
			else
				local to_pos = TeamAILogicTravel._get_exact_move_pos(data, cur_index)
				my_data.advance_path_search_id = tostring(data.key) .. "advance"
				my_data.processing_advance_path = true
				local prio
				if objective and objective.follow_unit then
					prio = 5
				end
				unit:brain():search_for_path(my_data.advance_path_search_id, to_pos, prio)
			end
		else
			local search_id = tostring(unit:key()) .. "coarse"
			local nav_seg
			if objective.follow_unit then
				if not alive(objective.follow_unit) then
				else
					nav_seg = objective.follow_unit:movement():nav_tracker():nav_segment()
				end
			else
				nav_seg = objective.nav_seg
			end
			if unit:brain():search_for_coarse_path(search_id, nav_seg) then
				my_data.coarse_path_search_id = search_id
				my_data.processing_coarse_path = true
			end
		end
	else
		CopLogicBase._exit(data.unit, "idle", {scan = true})
	end
end
function TeamAILogicTravel._upd_pathing(data, my_data)
	local pathing_results = data.pathing_results
	if pathing_results then
		data.pathing_results = nil
		if my_data.processing_advance_path then
			local path = pathing_results[my_data.advance_path_search_id]
			if path then
				my_data.processing_advance_path = nil
				my_data.advance_path_search_id = nil
				if path ~= "failed" then
					my_data.advance_path = path
				else
					print("[TeamAILogicTravel:_upd_pathing] advance_path failed!")
					managers.groupai:state():on_criminal_objective_failed(data.unit, data.objective)
					return
				end
			end
		end
		if my_data.processing_coarse_path then
			local path = pathing_results[my_data.coarse_path_search_id]
			if path then
				my_data.processing_coarse_path = nil
				my_data.coarse_path_search_id = nil
				if path ~= "failed" then
					my_data.coarse_path = path
					my_data.coarse_path_index = 1
				else
					print("[TeamAILogicTravel:_upd_pathing] coarse_path failed!")
					managers.groupai:state():on_criminal_objective_failed(data.unit, data.objective)
					return
				end
			end
		end
	end
end
function TeamAILogicTravel.action_complete_clbk(data, action)
	CopLogicTravel.action_complete_clbk(data, action)
	local my_data = data.internal_data
	local action_type = action:type()
	if action_type == "walk" and not action:expired() then
		if my_data.processing_advance_path then
			local pathing_results = data.pathing_results
			if pathing_results and pathing_results[my_data.advance_path_search_id] then
				data.pathing_results[my_data.advance_path_search_id] = nil
				my_data.advance_path_search_id = nil
				my_data.processing_advance_path = nil
			end
		elseif my_data.advance_path then
			my_data.advance_path = nil
		end
	end
end
function TeamAILogicTravel.damage_clbk(data, damage_info)
	TeamAILogicIdle.damage_clbk(data, damage_info)
end
function TeamAILogicTravel.death_clbk(data, damage_info)
end
function TeamAILogicTravel.on_detected_enemy_destroyed(data, enemy_unit)
	TeamAILogicIdle.on_cop_neutralized(data, enemy_unit:key())
end
function TeamAILogicTravel.on_cop_neutralized(data, cop_key)
	TeamAILogicIdle.on_cop_neutralized(data, cop_key)
end
function TeamAILogicTravel.on_objective_unit_damaged(...)
	TeamAILogicIdle.on_objective_unit_damaged(...)
end
function TeamAILogicTravel.on_alert(...)
	TeamAILogicIdle.on_alert(...)
end
function TeamAILogicTravel.on_intimidated(data, amount, aggressor_unit)
	local surrender = TeamAILogicIdle.on_intimidated(data, amount, aggressor_unit)
	if surrender and data.objective then
		managers.groupai:state():on_criminal_objective_failed(data.unit, data.objective)
	end
end
function TeamAILogicTravel._determine_destination_occupation(data, objective)
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
			local cover = managers.navigation:find_cover_in_nav_seg_1(objective.nav_seg)
			local cover_entry
			if cover then
				local cover_entry = {cover}
				occupation = {type = "defend", cover = cover_entry}
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
		local follow_tracker = objective.follow_unit:movement():nav_tracker()
		local follow_pos = follow_tracker:field_position()
		local threat_pos
		local max_dist = managers.groupai:state():get_assault_mode() and 500 or 1500
		local dist2 = mvector3.distance_sq(follow_pos, data.m_pos)
		local zdist = math.abs(follow_pos.z - data.m_pos.z)
		if dist2 > max_dist * max_dist * 2 or 600 < zdist then
			threat_pos = follow_pos
		elseif data.internal_data.focus_enemy then
			local threat_tracker = data.internal_data.focus_enemy.unit:movement():nav_tracker()
			threat_pos = threat_tracker:field_position()
		else
			threat_pos = follow_pos - data.m_pos
			mvector3.set_length(threat_pos, 300)
			mvector3.add(threat_pos, follow_pos)
		end
		local cover = managers.navigation:find_cover_near_pos_1(follow_pos, threat_pos, 800, 300, data.internal_data.called)
		if cover then
			local cover_entry = {cover}
			occupation = {type = "defend", cover = cover_entry}
		else
			local max_dist
			if objective.called then
				max_dist = 600
			end
			local to_pos = CopLogicTravel._get_pos_on_wall(follow_pos, max_dist)
			occupation = {type = "defend", pos = to_pos}
		end
	elseif objective.type == "revive" then
		local is_local_player = objective.follow_unit:base().is_local_player
		local revive_u_mv = objective.follow_unit:movement()
		local revive_u_tracker = revive_u_mv:nav_tracker()
		local revive_u_rot = is_local_player and Rotation(0, 0, 0) or revive_u_mv:m_rot()
		local revive_u_fwd = revive_u_rot:y()
		local revive_u_right = revive_u_rot:x()
		local revive_u_pos = revive_u_tracker:lost() and revive_u_tracker:field_position() or revive_u_mv:m_pos()
		local ray_params = {tracker_from = revive_u_tracker, trace = true}
		if revive_u_tracker:lost() then
			ray_params.pos_from = revive_u_pos
		end
		local stand_dis
		if is_local_player or objective.follow_unit:base().is_husk_player then
			stand_dis = 120
		else
			stand_dis = 90
			local mid_pos = mvector3.copy(revive_u_fwd)
			mvector3.multiply(mid_pos, -20)
			mvector3.add(mid_pos, revive_u_pos)
			ray_params.pos_to = mid_pos
			local ray_res = managers.navigation:raycast(ray_params)
			revive_u_pos = ray_params.trace[1]
		end
		local rand_side_mul = math.random() > 0.5 and 1 or -1
		local revive_pos = mvector3.copy(revive_u_right)
		mvector3.multiply(revive_pos, rand_side_mul * stand_dis)
		mvector3.add(revive_pos, revive_u_pos)
		ray_params.pos_to = revive_pos
		local ray_res = managers.navigation:raycast(ray_params)
		if ray_res then
			local opposite_pos = mvector3.copy(revive_u_right)
			mvector3.multiply(opposite_pos, -rand_side_mul * stand_dis)
			mvector3.add(opposite_pos, revive_u_pos)
			ray_params.pos_to = opposite_pos
			local old_trace = ray_params.trace[1]
			local opposite_ray_res = managers.navigation:raycast(ray_params)
			if opposite_ray_res then
				if mvector3.distance(ray_params.trace[1], revive_u_pos) > mvector3.distance(revive_pos, revive_u_pos) then
					revive_pos = ray_params.trace[1]
				else
					revive_pos = old_trace
				end
			else
				revive_pos = ray_params.trace[1]
			end
		else
			revive_pos = ray_params.trace[1]
		end
		local revive_rot = revive_u_pos - revive_pos
		local revive_rot = Rotation(revive_rot, math.UP)
		occupation = {
			type = "revive",
			pos = revive_pos,
			rot = revive_rot
		}
	end
	return occupation
end
function TeamAILogicTravel.is_available_for_assignment(data, new_objective)
	local objective = data.objective
	if objective and objective.type == "revive" and new_objective.type == "revive" then
		return
	end
	return true
end
function TeamAILogicTravel.on_long_dis_interacted(data, other_unit)
	TeamAILogicIdle.on_long_dis_interacted(data, other_unit)
end
function TeamAILogicTravel.on_new_objective(data, old_objective)
	local my_data = data.internal_data
	TeamAILogicIdle.on_new_objective(data, old_objective)
	if my_data == data.internal_data then
		TeamAILogicTravel.trap_error(data)
	end
end
function TeamAILogicTravel.trap_error(data)
	if not data.objective then
		return
	end
	if not data.objective.in_place and not data.objective.nav_seg and not data.objective.follow_unit then
		Application:error("L\228gg med det h\228r och ner\229t om du rapporterar detta p\229 Mantis --")
		Application:error("Invalid objective in travel logic.")
		print(inspect(data.objective))
		Application:error("Stack dump:")
		Application:stack_dump()
		Application:error("And a pause...")
		debug_pause(true)
	end
end
function TeamAILogicTravel._update_enemy_detection(data)
	data.t = TimerManager:game():time()
	local my_data = data.internal_data
	local delay = TeamAILogicIdle._detect_enemies(data, my_data)
	local enemies = my_data.detected_enemies
	local focus_enemy, focus_type, focus_enemy_key
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
	end
	my_data.focus_enemy = focus_enemy
	if focus_type then
		local objective = data.objective
		local objective_interrupted, objective_block
		local dont_exit = false
		if data.unit:movement():chk_action_forbidden("walk") then
			dont_exit = true
		elseif objective then
			local interrupt = objective.interrupt_on
			if interrupt == "contact" then
				objective_interrupted = true
			elseif interrupt == "obstructed" then
				if TeamAILogicIdle.is_obstructed(data, data.objective) then
					objective_interrupted = true
				else
					objective_block = true
				end
			elseif objective.type ~= "follow" then
				objective_block = true
			end
			if objective.type == "follow" then
				local max_dist = managers.groupai:state():get_assault_mode() and 800 or 1500
				local dist2 = mvector3.distance_sq(data.objective.follow_unit:movement():m_pos(), data.m_pos)
				local zdist = math.abs(data.objective.follow_unit:movement():m_pos().z - data.m_pos.z)
				if my_data.called or 3 < target_prio_slot and (dist2 > max_dist * max_dist or 300 < zdist) or target_prio_slot <= 3 and (dist2 > max_dist * max_dist * 2 or 600 < zdist) then
					dont_exit = true
				end
			end
		end
		if objective_interrupted and not dont_exit then
			managers.groupai:state():on_criminal_objective_failed(data.unit, data.objective)
			return
		elseif not objective_block then
			if focus_type == "assault" and target_prio_slot < 4 and not dont_exit then
				my_data.exiting = true
				CopLogicBase._exit(data.unit, "assault")
				return
			elseif focus_type == "assault" then
				TeamAILogicAssault._upd_aim(data, my_data)
				TeamAILogicAssault._chk_change_weapon(data, my_data)
			end
		end
	end
	if not my_data._intimidate_t or my_data._intimidate_t + 2 < data.t then
		local civ = TeamAILogicIdle.intimidate_civilians(data, data.unit, true, false)
		if civ then
			my_data._intimidate_t = data.t
			if not my_data.focus_enemy then
				CopLogicBase._set_attention_on_unit(data, civ)
				local key = "RemoveAttentionOnUnit" .. tostring(data.unit:key())
				CopLogicBase.queue_task(my_data, key, TeamAILogicTravel._remove_enemy_attention, data, data.t + 1.5)
			end
		end
	end
	TeamAILogicAssault._chk_request_combat_chatter(data, my_data)
	CopLogicBase.queue_task(my_data, my_data.detection_task_key, TeamAILogicTravel._update_enemy_detection, data, data.t + delay)
end
function TeamAILogicTravel._remove_enemy_attention(data)
	CopLogicBase._reset_attention(data)
end
function TeamAILogicTravel.clbk_heat(data)
	TeamAILogicIdle.clbk_heat(data)
end
function TeamAILogicTravel.chk_should_turn(data, my_data)
	CopLogicAttack.chk_should_turn(data, my_data)
end
function TeamAILogicTravel._get_exact_move_pos(data, cur_index)
	local my_data = data.internal_data
	local objective = data.objective
	local to_pos
	local coarse_path = my_data.coarse_path
	local cur_index = my_data.coarse_path_index
	local total_nav_points = #coarse_path
	local reservation, wants_reservation
	if cur_index >= total_nav_points - 1 then
		local new_occupation = TeamAILogicTravel._determine_destination_occupation(data, objective)
		if new_occupation then
			if new_occupation.type == "guard" then
				local guard_door = new_occupation.door
				local guard_pos = CopLogicTravel._get_pos_accross_door(guard_door, objective.nav_seg)
				if guard_pos then
					reservation = CopLogicTravel._reserve_pos_along_vec(guard_door.center, guard_pos)
					if reservation then
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
					local new_cover = new_occupation.cover
					managers.navigation:reserve_cover(new_cover[1], data.pos_rsrv_id)
					my_data.moving_to_cover = new_cover
				elseif new_occupation.pos then
					to_pos = new_occupation.pos
				end
				wants_reservation = true
			elseif new_occupation.type == "act" then
				to_pos = new_occupation.pos
				wants_reservation = true
			elseif new_occupation.type == "revive" then
				to_pos = new_occupation.pos
				objective.rot = new_occupation.rot
				wants_reservation = true
			end
		end
		if not to_pos then
			to_pos = managers.navigation:find_random_position_in_segment(objective.nav_seg)
			to_pos = CopLogicTravel._get_pos_on_wall(to_pos)
			wants_reservation = true
		end
	else
		local end_pos = coarse_path[cur_index + 1][2]
		local my_pos = data.m_pos
		local walk_dir = end_pos - my_pos
		local walk_dis = mvector3.normalize(walk_dir)
		local cover_range = math.min(700, math.max(0, walk_dis - 100))
		local cover = managers.navigation:find_cover_near_pos_1(end_pos, end_pos + walk_dir * 700, cover_range, cover_range)
		if cover then
			managers.navigation:reserve_cover(cover, data.pos_rsrv_id)
			my_data.moving_to_cover = {cover}
			to_pos = cover[1]
		else
			to_pos = end_pos
			my_data.moving_to_cover = nil
		end
	end
	if not reservation and wants_reservation then
		reservation = {
			position = mvector3.copy(to_pos),
			radius = 60,
			filter = data.pos_rsrv_id
		}
		managers.navigation:add_pos_reservation(reservation)
	end
	if my_data.rsrv_pos.path then
		managers.navigation:unreserve_pos(my_data.rsrv_pos.path)
	end
	my_data.rsrv_pos.path = reservation
	return to_pos
end
function TeamAILogicTravel._check_start_path_ahead(data)
	local my_data = data.internal_data
	if my_data.processing_advance_path then
		return
	end
	local objective = data.objective
	local coarse_path = my_data.coarse_path
	local next_index = my_data.coarse_path_index + 1
	local total_nav_points = #coarse_path
	if next_index >= total_nav_points - 1 then
		return
	end
	local to_pos = TeamAILogicTravel._get_exact_move_pos(data, next_index)
	my_data.advance_path_search_id = tostring(data.key) .. "advance"
	my_data.processing_advance_path = true
	local prio
	if objective and objective.follow_unit then
		prio = 5
	end
	local from_pos = my_data.rsrv_pos.move_dest.position
	data.unit:brain():search_for_path_from_pos(my_data.advance_path_search_id, from_pos, to_pos, prio)
end
function TeamAILogicTravel._get_all_paths(data)
	return {
		advance_path = data.internal_data.advance_path
	}
end
function TeamAILogicTravel._set_verified_paths(data, verified_paths)
	data.internal_data.advance_path = verified_paths.advance_path
end
