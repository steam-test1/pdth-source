PressureUnitElement = PressureUnitElement or class(MissionElement)
function PressureUnitElement:init(unit)
	PressureUnitElement.super.init(self, unit)
	self._hed.points = 0
	self._hed.interval = 0
	table.insert(self._save_values, "points")
	table.insert(self._save_values, "interval")
end
function PressureUnitElement:_build_panel(panel, panel_sizer)
	self:_create_panel()
	panel = panel or self._panel
	panel_sizer = panel_sizer or self._panel_sizer
	local interval_params = {
		name = "Interval:",
		panel = panel,
		sizer = panel_sizer,
		value = self._hed.interval,
		floats = 0,
		tooltip = "Use this to set the interval in seconds when to add new pressure point (0 means it is disabled)",
		min = 0,
		max = 600,
		name_proportions = 1,
		ctrlr_proportions = 2
	}
	local interval = CoreEWS.number_controller(interval_params)
	interval:connect("EVT_COMMAND_TEXT_ENTER", callback(self, self, "set_element_data"), {ctrlr = interval, value = "interval"})
	interval:connect("EVT_KILL_FOCUS", callback(self, self, "set_element_data"), {ctrlr = interval, value = "interval"})
	local pressure_points_params = {
		name = "Pressure points:",
		panel = panel,
		sizer = panel_sizer,
		value = self._hed.points,
		floats = 0,
		tooltip = "Can add pressure points or cool down points",
		min = -10,
		max = 10,
		name_proportions = 1,
		ctrlr_proportions = 2
	}
	local pressure_points = CoreEWS.number_controller(pressure_points_params)
	pressure_points:connect("EVT_COMMAND_TEXT_ENTER", callback(self, self, "set_element_data"), {ctrlr = pressure_points, value = "points"})
	pressure_points:connect("EVT_KILL_FOCUS", callback(self, self, "set_element_data"), {ctrlr = pressure_points, value = "points"})
	local help = {}
	help.text = "If pressure points ~= 0 the interval value wont be used. Add negative pressure points value will generate cool down points. If interval is 0 it will be disabled."
	help.panel = panel
	help.sizer = panel_sizer
	self:add_help_text(help)
end
