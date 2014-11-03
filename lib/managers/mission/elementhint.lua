core:import("CoreMissionScriptElement")
ElementHint = ElementHint or class(CoreMissionScriptElement.MissionScriptElement)
function ElementHint:init(...)
	ElementHint.super.init(self, ...)
end
function ElementHint:client_on_executed(...)
	self:on_executed(...)
end
function ElementHint:on_executed(instigator)
	if not self._values.enabled then
		return
	end
	if self._values.hint_id ~= "none" then
		managers.hint:show_hint(self._values.hint_id)
	elseif Application:editor() then
		managers.editor:output_error("Cant show hint " .. self._values.hint_id .. " in element " .. self._editor_name .. ".")
	end
	ElementHint.super.on_executed(self, instigator)
end
