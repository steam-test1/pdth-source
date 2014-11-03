DialogueUnitElement = DialogueUnitElement or class(MissionElement)
function DialogueUnitElement:init(unit)
	DialogueUnitElement.super.init(self, unit)
	self._hed.dialogue = "none"
	table.insert(self._save_values, "dialogue")
end
function DialogueUnitElement:test_element()
	if self._hed.dialogue == "none" then
		return
	end
	managers.dialog:quit_dialog()
	managers.dialog:queue_dialog(self._hed.dialogue, {
		case = "russian",
		on_unit = self._unit,
		skip_idle_check = true
	})
	managers.editor:set_wanted_mute(false)
	managers.editor:set_listener_enabled(true)
end
function DialogueUnitElement:stop_test_element()
	managers.dialog:quit_dialog()
	managers.editor:set_wanted_mute(true)
	managers.editor:set_listener_enabled(false)
end
function DialogueUnitElement:select_dialog_btn()
	local dialog = SelectNameModal:new("Select dialogue", managers.dialog:conversation_names())
	if dialog:cancelled() then
		return
	end
	for _, dialogue in ipairs(dialog:_selected_item_assets()) do
		self._hed.dialogue = dialogue
		CoreEws.change_combobox_value(self._dialogue_params, self._hed.dialogue)
	end
end
function DialogueUnitElement:_build_panel(panel, panel_sizer)
	self:_create_panel()
	panel = panel or self._panel
	panel_sizer = panel_sizer or self._panel_sizer
	local dialog_sizer = EWS:BoxSizer("HORIZONTAL")
	panel_sizer:add(dialog_sizer, 0, 1, "EXPAND,LEFT")
	local dialogue_params = {
		name = "Dialogue:",
		panel = panel,
		sizer = dialog_sizer,
		options = managers.dialog:conversation_names(),
		value = self._hed.dialogue,
		default = "none",
		tooltip = "Select a dialogue from the combobox",
		name_proportions = 1,
		ctrlr_proportions = 2,
		sizer_proportions = 1,
		sorted = true
	}
	local dialogue = CoreEWS.combobox(dialogue_params)
	dialogue:connect("EVT_COMMAND_COMBOBOX_SELECTED", callback(self, self, "set_element_data"), {ctrlr = dialogue, value = "dialogue"})
	self._dialogue_params = dialogue_params
	local toolbar = EWS:ToolBar(panel, "", "TB_FLAT,TB_NODIVIDER")
	toolbar:add_tool("SELECT", "Select dialog", CoreEws.image_path("world_editor\\unit_by_name_list.png"), nil)
	toolbar:connect("SELECT", "EVT_COMMAND_MENU_SELECTED", callback(self, self, "select_dialog_btn"), nil)
	toolbar:realize()
	dialog_sizer:add(toolbar, 0, 1, "EXPAND,LEFT")
end
