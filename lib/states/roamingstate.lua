require("lib/states/GameState")
RoamingState = RoamingState or class(GameState)
function RoamingState:init(game_state_machine, setup)
	GameState.init(self, "roaming_map", game_state_machine)
end
function RoamingState:set_controller_enabled(enabled)
	managers.roaming:controller():set_enabled(enabled)
end
