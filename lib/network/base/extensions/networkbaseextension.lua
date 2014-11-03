NetworkBaseExtension = NetworkBaseExtension or class()
function NetworkBaseExtension:init(unit)
	self._unit = unit
end
function NetworkBaseExtension:send(func, ...)
	if managers.network:session() then
		managers.network:session():send_to_peers_synched(func, self._unit, ...)
	end
end
function NetworkBaseExtension:send_to_host(func, ...)
	if managers.network:session() then
		managers.network:session():send_to_host(func, self._unit, ...)
	end
end
function NetworkBaseExtension:send_to_unit(params)
	if managers.network:game() then
		local member = managers.network:game():member_from_unit(self._unit)
		if not member then
			return
		end
		managers.network:session():send_to_peer(member:peer(), unpack(params))
	end
end
function NetworkBaseExtension:member()
	return managers.network:game():member_from_unit(self._unit)
end
function NetworkBaseExtension:peer()
	if managers.network:game() then
		local member = managers.network:game():member_from_unit(self._unit)
		return member and member:peer()
	end
end
