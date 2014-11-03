SentryGunWeapon = SentryGunWeapon or class()
function SentryGunWeapon:init(unit)
	self._unit = unit
	self._timer = TimerManager:game()
	self._name_id = self.name_id
	self.name_id = nil
	local my_tweak_data = tweak_data.weapon[self._name_id]
	self._bullet_slotmask = managers.slot:get_mask(Network:is_server() and "bullet_impact_targets_sentry_gun" or "bullet_blank_impact_targets")
	self._character_slotmask = managers.slot:get_mask("raycastable_characters")
	self._next_fire_allowed = -1000
	self._obj_fire = self._unit:get_object(Idstring("a_detect"))
	self._effect_align = {
		self._unit:get_object(Idstring("fire_left")),
		self._unit:get_object(Idstring("fire_right"))
	}
	self._interleaving_fire = 1
	self._muzzle_effect = Idstring(my_tweak_data.muzzleflash or "effects/particles/test/muzzleflash_maingun")
	self._muzzle_effect_table = {
		{
			effect = self._muzzle_effect,
			parent = self._effect_align[1],
			force_synch = false
		},
		{
			effect = self._muzzle_effect,
			parent = self._effect_align[2],
			force_synch = false
		}
	}
	self._damage = my_tweak_data.DAMAGE
	self._alert_events = {}
	self._alert_size = my_tweak_data.alert_size
	self._alert_fires = {}
	self._trail_effect_table = {
		effect = RaycastWeaponBase.TRAIL_EFFECT,
		position = Vector3(),
		normal = Vector3()
	}
	self._ammo_sync_resolution = 0.2
	if Network:is_server() then
		self._ammo_total = 1
		self._ammo_max = self._ammo_total
		self._ammo_sync = 1
	else
		self._ammo_ratio = 1
	end
end
function SentryGunWeapon:set_ammo(amount)
	self._ammo_total = amount
	self._ammo_max = math.max(self._ammo_max, amount)
end
function SentryGunWeapon:sync_ammo(ammo_ratio)
	self._ammo_ratio = ammo_ratio * self._ammo_sync_resolution * 100
end
function SentryGunWeapon:start_autofire()
	if self._shooting then
		return
	end
	self:_sound_autofire_start()
	self._next_fire_allowed = math.max(self._next_fire_allowed, Application:time())
	self._shooting = true
	self._fire_start_t = self._timer:time()
end
function SentryGunWeapon:stop_autofire()
	if not self._shooting then
		return
	end
	if self:out_of_ammo() then
		self:_sound_autofire_end_empty()
	elseif self._timer:time() - self._fire_start_t > 3 then
		self:_sound_autofire_end_cooldown()
	else
		self:_sound_autofire_end()
	end
	self._shooting = nil
end
function SentryGunWeapon:trigger_held(blanks, expend_ammo)
	local fired
	if self._next_fire_allowed <= self._timer:time() then
		fired = self:fire(blanks, expend_ammo)
		if fired then
			self._next_fire_allowed = self._next_fire_allowed + tweak_data.weapon[self._name_id].auto.fire_rate
			self._interleaving_fire = self._interleaving_fire == 1 and 2 or 1
		end
	end
	return fired
end
function SentryGunWeapon:fire(blanks, expend_ammo)
	if expend_ammo then
		if self._ammo_total <= 0 then
			return
		end
		self._ammo_total = self._ammo_total - 1
		local ammo_percent = self._ammo_total / self._ammo_max
		if ammo_percent == 0 or math.abs(ammo_percent - self._ammo_sync) >= self._ammo_sync_resolution then
			self._ammo_sync = ammo_percent
			self._unit:network():send("sentrygun_ammo", math.ceil(ammo_percent / self._ammo_sync_resolution))
		end
	end
	local fire_obj = self._effect_align[self._interleaving_fire]
	local from_pos = fire_obj:position()
	local direction = fire_obj:rotation():y()
	mvector3.negate(direction)
	mvector3.spread(direction, tweak_data.weapon[self._name_id].SPREAD * math.random())
	World:effect_manager():spawn(self._muzzle_effect_table[self._interleaving_fire])
	local ray_res = self:_fire_raycast(from_pos, direction, blanks)
	if self._alert_events and ray_res.rays then
		RaycastWeaponBase._check_alert(self, ray_res.rays, from_pos, direction, self._unit)
	end
	return ray_res
end
local mvec_to = Vector3()
function SentryGunWeapon:_fire_raycast(from_pos, direction, shoot_player)
	local result = {}
	local hit_unit
	mvector3.set(mvec_to, direction)
	mvector3.multiply(mvec_to, tweak_data.weapon[self._name_id].FIRE_RANGE)
	mvector3.add(mvec_to, from_pos)
	local col_ray = World:raycast("ray", from_pos, mvec_to, "slot_mask", self._bullet_slotmask)
	if col_ray then
		if col_ray.unit:in_slot(self._character_slotmask) then
			hit_unit = InstantBulletBase:on_collision(col_ray, self._unit, self._unit, self._damage)
		else
			hit_unit = InstantBulletBase:on_collision(col_ray, self._unit, self._unit, self._damage)
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
function SentryGunWeapon:_sound_autofire_start()
	self._autofire_sound_event = self._unit:sound_source():post_event("turret_fire")
end
function SentryGunWeapon:_sound_autofire_end()
	if self._autofire_sound_event then
		self._autofire_sound_event:stop()
		self._autofire_sound_event = nil
	end
	self._unit:sound_source():post_event("turret_fire_end")
end
function SentryGunWeapon:_sound_autofire_end_empty()
	if self._autofire_sound_event then
		self._autofire_sound_event:stop()
		self._autofire_sound_event = nil
	end
	self._unit:sound_source():post_event("turret_ammo_depleted")
end
function SentryGunWeapon:_sound_autofire_end_cooldown()
	if self._autofire_sound_event then
		self._autofire_sound_event:stop()
		self._autofire_sound_event = nil
	end
	self._unit:sound_source():post_event("turret_fire_end")
	self._unit:sound_source():post_event("turret_cooldown")
end
function SentryGunWeapon:_spawn_trail_effect(direction, col_ray)
	self._effect_align[self._interleaving_fire]:m_position(self._trail_effect_table.position)
	mvector3.set(self._trail_effect_table.normal, direction)
	local trail = World:effect_manager():spawn(self._trail_effect_table)
	if col_ray then
		World:effect_manager():set_remaining_lifetime(trail, math.clamp((col_ray.distance - 600) / 10000, 0, col_ray.distance))
	end
end
function SentryGunWeapon:out_of_ammo()
	if self._ammo_total then
		return self._ammo_total == 0
	else
		return self._ammo_ratio == 0
	end
end
