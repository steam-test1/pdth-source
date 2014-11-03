HuskCopDamage = HuskCopDamage or class(CopDamage)
function HuskCopDamage:die(variant)
	self._unit:base():set_slot(self._unit, 17)
	if self._unit:inventory() then
		self._unit:inventory():drop_shield()
	end
	variant = variant or "bullet"
	self._health = 0
	self._health_ratio = 0
	self._dead = true
	self:set_mover_collision_state(false)
end
