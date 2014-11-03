PlayerIncapacitated = PlayerIncapacitated or class(PlayerStandard)
PlayerIncapacitated._update_movement = PlayerBleedOut._update_movement
function PlayerIncapacitated:init(unit)
	PlayerIncapacitated.super.init(self, unit)
	self._ids_tased_exit = Idstring("tased_exit")
end
function PlayerIncapacitated:enter(enter_data)
	PlayerIncapacitated.super.enter(self, enter_data)
	self._revive_SO_data = {
		unit = self._unit
	}
	self:_start_action_incapacitated(Application:time())
	self._unit:base():set_slot(self._unit, 4)
	self._unit:camera():camera_unit():base():set_target_tilt(80)
	self._unit:character_damage():on_incapacitated()
	self._unit:character_damage():on_incapacitated_state_enter()
	self._reequip_weapon = enter_data and enter_data.equip_weapon
	self._next_shock = 0.5
	self._taser_value = 0.5
	managers.groupai:state():on_criminal_neutralized(self._unit)
	if Network:is_server() then
		PlayerBleedOut._register_revive_SO(self._revive_SO_data, "revive")
	end
	managers.groupai:state():report_criminal_downed(self._unit)
end
function PlayerIncapacitated:_enter(enter_data)
end
function PlayerIncapacitated:exit(new_state_name)
	PlayerIncapacitated.super.exit(self, new_state_name)
	self:_end_action_incapacitated(Application:time())
	managers.environment_controller:set_taser_value(1)
	PlayerBleedOut._unregister_revive_SO(self)
	return {
		equip_weapon = self._reequip_weapon
	}
end
function PlayerIncapacitated:update(t, dt)
	PlayerIncapacitated.super.update(self, t, dt)
end
function PlayerIncapacitated:_update_check_actions(t, dt)
	local input = self:_get_input()
	if t > self._next_shock then
		self._unit:camera():play_shaker("player_taser_shock", 0.5, 10)
		self._next_shock = t + 0.5 + math.rand(2.5)
		self._camera_unit:base():start_shooting()
		self._recoil_t = t + 0.5
		self._camera_unit:base():recoil_kick(-2, 2)
		self._taser_value = 0.25
		managers.rumble:play("incapacitated_shock")
		self._unit:camera()._camera_unit:base():animate_fov(math.lerp(65, 75, math.random()), 0.33)
	elseif self._recoil_t and t > self._recoil_t then
		self._recoil_t = nil
		self._camera_unit:base():stop_shooting()
	end
	self._taser_value = math.step(self._taser_value, 0.75, dt / 2)
	managers.environment_controller:set_taser_value(self._taser_value)
	if input.btn_stats_screen_press then
		self._unit:base():set_stats_screen_visible(true)
	elseif input.btn_stats_screen_release then
		self._unit:base():set_stats_screen_visible(false)
	end
	self:_update_foley(t, input)
	local new_action
	new_action = new_action or self:_check_set_upgrade(t, input)
	self:_check_action_interact(t, input)
end
function PlayerIncapacitated:_check_action_interact(t, input)
	if input.btn_interact_press and (not self._intimidate_t or t - self._intimidate_t > tweak_data.player.movement_state.interaction_delay) then
		self._intimidate_t = t
		PlayerArrested.call_teammate(self, "f11", t, true, true)
	end
end
function PlayerIncapacitated:_start_action_incapacitated(t)
	self:_interupt_action_running(t)
	self._ducking = true
	self:_stance_entered()
	self:_update_crosshair_offset()
	self._unit:kill_mover()
	self._unit:activate_mover(Idstring("duck"))
	self._unit:camera():play_redirect(self._ids_tased_exit)
	self._unit:camera()._camera_unit:base():animate_fov(75)
end
function PlayerIncapacitated:_end_action_incapacitated(t)
	if not self:_can_stand() then
		return
	end
	self._ducking = false
	self:_stance_entered()
	self:_update_crosshair_offset()
	self._unit:kill_mover()
	self._unit:activate_mover(Idstring("stand"))
end
function PlayerIncapacitated:pre_destroy(unit)
	PlayerBleedOut._unregister_revive_SO(self)
end
function PlayerIncapacitated:destroy(unit)
	PlayerBleedOut._unregister_revive_SO(self)
	managers.environment_controller:set_taser_value(1)
end
