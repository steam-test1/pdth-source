MenuNodeStatsGui = MenuNodeStatsGui or class(MenuNodeGui)
function MenuNodeStatsGui:init(node, layer, parameters)
	MenuNodeStatsGui.super.init(self, node, layer, parameters)
	self._stats_items = {}
	self:_setup_stats(node)
end
function MenuNodeStatsGui:_setup_panels(node)
	MenuNodeStatsGui.super._setup_panels(self, node)
	local safe_rect_pixels = managers.viewport:get_safe_rect_pixels()
end
function MenuNodeStatsGui:_setup_stats(node)
	self:_add_stats({
		topic = managers.localization:text("menu_stats_money"),
		data = managers.experience:total_cash_string(),
		type = "text"
	})
	self:_add_stats({
		topic = managers.localization:text("menu_stats_level_progress"),
		data = managers.experience:current_level() / managers.experience:level_cap(),
		text = "" .. managers.experience:current_level() .. "/" .. managers.experience:level_cap(),
		type = "progress"
	})
	self:_add_stats({
		topic = managers.localization:text("menu_stats_time_played"),
		data = managers.statistics:time_played() .. " " .. managers.localization:text("menu_stats_time"),
		type = "text"
	})
	self:_add_stats({
		topic = managers.localization:text("menu_stats_favourite_campaign"),
		data = string.upper(managers.statistics:favourite_level()),
		type = "text"
	})
	self:_add_stats({
		topic = managers.localization:text("menu_stats_total_completed_campaigns"),
		data = "" .. managers.statistics:total_completed_campaigns(),
		type = "text"
	})
	self:_add_stats({
		topic = managers.localization:text("menu_stats_total_completed_objectives"),
		data = "" .. managers.statistics:total_completed_objectives(),
		type = "text"
	})
	self:_add_stats({
		topic = managers.localization:text("menu_stats_challenges_completion"),
		data = managers.challenges:amount_of_completed_challenges() / managers.challenges:amount_of_challenges(),
		type = "progress"
	})
	self:_add_stats({
		topic = managers.localization:text("menu_stats_favourite_weapon"),
		data = "" .. string.upper(managers.statistics:favourite_weapon()),
		type = "text"
	})
	self:_add_stats({
		topic = managers.localization:text("menu_stats_hit_accuracy"),
		data = "" .. managers.statistics:hit_accuracy() .. "%",
		type = "text"
	})
	self:_add_stats({
		topic = managers.localization:text("menu_stats_total_kills"),
		data = "" .. managers.statistics:total_kills(),
		type = "text"
	})
	self:_add_stats({
		topic = managers.localization:text("menu_stats_total_head_shots"),
		data = "" .. managers.statistics:total_head_shots(),
		type = "text"
	})
	if SystemInfo:platform() == Idstring("WIN32") then
		local y = 30
		for _, panel in ipairs(self._stats_items) do
			y = y + panel:h() + self.spacing
		end
		local safe_rect = managers.viewport:get_safe_rect_pixels()
		local panel = self._main_panel:panel({y = y})
		local text = panel:text({
			font_size = tweak_data.menu.stats_font_size,
			x = safe_rect.x,
			y = 0,
			w = safe_rect.width,
			align = "center",
			halign = "center",
			vertical = "center",
			font = self.font,
			color = self.row_item_color,
			layer = self.layers.items,
			text = managers.localization:text("menu_visit_more_stats"),
			render_template = Idstring("VertexColorTextured")
		})
		local _, _, _, h = text:text_rect()
		text:set_h(h)
		panel:set_h(h)
	end
end
function MenuNodeStatsGui:_add_stats(params)
	local y = 0
	for _, panel in ipairs(self._stats_items) do
		y = y + panel:h() + self.spacing
	end
	local panel = self._main_panel:panel({y = y})
	local topic = panel:text({
		font_size = tweak_data.menu.stats_font_size,
		x = 0,
		y = 0,
		w = self:_left_align(),
		align = "right",
		halign = "right",
		vertical = "center",
		font = self.font,
		color = self.row_item_color,
		layer = self.layers.items,
		text = params.topic,
		render_template = Idstring("VertexColorTextured")
	})
	local x, y, w, h = topic:text_rect()
	topic:set_h(h)
	panel:set_h(h)
	if params.type == "text" then
		local text = panel:text({
			font_size = tweak_data.menu.stats_font_size,
			x = self:_right_align(),
			y = 0,
			h = h,
			align = "left",
			halign = "left",
			vertical = "center",
			font = self.font,
			color = self.color,
			layer = self.layers.items,
			text = params.data,
			render_template = Idstring("VertexColorTextured")
		})
	end
	if params.type == "progress" then
		local bg = panel:rect({
			x = self:_right_align(),
			y = h / 2 - 11,
			w = 256,
			h = 22,
			align = "center",
			halign = "center",
			vertical = "center",
			color = Color.black:with_alpha(0.5),
			layer = self.layers.items - 1
		})
		local bar = panel:gradient({
			orientation = "vertical",
			gradient_points = {
				0,
				Color(1, 1, 0.65882355, 0),
				1,
				Color(1, 0.6039216, 0.4, 0)
			},
			x = self:_right_align() + 2,
			y = bg:y() + 2,
			w = (bg:w() - 4) * params.data,
			h = bg:h() - 4,
			align = "center",
			halign = "center",
			vertical = "center",
			layer = self.layers.items
		})
		local text = panel:text({
			font_size = tweak_data.menu.stats_font_size,
			x = self:_right_align(),
			y = 0,
			h = h,
			w = bg:w(),
			align = "center",
			halign = "center",
			vertical = "center",
			valign = "center",
			font = self.font,
			color = self.color,
			layer = self.layers.items + 1,
			text = params.text or "" .. math.floor(params.data * 100) .. "%",
			render_template = Idstring("VertexColorTextured")
		})
	end
	table.insert(self._stats_items, panel)
end
function MenuNodeStatsGui:_create_menu_item(row_item)
	MenuNodeStatsGui.super._create_menu_item(self, row_item)
end
function MenuNodeStatsGui:_setup_main_panel(safe_rect)
	MenuNodeStatsGui.super._setup_main_panel(self, safe_rect)
end
function MenuNodeStatsGui:_setup_item_panel(safe_rect, res)
	MenuNodeStatsGui.super._setup_item_panel(self, safe_rect, res)
end
function MenuNodeStatsGui:resolution_changed()
	MenuNodeStatsGui.super.resolution_changed(self)
end
