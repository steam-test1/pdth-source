require("lib/managers/menu/MenuDialogNodeGui")
MenuDialogRenderer = MenuDialogRenderer or class(MenuRenderer)
function MenuDialogRenderer:init(logic)
	MenuRenderer.init(self, logic)
end
function MenuDialogRenderer:show_node(node)
	local layer = self._base_layer
	local previous_node_gui = self:active_node_gui()
	if previous_node_gui then
		layer = previous_node_gui:layer()
		previous_node_gui:set_visible(false)
	end
	local new_node_gui = MenuDialogNodeGui:new(node, layer + 1, {
		font = "fonts/font_fortress_22",
		font_size = 26,
		background_color = Color(0, 0, 0, 0),
		row_item_color = Color(1, 0.39215687, 0.39215687, 0.39215687)
	})
	table.insert(self._node_gui_stack, new_node_gui)
	self:_flash_background(0.2)
	self:disable_input(0.2)
end
function MenuDialogRenderer:update(t, dt)
	MenuRenderer.update(self, t, dt)
end
