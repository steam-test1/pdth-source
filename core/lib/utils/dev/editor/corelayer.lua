core:module("CoreLayer")
core:import("CoreEngineAccess")
core:import("CoreEditorSave")
core:import("CoreEditorUtils")
core:import("CoreEditorWidgets")
core:import("CoreEvent")
core:import("CoreClass")
core:import("CoreCode")
core:import("CoreInput")
core:import("CoreTable")
core:import("CoreUnit")
Layer = Layer or CoreClass.class()
function Layer:init(owner, save_name)
	if not owner then
		Application:error("Layer:init was called without parameters owner and save_name")
	end
	self._owner = owner or self._owner
	self._save_name = save_name
	self._confirmed_unit_types = {}
	self._unit_map = {}
	self._unit_types = {}
	self._created_units = {}
	self._selected_units = {}
	self._name_ids = {}
	self._notebook_units_lists = {}
	self._editor_data = self._owner._editor_data
	self._ctrl = self._editor_data.virtual_controller
	self._move_widget = CoreEditorWidgets.MoveWidget:new(self)
	self._rotate_widget = CoreEditorWidgets.RotationWidget:new(self)
	self._layer_enabled = true
	self._will_use_widgets = false
	self._using_widget = false
	self._ignore_global_select = false
	self._marker_sphere_size = 25
	self._uses_continents = false
	self:_init_unit_highlighter()
end
function Layer:_init_unit_highlighter()
	self._unit_highlighter = World:unit_manager():unit_highlighter()
	self._unit_highlighter:add_config("highlight", "highlight", "highlight_skinned")
	self._unit_highlighter:set_config_name_filter("highlight", "g_*", "gfx_*")
	self._highlighted_units = {}
end
function Layer:created_units()
	return self._created_units
end
function Layer:selected_units()
	return self._selected_units
end
function Layer:current_pos()
	return self._current_pos
end
function Layer:uses_continents()
	return self._uses_continents
end
function Layer:load(world_holder, offset)
	local world_units = world_holder:create_world("world", self._save_name, offset)
	if world_units then
		for _, unit in ipairs(world_units) do
			if unit:unit_data().unit_id == 0 then
				unit:unit_data().unit_id = self._owner:get_unit_id(unit)
			else
				self._owner:register_unit_id(unit)
			end
			self:set_up_name_id(unit)
			table.insert(self._created_units, unit)
		end
	end
	return world_units
end
function Layer:set_up_name_id(unit)
	if unit:unit_data().name_id == "none" then
		unit:unit_data().name_id = self:get_name_id(unit)
	else
		self:insert_name_id(unit)
	end
end
function Layer:insert_name_id(unit)
	local name = unit:name():s()
	self._name_ids[name] = self._name_ids[name] or {}
	local name_id = unit:unit_data().name_id
	self._name_ids[name][name_id] = (self._name_ids[name][name_id] or 0) + 1
end
function Layer:get_name_id(unit, name)
	local u_name = unit:name():s()
	local start_number = 1
	if name then
		local sub_name = name
		for i = string.len(name), 0, -1 do
			local sub = string.sub(name, i, string.len(name))
			sub_name = string.sub(name, 0, i)
			if tonumber(sub) then
				start_number = tonumber(sub)
			else
				break
			end
		end
		name = sub_name
	else
		local reverse = string.reverse(u_name)
		local i = string.find(reverse, "/")
		name = string.reverse(string.sub(reverse, 0, i - 1))
		name = name .. "_"
	end
	self._name_ids[u_name] = self._name_ids[u_name] or {}
	local t = self._name_ids[u_name]
	for i = start_number, 10000 do
		i = (i < 10 and "00" or i < 100 and "0" or "") .. i
		local name_id = name .. i
		if not t[name_id] then
			t[name_id] = 1
			return name_id
		end
	end
end
function Layer:remove_name_id(unit)
	local unit_name = unit:name():s()
	if self._name_ids[unit_name] then
		local name_id = unit:unit_data().name_id
		self._name_ids[unit_name][name_id] = self._name_ids[unit_name][name_id] - 1
		if self._name_ids[unit_name][name_id] == 0 then
			self._name_ids[unit_name][name_id] = nil
		end
	end
end
function Layer:set_name_id(unit, name_id)
	local unit_name = unit:name():s()
	if self._name_ids[unit_name] then
		self:remove_name_id(unit)
		self._name_ids[unit_name][name_id] = (self._name_ids[unit_name][name_id] or 0) + 1
		unit:unit_data().name_id = name_id
		managers.editor:unit_name_changed(unit)
	end
end
function Layer:widget_affect_object()
	return self._selected_unit
end
function Layer:use_widget_position(pos)
	self:set_unit_positions(pos)
end
function Layer:use_widget_rotation(rot)
	self:set_unit_rotations(rot * self:widget_affect_object():rotation():inverse())
end
function Layer:update(t, dt)
	self:_update_widget_affect_object(t, dt)
	self:_update_drag_select(t, dt)
	self:_update_draw_unit_trigger_sequences(t, dt)
end
function Layer:_update_widget_affect_object(t, dt)
	if alive(self:widget_affect_object()) then
		local widget_pos = managers.editor:world_to_screen(self:widget_affect_object():position())
		if widget_pos.z > 100 then
			widget_pos = widget_pos:with_z(0)
			local widget_screen_pos = widget_pos
			widget_pos = managers.editor:screen_to_world(widget_pos, 1000)
			local widget_rot = self:widget_rot()
			if self._using_widget then
				if self._move_widget:enabled() then
					local result_pos = self._move_widget:calculate(self:widget_affect_object(), widget_rot, widget_pos, widget_screen_pos)
					self:use_widget_position(result_pos)
				end
				if self._rotate_widget:enabled() then
					local result_rot = self._rotate_widget:calculate(self:widget_affect_object(), widget_rot, widget_pos, widget_screen_pos)
					self:use_widget_rotation(result_rot)
				end
			end
			if self._move_widget:enabled() then
				self._move_widget:set_position(widget_pos)
				self._move_widget:set_rotation(widget_rot)
				self._move_widget:update(t, dt)
			end
			if self._rotate_widget:enabled() then
				self._rotate_widget:set_position(widget_pos)
				self._rotate_widget:set_rotation(widget_rot)
				self._rotate_widget:update(t, dt)
			end
		end
	end
end
function Layer:_update_drag_select(t, dt)
	if not self._drag_select then
		return
	end
	local end_pos = managers.editor:cursor_pos()
	if self._polyline then
		local p1 = managers.editor:screen_pos(self._drag_start_pos)
		local p3 = managers.editor:screen_pos(end_pos)
		local p2 = Vector3(p3.x, p1.y, 0)
		local p4 = Vector3(p1.x, p3.y, 0)
		self._polyline:set_points({
			p1,
			p2,
			p3,
			p4
		})
	end
	local len = self._drag_start_pos - end_pos:length()
	if len > 0.05 then
		local top_left = self._drag_start_pos
		local bottom_right = end_pos
		if top_left.y > bottom_right.y and top_left.x < bottom_right.x or top_left.y < bottom_right.y and top_left.x > bottom_right.x then
			top_left = Vector3(self._drag_start_pos.x, end_pos.y, 0)
			bottom_right = Vector3(end_pos.x, self._drag_start_pos.y, 0)
		end
		local units = World:find_units("camera_frustum", managers.editor:camera(), top_left, bottom_right, 500000, self._slot_mask)
		self._drag_units = {}
		local r, g, b = 1, 1, 1
		local brush = Draw:brush()
		if CoreInput.alt() then
			r, g, b = 1, 0, 0
		end
		if CoreInput.ctrl() then
			r, g, b = 0, 1, 0
		end
		brush:set_color(Color(0.15, 0.5 * r, 0.5 * g, 0.5 * b))
		for _, unit in ipairs(units) do
			if self:authorised_unit_type(unit) and managers.editor:select_unit_ok_conditions(unit, self) then
				table.insert(self._drag_units, unit)
				brush:draw(unit)
				Application:draw(unit, r * 0.75, g * 0.75, b * 0.75)
			end
		end
	end
end
function Layer:_update_draw_unit_trigger_sequences(t, dt)
	if alive(self._selected_unit) and self._selected_unit:damage() and not self._selected_unit:mission_element() then
		local trigger_data = self._selected_unit:damage():get_editor_trigger_data()
		if trigger_data and #trigger_data > 0 then
			for _, data in ipairs(trigger_data) do
				if alive(data.notify_unit) then
					Application:draw_line(self._selected_unit:position(), data.notify_unit:position(), 0, 1, 1)
					Application:draw_sphere(data.notify_unit:position(), 50, 0, 1, 1)
					Application:draw(data.notify_unit, 0, 1, 1)
				end
			end
		end
	end
end
function Layer:authorised_unit_type(unit)
	local name = unit:name():s()
	if self._confirmed_unit_types[name] ~= nil then
		return self._confirmed_unit_types[name]
	end
	local u_type = unit:type():s()
	for _, type in ipairs(self._unit_types) do
		if u_type == type then
			self._confirmed_unit_types[name] = true
			return true
		end
	end
	self._confirmed_unit_types[name] = false
	return false
end
function Layer:draw_grid(t, dt)
	if not managers.editor:layer_draw_grid() then
		return
	end
	local rot = Rotation(0, 0, 0)
	if alive(self._selected_unit) and self:local_rot() then
		rot = self._selected_unit:rotation()
	end
	for i = -5, 5 do
		local from_x = self._current_pos + rot:x() * (i * self:grid_size()) - rot:y() * (6 * self:grid_size())
		local to_x = self._current_pos + rot:x() * (i * self:grid_size()) + rot:y() * (6 * self:grid_size())
		Application:draw_line(from_x, to_x, 0, 0.5, 0)
		local from_y = self._current_pos + rot:y() * (i * self:grid_size()) - rot:x() * (6 * self:grid_size())
		local to_y = self._current_pos + rot:y() * (i * self:grid_size()) + rot:x() * (6 * self:grid_size())
		Application:draw_line(from_y, to_y, 0, 0.5, 0)
	end
end
function Layer:update_always(t, dt)
	if not self._layer_enabled then
		for _, unit in ipairs(self._created_units) do
			Application:draw(unit, 0.75, 0.75, 0.75)
		end
	end
end
function Layer:local_rot()
	return managers.editor:is_coordinate_system("Local")
end
function Layer:surface_move()
	return managers.editor:use_surface_move()
end
function Layer:use_snappoints()
	return managers.editor:use_snappoints()
end
function Layer:grid_size()
	return managers.editor:grid_size()
end
function Layer:snap_rotation()
	return managers.editor:snap_rotation()
end
function Layer:snap_rotation_axis()
	return managers.editor:snap_rotation_axis()
end
function Layer:rotation_speed()
	return managers.editor:rotation_speed()
end
function Layer:grid_altitude()
	return managers.editor:grid_altitude()
end
function Layer:build_units(params)
	params = params or {}
	local style = params.style or "LC_REPORT,LC_NO_HEADER,LC_SORT_ASCENDING,LC_SINGLE_SEL"
	local unit_events = params.unit_events or {}
	local notebook_sizer = EWS:BoxSizer("VERTICAL")
	self._notebook = EWS:Notebook(self._ews_panel, "", "NB_TOP,NB_MULTILINE")
	notebook_sizer:add(self._notebook, 1, 0, "EXPAND")
	for c, names in pairs(self._category_map) do
		local panel = EWS:Panel(self._notebook, "", "TAB_TRAVERSAL")
		local units_sizer = EWS:BoxSizer("VERTICAL")
		panel:set_sizer(units_sizer)
		local short_name = EWS:CheckBox(panel, "Short name", "", "ALIGN_LEFT")
		short_name:set_value(true)
		units_sizer:add(short_name, 0, 0, "EXPAND")
		units_sizer:add(EWS:StaticText(panel, "Filter", 0, ""), 0, 0, "ALIGN_CENTER_HORIZONTAL")
		local unit_filter = EWS:TextCtrl(panel, "", "", "TE_CENTRE")
		units_sizer:add(unit_filter, 0, 0, "EXPAND")
		local units = EWS:ListCtrl(panel, "", style)
		units:clear_all()
		units:append_column("Name")
		for name, _ in pairs(names) do
			local i = units:append_item(self:_stripped_unit_name(name))
			units:set_item_data(i, name)
		end
		units:autosize_column(0)
		units_sizer:add(units, 1, 0, "EXPAND")
		short_name:connect("EVT_COMMAND_CHECKBOX_CLICKED", callback(self, self, "toggle_short_name"), {
			filter = unit_filter,
			units = units,
			category = c,
			short_name = short_name
		})
		units:connect("EVT_COMMAND_LIST_ITEM_SELECTED", callback(self, self, "set_unit_name"), units)
		for _, event in ipairs(unit_events) do
			units:connect(event, callback(self, self, "set_unit_name"), units)
		end
		unit_filter:connect("EVT_COMMAND_TEXT_UPDATED", callback(self, self, "update_filter"), {
			filter = unit_filter,
			units = units,
			category = c,
			short_name = short_name
		})
		local page_name = managers.editor:category_name(c)
		self._notebook_units_lists[page_name] = {units = units, filter = unit_filter}
		self._notebook:add_page(panel, page_name, true)
	end
	return notebook_sizer
end
function Layer:_stripped_unit_name(name)
	local reverse = string.reverse(name)
	local i = string.find(reverse, "/")
	name = string.reverse(string.sub(reverse, 0, i - 1))
	return name
end
function Layer:repopulate_units()
	self:load_unit_map_from_vector()
	for c, names in pairs(self._category_map) do
		local data = self._notebook_units_lists[managers.editor:category_name(c)]
		data.units:clear()
		for name, _ in pairs(names) do
			data.units:append(name)
		end
	end
end
function Layer:units_notebook()
	return self._notebook
end
function Layer:notebook_unit_list(name)
	return self._notebook_units_lists[name]
end
function Layer:toggle_short_name(data)
	self:update_filter(data)
end
function Layer:update_filter(data)
	local filter = data.filter:get_value()
	data.units:delete_all_items()
	local unit_map = self._unit_map
	if data.category then
		unit_map = self._category_map[data.category]
	end
	for name, _ in pairs(unit_map) do
		local stripped_name = data.short_name:get_value() and self:_stripped_unit_name(name) or name
		if string.find(stripped_name, filter, 1, true) then
			local i = data.units:append_item(stripped_name)
			data.units:set_item_data(i, name)
		end
	end
	data.units:autosize_column(0)
end
function Layer:build_name_id()
	local sizer = EWS:BoxSizer("HORIZONTAL")
	sizer:add(EWS:StaticText(self._ews_panel, "Name:", 0, ""), 0, 2, "ALIGN_CENTER,RIGHT")
	self._name_id = EWS:TextCtrl(self._ews_panel, "none", "", "TE_CENTRE")
	sizer:add(self._name_id, 1, 0, "EXPAND")
	self._name_id:connect("EVT_COMMAND_TEXT_UPDATED", callback(self, self, "update_name_id"), self._name_id)
	self._sizer:add(sizer, 0, 4, "EXPAND,TOP")
end
function Layer:update_name_id(name_id)
	if self._block_name_id_event then
		self._block_name_id_event = false
		return
	end
	if alive(self._selected_unit) then
		self:set_name_id(self._selected_unit, name_id:get_value())
	end
end
function Layer:cb_toogle(data)
	self[data.value] = data.cb:get_value()
end
function Layer:cb_toogle_trg(data)
	data.cb:set_value(not data.cb:get_value())
	self[data.value] = data.cb:get_value()
end
function Layer:change_combo_box(data)
	self[data.value] = tonumber(data.combobox:get_value())
end
function Layer:change_combo_box_trg(data)
	local next_i
	for i = 1, #self[data.t] do
		if self[data.value] == self[data.t][i] then
			if self:ctrl() then
				if i == 1 then
					next_i = #self[data.t]
				else
					next_i = 1
				end
			elseif self:shift() then
				if i == 1 then
					next_i = #self[data.t]
				else
					next_i = i - 1
				end
			elseif i == #self[data.t] then
				next_i = 1
			else
				next_i = i + 1
			end
		end
	end
	data.combobox:set_value(self[data.t][next_i])
	self[data.value] = tonumber(data.combobox:get_value())
end
function Layer:use_move_widget(value)
	if self._will_use_widgets then
		self._move_widget:set_use(value)
		self._move_widget:set_enabled(alive(self:widget_affect_object()))
		self._rotate_widget:set_enabled(alive(self:widget_affect_object()))
	end
end
function Layer:use_rotate_widget(value)
	if self._will_use_widgets then
		self._rotate_widget:set_use(value)
		self._move_widget:set_enabled(alive(self:widget_affect_object()))
		self._rotate_widget:set_enabled(alive(self:widget_affect_object()))
	end
end
function Layer:unit_types()
	return self._unit_types
end
function Layer:load_unit_map_from_vector(which)
	self._unit_types = which or self._unit_types
	self._unit_map = {}
	self._category_map = {}
	for _, t in pairs(self._unit_types) do
		self._category_map[t] = {}
		for _, unit_name in ipairs(managers.database:list_units_of_type(t)) do
			local unit_data = CoreEngineAccess._editor_unit_data(unit_name:id())
			self._unit_map[unit_name] = unit_data
			self._category_map[t][unit_name] = unit_data
		end
	end
end
function Layer:set_unit_map(map)
	self._unit_map = map
end
function Layer:get_unit_map()
	return self._unit_map
end
function Layer:category_map()
	return self._category_map
end
function Layer:get_layer_name()
	return nil
end
function Layer:cancel_all(ctrlr, event)
	event:skip()
	if EWS:name_to_key_code("K_ESCAPE") == event:key_code() then
		self:ews_replace_unit()
	end
end
function Layer:deselect()
	if not self:condition() then
		self:set_select_unit(nil)
		self:update_unit_settings()
	end
end
function Layer:force_editor_state()
	self._owner:force_editor_state()
end
function Layer:update_unit_settings()
	managers.editor:unit_output(self._selected_unit)
	managers.editor:has_editables(self._selected_unit, self._selected_units)
	self._move_widget:set_enabled(alive(self:widget_affect_object()))
	self._rotate_widget:set_enabled(alive(self:widget_affect_object()))
	if self._name_id then
		self._block_name_id_event = true
		if alive(self._selected_unit) then
			self._name_id:set_value(self._selected_unit:unit_data().name_id)
			self._name_id:set_enabled(true)
		else
			self._name_id:set_enabled(false)
			self._name_id:set_value("-")
		end
	end
	self:set_reference_unit(self._selected_unit)
end
function Layer:activate()
	self:update_unit_settings()
	if alive(self._selected_unit) then
		managers.editor:set_grid_altitude(self._selected_unit:position().z)
	end
	self:use_move_widget(managers.editor:using_move_widget())
	self:use_rotate_widget(managers.editor:using_rotate_widget())
	self:recalc_all_locals()
end
function Layer:deactivate()
	self._drag_units = nil
	self:select_release()
	self._move_widget:set_enabled(false)
end
function Layer:build_panel()
	return nil
end
function Layer:widget_rot()
	local widget_rot = Rotation()
	if self:local_rot() then
		widget_rot = self:widget_affect_object():rotation()
	end
	return widget_rot
end
function Layer:click_widget()
	local from = managers.editor:get_cursor_look_point(0)
	local to = managers.editor:get_cursor_look_point(100000)
	if self._move_widget:enabled() then
		local ray = World:raycast("ray", from, to, "ray_type", "widget", "target_unit", self._move_widget:widget())
		if ray and ray.body then
			if self:shift() then
				self:clone()
			end
			self._move_widget:add_move_widget_axis(ray.body:name():s())
			self._grab = true
			self._grab_info = CoreEditorUtils.GrabInfo:new(self:widget_affect_object())
			self._using_widget = true
			self._move_widget:set_move_widget_offset(self:widget_affect_object(), self:widget_rot())
		end
	end
	if self._rotate_widget:enabled() then
		local ray = World:raycast("ray", from, to, "ray_type", "widget", "target_unit", self._rotate_widget:widget())
		if ray and ray.body then
			if self:shift() then
				self:clone()
			end
			self._rotate_widget:set_rotate_widget_axis(ray.body:name():s())
			managers.editor:set_value_info_visibility(true)
			self._grab = true
			self._grab_info = CoreEditorUtils.GrabInfo:new(self:widget_affect_object())
			self._using_widget = true
			self._rotate_widget:set_world_dir(ray.position)
			self._rotate_widget:set_rotate_widget_start_screen_position(managers.editor:world_to_screen(ray.position):with_z(0))
			self._rotate_widget:set_rotate_widget_unit_rot(self:widget_affect_object():rotation())
		end
	end
end
function Layer:release_widget()
	if self._using_widget then
		self:cloned_group()
		self._grab = false
		if self._selected_unit then
			managers.editor:set_grid_altitude(self._selected_unit:position().z)
		end
		self:reset_widget_values()
	end
end
function Layer:cloned_group()
	if self._clone_create_group then
		self._clone_create_group = false
		managers.editor:group()
	end
end
function Layer:using_widget()
	return self._using_widget
end
function Layer:reset_widget_values()
	self._using_widget = false
	self._move_widget:reset_values()
	self._rotate_widget:reset_values()
	managers.editor:set_value_info_visibility(false)
end
function Layer:prepare_replace(names, rules)
	rules = rules or {}
	local data = {}
	local units = {}
	for _, name in ipairs(names) do
		local slot = CoreEngineAccess._editor_unit_data(name:id()):slot()
		for _, unit in ipairs(World:find_units_quick("disabled", "all", slot)) do
			if unit:name() == name:id() then
				local continent = unit:unit_data().continent
				if not rules.only_current_continent or not continent or managers.editor:current_continent() == continent then
					local unit_params = {
						name = unit:name(),
						continent = continent,
						position = unit:position(),
						rotation = unit:rotation(),
						groups = unit:unit_data().editor_groups
					}
					if unit == self._selected_unit then
						unit_params.reference_unit = true
					elseif table.contains(self._selected_units, unit) then
						unit_params.selected = true
					end
					table.insert(data, unit_params)
					table.insert(units, unit)
				end
			end
		end
	end
	for _, unit in ipairs(units) do
		self:delete_unit(unit)
	end
	return data
end
function Layer:recreate_units(name, data)
	local units_to_select = {}
	local reference_unit
	self._continent_locked_picked = true
	for _, params in ipairs(data) do
		local unit_name = name or params.name:id()
		local continent = params.continent
		local pos = params.position
		local rot = params.rotation
		local new_unit = self:do_spawn_unit(unit_name, pos, rot)
		if continent and new_unit:unit_data().continent ~= continent then
			managers.editor:change_continent_for_unit(new_unit, continent)
		end
		if params.groups then
			for _, group in ipairs(params.groups) do
				group:add_unit(new_unit)
			end
		end
		if params.reference_unit then
			reference_unit = new_unit
		elseif params.selected then
			table.insert(units_to_select, new_unit)
		end
	end
	self._continent_locked_picked = false
	self:set_select_unit(nil)
	self._replacing_units = true
	self:set_select_unit(reference_unit)
	for _, unit in ipairs(units_to_select) do
		self:set_select_unit(unit)
	end
	self._replacing_units = false
end
function Layer:replace_unit(name, all)
	local replace_units = {}
	if all then
		for _, unit in ipairs(World:find_units_quick("all", self._selected_unit:slot())) do
			if unit:name() == self._selected_unit:name() and unit ~= self._selected_unit then
				table.insert(replace_units, unit)
			end
		end
	else
		for _, unit in ipairs(self._selected_units) do
			if unit ~= self._selected_unit then
				table.insert(replace_units, unit)
			end
		end
	end
	table.insert(replace_units, self._selected_unit)
	self:_replace_units(name, replace_units)
end
function Layer:_replace_units(name, replace_units)
	local selected_units = CoreTable.clone(self._selected_units)
	local reference_unit = self._selected_unit
	local units_to_select = {}
	for _, unit in ipairs(replace_units) do
		local continent = unit:unit_data().continent
		if not continent or managers.editor:current_continent() == continent then
			local pos = unit:position()
			local rot = unit:rotation()
			local unit_name = name or unit:name():s()
			local new_unit = self:do_spawn_unit(unit_name, pos, rot)
			if continent and new_unit:unit_data().continent ~= continent then
				managers.editor:change_continent_for_unit(new_unit, continent)
			end
			if unit:unit_data().editor_groups then
				for _, group in ipairs(unit:unit_data().editor_groups) do
					group:add_unit(new_unit)
				end
			end
			if unit == reference_unit then
				reference_unit = new_unit
			elseif table.contains(selected_units, unit) then
				table.insert(units_to_select, new_unit)
			end
			self:delete_unit(unit)
		end
	end
	self:set_select_unit(nil)
	self._replacing_units = true
	self:set_select_unit(reference_unit)
	for _, unit in ipairs(units_to_select) do
		self:set_select_unit(unit)
	end
	self._replacing_units = false
end
function Layer:use_grab_info()
	self:reset_widget_values()
end
function Layer:unit_sampler()
	if not self._grab and not self:condition() then
		local data = {
			mask = managers.slot:get_mask("editor_all"),
			ray_type = "body editor",
			sample = true
		}
		local ray = managers.editor:unit_by_raycast(data)
		if ray and ray.unit then
			local unit_name = ray.unit:name()
			local s = managers.editor:select_unit_name(unit_name)
			managers.editor:output(s)
		end
	end
end
function Layer:ignore_global_select()
	return self._ignore_global_select
end
function Layer:select_unit_authorised(unit)
	return true
end
function Layer:click_select_unit()
	self:set_drag_select()
	managers.editor:click_select_unit(self)
end
function Layer:set_drag_select()
	if self:condition() or self._grab then
		return
	end
	self._drag_select = true
	self._polyline = managers.editor._gui:polyline({
		color = Color(0.5, 1, 1, 1)
	})
	self._polyline:set_closed(true)
	self._drag_start_pos = managers.editor:cursor_pos()
end
function Layer:remove_polyline()
	if self._polyline then
		managers.editor._gui:remove(self._polyline)
		self._polyline = nil
	end
end
function Layer:adding_units()
	return CoreInput.ctrl()
end
function Layer:removing_units()
	return CoreInput.alt()
end
function Layer:adding_or_removing_units()
	return CoreInput.ctrl() or CoreInput.alt()
end
function Layer:select_release()
	self._drag_select = false
	self:remove_polyline()
	if self._drag_units then
		self._selecting_many_units = true
		for _, unit in ipairs(self._drag_units) do
			self:set_select_unit(unit)
		end
		self._selecting_many_units = false
		self:check_referens_exists()
		managers.editor:selected_units(self._selected_units)
		self:update_unit_settings()
	end
	self._drag_units = nil
end
function Layer:add_highlighted_unit(unit, config)
	if not unit then
		return
	end
end
function Layer:remove_highlighted_unit(unit)
end
function Layer:clear_highlighted_units()
	for _, unit in ipairs(self._selected_units) do
		self:remove_highlighted_unit(unit)
	end
end
function Layer:clear_selected_units_table()
	self:clear_highlighted_units()
	self._selected_units = {}
end
function Layer:clear_selected_units()
	self:clear_selected_units_table()
	self:set_reference_unit(nil)
	self:update_unit_settings()
end
function Layer:set_selected_units(units)
	self:clear_selected_units()
	self._selecting_many_units = true
	local id = Profiler:start("call_set_select_unit")
	for _, unit in ipairs(units) do
		self:set_select_unit(unit)
	end
	Profiler:stop(id)
	Profiler:counter_time("call_set_select_unit")
	managers.editor:selected_units(self._selected_units)
	self:update_unit_settings()
	self._selecting_many_units = false
end
function Layer:select_group(group)
	self:clear_highlighted_units()
	self:set_reference_unit(group:reference())
	self._selected_units = CoreTable.clone(group:units())
	for _, unit in ipairs(self._selected_units) do
		self:add_highlighted_unit(unit, "highlight")
	end
	managers.editor:group_selected(group)
	self:recalc_all_locals()
	self:update_unit_settings()
end
function Layer:current_group()
	return self:unit_in_group(self._selected_unit)
end
function Layer:unit_in_group(unit)
	if alive(unit) then
		local groups = unit:unit_data().editor_groups
		if groups then
			for i = #groups, 1, -1 do
				local group = groups[i]
				if group and group:closed() and group:continent() == managers.editor:current_continent() then
					return group
				end
			end
		end
	end
	return nil
end
function Layer:set_select_group(unit)
	if managers.editor:using_groups() and not self._clone_create_group then
		local group = self:unit_in_group(unit)
		local current_group = self:current_group()
		if group then
			local reference = group:reference()
			if CoreInput.alt() then
				if current_group and current_group == group then
					current_group:remove_unit(unit)
					self:remove_select_unit(unit)
				end
			elseif CoreInput.shift() then
				group:set_reference(unit)
			elseif CoreInput.ctrl() then
				if current_group then
					if self:current_group() == group then
						current_group:remove_unit(unit)
						self:remove_select_unit(unit)
					else
						current_group:add_unit(unit)
						self:add_select_unit(unit)
					end
				end
			else
				self:select_group(group)
			end
			if reference ~= group:reference() then
				self:select_group(group)
			end
		elseif CoreInput.ctrl() then
			if current_group then
				current_group:add_unit(unit)
				self:add_select_unit(unit)
			end
		elseif not self._selecting_many_units then
			self:clear_selected_units()
		end
		return true
	end
	return false
end
function Layer:set_select_unit(unit)
	if managers.editor:loading() then
		return
	end
	if self:set_select_group(unit) then
		return
	end
	if self:alt() then
		self:remove_select_unit(unit)
	elseif self:shift() then
		if table.contains(self._selected_units, unit) then
			self:set_reference_unit(unit)
			self:recalc_all_locals()
		else
			self:set_reference_unit(self._selected_unit or unit)
			self:add_select_unit(unit)
		end
	elseif (self:ctrl() or self._selecting_many_units or self._replacing_units) and #self._selected_units > 0 then
		self:add_select_unit(unit)
	else
		self:clear_selected_units_table()
		self:set_reference_unit(unit)
		self:add_highlighted_unit(unit, "highlight")
		table.insert(self._selected_units, unit)
	end
	if not self._selecting_many_units then
		self:check_referens_exists()
	end
	if not self._selecting_many_units then
		managers.editor:on_selected_unit(unit)
		managers.editor:selected_units(self._selected_units)
		self:update_unit_settings()
	end
end
function Layer:add_select_unit(unit)
	if unit then
		if not table.contains(self._selected_units, unit) then
			table.insert(self._selected_units, unit)
			self:add_highlighted_unit(unit, "highlight")
			if self._selected_unit then
				self:recalc_locals(unit, self._selected_unit)
			end
		elseif not self._selecting_many_units then
			table.delete(self._selected_units, unit)
			self:remove_highlighted_unit(unit)
		end
	end
end
function Layer:remove_select_unit(unit)
	if table.contains(self._selected_units, unit) then
		table.delete(self._selected_units, unit)
		self:remove_highlighted_unit(unit)
	end
end
function Layer:check_referens_exists()
	if #self._selected_units > 0 then
		if not table.contains(self._selected_units, self._selected_unit) then
			self:set_reference_unit(self._selected_units[1])
			self:recalc_all_locals()
		end
	else
		self:set_reference_unit(nil)
	end
end
function Layer:set_reference_unit(unit)
	self._selected_unit = unit
	managers.editor:on_reference_unit(self._selected_unit)
end
function Layer:recalc_all_locals()
	if #self._selected_units > 0 and not table.contains(self._selected_units, self._selected_unit) then
		self:set_reference_unit(self._selected_units[1])
	end
	if alive(self._selected_unit) then
		local reference = self._selected_unit
		reference:unit_data().local_pos = Vector3(0, 0, 0)
		reference:unit_data().local_rot = Rotation(0, 0, 0)
		for _, unit in ipairs(self._selected_units) do
			if unit ~= reference then
				self:recalc_locals(unit, reference)
			end
		end
	end
end
function Layer:recalc_locals(unit, reference)
	local pos = reference:position()
	local rot = reference:rotation()
	unit:unit_data().local_pos = unit:unit_data().world_pos - pos:rotate_with(rot:inverse())
	unit:unit_data().local_rot = rot:inverse() * unit:rotation()
end
function Layer:selected_unit()
	return self._selected_unit
end
function Layer:create_unit(name, pos, rot)
	local unit = CoreUnit.safe_spawn_unit(name, pos, rot)
	if self:uses_continents() and managers.editor:current_continent() then
		managers.editor:current_continent():add_unit(unit)
	end
	unit:unit_data().world_pos = pos
	unit:unit_data().unit_id = self._owner:get_unit_id(unit)
	unit:unit_data().name_id = self:get_name_id(unit)
	managers.editor:spawned_unit(unit)
	return unit
end
function Layer:do_spawn_unit(name, pos, rot)
	if managers.editor:current_continent():value("locked") and not self._continent_locked_picked then
		managers.editor:output_warning("Can't create units in continent " .. managers.editor:current_continent():name() .. " because it is locked!")
		return
	end
	if name:s() ~= "" then
		pos = pos or self._current_pos
		rot = rot or Rotation(Vector3(1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, 1))
		local unit = self:create_unit(name, pos, rot)
		self:set_select_unit(unit)
		return unit
	end
end
function Layer:remove_unit(unit)
	table.delete(self._selected_units, unit)
	self:remove_highlighted_unit(unit)
	self:remove_name_id(unit)
	managers.editor:remove_unit_id(unit)
	managers.editor:deleted_unit(unit)
	managers.portal:delete_unit(unit)
	if unit:unit_data().continent then
		unit:unit_data().continent:remove_unit(unit)
	end
	World:delete_unit(unit)
end
function Layer:delete_unit(unit)
	if self._selected_unit == unit then
		self:set_reference_unit(nil)
	end
	table.delete(self._created_units, unit)
	self:remove_unit(unit)
	self:update_unit_settings()
end
function Layer:show_replace_units()
	if self:ctrl() or self:shift() or self:alt() then
		return
	end
	if self._selected_unit then
		managers.editor:show_layer_replace_dialog(self)
	end
end
function Layer:add_triggers()
	local vc = self._editor_data.virtual_controller
	vc:add_trigger(Idstring("lmb"), callback(self, self, "click_widget"))
	vc:add_release_trigger(Idstring("lmb"), callback(self, self, "release_widget"))
	vc:add_trigger(Idstring("deselect"), callback(self, self, "deselect"))
	vc:add_trigger(Idstring("unit_sampler"), callback(self, self, "unit_sampler"))
	vc:add_trigger(Idstring("lmb"), callback(self, self, "click_select_unit"))
	vc:add_release_trigger(Idstring("lmb"), callback(self, self, "select_release"))
	vc:add_trigger(Idstring("clone_edited_values"), callback(self, self, "on_clone_edited_values"))
	vc:add_trigger(Idstring("center_view_on_selected_unit"), callback(self, self, "on_center_view_on_selected_unit"))
end
function Layer:clear_triggers()
	self._editor_data.virtual_controller:clear_triggers()
end
function Layer:get_help(text)
	return text .. "No help Available"
end
function Layer:undo()
	cat_debug("editor", "No undo implemented in current layer")
end
function Layer:clone()
	cat_debug("editor", "No clone implemented in current layer")
end
function Layer:_cloning_done()
end
function Layer:on_center_view_on_selected_unit()
	managers.editor:center_view_on_unit(self:selected_unit())
end
function Layer:on_clone_edited_values()
	if self:ctrl() then
		return
	end
	if self._selected_unit then
		local ray = self._owner:select_unit_by_raycast(managers.slot:get_mask("editor_all"), "body editor")
		if ray and ray.unit then
			if self:shift() then
				self:clone_edited_values(self._selected_unit, ray.unit)
			else
				self:clone_edited_values(ray.unit, self._selected_unit)
			end
			self:update_unit_settings()
		end
	end
end
function Layer:clone_edited_values(unit, source)
	if unit:name() ~= source:name() then
		return
	end
	local lights = CoreEditorUtils.get_editable_lights(source)
	for _, light in ipairs(lights) do
		local new_light = unit:get_object(light:name())
		new_light:set_near_range(light:near_range())
		new_light:set_far_range(light:far_range())
		new_light:set_enable(light:enable())
		new_light:set_color(light:color())
		new_light:set_multiplier(light:multiplier())
		new_light:set_falloff_exponent(light:falloff_exponent())
		new_light:set_spot_angle_start(light:spot_angle_start())
		new_light:set_spot_angle_end(light:spot_angle_end())
		new_light:set_clipping_values(light:clipping_values())
	end
	unit:unit_data().mesh_variation = source:unit_data().mesh_variation
	if unit:unit_data().mesh_variation ~= "default" then
		managers.sequence:run_sequence_simple2(unit:unit_data().mesh_variation, "change_state", unit)
	end
	unit:unit_data().material = source:unit_data().material
	if unit:unit_data().material ~= "default" then
		unit:set_material_config(unit:unit_data().material, true)
	end
	if unit:editable_gui() then
		unit:editable_gui():set_text(source:editable_gui():text())
		unit:editable_gui():set_font_size(source:editable_gui():font_size())
		unit:editable_gui():set_font_color(source:editable_gui():font_color())
	end
end
function Layer:_continent_locked(unit)
	local continent = unit:unit_data().continent
	if not continent then
		return false
	end
	return unit:unit_data().continent:value("locked")
end
function Layer:set_enabled(enabled)
	self._layer_enabled = enabled
	for _, unit in ipairs(self._created_units) do
		if not self:_continent_locked(unit) then
			unit:set_enabled(enabled)
		end
	end
	return true
end
function Layer:hide_all()
	local units_in_layer = self._created_units
	for _, unit in ipairs(units_in_layer) do
		if unit:enabled() then
			managers.editor:set_unit_visible(unit, false)
		end
	end
end
function Layer:unhide_all()
	for _, unit in ipairs(self._created_units) do
		if unit:enabled() then
			managers.editor:set_unit_visible(unit, true)
		end
	end
end
function Layer:clear()
	for _, unit in ipairs(self._created_units) do
		if alive(unit) then
			self:remove_unit(unit)
		end
	end
	self._move_widget:set_enabled(false)
	self:set_reference_unit(nil)
	self:clear_selected_units_table()
	self._created_units = {}
	self._name_ids = {}
	if self._name_id then
		self._name_id:set_value("-")
		self._name_id:set_enabled(false)
	end
end
function Layer:set_unit_name(units)
	local i = units:selected_item()
	if i ~= -1 then
		local name = self:get_real_name(units:get_item_data(i))
		if not CoreEngineAccess._editor_unit_data(name:id()):model_script_data() then
			managers.editor:output("Unit " .. name .. " doesnt have a model or diesel file.")
			units:deselect_index(i)
			self._unit_name = ""
			return
		end
		self._unit_name = name
	end
end
function Layer:get_real_name(name)
	local fs = " %*"
	if string.find(name, fs) then
		local e = string.find(name, fs)
		name = string.sub(name, 1, e - 1)
	end
	return name
end
function Layer:condition()
	return managers.editor:conditions() or self._using_widget
end
function Layer:grab()
	return self._grab
end
function Layer:create_marker()
end
function Layer:use_marker()
end
function Layer:set_unit_rotations()
end
function Layer:set_unit_positions()
end
function Layer:_add_project_save_data(data)
end
function Layer:_add_project_unit_save_data(unit, data)
end
function Layer:save()
	for _, unit in ipairs(self._created_units) do
		local t = {
			entry = self._save_name,
			continent = unit:unit_data().continent and unit:unit_data().continent:name(),
			data = {
				unit_data = CoreEditorSave.save_data_table(unit)
			}
		}
		self:_add_project_unit_save_data(unit, t.data)
		managers.editor:add_save_data(t)
		managers.editor:add_to_world_package({
			category = "units",
			name = unit:name():s(),
			continent = unit:unit_data().continent
		})
		local sequence_files = {}
		self:_get_sequence_file(PackageManager:unit_data(unit:name()), sequence_files)
		for _, file in ipairs(sequence_files) do
			managers.editor:add_to_world_package({
				category = "script_data",
				name = file:s() .. ".sequence_manager",
				continent = unit:unit_data().continent,
				init = true
			})
		end
	end
end
function Layer:_get_sequence_file(unit_data, sequence_files)
	for _, unit_name in ipairs(unit_data:unit_dependencies()) do
		self:_get_sequence_file(PackageManager:unit_data(unit_name), sequence_files)
	end
	table.insert(sequence_files, unit_data:sequence_manager_filename())
end
function Layer:test_spawn(type)
	local pos = Vector3()
	local rot = Rotation()
	local i = 0
	local prow = 20
	local y_pos = 0
	local c_rad = 0
	local row_units = {}
	local max_rad = 0
	local removed = {}
	for name, unit_data in pairs(self._unit_map) do
		if not type or unit_data:type() == Idstring(type) then
			print("Spawning:", name)
			local unit = self:do_spawn_unit(name, pos, rot)
			local bsr = unit:bounding_sphere_radius() * 2
			if bsr > 20000 then
				table.insert(removed, name)
				print("  Removing:", name)
				self:remove_unit(unit)
			else
				max_rad = math.max(max_rad, bsr)
				i = i + 1
				self:set_unit_position(unit, unit:position() + Vector3(bsr / 2, y_pos, 0), Rotation())
				pos = pos + Vector3(bsr, 0, 0)
				table.insert(row_units, unit)
			end
			if math.mod(i, prow) == 0 then
				c_rad = max_rad * 1
				for _, unit in ipairs(row_units) do
				end
				max_rad = 0
				y_pos = y_pos + c_rad
				pos = Vector3()
				row_units = {}
			end
		end
	end
	print("\n")
	for _, name in ipairs(removed) do
		print("Removed", name)
	end
	print("DONE")
end
function Layer:shift()
	return CoreInput.shift()
end
function Layer:ctrl()
	return CoreInput.ctrl()
end
function Layer:alt()
	return CoreInput.alt()
end
