LevelLoadingScreenGuiScript = LevelLoadingScreenGuiScript or class()
function LevelLoadingScreenGuiScript:init(scene_gui, res, progress, base_layer)
	self._scene_gui = scene_gui
	self._res = res
	self._base_layer = base_layer
	self._level_tweak_data = arg.load_level_data.level_tweak_data
	self._gui_tweak_data = arg.load_level_data.gui_tweak_data
	self._menu_tweak_data = arg.load_level_data.menu_tweak_data
	self._scale_tweak_data = arg.load_level_data.scale_tweak_data
	self._gui_data = arg.load_level_data.gui_data
	self._workspace_size = self._gui_data.workspace_size
	self._saferect_size = self._gui_data.saferect_size
	local challenges = arg.load_level_data.challenges
	local safe_rect_pixels = self._gui_data.safe_rect_pixels
	local safe_rect = self._gui_data.safe_rect
	self._safe_rect_pixels = safe_rect_pixels
	self._safe_rect = safe_rect
	self._saferect = self._scene_gui:create_scaled_screen_workspace(self._workspace_size.w * safe_rect.width, self._workspace_size.h * safe_rect.height, safe_rect_pixels.x, safe_rect_pixels.y, safe_rect_pixels.width, safe_rect_pixels.height)
	self._workspace = self._scene_gui:create_scaled_screen_workspace(self._workspace_size.w, self._workspace_size.h, self._workspace_size.x, self._workspace_size.y, res.x, res.y)
	local saferect_panel = self._saferect:panel()
	local workspace_panel = self._workspace:panel()
	self._saferect_panel = saferect_panel
	self._bg_gui = workspace_panel:bitmap({
		texture = "guis/textures/loading_bg",
		layer = base_layer - 1
	})
	self._upper_frame_line = workspace_panel:rect({
		visible = false,
		x = 0,
		y = safe_rect_pixels.y + self._gui_tweak_data.upper_saferect_border,
		w = res.x,
		h = 2,
		layer = base_layer + 1,
		color = Color.white
	})
	self._lower_frame_line = workspace_panel:rect({
		visible = false,
		x = 0,
		y = safe_rect_pixels.y + self._gui_tweak_data.upper_saferect_border,
		w = res.x,
		h = 2,
		layer = base_layer + 1,
		color = Color.white
	})
	self._upper_frame_gradient = workspace_panel:gradient({
		x = 0,
		y = 0,
		w = res.x,
		h = 48,
		layer = base_layer,
		orientation = "vertical",
		gradient_points = {
			0,
			Color.black:with_alpha(1),
			0.8,
			Color.black:with_alpha(1),
			1,
			Color.black:with_alpha(1)
		}
	})
	self._lower_frame_gradient = workspace_panel:gradient({
		x = 0,
		y = 0,
		w = res.x,
		h = 48,
		layer = base_layer,
		orientation = "vertical",
		gradient_points = {
			0,
			Color.black:with_alpha(1),
			0.8,
			Color.black:with_alpha(1),
			1,
			Color.black:with_alpha(1)
		}
	})
	self._tips_head_line = saferect_panel:text({
		text_id = "tip_tips",
		font = "fonts/font_univers_530_medium",
		font_size = 14 * self._scale_tweak_data.small_font_multiplier,
		color = Color.white,
		align = "left",
		layer = base_layer + 1
	})
	self._tips_text = saferect_panel:text({
		text_id = arg.load_level_data.tip_id,
		font = "fonts/font_univers_530_medium",
		font_size = 14 * self._scale_tweak_data.small_font_multiplier,
		color = Color.white,
		align = "left",
		wrap = true,
		word_wrap = true,
		layer = base_layer + 1
	})
	self._tips_text:set_text(string.upper(self._tips_text:text()))
	self._rotating_rect_gui = saferect_panel:rect({
		visible = false,
		color = Color.white,
		w = 15,
		h = 15,
		layer = base_layer + 1
	})
	self._text_gui = saferect_panel:text({
		visible = false,
		text = "",
		font = "fonts/font_univers_530_bold",
		font_size = 32,
		color = Color.white,
		layer = base_layer + 1
	})
	self._bar_border_gui = saferect_panel:rect({
		visible = false,
		color = Color(0.3, 0.3, 0.3),
		layer = base_layer + 1
	})
	self._bar_bg_gui = saferect_panel:rect({
		visible = false,
		color = Color.black,
		layer = base_layer + 2
	})
	self._bar_gui = saferect_panel:rect({
		visible = false,
		color = Color.white,
		layer = base_layer + 3
	})
	self._briefing_text = saferect_panel:text({
		text_id = self._level_tweak_data.briefing_id or "debug_test_briefing",
		font = "fonts/font_univers_530_medium",
		font_size = 14 * self._scale_tweak_data.small_font_multiplier,
		color = Color.white,
		align = "left",
		wrap = true,
		word_wrap = true,
		layer = base_layer + 1,
		w = 128,
		h = 128
	})
	self._briefing_text:set_text(string.upper(self._briefing_text:text()))
	self._indicator = saferect_panel:bitmap({
		name = "indicator",
		texture = "guis/textures/icon_loading",
		layer = base_layer + 2
	})
	self._level_title_text = saferect_panel:text({
		y = 0,
		text_id = "debug_loading_level",
		font = "fonts/font_univers_530_bold",
		font_size = 32 * self._scale_tweak_data.default_font_multiplier,
		color = Color.white,
		align = "left",
		halign = "left",
		vertical = "bottom",
		layer = base_layer + 1,
		h = 24
	})
	self._level_title_text:set_text(string.upper((self._level_tweak_data.name and self._level_tweak_data.name or "") .. " > " .. self._level_title_text:text()))
	self._stonecold_small_logo = saferect_panel:bitmap({
		name = "stonecold_small_logo",
		texture = self._gui_tweak_data.stonecold_small_logo,
		texture_rect = {
			0,
			0,
			256,
			56
		},
		layer = base_layer + 1,
		h = 56
	})
	self._stonecold_small_logo:set_size(256 * self._scale_tweak_data.menu_logo_multiplier, 56 * self._scale_tweak_data.menu_logo_multiplier)
	self._tv_panel = saferect_panel:panel({visible = false, layer = base_layer})
	self._tv_bar = self._tv_panel:rect({
		visible = true,
		color = Color.red,
		layer = base_layer + 2,
		h = 16
	})
	local text_id
	self._tv_text = self._tv_panel:text({
		visible = true,
		text_id = text_id,
		text = not text_id and "BREAKING NEWS!",
		font = "fonts/font_univers_530_medium",
		font_size = 14,
		color = Color.white,
		layer = base_layer + 3
	})
	self._tv_text:set_text(string.upper(self._tv_text:text()))
	self._tv_text_gradient = self._tv_panel:gradient({
		x = 0,
		y = 0,
		h = 14,
		layer = base_layer + 2,
		orientation = "vertical",
		gradient_points = {
			0,
			Color.black:with_alpha(0),
			1,
			Color.black:with_alpha(1)
		}
	})
	self._challenges_topic = saferect_panel:text({
		text_id = "menu_near_completion_challenges",
		font = "fonts/font_univers_530_bold",
		font_size = self._menu_tweak_data.loading_challenge_name_font_size,
		color = Color.white,
		align = "left",
		layer = base_layer + 1
	})
	self._challenges_topic:set_shape(self._challenges_topic:text_rect())
	self._challenges = {}
	for i, challenge in ipairs(challenges) do
		local panel = saferect_panel:panel({
			layer = base_layer,
			w = 140 * self._scale_tweak_data.loading_challenge_bar_scale,
			h = 22 * self._scale_tweak_data.loading_challenge_bar_scale
		})
		local bg_bar = panel:rect({
			x = 0,
			y = 0,
			w = panel:w(),
			h = panel:h(),
			color = Color.black:with_alpha(0.5),
			align = "center",
			halign = "center",
			vertical = "center",
			layer = base_layer + 1
		})
		local bar = panel:gradient({
			orientation = "vertical",
			gradient_points = {
				0,
				Color(1, 1, 0.65882355, 0),
				1,
				Color(1, 0.6039216, 0.4, 0)
			},
			x = 2 * self._scale_tweak_data.loading_challenge_bar_scale,
			y = 2 * self._scale_tweak_data.loading_challenge_bar_scale,
			w = (bg_bar:w() - 4 * self._scale_tweak_data.loading_challenge_bar_scale) * (challenge.amount / challenge.count),
			h = bg_bar:h() - 4 * self._scale_tweak_data.loading_challenge_bar_scale,
			layer = base_layer + 2,
			align = "center",
			halign = "center",
			vertical = "center"
		})
		local progress_text = panel:text({
			font = self.font,
			font_size = self._menu_tweak_data.loading_challenge_progress_font_size,
			font = "fonts/font_univers_530_bold",
			x = 0,
			y = 0,
			h = bg_bar:h(),
			w = bg_bar:w(),
			align = "center",
			halign = "center",
			vertical = "center",
			valign = "center",
			color = Color.white,
			layer = base_layer + 3,
			text = challenge.amount .. "/" .. challenge.count
		})
		local text = saferect_panel:text({
			text = string.upper(challenge.name),
			font = "fonts/font_univers_530_bold",
			font_size = self._menu_tweak_data.loading_challenge_name_font_size,
			color = Color.white,
			align = "left",
			layer = base_layer + 1
		})
		text:set_shape(text:text_rect())
		table.insert(self._challenges, {panel = panel, text = text})
	end
	local text = self._text_gui:text()
	self._init_text = self._text_gui:text()
	self._dot_count = 0
	self._max_dot_count = 4
	self._init_progress = 0
	self._fake_progress = 0
	self._max_bar_width = 0
	self:setup(res, progress)
end
function LevelLoadingScreenGuiScript:setup(res, progress)
	self._saferect_bottom_y = self._saferect_panel:h() - self._gui_tweak_data.upper_saferect_border
	self._level_title_text:set_shape(0, 0, self._safe_rect_pixels.width, self._gui_tweak_data.upper_saferect_border - self._gui_tweak_data.border_pad)
	local _, _, w, _ = self._level_title_text:text_rect()
	self._level_title_text:set_w(w)
	self._bg_gui:set_size(self._res.y * 2, self._res.y)
	self._bg_gui:set_center(self._bg_gui:parent():center())
	if self._res and self._res.y <= 601 then
		self._briefing_text:set_w(self._briefing_text:parent():w())
		local _, _, w, h = self._briefing_text:text_rect()
		self._briefing_text:set_size(w, h)
		self._briefing_text:set_lefttop(0, self._briefing_text:parent():h() / 2)
	else
		self._briefing_text:set_w(self._briefing_text:parent():w() * 0.5)
		local _, _, w, h = self._briefing_text:text_rect()
		self._briefing_text:set_size(w, h)
		self._briefing_text:set_rightbottom(self._briefing_text:parent():w(), self._saferect_bottom_y - self._gui_tweak_data.border_pad)
	end
	self._text_gui:set_text(self:get_loading_text(self._max_dot_count))
	local text_x, text_y, text_w, text_h = self._text_gui:text_rect()
	text_x = (self._text_gui:parent():w() - text_w) / 2
	text_y = self._gui_tweak_data.upper_saferect_border - 16 - text_h
	self._text_gui:set_shape(text_x, text_y, text_w, text_h)
	self._text_gui:set_text(self._init_text)
	self._text_gui:set_y(text_y)
	self._rotating_rect_gui:set_x(text_x - self._rotating_rect_gui:h() * 1.5)
	self._rotating_rect_gui:set_y(text_y)
	local border_size = 2
	local bar_size = 2
	self._bar_border_gui:set_shape(self._rotating_rect_gui:x(), text_y + text_h + 2, text_x + text_w - self._rotating_rect_gui:x(), border_size * 2 + bar_size)
	self._bar_bg_gui:set_shape(self._bar_border_gui:x() + bar_size, self._bar_border_gui:y() + bar_size, self._bar_border_gui:w() - border_size * 2, bar_size)
	self._bar_gui:set_shape(self._bar_bg_gui:x(), self._bar_bg_gui:y(), 0, self._bar_bg_gui:h())
	self._max_bar_width = self._bar_bg_gui:w()
	local p = 1.775
	local h = self._saferect_panel:h() - self._briefing_text:top()
	self._tv_panel:set_size(h * p, h)
	self._tv_panel:set_bottom(self._saferect_panel:h())
	self._tv_bar:set_bottom(self._tv_panel:h())
	self._tv_text_gradient:set_bottom(self._tv_bar:top())
	local x, y, w, h = self._tv_text:text_rect()
	self._tv_text:set_size(w, h)
	self._tv_text:set_center_y(self._tv_bar:center_y())
	self._tv_text:set_x(self._tv_panel:w() / 2)
	self._stonecold_small_logo:set_righttop(self._stonecold_small_logo:parent():righttop())
	self._stonecold_small_logo:set_bottom(self._gui_tweak_data.upper_saferect_border - self._gui_tweak_data.border_pad)
	self._top_y = self._safe_rect_pixels.y + self._gui_tweak_data.upper_saferect_border
	self._bottom_y = self._safe_rect_pixels.y + self._saferect_panel:h() - self._gui_tweak_data.upper_saferect_border
	self._upper_frame_line:set_bottom(self._top_y)
	self._lower_frame_line:set_top(self._bottom_y)
	self._upper_frame_gradient:set_h(self._safe_rect_pixels.y + self._gui_tweak_data.upper_saferect_border)
	self._lower_frame_gradient:set_top(self._lower_frame_line:bottom())
	self._lower_frame_gradient:set_h(res.y - (self._safe_rect_pixels.y + self._saferect_panel:h() - self._gui_tweak_data.briefing_text.h - self._gui_tweak_data.border_pad))
	local tip_top = self._gui_tweak_data.upper_saferect_border + self._gui_tweak_data.border_pad + 14
	local _, _, w, h = self._tips_head_line:text_rect()
	self._tips_head_line:set_size(w, h)
	self._tips_head_line:set_top(tip_top)
	local offset = 20
	self._tips_text:set_w(self._saferect_panel:w() - self._tips_head_line:w() - offset)
	self._tips_text:set_top(tip_top)
	self._tips_text:set_left(self._tips_head_line:right() + offset)
	if progress > 0 then
		self._init_progress = progress
	end
	for i, challenge in ipairs(self._challenges) do
		local h = challenge.panel:h()
		challenge.panel:set_bottom(self._saferect_bottom_y - (h + 2) * (#self._challenges - i))
		challenge.text:set_left(challenge.panel:right() + 8 * self._scale_tweak_data.loading_challenge_bar_scale)
		challenge.text:set_center_y(challenge.panel:center_y())
	end
	self._challenges_topic:set_visible(self._challenges[1] and true or false)
	if self._challenges[1] then
		self._challenges_topic:set_bottom(self._challenges[1].panel:top() - 4)
	end
	self._indicator:set_left(self._level_title_text:right() + 8)
	self._indicator:set_bottom(self._gui_tweak_data.upper_saferect_border - self._gui_tweak_data.border_pad)
end
function LevelLoadingScreenGuiScript:update(progress, t, dt)
	if self._tv_text:right() < 0 then
		self._tv_text:set_x(self._tv_panel:w())
	end
	self._tv_text:set_x(self._tv_text:x() - 60 * dt)
	self._dot_count = (self._dot_count + dt * 2) % self._max_dot_count
	self._text_gui:set_text(self:get_loading_text(self._dot_count))
	self._indicator:rotate(180 * dt)
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
function LevelLoadingScreenGuiScript:get_loading_text(dot_count)
	return self._init_text .. string.rep(".", math.floor(dot_count))
end
function LevelLoadingScreenGuiScript:set_text(text)
	self._text_gui:set_text(text)
	self._init_text = text
end
function LevelLoadingScreenGuiScript:destroy()
	if alive(self._saferect) then
		self._scene_gui:destroy_workspace(self._saferect)
		self._saferect = nil
	end
	if alive(self._workspace) then
		self._scene_gui:destroy_workspace(self._workspace)
		self._workspace = nil
	end
	if alive(self._ws) then
		self._scene_gui:destroy_workspace(self._ws)
		self._ws = nil
	end
end
function LevelLoadingScreenGuiScript:visible()
	return self._ws:visible()
end
function LevelLoadingScreenGuiScript:set_visible(visible)
	if visible then
		self._ws:show()
	else
		self._ws:hide()
	end
end
