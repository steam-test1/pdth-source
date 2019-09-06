core:import("CoreMenuNodeGui")
MenuGameoverRenderer = MenuGameoverRenderer or class(MenuRenderer)
MenuGameoverRenderer.GUI_FULLSCREEN = Idstring("guis/gameoverscreen/gameoverscreen_fullscreen")
MenuGameoverRenderer.GUI_SAFERECT = Idstring("guis/gameoverscreen/gameoverscreen_saferect")
function MenuGameoverRenderer:init(logic)
	MenuRenderer.init(self, logic)
end
function MenuGameoverRenderer:show_node(node)
	local layer = self._base_layer
	local previous_node_gui = self:active_node_gui()
	if previous_node_gui then
		layer = previous_node_gui:layer()
		previous_node_gui:set_visible(false)
	end
	local new_node_gui = CoreMenuNodeGui.NodeGui:new(node, layer + 1, {
		background_color = Color(0, 0, 0, 0),
		row_item_color = Color(0.5, 1, 1, 1)
	})
	table.insert(self._node_gui_stack, new_node_gui)
	self:_flash_background(0.2)
	self:disable_input(0.2)
end
function MenuGameoverRenderer:open(...)
	MenuRenderer.open(self, ...)
	if not managers.hud:exists(self.GUI_SAFERECT) then
		managers.hud:load_hud(self.GUI_SAFERECT, false, true, true, {})
	end
	if not managers.hud:exists(self.GUI_FULLSCREEN) then
		managers.hud:load_hud(self.GUI_FULLSCREEN, false, true, false, {})
	end
	managers.hud:show(self.GUI_SAFERECT)
	managers.hud:show(self.GUI_FULLSCREEN)
end
function MenuGameoverRenderer:close()
	MenuRenderer.close(self)
	managers.hud:hide(self.GUI_SAFERECT)
	managers.hud:hide(self.GUI_FULLSCREEN)
end
function MenuGameoverRenderer:update(t, dt)
	MenuRenderer.update(self, t, dt)
	managers.hud:script(self.GUI_SAFERECT):update(t, dt)
	managers.hud:script(self.GUI_FULLSCREEN):update(t, dt)
end
