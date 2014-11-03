core:import("CoreMissionScriptElement")
ElementEnemyPreferedAdd = ElementEnemyPreferedAdd or class(CoreMissionScriptElement.MissionScriptElement)
function ElementEnemyPreferedAdd:init(...)
	ElementEnemyPreferedAdd.super.init(self, ...)
	self._group_data = {}
	self._group_data.spawn_points = {}
end
function ElementEnemyPreferedAdd:on_script_activated()
	for _, id in ipairs(self._values.elements) do
		local element = self:get_mission_element(id)
		local enemy_name = element:enemy_name()
		local position = element:value("position")
		local rotation = element:value("rotation")
		table.insert(self._group_data.spawn_points, element)
	end
end
function ElementEnemyPreferedAdd:add()
	managers.groupai:state():add_preferred_spawn_points(self._id, self._group_data.spawn_points)
end
function ElementEnemyPreferedAdd:remove()
	managers.groupai:state():remove_preferred_spawn_points(self._id)
end
function ElementEnemyPreferedAdd:on_executed(instigator)
	if not self._values.enabled then
		return
	end
	self:add()
	ElementEnemyPreferedAdd.super.on_executed(self, instigator)
end
ElementEnemyPreferedRemove = ElementEnemyPreferedRemove or class(CoreMissionScriptElement.MissionScriptElement)
function ElementEnemyPreferedRemove:init(...)
	ElementEnemyPreferedRemove.super.init(self, ...)
end
function ElementEnemyPreferedRemove:on_executed(instigator)
	if not self._values.enabled then
		return
	end
	for _, id in ipairs(self._values.elements) do
		local element = self:get_mission_element(id)
		if element then
			element:remove()
		end
	end
	ElementEnemyPreferedRemove.super.on_executed(self, instigator)
end
