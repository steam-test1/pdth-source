core:module("CoreEnvironmentData")
core:import("CoreClass")
EnvironmentData = EnvironmentData or CoreClass.class()
function EnvironmentData:init(entry_path)
	self._entry_path = entry_path
	self._metadata = {}
	self._data = {}
	if entry_path then
		self:load(entry_path)
	end
end
function EnvironmentData:load(entry_path)
	self._metadata = {}
	self._data = {}
	local env_data = self:_serialize_to_script("environment", entry_path)
	env_data.metadata._meta = nil
	env_data.metadata.param = nil
	for _, data in ipairs(env_data.metadata) do
		self._metadata[data.key] = data.key.value
	end
	self:_serialized_load_data(env_data.data, self._data)
	return
end
function EnvironmentData:name()
	return self._entry_path
end
function EnvironmentData:copy()
	local data = EnvironmentData:new()
	data._entry_path = self._entry_path
	self:for_each(function(block, ...)
		data:_set(true, data._data, block, ...)
	end)
	return data
end
function EnvironmentData:for_each(cb)
	self:_for_each(cb, self._data, {})
end
function EnvironmentData:parameter_block(...)
	return self:_get(self._data, ...)
end
function EnvironmentData:set_parameter_block(block_data, ...)
	self:_set(false, self._data, block_data, ...)
end
function EnvironmentData:data_root()
	return self._data
end
function EnvironmentData:metadata()
	return self._metadata
end
function EnvironmentData:_serialize_to_script(type, name)
	if Application:editor() then
		return PackageManager:editor_load_script_data(type:id(), name:id())
	else
		return PackageManager:script_data(type:id(), name:id())
	end
end
function EnvironmentData:_for_each(cb, data, path)
	for k, v in pairs(data) do
		local t = {
			unpack(path)
		}
		local the_end = false
		for _, pv in pairs(v) do
			if type(pv) ~= "table" then
				table.insert(t, k)
				cb(v, unpack(t))
				the_end = true
			else
			end
		end
		if not the_end then
			table.insert(t, k)
			self:_for_each(cb, v, t)
		end
	end
end
function EnvironmentData:_get(data, ...)
	local args = {
		...
	}
	local arg = data[args[1]]
	if #args == 1 then
		return arg
	else
		return self:_get(arg, select(2, ...))
	end
	error("[EnvironmentData] Bad path!")
end
function EnvironmentData:_set(create_new, data, block, ...)
	local args = {
		...
	}
	local arg = data[args[1]]
	if not arg and create_new then
		arg = {}
		data[args[1]] = arg
	end
	if #args == 1 then
		for pk, pv in pairs(block) do
			arg[pk] = pv
		end
		return
	else
		self:_set(create_new, arg, block, select(2, ...))
		return
	end
	error("[EnvironmentData] Bad path!")
end
function EnvironmentData:_serialized_load_data(data, data_table)
	for _, d in ipairs(data) do
		if d._meta == "param" then
			data_table[d.key] = d.value
		else
			local child_data = {}
			data_table[d._meta] = child_data
			self:_serialized_load_data(d, child_data)
		end
	end
end
