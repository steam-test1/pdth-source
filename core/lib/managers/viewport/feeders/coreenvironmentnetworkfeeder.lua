core:module("CoreEnvironmentNetworkFeeder")
core:import("CoreClass")
core:import("CoreCode")
NETWORK_SLAVE_RECEIVER = Idstring("envnetfeeder_slave")
NETWORK_MASTER_RECEIVER = Idstring("envnetfeeder_master")
EnvironmentNetworkFeeder = EnvironmentNetworkFeeder or CoreClass.class()
function EnvironmentNetworkFeeder:init()
	self._verification_table = {}
	self._block_nr = 1
end
function EnvironmentNetworkFeeder:feed(nr, scene, vp, data, block, ...)
	if nr == 1 then
		if assert(managers.slave:type()) == "slave" then
			if not self._data_cache then
				self._data_cache = data:copy()
				Network:set_receiver(NETWORK_SLAVE_RECEIVER, self)
			end
			data:set_parameter_block(self._data_cache:parameter_block(...), ...)
		else
			if not self._peer then
				Network:set_receiver(NETWORK_MASTER_RECEIVER, self)
			end
			self._peer = assert(managers.slave:peer())
			self:send(self._block_nr, block, {
				...
			}, self._peer)
		end
		self._block_nr = self._block_nr + 1
	end
	return false
end
function EnvironmentNetworkFeeder:end_feed(nr)
	self._block_nr = nr == 1 and 1 or self._block_nr
end
function EnvironmentNetworkFeeder:env_data_block_sync(data, id, rpc)
	local block, params = assert(loadstring("return " .. data))()
	self._data_cache:set_parameter_block(block, unpack(params))
	rpc:env_data_verify_block(id)
end
function EnvironmentNetworkFeeder:env_data_verify_block(id)
	self._verification_table[tostring(id)] = true
end
function EnvironmentNetworkFeeder:send(id, block, params, peer)
	local id_str = tostring(id)
	local ver = self._verification_table[id_str]
	if ver == nil or ver == true then
		self._verification_table[id_str] = false
		peer:env_data_block_sync(self:pack_data(block, params), id)
	end
end
function EnvironmentNetworkFeeder:pack_data(block, params)
	assert(table.size(block) > 0 and table.size(params) > 0)
	local str = ""
	local bstr, pstr
	for k, v in pairs(block) do
		bstr = bstr and bstr .. "," or "{"
		bstr = string.format("%s%s=", bstr, string.match(k, "[%w_]+"))
		bstr = type(v) == "string" and string.format("%s'%s'", bstr, v) or bstr .. tostring(v)
	end
	str = str .. bstr .. "},"
	for _, v in pairs(params) do
		pstr = pstr and pstr .. "," or "{"
		pstr = string.format("%s'%s'", pstr, v)
	end
	return str .. pstr .. "}"
end
