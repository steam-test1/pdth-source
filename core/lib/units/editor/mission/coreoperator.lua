CoreOperatorUnitElement = CoreOperatorUnitElement or class(MissionElement)
OperatorUnitElement = OperatorUnitElement or class(CoreOperatorUnitElement)
function OperatorUnitElement:init(...)
	OperatorUnitElement.super.init(self, ...)
end
function CoreOperatorUnitElement:init(unit)
	CoreOperatorUnitElement.super.init(self, unit)
	self._hed.operation = "none"
	self._hed.elements = {}
	table.insert(self._save_values, "operation")
	table.insert(self._save_values, "elements")
end
function CoreOperatorUnitElement:draw_links(t, dt, selected_unit, all_units)
	CoreOperatorUnitElement.super.draw_links(self, t, dt, selected_unit)
	for _, id in ipairs(self._hed.elements) do
		local unit = all_units[id]
		local draw = not selected_unit or unit == selected_unit or self._unit == selected_unit
		if draw then
			self:_draw_link({
				from_unit = self._unit,
				to_unit = unit,
				r = 0.75,
				g = 0.75,
				b = 0.25
			})
		end
	end
end
function CoreOperatorUnitElement:update_editing()
end
function CoreOperatorUnitElement:add_element()
	local ray = managers.editor:unit_by_raycast({mask = 10, ray_type = "editor"})
	if ray and ray.unit then
		local id = ray.unit:unit_data().unit_id
		if table.contains(self._hed.elements, id) then
			table.delete(self._hed.elements, id)
		else
			table.insert(self._hed.elements, id)
		end
	end
end
function CoreOperatorUnitElement:remove_links(unit)
	for _, id in ipairs(self._hed.elements) do
		if id == unit:unit_data().unit_id then
			table.delete(self._hed.elements, id)
		end
	end
end
function CoreOperatorUnitElement:add_triggers(vc)
	vc:add_trigger(Idstring("lmb"), callback(self, self, "add_element"))
end
function CoreOperatorUnitElement:_build_panel(panel, panel_sizer)
	self:_create_panel()
	panel = panel or self._panel
	panel_sizer = panel_sizer or self._panel_sizer
	local operation_params = {
		name = "Operation:",
		panel = panel,
		sizer = panel_sizer,
		default = "none",
		options = {"add", "remove"},
		value = self._hed.operation,
		tooltip = "Select an operation for the selected elements",
		name_proportions = 1,
		ctrlr_proportions = 2,
		sorted = true
	}
	local operation = CoreEWS.combobox(operation_params)
	operation:connect("EVT_COMMAND_COMBOBOX_SELECTED", callback(self, self, "set_element_data"), {ctrlr = operation, value = "operation"})
	local help = {}
	help.text = "Choose an operation to perform on the selected elements. An element might not have the selected operation implemented and will then generate error when executed."
	help.panel = panel
	help.sizer = panel_sizer
	self:add_help_text(help)
end
