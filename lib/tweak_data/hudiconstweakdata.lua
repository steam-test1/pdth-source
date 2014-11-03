HudIconsTweakData = HudIconsTweakData or class()
function HudIconsTweakData:init()
	self.fallback = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			480,
			0,
			32,
			32
		}
	}
	self.develop = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			0,
			192,
			48,
			48
		}
	}
	self.locked = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			192,
			144,
			48,
			48
		}
	}
	self.loading = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			464,
			96,
			32,
			32
		}
	}
	self.beretta92 = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			0,
			0,
			48,
			48
		}
	}
	self.m4 = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			48,
			0,
			48,
			48
		}
	}
	self.r870_shotgun = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			96,
			0,
			48,
			48
		}
	}
	self.mp5 = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			144,
			0,
			48,
			48
		}
	}
	self.c45 = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			192,
			0,
			48,
			48
		}
	}
	self.raging_bull = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			240,
			0,
			48,
			48
		}
	}
	self.mossberg = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			288,
			0,
			48,
			48
		}
	}
	self.hk21 = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			384,
			0,
			48,
			48
		}
	}
	self.m14 = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			336,
			0,
			48,
			48
		}
	}
	self.mac11 = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			432,
			0,
			48,
			48
		}
	}
	self.glock = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			368,
			288,
			48,
			48
		}
	}
	self.ak = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			416,
			288,
			48,
			48
		}
	}
	self.m79 = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			464,
			288,
			48,
			48
		}
	}
	self.crew_bonus_aggressor = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			0,
			48,
			48,
			48
		}
	}
	self.crew_bonus_more_blood_to_bleed = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			96,
			48,
			48,
			48
		}
	}
	self.crew_bonus_mr_nice_guy = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			144,
			48,
			48,
			48
		}
	}
	self.crew_bonus_protector = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			192,
			48,
			48,
			48
		}
	}
	self.crew_bonus_sharpshooters = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			240,
			48,
			48,
			48
		}
	}
	self.crew_bonus_speed_reloaders = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			288,
			48,
			48,
			48
		}
	}
	self.crew_bonus_three_angry_men = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			336,
			48,
			48,
			48
		}
	}
	self.crew_bonus_welcome_to_the_gang = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			384,
			48,
			48,
			48
		}
	}
	self.crew_bonus_more_ammo = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			48,
			144,
			48,
			48
		}
	}
	self.equipment_toolset = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			48,
			48,
			48,
			48
		}
	}
	self.wp_vial = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			240,
			310,
			32,
			32
		}
	}
	self.wp_arrow = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			432,
			48,
			32,
			15
		}
	}
	self.wp_standard = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			432,
			64,
			32,
			32
		}
	}
	self.wp_revive = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			464,
			64,
			32,
			32
		}
	}
	self.wp_rescue = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			464,
			96,
			32,
			32
		}
	}
	self.wp_trade = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			432,
			96,
			32,
			32
		}
	}
	self.wp_powersupply = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			70,
			242,
			32,
			32
		}
	}
	self.wp_watersupply = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			104,
			242,
			32,
			32
		}
	}
	self.wp_drill = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			2,
			242,
			32,
			32
		}
	}
	self.wp_hack = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			2,
			276,
			32,
			32
		}
	}
	self.wp_talk = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			36,
			276,
			32,
			32
		}
	}
	self.wp_c4 = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			36,
			242,
			32,
			32
		}
	}
	self.wp_crowbar = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			70,
			276,
			32,
			32
		}
	}
	self.wp_planks = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			104,
			276,
			32,
			32
		}
	}
	self.wp_door = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			2,
			310,
			32,
			32
		}
	}
	self.wp_saw = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			36,
			310,
			32,
			32
		}
	}
	self.wp_bag = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			70,
			310,
			32,
			32
		}
	}
	self.wp_exit = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			104,
			310,
			32,
			32
		}
	}
	self.wp_can = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			2,
			344,
			32,
			32
		}
	}
	self.wp_target = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			36,
			344,
			32,
			32
		}
	}
	self.wp_key = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			70,
			344,
			32,
			32
		}
	}
	self.wp_winch = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			104,
			344,
			32,
			32
		}
	}
	self.wp_escort = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			138,
			344,
			32,
			32
		}
	}
	self.wp_powerbutton = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			172,
			344,
			32,
			32
		}
	}
	self.wp_server = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			206,
			344,
			32,
			32
		},
		texture_rect = {
			206,
			344,
			32,
			32
		}
	}
	self.wp_powercord = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			240,
			344,
			32,
			32
		}
	}
	self.wp_phone = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			480,
			144,
			32,
			32
		}
	}
	self.wp_scrubs = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			480,
			177,
			32,
			32
		}
	}
	self.wp_sentry = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			480,
			210,
			32,
			32
		}
	}
	self.equipment_trip_mine = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			0,
			96,
			48,
			48
		}
	}
	self.equipment_ammo_bag = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			48,
			96,
			48,
			48
		}
	}
	self.equipment_doctor_bag = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			96,
			96,
			48,
			48
		}
	}
	self.equipment_money_bag = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			144,
			96,
			48,
			48
		}
	}
	self.equipment_bank_manager_key = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			288,
			144,
			48,
			48
		}
	}
	self.equipment_chavez_key = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			192,
			96,
			48,
			48
		}
	}
	self.equipment_drill = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			240,
			96,
			48,
			48
		}
	}
	self.equipment_ejection_seat = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			384,
			144,
			48,
			48
		}
	}
	self.equipment_saw = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			336,
			144,
			48,
			48
		}
	}
	self.equipment_cutter = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			384,
			192,
			48,
			48
		}
	}
	self.equipment_hack_ipad = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			432,
			192,
			48,
			48
		}
	}
	self.equipment_gold = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			384,
			240,
			48,
			48
		}
	}
	self.equipment_thermite = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			288,
			96,
			48,
			48
		}
	}
	self.equipment_c4 = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			336,
			96,
			48,
			48
		}
	}
	self.equipment_crowbar = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			192,
			240,
			48,
			48
		}
	}
	self.equipment_cable_ties = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			384,
			96,
			48,
			48
		}
	}
	self.equipment_extra_cable_ties = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			0,
			144,
			48,
			48
		}
	}
	self.equipment_extra_start_out_ammo = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			48,
			144,
			48,
			48
		}
	}
	self.equipment_bleed_out = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			96,
			144,
			48,
			48
		}
	}
	self.equipment_armor = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			144,
			144,
			48,
			48
		}
	}
	self.equipment_thick_skin = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			144,
			144,
			48,
			48
		}
	}
	self.equipment_planks = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			144,
			288,
			48,
			48
		}
	}
	self.equipment_sentry = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			320,
			288,
			48,
			48
		}
	}
	self.equipment_stash_server = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			272,
			288,
			48,
			48
		}
	}
	self.equipment_vialOK = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			336,
			48,
			48,
			48
		}
	}
	self.equipment_vial = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			416,
			336,
			48,
			48
		}
	}
	self.interaction_free = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			48,
			192,
			48,
			48
		}
	}
	self.interaction_trade = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			432,
			144,
			48,
			48
		}
	}
	self.interaction_intimidate = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			96,
			192,
			48,
			48
		}
	}
	self.interaction_money_wrap = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			144,
			191,
			48,
			48
		}
	}
	self.interaction_christmas_present = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			144,
			240,
			48,
			48
		}
	}
	self.interaction_powerbox = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			192,
			288,
			48,
			48
		}
	}
	self.interaction_gold = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			384,
			240,
			48,
			48
		}
	}
	self.interaction_open_door = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			96,
			192,
			48,
			48
		}
	}
	self.interaction_diamond = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			432,
			240,
			48,
			48
		}
	}
	self.interaction_powercord = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			272,
			336,
			48,
			48
		}
	}
	self.interaction_help = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			192,
			192,
			48,
			48
		}
	}
	self.interaction_answerphone = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			368,
			336,
			48,
			48
		}
	}
	self.interaction_patientfile = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			320,
			336,
			48,
			48
		}
	}
	self.interaction_wirecutter = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			464,
			336,
			48,
			48
		}
	}
	self.interaction_elevator = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			464,
			384,
			48,
			48
		}
	}
	self.interaction_sentrygun = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			320,
			288,
			48,
			48
		}
	}
	self.interaction_keyboard = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			368,
			384,
			48,
			48
		}
	}
	self.laptop_objective = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			240,
			144,
			48,
			48
		}
	}
	self.interaction_bar = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			1,
			393,
			358,
			20
		}
	}
	self.interaction_bar_background = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			0,
			414,
			360,
			22
		}
	}
	self.mask_clown1 = {
		texture = "guis/textures/hud_icons_mask_set",
		texture_rect = {
			1,
			50,
			48,
			48
		}
	}
	self.mask_clown2 = {
		texture = "guis/textures/hud_icons_mask_set",
		texture_rect = {
			50,
			50,
			48,
			48
		}
	}
	self.mask_clown3 = {
		texture = "guis/textures/hud_icons_mask_set",
		texture_rect = {
			99,
			50,
			48,
			48
		}
	}
	self.mask_clown4 = {
		texture = "guis/textures/hud_icons_mask_set",
		texture_rect = {
			148,
			50,
			48,
			48
		}
	}
	self.mask_alien1 = {
		texture = "guis/textures/hud_icons_mask_set",
		texture_rect = {
			1,
			1,
			48,
			48
		}
	}
	self.mask_alien2 = {
		texture = "guis/textures/hud_icons_mask_set",
		texture_rect = {
			50,
			1,
			48,
			48
		}
	}
	self.mask_alien3 = {
		texture = "guis/textures/hud_icons_mask_set",
		texture_rect = {
			99,
			1,
			48,
			48
		}
	}
	self.mask_alien4 = {
		texture = "guis/textures/hud_icons_mask_set",
		texture_rect = {
			148,
			1,
			48,
			48
		}
	}
	self.mask_dev = {
		texture = "guis/textures/hud_icons_mask_set",
		texture_rect = {
			197,
			1,
			48,
			48
		}
	}
	self.mask_com = {
		texture = "guis/textures/hud_icons_mask_set",
		texture_rect = {
			197,
			50,
			48,
			48
		}
	}
	self.mask_santa = {
		texture = "guis/textures/hud_icons_mask_set",
		texture_rect = {
			197,
			99,
			48,
			48
		}
	}
	self.mask_bf1 = {
		texture = "guis/textures/hud_icons_mask_set",
		texture_rect = {
			1,
			99,
			48,
			48
		}
	}
	self.mask_bf2 = {
		texture = "guis/textures/hud_icons_mask_set",
		texture_rect = {
			50,
			99,
			48,
			48
		}
	}
	self.mask_bf3 = {
		texture = "guis/textures/hud_icons_mask_set",
		texture_rect = {
			99,
			99,
			48,
			48
		}
	}
	self.mask_bf4 = {
		texture = "guis/textures/hud_icons_mask_set",
		texture_rect = {
			148,
			99,
			48,
			48
		}
	}
	self.mask_gold1 = {
		texture = "guis/textures/hud_icons_mask_set",
		texture_rect = {
			1,
			148,
			48,
			48
		}
	}
	self.mask_gold2 = {
		texture = "guis/textures/hud_icons_mask_set",
		texture_rect = {
			50,
			148,
			48,
			48
		}
	}
	self.mask_gold3 = {
		texture = "guis/textures/hud_icons_mask_set",
		texture_rect = {
			99,
			148,
			48,
			48
		}
	}
	self.mask_gold4 = {
		texture = "guis/textures/hud_icons_mask_set",
		texture_rect = {
			148,
			148,
			48,
			48
		}
	}
	self.mask_president1 = {
		texture = "guis/textures/hud_icons_mask_set",
		texture_rect = {
			1,
			197,
			48,
			48
		}
	}
	self.mask_president2 = {
		texture = "guis/textures/hud_icons_mask_set",
		texture_rect = {
			50,
			197,
			48,
			48
		}
	}
	self.mask_president3 = {
		texture = "guis/textures/hud_icons_mask_set",
		texture_rect = {
			99,
			197,
			48,
			48
		}
	}
	self.mask_president4 = {
		texture = "guis/textures/hud_icons_mask_set",
		texture_rect = {
			148,
			197,
			48,
			48
		}
	}
	self.mask_zombie1 = {
		texture = "guis/textures/hud_icons_mask_set_zombies",
		texture_rect = {
			1,
			1,
			48,
			48
		}
	}
	self.mask_zombie2 = {
		texture = "guis/textures/hud_icons_mask_set_zombies",
		texture_rect = {
			50,
			1,
			48,
			48
		}
	}
	self.mask_zombie3 = {
		texture = "guis/textures/hud_icons_mask_set_zombies",
		texture_rect = {
			99,
			1,
			48,
			48
		}
	}
	self.mask_zombie4 = {
		texture = "guis/textures/hud_icons_mask_set_zombies",
		texture_rect = {
			148,
			1,
			48,
			48
		}
	}
	self.mask_troll1 = {
		texture = "guis/textures/hud_icons_mask_set_lol",
		texture_rect = {
			1,
			1,
			48,
			48
		}
	}
	self.mask_troll2 = {
		texture = "guis/textures/hud_icons_mask_set_lol",
		texture_rect = {
			50,
			1,
			48,
			48
		}
	}
	self.mask_troll3 = {
		texture = "guis/textures/hud_icons_mask_set_lol",
		texture_rect = {
			99,
			1,
			48,
			48
		}
	}
	self.mask_troll4 = {
		texture = "guis/textures/hud_icons_mask_set_lol",
		texture_rect = {
			148,
			1,
			48,
			48
		}
	}
	self.mask_music1 = {
		texture = "guis/textures/hud_icons_mask_set_venetian",
		texture_rect = {
			1,
			1,
			48,
			48
		}
	}
	self.mask_music2 = {
		texture = "guis/textures/hud_icons_mask_set_venetian",
		texture_rect = {
			50,
			1,
			48,
			48
		}
	}
	self.mask_music3 = {
		texture = "guis/textures/hud_icons_mask_set_venetian",
		texture_rect = {
			99,
			1,
			48,
			48
		}
	}
	self.mask_music4 = {
		texture = "guis/textures/hud_icons_mask_set_venetian",
		texture_rect = {
			148,
			1,
			48,
			48
		}
	}
	self.mask_vyse1 = {
		texture = "guis/textures/hud_icons_mask_set_vyse",
		texture_rect = {
			1,
			1,
			48,
			48
		}
	}
	self.mask_vyse2 = {
		texture = "guis/textures/hud_icons_mask_set_vyse",
		texture_rect = {
			50,
			1,
			48,
			48
		}
	}
	self.mask_vyse3 = {
		texture = "guis/textures/hud_icons_mask_set_vyse",
		texture_rect = {
			99,
			1,
			48,
			48
		}
	}
	self.mask_vyse4 = {
		texture = "guis/textures/hud_icons_mask_set_vyse",
		texture_rect = {
			148,
			1,
			48,
			48
		}
	}
	self.mask_halloween1 = {
		texture = "guis/textures/hud_icons_mask_set_halloween",
		texture_rect = {
			1,
			1,
			48,
			48
		}
	}
	self.mask_halloween2 = {
		texture = "guis/textures/hud_icons_mask_set_halloween",
		texture_rect = {
			50,
			1,
			48,
			48
		}
	}
	self.mask_halloween3 = {
		texture = "guis/textures/hud_icons_mask_set_halloween",
		texture_rect = {
			99,
			1,
			48,
			48
		}
	}
	self.mask_halloween4 = {
		texture = "guis/textures/hud_icons_mask_set_halloween",
		texture_rect = {
			148,
			1,
			48,
			48
		}
	}
	self.mask_tester1 = {
		texture = "guis/textures/hud_icons_mask_set_tester",
		texture_rect = {
			1,
			1,
			48,
			48
		}
	}
	self.mask_tester2 = {
		texture = "guis/textures/hud_icons_mask_set_tester",
		texture_rect = {
			50,
			1,
			48,
			48
		}
	}
	self.mask_tester3 = {
		texture = "guis/textures/hud_icons_mask_set_tester",
		texture_rect = {
			99,
			1,
			48,
			48
		}
	}
	self.mask_tester4 = {
		texture = "guis/textures/hud_icons_mask_set_tester",
		texture_rect = {
			148,
			1,
			48,
			48
		}
	}
	self.mask_end_of_the_world1 = {
		texture = "guis/textures/hud_icons_mask_set_end_of_the_world",
		texture_rect = {
			1,
			1,
			48,
			48
		}
	}
	self.mask_end_of_the_world2 = {
		texture = "guis/textures/hud_icons_mask_set_end_of_the_world",
		texture_rect = {
			50,
			1,
			48,
			48
		}
	}
	self.mask_end_of_the_world3 = {
		texture = "guis/textures/hud_icons_mask_set_end_of_the_world",
		texture_rect = {
			99,
			1,
			48,
			48
		}
	}
	self.mask_end_of_the_world4 = {
		texture = "guis/textures/hud_icons_mask_set_end_of_the_world",
		texture_rect = {
			148,
			1,
			48,
			48
		}
	}
	self.mugshot_random = {
		texture = "guis/textures/hud_icons_mask_set",
		texture_rect = {
			197,
			148,
			48,
			48
		}
	}
	self.mugshot_unassigned = {
		texture = "guis/textures/hud_icons_mask_set",
		texture_rect = {
			197,
			197,
			48,
			48
		}
	}
	self.mugshot_health_background = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			240,
			240,
			12,
			48
		}
	}
	self.mugshot_health_armor = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			252,
			240,
			12,
			48
		}
	}
	self.mugshot_health_health = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			264,
			240,
			12,
			48
		}
	}
	self.mugshot_talk = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			240,
			288,
			16,
			16
		}
	}
	self.mugshot_in_custody = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			192,
			464,
			48,
			48
		}
	}
	self.mugshot_downed = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			240,
			464,
			48,
			48
		}
	}
	self.mugshot_cuffed = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			288,
			464,
			48,
			48
		}
	}
	self.mugshot_electrified = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			336,
			464,
			48,
			48
		}
	}
	self.control_marker = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			352,
			288,
			16,
			48
		}
	}
	self.control_left = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			304,
			288,
			48,
			48
		}
	}
	self.control_right = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			256,
			288,
			48,
			48
		}
	}
	self.assault = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			276,
			192,
			108,
			96
		}
	}
	self.ps3buttonhighlight = {
		texture = "guis/textures/hud_icons",
		texture_rect = {
			240,
			192,
			32,
			32
		}
	}
	self.level_up_image_frame = {
		texture = "guis/textures/levelimageframe",
		texture_rect = {
			0,
			0,
			340,
			150
		}
	}
	self.upgrades_selectedframe = {
		texture = "guis/textures/levelimageframe",
		texture_rect = {
			0,
			150,
			512,
			76
		}
	}
	self.upgrades_sliceframe = {
		texture = "guis/textures/levelimageframe",
		texture_rect = {
			0,
			0,
			340,
			150
		}
	}
	self.upgrades_mp5 = {
		texture = "guis/textures/upgrade_images_01",
		texture_rect = {
			0,
			0,
			512,
			226
		}
	}
	self.upgrades_mp5_slice = {
		texture = "guis/textures/upgrade_images_01",
		texture_rect = {
			0,
			10,
			512,
			76
		}
	}
	self.upgrades_45 = {
		texture = "guis/textures/upgrade_images_01",
		texture_rect = {
			512,
			0,
			512,
			226
		}
	}
	self.upgrades_45_slice = {
		texture = "guis/textures/upgrade_images_01",
		texture_rect = {
			512,
			124,
			512,
			76
		}
	}
	self.upgrades_remington = {
		texture = "guis/textures/upgrade_images_01",
		texture_rect = {
			0,
			226,
			512,
			226
		}
	}
	self.upgrades_remington_slice = {
		texture = "guis/textures/upgrade_images_01",
		texture_rect = {
			0,
			267,
			512,
			76
		}
	}
	self.upgrades_ragingbull = {
		texture = "guis/textures/upgrade_images_01",
		texture_rect = {
			512,
			226,
			512,
			226
		}
	}
	self.upgrades_ragingbull_slice = {
		texture = "guis/textures/upgrade_images_01",
		texture_rect = {
			512,
			266,
			512,
			76
		}
	}
	self.upgrades_m4 = {
		texture = "guis/textures/upgrade_images_01",
		texture_rect = {
			1024,
			0,
			512,
			226
		}
	}
	self.upgrades_m4_slice = {
		texture = "guis/textures/upgrade_images_01",
		texture_rect = {
			1024,
			44,
			512,
			76
		}
	}
	self.upgrades_mossberg = {
		texture = "guis/textures/upgrade_images_01",
		texture_rect = {
			1024,
			226,
			512,
			226
		}
	}
	self.upgrades_mossberg_slice = {
		texture = "guis/textures/upgrade_images_01",
		texture_rect = {
			1024,
			289,
			512,
			76
		}
	}
	self.upgrades_hk21 = {
		texture = "guis/textures/upgrade_images_01",
		texture_rect = {
			0,
			452,
			512,
			226
		}
	}
	self.upgrades_hk21_slice = {
		texture = "guis/textures/upgrade_images_01",
		texture_rect = {
			0,
			542,
			512,
			76
		}
	}
	self.upgrades_m9sd = {
		texture = "guis/textures/upgrade_images_01",
		texture_rect = {
			0,
			678,
			512,
			226
		}
	}
	self.upgrades_m9sd_slice = {
		texture = "guis/textures/upgrade_images_01",
		texture_rect = {
			0,
			756,
			512,
			76
		}
	}
	self.upgrades_mac10 = {
		texture = "guis/textures/upgrade_images_01",
		texture_rect = {
			512,
			452,
			512,
			226
		}
	}
	self.upgrades_mac10_slice = {
		texture = "guis/textures/upgrade_images_01",
		texture_rect = {
			512,
			494,
			512,
			76
		}
	}
	self.upgrades_m14 = {
		texture = "guis/textures/upgrade_images_01",
		texture_rect = {
			512,
			678,
			512,
			226
		}
	}
	self.upgrades_m14_slice = {
		texture = "guis/textures/upgrade_images_01",
		texture_rect = {
			512,
			708,
			512,
			76
		}
	}
	self.upgrades_doctorbag = {
		texture = "guis/textures/upgrade_images_01",
		texture_rect = {
			1024,
			452,
			512,
			226
		}
	}
	self.upgrades_doctorbag_slice = {
		texture = "guis/textures/upgrade_images_01",
		texture_rect = {
			1024,
			541,
			512,
			76
		}
	}
	self.upgrades_tripmines = {
		texture = "guis/textures/upgrade_images_01",
		texture_rect = {
			1024,
			678,
			512,
			226
		}
	}
	self.upgrades_tripmines_slice = {
		texture = "guis/textures/upgrade_images_01",
		texture_rect = {
			1024,
			717,
			512,
			76
		}
	}
	self.upgrades_ammobag = {
		texture = "guis/textures/upgrade_images_01",
		texture_rect = {
			1536,
			0,
			512,
			226
		}
	}
	self.upgrades_ammobag_slice = {
		texture = "guis/textures/upgrade_images_01",
		texture_rect = {
			1536,
			107,
			512,
			76
		}
	}
	self.upgrades_extracableties = {
		texture = "guis/textures/upgrade_images_01",
		texture_rect = {
			1536,
			226,
			512,
			226
		}
	}
	self.upgrades_extracableties_slice = {
		texture = "guis/textures/upgrade_images_01",
		texture_rect = {
			1536,
			353,
			512,
			76
		}
	}
	self.upgrades_thugskin = {
		texture = "guis/textures/upgrade_images_01",
		texture_rect = {
			1536,
			452,
			512,
			226
		}
	}
	self.upgrades_thugskin_slice = {
		texture = "guis/textures/upgrade_images_01",
		texture_rect = {
			1536,
			589,
			512,
			76
		}
	}
	self.upgrades_extrastartammo = {
		texture = "guis/textures/upgrade_images_01",
		texture_rect = {
			1536,
			678,
			512,
			226
		}
	}
	self.upgrades_extrastartammo_slice = {
		texture = "guis/textures/upgrade_images_01",
		texture_rect = {
			1536,
			727,
			512,
			76
		}
	}
	self.upgrades_agressor = {
		texture = "guis/textures/upgrade_images_01",
		texture_rect = {
			0,
			1356,
			512,
			226
		}
	}
	self.upgrades_agressor_slice = {
		texture = "guis/textures/upgrade_images_01",
		texture_rect = {
			0,
			1403,
			512,
			76
		}
	}
	self.upgrades_speedreloaders = {
		texture = "guis/textures/upgrade_images_01",
		texture_rect = {
			512,
			1356,
			512,
			226
		}
	}
	self.upgrades_speedreloaders_slice = {
		texture = "guis/textures/upgrade_images_01",
		texture_rect = {
			512,
			1423,
			512,
			76
		}
	}
	self.upgrades_sharpshooters = {
		texture = "guis/textures/upgrade_images_01",
		texture_rect = {
			1024,
			1356,
			512,
			226
		}
	}
	self.upgrades_sharpshooters_slice = {
		texture = "guis/textures/upgrade_images_01",
		texture_rect = {
			1024,
			1417,
			512,
			76
		}
	}
	self.upgrades_morebloodtobleed = {
		texture = "guis/textures/upgrade_images_01",
		texture_rect = {
			1536,
			1356,
			512,
			226
		}
	}
	self.upgrades_morebloodtobleed_slice = {
		texture = "guis/textures/upgrade_images_01",
		texture_rect = {
			1536,
			1367,
			512,
			76
		}
	}
	self.upgrades_protector = {
		texture = "guis/textures/upgrade_images_01",
		texture_rect = {
			0,
			1130,
			512,
			226
		}
	}
	self.upgrades_protector_slice = {
		texture = "guis/textures/upgrade_images_01",
		texture_rect = {
			0,
			1193,
			512,
			76
		}
	}
	self.upgrades_bodyarmor = {
		texture = "guis/textures/upgrade_images_01",
		texture_rect = {
			512,
			1130,
			512,
			226
		}
	}
	self.upgrades_bodyarmor_slice = {
		texture = "guis/textures/upgrade_images_01",
		texture_rect = {
			512,
			1239,
			512,
			76
		}
	}
	self.upgrades_welcome = {
		texture = "guis/textures/upgrade_images_01",
		texture_rect = {
			1024,
			1130,
			512,
			226
		}
	}
	self.upgrades_welcome_slice = {
		texture = "guis/textures/upgrade_images_01",
		texture_rect = {
			1024,
			1223,
			512,
			76
		}
	}
	self.upgrades_mrniceguy = {
		texture = "guis/textures/upgrade_images_01",
		texture_rect = {
			1536,
			1130,
			512,
			226
		}
	}
	self.upgrades_mrniceguy_slice = {
		texture = "guis/textures/upgrade_images_01",
		texture_rect = {
			1536,
			1227,
			512,
			76
		}
	}
	self.upgrades_ak = {
		texture = "guis/textures/upgrade_images_01",
		texture_rect = {
			0,
			904,
			512,
			226
		}
	}
	self.upgrades_ak_slice = {
		texture = "guis/textures/upgrade_images_01",
		texture_rect = {
			0,
			947,
			512,
			76
		}
	}
	self.upgrades_glock = {
		texture = "guis/textures/upgrade_images_01",
		texture_rect = {
			1024,
			904,
			512,
			226
		}
	}
	self.upgrades_glock_slice = {
		texture = "guis/textures/upgrade_images_01",
		texture_rect = {
			1024,
			911,
			512,
			76
		}
	}
	self.upgrades_grenade = {
		texture = "guis/textures/upgrade_images_01",
		texture_rect = {
			512,
			904,
			512,
			226
		}
	}
	self.upgrades_grenade_slice = {
		texture = "guis/textures/upgrade_images_01",
		texture_rect = {
			512,
			985,
			512,
			76
		}
	}
	self.upgrades_sentry = {
		texture = "guis/textures/upgrade_images_01",
		texture_rect = {
			1536,
			904,
			512,
			226
		}
	}
	self.upgrades_sentry_slice = {
		texture = "guis/textures/upgrade_images_01",
		texture_rect = {
			1536,
			941,
			512,
			76
		}
	}
	self.upgrades_toolset = {
		texture = "guis/textures/upgrade_images_01",
		texture_rect = {
			512,
			1582,
			512,
			226
		}
	}
	self.upgrades_toolset_slice = {
		texture = "guis/textures/upgrade_images_01",
		texture_rect = {
			512,
			1641,
			512,
			76
		}
	}
	self.upgrades_team_ammo = {
		texture = "guis/textures/upgrade_images_01",
		texture_rect = {
			0,
			1582,
			512,
			226
		}
	}
	self.upgrades_team_ammo_slice = {
		texture = "guis/textures/upgrade_images_01",
		texture_rect = {
			0,
			1690,
			512,
			76
		}
	}
end
function HudIconsTweakData:get_icon_data(icon_id, default_rect)
	local icon = tweak_data.hud_icons[icon_id] and tweak_data.hud_icons[icon_id].texture or icon_id
	local texture_rect = tweak_data.hud_icons[icon_id] and tweak_data.hud_icons[icon_id].texture_rect or default_rect or {
		0,
		0,
		48,
		48
	}
	return icon, texture_rect
end
