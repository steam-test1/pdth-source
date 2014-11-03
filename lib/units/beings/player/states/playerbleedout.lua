PlayerBleedOut = PlayerBleedOut or class(PlayerStandard)
function PlayerBleedOut:init(unit)
	PlayerBleedOut.super.init(self, unit)
end
function PlayerBleedOut:enter(enter_data)
	PlayerBleedOut.super.enter(self, enter_data)
	self._revive_SO_data = {
		unit = self._unit
	}
	self:_start_action_bleedout(Application:time())
	self._old_selection = nil
	if self._unit:inventory():equipped_selection() ~= 1 then
		self._old_selection = self._unit:inventory():equipped_selection()
		self:_start_action_unequip_weapon(Application:time(), {selection_wanted = 1})
		self._unit:inventory():unit_by_selection(1):base():on_reload()
	end
	self._unit:camera():camera_unit():base():set_target_tilt(35)
	managers.groupai:state():on_criminal_disabled(self._unit)
	if Network:is_server() and self._ext_movement:nav_tracker() then
		self._register_revive_SO(self._revive_SO_data, "revive")
	end
	managers.groupai:state():report_criminal_downed(self._unit)
end
function PlayerBleedOut:_enter(enter_data)
	self._unit:base():set_slot(self._unit, 2)
	if Network:is_server() and self._ext_movement:nav_tracker() then
		managers.groupai:state():on_player_weapons_hot()
	end
end
function PlayerBleedOut:exit(new_state_name)
	PlayerBleedOut.super.exit(self, new_state_name)
	self:_end_action_bleedout(Application:time())
	self._unit:camera():camera_unit():base():set_target_tilt(0)
	local exit_data = {
		equip_weapon = self._old_selection
	}
	if Network:is_server() then
		if new_state_name == "fatal" then
			exit_data.revive_SO_data = self._revive_SO_data
			self._revive_SO_data = nil
		else
			self:_unregister_revive_SO()
		end
	end
	exit_data.reload_expire_t = self._reload_expire_t
	exit_data.skip_equip = true
	return exit_data
end
function PlayerBleedOut:update(t, dt)
	PlayerBleedOut.super.update(self, t, dt)
end
function PlayerBleedOut:_update_check_actions(t, dt)
	local input = self:_get_input()
	self._unit:camera():set_shaker_parameter("headbob", "amplitude", 0)
	if self._reload_expire_t and t >= self._reload_expire_t then
		self._reload_expire_t = nil
		if self._equipped_unit then
			self._equipped_unit:base():on_reload()
			managers.hud:set_ammo_amount(self._equipped_unit:base():ammo_info())
		end
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
	new_action = new_action or self:_check_set_upgrade(t, input)
	new_action = new_action or self:_check_action_reload(t, input)
	if not new_action then
		new_action = self:_check_action_primary_attack(t, input)
		self._shooting = new_action
	end
	self:_check_action_interact(t, input)
end
function PlayerBleedOut:_check_action_interact(t, input)
	if input.btn_interact_press and (not self._intimidate_t or t - self._intimidate_t > tweak_data.player.movement_state.interaction_delay) then
		self._intimidate_t = t
		PlayerArrested.call_teammate(self, "f11", t)
	end
end
function PlayerBleedOut:_start_action_state_standard(t)
	managers.player:set_player_state("standard")
end
function PlayerBleedOut._register_revive_SO(revive_SO_data, variant)
	if revive_SO_data.SO_id or not managers.navigation:is_data_ready() then
		return
	end
	local followup_objective = {
		type = "act",
		scan = true,
		action = {
			type = "act",
			body_part = 1,
			variant = "crouch",
			blocks = {
				action = -1,
				walk = -1,
				hurt = -1,
				heavy_hurt = -1,
				aim = -1
			}
		}
	}
	local objective = {
		type = "revive",
		follow_unit = revive_SO_data.unit,
		called = true,
		destroy_clbk_key = false,
		nav_seg = revive_SO_data.unit:movement():nav_tracker():nav_segment(),
		fail_clbk = callback(PlayerBleedOut, PlayerBleedOut, "on_rescue_SO_failed", revive_SO_data),
		complete_clbk = callback(PlayerBleedOut, PlayerBleedOut, "on_rescue_SO_completed", revive_SO_data),
		action_start_clbk = callback(PlayerBleedOut, PlayerBleedOut, "on_rescue_SO_started", revive_SO_data),
		scan = true,
		action = {
			type = "act",
			variant = variant,
			body_part = 1,
			blocks = {
				action = -1,
				walk = -1,
				light_hurt = -1,
				hurt = -1,
				heavy_hurt = -1,
				aim = -1
			},
			align_sync = true
		},
		interact_delay = tweak_data.interaction[variant == "untie" and "free" or variant].timer,
		followup_objective = followup_objective
	}
	local so_descriptor = {
		objective = objective,
		base_chance = 1,
		chance_inc = 0,
		interval = 6,
		search_dis = 100000,
		search_pos = revive_SO_data.unit:position(),
		usage_amount = 1,
		AI_group = "friendlies",
		admin_clbk = callback(PlayerBleedOut, PlayerBleedOut, "on_rescue_SO_administered", revive_SO_data)
	}
	revive_SO_data.variant = variant
	local so_id = "Playerrevive"
	revive_SO_data.SO_id = so_id
	managers.groupai:state():add_special_objective(so_id, so_descriptor)
	if not revive_SO_data.deathguard_SO_id then
		revive_SO_data.deathguard_SO_id = PlayerBleedOut._register_deathguard_SO(revive_SO_data.unit)
	end
end
function PlayerBleedOut:_unregister_revive_SO()
	if self._revive_SO_data.deathguard_SO_id then
		PlayerBleedOut._unregister_deathguard_SO(self._revive_SO_data.deathguard_SO_id)
		self._revive_SO_data.deathguard_SO_id = nil
	end
	if self._revive_SO_data.SO_id then
		managers.groupai:state():remove_special_objective(self._revive_SO_data.SO_id)
		self._revive_SO_data.SO_id = nil
	elseif self._revive_SO_data.rescuer then
		local rescuer = self._revive_SO_data.rescuer
		self._revive_SO_data.rescuer = nil
		if alive(rescuer) then
			rescuer:brain():set_objective(nil)
		end
	end
end
function PlayerBleedOut._register_deathguard_SO(my_unit)
	local guard_objective = {
		type = "follow",
		deathguard = true,
		follow_unit = my_unit,
		scan = true,
		nav_seg = my_unit:movement():nav_tracker():nav_segment(),
		interrupt_on = "obstructed",
		stance = "cbt",
		distance = 600
	}
	local nr_guards = math.random(5, 10)
	local guard_so_descriptor = {
		objective = guard_objective,
		base_chance = 1,
		chance_inc = 0,
		interval = 2,
		search_dis = 10000,
		search_pos = my_unit:position(),
		usage_amount = nr_guards,
		AI_group = "enemies",
		verification_clbk = callback(PlayerBleedOut, PlayerBleedOut, "verif_clbk_is_unit_deathguard")
	}
	local guard_so_id = "deathguard" .. tostring(my_unit:key())
	managers.groupai:state():add_special_objective(guard_so_id, guard_so_descriptor)
	return guard_so_id
end
function PlayerBleedOut._unregister_deathguard_SO(so_id)
	managers.groupai:state():remove_special_objective(so_id)
end
function PlayerBleedOut:_start_action_bleedout(t)
	self:_interupt_action_running(t)
	self._ducking = true
	self:_stance_entered()
	self:_update_crosshair_offset()
	self._unit:kill_mover()
	self._unit:activate_mover(Idstring("duck"))
end
function PlayerBleedOut:_end_action_bleedout(t)
	if not self:_can_stand() then
		return
	end
	self._ducking = false
	self:_stance_entered()
	self:_update_crosshair_offset()
	self._unit:kill_mover()
	self._unit:activate_mover(Idstring("stand"))
end
function PlayerBleedOut:_update_movement(t, dt)
	if self._ext_network then
		local cur_pos = self._pos
		local move_dis = mvector3.distance_sq(cur_pos, self._last_sent_pos)
		if move_dis > 22500 or move_dis > 400 and t - self._last_sent_pos_t > 1.5 then
			self._ext_network:send("action_walk_nav_point", cur_pos)
			mvector3.set(self._last_sent_pos, cur_pos)
			self._last_sent_pos_t = t
		end
	end
end
function PlayerBleedOut:on_rescue_SO_administered(revive_SO_data, receiver_unit)
	if revive_SO_data.rescuer then
		debug_pause("[PlayerBleedOut:on_rescue_SO_administered] Already had a rescuer!!!!", receiver_unit, revive_SO_data.rescuer)
	end
	revive_SO_data.rescuer = receiver_unit
	revive_SO_data.SO_id = nil
end
function PlayerBleedOut:on_rescue_SO_failed(revive_SO_data, rescuer)
	if revive_SO_data.rescuer then
		revive_SO_data.rescuer = nil
		PlayerBleedOut._register_revive_SO(revive_SO_data, revive_SO_data.variant)
	end
end
function PlayerBleedOut:on_rescue_SO_completed(revive_SO_data, rescuer)
	revive_SO_data.rescuer = nil
end
function PlayerBleedOut:on_rescue_SO_started(revive_SO_data, rescuer)
	for c_key, criminal in pairs(managers.groupai:state():all_AI_criminals()) do
		if c_key ~= rescuer:key() then
			local obj = criminal.unit:brain():objective()
			if obj and obj.type == "revive" and obj.follow_unit:key() == revive_SO_data.unit:key() then
				criminal.unit:brain():set_objective(nil)
			end
		end
	end
end
function PlayerBleedOut:verif_clbk_is_unit_deathguard(enemy_unit)
	local char_tweak = tweak_data.character[enemy_unit:base()._tweak_table]
	return char_tweak.deathguard
end
function PlayerBleedOut:pre_destroy(unit)
	if Network:is_server() then
		self:_unregister_revive_SO()
	end
end
function PlayerBleedOut:destroy()
	if Network:is_server() then
		self:_unregister_revive_SO()
	end
end
