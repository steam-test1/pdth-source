CivilianLogicTravel = class(CopLogicBase)
function CivilianLogicTravel.enter(data, new_logic_name, enter_params)
	CopLogicBase.enter(data, new_logic_name, enter_params)
	data.unit:brain():cancel_all_pathing_searches()
	local old_internal_data = data.internal_data
	local my_data = {
		unit = data.unit
	}
	my_data.rsrv_pos = {}
	if old_internal_data then
		my_data.rsrv_pos = old_internal_data.rsrv_pos or my_data.rsrv_pos
		my_data.has_outline = old_internal_data.has_outline
		my_data.been_outlined = old_internal_data.been_outlined
	end
	data.unit:brain():set_update_enabled_state(true)
	CivilianLogicEscort._get_objective_path_data(data, my_data)
	data.internal_data = my_data
	if not my_data.been_outlined and tweak_data.character[data.unit:base()._tweak_table].outline_on_discover then
		my_data.outline_detection_task_key = "CivilianLogicIdle._upd_outline_detection" .. tostring(data.key)
		CopLogicBase.queue_task(my_data, my_data.outline_detection_task_key, CivilianLogicIdle._upd_outline_detection, data, data.t + 2)
	end
	managers.groupai:state():register_fleeing_civilian(data.key, data.unit)
end
function CivilianLogicTravel.exit(data, new_logic_name, enter_params)
	CopLogicBase.exit(data, new_logic_name, enter_params)
	local my_data = data.internal_data
	data.unit:brain():cancel_all_pathing_searches()
	CopLogicBase.cancel_delayed_clbks(my_data)
	CopLogicBase.cancel_queued_tasks(my_data)
	managers.groupai:state():unregister_fleeing_civilian(data.key)
	if new_logic_name ~= "inactive" then
		data.unit:brain():set_update_enabled_state(true)
	end
end
function CivilianLogicTravel.update(data)
	local my_data = data.internal_data
	local unit = data.unit
	local objective = data.objective
	local t = data.t
	if my_data.processing_advance_path or my_data.processing_coarse_path then
		CivilianLogicEscort._upd_pathing(data, my_data)
	elseif my_data.advancing then
	elseif my_data.advance_path then
		CopLogicAttack._correct_path_start_pos(data, my_data.advance_path)
		local end_rot
		if my_data.coarse_path_index == #my_data.coarse_path - 1 then
			end_rot = objective and objective.rot
		end
		local haste = objective and objective.haste or "walk"
		local new_action_data = {
			type = "walk",
			nav_path = my_data.advance_path,
			variant = haste,
			body_part = 2,
			no_walk = true,
			no_strafe = haste == "walk",
			end_rot = end_rot
		}
		my_data.starting_advance_action = true
		my_data.advancing = data.unit:brain():action_request(new_action_data)
		my_data.starting_advance_action = false
		if my_data.advancing then
			my_data.advance_path = nil
			my_data.rsrv_pos.move_dest = my_data.rsrv_pos.path
			my_data.rsrv_pos.path = nil
			if my_data.rsrv_pos.stand then
				managers.navigation:unreserve_pos(my_data.rsrv_pos.stand)
				my_data.rsrv_pos.stand = nil
			end
		end
	elseif objective then
		if my_data.coarse_path then
			local coarse_path = my_data.coarse_path
			local cur_index = my_data.coarse_path_index
			local total_nav_points = #coarse_path
			if cur_index >= total_nav_points then
				objective.in_place = true
				if objective.type ~= "escort" and objective.type ~= "act" then
					managers.groupai:state():on_civilian_objective_complete(unit, objective)
				else
					CivilianLogicTravel.on_new_objective(data)
				end
				return
			else
				my_data.rsrv_pos.path = nil
				local to_pos
				if objective.pos and cur_index == total_nav_points - 1 then
					to_pos = objective.pos
				else
					to_pos = coarse_path[cur_index + 1][2]
				end
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
function CivilianLogicTravel.on_new_objective(data, old_objective)
	CivilianLogicIdle.on_new_objective(data, old_objective)
end
function CivilianLogicTravel.action_complete_clbk(data, action)
	CopLogicTravel.action_complete_clbk(data, action)
end
function CivilianLogicTravel.on_alert(data, alert_data)
	return CivilianLogicIdle.on_alert(data, alert_data)
end
function CivilianLogicTravel.on_intimidated(data, amount, aggressor_unit)
	local logic_params = {amount = amount, aggressor_unit = aggressor_unit}
	local anim_data = data.unit:anim_data()
	if anim_data.run then
		logic_params.initial_act = "halt"
	end
	data.unit:sound():say("_a02x_any", true)
	CivilianLogicIdle.switch_logic(data, {type = "free", surrender_data = logic_params}, "surrender", logic_params)
end
