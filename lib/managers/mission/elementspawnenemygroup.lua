core:import("CoreMissionScriptElement")
ElementSpawnEnemyGroup = ElementSpawnEnemyGroup or class(CoreMissionScriptElement.MissionScriptElement)
function ElementSpawnEnemyGroup:init(...)
	ElementSpawnEnemyGroup.super.init(self, ...)
	self._group_data = {}
	self._group_data.amount = self._values.amount
	self._group_data.random = self._values.random
	self._group_data.ignore_disabled = self._values.ignore_disabled
	self._group_data.spawn_points = {}
	self._unused_randoms = {}
end
function ElementSpawnEnemyGroup:on_script_activated()
	for i, id in ipairs(self._values.elements) do
		local element = self:get_mission_element(id)
		table.insert(self._unused_randoms, i)
		table.insert(self._group_data.spawn_points, element)
	end
end
function ElementSpawnEnemyGroup:add_event_callback(name, callback)
	for _, id in ipairs(self._values.elements) do
		local element = self:get_mission_element(id)
		element:add_event_callback(name, callback)
	end
end
function ElementSpawnEnemyGroup:_check_spawn_points()
	self._spawn_points = {}
	if not self._group_data.ignore_disabled then
		self._spawn_points = self._group_data.spawn_points
		return
	end
	self._unused_randoms = {}
	local i = 1
	for _, element in pairs(self._group_data.spawn_points) do
		if element:enabled() then
			table.insert(self._unused_randoms, i)
			table.insert(self._spawn_points, element)
			i = i + 1
		end
	end
end
function ElementSpawnEnemyGroup:on_executed(instigator)
	if not self._values.enabled then
		return
	end
	self:_check_spawn_points()
	if #self._spawn_points > 0 then
		for i = 1, self._group_data.amount do
			local element = self._spawn_points[self:_get_spawn_point(i)]
			element:produce()
		end
	end
	ElementSpawnEnemyGroup.super.on_executed(self, instigator)
end
function ElementSpawnEnemyGroup:_get_spawn_point(i)
	if self._group_data.random then
		if #self._unused_randoms == 0 then
			for i = 1, #self._spawn_points do
				table.insert(self._unused_randoms, i)
			end
		end
		local rand = math.random(#self._unused_randoms)
		return table.remove(self._unused_randoms, rand)
	end
	return 1 + math.mod(i, #self._spawn_points)
end
function ElementSpawnEnemyGroup:units()
	local all_units = {}
	for _, element in ipairs(self._group_data.spawn_points) do
		local element_units = element:units()
		for _, unit in ipairs(element_units) do
			table.insert(all_units, unit)
		end
	end
	return all_units
end
function ElementSpawnEnemyGroup:unspawn_all_units()
	for _, element in ipairs(self._group_data.spawn_points) do
		element:unspawn_all_units()
	end
end
function ElementSpawnEnemyGroup:execute_on_all_units(func)
	for _, element in ipairs(self._group_data.spawn_points) do
		element:execute_on_all_units(func)
	end
end
