core:import("CoreEditorUtils")
core:import("CoreEws")
EditUnitEditableGui = EditUnitEditableGui or class(EditUnitBase)
function EditUnitEditableGui:init(editor)
	local panel, sizer = editor or managers.editor:add_unit_edit_page({name = "Gui Text", class = self})
	self._panel = panel
	self._ctrls = {}
	self._element_guis = {}
	local ctrlrs_sizer = EWS:BoxSizer("VERTICAL")
	local horizontal_sizer = EWS:BoxSizer("HORIZONTAL")
	horizontal_sizer:add(EWS:StaticText(self._panel, "Text:", 0, ""), 1, 0, "EXPAND")
	local gui_text = EWS:TextCtrl(self._panel, "none", "", "TE_RIGHT")
	gui_text:connect("EVT_COMMAND_TEXT_UPDATED", callback(self, self, "update_gui_text"), gui_text)
	horizontal_sizer:add(gui_text, 3, 0, "EXPAND")
	local color_button = EWS:Button(self._panel, "", "", "BU_EXACTFIT,NO_BORDER")
	color_button:connect("EVT_COMMAND_BUTTON_CLICKED", callback(self, self, "show_color_dialog"), "")
	horizontal_sizer:add(color_button, 0, 2, "EXPAND,LEFT")
	ctrlrs_sizer:add(horizontal_sizer, 0, 0, "EXPAND")
	self._font_size_params = {
		name = "Font size:",
		panel = panel,
		sizer = ctrlrs_sizer,
		value = 1,
		floats = 2,
		tooltip = "Set the font size using the slider",
		min = 0.1,
		max = 10,
		name_proportions = 1,
		ctrlr_proportions = 3,
		slider_ctrlr_proportions = 4
	}
	CoreEws.slider_and_number_controller(self._font_size_params)
	self._font_size_params.slider_ctrlr:connect("EVT_SCROLL_CHANGED", callback(self, self, "update_font_size"), nil)
	self._font_size_params.slider_ctrlr:connect("EVT_SCROLL_THUMBTRACK", callback(self, self, "update_font_size"), nil)
	self._font_size_params.number_ctrlr:connect("EVT_COMMAND_TEXT_ENTER", callback(self, self, "update_font_size"), nil)
	self._font_size_params.number_ctrlr:connect("EVT_KILL_FOCUS", callback(self, self, "update_font_size"), nil)
	sizer:add(ctrlrs_sizer, 0, 0, "EXPAND")
	self._ctrls.gui_text = gui_text
	self._ctrls.color_button = color_button
	panel:layout()
	panel:set_enabled(false)
end
function EditUnitEditableGui:show_color_dialog()
	local colordlg = EWS:ColourDialog(Global.frame, true, self._ctrls.color_button:background_colour() / 255)
	if colordlg:show_modal() then
		self._ctrls.color_button:set_background_colour(colordlg:get_colour().x * 255, colordlg:get_colour().y * 255, colordlg:get_colour().z * 255)
		for _, unit in ipairs(self._ctrls.units) do
			if alive(unit) and unit:editable_gui() then
				unit:editable_gui():set_font_color(Vector3(colordlg:get_colour().x, colordlg:get_colour().y, colordlg:get_colour().z))
			end
		end
	end
end
function EditUnitEditableGui:update_gui_text(gui_text)
	if self._no_event then
		return
	end
	for _, unit in ipairs(self._ctrls.units) do
		if alive(unit) and unit:editable_gui() then
			unit:editable_gui():set_text(gui_text:get_value())
		end
	end
end
function EditUnitEditableGui:update_font_size(font_size)
	if self._no_event then
		return
	end
	for _, unit in ipairs(self._ctrls.units) do
		if alive(unit) and unit:editable_gui() then
			unit:editable_gui():set_font_size(self._font_size_params.value)
		end
	end
end
function EditUnitEditableGui:is_editable(unit, units)
	if alive(unit) and unit:editable_gui() then
		self._ctrls.unit = unit
		self._ctrls.units = units
		self._no_event = true
		self._ctrls.gui_text:set_value(self._ctrls.unit:editable_gui():text())
		local font_color = self._ctrls.unit:editable_gui():font_color()
		self._ctrls.color_button:set_background_colour(font_color.x * 255, font_color.y * 255, font_color.z * 255)
		CoreEws.change_slider_and_number_value(self._font_size_params, self._ctrls.unit:editable_gui():font_size())
		self._no_event = false
		return true
	end
	return false
end
