TeamAILogicInactive = class(TeamAILogicBase)
function TeamAILogicInactive.enter(data, new_logic_name, enter_params)
	TeamAILogicBase.enter(data, new_logic_name, enter_params)
	local my_data = data.internal_data
	if my_data then
		local rsrv_pos = my_data.rsrv_pos
		if rsrv_pos.path then
			managers.navigation:unreserve_pos(rsrv_pos.path)
			rsrv_pos.path = nil
		end
		if rsrv_pos.move_dest then
			managers.navigation:unreserve_pos(rsrv_pos.move_dest)
			rsrv_pos.move_dest = nil
		end
		if rsrv_pos.stand then
			managers.navigation:unreserve_pos(rsrv_pos.stand)
			rsrv_pos.stand = nil
		end
		if my_data.focus_enemy then
			my_data.focus_enemy = nil
		end
		if my_data.detected_enemies then
			for key, enemy_data in pairs(my_data.detected_enemies) do
				enemy_data.unit:base():remove_destroy_listener(enemy_data.destroy_clbk_key)
			end
		end
	end
	data.internal_data = nil
	data.unit:brain():set_update_enabled_state(false)
	if data.objective then
		managers.groupai:state():on_criminal_objective_failed(data.unit, data.objective, true)
		data.unit:brain():set_objective(nil)
	end
end
function TeamAILogicInactive.is_available_for_assignment(data)
	return false
end
