core:import("CoreMenuNodeGui")
MenuNodeGui = MenuNodeGui or class(CoreMenuNodeGui.NodeGui)
function MenuNodeGui:init(node, layer, parameters)
	print("node", node:parameters().name)
	local name = node:parameters().name
	local lang_mods = {}
	lang_mods[Idstring("german"):key()] = name == "kit" and 0.95 or name == "challenges_active" and 0.875 or name == "challenges_awarded" and 0.875 or 0.9
	lang_mods[Idstring("french"):key()] = name == "kit" and 0.975 or name == "challenges_active" and 0.874 or name == "challenges_awarded" and 0.874 or name == "upgrades_support" and 0.875 or 0.9
	lang_mods[Idstring("italian"):key()] = name == "kit" and 0.975 or name == "challenges_active" and 0.875 or name == "challenges_awarded" and 0.875 or 0.95
	lang_mods[Idstring("spanish"):key()] = name == "kit" and 1 or name == "challenges_active" and 0.84 or name == "challenges_awarded" and 0.84 or (name == "upgrades_assault" or name == "upgrades_sharpshooter" or name == "upgrades_support") and 0.975 or 0.925
	lang_mods[Idstring("english"):key()] = name == "challenges_active" and 0.925 or name == "challenges_awarded" and 0.925 or 1
	local mod = lang_mods[SystemInfo:language():key()] or 1
	self._align_line_proportions = math.max((node:parameters().align_line or 0.75) * mod, 0.5)
	self._align_line_padding = 10 * tweak_data.scale.align_line_padding_multiplier
	self._use_info_rect = node:parameters().use_info_rect or node:parameters().use_info_rect == nil and true
	self._stencil_align = node:parameters().stencil_align or "right"
	self._stencil_align_percent = node:parameters().stencil_align_percent or 0
	self._stencil_image = node:parameters().stencil_image
	self._bg_visible = node:parameters().hide_bg
	self._bg_visible = self._bg_visible == nil
	MenuNodeGui.super.init(self, node, layer, parameters)
end
function MenuNodeGui:_mid_align()
	local safe_rect = managers.viewport:get_safe_rect_pixels()
	return safe_rect.width * self._align_line_proportions
end
function MenuNodeGui:_right_align(align_line_proportions)
	local safe_rect = managers.viewport:get_safe_rect_pixels()
	return safe_rect.width * (align_line_proportions or self._align_line_proportions) + self._align_line_padding
end
function MenuNodeGui:_left_align(align_line_proportions)
	local safe_rect = managers.viewport:get_safe_rect_pixels()
	return safe_rect.width * (align_line_proportions or self._align_line_proportions) - self._align_line_padding
end
function MenuNodeGui:_world_right_align()
	local safe_rect = managers.viewport:get_safe_rect_pixels()
	return safe_rect.x + safe_rect.width * self._align_line_proportions + self._align_line_padding
end
function MenuNodeGui:_world_left_align()
	local safe_rect = managers.viewport:get_safe_rect_pixels()
	return safe_rect.x + safe_rect.width * self._align_line_proportions - self._align_line_padding
end
function MenuNodeGui:_setup_panels(node)
	MenuNodeGui.super._setup_panels(self, node)
	local safe_rect_pixels = managers.viewport:get_safe_rect_pixels()
	local res = RenderSettings.resolution
	self._topic_panel = self.ws:panel():panel({
		x = safe_rect_pixels.x,
		y = safe_rect_pixels.y,
		w = safe_rect_pixels.width,
		h = tweak_data.load_level.upper_saferect_border
	})
	self._topic_text = self._topic_panel:text({
		text = managers.menu:active_menu().renderer:current_menu_text(node:parameters().topic_id),
		x = 0,
		y = 0,
		w = safe_rect_pixels.width,
		h = tweak_data.load_level.upper_saferect_border - tweak_data.load_level.border_pad,
		font_size = tweak_data.menu.topic_font_size,
		align = "left",
		halign = "left",
		vertical = "bottom",
		font = self.font,
		color = self.row_item_color,
		layer = self.layers.items
	})
	self:_create_align(node)
	self:_create_marker(node)
	local w = 200
	local h = 20
	local base = 20
	local height = 15
	self._list_arrows = {}
	self._list_arrows.up = self.ws:panel():polygon({
		visible = false,
		x = self:_mid_align(),
		y = 0,
		w = w,
		h = h,
		triangles = {
			Vector3(w / 2 - base / 2, h, 0),
			Vector3(w / 2 + base / 2, h, 0),
			Vector3(w / 2, h - height, 0)
		},
		layer = self.layers.items,
		color = self.row_item_color:with_alpha(1)
	})
	self._list_arrows.down = self.ws:panel():polygon({
		visible = false,
		x = self:_mid_align(),
		y = 0,
		w = w,
		h = h,
		triangles = {
			Vector3(w / 2 - base / 2, 0, 0),
			Vector3(w / 2 + base / 2, 0, 0),
			Vector3(w / 2, height, 0)
		},
		layer = self.layers.items,
		color = self.row_item_color:with_alpha(1)
	})
	self._info_bg_rect = self.safe_rect_panel:rect({
		visible = self._use_info_rect,
		x = 0,
		y = tweak_data.load_level.upper_saferect_border,
		w = safe_rect_pixels.width * 0.41,
		h = safe_rect_pixels.height - tweak_data.load_level.upper_saferect_border * 2,
		layer = self.layers.first,
		color = Color(0.5, 0, 0, 0)
	})
	self:_create_legends(node)
	managers.menu:active_menu().renderer:set_stencil_image(self._stencil_image)
	managers.menu:active_menu().renderer:set_stencil_align(self._stencil_align, self._stencil_align_percent)
	managers.menu:active_menu().renderer:set_bg_visible(self._bg_visible)
	local mini_info = self.safe_rect_panel:panel({
		x = 0,
		y = 0,
		w = 0,
		h = 0
	})
	local mini_text = mini_info:text({
		x = 0,
		y = 0,
		align = "left",
		halign = "top",
		vertical = "top",
		font = tweak_data.menu.default_font,
		font_size = tweak_data.menu.default_font_size,
		color = Color.white,
		layer = self.layers.items,
		text = "",
		wrap = true,
		word_wrap = true
	})
	mini_info:set_width((self._info_bg_rect:w() - tweak_data.menu.info_padding * 2) * 2)
	mini_text:set_width(mini_info:w())
	mini_info:set_height(100)
	mini_text:set_height(100)
	mini_info:set_top(self._info_bg_rect:bottom() + tweak_data.menu.info_padding)
	mini_text:set_top(0)
	mini_info:set_left(tweak_data.menu.info_padding)
	mini_text:set_left(0)
	self._mini_info_text = mini_text
	if node.mini_info then
		self:set_mini_info(node.mini_info)
	end
end
function MenuNodeGui:set_mini_info(text)
	self._mini_info_text:set_text(text)
end
function MenuNodeGui:_create_legends(node)
	local safe_rect_pixels = managers.viewport:get_safe_rect_pixels()
	local res = RenderSettings.resolution
	local visible = not managers.menu:is_pc_controller()
	local is_pc = managers.menu:is_pc_controller()
	self._legends_panel = self.ws:panel():panel({
		visible = visible,
		x = safe_rect_pixels.x,
		y = safe_rect_pixels.y,
		w = safe_rect_pixels.width,
		h = safe_rect_pixels.height
	})
	local t_text = ""
	local has_pc_legend = false
	for i, legend in ipairs(node:legends()) do
		if not is_pc or legend.pc then
			has_pc_legend = has_pc_legend or legend.pc
			local spacing = i > 1 and "  |  " or ""
			t_text = t_text .. spacing .. string.upper(managers.localization:text(legend.string_id, {
				BTN_UPDATE = managers.localization:btn_macro("menu_update")
			}))
		end
	end
	if is_pc then
		self._legends_panel:set_visible(has_pc_legend)
	end
	local text = self._legends_panel:text({
		text = t_text,
		font = self.font,
		font_size = self.font_size,
		color = self.color,
		layer = self.layers.items
	})
	local _, _, w, h = text:text_rect()
	text:set_size(w, h)
	self:_layout_legends()
end
function MenuNodeGui:_create_align(node)
	self._align_data = {}
	self._align_data.panel = self._main_panel:panel({
		x = self:_left_align(),
		y = 0,
		w = self._align_line_padding * 2,
		h = self._main_panel:h(),
		layer = self.layers.marker
	})
end
function MenuNodeGui:_create_marker(node)
	self._marker_data = {}
	self._marker_data.marker = self.item_panel:panel({
		x = 0,
		y = 0,
		w = 1280,
		h = 10,
		layer = self.layers.marker
	})
	self._marker_data.rect = self._marker_data.marker:rect({
		visible = false,
		x = 0,
		y = 0,
		w = 10,
		h = 10,
		layer = 1
	})
	self._marker_data.gradient = self._marker_data.marker:gradient({
		x = 0,
		y = 0,
		h = 10,
		layer = 0,
		gradient_points = {
			0,
			tweak_data.menu.highlight_background_color_left,
			1,
			tweak_data.menu.highlight_background_color_right
		}
	})
end
function MenuNodeGui:_setup_main_panel(safe_rect, shape)
	local res = RenderSettings.resolution
	shape = shape or {}
	local x = shape.x or safe_rect.x
	local y = shape.y or safe_rect.y + self._topic_panel:height()
	local w = shape.w or safe_rect.width
	local h = shape.h or safe_rect.height - self._topic_panel:height() * 2
	self._main_panel:set_shape(x, y, w, h)
	self._align_data.panel:set_h(self._main_panel:h())
	self._list_arrows.up:set_h(20 * tweak_data.scale.menu_arrow_padding_multiplier)
	self._list_arrows.up:set_lefttop(self._align_data.panel:world_center(), self._align_data.panel:world_top() + 1.5)
	self._list_arrows.down:set_h(20 * tweak_data.scale.menu_arrow_padding_multiplier)
	self._list_arrows.down:set_leftbottom(self._align_data.panel:world_center(), self._align_data.panel:world_bottom() - 1.5)
	self._legends_panel:set_top(self._main_panel:bottom() + tweak_data.load_level.border_pad)
	self._main_panel:set_y(self._main_panel:y() + 24 * tweak_data.scale.menu_arrow_padding_multiplier)
	self._main_panel:set_h(self._main_panel:h() - 48 * tweak_data.scale.menu_arrow_padding_multiplier)
end
function MenuNodeGui:_setup_item_panel(safe_rect, res)
	self.item_panel:set_shape(0, 0, safe_rect.width, self:_item_panel_height())
	self.item_panel:set_w(safe_rect.width)
	self.background:set_shape(0, 0, res.x, res.y)
	if self._main_panel:h() < self.item_panel:h() then
		self._list_arrows.up:set_visible(true)
		self._list_arrows.down:set_visible(true)
		self._list_arrows.up:set_color(self._list_arrows.up:color():with_alpha(0.5))
	end
end
function MenuNodeGui:_create_menu_item(row_item)
	local safe_rect = managers.viewport:get_safe_rect_pixels()
	local align_x = safe_rect.width * self._align_line_proportions
	if row_item.gui_panel then
		self.item_panel:remove(row_item.gui_panel)
	end
	if row_item.item:parameters().back then
		row_item.gui_panel = self.back_panel:text({
			font_size = self.font_size,
			align = "right",
			halign = "right",
			vertical = "bottom",
			hvertical = "bottom",
			font = row_item.font,
			color = row_item.color,
			layer = self.layers.items,
			text = row_item.text
		})
		local x, y, w, h = row_item.gui_panel:text_rect()
		row_item.gui_panel:set_height(h)
		local safe_rect = managers.viewport:get_safe_rect_pixels()
		row_item.gui_panel:set_width(safe_rect.width / 2)
	elseif row_item.type == "slider" then
		row_item.gui_panel = self.item_panel:panel({
			w = self.item_panel:w()
		})
		row_item.gui_text = self:_text_item_part(row_item, row_item.gui_panel, self:_right_align())
		local _, _, w, h = row_item.gui_text:text_rect()
		row_item.gui_panel:set_h(h)
		local bar_w = 192
		row_item.gui_slider_bg = row_item.gui_panel:rect({
			x = self:_left_align() - bar_w,
			y = h / 2 - 11,
			w = bar_w,
			h = 22,
			align = "center",
			halign = "center",
			vertical = "center",
			color = Color.black:with_alpha(0.5),
			layer = self.layers.items - 1
		})
		row_item.gui_slider_gfx = row_item.gui_panel:gradient({
			orientation = "vertical",
			gradient_points = {
				0,
				Color(0.5, 1, 0.65882355, 0),
				1,
				Color(0.5, 0.6039216, 0.4, 0)
			},
			x = self:_left_align() - bar_w + 2,
			y = row_item.gui_slider_bg:y() + 2,
			w = (row_item.gui_slider_bg:w() - 4) * 0.23,
			h = row_item.gui_slider_bg:h() - 4,
			align = "center",
			halign = "center",
			vertical = "center",
			color = self.color,
			layer = self.layers.items
		})
		row_item.gui_slider = row_item.gui_panel:rect({
			color = row_item.color:with_alpha(0),
			layer = self.layers.items,
			w = 100,
			h = row_item.gui_slider_bg:h() - 4
		})
		row_item.gui_slider_marker = row_item.gui_panel:bitmap({
			texture = "guis/textures/menu_icons",
			texture_rect = {
				0,
				0,
				24,
				28
			},
			layer = self.layers.items + 2
		})
		row_item.gui_slider_text = row_item.gui_panel:text({
			font_size = tweak_data.menu.stats_font_size,
			x = self:_right_align(),
			y = 0,
			h = h,
			w = row_item.gui_slider_bg:w(),
			align = "center",
			halign = "center",
			vertical = "center",
			valign = "center",
			font = self.font,
			color = self.color,
			layer = self.layers.items + 1,
			text = "" .. math.floor(0) .. "%",
			render_template = Idstring("VertexColorTextured")
		})
		if row_item.help_text then
			self:_create_info_panel(row_item)
		end
		self:_align_slider(row_item)
	elseif row_item.type == "toggle" then
		row_item.gui_panel = self.item_panel:panel({
			w = self.item_panel:w()
		})
		row_item.gui_text = self:_text_item_part(row_item, row_item.gui_panel, self:_right_align())
		row_item.gui_text:set_text(string.upper(row_item.text))
		if row_item.item:parameter("title_id") then
			row_item.gui_title = self:_text_item_part(row_item, row_item.gui_panel, self:_right_align(), "right")
			row_item.gui_title:set_text(managers.localization:text(row_item.item:parameter("title_id")))
		end
		if not row_item.item:enabled() then
			row_item.color = tweak_data.menu.default_disabled_text_color
			row_item.row_item_color = row_item.color
			row_item.gui_text:set_color(row_item.color)
		end
		if row_item.item:selected_option():parameters().text_id then
			row_item.gui_option = self:_text_item_part(row_item, row_item.gui_panel, self:_left_align())
			row_item.gui_option:set_align("right")
		end
		if row_item.item:selected_option():parameters().icon then
			row_item.gui_icon = row_item.gui_panel:bitmap({
				layer = self.layers.items,
				x = 0,
				y = 0,
				texture_rect = {
					0,
					0,
					24,
					24
				},
				texture = row_item.item:selected_option():parameters().icon
			})
			row_item.gui_icon:set_color(tweak_data.menu.default_disabled_text_color)
		end
		if row_item.help_text then
			self:_create_info_panel(row_item)
		end
		if row_item.item:info_panel() == "lobby_campaign" then
			self:_set_lobby_campaign(row_item)
		end
		self:_align_toggle(row_item)
	elseif row_item.type == "level" then
		row_item.gui_panel = self:_text_item_part(row_item, self.item_panel, self:_right_align())
		row_item.gui_panel:set_text(string.upper(row_item.gui_panel:text()))
		row_item.gui_level_panel = self._main_panel:panel({
			visible = false,
			layer = self.layers.items,
			x = 0,
			y = 0,
			w = self:_left_align(),
			h = self._main_panel:h()
		})
		local level_data = row_item.item:parameters().level_id
		level_data = tweak_data.levels[level_data]
		local movie = level_data and level_data.movie
		local description = level_data and level_data.briefing_id and managers.localization:text(level_data.briefing_id) or "Missing description text"
		local image = level_data and level_data.loading_image or "guis/textures/menu/missing_level"
		row_item.level_title = row_item.gui_level_panel:text({
			layer = 1,
			text = string.upper(row_item.gui_panel:text()),
			font = self.font,
			font_size = self.font_size,
			color = row_item.color,
			align = "left",
			vertical = "top",
			wrap = false,
			word_wrap = false,
			w = 50,
			h = 128
		})
		row_item.level_text = row_item.gui_level_panel:text({
			layer = 1,
			text = string.upper(description),
			font = tweak_data.menu.small_font,
			font_size = tweak_data.menu.small_font_size,
			color = row_item.color,
			align = "left",
			vertical = "top",
			wrap = true,
			word_wrap = true,
			w = 50,
			h = 128
		})
		if level_data.movie and SystemInfo:platform() == Idstring("WIN32") then
			row_item.level_movie = row_item.gui_level_panel:video({
				visible = true,
				video = level_data.movie,
				loop = true
			})
			row_item.level_movie:pause()
			managers.video:add_video(row_item.level_movie)
		end
		self:_align_normal(row_item)
	elseif row_item.type == "challenge" then
		local challenge_data = managers.challenges:challenge(row_item.item:parameter("challenge"))
		local progress_data = managers.challenges:active_challenge(row_item.item:parameter("challenge"))
		progress_data = progress_data or {
			amount = challenge_data.count
		}
		local chl_color = row_item.item:parameter("awarded") and tweak_data.menu.awarded_challenge_color or row_item.color
		row_item.gui_panel = self.item_panel:panel({
			w = self.item_panel:w()
		})
		row_item.challenge_name = self:_text_item_part(row_item, row_item.gui_panel, self:_right_align())
		row_item.challenge_name:set_font_size(tweak_data.menu.challenges_font_size)
		row_item.challenge_name:set_kern(tweak_data.scale.upgrade_menu_kern)
		row_item.challenge_name:set_color(chl_color)
		row_item.gui_info_panel = self.safe_rect_panel:panel({
			visible = false,
			layer = self.layers.items,
			x = 0,
			y = 0,
			w = self:_left_align(),
			h = self._main_panel:h()
		})
		row_item.description_text = row_item.gui_info_panel:text({
			text = row_item.item:parameter("description"),
			font = tweak_data.menu.small_font,
			font_size = tweak_data.menu.small_font_size,
			color = row_item.color,
			align = "left",
			vertical = "top",
			wrap = true,
			word_wrap = true
		})
		row_item.challenge_hl = row_item.gui_info_panel:text({
			text = row_item.text,
			layer = self.layers.items,
			font = self.font,
			font_size = tweak_data.menu.challenges_font_size,
			color = row_item.color,
			align = "left",
			vertical = "left",
			wrap = true,
			word_wrap = true
		})
		row_item.reward_panel = row_item.gui_info_panel:panel({
			visible = true,
			layer = self.layers.items,
			x = 0,
			y = 0,
			w = self:_left_align(),
			h = self._main_panel:h()
		})
		local text = managers.localization:text("menu_reward_xp", {
			XP = managers.experience:cash_string(challenge_data.xp)
		})
		row_item.reward_text = row_item.reward_panel:text({
			text = text,
			layer = self.layers.items,
			font = self.font,
			font_size = tweak_data.menu.challenges_font_size,
			color = row_item.color,
			align = "left",
			vertical = "left"
		})
		local _, _, w, h = row_item.challenge_name:text_rect()
		row_item.gui_panel:set_h(h)
		local bar_w = self:_left_align() - safe_rect.width / 2
		if challenge_data.count and 1 < challenge_data.count then
			local bg_bar = row_item.gui_panel:rect({
				x = self:_left_align() - bar_w,
				y = h / 2 - 11,
				w = bar_w,
				h = 22,
				align = "center",
				halign = "center",
				vertical = "center",
				color = Color.black:with_alpha(0.5),
				layer = self.layers.items - 1
			})
			row_item.bg_bar = bg_bar
			local bar = row_item.gui_panel:gradient({
				orientation = "vertical",
				gradient_points = {
					0,
					Color(0.5, 1, 0.65882355, 0),
					1,
					Color(0.5, 0.6039216, 0.4, 0)
				},
				x = self:_left_align() - bar_w + 2,
				y = bg_bar:y() + 2,
				w = (bg_bar:w() - 4) * (progress_data.amount / challenge_data.count),
				h = bg_bar:h() - 4,
				align = "center",
				halign = "center",
				vertical = "center",
				color = self.color,
				layer = self.layers.items
			})
			row_item.bar = bar
			local progress_text = row_item.gui_panel:text({
				font_size = tweak_data.menu.challenges_font_size,
				x = self:_left_align() - bar_w,
				y = 0,
				h = h,
				w = bg_bar:w(),
				align = "center",
				halign = "center",
				vertical = "center",
				valign = "center",
				font = self.font,
				color = self.color,
				layer = self.layers.items + 1,
				text = progress_data.amount .. "/" .. challenge_data.count,
				render_template = Idstring("VertexColorTextured")
			})
			row_item.progress_text = progress_text
		end
		self:_align_challenge(row_item)
	elseif row_item.type == "upgrade" then
		local upgrade_id = row_item.item:parameters().upgrade_id
		row_item.gui_panel = self.item_panel:panel({
			w = self.item_panel:w()
		})
		row_item.upgrade_name = self:_text_item_part(row_item, row_item.gui_panel, self:_right_align())
		row_item.upgrade_name:set_font_size(tweak_data.menu.upgrades_font_size)
		if row_item.item:parameters().topic_text then
			row_item.topic_text = self:_text_item_part(row_item, row_item.gui_panel, self:_left_align())
			row_item.topic_text:set_align("right")
			row_item.topic_text:set_font_size(tweak_data.menu.upgrades_font_size)
			row_item.topic_text:set_text(row_item.item:parameters().topic_text)
		end
		if row_item.item:name() == "upgrade_lock" then
			row_item.not_aquired = true
			row_item.locked = true
		else
			row_item.not_aquired = managers.upgrades:progress_by_tree(row_item.item:parameters().tree) < row_item.item:parameters().step
			row_item.locked = managers.upgrades:is_locked(row_item.item:parameters().step)
		end
		local upg_color = row_item.locked and tweak_data.menu.upgrade_locked_color or row_item.not_aquired and tweak_data.menu.upgrade_not_aquired_color or row_item.color
		if managers.upgrades:aquired(upgrade_id) then
			upg_color = row_item.color
		end
		row_item.upgrade_name:set_color(upg_color)
		if row_item.topic_text then
			row_item.topic_text:set_color(upg_color)
		end
		if row_item.item:name() ~= "upgrade_lock" then
			row_item.gui_info_panel = self.safe_rect_panel:panel({
				visible = false,
				layer = self.layers.items,
				x = 0,
				y = 0,
				w = self:_left_align(),
				h = self._main_panel:h()
			})
			local image, rect = managers.upgrades:image(upgrade_id)
			row_item.upgrade_info_image_rect = rect
			row_item.upgrade_info_image = row_item.gui_info_panel:bitmap({
				texture = image,
				texture_rect = rect,
				visible = true,
				x = 0,
				y = 0,
				w = 340,
				h = 150
			})
			row_item.upgrade_info_title = row_item.gui_info_panel:text({
				x = 0,
				y = 0,
				align = "left",
				halign = "top",
				vertical = "top",
				font_size = self.font_size,
				font = row_item.font,
				color = Color.white,
				wrap = true,
				word_wrap = true,
				layer = self.layers.items,
				text = string.upper(managers.upgrades:complete_title(upgrade_id, " > "))
			})
			row_item.upgrade_info_text = row_item.gui_info_panel:text({
				x = 0,
				y = 0,
				align = "left",
				halign = "top",
				vertical = "top",
				font = tweak_data.menu.small_font,
				font_size = tweak_data.menu.small_font_size,
				color = Color.white,
				layer = self.layers.items,
				text = string.upper(managers.upgrades:description(upgrade_id)),
				wrap = true,
				word_wrap = true
			})
			if tweak_data.upgrades.visual.upgrade[upgrade_id] and not tweak_data.upgrades.visual.upgrade[upgrade_id].base then
				row_item.upgrade_icon = row_item.gui_panel:bitmap({
					texture = "guis/textures/icon_star",
					texture_rect = {
						0,
						0,
						32,
						32
					},
					layer = self.layers.items,
					color = upg_color
				})
				if managers.upgrades:aquired(upgrade_id) then
					row_item.toggle_text = row_item.gui_info_panel:text({
						x = 0,
						y = 0,
						align = "left",
						halign = "top",
						vertical = "top",
						font = tweak_data.menu.small_font,
						font_size = tweak_data.menu.small_font_size,
						color = Color.white,
						layer = self.layers.items,
						text = "",
						wrap = true,
						word_wrap = true
					})
					self:_reload_upgrade(row_item)
				end
			end
		end
		self:_align_upgrade(row_item)
	elseif row_item.type == "multi_choice" then
		local right_align = self:_right_align()
		row_item.gui_panel = self.item_panel:panel({
			w = self.item_panel:w()
		})
		row_item.gui_text = self:_text_item_part(row_item, row_item.gui_panel, right_align, "right")
		row_item.gui_text:set_wrap(true)
		row_item.gui_text:set_word_wrap(true)
		row_item.choice_panel = row_item.gui_panel:panel({
			w = self.item_panel:w()
		})
		row_item.choice_text = row_item.choice_panel:text({
			font_size = tweak_data.menu.multichoice_font_size,
			x = right_align,
			y = 0,
			align = "left",
			halign = "center",
			vertical = "center",
			font = row_item.font,
			color = tweak_data.menu.default_changeable_text_color,
			layer = self.layers.items,
			text = string.upper(""),
			render_template = Idstring("VertexColorTextured")
		})
		local w = 20
		local h = 20
		local base = 20
		local height = 15
		row_item.arrow_left = row_item.gui_panel:bitmap({
			texture = "guis/textures/menu_arrows",
			texture_rect = {
				0,
				0,
				24,
				24
			},
			color = Color(0.5, 0.5, 0.5),
			visible = row_item.item:arrow_visible(),
			x = 0,
			y = 0,
			layer = self.layers.items
		})
		row_item.arrow_right = row_item.gui_panel:bitmap({
			texture = "guis/textures/menu_arrows",
			texture_rect = {
				24,
				0,
				-24,
				24
			},
			color = Color(0.5, 0.5, 0.5),
			visible = row_item.item:arrow_visible(),
			x = 0,
			y = 0,
			layer = self.layers.items
		})
		if row_item.item:info_panel() == "lobby_campaign" then
			self:_create_lobby_campaign(row_item)
		elseif row_item.item:info_panel() == "lobby_difficulty" then
			self:_create_lobby_difficulty(row_item)
		elseif row_item.help_text then
			self:_create_info_panel(row_item)
		end
		self:_align_multi_choice(row_item)
	elseif row_item.type == "chat" then
		row_item.gui_panel = self.item_panel:panel({
			w = self.item_panel:w(),
			h = 100
		})
		row_item.chat_output = row_item.gui_panel:gui(Idstring("guis/chat/textscroll"), {
			layer = self.layers.items,
			h = 120,
			w = 500,
			valign = "grow",
			halign = "grow"
		})
		row_item.chat_input = row_item.gui_panel:gui(Idstring("guis/chat/chat_input"), {
			h = 25,
			w = 500,
			layer = self.layers.items,
			valign = "bottom",
			halign = "grow",
			y = 125
		})
		row_item.chat_input:script().enter_callback = callback(self, self, "_cb_chat", row_item)
		row_item.chat_input:script().esc_callback = callback(self, self, "_cb_unlock", row_item)
		row_item.chat_input:script().typing_callback = callback(self, self, "_cb_lock", row_item)
		row_item.border = row_item.gui_panel:rect({
			visible = false,
			layer = self.layers.items,
			color = tweak_data.hud.prime_color,
			w = 800,
			h = 2
		})
		self:_align_chat(row_item)
	elseif row_item.type == "friend" then
		row_item.gui_panel = self.item_panel:panel({
			w = self.item_panel:w()
		})
		row_item.color_mod = (row_item.item:parameters().signin_status == "uninvitable" or row_item.item:parameters().signin_status == "not_signed_in") and 0.75 or 1
		row_item.friend_name = self:_text_item_part(row_item, row_item.gui_panel, self:_right_align())
		row_item.friend_name:set_color(row_item.friend_name:color() * row_item.color_mod)
		row_item.signin_status = self:_text_item_part(row_item, row_item.gui_panel, self:_left_align())
		row_item.signin_status:set_align("right")
		row_item.signin_status:set_color(row_item.signin_status:color() * row_item.color_mod)
		local status_text = managers.localization:text("menu_friends_" .. row_item.item:parameters().signin_status)
		row_item.signin_status:set_text(string.upper(status_text))
		self:_align_friend(row_item)
	elseif row_item.type == "customize_controller" then
		row_item.gui_panel = self.item_panel:panel({
			w = self.item_panel:w()
		})
		row_item.controller_name = self:_text_item_part(row_item, row_item.gui_panel, self:_left_align())
		row_item.controller_name:set_align("right")
		row_item.controller_binding = self:_text_item_part(row_item, row_item.gui_panel, self:_left_align(), "left")
		row_item.controller_binding:set_align("left")
		row_item.controller_binding:set_text(string.upper(row_item.item:parameters().binding))
		row_item.controller_binding:set_color(tweak_data.menu.default_changeable_text_color)
		self:_align_customize_controller(row_item)
	else
		row_item.gui_panel = self:_text_item_part(row_item, self.item_panel, self:_right_align())
		if row_item.help_text then
			self:_create_info_panel(row_item)
		end
		if row_item.item:parameters().trial_buy then
			self:_setup_trial_buy(row_item)
		end
		if row_item.item:parameters().fake_disabled then
			self:_setup_fake_disabled(row_item)
		end
		self:_align_normal(row_item)
	end
end
function MenuNodeGui:_setup_trial_buy(row_item)
	local font_size = SystemInfo:language() == Idstring("italian") and 25 or 28
	row_item.row_item_color = Color(1, 1, 0.65882355, 0)
	row_item.font_size = font_size * tweak_data.scale.default_font_multiplier
	row_item.gui_panel:set_color(row_item.row_item_color)
	row_item.gui_panel:set_font_size(row_item.font_size)
end
function MenuNodeGui:_setup_fake_disabled(row_item)
	row_item.row_item_color = tweak_data.menu.default_disabled_text_color
	row_item.gui_panel:set_color(row_item.row_item_color)
end
function MenuNodeGui:_create_info_panel(row_item)
	row_item.gui_info_panel = self.safe_rect_panel:panel({
		visible = false,
		layer = self.layers.first,
		x = 0,
		y = 0,
		w = self:_left_align(),
		h = self._main_panel:h()
	})
	row_item.help_title = row_item.gui_info_panel:text({
		x = 0,
		y = 0,
		align = "left",
		halign = "top",
		vertical = "top",
		font_size = self.font_size,
		font = row_item.font,
		color = Color.white,
		layer = self.layers.items,
		text = string.upper(row_item.text)
	})
	row_item.help_text = row_item.gui_info_panel:text({
		x = 0,
		y = 0,
		align = "left",
		halign = "top",
		vertical = "top",
		font = tweak_data.menu.small_font,
		font_size = tweak_data.menu.small_font_size,
		color = Color.white,
		layer = self.layers.items,
		text = string.upper(row_item.help_text),
		wrap = true,
		word_wrap = true
	})
end
function MenuNodeGui:_reload_upgrade(row_item)
	local upgrade_id = row_item.item:parameters().upgrade_id
	if row_item.toggle_text then
		local text
		if not managers.upgrades:visual_weapon_upgrade_active(upgrade_id) then
			text = managers.localization:text("menu_show_upgrade_info", {
				UPGRADE = managers.localization:text("menu_" .. upgrade_id .. "_info")
			})
		else
			text = managers.localization:text("menu_hide_upgrade_info", {
				UPGRADE = managers.localization:text("menu_" .. upgrade_id .. "_info")
			})
		end
		row_item.toggle_text:set_text(string.upper(text))
	end
end
function MenuNodeGui:_set_lobby_campaign(row_item)
	if not MenuNodeGui.lobby_campaign then
		self:_create_lobby_campaign(row_item)
	else
		row_item.level_id = MenuNodeGui.lobby_campaign.level_id
		row_item.gui_info_panel = MenuNodeGui.lobby_campaign.gui_info_panel
		row_item.level_movie = MenuNodeGui.lobby_campaign.level_movie
		row_item.level_title = MenuNodeGui.lobby_campaign.level_title
		row_item.level_briefing = MenuNodeGui.lobby_campaign.level_briefing
	end
end
function MenuNodeGui:_create_lobby_campaign(row_item)
	row_item.gui_info_panel = self.safe_rect_panel:panel({
		visible = false,
		layer = self.layers.items,
		x = 0,
		y = 0,
		w = self:_left_align(),
		h = self._main_panel:h()
	})
	row_item.level_id = Global.game_settings.level_id
	local movie_name = tweak_data.levels[row_item.level_id].movie
	row_item.level_movie = row_item.gui_info_panel:video({
		visible = true,
		video = movie_name,
		loop = true
	})
	row_item.level_movie:pause()
	managers.video:add_video(row_item.level_movie)
	row_item.level_title = row_item.gui_info_panel:text({
		x = 0,
		y = 0,
		align = "left",
		halign = "top",
		vertical = "top",
		font_size = self.font_size,
		font = row_item.font,
		color = Color.white,
		layer = self.layers.items,
		text = string.upper(managers.localization:text(tweak_data.levels[row_item.level_id].name_id))
	})
	local briefing_text = string.upper(managers.localization:text(tweak_data.levels[row_item.level_id].briefing_id))
	row_item.level_briefing = row_item.gui_info_panel:text({
		x = 0,
		y = 0,
		align = "left",
		halign = "top",
		vertical = "top",
		font = tweak_data.menu.small_font,
		font_size = tweak_data.menu.small_font_size,
		color = Color.white,
		layer = self.layers.items,
		text = briefing_text,
		wrap = true,
		word_wrap = true
	})
	MenuNodeGui.lobby_campaign = {
		level_id = Global.game_settings.level_id,
		gui_info_panel = row_item.gui_info_panel,
		level_movie = row_item.level_movie,
		level_title = row_item.level_title,
		level_briefing = row_item.level_briefing
	}
end
function MenuNodeGui:_align_lobby_campaign(row_item)
	self:_align_item_gui_info_panel(row_item.gui_info_panel)
	local w = row_item.gui_info_panel:w()
	local m = row_item.level_movie:video_width() / row_item.level_movie:video_height()
	row_item.level_movie:set_size(w, w / m)
	row_item.level_movie:set_y(0)
	row_item.level_movie:set_center_x(row_item.gui_info_panel:w() / 2)
	local _, _, _, h = row_item.level_title:text_rect()
	row_item.level_title:set_size(w, h)
	row_item.level_title:set_position(0, row_item.level_movie:bottom() + tweak_data.menu.info_padding)
	row_item.level_briefing:set_w(w)
	row_item.level_briefing:set_shape(row_item.level_briefing:text_rect())
	row_item.level_briefing:set_x(0)
	row_item.level_briefing:set_top(row_item.level_title:bottom() + tweak_data.menu.info_padding)
end
function MenuNodeGui:_highlight_lobby_campaign(row_item)
	if row_item.level_id ~= Global.game_settings.level_id then
		self:_reload_lobby_campaign(row_item)
	end
	row_item.gui_info_panel:set_visible(true)
	row_item.level_movie:play()
end
function MenuNodeGui:_fade_lobby_campaign(row_item)
	row_item.gui_info_panel:set_visible(false)
	row_item.level_movie:pause()
end
function MenuNodeGui:_reload_lobby_campaign(row_item)
	if MenuNodeGui.lobby_campaign.level_id == Global.game_settings.level_id then
		return
	end
	if row_item.level_id ~= MenuNodeGui.lobby_campaign.level_id then
		row_item.level_id = MenuNodeGui.lobby_campaign.level_id
		row_item.gui_info_panel = MenuNodeGui.lobby_campaign.gui_info_panel
		row_item.level_movie = MenuNodeGui.lobby_campaign.level_movie
		row_item.level_title = MenuNodeGui.lobby_campaign.level_title
		row_item.level_briefing = MenuNodeGui.lobby_campaign.level_briefing
		return
	end
	managers.video:remove_video(row_item.level_movie)
	row_item.level_id = Global.game_settings.level_id
	local movie_name = tweak_data.levels[row_item.level_id].movie
	row_item.level_movie:set_video(movie_name)
	local text = string.upper(managers.localization:text(tweak_data.levels[row_item.level_id].name_id))
	row_item.level_title:set_text(text)
	local briefing_text = string.upper(managers.localization:text(tweak_data.levels[row_item.level_id].briefing_id))
	row_item.level_briefing:set_text(briefing_text)
	local _, _, _, h = row_item.level_briefing:text_rect()
	row_item.level_briefing:set_w(row_item.level_movie:w())
	row_item.level_briefing:set_h(h)
	managers.video:add_video(row_item.level_movie)
	MenuNodeGui.lobby_campaign = {
		level_id = Global.game_settings.level_id,
		gui_info_panel = row_item.gui_info_panel,
		level_movie = row_item.level_movie,
		level_title = row_item.level_title,
		level_briefing = row_item.level_briefing
	}
end
function MenuNodeGui:_create_lobby_difficulty(row_item)
	row_item.gui_info_panel = self.safe_rect_panel:panel({
		visible = false,
		layer = self.layers.items,
		x = 0,
		y = 0,
		w = self:_left_align(),
		h = self._main_panel:h()
	})
	row_item.difficulty_title = row_item.gui_info_panel:text({
		x = 0,
		y = 0,
		align = "left",
		halign = "top",
		vertical = "top",
		font_size = self.font_size,
		font = row_item.font,
		color = Color.white,
		layer = self.layers.items,
		text = string.upper(row_item.text)
	})
	row_item.help_text = row_item.gui_info_panel:text({
		x = 0,
		y = 0,
		align = "left",
		halign = "top",
		vertical = "top",
		font = tweak_data.menu.small_font,
		font_size = tweak_data.menu.small_font_size,
		color = Color.white,
		layer = self.layers.items,
		text = string.upper(managers.localization:text("menu_difficulty_help")),
		wrap = true,
		word_wrap = true
	})
	row_item.difficulty_help_text = row_item.gui_info_panel:text({
		x = 0,
		y = 0,
		align = "left",
		halign = "top",
		vertical = "top",
		font = tweak_data.menu.small_font,
		font_size = tweak_data.menu.small_font_size,
		color = Color.white,
		layer = self.layers.items,
		text = string.upper("sdsd"),
		wrap = true,
		word_wrap = true
	})
end
function MenuNodeGui:_align_lobby_difficulty(row_item)
	local w = row_item.gui_info_panel:w()
	row_item.difficulty_title:set_shape(row_item.difficulty_title:text_rect())
	row_item.difficulty_title:set_position(0, 0)
	row_item.help_text:set_w(w)
	row_item.help_text:set_shape(row_item.help_text:text_rect())
	row_item.help_text:set_x(0)
	row_item.help_text:set_top(row_item.difficulty_title:bottom() + tweak_data.menu.info_padding)
	self:_align_lobby_difficulty_help_text(row_item)
end
function MenuNodeGui:_align_lobby_difficulty_help_text(row_item)
	local w = row_item.gui_info_panel:w()
	row_item.difficulty_help_text:set_w(w)
	local _, _, tw, th = row_item.difficulty_help_text:text_rect()
	row_item.difficulty_help_text:set_h(th)
	row_item.difficulty_help_text:set_x(0)
	row_item.difficulty_help_text:set_top(row_item.help_text:bottom() + tweak_data.menu.info_padding * 2)
end
function MenuNodeGui:_highlight_lobby_difficulty(row_item)
	row_item.gui_info_panel:set_visible(true)
end
function MenuNodeGui:_fade_lobby_difficulty(row_item)
	row_item.gui_info_panel:set_visible(false)
end
function MenuNodeGui:_reload_lobby_difficulty(row_item)
	row_item.difficulty_help_text:set_text(string.upper(managers.localization:text("menu_difficulty_" .. Global.game_settings.difficulty .. "_help")))
	self:_align_lobby_difficulty_help_text(row_item)
end
function MenuNodeGui:_align_friend(row_item)
	local safe_rect = managers.viewport:get_safe_rect_pixels()
	row_item.friend_name:set_font_size(self.font_size)
	local x, y, w, h = row_item.friend_name:text_rect()
	row_item.friend_name:set_height(h)
	row_item.friend_name:set_left(self:_right_align())
	row_item.gui_panel:set_height(h)
	row_item.signin_status:set_font_size(self.font_size)
	row_item.signin_status:set_height(h)
	row_item.signin_status:set_right(self:_left_align())
end
function MenuNodeGui:_align_customize_controller(row_item)
	local safe_rect = managers.viewport:get_safe_rect_pixels()
	row_item.controller_name:set_font_size(tweak_data.menu.customize_controller_size)
	local x, y, w, h = row_item.controller_name:text_rect()
	row_item.controller_name:set_height(h)
	row_item.controller_name:set_right(self:_left_align())
	row_item.gui_panel:set_height(h)
	row_item.controller_binding:set_font_size(tweak_data.menu.customize_controller_size)
	row_item.controller_binding:set_height(h)
	row_item.controller_binding:set_left(self:_right_align())
end
function MenuNodeGui:_reload_customize_controller(item)
	local row_item = self:row_item(item)
	if item:parameters().axis then
		row_item.controller_binding:set_text(string.upper(item:parameters().binding))
	else
		row_item.controller_binding:set_text(string.upper(item:parameters().binding))
	end
end
function MenuNodeGui:activate_customize_controller(item)
	self._listening_to_input = true
	setup:add_end_frame_clbk(function()
		self:_activate_customize_controller(item)
	end)
end
function MenuNodeGui:_activate_customize_controller(item)
	local row_item = self:row_item(item)
	self.ws:connect_keyboard(Input:keyboard())
	self.ws:connect_mouse(Input:mouse())
	self._skip_first_mouse_0 = true
	local function f(o, key)
		self:_key_press(o, key, "keyboard", item)
	end
	row_item.controller_binding:set_text("_")
	row_item.controller_binding:key_press(f)
	local function f(o, key)
		self:_key_press(o, key, "mouse", item)
	end
	row_item.controller_binding:mouse_click(f)
	local function f(index, key)
		self:_key_press(row_item.controller_binding, key, "mouse", item, true)
	end
	self._mouse_wheel_up_trigger = Input:mouse():add_trigger(Input:mouse():button_index(Idstring("mouse wheel up")), f)
	self._mouse_wheel_down_trigger = Input:mouse():add_trigger(Input:mouse():button_index(Idstring("mouse wheel down")), f)
end
function MenuNodeGui:_key_press(o, key, input_id, item, no_add)
	if managers.system_menu:is_active() then
		return
	end
	if self._skip_first_mouse_0 then
		self._skip_first_mouse_0 = false
		if input_id == "mouse" and key == Idstring("0") then
			return
		end
	end
	local row_item = self:row_item(item)
	if key == Idstring("esc") then
		self:_end_customize_controller(o, item)
		return
	end
	if input_id ~= "mouse" or not Input:mouse():button_name_str(key) then
	end
	local key_name = "" .. Input:keyboard():button_name_str(key)
	if not no_add and input_id == "mouse" then
		key_name = "mouse " .. key_name or key_name
	end
	local forbidden_btns = {
		"esc",
		"tab",
		"num abnt c1",
		"num abnt c2",
		"@",
		"ax",
		"convert",
		"kana",
		"kanji",
		"no convert",
		"oem 102",
		"stop",
		"unlabeled",
		"yen",
		"mouse 8",
		"mouse 9",
		""
	}
	for _, btn in ipairs(forbidden_btns) do
		if Idstring(btn) == key then
			managers.menu:show_key_binding_forbidden({KEY = key_name})
			self:_end_customize_controller(o, item)
			return
		end
	end
	local connections = managers.controller:get_settings(managers.controller:get_default_wrapper_type()):get_connection_map()
	for _, name in ipairs(MenuCustomizeControllerCreator.CONTROLS) do
		local connection = connections[name]
		if connection._btn_connections then
			for name, btn_connection in pairs(connection._btn_connections) do
				if btn_connection.name == key_name and item:parameters().binding ~= btn_connection.name then
					managers.menu:show_key_binding_collision({
						KEY = key_name,
						MAPPED = managers.localization:text(MenuCustomizeControllerCreator.CONTROLS_INFO[name].text_id)
					})
					self:_end_customize_controller(o, item)
					return
				end
			end
		else
			for _, b_name in ipairs(connection:get_input_name_list()) do
				if tostring(b_name) == key_name and item:parameters().binding ~= b_name then
					managers.menu:show_key_binding_collision({
						KEY = key_name,
						MAPPED = managers.localization:text(MenuCustomizeControllerCreator.CONTROLS_INFO[name].text_id)
					})
					self:_end_customize_controller(o, item)
					return
				end
			end
		end
	end
	if item:parameters().axis then
		connections[item:parameters().axis]._btn_connections[item:parameters().button].name = key_name
		managers.controller:set_user_mod(item:parameters().connection_name, {
			axis = item:parameters().axis,
			button = item:parameters().button,
			connection = key_name
		})
		item:parameters().binding = key_name
	else
		connections[item:parameters().button]:set_controller_id(input_id)
		connections[item:parameters().button]:set_input_name_list({key_name})
		managers.controller:set_user_mod(item:parameters().connection_name, {
			button = item:parameters().button,
			connection = key_name,
			controller_id = input_id
		})
		item:parameters().binding = key_name
	end
	managers.controller:rebind_connections()
	self:_end_customize_controller(o, item)
end
function MenuNodeGui:_end_customize_controller(o, item)
	self.ws:disconnect_keyboard()
	self.ws:disconnect_mouse()
	o:key_press(nil)
	o:mouse_click(nil)
	o:mouse_release(nil)
	Input:mouse():remove_trigger(self._mouse_wheel_up_trigger)
	Input:mouse():remove_trigger(self._mouse_wheel_down_trigger)
	setup:add_end_frame_clbk(function()
		self._listening_to_input = false
	end)
	item:dirty()
end
function MenuNodeGui:_cb_chat(row_item)
	local chat_text = row_item.chat_input:child("text"):text()
	if chat_text and tostring(chat_text) ~= "" then
		local name = utf8.to_upper(managers.network:session():local_peer():name())
		local say = name .. ": " .. tostring(chat_text)
		self:_say(say, row_item, managers.network:session():local_peer():id())
		managers.network:session():send_to_peers("sync_chat_message", say)
	end
	self._chatbox_typing = false
	row_item.chat_input:child("text"):set_text("")
	row_item.chat_input:child("text"):set_selection(0, 0)
end
function MenuNodeGui:sync_say(message, row_item, id)
	self:_say(message, row_item, id)
end
function MenuNodeGui:_say(message, row_item, id)
	if managers.menu:active_menu() then
		managers.menu:active_menu().renderer:post_event("prompt_exit")
	end
	local s = row_item.chat_output:script()
	local i = utf8.find_char(message, ":")
	s.box_print(message, tweak_data.chat_colors[id], i)
end
function MenuNodeGui:_cb_unlock()
end
function MenuNodeGui:_cb_lock()
end
function MenuNodeGui:_text_item_part(row_item, panel, align_x, text_align)
	return panel:text({
		font_size = self.font_size,
		x = align_x,
		y = 0,
		align = text_align or "left",
		halign = "left",
		vertical = "center",
		font = row_item.font,
		color = row_item.color,
		layer = self.layers.items,
		text = row_item.text,
		render_template = Idstring("VertexColorTextured")
	})
end
function MenuNodeGui:scroll_update(dt)
	MenuNodeGui.super.scroll_update(self, dt)
	if math.round(self.item_panel:world_y()) - math.round(self._main_panel:world_y()) < 0 then
		self._list_arrows.up:set_color(self._list_arrows.up:color():with_alpha(0.9))
	else
		self._list_arrows.up:set_color(self._list_arrows.up:color():with_alpha(0.25))
	end
	if math.round(self.item_panel:world_bottom()) - self._main_panel:world_bottom() < 4 then
		self._list_arrows.down:set_color(self._list_arrows.down:color():with_alpha(0.25))
	else
		self._list_arrows.down:set_color(self._list_arrows.down:color():with_alpha(0.9))
	end
end
function MenuNodeGui:reload_item(item)
	local type = item:type()
	if type == "multi_choice" then
		self:_reload_multi_choice(item)
	elseif type == "friend" then
		self:_reload_friend(item)
	elseif type == "upgrade" then
		self:_reload_upgrade(self:row_item(item))
	elseif type == "customize_controller" then
		self:_reload_customize_controller(item)
	else
		MenuNodeGui.super.reload_item(self, item)
	end
	if self._highlighted_item and self._highlighted_item == item then
		local row_item = self:row_item(item)
		if row_item then
			self:_align_marker(row_item)
		end
	end
end
function MenuNodeGui:_reload_friend(item)
	local row_item = self:row_item(item)
	local status_text = managers.localization:text("menu_friends_" .. row_item.item:parameters().signin_status)
	row_item.signin_status:set_text(string.upper(status_text))
end
function MenuNodeGui:_reload_multi_choice(item)
	local row_item = self:row_item(item)
	if not row_item then
		return
	end
	if self.localize_strings and item:selected_option():parameters().localize ~= false then
		row_item.option_text = managers.localization:text(item:selected_option():parameters().text_id)
	else
		row_item.option_text = item:selected_option():parameters().text_id
	end
	row_item.choice_text:set_text(string.upper(row_item.option_text))
	if item:selected_option():parameters().stencil_image then
		managers.menu:active_menu().renderer:set_stencil_image(item:selected_option():parameters().stencil_image)
	end
	if item:selected_option():parameters().stencil_align then
		managers.menu:active_menu().renderer:set_stencil_align(item:selected_option():parameters().stencil_align, item:selected_option():parameters().stencil_align_percent)
	end
	row_item.arrow_left:set_color(item:left_arrow_visible() and tweak_data.menu.arrow_available or tweak_data.menu.arrow_unavailable)
	row_item.arrow_right:set_color(item:right_arrow_visible() and tweak_data.menu.arrow_available or tweak_data.menu.arrow_unavailable)
	if item:info_panel() == "lobby_campaign" then
		self:_reload_lobby_campaign(row_item)
	elseif item:info_panel() == "lobby_difficulty" then
		self:_reload_lobby_difficulty(row_item)
	end
end
function MenuNodeGui:_reload_slider_item(item)
	local row_item = self:row_item(item)
	local value = item:show_value() and string.format("%.0f", item:value()) or string.format("%.0f", item:percentage()) .. "%"
	row_item.gui_slider_text:set_text(value)
	local where = row_item.gui_slider:left() + row_item.gui_slider:w() * (item:percentage() / 100)
	row_item.gui_slider_marker:set_center_x(where)
	row_item.gui_slider_gfx:set_w(row_item.gui_slider:w() * (item:percentage() / 100))
end
function MenuNodeGui:_set_toggle_item_image(row_item)
	local item = row_item.item
	if item:selected_option():parameters().icon then
		if row_item.highlighted and item:selected_option():parameters().s_icon then
			local x = item:selected_option():parameters().s_x
			local y = item:selected_option():parameters().s_y
			local w = item:selected_option():parameters().s_w
			local h = item:selected_option():parameters().s_h
			row_item.gui_icon:set_image(item:selected_option():parameters().s_icon, x, y, w, h)
		else
			local x = item:selected_option():parameters().x
			local y = item:selected_option():parameters().y
			local w = item:selected_option():parameters().w
			local h = item:selected_option():parameters().h
			row_item.gui_icon:set_image(item:selected_option():parameters().icon, x, y, w, h)
		end
		if row_item.item:enabled() then
			row_item.gui_icon:set_color(Color.white)
		else
			row_item.gui_icon:set_color(tweak_data.menu.default_disabled_text_color)
		end
	end
end
function MenuNodeGui:_reload_toggle_item(item)
	local row_item = self:row_item(item)
	if row_item.gui_option then
		if self.localize_strings and item:selected_option():parameters().localize ~= false then
			row_item.option_text = managers.localization:text(item:selected_option():parameters().text_id)
		else
			row_item.option_text = item:selected_option():parameters().text_id
		end
		row_item.gui_option:set_text(row_item.option_text)
	end
	self:_set_toggle_item_image(row_item)
	if item:info_panel() == "lobby_campaign" then
		self:_reload_lobby_campaign(row_item)
	end
end
function MenuNodeGui:_setup_item_size(row_item)
	local type = row_item.item:type()
	if type == "level" then
		self:_setup_level_size(row_item)
	elseif type == "challenge" then
		self:_setup_challenge_size(row_item)
	elseif type == "upgrade" then
		self:_setup_upgrade_size(row_item)
	end
end
function MenuNodeGui:_setup_level_size(row_item)
	local padding = 24
	row_item.gui_level_panel:set_shape(0, 0, self:_left_align(), self._main_panel:h())
	local w = row_item.gui_level_panel:w() - padding * 2
	row_item.level_title:set_shape(padding, 24, w, row_item.gui_level_panel:w())
	row_item.level_text:set_shape(padding, 66, w, row_item.gui_level_panel:w())
	if row_item.level_movie then
		local p = row_item.level_movie:video_height() / row_item.level_movie:video_width()
		row_item.level_movie:set_w(w)
		row_item.level_movie:set_h(w * p)
		row_item.level_movie:set_center_x(row_item.gui_level_panel:w() / 2)
		row_item.level_movie:set_bottom(self._main_panel:h() - 24)
	end
end
function MenuNodeGui:_setup_challenge_size(row_item)
	self:_align_item_gui_info_panel(row_item.gui_info_panel)
	row_item.challenge_hl:set_w(row_item.gui_info_panel:w())
	local _, _, w, h = row_item.challenge_hl:text_rect()
	row_item.challenge_hl:set_h(h)
	row_item.challenge_hl:set_x(0)
	row_item.challenge_hl:set_y(0)
	local _, _, w, h = row_item.reward_text:text_rect()
	row_item.reward_panel:set_h(h)
	row_item.reward_panel:set_w(row_item.gui_info_panel:w())
	row_item.reward_text:set_size(w, h)
	row_item.reward_panel:set_x(0)
	row_item.reward_panel:set_top(row_item.challenge_hl:bottom() + tweak_data.menu.info_padding)
	row_item.description_text:set_w(row_item.gui_info_panel:w())
	local _, _, w, h = row_item.description_text:text_rect()
	row_item.description_text:set_h(h)
	row_item.description_text:set_x(0)
	row_item.description_text:set_top(row_item.reward_panel:bottom() + tweak_data.menu.info_padding)
end
function MenuNodeGui:_setup_upgrade_size(row_item)
end
function MenuNodeGui:_highlight_row_item(row_item, mouse_over)
	if row_item then
		self:_align_marker(row_item)
		row_item.color = self.row_item_hightlight_color
		if row_item.type == "slider" then
			row_item.gui_text:set_color(row_item.color)
			row_item.gui_text:set_font(tweak_data.menu.default_font_no_outline_id)
			row_item.gui_slider_gfx:set_gradient_points({
				0,
				Color(1, 1, 0.65882355, 0),
				1,
				Color(1, 0.6039216, 0.4, 0)
			})
			if row_item.gui_info_panel then
				row_item.gui_info_panel:set_visible(true)
			end
		elseif row_item.type == "toggle" then
			row_item.gui_text:set_color(row_item.color)
			row_item.gui_text:set_font(tweak_data.menu.default_font_no_outline_id)
			row_item.highlighted = true
			self:_set_toggle_item_image(row_item)
			if row_item.gui_option then
				row_item.gui_option:set_color(row_item.color)
			end
			if row_item.gui_info_panel then
				row_item.gui_info_panel:set_visible(true)
			end
			if row_item.item:info_panel() == "lobby_campaign" then
				self:_highlight_lobby_campaign(row_item)
			end
		elseif row_item.type == "column" then
			for _, gui in ipairs(row_item.gui_columns) do
				gui:set_color(row_item.color)
				gui:set_font(tweak_data.menu.default_font_no_outline_id)
			end
		elseif row_item.type == "server_column" then
			for _, gui in ipairs(row_item.gui_columns) do
				gui:set_color(row_item.color)
				gui:set_font(tweak_data.menu.default_font_no_outline_id)
			end
			row_item.gui_info_panel:set_visible(true)
		elseif row_item.type == "level" then
			row_item.gui_level_panel:set_visible(true)
			if row_item.level_movie then
				row_item.level_movie:play()
			end
			MenuNodeGui.super._highlight_row_item(self, row_item)
		elseif row_item.type == "challenge" then
			row_item.gui_info_panel:set_visible(true)
			row_item.challenge_name:set_color(row_item.color)
			row_item.challenge_name:set_font(tweak_data.menu.default_font_no_outline_id)
			if row_item.bar then
				row_item.bar:set_gradient_points({
					0,
					Color(1, 1, 0.65882355, 0),
					1,
					Color(1, 0.6039216, 0.4, 0)
				})
			end
		elseif row_item.type == "upgrade" then
			if row_item.gui_info_panel then
				row_item.gui_info_panel:set_visible(true)
			end
			row_item.upgrade_name:set_color(row_item.color)
			row_item.upgrade_name:set_font(tweak_data.menu.default_font_no_outline_id)
			if row_item.upgrade_icon then
				row_item.upgrade_icon:set_image("guis/textures/icon_star", 32, 0, 32, 32)
			end
		elseif row_item.type == "friend" then
			row_item.friend_name:set_color(row_item.color * row_item.color_mod)
			row_item.friend_name:set_font(tweak_data.menu.default_font_no_outline_id)
			row_item.signin_status:set_color(row_item.color * row_item.color_mod)
			row_item.signin_status:set_font(tweak_data.menu.default_font_no_outline_id)
		elseif row_item.type == "multi_choice" then
			row_item.choice_text:set_color(row_item.color)
			row_item.choice_text:set_font(tweak_data.menu.default_font_no_outline_id)
			row_item.arrow_left:set_image("guis/textures/menu_arrows", 24, 0, 24, 24)
			row_item.arrow_right:set_image("guis/textures/menu_arrows", 48, 0, -24, 24)
			row_item.arrow_left:set_color(row_item.item:left_arrow_visible() and tweak_data.menu.arrow_available or tweak_data.menu.arrow_unavailable)
			row_item.arrow_right:set_color(row_item.item:right_arrow_visible() and tweak_data.menu.arrow_available or tweak_data.menu.arrow_unavailable)
			if row_item.item:info_panel() == "lobby_campaign" then
				self:_highlight_lobby_campaign(row_item)
			elseif row_item.item:info_panel() == "lobby_difficulty" then
				self:_highlight_lobby_difficulty(row_item)
			elseif row_item.gui_info_panel then
				row_item.gui_info_panel:set_visible(true)
			end
		elseif row_item.type == "chat" then
			self.ws:connect_keyboard(Input:keyboard())
			row_item.border:set_visible(true)
			if not mouse_over then
				row_item.chat_input:script().set_focus(true)
			end
		elseif row_item.type == "customize_controller" then
			row_item.controller_binding:set_color(row_item.color)
			row_item.controller_binding:set_font(tweak_data.menu.default_font_no_outline_id)
		else
			row_item.gui_panel:set_font(tweak_data.menu.default_font_no_outline_id)
			if row_item.gui_info_panel then
				row_item.gui_info_panel:set_visible(true)
			end
			MenuNodeGui.super._highlight_row_item(self, row_item)
		end
		if row_item.item:parameters().stencil_image then
			managers.menu:active_menu().renderer:set_stencil_image(row_item.item:parameters().stencil_image)
		else
			managers.menu:active_menu().renderer:set_stencil_image(self._stencil_image)
		end
	end
end
function MenuNodeGui:_align_marker(row_item)
	self._marker_data.marker:set_height(row_item.gui_panel:height())
	self._marker_data.marker:set_left(self:_mid_align())
	self._marker_data.marker:set_center_y(row_item.gui_panel:center_y())
	self._marker_data.gradient:set_height(row_item.gui_panel:height())
	local item_enabled = row_item.item:enabled()
	if item_enabled then
		self._marker_data.gradient:set_gradient_points({
			0,
			tweak_data.menu.highlight_background_color_left,
			1,
			tweak_data.menu.highlight_background_color_right
		})
	else
		self._marker_data.gradient:set_gradient_points({
			0,
			Color(1, 0.33, 0.33, 0.33),
			1,
			Color(1, 0.33, 0.33, 0.33)
		})
	end
	if row_item.name == "back" then
		self._marker_data.marker:set_visible(false)
		if not self._marker_data.back_marker then
			local gx, gy, gw, gh = row_item.gui_panel:text_rect()
			gx = row_item.gui_panel:right() - gw - self._align_line_padding
			gy = row_item.gui_panel:bottom() - gh
			gw = gw + self._align_line_padding * 2
			self._marker_data.back_marker = row_item.gui_panel:parent():panel({
				x = gx,
				y = gy,
				w = gw,
				h = gh,
				layer = row_item.gui_panel:layer() - 1
			})
			self._marker_data.back_marker:gradient({
				x = 0,
				y = 0,
				h = row_item.gui_panel:height(),
				layer = 0,
				gradient_points = {
					0,
					tweak_data.menu.highlight_background_color_left,
					1,
					tweak_data.menu.highlight_background_color_right
				}
			})
		end
		self._marker_data.back_marker:set_visible(true)
	else
		self._marker_data.marker:set_visible(true)
		if self._marker_data.back_marker then
			self._marker_data.back_marker:set_visible(false)
		end
	end
	if row_item.type == "upgrade" then
		self._marker_data.marker:set_left(self:_mid_align())
	elseif row_item.type == "friend" then
		local _, _, w, _ = row_item.signin_status:text_rect()
		self._marker_data.marker:set_left(self:_left_align() - w - self._align_line_padding)
	elseif row_item.type == "server_column" then
		self._marker_data.marker:set_left(row_item.gui_panel:x())
	elseif row_item.type == "customize_controller" then
	else
		if row_item.type == "kitslot" or row_item.type == "multi_choice" or row_item.type == "toggle" then
			if row_item.type == "slider" then
				self._marker_data.marker:set_left(self:_left_align() - row_item.gui_slider:width())
			elseif row_item.type == "kitslot" or row_item.type == "multi_choice" then
				if row_item.choice_panel then
					self._marker_data.marker:set_left(row_item.arrow_left:left() - self._align_line_padding + row_item.gui_panel:x())
				end
			elseif row_item.type == "toggle" then
				if row_item.gui_option then
					local x, y, w, h = row_item.gui_option:text_rect()
					self._marker_data.marker:set_left(self:_left_align() - w - self._align_line_padding + row_item.gui_panel:x())
				else
					self._marker_data.marker:set_left(row_item.gui_icon:x() - self._align_line_padding + row_item.gui_panel:x())
				end
			end
		else
		end
	end
	self._marker_data.gradient:set_visible(true)
	if row_item.type == "chat" then
		self._marker_data.gradient:set_visible(false)
	end
	self._marker_data.rect:set_right(self:_right_align() - self._marker_data.rect:parent():x())
	self._marker_data.rect:set_center_y(self._marker_data.rect:parent():h() / 2)
end
function MenuNodeGui:_fade_row_item(row_item)
	if row_item then
		row_item.color = row_item.item:enabled() and self.row_item_color or tweak_data.menu.default_disabled_text_color
		if row_item.type == "slider" then
			row_item.gui_text:set_color(row_item.color)
			row_item.gui_text:set_font(tweak_data.menu.default_font_id)
			row_item.gui_slider_gfx:set_gradient_points({
				0,
				Color(0.5, 1, 0.65882355, 0),
				1,
				Color(0.5, 0.6039216, 0.4, 0)
			})
			if row_item.gui_info_panel then
				row_item.gui_info_panel:set_visible(false)
			end
		elseif row_item.type == "toggle" then
			row_item.gui_text:set_color(row_item.color)
			row_item.gui_text:set_font(tweak_data.menu.default_font_id)
			row_item.highlighted = nil
			self:_set_toggle_item_image(row_item)
			if row_item.gui_option then
				row_item.gui_option:set_color(row_item.color)
			end
			if row_item.gui_info_panel then
				row_item.gui_info_panel:set_visible(false)
			end
			if row_item.item:info_panel() == "lobby_campaign" then
				self:_fade_lobby_campaign(row_item)
			end
		elseif row_item.type == "column" then
			for _, gui in ipairs(row_item.gui_columns) do
				gui:set_color(row_item.color)
				gui:set_font(tweak_data.menu.default_font_id)
			end
		elseif row_item.type == "server_column" then
			for _, gui in ipairs(row_item.gui_columns) do
				gui:set_color(row_item.color)
				gui:set_font(tweak_data.menu.default_font_id)
			end
			row_item.gui_info_panel:set_visible(false)
		elseif row_item.type == "level" then
			row_item.gui_level_panel:set_visible(false)
			if row_item.level_movie then
				row_item.level_movie:pause()
			end
			MenuNodeGui.super._fade_row_item(self, row_item)
		elseif row_item.type == "challenge" then
			local chl_color = row_item.item:parameter("awarded") and tweak_data.menu.awarded_challenge_color or row_item.color
			row_item.gui_info_panel:set_visible(false)
			row_item.challenge_name:set_color(chl_color)
			row_item.challenge_name:set_font(tweak_data.menu.default_font_id)
			if row_item.bar then
				row_item.bar:set_gradient_points({
					0,
					Color(0.5, 1, 0.65882355, 0),
					1,
					Color(0.5, 0.6039216, 0.4, 0)
				})
			end
		elseif row_item.type == "upgrade" then
			if row_item.gui_info_panel then
				row_item.gui_info_panel:set_visible(false)
			end
			local upg_color = row_item.locked and tweak_data.menu.upgrade_locked_color or row_item.not_aquired and tweak_data.menu.upgrade_not_aquired_color or row_item.color
			if managers.upgrades:aquired(row_item.item:parameters().upgrade_id) then
				upg_color = row_item.color
			end
			row_item.upgrade_name:set_color(upg_color)
			row_item.upgrade_name:set_font(tweak_data.menu.default_font_id)
			if row_item.upgrade_icon then
				row_item.upgrade_icon:set_image("guis/textures/icon_star", 0, 0, 32, 32)
			end
		elseif row_item.type == "friend" then
			row_item.friend_name:set_color(row_item.color * row_item.color_mod)
			row_item.friend_name:set_font(tweak_data.menu.default_font_id)
			row_item.signin_status:set_color(row_item.color * row_item.color_mod)
			row_item.signin_status:set_font(tweak_data.menu.default_font_id)
		elseif row_item.type == "multi_choice" then
			row_item.gui_text:set_color(self.row_item_color)
			row_item.choice_text:set_color(tweak_data.menu.default_changeable_text_color)
			row_item.choice_text:set_font(tweak_data.menu.default_font_id)
			row_item.arrow_left:set_image("guis/textures/menu_arrows", 0, 0, 24, 24)
			row_item.arrow_right:set_image("guis/textures/menu_arrows", 24, 0, -24, 24)
			row_item.arrow_left:set_color(row_item.item:left_arrow_visible() and tweak_data.menu.arrow_available or tweak_data.menu.arrow_unavailable)
			row_item.arrow_right:set_color(row_item.item:right_arrow_visible() and tweak_data.menu.arrow_available or tweak_data.menu.arrow_unavailable)
			if row_item.item:info_panel() == "lobby_campaign" then
				self:_fade_lobby_campaign(row_item)
			elseif row_item.item:info_panel() == "lobby_difficulty" then
				self:_fade_lobby_difficulty(row_item)
			elseif row_item.gui_info_panel then
				row_item.gui_info_panel:set_visible(false)
			end
		elseif row_item.type == "chat" then
			row_item.border:set_visible(false)
			row_item.chat_input:script().set_focus(false)
			self.ws:disconnect_keyboard()
		elseif row_item.type == "customize_controller" then
			row_item.controller_name:set_color(row_item.color)
			row_item.controller_name:set_font(tweak_data.menu.default_font_id)
			row_item.controller_binding:set_color(tweak_data.menu.default_changeable_text_color)
			row_item.controller_binding:set_font(tweak_data.menu.default_font_id)
		else
			row_item.gui_panel:set_font(tweak_data.menu.default_font_id)
			if row_item.gui_info_panel then
				row_item.gui_info_panel:set_visible(false)
			end
			MenuNodeGui.super._fade_row_item(self, row_item)
		end
	end
end
function MenuNodeGui:_align_item_gui_info_panel(panel)
	panel:set_shape(self._info_bg_rect:x() + tweak_data.menu.info_padding, self._info_bg_rect:y() + tweak_data.menu.info_padding, self._info_bg_rect:w() - tweak_data.menu.info_padding * 2, self._info_bg_rect:h() - tweak_data.menu.info_padding * 2)
end
local xl_pad = 64
function MenuNodeGui:_align_info_panel(row_item)
	self:_align_item_gui_info_panel(row_item.gui_info_panel)
	row_item.help_title:set_font_size(self.font_size)
	row_item.help_title:set_shape(row_item.help_title:text_rect())
	row_item.help_title:set_position(0, 0)
	row_item.help_text:set_font_size(tweak_data.menu.small_font_size)
	row_item.help_text:set_w(row_item.gui_info_panel:w())
	row_item.help_text:set_shape(row_item.help_text:text_rect())
	row_item.help_text:set_x(0)
	row_item.help_text:set_top(row_item.help_title:bottom() + tweak_data.menu.info_padding)
end
function MenuNodeGui:_align_normal(row_item)
	local safe_rect = managers.viewport:get_safe_rect_pixels()
	row_item.gui_panel:set_font_size(row_item.font_size or self.font_size)
	local x, y, w, h = row_item.gui_panel:text_rect()
	row_item.gui_panel:set_height(h)
	row_item.gui_panel:set_left(self:_right_align())
	row_item.gui_panel:set_width(safe_rect.width / 2)
	if row_item.gui_info_panel then
		self:_align_info_panel(row_item)
	end
end
function MenuNodeGui:_align_challenge(row_item)
	local safe_rect = managers.viewport:get_safe_rect_pixels()
	row_item.gui_panel:set_width(safe_rect.width / 2 + xl_pad)
	row_item.gui_panel:set_x(safe_rect.width / 2 - xl_pad)
	local x, y, w, h = row_item.challenge_name:text_rect()
	row_item.challenge_name:set_height(h)
	row_item.challenge_name:set_left(self:_right_align() - row_item.gui_panel:x())
	row_item.gui_panel:set_height(h)
	local sh = math.min(h, 22)
	if row_item.bg_bar then
		row_item.bg_bar:set_x(xl_pad)
		row_item.bg_bar:set_h(sh)
		row_item.bg_bar:set_center_y(row_item.gui_panel:h() / 2)
		row_item.bar:set_h(sh - 4)
		row_item.bar:set_x(row_item.bg_bar:x() + 2)
		row_item.bar:set_y(row_item.bg_bar:y() + 2)
		row_item.progress_text:set_center(row_item.bg_bar:center())
	end
	self:_align_item_gui_info_panel(row_item.gui_info_panel)
end
function MenuNodeGui:_align_upgrade(row_item)
	local safe_rect = managers.viewport:get_safe_rect_pixels()
	row_item.gui_panel:set_width(safe_rect.width / 2 + xl_pad * 1.5)
	row_item.gui_panel:set_x(safe_rect.width / 2 - xl_pad * 1.5)
	local x, y, w, h = row_item.upgrade_name:text_rect()
	row_item.upgrade_name:set_height(h)
	row_item.upgrade_name:set_left(self:_right_align() - row_item.gui_panel:x())
	row_item.gui_panel:set_height(h)
	if row_item.topic_text then
		row_item.topic_text:set_height(h)
		row_item.topic_text:set_right(self:_left_align() - row_item.gui_panel:x())
	end
	if row_item.upgrade_icon then
		local s = math.min(32, h * 1.75)
		row_item.upgrade_icon:set_size(s, s)
		row_item.upgrade_icon:set_left(self:_right_align() - row_item.gui_panel:x() + w + self._align_line_padding)
		row_item.upgrade_icon:set_center_y(h / 2)
	end
	if row_item.gui_info_panel then
		self:_align_item_gui_info_panel(row_item.gui_info_panel)
		local w = row_item.gui_info_panel:w()
		local m = row_item.upgrade_info_image_rect[3] / row_item.upgrade_info_image_rect[4]
		row_item.upgrade_info_image:set_size(w, w / m)
		row_item.upgrade_info_image:set_y(0)
		row_item.upgrade_info_image:set_center_x(row_item.gui_info_panel:w() / 2)
		row_item.upgrade_info_title:set_width(w)
		local _, _, _, h = row_item.upgrade_info_title:text_rect()
		row_item.upgrade_info_title:set_height(h)
		row_item.upgrade_info_title:set_top(row_item.upgrade_info_image:bottom() + tweak_data.menu.info_padding)
		row_item.upgrade_info_text:set_top(row_item.upgrade_info_image:bottom() + h + tweak_data.menu.info_padding * 2)
		row_item.upgrade_info_text:set_width(w)
		local _, _, _, h = row_item.upgrade_info_text:text_rect()
		row_item.upgrade_info_text:set_height(h)
		if row_item.toggle_text then
			row_item.toggle_text:set_width(row_item.gui_info_panel:w())
			local _, _, _, h = row_item.toggle_text:text_rect()
			row_item.toggle_text:set_height(h)
			row_item.toggle_text:set_bottom(row_item.gui_info_panel:height())
			row_item.toggle_text:set_left(0)
		end
	end
end
function MenuNodeGui:_align_slider(row_item)
	local safe_rect = managers.viewport:get_safe_rect_pixels()
	row_item.gui_text:set_font_size(self.font_size)
	local x, y, w, h = row_item.gui_text:text_rect()
	local bg_pad = 8
	local xl_pad = 64
	row_item.gui_panel:set_height(h)
	row_item.gui_panel:set_width(safe_rect.width / 2 + xl_pad)
	row_item.gui_panel:set_x(safe_rect.width / 2 - xl_pad)
	local sh = math.min(h, 22)
	row_item.gui_slider_bg:set_h(sh)
	row_item.gui_slider_bg:set_w(self:_left_align() - safe_rect.width / 2 - bg_pad * 2)
	row_item.gui_slider_bg:set_x(xl_pad)
	row_item.gui_slider_bg:set_center_y(h / 2)
	row_item.gui_slider_text:set_font_size(tweak_data.menu.stats_font_size)
	row_item.gui_slider_text:set_size(row_item.gui_slider_bg:size())
	row_item.gui_slider_text:set_position(row_item.gui_slider_bg:position())
	row_item.gui_slider_text:set_y(row_item.gui_slider_text:y())
	row_item.gui_slider_gfx:set_h(sh - 4)
	row_item.gui_slider_gfx:set_x(row_item.gui_slider_bg:x() + 2)
	row_item.gui_slider_gfx:set_y(row_item.gui_slider_bg:y() + 2)
	row_item.gui_slider:set_x(row_item.gui_slider_bg:x() + 2)
	row_item.gui_slider:set_y(row_item.gui_slider_bg:y() + 2)
	row_item.gui_slider:set_w(row_item.gui_slider_bg:w() - 4)
	row_item.gui_slider_marker:set_center_y(h / 2)
	row_item.gui_text:set_width(safe_rect.width / 2)
	row_item.gui_text:set_left(self:_right_align() - row_item.gui_panel:x())
	row_item.gui_text:set_height(h)
	local item = self.node:item(row_item.name)
	local where = row_item.gui_slider:left() + row_item.gui_slider:w() * (item:percentage() / 100)
	row_item.gui_slider_marker:set_center_x(where)
	row_item.gui_slider_gfx:set_w(row_item.gui_slider:w() * (item:percentage() / 100))
	if row_item.gui_info_panel then
		self:_align_info_panel(row_item)
	end
end
function MenuNodeGui:_align_toggle(row_item)
	local safe_rect = managers.viewport:get_safe_rect_pixels()
	row_item.gui_text:set_font_size(self.font_size)
	local x, y, w, h = row_item.gui_text:text_rect()
	row_item.gui_text:set_height(h)
	row_item.gui_panel:set_height(h)
	row_item.gui_panel:set_width(safe_rect.width / 2 + xl_pad)
	row_item.gui_panel:set_x(safe_rect.width / 2 - xl_pad)
	if row_item.gui_option then
		row_item.gui_option:set_font_size(self.font_size)
		row_item.gui_option:set_width(self:_left_align() - row_item.gui_panel:x())
		row_item.gui_option:set_right(self:_left_align() - row_item.gui_panel:x())
		row_item.gui_option:set_height(h)
	end
	row_item.gui_text:set_width(safe_rect.width / 2)
	row_item.gui_text:set_left(self:_right_align() - row_item.gui_panel:x())
	if row_item.gui_icon then
		row_item.gui_icon:set_w(h)
		row_item.gui_icon:set_h(h)
		row_item.gui_icon:set_right(self:_left_align() - row_item.gui_panel:x())
	end
	if row_item.gui_title then
		row_item.gui_title:set_font_size(self.font_size)
		row_item.gui_title:set_height(h)
		if row_item.gui_icon then
			row_item.gui_title:set_right(row_item.gui_icon:left() - self._align_line_padding * 2)
		else
			row_item.gui_title:set_right(self:_left_align())
		end
	end
	if row_item.gui_info_panel then
		if row_item.item:info_panel() == "lobby_campaign" then
			self:_align_lobby_campaign(row_item)
		else
			self:_align_info_panel(row_item)
		end
	end
end
function MenuNodeGui:_align_multi_choice(row_item)
	local safe_rect = managers.viewport:get_safe_rect_pixels()
	local right_align = self:_right_align()
	local left_align = self:_left_align()
	if row_item.item:parameters().filter then
		right_align = right_align + 230
		left_align = left_align + 230
	end
	row_item.gui_panel:set_width(safe_rect.width / 2 + xl_pad)
	row_item.gui_panel:set_x(safe_rect.width / 2 - xl_pad)
	row_item.arrow_right:set_size(24 * tweak_data.scale.multichoice_arrow_multiplier, 24 * tweak_data.scale.multichoice_arrow_multiplier)
	row_item.arrow_right:set_right(left_align - row_item.gui_panel:x())
	row_item.arrow_left:set_size(24 * tweak_data.scale.multichoice_arrow_multiplier, 24 * tweak_data.scale.multichoice_arrow_multiplier)
	row_item.arrow_left:set_right(row_item.arrow_right:left() + 2 * (1 - tweak_data.scale.multichoice_arrow_multiplier))
	row_item.gui_text:set_width(row_item.arrow_left:left() - self._align_line_padding * 2)
	local x, y, w, h = row_item.gui_text:text_rect()
	row_item.gui_text:set_h(h)
	row_item.choice_panel:set_w(safe_rect.width - right_align)
	row_item.choice_panel:set_h(h)
	row_item.choice_panel:set_left(right_align - row_item.gui_panel:x())
	row_item.choice_text:set_w(row_item.choice_panel:w())
	row_item.choice_text:set_h(h)
	row_item.choice_text:set_left(0)
	row_item.arrow_right:set_center_y(row_item.choice_panel:center_y())
	row_item.arrow_left:set_center_y(row_item.choice_panel:center_y())
	row_item.gui_text:set_left(0)
	row_item.gui_text:set_height(h)
	row_item.gui_panel:set_height(h)
	if row_item.gui_info_panel then
		self:_align_item_gui_info_panel(row_item.gui_info_panel)
		if row_item.item:info_panel() == "lobby_campaign" then
			self:_align_lobby_campaign(row_item)
		elseif row_item.item:info_panel() == "lobby_difficulty" then
			self:_align_lobby_difficulty(row_item)
		else
			self:_align_info_panel(row_item)
		end
	end
end
function MenuNodeGui:_align_chat(row_item)
	local safe_rect = managers.viewport:get_safe_rect_pixels()
	row_item.chat_input:script().text:set_font_size(tweak_data.hud.chatinput_size)
	row_item.chat_input:set_h(25 * tweak_data.scale.chat_multiplier)
	row_item.chat_output:script().scrollus:set_font_size(tweak_data.hud.chatoutput_size)
	row_item.gui_panel:set_w(safe_rect.width / 2)
	row_item.gui_panel:set_right(safe_rect.width)
	row_item.gui_panel:set_h(118 * tweak_data.scale.chat_menu_h_multiplier + 25 * tweak_data.scale.chat_multiplier + 2)
	row_item.chat_input:set_w(row_item.gui_panel:w())
	row_item.chat_input:set_bottom(row_item.gui_panel:h())
	row_item.chat_input:set_right(row_item.gui_panel:w())
	row_item.border:set_w(row_item.chat_input:w())
	row_item.border:set_bottom(row_item.chat_input:top())
	local h = row_item.gui_panel:h() - row_item.chat_input:h() - 2
	row_item.chat_output:set_h(h)
	row_item.chat_output:set_w(row_item.gui_panel:w())
	row_item.chat_output:set_bottom(h)
	row_item.chat_output:set_right(row_item.gui_panel:w())
end
function MenuNodeGui:_update_scaled_values()
	self.font_size = tweak_data.menu.default_font_size
	self._align_line_padding = 10 * tweak_data.scale.align_line_padding_multiplier
end
function MenuNodeGui:resolution_changed()
	self:_update_scaled_values()
	local safe_rect = managers.viewport:get_safe_rect_pixels()
	local res = RenderSettings.resolution
	self._info_bg_rect:set_shape(0, tweak_data.load_level.upper_saferect_border, safe_rect.width * 0.41, safe_rect.height - tweak_data.load_level.upper_saferect_border * 2)
	for _, row_item in pairs(self.row_items) do
		if row_item.item:parameters().trial_buy then
			self:_setup_trial_buy(row_item)
		end
		if row_item.item:parameters().fake_disabled then
			self:_setup_fake_disabled(row_item)
		end
		if row_item.item:parameters().back then
		elseif row_item.type == "slider" then
			self:_align_slider(row_item)
		elseif row_item.type == "toggle" then
			self:_align_toggle(row_item)
		elseif row_item.type == "chat" then
			self:_align_chat(row_item)
		elseif row_item.type == "multi_choice" then
			self:_align_multi_choice(row_item)
		elseif row_item.type ~= "kitslot" then
			self:_align_normal(row_item)
		end
	end
	self._topic_panel:set_shape(safe_rect.x, safe_rect.y, safe_rect.width, tweak_data.load_level.upper_saferect_border)
	self._topic_text:set_font_size(tweak_data.menu.topic_font_size)
	self._topic_text:set_shape(0, 0, self._topic_panel:w(), tweak_data.load_level.upper_saferect_border - tweak_data.load_level.border_pad)
	MenuNodeGui.super.resolution_changed(self)
	self._align_data.panel:set_center_x(self:_mid_align())
	self._list_arrows.up:set_left(self._align_data.panel:world_center())
	self._list_arrows.down:set_left(self._align_data.panel:world_center())
	self._legends_panel:set_shape(safe_rect.x, safe_rect.y, safe_rect.width, safe_rect.height)
	self:_layout_legends()
end
function MenuNodeGui:_layout_legends()
	local safe_rect = managers.viewport:get_safe_rect_pixels()
	local res = RenderSettings.resolution
	local text = self._legends_panel:child(0)
	local _, _, w, h = text:text_rect()
	self._legends_panel:set_h(h)
	local is_pc = managers.menu:is_pc_controller()
	if is_pc then
		text:set_center_x(self._legends_panel:w() / 2)
	else
		text:set_right(self._legends_panel:w())
	end
	text:set_bottom(self._legends_panel:h())
	self._legends_panel:set_top(self._main_panel:bottom() + tweak_data.load_level.border_pad)
end
function MenuNodeGui:set_visible(visible)
	MenuNodeGui.super.set_visible(self, visible)
	if visible then
		managers.menu:active_menu().renderer:set_stencil_image(self._stencil_image)
		managers.menu:active_menu().renderer:set_stencil_align(self._stencil_align, self._stencil_align_percent)
		managers.menu:active_menu().renderer:set_stencil_image(self._stencil_image)
		managers.menu:active_menu().renderer:set_bg_visible(self._bg_visible)
	end
end
function MenuNodeGui:close(...)
	for _, row_item in ipairs(self.row_items) do
		if row_item.level_movie then
			managers.video:remove_video(row_item.level_movie)
			row_item.level_movie:stop()
			row_item.level_movie:parent():remove(row_item.level_movie)
			row_item.level_movie = nil
			MenuNodeGui.lobby_campaign = nil
		else
		end
	end
	MenuNodeGui.super.close(self, ...)
end
