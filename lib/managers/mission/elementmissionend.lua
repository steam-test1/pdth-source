core:import("CoreMissionScriptElement")
ElementMissionEnd = ElementMissionEnd or class(CoreMissionScriptElement.MissionScriptElement)
function ElementMissionEnd:init(...)
	ElementMissionEnd.super.init(self, ...)
end
function ElementMissionEnd:client_on_executed(...)
end
function ElementMissionEnd:on_executed(instigator)
	if not self._values.enabled then
		return
	end
	if self._values.state ~= "none" then
		if self._values.state == "success" then
			if managers.platform:presence() == "Playing" then
				local num_winners = managers.network:game():amount_of_alive_players() + managers.groupai:state():amount_of_winning_ai_criminals()
				managers.network:session():send_to_peers("mission_ended", true, num_winners)
				game_state_machine:change_state_by_name("victoryscreen", {
					num_winners = num_winners,
					personal_win = alive(managers.player:player_unit())
				})
			end
		elseif self._values.state == "failed" then
			print("No fail state yet")
		end
	elseif Application:editor() then
		managers.editor:output_error("Cant change to state " .. self._values.state .. " in mission end element " .. self._editor_name .. ".")
	end
	ElementMissionEnd.super.on_executed(self, instigator)
end
