CivilianLogicEscort = class(CopLogicBase)
function CivilianLogicEscort.enter(data, new_logic_name, enter_params)
	CopLogicBase.enter(data, new_logic_name, enter_params)
	data.unit:brain():cancel_all_pathing_searches()
	local old_internal_data = data.internal_data
	local my_data = {
		unit = data.unit
	}
	my_data.rsrv_pos = {}
	if old_internal_data then
		my_data.rsrv_pos = old_internal_data.rsrv_pos or my_data.rsrv_pos
	end
	data.unit:brain():set_update_enabled_state(true)
	if data.char_tweak.escort_idle_talk then
		my_data._say_random_t = Application:time() + 45
	end
	CivilianLogicEscort._get_objective_path_data(data, my_data)
	data.internal_data = my_data
	data.unit:base():set_contour(true)
	if data.unit:anim_data().tied then
		local action_data = {
			type = "act",
			body_part = 1,
			variant = "panic",
			clamp_to_graph = true
		}
		data.unit:brain():action_request(action_data)
	end
	if not my_data.been_outlined and tweak_data.character[data.unit:base()._tweak_table].outline_on_discover then
		my_data.outline_detection_task_key = "CivilianLogicIdle._upd_outline_detection" .. tostring(data.key)
		CopLogicBase.queue_task(my_data, my_data.outline_detection_task_key, CivilianLogicIdle._upd_outline_detection, data, data.t + 2)
	end
end
function CivilianLogicEscort.exit(data, new_logic_name, enter_params)
	CopLogicBase.exit(data, new_logic_name, enter_params)
	local my_data = data.internal_data
	data.unit:brain():cancel_all_pathing_searches()
	CopLogicBase.cancel_queued_tasks(my_data)
	data.unit:base():set_contour(false)
	if new_logic_name ~= "inactive" then
		data.unit:brain():set_update_enabled_state(true)
	end
end
function CivilianLogicEscort.update(data)
	local my_data = data.internal_data
	local unit = data.unit
	local objective = data.objective
	local t = data.t
	if my_data._say_random_t and t > my_data._say_random_t then
		data.unit:sound():say("_a02", true)
		my_data._say_random_t = t + math.random(30, 60)
	end
	if CivilianLogicEscort.too_scared_to_move(data) and not data.unit:anim_data().panic then
		my_data.commanded_to_move = nil
		data.unit:movement():action_request({
			type = "act",
			body_part = 1,
			variant = "panic",
			clamp_to_graph = true
		})
	end
	if my_data.processing_advance_path or my_data.processing_coarse_path then
		CivilianLogicEscort._upd_pathing(data, my_data)
	elseif my_data.advancing or my_data.getting_up then
	elseif my_data.advance_path then
		if my_data.commanded_to_move then
			if data.unit:anim_data().standing_hesitant then
				CivilianLogicEscort._begin_advance_action(data, my_data)
			else
				CivilianLogicEscort._begin_stand_hesitant_action(data, my_data)
			end
		end
	elseif objective then
		if my_data.coarse_path then
			local coarse_path = my_data.coarse_path
			local cur_index = my_data.coarse_path_index
			local total_nav_points = #coarse_path
			if cur_index == total_nav_points then
				objective.in_place = true
				managers.groupai:state():on_civilian_objective_complete(unit, objective)
				return
			else
				my_data.rsrv_pos.path = nil
				local to_pos = coarse_path[cur_index + 1][2]
				my_data.advance_path_search_id = tostring(unit:key()) .. "advance"
				my_data.processing_advance_path = true
				unit:brain():search_for_path(my_data.advance_path_search_id, to_pos)
			end
		else
			local search_id = tostring(unit:key()) .. "coarse"
			if unit:brain():search_for_coarse_path(search_id, objective.nav_seg) then
				my_data.coarse_path_search_id = search_id
				my_data.processing_coarse_path = true
			end
		end
	else
		CopLogicBase._exit(data.unit, "idle")
	end
end
function CivilianLogicEscort.on_intimidated(data, amount, aggressor_unit)
	local scared_reason = CivilianLogicEscort.too_scared_to_move(data)
	if scared_reason then
		data.unit:sound():say("_a01", true)
	else
		data.internal_data.commanded_to_move = true
	end
end
function CivilianLogicEscort.action_complete_clbk(data, action)
	CopLogicTravel.action_complete_clbk(data, action)
	local my_data = data.internal_data
	local action_type = action:type()
	if action_type == "walk" then
		my_data.advancing = nil
	elseif action_type == "act" and my_data.getting_up then
		my_data.getting_up = nil
	end
end
function CivilianLogicEscort._upd_pathing(data, my_data)
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
				print("[CivilianLogicEscort:_upd_pathing] advance_path failed")
				managers.groupai:state():on_civilian_objective_failed(data.unit, data.objective)
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
			else
				managers.groupai:state():on_civilian_objective_failed(data.unit, data.objective)
				return
			end
		end
	end
end
function CivilianLogicEscort.on_new_objective(data, old_objective)
	CivilianLogicIdle.on_new_objective(data, old_objective)
end
function CivilianLogicEscort.damage_clbk(data, damage_info)
end
function CivilianLogicEscort._get_objective_path_data(data, my_data)
	local objective = data.objective
	local path_data = objective.path_data
	local path_style = objective.path_style
	if path_data then
		if path_style == "precise" then
			local path = {
				mvector3.copy(data.m_pos)
			}
			for _, point in ipairs(path_data.points) do
				table.insert(path, point.position)
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
		elseif path_style == "coarse" then
			local t_ins = table.insert
			my_data.coarse_path_index = 1
			local start_seg = data.unit:movement():nav_tracker():nav_segment()
			my_data.coarse_path = {
				{start_seg}
			}
			local coarse_path = my_data.coarse_path
			local points = path_data.points
			local i_point = 1
			while i_point <= #path_data.points do
				local next_pos = points[i_point].position
				local next_seg = managers.navigation:get_nav_seg_from_pos(next_pos)
				t_ins(coarse_path, {
					next_seg,
					mvector3.copy(next_pos)
				})
				i_point = i_point + 1
			end
		elseif path_style == "destination" then
			my_data.coarse_path_index = 1
			local start_seg = data.unit:movement():nav_tracker():nav_segment()
			local end_pos = mvector3.copy(path_data.points[#path_data.points].position)
			local end_seg = managers.navigation:get_nav_seg_from_pos(end_pos)
			my_data.coarse_path = {
				{start_seg},
				{end_seg, end_pos}
			}
		end
	end
end
function CivilianLogicEscort.too_scared_to_move(data)
	local my_data = data.internal_data
	local nobody_close = true
	local min_dis_sq = 1000000
	for c_key, c_data in pairs(managers.groupai:state():all_criminals()) do
		if min_dis_sq > mvector3.distance_sq(c_data.m_pos, data.m_pos) then
			nobody_close = nil
			break
		end
	end
	if nobody_close then
		return "abandoned"
	end
	local nobody_close = true
	local min_dis_sq = tweak_data.character[data.unit:base()._tweak_table].escort_scared_dist
	min_dis_sq = min_dis_sq * min_dis_sq
	for c_key, c_data in pairs(managers.enemy:all_enemies()) do
		if not c_data.unit:anim_data().surrender and c_data.unit:brain()._current_logic_name ~= "trade" and min_dis_sq > mvector3.distance_sq(c_data.m_pos, data.m_pos) and math.abs(c_data.m_pos.z - data.m_pos.z) < 250 then
			nobody_close = nil
			break
		end
	end
	if not nobody_close then
		return "pigs"
	end
	return
end
function CivilianLogicEscort._begin_advance_action(data, my_data)
	CopLogicAttack._correct_path_start_pos(data, my_data.advance_path)
	local objective = data.objective
	local haste = objective and objective.haste or "run"
	local new_action_data = {
		type = "walk",
		nav_path = my_data.advance_path,
		variant = haste,
		body_part = 2,
		no_walk = true,
		no_strafe = haste == "walk"
	}
	my_data.advancing = data.unit:brain():action_request(new_action_data)
	if my_data.advancing then
		my_data.advance_path = nil
		my_data.rsrv_pos.move_dest = my_data.rsrv_pos.path
		my_data.rsrv_pos.path = nil
		if my_data.rsrv_pos.stand then
			managers.navigation:unreserve_pos(my_data.rsrv_pos.stand)
			my_data.rsrv_pos.stand = nil
		end
	else
		debug_pause("[CivilianLogicEscort._begin_advance_action] failed to start")
	end
end
function CivilianLogicEscort._begin_stand_hesitant_action(data, my_data)
	local action = {
		type = "act",
		variant = "so_escort_get_up_hesitant",
		body_part = 1,
		clamp_to_graph = true,
		blocks = {
			action = -1,
			walk = -1,
			hurt = -1,
			heavy_hurt = -1
		}
	}
	my_data.getting_up = data.unit:movement():action_request(action)
end
function CivilianLogicEscort._get_all_paths(data)
	return {
		advance_path = data.internal_data.advance_path
	}
end
function CivilianLogicEscort._set_verified_paths(data, verified_paths)
	data.internal_data.stare_path = verified_paths.stare_path
end
