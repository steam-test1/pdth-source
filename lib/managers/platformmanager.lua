core:module("PlatformManager")
core:import("CoreEvent")
PlatformManager = PlatformManager or class()
PlatformManager.PLATFORM_CLASS_MAP = {}
function PlatformManager:new(...)
	local platform = SystemInfo:platform()
	return (self.PLATFORM_CLASS_MAP[platform:key()] or GenericPlatformManager):new(...)
end
GenericPlatformManager = GenericPlatformManager or class()
function GenericPlatformManager:init()
	self._event_queue_list = {}
	self._event_callback_handler_map = {}
	self._current_presence = "Idle"
end
function GenericPlatformManager:event(event_type, ...)
	table.insert(self._event_queue_list, {
		event_type = event_type,
		param_list = {
			...
		}
	})
end
function GenericPlatformManager:destroy_context()
end
function GenericPlatformManager:add_event_callback(event_type, callback_func)
	self._event_callback_handler_map[event_type] = self._event_callback_handler_map[event_type] or CoreEvent.CallbackEventHandler:new()
	self._event_callback_handler_map[event_type]:add(callback_func)
end
function GenericPlatformManager:remove_event_callback(event_type, callback_func)
	assert(event_type and self._event_callback_handler_map[event_type], "Tried to remove non-existing callback on event type \"" .. tostring(event_type) .. "\".")
	self._event_callback_handler_map[event_type]:remove(callback_func)
	if not next(self._event_callback_handler_map[event_type]) then
		self._event_callback_handler_map[event_type] = nil
	end
end
function GenericPlatformManager:update(t, dt)
	if next(self._event_queue_list) then
		for _, event in ipairs(self._event_queue_list) do
			local callback_handler = self._event_callback_handler_map[event.event_type]
			if callback_handler then
				callback_handler:dispatch(unpack(event.param_list))
			end
		end
		self._event_queue_list = {}
	end
end
function GenericPlatformManager:paused_update(t, dt)
	self:update(t, dt)
end
function GenericPlatformManager:set_presence(name)
	self._current_presence = name
end
function GenericPlatformManager:presence()
	return self._current_presence
end
function GenericPlatformManager:translate_path(path)
	return string.gsub(path, "/+([~/]*)", "\\%1")
end
Xbox360PlatformManager = Xbox360PlatformManager or class(GenericPlatformManager)
PlatformManager.PLATFORM_CLASS_MAP[_G.Idstring("X360"):key()] = Xbox360PlatformManager
function Xbox360PlatformManager:init()
	GenericPlatformManager.init(self)
	XboxLive:set_callback(callback(self, self, "event"))
end
function Xbox360PlatformManager:destroy_context()
	GenericPlatformManager.destroy_context(self)
	XboxLive:set_callback(nil)
end
PS3PlatformManager = PS3PlatformManager or class(GenericPlatformManager)
PlatformManager.PLATFORM_CLASS_MAP[_G.Idstring("PS3"):key()] = PS3PlatformManager
function PS3PlatformManager:init(...)
	PS3PlatformManager.super.init(self, ...)
	self._current_psn_presence = ""
	self._psn_set_presence_time = 0
end
function PS3PlatformManager:translate_path(path)
	return string.gsub(path, "\\+([~\\]*)", "/%1")
end
function PS3PlatformManager:update(t, dt)
	PS3PlatformManager.super.update(self, t, dt)
	if self._current_psn_presence ~= self:presence() and t >= self._psn_set_presence_time then
		self._psn_set_presence_time = t + 10
		self._current_psn_presence = self:presence()
		print("SET PRESENCE", self._current_psn_presence)
		PSN:set_presence_info(self._current_psn_presence)
	end
end
function PS3PlatformManager:set_presence(name)
	GenericPlatformManager.set_presence(self, name)
end
WinPlatformManager = WinPlatformManager or class(GenericPlatformManager)
PlatformManager.PLATFORM_CLASS_MAP[_G.Idstring("WIN32"):key()] = WinPlatformManager
