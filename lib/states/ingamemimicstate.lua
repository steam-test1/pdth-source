require("lib/states/GameState")
IngameMimicInteractionState = IngameMimicInteractionState or class(GameState)
function IngameMimicInteractionState:init(game_state_machine)
	GameState.init(self, "ingame_mimic_interaction", game_state_machine)
	self._ws = Overlay:newgui():create_screen_workspace()
	self._panel = self._ws:panel()
	self._text = self._panel:text({
		name = "text",
		text = "Mimic",
		font = "fonts/font_fortress_22",
		font_size = 24,
		color = Color.white,
		layer = 1
	})
	self._text = self._panel:text({
		name = "text",
		text = "Mimic",
		font = "fonts/font_fortress_22",
		font_size = 24,
		color = Color.black,
		layer = 0,
		x = -2,
		y = -2
	})
	self._text = self._panel:text({
		name = "text",
		text = "Mimic",
		font = "fonts/font_fortress_22",
		font_size = 24,
		color = Color.black,
		layer = 0,
		x = 2,
		y = -2
	})
	self._text = self._panel:text({
		name = "text",
		text = "Mimic",
		font = "fonts/font_fortress_22",
		font_size = 24,
		color = Color.black,
		layer = 0,
		x = 2,
		y = 2
	})
	self._text = self._panel:text({
		name = "text",
		text = "Mimic",
		font = "fonts/font_fortress_22",
		font_size = 24,
		color = Color.black,
		layer = 0,
		x = -2,
		y = 2
	})
	self._ws:hide()
end
function IngameMimicInteractionState:set_controller_enabled(enabled)
	local players = managers.player:players()
	for _, player in ipairs(players) do
		local controller = player:base():controller()
		if controller then
			controller:set_enabled(enabled)
		end
	end
end
function IngameMimicInteractionState:at_enter()
	self._ws:show()
end
function IngameMimicInteractionState:at_exit()
	self._ws:hide()
end
IngameMimicState = IngameMimicState or class(GameState)
function IngameMimicState:init(game_state_machine)
	GameState.init(self, "ingame_mimic", game_state_machine)
end
function IngameMimicState:set_controller_enabled(enabled)
	local players = managers.player:players()
	for _, player in ipairs(players) do
		local controller = player:base():controller()
		if controller then
			controller:set_enabled(enabled)
		end
	end
end
function IngameMimicState:at_enter()
end
function IngameMimicState:at_exit()
end
