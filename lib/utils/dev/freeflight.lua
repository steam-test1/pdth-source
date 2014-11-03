core:module("FreeFlight")
core:import("CoreFreeFlight")
core:import("CoreClass")
FreeFlight = FreeFlight or class(CoreFreeFlight.FreeFlight)
function FreeFlight:enable(...)
	FreeFlight.super.enable(self, ...)
	self._player_hud_visible = managers.hud and managers.hud:visible(Idstring("guis/player_hud"))
	if self._player_hud_visible then
		managers.hud:hide(Idstring("guis/player_hud"))
		managers.hud:hide(Idstring("guis/player_info_hud_fullscreen"))
		managers.hud:hide(Idstring("guis/player_info_hud"))
		managers.hud:hide(Idstring("guis/experience_hud"))
	end
end
function FreeFlight:disable(...)
	FreeFlight.super.disable(self, ...)
	if self._player_hud_visible then
		managers.hud:show(Idstring("guis/player_hud"))
		managers.hud:show(Idstring("guis/player_info_hud_fullscreen"))
		managers.hud:show(Idstring("guis/player_info_hud"))
		managers.hud:show(Idstring("guis/experience_hud"))
	end
end
function FreeFlight:_pause()
	Application:set_pause(true)
end
function FreeFlight:_unpause()
	Application:set_pause(false)
end
CoreClass.override_class(CoreFreeFlight.FreeFlight, FreeFlight)
