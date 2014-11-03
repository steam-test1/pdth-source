PlayerEquipment = PlayerEquipment or class()
function PlayerEquipment:init(unit)
	self._unit = unit
end
function PlayerEquipment:use_trip_mine()
	local from = self._unit:movement():m_head_pos()
	local to = from + self._unit:movement():m_head_rot():y() * 200
	local ray = self._unit:raycast("ray", from, to, "slot_mask", managers.slot:get_mask("trip_mine_placeables"), "ignore_unit", {})
	if ray then
		managers.challenges:count_up("plant_tripmine")
		managers.statistics:use_trip_mine()
		if Network:is_client() then
			managers.network:session():send_to_host("attach_device", ray.position, ray.normal)
		else
			local rot = Rotation(ray.normal, math.UP)
			local unit = TripMineBase.spawn(ray.position, rot)
			unit:base():set_active(true, self._unit)
		end
		return true
	end
	return false
end
function PlayerEquipment:use_ammo_bag()
	if not self._unit:movement():current_state():in_air() then
		local pos = self._unit:movement():m_pos()
		local rot = self._unit:movement():m_head_rot()
		rot = Rotation(rot:yaw(), 0, 0)
		PlayerStandard.say_line(self, "s01x_plu")
		managers.statistics:use_ammo_bag()
		managers.challenges:count_up("deploy_ammobag")
		local ammo_upgrade_lvl = managers.player:upgrade_level("ammo_bag", "ammo_increase")
		if Network:is_client() then
			managers.network:session():send_to_host("place_ammo_bag", pos, rot, ammo_upgrade_lvl)
		else
			local unit = AmmoBagBase.spawn(pos, rot, ammo_upgrade_lvl)
		end
		return true
	end
	return false
end
function PlayerEquipment:use_doctor_bag()
	if not self._unit:movement():current_state():in_air() then
		local pos = self._unit:movement():m_pos()
		local rot = self._unit:movement():m_head_rot()
		rot = Rotation(rot:yaw(), 0, 0)
		PlayerStandard.say_line(self, "s02x_plu")
		managers.statistics:use_doctor_bag()
		local amount_upgrade_lvl = managers.player:upgrade_level("doctor_bag", "amount_increase")
		if Network:is_client() then
			managers.network:session():send_to_host("place_doctor_bag", pos, rot, amount_upgrade_lvl)
		else
			local unit = DoctorBagBase.spawn(pos, rot, amount_upgrade_lvl)
		end
		return true
	end
	return false
end
function PlayerEquipment:use_sentry_gun(selected_index)
	if self._sentrygun_placement_requested then
		return
	end
	if not self._unit:movement():current_state():in_air() then
		local pos = self._unit:movement():m_pos()
		local rot = self._unit:movement():m_head_rot()
		rot = Rotation(rot:yaw(), 0, 0)
		local ammo_upgrade_lvl = managers.player:upgrade_level("sentry_gun", "ammo_increase")
		local armor_upgrade_lvl = managers.player:upgrade_level("sentry_gun", "armor_increase")
		if Network:is_client() then
			managers.network:session():send_to_host("place_sentry_gun", pos, rot, ammo_upgrade_lvl, armor_upgrade_lvl, selected_index, self._unit)
			self._sentrygun_placement_requested = true
			return false
		elseif not SentryGunBase.spawn(pos, rot, ammo_upgrade_lvl, armor_upgrade_lvl) then
			return false
		end
		return true
	end
	return false
end
function PlayerEquipment:use_flash_grenade()
	self._grenade_name = "units/weapons/flash_grenade/flash_grenade"
	return true, "throw_grenade"
end
function PlayerEquipment:use_smoke_grenade()
	self._grenade_name = "units/weapons/smoke_grenade/smoke_grenade"
	return true, "throw_grenade"
end
function PlayerEquipment:use_frag_grenade()
	self._grenade_name = "units/weapons/frag_grenade/frag_grenade"
	return true, "throw_grenade"
end
function PlayerEquipment:throw_flash_grenade()
	if not self._grenade_name then
		Application:error("Tried to throw a grenade with no name")
	end
	local from = self._unit:movement():m_head_pos()
	local to = from + self._unit:movement():m_head_rot():y() * 50 + Vector3(0, 0, 0)
	local unit = GrenadeBase.spawn(self._grenade_name, to, Rotation())
	unit:base():throw({
		dir = self._unit:movement():m_head_rot():y(),
		owner = self._unit
	})
	self._grenade_name = nil
end
function PlayerEquipment:use_duck()
	local soundsource = SoundDevice:create_source("duck")
	soundsource:post_event("footstep_walk")
	return true
end
function PlayerEquipment:from_server_sentry_gun_place_result()
	self._sentrygun_placement_requested = nil
end
