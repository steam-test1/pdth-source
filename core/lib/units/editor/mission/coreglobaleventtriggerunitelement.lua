CoreGlobalEventTriggerUnitElement = CoreGlobalEventTriggerUnitElement or class(MissionElement)
GlobalEventTriggerUnitElement = GlobalEventTriggerUnitElement or class(CoreGlobalEventTriggerUnitElement)
function GlobalEventTriggerUnitElement:init(...)
	GlobalEventTriggerUnitElement.super.init(self, ...)
end
function CoreGlobalEventTriggerUnitElement:init(unit)
	MissionElement.init(self, unit)
	self._hed.trigger_times = 1
	self._hed.global_event = "none"
	table.insert(self._save_values, "global_event")
end
function CoreGlobalEventTriggerUnitElement:_build_panel(panel, panel_sizer)
	self:_create_panel()
	panel = panel or self._panel
	panel_sizer = panel_sizer or self._panel_sizer
	local events_params = {
		name = "Global Event:",
		panel = panel,
		sizer = panel_sizer,
		options = managers.mission:get_global_event_list(),
		value = self._hed.global_event,
		default = "none",
		tooltip = "Select a global event from the combobox",
		name_proportions = 1,
		ctrlr_proportions = 2,
		sorted = true
	}
	local events = CoreEWS.combobox(events_params)
	events:connect("EVT_COMMAND_COMBOBOX_SELECTED", callback(self, self, "set_element_data"), {
		ctrlr = events,
		value = "global_event"
	})
end
