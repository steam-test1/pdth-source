core:import("CoreControllerWrapper")
ControllerWrapper = ControllerWrapper or class(CoreControllerWrapper.ControllerWrapper)
function ControllerWrapper:init(...)
	self._input_released_cache = {}
	ControllerWrapper.super.init(self, ...)
end
function ControllerWrapper:reset_cache(check_time)
	local reset_cache_time = TimerManager:wall():time()
	if (not check_time or reset_cache_time > self._reset_cache_time) and next(self._input_released_cache) then
		self._input_released_cache = {}
	end
	ControllerWrapper.super.reset_cache(self, check_time)
end
function ControllerWrapper:get_input_released(connection_name)
	local cache = self._input_released_cache[connection_name]
	if cache == nil then
		if self._connection_map[connection_name] then
			cache = self._enabled and self._virtual_controller and self:get_connection_enabled(connection_name) and self._virtual_controller:released(Idstring(connection_name)) or false
			cache = not not cache
		else
			Application:error(self:to_string() .. " No controller input binded to connection \"" .. tostring(connection_name) .. "\".")
			cache = false
		end
		self._input_released_cache[connection_name] = cache
	end
	return cache
end
CoreClass.override_class(CoreControllerWrapper.ControllerWrapper, ControllerWrapper)
