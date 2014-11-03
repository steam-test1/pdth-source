CivilianDamage = CivilianDamage or class(CopDamage)
function CivilianDamage:init(unit)
	CivilianDamage.super.init(self, unit)
	self._pickup = nil
end
function CivilianDamage:die(variant)
	self._unit:base():set_slot(self._unit, 17)
	self:drop_pickup()
	if self._unit:unit_data().mission_element then
		self._unit:unit_data().mission_element:event("death", self._unit)
	end
	variant = variant or "bullet"
	self._health = 0
	self._health_ratio = 0
	self._dead = true
	self:set_mover_collision_state(false)
end
function CivilianDamage:_on_damage_received(damage_info)
	self:_call_listeners(damage_info)
	if damage_info.result.type == "death" then
		self:_unregister_from_enemy_manager(damage_info)
		if Network:is_client() then
			self._unit:interaction():set_active(false, false)
		end
	end
end
function CivilianDamage:print(...)
	cat_print("civ_damage", ...)
end
function CivilianDamage:_unregister_from_enemy_manager(damage_info)
	managers.enemy:on_civilian_died(self._unit, damage_info)
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
