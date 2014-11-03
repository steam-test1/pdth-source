DoctorBagBase = DoctorBagBase or class(UnitBase)
function DoctorBagBase.spawn(pos, rot, amount_upgrade_lvl)
	local unit = World:spawn_unit(Idstring("units/equipment/doctor_bag/doctor_bag"), pos, rot)
	managers.network:session():send_to_peers_synched("sync_doctor_bag_setup", unit, amount_upgrade_lvl)
	unit:base():setup(amount_upgrade_lvl)
	return unit
end
function DoctorBagBase:set_server_information(peer_id)
	self._server_information = {owner_peer_id = peer_id}
	managers.network:game():member(peer_id):peer():set_used_deployable(true)
end
function DoctorBagBase:server_information()
	return self._server_information
end
function DoctorBagBase:init(unit)
	UnitBase.init(self, unit, false)
	self._unit = unit
	self._unit:sound_source():post_event("ammo_bag_drop")
end
function DoctorBagBase:sync_setup(amount_upgrade_lvl)
	self:setup(amount_upgrade_lvl)
end
function DoctorBagBase:setup(amount_upgrade_lvl)
	self._amount = tweak_data.upgrades.doctor_bag_base + managers.player:upgrade_value_by_level("doctor_bag", "amount_increase", amount_upgrade_lvl)
	if Network:is_server() then
		local from_pos = self._unit:position() + self._unit:rotation():z() * 10
		local to_pos = self._unit:position() + self._unit:rotation():z() * -10
		local ray = self._unit:raycast("ray", from_pos, to_pos, "slot_mask", managers.slot:get_mask("world_geometry"))
		if ray then
			self._attached_data = {}
			self._attached_data.body = ray.body
			self._attached_data.position = ray.body:position()
			self._attached_data.rotation = ray.body:rotation()
			self._attached_data.index = 1
			self._attached_data.max_index = 3
			self._unit:set_extension_update_enabled(Idstring("base"), true)
		end
	end
end
function DoctorBagBase:update(unit, t, dt)
	self:_check_body()
end
function DoctorBagBase:_check_body()
	if self._attached_data.index == 1 then
		if not self._attached_data.body:enabled() then
			self:_set_empty()
		end
	elseif self._attached_data.index == 2 then
		if not mrotation.equal(self._attached_data.rotation, self._attached_data.body:rotation()) then
			self:_set_empty()
		end
	elseif self._attached_data.index == 3 and mvector3.not_equal(self._attached_data.position, self._attached_data.body:position()) then
		self:_set_empty()
	end
	self._attached_data.index = (self._attached_data.index < self._attached_data.max_index and self._attached_data.index or 0) + 1
end
function DoctorBagBase:take(unit)
	if self._empty then
		return
	end
	local taken = self:_take(unit)
	if taken > 0 then
		unit:sound():play("pickup_ammo")
		managers.network:session():send_to_peers_synched("sync_doctor_bag_taken", self._unit, taken)
	end
	if 0 >= self._amount then
		self:_set_empty()
	end
	return taken > 0
end
function DoctorBagBase:sync_taken(amount)
	self._amount = self._amount - amount
	if self._amount <= 0 then
		self:_set_empty()
	end
end
function DoctorBagBase:_take(unit)
	local taken = 1
	self._amount = self._amount - taken
	unit:character_damage():replenish()
	return taken
end
function DoctorBagBase:_set_empty()
	self._empty = true
	self._unit:set_slot(0)
end
function DoctorBagBase:save(data)
	local state = {}
	state.amount = self._amount
	data.DoctorBagBase = state
end
function DoctorBagBase:load(data)
	local state = data.DoctorBagBase
	self._amount = state.amount
end
function DoctorBagBase:destroy()
end
