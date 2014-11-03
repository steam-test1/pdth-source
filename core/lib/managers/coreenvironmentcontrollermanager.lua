CoreEnvironmentControllerManager = CoreEnvironmentControllerManager or class()
function CoreEnvironmentControllerManager:init()
	self._DEFAULT_DOF_DISTANCE = 10
	self._dof_distance = self._DEFAULT_DOF_DISTANCE
	self._current_dof_distance = self._dof_distance
	self._hurt_value = 1
	self._taser_value = 1
	self._health_effect_value = 1
	self._blurzone = -1
	self._pos = nil
	self._radius = 0
	self._height = 0
	self._opacity = 0
	self._blurzone_update = nil
	self._blurzone_check = nil
	self._hit_right = 0
	self._hit_left = 0
	self._hit_up = 0
	self._hit_down = 0
	self._hit_some = 0
	self._hit_amount = 1
	self._hit_cap = 1
end
function CoreEnvironmentControllerManager:update(t, dt)
	self:_update_values(t, dt)
	self:set_post_composite(t, dt)
end
function CoreEnvironmentControllerManager:_update_values(t, dt)
	if self._current_dof_distance ~= self._dof_distance then
		self._current_dof_distance = math.step(self._current_dof_distance, self._dof_distance, 80000 * dt)
	end
end
function CoreEnvironmentControllerManager:set_dof_distance(distance)
	self._dof_distance = math.max(self._DEFAULT_DOF_DISTANCE, distance or self._DEFAULT_DOF_DISTANCE)
end
function CoreEnvironmentControllerManager:set_hurt_value(hurt)
	self._hurt_value = hurt
end
function CoreEnvironmentControllerManager:set_health_effect_value(health_effect_value)
	self._health_effect_value = health_effect_value
end
function CoreEnvironmentControllerManager:hurt_value()
	return self._hurt_value
end
function CoreEnvironmentControllerManager:set_taser_value(taser)
	self._taser_value = taser
end
function CoreEnvironmentControllerManager:taser_value()
	return self._taser_value
end
function CoreEnvironmentControllerManager:hit_feedback_right()
	self._hit_right = math.min(self._hit_right + self._hit_amount, 1.1)
	self._hit_some = math.min(self._hit_some + self._hit_amount, 1.1)
end
function CoreEnvironmentControllerManager:hit_feedback_left()
	self._hit_left = math.min(self._hit_left + self._hit_amount, 1.1)
	self._hit_some = math.min(self._hit_some + self._hit_amount, 1.1)
end
function CoreEnvironmentControllerManager:hit_feedback_up()
	self._hit_up = math.min(self._hit_up + self._hit_amount, 1.1)
	self._hit_some = math.min(self._hit_some + self._hit_amount, 1.1)
end
function CoreEnvironmentControllerManager:hit_feedback_down()
	self._hit_down = math.min(self._hit_down + self._hit_amount, 1.1)
	self._hit_some = math.min(self._hit_some + self._hit_amount, 1.1)
end
function CoreEnvironmentControllerManager:set_blurzone(mode, pos, radius, height)
	if mode > 0 then
		self._blurzone = mode
		self._pos = pos
		self._radius = radius
		self._height = height
		if mode == 2 then
			self._opacity = 2
			self._blurzone = 1
			self._blurzone_update = self.blurzone_flash_in
		else
			self._opacity = 0
			self._blurzone_update = self.blurzone_fade_in
		end
		if height > 0 then
			self._blurzone_check = self.blurzone_check_cylinder
		else
			self._blurzone_check = self.blurzone_check_sphere
		end
	elseif 0 < self._blurzone then
		self._blurzone = mode
		self._pos = self._pos or pos
		self._radius = self._radius or radius
		self._height = self._height or height
		self._opacity = 1
		self._blurzone_update = self.blurzone_fade_out
		if 0 < self._height then
			self._blurzone_check = self.blurzone_check_cylinder
		else
			self._blurzone_check = self.blurzone_check_sphere
		end
	end
end
function CoreEnvironmentControllerManager:blurzone_flash_in(t, dt, camera_pos)
	self._opacity = self._opacity - dt * 0.3
	if self._opacity < 1 then
		self._opacity = 1
		self._blurzone_update = self.blurzone_fade_idle
	end
	return self:_blurzone_check(camera_pos) * (1 + 11 * (self._opacity - 1))
end
function CoreEnvironmentControllerManager:blurzone_fade_in(t, dt, camera_pos)
	self._opacity = self._opacity + dt
	if self._opacity > 1 then
		self._opacity = 1
		self._blurzone_update = self.blurzone_fade_idle
	end
	return self:_blurzone_check(camera_pos)
end
function CoreEnvironmentControllerManager:blurzone_fade_out(t, dt, camera_pos)
	self._opacity = self._opacity - dt
	if self._opacity < 0 then
		self._opacity = 0
		self._blurzone = -1
		self._blurzone_update = self.blurzone_fade_idle
	end
	return self:_blurzone_check(camera_pos)
end
function CoreEnvironmentControllerManager:blurzone_fade_idle(t, dt, camera_pos)
	return self:_blurzone_check(camera_pos)
end
function CoreEnvironmentControllerManager:blurzone_fade_out_switch(t, dt, camera_pos)
	return self:_blurzone_check(camera_pos)
end
function CoreEnvironmentControllerManager:blurzone_check_cylinder(camera_pos)
	local pos_z = self._pos.z
	local cam_z = camera_pos.z
	local len
	if pos_z > cam_z then
		len = self._pos - camera_pos:length()
	elseif cam_z > pos_z + self._height then
		len = self._pos:with_z(pos_z + self._height) - camera_pos:length()
	else
		len = self._pos:with_z(cam_z) - camera_pos:length()
	end
	local result = math.min(len / self._radius, 1)
	result = result * result
	return (1 - result) * self._opacity
end
function CoreEnvironmentControllerManager:blurzone_check_sphere(camera_pos)
	local len = self._pos - camera_pos:length()
	local result = math.min(len / self._radius, 1)
	result = result * result
	return (1 - result) * self._opacity
end
local ids_dof_settings = Idstring("dof_settings")
local ids_tgl_r = Idstring("tgl_r")
local hit_feedback_rlu = Idstring("hit_feedback_rlu")
local hit_feedback_d = Idstring("hit_feedback_d")
local ids_hdr_post_processor = Idstring("hdr_post_processor")
local ids_hdr_post_composite = Idstring("post_composite")
local mvec1 = Vector3()
local mvec2 = Vector3()
local new_cam_fwd = Vector3()
local new_cam_up = Vector3()
local new_cam_right = Vector3()
function CoreEnvironmentControllerManager:refresh_render_settings(vp)
	if not alive(self._vp) then
		return
	end
	local lvl_tweak_data = Global.level_data and Global.level_data.level_id and tweak_data.levels[Global.level_data.level_id]
	local cubemap_name = lvl_tweak_data and lvl_tweak_data.cube or "cube_apply_empty"
	self._vp:vp():set_post_processor_effect("World", Idstring("cube_apply"), Idstring(cubemap_name))
	self._vp:vp():set_post_processor_effect("World", Idstring("color_grading_post"), Idstring(managers.user:get_setting("video_color_grading")))
	self._vp:vp():set_post_processor_effect("World", Idstring("AA_post"), Idstring(managers.user:get_setting("video_anti_alias")))
	self._vp:vp():set_post_processor_effect("World", Idstring("tonemapper"), Idstring(managers.user:get_setting("video_streaks") and "streaks_2" or "streaks_2_off"))
	self._vp:vp():set_post_processor_effect("World", ids_hdr_post_processor, Idstring(managers.user:get_setting("light_adaption") and "default" or "no_light_adaption"))
end
function CoreEnvironmentControllerManager:set_post_composite(t, dt)
	local vp = managers.viewport:first_active_viewport()
	if not vp then
		return
	end
	if self._vp ~= vp then
		local hdr_post_processor = vp:vp():get_post_processor_effect("World", ids_hdr_post_processor)
		if hdr_post_processor then
			local post_composite = hdr_post_processor:modifier(ids_hdr_post_composite)
			if not post_composite then
				return
			end
			self._material = post_composite:material()
			if not self._material then
				return
			end
			self._vp = vp
		end
	end
	local camera = vp:camera()
	local color_tweak = mvec1
	if camera then
		if self._old_vp ~= vp then
			self:refresh_render_settings()
			self._old_vp = vp
		end
		local base_blur = math.clamp(1 - self._hurt_value - 0.8, 0, 0.2) / 0.2
		base_blur = base_blur + (1 - self._taser_value)
		if 0 <= self._blurzone then
			local fade = self:_blurzone_update(t, dt, camera:position())
			base_blur = base_blur + fade
			color_tweak = Vector3(1, 0.4, 0.2) * fade
		else
			mvector3.set_zero(color_tweak)
		end
		mvector3.set_static(mvec2, 0.32, self._dof_distance, base_blur)
		self._material:set_variable(ids_dof_settings, mvec2)
	else
		mvector3.set_zero(color_tweak)
	end
	local taser_value = 1 - self._taser_value
	local health_scale = 1 - self._health_effect_value
	local hurt_value = (1 - self._hurt_value) * health_scale
	local color = mvec2
	mvector3.set_static(color, 1 + hurt_value - 0.2 * taser_value, 1 - 0.8 * hurt_value - 0.2 * taser_value, 1 - 0.9 * hurt_value + taser_value)
	mvector3.add(color, color_tweak)
	self._material:set_variable(ids_tgl_r, color)
	local hit_fade = dt * 0.4
	self._hit_some = math.max(self._hit_some - hit_fade, 0)
	self._hit_right = math.max(self._hit_right - hit_fade, 0)
	self._hit_left = math.max(self._hit_left - hit_fade, 0)
	self._hit_up = math.max(self._hit_up - hit_fade, 0)
	self._hit_down = math.max(self._hit_down - hit_fade, 0)
	mvector3.set_static(color, self._hit_right, self._hit_left, self._hit_up)
	self._material:set_variable(hit_feedback_rlu, color)
	self._material:set_variable(hit_feedback_d, self._hit_down)
end
local ids_d_sun = Idstring("d_sun")
function CoreEnvironmentControllerManager:feed_params()
	local sun = Underlay:get_object(ids_d_sun)
	if not sun then
		return
	end
	local sun_dir = sun:rotation():z()
	sun_dir = sun_dir * -1
	self:feed_param_underlay("cloud_overlay", "global_sun_dir", sun_dir)
end
function CoreEnvironmentControllerManager:feed_param_underlay(material_name, param_name, param_value)
	local material = Underlay:material(Idstring(material_name))
	material:set_variable(Idstring(param_name), param_value)
end
function CoreEnvironmentControllerManager:set_global_param(param_name, param_value)
end
