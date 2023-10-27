CopLogicIdle = class(CopLogicBase)
CopLogicIdle.allowed_transitional_actions = {
	{
		"idle",
		"hurt",
		"dodge"
	},
	{"idle", "turn"},
	{"idle", "reload"},
	{
		"hurt",
		"stand",
		"crouch"
	}
}
function CopLogicIdle.enter(data, new_logic_name, enter_params)
	CopLogicBase.enter(data, new_logic_name, enter_params)
	local my_data = {
		unit = data.unit
	}
	my_data.detection = tweak_data.character[data.unit:base()._tweak_table].detection.idle
	my_data.enemy_detect_slotmask = managers.slot:get_mask("criminals")
	my_data.ai_visibility_slotmask = managers.slot:get_mask("AI_visibility")
	my_data.rsrv_pos = {}
	local old_internal_data = data.internal_data
	if old_internal_data then
		my_data.suspected_enemies = old_internal_data.suspected_enemies or {}
		my_data.detected_enemies = old_internal_data.detected_enemies or {}
		if old_internal_data.focus_enemy then
			managers.groupai:state():on_enemy_disengaging(data.unit, old_internal_data.focus_enemy.unit:key())
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
	data.internal_data = my_data
	if not my_data.rsrv_pos.stand then
		local pos_rsrv = {
			position = mvector3.copy(data.m_pos),
			radius = 60,
			filter = data.pos_rsrv_id
		}
		my_data.rsrv_pos.stand = pos_rsrv
		managers.navigation:add_pos_reservation(pos_rsrv)
	end
	local key_str = tostring(data.unit:key())
	my_data.detection_task_key = "CopLogicIdle._update_enemy_detection" .. key_str
	CopLogicBase.queue_task(my_data, my_data.detection_task_key, CopLogicIdle._update_enemy_detection, data, data.t)
	if my_data.nearest_cover or my_data.best_cover then
		my_data.cover_update_task_key = "CopLogicIdle._update_cover" .. key_str
		CopLogicBase.add_delayed_clbk(my_data, my_data.cover_update_task_key, callback(CopLogicTravel, CopLogicTravel, "_update_cover", data), data.t + 1)
	end
	local objective = data.objective
	if objective then
		my_data.scan = objective.scan
	else
		my_data.scan = true
	end
	if my_data.scan then
		my_data.stare_path_search_id = "stare" .. key_str
		my_data.wall_stare_task_key = "CopLogicIdle._chk_stare_into_wall" .. key_str
	end
	if my_data.scan and (not objective or not objective.action) then
		CopLogicBase.queue_task(my_data, my_data.wall_stare_task_key, CopLogicIdle._chk_stare_into_wall_1, data, data.t)
	end
	local entry_action
	if objective and objective.action then
		entry_action = data.unit:brain():action_request(objective.action)
		if objective.action_start_clbk then
			objective.action_start_clbk(data.unit)
		end
		if objective.action.type == "act" then
			my_data.acting = true
			if objective.type == "act" then
				my_data.performing_act_objective = objective
				if objective.act_duration then
					my_data.act_complete_clbk_id = "CopLogicIdle_act_duration" .. key_str
					local act_complete_t = data.t + objective.act_duration
					CopLogicBase.add_delayed_clbk(my_data, my_data.act_complete_clbk_id, callback(CopLogicIdle, CopLogicIdle, "clbk_act_complete", data), act_complete_t)
				end
			end
		end
	end
	if objective and objective.stance then
		local upper_body_action = data.unit:movement()._active_actions[3]
		if not upper_body_action or upper_body_action:type() ~= "shoot" then
			data.unit:movement():set_stance(objective.stance)
		end
	end
	CopLogicBase._reset_attention(data)
	if not entry_action and not data.unit:movement():chk_action_forbidden("walk") then
		CopLogicTravel.reset_actions(data, my_data, old_internal_data, CopLogicIdle.allowed_transitional_actions)
		if data.char_tweak.no_stand and data.unit:anim_data().stand then
			CopLogicAttack._chk_request_action_crouch(data)
		end
	else
		data.unit:movement():set_allow_fire(false)
	end
end
function CopLogicIdle.exit(data, new_logic_name, enter_params)
	CopLogicBase.exit(data, new_logic_name, enter_params)
	local my_data = data.internal_data
	if my_data.acting and not data.unit:character_damage():dead() then
		local new_action = {type = "idle", body_part = 1}
		data.unit:brain():action_request(new_action)
	end
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
function CopLogicIdle.update(data)
	local my_data = data.internal_data
	if CopLogicIdle._chk_relocate(data) then
		return
	end
	CopLogicIdle._upd_pathing(data, my_data)
	CopLogicIdle._upd_scan(data, my_data)
end
function CopLogicIdle._update_enemy_detection(data)
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
		local exit_state
		if not my_data.performing_act_objective or my_data.performing_act_objective.interrupt_on == "contact" or my_data.performing_act_objective.interrupt_on == "obstructed" and focus_enemy.verified_dis < 800 and math.abs(focus_enemy.m_pos.z - data.m_pos.z) < 300 or data.unit:anim_data().act_idle then
			exit_state = focus_type == "assault" and "attack" or focus_type
		end
		if exit_state then
			if focus_type == "assault" and focus_enemy.verified and data.t - managers.groupai:state():criminal_record(focus_enemy_key).det_t > 15 then
				if not focus_enemy.is_deployable then
					data.unit:sound():say("_c01x_plu", true)
				end
				CopLogicIdle.try_dodge(data, "on_contact")
			end
			managers.groupai:state():on_enemy_engaging(data.unit, focus_enemy_key)
			my_data.focus_enemy = focus_enemy
			my_data.focus_type = focus_type
			if data.objective and data.objective.type ~= "free" then
				managers.groupai:state():on_objective_failed(data.unit, data.objective)
			else
				CopLogicBase._exit(data.unit, exit_state)
			end
			CopLogicBase._report_detections(enemies)
			return
		end
	end
	CopLogicBase.queue_task(my_data, my_data.detection_task_key, CopLogicIdle._update_enemy_detection, data, data.t + delay)
	CopLogicBase._report_detections(enemies)
end
function CopLogicIdle._upd_pathing(data, my_data)
	if data.pathing_results then
		local path = my_data.stare_path_search_id and data.pathing_results[my_data.stare_path_search_id]
		if path then
			data.pathing_results[my_data.stare_path_search_id] = nil
			if not next(data.pathing_results) then
				data.pathing_results = nil
			end
			if path ~= "failed" then
				my_data.stare_path = path
				CopLogicBase.queue_task(my_data, my_data.wall_stare_task_key, CopLogicIdle._chk_stare_into_wall_2, data, data.t)
			else
				print("[CopLogicIdle:_upd_pathing] stare path failed!", data.unit:key())
				local path_jobs = my_data.stare_path_pos
				table.remove(path_jobs)
				if #path_jobs ~= 0 then
					data.unit:brain():search_for_path(my_data.stare_path_search_id, path_jobs[#path_jobs])
				else
					my_data.stare_path_pos = nil
				end
			end
		end
	end
end
function CopLogicIdle._upd_scan(data, my_data)
	if not (my_data.stare_pos and my_data.next_scan_t) or data.t < my_data.next_scan_t or data.unit:movement():chk_action_forbidden("walk") then
		return
	end
	local beanbag = my_data.scan_beanbag
	if not beanbag then
		beanbag = {}
		for i_pos, pos in ipairs(my_data.stare_pos) do
			table.insert(beanbag, pos)
		end
		my_data.scan_beanbag = beanbag
	end
	local nr_pos = #beanbag
	local scan_pos
	local lucky_i_pos = math.random(nr_pos)
	scan_pos = beanbag[lucky_i_pos]
	if #beanbag == 1 then
		my_data.scan_beanbag = nil
	else
		beanbag[lucky_i_pos] = beanbag[#beanbag]
		table.remove(beanbag)
	end
	CopLogicBase._set_attention_on_pos(data, scan_pos)
	if CopLogicIdle._chk_request_action_turn_to_look_pos(data, my_data, data.m_pos, scan_pos) then
		local upper_body_action = data.unit:movement()._active_actions[3]
		if not upper_body_action then
			local idle_action = {type = "idle", body_part = 3}
			data.unit:movement():action_request(idle_action)
		end
	end
	my_data.next_scan_t = data.t + math.random(3, 10)
end
function CopLogicIdle.damage_clbk(data, damage_info)
	local enemy = damage_info.attacker_unit
	if enemy then
		local my_data = data.internal_data
		local enemy_key = enemy:key()
		local enemy_data = my_data.detected_enemies[enemy_key]
		local t = TimerManager:game():time()
		if enemy_data then
			enemy_data.verified_t = t
			enemy_data.verified = true
			enemy_data.verified_pos = mvector3.copy(enemy:movement():m_stand_pos())
			enemy_data.verified_dis = mvector3.distance(enemy_data.verified_pos, data.unit:movement():m_stand_pos())
			enemy_data.dmg_t = t
			enemy_data.alert_t = t
		else
			local enemy_data = CopLogicAttack._create_detected_enemy_data(data, enemy)
			enemy_data.verified_t = t
			enemy_data.verified = true
			enemy_data.dmg_t = t
			enemy_data.alert_t = t
			my_data.detected_enemies[enemy_key] = enemy_data
			my_data.suspected_enemies[enemy_key] = nil
		end
	end
	local is_free_objective = not data.objective or data.objective and (not data.objective.interrupt_on or data.objective.type == "free" and (not data.objective.nav_seg or data.objective.in_place))
	if data.unit:character_damage():health_ratio() < 0.55 and not managers.groupai:state():get_assault_mode() and not data.internal_data.acting and (not data.objective or not data.objective.no_retreat) and not data.char_tweak.no_retreat and is_free_objective then
		if data.objective and not is_free_objective then
			my_data.exiting = true
			managers.groupai:state():on_objective_failed(data.unit, data.objective)
		end
		CopLogicBase._exit(data.unit, "flee")
	end
	if enemy then
		managers.groupai:state():criminal_spotted(enemy)
		managers.groupai:state():report_aggression(enemy)
	end
end
function CopLogicIdle.on_alert(data, alert_data)
	local enemy = alert_data[5] or alert_data[4]
	local my_data = data.internal_data
	local t = TimerManager:game():time()
	local enemy_key = enemy:key()
	if managers.groupai:state():criminal_record(enemy_key) then
		local enemy_data = my_data.detected_enemies[enemy_key]
		local action_data
		if enemy_data then
			enemy_data.verified_pos = mvector3.copy(enemy:movement():m_stand_pos())
			enemy_data.verified_dis = mvector3.distance(enemy_data.verified_pos, data.unit:movement():m_stand_pos())
			if alert_data[1] ~= "voice" then
				enemy_data.alert_t = t
			end
		else
			local enemy_data = CopLogicAttack._create_detected_enemy_data(data, enemy)
			if alert_data[1] ~= "voice" then
				enemy_data.alert_t = t
			end
			my_data.detected_enemies[enemy_key] = enemy_data
			my_data.suspected_enemies[enemy_key] = nil
			if data.unit:anim_data().idle and not data.unit:movement():chk_action_forbidden("walk") then
				action_data = {
					type = "act",
					body_part = 1,
					variant = "surprised"
				}
				data.unit:brain():action_request(action_data)
			end
		end
		if alert_data[1] ~= "voice" and data.important and not action_data and not data.unit:anim_data().crouch and not data.unit:movement():chk_action_forbidden("walk") then
			local tweak = tweak_data.character[data.unit:base()._tweak_table]
			if not action_data and tweak.allow_crouch then
				local lower_body_action = data.unit:movement()._active_actions[2]
				if lower_body_action and lower_body_action:type() == "walk" then
					if tweak.crouch_move then
						action_data = CopLogicAttack._chk_request_action_crouch(data)
					end
				else
					action_data = CopLogicAttack._chk_request_action_crouch(data)
				end
			end
		end
		managers.groupai:state():criminal_spotted(enemy)
		managers.groupai:state():report_aggression(enemy)
	end
	my_data.alert_t = t
end
function CopLogicIdle.on_new_objective(data, old_objective)
	local new_objective = data.objective
	TeamAILogicBase.on_new_objective(data, old_objective)
	local my_data = data.internal_data
	if new_objective then
		local objective_type = new_objective.type
		if (new_objective.nav_seg or objective_type == "follow") and not new_objective.in_place then
			CopLogicBase._exit(data.unit, "travel")
		elseif objective_type == "guard" then
			CopLogicBase._exit(data.unit, "guard")
		elseif objective_type == "security" then
			CopLogicBase._exit(data.unit, "security")
		elseif objective_type == "sniper" then
			CopLogicBase._exit(data.unit, "sniper")
		elseif objective_type == "free" and my_data.exiting then
		elseif new_objective.action or not my_data.focus_enemy then
			CopLogicBase._exit(data.unit, "idle")
		else
			CopLogicBase._exit(data.unit, "attack")
		end
	elseif not my_data.exiting then
		CopLogicBase._exit(data.unit, "idle")
	end
	if old_objective and old_objective.fail_clbk then
		old_objective.fail_clbk()
	end
end
function CopLogicIdle._chk_reaction_to_criminal(data, key_criminal, criminal_data, stationary)
	local u_criminal = criminal_data.unit
	local record = managers.groupai:state():criminal_record(key_criminal)
	local assault_mode = managers.groupai:state():get_assault_mode()
	if record.is_deployable or data.t < record.arrest_timeout then
		return "assault"
	end
	local can_disarm = not stationary and not data.char_tweak.no_disarm
	local can_arrest = not data.char_tweak.no_arrest
	local visible = criminal_data.verified
	if record.status == "disabled" then
		if record.assault_t - record.disabled_t > 0.6 and (record.engaged_force < 25 or CopLogicIdle._am_i_important_to_player(record, data.key)) then
			return "assault"
		end
	elseif record.being_arrested then
		if record.being_disarmed then
			if not assault_mode and can_arrest and table.size(record.being_arrested) < 4 and mvector3.distance(u_criminal:movement():m_pos(), data.m_pos) < 2000 and visible then
				return "arrest"
			end
		elseif can_disarm then
			return "disarm"
		end
	elseif record.engaged_force == 0 and data.t - record.assault_t > 10 then
		if not assault_mode and can_arrest and mvector3.distance(u_criminal:movement():m_pos(), data.m_pos) < 2000 and visible then
			return "arrest"
		else
			return "assault"
		end
	else
		local criminal_fwd = u_criminal:movement():m_head_rot():y()
		local criminal_vec = data.m_pos - u_criminal:movement():m_pos()
		mvector3.normalize(criminal_vec)
		local criminal_look_dot = mvector3.dot(criminal_vec, criminal_fwd)
		if criminal_look_dot < 0 then
			if not assault_mode and can_arrest and mvector3.distance(u_criminal:movement():m_pos(), data.m_pos) < 2000 and visible then
				return "arrest"
			else
				return "assault"
			end
		else
			return "assault"
		end
	end
end
function CopLogicIdle._am_i_important_to_player(record, my_key)
	if record.important_enemies then
		for i, test_e_key in ipairs(record.important_enemies) do
			if test_e_key == my_key then
				return true
			end
		end
	end
end
function CopLogicIdle.on_detected_enemy_destroyed(data, enemy_unit)
	local my_data = data.internal_data
	if my_data.focus_enemy and my_data.focus_enemy.unit:key() == enemy_unit:key() then
		my_data.focus_enemy = nil
	end
	if my_data.threat_enemy and my_data.threat_enemy.unit:key() == enemy_unit:key() then
		my_data.threat_enemy = nil
	end
	data.internal_data.detected_enemies[enemy_unit:key()] = nil
end
function CopLogicIdle.on_criminal_neutralized(data, criminal_key)
	local my_data = data.internal_data
	local record = managers.groupai:state():criminal_record(criminal_key)
	if record.status == "dead" or record.status == "removed" then
		my_data.detected_enemies[criminal_key] = nil
		my_data.suspected_enemies[criminal_key] = nil
	end
end
function CopLogicIdle.on_intimidated(data, amount, aggressor_unit)
	local surrender = false
	local my_data = data.internal_data
	if data.char_tweak.surrender_easy and (not (next(my_data.detected_enemies) or next(my_data.suspected_enemies)) or data.unit:anim_data().equip) then
		surrender = true
	end
	if data.char_tweak.surrender_hard and not my_data.detected_enemies[aggressor_unit:key()] then
		local vec = data.m_pos - aggressor_unit:movement():m_pos()
		mvector3.normalize(vec)
		local fwd = data.unit:movement():m_rot():y()
		local fwd_dot = fwd:dot(vec)
		if 0 < fwd_dot then
			surrender = true
		end
	end
	surrender = surrender and CopLogicIdle._surrender(data, amount)
	managers.groupai:state():criminal_spotted(aggressor_unit)
	return surrender
end
function CopLogicIdle._surrender(data, amount)
	if managers.groupai:state():police_hostage_count() < 4 and not managers.groupai:state():get_assault_mode() then
		local params = {effect = amount}
		data.unit:brain():set_logic("intimidated", params)
		if data.objective then
			managers.groupai:state():on_objective_failed(data.unit, data.objective)
		end
		return true
	end
	return false
end
function CopLogicIdle._chk_stare_into_wall_1(data)
	local my_data = data.internal_data
	local walk_from_pos = data.m_pos
	local ray_from_pos = data.unit:movement():m_stand_pos()
	local ray_to_pos = Vector3()
	local nav_manager = managers.navigation
	local all_nav_segs = nav_manager._nav_segments
	local my_tracker = data.unit:movement():nav_tracker()
	local my_nav_seg = my_tracker:nav_segment()
	local neighbour_segs = nav_manager:get_nav_seg_neighbours(my_nav_seg)
	local walk_params = {tracker_from = my_tracker}
	local slotmask = my_data.ai_visibility_slotmask
	local mvec3_set = mvector3.set
	local mvec3_set_z = mvector3.set_z
	local stare_pos = {}
	local path_tasks = {}
	local groupai_state = managers.groupai:state()
	local _f_area_dangerous
	if data.unit:in_slot(managers.slot:get_mask("enemies")) then
		_f_area_dangerous = groupai_state.chk_area_leads_to_enemy
	end
	for seg_id, door_list in pairs(neighbour_segs) do
		local neigh_nav_seg = all_nav_segs[seg_id]
		if not neigh_nav_seg.disabled and (not _f_area_dangerous or _f_area_dangerous(groupai_state, my_nav_seg, seg_id, true)) then
			local seg_pos = nav_manager:find_random_position_in_segment(seg_id)
			walk_params.pos_to = seg_pos
			local ray_hit = nav_manager:raycast(walk_params)
			if ray_hit then
				mvec3_set(ray_to_pos, seg_pos)
				mvec3_set_z(ray_to_pos, ray_to_pos.z + 160)
				ray_hit = World:raycast("ray", ray_from_pos, ray_to_pos, "slot_mask", slotmask)
				if ray_hit then
					table.insert(path_tasks, seg_pos)
				else
					table.insert(stare_pos, ray_to_pos)
				end
			end
			if not ray_hit then
				table.insert(stare_pos, seg_pos + math.UP * 160)
			end
		end
	end
	if 0 < #stare_pos then
		my_data.stare_pos = stare_pos
		my_data.next_scan_t = 0
	end
	if 0 < #path_tasks then
		my_data.stare_path_pos = path_tasks
		data.unit:brain():search_for_path(my_data.stare_path_search_id, path_tasks[#path_tasks])
	end
end
function CopLogicIdle._chk_stare_into_wall_2(data)
	local my_data = data.internal_data
	local slotmask = my_data.ai_visibility_slotmask
	local path_jobs = my_data.stare_path_pos
	local stare_path = my_data.stare_path
	local f_nav_point_pos = CopLogicIdle._nav_point_pos
	if not stare_path then
		return
	end
	for i, nav_point in ipairs(stare_path) do
		stare_path[i] = f_nav_point_pos(nav_point)
	end
	local mvec3_dis = mvector3.distance
	local mvec3_lerp = mvector3.lerp
	local mvec3_cpy = mvector3.copy
	local mvec3_set = mvector3.set
	local mvec3_set_z = mvector3.set_z
	local dis_table = {}
	local total_dis = 0
	local nr_nodes = #stare_path
	local i_node = 1
	local this_pos = stare_path[1]
	repeat
		local next_pos = stare_path[i_node + 1]
		local dis = mvec3_dis(this_pos, next_pos)
		total_dis = total_dis + dis
		table.insert(dis_table, dis)
		this_pos = next_pos
		i_node = i_node + 1
	until i_node == nr_nodes
	local nr_loops = 5
	local dis_step = total_dis / (nr_loops + 1)
	local ray_from_pos = data.unit:movement():m_stand_pos()
	local ray_to_pos = Vector3()
	local furthest_good_pos
	local dis_in_seg = 0
	local index = nr_nodes
	local i_loop = 0
	repeat
		dis_in_seg = dis_in_seg + dis_step
		local seg_dis = dis_table[index - 1]
		while dis_in_seg > seg_dis do
			index = index - 1
			dis_in_seg = dis_in_seg - seg_dis
			seg_dis = dis_table[index - 1]
		end
		mvec3_lerp(ray_to_pos, stare_path[index], stare_path[index - 1], dis_in_seg / seg_dis)
		mvec3_set_z(ray_to_pos, ray_to_pos.z + 160)
		local hit = World:raycast("ray", ray_from_pos, ray_to_pos, "slot_mask", slotmask, "ray_type", "ai_vision")
		if not hit then
			if not my_data.stare_pos then
				my_data.next_scan_t = 0
				my_data.stare_pos = {}
			end
			table.insert(my_data.stare_pos, ray_to_pos)
			break
		end
		i_loop = i_loop + 1
	until i_loop == nr_loops
	my_data.stare_path = nil
	table.remove(path_jobs)
	if 0 < #path_jobs then
		data.unit:brain():search_for_path(my_data.stare_path_search_id, path_jobs[#path_jobs])
	else
		my_data.stare_path_pos = nil
	end
end
function CopLogicIdle._chk_request_action_turn_to_look_pos(data, my_data, my_pos, look_pos)
	local fwd = data.unit:movement():m_rot():y()
	local target_vec = look_pos - my_pos
	local error_polar = target_vec:to_polar_with_reference(fwd, math.UP)
	local error_spin = error_polar.spin
	local abs_err_spin = math.abs(error_spin)
	local tolerance = error_spin < 0 and 50 or 30
	local err_to_correct = error_spin - tolerance * math.sign(error_spin)
	if math.sign(err_to_correct) ~= math.sign(error_spin) then
		return
	end
	local err_to_correct_abs = math.abs(err_to_correct)
	local angle_str
	if err_to_correct_abs < 5 then
		return
	end
	local new_action_data = {
		type = "turn",
		body_part = 2,
		angle = err_to_correct,
		sync = true
	}
	if data.unit:brain():action_request(new_action_data) then
		my_data.turning = err_to_correct
		return true
	end
end
function CopLogicIdle.on_area_safety(data, nav_seg, safe, event)
	if not safe and event.reason == "criminal" then
		local my_data = data.internal_data
		local u_criminal = event.record.unit
		local key_criminal = u_criminal:key()
		if not my_data.detected_enemies[key_criminal] then
			local enemy_data = CopLogicAttack._create_detected_enemy_data(data, u_criminal)
			my_data.detected_enemies[key_criminal] = enemy_data
			my_data.suspected_enemies[key_criminal] = nil
		end
	end
end
function CopLogicIdle.action_complete_clbk(data, action)
	local action_type = action:type()
	if action_type == "turn" then
		data.internal_data.turning = nil
	elseif action_type == "act" then
		local my_data = data.internal_data
		my_data.acting = nil
		if my_data.scan and not my_data.exiting and (not my_data.queued_tasks or not my_data.queued_tasks[my_data.wall_stare_task_key]) and not my_data.stare_path_pos then
			CopLogicBase.queue_task(my_data, my_data.wall_stare_task_key, CopLogicIdle._chk_stare_into_wall_1, data, data.t)
		end
		CopLogicBase.chk_cancel_delayed_clbk(my_data, my_data.act_complete_clbk_id)
		if my_data.performing_act_objective then
			local old_objective = my_data.performing_act_objective
			my_data.performing_act_objective = nil
			if action:expired() then
				managers.groupai:state():on_objective_complete(data.unit, old_objective)
			else
				managers.groupai:state():on_objective_failed(data.unit, old_objective)
			end
		end
	elseif action_type == "hurt" and action:expired() then
		CopLogicIdle.try_dodge(data, "on_hurt")
	end
end
function CopLogicIdle.is_available_for_assignment(data)
	return (not data.internal_data.performing_act_objective or data.unit:anim_data().act_idle) and not data.internal_data.exiting
end
function CopLogicIdle.clbk_act_complete(ignore_this, data)
	local my_data = data.internal_data
	CopLogicBase.on_delayed_clbk(my_data, my_data.act_complete_clbk_id)
	if my_data.performing_act_objective then
		local old_objective = my_data.performing_act_objective
		my_data.performing_act_objective = nil
		my_data.acting = nil
		managers.groupai:state():on_objective_complete(data.unit, old_objective)
	end
end
function CopLogicIdle.dodge(data, hipshot)
	if not data.unit:movement():chk_action_forbidden("walk") then
		return CopLogicIdle.try_dodge(data, hipshot and "on_hit" or "scared")
	end
	return nil
end
function CopLogicIdle.try_dodge(data, dodge_type)
	local current_actions = data.unit:movement()._active_actions[1]
	if current_actions and current_actions:type() == "dodge" then
		return nil
	end
	local tweak_dodge = tweak_data.character[data.unit:base()._tweak_table].dodge
	if not tweak_dodge then
		return nil
	end
	local tweak = tweak_dodge[dodge_type]
	if math.random() > tweak.chance then
		return nil
	end
	local var_rand = math.random()
	local variation = #tweak.variation
	for i = 1, #tweak.variation do
		if var_rand <= tweak.variation[i] then
			variation = i - 1
			break
		end
	end
	local action_data = CopActionDodge.try_dodge(data.unit, variation)
	if action_data then
		return data.unit:movement():action_request(action_data)
	end
	return nil
end
function CopLogicIdle._nav_point_pos(nav_point)
	return nav_point.x and nav_point or nav_point:script_data().element:value("position")
end
function CopLogicIdle._chk_relocate(data)
	if data.objective and data.objective.type == "follow" then
		local relocate
		local follow_unit = data.objective.follow_unit
		local advance_pos = follow_unit:brain() and follow_unit:brain():is_advancing()
		local follow_unit_pos = advance_pos or data.m_pos
		if data.objective.relocated_to and mvector3.equal(data.objective.relocated_to, follow_unit_pos) then
			return
		end
		if mvector3.distance(follow_unit:movement():m_pos(), follow_unit_pos) > data.objective.distance then
			relocate = true
		end
		if not relocate then
			local ray_params = {
				tracker_from = data.unit:movement():nav_tracker(),
				pos_to = follow_unit_pos
			}
			local ray_res = managers.navigation:raycast(ray_params)
			if ray_res then
				relocate = true
			end
		end
		if relocate then
			data.objective.in_place = nil
			data.objective.nav_seg = follow_unit:movement():nav_tracker():nav_segment()
			data.objective.relocated_to = mvector3.copy(follow_unit_pos)
			CopLogicBase._exit(data.unit, "travel")
			return true
		end
	end
end
function CopLogicIdle._get_all_paths(data)
	return {
		stare_path = data.internal_data.stare_path
	}
end
function CopLogicIdle._set_verified_paths(data, verified_paths)
	data.internal_data.stare_path = verified_paths.stare_path
end
