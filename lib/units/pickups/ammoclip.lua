AmmoClip = AmmoClip or class(Pickup)
function AmmoClip:init(unit)
	AmmoClip.super.init(self, unit)
	self._ammo_type = ""
end
function AmmoClip:_pickup(unit)
	if self._picked_up then
		return
	end
	local inventory = unit:inventory()
	if not unit:character_damage():dead() and inventory then
		local picked_up = false
		for _, weapon in pairs(inventory:available_selections()) do
			picked_up = weapon.unit:base():add_ammo() or picked_up
		end
		if picked_up then
			self._picked_up = true
			if Network:is_client() then
				managers.network:session():send_to_host("sync_pickup", self._unit)
			end
			unit:sound():sync_play("pickup_ammo")
			self:consume()
			return true
		end
	end
	return false
end
