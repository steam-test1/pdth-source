require("lib/states/GameState")
MenuMainState = MenuMainState or class(GameState)
function MenuMainState:init(game_state_machine)
	GameState.init(self, "menu_main", game_state_machine)
end
function MenuMainState:at_enter(old_state)
	if old_state:name() ~= "freeflight" or not managers.menu:is_active() then
		self._camera_object = World:create_camera()
		self._camera_object:set_near_range(3)
		self._camera_object:set_far_range(1000000)
		self._camera_object:set_fov(75)
		self._vp = managers.viewport:new_vp(0, 0, 1, 1, "menu_main")
		self._vp:set_camera(self._camera_object)
		self._vp:set_environment(managers.environment_area:default_environment())
		self._vp:set_active(true)
		managers.menu:open_menu("menu_main")
		managers.music:post_event("menu_music")
	end
	if SystemInfo:platform() == Idstring("PS3") then
		Global.boot_invite = Global.boot_invite or {}
		if Application:is_booted_from_invitation() and not Global.boot_invite.used then
			Global.boot_invite.used = false
			Global.boot_invite.pending = true
			if 0 < #PSN:get_world_list() and PSN:is_online() then
				print("had world list, can join now")
				managers.network.matchmake:join_boot_invite()
			else
				local ok_func = function()
					managers.menu:open_ps3_sign_in_menu(function(success)
						print("success", success)
					end)
				end
				managers.menu:show_pending_invite_message({ok_func = ok_func})
			end
		end
	elseif SystemInfo:platform() == Idstring("WIN32") and Global.boot_invite then
		local lobby = Global.boot_invite
		Global.boot_invite = nil
		managers.network.matchmake:join_server_with_check(lobby)
	end
	if Global.open_trial_buy then
		Global.open_trial_buy = nil
		managers.menu:open_node("trial_info")
	end
end
function MenuMainState:at_exit(new_state)
	if new_state:name() ~= "freeflight" then
		managers.menu:close_menu("menu_main")
	end
end
function MenuMainState:on_server_left()
	self:_create_server_left_dialog()
end
function MenuMainState:_create_server_left_dialog()
	local dialog_data = {}
	dialog_data.title = managers.localization:text("dialog_warning_title")
	dialog_data.text = Global.on_server_left_message and managers.localization:text(Global.on_server_left_message) or managers.localization:text("dialog_the_host_has_left_the_game")
	Global.on_server_left_message = nil
	local ok_button = {}
	ok_button.text = managers.localization:text("dialog_ok")
	ok_button.callback_func = callback(self, self, "on_server_left_ok_pressed")
	dialog_data.button_list = {ok_button}
	managers.system_menu:show(dialog_data)
end
function MenuMainState:on_server_left_ok_pressed()
	print("[MenuMainState:on_server_left_ok_pressed]")
	managers.network:queue_stop_network()
	managers.menu:close_menu("lobby_menu")
	managers.menu:open_menu("menu_main")
end
function MenuMainState:_create_disconnected_dialog()
	managers.menu:show_mp_disconnected_internet_dialog({
		ok_func = callback(self, self, "on_server_left_ok_pressed")
	})
end
