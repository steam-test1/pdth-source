GrenadeLauncherBase = GrenadeLauncherBase or class(RaycastWeaponBase)
function GrenadeLauncherBase:init(...)
	GrenadeLauncherBase.super.init(self, ...)
end
function GrenadeLauncherBase:_fire_raycast(user_unit, from_pos, direction)
	local range_mul = managers.player:upgrade_value(self._name_id, "explosion_range_multiplier")
	local range = tweak_data.weapon[self._name_id].EXPLOSION_RANGE * (range_mul == 0 and 1 or range_mul)
	local curve_pow = tweak_data.weapon[self._name_id].DAMAGE_CURVE_POW
	local unit = M79GrenadeBase.spawn("units/weapons/m79/grenade", from_pos, Rotation(direction, math.UP))
	unit:base():launch({
		dir = direction,
		owner = self._unit,
		user = user_unit,
		damage = self._damage,
		range = range,
		curve_pow = curve_pow
	})
	return {}
end
