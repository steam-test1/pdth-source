KillzoneUnitElement = KillzoneUnitElement or class(MissionElement)
function KillzoneUnitElement:init(unit)
	KillzoneUnitElement.super.init(self, unit)
	self._hed.type = "sniper"
	table.insert(self._save_values, "type")
end
function KillzoneUnitElement:_build_panel(panel, panel_sizer)
	self:_create_panel()
	panel = panel or self._panel
	panel_sizer = panel_sizer or self._panel_sizer
	local type_params = {
		name = "Type:",
		panel = panel,
		sizer = panel_sizer,
		options = {
			"sniper",
			"gas",
			"fire"
		},
		value = self._hed.type,
		tooltip = "Select a type from the combobox",
		name_proportions = 1,
		ctrlr_proportions = 2,
		sorted = true
	}
	local type = CoreEWS.combobox(type_params)
	type:connect("EVT_COMMAND_COMBOBOX_SELECTED", callback(self, self, "set_element_data"), {ctrlr = type, value = "type"})
end
