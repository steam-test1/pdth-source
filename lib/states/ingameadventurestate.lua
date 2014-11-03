require("lib/states/GameState")
IngameAdventureState = IngameAdventureState or class(GameState)
function IngameAdventureState:init(game_state_machine)
	GameState.init(self, "ingame_adventure", game_state_machine)
	self._ws = Overlay:newgui():create_screen_workspace()
	self._panel = self._ws:panel()
	self._text = self._panel:text({
		name = "text",
		text = "Adventure",
		font = "fonts/font_fortress_22",
		font_size = 24,
		color = Color.black,
		layer = 1
	})
	self._ws:hide()
end
function IngameAdventureState:set_controller_enabled(enabled)
	local players = managers.player:players()
	for _, player in ipairs(players) do
		local controller = player:base():controller()
		if controller then
			controller:set_enabled(enabled)
		end
	end
end
function IngameAdventureState:at_enter()
	self._ws:show()
end
function IngameAdventureState:at_exit()
	self._ws:hide()
end
