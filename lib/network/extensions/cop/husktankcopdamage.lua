HuskTankCopDamage = HuskTankCopDamage or class(TankCopDamage)
function HuskTankCopDamage:die(variant)
	HuskCopDamage.die(self, variant)
end
