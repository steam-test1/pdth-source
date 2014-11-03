UpgradesTweakData = UpgradesTweakData or class()
function UpgradesTweakData:init()
	self.values = {}
	self.steps = {}
	self.values.player = {}
	self.values.player.body_armor = {
		1,
		2,
		3,
		4,
		5
	}
	self.values.player.thick_skin = {
		2,
		4,
		6,
		8,
		10
	}
	self.values.player.bleed_out_increase = {
		2,
		4,
		6,
		8,
		10,
		12,
		14,
		16
	}
	self.values.player.intimidation_multiplier = {
		1.08,
		1.16,
		1.24,
		1.32,
		1.4,
		1.48,
		1.56,
		1.64
	}
	self.values.player.extra_ammo_multiplier = {
		1.1,
		1.2,
		1.3,
		1.4,
		1.5
	}
	self.values.player.toolset = {
		0.95,
		0.9,
		0.85,
		0.8
	}
	self.steps.player = {}
	self.steps.player.thick_skin = {
		nil,
		8,
		18,
		27,
		39
	}
	self.steps.player.extra_ammo_multiplier = {
		nil,
		7,
		16,
		24,
		38
	}
	self.steps.player.toolset = {
		nil,
		7,
		16,
		38
	}
	self.values.crew_bonus = {}
	self.values.crew_bonus.welcome_to_the_gang = {1.2}
	self.values.crew_bonus.aggressor = {1.1}
	self.values.crew_bonus.protector = {1.1}
	self.values.crew_bonus.sharpshooters = {0.9}
	self.values.crew_bonus.more_blood_to_bleed = {5}
	self.values.crew_bonus.speed_reloaders = {1.1}
	self.values.crew_bonus.more_ammo = {1.15}
	self.values.crew_bonus.mr_nice_guy = {1.2}
	self.values.trip_mine = {}
	self.values.trip_mine.quantity = {
		1,
		2,
		3,
		4,
		5,
		8
	}
	self.values.trip_mine.damage_multiplier = {1.3, 1.6}
	self.steps.trip_mine = {}
	self.steps.trip_mine.quantity = {
		14,
		22,
		29,
		36,
		42,
		47
	}
	self.steps.trip_mine.damage_multiplier = {6, 32}
	self.ammo_bag_base = 4
	self.values.ammo_bag = {}
	self.values.ammo_bag.ammo_increase = {
		1,
		3,
		6
	}
	self.steps.ammo_bag = {}
	self.steps.ammo_bag.ammo_increase = {
		10,
		19,
		30
	}
	self.values.sentry_gun = {}
	self.steps.sentry_gun = {}
	self.sentry_gun_base_ammo = 400
	self.sentry_gun_base_armor = 5
	self.values.sentry_gun.ammo_increase = {
		100,
		200,
		300,
		400
	}
	self.values.sentry_gun.armor_increase = {
		2,
		3,
		4,
		5
	}
	self.steps.sentry_gun.ammo_increase = {
		11,
		19,
		36,
		45
	}
	self.steps.sentry_gun.armor_increase = {
		10,
		17,
		24,
		33
	}
	self.doctor_bag_base = 2
	self.values.doctor_bag = {}
	self.values.doctor_bag.amount_increase = {
		1,
		2,
		3
	}
	self.steps.doctor_bag = {}
	self.steps.doctor_bag.amount_increase = {
		11,
		19,
		33
	}
	self.values.extra_cable_tie = {}
	self.values.extra_cable_tie.quantity = {
		1,
		2,
		3,
		4
	}
	self.steps.extra_cable_tie = {}
	self.steps.extra_cable_tie.quantity = {
		nil,
		12,
		23,
		33
	}
	self.values.c45 = {}
	self.values.c45.clip_ammo_increase = {2, 4}
	self.values.c45.recoil_multiplier = {
		0.9,
		0.8,
		0.7,
		0.6
	}
	self.values.c45.damage_multiplier = {
		1.1,
		1.2,
		1.3,
		1.4
	}
	self.steps.c45 = {}
	self.steps.c45.clip_ammo_increase = {20, 29}
	self.steps.c45.recoil_multiplier = {
		16,
		36,
		41,
		45
	}
	self.steps.c45.damage_multiplier = {
		18,
		25,
		34,
		43
	}
	self.values.beretta92 = {}
	self.values.beretta92.clip_ammo_increase = {4, 6}
	self.values.beretta92.recoil_multiplier = {
		0.9,
		0.8,
		0.7,
		0.6
	}
	self.values.beretta92.spread_multiplier = {0.9, 0.8}
	self.steps.beretta92 = {}
	self.steps.beretta92.clip_ammo_increase = {3, 8}
	self.steps.beretta92.recoil_multiplier = {
		3,
		9,
		21,
		30
	}
	self.steps.beretta92.spread_multiplier = {1, 9}
	self.values.raging_bull = {}
	self.values.raging_bull.spread_multiplier = {
		0.9,
		0.8,
		0.7,
		0.6
	}
	self.values.raging_bull.reload_speed_multiplier = {1.1, 1.2}
	self.values.raging_bull.damage_multiplier = {
		1.1,
		1.2,
		1.3,
		1.4
	}
	self.steps.raging_bull = {}
	self.steps.raging_bull.spread_multiplier = {
		10,
		20,
		34,
		43
	}
	self.steps.raging_bull.reload_speed_multiplier = {14, 26}
	self.steps.raging_bull.damage_multiplier = {
		8,
		17,
		30,
		46
	}
	self.values.m4 = {}
	self.values.m4.clip_ammo_increase = {5, 10}
	self.values.m4.spread_multiplier = {
		0.9,
		0.8,
		0.7,
		0.6
	}
	self.values.m4.damage_multiplier = {1.1, 1.2}
	self.steps.m4 = {}
	self.steps.m4.clip_ammo_increase = {3, 12}
	self.steps.m4.spread_multiplier = {
		1,
		5,
		12,
		16
	}
	self.steps.m4.damage_multiplier = {1, 15}
	self.values.m14 = {}
	self.values.m14.clip_ammo_increase = {2, 4}
	self.values.m14.recoil_multiplier = {
		0.9,
		0.8,
		0.7,
		0.6
	}
	self.values.m14.spread_multiplier = {0.9, 0.8}
	self.values.m14.damage_multiplier = {1.1, 1.2}
	self.steps.m14 = {}
	self.steps.m14.clip_ammo_increase = {35, 45}
	self.steps.m14.recoil_multiplier = {
		24,
		37,
		41,
		48
	}
	self.steps.m14.spread_multiplier = {19, 31}
	self.steps.m14.damage_multiplier = {26, 43}
	self.values.r870_shotgun = {}
	self.values.r870_shotgun.clip_ammo_increase = {2, 4}
	self.values.r870_shotgun.recoil_multiplier = {
		0.9,
		0.8,
		0.7,
		0.6
	}
	self.values.r870_shotgun.damage_multiplier = {
		1.1,
		1.2,
		1.3,
		1.4
	}
	self.steps.r870_shotgun = {}
	self.steps.r870_shotgun.clip_ammo_increase = {18, 28}
	self.steps.r870_shotgun.recoil_multiplier = {
		22,
		36,
		41,
		48
	}
	self.steps.r870_shotgun.damage_multiplier = {
		15,
		25,
		39,
		44
	}
	self.values.mossberg = {}
	self.values.mossberg.clip_ammo_increase = {1, 2}
	self.values.mossberg.reload_speed_multiplier = {1.1, 1.2}
	self.values.mossberg.fire_rate_multiplier = {
		1.2,
		1.3,
		1.4,
		1.6
	}
	self.values.mossberg.recoil_multiplier = {0.9, 0.8}
	self.steps.mossberg = {}
	self.steps.mossberg.clip_ammo_increase = {13, 38}
	self.steps.mossberg.reload_speed_multiplier = {15, 40}
	self.steps.mossberg.fire_rate_multiplier = {
		10,
		23,
		34,
		44
	}
	self.steps.mossberg.recoil_multiplier = {28, 46}
	self.values.mp5 = {}
	self.values.mp5.recoil_multiplier = {0.85, 0.7}
	self.values.mp5.spread_multiplier = {0.75, 0.5}
	self.values.mp5.reload_speed_multiplier = {
		1.1,
		1.2,
		1.3,
		1.4
	}
	self.values.mp5.enter_steelsight_speed_multiplier = {1.5, 1.8}
	self.steps.mp5 = {}
	self.steps.mp5.recoil_multiplier = {32, 40}
	self.steps.mp5.spread_multiplier = {27, 45}
	self.steps.mp5.reload_speed_multiplier = {
		31,
		37,
		42,
		47
	}
	self.steps.mp5.enter_steelsight_speed_multiplier = {23, 35}
	self.values.mac11 = {}
	self.values.mac11.clip_ammo_increase = {
		6,
		12,
		18,
		24
	}
	self.values.mac11.recoil_multiplier = {
		0.9,
		0.8,
		0.7,
		0.6
	}
	self.values.mac11.enter_steelsight_speed_multiplier = {1.1, 1.2}
	self.steps.mac11 = {}
	self.steps.mac11.recoil_multiplier = {
		6,
		11,
		21,
		35
	}
	self.steps.mac11.clip_ammo_increase = {
		9,
		17,
		32,
		40
	}
	self.steps.mac11.enter_steelsight_speed_multiplier = {14, 28}
	self.values.hk21 = {}
	self.values.hk21.clip_ammo_increase = {
		20,
		40,
		60,
		80
	}
	self.values.hk21.recoil_multiplier = {0.9, 0.8}
	self.values.hk21.damage_multiplier = {
		1.1,
		1.2,
		1.3,
		1.4
	}
	self.steps.hk21 = {}
	self.steps.hk21.clip_ammo_increase = {
		24,
		37,
		42,
		48
	}
	self.steps.hk21.recoil_multiplier = {31, 46}
	self.steps.hk21.damage_multiplier = {
		27,
		39,
		44,
		47
	}
	self.values.ak47 = {}
	self.values.ak47.spread_multiplier = {0.9, 0.8}
	self.values.ak47.recoil_multiplier = {
		0.95,
		0.9,
		0.85,
		0.8
	}
	self.values.ak47.damage_multiplier = {
		1.1,
		1.2,
		1.25,
		1.3
	}
	self.values.ak47.clip_ammo_increase = {5, 10}
	self.steps.ak47 = {}
	self.steps.ak47.spread_multiplier = {18, 40}
	self.steps.ak47.recoil_multiplier = {
		12,
		22,
		41,
		48
	}
	self.steps.ak47.damage_multiplier = {
		15,
		30,
		37,
		44
	}
	self.steps.ak47.clip_ammo_increase = {27, 32}
	self.values.glock = {}
	self.values.glock.recoil_multiplier = {0.9, 0.8}
	self.values.glock.clip_ammo_increase = {
		5,
		10,
		15,
		20
	}
	self.values.glock.damage_multiplier = {1.1, 1.2}
	self.values.glock.reload_speed_multiplier = {1.1, 1.2}
	self.steps.glock = {}
	self.steps.glock.recoil_multiplier = {14, 26}
	self.steps.glock.clip_ammo_increase = {
		3,
		20,
		34,
		43
	}
	self.steps.glock.damage_multiplier = {8, 46}
	self.steps.glock.reload_speed_multiplier = {4, 13}
	self.values.m79 = {}
	self.values.m79.damage_multiplier = {
		1.1,
		1.2,
		1.3,
		1.4
	}
	self.values.m79.explosion_range_multiplier = {1.1, 1.2}
	self.values.m79.clip_amount_increase = {1, 3}
	self.steps.m79 = {}
	self.steps.m79.damage_multiplier = {
		31,
		35,
		42,
		47
	}
	self.steps.m79.explosion_range_multiplier = {23, 28}
	self.steps.m79.clip_amount_increase = {25, 39}
	self.itree_caps = {}
	table.insert(self.itree_caps, {step = 5, level = 8})
	table.insert(self.itree_caps, {step = 13, level = 20})
	table.insert(self.itree_caps, {step = 44, level = 88})
	table.insert(self.itree_caps, {
		step = 49,
		level = managers.dlc:has_dlc1() and 192 or 144
	})
	table.insert(self.itree_caps, {
		step = 50,
		level = managers.dlc:has_dlc1() and 193 or 145
	})
	self.tree_caps = {}
	for i, d in ipairs(self.itree_caps) do
		self.tree_caps[d.step] = d.level
	end
	self.trees = {}
	self.trees[1] = {
		name_id = "debug_upgrade_tree_assault"
	}
	self.trees[2] = {
		name_id = "debug_upgrade_tree_sharpshooter"
	}
	self.trees[3] = {
		name_id = "debug_upgrade_tree_support"
	}
	self.trees[4] = {
		name_id = "debug_upgrade_tree_technician"
	}
	self.definitions = {}
	self:_player_definitions()
	self:_trip_mine_definitions()
	self:_ammo_bag_definitions()
	self:_doctor_bag_definitions()
	self:_cable_tie_definitions()
	self:_sentry_gun_definitions()
	self:_crew_bonuses_definitions()
	self:_c45_definitions()
	self:_beretta92_definitions()
	self:_raging_bull_definitions()
	self:_m4_definitions()
	self:_m14_definitions()
	self:_mp5_definitions()
	self:_mac11_definitions()
	self:_remington_definitions()
	self:_mossberg_definitions()
	self:_hk21_definitions()
	self:_ak47_definitions()
	self:_glock_definitions()
	self:_m79_definitions()
	self.definitions.money_bag1 = {
		category = "money_multiplier",
		name_id = "debug_upgrade_money_bag1",
		icon = "equipment_money_bag",
		multiplier = "money_bag1",
		unlock_lvl = 7,
		prio = "high"
	}
	self.definitions.money_bag2 = {
		category = "money_multiplier",
		name_id = "debug_upgrade_money_bag2",
		icon = "equipment_money_bag",
		multiplier = "money_bag2",
		unlock_lvl = 10,
		prio = "high",
		depends_on = "money_bag1"
	}
	self.levels = {}
	for name, upgrade in pairs(self.definitions) do
		local unlock_lvl = upgrade.unlock_lvl or 1
		self.levels[unlock_lvl] = self.levels[unlock_lvl] or {}
		if upgrade.prio and upgrade.prio == "high" then
			table.insert(self.levels[unlock_lvl], 1, name)
		else
			table.insert(self.levels[unlock_lvl], name)
		end
	end
	self.progress = {
		{},
		{},
		{},
		{}
	}
	for name, upgrade in pairs(self.definitions) do
		if upgrade.tree then
			if upgrade.step then
				if self.progress[upgrade.tree][upgrade.step] then
					Application:error("upgrade collision", upgrade.tree, upgrade.step, self.progress[upgrade.tree][upgrade.step], name)
				end
				self.progress[upgrade.tree][upgrade.step] = name
			else
				print(name, upgrade.tree, "is in no step")
			end
		end
	end
	self.progress[1][49] = "mr_nice_guy"
	self.progress[2][49] = "mr_nice_guy"
	self.progress[3][49] = "mr_nice_guy"
	self.progress[4][49] = "mr_nice_guy"
end
function UpgradesTweakData:_player_definitions()
	self.definitions.body_armor = {
		category = "equipment",
		equipment_id = "body_armor",
		name_id = "debug_upgrade_body_armor1",
		icon = "equipment_armor",
		image = "upgrades_bodyarmor",
		image_slice = "upgrades_bodyarmor_slice",
		unlock_lvl = 0,
		description_text_id = "body_armor",
		slot = 0
	}
	for i, _ in ipairs(self.values.player.body_armor) do
		local depends_on = 0 < i - 1 and "body_armor" .. i - 1
		local unlock_lvl = 3
		local prio = i == 1 and "high"
		self.definitions["body_armor" .. i] = {
			incremental = true,
			category = "feature",
			name_id = "debug_upgrade_body_armor" .. i,
			title_id = "debug_upgrade_body_armor",
			subtitle_id = "debug_upgrade_body_armor_increase",
			icon = "equipment_armor",
			image = "upgrades_bodyarmor",
			image_slice = "upgrades_bodyarmor_slice",
			description_text_id = "body_armor",
			depends_on = depends_on,
			unlock_lvl = unlock_lvl,
			prio = prio,
			upgrade = {
				category = "player",
				upgrade = "body_armor",
				value = i
			}
		}
	end
	self.definitions.body_armor1.tree = 1
	self.definitions.body_armor1.step = 7
	self.definitions.body_armor2.tree = 2
	self.definitions.body_armor2.step = 11
	self.definitions.body_armor3.tree = 2
	self.definitions.body_armor3.step = 25
	self.definitions.body_armor4.tree = 3
	self.definitions.body_armor4.step = 4
	self.definitions.body_armor5.tree = 4
	self.definitions.body_armor5.step = 6
	self.definitions.thick_skin = {
		tree = 2,
		step = 2,
		category = "equipment",
		equipment_id = "thick_skin",
		title_id = "debug_upgrade_player_upgrade",
		subtitle_id = "debug_upgrade_thick_skin1",
		name_id = "debug_upgrade_thick_skin1",
		icon = "equipment_armor",
		image = "upgrades_thugskin",
		image_slice = "upgrades_thugskin_slice",
		description_text_id = "thick_skin",
		unlock_lvl = 0,
		aquire = {
			upgrade = "thick_skin1"
		},
		slot = 2
	}
	for i, _ in ipairs(self.values.player.thick_skin) do
		local depends_on = 0 < i - 1 and "thick_skin" .. i - 1
		local unlock_lvl = 3
		local prio = i == 1 and "high"
		self.definitions["thick_skin" .. i] = {
			tree = 2,
			step = self.steps.player.thick_skin[i],
			category = "feature",
			title_id = "debug_upgrade_player_upgrade",
			subtitle_id = "debug_upgrade_thick_skin" .. i,
			name_id = "debug_upgrade_thick_skin" .. i,
			icon = "equipment_thick_skin",
			image = "upgrades_thugskin",
			image_slice = "upgrades_thugskin_slice",
			description_text_id = "thick_skin",
			depends_on = depends_on,
			unlock_lvl = unlock_lvl,
			prio = prio,
			upgrade = {
				category = "player",
				upgrade = "thick_skin",
				value = i
			}
		}
	end
	self.definitions.extra_start_out_ammo = {
		tree = 3,
		step = 2,
		category = "equipment",
		equipment_id = "extra_start_out_ammo",
		name_id = "debug_upgrade_extra_start_out_ammo1",
		title_id = "debug_upgrade_player_upgrade",
		subtitle_id = "debug_upgrade_extra_start_out_ammo1",
		icon = "equipment_extra_start_out_ammo",
		image = "upgrades_extrastartammo",
		image_slice = "upgrades_extrastartammo_slice",
		description_text_id = "extra_ammo_multiplier",
		unlock_lvl = 13,
		prio = "high",
		aquire = {
			upgrade = "extra_ammo_multiplier1"
		},
		slot = 2
	}
	for i, _ in ipairs(self.values.player.extra_ammo_multiplier) do
		local depends_on = 0 < i - 1 and "extra_ammo_multiplier" .. i - 1
		local unlock_lvl = 14
		local prio = i == 1 and "high"
		self.definitions["extra_ammo_multiplier" .. i] = {
			tree = 3,
			step = self.steps.player.extra_ammo_multiplier[i],
			category = "feature",
			name_id = "debug_upgrade_extra_start_out_ammo" .. i,
			title_id = "debug_upgrade_player_upgrade",
			subtitle_id = "debug_upgrade_extra_start_out_ammo" .. i,
			icon = "equipment_extra_start_out_ammo",
			image = "upgrades_extrastartammo",
			image_slice = "upgrades_extrastartammo_slice",
			description_text_id = "extra_ammo_multiplier",
			depends_on = depends_on,
			unlock_lvl = unlock_lvl,
			prio = prio,
			upgrade = {
				category = "player",
				upgrade = "extra_ammo_multiplier",
				value = i
			}
		}
	end
	self.definitions.toolset = {
		tree = 4,
		step = 1,
		category = "equipment",
		equipment_id = "toolset",
		title_id = "debug_upgrade_player_upgrade",
		subtitle_id = "debug_upgrade_toolset1",
		name_id = "debug_upgrade_toolset1",
		icon = "equipment_toolset",
		image = "upgrades_toolset",
		image_slice = "upgrades_toolset_slice",
		description_text_id = "toolset",
		unlock_lvl = 0,
		aquire = {upgrade = "toolset1"},
		slot = 2
	}
	for i, _ in ipairs(self.values.player.toolset) do
		local depends_on = 0 < i - 1 and "toolset" .. i - 1
		local unlock_lvl = 3
		local prio = i == 1 and "high"
		self.definitions["toolset" .. i] = {
			tree = 4,
			step = self.steps.player.toolset[i],
			category = "feature",
			title_id = "debug_upgrade_player_upgrade",
			subtitle_id = "debug_upgrade_toolset" .. i,
			name_id = "debug_upgrade_toolset" .. i,
			icon = "equipment_toolset",
			image = "upgrades_toolset",
			image_slice = "upgrades_toolset_slice",
			description_text_id = "toolset",
			depends_on = depends_on,
			unlock_lvl = unlock_lvl,
			prio = prio,
			upgrade = {
				category = "player",
				upgrade = "toolset",
				value = i
			}
		}
	end
end
function UpgradesTweakData:_trip_mine_definitions()
	self.definitions.trip_mine = {
		tree = 2,
		step = 4,
		category = "equipment",
		equipment_id = "trip_mine",
		name_id = "debug_trip_mine",
		title_id = "debug_upgrade_new_equipment",
		subtitle_id = "debug_trip_mine",
		icon = "equipment_trip_mine",
		image = "upgrades_tripmines",
		image_slice = "upgrades_tripmines_slice",
		description_text_id = "trip_mine",
		unlock_lvl = 0,
		prio = "high",
		slot = 1
	}
	for i, _ in ipairs(self.values.trip_mine.quantity) do
		local depends_on = 0 < i - 1 and "trip_mine_quantity" .. i - 1 or "trip_mine"
		local unlock_lvl = 7
		local prio = i == 1 and "high"
		self.definitions["trip_mine_quantity" .. i] = {
			tree = 2,
			step = self.steps.trip_mine.quantity[i],
			category = "equipment_upgrade",
			name_id = "debug_upgrade_trip_mine_quantity" .. i,
			title_id = "debug_trip_mine",
			subtitle_id = "debug_upgrade_amount_increase" .. i,
			icon = "equipment_trip_mine",
			image = "upgrades_tripmines",
			image_slice = "upgrades_tripmines_slice",
			description_text_id = "trip_mine_quantity",
			depends_on = depends_on,
			unlock_lvl = unlock_lvl,
			prio = prio,
			upgrade = {
				category = "trip_mine",
				upgrade = "quantity",
				value = i
			}
		}
	end
	for i, _ in ipairs(self.values.trip_mine.damage_multiplier) do
		local depends_on = 0 < i - 1 and "trip_mine_damage" .. i - 1 or "trip_mine"
		local unlock_lvl = 7
		local prio = i == 1 and "high"
		self.definitions["trip_mine_damage" .. i] = {
			tree = 2,
			step = self.steps.trip_mine.damage_multiplier[i],
			category = "feature",
			name_id = "debug_upgrade_trip_mine_damage" .. i,
			title_id = "debug_trip_mine",
			subtitle_id = "debug_upgrade_damage" .. i,
			icon = "equipment_trip_mine",
			image = "upgrades_tripmines",
			image_slice = "upgrades_tripmines_slice",
			description_text_id = "trip_mine_damage",
			depends_on = depends_on,
			unlock_lvl = unlock_lvl,
			prio = prio,
			upgrade = {
				category = "trip_mine",
				upgrade = "damage_multiplier",
				value = i
			}
		}
	end
end
function UpgradesTweakData:_ammo_bag_definitions()
	self.definitions.ammo_bag = {
		tree = 1,
		step = 2,
		category = "equipment",
		equipment_id = "ammo_bag",
		name_id = "debug_ammo_bag",
		title_id = "debug_upgrade_new_equipment",
		subtitle_id = "debug_ammo_bag",
		icon = "equipment_ammo_bag",
		image = "upgrades_ammobag",
		image_slice = "upgrades_ammobag_slice",
		description_text_id = "ammo_bag",
		unlock_lvl = 0,
		prio = "high",
		slot = 1
	}
	for i, _ in ipairs(self.values.ammo_bag.ammo_increase) do
		local depends_on = i - 1 > 0 and "ammo_bag_ammo_increase" .. i - 1 or "ammo_bag"
		local unlock_lvl = 11
		local prio = i == 1 and "high"
		self.definitions["ammo_bag_ammo_increase" .. i] = {
			tree = 1,
			step = self.steps.ammo_bag.ammo_increase[i],
			category = "equipment_upgrade",
			name_id = "debug_upgrade_ammo_bag_ammo_increase" .. i,
			title_id = "debug_ammo_bag",
			subtitle_id = "debug_upgrade_amount_increase" .. i,
			icon = "equipment_ammo_bag",
			image = "upgrades_ammobag",
			image_slice = "upgrades_ammobag_slice",
			description_text_id = "ammo_bag_increase",
			depends_on = depends_on,
			unlock_lvl = unlock_lvl,
			prio = prio,
			upgrade = {
				category = "ammo_bag",
				upgrade = "ammo_increase",
				value = i
			}
		}
	end
end
function UpgradesTweakData:_doctor_bag_definitions()
	self.definitions.doctor_bag = {
		tree = 3,
		step = 5,
		category = "equipment",
		equipment_id = "doctor_bag",
		name_id = "debug_doctor_bag",
		title_id = "debug_upgrade_new_equipment",
		subtitle_id = "debug_doctor_bag",
		icon = "equipment_doctor_bag",
		image = "upgrades_doctorbag",
		image_slice = "upgrades_doctorbag_slice",
		description_text_id = "doctor_bag",
		unlock_lvl = 2,
		prio = "high",
		slot = 1
	}
	for i, _ in ipairs(self.values.doctor_bag.amount_increase) do
		local depends_on = i - 1 > 0 and "doctor_bag_amount_increase" .. i - 1 or "doctor_bag"
		local unlock_lvl = 3
		local prio = i == 1 and "high"
		self.definitions["doctor_bag_amount_increase" .. i] = {
			tree = 3,
			step = self.steps.doctor_bag.amount_increase[i],
			category = "equipment_upgrade",
			name_id = "debug_upgrade_doctor_bag_amount_increase" .. i,
			title_id = "debug_doctor_bag",
			subtitle_id = "debug_upgrade_amount_increase" .. i,
			icon = "equipment_doctor_bag",
			image = "upgrades_doctorbag",
			image_slice = "upgrades_doctorbag_slice",
			description_text_id = "doctor_bag_increase",
			depends_on = depends_on,
			unlock_lvl = unlock_lvl,
			prio = prio,
			upgrade = {
				category = "doctor_bag",
				upgrade = "amount_increase",
				value = i
			}
		}
	end
end
function UpgradesTweakData:_cable_tie_definitions()
	self.definitions.cable_tie = {
		category = "equipment",
		equipment_id = "cable_tie",
		name_id = "debug_equipment_cable_tie",
		title_id = "debug_equipment_cable_tie",
		icon = "equipment_cable_ties",
		image = "upgrades_extracableties",
		image_slice = "upgrades_extracableties_slice",
		unlock_lvl = 0,
		prio = "high"
	}
	self.definitions.extra_cable_tie = {
		tree = 1,
		step = 4,
		category = "equipment",
		equipment_id = "extra_cable_tie",
		name_id = "debug_upgrade_extra_cable_tie_quantity1",
		title_id = "debug_equipment_cable_tie",
		subtitle_id = "debug_upgrade_amount_increase1",
		icon = "equipment_extra_cable_ties",
		image = "upgrades_extracableties",
		image_slice = "upgrades_extracableties_slice",
		description_text_id = "extra_cable_tie",
		unlock_lvl = 3,
		prio = "high",
		aquire = {
			upgrade = "extra_cable_tie_quantity1"
		},
		slot = 2
	}
	for i, _ in ipairs(self.values.extra_cable_tie.quantity) do
		local depends_on = 0 < i - 1 and "extra_cable_tie_quantity" .. i - 1 or "extra_cable_tie"
		local unlock_lvl = 4
		local prio = i == 1 and "high"
		self.definitions["extra_cable_tie_quantity" .. i] = {
			tree = 1,
			step = self.steps.extra_cable_tie.quantity[i],
			category = "equipment_upgrade",
			name_id = "debug_upgrade_extra_cable_tie_quantity" .. i,
			title_id = "debug_equipment_cable_tie",
			subtitle_id = "debug_upgrade_amount_increase" .. i,
			icon = "equipment_extra_cable_ties",
			image = "upgrades_extracableties",
			image_slice = "upgrades_extracableties_slice",
			description_text_id = "extra_cable_tie",
			depends_on = depends_on,
			unlock_lvl = unlock_lvl,
			prio = prio,
			upgrade = {
				category = "extra_cable_tie",
				upgrade = "quantity",
				value = i
			}
		}
	end
end
function UpgradesTweakData:_revive_kit_definitions()
	self.definitions.revive_kit = {
		category = "equipment",
		equipment_id = "revive_kit",
		name_id = "debug_equipment_revive_kit",
		icon = "interaction_help",
		unlock_lvl = 0,
		prio = "high"
	}
	self.definitions.extra_revive_kit = {
		category = "equipment",
		equipment_id = "extra_revive_kit",
		name_id = "debug_upgrade_extra_revive_kit_quantity1",
		icon = "guis/textures/equipment_extra_revive_kit",
		unlock_lvl = 5,
		prio = "high",
		aquire = {
			upgrade = "extra_revive_kit_quantity1"
		},
		slot = 2
	}
	for i, _ in ipairs(self.values.extra_revive_kit.quantity) do
		local depends_on = 0 < i - 1 and "extra_revive_kit_quantity" .. i - 1 or "extra_revive_kit"
		local unlock_lvl = 6
		local prio = i == 1 and "high"
		self.definitions["extra_revive_kit_quantity" .. i] = {
			category = "equipment_upgrade",
			name_id = "debug_upgrade_extra_revive_kit_quantity" .. i,
			icon = "guis/textures/equipment_extra_revive_kit",
			depends_on = depends_on,
			unlock_lvl = unlock_lvl,
			prio = prio,
			upgrade = {
				category = "extra_revive_kit",
				upgrade = "quantity",
				value = i
			}
		}
	end
end
function UpgradesTweakData:_sentry_gun_definitions()
	self.definitions.sentry_gun = {
		tree = 4,
		step = 5,
		category = "equipment",
		equipment_id = "sentry_gun",
		name_id = "debug_sentry_gun",
		title_id = "debug_upgrade_new_equipment",
		subtitle_id = "debug_sentry_gun",
		icon = "equipment_sentry",
		image = "upgrades_sentry",
		image_slice = "upgrades_sentry_slice",
		description_text_id = "sentry_gun",
		unlock_lvl = 0,
		prio = "high",
		slot = 1
	}
	for i, _ in ipairs(self.values.sentry_gun.ammo_increase) do
		local depends_on = 0 < i - 1 and "sentry_gun_ammo_increase" .. i - 1 or "sentry_gun"
		local unlock_lvl = 11
		local prio = i == 1 and "high"
		self.definitions["sentry_gun_ammo_increase" .. i] = {
			tree = 4,
			step = self.steps.sentry_gun.ammo_increase[i],
			category = "equipment_upgrade",
			name_id = "debug_upgrade_sentry_gun_ammo_increase" .. i,
			title_id = "debug_sentry_gun",
			subtitle_id = "debug_upgrade_ammo_increase" .. i,
			icon = "equipment_sentry",
			image = "upgrades_sentry",
			image_slice = "upgrades_sentry_slice",
			description_text_id = "sentry_gun_ammo_increase",
			depends_on = depends_on,
			unlock_lvl = unlock_lvl,
			prio = prio,
			upgrade = {
				category = "sentry_gun",
				upgrade = "ammo_increase",
				value = i
			}
		}
	end
	for i, _ in ipairs(self.values.sentry_gun.armor_increase) do
		local depends_on = 0 < i - 1 and "sentry_gun_armor_increase" .. i - 1 or "sentry_gun"
		local unlock_lvl = 11
		local prio = i == 1 and "high"
		self.definitions["sentry_gun_armor_increase" .. i] = {
			tree = 4,
			step = self.steps.sentry_gun.armor_increase[i],
			category = "equipment_upgrade",
			name_id = "name" .. i,
			title_id = "debug_sentry_gun",
			subtitle_id = "debug_upgrade_armor_increase" .. i,
			icon = "equipment_sentry",
			image = "upgrades_sentry",
			image_slice = "upgrades_sentry_slice",
			description_text_id = "sentry_gun_armor_increase",
			depends_on = depends_on,
			unlock_lvl = unlock_lvl,
			prio = prio,
			upgrade = {
				category = "sentry_gun",
				upgrade = "armor_increase",
				value = i
			}
		}
	end
end
function UpgradesTweakData:_crew_bonuses_definitions()
	self.definitions.welcome_to_the_gang = {
		category = "crew_bonus",
		name_id = "debug_upgrade_welcome_to_the_gang",
		description_id = "des_welcome_to_the_gang",
		description_text_id = "des_welcome_to_the_gang",
		icon = "crew_bonus_welcome_to_the_gang",
		image = "upgrades_welcome",
		image_slice = "upgrades_welcome_slice",
		unlock_lvl = 0,
		upgrade = {
			category = "crew_bonus",
			upgrade = "welcome_to_the_gang",
			value = 1
		}
	}
	self.definitions.aggressor = {
		tree = 1,
		step = 26,
		category = "crew_bonus",
		name_id = "debug_upgrade_aggressor",
		title_id = "debug_upgrade_crewbonus",
		subtitle_id = "debug_upgrade_aggressor",
		description_id = "des_aggressor",
		description_text_id = "des_aggressor",
		icon = "crew_bonus_aggressor",
		image = "upgrades_agressor",
		image_slice = "upgrades_agressor_slice",
		unlock_lvl = 80,
		upgrade = {
			category = "crew_bonus",
			upgrade = "aggressor",
			value = 1
		}
	}
	self.definitions.protector = {
		tree = 3,
		step = 29,
		category = "crew_bonus",
		name_id = "debug_upgrade_protector",
		title_id = "debug_upgrade_crewbonus",
		subtitle_id = "debug_upgrade_protector",
		description_id = "des_protector",
		description_text_id = "des_protector",
		icon = "crew_bonus_protector",
		image = "upgrades_protector",
		image_slice = "upgrades_protector_slice",
		unlock_lvl = 85,
		upgrade = {
			category = "crew_bonus",
			upgrade = "protector",
			value = 1
		}
	}
	self.definitions.sharpshooters = {
		tree = 2,
		step = 20,
		category = "crew_bonus",
		name_id = "debug_upgrade_sharpshooters",
		title_id = "debug_upgrade_crewbonus",
		subtitle_id = "debug_upgrade_sharpshooters",
		description_id = "des_sharpshooters",
		description_text_id = "des_sharpshooters",
		icon = "crew_bonus_sharpshooters",
		image = "upgrades_sharpshooters",
		image_slice = "upgrades_sharpshooters_slice",
		unlock_lvl = 90,
		upgrade = {
			category = "crew_bonus",
			upgrade = "sharpshooters",
			value = 1
		}
	}
	self.definitions.more_blood_to_bleed = {
		tree = 2,
		step = 33,
		category = "crew_bonus",
		name_id = "debug_upgrade_more_blood_to_bleed",
		title_id = "debug_upgrade_crewbonus",
		subtitle_id = "debug_upgrade_more_blood_to_bleed",
		description_id = "des_more_blood_to_bleed",
		description_text_id = "des_more_blood_to_bleed",
		icon = "crew_bonus_more_blood_to_bleed",
		image = "upgrades_morebloodtobleed",
		image_slice = "upgrades_morebloodtobleed_slice",
		unlock_lvl = 95,
		upgrade = {
			category = "crew_bonus",
			upgrade = "more_blood_to_bleed",
			value = 1
		}
	}
	self.definitions.speed_reloaders = {
		tree = 1,
		step = 38,
		category = "crew_bonus",
		name_id = "debug_upgrade_speed_reloaders",
		title_id = "debug_upgrade_crewbonus",
		subtitle_id = "debug_upgrade_speed_reloaders",
		description_id = "des_speed_reloaders",
		description_text_id = "des_speed_reloaders",
		icon = "crew_bonus_speed_reloaders",
		image = "upgrades_speedreloaders",
		image_slice = "upgrades_speedreloaders_slice",
		unlock_lvl = 100,
		upgrade = {
			category = "crew_bonus",
			upgrade = "speed_reloaders",
			value = 1
		}
	}
	self.definitions.more_ammo = {
		tree = 4,
		step = 29,
		category = "crew_bonus",
		name_id = "debug_upgrade_more_ammo",
		title_id = "debug_upgrade_crewbonus",
		subtitle_id = "debug_upgrade_more_ammo",
		description_id = "des_more_ammo",
		description_text_id = "des_more_ammo",
		icon = "crew_bonus_more_ammo",
		image = "upgrades_team_ammo",
		image_slice = "upgrades_team_ammo_slice",
		unlock_lvl = 100,
		upgrade = {
			category = "crew_bonus",
			upgrade = "more_ammo",
			value = 1
		}
	}
	self.definitions.mr_nice_guy = {
		category = "crew_bonus",
		name_id = "debug_upgrade_mr_nice_guy",
		title_id = "debug_upgrade_crewbonus",
		subtitle_id = "debug_upgrade_mr_nice_guy",
		description_id = "des_mr_nice_guy",
		description_text_id = "des_mr_nice_guy",
		icon = "crew_bonus_mr_nice_guy",
		image = "upgrades_mrniceguy",
		image_slice = "upgrades_mrniceguy_slice",
		unlock_lvl = 115,
		upgrade = {
			category = "crew_bonus",
			upgrade = "mr_nice_guy",
			value = 1
		}
	}
end
function UpgradesTweakData:_c45_definitions()
	self.definitions.c45 = {
		tree = 1,
		step = 13,
		category = "weapon",
		unit_name = Idstring("units/weapons/c45/c45"),
		name_id = "debug_c45",
		title_id = "debug_upgrade_new_weapon",
		subtitle_id = "debug_c45_short",
		icon = "c45",
		image = "upgrades_45",
		image_slice = "upgrades_45_slice",
		unlock_lvl = 30,
		prio = "high",
		description_text_id = "des_c45"
	}
	for i, _ in ipairs(self.values.c45.clip_ammo_increase) do
		local depends_on = i - 1 > 0 and "c45_mag" .. i - 1 or "c45"
		local unlock_lvl = 31
		local prio = i == 1 and "high"
		self.definitions["c45_mag" .. i] = {
			tree = 1,
			step = self.steps.c45.clip_ammo_increase[i],
			category = "feature",
			name_id = "debug_upgrade_c45_mag" .. i,
			title_id = "debug_c45_short",
			subtitle_id = "debug_upgrade_mag" .. i,
			icon = "c45",
			image = "upgrades_45",
			image_slice = "upgrades_45_slice",
			description_text_id = "clip_ammo_increase",
			depends_on = depends_on,
			unlock_lvl = unlock_lvl,
			prio = prio,
			upgrade = {
				category = "c45",
				upgrade = "clip_ammo_increase",
				value = i
			}
		}
	end
	for i, _ in ipairs(self.values.c45.recoil_multiplier) do
		local depends_on = i - 1 > 0 and "c45_recoil" .. i - 1 or "c45"
		local unlock_lvl = 31
		local prio = i == 1 and "high"
		self.definitions["c45_recoil" .. i] = {
			tree = 1,
			step = self.steps.c45.recoil_multiplier[i],
			category = "feature",
			name_id = "debug_upgrade_c45_recoil" .. i,
			title_id = "debug_c45_short",
			subtitle_id = "debug_upgrade_recoil" .. i,
			icon = "c45",
			image = "upgrades_45",
			image_slice = "upgrades_45_slice",
			description_text_id = "recoil_multiplier",
			depends_on = depends_on,
			unlock_lvl = unlock_lvl,
			prio = prio,
			upgrade = {
				category = "c45",
				upgrade = "recoil_multiplier",
				value = i
			}
		}
	end
	for i, _ in ipairs(self.values.c45.damage_multiplier) do
		local depends_on = i - 1 > 0 and "c45_damage" .. i - 1 or "c45"
		local unlock_lvl = 31
		local prio = i == 1 and "high"
		self.definitions["c45_damage" .. i] = {
			tree = 1,
			step = self.steps.c45.damage_multiplier[i],
			category = "feature",
			name_id = "debug_upgrade_c45_damage" .. i,
			title_id = "debug_c45_short",
			subtitle_id = "debug_upgrade_damage" .. i,
			icon = "c45",
			image = "upgrades_45",
			image_slice = "upgrades_45_slice",
			description_text_id = "damage_multiplier",
			depends_on = depends_on,
			unlock_lvl = unlock_lvl,
			prio = prio,
			upgrade = {
				category = "c45",
				upgrade = "damage_multiplier",
				value = i
			}
		}
	end
end
function UpgradesTweakData:_beretta92_definitions()
	self.definitions.beretta92 = {
		category = "weapon",
		weapon_id = "beretta92",
		unit_name = Idstring("units/weapons/beretta92/beretta92"),
		name_id = "debug_beretta92",
		title_id = "debug_upgrade_new_weapon",
		subtitle_id = "debug_beretta92_short",
		icon = "beretta92",
		image = "upgrades_m9sd",
		image_slice = "upgrades_m9sd_slice",
		unlock_lvl = 0,
		prio = "high",
		description_text_id = "des_beretta92"
	}
	for i, _ in ipairs(self.values.beretta92.clip_ammo_increase) do
		local depends_on = 0 < i - 1 and "beretta_mag" .. i - 1 or "beretta92"
		local unlock_lvl = 2
		local prio = i == 1 and "high"
		self.definitions["beretta_mag" .. i] = {
			tree = 1,
			step = self.steps.beretta92.clip_ammo_increase[i],
			category = "feature",
			name_id = "debug_upgrade_beretta_mag" .. i,
			title_id = "debug_beretta92_short",
			subtitle_id = "debug_upgrade_mag" .. i,
			icon = "beretta92",
			image = "upgrades_m9sd",
			image_slice = "upgrades_m9sd_slice",
			description_text_id = "clip_ammo_increase",
			depends_on = depends_on,
			unlock_lvl = unlock_lvl,
			prio = prio,
			upgrade = {
				category = "beretta92",
				upgrade = "clip_ammo_increase",
				value = i
			}
		}
	end
	for i, _ in ipairs(self.values.beretta92.recoil_multiplier) do
		local depends_on = 0 < i - 1 and "beretta_recoil" .. i - 1 or "beretta92"
		local unlock_lvl = 2
		local prio = i == 1 and "high"
		self.definitions["beretta_recoil" .. i] = {
			tree = 2,
			step = self.steps.beretta92.recoil_multiplier[i],
			category = "feature",
			name_id = "debug_upgrade_beretta_recoil" .. i,
			title_id = "debug_beretta92_short",
			subtitle_id = "debug_upgrade_recoil" .. i,
			icon = "beretta92",
			image = "upgrades_m9sd",
			image_slice = "upgrades_m9sd_slice",
			description_text_id = "recoil_multiplier",
			depends_on = depends_on,
			unlock_lvl = unlock_lvl,
			prio = prio,
			upgrade = {
				category = "beretta92",
				upgrade = "recoil_multiplier",
				value = i
			}
		}
	end
	for i, _ in ipairs(self.values.beretta92.spread_multiplier) do
		local depends_on = 0 < i - 1 and "beretta_spread" .. i - 1 or "beretta92"
		local unlock_lvl = 2
		local prio = i == 1 and "high"
		self.definitions["beretta_spread" .. i] = {
			tree = 3,
			step = self.steps.beretta92.spread_multiplier[i],
			category = "feature",
			name_id = "debug_upgrade_beretta_spread" .. i,
			title_id = "debug_beretta92_short",
			subtitle_id = "debug_upgrade_spread" .. i,
			icon = "beretta92",
			image = "upgrades_m9sd",
			image_slice = "upgrades_m9sd_slice",
			description_text_id = "spread_multiplier",
			depends_on = depends_on,
			unlock_lvl = unlock_lvl,
			prio = prio,
			upgrade = {
				category = "beretta92",
				upgrade = "spread_multiplier",
				value = i
			}
		}
	end
end
function UpgradesTweakData:_raging_bull_definitions()
	self.definitions.raging_bull = {
		tree = 3,
		step = 6,
		category = "weapon",
		weapon_id = "raging_bull",
		unit_name = Idstring("units/weapons/raging_bull/raging_bull"),
		name_id = "debug_raging_bull",
		title_id = "debug_upgrade_new_weapon",
		subtitle_id = "debug_raging_bull_short",
		icon = "raging_bull",
		image = "upgrades_ragingbull",
		image_slice = "upgrades_ragingbull_slice",
		unlock_lvl = 60,
		prio = "high",
		description_text_id = "des_raging_bull"
	}
	for i, _ in ipairs(self.values.raging_bull.spread_multiplier) do
		local depends_on = i - 1 > 0 and "raging_bull_spread" .. i - 1
		local unlock_lvl = 61
		local prio = i == 1 and "high"
		self.definitions["raging_bull_spread" .. i] = {
			tree = 3,
			step = self.steps.raging_bull.spread_multiplier[i],
			category = "feature",
			name_id = "debug_upgrade_raging_bull_spread" .. i,
			title_id = "debug_raging_bull_short",
			subtitle_id = "debug_upgrade_spread" .. i,
			icon = "raging_bull",
			image = "upgrades_ragingbull",
			image_slice = "upgrades_ragingbull_slice",
			description_text_id = "spread_multiplier",
			depends_on = depends_on,
			unlock_lvl = unlock_lvl,
			prio = prio,
			upgrade = {
				category = "raging_bull",
				upgrade = "spread_multiplier",
				value = i
			}
		}
	end
	for i, _ in ipairs(self.values.raging_bull.reload_speed_multiplier) do
		local depends_on = i - 1 > 0 and "raging_bull_reload_speed" .. i - 1 or "raging_bull"
		local unlock_lvl = 61
		local prio = i == 1 and "high"
		self.definitions["raging_bull_reload_speed" .. i] = {
			tree = 3,
			step = self.steps.raging_bull.reload_speed_multiplier[i],
			category = "feature",
			name_id = "debug_upgrade_raging_bull_reload_speed" .. i,
			title_id = "debug_raging_bull_short",
			subtitle_id = "debug_upgrade_reload_speed" .. i,
			icon = "raging_bull",
			image = "upgrades_ragingbull",
			image_slice = "upgrades_ragingbull_slice",
			description_text_id = "reload_speed_multiplier",
			depends_on = depends_on,
			unlock_lvl = unlock_lvl,
			prio = prio,
			upgrade = {
				category = "raging_bull",
				upgrade = "reload_speed_multiplier",
				value = i
			}
		}
	end
	for i, _ in ipairs(self.values.raging_bull.damage_multiplier) do
		local depends_on = i - 1 > 0 and "raging_bull_damage" .. i - 1 or "raging_bull"
		local unlock_lvl = 61
		local prio = i == 1 and "high"
		self.definitions["raging_bull_damage" .. i] = {
			tree = 3,
			step = self.steps.raging_bull.damage_multiplier[i],
			category = "feature",
			name_id = "debug_upgrade_raging_bull_damage" .. i,
			title_id = "debug_raging_bull_short",
			subtitle_id = "debug_upgrade_damage" .. i,
			icon = "raging_bull",
			image = "upgrades_ragingbull",
			image_slice = "upgrades_ragingbull_slice",
			description_text_id = "damage_multiplier",
			depends_on = depends_on,
			unlock_lvl = unlock_lvl,
			prio = prio,
			upgrade = {
				category = "raging_bull",
				upgrade = "damage_multiplier",
				value = i
			}
		}
	end
end
function UpgradesTweakData:_m4_definitions()
	self.definitions.m4 = {
		category = "weapon",
		weapon_id = "m4",
		unit_name = Idstring("units/weapons/m4_rifle/m4_rifle"),
		name_id = "debug_m4_rifle",
		title_id = "debug_m4_rifle_short",
		icon = "m4",
		image = "upgrades_m4",
		image_slice = "upgrades_m4_slice",
		unlock_lvl = 0,
		prio = "high",
		description_text_id = "des_m4"
	}
	for i, _ in ipairs(self.values.m4.clip_ammo_increase) do
		local depends_on = 0 < i - 1 and "m4_mag" .. i - 1 or "m4"
		local unlock_lvl = 3
		local prio = i == 1 and "high"
		self.definitions["m4_mag" .. i] = {
			tree = 3,
			step = self.steps.m4.clip_ammo_increase[i],
			category = "feature",
			name_id = "debug_upgrade_m4_mag" .. i,
			title_id = "debug_m4_rifle_short",
			subtitle_id = "debug_upgrade_mag" .. i,
			icon = "m4",
			image = "upgrades_m4",
			image_slice = "upgrades_m4_slice",
			description_text_id = "clip_ammo_increase",
			depends_on = depends_on,
			unlock_lvl = unlock_lvl,
			prio = prio,
			upgrade = {
				category = "m4",
				upgrade = "clip_ammo_increase",
				value = i
			}
		}
	end
	for i, _ in ipairs(self.values.m4.spread_multiplier) do
		local depends_on = 0 < i - 1 and "m4_spread" .. i - 1 or "m4"
		local unlock_lvl = 4
		local prio = i == 1 and "high"
		self.definitions["m4_spread" .. i] = {
			tree = 2,
			step = self.steps.m4.spread_multiplier[i],
			category = "feature",
			name_id = "debug_upgrade_m4_spread" .. i,
			title_id = "debug_m4_rifle_short",
			subtitle_id = "debug_upgrade_spread" .. i,
			icon = "m4",
			image = "upgrades_m4",
			image_slice = "upgrades_m4_slice",
			description_text_id = "spread_multiplier",
			depends_on = depends_on,
			unlock_lvl = unlock_lvl,
			prio = prio,
			upgrade = {
				category = "m4",
				upgrade = "spread_multiplier",
				value = i
			}
		}
	end
	for i, _ in ipairs(self.values.m4.damage_multiplier) do
		local depends_on = 0 < i - 1 and "m4_damage" .. i - 1 or "m4"
		local unlock_lvl = 5
		local prio = i == 1 and "high"
		self.definitions["m4_damage" .. i] = {
			tree = 1,
			step = self.steps.m4.damage_multiplier[i],
			category = "feature",
			name_id = "debug_upgrade_m4_damage" .. i,
			title_id = "debug_m4_rifle_short",
			subtitle_id = "debug_upgrade_damage" .. i,
			icon = "m4",
			image = "upgrades_m4",
			image_slice = "upgrades_m4_slice",
			description_text_id = "damage_multiplier",
			depends_on = depends_on,
			unlock_lvl = unlock_lvl,
			prio = prio,
			upgrade = {
				category = "m4",
				upgrade = "damage_multiplier",
				value = i
			}
		}
	end
end
function UpgradesTweakData:_m14_definitions()
	self.definitions.m14 = {
		tree = 2,
		step = 17,
		category = "weapon",
		weapon_id = "m14",
		unit_name = Idstring("units/weapons/m14/m14"),
		name_id = "debug_m14",
		title_id = "debug_upgrade_new_weapon",
		subtitle_id = "debug_m14_short",
		icon = "m14",
		image = "upgrades_m14",
		image_slice = "upgrades_m14_slice",
		unlock_lvl = 101,
		prio = "high",
		description_text_id = "des_m14"
	}
	for i, _ in ipairs(self.values.m14.clip_ammo_increase) do
		local depends_on = i - 1 > 0 and "m14_mag" .. i - 1 or "m14"
		local unlock_lvl = 102
		local prio = i == 1 and "high"
		self.definitions["m14_mag" .. i] = {
			tree = 2,
			step = self.steps.m14.clip_ammo_increase[i],
			category = "feature",
			name_id = "debug_upgrade_m14_mag" .. i,
			title_id = "debug_m14_short",
			subtitle_id = "debug_upgrade_mag" .. i,
			icon = "m14",
			image = "upgrades_m14",
			image_slice = "upgrades_m14_slice",
			description_text_id = "clip_ammo_increase",
			depends_on = depends_on,
			unlock_lvl = unlock_lvl,
			prio = prio,
			upgrade = {
				category = "m14",
				upgrade = "clip_ammo_increase",
				value = i
			}
		}
	end
	for i, _ in ipairs(self.values.m14.spread_multiplier) do
		local depends_on = i - 1 > 0 and "m14_spread" .. i - 1 or "m14"
		local unlock_lvl = 102
		local prio = i == 1 and "high"
		self.definitions["m14_spread" .. i] = {
			tree = 2,
			step = self.steps.m14.spread_multiplier[i],
			category = "feature",
			name_id = "debug_upgrade_m14_spread" .. i,
			title_id = "debug_m14_short",
			subtitle_id = "debug_upgrade_spread" .. i,
			icon = "m14",
			image = "upgrades_m14",
			image_slice = "upgrades_m14_slice",
			description_text_id = "spread_multiplier",
			depends_on = depends_on,
			unlock_lvl = unlock_lvl,
			prio = prio,
			upgrade = {
				category = "m14",
				upgrade = "spread_multiplier",
				value = i
			}
		}
	end
	for i, _ in ipairs(self.values.m14.damage_multiplier) do
		local depends_on = i - 1 > 0 and "m14_damage" .. i - 1 or "m14"
		local unlock_lvl = 102
		local prio = i == 1 and "high"
		self.definitions["m14_damage" .. i] = {
			tree = 2,
			step = self.steps.m14.damage_multiplier[i],
			category = "feature",
			name_id = "debug_upgrade_m14_damage" .. i,
			title_id = "debug_m14_short",
			subtitle_id = "debug_upgrade_damage" .. i,
			icon = "m14",
			image = "upgrades_m14",
			image_slice = "upgrades_m14_slice",
			description_text_id = "damage_multiplier",
			depends_on = depends_on,
			unlock_lvl = unlock_lvl,
			prio = prio,
			upgrade = {
				category = "m14",
				upgrade = "damage_multiplier",
				value = i
			}
		}
	end
	for i, _ in ipairs(self.values.m14.recoil_multiplier) do
		local depends_on = i - 1 > 0 and "m14_recoil" .. i - 1 or "m14"
		local unlock_lvl = 102
		local prio = i == 1 and "high"
		self.definitions["m14_recoil" .. i] = {
			tree = 2,
			step = self.steps.m14.recoil_multiplier[i],
			category = "feature",
			name_id = "debug_upgrade_m14_recoil" .. i,
			title_id = "debug_m14_short",
			subtitle_id = "debug_upgrade_recoil" .. i,
			icon = "m14",
			image = "upgrades_m14",
			image_slice = "upgrades_m14_slice",
			description_text_id = "recoil_multiplier",
			depends_on = depends_on,
			unlock_lvl = unlock_lvl,
			prio = prio,
			upgrade = {
				category = "m14",
				upgrade = "recoil_multiplier",
				value = i
			}
		}
	end
end
function UpgradesTweakData:_mp5_definitions()
	self.definitions.mp5 = {
		tree = 3,
		step = 21,
		category = "weapon",
		weapon_id = "mp5",
		unit_name = Idstring("units/weapons/mp5/mp5"),
		name_id = "debug_mp5",
		title_id = "debug_upgrade_new_weapon",
		subtitle_id = "debug_mp5_short",
		icon = "mp5",
		image = "upgrades_mp5",
		image_slice = "upgrades_mp5_slice",
		unlock_lvl = 6,
		prio = "high",
		description_text_id = "des_mp5"
	}
	for i, _ in ipairs(self.values.mp5.spread_multiplier) do
		local depends_on = i - 1 > 0 and "mp5_spread" .. i - 1 or "mp5"
		local unlock_lvl = 7
		local prio = i == 1 and "high"
		self.definitions["mp5_spread" .. i] = {
			tree = 3,
			step = self.steps.mp5.spread_multiplier[i],
			category = "feature",
			name_id = "debug_upgrade_mp5_spread" .. i,
			title_id = "debug_mp5_short",
			subtitle_id = "debug_upgrade_spread" .. i,
			icon = "mp5",
			image = "upgrades_mp5",
			image_slice = "upgrades_mp5_slice",
			description_text_id = "spread_multiplier",
			depends_on = depends_on,
			unlock_lvl = unlock_lvl,
			prio = prio,
			upgrade = {
				category = "mp5",
				upgrade = "spread_multiplier",
				value = i
			}
		}
	end
	for i, _ in ipairs(self.values.mp5.recoil_multiplier) do
		local depends_on = i - 1 > 0 and "mp5_recoil" .. i - 1 or "mp5"
		local unlock_lvl = 8
		local prio = i == 1 and "high"
		self.definitions["mp5_recoil" .. i] = {
			tree = 3,
			step = self.steps.mp5.recoil_multiplier[i],
			category = "feature",
			name_id = "debug_upgrade_mp5_recoil" .. i,
			title_id = "debug_mp5_short",
			subtitle_id = "debug_upgrade_recoil" .. i,
			icon = "mp5",
			image = "upgrades_mp5",
			image_slice = "upgrades_mp5_slice",
			description_text_id = "recoil_multiplier",
			depends_on = depends_on,
			unlock_lvl = unlock_lvl,
			prio = prio,
			upgrade = {
				category = "mp5",
				upgrade = "recoil_multiplier",
				value = i
			}
		}
	end
	for i, _ in ipairs(self.values.mp5.reload_speed_multiplier) do
		local depends_on = i - 1 > 0 and "mp5_reload_speed" .. i - 1 or "mp5"
		local unlock_lvl = 9
		local prio = i == 1 and "high"
		self.definitions["mp5_reload_speed" .. i] = {
			tree = 3,
			step = self.steps.mp5.reload_speed_multiplier[i],
			category = "feature",
			name_id = "debug_upgrade_mp5_reload_speed" .. i,
			title_id = "debug_mp5_short",
			subtitle_id = "debug_upgrade_reload_speed" .. i,
			icon = "mp5",
			image = "upgrades_mp5",
			image_slice = "upgrades_mp5_slice",
			description_text_id = "reload_speed_multiplier",
			depends_on = depends_on,
			unlock_lvl = unlock_lvl,
			prio = prio,
			upgrade = {
				category = "mp5",
				upgrade = "reload_speed_multiplier",
				value = i
			}
		}
	end
	for i, _ in ipairs(self.values.mp5.enter_steelsight_speed_multiplier) do
		local depends_on = i - 1 > 0 and "mp5_enter_steelsight_speed" .. i - 1 or "mp5"
		local unlock_lvl = 10
		local prio = i == 1 and "high"
		self.definitions["mp5_enter_steelsight_speed" .. i] = {
			tree = 3,
			step = self.steps.mp5.enter_steelsight_speed_multiplier[i],
			category = "feature",
			name_id = "debug_upgrade_mp5_enter_steelsight_speed" .. i,
			title_id = "debug_mp5_short",
			subtitle_id = "debug_upgrade_enter_steelsight_speed" .. i,
			icon = "mp5",
			image = "upgrades_mp5",
			image_slice = "upgrades_mp5_slice",
			description_text_id = "enter_steelsight_speed_multiplier",
			depends_on = depends_on,
			unlock_lvl = unlock_lvl,
			prio = prio,
			upgrade = {
				category = "mp5",
				upgrade = "enter_steelsight_speed_multiplier",
				value = i
			}
		}
	end
end
function UpgradesTweakData:_mac11_definitions()
	self.definitions.mac11 = {
		tree = 1,
		step = 5,
		category = "weapon",
		weapon_id = "mac11",
		unit_name = Idstring("units/weapons/mac11/mac11"),
		name_id = "debug_mac11",
		title_id = "debug_upgrade_new_weapon",
		subtitle_id = "debug_mac11_short",
		icon = "mac11",
		image = "upgrades_mac10",
		image_slice = "upgrades_mac10_slice",
		unlock_lvl = 81,
		prio = "high",
		description_text_id = "des_mac11"
	}
	for i, _ in ipairs(self.values.mac11.recoil_multiplier) do
		local depends_on = i - 1 > 0 and "mac11_recoil" .. i - 1 or "mac11"
		local unlock_lvl = 82
		local prio = i == 1 and "high"
		self.definitions["mac11_recoil" .. i] = {
			tree = 1,
			step = self.steps.mac11.recoil_multiplier[i],
			category = "feature",
			name_id = "debug_upgrade_mac11_recoil" .. i,
			title_id = "debug_mac11_short",
			subtitle_id = "debug_upgrade_recoil" .. i,
			icon = "mac11",
			image = "upgrades_mac10",
			image_slice = "upgrades_mac10_slice",
			description_text_id = "recoil_multiplier",
			depends_on = depends_on,
			unlock_lvl = unlock_lvl,
			prio = prio,
			upgrade = {
				category = "mac11",
				upgrade = "recoil_multiplier",
				value = i
			}
		}
	end
	for i, _ in ipairs(self.values.mac11.enter_steelsight_speed_multiplier) do
		local depends_on = i - 1 > 0 and "mac11_enter_steelsight_speed" .. i - 1 or "mac11"
		local unlock_lvl = 82
		local prio = i == 1 and "high"
		self.definitions["mac11_enter_steelsight_speed" .. i] = {
			tree = 1,
			step = self.steps.mac11.enter_steelsight_speed_multiplier[i],
			category = "feature",
			name_id = "debug_upgrade_mac11_enter_steelsight_speed" .. i,
			title_id = "debug_mac11_short",
			subtitle_id = "debug_upgrade_enter_steelsight_speed" .. i,
			icon = "mac11",
			image = "upgrades_mac10",
			image_slice = "upgrades_mac10_slice",
			description_text_id = "enter_steelsight_speed_multiplier",
			depends_on = depends_on,
			unlock_lvl = unlock_lvl,
			prio = prio,
			upgrade = {
				category = "mac11",
				upgrade = "enter_steelsight_speed_multiplier",
				value = i
			}
		}
	end
	for i, _ in ipairs(self.values.mac11.clip_ammo_increase) do
		local depends_on = i - 1 > 0 and "mac11_mag" .. i - 1 or "mac11"
		local unlock_lvl = 82
		local prio = i == 1 and "high"
		self.definitions["mac11_mag" .. i] = {
			tree = 1,
			step = self.steps.mac11.clip_ammo_increase[i],
			category = "feature",
			name_id = "debug_upgrade_mac11_mag" .. i,
			title_id = "debug_mac11_short",
			subtitle_id = "debug_upgrade_mag" .. i,
			icon = "mac11",
			image = "upgrades_mac10",
			image_slice = "upgrades_mac10_slice",
			description_text_id = "clip_ammo_increase",
			depends_on = depends_on,
			unlock_lvl = unlock_lvl,
			prio = prio,
			upgrade = {
				category = "mac11",
				upgrade = "clip_ammo_increase",
				value = i
			}
		}
	end
end
function UpgradesTweakData:_remington_definitions()
	self.definitions.r870_shotgun = {
		tree = 3,
		step = 13,
		category = "weapon",
		weapon_id = "r870_shotgun",
		unit_name = Idstring("units/weapons/r870_shotgun/r870_shotgun"),
		name_id = "debug_r870_shotgun",
		title_id = "debug_upgrade_new_weapon",
		subtitle_id = "debug_r870_shotgun_short",
		icon = "r870_shotgun",
		image = "upgrades_remington",
		image_slice = "upgrades_remington_slice",
		unlock_lvl = 1,
		prio = "high",
		description_text_id = "des_r870_shotgun"
	}
	for i, _ in ipairs(self.values.r870_shotgun.clip_ammo_increase) do
		local depends_on = i - 1 > 0 and "remington_mag" .. i - 1 or "r870_shotgun"
		local unlock_lvl = 2
		local prio = i == 1 and "high"
		self.definitions["remington_mag" .. i] = {
			tree = 3,
			step = self.steps.r870_shotgun.clip_ammo_increase[i],
			category = "feature",
			name_id = "debug_upgrade_remington_mag" .. i,
			title_id = "debug_r870_shotgun_short",
			subtitle_id = "debug_upgrade_mag" .. i,
			icon = "r870_shotgun",
			image = "upgrades_remington",
			image_slice = "upgrades_remington_slice",
			description_text_id = "clip_ammo_increase",
			depends_on = depends_on,
			unlock_lvl = unlock_lvl,
			prio = prio,
			upgrade = {
				category = "r870_shotgun",
				upgrade = "clip_ammo_increase",
				value = i
			}
		}
	end
	for i, _ in ipairs(self.values.r870_shotgun.recoil_multiplier) do
		local depends_on = i - 1 > 0 and "remington_recoil" .. i - 1 or "r870_shotgun"
		local unlock_lvl = 3
		local prio = i == 1 and "high"
		self.definitions["remington_recoil" .. i] = {
			tree = 3,
			step = self.steps.r870_shotgun.recoil_multiplier[i],
			category = "feature",
			name_id = "debug_upgrade_remington_recoil" .. i,
			title_id = "debug_r870_shotgun_short",
			subtitle_id = "debug_upgrade_recoil" .. i,
			icon = "r870_shotgun",
			image = "upgrades_remington",
			image_slice = "upgrades_remington_slice",
			description_text_id = "recoil_multiplier",
			depends_on = depends_on,
			unlock_lvl = unlock_lvl,
			prio = prio,
			upgrade = {
				category = "r870_shotgun",
				upgrade = "recoil_multiplier",
				value = i
			}
		}
	end
	for i, _ in ipairs(self.values.r870_shotgun.damage_multiplier) do
		local depends_on = i - 1 > 0 and "remington_damage" .. i - 1 or "r870_shotgun"
		local unlock_lvl = 4
		local prio = i == 1 and "high"
		self.definitions["remington_damage" .. i] = {
			tree = 3,
			step = self.steps.r870_shotgun.damage_multiplier[i],
			category = "feature",
			name_id = "debug_upgrade_remington_damage" .. i,
			title_id = "debug_r870_shotgun_short",
			subtitle_id = "debug_upgrade_damage" .. i,
			icon = "r870_shotgun",
			image = "upgrades_remington",
			image_slice = "upgrades_remington_slice",
			description_text_id = "damage_multiplier",
			depends_on = depends_on,
			unlock_lvl = unlock_lvl,
			prio = prio,
			upgrade = {
				category = "r870_shotgun",
				upgrade = "damage_multiplier",
				value = i
			}
		}
	end
end
function UpgradesTweakData:_mossberg_definitions()
	self.definitions.mossberg = {
		tree = 2,
		step = 7,
		category = "weapon",
		weapon_id = "mossberg",
		unit_name = Idstring("units/weapons/mossberg/mossberg"),
		name_id = "debug_mossberg",
		title_id = "debug_upgrade_new_weapon",
		subtitle_id = "debug_mossberg_short",
		icon = "mossberg",
		image = "upgrades_mossberg",
		image_slice = "upgrades_mossberg_slice",
		unlock_lvl = 120,
		prio = "high",
		description_text_id = "des_mossberg"
	}
	for i, _ in ipairs(self.values.mossberg.clip_ammo_increase) do
		local depends_on = i - 1 > 0 and "mossberg_mag" .. i - 1 or "mossberg"
		local unlock_lvl = 121
		local prio = i == 1 and "high"
		self.definitions["mossberg_mag" .. i] = {
			tree = 2,
			step = self.steps.mossberg.clip_ammo_increase[i],
			category = "feature",
			name_id = "debug_upgrade_mossberg_mag" .. i,
			title_id = "debug_mossberg_short",
			subtitle_id = "debug_upgrade_mag" .. i,
			icon = "mossberg",
			image = "upgrades_mossberg",
			image_slice = "upgrades_mossberg_slice",
			description_text_id = "clip_ammo_increase",
			depends_on = depends_on,
			unlock_lvl = unlock_lvl,
			prio = prio,
			upgrade = {
				category = "mossberg",
				upgrade = "clip_ammo_increase",
				value = i
			}
		}
	end
	for i, _ in ipairs(self.values.mossberg.reload_speed_multiplier) do
		local depends_on = i - 1 > 0 and "mossberg_reload_speed" .. i - 1 or "mossberg"
		local unlock_lvl = 121
		local prio = i == 1 and "high"
		self.definitions["mossberg_reload_speed" .. i] = {
			tree = 2,
			step = self.steps.mossberg.reload_speed_multiplier[i],
			category = "feature",
			name_id = "debug_upgrade_mossberg_reload_speed" .. i,
			title_id = "debug_mossberg_short",
			subtitle_id = "debug_upgrade_reload_speed" .. i,
			icon = "mossberg",
			image = "upgrades_mossberg",
			image_slice = "upgrades_mossberg_slice",
			description_text_id = "reload_speed_multiplier",
			depends_on = depends_on,
			unlock_lvl = unlock_lvl,
			prio = prio,
			upgrade = {
				category = "mossberg",
				upgrade = "reload_speed_multiplier",
				value = i
			}
		}
	end
	for i, _ in ipairs(self.values.mossberg.fire_rate_multiplier) do
		local depends_on = i - 1 > 0 and "mossberg_fire_rate_multiplier" .. i - 1 or "mossberg"
		local unlock_lvl = 121
		local prio = i == 1 and "high"
		self.definitions["mossberg_fire_rate_multiplier" .. i] = {
			tree = 2,
			step = self.steps.mossberg.fire_rate_multiplier[i],
			category = "feature",
			name_id = "debug_upgrade_mossberg_fire_rate" .. i,
			title_id = "debug_mossberg_short",
			subtitle_id = "debug_upgrade_fire_rate" .. i,
			icon = "mossberg",
			image = "upgrades_mossberg",
			image_slice = "upgrades_mossberg_slice",
			description_text_id = "fire_rate_multiplier",
			depends_on = depends_on,
			unlock_lvl = unlock_lvl,
			prio = prio,
			upgrade = {
				category = "mossberg",
				upgrade = "fire_rate_multiplier",
				value = i
			}
		}
	end
	for i, _ in ipairs(self.values.mossberg.recoil_multiplier) do
		local depends_on = i - 1 > 0 and "mossberg_recoil_multiplier" .. i - 1 or "mossberg"
		local unlock_lvl = 121
		local prio = i == 1 and "high"
		self.definitions["mossberg_recoil_multiplier" .. i] = {
			tree = 2,
			step = self.steps.mossberg.recoil_multiplier[i],
			category = "feature",
			name_id = "debug_upgrade_mossberg_recoil_multiplier" .. i,
			title_id = "debug_mossberg_short",
			subtitle_id = "debug_upgrade_recoil" .. i,
			icon = "mossberg",
			image = "upgrades_mossberg",
			image_slice = "upgrades_mossberg_slice",
			description_text_id = "recoil_multiplier",
			depends_on = depends_on,
			unlock_lvl = unlock_lvl,
			prio = prio,
			upgrade = {
				category = "mossberg",
				upgrade = "recoil_multiplier",
				value = i
			}
		}
	end
end
function UpgradesTweakData:_hk21_definitions()
	self.definitions.hk21 = {
		tree = 1,
		step = 22,
		category = "weapon",
		weapon_id = "hk21",
		unit_name = Idstring("units/weapons/hk21/hk21"),
		name_id = "debug_hk21",
		title_id = "debug_upgrade_new_weapon",
		subtitle_id = "debug_hk21_short",
		icon = "hk21",
		image = "upgrades_hk21",
		image_slice = "upgrades_hk21_slice",
		unlock_lvl = 140,
		prio = "high",
		description_text_id = "des_hk21"
	}
	for i, _ in ipairs(self.values.hk21.clip_ammo_increase) do
		local depends_on = i - 1 > 0 and "hk21_mag" .. i - 1 or "hk21"
		local unlock_lvl = 141
		local prio = i == 1 and "high"
		self.definitions["hk21_mag" .. i] = {
			tree = 1,
			step = self.steps.hk21.clip_ammo_increase[i],
			category = "feature",
			name_id = "debug_upgrade_hk21_mag" .. i,
			title_id = "debug_hk21_short",
			subtitle_id = "debug_upgrade_mag" .. i,
			icon = "hk21",
			image = "upgrades_hk21",
			image_slice = "upgrades_hk21_slice",
			description_text_id = "clip_ammo_increase",
			depends_on = depends_on,
			unlock_lvl = unlock_lvl,
			prio = prio,
			upgrade = {
				category = "hk21",
				upgrade = "clip_ammo_increase",
				value = i
			}
		}
	end
	for i, _ in ipairs(self.values.hk21.recoil_multiplier) do
		local depends_on = i - 1 > 0 and "hk21_recoil" .. i - 1 or "hk21"
		local unlock_lvl = 141
		local prio = i == 1 and "high"
		self.definitions["hk21_recoil" .. i] = {
			tree = 1,
			step = self.steps.hk21.recoil_multiplier[i],
			category = "feature",
			name_id = "debug_upgrade_hk21_recoil" .. i,
			title_id = "debug_hk21_short",
			subtitle_id = "debug_upgrade_recoil" .. i,
			icon = "hk21",
			image = "upgrades_hk21",
			image_slice = "upgrades_hk21_slice",
			description_text_id = "recoil_multiplier",
			depends_on = depends_on,
			unlock_lvl = unlock_lvl,
			prio = prio,
			upgrade = {
				category = "hk21",
				upgrade = "recoil_multiplier",
				value = i
			}
		}
	end
	for i, _ in ipairs(self.values.hk21.damage_multiplier) do
		local depends_on = i - 1 > 0 and "hk21_damage" .. i - 1 or "hk21"
		local unlock_lvl = 141
		local prio = i == 1 and "high"
		self.definitions["hk21_damage" .. i] = {
			tree = 1,
			step = self.steps.hk21.damage_multiplier[i],
			category = "feature",
			name_id = "debug_upgrade_hk21_damage" .. i,
			title_id = "debug_hk21_short",
			subtitle_id = "debug_upgrade_damage" .. i,
			icon = "hk21",
			image = "upgrades_hk21",
			image_slice = "upgrades_hk21_slice",
			description_text_id = "damage_multiplier",
			depends_on = depends_on,
			unlock_lvl = unlock_lvl,
			prio = prio,
			upgrade = {
				category = "hk21",
				upgrade = "damage_multiplier",
				value = i
			}
		}
	end
end
function UpgradesTweakData:_ak47_definitions()
	self.definitions.ak47 = {
		tree = 4,
		step = 9,
		category = "weapon",
		weapon_id = "ak47",
		unit_name = Idstring("units/weapons/ak47/ak"),
		name_id = "debug_ak47",
		title_id = "debug_upgrade_new_weapon",
		subtitle_id = "debug_ak47_short",
		icon = "ak",
		image = "upgrades_ak",
		image_slice = "upgrades_ak_slice",
		unlock_lvl = 0,
		prio = "high",
		description_text_id = "des_ak47"
	}
	for i, _ in ipairs(self.values.ak47.damage_multiplier) do
		local depends_on = 0 < i - 1 and "ak47_damage" .. i - 1 or "ak47"
		local unlock_lvl = 141
		local prio = i == 1 and "high"
		self.definitions["ak47_damage" .. i] = {
			tree = 4,
			step = self.steps.ak47.damage_multiplier[i],
			category = "feature",
			name_id = "debug_upgrade_ak47_damage" .. i,
			title_id = "debug_ak47_short",
			subtitle_id = "debug_upgrade_damage" .. i,
			icon = "ak",
			image = "upgrades_ak",
			image_slice = "upgrades_ak_slice",
			description_text_id = "damage_multiplier",
			depends_on = depends_on,
			unlock_lvl = unlock_lvl,
			prio = prio,
			upgrade = {
				category = "ak47",
				upgrade = "damage_multiplier",
				value = i
			}
		}
	end
	for i, _ in ipairs(self.values.ak47.recoil_multiplier) do
		local depends_on = 0 < i - 1 and "ak47_recoil" .. i - 1 or "ak47"
		local unlock_lvl = 141
		local prio = i == 1 and "high"
		self.definitions["ak47_recoil" .. i] = {
			tree = 4,
			step = self.steps.ak47.recoil_multiplier[i],
			category = "feature",
			name_id = "debug_upgrade_ak47_recoil" .. i,
			title_id = "debug_ak47_short",
			subtitle_id = "debug_upgrade_recoil" .. i,
			icon = "ak",
			image = "upgrades_ak",
			image_slice = "upgrades_ak_slice",
			description_text_id = "recoil_multiplier",
			depends_on = depends_on,
			unlock_lvl = unlock_lvl,
			prio = prio,
			upgrade = {
				category = "ak47",
				upgrade = "recoil_multiplier",
				value = i
			}
		}
	end
	for i, _ in ipairs(self.values.ak47.spread_multiplier) do
		local depends_on = 0 < i - 1 and "ak47_spread" .. i - 1 or "ak47"
		local unlock_lvl = 141
		local prio = i == 1 and "high"
		self.definitions["ak47_spread" .. i] = {
			tree = 4,
			step = self.steps.ak47.spread_multiplier[i],
			category = "feature",
			name_id = "debug_upgrade_ak47_spread" .. i,
			title_id = "debug_ak47_short",
			subtitle_id = "debug_upgrade_spread" .. i,
			icon = "ak",
			image = "upgrades_ak",
			image_slice = "upgrades_ak_slice",
			description_text_id = "spread_multiplier",
			depends_on = depends_on,
			unlock_lvl = unlock_lvl,
			prio = prio,
			upgrade = {
				category = "ak47",
				upgrade = "spread_multiplier",
				value = i
			}
		}
	end
	for i, _ in ipairs(self.values.ak47.clip_ammo_increase) do
		local depends_on = 0 < i - 1 and "ak47_mag" .. i - 1 or "ak47"
		local unlock_lvl = 141
		local prio = i == 1 and "high"
		self.definitions["ak47_mag" .. i] = {
			tree = 4,
			step = self.steps.ak47.clip_ammo_increase[i],
			category = "feature",
			name_id = "debug_upgrade_ak47_mag" .. i,
			title_id = "debug_ak47_short",
			subtitle_id = "debug_upgrade_mag" .. i,
			icon = "ak",
			image = "upgrades_ak",
			image_slice = "upgrades_ak_slice",
			description_text_id = "clip_ammo_increase",
			depends_on = depends_on,
			unlock_lvl = unlock_lvl,
			prio = prio,
			upgrade = {
				category = "ak47",
				upgrade = "clip_ammo_increase",
				value = i
			}
		}
	end
end
function UpgradesTweakData:_glock_definitions()
	self.definitions.glock = {
		tree = 4,
		step = 2,
		category = "weapon",
		weapon_id = "glock",
		unit_name = Idstring("units/weapons/glock/glock"),
		name_id = "debug_glock",
		title_id = "debug_upgrade_new_weapon",
		subtitle_id = "debug_glock_short",
		icon = "glock",
		image = "upgrades_glock",
		image_slice = "upgrades_glock_slice",
		unlock_lvl = 0,
		prio = "high",
		description_text_id = "des_glock"
	}
	for i, _ in ipairs(self.values.glock.damage_multiplier) do
		local depends_on = 0 < i - 1 and "glock_damage" .. i - 1 or "glock"
		local unlock_lvl = 141
		local prio = i == 1 and "high"
		self.definitions["glock_damage" .. i] = {
			tree = 4,
			step = self.steps.glock.damage_multiplier[i],
			category = "feature",
			name_id = "debug_upgrade_glock_damage" .. i,
			title_id = "debug_glock_short",
			subtitle_id = "debug_upgrade_damage" .. i,
			icon = "glock",
			image = "upgrades_glock",
			image_slice = "upgrades_glock_slice",
			description_text_id = "damage_multiplier",
			depends_on = depends_on,
			unlock_lvl = unlock_lvl,
			prio = prio,
			upgrade = {
				category = "glock",
				upgrade = "damage_multiplier",
				value = i
			}
		}
	end
	for i, _ in ipairs(self.values.glock.recoil_multiplier) do
		local depends_on = 0 < i - 1 and "glock_recoil" .. i - 1 or "glock"
		local unlock_lvl = 141
		local prio = i == 1 and "high"
		self.definitions["glock_recoil" .. i] = {
			tree = 4,
			step = self.steps.glock.recoil_multiplier[i],
			category = "feature",
			name_id = "debug_upgrade_glock_recoil" .. i,
			title_id = "debug_glock_short",
			subtitle_id = "debug_upgrade_recoil" .. i,
			icon = "glock",
			image = "upgrades_glock",
			image_slice = "upgrades_glock_slice",
			description_text_id = "recoil_multiplier",
			depends_on = depends_on,
			unlock_lvl = unlock_lvl,
			prio = prio,
			upgrade = {
				category = "glock",
				upgrade = "recoil_multiplier",
				value = i
			}
		}
	end
	for i, _ in ipairs(self.values.glock.clip_ammo_increase) do
		local depends_on = 0 < i - 1 and "glock_mag" .. i - 1 or "glock"
		local unlock_lvl = 141
		local prio = i == 1 and "high"
		self.definitions["glock_mag" .. i] = {
			tree = 4,
			step = self.steps.glock.clip_ammo_increase[i],
			category = "feature",
			name_id = "debug_upgrade_glock_mag" .. i,
			title_id = "debug_glock_short",
			subtitle_id = "debug_upgrade_mag" .. i,
			icon = "glock",
			image = "upgrades_glock",
			image_slice = "upgrades_glock_slice",
			description_text_id = "clip_ammo_increase",
			depends_on = depends_on,
			unlock_lvl = unlock_lvl,
			prio = prio,
			upgrade = {
				category = "glock",
				upgrade = "clip_ammo_increase",
				value = i
			}
		}
	end
	for i, _ in ipairs(self.values.glock.reload_speed_multiplier) do
		local depends_on = 0 < i - 1 and "glock_reload_speed" .. i - 1 or "glock"
		local unlock_lvl = 141
		local prio = i == 1 and "high"
		self.definitions["glock_reload_speed" .. i] = {
			tree = 4,
			step = self.steps.glock.reload_speed_multiplier[i],
			category = "feature",
			name_id = "debug_upgrade_glock_reload_speed" .. i,
			title_id = "debug_glock_short",
			subtitle_id = "debug_upgrade_reload_speed" .. i,
			icon = "glock",
			image = "upgrades_glock",
			image_slice = "upgrades_glock_slice",
			description_text_id = "reload_speed_multiplier",
			depends_on = depends_on,
			unlock_lvl = unlock_lvl,
			prio = prio,
			upgrade = {
				category = "glock",
				upgrade = "reload_speed_multiplier",
				value = i
			}
		}
	end
end
function UpgradesTweakData:_m79_definitions()
	self.definitions.m79 = {
		tree = 4,
		step = 21,
		category = "weapon",
		weapon_id = "m79",
		unit_name = Idstring("units/weapons/m79/m79"),
		name_id = "debug_m79",
		title_id = "debug_upgrade_new_weapon",
		subtitle_id = "debug_m79_short",
		icon = "m79",
		image = "upgrades_grenade",
		image_slice = "upgrades_grenade_slice",
		unlock_lvl = 0,
		prio = "high",
		description_text_id = "des_m79"
	}
	for i, _ in ipairs(self.values.m79.damage_multiplier) do
		local depends_on = 0 < i - 1 and "m79_damage" .. i - 1 or "m79"
		local unlock_lvl = 141
		local prio = i == 1 and "high"
		self.definitions["m79_damage" .. i] = {
			tree = 4,
			step = self.steps.m79.damage_multiplier[i],
			category = "feature",
			name_id = "debug_upgrade_m79_damage" .. i,
			title_id = "debug_m79_short",
			subtitle_id = "debug_upgrade_damage" .. i,
			icon = "m79",
			image = "upgrades_grenade",
			image_slice = "upgrades_grenade_slice",
			description_text_id = "damage_multiplier",
			depends_on = depends_on,
			unlock_lvl = unlock_lvl,
			prio = prio,
			upgrade = {
				category = "m79",
				upgrade = "damage_multiplier",
				value = i
			}
		}
	end
	for i, _ in ipairs(self.values.m79.explosion_range_multiplier) do
		local depends_on = 0 < i - 1 and "m79_expl_range" .. i - 1 or "m79"
		local unlock_lvl = 141
		local prio = i == 1 and "high"
		self.definitions["m79_expl_range" .. i] = {
			tree = 4,
			step = self.steps.m79.explosion_range_multiplier[i],
			category = "feature",
			name_id = "debug_upgrade_m79_expl_range" .. i,
			title_id = "debug_m79_short",
			subtitle_id = "debug_upgrade_expl_range" .. i,
			icon = "m79",
			image = "upgrades_grenade",
			image_slice = "upgrades_grenade_slice",
			description_text_id = "explosion_range_multiplier",
			depends_on = depends_on,
			unlock_lvl = unlock_lvl,
			prio = prio,
			upgrade = {
				category = "m79",
				upgrade = "explosion_range_multiplier",
				value = i
			}
		}
	end
	for i, _ in ipairs(self.values.m79.clip_amount_increase) do
		local depends_on = 0 < i - 1 and "m79_clip_num" .. i - 1 or "m79"
		local unlock_lvl = 141
		local prio = i == 1 and "high"
		self.definitions["m79_clip_num" .. i] = {
			tree = 4,
			step = self.steps.m79.clip_amount_increase[i],
			category = "feature",
			name_id = "debug_upgrade_m79_clip_num" .. i,
			title_id = "debug_m79_short",
			subtitle_id = "debug_upgrade_clip_num" .. i,
			icon = "m79",
			image = "upgrades_grenade",
			image_slice = "upgrades_grenade_slice",
			description_text_id = "clip_amount_increase",
			depends_on = depends_on,
			unlock_lvl = unlock_lvl,
			prio = prio,
			upgrade = {
				category = "m79",
				upgrade = "clip_amount_increase",
				value = i
			}
		}
	end
end
