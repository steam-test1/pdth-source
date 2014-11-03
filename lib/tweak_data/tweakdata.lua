require("lib/tweak_data/WeaponTweakData")
require("lib/tweak_data/EquipmentsTweakData")
require("lib/tweak_data/CharacterTweakData")
require("lib/tweak_data/PlayerTweakData")
require("lib/tweak_data/StatisticsTweakData")
require("lib/tweak_data/LevelsTweakData")
require("lib/tweak_data/GroupAITweakData")
require("lib/tweak_data/DramaTweakData")
require("lib/tweak_data/SecretAssignmentTweakData")
require("lib/tweak_data/ChallengesTweakData")
require("lib/tweak_data/UpgradesTweakData")
require("lib/tweak_data/UpgradesVisualTweakData")
require("lib/tweak_data/HudIconsTweakData")
require("lib/tweak_data/TipsTweakData")
TweakData = TweakData or class()
TweakData.RELOAD = true
function TweakData:set_difficulty()
	if not Global.game_settings then
		return
	end
	if Global.game_settings.difficulty == "easy" then
		self:_set_easy()
	elseif Global.game_settings.difficulty == "normal" then
		self:_set_normal()
	elseif Global.game_settings.difficulty == "overkill" then
		self:_set_overkill()
	elseif Global.game_settings.difficulty == "overkill_145" then
		self:_set_overkill_145()
	else
		self:_set_hard()
	end
end
function TweakData:_set_easy()
	self.player:_set_easy()
	self.character:_set_easy()
	self.group_ai:_set_easy()
	self.experience_manager.total_level_objectives = 1000
	self.experience_manager.total_criminals_finished = 25
	self.experience_manager.total_objectives_finished = 750
	self.experience_manager.civilians_killed = 15
end
function TweakData:_set_normal()
	self.player:_set_normal()
	self.character:_set_normal()
	self.group_ai:_set_normal()
	self.experience_manager.total_level_objectives = 2000
	self.experience_manager.total_criminals_finished = 50
	self.experience_manager.total_objectives_finished = 1000
	self.experience_manager.civilians_killed = 35
end
function TweakData:_set_hard()
	self.player:_set_hard()
	self.character:_set_hard()
	self.group_ai:_set_hard()
	self.experience_manager.total_level_objectives = 2500
	self.experience_manager.total_criminals_finished = 150
	self.experience_manager.total_objectives_finished = 1500
	self.experience_manager.civilians_killed = 75
end
function TweakData:_set_overkill()
	self.player:_set_overkill()
	self.character:_set_overkill()
	self.group_ai:_set_overkill()
	self.experience_manager.total_level_objectives = 5000
	self.experience_manager.total_criminals_finished = 500
	self.experience_manager.total_objectives_finished = 3000
	self.experience_manager.civilians_killed = 150
end
function TweakData:_set_overkill_145()
	self.player:_set_overkill_145()
	self.character:_set_overkill_145()
	self.group_ai:_set_overkill_145()
	self.experience_manager.total_level_objectives = 5000
	self.experience_manager.total_criminals_finished = 2000
	self.experience_manager.total_objectives_finished = 3000
	self.experience_manager.civilians_killed = 550
end
function TweakData:difficulty_to_index(difficulty)
	for i, diff in ipairs(self.difficulties) do
		if diff == difficulty then
			return i
		end
	end
end
function TweakData:index_to_difficulty(index)
	return self.difficulties[index]
end
function TweakData:permission_to_index(permission)
	for i, perm in ipairs(self.permissions) do
		if perm == permission then
			return i
		end
	end
end
function TweakData:index_to_permission(index)
	return self.permissions[index]
end
function TweakData:server_state_to_index(state)
	for i, server_state in ipairs(self.server_states) do
		if server_state == state then
			return i
		end
	end
end
function TweakData:index_to_server_state(index)
	return self.server_states[index]
end
function TweakData:init()
	self.hud_icons = HudIconsTweakData:new()
	self.weapon = WeaponTweakData:new()
	self.equipments = EquipmentsTweakData:new()
	self.player = PlayerTweakData:new()
	self.character = CharacterTweakData:new(self)
	self.statistics = StatisticsTweakData:new()
	self.levels = LevelsTweakData:new()
	self.group_ai = GroupAITweakData:new()
	self.drama = DramaTweakData:new()
	self.secret_assignment_manager = SecretAssignmentTweakData:new()
	self.challenges = ChallengesTweakData:new()
	self.upgrades = UpgradesTweakData:new()
	self.upgrades.visual = UpgradesVisualTweakData:new()
	self.tips = TipsTweakData:new()
	self:set_scale()
	self.difficulties = {
		"easy",
		"normal",
		"hard",
		"overkill",
		"overkill_145"
	}
	self.permissions = {
		"public",
		"friends_only",
		"private"
	}
	self.server_states = {
		"in_lobby",
		"loading",
		"in_game"
	}
	self.mask_sets = {
		clowns = {
			{
				mask_icon = "mask_clown2",
				health_gui_offset = 128,
				mask_obj = "units/characters/npc/criminal/masks/clown/hoxton_clown"
			},
			{
				mask_icon = "mask_clown1",
				health_gui_offset = 64,
				mask_obj = "units/characters/npc/criminal/masks/clown/wolf_clown"
			},
			{
				mask_icon = "mask_clown3",
				health_gui_offset = 0,
				mask_obj = "units/characters/npc/criminal/masks/clown/dallas_clown"
			},
			{
				mask_icon = "mask_clown4",
				health_gui_offset = 192,
				mask_obj = "units/characters/npc/criminal/masks/clown/chains_clown"
			},
			health_gui_image = "guis/textures/team_health_org"
		},
		alienware = {
			{
				mask_icon = "mask_alien2",
				health_gui_offset = 128,
				mask_obj = "units/characters/npc/criminal/masks/alien/hoxton_alien"
			},
			{
				mask_icon = "mask_alien1",
				health_gui_offset = 64,
				mask_obj = "units/characters/npc/criminal/masks/alien/wolf_alien"
			},
			{
				mask_icon = "mask_alien3",
				health_gui_offset = 0,
				mask_obj = "units/characters/npc/criminal/masks/alien/dallas_alien"
			},
			{
				mask_icon = "mask_alien4",
				health_gui_offset = 192,
				mask_obj = "units/characters/npc/criminal/masks/alien/chains_alien"
			},
			health_gui_image = "guis/textures/team_health_alienware"
		},
		developer = {
			{
				mask_icon = "mask_dev",
				health_gui_offset = 0,
				mask_obj = "units/characters/npc/criminal/masks/hockey/hoxton_hockey"
			},
			{
				mask_icon = "mask_dev",
				health_gui_offset = 0,
				mask_obj = "units/characters/npc/criminal/masks/hockey/wolf_hockey"
			},
			{
				mask_icon = "mask_dev",
				health_gui_offset = 0,
				mask_obj = "units/characters/npc/criminal/masks/hockey/dallas_hockey"
			},
			{
				mask_icon = "mask_dev",
				health_gui_offset = 0,
				mask_obj = "units/characters/npc/criminal/masks/hockey/chains_hockey"
			},
			health_gui_image = "guis/textures/team_health_devcom"
		},
		hockey_com = {
			{
				mask_icon = "mask_com",
				health_gui_offset = 64,
				mask_obj = "units/characters/npc/criminal/masks/hockey_com/hoxton_hockey_com"
			},
			{
				mask_icon = "mask_com",
				health_gui_offset = 64,
				mask_obj = "units/characters/npc/criminal/masks/hockey_com/wolf_hockey_com"
			},
			{
				mask_icon = "mask_com",
				health_gui_offset = 64,
				mask_obj = "units/characters/npc/criminal/masks/hockey_com/dallas_hockey_com"
			},
			{
				mask_icon = "mask_com",
				health_gui_offset = 64,
				mask_obj = "units/characters/npc/criminal/masks/hockey_com/chains_hockey_com"
			},
			health_gui_image = "guis/textures/team_health_devcom"
		},
		bf3 = {
			{
				mask_icon = "mask_bf2",
				health_gui_offset = 128,
				mask_obj = "units/characters/npc/criminal/masks/beeef/hoxton_beeef"
			},
			{
				mask_icon = "mask_bf1",
				health_gui_offset = 64,
				mask_obj = "units/characters/npc/criminal/masks/beeef/wolf_beeef"
			},
			{
				mask_icon = "mask_bf3",
				health_gui_offset = 0,
				mask_obj = "units/characters/npc/criminal/masks/beeef/dallas_beeef"
			},
			{
				mask_icon = "mask_bf4",
				health_gui_offset = 192,
				mask_obj = "units/characters/npc/criminal/masks/beeef/chains_beeef"
			},
			health_gui_image = "guis/textures/team_health_beef"
		},
		santa = {
			{
				mask_icon = "mask_santa",
				health_gui_offset = 128,
				mask_obj = {
					default = "units/characters/npc/criminal/masks/santa_clause_mask/hoxton_santa",
					bridge = "units/characters/npc/criminal/masks/santa_clause_mask/hoxton_santa_raincoat"
				}
			},
			{
				mask_icon = "mask_santa",
				health_gui_offset = 128,
				mask_obj = {
					default = "units/characters/npc/criminal/masks/santa_clause_mask/wolf_santa",
					bridge = "units/characters/npc/criminal/masks/santa_clause_mask/wolf_santa_raincoat"
				}
			},
			{
				mask_icon = "mask_santa",
				health_gui_offset = 128,
				mask_obj = {
					default = "units/characters/npc/criminal/masks/santa_clause_mask/dallas_santa",
					bridge = "units/characters/npc/criminal/masks/santa_clause_mask/dallas_santa_raincoat"
				}
			},
			{
				mask_icon = "mask_santa",
				health_gui_offset = 128,
				mask_obj = {
					default = "units/characters/npc/criminal/masks/santa_clause_mask/chains_santa",
					bridge = "units/characters/npc/criminal/masks/santa_clause_mask/chains_santa_raincoat"
				}
			},
			health_gui_image = "guis/textures/team_health_devcom"
		},
		gold = {
			{
				mask_icon = "mask_gold2",
				health_gui_offset = 128,
				mask_obj = "units/characters/npc/criminal/masks/gold/hoxton_clown_gold"
			},
			{
				mask_icon = "mask_gold1",
				health_gui_offset = 64,
				mask_obj = "units/characters/npc/criminal/masks/gold/wolf_clown_gold"
			},
			{
				mask_icon = "mask_gold3",
				health_gui_offset = 0,
				mask_obj = "units/characters/npc/criminal/masks/gold/dallas_clown_gold"
			},
			{
				mask_icon = "mask_gold4",
				health_gui_offset = 192,
				mask_obj = "units/characters/npc/criminal/masks/gold/chains_clown_gold"
			},
			health_gui_image = "guis/textures/team_health_145"
		},
		president = {
			{
				mask_icon = "mask_president2",
				health_gui_offset = 128,
				mask_obj = {
					default = "units/characters/npc/criminal/masks/presidents/hoxton_president",
					bridge = "units/characters/npc/criminal/masks/presidents/hoxton_president_raincoat"
				}
			},
			{
				mask_icon = "mask_president1",
				health_gui_offset = 64,
				mask_obj = {
					default = "units/characters/npc/criminal/masks/presidents/wolf_president",
					bridge = "units/characters/npc/criminal/masks/presidents/wolf_president_raincoat"
				}
			},
			{
				mask_icon = "mask_president3",
				health_gui_offset = 0,
				mask_obj = {
					default = "units/characters/npc/criminal/masks/presidents/dallas_president",
					bridge = "units/characters/npc/criminal/masks/presidents/dallas_president_raincoat"
				}
			},
			{
				mask_icon = "mask_president4",
				health_gui_offset = 192,
				mask_obj = "units/characters/npc/criminal/masks/presidents/chains_president"
			},
			health_gui_image = "guis/textures/team_health_presidents"
		},
		zombie = {
			{
				mask_icon = "mask_zombie2",
				health_gui_offset = 128,
				mask_obj = "units/characters/npc/criminal/masks/zombie/boomer_hoxton"
			},
			{
				mask_icon = "mask_zombie1",
				health_gui_offset = 64,
				mask_obj = "units/characters/npc/criminal/masks/zombie/smoker_wolf"
			},
			{
				mask_icon = "mask_zombie3",
				health_gui_offset = 0,
				mask_obj = "units/characters/npc/criminal/masks/zombie/hunter_dallas"
			},
			{
				mask_icon = "mask_zombie4",
				health_gui_offset = 192,
				mask_obj = "units/characters/npc/criminal/masks/zombie/hulk_chains"
			},
			health_gui_image = "guis/textures/team_health_zombie"
		},
		troll = {
			{
				mask_icon = "mask_troll2",
				health_gui_offset = 128,
				mask_obj = "units/characters/npc/criminal/masks/troll/hoxton_lol"
			},
			{
				mask_icon = "mask_troll1",
				health_gui_offset = 64,
				mask_obj = "units/characters/npc/criminal/masks/troll/wolf_lol"
			},
			{
				mask_icon = "mask_troll3",
				health_gui_offset = 0,
				mask_obj = "units/characters/npc/criminal/masks/troll/dallas_lol"
			},
			{
				mask_icon = "mask_troll4",
				health_gui_offset = 192,
				mask_obj = "units/characters/npc/criminal/masks/troll/chains_lol"
			},
			health_gui_image = "guis/textures/team_health_lol"
		},
		music = {
			{
				mask_icon = "mask_music2",
				health_gui_offset = 128,
				mask_obj = "units/characters/npc/criminal/masks/venetian/hoxton_venetian"
			},
			{
				mask_icon = "mask_music1",
				health_gui_offset = 64,
				mask_obj = "units/characters/npc/criminal/masks/venetian/wolf_venetian"
			},
			{
				mask_icon = "mask_music3",
				health_gui_offset = 0,
				mask_obj = {
					default = "units/characters/npc/criminal/masks/venetian/dallas_venetian",
					bridge = "units/characters/npc/criminal/masks/venetian/dallas_venetian_raincoat"
				}
			},
			{
				mask_icon = "mask_music4",
				health_gui_offset = 192,
				mask_obj = "units/characters/npc/criminal/masks/venetian/chains_venetian"
			},
			health_gui_image = "guis/textures/team_health_venetian"
		},
		vyse = {
			{
				mask_icon = "mask_vyse2",
				health_gui_offset = 128,
				mask_obj = "units/characters/npc/criminal/masks/vyse/hoxton_vyce"
			},
			{
				mask_icon = "mask_vyse1",
				health_gui_offset = 64,
				mask_obj = "units/characters/npc/criminal/masks/vyse/wolf_vyce"
			},
			{
				mask_icon = "mask_vyse3",
				health_gui_offset = 0,
				mask_obj = "units/characters/npc/criminal/masks/vyse/dallas_vyce"
			},
			{
				mask_icon = "mask_vyse4",
				health_gui_offset = 192,
				mask_obj = "units/characters/npc/criminal/masks/vyse/chains_vyce"
			},
			health_gui_image = "guis/textures/team_health_vyse"
		},
		halloween = {
			{
				mask_icon = "mask_halloween2",
				health_gui_offset = 128,
				mask_obj = {
					default = "units/characters/npc/criminal/masks/halloween/hoxton_halloween",
					bridge = "units/characters/npc/criminal/masks/halloween/hoxton_halloween_raincoat"
				}
			},
			{
				mask_icon = "mask_halloween1",
				health_gui_offset = 64,
				mask_obj = {
					default = "units/characters/npc/criminal/masks/halloween/wolf_halloween",
					bridge = "units/characters/npc/criminal/masks/halloween/wolf_halloween_raincoat"
				}
			},
			{
				mask_icon = "mask_halloween3",
				health_gui_offset = 0,
				mask_obj = {
					default = "units/characters/npc/criminal/masks/halloween/dallas_halloween",
					bridge = "units/characters/npc/criminal/masks/halloween/dallas_halloween_raincoat"
				}
			},
			{
				mask_icon = "mask_halloween4",
				health_gui_offset = 192,
				mask_obj = "units/characters/npc/criminal/masks/halloween/chains_halloween"
			},
			health_gui_image = "guis/textures/team_health_halloween"
		},
		tester = {
			{
				mask_icon = "mask_tester2",
				health_gui_offset = 128,
				mask_obj = "units/characters/npc/criminal/masks/tester/hoxton_tester"
			},
			{
				mask_icon = "mask_tester1",
				health_gui_offset = 64,
				mask_obj = "units/characters/npc/criminal/masks/tester/wolf_tester"
			},
			{
				mask_icon = "mask_tester3",
				health_gui_offset = 0,
				mask_obj = "units/characters/npc/criminal/masks/tester/dallas_tester"
			},
			{
				mask_icon = "mask_tester4",
				health_gui_offset = 192,
				mask_obj = "units/characters/npc/criminal/masks/tester/chains_tester"
			},
			health_gui_image = "guis/textures/team_health_tester"
		},
		end_of_the_world = {
			{
				mask_icon = "mask_end_of_the_world2",
				health_gui_offset = 128,
				mask_obj = "units/characters/npc/criminal/masks/end_of_the_world/hoxton_end_of_the_world"
			},
			{
				mask_icon = "mask_end_of_the_world1",
				health_gui_offset = 64,
				mask_obj = "units/characters/npc/criminal/masks/end_of_the_world/wolf_end_of_the_world"
			},
			{
				mask_icon = "mask_end_of_the_world3",
				health_gui_offset = 0,
				mask_obj = "units/characters/npc/criminal/masks/end_of_the_world/dallas_end_of_the_world"
			},
			{
				mask_icon = "mask_end_of_the_world4",
				health_gui_offset = 192,
				mask_obj = "units/characters/npc/criminal/masks/end_of_the_world/chains_end_of_the_world"
			},
			health_gui_image = "guis/textures/team_health_end_of_the_world"
		}
	}
	self.menu_themes = {
		old = {
			bg_startscreen = "guis/textures/menu/old_theme/bg_startscreen",
			bg_dlc = "guis/textures/menu/old_theme/bg_dlc",
			bg_setupgame = "guis/textures/menu/old_theme/bg_setupgame",
			bg_creategame = "guis/textures/menu/old_theme/bg_creategame",
			bg_challenge = "guis/textures/menu/old_theme/bg_challenge",
			bg_upgrades = "guis/textures/menu/old_theme/bg_upgrades",
			bg_stats = "guis/textures/menu/old_theme/bg_stats",
			bg_options = "guis/textures/menu/old_theme/bg_options",
			bg_assault = "guis/textures/menu/old_theme/bg_assault",
			bg_sharpshooter = "guis/textures/menu/old_theme/bg_sharpshooter",
			bg_support = "guis/textures/menu/old_theme/bg_support",
			bg_technician = "guis/textures/menu/old_theme/bg_technician",
			bg_lobby_fullteam = "guis/textures/menu/old_theme/bg_lobby_fullteam",
			bg_hoxton = "guis/textures/menu/old_theme/bg_hoxton",
			bg_wolf = "guis/textures/menu/old_theme/bg_wolf",
			bg_dallas = "guis/textures/menu/old_theme/bg_dallas",
			bg_chains = "guis/textures/menu/old_theme/bg_chains",
			background = "guis/textures/menu/old_theme/background"
		},
		fire = {
			bg_startscreen = "guis/textures/menu/fire_theme/bg_startscreen",
			bg_dlc = "guis/textures/menu/fire_theme/bg_dlc",
			bg_setupgame = "guis/textures/menu/fire_theme/bg_setupgame",
			bg_creategame = "guis/textures/menu/fire_theme/bg_creategame",
			bg_challenge = "guis/textures/menu/fire_theme/bg_challenge",
			bg_upgrades = "guis/textures/menu/fire_theme/bg_upgrades",
			bg_stats = "guis/textures/menu/fire_theme/bg_stats",
			bg_options = "guis/textures/menu/fire_theme/bg_options",
			bg_assault = "guis/textures/menu/fire_theme/bg_assault",
			bg_sharpshooter = "guis/textures/menu/fire_theme/bg_sharpshooter",
			bg_support = "guis/textures/menu/fire_theme/bg_support",
			bg_technician = "guis/textures/menu/fire_theme/bg_technician",
			bg_lobby_fullteam = "guis/textures/menu/fire_theme/bg_lobby_fullteam",
			bg_hoxton = "guis/textures/menu/fire_theme/bg_hoxton",
			bg_wolf = "guis/textures/menu/fire_theme/bg_wolf",
			bg_dallas = "guis/textures/menu/fire_theme/bg_dallas",
			bg_chains = "guis/textures/menu/fire_theme/bg_chains",
			background = "guis/textures/menu/fire_theme/background"
		},
		zombie = {
			bg_startscreen = "guis/textures/menu/zombie_theme/bg_startscreen",
			bg_dlc = "guis/textures/menu/fire_theme/bg_dlc",
			bg_setupgame = "guis/textures/menu/zombie_theme/bg_setupgame",
			bg_creategame = "guis/textures/menu/zombie_theme/bg_creategame",
			bg_challenge = "guis/textures/menu/zombie_theme/bg_challenge",
			bg_upgrades = "guis/textures/menu/zombie_theme/bg_upgrades",
			bg_stats = "guis/textures/menu/zombie_theme/bg_stats",
			bg_options = "guis/textures/menu/zombie_theme/bg_options",
			bg_assault = "guis/textures/menu/zombie_theme/bg_assault",
			bg_sharpshooter = "guis/textures/menu/zombie_theme/bg_sharpshooter",
			bg_support = "guis/textures/menu/zombie_theme/bg_support",
			bg_technician = "guis/textures/menu/zombie_theme/bg_technician",
			bg_lobby_fullteam = "guis/textures/menu/zombie_theme/bg_lobby_fullteam",
			bg_hoxton = "guis/textures/menu/zombie_theme/bg_hoxton",
			bg_wolf = "guis/textures/menu/zombie_theme/bg_wolf",
			bg_dallas = "guis/textures/menu/zombie_theme/bg_dallas",
			bg_chains = "guis/textures/menu/zombie_theme/bg_chains",
			background = "guis/textures/menu/zombie_theme/background"
		}
	}
	self.states = {}
	self.states.title = {}
	self.states.title.ATTRACT_VIDEO_DELAY = 90
	self.menu = {}
	self.menu.BRIGHTNESS_CHANGE = 0.05
	self.menu.MIN_BRIGHTNESS = 0.5
	self.menu.MAX_BRIGHTNESS = 1.5
	self.menu.MUSIC_CHANGE = 10
	self.menu.MIN_MUSIC_VOLUME = 0
	self.menu.MAX_MUSIC_VOLUME = 100
	self.menu.SFX_CHANGE = 10
	self.menu.MIN_SFX_VOLUME = 0
	self.menu.MAX_SFX_VOLUME = 100
	self.menu.VOICE_CHANGE = 0.05
	self.menu.MIN_VOICE_VOLUME = 0
	self.menu.MAX_VOICE_VOLUME = 1
	self:set_menu_scale()
	self.chat_colors = {
		Color(0.6, 0.6, 1),
		Color(1, 0.6, 0.6),
		Color(0.6, 1, 0.6),
		Color(1, 1, 0.6)
	}
	self.dialog = {}
	self.dialog.WIDTH = 400
	self.dialog.HEIGHT = 300
	self.dialog.PADDING = 30
	self.dialog.BUTTON_PADDING = 5
	self.dialog.BUTTON_SPACING = 10
	self.dialog.FONT = self.menu.default_font
	self.dialog.BG_COLOR = self.menu.default_menu_background_color
	self.dialog.TITLE_TEXT_COLOR = Color(1, 1, 1, 1)
	self.dialog.TEXT_COLOR = self.menu.default_font_row_item_color
	self.dialog.BUTTON_BG_COLOR = Color(0, 0.5, 0.5, 0.5)
	self.dialog.BUTTON_TEXT_COLOR = self.menu.default_font_row_item_color
	self.dialog.SELECTED_BUTTON_BG_COLOR = self.menu.default_font_row_item_color
	self.dialog.SELECTED_BUTTON_TEXT_COLOR = self.menu.default_hightlight_row_item_color
	self.dialog.TITLE_SIZE = self.menu.topic_font_size
	self.dialog.TEXT_SIZE = self.menu.dialog_text_font_size
	self.dialog.BUTTON_SIZE = self.menu.dialog_title_font_size
	self.dialog.TITLE_TEXT_SPACING = 20
	self.dialog.BUTTON_TEXT_SPACING = 3
	self.dialog.DEFAULT_PRIORITY = 1
	self.dialog.MINIMUM_DURATION = 2
	self.dialog.DURATION_PER_CHAR = 0.07
	self.hud = {}
	self:set_hud_values()
	self.interaction = {}
	self.interaction.CULLING_DISTANCE = 2000
	self.interaction.INTERACT_DISTANCE = 200
	self.interaction.copy_machine_smuggle = {}
	self.interaction.copy_machine_smuggle.icon = "equipment_thermite"
	self.interaction.copy_machine_smuggle.text_id = "debug_interact_copy_machine"
	self.interaction.copy_machine_smuggle.interact_distance = 305
	self.interaction.safety_deposit = {}
	self.interaction.safety_deposit.icon = "develop"
	self.interaction.safety_deposit.text_id = "debug_interact_safety_deposit"
	self.interaction.paper_pickup = {}
	self.interaction.paper_pickup.icon = "develop"
	self.interaction.paper_pickup.text_id = "debug_interact_paper_pickup"
	self.interaction.thermite = {}
	self.interaction.thermite.icon = "equipment_thermite"
	self.interaction.thermite.text_id = "debug_interact_thermite"
	self.interaction.thermite.equipment_text_id = "debug_interact_equipment_thermite"
	self.interaction.thermite.special_equipment = "thermite"
	self.interaction.thermite.equipment_consume = true
	self.interaction.thermite.interact_distance = 300
	self.interaction.gasoline = {}
	self.interaction.gasoline.icon = "equipment_thermite"
	self.interaction.gasoline.text_id = "debug_interact_gas"
	self.interaction.gasoline.equipment_text_id = "debug_interact_equipment_gas"
	self.interaction.gasoline.special_equipment = "gas"
	self.interaction.gasoline.equipment_consume = true
	self.interaction.gasoline.interact_distance = 300
	self.interaction.train_car = {}
	self.interaction.train_car.icon = "develop"
	self.interaction.train_car.text_id = "debug_interact_train_car"
	self.interaction.train_car.equipment_text_id = "debug_interact_equipment_gas"
	self.interaction.train_car.special_equipment = "gas"
	self.interaction.train_car.equipment_consume = true
	self.interaction.train_car.interact_distance = 400
	self.interaction.walkout_van = {}
	self.interaction.walkout_van.icon = "develop"
	self.interaction.walkout_van.text_id = "debug_interact_walkout_van"
	self.interaction.walkout_van.equipment_text_id = "debug_interact_equipment_gold"
	self.interaction.walkout_van.special_equipment = "gold"
	self.interaction.walkout_van.equipment_consume = true
	self.interaction.walkout_van.interact_distance = 400
	self.interaction.alaska_plane = {}
	self.interaction.alaska_plane.icon = "develop"
	self.interaction.alaska_plane.text_id = "debug_interact_alaska_plane"
	self.interaction.alaska_plane.equipment_text_id = "debug_interact_equipment_organs"
	self.interaction.alaska_plane.special_equipment = "organs"
	self.interaction.alaska_plane.equipment_consume = true
	self.interaction.alaska_plane.interact_distance = 400
	self.interaction.suburbia_door_crowbar = {}
	self.interaction.suburbia_door_crowbar.icon = "equipment_crowbar"
	self.interaction.suburbia_door_crowbar.text_id = "debug_interact_crowbar"
	self.interaction.suburbia_door_crowbar.equipment_text_id = "debug_interact_equipment_crowbar"
	self.interaction.suburbia_door_crowbar.special_equipment = "crowbar"
	self.interaction.suburbia_door_crowbar.timer = 5
	self.interaction.suburbia_door_crowbar.start_active = false
	self.interaction.suburbia_door_crowbar.sound_start = "crowbar_work_loop"
	self.interaction.suburbia_door_crowbar.sound_interupt = "crowbar_cancel"
	self.interaction.suburbia_door_crowbar.sound_done = "crowbar_work_finished"
	self.interaction.suburbia_door_crowbar.interact_distance = 130
	self.interaction.secret_stash_trunk_crowbar = {}
	self.interaction.secret_stash_trunk_crowbar.icon = "equipment_crowbar"
	self.interaction.secret_stash_trunk_crowbar.text_id = "debug_interact_crowbar2"
	self.interaction.secret_stash_trunk_crowbar.equipment_text_id = "debug_interact_equipment_crowbar"
	self.interaction.secret_stash_trunk_crowbar.special_equipment = "crowbar"
	self.interaction.secret_stash_trunk_crowbar.timer = 20
	self.interaction.secret_stash_trunk_crowbar.start_active = false
	self.interaction.secret_stash_trunk_crowbar.sound_start = "und_crowbar_trunk"
	self.interaction.secret_stash_trunk_crowbar.sound_interupt = "und_crowbar_trunk_cancel"
	self.interaction.secret_stash_trunk_crowbar.sound_done = "und_crowbar_trunk_finished"
	self.interaction.requires_crowbar_interactive_template = {}
	self.interaction.requires_crowbar_interactive_template.icon = "equipment_crowbar"
	self.interaction.requires_crowbar_interactive_template.text_id = "debug_interact_crowbar_breach"
	self.interaction.requires_crowbar_interactive_template.equipment_text_id = "debug_interact_equipment_crowbar"
	self.interaction.requires_crowbar_interactive_template.special_equipment = "crowbar"
	self.interaction.requires_crowbar_interactive_template.timer = 8
	self.interaction.requires_crowbar_interactive_template.start_active = false
	self.interaction.requires_crowbar_interactive_template.sound_start = "crowbar_metal_work_loop"
	self.interaction.requires_crowbar_interactive_template.sound_interupt = "crowbar_metal_cancel"
	self.interaction.requires_crowbar_interactive_template.sound_done = "crowbar_metal_cancel"
	self.interaction.secret_stash_limo_roof_crowbar = {}
	self.interaction.secret_stash_limo_roof_crowbar.icon = "develop"
	self.interaction.secret_stash_limo_roof_crowbar.text_id = "debug_interact_hold_to_breach"
	self.interaction.secret_stash_limo_roof_crowbar.timer = 5
	self.interaction.secret_stash_limo_roof_crowbar.start_active = false
	self.interaction.secret_stash_limo_roof_crowbar.sound_start = "und_limo_chassis_open"
	self.interaction.secret_stash_limo_roof_crowbar.sound_interupt = "und_limo_chassis_open_stop"
	self.interaction.secret_stash_limo_roof_crowbar.sound_done = "und_limo_chassis_open_stop"
	self.interaction.secret_stash_limo_roof_crowbar.axis = "y"
	self.interaction.suburbia_iron_gate_crowbar = {}
	self.interaction.suburbia_iron_gate_crowbar.icon = "equipment_crowbar"
	self.interaction.suburbia_iron_gate_crowbar.text_id = "debug_interact_crowbar"
	self.interaction.suburbia_iron_gate_crowbar.equipment_text_id = "debug_interact_equipment_crowbar"
	self.interaction.suburbia_iron_gate_crowbar.special_equipment = "crowbar"
	self.interaction.suburbia_iron_gate_crowbar.timer = 5
	self.interaction.suburbia_iron_gate_crowbar.start_active = false
	self.interaction.suburbia_iron_gate_crowbar.sound_start = "crowbar_metal_work_loop"
	self.interaction.suburbia_iron_gate_crowbar.sound_interupt = "crowbar_metal_cancel"
	self.interaction.apartment_key = {}
	self.interaction.apartment_key.icon = "equipment_chavez_key"
	self.interaction.apartment_key.text_id = "debug_interact_apartment_key"
	self.interaction.apartment_key.equipment_text_id = "debug_interact_equiptment_apartment_key"
	self.interaction.apartment_key.special_equipment = "chavez_key"
	self.interaction.apartment_key.equipment_consume = true
	self.interaction.apartment_key.interact_distance = 150
	self.interaction.hospital_sample_validation_machine = {}
	self.interaction.hospital_sample_validation_machine.icon = "equipment_vial"
	self.interaction.hospital_sample_validation_machine.text_id = "debug_interact_sample_validation"
	self.interaction.hospital_sample_validation_machine.equipment_text_id = "debug_interact_equiptment_sample_validation"
	self.interaction.hospital_sample_validation_machine.special_equipment = "blood_sample"
	self.interaction.hospital_sample_validation_machine.equipment_consume = true
	self.interaction.hospital_sample_validation_machine.start_active = false
	self.interaction.hospital_sample_validation_machine.interact_distance = 150
	self.interaction.hospital_sample_validation_machine.axis = "y"
	self.interaction.elevator_button = {}
	self.interaction.elevator_button.icon = "interaction_elevator"
	self.interaction.elevator_button.text_id = "debug_interact_elevator_door"
	self.interaction.elevator_button.start_active = false
	self.interaction.elevator_button_roof = {}
	self.interaction.elevator_button_roof.icon = "interaction_elevator"
	self.interaction.elevator_button_roof.text_id = "debug_interact_elevator_door_roof"
	self.interaction.elevator_button_roof.start_active = false
	self.interaction.key = {}
	self.interaction.key.icon = "equipment_bank_manager_key"
	self.interaction.key.text_id = "debug_interact_key"
	self.interaction.key.equipment_text_id = "debug_interact_equipment_key"
	self.interaction.key.special_equipment = "bank_manager_key"
	self.interaction.key.equipment_consume = true
	self.interaction.numpad = {}
	self.interaction.numpad.icon = "equipment_bank_manager_key"
	self.interaction.numpad.text_id = "debug_interact_numpad"
	self.interaction.numpad.start_active = false
	self.interaction.hospital_veil_container = {}
	self.interaction.hospital_veil_container.icon = "equipment_vialOK"
	self.interaction.hospital_veil_container.text_id = "debug_interact_hospital_veil_container"
	self.interaction.hospital_veil_container.equipment_text_id = "debug_interact_equipment_blood_sample_verified"
	self.interaction.hospital_veil_container.special_equipment = "blood_sample_verified"
	self.interaction.hospital_veil_container.equipment_consume = true
	self.interaction.hospital_veil_container.start_active = false
	self.interaction.hospital_veil_container.timer = 2
	self.interaction.hospital_veil_container.axis = "y"
	self.interaction.hospital_phone = {}
	self.interaction.hospital_phone.icon = "interaction_answerphone"
	self.interaction.hospital_phone.text_id = "debug_interact_hospital_phone"
	self.interaction.hospital_phone.start_active = false
	self.interaction.hospital_security_cable = {}
	self.interaction.hospital_security_cable.text_id = "debug_interact_hospital_security_cable"
	self.interaction.hospital_security_cable.icon = "interaction_wirecutter"
	self.interaction.hospital_security_cable.start_active = false
	self.interaction.hospital_security_cable.timer = 5
	self.interaction.hospital_security_cable.interact_distance = 50
	self.interaction.hospital_veil = {}
	self.interaction.hospital_veil.icon = "equipment_vial"
	self.interaction.hospital_veil.text_id = "debug_interact_hospital_veil_hold"
	self.interaction.hospital_veil.start_active = false
	self.interaction.hospital_veil.timer = 2
	self.interaction.hospital_veil_take = {}
	self.interaction.hospital_veil_take.icon = "equipment_vial"
	self.interaction.hospital_veil_take.text_id = "debug_interact_hospital_veil_take"
	self.interaction.hospital_veil_take.start_active = false
	self.interaction.hospital_sentry = {}
	self.interaction.hospital_sentry.icon = "interaction_sentrygun"
	self.interaction.hospital_sentry.text_id = "debug_interact_hospital_sentry"
	self.interaction.hospital_sentry.start_active = false
	self.interaction.hospital_sentry.timer = 2
	self.interaction.s_cube = {}
	self.interaction.s_cube.icon = "develop"
	self.interaction.s_cube.text_id = "debug_interact_temp_interact_box"
	self.interaction.s_cube.start_active = false
	self.interaction.s_cube.timer = 2
	self.interaction.s_cube.contour = "interactable_look_at"
	self.interaction.s_drill_2h = {}
	self.interaction.s_drill_2h.icon = "equipment_drill"
	self.interaction.s_drill_2h.text_id = "debug_interact_drill"
	self.interaction.s_drill_2h.equipment_text_id = "debug_interact_equipment_drill"
	self.interaction.s_drill_2h.special_equipment = "drill"
	self.interaction.s_drill_2h.timer = 3
	self.interaction.s_drill_2h.blocked_hint = "no_drill"
	self.interaction.s_drill_2h.sound_start = "bar_drill_apply"
	self.interaction.s_drill_2h.sound_interupt = "bar_drill_apply_cancel"
	self.interaction.s_drill_2h.sound_done = "bar_drill_apply_finished"
	self.interaction.s_drill_2h.axis = "y"
	self.interaction.drill = {}
	self.interaction.drill.icon = "equipment_drill"
	self.interaction.drill.text_id = "debug_interact_drill"
	self.interaction.drill.equipment_text_id = "debug_interact_equipment_drill"
	self.interaction.drill.special_equipment = "drill"
	self.interaction.drill.timer = 3
	self.interaction.drill.blocked_hint = "no_drill"
	self.interaction.drill.sound_start = "bar_drill_apply"
	self.interaction.drill.sound_interupt = "bar_drill_apply_cancel"
	self.interaction.drill.sound_done = "bar_drill_apply_finished"
	self.interaction.drill.axis = "y"
	self.interaction.drill_jammed = {}
	self.interaction.drill_jammed.icon = "equipment_drill"
	self.interaction.drill_jammed.text_id = "debug_interact_drill_jammed"
	self.interaction.drill_jammed.timer = 10
	self.interaction.drill_jammed.sound_start = "bar_drill_fix"
	self.interaction.drill_jammed.sound_interupt = "bar_drill_fix_cancel"
	self.interaction.drill_jammed.sound_done = "bar_drill_fix_finished"
	self.interaction.glass_cutter = {}
	self.interaction.glass_cutter.icon = "equipment_cutter"
	self.interaction.glass_cutter.text_id = "debug_interact_glass_cutter"
	self.interaction.glass_cutter.equipment_text_id = "debug_interact_equipment_glass_cutter"
	self.interaction.glass_cutter.special_equipment = "glass_cutter"
	self.interaction.glass_cutter.timer = 3
	self.interaction.glass_cutter.blocked_hint = "no_glass_cutter"
	self.interaction.glass_cutter.sound_start = "bar_drill_apply"
	self.interaction.glass_cutter.sound_interupt = "bar_drill_apply_cancel"
	self.interaction.glass_cutter.sound_done = "bar_drill_apply_finished"
	self.interaction.glass_cutter_jammed = {}
	self.interaction.glass_cutter_jammed.icon = "equipment_cutter"
	self.interaction.glass_cutter_jammed.text_id = "debug_interact_cutter_jammed"
	self.interaction.glass_cutter_jammed.timer = 10
	self.interaction.glass_cutter_jammed.sound_start = "bar_drill_fix"
	self.interaction.glass_cutter_jammed.sound_interupt = "bar_drill_fix_cancel"
	self.interaction.glass_cutter_jammed.sound_done = "bar_drill_fix_finished"
	self.interaction.hack_ipad = {}
	self.interaction.hack_ipad.icon = "equipment_hack_ipad"
	self.interaction.hack_ipad.text_id = "debug_interact_hack_ipad"
	self.interaction.hack_ipad.timer = 3
	self.interaction.hack_ipad.sound_start = "bar_drill_apply"
	self.interaction.hack_ipad.sound_interupt = "bar_drill_apply_cancel"
	self.interaction.hack_ipad.sound_done = "bar_drill_apply_finished"
	self.interaction.hack_ipad.axis = "x"
	self.interaction.hack_ipad_jammed = {}
	self.interaction.hack_ipad_jammed.icon = "equipment_hack_ipad"
	self.interaction.hack_ipad_jammed.text_id = "debug_interact_hack_ipad_jammed"
	self.interaction.hack_ipad_jammed.timer = 10
	self.interaction.hack_ipad_jammed.sound_start = "bar_drill_fix"
	self.interaction.hack_ipad_jammed.sound_interupt = "bar_drill_fix_cancel"
	self.interaction.hack_ipad_jammed.sound_done = "bar_drill_fix_finished"
	self.interaction.hack_suburbia = {}
	self.interaction.hack_suburbia.icon = "equipment_hack_ipad"
	self.interaction.hack_suburbia.text_id = "debug_interact_hack_ipad"
	self.interaction.hack_suburbia.timer = 5
	self.interaction.hack_suburbia.sound_start = "bar_drill_apply"
	self.interaction.hack_suburbia.sound_interupt = "bar_drill_apply_cancel"
	self.interaction.hack_suburbia.sound_done = "bar_drill_apply_finished"
	self.interaction.hack_suburbia.axis = "x"
	self.interaction.hack_suburbia_jammed = {}
	self.interaction.hack_suburbia_jammed.icon = "equipment_hack_ipad"
	self.interaction.hack_suburbia_jammed.text_id = "debug_interact_hack_ipad_jammed"
	self.interaction.hack_suburbia_jammed.timer = 5
	self.interaction.hack_suburbia_jammed.sound_start = "bar_drill_fix"
	self.interaction.hack_suburbia_jammed.sound_interupt = "bar_drill_fix_cancel"
	self.interaction.hack_suburbia_jammed.sound_done = "bar_drill_fix_finished"
	self.interaction.security_station = {}
	self.interaction.security_station.icon = "equipment_hack_ipad"
	self.interaction.security_station.text_id = "debug_interact_security_station"
	self.interaction.security_station.timer = 3
	self.interaction.security_station.sound_start = "bar_drill_apply"
	self.interaction.security_station.sound_interupt = "bar_drill_apply_cancel"
	self.interaction.security_station.sound_done = "bar_drill_apply_finished"
	self.interaction.security_station.axis = "z"
	self.interaction.security_station.start_active = false
	self.interaction.security_station.sound_start = "bar_keyboard"
	self.interaction.security_station.sound_interupt = "bar_keyboard_cancel"
	self.interaction.security_station.sound_done = "bar_keyboard_finished"
	self.interaction.security_station_keyboard = {}
	self.interaction.security_station_keyboard.icon = "interaction_keyboard"
	self.interaction.security_station_keyboard.text_id = "debug_interact_security_station"
	self.interaction.security_station_keyboard.timer = 3
	self.interaction.security_station_keyboard.axis = "z"
	self.interaction.security_station_keyboard.start_active = false
	self.interaction.security_station_keyboard.interact_distance = 100
	self.interaction.security_station_keyboard.sound_start = "bar_keyboard"
	self.interaction.security_station_keyboard.sound_interupt = "bar_keyboard_cancel"
	self.interaction.security_station_keyboard.sound_done = "bar_keyboard_finished"
	self.interaction.security_station_jammed = {}
	self.interaction.security_station_jammed.icon = "interaction_keyboard"
	self.interaction.security_station_jammed.text_id = "debug_interact_security_station_jammed"
	self.interaction.security_station_jammed.timer = 10
	self.interaction.security_station_jammed.sound_start = "bar_drill_fix"
	self.interaction.security_station_jammed.sound_interupt = "bar_drill_fix_cancel"
	self.interaction.security_station_jammed.sound_done = "bar_drill_fix_finished"
	self.interaction.security_station_jammed.axis = "z"
	self.interaction.apartment_drill = {}
	self.interaction.apartment_drill.icon = "equipment_drill"
	self.interaction.apartment_drill.text_id = "debug_interact_drill"
	self.interaction.apartment_drill.equipment_text_id = "debug_interact_equipment_drill"
	self.interaction.apartment_drill.special_equipment = "drill"
	self.interaction.apartment_drill.timer = 3
	self.interaction.apartment_drill.blocked_hint = "no_drill"
	self.interaction.apartment_drill.sound_start = "bar_drill_apply"
	self.interaction.apartment_drill.sound_interupt = "bar_drill_apply_cancel"
	self.interaction.apartment_drill.sound_done = "bar_drill_apply_finished"
	self.interaction.apartment_drill.interact_distance = 200
	self.interaction.apartment_drill_jammed = {}
	self.interaction.apartment_drill_jammed.icon = "equipment_drill"
	self.interaction.apartment_drill_jammed.text_id = "debug_interact_drill_jammed"
	self.interaction.apartment_drill_jammed.timer = 3
	self.interaction.apartment_drill_jammed.sound_start = "bar_drill_fix"
	self.interaction.apartment_drill_jammed.sound_interupt = "bar_drill_fix_cancel"
	self.interaction.apartment_drill_jammed.sound_done = "bar_drill_fix_finished"
	self.interaction.apartment_drill_jammed.interact_distance = 200
	self.interaction.suburbia_drill = {}
	self.interaction.suburbia_drill.icon = "equipment_drill"
	self.interaction.suburbia_drill.text_id = "debug_interact_drill"
	self.interaction.suburbia_drill.equipment_text_id = "debug_interact_equipment_drill"
	self.interaction.suburbia_drill.special_equipment = "drill"
	self.interaction.suburbia_drill.timer = 3
	self.interaction.suburbia_drill.blocked_hint = "no_drill"
	self.interaction.suburbia_drill.sound_start = "bar_drill_apply"
	self.interaction.suburbia_drill.sound_interupt = "bar_drill_apply_cancel"
	self.interaction.suburbia_drill.sound_done = "bar_drill_apply_finished"
	self.interaction.suburbia_drill.interact_distance = 200
	self.interaction.suburbia_drill_jammed = {}
	self.interaction.suburbia_drill_jammed.icon = "equipment_drill"
	self.interaction.suburbia_drill_jammed.text_id = "debug_interact_drill_jammed"
	self.interaction.suburbia_drill_jammed.timer = 3
	self.interaction.suburbia_drill_jammed.sound_start = "bar_drill_fix"
	self.interaction.suburbia_drill_jammed.sound_interupt = "bar_drill_fix_cancel"
	self.interaction.suburbia_drill_jammed.sound_done = "bar_drill_fix_finished"
	self.interaction.suburbia_drill_jammed.interact_distance = 200
	self.interaction.goldheist_drill = {}
	self.interaction.goldheist_drill.icon = "equipment_drill"
	self.interaction.goldheist_drill.text_id = "debug_interact_drill"
	self.interaction.goldheist_drill.equipment_text_id = "debug_interact_equipment_drill"
	self.interaction.goldheist_drill.special_equipment = "drill"
	self.interaction.goldheist_drill.timer = 3
	self.interaction.goldheist_drill.blocked_hint = "no_drill"
	self.interaction.goldheist_drill.sound_start = "bar_drill_apply"
	self.interaction.goldheist_drill.sound_interupt = "bar_drill_apply_cancel"
	self.interaction.goldheist_drill.sound_done = "bar_drill_apply_finished"
	self.interaction.goldheist_drill.interact_distance = 200
	self.interaction.goldheist_drill_jammed = {}
	self.interaction.goldheist_drill_jammed.icon = "equipment_drill"
	self.interaction.goldheist_drill_jammed.text_id = "debug_interact_drill_jammed"
	self.interaction.goldheist_drill_jammed.timer = 3
	self.interaction.goldheist_drill_jammed.sound_start = "bar_drill_fix"
	self.interaction.goldheist_drill_jammed.sound_interupt = "bar_drill_fix_cancel"
	self.interaction.goldheist_drill_jammed.sound_done = "bar_drill_fix_finished"
	self.interaction.goldheist_drill_jammed.interact_distance = 200
	self.interaction.hospital_saw_teddy = {}
	self.interaction.hospital_saw_teddy.icon = "equipment_saw"
	self.interaction.hospital_saw_teddy.text_id = "debug_interact_hospital_saw_teddy"
	self.interaction.hospital_saw_teddy.start_active = false
	self.interaction.hospital_saw_teddy.timer = 2
	self.interaction.hospital_saw = {}
	self.interaction.hospital_saw.icon = "equipment_saw"
	self.interaction.hospital_saw.text_id = "debug_interact_saw"
	self.interaction.hospital_saw.equipment_text_id = "debug_interact_equipment_saw"
	self.interaction.hospital_saw.special_equipment = "saw"
	self.interaction.hospital_saw.timer = 3
	self.interaction.hospital_saw.sound_start = "bar_drill_apply"
	self.interaction.hospital_saw.sound_interupt = "bar_drill_apply_cancel"
	self.interaction.hospital_saw.sound_done = "bar_drill_apply_finished"
	self.interaction.hospital_saw.interact_distance = 200
	self.interaction.hospital_saw.axis = "z"
	self.interaction.hospital_saw_jammed = {}
	self.interaction.hospital_saw_jammed.icon = "equipment_saw"
	self.interaction.hospital_saw_jammed.text_id = "debug_interact_saw_jammed"
	self.interaction.hospital_saw_jammed.timer = 3
	self.interaction.hospital_saw_jammed.sound_start = "bar_drill_fix"
	self.interaction.hospital_saw_jammed.sound_interupt = "bar_drill_fix_cancel"
	self.interaction.hospital_saw_jammed.sound_done = "bar_drill_fix_finished"
	self.interaction.hospital_saw_jammed.interact_distance = 200
	self.interaction.hospital_saw_jammed.axis = "z"
	self.interaction.apartment_saw = {}
	self.interaction.apartment_saw.icon = "equipment_saw"
	self.interaction.apartment_saw.text_id = "debug_interact_saw"
	self.interaction.apartment_saw.equipment_text_id = "debug_interact_equipment_saw"
	self.interaction.apartment_saw.special_equipment = "saw"
	self.interaction.apartment_saw.timer = 3
	self.interaction.apartment_saw.sound_start = "bar_drill_apply"
	self.interaction.apartment_saw.sound_interupt = "bar_drill_apply_cancel"
	self.interaction.apartment_saw.sound_done = "bar_drill_apply_finished"
	self.interaction.apartment_saw.interact_distance = 200
	self.interaction.apartment_saw.axis = "z"
	self.interaction.apartment_saw_jammed = {}
	self.interaction.apartment_saw_jammed.icon = "equipment_saw"
	self.interaction.apartment_saw_jammed.text_id = "debug_interact_saw_jammed"
	self.interaction.apartment_saw_jammed.timer = 3
	self.interaction.apartment_saw_jammed.sound_start = "bar_drill_fix"
	self.interaction.apartment_saw_jammed.sound_interupt = "bar_drill_fix_cancel"
	self.interaction.apartment_saw_jammed.sound_done = "bar_drill_fix_finished"
	self.interaction.apartment_saw_jammed.interact_distance = 200
	self.interaction.apartment_saw_jammed.axis = "z"
	self.interaction.secret_stash_saw = {}
	self.interaction.secret_stash_saw.icon = "equipment_saw"
	self.interaction.secret_stash_saw.text_id = "debug_interact_saw"
	self.interaction.secret_stash_saw.equipment_text_id = "debug_interact_equipment_saw"
	self.interaction.secret_stash_saw.special_equipment = "saw"
	self.interaction.secret_stash_saw.timer = 3
	self.interaction.secret_stash_saw.sound_start = "bar_drill_apply"
	self.interaction.secret_stash_saw.sound_interupt = "bar_drill_apply_cancel"
	self.interaction.secret_stash_saw.sound_done = "bar_drill_apply_finished"
	self.interaction.secret_stash_saw.interact_distance = 200
	self.interaction.secret_stash_saw.axis = "z"
	self.interaction.secret_stash_saw_jammed = {}
	self.interaction.secret_stash_saw_jammed.icon = "equipment_saw"
	self.interaction.secret_stash_saw_jammed.text_id = "debug_interact_saw_jammed"
	self.interaction.secret_stash_saw_jammed.timer = 3
	self.interaction.secret_stash_saw_jammed.sound_start = "bar_drill_fix"
	self.interaction.secret_stash_saw_jammed.sound_interupt = "bar_drill_fix_cancel"
	self.interaction.secret_stash_saw_jammed.sound_done = "bar_drill_fix_finished"
	self.interaction.secret_stash_saw_jammed.interact_distance = 200
	self.interaction.secret_stash_saw_jammed.axis = "z"
	self.interaction.revive = {}
	self.interaction.revive.icon = "interaction_help"
	self.interaction.revive.text_id = "debug_interact_revive"
	self.interaction.revive.start_active = false
	self.interaction.revive.interact_distance = 300
	self.interaction.revive.no_contour = true
	self.interaction.revive.axis = "z"
	self.interaction.revive.timer = 6
	self.interaction.revive.sound_start = "bar_helpup"
	self.interaction.revive.sound_interupt = "bar_helpup_cancel"
	self.interaction.revive.sound_done = "bar_helpup_finished"
	self.interaction.free = {}
	self.interaction.free.icon = "interaction_free"
	self.interaction.free.text_id = "debug_interact_free"
	self.interaction.free.start_active = false
	self.interaction.free.interact_distance = 300
	self.interaction.free.no_contour = true
	self.interaction.free.timer = 1
	self.interaction.free.sound_start = "bar_rescue"
	self.interaction.free.sound_interupt = "bar_rescue_cancel"
	self.interaction.free.sound_done = "bar_rescue_finished"
	self.interaction.hostage_trade = {}
	self.interaction.hostage_trade.icon = "interaction_trade"
	self.interaction.hostage_trade.text_id = "debug_interact_trade"
	self.interaction.hostage_trade.start_active = true
	self.interaction.hostage_trade.contour = "character_interactable"
	self.interaction.hostage_trade.timer = 3
	self.interaction.trip_mine = {}
	self.interaction.trip_mine.icon = "equipment_trip_mine"
	self.interaction.trip_mine.text_id = "debug_interact_trip_mine"
	self.interaction.trip_mine.contour = "deployable"
	self.interaction.ammo_bag = {}
	self.interaction.ammo_bag.icon = "equipment_ammo_bag"
	self.interaction.ammo_bag.text_id = "debug_interact_ammo_bag_take_ammo"
	self.interaction.ammo_bag.contour = "deployable"
	self.interaction.ammo_bag.timer = 3.5
	self.interaction.ammo_bag.blocked_hint = "full_ammo"
	self.interaction.ammo_bag.sound_start = "bar_bag_generic"
	self.interaction.ammo_bag.sound_interupt = "bar_bag_generic_cancel"
	self.interaction.ammo_bag.sound_done = "bar_bag_generic_finished"
	self.interaction.doctor_bag = {}
	self.interaction.doctor_bag.icon = "equipment_doctor_bag"
	self.interaction.doctor_bag.text_id = "debug_interact_doctor_bag_heal"
	self.interaction.doctor_bag.contour = "deployable"
	self.interaction.doctor_bag.timer = 3.5
	self.interaction.doctor_bag.blocked_hint = "full_health"
	self.interaction.doctor_bag.sound_start = "bar_helpup"
	self.interaction.doctor_bag.sound_interupt = "bar_helpup_cancel"
	self.interaction.doctor_bag.sound_done = "bar_helpup_finished"
	self.interaction.laptop_objective = {}
	self.interaction.laptop_objective.icon = "laptop_objective"
	self.interaction.laptop_objective.start_active = false
	self.interaction.laptop_objective.text_id = "debug_interact_laptop_objective"
	self.interaction.laptop_objective.timer = 15
	self.interaction.laptop_objective.sound_start = "bar_keyboard"
	self.interaction.laptop_objective.sound_interupt = "bar_keyboard_cancel"
	self.interaction.laptop_objective.sound_done = "bar_keyboard_finished"
	self.interaction.laptop_objective.say_waiting = "i01x_any"
	self.interaction.laptop_objective.axis = "z"
	self.interaction.laptop_objective.interact_distance = 100
	self.interaction.money_bag = {}
	self.interaction.money_bag.icon = "equipment_money_bag"
	self.interaction.money_bag.text_id = "debug_interact_money_bag"
	self.interaction.money_bag.equipment_text_id = "debug_interact_equipment_money_bag"
	self.interaction.money_bag.special_equipment = "money_bag"
	self.interaction.money_bag.equipment_consume = false
	self.interaction.money_bag.sound_event = "ammo_bag_drop"
	self.interaction.apartment_helicopter = {}
	self.interaction.apartment_helicopter.icon = "develop"
	self.interaction.apartment_helicopter.text_id = "debug_interact_apartment_helicopter"
	self.interaction.apartment_helicopter.sound_event = "ammo_bag_drop"
	self.interaction.apartment_helicopter.timer = 13
	self.interaction.apartment_helicopter.interact_distance = 350
	self.interaction.temp_interact_box = {}
	self.interaction.temp_interact_box.icon = "develop"
	self.interaction.temp_interact_box.text_id = "debug_interact_temp_interact_box"
	self.interaction.temp_interact_box.sound_event = "ammo_bag_drop"
	self.interaction.temp_interact_box.timer = 4
	self.interaction.interaction_ball = {}
	self.interaction.interaction_ball.icon = "develop"
	self.interaction.interaction_ball.text_id = "debug_interact_interaction_ball"
	self.interaction.interaction_ball.timer = 5
	self.interaction.interaction_ball.sound_start = "cft_hose_loop"
	self.interaction.interaction_ball.sound_interupt = "cft_hose_cancel"
	self.interaction.interaction_ball.sound_done = "cft_hose_end"
	self.interaction.water_tap = {}
	self.interaction.water_tap.icon = "develop"
	self.interaction.water_tap.text_id = "debug_interact_water_tap"
	self.interaction.water_tap.timer = 3
	self.interaction.water_tap.start_active = false
	self.interaction.water_tap.axis = "y"
	self.interaction.water_manhole = {}
	self.interaction.water_manhole.icon = "develop"
	self.interaction.water_manhole.text_id = "debug_interact_water_tap"
	self.interaction.water_manhole.timer = 3
	self.interaction.water_manhole.start_active = false
	self.interaction.water_manhole.axis = "z"
	self.interaction.water_manhole.interact_distance = 200
	self.interaction.sewer_manhole = {}
	self.interaction.sewer_manhole.icon = "develop"
	self.interaction.sewer_manhole.text_id = "debug_interact_sewer_manhole"
	self.interaction.sewer_manhole.timer = 3
	self.interaction.sewer_manhole.start_active = false
	self.interaction.sewer_manhole.axis = "z"
	self.interaction.sewer_manhole.interact_distance = 200
	self.interaction.sewer_manhole.equipment_text_id = "debug_interact_equipment_crowbar"
	self.interaction.sewer_manhole.special_equipment = "crowbar"
	self.interaction.circuit_breaker = {}
	self.interaction.circuit_breaker.icon = "interaction_powerbox"
	self.interaction.circuit_breaker.text_id = "debug_interact_circuit_breaker"
	self.interaction.circuit_breaker.start_active = false
	self.interaction.circuit_breaker.axis = "z"
	self.interaction.transformer_box = {}
	self.interaction.transformer_box.icon = "interaction_powerbox"
	self.interaction.transformer_box.text_id = "debug_interact_transformer_box"
	self.interaction.transformer_box.start_active = false
	self.interaction.transformer_box.axis = "y"
	self.interaction.transformer_box.timer = 5
	self.interaction.stash_server_cord = {}
	self.interaction.stash_server_cord.icon = "interaction_powercord"
	self.interaction.stash_server_cord.text_id = "debug_interact_stash_server_cord"
	self.interaction.stash_server_cord.start_active = false
	self.interaction.stash_server_cord.axis = "z"
	self.interaction.stash_planks = {}
	self.interaction.stash_planks.icon = "equipment_planks"
	self.interaction.stash_planks.text_id = "debug_interact_stash_planks"
	self.interaction.stash_planks.start_active = false
	self.interaction.stash_planks.timer = 5
	self.interaction.stash_planks.equipment_text_id = "debug_interact_equipment_stash_planks"
	self.interaction.stash_planks.special_equipment = "planks"
	self.interaction.stash_planks.equipment_consume = true
	self.interaction.stash_planks.sound_start = "und_hammer_planks"
	self.interaction.stash_planks.sound_interupt = "und_hammer_planks_cancel"
	self.interaction.stash_planks.sound_done = "und_hammer_planks_finished"
	self.interaction.stash_planks_pickup = {}
	self.interaction.stash_planks_pickup.icon = "equipment_planks"
	self.interaction.stash_planks_pickup.text_id = "debug_interact_stash_planks_pickup"
	self.interaction.stash_planks_pickup.start_active = false
	self.interaction.stash_planks_pickup.timer = 2
	self.interaction.stash_planks_pickup.axis = "z"
	self.interaction.stash_planks_pickup.special_equipment_block = "planks"
	self.interaction.stash_planks_pickup.sound_start = "und_pickup_planks_loop"
	self.interaction.stash_planks_pickup.sound_interupt = "und_pickup_planks_stop"
	self.interaction.stash_planks_pickup.sound_done = "und_pickup_planks_stop"
	self.interaction.stash_server = {}
	self.interaction.stash_server.icon = "equipment_stash_server"
	self.interaction.stash_server.text_id = "debug_interact_stash_server"
	self.interaction.stash_server.timer = 2
	self.interaction.stash_server.start_active = false
	self.interaction.stash_server.axis = "z"
	self.interaction.stash_server.equipment_text_id = "debug_interact_equipment_stash_server"
	self.interaction.stash_server.special_equipment = "server"
	self.interaction.stash_server.equipment_consume = true
	self.interaction.stash_server_pickup = {}
	self.interaction.stash_server_pickup.icon = "equipment_stash_server"
	self.interaction.stash_server_pickup.text_id = "debug_interact_stash_server_pickup"
	self.interaction.stash_server_pickup.timer = 1
	self.interaction.stash_server_pickup.start_active = false
	self.interaction.stash_server_pickup.axis = "z"
	self.interaction.shelf_sliding_suburbia = {}
	self.interaction.shelf_sliding_suburbia.icon = "develop"
	self.interaction.shelf_sliding_suburbia.text_id = "debug_interact_move_bookshelf"
	self.interaction.shelf_sliding_suburbia.start_active = false
	self.interaction.shelf_sliding_suburbia.axis = "y"
	self.interaction.shelf_sliding_suburbia.timer = 3
	self.interaction.tear_painting = {}
	self.interaction.tear_painting.icon = "develop"
	self.interaction.tear_painting.text_id = "debug_interact_tear_painting"
	self.interaction.tear_painting.start_active = false
	self.interaction.tear_painting.axis = "y"
	self.interaction.ejection_seat_interact = {}
	self.interaction.ejection_seat_interact.icon = "equipment_ejection_seat"
	self.interaction.ejection_seat_interact.text_id = "debug_interact_temp_interact_box"
	self.interaction.ejection_seat_interact.timer = 4
	self.interaction.diamond_pickup = {}
	self.interaction.diamond_pickup.icon = "interaction_diamond"
	self.interaction.diamond_pickup.text_id = "debug_interact_diamond"
	self.interaction.diamond_pickup.sound_event = "money_grab"
	self.interaction.diamond_pickup.start_active = false
	self.interaction.patientpaper_pickup = {}
	self.interaction.patientpaper_pickup.icon = "interaction_patientfile"
	self.interaction.patientpaper_pickup.text_id = "debug_interact_patient_paper"
	self.interaction.patientpaper_pickup.timer = 2
	self.interaction.patientpaper_pickup.start_active = false
	self.interaction.diamond_case = {}
	self.interaction.diamond_case.icon = "interaction_diamond"
	self.interaction.diamond_case.text_id = "debug_interact_diamond_case"
	self.interaction.diamond_case.start_active = false
	self.interaction.diamond_case.axis = "x"
	self.interaction.diamond_case.interact_distance = 150
	self.interaction.diamond_single_pickup = {}
	self.interaction.diamond_single_pickup.icon = "interaction_diamond"
	self.interaction.diamond_single_pickup.text_id = "debug_interact_temp_interact_box_press"
	self.interaction.diamond_single_pickup.sound_event = "ammo_bag_drop"
	self.interaction.diamond_single_pickup.start_active = false
	self.interaction.suburbia_necklace_pickup = {}
	self.interaction.suburbia_necklace_pickup.icon = "interaction_diamond"
	self.interaction.suburbia_necklace_pickup.text_id = "debug_interact_temp_interact_box_press"
	self.interaction.suburbia_necklace_pickup.sound_event = "ammo_bag_drop"
	self.interaction.suburbia_necklace_pickup.start_active = false
	self.interaction.suburbia_necklace_pickup.interact_distance = 100
	self.interaction.temp_interact_box2 = {}
	self.interaction.temp_interact_box2.icon = "develop"
	self.interaction.temp_interact_box2.text_id = "debug_interact_temp_interact_box"
	self.interaction.temp_interact_box2.sound_event = "ammo_bag_drop"
	self.interaction.temp_interact_box2.timer = 20
	self.interaction.printing_plates = {}
	self.interaction.printing_plates.icon = "develop"
	self.interaction.printing_plates.text_id = "debug_interact_printing_plates"
	self.interaction.printing_plates.timer = 0.25
	self.interaction.c4 = {}
	self.interaction.c4.icon = "equipment_c4"
	self.interaction.c4.text_id = "debug_interact_c4"
	self.interaction.c4.timer = 4
	self.interaction.c4.sound_start = "bar_c4_apply"
	self.interaction.c4.sound_interupt = "bar_c4_apply_cancel"
	self.interaction.c4.sound_done = "bar_c4_apply_finished"
	self.interaction.c4_diffusible = {}
	self.interaction.c4_diffusible.icon = "equipment_c4"
	self.interaction.c4_diffusible.text_id = "debug_c4_diffusible"
	self.interaction.c4_diffusible.timer = 4
	self.interaction.c4_diffusible.sound_start = "bar_c4_apply"
	self.interaction.c4_diffusible.sound_interupt = "bar_c4_apply_cancel"
	self.interaction.c4_diffusible.sound_done = "bar_c4_apply_finished"
	self.interaction.c4_diffusible.axis = "z"
	self.interaction.open_trunk = {}
	self.interaction.open_trunk.icon = "develop"
	self.interaction.open_trunk.text_id = "debug_interact_open_trunk"
	self.interaction.open_trunk.timer = 0.5
	self.interaction.open_trunk.axis = "x"
	self.interaction.open_door = {}
	self.interaction.open_door.icon = "interaction_open_door"
	self.interaction.open_door.text_id = "debug_interact_open_door"
	self.interaction.open_door.interact_distance = 200
	self.interaction.embassy_door = {}
	self.interaction.embassy_door.start_active = false
	self.interaction.embassy_door.icon = "interaction_open_door"
	self.interaction.embassy_door.text_id = "debug_interact_embassy_door"
	self.interaction.embassy_door.interact_distance = 150
	self.interaction.embassy_door.timer = 5
	self.interaction.c4_special = {}
	self.interaction.c4_special.icon = "equipment_c4"
	self.interaction.c4_special.text_id = "debug_interact_c4"
	self.interaction.c4_special.equipment_text_id = "debug_interact_equipment_c4"
	self.interaction.c4_special.special_equipment = "c4"
	self.interaction.c4_special.equipment_consume = true
	self.interaction.c4_special.timer = 4
	self.interaction.c4_special.sound_start = "bar_c4_apply"
	self.interaction.c4_special.sound_interupt = "bar_c4_apply_cancel"
	self.interaction.c4_special.sound_done = "bar_c4_apply_finished"
	self.interaction.c4_special.axis = "z"
	self.interaction.c4_bag = {}
	self.interaction.c4_bag.icon = "equipment_c4"
	self.interaction.c4_bag.text_id = "debug_interact_c4_bag"
	self.interaction.c4_bag.timer = 2
	self.interaction.c4_bag.contour = "interactable"
	self.interaction.c4_bag.axis = "z"
	self.interaction.c4_bag.sound_start = "bar_bag_generic"
	self.interaction.c4_bag.sound_interupt = "bar_bag_generic_cancel"
	self.interaction.c4_bag.sound_done = "bar_bag_generic_finished"
	self.interaction.money_wrap = {}
	self.interaction.money_wrap.icon = "interaction_money_wrap"
	self.interaction.money_wrap.text_id = "debug_interact_money_wrap_take_money"
	self.interaction.money_wrap.start_active = false
	self.interaction.money_wrap.timer = 3
	self.interaction.suburbia_money_wrap = {}
	self.interaction.suburbia_money_wrap.icon = "interaction_money_wrap"
	self.interaction.suburbia_money_wrap.text_id = "debug_interact_money_printed_take_money"
	self.interaction.suburbia_money_wrap.start_active = false
	self.interaction.suburbia_money_wrap.timer = 3
	self.interaction.money_wrap_single_bundle = {}
	self.interaction.money_wrap_single_bundle.icon = "interaction_money_wrap"
	self.interaction.money_wrap_single_bundle.text_id = "debug_interact_money_wrap_single_bundle_take_money"
	self.interaction.money_wrap_single_bundle.start_active = false
	self.interaction.money_wrap_single_bundle.interact_distance = 175
	self.interaction.christmas_present = {}
	self.interaction.christmas_present.icon = "interaction_christmas_present"
	self.interaction.christmas_present.text_id = "debug_interact_take_christmas_present"
	self.interaction.christmas_present.start_active = true
	self.interaction.christmas_present.interact_distance = 125
	self.interaction.gold_pile = {}
	self.interaction.gold_pile.icon = "interaction_gold"
	self.interaction.gold_pile.text_id = "debug_interact_gold_pile_take_money"
	self.interaction.gold_pile.start_active = false
	self.interaction.gold_pile.timer = 1
	self.interaction.gold_bag = {}
	self.interaction.gold_bag.icon = "interaction_gold"
	self.interaction.gold_bag.text_id = "debug_interact_gold_bag"
	self.interaction.gold_bag.start_active = false
	self.interaction.gold_bag.timer = 1
	self.interaction.gold_bag.special_equipment_block = "gold_bag_equip"
	self.interaction.requires_gold_bag = {}
	self.interaction.requires_gold_bag.icon = "interaction_gold"
	self.interaction.requires_gold_bag.text_id = "debug_interact_requires_gold_bag"
	self.interaction.requires_gold_bag.equipment_text_id = "debug_interact_equipment_requires_gold_bag"
	self.interaction.requires_gold_bag.special_equipment = "gold_bag_equip"
	self.interaction.requires_gold_bag.start_active = true
	self.interaction.requires_gold_bag.equipment_consume = true
	self.interaction.requires_gold_bag.timer = 1
	self.interaction.requires_gold_bag.sound_event = "ammo_bag_drop"
	self.interaction.requires_gold_bag.axis = "x"
	self.interaction.intimidate = {}
	self.interaction.intimidate.icon = "equipment_cable_ties"
	self.interaction.intimidate.text_id = "debug_interact_intimidate"
	self.interaction.intimidate.equipment_text_id = "debug_interact_equipment_cable_tie"
	self.interaction.intimidate.start_active = false
	self.interaction.intimidate.special_equipment = "cable_tie"
	self.interaction.intimidate.equipment_consume = true
	self.interaction.intimidate.no_contour = true
	self.interaction.intimidate.timer = 2
	self.interaction.intimidate_and_search = {}
	self.interaction.intimidate_and_search.icon = "equipment_cable_ties"
	self.interaction.intimidate_and_search.text_id = "debug_interact_intimidate"
	self.interaction.intimidate_and_search.equipment_text_id = "debug_interact_search_key"
	self.interaction.intimidate_and_search.start_active = false
	self.interaction.intimidate_and_search.special_equipment = "cable_tie"
	self.interaction.intimidate_and_search.equipment_consume = true
	self.interaction.intimidate_and_search.dont_need_equipment = true
	self.interaction.intimidate_and_search.no_contour = true
	self.interaction.intimidate_and_search.timer = 3.5
	self.interaction.intimidate_with_contour = deep_clone(self.interaction.intimidate)
	self.interaction.intimidate_with_contour.no_contour = false
	self.interaction.intimidate_and_search_with_contour = deep_clone(self.interaction.intimidate_and_search)
	self.interaction.intimidate_and_search_with_contour.no_contour = false
	self.interaction.computer_test = {}
	self.interaction.computer_test.icon = "develop"
	self.interaction.computer_test.text_id = "debug_interact_computer_test"
	self.interaction.computer_test.start_active = false
	self.gui = {}
	self.gui.BOOT_SCREEN_LAYER = 1
	self.gui.TITLE_SCREEN_LAYER = 1
	self.gui.MENU_LAYER = 200
	self.gui.ATTRACT_SCREEN_LAYER = 400
	self.gui.LOADING_SCREEN_LAYER = 1000
	self.gui.DIALOG_LAYER = 1100
	self.gui.MOUSE_LAYER = 1200
	self.gui.SAVEFILE_LAYER = 1400
	self.overlay_effects = {}
	self.overlay_effects.spectator = {
		blend_mode = "normal",
		sustain = nil,
		fade_in = 3,
		fade_out = 2,
		color = Color(1, 0, 0, 0),
		timer = TimerManager:main(),
		play_paused = true
	}
	self.overlay_effects.level_fade_in = {
		blend_mode = "normal",
		sustain = 1,
		fade_in = 0,
		fade_out = 3,
		color = Color(1, 0, 0, 0),
		timer = TimerManager:main(),
		play_paused = true
	}
	self.overlay_effects.fade_in = {
		blend_mode = "normal",
		sustain = 0,
		fade_in = 0,
		fade_out = 3,
		color = Color(1, 0, 0, 0),
		timer = TimerManager:main(),
		play_paused = true
	}
	self.overlay_effects.fade_out = {
		blend_mode = "normal",
		sustain = 30,
		fade_in = 3,
		fade_out = 0,
		color = Color(1, 0, 0, 0),
		timer = TimerManager:main(),
		play_paused = true
	}
	self.overlay_effects.fade_out_permanent = {
		blend_mode = "normal",
		fade_in = 1,
		fade_out = 0,
		color = Color(1, 0, 0, 0),
		timer = TimerManager:main(),
		play_paused = true
	}
	self.overlay_effects.fade_out_in = {
		blend_mode = "normal",
		sustain = 1,
		fade_in = 1,
		fade_out = 1,
		color = Color(1, 0, 0, 0),
		timer = TimerManager:main(),
		play_paused = true
	}
	self.overlay_effects.element_fade_in = {
		blend_mode = "normal",
		sustain = 0,
		fade_in = 0,
		fade_out = 3,
		color = Color(1, 0, 0, 0),
		timer = TimerManager:main(),
		play_paused = true
	}
	self.overlay_effects.element_fade_out = {
		blend_mode = "normal",
		sustain = 0,
		fade_in = 3,
		fade_out = 0,
		color = Color(1, 0, 0, 0),
		timer = TimerManager:main(),
		play_paused = true
	}
	local d_color = Color(0.75, 1, 1, 1)
	local d_sustain = 0.1
	local d_fade_out = 0.9
	self.overlay_effects.damage = {
		blend_mode = "add",
		sustain = d_sustain,
		fade_in = 0,
		fade_out = d_fade_out,
		color = d_color
	}
	self.overlay_effects.damage_left = {
		blend_mode = "add",
		sustain = d_sustain,
		fade_in = 0,
		fade_out = d_fade_out,
		color = d_color,
		gradient_points = {
			0,
			d_color,
			0.1,
			d_color,
			0.15,
			Color():with_alpha(0),
			1,
			Color():with_alpha(0)
		},
		orientation = "horizontal"
	}
	self.overlay_effects.damage_right = {
		blend_mode = "add",
		sustain = d_sustain,
		fade_in = 0,
		fade_out = d_fade_out,
		color = d_color,
		gradient_points = {
			1,
			d_color,
			0.9,
			d_color,
			0.85,
			Color():with_alpha(0),
			0,
			Color():with_alpha(0)
		},
		orientation = "horizontal"
	}
	self.overlay_effects.damage_up = {
		blend_mode = "add",
		sustain = d_sustain,
		fade_in = 0,
		fade_out = d_fade_out,
		color = d_color,
		gradient_points = {
			0,
			d_color,
			0.1,
			d_color,
			0.15,
			Color():with_alpha(0),
			1,
			Color():with_alpha(0)
		},
		orientation = "vertical"
	}
	self.overlay_effects.damage_down = {
		blend_mode = "add",
		sustain = d_sustain,
		fade_in = 0,
		fade_out = d_fade_out,
		color = d_color,
		gradient_points = {
			1,
			d_color,
			0.9,
			d_color,
			0.85,
			Color():with_alpha(0),
			0,
			Color():with_alpha(0)
		},
		orientation = "vertical"
	}
	self.overlay_effects.maingun_zoomed = {
		blend_mode = "add",
		sustain = 0,
		fade_in = 0,
		fade_out = 0.4,
		color = Color(0.1, 1, 1, 1)
	}
	self.materials = {}
	self.materials[Idstring("concrete"):key()] = "concrete"
	self.materials[Idstring("ceramic"):key()] = "ceramic"
	self.materials[Idstring("marble"):key()] = "marble"
	self.materials[Idstring("flesh"):key()] = "flesh"
	self.materials[Idstring("parket"):key()] = "parket"
	self.materials[Idstring("sheet_metal"):key()] = "sheet_metal"
	self.materials[Idstring("iron"):key()] = "iron"
	self.materials[Idstring("wood"):key()] = "wood"
	self.materials[Idstring("gravel"):key()] = "gravel"
	self.materials[Idstring("cloth"):key()] = "cloth"
	self.materials[Idstring("cloth_no_decal"):key()] = "cloth"
	self.materials[Idstring("cloth_stuffed"):key()] = "cloth_stuffed"
	self.materials[Idstring("dirt"):key()] = "dirt"
	self.materials[Idstring("grass"):key()] = "grass"
	self.materials[Idstring("carpet"):key()] = "carpet"
	self.materials[Idstring("metal"):key()] = "metal"
	self.materials[Idstring("glass_breakable"):key()] = "glass_breakable"
	self.materials[Idstring("glass_unbreakable"):key()] = "glass_unbreakable"
	self.materials[Idstring("glass_no_decal"):key()] = "glass_unbreakable"
	self.materials[Idstring("rubber"):key()] = "rubber"
	self.materials[Idstring("plastic"):key()] = "plastic"
	self.materials[Idstring("asphalt"):key()] = "asphalt"
	self.materials[Idstring("foliage"):key()] = "foliage"
	self.materials[Idstring("stone"):key()] = "stone"
	self.materials[Idstring("sand"):key()] = "sand"
	self.materials[Idstring("thin_layer"):key()] = "thin_layer"
	self.materials[Idstring("no_decal"):key()] = "silent_material"
	self.materials[Idstring("plaster"):key()] = "plaster"
	self.materials[Idstring("no_material"):key()] = "no_material"
	self.materials[Idstring("paper"):key()] = "paper"
	self.materials[Idstring("metal_hollow"):key()] = "metal_hollow"
	self.materials[Idstring("metal_chassis"):key()] = "metal_chassis"
	self.materials[Idstring("metal_catwalk"):key()] = "metal_catwalk"
	self.materials[Idstring("hardwood"):key()] = "hardwood"
	self.materials[Idstring("fence"):key()] = "fence"
	self.materials[Idstring("steel"):key()] = "steel"
	self.materials[Idstring("steel_no_decal"):key()] = "steel"
	self.materials[Idstring("tile"):key()] = "tile"
	self.materials[Idstring("water_deep"):key()] = "water_deep"
	self.materials[Idstring("water_puddle"):key()] = "water_puddle"
	self.materials[Idstring("water_shallow"):key()] = "water_shallow"
	self.materials[Idstring("shield"):key()] = "shield"
	self.screen = {}
	self.screen.fadein_delay = 1
	self.money_manager = {}
	self.money_manager.actions = {}
	self.money_manager.actions.killed_cop = 0
	self.money_manager.actions.revive = 100
	self.money_manager.actions.end_mission_alive = 200
	self.money_manager.actions.take_money = 1000
	self.money_manager.actions.security_camera = 50
	self.money_manager.actions.tie_swat = 51
	self.money_manager.actions.tie_civ = 29
	self.money_manager.actions.money_wrap = 10000
	self.money_manager.actions.money_wrap_single_bundle = 1000
	self.money_manager.actions.objective_completed = 125
	self.money_manager.actions.apartment_completed = 800000
	self.money_manager.actions.bridge_completed = 800000
	self.money_manager.actions.street_completed = 800000
	local multiplier = 10
	for name, money in pairs(self.money_manager.actions) do
		self.money_manager.actions[name] = money * multiplier
	end
	self.money_manager.actions.interact = {}
	self.money_manager.actions.interact[Idstring("units/bank/drill_dummy/drill_dummy"):key()] = 25
	self.money_manager.multipliers = {}
	self.money_manager.multipliers.money_bag1 = 1.1
	self.money_manager.multipliers.money_bag2 = 1.15
	self.money_manager.multipliers.timed_bonus = 2
	self.money_manager.end_multipliers = {}
	self.money_manager.end_multipliers.all_survived = 1.5
	self.money_manager.end_multipliers.time_goal = 1.2
	self.experience_manager = {}
	self.experience_manager.values = {}
	self.experience_manager.values.size02 = 0
	self.experience_manager.values.size03 = 10
	self.experience_manager.values.size04 = 15
	self.experience_manager.values.size06 = 25
	self.experience_manager.values.size08 = 40
	self.experience_manager.values.size10 = 80
	self.experience_manager.values.size12 = 100
	self.experience_manager.values.size14 = 150
	self.experience_manager.values.size16 = 250
	self.experience_manager.values.size18 = 500
	self.experience_manager.values.size20 = 1000
	self.experience_manager.actions = {}
	self.experience_manager.actions.killed_cop = "size02"
	self.experience_manager.actions.revive = "size04"
	self.experience_manager.actions.security_camera = "size04"
	self.experience_manager.actions.tie_swat = "size08"
	self.experience_manager.actions.tie_civ = "size06"
	self.experience_manager.actions.objective_completed = "size02"
	self.experience_manager.actions.secret_assignment = "size16"
	self.experience_manager.actions.money_wrap_single_bundle = "size06"
	self.experience_manager.actions.diamond_single_pickup = "size12"
	self.experience_manager.actions.suburbia_necklace_pickup = "size20"
	self.experience_manager.actions.suburbia_bracelet_pickup = "size18"
	self.experience_manager.actions.diamondheist_vault_bust = "size06"
	self.experience_manager.actions.diamondheist_vault_diamond = "size03"
	self.experience_manager.actions.apartment_completed = "size02"
	self.experience_manager.actions.bridge_completed = "size02"
	self.experience_manager.actions.street_completed = "size02"
	self.experience_manager.actions.diamondheist_big_diamond = "size18"
	self.experience_manager.actions.slaughterhouse_take_gold = "size16"
	self.experience_manager.actions.suburbia_money = "size20"
	self.experience_manager.total_level_objectives = 500
	self.experience_manager.total_criminals_finished = 50
	self.experience_manager.total_objectives_finished = 500
	self.experience_manager.civilians_killed = 50
	local multiplier = 1
	self.experience_manager.levels = {}
	self.experience_manager.levels[1] = {
		points = 1400 * multiplier
	}
	self.experience_manager.levels[2] = {
		points = 1600 * multiplier
	}
	self.experience_manager.levels[3] = {
		points = 1800 * multiplier
	}
	self.experience_manager.levels[4] = {
		points = 2000 * multiplier
	}
	local exp_step_start = 5
	local exp_step_end = 150
	local exp_step = 1 / (exp_step_end - exp_step_start)
	for i = exp_step_start, exp_step_end do
		self.experience_manager.levels[i] = {
			points = math.round(6000 * (exp_step * (i - exp_step_start)) + 2000) * multiplier
		}
	end
	local exp_step_start = 5
	local exp_step_end = 193
	local exp_step = 1 / (exp_step_end - exp_step_start)
	for i = 146, exp_step_end do
		self.experience_manager.levels[i] = {
			points = math.round(22000 * (exp_step * (i - exp_step_start)) - 6000) * multiplier
		}
	end
	self.pickups = {}
	self.pickups.ammo = {
		unit = Idstring("units/pickups/ammo/ammo_pickup")
	}
	self.pickups.bank_manager_key = {
		unit = Idstring("units/pickups/pickup_bank_manager_key/pickup_bank_manager_key")
	}
	self.pickups.chavez_key = {
		unit = Idstring("units/pickups/pickup_chavez_key/pickup_chavez_key")
	}
	self.pickups.drill = {
		unit = Idstring("units/pickups/pickup_drill/pickup_drill")
	}
	self.danger_zones = {
		0.6,
		0.5,
		0.35,
		0.1
	}
	self.contour = {}
	self.contour.character = {}
	self.contour.character.standard_color = Vector3(0.1, 1, 0.5)
	self.contour.character.downed_color = Vector3(1, 0.5, 0)
	self.contour.character.dead_color = Vector3(1, 0.1, 0.1)
	self.contour.character.dangerous_color = Vector3(1, 0.1, 0.1)
	self.contour.character.standard_opacity = 0
	self.contour.character_interactable = {}
	self.contour.character_interactable.standard_color = Vector3(1, 0.5, 0)
	self.contour.character_interactable.selected_color = Vector3(1, 1, 1)
	self.contour.interactable = {}
	self.contour.interactable.standard_color = Vector3(1, 0.5, 0)
	self.contour.interactable.selected_color = Vector3(1, 1, 1)
	self.contour.interactable_look_at = {}
	self.contour.interactable_look_at.standard_color = Vector3(0, 0, 0)
	self.contour.interactable_look_at.selected_color = Vector3(1, 1, 1)
	self.contour.deployable = {}
	self.contour.deployable.standard_color = Vector3(0.1, 1, 0.5)
	self.contour.deployable.selected_color = Vector3(1, 1, 1)
	self.contour.pickup = {}
	self.contour.pickup.standard_color = Vector3(0.1, 1, 0.5)
	self.contour.pickup.selected_color = Vector3(1, 1, 1)
	self.contour.pickup.standard_opacity = 1
	self.music = {}
	self.music.default = {}
	self.music.default.intro = "music_bri_control_01"
	self.music.default.anticipation = "music_bri_anticipation"
	self.music.default.assault = "music_bri_assault"
	self.music.default.fake_assault = "music_bri_assault"
	self.music.default.control = "music_bri_control_02"
	self.music.bank = {}
	self.music.bank.intro = "music_1wb_control_01"
	self.music.bank.anticipation = "music_1wb_anticipation"
	self.music.bank.assault = "music_1wb_assault"
	self.music.bank.fake_assault = "music_1wb_assault"
	self.music.bank.control = "music_1wb_control_02"
	self.music.sla = {}
	self.music.sla.intro = "music_sla_control_01"
	self.music.sla.anticipation = "music_sla_anticipation"
	self.music.sla.assault = "music_sla_assault"
	self.music.sla.fake_assault = "music_sla_assault"
	self.music.sla.control = "music_sla_control_02"
	self.music.bri = {}
	self.music.bri.intro = "music_bri_control_01"
	self.music.bri.anticipation = "music_bri_anticipation"
	self.music.bri.assault = "music_bri_assault"
	self.music.bri.fake_assault = "music_bri_assault"
	self.music.bri.control = "music_bri_control_02"
	self.music.str = {}
	self.music.str.intro = "music_str_control_01"
	self.music.str.anticipation = "music_str_anticipation"
	self.music.str.assault = "music_str_assault"
	self.music.str.fake_assault = "music_str_assault"
	self.music.str.control = "music_str_control_02"
	self.music.apa = {}
	self.music.apa.intro = "music_apa_control_01"
	self.music.apa.anticipation = "music_apa_anticipation"
	self.music.apa.assault = "music_apa_assault"
	self.music.apa.fake_assault = "music_apa_assault"
	self.music.apa.control = "music_apa_control_02"
	self.music.dia = {}
	self.music.dia.intro = "music_dia_control_01"
	self.music.dia.anticipation = "music_dia_anticipation"
	self.music.dia.assault = "music_dia_assault"
	self.music.dia.fake_assault = "music_dia_assault"
	self.music.dia.control = "music_dia_control_02"
	self.music.cft = {}
	self.music.cft.intro = "music_cft_control_01"
	self.music.cft.anticipation = "music_cft_anticipation"
	self.music.cft.assault = "music_cft_assault"
	self.music.cft.fake_assault = "music_cft_assault"
	self.music.cft.control = "music_cft_control_02"
	self.music.und = {}
	self.music.und.intro = "music_und_control_01"
	self.music.und.anticipation = "music_und_anticipation"
	self.music.und.assault = "music_und_assault"
	self.music.und.fake_assault = "music_und_assault"
	self.music.und.control = "music_und_control_02"
	self.music.hos = {}
	self.music.hos.intro = "music_hos_control_01"
	self.music.hos.anticipation = "music_hos_anticipation"
	self.music.hos.assault = "music_hos_assault"
	self.music.hos.fake_assault = "music_hos_jolt"
	self.music.hos.control = "music_hos_control_02"
	self:set_difficulty()
end
function TweakData:_execute_reload_clbks()
	if self._reload_clbks then
		for key, clbk_data in pairs(self._reload_clbks) do
			if clbk_data.func then
				clbk_data.func(clbk_data.clbk_object)
			end
		end
	end
end
function TweakData:add_reload_callback(object, func)
	self._reload_clbks = self._reload_clbks or {}
	table.insert(self._reload_clbks, {clbk_object = object, func = func})
end
function TweakData:remove_reload_callback(object)
	if self._reload_clbks then
		for i, k in ipairs(self._reload_clbks) do
			if k.clbk_object == object then
				table.remove(self._reload_clbks, i)
				return
			end
		end
	end
end
function TweakData:set_scale()
	local lang_key = SystemInfo:language():key()
	local lang_mods = {
		[Idstring("german"):key()] = {
			large = 0.9,
			small = 1,
			sd_large = 0.9,
			sd_small = 0.9,
			sd_menu_border_multiplier = 0.9,
			stats_upgrade_kern = -1,
			level_up_text_kern = -1.5,
			objectives_text_kern = -1,
			menu_logo_multiplier = 0.9,
			kit_desc_large = 0.9,
			sd_w_interact_multiplier = 1.55,
			w_interact_multiplier = 1.65
		}
	}
	lang_mods[Idstring("french"):key()] = {
		large = 0.9,
		small = 1,
		sd_large = 0.9,
		sd_small = 0.95,
		victory_screen_kern = -0.5,
		objectives_text_kern = -0.8,
		level_up_text_kern = -1.5,
		sd_level_up_font_multiplier = 0.9,
		stats_upgrade_kern = -1,
		kit_desc_large = 0.9,
		sd_w_interact_multiplier = 1.3,
		w_interact_multiplier = 1.4,
		subtitle_multiplier = 0.85
	}
	lang_mods[Idstring("italian"):key()] = {
		large = 1,
		small = 1,
		sd_large = 1,
		sd_small = 1,
		objectives_text_kern = -0.8,
		kit_desc_large = 0.9,
		sd_w_interact_multiplier = 1.5,
		w_interact_multiplier = 1.35
	}
	lang_mods[Idstring("spanish"):key()] = {
		large = 1,
		small = 1,
		sd_large = 1,
		sd_small = 0.9,
		sd_menu_border_multiplier = 0.85,
		stats_upgrade_kern = -1,
		upgrade_menu_kern = -1.25,
		level_up_text_kern = -1.5,
		menu_logo_multiplier = 0.9,
		objectives_text_kern = -0.8,
		objectives_desc_text_kern = 0,
		level_up_text_kern = -1.5,
		sd_level_up_font_multiplier = 0.9,
		kit_desc_large = 0.9,
		sd_w_interact_multiplier = 1.5,
		w_interact_multiplier = 1.6,
		server_list_font_multiplier = 0.9,
		victory_title_multiplier = 0.9
	}
	local lang_l_mod = lang_mods[lang_key] and lang_mods[lang_key].large or 1
	local lang_s_mod = lang_mods[lang_key] and lang_mods[lang_key].small or 1
	local lang_lsd_mod = lang_mods[lang_key] and lang_mods[lang_key].sd_large or 1
	local lang_ssd_mod = lang_mods[lang_key] and lang_mods[lang_key].sd_large or 1
	local sd_menu_border_multiplier = lang_mods[lang_key] and lang_mods[lang_key].sd_menu_border_multiplier or 1
	local stats_upgrade_kern = lang_mods[lang_key] and lang_mods[lang_key].stats_upgrade_kern or 0
	local level_up_text_kern = lang_mods[lang_key] and lang_mods[lang_key].level_up_text_kern or 0
	local victory_screen_kern = lang_mods[lang_key] and lang_mods[lang_key].victory_screen_kern
	local upgrade_menu_kern = lang_mods[lang_key] and lang_mods[lang_key].upgrade_menu_kern
	local mugshot_name_kern = lang_mods[lang_key] and lang_mods[lang_key].mugshot_name_kern
	local menu_logo_multiplier = lang_mods[lang_key] and lang_mods[lang_key].menu_logo_multiplier or 1
	local objectives_text_kern = lang_mods[lang_key] and lang_mods[lang_key].objectives_text_kern
	local objectives_desc_text_kern = lang_mods[lang_key] and lang_mods[lang_key].objectives_desc_text_kern
	local kit_desc_large = lang_mods[lang_key] and lang_mods[lang_key].kit_desc_large or 1
	local sd_level_up_font_multiplier = lang_mods[lang_key] and lang_mods[lang_key].sd_level_up_font_multiplier or 1
	local sd_w_interact_multiplier = lang_mods[lang_key] and lang_mods[lang_key].sd_w_interact_multiplier or 1
	local w_interact_multiplier = lang_mods[lang_key] and lang_mods[lang_key].w_interact_multiplier or 1
	local server_list_font_multiplier = lang_mods[lang_key] and lang_mods[lang_key].server_list_font_multiplier or 1
	local victory_title_multiplier = lang_mods[lang_key] and lang_mods[lang_key].victory_title_multiplier
	local subtitle_multiplier = lang_mods[lang_key] and lang_mods[lang_key].subtitle_multiplier or 1
	local res = RenderSettings.resolution
	self.sd_scale = {}
	self.sd_scale.is_sd = true
	self.sd_scale.title_image_multiplier = 0.6
	self.sd_scale.menu_logo_multiplier = 0.575 * menu_logo_multiplier
	self.sd_scale.menu_border_multiplier = 0.6 * sd_menu_border_multiplier
	self.sd_scale.default_font_multiplier = 0.6 * lang_lsd_mod
	self.sd_scale.small_font_multiplier = 0.8 * lang_ssd_mod
	self.sd_scale.lobby_info_font_size_scale_multiplier = 0.65
	self.sd_scale.lobby_name_font_size_scale_multiplier = 0.6
	self.sd_scale.server_list_font_size_multiplier = 0.55
	self.sd_scale.multichoice_arrow_multiplier = 0.7
	self.sd_scale.align_line_padding_multiplier = 0.4
	self.sd_scale.menu_arrow_padding_multiplier = 0.5
	self.sd_scale.briefing_text_h_multiplier = 0.5
	self.sd_scale.experience_bar_multiplier = 0.825
	self.sd_scale.hud_equipment_icon_multiplier = 0.65
	self.sd_scale.hud_default_font_multiplier = 0.7
	self.sd_scale.hud_ammo_clip_multiplier = 0.75
	self.sd_scale.hud_ammo_clip_large_multiplier = 0.5
	self.sd_scale.hud_health_multiplier = 0.75
	self.sd_scale.hud_mugshot_multiplier = 0.75
	self.sd_scale.hud_assault_image_multiplier = 0.5
	self.sd_scale.hud_crosshair_offset_multiplier = 0.75
	self.sd_scale.hud_objectives_pad_multiplier = 0.65
	self.sd_scale.experience_upgrade_multiplier = 0.75
	self.sd_scale.level_up_multiplier = 0.7
	self.sd_scale.next_upgrade_font_multiplier = 0.75
	self.sd_scale.level_up_font_multiplier = 0.51 * sd_level_up_font_multiplier
	self.sd_scale.present_multiplier = 0.75
	self.sd_scale.lobby_info_offset_multiplier = 0.7
	self.sd_scale.info_padding_multiplier = 0.4
	self.sd_scale.loading_challenge_bar_scale = 0.8
	self.sd_scale.kit_menu_bar_scale = 0.65
	self.sd_scale.kit_menu_description_h_scale = 1.22
	self.sd_scale.button_layout_multiplier = 0.7
	self.sd_scale.subtitle_pos_multiplier = 0.7
	self.sd_scale.subtitle_font_multiplier = 0.65
	self.sd_scale.subtitle_lang_multiplier = subtitle_multiplier
	self.sd_scale.default_font_kern = 0
	self.sd_scale.stats_upgrade_kern = stats_upgrade_kern or 0
	self.sd_scale.level_up_text_kern = level_up_text_kern or 0
	self.sd_scale.victory_screen_kern = victory_screen_kern or -0.5
	self.sd_scale.upgrade_menu_kern = upgrade_menu_kern or 0
	self.sd_scale.mugshot_name_kern = mugshot_name_kern or -1
	self.sd_scale.objectives_text_kern = objectives_text_kern or 0
	self.sd_scale.objectives_desc_text_kern = objectives_desc_text_kern or 0
	self.sd_scale.kit_description_multiplier = 0.8 * lang_ssd_mod
	self.sd_scale.chat_multiplier = 0.68
	self.sd_scale.chat_menu_h_multiplier = 0.34
	self.sd_scale.w_interact_multiplier = 0.8 * sd_w_interact_multiplier
	self.sd_scale.victory_title_multiplier = victory_title_multiplier and victory_title_multiplier * 0.95 or 1
	if res and res.y <= 601 then
		self.scale = deep_clone(self.sd_scale)
	else
		self.scale = {}
		self.scale.is_sd = false
		self.scale.title_image_multiplier = 1
		self.scale.menu_logo_multiplier = 1
		self.scale.menu_border_multiplier = 1
		self.scale.default_font_multiplier = 1 * lang_l_mod
		self.scale.small_font_multiplier = 1 * lang_s_mod
		self.scale.lobby_info_font_size_scale_multiplier = 1 * lang_l_mod
		self.scale.lobby_name_font_size_scale_multiplier = 1 * lang_l_mod
		self.scale.server_list_font_size_multiplier = 1 * lang_l_mod * server_list_font_multiplier
		self.scale.multichoice_arrow_multiplier = 1
		self.scale.align_line_padding_multiplier = 1
		self.scale.menu_arrow_padding_multiplier = 1
		self.scale.briefing_text_h_multiplier = 1 * lang_s_mod
		self.scale.experience_bar_multiplier = 1
		self.scale.hud_equipment_icon_multiplier = 1
		self.scale.hud_default_font_multiplier = 1 * lang_l_mod
		self.scale.hud_ammo_clip_multiplier = 1
		self.scale.hud_health_multiplier = 1
		self.scale.hud_mugshot_multiplier = 1
		self.scale.hud_assault_image_multiplier = 1
		self.scale.hud_crosshair_offset_multiplier = 1
		self.scale.hud_objectives_pad_multiplier = 1
		self.scale.experience_upgrade_multiplier = 1
		self.scale.level_up_multiplier = 1
		self.scale.next_upgrade_font_multiplier = 1 * lang_l_mod
		self.scale.level_up_font_multiplier = 1 * lang_l_mod
		self.scale.present_multiplier = 1
		self.scale.lobby_info_offset_multiplier = 1
		self.scale.info_padding_multiplier = 1
		self.scale.loading_challenge_bar_scale = 1
		self.scale.kit_menu_bar_scale = 1
		self.scale.kit_menu_description_h_scale = 1
		self.scale.button_layout_multiplier = 1
		self.scale.subtitle_pos_multiplier = 1
		self.scale.subtitle_font_multiplier = 1 * lang_l_mod
		self.scale.subtitle_lang_multiplier = subtitle_multiplier
		self.scale.default_font_kern = 0
		self.scale.stats_upgrade_kern = stats_upgrade_kern or 0
		self.scale.level_up_text_kern = 0
		self.scale.victory_screen_kern = victory_screen_kern or 0
		self.scale.upgrade_menu_kern = 0
		self.scale.mugshot_name_kern = 0
		self.scale.objectives_text_kern = objectives_text_kern or 0
		self.scale.objectives_desc_text_kern = objectives_desc_text_kern or 0
		self.scale.kit_description_multiplier = 1 * kit_desc_large
		self.scale.chat_multiplier = 1
		self.scale.chat_menu_h_multiplier = 1
		self.scale.w_interact_multiplier = 1 * w_interact_multiplier
		self.scale.victory_title_multiplier = victory_title_multiplier or 1
	end
end
function TweakData:set_menu_scale()
	local lang_mods_def = {
		[Idstring("german"):key()] = {
			topic_font_size = 0.8,
			challenges_font_size = 1,
			upgrades_font_size = 1,
			mission_end_font_size = 1
		},
		[Idstring("french"):key()] = {
			topic_font_size = 1,
			challenges_font_size = 1,
			upgrades_font_size = 1,
			mission_end_font_size = 1
		},
		[Idstring("italian"):key()] = {
			topic_font_size = 1,
			challenges_font_size = 1,
			upgrades_font_size = 1,
			mission_end_font_size = 0.95
		},
		[Idstring("spanish"):key()] = {
			topic_font_size = 0.95,
			challenges_font_size = 0.95,
			upgrades_font_size = 1,
			mission_end_font_size = 1
		}
	}
	if not lang_mods_def[SystemInfo:language():key()] then
		local lang_mods = {
			topic_font_size = 1,
			challenges_font_size = 1,
			upgrades_font_size = 1,
			mission_end_font_size = 1
		}
	end
	local scale_multiplier = self.scale.default_font_multiplier
	local small_scale_multiplier = self.scale.small_font_multiplier
	self.menu.default_font = "fonts/font_univers_530_bold"
	self.menu.default_font_no_outline = "fonts/font_univers_530_bold_no_outline"
	self.menu.default_font_id = Idstring(self.menu.default_font)
	self.menu.default_font_no_outline_id = Idstring(self.menu.default_font_no_outline)
	self.menu.default_font_size = 24 * scale_multiplier
	self.menu.default_font_row_item_color = Color.white
	self.menu.default_hightlight_row_item_color = Color(1, 0, 0, 0)
	self.menu.default_menu_background_color = Color(1, 0.3254902, 0.37254903, 0.39607844)
	self.menu.highlight_background_color_left = Color(1, 1, 0.65882355, 0)
	self.menu.highlight_background_color_right = Color(1, 1, 0.65882355, 0)
	self.menu.default_changeable_text_color = Color(1, 1, 0.65882355, 0)
	self.menu.default_disabled_text_color = Color(1, 0.5, 0.5, 0.5)
	self.menu.arrow_available = Color(1, 1, 0.65882355, 0)
	self.menu.arrow_unavailable = Color(1, 0.5, 0.5, 0.5)
	self.menu.arrow_unavailable = Color(1, 0.5, 0.5, 0.5)
	self.menu.upgrade_locked_color = Color(0.75, 0, 0)
	self.menu.upgrade_not_aquired_color = Color(0.5, 0.5, 0.5)
	self.menu.awarded_challenge_color = self.menu.default_font_row_item_color
	self.menu.dialog_title_font_size = 28 * self.scale.small_font_multiplier
	self.menu.dialog_text_font_size = 24 * self.scale.small_font_multiplier
	self.menu.info_padding = 10 * self.scale.info_padding_multiplier
	self.menu.small_font = "fonts/font_univers_530_medium"
	self.menu.small_font_size = 14 * small_scale_multiplier
	self.menu.topic_font_size = 32 * scale_multiplier * lang_mods.topic_font_size
	self.menu.main_menu_background_color = Color(1, 0, 0, 0)
	self.menu.kit_default_font_size = 24 * scale_multiplier
	self.menu.stats_font_size = 24 * scale_multiplier
	self.menu.customize_controller_size = 21 * scale_multiplier
	self.menu.server_list_font_size = 22 * self.scale.server_list_font_size_multiplier
	self.menu.challenges_font_size = 24 * scale_multiplier * lang_mods.challenges_font_size
	self.menu.upgrades_font_size = 24 * scale_multiplier * lang_mods.upgrades_font_size
	self.menu.multichoice_font_size = 24 * scale_multiplier
	self.menu.mission_end_font_size = 20 * scale_multiplier * lang_mods.mission_end_font_size
	self.menu.sd_mission_end_font_size = 14 * small_scale_multiplier * lang_mods.mission_end_font_size
	self.menu.lobby_info_font_size = 22 * self.scale.lobby_info_font_size_scale_multiplier
	self.menu.lobby_name_font_size = 22 * self.scale.lobby_name_font_size_scale_multiplier
	self.menu.loading_challenge_progress_font_size = 22 * small_scale_multiplier
	self.menu.loading_challenge_name_font_size = 22 * small_scale_multiplier
	self.menu.upper_saferect_border = 64 * self.scale.menu_border_multiplier
	self.menu.border_pad = 8 * self.scale.menu_border_multiplier
	self.menu.kit_description_font_size = 14 * self.scale.kit_description_multiplier
	self.load_level = {}
	self.load_level.briefing_text = {
		h = 192 * self.scale.briefing_text_h_multiplier
	}
	self.load_level.upper_saferect_border = self.menu.upper_saferect_border
	self.load_level.border_pad = self.menu.border_pad
	self.load_level.stonecold_small_logo = "guis/textures/game_small_logo"
end
function TweakData:set_hud_values()
	local lang_mods_def = {
		[Idstring("german"):key()] = {
			hint_font_size = 0.9,
			stats_challenges_font_size = 0.7,
			active_objective_title_font_size = 0.9,
			present_mid_text_font_size = 0.8,
			next_player_font_size = 0.85,
			location_font_size = 1
		},
		[Idstring("french"):key()] = {
			hint_font_size = 0.825,
			stats_challenges_font_size = 1,
			active_objective_title_font_size = 1,
			present_mid_text_font_size = 1,
			next_player_font_size = 0.85,
			location_font_size = 1
		},
		[Idstring("italian"):key()] = {
			hint_font_size = 1,
			stats_challenges_font_size = 1,
			active_objective_title_font_size = 1,
			present_mid_text_font_size = 1,
			next_player_font_size = 0.85,
			location_font_size = 1
		},
		[Idstring("spanish"):key()] = {
			hint_font_size = 1,
			stats_challenges_font_size = 1,
			active_objective_title_font_size = 1,
			present_mid_text_font_size = 1,
			next_player_font_size = 0.85,
			location_font_size = 0.7
		}
	}
	if not lang_mods_def[SystemInfo:language():key()] then
		local lang_mods = {
			hint_font_size = 1,
			stats_challenges_font_size = 1,
			active_objective_title_font_size = 1,
			present_mid_text_font_size = 1,
			next_player_font_size = 1,
			location_font_size = 1
		}
	end
	self.hud.small_font = "fonts/font_univers_530_medium"
	self.hud.small_font_size = 14 * self.scale.small_font_multiplier
	self.hud.location_font_size = 28 * self.scale.hud_default_font_multiplier * lang_mods.location_font_size
	self.hud.assault_title_font_size = 30 * self.scale.hud_default_font_multiplier
	self.hud.default_font_size = 32 * self.scale.hud_default_font_multiplier
	self.hud.present_mid_text_font_size = 32 * self.scale.hud_default_font_multiplier * lang_mods.present_mid_text_font_size
	self.hud.timer_font_size = 40 * self.scale.hud_default_font_multiplier
	self.hud.medium_deafult_font_size = 28 * self.scale.hud_default_font_multiplier
	self.hud.ammo_font_size = 30 * self.scale.hud_default_font_multiplier
	self.hud.weapon_ammo_font_size = 24 * self.scale.hud_default_font_multiplier
	self.hud.name_label_font_size = 24 * self.scale.hud_default_font_multiplier
	self.hud.equipment_font_size = 24 * self.scale.hud_default_font_multiplier
	self.hud.hint_font_size = 28 * self.scale.hud_default_font_multiplier * lang_mods.hint_font_size
	self.hud.active_objective_title_font_size = 24 * self.scale.hud_default_font_multiplier * lang_mods.active_objective_title_font_size
	self.hud.completed_objective_title_font_size = 20 * self.scale.hud_default_font_multiplier
	self.hud.upgrade_awarded_font_size = 26 * self.scale.hud_default_font_multiplier
	self.hud.next_upgrade_font_size = 14 * self.scale.next_upgrade_font_multiplier
	self.hud.level_up_font_size = 32 * self.scale.level_up_font_multiplier
	self.hud.next_player_font_size = 24 * self.scale.hud_default_font_multiplier * lang_mods.next_player_font_size
	self.hud.stats_challenges_font_size = 32 * self.scale.hud_default_font_multiplier * lang_mods.stats_challenges_font_size
	self.hud.chatinput_size = 22 * self.scale.hud_default_font_multiplier
	self.hud.chatoutput_size = 14 * self.scale.small_font_multiplier
	self.hud.prime_color = Color(1, 1, 0.65882355, 0)
end
function TweakData:resolution_changed()
	self:set_scale()
	self:set_menu_scale()
	self:set_hud_values()
end
if (not tweak_data or tweak_data.RELOAD) and managers.dlc then
	local reload = tweak_data and tweak_data.RELOAD
	local reload_clbks = tweak_data and tweak_data._reload_clbks
	tweak_data = TweakData:new()
	tweak_data._reload_clbks = reload_clbks
	if reload then
		tweak_data:_execute_reload_clbks()
	end
end
