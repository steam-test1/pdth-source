BaseNetworkHandler = BaseNetworkHandler or class()
BaseNetworkHandler._gamestate_filter = {
	any_ingame = {
		ingame_standard = true,
		ingame_mask_off = true,
		ingame_clean = true,
		ingame_bleed_out = true,
		ingame_fatal = true,
		ingame_arrested = true,
		ingame_electrified = true,
		ingame_incapacitated = true,
		ingame_waiting_for_players = true,
		ingame_waiting_for_respawn = true
	},
	any_ingame_playing = {
		ingame_standard = true,
		ingame_mask_off = true,
		ingame_clean = true,
		ingame_bleed_out = true,
		ingame_fatal = true,
		ingame_arrested = true,
		ingame_electrified = true,
		ingame_incapacitated = true,
		ingame_waiting_for_respawn = true
	},
	downed = {
		ingame_bleed_out = true,
		ingame_fatal = true,
		ingame_incapacitated = true
	},
	need_revive = {
		ingame_bleed_out = true,
		ingame_fatal = true,
		ingame_arrested = true,
		ingame_incapacitated = true
	},
	arrested = {ingame_arrested = true},
	game_over = {gameoverscreen = true},
	any_end_game = {gameoverscreen = true, victoryscreen = true},
	waiting_for_players = {ingame_waiting_for_players = true},
	waiting_for_respawn = {ingame_waiting_for_respawn = true},
	menu = {menu_main = true},
	player_slot = {
		menu_main = true,
		ingame_waiting_for_players = true,
		ingame_lobby_menu = true
	},
	lobby = {menu_main = true, ingame_lobby_menu = true}
}
function BaseNetworkHandler._verify_in_session()
	local session = managers.network:session()
	if not session or session:closing() then
		print("[BaseNetworkHandler._verify_in_session] Discarding message")
		Application:stack_dump()
		return
	end
	return session
end
function BaseNetworkHandler._verify_in_server_session()
	local session = managers.network:session()
	if not (session and session:is_host()) or session:closing() then
		print("[BaseNetworkHandler._verify_in_server_session] Discarding message")
		Application:stack_dump()
		return
	end
	return session
end
function BaseNetworkHandler._verify_in_client_session()
	local session = managers.network:session()
	if not (session and session:is_client()) or session:closing() then
		print("[BaseNetworkHandler._verify_in_client_session] Discarding message")
		Application:stack_dump()
		return
	end
	return session
end
function BaseNetworkHandler._verify_sender(rpc)
	local session = managers.network:session()
	local peer
	if session then
		if rpc:protocol_at_index(0) == "STEAM" then
			peer = session:peer_by_user_id(rpc:ip_at_index(0))
		else
			peer = session:peer_by_ip(rpc:ip_at_index(0))
		end
		if peer then
			return peer
		end
	end
	print("[BaseNetworkHandler._verify_sender] Discarding message", session, peer and peer:id())
	Application:stack_dump()
end
function BaseNetworkHandler._verify_character_and_sender(unit, rpc)
	return BaseNetworkHandler._verify_sender(rpc) and BaseNetworkHandler._verify_character(unit)
end
function BaseNetworkHandler._verify_character(unit)
	return alive(unit) and not unit:character_damage():dead()
end
function BaseNetworkHandler._verify_gamestate(acceptable_gamestates)
	local correct_state = acceptable_gamestates[game_state_machine:last_queued_state_name()]
	if correct_state then
		return true
	end
	print("[BaseNetworkHandler._verify_gamestate] Discarding message. current state:", game_state_machine:last_queued_state_name(), "acceptable:", inspect(acceptable_gamestates))
	Application:stack_dump()
end
function BaseNetworkHandler:_chk_flush_unit_too_early_packets(unit)
	if self._flushing_unit_too_early_packets then
		return
	end
	if not alive(unit) then
		return
	end
	local unit_id = unit:id()
	if unit_id == -1 then
		return
	end
	if not self._unit_too_early_queue then
		return
	end
	local unit_rpcs = self._unit_too_early_queue[unit_id]
	if not unit_rpcs then
		return
	end
	print("[BaseNetworkHandler:_chk_flush_unit_too_early_packets]", unit_id)
	self._flushing_unit_too_early_packets = true
	for _, rpc_info in ipairs(unit_rpcs) do
		print(" calling", rpc_info.fun_name)
		rpc_info.params[rpc_info.unit_param_index] = unit
		self[rpc_info.fun_name](self, unpack(rpc_info.params))
	end
	self._unit_too_early_queue[unit_id] = nil
	if not next(self._unit_too_early_queue) then
		self._unit_too_early_queue = nil
	end
	self._flushing_unit_too_early_packets = nil
end
function BaseNetworkHandler:_chk_unit_too_early(unit, unit_id_str, fun_name, unit_param_index, ...)
	if self._flushing_unit_too_early_packets then
		return
	end
	if alive(unit) then
		return
	end
	if not self._unit_too_early_queue then
		self._unit_too_early_queue = {}
	end
	local data = {
		unit_param_index = unit_param_index,
		fun_name = fun_name,
		params = {
			...
		}
	}
	local unit_id = tonumber(unit_id_str)
	self._unit_too_early_queue[unit_id] = self._unit_too_early_queue[unit_id] or {}
	table.insert(self._unit_too_early_queue[unit_id], data)
	print("[BaseNetworkHandler:_chk_unit_too_early]", unit_id_str, fun_name)
	return true
end
