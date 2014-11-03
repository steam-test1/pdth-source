NPCRaycastWeaponBase = NPCRaycastWeaponBase or class(RaycastWeaponBase)
NPCRaycastWeaponBase._VOICES = {
	"a",
	"b",
	"c"
}
NPCRaycastWeaponBase._next_i_voice = {}
function NPCRaycastWeaponBase:init(unit)
	RaycastWeaponBase.super.init(self, unit, false)
	self._unit = unit
	self._name_id = self.name_id or "m4_npc"
	self.name_id = nil
	self._bullet_slotmask = managers.slot:get_mask("bullet_impact_targets")
	self._blank_slotmask = managers.slot:get_mask("bullet_blank_impact_targets")
	self:_create_use_setups()
	self._setup = {}
	self._ammo_max = tweak_data.weapon[self._name_id].AMMO_MAX
	self._ammo_total = self._ammo_max
	self._ammo_max_per_clip = tweak_data.weapon[self._name_id].CLIP_AMMO_MAX
	self._ammo_remaining_in_clip = self._ammo_max_per_clip
	self._damage = tweak_data.weapon[self._name_id].DAMAGE
	self._next_fire_allowed = -1000
	self._obj_fire = self._unit:get_object(Idstring("fire"))
	self._sound_fire = SoundDevice:create_source("fire")
	self._sound_fire:link(self._unit:orientation_object())
	self._muzzle_effect = Idstring(self:weapon_tweak_data().muzzleflash or "effects/particles/test/muzzleflash_maingun")
	self._muzzle_effect_table = {
		effect = self._muzzle_effect,
		parent = self._obj_fire,
		force_synch = false
	}
	self._trail_effect_table = {
		effect = self.TRAIL_EFFECT,
		position = Vector3(),
		normal = Vector3()
	}
	self._flashlight_light_lod_enabled = true
	if self._multivoice then
		if not NPCRaycastWeaponBase._next_i_voice[self._name_id] then
			NPCRaycastWeaponBase._next_i_voice[self._name_id] = 1
		end
		self._voice = NPCRaycastWeaponBase._VOICES[NPCRaycastWeaponBase._next_i_voice[self._name_id]]
		if NPCRaycastWeaponBase._next_i_voice[self._name_id] == #NPCRaycastWeaponBase._VOICES then
			NPCRaycastWeaponBase._next_i_voice[self._name_id] = 1
		else
			NPCRaycastWeaponBase._next_i_voice[self._name_id] = NPCRaycastWeaponBase._next_i_voice[self._name_id] + 1
		end
	else
		self._voice = "a"
	end
	if self._unit:get_object(Idstring("ls_flashlight")) then
		self._flashlight_data = {}
		self._flashlight_data.light = self._unit:get_object(Idstring("ls_flashlight"))
		self._flashlight_data.effect = self._unit:effect_spawner(Idstring("flashlight"))
		self._flashlight_data.light:set_far_range(400)
		self._flashlight_data.light:set_spot_angle_end(25)
		self._flashlight_data.light:set_multiplier(2)
	end
end
function NPCRaycastWeaponBase:setup(setup_data)
	self._autoaim = setup_data.autoaim
	self._alert_events = setup_data.alert_AI and {} or nil
	self._alert_size = tweak_data.weapon[self._name_id].alert_size
	self._alert_fires = {}
	self._bullet_slotmask = setup_data.hit_slotmask or self._bullet_slotmask
	self._character_slotmask = managers.slot:get_mask("raycastable_characters")
	self._hit_player = setup_data.hit_player and true or false
	self._setup = setup_data
end
function NPCRaycastWeaponBase:start_autofire(nr_shots)
	self:_sound_autofire_start(nr_shots)
	self._next_fire_allowed = math.max(self._next_fire_allowed, Application:time())
	self._shooting = true
end
function NPCRaycastWeaponBase:stop_autofire()
	self:_sound_autofire_end()
	self._shooting = nil
end
function NPCRaycastWeaponBase:singleshot(...)
	local fired = self:fire(...)
	if fired then
		self:_sound_singleshot()
	end
	return fired
end
function NPCRaycastWeaponBase:trigger_held(...)
	local fired
	if self._next_fire_allowed <= Application:time() then
		fired = self:fire(...)
		if fired then
			self._next_fire_allowed = self._next_fire_allowed + tweak_data.weapon[self._name_id].auto.fire_rate
		end
	end
	return fired
end
local mto = Vector3()
local mfrom = Vector3()
local mspread = Vector3()
function NPCRaycastWeaponBase:fire_blank(direction, impact)
	local user_unit = self._setup.user_unit
	self._unit:m_position(mfrom)
	local rays = {}
	if impact then
		mvector3.set(mspread, direction)
		mvector3.spread(mspread, 5)
		mvector3.set(mto, mspread)
		mvector3.multiply(mto, 20000)
		mvector3.add(mto, mfrom)
		local col_ray = World:raycast("ray", mfrom, mto, "slot_mask", self._blank_slotmask, "ignore_unit", self._setup.ignore_units)
		self._obj_fire:m_position(self._trail_effect_table.position)
		mvector3.set(self._trail_effect_table.normal, mspread)
		local trail = (not col_ray or col_ray.distance > 650) and World:effect_manager():spawn(self._trail_effect_table) or nil
		if col_ray then
			InstantBulletBase:on_collision(col_ray, self._unit, user_unit, self._damage)
			if trail then
				World:effect_manager():set_remaining_lifetime(trail, math.clamp((col_ray.distance - 600) / 10000, 0, col_ray.distance))
			end
			table.insert(rays, col_ray)
		end
	end
	World:effect_manager():spawn(self._muzzle_effect_table)
	self:_sound_singleshot()
end
function NPCRaycastWeaponBase:destroy(unit)
	RaycastWeaponBase.super.pre_destroy(self, unit)
	if self._shooting then
		self:stop_autofire()
	end
end
function NPCRaycastWeaponBase:_get_spread(user_unit)
end
function NPCRaycastWeaponBase:_sound_autofire_start(nr_shots)
	local tweak_sound = tweak_data.weapon[self._name_id].sounds
	local sound_name = tweak_sound.prefix .. self._setup.user_sound_variant .. self._voice .. (nr_shots and "_" .. tostring(nr_shots) .. "shot" or "_loop")
	local sound = self._sound_fire:post_event(sound_name)
	if not sound then
		sound_name = tweak_sound.prefix .. "1" .. self._voice .. "_end"
		sound = self._sound_fire:post_event(sound_name)
	end
end
function NPCRaycastWeaponBase:_sound_autofire_end()
	local tweak_sound = tweak_data.weapon[self._name_id].sounds
	local sound_name = tweak_sound.prefix .. self._setup.user_sound_variant .. self._voice .. "_end"
	local sound = self._sound_fire:post_event(sound_name)
	if not sound then
		sound_name = tweak_sound.prefix .. "1" .. self._voice .. "_end"
		sound = self._sound_fire:post_event(sound_name)
	end
end
function NPCRaycastWeaponBase:_sound_singleshot()
	local tweak_sound = tweak_data.weapon[self._name_id].sounds
	local sound_name = tweak_sound.prefix .. self._setup.user_sound_variant .. self._voice .. "_1shot"
	local sound = self._sound_fire:post_event(sound_name)
	if not sound then
		sound_name = tweak_sound.prefix .. "1" .. self._voice .. "_1shot"
		sound = self._sound_fire:post_event(sound_name)
	end
end
local mvec_to = Vector3()
function NPCRaycastWeaponBase:_fire_raycast(user_unit, from_pos, direction, dmg_mul, shoot_player)
	local result = {}
	local hit_unit
	mvector3.set(mvec_to, direction)
	mvector3.multiply(mvec_to, 20000)
	mvector3.add(mvec_to, from_pos)
	local damage = self._damage * (dmg_mul or 1)
	local col_ray = World:raycast("ray", from_pos, mvec_to, "slot_mask", self._bullet_slotmask, "ignore_unit", self._setup.ignore_units)
	if col_ray then
		if col_ray.unit:in_slot(self._character_slotmask) then
			hit_unit = InstantBulletBase:on_collision(col_ray, self._unit, user_unit, damage)
		elseif shoot_player and self._hit_player and self:damage_player(col_ray, from_pos, direction) then
			InstantBulletBase:on_hit_player(col_ray, self._unit, user_unit, self._damage * (dmg_mul or 1))
		else
			hit_unit = InstantBulletBase:on_collision(col_ray, self._unit, user_unit, damage)
		end
	elseif shoot_player and self._hit_player then
		local hit, ray_data = self:damage_player(col_ray, from_pos, direction)
		if hit then
			InstantBulletBase:on_hit_player(ray_data, self._unit, user_unit, damage)
		end
	end
	if not col_ray or col_ray.distance > 600 then
		self:_spawn_trail_effect(direction, col_ray)
	end
	result.hit_enemy = hit_unit
	if self._alert_events then
		result.rays = {col_ray}
	end
	return result
end
function NPCRaycastWeaponBase:_spawn_trail_effect(direction, col_ray)
	self._obj_fire:m_position(self._trail_effect_table.position)
	mvector3.set(self._trail_effect_table.normal, direction)
	local trail = World:effect_manager():spawn(self._trail_effect_table)
	if col_ray then
		World:effect_manager():set_remaining_lifetime(trail, math.clamp((col_ray.distance - 600) / 10000, 0, col_ray.distance))
	end
end
function NPCRaycastWeaponBase:has_flashlight_on()
	return self._flashlight_data and self._flashlight_data.on and true or false
end
function NPCRaycastWeaponBase:flashlight_data()
	return self._flashlight_data
end
function NPCRaycastWeaponBase:flashlight_state_changed()
	if not self._flashlight_data then
		return
	end
	if not self._flashlight_data.enabled or self._flashlight_data.dropped then
		return
	end
	if managers.game_play_central:flashlights_on() then
		self._flashlight_data.light:set_enable(self._flashlight_light_lod_enabled)
		self._flashlight_data.effect:activate()
		self._flashlight_data.on = true
	else
		self._flashlight_data.light:set_enable(false)
		self._flashlight_data.effect:kill_effect()
		self._flashlight_data.on = false
	end
end
function NPCRaycastWeaponBase:set_flashlight_enabled(enabled)
	if not self._flashlight_data then
		return
	end
	self._flashlight_data.enabled = enabled
	if managers.game_play_central:flashlights_on() and enabled then
		self._flashlight_data.light:set_enable(self._flashlight_light_lod_enabled)
		self._flashlight_data.effect:activate()
		self._flashlight_data.on = true
	else
		self._flashlight_data.light:set_enable(false)
		self._flashlight_data.effect:kill_effect()
		self._flashlight_data.on = false
	end
end
function NPCRaycastWeaponBase:set_flashlight_light_lod_enabled(enabled)
	if not self._flashlight_data then
		return
	end
	self._flashlight_light_lod_enabled = enabled
	if self._flashlight_data.on and enabled then
		self._flashlight_data.light:set_enable(true)
	else
		self._flashlight_data.light:set_enable(false)
	end
end
