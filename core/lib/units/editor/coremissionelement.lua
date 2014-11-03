CoreMissionElement = CoreMissionElement or class()
MissionElement = MissionElement or class(CoreMissionElement)
function MissionElement:init(...)
	CoreMissionElement.init(self, ...)
end
function CoreMissionElement:init(unit)
	if not CoreMissionElement.editor_link_brush then
		local brush = Draw:brush()
		brush:set_font(Idstring("core/fonts/nice_editor_font"), 10)
		brush:set_render_template(Idstring("OverlayVertexColorTextured"))
		CoreMissionElement.editor_link_brush = brush
	end
	self._unit = unit
	self._hed = self._unit:mission_element_data()
	self._ud = self._unit:unit_data()
	self._unit:anim_play(1)
	self._save_values = {}
	self._update_selected_on = false
	self:_add_default_saves()
	self._parent_panel = managers.editor:mission_element_panel()
	self._parent_sizer = managers.editor:mission_element_sizer()
	self._panels = {}
	self._on_executed_units = {}
	self._arrow_brush = Draw:brush()
	self:_createicon()
end
function CoreMissionElement:post_init()
end
function CoreMissionElement:_createicon()
	local iconsize = 32
	if Global.iconsize then
		iconsize = Global.iconsize
	end
	if self._icon == nil and self._icon_x == nil then
		return
	end
	local root = self._unit:orientation_object()
	if root == nil then
		return
	end
	if self._iconcolor_type then
		if self._iconcolor_type == "trigger" then
			self._iconcolor = "ff81bffc"
		elseif self._iconcolor_type == "logic" then
			self._iconcolor = "ffffffd9"
		elseif self._iconcolor_type == "operator" then
			self._iconcolor = "fffcbc7c"
		end
	end
	if self._iconcolor == nil then
		self._iconcolor = "fff"
	end
	self._iconcolor_c = Color(self._iconcolor)
	self._icon_gui = World:newgui()
	local pos = self._unit:position() - Vector3(iconsize / 2, iconsize / 2, 0)
	self._icon_ws = self._icon_gui:create_linked_workspace(64, 64, root, pos, Vector3(iconsize, 0, 0), Vector3(0, iconsize, 0))
	self._icon_ws:set_billboard(self._icon_ws.BILLBOARD_BOTH)
	self._icon_ws:panel():gui(Idstring("core/guis/core_edit_icon"))
	self._icon_script = self._icon_ws:panel():gui(Idstring("core/guis/core_edit_icon")):script()
	if self._icon then
		self._icon_script:seticon(self._icon, tostring(self._iconcolor))
	elseif self._icon_x then
		self._icon_script:seticon_texture_rect(self._icon_x, self._icon_y, self._icon_w, self._icon_h, tostring(self._iconcolor))
	end
end
function CoreMissionElement:set_iconsize(size)
	if not self._icon_ws then
		return
	end
	local root = self._unit:orientation_object()
	local pos = self._unit:position() - Vector3(size / 2, size / 2, 0)
	self._icon_ws:set_linked(64, 64, root, pos, Vector3(size, 0, 0), Vector3(0, size, 0))
end
function CoreMissionElement:_add_default_saves()
	self._hed.enabled = true
	self._hed.debug = false
	self._hed.execute_on_startup = false
	self._hed.execute_on_restart = false
	self._hed.base_delay = 0
	self._hed.trigger_times = 0
	self._hed.on_executed = {}
	table.insert(self._save_values, "unit:position")
	table.insert(self._save_values, "unit:rotation")
	table.insert(self._save_values, "enabled")
	table.insert(self._save_values, "debug")
	table.insert(self._save_values, "execute_on_startup")
	table.insert(self._save_values, "execute_on_restart")
	table.insert(self._save_values, "base_delay")
	table.insert(self._save_values, "trigger_times")
	table.insert(self._save_values, "on_executed")
end
function CoreMissionElement:build_default_gui(panel, sizer)
	local enabled = EWS:CheckBox(panel, "Enabled", "")
	enabled:set_value(self._hed.enabled)
	enabled:connect("EVT_COMMAND_CHECKBOX_CLICKED", callback(self, self, "set_element_data"), {ctrlr = enabled, value = "enabled"})
	sizer:add(enabled, 0, 0, "EXPAND")
	local debug = EWS:CheckBox(panel, "Debug", "")
	debug:set_value(self._hed.debug)
	debug:connect("EVT_COMMAND_CHECKBOX_CLICKED", callback(self, self, "set_element_data"), {ctrlr = debug, value = "debug"})
	sizer:add(debug, 0, 0, "EXPAND")
	local execute_on_startup = EWS:CheckBox(panel, "Execute on startup", "")
	execute_on_startup:set_value(self._hed.execute_on_startup)
	execute_on_startup:connect("EVT_COMMAND_CHECKBOX_CLICKED", callback(self, self, "set_element_data"), {
		ctrlr = execute_on_startup,
		value = "execute_on_startup"
	})
	sizer:add(execute_on_startup, 0, 0, "EXPAND")
	local execute_on_restart = EWS:CheckBox(panel, "Execute on restart", "")
	execute_on_restart:set_value(self._hed.execute_on_restart)
	execute_on_restart:connect("EVT_COMMAND_CHECKBOX_CLICKED", callback(self, self, "set_element_data"), {
		ctrlr = execute_on_restart,
		value = "execute_on_restart"
	})
	sizer:add(execute_on_restart, 0, 0, "EXPAND")
	local trigger_times_params = {
		name = "Trigger times:",
		panel = panel,
		sizer = sizer,
		value = self._hed.trigger_times,
		floats = 0,
		tooltip = "Specifies how many time this element can be executed (0 mean unlimited times)",
		min = 0,
		name_proportions = 1,
		ctrlr_proportions = 2
	}
	local trigger_times = CoreEWS.number_controller(trigger_times_params)
	trigger_times:connect("EVT_COMMAND_TEXT_ENTER", callback(self, self, "set_element_data"), {
		ctrlr = trigger_times,
		value = "trigger_times"
	})
	trigger_times:connect("EVT_KILL_FOCUS", callback(self, self, "set_element_data"), {
		ctrlr = trigger_times,
		value = "trigger_times"
	})
	local base_delay_params = {
		name = "Base Delay:",
		panel = panel,
		sizer = sizer,
		value = self._hed.base_delay,
		floats = 2,
		tooltip = "Specifies a base delay that is added to each on executed delay",
		min = 0,
		name_proportions = 1,
		ctrlr_proportions = 2
	}
	local base_delay = CoreEWS.number_controller(base_delay_params)
	base_delay:connect("EVT_COMMAND_TEXT_ENTER", callback(self, self, "set_element_data"), {ctrlr = base_delay, value = "base_delay"})
	base_delay:connect("EVT_KILL_FOCUS", callback(self, self, "set_element_data"), {ctrlr = base_delay, value = "base_delay"})
	local on_executed_sizer = EWS:StaticBoxSizer(panel, "VERTICAL", "On Executed")
	local element_sizer = EWS:BoxSizer("HORIZONTAL")
	on_executed_sizer:add(element_sizer, 0, 1, "EXPAND,LEFT")
	self._elements_params = {
		name = "Element:",
		panel = panel,
		sizer = element_sizer,
		options = {},
		value = nil,
		tooltip = "Select an element from the combobox",
		name_proportions = 1,
		ctrlr_proportions = 2,
		sizer_proportions = 1,
		sorted = true
	}
	local elements = CoreEWS.combobox(self._elements_params)
	elements:connect("EVT_COMMAND_COMBOBOX_SELECTED", callback(self, self, "on_executed_element_selected"), nil)
	self._add_elements_toolbar = EWS:ToolBar(panel, "", "TB_FLAT,TB_NODIVIDER")
	self._add_elements_toolbar:add_tool("ADD_ELEMENT", "Add an element", CoreEws.image_path("world_editor\\unit_by_name_list.png"), nil)
	self._add_elements_toolbar:connect("ADD_ELEMENT", "EVT_COMMAND_MENU_SELECTED", callback(self, self, "_on_toolbar_add_element"), nil)
	self._add_elements_toolbar:realize()
	element_sizer:add(self._add_elements_toolbar, 0, 1, "EXPAND,LEFT")
	self._elements_toolbar = EWS:ToolBar(panel, "", "TB_FLAT,TB_NODIVIDER")
	self._elements_toolbar:add_tool("DELETE_SELECTED", "Remove selected element", CoreEws.image_path("toolbar\\delete_16x16.png"), nil)
	self._elements_toolbar:connect("DELETE_SELECTED", "EVT_COMMAND_MENU_SELECTED", callback(self, self, "_on_toolbar_remove"), nil)
	self._elements_toolbar:realize()
	element_sizer:add(self._elements_toolbar, 0, 1, "EXPAND,LEFT")
	self._element_delay_params = {
		name = "Delay:",
		panel = panel,
		sizer = on_executed_sizer,
		value = 0,
		floats = 2,
		tooltip = "Sets the delay time for the selected on executed element",
		min = 0,
		name_proportions = 1,
		ctrlr_proportions = 2
	}
	local element_delay = CoreEWS.number_controller(self._element_delay_params)
	element_delay:connect("EVT_COMMAND_TEXT_ENTER", callback(self, self, "on_executed_element_delay"), nil)
	element_delay:connect("EVT_KILL_FOCUS", callback(self, self, "on_executed_element_delay"), nil)
	sizer:add(on_executed_sizer, 0, 0, "EXPAND")
	sizer:add(EWS:StaticLine(panel, "", "LI_HORIZONTAL"), 0, 5, "EXPAND,TOP,BOTTOM")
	self:append_elements_sorted()
	self:set_on_executed_element()
end
function CoreMissionElement:_create_panel()
	if self._panel then
		return
	end
	self._panel, self._panel_sizer = self:_add_panel(self._parent_panel, self._parent_sizer)
end
function CoreMissionElement:_build_panel()
	self:_create_panel()
end
function CoreMissionElement:panel(id, parent, parent_sizer)
	if id then
		if self._panels[id] then
			return self._panels[id]
		end
		local panel, panel_sizer = self:_add_panel(parent, parent_sizer)
		self:_build_panel(panel, panel_sizer)
		self._panels[id] = panel
		return self._panels[id]
	end
	if not self._panel then
		self:_build_panel()
	end
	return self._panel
end
function CoreMissionElement:_add_panel(parent, parent_sizer)
	local panel = EWS:Panel(parent, "", "TAB_TRAVERSAL")
	local panel_sizer = EWS:BoxSizer("VERTICAL")
	panel:set_sizer(panel_sizer)
	panel_sizer:add(EWS:StaticLine(panel, "", "LI_HORIZONTAL"), 0, 0, "EXPAND")
	parent_sizer:add(panel, 1, 0, "EXPAND")
	panel:set_visible(false)
	panel:set_extension({alive = true})
	self:build_default_gui(panel, panel_sizer)
	return panel, panel_sizer
end
function CoreMissionElement:add_help_text(data)
	if data.panel and data.sizer then
		data.sizer:add(EWS:TextCtrl(data.panel, data.text, 0, "TE_MULTILINE,TE_READONLY,TE_WORDWRAP,TE_CENTRE"), 0, 5, "EXPAND,TOP,BOTTOM")
	end
end
function CoreMissionElement:_on_toolbar_add_element()
	local function f(unit)
		return unit:type() == Idstring("mission_element") and unit ~= self._unit
	end
	local dialog = SelectUnitByNameModal:new("Add/Remove element", f)
	for _, unit in ipairs(dialog:selected_units()) do
		self:add_on_executed(unit)
	end
end
function CoreMissionElement:_on_toolbar_remove()
	self:remove_on_execute(self:_current_element_unit())
end
function CoreMissionElement:set_element_data(data)
	if data.callback then
		local he = self._unit:mission_element()
		he[data.callback](he, data.ctrlr, data.params)
	end
	if data.value then
		self._hed[data.value] = data.ctrlr:get_value()
		self._hed[data.value] = tonumber(self._hed[data.value]) or self._hed[data.value]
	end
end
function CoreMissionElement:selected()
	self:append_elements_sorted()
end
function CoreMissionElement:update_selected()
end
function CoreMissionElement:update_unselected()
end
function CoreMissionElement:begin_editing()
end
function CoreMissionElement:end_editing()
end
function CoreMissionElement:clone_data(all_units)
	for _, data in ipairs(self._hed.on_executed) do
		table.insert(self._on_executed_units, all_units[data.id])
	end
end
function CoreMissionElement:layer_finished()
	for _, data in ipairs(self._hed.on_executed) do
		local unit = managers.worlddefinition:get_mission_element_unit(data.id)
		table.insert(self._on_executed_units, unit)
	end
end
function CoreMissionElement:save_data(file, t)
	self:save_values(file, t)
end
function CoreMissionElement:save_values(file, t)
	t = t .. "\t"
	file:puts(t .. "<values>")
	for _, name in ipairs(self._save_values) do
		self:save_value(file, t, name)
	end
	file:puts(t .. "</values>")
end
function CoreMissionElement:save_value(file, t, name)
	t = t .. "\t"
	file:puts(save_value_string(self._hed, name, t, self._unit))
end
function CoreMissionElement:new_save_values()
	local t = {
		position = self._unit:position(),
		rotation = self._unit:rotation()
	}
	for _, value in ipairs(self._save_values) do
		t[value] = self._hed[value]
	end
	return t
end
function CoreMissionElement:name()
	return self._unit:name() .. self._ud.unit_id
end
function CoreMissionElement:add_to_mission_package()
end
function CoreMissionElement:get_color(type)
	if type then
		if type == "activate" or type == "enable" then
			return 0, 1, 0
		elseif type == "deactivate" or type == "disable" then
			return 1, 0, 0
		end
	end
	return 0, 1, 0
end
function CoreMissionElement:draw_links_selected(t, dt, selected_unit)
	local unit = self:_current_element_unit()
	if alive(unit) then
		local r, g, b = 1, 1, 1
		if self._iconcolor and managers.editor:layer("Mission"):use_colored_links() then
			r = self._iconcolor_c.r
			g = self._iconcolor_c.g
			b = self._iconcolor_c.b
		end
		self:_draw_link({
			from_unit = self._unit,
			to_unit = unit,
			r = r,
			g = g,
			b = b,
			thick = true
		})
	end
end
function CoreMissionElement:_draw_link(params)
	params.draw_flow = managers.editor:layer("Mission"):visualize_flow()
	Application:draw_link(params)
end
function CoreMissionElement:draw_links_unselected()
end
function CoreMissionElement:clear()
end
function CoreMissionElement:action_types()
	return self._action_types
end
function CoreMissionElement:timeline_color()
	return self._timeline_color
end
function CoreMissionElement:add_triggers()
end
function CoreMissionElement:clear_triggers()
end
function CoreMissionElement:widget_affect_object()
	return nil
end
function CoreMissionElement:use_widget_position()
	return nil
end
function CoreMissionElement:set_enabled()
	if self._icon_ws then
		self._icon_ws:show()
	end
end
function CoreMissionElement:set_disabled()
	if self._icon_ws then
		self._icon_ws:hide()
	end
end
function CoreMissionElement:on_set_visible(visible)
	if self._icon_ws then
		if visible then
			self._icon_ws:show()
		else
			self._icon_ws:hide()
		end
	end
end
function CoreMissionElement:set_update_selected_on(value)
	self._update_selected_on = value
end
function CoreMissionElement:update_selected_on()
	return self._update_selected_on
end
function CoreMissionElement:destroy_panel()
	if self._panel then
		self._panel:extension().alive = false
		self._panel:destroy()
		self._panel = nil
	end
end
function CoreMissionElement:destroy()
	if self._timeline then
		self._timeline:destroy()
	end
	if self._panel then
		self._panel:extension().alive = false
		self._panel:destroy()
	end
	if self._icon_ws then
		self._icon_gui:destroy_workspace(self._icon_ws)
		self._icon_ws = nil
	end
end
function CoreMissionElement:draw_links(t, dt, selected_unit)
	self:draw_link_on_executed(t, dt, selected_unit)
end
function CoreMissionElement:draw_link_on_executed(t, dt, selected_unit)
	local unit_sel = self._unit == selected_unit
	CoreMissionElement.editor_link_brush:set_color(unit_sel and Color.green or Color.white)
	for _, unit in ipairs(self._on_executed_units) do
		if not selected_unit or unit_sel or unit == selected_unit then
			local dir = mvector3.copy(unit:position())
			mvector3.subtract(dir, self._unit:position())
			local vec_len = mvector3.normalize(dir)
			local offset = math.min(50, vec_len)
			mvector3.multiply(dir, offset)
			if self._distance_to_camera < 1000000 then
				CoreMissionElement.editor_link_brush:center_text(self._unit:position() + dir, string.format("%.2f", self:_get_on_executed(unit:unit_data().unit_id).delay), managers.editor:camera_rotation():x(), -managers.editor:camera_rotation():z())
			end
			local r, g, b = 1, 1, 1
			if self._iconcolor and managers.editor:layer("Mission"):use_colored_links() then
				r = self._iconcolor_c.r
				g = self._iconcolor_c.g
				b = self._iconcolor_c.b
			end
			self:_draw_link({
				from_unit = self._unit,
				to_unit = unit,
				r = r * 0.75,
				g = g * 0.75,
				b = b * 0.75
			})
		end
	end
end
function CoreMissionElement:add_on_executed(unit)
	if self:remove_on_execute(unit) then
		return
	end
	local params = {
		id = unit:unit_data().unit_id,
		delay = 0
	}
	table.insert(self._on_executed_units, unit)
	table.insert(self._hed.on_executed, params)
	if self._timeline then
		self._timeline:add_element(unit, params)
	end
	self:append_elements_sorted()
	self:set_on_executed_element(unit)
end
function CoreMissionElement:remove_links(unit)
end
function CoreMissionElement:remove_on_execute(unit)
	for _, on_executed in ipairs(self._hed.on_executed) do
		if on_executed.id == unit:unit_data().unit_id then
			if self._timeline then
				self._timeline:remove_element(on_executed)
			end
			table.delete(self._hed.on_executed, on_executed)
			table.delete(self._on_executed_units, unit)
			self:append_elements_sorted()
			return true
		end
	end
	return false
end
function CoreMissionElement:delete_unit(units)
	local id = self._unit:unit_data().unit_id
	for _, unit in ipairs(units) do
		unit:mission_element():remove_on_execute(self._unit)
		unit:mission_element():remove_links(self._unit)
	end
end
function CoreMissionElement:set_on_executed_element(unit, id)
	unit = unit or self:on_execute_unit_by_id(id)
	if not alive(unit) then
		self:_set_on_execute_ctrlrs_enabled(false)
		self:_set_first_executed_element()
		return
	end
	self:_set_on_execute_ctrlrs_enabled(true)
	if self._elements_params then
		local name = self:combobox_name(unit)
		CoreEWS.change_combobox_value(self._elements_params, name)
		self:set_on_executed_data()
	end
end
function CoreMissionElement:set_on_executed_data()
	local id = self:combobox_id(self._elements_params.value)
	local params = self:_get_on_executed(id)
	CoreEWS.change_entered_number(self._element_delay_params, params.delay)
	if self._timeline then
		self._timeline:select_element(params)
	end
end
function CoreMissionElement:_set_first_executed_element()
	if #self._hed.on_executed > 0 then
		self:set_on_executed_element(nil, self._hed.on_executed[1].id)
	end
end
function CoreMissionElement:_set_on_execute_ctrlrs_enabled(enabled)
	if not self._elements_params then
		return
	end
	self._elements_params.ctrlr:set_enabled(enabled)
	self._element_delay_params.number_ctrlr:set_enabled(enabled)
	self._elements_toolbar:set_enabled(enabled)
end
function CoreMissionElement:on_executed_element_selected()
	self:set_on_executed_data()
end
function CoreMissionElement:_get_on_executed(id)
	for _, params in ipairs(self._hed.on_executed) do
		if params.id == id then
			return params
		end
	end
end
function CoreMissionElement:_current_element_id()
	if not self._elements_params or not self._elements_params.value then
		return nil
	end
	return self:combobox_id(self._elements_params.value)
end
function CoreMissionElement:_current_element_unit()
	local id = self:_current_element_id()
	if not id then
		return nil
	end
	local unit = self:on_execute_unit_by_id(id)
	if not alive(unit) then
		return nil
	end
	return unit
end
function CoreMissionElement:on_executed_element_delay()
	local id = self:combobox_id(self._elements_params.value)
	local params = self:_get_on_executed(id)
	params.delay = self._element_delay_params.value
	if self._timeline then
		self._timeline:delay_updated(params)
	end
end
function CoreMissionElement:append_elements_sorted()
	if not self._elements_params then
		return
	end
	local id = self:_current_element_id()
	CoreEWS.update_combobox_options(self._elements_params, self:_combobox_names_names(self._on_executed_units))
	self:set_on_executed_element(nil, id)
end
function CoreMissionElement:combobox_name(unit)
	return unit:unit_data().name_id .. " (" .. unit:unit_data().unit_id .. ")"
end
function CoreMissionElement:combobox_id(name)
	local s
	local e = string.len(name) - 1
	for i = string.len(name), 0, -1 do
		local t = string.sub(name, i, i)
		if t == "(" then
			s = i + 1
			break
		end
	end
	return tonumber(string.sub(name, s, e))
end
function CoreMissionElement:on_execute_unit_by_id(id)
	for _, unit in ipairs(self._on_executed_units) do
		if unit:unit_data().unit_id == id then
			return unit
		end
	end
	return nil
end
function CoreMissionElement:_combobox_names_names(units)
	local names = {}
	for _, unit in ipairs(units) do
		table.insert(names, self:combobox_name(unit))
	end
	return names
end
function CoreMissionElement:on_timeline()
	if not self._timeline then
		self._timeline = MissionElementTimeline:new(self._unit:unit_data().name_id)
		self._timeline:set_mission_unit(self._unit)
	else
		self._timeline:set_visible(true)
	end
end
