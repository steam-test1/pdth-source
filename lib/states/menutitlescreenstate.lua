require("lib/states/GameState")
MenuTitlescreenState = MenuTitlescreenState or class(GameState)
function MenuTitlescreenState:init(game_state_machine, setup)
	GameState.init(self, "menu_titlescreen", game_state_machine)
	if setup then
		self:setup()
	end
end
local is_ps3 = SystemInfo:platform() == Idstring("PS3")
function MenuTitlescreenState:setup()
	local res = RenderSettings.resolution
	local gui = Overlay:gui()
	self._workspace = gui:create_screen_workspace()
	self._workspace:hide()
	local bitmap = self._workspace:panel():bitmap({
		texture = "guis/textures/menu_background",
		layer = 1
	})
	bitmap:set_size(1024 * tweak_data.scale.title_image_multiplier, 512 * tweak_data.scale.title_image_multiplier)
	bitmap:set_center(res.x / 2, res.y / 2)
	self._workspace:panel():rect({
		color = Color.black,
		w = res.x,
		h = res.y,
		layer = 0
	})
	local text_id
	if managers.dlc:has_pre_dlc() then
		text_id = "menu_visit_forum1"
	else
		text_id = is_ps3 and "menu_press_start" or "menu_visit_forum3"
	end
	local text = self._workspace:panel():text({
		text = managers.localization:text(text_id),
		font = "fonts/font_univers_latin_530_bold",
		font_size = tweak_data.menu.topic_font_size,
		color = Color.white,
		align = "center",
		vertical = "bottom",
		w = res.x,
		h = res.y,
		layer = tweak_data.gui.TITLE_SCREEN_LAYER
	})
	text:set_bottom(res.y / 1.25)
	self._controller_list = {}
	for index = 1, managers.controller:get_wrapper_count() do
		self._controller_list[index] = managers.controller:create_controller("title_" .. index, index, false)
	end
	self:reset_attract_video()
end
function MenuTitlescreenState:at_enter()
	if not self._controller_list then
		self:setup()
		Application:stack_dump_error("Shouldn't enter title more than once. Except when toggling freeflight.")
	end
	managers.menu:input_enabled(false)
	for index, controller in ipairs(self._controller_list) do
		controller:enable()
	end
	self._workspace:show()
	managers.user:set_index(nil)
	managers.controller:set_default_wrapper_index(nil)
	self:reset_attract_video()
end
function MenuTitlescreenState:update(t, dt)
	self:check_confirm_pressed()
	if managers.system_menu:is_active() then
		self:reset_attract_video()
	else
		self._controller_index = self:get_start_pressed_controller_index()
		if self._controller_index then
			managers.controller:set_default_wrapper_index(self._controller_index)
			managers.user:set_index(self._controller_index)
			managers.user:check_user(callback(self, self, "check_user_callback"), true)
		elseif not self:check_attract_video() and self:is_attract_video_delay_done() then
			self:play_attract_video()
		end
	end
end
function MenuTitlescreenState:get_start_pressed_controller_index()
	for index, controller in ipairs(self._controller_list) do
		if is_ps3 then
			if controller:get_input_pressed("start") then
				return index
			end
		elseif controller._default_controller_id == "keyboard" and (#Input:keyboard():pressed_list() > 0 or 0 < #Input:mouse():pressed_list()) then
			return index
		end
	end
	return nil
end
function MenuTitlescreenState:check_confirm_pressed()
	for index, controller in ipairs(self._controller_list) do
		if controller:get_input_pressed("confirm") then
			print("check_confirm_pressed")
			local active, dialog = managers.system_menu:is_active_by_id("invite_join_message")
			if active then
				print("close")
				dialog:button_pressed_callback()
			end
		end
	end
end
function MenuTitlescreenState:check_user_callback(success)
	if success then
		managers.user:check_storage(callback(self, self, "check_storage_callback"), true)
	else
		local dialog_data = {}
		dialog_data.title = managers.localization:text("dialog_warning_title")
		dialog_data.text = managers.localization:text("dialog_skip_signin_warning")
		local yes_button = {}
		yes_button.text = managers.localization:text("dialog_yes")
		yes_button.callback_func = callback(self, self, "continue_without_saving_yes_callback")
		local no_button = {}
		no_button.text = managers.localization:text("dialog_no")
		no_button.callback_func = callback(self, self, "continue_without_saving_no_callback")
		dialog_data.button_list = {yes_button, no_button}
		managers.system_menu:show(dialog_data)
	end
end
function MenuTitlescreenState:check_storage_callback(success)
	if success then
		local sound_source = SoundDevice:create_source("MenuTitleScreen")
		sound_source:post_event("menu_start")
		self:gsm():change_state_by_name("menu_main")
	else
		local dialog_data = {}
		dialog_data.title = managers.localization:text("dialog_warning_title")
		dialog_data.text = managers.localization:text("dialog_skip_storage_warning")
		local yes_button = {}
		yes_button.text = managers.localization:text("dialog_yes")
		yes_button.callback_func = callback(self, self, "continue_without_saving_yes_callback")
		local no_button = {}
		no_button.text = managers.localization:text("dialog_no")
		no_button.callback_func = callback(self, self, "continue_without_saving_no_callback")
		dialog_data.button_list = {yes_button, no_button}
		managers.system_menu:show(dialog_data)
	end
end
function MenuTitlescreenState:continue_without_saving_yes_callback()
	self:gsm():change_state_by_name("menu_main")
end
function MenuTitlescreenState:continue_without_saving_no_callback()
	managers.user:set_index(nil)
	managers.controller:set_default_wrapper_index(nil)
end
function MenuTitlescreenState:check_attract_video()
	if alive(self._attract_video_gui) then
		if self._attract_video_gui:loop_count() > 0 or self:is_any_input_pressed() then
			self:reset_attract_video()
		else
			return true
		end
	elseif self:is_any_input_pressed() then
		self:reset_attract_video()
	end
	return false
end
function MenuTitlescreenState:is_any_input_pressed()
	for _, controller in ipairs(self._controller_list) do
		if controller:get_any_input_pressed() then
			return true
		end
	end
	return false
end
function MenuTitlescreenState:reset_attract_video()
	self._attract_video_time = TimerManager:main():time()
	if alive(self._attract_video_gui) then
		self._attract_video_gui:stop()
		self._workspace:panel():remove(self._attract_video_gui)
		self._attract_video_gui = nil
	end
end
function MenuTitlescreenState:is_attract_video_delay_done()
	return TimerManager:main():time() > self._attract_video_time + _G.tweak_data.states.title.ATTRACT_VIDEO_DELAY
end
function MenuTitlescreenState:play_attract_video()
	self:reset_attract_video()
	local res = RenderSettings.resolution
	local src_width, src_height = 1280, 720
	local dest_width, dest_height
	if src_width / src_height > res.x / res.y then
		dest_width = res.x
		dest_height = src_height * dest_width / src_width
	else
		dest_height = res.y
		dest_width = src_width * dest_height / src_height
	end
	local x = (res.x - dest_width) / 2
	local y = (res.y - dest_height) / 2
	self._attract_video_gui = self._workspace:panel():video({
		video = "movies/attract",
		x = x,
		y = y,
		width = dest_width,
		height = dest_height,
		layer = tweak_data.gui.ATTRACT_SCREEN_LAYER
	})
	self._attract_video_gui:play()
end
function MenuTitlescreenState:at_exit()
	if alive(self._workspace) then
		Overlay:gui():destroy_workspace(self._workspace)
		self._workspace = nil
	end
	if self._controller_list then
		for _, controller in ipairs(self._controller_list) do
			controller:destroy()
		end
		self._controller_list = nil
	end
	managers.menu:input_enabled(true)
	managers.user:set_active_user_state_change_quit(true)
	managers.system_menu:init_finalize()
end
