require("lib/states/GameState")
IngameDialogState = IngameDialogState or class(GameState)
function IngameDialogState:init(game_state_machine)
	GameState.init(self, "ingame_dialog", game_state_machine)
	self._ws = Overlay:newgui():create_screen_workspace()
	self._panel = self._ws:panel()
	self._text = self._panel:text({
		name = "text",
		text = "Dialog",
		font = "fonts/font_fortress_22",
		font_size = 24,
		color = Color.black,
		layer = 1
	})
	self._controller = managers.controller:create_controller("ingame_dialog", managers.controller:get_default_wrapper_index(), false)
	self._controller:set_enabled(true)
	self._ws:hide()
end
function IngameDialogState:set_controller_enabled(enabled)
	local players = managers.player:players()
	for _, player in ipairs(players) do
		local controller = player:base():controller()
		if controller then
			controller:set_enabled(enabled)
		end
	end
end
function IngameDialogState:at_enter()
	self:set_controller_enabled(false)
	self._ws:show()
end
function IngameDialogState:at_exit()
	self:set_controller_enabled(true)
	self._ws:hide()
end
function IngameDialogState:update(t, dt)
	if not managers.dialog:is_active() then
		managers.player:set_player_state("adventure")
	end
end
