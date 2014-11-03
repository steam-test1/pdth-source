PlayerClean = PlayerClean or class(PlayerStandard)
function PlayerClean:init(unit)
	PlayerClean.super.init(self, unit)
	self._ids_unequip = Idstring("unequip")
end
function PlayerClean:enter(enter_data)
	self._ducking = enter_data and enter_data.ducking
	PlayerClean.super.enter(self, enter_data)
end
function PlayerClean:_enter(enter_data)
	local equipped_selection = self._unit:inventory():equipped_selection()
	if equipped_selection ~= 1 then
		self._previous_equipped_selection = equipped_selection
		self._ext_inventory:equip_selection(1, false)
		managers.upgrades:setup_current_weapon()
	end
	if self._unit:camera():anim_data().equipped then
		self._unit:camera():play_redirect(self._ids_unequip)
	end
	self._unit:base():set_slot(self._unit, 4)
end
function PlayerClean:exit(new_state_name)
	PlayerClean.super.exit(self)
	if self._previous_equipped_selection then
		self._unit:inventory():equip_selection(self._previous_equipped_selection, false)
		self._previous_equipped_selection = nil
	end
	self._unit:base():set_slot(self._unit, 2)
	return
end
function PlayerClean:update(t, dt)
	PlayerClean.super.update(self, t, dt)
end
function PlayerClean:_update_check_actions(t, dt)
	local input = self:_get_input()
	self._stick_move = self._controller:get_input_axis("move")
	if mvector3.length(self._stick_move) < 0.1 then
		self._move_dir = nil
	else
		self._move_dir = mvector3.copy(self._stick_move)
		local cam_flat_rot = Rotation(self._cam_fwd_flat, math.UP)
		mvector3.rotate_with(self._move_dir, cam_flat_rot)
	end
	if input.btn_stats_screen_press then
		self._unit:base():set_stats_screen_visible(true)
	elseif input.btn_stats_screen_release then
		self._unit:base():set_stats_screen_visible(false)
	end
	self:_update_foley(t, input)
	local new_action
	new_action = new_action or self:_check_set_upgrade(t, input)
	if not new_action then
	end
	if not new_action and self._ducking then
		self:_end_action_ducking(t)
	end
end
function PlayerClean:_get_walk_headbob()
	return 0.0125
end
function PlayerClean:_check_action_interact(t, input)
	local new_action
	local interaction_wanted = input.btn_interact_press
	if interaction_wanted then
		local action_forbidden = self:chk_action_forbidden("interact") or managers.hud:showing_scenario()
		if not action_forbidden then
			self:_start_action_state_standard(t)
		end
	end
	return new_action
end
function PlayerClean:_start_action_state_standard(t)
	managers.player:set_player_state("standard")
end
