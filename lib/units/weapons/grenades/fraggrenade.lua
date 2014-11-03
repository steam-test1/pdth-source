FragGrenade = FragGrenade or class(GrenadeBase)
function FragGrenade:init(unit)
	FragGrenade.super.init(self, unit)
end
function FragGrenade:_detonate()
	local units = World:find_units("sphere", self._unit:position(), 400, self._slotmask)
	for _, unit in ipairs(units) do
		local col_ray = {}
		col_ray.ray = unit:position() - self._unit:position():normalized()
		col_ray.position = self._unit:position()
		if unit:character_damage() and unit:character_damage().damage_explosion then
			self:_give_explosion_damage(col_ray, unit, 10)
		end
	end
	self._unit:set_slot(0)
end
function FragGrenade:_play_sound_and_effects()
	World:effect_manager():spawn({
		effect = Idstring("effects/particles/explosions/explosion_grenade"),
		position = self._unit:position(),
		normal = self._unit:rotation():y()
	})
	self._unit:sound_source():post_event("trip_mine_explode")
end
function FragGrenade:_give_explosion_damage(col_ray, unit, damage)
	local action_data = {}
	action_data.variant = "explosion"
	action_data.damage = damage
	action_data.attacker_unit = self._unit
	action_data.col_ray = col_ray
	local defense_data = unit:character_damage():damage_explosion(action_data)
	return defense_data
end
