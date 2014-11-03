core:import("CoreMenuNodeGui")
MenuNodeKitGui = MenuNodeKitGui or class(MenuNodeGui)
function MenuNodeKitGui:init(node, layer, parameters)
	MenuNodeKitGui.super.init(self, node, layer, parameters)
end
function MenuNodeKitGui:_create_menu_item(row_item)
	local safe_rect = managers.viewport:get_safe_rect_pixels()
	local align_x = safe_rect.width * self._align_line_proportions
	if row_item.gui_panel then
		self.item_panel:remove(row_item.gui_panel)
	end
	if row_item.type == "kitslot" then
		local category = row_item.item:parameters().category
		local slot = row_item.item:parameters().slot
		row_item.gui_panel = self.item_panel:panel({
			w = self.item_panel:w()
		})
		row_item.gui_text = self:_text_item_part(row_item, row_item.gui_panel, self:_right_align(), "right")
		row_item.gui_text:set_wrap(true)
		row_item.gui_text:set_word_wrap(true)
		row_item.choice_panel = row_item.gui_panel:panel({
			w = self.item_panel:w()
		})
		row_item.choice_text = row_item.choice_panel:text({
			font_size = self.font_size,
			x = self:_right_align(),
			y = 0,
			align = "left",
			halign = "center",
			vertical = "center",
			font = row_item.font,
			color = row_item.item:arrow_visible() and tweak_data.menu.default_changeable_text_color or tweak_data.menu.default_disabled_text_color,
			layer = self.layers.items,
			text = string.upper(row_item.item:text()),
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
			rotation = 180,
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
		row_item.description_panel = self.safe_rect_panel:panel({
			w = self.item_panel:w() / 2,
			h = 112,
			visible = false
		})
		row_item.description_panel:set_left(row_item.choice_panel:left())
		row_item.description_panel_bg = row_item.description_panel:rect({
			color = Color.black:with_alpha(0.5)
		})
		local icon, texture_rect = tweak_data.hud_icons:get_icon_data("fallback")
		row_item.description_icon = row_item.description_panel:bitmap({
			name = "description_icon",
			texture = icon,
			layer = self.layers.items,
			texture_rect = texture_rect,
			x = 0,
			y = 0,
			w = 48,
			h = 48
		})
		row_item.description_progress_text = row_item.description_panel:text({
			font_size = self.font_size,
			x = 0,
			y = 0,
			align = "left",
			halign = "left",
			vertical = "bottom",
			font = row_item.font,
			color = row_item.color,
			layer = self.layers.items,
			text = managers.localization:text("menu_upgrade_progress"),
			wrap = false,
			word_wrap = false,
			render_template = Idstring("VertexColorTextured")
		})
		local _, _, w, h = row_item.description_progress_text:text_rect()
		row_item.progress_bg = row_item.description_panel:rect({
			x = 52 + w + 4,
			y = 0,
			w = 256,
			h = 22,
			align = "center",
			halign = "center",
			vertical = "center",
			color = Color.black:with_alpha(0.5),
			layer = self.layers.items - 1
		})
		row_item.progress_bar = row_item.description_panel:gradient({
			orientation = "vertical",
			gradient_points = {
				0,
				Color(1, 1, 0.65882355, 0),
				1,
				Color(1, 0.6039216, 0.4, 0)
			},
			x = row_item.progress_bg:x() + 2,
			y = row_item.progress_bg:y() + 2,
			w = (row_item.progress_bg:w() - 4) * 0.11,
			h = row_item.progress_bg:h() - 4,
			align = "center",
			halign = "center",
			vertical = "center",
			layer = self.layers.items
		})
		row_item.progress_text = row_item.description_panel:text({
			font_size = tweak_data.menu.stats_font_size,
			x = row_item.progress_bg:x(),
			y = 0,
			h = h,
			w = row_item.progress_bg:w(),
			align = "center",
			halign = "center",
			vertical = "center",
			valign = "center",
			font = self.font,
			color = self.color,
			layer = self.layers.items + 1,
			text = "" .. math.floor(11) .. "%",
			render_template = Idstring("VertexColorTextured")
		})
		row_item.description_text = row_item.description_panel:text({
			font_size = tweak_data.menu.small_font_size,
			x = 0,
			y = 0,
			align = "left",
			halign = "left",
			vertical = "top",
			font = tweak_data.menu.small_font,
			color = row_item.color,
			layer = self.layers.items,
			text = row_item.item:text(),
			wrap = true,
			word_wrap = true,
			render_template = Idstring("VertexColorTextured")
		})
		self:_align_kitslot(row_item)
	else
		MenuNodeKitGui.super._create_menu_item(self, row_item)
	end
end
function MenuNodeKitGui:_setup_main_panel(safe_rect, shape)
	MenuNodeKitGui.super._setup_main_panel(self, safe_rect, shape)
end
function MenuNodeKitGui:reload_item(item)
	local type = item:type()
	if type == "kitslot" then
		self:_reload_kitslot_item(item)
	else
		MenuNodeKitGui.super.reload_item(self, item)
	end
end
function MenuNodeKitGui:_reload_kitslot_item(item)
	local row_item = self:row_item(item)
	local icon_id, description = item:icon_and_description()
	if icon_id then
		local icon, texture_rect = tweak_data.hud_icons:get_icon_data(icon_id)
		row_item.description_icon:set_image(icon, texture_rect[1], texture_rect[2], texture_rect[3], texture_rect[4])
		row_item.description_text:set_text(string.upper(description))
	end
	row_item.choice_text:set_text(string.upper(item:text()))
	local current, total = item:upgrade_progress()
	local value = total ~= 0 and current / total or 0
	row_item.progress_bar:set_w((row_item.progress_bg:w() - 4) * value)
	row_item.progress_text:set_text(current .. "/" .. total)
	row_item.arrow_left:set_color(item:left_arrow_visible() and tweak_data.menu.arrow_available or tweak_data.menu.arrow_unavailable)
	row_item.arrow_right:set_color(item:right_arrow_visible() and tweak_data.menu.arrow_available or tweak_data.menu.arrow_unavailable)
end
function MenuNodeKitGui:_setup_item_size(row_item)
	local type = row_item.item:type()
	if type == "kitslot" then
		self:_setup_kitslot_size(row_item)
	else
		MenuNodeKitGui.super._setup_item_size(self, row_item)
	end
end
function MenuNodeKitGui:_setup_kitslot_size(row_item)
end
function MenuNodeKitGui:_highlight_row_item(row_item)
	if row_item then
		self:_align_marker(row_item)
		row_item.color = self.row_item_hightlight_color
		if row_item.type == "kitslot" then
			row_item.description_panel:set_visible(true)
			row_item.choice_text:set_color(row_item.color)
			row_item.choice_text:set_font(tweak_data.menu.default_font_no_outline_id)
			row_item.arrow_left:set_image("guis/textures/menu_arrows", 24, 0, 24, 24)
			row_item.arrow_right:set_image("guis/textures/menu_arrows", 24, 0, 24, 24)
			row_item.arrow_left:set_color(row_item.item:left_arrow_visible() and tweak_data.menu.arrow_available or tweak_data.menu.arrow_unavailable)
			row_item.arrow_right:set_color(row_item.item:right_arrow_visible() and tweak_data.menu.arrow_available or tweak_data.menu.arrow_unavailable)
		else
			MenuNodeKitGui.super._highlight_row_item(self, row_item)
		end
	end
end
function MenuNodeKitGui:_fade_row_item(row_item)
	if row_item then
		row_item.color = self.row_item_color
		if row_item.type == "kitslot" then
			row_item.description_panel:set_visible(false)
			row_item.choice_text:set_color(row_item.item:arrow_visible() and tweak_data.menu.default_changeable_text_color or tweak_data.menu.default_disabled_text_color)
			row_item.choice_text:set_font(tweak_data.menu.default_font_id)
			row_item.arrow_left:set_image("guis/textures/menu_arrows", 0, 0, 24, 24)
			row_item.arrow_right:set_image("guis/textures/menu_arrows", 0, 0, 24, 24)
			row_item.arrow_left:set_color(row_item.item:left_arrow_visible() and tweak_data.menu.arrow_available or tweak_data.menu.arrow_unavailable)
			row_item.arrow_right:set_color(row_item.item:right_arrow_visible() and tweak_data.menu.arrow_available or tweak_data.menu.arrow_unavailable)
		else
			MenuNodeKitGui.super._fade_row_item(self, row_item)
		end
	end
end
function MenuNodeKitGui:_align_kitslot(row_item)
	local safe_rect = managers.viewport:get_safe_rect_pixels()
	local xl_pad = 64
	row_item.gui_text:set_font_size(self.font_size)
	row_item.choice_text:set_font_size(self.font_size)
	row_item.gui_panel:set_width(safe_rect.width / 2 + xl_pad)
	row_item.gui_panel:set_x(safe_rect.width / 2 - xl_pad)
	row_item.arrow_right:set_size(24 * tweak_data.scale.multichoice_arrow_multiplier, 24 * tweak_data.scale.multichoice_arrow_multiplier)
	row_item.arrow_right:set_right(self:_left_align() - row_item.gui_panel:x())
	row_item.arrow_left:set_size(24 * tweak_data.scale.multichoice_arrow_multiplier, 24 * tweak_data.scale.multichoice_arrow_multiplier)
	row_item.arrow_left:set_right(row_item.arrow_right:left() + 2 * (1 - tweak_data.scale.multichoice_arrow_multiplier))
	row_item.gui_text:set_width(row_item.arrow_left:left() - self._align_line_padding * 2)
	local x, y, w, h = row_item.gui_text:text_rect()
	row_item.gui_text:set_h(h)
	row_item.choice_panel:set_w(safe_rect.width - self:_right_align())
	row_item.choice_panel:set_h(h)
	row_item.choice_panel:set_left(self:_right_align() - row_item.gui_panel:x())
	row_item.choice_text:set_w(row_item.choice_panel:w())
	row_item.choice_text:set_h(h)
	row_item.choice_text:set_left(0)
	row_item.arrow_right:set_center_y(row_item.choice_panel:center_y())
	row_item.arrow_left:set_center_y(row_item.choice_panel:center_y())
	row_item.gui_text:set_left(0)
	row_item.gui_text:set_height(h)
	row_item.gui_panel:set_height(h)
	row_item.description_panel:set_h(126 * tweak_data.scale.kit_menu_description_h_scale)
	row_item.description_panel:set_w(safe_rect.width / 2)
	row_item.description_panel:set_right(safe_rect.width)
	row_item.description_panel:set_bottom(safe_rect.height - tweak_data.menu.upper_saferect_border - tweak_data.menu.border_pad)
	row_item.description_panel_bg:set_size(row_item.description_panel:size())
	local pad = 4 * tweak_data.scale.kit_menu_bar_scale
	row_item.description_icon:set_size(48 * tweak_data.scale.kit_menu_bar_scale, 48 * tweak_data.scale.kit_menu_bar_scale)
	row_item.description_icon:set_position(pad, pad)
	row_item.description_text:set_font_size(tweak_data.menu.kit_description_font_size)
	row_item.description_text:set_h(row_item.description_panel:h())
	row_item.description_text:set_w(safe_rect.width / 2 - (row_item.description_icon:right() + 4) - pad)
	row_item.description_text:set_y(pad)
	row_item.description_text:set_left(row_item.description_icon:right() + 4)
	row_item.description_progress_text:set_font_size(self.font_size)
	row_item.description_progress_text:set_left(pad)
	local _, _, w, h = row_item.description_progress_text:text_rect()
	row_item.description_progress_text:set_w(w)
	row_item.description_progress_text:set_bottom(row_item.description_panel:h() - pad)
	row_item.progress_bg:set_h(22 * tweak_data.scale.kit_menu_bar_scale)
	row_item.progress_bg:set_bottom(row_item.description_panel_bg:h() - pad)
	row_item.progress_bg:set_left(row_item.description_progress_text:right() + 8)
	row_item.progress_bg:set_w(row_item.description_panel:w() - row_item.progress_bg:left() - pad)
	local current, total = row_item.item:upgrade_progress()
	local value = total ~= 0 and current / total or 0
	row_item.progress_bar:set_h(row_item.progress_bg:h() - 4)
	row_item.progress_bar:set_w((row_item.progress_bg:w() - 4) * value)
	row_item.progress_bar:set_position(row_item.progress_bg:x() + 2, row_item.progress_bg:y() + 2)
	row_item.progress_text:set_font_size(tweak_data.menu.stats_font_size)
	row_item.progress_text:set_size(row_item.progress_bg:size())
	row_item.progress_text:set_position(row_item.progress_bg:x(), row_item.progress_bg:y())
end
function MenuNodeKitGui:_update_scaled_values()
	MenuNodeKitGui.super._update_scaled_values(self)
	self.font_size = tweak_data.menu.kit_default_font_size
end
function MenuNodeKitGui:resolution_changed()
	self:_update_scaled_values()
	for _, row_item in pairs(self.row_items) do
		if row_item.type == "kitslot" then
			self:_align_kitslot(row_item)
		end
	end
	MenuNodeKitGui.super.resolution_changed(self)
end
