EquipmentUnitElement = EquipmentUnitElement or class(MissionElement)
function EquipmentUnitElement:init(unit)
	EquipmentUnitElement.super.init(self, unit)
	self._hed.equipment = "none"
	self._hed.amount = 1
	table.insert(self._save_values, "equipment")
	table.insert(self._save_values, "amount")
end
function EquipmentUnitElement:_build_panel(panel, panel_sizer)
	self:_create_panel()
	panel = panel or self._panel
	panel_sizer = panel_sizer or self._panel_sizer
	local options = {}
	for name, _ in pairs(tweak_data.equipments.specials) do
		table.insert(options, name)
	end
	local equipment_params = {
		name = "Equipment:",
		panel = panel,
		sizer = panel_sizer,
		options = options,
		value = self._hed.equipment,
		default = "none",
		tooltip = "Select an equipment from the combobox",
		name_proportions = 1,
		ctrlr_proportions = 2,
		sorted = true
	}
	local equipment = CoreEWS.combobox(equipment_params)
	equipment:connect("EVT_COMMAND_COMBOBOX_SELECTED", callback(self, self, "set_element_data"), {ctrlr = equipment, value = "equipment"})
	local amount_params = {
		name = "Amount:",
		panel = panel,
		sizer = panel_sizer,
		value = self._hed.amount,
		floats = 0,
		tooltip = "Specifies how many of this equipment to recieve (only work on those who has a max_amount set in their tweak data).",
		min = 1,
		name_proportions = 1,
		ctrlr_proportions = 2
	}
	local amount = CoreEWS.number_controller(amount_params)
	amount:connect("EVT_COMMAND_TEXT_ENTER", callback(self, self, "set_element_data"), {ctrlr = amount, value = "amount"})
	amount:connect("EVT_KILL_FOCUS", callback(self, self, "set_element_data"), {ctrlr = amount, value = "amount"})
end
