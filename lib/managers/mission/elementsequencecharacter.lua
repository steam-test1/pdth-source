core:import("CoreMissionScriptElement")
ElementSequenceCharacter = ElementSequenceCharacter or class(CoreMissionScriptElement.MissionScriptElement)
function ElementSequenceCharacter:init(...)
	ElementSequenceCharacter.super.init(self, ...)
end
function ElementSequenceCharacter:client_on_executed(...)
end
function ElementSequenceCharacter.sync_function(unit, sequence)
	if alive(unit) and unit:damage() then
		unit:damage():run_sequence_simple(sequence)
	end
end
function ElementSequenceCharacter:on_executed(instigator)
	if not self._values.enabled then
		return
	end
	local function f(unit)
		ElementSequenceCharacter.sync_function(unit, self._values.sequence)
		managers.network:session():send_to_peers_synched("sync_run_sequence_char", unit, self._values.sequence)
	end
	for _, id in ipairs(self._values.elements) do
		local element = self:get_mission_element(id)
		element:execute_on_all_units(f)
	end
	ElementSequenceCharacter.super.on_executed(self, instigator)
end
