CoreCounterUnitElement = CoreCounterUnitElement or class(MissionElement)
CounterUnitElement = CounterUnitElement or class(CoreCounterUnitElement)
function CounterUnitElement:init(...)
	CoreCounterUnitElement.init(self, ...)
end
function CoreCounterUnitElement:init(unit)
	MissionElement.init(self, unit)
	self._hed.counter_target = 1
	table.insert(self._save_values, "counter_target")
end
function CoreCounterUnitElement:_build_panel(panel, panel_sizer)
	self:_create_panel()
	panel = panel or self._panel
	panel_sizer = panel_sizer or self._panel_sizer
	local counter_target_params = {
		name = "Counter target:",
		panel = panel,
		sizer = panel_sizer,
		value = self._hed.counter_target,
		floats = 0,
		tooltip = "Specifies how many times the counter should be executed before running its on executed",
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
