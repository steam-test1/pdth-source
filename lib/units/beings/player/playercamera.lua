PlayerCamera = PlayerCamera or class()
PlayerCamera.IDS_NOTHING = Idstring("")
function PlayerCamera:init(unit)
	self._unit = unit
	self._m_cam_rot = unit:rotation()
	self._m_cam_pos = unit:position() + math.UP * 140
	self._m_cam_fwd = self._m_cam_rot:y()
	self._camera_object = World:create_camera()
	self._camera_object:set_near_range(3)
	self._camera_object:set_far_range(250000)
	self._camera_object:set_fov(75)
	self:spawn_camera_unit()
	self:_setup_sound_listener()
	self._sync_fwd = unit:rotation():y():with_z(0):normalized()
	self._last_sync_t = 0
end
function PlayerCamera:setup_viewport(data)
	if self._vp then
		self._vp:destroy()
	end
	local dimensions = data.dimensions
	local name = "player" .. tostring(self._id)
	local vp = managers.viewport:new_vp(dimensions.x, dimensions.y, dimensions.w, dimensions.h, name)
	self._director = vp:director()
	self._shaker = self._director:shaker()
	self._camera_controller = self._director:make_camera(self._camera_object, Idstring("fps"))
	self._director:set_camera(self._camera_controller)
	self._director:position_as(self._camera_object)
	self._camera_controller:set_both(self._camera_unit)
	self._shakers = {}
	self._shakers.breathing = self._shaker:play("breathing", 0.3)
	self._shakers.headbob = self._shaker:play("headbob", 0)
	vp:set_camera(self._camera_object)
	vp:set_environment(managers.environment_area:default_environment())
	self._vp = vp
end
function PlayerCamera:spawn_camera_unit()
	local lvl_tweak_data = Global.level_data and Global.level_data.level_id and tweak_data.levels[Global.level_data.level_id]
	local unit_folder = lvl_tweak_data and lvl_tweak_data.unit_suit or "suit"
	self._camera_unit = World:spawn_unit(Idstring("units/characters/fps/" .. unit_folder .. "/fps_hand"), self._m_cam_pos, self._m_cam_rot)
	self._machine = self._camera_unit:anim_state_machine()
	self._unit:link(self._camera_unit)
	self._camera_unit:base():set_parent_unit(self._unit)
	self._camera_unit:base():reset_properties()
	self._camera_unit:base():set_stance_instant("standard")
end
function PlayerCamera:camera_unit()
	return self._camera_unit
end
function PlayerCamera:anim_state_machine()
	return self._camera_unit:anim_state_machine()
end
function PlayerCamera:play_redirect(redirect_name, at_time)
	local result = self._camera_unit:base():play_redirect(redirect_name, at_time)
	return result ~= PlayerCamera.IDS_NOTHING and result
end
function PlayerCamera:play_state(state_name, at_time)
	local result = self._camera_unit:base():play_state(state_name, at_time)
	return result ~= PlayerCamera.IDS_NOTHING and result
end
function PlayerCamera:set_speed(state_name, speed)
	self._machine:set_speed(state_name, speed)
end
function PlayerCamera:anim_data()
	return self._camera_unit:anim_data()
end
function PlayerCamera:destroy()
	self._vp:destroy()
	self._unit = nil
	World:delete_camera(self._camera_object)
	self._camera_object = nil
	self:remove_sound_listener()
end
function PlayerCamera:remove_sound_listener()
	if not self._listener_id then
		return
	end
	managers.sound_environment:remove_check_object(self._sound_check_object)
	managers.listener:remove_listener(self._listener_id)
	managers.listener:remove_set("player_camera")
	self._listener_id = nil
end
function PlayerCamera:clbk_fp_enter(aim_dir)
	if self._camera_manager_mode ~= "first_person" then
		self._camera_manager_mode = "first_person"
	end
end
function PlayerCamera:_setup_sound_listener()
	self._listener_id = managers.listener:add_listener("player_camera", self._camera_object, self._camera_object, nil, false)
	managers.listener:add_set("player_camera", {
		"player_camera"
	})
	self._listener_activation_id = managers.listener:activate_set("main", "player_camera")
	self._sound_check_object = managers.sound_environment:add_check_object({
		object = self._unit:orientation_object(),
		active = true,
		primary = true
	})
end
function PlayerCamera:position()
	return self._m_cam_pos
end
function PlayerCamera:rotation()
	return self._m_cam_rot
end
function PlayerCamera:forward()
	return self._m_cam_fwd
end
function PlayerCamera:set_position(pos)
	self._camera_controller:set_camera(pos)
	mvector3.set(self._m_cam_pos, pos)
end
local mvec1 = Vector3()
function PlayerCamera:set_rotation(rot)
	mrotation.y(rot, mvec1)
	mvector3.multiply(mvec1, 100000)
	mvector3.add(mvec1, self._m_cam_pos)
	self._camera_controller:set_target(mvec1)
	mrotation.z(rot, mvec1)
	self._camera_controller:set_default_up(mvec1)
	mrotation.set_yaw_pitch_roll(self._m_cam_rot, rot:yaw(), rot:pitch(), rot:roll())
	mrotation.y(self._m_cam_rot, self._m_cam_fwd)
	local new_fwd = self:forward()
	local error_sync_dot = mvector3.dot(self._sync_fwd, new_fwd)
	local t = TimerManager:game():time()
	local sync_dt = t - self._last_sync_t
	if error_sync_dot < 0.9 and sync_dt > 0.5 or error_sync_dot < 0.99 and sync_dt > 1 then
		self._last_sync_t = t
		self._unit:network():send("set_look_dir", new_fwd)
		mvector3.set(self._sync_fwd, new_fwd)
	end
end
function PlayerCamera:set_FOV(fov_value)
	self._camera_object:set_fov(fov_value)
end
function PlayerCamera:viewport()
	return self._vp
end
function PlayerCamera:set_shaker_parameter(effect, parameter, value)
	if not self._shakers then
		return
	end
	if self._shakers[effect] then
		self._shaker:set_parameter(self._shakers[effect], parameter, value)
	end
end
function PlayerCamera:play_shaker(effect, amplitude, frequency, offset)
	return self._shaker:play(effect, amplitude or 1, frequency or 1, offset or 0)
end
function PlayerCamera:stop_shaker(id)
	self._shaker:stop_immediately(id)
end
function PlayerCamera:shaker()
	return self._shaker
end
