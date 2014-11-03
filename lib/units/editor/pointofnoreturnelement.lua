PointOfNoReturnElement = PointOfNoReturnElement or class(MissionElement)
function PointOfNoReturnElement:init(unit)
	PointOfNoReturnElement.super.init(self, unit)
	self._hed.elements = {}
	self._hed.time_easy = 300
	self._hed.time_normal = 240
	self._hed.time_hard = 120
	self._hed.time_overkill = 60
	self._hed.time_overkill_145 = 30
	table.insert(self._save_values, "elements")
	table.insert(self._save_values, "time_easy")
	table.insert(self._save_values, "time_normal")
	table.insert(self._save_values, "time_hard")
	table.insert(self._save_values, "time_overkill")
	table.insert(self._save_values, "time_overkill_145")
end
function PointOfNoReturnElement:_build_panel(panel, panel_sizer)
	self:_create_panel()
	panel = panel or self._panel
	panel_sizer = panel_sizer or self._panel_sizer
	local time_params_easy = {
		name = "Time left on easy:",
		panel = panel,
		sizer = panel_sizer,
		value = self._hed.time_easy,
		floats = 0,
		tooltip = "Set the time left",
		min = 1,
		name_proportions = 1,
		ctrlr_proportions = 2
	}
	local time_easy = CoreEWS.number_controller(time_params_easy)
	time_easy:connect("EVT_COMMAND_TEXT_ENTER", callback(self, self, "set_element_data"), {ctrlr = time_easy, value = "time_easy"})
	time_easy:connect("EVT_KILL_FOCUS", callback(self, self, "set_element_data"), {ctrlr = time_easy, value = "time_easy"})
	local time_params_normal = {
		name = "Time left on normal:",
		panel = panel,
		sizer = panel_sizer,
		value = self._hed.time_normal,
		floats = 0,
		tooltip = "Set the time left",
		min = 1,
		name_proportions = 1,
		ctrlr_proportions = 2
	}
	local time_normal = CoreEWS.number_controller(time_params_normal)
	time_normal:connect("EVT_COMMAND_TEXT_ENTER", callback(self, self, "set_element_data"), {
		ctrlr = time_normal,
		value = "time_normal"
	})
	time_normal:connect("EVT_KILL_FOCUS", callback(self, self, "set_element_data"), {
		ctrlr = time_normal,
		value = "time_normal"
	})
	local time_params_hard = {
		name = "Time left on hard:",
		panel = panel,
		sizer = panel_sizer,
		value = self._hed.time_hard,
		floats = 0,
		tooltip = "Set the time left",
		min = 1,
		name_proportions = 1,
		ctrlr_proportions = 2
	}
	local time_hard = CoreEWS.number_controller(time_params_hard)
	time_hard:connect("EVT_COMMAND_TEXT_ENTER", callback(self, self, "set_element_data"), {ctrlr = time_hard, value = "time_hard"})
	time_hard:connect("EVT_KILL_FOCUS", callback(self, self, "set_element_data"), {ctrlr = time_hard, value = "time_hard"})
	local time_params_overkill = {
		name = "Time left on overkill:",
		panel = panel,
		sizer = panel_sizer,
		value = self._hed.time_overkill,
		floats = 0,
		tooltip = "Set the time left",
		min = 1,
		name_proportions = 1,
		ctrlr_proportions = 2
	}
	local time_overkill = CoreEWS.number_controller(time_params_overkill)
	time_overkill:connect("EVT_COMMAND_TEXT_ENTER", callback(self, self, "set_element_data"), {
		ctrlr = time_overkill,
		value = "time_overkill"
	})
	time_overkill:connect("EVT_KILL_FOCUS", callback(self, self, "set_element_data"), {
		ctrlr = time_overkill,
		value = "time_overkill"
	})
	local time_params_overkill_145 = {
		name = "Time left on overkill 145:",
		panel = panel,
		sizer = panel_sizer,
		value = self._hed.time_overkill_145,
		floats = 0,
		tooltip = "Set the time left",
		min = 1,
		name_proportions = 1,
		ctrlr_proportions = 2
	}
	local time_overkill_145 = CoreEWS.number_controller(time_params_overkill_145)
	time_overkill_145:connect("EVT_COMMAND_TEXT_ENTER", callback(self, self, "set_element_data"), {
		ctrlr = time_overkill_145,
		value = "time_overkill_145"
	})
	time_overkill_145:connect("EVT_KILL_FOCUS", callback(self, self, "set_element_data"), {
		ctrlr = time_overkill_145,
		value = "time_overkill_145"
	})
end
function PointOfNoReturnElement:draw_links(t, dt, selected_unit, all_units)
	MissionElement.draw_links(self, t, dt, selected_unit, all_units)
end
function PointOfNoReturnElement:update_editing()
end
function PointOfNoReturnElement:update_selected(t, dt, selected_unit, all_units)
	for _, id in ipairs(self._hed.elements) do
		local unit = all_units[id]
		local draw = not selected_unit or unit == selected_unit or self._unit == selected_unit
		if draw then
			self:_draw_link({
				from_unit = self._unit,
				to_unit = unit,
				r = 0.75,
				g = 0,
				b = 0.75
			})
		end
	end
end
function PointOfNoReturnElement:add_element()
	local ray = managers.editor:unit_by_raycast({mask = 10, ray_type = "editor"})
	if ray and ray.unit and string.find(ray.unit:name():s(), "trigger_area", 1, true) then
		local id = ray.unit:unit_data().unit_id
		if table.contains(self._hed.elements, id) then
			table.delete(self._hed.elements, id)
		else
			table.insert(self._hed.elements, id)
		end
	end
end
function PointOfNoReturnElement:remove_links(unit)
	for _, id in ipairs(self._hed.elements) do
		if id == unit:unit_data().unit_id then
			table.delete(self._hed.elements, id)
		end
	end
end
function PointOfNoReturnElement:add_triggers(vc)
	vc:add_trigger(Idstring("lmb"), callback(self, self, "add_element"))
end
