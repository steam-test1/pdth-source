core:import("CoreMenuNodeGui")
MenuPauseRenderer = MenuPauseRenderer or class(MenuRenderer)
function MenuPauseRenderer:init(logic)
	MenuRenderer.init(self, logic)
end
function MenuPauseRenderer:show_node(node)
	local gui_class = MenuNodeGui
	if node:parameters().gui_class then
		gui_class = CoreSerialize.string_to_classtable(node:parameters().gui_class)
	end
	local parameters = {
		font = tweak_data.menu.default_font,
		background_color = tweak_data.menu.default_menu_background_color:with_alpha(0),
		row_item_color = tweak_data.menu.default_font_row_item_color,
		row_item_hightlight_color = tweak_data.menu.default_hightlight_row_item_color,
		font_size = tweak_data.menu.default_font_size,
		node_gui_class = gui_class,
		spacing = node:parameters().spacing
	}
	MenuPauseRenderer.super.super.show_node(self, node, parameters)
end
function MenuPauseRenderer:open(...)
	MenuPauseRenderer.super.super.open(self, ...)
	self._menu_bg = self._main_panel:bitmap({
		texture = "guis/textures/ingame_menu_bg",
		color = Color.white:with_alpha(0.75),
		blend_mode = "mulx2"
	})
	MenuRenderer.setup_frames_and_logo(self)
	self:_layout_menu_bg()
end
function MenuPauseRenderer:_layout_menu_bg()
	local res = RenderSettings.resolution
	local safe_rect_pixels = managers.viewport:get_safe_rect_pixels()
	self._menu_bg:set_size(res.y * 2, res.y)
	self._menu_bg:set_center(self._menu_bg:parent():center())
	MenuRenderer.layout_frames_and_logo(self)
end
function MenuPauseRenderer:resolution_changed(...)
	MenuPauseRenderer.super.resolution_changed(self, ...)
	self:_layout_menu_bg()
end
function MenuPauseRenderer:close(...)
	MenuPauseRenderer.super.close(self, ...)
end
