core:import("CoreUnit")
require("lib/states/GameState")
IngameWaitingForPlayersState = IngameWaitingForPlayersState or class(GameState)
IngameWaitingForPlayersState.GUI_SAFERECT = Idstring("guis/waiting_saferect")
IngameWaitingForPlayersState.GUI_FULLSCREEN = Idstring("guis/waiting_fullscreen")
IngameWaitingForPlayersState.PLAYER_HUD = Idstring("guis/player_hud")
IngameWaitingForPlayersState.XP_HUD = Idstring("guis/experience_hud")
IngameWaitingForPlayersState.PLAYER_INFO_HUD = Idstring("guis/player_info_hud")
IngameWaitingForPlayersState.PLAYER_INFO_HUD_FULLSCREEN = Idstring("guis/player_info_hud_fullscreen")
IngameWaitingForPlayersState.PLAYER_DOWNED_HUD = Idstring("guis/player_downed_hud")
IngameWaitingForPlayersState.LEVEL_INTRO_GUI = Idstring("guis/level_intro")
function IngameWaitingForPlayersState:init(game_state_machine)
	GameState.init(self, "ingame_waiting_for_players", game_state_machine)
	self._intro_source = SoundDevice:create_source("intro_source")
	self._start_cb = callback(self, self, "_start")
	self._controller = nil
end
function IngameWaitingForPlayersState:setup_controller()
	if not self._controller then
		self._controller = managers.controller:create_controller("waiting_for_players", managers.controller:get_default_wrapper_index(), false)
	end
	self._controller:set_enabled(true)
end
function IngameWaitingForPlayersState:set_controller_enabled(enabled)
	if self._controller then
	end
end
function IngameWaitingForPlayersState:_start()
	if not Network:is_server() then
		return
	end
	local variant = managers.groupai:state():blackscreen_variant() or 0
	self:sync_start(variant)
	managers.network:session():send_to_peers_synched("sync_waiting_for_player_start", variant)
end
function IngameWaitingForPlayersState:sync_start(variant)
	self._kit_menu.renderer:set_all_items_enabled(false)
	managers.music:post_event(tweak_data.levels:get_music_event("intro"))
	self._fade_out_id = managers.overlay_effect:play_effect(tweak_data.overlay_effects.fade_out_permanent)
	local level_data = Global.level_data.level_id and tweak_data.levels[Global.level_data.level_id]
	self._intro_text_id = level_data and level_data.intro_text_id
	self._intro_event = level_data and (variant == 0 and level_data.intro_event or level_data.intro_event[variant])
	self._intro_cues = level_data and (variant == 0 and level_data.intro_cues or level_data.intro_cues[variant])
	if self._intro_event then
		self._delay_audio_t = Application:time() + 1
	else
		self:_start_delay()
	end
end
function IngameWaitingForPlayersState:_start_audio()
	managers.hud:script(self.GUI_SAFERECT):stop_movie()
	managers.hud:show(self.LEVEL_INTRO_GUI)
	local hud = managers.hud:script(self.LEVEL_INTRO_GUI)
	hud:set_mid_text(self._intro_text_id and managers.localization:text(self._intro_text_id) or "")
	hud.mid_text:animate(hud.fade_in)
	self._intro_cue_index = 1
	managers.menu:close_menu("kit_menu")
	if not self._intro_source:post_event(self._intro_event, self._audio_done, self, "marker", "end_of_event") then
		print("failed to start audio")
		if Network:is_server() then
			self:_start_delay()
		end
	end
end
function IngameWaitingForPlayersState:_start_delay()
	if self._delay_start_t then
		return
	end
	self._delay_start_t = Application:time() + 1
end
function IngameWaitingForPlayersState:_audio_done(instance, event_type, self, sound_source, label, identifier, position)
	if event_type == "end_of_event" or event_type == "marker" and sound_source and sound_source == "end" then
		self:_start_delay()
	else
		managers.subtitle:set_visible(true)
		managers.subtitle:set_enabled(true)
		if self._intro_cues then
			local cue = managers.drama:cue(self._intro_cues[self._intro_cue_index])
			managers.subtitle:show_subtitle(cue.string_id, cue.duration)
			self._intro_cue_index = self._intro_cue_index + 1
		end
	end
end
function IngameWaitingForPlayersState:update(t, dt)
	if t > self._camera_data.next_t then
		self:_next_camera()
	end
	managers.hud:script(self.GUI_SAFERECT).date:set_text(Application:date("%Y-%m-%d %H:%M:%S"))
	if self._delay_audio_t and t > self._delay_audio_t then
		self._delay_audio_t = nil
		self:_start_audio()
	end
	if self._delay_start_t and t > self._delay_start_t then
		self._delay_start_t = nil
		local hud = managers.hud:script(self.LEVEL_INTRO_GUI)
		hud.mid_text:animate(hud.fade_out)
		if Network:is_server() then
			self._delay_spawn_t = Application:time() + 1
		end
	end
	if self._delay_spawn_t and t > self._delay_spawn_t then
		self._delay_spawn_t = nil
		if managers.network:game() then
			managers.network:game():spawn_players()
		end
	end
	local in_foucs = managers.menu:active_menu() == self._kit_menu
	if self._controller and in_foucs then
		local btn_stats_screen_press = not self._stats_screen and self._controller:get_input_bool("stats_screen")
		local btn_stats_screen_release = self._stats_screen and self._controller:get_input_released("stats_screen")
		local btn_upgrade_alternative1_press = self._stats_screen and self._controller:get_input_pressed("upgrade_alternative1")
		local btn_upgrade_alternative2_press = self._stats_screen and self._controller:get_input_pressed("upgrade_alternative2")
		local btn_upgrade_alternative3_press = self._stats_screen and self._controller:get_input_pressed("upgrade_alternative3")
		local btn_upgrade_alternative4_press = self._stats_screen and self._controller:get_input_pressed("upgrade_alternative4")
		if btn_stats_screen_press then
			self._stats_screen = true
			self._kit_menu.input._accept_input = false
			managers.hud:show_stats_screen()
			managers.experience:show_stats()
		elseif btn_stats_screen_release then
			self._stats_screen = false
			self._kit_menu.input._accept_input = true
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
	elseif self._stats_screen then
		self._stats_screen = false
		managers.hud:hide_stats_screen()
		managers.experience:hide_stats()
		if self._controller and not in_foucs then
			self._kit_menu.input._accept_input = true
		end
	end
end
function IngameWaitingForPlayersState:at_enter()
	self._started_from_beginning = true
	self:setup_controller()
	managers.subtitle:set_presenter(CoreSubtitlePresenter.OverlayPresenter:new("fonts/font_univers_530_bold", 28))
	managers.hud:load_hud(self.GUI_SAFERECT, false, true, true, {})
	managers.hud:show(self.GUI_SAFERECT)
	managers.hud:script(self.GUI_SAFERECT):set_server(Network:is_server())
	managers.hud:load_hud(self.GUI_FULLSCREEN, false, true, false, {})
	managers.hud:show(self.GUI_FULLSCREEN)
	self._hud = managers.hud:script(self.GUI_SAFERECT)
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
	if not managers.hud:exists(self.LEVEL_INTRO_GUI) then
		managers.hud:load_hud(self.LEVEL_INTRO_GUI, false, false, true, {})
	end
	managers.hud:show(PlayerBase.XP_HUD)
	managers.menu:close_menu()
	managers.menu:open_menu("kit_menu")
	self._kit_menu = managers.menu:get_menu("kit_menu")
	self:_get_cameras()
	self._cam_unit = CoreUnit.safe_spawn_unit("units/gui/background_camera_01/waiting_camera_01", Vector3(), Rotation())
	self._camera_data = {}
	self._camera_data.index = 0
	self:_next_camera()
	if managers.network:session():is_client() and managers.network:session():server_peer() then
		Global.local_member:sync_lobby_data(managers.network:session():server_peer())
		Global.local_member:sync_data(managers.network:session():server_peer())
	end
end
function IngameWaitingForPlayersState:start_game_intro()
	if self._starting_game_intro then
		return
	end
	self._starting_game_intro = true
	self:_start()
end
function IngameWaitingForPlayersState:set_dropin(char_name)
	self._started_from_beginning = false
	print("Joining as " .. char_name)
end
function IngameWaitingForPlayersState:at_exit()
	managers.menu:close_menu("kit_menu")
	managers.statistics:start_session({
		from_beginning = self._started_from_beginning,
		drop_in = not self._started_from_beginning
	})
	managers.hud:hide(PlayerBase.XP_HUD)
	managers.hud:hide(self.GUI_SAFERECT)
	managers.hud:hide(self.GUI_FULLSCREEN)
	managers.hud:script(self.GUI_SAFERECT):stop_movie()
	World:delete_unit(self._cam_unit)
	managers.overlay_effect:play_effect(tweak_data.overlay_effects.level_fade_in)
	managers.overlay_effect:stop_effect(self._fade_out_id)
	managers.hud:hide(self.LEVEL_INTRO_GUI)
	if self._started_from_beginning then
		managers.music:post_event(tweak_data.levels:get_music_event("intro"))
	end
	managers.platform:set_presence("Playing")
	self._delay_audio_t = nil
end
function IngameWaitingForPlayersState:_get_cameras()
	self._cameras = {}
	for _, unit in ipairs(managers.helper_unit:get_units_by_type("waiting_camera")) do
		table.insert(self._cameras, {
			pos = unit:position(),
			rot = unit:rotation(),
			nr = math.random(20)
		})
	end
	if #self._cameras == 0 then
		table.insert(self._cameras, {
			pos = Vector3(-196, -496, 851),
			rot = Rotation(90, 0, 0),
			nr = math.random(20)
		})
		table.insert(self._cameras, {
			pos = Vector3(-1897, -349, 365),
			rot = Rotation(0, 0, 0),
			nr = math.random(20)
		})
		table.insert(self._cameras, {
			pos = Vector3(-2593, 552, 386),
			rot = Rotation(-90, 0, 0),
			nr = math.random(20)
		})
	end
end
function IngameWaitingForPlayersState:_next_camera()
	self._camera_data.next_t = Application:time() + 8 + math.rand(4)
	self._camera_data.index = self._camera_data.index + 1
	if self._camera_data.index > #self._cameras then
		self._camera_data.index = 1
	end
	self._cam_unit:set_position(self._cameras[self._camera_data.index].pos)
	self._cam_unit:set_rotation(self._cameras[self._camera_data.index].rot)
	self._cam_unit:camera():start(math.rand(30))
	local text = self._cameras[self._camera_data.index].nr < 10 and "0" .. self._cameras[self._camera_data.index].nr or self._cameras[self._camera_data.index].nr
	managers.hud:script(self.GUI_SAFERECT).cam_nr:set_text("CAM-" .. text)
end
function IngameWaitingForPlayersState:on_server_left()
	IngameCleanState.on_server_left(self)
end
function IngameWaitingForPlayersState:on_kicked()
	IngameCleanState.on_kicked(self)
end
function IngameWaitingForPlayersState:on_disconnected()
	IngameCleanState.on_disconnected(self)
end
