ShieldLogicAttack = class(TankCopLogicAttack)
function ShieldLogicAttack.enter(data, new_logic_name, enter_params)
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
	else
		my_data.suspected_enemies = {}
		my_data.detected_enemies = {}
	end
	local key_str = tostring(data.unit:key())
	CopLogicTravel.reset_actions(data, my_data, old_internal_data, CopLogicTravel.allowed_transitional_actions)
	my_data.attitude = data.objective and data.objective.attitude or "avoid"
	local upper_body_action = data.unit:movement()._active_actions[3]
	if not upper_body_action or upper_body_action:type() ~= "shoot" then
		data.unit:movement():set_stance("hos")
	end
	data.unit:brain():set_update_enabled_state(false)
	data.unit:sound():play("shield_identification", nil, true)
	my_data.update_queue_id = "ShieldLogicAttack.queued_update" .. key_str
	ShieldLogicAttack.queue_update(data, my_data)
end
function ShieldLogicAttack.exit(data, new_logic_name, enter_params)
	CopLogicBase.exit(data, new_logic_name, enter_params)
	local my_data = data.internal_data
	data.unit:brain():cancel_all_pathing_searches()
	CopLogicBase.cancel_queued_tasks(my_data)
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
function ShieldLogicAttack.queued_update(data)
	local t = TimerManager:game():time()
	data.t = t
	local unit = data.unit
	local my_data = data.internal_data
	ShieldLogicAttack._upd_enemy_detection(data)
	local focus_type = my_data.focus_type
	if focus_type ~= "assault" then
		my_data.update_task_key = nil
		if focus_type then
			CopLogicBase._exit(data.unit, focus_type)
		elseif data.objective then
			CopLogicBase._exit(data.unit, "idle")
		elseif not managers.groupai:state():on_cop_jobless(data.unit) then
			CopLogicBase._exit(data.unit, "idle", {scan = true})
		end
		CopLogicBase._report_detections(my_data.detected_enemies)
		return
	end
	local focus_enemy = my_data.focus_enemy
	ShieldLogicAttack._upd_aim(data, my_data)
	local action_taken = my_data.turning or data.unit:movement():chk_action_forbidden("walk") or my_data.walking_to_shoot_pos
	if not action_taken and unit:anim_data().stand then
		action_taken = CopLogicAttack._chk_request_action_crouch(data)
	end
	ShieldLogicAttack._process_pathing_results(data, my_data)
	local enemy_visible = focus_enemy.verified
	local engage = my_data.attitude == "engage"
	local action_taken = my_data.turning or data.unit:movement():chk_action_forbidden("walk") or my_data.walking_to_optimal_pos
	if not action_taken then
		if unit:anim_data().stand then
			action_taken = CopLogicAttack._chk_request_action_crouch(data)
		end
		if action_taken or my_data.pathing_to_optimal_pos then
		elseif my_data.optimal_path then
			ShieldLogicAttack._chk_request_action_walk_to_optimal_pos(data, my_data)
		elseif my_data.optimal_pos then
			local to_pos = my_data.optimal_pos
			my_data.optimal_pos = nil
			local ray_params = {
				tracker_from = unit:movement():nav_tracker(),
				pos_to = to_pos,
				trace = true
			}
			local ray_res = managers.navigation:raycast(ray_params)
			to_pos = ray_params.trace[1]
			if ray_res then
				local vec = data.m_pos - to_pos
				mvector3.normalize(vec)
				local fwd = unit:movement():m_rot():y()
				local fwd_dot = fwd:dot(vec)
				if 0 < fwd_dot then
					local enemy_tracker = focus_enemy.unit:movement():nav_tracker()
					if enemy_tracker:lost() then
						ray_params.tracker_from = nil
						ray_params.pos_from = enemy_tracker:field_position()
					else
						ray_params.tracker_from = enemy_tracker
					end
					ray_res = managers.navigation:raycast(ray_params)
					to_pos = ray_params.trace[1]
				end
			end
			if mvector3.distance(to_pos, data.m_pos) > 100 then
				if my_data.rsrv_pos.path then
					managers.navigation:unreserve_pos(my_data.rsrv_pos.path)
				end
				my_data.pathing_to_optimal_pos = true
				my_data.optimal_path_search_id = tostring(unit:key()) .. "optimal"
				local reservation = managers.navigation:reserve_pos(nil, nil, to_pos, callback(ShieldLogicAttack, ShieldLogicAttack, "_reserve_pos_step_clbk", {
					unit_pos = data.m_pos
				}), 70, data.pos_rsrv_id)
				if reservation then
					to_pos = reservation.position
				else
					reservation = {
						position = mvector3.copy(to_pos),
						radius = 70,
						filter = data.pos_rsrv_id
					}
					managers.navigation:add_pos_reservation(reservation)
				end
				my_data.rsrv_pos.path = reservation
				unit:brain():search_for_path(my_data.optimal_path_search_id, to_pos)
			end
		end
	end
	ShieldLogicAttack.queue_update(data, my_data)
	CopLogicBase._report_detections(my_data.detected_enemies)
end
function ShieldLogicAttack:_reserve_pos_step_clbk(data, test_pos)
	if not data.step_vector then
		data.step_vector = mvector3.copy(data.unit_pos)
		mvector3.subtract(data.step_vector, test_pos)
		data.distance = mvector3.normalize(data.step_vector)
		mvector3.set_length(data.step_vector, 25)
		data.num_steps = 0
	end
	local step_length = mvector3.length(data.step_vector)
	if step_length > data.distance or data.num_steps > 4 then
		return false
	end
	mvector3.add(test_pos, data.step_vector)
	data.distance = data.distance - step_length
	mvector3.set_length(data.step_vector, step_length * 2)
	data.num_steps = data.num_steps + 1
	return true
end
function ShieldLogicAttack._process_pathing_results(data, my_data)
	if data.pathing_results then
		local pathing_results = data.pathing_results
		data.pathing_results = nil
		local path = pathing_results[my_data.optimal_path_search_id]
		if path then
			if path ~= "failed" then
				my_data.optimal_path = path
			else
				print("[ShieldLogicAttack._process_pathing_results] optimal path failed")
			end
			my_data.pathing_to_optimal_pos = nil
			my_data.optimal_path_search_id = nil
		end
	end
end
function ShieldLogicAttack._chk_request_action_walk_to_optimal_pos(data, my_data, end_rot)
	if not data.unit:movement():chk_action_forbidden("walk") then
		local new_action_data = {
			type = "walk",
			nav_path = my_data.optimal_path,
			variant = "walk",
			body_part = 2,
			end_rot = end_rot
		}
		my_data.optimal_path = nil
		my_data.walking_to_optimal_pos = data.unit:brain():action_request(new_action_data)
		if my_data.walking_to_optimal_pos then
			my_data.rsrv_pos.move_dest = my_data.rsrv_pos.path
			my_data.rsrv_pos.path = nil
			if my_data.rsrv_pos.stand then
				managers.navigation:unreserve_pos(my_data.rsrv_pos.stand)
				my_data.rsrv_pos.stand = nil
			end
			if data.char_tweak.leader then
				managers.groupai:state():find_followers_to_unit(data.key, data.char_tweak.leader)
				if data.char_tweak.chatter.follow_me and mvector3.distance(new_action_data.nav_path[#new_action_data.nav_path], data.m_pos) > 800 and managers.groupai:state():chk_has_followers(data.key) and not data.unit:sound():speaking(data.t) then
					managers.groupai:state():chk_say_enemy_chatter(data.unit, data.m_pos, "follow_me")
				end
			end
		end
	end
end
function ShieldLogicAttack._cancel_optimal_attempt(data, my_data)
	if my_data.optimal_path then
		my_data.optimal_path = nil
	elseif my_data.walking_to_optimal_pos then
		local new_action = {type = "idle", body_part = 2}
		data.unit:brain():action_request(new_action)
	elseif my_data.pathing_to_optimal_pos then
		if my_data.rsrv_pos.path then
			managers.navigation:unreserve_pos(my_data.rsrv_pos.path)
			my_data.rsrv_pos.path = nil
		end
		if data.active_searches[my_data.optimal_path_search_id] then
			managers.navigation:cancel_pathing_search(my_data.optimal_path_search_id)
			data.active_searches[my_data.optimal_path_search_id] = nil
		elseif data.pathing_results then
			data.pathing_results[my_data.optimal_path_search_id] = nil
		end
		my_data.optimal_path_search_id = nil
		my_data.pathing_to_optimal_pos = nil
		data.unit:brain():cancel_all_pathing_searches()
	end
end
function ShieldLogicAttack.queue_update(data, my_data)
	CopLogicBase.queue_task(my_data, my_data.update_queue_id, ShieldLogicAttack.queued_update, data, data.t + (data.important and 0.5 or 1.5), data.important and true)
end
function ShieldLogicAttack._upd_enemy_detection(data)
	managers.groupai:state():on_unit_detection_updated(data.unit)
	local my_data = data.internal_data
	local delay = CopLogicAttack._detect_enemies(data, my_data)
	local focus_enemy, focus_type, focus_enemy_key, focus_enemy_verified, focus_enemy_dmg_t, focus_enemy_verified_t
	local detected_enemies = my_data.detected_enemies
	local enemies = {}
	local enemies_cpy = {}
	local passive_enemies = {}
	local threat_epicenter, threats
	local nr_threats = 0
	local verified_chk_t = data.t - 8
	for key, enemy_data in pairs(detected_enemies) do
		if enemy_data.verified_t and verified_chk_t < enemy_data.verified_t then
			enemies[key] = enemy_data
			enemies_cpy[key] = enemy_data
		end
	end
	for key, enemy_data in pairs(enemies) do
		threat_epicenter = threat_epicenter or Vector3()
		mvector3.add(threat_epicenter, enemy_data.m_pos)
		nr_threats = nr_threats + 1
	end
	if threat_epicenter then
		mvector3.divide(threat_epicenter, nr_threats)
		local from_threat = mvector3.copy(threat_epicenter)
		mvector3.subtract(from_threat, data.m_pos)
		mvector3.normalize(from_threat)
		local furthest_pt_dist = 0
		local furthest_line
		if not my_data.threat_epicenter or mvector3.distance(threat_epicenter, my_data.threat_epicenter) > 100 then
			my_data.threat_epicenter = mvector3.copy(threat_epicenter)
			for key1, enemy_data1 in pairs(enemies) do
				enemies_cpy[key1] = nil
				for key2, enemy_data2 in pairs(enemies_cpy) do
					if nr_threats == 2 then
						local AB = mvector3.copy(enemy_data1.m_pos)
						mvector3.subtract(AB, enemy_data2.m_pos)
						mvector3.normalize(AB)
						local PA = mvector3.copy(data.m_pos)
						mvector3.subtract(PA, enemy_data1.m_pos)
						mvector3.normalize(PA)
						local PB = mvector3.copy(data.m_pos)
						mvector3.subtract(PB, enemy_data2.m_pos)
						mvector3.normalize(PB)
						local dot1 = mvector3.dot(AB, PA)
						local dot2 = mvector3.dot(AB, PB)
						if dot1 < 0 and dot2 < 0 or 0 < dot1 and 0 < dot2 then
							break
						else
							furthest_line = {
								enemy_data1.m_pos,
								enemy_data2.m_pos
							}
							break
						end
					end
					local pt = math.line_intersection(enemy_data1.m_pos, enemy_data2.m_pos, threat_epicenter, data.m_pos)
					local to_pt = mvector3.copy(threat_epicenter)
					mvector3.subtract(to_pt, pt)
					mvector3.normalize(to_pt)
					if 0 < mvector3.dot(from_threat, to_pt) then
						local line = mvector3.copy(enemy_data2.m_pos)
						mvector3.subtract(line, enemy_data1.m_pos)
						local line_len = mvector3.normalize(line)
						local pt_line = mvector3.copy(pt)
						mvector3.subtract(pt_line, enemy_data1.m_pos)
						local dot = mvector3.dot(line, pt_line)
						if line_len > dot and 0 < dot then
							local dist = mvector3.distance(pt, threat_epicenter)
							if furthest_pt_dist < dist then
								furthest_pt_dist = dist
								furthest_line = {
									enemy_data1.m_pos,
									enemy_data2.m_pos
								}
							end
						end
					end
				end
			end
		end
		local optimal_direction
		if furthest_line then
			local BA = mvector3.copy(furthest_line[2])
			mvector3.subtract(BA, furthest_line[1])
			local PA = mvector3.copy(furthest_line[1])
			mvector3.subtract(PA, data.m_pos)
			local out
			if nr_threats == 2 then
				mvector3.normalize(BA)
				local len = mvector3.dot(BA, PA)
				local x = mvector3.copy(furthest_line[1])
				mvector3.multiply(BA, len)
				mvector3.subtract(x, BA)
				out = mvector3.copy(data.m_pos)
				mvector3.subtract(out, x)
			else
				local EA = mvector3.copy(threat_epicenter)
				mvector3.subtract(EA, furthest_line[1])
				local rot_axis = Vector3()
				mvector3.cross(rot_axis, BA, EA)
				mvector3.set_static(rot_axis, 0, 0, rot_axis.z)
				out = Vector3()
				mvector3.cross(out, BA, rot_axis)
			end
			mvector3.normalize(out)
			optimal_direction = mvector3.copy(out)
			mvector3.multiply(optimal_direction, -1)
			mvector3.multiply(out, mvector3.dot(out, PA) + 600)
			my_data.optimal_pos = mvector3.copy(data.m_pos)
			mvector3.add(my_data.optimal_pos, out)
		else
			optimal_direction = mvector3.copy(threat_epicenter)
			mvector3.subtract(optimal_direction, data.m_pos)
			mvector3.normalize(optimal_direction)
			local optimal_length = 0
			for _, enemy in pairs(enemies) do
				local enemy_dir = mvector3.copy(threat_epicenter)
				mvector3.subtract(enemy_dir, enemy.m_pos)
				local len = mvector3.dot(enemy_dir, optimal_direction)
				optimal_length = math.max(len, optimal_length)
			end
			local optimal_pos = mvector3.copy(optimal_direction)
			mvector3.multiply(optimal_pos, -(optimal_length + 600))
			mvector3.add(optimal_pos, threat_epicenter)
			my_data.optimal_pos = optimal_pos
		end
		local focus_enemy_angle
		for key, enemy_data in pairs(enemies) do
			local reaction = ShieldLogicAttack._chk_reaction_to_criminal(data, my_data, key, enemy_data)
			if reaction and reaction == "assault" then
				local enemy_dir = mvector3.copy(enemy_data.m_pos)
				mvector3.subtract(enemy_dir, data.m_pos)
				mvector3.normalize(enemy_dir)
				local angle = mvector3.dot(optimal_direction, enemy_dir)
				if enemy_data == my_data.focus_enemy then
					angle = angle + 0.15
				end
				if not ((focus_enemy_verified or not enemy_data.verified) and focus_type) or focus_enemy_angle < angle then
					focus_enemy = enemy_data
					focus_type = reaction
					focus_enemy_angle = angle
					focus_enemy_key = key
					focus_enemy_verified = enemy_data.verified
					focus_enemy_dmg_t = enemy_data.dmg_t
					focus_enemy_verified_t = enemy_data.verified_t
				end
			end
		end
	else
		local target = CopLogicAttack._get_priority_enemy(data, enemies)
		if target then
			focus_enemy = target.enemy_data
			focus_type = target.reaction
			focus_enemy_key = target.key
			focus_enemy_verified = focus_enemy.verified
			focus_enemy_dmg_t = focus_enemy.dmg_t
			focus_enemy_verified_t = focus_enemy.verified_t
			my_data.optimal_pos = CopLogicAttack._find_flank_pos(data, my_data, focus_enemy.unit:movement():nav_tracker())
		else
			local key, enemy_data = next(detected_enemies)
			if enemy_data then
				local reaction = ShieldLogicAttack._chk_reaction_to_criminal(data, my_data, key, enemy_data)
				focus_enemy = enemy_data
				focus_type = reaction
				focus_enemy_key = key
				focus_enemy_verified = focus_enemy.verified
				focus_enemy_dmg_t = focus_enemy.dmg_t
				focus_enemy_verified_t = focus_enemy.verified_t
				my_data.optimal_pos = CopLogicAttack._find_flank_pos(data, my_data, focus_enemy.unit:movement():nav_tracker())
			end
		end
	end
	if my_data.optimal_pos and focus_enemy then
		mvector3.set_z(my_data.optimal_pos, focus_enemy.m_pos.z)
	end
	if focus_enemy then
		if my_data.focus_enemy then
			if my_data.focus_enemy.unit:key() ~= focus_enemy_key then
				managers.groupai:state():on_enemy_disengaging(data.unit, my_data.focus_enemy.unit:key())
				managers.groupai:state():on_enemy_engaging(data.unit, focus_enemy_key)
				ShieldLogicAttack._cancel_optimal_attempt(data, my_data)
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
		ShieldLogicAttack._cancel_optimal_attempt(data, my_data)
	end
	my_data.focus_enemy = focus_enemy
	my_data.focus_type = focus_type
end
function ShieldLogicAttack._chk_reaction_to_criminal(data, my_data, key_criminal, criminal_data)
	local record = managers.groupai:state():criminal_record(key_criminal)
	if record.being_arrested then
	elseif record.status == "disabled" then
		if record.assault_t - record.disabled_t > 0.6 and (record.engaged_force < 5 or CopLogicIdle._am_i_important_to_player(record, data.key)) then
			return "assault"
		end
	elseif criminal_data.unit:movement():tased() then
	else
		return "assault"
	end
end
function ShieldLogicAttack.action_complete_clbk(data, action)
	local my_data = data.internal_data
	local action_type = action:type()
	if action_type == "walk" then
		if my_data.rsrv_pos.stand then
			managers.navigation:unreserve_pos(my_data.rsrv_pos.stand)
			my_data.rsrv_pos.stand = nil
		end
		if action:expired() then
			my_data.rsrv_pos.stand = my_data.rsrv_pos.move_dest
			my_data.rsrv_pos.move_dest = nil
		else
			if my_data.rsrv_pos.move_dest then
				managers.navigation:unreserve_pos(my_data.rsrv_pos.move_dest)
				my_data.rsrv_pos.move_dest = nil
			end
			local reservation = {
				position = mvector3.copy(data.m_pos),
				radius = 70,
				filter = data.pos_rsrv_id
			}
			managers.navigation:add_pos_reservation(reservation)
			my_data.rsrv_pos.stand = reservation
		end
		if my_data.walking_to_optimal_pos then
			my_data.walking_to_optimal_pos = nil
		end
	elseif action_type == "shoot" then
		my_data.shooting = nil
	elseif action_type == "turn" then
		my_data.turning = nil
	elseif action_type == "hurt" and action:expired() then
		ShieldLogicAttack._upd_aim(data, my_data)
	end
end
function ShieldLogicAttack.is_advancing(data)
	if data.internal_data.walking_to_optimal_pos then
		return data.internal_data.rsrv_pos.move_dest.position
	end
end
function ShieldLogicAttack._get_all_paths(data)
	return {
		optimal_path = data.internal_data.optimal_path
	}
end
function ShieldLogicAttack._set_verified_paths(data, verified_paths)
	data.internal_data.optimal_path = verified_paths.optimal_path
end
