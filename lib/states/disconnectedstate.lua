require("lib/states/GameState")
DisconnectedState = DisconnectedState or class(MissionEndState)
function DisconnectedState:init(game_state_machine, setup)
	DisconnectedState.super.init(self, "disconnected", game_state_machine, setup)
end
function DisconnectedState:at_enter(...)
	self._success = false
	DisconnectedState.super.at_enter(self, ...)
	managers.network.voice_chat:destroy_voice(true)
	self:_create_disconnected_dialog()
end
function DisconnectedState:_create_disconnected_dialog()
	MenuMainState._create_disconnected_dialog(self)
end
function DisconnectedState:on_server_left_ok_pressed()
end
function DisconnectedState:on_disconnected()
end
function DisconnectedState:on_server_left()
end
