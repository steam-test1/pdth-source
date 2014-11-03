MissionEndUnitElement = MissionEndUnitElement or class(MissionElement)
function MissionEndUnitElement:init(unit)
	MissionEndUnitElement.super.init(self, unit)
	self._hed.state = "none"
	table.insert(self._save_values, "state")
end
function MissionEndUnitElement:_build_panel(panel, panel_sizer)
	self:_create_panel()
	panel = panel or self._panel
	panel_sizer = panel_sizer or self._panel_sizer
	local state_params = {
		name = "State:",
		panel = panel,
		sizer = panel_sizer,
		options = {"success", "failed"},
		default = "none",
		value = self._hed.state,
		tooltip = "Select a state from the combobox",
		name_proportions = 1,
		ctrlr_proportions = 2,
		sorted = true
	}
	local state = CoreEWS.combobox(state_params)
	state:connect("EVT_COMMAND_COMBOBOX_SELECTED", callback(self, self, "set_element_data"), {ctrlr = state, value = "state"})
end
