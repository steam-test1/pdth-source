WaypointUnitElement = WaypointUnitElement or class(MissionElement)
function WaypointUnitElement:init(unit)
	WaypointUnitElement.super.init(self, unit)
	self:_add_wp_options()
	self._icon_options = {
		"wp_vial",
		"wp_standard",
		"wp_powersupply",
		"wp_watersupply",
		"wp_c4",
		"wp_drill",
		"wp_hack",
		"wp_talk",
		"wp_crowbar",
		"wp_planks",
		"wp_door",
		"wp_saw",
		"wp_bag",
		"wp_exit",
		"wp_can",
		"wp_target",
		"wp_key",
		"wp_winch",
		"wp_escort",
		"wp_powerbutton",
		"wp_server",
		"wp_powercord",
		"wp_phone",
		"wp_scrubs",
		"wp_sentry"
	}
	self._hed.icon = "wp_standard"
	self._hed.text_id = "debug_none"
	table.insert(self._save_values, "icon")
	table.insert(self._save_values, "text_id")
end
function WaypointUnitElement:_add_wp_options()
	self._text_options = {"debug_none"}
	for _, id_string in ipairs(managers.localization:ids("strings/system_text")) do
		local s = id_string:s()
		if string.find(s, "wp_") then
			table.insert(self._text_options, s)
		end
	end
end
function WaypointUnitElement:set_text()
	self._text:set_value(managers.localization:text(self._hed.text_id))
end
function WaypointUnitElement:_build_panel(panel, panel_sizer)
	self:_create_panel()
	panel = panel or self._panel
	panel_sizer = panel_sizer or self._panel_sizer
	local icon_params = {
		name = "Icon:",
		panel = panel,
		sizer = panel_sizer,
		options = self._icon_options,
		value = self._hed.icon,
		tooltip = "Select an icon from the combobox",
		name_proportions = 1,
		ctrlr_proportions = 2,
		sorted = true
	}
	local icon = CoreEWS.combobox(icon_params)
	icon:connect("EVT_COMMAND_COMBOBOX_SELECTED", callback(self, self, "set_element_data"), {ctrlr = icon, value = "icon"})
	local text_params = {
		name = "Text id:",
		panel = panel,
		sizer = panel_sizer,
		options = self._text_options,
		value = self._hed.text_id,
		tooltip = "Select a text id from the combobox",
		name_proportions = 1,
		ctrlr_proportions = 2,
		sorted = true
	}
	local text = CoreEWS.combobox(text_params)
	text:connect("EVT_COMMAND_COMBOBOX_SELECTED", callback(self, self, "set_element_data"), {ctrlr = text, value = "text_id"})
	text:connect("EVT_COMMAND_COMBOBOX_SELECTED", callback(self, self, "set_text"), nil)
	local text_sizer = EWS:BoxSizer("HORIZONTAL")
	text_sizer:add(EWS:StaticText(panel, "Text: ", "", ""), 1, 2, "ALIGN_CENTER_VERTICAL,RIGHT,EXPAND")
	self._text = EWS:StaticText(panel, managers.localization:text(self._hed.text_id), "", "")
	text_sizer:add(self._text, 2, 2, "RIGHT,TOP,EXPAND")
	panel_sizer:add(text_sizer, 1, 0, "EXPAND")
end
