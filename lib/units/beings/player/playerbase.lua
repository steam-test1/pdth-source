PlayerBase = PlayerBase or class(UnitBase)
PlayerBase.PLAYER_HUD = Idstring("guis/player_hud")
PlayerBase.PLAYER_INFO_HUD_FULLSCREEN = Idstring("guis/player_info_hud_fullscreen")
PlayerBase.XP_HUD = Idstring("guis/experience_hud")
PlayerBase.PLAYER_INFO_HUD = Idstring("guis/player_info_hud")
PlayerBase.PLAYER_DOWNED_HUD = Idstring("guis/player_downed_hud")
function PlayerBase:init(unit)
	UnitBase.init(self, unit, false)
	self._unit = unit
	self:_setup_hud()
	self._id = managers.player:player_id(self._unit)
	self._rumble_pos_callback = callback(self, self, "get_rumble_position")
	self:_setup_controller()
	self._unit:set_extension_update_enabled(Idstring("base"), false)
	self._stats_screen_visible = false
	managers.game_play_central:restart_portal_effects()
end
function PlayerBase:update(unit, t, dt)
	if self._wanted_controller_enabled_t then
		if self._wanted_controller_enabled_t <= 0 then
			if self._wanted_controller_enabled then
				self._controller:set_enabled(true)
				self._wanted_controller_enabled = nil
				self._wanted_controller_enabled_t = nil
			end
			self._unit:set_extension_update_enabled(Idstring("base"), false)
		else
			self._wanted_controller_enabled_t = self._wanted_controller_enabled_t - 1
		end
	end
end
function PlayerBase:stats_screen_visible()
	return self._stats_screen_visible
end
function PlayerBase:set_stats_screen_visible(visible)
	self._stats_screen_visible = visible
	if self._stats_screen_visible then
		managers.hud:show_stats_screen()
		managers.experience:show_stats()
	else
		managers.hud:hide_stats_screen()
		managers.experience:hide_stats()
	end
end
function PlayerBase:set_enabled(enabled)
	self._unit:set_extension_update_enabled(Idstring("movement"), enabled)
end
function PlayerBase:_setup_hud()
	if not managers.hud:exists(self.PLAYER_HUD) then
		managers.hud:load_hud(self.PLAYER_HUD, false, false, true, {})
	end
	if not managers.hud:exists(self.PLAYER_INFO_HUD_FULLSCREEN) then
		managers.hud:load_hud(self.PLAYER_INFO_HUD_FULLSCREEN, false, false, false, {})
	end
	if not managers.hud:exists(self.XP_HUD) then
		managers.hud:load_hud(self.XP_HUD, false, false, true, {})
	end
	if not managers.hud:exists(self.PLAYER_INFO_HUD) then
		managers.hud:load_hud(self.PLAYER_INFO_HUD, false, false, true, {})
	end
	if not managers.hud:exists(self.PLAYER_DOWNED_HUD) then
		managers.hud:load_hud(self.PLAYER_DOWNED_HUD, false, false, true, {})
	end
end
function PlayerBase:_equip_default_weapon()
end
function PlayerBase:post_init()
	self._unit:movement():post_init()
	self:_equip_default_weapon()
	if self._unit:movement():nav_tracker() then
		managers.groupai:state():register_criminal(self._unit)
	else
		self._unregistered = true
	end
end
function PlayerBase:_setup_controller()
	self._controller = managers.controller:create_controller("player_" .. tostring(self._id), nil, false)
	managers.rumble:register_controller(self._controller, self._rumble_pos_callback)
end
function PlayerBase:id()
	return self._id
end
function PlayerBase:nick_name()
	return Global.local_member:peer():name()
end
function PlayerBase:set_controller_enabled(enabled)
	if not self._controller then
		return
	end
	if not enabled then
		self._controller:set_enabled(false)
	end
	self._wanted_controller_enabled = enabled
	if self._wanted_controller_enabled then
		self._wanted_controller_enabled_t = 1
		self._unit:set_extension_update_enabled(Idstring("base"), true)
	end
end
function PlayerBase:controller()
	return self._controller
end
function PlayerBase:anim_data_clbk_footstep(foot)
	local obj = self._unit:orientation_object()
	local proj_dir = math.UP
	local proj_from = obj:position()
	local proj_to = proj_from - proj_dir * 30
	local material_name, pos, norm = World:pick_decal_material(proj_from, proj_to, managers.slot:get_mask("surface_move"))
	self._unit:sound():play_footstep(foot, material_name)
end
function PlayerBase:get_rumble_position()
	return self._unit:position() + math.UP * 100
end
function PlayerBase:replenish()
	for _, weapon in pairs(self._unit:inventory():available_selections()) do
		if alive(weapon.unit) then
			weapon.unit:base():replenish()
			managers.hud:set_weapon_ammo_by_unit(weapon.unit)
		end
	end
	managers.hud:set_ammo_amount(self._unit:inventory():equipped_unit():base():ammo_info())
	self._unit:character_damage():replenish()
end
function PlayerBase:_unregister()
	if not self._unregistered then
		managers.groupai:state():unregister_criminal(self._unit)
		self._unregistered = true
	end
end
function PlayerBase:pre_destroy(unit)
	self:_unregister()
	UnitBase.pre_destroy(self, unit)
	managers.player:player_destroyed(self._id)
	if self._controller then
		managers.rumble:unregister_controller(self._controller, self._rumble_pos_callback)
		self._controller:destroy()
		self._controller = nil
	end
	if managers.hud:alive(self.PLAYER_HUD) then
		managers.hud:clear_weapons()
		managers.hud:hide(self.PLAYER_HUD)
	end
	self:set_stats_screen_visible(false)
	if Global.local_member then
		Global.local_member:set_unit(nil)
	end
	unit:movement():pre_destroy(unit)
end
