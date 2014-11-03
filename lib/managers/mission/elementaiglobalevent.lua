core:import("CoreMissionScriptElement")
ElementAiGlobalEvent = ElementAiGlobalEvent or class(CoreMissionScriptElement.MissionScriptElement)
function ElementAiGlobalEvent:init(...)
	ElementAiGlobalEvent.super.init(self, ...)
end
function ElementAiGlobalEvent:on_executed(instigator)
	if not self._values.enabled then
		return
	end
	if self._values.event ~= "none" then
		managers.groupai:state():set_wave_mode(self._values.event)
	elseif Application:editor() then
		managers.editor:output_error("Cant perform ai global event " .. self._values.event .. " in element " .. self._editor_name .. ".")
	end
	ElementAiGlobalEvent.super.on_executed(self, instigator)
end
