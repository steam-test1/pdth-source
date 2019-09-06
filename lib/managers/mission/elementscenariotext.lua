core:import("CoreMissionScriptElement")
ElementScenarioText = ElementScenarioText or class(CoreMissionScriptElement.MissionScriptElement)
function ElementScenarioText:init(...)
	ElementScenarioText.super.init(self, ...)
end
function ElementScenarioText:client_on_executed(...)
	self:on_executed(...)
end
function ElementScenarioText:on_executed(instigator)
	if not self._values.enabled then
		return
	end
	managers.hud:show_scenario(managers.localization:text(self._values.text_id))
	ElementScenarioText.super.on_executed(self, instigator)
end
