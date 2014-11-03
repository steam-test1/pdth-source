EquipmentsTweakData = EquipmentsTweakData or class()
function EquipmentsTweakData:init()
	self.trip_mine = {
		icon = "equipment_trip_mine",
		use_function_name = "use_trip_mine",
		quantity = 2,
		text_id = "debug_trip_mine",
		description_id = "des_trip_mine"
	}
	self.ammo_bag = {
		icon = "equipment_ammo_bag",
		use_function_name = "use_ammo_bag",
		quantity = 1,
		text_id = "debug_ammo_bag",
		description_id = "des_ammo_bag"
	}
	self.doctor_bag = {
		icon = "equipment_doctor_bag",
		use_function_name = "use_doctor_bag",
		quantity = 1,
		text_id = "debug_doctor_bag",
		description_id = "des_doctor_bag"
	}
	self.flash_grenade = {
		icon = "equipment_ammo_bag",
		use_function_name = "use_flash_grenade",
		action_timer = 2
	}
	self.smoke_grenade = {
		icon = "equipment_ammo_bag",
		use_function_name = "use_smoke_grenade",
		action_timer = 2
	}
	self.frag_grenade = {
		icon = "equipment_ammo_bag",
		use_function_name = "use_frag_grenade",
		action_timer = 2
	}
	self.sentry_gun = {
		icon = "equipment_sentry",
		use_function_name = "use_sentry_gun",
		quantity = 1,
		text_id = "debug_sentry_gun",
		description_id = "des_sentry_gun"
	}
	self.specials = {}
	self.specials.revive_kit = {
		text_id = "debug_equipment_revive",
		icon = "interaction_help",
		quantity = 3,
		extra_quantity = {
			equipped_upgrade = "extra_revive_kit",
			category = "extra_revive_kit",
			upgrade = "quantity"
		}
	}
	self.specials.extra_revive_kit = {
		text_id = "debug_equipment_extra_revive_kit",
		icon = "guis/textures/equipment_extra_revive_kit"
	}
	self.specials.cable_tie = {
		text_id = "debug_equipment_cable_tie",
		icon = "equipment_cable_ties",
		quantity = 2,
		extra_quantity = {
			equipped_upgrade = "extra_cable_tie",
			category = "extra_cable_tie",
			upgrade = "quantity"
		}
	}
	self.specials.extra_cable_tie = {
		text_id = "debug_equipment_extra_cable_tie",
		description_id = "des_extra_cable_tie",
		icon = "equipment_extra_cable_ties"
	}
	self.specials.body_armor = {
		text_id = "debug_body_armor",
		description_id = "des_body_armor",
		icon = "equipment_armor"
	}
	self.specials.thick_skin = {
		text_id = "debug_thick_skin",
		description_id = "des_thick_skin",
		icon = "equipment_thick_skin"
	}
	self.specials.bleed_out_increase = {
		text_id = "debug_equipment_bleed_out",
		description_id = "des_bleed_out_increase",
		icon = "equipment_bleed_out"
	}
	self.specials.intimidation = {
		text_id = "debug_equipment_initimidation",
		description_id = "des_intimidation",
		icon = "interaction_intimidate"
	}
	self.specials.extra_start_out_ammo = {
		text_id = "debug_equipment_extra_start_out_ammo",
		description_id = "des_extra_start_out_ammo",
		icon = "equipment_extra_start_out_ammo"
	}
	self.specials.toolset = {
		text_id = "debug_toolset",
		description_id = "des_toolset",
		icon = "equipment_toolset"
	}
	self.specials.bank_manager_key = {
		text_id = "debug_equipment_bank_manager_key",
		icon = "equipment_bank_manager_key",
		action_message = "bank_manager_key_obtained",
		sync_possession = true
	}
	self.specials.chavez_key = {
		text_id = "debug_equipment_chavez_key",
		icon = "equipment_chavez_key",
		action_message = "chavez_key_obtained",
		sync_possession = true
	}
	self.specials.drill = {
		text_id = "debug_equipment_drill",
		icon = "equipment_drill",
		action_message = "drill_obtained",
		sync_possession = true
	}
	self.specials.glass_cutter = {
		text_id = "debug_equipment_glass_cutter",
		icon = "equipment_cutter",
		sync_possession = true
	}
	self.specials.saw = {
		text_id = "debug_equipment_saw",
		icon = "equipment_saw",
		sync_possession = true
	}
	self.specials.money_bag = {
		text_id = "debug_equipment_money_bag",
		icon = "equipment_money_bag"
	}
	self.specials.server = {
		text_id = "debug_equipment_stash_server",
		icon = "equipment_stash_server",
		sync_possession = true
	}
	self.specials.planks = {
		text_id = "debug_equipment_stash_planks",
		icon = "equipment_planks",
		sync_possession = true
	}
	self.specials.gold_bag_equip = {
		text_id = "debug_equipment_gold_bag",
		icon = "equipment_gold",
		sync_possession = true
	}
	self.specials.thermite = {
		text_id = "debug_equipment_thermite",
		icon = "equipment_thermite",
		action_message = "thermite_obtained",
		sync_possession = true
	}
	self.specials.gas = {
		text_id = "debug_equipment_gas",
		icon = "equipment_thermite",
		action_message = "gas_obtained",
		sync_possession = true
	}
	self.specials.c4 = {
		text_id = "debug_equipment_c4",
		icon = "equipment_c4",
		action_message = "c4_obtained",
		quantity = 3,
		sync_possession = true
	}
	self.specials.organs = {
		text_id = "debug_equipment_organs",
		icon = "equipment_thermite",
		action_message = "organs_obtained"
	}
	self.specials.crowbar = {
		text_id = "debug_equipment_crowbar",
		icon = "equipment_crowbar",
		sync_possession = true
	}
	self.specials.blood_sample = {
		text_id = "debug_equipment_blood_sample",
		icon = "equipment_vial",
		sync_possession = true
	}
	self.specials.blood_sample_verified = {
		text_id = "debug_equipment_blood_sample_valid",
		icon = "equipment_vialOK",
		sync_possession = true
	}
	self.specials.gold = {
		text_id = "debug_equipment_gold",
		icon = "equipment_gold",
		player_rule = "no_run"
	}
end
