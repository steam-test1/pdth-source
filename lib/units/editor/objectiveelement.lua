ObjectiveUnitElement = ObjectiveUnitElement or class(MissionElement)
function ObjectiveUnitElement:init(unit)
	ObjectiveUnitElement.super.init(self, unit)
	self._hed.state = "activate"
	self._hed.objective = "none"
	self._hed.sub_objective = "none"
	table.insert(self._save_values, "state")
	table.insert(self._save_values, "objective")
	table.insert(self._save_values, "sub_objective")
end
function ObjectiveUnitElement:update_sub_objectives()
	local sub_objectives = managers.objectives:sub_objectives_by_name(self._hed.objective)
	self._hed.sub_objective = "none"
	CoreEws.update_combobox_options(self._sub_objective_params, sub_objectives)
	CoreEws.change_combobox_value(self._sub_objective_params, self._hed.sub_objective)
end
function ObjectiveUnitElement:_build_panel(panel, panel_sizer)
	self:_create_panel()
	panel = panel or self._panel
	panel_sizer = panel_sizer or self._panel_sizer
	local state_params = {
		name = "State:",
		panel = panel,
		sizer = panel_sizer,
		options = {
			"activate",
			"complete",
			"update",
			"remove"
		},
		value = self._hed.state,
		tooltip = "Select a state from the combobox",
		name_proportions = 1,
		ctrlr_proportions = 2,
		sorted = true
	}
	local state = CoreEWS.combobox(state_params)
	state:connect("EVT_COMMAND_COMBOBOX_SELECTED", callback(self, self, "set_element_data"), {ctrlr = state, value = "state"})
	local objective_params = {
		name = "Objective:",
		panel = panel,
		sizer = panel_sizer,
		options = managers.objectives:objectives_by_name(),
		value = self._hed.objective,
		default = "none",
		tooltip = "Select an objective from the combobox",
		name_proportions = 1,
		ctrlr_proportions = 2,
		sorted = true
	}
	local objective = CoreEWS.combobox(objective_params)
	objective:connect("EVT_COMMAND_COMBOBOX_SELECTED", callback(self, self, "set_element_data"), {ctrlr = objective, value = "objective"})
	objective:connect("EVT_COMMAND_COMBOBOX_SELECTED", callback(self, self, "update_sub_objectives"), nil)
	self._sub_objective_params = {
		name = "Sub objective:",
		panel = panel,
		sizer = panel_sizer,
		options = self._hed.objective ~= "none" and managers.objectives:sub_objectives_by_name(self._hed.objective) or {},
		value = self._hed.sub_objective,
		default = "none",
		tooltip = "Select a sub objective from the combobox (if availible)",
		name_proportions = 1,
		ctrlr_proportions = 2,
		sorted = true
	}
	local sub_objective = CoreEWS.combobox(self._sub_objective_params)
	sub_objective:connect("EVT_COMMAND_COMBOBOX_SELECTED", callback(self, self, "set_element_data"), {
		ctrlr = sub_objective,
		value = "sub_objective"
	})
end
