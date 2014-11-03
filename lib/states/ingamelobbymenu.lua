core:import("CoreUnit")
require("lib/states/GameState")
IngameLobbyMenuState = IngameLobbyMenuState or class(GameState)
function IngameLobbyMenuState:init(game_state_machine)
	GameState.init(self, "ingame_lobby_menu", game_state_machine)
	self._controller = nil
end
function IngameLobbyMenuState:setup_controller()
	if not self._controller then
		self._controller = managers.controller:create_controller("ingame_lobby_menu", managers.controller:get_default_wrapper_index(), false)
	end
	self._controller:set_enabled(true)
end
function IngameLobbyMenuState:set_controller_enabled(enabled)
	if self._controller then
	end
end
function IngameLobbyMenuState:update(t, dt)
end
function IngameLobbyMenuState:at_enter()
	managers.platform:set_presence("Mission_end")
	managers.hud:remove_updator("point_of_no_return")
	print("[IngameLobbyMenuState:at_enter()]")
	if Network:is_server() then
		managers.network.matchmake:set_server_state("in_lobby")
		managers.network.matchmake:set_server_joinable(true)
		managers.network:session():set_state("in_lobby")
	else
		managers.network:session():send_to_peers_loaded("set_peer_entered_lobby")
	end
	managers.mission:pre_destroy()
	self:setup_controller()
	managers.menu:close_menu()
	managers.menu:open_menu("lobby_menu")
end
function IngameLobbyMenuState:at_exit()
	print("[IngameLobbyMenuState:at_exit()]")
	managers.menu:close_menu("lobby_menu")
end
function IngameLobbyMenuState:on_server_left()
	IngameCleanState.on_server_left(self)
end
function IngameLobbyMenuState:on_kicked()
	print("IngameLobbyMenuState:on_kicked()")
	IngameCleanState.on_kicked(self)
end
function IngameLobbyMenuState:on_disconnected()
	IngameCleanState.on_disconnected(self)
end
