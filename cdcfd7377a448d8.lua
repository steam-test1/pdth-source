ScenarioTextUnitElement = ScenarioTextUnitElement or class(MissionElement)
function ScenarioTextUnitElement:init(unit)
	ScenarioTextUnitElement.super.init(self, unit)
	self._options = {"debug_none", "sl_bank"}
	self._hed.text_id = "debug_none"
	table.insert(self._save_values, "text_id")
end
function ScenarioTextUnitElement:set_text()
	self._text:set_value(managers.localization:text(self._hed.text_id))
end
function ScenarioTextUnitElement:_build_panel(panel, panel_sizer)
	self:_create_panel()
	panel = panel or self._panel
	panel_sizer = panel_sizer or self._panel_sizer
	local selection_params = {
		name = "Text id:",
		panel = panel,
		sizer = panel_sizer,
		options = self._options,
		value = self._hed.text_id,
		tooltip = "Select a text id from the combobox",
		name_proportions = 1,
		ctrlr_proportions = 2,
		sorted = true
	}
	local selection = CoreEWS.combobox(selection_params)
	selection:connect("EVT_COMMAND_COMBOBOX_SELECTED", callback(self, self, "set_element_data"), {ctrlr = selection, value = "text_id"})
	selection:connect("EVT_COMMAND_COMBOBOX_SELECTED", callback(self, self, "set_text"), nil)
	local text_sizer = EWS:BoxSizer("HORIZONTAL")
	text_sizer:add(EWS:StaticText(panel, "Text: ", "", ""), 1, 2, "ALIGN_CENTER_VERTICAL,RIGHT,EXPAND")
	self._text = EWS:StaticText(panel, managers.localization:text(self._hed.text_id), "", "")
	text_sizer:add(self._text, 2, 2, "RIGHT,TOP,EXPAND")
	panel_sizer:add(text_sizer, 1, 0, "EXPAND")
end
