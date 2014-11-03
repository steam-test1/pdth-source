core:import("CoreMissionScriptElement")
ElementAIRemove = ElementAIRemove or class(CoreMissionScriptElement.MissionScriptElement)
function ElementAIRemove:init(...)
	ElementAIRemove.super.init(self, ...)
end
function ElementAIRemove:on_executed(instigator)
	if not self._values.enabled then
		return
	end
	if self._values.use_instigator then
		instigator:brain():set_active(false)
		instigator:base():set_slot(instigator, 0)
	else
		for _, id in ipairs(self._values.elements) do
			local element = self:get_mission_element(id)
			element:unspawn_all_units()
		end
	end
	ElementAIRemove.super.on_executed(self, instigator)
end
