LevelsTweakData = LevelsTweakData or class()
function LevelsTweakData:init()
	self.sony_tutorial1 = {}
	self.sony_tutorial1.name_id = "debug_sony_level1"
	self.sony_tutorial1.description_id = "debug_sony_level1_description"
	self.sony_tutorial1.briefing_id = "debug_sony_level1_description"
	self.sony_tutorial1.ticker_id = "debug_sony_level1_ticker"
	self.sony_tutorial1.world_name = "sonybootcamp"
	self.sony_tutorial1.music = "bank"
	self.sony_tutorial1.package = "packages/level_debug"
	self.sony_tutorial2 = {}
	self.sony_tutorial2.name_id = "debug_sony_level2"
	self.sony_tutorial2.description_id = "debug_sony_level2_description"
	self.sony_tutorial2.briefing_id = "debug_sony_level2_description"
	self.sony_tutorial2.ticker_id = "debug_sony_level2_ticker"
	self.sony_tutorial2.world_name = "sony_bootcamp_arena"
	self.sony_tutorial2.music = "bank"
	self.sony_tutorial2.package = "packages/level_debug"
	self.wfv = {}
	self.wfv.name_id = "debug_alley_wfv"
	self.wfv.world_name = "alleys"
	self.wfv.briefing_id = "debug_alley_wfv_briefing"
	self.wfv.ticker_id = "debug_alley_wfv_ticker"
	self.wfv.loading_image = "guis/textures/level_wfv"
	self.wfv.movie = "movies/level_wfv"
	self.wfv.equipment = {"drill"}
	self.wfv.package = "packages/level_wfv"
	self.bank = {}
	self.bank.name_id = "debug_bank"
	self.bank.description_id = "debug_bank_description"
	self.bank.briefing_id = "debug_bank_briefing"
	self.bank.ticker_id = "debug_bank_ticker"
	self.bank.loading_image = "guis/textures/level_bank"
	self.bank.movie = "movies/level_bank"
	self.bank.world_name = SystemInfo:platform() == Idstring("PS3") and "bank_ps3" or "bank"
	self.bank.intro_event = "Play_1wb_ban_01x_any"
	self.bank.intro_cues = {
		"intro_bank01",
		"intro_bank02",
		"intro_bank03",
		"intro_bank04"
	}
	self.bank.intro_text_id = "intro_bank"
	self.bank.music = "bank"
	self.bank.package = "packages/level_bank"
	self.bank.megaphone_pos = Vector3(-6202, 32, 88)
	self.bank.cube = "cube_apply_bank"
	self.bank_trial = {}
	self.bank_trial.name_id = "debug_bank"
	self.bank_trial.description_id = "debug_bank_description"
	self.bank_trial.briefing_id = "debug_bank_briefing"
	self.bank_trial.ticker_id = "debug_bank_ticker"
	self.bank_trial.loading_image = "guis/textures/level_bank"
	self.bank_trial.movie = "movies/level_bank"
	self.bank_trial.world_name = "bank_trial"
	self.bank_trial.intro_event = "Play_1wb_ban_01x_any"
	self.bank_trial.intro_cues = {
		"intro_bank01",
		"intro_bank02",
		"intro_bank03",
		"intro_bank04"
	}
	self.bank_trial.intro_text_id = "intro_bank"
	self.bank_trial.music = "bank"
	self.bank_trial.package = "packages/level_bank"
	self.bank_trial.megaphone_pos = Vector3(-6202, 32, 88)
	self.bank_trial.cube = "cube_apply_bank"
	self.heat_street = {}
	self.heat_street.name_id = "debug_street"
	self.heat_street.description_id = "debug_street_description"
	self.heat_street.ticker_id = "debug_heat_street_ticker"
	self.heat_street.world_name = SystemInfo:platform() == Idstring("PS3") and "street_ps3" or "street"
	self.heat_street.intro_event = "str_blackscreen"
	self.heat_street.intro_cues = {
		"intro_street01",
		"intro_street02",
		"intro_street03",
		"intro_street04",
		"intro_street05"
	}
	self.heat_street.intro_text_id = "intro_street"
	self.heat_street.music = "str"
	self.heat_street.briefing_id = "debug_street_briefing"
	self.heat_street.loading_image = "guis/textures/level_street"
	self.heat_street.movie = "movies/level_street"
	self.heat_street.package = "packages/level_street"
	self.heat_street.cube = "cube_apply_street"
	self.bridge = {}
	self.bridge.name_id = "debug_bridge"
	self.bridge.world_name = SystemInfo:platform() == Idstring("PS3") and "bridge_ps3" or "bridge"
	self.bridge.intro_event = "bri_blackscreen"
	self.bridge.intro_cues = {
		"intro_bridge01",
		"intro_bridge02"
	}
	self.bridge.intro_text_id = "intro_bridge"
	self.bridge.briefing_id = "debug_bridge_briefing"
	self.bridge.ticker_id = "debug_bridge_ticker"
	self.bridge.loading_image = "guis/textures/level_bridge"
	self.bridge.movie = "movies/level_bridge"
	self.bridge.package = "packages/level_bridge"
	self.bridge.equipment = {"saw"}
	self.bridge.music = "bri"
	self.bridge.flashlights_on = true
	self.bridge.unit_suit = "raincoat"
	self.bridge.environment_effects = {
		"rain",
		"raindrop_screen",
		"lightning"
	}
	self.bridge.cube = "cube_apply_bridge"
	self.apartment = {}
	self.apartment.name_id = "debug_apartment"
	self.apartment.world_name = SystemInfo:platform() == Idstring("PS3") and "apartment_ps3" or "apartment"
	self.apartment.briefing_id = "debug_apartment_briefing"
	self.apartment.ticker_id = "debug_apartment_ticker"
	self.apartment.loading_image = "guis/textures/level_apartment"
	self.apartment.movie = "movies/level_apartment"
	self.apartment.equipment = {"saw"}
	self.apartment.intro_event = "Play_apa_rbx_00x_any"
	self.apartment.intro_cues = {
		"intro_apartment01",
		"intro_apartment02",
		"intro_apartment03",
		"intro_apartment04"
	}
	self.apartment.intro_text_id = "intro_apartment"
	self.apartment.music = "apa"
	self.apartment.package = "packages/level_apartment"
	self.apartment.megaphone_pos = Vector3(-444, -1502, 206)
	self.apartment.cube = "cube_apply_apartment"
	self.diamond_heist = {}
	self.diamond_heist.name_id = "debug_diamond_heist"
	self.diamond_heist.world_name = SystemInfo:platform() == Idstring("PS3") and "diamondheist_ps3" or "diamondheist"
	self.diamond_heist.intro_event = "dim_blackscreen"
	self.diamond_heist.intro_cues = {
		"intro_diamondheist01",
		"intro_diamondheist02",
		"intro_diamondheist03"
	}
	self.diamond_heist.intro_text_id = "intro_diamondheist"
	self.diamond_heist.music = "dia"
	self.diamond_heist.briefing_id = "debug_diamond_heist_briefing"
	self.diamond_heist.ticker_id = "debug_diamond_heist_ticker"
	self.diamond_heist.loading_image = "guis/textures/level_diamond_heist"
	self.diamond_heist.movie = "movies/level_diamond_heist"
	self.diamond_heist.package = "packages/level_diamond_heist"
	self.diamond_heist.unit_suit = "cat_suit"
	self.diamond_heist.cube = "cube_apply_diamond"
	self.slaughter_house = {}
	self.slaughter_house.name_id = "debug_slaughter_house"
	self.slaughter_house.world_name = SystemInfo:platform() == Idstring("PS3") and "slaughterhouse_ps3" or "slaughterhouse"
	self.slaughter_house.intro_event = "slh_blackscreen"
	self.slaughter_house.intro_cues = {
		"intro_slaughterhouse01",
		"intro_slaughterhouse03",
		"intro_slaughterhouse05"
	}
	self.slaughter_house.intro_text_id = "intro_slaughterhouse"
	self.slaughter_house.briefing_id = "debug_slaughter_house_briefing"
	self.slaughter_house.ticker_id = "debug_slaughter_house_ticker"
	self.slaughter_house.loading_image = "guis/textures/level_early_birds"
	self.slaughter_house.movie = "movies/level_slaughter_house"
	self.slaughter_house.package = "packages/level_slaughterhouse"
	self.slaughter_house.equipment = {"drill"}
	self.slaughter_house.music = "sla"
	self.slaughter_house.unit_suit = "cat_suit"
	self.slaughter_house.cube = "cube_apply_slaughter"
	self.departing = {}
	self.departing.name_id = "debug_departing"
	self.departing.world_name = "diamond2"
	self.departing.briefing_id = "debug_departing_briefing"
	self.departing.ticker_id = "debug_departing_ticker"
	self.departing.loading_image = "guis/textures/level_departing"
	self.departing.movie = "movies/level_departing"
	self.departing.package = "packages/level_departing"
	self.alaska = {}
	self.alaska.name_id = "debug_alaska"
	self.alaska.world_name = "warehouse"
	self.alaska.briefing_id = "debug_alaska_briefing"
	self.alaska.ticker_id = "debug_alaska_ticker"
	self.alaska.loading_image = "guis/textures/level_alaska"
	self.alaska.movie = "movies/level_alaska"
	self.alaska.package = "packages/level_alaska"
	self.yacht = {}
	self.yacht.name_id = "debug_yacht"
	self.yacht.world_name = "yacht_mod"
	self.yacht.briefing_id = "debug_yacht_briefing"
	self.yacht.ticker_id = "debug_yacht_ticker"
	self.yacht.loading_image = "guis/textures/level_yacht"
	self.yacht.movie = "movies/level_yacht"
	self.yacht.package = "packages/level_yacht"
	self.suburbia = {}
	self.suburbia.name_id = "debug_suburbia"
	self.suburbia.world_name = "suburbia"
	self.suburbia.intro_event = "cft_blackscreen"
	self.suburbia.intro_cues = {
		"intro_suburbia01",
		"intro_suburbia02",
		"intro_suburbia03",
		"intro_suburbia04",
		"intro_suburbia05",
		"intro_suburbia06"
	}
	self.suburbia.intro_text_id = "intro_suburbia"
	self.suburbia.briefing_id = "debug_suburbia_briefing"
	self.suburbia.movie = "movies/level_suburbia"
	self.suburbia.package = "packages/level_suburbia"
	self.suburbia.equipment = {"drill"}
	self.suburbia.music = "cft"
	self.suburbia.unit_suit = "suburbia"
	self.suburbia.cube = "cube_apply_suburbia"
	self.suburbia.dlc = "dlc2"
	self.secret_stash = {}
	self.secret_stash.name_id = "debug_secret_stash"
	self.secret_stash.world_name = "secret_stash"
	self.secret_stash.intro_event = "und_blackscreen"
	self.secret_stash.intro_cues = {
		"intro_secret_stash01",
		"intro_secret_stash02",
		"intro_secret_stash03",
		"intro_secret_stash04",
		"intro_secret_stash05",
		"intro_secret_stash06",
		"intro_secret_stash07"
	}
	self.secret_stash.intro_text_id = "intro_secret_stash"
	self.secret_stash.briefing_id = "debug_secret_stash_briefing"
	self.secret_stash.movie = "movies/level_secret_stash"
	self.secret_stash.package = "packages/level_secret_stash"
	self.secret_stash.equipment = {"saw"}
	self.secret_stash.music = "und"
	self.secret_stash.cube = "cube_apply_secret_stash"
	self.secret_stash.dlc = "dlc3"
	self.secret_stash.unit_suit = "cat_suit"
	self.hospital = {}
	self.hospital.name_id = "debug_hospital"
	self.hospital.world_name = "l4d"
	self.hospital.intro_event = {
		"hos_blackscreen",
		"hos_blackscreen_bill_01",
		"hos_blackscreen_bill_02",
		"hos_blackscreen_bill_03",
		"hos_blackscreen_bill_04",
		"hos_blackscreen_bill_05",
		"hos_blackscreen_bill_06",
		"hos_blackscreen_bill_07",
		"hos_blackscreen_bill_08",
		"hos_blackscreen_bill_09",
		"hos_blackscreen_bill_10",
		"hos_blackscreen_bill_11",
		"hos_blackscreen_bill_12",
		"hos_blackscreen_bill_13",
		"hos_blackscreen_bill_14"
	}
	self.hospital.intro_cues = {
		{
			"intro_hospital00",
			"intro_hospital01",
			"intro_hospital02",
			"intro_hospital03",
			"intro_hospital04",
			"intro_hospital05",
			"intro_hospital06",
			"intro_hospital07",
			"intro_hospital08",
			"intro_hospital09"
		},
		{
			"intro_hospital10",
			"intro_hospital11",
			"intro_hospital12",
			"intro_hospital13",
			"intro_hospital14",
			"intro_hospital15",
			"intro_hospital16",
			"intro_hospital17",
			"intro_hospital18",
			"intro_hospital19"
		},
		{
			"intro_hospital20",
			"intro_hospital21",
			"intro_hospital22",
			"intro_hospital23",
			"intro_hospital24",
			"intro_hospital25",
			"intro_hospital26",
			"intro_hospital27",
			"intro_hospital28",
			"intro_hospital29"
		},
		{
			"intro_hospital30",
			"intro_hospital31",
			"intro_hospital32",
			"intro_hospital33",
			"intro_hospital34",
			"intro_hospital35",
			"intro_hospital36",
			"intro_hospital37",
			"intro_hospital38",
			"intro_hospital39"
		},
		{
			"intro_hospital40",
			"intro_hospital41",
			"intro_hospital42",
			"intro_hospital43",
			"intro_hospital44",
			"intro_hospital45",
			"intro_hospital46",
			"intro_hospital47",
			"intro_hospital48",
			"intro_hospital49"
		},
		{
			"intro_hospital50",
			"intro_hospital51",
			"intro_hospital52",
			"intro_hospital53",
			"intro_hospital54",
			"intro_hospital55",
			"intro_hospital56",
			"intro_hospital57",
			"intro_hospital58",
			"intro_hospital59"
		},
		{
			"intro_hospital60",
			"intro_hospital61",
			"intro_hospital62",
			"intro_hospital63",
			"intro_hospital64",
			"intro_hospital65",
			"intro_hospital66",
			"intro_hospital67",
			"intro_hospital68",
			"intro_hospital69"
		},
		{
			"intro_hospital70",
			"intro_hospital71",
			"intro_hospital72",
			"intro_hospital73",
			"intro_hospital74",
			"intro_hospital75",
			"intro_hospital76",
			"intro_hospital77",
			"intro_hospital78",
			"intro_hospital79"
		},
		{
			"intro_hospital80",
			"intro_hospital81",
			"intro_hospital82",
			"intro_hospital83",
			"intro_hospital84",
			"intro_hospital85",
			"intro_hospital86",
			"intro_hospital87",
			"intro_hospital88",
			"intro_hospital89"
		},
		{
			"intro_hospital90",
			"intro_hospital91",
			"intro_hospital92",
			"intro_hospital93",
			"intro_hospital94",
			"intro_hospital95",
			"intro_hospital96",
			"intro_hospital97",
			"intro_hospital98",
			"intro_hospital99"
		},
		{
			"intro_hospital100",
			"intro_hospital101",
			"intro_hospital102",
			"intro_hospital103",
			"intro_hospital104",
			"intro_hospital105",
			"intro_hospital106",
			"intro_hospital107",
			"intro_hospital108",
			"intro_hospital109"
		},
		{
			"intro_hospital110",
			"intro_hospital111",
			"intro_hospital112",
			"intro_hospital113",
			"intro_hospital114",
			"intro_hospital115",
			"intro_hospital116",
			"intro_hospital117",
			"intro_hospital118",
			"intro_hospital119"
		},
		{
			"intro_hospital120",
			"intro_hospital121",
			"intro_hospital122",
			"intro_hospital123",
			"intro_hospital124",
			"intro_hospital125",
			"intro_hospital126",
			"intro_hospital127",
			"intro_hospital128",
			"intro_hospital129"
		},
		{
			"intro_hospital130",
			"intro_hospital131",
			"intro_hospital132",
			"intro_hospital133",
			"intro_hospital134",
			"intro_hospital135",
			"intro_hospital136",
			"intro_hospital137",
			"intro_hospital138",
			"intro_hospital139"
		},
		{
			"intro_hospital140",
			"intro_hospital141",
			"intro_hospital142",
			"intro_hospital143",
			"intro_hospital144",
			"intro_hospital145",
			"intro_hospital146",
			"intro_hospital147",
			"intro_hospital148",
			"intro_hospital149"
		}
	}
	self.hospital.intro_text_id = "intro_hospital"
	self.hospital.briefing_id = "debug_hospital_briefing"
	self.hospital.movie = "movies/level_hospital"
	self.hospital.package = "packages/level_hospital"
	self.hospital.music = "hos"
	self.hospital.unit_suit = "scrubs"
	self.hospital.cube = "cube_apply_slaughter"
	self.hospital.dlc = "dlc4"
	self.gold_heist = {}
	self.gold_heist.name_id = "debug_gold_heist"
	self.gold_heist.world_name = "goldheist"
	self.gold_heist.briefing_id = "debug_gold_heist_briefing"
	self.gold_heist.movie = "movies/level_gold_heist"
	self.gold_heist.package = "packages/level_gold_heist"
	self.gold_heist.equipment = {"drill"}
	self.gold_heist.music = "sla"
	self.gold_heist.flashlights_on = true
	self.gold_heist.unit_suit = "raincoat"
	self.gold_heist.environment_effects = {
		"rain",
		"raindrop_screen",
		"lightning"
	}
	self.gold_heist.cube = "cube_apply_slaughter"
	self.casino_boat = {}
	self.casino_boat.name_id = "debug_casino_boat"
	self.casino_boat.world_name = "tests/casino_boat"
	self.casino_boat.briefing_id = "debug_casino_boat_briefing"
	self.casino_boat.movie = "movies/level_casino_boat"
	self.casino_boat.package = "packages/level_casino_boat"
	self.casino_boat.equipment = {"drill"}
	self.casino_boat.music = "sla"
	self.casino_boat.cube = "cube_apply_slaughter"
	self._level_index = {
		"wfv",
		"bank",
		"heat_street",
		"bridge",
		"apartment",
		"slaughter_house",
		"departing",
		"alaska",
		"diamond_heist",
		"bank_trial",
		"yacht",
		"suburbia",
		"secret_stash",
		"gold_heist",
		"casino_boat",
		"hospital",
		"sony_tutorial1",
		"sony_tutorial2"
	}
end
function LevelsTweakData:get_level_index()
	return self._level_index
end
function LevelsTweakData:get_world_name_from_index(index)
	if not self._level_index[index] then
		return
	end
	return self[self._level_index[index]].world_name
end
function LevelsTweakData:get_level_name_from_index(index)
	return self._level_index[index]
end
function LevelsTweakData:get_index_from_world_name(world_name)
	for index, entry_name in ipairs(self._level_index) do
		if world_name == self[entry_name].world_name then
			return index
		end
	end
end
function LevelsTweakData:get_index_from_level_id(level_id)
	for index, entry_name in ipairs(self._level_index) do
		if entry_name == level_id then
			return index
		end
	end
end
function LevelsTweakData:requires_dlc(level_id)
	return self[level_id].dlc
end
function LevelsTweakData:requires_dlc_by_index(index)
	return self[self._level_index[index]].dlc
end
function LevelsTweakData:get_level_name_from_world_name(world_name)
	for _, entry_name in ipairs(self._level_index) do
		if world_name == self[entry_name].world_name then
			return entry_name
		end
	end
end
function LevelsTweakData:get_localized_level_name_from_world_name(world_name)
	for _, entry_name in ipairs(self._level_index) do
		if world_name == self[entry_name].world_name then
			return managers.localization:text(self[entry_name].name_id)
		end
	end
end
function LevelsTweakData:get_localized_level_name_from_level_id(level_id)
	for _, entry_name in ipairs(self._level_index) do
		if level_id == entry_name then
			return managers.localization:text(self[entry_name].name_id)
		end
	end
end
function LevelsTweakData:get_music_event(stage)
	local level_data = Global.level_data.level_id and tweak_data.levels[Global.level_data.level_id]
	local music_id = level_data and level_data.music or "default"
	return tweak_data.music[music_id][stage]
end
