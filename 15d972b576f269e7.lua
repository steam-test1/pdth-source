AnimatedHeliBase = AnimatedHeliBase or class(UnitBase)
function AnimatedHeliBase:init(unit)
	AnimatedHeliBase.super.init(self, unit, false)
	self._unit = unit
	self:_set_anim_lod(0)
end
function AnimatedHeliBase:update(unit, t, dt)
	local new_pos = self._obj_com:position()
	if new_pos ~= self._last_pos and alive(self._listener_obj) then
		local new_vel = new_pos - self._last_pos
		mvector3.divide(new_vel, dt)
		self._last_pos = new_pos
		local listener_pos = self._listener_obj:position()
		local listener_vec = listener_pos - new_pos
		local listener_dis = mvector3.normalize(listener_vec)
		local vel_dot = mvector3.dot(listener_vec, new_vel)
		vel_dot = math.clamp(vel_dot / 15000, -1, 1)
		self._sound_source:set_rtpc("vel_to_listener", vel_dot)
		self:_set_anim_lod(listener_dis)
	end
end
function AnimatedHeliBase:_set_anim_lod(dis)
	if dis > 9000 then
		if self._lod_high then
			self._lod_high = false
			self._unit:set_animation_lod(2, 0, 0, 0)
		end
	elseif dis < 8000 and not self._lod_high then
		self._lod_high = true
		self._unit:set_animation_lod(1, 1000000, 1000000, 1000000)
	end
end
function AnimatedHeliBase:start_doppler()
	self:set_enabled(true)
	self._obj_com = self._unit:get_object(Idstring("a_body"))
	self._last_pos = self._obj_com:position()
	self._listener_obj = managers.listener:active_listener_obj()
	self._sound_source = self._unit:sound_source()
end
function AnimatedHeliBase:stop_doppler()
	self:set_enabled(false)
	self._listener_obj = nil
	self._sound_source = nil
end
function AnimatedHeliBase:set_enabled(state)
	if state then
		if self._ext_enabled_count then
			self._ext_enabled_count = self._ext_enabled_count + 1
		else
			self._ext_enabled_count = 1
			self._unit:set_extension_update_enabled(Idstring("base"), true)
		end
	elseif self._ext_enabled_count and self._ext_enabled_count > 1 then
		self._ext_enabled_count = self._ext_enabled_count - 1
	else
		self._ext_enabled_count = nil
		self._unit:set_extension_update_enabled(Idstring("base"), false)
	end
end
function AnimatedHeliBase:anim_clbk_empty_full_blend(unit)
	self:stop_doppler()
	unit:set_animations_enabled(false)
end
function AnimatedHeliBase:anim_clbk_empty_exit(unit)
	self:start_doppler()
	unit:set_animations_enabled(true)
end
