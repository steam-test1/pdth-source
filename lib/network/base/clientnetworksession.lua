ClientNetworkSession = ClientNetworkSession or class(BaseNetworkSession)
function ClientNetworkSession:request_join_host(host_rpc, result_cb)
	print("[ClientNetworkSession:request_join_host]", host_rpc:ip_at_index(0), host_rpc:num_peers() > 1 and host_rpc:ip_at_index(1), result_cb)
	local my_external_IP = self:get_my_external_IP() or ""
	if SystemInfo:platform() == self._ids_WIN32 and my_external_IP == "" and managers.network:protocol_type() == "TCP_IP" then
		Application:error("no external IP")
	end
	print("my_external_IP", my_external_IP)
	self._cb_find_game = result_cb
	local host_name = managers.network.matchmake:game_owner_name()
	local my_user_id = ""
	local host_user_id = SystemInfo:platform() == self._ids_WIN32 and host_rpc:ip_at_index(0) or false
	local id, peer = self:add_peer(host_name, nil, nil, nil, nil, 1, nil, host_user_id)
	if SystemInfo:platform() == self._ids_WIN32 then
		peer:set_steam_rpc(Network:handshake(host_rpc:ip_at_index(0), nil, "STEAM"))
		my_user_id = Steam:userid()
	end
	self._server_peer = peer
	Network:set_multiplayer(true)
	Network:set_client(host_rpc)
	if SystemInfo:platform() == self._ids_WIN32 and managers.network:protocol_type() == "TCP_IP" then
		print("huh?")
		Network:broadcast(NetworkManager.DEFAULT_PORT):request_join_broadcast(self._local_peer:name(), self._local_peer:mask_set(), managers.dlc:dlcs_string(), my_external_IP, my_user_id, host_user_id)
		print("huh2?")
	end
	host_rpc:request_join(self._local_peer:name(), self._local_peer:mask_set(), managers.dlc:dlcs_string(), my_external_IP, my_user_id, host_user_id)
	self._join_start_t = TimerManager:wall_running():time()
end
function ClientNetworkSession:on_join_request_reply(reply, my_peer_id, level_index, difficulty_index, state_index, mask_set, user_id, sender)
	print("[ClientNetworkSession:on_join_request_reply] ", self._server_peer and self._server_peer:user_id(), user_id, sender:ip_at_index(0), sender:protocol_at_index(0))
	if not self._server_peer or not self._cb_find_game then
		return
	end
	if self._server_peer:ip() and sender:ip_at_index(0) ~= self._server_peer:ip() then
		print("[ClientNetworkSession:on_join_request_reply] wrong host replied", self._server_peer:ip(), sender:ip_at_index(0))
		return
	end
	if SystemInfo:platform() == self._ids_WIN32 then
		if self._server_peer:user_id() and user_id ~= self._server_peer:user_id() then
			print("[ClientNetworkSession:on_join_request_reply] wrong host replied", self._server_peer:user_id(), user_id)
			return
		else
			if sender:protocol_at_index(0) == "STEAM" then
				self._server_protocol = "STEAM"
				if self._matchmaking_server then
					self._matchmaking_server:match_stat_p2p_con_established(2)
				end
			else
				self._server_protocol = "TCP_IP"
				if self._matchmaking_server then
					self._matchmaking_server:match_stat_p2p_con_established(1)
				end
			end
			print("self._server_protocol", self._server_protocol)
			local host_handshake_time = TimerManager:wall_running():time() - self._join_start_t
			print("host_handshake_time", host_handshake_time)
			self._server_peer:set_rpc(sender)
			self._server_peer:set_ip_verified(true)
			Network:set_client(sender)
			self._server_peer:send("connection_established", self._server_peer:id())
		end
	end
	local cb = self._cb_find_game
	self._cb_find_game = nil
	if reply == 1 then
		Global.game_settings.level_id = tweak_data.levels:get_level_name_from_index(level_index)
		Global.game_settings.difficulty = tweak_data:index_to_difficulty(difficulty_index)
		self._server_peer:set_mask_set(mask_set)
		self._local_peer:set_id(my_peer_id)
		self._server_peer:set_id(1)
		self._server_peer:set_in_lobby_soft(state_index == 1)
		self._server_peer:set_synched_soft(state_index ~= 1)
		if SystemInfo:platform() == Idstring("PS3") then
		end
		cb(state_index == 1 and "JOINED_LOBBY" or "JOINED_GAME", level_index, difficulty_index, state_index)
	elseif reply == 2 then
		self:remove_peer(self._server_peer, 1)
		cb("KICKED")
	elseif reply == 0 then
		self:remove_peer(self._server_peer, 1)
		cb("FAILED_CONNECT")
	elseif reply == 3 then
		self:remove_peer(self._server_peer, 1)
		cb("GAME_STARTED")
	elseif reply == 4 then
		self:remove_peer(self._server_peer, 1)
		cb("DO_NOT_OWN_HEIST")
	end
end
function ClientNetworkSession:on_join_request_timed_out()
	local cb = self._cb_find_game
	self._cb_find_game = nil
	cb("TIMED_OUT")
end
function ClientNetworkSession:on_join_request_cancelled()
	local cb = self._cb_find_game
	if cb then
		self._cb_find_game = nil
		if self._server_peer then
			self:remove_peer(self._server_peer, 1)
		end
		cb("CANCELLED")
	end
end
function ClientNetworkSession:discover_hosts()
	self._discovered_hosts = {}
	Network:broadcast(NetworkManager.DEFAULT_PORT):discover_host()
end
function ClientNetworkSession:on_host_discovered(new_host, new_host_name, level_name, my_ip, state, difficulty)
	if self._discovered_hosts then
		local new_host_data = {
			rpc = new_host,
			host_name = new_host_name,
			level_name = level_name,
			my_ip = my_ip,
			state = state,
			difficulty = difficulty
		}
		local already_known
		for i_host, host_data in ipairs(self._discovered_hosts) do
			if host_data.host_name == new_host_name and host_data.rpc:ip_at_index(0) == new_host:ip_at_index(0) then
				self._discovered_hosts[i_host] = new_host_data
				already_known = true
				break
			end
		end
		if not already_known then
			table.insert(self._discovered_hosts, new_host_data)
		end
	end
end
function ClientNetworkSession:on_server_up_received(host_rpc)
	if self._discovered_hosts then
		host_rpc:request_host_discover_reply()
	end
end
function ClientNetworkSession:discovered_hosts()
	return self._discovered_hosts
end
function ClientNetworkSession:send_to_host(...)
	if self._server_peer then
		self._server_peer:send(...)
	else
		print("[ClientNetworkSession:send_to_host] no host")
	end
end
function ClientNetworkSession:is_host()
	return false
end
function ClientNetworkSession:is_client()
	return true
end
function ClientNetworkSession:load_level(...)
	self:_load_level(...)
end
function ClientNetworkSession:peer_handshake(name, peer_id, peer_user_id, in_lobby, loading, synched, character, mask_set, peer_ip)
	print("ClientNetworkSession:peer_handshake", name, peer_id, peer_user_id, in_lobby, loading, synched, character, mask_set, peer_ip)
	if self._peers[peer_id] then
		print("ALREADY HAD PEER returns here")
		local peer = self._peers[peer_id]
		if peer:ip_verified() then
			self._server_peer:send("connection_established", peer_id)
		end
		return
	end
	peer_user_id = SystemInfo:platform() == self._ids_WIN32 and peer_user_id or false
	local id, peer = self:add_peer(name, nil, in_lobby, loading, synched, peer_id, mask_set, peer_user_id)
	peer:set_character(character)
	if peer_ip and SystemInfo:platform() == self._ids_WIN32 and managers.network:protocol_type() == "TCP_IP" then
		peer:set_tmp_udp_rpc(Network:handshake(peer_ip, nil, "TCP_IP"))
	end
	cat_print("multiplayer_base", "[ClientNetworkSession:peer_handshake]", name, peer_user_id, loading, synched, id, inspect(peer))
	if self._connection_established_results[name] then
		self:on_connection_established(name, self._connection_established_results[name])
	end
	self:chk_send_connection_established(name, peer_user_id)
	if managers.trade then
		managers.trade:handshake_complete(peer_id)
	end
end
function ClientNetworkSession:on_connection_established(name, ip)
	if SystemInfo:platform() ~= Idstring("PS3") then
		return
	end
	local peer = self:peer_by_name(name)
	if peer then
		print("[ClientNetworkSession:on_connection_established]", name, "sender ip", ip, "peer:ip()", peer:ip())
		if ip ~= peer:ip() or not peer:rpc() then
			peer:set_rpc(Network:handshake(ip, nil, "TCP_IP"))
		end
		return
	end
	print("[ClientNetworkSession:on_connection_established]", name, "didn't exist, store it", ip)
	self._connection_established_results[name] = ip
end
function ClientNetworkSession:on_peer_synched(peer_id)
	local peer = self._peers[peer_id]
	if not peer then
		cat_error("multiplayer_base", "[ClientNetworkSession:on_peer_synched] Unknown Peer:", peer_id)
		return
	end
	peer:set_loading(false)
	peer:set_synched(true)
	managers.network:game():on_peer_sync_complete(peer, peer_id)
end
function ClientNetworkSession:ok_to_load_level()
	print("[ClientNetworkSession:ok_to_load_level]", self._recieved_ok_to_load_level, self._local_peer:id())
	if self._closing then
		return
	end
	self:send_to_host("set_loading_state", true)
	if self._recieved_ok_to_load_level then
		print("Allready recieved ok to load level, returns")
		return
	end
	self._recieved_ok_to_load_level = true
	if managers.menu:active_menu() then
		managers.menu:close_menu()
	end
	managers.system_menu:force_close_all()
	local level_id = Global.game_settings.level_id
	local level_name = level_id and tweak_data.levels[level_id].world_name
	managers.network:session():load_level(level_name, nil, nil, nil, level_id)
end
function ClientNetworkSession:on_mutual_connection(other_peer_id)
	local other_peer = self._peers[other_peer_id]
	if not other_peer then
		return
	end
	other_peer:set_next_p2p_ping_send_t(nil)
	other_peer:set_ip_verified(true)
	Global.local_member:sync_lobby_data(other_peer)
	Global.local_member:sync_data(other_peer)
	other_peer:send("set_character", self._local_peer:character())
	other_peer:send("set_loading_state", self._local_peer:loading())
	if self._local_peer:loaded() and other_peer:ip_verified() then
		other_peer:send_after_load("set_member_ready", self._local_peer:waiting_for_player_ready())
	end
end
function ClientNetworkSession:update()
	ClientNetworkSession.super.update(self)
	if self._closing then
		return
	end
	local wall_time = TimerManager:wall_running():time()
	self:send_handshake_p2p_ping_msgs(wall_time)
end
function ClientNetworkSession:_soft_remove_peer(peer)
	ClientNetworkSession.super._soft_remove_peer(self, peer)
	if peer:id() == 1 then
		Network:set_disconnected()
	end
end
function ClientNetworkSession:on_peer_save_received(event, event_data)
	if managers.network:stopping() then
		return
	end
	local packet_index = event_data.index
	local total_nr_packets = event_data.total
	print("[ClientNetworkSession:on_peer_save_received]", packet_index, "/", total_nr_packets)
	local kit_menu = managers.menu:get_menu("kit_menu")
	if not kit_menu or not kit_menu.renderer:is_open() then
		return
	end
	if packet_index == total_nr_packets then
		local is_ready = self._local_peer:waiting_for_player_ready()
		if is_ready then
			kit_menu.renderer:set_slot_ready(self._local_peer, self._local_peer:id())
		else
			kit_menu.renderer:set_slot_not_ready(self._local_peer, self._local_peer:id())
		end
	else
		local progress_ratio = packet_index / total_nr_packets
		local progress_percentage = math.floor(math.clamp(progress_ratio * 100, 0, 100))
		managers.menu:get_menu("kit_menu").renderer:set_dropin_progress(self._local_peer:id(), progress_percentage)
	end
end
function ClientNetworkSession:load(data)
	ClientNetworkSession.super.load(self, data)
end
function ClientNetworkSession:on_load_complete()
	ClientNetworkSession.super.on_load_complete(self)
end
function ClientNetworkSession:send_handshake_p2p_ping_msgs(wall_t)
	if SystemInfo:platform() ~= self._ids_WIN32 then
		return
	end
	for peer_id, peer in pairs(self._peers) do
		if peer_id < self._local_peer:id() and peer ~= self._server_peer and not peer:ip_verified() and (not peer:next_p2p_ping_send_t() or wall_t > peer:next_p2p_ping_send_t()) then
			local my_user_id = Steam:userid()
			if peer:tmp_udp_rpc() then
				Network:broadcast(NetworkManager.DEFAULT_PORT):p2p_ping(my_user_id)
				peer:tmp_udp_rpc():p2p_ping(my_user_id)
			end
			peer:steam_rpc():p2p_ping(my_user_id)
			peer:set_next_p2p_ping_send_t(wall_t + self._STEAM_P2P_SEND_INTERVAL)
		end
	end
end
function ClientNetworkSession:on_p2p_ping(user_id, is_reply, sender)
	print("[ClientNetworkSession:on_p2p_ping]", user_id, type(user_id), is_reply, sender:ip_at_index(0))
	local peer = self:peer_by_user_id(user_id)
	print("[ClientNetworkSession:on_p2p_ping] peer", inspect(peer))
	if peer and peer ~= self._local_peer and (is_reply and peer:id() < self._local_peer:id() or not is_reply and peer:id() > self._local_peer:id()) then
		if not is_reply and (not peer:rpc() or peer:rpc():ip_at_index(0) == sender:ip_at_index(0)) then
			sender:p2p_ping_reply(self._local_peer:user_id())
		end
		if peer:rpc() then
			print("[ClientNetworkSession:on_p2p_ping] already had rpc", peer:rpc():ip_at_index(0))
			return
		end
		peer:set_rpc(sender)
		self:chk_send_connection_established(nil, user_id)
	else
		self._connection_established_results[user_id] = sender:ip_at_index(0)
	end
	self:remove_connection_from_trash(sender)
	self:remove_connection_from_soft_remove_peers(sender)
end
