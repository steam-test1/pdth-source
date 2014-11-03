require("lib/states/GameState")
BootupState = BootupState or class(GameState)
function BootupState:init(game_state_machine, setup)
	GameState.init(self, "bootup", game_state_machine)
	if setup then
		self:setup()
	end
end
function BootupState:setup()
	local res = RenderSettings.resolution
	local safe_rect_pixels = managers.viewport:get_safe_rect_pixels()
	local gui = Overlay:gui()
	local is_win32 = SystemInfo:platform() == Idstring("WIN32")
	local show_esrb = true
	self._workspace = gui:create_screen_workspace()
	self._workspace:hide()
	local esrb_y = res.y / 1.9
	local can_skip = true
	local has_full_game = managers.dlc:has_full_game()
	local legal_text = managers.localization:text("legal_text")
	self._play_data_list = {
		{
			visible = not is_win32,
			gui = Idstring("guis/autosave_warning"),
			width = 600,
			height = 200,
			can_skip = false,
			fade_in = 1.25,
			duration = is_win32 and 0 or 6,
			fade_out = 1.25
		},
		{
			visible = show_esrb,
			layer = 1,
			texture = "guis/textures/esrb_rating",
			width = esrb_y * 2,
			height = esrb_y,
			can_skip = has_full_game,
			fade_in = 1.25,
			duration = show_esrb and 6.5 or 0,
			fade_out = 1.25
		},
		{
			layer = 1,
			texture = "guis/textures/soe_logo",
			width = 256,
			height = 256,
			padding = 200,
			can_skip = can_skip,
			fade_in = 1.25,
			duration = 6,
			fade_out = 1.25
		},
		{
			layer = 1,
			text = legal_text,
			font = "fonts/font_univers_530_bold",
			font_size = 24,
			wrap = true,
			word_wrap = true,
			vertical = "center",
			width = safe_rect_pixels.width,
			height = safe_rect_pixels.height,
			padding = 200,
			can_skip = can_skip,
			fade_in = 1.25,
			duration = 6,
			fade_out = 1.25
		},
		{
			layer = 1,
			video = "movies/company_logo",
			width = res.x,
			height = res.y,
			padding = 200,
			can_skip = true
		},
		{
			layer = 1,
			video = "movies/game_logo",
			width = res.x,
			height = res.y,
			padding = 200,
			can_skip = true
		}
	}
	self._panel = self._workspace:panel()
	self._panel:rect({
		visible = true,
		color = Color.black,
		w = res.x,
		h = res.y,
		layer = 0
	})
	self._panel:bitmap({
		visible = true,
		texture = "guis/textures/menu_background",
		layer = -1
	})
	self._controller_list = {}
	for index = 1, managers.controller:get_wrapper_count() do
		local con = managers.controller:create_controller("boot_" .. index, index, false)
		con:enable()
		self._controller_list[index] = con
	end
end
function BootupState:at_enter()
	managers.music:post_event("menu_music")
	managers.menu:input_enabled(false)
	if not self._controller_list then
		self:setup()
		Application:stack_dump_error("Shouldn't enter boot state more than once. Except when toggling freeflight.")
	end
	self._workspace:show()
	self:play_next()
end
function BootupState:update(t, dt)
	self:check_confirm_pressed()
	if not self:is_playing() or (self._play_data.can_skip or Global.override_bootup_can_skip) and self:is_skipped() then
		self:play_next()
	else
		self:update_fades()
	end
end
function BootupState:check_confirm_pressed()
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
function BootupState:update_fades()
	local time, duration
	if self._play_data.video then
		duration = self._gui_obj:length()
		local frames = self._gui_obj:frames()
		if frames > 0 then
			time = self._gui_obj:frame_num() / frames * duration
		else
			time = 0
		end
	else
		time = TimerManager:game():time() - self._play_time
		duration = self._play_data.duration
	end
	local old_fade = self._fade
	if self._play_data.fade_in and time < self._play_data.fade_in then
		if 0 < self._play_data.fade_in then
			self._fade = time / self._play_data.fade_in
		else
			self._fade = 1
		end
	elseif self._play_data.fade_in and duration - time < self._play_data.fade_out then
		if 0 < self._play_data.fade_out then
			self._fade = (duration - time) / self._play_data.fade_out
		else
			self._fade = 0
		end
	else
		self._fade = 1
	end
	if self._fade ~= old_fade then
		self:apply_fade()
	end
end
function BootupState:apply_fade()
	if self._play_data.gui then
		local script = self._gui_obj.script and self._gui_obj:script()
		if script.set_fade then
			script:set_fade(self._fade)
		else
			Application:error("GUI \"" .. tostring(self._play_data.gui) .. "\" lacks a function set_fade( o, fade ).")
		end
	else
		self._gui_obj:set_color(self._gui_obj:color():with_alpha(self._fade))
	end
end
function BootupState:is_skipped()
	for _, controller in ipairs(self._controller_list) do
		if controller:get_any_input_pressed() then
			return true
		end
	end
	return false
end
function BootupState:is_playing()
	if alive(self._gui_obj) then
		if self._gui_obj.loop_count then
			return self._gui_obj:loop_count() < 1
		else
			return TimerManager:game():time() < self._play_time + self._play_data.duration
		end
	else
		return false
	end
end
function BootupState:play_next()
	self._play_time = TimerManager:game():time()
	self._play_index = (self._play_index or 0) + 1
	self._play_data = self._play_data_list[self._play_index]
	if self._play_data then
		self._fade = self._play_data.fade_in and 0 or 1
		if alive(self._gui_obj) then
			self._panel:remove(self._gui_obj)
			self._gui_obj = nil
		end
		local res = RenderSettings.resolution
		local width, height
		local padding = self._play_data.padding or 0
		if self._play_data.gui then
			if self._play_data.width / self._play_data.height > res.x / res.y then
				width = res.x - padding * 2
				height = self._play_data.height * width / self._play_data.width
			else
				height = self._play_data.height
				width = self._play_data.width
			end
		else
			height = self._play_data.height
			width = self._play_data.width
		end
		local x = (res.x - width) / 2
		local y = (res.y - height) / 2
		local gui_config = {
			x = x,
			y = y,
			width = width,
			height = height,
			layer = tweak_data.gui.BOOT_SCREEN_LAYER
		}
		if self._play_data.video then
			gui_config.video = self._play_data.video
			self._gui_obj = self._panel:video(gui_config)
			local w = self._gui_obj:video_width()
			local h = self._gui_obj:video_height()
			local m = h / w
			self._gui_obj:set_size(res.x, res.x * m)
			self._gui_obj:set_center(res.x / 2, res.y / 2)
			self._gui_obj:play()
		elseif self._play_data.texture then
			gui_config.texture = self._play_data.texture
			self._gui_obj = self._panel:bitmap(gui_config)
		elseif self._play_data.text then
			gui_config.text = self._play_data.text
			gui_config.font = self._play_data.font
			gui_config.font_size = self._play_data.font_size
			gui_config.wrap = self._play_data.wrap
			gui_config.word_wrap = self._play_data.word_wrap
			gui_config.vertical = self._play_data.vertical
			self._gui_obj = self._panel:text(gui_config)
		elseif self._play_data.gui then
			self._gui_obj = self._panel:gui(self._play_data.gui)
			self._gui_obj:set_shape(x, y, width, height)
			local script = self._gui_obj:script()
			if script.setup then
				script:setup()
			end
		end
		self:apply_fade()
	else
		self:gsm():change_state_by_name("menu_titlescreen")
	end
end
function BootupState:at_exit()
	if alive(self._workspace) then
		Overlay:gui():destroy_workspace(self._workspace)
		self._workspace = nil
		self._gui_obj = nil
	end
	if self._controller_list then
		for _, controller in ipairs(self._controller_list) do
			controller:destroy()
		end
		self._controller_list = nil
	end
	self._play_data_list = nil
	self._play_index = nil
	self._play_data = nil
	managers.menu:input_enabled(true)
	if PackageManager:loaded("packages/boot_screen") then
		PackageManager:unload("packages/boot_screen")
	end
end
