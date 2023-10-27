FPCameraPlayerBase = FPCameraPlayerBase or class(UnitBase)
FPCameraPlayerBase.IDS_EMPTY = Idstring("empty")
FPCameraPlayerBase.IDS_NOSTRING = Idstring("")
function FPCameraPlayerBase:init(unit)
	UnitBase.init(self, unit, true)
	self._unit = unit
	self._anims_enabled = true
	self._obj_eye = self._unit:orientation_object()
	self._weap_align = self._unit:get_object(Idstring("right_weapon_align"))
	self._camera_properties = {spin = 0, pitch = 0.5}
	self._output_data = {
		position = unit:position(),
		rotation = unit:rotation()
	}
	self._head_stance = {}
	self._head_stance.translation = Vector3()
	self._head_stance.rotation = Rotation()
	self._shoulder_stance = {}
	self._shoulder_stance.translation = Vector3()
	self._shoulder_stance.rotation = Rotation()
	self._vel_overshot = {}
	self._vel_overshot.translation = Vector3()
	self._vel_overshot.rotation = Rotation()
	self._vel_overshot.last_yaw = 0
	self._vel_overshot.last_pitch = 0
	self._vel_overshot.target_yaw = 0
	self._vel_overshot.target_pitch = 0
	self._fov = {fov = 75}
	self._input = {}
	self._tweak_data = {}
	self._tweak_data.look_speed_dead_zone = 0.1
	self._tweak_data.look_speed_standard = 120
	self._tweak_data.look_speed_fast = 360
	self._tweak_data.look_speed_steel_sight = 60
	self._tweak_data.look_speed_transition_to_fast = 0.5
	self._tweak_data.look_speed_transition_zone = 0.8
	self._tweak_data.look_speed_transition_occluder = 0.95
	self._camera_properties.look_speed_current = self._tweak_data.look_speed_standard
	self._camera_properties.look_speed_transition_timer = 0
	self._camera_properties.target_tilt = 0
	self._camera_properties.current_tilt = 0
	self._recoil_kick = {}
	self._recoil_kick.h = {}
	self:check_flashlight_enabled()
end
function FPCameraPlayerBase:set_parent_unit(parent_unit)
	self._parent_unit = parent_unit
	self._parent_movement_ext = self._parent_unit:movement()
	parent_unit:base():add_destroy_listener("FPCameraPlayerBase", callback(self, self, "parent_destroyed_clbk"))
	local controller_type = self._parent_unit:base():controller():get_default_controller_id()
	if controller_type == "keyboard" then
		self._look_function = callback(self, self, "_pc_look_function")
	else
		self._look_function = callback(self, self, "_gamepad_look_function")
	end
end
function FPCameraPlayerBase:parent_destroyed_clbk(parent_unit)
	self._unit:set_extension_update_enabled(Idstring("base"), false)
	self:set_slot(self._unit, 0)
	self._parent_unit = nil
end
function FPCameraPlayerBase:reset_properties()
	self._camera_properties.spin = self._parent_unit:rotation():y():to_polar().spin
end
function FPCameraPlayerBase:update(unit, t, dt)
	self._parent_unit:base():controller():get_input_axis_clbk("look", callback(self, self, "_update_rot"))
	self:_update_stance(t, dt)
	self:_update_movement(t, dt)
	self._parent_unit:camera():set_position(self._output_data.position)
	self._parent_unit:camera():set_rotation(self._output_data.rotation)
	if self._fov.dirty then
		self._parent_unit:camera():set_FOV(self._fov.fov)
		self._fov.dirty = nil
	end
	if alive(self._light) then
		local weapon = self._parent_unit:inventory():equipped_unit()
		if weapon then
			local object = weapon:get_object(Idstring("fire"))
			local pos = object:position() + object:rotation():y() * 10 + object:rotation():x() * 0 + object:rotation():z() * -2
			self._light:set_position(pos)
			self._light:set_rotation(Rotation(object:rotation():z(), object:rotation():x(), object:rotation():y()))
			World:effect_manager():move_rotate(self._light_effect, pos, Rotation(object:rotation():x(), -object:rotation():y(), -object:rotation():z()))
		end
	end
end
function FPCameraPlayerBase:check_flashlight_enabled()
	if managers.game_play_central:flashlights_on_player_on() then
		if not alive(self._light) then
			self._light = World:create_light("spot|specular")
			self._light:set_spot_angle_end(45)
			self._light:set_far_range(1000)
		end
		if not self._light_effect then
			self._light_effect = World:effect_manager():spawn({
				effect = Idstring("effects/particles/weapons/flashlight/fp_flashlight"),
				position = self._unit:position(),
				rotation = Rotation()
			})
		end
		self._light:set_enable(true)
		World:effect_manager():set_hidden(self._light_effect, false)
	elseif alive(self._light) then
		self._light:set_enable(false)
		World:effect_manager():set_hidden(self._light_effect, true)
	end
end
function FPCameraPlayerBase:start_shooting()
	self._recoil_kick.accumulated = self._recoil_kick.to_reduce or 0
	self._recoil_kick.to_reduce = nil
	self._recoil_kick.current = self._recoil_kick.accumulated or 0
	self._recoil_kick.h.accumulated = self._recoil_kick.h.to_reduce or 0
	self._recoil_kick.h.to_reduce = nil
	self._recoil_kick.h.current = self._recoil_kick.h.accumulated or 0
end
function FPCameraPlayerBase:stop_shooting()
	self._recoil_kick.to_reduce = self._recoil_kick.accumulated
	self._recoil_kick.h.to_reduce = self._recoil_kick.h.accumulated
end
function FPCameraPlayerBase:break_recoil()
	self._recoil_kick.current = 0
	self._recoil_kick.h.current = 0
	self._recoil_kick.accumulated = 0
	self._recoil_kick.h.accumulated = 0
	self:stop_shooting()
end
function FPCameraPlayerBase:recoil_kick(v, v_h)
	if self._recoil_kick.accumulated < 10 then
		v = v or 0.1
		if v < 0 then
			v = (v or 0.1) * (math.random(0, 1) == 0 and -1 or 1)
		end
		self._recoil_kick.accumulated = (self._recoil_kick.accumulated or 0) + v
	end
	v_h = (v_h or 0.25) * (math.random(0, 1) == 0 and -1 or 1)
	self._recoil_kick.h.accumulated = (self._recoil_kick.h.accumulated or 0) + v_h * math.rand(0.5, 1)
end
local bezier_values = {
	0,
	0,
	1,
	1
}
function FPCameraPlayerBase:_update_stance(t, dt)
	if self._shoulder_stance.transition then
		local trans_data = self._shoulder_stance.transition
		local elapsed_t = t - trans_data.start_t
		if elapsed_t > trans_data.duration then
			mvector3.set(self._shoulder_stance.translation, trans_data.end_translation)
			self._shoulder_stance.rotation = trans_data.end_rotation
			self._shoulder_stance.transition = nil
		else
			local progress = elapsed_t / trans_data.duration
			local progress_smooth = math.bezier(bezier_values, progress)
			mvector3.lerp(self._shoulder_stance.translation, trans_data.start_translation, trans_data.end_translation, progress_smooth)
			self._shoulder_stance.rotation = trans_data.start_rotation:slerp(trans_data.end_rotation, progress_smooth)
		end
	end
	if self._head_stance.transition then
		local trans_data = self._head_stance.transition
		local elapsed_t = t - trans_data.start_t
		if elapsed_t > trans_data.duration then
			mvector3.set(self._head_stance.translation, trans_data.end_translation)
			self._head_stance.transition = nil
		else
			local progress = elapsed_t / trans_data.duration
			local progress_smooth = math.bezier(bezier_values, progress)
			mvector3.lerp(self._head_stance.translation, trans_data.start_translation, trans_data.end_translation, progress_smooth)
		end
	end
	if self._vel_overshot.transition then
		local trans_data = self._vel_overshot.transition
		local elapsed_t = t - trans_data.start_t
		if elapsed_t > trans_data.duration then
			self._vel_overshot.yaw_neg = trans_data.end_yaw_neg
			self._vel_overshot.yaw_pos = trans_data.end_yaw_pos
			self._vel_overshot.pitch_neg = trans_data.end_pitch_neg
			self._vel_overshot.pitch_pos = trans_data.end_pitch_pos
			mvector3.set(self._vel_overshot.pivot, trans_data.end_pivot)
			self._vel_overshot.transition = nil
		else
			local progress = elapsed_t / trans_data.duration
			local progress_smooth = math.bezier(bezier_values, progress)
			self._vel_overshot.yaw_neg = math.lerp(trans_data.start_yaw_neg, trans_data.end_yaw_neg, progress_smooth)
			self._vel_overshot.yaw_pos = math.lerp(trans_data.start_yaw_pos, trans_data.end_yaw_pos, progress_smooth)
			self._vel_overshot.pitch_neg = math.lerp(trans_data.start_pitch_neg, trans_data.end_pitch_neg, progress_smooth)
			self._vel_overshot.pitch_pos = math.lerp(trans_data.start_pitch_pos, trans_data.end_pitch_pos, progress_smooth)
			mvector3.lerp(self._vel_overshot.pivot, trans_data.start_pivot, trans_data.end_pivot, progress_smooth)
		end
	end
	self:_calculate_soft_velocity_overshot(dt)
	if self._fov.transition then
		local trans_data = self._fov.transition
		local elapsed_t = t - trans_data.start_t
		if elapsed_t > trans_data.duration then
			self._fov.fov = trans_data.end_fov
			self._fov.transition = nil
		else
			local progress = elapsed_t / trans_data.duration
			local progress_smooth = math.max(math.min(math.bezier(bezier_values, progress), 1), 0)
			self._fov.fov = math.lerp(trans_data.start_fov, trans_data.end_fov, progress_smooth)
		end
		self._fov.dirty = true
	end
end
local mrot1 = Rotation()
local mrot2 = Rotation()
local mrot3 = Rotation()
local mvec1 = Vector3()
local mvec2 = Vector3()
local mvec3 = Vector3()
function FPCameraPlayerBase:_update_movement(t, dt)
	local data = self._camera_properties
	local new_head_pos = mvec2
	local new_shoulder_pos = mvec1
	local new_shoulder_rot = mrot1
	local new_head_rot = mrot2
	self._parent_unit:m_position(new_head_pos)
	mvector3.add(new_head_pos, self._head_stance.translation)
	local stick_input_x, stick_input_y = 0, 0
	stick_input_x = stick_input_x + self:_horizonatal_recoil_kick(t, dt)
	stick_input_y = stick_input_y + self:_vertical_recoil_kick(t, dt)
	local look_polar_spin = data.spin - stick_input_x
	local look_polar_pitch = math.clamp(data.pitch + stick_input_y, -85, 85)
	if self._limit_spin then
		look_polar_spin = math.clamp(look_polar_spin, self._limit_spin.mid + self._limit_spin.min, self._limit_spin.mid + self._limit_spin.max)
	else
		look_polar_spin = look_polar_spin % 360
	end
	local look_polar = Polar(1, look_polar_pitch, look_polar_spin)
	local look_vec = look_polar:to_vector()
	local cam_offset_rot = mrot3
	mrotation.set_look_at(cam_offset_rot, look_vec, math.UP)
	mrotation.set_zero(new_head_rot)
	mrotation.multiply(new_head_rot, self._head_stance.rotation)
	mrotation.multiply(new_head_rot, cam_offset_rot)
	data.pitch = look_polar_pitch
	data.spin = look_polar_spin
	self._output_data.position = new_head_pos
	self._output_data.rotation = new_head_rot or self._output_data.rotation
	if self._camera_properties.current_tilt ~= self._camera_properties.target_tilt then
		self._camera_properties.current_tilt = math.step(self._camera_properties.current_tilt, self._camera_properties.target_tilt, 150 * dt)
	end
	if self._camera_properties.current_tilt ~= 0 then
		self._output_data.rotation = Rotation(self._output_data.rotation:yaw(), self._output_data.rotation:pitch(), self._output_data.rotation:roll() + self._camera_properties.current_tilt)
	end
	mvector3.set(new_shoulder_pos, self._shoulder_stance.translation)
	mvector3.add(new_shoulder_pos, self._vel_overshot.translation)
	mvector3.rotate_with(new_shoulder_pos, self._output_data.rotation)
	mvector3.add(new_shoulder_pos, new_head_pos)
	mrotation.set_zero(new_shoulder_rot)
	mrotation.multiply(new_shoulder_rot, self._output_data.rotation)
	mrotation.multiply(new_shoulder_rot, self._shoulder_stance.rotation)
	mrotation.multiply(new_shoulder_rot, self._vel_overshot.rotation)
	self:set_position(new_shoulder_pos)
	self:set_rotation(new_shoulder_rot)
end
function FPCameraPlayerBase:_update_rot(axis)
	if self._parent_movement_ext._current_state and self._parent_movement_ext._current_state:_interacting() then
		return
	end
	local t = Application:time()
	local dt = t - (self._last_rot_t or t)
	self._last_rot_t = t
	local data = self._camera_properties
	local new_head_pos = mvec2
	local new_shoulder_pos = mvec1
	local new_shoulder_rot = mrot1
	local new_head_rot = mrot2
	self._parent_unit:m_position(new_head_pos)
	mvector3.add(new_head_pos, self._head_stance.translation)
	self._input.look = axis
	local stick_input_x, stick_input_y = self._look_function(self._input.look, dt)
	stick_input_x = stick_input_x + self:_horizonatal_recoil_kick(t, dt)
	stick_input_y = stick_input_y + self:_vertical_recoil_kick(t, dt)
	local look_polar_spin = data.spin - stick_input_x
	local look_polar_pitch = math.clamp(data.pitch + stick_input_y, -85, 85)
	if self._limit_spin then
		look_polar_spin = math.clamp(look_polar_spin, self._limit_spin.mid + self._limit_spin.min, self._limit_spin.mid + self._limit_spin.max)
	else
		look_polar_spin = look_polar_spin % 360
	end
	local look_polar = Polar(1, look_polar_pitch, look_polar_spin)
	local look_vec = look_polar:to_vector()
	local cam_offset_rot = mrot3
	mrotation.set_look_at(cam_offset_rot, look_vec, math.UP)
	mrotation.set_zero(new_head_rot)
	mrotation.multiply(new_head_rot, self._head_stance.rotation)
	mrotation.multiply(new_head_rot, cam_offset_rot)
	data.pitch = look_polar_pitch
	data.spin = look_polar_spin
	self._output_data.position = new_head_pos
	self._output_data.rotation = new_head_rot or self._output_data.rotation
	if self._camera_properties.current_tilt ~= self._camera_properties.target_tilt then
		self._camera_properties.current_tilt = math.step(self._camera_properties.current_tilt, self._camera_properties.target_tilt, 150 * dt)
	end
	if self._camera_properties.current_tilt ~= 0 then
		self._output_data.rotation = Rotation(self._output_data.rotation:yaw(), self._output_data.rotation:pitch(), self._output_data.rotation:roll() + self._camera_properties.current_tilt)
	end
	mvector3.set(new_shoulder_pos, self._shoulder_stance.translation)
	mvector3.add(new_shoulder_pos, self._vel_overshot.translation)
	mvector3.rotate_with(new_shoulder_pos, self._output_data.rotation)
	mvector3.add(new_shoulder_pos, new_head_pos)
	mrotation.set_zero(new_shoulder_rot)
	mrotation.multiply(new_shoulder_rot, self._output_data.rotation)
	mrotation.multiply(new_shoulder_rot, self._shoulder_stance.rotation)
	mrotation.multiply(new_shoulder_rot, self._vel_overshot.rotation)
	self:set_position(new_shoulder_pos)
	self:set_rotation(new_shoulder_rot)
	self._parent_unit:camera():set_position(self._output_data.position)
	self._parent_unit:camera():set_rotation(self._output_data.rotation)
end
function FPCameraPlayerBase:_vertical_recoil_kick(t, dt)
	local r_value = 0
	if self._recoil_kick.current and self._recoil_kick.current ~= self._recoil_kick.accumulated then
		local n = math.step(self._recoil_kick.current, self._recoil_kick.accumulated, 40 * dt)
		r_value = n - self._recoil_kick.current
		self._recoil_kick.current = n
	elseif self._recoil_kick.to_reduce then
		self._recoil_kick.current = nil
		local n = math.lerp(self._recoil_kick.to_reduce, 0, 9 * dt)
		r_value = -(self._recoil_kick.to_reduce - n)
		self._recoil_kick.to_reduce = n
		if self._recoil_kick.to_reduce == 0 then
			self._recoil_kick.to_reduce = nil
		end
	end
	return r_value
end
function FPCameraPlayerBase:_horizonatal_recoil_kick(t, dt)
	local r_value = 0
	if self._recoil_kick.h.current and self._recoil_kick.h.current ~= self._recoil_kick.h.accumulated then
		local n = math.step(self._recoil_kick.h.current, self._recoil_kick.h.accumulated, 40 * dt)
		r_value = n - self._recoil_kick.h.current
		self._recoil_kick.h.current = n
	elseif self._recoil_kick.h.to_reduce then
		self._recoil_kick.h.current = nil
		local n = math.lerp(self._recoil_kick.h.to_reduce, 0, 5 * dt)
		r_value = -(self._recoil_kick.h.to_reduce - n)
		self._recoil_kick.h.to_reduce = n
		if self._recoil_kick.h.to_reduce == 0 then
			self._recoil_kick.h.to_reduce = nil
		end
	end
	return r_value
end
function FPCameraPlayerBase:_pc_look_function(stick_input, dt)
	return stick_input.x, stick_input.y
end
function FPCameraPlayerBase:_gamepad_look_function(stick_input, dt)
	if mvector3.length(stick_input) > self._tweak_data.look_speed_dead_zone then
		local x = stick_input.x
		local y = stick_input.y
		stick_input = Vector3(x / (1.3 - 0.3 * (1 - math.abs(y))), y / (1.3 - 0.3 * (1 - math.abs(x))), 0)
		local look_speed = self:_get_look_speed(stick_input, dt)
		local stick_input_x = stick_input.x * dt * look_speed
		local stick_input_y = stick_input.y * dt * look_speed
		return stick_input_x, stick_input_y
	end
	return 0, 0
end
function FPCameraPlayerBase:_get_look_speed(stick_input, dt)
	if self._parent_unit:movement()._current_state._in_steelsight then
		return self._tweak_data.look_speed_steel_sight
	end
	if not (mvector3.length(stick_input) > self._tweak_data.look_speed_transition_occluder) or not (math.abs(stick_input.x) > self._tweak_data.look_speed_transition_zone) then
		self._camera_properties.look_speed_transition_timer = 0
		return self._tweak_data.look_speed_standard
	end
	if self._camera_properties.look_speed_transition_timer >= 1 then
		return self._tweak_data.look_speed_fast
	end
	local p1 = self._tweak_data.look_speed_standard
	local p2 = self._tweak_data.look_speed_standard
	local p3 = self._tweak_data.look_speed_standard + (self._tweak_data.look_speed_fast - self._tweak_data.look_speed_standard) / 3 * 2
	local p4 = self._tweak_data.look_speed_fast
	self._camera_properties.look_speed_transition_timer = self._camera_properties.look_speed_transition_timer + dt / self._tweak_data.look_speed_transition_to_fast
	return math.bezier({
		p1,
		p2,
		p3,
		p4
	}, self._camera_properties.look_speed_transition_timer)
end
function FPCameraPlayerBase:_calculate_soft_velocity_overshot(dt)
	local stick_input = self._input.look
	local vel_overshot = self._vel_overshot
	if not stick_input then
		return
	end
	local input_yaw, input_pitch, input_x, input_z
	if stick_input.x >= 0 then
		local stick_input_x = math.pow(math.abs(math.clamp(0.002 * stick_input.x / dt, 0, 1)), 1.5) * math.sign(stick_input.x)
		input_yaw = stick_input_x * vel_overshot.yaw_pos
	else
		local stick_input_x = math.pow(math.abs(math.clamp(0.002 * stick_input.x / dt, -1, 0)), 1.5)
		input_yaw = stick_input_x * vel_overshot.yaw_neg
	end
	local last_yaw = vel_overshot.last_yaw
	local sign_in_yaw = math.sign(input_yaw)
	local abs_in_yaw = math.abs(input_yaw)
	local sign_last_yaw = math.sign(last_yaw)
	local abs_last_yaw = math.abs(last_yaw)
	vel_overshot.target_yaw = math.step(vel_overshot.target_yaw, input_yaw, 120 * dt)
	local final_yaw
	local diff = math.abs(vel_overshot.target_yaw - last_yaw)
	local diff_clamp = 40
	local diff_ratio = math.pow(diff / diff_clamp, 1)
	local diff_ratio_clamped = math.clamp(diff_ratio, 0, 1)
	local step_amount = math.lerp(3, 180, diff_ratio_clamped) * dt
	final_yaw = math.step(last_yaw, vel_overshot.target_yaw, step_amount)
	vel_overshot.last_yaw = final_yaw
	if 0 <= stick_input.y then
		local stick_input_y = math.pow(math.abs(math.clamp(0.002 * stick_input.y / dt, 0, 1)), 1.5) * math.sign(stick_input.y)
		input_pitch = stick_input_y * vel_overshot.pitch_pos
	else
		local stick_input_y = math.pow(math.abs(math.clamp(0.002 * stick_input.y / dt, -1, 0)), 1.5)
		input_pitch = stick_input_y * vel_overshot.pitch_neg
	end
	local last_pitch = vel_overshot.last_pitch
	local sign_in_pitch = math.sign(input_pitch)
	local abs_in_pitch = math.abs(input_pitch)
	local sign_last_pitch = math.sign(last_pitch)
	local abs_last_pitch = math.abs(last_pitch)
	vel_overshot.target_pitch = math.step(vel_overshot.target_pitch, input_pitch, 120 * dt)
	local final_pitch
	local diff = math.abs(vel_overshot.target_pitch - last_pitch)
	local diff_clamp = 40
	local diff_ratio = math.pow(diff / diff_clamp, 1)
	local diff_ratio_clamped = math.clamp(diff_ratio, 0, 1)
	local step_amount = math.lerp(3, 180, diff_ratio_clamped) * dt
	final_pitch = math.step(last_pitch, vel_overshot.target_pitch, step_amount)
	vel_overshot.last_pitch = final_pitch
	mrotation.set_yaw_pitch_roll(vel_overshot.rotation, final_yaw, final_pitch, 0)
	local pivot = vel_overshot.pivot
	local new_root = mvec3
	mvector3.set(new_root, pivot)
	mvector3.negate(new_root)
	mvector3.rotate_with(new_root, vel_overshot.rotation)
	mvector3.add(new_root, pivot)
	mvector3.set(vel_overshot.translation, new_root)
end
function FPCameraPlayerBase:set_position(pos)
	self._unit:set_position(pos)
end
function FPCameraPlayerBase:set_rotation(rot)
	self._unit:set_rotation(rot)
end
function FPCameraPlayerBase:eye_position()
	return self._obj_eye:position()
end
function FPCameraPlayerBase:eye_rotation()
	return self._obj_eye:rotation()
end
function FPCameraPlayerBase:play_redirect(redirect_name, speed)
	self:set_anims_enabled(true)
	local result = self._unit:play_redirect(redirect_name)
	if result == self.IDS_NOSTRING then
		return false
	end
	if speed then
		self._unit:anim_state_machine():set_speed(result, speed)
	end
	return result
end
function FPCameraPlayerBase:play_state(state_name)
	self:set_anims_enabled(true)
	local result = self._unit:play_state(Idstring(state_name))
	return result ~= self.IDS_NOSTRING and result
end
function FPCameraPlayerBase:set_target_tilt(tilt)
	self._camera_properties.target_tilt = tilt
end
function FPCameraPlayerBase:set_stance_instant(stance_name)
	local new_stance = tweak_data.player.stances.default[stance_name].shoulders
	if new_stance then
		self._shoulder_stance.transition = nil
		self._shoulder_stance.translation = mvector3.copy(new_stance.translation)
		self._shoulder_stance.rotation = new_stance.rotation
	end
	local new_stance = tweak_data.player.stances.default[stance_name].head
	if new_stance then
		self._head_stance.transition = nil
		self._head_stance.translation = mvector3.copy(new_stance.translation)
		self._head_stance.rotation = new_stance.rotation
	end
	local new_overshot = tweak_data.player.stances.default[stance_name].vel_overshot
	if new_overshot then
		self._vel_overshot.transition = nil
		self._vel_overshot.yaw_neg = new_overshot.yaw_neg
		self._vel_overshot.yaw_pos = new_overshot.yaw_pos
		self._vel_overshot.pitch_neg = new_overshot.pitch_neg
		self._vel_overshot.pitch_pos = new_overshot.pitch_pos
		self._vel_overshot.pivot = mvector3.copy(new_overshot.pivot)
	end
	self:set_stance_fov_instant(stance_name)
end
function FPCameraPlayerBase:set_stance_fov_instant(stance_name)
	local new_fov = tweak_data.player.stances.default[stance_name].zoom_fov and managers.user:get_setting("fov_zoom") or managers.user:get_setting("fov_standard")
	if new_fov then
		self._fov.transition = nil
		self._fov.fov = new_fov
		self._fov.dirty = true
		if Application:paused() then
			self._parent_unit:camera():set_FOV(self._fov.fov)
		end
	end
end
function FPCameraPlayerBase:clbk_stance_entered(new_shoulder_stance, new_head_stance, new_vel_overshot, new_fov, new_shakers, duration_multiplier)
	local t = TimerManager:game():time()
	if new_shoulder_stance then
		local transition = {}
		self._shoulder_stance.transition = transition
		transition.end_translation = new_shoulder_stance.translation
		transition.end_rotation = new_shoulder_stance.rotation
		transition.start_translation = mvector3.copy(self._shoulder_stance.translation)
		transition.start_rotation = self._shoulder_stance.rotation
		transition.start_t = t
		transition.duration = 0.23 * duration_multiplier
	end
	if new_head_stance then
		local transition = {}
		self._head_stance.transition = transition
		transition.end_translation = new_head_stance.translation
		transition.end_rotation = new_head_stance.rotation
		transition.start_translation = mvector3.copy(self._head_stance.translation)
		transition.start_rotation = self._head_stance.rotation
		transition.start_t = t
		transition.duration = 0.23 * duration_multiplier
	end
	if new_vel_overshot then
		local transition = {}
		self._vel_overshot.transition = transition
		transition.end_pivot = new_vel_overshot.pivot
		transition.end_yaw_neg = new_vel_overshot.yaw_neg
		transition.end_yaw_pos = new_vel_overshot.yaw_pos
		transition.end_pitch_neg = new_vel_overshot.pitch_neg
		transition.end_pitch_pos = new_vel_overshot.pitch_pos
		transition.start_pivot = mvector3.copy(self._vel_overshot.pivot)
		transition.start_yaw_neg = self._vel_overshot.yaw_neg
		transition.start_yaw_pos = self._vel_overshot.yaw_pos
		transition.start_pitch_neg = self._vel_overshot.pitch_neg
		transition.start_pitch_pos = self._vel_overshot.pitch_pos
		transition.start_t = t
		transition.duration = 0.23 * duration_multiplier
	end
	if new_fov then
		if new_fov == self._fov.fov then
			self._fov.transition = nil
		else
			local transition = {}
			self._fov.transition = transition
			transition.end_fov = new_fov
			transition.start_fov = self._fov.fov
			transition.start_t = t
			transition.duration = 0.23 * duration_multiplier
		end
	end
	if new_shakers then
		for effect, values in pairs(new_shakers) do
			for parameter, value in pairs(values) do
				self._parent_unit:camera():set_shaker_parameter(effect, parameter, value)
			end
		end
	end
end
function FPCameraPlayerBase:animate_fov(new_fov, duration_multiplier)
	if new_fov == self._fov.fov then
		self._fov.transition = nil
	else
		local transition = {}
		self._fov.transition = transition
		transition.end_fov = new_fov
		transition.start_fov = self._fov.fov
		transition.start_t = TimerManager:game():time()
		transition.duration = 0.23 * (duration_multiplier or 1)
	end
end
function FPCameraPlayerBase:anim_clbk_idle_full_blend()
	self:play_redirect(self.IDS_EMPTY)
end
function FPCameraPlayerBase:anim_clbk_idle_exit()
end
function FPCameraPlayerBase:anim_clbk_empty_full_blend()
	self:set_anims_enabled(false)
end
function FPCameraPlayerBase:set_handcuff_units(units)
	self._handcuff_units = units
end
function FPCameraPlayerBase:anim_clbk_spawn_handcuffs()
	if not self._handcuff_units then
		local align_obj_l_name = Idstring("a_weapon_left")
		local align_obj_r_name = Idstring("a_weapon_right")
		local align_obj_l = self._unit:get_object(align_obj_l_name)
		local align_obj_r = self._unit:get_object(align_obj_r_name)
		local handcuff_unit_name = Idstring("units/equipment/handcuffs_first_person/handcuffs_first_person")
		local handcuff_unit_l = World:spawn_unit(handcuff_unit_name, align_obj_l:position(), align_obj_l:rotation())
		local handcuff_unit_r = World:spawn_unit(handcuff_unit_name, align_obj_r:position(), align_obj_r:rotation())
		self._unit:link(align_obj_l_name, handcuff_unit_l, handcuff_unit_l:orientation_object():name())
		self._unit:link(align_obj_r_name, handcuff_unit_r, handcuff_unit_r:orientation_object():name())
		local handcuff_units = {handcuff_unit_l, handcuff_unit_r}
		self._unit:base():set_handcuff_units(handcuff_units)
	end
end
function FPCameraPlayerBase:anim_clbk_unspawn_handcuffs()
	if self._handcuff_units then
		for _, handcuff_unit in ipairs(self._handcuff_units) do
			handcuff_unit:set_slot(0)
		end
	end
	self:set_handcuff_units(nil)
end
function FPCameraPlayerBase:get_weapon_offsets()
	local weapon = self._parent_unit:inventory():equipped_unit()
	local object = weapon:get_object(Idstring("a_sight"))
	print((object:position() - self._unit:position()):rotate_HP(self._unit:rotation():inverse()))
	print(self._unit:rotation():inverse() * object:rotation())
end
function FPCameraPlayerBase:set_anims_enabled(state)
	if state ~= self._anims_enabled then
		self._unit:set_animations_enabled(state)
		self._anims_enabled = state
	end
end
function FPCameraPlayerBase:play_sound(unit, event)
	if alive(self._parent_unit) then
		self._parent_unit:sound():play(event)
	end
end
function FPCameraPlayerBase:limit_spin(min, max)
	self._limit_spin = {
		mid = self._camera_properties.spin,
		min = min,
		max = max
	}
end
function FPCameraPlayerBase:remove_spin_limit()
	self._limit_spin = nil
end
function FPCameraPlayerBase:throw_flash_grenade(unit)
	if alive(self._parent_unit) then
		self._parent_unit:equipment():throw_flash_grenade()
	end
end
function FPCameraPlayerBase:hide_weapon()
	if alive(self._parent_unit) then
		self._parent_unit:inventory():hide_equipped_unit()
	end
end
function FPCameraPlayerBase:show_weapon()
	if alive(self._parent_unit) then
		self._parent_unit:inventory():show_equipped_unit()
	end
end
function FPCameraPlayerBase:enter_shotgun_reload_loop(unit, state, ...)
	if alive(self._parent_unit) then
		local speed_multiplier = self._parent_unit:inventory():equipped_unit():base():reload_speed_multiplier()
		self._unit:anim_state_machine():set_speed(Idstring(state), speed_multiplier)
	end
end
function FPCameraPlayerBase:destroy()
	if self._parent_unit then
		self._parent_unit:base():remove_destroy_listener("FPCameraPlayerBase")
	end
	if self._light then
		World:delete_light(self._light)
	end
	if self._light_effect then
		World:effect_manager():kill(self._light_effect)
		self._light_effect = nil
	end
	self:anim_clbk_unspawn_handcuffs()
end
