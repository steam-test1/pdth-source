core:module("CoreEnvironmentCache")
core:import("CoreClass")
core:import("CoreEnvironmentData")
EnvironmentCache = EnvironmentCache or CoreClass.class()
function EnvironmentCache:init()
	self._full_control_handles = {}
	self._part_control_handles = {}
	self._preloaded_environments = {}
end
function EnvironmentCache:set_shared_handle(full_control, name, handle)
	if full_control then
		self._full_control_handles[name] = handle
	else
		self._part_control_handles[name] = handle
	end
	return name
end
function EnvironmentCache:destroy_shared_handle(id)
	local handle = self._full_control_handles[id] or self._part_control_handles[id]
	self._full_control_handles[id] = nil
	self._part_control_handles[id] = nil
	assert(handle, "[EnvironmentMixer] No handle!")
end
function EnvironmentCache:shared_handle(full_control, id)
	if full_control == true then
		return self._full_control_handles[id]
	elseif full_control == false then
		return self._part_control_handles[id]
	else
		return self._full_control_handles[id] or self._part_control_handles[id]
	end
end
function EnvironmentCache:load_environment(name)
	local env = self._preloaded_environments[name]
	if not env then
		if not Application:editor() then
			Application:error("[EnvironmentCache] WARNING! Environment was not preloaded: " .. name)
		end
		self:preload_environment(name)
		env = self._preloaded_environments[name]
	end
	return env
end
function EnvironmentCache:copy_environment(name)
	local env = self:load_environment(name)
	return env:copy()
end
function EnvironmentCache:preload_environment(name)
	if not self._preloaded_environments[name] then
		self._preloaded_environments[name] = CoreEnvironmentData.EnvironmentData:new(name)
	end
end
function EnvironmentCache:environment(name)
	return self:load_environment(name)
end
