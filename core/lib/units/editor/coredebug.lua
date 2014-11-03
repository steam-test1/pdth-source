CoreDebugUnitElement = CoreDebugUnitElement or class(MissionElement)
DebugUnitElement = DebugUnitElement or class(CoreDebugUnitElement)
function DebugUnitElement:init(...)
	CoreDebugUnitElement.init(self, ...)
end
function CoreDebugUnitElement:init(unit)
	MissionElement.init(self, unit)
	self._hed.debug_string = "none"
	table.insert(self._save_values, "debug_string")
end
function CoreDebugUnitElement:_build_panel(panel, panel_sizer)
	self:_create_panel()
	panel = panel or self._panel
	panel_sizer = panel_sizer or self._panel_sizer
	local debug = EWS:TextCtrl(panel, self._hed.debug_string, "", "TE_PROCESS_ENTER")
	panel_sizer:add(debug, 0, 0, "EXPAND")
	debug:connect("EVT_COMMAND_TEXT_ENTER", callback(self, self, "set_element_data"), {
		ctrlr = debug,
		value = "debug_string"
	})
	debug:connect("EVT_KILL_FOCUS", callback(self, self, "set_element_data"), {
		ctrlr = debug,
		value = "debug_string"
	})
end
