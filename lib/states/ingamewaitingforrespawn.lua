core:import("CoreUnit")
require("lib/states/GameState")
IngameWaitingForRespawnState = IngameWaitingForRespawnState or class(GameState)
IngameWaitingForRespawnState.GUI_SPECTATOR_FULLSCREEN = Idstring("guis/spectator_fullscreen")
IngameWaitingForRespawnState.GUI_SPECTATOR = Idstring("guis/spectator_mode")
IngameWaitingForRespawnState.PLAYER_HUD = Idstring("guis/player_hud")
IngameWaitingForRespawnState.XP_HUD = Idstring("guis/experience_hud")
IngameWaitingForRespawnState.PLAYER_INFO_HUD = Idstring("guis/player_info_hud")
function IngameWaitingForRespawnState:init(game_state_machine)
	GameState.init(self, "ingame_waiting_for_respawn", game_state_machine)
	self._slotmask = managers.slot:get_mask("world_geometry")
	self._fwd = Vector3(1, 0, 0)
	self._up_offset = math.UP * 80
end
function IngameWaitingForRespawnState:_setup_controller()
	self._controller = managers.controller:create_controller("waiting_for_respawn", managers.controller:get_default_wrapper_index(), false)
	self._next_player_cb = callback(self, self, "cb_next_player")
	self._prev_player_cb = callback(self, self, "cb_prev_player")
	self._controller:add_trigger("left", self._prev_player_cb)
	self._controller:add_trigger("right", self._next_player_cb)
	self._controller:add_trigger("primary_attack", self._prev_player_cb)
	self._controller:add_trigger("secondary_attack", self._next_player_cb)
	self._controller:set_enabled(true)
end
function IngameWaitingForRespawnState:_clear_controller()
	if self._controller then
		self._controller:remove_trigger("left", self._prev_player_cb)
		self._controller:remove_trigger("right", self._next_player_cb)
		self._controller:remove_trigger("primary_attack", self._prev_player_cb)
		self._controller:remove_trigger("secondary_attack", self._next_player_cb)
		self._controller:set_enabled(false)
		self._controller:destroy()
		self._controller = nil
	end
end
function IngameWaitingForRespawnState:set_controller_enabled(enabled)
	if self._controller then
		self._controller:set_enabled(enabled)
	end
end
function IngameWaitingForRespawnState:_setup_camera()
	self._camera_object = World:create_camera()
	self._camera_object:set_near_range(3)
	self._camera_object:set_far_range(1000000)
	self._camera_object:set_fov(75)
	self._viewport = managers.viewport:new_vp(0, 0, 1, 1, "spectator", CoreManagerBase.PRIO_WORLDCAMERA)
	self._viewport:set_camera(self._camera_object)
	self._viewport:set_environment(managers.environment_area:default_environment())
	self._viewport:set_active(true)
end
function IngameWaitingForRespawnState:_clear_camera()
	self._viewport:destroy()
	self._viewport = nil
	World:delete_camera(self._camera_object)
	self._camera_object = nil
end
function IngameWaitingForRespawnState:_setup_sound_listener()
	self._listener_id = managers.listener:add_listener("spectator_camera", self._camera_object, self._camera_object, nil, false)
	managers.listener:add_set("spectator_camera", {
		"spectator_camera"
	})
	self._listener_activation_id = managers.listener:activate_set("main", "spectator_camera")
	self._sound_check_object = managers.sound_environment:add_check_object({
		object = self._camera_object,
		active = true,
		primary = true
	})
end
function IngameWaitingForRespawnState:_clear_sound_listener()
	managers.sound_environment:remove_check_object(self._sound_check_object)
	managers.listener:remove_listener(self._listener_id)
	managers.listener:remove_set("spectator_camera")
	self._listener_id = nil
end
function IngameWaitingForRespawnState:_create_spectator_data()
	local all_teammates = managers.groupai:state():all_char_criminals()
	local teammate_list = {}
	for u_key, u_data in pairs(all_teammates) do
		table.insert(teammate_list, u_key)
	end
	self._spectator_data = {
		teammate_records = all_teammates,
		teammate_list = teammate_list,
		watch_u_key = teammate_list[1]
	}
end
function IngameWaitingForRespawnState:_begin_game_enter_transition()
	if self._ready_to_spawn_t then
		return
	end
	self._auto_respawn_t = nil
	local overlay_effect_desc = tweak_data.overlay_effects.spectator
	local fade_in_duration = overlay_effect_desc.fade_in
	self._fade_in_overlay_eff_id = managers.overlay_effect:play_effect(overlay_effect_desc)
	self._ready_to_spawn_t = TimerManager:game():time() + fade_in_duration
end
function IngameWaitingForRespawnState.request_player_spawn(peer_to_spawn)
	if Network:is_client() then
		local peer_id = managers.network:session():local_peer():id()
		managers.network:session():server_peer():send("request_spawn_member", peer_id)
	else
		local possible_criminals = {}
		for u_key, u_data in pairs(managers.groupai:state():all_player_criminals()) do
			table.insert(possible_criminals, u_key)
		end
		local spawn_at = managers.groupai:state():all_player_criminals()[possible_criminals[math.random(1, #possible_criminals)]]
		if spawn_at then
			local spawn_pos = spawn_at.unit:position()
			local spawn_rot = spawn_at.unit:rotation()
			local peer_id = peer_to_spawn or 1
			local crim_name = managers.criminals:character_name_by_peer_id(peer_id)
			local first_crim = managers.trade:get_criminal_to_trade()
			if first_crim and first_crim.id == crim_name then
				managers.trade:cancel_trade()
			end
			managers.trade:sync_set_trade_spawn(crim_name)
			managers.network:session():send_to_peers_synched("set_trade_spawn", crim_name)
			local sp_id = "IngameWaitingForRespawnState"
			local spawn_point = {position = spawn_pos, rotation = spawn_rot}
			managers.network:register_spawn_point(sp_id, spawn_point)
			managers.network:game():spawn_member_by_id(peer_id, sp_id, true)
			managers.network:unregister_spawn_point(sp_id)
		end
	end
end
function IngameWaitingForRespawnState:update(t, dt)
	if self._player_state_change_needed and not alive(managers.player:player_unit()) then
		self._player_state_change_needed = nil
		managers.player:set_player_state("standard")
	end
	local btn_stats_screen_press = not self._stats_screen and self._controller:get_input_pressed("stats_screen")
	local btn_stats_screen_release = self._stats_screen and self._controller:get_input_released("stats_screen")
	local btn_upgrade_alternative1_press = self._stats_screen and self._controller:get_input_pressed("upgrade_alternative1")
	local btn_upgrade_alternative2_press = self._stats_screen and self._controller:get_input_pressed("upgrade_alternative2")
	local btn_upgrade_alternative3_press = self._stats_screen and self._controller:get_input_pressed("upgrade_alternative3")
	local btn_upgrade_alternative4_press = self._stats_screen and self._controller:get_input_pressed("upgrade_alternative4")
	if btn_stats_screen_press then
		self._stats_screen = true
		managers.hud:show_stats_screen()
		managers.experience:show_stats()
	elseif btn_stats_screen_release then
		self._stats_screen = false
		managers.hud:hide_stats_screen()
		managers.experience:hide_stats()
	end
	local hud = managers.hud:script(PlayerBase.XP_HUD)
	if btn_upgrade_alternative1_press then
		hud:set_alternative(1)
	elseif btn_upgrade_alternative2_press then
		hud:set_alternative(2)
	elseif btn_upgrade_alternative3_press then
		hud:set_alternative(3)
	elseif btn_upgrade_alternative4_press then
		hud:set_alternative(4)
	end
	if self._auto_respawn_t then
		local time = self._auto_respawn_t - t
		local s = time % 60
		local m = math.floor(time / 60)
		if 0 < time then
			local text = m .. ":" .. (math.round(s) < 10 and "0" .. math.round(s) or math.round(s))
			managers.hud:script(self.GUI_SPECTATOR).trade_text4:set_text(string.upper(managers.localization:text("menu_spectator_respawning_in", {
				TIME = tostring(text)
			})))
		else
			managers.hud:script(self.GUI_SPECTATOR).trade_text4:set_visible(false)
		end
		if t > self._auto_respawn_t then
			self._auto_respawn_t = nil
			self:_begin_game_enter_transition()
		end
	elseif self._ready_to_spawn_t and t > self._ready_to_spawn_t then
		IngameWaitingForRespawnState.request_player_spawn()
	end
	if self._respawn_delay then
		self._respawn_delay = managers.trade:respawn_delay_by_name(managers.criminals:local_character_name())
		if 0 >= self._respawn_delay then
			self._respawn_delay = nil
			managers.hud:script(self.GUI_SPECTATOR).trade_text2:set_visible(false)
			managers.hud:script(self.GUI_SPECTATOR).trade_text3:set_visible(false)
		else
			local time = self._respawn_delay
			local text = math.round(time) < 10 and "0" .. math.round(time) or math.round(time)
			managers.hud:script(self.GUI_SPECTATOR).trade_text3:set_text(string.upper(managers.localization:text("menu_spectator_being_traded_civ_killed", {
				CIVS_KILLED = tostring(self._hostages_killed),
				SPAWN_DELAY = tostring(self._respawn_delay)
			})))
		end
	end
	if self._play_too_long_line_t and t > self._play_too_long_line_t and managers.groupai:state():bain_state() then
		self._play_too_long_line_t = nil
		managers.dialog:queue_dialog("Play_ban_h38x", {})
	end
	self:_upd_watch(t, dt)
end
function IngameWaitingForRespawnState:_upd_watch(t, dt)
	self:_refresh_teammate_list()
	if self._spectator_data.watch_u_key then
		if managers.hud:visible(self.GUI_SPECTATOR_FULLSCREEN) then
			managers.hud:hide(self.GUI_SPECTATOR_FULLSCREEN)
		end
		local look_d = self._controller:get_input_axis("look")
		local watch_u_record = self._spectator_data.teammate_records[self._spectator_data.watch_u_key]
		local watch_u_head_pos = watch_u_record.unit:movement():m_head_pos()
		local controller_type = self._controller:get_default_controller_id()
		if controller_type == "keyboard" then
			self._fwd = self._fwd:rotate_with(Rotation(math.UP, 0.5 * -look_d.x))
		elseif mvector3.length(look_d) > 0.1 then
			local stick_input_x = look_d.x
			stick_input_x = stick_input_x / (1.3 - 0.3 * (1 - math.abs(look_d.y)))
			stick_input_x = stick_input_x * dt * 180
			self._fwd = self._fwd:rotate_with(Rotation(math.UP, -0.5 * stick_input_x))
		end
		local target = watch_u_record.unit:position() + self._up_offset
		local eye_pos = target - self._fwd * 150 + self._up_offset
		local eye_rot = Rotation(self._fwd, math.UP)
		target = target:with_z(eye_pos.z)
		local col_ray = World:raycast("ray", target, eye_pos, "slot_mask", self._slotmask)
		local dir_new, dis_new
		if col_ray then
			dir_new = col_ray.normal
			dis_new = math.max(col_ray.distance - 30, 0)
		else
			dir_new = eye_pos - target
			dis_new = dir_new:length()
			dir_new = dir_new:normalized()
		end
		if self._dis_curr and dis_new > self._dis_curr then
			local speed = math.max((dis_new - self._dis_curr) / 5, 1.5)
			self._dis_curr = math.lerp(self._dis_curr, dis_new, speed * dt)
		else
			self._dis_curr = dis_new
		end
		eye_pos = target + dir_new * self._dis_curr
		self._camera_object:set_position(eye_pos)
		self._camera_object:set_rotation(eye_rot)
	elseif not managers.hud:visible(self.GUI_SPECTATOR_FULLSCREEN) then
		managers.hud:show(self.GUI_SPECTATOR_FULLSCREEN)
	end
end
function IngameWaitingForRespawnState:at_enter()
	managers.overlay_effect:play_effect(tweak_data.overlay_effects.fade_in)
	self:_setup_camera()
	self:_setup_controller()
	self:_setup_sound_listener()
	self._dis_curr = 150
	managers.statistics:in_custody()
	managers.menu:set_mouse_sensitivity(false)
	self._player_state_change_needed = true
	self._respawn_delay = nil
	self._play_too_long_line_t = nil
	managers.hud:load_hud(self.GUI_SPECTATOR_FULLSCREEN, false, false, false, {})
	managers.hud:load_hud(self.GUI_SPECTATOR, false, true, true, {})
	managers.hud:show(PlayerBase.XP_HUD)
	managers.hud:show(self.GUI_SPECTATOR)
	managers.hud:show(self.PLAYER_INFO_HUD)
	managers.hud:show(PlayerBase.PLAYER_INFO_HUD_FULLSCREEN)
	managers.hud:script(self.GUI_SPECTATOR).trade_text1:set_visible(false)
	managers.hud:script(self.GUI_SPECTATOR).trade_text2:set_visible(false)
	managers.hud:script(self.GUI_SPECTATOR).trade_text3:set_visible(false)
	if tweak_data.player.damage.automatic_respawn_time then
		self._auto_respawn_t = Application:time() + tweak_data.player.damage.automatic_respawn_time
		managers.hud:script(self.GUI_SPECTATOR).trade_text4:set_visible(true)
	else
		managers.hud:script(self.GUI_SPECTATOR).trade_text4:set_visible(false)
	end
	if not managers.hud:exists(self.PLAYER_HUD) then
		managers.hud:load_hud(self.PLAYER_HUD, false, false, true, {})
	end
	if not managers.hud:exists(self.XP_HUD) then
		managers.hud:load_hud(self.XP_HUD, false, false, true, {})
	end
	if not managers.hud:exists(self.PLAYER_INFO_HUD) then
		managers.hud:load_hud(self.PLAYER_INFO_HUD, false, false, true, {})
	end
	self:_create_spectator_data()
	self._next_player_cb()
	if Network:is_server() then
		local respawn_delay = managers.trade:respawn_delay_by_name(managers.criminals:local_character_name())
		local hostages_killed = managers.trade:hostages_killed_by_name(managers.criminals:local_character_name())
		self:trade_death(respawn_delay, hostages_killed)
	end
end
function IngameWaitingForRespawnState:at_exit()
	managers.hud:hide(self.GUI_SPECTATOR)
	managers.hud:hide(PlayerBase.XP_HUD)
	managers.hud:hide(self.PLAYER_INFO_HUD)
	managers.hud:hide(PlayerBase.PLAYER_INFO_HUD_FULLSCREEN)
	managers.overlay_effect:fade_out_effect(self._fade_in_overlay_eff_id)
	if managers.hud:visible(self.GUI_SPECTATOR_FULLSCREEN) then
		managers.hud:hide(self.GUI_SPECTATOR_FULLSCREEN)
	end
	self:_clear_controller()
	self:_clear_camera()
	self:_clear_sound_listener()
	self._ready_to_spawn_t = nil
	self._fade_in_overlay_eff_id = nil
end
function IngameWaitingForRespawnState:_refresh_teammate_list()
	local all_teammates = self._spectator_data.teammate_records
	local teammate_list = self._spectator_data.teammate_list
	local lost_teammate_at_i
	local i = #teammate_list
	while 0 < i do
		local u_key = teammate_list[i]
		local teammate_data = all_teammates[u_key]
		if not teammate_data then
			table.remove(teammate_list, i)
			if u_key == self._spectator_data.watch_u_key then
				lost_teammate_at_i = i
				self._spectator_data.watch_u_key = nil
			end
		end
		i = i - 1
	end
	if #teammate_list ~= table.size(all_teammates) then
		for u_key, u_data in pairs(all_teammates) do
			local add = true
			for i_key, test_u_key in ipairs(teammate_list) do
				if test_u_key == u_key then
					add = false
					break
				end
			end
			if add then
				table.insert(teammate_list, u_key)
			end
		end
	end
	if lost_teammate_at_i then
		self._spectator_data.watch_u_key = teammate_list[math.clamp(lost_teammate_at_i, 1, #teammate_list)]
	end
end
function IngameWaitingForRespawnState:_get_teammate_index_by_unit_key(u_key)
	for i_key, test_u_key in ipairs(self._spectator_data.teammate_list) do
		if test_u_key == u_key then
			return i_key
		end
	end
end
function IngameWaitingForRespawnState:cb_next_player()
	self:_refresh_teammate_list()
	local watch_u_key = self._spectator_data.watch_u_key
	if not watch_u_key then
		return
	end
	local i_watch = self:_get_teammate_index_by_unit_key(watch_u_key)
	if i_watch == #self._spectator_data.teammate_list then
		i_watch = 1
	else
		i_watch = i_watch + 1
	end
	watch_u_key = self._spectator_data.teammate_list[i_watch]
	self._spectator_data.watch_u_key = watch_u_key
	self:_upd_hud_watch_character_name()
	self._dis_curr = nil
end
function IngameWaitingForRespawnState:cb_prev_player()
	self:_refresh_teammate_list()
	local watch_u_key = self._spectator_data.watch_u_key
	if not watch_u_key then
		return
	end
	local i_watch = self:_get_teammate_index_by_unit_key(watch_u_key)
	if i_watch == 1 then
		i_watch = #self._spectator_data.teammate_list
	else
		i_watch = i_watch - 1
	end
	watch_u_key = self._spectator_data.teammate_list[i_watch]
	self._spectator_data.watch_u_key = watch_u_key
	self:_upd_hud_watch_character_name()
	self._dis_curr = nil
end
function IngameWaitingForRespawnState:_upd_hud_watch_character_name()
	local new_text
	if self._spectator_data.watch_u_key then
		new_text = managers.localization:text("menu_spectator_spactating") .. self._spectator_data.teammate_records[self._spectator_data.watch_u_key].unit:base():nick_name()
	else
		new_text = ""
	end
	managers.hud:script(self.GUI_SPECTATOR).text_title:set_text(string.upper(new_text))
end
function IngameWaitingForRespawnState:trade_death(respawn_delay, hostages_killed)
	managers.hud:script(self.GUI_SPECTATOR).trade_text1:set_visible(false)
	self._respawn_delay = managers.trade:respawn_delay_by_name(managers.criminals:local_character_name())
	self._hostages_killed = hostages_killed
	if self._respawn_delay > 0 then
		managers.hud:script(self.GUI_SPECTATOR).trade_text2:set_text(string.upper(managers.localization:text("menu_spectator_being_traded_hesitant")))
		managers.hud:script(self.GUI_SPECTATOR).trade_text3:set_text(string.upper(managers.localization:text("menu_spectator_being_traded_civ_killed", {
			CIVS_KILLED = tostring(self._hostages_killed),
			SPAWN_DELAY = tostring(self._respawn_delay)
		})))
		managers.hud:script(self.GUI_SPECTATOR).trade_text2:set_visible(true)
		managers.hud:script(self.GUI_SPECTATOR).trade_text3:set_visible(true)
	end
	if not Global.game_settings.single_player and managers.groupai:state():bain_state() then
		if managers.groupai:state():get_assault_mode() then
			managers.dialog:queue_dialog("ban_h31x", {})
		elseif hostages_killed == 0 then
			managers.dialog:queue_dialog("Play_ban_h32x", {})
		elseif hostages_killed < 3 then
			managers.dialog:queue_dialog("Play_ban_h33x", {})
		else
			managers.dialog:queue_dialog("Play_ban_h34x", {})
		end
	end
end
function IngameWaitingForRespawnState:finish_trade()
	self:_begin_game_enter_transition()
end
function IngameWaitingForRespawnState:begin_trade()
	managers.hud:script(self.GUI_SPECTATOR).trade_text1:set_text(string.upper(managers.localization:text("menu_spectator_being_traded")))
	managers.hud:script(self.GUI_SPECTATOR).trade_text1:set_visible(true)
	local crims = {}
	for k, d in pairs(managers.groupai:state():all_char_criminals()) do
		crims[k] = d
	end
	if managers.groupai:state():bain_state() then
		if table.size(crims) > 1 then
			managers.dialog:queue_dialog("Play_ban_h36x", {})
		else
			local _, data = next(crims)
			local char_code = managers.criminals:character_static_data_by_unit(data.unit).ssuffix
			managers.dialog:queue_dialog("Play_ban_h37" .. char_code, {})
		end
	end
	self._play_too_long_line_t = Application:time() + 60
end
function IngameWaitingForRespawnState:cancel_trade()
	managers.hud:script(self.GUI_SPECTATOR).trade_text1:set_visible(false)
end
function IngameWaitingForRespawnState:on_server_left()
	IngameCleanState.on_server_left(self)
end
function IngameWaitingForRespawnState:on_kicked()
	IngameCleanState.on_kicked(self)
end
function IngameWaitingForRespawnState:on_disconnected()
	IngameCleanState.on_disconnected(self)
end
