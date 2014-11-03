AreaMinPoliceForceUnitElement = AreaMinPoliceForceUnitElement or class(MissionElement)
function AreaMinPoliceForceUnitElement:init(unit)
	AreaMinPoliceForceUnitElement.super.init(self, unit)
	self._hed.amount = 1
	table.insert(self._save_values, "amount")
end
function AreaMinPoliceForceUnitElement:_build_panel(panel, panel_sizer)
	self:_create_panel()
	panel = panel or self._panel
	panel_sizer = panel_sizer or self._panel_sizer
	local amount_params = {
		name = "Amount:",
		panel = panel,
		sizer = panel_sizer,
		value = self._hed.amount,
		floats = 0,
		tooltip = "Set amount of enemy forces in area",
		min = 1,
		name_proportions = 1,
		ctrlr_proportions = 2
	}
	local amount_points = CoreEWS.number_controller(amount_params)
	amount_points:connect("EVT_COMMAND_TEXT_ENTER", callback(self, self, "set_element_data"), {ctrlr = amount_points, value = "amount"})
	amount_points:connect("EVT_KILL_FOCUS", callback(self, self, "set_element_data"), {ctrlr = amount_points, value = "amount"})
end
