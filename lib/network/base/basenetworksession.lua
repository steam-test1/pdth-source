BaseNetworkSession = BaseNetworkSession or class()
BaseNetworkSession._ids_WIN32 = Idstring("WIN32")
BaseNetworkSession.TIMEOUT_CHK_INTERVAL = 5
BaseNetworkSession.CONNECTION_TIMEOUT = 12
BaseNetworkSession._LOAD_WAIT_TIME = 3
BaseNetworkSession._STEAM_P2P_SEND_INTERVAL = 1
BaseNetworkSession._EXTERNAL_IP_REQUEST_INTERVAL = 1
BaseNetworkSession._NAT_KEEP_ALIVE_INTERVAL = 15
BaseNetworkSession._NAT_TIMEOUT = 30
BaseNetworkSession._KEEP_ALIVE_INTERVAL = 1
BaseNetworkSession.MATCHMAKING_SERVER_IP_ADDRESSES = {}
function BaseNetworkSession:init()
	print("[BaseNetworkSession:init]")
	self._matchmaking_server_rpcs = {}
	for i, ip_address in ipairs(self.MATCHMAKING_SERVER_IP_ADDRESSES) do
		local matchmaking_server_rpc = Network:handshake(ip_address, nil, "TCP_IP")
		Network:set_connection_persistent(matchmaking_server_rpc, true)
		Network:set_throttling_disabled(matchmaking_server_rpc, true)
		self._matchmaking_server_rpcs[ip_address] = matchmaking_server_rpc
	end
	local my_name = managers.network.account:username_id()
	local my_user_id = SystemInfo:platform() == self._ids_WIN32 and Steam:userid() or false
	self._local_peer = NetworkPeer:new(my_name, Network:self("TCP_IP"), 1, false, false, false, managers.user:get_setting("mask_set"), my_user_id)
	self._peers = {}
	self._server_peer = nil
	self._timeout_chk_t = 0
	self._alive_send_t = 0
	self._kicked_list = {}
	self._connection_established_results = {}
	self._soft_remove_peers = false
	Network:set_client_send_callback(callback(self, self, "clbk_network_send"))
	self._dropin_complete_event_manager_id = EventManager:register_listener(Idstring("net_save_received"), callback(self, self, "on_peer_save_received"))
	self._my_external_IP = Global.my_external_IP
	if not Application:editor() then
		self._next_NAT_keep_alive_t = 0
	end
	self._matchmaking_server = nil
	self._matchmaking_server_expire_t = 0
end
function BaseNetworkSession:load(data)
	for peer_id, peer_data in pairs(data.peers) do
		self._peers[peer_id] = NetworkPeer:new()
		self._peers[peer_id]:load(peer_data)
	end
	if data.server_peer then
		self._server_peer = self._peers[data.server_peer]
	end
	self._local_peer:load(data.local_peer)
	self.update = self.update_skip_one
	self._kicked_list = data.kicked_list
	self._connection_established_results = data.connection_established_results
	if data.dead_con_reports then
		self._dead_con_reports = {}
		for _, report in ipairs(data.dead_con_reports) do
			local report = {
				process_t = report.process_t,
				reporter = self._peers[report.reporter],
				reported = self._peers[report.reported]
			}
			table.insert(self._dead_con_reports, report)
		end
	end
	self._server_protocol = data.server_protocol
	self._matchmaking_server = data.matchmaking_server
	if self._matchmaking_server then
		self._next_NAT_keep_alive_t = 0
		self._matchmaking_server_expire_t = TimerManager:wall_running():time() + self._NAT_TIMEOUT
	end
end
function BaseNetworkSession:save(data)
	if self._server_peer then
		data.server_peer = self._server_peer:id()
	end
	local peers = {}
	data.peers = peers
	for peer_id, peer in pairs(self._peers) do
		local peer_data = {}
		peers[peer_id] = peer_data
		peer:save(peer_data)
	end
	data.local_peer = {}
	self._local_peer:save(data.local_peer)
	data.kicked_list = self._kicked_list
	data.connection_established_results = self._connection_established_results
	if self._dead_con_reports then
		data.dead_con_reports = {}
		for _, report in ipairs(self._dead_con_reports) do
			local save_report = {
				process_t = report.process_t,
				reporter = report.reporter:id(),
				reported = report.reported:id()
			}
			table.insert(data.dead_con_reports, save_report)
		end
	end
	if self._dropin_complete_event_manager_id then
		EventManager:unregister_listener(self._dropin_complete_event_manager_id)
		self._dropin_complete_event_manager_id = nil
	end
	data.server_protocol = self._server_protocol
	data.matchmaking_server = self._matchmaking_server
	self:_flush_soft_remove_peers()
end
function BaseNetworkSession:server_peer()
	return self._server_peer
end
function BaseNetworkSession:peer(peer_id)
	local peer = self._peers[peer_id]
	if peer then
		return peer
	elseif peer_id == self._local_peer:id() then
		return self._local_peer
	end
end
function BaseNetworkSession:peers()
	return self._peers
end
function BaseNetworkSession:peer_by_ip(ip)
	for peer_id, peer in pairs(self._peers) do
		if peer:ip() == ip then
			return peer
		end
	end
	if self._local_peer:ip() == ip then
		return self._local_peer
	end
end
function BaseNetworkSession:peer_by_name(name)
	for peer_id, peer in pairs(self._peers) do
		if peer:name() == name then
			return peer
		end
	end
end
function BaseNetworkSession:peer_by_user_id(user_id)
	if type(user_id) ~= "string" then
		print("peer_by_user_id converting to string", user_id, tostring(user_id))
		user_id = tostring(user_id)
	end
	for peer_id, peer in pairs(self._peers) do
		if peer:user_id() == user_id then
			return peer
		end
	end
	if self._local_peer:user_id() == user_id then
		return self._local_peer
	end
end
function BaseNetworkSession:local_peer()
	return self._local_peer
end
function BaseNetworkSession:is_kicked(peer_name)
	return self._kicked_list[peer_name]
end
function BaseNetworkSession:add_peer(name, rpc, in_lobby, loading, synched, id, mask_set, user_id)
	cat_print("multiplayer_base", " BaseNetworkSession:add_peer", name, rpc, in_lobby, loading, synched, id, mask_set, user_id)
	local peer = NetworkPeer:new(name, rpc, id, loading, synched, in_lobby, mask_set, user_id)
	if SystemInfo:platform() == Idstring("WIN32") then
		Steam:set_played_with(peer:user_id())
	end
	self._peers[id] = peer
	managers.network:game():on_peer_added(peer, id)
	if synched then
		managers.network:game():on_peer_sync_complete(peer, id)
	end
	if rpc then
		self:remove_connection_from_trash(rpc)
		self:remove_connection_from_soft_remove_peers(rpc)
	end
	return id, peer
end
function BaseNetworkSession:remove_peer(peer, peer_id, reason)
	print("[BaseNetworkSession:remove_peer]", inspect(peer), peer_id, reason)
	Application:stack_dump()
	if peer_id == 1 then
		self._server_peer = nil
	end
	self._peers[peer_id] = nil
	self._connection_established_results[peer:name()] = nil
	if peer:rpc() then
		self:_soft_remove_peer(peer)
	else
		peer:destroy()
	end
	managers.network:game():on_peer_removed(peer, peer_id, reason)
end
function BaseNetworkSession:_soft_remove_peer(peer)
	self._soft_remove_peers = self._soft_remove_peers or {}
	self._soft_remove_peers[peer:rpc():ip_at_index(0)] = {
		peer = peer,
		expire_t = TimerManager:wall_running():time() + 1.5
	}
end
function BaseNetworkSession:on_peer_left_lobby(peer)
	if peer:id() == 1 and self:is_client() and self._cb_find_game then
		self:on_join_request_timed_out()
	end
end
function BaseNetworkSession:on_peer_left(peer, peer_id)
	cat_print("multiplayer_base", "[BaseNetworkSession:on_peer_left] Peer Left", peer_id, peer:name(), peer:ip())
	Application:stack_dump()
	self:remove_peer(peer, peer_id, "left")
	if peer_id == 1 and self:is_client() then
		if self._cb_find_game then
			self:on_join_request_timed_out()
		else
			if self:_local_peer_in_lobby() then
				managers.network.matchmake:leave_game()
			else
				managers.network.matchmake:destroy_game()
			end
			managers.network.voice_chat:destroy_voice()
			if game_state_machine:current_state().on_server_left then
				game_state_machine:current_state():on_server_left()
			end
		end
	end
end
function BaseNetworkSession:on_peer_lost(peer, peer_id)
	cat_print("multiplayer_base", "[BaseNetworkSession:on_peer_lost] Peer Lost", peer_id, peer:name(), peer:ip())
	Application:stack_dump()
	self:remove_peer(peer, peer_id, "lost")
	if peer_id == 1 and self:is_client() then
		if self._cb_find_game then
			self:on_join_request_timed_out()
		else
			if self:_local_peer_in_lobby() then
				managers.network.matchmake:leave_game()
			else
				managers.network.matchmake:destroy_game()
			end
			managers.network.voice_chat:destroy_voice()
			if game_state_machine:current_state().on_server_left then
				Global.on_server_left_message = "dialog_connection_to_host_lost"
				game_state_machine:current_state():on_server_left()
			end
		end
	end
	if peer_id ~= 1 and self:is_client() and self._server_peer then
		self._server_peer:send_after_load("report_dead_connection", peer_id)
	end
	if self._matchmaking_server and peer:rpc() then
		self._matchmaking_server:match_stat_p2p_con_lost(peer:rpc():protocol_at_index(0) == "TCP_IP" and 1 or 2)
	end
end
function BaseNetworkSession:on_peer_kicked(peer, peer_id)
	if peer ~= self._local_peer then
		local ident = SystemInfo:platform() == Idstring("WIN32") and peer:user_id() or peer:name()
		self._kicked_list[ident] = true
		self:remove_peer(peer, peer_id, "kicked")
	else
		print("IVE BEEN KICKED!")
		if self:_local_peer_in_lobby() then
			print("KICKED FROM LOBBY")
			managers.menu:on_leave_lobby()
			managers.menu:show_peer_kicked_dialog()
		else
			print("KICKED FROM INGAME")
			managers.network.matchmake:destroy_game()
			managers.network.voice_chat:destroy_voice()
			if game_state_machine:current_state().on_kicked then
				game_state_machine:current_state():on_kicked()
			end
		end
	end
end
function BaseNetworkSession:on_remove_dead_peer(peer, peer_id)
	if peer ~= self._local_peer then
		self:remove_peer(peer, peer_id, "removed_dead")
	else
		print("IVE BEEN REMOVED DEAD!")
		Global.on_remove_dead_peer_message = "dialog_remove_dead_peer"
		if self:_local_peer_in_lobby() then
			print("REMOVED FROM LOBBY")
			managers.menu:on_leave_lobby()
			managers.menu:show_peer_kicked_dialog()
		else
			print("REMOVED FROM INGAME")
			managers.network.matchmake:destroy_game()
			managers.network.voice_chat:destroy_voice()
			if game_state_machine:current_state().on_kicked then
				game_state_machine:current_state():on_kicked()
			end
		end
	end
end
function BaseNetworkSession:_local_peer_in_lobby()
	return self._local_peer:in_lobby() and game_state_machine:current_state_name() ~= "ingame_lobby_menu"
end
function BaseNetworkSession:update_skip_one()
	self.update = nil
	local wall_time = TimerManager:wall_running():time()
	self._timeout_chk_t = wall_time + self.TIMEOUT_CHK_INTERVAL
	self._alive_send_t = 0
end
function BaseNetworkSession:update()
	local wall_run_t = TimerManager:wall_running():time()
	if wall_run_t > self._timeout_chk_t then
		for peer_id, peer in pairs(self._peers) do
			peer:chk_timeout(self.CONNECTION_TIMEOUT, wall_run_t)
		end
		self._timeout_chk_t = wall_run_t + self.TIMEOUT_CHK_INTERVAL
	end
	if self._closing and self:is_ready_to_close() then
		self._closing = false
		managers.network:queue_stop_network()
	end
	self:upd_trash_connections(wall_run_t)
	self:_update_matchmaking_server_connection(wall_run_t)
	self:_upd_send_peer_alive_checks(wall_run_t)
end
function BaseNetworkSession:end_update()
end
function BaseNetworkSession:send_to_peers(...)
	for peer_id, peer in pairs(self._peers) do
		peer:send(...)
	end
end
function BaseNetworkSession:send_to_peers_except(id, ...)
	for peer_id, peer in pairs(self._peers) do
		if peer_id ~= id then
			peer:send(...)
		end
	end
end
function BaseNetworkSession:send_to_peers_synched(...)
	for peer_id, peer in pairs(self._peers) do
		peer:send_queued_sync(...)
	end
end
function BaseNetworkSession:send_to_peers_synched_except(id, ...)
	for peer_id, peer in pairs(self._peers) do
		if peer_id ~= id then
			peer:send_queued_sync(...)
		end
	end
end
function BaseNetworkSession:send_to_peers_loaded(...)
	for peer_id, peer in pairs(self._peers) do
		peer:send_after_load(...)
	end
end
function BaseNetworkSession:send_to_peers_loaded_except(id, ...)
	for peer_id, peer in pairs(self._peers) do
		if peer_id ~= id then
			peer:send_after_load(...)
		end
	end
end
function BaseNetworkSession:send_to_peer(peer, ...)
	peer:send(...)
end
function BaseNetworkSession:send_to_peer_synched(peer, ...)
	peer:send_queued_sync(...)
end
function BaseNetworkSession:_load_level(...)
	self._local_peer:set_loading(true)
	Network:set_multiplayer(true)
	setup:load_level(...)
	self._load_wait_timeout_t = TimerManager:wall_running():time() + self._LOAD_WAIT_TIME
end
function BaseNetworkSession:debug_list_peers()
	for i, peer in pairs(self._peers) do
		cat_print("multiplayer_base", "Peer", i, peer:connection_info())
	end
end
function BaseNetworkSession:clbk_network_send(target_rpc, post_send)
	local target_ip = target_rpc:ip_at_index(0)
	if post_send then
		if self._soft_remove_peers and self._soft_remove_peers[target_ip] then
			local ok_to_delete = true
			local peer_remove_info = self._soft_remove_peers[target_ip]
			if not peer_remove_info.expire_t or peer_remove_info.expire_t > TimerManager:game():time() then
				local send_resume = Network:get_connection_send_status(target_rpc)
				if send_resume then
					for delivery_type, amount in pairs(send_resume) do
						if amount > 0 then
							ok_to_delete = false
						else
						end
					end
				end
			end
			if ok_to_delete then
				print("[BaseNetworkSession:clbk_network_send] soft-removed peer", peer_remove_info.peer:id(), target_ip)
				peer_remove_info.peer:destroy()
				self._soft_remove_peers[target_ip] = nil
				if not next(self._soft_remove_peers) then
					self._soft_remove_peers = false
				end
			end
		elseif self._matchmaking_server and self._matchmaking_server:ip_at_index(0) == target_ip then
		elseif not self._matchmaking_server and self._matchmaking_server_rpcs[target_ip] then
		else
			local peer = target_rpc:protocol_at_index(0) == "TCP_IP" and self:peer_by_ip(target_ip) or self:peer_by_user_id(target_ip)
			if not peer then
				self:add_connection_to_trash(target_rpc)
			end
		end
	else
		local peer = self:peer_by_ip(target_ip)
		if peer then
			peer:on_send()
		end
	end
end
function BaseNetworkSession:is_ready_to_close()
	if self._load_wait_timeout_t and TimerManager:wall_running():time() > self._load_wait_timeout_t then
		return true
	end
	for peer_id, peer in pairs(self._peers) do
		if peer:is_waiting_to_start_loading() then
			print("[BaseNetworkSession:is_ready_to_close] waiting load", peer_id)
			return false
		elseif peer:has_queued_rpcs() then
			print("[BaseNetworkSession:is_ready_to_close] waiting queued rpcs", peer_id, peer:has_queued_rpcs())
			return false
		end
		if peer:rpc() then
			local send_resume = Network:get_connection_send_status(peer:rpc())
			if send_resume then
				for delivery_type, amount in pairs(send_resume) do
					if delivery_type ~= "unreliable" and amount > 0 then
						print("[BaseNetworkSession:is_ready_to_close] waiting transmission", delivery_type, amount)
						return false
					end
				end
			end
		end
	end
	return true
end
function BaseNetworkSession:closing()
	return self._closing
end
function BaseNetworkSession:prepare_to_close()
	print("[BaseNetworkSession:prepare_to_close]")
	self._closing = true
	managers.network.matchmake:destroy_game()
	Network:set_disconnected()
	if self._matchmaking_server then
		self._matchmaking_server:from_client_close_connection()
	end
end
function BaseNetworkSession:set_peer_loading_state(peer, state)
	print("[BaseNetworkSession:set_peer_loading_state]", peer:id(), state)
	peer:set_loading(state)
	if not state and self._local_peer:loaded() then
		if peer:ip_verified() then
			Global.local_member:sync_lobby_data(peer)
			Global.local_member:sync_data(peer)
			peer:send_after_load("set_member_ready", self._local_peer:waiting_for_player_ready())
		end
		peer:flush_overwriteable_msgs()
	end
end
function BaseNetworkSession:upd_trash_connections(wall_t)
	if self._trash_connections then
		for ip, info in pairs(self._trash_connections) do
			if wall_t > info.expire_t then
				local reset = true
				for peer_id, peer in pairs(self._peers) do
					if peer:ip_verified() and peer:ip() == ip or peer:user_id() == ip then
						reset = false
					else
					end
				end
				if reset then
					print("[BaseNetworkSession:upd_trash_connections] resetting connection:", info.rpc:ip_at_index(0))
					Network:reset_connection(info.rpc)
				end
				self._trash_connections[ip] = nil
			end
		end
		if not next(self._trash_connections) then
			self._trash_connections = nil
		end
	end
	if self._soft_remove_peers then
		for peer_ip, info in pairs(self._soft_remove_peers) do
			if wall_t > info.expire_t then
				info.peer:destroy()
				self._soft_remove_peers[peer_ip] = nil
			else
			end
		end
		if not next(self._soft_remove_peers) then
			self._soft_remove_peers = nil
		end
	end
end
function BaseNetworkSession:add_connection_to_trash(rpc)
	local wanted_ip = rpc:ip_at_index(0)
	self._trash_connections = self._trash_connections or {}
	if not self._trash_connections[wanted_ip] then
		print("[BaseNetworkSession:add_connection_to_trash]", wanted_ip)
		self._trash_connections[wanted_ip] = {
			rpc = rpc,
			expire_t = TimerManager:wall_running():time() + self.CONNECTION_TIMEOUT
		}
	end
end
function BaseNetworkSession:remove_connection_from_trash(rpc)
	local wanted_ip = rpc:ip_at_index(0)
	if self._trash_connections then
		if self._trash_connections[wanted_ip] then
			print("[BaseNetworkSession:remove_connection_from_trash]", wanted_ip)
		end
		self._trash_connections[wanted_ip] = nil
		if not next(self._trash_connections) then
			self._trash_connections = nil
		end
	end
end
function BaseNetworkSession:remove_connection_from_soft_remove_peers(rpc)
	if self._soft_remove_peers and self._soft_remove_peers[rpc:ip_at_index(0)] then
		self._soft_remove_peers[rpc:ip_at_index(0)] = nil
		if not next(self._soft_remove_peers) then
			self._soft_remove_peers = nil
		end
	end
end
function BaseNetworkSession:chk_send_local_player_ready()
	local state = self._local_peer:waiting_for_player_ready()
	for peer_id, peer in pairs(self._peers) do
		if peer:ip_verified() then
			peer:send_after_load("set_member_ready", state)
		end
	end
end
function BaseNetworkSession:destroy()
	if self._dropin_complete_event_manager_id then
		EventManager:unregister_listener(self._dropin_complete_event_manager_id)
		self._dropin_complete_event_manager_id = nil
	end
end
function BaseNetworkSession:_flush_soft_remove_peers()
	if self._soft_remove_peers then
		for ip, peer_remove_info in pairs(self._soft_remove_peers) do
			cat_print("multiplayer_base", "[BaseNetworkSession:destroy] soft-removed peer", peer_remove_info.peer:id(), ip)
			peer_remove_info.peer:destroy()
		end
	end
	self._soft_remove_peers = nil
end
function BaseNetworkSession:on_load_complete()
	print("[BaseNetworkSession:on_load_complete]")
	self._local_peer:set_loading(false)
	for peer_id, peer in pairs(self._peers) do
		if peer:ip_verified() then
			peer:send("set_loading_state", false)
		end
	end
end
function BaseNetworkSession:chk_send_connection_established(name, user_id)
	local peer
	if SystemInfo:platform() == Idstring("PS3") then
		peer = self:peer_by_name(name)
		if not peer then
			print("[BaseNetworkSession:chk_send_connection_established] no peer yet", name)
			return
		end
		local connection_info = managers.network.matchmake:get_connection_info(name)
		if not connection_info then
			print("[BaseNetworkSession:chk_send_connection_established] no connection_info yet", name)
			return
		end
		if connection_info.dead then
			if peer:id() ~= 1 then
				print("[BaseNetworkSession:chk_send_connection_established] reporting dead connection", name)
				if self._server_peer then
					self._server_peer:send_queued_load("report_dead_connection", peer:id())
				end
			end
			return
		end
		local rpc = Network:handshake(connection_info.external_ip, connection_info.port, "TCP_IP")
		peer:set_rpc(rpc)
		self:remove_connection_from_trash(rpc)
		self:remove_connection_from_soft_remove_peers(rpc)
	else
		peer = self:peer_by_user_id(user_id)
		if not peer then
			print("[BaseNetworkSession:chk_send_connection_established] no peer yet", user_id)
			return
		end
		if not peer:rpc() then
			print("[BaseNetworkSession:chk_send_connection_established] no rpc yet", user_id)
			return
		end
		if self._matchmaking_server then
			self._matchmaking_server:match_stat_p2p_con_established(peer:rpc():protocol_at_index(0) == "TCP_IP" and 1 or 2)
		end
	end
	print("[BaseNetworkSession:chk_send_connection_established] success", name or "", user_id or "", peer:id())
	if self._server_peer then
		self._server_peer:send("connection_established", peer:id())
	end
end
function BaseNetworkSession:on_ask_IP_reply(my_ip_address, sender)
	print("[BaseNetworkSession:on_ask_IP_reply] my_ip_address", my_ip_address, "self._my_external_IP", self._my_external_IP, "sender", sender:ip_at_index(0))
	if not self._my_external_IP then
		self._my_external_IP = my_ip_address
		Global.my_external_IP = self._my_external_IP
	end
	if not self._matchmaking_server then
		self:set_matchmaking_server(sender)
	end
end
function BaseNetworkSession:_update_matchmaking_server_connection(wall_run_t)
	if wall_run_t > self._next_NAT_keep_alive_t then
		if self._matchmaking_server then
			if wall_run_t > self._matchmaking_server_expire_t then
				self:set_matchmaking_server(nil)
			else
				self._matchmaking_server:NAT_keep_alive()
			end
		elseif self._my_external_IP then
			for ip, rpc in pairs(self._matchmaking_server_rpcs) do
				rpc:NAT_keep_alive()
			end
		end
		if not self._my_external_IP then
			if self._matchmaking_server then
				self._matchmaking_server:ask_IP()
			else
				for ip, rpc in pairs(self._matchmaking_server_rpcs) do
					rpc:ask_IP()
				end
			end
		end
		self._next_NAT_keep_alive_t = wall_run_t + self._NAT_KEEP_ALIVE_INTERVAL
	end
end
function BaseNetworkSession:get_my_external_IP()
	return self._my_external_IP or Global.my_external_IP
end
function BaseNetworkSession:on_from_server_NAT_keep_alive(sender)
	if not self._matchmaking_server then
		self:set_matchmaking_server(sender)
	end
	if self._matchmaking_server:ip_at_index(0) ~= sender:ip_at_index(0) then
		return
	end
	self._matchmaking_server_expire_t = TimerManager:wall_running():time() + self._NAT_TIMEOUT
end
function BaseNetworkSession:set_matchmaking_server(rpc)
	if self._matchmaking_server then
		if rpc and self._matchmaking_server:ip_at_index(0) == sender:ip_at_index(0) then
			return
		else
			self:add_connection_to_trash(self._matchmaking_server)
		end
	end
	self._matchmaking_server = rpc
	if self._matchmaking_server then
		Network:set_connection_persistent(self._matchmaking_server, true)
		Network:set_throttling_disabled(self._matchmaking_server, true)
		self._next_NAT_keep_alive_t = 0
		self:remove_connection_from_trash(self._matchmaking_server)
		self:remove_connection_from_soft_remove_peers(self._matchmaking_server)
	else
		self._next_NAT_keep_alive_t = nil
	end
end
function BaseNetworkSession:_upd_send_peer_alive_checks(wall_run_t)
	if self._closing or wall_run_t < self._alive_send_t then
		return
	end
	for peer_id, peer in pairs(self._peers) do
		if peer:ip_verified() then
			if peer:rpc():protocol_at_index(0) == "STEAM" then
				peer:send("keep_alive")
			else
				peer:send("keep_alive_tcpip", self._local_peer:user_id())
			end
		end
	end
	self._alive_send_t = wall_run_t + self._KEEP_ALIVE_INTERVAL
end
