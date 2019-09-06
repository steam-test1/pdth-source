core:import("CoreMenuNodeGui")
MenuDialogNodeGui = MenuDialogNodeGui or class(CoreMenuNodeGui.NodeGui)
function MenuDialogNodeGui:init(node, layer, parameters)
	CoreMenuNodeGui.NodeGui.init(self, node, layer, parameters)
	self.font = "fonts/font_fortress_22"
end
function MenuDialogNodeGui:_create_menu_item(row_item)
	if row_item.gui_panel then
		self.item_panel:remove(row_item.gui_panel)
	end
	row_item.gui_panel = self.item_panel:text({
		font_size = self.font_size,
		x = row_item.position.x,
		y = 0,
		align = "center",
		halign = "center",
		vertical = "center",
		font = self.font,
		color = row_item.color,
		layer = self.layers.items,
		text = row_item.text
	})
	local x, y, w, h = row_item.gui_panel:text_rect()
	row_item.gui_panel:set_height(h)
end
