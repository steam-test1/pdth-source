HostStateInLobby = HostStateInLobby or class(HostStateBase)
function HostStateInLobby:on_join_request_received(data, peer_name, client_mask_set, dlcs, client_ip, client_user_id, sender)
	print("[HostStateInLobby:on_join_request_received]", peer_name, client_mask_set, dlcs, client_ip, client_user_id, sender:ip_at_index(0))
	if self:_has_peer_left_PSN(peer_name) then
		print("this CLIENT has left us from PSN, ignore his request", peer_name)
		return
	end
	local my_user_id = data.local_peer:user_id() or ""
	if self:_is_kicked(data, peer_name, sender) then
		print("YOU ARE IN MY KICKED LIST", peer_name)
		sender:join_request_reply(2, 0, 1, 1, 0, "", my_user_id)
		return
	end
	if data.wants_to_load_level then
		sender:join_request_reply(0, 0, 1, 1, 0, "", my_user_id)
		return
	end
	local old_peer = data.session:chk_peer_already_in(sender, client_user_id)
	if old_peer then
		print("[HostStateInLobby:on_join_request_received] already had peer", peer_name)
		if old_peer:creation_age() > 20 then
			print("[HostStateInLobby:on_join_request_received] Rejecting join. Peer was already in", peer_name)
			data.session:remove_peer(old_peer, old_peer:id(), "lost")
			sender:join_request_reply(0, 0, 1, 1, 0, "", my_user_id)
		end
		return
	end
	if table.size(data.peers) >= 3 then
		print("server is full")
		sender:join_request_reply(0, 0, 1, 1, 0, "", my_user_id)
		return
	end
	print("[HostStateInLobby:on_join_request_received] new peer accepted", peer_name)
	local new_peer_id, new_peer
	new_peer_id, new_peer = data.session:add_peer(peer_name, nil, true, false, false, nil, client_mask_set, client_user_id)
	if not new_peer_id then
		print("there was no clean peer_id")
		sender:join_request_reply(0, 0, 1, 1, 0, "", my_user_id)
		return
	end
	new_peer:set_dlcs(dlcs)
	local new_peer_rpc = sender
	new_peer:set_rpc(new_peer_rpc)
	Network:add_client(new_peer:rpc())
	new_peer:set_entering_lobby(true)
	local level_index = tweak_data.levels:get_index_from_level_id(Global.game_settings.level_id)
	local difficulty_index = tweak_data:difficulty_to_index(Global.game_settings.difficulty)
	new_peer_rpc:join_request_reply(1, new_peer_id, level_index, difficulty_index, 1, data.local_peer:mask_set(), my_user_id)
end
function HostStateInLobby:on_connection_to_peer_established(data, peer)
	peer:set_ip_verified(true)
	peer:send("set_loading_state", false)
	peer:send("set_character", data.local_peer:character())
	self:_introduce_new_peer_to_old_peers(data, peer)
	self:_introduce_old_peers_to_new_peer(data, peer)
	Global.local_member:sync_lobby_data(peer)
	self:on_handshake_confirmation(data, peer, 1)
end
function HostStateInLobby:is_joinable(data)
	return not data.wants_to_load_level
end
