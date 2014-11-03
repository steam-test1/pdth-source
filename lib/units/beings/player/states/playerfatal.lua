PlayerFatal = PlayerFatal or class(PlayerStandard)
PlayerFatal._update_movement = PlayerBleedOut._update_movement
function PlayerFatal:init(unit)
	PlayerFatal.super.init(self, unit)
end
function PlayerFatal:enter(enter_data)
	PlayerFatal.super.enter(self, enter_data)
	self:_start_action_dead(Application:time())
	self:_start_action_unequip_weapon(Application:time(), {selection_wanted = 1})
	self._unit:base():set_slot(self._unit, 4)
	self._unit:camera():camera_unit():base():set_target_tilt(80)
	if self._ext_movement:nav_tracker() then
		managers.groupai:state():on_criminal_neutralized(self._unit)
	end
	self._unit:character_damage():on_fatal_state_enter()
	if Network:is_server() and enter_data then
		if enter_data.revive_SO_data then
			self._revive_SO_data = enter_data.revive_SO_data
		end
		self._deathguard_SO_id = enter_data.deathguard_SO_id
	end
	self._reequip_weapon = enter_data and enter_data.equip_weapon
end
function PlayerFatal:_enter(enter_data)
end
function PlayerFatal:exit(new_state_name)
	PlayerFatal.super.exit(self, new_state_name)
	self:_end_action_dead(Application:time())
	if Network:is_server() then
		PlayerBleedOut._unregister_revive_SO(self)
	end
	self._revive_SO_data = nil
	if self._stats_screen then
		self._stats_screen = false
		managers.hud:hide_stats_screen()
		managers.experience:hide_stats()
	end
	return {
		equip_weapon = self._reequip_weapon
	}
end
function PlayerFatal:update(t, dt)
	PlayerFatal.super.update(self, t, dt)
end
function PlayerFatal:_update_check_actions(t, dt)
	local input = self:_get_input()
	self:_update_foley(t, input)
	local new_action
	new_action = new_action or self:_check_set_upgrade(t, input)
	if input.btn_stats_screen_press then
		self._unit:base():set_stats_screen_visible(true)
	elseif input.btn_stats_screen_release then
		self._unit:base():set_stats_screen_visible(false)
	end
	self:_check_action_interact(t, input)
end
function PlayerFatal:_check_action_interact(t, input)
	if input.btn_interact_press and (not self._intimidate_t or t - self._intimidate_t > tweak_data.player.movement_state.interaction_delay) then
		self._intimidate_t = t
		PlayerArrested.call_teammate(self, "f11", t, true, true)
	end
end
function PlayerFatal:_start_action_dead(t)
	self:_interupt_action_running(t)
	self._ducking = true
	self:_stance_entered()
	self:_update_crosshair_offset()
	self._unit:kill_mover()
	self._unit:activate_mover(Idstring("duck"))
end
function PlayerFatal:_end_action_dead(t)
	if not self:_can_stand() then
		return
	end
	self._ducking = false
	self:_stance_entered()
	self:_update_crosshair_offset()
	self._unit:kill_mover()
	self._unit:activate_mover(Idstring("stand"))
end
function PlayerFatal:pre_destroy(unit)
	if Network:is_server() then
		PlayerBleedOut._unregister_revive_SO(self)
	end
end
function PlayerFatal:destroy()
	if Network:is_server() then
		PlayerBleedOut._unregister_revive_SO(self)
	end
end
