SentryGunDamage = SentryGunDamage or class()
function SentryGunDamage:init(unit)
	self._unit = unit
	self._ext_movement = unit:movement()
	unit:base():post_init()
	unit:brain():post_init()
	unit:movement():post_init()
	self._shield_body_name = Idstring("shield")
	self._health_sync_resolution = 0.2
	if Network:is_server() then
		self._health = 1
		self._health_max = self._health
		self._health_sync = 1
	else
		self._health_ratio = 1
	end
end
function SentryGunDamage:set_health(amount)
	self._health = amount
	self._health_max = math.max(self._health_max, amount)
end
function SentryGunDamage:sync_health(health_ratio)
	self._health_ratio = health_ratio * self._health_sync_resolution * 100
	if health_ratio == 0 then
		self:die()
	end
end
function SentryGunDamage:shoot_pos_mid(m_pos)
	mvector3.set(m_pos, self._ext_movement:m_head_pos())
end
function SentryGunDamage:damage_bullet(attack_data)
	if self._dead or self._invulnerable or PlayerDamage:_look_for_friendly_fire(attack_data.attacker_unit) then
		return
	end
	local hit_shield = attack_data.col_ray.body and attack_data.col_ray.body:name() == self._shield_body_name
	local dmg_adjusted = attack_data.damage * (hit_shield and tweak_data.weapon.sentry_gun.SHIELD_DMG_MUL or 1)
	if dmg_adjusted >= self._health then
		self:die()
	else
		self._health = self._health - dmg_adjusted
	end
	local health_percent = self._health / self._health_max
	if health_percent == 0 or math.abs(health_percent - self._health_sync) >= self._health_sync_resolution then
		self._health_sync = health_percent
		self._unit:network():send("sentrygun_health", math.ceil(health_percent / self._health_sync_resolution))
	end
end
function SentryGunDamage:dead()
	return self._dead
end
function SentryGunDamage:health_ratio()
	return self._health / HEALTH_MAX
end
function SentryGunDamage:focus_delay_mul()
	return 1
end
function SentryGunDamage:die()
	self._health = 0
	self._dead = true
	self._unit:set_slot(26)
	self._unit:brain():set_active(false)
	self._unit:movement():set_active(false)
	self._unit:base():on_death()
	managers.groupai:state():on_criminal_neutralized(self._unit)
	self._unit:sound_source():post_event("turret_breakdown")
	self._unit:damage():run_sequence_simple("broken")
end
function SentryGunDamage:save(save_data)
	local my_save_data = {}
	if self._health_sync then
		my_save_data.health = math.ceil(self._health_sync / self._health_sync_resolution)
	end
	if next(my_save_data) then
		save_data.char_damage = my_save_data
	end
end
function SentryGunDamage:load(save_data)
	if not save_data or not save_data.char_damage then
		return
	end
	if save_data.char_damage.health then
		self:sync_health(save_data.char_damage.health)
	end
end
function SentryGunDamage:destroy(unit)
	unit:brain():pre_destroy()
	unit:movement():pre_destroy()
	unit:base():pre_destroy()
end
