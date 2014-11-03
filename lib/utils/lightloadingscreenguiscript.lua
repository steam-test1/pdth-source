LightLoadingScreenGuiScript = LightLoadingScreenGuiScript or class()
function LightLoadingScreenGuiScript:init(scene_gui, res, progress, base_layer, is_win32)
	self._base_layer = base_layer
	self._is_win32 = is_win32
	self._scene_gui = scene_gui
	self._ws = scene_gui:create_screen_workspace()
	local panel = self._ws:panel()
	self._panel = panel
	self._bg_gui = panel:rect({
		visible = true,
		color = Color.black,
		layer = base_layer
	})
	self._rotating_rect_gui = panel:rect({
		visible = false,
		color = Color.white,
		w = 15,
		h = 15,
		layer = base_layer + 1
	})
	self._text_gui = panel:text({
		visible = false,
		text = "LOADING",
		font = "fonts/font_univers_530_medium",
		font_size = 24,
		color = Color.white,
		layer = base_layer + 1
	})
	self._bar_border_gui = panel:rect({
		visible = false,
		color = Color(0.3, 0.3, 0.3),
		layer = base_layer + 1
	})
	self._bar_bg_gui = panel:rect({
		visible = false,
		color = Color.black,
		layer = base_layer + 2
	})
	self._bar_gui = panel:rect({
		visible = false,
		color = Color.white,
		layer = base_layer + 3
	})
	self._safe_rect_pixels = self:get_safe_rect_pixels(res)
	self._saferect_panel = panel:panel(self._safe_rect_pixels)
	local title_scale = 1
	local menu_border_multiplier = 1
	local menu_logo_multiplier = 1
	if res.y <= 601 then
		title_scale = 0.7
		menu_border_multiplier = 0.6
		menu_logo_multiplier = 0.575
	end
	self._gui_tweak_data = {}
	self._gui_tweak_data.upper_saferect_border = 64 * menu_border_multiplier
	self._gui_tweak_data.border_pad = 8 * menu_border_multiplier
	self._title_text = self._saferect_panel:text({
		y = 0,
		text_id = "debug_loading_level",
		font = "fonts/font_univers_530_bold",
		font_size = 32 * title_scale,
		color = Color.white,
		align = "left",
		halign = "left",
		vertical = "bottom",
		layer = self._base_layer + 1,
		h = 24
	})
	self._title_text:set_text(string.upper(" > " .. self._title_text:text()))
	self._stonecold_small_logo = self._saferect_panel:bitmap({
		name = "stonecold_small_logo",
		texture = "guis/textures/game_small_logo",
		texture_rect = {
			0,
			0,
			256,
			56
		},
		layer = self._base_layer + 1,
		h = 56
	})
	self._stonecold_small_logo:set_size(256 * menu_logo_multiplier, 56 * menu_logo_multiplier)
	self._indicator = self._saferect_panel:bitmap({
		name = "indicator",
		texture = "guis/textures/icon_loading",
		layer = self._base_layer + 1
	})
	self._init_text = self._text_gui:text()
	self._dot_count = 0
	self._max_dot_count = 4
	self._init_progress = 0
	self._fake_progress = 0
	self._max_bar_width = 0
	self:setup(res, progress)
end
function LightLoadingScreenGuiScript:get_safe_rect()
	local a = self._is_win32 and 0.032 or 0.075
	local b = 1 - a * 2
	return {
		x = a,
		y = a,
		width = b,
		height = b
	}
end
function LightLoadingScreenGuiScript:get_safe_rect_pixels(res)
	local safe_rect_scale = self:get_safe_rect()
	local safe_rect_pixels = {}
	safe_rect_pixels.x = safe_rect_scale.x * res.x
	safe_rect_pixels.y = safe_rect_scale.y * res.y
	safe_rect_pixels.width = safe_rect_scale.width * res.x
	safe_rect_pixels.height = safe_rect_scale.height * res.y
	return safe_rect_pixels
end
function LightLoadingScreenGuiScript:setup(res, progress)
	local title_scale = 1
	local menu_border_multiplier = 1
	local menu_logo_multiplier = 1
	if res.y <= 601 then
		title_scale = 0.7
		menu_border_multiplier = 0.6
		menu_logo_multiplier = 0.575
	end
	self._saferect_panel:set_shape(self._safe_rect_pixels.x, self._safe_rect_pixels.y, self._safe_rect_pixels.width, self._safe_rect_pixels.height)
	self._gui_tweak_data = {}
	self._gui_tweak_data.upper_saferect_border = 64 * menu_border_multiplier
	self._gui_tweak_data.border_pad = 8 * menu_border_multiplier
	self._title_text:set_font_size(32 * title_scale)
	self._stonecold_small_logo:set_size(256 * menu_logo_multiplier, 56 * menu_logo_multiplier)
	self._title_text:set_shape(0, 0, self._safe_rect_pixels.width, self._gui_tweak_data.upper_saferect_border - self._gui_tweak_data.border_pad)
	local _, _, w, _ = self._title_text:text_rect()
	self._title_text:set_w(w)
	self._stonecold_small_logo:set_right(self._stonecold_small_logo:parent():w())
	self._stonecold_small_logo:set_bottom(self._gui_tweak_data.upper_saferect_border - self._gui_tweak_data.border_pad)
	self._indicator:set_left(self._title_text:right() + 8)
	self._indicator:set_bottom(self._gui_tweak_data.upper_saferect_border - self._gui_tweak_data.border_pad)
	self._bg_gui:set_size(res.x, res.y)
	self._text_gui:set_text(self:get_loading_text(self._max_dot_count))
	local text_x, text_y, text_w, text_h = self._text_gui:text_rect()
	text_x = (res.x - text_w) / 2
	text_y = (res.y - text_h) / 2
	self._text_gui:set_shape(text_x, text_y, text_w, text_h)
	self._text_gui:set_text(self._init_text)
	self._rotating_rect_gui:set_x(text_x - self._rotating_rect_gui:h() * 1.5)
	self._rotating_rect_gui:set_y((res.y - self._rotating_rect_gui:h()) / 2)
	local border_size = 2
	local bar_size = 2
	self._bar_border_gui:set_shape(self._rotating_rect_gui:x(), text_y + text_h + 2, text_x + text_w - self._rotating_rect_gui:x(), border_size * 2 + bar_size)
	self._bar_bg_gui:set_shape(self._bar_border_gui:x() + bar_size, self._bar_border_gui:y() + bar_size, self._bar_border_gui:w() - border_size * 2, bar_size)
	self._bar_gui:set_shape(self._bar_bg_gui:x(), self._bar_bg_gui:y(), 0, self._bar_bg_gui:h())
	self._max_bar_width = self._bar_bg_gui:w()
	if progress > 0 then
		self._init_progress = progress
	end
end
function LightLoadingScreenGuiScript:update(progress, dt)
	self._indicator:rotate(180 * dt)
	self._dot_count = (self._dot_count + dt * 2) % self._max_dot_count
	self._text_gui:set_text(self:get_loading_text(self._dot_count))
	self._rotating_rect_gui:rotate(180 * dt)
	if self._init_progress < 100 then
		if progress == -1 then
			self._fake_progress = self._fake_progress + 20 * dt
			if 100 < self._fake_progress then
				self._fake_progress = 100
			end
			progress = self._fake_progress
		end
		self._bar_gui:set_w(self._max_bar_width * progress / (100 - self._init_progress))
	end
end
function LightLoadingScreenGuiScript:get_loading_text(dot_count)
	return self._init_text .. string.rep(".", math.floor(dot_count))
end
function LightLoadingScreenGuiScript:set_text(text)
	self._text_gui:set_text(text)
	self._init_text = text
end
function LightLoadingScreenGuiScript:destroy()
	if alive(self._ws) then
		self._scene_gui:destroy_workspace(self._ws)
		self._ws = nil
	end
end
function LightLoadingScreenGuiScript:visible()
	return self._ws:visible()
end
function LightLoadingScreenGuiScript:set_visible(visible, res)
	if res then
		self._safe_rect_pixels = self:get_safe_rect_pixels(res)
		self:setup(res, -1)
	end
	if visible then
		self._ws:show()
	else
		self._ws:hide()
	end
end
