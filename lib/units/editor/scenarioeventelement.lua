ScenarioEventUnitElement = ScenarioEventUnitElement or class(MissionElement)
function ScenarioEventUnitElement:init(unit)
	ScenarioEventUnitElement.super.init(self, unit)
	self._hed.amount = 1
	self._hed.task = managers.groupai:state():task_names()[1]
	self._hed.base_chance = 1
	self._hed.chance_inc = 0
	table.insert(self._save_values, "amount")
	table.insert(self._save_values, "task")
	table.insert(self._save_values, "base_chance")
	table.insert(self._save_values, "chance_inc")
end
function ScenarioEventUnitElement:_build_panel(panel, panel_sizer)
	self:_create_panel()
	panel = panel or self._panel
	panel_sizer = panel_sizer or self._panel_sizer
	local amount_params = {
		name = "Amount:",
		panel = panel,
		sizer = panel_sizer,
		value = self._hed.amount,
		floats = 0,
		tooltip = "Should be set to the amount of enemies that will be created from this event",
		min = 1,
		max = 25,
		name_proportions = 1,
		ctrlr_proportions = 2
	}
	local amount = CoreEWS.number_controller(amount_params)
	amount:connect("EVT_COMMAND_TEXT_ENTER", callback(self, self, "set_element_data"), {ctrlr = amount, value = "amount"})
	amount:connect("EVT_KILL_FOCUS", callback(self, self, "set_element_data"), {ctrlr = amount, value = "amount"})
	local task_params = {
		name = "Task:",
		panel = panel,
		sizer = panel_sizer,
		options = managers.groupai:state():task_names(),
		value = self._hed.task,
		tooltip = "Select a task from the combobox",
		name_proportions = 1,
		ctrlr_proportions = 2,
		sorted = true
	}
	local task = CoreEWS.combobox(task_params)
	task:connect("EVT_COMMAND_COMBOBOX_SELECTED", callback(self, self, "set_element_data"), {ctrlr = task, value = "task"})
	local base_chance_params = {
		name = "Base chance:",
		panel = panel,
		sizer = panel_sizer,
		value = self._hed.base_chance,
		floats = 2,
		tooltip = "Used to specify chance to happen (1==absolutely!)",
		min = 0,
		max = 1,
		name_proportions = 1,
		ctrlr_proportions = 2
	}
	local base_chance = CoreEWS.number_controller(base_chance_params)
	base_chance:connect("EVT_COMMAND_TEXT_ENTER", callback(self, self, "set_element_data"), {
		ctrlr = base_chance,
		value = "base_chance"
	})
	base_chance:connect("EVT_KILL_FOCUS", callback(self, self, "set_element_data"), {
		ctrlr = base_chance,
		value = "base_chance"
	})
	local chance_inc_params = {
		name = "Chance incremental:",
		panel = panel,
		sizer = panel_sizer,
		value = self._hed.chance_inc,
		floats = 2,
		tooltip = "Used to specify an incremental chance to happen",
		min = 0,
		max = 1,
		name_proportions = 1,
		ctrlr_proportions = 2
	}
	local chance_inc = CoreEWS.number_controller(chance_inc_params)
	chance_inc:connect("EVT_COMMAND_TEXT_ENTER", callback(self, self, "set_element_data"), {ctrlr = chance_inc, value = "chance_inc"})
	chance_inc:connect("EVT_KILL_FOCUS", callback(self, self, "set_element_data"), {ctrlr = chance_inc, value = "chance_inc"})
end
