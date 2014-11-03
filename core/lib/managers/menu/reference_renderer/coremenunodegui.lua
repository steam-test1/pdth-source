core:module("CoreMenuNodeGui")
core:import("CoreUnit")
NodeGui = NodeGui or class()
function NodeGui:init(node, layer, parameters)
	self.node = node
	self.name = node:parameters().name
	self.font = "core/fonts/diesel"
	self.font_size = 28
	self.topic_font_size = 48
	self.spacing = 3
	self.ws = Overlay:gui():create_screen_workspace()
	local safe_rect_pixels = managers.viewport:get_safe_rect_pixels()
	self._main_panel = self.ws:panel():panel({
		x = safe_rect_pixels.x,
		y = safe_rect_pixels.y,
		w = safe_rect_pixels.width,
		h = safe_rect_pixels.height
	})
	self.item_panel = self._main_panel:panel({
		w = safe_rect_pixels.width,
		h = safe_rect_pixels.height
	})
	self.back_panel = self.ws:panel():panel({
		w = safe_rect_pixels.width,
		h = safe_rect_pixels.height
	})
	self.safe_rect_panel = self.back_panel
	self.ws:show()
	self.layers = {}
	self.layers.first = layer
	self.layers.background = layer
	self.layers.marker = layer + 1
	self.layers.items = layer + 2
	self.layers.last = self.layers.items
	self.localize_strings = true
	self.background_color = Color(1, 0.06666667, 0.14117648, 0.20784314)
	self.row_item_color = Color(1, 0.5529412, 0.6901961, 0.827451)
	self.row_item_hightlight_color = Color(1, 0.5529412, 0.6901961, 0.827451)
	if parameters then
		for param_name, param_value in pairs(parameters) do
			self[param_name] = param_value
		end
	end
	self.background = self.ws:panel():rect({
		color = self.background_color,
		layer = self.layers.background
	})
	self.background:set_visible(true)
	if self.texture then
		self.texture.layer = self.layers.background
		self.texture = self.ws:panel():bitmap(self.texture)
		self.texture:set_visible(true)
	end
	self:_setup_panels(node)
	self.row_items = {}
	self:_setup_item_rows(node)
end
function NodeGui:_setup_panels(node)
end
function NodeGui:_setup_item_rows(node)
	local items = node:items()
	local i = 0
	for _, item in pairs(items) do
		if item:visible() then
			local item_name = item:parameters().name
			local item_text = "menu item missing 'text_id'"
			local help_text
			local params = item:parameters()
			if params.text_id then
				if self.localize_strings and params.localize ~= "false" then
					item_text = managers.localization:text(params.text_id)
				else
					item_text = params.text_id
				end
			end
			if params.help_id then
				help_text = managers.localization:text(params.help_id)
			end
			local row_item = {}
			table.insert(self.row_items, row_item)
			row_item.item = item
			row_item.node = node
			row_item.type = item._type
			row_item.name = item_name
			row_item.position = {
				x = 0,
				y = self.font_size * i + self.spacing * (i - 1)
			}
			row_item.color = self.row_item_color
			row_item.font = self.font
			row_item.text = item_text
			row_item.help_text = help_text
			row_item.align = params.align or "left"
			row_item.halign = params.halign or "left"
			row_item.vertical = params.vertical or "center"
			self:_create_menu_item(row_item)
			self:reload_item(item)
			i = i + 1
		end
	end
	self:_setup_size()
	self:scroll_setup()
	self:_flash_background_setup()
	self:_set_item_positions()
	self._highlighted_item = nil
end
function NodeGui:refresh_gui(node)
	self:_clear_gui()
	self:_setup_item_rows(node)
end
function NodeGui:_clear_gui()
	for _, row_item in ipairs(self.row_items) do
		if alive(row_item.gui_panel) then
			if row_item.item:parameters().back then
				self.back_panel:remove(row_item.gui_panel)
			else
				self.item_panel:remove(row_item.gui_panel)
			end
		end
		if alive(row_item.gui_info_panel) then
			self.safe_rect_panel:remove(row_item.gui_info_panel)
		end
	end
	self.row_items = {}
end
function NodeGui:close()
	if self._menu_plane then
		World:newgui():destroy_workspace(self.ws)
	else
		Overlay:gui():destroy_workspace(self.ws)
	end
	if self._menu_plane then
		World:delete_unit(self._menu_plane)
	end
	self.ws = nil
end
function NodeGui:layer()
	return self.layers.last
end
function NodeGui:set_visible(visible)
	if visible then
		self.ws:show()
	else
		self.ws:hide()
	end
end
function NodeGui:reload_item(item)
	local type = item:type()
	if type == "" then
		self:_reload_item(item)
	end
	if type == "toggle" then
		self:_reload_toggle_item(item)
	end
	if type == "slider" then
		self:_reload_slider_item(item)
	end
end
function NodeGui:_reload_item(item)
	local row_item = self:row_item(item)
	local params = item:parameters()
	if params.text_id then
		if self.localize_strings and params.localize ~= "false" then
			item_text = managers.localization:text(params.text_id)
		else
			item_text = params.text_id
		end
	end
	if row_item then
		row_item.text = item_text
		row_item.gui_panel:set_text(row_item.text)
	end
end
function NodeGui:_reload_toggle_item(item)
	local row_item = self:row_item(item)
	if self.localize_strings and item:selected_option():parameters().localize ~= "false" then
		row_item.option_text = managers.localization:text(item:selected_option():parameters().text_id)
	else
		row_item.option_text = item:selected_option():parameters().text_id
	end
	row_item.gui_panel:set_text(row_item.text .. ": " .. row_item.option_text)
end
function NodeGui:_reload_slider_item(item)
	local row_item = self:row_item(item)
	local value = string.format("%.0f", item:percentage())
	row_item.gui_panel:set_text(row_item.text .. ": " .. value .. "%")
end
function NodeGui:_create_menu_item(row_item)
end
function NodeGui:_reposition_items(highlighted_row_item)
	local safe_rect = managers.viewport:get_safe_rect_pixels()
	local dy = 0
	if highlighted_row_item then
		if highlighted_row_item.item:parameters().back then
			return
		end
		if self._main_panel:world_y() > highlighted_row_item.gui_panel:world_y() then
			dy = -(highlighted_row_item.gui_panel:world_y() - self._main_panel:world_y())
		elseif self._main_panel:world_y() + self._main_panel:h() < highlighted_row_item.gui_panel:world_y() + highlighted_row_item.gui_panel:h() then
			dy = -(highlighted_row_item.gui_panel:world_y() + highlighted_row_item.gui_panel:h() - (self._main_panel:world_y() + self._main_panel:h()))
		end
		local old_dy = self._scroll_data.dy_left
		local is_same_dir = 0 < math.abs(old_dy) and (math.sign(dy) == math.sign(old_dy) or dy == 0)
		if is_same_dir then
			local within_view = math.within(highlighted_row_item.gui_panel:world_y(), self._main_panel:world_y(), self._main_panel:world_y() + self._main_panel:h())
			if within_view then
				dy = math.max(math.abs(old_dy), math.abs(dy)) * math.sign(old_dy)
			end
		end
	end
	self:scroll_start(dy)
end
function NodeGui:scroll_setup()
	self._scroll_data = {}
	self._scroll_data.max_scroll_duration = 0.5
	self._scroll_data.scroll_speed = (self.font_size + self.spacing * 2) / 0.1
	self._scroll_data.dy_total = 0
	self._scroll_data.dy_left = 0
end
function NodeGui:scroll_start(dy)
	local speed = self._scroll_data.scroll_speed
	if speed > 0 and math.abs(dy / speed) > self._scroll_data.max_scroll_duration then
		speed = math.abs(dy) / self._scroll_data.max_scroll_duration
	end
	self._scroll_data.speed = speed
	self._scroll_data.dy_total = dy
	self._scroll_data.dy_left = dy
	self:scroll_update(TimerManager:main():delta_time())
end
function NodeGui:scroll_update(dt)
	local dy_left = self._scroll_data.dy_left
	if dy_left ~= 0 then
		local speed = self._scroll_data.speed
		local dy
		if speed <= 0 then
			dy = dy_left
		else
			dy = math.lerp(0, dy_left, math.clamp(math.sign(dy_left) * speed * dt / dy_left, 0, 1))
		end
		self._scroll_data.dy_left = self._scroll_data.dy_left - dy
		self.item_panel:move(0, dy)
	end
end
function NodeGui:highlight_item(item, mouse_over)
	if not item then
		return
	end
	local item_name = item:parameters().name
	local row_item = self:row_item(item)
	self:_highlight_row_item(row_item, mouse_over)
	self:_reposition_items(row_item)
	self._highlighted_item = item
end
function NodeGui:_highlight_row_item(row_item, mouse_over)
	if row_item then
		row_item.color = row_item_hightlight_color or self.row_item_hightlight_color
		row_item.gui_panel:set_color(row_item.color)
	end
end
function NodeGui:fade_item(item)
	local item_name = item:parameters().name
	local row_item = self:row_item(item)
	self:_fade_row_item(row_item)
end
function NodeGui:_fade_row_item(row_item)
	if row_item then
		row_item.color = row_item.row_item_color or self.row_item_color
		row_item.gui_panel:set_color(row_item.color)
	end
end
function NodeGui:row_item(item)
	local item_name = item:parameters().name
	for _, row_item in ipairs(self.row_items) do
		if row_item.name == item_name then
			return row_item
		end
	end
	return nil
end
function NodeGui:row_item_by_name(item_name)
	for _, row_item in ipairs(self.row_items) do
		if row_item.name == item_name then
			return row_item
		end
	end
	return nil
end
function NodeGui:update(t, dt)
	if self._menu_plane then
		self._menu_plane:set_rotation(Rotation(math.sin(t * 60) * 40, math.sin(t * 50) * 30, 0))
	end
	self:scroll_update(dt)
end
function NodeGui:_item_panel_height()
	local height = 0
	for _, row_item in pairs(self.row_items) do
		if not row_item.item:parameters().back then
			local x, y, w, h = row_item.gui_panel:shape()
			height = height + h + self.spacing
		end
	end
	return height
end
function NodeGui:_set_item_positions()
	local total_height = self:_item_panel_height()
	local current_y = 0
	local current_item_height = 0
	for _, row_item in pairs(self.row_items) do
		if not row_item.item:parameters().back then
			row_item.position.y = current_y
			row_item.gui_panel:set_y(row_item.position.y)
			local x, y, w, h = row_item.gui_panel:shape()
			current_item_height = h + self.spacing
			current_y = current_y + current_item_height
		end
	end
end
function NodeGui:resolution_changed()
	self:_setup_size()
	self:_set_item_positions()
	self:highlight_item(self._highlighted_item)
end
function NodeGui:_setup_main_panel(safe_rect)
	self._main_panel:set_shape(safe_rect.x, safe_rect.y, safe_rect.width, safe_rect.height)
end
function NodeGui:_set_width_and_height(safe_rect)
	self.width = safe_rect.width
	self.height = safe_rect.height
end
function NodeGui:_setup_item_panel(safe_rect, res)
	local item_panel_offset = safe_rect.height * 0.5 - #self.row_items * 0.5 * (self.font_size + self.spacing)
	if item_panel_offset < 0 then
		item_panel_offset = 0
	end
	self.item_panel:set_shape(0, 0 + item_panel_offset, safe_rect.width, self:_item_panel_height())
	self.item_panel:set_w(safe_rect.width)
	self.background:set_shape(0, 0, res.x, res.y)
end
function NodeGui:_setup_size()
	local safe_rect = managers.viewport:get_safe_rect_pixels()
	local res = RenderSettings.resolution
	if not self._menu_plane then
		self.ws:set_screen(res.x, res.y, 0, 0, res.x, res.y)
	end
	self:_setup_main_panel(safe_rect)
	self:_set_width_and_height(safe_rect)
	self:_setup_item_panel(safe_rect, res)
	self.background:set_shape(0, 0, res.x, res.y)
	if self.texture then
		self.texture:set_width(res.x)
		self.texture:set_height(res.x / 2)
		self.texture:set_center_x(safe_rect.x + safe_rect.width / 2)
		self.texture:set_center_y(safe_rect.y + safe_rect.height / 2)
	end
	self.back_panel:set_shape(safe_rect.x, safe_rect.y, safe_rect.width, safe_rect.height)
	for _, row_item in pairs(self.row_items) do
		if row_item.item:parameters().back then
			row_item.gui_panel:set_font_size(self.font_size)
			do
				local x, y, w, h = row_item.gui_panel:text_rect()
				local pad = 32
				row_item.gui_panel:set_h(h + pad)
				row_item.gui_panel:set_w(150)
				row_item.gui_panel:set_rightbottom(self.back_panel:w() - 10 * _G.tweak_data.scale.align_line_padding_multiplier, self.back_panel:h())
				row_item.gui_panel:set_top(self.back_panel:h() - _G.tweak_data.load_level.upper_saferect_border + _G.tweak_data.load_level.border_pad - pad)
			end
		else
			self:_setup_item_size(row_item)
		end
	end
end
function NodeGui:_setup_item_size(row_item)
end
function NodeGui:_flash_background_setup()
	self._background_flash = {}
	self._background_flash.duration = 0
	self._background_flash.timer = 0
end
function NodeGui:_flash_background_start(duration)
	self._background_flash.duration = duration
	self._background_flash.timer = duration
end
function NodeGui:_flash_background_update(dt)
	if self._background_flash.timer > 0 then
		self._background_flash.timer = self._background_flash.timer - dt
		if self.ws then
			local val = math.clamp(1 - self._background_flash.timer / self._background_flash.duration, 0, 1)
			local bg_color = self.background_color
			self.background:set_color(Color(bg_color.a, bg_color.r * val, bg_color.g * val, bg_color.b * val))
		end
	end
end
