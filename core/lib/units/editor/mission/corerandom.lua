CoreRandomUnitElement = CoreRandomUnitElement or class(MissionElement)
RandomUnitElement = RandomUnitElement or class(CoreRandomUnitElement)
function RandomUnitElement:init(...)
	CoreRandomUnitElement.init(self, ...)
end
function CoreRandomUnitElement:init(unit)
	MissionElement.init(self, unit)
	self._hed.amount = 1
	self._hed.ignore_disabled = false
	table.insert(self._save_values, "amount")
	table.insert(self._save_values, "ignore_disabled")
end
function CoreRandomUnitElement:_build_panel(panel, panel_sizer)
	self:_create_panel()
	panel = panel or self._panel
	panel_sizer = panel_sizer or self._panel_sizer
	local amount_params = {
		name = "Amount:",
		panel = panel,
		sizer = panel_sizer,
		value = self._hed.amount,
		floats = 0,
		tooltip = "Specifies how many times the counter should be executed before running its on executed",
		min = 1,
		name_proportions = 1,
		ctrlr_proportions = 2,
		sorted = false
	}
	local amount = CoreEWS.number_controller(amount_params)
	amount:connect("EVT_COMMAND_TEXT_ENTER", callback(self, self, "set_element_data"), {ctrlr = amount, value = "amount"})
	amount:connect("EVT_KILL_FOCUS", callback(self, self, "set_element_data"), {ctrlr = amount, value = "amount"})
	local ignore_disabled = EWS:CheckBox(panel, "Ignore disabled", "")
	ignore_disabled:set_value(self._hed.ignore_disabled)
	ignore_disabled:connect("EVT_COMMAND_CHECKBOX_CLICKED", callback(self, self, "set_element_data"), {
		ctrlr = ignore_disabled,
		value = "ignore_disabled"
	})
	panel_sizer:add(ignore_disabled, 0, 0, "EXPAND")
end
