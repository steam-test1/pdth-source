CopLogicTrade = class(CopLogicBase)
CopLogicTrade.butchers_traded = 0
function CopLogicTrade.enter(data, new_logic_name, enter_params)
	CopLogicBase.enter(data, new_logic_name, enter_params)
	data.unit:brain():cancel_all_pathing_searches()
	local old_internal_data = data.internal_data
	local my_data = {
		unit = data.unit
	}
	my_data.rsrv_pos = {}
	if old_internal_data then
		if old_internal_data.focus_enemy then
			managers.groupai:state():on_enemy_disengaging(data.unit, old_internal_data.focus_enemy.unit:key())
		end
		my_data.rsrv_pos = old_internal_data.rsrv_pos or my_data.rsrv_pos
	end
	data.internal_data = my_data
	data.unit:movement():set_allow_fire(false)
	CopLogicBase._reset_attention(data)
	my_data._trade_enabled = true
	data.unit:network():send("hostage_trade", true)
	CopLogicTrade.hostage_trade(data.unit, true)
	data.unit:brain():set_update_enabled_state(true)
	managers.groupai:state():on_hostage_state(true, data.key)
	managers.secret_assignment:unregister_unit(data.unit, true)
	my_data._destroy_clbk_key = "trade_destroy_clbk"
	data.unit:base():add_destroy_listener(my_data._destroy_clbk_key, callback(CopLogicTrade, CopLogicTrade, "on_enemy_destroyed", data))
end
function CopLogicTrade:on_enemy_destroyed(data)
	local my_data = data.internal_data
	my_data._destroy_clbk_key = "nil"
	managers.trade:change_hostage()
end
local is_win32 = SystemInfo:platform() == Idstring("WIN32")
function CopLogicTrade.hostage_trade(unit, enable)
	local wp_id = "wp_hostage_trade"
	print("RC: hostage_trade", enable)
	if enable then
		local text = managers.localization:text("debug_trade_hostage")
		managers.hud:add_waypoint(wp_id, {
			text = text,
			icon = "wp_trade",
			position = unit:movement():m_pos(),
			distance = is_win32
		})
		managers.hint:show_hint("trade_offered")
		unit:base():set_allow_invisible(false)
		unit:character_damage():set_invulnerable(true)
		unit:base():swap_material_config()
		unit:interaction():set_tweak_data("hostage_trade")
		unit:interaction():set_active(true, false)
	else
		managers.hud:remove_waypoint(wp_id)
		unit:base():swap_material_config()
		unit:interaction():set_tweak_data("intimidate")
		unit:interaction():set_active(false, false)
		unit:base():set_allow_invisible(true)
	end
end
function CopLogicTrade.exit(data, new_logic_name, enter_params)
	CopLogicBase.exit(data, new_logic_name, enter_params)
	local my_data = data.internal_data
	if my_data._destroy_clbk_key then
		data.unit:base():remove_destroy_listener(my_data._destroy_clbk_key)
		my_data._destroy_clbk_key = nil
	end
	if my_data._trade_enabled then
		my_data._trade_enabled = false
		data.unit:network():send("hostage_trade", false)
		CopLogicTrade.hostage_trade(data.unit, false)
		managers.groupai:state():on_hostage_state(false, data.key)
	end
	data.unit:character_damage():set_invulnerable(false)
	data.unit:network():send("set_unit_invulnerable", false)
end
function CopLogicTrade.on_trade(data, trading_unit)
	if not data.internal_data._trade_enabled then
		return
	end
	managers.trade:on_hostage_traded(trading_unit)
	local my_data = data.internal_data
	if my_data._destroy_clbk_key then
		data.unit:base():remove_destroy_listener(my_data._destroy_clbk_key)
		my_data._destroy_clbk_key = nil
	end
	if data.unit:base().butcher then
		CopLogicTrade.butchers_traded = CopLogicTrade.butchers_traded + 1
		if CopLogicTrade.butchers_traded >= 3 then
			managers.challenges:set_flag("blood_in_blood_out")
			managers.network:session():send_to_peers_synched("award_achievment", "blood_in_blood_out")
		end
	end
	data.internal_data._trade_enabled = false
	data.unit:network():send("hostage_trade", false)
	CopLogicTrade.hostage_trade(data.unit, false)
	managers.groupai:state():on_hostage_state(false, data.key)
	local flee_pos = managers.groupai:state():flee_point(data.unit)
	if flee_pos then
		data.internal_data.flee_pos = flee_pos
		if data.unit:anim_data().hands_tied or data.unit:anim_data().tied then
			local new_action = {
				type = "act",
				variant = "stand",
				body_part = 1
			}
			data.unit:brain():action_request(new_action)
		end
	else
		data.unit:set_slot(0)
	end
end
function CopLogicTrade.update(data)
	local my_data = data.internal_data
	CopLogicTrade._process_pathing_results(data, my_data)
	if my_data.pathing_to_flee_pos then
	elseif my_data.flee_path then
		if not data.unit:movement():chk_action_forbidden("walk") and data.unit:anim_data().idle_full_blend then
			data.unit:brain()._current_logic._chk_request_action_walk_to_flee_pos(data, my_data)
		end
	elseif my_data.flee_pos then
		local to_pos = my_data.flee_pos
		my_data.flee_pos = nil
		my_data.pathing_to_flee_pos = true
		my_data.flee_path_search_id = tostring(data.unit:key()) .. "flee"
		data.unit:brain():search_for_path(my_data.flee_path_search_id, to_pos)
	end
end
function CopLogicTrade._process_pathing_results(data, my_data)
	if data.pathing_results then
		local pathing_results = data.pathing_results
		data.pathing_results = nil
		local path = pathing_results[my_data.flee_path_search_id]
		if path then
			if path ~= "failed" then
				my_data.flee_path = path
			else
				data.unit:set_slot(0)
			end
			my_data.pathing_to_flee_pos = nil
			my_data.flee_path_search_id = nil
		end
	end
end
function CopLogicTrade._chk_request_action_walk_to_flee_pos(data, my_data, end_rot)
	local new_action_data = {}
	new_action_data.type = "walk"
	new_action_data.nav_path = my_data.flee_path
	new_action_data.variant = "run"
	new_action_data.body_part = 2
	my_data.flee_path = nil
	my_data.walking_to_flee_pos = data.unit:brain():action_request(new_action_data)
end
function CopLogicTrade.action_complete_clbk(data, action)
	local my_data = data.internal_data
	local action_type = action:type()
	if action_type == "walk" and my_data.walking_to_flee_pos then
		my_data.walking_to_flee_pos = nil
		data.unit:set_slot(0)
	end
end
function CopLogicTrade.can_activate()
	return false
end
function CopLogicTrade.is_available_for_assignment(data)
	return false
end
function CopLogicTrade._get_all_paths(data)
	return {
		flee_path = data.internal_data.flee_path
	}
end
function CopLogicTrade._set_verified_paths(data, verified_paths)
	data.internal_data.flee_path = verified_paths.flee_path
end
