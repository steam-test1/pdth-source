HuskPlayerInventory = HuskPlayerInventory or class(PlayerInventory)
HuskPlayerInventory._index_to_weapon_list = {
	Idstring("units/weapons/c45_npc/c45_npc"),
	Idstring("units/weapons/beretta92_npc/beretta92_npc"),
	Idstring("units/weapons/raging_bull_npc/raging_bull_npc"),
	Idstring("units/weapons/glock_npc/glock_18_npc"),
	Idstring("units/weapons/m4_rifle_npc/m4_rifle_npc"),
	Idstring("units/weapons/ak47_npc/ak47_npc"),
	Idstring("units/weapons/m14_npc/m14_npc"),
	Idstring("units/weapons/r870_shotgun_npc/r870_shotgun_npc"),
	Idstring("units/weapons/mossberg_npc/mossberg_npc"),
	Idstring("units/weapons/mp5_npc/mp5_npc"),
	Idstring("units/weapons/mac11_npc/mac11_npc"),
	Idstring("units/weapons/hk21_npc/hk21_npc"),
	Idstring("units/weapons/m79_npc/m79_npc"),
	Idstring("units/weapons/shield_pistol_npc/shield_pistol_npc"),
	Idstring("units/weapons/sniper_rifle_npc/sniper_rifle_npc")
}
function HuskPlayerInventory:init(unit)
	HuskPlayerInventory.super.init(self, unit)
	self._align_places.right_hand = {
		obj3d_name = Idstring("a_weapon_right_front"),
		on_body = true
	}
	self._align_places.left_hand = {
		obj3d_name = Idstring("a_weapon_left_front"),
		on_body = true
	}
end
function HuskPlayerInventory:_send_equipped_weapon()
end
function HuskPlayerInventory:synch_equipped_weapon(weap_index)
	local weapon_name = HuskPlayerInventory._index_to_weapon_list[weap_index]
	self:add_unit_by_name(weapon_name, true, true)
end
function HuskPlayerInventory:add_unit_by_name(new_unit_name, equip, instant)
	local new_unit = World:spawn_unit(new_unit_name, Vector3(), Rotation())
	local setup_data = {}
	setup_data.user_unit = self._unit
	setup_data.ignore_units = {
		self._unit,
		new_unit
	}
	setup_data.expend_ammo = false
	setup_data.autoaim = false
	setup_data.alert_AI = false
	setup_data.user_sound_variant = "1"
	new_unit:base():setup(setup_data)
	self:add_unit(new_unit, equip, instant)
end
