FlashlightUnitElement = FlashlightUnitElement or class(MissionElement)
function FlashlightUnitElement:init(unit)
	FlashlightUnitElement.super.init(self, unit)
	self._hed.state = false
	self._hed.on_player = false
	table.insert(self._save_values, "state")
	table.insert(self._save_values, "on_player")
end
function FlashlightUnitElement:_build_panel(panel, panel_sizer)
	self:_create_panel()
	panel = panel or self._panel
	panel_sizer = panel_sizer or self._panel_sizer
	local state = EWS:CheckBox(panel, "Flashlight state", "")
	state:set_value(self._hed.state)
	state:connect("EVT_COMMAND_CHECKBOX_CLICKED", callback(self, self, "set_element_data"), {ctrlr = state, value = "state"})
	panel_sizer:add(state, 0, 0, "EXPAND")
	local on_player = EWS:CheckBox(panel, "Include player", "")
	on_player:set_value(self._hed.on_player)
	on_player:connect("EVT_COMMAND_CHECKBOX_CLICKED", callback(self, self, "set_element_data"), {ctrlr = on_player, value = "on_player"})
	panel_sizer:add(on_player, 0, 0, "EXPAND")
	local help = {}
	help.text = "Sets if flashlights should be turned on or off."
	help.panel = panel
	help.sizer = panel_sizer
	self:add_help_text(help)
end
