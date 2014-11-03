M79GrenadeBase = M79GrenadeBase or class()
function M79GrenadeBase.spawn(unit_name, pos, rot)
	local unit = World:spawn_unit(Idstring(unit_name), pos, rot)
	return unit
end
function M79GrenadeBase:init(unit)
	self._unit = unit
	self._new_pos = unit:position()
	self._collision_slotmask = managers.slot:get_mask("bullet_impact_targets")
	self._spawn_pos = unit:position()
	self._hidden = true
	self._unit:set_visible(false)
end
function M79GrenadeBase:launch(params)
	self._owner = params.owner
	self._user = params.user
	self._damage = params.damage
	self._range = params.range
	self._curve_pow = params.curve_pow
	self._velocity = params.dir * 4000
	self._last_pos = self._unit:position()
	self._last_last_pos = mvector3.copy(self._last_pos)
	self._upd_interval = 0.1
	self._last_upd_t = TimerManager:game():time()
	self._next_upd_t = self._last_upd_t + self._upd_interval
	self._auto_explode_t = self._last_upd_t + 3
end
function M79GrenadeBase:update(unit, t, dt)
	if t > self._auto_explode_t then
		self:_detonate()
		return
	end
	if t < self._next_upd_t then
		return
	end
	local dt = t - self._last_upd_t
	mvector3.set(self._last_last_pos, self._last_pos)
	mvector3.set(self._last_pos, self._new_pos)
	self:_upd_velocity(dt)
	if self:_chk_collision() then
		self:_detonate()
		return
	end
	self:_upd_position()
	if self._hidden then
		local safe_dis_sq = 120
		safe_dis_sq = safe_dis_sq * safe_dis_sq
		if safe_dis_sq < mvector3.distance_sq(self._spawn_pos, self._last_pos) then
			self._hidden = false
			self._unit:set_visible(true)
		end
	end
	self._last_upd_t = t
	self._next_upd_t = t + self._upd_interval
end
function M79GrenadeBase:_upd_velocity(dt)
	local new_vel_z = mvector3.z(self._velocity) - dt * 981
	mvector3.set_z(self._velocity, new_vel_z)
	mvector3.set(self._new_pos, self._velocity)
	mvector3.multiply(self._new_pos, dt)
	mvector3.add(self._new_pos, self._last_pos)
end
function M79GrenadeBase:_upd_position()
	self._unit:set_position(self._new_pos)
end
function M79GrenadeBase:_chk_collision()
	local col_ray = World:raycast("ray", self._last_pos, self._new_pos, "slot_mask", self._collision_slotmask)
	col_ray = col_ray or World:raycast("ray", self._last_last_pos, self._new_pos, "slot_mask", self._collision_slotmask)
	if col_ray then
		self._col_ray = col_ray
		return true
	end
end
function M79GrenadeBase:_detonate()
	if self._detonated then
		debug_pause("[M79GrenadeBase:_detonate] grenade has already detonated", self._unit, alive(self._unit) and self._unit:slot())
		if self._unit:slot() == 0 then
			self._unit:set_slot(14)
		end
		self._unit:set_slot(0)
		return
	end
	self._detonated = true
	local expl_normal = mvector3.copy(self._velocity)
	mvector3.negate(expl_normal)
	mvector3.normalize(expl_normal)
	local expl_pos = mvector3.copy(expl_normal)
	mvector3.multiply(expl_pos, 30)
	if self._col_ray then
		mvector3.add(expl_pos, self._col_ray.position)
	else
		mvector3.add(expl_pos, self._new_pos)
	end
	M79GrenadeBase._play_sound_and_effects(expl_pos, expl_normal)
	self._unit:set_slot(0)
	if not alive(self._owner) or not alive(self._user) then
		return
	end
	managers.network:session():send_to_peers_synched("m79grenade_explode_on_client", expl_pos, expl_normal, self._user, self._damage, self._range, self._curve_pow)
	self:_detect_and_give_dmg(expl_pos)
end
function M79GrenadeBase:_detect_and_give_dmg(hit_pos)
	local slotmask = self._collision_slotmask
	local user_unit = self._user
	local dmg = self._damage
	local range = self._range
	local player = managers.player:player_unit()
	if alive(player) then
		player:character_damage():damage_explosion({
			position = hit_pos,
			range = range,
			damage = 9
		})
	end
	local bodies = World:find_bodies("intersect", "sphere", hit_pos, range, slotmask)
	managers.groupai:state():propagate_alert({
		"bulletfired",
		hit_pos,
		10000,
		user_unit
	})
	local splinters = {
		mvector3.copy(hit_pos)
	}
	local dirs = {
		Vector3(range, 0, 0),
		Vector3(-range, 0, 0),
		Vector3(0, range, 0),
		Vector3(0, -range, 0),
		Vector3(0, 0, range),
		Vector3(0, 0, -range)
	}
	local pos = Vector3()
	for _, dir in ipairs(dirs) do
		mvector3.set(pos, dir)
		mvector3.add(pos, hit_pos)
		local splinter_ray = World:raycast("ray", hit_pos, pos, "slot_mask", slotmask)
		pos = (splinter_ray and splinter_ray.position or pos) - dir:normalized() * math.min(splinter_ray and splinter_ray.distance or 0, 10)
		local near_splinter = false
		for _, s_pos in ipairs(splinters) do
			if mvector3.distance_sq(pos, s_pos) < 900 then
				near_splinter = true
			else
			end
		end
		if not near_splinter then
			table.insert(splinters, mvector3.copy(pos))
		end
	end
	local characters_hit = {}
	local units_to_push = {}
	for _, hit_body in ipairs(bodies) do
		local character = hit_body:unit():character_damage() and hit_body:unit():character_damage().damage_explosion
		local apply_dmg = hit_body:extension() and hit_body:extension().damage
		local tmp_vec3 = Vector3()
		units_to_push[hit_body:unit():key()] = hit_body:unit()
		local dir, len, damage, ray_hit
		if character and not characters_hit[hit_body:unit():key()] then
			for i_splinter, s_pos in ipairs(splinters) do
				ray_hit = not World:raycast("ray", s_pos, hit_body:center_of_mass(), "slot_mask", slotmask, "ignore_unit", {
					hit_body:unit()
				}, "report")
				if ray_hit then
					characters_hit[hit_body:unit():key()] = true
				else
				end
			end
		elseif apply_dmg or hit_body:dynamic() then
			ray_hit = true
		end
		if ray_hit then
			dir = hit_body:center_of_mass()
			len = mvector3.direction(dir, hit_pos, dir)
			damage = dmg * math.pow(math.clamp(1 - len / range, 0, 1), self._curve_pow)
			damage = math.max(damage, 1)
			local hit_unit = hit_body:unit()
			if apply_dmg then
				local normal = dir
				hit_body:extension().damage:damage_explosion(user_unit, normal, hit_body:position(), dir, damage)
				hit_body:extension().damage:damage_damage(user_unit, normal, hit_body:position(), dir, damage)
				if hit_unit:id() ~= -1 then
					managers.network:session():send_to_peers_synched("sync_body_damage_explosion", hit_body, user_unit, normal, hit_body:position(), dir, damage)
				end
			end
			if character then
				local action_data = {}
				action_data.variant = "explosion"
				action_data.damage = damage
				action_data.attacker_unit = user_unit
				action_data.weapon_unit = self._owner
				action_data.col_ray = self._col_ray or {
					position = hit_body:position(),
					ray = dir
				}
				hit_unit:character_damage():damage_explosion(action_data)
			end
		end
	end
	for u_key, unit in pairs(units_to_push) do
		if alive(unit) then
			local is_character = unit:character_damage() and unit:character_damage().damage_explosion
			local tmp_vec3 = Vector3()
			if not is_character or unit:character_damage():dead() then
				if is_character and unit:movement()._active_actions[1] and unit:movement()._active_actions[1]:type() == "hurt" then
					unit:movement()._active_actions[1]:force_ragdoll()
				end
				local nr_u_bodies = unit:num_bodies()
				local i_u_body = 0
				while nr_u_bodies > i_u_body do
					local u_body = unit:body(i_u_body)
					if u_body:enabled() and u_body:dynamic() then
						local body_mass = u_body:mass()
						local len = mvector3.direction(tmp_vec3, hit_pos, u_body:center_of_mass())
						local body_vel = u_body:velocity()
						local vel_dot = mvector3.dot(body_vel, tmp_vec3)
						local max_vel = 800
						if vel_dot < max_vel then
							local push_vel = (1 - len / range) * (max_vel - math.max(vel_dot, 0))
							mvector3.multiply(tmp_vec3, push_vel)
							u_body:push(body_mass, tmp_vec3)
						end
					end
					i_u_body = i_u_body + 1
				end
			end
		end
	end
	managers.challenges:reset_counter("m79_law_simultaneous_kills")
	managers.challenges:reset_counter("m79_simultaneous_specials")
	managers.statistics:shot_fired({
		hit = next(characters_hit) and true or false,
		weapon_unit = self._owner
	})
end
function M79GrenadeBase._explode_on_client(position, normal, user_unit, dmg, range, curve_pow)
	M79GrenadeBase._play_sound_and_effects(position, normal)
	local bodies = World:find_bodies("intersect", "sphere", position, range, managers.slot:get_mask("bullet_impact_targets"))
	for _, hit_body in ipairs(bodies) do
		local apply_dmg = hit_body:extension() and hit_body:extension().damage
		local dir, len, damage
		if apply_dmg or hit_body:dynamic() then
			dir = hit_body:center_of_mass()
			len = mvector3.direction(dir, position, dir)
			damage = dmg * math.pow(math.clamp(1 - len / range, 0, 1), curve_pow)
			damage = math.max(damage, 1)
			if apply_dmg then
				local normal = dir
				if hit_body:unit():id() == -1 then
					hit_body:extension().damage:damage_explosion(user_unit, normal, hit_body:position(), dir, damage)
					hit_body:extension().damage:damage_damage(user_unit, normal, hit_body:position(), dir, damage)
				end
			end
			if hit_body:unit():in_slot(managers.game_play_central._slotmask_physics_push) then
				hit_body:unit():push(5, dir * 1000 * (1 - len / range))
			end
		end
	end
end
function M79GrenadeBase._play_sound_and_effects(position, normal)
	local player = managers.player:player_unit()
	if player then
		local feedback = managers.feedback:create("mission_triggered")
		local distance = mvector3.distance_sq(position, player:position())
		local mul = math.clamp(1 - distance / 9000000, 0, 1)
		feedback:set_unit(player)
		feedback:set_enabled("camera_shake", true)
		feedback:set_enabled("rumble", true)
		feedback:set_enabled("above_camera_effect", false)
		local params = {
			"camera_shake",
			"multiplier",
			mul,
			"camera_shake",
			"amplitude",
			0.5,
			"camera_shake",
			"attack",
			0.05,
			"camera_shake",
			"sustain",
			0.15,
			"camera_shake",
			"decay",
			0.5,
			"rumble",
			"multiplier_data",
			mul,
			"rumble",
			"peak",
			0.5,
			"rumble",
			"attack",
			0.05,
			"rumble",
			"sustain",
			0.15,
			"rumble",
			"release",
			0.5
		}
		feedback:play(unpack(params))
	end
	World:effect_manager():spawn({
		effect = Idstring("effects/particles/explosions/explosion_grenade_launcher"),
		position = position,
		normal = normal
	})
	local sound_source = SoundDevice:create_source("M79GrenadeBase")
	sound_source:set_position(position)
	sound_source:post_event("trip_mine_explode")
	managers.enemy:add_delayed_clbk("M79expl", callback(M79GrenadeBase, M79GrenadeBase, "_dispose_of_sound", {sound_source = sound_source}), TimerManager:game():time() + 2)
end
function M79GrenadeBase._dispose_of_sound(...)
end
