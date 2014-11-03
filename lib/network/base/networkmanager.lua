require("lib/network/base/BaseNetworkSession")
require("lib/network/base/ClientNetworkSession")
require("lib/network/base/HostNetworkSession")
require("lib/network/matchmaking/NetworkAccount")
require("lib/network/matchmaking/NetworkAccountPSN")
require("lib/network/matchmaking/NetworkAccountSTEAM")
require("lib/network/matchmaking/NetworkFriend")
require("lib/network/matchmaking/NetworkFriendsPSN")
require("lib/network/matchmaking/NetworkGenericPSN")
require("lib/network/matchmaking/NetworkGroupLobby")
require("lib/network/matchmaking/NetworkGroupLobbyPSN")
require("lib/network/matchmaking/NetworkMatchMakingPSN")
require("lib/network/matchmaking/NetworkMatchMakingSTEAM")
require("lib/network/matchmaking/NetworkVoiceChatDisabled")
require("lib/network/matchmaking/NetworkVoiceChatPSN")
require("lib/network/matchmaking/NetworkVoiceChatSTEAM")
require("lib/network/base/NetworkPeer")
require("lib/network/base/handlers/BaseNetworkHandler")
require("lib/network/base/handlers/DefaultNetworkHandler")
require("lib/network/base/handlers/ConnectionNetworkHandler")
require("lib/network/base/handlers/PacketNetworkHandler")
require("lib/units/beings/player/PlayerDamage")
NetworkManager = NetworkManager or class()
if SystemInfo:platform() == Idstring("X360") then
	NetworkManager.DEFAULT_PORT = 1000
else
	NetworkManager.DEFAULT_PORT = 9899
end
NetworkManager.DROPIN_ENABLED = true
NetworkManager.PROTOCOL_TYPE = "STEAM"
function NetworkManager:init(game_class)
	self.OVERWRITEABLE_MSGS = {
		request_character = {
			clbk = NetworkManager.clbk_msg_overwrite
		},
		set_look_dir = {
			clbk = NetworkManager.clbk_msg_overwrite
		},
		set_kit_selection = {
			clbk = MenuItemKitSlot.clbk_msg_set_kit_selection,
			categories = {}
		},
		set_mask_set = {
			clbk = NetworkManager.clbk_msg_overwrite
		},
		criminal_hurt = {
			clbk = PlayerDamage.clbk_msg_overwrite_criminal_hurt,
			indexes = {}
		}
	}
	if SystemInfo:platform() == Idstring("PS3") then
		self._is_ps3 = true
	else
		self._is_win32 = true
	end
	self._spawn_points = {}
	if self._is_ps3 then
		Network:set_use_psn_network(true)
		if #PSN:get_world_list() == 0 then
			PSN:init_matchmaking()
		end
		self:_register_PSN_matchmaking_callbacks()
	elseif self._is_win32 then
		self.account = NetworkAccountSTEAM:new()
		self.voice_chat = NetworkVoiceChatSTEAM:new()
	end
	self._started = false
	self._game_class = game_class
	managers.network = self
	self:_create_lobby()
	self:load()
end
function NetworkManager:init_finalize()
	print("NetworkManager:init_finalize()")
	if Network:multiplayer() and not Application:editor() then
		self._session:on_load_complete()
		self._game:on_load_complete()
	end
end
function NetworkManager:_create_lobby()
	if self._is_win32 then
		cat_print("lobby", "Online Lobby is PC")
		self.matchmake = NetworkMatchMakingSTEAM:new()
	elseif self._is_ps3 then
		cat_print("lobby", "Online Lobby is PS3")
		self.friends = NetworkFriendsPSN:new()
		self.group = NetworkGroupLobbyPSN:new()
		self.matchmake = NetworkMatchMakingPSN:new()
		self.shared_psn = NetworkGenericPSN:new()
		self.shared = self.shared_psn
		self.account = NetworkAccountPSN:new()
		self.match = nil
		self:ps3_determine_voice()
		self._shared_update = self.shared_psn
	else
		Global._boot_invite_mp = nil
		Application:error("NetworkManager:create_lobby failed to get a valid lobby for online play.")
		return
	end
end
function NetworkManager:ps3_determine_voice(lan)
	local voice = "voice_quiet"
	if lan == true then
		voice = "voice_quiet"
	elseif PSN:is_online() then
		if PSN:online_chat_allowed() then
			voice = "voice_psn"
		else
			voice = "voice_disabled"
		end
	end
	if self.voice_chat and self.voice_chat:voice_type() == voice then
		return
	end
	if self.voice_chat and self.voice_chat:voice_type() ~= voice then
		self.voice_chat:close_all(true)
		self.voice_chat = nil
	end
	if voice == "voice_psn" then
		self.voice_chat = NetworkVoiceChatPSN:new()
	elseif voice == "voice_disabled" then
		self.voice_chat = NetworkVoiceChatDisabled:new()
	else
		self.voice_chat = NetworkVoiceChatDisabled:new(true)
	end
end
function NetworkManager:session()
	return self._session
end
function NetworkManager:game()
	return self._game
end
function NetworkManager:shared_handler_data()
	return self._shared_handler_data
end
function NetworkManager:load()
	if Global.network then
		self._network_bound = Global.network.network_bound
		self:start_network()
		if Global.network.session then
			if Global.network.session_host then
				self._session = HostNetworkSession:new()
				self._game:on_server_session_created()
			else
				self._session = ClientNetworkSession:new()
			end
		end
		self._session:load(Global.network.session)
		self._game:load(Global.network_game)
		managers.network.matchmake:_load_globals()
		managers.network.voice_chat:_load_globals()
		Global.network_game = nil
		Global.network = nil
		if self._is_win32 then
			managers.network.voice_chat:open()
		end
	end
end
function NetworkManager:save()
	if self._started then
		Global.network = {}
		Global.network.network_bound = self._network_bound
		if self._session then
			Global.network.session_host = self._session:is_host()
			Global.network.session = {}
			self._session:save(Global.network.session)
		end
		managers.network.matchmake:_save_globals()
		managers.network.voice_chat:_save_globals(true)
		self._game:save()
		if self._is_win32 then
			managers.network.voice_chat:destroy_voice()
		end
	end
end
function NetworkManager:update(t, dt)
	if self._stop_next_frame then
		self:stop_network(true)
		self._stop_next_frame = nil
		return
	end
	if self._session then
		self._session:update()
	end
	self.matchmake:update()
	self.voice_chat:update(t)
end
function NetworkManager:end_update()
	if self._stop_network then
		self._stop_next_frame = true
		self._stop_network = nil
	end
	if self._session then
		self._session:end_update()
	end
end
function NetworkManager:start_network()
	if not self._started then
		Global.category_print.multiplayer_base = true
		if self._game_class then
			self._game = _G[self._game_class]:new()
		end
		self:register_handler("connection", ConnectionNetworkHandler)
		self:register_handler("packet", PacketNetworkHandler)
		self._game:on_network_started()
		Network:bind(self._network_bound and -1 or self.DEFAULT_PORT, DefaultNetworkHandler:new())
		self._network_bound = true
		self._started = true
		cat_print("multiplayer_base", "[NetworkManager:start_network]")
	end
end
function NetworkManager:register_handler(name, handler_class)
	if not self._handlers then
		self._handlers = {}
		self._shared_handler_data = {}
	end
	local new_handler = handler_class:new()
	self._handlers[name] = new_handler
	Network:set_receiver(Idstring(name), new_handler)
end
function NetworkManager:prepare_stop_network()
	if self._session then
		self._session:prepare_to_close()
		if self.voice_chat and self._is_win32 then
			self.voice_chat:destroy_voice()
		end
	end
end
function NetworkManager:stop_network(clean)
	if self._started then
		self._game:on_network_stopped()
		self._started = false
		if clean and self._session then
			local peers = self._session:peers()
			for k, peer in pairs(peers) do
				local rpc = peer:rpc()
				if rpc then
					Network:reset_connection(rpc)
					Network:remove_client(rpc)
				end
			end
		end
		self._handlers = nil
		self._shared_handler_data = nil
		self._session:destroy()
		self._session = nil
		self._game = nil
		self._stop_network = nil
		self._stop_next_frame = nil
		self._network_bound = nil
		Network:unbind()
		Network:set_disconnected()
		cat_print("multiplayer_base", "[NetworkManager:stop_network]")
		print("---------------------------------------------------------")
	end
end
function NetworkManager:queue_stop_network()
	self._stop_network = true
end
function NetworkManager:is_ready_to_load()
	return not self._session or self._session:is_ready_to_close()
end
function NetworkManager:stopping()
	if not self._started then
		return true
	end
	if self._stop_next_frame or self._stop_network then
		return true
	end
	return false
end
function NetworkManager:start_client()
	self:stop_network(true)
	self:start_network()
	if self._is_win32 then
		self.voice_chat:open()
	end
	self._session = ClientNetworkSession:new()
end
function NetworkManager:discover_hosts(result_cb)
	self:stop_network(true)
	self:start_network()
	self._session = ClientNetworkSession:new()
	self._discover_hosts_cb = result_cb
	self._session:discover_hosts()
end
function NetworkManager:on_discover_host_received(sender)
	if Global.game_settings.single_player then
		return
	end
	local level_name = Global.level_data.level
	local level_id = tweak_data.levels:get_index_from_world_name(level_name)
	if level_id then
		level_name = ""
	else
		level_id = 1
	end
	local peer = managers.network:session():local_peer()
	local state = peer:in_lobby() and 1 or 2
	local difficulty = Global.game_settings.difficulty
	level_id = tweak_data.levels:get_index_from_level_id(Global.game_settings.level_id)
	print("on_discover_host_received", level_id)
	local my_name
	if SystemInfo:platform() == Idstring("PS3") then
		my_name = "Player 1"
	else
		my_name = Network:hostname()
	end
	sender:discover_host_reply(my_name, level_id, level_name, sender:ip_at_index(0), state, difficulty)
end
function NetworkManager:on_discover_host_reply(host, host_name, level_name, my_ip, state, difficulty)
	print("on_discover_host_reply", host, host_name, level_name, my_ip, state)
	if self._discover_hosts_cb then
		local cb = self._discover_hosts_cb
		self._session:on_host_discovered(host, host_name, level_name, my_ip, state, difficulty)
		cb(host, host_name, level_name, my_ip, state, difficulty)
	end
end
function NetworkManager:host_game()
	self:stop_network(true)
	self:start_network()
	if self._is_win32 then
		self.voice_chat:open()
	end
	self._session = HostNetworkSession:new()
	self._game:on_server_session_created()
	if self.is_ps3 then
		self._session:broadcast_server_up()
	end
end
function NetworkManager:join_game_at_host_rpc(host_rpc, result_cb)
	if not self._session or not self._session:is_client() then
		self:start_client()
	end
	self._discover_hosts_cb = nil
	if self._session then
		self._session:request_join_host(host_rpc, result_cb)
	else
		debug_pause("[NetworkManager:join_game_at_host_rpc] no session!!!")
	end
end
function NetworkManager:register_spawn_point(id, data)
	local runtime_data = {
		pos_rot = {
			data.position,
			data.rotation
		},
		id = id
	}
	self._spawn_points[id] = runtime_data
end
function NetworkManager:unregister_spawn_point(id)
	self._spawn_points[id] = nil
end
function NetworkManager:unregister_all_spawn_points()
	self._spawn_points = {}
end
function NetworkManager:has_spawn_points()
	return next(self._spawn_points)
end
function NetworkManager:spawn_point(sp_id)
	return self._spawn_points[sp_id]
end
function NetworkManager:_register_PSN_matchmaking_callbacks()
	local gen_clbk = callback(self, self, "clbk_PSN_event")
	PSN:set_matchmaking_callback("session_destroyed", gen_clbk)
	PSN:set_matchmaking_callback("session_created", gen_clbk)
	PSN:set_matchmaking_callback("session_kickout", gen_clbk)
	PSN:set_matchmaking_callback("member_left", gen_clbk)
	PSN:set_matchmaking_callback("member_joined", gen_clbk)
	PSN:set_matchmaking_callback("owner_changed", gen_clbk)
	PSN:set_matchmaking_callback("server_ready", gen_clbk)
	PSN:set_matchmaking_callback("lobby_refresh", gen_clbk)
	PSN:set_matchmaking_callback("lobby_joined", gen_clbk)
	PSN:set_matchmaking_callback("lobby_left", gen_clbk)
	PSN:set_matchmaking_callback("friends_updated", gen_clbk)
	PSN:set_matchmaking_callback("receive_group_invitation", gen_clbk)
	PSN:set_matchmaking_callback("room_custom_info", gen_clbk)
	PSN:set_matchmaking_callback("invitation_received", gen_clbk)
	PSN:set_matchmaking_callback("invitation_received_result", gen_clbk)
	PSN:set_matchmaking_callback("invitation_gui_opened", gen_clbk)
	PSN:set_matchmaking_callback("invitation_gui_closed", gen_clbk)
	PSN:set_matchmaking_callback("connection_etablished", gen_clbk)
	PSN:set_matchmaking_callback("session_search", gen_clbk)
	PSN:set_matchmaking_callback("custom_message", gen_clbk)
	PSN:set_matchmaking_callback("session_update", gen_clbk)
	PSN:set_matchmaking_callback("error", gen_clbk)
end
function NetworkManager:clbk_PSN_event(...)
	print("[NetworkManager:clbk_PSN_event]", inspect(...))
end
function NetworkManager:search_ses()
	PSN:set_matchmaking_callback("session_search", callback(self, self, "clbk_search_session"))
	local search_params = {
		numbers = {1, 3}
	}
	PSN:search_session(search_params, {}, PSN:get_world_list()[1].world_id)
end
function NetworkManager:clbk_search_session(search_results)
	print("[NetworkManager:clbk_search_session]", search_results)
	for i, k in pairs(search_results) do
		print(i, k and inspect(k))
	end
end
function NetworkManager.clbk_msg_overwrite(overwrite_data, msg_queue, ...)
	if msg_queue then
		if overwrite_data.index then
			msg_queue[overwrite_data.index] = {
				...
			}
		else
			table.insert(msg_queue, {
				...
			})
			overwrite_data.index = #msg_queue
		end
	else
		overwrite_data.index = nil
	end
end
function NetworkManager:protocol_type()
	return self.PROTOCOL_TYPE
end
