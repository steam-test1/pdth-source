SentryGunBase = SentryGunBase or class(UnitBase)
function SentryGunBase:init(unit)
	SentryGunBase.super.init(self, unit, false)
	self._unit = unit
	self._unit:sound_source():post_event("ammo_bag_drop")
end
function SentryGunBase:post_init()
	managers.groupai:state():register_criminal(self._unit)
	if Network:is_client() then
		self._unit:brain():set_active(true)
	end
end
function SentryGunBase.spawn(pos, rot, ammo_upgrade_lvl, armor_upgrade_lvl)
	local attached_data = SentryGunBase._attach(pos, rot)
	if not attached_data then
		return
	end
	local unit = World:spawn_unit(Idstring("units/equipment/sentry_gun/sentry_gun"), pos, rot)
	unit:base():setup(ammo_upgrade_lvl, armor_upgrade_lvl, attached_data)
	unit:brain():set_active(true)
	SentryGunBase.deployed = (SentryGunBase.deployed or 0) + 1
	if SentryGunBase.deployed >= 4 then
		managers.challenges:set_flag("sentry_gun_resources")
	end
	return unit
end
function SentryGunBase:get_name_id()
	return "sentry_gun"
end
function SentryGunBase:set_server_information(peer_id)
	self._server_information = {owner_peer_id = peer_id}
	managers.network:game():member(peer_id):peer():set_used_deployable(true)
end
function SentryGunBase:server_information()
	return self._server_information
end
function SentryGunBase:setup(ammo_upgrade_lvl, armor_upgrade_lvl, attached_data)
	self._attached_data = attached_data
	local ammo_amount = tweak_data.upgrades.sentry_gun_base_ammo + managers.player:upgrade_value_by_level("sentry_gun", "ammo_increase", ammo_upgrade_lvl)
	self._unit:weapon():set_ammo(ammo_amount)
	local armor_amount = tweak_data.upgrades.sentry_gun_base_armor + managers.player:upgrade_value_by_level("sentry_gun", "armor_increase", armor_upgrade_lvl)
	self._unit:character_damage():set_health(armor_amount)
	self._unit:sound_source():post_event("turret_place")
	self._unit:set_extension_update_enabled(Idstring("base"), true)
	return true
end
function SentryGunBase:update(unit, t, dt)
	self:_check_body()
end
function SentryGunBase:_check_body()
	if self._attached_data.index == 1 then
		if not self._attached_data.body:enabled() then
			self._attached_data = self._attach(nil, nil, self._unit)
			if not self._attached_data then
				self:remove()
				return
			end
		end
	elseif self._attached_data.index == 2 then
		if not mrotation.equal(self._attached_data.rotation, self._attached_data.body:rotation()) then
			self._attached_data = self._attach(nil, nil, self._unit)
			if not self._attached_data then
				self:remove()
				return
			end
		end
	elseif self._attached_data.index == 3 and mvector3.not_equal(self._attached_data.position, self._attached_data.body:position()) then
		self._attached_data = self._attach(nil, nil, self._unit)
		if not self._attached_data then
			self:remove()
			return
		end
	end
	self._attached_data.index = (self._attached_data.index < self._attached_data.max_index and self._attached_data.index or 0) + 1
end
function SentryGunBase:remove()
	self._removed = true
	self._unit:set_slot(0)
end
function SentryGunBase._attach(pos, rot, sentrygun_unit)
	pos = pos or sentrygun_unit:position()
	rot = rot or sentrygun_unit:rotation()
	local from_pos = pos + rot:z() * 10
	local to_pos = pos + rot:z() * -10
	local ray
	if sentrygun_unit then
		ray = sentrygun_unit:raycast("ray", from_pos, to_pos, "slot_mask", managers.slot:get_mask("world_geometry"))
	else
		ray = World:raycast("ray", from_pos, to_pos, "slot_mask", managers.slot:get_mask("world_geometry"))
	end
	if ray then
		local attached_data = {
			body = ray.body,
			position = ray.body:position(),
			rotation = ray.body:rotation(),
			index = 1,
			max_index = 3
		}
		return attached_data
	end
end
function SentryGunBase:set_visibility_state(stage)
	local state = stage and true
	if self._visibility_state ~= state then
		self._unit:set_visible(state)
		self._visibility_state = state
	end
	self._lod_stage = stage
end
function SentryGunBase:weapon_tweak_data()
	return tweak_data.weapon[self._unit:weapon()._name_id]
end
function SentryGunBase:on_death()
	self._unit:set_extension_update_enabled(Idstring("base"), false)
end
function SentryGunBase:pre_destroy()
	SentryGunBase.super.pre_destroy(self, self._unit)
	managers.groupai:state():unregister_criminal(self._unit)
	self._removed = true
end
