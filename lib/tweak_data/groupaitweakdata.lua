GroupAITweakData = GroupAITweakData or class()
function GroupAITweakData:_set_easy()
	local is_singleplayer = Global.game_settings.single_player
	self.difficulty_curve_points = {0.9}
	if SystemInfo:platform() == Idstring("PS3") or is_singleplayer then
		self.besiege.assault.force = {
			15,
			15,
			15
		}
	else
		self.besiege.assault.force = {
			15,
			15,
			15
		}
	end
	if SystemInfo:platform() == Idstring("PS3") or is_singleplayer then
		self.street.assault.force.aggressive = {
			10,
			13,
			15
		}
	else
		self.street.assault.force.aggressive = {
			10,
			15,
			20
		}
	end
end
function GroupAITweakData:_set_normal()
	self.difficulty_curve_points = {0.5}
end
function GroupAITweakData:_set_hard()
	local is_singleplayer = Global.game_settings.single_player
	self.difficulty_curve_points = {0.35}
	self.besiege.assault.sustain_duration_min = {
		30,
		70,
		140
	}
	self.besiege.assault.sustain_duration_max = {
		40,
		120,
		200
	}
	self.besiege.assault.delay = {
		80,
		50,
		40
	}
	self.besiege.assault.units = {
		cop = {
			1,
			0,
			0
		},
		swat = {
			0,
			1,
			0.2
		},
		swat_kevlar = {
			0,
			0.5,
			1
		},
		shield = {
			0,
			0.1,
			0.2
		},
		spooc = {
			0,
			0.1,
			0.2
		},
		taser = {
			0,
			0.05,
			0.1
		}
	}
	self.street.assault.build_duration = 35
	self.street.assault.sustain_duration_min = {
		30,
		50,
		70
	}
	self.street.assault.sustain_duration_max = {
		40,
		60,
		80
	}
	self.street.assault.delay = {
		40,
		35,
		30
	}
	self.street.assault.units = {
		swat = {
			1,
			0.5,
			0.5
		},
		swat_kevlar = {
			0,
			0.5,
			0.5
		},
		shield = {
			0,
			0.2,
			0.2
		},
		spooc = {
			0,
			0.1,
			0.1
		},
		taser = {
			0,
			0.05,
			0.1
		}
	}
	self.street.blockade.units = {
		defend = {
			swat = {
				1,
				1,
				0.5
			},
			swat_kevlar = {
				0.4,
				0.7,
				0.7
			},
			shield = {
				0.1,
				0.2,
				0.3
			}
		},
		frontal = {
			swat = {
				1,
				0.2,
				0.3
			},
			swat_kevlar = {
				0.2,
				0.5,
				0.7
			},
			shield = {
				0,
				0.1,
				0.3
			},
			spooc = {
				0,
				0.1,
				0.2
			}
		},
		flank = {
			spooc = {
				1,
				1,
				1
			},
			taser = {
				1,
				1,
				1
			},
			fbi_special = {
				0.001,
				0.001,
				0.001
			}
		}
	}
end
function GroupAITweakData:_set_overkill()
	local is_singleplayer = Global.game_settings.single_player
	self.difficulty_curve_points = {0.1}
	self.max_nr_simultaneous_boss_types = 4
	self.besiege.assault.sustain_duration_min = {
		150,
		180,
		250
	}
	self.besiege.assault.sustain_duration_max = {
		200,
		220,
		360
	}
	self.besiege.assault.delay = {
		20,
		20,
		20
	}
	self.besiege.assault.units = {
		swat = {
			1,
			0,
			0
		},
		swat_kevlar = {
			0.4,
			1,
			0.2
		},
		shield = {
			0.2,
			0.5,
			0.5
		},
		tank = {
			0,
			0,
			0.1
		},
		spooc = {
			0.2,
			0.5,
			1
		},
		taser = {
			0.05,
			0.2,
			0.3
		}
	}
	self.street.assault.build_duration = 35
	self.street.assault.sustain_duration_min = {
		50,
		70,
		90
	}
	self.street.assault.sustain_duration_max = {
		60,
		90,
		120
	}
	self.street.assault.delay = {
		40,
		35,
		30
	}
	self.street.assault.units = {
		swat = {
			1,
			0.5,
			0
		},
		swat_kevlar = {
			0.4,
			1,
			0.2
		},
		shield = {
			0.2,
			0.5,
			0.5
		},
		tank = {
			0,
			0,
			0.1
		},
		spooc = {
			0.2,
			0.5,
			1
		},
		taser = {
			0.05,
			0.2,
			0.3
		}
	}
	self.street.blockade.units = {
		defend = {
			swat = {
				1,
				0.5,
				0.5
			},
			swat_kevlar = {
				0.4,
				1,
				1
			},
			shield = {
				0.1,
				0.2,
				0.3
			}
		},
		frontal = {
			swat = {
				1,
				0.5,
				0.5
			},
			swat_kevlar = {
				0.2,
				0.5,
				1
			},
			shield = {
				0,
				0.1,
				0.5
			},
			spooc = {
				0.1,
				0.3,
				0.4
			}
		},
		flank = {
			spooc = {
				1,
				1,
				1
			},
			taser = {
				1,
				1,
				1
			},
			fbi_special = {
				0.001,
				0.001,
				0.001
			}
		}
	}
end
function GroupAITweakData:_set_overkill_145()
	local is_singleplayer = Global.game_settings.single_player
	self.difficulty_curve_points = {0.1}
	self.max_nr_simultaneous_boss_types = 4
	self.besiege.assault.build_duration = 30
	self.besiege.assault.sustain_duration_min = {
		200,
		360,
		400
	}
	self.besiege.assault.sustain_duration_max = {
		200,
		360,
		400
	}
	self.besiege.assault.delay = {
		15,
		15,
		15
	}
	self.besiege.assault.units = {
		swat = {
			0,
			0,
			0
		},
		swat_kevlar = {
			1,
			1,
			0.1
		},
		shield = {
			0.5,
			0.7,
			0.7
		},
		tank = {
			0,
			0.1,
			0.2
		},
		spooc = {
			0.2,
			0.7,
			1
		},
		taser = {
			0.05,
			0.35,
			0.45
		}
	}
	if SystemInfo:platform() == Idstring("PS3") then
		self.besiege.assault.force = {
			15,
			15,
			15
		}
	elseif is_singleplayer then
		self.besiege.assault.force = {
			25,
			30,
			30
		}
	else
		self.besiege.assault.force = {
			25,
			35,
			35
		}
	end
	self.besiege.recon.interval = {
		50000,
		50000,
		50000
	}
	self.besiege.recon.group_size = {
		0,
		0,
		0
	}
	self.besiege.recon.interval_variation = 0
	self.street.assault.build_duration = 35
	self.street.assault.sustain_duration_min = {
		60,
		120,
		160
	}
	self.street.assault.sustain_duration_max = {
		60,
		120,
		160
	}
	self.street.assault.delay = {
		30,
		30,
		30
	}
	self.street.assault.units = {
		swat = {
			0,
			0,
			0
		},
		swat_kevlar = {
			0,
			1,
			0.1
		},
		shield = {
			0.2,
			0.5,
			0.7
		},
		tank = {
			0,
			0.1,
			0.2
		},
		spooc = {
			0.2,
			0.7,
			1
		},
		taser = {
			0.05,
			0.35,
			0.45
		}
	}
	self.street.blockade.units = {
		defend = {
			swat = {
				1,
				0.5,
				0.5
			},
			swat_kevlar = {
				0.4,
				1,
				1
			},
			shield = {
				0.1,
				0.2,
				0.3
			}
		},
		frontal = {
			swat = {
				1,
				0.5,
				0.5
			},
			swat_kevlar = {
				0.2,
				0.5,
				1
			},
			shield = {
				0,
				0.1,
				0.5
			},
			spooc = {
				0.1,
				0.3,
				0.4
			}
		},
		flank = {
			spooc = {
				1,
				1,
				1
			},
			taser = {
				1,
				1,
				1
			},
			fbi_special = {
				0.001,
				0.001,
				0.001
			}
		}
	}
end
function GroupAITweakData:init()
	local is_singleplayer = Global.game_settings and Global.game_settings.single_player
	self:_create_table_structure()
	self:_init_chatter_data()
	self.max_nr_simultaneous_boss_types = 2
	self.difficulty_curve_points = {0.5}
	self.optimal_trade_distance = {0, 0}
	self.bain_assault_praise_limits = {1, 3}
	self.besiege.regroup.duration = {
		120,
		120,
		120
	}
	self.besiege.assault.anticipation_duration = {
		{45, 0.6},
		{35, 0.3},
		{25, 0.1}
	}
	self.besiege.assault.build_duration = 60
	self.besiege.assault.sustain_duration_min = {
		30,
		40,
		120
	}
	self.besiege.assault.sustain_duration_max = {
		40,
		120,
		160
	}
	self.besiege.assault.delay = {
		120,
		80,
		40
	}
	if SystemInfo:platform() == Idstring("PS3") then
		self.besiege.assault.force = {
			15,
			15,
			15
		}
	elseif is_singleplayer then
		self.besiege.assault.force = {
			20,
			20,
			20
		}
	else
		self.besiege.assault.force = {
			25,
			25,
			25
		}
	end
	self.besiege.assault.units = {
		cop = {
			1,
			0,
			0
		},
		swat = {
			0,
			1,
			0.5
		},
		swat_kevlar = {
			0,
			0.5,
			1
		},
		shield = {
			0,
			0.1,
			0.2
		},
		fbi_special = {
			0,
			0.2,
			0.1
		}
	}
	self.besiege.reenforce.interval = {
		2,
		2,
		2
	}
	self.besiege.reenforce.group_size = {
		5,
		5,
		5
	}
	self.besiege.reenforce.units = {
		spooc = {
			1,
			1,
			1
		}
	}
	self.besiege.recon.interval = {
		1,
		1,
		1
	}
	if SystemInfo:platform() == Idstring("PS3") or is_singleplayer then
		self.besiege.recon.group_size = {
			2,
			2,
			2
		}
		self.besiege.recon.interval_variation = 7
	else
		self.besiege.recon.group_size = {
			4,
			4,
			4
		}
		self.besiege.recon.interval_variation = 7
	end
	self.besiege.recon.units = {
		cop = {
			1,
			0,
			0
		},
		fbi = {
			0,
			0.3,
			0.2
		},
		fbi_special = {
			0,
			0.1,
			0.3
		}
	}
	self.besiege.rescue.interval = {
		10,
		10,
		10
	}
	self.besiege.rescue.interval_variation = 2
	self.besiege.rescue.group_size = {
		2,
		2,
		2
	}
	self.besiege.rescue.units = {
		cop = {
			1,
			0,
			0
		},
		swat = {
			0,
			0.5,
			0.1
		},
		fbi = {
			0,
			0.5,
			0
		},
		fbi_special = {
			0,
			0.1,
			0.1
		}
	}
	self.street.regroup.duration = {
		120,
		120,
		120
	}
	self.street.assault.anticipation_duration = {
		{45, 0.6},
		{35, 0.3},
		{25, 0.1}
	}
	self.street.assault.build_duration = 25
	self.street.assault.sustain_duration_min = {
		30,
		50,
		70
	}
	self.street.assault.sustain_duration_max = {
		40,
		60,
		80
	}
	self.street.assault.delay = {
		120,
		80,
		40
	}
	if SystemInfo:platform() == Idstring("PS3") or is_singleplayer then
		self.street.assault.force.aggressive = {
			10,
			13,
			15
		}
	else
		self.street.assault.force.aggressive = {
			20,
			23,
			25
		}
	end
	self.street.assault.force.defensive = {
		5,
		2,
		0
	}
	self.street.assault.units = {
		cop = {
			1,
			0,
			0
		},
		swat = {
			0,
			1,
			0.5
		},
		swat_kevlar = {
			0,
			0.3,
			1
		},
		shield = {
			0,
			0.1,
			0.2
		}
	}
	self.street.blockade.min_distance = 1500
	self.street.blockade.anticipation_duration = {
		{45, 0.6},
		{35, 0.3},
		{25, 0.1}
	}
	self.street.blockade.build_duration = 5
	self.street.blockade.sustain_duration_min = {
		30,
		50,
		70
	}
	self.street.blockade.sustain_duration_max = {
		40,
		60,
		80
	}
	self.street.blockade.delay = {
		120,
		100,
		80
	}
	if SystemInfo:platform() == Idstring("PS3") or is_singleplayer then
		self.street.blockade.force.defend = {
			5,
			5,
			5
		}
		self.street.blockade.force.frontal = {
			10,
			10,
			10
		}
	else
		self.street.blockade.force.defend = {
			9,
			9,
			9
		}
		self.street.blockade.force.frontal = {
			15,
			15,
			15
		}
	end
	self.street.blockade.units = {
		defend = {
			cop = {
				1,
				0,
				0
			},
			swat = {
				0,
				1,
				0.3
			}
		},
		frontal = {
			cop = {
				1,
				0,
				0
			},
			swat = {
				0,
				1,
				0.3
			},
			swat_kevlar = {
				0,
				0.5,
				1
			},
			shield = {
				0,
				0.1,
				0.5
			}
		},
		flank = {
			spooc = {
				1,
				1,
				1
			},
			taser = {
				1,
				1,
				1
			},
			fbi_special = {
				0.001,
				0.001,
				0.001
			}
		}
	}
	self.street.capture.force = 0
	self.street.capture.units = {
		cop = {
			1,
			0,
			0
		},
		swat = {
			0,
			1,
			0.5
		},
		swat_kevlar = {
			0,
			0.5,
			1
		},
		fbi_special = {
			0,
			0.2,
			0.1
		}
	}
	local access_type_walk_only = {"walk"}
	local access_type_all = {"walk", "acrobatic"}
	self.unit_categories = {
		security = {
			units = {
				Idstring("units/characters/enemies/security/security_guard_01"),
				Idstring("units/characters/enemies/security/security_guard_02")
			},
			access = access_type_walk_only
		},
		cop = {
			units = {
				Idstring("units/characters/enemies/cop/cop"),
				Idstring("units/characters/enemies/cop2/cop2"),
				Idstring("units/characters/enemies/cop3/cop3")
			},
			access = access_type_walk_only
		},
		fbi = {
			units = {
				Idstring("units/characters/enemies/fbi1/fbi1"),
				Idstring("units/characters/enemies/fbi2/fbi2"),
				Idstring("units/characters/enemies/fbi3/fbi3")
			},
			access = access_type_walk_only
		},
		fbi_special = {
			units = {
				Idstring("units/characters/enemies/fbi2/fbi2")
			},
			access = access_type_all
		},
		swat = {
			units = {
				Idstring("units/characters/enemies/swat/swat"),
				Idstring("units/characters/enemies/swat2/swat2"),
				Idstring("units/characters/enemies/swat3/swat3")
			},
			access = access_type_all
		},
		swat_kevlar = {
			units = {
				Idstring("units/characters/enemies/swat_kevlar1/swat_kevlar1"),
				Idstring("units/characters/enemies/swat_kevlar2/swat_kevlar2")
			},
			access = access_type_all
		},
		tank = {
			units = {
				Idstring("units/characters/enemies/tank/tank")
			},
			access = access_type_walk_only,
			max_amount = 1,
			special_type = "tank"
		},
		shield = {
			units = {
				Idstring("units/characters/enemies/shield/shield")
			},
			access = access_type_walk_only,
			max_amount = 2,
			special_type = "shield"
		},
		spooc = {
			units = {
				Idstring("units/characters/enemies/spooc/spooc")
			},
			access = access_type_all,
			max_amount = 2,
			special_type = "spooc"
		},
		taser = {
			units = {
				Idstring("units/characters/enemies/taser/taser")
			},
			access = access_type_all,
			max_amount = 2,
			special_type = "taser"
		},
		sniper = {
			units = {
				Idstring("units/characters/enemies/sniper/sniper")
			},
			access = access_type_all
		}
	}
end
function GroupAITweakData:_init_chatter_data()
	self.enemy_chatter.aggressive = {
		radius = 600,
		max_nr = 3,
		duration = {1, 3},
		interval = {0.5, 0.8},
		group_min = 3,
		queue = "_g90"
	}
	self.enemy_chatter.retreat = {
		radius = 700,
		max_nr = 2,
		duration = {2, 4},
		interval = {0.75, 1.5},
		group_min = 3,
		queue = "_m01x_plu"
	}
	self.enemy_chatter.follow_me = {
		radius = 700,
		max_nr = 1,
		duration = {5, 10},
		interval = {0.75, 1.5},
		group_min = 2,
		queue = "_mov"
	}
	self.enemy_chatter.clear = {
		radius = 700,
		max_nr = 1,
		duration = {60, 60},
		interval = {0.75, 1.5},
		group_min = 3,
		queue = "_clr"
	}
	self.enemy_chatter.go_go = {
		radius = 700,
		max_nr = 1,
		duration = {60, 60},
		interval = {0.75, 1.2},
		group_min = 0,
		queue = "_mov"
	}
	self.enemy_chatter.ready = {
		radius = 700,
		max_nr = 1,
		duration = {60, 60},
		interval = {0.75, 1.2},
		group_min = 3,
		queue = "_rdy"
	}
	self.enemy_chatter.smoke = {
		radius = 0,
		max_nr = 1,
		duration = {0, 0},
		interval = {0, 0},
		group_min = 2,
		queue = "_gas"
	}
	self.enemy_chatter.incomming_tank = {
		radius = 1000,
		max_nr = 1,
		duration = {60, 60},
		interval = {0.5, 1},
		group_min = 0,
		queue = "_bdz"
	}
	self.enemy_chatter.incomming_spooc = {
		radius = 1000,
		max_nr = 1,
		duration = {60, 60},
		interval = {0.5, 1},
		group_min = 0,
		queue = "_clk"
	}
	self.enemy_chatter.incomming_shield = {
		radius = 1000,
		max_nr = 1,
		duration = {60, 60},
		interval = {0.5, 1},
		group_min = 0,
		queue = "_shd"
	}
	self.enemy_chatter.incomming_taser = {
		radius = 1000,
		max_nr = 1,
		duration = {60, 60},
		interval = {0.5, 1},
		group_min = 0,
		queue = "_tsr"
	}
end
function GroupAITweakData:_create_table_structure()
	self.enemy_chatter = {}
	self.besiege = {
		regroup = {},
		assault = {
			force = {}
		},
		reenforce = {},
		recon = {},
		rescue = {}
	}
	self.street = {
		blockade = {
			force = {}
		},
		assault = {
			force = {}
		},
		regroup = {},
		capture = {
			force = {}
		}
	}
end
