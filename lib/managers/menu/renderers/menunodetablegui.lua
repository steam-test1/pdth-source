MenuNodeTableGui = MenuNodeTableGui or class(MenuNodeGui)
function MenuNodeTableGui:init(node, layer, parameters)
	MenuNodeTableGui.super.init(self, node, layer, parameters)
	self:_setup_topics(node)
end
function MenuNodeTableGui:_setup_panels(node)
	MenuNodeTableGui.super._setup_panels(self, node)
	local safe_rect_pixels = managers.viewport:get_safe_rect_pixels()
	self._column_topics_panel = self.ws:panel():panel({
		x = self:_world_right_align(),
		y = safe_rect_pixels.y,
		w = safe_rect_pixels.width - self:_right_align(),
		h = 28
	})
	self._column_topics_panel:set_y(self._topic_panel:bottom())
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
	mini_info:set_width(self._info_bg_rect:w() - tweak_data.menu.info_padding * 2)
	mini_text:set_width(mini_info:w())
	mini_info:set_height(100)
	mini_text:set_height(100)
	mini_info:set_top(self._info_bg_rect:bottom() + tweak_data.menu.info_padding)
	mini_text:set_top(0)
	mini_info:set_left(tweak_data.menu.info_padding)
	mini_text:set_left(0)
	self._mini_info_text = mini_text
end
function MenuNodeTableGui:set_mini_info(text)
	self._mini_info_text:set_text(text)
end
function MenuNodeTableGui:_setup_topics(node)
	local columns = node:columns()
	local total_proportions = node:parameters().total_proportions
	local x = 0
	for i, data in ipairs(columns) do
		local text = self._column_topics_panel:text({
			font_size = self.font_size,
			align = data.align,
			halign = data.align,
			vertical = "center",
			hvertical = "center",
			font = self.font,
			color = self.color,
			layer = self.layers.items,
			text = data.text
		})
		text:set_h(self._column_topics_panel:h())
		local w = data.proportions / total_proportions * self._column_topics_panel:w()
		text:set_w(w)
		text:set_x(x)
		x = x + w
	end
end
function MenuNodeTableGui:_create_menu_item(row_item)
	if row_item.type == "column" then
		local columns = row_item.node:columns()
		local total_proportions = row_item.node:parameters().total_proportions
		row_item.gui_panel = self.item_panel:panel({
			x = self:_right_align(),
			w = self._column_topics_panel:w()
		})
		row_item.gui_columns = {}
		local x = 0
		for i, data in ipairs(columns) do
			local text = row_item.gui_panel:text({
				font_size = self.font_size,
				x = row_item.position.x,
				y = 0,
				align = data.align,
				halign = data.align,
				vertical = "center",
				font = row_item.font,
				color = row_item.color,
				layer = self.layers.items,
				text = row_item.item:parameters().columns[i]
			})
			row_item.gui_columns[i] = text
			local _, _, w, h = text:text_rect()
			text:set_h(h)
			local w = data.proportions / total_proportions * row_item.gui_panel:w()
			text:set_w(w)
			text:set_x(x)
			x = x + w
		end
		local x, y, w, h = row_item.gui_columns[1]:text_rect()
		row_item.gui_panel:set_height(h)
	elseif row_item.type == "server_column" then
		local columns = row_item.node:columns()
		local total_proportions = row_item.node:parameters().total_proportions
		local safe_rect = managers.viewport:get_safe_rect_pixels()
		local xl_pad = 54
		row_item.gui_panel = self.item_panel:panel({
			x = safe_rect.width / 2 - xl_pad,
			w = safe_rect.width / 2 + xl_pad
		})
		row_item.gui_columns = {}
		local x = 0
		for i, data in ipairs(columns) do
			local text = row_item.gui_panel:text({
				font_size = tweak_data.menu.server_list_font_size,
				x = row_item.position.x,
				y = 0,
				align = data.align,
				halign = data.align,
				vertical = "center",
				font = row_item.font,
				color = row_item.color,
				layer = self.layers.items,
				text = row_item.item:parameters().columns[i]
			})
			row_item.gui_columns[i] = text
			local _, _, w, h = text:text_rect()
			text:set_h(h)
			local w = data.proportions / total_proportions * row_item.gui_panel:w()
			text:set_w(w)
			text:set_x(x)
			x = x + w
		end
		local x, y, w, h = row_item.gui_columns[1]:text_rect()
		row_item.gui_panel:set_height(h)
		local level_id = row_item.item:parameters().level_id
		row_item.gui_info_panel = self.safe_rect_panel:panel({
			visible = false,
			layer = self.layers.items,
			x = 0,
			y = 0,
			w = self:_left_align(),
			h = self._main_panel:h()
		})
		row_item.heist_name = row_item.gui_info_panel:text({
			visible = false,
			text = string.upper(row_item.item:parameters().level_name),
			layer = self.layers.items,
			font = self.font,
			font_size = tweak_data.menu.challenges_font_size,
			color = row_item.color,
			align = "left",
			vertical = "left"
		})
		local briefing_text = string.upper(level_id and managers.localization:text(tweak_data.levels[level_id].briefing_id) or "")
		row_item.heist_briefing = row_item.gui_info_panel:text({
			visible = true,
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
		local font_size = tweak_data.menu.lobby_info_font_size
		row_item.server_title = row_item.gui_info_panel:text({
			name = "server_title",
			text = string.upper(managers.localization:text("menu_lobby_server_title")),
			font = "fonts/font_univers_530_bold",
			font_size = font_size,
			align = "left",
			vertical = "center",
			w = 256,
			h = font_size,
			layer = 1
		})
		row_item.server_text = row_item.gui_info_panel:text({
			name = "server_text",
			text = string.upper(row_item.item:parameters().host_name),
			font = "fonts/font_univers_530_bold",
			color = tweak_data.hud.prime_color,
			font_size = font_size,
			align = "left",
			vertical = "center",
			w = 256,
			h = font_size,
			layer = 1
		})
		row_item.server_info_title = row_item.gui_info_panel:text({
			name = "server_info_title",
			text = string.upper(managers.localization:text("menu_lobby_server_state_title")),
			font = self.font,
			font_size = font_size,
			align = "left",
			vertical = "center",
			w = 256,
			h = font_size,
			layer = 1
		})
		row_item.server_info_text = row_item.gui_info_panel:text({
			name = "server_info_text",
			text = string.upper(row_item.item:parameters().state_name),
			font = self.font,
			color = tweak_data.hud.prime_color,
			font_size = font_size,
			align = "left",
			vertical = "center",
			w = 256,
			h = font_size,
			layer = 1
		})
		row_item.level_title = row_item.gui_info_panel:text({
			name = "level_title",
			text = string.upper(managers.localization:text("menu_lobby_campaign_title")),
			font = "fonts/font_univers_530_bold",
			font_size = font_size,
			align = "left",
			vertical = "center",
			w = 256,
			h = font_size,
			layer = 1
		})
		row_item.level_text = row_item.gui_info_panel:text({
			name = "level_text",
			text = string.upper(row_item.item:parameters().real_level_name),
			font = "fonts/font_univers_530_bold",
			color = tweak_data.hud.prime_color,
			font_size = font_size,
			align = "left",
			vertical = "center",
			w = 256,
			h = font_size,
			layer = 1
		})
		row_item.difficulty_title = row_item.gui_info_panel:text({
			name = "difficulty_title",
			text = string.upper(managers.localization:text("menu_lobby_difficulty_title")),
			font = "fonts/font_univers_530_bold",
			font_size = font_size,
			align = "left",
			vertical = "center",
			w = 256,
			h = font_size,
			layer = 1
		})
		row_item.difficulty_text = row_item.gui_info_panel:text({
			name = "difficulty_text",
			text = string.upper(managers.localization:text("menu_difficulty_" .. row_item.item:parameters().difficulty)),
			font = "fonts/font_univers_530_bold",
			color = tweak_data.hud.prime_color,
			font_size = font_size,
			align = "left",
			vertical = "center",
			w = 256,
			h = font_size,
			layer = 1
		})
		self:_align_server_column(row_item)
	else
		MenuNodeTableGui.super._create_menu_item(self, row_item)
	end
end
function MenuNodeTableGui:_align_server_column(row_item)
	local safe_rect = managers.viewport:get_safe_rect_pixels()
	self:_align_item_gui_info_panel(row_item.gui_info_panel)
	local font_size = tweak_data.menu.lobby_info_font_size
	local offset = 22 * tweak_data.scale.lobby_info_offset_multiplier
	row_item.server_title:set_font_size(font_size)
	row_item.server_text:set_font_size(font_size)
	local x, y, w, h = row_item.server_title:text_rect()
	row_item.server_title:set_x(tweak_data.menu.info_padding)
	row_item.server_title:set_y(tweak_data.menu.info_padding)
	row_item.server_title:set_w(w)
	row_item.server_text:set_lefttop(row_item.server_title:righttop())
	row_item.server_text:set_w(row_item.gui_info_panel:w())
	row_item.server_info_title:set_font_size(font_size)
	row_item.server_info_text:set_font_size(font_size)
	local x, y, w, h = row_item.server_info_title:text_rect()
	row_item.server_info_title:set_x(tweak_data.menu.info_padding)
	row_item.server_info_title:set_y(tweak_data.menu.info_padding + offset)
	row_item.server_info_title:set_w(w)
	row_item.server_info_text:set_lefttop(row_item.server_info_title:righttop())
	row_item.server_info_text:set_w(row_item.gui_info_panel:w())
	row_item.level_title:set_font_size(font_size)
	row_item.level_text:set_font_size(font_size)
	local x, y, w, h = row_item.level_title:text_rect()
	row_item.level_title:set_x(tweak_data.menu.info_padding)
	row_item.level_title:set_y(tweak_data.menu.info_padding + offset * 2)
	row_item.level_title:set_w(w)
	row_item.level_text:set_lefttop(row_item.level_title:righttop())
	row_item.level_text:set_w(row_item.gui_info_panel:w())
	row_item.difficulty_title:set_font_size(font_size)
	row_item.difficulty_text:set_font_size(font_size)
	local x, y, w, h = row_item.difficulty_title:text_rect()
	row_item.difficulty_title:set_x(tweak_data.menu.info_padding)
	row_item.difficulty_title:set_y(tweak_data.menu.info_padding + offset * 3)
	row_item.difficulty_title:set_w(w)
	row_item.difficulty_text:set_lefttop(row_item.difficulty_title:righttop())
	row_item.difficulty_text:set_w(row_item.gui_info_panel:w())
	local _, _, _, h = row_item.heist_name:text_rect()
	local w = row_item.gui_info_panel:w()
	row_item.heist_name:set_height(h)
	row_item.heist_name:set_w(w)
	row_item.heist_briefing:set_w(w)
	row_item.heist_briefing:set_shape(row_item.heist_briefing:text_rect())
	row_item.heist_briefing:set_x(0)
	row_item.heist_briefing:set_y(tweak_data.menu.info_padding + offset * 4 + tweak_data.menu.info_padding * 2)
end
function MenuNodeTableGui:_setup_main_panel(safe_rect)
	MenuNodeTableGui.super._setup_main_panel(self, safe_rect)
	self._main_panel:set_shape(safe_rect.x, self._column_topics_panel:bottom(), safe_rect.width, self._main_panel:h() - self._column_topics_panel:h())
end
function MenuNodeTableGui:_set_width_and_height(safe_rect)
	self.width = safe_rect.width
	self.height = self._main_panel:h()
end
function MenuNodeTableGui:_setup_item_panel(safe_rect, res)
	MenuNodeTableGui.super._setup_item_panel(self, safe_rect, res)
	self.item_panel:set_top(0)
end
function MenuNodeTableGui:resolution_changed()
	MenuNodeTableGui.super.resolution_changed(self)
	local safe_rect_pixels = managers.viewport:get_safe_rect_pixels()
	self._column_topics_panel:set_shape(safe_rect.x, safe_rect.y, safe_rect.width, 28)
end
