core:module("CoreEnvironmentLayer")
core:import("CoreStaticLayer")
core:import("CoreEngineAccess")
core:import("CoreEws")
core:import("CoreEditorSave")
EnvironmentLayer = EnvironmentLayer or class(CoreStaticLayer.StaticLayer)
function EnvironmentLayer:init(owner)
	EnvironmentLayer.super.init(self, owner, "environment", {
		"environment"
	}, "environment_layer")
	self._environment_values = {}
	self:reset_environment_values()
	self._wind_pen = Draw:pen("green")
	self._wind_speeds = {}
	table.insert(self._wind_speeds, {
		speed = 0,
		beaufort = 0,
		description = "Calm"
	})
	table.insert(self._wind_speeds, {
		speed = 0.3,
		beaufort = 1,
		description = "Light air"
	})
	table.insert(self._wind_speeds, {
		speed = 1.6,
		beaufort = 2,
		description = "Light breeze"
	})
	table.insert(self._wind_speeds, {
		speed = 3.4,
		beaufort = 3,
		description = "Gentle breeze"
	})
	table.insert(self._wind_speeds, {
		speed = 5.5,
		beaufort = 4,
		description = "Moderate breeze"
	})
	table.insert(self._wind_speeds, {
		speed = 8,
		beaufort = 5,
		description = "Fresh breeze"
	})
	table.insert(self._wind_speeds, {
		speed = 10.8,
		beaufort = 6,
		description = "Strong breeze"
	})
	table.insert(self._wind_speeds, {
		speed = 13.9,
		beaufort = 7,
		description = "Near Gale"
	})
	table.insert(self._wind_speeds, {
		speed = 17.2,
		beaufort = 8,
		description = "Fresh Gale"
	})
	table.insert(self._wind_speeds, {
		speed = 20.8,
		beaufort = 9,
		description = "Strong Gale"
	})
	table.insert(self._wind_speeds, {
		speed = 24.5,
		beaufort = 10,
		description = "Whole storm"
	})
	table.insert(self._wind_speeds, {
		speed = 28.5,
		beaufort = 11,
		description = "Violent storm"
	})
	table.insert(self._wind_speeds, {
		speed = 32.7,
		beaufort = 12,
		description = "Hurricane"
	})
	self._draw_wind = false
	self._wind_speed = 6
	self._wind_speed_variation = 1
	self._environment_area_unit = "core/units/environment_area/environment_area"
	self._effect_unit = "core/units/effect/effect"
	self._cubemap_unit = "core/units/cubemap_gizmo/cubemap_gizmo"
	self._position_as_slot_mask = self._position_as_slot_mask + managers.slot:get_mask("statics")
	self._environment_modifier_id = self._owner:viewport():create_environment_modifier(false, function(interface)
		return self:sky_rotation_modifier(interface)
	end, "sky_orientation")
end
function EnvironmentLayer:get_layer_name()
	return "Environment"
end
function EnvironmentLayer:load(world_holder, offset)
	local environment = world_holder:create_world("world", self._save_name, offset)
	if not self:old_load(environment) then
		self._environment_values = environment.environment_values
		self._environments:set_value(self._environment_values.environment)
		self._sky_rotation:set_value(self._environment_values.sky_rot)
		self:_load_wind(environment.wind)
		self:_load_effects(environment.effects)
		self:_load_environment_areas()
		for _, unit in ipairs(environment.units) do
			self:set_up_name_id(unit)
			self._owner:register_unit_id(unit)
			table.insert(self._created_units, unit)
		end
	end
	self:clear_selected_units()
	return environment
end
function EnvironmentLayer:_load_wind(wind)
	self._wind_rot = Rotation(wind.angle, 0, wind.tilt)
	self._wind_dir_var = wind.angle_var
	self._wind_tilt_var = wind.tilt_var
	self._wind_speed = wind.speed or self._wind_speed
	self._wind_speed_variation = wind.speed_variation or self._wind_speed_variation
	self._wind_ctrls.wind_speed:set_value(self._wind_speed * 10)
	self._wind_ctrls.wind_speed_variation:set_value(self._wind_speed_variation * 10)
	self:update_wind_speed_labels()
	self._wind_ctrls.wind_direction:set_value(wind.angle)
	self._wind_ctrls.wind_variation:set_value(self._wind_dir_var)
	self._wind_ctrls.tilt_angle:set_value(wind.tilt)
	self._wind_ctrls.tilt_variation:set_value(self._wind_tilt_var)
	self:set_wind()
end
function EnvironmentLayer:_load_effects(effects)
	for _, effect in ipairs(effects) do
		local unit = self:do_spawn_unit(self._effect_unit, effect.position, effect.rotation)
		self:play_effect(unit, effect.name)
	end
end
function EnvironmentLayer:_load_environment_areas()
	for _, area in ipairs(managers.environment_area:areas()) do
		local unit = EnvironmentLayer.super.do_spawn_unit(self, self._environment_area_unit, area:position(), area:rotation())
		unit:unit_data().environment_area = area
		unit:unit_data().environment_area:set_unit(unit)
	end
end
function EnvironmentLayer:old_load(environment)
	if not environment._values then
		return false
	end
	for name, value in pairs(environment._values) do
		self._environment_values[name] = value
	end
	self._environments:set_value(self._environment_values.environment)
	self._sky_rotation:set_value(self._environment_values.sky_rot)
	if environment._wind then
		local wind_angle = environment._wind.wind_angle
		local wind_tilt = environment._wind.wind_tilt
		self._wind_rot = Rotation(wind_angle, 0, wind_tilt)
		self._wind_dir_var = environment._wind.wind_dir_var
		self._wind_tilt_var = environment._wind.wind_tilt_var
		self._wind_speed = environment._wind.wind_speed or self._wind_speed
		self._wind_speed_variation = environment._wind.wind_speed_variation or self._wind_speed_variation
		self._wind_ctrls.wind_speed:set_value(self._wind_speed * 10)
		self._wind_ctrls.wind_speed_variation:set_value(self._wind_speed_variation * 10)
		self:update_wind_speed_labels()
		self._wind_ctrls.wind_direction:set_value(wind_angle)
		self._wind_ctrls.wind_variation:set_value(self._wind_dir_var)
		self._wind_ctrls.tilt_angle:set_value(wind_tilt)
		self._wind_ctrls.tilt_variation:set_value(self._wind_tilt_var)
		self:set_wind()
	end
	if environment._unit_effects then
		for _, effect in ipairs(environment._unit_effects) do
			local unit = self:do_spawn_unit(self._effect_unit, effect.pos, effect.rot)
			self:play_effect(unit, effect.name)
		end
	end
	for _, area in ipairs(managers.environment_area:areas()) do
		local unit = EnvironmentLayer.super.do_spawn_unit(self, self._environment_area_unit, area:position(), area:rotation())
		unit:unit_data().environment_area = area
		unit:unit_data().environment_area:set_unit(unit)
	end
	if environment._units then
		for _, unit in ipairs(environment._units) do
			self:set_up_name_id(unit)
			table.insert(self._created_units, unit)
		end
	end
	self:clear_selected_units()
	return environment
end
function EnvironmentLayer:save()
	local effects = {}
	local environment_areas = {}
	local cubemap_gizmos = {}
	for _, unit in ipairs(self._created_units) do
		if unit:name() == Idstring(self._effect_unit) then
			local effect = unit:unit_data().effect or "none"
			table.insert(effects, {
				name = effect,
				position = unit:position(),
				rotation = unit:rotation()
			})
			self:_save_to_world_package("effects", effect)
		elseif unit:name() == Idstring(self._environment_area_unit) then
			local area = unit:unit_data().environment_area
			table.insert(environment_areas, area:save_level_data())
		elseif unit:name() == Idstring(self._cubemap_unit) then
			table.insert(cubemap_gizmos, CoreEditorSave.save_data_table(unit))
		end
	end
	local wind = {
		angle = self._wind_rot:yaw(),
		angle_var = self._wind_dir_var,
		tilt = self._wind_rot:roll(),
		tilt_var = self._wind_tilt_var,
		speed = self._wind_speed,
		speed_variation = self._wind_speed_variation
	}
	local data = {
		environment_values = self._environment_values,
		wind = wind,
		effects = effects,
		environment_areas = environment_areas,
		cubemap_gizmos = cubemap_gizmos
	}
	self:_add_project_save_data(data)
	local t = {
		entry = self._save_name,
		single_data_block = true,
		data = data
	}
	managers.editor:add_save_data(t)
	self:_save_to_world_package("scenes", managers.viewport:first_active_viewport():environment_mixer():internal_output("others", "underlay"))
	self:_save_to_world_package("script_data", self._environment_values.environment .. ".environment")
end
function EnvironmentLayer:_save_to_world_package(category, name)
	if name and name ~= "none" then
		managers.editor:add_to_world_package({category = category, name = name})
	end
end
function EnvironmentLayer:update(t, dt)
	EnvironmentLayer.super.update(self, t, dt)
	if self._draw_wind then
		for i = -0.9, 1.2, 0.3 do
			for j = -0.9, 1.2, 0.3 do
				self:draw_wind(self._owner:screen_to_world(Vector3(j, i, 0), 1000))
			end
		end
	end
	for _, unit in ipairs(self._created_units) do
		if unit:unit_data().current_effect then
			World:effect_manager():move(unit:unit_data().current_effect, unit:position())
			World:effect_manager():rotate(unit:unit_data().current_effect, unit:rotation())
		end
		if unit:name() == Idstring(self._effect_unit) then
			Application:draw(unit, 0, 0, 1)
		end
		if unit:name() == Idstring(self._environment_area_unit) then
			local r, g, b = 0, 0.5, 0.5
			if alive(self._selected_unit) and unit == self._selected_unit then
				r, g, b = 0, 1, 1
			end
			Application:draw(unit, r, g, b)
			unit:unit_data().environment_area:draw(t, dt, r, g, b)
		end
	end
end
function EnvironmentLayer:draw_wind(pos)
	local rot = Rotation(self._wind_rot:yaw(), self._wind_rot:pitch(), self._wind_rot:roll() * -1)
	self._wind_pen:arrow(pos, pos + rot:x() * 300, 0.25)
	self._wind_pen:arc(pos, pos + rot:x() * 100, self._wind_dir_var, rot:z(), 32)
	self._wind_pen:arc(pos, pos + rot:x() * 100, -self._wind_dir_var, rot:z(), 32)
	self._wind_pen:arc(pos, pos + rot:x() * 100, self._wind_tilt_var, rot:y(), 32)
	self._wind_pen:arc(pos, pos + rot:x() * 100, -self._wind_tilt_var, rot:y(), 32)
end
function EnvironmentLayer:build_panel(notebook)
	EnvironmentLayer.super.build_panel(self, notebook)
	cat_print("editor", "EnvironmentLayer:build_panel")
	self._env_panel = EWS:Panel(self._ews_panel, "", "TAB_TRAVERSAL")
	self._env_sizer = EWS:BoxSizer("VERTICAL")
	self._env_panel:set_sizer(self._env_sizer)
	local cubemap_sizer = EWS:StaticBoxSizer(self._env_panel, "HORIZONTAL", "Cubemaps")
	local create_cube_map = EWS:Button(self._env_panel, "Generate all", "", "BU_EXACTFIT,NO_BORDER")
	cubemap_sizer:add(create_cube_map, 1, 5, "EXPAND,TOP,RIGHT")
	create_cube_map:connect("EVT_COMMAND_BUTTON_CLICKED", callback(self, self, "create_cube_map"), "all")
	local create_selected_cube_map = EWS:Button(self._env_panel, "Generate selected", "", "BU_EXACTFIT,NO_BORDER")
	cubemap_sizer:add(create_selected_cube_map, 1, 5, "EXPAND,TOP")
	create_selected_cube_map:connect("EVT_COMMAND_BUTTON_CLICKED", callback(self, self, "create_cube_map"), "selected")
	self._env_sizer:add(cubemap_sizer, 0, 0, "EXPAND")
	self._environment_sizer = EWS:StaticBoxSizer(self._env_panel, "VERTICAL", "Environment")
	local env_dd_sizer = EWS:BoxSizer("HORIZONTAL")
	env_dd_sizer:add(EWS:StaticText(self._env_panel, "Default", 0, ""), 1, 0, "ALIGN_CENTER_VERTICAL")
	self._environments = EWS:ComboBox(self._env_panel, "", "", "CB_DROPDOWN,CB_READONLY")
	local envs = managers.database:list_entries_of_type("environment")
	table.sort(envs)
	for _, env in pairs(envs) do
		self._environments:append(env)
	end
	self._environments:connect("EVT_COMMAND_COMBOBOX_SELECTED", callback(self, self, "change_environment"), self._environments)
	env_dd_sizer:add(self._environments, 2, 0, "EXPAND")
	self._environment_sizer:add(env_dd_sizer, 0, 0, "EXPAND")
	local sky_sizer = EWS:BoxSizer("HORIZONTAL")
	sky_sizer:add(EWS:StaticText(self._env_panel, "Rotation", 0, ""), 1, 0, "ALIGN_CENTER_VERTICAL")
	self._sky_rotation = EWS:Slider(self._env_panel, 0, 0, 360, "", "SL_LABELS")
	self._sky_rotation:connect("EVT_SCROLL_CHANGED", callback(self, self, "change_sky_rotation"), self._sky_rotation)
	self._sky_rotation:connect("EVT_SCROLL_THUMBTRACK", callback(self, self, "change_sky_rotation"), self._sky_rotation)
	sky_sizer:add(self._sky_rotation, 4, 0, "EXPAND")
	self._environment_sizer:add(sky_sizer, 0, 0, "EXPAND")
	self._environment_sizer:add(EWS:StaticLine(self._env_panel, "", "LI_HORIZONTAL"), 0, 0, "EXPAND")
	self._environment_area_ctrls = {}
	local env_area_sizer = EWS:BoxSizer("HORIZONTAL")
	env_area_sizer:add(EWS:StaticText(self._env_panel, "Area:", 0, ""), 2, 0, "ALIGN_CENTER_VERTICAL")
	local environment = EWS:ComboBox(self._env_panel, "", "", "CB_DROPDOWN,CB_READONLY")
	for _, env in pairs(managers.database:list_entries_of_type("environment")) do
		environment:append(env)
	end
	environment:set_value(managers.environment_area:game_default_environment())
	environment:connect("EVT_COMMAND_COMBOBOX_SELECTED", callback(self, self, "set_environment_area"), environment)
	env_area_sizer:add(environment, 3, 0, "EXPAND")
	self._environment_area_ctrls.environment = environment
	self._environment_sizer:add(env_area_sizer, 0, 0, "EXPAND")
	local transition_sizer = EWS:BoxSizer("HORIZONTAL")
	transition_sizer:add(EWS:StaticText(self._env_panel, "Fade Time [sec]: ", "", ""), 2, 0, "ALIGN_CENTER_VERTICAL")
	local transition = EWS:TextCtrl(self._env_panel, "0.10", "", "TE_CENTRE")
	transition_sizer:add(transition, 3, 0, "EXPAND")
	transition:connect("EVT_CHAR", callback(nil, _G, "verify_number"), transition)
	transition:connect("EVT_COMMAND_TEXT_ENTER", callback(self, self, "set_transition_time"), nil)
	transition:connect("EVT_KILL_FOCUS", callback(self, self, "set_transition_time"), nil)
	self._environment_sizer:add(transition_sizer, 0, 0, "EXPAND")
	local permanent_cb = EWS:CheckBox(self._env_panel, "Permanent", "")
	permanent_cb:set_value(false)
	self._environment_sizer:add(permanent_cb, 0, 0, "EXPAND")
	permanent_cb:connect("EVT_COMMAND_CHECKBOX_CLICKED", callback(self, self, "set_permanent"), nil)
	self._environment_area_ctrls.transition_time = transition
	self._environment_area_ctrls.permanent_cb = permanent_cb
	self._env_sizer:add(self._environment_sizer, 0, 0, "EXPAND")
	local wind_sizer = EWS:StaticBoxSizer(self._env_panel, "VERTICAL", "Wind")
	local show_wind_cb = EWS:CheckBox(self._env_panel, "Draw Wind", "")
	show_wind_cb:set_value(self._draw_wind)
	wind_sizer:add(show_wind_cb, 0, 0, "EXPAND")
	show_wind_cb:connect("EVT_COMMAND_CHECKBOX_CLICKED", callback(self, self, "cb_toogle"), {cb = show_wind_cb, value = "_draw_wind"})
	local direction_sizer = EWS:StaticBoxSizer(self._env_panel, "HORIZONTAL", "Direction / Variation")
	local wind_direction = EWS:Slider(self._env_panel, 0, 0, 360, "", "")
	wind_direction:connect("EVT_SCROLL_CHANGED", callback(self, self, "update_wind_direction"), wind_direction)
	wind_direction:connect("EVT_SCROLL_THUMBTRACK", callback(self, self, "update_wind_direction"), wind_direction)
	direction_sizer:add(wind_direction, 2, 0, "EXPAND")
	local wind_variation = EWS:SpinCtrl(self._env_panel, 0, "", "")
	wind_variation:set_range(0, 180)
	wind_variation:connect("EVT_SCROLL_THUMBTRACK", callback(self, self, "update_wind_variation"), wind_variation)
	wind_variation:connect("EVT_COMMAND_TEXT_UPDATED", callback(self, self, "update_wind_variation"), wind_variation)
	direction_sizer:add(wind_variation, 1, 0, "EXPAND")
	wind_sizer:add(direction_sizer, 0, 0, "EXPAND")
	local tilt_sizer = EWS:StaticBoxSizer(self._env_panel, "HORIZONTAL", "Tilt / Variation")
	local tilt_angle = EWS:Slider(self._env_panel, 0, -90, 90, "", "")
	tilt_angle:connect("EVT_SCROLL_CHANGED", callback(self, self, "update_tilt_angle"), tilt_angle)
	tilt_angle:connect("EVT_SCROLL_THUMBTRACK", callback(self, self, "update_tilt_angle"), tilt_angle)
	tilt_sizer:add(tilt_angle, 2, 0, "EXPAND")
	local tilt_variation = EWS:SpinCtrl(self._env_panel, 0, "", "")
	tilt_variation:set_range(-90, 90)
	tilt_variation:connect("EVT_SCROLL_THUMBTRACK", callback(self, self, "update_tilt_variation"), tilt_variation)
	tilt_variation:connect("EVT_COMMAND_TEXT_UPDATED", callback(self, self, "update_tilt_variation"), tilt_variation)
	tilt_sizer:add(tilt_variation, 1, 0, "EXPAND")
	wind_sizer:add(tilt_sizer, 0, 0, "EXPAND")
	local speed_sizer = EWS:StaticBoxSizer(self._env_panel, "VERTICAL", "Speed / Variation")
	local speed_help_sizer = EWS:BoxSizer("HORIZONTAL")
	self._speed_text = EWS:StaticText(self._env_panel, self._wind_speed .. " m/s", 0, "")
	self._speed_beaufort = EWS:StaticText(self._env_panel, "Beaufort: " .. self:wind_beaufort(self._wind_speed), 0, "")
	self._speed_description = EWS:StaticText(self._env_panel, self:wind_description(self._wind_speed), 0, "")
	self._speed_text:set_font_size(9)
	self._speed_beaufort:set_font_size(9)
	self._speed_description:set_font_size(9)
	speed_help_sizer:add(self._speed_description, 4, 0, "EXPAND")
	speed_help_sizer:add(self._speed_beaufort, 3, 0, "EXPAND")
	local wind_speed_help = EWS:BitmapButton(self._env_panel, CoreEws.image_path("toolbar\\help_16x16.png"), "", "NO_BORDER")
	wind_speed_help:set_tool_tip("Wind speed references.")
	wind_speed_help:connect("EVT_COMMAND_BUTTON_CLICKED", callback(self, self, "on_wind_speed_help"), nil)
	speed_help_sizer:add(wind_speed_help, 0, 0, "EXPAND")
	speed_sizer:add(speed_help_sizer, 0, 0, "EXPAND")
	local wind_speed_sizer = EWS:BoxSizer("HORIZONTAL")
	local wind_speed = EWS:Slider(self._env_panel, self._wind_speed * 10, 0, 408, "", "")
	wind_speed:set_tool_tip("Wind speed [m/s]")
	wind_speed:connect("EVT_SCROLL_CHANGED", callback(self, self, "update_wind_speed"), wind_speed)
	wind_speed:connect("EVT_SCROLL_THUMBTRACK", callback(self, self, "update_wind_speed"), wind_speed)
	wind_speed_sizer:add(wind_speed, 10, 5, "EXPAND,RIGHT")
	wind_speed_sizer:add(self._speed_text, 3, 0, "EXPAND,ALIGN_CENTER_VERTICAL")
	speed_sizer:add(wind_speed_sizer, 0, 0, "EXPAND")
	local wind_speed_variation_sizer = EWS:BoxSizer("HORIZONTAL")
	local wind_speed_variation = EWS:Slider(self._env_panel, self._wind_speed_variation * 10, 0, 408, "", "")
	wind_speed_variation:set_tool_tip("Wind speed variation [m/s]")
	wind_speed_variation:connect("EVT_SCROLL_CHANGED", callback(self, self, "update_wind_speed_variation"), wind_speed_variation)
	wind_speed_variation:connect("EVT_SCROLL_THUMBTRACK", callback(self, self, "update_wind_speed_variation"), wind_speed_variation)
	wind_speed_variation_sizer:add(wind_speed_variation, 10, 5, "EXPAND,RIGHT")
	self._speed_variation_text = EWS:StaticText(self._env_panel, self._wind_speed_variation .. " m/s", 0, "")
	self._speed_variation_text:set_font_size(9)
	wind_speed_variation_sizer:add(self._speed_variation_text, 3, 0, "EXPAND,ALIGN_CENTER_VERTICAL")
	speed_sizer:add(wind_speed_variation_sizer, 0, 0, "EXPAND")
	wind_sizer:add(speed_sizer, 0, 0, "EXPAND")
	self._env_sizer:add(wind_sizer, 0, 0, "EXPAND")
	self._wind_ctrls = {}
	self._wind_ctrls.wind_direction = wind_direction
	self._wind_ctrls.wind_variation = wind_variation
	self._wind_ctrls.tilt_angle = tilt_angle
	self._wind_ctrls.tilt_variation = tilt_variation
	self._wind_ctrls.wind_speed = wind_speed
	self._wind_ctrls.wind_speed_variation = wind_speed_variation
	local unit_effect_sizer = EWS:BoxSizer("HORIZONTAL")
	unit_effect_sizer:add(EWS:StaticText(self._env_panel, "Effect", 0, ""), 1, 5, "EXPAND,ALIGN_CENTER_VERTICAL,TOP")
	self._unit_effects = EWS:ComboBox(self._env_panel, "", "", "CB_DROPDOWN,CB_READONLY")
	self:populate_unit_effects()
	self._unit_effects:connect("EVT_COMMAND_COMBOBOX_SELECTED", callback(self, self, "change_unit_effect"), nil)
	unit_effect_sizer:add(self._unit_effects, 4, 0, "EXPAND")
	local reload_effects = EWS:BitmapButton(self._env_panel, CoreEws.image_path("world_editor\\reload_unit_effects.png"), "", "NO_BORDER")
	reload_effects:set_tool_tip("Repopulate combo box with effects from the database.")
	reload_effects:connect("EVT_COMMAND_BUTTON_CLICKED", callback(self, self, "populate_unit_effects"), nil)
	unit_effect_sizer:add(reload_effects, 0, 5, "EXPAND,LEFT")
	self._env_sizer:add(unit_effect_sizer, 0, 0, "EXPAND")
	self._sizer:add(self._env_panel, 4, 0, "EXPAND")
	return self._ews_panel
end
function EnvironmentLayer:populate_unit_effects()
	self._unit_effects:clear()
	self._unit_effects:append("none")
	for _, name in ipairs(managers.database:list_entries_of_type("effect")) do
		if string.match(name, "scene_") then
			self._unit_effects:append(name)
		end
	end
	self._unit_effects:set_value("none")
	self:update_unit_settings()
end
function EnvironmentLayer:create_cube_map(type)
	local cubes = {}
	if type == "all" then
		for _, unit in ipairs(self._created_units) do
			if unit:name() == Idstring(self._cubemap_unit) then
				table.insert(cubes, {
					position = unit:position(),
					name = unit:unit_data().name_id,
					output_name = "outputcube"
				})
			end
		end
	elseif type == "selected" and self._selected_unit:name() == Idstring(self._cubemap_unit) then
		table.insert(cubes, {
			position = self._selected_unit:position(),
			name = self._selected_unit:unit_data().name_id,
			output_name = "outputcube"
		})
	end
	local params = {cubes = cubes}
	params.output_path = managers.database:base_path() .. "environments\\cubemaps\\"
	managers.editor:create_cube_map(params)
end
function EnvironmentLayer:change_environment(ctrlr)
	self._environment_values.environment = ctrlr:get_value()
	managers.environment_area:set_default_environment(self._environment_values.environment)
end
function EnvironmentLayer:set_environment_area()
	local area = self._selected_unit:unit_data().environment_area
	area:set_environment(self._environment_area_ctrls.environment:get_value())
end
function EnvironmentLayer:set_permanent()
	local area = self._selected_unit:unit_data().environment_area
	area:set_permanent(self._environment_area_ctrls.permanent_cb:get_value())
end
function EnvironmentLayer:set_transition_time()
	local area = self._selected_unit:unit_data().environment_area
	local value = tonumber(self._environment_area_ctrls.transition_time:get_value())
	value = math.clamp(value, 0, 100000000)
	self._environment_area_ctrls.transition_time:change_value(string.format("%.2f", value))
	area:set_transition_time(value)
end
function EnvironmentLayer:update_wind_direction(wind_direction)
	local dir = wind_direction:get_value()
	self._wind_rot = Rotation(dir, 0, self._wind_rot:roll())
	self:set_wind()
end
function EnvironmentLayer:set_wind()
	Wind:set_direction(self._wind_rot:yaw(), self._wind_dir_var, 5)
	Wind:set_tilt(self._wind_rot:roll(), self._wind_tilt_var, 5)
	Wind:set_speed_m_s(self._wind_speed, self._wind_speed_variation, 5)
	Wind:set_enabled(true)
end
function EnvironmentLayer:update_wind_variation(wind_variation)
	self._wind_dir_var = wind_variation:get_value()
	self:set_wind()
end
function EnvironmentLayer:update_tilt_angle(tilt_angle)
	local dir = tilt_angle:get_value()
	self._wind_rot = Rotation(self._wind_rot:yaw(), 0, dir)
	self:set_wind()
end
function EnvironmentLayer:update_tilt_variation(tilt_variation)
	self._wind_tilt_var = tilt_variation:get_value()
	self:set_wind()
end
function EnvironmentLayer:on_wind_speed_help()
	EWS:launch_url("http://en.wikipedia.org/wiki/Beaufort_scale")
end
function EnvironmentLayer:update_wind_speed(wind_speed)
	self._wind_speed = wind_speed:get_value() / 10
	self:update_wind_speed_labels()
	self:set_wind()
end
function EnvironmentLayer:update_wind_speed_variation(wind_speed_variation)
	self._wind_speed_variation = wind_speed_variation:get_value() / 10
	self:update_wind_speed_labels()
	self:set_wind()
end
function EnvironmentLayer:update_wind_speed_labels()
	self._speed_text:set_value(string.format("%.3g", self._wind_speed) .. " m/s")
	self._speed_beaufort:set_value("Beaufort: " .. self:wind_beaufort(self._wind_speed))
	self._speed_description:set_value(self:wind_description(self._wind_speed))
	self._speed_variation_text:set_value(string.format("%.3g", self._wind_speed_variation) .. " m/s")
end
function EnvironmentLayer:sky_rotation_modifier(interface)
	return self._environment_values.sky_rot
end
function EnvironmentLayer:change_sky_rotation(ctrlr)
	self._environment_values.sky_rot = ctrlr:get_value()
	self._owner:viewport():feed_params()
end
function EnvironmentLayer:unit_ok(unit)
	return unit:name() == Idstring(self._effect_unit) or unit:name() == Idstring(self._cubemap_unit) or unit:name() == Idstring(self._environment_area_unit)
end
function EnvironmentLayer:do_spawn_unit(...)
	local unit = EnvironmentLayer.super.do_spawn_unit(self, ...)
	if alive(unit) and unit:name() == Idstring(self._environment_area_unit) then
		if not unit:unit_data().environment_area then
			unit:unit_data().environment_area = managers.environment_area:add_area({})
			unit:unit_data().environment_area:set_unit(unit)
			self._current_shape_panel = unit:unit_data().environment_area:panel(self._env_panel, self._environment_sizer)
		end
		self:set_environment_area_parameters()
	end
	return unit
end
function EnvironmentLayer:clone_edited_values(unit, source)
	EnvironmentLayer.super.clone_edited_values(self, unit, source)
	if unit:name() == Idstring(self._environment_area_unit) then
		local area = unit:unit_data().environment_area
		local source_area = source:unit_data().environment_area
		area:set_environment(source_area:environment())
		area:set_permanent(source_area:permanent())
		area:set_property("width", source_area:property("width"))
		area:set_property("depth", source_area:property("depth"))
		area:set_property("height", source_area:property("height"))
	end
	if unit:name() == Idstring(self._effect_unit) then
		self:play_effect(unit, source:unit_data().effect)
	end
end
function EnvironmentLayer:delete_unit(unit)
	self:kill_effect(unit)
	if unit:name() == Idstring(self._environment_area_unit) then
		managers.environment_area:remove_area(unit:unit_data().environment_area)
		if unit:unit_data().environment_area:panel() then
			if self._current_shape_panel == unit:unit_data().environment_area:panel() then
				self._current_shape_panel = nil
			end
			unit:unit_data().environment_area:panel():destroy()
			self._env_panel:layout()
		end
	end
	EnvironmentLayer.super.delete_unit(self, unit)
end
function EnvironmentLayer:play_effect(unit, effect)
	unit:unit_data().effect = effect
	if DB:has("effect", effect) then
		CoreEngineAccess._editor_load(Idstring("effect"), effect:id())
		unit:unit_data().current_effect = World:effect_manager():spawn({
			effect = Idstring(effect),
			position = unit:position(),
			rotation = unit:rotation()
		})
	end
end
function EnvironmentLayer:kill_effect(unit)
	if unit:name() == Idstring(self._effect_unit) and unit:unit_data().current_effect then
		World:effect_manager():kill(unit:unit_data().current_effect)
		unit:unit_data().current_effect = nil
	end
end
function EnvironmentLayer:change_unit_effect()
	self:kill_effect(self._selected_unit)
	self:play_effect(self._selected_unit, self._unit_effects:get_value())
end
function EnvironmentLayer:update_unit_settings()
	EnvironmentLayer.super.update_unit_settings(self)
	self._unit_effects:set_enabled(false)
	if alive(self._selected_unit) and self._selected_unit:name() == Idstring(self._effect_unit) then
		self._unit_effects:set_enabled(true)
		self._unit_effects:set_value(self._selected_unit:unit_data().effect or "none")
	end
	self:set_environment_area_parameters()
end
function EnvironmentLayer:set_environment_area_parameters()
	self._environment_area_ctrls.environment:set_enabled(false)
	self._environment_area_ctrls.permanent_cb:set_enabled(false)
	self._environment_area_ctrls.transition_time:set_enabled(false)
	if self._current_shape_panel then
		self._current_shape_panel:set_visible(false)
	end
	if alive(self._selected_unit) and self._selected_unit:name() == Idstring(self._environment_area_unit) then
		local area = self._selected_unit:unit_data().environment_area
		if area then
			self._current_shape_panel = area:panel(self._env_panel, self._environment_sizer)
			self._current_shape_panel:set_visible(true)
			self._environment_area_ctrls.environment:set_enabled(true)
			self._environment_area_ctrls.environment:set_value(area:environment())
			self._environment_area_ctrls.permanent_cb:set_enabled(true)
			self._environment_area_ctrls.permanent_cb:set_value(area:permanent())
			self._environment_area_ctrls.transition_time:set_enabled(true)
			self._environment_area_ctrls.transition_time:set_value(string.format("%.2f", area:transition_time()))
		end
	end
	self._env_panel:layout()
	self._ews_panel:fit_inside()
	self._ews_panel:refresh()
end
function EnvironmentLayer:wind_description(speed)
	local description
	for _, data in ipairs(self._wind_speeds) do
		if speed < data.speed then
			return description
		end
		description = data.description
	end
	return description
end
function EnvironmentLayer:wind_beaufort(speed)
	local beaufort
	for _, data in ipairs(self._wind_speeds) do
		if speed < data.speed then
			return beaufort
		end
		beaufort = data.beaufort
	end
	return beaufort
end
function EnvironmentLayer:reset_environment_values()
	self._environment_values.environment = managers.environment_area:game_default_environment()
	self._environment_values.sky_rot = 0
end
function EnvironmentLayer:clear()
	managers.environment_area:set_to_default()
	self:reset_environment_values()
	managers.environment_area:set_default_environment(self._environment_values.environment)
	self._environments:set_value(self._environment_values.environment)
	self._sky_rotation:set_value(self._environment_values.sky_rot)
	self._wind_rot = Rotation(0, 0, 0)
	self._wind_dir_var = 0
	self._wind_tilt_var = 0
	self._wind_speed = 6
	self._wind_speed_variation = 1
	self._wind_ctrls.wind_speed:set_value(self._wind_speed * 10)
	self._wind_ctrls.wind_speed_variation:set_value(self._wind_speed_variation * 10)
	self:update_wind_speed_labels()
	self._wind_ctrls.wind_direction:set_value(0)
	self._wind_ctrls.wind_variation:set_value(0)
	self._wind_ctrls.tilt_angle:set_value(0)
	self._wind_ctrls.tilt_variation:set_value(0)
	self:set_wind()
	for _, unit in ipairs(self._created_units) do
		self:kill_effect(unit)
		if unit:name() == Idstring(self._environment_area_unit) then
			managers.environment_area:remove_area(unit:unit_data().environment_area)
		end
	end
	EnvironmentLayer.super.clear(self)
	self:set_environment_area_parameters()
end
function EnvironmentLayer:add_triggers()
	EnvironmentLayer.super.add_triggers(self)
end
function EnvironmentLayer:clear_triggers()
	self._editor_data.virtual_controller:clear_triggers()
end
