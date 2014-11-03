core:import("CoreEvent")
SavefileManager = SavefileManager or class()
SavefileManager.SETTING_SLOT = 0
SavefileManager.AUTO_SAVE_SLOT = 1
SavefileManager.PROGRESS_SLOT = 99
SavefileManager.MAX_SLOT = 99
SavefileManager.MAX_PROFILE_SAVE_INTERVAL = 300
SavefileManager.IDLE_TASK_TYPE = 1
SavefileManager.LOAD_TASK_TYPE = 2
SavefileManager.SAVE_TASK_TYPE = 3
SavefileManager.REMOVE_TASK_TYPE = 4
SavefileManager.DEBUG_TASK_TYPE_NAME_LIST = {
	"Idle",
	"Loading",
	"Saving",
	"Removing"
}
SavefileManager.RESERVED_BYTES = 204800
SavefileManager.VERSION = 4
if SystemInfo:platform() == Idstring("PS3") then
	SavefileManager.VERSION_NAME = "1.03"
	SavefileManager.LOWEST_COMPATIBLE_VERSION = "1.02"
else
	SavefileManager.VERSION_NAME = "1.8"
	SavefileManager.LOWEST_COMPATIBLE_VERSION = "1.7"
end
SavefileManager.SAVE_SYSTEM = "steam_cloud"
function SavefileManager:init()
	self._active_changed_callback_handler = CoreEvent.CallbackEventHandler:new()
	self._save_begin_callback_handler = CoreEvent.CallbackEventHandler:new()
	self._save_done_callback_handler = CoreEvent.CallbackEventHandler:new()
	self._load_begin_callback_handler = CoreEvent.CallbackEventHandler:new()
	self._load_done_callback_handler = CoreEvent.CallbackEventHandler:new()
	self._current_task_type = self.IDLE_TASK_TYPE
	if not Global.savefile_manager then
		Global.savefile_manager = {
			current_game_cache_slot = nil,
			meta_data_list = {},
			setting_changed = nil,
			safe_profile_save_time = nil
		}
	end
	self._workspace = Overlay:gui():create_screen_workspace()
	self._gui = self._workspace:panel():gui(Idstring("guis/savefile_manager"))
	self._gui_script = self._gui:script()
	self._workspace:hide()
	local safe_rect = managers.viewport:get_safe_rect_pixels()
	self._gui:set_shape(safe_rect.x, safe_rect.y, safe_rect.width, safe_rect.height)
	self._savegame_hdd_space_required = false
end
function SavefileManager:destroy()
	if self._workspace then
		Overlay:gui():destroy_workspace(self._workspace)
		self._workspace = nil
		self._gui = nil
		self._gui_script = nil
	end
end
function SavefileManager:active_user_changed()
	if managers.user.STORE_SETTINGS_ON_PROFILE then
		self:_clean_meta_data_list(true)
		local is_signed_in = managers.user:is_signed_in(nil)
		if is_signed_in then
			self:load_setting()
		end
	end
end
function SavefileManager:storage_changed()
	local storage_device_selected = managers.user:is_storage_selected(nil)
	if not managers.user.STORE_SETTINGS_ON_PROFILE then
		self:_clean_meta_data_list(true)
	end
	self:_clean_meta_data_list(false)
	if storage_device_selected then
		cat_print("savefile_manager", "[SavefileManager] Loading meta data list.")
		local param_map = {
			user_index = managers.user:get_platform_id()
		}
		if self._backup_data == nil and SystemInfo:platform() == Idstring("WIN32") then
			self:load_progress("local_hdd")
		end
		if SystemInfo:platform() == Idstring("WIN32") then
			param_map.save_system = self.SAVE_SYSTEM
		end
		local task = NewSave:all_slots(param_map)
		local task_handler = SavefileTaskHandler:new(task, self.LOAD_TASK_TYPE, callback(self, self, "_meta_data_slot_detected_callback"), callback(self, self, "_meta_data_slot_detected_done_callback"))
		self:_add_task_handler(task_handler)
	else
		cat_print("savefile_manager", "[SavefileManager] Unable to load meta data. Signed in: " .. tostring(managers.user:is_signed_in(nil)) .. ", Storage device selected: " .. tostring(storage_device_selected))
	end
end
function SavefileManager:setting_changed()
	self:_set_setting_changed(true)
end
function SavefileManager:save_game(slot, cache_only)
	self:_save(slot, cache_only)
end
function SavefileManager:save_setting(is_user_initiated_action)
	if self:_is_saving_setting_allowed(is_user_initiated_action) then
		self:_save(self.SETTING_SLOT, false)
	end
end
function SavefileManager:save_progress(save_system)
	self:_save(self.PROGRESS_SLOT, nil, save_system)
end
function SavefileManager:load_progress(save_system)
	self:_load(self.PROGRESS_SLOT, nil, save_system)
end
function SavefileManager:load_game(slot, cache_only)
	self:_load(slot, cache_only)
end
function SavefileManager:load_setting()
	self:_load(self.SETTING_SLOT)
end
function SavefileManager:current_game_cache_slot()
	return Global.savefile_manager.current_game_cache_slot
end
function SavefileManager:update(t, dt)
	self:update_task_handler_list()
	self:update_gui_visibility()
end
function SavefileManager:paused_update(t, dt)
	self:update_task_handler_list()
	self:update_gui_visibility()
end
function SavefileManager:update_task_handler_list()
	if self._task_handler_list then
		local next_task_handler
		repeat
			next_task_handler = self._task_handler_list[1]
			if not next_task_handler then
				self._task_handler_list = nil
			elseif next_task_handler:update() then
				next_task_handler:destroy()
				table.remove(self._task_handler_list, 1)
			else
				next_task_handler = nil
			end
		until not next_task_handler
		self:update_current_task_type()
	end
end
function SavefileManager:update_current_task_type()
	local current_task_handler = self._task_handler_list and self._task_handler_list[1]
	self:_set_current_task_type(current_task_handler and current_task_handler:task_type() or self.IDLE_TASK_TYPE)
end
function SavefileManager:update_gui_visibility()
	if self._hide_gui_time and TimerManager:main():time() >= self._hide_gui_time then
		self._workspace:hide()
		self._gui_script:set_text("")
		self._hide_gui_time = nil
	end
end
function SavefileManager:debug_get_task_name(task_type)
	return self.DEBUG_TASK_TYPE_NAME_LIST[task_type] or "Invalid"
end
function SavefileManager:is_active()
	return not not self._task_handler_list
end
function SavefileManager:get_save_info_list(include_empty_slot)
	local data_list = {}
	local save_info_list = {}
	for slot, meta_data in pairs(Global.savefile_manager.meta_data_list) do
		if meta_data.is_synched_text and (not include_empty_slot or slot ~= self.AUTO_SAVE_SLOT) and slot ~= self.SETTING_SLOT and slot ~= self.PROGRESS_SLOT then
			table.insert(data_list, {
				slot = slot,
				text = meta_data.text,
				sort_list = meta_data.sort_list
			})
		end
	end
	local function sort_func(data1, data2)
		return self:_compare_sort_list(data1.sort_list, data2.sort_list) < 0
	end
	table.sort(data_list, sort_func)
	for _, data in ipairs(data_list) do
		table.insert(save_info_list, SavefileInfo:new(data.slot, data.text))
	end
	if include_empty_slot then
		for empty_slot = 0, self.MAX_SLOT do
			local meta_data = Global.savefile_manager.meta_data_list[empty_slot]
			if empty_slot ~= self.SETTING_SLOT and empty_slot ~= self.PROGRESS_SLOT and empty_slot ~= self.AUTO_SAVE_SLOT and (not meta_data or not meta_data.is_synched_text) then
				local save_info = SavefileInfo:new(empty_slot, managers.localization:text("savefile_empty"))
				table.insert(save_info_list, 1, save_info)
				break
			end
		end
	end
	return save_info_list
end
function SavefileManager:add_active_changed_callback(callback_func)
	self._active_changed_callback_handler:add(callback_func)
end
function SavefileManager:remove_active_changed_callback(callback_func)
	self._active_changed_callback_handler:remove(callback_func)
end
function SavefileManager:add_save_begin_callback(callback_func)
	self._save_begin_callback_handler:add(callback_func)
end
function SavefileManager:remove_save_begin_callback(callback_func)
	self._save_begin_callback_handler:remove(callback_func)
end
function SavefileManager:add_save_done_callback(callback_func)
	self._save_done_callback_handler:add(callback_func)
end
function SavefileManager:remove_save_done_callback(callback_func)
	self._save_done_callback_handler:remove(callback_func)
end
function SavefileManager:add_load_begin_callback(callback_func)
	self._load_begin_callback_handler:add(callback_func)
end
function SavefileManager:remove_load_begin_callback(callback_func)
	self._load_begin_callback_handler:remove(callback_func)
end
function SavefileManager:add_load_done_callback(callback_func)
	self._load_done_callback_handler:add(callback_func)
end
function SavefileManager:remove_load_done_callback(callback_func)
	self._load_done_callback_handler:remove(callback_func)
end
function SavefileManager:_clean_meta_data_list(is_setting_slot)
	if is_setting_slot then
		Global.savefile_manager.meta_data_list[self.SETTING_SLOT] = nil
	else
		local empty_list
		for slot in pairs(Global.savefile_manager.meta_data_list) do
			if slot ~= self.SETTING_SLOT then
				empty_list = true
			else
			end
		end
		if empty_list then
			local setting_meta_data = Global.savefile_manager.meta_data_list[self.SETTING_SLOT]
			Global.savefile_manager.meta_data_list = {}
			Global.savefile_manager.meta_data_list[self.SETTING_SLOT] = setting_meta_data
		end
	end
end
function SavefileManager:_meta_data_slot_detected_done_callback()
	print("SavefileManager:_meta_data_slot_detected_done_callbac", self._has_meta_list)
	if not self._has_meta_list then
		print(" HAD NO SAVE GAMES")
		if SystemInfo:platform() == Idstring("PS3") then
			self._savegame_hdd_space_required = 2 * self.RESERVED_BYTES / 1024
		end
	else
		print(" #self._has_meta_list", #self._has_meta_list)
		if SystemInfo:platform() == Idstring("PS3") then
			self._savegame_hdd_space_required = (2 - #self._has_meta_list) * self.RESERVED_BYTES / 1024
		end
	end
	if (not self._has_meta_list or not table.contains(self._has_meta_list, self.PROGRESS_SLOT)) and self._backup_data then
		self:_ask_load_backup("no_progress", true)
	end
end
function SavefileManager:_meta_data_slot_detected_callback(slot)
	self._has_meta_list = self._has_meta_list or {}
	table.insert(self._has_meta_list, slot)
	print("SavefileManager:_meta_data_slot_detected_callback", slot)
	cat_print("savefile_manager", "[SavefileManager] Meta data slot detected. Slot: " .. tostring(slot))
	if slot == self.SETTING_SLOT then
		if managers.user.STORE_SETTINGS_ON_PROFILE then
			Application:error("[SavefileManager] Found setting save slot on storage device. Settings are stored in the profile and not in a file.")
		else
			self:load_setting()
		end
	elseif slot == self.PROGRESS_SLOT then
		if managers.user.STORE_SETTINGS_ON_PROFILE then
			Application:error("[SavefileManager] Found setting save slot on storage device. Settings are stored in the profile and not in a file.")
		else
			self:load_progress()
		end
	else
		local param_map = {
			save_slots = slot,
			preview = true,
			user_index = managers.user:get_platform_id()
		}
		if SystemInfo:platform() == Idstring("PS3") then
			param_map.disable_ownership_check = is_setting_slot
		end
		if SystemInfo:platform() == Idstring("WIN32") then
			param_map.save_system = self.SAVE_SYSTEM
		end
		local task = NewSave:load(param_map)
		local task_handler = SavefileTaskHandler:new(task, self.LOAD_TASK_TYPE, callback(self, self, "_meta_data_loaded_callback"))
		self:_add_task_handler(task_handler)
	end
end
function SavefileManager:_meta_data_loaded_callback(save_data)
	local slot = save_data:slot()
	local status = save_data:status()
	local success = status == SaveData.OK
	cat_print("savefile_manager", "[SavefileManager] Meta data loaded. Slot: " .. tostring(slot) .. ", Text: \"" .. tostring(save_data:subtitle()) .. "\", Status: " .. tostring(SaveData.status_to_string(status)) .. " (" .. tostring(status) .. ")")
	if not success then
		self:_set_cache(slot, nil)
	end
	self:_set_text(slot, save_data, success)
end
function SavefileManager:_parse_text(save_data)
	if not save_data then
		return ""
	else
		local text = save_data:subtitle()
		local status = save_data:status()
		if status ~= SaveData.OK then
			text = managers.localization:text("debug_corrupt_save")
			if Application:production_build() then
				text = text .. " (Reason: " .. tostring(SaveData.status_to_string(status)) .. ", Error code: " .. tostring(status) .. ")"
			end
		end
		text = managers.localization:text("savefile", {
			TEXT = text,
			DATE = save_data:date("%c")
		})
		if save_data:slot() == self.AUTO_SAVE_SLOT then
			text = managers.localization:text("savefile_autosave", {TEXT_WITH_DATE = text})
		end
		return text
	end
end
function SavefileManager:_parse_sort_list(save_data)
	local date_instance = save_data or Application
	local format_order = {
		"%Y",
		"%j",
		"%H",
		"%M",
		"%S"
	}
	local sort_list = {}
	for index, format in ipairs(format_order) do
		sort_list[index] = tonumber(date_instance:date(format))
	end
	return sort_list
end
function SavefileManager:_save(slot, cache_only, save_system)
	cat_print("savefile_manager", "[SavefileManager] Saving to slot \"" .. tostring(slot) .. "\". Cache only: " .. tostring(cache_only))
	local is_setting_slot = slot == self.SETTING_SLOT
	local is_progress_slot = slot == self.PROGRESS_SLOT
	self._save_begin_callback_handler:dispatch(slot, is_setting_slot, cache_only)
	self:_save_cache(slot)
	if cache_only then
		self:_save_done(slot, cache_only, nil, true)
	else
		if is_setting_slot then
			self:_set_setting_changed(false)
		end
		if is_setting_slot and managers.user.STORE_SETTINGS_ON_PROFILE then
			Global.savefile_manager.safe_profile_save_time = TimerManager:main():time() + self.MAX_PROFILE_SAVE_INTERVAL
			local task_handler = SavefileTaskHandler:new(SavePlatformSettingMapTask:new(), self.SAVE_TASK_TYPE, callback(self, self, "_save_platform_setting_map_callback"))
			self:_add_task_handler(task_handler)
		else
			local meta_data = self:_meta_data(slot)
			local param_map = {
				save_slots = slot,
				user_index = managers.user:get_platform_id()
			}
			local save_data = NewSave:create_save_data()
			local subtitle, description, title
			if is_setting_slot then
				title = managers.localization:text("savefile_game_title")
				subtitle = managers.localization:text("savefile_setting", {
					VERSION = self.LOWEST_COMPATIBLE_VERSION
				})
				description = managers.localization:text("savefile_setting_description")
			else
				title = managers.localization:text("savefile_game_title")
				subtitle = managers.localization:text("savefile_progress", {
					VERSION = self.LOWEST_COMPATIBLE_VERSION
				})
				description = managers.localization:text("savefile_progress_description")
			end
			if SystemInfo:platform() == Idstring("PS3") then
				if is_setting_slot then
					param_map.disable_ownership_check = true
				end
				save_data:set_title(title)
				save_data:set_small_icon_by_path("ICON0.PNG")
				param_map.use_small_icon = true
			end
			save_data:set_subtitle(subtitle)
			save_data:set_details(description)
			save_data:set_information(meta_data.cache)
			if SystemInfo:platform() == Idstring("WIN32") then
				param_map.save_system = save_system or "steam_cloud"
			end
			local task = NewSave:save(save_data, param_map)
			local task_handler = SavefileTaskHandler:new(task, self.SAVE_TASK_TYPE, callback(self, self, "_save_callback"))
			self:_add_task_handler(task_handler)
		end
	end
end
function SavefileManager:_save_platform_setting_map_callback(success)
	self:_save_done(self.SETTING_SLOT, false, nil, success)
end
function SavefileManager:_save_callback(save_data)
	local status = save_data:status()
	local slot = save_data:slot()
	cat_print("savefile_manager", "[SavefileManager] Save to slot \"" .. tostring(slot) .. "\" done with status \"" .. tostring(SaveData.status_to_string(status)) .. "\" (" .. tostring(status) .. ").")
	local disk_full = status == SaveData.DISK_FULL
	local success = status == SaveData.OK
	self:_save_done(slot, false, save_data, success)
end
function SavefileManager:_save_cache(slot)
	cat_print("savefile_manager", "[SavefileManager] Saves slot \"" .. tostring(slot) .. "\" to cache.")
	local is_setting_slot = slot == self.SETTING_SLOT
	if is_setting_slot then
		self:_set_cache(slot, nil)
	else
		local old_slot = Global.savefile_manager.current_game_cache_slot
		if old_slot then
			self:_set_cache(old_slot, nil)
		end
		self:_set_current_game_cache_slot(slot)
	end
	local cache = {
		version = SavefileManager.VERSION,
		version_name = SavefileManager.VERSION_NAME
	}
	if is_setting_slot then
		managers.user:save(cache)
	else
		managers.timeline:save(cache)
		managers.player:save(cache)
		managers.experience:save(cache)
		managers.upgrades:save(cache)
		managers.money:save(cache)
		managers.statistics:save(cache)
		managers.challenges:save(cache)
	end
	self:_set_cache(slot, cache)
	self:_set_synched_cache(slot, false)
end
function SavefileManager:_save_done(slot, cache_only, save_data, success)
	cat_print("savefile_manager", "[SavefileManager] Done saving to slot \"" .. tostring(slot) .. "\". Cache only: " .. tostring(cache_only) .. ", Success: " .. tostring(success))
	if not success then
		self:_set_cache(slot, nil)
	end
	self:_set_text(slot, save_data, not cache_only and success)
	if not cache_only then
		self:_set_corrupt(slot, not success)
	end
	self:_set_synched_cache(slot, success and not cache_only)
	local is_setting_slot = slot == self.SETTING_SLOT
	if is_setting_slot and not success then
		self:_set_setting_changed(true)
	end
	self._save_done_callback_handler:dispatch(slot, success, is_setting_slot, cache_only)
end
function SavefileManager:_load(slot, cache_only, save_system)
	cat_print("savefile_manager", "[SavefileManager] Loading slot \"" .. tostring(slot) .. "\". Cache only: " .. tostring(cache_only))
	local is_setting_slot = slot == self.SETTING_SLOT
	if not is_setting_slot then
		self:_set_current_game_cache_slot(slot)
	end
	self._load_begin_callback_handler:dispatch(slot, is_setting_slot, cache_only)
	local meta_data = self:_meta_data(slot)
	if cache_only or meta_data.is_synched_cache and meta_data.cache then
		self:_load_done(slot, cache_only)
	else
		if is_setting_slot then
			self:_set_cache(slot, nil)
		else
			self:_set_cache(Global.savefile_manager.current_game_cache_slot, nil)
		end
		if is_setting_slot and managers.user.STORE_SETTINGS_ON_PROFILE then
			local task_handler = SavefileTaskHandler:new(LoadPlatformSettingMapTask:new(), self.LOAD_TASK_TYPE, callback(self, self, "_load_platform_setting_map_callback"))
			self:_add_task_handler(task_handler)
		else
			print("SET UP LOAD", slot)
			local param_map = {
				save_slots = slot,
				user_index = managers.user:get_platform_id()
			}
			if SystemInfo:platform() == Idstring("PS3") then
				param_map.disable_ownership_check = is_setting_slot
			end
			if SystemInfo:platform() == Idstring("WIN32") then
				param_map.save_system = save_system or "steam_cloud"
			end
			local load_callback_obj
			if param_map.save_system == "local_hdd" then
				load_callback_obj = callback(self, self, "_load_backup_callback")
			else
				load_callback_obj = callback(self, self, "_load_callback")
			end
			local task = NewSave:load(param_map)
			local task_handler = SavefileTaskHandler:new(task, self.LOAD_TASK_TYPE, load_callback_obj, callback(self, self, "_load_callback_done"))
			self:_add_task_handler(task_handler)
		end
	end
end
function SavefileManager:_load_callback_done()
end
function SavefileManager:_load_backup_callback(save_data)
	local status = save_data:status()
	print("[SavefileManager:_load_backup_callback] status", status)
	if status == SaveData.OK then
		local save_data_info = save_data:information()
		local version = save_data_info.version or 0
		local version_name = save_data_info.version_name
		if version <= SavefileManager.VERSION then
			print("[SavefileManager:_load_backup_callback] backup loaded")
			self._backup_data = {save_data = save_data}
		else
			Application:error("local savegame backup is wrong version")
			self._backup_data = false
		end
	else
		self._backup_data = false
	end
end
function SavefileManager:_load_callback(save_data)
	print("[SavefileManager:_load_callback] slot", save_data:slot(), "status", save_data:status())
	local slot = save_data:slot()
	local status = save_data:status()
	local size = save_data:size()
	local cache
	cat_print("savefile_manager", "[SavefileManager] Load of slot \"" .. tostring(slot) .. "\" done with status \"" .. tostring(SaveData.status_to_string(status)) .. "\" (" .. tostring(status) .. ").")
	local wrong_user = status == SaveData.WRONG_USER
	if status == SaveData.OK or wrong_user then
		cache = save_data:information()
	end
	self._save_sizes = self._save_sizes or {}
	table.insert(self._save_sizes, size)
	self:_set_cache(slot, cache)
	self:_load_done(slot, false, wrong_user)
end
function SavefileManager:_load_platform_setting_map_callback(platform_setting_map)
	local cache
	if platform_setting_map then
		cache = managers.user:get_setting_map()
	end
	self:_set_cache(self.SETTING_SLOT, cache)
	self:_load_done(self.SETTING_SLOT, false)
end
function SavefileManager:_load_done(slot, cache_only, wrong_user)
	local is_setting_slot = slot == self.SETTING_SLOT
	local is_progress_slot = slot == self.PROGRESS_SLOT
	local meta_data = self:_meta_data(slot)
	local success = meta_data.cache ~= nil
	cat_print("savefile_manager", "[SavefileManager] Done loading slot \"" .. tostring(slot) .. "\". Success: \"" .. tostring(success) .. "\".")
	if not cache_only then
		self:_set_corrupt(slot, not success)
		self:_set_synched_cache(slot, success)
	end
	if self._backup_data and is_progress_slot then
		local meta_data = self:_meta_data(slot)
		local cache = meta_data.cache
		if cache and managers.experience:chk_ask_use_backup(cache, self._backup_data.save_data:information()) then
			self:_ask_load_backup("low_progress", true, {cache_only, wrong_user})
			return
		end
	end
	local req_version = self:_load_cache(slot)
	if req_version ~= nil or not success then
		success = false
	end
	self._load_done_callback_handler:dispatch(slot, success, is_setting_slot, cache_only)
	if not success then
		self._try_again = self._try_again or {}
		local dialog_data = {}
		dialog_data.title = managers.localization:text("dialog_error_title")
		local ok_button = {}
		ok_button.text = managers.localization:text("dialog_ok")
		dialog_data.button_list = {ok_button}
		if is_setting_slot or is_progress_slot then
			do
				local at_init = true
				local error_msg = is_setting_slot and "dialog_fail_load_setting_" or is_progress_slot and "dialog_fail_load_progress_"
				error_msg = error_msg .. (req_version == nil and "corrupt" or "wrong_version")
				print("ERROR: ", error_msg)
				if not self._try_again[slot] then
					local yes_button = {}
					yes_button.text = managers.localization:text("dialog_yes")
					local no_button = {}
					no_button.text = managers.localization:text("dialog_no")
					dialog_data.button_list = {yes_button, no_button}
					dialog_data.text = managers.localization:text(error_msg .. "_retry", {VERSION = req_version})
					if is_setting_slot then
						function yes_button.callback_func()
							self:load_setting()
						end
					elseif is_progress_slot then
						function yes_button.callback_func()
							self:load_progress()
						end
					end
					function no_button.callback_func()
						if is_progress_slot and self._backup_data then
							self:_ask_load_backup("progress_" .. (req_version == nil and "corrupt" or "wrong_version"), false)
							return
						else
							local rem_dialog_data = {}
							rem_dialog_data.title = managers.localization:text("dialog_error_title")
							rem_dialog_data.text = managers.localization:text(error_msg, {VERSION = req_version})
							local ok_button = {}
							ok_button.text = managers.localization:text("dialog_ok")
							function ok_button.callback_func()
								self:_remove(slot)
							end
							rem_dialog_data.button_list = {ok_button}
							managers.system_menu:show(rem_dialog_data)
						end
					end
					self._try_again[slot] = true
				else
					at_init = false
					if is_progress_slot and self._backup_data then
						self:_ask_load_backup("progress_" .. (req_version == nil and "corrupt" or "wrong_version"), false)
						return
					else
						dialog_data.text = managers.localization:text(error_msg, {VERSION = req_version})
						function ok_button.callback_func()
							self:_remove(slot)
						end
					end
				end
				if at_init then
					managers.system_menu:add_init_show(dialog_data)
				else
					managers.system_menu:show(dialog_data)
				end
			end
		else
			dialog_data.text = managers.localization:text("dialog_fail_load_game_corrupt")
			managers.system_menu:add_init_show(dialog_data)
		end
	elseif wrong_user and not self._queued_wrong_user then
		self._queued_wrong_user = true
		local dialog_data = {}
		dialog_data.title = managers.localization:text("dialog_information_title")
		dialog_data.text = managers.localization:text("dialog_load_wrong_user")
		dialog_data.id = "wrong_user"
		local ok_button = {}
		ok_button.text = managers.localization:text("dialog_ok")
		dialog_data.button_list = {ok_button}
		managers.system_menu:add_init_show(dialog_data)
	end
end
function SavefileManager:_remove(slot, save_system)
	local param_map = {
		save_slots = slot,
		user_index = managers.user:get_platform_id()
	}
	if SystemInfo:platform() == Idstring("WIN32") then
		param_map.save_system = save_system or "steam_cloud"
	end
	local task = NewSave:remove(param_map)
	local task_handler = SavefileTaskHandler:new(task, self.REMOVE_TASK_TYPE, callback(self, self, "_remove_callback"))
	self:_add_task_handler(task_handler)
end
function SavefileManager:_remove_callback(...)
end
function SavefileManager:_load_cache(slot)
	cat_print("savefile_manager", "[SavefileManager] Loads cached slot \"" .. tostring(slot) .. "\".")
	local meta_data = self:_meta_data(slot)
	local cache = meta_data.cache
	local is_setting_slot = slot == self.SETTING_SLOT
	if not is_setting_slot then
		self:_set_current_game_cache_slot(slot)
	end
	if cache then
		local version = cache.version or 0
		local version_name = cache.version_name
		if version > SavefileManager.VERSION then
			return version_name
		end
		if is_setting_slot then
			managers.user:load(cache, version)
			self:_set_setting_changed(false)
		else
			managers.timeline:load(cache, version)
			managers.upgrades:load(cache, version)
			managers.experience:load(cache, version)
			managers.player:load(cache, version)
			managers.money:load(cache, version)
			managers.challenges:load(cache, version)
			managers.statistics:load(cache, version)
		end
	else
		Application:error("[SavefileManager] Unable to load savefile from slot \"" .. tostring(slot) .. "\".")
	end
end
function SavefileManager:_meta_data(slot)
	local meta_data = Global.savefile_manager.meta_data_list[slot]
	if not meta_data then
		meta_data = {
			slot = slot,
			is_corrupt = false,
			is_synched_text = false,
			text = nil,
			is_synched_cache = false,
			cache = nil,
			timeline_event_id = nil,
			timeline_checkpoint_index = nil
		}
		Global.savefile_manager.meta_data_list[slot] = meta_data
		cat_print("savefile_manager", "[SavefileManager] Created meta data for slot \"" .. tostring(slot) .. "\".")
	end
	return meta_data
end
function SavefileManager:_add_task_handler(task_handler)
	self._task_handler_list = self._task_handler_list or {}
	table.insert(self._task_handler_list, task_handler)
	self:update_current_task_type()
end
function SavefileManager:_set_current_task_type(task_type)
	local old_task_type = self._current_task_type
	if old_task_type ~= task_type then
		if Global.category_print.savefile_manager then
			cat_print("savefile_manager", "[SavefileManager] Changed current task from \"" .. self:debug_get_task_name(old_task_type) .. "\" to \"" .. self:debug_get_task_name(task_type) .. "\".")
		end
		self._current_task_type = task_type
		if task_type == self.IDLE_TASK_TYPE then
			self._active_changed_callback_handler:dispatch(false, task_type)
		elseif old_task_type == self.IDLE_TASK_TYPE then
			self._active_changed_callback_handler:dispatch(true, task_type)
		end
		local main_time = TimerManager:main():time()
		if task_type == self.SAVE_TASK_TYPE or task_type == self.REMOVE_TASK_TYPE then
			self._workspace:show()
			self._hide_gui_time = nil
			self._show_gui_time = self._show_gui_time or main_time
			if task_type == self.SAVE_TASK_TYPE then
				self._gui_script:set_text(string.upper(managers.localization:text("savefile_saving")))
				self._gui_script.indicator:animate(self._gui_script.saving)
			else
				self._gui_script:set_text(string.upper(managers.localization:text("savefile_removing")))
			end
		elseif self._show_gui_time then
			if main_time - self._show_gui_time > 3 then
				self._hide_gui_time = main_time
			elseif main_time - self._show_gui_time > 1 then
				self._hide_gui_time = self._show_gui_time + 3
			else
				self._hide_gui_time = self._show_gui_time + 3
			end
			self._show_gui_time = nil
		end
	end
end
function SavefileManager:_set_current_game_cache_slot(current_game_cache_slot)
	local old_slot = Global.savefile_manager.current_game_cache_slot
	if old_slot ~= current_game_cache_slot then
		cat_print("savefile_manager", "[SavefileManager] Changed current cache slot from \"" .. tostring(old_slot) .. "\" to \"" .. tostring(current_game_cache_slot) .. "\".")
		if old_slot then
			self:_set_cache(old_slot, nil)
		end
		Global.savefile_manager.current_game_cache_slot = current_game_cache_slot
	end
end
function SavefileManager:_set_corrupt(slot, is_corrupt)
	local meta_data = self:_meta_data(slot)
	if not meta_data.is_corrupt ~= not is_corrupt then
		cat_print("savefile_manager", "[SavefileManager] Slot \"" .. tostring(slot) .. "\" changed corrupt state to \"" .. tostring(not not is_corrupt) .. "\".")
		meta_data.is_corrupt = is_corrupt
	end
end
function SavefileManager:_set_synched_text(slot, is_synched_text)
	local meta_data = self:_meta_data(slot)
	if not meta_data.is_synched_text ~= not is_synched_text then
		cat_print("savefile_manager", "[SavefileManager] Slot \"" .. tostring(slot) .. "\" changed synched text state to \"" .. tostring(not not is_synched_text) .. "\".")
		meta_data.is_synched_text = is_synched_text
	end
end
function SavefileManager:_set_text(slot, save_data, is_synched_text)
	local meta_data = self:_meta_data(slot)
	local text = self:_parse_text(save_data)
	local sort_list = self:_parse_sort_list(save_data)
	if meta_data.text ~= text then
		cat_print("savefile_manager", "[SavefileManager] Slot \"" .. tostring(slot) .. "\" changed text from \"" .. tostring(meta_data.text) .. "\" to \"" .. tostring(text) .. "\".")
		meta_data.text = text
	end
	meta_data.sort_list = sort_list
	self:_set_synched_text(slot, is_synched_text)
end
function SavefileManager:_compare_sort_list(sort_list1, sort_list2)
	if not sort_list1 then
		return 1
	elseif not sort_list2 then
		return -1
	else
		for index, sort1 in ipairs(sort_list1) do
			local sort2 = sort_list2[index]
			if sort1 ~= sort2 then
				return sort1 < sort2 and 1 or -1
			end
		end
		return 0
	end
end
function SavefileManager:_set_synched_cache(slot, is_synched_cache)
	local meta_data = self:_meta_data(slot)
	if not meta_data.is_synched_cache ~= not is_synched_cache then
		cat_print("savefile_manager", "[SavefileManager] Slot \"" .. tostring(slot) .. "\" changed synched cache state to \"" .. tostring(not not is_synched_cache) .. "\".")
		meta_data.is_synched_cache = is_synched_cache
	end
end
function SavefileManager:_set_cache(slot, cache)
	local meta_data = self:_meta_data(slot)
	if meta_data.cache ~= cache then
		cat_print("savefile_manager", "[SavefileManager] Slot \"" .. tostring(slot) .. "\" changed cache from \"" .. tostring(meta_data.cache) .. "\" to \"" .. tostring(cache) .. "\".")
		meta_data.cache = cache
	end
end
function SavefileManager:_set_setting_changed(setting_changed)
	if not Global.savefile_manager.setting_changed ~= not setting_changed then
		cat_print("savefile_manager", "[SavefileManager] Setting changed: \"" .. tostring(setting_changed) .. "\".")
		Global.savefile_manager.setting_changed = setting_changed
	end
end
function SavefileManager:_is_saving_setting_allowed(is_user_initiated_action)
	if not Global.savefile_manager.setting_changed then
		cat_print("savefile_manager", "[SavefileManager] Skips saving setting. Setting is already saved.")
		return false
	elseif not is_user_initiated_action then
		local safe_time = Global.savefile_manager.safe_profile_save_time
		if safe_time then
			local time = TimerManager:main():time()
			if safe_time >= time then
				cat_print("savefile_manager", string.format("[SavefileManager] Skips saving setting. Needs to be user initiated or triggered after %g seconds.", safe_time - time))
				return false
			else
				Global.savefile_manager.safe_profile_save_time = nil
			end
		end
	end
	return true
end
function SavefileManager:fetch_savegame_hdd_space_required()
	return self._savegame_hdd_space_required
end
function SavefileManager:_ask_load_backup(reason, dialog_at_init, load_params)
	local dialog_data = {}
	dialog_data.title = managers.localization:text("dialog_error_title")
	local yes_button = {}
	yes_button.text = managers.localization:text("dialog_yes")
	local no_button = {}
	no_button.text = managers.localization:text("dialog_no")
	dialog_data.button_list = {yes_button, no_button}
	function yes_button.callback_func()
		self:_set_cache(self.PROGRESS_SLOT, self._backup_data.save_data:information())
		self._backup_data = nil
		self:_load_cache(self.PROGRESS_SLOT)
	end
	function no_button.callback_func()
		self._backup_data = nil
	end
	if reason == "no_progress" or reason == "low_progress" then
		dialog_data.text = managers.localization:text("dialog_ask_load_progress_backup_low_lvl")
		if reason == "low_progress" then
			function no_button.callback_func()
				self._backup_data = nil
				self:_load_done(self.PROGRESS_SLOT, unpack(load_params))
			end
		end
	elseif reason == "progress_corrupt" or reason == "progress_wrong_version" then
		dialog_data.text = managers.localization:text("dialog_ask_load_progress_backup_" .. (reason == "progress_corrupt" and "corrupt" or "wrong_version"))
		function no_button.callback_func()
			self._backup_data = nil
			self:_remove(self.PROGRESS_SLOT)
		end
	end
	if dialog_at_init then
		managers.system_menu:add_init_show(dialog_data)
	else
		managers.system_menu:show(dialog_data)
	end
end
SavefileTaskHandler = SavefileTaskHandler or class()
function SavefileTaskHandler:init(task, task_type, callback_func, done_callback_func)
	self._task = task
	self._task_type = task_type
	self._callback_func = callback_func
	self._done_callback_func = done_callback_func
	if self._task_type == SavefileManager.REMOVE_TASK_TYPE then
		print("SavefileTaskHandler Show rect")
		self._ws = Overlay:gui():create_screen_workspace()
		self._remove_rect = self._ws:panel():rect({
			color = Color(0.97, 0, 0, 0),
			layer = 1200
		})
	end
end
function SavefileTaskHandler:destroy()
	self._task = nil
end
function SavefileTaskHandler:task_type()
	return self._task_type
end
function SavefileTaskHandler:update()
	while self._task:has_next() do
		self._callback_func(self._task:next())
	end
	if self._task:done() and self._done_callback_func then
		self._done_callback_func()
	end
	if self._task:done() and alive(self._remove_rect) then
		print("SavefileTaskHandler Hide rect")
		self._remove_rect:set_visible(false)
		Overlay:gui():destroy_workspace(self._ws)
	end
	return self._task:done()
end
LoadPlatformSettingMapTask = LoadPlatformSettingMapTask or class()
function LoadPlatformSettingMapTask:init()
	managers.user:load_platform_setting_map(callback(self, self, "load_platform_setting_map_callback"))
end
function LoadPlatformSettingMapTask:load_platform_setting_map_callback(platform_setting_map)
	self._platform_setting_map = platform_setting_map
	self._has_next = true
end
function LoadPlatformSettingMapTask:has_next()
	return not self._done and self._has_next
end
function LoadPlatformSettingMapTask:next()
	self._has_next = nil
	self._done = true
	return self._platform_setting_map
end
function LoadPlatformSettingMapTask:done()
	return self._done
end
SavePlatformSettingMapTask = SavePlatformSettingMapTask or class()
function SavePlatformSettingMapTask:init()
	managers.user:save_setting_map(callback(self, self, "save_platform_setting_map_callback"))
end
function SavePlatformSettingMapTask:save_platform_setting_map_callback(result)
	self._result = result
	self._has_next = true
end
function SavePlatformSettingMapTask:has_next()
	return not self._done and self._has_next
end
function SavePlatformSettingMapTask:next()
	self._has_next = nil
	self._done = true
	return self._result
end
function SavePlatformSettingMapTask:done()
	return self._done
end
SavefileInfo = SavefileInfo or class()
function SavefileInfo:init(slot, text)
	self._slot = slot
	self._text = text
end
function SavefileInfo:slot()
	return self._slot
end
function SavefileInfo:text()
	return self._text
end
