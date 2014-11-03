require("lib/states/GameState")
IngameIncapacitatedState = IngameIncapacitatedState or class(IngamePlayerBaseState)
function IngameIncapacitatedState:init(game_state_machine)
	IngameIncapacitatedState.super.init(self, "ingame_incapacitated", game_state_machine)
end
function IngameIncapacitatedState:update(t, dt)
	local player = managers.player:player_unit()
	if not alive(player) then
		return
	end
	if player:character_damage():update_incapacitated(t, dt) then
		managers.statistics:downed({death = true})
		IngameFatalState.client_died()
		game_state_machine:change_state_by_name("ingame_waiting_for_respawn")
		player:character_damage():set_invulnerable(true)
		player:character_damage():set_health(0)
		player:base():_unregister()
		player:base():set_slot(player, 0)
	end
end
function IngameIncapacitatedState:at_enter()
	local players = managers.player:players()
	for k, player in ipairs(players) do
		local vp = player:camera():viewport()
		if vp then
			vp:set_active(true)
		else
			Application:error("No viewport for player " .. tostring(k))
		end
	end
	managers.statistics:downed({incapacitated = true})
	local player = managers.player:player_unit()
	if player then
		player:base():set_enabled(true)
	end
	managers.hud:show(PlayerBase.XP_HUD)
	managers.hud:show(PlayerBase.PLAYER_INFO_HUD)
	managers.hud:show(PlayerBase.PLAYER_INFO_HUD_FULLSCREEN)
	managers.hud:show(PlayerBase.PLAYER_DOWNED_HUD)
end
function IngameIncapacitatedState:at_exit()
	local player = managers.player:player_unit()
	if player then
		player:base():set_enabled(false)
	end
	managers.hud:hide(PlayerBase.XP_HUD)
	managers.hud:hide(PlayerBase.PLAYER_INFO_HUD)
	managers.hud:hide(PlayerBase.PLAYER_INFO_HUD_FULLSCREEN)
	managers.hud:hide(PlayerBase.PLAYER_DOWNED_HUD)
end
function IngameIncapacitatedState:on_server_left()
	IngameCleanState.on_server_left(self)
end
function IngameIncapacitatedState:on_kicked()
	IngameCleanState.on_kicked(self)
end
function IngameIncapacitatedState:on_disconnected()
	IngameCleanState.on_disconnected(self)
end
