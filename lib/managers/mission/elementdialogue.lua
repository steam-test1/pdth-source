core:import("CoreMissionScriptElement")
ElementDialogue = ElementDialogue or class(CoreMissionScriptElement.MissionScriptElement)
function ElementDialogue:init(...)
	ElementDialogue.super.init(self, ...)
end
function ElementDialogue:client_on_executed(...)
	self:on_executed(...)
end
function ElementDialogue:on_executed(instigator)
	if not self._values.enabled then
		return
	end
	if self._values.dialogue ~= "none" then
		managers.dialog:queue_dialog(self._values.dialogue, {
			case = managers.criminals:character_name_by_unit(instigator)
		})
	elseif Application:editor() then
		managers.editor:output_error("Cant start dialogue " .. self._values.dialogue .. " in element " .. self._editor_name .. ".")
	end
	ElementDialogue.super.on_executed(self, instigator)
end
