require("lib/managers/group_ai_states/GroupAIStateBase")
require("lib/managers/group_ai_states/GroupAIStateEmpty")
require("lib/managers/group_ai_states/GroupAIStateBesiege")
require("lib/managers/group_ai_states/GroupAIStateStreet")
require("lib/managers/group_ai_states/GroupAIStateAirport")
require("lib/managers/group_ai_states/GroupAIStateZombieApocalypse")
GroupAIManager = GroupAIManager or class()
function GroupAIManager:init()
	self:set_state("empty")
end
function GroupAIManager:update(t, dt)
	self._state:update(t, dt)
end
function GroupAIManager:paused_update(t, dt)
	self._state:paused_update(t, dt)
end
function GroupAIManager:set_state(name)
	if name == "empty" then
		self._state = GroupAIStateEmpty:new()
	elseif name == "besiege" then
		self._state = GroupAIStateBesiege:new()
	elseif name == "street" then
		self._state = GroupAIStateStreet:new()
	elseif name == "airport" then
		self._state = GroupAIStateAirport:new()
	elseif name == "zombie_apocalypse" then
		self._state = GroupAIStateZombieApocalypse:new()
	else
		Application:error("[GroupAIManager:set_state] inexistent state name", name)
		return
	end
	self._state_name = name
end
function GroupAIManager:state()
	return self._state
end
function GroupAIManager:state_name()
	return self._state_name
end
function GroupAIManager:state_names()
	return {
		"empty",
		"airport",
		"besiege",
		"street",
		"zombie_apocalypse"
	}
end
function GroupAIManager:on_simulation_started()
	self._state:on_simulation_started()
end
function GroupAIManager:on_simulation_ended()
	self._state:on_simulation_ended()
end
function GroupAIManager:visualization_enabled()
	return self._state._draw_enabled
end
