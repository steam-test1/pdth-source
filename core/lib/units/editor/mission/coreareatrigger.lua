core:import("CoreShapeManager")
CoreAreaTriggerUnitElement = CoreAreaTriggerUnitElement or class(MissionElement)
AreaTriggerUnitElement = AreaTriggerUnitElement or class(CoreAreaTriggerUnitElement)
function AreaTriggerUnitElement:init(...)
	CoreAreaTriggerUnitElement.init(self, ...)
end
function CoreAreaTriggerUnitElement:init(unit)
	MissionElement.init(self, unit)
	self._timeline_color = Vector3(1, 1, 0)
	self._brush = Draw:brush()
	self._hed.trigger_times = 1
	self._hed.interval = 0.1
	self._hed.trigger_on = "on_enter"
	self._hed.instigator = managers.mission:default_area_instigator()
	self._hed.width = 500
	self._hed.depth = 500
	self._hed.height = 500
	self._hed.spawn_unit_elements = {}
	self._hed.amount = "1"
	table.insert(self._save_values, "interval")
	table.insert(self._save_values, "trigger_on")
	table.insert(self._save_values, "instigator")
	table.insert(self._save_values, "width")
	table.insert(self._save_values, "depth")
	table.insert(self._save_values, "height")
	table.insert(self._save_values, "spawn_unit_elements")
	table.insert(self._save_values, "amount")
end
function CoreAreaTriggerUnitElement:draw_links(t, dt, selected_unit, all_units)
	MissionElement.draw_links(self, t, dt, selected_unit)
	for _, id in ipairs(self._hed.spawn_unit_elements) do
		local unit = all_units[id]
		local draw = not selected_unit or unit == selected_unit or self._unit == selected_unit
		if draw then
			self:_draw_link({
				from_unit = self._unit,
				to_unit = unit,
				r = 0.75,
				g = 0,
				b = 0
			})
		end
	end
end
function CoreAreaTriggerUnitElement:update_editing()
end
function CoreAreaTriggerUnitElement:add_element()
	local ray = managers.editor:unit_by_raycast({mask = 10, ray_type = "editor"})
	if ray and ray.unit and string.find(ray.unit:name():s(), "point_spawn_unit", 1, true) then
		local id = ray.unit:unit_data().unit_id
		if table.contains(self._hed.spawn_unit_elements, id) then
			table.delete(self._hed.spawn_unit_elements, id)
		else
			table.insert(self._hed.spawn_unit_elements, id)
		end
	end
end
function CoreAreaTriggerUnitElement:remove_links(unit)
	for _, id in ipairs(self._hed.spawn_unit_elements) do
		if id == unit:unit_data().unit_id then
			table.delete(self._hed.spawn_unit_elements, id)
		end
	end
end
function CoreAreaTriggerUnitElement:update_selected(t, dt)
	if self._shape then
		self._shape:draw(t, dt, 1, 1, 1)
	end
end
function CoreAreaTriggerUnitElement:set_shape_property(params)
	self._shape:set_property(params.property, self._hed[params.value])
end
function CoreAreaTriggerUnitElement:add_triggers(vc)
	vc:add_trigger(Idstring("lmb"), callback(self, self, "add_element"))
end
function CoreAreaTriggerUnitElement:_build_panel(panel, panel_sizer)
	self:_create_panel()
	panel = panel or self._panel
	panel_sizer = panel_sizer or self._panel_sizer
	local interval_params = {
		name = "Check interval:",
		value = self._hed.interval,
		panel = panel,
		sizer = panel_sizer,
		tooltip = "Set the check interval for the area, in seconds",
		floats = 2,
		min = 0.01,
		name_proportions = 1,
		ctrlr_proportions = 2
	}
	local interval = CoreEWS.number_controller(interval_params)
	interval:connect("EVT_COMMAND_TEXT_ENTER", callback(self, self, "set_element_data"), {ctrlr = interval, value = "interval"})
	interval:connect("EVT_KILL_FOCUS", callback(self, self, "set_element_data"), {ctrlr = interval, value = "interval"})
	local trigger_types_params = {
		name = "Trigger on:",
		panel = panel,
		sizer = panel_sizer,
		options = {
			"on_enter",
			"on_exit",
			"both",
			"on_empty"
		},
		value = self._hed.trigger_on,
		tooltip = "Select a trigger on type from the combobox",
		name_proportions = 1,
		ctrlr_proportions = 2,
		sorted = false
	}
	local trigger_types = CoreEWS.combobox(trigger_types_params)
	trigger_types:connect("EVT_COMMAND_COMBOBOX_SELECTED", callback(self, self, "set_element_data"), {ctrlr = trigger_types, value = "trigger_on"})
	local instigator_params = {
		name = "Instigator:",
		panel = panel,
		sizer = panel_sizer,
		options = managers.mission:area_instigator_categories(),
		value = self._hed.instigator,
		tooltip = "Select an instigator type for the area",
		name_proportions = 1,
		ctrlr_proportions = 2,
		sorted = false
	}
	local instigator = CoreEWS.combobox(instigator_params)
	instigator:connect("EVT_COMMAND_COMBOBOX_SELECTED", callback(self, self, "set_element_data"), {ctrlr = instigator, value = "instigator"})
	local amount_params = {
		name = "Amount:",
		panel = panel,
		sizer = panel_sizer,
		options = {
			"1",
			"2",
			"3",
			"4",
			"all"
		},
		value = self._hed.amount,
		tooltip = "Select how manu are required to trigger area",
		name_proportions = 1,
		ctrlr_proportions = 2,
		sorted = false
	}
	local amount = CoreEWS.combobox(amount_params)
	amount:connect("EVT_COMMAND_COMBOBOX_SELECTED", callback(self, self, "set_element_data"), {ctrlr = amount, value = "amount"})
	self._shape = CoreShapeManager.ShapeBoxMiddle:new({
		width = self._hed.width,
		depth = self._hed.depth,
		height = self._hed.height
	})
	self._shape:set_unit(self._unit)
	local base_params = {
		panel = panel,
		sizer = panel_sizer,
		floats = 0,
		min = 0,
		name_proportions = 1,
		ctrlr_proportions = 2
	}
	local width_params = clone(base_params)
	width_params.name = "Width[cm]:"
	width_params.value = self._hed.width
	width_params.tooltip = "Set the width for the shape"
	local width = CoreEWS.number_controller(width_params)
	width:connect("EVT_COMMAND_TEXT_ENTER", callback(self, self, "set_element_data"), {ctrlr = width, value = "width"})
	width:connect("EVT_KILL_FOCUS", callback(self, self, "set_element_data"), {ctrlr = width, value = "width"})
	width:connect("EVT_COMMAND_TEXT_ENTER", callback(self, self, "set_shape_property"), {property = "width", value = "width"})
	width:connect("EVT_KILL_FOCUS", callback(self, self, "set_shape_property"), {property = "width", value = "width"})
	local depth_params = clone(base_params)
	depth_params.name = "Depth[cm]:"
	depth_params.value = self._hed.depth
	depth_params.tooltip = "Set the depth for the shape"
	local depth = CoreEWS.number_controller(depth_params)
	depth:connect("EVT_COMMAND_TEXT_ENTER", callback(self, self, "set_element_data"), {ctrlr = depth, value = "depth"})
	depth:connect("EVT_KILL_FOCUS", callback(self, self, "set_element_data"), {ctrlr = depth, value = "depth"})
	depth:connect("EVT_COMMAND_TEXT_ENTER", callback(self, self, "set_shape_property"), {property = "depth", value = "depth"})
	depth:connect("EVT_KILL_FOCUS", callback(self, self, "set_shape_property"), {property = "depth", value = "depth"})
	local height_params = clone(base_params)
	height_params.name = "Height[cm]:"
	height_params.value = self._hed.height
	height_params.tooltip = "Set the height for the shape"
	local height = CoreEWS.number_controller(height_params)
	self._height_params = height_params
	height:connect("EVT_COMMAND_TEXT_ENTER", callback(self, self, "set_element_data"), {ctrlr = height, value = "height"})
	height:connect("EVT_KILL_FOCUS", callback(self, self, "set_element_data"), {ctrlr = height, value = "height"})
	height:connect("EVT_COMMAND_TEXT_ENTER", callback(self, self, "set_shape_property"), {property = "height", value = "height"})
	height:connect("EVT_KILL_FOCUS", callback(self, self, "set_shape_property"), {property = "height", value = "height"})
	self:scale_slider(panel, panel_sizer, width_params, "width", "Width scale:")
	self:scale_slider(panel, panel_sizer, depth_params, "depth", "Depth scale:")
	self:scale_slider(panel, panel_sizer, height_params, "height", "Height scale:")
end
function CoreAreaTriggerUnitElement:scale_slider(panel, sizer, number_ctrlr_params, value, name)
	local slider_sizer = EWS:BoxSizer("HORIZONTAL")
	slider_sizer:add(EWS:StaticText(panel, name, "", "ALIGN_LEFT"), 1, 0, "ALIGN_CENTER_VERTICAL")
	local slider = EWS:Slider(panel, 100, 1, 200, "", "")
	slider_sizer:add(slider, 2, 0, "EXPAND")
	slider:connect("EVT_SCROLL_CHANGED", callback(self, self, "set_size"), {
		ctrlr = slider,
		number_ctrlr_params = number_ctrlr_params,
		value = value
	})
	slider:connect("EVT_SCROLL_THUMBTRACK", callback(self, self, "set_size"), {
		ctrlr = slider,
		number_ctrlr_params = number_ctrlr_params,
		value = value
	})
	slider:connect("EVT_SCROLL_CHANGED", callback(self, self, "size_release"), {
		ctrlr = slider,
		number_ctrlr_params = number_ctrlr_params,
		value = value
	})
	slider:connect("EVT_SCROLL_THUMBRELEASE", callback(self, self, "size_release"), {
		ctrlr = slider,
		number_ctrlr_params = number_ctrlr_params,
		value = value
	})
	sizer:add(slider_sizer, 0, 0, "EXPAND")
end
function CoreAreaTriggerUnitElement:set_size(params)
	local value = self._hed[params.value] * params.ctrlr:get_value() / 100
	self._shape:set_property(params.value, value)
	CoreEWS.change_entered_number(params.number_ctrlr_params, value)
end
function CoreAreaTriggerUnitElement:size_release(params)
	self._hed[params.value] = params.number_ctrlr_params.value
	params.ctrlr:set_value(100)
end
