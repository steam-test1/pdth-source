FortressLevel = FortressLevel or class()
function FortressLevel:init()
	self._spawn_index = 1
	self._spawn_map = {}
	table.insert(self._spawn_map, {
		name = Idstring("units/characters/dummy_duel/dummy_duel"),
		func = self.spawn_dummy
	})
	Global.god_mode = true
end
function FortressLevel:post_init()
	self._ctrlr_debug = Input:create_virtual_controller()
	local keyboard = Input:keyboard()
	if keyboard and keyboard:has_button(Idstring("right shift")) then
		local connection_name = "step_right"
		self._ctrlr_debug:connect(keyboard, Idstring("right"), Idstring(connection_name))
		self._ctrlr_debug:add_trigger(Idstring(connection_name), callback(self, self, "step_right"))
		connection_name = "step_left"
		self._ctrlr_debug:connect(keyboard, Idstring("left"), Idstring(connection_name))
		self._ctrlr_debug:add_trigger(Idstring(connection_name), callback(self, self, "step_left"))
		if keyboard:has_button(Idstring("right shift")) then
			connection_name = "Debug Spawn"
			self._ctrlr_debug:connect(keyboard, Idstring("right shift"), Idstring(connection_name))
			self._ctrlr_debug:add_trigger(Idstring(connection_name), callback(self, self, "spawn"))
		end
	end
	self._dummy_unit = nil
end
function FortressLevel:update(t, dt)
	if self._spawn_btn_presses then
		self:spawn_dummy()
		self._spawn_btn_presses = false
	end
end
function FortressLevel:spawn_pos()
	return Application:last_camera_position() + Application:last_camera_rotation():y() * 700
end
function FortressLevel:step_right()
	self._spawn_index = self._spawn_index + 1
	if self._spawn_index > #self._spawn_map then
		self._spawn_index = 1
	end
end
function FortressLevel:step_left()
	self._spawn_index = self._spawn_index - 1
	if self._spawn_index < 1 then
		self._spawn_index = #self._spawn_map
	end
end
function FortressLevel:_spawn_enemy_group()
	self:spawn_dummy()
end
function FortressLevel:spawn()
	self._spawn_btn_press_t = TimerManager:game():time()
	self._spawn_btn_presses = (self._spawn_btn_presses or 0) + 1
end
function FortressLevel:spawn_generic(name)
	World:spawn_unit(name, self:spawn_pos())
end
function FortressLevel:spawn_dummy()
	self._debug_unit_name = Idstring("units/characters/drone/drone")
	local dummy_unit = World:spawn_unit(self._debug_unit_name, self:spawn_pos())
end
