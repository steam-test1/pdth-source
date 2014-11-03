require("lib/states/GameState")
IngameBattleState = IngameBattleState or class(GameState)
function IngameBattleState:init(game_state_machine)
	GameState.init(self, "ingame_battle", game_state_machine)
	self._ws = Overlay:newgui():create_screen_workspace()
	self._panel = self._ws:panel()
	self._text = self._panel:text({
		name = "text",
		text = "Battle",
		font = "fonts/font_fortress_22",
		font_size = 24,
		color = Color.black,
		layer = 1
	})
	self._ws:hide()
end
function IngameBattleState:set_controller_enabled(enabled)
	local players = managers.player:players()
	for _, player in ipairs(players) do
		local controller = player:base():controller()
		if controller then
			controller:set_enabled(enabled)
		end
	end
end
function IngameBattleState:at_enter()
	local players = managers.player:players()
	for k, player in ipairs(players) do
		local vp = player:camera():viewport()
		if vp then
			vp:set_active(true)
		else
			Application:error("No viewport for player " .. tostring(k))
		end
	end
	self._ws:show()
end
function IngameBattleState:at_exit()
	self._ws:hide()
end
