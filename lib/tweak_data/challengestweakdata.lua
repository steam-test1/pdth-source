ChallengesTweakData = ChallengesTweakData or class()
local tiny_xp = 800
local small_xp = 1000
local mid_xp = 1400
local large_xp = 2400
local huge_xp = 3600
local gigantic_xp = 5000
local ten_steps = {
	"size08",
	"size10",
	"size12",
	"size12",
	"size14",
	"size16",
	"size18",
	"size20",
	"size20",
	"size20"
}
local five_steps = {
	"size12",
	"size14",
	"size16",
	"size18",
	"size20"
}
function ChallengesTweakData:init()
	self.character = {}
	self.character.bullet_to_bleed_out = {
		title_id = "ch_bullet_to_bleed_out_hl",
		description_id = "ch_bullet_to_bleed_out",
		flag_id = "bullet_to_bleed_out",
		unlock_level = 0,
		xp = tiny_xp,
		in_trial = true
	}
	self.character.fall_to_bleed_out = {
		title_id = "ch_fall_to_bleed_out_hl",
		description_id = "ch_fall_to_bleed_out",
		flag_id = "fall_to_bleed_out",
		unlock_level = 0,
		xp = tiny_xp
	}
	self.character.revived = {
		title_id = "ch_revived_hl",
		description_id = "ch_revived_single",
		counter_id = "revived",
		unlock_level = 0,
		count = 1,
		xp = tiny_xp,
		in_trial = true
	}
	self.character.arrested = {
		title_id = "ch_arrested_hl",
		description_id = "ch_arrested_single",
		counter_id = "arrested",
		unlock_level = 0,
		count = 1,
		xp = tiny_xp,
		in_trial = true
	}
	self.character.deploy_ammobag = {
		title_id = "ch_deploy_ammobag_hl",
		description_id = "ch_deploy_ammobag",
		counter_id = "deploy_ammobag",
		unlock_level = 0,
		count = 100,
		xp = mid_xp,
		depends_on = {
			equipment = {"ammo_bag"}
		}
	}
	self.character.tiedown_civilian = {
		title_id = "ch_tiedown_civilian_hl",
		description_id = "ch_tiedown_civilian",
		counter_id = "tiedown_civilians",
		unlock_level = 0,
		count = 15,
		xp = tiny_xp
	}
	self.character.tiedown_law = {
		title_id = "ch_tiedown_law_hl",
		description_id = "ch_tiedown_law",
		counter_id = "tiedown_law",
		unlock_level = 0,
		count = 15,
		xp = small_xp,
		depends_on = {
			challenges = {
				"tiedown_civilian"
			}
		}
	}
	self.character.tiedown_cop = {
		title_id = "ch_tiedown_cop_hl",
		description_id = "ch_tiedown_cop",
		counter_id = "tiedown_cop",
		unlock_level = 0,
		count = 15,
		xp = mid_xp,
		depends_on = {
			challenges = {
				"tiedown_law"
			}
		}
	}
	self.character.tiedown_fbi = {
		title_id = "ch_tiedown_fbi_hl",
		description_id = "ch_tiedown_fbi",
		counter_id = "tiedown_fbi",
		unlock_level = 0,
		count = 15,
		xp = huge_xp,
		depends_on = {
			challenges = {
				"tiedown_cop"
			}
		}
	}
	self.character.tiedown_swat = {
		title_id = "ch_tiedown_swat_hl",
		description_id = "ch_tiedown_swat",
		counter_id = "tiedown_swat",
		unlock_level = 0,
		count = 15,
		xp = large_xp,
		depends_on = {
			challenges = {
				"tiedown_fbi"
			}
		}
	}
	self.achievment = {}
	self.achievment.diplomatic = {
		title_id = "ch_diplomatic_hl",
		description_id = "ch_diplomatic",
		flag_id = "diplomatic",
		unlock_level = 0,
		xp = tiny_xp,
		awards_achievment = "diplomatic"
	}
	self.achievment.cheney = {
		title_id = "ch_cheney_hl",
		description_id = "ch_cheney",
		flag_id = "cheney",
		unlock_level = 0,
		xp = tiny_xp,
		awards_achievment = "cheney"
	}
	self.achievment.intimidating = {
		title_id = "ch_intimidating_hl",
		description_id = "ch_intimidating",
		flag_id = "intimidating",
		unlock_level = 0,
		xp = mid_xp,
		awards_achievment = "intimidating"
	}
	self.achievment.left_for_dead = {
		title_id = "ch_left_for_dead_hl",
		description_id = "ch_left_for_dead",
		flag_id = "left_for_dead",
		unlock_level = 0,
		xp = mid_xp,
		awards_achievment = "left_for_dead"
	}
	self.achievment.blood_in_blood_out = {
		title_id = "ch_blood_in_blood_out_hl",
		description_id = "ch_blood_in_blood_out",
		flag_id = "blood_in_blood_out",
		unlock_level = 0,
		xp = mid_xp,
		awards_achievment = "blood_in_blood_out"
	}
	self.achievment.dodge_this = {
		title_id = "ch_dodge_this_hl",
		description_id = "ch_dodge_this",
		flag_id = "dodge_this",
		unlock_level = 0,
		xp = mid_xp,
		awards_achievment = "dodge_this"
	}
	self.achievment.drop_armored_car = {
		title_id = "ch_drop_armored_car_hl",
		description_id = "ch_drop_armored_car",
		flag_id = "drop_armored_car",
		unlock_level = 0,
		xp = mid_xp,
		awards_achievment = "drop_armored_car"
	}
	self.achievment.last_man_standing = {
		title_id = "ch_last_man_standing_hl",
		description_id = "ch_last_man_standing",
		flag_id = "last_man_standing",
		unlock_level = 0,
		xp = mid_xp,
		awards_achievment = "last_man_standing"
	}
	self.achievment.windowlicker = {
		title_id = "ch_windowlicker_hl",
		description_id = "ch_windowlicker",
		flag_id = "windowlicker",
		unlock_level = 0,
		xp = mid_xp,
		awards_achievment = "windowlicker"
	}
	self.achievment.civil_disobedience = {
		title_id = "ch_civil_disobedience_hl",
		description_id = "ch_civil_disobedience",
		flag_id = "civil_disobedience",
		unlock_level = 0,
		xp = mid_xp,
		awards_achievment = "civil_disobedience"
	}
	self.achievment.take_money = {
		title_id = "ch_take_money_hl",
		description_id = "ch_take_money",
		flag_id = "take_money",
		unlock_level = 0,
		xp = mid_xp,
		awards_achievment = "take_money"
	}
	self.achievment.the_darkness = {
		title_id = "ch_the_darkness_hl",
		description_id = "ch_the_darkness",
		flag_id = "the_darkness",
		unlock_level = 0,
		xp = mid_xp,
		awards_achievment = "the_darkness"
	}
	self.achievment.chavez_can_run = {
		title_id = "ch_chavez_can_run_hl",
		description_id = "ch_chavez_can_run",
		flag_id = "chavez_can_run",
		unlock_level = 0,
		xp = mid_xp,
		awards_achievment = "chavez_can_run"
	}
	self.achievment.ninja = {
		title_id = "ch_ninja_hl",
		description_id = "ch_ninja",
		flag_id = "ninja",
		unlock_level = 0,
		xp = mid_xp,
		awards_achievment = "ninja"
	}
	self.achievment.take_sapphires = {
		title_id = "ch_take_sapphires_hl",
		description_id = "ch_take_sapphires",
		flag_id = "take_sapphires",
		unlock_level = 0,
		xp = mid_xp,
		awards_achievment = "take_sapphires"
	}
	self.achievment.quick_gold = {
		title_id = "ch_quick_gold_hl",
		description_id = "ch_quick_gold",
		flag_id = "quick_gold",
		unlock_level = 0,
		xp = mid_xp,
		awards_achievment = "quick_gold"
	}
	self.achievment.stand_together = {
		title_id = "ch_stand_together_hl",
		description_id = "ch_stand_together",
		flag_id = "stand_together",
		unlock_level = 0,
		xp = large_xp,
		awards_achievment = "stand_together"
	}
	self.achievment.kill_thugs = {
		title_id = "ch_kill_thugs_hl",
		description_id = "ch_kill_thugs",
		flag_id = "kill_thugs",
		unlock_level = 0,
		xp = large_xp,
		awards_achievment = "kill_thugs"
	}
	self.achievment.kill_cameras = {
		title_id = "ch_kill_cameras_hl",
		description_id = "ch_kill_cameras",
		flag_id = "kill_cameras",
		unlock_level = 0,
		xp = large_xp,
		awards_achievment = "kill_cameras"
	}
	self.achievment.hot_lava = {
		title_id = "ch_hot_lava_hl",
		description_id = "ch_hot_lava",
		flag_id = "hot_lava",
		unlock_level = 0,
		xp = gigantic_xp,
		awards_achievment = "hot_lava"
	}
	self.achievment.federal_crime = {
		title_id = "ch_federal_crime_hl",
		description_id = "ch_federal_crime",
		flag_id = "federal_crime",
		unlock_level = 0,
		xp = large_xp,
		awards_achievment = "federal_crime"
	}
	self.achievment.one_shot_one_kill = {
		title_id = "ch_one_shot_one_kill_hl",
		description_id = "ch_one_shot_one_kill",
		flag_id = "one_shot_one_kill",
		unlock_level = 0,
		xp = gigantic_xp,
		awards_achievment = "one_shot_one_kill"
	}
	self.achievment.bomb_man = {
		title_id = "ch_bomb_man_hl",
		description_id = "ch_bomb_man",
		flag_id = "bomb_man",
		unlock_level = 0,
		xp = large_xp,
		awards_achievment = "bomb_man"
	}
	self.achievment.duck_hunting = {
		title_id = "ch_duck_hunting_hl",
		description_id = "ch_duck_hunting",
		flag_id = "duck_hunting",
		unlock_level = 0,
		xp = small_xp,
		awards_achievment = "duck_hunting"
	}
	self.achievment.ready_yet = {
		title_id = "ch_ready_yet_hl",
		description_id = "ch_ready_yet",
		flag_id = "ready_yet",
		unlock_level = 0,
		xp = large_xp,
		awards_achievment = "ready_yet"
	}
	self.achievment.cant_touch = {
		title_id = "ch_cant_touch_hl",
		description_id = "ch_cant_touch",
		flag_id = "cant_touch",
		unlock_level = 0,
		xp = gigantic_xp,
		awards_achievment = "cant_touch"
	}
	self.achievment.dozen_angry = {
		title_id = "ch_dozen_angry_hl",
		description_id = "ch_dozen_angry",
		flag_id = "dozen_angry",
		unlock_level = 0,
		xp = gigantic_xp,
		awards_achievment = "dozen_angry"
	}
	self.achievment.noob_herder = {
		title_id = "ch_noob_herder_hl",
		description_id = "ch_noob_herder",
		flag_id = "noob_herder",
		unlock_level = 0,
		xp = gigantic_xp,
		awards_achievment = "noob_herder"
	}
	self.achievment.dont_lose = {
		title_id = "ch_dont_lose_face_hl",
		description_id = "ch_dont_lose_face",
		counter_id = "dont_lose_face",
		count = 6,
		unlock_level = 48,
		xp = gigantic_xp,
		awards_achievment = "dont_lose_face"
	}
	self.achievment.eagle_eyes = {
		title_id = "ch_eagle_eyes_hl",
		description_id = "ch_eagle_eyes",
		flag_id = "eagle_eyes",
		unlock_level = 0,
		xp = tiny_xp,
		awards_achievment = "eagle_eyes"
	}
	self.achievment.aint_afraid = {
		title_id = "ch_aint_afraid_hl",
		description_id = "ch_aint_afraid",
		flag_id = "aint_afraid",
		unlock_level = 0,
		xp = tiny_xp,
		awards_achievment = "aint_afraid"
	}
	self.achievment.crack_bang = {
		title_id = "ch_crack_bang_hl",
		description_id = "ch_crack_bang",
		flag_id = "crack_bang",
		unlock_level = 0,
		xp = mid_xp,
		awards_achievment = "crack_bang"
	}
	self.achievment.lay_on_hands = {
		title_id = "ch_lay_on_hands_hl",
		description_id = "ch_lay_on_hands",
		flag_id = "lay_on_hands",
		unlock_level = 0,
		xp = mid_xp,
		awards_achievment = "lay_on_hands"
	}
	self.achievment.christmas_present = {
		title_id = "ch_christmas_present_hl",
		description_id = "ch_christmas_present",
		flag_id = "take_christmas_present",
		unlock_level = 0,
		xp = large_xp,
		awards_achievment = "christmas_present"
	}
	self.achievment.golden_boy = {
		title_id = "ch_golden_boy_hl",
		description_id = "ch_golden_boy",
		counter_id = "golden_boy",
		count = 6,
		unlock_level = 145,
		xp = gigantic_xp,
		awards_achievment = "golden_boy"
	}
	self.achievment.president = {
		title_id = "ch_president_hl",
		description_id = "ch_president",
		flag_id = "president",
		unlock_level = 0,
		xp = gigantic_xp,
		awards_achievment = "president"
	}
	self.achievment.tester = {
		title_id = "ch_tester_hl",
		description_id = "ch_tester",
		flag_id = "tester",
		unlock_level = 0,
		xp = tiny_xp,
		awards_achievment = "tester"
	}
	if managers.dlc:has_dlc1() then
		self.achievment.crowd_control = {
			title_id = "ch_crowd_control_hl",
			description_id = "ch_crowd_control",
			flag_id = "crowd_control",
			unlock_level = 0,
			xp = tiny_xp,
			awards_achievment = "crowd_control"
		}
		self.achievment.quick_hands = {
			title_id = "ch_quick_hands_hl",
			description_id = "ch_quick_hands",
			flag_id = "quick_hands",
			unlock_level = 0,
			xp = tiny_xp,
			awards_achievment = "quick_hands"
		}
		self.achievment.pacifist = {
			title_id = "ch_pacifist_hl",
			description_id = "ch_pacifist",
			flag_id = "pacifist",
			unlock_level = 0,
			xp = gigantic_xp,
			awards_achievment = "pacifist"
		}
		self.achievment.blow_out = {
			title_id = "ch_blow_out_hl",
			description_id = "ch_blow_out",
			flag_id = "blow_out",
			unlock_level = 0,
			xp = mid_xp,
			awards_achievment = "blow_out"
		}
		self.achievment.saviour = {
			title_id = "ch_saviour_hl",
			description_id = "ch_saviour",
			flag_id = "saviour",
			unlock_level = 0,
			xp = tiny_xp,
			awards_achievment = "saviour"
		}
		self.achievment.det_gadget = {
			title_id = "ch_det_gadget_hl",
			description_id = "ch_det_gadget",
			flag_id = "det_gadget",
			unlock_level = 0,
			xp = tiny_xp,
			awards_achievment = "det_gadget"
		}
	end
	if managers.dlc:has_dlc4() then
		self.achievment.dont_panic = {
			title_id = "ch_hos_dont_panic_hl",
			description_id = "ch_hos_dont_panic",
			flag_id = "dont_panic",
			unlock_level = 0,
			xp = tiny_xp,
			awards_achievment = "dont_panic"
		}
		self.achievment.cut_wire = {
			title_id = "ch_hos_cut_wire_hl",
			description_id = "ch_hos_cut_wire",
			flag_id = "cut_wire",
			unlock_level = 0,
			xp = mid_xp,
			awards_achievment = "cut_wire"
		}
		self.achievment.wrong_door = {
			title_id = "ch_hos_wrong_door_hl",
			description_id = "ch_hos_wrong_door",
			flag_id = "wrong_door",
			unlock_level = 0,
			xp = large_xp,
			awards_achievment = "wrong_door"
		}
		self.achievment.afraid_of_the_dark = {
			title_id = "ch_hos_afraid_of_the_dark_hl",
			description_id = "ch_hos_afraid_of_the_dark",
			flag_id = "afraid_of_the_dark",
			unlock_level = 0,
			xp = mid_xp,
			awards_achievment = "afraid_of_the_dark"
		}
	end
	self.weapon = {}
	self:_any_weapon_challenges()
	self:_c45_challenges()
	self:_beretta92_challenges()
	self:_bronco_challenges()
	self:_reinbeck_challenges()
	self:_mossberg_challenges()
	self:_mp5_challenges()
	self:_mac11_challenges()
	self:_m4_challenges()
	self:_m14_challenges()
	self:_hk21_challenges()
	if managers.dlc:has_dlc1() then
		self:_glock_challenges()
		self:_ak47_challenges()
		self:_m79_challenges()
		self:_sentry_gun_challenges()
	end
	self:_melee_challenges()
	self:_bleed_out_challenges()
	self:_trip_mine_challenges()
	self.character.revive_1 = {
		title_id = "ch_revive_1_hl",
		description_id = "ch_revive",
		counter_id = "revive",
		unlock_level = 0,
		count = 5,
		xp = tiny_xp,
		in_trial = true
	}
	self.character.revive_2 = {
		title_id = "ch_revive_2_hl",
		description_id = "ch_revive",
		counter_id = "revive",
		unlock_level = 0,
		count = 30,
		xp = small_xp,
		depends_on = {
			challenges = {"revive_1"}
		}
	}
	self.character.revive_3 = {
		title_id = "ch_revive_3_hl",
		description_id = "ch_revive",
		counter_id = "revive",
		unlock_level = 0,
		count = 60,
		xp = mid_xp,
		depends_on = {
			challenges = {"revive_2"}
		}
	}
	self.character.revive_4 = {
		title_id = "ch_revive_4_hl",
		description_id = "ch_revive",
		counter_id = "revive",
		unlock_level = 0,
		count = 120,
		xp = large_xp,
		depends_on = {
			challenges = {"revive_3"}
		}
	}
	self.session = {}
	self:_money_challenges()
	self.session.bank_no_civilians_hard = {
		title_id = "ch_bank_no_civilians_hl",
		description_id = "ch_bank_no_civilians",
		unlock_level = 20,
		xp = mid_xp,
		level_id = "bank",
		difficulty = {
			"hard",
			"overkill",
			"overkill_145"
		},
		session_stopped = {
			callback = "no_civilians_killed"
		}
	}
	self.session.bank_no_deaths_hard = {
		title_id = "ch_bank_no_deaths_hl",
		description_id = "ch_bank_no_deaths",
		unlock_level = 20,
		xp = large_xp,
		level_id = "bank",
		difficulty = {
			"hard",
			"overkill",
			"overkill_145"
		},
		session_stopped = {callback = "never_died"}
	}
	self.session.bank_no_bleedouts_hard = {
		title_id = "ch_bank_no_bleedouts_hl",
		description_id = "ch_bank_no_bleedouts",
		unlock_level = 20,
		xp = huge_xp,
		level_id = "bank",
		difficulty = {
			"hard",
			"overkill",
			"overkill_145"
		},
		session_stopped = {
			callback = "never_bleedout"
		}
	}
	self.session.bank_success_overkill = {
		title_id = "ch_bank_on_overkill_hl",
		description_id = "ch_bank_on_overkill",
		unlock_level = 48,
		xp = gigantic_xp,
		level_id = "bank",
		difficulty = {
			"overkill",
			"overkill_145"
		},
		session_stopped = {
			callback = "overkill_success"
		}
	}
	self.session.bank_overkill_no_trade = {
		title_id = "ch_bank_overkill_no_trade_hl",
		description_id = "ch_bank_overkill_no_trade",
		unlock_level = 48,
		xp = gigantic_xp,
		level_id = "bank",
		difficulty = {
			"overkill",
			"overkill_145"
		},
		increment_counter = "dont_lose_face",
		session_stopped = {
			callback = "overkill_no_trade"
		}
	}
	self.session.bank_success_overkill_145 = {
		title_id = "ch_bank_on_overkill_145_hl",
		description_id = "ch_bank_on_overkill_145",
		unlock_level = 145,
		xp = gigantic_xp,
		level_id = "bank",
		difficulty = "overkill_145",
		increment_counter = "golden_boy",
		session_stopped = {
			callback = "overkill_success"
		},
		awards_achievment = "bank_145"
	}
	self.session.street_no_civilians_hard = {
		title_id = "ch_street_no_civilians_hl",
		description_id = "ch_street_no_civilians",
		unlock_level = 20,
		xp = mid_xp,
		level_id = "heat_street",
		difficulty = {
			"hard",
			"overkill",
			"overkill_145"
		},
		session_stopped = {
			callback = "no_civilians_killed"
		}
	}
	self.session.street_no_deaths_hard = {
		title_id = "ch_street_no_deaths_hl",
		description_id = "ch_street_no_deaths",
		unlock_level = 20,
		xp = large_xp,
		level_id = "heat_street",
		difficulty = {
			"hard",
			"overkill",
			"overkill_145"
		},
		session_stopped = {callback = "never_died"}
	}
	self.session.street_no_bleedouts_hard = {
		title_id = "ch_street_no_bleedouts_hl",
		description_id = "ch_street_no_bleedouts",
		unlock_level = 20,
		xp = huge_xp,
		level_id = "heat_street",
		difficulty = {
			"hard",
			"overkill",
			"overkill_145"
		},
		session_stopped = {
			callback = "never_bleedout"
		}
	}
	self.session.street_success_overkill = {
		title_id = "ch_street_on_overkill_hl",
		description_id = "ch_street_on_overkill",
		unlock_level = 48,
		xp = gigantic_xp,
		level_id = "heat_street",
		difficulty = {
			"overkill",
			"overkill_145"
		},
		session_stopped = {
			callback = "overkill_success"
		}
	}
	self.session.street_overkill_no_trade = {
		title_id = "ch_street_overkill_no_trade_hl",
		description_id = "ch_street_overkill_no_trade",
		unlock_level = 48,
		xp = gigantic_xp,
		level_id = "heat_street",
		difficulty = {
			"overkill",
			"overkill_145"
		},
		increment_counter = "dont_lose_face",
		session_stopped = {
			callback = "overkill_no_trade"
		}
	}
	self.session.street_success_overkill_145 = {
		title_id = "ch_street_on_overkill_145_hl",
		description_id = "ch_street_on_overkill_145",
		unlock_level = 145,
		xp = gigantic_xp,
		increment_counter = "golden_boy",
		level_id = "heat_street",
		difficulty = "overkill_145",
		session_stopped = {
			callback = "overkill_success"
		},
		awards_achievment = "street_145"
	}
	self.session.bridge_no_civilians_hard = {
		title_id = "ch_bridge_no_civilians_hl",
		description_id = "ch_bridge_no_civilians",
		unlock_level = 20,
		xp = mid_xp,
		level_id = "bridge",
		difficulty = {
			"hard",
			"overkill",
			"overkill_145"
		},
		session_stopped = {
			callback = "no_civilians_killed"
		}
	}
	self.session.bridge_no_deaths_hard = {
		title_id = "ch_bridge_no_deaths_hl",
		description_id = "ch_bridge_no_deaths",
		unlock_level = 20,
		xp = large_xp,
		level_id = "bridge",
		difficulty = {
			"hard",
			"overkill",
			"overkill_145"
		},
		session_stopped = {callback = "never_died"}
	}
	self.session.bridge_no_bleedouts_hard = {
		title_id = "ch_bridge_no_bleedouts_hl",
		description_id = "ch_bridge_no_bleedouts",
		unlock_level = 20,
		xp = huge_xp,
		level_id = "bridge",
		difficulty = {
			"hard",
			"overkill",
			"overkill_145"
		},
		session_stopped = {
			callback = "never_bleedout"
		}
	}
	self.session.bridge_success_overkill = {
		title_id = "ch_bridge_on_overkill_hl",
		description_id = "ch_bridge_on_overkill",
		unlock_level = 48,
		xp = gigantic_xp,
		level_id = "bridge",
		difficulty = {
			"overkill",
			"overkill_145"
		},
		session_stopped = {
			callback = "overkill_success"
		}
	}
	self.session.bridge_overkill_no_trade = {
		title_id = "ch_bridge_overkill_no_trade_hl",
		description_id = "ch_bridge_overkill_no_trade",
		unlock_level = 48,
		xp = gigantic_xp,
		level_id = "bridge",
		difficulty = {
			"overkill",
			"overkill_145"
		},
		increment_counter = "dont_lose_face",
		session_stopped = {
			callback = "overkill_no_trade"
		}
	}
	self.session.bridge_success_overkill_145 = {
		title_id = "ch_bridge_on_overkill_145_hl",
		description_id = "ch_bridge_on_overkill_145",
		unlock_level = 145,
		xp = gigantic_xp,
		increment_counter = "golden_boy",
		level_id = "bridge",
		difficulty = "overkill_145",
		session_stopped = {
			callback = "overkill_success"
		},
		awards_achievment = "bridge_145"
	}
	self.session.apartment_no_civilians_hard = {
		title_id = "ch_apartment_no_civilians_hl",
		description_id = "ch_apartment_no_civilians",
		unlock_level = 20,
		xp = mid_xp,
		level_id = "apartment",
		difficulty = {
			"hard",
			"overkill",
			"overkill_145"
		},
		session_stopped = {
			callback = "no_civilians_killed"
		}
	}
	self.session.apartment_no_deaths_hard = {
		title_id = "ch_apartment_no_deaths_hl",
		description_id = "ch_apartment_no_deaths",
		unlock_level = 20,
		xp = large_xp,
		level_id = "apartment",
		difficulty = {
			"hard",
			"overkill",
			"overkill_145"
		},
		session_stopped = {callback = "never_died"}
	}
	self.session.apartment_no_bleedouts_hard = {
		title_id = "ch_apartment_no_bleedouts_hl",
		description_id = "ch_apartment_no_bleedouts",
		unlock_level = 20,
		xp = huge_xp,
		level_id = "apartment",
		difficulty = {
			"hard",
			"overkill",
			"overkill_145"
		},
		session_stopped = {
			callback = "never_bleedout"
		}
	}
	self.session.apartment_success_overkill = {
		title_id = "ch_apartment_on_overkill_hl",
		description_id = "ch_apartment_on_overkill",
		unlock_level = 48,
		xp = gigantic_xp,
		level_id = "apartment",
		difficulty = {
			"overkill",
			"overkill_145"
		},
		session_stopped = {
			callback = "overkill_success"
		}
	}
	self.session.apartment_overkill_no_trade = {
		title_id = "ch_apartment_overkill_no_trade_hl",
		description_id = "ch_apartment_overkill_no_trade",
		unlock_level = 48,
		xp = gigantic_xp,
		level_id = "apartment",
		difficulty = {
			"overkill",
			"overkill_145"
		},
		increment_counter = "dont_lose_face",
		session_stopped = {
			callback = "overkill_no_trade"
		}
	}
	self.session.apartment_success_overkill_145 = {
		title_id = "ch_apartment_on_overkill_145_hl",
		description_id = "ch_apartment_on_overkill_145",
		unlock_level = 145,
		xp = gigantic_xp,
		increment_counter = "golden_boy",
		level_id = "apartment",
		difficulty = "overkill_145",
		session_stopped = {
			callback = "overkill_success"
		},
		awards_achievment = "apartment_145"
	}
	self.session.slaughterhouse_no_civilians_hard = {
		title_id = "ch_slaughterhouse_no_civilians_hl",
		description_id = "ch_slaughterhouse_no_civilians",
		unlock_level = 20,
		xp = mid_xp,
		level_id = "slaughter_house",
		difficulty = {
			"hard",
			"overkill",
			"overkill_145"
		},
		session_stopped = {
			callback = "no_civilians_killed"
		}
	}
	self.session.slaughterhouse_no_deaths_hard = {
		title_id = "ch_slaughterhouse_no_deaths_hl",
		description_id = "ch_slaughterhouse_no_deaths",
		unlock_level = 20,
		xp = large_xp,
		level_id = "slaughter_house",
		difficulty = {
			"hard",
			"overkill",
			"overkill_145"
		},
		session_stopped = {callback = "never_died"}
	}
	self.session.slaughterhouse_no_bleedouts_hard = {
		title_id = "ch_slaughterhouse_no_bleedouts_hl",
		description_id = "ch_slaughterhouse_no_bleedouts",
		unlock_level = 20,
		xp = huge_xp,
		level_id = "slaughter_house",
		difficulty = {
			"hard",
			"overkill",
			"overkill_145"
		},
		session_stopped = {
			callback = "never_bleedout"
		}
	}
	self.session.slaughterhouse_success_overkill = {
		title_id = "ch_slaughterhouse_on_overkill_hl",
		description_id = "ch_slaughterhouse_on_overkill",
		unlock_level = 48,
		xp = gigantic_xp,
		level_id = "slaughter_house",
		difficulty = {
			"overkill",
			"overkill_145"
		},
		session_stopped = {
			callback = "overkill_success"
		}
	}
	self.session.slaughterhouse_overkill_no_trade = {
		title_id = "ch_slaughterhouse_overkill_no_trade_hl",
		description_id = "ch_slaughterhouse_overkill_no_trade",
		unlock_level = 48,
		xp = gigantic_xp,
		level_id = "slaughter_house",
		difficulty = {
			"overkill",
			"overkill_145"
		},
		increment_counter = "dont_lose_face",
		session_stopped = {
			callback = "overkill_no_trade"
		}
	}
	self.session.slaughterhouse_success_overkill_145 = {
		title_id = "ch_slaughterhouse_on_overkill_145_hl",
		description_id = "ch_slaughterhouse_on_overkill_145",
		unlock_level = 145,
		xp = gigantic_xp,
		increment_counter = "golden_boy",
		level_id = "slaughter_house",
		difficulty = "overkill_145",
		session_stopped = {
			callback = "overkill_success"
		},
		awards_achievment = "slaughter_house_145"
	}
	self.session.diamond_heist_no_civilians_hard = {
		title_id = "ch_diamond_heist_no_civilians_hl",
		description_id = "ch_diamond_heist_no_civilians",
		unlock_level = 20,
		xp = mid_xp,
		level_id = "diamond_heist",
		difficulty = {
			"hard",
			"overkill",
			"overkill_145"
		},
		session_stopped = {
			callback = "no_civilians_killed"
		}
	}
	self.session.diamond_heist_no_deaths_hard = {
		title_id = "ch_diamond_heist_no_deaths_hl",
		description_id = "ch_diamond_heist_no_deaths",
		unlock_level = 20,
		xp = large_xp,
		level_id = "diamond_heist",
		difficulty = {
			"hard",
			"overkill",
			"overkill_145"
		},
		session_stopped = {callback = "never_died"}
	}
	self.session.diamond_heist_no_bleedouts_hard = {
		title_id = "ch_diamond_heist_no_bleedouts_hl",
		description_id = "ch_diamond_heist_no_bleedouts",
		unlock_level = 20,
		xp = huge_xp,
		level_id = "diamond_heist",
		difficulty = {
			"hard",
			"overkill",
			"overkill_145"
		},
		session_stopped = {
			callback = "never_bleedout"
		}
	}
	self.session.diamond_heist_success_overkill = {
		title_id = "ch_diamond_heist_on_overkill_hl",
		description_id = "ch_diamond_heist_on_overkill",
		unlock_level = 48,
		xp = gigantic_xp,
		level_id = "diamond_heist",
		difficulty = {
			"overkill",
			"overkill_145"
		},
		session_stopped = {
			callback = "overkill_success"
		}
	}
	self.session.diamond_heist_overkill_no_trade = {
		title_id = "ch_diamond_heist_overkill_no_trade_hl",
		description_id = "ch_diamond_heist_overkill_no_trade",
		unlock_level = 48,
		xp = gigantic_xp,
		level_id = "diamond_heist",
		difficulty = {
			"overkill",
			"overkill_145"
		},
		increment_counter = "dont_lose_face",
		session_stopped = {
			callback = "overkill_no_trade"
		}
	}
	self.session.diamond_heist_success_overkill_145 = {
		title_id = "ch_diamond_heist_on_overkill_145_hl",
		description_id = "ch_diamond_heist_on_overkill_145",
		unlock_level = 145,
		xp = gigantic_xp,
		increment_counter = "golden_boy",
		level_id = "diamond_heist",
		difficulty = "overkill_145",
		session_stopped = {
			callback = "overkill_success"
		},
		awards_achievment = "diamond_heist_145"
	}
	if managers.dlc:has_dlc2() then
		self.session.suburbia_no_civilians_hard = {
			title_id = "ch_suburbia_no_civilians_hl",
			description_id = "ch_suburbia_no_civilians",
			unlock_level = 20,
			xp = mid_xp,
			level_id = "suburbia",
			difficulty = {
				"hard",
				"overkill",
				"overkill_145"
			},
			session_stopped = {
				callback = "no_civilians_killed"
			}
		}
		self.session.suburbia_no_deaths_hard = {
			title_id = "ch_suburbia_no_deaths_hl",
			description_id = "ch_suburbia_no_deaths",
			unlock_level = 20,
			xp = large_xp,
			level_id = "suburbia",
			difficulty = {
				"hard",
				"overkill",
				"overkill_145"
			},
			session_stopped = {callback = "never_died"}
		}
		self.session.suburbia_no_bleedouts_hard = {
			title_id = "ch_suburbia_no_bleedouts_hl",
			description_id = "ch_suburbia_no_bleedouts",
			unlock_level = 20,
			xp = huge_xp,
			level_id = "suburbia",
			difficulty = {
				"hard",
				"overkill",
				"overkill_145"
			},
			session_stopped = {
				callback = "never_bleedout"
			}
		}
		self.session.suburbia_success_overkill = {
			title_id = "ch_suburbia_on_overkill_hl",
			description_id = "ch_suburbia_on_overkill",
			unlock_level = 48,
			xp = gigantic_xp,
			level_id = "suburbia",
			difficulty = {
				"overkill",
				"overkill_145"
			},
			session_stopped = {
				callback = "overkill_success"
			}
		}
		self.session.suburbia_overkill_no_trade = {
			title_id = "ch_suburbia_overkill_no_trade_hl",
			description_id = "ch_suburbia_overkill_no_trade",
			unlock_level = 48,
			xp = gigantic_xp,
			level_id = "suburbia",
			difficulty = {
				"overkill",
				"overkill_145"
			},
			session_stopped = {
				callback = "overkill_no_trade"
			}
		}
		self.session.suburbia_success_overkill_145 = {
			title_id = "ch_suburbia_on_overkill_145_hl",
			description_id = "ch_suburbia_on_overkill_145",
			unlock_level = 145,
			xp = gigantic_xp,
			level_id = "suburbia",
			difficulty = "overkill_145",
			session_stopped = {
				callback = "overkill_success"
			},
			awards_achievment = "suburbia_145"
		}
	end
	if managers.dlc:has_dlc3() then
		self.session.secret_stash_no_deaths_hard = {
			title_id = "ch_secret_stash_no_deaths_hl",
			description_id = "ch_secret_stash_no_deaths",
			unlock_level = 20,
			xp = large_xp,
			level_id = "secret_stash",
			difficulty = {
				"hard",
				"overkill",
				"overkill_145"
			},
			session_stopped = {callback = "never_died"}
		}
		self.session.secret_stash_no_bleedouts_hard = {
			title_id = "ch_secret_stash_no_bleedouts_hl",
			description_id = "ch_secret_stash_no_bleedouts",
			unlock_level = 20,
			xp = huge_xp,
			level_id = "secret_stash",
			difficulty = {
				"hard",
				"overkill",
				"overkill_145"
			},
			session_stopped = {
				callback = "never_bleedout"
			}
		}
		self.session.secret_stash_success_overkill = {
			title_id = "ch_secret_stash_on_overkill_hl",
			description_id = "ch_secret_stash_on_overkill",
			unlock_level = 48,
			xp = gigantic_xp,
			level_id = "secret_stash",
			difficulty = {
				"overkill",
				"overkill_145"
			},
			session_stopped = {
				callback = "overkill_success"
			}
		}
		self.session.secret_stash_overkill_no_trade = {
			title_id = "ch_secret_stash_overkill_no_trade_hl",
			description_id = "ch_secret_stash_overkill_no_trade",
			unlock_level = 48,
			xp = gigantic_xp,
			level_id = "secret_stash",
			difficulty = {
				"overkill",
				"overkill_145"
			},
			session_stopped = {
				callback = "overkill_no_trade"
			}
		}
		self.session.secret_stash_success_overkill_145 = {
			title_id = "ch_secret_stash_on_overkill_145_hl",
			description_id = "ch_secret_stash_on_overkill_145",
			unlock_level = 145,
			xp = gigantic_xp,
			level_id = "secret_stash",
			difficulty = "overkill_145",
			session_stopped = {
				callback = "overkill_success"
			},
			awards_achievment = "secret_stash_145"
		}
	end
end
function ChallengesTweakData:_any_weapon_challenges()
	local definition = {}
	definition.me = {}
	definition.me.vs_the_law = {
		{
			count = 100,
			xp = tiny_xp,
			in_trial = true
		},
		{count = 400, xp = small_xp},
		{count = 800, xp = mid_xp}
	}
	definition.me.vs_the_law_head_shot = {
		{count = 100, xp = tiny_xp},
		{count = 300, xp = small_xp},
		{count = 600, xp = mid_xp},
		{count = 900, xp = large_xp},
		{count = 1800, xp = huge_xp}
	}
	for i = 1, #definition.me.vs_the_law do
		local name = "me_vs_the_law_" .. i
		local count = definition.me.vs_the_law[i].count
		local xp = definition.me.vs_the_law[i].xp
		local challenges = {
			i - 1 > 0 and "me_vs_the_law_" .. i - 1 or nil
		}
		local depends_on = {challenges = challenges}
		self.weapon[name] = {
			title_id = "ch_me_vs_the_law_" .. i .. "_hl",
			description_id = "ch_me_vs_the_law",
			counter_id = "law_kill",
			unlock_level = 0,
			count = count,
			xp = xp,
			depends_on = depends_on,
			in_trial = definition.me.vs_the_law[i].in_trial
		}
	end
	for i = 1, #definition.me.vs_the_law_head_shot do
		local name = "me_vs_the_law_head_shot_" .. i
		local count = definition.me.vs_the_law_head_shot[i].count
		local xp = definition.me.vs_the_law_head_shot[i].xp
		local challenges = {
			i - 1 > 0 and "me_vs_the_law_head_shot_" .. i - 1 or "me_vs_the_law_2"
		}
		local depends_on = {challenges = challenges}
		self.weapon[name] = {
			title_id = "ch_me_vs_the_law_head_shot_" .. i .. "_hl",
			description_id = "ch_me_vs_the_law_head_shot",
			counter_id = "law_head_shot",
			unlock_level = 0,
			count = count,
			xp = xp,
			depends_on = depends_on,
			in_trial = definition.me.vs_the_law_head_shot[i].in_trial
		}
	end
	self.weapon.me_vs_cop = {
		title_id = "ch_me_vs_cop_hl",
		description_id = "ch_me_vs_cop",
		counter_id = "cop_kill",
		unlock_level = 0,
		count = 100,
		xp = mid_xp,
		depends_on = {
			challenges = {
				"me_vs_the_law_3"
			}
		}
	}
	self.weapon.me_vs_swat = {
		title_id = "ch_me_vs_swat_hl",
		description_id = "ch_me_vs_swat",
		counter_id = "swat_kill",
		unlock_level = 0,
		count = 150,
		xp = mid_xp,
		depends_on = {
			challenges = {"me_vs_cop"}
		}
	}
	self.weapon.me_vs_fbi = {
		title_id = "ch_me_vs_fbi_hl",
		description_id = "ch_me_vs_fbi",
		counter_id = "fbi_kill",
		unlock_level = 0,
		count = 200,
		xp = mid_xp,
		depends_on = {
			challenges = {"me_vs_swat"}
		}
	}
	self.weapon.me_vs_heavy_swat = {
		title_id = "ch_me_vs_heavy_swat_hl",
		description_id = "ch_me_vs_heavy_swat",
		counter_id = "heavy_swat_kill",
		unlock_level = 0,
		count = 250,
		xp = large_xp,
		depends_on = {
			challenges = {"me_vs_fbi"}
		}
	}
	self.weapon.me_vs_shield = {
		title_id = "ch_me_vs_shield_hl",
		description_id = "ch_me_vs_shield",
		counter_id = "shield_kill",
		unlock_level = 0,
		count = 100,
		xp = huge_xp,
		depends_on = {
			challenges = {
				"me_vs_heavy_swat"
			}
		}
	}
	self.weapon.me_vs_taser = {
		title_id = "ch_me_vs_taser_hl",
		description_id = "ch_me_vs_taser",
		counter_id = "taser_kill",
		unlock_level = 0,
		count = 100,
		xp = gigantic_xp,
		depends_on = {
			challenges = {
				"me_vs_shield"
			}
		}
	}
	self.weapon.me_vs_spooc = {
		title_id = "ch_me_vs_spooc_hl",
		description_id = "ch_me_vs_spooc",
		counter_id = "spooc_kill",
		unlock_level = 0,
		count = 100,
		xp = gigantic_xp,
		depends_on = {
			challenges = {
				"me_vs_taser"
			}
		}
	}
	self.weapon.me_vs_tank = {
		title_id = "ch_me_vs_tank_hl",
		description_id = "ch_me_vs_tank",
		counter_id = "tank_kill",
		unlock_level = 0,
		count = 100,
		xp = gigantic_xp,
		depends_on = {
			challenges = {
				"me_vs_spooc"
			}
		}
	}
end
function ChallengesTweakData:_c45_challenges()
	local definition = {}
	definition.c45 = {}
	definition.c45.vs_the_law = {
		{count = 50, xp = tiny_xp},
		{count = 200, xp = small_xp},
		{count = 400, xp = mid_xp},
		{count = 600, xp = large_xp},
		{count = 800, xp = large_xp},
		{count = 1000, xp = large_xp}
	}
	definition.c45.head_shots = {
		{count = 75, xp = small_xp},
		{count = 200, xp = mid_xp},
		{count = 350, xp = large_xp},
		{count = 500, xp = large_xp}
	}
	definition.c45.fbi_kill = {
		{count = 60, xp = huge_xp}
	}
	for i = 1, #definition.c45.vs_the_law do
		local name = "c45_vs_the_law_" .. i
		local count = definition.c45.vs_the_law[i].count
		local xp = definition.c45.vs_the_law[i].xp
		local challenges = {
			i - 1 > 0 and "c45_vs_the_law_" .. i - 1 or nil
		}
		local depends_on = {
			challenges = challenges,
			weapons = {"c45"}
		}
		self.weapon[name] = {
			title_id = "ch_c45_vs_the_law_" .. i .. "_hl",
			description_id = "ch_c45_vs_the_law",
			counter_id = "c45_law_kill",
			unlock_level = 0,
			count = count,
			xp = xp,
			depends_on = depends_on
		}
	end
	for i = 1, #definition.c45.head_shots do
		local name = "c45_head_shots_" .. i
		local count = definition.c45.head_shots[i].count
		local xp = definition.c45.head_shots[i].xp
		local challenges = {
			i - 1 > 0 and "c45_head_shots_" .. i - 1 or "c45_vs_the_law_3"
		}
		local depends_on = {
			challenges = challenges,
			weapons = {"c45"}
		}
		self.weapon[name] = {
			title_id = "ch_c45_head_shots_" .. i .. "_hl",
			description_id = "ch_c45_head_shots",
			counter_id = "c45_law_head_shot",
			unlock_level = 0,
			count = count,
			xp = xp,
			depends_on = depends_on
		}
	end
	for i = 1, #definition.c45.fbi_kill do
		local name = "c45_fbi_kill_" .. i
		local count = definition.c45.fbi_kill[i].count
		local xp = definition.c45.fbi_kill[i].xp
		local challenges = {
			i - 1 > 0 and "c45_fbi_kill" .. i - 1 or "c45_vs_the_law_5"
		}
		local depends_on = {
			challenges = challenges,
			weapons = {"c45"}
		}
		self.weapon[name] = {
			title_id = "ch_c45_fbi_kill_" .. i .. "_hl",
			description_id = "ch_c45_fbi_kill",
			counter_id = "c45_fbi_kill",
			unlock_level = 0,
			count = count,
			xp = xp,
			depends_on = depends_on
		}
	end
end
function ChallengesTweakData:_beretta92_challenges()
	local definition = {}
	definition.beretta92 = {}
	definition.beretta92.vs_the_law = {
		{count = 50, xp = tiny_xp},
		{count = 200, xp = small_xp},
		{count = 400, xp = mid_xp},
		{count = 600, xp = large_xp},
		{count = 800, xp = large_xp},
		{count = 1000, xp = large_xp}
	}
	definition.beretta92.head_shots = {
		{count = 75, xp = small_xp},
		{count = 200, xp = mid_xp},
		{count = 350, xp = large_xp},
		{count = 500, xp = large_xp}
	}
	definition.beretta92.taser_kill = {
		{count = 20, xp = huge_xp}
	}
	for i = 1, #definition.beretta92.vs_the_law do
		local name = "beretta92_vs_the_law_" .. i
		local count = definition.beretta92.vs_the_law[i].count
		local xp = definition.beretta92.vs_the_law[i].xp
		local challenges = {
			i - 1 > 0 and "beretta92_vs_the_law_" .. i - 1 or nil
		}
		local depends_on = {challenges = challenges}
		self.weapon[name] = {
			title_id = "ch_beretta92_vs_the_law_" .. i .. "_hl",
			description_id = "ch_beretta92_vs_the_law",
			counter_id = "beretta92_law_kill",
			unlock_level = 0,
			count = count,
			xp = xp,
			depends_on = depends_on
		}
	end
	for i = 1, #definition.beretta92.head_shots do
		local name = "beretta92_head_shots_" .. i
		local count = definition.beretta92.head_shots[i].count
		local xp = definition.beretta92.head_shots[i].xp
		local challenges = {
			i - 1 > 0 and "beretta92_head_shots_" .. i - 1 or "beretta92_vs_the_law_3"
		}
		local depends_on = {challenges = challenges}
		self.weapon[name] = {
			title_id = "ch_beretta92_head_shots_" .. i .. "_hl",
			description_id = "ch_beretta92_head_shots",
			counter_id = "beretta92_law_head_shot",
			unlock_level = 0,
			count = count,
			xp = xp,
			depends_on = depends_on
		}
	end
	for i = 1, #definition.beretta92.taser_kill do
		local name = "beretta92_taser_kill_" .. i
		local count = definition.beretta92.taser_kill[i].count
		local xp = definition.beretta92.taser_kill[i].xp
		local challenges = {
			i - 1 > 0 and "beretta92_taser_kill" .. i - 1 or "beretta92_vs_the_law_5"
		}
		local depends_on = {challenges = challenges}
		self.weapon[name] = {
			title_id = "ch_beretta92_taser_kill_" .. i .. "_hl",
			description_id = "ch_beretta92_taser_kill",
			counter_id = "beretta92_taser_kill",
			unlock_level = 0,
			count = count,
			xp = xp,
			depends_on = depends_on
		}
	end
end
function ChallengesTweakData:_bronco_challenges()
	local definition = {}
	definition.bronco = {}
	definition.bronco.vs_the_law = {
		{count = 50, xp = tiny_xp},
		{count = 200, xp = small_xp},
		{count = 400, xp = mid_xp},
		{count = 600, xp = large_xp},
		{count = 800, xp = large_xp},
		{count = 1000, xp = large_xp}
	}
	definition.bronco.head_shots = {
		{count = 75, xp = small_xp},
		{count = 200, xp = mid_xp},
		{count = 350, xp = large_xp},
		{count = 500, xp = large_xp}
	}
	definition.bronco.tank_kill = {
		{count = 5, xp = huge_xp}
	}
	for i = 1, #definition.bronco.vs_the_law do
		local name = "bronco_vs_the_law_" .. i
		local count = definition.bronco.vs_the_law[i].count
		local xp = definition.bronco.vs_the_law[i].xp
		local challenges = {
			i - 1 > 0 and "bronco_vs_the_law_" .. i - 1 or nil
		}
		local depends_on = {
			challenges = challenges,
			weapons = {
				"raging_bull"
			}
		}
		self.weapon[name] = {
			title_id = "ch_bronco_vs_the_law_" .. i .. "_hl",
			description_id = "ch_bronco_vs_the_law",
			counter_id = "bronco_law_kill",
			unlock_level = 0,
			count = count,
			xp = xp,
			depends_on = depends_on
		}
	end
	for i = 1, #definition.bronco.head_shots do
		local name = "bronco_head_shots_" .. i
		local count = definition.bronco.head_shots[i].count
		local xp = definition.bronco.head_shots[i].xp
		local challenges = {
			i - 1 > 0 and "bronco_head_shots_" .. i - 1 or "bronco_vs_the_law_3"
		}
		local depends_on = {
			challenges = challenges,
			weapons = {
				"raging_bull"
			}
		}
		self.weapon[name] = {
			title_id = "ch_bronco_head_shots_" .. i .. "_hl",
			description_id = "ch_bronco_head_shots",
			counter_id = "bronco_law_head_shot",
			unlock_level = 0,
			count = count,
			xp = xp,
			depends_on = depends_on
		}
	end
	for i = 1, #definition.bronco.tank_kill do
		local name = "bronco_tank_kill_" .. i
		local count = definition.bronco.tank_kill[i].count
		local xp = definition.bronco.tank_kill[i].xp
		local challenges = {
			i - 1 > 0 and "bronco_tank_kill" .. i - 1 or "bronco_vs_the_law_5"
		}
		local depends_on = {
			challenges = challenges,
			weapons = {
				"raging_bull"
			}
		}
		self.weapon[name] = {
			title_id = "ch_bronco_tank_kill_" .. i .. "_hl",
			description_id = "ch_bronco_tank_kill",
			counter_id = "bronco_tank_kill",
			unlock_level = 0,
			count = count,
			xp = xp,
			depends_on = depends_on
		}
	end
end
function ChallengesTweakData:_reinbeck_challenges()
	local definition = {}
	definition.reinbeck = {}
	definition.reinbeck.vs_the_law = {
		{count = 50, xp = tiny_xp},
		{count = 200, xp = small_xp},
		{count = 400, xp = mid_xp},
		{count = 600, xp = large_xp},
		{count = 800, xp = large_xp},
		{count = 1000, xp = large_xp}
	}
	definition.reinbeck.head_shots = {
		{count = 75, xp = small_xp},
		{count = 200, xp = mid_xp},
		{count = 350, xp = large_xp},
		{count = 500, xp = large_xp}
	}
	definition.reinbeck.spooc_kill = {
		{count = 20, xp = huge_xp}
	}
	for i = 1, #definition.reinbeck.vs_the_law do
		local name = "reinbeck_vs_the_law_" .. i
		local count = definition.reinbeck.vs_the_law[i].count
		local xp = definition.reinbeck.vs_the_law[i].xp
		local challenges = {
			i - 1 > 0 and "reinbeck_vs_the_law_" .. i - 1 or nil
		}
		local depends_on = {
			challenges = challenges,
			weapons = {
				"r870_shotgun"
			}
		}
		self.weapon[name] = {
			title_id = "ch_reinbeck_vs_the_law_" .. i .. "_hl",
			description_id = "ch_reinbeck_vs_the_law",
			counter_id = "reinbeck_law_kill",
			unlock_level = 0,
			count = count,
			xp = xp,
			depends_on = depends_on
		}
	end
	for i = 1, #definition.reinbeck.head_shots do
		local name = "reinbeck_head_shots_" .. i
		local count = definition.reinbeck.head_shots[i].count
		local xp = definition.reinbeck.head_shots[i].xp
		local challenges = {
			i - 1 > 0 and "reinbeck_head_shots_" .. i - 1 or "reinbeck_vs_the_law_3"
		}
		local depends_on = {
			challenges = challenges,
			weapons = {
				"r870_shotgun"
			}
		}
		self.weapon[name] = {
			title_id = "ch_reinbeck_head_shots_" .. i .. "_hl",
			description_id = "ch_reinbeck_head_shots",
			counter_id = "reinbeck_law_head_shot",
			unlock_level = 0,
			count = count,
			xp = xp,
			depends_on = depends_on
		}
	end
	for i = 1, #definition.reinbeck.spooc_kill do
		local name = "reinbeck_spooc_kill_" .. i
		local count = definition.reinbeck.spooc_kill[i].count
		local xp = definition.reinbeck.spooc_kill[i].xp
		local challenges = {
			i - 1 > 0 and "reinbeck_spooc_kill" .. i - 1 or "reinbeck_vs_the_law_5"
		}
		local depends_on = {
			challenges = challenges,
			weapons = {
				"r870_shotgun"
			}
		}
		self.weapon[name] = {
			title_id = "ch_reinbeck_spooc_kill_" .. i .. "_hl",
			description_id = "ch_reinbeck_spooc_kill",
			counter_id = "reinbeck_spooc_kill",
			unlock_level = 0,
			count = count,
			xp = xp,
			depends_on = depends_on
		}
	end
end
function ChallengesTweakData:_mossberg_challenges()
	local definition = {}
	definition.mossberg = {}
	definition.mossberg.vs_the_law = {
		{count = 50, xp = tiny_xp},
		{count = 200, xp = small_xp},
		{count = 400, xp = mid_xp},
		{count = 600, xp = large_xp},
		{count = 800, xp = large_xp},
		{count = 1000, xp = large_xp}
	}
	definition.mossberg.head_shots = {
		{count = 75, xp = small_xp},
		{count = 200, xp = mid_xp},
		{count = 350, xp = large_xp},
		{count = 500, xp = large_xp}
	}
	definition.mossberg.cop_kill = {
		{count = 20, xp = huge_xp}
	}
	for i = 1, #definition.mossberg.vs_the_law do
		local name = "mossberg_vs_the_law_" .. i
		local count = definition.mossberg.vs_the_law[i].count
		local xp = definition.mossberg.vs_the_law[i].xp
		local challenges = {
			i - 1 > 0 and "mossberg_vs_the_law_" .. i - 1 or nil
		}
		local depends_on = {
			challenges = challenges,
			weapons = {"mossberg"}
		}
		self.weapon[name] = {
			title_id = "ch_mossberg_vs_the_law_" .. i .. "_hl",
			description_id = "ch_mossberg_vs_the_law",
			counter_id = "mossberg_law_kill",
			unlock_level = 0,
			count = count,
			xp = xp,
			depends_on = depends_on
		}
	end
	for i = 1, #definition.mossberg.head_shots do
		local name = "mossberg_head_shots_" .. i
		local count = definition.mossberg.head_shots[i].count
		local xp = definition.mossberg.head_shots[i].xp
		local challenges = {
			i - 1 > 0 and "mossberg_head_shots_" .. i - 1 or "mossberg_vs_the_law_3"
		}
		local depends_on = {
			challenges = challenges,
			weapons = {"mossberg"}
		}
		self.weapon[name] = {
			title_id = "ch_mossberg_head_shots_" .. i .. "_hl",
			description_id = "ch_mossberg_head_shots",
			counter_id = "mossberg_law_head_shot",
			unlock_level = 0,
			count = count,
			xp = xp,
			depends_on = depends_on
		}
	end
	for i = 1, #definition.mossberg.cop_kill do
		local name = "mossberg_cop_kill_" .. i
		local count = definition.mossberg.cop_kill[i].count
		local xp = definition.mossberg.cop_kill[i].xp
		local challenges = {
			i - 1 > 0 and "mossberg_cop_kill" .. i - 1 or "mossberg_vs_the_law_5"
		}
		local depends_on = {
			challenges = challenges,
			weapons = {"mossberg"}
		}
		self.weapon[name] = {
			title_id = "ch_mossberg_cop_kill_" .. i .. "_hl",
			description_id = "ch_mossberg_cop_kill",
			counter_id = "mossberg_cop_kill",
			unlock_level = 0,
			count = count,
			xp = xp,
			depends_on = depends_on
		}
	end
end
function ChallengesTweakData:_mp5_challenges()
	local definition = {}
	definition.mp5 = {}
	definition.mp5.vs_the_law = {
		{count = 50, xp = tiny_xp},
		{count = 200, xp = small_xp},
		{count = 400, xp = mid_xp},
		{count = 600, xp = large_xp},
		{count = 800, xp = large_xp},
		{count = 1000, xp = large_xp}
	}
	definition.mp5.head_shots = {
		{count = 75, xp = small_xp},
		{count = 200, xp = mid_xp},
		{count = 350, xp = large_xp},
		{count = 500, xp = large_xp}
	}
	definition.mp5.shield_head_shots = {
		{count = 10, xp = huge_xp}
	}
	for i = 1, #definition.mp5.vs_the_law do
		local name = "mp5_vs_the_law_" .. i
		local count = definition.mp5.vs_the_law[i].count
		local xp = definition.mp5.vs_the_law[i].xp
		local challenges = {
			i - 1 > 0 and "mp5_vs_the_law_" .. i - 1 or nil
		}
		local depends_on = {
			challenges = challenges,
			weapons = {"mp5"}
		}
		self.weapon[name] = {
			title_id = "ch_mp5_vs_the_law_" .. i .. "_hl",
			description_id = "ch_mp5_vs_the_law",
			counter_id = "mp5_law_kill",
			unlock_level = 0,
			count = count,
			xp = xp,
			depends_on = depends_on
		}
	end
	for i = 1, #definition.mp5.head_shots do
		local name = "mp5_head_shots_" .. i
		local count = definition.mp5.head_shots[i].count
		local xp = definition.mp5.head_shots[i].xp
		local challenges = {
			i - 1 > 0 and "mp5_head_shots_" .. i - 1 or "mp5_vs_the_law_3"
		}
		local depends_on = {
			challenges = challenges,
			weapons = {"mp5"}
		}
		self.weapon[name] = {
			title_id = "ch_mp5_head_shots_" .. i .. "_hl",
			description_id = "ch_mp5_head_shots",
			counter_id = "mp5_law_head_shot",
			unlock_level = 0,
			count = count,
			xp = xp,
			depends_on = depends_on
		}
	end
	for i = 1, #definition.mp5.shield_head_shots do
		local name = "mp5_shield_head_shots_" .. i
		local count = definition.mp5.shield_head_shots[i].count
		local xp = definition.mp5.shield_head_shots[i].xp
		local challenges = {
			i - 1 > 0 and "mp5_shield_head_shots" .. i - 1 or "mp5_vs_the_law_5"
		}
		local depends_on = {
			challenges = challenges,
			weapons = {"mp5"}
		}
		self.weapon[name] = {
			title_id = "ch_mp5_shield_head_shot_" .. i .. "_hl",
			description_id = "ch_mp5_shield_head_shot",
			counter_id = "mp5_shield_head_shot",
			unlock_level = 0,
			count = count,
			xp = xp,
			depends_on = depends_on
		}
	end
end
function ChallengesTweakData:_mac11_challenges()
	local definition = {}
	definition.mac11 = {}
	definition.mac11.vs_the_law = {
		{count = 50, xp = tiny_xp},
		{count = 200, xp = small_xp},
		{count = 400, xp = mid_xp},
		{count = 600, xp = large_xp},
		{count = 800, xp = large_xp},
		{count = 1000, xp = large_xp}
	}
	definition.mac11.head_shots = {
		{count = 75, xp = small_xp},
		{count = 200, xp = mid_xp},
		{count = 350, xp = large_xp},
		{count = 500, xp = large_xp}
	}
	definition.mac11.heavy_swat_kill = {
		{count = 120, xp = huge_xp}
	}
	for i = 1, #definition.mac11.vs_the_law do
		local name = "mac11_vs_the_law_" .. i
		local count = definition.mac11.vs_the_law[i].count
		local xp = definition.mac11.vs_the_law[i].xp
		local challenges = {
			i - 1 > 0 and "mac11_vs_the_law_" .. i - 1 or nil
		}
		local depends_on = {
			challenges = challenges,
			weapons = {"mac11"}
		}
		self.weapon[name] = {
			title_id = "ch_mac11_vs_the_law_" .. i .. "_hl",
			description_id = "ch_mac11_vs_the_law",
			counter_id = "mac11_law_kill",
			unlock_level = 0,
			count = count,
			xp = xp,
			depends_on = depends_on
		}
	end
	for i = 1, #definition.mac11.head_shots do
		local name = "mac11_head_shots_" .. i
		local count = definition.mac11.head_shots[i].count
		local xp = definition.mac11.head_shots[i].xp
		local challenges = {
			i - 1 > 0 and "mac11_head_shots_" .. i - 1 or "mac11_vs_the_law_3"
		}
		local depends_on = {
			challenges = challenges,
			weapons = {"mac11"}
		}
		self.weapon[name] = {
			title_id = "ch_mac11_head_shots_" .. i .. "_hl",
			description_id = "ch_mac11_head_shots",
			counter_id = "mac11_law_head_shot",
			unlock_level = 0,
			count = count,
			xp = xp,
			depends_on = depends_on
		}
	end
	for i = 1, #definition.mac11.heavy_swat_kill do
		local name = "mac11_heavy_swat_kill_" .. i
		local count = definition.mac11.heavy_swat_kill[i].count
		local xp = definition.mac11.heavy_swat_kill[i].xp
		local challenges = {
			i - 1 > 0 and "mac11_heavy_swat_kill" .. i - 1 or "mac11_vs_the_law_5"
		}
		local depends_on = {
			challenges = challenges,
			weapons = {"mac11"}
		}
		self.weapon[name] = {
			title_id = "ch_mac11_heavy_swat_kill_" .. i .. "_hl",
			description_id = "ch_mac11_heavy_swat_kill",
			counter_id = "mac11_heavy_swat_kill",
			unlock_level = 0,
			count = count,
			xp = xp,
			depends_on = depends_on
		}
	end
end
function ChallengesTweakData:_m4_challenges()
	local definition = {}
	definition.m4 = {}
	definition.m4.vs_the_law = {
		{count = 50, xp = tiny_xp},
		{count = 200, xp = small_xp},
		{count = 400, xp = mid_xp},
		{count = 600, xp = large_xp},
		{count = 800, xp = large_xp},
		{count = 1000, xp = large_xp}
	}
	definition.m4.head_shots = {
		{count = 75, xp = small_xp},
		{count = 200, xp = mid_xp},
		{count = 350, xp = large_xp},
		{count = 500, xp = large_xp}
	}
	definition.m4.spooc_head_shot = {
		{count = 20, xp = huge_xp}
	}
	for i = 1, #definition.m4.vs_the_law do
		local name = "m4_vs_the_law_" .. i
		local count = definition.m4.vs_the_law[i].count
		local xp = definition.m4.vs_the_law[i].xp
		local challenges = {
			i - 1 > 0 and "m4_vs_the_law_" .. i - 1 or nil
		}
		local depends_on = {challenges = challenges, weapons = nil}
		self.weapon[name] = {
			title_id = "ch_m4_vs_the_law_" .. i .. "_hl",
			description_id = "ch_m4_vs_the_law",
			counter_id = "m4_law_kill",
			unlock_level = 0,
			count = count,
			xp = xp,
			depends_on = depends_on
		}
	end
	for i = 1, #definition.m4.head_shots do
		local name = "m4_head_shots_" .. i
		local count = definition.m4.head_shots[i].count
		local xp = definition.m4.head_shots[i].xp
		local challenges = {
			i - 1 > 0 and "m4_head_shots_" .. i - 1 or "m4_vs_the_law_3"
		}
		local depends_on = {challenges = challenges, weapons = nil}
		self.weapon[name] = {
			title_id = "ch_m4_head_shots_" .. i .. "_hl",
			description_id = "ch_m4_head_shots",
			counter_id = "m4_law_head_shot",
			unlock_level = 0,
			count = count,
			xp = xp,
			depends_on = depends_on
		}
	end
	for i = 1, #definition.m4.spooc_head_shot do
		local name = "m4_spooc_head_shot_" .. i
		local count = definition.m4.spooc_head_shot[i].count
		local xp = definition.m4.spooc_head_shot[i].xp
		local challenges = {
			i - 1 > 0 and "m4_spooc_head_shot" .. i - 1 or "m4_vs_the_law_5"
		}
		local depends_on = {challenges = challenges, weapons = nil}
		self.weapon[name] = {
			title_id = "ch_m4_spooc_head_shot_" .. i .. "_hl",
			description_id = "ch_m4_spooc_head_shot",
			counter_id = "m4_spooc_head_shot",
			unlock_level = 0,
			count = count,
			xp = xp,
			depends_on = depends_on
		}
	end
end
function ChallengesTweakData:_m14_challenges()
	local definition = {}
	definition.m14 = {}
	definition.m14.vs_the_law = {
		{count = 50, xp = tiny_xp},
		{count = 200, xp = small_xp},
		{count = 400, xp = mid_xp},
		{count = 600, xp = large_xp},
		{count = 800, xp = large_xp},
		{count = 1000, xp = large_xp}
	}
	definition.m14.head_shots = {
		{count = 75, xp = small_xp},
		{count = 200, xp = mid_xp},
		{count = 350, xp = large_xp},
		{count = 500, xp = large_xp}
	}
	definition.m14.taser_head_shot = {
		{count = 15, xp = huge_xp}
	}
	for i = 1, #definition.m14.vs_the_law do
		local name = "m14_vs_the_law_" .. i
		local count = definition.m14.vs_the_law[i].count
		local xp = definition.m14.vs_the_law[i].xp
		local challenges = {
			i - 1 > 0 and "m14_vs_the_law_" .. i - 1 or nil
		}
		local depends_on = {
			challenges = challenges,
			weapons = {"m14"}
		}
		self.weapon[name] = {
			title_id = "ch_m14_vs_the_law_" .. i .. "_hl",
			description_id = "ch_m14_vs_the_law",
			counter_id = "m14_law_kill",
			unlock_level = 0,
			count = count,
			xp = xp,
			depends_on = depends_on
		}
	end
	for i = 1, #definition.m14.head_shots do
		local name = "m14_head_shots_" .. i
		local count = definition.m14.head_shots[i].count
		local xp = definition.m14.head_shots[i].xp
		local challenges = {
			i - 1 > 0 and "m14_head_shots_" .. i - 1 or "m14_vs_the_law_3"
		}
		local depends_on = {
			challenges = challenges,
			weapons = {"m14"}
		}
		self.weapon[name] = {
			title_id = "ch_m14_head_shots_" .. i .. "_hl",
			description_id = "ch_m14_head_shots",
			counter_id = "m14_law_head_shot",
			unlock_level = 0,
			count = count,
			xp = xp,
			depends_on = depends_on
		}
	end
	for i = 1, #definition.m14.taser_head_shot do
		local name = "m14_taser_head_shot_" .. i
		local count = definition.m14.taser_head_shot[i].count
		local xp = definition.m14.taser_head_shot[i].xp
		local challenges = {
			i - 1 > 0 and "m14_taser_head_shot" .. i - 1 or "m14_vs_the_law_5"
		}
		local depends_on = {
			challenges = challenges,
			weapons = {"m14"}
		}
		self.weapon[name] = {
			title_id = "ch_m14_taser_head_shot_" .. i .. "_hl",
			description_id = "ch_m14_taser_head_shot",
			counter_id = "m14_taser_head_shot",
			unlock_level = 0,
			count = count,
			xp = xp,
			depends_on = depends_on
		}
	end
end
function ChallengesTweakData:_hk21_challenges()
	local definition = {}
	definition.hk21 = {}
	definition.hk21.vs_the_law = {
		{count = 50, xp = tiny_xp},
		{count = 200, xp = small_xp},
		{count = 400, xp = mid_xp},
		{count = 600, xp = large_xp},
		{count = 800, xp = large_xp},
		{count = 1000, xp = large_xp}
	}
	definition.hk21.head_shots = {
		{count = 75, xp = small_xp},
		{count = 200, xp = mid_xp},
		{count = 350, xp = large_xp},
		{count = 500, xp = large_xp}
	}
	definition.hk21.shield_kill = {
		{count = 30, xp = huge_xp}
	}
	for i = 1, #definition.hk21.vs_the_law do
		local name = "hk21_vs_the_law_" .. i
		local count = definition.hk21.vs_the_law[i].count
		local xp = definition.hk21.vs_the_law[i].xp
		local challenges = {
			i - 1 > 0 and "hk21_vs_the_law_" .. i - 1 or nil
		}
		local depends_on = {
			challenges = challenges,
			weapons = {"hk21"}
		}
		self.weapon[name] = {
			title_id = "ch_hk21_vs_the_law_" .. i .. "_hl",
			description_id = "ch_hk21_vs_the_law",
			counter_id = "hk21_law_kill",
			unlock_level = 0,
			count = count,
			xp = xp,
			depends_on = depends_on
		}
	end
	for i = 1, #definition.hk21.head_shots do
		local name = "hk21_head_shots_" .. i
		local count = definition.hk21.head_shots[i].count
		local xp = definition.hk21.head_shots[i].xp
		local challenges = {
			i - 1 > 0 and "hk21_head_shots_" .. i - 1 or "hk21_vs_the_law_3"
		}
		local depends_on = {
			challenges = challenges,
			weapons = {"hk21"}
		}
		self.weapon[name] = {
			title_id = "ch_hk21_head_shots_" .. i .. "_hl",
			description_id = "ch_hk21_head_shots",
			counter_id = "hk21_law_head_shot",
			unlock_level = 0,
			count = count,
			xp = xp,
			depends_on = depends_on
		}
	end
	for i = 1, #definition.hk21.shield_kill do
		local name = "hk21_shield_kill_" .. i
		local count = definition.hk21.shield_kill[i].count
		local xp = definition.hk21.shield_kill[i].xp
		local challenges = {
			i - 1 > 0 and "hk21_shield_kill" .. i - 1 or "hk21_vs_the_law_5"
		}
		local depends_on = {
			challenges = challenges,
			weapons = {"hk21"}
		}
		self.weapon[name] = {
			title_id = "ch_hk21_shield_kill_" .. i .. "_hl",
			description_id = "ch_hk21_shield_kill",
			counter_id = "hk21_shield_kill",
			unlock_level = 0,
			count = count,
			xp = xp,
			depends_on = depends_on
		}
	end
end
function ChallengesTweakData:_glock_challenges()
	local definition = {}
	definition.glock = {}
	definition.glock.vs_the_law = {
		{count = 50, xp = tiny_xp},
		{count = 200, xp = small_xp},
		{count = 400, xp = mid_xp},
		{count = 600, xp = large_xp},
		{count = 800, xp = large_xp},
		{count = 1000, xp = large_xp}
	}
	definition.glock.head_shots = {
		{count = 75, xp = small_xp},
		{count = 200, xp = mid_xp},
		{count = 350, xp = large_xp},
		{count = 500, xp = large_xp}
	}
	definition.glock.shield_body_shots = {
		{count = 20, xp = huge_xp}
	}
	for i = 1, #definition.glock.vs_the_law do
		local name = "glock_vs_the_law_" .. i
		local count = definition.glock.vs_the_law[i].count
		local xp = definition.glock.vs_the_law[i].xp
		local challenges = {
			i - 1 > 0 and "glock_vs_the_law_" .. i - 1 or nil
		}
		local depends_on = {
			challenges = challenges,
			weapons = {"glock"}
		}
		self.weapon[name] = {
			title_id = "ch_glock_vs_the_law_" .. i .. "_hl",
			description_id = "ch_glock_vs_the_law",
			counter_id = "glock_law_kill",
			unlock_level = 0,
			count = count,
			xp = xp,
			depends_on = depends_on
		}
	end
	for i = 1, #definition.glock.head_shots do
		local name = "glock_head_shots_" .. i
		local count = definition.glock.head_shots[i].count
		local xp = definition.glock.head_shots[i].xp
		local challenges = {
			i - 1 > 0 and "glock_head_shots_" .. i - 1 or "glock_vs_the_law_3"
		}
		local depends_on = {
			challenges = challenges,
			weapons = {"glock"}
		}
		self.weapon[name] = {
			title_id = "ch_glock_head_shots_" .. i .. "_hl",
			description_id = "ch_glock_head_shots",
			counter_id = "glock_law_head_shot",
			unlock_level = 0,
			count = count,
			xp = xp,
			depends_on = depends_on
		}
	end
	for i = 1, #definition.glock.shield_body_shots do
		local name = "glock_shield_body_shots_" .. i
		local count = definition.glock.shield_body_shots[i].count
		local xp = definition.glock.shield_body_shots[i].xp
		local challenges = {
			i - 1 > 0 and "glock_shield_body_shots" .. i - 1 or "glock_vs_the_law_5"
		}
		local depends_on = {
			challenges = challenges,
			weapons = {"glock"}
		}
		self.weapon[name] = {
			title_id = "ch_glock_shield_body_shot_" .. i .. "_hl",
			description_id = "ch_glock_shield_body_shot",
			counter_id = "glock_shield_body_shot",
			unlock_level = 0,
			count = count,
			xp = xp,
			depends_on = depends_on
		}
	end
end
function ChallengesTweakData:_ak47_challenges()
	local definition = {}
	definition.ak47 = {}
	definition.ak47.vs_the_law = {
		{count = 50, xp = tiny_xp},
		{count = 200, xp = small_xp},
		{count = 400, xp = mid_xp},
		{count = 600, xp = large_xp},
		{count = 800, xp = large_xp},
		{count = 1000, xp = large_xp}
	}
	definition.ak47.head_shots = {
		{count = 75, xp = small_xp},
		{count = 200, xp = mid_xp},
		{count = 350, xp = large_xp},
		{count = 500, xp = large_xp}
	}
	definition.ak47.taser_kill = {
		{count = 20, xp = huge_xp}
	}
	for i = 1, #definition.ak47.vs_the_law do
		local name = "ak47_vs_the_law_" .. i
		local count = definition.ak47.vs_the_law[i].count
		local xp = definition.ak47.vs_the_law[i].xp
		local challenges = {
			i - 1 > 0 and "ak47_vs_the_law_" .. i - 1 or nil
		}
		local depends_on = {
			challenges = challenges,
			weapons = {"ak47"}
		}
		self.weapon[name] = {
			title_id = "ch_ak47_vs_the_law_" .. i .. "_hl",
			description_id = "ch_ak47_vs_the_law",
			counter_id = "ak47_law_kill",
			unlock_level = 0,
			count = count,
			xp = xp,
			depends_on = depends_on
		}
	end
	for i = 1, #definition.ak47.head_shots do
		local name = "ak47_head_shots_" .. i
		local count = definition.ak47.head_shots[i].count
		local xp = definition.ak47.head_shots[i].xp
		local challenges = {
			i - 1 > 0 and "ak47_head_shots_" .. i - 1 or "ak47_vs_the_law_3"
		}
		local depends_on = {
			challenges = challenges,
			weapons = {"ak47"}
		}
		self.weapon[name] = {
			title_id = "ch_ak47_head_shots_" .. i .. "_hl",
			description_id = "ch_ak47_head_shots",
			counter_id = "ak47_law_head_shot",
			unlock_level = 0,
			count = count,
			xp = xp,
			depends_on = depends_on
		}
	end
	for i = 1, #definition.ak47.taser_kill do
		local name = "ak47_taser_kill_" .. i
		local count = definition.ak47.taser_kill[i].count
		local xp = definition.ak47.taser_kill[i].xp
		local challenges = {
			i - 1 > 0 and "ak47_taser_kill" .. i - 1 or "ak47_vs_the_law_5"
		}
		local depends_on = {
			challenges = challenges,
			weapons = {"ak47"}
		}
		self.weapon[name] = {
			title_id = "ch_ak47_taser_kill_" .. i .. "_hl",
			description_id = "ch_ak47_taser_kill",
			counter_id = "ak47_taser_kill",
			unlock_level = 0,
			count = count,
			xp = xp,
			depends_on = depends_on
		}
	end
end
function ChallengesTweakData:_m79_challenges()
	local definition = {}
	definition.m79 = {}
	definition.m79.vs_the_law = {
		{count = 50, xp = tiny_xp},
		{count = 200, xp = small_xp},
		{count = 400, xp = mid_xp},
		{count = 600, xp = large_xp},
		{count = 800, xp = large_xp},
		{count = 1000, xp = large_xp}
	}
	definition.m79.simultaneous_kills = {
		{count = 4, xp = small_xp},
		{count = 6, xp = mid_xp},
		{count = 8, xp = large_xp},
		{count = 10, xp = large_xp}
	}
	definition.m79.simultaneous_specials = {
		{count = 3, xp = huge_xp}
	}
	for i = 1, #definition.m79.vs_the_law do
		local name = "m79_vs_the_law_" .. i
		local count = definition.m79.vs_the_law[i].count
		local xp = definition.m79.vs_the_law[i].xp
		local challenges = {
			i - 1 > 0 and "m79_vs_the_law_" .. i - 1 or nil
		}
		local depends_on = {
			challenges = challenges,
			weapons = {"m79"}
		}
		self.weapon[name] = {
			title_id = "ch_m79_vs_the_law_" .. i .. "_hl",
			description_id = "ch_m79_vs_the_law",
			counter_id = "m79_law_kill",
			unlock_level = 0,
			count = count,
			xp = xp,
			depends_on = depends_on
		}
	end
	for i = 1, #definition.m79.simultaneous_kills do
		local name = "m79_simultaneous_kills_" .. i
		local count = definition.m79.simultaneous_kills[i].count
		local xp = definition.m79.simultaneous_kills[i].xp
		local challenges = {
			i - 1 > 0 and "m79_simultaneous_kills_" .. i - 1 or "m79_vs_the_law_3"
		}
		local depends_on = {
			challenges = challenges,
			weapons = {"m79"}
		}
		self.weapon[name] = {
			title_id = "ch_m79_simultaneous_kills_" .. i .. "_hl",
			description_id = "ch_m79_simultaneous_kills",
			counter_id = "m79_law_simultaneous_kills",
			unlock_level = 0,
			count = count,
			xp = xp,
			depends_on = depends_on
		}
	end
	for i = 1, #definition.m79.simultaneous_specials do
		local name = "m79_taser_kill_" .. i
		local count = definition.m79.simultaneous_specials[i].count
		local xp = definition.m79.simultaneous_specials[i].xp
		local challenges = {
			i - 1 > 0 and "m79_simultaneous_specials" .. i - 1 or "m79_vs_the_law_5"
		}
		local depends_on = {
			challenges = challenges,
			weapons = {"m79"}
		}
		self.weapon[name] = {
			title_id = "ch_m79_simultaneous_specials_" .. i .. "_hl",
			description_id = "ch_m79_simultaneous_specials",
			counter_id = "m79_simultaneous_specials",
			unlock_level = 0,
			count = count,
			xp = xp,
			depends_on = depends_on
		}
	end
end
function ChallengesTweakData:_sentry_gun_challenges()
	local definition = {}
	definition.sentry_gun = {}
	definition.sentry_gun.vs_the_law = {
		{count = 50, xp = tiny_xp},
		{count = 200, xp = small_xp},
		{count = 400, xp = mid_xp},
		{count = 600, xp = large_xp},
		{count = 800, xp = large_xp},
		{count = 1000, xp = large_xp}
	}
	definition.sentry_gun.row_kills = {
		{count = 5, xp = small_xp},
		{count = 10, xp = mid_xp},
		{count = 15, xp = large_xp},
		{count = 20, xp = large_xp}
	}
	for i = 1, #definition.sentry_gun.vs_the_law do
		local name = "sentry_gun_vs_the_law_" .. i
		local count = definition.sentry_gun.vs_the_law[i].count
		local xp = definition.sentry_gun.vs_the_law[i].xp
		local challenges = {
			i - 1 > 0 and "sentry_gun_vs_the_law_" .. i - 1 or nil
		}
		local depends_on = {challenges = challenges}
		self.weapon[name] = {
			title_id = "ch_sentry_gun_vs_the_law_" .. i .. "_hl",
			description_id = "ch_sentry_gun_vs_the_law",
			counter_id = "sentry_gun_law_kill",
			unlock_level = 0,
			count = count,
			xp = xp,
			depends_on = depends_on
		}
	end
	for i = 1, #definition.sentry_gun.row_kills do
		local name = "sentry_gun_row_kills_" .. i
		local count = definition.sentry_gun.row_kills[i].count
		local xp = definition.sentry_gun.row_kills[i].xp
		local challenges = {
			i - 1 > 0 and "sentry_gun_row_kills_" .. i - 1 or "sentry_gun_vs_the_law_3"
		}
		local depends_on = {challenges = challenges}
		self.weapon[name] = {
			title_id = "ch_sentry_gun_row_kills_" .. i .. "_hl",
			description_id = "ch_sentry_gun_row_kills",
			counter_id = "sentry_gun_law_row_kills",
			unlock_level = 0,
			count = count,
			xp = xp,
			depends_on = depends_on
		}
	end
	self.weapon.sentry_gun_resources = {
		title_id = "ch_sentry_gun_resources_hl",
		description_id = "ch_sentry_gun_resources",
		flag_id = "sentry_gun_resources",
		unlock_level = 0,
		xp = huge_xp,
		depends_on = {
			challenges = {
				"sentry_gun_vs_the_law_5"
			}
		}
	}
end
function ChallengesTweakData:_trip_mine_challenges()
	self.weapon.plant_tripmine = {
		title_id = "ch_plant_tripmine_hl",
		description_id = "ch_plant_tripmine",
		counter_id = "plant_tripmine",
		unlock_level = 0,
		count = 200,
		xp = mid_xp,
		depends_on = {
			equipment = {"trip_mine"}
		}
	}
	local definition = {}
	definition.trip_mine = {}
	definition.trip_mine.vs_the_law = {
		{count = 10, xp = tiny_xp},
		{count = 20, xp = small_xp},
		{count = 40, xp = mid_xp},
		{count = 80, xp = large_xp}
	}
	for i = 1, #definition.trip_mine.vs_the_law do
		local name = "trip_mine_vs_the_law_" .. i
		local count = definition.trip_mine.vs_the_law[i].count
		local xp = definition.trip_mine.vs_the_law[i].xp
		local challenges = {
			0 < i - 1 and "trip_mine_vs_the_law_" .. i - 1 or nil
		}
		local depends_on = {
			challenges = challenges,
			equipment = {"trip_mine"}
		}
		self.weapon[name] = {
			title_id = "ch_trip_mine_vs_the_law_" .. i .. "_hl",
			description_id = "ch_trip_mine_vs_the_law",
			counter_id = "trip_mine_law_kill",
			unlock_level = 0,
			count = count,
			xp = xp,
			depends_on = depends_on
		}
	end
	self.weapon.dual_tripmine = {
		title_id = "ch_dual_tripmine_hl",
		description_id = "ch_dual_tripmine",
		counter_id = "dual_tripmine",
		unlock_level = 0,
		count = 1,
		xp = mid_xp,
		depends_on = {
			challenges = {
				"trip_mine_vs_the_law_2"
			},
			equipment = {"trip_mine"}
		}
	}
	self.weapon.tris_tripmine = {
		title_id = "ch_tris_tripmine_hl",
		description_id = "ch_tris_tripmine",
		counter_id = "tris_tripmine",
		unlock_level = 0,
		count = 1,
		xp = large_xp,
		depends_on = {
			challenges = {
				"dual_tripmine"
			},
			equipment = {"trip_mine"}
		}
	}
	self.weapon.quad_tripmine = {
		title_id = "ch_quad_tripmine_hl",
		description_id = "ch_quad_tripmine",
		counter_id = "quad_tripmine",
		unlock_level = 0,
		count = 1,
		xp = huge_xp,
		depends_on = {
			challenges = {
				"tris_tripmine"
			},
			equipment = {"trip_mine"}
		}
	}
end
function ChallengesTweakData:_bleed_out_challenges()
	local definition = {}
	definition.bleed_out = {}
	definition.bleed_out.vs_the_law = {
		{count = 10, xp = small_xp},
		{count = 20, xp = small_xp},
		{count = 40, xp = mid_xp},
		{count = 80, xp = large_xp}
	}
	for i = 1, #definition.bleed_out.vs_the_law do
		local name = "bleed_out_vs_the_law_" .. i
		local count = definition.bleed_out.vs_the_law[i].count
		local xp = definition.bleed_out.vs_the_law[i].xp
		local challenges = {
			i - 1 > 0 and "bleed_out_vs_the_law_" .. i - 1 or nil
		}
		local depends_on = {challenges = challenges}
		self.weapon[name] = {
			title_id = "ch_bleed_out_kill_" .. i .. "_hl",
			description_id = "ch_bleed_out_kill",
			counter_id = "bleed_out_kill",
			unlock_level = 30,
			count = count,
			xp = xp,
			depends_on = depends_on
		}
	end
	self.weapon.bleed_out_multikill = {
		title_id = "ch_bleed_out_multikill_hl",
		description_id = "ch_bleed_out_multikill",
		counter_id = "bleed_out_multikill",
		unlock_level = 30,
		count = 10,
		xp = huge_xp,
		reset_criterias = {
			"exit_bleed_out"
		},
		depends_on = {
			challenges = {
				"bleed_out_vs_the_law_4"
			}
		}
	}
	self.weapon.grim_reaper = {
		title_id = "ch_grim_reaper_hl",
		description_id = "ch_grim_reaper",
		counter_id = "grim_reaper",
		unlock_level = 30,
		count = 1,
		xp = large_xp,
		depends_on = {
			challenges = {
				"bleed_out_multikill"
			}
		}
	}
end
function ChallengesTweakData:_melee_challenges()
	local definition = {}
	definition.melee = {}
	definition.melee.vs_the_law = {
		{
			count = 10,
			xp = tiny_xp,
			in_trial = true
		},
		{count = 30, xp = small_xp},
		{count = 60, xp = mid_xp},
		{count = 120, xp = large_xp}
	}
	for i = 1, #definition.melee.vs_the_law do
		local name = "melee_vs_the_law_" .. i
		local count = definition.melee.vs_the_law[i].count
		local xp = definition.melee.vs_the_law[i].xp
		local challenges = {
			i - 1 > 0 and "melee_vs_the_law_" .. i - 1 or nil
		}
		local depends_on = {challenges = challenges}
		self.weapon[name] = {
			title_id = "ch_melee_" .. i .. "_hl",
			description_id = "ch_melee",
			counter_id = "melee_law_kill",
			unlock_level = 0,
			count = count,
			xp = xp,
			depends_on = depends_on,
			in_trial = definition.melee.vs_the_law[i].in_trial
		}
	end
end
function ChallengesTweakData:_money_challenges()
	local definition = {}
	definition.money = {}
	definition.money.aquire = {
		{
			amount = 20000,
			xp = mid_xp,
			in_trial = true
		},
		{amount = 50000, xp = mid_xp},
		{amount = 100000, xp = large_xp},
		{amount = 200000, xp = large_xp},
		{amount = 300000, xp = large_xp},
		{amount = 400000, xp = huge_xp},
		{amount = 500000, xp = huge_xp},
		{amount = 600000, xp = gigantic_xp},
		{amount = 800000, xp = gigantic_xp},
		{
			amount = 1000000,
			xp = gigantic_xp,
			awards_achievment = "payday"
		}
	}
	for i = 1, #definition.money.aquire do
		local name = "aquire_money" .. i
		local amount = definition.money.aquire[i].amount
		local xp = definition.money.aquire[i].xp
		local awards_achievment = definition.money.aquire[i].awards_achievment
		local challenges = {
			i - 1 > 0 and "aquire_money" .. i - 1 or nil
		}
		local depends_on = {challenges = challenges}
		self.session[name] = {
			title_id = "ch_aquire_money_" .. i .. "_hl",
			description_id = "ch_aquire_money_" .. i,
			unlock_level = 0,
			amount = amount,
			xp = xp,
			awards_achievment = awards_achievment,
			depends_on = depends_on,
			id = "aquired_money",
			in_trial = definition.money.aquire[i].in_trial
		}
	end
end
