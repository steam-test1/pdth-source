NetworkMatchMakingSTEAM = NetworkMatchMakingSTEAM or class()
NetworkMatchMakingSTEAM.OPEN_SLOTS = 4
NetworkMatchMakingSTEAM._BUILD_SEARCH_INTEREST_KEY = "1.21.0"
function NetworkMatchMakingSTEAM:init()
	cat_print("lobby", "matchmake = NetworkMatchMakingSTEAM")
	self._callback_map = {}
	self._distance_filter = -1
	self._difficulty_filter = 0
	self._try_re_enter_lobby = nil
end
function NetworkMatchMakingSTEAM:register_callback(event, callback)
	self._callback_map[event] = callback
end
function NetworkMatchMakingSTEAM:_call_callback(name, ...)
	if self._callback_map[name] then
		return self._callback_map[name](...)
	else
		Application:error("Callback " .. name .. " not found.")
	end
end
function NetworkMatchMakingSTEAM:_has_callback(name)
	if self._callback_map[name] then
		return true
	end
	return false
end
function NetworkMatchMakingSTEAM:destroy_game()
	self:leave_game()
end
function NetworkMatchMakingSTEAM:_load_globals()
	if Global.steam and Global.steam.match then
		self.lobby_handler = Global.steam.match.lobby_handler
		self._lobby_attributes = Global.steam.match.lobby_attributes
		if self.lobby_handler then
			self.lobby_handler:setup_callbacks(NetworkMatchMakingSTEAM._on_memberstatus_change, NetworkMatchMakingSTEAM._on_data_update, NetworkMatchMakingSTEAM._on_chat_message)
		end
		self._try_re_enter_lobby = Global.steam.match.try_re_enter_lobby
		self._server_rpc = Global.steam.match.server_rpc
		Global.steam.match = nil
	end
end
function NetworkMatchMakingSTEAM:_save_globals()
	if not Global.steam then
		Global.steam = {}
	end
	Global.steam.match = {}
	Global.steam.match.lobby_handler = self.lobby_handler
	Global.steam.match.lobby_attributes = self._lobby_attributes
	Global.steam.match.try_re_enter_lobby = self._try_re_enter_lobby
	Global.steam.match.server_rpc = self._server_rpc
end
function NetworkMatchMakingSTEAM:update()
	Steam:update()
	if self._try_re_enter_lobby then
		if self._try_re_enter_lobby == "lost" then
			Application:error("REQUESTING RE-OPEN LOBBY")
			self._server_rpc:re_open_lobby_request(true)
			self._try_re_enter_lobby = "asked"
		elseif self._try_re_enter_lobby == "asked" then
		else
			if self._try_re_enter_lobby == "open" then
				self._try_re_enter_lobby = "joining"
				Application:error("RE-ENTERING LOBBY", self.lobby_handler:id())
				local function _join_lobby_result_f(result, handler)
					if result == "success" then
						Application:error("SUCCESS!")
						self.lobby_handler = handler
					else
						Application:error("FAIL!")
					end
					self._server_rpc:re_open_lobby_request(false)
					self._try_re_enter_lobby = nil
				end
				Steam:join_lobby(self.lobby_handler:id(), _join_lobby_result_f)
			else
			end
		end
	end
end
function NetworkMatchMakingSTEAM:leave_game()
	self._server_rpc = nil
	if self.lobby_handler then
		self.lobby_handler:leave_lobby()
	end
	self.lobby_handler = nil
	if self._try_re_enter_lobby then
		self._try_re_enter_lobby = nil
	end
	print("NetworkMatchMakingSTEAM:leave_game()")
end
function NetworkMatchMakingSTEAM:get_friends_lobbies()
	local lobbies = {}
	local num_updated_lobbies = 0
	local empty = function()
	end
	local function f(updated_lobby)
		updated_lobby:setup_callback(empty)
		print("NetworkMatchMakingSTEAM:get_friends_lobbies f")
		num_updated_lobbies = num_updated_lobbies + 1
		if num_updated_lobbies >= #lobbies then
			local info = {
				room_list = {},
				attribute_list = {}
			}
			for _, lobby in ipairs(lobbies) do
				print("Found lobby ", lobby:id(), lobby:key_value("owner_name"), lobby:key_value("owner_id"), lobby:member_limit(), lobby:num_members())
				if NetworkMatchMakingSTEAM._BUILD_SEARCH_INTEREST_KEY then
					local ikey = lobby:key_value(NetworkMatchMakingSTEAM._BUILD_SEARCH_INTEREST_KEY)
					if ikey ~= "value_missing" and ikey ~= "value_pending" then
						table.insert(info.room_list, {
							owner_id = lobby:key_value("owner_id"),
							owner_name = lobby:key_value("owner_name"),
							room_id = lobby:id()
						})
						table.insert(info.attribute_list, {
							numbers = self:_lobby_to_numbers(lobby)
						})
					end
				end
			end
			self:_call_callback("search_lobby", info)
		end
	end
	if Steam:friends() then
		for _, friend in ipairs(Steam:friends()) do
			local lobby = friend:lobby()
			if lobby then
				table.insert(lobbies, lobby)
			end
		end
	end
	if #lobbies == 0 then
		local info = {
			room_list = {},
			attribute_list = {}
		}
		self:_call_callback("search_lobby", info)
	else
		for _, lobby in ipairs(lobbies) do
			lobby:setup_callback(f)
			if lobby:key_value("state") == "value_pending" then
				print("NetworkMatchMakingSTEAM:get_friends_lobbies value_pending")
				lobby:request_data()
			else
				f(lobby)
			end
		end
	end
end
function NetworkMatchMakingSTEAM:search_friends_only()
	return self._search_friends_only
end
function NetworkMatchMakingSTEAM:distance_filter()
	return self._distance_filter
end
function NetworkMatchMakingSTEAM:set_distance_filter(filter)
	self._distance_filter = filter
end
function NetworkMatchMakingSTEAM:difficulty_filter()
	return self._difficulty_filter
end
function NetworkMatchMakingSTEAM:set_difficulty_filter(filter)
	self._difficulty_filter = filter
end
function NetworkMatchMakingSTEAM:search_lobby(friends_only)
	self._search_friends_only = friends_only
	if not self:_has_callback("search_lobby") then
		return
	end
	managers.menu:show_retrieving_servers_dialog()
	if friends_only then
		self:get_friends_lobbies()
	else
		local function refresh_lobby()
			local lobbies = self.browser:lobbies()
			local info = {
				room_list = {},
				attribute_list = {}
			}
			print("on_match")
			if lobbies then
				print(inspect(lobbies))
				for _, lobby in ipairs(lobbies) do
					if self._difficulty_filter == 0 or self._difficulty_filter == tonumber(lobby:key_value("difficulty")) then
						print("Found lobby ", lobby:id(), lobby:key_value("owner_name"), lobby:key_value("owner_id"), lobby:member_limit(), lobby:num_members())
						table.insert(info.room_list, {
							owner_id = lobby:key_value("owner_id"),
							owner_name = lobby:key_value("owner_name"),
							room_id = lobby:id()
						})
						table.insert(info.attribute_list, {
							numbers = self:_lobby_to_numbers(lobby)
						})
					end
				end
			end
			self:_call_callback("search_lobby", info)
		end
		self.browser = LobbyBrowser(refresh_lobby, refresh_lobby)
		local interest_keys = {
			"owner_id",
			"owner_name",
			"level",
			"difficulty",
			"permission",
			"state",
			"num_players",
			"drop_in",
			"min_level"
		}
		if self._BUILD_SEARCH_INTEREST_KEY then
			table.insert(interest_keys, self._BUILD_SEARCH_INTEREST_KEY)
		end
		self.browser:set_interest_keys(interest_keys)
		self.browser:set_distance_filter(self._distance_filter)
		if Global.game_settings.playing_lan then
			self.browser:refresh_lan()
		else
			self.browser:refresh()
		end
	end
end
function NetworkMatchMakingSTEAM:search_lobby_done()
	managers.system_menu:close("find_server")
	self.browser = nil
end
function NetworkMatchMakingSTEAM:game_owner_name()
	return managers.network.matchmake.lobby_handler:get_lobby_data("owner_name")
end
function NetworkMatchMakingSTEAM:is_server_ok(friends_only, room, attributes_numbers)
	local permission = tweak_data:index_to_permission(attributes_numbers[3])
	print("MenuSTEAMHostBrowser:_is_server_ok ", attributes_numbers[3], permission)
	if (not NetworkManager.DROPIN_ENABLED or attributes_numbers[6] == 0) and attributes_numbers[4] ~= 1 then
		return false, 1
	end
	if managers.experience:current_level() < attributes_numbers[7] then
		return false, 3
	end
	if permission == "private" then
		return false, 2
	end
	if permission == "public" then
		return true
	end
	return true
end
function NetworkMatchMakingSTEAM:join_server_with_check(room_id)
	managers.menu:show_joining_lobby_dialog()
	local lobby = Steam:lobby(room_id)
	local empty = function()
	end
	local function f()
		print("[NetworkMatchMakingSTEAM:join_server_with_check f]")
		lobby:setup_callback(empty)
		local attributes = self:_lobby_to_numbers(lobby)
		if NetworkMatchMakingSTEAM._BUILD_SEARCH_INTEREST_KEY then
			local ikey = lobby:key_value(NetworkMatchMakingSTEAM._BUILD_SEARCH_INTEREST_KEY)
			if ikey == "value_missing" or ikey == "value_pending" then
				print("Wrong version!!")
				managers.system_menu:close("join_server")
				managers.menu:show_failed_joining_dialog()
				return
			end
		end
		local owner_ip = lobby:key_value("owner_ip")
		print("owner_ip", owner_ip)
		if owner_ip == "" or owner_ip == "value_missing" or owner_ip == "value_pending" then
			owner_ip = nil
		end
		print(inspect(attributes))
		local server_ok, ok_error = self:is_server_ok(nil, room_id, attributes)
		if server_ok then
			self:join_server(room_id, true, owner_ip)
		else
			managers.system_menu:close("join_server")
			if ok_error == 1 then
				managers.menu:show_game_started_dialog()
			elseif ok_error == 2 then
				managers.menu:show_game_permission_changed_dialog()
			elseif ok_error == 3 then
				managers.menu:show_too_low_level()
			elseif ok_error == 4 then
				managers.menu:show_does_not_own_heist()
			end
			self:search_lobby(self:search_friends_only())
		end
	end
	lobby:setup_callback(f)
	if lobby:key_value("state") == "value_pending" then
		print("NetworkMatchMakingSTEAM:join_server_with_check value_pending")
		lobby:request_data()
	else
		f()
	end
end
function NetworkMatchMakingSTEAM._on_member_left(steam_id, status)
	if not managers.network:session() then
		return
	end
	local peer = managers.network:session():peer_by_user_id(steam_id)
	if not peer then
		return
	end
	if peer == managers.network:session():local_peer() and not managers.network:session():closing() and not managers.network:session():is_host() then
		Application:error("OMG I LEFT THE LOBBY")
		managers.network.matchmake._try_re_enter_lobby = "lost"
	end
	managers.network:session():on_peer_left_lobby(peer)
end
function NetworkMatchMakingSTEAM._on_memberstatus_change(memberstatus)
	print("[NetworkMatchMakingSTEAM._on_memberstatus_change]", memberstatus)
	local user, status = unpack(string.split(memberstatus, ":"))
	if status == "lost_steam_connection" or status == "left_become_owner" or status == "left" or status == "kicked" or status == "banned" or status == "invalid" then
		NetworkMatchMakingSTEAM._on_member_left(user, status)
	end
end
function NetworkMatchMakingSTEAM._on_data_update(...)
	print("[NetworkMatchMakingSTEAM._on_data_update]", ...)
end
function NetworkMatchMakingSTEAM._on_chat_message(...)
	print("[NetworkMatchMakingSTEAM._on_chat_message]", ...)
end
function NetworkMatchMakingSTEAM:join_server(room_id, skip_showing_dialog, owner_ip)
	if not skip_showing_dialog then
		managers.menu:show_joining_lobby_dialog()
	end
	local function f(result, handler)
		print("[NetworkMatchMakingSTEAM:join_server:f]", result, handler)
		managers.system_menu:close("join_server")
		if result == "success" then
			print("Success!")
			self.lobby_handler = handler
			local _, host_id, owner = self.lobby_handler:get_server_details()
			print("[NetworkMatchMakingSTEAM:join_server] server details", _, host_id)
			print("Gonna handshake now!")
			self._server_rpc = Network:handshake(host_id:tostring(), nil, "STEAM")
			if owner_ip and managers.network:protocol_type() == "TCP_IP" then
				self._server_rpc:add(Network:handshake(owner_ip, nil, "TCP_IP"))
			end
			print("Handshook!")
			print("Server RPC:", self._server_rpc and self._server_rpc:ip_at_index(0))
			if not self._server_rpc then
				return
			end
			self.lobby_handler:setup_callbacks(NetworkMatchMakingSTEAM._on_memberstatus_change, NetworkMatchMakingSTEAM._on_data_update, NetworkMatchMakingSTEAM._on_chat_message)
			local cancel_f = function()
				if managers.network:session() then
					managers.network:session():on_join_request_cancelled()
				end
			end
			managers.menu:show_waiting_for_server_response({cancel_func = cancel_f})
			local joined_game = function(res, level_index, difficulty_index, state_index)
				managers.system_menu:close("waiting_for_server_response")
				print("[NetworkMatchMakingSTEAM:join_server:joined_game]", res, level_index, difficulty_index, state_index)
				if res == "JOINED_LOBBY" then
					managers.menu:close_menu("menu_main")
					managers.menu:open_menu("lobby_menu")
					managers.network:session():send_to_peers_loaded("set_peer_entered_lobby")
				elseif res == "JOINED_GAME" then
					local level_id = tweak_data.levels:get_level_name_from_index(level_index)
					Global.game_settings.level_id = level_id
					managers.network:session():ok_to_load_level()
				elseif res == "KICKED" then
					managers.network.matchmake:leave_game()
					managers.network.voice_chat:destroy_voice()
					managers.network:queue_stop_network()
					managers.menu:show_peer_kicked_dialog()
				elseif res == "TIMED_OUT" then
					managers.network.matchmake:leave_game()
					managers.network.voice_chat:destroy_voice()
					managers.network:queue_stop_network()
					managers.menu:show_request_timed_out_dialog()
				elseif res == "GAME_STARTED" then
					managers.network.matchmake:leave_game()
					managers.network.voice_chat:destroy_voice()
					managers.network:queue_stop_network()
					managers.menu:show_game_started_dialog()
				elseif res == "DO_NOT_OWN_HEIST" then
					managers.network.matchmake:leave_game()
					managers.network.voice_chat:destroy_voice()
					managers.network:queue_stop_network()
					managers.menu:show_does_not_own_heist()
				elseif res == "CANCELLED" then
					managers.network.matchmake:leave_game()
					managers.network.voice_chat:destroy_voice()
					managers.network:queue_stop_network()
				elseif res == "FAILED_CONNECT" then
					managers.network.matchmake:leave_game()
					managers.network.voice_chat:destroy_voice()
					managers.network:queue_stop_network()
					managers.menu:show_failed_joining_dialog()
				else
					Application:error("[NetworkMatchMakingSTEAM:join_server] FAILED TO START MULTIPLAYER!", res)
				end
			end
			managers.network:join_game_at_host_rpc(self._server_rpc, joined_game)
		else
			managers.menu:show_failed_joining_dialog()
			self:search_lobby(self:search_friends_only())
		end
	end
	Steam:join_lobby(room_id, f)
end
function NetworkMatchMakingSTEAM:send_join_invite(friend)
end
function NetworkMatchMakingSTEAM:set_server_attributes(settings)
	self:set_attributes(settings)
end
function NetworkMatchMakingSTEAM:create_lobby(settings)
	self._num_players = nil
	local dialog_data = {}
	dialog_data.title = managers.localization:text("dialog_creating_lobby_title")
	dialog_data.text = managers.localization:text("dialog_wait")
	dialog_data.id = "create_lobby"
	dialog_data.no_buttons = true
	managers.system_menu:show(dialog_data)
	local function f(result, handler)
		print("Create lobby callback!!", result, handler)
		if result == "success" then
			self.lobby_handler = handler
			self:set_attributes(settings)
			self.lobby_handler:publish_server_details()
			self.lobby_handler:set_joinable(true)
			self.lobby_handler:setup_callbacks(NetworkMatchMakingSTEAM._on_memberstatus_change, NetworkMatchMakingSTEAM._on_data_update, NetworkMatchMakingSTEAM._on_chat_message)
			managers.system_menu:close("create_lobby")
			managers.menu:created_lobby()
		else
			managers.system_menu:close("create_lobby")
			local title = managers.localization:text("dialog_error_title")
			local dialog_data = {
				title = title,
				text = managers.localization:text("dialog_err_failed_creating_lobby")
			}
			dialog_data.button_list = {
				{
					text = managers.localization:text("dialog_ok")
				}
			}
			managers.system_menu:show(dialog_data)
		end
	end
	return Steam:create_lobby(f, NetworkMatchMakingSTEAM.OPEN_SLOTS, "invisible")
end
function NetworkMatchMakingSTEAM:set_num_players(num)
	print("NetworkMatchMakingSTEAM:set_num_players", num)
	self._num_players = num
	if self._lobby_attributes then
		self._lobby_attributes.num_players = num
		self.lobby_handler:set_lobby_data(self._lobby_attributes)
	end
end
function NetworkMatchMakingSTEAM:set_server_state(state)
	if self._lobby_attributes then
		local state_id = tweak_data:server_state_to_index(state)
		self._lobby_attributes.state = state_id
		if self.lobby_handler then
			self.lobby_handler:set_lobby_data(self._lobby_attributes)
			if not NetworkManager.DROPIN_ENABLED then
				self.lobby_handler:set_joinable(state == "in_lobby")
			end
		end
	end
end
function NetworkMatchMakingSTEAM:set_server_joinable(state)
	print("[NetworkMatchMakingSTEAM:set_server_joinable]", state)
	if self.lobby_handler then
		self.lobby_handler:set_joinable(state)
	end
end
function NetworkMatchMakingSTEAM:server_state_name()
	return tweak_data:index_to_server_state(self._lobby_attributes.state)
end
function NetworkMatchMakingSTEAM:set_attributes(settings)
	if not self.lobby_handler then
		return
	end
	local permissions = {
		"public",
		"friend",
		"invisible"
	}
	local owner_ip = managers.network:protocol_type() == "TCP_IP" and managers.network:session():get_my_external_IP() or ""
	print("[NetworkMatchMakingSTEAM:set_attributes] owner_ip", owner_ip)
	local lobby_attributes = {
		owner_name = managers.network.account:username_id(),
		owner_id = managers.network.account:player_id(),
		level = settings.numbers[1],
		difficulty = settings.numbers[2],
		permission = settings.numbers[3],
		state = settings.numbers[4] or self._lobby_attributes and self._lobby_attributes.state or 1,
		min_level = settings.numbers[7] or 0,
		num_players = self._num_players or 1,
		drop_in = settings.numbers[6] or 1,
		owner_ip = owner_ip
	}
	if self._BUILD_SEARCH_INTEREST_KEY then
		lobby_attributes[self._BUILD_SEARCH_INTEREST_KEY] = "true"
	end
	self._lobby_attributes = lobby_attributes
	self.lobby_handler:set_lobby_data(lobby_attributes)
	self.lobby_handler:set_lobby_type(permissions[settings.numbers[3]])
end
function NetworkMatchMakingSTEAM:_lobby_to_numbers(lobby)
	return {
		tonumber(lobby:key_value("level")),
		tonumber(lobby:key_value("difficulty")),
		tonumber(lobby:key_value("permission")),
		tonumber(lobby:key_value("state")),
		tonumber(lobby:key_value("num_players")),
		tonumber(lobby:key_value("drop_in")),
		tonumber(lobby:key_value("min_level"))
	}
end
function NetworkMatchMakingSTEAM:from_host_lobby_re_opened(status)
	print("[NetworkMatchMakingSTEAM::from_host_lobby_re_opened]", self._try_re_enter_lobby, status)
	if self._try_re_enter_lobby == "asked" then
		if status then
			self._try_re_enter_lobby = "open"
		else
			self._try_re_enter_lobby = nil
			managers.network.matchmake:leave_game()
		end
	end
end
