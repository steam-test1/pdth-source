AiGlobalEventUnitElement = AiGlobalEventUnitElement or class(MissionElement)
function AiGlobalEventUnitElement:init(unit)
	AiGlobalEventUnitElement.super.init(self, unit)
	self._options = {
		"none",
		"assault",
		"besiege",
		"blockade",
		"hunt",
		"quiet",
		"passive"
	}
	self._hed.event = "none"
	table.insert(self._save_values, "event")
end
function AiGlobalEventUnitElement:_build_panel(panel, panel_sizer)
	self:_create_panel()
	panel = panel or self._panel
	panel_sizer = panel_sizer or self._panel_sizer
	local event_params = {
		name = "Event:",
		panel = panel,
		sizer = panel_sizer,
		options = self._options,
		value = self._hed.event,
		default = "none",
		tooltip = "Select an event from the combobox",
		name_proportions = 1,
		ctrlr_proportions = 2,
		sorted = true
	}
	local event = CoreEWS.combobox(event_params)
	event:connect("EVT_COMMAND_COMBOBOX_SELECTED", callback(self, self, "set_element_data"), {ctrlr = event, value = "event"})
end
