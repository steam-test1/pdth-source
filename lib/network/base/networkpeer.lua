NetworkPeer = NetworkPeer or class()
NetworkPeer.PRE_HANDSHAKE_CHK_TIME = 20
function NetworkPeer:init(name, rpc, id, loading, synced, in_lobby, mask_set, user_id)
	self._name = name or "NAMELESS PEER ID:" .. tostring(id)
	self._rpc = rpc
	self._id = id
	self._mask_set = mask_set
	self._user_id = user_id
	if self._rpc then
		Network:set_connection_persistent(rpc, true)
		self._ip = self._rpc:ip_at_index(0)
		Network:set_throttling_disabled(self._rpc, true)
	end
	if user_id then
		self._steam_rpc = Network:handshake(user_id, nil, "STEAM")
		Network:set_connection_persistent(self._steam_rpc, true)
		Network:set_throttling_disabled(self._steam_rpc, true)
	end
	self._level = 0
	self._in_lobby = in_lobby
	self._loading = loading
	self._synced = synced
	self._waiting_for_player_ready = false
	self._ip_verified = false
	self._dlcs = {
		dlc1 = false,
		dlc2 = false,
		dlc3 = false,
		dlc4 = false
	}
	self:chk_enable_queue()
	self._character = "random"
	self._overwriteable_msgs = deep_clone(managers.network.OVERWRITEABLE_MSGS)
	self._overwriteable_queue = {}
	self:_chk_flush_msg_queues()
	self._activate_timeout_t = TimerManager:wall_running():time() + self.PRE_HANDSHAKE_CHK_TIME
	self._creation_t = TimerManager:wall_running():time()
	if self._rpc and not self._loading and managers.network.voice_chat.on_member_added and self._rpc:ip_at_index(0) ~= Network:self("TCP_IP"):ip_at_index(0) then
		managers.network.voice_chat:on_member_added(self)
	end
	self._handshakes = {}
end
function NetworkPeer:set_rpc(rpc)
	self._rpc = rpc
	if self._rpc then
		Network:set_connection_persistent(rpc, true)
		self._ip = self._rpc:ip_at_index(0)
		Network:set_throttling_disabled(self._rpc, true)
		self:_chk_flush_msg_queues()
		if managers.network.voice_chat.on_member_added then
			managers.network.voice_chat:on_member_added(self)
		end
	end
end
function NetworkPeer:set_steam_rpc(rpc)
	self._steam_rpc = rpc
	if self._steam_rpc then
		Network:set_connection_persistent(self._steam_rpc, true)
		Network:set_throttling_disabled(self._steam_rpc, true)
	end
end
function NetworkPeer:set_tmp_udp_rpc(rpc)
	self._tmp_udp_rpc = rpc
	if self._tmp_udp_rpc then
		Network:set_connection_persistent(self._tmp_udp_rpc, true)
		Network:set_throttling_disabled(self._tmp_udp_rpc, true)
	end
end
function NetworkPeer:tmp_udp_rpc()
	return self._tmp_udp_rpc
end
function NetworkPeer:set_dlcs(dlcs)
	local i_dlcs = string.split(dlcs, " ")
	for _, dlc in ipairs(i_dlcs) do
		self._dlcs[dlc] = true
	end
end
function NetworkPeer:has_dlc(dlc)
	return self._dlcs[dlc]
end
function NetworkPeer:load(data)
	print("[NetworkPeer:load] data:", inspect(data))
	self._name = data.name
	self._rpc = data.rpc
	self._steam_rpc = data.steam_rpc
	self._id = data.id
	if self._rpc then
		self._ip = self._rpc:ip_at_index(0)
	end
	print("LOAD IP", self._ip, "self._rpc ip", self._rpc and self._rpc:ip_at_index(0))
	self._synced = data.synced
	self._character = data.character
	self._ip_verified = data.ip_verified
	self._creation_t = data.creation_t
	self._mask_set = data.mask_set
	self._dlcs = data.dlcs
	self._handshakes = data.handshakes
	self._loaded = data.loaded
	self._loading = data.loading
	self._msg_queues = data.msg_queues
	self._user_id = data.user_id
	self._force_open_lobby = data.force_open_lobby
	self:chk_enable_queue()
	self:_chk_flush_msg_queues()
	if self._rpc and not self._loading and managers.network.voice_chat.on_member_added then
		managers.network.voice_chat:on_member_added(self)
	end
	self._expected_dropin_pause_confirmations = data.expected_dropin_pause_confirmations
	self._activate_timeout_t = TimerManager:wall_running():time() + self.PRE_HANDSHAKE_CHK_TIME
end
function NetworkPeer:save(data)
	data.name = self._name
	data.rpc = self._rpc
	data.steam_rpc = self._steam_rpc
	data.id = self._id
	print("SAVE IP", data.ip, "self._rpc ip", self._rpc and self._rpc:ip_at_index(0), "self._steam_rpc", self._steam_rpc)
	data.synced = self._synced
	data.character = self._character
	data.ip_verified = self._ip_verified
	data.creation_t = self._creation_t
	data.mask_set = self._mask_set
	data.dlcs = self._dlcs
	data.handshakes = self._handshakes
	data.loaded = self._loaded
	data.loading = self._loading
	data.expected_dropin_pause_confirmations = self._expected_dropin_pause_confirmations
	data.msg_queues = self._msg_queues
	data.user_id = self._user_id
	data.force_open_lobby = self._force_open_lobby
	print("[NetworkPeer:save]", inspect(data))
end
function NetworkPeer:name()
	return self._name
end
function NetworkPeer:ip()
	return self._ip
end
function NetworkPeer:id()
	return self._id
end
function NetworkPeer:rpc()
	return self._rpc
end
function NetworkPeer:steam_rpc()
	return self._steam_rpc
end
function NetworkPeer:connection_info()
	local ip = self._rpc:protocol_at_index(0) == "TCP_IP" and self._ip or ""
	return self._name, self._id, self._user_id or "", self._in_lobby, self._loading, self._synced, self._character, self._mask_set, ip
end
function NetworkPeer:synched()
	return self._synced
end
function NetworkPeer:loading()
	return self._loading
end
function NetworkPeer:loaded()
	return self._loaded
end
function NetworkPeer:in_lobby()
	return self._in_lobby
end
function NetworkPeer:character()
	return self._character
end
function NetworkPeer:set_mask_set(mask_set)
	self._mask_set = mask_set
end
function NetworkPeer:mask_set()
	return self._mask_set
end
function NetworkPeer:used_deployable()
	return self._used_deployable
end
function NetworkPeer:set_used_deployable(used)
	self._used_deployable = used
end
function NetworkPeer:waiting_for_player_ready()
	return self._waiting_for_player_ready
end
function NetworkPeer:ip_verified()
	return self._ip_verified
end
function NetworkPeer:set_ip_verified(state)
	cat_print("multiplayer_base", "NetworkPeer:set_ip_verified", state, self._name, self._id)
	self._ip_verified = state
	self:_chk_flush_msg_queues()
end
function NetworkPeer:set_loading(state)
	cat_print("multiplayer_base", "[NetworkPeer:set_loading]", state, "was loading", self._loading, "id", self._id)
	if self._loading and not state then
		self._loaded = true
	end
	self._activate_timeout_t = TimerManager:wall_running():time() + self.PRE_HANDSHAKE_CHK_TIME
	self._loading = state
	if state then
		self:chk_enable_queue()
	end
	self:_chk_flush_msg_queues()
	if self == managers.network:session():local_peer() then
		return
	end
	managers.network:game():on_peer_loading(self, state)
	if state then
		self._waiting_to_start_loading = nil
		if managers.network.voice_chat.on_member_removed then
			managers.network.voice_chat:on_member_removed(self)
		end
	elseif self._rpc and managers.network.voice_chat.on_member_added then
		managers.network.voice_chat:on_member_added(self)
	end
end
function NetworkPeer:set_loaded(state)
	self._loaded = state
end
function NetworkPeer:set_synched(state)
	cat_print("multiplayer_base", "[NetworkPeer:set_synched]", self._id, state)
	self._synced = state
	if state then
		self._syncing = false
	end
	self:_chk_flush_msg_queues()
end
function NetworkPeer:on_sync_start()
	self._syncing = true
end
function NetworkPeer:set_entering_lobby(state)
	self._entering_lobby = state
end
function NetworkPeer:entering_lobby()
	return self._entering_lobby
end
function NetworkPeer:set_in_lobby(state)
	cat_print("multiplayer_base", "NetworkPeer:set_in_lobby", state, self._id)
	self._in_lobby = state
	if state then
		self._entering_lobby = false
	end
	self:_chk_flush_msg_queues()
end
function NetworkPeer:set_in_lobby_soft(state)
	self._in_lobby = state
end
function NetworkPeer:set_synched_soft(state)
	self._synced = state
	self:_chk_flush_msg_queues()
end
function NetworkPeer:set_character(character)
	self._character = character
end
function NetworkPeer:set_waiting_for_player_ready(state)
	cat_print("multiplayer_base", "NetworkPeer:waiting_for_player_ready", state, self._id)
	self._waiting_for_player_ready = state
end
function NetworkPeer:set_statistics(total_kills, total_specials_kills, total_head_shots, accuracy, downs)
	self._statistics = {
		total_kills = total_kills,
		total_specials_kills = total_specials_kills,
		total_head_shots = total_head_shots,
		accuracy = accuracy,
		downs = downs
	}
end
function NetworkPeer:statistics()
	return self._statistics
end
function NetworkPeer:has_statistics()
	return self._statistics and true or false
end
function NetworkPeer:send(func_name, ...)
	if not self._ip_verified then
		debug_pause("[NetworkPeer:send] ip unverified:", func_name, ...)
		return
	end
	local rpc = self._rpc
	rpc[func_name](rpc, ...)
end
function NetworkPeer:_send_queued(queue_name, func_name, ...)
	if self._msg_queues and self._msg_queues[queue_name] then
		self:_push_to_queue(queue_name, func_name, ...)
	else
		local overwrite_data = self._overwriteable_msgs[func_name]
		if overwrite_data then
			overwrite_data.clbk(overwrite_data, self._overwriteable_queue, func_name, ...)
			return
		end
		self:send(func_name, ...)
	end
end
function NetworkPeer:send_after_load(...)
	if not self._ip_verified then
		Application:error("[NetworkPeer:send_after_load] ip unverified:", ...)
		return
	end
	self:_send_queued("load", ...)
end
function NetworkPeer:send_queued_sync(...)
	if not self._ip_verified then
		Application:error("[NetworkPeer:send_queued_sync] ip unverified:", ...)
		return
	end
	if self._synced or self._syncing then
		self:_send_queued("sync", ...)
	end
end
function NetworkPeer:_chk_flush_msg_queues()
	if not self._msg_queues or not self._ip_verified then
		return
	end
	if not self._loading then
		self:_flush_queue("load")
	end
	if self._synced then
		self:_flush_queue("sync")
	end
	if not next(self._msg_queues) then
		self._msg_queues = nil
	end
end
function NetworkPeer:chk_enable_queue()
	if self._loading then
		self._msg_queues = self._msg_queues or {}
		self._msg_queues.load = self._msg_queues.load or {}
	end
	if not self._synched then
		self._msg_queues = self._msg_queues or {}
		self._msg_queues.sync = self._msg_queues.sync or {}
	end
end
function NetworkPeer:_push_to_queue(queue_name, ...)
	table.insert(self._msg_queues[queue_name], {
		...
	})
end
function NetworkPeer:_flush_queue(queue_name)
	local msg_queue = self._msg_queues[queue_name]
	if not msg_queue then
		return
	end
	self._msg_queues[queue_name] = nil
	local ok
	for i, msg in ipairs(msg_queue) do
		ok = true
		for _, param in ipairs(msg) do
			local param_type = type_name(param)
			if param_type == "Unit" then
				if not alive(param) or param:id() == -1 then
					ok = nil
					break
				end
			elseif param_type == "Body" and not alive(param) then
				ok = nil
				break
			end
		end
		if ok then
			self:send(unpack(msg))
		end
	end
end
function NetworkPeer:chk_timeout(timeout, wall_run_t)
	if wall_run_t < self._activate_timeout_t then
		return
	end
	if self._rpc then
		if not self._waiting_to_start_loading then
			local silent_time = Network:receive_silent_time(self._rpc)
			if timeout < silent_time then
				if self._steam_rpc then
					silent_time = math.min(silent_time, Network:receive_silent_time(self._steam_rpc))
				end
				if timeout < silent_time then
					print("PINGED OUT", silent_time, timeout)
					self:_ping_timedout()
				end
			end
		end
	else
		self:_ping_timedout()
	end
end
function NetworkPeer:on_lost()
	self._in_lobby = false
	self._loading = false
	self._synced = false
	self._waiting_for_player_ready = false
	self._msg_queue = nil
end
function NetworkPeer:_ping_timedout()
	managers.network:session():on_peer_lost(self, self._id)
end
function NetworkPeer:set_ip(my_ip)
	self._ip = my_ip
end
function NetworkPeer:set_id(my_id)
	self._id = my_id
end
function NetworkPeer:set_name(name)
	self._name = name
end
function NetworkPeer:destroy()
	print("!! NetworkPeer:destroy()", self:id())
	if self._rpc then
		Network:reset_connection(self._rpc)
		if managers.network.voice_chat.on_member_removed then
			managers.network.voice_chat:on_member_removed(self)
		end
	end
	if self._steam_rpc then
		Network:reset_connection(self._steam_rpc)
	end
end
function NetworkPeer:on_send()
	self:flush_overwriteable_msgs()
end
function NetworkPeer:flush_overwriteable_msgs()
	local overwriteable_queue = self._overwriteable_queue
	if self._loading or not next(overwriteable_queue) then
		return
	end
	for msg_name, data in pairs(self._overwriteable_msgs) do
		data.clbk(data)
	end
	for msg_name, rpc_params in pairs(overwriteable_queue) do
		self:send(unpack(rpc_params))
		overwriteable_queue[msg_name] = nil
	end
end
function NetworkPeer:set_expecting_drop_in_pause_confirmation(dropin_peer_id, state)
	print(" [NetworkPeer:set_expecting_drop_in_pause_confirmation] peer", self._id, "dropin_peer", dropin_peer_id, "state", state)
	if state then
		self._expected_dropin_pause_confirmations = self._expected_dropin_pause_confirmations or {}
		self._expected_dropin_pause_confirmations[dropin_peer_id] = state
	elseif self._expected_dropin_pause_confirmations then
		self._expected_dropin_pause_confirmations[dropin_peer_id] = nil
		if not next(self._expected_dropin_pause_confirmations) then
			self._expected_dropin_pause_confirmations = nil
		end
	end
end
function NetworkPeer:is_expecting_pause_confirmation(dropin_peer_id)
	return self._expected_dropin_pause_confirmations and self._expected_dropin_pause_confirmations[dropin_peer_id]
end
function NetworkPeer:expected_dropin_pause_confirmations()
	return self._expected_dropin_pause_confirmations
end
function NetworkPeer:set_expecting_pause_sequence(state)
	self._expecting_pause_sequence = state
end
function NetworkPeer:expecting_pause_sequence()
	return self._expecting_pause_sequence
end
function NetworkPeer:set_expecting_dropin(state)
	self._expecting_dropin = state
end
function NetworkPeer:expecting_dropin()
	return self._expecting_dropin
end
function NetworkPeer:on_ok_load_level_sent()
	print("[NetworkPeer:on_ok_load_level_sent]", self._id)
	self._waiting_to_start_loading = true
end
function NetworkPeer:is_waiting_to_start_loading()
	return self._waiting_to_start_loading
end
function NetworkPeer:creation_t()
	return self._creation_t
end
function NetworkPeer:creation_age()
	return TimerManager:wall_running():time() - self._creation_t
end
function NetworkPeer:set_level(level)
	self._level = level
	if managers.hud then
		managers.hud:update_name_label_by_peer(self)
	end
end
function NetworkPeer:level()
	return self._level
end
function NetworkPeer:set_handshake_status(introduced_peer_id, status)
	print("[NetworkPeer:set_handshake_status]", self._id, introduced_peer_id, status)
	Application:stack_dump()
	self._handshakes[introduced_peer_id] = status
end
function NetworkPeer:handshakes()
	return self._handshakes
end
function NetworkPeer:has_queued_rpcs()
	if not self._msg_queues then
		return
	end
	for queue_name, queue in pairs(self._msg_queues) do
		if next(queue) then
			return queue_name
		end
	end
end
function NetworkPeer:user_id()
	return self._user_id
end
function NetworkPeer:next_p2p_ping_send_t()
	return self._next_p2p_ping_send_t
end
function NetworkPeer:set_next_p2p_ping_send_t(t)
	self._next_p2p_ping_send_t = t
end
function NetworkPeer:set_force_open_lobby_state(state)
	self._force_open_lobby = state or nil
end
function NetworkPeer:force_open_lobby_state()
	return self._force_open_lobby
end
