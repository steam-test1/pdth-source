SecretAssignmentUnitElement = SecretAssignmentUnitElement or class(MissionElement)
function SecretAssignmentUnitElement:init(unit)
	SecretAssignmentUnitElement.super.init(self, unit)
	self._hed.set_enabled = false
	self._hed.assignment = "none"
	table.insert(self._save_values, "set_enabled")
	table.insert(self._save_values, "assignment")
end
function SecretAssignmentUnitElement:_build_panel(panel, panel_sizer)
	self:_create_panel()
	panel = panel or self._panel
	panel_sizer = panel_sizer or self._panel_sizer
	local assignment_params = {
		name = "Assignment:",
		panel = panel,
		sizer = panel_sizer,
		options = managers.secret_assignment:assignment_names(),
		value = self._hed.assignment,
		default = "none",
		tooltip = "Select an assignment from the combobox",
		name_proportions = 1,
		ctrlr_proportions = 2,
		sorted = true
	}
	local assignment = CoreEWS.combobox(assignment_params)
	assignment:connect("EVT_COMMAND_COMBOBOX_SELECTED", callback(self, self, "set_element_data"), {ctrlr = assignment, value = "assignment"})
	local set_enabled = EWS:CheckBox(panel, "Set enabled", "")
	set_enabled:set_value(self._hed.set_enabled)
	set_enabled:connect("EVT_COMMAND_CHECKBOX_CLICKED", callback(self, self, "set_element_data"), {
		ctrlr = set_enabled,
		value = "set_enabled"
	})
	panel_sizer:add(set_enabled, 0, 0, "EXPAND")
end
