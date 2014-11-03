core:module("CoreControllerManager")
core:import("CoreControllerWrapperSettings")
core:import("CoreControllerWrapperGamepad")
core:import("CoreControllerWrapperPC")
core:import("CoreControllerWrapperXbox360")
core:import("CoreControllerWrapperPS3")
core:import("CoreControllerWrapperDebug")
core:import("CoreManagerBase")
core:import("CoreEvent")
ControllerManager = ControllerManager or class(CoreManagerBase.ManagerBase)
ControllerManager.CONTROLLER_SETTINGS_TYPE = ControllerManager.CONTROLLER_SETTINGS_TYPE or "controller_settings"
ControllerManager.CORE_CONTROLLER_SETTINGS_PATH = ControllerManager.CORE_CONTROLLER_SETTINGS_PATH or "core/settings/core_controller_settings"
function ControllerManager:init(path, default_settings_path)
	ControllerManager.super.init(self, "controller")
	if not Global.controller_manager then
		Global.controller_manager = {default_controller_connected = nil}
	end
	self._skip_controller_map = {}
	if SystemInfo:platform() ~= Idstring("WIN32") then
		self._skip_controller_map.win32_keyboard = true
		self._skip_controller_map.win32_mouse = true
	end
	self._controller_to_wrapper_list = {}
	self._wrapper_to_controller_list = {}
	self._wrapper_class_map = {}
	self._wrapper_count = 0
	self:create_virtual_pad()
	self._last_default_wrapper_index_change_callback_id = 0
	self._default_wrapper_index_change_callback_map = {}
	self._controller_wrapper_list = {}
	self._controller_wrapper_map = {}
	self._next_controller_wrapper_id = 1
	self._supported_wrapper_types = {}
	if SystemInfo:platform() == Idstring("WIN32") then
		self._supported_wrapper_types[CoreControllerWrapperPC.ControllerWrapperPC.TYPE] = CoreControllerWrapperPC.ControllerWrapperPC
	elseif SystemInfo:platform() == Idstring("PS3") then
		self._supported_wrapper_types[CoreControllerWrapperPS3.ControllerWrapperPS3.TYPE] = CoreControllerWrapperPS3.ControllerWrapperPS3
	end
	self._supported_controller_type_map = {}
	for wrapper_type, wrapper in pairs(self._supported_wrapper_types) do
		for _, controller_type in ipairs(wrapper.CONTROLLER_TYPE_LIST) do
			self._supported_controller_type_map[controller_type] = wrapper_type
		end
	end
	self._last_version = nil
	self._last_core_version = nil
	self._default_settings_path = default_settings_path
	self._controller_setup = {}
	self._core_controller_setup = {}
	self._settings_file_changed_callback_list = {}
	self._last_settings_file_changed_callback_id = 0
	self._settings_path = path
	self:load_core_settings(false)
	self._default_controller_connect_change_callback_handler = CoreEvent.CallbackEventHandler:new()
	self:update_controller_wrapper_mappings()
	self:setup_default_controller_list()
end
function ControllerManager:setup_default_controller_list()
	if Global.controller_manager.default_wrapper_index then
		local controller_index_list = self._wrapper_to_controller_list[Global.controller_manager.default_wrapper_index]
		self._default_controller_list = {}
		for _, controller_index in ipairs(controller_index_list) do
			table.insert(self._default_controller_list, Input:controller(controller_index))
		end
	end
end
function ControllerManager:update(t, dt)
	for id, controller_wrapper in pairs(self._controller_wrapper_list) do
		if controller_wrapper:enabled() then
			controller_wrapper:update(t, dt)
		end
	end
	self:check_connect_change()
end
function ControllerManager:paused_update(t, dt)
	for id, controller_wrapper in pairs(self._controller_wrapper_list) do
		if controller_wrapper:enabled() then
			controller_wrapper:paused_update(t, dt)
		end
	end
	self:check_connect_change()
end
function ControllerManager:check_connect_change()
	if self._default_controller_list then
		local connected
		for _, controller in ipairs(self._default_controller_list) do
			connected = controller:connected()
			if not connected then
			else
			end
		end
		if not Global.controller_manager.default_controller_connected ~= not connected then
			self:default_controller_connect_change(connected)
			Global.controller_manager.default_controller_connected = connected
		end
	end
end
function ControllerManager:default_controller_connect_change(connected)
	self._default_controller_connect_change_callback_handler:dispatch(connected)
end
function ControllerManager:add_settings_file_changed_callback(func)
	self._last_settings_file_changed_callback_id = self._last_settings_file_changed_callback_id + 1
	self._settings_file_changed_callback_list[self._last_settings_file_changed_callback_id] = func
	return self._last_settings_file_changed_callback_id
end
function ControllerManager:remove_settings_file_changed_callback(id)
	self._settings_file_changed_callback_list[id] = nil
end
function ControllerManager:add_default_controller_connect_change_callback(func)
	self._default_controller_connect_change_callback_handler:add(func)
end
function ControllerManager:remove_default_controller_connect_change_callback(func)
	self._default_controller_connect_change_callback_handler:remove(func)
end
function ControllerManager:create_controller(name, index, debug, prio)
	local controller_wrapper
	self:update_controller_wrapper_mappings()
	if debug then
		local wrapper_list = {}
		local default_wrapper
		for wrapper_index, wrapper_class in pairs(self._wrapper_class_map) do
			local controller_index = self._wrapper_to_controller_list[wrapper_index][1]
			local controller = Input:controller(controller_index)
			local wrapper = wrapper_class:new(self, self._next_controller_wrapper_id, name, controller, self._controller_setup[wrapper_class.TYPE], debug, false, self._virtual_game_pad)
			self:_add_accessobj(wrapper, prio or CoreManagerBase.PRIO_DEFAULT)
			default_wrapper = default_wrapper or wrapper
			table.insert(wrapper_list, wrapper)
		end
		controller_wrapper = CoreControllerWrapperDebug.ControllerWrapperDebug:new(wrapper_list, self, self._next_controller_wrapper_id, name, default_wrapper, CoreControllerWrapperSettings.ControllerWrapperSettings:new(CoreControllerWrapperDebug.ControllerWrapperDebug.TYPE, nil, nil, nil))
	else
		index = index or Global.controller_manager.default_wrapper_index or self:get_preferred_default_wrapper_index()
		local wrapper_class = self._wrapper_class_map[index]
		if not wrapper_class then
			error("Tried to create a controller with non-existing index \"" .. tostring(index) .. "\" (default index: " .. tostring(Global.controller_manager.default_wrapper_index) .. ", name: \"" .. tostring(name) .. "\").")
		end
		local controller_index = self._wrapper_to_controller_list[index][1]
		local controller = Input:controller(controller_index)
		controller_wrapper = wrapper_class:new(self, self._next_controller_wrapper_id, name, controller, self._controller_setup[wrapper_class.TYPE], debug, false, self._virtual_game_pad)
	end
	if name then
		if self._controller_wrapper_map[name] then
			controller_wrapper:destroy()
			error("Tried to create a controller with a name \"" .. tostring(name) .. "\" that already exists.")
		end
		self._controller_wrapper_map[name] = controller_wrapper
	end
	cat_print("controller_manager", "[ControllerManager] Created new controller. Name: " .. tostring(name) .. ", Index: " .. tostring(index) .. ", Debug: " .. tostring(debug) .. ", Id: " .. tostring(self._next_controller_wrapper_id))
	controller_wrapper:add_destroy_callback(callback(self, self, "controller_wrapper_destroy_callback"))
	self._controller_wrapper_list[self._next_controller_wrapper_id] = controller_wrapper
	self._next_controller_wrapper_id = self._next_controller_wrapper_id + 1
	self:_add_accessobj(controller_wrapper, prio or CoreManagerBase.PRIO_DEFAULT)
	return controller_wrapper
end
function ControllerManager:get_controller_by_name(name)
	if name and self._controller_wrapper_map[name] then
		return self._controller_wrapper_map[name]
	end
end
function ControllerManager:get_preferred_default_wrapper_index()
	self:update_controller_wrapper_mappings()
	for wrapper_index, wrapper_class in ipairs(self._wrapper_class_map) do
		if Input:controller(wrapper_index):connected() and wrapper_class.TYPE ~= "pc" then
			return wrapper_index
		end
	end
	return 1
end
function ControllerManager:get_default_wrapper_type()
	local index = Global.controller_manager.default_wrapper_index or self:get_preferred_default_wrapper_index()
	local wrapper_class = self._wrapper_class_map[index]
	return wrapper_class.TYPE
end
function ControllerManager:update_controller_wrapper_mappings()
	local controller_count = Input:num_real_controllers()
	local controller_type_to_old_wrapper_map = {}
	local next_wrapper_index = 1
	for controller_index = 0, controller_count do
		if not self._controller_to_wrapper_list[controller_index] then
			local controller = Input:controller(controller_index)
			local controller_type = controller:type()
			local wrapper_type = self._supported_controller_type_map[controller_type]
			if wrapper_type and not self._skip_controller_map[controller_type] then
				local old_wrapper_index = controller_type_to_old_wrapper_map[controller_type]
				local wrapper_index
				local wrapper_class = self._supported_wrapper_types[wrapper_type]
				if old_wrapper_index then
					wrapper_index = old_wrapper_index
					controller_type_to_old_wrapper_map[controller_type] = nil
				else
					wrapper_index = next_wrapper_index
					self._wrapper_count = next_wrapper_index
					self._wrapper_class_map[wrapper_index] = wrapper_class
					for _, next_controller_type in ipairs(wrapper_class.CONTROLLER_TYPE_LIST) do
						if controller_type ~= next_controller_type then
							controller_type_to_old_wrapper_map[next_controller_type] = wrapper_index
						end
					end
					next_wrapper_index = next_wrapper_index + 1
				end
				self._controller_to_wrapper_list[controller_index] = wrapper_index
				self._wrapper_to_controller_list[wrapper_index] = self._wrapper_to_controller_list[wrapper_index] or {}
				if controller_type == wrapper_class.CONTROLLER_TYPE_LIST[1] then
					table.insert(self._wrapper_to_controller_list[wrapper_index], 1, controller_index)
				else
					table.insert(self._wrapper_to_controller_list[wrapper_index], controller_index)
				end
			end
		end
	end
end
function ControllerManager:get_controller_index_list(wrapper_index)
	return self._wrapper_to_controller_list[wrapper_index]
end
function ControllerManager:get_wrapper_index(controller_index)
	return self._controller_to_wrapper_list[controller_index]
end
function ControllerManager:get_real_controller_count()
	return Input:num_real_controllers()
end
function ControllerManager:get_wrapper_count()
	self:update_controller_wrapper_mappings()
	return self._wrapper_count
end
function ControllerManager:add_default_wrapper_index_change_callback(func)
	self._last_default_wrapper_index_change_callback_id = self._last_default_wrapper_index_change_callback_id + 1
	self._default_wrapper_index_change_callback_map[self._last_default_wrapper_index_change_callback_id] = func
	return self._last_default_wrapper_index_change_callback_id
end
function ControllerManager:remove_default_wrapper_index_change_callback(id)
	self._default_wrapper_index_change_callback_map[id] = nil
end
function ControllerManager:set_default_wrapper_index(default_wrapper_index)
	if Global.controller_manager.default_wrapper_index ~= default_wrapper_index then
		local controller_index_list = default_wrapper_index and self._wrapper_to_controller_list[default_wrapper_index]
		if not default_wrapper_index or controller_index_list then
			cat_print("controller_manager", "[ControllerManager] Changed default controller index from " .. tostring(Global.controller_manager.default_wrapper_index) .. " to " .. tostring(default_wrapper_index) .. ".")
			Global.controller_manager.default_wrapper_index = default_wrapper_index
			local remove_safe_list = {}
			for _, func in pairs(self._default_wrapper_index_change_callback_map) do
				table.insert(remove_safe_list, func)
			end
			for _, func in ipairs(remove_safe_list) do
				func(default_wrapper_index)
			end
			self:setup_default_controller_list()
		else
			Application:error("Invalid default controller index.")
		end
	end
end
function ControllerManager:get_default_wrapper_index()
	return Global.controller_manager.default_wrapper_index
end
function ControllerManager:controller_wrapper_destroy_callback(controller_wrapper)
	self:_del_accessobj(controller_wrapper)
	local id = controller_wrapper:get_id()
	local name = controller_wrapper:get_name()
	cat_print("controller_manager", "[ControllerManager] Destroyed controller. Name: " .. tostring(name) .. ", Id: " .. tostring(id))
	self._controller_wrapper_list[id] = nil
	if name then
		self._controller_wrapper_map[name] = nil
	end
end
function ControllerManager:load_core_settings()
	local result
	if PackageManager:has(self.CONTROLLER_SETTINGS_TYPE:id(), self.CORE_CONTROLLER_SETTINGS_PATH:id()) then
		local node = PackageManager:script_data(self.CONTROLLER_SETTINGS_TYPE:id(), self.CORE_CONTROLLER_SETTINGS_PATH:id())
		local parsed_controller_setup_map = {}
		for _, child in ipairs(node) do
			local wrapper_type = child._meta
			if self._core_controller_setup[wrapper_type] then
				Application:error("Duplicate core controller settings for \"" .. tostring(wrapper_type) .. "\" found in \"" .. tostring(self.CORE_CONTROLLER_SETTINGS_PATH) .. "." .. tostring(self.CONTROLLER_SETTINGS_TYPE) .. "\". Overwrites existing one.")
			end
			local setup = CoreControllerWrapperSettings.ControllerWrapperSettings:new(wrapper_type, child, nil, self.CORE_CONTROLLER_SETTINGS_PATH .. "." .. self.CONTROLLER_SETTINGS_TYPE)
			parsed_controller_setup_map[wrapper_type] = setup
		end
		if self:verify_parsed_controller_setup_map(parsed_controller_setup_map, self.CORE_CONTROLLER_SETTINGS_PATH) then
			self._last_core_version = tonumber(node.core_version)
			self._core_controller_setup = parsed_controller_setup_map
			self._controller_setup = parsed_controller_setup_map
		end
		result = true
	end
	if self._settings_path then
		self:load_settings(self._settings_path)
	end
	return result
end
function ControllerManager:load_settings(path)
	local result = false
	if self._default_settings_path and (not path or not PackageManager:has(self.CONTROLLER_SETTINGS_TYPE:id(), path:id())) then
		if path then
			Application:error("Invalid path \"" .. tostring(path) .. "." .. tostring(self.CONTROLLER_SETTINGS_TYPE) .. "\", defaults to \"" .. tostring(self._default_settings_path) .. "." .. tostring(self.CONTROLLER_SETTINGS_TYPE) .. "\".")
		end
		path = self._default_settings_path
	end
	if path and PackageManager:has(self.CONTROLLER_SETTINGS_TYPE:id(), path:id()) then
		local node = PackageManager:script_data(self.CONTROLLER_SETTINGS_TYPE:id(), path:id())
		local version = tonumber(node.version)
		local core_version = tonumber(node.core_version)
		local valid_version = not self._last_version or version and version >= self._last_version
		local valid_core_version = path == self._default_settings_path or not self._last_core_version or not core_version or core_version >= self._last_core_version
		if valid_version and valid_core_version then
			local parsed_controller_setup_map = {}
			for _, child in ipairs(node) do
				local wrapper_type = child._meta
				if parsed_controller_setup_map[wrapper_type] then
					Application:error("Duplicate controller settings for \"" .. tostring(wrapper_type) .. "\" found in \"" .. tostring(path) .. "." .. tostring(self.CONTROLLER_SETTINGS_TYPE) .. "\". Overwrites existing one.")
				end
				local setup = CoreControllerWrapperSettings.ControllerWrapperSettings:new(wrapper_type, child, self._core_controller_setup[wrapper_type], tostring(path) .. "." .. tostring(self.CONTROLLER_SETTINGS_TYPE))
				parsed_controller_setup_map[wrapper_type] = setup
			end
			if self:verify_parsed_controller_setup_map(parsed_controller_setup_map, path) then
				result = true
				for _, controller_wrapper in pairs(self._controller_wrapper_list) do
					controller_wrapper:clear_connections(false)
				end
				self._controller_setup = parsed_controller_setup_map
				self._last_version = version
				self._settings_path = path
			else
				Application:error("Ignores invalid controller setting file \"" .. tostring(path) .. "." .. tostring(self.CONTROLLER_SETTINGS_TYPE) .. "\".")
			end
		else
			local error_msg = "Old controller settings file \"" .. tostring(path) .. "." .. tostring(self.CONTROLLER_SETTINGS_TYPE) .. "\" detected (version: \"" .. tostring(version) .. "\", core version: \"" .. tostring(core_version) .. "\", latest version: \"" .. tostring(self._last_version) .. "\", latest core version: \"" .. tostring(self._last_core_version) .. "\"."
			local load_default
			if path ~= self._default_settings_path then
				error_msg = error_msg .. " Loads the default path \"" .. tostring(self._default_settings_path) .. "." .. tostring(self.CONTROLLER_SETTINGS_TYPE) .. "\" instead."
			end
			Application:error(error_msg)
			if path ~= self._default_settings_path then
				self:load_settings(self._default_settings_path)
			end
		end
	else
		Application:error("No controller settings file were found at path \"" .. tostring(path) .. "." .. tostring(self.CONTROLLER_SETTINGS_TYPE) .. "\".")
	end
	for wrapper_type, _ in pairs(self._supported_wrapper_types) do
		self._controller_setup[wrapper_type] = self._controller_setup[wrapper_type] or CoreControllerWrapperSettings.ControllerWrapperSettings:new(wrapper_type, nil, self._core_controller_setup[wrapper_type], nil)
	end
	self:rebind_connections()
	for id, func in pairs(self._settings_file_changed_callback_list) do
		func(id)
	end
	return result
end
function ControllerManager:save_settings(path)
	if not rawget(_G, "SystemFS") then
		Application:error("Unable to save controller settings. Not supported on this platform.")
	elseif self._last_version and path then
		local file = SystemFS:open("./" .. tostring(path), "w")
		local data = {
			_meta = "controller_settings",
			core_version = self._last_core_version,
			version = self._last_version
		}
		for wrapper_type, setting in pairs(self._controller_setup) do
			setting:populate_data(data)
		end
		file:print(ScriptSerializer:to_custom_xml(data))
		SystemFS:close(file)
		self._settings_path = path
	else
		Application:error("Unable to save controller settings. No settings to save.")
	end
end
function ControllerManager:rebind_connections()
	for _, controller_wrapper in pairs(self._controller_wrapper_list) do
		controller_wrapper:rebind_connections(self._controller_setup[controller_wrapper:get_type()], self._controller_setup)
	end
end
function ControllerManager:get_settings_map()
	return self._controller_setup
end
function ControllerManager:get_settings(wrapper_type)
	return self._controller_setup[wrapper_type]
end
function ControllerManager:get_default_settings_path()
	return self._default_settings_path
end
function ControllerManager:set_default_settings_path(path)
	self._default_settings_path = path
end
function ControllerManager:get_settings_path()
	return self._default_settings_path
end
function ControllerManager:set_settings_path(path)
	self._settings_path = path
end
function ControllerManager:create_virtual_pad()
	self._virtual_game_pad = self._virtual_game_pad or Input:create_virtual_controller("all_gamepads")
	self._virtual_game_pad:clear_connections()
	local game_pad_num = 0
	local step = 0
	local num = Input:num_real_controllers()
	while step < num do
		local controller = Input:controller(step)
		if controller and controller:type() == "win32_game_controller" and controller:connected() then
			game_pad_num = game_pad_num + 1
			for i = 0, controller:num_buttons() - 1 do
				self._virtual_game_pad:connect(controller, controller:button_name(i), Idstring("gamepad" .. tostring(game_pad_num) .. "_B" .. tostring(i)))
			end
			for i = 0, controller:num_axes() - 1 do
				self._virtual_game_pad:connect(controller, controller:axis_name(i), Idstring("gamepad" .. tostring(game_pad_num) .. "_A" .. tostring(i)))
			end
		end
		step = step + 1
	end
	local controller = Input:mouse()
	for i = 0, controller:num_buttons() - 1 do
		self._virtual_game_pad:connect(controller, controller:button_name(i), Idstring("mouse " .. tostring(i)))
	end
end
function ControllerManager:verify_parsed_controller_setup_map(parsed_controller_setup_map, path)
	local result = true
	local connection_map = {}
	local last_wrapper_type
	for wrapper_type, setup in pairs(parsed_controller_setup_map) do
		local current_connection_map = setup:get_connection_map()
		for connection_name in pairs(current_connection_map) do
			if not last_wrapper_type then
				connection_map[connection_name] = wrapper_type
			elseif not connection_map[connection_name] then
				Application:error("Controller settings for \"" .. tostring(last_wrapper_type) .. "\" doesn't have a connection called \"" .. tostring(connection_name) .. "\" in \"" .. tostring(path) .. "." .. tostring(self.CONTROLLER_SETTINGS_TYPE) .. "\". It was last specified in \"" .. tostring(wrapper_type) .. "\".")
				connection_map[connection_name] = wrapper_type
				result = false
			end
		end
		if last_wrapper_type then
			for connection_name, found_wrapper_type in pairs(connection_map) do
				if not current_connection_map[connection_name] then
					Application:error("Controller settings for \"" .. tostring(wrapper_type) .. "\" doesn't have a connection called \"" .. tostring(connection_name) .. "\" in \"" .. tostring(path) .. "." .. tostring(self.CONTROLLER_SETTINGS_TYPE) .. "\". It was last specified in \"" .. tostring(found_wrapper_type) .. "\".")
					result = false
				end
			end
		end
		last_wrapper_type = last_wrapper_type or wrapper_type
	end
	return result
end
