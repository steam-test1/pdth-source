PlayerTased = PlayerTased or class(PlayerStandard)
PlayerTased._update_movement = PlayerBleedOut._update_movement
function PlayerTased:enter(enter_data)
	PlayerTased.super.enter(self, enter_data)
	self._ids_tased_boost = Idstring("tased_boost")
	self._ids_tased = Idstring("tased")
	self:_start_action_tased(Application:time())
	self._fatal_delayed_clbk = "PlayerTased_fatal_delayed_clbk"
	managers.enemy:add_delayed_clbk(self._fatal_delayed_clbk, callback(self, self, "clbk_exit_to_fatal"), TimerManager:game():time() + tweak_data.player.damage.TASED_TIME)
	self._next_shock = 0.5
	self._taser_value = 1
	managers.groupai:state():on_criminal_disabled(self._unit, "electrified")
	if Network:is_server() then
		self:_register_revive_SO()
	end
	self._equipped_unit:base():on_reload()
	self:_interupt_action_reload()
	self._rumble_electrified = managers.rumble:play("electrified")
end
function PlayerTased:_enter(enter_data)
	self._unit:base():set_slot(self._unit, 2)
	self._unit:camera():camera_unit():base():set_target_tilt(0)
end
function PlayerTased:exit(enter_data)
	PlayerTased.super.exit(self, enter_data)
	if self._fatal_delayed_clbk then
		managers.enemy:remove_delayed_clbk(self._fatal_delayed_clbk)
		self._fatal_delayed_clbk = nil
	end
	if self._recover_delayed_clbk then
		managers.enemy:remove_delayed_clbk(self._recover_delayed_clbk)
		self._recover_delayed_clbk = nil
	end
	if Network:is_server() and self._SO_id then
		managers.groupai:state():remove_special_objective(self._SO_id)
	end
	managers.environment_controller:set_taser_value(1)
	self._camera_unit:base():break_recoil()
	self._unit:sound():play("tasered_stop")
	managers.rumble:stop(self._rumble_electrified)
	self._unit:camera():play_redirect(Idstring("idle"))
end
function PlayerTased:update(t, dt)
	PlayerTased.super.update(self, t, dt)
end
function PlayerTased:_update_check_actions(t, dt)
	local input = self:_get_input()
	if t > self._next_shock then
		self._next_shock = t + 0.25 + math.rand(1)
		self._unit:camera():play_shaker("player_taser_shock", 1, 10)
		self._camera_unit:base():start_shooting()
		self._recoil_t = t + 0.5
		self._camera_unit:base():recoil_kick(-5, 5)
		input.btn_primary_attack_state = true
		input.btn_primary_attack_press = true
		self._unit:camera():camera_unit():base():set_target_tilt((math.random(2) == 1 and -1 or 1) * math.random(10))
		self._taser_value = math.max(self._taser_value - 0.25, 0)
		self._unit:sound():play("tasered_shock")
		self._unit:camera():play_redirect(self._ids_tased_boost)
		managers.rumble:play("electric_shock")
	elseif self._recoil_t then
		input.btn_primary_attack_state = true
		if t > self._recoil_t then
			self._recoil_t = nil
			self._camera_unit:base():stop_shooting()
		end
	end
	self._taser_value = math.step(self._taser_value, 0.8, dt / 4)
	managers.environment_controller:set_taser_value(self._taser_value)
	self._shooting = self:_check_action_primary_attack(t, input)
	if self._shooting then
		self._camera_unit:base():recoil_kick(-5, 5)
	end
	if self._unequip_weapon_expire_t and t >= self._unequip_weapon_expire_t then
		self._unequip_weapon_expire_t = nil
		self:_start_action_equip_weapon(t)
	end
	if self._equip_weapon_expire_t and t >= self._equip_weapon_expire_t then
		self._equip_weapon_expire_t = nil
	end
	if input.btn_stats_screen_press then
		self._unit:base():set_stats_screen_visible(true)
	elseif input.btn_stats_screen_release then
		self._unit:base():set_stats_screen_visible(false)
	end
	self:_update_foley(t, input)
	local new_action
	if not new_action then
	end
	self:_check_action_interact(t, input)
	local new_action
	new_action = new_action or self:_check_set_upgrade(t, input)
end
function PlayerTased:_check_action_primary_attack(t, input)
	local new_action
	local action_forbidden = self:chk_action_forbidden("primary_attack")
	action_forbidden = action_forbidden or self:_is_reloading() or self:_changing_weapon() or self._melee_expire_t or self._use_item_expire_t or self:_interacting()
	local action_wanted = input.btn_primary_attack_state
	if action_wanted then
		if not action_forbidden then
			self._queue_reload_interupt = nil
			self._ext_inventory:equip_selected_primary(false)
			if self._equipped_unit then
				local weap_base = self._equipped_unit:base()
				local fire_mode = weap_base:fire_mode()
				if weap_base:out_of_ammo() then
					if input.btn_primary_attack_press then
						weap_base:dryfire()
					end
				elseif weap_base.clip_empty and weap_base:clip_empty() then
					if fire_mode == "single" and input.btn_primary_attack_press then
						weap_base:dryfire()
					end
				elseif self._running then
					self:_interupt_action_running(t)
				else
					if not self._shooting and weap_base:start_shooting_allowed() then
						local start = fire_mode == "single" and input.btn_primary_attack_press
						start = start or fire_mode ~= "single" and input.btn_primary_attack_state
						if start then
							weap_base:start_shooting()
							self._camera_unit:base():start_shooting()
							if not self._in_steelsight or not weap_base:tweak_data_anim_play("fire_steelsight", weap_base:fire_rate_multiplier()) then
								weap_base:tweak_data_anim_play("fire", weap_base:fire_rate_multiplier())
							end
						end
					end
					local fired
					if fire_mode == "single" then
						if input.btn_primary_attack_press then
							fired = weap_base:trigger_pressed(self._ext_camera:position(), self._ext_camera:forward())
						end
					elseif input.btn_primary_attack_state then
						fired = weap_base:trigger_held(self._ext_camera:position(), self._ext_camera:forward())
					end
					new_action = true
					if fired then
						local weap_tweak_data = tweak_data.weapon[weap_base:get_name_id()]
						if not self._in_steelsight then
						elseif weap_tweak_data.animations.recoil_steelsight then
						end
						local kick_v = weap_tweak_data.kick.v[self._in_steelsight and "steelsight" or self._ducking and "crouching" or "standing"]
						local kick_h = weap_tweak_data.kick.h and weap_tweak_data.kick.h[self._in_steelsight and "steelsight" or self._ducking and "crouching" or "standing"] or 0
						local recoil_multiplier = managers.player:upgrade_value(weap_base:get_name_id(), "recoil_multiplier")
						recoil_multiplier = recoil_multiplier ~= 0 and recoil_multiplier or 1
						self._camera_unit:base():recoil_kick(kick_v * recoil_multiplier, kick_h * recoil_multiplier)
						local spread_multiplier = weap_base:spread_multiplier()
						managers.hud:_kick_crosshair_offset(weap_tweak_data.crosshair[self._in_steelsight and "steelsight" or self._ducking and "crouching" or "standing"].kick_offset * spread_multiplier)
						managers.hud:set_ammo_amount(weap_base:ammo_info())
						if self._ext_network then
							local impact = not fired.hit_enemy
							self._ext_network:send("shot_blank", impact)
						end
					elseif fire_mode == "single" then
						new_action = false
					end
				end
			end
		else
			if self:_is_reloading() and self._equipped_unit:base():reload_interuptable() and input.btn_primary_attack_press then
				self._queue_reload_interupt = true
			else
			end
		end
	end
	if not new_action and self._shooting then
		self._equipped_unit:base():stop_shooting()
		self._camera_unit:base():stop_shooting()
	end
	return new_action
end
function PlayerTased:_check_action_interact(t, input)
	if input.btn_interact_press and (not self._intimidate_t or t - self._intimidate_t > tweak_data.player.movement_state.interaction_delay) then
		self._intimidate_t = t
		self:call_teammate(nil, t, true, true)
	end
end
function PlayerTased:call_teammate(line, t, no_gesture, skip_alert)
	local voice_type, plural, prime_target = self:_get_unit_intimidation_action(true, false, false, true)
	local interact_type, queue_name
	if voice_type == "stop_cop" then
		local shout_sound = tweak_data.character[prime_target.unit:base()._tweak_table].priority_shout
		shout_sound = managers.groupai:state():whisper_mode() and tweak_data.character[prime_target.unit:base()._tweak_table].silent_priority_shout or shout_sound
		if shout_sound then
			interact_type = "cmd_point"
			queue_name = "s07x_sin"
			managers.game_play_central:add_enemy_contour(prime_target.unit)
			managers.network:session():send_to_peers_synched("mark_enemy", prime_target.unit)
			managers.challenges:set_flag("eagle_eyes")
		end
	end
	if interact_type then
		self:_do_action_intimidate(t, not no_gesture and interact_type or nil, queue_name, skip_alert)
	end
end
function PlayerTased:_start_action_tased(t)
	self:_interupt_action_running(t)
	self:_stance_entered()
	self:_update_crosshair_offset()
	self._unit:camera():play_redirect(self._ids_tased)
	self._unit:sound():play("tasered_loop")
	managers.hint:show_hint("hint_been_tasered")
end
function PlayerTased:_register_revive_SO()
	if self._SO_id or not managers.navigation:is_data_ready() then
		return
	end
	local objective = {
		type = "follow",
		follow_unit = self._unit,
		called = true,
		destroy_clbk_key = false,
		scan = true,
		nav_seg = self._unit:movement():nav_tracker():nav_segment()
	}
	local so_descriptor = {
		objective = objective,
		base_chance = 1,
		chance_inc = 0,
		interval = 6,
		search_dis = 5000,
		search_pos = self._unit:position(),
		usage_amount = 1,
		AI_group = "friendlies"
	}
	local so_id = "PlayerTased_assistance"
	self._SO_id = so_id
	managers.groupai:state():add_special_objective(so_id, so_descriptor)
end
function PlayerTased:clbk_exit_to_fatal()
	self._fatal_delayed_clbk = nil
	managers.player:set_player_state("incapacitated")
end
function PlayerTased:clbk_exit_to_std()
	self._recover_delayed_clbk = nil
	managers.player:set_player_state("standard")
end
function PlayerTased:on_tase_ended()
	if self._fatal_delayed_clbk then
		managers.enemy:remove_delayed_clbk(self._fatal_delayed_clbk)
		self._fatal_delayed_clbk = nil
	end
	if not self._recover_delayed_clbk then
		self._recover_delayed_clbk = "PlayerTased_recover_delayed_clbk"
		managers.enemy:add_delayed_clbk(self._recover_delayed_clbk, callback(self, self, "clbk_exit_to_std"), TimerManager:game():time() + tweak_data.player.damage.TASED_RECOVER_TIME)
	end
end
