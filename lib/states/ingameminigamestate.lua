require("lib/states/GameState")
IngameMinigameState = IngameMinigameState or class(GameState)
function IngameMinigameState:init(game_state_machine)
	GameState.init(self, "ingame_minigame", game_state_machine)
	self._ws = Overlay:newgui():create_screen_workspace()
	self._panel = self._ws:panel()
	self._text = self._panel:text({
		name = "text",
		text = "Minigame",
		font = "fonts/font_fortress_22",
		font_size = 24,
		color = Color.black,
		layer = 1
	})
	self._rect = self._panel:rect({
		x = Application:screen_resolution().x * 0.25,
		y = Application:screen_resolution().y * 0.25,
		w = Application:screen_resolution().x * 0.5,
		h = Application:screen_resolution().y * 0.5,
		color = Color.white:with_alpha(0)
	})
	self._controller = managers.controller:get_controller_by_name("ingame_dialog")
	self._ws:hide()
end
function IngameMinigameState:set_controller_enabled(enabled)
	local players = managers.player:players()
	for _, player in ipairs(players) do
		local controller = player:base():controller()
		if controller then
			controller:set_enabled(enabled)
		end
	end
end
function IngameMinigameState:at_enter()
	local players = managers.player:players()
	for k, player in ipairs(players) do
		local vp = player:camera():viewport()
		if vp then
			vp:set_active(true)
		else
			Application:error("No viewport for player " .. tostring(k))
		end
	end
	self:set_controller_enabled(false)
	self:_start_game()
	self._ws:show()
end
function IngameMinigameState:at_exit()
	local players = managers.player:players()
	for _, player in ipairs(players) do
		local vp = player:camera():viewport()
		if vp then
			vp:set_active(false)
		end
	end
	self:set_controller_enabled(true)
	self._ws:hide()
end
function IngameMinigameState:update(t, dt)
	local any_button = self._controller:get_any_input_pressed()
	local buttons = {}
	buttons.green = self._controller:get_input_pressed("minigame_green")
	buttons.red = self._controller:get_input_pressed("minigame_red")
	buttons.yellow = self._controller:get_input_pressed("minigame_yellow")
	buttons.blue = self._controller:get_input_pressed("minigame_blue")
	local buttons_down = false
	if buttons.green or buttons.red or buttons.yellow or buttons.blue then
		buttons_down = true
	end
	if any_button and not buttons.green and not buttons.red and not buttons.yellow and not buttons.blue then
		managers.player:set_player_state("adventure")
		return
	end
	if self._user then
		local a = 0.4 * (Application:time() - math.floor(Application:time()))
		if a > 0.2 then
			a = 0.2 - (a - 0.2)
		end
		self._rect:set_color(Color.white:with_alpha(0.1 + a))
		if buttons_down then
			if buttons[self._button_list[self._color_index]] then
				if self._color_index == self._level then
					self:_update_level()
				else
					self._color_index = self._color_index + 1
				end
			else
				self:_start_game()
			end
		end
	else
		self._rect:set_color(Color[self._button_list[self._color_index]]:with_alpha(0.3))
		self._color_time = self._color_time - dt
		if self._color_time <= 0 then
			if self._color_index == self._level then
				self._user = true
				self._color_index = 1
				self._rect:set_color(Color.white:with_alpha(0))
			else
				self._color_time = 1
				self._color_index = self._color_index + 1
			end
		end
	end
end
function IngameMinigameState:_start_game()
	self._level = 0
	self._user = false
	self._button_list = {}
	self._last = 0
	self:_update_level()
end
function IngameMinigameState:_update_level()
	self._level = self._level + 1
	self._text:set_text("Minigame(X360 controller only) , Simon says , Level : " .. self._level)
	local r = 1 + math.floor(3.99 * math.random())
	while r == self._last do
		r = 1 + math.floor(3.99 * math.random())
	end
	self._last = r
	if r == 1 then
		table.insert(self._button_list, "green")
	elseif r == 2 then
		table.insert(self._button_list, "red")
	elseif r == 3 then
		table.insert(self._button_list, "yellow")
	elseif r == 4 then
		table.insert(self._button_list, "blue")
	end
	self._user = false
	self._color_index = 1
	self._color_time = 1
end
