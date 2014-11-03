require("lib/network/NetworkMember")
require("lib/network/handlers/UnitNetworkHandler")
NetworkGame = NetworkGame or class()
function NetworkGame:init()
	self._members = {}
	self._spawn_point_beanbag = nil
	self._dropin_pause_info = {}
	self._old_players = {}
end
function NetworkGame:on_network_started()
	managers.network:register_handler("unit", UnitNetworkHandler)
end
function NetworkGame:on_network_stopped()
	for k, v in pairs(self._members) do
		self:on_drop_in_pause_request_received(k, nil, false)
		v:delete()
	end
	if managers.network:session() and managers.network:session():local_peer() then
		self:on_drop_in_pause_request_received(managers.network:session():local_peer():id(), nil, false)
	end
end
function NetworkGame:load(game_data)
	if managers.network:session():is_client() then
		Network:set_client(managers.network:session():server_peer():rpc())
		local is_playing = BaseNetworkHandler._gamestate_filter.any_ingame_playing[game_state_machine:last_queued_state_name()]
		if is_playing then
			Application:set_pause(true)
		end
	end
	if game_data then
		for k, v in pairs(game_data.members) do
			self._members[k] = NetworkMember:new()
			self._members[k]:load(v)
		end
	end
end
function NetworkGame:save()
	Global.network_game = {
		members = {}
	}
	for k, v in pairs(self._members) do
		Global.network_game.members[k] = v:save()
	end
	Global.local_member = nil
end
function NetworkGame:on_server_session_created()
	if Network:multiplayer() then
		Network:set_server()
	end
end
function NetworkGame:on_new_host(host_peer)
	if Network:multiplayer() and Network:is_client() then
		Network:set_client(host_peer:rpc())
	end
end
function NetworkGame:on_entered_lobby()
	local local_peer = managers.network:session():local_peer()
	local id = local_peer:id()
	local my_member = self._members[id] or NetworkMember:new(local_peer)
	self._members[id] = my_member
	Global.local_member = my_member
	local_peer:set_in_lobby(true)
	cat_print("multiplayer_base", "NetworkGame:on_entered_lobby", local_peer, id)
end
function NetworkGame:on_peer_entered_lobby(peer_id)
	cat_print("multiplayer_base", "[NetworkGame:on_peer_entered_lobby]", peer_id)
	local peer = managers.network:session():peer(peer_id)
	peer:set_in_lobby(true)
	if peer:ip_verified() then
		Global.local_member:sync_lobby_data(peer)
	end
end
function NetworkGame:on_load_complete()
	local local_peer = managers.network:session():local_peer()
	local_peer:set_synched(true)
	local id = local_peer:id()
	local my_member = NetworkMember:new(local_peer)
	self._members[id] = my_member
	Global.local_member = my_member
	cat_print("multiplayer_base", "[NetworkGame:on_load_complete]", local_peer, id)
	if managers.hud then
		for _, peer in pairs(managers.network:session():peers()) do
			local peer_id = peer:id()
			managers.hud:wfp_add_member(peer_id)
		end
	end
	if SystemInfo:platform() == Idstring("PS3") then
		PSN:set_online_callback(callback(self, self, "ps3_disconnect"))
	end
end
function NetworkGame:psn_disconnected()
	if Global.game_settings.single_player then
		return
	end
	if game_state_machine:current_state().on_disconnected then
		game_state_machine:current_state():on_disconnected()
	end
	managers.network.voice_chat:destroy_voice(true)
end
function NetworkGame:steam_disconnected()
	if Global.game_settings.single_player then
		return
	end
	if game_state_machine:current_state().on_disconnected then
		game_state_machine:current_state():on_disconnected()
	end
	managers.network.voice_chat:destroy_voice(true)
end
function NetworkGame:ps3_disconnect(connected)
	print("NetworkGame ps3_disconnect", connected)
	if Global.game_settings.single_player then
		return
	end
	if not connected and not PSN:is_online() then
		if game_state_machine:current_state().on_disconnected then
			game_state_machine:current_state():on_disconnected()
		end
		managers.network.voice_chat:destroy_voice(true)
	end
end
function NetworkGame:on_peer_added(peer, peer_id)
	cat_print("multiplayer_base", "NetworkGame:on_peer_added", peer, peer_id)
	self._members[peer_id] = NetworkMember:new(peer)
	if managers.hud then
		managers.hud:wfp_add_member(peer_id)
		managers.menu:get_menu("kit_menu").renderer:set_slot_joining(peer, peer_id)
	end
	if Network:is_server() then
		managers.network.matchmake:set_num_players(table.size(self._members))
	end
end
function NetworkGame:on_peer_request_character(peer_id, character)
	if Global.game_settings.single_player then
		local peer = managers.network:session():peer(peer_id)
		peer:set_character(character)
		local lobby_menu = managers.menu:get_menu("lobby_menu")
		if lobby_menu and lobby_menu.renderer:is_open() then
			lobby_menu.renderer:set_character(peer_id, character)
		end
		local kit_menu = managers.menu:get_menu("kit_menu")
		if kit_menu and kit_menu.renderer:is_open() then
			kit_menu.renderer:set_character(peer_id, character)
		end
		return
	end
	if not managers.network:session():local_peer():in_lobby() then
	end
	if character ~= "random" then
		for pid, member in pairs(self._members) do
			if member:peer():character() == character then
				print("Deny", peer_id, "cause peer", member:peer():id(), "has character", character)
				return
			end
		end
	end
	print("[NetworkGame:on_peer_request_character] peer", peer_id, "character", character)
	managers.network:session():peer(peer_id):set_character(character)
	local lobby_menu = managers.menu:get_menu("lobby_menu")
	if lobby_menu and lobby_menu.renderer:is_open() then
		lobby_menu.renderer:set_character(peer_id, character)
	end
	local kit_menu = managers.menu:get_menu("kit_menu")
	if kit_menu and kit_menu.renderer:is_open() then
		kit_menu.renderer:set_character(peer_id, character)
	end
	managers.network:session():send_to_peers("request_character_response", peer_id, character)
end
function NetworkGame:on_peer_sync_complete(peer, peer_id)
	cat_print("multiplayer_base", "[NetworkGame:on_peer_sync_complete]", peer_id)
	if not Global.local_member then
		return
	end
	if not peer:ip_verified() then
		return
	end
	if managers.hud then
		managers.hud:wfp_member_is_not_ready(peer_id)
	end
	local local_peer = managers.network:session():local_peer()
	local local_peer_id = local_peer:id()
	if peer:ip_verified() then
		Global.local_member:sync_lobby_data(peer)
		Global.local_member:sync_data(peer)
	end
	local kit_menu = managers.menu:get_menu("kit_menu")
	if kit_menu and kit_menu.renderer:is_open() then
		if peer:waiting_for_player_ready() then
			kit_menu.renderer:set_slot_ready(peer, peer_id)
		else
			kit_menu.renderer:set_slot_not_ready(peer, peer_id)
		end
	end
	if Network:is_server() then
		self:check_start_game_intro()
	end
end
function NetworkGame:on_set_member_ready(peer_id, ready)
	print("[NetworkGame:on_set_member_ready]", peer_id, ready)
	local peer = managers.network:session():peer(peer_id)
	local kit_menu = managers.menu:get_menu("kit_menu")
	if kit_menu and kit_menu.renderer:is_open() then
		if ready then
			kit_menu.renderer:set_slot_ready(peer, peer_id)
		else
			kit_menu.renderer:set_slot_not_ready(peer, peer_id)
		end
	end
	if Network:is_server() then
		self:check_start_game_intro()
	end
end
function NetworkGame:check_start_game_intro()
	if not managers.network:session():chk_all_handshakes_complete() then
		print("[NetworkGame:check_start_game_intro] handshakes incomplete")
		return
	end
	for _, member in pairs(self._members) do
		if not member:peer():waiting_for_player_ready() then
			print("[NetworkGame:check_start_game_intro] ", member:peer():id(), "not ready")
			return
		end
		if not member:peer():synched() then
			print("[NetworkGame:check_start_game_intro] ", member:peer():id(), "not synched")
			return
		end
	end
	if not managers.network:session():chk_send_ready_to_unpause() then
		print("[NetworkGame:check_start_game_intro] not ready to unpause")
		return
	end
	if game_state_machine:current_state().start_game_intro then
		game_state_machine:current_state():start_game_intro()
	end
end
function NetworkGame:on_statistics_recieved(peer_id, peer_kills, peer_specials_kills, peer_head_shots, accuracy, downs)
	local peer = managers.network:session():peer(peer_id)
	peer:set_statistics(peer_kills, peer_specials_kills, peer_head_shots, accuracy, downs)
	for _, member in pairs(self._members) do
		if member:peer():has_statistics() then
		elseif member:peer():waiting_for_player_ready() and not member:peer():has_statistics() then
			return
		end
	end
	print("decide the stats")
	local total_kills = 0
	local total_specials_kills = 0
	local total_head_shots = 0
	local best_killer = {peer_id = nil, score = 0}
	local best_special_killer = {peer_id = nil, score = 0}
	local best_accuracy = {peer_id = nil, score = 0}
	local group_accuracy = 0
	local group_downs = 0
	local most_downs = {peer_id = nil, score = 0}
	for _, member in pairs(self._members) do
		if member:peer():has_statistics() then
			local stats = member:peer():statistics()
			total_kills = total_kills + stats.total_kills
			total_specials_kills = total_specials_kills + stats.total_specials_kills
			total_head_shots = total_head_shots + stats.total_head_shots
			group_accuracy = group_accuracy + stats.accuracy
			group_downs = group_downs + stats.downs
			if stats.total_kills > best_killer.score or not best_killer.peer_id then
				best_killer.score = stats.total_kills
				best_killer.peer_id = member:peer():id()
			end
			if stats.total_specials_kills > best_special_killer.score or not best_special_killer.peer_id then
				best_special_killer.score = stats.total_specials_kills
				best_special_killer.peer_id = member:peer():id()
			end
			if stats.accuracy > best_accuracy.score or not best_accuracy.peer_id then
				best_accuracy.score = stats.accuracy
				best_accuracy.peer_id = member:peer():id()
			end
			if stats.downs > most_downs.score or not most_downs.peer_id then
				most_downs.score = stats.downs
				most_downs.peer_id = member:peer():id()
			end
		end
	end
	group_accuracy = math.floor(group_accuracy / table.size(self._members))
	print("result is", "total_kills", total_kills, "total_specials_kills", total_specials_kills, "total_head_shots", total_head_shots)
	print(inspect(best_killer))
	print(inspect(best_special_killer))
	print(inspect(best_accuracy.peer_id))
	if game_state_machine:current_state().on_statistics_result then
		game_state_machine:current_state():on_statistics_result(best_killer.peer_id, best_killer.score, best_special_killer.peer_id, best_special_killer.score, best_accuracy.peer_id, best_accuracy.score, most_downs.peer_id, most_downs.score, total_kills, total_specials_kills, total_head_shots, group_accuracy, group_downs)
	end
	managers.network:session():send_to_peers("sync_statistics_result", best_killer.peer_id, best_killer.score, best_special_killer.peer_id, best_special_killer.score, best_accuracy.peer_id, best_accuracy.score, most_downs.peer_id, most_downs.score, total_kills, total_specials_kills, total_head_shots, group_accuracy, group_downs)
end
function NetworkGame:on_peer_removed(peer, peer_id, reason)
	if self._members[peer_id] then
		if managers.hud then
			managers.hud:wfp_remove_member(peer_id)
		end
		if managers.player then
			managers.player:peer_dropped_out(peer)
		end
		local lobby_menu = managers.menu:get_menu("lobby_menu")
		if lobby_menu and lobby_menu.renderer:is_open() then
			lobby_menu.renderer:remove_player_slot_by_peer_id(peer, reason)
		end
		local kit_menu = managers.menu:get_menu("kit_menu")
		if kit_menu and kit_menu.renderer:is_open() then
			kit_menu.renderer:remove_player_slot_by_peer_id(peer, reason)
		end
		print("Someone left", peer:name(), peer_id)
		local player_left = false
		local player_character
		if managers.criminals then
			player_character = managers.criminals:character_name_by_peer_id(peer_id)
			if player_character then
				player_left = true
				print("Player left")
			end
		end
		local member_unit = self._members[peer_id]:unit()
		local member_downed = alive(member_unit) and member_unit:movement():downed()
		local member_health = 1
		local member_dead = managers.trade and managers.trade:is_peer_in_custody(peer_id)
		if player_left then
			local mugshot_id = managers.criminals:character_data_by_peer_id(peer_id).mugshot_id
			local mugshot_data = managers.hud:_get_mugshot_data(mugshot_id)
			member_health = mugshot_data and mugshot_data.health_amount or 1
		end
		local member_used_deployable = peer:used_deployable() or false
		self._members[peer_id]:delete()
		self._members[peer_id] = nil
		local peer_ident = SystemInfo:platform() == Idstring("WIN32") and peer:user_id() or peer:name()
		if Network:is_server() then
			self:check_start_game_intro()
		end
		if Network:multiplayer() then
			if Network:is_client() then
				if player_left then
					managers.criminals:remove_character_by_peer_id(peer_id)
					managers.trade:replace_player_with_ai(player_character, player_character)
				end
			elseif Network:is_server() then
				managers.network.matchmake:set_num_players(table.size(self._members))
				Network:remove_client(peer:rpc())
				if player_left then
					managers.achievment:set_script_data("cant_touch_fail", true)
					managers.criminals:remove_character_by_peer_id(peer_id)
					local unit = managers.groupai:state():spawn_one_teamAI(true, player_character)
					self._old_players[peer_ident] = {
						t = Application:time(),
						member_downed = member_downed,
						health = member_health,
						used_deployable = member_used_deployable,
						member_dead = member_dead
					}
					local trade_entry = managers.trade:replace_player_with_ai(player_character, player_character)
					if unit then
						if trade_entry then
							unit:brain():set_active(false)
							unit:base():set_slot(unit, 0)
							unit:base():unregister()
						elseif member_downed then
							unit:character_damage():force_bleedout()
						end
					end
				end
				local deployed_equipment = World:find_units_quick("all", 14, 25, 26)
				for _, equipment in ipairs(deployed_equipment) do
					if equipment:base().server_information then
						local server_information = equipment:base():server_information()
						if server_information and server_information.owner_peer_id == peer_id then
							equipment:set_slot(0)
						end
					end
				end
			else
				print("Tried to remove client when neither server or client")
				Application:stack_dump()
			end
		end
	end
end
function NetworkGame:_has_client(peer)
	for i = 0, Network:clients():num_peers() - 1 do
		if Network:clients():ip_at_index(i) == peer:ip() then
			return true
		end
	end
	return false
end
function NetworkGame:on_peer_loading(peer, state)
	cat_print("multiplayer_base", "[NetworkGame:on_peer_loading]", inspect(peer), state)
	if Network:is_server() and not state then
		if not self:_has_client(peer) then
			Network:add_client(peer:rpc())
		end
		if not NetworkManager.DROPIN_ENABLED then
			peer:on_sync_start()
			peer:chk_enable_queue()
			Network:drop_in(peer:rpc())
		end
	end
	if state and peer == managers.network:session():server_peer() then
		cat_print("multiplayer_base", "  SERVER STARTED LOADING", peer, peer:id())
		if managers.network:session():local_peer():in_lobby() then
			managers.menu:get_menu("lobby_menu").renderer:set_server_state("loading")
		end
	end
end
function NetworkGame:spawn_players(is_drop_in)
	if not managers.network:has_spawn_points() then
		return
	end
	if not self._spawn_point_beanbag then
		self:_create_spawn_point_beanbag()
	end
	if Network:is_server() then
		if not Global.local_member then
			return
		end
		local id = self:_get_next_spawn_point_id()
		Application:stack_dump()
		for peer_id, member in pairs(self._members) do
			local character = member:peer()._character
			if member ~= Global.local_member and character ~= "random" then
				member:spawn_unit(self:_get_next_spawn_point_id(), is_drop_in, character)
			end
		end
		local local_character = Global.local_member:peer()._character
		Global.local_member:spawn_unit(id, false, local_character ~= "random" and local_character or nil)
		for peer_id, member in pairs(self._members) do
			local character = member:peer()._character
			if member ~= Global.local_member and character == "random" then
				member:spawn_unit(self:_get_next_spawn_point_id(), is_drop_in)
			end
		end
		managers.network:session():set_game_started(true)
	end
	managers.groupai:state():fill_criminal_team_with_AI(is_drop_in)
end
function NetworkGame:assign_character_name(peer_id)
	if Network:is_server() then
		return self._members[peer_id]:assign_character_name()
	end
end
function NetworkGame:spawn_dropin_player(peer_id)
	if Network:is_server() then
		managers.achievment:set_script_data("cant_touch_fail", true)
		self._members[peer_id]:spawn_unit(0, true)
	end
end
function NetworkGame:member(id)
	return self._members[id]
end
function NetworkGame:all_members()
	return self._members
end
function NetworkGame:amount_of_members()
	return table.size(self._members)
end
function NetworkGame:amount_of_alive_players()
	local i = 0
	for _, member in pairs(self._members) do
		i = i + (alive(member._unit) and 1 or 0)
	end
	return i
end
function NetworkGame:member_peer(peer)
	return self._members[peer:id()]
end
function NetworkGame:member_from_unit(unit)
	local wanted_key = unit:key()
	for _, member in pairs(self._members) do
		local test_unit = member:unit()
		if alive(test_unit) and test_unit:key() == wanted_key then
			return member
		end
	end
end
function NetworkGame:unit_from_peer_id(peer_id)
	for _, member in pairs(self._members) do
		if member:peer():id() == peer_id then
			return member:unit()
		end
	end
end
function NetworkGame:_create_spawn_point_beanbag()
	local spawn_points = managers.network._spawn_points
	local spawn_point_ids = {}
	self._spawn_point_beanbag = {}
	for sp_id, sp_data in pairs(spawn_points) do
		table.insert(spawn_point_ids, sp_id)
	end
	while #spawn_point_ids > 0 do
		local i_id = math.random(#spawn_point_ids)
		local random_id = spawn_point_ids[i_id]
		table.insert(self._spawn_point_beanbag, random_id)
		spawn_point_ids[i_id] = spawn_point_ids[#spawn_point_ids]
		table.remove(spawn_point_ids)
	end
	self._next_i_spawn_point = 1
end
function NetworkGame:_get_next_spawn_point_id()
	local id = self._spawn_point_beanbag[self._next_i_spawn_point]
	if self._next_i_spawn_point == #self._spawn_point_beanbag then
		self._next_i_spawn_point = 1
	else
		self._next_i_spawn_point = self._next_i_spawn_point + 1
	end
	return id
end
function NetworkGame:get_next_spawn_point()
	local id = self:_get_next_spawn_point_id()
	return managers.network:spawn_point(id)
end
function NetworkGame:spawn_member_by_id(peer_id, spawn_point_id, is_drop_in)
	local member = self._members[peer_id]
	if member then
		return member:spawn_unit(spawn_point_id, is_drop_in)
	end
end
function NetworkGame:on_drop_in_pause_request_received(peer_id, nickname, state)
	print("[NetworkGame:on_drop_in_pause_request_received]", peer_id, nickname, state)
	local status_changed = false
	local is_playing = BaseNetworkHandler._gamestate_filter.any_ingame_playing[game_state_machine:last_queued_state_name()]
	if state then
		if not managers.network:session():closing() then
			status_changed = true
			self._dropin_pause_info[peer_id] = nickname
			if is_playing then
				managers.menu:show_person_joining(peer_id, nickname)
			end
		end
	elseif self._dropin_pause_info[peer_id] then
		status_changed = true
		if peer_id == managers.network:session():local_peer():id() then
			self._dropin_pause_info[peer_id] = nil
			managers.menu:close_person_joining(peer_id)
		else
			self._dropin_pause_info[peer_id] = nil
			managers.menu:close_person_joining(peer_id)
		end
	end
	if status_changed then
		if state then
			if not managers.network:session():closing() then
				if table.size(self._dropin_pause_info) == 1 then
					print("DROP-IN PAUSE")
					Application:set_pause(true)
					SoundDevice:set_rtpc("ingame_sound", 0)
				end
				if Network:is_client() then
					managers.network:session():send_to_host("drop_in_pause_confirmation", peer_id)
				end
			end
		elseif not next(self._dropin_pause_info) then
			print("DROP-IN UNPAUSE")
			Application:set_pause(false)
			SoundDevice:set_rtpc("ingame_sound", 1)
		else
			print("MAINTAINING DROP-IN UNPAUSE. # dropping peers:", table.size(self._dropin_pause_info))
		end
	end
end
function NetworkGame:on_dropin_progress_received(dropin_peer_id, progress_percentage)
	local peer = managers.network:session():peer(dropin_peer_id)
	if peer:synched() then
		return
	end
	local dropin_member = self._members[dropin_peer_id]
	local old_drop_in_prog = dropin_member:drop_in_progress()
	if not old_drop_in_prog or progress_percentage > old_drop_in_prog then
		dropin_member:set_drop_in_progress(progress_percentage)
		if game_state_machine:last_queued_state_name() == "ingame_waiting_for_players" then
			managers.menu:get_menu("kit_menu").renderer:set_dropin_progress(dropin_peer_id, progress_percentage)
		else
			managers.menu:update_person_joining(dropin_peer_id, progress_percentage)
		end
	end
end
