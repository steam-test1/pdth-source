TeammateCommentUnitElement = TeammateCommentUnitElement or class(MissionElement)
function TeammateCommentUnitElement:init(unit)
	TeammateCommentUnitElement.super.init(self, unit)
	self._hed.comment = "none"
	self._hed.close_to_element = false
	self._hed.use_instigator = false
	self._hed.radius = 0
	table.insert(self._save_values, "comment")
	table.insert(self._save_values, "close_to_element")
	table.insert(self._save_values, "use_instigator")
	table.insert(self._save_values, "radius")
end
function TeammateCommentUnitElement:post_init(...)
	TeammateCommentUnitElement.super.post_init(self, ...)
end
function TeammateCommentUnitElement:update_selected(t, dt)
	if self._hed.radius ~= 0 then
		local brush = Draw:brush()
		brush:set_color(Color(0.15, 1, 1, 1))
		local pen = Draw:pen(Color(0.15, 0.5, 0.5, 0.5))
		brush:sphere(self._unit:position(), self._hed.radius, 4)
		pen:sphere(self._unit:position(), self._hed.radius)
	end
end
function TeammateCommentUnitElement:test_element()
	if self._hed.comment then
		managers.editor:set_wanted_mute(false)
		managers.editor:set_listener_enabled(true)
		if self._ss then
			self._ss:stop()
		end
		self._ss = SoundDevice:create_source(self._unit:unit_data().name_id)
		self._ss:set_position(self._unit:position())
		self._ss:set_orientation(self._unit:rotation())
		self._ss:set_switch("int_ext", "third")
		for i = 1, 4 do
			self._ss:set_switch("robber", "rb" .. tostring(i))
			if self._ss:post_event(self._hed.comment) then
				break
			end
		end
	end
end
function TeammateCommentUnitElement:stop_test_element()
	managers.editor:set_wanted_mute(true)
	managers.editor:set_listener_enabled(false)
	if self._ss then
		self._ss:stop()
	end
end
function TeammateCommentUnitElement:select_comment_btn()
	local dialog = SelectNameModal:new("Select comment", managers.groupai:state().teammate_comment_names)
	if dialog:cancelled() then
		return
	end
	for _, comment in ipairs(dialog:_selected_item_assets()) do
		self._hed.comment = comment
		CoreEws.change_combobox_value(self._comment_params, self._hed.comment)
	end
end
function TeammateCommentUnitElement:_build_panel(panel, panel_sizer)
	self:_create_panel()
	panel = panel or self._panel
	panel_sizer = panel_sizer or self._panel_sizer
	local comment_sizer = EWS:BoxSizer("HORIZONTAL")
	panel_sizer:add(comment_sizer, 0, 1, "EXPAND,LEFT")
	self._comment_params = {
		name = "Comment:",
		panel = panel,
		sizer = comment_sizer,
		options = managers.groupai:state().teammate_comment_names,
		value = self._hed.comment,
		default = "none",
		tooltip = "Select a comment from the combobox",
		name_proportions = 1,
		ctrlr_proportions = 2,
		sizer_proportions = 1,
		sorted = true
	}
	local comment = CoreEWS.combobox(self._comment_params)
	comment:connect("EVT_COMMAND_COMBOBOX_SELECTED", callback(self, self, "set_element_data"), {ctrlr = comment, value = "comment"})
	local toolbar = EWS:ToolBar(panel, "", "TB_FLAT,TB_NODIVIDER")
	toolbar:add_tool("SELECT", "Select comment", CoreEws.image_path("world_editor\\unit_by_name_list.png"), nil)
	toolbar:connect("SELECT", "EVT_COMMAND_MENU_SELECTED", callback(self, self, "select_comment_btn"), nil)
	toolbar:realize()
	comment_sizer:add(toolbar, 0, 1, "EXPAND,LEFT")
	local close_to_element = EWS:CheckBox(panel, "Play close to element", "")
	close_to_element:set_value(self._hed.close_to_element)
	close_to_element:connect("EVT_COMMAND_CHECKBOX_CLICKED", callback(self, self, "set_element_data"), {
		ctrlr = close_to_element,
		value = "close_to_element"
	})
	panel_sizer:add(close_to_element, 0, 0, "EXPAND")
	local use_instigator = EWS:CheckBox(panel, "Play on instigator", "")
	use_instigator:set_value(self._hed.use_instigator)
	use_instigator:connect("EVT_COMMAND_CHECKBOX_CLICKED", callback(self, self, "set_element_data"), {
		ctrlr = use_instigator,
		value = "use_instigator"
	})
	panel_sizer:add(use_instigator, 0, 0, "EXPAND")
	local radius_params = {
		name = "Radius:",
		value = self._hed.radius,
		panel = panel,
		sizer = panel_sizer,
		tooltip = "(Optional) Sets a distance to use with the check (in cm)",
		floats = 0,
		min = 0,
		name_proportions = 1,
		ctrlr_proportions = 2
	}
	local radius = CoreEWS.number_controller(radius_params)
	radius:connect("EVT_COMMAND_TEXT_ENTER", callback(self, self, "set_element_data"), {ctrlr = radius, value = "radius"})
	radius:connect("EVT_KILL_FOCUS", callback(self, self, "set_element_data"), {ctrlr = radius, value = "radius"})
	local help = {}
	help.text = "If \"Play close to element\" is checked, the comment will be played on a teammate close to the element position, otherwise close to the player."
	help.panel = panel
	help.sizer = panel_sizer
	self:add_help_text(help)
end
function TeammateCommentUnitElement:destroy()
	self:stop_test_element()
	TeammateCommentUnitElement.super.destroy(self)
end
