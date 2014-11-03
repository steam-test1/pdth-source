core:module("CoreEnvironmentDebugInterface")
core:import("CoreClass")
EnvironmentDebugInterface = EnvironmentDebugInterface or CoreClass.class()
EnvironmentDebugInterface.DATA_PATH = nil
EnvironmentDebugInterface.SHARED = nil
function EnvironmentDebugInterface:processed()
	return self._handle:processed()
end
function EnvironmentDebugInterface:shared()
	return self._handle:shared()
end
function EnvironmentDebugInterface:parameter_info(name)
	return self._handle:parameter_info(name)
end
function EnvironmentDebugInterface:parameters()
	return table.list_copy(self._handle:parameters())
end
function EnvironmentDebugInterface:init(handle)
	self._handle = handle
	self._init_trace_back = debug.traceback()
end
