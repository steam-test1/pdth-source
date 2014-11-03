ChristmasPresentBase = ChristmasPresentBase or class(UnitBase)
function ChristmasPresentBase:init(unit)
	UnitBase.init(self, unit, false)
	self._unit = unit
	if Global.game_settings.single_player then
		Network:detach_unit(self._unit)
		self._unit:set_slot(0)
	end
end
function ChristmasPresentBase:take_money(unit)
	managers.challenges:set_flag("take_christmas_present")
	local params = {}
	params.effect = Idstring("effects/particles/environment/player_snowflakes")
	params.position = Vector3()
	params.rotation = Rotation()
	World:effect_manager():spawn(params)
	managers.hud._sound_source:post_event("jingle_bells")
	Network:detach_unit(self._unit)
	self._unit:set_slot(0)
end
function ChristmasPresentBase:update(unit, t, dt)
end
function ChristmasPresentBase:destroy()
end
