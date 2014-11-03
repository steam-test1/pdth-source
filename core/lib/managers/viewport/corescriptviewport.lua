core:module("CoreScriptViewport")
core:import("CoreApp")
core:import("CoreMath")
core:import("CoreCode")
core:import("CoreAccessObjectBase")
core:import("CoreEnvironmentMixer")
core:import("CoreEnvironmentFeeder")
_ScriptViewport = _ScriptViewport or class(CoreAccessObjectBase.AccessObjectBase)
DEFAULT_NETWORK_PORT = 31254
DEFAULT_NETWORK_LSPORT = 31255
VPSLAVE_ARG_NAME = "-vpslave"
NETWORK_SLAVE_RECEIVER = Idstring("scriptviewport_slave")
NETWORK_MASTER_RECEIVER = Idstring("scriptviewport_master")
function _ScriptViewport:init(x, y, width, height, vpm, name)
	_ScriptViewport.super.init(self, vpm, name)
	self._vp = Application:create_world_viewport(x, y, width, height)
	self._vpm = vpm
	self._slave = false
	self._master = false
	self._manual_net_pumping = false
	self._pump_net = false
	self._replaced_vp = false
	self._width_mul_enabled = true
	self._mixer = CoreEnvironmentMixer.EnvironmentMixer:new(vpm:_get_environment_cache(), "core/environments/default")
	self._feeder = CoreEnvironmentFeeder.EnvironmentFeeder:new()
	self._render_params = Global.render_debug.render_sky and {
		"World",
		self._vp,
		nil,
		"Underlay",
		self._vp
	} or {
		"World",
		self._vp,
		nil
	}
	if CoreApp.arg_supplied(VPSLAVE_ARG_NAME) then
		local port = CoreApp.arg_value(VPSLAVE_ARG_NAME)
		if port then
			port = string.lower(port)
			port = port == "default" and DEFAULT_NETWORK_PORT or tonumber(port)
		end
		self:enable_slave(port)
	end
	self._editor_callback = nil
	self._init_trace = debug.traceback()
end
function _ScriptViewport:pump_network()
	if self._manual_net_pumping then
		self._pump_net = true
	end
end
function _ScriptViewport:enable_slave(port)
	Network:bind(port or DEFAULT_NETWORK_PORT, self)
	Network:set_receiver(NETWORK_SLAVE_RECEIVER, self)
	self._slave = true
end
function _ScriptViewport:enable_master(host_name, port, master_listener_port, net_pump)
	self._remote_slave = Network:handshake(host_name or "localhost", port or DEFAULT_NETWORK_PORT)
	if self._remote_slave then
		self._master = true
		self._manual_net_pumping = net_pump
		Network:bind(master_listener_port or DEFAULT_NETWORK_LSPORT, self)
		Network:set_receiver(NETWORK_MASTER_RECEIVER, self)
		assert(self._vp:camera())
		self:remote_update("scriptviewport_update_camera_settings", self._vp:camera():near_range(), self._vp:camera():far_range(), self._vp:camera():fov())
	end
end
function _ScriptViewport:disable_slave_or_master()
	Network:unbind()
	self._slave = false
	self._master = false
	self._manual_net_pumping = false
	self._pump_net = false
end
function _ScriptViewport:render_params()
	return self._render_params
end
function _ScriptViewport:set_render_params(...)
	self._render_params = {
		...
	}
end
function _ScriptViewport:destroy()
	self:set_active(false)
	local vp = not self._replaced_vp and self._vp
	if CoreCode.alive(vp) then
		Application:destroy_viewport(vp)
	end
	self._vpm:_viewport_destroyed(self)
end
function _ScriptViewport:set_width_mul_enabled(b)
	self._width_mul_enabled = b
end
function _ScriptViewport:width_mul_enabled()
	return self._width_mul_enabled
end
function _ScriptViewport:environment_mixer()
	return self._mixer
end
function _ScriptViewport:set_camera(camera)
	self._vp:set_camera(camera)
	self:_set_width_multiplier()
end
function _ScriptViewport:camera()
	return self._vp:camera()
end
function _ScriptViewport:director()
	return self._vp:director()
end
function _ScriptViewport:shaker()
	return self:director():shaker()
end
function _ScriptViewport:vp()
	return self._vp
end
function _ScriptViewport:alive()
	return CoreCode.alive(self._vp)
end
function _ScriptViewport:reference_fov()
	return self._mixer:internal_ref_fov(self._vp, self._render_params[1])
end
function _ScriptViewport:push_ref_fov(fov)
	return self._mixer:internal_push_ref_fov(fov, self._vp, self._render_params[1])
end
function _ScriptViewport:pop_ref_fov()
	return self._mixer:internal_pop_ref_fov(self._vp, self._render_params[1])
end
function _ScriptViewport:set_visualization_mode(name)
	self._mixer:internal_set_visualization_mode(name, self._vp, self._render_params[1])
end
function _ScriptViewport:visualization_modes()
	return self._mixer:internal_visualization_modes()
end
function _ScriptViewport:is_rendering_scene(scene_name)
	for _, param in ipairs(self:render_params()) do
		if param == scene_name then
			return true
		end
	end
	return false
end
function _ScriptViewport:set_dof(clamp, near_focus_distance_min, near_focus_distance_max, far_focus_distance_min, far_focus_distance_max)
end
function _ScriptViewport:replace_engine_vp(vp)
	self:destroy()
	self._replaced_vp = true
	self._vp = vp
end
function _ScriptViewport:feed_now(nr)
	if self._editor_callback then
		self._editor_callback(self._mixer._target_env)
	end
	self._feeder:set_slaving(self._remote_editor or self._editor_callback)
	local id = Profiler:start("Environment Feeders")
	self._feeder:feed(self._mixer:internal_output(), nr or 1, self._render_params[1], self._vp)
	Profiler:stop(id)
end
function _ScriptViewport:reset_network_cache()
	if self._master then
		self:remote_update("scriptviewport_reset_network_cache", self._editor_callback)
	end
end
function _ScriptViewport:scriptviewport_update_position(pos)
	if self._vp:camera() then
		self._vp:camera():set_position(pos)
	end
end
function _ScriptViewport:scriptviewport_update_rotation(rot)
	if self._vp:camera() then
		self._vp:camera():set_rotation(rot)
	end
end
function _ScriptViewport:scriptviewport_update_environment(environment, sky_yaw, rpc)
	if not self._env_net_cache or not self._sky_rot_cache or self._env_net_cache ~= environment or self._sky_rot_cache ~= sky_yaw then
		self._env_net_cache = environment
		self._sky_rot_cache = sky_yaw
		self._mixer:set_environment(environment)
		if managers.worlddefinition and managers.worlddefinition.release_sky_orientation_modifier then
			managers.worlddefinition:release_sky_orientation_modifier()
		end
		self._sky_yaw = sky_yaw
		if not self._environment_modifier_id then
			self._environment_modifier_id = self:create_environment_modifier(false, function()
				return self._sky_yaw
			end, "sky_orientation")
		end
	end
	rpc:scriptviewport_verify_environment(environment, sky_yaw)
end
function _ScriptViewport:scriptviewport_update_camera_settings(near, far, fov)
	if self._vp:camera() then
		self._vp:camera():set_near_range(near)
		self._vp:camera():set_far_range(far)
		self._vp:camera():set_fov(fov)
	end
end
function _ScriptViewport:scriptviewport_verify_environment(environment, sky_yaw)
	self._env_net_cache = environment
	self._sky_rot_cache = sky_yaw
end
function _ScriptViewport:scriptviewport_reset_network_cache(editor, rpc)
	self._env_net_cache = nil
	self._sky_rot_cache = nil
	self._remote_editor = editor
	self:feed_now(1)
	rpc:scriptviewport_verify_reset_network_cache()
end
function _ScriptViewport:scriptviewport_verify_reset_network_cache()
	self._env_net_cache = nil
	self._sky_rot_cache = nil
end
function _ScriptViewport:_update(nr, t, dt)
	self._vp:update()
	self._feed = self._mixer:internal_update(nr, t, dt)
	if self._master and (not self._manual_net_pumping or self._pump_net) then
		self:remote_update("scriptviewport_update_position", self._vp:camera() and self._vp:camera():position() or Vector3())
		self:remote_update("scriptviewport_update_rotation", self._vp:camera() and self._vp:camera():rotation() or Rotation())
		local object = Underlay:get_object(Idstring("skysphere")) or Underlay:get_object(Idstring("g_skysphere"))
		if not object then
			return
		end
		local sky_yaw = -object:rotation():yaw()
		local current_env = self._mixer:current_environment()
		if not self._env_net_cache or not self._sky_rot_cache or self._env_net_cache ~= current_env or self._sky_rot_cache ~= sky_yaw then
			self:remote_update("scriptviewport_update_environment", current_env, sky_yaw)
		end
		self._pump_net = false
	end
end
function _ScriptViewport:remote_update(msg, ...)
	if self._master then
		self._remote_slave[msg](self._remote_slave, ...)
	end
end
function _ScriptViewport:_render(nr)
	if Global.render_debug.render_world then
		if self._feed then
			self:feed_now(nr)
		end
		Application:render(unpack(self._render_params))
	end
end
function _ScriptViewport:_resolution_changed()
	self:_set_width_multiplier()
end
function _ScriptViewport:_set_width_multiplier()
	local camera = self:camera()
	if CoreCode.alive(camera) and self._width_mul_enabled then
		local screen_res = Application:screen_resolution()
		local screen_pixel_aspect = screen_res.x / screen_res.y
		local rect = self._vp:get_rect()
		local vp_pixel_aspect = screen_pixel_aspect
		if rect.ph > 0 then
			vp_pixel_aspect = rect.pw / rect.ph
		end
		camera:set_width_multiplier(CoreMath.width_mul(self._vpm:aspect_ratio()) * (vp_pixel_aspect / screen_pixel_aspect))
	end
end
function _ScriptViewport:_create_environment_modifier_debug(preprocess, callback, shared, ...)
	return self._mixer:create_modifier(preprocess, "debug", callback, shared, ...)
end
function _ScriptViewport:feed_params()
	self._mixer:set_feed_params()
end
function _ScriptViewport:editor_callback(func)
	self._editor_callback = func
end
function _ScriptViewport:set_environment(environment_name, blend_time)
	self._mixer:set_environment(environment_name, blend_time)
end
function _ScriptViewport:environment()
	return self._mixer:current_environment()
end
function _ScriptViewport:create_environment_modifier(preprocess, callback, interface_name)
	return self._mixer:create_modifier(preprocess, interface_name, callback)
end
function _ScriptViewport:destroy_environment_modifier(id)
	return self._mixer:destroy_modifier(id)
end
