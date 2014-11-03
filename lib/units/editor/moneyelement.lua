MoneyUnitElement = MoneyUnitElement or class(MissionElement)
function MoneyUnitElement:init(unit)
	MoneyUnitElement.super.init(self, unit)
	self._hed.action = "none"
	table.insert(self._save_values, "action")
end
function MoneyUnitElement:_build_panel(panel, panel_sizer)
	self:_create_panel()
	panel = panel or self._panel
	panel_sizer = panel_sizer or self._panel_sizer
	local acion_params = {
		name = "Action:",
		panel = panel,
		sizer = panel_sizer,
		options = managers.experience:actions(),
		value = self._hed.action,
		default = "none",
		tooltip = "Select an action from the combobox",
		name_proportions = 1,
		ctrlr_proportions = 2,
		sorted = true
	}
	local action = CoreEWS.combobox(acion_params)
	action:connect("EVT_COMMAND_COMBOBOX_SELECTED", callback(self, self, "set_element_data"), {ctrlr = action, value = "action"})
end
