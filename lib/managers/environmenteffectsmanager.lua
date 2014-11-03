core:import("CoreEnvironmentEffectsManager")
EnvironmentEffectsManager = EnvironmentEffectsManager or class(CoreEnvironmentEffectsManager.EnvironmentEffectsManager)
function EnvironmentEffectsManager:init()
	EnvironmentEffectsManager.super.init(self)
	self:add_effect("rain", RainEffect:new())
	self:add_effect("raindrop_screen", RainDropScreenEffect:new())
	self:add_effect("lightning", LightningEffect:new())
	self._camera_position = Vector3()
	self._camera_rotation = Rotation()
end
function EnvironmentEffectsManager:update(t, dt)
	self._camera_position = managers.viewport:get_current_camera_position()
	self._camera_rotation = managers.viewport:get_current_camera_rotation()
	EnvironmentEffectsManager.super.update(self, t, dt)
end
function EnvironmentEffectsManager:camera_position()
	return self._camera_position
end
function EnvironmentEffectsManager:camera_rotation()
	return self._camera_rotation
end
EnvironmentEffect = EnvironmentEffect or class()
function EnvironmentEffect:init(default)
	self._default = default
end
function EnvironmentEffect:load_effects()
end
function EnvironmentEffect:update(t, dt)
end
function EnvironmentEffect:start()
end
function EnvironmentEffect:stop()
end
function EnvironmentEffect:default()
	return self._default
end
RainEffect = RainEffect or class(EnvironmentEffect)
function RainEffect:init()
	EnvironmentEffect.init(self)
	self._effect_name = Idstring("effects/particles/rain/rain_01_a")
end
function RainEffect:load_effects()
end
function RainEffect:update(t, dt)
	local vp = managers.viewport:first_active_viewport()
	if vp and self._vp ~= vp then
		vp:vp():set_post_processor_effect("World", Idstring("streaks"), Idstring("streaks_rain"))
		if alive(self._vp) then
			self._vp:vp():set_post_processor_effect("World", Idstring("streaks"), Idstring("streaks"))
		end
		self._vp = vp
	end
	local c_rot = managers.environment_effects:camera_rotation()
	if not c_rot then
		return
	end
	local c_pos = managers.environment_effects:camera_position()
	if not c_pos then
		return
	end
	World:effect_manager():move_rotate(self._effect, c_pos, c_rot)
end
function RainEffect:start()
	self._effect = World:effect_manager():spawn({
		effect = self._effect_name,
		position = Vector3(),
		rotation = Rotation()
	})
end
function RainEffect:stop()
	World:effect_manager():kill(self._effect)
	self._effect = nil
	if alive(self._vp) then
		self._vp:vp():set_post_processor_effect("World", Idstring("streaks"), Idstring("streaks"))
		self._vp = nil
	end
end
LightningEffect = LightningEffect or class(EnvironmentEffect)
function LightningEffect:init()
	EnvironmentEffect.init(self)
end
function LightningEffect:load_effects()
end
function LightningEffect:_update_wait_start()
	if Underlay:loaded() then
		self:start()
	end
end
function LightningEffect:_update(t, dt)
	if self._flashing then
		self:_update_function(t, dt)
	end
	if self._sound_delay then
		self._sound_delay = self._sound_delay - dt
		if self._sound_delay <= 0 then
			self._sound_source:post_event("thunder")
			self._sound_delay = nil
		end
	end
	self._next = self._next - dt
	if 0 >= self._next then
		self:_set_lightning_values()
		self:_make_lightning()
		self._update_function = self._update_first
		self:_set_next_timer()
		self._flashing = true
	end
end
function LightningEffect:start()
	if not Underlay:loaded() then
		self.update = self._update_wait_start
		return
	end
	self.update = self._update
	self._sky_material = Underlay:material(Idstring("sky"))
	self._original_color0 = self._sky_material:get_variable(Idstring("color0"))
	self._original_light_color = Global._global_light:color()
	self._original_sun_horizontal = Underlay:time(Idstring("sun_horizontal"))
	self._min_interval = 2
	self._rnd_interval = 10
	self._sound_source = SoundDevice:create_source("thunder")
	self:_set_next_timer()
end
function LightningEffect:stop()
end
function LightningEffect:_update_first(t, dt)
	self._first_flash_time = self._first_flash_time - dt
	if self._first_flash_time <= 0 then
		self:_set_original_values()
		self._update_function = self._update_pause
	end
end
function LightningEffect:_update_pause(t, dt)
	self._pause_flash_time = self._pause_flash_time - dt
	if self._pause_flash_time <= 0 then
		self:_make_lightning()
		self._update_function = self._update_second
	end
end
function LightningEffect:_update_second(t, dt)
	self._second_flash_time = self._second_flash_time - dt
	if self._second_flash_time <= 0 then
		self:_set_original_values()
		self._flashing = false
	end
end
function LightningEffect:_set_original_values()
	self._sky_material:set_variable(Idstring("color0"), self._original_color0)
	Global._global_light:set_color(self._original_light_color)
	Underlay:set_time(Idstring("sun_horizontal"), self._original_sun_horizontal)
end
function LightningEffect:_make_lightning()
	self._sky_material:set_variable(Idstring("color0"), self._intensity_value)
	Global._global_light:set_color(self._intensity_value)
	Underlay:set_time(Idstring("sun_horizontal"), self._flash_anim_time)
end
function LightningEffect:_set_lightning_values()
	self._first_flash_time = 0.1
	self._pause_flash_time = 0.1
	self._second_flash_time = 0.3
	self._flash_roll = math.rand(360)
	self._flash_dir = Rotation(0, 0, self._flash_roll):y()
	self._flash_anim_time = math.rand(0, 1)
	self._distance = math.rand(1)
	self._intensity_value = math.lerp(Vector3(2, 2, 2), Vector3(5, 5, 5), self._distance)
	local c_pos = managers.environment_effects:camera_position()
	if c_pos then
		local sound_speed = 30000
		self._sound_delay = self._distance * 2
		self._sound_source:set_rtpc("lightning_distance", self._distance * 4000)
	end
end
function LightningEffect:_set_next_timer()
	self._next = self._min_interval + math.rand(self._rnd_interval)
end
RainDropEffect = RainDropEffect or class(EnvironmentEffect)
function RainDropEffect:init()
	EnvironmentEffect.init(self)
	self._under_roof = false
	self._slotmask = managers.slot:get_mask("statics")
end
function RainDropEffect:load_effects()
end
function RainDropEffect:update(t, dt)
end
function RainDropEffect:start()
	local t = {
		effect = self._effect_name,
		position = Vector3(),
		rotation = Rotation()
	}
	self._raindrops = World:effect_manager():spawn(t)
	self._extra_raindrops = World:effect_manager():spawn(t)
end
function RainDropEffect:stop()
	if self._raindrops then
		World:effect_manager():fade_kill(self._raindrops)
		World:effect_manager():fade_kill(self._extra_raindrops)
		self._raindrops = nil
	end
end
RainDropScreenEffect = RainDropScreenEffect or class(RainDropEffect)
function RainDropScreenEffect:init()
	RainDropEffect.init(self)
	self._effect_name = Idstring("effects/particles/rain/raindrop_screen")
end
CoreClass.override_class(CoreEnvironmentEffectsManager.EnvironmentEffectsManager, EnvironmentEffectsManager)
