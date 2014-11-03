core:module("CoreEnvironmentHandle")
core:import("CoreClass")
EnvironmentHandle = EnvironmentHandle or CoreClass.class()
function EnvironmentHandle:init(mixer, interface, full_control, func, name, shared, ...)
	self._mixer = mixer
	self._interface = interface:new(self)
	self._full_control = full_control
	self._script_cb = func
	self._name = name
	self._shared = shared
	self._path = {
		...
	}
	self._traceback = debug.traceback()
end
function EnvironmentHandle:name()
	return self._name
end
function EnvironmentHandle:traceback()
	return self._traceback
end
function EnvironmentHandle:do_callback()
	if self._interface._pre_call then
		self._interface:_pre_call()
	end
	local ret = self._script_cb(self._interface)
	if self._interface._process_return then
		ret = self._interface:_process_return(ret)
	end
	return assert(ret, "[EnvironmentHandle] The script callback should return a table!")
end
function EnvironmentHandle:processed()
	return self._full_control
end
function EnvironmentHandle:shared()
	return self._shared
end
function EnvironmentHandle:parameter_info(name)
	return self._mixer:parameter_info(name)
end
function EnvironmentHandle:parameters()
	return self._mixer:internal_output(unpack(self._path))
end
