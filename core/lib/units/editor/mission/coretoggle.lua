CoreToggleUnitElement = CoreToggleUnitElement or class(MissionElement)
ToggleUnitElement = ToggleUnitElement or class(CoreToggleUnitElement)
function ToggleUnitElement:init(...)
	CoreToggleUnitElement.init(self, ...)
end
function CoreToggleUnitElement:init(unit)
	MissionElement.init(self, unit)
	self._hed.toggle = "on"
	self._hed.elements = {}
	table.insert(self._save_values, "toggle")
	table.insert(self._save_values, "elements")
end
function CoreToggleUnitElement:draw_links(t, dt, selected_unit, all_units)
	MissionElement.draw_links(self, t, dt, selected_unit)
	for _, id in ipairs(self._hed.elements) do
		local unit = all_units[id]
		local draw = not selected_unit or unit == selected_unit or self._unit == selected_unit
		if draw then
			self:_draw_link({
				from_unit = self._unit,
				to_unit = unit,
				r = 0.75,
				g = 0,
				b = 0
			})
		end
	end
end
function CoreToggleUnitElement:update_editing()
end
function CoreToggleUnitElement:add_element()
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
function CoreToggleUnitElement:remove_links(unit)
	for _, id in ipairs(self._hed.elements) do
		if id == unit:unit_data().unit_id then
			table.delete(self._hed.elements, id)
		end
	end
end
function CoreToggleUnitElement:add_triggers(vc)
	vc:add_trigger(Idstring("lmb"), callback(self, self, "add_element"))
end
function CoreToggleUnitElement:_build_panel(panel, panel_sizer)
	self:_create_panel()
	panel = panel or self._panel
	panel_sizer = panel_sizer or self._panel_sizer
	local toggle_params = {
		name = "Toggle:",
		panel = panel,
		sizer = panel_sizer,
		options = {
			"on",
			"off",
			"toggle"
		},
		value = self._hed.toggle,
		tooltip = "Select how you want to toggle an element",
		name_proportions = 1,
		ctrlr_proportions = 2,
		sorted = true
	}
	local toggle = CoreEWS.combobox(toggle_params)
	toggle:connect("EVT_COMMAND_COMBOBOX_SELECTED", callback(self, self, "set_element_data"), {ctrlr = toggle, value = "toggle"})
end
