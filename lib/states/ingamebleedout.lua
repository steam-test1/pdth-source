require("lib/states/GameState")
IngameBleedOutState = IngameBleedOutState or class(IngamePlayerBaseState)
function IngameBleedOutState:init(game_state_machine)
	IngameBleedOutState.super.init(self, "ingame_bleed_out", game_state_machine)
end
function IngameBleedOutState:update(t, dt)
	local player = managers.player:player_unit()
	if not alive(player) then
		return
	end
	if player:movement():nav_tracker() and player:character_damage():update_downed(t, dt) then
		managers.statistics:downed({death = true})
		IngameFatalState.client_died()
		player:base():set_enabled(false)
		game_state_machine:change_state_by_name("ingame_waiting_for_respawn")
		player:character_damage():set_invulnerable(true)
		player:character_damage():set_health(0)
		player:base():_unregister()
		player:base():set_slot(player, 0)
	end
end
function IngameBleedOutState:at_enter()
	local players = managers.player:players()
	for k, player in ipairs(players) do
		local vp = player:camera():viewport()
		if vp then
			vp:set_active(true)
		else
			Application:error("No viewport for player " .. tostring(k))
		end
	end
	managers.statistics:downed({bleed_out = true})
	local player = managers.player:player_unit()
	if player then
		player:base():set_enabled(true)
	end
	managers.hud:show(PlayerBase.XP_HUD)
	managers.hud:show(PlayerBase.PLAYER_INFO_HUD)
	managers.hud:show(PlayerBase.PLAYER_INFO_HUD_FULLSCREEN)
	managers.hud:show(PlayerBase.PLAYER_DOWNED_HUD)
end
function IngameBleedOutState:at_exit()
	managers.challenges:reset("exit_bleed_out")
	local player = managers.player:player_unit()
	if player then
		player:base():set_enabled(false)
	end
	managers.hud:hide(PlayerBase.XP_HUD)
	managers.hud:hide(PlayerBase.PLAYER_INFO_HUD)
	managers.hud:hide(PlayerBase.PLAYER_INFO_HUD_FULLSCREEN)
	managers.hud:hide(PlayerBase.PLAYER_DOWNED_HUD)
end
function IngameBleedOutState:on_server_left()
	IngameCleanState.on_server_left(self)
end
function IngameBleedOutState:on_kicked()
	IngameCleanState.on_kicked(self)
end
function IngameBleedOutState:on_disconnected()
	IngameCleanState.on_disconnected(self)
end
