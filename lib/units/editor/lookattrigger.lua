LookAtTriggerUnitElement = LookAtTriggerUnitElement or class(MissionElement)
function LookAtTriggerUnitElement:init(unit)
	LookAtTriggerUnitElement.super.init(self, unit)
	self._hed.trigger_times = 1
	self._hed.interval = 0.1
	self._hed.sensitivity = 0.9
	self._hed.distance = 0
	self._hed.in_front = false
	table.insert(self._save_values, "interval")
	table.insert(self._save_values, "sensitivity")
	table.insert(self._save_values, "distance")
	table.insert(self._save_values, "in_front")
end
function LookAtTriggerUnitElement:update_selected(t, dt)
	if self._hed.distance ~= 0 then
		local brush = Draw:brush()
		brush:set_color(Color(0.15, 1, 1, 1))
		local pen = Draw:pen(Color(0.15, 0.5, 0.5, 0.5))
		if not self._hed.in_front then
			brush:sphere(self._unit:position(), self._hed.distance, 4)
			pen:sphere(self._unit:position(), self._hed.distance)
		else
			brush:half_sphere(self._unit:position(), self._hed.distance, -self._unit:rotation():y(), 4)
			pen:half_sphere(self._unit:position(), self._hed.distance, -self._unit:rotation():y())
		end
	end
end
function LookAtTriggerUnitElement:_build_panel(panel, panel_sizer)
	self:_create_panel()
	panel = panel or self._panel
	panel_sizer = panel_sizer or self._panel_sizer
	local interval_params = {
		name = "Check interval:",
		value = self._hed.interval,
		panel = panel,
		sizer = panel_sizer,
		tooltip = "Set the check interval for the look at, in seconds",
		floats = 2,
		min = 0.01,
		name_proportions = 1,
		ctrlr_proportions = 2
	}
	local interval = CoreEWS.number_controller(interval_params)
	interval:connect("EVT_COMMAND_TEXT_ENTER", callback(self, self, "set_element_data"), {ctrlr = interval, value = "interval"})
	interval:connect("EVT_KILL_FOCUS", callback(self, self, "set_element_data"), {ctrlr = interval, value = "interval"})
	local sensitivity_params = {
		name = "Sensitivity:",
		panel = panel,
		sizer = panel_sizer,
		value = self._hed.sensitivity,
		floats = 3,
		min = 0.5,
		max = 0.999,
		name_proportions = 1,
		ctrlr_proportions = 2,
		slider_ctrlr_proportions = 3,
		number_ctrlr_proportions = 1
	}
	CoreEws.slider_and_number_controller(sensitivity_params)
	sensitivity_params.slider_ctrlr:connect("EVT_SCROLL_THUMBTRACK", callback(self, self, "set_element_data"), {
		ctrlr = sensitivity_params.number_ctrlr,
		value = "sensitivity"
	})
	sensitivity_params.slider_ctrlr:connect("EVT_SCROLL_CHANGED", callback(self, self, "set_element_data"), {
		ctrlr = sensitivity_params.number_ctrlr,
		value = "sensitivity"
	})
	sensitivity_params.number_ctrlr:connect("EVT_COMMAND_TEXT_ENTER", callback(self, self, "set_element_data"), {
		ctrlr = sensitivity_params.number_ctrlr,
		value = "sensitivity"
	})
	sensitivity_params.number_ctrlr:connect("EVT_KILL_FOCUS", callback(self, self, "set_element_data"), {
		ctrlr = sensitivity_params.number_ctrlr,
		value = "sensitivity"
	})
	local distance_params = {
		name = "Distance:",
		value = self._hed.distance,
		panel = panel,
		sizer = panel_sizer,
		tooltip = "(Optional) Sets a distance to use with the check (in meters)",
		floats = 2,
		min = 0,
		name_proportions = 1,
		ctrlr_proportions = 2
	}
	local distance = CoreEWS.number_controller(distance_params)
	distance:connect("EVT_COMMAND_TEXT_ENTER", callback(self, self, "set_element_data"), {ctrlr = distance, value = "distance"})
	distance:connect("EVT_KILL_FOCUS", callback(self, self, "set_element_data"), {ctrlr = distance, value = "distance"})
	local in_front = EWS:CheckBox(panel, "Only in front", "")
	in_front:set_value(self._hed.in_front)
	in_front:connect("EVT_COMMAND_CHECKBOX_CLICKED", callback(self, self, "set_element_data"), {ctrlr = in_front, value = "in_front"})
	panel_sizer:add(in_front, 0, 0, "EXPAND")
	local help = {}
	help.text = [[
Interval defines how offen the check should be done. Sensitivity defines how precise the look angle must be. A sensitivity of 0.999 means that you need to look almost directly at it, 0.5 means that you will get the trigger somewhere at the edge of the screen (might be outside or inside). 

Distance(in meters) can be used as a filter to the trigger (0 means no distance filtering)]]
	help.panel = panel
	help.sizer = panel_sizer
	self:add_help_text(help)
end
