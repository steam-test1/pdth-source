AIGraphUnitElement = AIGraphUnitElement or class(MissionElement)
function AIGraphUnitElement:init(unit)
	EnemyPreferedRemoveUnitElement.super.init(self, unit)
	self._hed.graph_ids = {}
	self._hed.operation = NavigationManager.nav_states[1]
	table.insert(self._save_values, "graph_ids")
	table.insert(self._save_values, "operation")
end
function AIGraphUnitElement:draw_links(t, dt, selected_unit, all_units)
	EnemyPreferedRemoveUnitElement.super.draw_links(self, t, dt, selected_unit)
end
function AIGraphUnitElement:update_editing()
end
function AIGraphUnitElement:_get_unit(id)
	for _, unit in ipairs(managers.editor:layer("Ai"):created_units()) do
		if unit:unit_data().unit_id == id then
			return unit
		end
	end
	return
end
function AIGraphUnitElement:update_selected(t, dt)
	managers.editor:layer("Ai"):external_draw(t, dt)
	for _, unit in ipairs(managers.editor:layer("Ai"):created_units()) do
		for _, id in ipairs(self._hed.graph_ids) do
			if unit:unit_data().unit_id == id then
				self:_draw_link({
					from_unit = self._unit,
					to_unit = unit,
					r = 0,
					g = 0.75,
					b = 0
				})
			end
		end
	end
end
function AIGraphUnitElement:update_unselected()
	for _, id in ipairs(self._hed.graph_ids) do
		local unit = self:_get_unit(id)
		if not alive(unit) then
			self:_add_or_remove_graph(id)
		end
	end
end
function AIGraphUnitElement:_add_element()
	local ray = managers.editor:unit_by_raycast({mask = 19, ray_type = "editor"})
	if ray and ray.unit and string.find(ray.unit:name():s(), "nav_surface", 1, true) then
		self:_add_or_remove_graph(ray.unit:unit_data().unit_id)
	end
end
function AIGraphUnitElement:_add_or_remove_graph(id)
	if table.contains(self._hed.graph_ids, id) then
		table.delete(self._hed.graph_ids, id)
	else
		table.insert(self._hed.graph_ids, id)
	end
end
function AIGraphUnitElement:add_unit_list_btn()
	local f = function(unit)
		return unit:type() == Idstring("ai")
	end
	local dialog = SelectUnitByNameModal:new("Add Trigger Unit", f)
	for _, unit in ipairs(dialog:selected_units()) do
		self:_add_or_remove_graph(unit:unit_data().unit_id)
	end
end
function AIGraphUnitElement:remove_links(unit)
	for _, id in ipairs(self._hed.graph_ids) do
		if id == unit:unit_data().unit_id then
			table.delete(self._hed.graph_ids, id)
		end
	end
end
function AIGraphUnitElement:add_triggers(vc)
	vc:add_trigger(Idstring("lmb"), callback(self, self, "_add_element"))
end
function AIGraphUnitElement:_build_panel(panel, panel_sizer)
	self:_create_panel()
	panel = panel or self._panel
	panel_sizer = panel_sizer or self._panel_sizer
	self._btn_toolbar = EWS:ToolBar(panel, "", "TB_FLAT,TB_NODIVIDER")
	self._btn_toolbar:add_tool("ADD_UNIT_LIST", "Add unit from unit list", CoreEws.image_path("world_editor\\unit_by_name_list.png"), nil)
	self._btn_toolbar:connect("ADD_UNIT_LIST", "EVT_COMMAND_MENU_SELECTED", callback(self, self, "add_unit_list_btn"), nil)
	self._btn_toolbar:realize()
	panel_sizer:add(self._btn_toolbar, 0, 1, "EXPAND,LEFT")
	local operations_params = {
		name = "Operation:",
		panel = panel,
		sizer = panel_sizer,
		options = NavigationManager.nav_states,
		value = self._hed.operation,
		tooltip = "Select an operation to perform on the selected graphs",
		name_proportions = 1,
		ctrlr_proportions = 2,
		sorted = true
	}
	local operations = CoreEWS.combobox(operations_params)
	operations:connect("EVT_COMMAND_COMBOBOX_SELECTED", callback(self, self, "set_element_data"), {ctrlr = operations, value = "operation"})
	local help = {}
	help.text = "The operation defines what to do with the selected graphs"
	help.panel = panel
	help.sizer = panel_sizer
	self:add_help_text(help)
end
