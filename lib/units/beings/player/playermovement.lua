require("lib/units/beings/player/states/PlayerMovementState")
require("lib/units/beings/player/states/PlayerEmpty")
require("lib/units/beings/player/states/PlayerStandard")
require("lib/units/beings/player/states/PlayerMaskOff")
require("lib/units/beings/player/states/PlayerBleedOut")
require("lib/units/beings/player/states/PlayerFatal")
require("lib/units/beings/player/states/PlayerArrested")
require("lib/units/beings/player/states/PlayerTased")
require("lib/units/beings/player/states/PlayerIncapacitated")
require("lib/units/beings/player/states/PlayerClean")
PlayerMovement = PlayerMovement or class()
function PlayerMovement:init(unit)
	self._unit = unit
	self._machine = self._unit:anim_state_machine()
	self._nav_tracker = nil
	self:set_driving("script")
	self._m_pos = unit:position()
	self._m_stand_pos = mvector3.copy(self._m_pos)
	mvector3.set_z(self._m_stand_pos, self._m_pos.z + 140)
	self._m_com = math.lerp(self._m_pos, self._m_stand_pos, 0.5)
	self._kill_overlay_t = Application:time() + 5
end
function PlayerMovement:post_init()
	self._m_head_rot = self._unit:camera()._m_cam_rot
	self._m_head_pos = self._unit:camera()._m_cam_pos
	if managers.navigation:is_data_ready() and (not Global.running_simulation or Global.running_simulation_with_mission) then
		self._nav_tracker = managers.navigation:create_nav_tracker(self._unit:position())
	end
	self:_setup_states()
end
function PlayerMovement:nav_tracker()
	return self._nav_tracker
end
function PlayerMovement:warp_to(pos, rot)
	self._unit:warp_to(rot, pos)
end
function PlayerMovement:_setup_states()
	local unit = self._unit
	self._states = {
		empty = PlayerEmpty:new(unit),
		standard = PlayerStandard:new(unit),
		mask_off = PlayerMaskOff:new(unit),
		bleed_out = PlayerBleedOut:new(unit),
		fatal = PlayerFatal:new(unit),
		arrested = PlayerArrested:new(unit),
		tased = PlayerTased:new(unit),
		incapacitated = PlayerIncapacitated:new(unit),
		clean = PlayerClean:new(unit)
	}
end
function PlayerMovement:set_character_anim_variables()
	local char_name = managers.criminals:character_name_by_unit(self._unit)
	local mesh_names
	local lvl_tweak_data = Global.level_data and Global.level_data.level_id and tweak_data.levels[Global.level_data.level_id]
	local unit_suit = lvl_tweak_data and lvl_tweak_data.unit_suit or "suit"
	if not lvl_tweak_data then
		mesh_names = {
			russian = "",
			american = "",
			german = "",
			spanish = ""
		}
	elseif unit_suit == "cat_suit" then
		mesh_names = {
			russian = "",
			american = "",
			german = "",
			spanish = "_chains"
		}
	elseif managers.player._player_mesh_suffix == "_scrubs" then
		mesh_names = {
			russian = "",
			american = "",
			german = "",
			spanish = "_chains"
		}
	else
		mesh_names = {
			russian = "_dallas",
			american = "_hoxton",
			german = "",
			spanish = "_chains"
		}
	end
	local mesh_name = Idstring("g_fps_hand" .. mesh_names[char_name] .. managers.player._player_mesh_suffix)
	local mesh_obj = self._unit:camera():camera_unit():get_object(mesh_name)
	if mesh_obj then
		if self._plr_mesh_name then
			local old_mesh_obj = self._unit:camera():camera_unit():get_object(self._plr_mesh_name)
			if old_mesh_obj then
				old_mesh_obj:set_visibility(false)
			end
		end
		self._plr_mesh_name = mesh_name
		mesh_obj:set_visibility(true)
	end
end
function PlayerMovement:set_driving(mode)
	self._unit:set_driving(mode)
end
function PlayerMovement:change_state(name)
	local exit_data
	if self._current_state then
		exit_data = self._current_state:exit(name)
	end
	local new_state = self._states[name]
	self._current_state = new_state
	self._current_state_name = name
	new_state:enter(exit_data)
	self._unit:network():send("sync_player_movement_state", self._current_state_name, self._unit:character_damage():down_time(), self._unit:id())
end
function PlayerMovement:update(unit, t, dt)
	self:_calculate_m_pose()
	if self._current_state then
		self._current_state:update(t, dt)
	end
	if self._kill_overlay_t and t > self._kill_overlay_t then
		self._kill_overlay_t = nil
		managers.overlay_effect:stop_effect()
	end
end
function PlayerMovement:set_position(pos)
	self._unit:set_position(pos)
end
function PlayerMovement:set_m_pos(pos)
	mvector3.set(self._m_pos, pos)
	mvector3.set(self._m_stand_pos, pos)
	mvector3.set_z(self._m_stand_pos, pos.z + 140)
end
function PlayerMovement:m_pos()
	return self._m_pos
end
function PlayerMovement:m_stand_pos()
	return self._m_stand_pos
end
function PlayerMovement:m_com()
	return self._m_com
end
function PlayerMovement:m_head_pos()
	return self._m_head_pos
end
function PlayerMovement:m_head_rot()
	return self._m_head_rot
end
function PlayerMovement:m_detect_pos()
	return self._m_head_pos
end
function PlayerMovement:running()
	return self._current_state._running
end
function PlayerMovement:downed()
	return self._current_state_name == "bleed_out" or self._current_state_name == "fatal" or self._current_state_name == "arrested" or self._current_state_name == "incapacitated"
end
function PlayerMovement:current_state()
	return self._current_state
end
function PlayerMovement:_calculate_m_pose()
	mvector3.lerp(self._m_com, self._m_pos, self._m_head_pos, 0.5)
end
function PlayerMovement:play_redirect(redirect_name, at_time)
	local result = self._unit:play_redirect(Idstring(redirect_name), at_time)
	return result ~= Idstring("") and result
end
function PlayerMovement:play_state(state_name, at_time)
	local result = self._unit:play_state(Idstring(state_name), at_time)
	return result ~= Idstring("") and result
end
function PlayerMovement:chk_action_forbidden(action_type)
	return self._current_state.chk_action_forbidden and self._current_state:chk_action_forbidden(action_type)
end
function PlayerMovement:get_melee_damage_result(...)
	return self._current_state.get_melee_damage_result and self._current_state:get_melee_damage_result(...)
end
function PlayerMovement:linked(state, physical, parent_unit)
	if state then
		self._link_data = {physical = physical, parent = parent_unit}
		parent_unit:base():add_destroy_listener("PlayerMovement" .. tostring(self._unit:key()), callback(self, self, "parent_clbk_unit_destroyed"))
	else
		self._link_data = nil
	end
end
function PlayerMovement:parent_clbk_unit_destroyed(parent_unit, key)
	self._link_data = nil
	parent_unit:base():remove_destroy_listener("PlayerMovement" .. tostring(self._unit:key()))
end
function PlayerMovement:is_physically_linked()
	return self._link_data and self._link_data.physical
end
function PlayerMovement:on_disarmed()
	if self._unit:character_damage()._god_mode then
		return
	end
	if self._current_state_name == "standard" or self._current_state_name == "bleed_out" then
		managers.player:set_player_state("arrested")
	end
end
function PlayerMovement:on_discovered()
	if self._current_state_name == "mask_off" then
		managers.player:set_player_state("standard")
	end
end
function PlayerMovement:on_SPOOCed()
	if self._unit:character_damage()._god_mode then
		return
	end
	if self._current_state_name == "standard" or self._current_state_name == "bleed_out" then
		managers.player:set_player_state("incapacitated")
	end
end
function PlayerMovement:on_tase_ended()
	if self._current_state_name == "tased" then
		self._current_state:on_tase_ended()
	end
end
function PlayerMovement:tased()
	return self._current_state_name == "tased"
end
function PlayerMovement:current_state_name()
	return self._current_state_name
end
function PlayerMovement:save(data)
	local peer_id = managers.network:game():member_from_unit(self._unit):peer():id()
	data.movement = {
		state_name = self._current_state_name,
		look_fwd = self._m_head_rot:y(),
		peer_id = peer_id,
		character_name = managers.criminals:character_name_by_unit(self._unit)
	}
	data.down_time = self._unit:character_damage():down_time()
	self._current_state:save(data.movement)
end
function PlayerMovement:pre_destroy(unit)
	self._current_state:pre_destroy(unit)
	if self._nav_tracker then
		managers.navigation:destroy_nav_tracker(self._nav_tracker)
		self._nav_tracker = nil
	end
end
function PlayerMovement:destroy(unit)
	if self._link_data then
		self._link_data.parent:base():remove_destroy_listener("PlayerMovement" .. tostring(self._unit:key()))
	end
	self._current_state:destroy(unit)
end
