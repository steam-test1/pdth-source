GrenadeBase = GrenadeBase or class(UnitBase)
function GrenadeBase.spawn(unit_name, pos, rot)
	local unit = World:spawn_unit(Idstring(unit_name), pos, rot)
	return unit
end
function GrenadeBase:init(unit)
	UnitBase.init(self, unit, true)
	self._unit = unit
	self:_setup()
end
function GrenadeBase:_setup()
	self._slotmask = managers.slot:get_mask("trip_mine_targets")
	self._timer = self._init_timer or 3
end
function GrenadeBase:set_active(active)
	self._active = active
	self._unit:set_extension_update_enabled(Idstring("base"), self._active)
end
function GrenadeBase:active()
	return self._active
end
function GrenadeBase:throw(params)
	self._owner = params.owner
	local velocity = params.dir * 1000
	velocity = Vector3(velocity.x, velocity.y, velocity.z + 100)
	local mass = math.max(2 * (1 - math.abs(params.dir.z)), 1)
	self._unit:push_at(mass, velocity, self._unit:position())
end
function GrenadeBase:_bounce(...)
	print("_bounce", ...)
end
function GrenadeBase:update(unit, t, dt)
	if self._timer then
		self._timer = self._timer - dt
		if self._timer <= 0 then
			self._timer = nil
			self:__detonate()
		end
	end
end
function GrenadeBase:detonate()
	if not self._active then
		return
	end
end
function GrenadeBase:__detonate()
	self:_play_sound_and_effects()
	if not self._owner then
		return
	end
	self:_detonate()
end
function GrenadeBase:_detonate()
	print("no detonate function for grenade")
end
function GrenadeBase:_play_sound_and_effects()
	World:effect_manager():spawn({
		effect = Idstring("effects/particles/explosions/explosion_grenade"),
		position = self._unit:position(),
		normal = self._unit:rotation():y()
	})
	self._unit:sound_source():post_event("trip_mine_explode")
end
function GrenadeBase:save(data)
	local state = {}
	state.timer = self._timer
	data.GrenadeBase = state
end
function GrenadeBase:load(data)
	local state = data.GrenadeBase
	self._timer = state.timer
end
function GrenadeBase:destroy()
end
