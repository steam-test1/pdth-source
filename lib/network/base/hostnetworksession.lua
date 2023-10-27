require("lib/network/base/session_states/HostStateBase")
require("lib/network/base/session_states/HostStateInLobby")
require("lib/network/base/session_states/HostStateInGame")
require("lib/network/base/session_states/HostStateLoadout")
require("lib/network/base/session_states/HostStateGameEnd")
require("lib/network/base/session_states/HostStateClosing")
HostNetworkSession = HostNetworkSession or class(BaseNetworkSession)
HostNetworkSession._STATES = {
	in_lobby = HostStateInLobby,
	loadout = HostStateLoadout,
	in_game = HostStateInGame,
	game_end = HostStateGameEnd,
	closing = HostStateClosing
}
HostNetworkSession._DEAD_CONNECTION_REPORT_PROCESS_DELAY = BaseNetworkSession.CONNECTION_TIMEOUT + BaseNetworkSession.TIMEOUT_CHK_INTERVAL + 1
function HostNetworkSession:init()
	HostNetworkSession.super.init(self)
	print("[HostNetworkSession:init]")
	Network:set_multiplayer(true)
	Network:set_server()
	self._state_data = {
		session = self,
		peers = self._peers,
		kicked_list = self._kicked_list,
		local_peer = self._local_peer
	}
	self:set_state("in_lobby")
end
function HostNetworkSession:on_join_request_received(peer_name, client_mask_set, dlcs, client_ip, client_user_id, sender)
	return self._state.on_join_request_received and self._state:on_join_request_received(self._state_data, peer_name, client_mask_set, dlcs, client_ip, client_user_id, sender)
end
function HostNetworkSession:send_to_host(...)
	debug_pause("[HostNetworkSession:send_to_host] This is dumb. call the function directly instead of sending it...")
end
function HostNetworkSession:is_host()
	return true
end
function HostNetworkSession:is_client()
	return false
end
function HostNetworkSession:load_level(...)
	self._state:on_load_level(self._state_data)
	managers.network.matchmake:set_server_state("loading")
	for _, peer in pairs(self._peers) do
		peer:set_synched(false)
		peer:set_loaded(false)
	end
	self:set_state("closing")
	self:send_to_peers("set_loading_state", true)
	self:send_ok_to_load_level()
	self:_load_level(...)
end
function HostNetworkSession:broadcast_server_up()
	print("[HostNetworkSession:broadcast_server_up]")
	Network:broadcast(NetworkManager.DEFAULT_PORT):server_up()
end
function HostNetworkSession:on_server_up_received()
end
function HostNetworkSession:load(data)
	self:set_state("loadout")
	HostNetworkSession.super.load(self, data)
	self._state_data = {
		session = self,
		peers = self._peers,
		kicked_list = self._kicked_list,
		local_peer = self._local_peer
	}
end
function HostNetworkSession:on_peer_connection_established(sender_peer, introduced_peer_id)
	print("[HostNetworkSession:on_peer_connection_established]", sender_peer:id(), introduced_peer_id)
	if introduced_peer_id == 1 then
		if self._state.on_connection_to_peer_established then
			self._state:on_connection_to_peer_established(self._state_data, sender_peer)
		else
			print("con to peer established not existent in state:", self._state_name)
			return
		end
	end
	if not self._peers[introduced_peer_id] then
		print("introduced peer does not exist. ignoring.")
		return
	end
	if sender_peer:handshakes()[introduced_peer_id] ~= "asked" then
		print("peer was not asked. ignoring.")
		return
	end
	sender_peer:set_handshake_status(introduced_peer_id, true)
	if self._state.on_handshake_confirmation then
		self._state:on_handshake_confirmation(self._state_data, sender_peer, introduced_peer_id)
	end
	self:chk_initiate_dropin_pause(sender_peer)
	if self._peers[introduced_peer_id] then
		self:chk_initiate_dropin_pause(self._peers[introduced_peer_id])
	end
end
function HostNetworkSession:set_game_started(state)
	self._game_started = state
	self._state_data.game_started = state
	if state then
		self:set_state("in_game")
	end
end
function HostNetworkSession:chk_peer_already_in(rpc, user_id)
	local old_peer
	if SystemInfo:platform() == self._ids_WIN32 then
		old_peer = self:peer_by_user_id(user_id or rpc:ip_at_index(0))
	else
		old_peer = self:peer_by_ip(rpc:ip_at_index(0))
	end
	return old_peer
end
function HostNetworkSession:send_ok_to_load_level()
	for peer_id, peer in pairs(self._peers) do
		if not peer:loaded() and not peer:loading() then
			print("[HostNetworkSession:send_ok_to_load_level]", inspect(peer))
			peer:send("ok_to_load_level")
			peer:on_ok_load_level_sent()
		end
	end
end
function HostNetworkSession:on_peer_save_received(event, event_data)
	if managers.network:stopping() then
		return
	end
	local peer = self:peer_by_ip(event_data.ip_address)
	if not peer then
		Application:error("[HostNetworkSession:on_peer_save_received] A nonregistered peer confirmed save packet.")
		return
	end
	if event_data.index then
		local packet_index = event_data.index
		local total_nr_packets = event_data.total
		local progress_ratio = packet_index / total_nr_packets
		local progress_percentage = math.floor(math.clamp(progress_ratio * 100, 0, 100))
		local is_playing = BaseNetworkHandler._gamestate_filter.any_ingame_playing[game_state_machine:last_queued_state_name()]
		if is_playing then
			managers.menu:update_person_joining(peer:id(), progress_percentage)
		elseif BaseNetworkHandler._gamestate_filter.any_ingame[game_state_machine:last_queued_state_name()] then
			managers.menu:get_menu("kit_menu").renderer:set_dropin_progress(peer:id(), progress_percentage)
		end
		self:send_to_peers_synched_except(peer:id(), "dropin_progress", peer:id(), progress_percentage)
	else
		cat_print("multiplayer_base", "[HostNetworkSession:on_peer_save_received]", peer, peer:id())
		peer:set_synched(true)
		peer:send("set_peer_synched", 1)
		for _, old_peer in pairs(self._peers) do
			if old_peer ~= peer then
				old_peer:send_after_load("set_peer_synched", peer:id())
			end
		end
		if NetworkManager.DROPIN_ENABLED then
			for other_peer_id, other_peer in pairs(self._peers) do
				if other_peer_id ~= peer:id() and other_peer:expecting_dropin() then
					self:set_dropin_pause_request(peer, other_peer_id, "asked")
				end
			end
			for old_peer_id, old_peer in pairs(self._peers) do
				if old_peer_id ~= peer:id() and old_peer:is_expecting_pause_confirmation(peer:id()) then
					self:set_dropin_pause_request(old_peer, peer:id(), false)
				end
			end
			if self._local_peer:is_expecting_pause_confirmation(peer:id()) then
				self._local_peer:set_expecting_drop_in_pause_confirmation(peer:id(), nil)
				managers.network:game():on_drop_in_pause_request_received(peer:id(), peer:name(), false)
			end
		end
		self:chk_send_local_player_ready()
		for other_peer_id, other_peer in pairs(self._peers) do
			self:chk_spawn_member_unit(other_peer, other_peer_id)
		end
		managers.network:game():on_peer_sync_complete(peer, peer:id())
	end
end
function HostNetworkSession:update()
	if Application:editor() then
		return
	end
	HostNetworkSession.super.update(self)
	self:process_dead_con_reports()
end
function HostNetworkSession:set_peer_loading_state(peer, state)
	print("[HostNetworkSession:set_peer_loading_state]", peer:id(), state)
	HostNetworkSession.super.set_peer_loading_state(self, peer, state)
	if not state and self._local_peer:loaded() and NetworkManager.DROPIN_ENABLED then
		if self._state.on_peer_finished_loading then
			self._state:on_peer_finished_loading(self._state_data, peer)
		end
		peer:set_expecting_pause_sequence(true)
		local dropin_pause_ok = self:chk_initiate_dropin_pause(peer)
		if dropin_pause_ok then
			self:chk_drop_in_peer(peer)
		else
			print(" setting set_expecting_pause_sequence", peer:id())
		end
	end
end
function HostNetworkSession:on_drop_in_pause_confirmation_received(dropin_peer_id, sender_peer)
	print("[HostNetworkSession:on_drop_in_pause_confirmation_received]", sender_peer:id(), " paused for ", dropin_peer_id)
	local is_expecting = sender_peer:is_expecting_pause_confirmation(dropin_peer_id)
	local dropin_peer = self._peers[dropin_peer_id]
	if dropin_peer and dropin_peer:expecting_dropin() then
		if is_expecting == "asked" then
			self:set_dropin_pause_request(sender_peer, dropin_peer_id, "paused")
		else
			print("peer", sender_peer:id(), "was not asked for confirmation. is_expecting:", is_expecting)
		end
		self:chk_drop_in_peer(dropin_peer)
	else
		self:set_dropin_pause_request(sender_peer, dropin_peer_id, false)
		if dropin_peer then
			self:chk_initiate_dropin_pause(dropin_peer)
		end
	end
end
function HostNetworkSession:chk_initiate_dropin_pause(dropin_peer)
	print("[HostNetworkSession:chk_initiate_dropin_pause]", dropin_peer:id())
	if not dropin_peer:expecting_pause_sequence() then
		print("not expecting")
		return
	end
	if not self:chk_peer_handshakes_complete(dropin_peer) then
		print("misses handshakes")
		return
	end
	for peer_id, peer in pairs(self._peers) do
		local is_expecting = peer:is_expecting_pause_confirmation(dropin_peer:id())
		if is_expecting then
			print(" peer", peer_id, "is still to confirm", is_expecting)
			return
		end
	end
	for other_peer_id, other_peer in pairs(self._peers) do
		if other_peer_id ~= dropin_peer:id() and not other_peer:is_expecting_pause_confirmation(dropin_peer:id()) then
			self:set_dropin_pause_request(other_peer, dropin_peer:id(), "asked")
		end
	end
	if not self._local_peer:is_expecting_pause_confirmation(dropin_peer:id()) then
		self._local_peer:set_expecting_drop_in_pause_confirmation(dropin_peer:id(), "paused")
		managers.network:game():on_drop_in_pause_request_received(dropin_peer:id(), dropin_peer:name(), true)
	end
	dropin_peer:set_expecting_pause_sequence(nil)
	dropin_peer:set_expecting_dropin(true)
	return true
end
function HostNetworkSession:chk_drop_in_peer(dropin_peer)
	if not dropin_peer:expecting_dropin() then
		return
	end
	local dropin_peer_id = dropin_peer:id()
	print("[HostNetworkSession:chk_drop_in_peer]", dropin_peer_id)
	for peer_id, peer in pairs(self._peers) do
		if dropin_peer_id ~= peer_id and peer:synched() then
			local is_expecting = peer:is_expecting_pause_confirmation(dropin_peer_id)
			if is_expecting ~= "paused" then
				print("peer", peer_id, "is expected to confirm", is_expecting)
				if not is_expecting then
					debug_pause("was not asked!")
				end
				return
			end
		end
	end
	print("doing drop-in!")
	Application:stack_dump()
	dropin_peer:set_expecting_dropin(nil)
	dropin_peer:on_sync_start()
	dropin_peer:chk_enable_queue()
	Network:drop_in(dropin_peer:rpc())
	return true
end
function HostNetworkSession:add_peer(name, rpc, in_lobby, loading, synched, id, mask_set, user_id)
	id = id or self:_get_free_client_id()
	if not id then
		return
	end
	name = name or "Player " .. tostring(id)
	local peer
	id, peer = HostNetworkSession.super.add_peer(self, name, rpc, in_lobby, loading, synched, id, mask_set, user_id)
	self:chk_server_joinable_state()
	return id, peer
end
function HostNetworkSession:_get_free_client_id()
	local i = 2
	repeat
		if not self._peers[i] then
			local is_dirty = false
			for peer_id, peer in pairs(self._peers) do
				if peer:handshakes()[i] then
					is_dirty = true
				end
			end
			if not is_dirty then
				return i
			end
		end
		i = i + 1
	until i == 5
end
function HostNetworkSession:remove_peer(peer, peer_id, reason)
	print("[HostNetworkSession:remove_peer]", inspect(peer), peer_id, reason)
	HostNetworkSession.super.remove_peer(self, peer, peer_id, reason)
	if self._dead_con_reports then
		local i = #self._dead_con_reports
		while 0 < i do
			local dead_con_report = self._dead_con_reports[i]
			if dead_con_report.reporter == peer or dead_con_report.reported == peer then
				table.remove(self._dead_con_reports, i)
			end
			i = i - 1
		end
		if not next(self._dead_con_reports) then
			self._dead_con_reports = nil
		end
	end
	if NetworkManager.DROPIN_ENABLED then
		for other_peer_id, other_peer in pairs(self._peers) do
			if other_peer:is_expecting_pause_confirmation(peer_id) then
				self:set_dropin_pause_request(other_peer, peer_id, false)
			end
		end
		if self._local_peer:is_expecting_pause_confirmation(peer_id) then
			self._local_peer:set_expecting_drop_in_pause_confirmation(peer_id, nil)
			managers.network:game():on_drop_in_pause_request_received(peer_id, "", false)
		end
		for other_peer_id, other_peer in pairs(self._peers) do
			self:chk_drop_in_peer(other_peer)
			self:chk_initiate_dropin_pause(other_peer)
			self:chk_spawn_member_unit(other_peer, other_peer_id)
		end
	end
	local info_msg_type
	if reason == "kicked" then
		info_msg_type = "kick_peer"
	else
		info_msg_type = "remove_dead_peer"
	end
	for other_peer_id, other_peer in pairs(self._peers) do
		if other_peer:handshakes()[peer_id] == true or other_peer:handshakes()[peer_id] == "asked" then
			other_peer:send_after_load(info_msg_type, peer_id)
			other_peer:set_handshake_status(peer_id, "removing")
		end
	end
	if reason ~= "left" and reason ~= "kicked" and peer:ip_verified() then
		peer:send(info_msg_type, peer_id)
	end
	self:chk_server_joinable_state()
end
function HostNetworkSession:on_remove_peer_confirmation(sender_peer, removed_peer_id)
	print("[HostNetworkSession:on_remove_peer_confirmation]", sender_peer:id(), removed_peer_id)
	if sender_peer:handshakes()[removed_peer_id] ~= "removing" then
		print("peer should not remove. ignoring.")
		return
	end
	sender_peer:set_handshake_status(removed_peer_id, nil)
	self:chk_server_joinable_state()
	managers.network:game():check_start_game_intro()
end
function HostNetworkSession:on_dead_connection_reported(reporter_peer_id, other_peer_id)
	print("[HostNetworkSession:on_dead_connection_reported]", reporter_peer_id, other_peer_id)
	if not self._peers[reporter_peer_id] or not self._peers[other_peer_id] then
		return
	end
	self._dead_con_reports = self._dead_con_reports or {}
	local entry = {
		process_t = TimerManager:wall():time() + self._DEAD_CONNECTION_REPORT_PROCESS_DELAY,
		reporter = self._peers[reporter_peer_id],
		reported = self._peers[other_peer_id]
	}
	table.insert(self._dead_con_reports, entry)
end
function HostNetworkSession:process_dead_con_reports()
	if self._dead_con_reports then
		local t = TimerManager:wall():time()
		local first_dead_con_report = self._dead_con_reports[1]
		if t > first_dead_con_report.process_t then
			if #self._dead_con_reports == 1 then
				self._dead_con_reports = nil
			else
				table.remove(self._dead_con_reports, 1)
			end
			local kick_peer
			local reporter_peer = first_dead_con_report.reporter
			local reported_peer = first_dead_con_report.reported
			if reporter_peer:creation_t() > reported_peer:creation_t() then
				print("[HostNetworkSession:process_dead_con_reports] kicking reporter ", reporter_peer:id(), reported_peer:id(), reporter_peer:creation_t(), reported_peer:creation_t())
				kick_peer = reporter_peer
			else
				print("[HostNetworkSession:process_dead_con_reports] kicking reported ", reporter_peer:id(), reported_peer:id(), reporter_peer:creation_t(), reported_peer:creation_t())
				kick_peer = reported_peer
			end
			self:on_remove_dead_peer(kick_peer, kick_peer:id())
		end
	end
end
function HostNetworkSession:chk_spawn_member_unit(peer, peer_id)
	print("[HostNetworkSession:chk_spawn_member_unit]", peer:name(), peer_id)
	local member = managers.network:game():member(peer_id)
	if not self._game_started then
		print("Game not started yet")
		return
	end
	if not member or member:spawn_unit_called() or not peer:waiting_for_player_ready() then
		print("not ready to spawn unit: member", member, "member:spawn_unit_called()", member:spawn_unit_called(), "peer:waiting_for_player_ready()", peer:waiting_for_player_ready())
		return
	end
	for other_peer_id, other_peer in pairs(self._peers) do
		if not other_peer:synched() then
			print("peer", other_peer_id, "is not synched")
			return
		end
	end
	if not self:chk_all_handshakes_complete() then
		return
	end
	managers.network:game():spawn_dropin_player(peer_id)
end
function HostNetworkSession:chk_server_joinable_state()
	for peer_id, peer in pairs(self._peers) do
		if peer:force_open_lobby_state() then
			print("force-opening lobby for peer", peer_id)
			managers.network.matchmake:set_server_joinable(true)
			return
		end
	end
	if table.size(self._peers) >= 3 then
		managers.network.matchmake:set_server_joinable(false)
		return
	end
	local game_state_name = game_state_machine:last_queued_state_name()
	if BaseNetworkHandler._gamestate_filter.any_end_game[game_state_name] then
		managers.network.matchmake:set_server_joinable(false)
		return
	end
	if not self:_get_free_client_id() then
		managers.network.matchmake:set_server_joinable(false)
		return
	end
	if not self._state:is_joinable(self._state_data) then
		managers.network.matchmake:set_server_joinable(false)
		return
	end
	if NetworkManager.DROPIN_ENABLED then
		if BaseNetworkHandler._gamestate_filter.lobby[game_state_name] then
			managers.network.matchmake:set_server_joinable(true)
			return
		elseif managers.groupai and not managers.groupai:state():chk_allow_drop_in() then
			managers.network.matchmake:set_server_joinable(false)
			return
		end
	elseif not BaseNetworkHandler._gamestate_filter.lobby[game_state_name] then
		managers.network.matchmake:set_server_joinable(false)
		return
	end
	managers.network.matchmake:set_server_joinable(true)
end
function HostNetworkSession:on_load_complete()
	HostNetworkSession.super.on_load_complete(self)
	self:set_state("loadout")
	managers.network.matchmake:set_server_state("in_game")
	if NetworkManager.DROPIN_ENABLED then
		for peer_id, peer in pairs(self._peers) do
			if peer:loaded() then
				if not managers.network:game():_has_client(peer) then
					Network:add_client(peer:rpc())
				end
				if not peer:synched() then
					peer:set_expecting_pause_sequence(true)
					local dropin_pause_ok = self:chk_initiate_dropin_pause(peer)
					if dropin_pause_ok then
						self:chk_drop_in_peer(peer)
					end
				end
			end
		end
	end
end
function HostNetworkSession:prepare_to_close()
	HostNetworkSession.super.prepare_to_close(self)
	self:set_state("closing")
end
function HostNetworkSession:chk_peer_handshakes_complete(peer)
	local peer_id = peer:id()
	local peer_handshakes = peer:handshakes()
	for other_peer_id, other_peer in pairs(self._peers) do
		if other_peer_id ~= peer_id and other_peer:loaded() then
			if peer_handshakes[other_peer_id] ~= true then
				print("[HostNetworkSession:chk_peer_handshakes_complete]", peer_id, "is missing handshake for", other_peer_id)
				return false
			end
			if other_peer:handshakes()[peer_id] ~= true then
				print("[HostNetworkSession:chk_peer_handshakes_complete]", peer_id, "is not known by", other_peer_id)
				return false
			end
		end
	end
	return true
end
function HostNetworkSession:chk_all_handshakes_complete()
	for peer_id, peer in pairs(self._peers) do
		local peer_handshakes = peer:handshakes()
		for other_peer_id, other_peer in pairs(self._peers) do
			if other_peer_id ~= peer_id and peer_handshakes[other_peer_id] ~= true then
				print("[HostNetworkSession:chk_all_handshakes_complete]", peer_id, "is missing handshake for", other_peer_id)
				return false
			end
		end
	end
	return true
end
function HostNetworkSession:set_dropin_pause_request(peer, dropin_peer_id, state)
	if state == "asked" then
		local dropin_peer = self._peers[dropin_peer_id]
		peer:set_expecting_drop_in_pause_confirmation(dropin_peer_id, state)
		peer:send_after_load("request_drop_in_pause", dropin_peer_id, dropin_peer:name() or "unknown_peer", true)
	elseif state == "paused" then
		peer:set_expecting_drop_in_pause_confirmation(dropin_peer_id, state)
	elseif not state then
		peer:set_expecting_drop_in_pause_confirmation(dropin_peer_id, nil)
		peer:send_after_load("request_drop_in_pause", dropin_peer_id, "", false)
	else
		debug_pause("[HostNetworkSession:set_dropin_pause_request] unknown state", state)
	end
end
function HostNetworkSession:chk_send_ready_to_unpause()
	for peer_id, peer in pairs(self._peers) do
		if peer:loaded() and not peer:synched() then
			return
		end
	end
	for peer_id, peer in pairs(self._peers) do
		self:set_dropin_pause_request(peer, peer_id, false)
	end
	if self._local_peer:is_expecting_pause_confirmation(self._local_peer:id()) then
		self._local_peer:set_expecting_drop_in_pause_confirmation(self._local_peer:id(), nil)
		managers.network:game():on_drop_in_pause_request_received(self._local_peer:id(), "", false)
	end
	return true
end
function HostNetworkSession:set_state(name, enter_params)
	local state = self._STATES[name]
	local state_data = self._state_data
	if self._state then
		self._state:exit(state_data, name, enter_params)
	end
	state_data.name = name
	state_data.state = state
	self._state = state
	self._state_name = name
	state:enter(state_data, enter_params)
end
function HostNetworkSession:on_re_open_lobby_request(peer, state)
	if state then
		peer:send_after_load("re_open_lobby_reply", true)
	end
	peer:set_force_open_lobby_state(state)
	self:chk_server_joinable_state()
end
