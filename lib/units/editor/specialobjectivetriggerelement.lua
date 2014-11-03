SpecialObjectiveTriggerUnitElement = SpecialObjectiveTriggerUnitElement or class(MissionElement)
function SpecialObjectiveTriggerUnitElement:init(unit)
	MissionElement.init(self, unit)
	self._options = {
		"anim_act_01",
		"anim_act_02",
		"anim_act_03",
		"anim_act_04",
		"anim_act_05",
		"anim_act_06",
		"anim_act_07",
		"anim_act_08",
		"anim_act_09",
		"anim_act_10",
		"administered",
		"anim_start",
		"complete",
		"fail"
	}
	self._hed.event = self._options[1]
	self._hed.elements = {}
	table.insert(self._save_values, "event")
	table.insert(self._save_values, "elements")
end
function SpecialObjectiveTriggerUnitElement:draw_links(t, dt, selected_unit, all_units)
	MissionElement.draw_links(self, t, dt, selected_unit)
	for _, id in ipairs(self._hed.elements) do
		local unit = all_units[id]
		local draw = not selected_unit or unit == selected_unit or self._unit == selected_unit
		if draw then
			self:_draw_link({
				from_unit = unit,
				to_unit = self._unit,
				r = 0,
				g = 0.75,
				b = 0
			})
		end
	end
end
function SpecialObjectiveTriggerUnitElement:update_editing()
end
function SpecialObjectiveTriggerUnitElement:add_element()
	local ray = managers.editor:unit_by_raycast({mask = 10, ray_type = "editor"})
	if ray and ray.unit and self:_correct_unit(ray.unit:name():s()) then
		local id = ray.unit:unit_data().unit_id
		if table.contains(self._hed.elements, id) then
			table.delete(self._hed.elements, id)
		else
			table.insert(self._hed.elements, id)
		end
	end
end
function SpecialObjectiveTriggerUnitElement:_correct_unit(u_name)
	local names = {
		"point_special_objective"
	}
	for _, name in ipairs(names) do
		if string.find(u_name, name, 1, true) then
			return true
		end
	end
	return false
end
function SpecialObjectiveTriggerUnitElement:remove_links(unit)
	for _, id in ipairs(self._hed.elements) do
		if id == unit:unit_data().unit_id then
			table.delete(self._hed.elements, id)
		end
	end
end
function SpecialObjectiveTriggerUnitElement:add_triggers(vc)
	vc:add_trigger(Idstring("lmb"), callback(self, self, "add_element"))
end
function SpecialObjectiveTriggerUnitElement:_build_panel(panel, panel_sizer)
	self:_create_panel()
	panel = panel or self._panel
	panel_sizer = panel_sizer or self._panel_sizer
	local event_params = {
		name = "Event:",
		panel = panel,
		sizer = panel_sizer,
		options = self._options,
		value = self._hed.event,
		tooltip = "Select an event from the combobox",
		name_proportions = 1,
		ctrlr_proportions = 2,
		sorted = false
	}
	local events = CoreEWS.combobox(event_params)
	events:connect("EVT_COMMAND_COMBOBOX_SELECTED", callback(self, self, "set_element_data"), {ctrlr = events, value = "event"})
end
