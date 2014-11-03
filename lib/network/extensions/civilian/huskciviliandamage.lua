HuskCivilianDamage = HuskCivilianDamage or class(HuskCopDamage)
HuskCivilianDamage._HEALTH_INIT = CivilianDamage._HEALTH_INIT
function HuskCivilianDamage:_on_damage_received(damage_info)
	CivilianDamage._on_damage_received(self, damage_info)
end
function HuskCivilianDamage:_unregister_from_enemy_manager(damage_info)
	CivilianDamage._unregister_from_enemy_manager(self, damage_info)
end
function CivilianDamage:damage_bullet(attack_data)
	attack_data.damage = 10
	return CopDamage.damage_bullet(self, attack_data)
end
function CivilianDamage:damage_explosion(attack_data)
	attack_data.damage = 10
	return CopDamage.damage_explosion(self, attack_data)
end
function CivilianDamage:damage_melee(attack_data)
	attack_data.damage = 10
	return CopDamage.damage_melee(self, attack_data)
end
