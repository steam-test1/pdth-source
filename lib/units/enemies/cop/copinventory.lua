CopInventory = CopInventory or class(PlayerInventory)
CopInventory._index_to_weapon_list = HuskPlayerInventory._index_to_weapon_list
function CopInventory:init(unit)
	CopInventory.super.init(self, unit)
	self._unit = unit
	self._available_selections = {}
	self._equipped_selection = nil
	self._latest_addition = nil
	self._selected_primary = nil
	self._use_data_alias = "npc"
	self._align_places = {}
	self._align_places.right_hand = {
		obj3d_name = Idstring("a_weapon_right_front"),
		on_body = true
	}
	self._align_places.back = {
		obj3d_name = Idstring("Hips"),
		on_body = true
	}
	self._listener_id = "CopInventory" .. tostring(unit:key())
end
function CopInventory:add_unit_by_name(new_unit_name, equip)
	local new_unit = World:spawn_unit(new_unit_name, Vector3(), Rotation())
	self:_chk_spawn_shield(new_unit)
	local setup_data = {}
	setup_data.user_unit = self._unit
	setup_data.ignore_units = {
		self._unit,
		new_unit,
		self._shield_unit
	}
	setup_data.expend_ammo = false
	setup_data.hit_slotmask = managers.slot:get_mask("bullet_impact_targets_no_police")
	setup_data.hit_player = true
	setup_data.user_sound_variant = tweak_data.character[self._unit:base()._tweak_table].weapon_voice
	new_unit:base():setup(setup_data)
	self:add_unit(new_unit, equip)
end
function CopInventory:_chk_spawn_shield(weapon_unit)
	if not alive(self._shield_unit) and weapon_unit:base().name_id == "shield_pistol_npc" then
		local align_name = Idstring("a_weapon_left_front")
		local align_obj = self._unit:get_object(align_name)
		self._shield_unit = World:spawn_unit(Idstring("units/weapons/shield/shield"), align_obj:position(), align_obj:rotation())
		self._unit:link(align_name, self._shield_unit, self._shield_unit:orientation_object():name())
	end
end
function CopInventory:add_unit(new_unit, equip)
	CopInventory.super.add_unit(self, new_unit, equip)
end
function CopInventory:get_sync_data(sync_data)
	MPPlayerInventory.get_sync_data(self, sync_data)
end
function CopInventory:get_weapon()
	local selection = self._available_selections[self._equipped_selection]
	local unit = selection and selection.unit
	return unit
end
function CopInventory:drop_weapon()
	local selection = self._available_selections[self._equipped_selection]
	local unit = selection and selection.unit
	if unit and unit:damage() then
		unit:unlink()
		unit:damage():run_sequence_simple("enable_body")
		self:_call_listeners("unequip")
		managers.game_play_central:weapon_dropped(unit)
	end
end
function CopInventory:drop_shield()
	if alive(self._shield_unit) then
		self._shield_unit:unlink()
		if self._shield_unit:damage() then
			self._shield_unit:damage():run_sequence_simple("enable_body")
		end
	end
end
function CopInventory:destroy_all_items()
	CopInventory.super.destroy_all_items(self)
	if alive(self._shield_unit) then
		self._shield_unit:set_slot(0)
		self._shield_unit = nil
	end
end
