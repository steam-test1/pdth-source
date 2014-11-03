HuskPlayerDamage = HuskPlayerDamage or class()
function HuskPlayerDamage:init(unit)
	self._unit = unit
	self._spine2_obj = unit:get_object(Idstring("Spine2"))
	self._listener_holder = EventListenerHolder:new()
end
function HuskPlayerDamage:_call_listeners(damage_info)
	CopDamage._call_listeners(self, damage_info)
end
function HuskPlayerDamage:add_listener(...)
	CopDamage.add_listener(self, ...)
end
function HuskPlayerDamage:remove_listener(key)
	CopDamage.remove_listener(self, key)
end
function HuskPlayerDamage:sync_damage_bullet(attacker_unit, damage, i_body, height_offset)
	if not attacker_unit or not (attacker_unit:movement():m_pos() - self._unit:movement():m_pos()) then
	end
	local attack_data = {
		attacker_unit = attacker_unit,
		attack_dir = Vector3(1, 0, 0),
		pos = mvector3.copy(self._unit:movement():m_head_pos()),
		result = {type = "hurt", variant = "bullet"}
	}
	self:_call_listeners(attack_data)
end
function HuskPlayerDamage:shoot_pos_mid(m_pos)
	self._spine2_obj:m_position(m_pos)
end
function HuskPlayerDamage:set_last_down_time(down_time)
	self._last_down_time = down_time
end
function HuskPlayerDamage:down_time()
	return self._last_down_time
end
function HuskPlayerDamage:arrested()
	return self._unit:movement():current_state_name() == "arrested"
end
function HuskPlayerDamage:incapacitated()
	return self._unit:movement():current_state_name() == "incapacitated"
end
function HuskPlayerDamage:dead()
end
