ShotgunBase = ShotgunBase or class(RaycastWeaponBase)
function ShotgunBase:init(...)
	ShotgunBase.super.init(self, ...)
	self._damage_near = tweak_data.weapon[self._name_id].damage_near
	self._damage_far = tweak_data.weapon[self._name_id].damage_far
	self._range = self._damage_far
end
function ShotgunBase:_create_use_setups()
	local use_data = {}
	local player_setup = {}
	player_setup.selection_index = tweak_data.weapon[self._name_id].use_data.selection_index
	player_setup.equip = {align_place = "left_hand"}
	player_setup.unequip = {align_place = "back"}
	use_data.player = player_setup
	self._use_data = use_data
end
function ShotgunBase:_fire_raycast(user_unit, from_pos, direction)
	local result = {}
	local hit_enemies = {}
	local hit_something, col_rays
	if self._alert_events then
		col_rays = {}
	end
	local damage = self._damage
	local autoaim, dodge_enemies = self:check_autoaim(from_pos, direction, self._range)
	local weight = 0.1
	local enemy_died = false
	local function hit_enemy(col_ray)
		if col_ray.unit:character_damage() and col_ray.unit:character_damage().is_head then
			local enemy_key = col_ray.unit:key()
			if not hit_enemies[enemy_key] or col_ray.unit:character_damage():is_head(col_ray.body) then
				hit_enemies[enemy_key] = col_ray
			end
		else
			InstantBulletBase:on_collision(col_ray, self._unit, user_unit, self._damage)
		end
	end
	for i = 1, 6 do
		local spread_direction = direction:spread(self:_get_spread(user_unit))
		local ray_to = mvector3.copy(spread_direction)
		mvector3.multiply(ray_to, self._range)
		mvector3.add(ray_to, from_pos)
		local col_ray = World:raycast("ray", from_pos, ray_to, "slot_mask", self._bullet_slotmask, "ignore_unit", self._setup.ignore_units)
		if col_rays then
			if col_ray then
				table.insert(col_rays, col_ray)
			else
				table.insert(col_rays, {position = ray_to, ray = spread_direction})
			end
		end
		if self._autoaim and autoaim then
			if col_ray and col_ray.unit:in_slot(managers.slot:get_mask("enemies")) then
				self._autohit_current = (self._autohit_current + weight) / (1 + weight)
				hit_enemy(col_ray)
				autoaim = false
			else
				autoaim = false
				local autohit = self:check_autoaim(from_pos, direction, self._range)
				if autohit then
					local autohit_chance = 1 - math.clamp((self._autohit_current - self._autohit_data.MIN_RATIO) / (self._autohit_data.MAX_RATIO - self._autohit_data.MIN_RATIO), 0, 1)
					if autohit_chance > math.random() then
						self._autohit_current = (self._autohit_current + weight) / (1 + weight)
						hit_something = true
						hit_enemy(autohit)
					else
						self._autohit_current = self._autohit_current / (1 + weight)
					end
				elseif col_ray then
					hit_something = true
					hit_enemy(col_ray)
				end
			end
		elseif col_ray then
			hit_something = true
			hit_enemy(col_ray)
		end
	end
	for _, col_ray in pairs(hit_enemies) do
		local dist = mvector3.distance(col_ray.unit:position(), user_unit:position())
		local damage = (1 - math.min(1, math.max(0, dist - self._damage_near) / self._damage_far)) * self._damage
		InstantBulletBase:on_collision(col_ray, self._unit, user_unit, damage)
	end
	result.hit_enemy = next(hit_enemies) and true or false
	result.rays = 0 < #col_rays and col_rays
	managers.statistics:shot_fired({
		hit = result.hit_enemy,
		weapon_unit = self._unit
	})
	return result
end
function ShotgunBase:reload_expire_t()
	return math.min(self._ammo_total - self._ammo_remaining_in_clip, self._ammo_max_per_clip - self._ammo_remaining_in_clip) * 20 / 30
end
function ShotgunBase:reload_enter_expire_t()
	return 0.4
end
function ShotgunBase:reload_exit_expire_t()
	return 1.3
end
function ShotgunBase:reload_not_empty_exit_expire_t()
	return 1
end
function ShotgunBase:start_reload(...)
	ShotgunBase.super.start_reload(self, ...)
	self._started_reload_empty = self:clip_empty()
	local speed_multiplier = self:reload_speed_multiplier()
	self._next_shell_reloded_t = Application:time() + 0.33666667 / speed_multiplier
end
function ShotgunBase:started_reload_empty()
	return self._started_reload_empty
end
function ShotgunBase:update_reloading(t, dt, time_left)
	if t > self._next_shell_reloded_t then
		local speed_multiplier = self:reload_speed_multiplier()
		self._next_shell_reloded_t = self._next_shell_reloded_t + 0.6666667 / speed_multiplier
		self._ammo_remaining_in_clip = math.min(self._ammo_max_per_clip, self._ammo_remaining_in_clip + 1)
		return true
	end
end
function ShotgunBase:reload_interuptable()
	return true
end
