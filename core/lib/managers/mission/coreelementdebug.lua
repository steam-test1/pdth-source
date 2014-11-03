core:module("CoreElementDebug")
core:import("CoreMissionScriptElement")
ElementDebug = ElementDebug or class(CoreMissionScriptElement.MissionScriptElement)
function ElementDebug:init(...)
	ElementDebug.super.init(self, ...)
end
function ElementDebug:client_on_executed(...)
	self:on_executed(...)
end
function ElementDebug:on_executed(instigator)
	if not self._values.enabled then
		return
	end
	local prefix = "<debug>    "
	managers.mission:add_fading_debug_output(prefix .. self._values.debug_string)
	ElementDebug.super.on_executed(self, instigator)
end
