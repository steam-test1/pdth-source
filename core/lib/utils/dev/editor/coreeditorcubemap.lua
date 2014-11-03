core:import("CoreEditorUtils")
function CoreEditor:create_projection_light(type)
	local lights = {}
	local units = {}
	if type == "all" then
		local s_units = self:layer("Statics"):created_units()
		for _, unit in ipairs(s_units) do
			local light_name = CoreEditorUtils.has_projection_light(unit)
			if light_name then
				table.insert(units, {unit = unit, light_name = light_name})
			end
		end
	elseif type == "selected" and alive(self:selected_unit()) then
		local light_name = CoreEditorUtils.has_projection_light(self:selected_unit())
		if light_name then
			table.insert(units, {
				unit = self:selected_unit(),
				light_name = light_name
			})
		end
	end
	self._saved_all_lights = {}
	for _, light in ipairs(CoreEditorUtils.all_lights()) do
		table.insert(self._saved_all_lights, {
			light = light,
			enabled = light:enable()
		})
	end
	for _, data in ipairs(units) do
		local unit = data.unit
		local light = unit:get_object(Idstring(data.light_name))
		local enabled = light:enable()
		local resolution = unit:unit_data().projection_lights and unit:unit_data().projection_lights[light:name():s()] and unit:unit_data().projection_lights[light:name():s()].x
		resolution = resolution or EditUnitLight.DEFAULT_SHADOW_RESOLUTION
		table.insert(lights, {
			position = light:position(),
			unit = unit,
			light = light,
			enabled = enabled,
			name = "",
			spot = string.find(light:properties(), "spot") and true or false,
			resolution = resolution,
			output_name = unit:unit_data().unit_id
		})
		light:set_enable(false)
	end
	if #lights == 0 then
		return
	end
	for _, data in ipairs(self._saved_all_lights) do
		data.light:set_enable(false)
	end
	self:viewport():vp():set_post_processor_effect("World", Idstring("hdr_post_processor"), Idstring("empty"))
	self:viewport():vp():set_post_processor_effect("World", Idstring("deferred"), Idstring("projection_generation"))
	self:viewport():vp():set_post_processor_effect("World", Idstring("depth_projection"), Idstring("depth_project"))
	local saved_environment = managers.environment_area:default_environment()
	managers.environment_area:set_default_environment("core/environments/default_depthlight")
	self:_create_cube_light({
		cubes = lights,
		simple_postfix = true,
		saved_environment = saved_environment
	})
end
function CoreEditor:_create_cube_light(params)
	if not self._lastdir then
		return
	end
	params.lights = true
	local folder_name = "cube_lights"
	params.source_path = self:create_temp_saves(folder_name) .. "\\"
	self:_make_dir(self._lastdir .. "\\" .. folder_name)
	params.output_path = self._lastdir .. "\\" .. folder_name .. "\\"
	self:create_cube_map(params)
end
function CoreEditor:create_cube_map(params)
	assert(self._vp:push_ref_fov(500))
	self._vp:set_width_mul_enabled(false)
	self._cubemap_params = params
	self._cubes_que = clone(params.cubes)
	if #self._cubes_que == 0 then
		table.insert(self._cubes_que, {
			position = self:camera():position(),
			name = "camera"
		})
	end
	self._saved_camera = {}
	self._saved_camera.aspect_ratio = self:camera():aspect_ratio()
	self._saved_camera.pos = self:camera():position()
	self._saved_camera.rot = self:camera():rotation()
	self._saved_camera.fov = self:camera_fov()
	self._saved_camera.near_range = self:camera():near_range()
	self._saved_camera.far_range = self:camera():far_range()
	self:camera():set_aspect_ratio(1)
	self:camera():set_width_multiplier(1)
	self:set_show_camera_info(false)
	self._layers[self._mission_layer_name]:set_enabled(false)
	self._saved_show_center = self._show_center
	self._show_center = false
	self:on_hide_helper_units(false)
	self._saved_hidden_object = {}
	self._saved_hidden_units = {}
	for name, layer in pairs(self._layers) do
		for _, unit in ipairs(layer:created_units()) do
			if unit:has_material_assigned(Idstring("leveltools")) then
				self:set_unit_visible(unit, true)
				for _, obj in ipairs(unit:get_objects("*")) do
					local match = string.find(obj:name(), "s_", 1, true)
					if not match or match ~= 1 then
						obj:set_visibility(false)
						table.insert(self._saved_hidden_object, obj)
					end
				end
			elseif unit:unit_data().hide_on_projection_light then
				self:set_unit_visible(unit, false)
				table.insert(self._saved_hidden_units, unit)
			end
		end
	end
	if self._current_layer then
		self._current_layer:update_unit_settings()
	end
	if managers.viewport and managers.viewport._sun_flare_effect then
		managers.viewport._sun_flare_effect._sf_panel:hide()
	end
	self:next_cube()
end
function CoreEditor:next_cube()
	if #self._cubes_que > 0 then
		local cube = table.remove(self._cubes_que, 1)
		self:set_camera(cube.position, self._saved_camera.rot)
		local resolution = cube.resolution or 512
		self:_set_appwin_fixed_resolution(Vector3(resolution + 4, resolution + 4, 0))
		local params = {
			done_callback = callback(self, self, "cube_map_done"),
			name = cube.name,
			simple_postfix = self._cubemap_params.simple_postfix,
			source_path = self._cubemap_params.source_path,
			output_path = self._cubemap_params.output_path,
			output_name = cube.output_name,
			unit = cube.unit,
			light = cube.light,
			spot = cube.spot
		}
		self._camera_controller:start_cube_map(params)
		return true
	end
	return false
end
function CoreEditor:cube_map_done()
	if self:next_cube() then
		return
	end
	if self._cubemap_params.saved_environment then
		managers.environment_area:set_default_environment(self._cubemap_params.saved_environment)
	end
	if self._saved_all_lights then
		for _, data in ipairs(self._saved_all_lights) do
			data.light:set_enable(data.enabled)
		end
		self._saved_all_lights = nil
	end
	if self._cubemap_params.lights then
		self:viewport():vp():set_post_processor_effect("World", Idstring("hdr_post_processor"), self._default_post_processor_effect)
		self:viewport():vp():set_post_processor_effect("World", Idstring("deferred"), Idstring("deferred_lighting"))
		self:viewport():vp():set_post_processor_effect("World", Idstring("depth_projection"), Idstring("depth_project_empty"))
		self:_recompile(self._cubemap_params.output_path)
		for _, cube in ipairs(self._cubemap_params.cubes) do
			cube.light:set_enable(cube.enabled)
			local texture_path = managers.database:entry_path(self._cubemap_params.output_path .. cube.output_name)
			cube.light:set_projection_texture(texture_path, not cube.spot)
		end
	end
	self:set_show_camera_info(true)
	self._layers[self._mission_layer_name]:set_enabled(true)
	self._show_center = self._saved_show_center
	self:on_hide_helper_units(true)
	for _, obj in ipairs(self._saved_hidden_object) do
		obj:set_visibility(true)
	end
	for _, unit in ipairs(self._saved_hidden_units) do
		self:set_unit_visible(unit, true)
	end
	if managers.viewport and managers.viewport._sun_flare_effect then
		managers.viewport._sun_flare_effect._sf_panel:show()
	end
	if self._saved_camera then
		self:set_camera(self._saved_camera.pos, self._saved_camera.rot)
		self:set_camera_fov(self._saved_camera.fov)
		self:camera():set_aspect_ratio(self._saved_camera.aspect_ratio)
		self:camera():set_near_range(self._saved_camera.near_range)
		self:camera():set_far_range(self._saved_camera.far_range)
		self._saved_camera = nil
	end
	self:_set_appwin_fixed_resolution(nil)
	self._vp:set_width_mul_enabled(true)
	assert(self._vp:pop_ref_fov())
end
