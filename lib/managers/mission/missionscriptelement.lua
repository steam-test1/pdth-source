core:import("CoreMissionScriptElement")
core:import("CoreClass")
MissionScriptElement = MissionScriptElement or class(CoreMissionScriptElement.MissionScriptElement)
function MissionScriptElement:init(...)
	MissionScriptElement.super.init(self, ...)
end
function MissionScriptElement:client_on_executed()
end
function MissionScriptElement:on_executed(...)
	if Network:is_client() then
		return
	end
	MissionScriptElement.super.on_executed(self, ...)
end
CoreClass.override_class(CoreMissionScriptElement.MissionScriptElement, MissionScriptElement)
