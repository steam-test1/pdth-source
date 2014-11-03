ConnectionNetworkHandler = ConnectionNetworkHandler or class(BaseNetworkHandler)
function ConnectionNetworkHandler:server_up(sender)
	if not self._verify_in_session() or Application:editor() then
		return
	end
	managers.network:session():on_server_up_received(sender)
end
function ConnectionNetworkHandler:request_host_discover_reply(sender)
	if not self._verify_in_server_session() then
		return
	end
	managers.network:on_discover_host_received(sender)
end
function ConnectionNetworkHandler:discover_host(sender)
	if not self._verify_in_server_session() or Application:editor() then
		return
	end
	managers.network:on_discover_host_received(sender)
end
function ConnectionNetworkHandler:discover_host_reply(sender_name, level_id, level_name, my_ip, state, difficulty, sender)
	if not self._verify_in_client_session() then
		return
	end
	if level_name == "" then
		level_name = tweak_data.levels:get_world_name_from_index(level_id)
		if not level_name then
			cat_print("multiplayer_base", "[ConnectionNetworkHandler:discover_host_reply] Ignoring host", sender_name, ". I do not have this level in my revision.")
			return
		end
	end
	managers.network:on_discover_host_reply(sender, sender_name, level_name, my_ip, state, difficulty)
end
function ConnectionNetworkHandler:request_join(peer_name, mask_set, dlcs, client_ip, client_user_id, host_user_id, sender)
	if not self._verify_in_server_session() then
		return
	end
	if client_user_id == "" then
		client_user_id = nil
	end
	if SystemInfo:platform() == Idstring("WIN32") and Steam:userid() ~= host_user_id then
		print("[ConnectionNetworkHandler:request_join] wrong host_user_id", host_user_id)
		return
	end
	managers.network:session():on_join_request_received(peer_name, mask_set, dlcs, client_ip, client_user_id, sender)
end
function ConnectionNetworkHandler:request_join_broadcast(...)
	self:request_join(...)
end
function ConnectionNetworkHandler:join_request_reply(reply_id, my_peer_id, level_index, difficulty_index, state, mask_set, user_id, sender)
	print(" 1 ConnectionNetworkHandler:join_request_reply", reply_id, my_peer_id, level_index, difficulty_index, state, mask_set, user_id, sender)
	if not self._verify_in_client_session() then
		return
	end
	managers.network:session():on_join_request_reply(reply_id, my_peer_id, level_index, difficulty_index, state, mask_set, user_id, sender)
end
function ConnectionNetworkHandler:peer_handshake(name, peer_id, peer_user_id, in_lobby, loading, synched, character, mask_set, peer_ip)
	print(" 1 ConnectionNetworkHandler:peer_handshake", name, peer_id, peer_user_id, in_lobby, loading, synched, character, mask_set, peer_ip)
	if not self._verify_in_client_session() then
		return
	end
	if peer_ip == "" then
		peer_ip = nil
	end
	managers.network:session():peer_handshake(name, peer_id, peer_user_id, in_lobby, loading, synched, character, mask_set, peer_ip)
end
function ConnectionNetworkHandler:p2p_ping(user_id, sender)
	if not self._verify_in_client_session() then
		return
	end
	managers.network:session():on_p2p_ping(user_id, false, sender)
end
function ConnectionNetworkHandler:p2p_ping_reply(user_id, sender)
	if not self._verify_in_client_session() then
		return
	end
	managers.network:session():on_p2p_ping(user_id, true, sender)
end
function ConnectionNetworkHandler:connection_established(peer_id, sender)
	if not self._verify_in_server_session() then
		return
	end
	local sender_peer = self._verify_sender(sender)
	if not sender_peer then
		return
	end
	managers.network:session():on_peer_connection_established(sender_peer, peer_id)
end
function ConnectionNetworkHandler:mutual_connection(other_peer_id)
	print("[ConnectionNetworkHandler:mutual_connection]", other_peer_id)
	if not self._verify_in_client_session() then
		return
	end
	managers.network:session():on_mutual_connection(other_peer_id)
end
function ConnectionNetworkHandler:remove_dead_peer(peer_id, sender)
	print("[ConnectionNetworkHandler:remove_dead_peer]", peer_id, sender:ip_at_index(0))
	if not self._verify_sender(sender) then
		return
	end
	sender:remove_peer_confirmation(peer_id)
	local peer = managers.network:session():peer(peer_id)
	if not peer then
		print("[ConnectionNetworkHandler:remove_dead_peer] unknown peer", peer_id)
		return
	end
	managers.network:session():on_remove_dead_peer(peer, peer_id)
end
function ConnectionNetworkHandler:kick_peer(peer_id, sender)
	if not self._verify_sender(sender) then
		return
	end
	sender:remove_peer_confirmation(peer_id)
	local peer = managers.network:session():peer(peer_id)
	if not peer then
		print("[ConnectionNetworkHandler:kick_peer] unknown peer", peer_id)
		return
	end
	managers.network:session():on_peer_kicked(peer, peer_id)
end
function ConnectionNetworkHandler:remove_peer_confirmation(removed_peer_id, sender)
	local sender_peer = self._verify_sender(sender)
	if not sender_peer then
		return
	end
	managers.network:session():on_remove_peer_confirmation(sender_peer, removed_peer_id)
end
function ConnectionNetworkHandler:set_loading_state(state, sender)
	local peer = self._verify_sender(sender)
	if not peer then
		return
	end
	managers.network:session():set_peer_loading_state(peer, state)
end
function ConnectionNetworkHandler:set_character(character, sender)
	local peer = self._verify_sender(sender)
	if peer then
		peer:set_character(character)
	end
end
function ConnectionNetworkHandler:set_peer_synched(id, sender)
	if not self._verify_sender(sender) then
		return
	end
	managers.network:session():on_peer_synched(id)
end
function ConnectionNetworkHandler:set_dropin(char_name)
	if game_state_machine:current_state().set_dropin then
		game_state_machine:current_state():set_dropin(char_name)
	end
end
function ConnectionNetworkHandler:spawn_dropin_penalty(dead, bleed_out, health, used_deployable)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame_playing) then
		return
	end
	local player = managers.player:player_unit()
	print("[ConnectionNetworkHandler:spawn_dropin_penalty]", dead, bleed_out, health)
	if not alive(player) then
		return
	end
	if used_deployable then
		managers.player:clear_equipment()
	end
	local min_health
	if dead or bleed_out then
		min_health = 0
	else
		min_health = 0.25
	end
	player:character_damage():set_health(math.max(min_health, health) * player:character_damage():_max_health())
	player:inventory():set_ammo(0.5)
	if dead or bleed_out then
		print("[ConnectionNetworkHandler:spawn_dead] Killing")
		IngameFatalState.client_died()
		player:base():set_enabled(false)
		game_state_machine:change_state_by_name("ingame_waiting_for_respawn")
		player:character_damage():set_invulnerable(true)
		player:base():_unregister()
		player:base():set_slot(player, 0)
	end
end
function ConnectionNetworkHandler:ok_to_load_level(sender)
	print("ConnectionNetworkHandler:ok_to_load_level")
	if not self:_verify_in_client_session() then
		return
	end
	managers.network:session():ok_to_load_level()
end
function ConnectionNetworkHandler:set_peer_left(peer_id, sender)
	if not self._verify_sender(sender) then
		return
	end
	local peer = managers.network:session():peer(peer_id)
	if not peer then
		print("[ConnectionNetworkHandler:set_peer_left] unknown peer", peer_id)
		return
	end
	managers.network:session():on_peer_left(peer, peer_id)
end
function ConnectionNetworkHandler:enter_ingame_lobby_menu(sender)
	if not self._verify_sender(sender) then
		return
	end
	game_state_machine:change_state_by_name("ingame_lobby_menu")
end
function ConnectionNetworkHandler:entered_lobby_confirmation(peer_id)
	managers.network:session():on_entered_lobby_confirmation(peer_id)
end
function ConnectionNetworkHandler:set_peer_entered_lobby(sender)
	if not self._verify_in_session() then
		return
	end
	local peer = self._verify_sender(sender)
	if not peer then
		return
	end
	managers.network:game():on_peer_entered_lobby(peer:id())
end
function ConnectionNetworkHandler:lobby_sync_update_level_id(level_id_index)
	local level_id = tweak_data.levels:get_level_name_from_index(level_id_index)
	local lobby_menu = managers.menu:get_menu("lobby_menu")
	if lobby_menu and lobby_menu.renderer:is_open() then
		lobby_menu.renderer:sync_update_level_id(level_id)
	end
	local kit_menu = managers.menu:get_menu("kit_menu")
	if kit_menu and kit_menu.renderer:is_open() then
		kit_menu.renderer:sync_update_level_id(level_id)
	end
end
function ConnectionNetworkHandler:lobby_sync_update_difficulty(difficulty)
	local lobby_menu = managers.menu:get_menu("lobby_menu")
	if lobby_menu and lobby_menu.renderer:is_open() then
		lobby_menu.renderer:sync_update_difficulty(difficulty)
	end
	local kit_menu = managers.menu:get_menu("kit_menu")
	if kit_menu and kit_menu.renderer:is_open() then
		kit_menu.renderer:sync_update_difficulty(difficulty)
	end
end
function ConnectionNetworkHandler:lobby_info(peer_id, level, character, mask_set, ass_progress, sha_progress, sup_progress, tech_progress, sender)
	print("ConnectionNetworkHandler:lobby_info", peer_id, level)
	local peer = self._verify_sender(sender)
	print("  IS THIS AN OK PEER?", peer and peer:id())
	if peer then
		peer:set_level(level)
		local progress = {
			ass_progress,
			sha_progress,
			sup_progress
		}
		if tech_progress ~= -1 then
			table.insert(progress, tech_progress)
		end
		peer:set_mask_set(mask_set)
		local lobby_menu = managers.menu:get_menu("lobby_menu")
		if lobby_menu and lobby_menu.renderer:is_open() then
			lobby_menu.renderer:_set_player_slot(peer_id, {
				name = peer:name(),
				peer_id = peer_id,
				level = level,
				character = character,
				progress = progress
			})
		end
		local kit_menu = managers.menu:get_menu("kit_menu")
		if kit_menu and kit_menu.renderer:is_open() then
			kit_menu.renderer:_set_player_slot(peer_id, {
				name = peer:name(),
				peer_id = peer_id,
				level = level,
				character = character,
				progress = progress
			})
		end
	end
end
function ConnectionNetworkHandler:sync_chat_message(message, sender)
	local peer = self._verify_sender(sender)
	if not peer then
		return
	end
	print("sync_chat_message peer", peer, peer:id())
	managers.menu:relay_chat_message(message, peer:id())
end
function ConnectionNetworkHandler:request_character(peer_id, character, sender)
	if not self._verify_sender(sender) then
		return
	end
	managers.network:game():on_peer_request_character(peer_id, character)
end
function ConnectionNetworkHandler:set_mask_set(peer_id, mask_set, sender)
	local peer = self._verify_sender(sender)
	if not peer then
		return
	end
	if not self._verify_gamestate(self._gamestate_filter.lobby) then
		return
	end
	peer:set_mask_set(mask_set)
	local lobby_menu = managers.menu:get_menu("lobby_menu")
	if lobby_menu and lobby_menu.renderer:is_open() then
		lobby_menu.renderer:set_character(peer_id, peer:character())
	end
	local kit_menu = managers.menu:get_menu("kit_menu")
	if kit_menu and kit_menu.renderer:is_open() then
		kit_menu.renderer:set_character(peer_id, peer:character())
	end
end
function ConnectionNetworkHandler:request_character_response(peer_id, character, sender)
	if not self._verify_sender(sender) then
		return
	end
	local peer = managers.network:session():peer(peer_id)
	if not peer then
		return
	end
	peer:set_character(character)
	local lobby_menu = managers.menu:get_menu("lobby_menu")
	if lobby_menu and lobby_menu.renderer:is_open() then
		lobby_menu.renderer:set_character(peer_id, character)
	end
	local kit_menu = managers.menu:get_menu("kit_menu")
	if kit_menu and kit_menu.renderer:is_open() then
		kit_menu.renderer:set_character(peer_id, character)
	end
end
function ConnectionNetworkHandler:client_died(peer_id, sender)
	local peer = self._verify_sender(sender)
	if not peer or peer:id() ~= peer_id then
		return
	end
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) then
		return
	end
	managers.groupai:state():on_player_criminal_death(peer_id)
end
function ConnectionNetworkHandler:begin_trade()
	if not self._verify_gamestate(self._gamestate_filter.waiting_for_respawn) then
		return
	end
	game_state_machine:current_state():begin_trade()
end
function ConnectionNetworkHandler:cancel_trade()
	if not self._verify_gamestate(self._gamestate_filter.waiting_for_respawn) then
		return
	end
	game_state_machine:current_state():cancel_trade()
end
function ConnectionNetworkHandler:finish_trade()
	if not self._verify_gamestate(self._gamestate_filter.waiting_for_respawn) then
		return
	end
	game_state_machine:current_state():finish_trade()
end
function ConnectionNetworkHandler:request_spawn_member(peer_id)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) then
		return
	end
	IngameWaitingForRespawnState.request_player_spawn(peer_id)
end
function ConnectionNetworkHandler:hostage_trade_dialog(i)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) then
		return
	end
	managers.trade:sync_hostage_trade_dialog(i)
end
function ConnectionNetworkHandler:warn_about_civilian_free(i)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) then
		return
	end
	managers.groupai:state():sync_warn_about_civilian_free(i)
end
function ConnectionNetworkHandler:keep_alive(sender)
	if not self._verify_in_session() then
		print("[ConnectionNetworkHandler:keep_alive] no session")
		sender:sanity_check_network_status_reply()
		return
	end
	local sender_peer = self._verify_sender(sender)
	if not sender_peer then
		print("[ConnectionNetworkHandler:keep_alive] no peer")
		sender:sanity_check_network_status_reply()
		return
	end
end
function ConnectionNetworkHandler:keep_alive_tcpip(user_id, sender)
	if not self._verify_in_session() then
		print("[ConnectionNetworkHandler:keep_alive_tcpip] no session")
		sender:sanity_check_network_status_reply()
		return
	end
	local sender_peer = managers.network:session():peer_by_user_id(user_id)
	if not sender_peer then
		print("[ConnectionNetworkHandler:keep_alive_tcpip] no peer", user_id)
		sender:sanity_check_network_status_reply()
		return
	end
end
function ConnectionNetworkHandler:request_drop_in_pause(peer_id, nickname, state, sender)
	managers.network:game():on_drop_in_pause_request_received(peer_id, nickname, state)
end
function ConnectionNetworkHandler:drop_in_pause_confirmation(dropin_peer_id, sender)
	local sender_peer = self._verify_sender(sender)
	if not sender_peer then
		return
	end
	managers.network:session():on_drop_in_pause_confirmation_received(dropin_peer_id, sender_peer)
end
function ConnectionNetworkHandler:report_dead_connection(other_peer_id, sender)
	local sender_peer = self._verify_sender(sender)
	if not sender_peer then
		return
	end
	managers.network:session():on_dead_connection_reported(sender_peer:id(), other_peer_id)
end
function ConnectionNetworkHandler:sanity_check_network_status_reply(sender)
	local session = self._verify_in_session()
	if not session then
		return
	end
	local sender_peer = self._verify_sender(sender)
	if not sender_peer then
		return
	end
	print("[ConnectionNetworkHandler:sanity_check_network_status_reply]")
	session:on_peer_lost(sender_peer, sender_peer:id())
end
function ConnectionNetworkHandler:dropin_progress(dropin_peer_id, progress_percentage, sender)
	if not self._verify_in_client_session() or not self._verify_gamestate(self._gamestate_filter.any_ingame) then
		return
	end
	local session = managers.network:session()
	local dropin_peer = session:peer(dropin_peer_id)
	if not dropin_peer or dropin_peer_id == session:local_peer():id() then
		return
	end
	managers.network:game():on_dropin_progress_received(dropin_peer_id, progress_percentage)
end
function ConnectionNetworkHandler:set_member_ready(ready, sender)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) then
		return
	end
	local peer = self._verify_sender(sender)
	if not peer then
		return
	end
	local peer_id = peer:id()
	peer:set_waiting_for_player_ready(ready)
	managers.network:game():on_set_member_ready(peer_id, ready)
	if not Network:is_server() or game_state_machine:current_state().start_game_intro then
	elseif ready then
		managers.network:session():chk_spawn_member_unit(peer, peer_id)
	end
	if ready then
		managers.hud:wfp_member_ready(peer_id)
	else
		managers.hud:wfp_member_is_not_ready(peer_id)
	end
end
function ConnectionNetworkHandler:re_open_lobby_request(state, sender)
	local peer = self._verify_sender(sender)
	if not peer then
		sender:re_open_lobby_reply(false)
		return
	end
	local session = managers.network:session()
	if session:closing() then
		sender:re_open_lobby_reply(false)
		return
	end
	session:on_re_open_lobby_request(peer, state)
end
function ConnectionNetworkHandler:re_open_lobby_reply(status, sender)
	local peer = self._verify_sender(sender)
	if not peer then
		return
	end
	local session = managers.network:session()
	if session:closing() then
		return
	end
	managers.network.matchmake:from_host_lobby_re_opened(status)
end
function ConnectionNetworkHandler:ask_IP(keep_alive_wanted, sender)
end
function ConnectionNetworkHandler:ask_IP_reply(my_ip, sender)
	local session = managers.network:session()
	if not session or session:closing() then
		return
	end
	session:on_ask_IP_reply(my_ip, sender)
end
function ConnectionNetworkHandler:NAT_keep_alive(sender)
	local session = managers.network:session()
	if not session or session:closing() then
		return
	end
	session:on_from_server_NAT_keep_alive(sender)
end
function ConnectionNetworkHandler:from_client_close_connection(sender)
end
function ConnectionNetworkHandler:match_stat_p2p_con_established(code)
end
function ConnectionNetworkHandler:match_stat_p2p_con_lost(code)
end
