PlayerDamage = PlayerDamage or class()
PlayerDamage._HEALTH_INIT = tweak_data.player.damage.HEALTH_INIT
PlayerDamage._ARMOR_INIT = tweak_data.player.damage.ARMOR_INIT
function PlayerDamage:init(unit)
	self._unit = unit
	self:replenish()
	self._bleed_out_health = tweak_data.player.damage.BLEED_OUT_HEALTH_INIT
	self._god_mode = Global.god_mode
	self._invulnerable = false
	self._gui = Overlay:newgui()
	self._ws = self._gui:create_screen_workspace()
	self._focus_delay_mul = 1
	self._listener_holder = EventListenerHolder:new()
	self._dmg_interval = tweak_data.player.damage.MIN_DAMAGE_INTERVAL
	self._next_allowed_dmg_t = -100
	self._last_received_dmg = 0
end
function PlayerDamage:update(unit, t, dt)
	if self._regenerate_timer and not self._dead and not self._bleed_out then
		self._regenerate_timer = self._regenerate_timer - dt
		local top_fade = math.clamp(self._hurt_value - 0.8, 0, 1) / 0.2
		local hurt = self._hurt_value - (1 - top_fade) * ((1 + math.sin(t * 500)) / 2) / 10
		managers.environment_controller:set_hurt_value(hurt)
		if self._regenerate_timer < 0 then
			self:_regenerate_armor()
		end
	elseif self._hurt_value then
		if not self._bleed_out then
			self._hurt_value = self._hurt_value + dt
			local top_fade = math.clamp(self._hurt_value - 0.8, 0, 1) / 0.2
			local hurt = self._hurt_value - (1 - top_fade) * ((1 + math.sin(t * 500)) / 2) / 10
			managers.environment_controller:set_hurt_value(hurt)
			managers.hud:set_player_armor({
				current = self._hurt_value,
				total = 1
			})
			SoundDevice:set_rtpc("shield_status", self._hurt_value * 100)
			if self._hurt_value >= 1 then
				self._hurt_value = nil
				managers.environment_controller:set_hurt_value(1)
			end
		else
			local hurt = self._hurt_value - (1 + math.sin(t * 500)) / 2 / 10
			managers.environment_controller:set_hurt_value(hurt)
		end
	end
	if self._revive_miss then
		self._revive_miss = self._revive_miss - dt
		if 0 >= self._revive_miss then
			self._revive_miss = nil
		end
	end
end
function PlayerDamage:replenish()
	if managers.platform:presence() == "Playing" and (self:arrested() or self:need_revive()) then
		self:revive(true)
	end
	self:_regenerated()
	self:_regenerate_armor()
	managers.hud:set_player_health({
		current = self._health,
		total = self:_max_health()
	})
	managers.hud:set_player_armor({
		current = self._armor,
		total = self:_max_armor()
	})
	SoundDevice:set_rtpc("shield_status", 100)
end
function PlayerDamage:_regenerate_armor()
	if self._unit:sound() then
		self._unit:sound():play("shield_full_indicator")
	end
	self._armor = self:_max_armor()
	self._regenerate_timer = nil
	self:_send_set_armor()
end
function PlayerDamage:_regenerated()
	self._health = self:_max_health()
	self._revive_health_i = 1
	self._down_time = tweak_data.player.damage.DOWNED_TIME + managers.player:synced_crew_bonus_upgrade_value("more_blood_to_bleed", 0)
	self._regenerate_timer = nil
	self:_send_set_health()
	self:_set_health_effect()
	self._said_hurt = false
end
function PlayerDamage:set_health(health)
	self._health = health
	self:_send_set_health()
	self:_set_health_effect()
	managers.hud:set_player_health({
		current = self._health,
		total = self:_max_health()
	})
end
function PlayerDamage:down_time()
	return self._down_time
end
function PlayerDamage:health_ratio()
	return self._health / self:_max_health()
end
function PlayerDamage:_max_health()
	return math.round(self._HEALTH_INIT + managers.player:thick_skin_value())
end
function PlayerDamage:_max_armor()
	return (self._ARMOR_INIT + managers.player:body_armor_value()) * managers.player:synced_crew_bonus_upgrade_value("protector", 1)
end
function PlayerDamage:full_health()
	return self._health == self:_max_health()
end
function PlayerDamage:damage_tase(attack_data)
	if self._god_mode then
		return
	end
	local cur_state = self._unit:movement():current_state_name()
	if cur_state ~= "tased" and cur_state ~= "fatal" then
		managers.player:set_player_state("tased")
		local damage_info = {
			result = {type = "hurt", variant = "tase"}
		}
		self:_call_listeners(damage_info)
	end
end
function PlayerDamage:damage_melee(attack_data)
	local damage_info = {
		result = {type = "hurt", variant = "melee"}
	}
	self:_call_listeners(damage_info)
end
function PlayerDamage:_look_for_friendly_fire(unit)
	local players = managers.player:players()
	for _, player in ipairs(players) do
		if player == unit then
			return true
		end
	end
	local criminals = managers.groupai:state():all_criminals()
	if unit and criminals[unit:key()] then
		return true
	end
	return false
end
function PlayerDamage:play_whizby(position)
	self._unit:sound():play_whizby({position = position})
	self._unit:camera():play_shaker("whizby", 0.1)
	managers.rumble:play("bullet_whizby")
end
function PlayerDamage:damage_bullet(attack_data)
	local damage_info = {
		result = {type = "hurt", variant = "bullet"},
		attacker_unit = attack_data.attacker_unit
	}
	if self._god_mode then
		if attack_data.damage > 0 then
			self:_send_damage_drama(attack_data, attack_data.damage)
		end
		self:_call_listeners(damage_info)
		return
	elseif self._invulnerable then
		self:_call_listeners(damage_info)
		return
	elseif self:incapacitated() then
		return
	elseif PlayerDamage:_look_for_friendly_fire(attack_data.attacker_unit) then
		return
	elseif self:_chk_dmg_too_soon(attack_data.damage) then
		return
	elseif self._revive_miss and math.random() < self._revive_miss then
		self:play_whizby(attack_data.col_ray.position)
		return
	end
	if attack_data.attacker_unit:base()._tweak_table == "tank" then
		managers.achievment:set_script_data("dodge_this_fail", true)
	end
	self._unit:sound():play("player_hit")
	self._unit:camera():play_shaker("player_bullet_damage", 1)
	managers.rumble:play("damage_bullet")
	self:_hit_direction(attack_data.col_ray)
	if self._bleed_out then
		self:_bleed_out_damage(attack_data)
		return
	end
	local health_subtracted = self:_calc_armor_damage(attack_data)
	health_subtracted = health_subtracted or self:_calc_health_damage(attack_data)
	self._next_allowed_dmg_t = TimerManager:game():time() + self._dmg_interval
	self._last_received_dmg = health_subtracted
	if not self._bleed_out and health_subtracted > 0 then
		self:_send_damage_drama(attack_data, health_subtracted)
	elseif self._bleed_out then
		managers.challenges:set_flag("bullet_to_bleed_out")
	end
	self:_call_listeners(damage_info)
end
function PlayerDamage:_calc_armor_damage(attack_data)
	local health_subtracted
	if self._armor > 0 then
		health_subtracted = self._armor
		self._armor = math.max(0, self._armor - attack_data.damage)
		health_subtracted = health_subtracted - self._armor
		self:_damage_screen()
		managers.hud:set_player_armor({
			current = self._armor,
			total = self:_max_armor()
		})
		SoundDevice:set_rtpc("shield_status", self._armor / self:_max_armor() * 100)
		self:_send_set_armor()
	end
	return health_subtracted
end
function PlayerDamage:_calc_health_damage(attack_data)
	local health_subtracted
	if self._armor <= 0 then
		health_subtracted = self._health
		self._health = math.max(0, self._health - attack_data.damage)
		health_subtracted = health_subtracted - self._health
		self:_damage_screen()
		self:_check_bleed_out()
		managers.hud:set_player_health({
			current = self._health,
			total = self:_max_health()
		})
		self:_send_set_health()
		self:_set_health_effect()
		managers.statistics:health_subtracted(health_subtracted)
	end
	return health_subtracted
end
function PlayerDamage:_send_damage_drama(attack_data, health_subtracted)
	local dmg_percent = health_subtracted / self._HEALTH_INIT
	local attacker
	if not attacker or attack_data.attacker_unit:id() == -1 then
		attacker = self._unit
	end
	self._unit:network():send("criminal_hurt", attacker, math.clamp(math.ceil(dmg_percent * 100), 1, 100))
	if Network:is_server() then
		attacker = attack_data.attacker_unit
		if attacker and not attack_data.attacker_unit:movement() then
			attacker = nil
		end
		managers.groupai:state():criminal_hurt_drama(self._unit, attacker, dmg_percent)
	end
	if Network:is_client() then
		self._unit:network():send_to_host("damage_bullet", attacker, 1, 1, 1)
	end
end
function PlayerDamage:damage_killzone(attack_data)
	local damage_info = {
		result = {type = "hurt", variant = "killzone"}
	}
	if self._god_mode or self._invulnerable then
		self:_call_listeners(damage_info)
		return
	elseif self:incapacitated() then
		return
	end
	self._unit:sound():play("player_hit")
	self:_hit_direction(attack_data.col_ray)
	if self._bleed_out then
		return
	end
	attack_data.damage = attack_data.damage or 1
	local health_subtracted = self:_calc_armor_damage(attack_data)
	health_subtracted = health_subtracted or self:_calc_health_damage(attack_data)
	self:_call_listeners(damage_info)
end
function PlayerDamage:damage_fall(data)
	local damage_info = {
		result = {type = "hurt", variant = "fall"}
	}
	if self._god_mode or self._invulnerable then
		self:_call_listeners(damage_info)
		return
	elseif self:incapacitated() then
		return
	end
	local height_limit = 300
	local death_limit = 631
	if height_limit > data.height then
		return
	end
	local die = death_limit < data.height
	self._unit:sound():play("player_hit")
	managers.environment_controller:hit_feedback_down()
	if self._bleed_out then
		return
	end
	if die then
		self._health = 0
	elseif self._health / self:_max_health() < 0.25 then
	else
		self._health = math.clamp(self._health - 4, 1, self:_max_health())
	end
	self._armor = 0
	managers.hud:set_player_armor({
		current = self._armor,
		total = self:_max_armor(),
		no_hint = true
	})
	SoundDevice:set_rtpc("shield_status", 0)
	self:_send_set_armor()
	managers.hud:set_player_health({
		current = self._health,
		total = self:_max_health()
	})
	self:_send_set_health()
	self:_set_health_effect()
	self:_damage_screen()
	self:_check_bleed_out()
	if die then
		managers.challenges:set_flag("fall_to_bleed_out")
	end
	self:_call_listeners(damage_info)
	return true
end
function PlayerDamage:damage_explosion(attack_data)
	local damage_info = {
		result = {type = "hurt", variant = "explosion"}
	}
	if self._god_mode or self._invulnerable then
		self:_call_listeners(damage_info)
		return
	elseif self:incapacitated() then
		return
	end
	local distance = mvector3.distance(attack_data.position, self._unit:position())
	if distance > attack_data.range then
		return
	end
	local damage = (attack_data.damage or 1) * (1 - distance / attack_data.range)
	if self._bleed_out then
		return
	end
	attack_data.damage = damage
	local armor_subtracted = self:_calc_armor_damage(attack_data)
	attack_data.damage = attack_data.damage - (armor_subtracted or 0)
	local health_subtracted = self:_calc_health_damage(attack_data)
	self:_call_listeners(damage_info)
end
function PlayerDamage:update_downed(t, dt)
	if self._downed_timer and self._downed_paused_counter == 0 then
		self._downed_timer = self._downed_timer - dt
		return self._downed_timer <= 0
	end
	return false
end
function PlayerDamage:_check_bleed_out()
	if self._health == 0 then
		self._bleed_out = true
		managers.player:set_player_state("bleed_out")
		self._critical_state_heart_loop_instance = self._unit:sound():play("critical_state_heart_loop")
		self._bleed_out_health = tweak_data.player.damage.BLEED_OUT_HEALTH_INIT
		self._hurt_value = 0.2
		self:_drop_blood_sample()
		self:on_downed()
	elseif not self._said_hurt and 0.2 > self._health / self:_max_health() then
		self._said_hurt = true
		PlayerStandard.say_line(self, "g80x_plu")
	end
end
function PlayerDamage:_drop_blood_sample()
	local remove = math.rand(1) < 0.5
	if not remove then
		return
	end
	local removed = false
	if managers.player:has_special_equipment("blood_sample") then
		removed = true
		managers.player:remove_special("blood_sample")
		managers.hint:show_hint("dropped_blood_sample")
	end
	if managers.player:has_special_equipment("blood_sample_verified") then
		removed = true
		managers.player:remove_special("blood_sample_verified")
		managers.hint:show_hint("dropped_blood_sample")
	end
	if removed then
		self._unit:sound():play("vial_break_2d")
		self._unit:sound():say("g29", false)
		if managers.groupai:state():bain_state() then
			managers.dialog:queue_dialog("hos_ban_139", {})
		end
		local splatter_from = self._unit:position() + math.UP * 5
		local splatter_to = self._unit:position() - math.UP * 45
		local splatter_ray = World:raycast("ray", splatter_from, splatter_to, "slot_mask", managers.game_play_central._slotmask_world_geometry)
		if splatter_ray then
			World:project_decal(Idstring("blood_spatter"), splatter_ray.position, splatter_ray.ray, splatter_ray.unit, nil, splatter_ray.normal)
		end
	end
end
function PlayerDamage:on_downed()
	self._downed_timer = self:down_time()
	self._downed_paused_counter = 0
	managers.hud:pd_start_timer({
		time = self._downed_timer
	})
end
function PlayerDamage:pause_downed_timer()
	self._downed_paused_counter = self._downed_paused_counter + 1
	if self._downed_paused_counter == 1 then
		managers.hud:pd_pause_timer()
		managers.hud:pd_start_progress(0, tweak_data.interaction.revive.timer, "debug_interact_being_revived", "interaction_help")
	end
end
function PlayerDamage:unpause_downed_timer()
	self._downed_paused_counter = self._downed_paused_counter - 1
	if self._downed_paused_counter == 0 then
		managers.hud:pd_unpause_timer()
		managers.hud:pd_stop_progress()
	end
end
function PlayerDamage:update_arrested(t, dt)
	if self._arrested_timer and self._arrested_paused_counter == 0 then
		self._arrested_timer = self._arrested_timer - dt
		return not self:arrested()
	end
	return false
end
function PlayerDamage:on_freed()
	self._arrested_timer = nil
	self._arrested = nil
end
function PlayerDamage:on_arrested()
	self._bleed_out = false
	self._arrested_timer = tweak_data.player.damage.ARRESTED_TIME
	self._arrested_paused_counter = 0
	managers.hud:pd_start_timer({
		time = self._arrested_timer
	})
end
function PlayerDamage:pause_arrested_timer()
	if not self._arrested_timer or self._arrested_timer <= 0 then
		return
	end
	self._arrested_paused_counter = self._arrested_paused_counter + 1
	if self._arrested_paused_counter == 1 then
		managers.hud:pd_pause_timer()
		managers.hud:pd_start_progress(0, tweak_data.interaction.free.timer, "debug_interact_being_freed", "interaction_free")
	end
end
function PlayerDamage:unpause_arrested_timer()
	if not self._arrested_timer or self._arrested_timer <= 0 then
		return
	end
	self._arrested_paused_counter = self._arrested_paused_counter - 1
	if self._arrested_paused_counter == 0 then
		managers.hud:pd_unpause_timer()
		managers.hud:pd_stop_progress()
	end
end
function PlayerDamage:update_incapacitated(t, dt)
	return self:update_downed(t, dt)
end
function PlayerDamage:on_incapacitated()
	self:on_downed()
	self._incapacitated = true
end
function PlayerDamage:bleed_out()
	return self._bleed_out
end
function PlayerDamage:incapacitated()
	return self._incapacitated
end
function PlayerDamage:arrested()
	return self._arrested_timer or self._arrested
end
function PlayerDamage:_bleed_out_damage(attack_data)
	local health_subtracted = self._bleed_out_health
	self._bleed_out_health = math.max(0, self._bleed_out_health - attack_data.damage)
	health_subtracted = health_subtracted - self._health
	self._next_allowed_dmg_t = TimerManager:game():time() + self._dmg_interval
	self._last_received_dmg = health_subtracted
	if self._bleed_out_health <= 0 then
		managers.player:set_player_state("fatal")
	end
	if health_subtracted > 0 then
		self:_send_damage_drama(attack_data, health_subtracted)
	end
end
function PlayerDamage:_hit_direction(col_ray)
	if col_ray then
		local dir = col_ray.ray
		local infront = math.dot(self._unit:camera():forward(), dir)
		if infront < -0.9 then
		else
			local polar = self._unit:camera():forward():to_polar_with_reference(-dir, Vector3(0, 0, 1))
			local direction = Vector3(polar.spin, polar.pitch, 0):normalized()
			if math.abs(direction.x) > math.abs(direction.y) then
				if 0 > direction.x then
					managers.environment_controller:hit_feedback_left()
				else
					managers.environment_controller:hit_feedback_right()
				end
			elseif 0 > direction.y then
				managers.environment_controller:hit_feedback_up()
			else
				managers.environment_controller:hit_feedback_down()
			end
		end
	else
	end
end
function PlayerDamage:_damage_screen()
	self._regenerate_timer = tweak_data.player.damage.REGENERATE_TIME
	self._hurt_value = 1 - math.clamp(0.8 - math.pow(self._armor / self:_max_armor(), 2), 0, 1)
	managers.environment_controller:set_hurt_value(self._hurt_value)
end
function PlayerDamage:revive(helped_self)
	local arrested = self:arrested()
	managers.player:set_player_state("standard")
	self._unit:sound():play("critical_state_heart_stop")
	if not helped_self then
		PlayerStandard.say_line(self, "s05x_sin")
	end
	self._bleed_out = false
	self._incapacitated = nil
	self._downed_timer = nil
	if not arrested then
		if true ~= helped_self then
			managers.challenges:count_up("revived")
		end
		self._down_time = math.max(tweak_data.player.damage.DOWNED_TIME_MIN, self._down_time - tweak_data.player.damage.DOWNED_TIME_DEC)
		self._health = math.round(tweak_data.player.damage.REVIVE_HEALTH_STEPS[self._revive_health_i] * self:_max_health())
		self._revive_health_i = math.min(#tweak_data.player.damage.REVIVE_HEALTH_STEPS, self._revive_health_i + 1)
		self._revive_miss = 2
	end
	self:_regenerate_armor()
	managers.hud:set_player_health({
		current = self._health,
		total = self:_max_health()
	})
	self:_send_set_health()
	self:_set_health_effect()
	managers.hud:pd_stop_progress()
end
function PlayerDamage:need_revive()
	return self._bleed_out or self._incapacitated
end
function PlayerDamage:dead()
	return self._dead
end
function PlayerDamage:set_god_mode(state)
	Global.god_mode = state
	self._god_mode = state
	self:print("PlayerDamage god mode " .. (state and "ON" or "OFF"))
end
function PlayerDamage:god_mode()
	return self._god_mode
end
function PlayerDamage:print(...)
	cat_print("player_damage", ...)
end
function PlayerDamage:set_invulnerable(state)
	self._invulnerable = state
end
function PlayerDamage:set_danger_level(danger_level)
	self._danger_level = self._danger_level ~= danger_level and danger_level or nil
	self._focus_delay_mul = danger_level and tweak_data.danger_zones[self._danger_level] or 1
end
function PlayerDamage:focus_delay_mul()
	return self._focus_delay_mul
end
function PlayerDamage:shoot_pos_mid(m_pos)
	mvector3.set(m_pos, self._unit:movement():m_head_pos())
end
function PlayerDamage:_send_set_health()
	if self._unit:network() then
		local hp = math.round(self._health / self:_max_health() * 100)
		self._unit:network():send("set_health", math.clamp(hp, 0, 100))
	end
end
function PlayerDamage:_set_health_effect()
	local hp = self._health / self:_max_health()
	math.clamp(hp, 0, 1)
	managers.environment_controller:set_health_effect_value(hp)
end
function PlayerDamage:_send_set_armor()
	if self._unit:network() then
		local armor = math.round(self._armor / self:_max_armor() * 100)
		self._unit:network():send("set_armor", math.clamp(armor, 0, 100))
	end
end
function PlayerDamage:stop_heartbeat()
	if self._critical_state_heart_loop_instance then
		self._critical_state_heart_loop_instance:stop()
		self._critical_state_heart_loop_instance = nil
	end
end
function PlayerDamage:destroy()
	if alive(self._gui) and alive(self._ws) then
		self._gui:destroy_workspace(self._ws)
	end
	if self._critical_state_heart_loop_instance then
		self._critical_state_heart_loop_instance:stop()
	end
	SoundDevice:set_rtpc("shield_status", 100)
	managers.environment_controller:set_hurt_value(1)
	managers.environment_controller:set_health_effect_value(1)
end
function PlayerDamage:_call_listeners(damage_info)
	CopDamage._call_listeners(self, damage_info)
end
function PlayerDamage:add_listener(...)
	CopDamage.add_listener(self, ...)
end
function PlayerDamage:remove_listener(key)
	CopDamage.remove_listener(self, key)
end
function PlayerDamage:on_fatal_state_enter()
	local dmg_info = {
		result = {type = "death"}
	}
	self:_call_listeners(dmg_info)
end
function PlayerDamage:on_incapacitated_state_enter()
	local dmg_info = {
		result = {type = "death"}
	}
	self:_call_listeners(dmg_info)
end
function PlayerDamage:_chk_dmg_too_soon(damage)
	if damage <= self._last_received_dmg and TimerManager:game():time() < self._next_allowed_dmg_t then
		return true
	end
end
function PlayerDamage.clbk_msg_overwrite_criminal_hurt(overwrite_data, msg_queue, msg_name, crim_unit, attacker_unit, dmg)
	if msg_queue then
		local crim_key = crim_unit:key()
		local attacker_key = attacker_unit:key()
		if overwrite_data.indexes[crim_key] and overwrite_data.indexes[crim_key][attacker_key] then
			local index = overwrite_data.indexes[crim_key][attacker_key]
			local old_msg = msg_queue[index]
			old_msg[4] = math.clamp(dmg + old_msg[4], 1, 100)
		else
			table.insert(msg_queue, {
				msg_name,
				crim_unit,
				attacker_unit,
				dmg
			})
			overwrite_data.indexes[crim_key] = {
				[attacker_key] = #msg_queue
			}
		end
	else
		overwrite_data.indexes = {}
	end
end
