require("lib/states/GameState")
KickedState = KickedState or class(MissionEndState)
function KickedState:init(game_state_machine, setup)
	KickedState.super.init(self, "kicked", game_state_machine, setup)
end
function KickedState:at_enter(...)
	self._success = false
	KickedState.super.at_enter(self, ...)
	if Network:multiplayer() then
		self:_shut_down_network()
	end
	self:_create_kicked_dialog()
end
function KickedState:_create_kicked_dialog()
	managers.menu:show_peer_kicked_dialog()
end
function KickedState:on_kicked_ok_pressed()
end
