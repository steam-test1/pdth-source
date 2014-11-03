core:import("CoreMissionScriptElement")
ElementMoney = ElementMoney or class(CoreMissionScriptElement.MissionScriptElement)
function ElementMoney:init(...)
	ElementMoney.super.init(self, ...)
end
function ElementMoney:client_on_executed(...)
	self:on_executed(...)
end
function ElementMoney:on_executed(instigator)
	if not self._values.enabled then
		return
	end
	if self._values.action ~= "none" then
		managers.experience:perform_action(self._values.action)
	elseif Application:editor() then
		managers.editor:output_error("Cant perform money action " .. self._values.action .. " in element " .. self._editor_name .. ".")
	end
	ElementMoney.super.on_executed(self, instigator)
end
