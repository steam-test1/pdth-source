function MenuManager:show_retrieving_servers_dialog()
	local dialog_data = {}
	dialog_data.title = managers.localization:text("dialog_retrieving_servers_title")
	dialog_data.text = managers.localization:text("dialog_wait")
	dialog_data.id = "find_server"
	dialog_data.no_buttons = true
	managers.system_menu:show(dialog_data)
end
function MenuManager:show_get_world_list_dialog(params)
	local dialog_data = {}
	dialog_data.title = managers.localization:text("dialog_logging_in")
	dialog_data.text = managers.localization:text("dialog_wait")
	dialog_data.id = "get_world_list"
	local cancel_button = {}
	cancel_button.text = managers.localization:text("dialog_cancel")
	cancel_button.callback_func = params.cancel_func
	dialog_data.button_list = {cancel_button}
	dialog_data.indicator = true
	managers.system_menu:show(dialog_data)
end
function MenuManager:show_game_permission_changed_dialog()
	local dialog_data = {}
	dialog_data.title = managers.localization:text("dialog_error_title")
	dialog_data.text = managers.localization:text("dialog_game_permission_changed")
	local ok_button = {}
	ok_button.text = managers.localization:text("dialog_ok")
	dialog_data.button_list = {ok_button}
	managers.system_menu:show(dialog_data)
end
function MenuManager:show_too_low_level()
	local dialog_data = {}
	dialog_data.title = managers.localization:text("dialog_error_title")
	dialog_data.text = managers.localization:text("dialog_too_low_level")
	local ok_button = {}
	ok_button.text = managers.localization:text("dialog_ok")
	dialog_data.button_list = {ok_button}
	managers.system_menu:show(dialog_data)
end
function MenuManager:show_too_low_level_ovk145()
	local dialog_data = {}
	dialog_data.title = managers.localization:text("dialog_error_title")
	dialog_data.text = managers.localization:text("dialog_too_low_level_ovk145")
	local ok_button = {}
	ok_button.text = managers.localization:text("dialog_ok")
	dialog_data.button_list = {ok_button}
	managers.system_menu:show(dialog_data)
end
function MenuManager:show_does_not_own_heist()
	local dialog_data = {}
	dialog_data.title = managers.localization:text("dialog_error_title")
	dialog_data.text = managers.localization:text("dialog_does_not_own_heist")
	local ok_button = {}
	ok_button.text = managers.localization:text("dialog_ok")
	dialog_data.button_list = {ok_button}
	managers.system_menu:show(dialog_data)
end
function MenuManager:show_does_not_own_heist_info(heist, player)
	local dialog_data = {}
	dialog_data.title = managers.localization:text("dialog_error_title")
	dialog_data.text = managers.localization:text("dialog_does_not_own_heist_info", {
		HEIST = string.upper(heist),
		PLAYER = string.upper(player)
	})
	local ok_button = {}
	ok_button.text = managers.localization:text("dialog_ok")
	dialog_data.button_list = {ok_button}
	managers.system_menu:show(dialog_data)
end
function MenuManager:show_failed_joining_dialog()
	local dialog_data = {}
	dialog_data.title = managers.localization:text("dialog_error_title")
	dialog_data.text = managers.localization:text("dialog_err_failed_joining_lobby")
	local ok_button = {}
	ok_button.text = managers.localization:text("dialog_ok")
	dialog_data.button_list = {ok_button}
	managers.system_menu:show(dialog_data)
end
function MenuManager:show_cant_join_from_game_dialog()
	local dialog_data = {}
	dialog_data.title = managers.localization:text("dialog_error_title")
	dialog_data.text = managers.localization:text("dialog_err_cant_join_from_game")
	local ok_button = {}
	ok_button.text = managers.localization:text("dialog_ok")
	dialog_data.button_list = {ok_button}
	managers.system_menu:show(dialog_data)
end
function MenuManager:show_game_started_dialog()
	local dialog_data = {}
	dialog_data.title = managers.localization:text("dialog_error_title")
	dialog_data.text = managers.localization:text("dialog_game_started")
	local ok_button = {}
	ok_button.text = managers.localization:text("dialog_ok")
	dialog_data.button_list = {ok_button}
	managers.system_menu:show(dialog_data)
end
function MenuManager:show_joining_lobby_dialog()
	local dialog_data = {}
	dialog_data.title = managers.localization:text("dialog_joining_lobby_title")
	dialog_data.text = managers.localization:text("dialog_wait")
	dialog_data.id = "join_server"
	dialog_data.no_buttons = true
	dialog_data.indicator = true
	managers.system_menu:show(dialog_data)
end
function MenuManager:show_no_connection_to_game_servers_dialog()
	local dialog_data = {}
	dialog_data.title = managers.localization:text("dialog_error_title")
	dialog_data.text = managers.localization:text("dialog_no_connection_to_game_servers")
	local ok_button = {}
	ok_button.text = managers.localization:text("dialog_ok")
	dialog_data.button_list = {ok_button}
	managers.system_menu:show(dialog_data)
end
function MenuManager:show_person_joining(id, nick)
	local dialog_data = {}
	dialog_data.title = managers.localization:text("dialog_dropin_title", {
		USER = string.upper(nick)
	})
	dialog_data.text = managers.localization:text("dialog_wait") .. " 0%"
	dialog_data.id = "user_dropin" .. id
	dialog_data.no_buttons = true
	managers.system_menu:show(dialog_data)
end
function MenuManager:close_person_joining(id)
	managers.system_menu:close("user_dropin" .. id)
end
function MenuManager:update_person_joining(id, progress_percentage)
	local dlg = managers.system_menu:get_dialog("user_dropin" .. id)
	if dlg then
		dlg:set_text(managers.localization:text("dialog_wait") .. " " .. tostring(progress_percentage) .. "%")
	end
end
function MenuManager:show_kick_peer_dialog()
end
function MenuManager:show_peer_kicked_dialog()
	local title = Global.on_remove_dead_peer_message and "dialog_information_title" or "dialog_mp_kicked_out_title"
	local dialog_data = {}
	dialog_data.title = managers.localization:text(title)
	dialog_data.text = managers.localization:text(Global.on_remove_dead_peer_message or "dialog_mp_kicked_out_message")
	local ok_button = {}
	ok_button.text = managers.localization:text("dialog_ok")
	dialog_data.button_list = {ok_button}
	managers.system_menu:show(dialog_data)
	Global.on_remove_dead_peer_message = nil
end
function MenuManager:show_default_option_dialog()
	local dialog_data = {}
	dialog_data.title = managers.localization:text("dialog_default_options_title")
	dialog_data.text = managers.localization:text("dialog_default_options_message")
	local yes_button = {}
	yes_button.text = managers.localization:text("dialog_yes")
	function yes_button.callback_func()
		managers.user:reset_setting_map()
	end
	local no_button = {}
	no_button.text = managers.localization:text("dialog_no")
	no_button.cancel_button = true
	dialog_data.button_list = {yes_button, no_button}
	managers.system_menu:show(dialog_data)
end
function MenuManager:show_err_not_signed_in_dialog()
	local dialog_data = {}
	dialog_data.title = string.upper(managers.localization:text("dialog_error_title"))
	dialog_data.text = managers.localization:text("dialog_err_not_signed_in")
	dialog_data.no_upper = true
	local ok_button = {}
	ok_button.text = managers.localization:text("dialog_ok")
	function ok_button.callback_func()
		self._showing_disconnect_message = nil
	end
	dialog_data.button_list = {ok_button}
	managers.system_menu:show(dialog_data)
end
function MenuManager:show_mp_disconnected_internet_dialog(params)
	local dialog_data = {}
	dialog_data.title = string.upper(managers.localization:text("dialog_warning_title"))
	dialog_data.text = managers.localization:text("dialog_mp_disconnected_internet")
	dialog_data.no_upper = true
	local ok_button = {}
	ok_button.text = managers.localization:text("dialog_ok")
	ok_button.callback_func = params.ok_func
	dialog_data.button_list = {ok_button}
	managers.system_menu:show(dialog_data)
end
function MenuManager:show_err_no_chat_parental_control()
	local dialog_data = {}
	dialog_data.title = string.upper(managers.localization:text("dialog_information_title"))
	dialog_data.text = managers.localization:text("dialog_no_chat_parental_control")
	dialog_data.no_upper = true
	local ok_button = {}
	ok_button.text = managers.localization:text("dialog_ok")
	dialog_data.button_list = {ok_button}
	managers.system_menu:show(dialog_data)
end
function MenuManager:show_err_under_age()
	local dialog_data = {}
	dialog_data.title = string.upper(managers.localization:text("dialog_information_title"))
	dialog_data.text = managers.localization:text("dialog_age_restriction")
	dialog_data.no_upper = true
	local ok_button = {}
	ok_button.text = managers.localization:text("dialog_ok")
	dialog_data.button_list = {ok_button}
	managers.system_menu:show(dialog_data)
end
function MenuManager:show_waiting_for_server_response(params)
	local dialog_data = {}
	dialog_data.title = managers.localization:text("dialog_waiting_for_server_response_title")
	dialog_data.text = managers.localization:text("dialog_wait")
	dialog_data.id = "waiting_for_server_response"
	dialog_data.indicator = true
	local cancel_button = {}
	cancel_button.text = managers.localization:text("dialog_cancel")
	cancel_button.callback_func = params.cancel_func
	dialog_data.button_list = {cancel_button}
	managers.system_menu:show(dialog_data)
end
function MenuManager:show_request_timed_out_dialog()
	local dialog_data = {}
	dialog_data.title = managers.localization:text("dialog_request_timed_out_title")
	dialog_data.text = managers.localization:text("dialog_request_timed_out_message")
	local ok_button = {}
	ok_button.text = managers.localization:text("dialog_ok")
	dialog_data.button_list = {ok_button}
	managers.system_menu:show(dialog_data)
end
function MenuManager:show_restart_game_dialog(params)
	local dialog_data = {}
	dialog_data.title = managers.localization:text("dialog_warning_title")
	dialog_data.text = managers.localization:text("dialog_show_restart_game_message")
	local yes_button = {}
	yes_button.text = managers.localization:text("dialog_yes")
	yes_button.callback_func = params.yes_func
	local no_button = {}
	no_button.text = managers.localization:text("dialog_no")
	no_button.cancel_button = true
	dialog_data.button_list = {yes_button, no_button}
	managers.system_menu:show(dialog_data)
end
function MenuManager:show_no_invites_message()
	local dialog_data = {}
	dialog_data.title = managers.localization:text("dialog_information_title")
	dialog_data.text = managers.localization:text("dialog_mp_no_invites_message")
	local ok_button = {}
	ok_button.text = managers.localization:text("dialog_ok")
	dialog_data.button_list = {ok_button}
	managers.system_menu:show(dialog_data)
end
function MenuManager:show_invite_wrong_version_message()
	local dialog_data = {}
	dialog_data.title = managers.localization:text("dialog_information_title")
	dialog_data.text = managers.localization:text("dialog_mp_invite_wrong_version_message")
	local ok_button = {}
	ok_button.text = managers.localization:text("dialog_ok")
	dialog_data.button_list = {ok_button}
	managers.system_menu:show(dialog_data)
end
function MenuManager:show_invite_join_message(params)
	local dialog_data = {}
	dialog_data.title = managers.localization:text("dialog_information_title")
	dialog_data.text = managers.localization:text("dialog_mp_invite_join_message")
	dialog_data.id = "invite_join_message"
	local ok_button = {}
	ok_button.text = managers.localization:text("dialog_ok")
	ok_button.callback_func = params.ok_func
	dialog_data.button_list = {ok_button}
	managers.system_menu:show(dialog_data)
end
function MenuManager:show_pending_invite_message(params)
	local dialog_data = {}
	dialog_data.title = string.upper(managers.localization:text("dialog_information_title"))
	dialog_data.text = managers.localization:text("dialog_mp_pending_invite_short_message")
	dialog_data.no_upper = true
	local ok_button = {}
	ok_button.text = managers.localization:text("dialog_ok")
	ok_button.callback_func = params.ok_func
	dialog_data.button_list = {ok_button}
	managers.system_menu:show(dialog_data)
end
function MenuManager:show_NPCommerce_open_fail(params)
	local dialog_data = {}
	dialog_data.title = string.upper(managers.localization:text("dialog_error_title"))
	dialog_data.text = managers.localization:text("dialog_npcommerce_fail_open")
	dialog_data.no_upper = true
	local ok_button = {}
	ok_button.text = managers.localization:text("dialog_ok")
	dialog_data.button_list = {ok_button}
	managers.system_menu:show(dialog_data)
end
function MenuManager:show_NPCommerce_checkout_fail(params)
	local dialog_data = {}
	dialog_data.title = managers.localization:text("dialog_error_title")
	dialog_data.text = managers.localization:text("dialog_npcommerce_checkout_fail")
	local ok_button = {}
	ok_button.text = managers.localization:text("dialog_ok")
	dialog_data.button_list = {ok_button}
	managers.system_menu:show(dialog_data)
end
function MenuManager:show_waiting_NPCommerce_open(params)
	local dialog_data = {}
	dialog_data.title = managers.localization:text("dialog_npcommerce_opening")
	dialog_data.text = string.upper(managers.localization:text("dialog_wait"))
	dialog_data.id = "waiting_for_NPCommerce_open"
	dialog_data.no_upper = true
	dialog_data.no_buttons = true
	dialog_data.indicator = true
	managers.system_menu:show(dialog_data)
end
function MenuManager:show_NPCommerce_browse_fail()
	local dialog_data = {}
	dialog_data.title = managers.localization:text("dialog_error_title")
	dialog_data.text = managers.localization:text("dialog_npcommerce_browse_fail")
	dialog_data.no_upper = true
	local ok_button = {}
	ok_button.text = managers.localization:text("dialog_ok")
	dialog_data.button_list = {ok_button}
	managers.system_menu:show(dialog_data)
end
function MenuManager:show_NPCommerce_browse_success()
	local dialog_data = {}
	dialog_data.title = managers.localization:text("dialog_transaction_successful")
	dialog_data.text = managers.localization:text("dialog_npcommerce_need_install")
	local ok_button = {}
	ok_button.text = managers.localization:text("dialog_ok")
	dialog_data.button_list = {ok_button}
	managers.system_menu:show(dialog_data)
end
function MenuManager:show_accept_gfx_settings_dialog(func)
	local count = 10
	local dialog_data = {}
	dialog_data.title = managers.localization:text("dialog_accept_changes_title")
	dialog_data.text = managers.localization:text("dialog_accept_changes", {TIME = count})
	dialog_data.id = "accept_changes"
	local cancel_button = {}
	cancel_button.text = managers.localization:text("dialog_cancel")
	cancel_button.callback_func = func
	cancel_button.cancel_button = true
	local ok_button = {}
	ok_button.text = managers.localization:text("dialog_ok")
	dialog_data.button_list = {ok_button, cancel_button}
	dialog_data.counter = {
		1,
		function()
			count = count - 1
			if count < 0 then
				func()
				managers.system_menu:close(dialog_data.id)
			else
				local dlg = managers.system_menu:get_dialog(dialog_data.id)
				if dlg then
					dlg:set_text(managers.localization:text("dialog_accept_changes", {TIME = count}))
				end
			end
		end
	}
	managers.system_menu:show(dialog_data)
end
function MenuManager:show_key_binding_collision(params)
	local dialog_data = {}
	dialog_data.title = managers.localization:text("dialog_error_title")
	dialog_data.text = managers.localization:text("dialog_key_binding_collision", params)
	local ok_button = {}
	ok_button.text = managers.localization:text("dialog_ok")
	dialog_data.button_list = {ok_button}
	managers.system_menu:show(dialog_data)
end
function MenuManager:show_key_binding_forbidden(params)
	local dialog_data = {}
	dialog_data.title = managers.localization:text("dialog_error_title")
	dialog_data.text = managers.localization:text("dialog_key_binding_forbidden", params)
	local ok_button = {}
	ok_button.text = managers.localization:text("dialog_ok")
	dialog_data.button_list = {ok_button}
	managers.system_menu:show(dialog_data)
end
