core:module("CoreElementRandom")
core:import("CoreMissionScriptElement")
core:import("CoreTable")
ElementRandom = ElementRandom or class(CoreMissionScriptElement.MissionScriptElement)
function ElementRandom:init(...)
	ElementRandom.super.init(self, ...)
	self._original_on_executed = CoreTable.clone(self._values.on_executed)
end
function ElementRandom:client_on_executed(...)
end
function ElementRandom:on_executed(instigator)
	if not self._values.enabled then
		return
	end
	self._unused_randoms = {}
	for i, element_data in ipairs(self._original_on_executed) do
		if not self._values.ignore_disabled or self._values.ignore_disabled and self:get_mission_element(element_data.id):enabled() then
			table.insert(self._unused_randoms, i)
		end
	end
	self._values.on_executed = {}
	for i = 1, math.min(self._values.amount or 1, #self._original_on_executed) do
		table.insert(self._values.on_executed, self._original_on_executed[self:_get_random_elements()])
	end
	ElementRandom.super.on_executed(self, instigator)
end
function ElementRandom:_get_random_elements()
	local t = {}
	local rand = math.random(#self._unused_randoms)
	return table.remove(self._unused_randoms, rand)
end
