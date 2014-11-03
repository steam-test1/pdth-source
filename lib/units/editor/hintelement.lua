HintUnitElement = HintUnitElement or class(MissionElement)
function HintUnitElement:init(unit)
	HintUnitElement.super.init(self, unit)
	self._hed.hint_id = "none"
	table.insert(self._save_values, "hint_id")
end
function HintUnitElement:set_text()
	local hint = managers.hint:hint(self._hed.hint_id)
	self._text:set_value(hint and managers.localization:text(hint.text_id) or "none")
end
function HintUnitElement:_build_panel(panel, panel_sizer)
	self:_create_panel()
	panel = panel or self._panel
	panel_sizer = panel_sizer or self._panel_sizer
	local selection_params = {
		name = "Hint id:",
		panel = panel,
		sizer = panel_sizer,
		options = managers.hint:ids(),
		default = "none",
		value = self._hed.hint_id,
		tooltip = "Select a text id from the combobox",
		name_proportions = 1,
		ctrlr_proportions = 2,
		sorted = true
	}
	local selection = CoreEWS.combobox(selection_params)
	selection:connect("EVT_COMMAND_COMBOBOX_SELECTED", callback(self, self, "set_element_data"), {ctrlr = selection, value = "hint_id"})
	selection:connect("EVT_COMMAND_COMBOBOX_SELECTED", callback(self, self, "set_text"), nil)
	local text_sizer = EWS:BoxSizer("HORIZONTAL")
	text_sizer:add(EWS:StaticText(panel, "Text: ", "", ""), 1, 2, "ALIGN_CENTER_VERTICAL,RIGHT,EXPAND")
	self._text = EWS:StaticText(panel, managers.localization:text(self._hed.hint_id), "", "")
	self:set_text()
	text_sizer:add(self._text, 2, 2, "RIGHT,TOP,EXPAND")
	panel_sizer:add(text_sizer, 1, 0, "EXPAND")
end
