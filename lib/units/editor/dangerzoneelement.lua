DangerZoneUnitElement = DangerZoneUnitElement or class(MissionElement)
function DangerZoneUnitElement:init(unit)
	DangerZoneUnitElement.super.init(self, unit)
	self._hed.level = 1
	table.insert(self._save_values, "level")
end
function DangerZoneUnitElement:_build_panel(panel, panel_sizer)
	self:_create_panel()
	panel = panel or self._panel
	panel_sizer = panel_sizer or self._panel_sizer
	local level_params = {
		name = "Level:",
		panel = panel,
		sizer = panel_sizer,
		value = self._hed.level,
		floats = 0,
		tooltip = "Sets the level of danger. 1 is least dangerous.",
		min = 1,
		max = 4,
		name_proportions = 1,
		ctrlr_proportions = 2
	}
	local level = CoreEWS.number_controller(level_params)
	level:connect("EVT_COMMAND_TEXT_ENTER", callback(self, self, "set_element_data"), {ctrlr = level, value = "level"})
	level:connect("EVT_KILL_FOCUS", callback(self, self, "set_element_data"), {ctrlr = level, value = "level"})
end
