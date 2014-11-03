core:module("CoreEnvironmentMixer")
core:import("CoreClass")
core:import("CoreEnvironmentData")
core:import("CoreEnvironmentHandle")
core:import("CoreEnvironmentDebugInterface")
core:import("CoreEnvironmentSkyOrientationInterface")
core:import("CoreEnvironmentRadialBlurInterface")
core:import("CoreEnvironmentFogInterface")
core:import("CoreEnvironmentDOFInterface")
core:import("CoreEnvironmentDOFSharedInterface")
core:import("CoreEnvironmentShadowInterface")
core:import("CoreEnvironmentShadowSharedInterface")
EnvironmentMixer = EnvironmentMixer or CoreClass.class()
function EnvironmentMixer:set_environment(name, blend_time)
	if not blend_time or blend_time == 0 then
		self._from_env = self._cache:load_environment(name)
		self._target_env = self._cache:copy_environment(name)
	else
		self._from_env = self._to_env
	end
	self._blend = 0
	self._blend_time = blend_time or 0
	self._to_env = self._cache:load_environment(name)
	self._feed_params = 3
end
function EnvironmentMixer:current_environment()
	if self:is_mixing() then
		return self._from_env:name(), self._to_env:name(), self._scale
	else
		return self._to_env:name()
	end
end
function EnvironmentMixer:is_mixing()
	return self._is_mixing or false
end
function EnvironmentMixer:create_modifier(full_control, interface_name, func)
	return self:_create_modifier(full_control, interface_name, func)
end
function EnvironmentMixer:modifier_owner(interface_name)
	local interface = self._interfaces[interface_name]
	if interface then
		local handle_name = self:_create_handle_name_from_params(unpack(interface.DATA_PATH))
		local handle = self._full_control_handles[handle_name] or self._part_control_handles[handle_name] or self._cache:shared_handle(nil, handle_name)
		if handle then
			return handle:traceback()
		else
			Application:error("[EnvironmentMixer] No modifier created!")
		end
	else
		Application:error("[EnvironmentMixer] No interface with name: " .. interface_name)
	end
end
function EnvironmentMixer:destroy_modifier(id)
	local handle = self._full_control_handles[id] or self._part_control_handles[id]
	if not handle then
		self._cache:destroy_shared_handle(id)
		return
	end
	self._full_control_handles[id] = nil
	self._part_control_handles[id] = nil
end
function EnvironmentMixer:modifier_interface_names()
	local t = {}
	for name, _ in pairs(self._interfaces) do
		table.insert(t, name)
	end
	return unpack(t)
end
function EnvironmentMixer:static_parameters(env_name, ...)
	local env = self._cache:load_environment(env_name)
	return env:parameter_block(...)
end
function EnvironmentMixer:init(cache, name)
	self._cache = cache
	self._target_env = self._cache:copy_environment(name)
	self:set_environment(name)
	self._full_control_handles = {}
	self._part_control_handles = {}
	self._ref_fov_stack = {}
	self._interfaces = {
		debug = CoreEnvironmentDebugInterface.EnvironmentDebugInterface,
		sky_orientation = CoreEnvironmentSkyOrientationInterface.EnvironmentSkyOrientationInterface,
		radial_blur = CoreEnvironmentRadialBlurInterface.EnvironmentRadialBlurInterface,
		fog = CoreEnvironmentFogInterface.EnvironmentFogInterface,
		dof = CoreEnvironmentDOFInterface.EnvironmentDOFInterface,
		shared_dof = CoreEnvironmentDOFSharedInterface.EnvironmentDOFSharedInterface,
		shadow = CoreEnvironmentShadowInterface.EnvironmentShadowInterface,
		shared_shadow = CoreEnvironmentShadowSharedInterface.EnvironmentShadowSharedInterface
	}
	self._visualization_modes = {
		"glossiness_visualization",
		"specular_visualization",
		"normal_visualization",
		"albedo_visualization",
		"deferred_lighting",
		"depth_visualization"
	}
end
function EnvironmentMixer:internal_push_ref_fov(fov, vp, scene)
	if fov < math.rad(vp:camera() and vp:camera():fov()) then
		return false
	end
	local sh_pro = vp:get_post_processor_effect(scene, Idstring("shadow_processor"), Idstring("shadow_rendering"))
	if sh_pro then
		local sh_mod = sh_pro:modifier(Idstring("shadow_modifier"))
		if sh_mod then
			table.insert(self._ref_fov_stack, sh_mod:reference_fov())
			sh_mod:set_reference_fov(math.rad(fov))
			return true
		end
	end
	return false
end
function EnvironmentMixer:internal_pop_ref_fov(vp, scene)
	local sh_pro = vp:get_post_processor_effect(scene, Idstring("shadow_processor"), Idstring("shadow_rendering"))
	if sh_pro then
		local sh_mod = sh_pro:modifier(Idstring("shadow_modifier"))
		if sh_mod and #self._ref_fov_stack > 0 then
			local last = self._ref_fov_stack[#self._ref_fov_stack]
			if not vp:camera() or last >= math.rad(vp:camera():fov()) then
				sh_mod:set_reference_fov(self._ref_fov_stack[#self._ref_fov_stack])
				table.remove(self._ref_fov_stack, #self._ref_fov_stack)
				return true
			end
		end
	end
	return false
end
function EnvironmentMixer:internal_ref_fov(vp, scene)
	local fov = -1
	local sh_pro = vp:get_post_processor_effect(scene, Idstring("shadow_processor"), Idstring("shadow_rendering"))
	if sh_pro then
		local sh_mod = sh_pro:modifier(Idstring("shadow_modifier"))
		if sh_mod then
			fov = math.deg(sh_mod:reference_fov())
		end
	end
	return fov
end
function EnvironmentMixer:internal_set_visualization_mode(effect_name, vp, scene)
	if table.contains(self._visualization_modes, effect_name) then
		if effect_name == "deferred_lighting" then
			vp:set_post_processor_effect(scene, Idstring("tonemapper"), Idstring("tonemap")):set_visibility(true)
		else
			vp:set_post_processor_effect(scene, Idstring("tonemapper"), Idstring("tonemap_disable")):set_visibility(true)
		end
		vp:set_post_processor_effect(scene, Idstring("hdr_post_processor"), Idstring("empty")):set_visibility(effect_name == "deferred_lighting")
		vp:set_post_processor_effect(scene, Idstring("deferred"), Idstring(effect_name)):set_visibility(true)
	else
		local error_msg = "[EnvironmentMixer] " .. effect_name .. " is not a valid visualization mode! Available modes are:"
		for _, mode in ipairs({
			self:internal_visualization_modes()
		}) do
			error_msg = error_msg .. "\t" .. mode
		end
		Application:error(error_msg)
	end
end
function EnvironmentMixer:internal_visualization_modes()
	return unpack(self._visualization_modes)
end
function EnvironmentMixer:set_feed_params()
	self._feed_params = 1
end
function EnvironmentMixer:internal_update(nr, t, dt)
	local id = Profiler:start("Environment Mixer")
	local return_value = self._feed_params and true
	if self._feed_params then
		self._target_env:for_each(function(block, ...)
			self:_process_block(nr == 1, block, ...)
		end)
		self._feed_params = self._feed_params - 1
		if self._feed_params <= 0 then
			self._feed_params = nil
		end
		managers.environment_controller:feed_params()
	end
	Profiler:stop(id)
	return return_value
end
function EnvironmentMixer:internal_output(...)
	return select("#", ...) > 0 and self._target_env:parameter_block(...) or self._target_env
end
function EnvironmentMixer:_create_modifier(full_control, interface_name, func, shared, ...)
	local interface = assert(self._interfaces[interface_name], "[EnvironmentMixer] Could not find interface with name: " .. interface_name)
	if not interface.DATA_PATH then
		local path = {
			...
		}
	end
	local is_shared = interface.SHARED or shared
	local name = self:_create_handle_name_from_params(unpack(path))
	local handle = self:_get_handle_by_name(name) or self._cache:shared_handle(nil, name)
	if not handle then
		handle = CoreEnvironmentHandle.EnvironmentHandle:new(self, interface, full_control, func, name, is_shared, unpack(path))
		if is_shared then
			self._cache:set_shared_handle(full_control, name, handle)
		elseif full_control then
			self._full_control_handles[name] = handle
		else
			self._part_control_handles[name] = handle
		end
	end
	return name
end
function EnvironmentMixer:_get_handle_by_params(...)
	local handle_name = self:_create_handle_name_from_params(...)
	return self:_get_handle_by_name(handle_name)
end
function EnvironmentMixer:_get_handle_by_name(name)
	for _, handle in pairs(self._full_control_handles) do
		if handle:name() == name then
			return handle
		end
	end
	for _, handle in pairs(self._part_control_handles) do
		if handle:name() == name then
			return handle
		end
	end
end
function EnvironmentMixer:_process_block(first_mixer, block, ...)
	local handle_name = self:_create_handle_name_from_params(...)
	local handle = first_mixer and (self._full_control_handles[handle_name] or self._cache:shared_handle(true, handle_name)) or self._full_control_handles[handle_name]
	if handle then
		self._target_env:set_parameter_block(handle:do_callback(), ...)
		return
	end
	if self:is_mixing() then
		self:_do_mix(block, ...)
	end
	handle = first_mixer and (self._part_control_handles[handle_name] or self._cache:shared_handle(false, handle_name)) or self._part_control_handles[handle_name]
	if handle then
		self._target_env:set_parameter_block(handle:do_callback(), ...)
	end
end
function EnvironmentMixer:_create_handle_name_from_params(...)
	local str = ""
	for _, v in ipairs({
		...
	}) do
		str = str .. v
	end
	return str
end
function EnvironmentMixer:_do_mix(block, ...)
	self:_mix(block, self._from_env:parameter_block(...), self._to_env:parameter_block(...), self._scale)
end
function EnvironmentMixer:_mix(target_block, from_block, to_block, scale)
	for key, value in pairs(from_block) do
		assert(target_block[key] and to_block[key], "[EnvironmentMixer] Mixing failed, parameters does not match.")
		if type(value) == "string" then
			if scale >= 0.5 then
				target_block[key] = value
			end
		else
			local invscale = 1 - scale
			target_block[key] = value * invscale + to_block[key] * scale
		end
	end
end
