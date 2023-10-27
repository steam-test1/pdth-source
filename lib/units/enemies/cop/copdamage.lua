CopDamage = CopDamage or class()
CopDamage._all_event_types = {
	"light_hurt",
	"hurt",
	"heavy_hurt",
	"death"
}
function CopDamage:init(unit)
	self._unit = unit
	local char_tweak = tweak_data.character[unit:base()._tweak_table]
	self._HEALTH_INIT = char_tweak.HEALTH_INIT
	self._health = self._HEALTH_INIT
	self._health_ratio = self._health / self._HEALTH_INIT
	self._HEALTH_INIT_PRECENT = self._HEALTH_INIT / 100
	self._autotarget_data = {
		fast = unit:get_object(Idstring("Spine1"))
	}
	self._pickup = "ammo"
	self._listener_holder = EventListenerHolder:new()
	if char_tweak.permanently_invulnerable or self.immortal then
		self:set_invulnerable(true)
	end
	self._char_tweak = char_tweak
	self._spine2_obj = unit:get_object(Idstring("Spine2"))
	if self._head_body_name then
		self._ids_head_body_name = Idstring(self._head_body_name)
		self._head_body_key = self._unit:body(self._head_body_name):key()
	end
	local body = self._unit:body("mover_blocker")
	if body then
		body:add_ray_type(Idstring("trip_mine"))
	end
end
function CopDamage.get_damage_type(hurt_table, damage_percent)
	local dmg = damage_percent / 100
	if dmg < hurt_table[1] then
		return nil
	elseif dmg < hurt_table[2] then
		return "light_hurt"
	elseif dmg > hurt_table[4] then
		return "heavy_hurt"
	end
	local r = math.rand(0, 1)
	if dmg < hurt_table[3] then
		return r < (dmg - hurt_table[2]) / (hurt_table[3] - hurt_table[2]) and "hurt" or "light_hurt"
	else
		return r < (dmg - hurt_table[3]) / (hurt_table[4] - hurt_table[3]) and "heavy_hurt" or "hurt"
	end
end
function CopDamage:dodge(hipshot)
	if self._dead or self._invulnerable or self._unit:movement():chk_action_forbidden("walk") then
		return
	end
	return self._unit:brain()._current_logic.dodge(self._unit:brain()._logic_data, hipshot)
end
function CopDamage:is_head(body)
	local head = self._head_body_name and body and body:name() == self._ids_head_body_name
	return head
end
function CopDamage:damage_bullet(attack_data)
	if self._dead or self._invulnerable then
		return
	end
	local result
	local body_index = self._unit:get_body_index(attack_data.col_ray.body:name())
	local head = self._head_body_name and attack_data.col_ray.body and attack_data.col_ray.body:name() == self._ids_head_body_name
	local damage = attack_data.damage
	if head then
		if self._char_tweak.headshot_dmg_mul then
			damage = damage * self._char_tweak.headshot_dmg_mul
		else
			damage = self._health * 10
		end
	end
	local damage_percent = math.ceil(math.clamp(damage / self._HEALTH_INIT_PRECENT, 1, 100))
	damage = damage_percent * self._HEALTH_INIT_PRECENT
	if damage >= self._health then
		if head then
			self:_spawn_head_gadget({
				position = attack_data.col_ray.body:position(),
				rotation = attack_data.col_ray.body:rotation(),
				dir = attack_data.col_ray.ray
			})
		end
		attack_data.damage = self._health
		result = {
			type = "death",
			variant = attack_data.variant
		}
		self:die(attack_data.variant)
	else
		attack_data.damage = damage
		local result_type = CopDamage.get_damage_type(self._char_tweak.damage.hurt_severity, damage_percent)
		result = {
			type = result_type,
			variant = attack_data.variant
		}
		self._health = self._health - damage
		self._health_ratio = self._health / self._HEALTH_INIT
	end
	attack_data.result = result
	attack_data.pos = attack_data.col_ray.position
	if result.type == "death" then
		local data = {
			name = self._unit:base()._tweak_table,
			head_shot = head,
			weapon_unit = attack_data.weapon_unit,
			variant = attack_data.variant
		}
		if managers.groupai:state():all_criminals()[attack_data.attacker_unit:key()] then
			managers.statistics:killed_by_anyone(data)
		end
		if attack_data.attacker_unit == managers.player:player_unit() then
			self:_comment_death(attack_data.attacker_unit, self._unit:base()._tweak_table)
			self:_show_death_hint(self._unit:base()._tweak_table)
			local attacker_state = managers.player:current_state()
			data.attacker_state = attacker_state
			managers.statistics:killed(data)
		elseif attack_data.attacker_unit:in_slot(managers.slot:get_mask("criminals_no_deployables")) then
			self:_AI_comment_death(attack_data.attacker_unit, self._unit:base()._tweak_table)
		elseif attack_data.attacker_unit:base().sentry_gun and Network:is_server() then
			local server_info = attack_data.weapon_unit:base():server_information()
			if server_info and server_info.owner_peer_id ~= managers.network:session():local_peer():id() then
				local owner_peer = managers.network:session():peer(server_info.owner_peer_id)
				if owner_peer then
					owner_peer:send_queued_sync("sync_player_kill_statistic", data.name, data.head_shot and true or false, data.weapon_unit, data.variant)
				end
			else
				data.attacker_state = managers.player:current_state()
				managers.statistics:killed(data)
			end
		end
	end
	local hit_offset_height = math.clamp(attack_data.col_ray.position.z - self._unit:movement():m_pos().z, 0, 300)
	local attacker = attack_data.attacker_unit
	if attacker:id() == -1 then
		attacker = self._unit
	end
	self:_send_bullet_attack_result(attack_data, attacker, damage_percent, body_index, hit_offset_height)
	self:_on_damage_received(attack_data)
	return result
end
function CopDamage:_show_death_hint(type)
	if type == "civilian" or type == "civilian_female" or type == "bank_manager" and not self._unit:base().enemy then
		managers.hint:show_hint("hint_killing_people")
	end
end
function CopDamage:_comment_death(unit, type)
	if type == "tank" then
		PlayerStandard.say_line(unit:sound(), "g30x_any")
	elseif type == "spooc" then
		PlayerStandard.say_line(unit:sound(), "g33x_any")
	elseif type == "taser" then
		PlayerStandard.say_line(unit:sound(), "g32x_any")
	elseif type == "shield" then
		PlayerStandard.say_line(unit:sound(), "g31x_any")
	end
end
function CopDamage:_AI_comment_death(unit, type)
	if type == "tank" then
		unit:sound():say("g30x_any", true)
	elseif type == "spooc" then
		unit:sound():say("g33x_any", true)
	elseif type == "taser" then
		unit:sound():say("g32x_any", true)
	elseif type == "shield" then
		unit:sound():say("g31x_any", true)
	end
end
function CopDamage:damage_explosion(attack_data)
	if self._dead or self._invulnerable then
		return
	end
	local result
	local damage = attack_data.damage
	damage = math.clamp(damage, self._HEALTH_INIT_PRECENT, self._HEALTH_INIT)
	local damage_percent = math.ceil(damage / self._HEALTH_INIT_PRECENT)
	damage = damage_percent * self._HEALTH_INIT_PRECENT
	if damage >= self._health then
		attack_data.damage = self._health
		result = {
			type = "death",
			variant = attack_data.variant
		}
		self:die(attack_data.variant)
	else
		attack_data.damage = damage
		local result_type = CopDamage.get_damage_type(self._char_tweak.damage.hurt_severity, damage_percent)
		result = {
			type = result_type,
			variant = attack_data.variant
		}
		self._health = self._health - damage
		self._health_ratio = self._health / self._HEALTH_INIT
	end
	attack_data.result = result
	attack_data.pos = attack_data.col_ray.position
	local head
	if self._head_body_name then
		head = attack_data.col_ray.body and self._head_body_key and attack_data.col_ray.body:key() == self._head_body_key
		local body = self._unit:body(self._head_body_name)
		self:_spawn_head_gadget({
			position = body:position(),
			rotation = body:rotation(),
			dir = -attack_data.col_ray.ray
		})
	end
	local attacker = attack_data.attacker_unit
	if not attacker or attacker:id() == -1 then
		attacker = self._unit
	end
	if result.type == "death" then
		local data = {
			name = self._unit:base()._tweak_table,
			owner = attack_data.owner,
			weapon_unit = attack_data.weapon_unit,
			variant = attack_data.variant,
			head_shot = head
		}
		managers.statistics:killed_by_anyone(data)
		if attack_data.attacker_unit == managers.player:player_unit() then
			if alive(attack_data.attacker_unit) then
				self:_comment_death(attack_data.attacker_unit, self._unit:base()._tweak_table)
			end
			self:_show_death_hint(self._unit:base()._tweak_table)
			managers.statistics:killed(data)
		end
	end
	self:_send_explosion_attack_result(attack_data, attacker, damage_percent)
	self:_on_damage_received(attack_data)
	return result
end
function CopDamage:damage_melee(attack_data)
	if self._dead or self._invulnerable then
		return
	end
	local result
	local head = self._head_body_name and attack_data.col_ray.body and attack_data.col_ray.body:name() == self._ids_head_body_name
	local damage = attack_data.damage
	local damage_effect = attack_data.damage_effect
	damage = math.clamp(damage, self._HEALTH_INIT_PRECENT, self._HEALTH_INIT)
	local damage_percent = math.ceil(damage / self._HEALTH_INIT_PRECENT)
	damage = damage_percent * self._HEALTH_INIT_PRECENT
	if damage >= self._health then
		attack_data.damage = self._health
		result = {
			type = "death",
			variant = attack_data.variant
		}
		self:die(attack_data.variant)
	else
		attack_data.damage = damage
		damage_effect = math.clamp(damage_effect, self._HEALTH_INIT_PRECENT, self._HEALTH_INIT)
		local damage_effect_percent = math.ceil(damage_effect / self._HEALTH_INIT_PRECENT)
		local result_type = CopDamage.get_damage_type(self._char_tweak.damage.hurt_severity, damage_effect_percent)
		result = {
			type = result_type,
			variant = attack_data.variant
		}
		self._health = self._health - damage
		self._health_ratio = self._health / self._HEALTH_INIT
	end
	attack_data.result = result
	attack_data.pos = attack_data.col_ray.position
	if result.type == "death" then
		local data = {
			name = self._unit:base()._tweak_table,
			head_shot = head,
			weapon_unit = attack_data.weapon_unit,
			variant = attack_data.variant
		}
		managers.statistics:killed_by_anyone(data)
		if attack_data.attacker_unit == managers.player:player_unit() then
			self:_comment_death(attack_data.attacker_unit, self._unit:base()._tweak_table)
			self:_show_death_hint(self._unit:base()._tweak_table)
			managers.statistics:killed(data)
		end
	end
	local hit_offset_height = math.clamp(attack_data.col_ray.position.z - self._unit:movement():m_pos().z, 0, 300)
	self:_send_melee_attack_result(attack_data, damage_percent, hit_offset_height)
	self:_on_damage_received(attack_data)
	return result
end
function CopDamage:get_ranged_attack_autotarget_data_fast()
	return {
		object = self._autotarget_data.fast
	}
end
function CopDamage:get_ranged_attack_autotarget_data(shoot_from_pos, aim_vec)
	local autotarget_data
	autotarget_data = {
		body = self._unit:body("b_spine1")
	}
	local dis = mvector3.distance(shoot_from_pos, self._unit:position())
	if 3500 < dis then
		autotarget_data = {
			body = self._unit:body("b_spine1")
		}
	else
		self._aim_bodies = {}
		table.insert(self._aim_bodies, self._unit:body("b_right_thigh"))
		table.insert(self._aim_bodies, self._unit:body("b_left_thigh"))
		table.insert(self._aim_bodies, self._unit:body("b_head"))
		table.insert(self._aim_bodies, self._unit:body("b_left_lower_arm"))
		table.insert(self._aim_bodies, self._unit:body("b_right_lower_arm"))
		local uncovered_body, best_angle
		for i, body in ipairs(self._aim_bodies) do
			local body_pos = body:center_of_mass()
			local body_vec = body_pos - shoot_from_pos
			local body_angle = body_vec:angle(aim_vec)
			if not best_angle or best_angle > body_angle then
				local aim_ray = World:raycast("ray", shoot_from_pos, body_pos, "sphere_cast_radius", 30, "bundle", 4, "slot_mask", managers.slot:get_mask("melee_equipment"))
				if not aim_ray then
					uncovered_body = body
					best_angle = body_angle
				else
				end
			end
		end
		if uncovered_body then
			autotarget_data = {body = uncovered_body}
		else
			autotarget_data = {
				body = self._unit:body("b_spine1")
			}
		end
	end
	return autotarget_data
end
function CopDamage:_spawn_head_gadget(params)
	if not self._head_gear then
		return
	end
	if self._head_gear_object then
		self._unit:get_object(Idstring(self._head_gear_object)):set_visibility(false)
	end
	local unit = World:spawn_unit(Idstring(self._head_gear), params.position, params.rotation)
	local dir = math.UP - params.dir / 2
	dir = dir:spread(25)
	local body = unit:body(0)
	body:push_at(body:mass(), dir * math.lerp(300, 650, math.random()), unit:position() + Vector3(math.rand(1), math.rand(1), math.rand(1)))
	self._head_gear = false
end
function CopDamage:dead()
	return self._dead
end
function CopDamage:die(variant)
	if Network:is_server() then
		local pos = self._unit:position()
		local key = self._unit:key()
		local radius = 640000
		local num_dodged = 0
		for _, enemy_data in pairs(managers.enemy:all_enemies()) do
			if enemy_data.unit:key() ~= key and radius > mvector3.distance_sq(pos, enemy_data.m_pos) and enemy_data.unit:character_damage():dodge(false) then
				num_dodged = num_dodged + 1
				if 4 <= num_dodged then
					break
				end
			end
		end
	end
	self._unit:base():set_slot(self._unit, 17)
	self:drop_pickup()
	self._unit:inventory():drop_shield()
	if self._unit:unit_data().mission_element then
		self._unit:unit_data().mission_element:event("death", self._unit)
	end
	variant = variant or "bullet"
	self._health = 0
	self._health_ratio = 0
	self._dead = true
	self:set_mover_collision_state(false)
end
function CopDamage:set_mover_collision_state(state)
	local change_state
	if state then
		if self._mover_collision_state then
			if self._mover_collision_state == -1 then
				self._mover_collision_state = nil
				change_state = true
			else
				self._mover_collision_state = self._mover_collision_state + 1
			end
		end
	elseif self._mover_collision_state then
		self._mover_collision_state = self._mover_collision_state - 1
	else
		self._mover_collision_state = -1
		change_state = true
	end
	if change_state then
		local body = self._unit:body("mover_blocker")
		if body then
			body:set_enabled(state)
		end
	end
end
function CopDamage:anim_clbk_mover_collision_state(unit, state)
	state = state == "true" and true or false
	self:set_mover_collision_state(state)
end
function CopDamage:drop_pickup()
	if self._pickup then
		local tracker = self._unit:movement():nav_tracker()
		local position = tracker:lost() and tracker:field_position() or tracker:position()
		local rotation = self._unit:rotation()
		managers.game_play_central:spawn_pickup({
			name = self._pickup,
			position = position,
			rotation = rotation
		})
	end
end
function CopDamage:sync_damage_bullet(attacker_unit, damage_percent, i_body, hit_offset_height)
	if self._dead then
		return
	end
	local body = self._unit:body(i_body)
	local head = self._head_body_name and body and body:name() == self._ids_head_body_name
	local damage = damage_percent * self._HEALTH_INIT_PRECENT
	local attack_data = {}
	local hit_pos = mvector3.copy(self._unit:movement():m_pos())
	mvector3.set_z(hit_pos, hit_pos.z + hit_offset_height)
	attack_data.pos = hit_pos
	local attack_dir
	if attacker_unit then
		attack_dir = hit_pos - attacker_unit:movement():m_head_pos()
		mvector3.normalize(attack_dir)
	else
		attack_dir = self._unit:rotation():y()
	end
	attack_data.attack_dir = attack_dir
	local result
	if damage >= self._health then
		if head then
			self:_spawn_head_gadget({
				position = body:position(),
				rotation = body:rotation(),
				dir = attack_dir
			})
		end
		result = {type = "death", variant = "bullet"}
		self:die(attack_data.variant)
		local data = {
			name = self._unit:base()._tweak_table,
			head_shot = head,
			weapon_unit = attacker_unit and attacker_unit:inventory() and attacker_unit:inventory():equipped_unit(),
			variant = attack_data.variant
		}
		if data.weapon_unit then
			managers.statistics:killed_by_anyone(data)
		end
	else
		local result_type = CopDamage.get_damage_type(self._char_tweak.damage.hurt_severity, damage_percent)
		result = {type = result_type, variant = "bullet"}
		self._health = self._health - damage
		self._health_ratio = self._health / self._HEALTH_INIT
	end
	attack_data.variant = "bullet"
	attack_data.attacker_unit = attacker_unit
	attack_data.result = result
	attack_data.damage = damage
	if not self._no_blood then
		managers.game_play_central:sync_play_impact_flesh(hit_pos, attack_dir)
	end
	self:_send_sync_bullet_attack_result(attack_data, hit_offset_height)
	self:_on_damage_received(attack_data)
end
function CopDamage:sync_damage_explosion(attacker_unit, damage_percent, i_body)
	if self._dead then
		return
	end
	local damage = damage_percent * self._HEALTH_INIT_PRECENT
	local attack_data = {}
	local result
	if damage >= self._health then
		result = {type = "death", variant = "explosion"}
		self:die(attack_data.variant)
		local data = {
			name = self._unit:base()._tweak_table,
			head_shot = false,
			weapon_unit = attacker_unit and attacker_unit:inventory() and attacker_unit:inventory():equipped_unit(),
			variant = "explosion"
		}
		managers.statistics:killed_by_anyone(data)
	else
		local result_type = CopDamage.get_damage_type(self._char_tweak.damage.hurt_severity, damage_percent)
		result = {type = result_type, variant = "explosion"}
		self._health = self._health - damage
		self._health_ratio = self._health / self._HEALTH_INIT
	end
	attack_data.variant = "explosion"
	attack_data.attacker_unit = attacker_unit
	attack_data.result = result
	attack_data.damage = damage
	local attack_dir
	if attacker_unit then
		attack_dir = self._unit:position() - attacker_unit:position()
		mvector3.normalize(attack_dir)
	else
		attack_dir = self._unit:rotation():y()
	end
	attack_data.attack_dir = attack_dir
	attack_data.pos = self._unit:position()
	mvector3.set_z(attack_data.pos, attack_data.pos.z + math.random() * 180)
	self:_send_sync_explosion_attack_result(attack_data)
	self:_on_damage_received(attack_data)
end
function CopDamage:sync_damage_melee(attacker_unit, damage_percent, i_body, hit_offset_height)
	if self._dead then
		return
	end
	local damage = damage_percent * self._HEALTH_INIT_PRECENT
	local attack_data = {}
	local result
	if damage >= self._health then
		result = {type = "death", variant = "melee"}
		self:die(attack_data.variant)
		local data = {
			name = self._unit:base()._tweak_table,
			head_shot = false,
			variant = "melee"
		}
		managers.statistics:killed_by_anyone(data)
	else
		local result_type = CopDamage.get_damage_type(self._char_tweak.damage.hurt_severity, damage_percent)
		result = {type = result_type, variant = "melee"}
		self._health = self._health - damage
		self._health_ratio = self._health / self._HEALTH_INIT
	end
	attack_data.variant = "melee"
	attack_data.attacker_unit = attacker_unit
	attack_data.result = result
	attack_data.damage = damage
	local attack_dir
	if attacker_unit then
		attack_dir = self._unit:position() - attacker_unit:position()
		mvector3.normalize(attack_dir)
	else
		attack_dir = -self._unit:rotation():y()
	end
	attack_data.attack_dir = attack_dir
	attack_data.pos = self._unit:position()
	mvector3.set_z(attack_data.pos, attack_data.pos.z + math.random() * 180)
	if not self._no_blood then
		managers.game_play_central:sync_play_impact_flesh(self._unit:movement():m_pos() + Vector3(0, 0, hit_offset_height), attack_dir)
	end
	self:_send_sync_melee_attack_result(attack_data, hit_offset_height)
	self:_on_damage_received(attack_data)
end
function CopDamage:_send_bullet_attack_result(attack_data, attacker, damage_percent, body_index, hit_offset_height)
	self._unit:network():send("damage_bullet", attacker, damage_percent, body_index, hit_offset_height)
end
function CopDamage:_send_explosion_attack_result(attack_data, attacker, damage_percent)
	self._unit:network():send("damage_explosion", attacker, damage_percent, 1)
end
function CopDamage:_send_melee_attack_result(attack_data, damage_percent, hit_offset_height)
	self._unit:network():send("damage_melee", attack_data.attacker_unit, damage_percent, 1, hit_offset_height)
end
function CopDamage:_send_sync_bullet_attack_result(attack_data, hit_offset_height)
end
function CopDamage:_send_sync_explosion_attack_result(attack_data)
end
function CopDamage:_send_sync_melee_attack_result(attack_data, hit_offset_height)
end
function CopDamage:sync_death(damage)
	if self._dead then
		return
	end
end
function CopDamage:_on_damage_received(damage_info)
	self:_call_listeners(damage_info)
	if damage_info.result.type == "death" then
		managers.enemy:on_enemy_died(self._unit, damage_info)
	end
end
function CopDamage:_call_listeners(damage_info)
	self._listener_holder:call(damage_info.result.type, self._unit, damage_info)
end
function CopDamage:add_listener(key, events, clbk)
	events = events or self._all_event_types
	self._listener_holder:add(key, events, clbk)
end
function CopDamage:remove_listener(key)
	self._listener_holder:remove(key)
end
function CopDamage:set_pickup(pickup)
	self._pickup = pickup
end
function CopDamage:pickup()
	return self._pickup
end
function CopDamage:health_ratio()
	return self._health_ratio
end
function CopDamage:set_invulnerable(state)
	if state then
		self._invulnerable = (self._invulnerable or 0) + 1
	elseif self._invulnerable then
		if self._invulnerable == 1 then
			self._invulnerable = nil
		else
			self._invulnerable = self._invulnerable - 1
		end
	end
end
function CopDamage:print(...)
	cat_print("cop_damage", ...)
end
function CopDamage:focus_delay_mul()
	return 1
end
function CopDamage:shoot_pos_mid(m_pos)
	self._spine2_obj:m_position(m_pos)
end
function CopDamage:save(data)
	if self._health ~= self._HEALTH_INIT then
		data.char_dmg = data.char_dmg or {}
		data.char_dmg.health = self._health
	end
	if self._invulnerable then
		data.char_dmg = data.char_dmg or {}
		data.char_dmg.invulnerable = self._invulnerable
	end
end
function CopDamage:load(data)
	if not data.char_dmg then
		return
	end
	if data.char_dmg.health then
		self._health = data.char_dmg.health
		self._health_ratio = self._health / self._HEALTH_INIT
	end
	if data.char_dmg.invulnerable then
		self._invulnerable = data.char_dmg.invulnerable
	end
end
