core:module("SystemMenuManager")
core:import("CoreEvent")
core:import("CoreClass")
require("lib/managers/dialogs/GenericDialog")
require("lib/managers/dialogs/Xbox360Dialog")
require("lib/managers/dialogs/PS3Dialog")
require("lib/managers/dialogs/Xbox360SelectStorageDialog")
require("lib/managers/dialogs/PS3DeleteFileDialog")
require("lib/managers/dialogs/Xbox360KeyboardInputDialog")
require("lib/managers/dialogs/PS3KeyboardInputDialog")
require("lib/managers/dialogs/Xbox360SelectUserDialog")
require("lib/managers/dialogs/Xbox360AchievementsDialog")
require("lib/managers/dialogs/Xbox360FriendsDialog")
require("lib/managers/dialogs/Xbox360PlayerReviewDialog")
require("lib/managers/dialogs/Xbox360PlayerDialog")
require("lib/managers/dialogs/Xbox360MarketplaceDialog")
SystemMenuManager = SystemMenuManager or class()
SystemMenuManager.PLATFORM_CLASS_MAP = {}
function SystemMenuManager:new(...)
	local platform = SystemInfo:platform()
	return (self.PLATFORM_CLASS_MAP[platform:key()] or GenericSystemMenuManager):new(...)
end
GenericSystemMenuManager = GenericSystemMenuManager or class()
GenericSystemMenuManager.DIALOG_CLASS = GenericDialog
GenericSystemMenuManager.GENERIC_DIALOG_CLASS = GenericDialog
function GenericSystemMenuManager:init()
	if not Global.dialog_manager then
		Global.dialog_manager = {init_show_data_list = nil}
	end
	self._dialog_shown_callback_handler = CoreEvent.CallbackEventHandler:new()
	self._dialog_hidden_callback_handler = CoreEvent.CallbackEventHandler:new()
	self._dialog_closed_callback_handler = CoreEvent.CallbackEventHandler:new()
	self._active_changed_callback_handler = CoreEvent.CallbackEventHandler:new()
	local gui = Overlay:gui()
	self._ws = gui:create_screen_workspace()
	self._ws:hide()
	self._controller = managers.controller:create_controller("dialog", nil, false)
	managers.controller:add_default_wrapper_index_change_callback(callback(self, self, "changed_controller_index"))
end
function GenericSystemMenuManager:init_finalize()
	if Global.dialog_manager.init_show_data_list then
		local init_show_data_list = Global.dialog_manager.init_show_data_list
		Global.dialog_manager.init_show_data_list = nil
		for index, data in ipairs(init_show_data_list) do
			cat_print("dialog_manager", "[SystemMenuManager] Processing init dialog. Index: " .. tostring(index) .. "/" .. tostring(#init_show_data_list))
			self:show(data)
		end
	end
end
function GenericSystemMenuManager:add_init_show(data)
	local init_show_data_list = Global.dialog_manager.init_show_data_list
	local priority = data.priority or 0
	cat_print("dialog_manager", "[SystemMenuManager] Adding an init dialog with priority \"" .. tostring(priority) .. "\".")
	if init_show_data_list then
		for index = #init_show_data_list, 1, -1 do
			local next_data = init_show_data_list[index]
			local next_priority = next_data.priority or 0
			if priority < next_priority then
				cat_print("dialog_manager", "[SystemMenuManager] Ignoring request to show init dialog since it had lower priority than the existing priority \"" .. tostring(next_priority) .. "\". Index: " .. tostring(index) .. "/" .. tostring(#init_show_data_list))
				return false
			elseif priority > next_priority then
				cat_print("dialog_manager", "[SystemMenuManager] Removed an already added init dialog with the lower priority of \"" .. tostring(next_priority) .. "\". Index: " .. tostring(index) .. "/" .. tostring(#init_show_data_list))
				table.remove(init_show_data_list, index)
			end
		end
	else
		init_show_data_list = {}
	end
	table.insert(init_show_data_list, data)
	Global.dialog_manager.init_show_data_list = init_show_data_list
end
function GenericSystemMenuManager:destroy()
	if alive(self._ws) then
		Overlay:gui():destroy_workspace(self._ws)
		self._ws = nil
	end
	if self._controller then
		self._controller:destroy()
		self._controller = nil
	end
end
function GenericSystemMenuManager:changed_controller_index(default_wrapper_index)
	local was_enabled = self._controller:enabled()
	self._controller:destroy()
	self._controller = managers.controller:create_controller("dialog", nil, false)
	self._controller:set_enabled(was_enabled)
end
function GenericSystemMenuManager:update(t, dt)
	if self._active_dialog and self._active_dialog.update then
		self._active_dialog:update(t, dt)
	end
	self:update_queue()
	self:check_active_state()
end
function GenericSystemMenuManager:paused_update(t, dt)
	self:update(t, dt)
end
function GenericSystemMenuManager:update_queue()
	if not self:is_active() and self._dialog_queue then
		local dialog, index
		for next_index, next_dialog in ipairs(self._dialog_queue) do
			if not dialog or next_dialog:priority() > dialog:priority() then
				index = next_index
				dialog = next_dialog
			end
		end
		table.remove(self._dialog_queue, index)
		if not next(self._dialog_queue) then
			self._dialog_queue = nil
		end
		if dialog then
			self:_show_instance(dialog, true)
		end
	end
end
function GenericSystemMenuManager:check_active_state()
	local active = self:is_active()
	if not self._old_active_state ~= not active then
		self:event_active_changed(active)
		self._old_active_state = active
	end
end
function GenericSystemMenuManager:block_exec()
	return self:is_active()
end
function GenericSystemMenuManager:is_active()
	return self._active_dialog ~= nil
end
function GenericSystemMenuManager:force_close_all()
	if self._active_dialog then
		self._active_dialog:fade_out_close()
	end
	self._dialog_queue = nil
end
function GenericSystemMenuManager:get_dialog(id)
	if not id then
		return
	end
	if self._active_dialog and self._active_dialog:id() == id then
		return self._active_dialog
	end
end
function GenericSystemMenuManager:close(id)
	if not id then
		return
	end
	print("close active dialog", self._active_dialog and self._active_dialog:id(), id)
	if self._active_dialog and self._active_dialog:id() == id then
		self._active_dialog:fade_out_close()
		return
	end
	if not self._dialog_queue then
		return
	end
	for i, dialog in ipairs(self._dialog_queue) do
		if dialog:id() == id then
			print("remove from queue", id)
			table.remove(self._dialog_queue, i)
		end
	end
end
function GenericSystemMenuManager:is_active_by_id(id)
	if not self._active_dialog or not id then
		return false
	end
	if self._active_dialog:id() == id then
		return true, self._active_dialog
	end
	if not self._dialog_queue then
		return false
	end
	for i, dialog in ipairs(self._dialog_queue) do
		if dialog:id() == id then
			return true, dialog
		end
	end
	return false
end
function GenericSystemMenuManager:show(data)
	local success = self:_show_class(data, self.GENERIC_DIALOG_CLASS, self.DIALOG_CLASS, data.force)
	if not success and data then
		local default_button_index = data.focus_button or 1
		local button_list = data.button_list
		if data.button_list then
			local button_data = data.button_list[default_button_index]
			if button_data then
				local callback_func = button_data.callback_func
				if callback_func then
					callback_func(default_button_index, button_data)
				end
			end
		end
		if data.callback_func then
			data.callback_func(default_button_index, data)
		end
	end
end
function GenericSystemMenuManager:show_select_storage(data)
	self:_show_class(data, self.GENERIC_SELECT_STORAGE_DIALOG_CLASS, self.SELECT_STORAGE_DIALOG_CLASS, false)
end
function GenericSystemMenuManager:show_delete_file(data)
	self:_show_class(data, self.GENERIC_DELETE_FILE_DIALOG_CLASS, self.DELETE_FILE_DIALOG_CLASS, false)
end
function GenericSystemMenuManager:show_keyboard_input(data)
	self:_show_class(data, self.GENERIC_KEYBOARD_INPUT_DIALOG, self.KEYBOARD_INPUT_DIALOG, false)
end
function GenericSystemMenuManager:show_select_user(data)
	self:_show_class(data, self.GENERIC_SELECT_USER_DIALOG, self.SELECT_USER_DIALOG, false)
end
function GenericSystemMenuManager:show_achievements(data)
	self:_show_class(data, self.GENERIC_ACHIEVEMENTS_DIALOG, self.ACHIEVEMENTS_DIALOG, false)
end
function GenericSystemMenuManager:show_friends(data)
	self:_show_class(data, self.GENERIC_FRIENDS_DIALOG, self.FRIENDS_DIALOG, false)
end
function GenericSystemMenuManager:show_player_review(data)
	self:_show_class(data, self.GENERIC_PLAYER_REVIEW_DIALOG, self.PLAYER_REVIEW_DIALOG, false)
end
function GenericSystemMenuManager:show_player(data)
	self:_show_class(data, self.GENERIC_PLAYER_DIALOG, self.PLAYER_DIALOG, false)
end
function GenericSystemMenuManager:show_marketplace(data)
	self:_show_class(data, self.GENERIC_MARKETPLACE_DIALOG, self.MARKETPLACE_DIALOG, false)
end
function GenericSystemMenuManager:_show_class(data, generic_dialog_class, dialog_class, force)
	local dialog_class = data and data.is_generic and generic_dialog_class or dialog_class
	if dialog_class then
		local dialog = dialog_class:new(self, data)
		self:_show_instance(dialog, force)
		return true
	else
		if data then
			local callback_func = data.callback_func
			if callback_func then
				callback_func()
			end
		end
		return false
	end
end
function GenericSystemMenuManager:_show_instance(dialog, force)
	local is_active = self:is_active()
	if is_active and force then
		self:hide_active_dialog()
	end
	local queue = true
	if not is_active then
		queue = not dialog:show()
	end
	if queue then
		self:queue_dialog(dialog, force and 1 or nil)
	end
end
function GenericSystemMenuManager:hide_active_dialog()
	if self._active_dialog and not self._active_dialog:is_closing() and self._active_dialog.hide then
		self:queue_dialog(self._active_dialog, 1)
		self._active_dialog:hide()
	end
end
function GenericSystemMenuManager:queue_dialog(dialog, index)
	if Global.category_print.dialog_manager then
		cat_print("dialog_manager", "[SystemMenuManager] [Queue dialog (index: " .. tostring(index) .. "/" .. tostring(self._dialog_queue and #self._dialog_queue) .. ")] " .. tostring(dialog:to_string()))
	end
	self._dialog_queue = self._dialog_queue or {}
	if index then
		table.insert(self._dialog_queue, index, dialog)
	else
		table.insert(self._dialog_queue, dialog)
	end
end
function GenericSystemMenuManager:set_active_dialog(dialog)
	self._active_dialog = dialog
	local is_ws_visible = dialog and dialog:_get_ws() == self._ws
	if not self._is_ws_visible ~= not is_ws_visible then
		if is_ws_visible then
			self._ws:show()
		else
			self._ws:hide()
		end
		self._is_ws_visible = is_ws_visible
	end
	local is_controller_enabled = dialog and dialog:_get_controller() == self._controller
	if not self._controller:enabled() ~= not is_controller_enabled then
		self._controller:set_enabled(is_controller_enabled)
	end
end
function GenericSystemMenuManager:_is_engine_delaying_signin_change()
	if self._is_engine_delaying_signin_change_delay then
		self._is_engine_delaying_signin_change_delay = self._is_engine_delaying_signin_change_delay - TimerManager:main():delta_time()
		if self._is_engine_delaying_signin_change_delay <= 0 then
			self._is_engine_delaying_signin_change_delay = nil
			return false
		end
	else
		self._is_engine_delaying_signin_change_delay = 1.2
	end
	return true
end
function GenericSystemMenuManager:_get_ws()
	return self._ws
end
function GenericSystemMenuManager:_get_controller()
	return self._controller
end
function GenericSystemMenuManager:add_dialog_shown_callback(func)
	self._dialog_shown_callback_handler:add(func)
end
function GenericSystemMenuManager:remove_dialog_shown_callback(func)
	self._dialog_shown_callback_handler:remove(func)
end
function GenericSystemMenuManager:add_dialog_hidden_callback(func)
	self._dialog_hidden_callback_handler:add(func)
end
function GenericSystemMenuManager:remove_dialog_hidden_callback(func)
	self._dialog_hidden_callback_handler:remove(func)
end
function GenericSystemMenuManager:add_dialog_closed_callback(func)
	self._dialog_closed_callback_handler:add(func)
end
function GenericSystemMenuManager:remove_dialog_closed_callback(func)
	self._dialog_closed_callback_handler:remove(func)
end
function GenericSystemMenuManager:add_active_changed_callback(func)
	self._active_changed_callback_handler:add(func)
end
function GenericSystemMenuManager:remove_active_changed_callback(func)
	self._active_changed_callback_handler:remove(func)
end
function GenericSystemMenuManager:event_dialog_shown(dialog)
	if Global.category_print.dialog_manager then
		cat_print("dialog_manager", "[SystemMenuManager] [Show dialog] " .. tostring(dialog:to_string()))
	end
	dialog:fade_in()
	self:set_active_dialog(dialog)
	self._dialog_shown_callback_handler:dispatch(dialog)
end
function GenericSystemMenuManager:event_dialog_hidden(dialog)
	if Global.category_print.dialog_manager then
		cat_print("dialog_manager", "[SystemMenuManager] [Hide dialog] " .. tostring(dialog:to_string()))
	end
	self:set_active_dialog(nil)
	self._dialog_hidden_callback_handler:dispatch(dialog)
end
function GenericSystemMenuManager:event_dialog_closed(dialog)
	if Global.category_print.dialog_manager then
		cat_print("dialog_manager", "[SystemMenuManager] [Close dialog] " .. tostring(dialog:to_string()))
	end
	self:set_active_dialog(nil)
	self._dialog_closed_callback_handler:dispatch(dialog)
end
function GenericSystemMenuManager:event_active_changed(active)
	if Global.category_print.dialog_manager then
		cat_print("dialog_manager", "[SystemMenuManager] [Active changed] Active: " .. tostring(not not active))
	end
	print("dispacth from system menus", active)
	self._active_changed_callback_handler:dispatch(active)
end
WinSystemMenuManager = WinSystemMenuManager or class(GenericSystemMenuManager)
SystemMenuManager.PLATFORM_CLASS_MAP[Idstring("win32"):key()] = WinSystemMenuManager
Xbox360SystemMenuManager = Xbox360SystemMenuManager or class(GenericSystemMenuManager)
Xbox360SystemMenuManager.DIALOG_CLASS = Xbox360Dialog
Xbox360SystemMenuManager.SELECT_STORAGE_DIALOG_CLASS = Xbox360SelectStorageDialog
Xbox360SystemMenuManager.GENERIC_SELECT_STORAGE_DIALOG_CLASS = Xbox360SelectStorageDialog
Xbox360SystemMenuManager.KEYBOARD_INPUT_DIALOG = Xbox360KeyboardInputDialog
Xbox360SystemMenuManager.GENERIC_KEYBOARD_INPUT_DIALOG = Xbox360KeyboardInputDialog
Xbox360SystemMenuManager.GENERIC_SELECT_USER_DIALOG = Xbox360SelectUserDialog
Xbox360SystemMenuManager.SELECT_USER_DIALOG = Xbox360SelectUserDialog
Xbox360SystemMenuManager.GENERIC_ACHIEVEMENTS_DIALOG = Xbox360AchievementsDialog
Xbox360SystemMenuManager.ACHIEVEMENTS_DIALOG = Xbox360AchievementsDialog
Xbox360SystemMenuManager.GENERIC_FRIENDS_DIALOG = Xbox360FriendsDialog
Xbox360SystemMenuManager.FRIENDS_DIALOG = Xbox360FriendsDialog
Xbox360SystemMenuManager.GENERIC_PLAYER_REVIEW_DIALOG = Xbox360PlayerReviewDialog
Xbox360SystemMenuManager.PLAYER_REVIEW_DIALOG = Xbox360PlayerReviewDialog
Xbox360SystemMenuManager.GENERIC_PLAYER_DIALOG = Xbox360PlayerDialog
Xbox360SystemMenuManager.PLAYER_DIALOG = Xbox360PlayerDialog
Xbox360SystemMenuManager.GENERIC_MARKETPLACE_DIALOG = Xbox360MarketplaceDialog
Xbox360SystemMenuManager.MARKETPLACE_DIALOG = Xbox360MarketplaceDialog
SystemMenuManager.PLATFORM_CLASS_MAP[Idstring("X360"):key()] = Xbox360SystemMenuManager
function Xbox360SystemMenuManager:is_active()
	return GenericSystemMenuManager.is_active(self) or Application:is_showing_system_dialog()
end
PS3SystemMenuManager = PS3SystemMenuManager or class(GenericSystemMenuManager)
PS3SystemMenuManager.DELETE_FILE_DIALOG_CLASS = PS3DeleteFileDialog
PS3SystemMenuManager.GENERIC_DELETE_FILE_DIALOG_CLASS = PS3DeleteFileDialog
PS3SystemMenuManager.KEYBOARD_INPUT_DIALOG = PS3KeyboardInputDialog
PS3SystemMenuManager.GENERIC_KEYBOARD_INPUT_DIALOG = PS3KeyboardInputDialog
SystemMenuManager.PLATFORM_CLASS_MAP[Idstring("PS3"):key()] = PS3SystemMenuManager
function PS3SystemMenuManager:init()
	GenericSystemMenuManager.init(self)
	self._is_ps_button_menu_visible = false
	PS3:set_ps_button_callback(callback(self, self, "ps_button_menu_callback"))
end
function PS3SystemMenuManager:ps_button_menu_callback(is_ps_button_menu_visible)
	self._is_ps_button_menu_visible = is_ps_button_menu_visible
end
function PS3SystemMenuManager:block_exec()
	return GenericSystemMenuManager.is_active(self) or PS3:is_displaying_box()
end
function PS3SystemMenuManager:is_active()
	return GenericSystemMenuManager.is_active(self) or PS3:is_displaying_box() or self._is_ps_button_menu_visible
end
