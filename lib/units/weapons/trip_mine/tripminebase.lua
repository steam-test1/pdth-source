TripMineBase = TripMineBase or class(UnitBase)
function TripMineBase.spawn(pos, rot)
	local unit = World:spawn_unit(Idstring("units/weapons/trip_mine/trip_mine"), pos, rot)
	return unit
end
function TripMineBase:set_server_information(peer_id)
	self._server_information = {owner_peer_id = peer_id}
	managers.network:game():member(peer_id):peer():set_used_deployable(true)
end
function TripMineBase:server_information()
	return self._server_information
end
function TripMineBase:init(unit)
	UnitBase.init(self, unit, false)
	self._unit = unit
	self._position = self._unit:position()
	self._rotation = self._unit:rotation()
	self._forward = self._rotation:y()
	self._ray_from_pos = Vector3()
	self._ray_to_pos = Vector3()
	self._ids_laser = Idstring("laser")
	self._g_laser = self._unit:get_object(Idstring("g_laser"))
	self:_setup()
end
function TripMineBase:get_name_id()
	return "trip_mine"
end
function TripMineBase:_setup()
	self._slotmask = managers.slot:get_mask("trip_mine_targets")
	self._init_length = 500
	self._first_armed = false
	self._armed = false
	self:set_active(false)
	self._unit:sound_source():post_event("trip_mine_attach")
end
function TripMineBase:set_active(active, owner)
	self._active = active
	self._unit:set_extension_update_enabled(Idstring("base"), self._active)
	if self._active then
		self._owner = owner
		self._owner_peer_id = managers.network:session():local_peer():id()
		local from_pos = self._unit:position() + self._unit:rotation():y() * 10
		local to_pos = from_pos + self._unit:rotation():y() * self._init_length
		local ray = self._unit:raycast("ray", from_pos, to_pos, "slot_mask", managers.slot:get_mask("world_geometry"))
		self._length = math.clamp(ray and ray.distance + 10 or self._init_length, 0, self._init_length)
		self._unit:anim_set_time(self._ids_laser, self._length / self._init_length)
		self._activate_timer = 3
		mvector3.set(self._ray_from_pos, self._position)
		mvector3.set(self._ray_to_pos, self._forward)
		mvector3.multiply(self._ray_to_pos, self._length)
		mvector3.add(self._ray_to_pos, self._ray_from_pos)
		local from_pos = self._unit:position() + self._unit:rotation():y() * 10
		local to_pos = self._unit:position() + self._unit:rotation():y() * -10
		local ray = self._unit:raycast("ray", from_pos, to_pos, "slot_mask", managers.slot:get_mask("world_geometry"))
		if ray then
			self._attached_data = {}
			self._attached_data.body = ray.body
			self._attached_data.position = ray.body:position()
			self._attached_data.rotation = ray.body:rotation()
			self._attached_data.index = 1
			self._attached_data.max_index = 3
		end
	end
end
function TripMineBase:active()
	return self._active
end
function TripMineBase:armed()
	return self._armed
end
function TripMineBase:_set_armed(armed)
	self._armed = armed
	self._g_laser:set_visibility(self._armed)
	if not self._first_armed then
		self._first_armed = true
		self._unit:sound_source():post_event("trip_mine_beep_armed")
	end
	self._unit:sound_source():post_event(self._armed and "trip_mine_arm" or "trip_mine_disarm")
end
function TripMineBase:set_armed(armed)
	if not managers.network:session() then
		return
	end
	self:_set_armed(armed)
	if managers.network:session() then
		managers.network:session():send_to_peers_synched("sync_trip_mine_set_armed", self._unit, self._armed, self._length)
	end
end
function TripMineBase:sync_trip_mine_set_armed(armed, lenght)
	self._length = lenght
	self._unit:anim_set_time(self._ids_laser, lenght / self._init_length)
	self:_set_armed(armed)
end
function TripMineBase:update(unit, t, dt)
	self:_check_body()
	if self._explode_timer then
		self._explode_timer = self._explode_timer - dt
		if self._explode_timer <= 0 then
			self:_explode(self._explode_ray)
			return
		end
	end
	if self._activate_timer then
		self._activate_timer = self._activate_timer - dt
		if 0 >= self._activate_timer then
			self:set_armed(true)
			self._activate_timer = nil
		end
		return
	end
	if self._deactive_timer then
		self._deactive_timer = self._deactive_timer - dt
		if 0 >= self._deactive_timer then
			self._deactive_timer = nil
		end
		return
	end
	if not self._armed then
		return
	end
	if not self._explode_timer then
		self:_check()
	end
end
function TripMineBase:_check_body()
	if not self._attached_data then
		return
	end
	if self._attached_data.index == 1 then
		if not alive(self._attached_data.body) or not self._attached_data.body:enabled() then
			self:explode()
		end
	elseif self._attached_data.index == 2 then
		if not alive(self._attached_data.body) or not mrotation.equal(self._attached_data.rotation, self._attached_data.body:rotation()) then
			self:explode()
		end
	elseif self._attached_data.index == 3 and (not alive(self._attached_data.body) or mvector3.not_equal(self._attached_data.position, self._attached_data.body:position())) then
		self:explode()
	end
	self._attached_data.index = (self._attached_data.index < self._attached_data.max_index and self._attached_data.index or 0) + 1
end
function TripMineBase:_check()
	if not managers.network:session() then
		return
	end
	local ray = self._unit:raycast("ray", self._ray_from_pos, self._ray_to_pos, "slot_mask", self._slotmask, "ray_type", "trip_mine body")
	if ray and ray.unit and not tweak_data.character[ray.unit:base()._tweak_table].is_escort then
		self._explode_timer = tweak_data.weapon.trip_mines.delay
		self._explode_ray = ray
		self._unit:sound_source():post_event("trip_mine_beep_explode")
		if managers.network:session() then
			managers.network:session():send_to_peers_synched("sync_trip_mine_beep_explode", self._unit)
		end
	end
end
function TripMineBase:sync_trip_mine_beep_explode()
	self._unit:sound_source():post_event("trip_mine_beep_explode")
end
function TripMineBase:explode()
	if not self._active then
		return
	end
	self._active = false
	local col_ray = {}
	col_ray.ray = self._forward
	col_ray.position = self._position
	self:_explode(col_ray)
end
function TripMineBase:_explode(col_ray)
	if not managers.network:session() then
		return
	end
	local player = managers.player:player_unit()
	if alive(player) then
		player:character_damage():damage_explosion({
			position = self._position,
			range = 500,
			damage = 6
		})
	else
		player = nil
	end
	self._unit:set_extension_update_enabled(Idstring("base"), false)
	self._deactive_timer = 5
	self:_play_sound_and_effects()
	local slotmask = managers.slot:get_mask("bullet_impact_targets")
	local damage_size = tweak_data.weapon.trip_mines.damage_size * managers.player:upgrade_value("trip_mine", "damage_multiplier", 1)
	local bodies = World:find_bodies("intersect", "cylinder", self._ray_from_pos, self._ray_to_pos, damage_size, slotmask)
	local damage = tweak_data.weapon.trip_mines.damage * managers.player:upgrade_value("trip_mine", "damage_multiplier", 1)
	local amount = 0
	local characters_hit = {}
	for _, hit_body in ipairs(bodies) do
		local character = hit_body:unit():character_damage() and hit_body:unit():character_damage().damage_explosion
		local apply_dmg = hit_body:extension() and hit_body:extension().damage
		local dir, ray_hit
		if character and not characters_hit[hit_body:unit():key()] then
			local com = hit_body:center_of_mass()
			local ray_from = math.point_on_line(self._ray_from_pos, self._ray_to_pos, com)
			ray_hit = not World:raycast("ray", ray_from, com, "slot_mask", slotmask, "ignore_unit", {
				hit_body:unit()
			}, "report")
			if ray_hit then
				characters_hit[hit_body:unit():key()] = true
			end
		elseif apply_dmg or hit_body:dynamic() then
			ray_hit = true
		end
		if ray_hit then
			dir = hit_body:center_of_mass()
			mvector3.direction(dir, self._ray_from_pos, dir)
			if apply_dmg then
				local normal = dir
				hit_body:extension().damage:damage_explosion(player, normal, hit_body:position(), dir, damage)
				hit_body:extension().damage:damage_damage(player, normal, hit_body:position(), dir, damage)
				if hit_body:unit():id() ~= -1 then
					if player then
						managers.network:session():send_to_peers_synched("sync_body_damage_explosion", hit_body, player, normal, hit_body:position(), dir, damage)
					else
						managers.network:session():send_to_peers_synched("sync_body_damage_explosion_no_attacker", hit_body, normal, hit_body:position(), dir, damage)
					end
				end
			end
			if hit_body:unit():in_slot(managers.game_play_central._slotmask_physics_push) then
				hit_body:unit():push(5, dir * 500)
			end
			if character then
				self:_give_explosion_damage(col_ray, hit_body:unit(), damage)
				amount = amount + 1
			end
		end
	end
	if 2 <= amount then
		managers.challenges:count_up("dual_tripmine")
	end
	if 3 <= amount then
		managers.challenges:count_up("tris_tripmine")
	end
	if 4 <= amount then
		managers.challenges:count_up("quad_tripmine")
	end
	if managers.network:session() then
		if player then
			managers.network:session():send_to_peers_synched("sync_trip_mine_explode", self._unit, player, self._ray_from_pos, self._ray_to_pos, damage_size, damage)
		else
			managers.network:session():send_to_peers_synched("sync_trip_mine_explode_no_user", self._unit, self._ray_from_pos, self._ray_to_pos, damage_size, damage)
		end
	end
	if Network:is_server() then
		local alert_event = {
			"bulletfired",
			mvector3.copy(self._position),
			tweak_data.weapon.trip_mines.alert_radius,
			self._unit
		}
		managers.groupai:state():propagate_alert(alert_event)
	end
	self._unit:set_slot(0)
end
function TripMineBase:sync_trip_mine_explode(user_unit, ray_from, ray_to, damage_size, damage)
	self:_play_sound_and_effects()
	self._unit:set_slot(0)
	local bodies = World:find_bodies("intersect", "cylinder", ray_from, ray_to, damage_size, managers.slot:get_mask("bullet_impact_targets"))
	for _, hit_body in ipairs(bodies) do
		local apply_dmg = hit_body:extension() and hit_body:extension().damage
		local dir
		if apply_dmg or hit_body:dynamic() then
			dir = hit_body:center_of_mass()
			mvector3.direction(dir, ray_from, dir)
			if apply_dmg then
				local normal = dir
				if hit_body:unit():id() == -1 then
					hit_body:extension().damage:damage_explosion(user_unit, normal, hit_body:position(), dir, damage)
					hit_body:extension().damage:damage_damage(user_unit, normal, hit_body:position(), dir, damage)
				end
			end
			if hit_body:unit():in_slot(managers.game_play_central._slotmask_physics_push) then
				hit_body:unit():push(5, dir * 500)
			end
		end
	end
end
function TripMineBase:_play_sound_and_effects()
	World:effect_manager():spawn({
		effect = Idstring("effects/particles/explosions/explosion_grenade"),
		position = self._unit:position(),
		normal = self._unit:rotation():y()
	})
	local sound_source = SoundDevice:create_source("TripMineBase")
	sound_source:set_position(self._unit:position())
	sound_source:post_event("trip_mine_explode")
	managers.enemy:add_delayed_clbk("TrMiexpl", callback(TripMineBase, TripMineBase, "_dispose_of_sound", {sound_source = sound_source}), TimerManager:game():time() + 2)
end
function TripMineBase._dispose_of_sound(...)
end
function TripMineBase:_give_explosion_damage(col_ray, unit, damage)
	local action_data = {}
	action_data.variant = "explosion"
	action_data.damage = damage
	action_data.weapon_unit = self._unit
	action_data.attacker_unit = managers.player:player_unit()
	action_data.col_ray = col_ray
	action_data.owner = managers.player:player_unit()
	action_data.owner_peer_id = self._owner_peer_id
	local defense_data = unit:character_damage():damage_explosion(action_data)
	return defense_data
end
function TripMineBase:save(data)
	local state = {}
	state.armed = self._armed
	state.length = self._length
	state.first_armed = self._first_armed
	data.TripMineBase = state
end
function TripMineBase:load(data)
	local state = data.TripMineBase
	self._first_armed = state.first_armed
	self:sync_trip_mine_set_armed(state.armed, state.length)
end
function TripMineBase:_debug_draw(from, to)
	local brush = Draw:brush(Color.red:with_alpha(0.5))
	brush:cylinder(from, to, 1)
end
function TripMineBase:destroy()
end
