core:import("CoreMissionScriptElement")
ElementFilter = ElementFilter or class(CoreMissionScriptElement.MissionScriptElement)
function ElementFilter:init(...)
	ElementFilter.super.init(self, ...)
end
function ElementFilter:client_on_executed(...)
	self:on_executed(...)
end
function ElementFilter:on_executed(instigator)
	if not self._values.enabled then
		return
	end
	if not self:_check_platform() then
		return
	end
	if not self:_check_difficulty() then
		return
	end
	if not self:_check_players() then
		return
	end
	if not self:_check_mode() then
		return
	end
	ElementFilter.super.on_executed(self, instigator)
end
local win32 = Idstring("WIN32")
local ps3 = Idstring("PS3")
function ElementFilter:_check_platform()
	local platform = Global.running_simulation and Idstring(managers.editor:mission_platform())
	platform = platform or SystemInfo:platform()
	if self._values.platform_win32 and platform == win32 then
		return true
	end
	if self._values.platform_ps3 and platform == ps3 then
		return true
	end
	return false
end
function ElementFilter:_check_difficulty()
	local diff = Global.game_settings and Global.game_settings.difficulty or "hard"
	if self._values.difficulty_easy and diff == "easy" then
		return true
	end
	if self._values.difficulty_normal and diff == "normal" then
		return true
	end
	if self._values.difficulty_hard and diff == "hard" then
		return true
	end
	if self._values.difficulty_overkill and diff == "overkill" then
		return true
	end
	if self._values.difficulty_overkill_145 and diff == "overkill_145" then
		return true
	end
	return false
end
function ElementFilter:_check_players()
	local players = Global.running_simulation and managers.editor:mission_player()
	players = players or managers.network:game():amount_of_members()
	if self._values.player_1 and players == 1 then
		return true
	end
	if self._values.player_2 and players == 2 then
		return true
	end
	if self._values.player_3 and players == 3 then
		return true
	end
	if self._values.player_4 and players == 4 then
		return true
	end
	return false
end
function ElementFilter:_check_mode()
	if self._values.mode_control == nil or self._values.mode_assault == nil then
		return true
	end
	if managers.groupai:state():get_assault_mode() and self._values.mode_assault then
		return true
	end
	if not managers.groupai:state():get_assault_mode() and self._values.mode_control then
		return true
	end
	return false
end
