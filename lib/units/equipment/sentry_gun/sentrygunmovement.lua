local mvec3_dir = mvector3.direction
local tmp_rot1 = Rotation()
local tmp_vec1 = Vector3()
local tmp_vec2 = Vector3()
SentryGunMovement = SentryGunMovement or class()
function SentryGunMovement:init(unit)
	self._unit = unit
	self._head_obj = self._unit:get_object(Idstring("a_detect"))
	self._spin_obj = self._unit:get_object(Idstring("a_shield"))
	self._pitch_obj = self._unit:get_object(Idstring("a_gun"))
	self._m_rot = unit:rotation()
	self._m_head_fwd = self._m_rot:y()
	self._unit_up = self._m_rot:z()
	self._unit_fwd = self._m_rot:y()
	self._m_head_pos = self._head_obj:position()
	self._vel = {spin = 0, pitch = 0}
	if managers.navigation:is_data_ready() then
		self._nav_tracker = managers.navigation:create_nav_tracker(self._unit:position())
		self._pos_reservation = {
			position = self._unit:position(),
			radius = 30
		}
		managers.navigation:add_pos_reservation(self._pos_reservation)
	else
		Application:error("[SentryGunBase:setup] Spawned Sentry gun unit with incomplete navigation data.")
	end
	self._tweak = tweak_data.weapon.sentry_gun
	self._sound_source = self._unit:sound_source()
	self._last_attention_t = 0
	self._warmup_t = 0
end
function SentryGunMovement:post_init()
	self._ext_network = self._unit:network()
end
function SentryGunMovement:update(unit, t, dt)
	if t > self._warmup_t then
		self:_upd_movement(dt)
	end
end
function SentryGunMovement:set_active(state)
	self._unit:set_extension_update_enabled(Idstring("movement"), state)
	if not state and self._motor_sound then
		self._motor_sound:stop()
		self._motor_sound = false
	end
end
function SentryGunMovement:nav_tracker()
	return self._nav_tracker
end
function SentryGunMovement:set_attention(attention)
	if self._attention and self._attention.destroy_listener_key then
		self._attention.unit:base():remove_destroy_listener(self._attention.destroy_listener_key)
	end
	if attention then
		if attention.unit then
			local listener_key = "SentryGunMovement" .. tostring(self._unit:key())
			attention.destroy_listener_key = listener_key
			attention.unit:base():add_destroy_listener(listener_key, callback(self, self, "attention_unit_destroy_clbk"))
			if self._ext_network then
				self._ext_network:send("cop_set_attention_unit", attention.unit)
			end
		elseif self._ext_network then
			self._ext_network:send("cop_set_attention_pos", attention.pos)
		end
	elseif self._attention and Network:is_server() and self._unit:id() ~= -1 then
		self._ext_network:send("cop_reset_attention")
	end
	self:chk_play_alert(attention, self._attention)
	self._attention = attention
end
function SentryGunMovement:synch_attention(attention)
	if self._attention and self._attention.destroy_listener_key then
		self._attention.unit:base():remove_destroy_listener(self._attention.destroy_listener_key)
	end
	if attention and attention.unit then
		local listener_key = "SentryGunMovement" .. tostring(self._unit:key())
		attention.destroy_listener_key = listener_key
		attention.unit:base():add_destroy_listener(listener_key, callback(self, self, "attention_unit_destroy_clbk"))
	end
	self:chk_play_alert(attention, self._attention)
	self._attention = attention
end
function SentryGunMovement:chk_play_alert(attention, old_attention)
	if not attention and old_attention then
		self._last_attention_t = TimerManager:game():time()
	end
	if attention and not old_attention and TimerManager:game():time() - self._last_attention_t > 3 then
		self._sound_source:post_event("turret_alert")
		self._warmup_t = TimerManager:game():time() + 0.5
	end
end
function SentryGunMovement:attention()
	return self._attention
end
function SentryGunMovement:attention_unit_destroy_clbk(unit)
	if Network:is_server() then
		self:set_attention()
	else
		self:synch_attention()
	end
end
function SentryGunMovement:m_head_pos()
	return self._m_head_pos
end
function SentryGunMovement:m_com()
	return self._m_head_pos
end
function SentryGunMovement:m_pos()
	return self._m_head_pos
end
function SentryGunMovement:m_detect_pos()
	return self._m_head_pos
end
function SentryGunMovement:m_stand_pos()
	return self._m_head_pos
end
function SentryGunMovement:m_head_fwd()
	return self._m_head_fwd
end
function SentryGunMovement:set_look_vec3(look_vec3)
	mvector3.set(self._m_head_fwd, look_vec3)
	local look_rel_polar = look_vec3:to_polar_with_reference(self._unit_fwd, self._unit_up)
	self._spin_obj:set_local_rotation(Rotation(look_rel_polar.spin, 0, 0))
	self._pitch_obj:set_local_rotation(Rotation(0, look_rel_polar.pitch, 0))
	self._unit:set_moving(true)
end
function SentryGunMovement:_upd_movement(dt)
	local target_dir = self:_get_target_dir(self._attention)
	local unit_fwd_polar = self._unit_fwd:to_polar()
	local fwd_polar = self._m_head_fwd:to_polar_with_reference(self._unit_fwd, self._unit_up)
	local error_polar = target_dir:to_polar_with_reference(self._unit_fwd, self._unit_up)
	error_polar = Polar(1, math.clamp(error_polar.pitch, -55, 35.5), error_polar.spin)
	error_polar = error_polar - fwd_polar
	local function _ramp_value(value, err, vel, slowdown_at, max_vel, min_vel, acc)
		local sign_err = math.sign(err)
		local abs_err = math.abs(err)
		local wanted_vel
		if slowdown_at > abs_err then
			wanted_vel = math.lerp(min_vel, max_vel, abs_err / slowdown_at) * sign_err
		else
			wanted_vel = max_vel * sign_err
		end
		local err_vel = wanted_vel - vel
		local sign_err_vel = math.sign(err_vel)
		local abs_err_vel = math.abs(err_vel)
		local abs_delta_vel = math.min(acc * dt, abs_err_vel)
		local delta_vel = abs_delta_vel * sign_err_vel
		local new_vel = vel + delta_vel
		local at_end
		local correction = new_vel * dt
		if math.abs(correction) >= math.abs(err) and math.sign(correction) == math.sign(err) then
			new_vel = 0
			correction = err
			at_end = true
		end
		local new_val = value + correction
		return at_end, new_vel, new_val
	end
	local pitch_end, spin_end, new_vel, new_spin, new_pitch
	spin_end, new_vel, new_spin = _ramp_value(fwd_polar.spin, error_polar.spin, self._vel.spin, self._tweak.SLOWDOWN_ANGLE_SPIN, self._tweak.MAX_VEL_SPIN, self._tweak.MIN_VEL_SPIN, self._tweak.ACC_SPIN)
	self._vel.spin = new_vel
	if new_vel > self._tweak.MAX_VEL_SPIN * 0.25 then
		if not self._motor_sound then
			self._sound_source:post_event("turret_spin_start")
			self._motor_sound = self._sound_source:post_event("turret_spin_loop")
		end
	elseif self._motor_sound and new_vel < self._tweak.MAX_VEL_SPIN * 0.2 then
		self._sound_source:post_event("turret_spin_stop")
		self._motor_sound:stop()
		self._motor_sound = false
	end
	if self._motor_sound then
		self._sound_source:set_rtpc("spin_vel", math.clamp((new_vel - self._tweak.MAX_VEL_SPIN * 0.25) / self._tweak.MAX_VEL_SPIN, 0, 1))
	end
	pitch_end, new_vel, new_pitch = _ramp_value(fwd_polar.pitch, error_polar.pitch, self._vel.pitch, self._tweak.SLOWDOWN_ANGLE_PITCH, self._tweak.MAX_VEL_PITCH, self._tweak.MIN_VEL_PITCH, self._tweak.ACC_PITCH)
	self._vel.pitch = new_vel
	local new_fwd_polar = Polar(1, new_pitch, new_spin)
	local new_fwd_vec3 = new_fwd_polar:to_vector()
	mvector3.rotate_with(new_fwd_vec3, Rotation(math.UP, 90))
	mvector3.rotate_with(new_fwd_vec3, self._m_rot)
	self:set_look_vec3(new_fwd_vec3)
	if pitch_end and spin_end and self._switched_off then
		self:set_active(false)
	end
end
function SentryGunMovement:_get_target_dir(attention)
	if not attention then
		if self._switched_off then
			mvector3.set(tmp_vec2, self._unit_fwd)
			mvector3.rotate_with(tmp_vec2, self._switch_off_rot)
			return tmp_vec2
		else
			return self._unit_fwd
		end
	else
		local target_pos
		if attention.unit then
			target_pos = tmp_vec1
			attention.unit:character_damage():shoot_pos_mid(target_pos)
		else
			target_pos = attention.pos
		end
		local target_vec = tmp_vec2
		mvec3_dir(target_vec, self._m_head_pos, target_pos)
		return target_vec
	end
end
function SentryGunMovement:tased()
	return false
end
function SentryGunMovement:on_death()
	self._unit:set_extension_update_enabled(Idstring("movement"), false)
end
function SentryGunMovement:synch_allow_fire(...)
	self._unit:brain():synch_allow_fire(...)
end
function SentryGunMovement:warming_up(t)
	return t < self._warmup_t
end
function SentryGunMovement:switch_off()
	self._switched_off = true
	self._switch_off_rot = Rotation(self._m_rot:x(), -35)
end
function SentryGunMovement:save(save_data)
	local my_save_data = {}
	if self._attention then
		if self._attention.pos then
			my_save_data.attention = self._attention
		elseif self._attention.unit:id() == -1 then
			my_save_data.attention = {
				pos = self._attention.unit:movement():m_com()
			}
		else
			managers.enemy:add_delayed_clbk("clbk_sync_attention" .. tostring(self._unit:key()), callback(self, CopMovement, "clbk_sync_attention", {
				self._unit,
				self._attention.unit
			}), TimerManager:game():time() + 0.1)
		end
	end
	if next(my_save_data) then
		save_data.movement = my_save_data
	end
end
function SentryGunMovement:load(save_data)
	if not save_data or not save_data.movement then
		return
	end
	if save_data.movement.attention then
		self._attention = save_data.movement.attention
	end
end
function SentryGunMovement:pre_destroy()
	if Network:is_server() then
		self:set_attention()
	else
		self:synch_attention()
	end
	if self._nav_tracker then
		managers.navigation:destroy_nav_tracker(self._nav_tracker)
		self._nav_tracker = nil
	end
	if self._pos_reservation then
		managers.navigation:unreserve_pos(self._pos_reservation)
		self._pos_reservation = nil
	end
end
