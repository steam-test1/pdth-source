require("lib/states/GameState")
MissionEndState = MissionEndState or class(GameState)
MissionEndState.GUI_FULLSCREEN = Idstring("guis/victoryscreen/victoryscreen_fullscreen")
MissionEndState.GUI_SAFERECT = Idstring("guis/victoryscreen/victoryscreen_saferect")
function MissionEndState:init(name, game_state_machine, setup)
	GameState.init(self, name, game_state_machine)
	if managers.hud then
		self._setup = true
		managers.hud:load_hud(self.GUI_SAFERECT, false, true, true, {})
		managers.hud:load_hud(self.GUI_FULLSCREEN, false, true, false, {})
	end
	self._continue_cb = callback(self, self, "_continue")
	self._controller = nil
end
function MissionEndState:setup_controller()
	if not self._controller then
		self._controller = managers.controller:create_controller("victoryscreen", managers.controller:get_default_wrapper_index(), false)
		self._controller:add_trigger("continue", self._continue_cb)
	end
	local enabled = not managers.menu:active_menu()
	self._controller:set_enabled(enabled)
end
function MissionEndState:set_controller_enabled(enabled)
	if self._controller then
		self._controller:set_enabled(enabled)
	end
end
function MissionEndState:at_enter(old_state, params)
	managers.platform:set_presence("Mission_end")
	managers.hud:remove_updator("point_of_no_return")
	if Network:is_server() then
		managers.network.matchmake:set_server_joinable(false)
	end
	if not self._success then
		managers.mission:pre_destroy()
	end
	if SystemInfo:platform() == Idstring("WIN32") and managers.network.account:has_alienware() then
		LightFX:set_lamps(0, 255, 0, 255)
	end
	self._completion_bonus_done = false
	self:setup_controller()
	if not self._setup then
		self._setup = true
		managers.hud:load_hud(self.GUI_SAFERECT, false, true, true, {})
		managers.hud:load_hud(self.GUI_FULLSCREEN, false, true, false, {})
	end
	self._old_state = old_state
	managers.hud:set_chat_output_state("mission_end")
	managers.hud:show(PlayerBase.PLAYER_INFO_HUD_FULLSCREEN)
	managers.hud:show(PlayerBase.PLAYER_INFO_HUD)
	for _, component in ipairs(managers.hud:script(PlayerBase.PLAYER_INFO_HUD).panel:children()) do
		if component:name() == "title_mid_text" or component:name() == "present_mid_text" or component:name() == "present_mid_icon" then
			if not managers.hud._mid_text_presenting or managers.hud._mid_text_presenting.type ~= "challenge" then
				component:set_visible(false)
			end
		else
			component:set_visible(false)
		end
	end
	if not managers.hud._mid_text_presenting or managers.hud._mid_text_presenting.type ~= "challenge" then
		managers.hud:script(PlayerBase.PLAYER_INFO_HUD_FULLSCREEN).present_background:set_visible(false)
	end
	managers.hud:show(PlayerBase.XP_HUD)
	managers.hud:show(self.GUI_SAFERECT)
	managers.hud:script(self.GUI_SAFERECT):reset()
	managers.hud:show(self.GUI_FULLSCREEN)
	managers.hud:script(self.GUI_SAFERECT):set_success(self._success, self._server_left)
	managers.hud:script(self.GUI_SAFERECT):hide_legends()
	self:_set_continue_button_text()
	managers.groupai:state():set_AI_enabled(false)
	local player = managers.player:player_unit()
	if player then
		player:character_damage():set_invulnerable(true)
		player:character_damage():stop_heartbeat()
		player:base():set_stats_screen_visible(false)
		if player:movement():current_state():shooting() then
			player:movement():current_state()._equipped_unit:base():stop_shooting()
		end
		if player:movement():current_state()._interupt_action_interact then
			player:movement():current_state():_interupt_action_interact()
		end
	end
	if self._success then
		if params.personal_win then
			if managers.achievment:get_script_data("last_man_standing") then
				managers.challenges:set_flag("last_man_standing")
			end
			if not managers.statistics:is_dropin() then
				if managers.achievment:get_script_data("dodge_this_active") and not managers.achievment:get_script_data("dodge_this_fail") and tweak_data:difficulty_to_index(Global.game_settings.difficulty) >= 2 then
					managers.challenges:set_flag("dodge_this")
				end
				if not managers.achievment:get_script_data("pacifist_fail") and Global.level_data.level_id == "suburbia" and tweak_data:difficulty_to_index(Global.game_settings.difficulty) >= 3 then
					managers.challenges:set_flag("pacifist")
				end
				if not managers.achievment:get_script_data("blow_out_fail") and Global.level_data.level_id == "secret_stash" then
					managers.challenges:set_flag("blow_out")
				end
				if tweak_data:difficulty_to_index(Global.game_settings.difficulty) >= 4 then
					local noob_lubes = 0
					for _, data in ipairs(Global.player_manager.synced_bonuses) do
						if data.upgrade == "welcome_to_the_gang" then
							noob_lubes = noob_lubes + 1
						end
					end
					if 3 <= noob_lubes then
						managers.challenges:set_flag("noob_herder")
					end
				end
				if not managers.achievment:get_script_data("stand_together_fail") and tweak_data:difficulty_to_index(Global.game_settings.difficulty) >= 2 and Global.level_data.level_id == "heat_street" then
					managers.challenges:set_flag("stand_together")
				end
				if managers.player:crew_bonus_in_slot(1) == "more_ammo" and managers.player:equipment_in_slot(1) == "sentry_gun" and managers.player:equipment_in_slot(2) == "toolset" then
					local plr_inv = managers.player:player_unit():inventory()
					if plr_inv:unit_by_selection(1):base():get_name_id() == "glock" and plr_inv:unit_by_selection(2):base():get_name_id() == "ak47" and plr_inv:unit_by_selection(3) and plr_inv:unit_by_selection(3):base():get_name_id() == "m79" then
						managers.challenges:set_flag("det_gadget")
					end
				end
			end
		elseif params.num_winners == 3 and not alive(managers.player:player_unit()) then
			managers.challenges:set_flag("left_for_dead")
		end
	end
	managers.statistics:stop_session({
		success = self._success
	})
	managers.statistics:send_statistics()
	managers.hud:script(self.GUI_SAFERECT):set_statistics(self._success and params.num_winners or 0, self._success)
	managers.music:post_event(self._success and "resultscreen_win" or "resultscreen_lose")
	managers.enemy:add_delayed_clbk("play_finishing_sound", callback(self, self, "play_finishing_sound", self._success), Application:time() + 2)
	if self._success then
		managers.hud:script(self.GUI_SAFERECT).bonus_panel:animate(managers.hud:script(self.GUI_SAFERECT).present_completion_bonus, callback(self, self, "completion_bonus_done"))
	else
		self:completion_bonus_done(0)
	end
	if Network:is_server() then
		managers.network:session():set_state("game_end")
	end
end
function MissionEndState:_set_continue_button_text()
	local text = string.upper(managers.localization:text("failed_disconnected_continue", {
		CONTINUE = managers.localization:btn_macro("continue")
	}))
	managers.hud:script(self.GUI_SAFERECT):set_continue_button_text(text)
end
function MissionEndState:play_finishing_sound(success)
	if self._server_left then
		return
	end
	if managers.groupai:state():bain_state() then
		managers.dialog:queue_dialog(success and "Play_ban_g02x" or "Play_ban_g01x", {})
	else
		managers.dialog:queue_dialog(success and "hos_03" or "hos_04", {})
	end
end
function MissionEndState:completion_bonus_done(total_xp_bonus)
	self._total_xp_bonus = total_xp_bonus
end
function MissionEndState:at_exit(next_state)
	managers.hud:hide(PlayerBase.XP_HUD)
	managers.hud:hide(self.GUI_SAFERECT)
	managers.hud:hide(self.GUI_FULLSCREEN)
	self:_clear_controller()
	if not self._debug_continue and not Application:editor() then
		managers.savefile:save_progress()
		if Network:multiplayer() then
			self:_shut_down_network()
		end
		local player = managers.player:player_unit()
		if player then
			player:camera():remove_sound_listener()
		end
		self:_load_start_menu(next_state)
	else
		self._debug_continue = nil
		managers.groupai:state():set_AI_enabled(true)
		local player = managers.player:player_unit()
		if player then
			player:character_damage():set_invulnerable(false)
		end
	end
end
function MissionEndState:_shut_down_network()
	Network:set_multiplayer(false)
	managers.network:queue_stop_network()
	managers.network.matchmake:destroy_game()
	managers.network.voice_chat:destroy_voice()
end
function MissionEndState:_load_start_menu(next_state)
	if next_state:name() == "disconnected" then
		return
	end
	if managers.dlc:is_trial() then
		Global.open_trial_buy = true
	end
	setup:load_start_menu()
end
function MissionEndState:on_statistics_result(best_kills_peer_id, best_kills_score, best_special_kills_peer_id, best_special_kills_score, best_accuracy_peer_id, best_accuracy_score, most_downs_peer_id, most_downs_score, total_kills, total_specials_kills, total_head_shots, group_accuracy, group_downs)
	print("on_statistics_result begin")
	if managers.network and managers.network:session() and managers.network:session():peer(best_kills_peer_id) then
		local best_kills = managers.network:session():peer(best_kills_peer_id):name()
		local best_special_kills = managers.network:session():peer(best_special_kills_peer_id):name()
		local best_accuracy = managers.network:session():peer(best_accuracy_peer_id):name()
		local most_downs = managers.network:session():peer(most_downs_peer_id):name()
		managers.hud:script(self.GUI_SAFERECT):set_group_statistics(best_kills, best_kills_score, best_special_kills, best_special_kills_score, best_accuracy, best_accuracy_score, most_downs, most_downs_score, total_kills, total_specials_kills, total_head_shots, group_accuracy, group_downs)
	end
	print("on_statistics_result end")
	if Network:is_server() and self._success and not managers.achievment:get_script_data("cant_touch_fail") and tweak_data:difficulty_to_index(Global.game_settings.difficulty) >= 4 and Global.level_data.level_id == "heat_street" and 60 <= group_accuracy then
		managers.challenges:set_flag("cant_touch")
		managers.network:session():send_to_peers("award_achievment", "cant_touch")
	end
end
function MissionEndState:_continue()
	self:continue()
end
function MissionEndState:continue()
	if managers.system_menu:is_active() then
		return
	end
	if not self._completion_bonus_done then
		return
	end
	if self._old_state then
		self:_clear_controller()
		self:gsm():change_state_by_name("empty")
	else
		Application:error("Trying to continue from victory screen, but I have no state to goto")
	end
end
function MissionEndState:_clear_controller()
	if not self._controller then
		return
	end
	self._controller:remove_trigger("continue", self._continue_cb)
	self._controller:set_enabled(false)
	self._controller:destroy()
	self._controller = nil
end
function MissionEndState:debug_continue()
	if not self._success then
		return
	end
	if not self._completion_bonus_done then
		return
	end
	if self._old_state then
		self._debug_continue = true
		self:_clear_controller()
		self:gsm():change_state_by_name(self._old_state:name())
	end
end
function MissionEndState:update(t, dt)
	managers.hud:script(self.GUI_SAFERECT):update(t, dt)
	if self._total_xp_bonus then
		if self._total_xp_bonus > 0 then
			managers.experience:add_points(self._total_xp_bonus, true)
			if SystemInfo:platform() == Idstring("WIN32") and Global.level_data.level_id then
				local stats = {}
				stats[Global.game_settings.difficulty .. "_" .. Global.level_data.level_id .. "_" .. "cash"] = {
					type = "int",
					value = self._total_xp_bonus * 1000
				}
				managers.network.account:publish_statistics(stats)
			end
		end
		self._total_xp_bonus = nil
		self._completion_bonus_done = true
		managers.hud:script(self.GUI_SAFERECT):show_legends()
	end
	if self._controller then
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
	end
end
function MissionEndState:game_ended()
	return true
end
function MissionEndState:on_server_left()
	IngameCleanState.on_server_left(self)
end
function MissionEndState:on_kicked()
	IngameCleanState.on_kicked(self)
end
function MissionEndState:on_disconnected()
	IngameCleanState.on_disconnected(self)
end
