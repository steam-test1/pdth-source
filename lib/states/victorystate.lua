require("lib/states/GameState")
VictoryState = VictoryState or class(MissionEndState)
function VictoryState:init(game_state_machine, setup)
	VictoryState.super.init(self, "victoryscreen", game_state_machine, setup)
end
function VictoryState:at_enter(...)
	self._success = true
	VictoryState.super.at_enter(self, ...)
end
function VictoryState:_shut_down_network()
	if managers.dlc:is_trial() then
		VictoryState.super._shut_down_network(self)
	end
end
function VictoryState:_load_start_menu()
	if managers.dlc:is_trial() then
		Global.open_trial_buy = true
		setup:load_start_menu()
	end
end
function VictoryState:_set_continue_button_text()
	local text = string.upper(managers.localization:text((Network:is_server() or managers.dlc:is_trial()) and "debug_mission_end_continue" or "victory_client_waiting_for_server", {
		CONTINUE = managers.localization:btn_macro("continue")
	}))
	print("VictoryState", text)
	managers.hud:script(self.GUI_SAFERECT):set_continue_button_text(text)
end
function VictoryState:_continue()
	if Network:is_server() or managers.dlc:is_trial() then
		self:continue()
	end
end
function VictoryState:continue()
	if managers.hud:visible("guis/stats_screen/stats_screen_saferect") then
		return
	end
	if managers.system_menu:is_active() then
		return
	end
	if not self._completion_bonus_done then
		return
	end
	if Network:is_server() and not managers.dlc:is_trial() then
		managers.network:session():send_to_peers_loaded("enter_ingame_lobby_menu")
	end
	if managers.dlc:is_trial() then
		self:gsm():change_state_by_name("empty")
		return
	end
	if self._old_state then
		self:_clear_controller()
		self:gsm():change_state_by_name("ingame_lobby_menu")
	else
		Application:error("Trying to continue from victory screen, but I have no state to goto")
	end
end
