MaskFilterUnitElement = MaskFilterUnitElement or class(MissionElement)
function MaskFilterUnitElement:init(unit)
	MaskFilterUnitElement.super.init(self, unit)
	self._hed.mask = "none"
	self._hed.player_amount = 1
	table.insert(self._save_values, "mask")
	table.insert(self._save_values, "player_amount")
end
function MaskFilterUnitElement:_build_panel(panel, panel_sizer)
	self:_create_panel()
	panel = panel or self._panel
	panel_sizer = panel_sizer or self._panel_sizer
	local options = {}
	for name, _ in pairs(tweak_data.mask_sets) do
		table.insert(options, name)
	end
	local mask_params = {
		name = "Mask:",
		panel = panel,
		sizer = panel_sizer,
		options = options,
		value = self._hed.mask,
		default = "none",
		tooltip = "Select  mask from the combobox",
		name_proportions = 1,
		ctrlr_proportions = 2,
		sorted = true
	}
	local mask = CoreEWS.combobox(mask_params)
	mask:connect("EVT_COMMAND_COMBOBOX_SELECTED", callback(self, self, "set_element_data"), {ctrlr = mask, value = "mask"})
end
