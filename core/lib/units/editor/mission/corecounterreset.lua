CoreCounterResetUnitElement = CoreCounterResetUnitElement or class(MissionElement)
CounterResetUnitElement = CounterResetUnitElement or class(CoreCounterResetUnitElement)
function CounterResetUnitElement:init(...)
	CoreCounterResetUnitElement.init(self, ...)
end
function CoreCounterResetUnitElement:init(unit)
	MissionElement.init(self, unit)
	self._hed.counter_target = 1
	self._hed.elements = {}
	self._elements_units = {}
	table.insert(self._save_values, "counter_target")
	table.insert(self._save_values, "elements")
end
function CoreCounterResetUnitElement:layer_finished(...)
	MissionElement.layer_finished(self, ...)
	for _, id in ipairs(self._hed.elements) do
		local unit = managers.worlddefinition:get_mission_element_unit(id)
		table.insert(self._elements_units, unit)
	end
end
function CoreCounterResetUnitElement:draw_links(t, dt, selected_unit)
	MissionElement.draw_links(self, t, dt, selected_unit)
	for _, unit in ipairs(self._elements_units) do
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
function CoreCounterResetUnitElement:update_editing()
end
function CoreCounterResetUnitElement:add_element()
	local ray = managers.editor:unit_by_raycast({mask = 10, ray_type = "editor"})
	if ray and ray.unit and string.find(ray.unit:name():s(), "logic_counter", 1, true) then
		local id = ray.unit:unit_data().unit_id
		if table.contains(self._hed.elements, id) then
			table.delete(self._hed.elements, id)
			table.delete(self._elements_units, ray.unit)
		else
			table.insert(self._hed.elements, id)
			table.insert(self._elements_units, ray.unit)
		end
	end
end
function CoreCounterResetUnitElement:remove_links(unit)
	MissionElement.remove_links(self, unit)
	for _, id in ipairs(self._hed.elements) do
		if id == unit:unit_data().unit_id then
			table.delete(self._hed.elements, id)
			table.delete(self._elements_units, unit)
		end
	end
end
function CoreCounterResetUnitElement:add_triggers(vc)
	vc:add_trigger(Idstring("lmb"), callback(self, self, "add_element"))
end
function CoreCounterResetUnitElement:_build_panel(panel, panel_sizer)
	self:_create_panel()
	panel = panel or self._panel
	panel_sizer = panel_sizer or self._panel_sizer
	local counter_target_params = {
		name = "Counter target:",
		panel = panel,
		sizer = panel_sizer,
		value = self._hed.counter_target,
		floats = 0,
		tooltip = "Specifies what the selected counted should reset to",
		min = 0,
		name_proportions = 1,
		ctrlr_proportions = 2,
		sorted = false
	}
	local counter_target = CoreEWS.number_controller(counter_target_params)
	counter_target:connect("EVT_COMMAND_TEXT_ENTER", callback(self, self, "set_element_data"), {
		ctrlr = counter_target,
		value = "counter_target"
	})
	counter_target:connect("EVT_KILL_FOCUS", callback(self, self, "set_element_data"), {
		ctrlr = counter_target,
		value = "counter_target"
	})
end
