CharacterTweakData = CharacterTweakData or class()
function CharacterTweakData:_set_easy()
	self:_multiply_all_hp(0.7, 1.5)
	self:_multiply_weapon_delay(self.presets.weapon.normal, 3)
	self:_multiply_weapon_delay(self.presets.weapon.good, 3)
	self:_multiply_weapon_delay(self.presets.weapon.expert, 3)
	self:_multiply_weapon_delay(self.presets.weapon.sniper, 5)
	self:_multiply_weapon_delay(self.presets.weapon.gang_member, 0.5)
	self.presets.gang_member_damage.REGENERATE_TIME = 1.8
	self.presets.gang_member_damage.REGENERATE_TIME_AWAY = 0.2
end
function CharacterTweakData:_set_normal()
	self:_multiply_all_hp(0.8, 1)
	self:_multiply_weapon_delay(self.presets.weapon.normal, 1)
	self:_multiply_weapon_delay(self.presets.weapon.good, 1)
	self:_multiply_weapon_delay(self.presets.weapon.expert, 1)
	self:_multiply_weapon_delay(self.presets.weapon.sniper, 3)
	self:_multiply_weapon_delay(self.presets.weapon.gang_member, 0.5)
	self.presets.gang_member_damage.REGENERATE_TIME = 2
	self.presets.gang_member_damage.REGENERATE_TIME_AWAY = 0.2
end
function CharacterTweakData:_set_hard()
	self:_multiply_all_hp(1, 1)
	self:_multiply_weapon_delay(self.presets.weapon.normal, 0.6)
	self:_multiply_weapon_delay(self.presets.weapon.good, 0.5)
	self:_multiply_weapon_delay(self.presets.weapon.expert, 0.4)
	self:_multiply_weapon_delay(self.presets.weapon.sniper, 2)
	self:_multiply_weapon_delay(self.presets.weapon.gang_member, 1.5)
	self.presets.gang_member_damage.REGENERATE_TIME = 2
	self.presets.gang_member_damage.REGENERATE_TIME_AWAY = 1
end
function CharacterTweakData:_set_overkill()
	self:_multiply_all_hp(1.5, 1.5)
	self:_multiply_weapon_delay(self.presets.weapon.normal, 0)
	self:_multiply_weapon_delay(self.presets.weapon.good, 0)
	self:_multiply_weapon_delay(self.presets.weapon.expert, 0)
	self:_multiply_weapon_delay(self.presets.weapon.sniper, 0)
	self:_multiply_weapon_delay(self.presets.weapon.gang_member, 2)
	self.presets.gang_member_damage.REGENERATE_TIME = 2.5
	self.presets.gang_member_damage.REGENERATE_TIME_AWAY = 1.4
end
function CharacterTweakData:_set_overkill_145()
	if SystemInfo:platform() == Idstring("PS3") then
		self:_multiply_all_hp(1.7, 1.5)
	else
		self:_multiply_all_hp(2, 1.55)
	end
	self:_multiply_all_speeds(1.05, 1.15)
	self:_multiply_weapon_delay(self.presets.weapon.normal, 0)
	self:_multiply_weapon_delay(self.presets.weapon.good, 0)
	self:_multiply_weapon_delay(self.presets.weapon.expert, 0)
	self:_multiply_weapon_delay(self.presets.weapon.sniper, 0)
	self:_multiply_weapon_delay(self.presets.weapon.gang_member, 2)
	self.presets.gang_member_damage.REGENERATE_TIME = 2.5
	self.presets.gang_member_damage.REGENERATE_TIME_AWAY = 1.4
end
function CharacterTweakData:_multiply_weapon_delay(weap_usage_table, mul)
	for _, weap_id in ipairs(self.weap_ids) do
		local usage_data = weap_usage_table[weap_id]
		if usage_data then
			usage_data.focus_delay = usage_data.focus_delay * mul
		end
	end
end
function CharacterTweakData:_multiply_all_hp(hp_mul, hs_mul)
	self.patrol.HEALTH_INIT = self.patrol.HEALTH_INIT * hp_mul
	self.security.HEALTH_INIT = self.security.HEALTH_INIT * hp_mul
	self.cop.HEALTH_INIT = self.cop.HEALTH_INIT * hp_mul
	self.fbi.HEALTH_INIT = self.fbi.HEALTH_INIT * hp_mul
	self.swat.HEALTH_INIT = self.swat.HEALTH_INIT * hp_mul
	self.heavy_swat.HEALTH_INIT = self.heavy_swat.HEALTH_INIT * hp_mul
	self.sniper.HEALTH_INIT = self.sniper.HEALTH_INIT * hp_mul
	self.gangster.HEALTH_INIT = self.gangster.HEALTH_INIT * hp_mul
	self.dealer.HEALTH_INIT = self.dealer.HEALTH_INIT * hp_mul
	self.tank.HEALTH_INIT = self.tank.HEALTH_INIT * hp_mul
	self.murky.HEALTH_INIT = self.murky.HEALTH_INIT * hp_mul
	self.spooc.HEALTH_INIT = self.spooc.HEALTH_INIT * hp_mul
	self.shield.HEALTH_INIT = self.shield.HEALTH_INIT * hp_mul
	self.taser.HEALTH_INIT = self.taser.HEALTH_INIT * hp_mul
	self.patrol.headshot_dmg_mul = self.patrol.headshot_dmg_mul * hs_mul
	self.security.headshot_dmg_mul = self.security.headshot_dmg_mul * hs_mul
	self.cop.headshot_dmg_mul = self.cop.headshot_dmg_mul * hs_mul
	self.fbi.headshot_dmg_mul = self.fbi.headshot_dmg_mul * hs_mul
	self.swat.headshot_dmg_mul = self.swat.headshot_dmg_mul * hs_mul
	self.heavy_swat.headshot_dmg_mul = self.heavy_swat.headshot_dmg_mul * hs_mul
	self.sniper.headshot_dmg_mul = self.sniper.headshot_dmg_mul * hs_mul
	self.gangster.headshot_dmg_mul = self.gangster.headshot_dmg_mul * hs_mul
	self.dealer.headshot_dmg_mul = self.dealer.headshot_dmg_mul * hs_mul
	self.tank.headshot_dmg_mul = self.tank.headshot_dmg_mul * hs_mul
	self.murky.headshot_dmg_mul = self.murky.headshot_dmg_mul * hs_mul
	self.spooc.headshot_dmg_mul = self.spooc.headshot_dmg_mul * hs_mul
	self.shield.headshot_dmg_mul = self.shield.headshot_dmg_mul * hs_mul
	self.taser.headshot_dmg_mul = self.taser.headshot_dmg_mul * hs_mul
end
function CharacterTweakData:_multiply_all_speeds(walk_mul, run_mul)
	self.patrol.SPEED_WALK = self.patrol.SPEED_WALK * walk_mul
	self.security.SPEED_WALK = self.security.SPEED_WALK * walk_mul
	self.cop.SPEED_WALK = self.cop.SPEED_WALK * walk_mul
	self.fbi.SPEED_WALK = self.fbi.SPEED_WALK * walk_mul
	self.swat.SPEED_WALK = self.swat.SPEED_WALK * walk_mul
	self.heavy_swat.SPEED_WALK = self.heavy_swat.SPEED_WALK * walk_mul
	self.sniper.SPEED_WALK = self.sniper.SPEED_WALK * walk_mul
	self.gangster.SPEED_WALK = self.gangster.SPEED_WALK * walk_mul
	self.dealer.SPEED_WALK = self.dealer.SPEED_WALK * walk_mul
	self.tank.SPEED_WALK = self.tank.SPEED_WALK * walk_mul
	self.murky.SPEED_WALK = self.murky.SPEED_WALK * walk_mul
	self.spooc.SPEED_WALK = self.spooc.SPEED_WALK * walk_mul
	self.shield.SPEED_WALK = self.shield.SPEED_WALK * walk_mul
	self.taser.SPEED_WALK = self.taser.SPEED_WALK * walk_mul
	self.patrol.SPEED_RUN = self.patrol.SPEED_RUN * run_mul
	self.security.SPEED_RUN = self.security.SPEED_RUN * run_mul
	self.cop.SPEED_RUN = self.cop.SPEED_RUN * run_mul
	self.fbi.SPEED_RUN = self.fbi.SPEED_RUN * run_mul
	self.swat.SPEED_RUN = self.swat.SPEED_RUN * run_mul
	self.heavy_swat.SPEED_RUN = self.heavy_swat.SPEED_RUN * run_mul
	self.sniper.SPEED_RUN = self.sniper.SPEED_RUN * run_mul
	self.gangster.SPEED_RUN = self.gangster.SPEED_RUN * run_mul
	self.dealer.SPEED_RUN = self.dealer.SPEED_RUN * run_mul
	self.tank.SPEED_RUN = self.tank.SPEED_RUN * run_mul
	self.murky.SPEED_RUN = self.murky.SPEED_RUN * run_mul
	self.spooc.SPEED_RUN = self.spooc.SPEED_RUN * run_mul
	self.shield.SPEED_RUN = self.shield.SPEED_RUN * run_mul
	self.taser.SPEED_RUN = self.taser.SPEED_RUN * run_mul
end
function CharacterTweakData:init(tweak_data)
	self:_create_table_structure()
	local presets = self:_presets(tweak_data)
	self.presets = presets
	self:_init_patrol(presets)
	self:_init_security(presets)
	self:_init_cop(presets)
	self:_init_fbi(presets)
	self:_init_swat(presets)
	self:_init_heavy_swat(presets)
	self:_init_sniper(presets)
	self:_init_gangster(presets)
	self:_init_dealer(presets)
	self:_init_tank(presets)
	self:_init_murky(presets)
	self:_init_spooc(presets)
	self:_init_shield(presets)
	self:_init_taser(presets)
	self:_init_civilian(presets)
	self:_init_bank_manager(presets)
	self:_init_escort(presets)
	self:_init_escort_suitcase(presets)
	self:_init_escort_prisoner(presets)
	self:_init_escort_ralph(presets)
	self:_init_escort_cfo(presets)
	self:_init_escort_undercover(presets)
	self:_init_russian(presets)
	self:_init_german(presets)
	self:_init_spanish(presets)
	self:_init_american(presets)
end
function CharacterTweakData:_init_patrol(presets)
	self.patrol = deep_clone(presets.base)
	self.patrol.experience = {}
	self.patrol.weapon = presets.weapon.normal
	self.patrol.detection = presets.detection.patrol
	self.patrol.HEALTH_INIT = 2
	self.patrol.SPEED_WALK = 100
	self.patrol.SPEED_RUN = 300
	self.patrol.surrender_hard = nil
	self.patrol.crouch_move = nil
	self.patrol.submission_max = {50, 100}
	self.patrol.submission_intimidate = 45
	self.patrol.weapon_range = 1000
	self.patrol.weapon_voice = "3"
	self.patrol.experience.cable_tie = "tie_swat"
	self.patrol.speech_prefix = "po"
	self.patrol.speech_prefix_count = 4
	self.patrol.access = "security_patrol"
	self.patrol.use_smoke = false
	self.patrol.rescue_hostages = false
	self.patrol.use_radio = "dia_guard_radio"
	self.patrol.silent_priority_shout = "Dia_10"
	self.patrol.dodge = presets.dodge.poor
	self.patrol.chatter = presets.enemy_chatter.cop
end
function CharacterTweakData:_init_security(presets)
	self.security = deep_clone(presets.base)
	self.security.experience = {}
	self.security.weapon = presets.weapon.normal
	self.security.detection = presets.detection.guard
	self.security.HEALTH_INIT = 2
	self.security.SPEED_WALK = 100
	self.security.SPEED_RUN = 300
	self.security.surrender_easy = true
	self.security.crouch_move = nil
	self.security.submission_max = {50, 100}
	self.security.submission_intimidate = 45
	self.security.weapon_range = 1000
	self.security.weapon_voice = "3"
	self.security.experience.cable_tie = "tie_swat"
	self.security.speech_prefix = "po"
	self.security.speech_prefix_count = 4
	self.security.access = "security"
	self.security.use_smoke = false
	self.security.rescue_hostages = false
	self.security.use_radio = nil
	self.security.silent_priority_shout = "Dia_10"
	self.security.dodge = presets.dodge.poor
	self.security.deathguard = true
	self.security.chatter = presets.enemy_chatter.cop
end
function CharacterTweakData:_init_cop(presets)
	self.cop = deep_clone(presets.base)
	self.cop.experience = {}
	self.cop.weapon = presets.weapon.normal
	self.cop.detection = presets.detection.normal
	self.cop.HEALTH_INIT = 2
	self.cop.SPEED_WALK = 175
	self.cop.SPEED_RUN = 300
	self.cop.submission_max = {50, 80}
	self.cop.submission_intimidate = 30
	self.cop.weapon_range = 1000
	self.cop.weapon_voice = "1"
	self.cop.experience.cable_tie = "tie_swat"
	self.cop.speech_prefix = "po"
	self.cop.speech_prefix_count = 4
	self.cop.access = "cop"
	self.cop.use_smoke = false
	self.cop.dodge = presets.dodge.normal
	self.cop.follower = true
	self.cop.deathguard = true
	self.cop.no_disarm = true
	self.cop.no_arrest = true
	self.cop.chatter = presets.enemy_chatter.cop
end
function CharacterTweakData:_init_fbi(presets)
	self.fbi = deep_clone(presets.base)
	self.fbi.experience = {}
	self.fbi.weapon = presets.weapon.good
	self.fbi.detection = presets.detection.normal
	self.fbi.HEALTH_INIT = 3
	self.fbi.SPEED_WALK = 100
	self.fbi.SPEED_RUN = 350
	self.fbi.submission_max = {45, 60}
	self.fbi.submission_intimidate = 15
	self.fbi.weapon_range = 1000
	self.fbi.weapon_voice = "2"
	self.fbi.experience.cable_tie = "tie_swat"
	self.fbi.speech_prefix = "po"
	self.fbi.speech_prefix_count = 4
	self.fbi.access = "fbi"
	self.fbi.dodge = presets.dodge.good
	self.fbi.follower = true
	self.fbi.deathguard = true
	self.fbi.no_disarm = true
	self.fbi.no_arrest = true
	self.fbi.chatter = presets.enemy_chatter.cop
end
function CharacterTweakData:_init_swat(presets)
	self.swat = deep_clone(presets.base)
	self.swat.experience = {}
	self.swat.weapon = presets.weapon.good
	self.swat.detection = presets.detection.normal
	self.swat.HEALTH_INIT = 3
	self.swat.SPEED_WALK = 100
	self.swat.SPEED_RUN = 350
	self.swat.submission_max = {45, 60}
	self.swat.submission_intimidate = 15
	self.swat.weapon_range = 1000
	self.swat.weapon_voice = "2"
	self.swat.experience.cable_tie = "tie_swat"
	self.swat.speech_prefix = "sw"
	self.swat.speech_prefix_count = 4
	self.swat.access = "swat"
	self.swat.dodge = presets.dodge.good
	self.swat.follower = true
	self.swat.no_disarm = true
	self.swat.no_arrest = true
	self.swat.chatter = presets.enemy_chatter.swat
end
function CharacterTweakData:_init_heavy_swat(presets)
	self.heavy_swat = deep_clone(presets.base)
	self.heavy_swat.experience = {}
	self.heavy_swat.weapon = presets.weapon.good
	self.heavy_swat.detection = presets.detection.normal
	self.heavy_swat.HEALTH_INIT = 7
	self.heavy_swat.headshot_dmg_mul = 1.5
	self.heavy_swat.SPEED_WALK = 100
	self.heavy_swat.SPEED_RUN = 350
	self.heavy_swat.submission_max = {45, 60}
	self.heavy_swat.submission_intimidate = 15
	self.heavy_swat.weapon_range = 1000
	self.heavy_swat.weapon_voice = "2"
	self.heavy_swat.experience.cable_tie = "tie_swat"
	self.heavy_swat.speech_prefix = "sw"
	self.heavy_swat.speech_prefix_count = 4
	self.heavy_swat.access = "swat"
	self.heavy_swat.dodge = presets.dodge.expert
	self.heavy_swat.follower = true
	self.heavy_swat.no_disarm = true
	self.heavy_swat.no_arrest = true
	self.heavy_swat.chatter = presets.enemy_chatter.swat
end
function CharacterTweakData:_init_murky(presets)
	self.murky = deep_clone(presets.base)
	self.murky.experience = {}
	self.murky.weapon = presets.weapon.expert
	self.murky.detection = presets.detection.normal
	self.murky.HEALTH_INIT = 8
	self.murky.headshot_dmg_mul = 5
	self.murky.surrender_easy = true
	self.murky.SPEED_WALK = 100
	self.murky.SPEED_RUN = 350
	self.murky.submission_max = {45, 60}
	self.murky.submission_intimidate = 15
	self.murky.weapon_range = 1000
	self.murky.weapon_voice = "2"
	self.murky.experience.cable_tie = "tie_swat"
	self.murky.speech_prefix = "sw"
	self.murky.speech_prefix_count = 4
	self.murky.access = "murky"
	self.murky.use_smoke = false
	self.murky.rescue_hostages = false
	self.murky.use_radio = nil
	self.murky.dodge = presets.dodge.expert
	self.murky.no_disarm = true
	self.murky.no_arrest = true
	self.murky.chatter = presets.enemy_chatter.swat
end
function CharacterTweakData:_init_sniper(presets)
	self.sniper = deep_clone(presets.base)
	self.sniper.experience = {}
	self.sniper.weapon = presets.weapon.sniper
	self.sniper.detection = presets.detection.sniper
	self.sniper.HEALTH_INIT = 2
	self.sniper.SPEED_WALK = 100
	self.sniper.SPEED_RUN = 350
	self.sniper.shooting_death = false
	self.sniper.submission_max = {45, 60}
	self.sniper.submission_intimidate = 15
	self.sniper.weapon_range = 100000
	self.sniper.weapon_voice = "1"
	self.sniper.experience.cable_tie = "tie_swat"
	self.sniper.speech_prefix = "sw"
	self.sniper.speech_prefix_count = 4
	self.sniper.access = "sniper"
	self.sniper.no_retreat = true
	self.sniper.no_disarm = true
	self.sniper.no_arrest = true
	self.sniper.chatter = presets.enemy_chatter.no_chatter
end
function CharacterTweakData:_init_gangster(presets)
	self.gangster = deep_clone(presets.base)
	self.gangster.experience = {}
	self.gangster.weapon = presets.weapon.good
	self.gangster.detection = presets.detection.sniper
	self.gangster.HEALTH_INIT = 2
	self.gangster.SPEED_WALK = 100
	self.gangster.SPEED_RUN = 300
	self.gangster.surrender_hard = nil
	self.gangster.suspicious = nil
	self.gangster.no_disarm = true
	self.gangster.no_arrest = true
	self.gangster.no_retreat = true
	self.gangster.weapon_range = 1000
	self.gangster.weapon_voice = "3"
	self.gangster.experience.cable_tie = "tie_swat"
	self.gangster.speech_prefix = "th"
	self.gangster.speech_prefix_count = 3
	self.gangster.access = "gangster"
	self.gangster.use_smoke = false
	self.gangster.rescue_hostages = false
	self.gangster.use_radio = nil
	self.gangster.dodge = presets.dodge.normal
	self.gangster.challenges = {type = "gangster"}
	self.gangster.chatter = presets.enemy_chatter.no_chatter
end
function CharacterTweakData:_init_dealer(presets)
	self.dealer = deep_clone(presets.base)
	self.dealer.experience = {}
	self.dealer.weapon = presets.weapon.good
	self.dealer.detection = presets.detection.guard
	self.dealer.HEALTH_INIT = 2
	self.dealer.SPEED_WALK = 200
	self.dealer.SPEED_RUN = 350
	self.dealer.suspicious = nil
	self.dealer.surrender_hard = nil
	self.dealer.no_disarm = true
	self.dealer.no_arrest = true
	self.dealer.no_retreat = true
	self.dealer.weapon_range = 1000
	self.dealer.weapon_voice = "3"
	self.dealer.experience.cable_tie = "tie_swat"
	self.dealer.speech_prefix = "th"
	self.dealer.speech_prefix_count = 3
	self.dealer.access = "gangster"
	self.dealer.use_smoke = false
	self.dealer.rescue_hostages = false
	self.dealer.use_radio = nil
	self.dealer.dodge = presets.dodge.normal
	self.dealer.challenges = {type = "gangster"}
	self.dealer.chatter = "gangster"
end
function CharacterTweakData:_init_tank(presets)
	self.tank = deep_clone(presets.base)
	self.tank.experience = {}
	self.tank.weapon = deep_clone(presets.weapon.expert)
	if SystemInfo:platform() == Idstring("PS3") then
		self.tank.weapon.r870.FALLOFF[1].dmg_mul = 2
		self.tank.weapon.r870.FALLOFF[2].dmg_mul = 1.5
		self.tank.weapon.r870.FALLOFF[3].dmg_mul = 0.75
	else
		self.tank.weapon.r870.FALLOFF[1].dmg_mul = 6
		self.tank.weapon.r870.FALLOFF[2].dmg_mul = 4
		self.tank.weapon.r870.FALLOFF[3].dmg_mul = 2
	end
	self.tank.weapon.r870.hit_chance = {
		near = {0.9, 1},
		far = {0.5, 0.5}
	}
	self.tank.detection = presets.detection.normal
	if SystemInfo:platform() == Idstring("PS3") then
		self.tank.HEALTH_INIT = 100
	else
		self.tank.HEALTH_INIT = 100
	end
	self.tank.headshot_dmg_mul = 2
	self.tank.SPEED_WALK = 100
	self.tank.SPEED_RUN = 350
	self.tank.SPEED_SPRINT = 500
	self.tank.crouch_move = false
	self.tank.allow_crouch = false
	self.tank.surrender_hard = nil
	self.tank.no_retreat = true
	self.tank.no_disarm = true
	self.tank.no_arrest = true
	self.tank.weapon_range = 1000
	self.tank.weapon_voice = "3"
	self.tank.experience.cable_tie = "tie_swat"
	self.tank.access = "tank"
	self.tank.speech_prefix = "bdz"
	self.tank.speech_prefix_count = nil
	self.tank.priority_shout = "f30"
	self.tank.rescue_hostages = false
	self.tank.leader = {max_nr_followers = 4}
	self.tank.damage.hurt_severity = {
		0,
		1,
		1,
		1
	}
	self.tank.chatter = presets.enemy_chatter.no_chatter
	self.tank.announce_incomming = "incomming_tank"
end
function CharacterTweakData:_init_spooc(presets)
	self.spooc = deep_clone(presets.base)
	self.spooc.experience = {}
	self.spooc.weapon = deep_clone(presets.weapon.expert)
	self.spooc.detection = presets.detection.normal
	self.spooc.HEALTH_INIT = 15
	self.spooc.headshot_dmg_mul = 1.5
	self.spooc.SPEED_WALK = 100
	self.spooc.SPEED_RUN = 440
	self.spooc.SPEED_SPRINT = 500
	self.spooc.surrender_hard = nil
	self.spooc.no_retreat = true
	self.spooc.no_arrest = true
	self.spooc.no_disarm = true
	self.spooc.submission_max = {45, 60}
	self.spooc.submission_intimidate = 15
	self.spooc.weapon_range = 1000
	self.spooc.priority_shout = "f33"
	self.spooc.rescue_hostages = false
	self.spooc.weapon.beretta92.choice_chance = 0
	self.spooc.weapon.m4.choice_chance = 1
	self.spooc.weapon.r870.choice_chance = 0
	self.spooc.weapon.mp5.choice_chance = 1
	self.spooc.weapon_voice = "3"
	self.spooc.experience.cable_tie = "tie_swat"
	self.spooc.speech_prefix = "clk"
	self.spooc.speech_prefix_count = nil
	self.spooc.access = "spooc"
	self.spooc.dodge = presets.dodge.ninja
	self.spooc.follower = true
	self.spooc.chatter = presets.enemy_chatter.no_chatter
	self.spooc.announce_incomming = "incomming_spooc"
end
function CharacterTweakData:_init_shield(presets)
	self.shield = deep_clone(presets.base)
	self.shield.experience = {}
	self.shield.weapon = deep_clone(presets.weapon.expert)
	self.shield.detection = presets.detection.normal
	self.shield.HEALTH_INIT = 10
	self.shield.headshot_dmg_mul = 1.5
	self.shield.SPEED_WALK = 100
	self.shield.SPEED_RUN = 400
	self.shield.surrender_hard = nil
	self.shield.no_retreat = true
	self.shield.no_stand = true
	self.shield.no_disarm = true
	self.shield.no_arrest = true
	self.shield.weapon_range = 1000
	self.shield.priority_shout = "f31"
	self.shield.rescue_hostages = false
	self.shield.leader = {max_nr_followers = 4}
	self.shield.deathguard = true
	self.shield.damage.hurt_severity = {
		0,
		1,
		1,
		1
	}
	self.shield.weapon.shield = {}
	self.shield.weapon.shield.choice_chance = 1
	self.shield.weapon.shield.aim_delay = {0, 0.3}
	self.shield.weapon.shield.focus_delay = 6
	self.shield.weapon.shield.focus_dis = 250
	self.shield.weapon.shield.spread = 60
	self.shield.weapon.shield.miss_dis = 15
	self.shield.weapon.shield.hit_chance = {
		near = {0.1, 0.6},
		far = {0.1, 0.25}
	}
	self.shield.weapon.shield.RELOAD_SPEED = 2
	self.shield.weapon.shield.FALLOFF = {
		{
			r = 0,
			dmg_mul = 4,
			recoil = {0.35, 0.55},
			mode = {
				0.2,
				2,
				4,
				10
			}
		},
		{
			r = 700,
			dmg_mul = 1,
			recoil = {0.35, 0.55},
			mode = {
				0.2,
				2,
				4,
				10
			}
		},
		{
			r = 1000,
			dmg_mul = 1,
			recoil = {0.35, 0.55},
			mode = {
				0.2,
				2,
				4,
				10
			}
		},
		{
			r = 2000,
			dmg_mul = 1,
			recoil = {0.35, 0.55},
			mode = {
				2,
				5,
				6,
				4
			}
		},
		{
			r = 10000,
			dmg_mul = 1,
			recoil = {0.35, 0.55},
			mode = {
				6,
				4,
				2,
				1
			}
		}
	}
	self:_process_weapon_usage_table(self.shield.weapon)
	self.shield.weapon_voice = "3"
	self.shield.experience.cable_tie = "tie_swat"
	self.shield.speech_prefix = "sw"
	self.shield.speech_prefix_count = 4
	self.shield.access = "shield"
	self.shield.chatter = presets.enemy_chatter.shield
	self.shield.announce_incomming = "incomming_shield"
end
function CharacterTweakData:_init_taser(presets)
	self.taser = deep_clone(presets.base)
	self.taser.damage.hurt_severity = {
		0,
		0,
		0.2,
		0.3
	}
	self.taser.experience = {}
	self.taser.weapon = deep_clone(presets.weapon.expert)
	self.taser.weapon.m4.tase_distance = 1400
	self.taser.weapon.m4.aim_delay_tase = {0, 0.5}
	self.taser.detection = presets.detection.normal
	self.taser.HEALTH_INIT = 20
	self.taser.headshot_dmg_mul = 1.5
	self.taser.SPEED_WALK = 100
	self.taser.SPEED_RUN = 350
	self.taser.surrender_hard = nil
	self.taser.no_retreat = true
	self.taser.no_disarm = true
	self.taser.no_arrest = true
	self.taser.submission_max = {45, 60}
	self.taser.submission_intimidate = 15
	self.taser.weapon_range = 1000
	self.taser.weapon_voice = "3"
	self.taser.experience.cable_tie = "tie_swat"
	self.taser.speech_prefix = "tsr"
	self.taser.speech_prefix_count = nil
	self.taser.access = "taser"
	self.taser.priority_shout = "f32"
	self.taser.rescue_hostages = false
	self.taser.follower = true
	self.taser.chatter = presets.enemy_chatter.no_chatter
	self.taser.announce_incomming = "incomming_taser"
end
function CharacterTweakData:_init_civilian(presets)
	self.civilian = {
		experience = {}
	}
	self.civilian.HEALTH_INIT = 0.9
	self.civilian.SPEED_WALK = 150
	self.civilian.SPEED_RUN = 400
	self.civilian.flee_type = "escape"
	self.civilian.scare_max = {10, 20}
	self.civilian.scare_shot = 1
	self.civilian.scare_intimidate = -2
	self.civilian.submission_max = {60, 120}
	self.civilian.submission_intimidate = 60
	self.civilian.damage = {
		hurt_severity = {
			0,
			0.2,
			0.5,
			0.75
		}
	}
	self.civilian.experience.cable_tie = "tie_civ"
	self.civilian.speech_prefix = "cm"
	self.civilian.speech_prefix_count = 2
	self.civilian.access = "civ_male"
	self.civilian.intimidateable = true
	self.civilian.challenges = {type = "civilians"}
	self.civilian_female = deep_clone(self.civilian)
	self.civilian_female.speech_prefix = "cf"
	self.civilian_female.speech_prefix_count = 5
	self.civilian_female.female = true
	self.civilian_female.access = "civ_female"
	self.civilian_female.no_run_death_anim = true
end
function CharacterTweakData:_init_bank_manager(presets)
	self.bank_manager = {
		experience = {},
		escort = {}
	}
	self.bank_manager.HEALTH_INIT = self.civilian.HEALTH_INIT
	self.bank_manager.SPEED_WALK = self.civilian.SPEED_WALK
	self.bank_manager.SPEED_RUN = self.civilian.SPEED_RUN
	self.bank_manager.flee_type = "hide"
	self.bank_manager.scare_max = {10, 20}
	self.bank_manager.scare_shot = 1
	self.bank_manager.scare_intimidate = -2
	self.bank_manager.submission_max = {60, 120}
	self.bank_manager.submission_intimidate = 60
	self.bank_manager.damage = {
		hurt_severity = {
			0,
			0.2,
			0.5,
			0.75
		}
	}
	self.bank_manager.experience.cable_tie = "tie_civ"
	self.bank_manager.speech_prefix = "cm"
	self.bank_manager.speech_prefix_count = 2
	self.bank_manager.escort.scared_duration = 45
	self.bank_manager.escort.shot_scare = 25
	self.bank_manager.escort.yell_scare = -25
	self.bank_manager.escort.yell_timeout = 2
	self.bank_manager.access = "civ_male"
	self.bank_manager.intimidateable = true
	self.bank_manager.challenges = {type = "civilians"}
	self.bank_manager.outline_on_discover = true
end
function CharacterTweakData:_init_escort(presets)
	self.escort = {
		experience = {},
		escort = {}
	}
	self.escort.HEALTH_INIT = self.civilian.HEALTH_INIT
	self.escort.permanently_invulnerable = true
	self.escort.SPEED_WALK = self.civilian.SPEED_WALK
	self.escort.SPEED_RUN = self.civilian.SPEED_RUN
	self.escort.flee_type = "hide"
	self.escort.scare_max = {10, 20}
	self.escort.scare_shot = 1
	self.escort.scare_intimidate = -3
	self.escort.submission_max = {60, 120}
	self.escort.submission_intimidate = 60
	self.escort.damage = {
		hurt_severity = {
			0,
			0.2,
			0.5,
			0.75
		}
	}
	self.escort.experience.cable_tie = "tie_civ"
	self.escort.speech_prefix = "cm"
	self.escort.speech_prefix_count = 2
	self.escort.is_escort = true
	self.escort.escort.scared_duration = 15
	self.escort.escort.shot_scare = 3
	self.escort.escort.yell_scare = -100
	self.escort.escort.yell_timeout = 0
	self.escort.access = "SO_ID1"
	self.escort.intimidateable = false
	self.escort.escort_idle_talk = true
	self.escort.escort_scared_dist = 600
end
function CharacterTweakData:_init_escort_suitcase(presets)
	self.escort_suitcase = deep_clone(self.escort)
	self.escort_suitcase.SPEED_RUN = 170
	self.escort_suitcase.speech_prefix = "mtt"
	self.escort_suitcase.speech_prefix_count = nil
end
function CharacterTweakData:_init_escort_prisoner(presets)
	self.escort_prisoner = deep_clone(self.escort)
	self.escort_prisoner.SPEED_RUN = 320
	self.escort_prisoner.speech_prefix = "chi"
	self.escort_prisoner.speech_prefix_count = nil
end
function CharacterTweakData:_init_escort_ralph(presets)
	self.escort_ralph = deep_clone(self.escort)
	self.escort_ralph.speech_prefix = "rph"
	self.escort_ralph.speech_prefix_count = nil
end
function CharacterTweakData:_init_escort_cfo(presets)
	self.escort_cfo = deep_clone(self.escort)
	self.escort_cfo.speech_prefix = "cfo"
	self.escort_cfo.speech_prefix_count = nil
	self.escort_cfo.access = "SO_ID2"
end
function CharacterTweakData:_init_escort_undercover(presets)
	self.escort_undercover = deep_clone(self.escort)
	self.escort_undercover.speech_prefix = "crs"
	self.escort_undercover.speech_prefix_count = nil
	self.escort_undercover.access = "SO_ID2"
	self.escort_undercover.escort_idle_talk = false
	self.escort_undercover.SPEED_RUN = 170
	self.escort_undercover.escort_scared_dist = 200
end
function CharacterTweakData:_init_russian(presets)
	self.russian = {}
	self.russian.damage = presets.gang_member_damage
	self.russian.weapon = presets.weapon.gang_member
	self.russian.detection = presets.detection.gang_member
	self.russian.SPEED_WALK = 205
	self.russian.SPEED_RUN = 325
	self.russian.crouch_move = false
	self.russian.speech_prefix = "rb2"
	self.russian.speech_prefix_count = nil
	self.russian.weapon_voice = "1"
	self.russian.access = "teamAI1"
end
function CharacterTweakData:_init_german(presets)
	self.german = {}
	self.german.damage = presets.gang_member_damage
	self.german.weapon = presets.weapon.gang_member
	self.german.detection = presets.detection.gang_member
	self.german.SPEED_WALK = 200
	self.german.SPEED_RUN = 335
	self.german.crouch_move = false
	self.german.speech_prefix = "rb2"
	self.german.speech_prefix_count = nil
	self.german.weapon_voice = "2"
	self.german.access = "teamAI2"
end
function CharacterTweakData:_init_spanish(presets)
	self.spanish = {}
	self.spanish.damage = presets.gang_member_damage
	self.spanish.weapon = presets.weapon.gang_member
	self.spanish.detection = presets.detection.gang_member
	self.spanish.SPEED_WALK = 210
	self.spanish.SPEED_RUN = 330
	self.spanish.crouch_move = false
	self.spanish.speech_prefix = "rb2"
	self.spanish.speech_prefix_count = nil
	self.spanish.weapon_voice = "3"
	self.spanish.access = "teamAI3"
end
function CharacterTweakData:_init_american(presets)
	self.american = {}
	self.american.damage = presets.gang_member_damage
	self.american.weapon = presets.weapon.gang_member
	self.american.detection = presets.detection.gang_member
	self.american.SPEED_WALK = 215
	self.american.SPEED_RUN = 340
	self.american.crouch_move = false
	self.american.speech_prefix = "rb2"
	self.american.speech_prefix_count = nil
	self.american.weapon_voice = "3"
	self.american.access = "teamAI4"
end
function CharacterTweakData:_presets(tweak_data)
	local presets = {}
	presets.base = {}
	presets.base.HEALTH_INIT = 2
	presets.base.headshot_dmg_mul = 2
	presets.base.SPEED_WALK = 130
	presets.base.SPEED_RUN = 370
	presets.base.crouch_move = true
	presets.base.allow_crouch = true
	presets.base.shooting_death = true
	presets.base.surrender_hard = true
	presets.base.suspicious = true
	presets.base.submission_max = {45, 60}
	presets.base.submission_intimidate = 15
	presets.base.weapon_range = 1400
	presets.base.speech_prefix = "po"
	presets.base.speech_prefix_count = 1
	presets.base.use_smoke = true
	presets.base.rescue_hostages = true
	presets.base.use_radio = "dispatch_generic_message"
	presets.base.dodge = nil
	presets.base.challenges = {type = "law"}
	presets.base.experience = {}
	presets.base.experience.cable_tie = "tie_swat"
	presets.base.damage = {}
	presets.base.damage.hurt_severity = {
		0,
		0.2,
		0.5,
		0.75
	}
	presets.base.damage.death_severity = 0.5
	presets.gang_member_damage = {}
	presets.gang_member_damage.HEALTH_INIT = 75
	presets.gang_member_damage.REGENERATE_TIME = 2
	presets.gang_member_damage.REGENERATE_TIME_AWAY = 0.2
	presets.gang_member_damage.DOWNED_TIME = tweak_data.player.damage.DOWNED_TIME
	presets.gang_member_damage.TASED_TIME = tweak_data.player.damage.TASED_TIME
	presets.gang_member_damage.BLEED_OUT_HEALTH_INIT = tweak_data.player.damage.BLEED_OUT_HEALTH_INIT
	presets.gang_member_damage.ARRESTED_TIME = tweak_data.player.damage.ARRESTED_TIME
	presets.gang_member_damage.INCAPACITATED_TIME = tweak_data.player.damage.INCAPACITATED_TIME
	presets.gang_member_damage.hurt_severity = {
		0.1,
		0.12,
		0.14,
		0.16
	}
	presets.gang_member_damage.MIN_DAMAGE_INTERVAL = 0
	presets.gang_member_damage.respawn_time_penalty = 0
	presets.gang_member_damage.base_respawn_time_penalty = 5
	presets.weapon = {}
	presets.weapon.normal = {
		beretta92 = {},
		c45 = {},
		m4 = {},
		r870 = {},
		mp5 = {},
		mac11 = {}
	}
	presets.weapon.normal.beretta92.aim_delay = {0, 0.2}
	presets.weapon.normal.beretta92.focus_delay = 1
	presets.weapon.normal.beretta92.focus_dis = 2000
	presets.weapon.normal.beretta92.spread = 25
	presets.weapon.normal.beretta92.miss_dis = 20
	presets.weapon.normal.beretta92.hit_chance = {
		near = {0.1, 0.6},
		far = {0, 0.1}
	}
	presets.weapon.normal.beretta92.RELOAD_SPEED = 1.5
	presets.weapon.normal.beretta92.FALLOFF = {
		{
			r = 0,
			dmg_mul = 4,
			recoil = {0.25, 0.35},
			mode = {
				2,
				1,
				0,
				0
			}
		},
		{
			r = 700,
			dmg_mul = 1,
			recoil = {0.25, 0.35},
			mode = {
				2,
				1,
				0,
				0
			}
		},
		{
			r = 3000,
			dmg_mul = 1,
			recoil = {0.25, 0.35},
			mode = {
				2,
				1,
				0,
				0
			}
		},
		{
			r = 10000,
			dmg_mul = 1,
			recoil = {2, 5},
			mode = {
				1,
				0,
				0,
				0
			}
		}
	}
	presets.weapon.normal.c45.aim_delay = {0, 0.2}
	presets.weapon.normal.c45.focus_delay = 1
	presets.weapon.normal.c45.focus_dis = 2000
	presets.weapon.normal.c45.spread = 25
	presets.weapon.normal.c45.miss_dis = 20
	presets.weapon.normal.c45.hit_chance = {
		near = {0.1, 0.6},
		far = {0, 0.1}
	}
	presets.weapon.normal.c45.RELOAD_SPEED = 1.5
	presets.weapon.normal.c45.FALLOFF = {
		{
			r = 0,
			dmg_mul = 4,
			recoil = {0.25, 0.35},
			mode = {
				2,
				1,
				0,
				0
			}
		},
		{
			r = 700,
			dmg_mul = 1,
			recoil = {0.25, 0.35},
			mode = {
				2,
				1,
				0,
				0
			}
		},
		{
			r = 3000,
			dmg_mul = 1,
			recoil = {0.25, 0.35},
			mode = {
				2,
				1,
				0,
				0
			}
		},
		{
			r = 10000,
			dmg_mul = 1,
			recoil = {2, 5},
			mode = {
				1,
				0,
				0,
				0
			}
		}
	}
	presets.weapon.normal.m4.aim_delay = {0, 0.2}
	presets.weapon.normal.m4.focus_delay = 1
	presets.weapon.normal.m4.focus_dis = 2000
	presets.weapon.normal.m4.spread = 15
	presets.weapon.normal.m4.miss_dis = 10
	presets.weapon.normal.m4.hit_chance = {
		near = {0.1, 0.6},
		far = {0, 0.2}
	}
	presets.weapon.normal.m4.RELOAD_SPEED = 1
	presets.weapon.normal.m4.FALLOFF = {
		{
			r = 0,
			dmg_mul = 4,
			recoil = {0.25, 0.45},
			mode = {
				3,
				3,
				3,
				3
			}
		},
		{
			r = 700,
			dmg_mul = 1,
			recoil = {0.25, 0.45},
			mode = {
				3,
				3,
				3,
				3
			}
		},
		{
			r = 3000,
			dmg_mul = 1,
			recoil = {0.25, 0.45},
			mode = {
				3,
				3,
				3,
				3
			}
		},
		{
			r = 10000,
			dmg_mul = 1,
			recoil = {1.5, 3},
			mode = {
				2,
				1,
				0,
				0
			}
		}
	}
	presets.weapon.normal.r870.aim_delay = {0, 0.02}
	presets.weapon.normal.r870.focus_delay = 1
	presets.weapon.normal.r870.focus_dis = 2000
	presets.weapon.normal.r870.spread = 25
	presets.weapon.normal.r870.miss_dis = 10
	presets.weapon.normal.r870.hit_chance = {
		near = {0.2, 0.9},
		far = {0, 0.8}
	}
	presets.weapon.normal.r870.RELOAD_SPEED = 2
	presets.weapon.normal.r870.FALLOFF = {
		{
			r = 0,
			dmg_mul = 4,
			recoil = {2, 2},
			mode = {
				1,
				0,
				0,
				0
			}
		},
		{
			r = 700,
			dmg_mul = 1,
			recoil = {2, 2},
			mode = {
				1,
				0,
				0,
				0
			}
		},
		{
			r = 1000,
			dmg_mul = 1,
			recoil = {2, 2},
			mode = {
				1,
				0,
				0,
				0
			}
		},
		{
			r = 4000,
			dmg_mul = 0.5,
			recoil = {2, 3},
			mode = {
				1,
				0,
				0,
				0
			}
		},
		{
			r = 10000,
			dmg_mul = 0.3,
			recoil = {2, 4},
			mode = {
				1,
				0,
				0,
				0
			}
		}
	}
	presets.weapon.normal.mp5.aim_delay = {0, 0.2}
	presets.weapon.normal.mp5.focus_delay = 1
	presets.weapon.normal.mp5.focus_dis = 2000
	presets.weapon.normal.mp5.spread = 25
	presets.weapon.normal.mp5.miss_dis = 10
	presets.weapon.normal.mp5.hit_chance = {
		near = {0.1, 0.6},
		far = {0, 0.2}
	}
	presets.weapon.normal.mp5.RELOAD_SPEED = 2
	presets.weapon.normal.mp5.FALLOFF = {
		{
			r = 0,
			dmg_mul = 4,
			recoil = {0.35, 0.55},
			mode = {
				2,
				1,
				3,
				0
			}
		},
		{
			r = 700,
			dmg_mul = 1,
			recoil = {0.35, 0.55},
			mode = {
				2,
				1,
				3,
				0
			}
		},
		{
			r = 3000,
			dmg_mul = 1,
			recoil = {0.35, 0.55},
			mode = {
				2,
				1,
				3,
				0
			}
		},
		{
			r = 10000,
			dmg_mul = 1,
			recoil = {2, 4},
			mode = {
				3,
				1,
				0,
				0
			}
		}
	}
	presets.weapon.normal.mac11.aim_delay = {0, 0.2}
	presets.weapon.normal.mac11.focus_delay = 1
	presets.weapon.normal.mac11.focus_dis = 2000
	presets.weapon.normal.mac11.spread = 25
	presets.weapon.normal.mac11.miss_dis = 10
	presets.weapon.normal.mac11.hit_chance = {
		near = {0.1, 0.6},
		far = {0, 0.2}
	}
	presets.weapon.normal.mac11.RELOAD_SPEED = 2
	presets.weapon.normal.mac11.FALLOFF = {
		{
			r = 0,
			dmg_mul = 4,
			recoil = {0.35, 0.55},
			mode = {
				2,
				1,
				3,
				0
			}
		},
		{
			r = 700,
			dmg_mul = 1,
			recoil = {0.35, 0.55},
			mode = {
				2,
				1,
				3,
				0
			}
		},
		{
			r = 3000,
			dmg_mul = 1,
			recoil = {0.35, 0.55},
			mode = {
				2,
				1,
				3,
				0
			}
		},
		{
			r = 10000,
			dmg_mul = 1,
			recoil = {2, 4},
			mode = {
				4,
				1,
				0,
				0
			}
		}
	}
	presets.weapon.good = {
		beretta92 = {},
		c45 = {},
		m4 = {},
		r870 = {},
		mp5 = {},
		mac11 = {}
	}
	presets.weapon.good.beretta92.aim_delay = {0, 0.2}
	presets.weapon.good.beretta92.focus_delay = 1
	presets.weapon.good.beretta92.focus_dis = 2000
	presets.weapon.good.beretta92.spread = 15
	presets.weapon.good.beretta92.miss_dis = 20
	presets.weapon.good.beretta92.hit_chance = {
		near = {0.1, 0.6},
		far = {0, 0.1}
	}
	presets.weapon.good.beretta92.RELOAD_SPEED = 1.5
	presets.weapon.good.beretta92.FALLOFF = {
		{
			r = 0,
			dmg_mul = 4,
			recoil = {0.25, 0.35},
			mode = {
				1,
				3,
				1,
				0
			}
		},
		{
			r = 700,
			dmg_mul = 1,
			recoil = {0.25, 0.35},
			mode = {
				1,
				3,
				1,
				0
			}
		},
		{
			r = 3000,
			dmg_mul = 1,
			recoil = {0.25, 0.35},
			mode = {
				1,
				3,
				1,
				0
			}
		},
		{
			r = 10000,
			dmg_mul = 1,
			recoil = {1.6, 3.5},
			mode = {
				1,
				0,
				0,
				0
			}
		}
	}
	presets.weapon.good.c45.aim_delay = {0, 0.2}
	presets.weapon.good.c45.focus_delay = 1
	presets.weapon.good.c45.focus_dis = 2000
	presets.weapon.good.c45.spread = 15
	presets.weapon.good.c45.miss_dis = 20
	presets.weapon.good.c45.hit_chance = {
		near = {0.1, 0.6},
		far = {0, 0.1}
	}
	presets.weapon.good.c45.RELOAD_SPEED = 1.5
	presets.weapon.good.c45.FALLOFF = {
		{
			r = 0,
			dmg_mul = 4,
			recoil = {0.25, 0.35},
			mode = {
				1,
				3,
				1,
				0
			}
		},
		{
			r = 700,
			dmg_mul = 1,
			recoil = {0.25, 0.35},
			mode = {
				1,
				3,
				1,
				0
			}
		},
		{
			r = 3000,
			dmg_mul = 1,
			recoil = {0.25, 0.35},
			mode = {
				1,
				3,
				1,
				0
			}
		},
		{
			r = 10000,
			dmg_mul = 1,
			recoil = {1.6, 3.5},
			mode = {
				1,
				0,
				0,
				0
			}
		}
	}
	presets.weapon.good.m4.aim_delay = {0, 0.2}
	presets.weapon.good.m4.focus_delay = 1
	presets.weapon.good.m4.focus_dis = 2000
	presets.weapon.good.m4.spread = 15
	presets.weapon.good.m4.miss_dis = 10
	presets.weapon.good.m4.hit_chance = {
		near = {0.1, 0.6},
		far = {0, 0.2}
	}
	presets.weapon.good.m4.RELOAD_SPEED = 1
	presets.weapon.good.m4.FALLOFF = {
		{
			r = 0,
			dmg_mul = 4,
			recoil = {0.25, 0.45},
			mode = {
				3,
				3,
				3,
				3
			}
		},
		{
			r = 700,
			dmg_mul = 1,
			recoil = {0.25, 0.45},
			mode = {
				3,
				3,
				3,
				3
			}
		},
		{
			r = 3000,
			dmg_mul = 1,
			recoil = {0.25, 0.45},
			mode = {
				3,
				3,
				3,
				3
			}
		},
		{
			r = 10000,
			dmg_mul = 1,
			recoil = {1.2, 2.5},
			mode = {
				2,
				1,
				0,
				0
			}
		}
	}
	presets.weapon.good.r870.aim_delay = {0, 0.02}
	presets.weapon.good.r870.focus_delay = 1
	presets.weapon.good.r870.focus_dis = 2000
	presets.weapon.good.r870.spread = 15
	presets.weapon.good.r870.miss_dis = 10
	presets.weapon.good.r870.hit_chance = {
		near = {0.4, 0.9},
		far = {0, 0.9}
	}
	presets.weapon.good.r870.RELOAD_SPEED = 2
	presets.weapon.good.r870.FALLOFF = {
		{
			r = 0,
			dmg_mul = 4,
			recoil = {2, 2},
			mode = {
				1,
				1,
				0,
				0
			}
		},
		{
			r = 700,
			dmg_mul = 1,
			recoil = {2, 2},
			mode = {
				1,
				1,
				0,
				0
			}
		},
		{
			r = 1000,
			dmg_mul = 1,
			recoil = {2, 2},
			mode = {
				1,
				1,
				0,
				0
			}
		},
		{
			r = 4000,
			dmg_mul = 0.5,
			recoil = {2, 3},
			mode = {
				1,
				0,
				0,
				0
			}
		},
		{
			r = 10000,
			dmg_mul = 0.3,
			recoil = {2, 4},
			mode = {
				1,
				0,
				0,
				0
			}
		}
	}
	presets.weapon.good.mp5.aim_delay = {0, 0.2}
	presets.weapon.good.mp5.focus_delay = 1
	presets.weapon.good.mp5.focus_dis = 2000
	presets.weapon.good.mp5.spread = 15
	presets.weapon.good.mp5.miss_dis = 10
	presets.weapon.good.mp5.hit_chance = {
		near = {0.1, 0.6},
		far = {0, 0.2}
	}
	presets.weapon.good.mp5.RELOAD_SPEED = 1.5
	presets.weapon.good.mp5.FALLOFF = {
		{
			r = 0,
			dmg_mul = 4,
			recoil = {0.35, 0.55},
			mode = {
				0.2,
				2,
				4,
				10
			}
		},
		{
			r = 700,
			dmg_mul = 1,
			recoil = {0.35, 0.55},
			mode = {
				0.2,
				2,
				4,
				10
			}
		},
		{
			r = 3000,
			dmg_mul = 1,
			recoil = {0.35, 0.55},
			mode = {
				0.2,
				2,
				4,
				10
			}
		},
		{
			r = 10000,
			dmg_mul = 1,
			recoil = {1.8, 3.5},
			mode = {
				3,
				1,
				0,
				0
			}
		}
	}
	presets.weapon.good.mac11.aim_delay = {0, 0.2}
	presets.weapon.good.mac11.focus_delay = 1
	presets.weapon.good.mac11.focus_dis = 2000
	presets.weapon.good.mac11.spread = 15
	presets.weapon.good.mac11.miss_dis = 10
	presets.weapon.good.mac11.hit_chance = {
		near = {0.1, 0.6},
		far = {0, 0.2}
	}
	presets.weapon.good.mac11.RELOAD_SPEED = 1.5
	presets.weapon.good.mac11.FALLOFF = {
		{
			r = 0,
			dmg_mul = 4,
			recoil = {0.35, 0.55},
			mode = {
				0.2,
				2,
				4,
				10
			}
		},
		{
			r = 700,
			dmg_mul = 1,
			recoil = {0.35, 0.55},
			mode = {
				0.2,
				2,
				4,
				10
			}
		},
		{
			r = 3000,
			dmg_mul = 1,
			recoil = {0.35, 0.55},
			mode = {
				0.2,
				2,
				4,
				10
			}
		},
		{
			r = 10000,
			dmg_mul = 1,
			recoil = {2, 4},
			mode = {
				4,
				1,
				0,
				0
			}
		}
	}
	presets.weapon.expert = {
		beretta92 = {},
		c45 = {},
		m4 = {},
		r870 = {},
		mp5 = {},
		mac11 = {}
	}
	presets.weapon.expert.beretta92.aim_delay = {0, 0.2}
	presets.weapon.expert.beretta92.focus_delay = 1
	presets.weapon.expert.beretta92.focus_dis = 2000
	presets.weapon.expert.beretta92.spread = 15
	presets.weapon.expert.beretta92.miss_dis = 20
	presets.weapon.expert.beretta92.hit_chance = {
		near = {0.1, 0.9},
		far = {0, 0.3}
	}
	presets.weapon.expert.beretta92.RELOAD_SPEED = 1.5
	presets.weapon.expert.beretta92.FALLOFF = {
		{
			r = 0,
			dmg_mul = 4,
			recoil = {0.25, 0.35},
			mode = {
				1,
				3,
				1,
				0
			}
		},
		{
			r = 700,
			dmg_mul = 1,
			recoil = {0.25, 0.35},
			mode = {
				1,
				3,
				1,
				0
			}
		},
		{
			r = 3000,
			dmg_mul = 1,
			recoil = {0.25, 0.35},
			mode = {
				1,
				3,
				1,
				0
			}
		},
		{
			r = 10000,
			dmg_mul = 1,
			recoil = {1.5, 3},
			mode = {
				1,
				0,
				0,
				0
			}
		}
	}
	presets.weapon.expert.c45.aim_delay = {0, 0.2}
	presets.weapon.expert.c45.focus_delay = 1
	presets.weapon.expert.c45.focus_dis = 2000
	presets.weapon.expert.c45.spread = 15
	presets.weapon.expert.c45.miss_dis = 20
	presets.weapon.expert.c45.hit_chance = {
		near = {0.1, 0.9},
		far = {0, 0.3}
	}
	presets.weapon.expert.c45.RELOAD_SPEED = 1.5
	presets.weapon.expert.c45.FALLOFF = {
		{
			r = 0,
			dmg_mul = 4,
			recoil = {0.25, 0.35},
			mode = {
				1,
				3,
				1,
				0
			}
		},
		{
			r = 700,
			dmg_mul = 1,
			recoil = {0.25, 0.35},
			mode = {
				1,
				3,
				1,
				0
			}
		},
		{
			r = 3000,
			dmg_mul = 1,
			recoil = {0.25, 0.35},
			mode = {
				1,
				3,
				1,
				0
			}
		},
		{
			r = 10000,
			dmg_mul = 1,
			recoil = {1.5, 3},
			mode = {
				1,
				0,
				0,
				0
			}
		}
	}
	presets.weapon.expert.m4.aim_delay = {0, 0.2}
	presets.weapon.expert.m4.focus_delay = 1
	presets.weapon.expert.m4.focus_dis = 2000
	presets.weapon.expert.m4.spread = 15
	presets.weapon.expert.m4.miss_dis = 10
	presets.weapon.expert.m4.hit_chance = {
		near = {0.1, 0.9},
		far = {0, 0.5}
	}
	presets.weapon.expert.m4.RELOAD_SPEED = 1
	presets.weapon.expert.m4.FALLOFF = {
		{
			r = 0,
			dmg_mul = 4,
			recoil = {0.25, 0.45},
			mode = {
				0.2,
				2,
				4,
				10
			}
		},
		{
			r = 700,
			dmg_mul = 1,
			recoil = {0.25, 0.45},
			mode = {
				0.2,
				2,
				4,
				10
			}
		},
		{
			r = 3000,
			dmg_mul = 1,
			recoil = {0.25, 0.45},
			mode = {
				0.2,
				2,
				4,
				10
			}
		},
		{
			r = 10000,
			dmg_mul = 1,
			recoil = {1.1, 2.2},
			mode = {
				2,
				1,
				0,
				0
			}
		}
	}
	presets.weapon.expert.r870.aim_delay = {0, 0.02}
	presets.weapon.expert.r870.focus_delay = 1
	presets.weapon.expert.r870.focus_dis = 2000
	presets.weapon.expert.r870.spread = 15
	presets.weapon.expert.r870.miss_dis = 10
	presets.weapon.expert.r870.hit_chance = {
		near = {0.4, 0.9},
		far = {0, 0.9}
	}
	presets.weapon.expert.r870.RELOAD_SPEED = 2
	presets.weapon.expert.r870.FALLOFF = {
		{
			r = 0,
			dmg_mul = 4,
			recoil = {2, 2},
			mode = {
				1,
				1,
				0,
				0
			}
		},
		{
			r = 700,
			dmg_mul = 1,
			recoil = {2, 2},
			mode = {
				1,
				1,
				0,
				0
			}
		},
		{
			r = 1000,
			dmg_mul = 1,
			recoil = {2, 2},
			mode = {
				1,
				1,
				0,
				0
			}
		},
		{
			r = 2000,
			dmg_mul = 0.5,
			recoil = {2, 3},
			mode = {
				1,
				0,
				0,
				0
			}
		},
		{
			r = 10000,
			dmg_mul = 0.3,
			recoil = {2, 4},
			mode = {
				1,
				0,
				0,
				0
			}
		}
	}
	presets.weapon.expert.mp5.aim_delay = {0, 0.2}
	presets.weapon.expert.mp5.focus_delay = 1
	presets.weapon.expert.mp5.focus_dis = 2000
	presets.weapon.expert.mp5.spread = 15
	presets.weapon.expert.mp5.miss_dis = 10
	presets.weapon.expert.mp5.hit_chance = {
		near = {0.1, 0.9},
		far = {0, 0.3}
	}
	presets.weapon.expert.mp5.RELOAD_SPEED = 1.5
	presets.weapon.expert.mp5.FALLOFF = {
		{
			r = 0,
			dmg_mul = 4,
			recoil = {0.35, 0.55},
			mode = {
				0.2,
				2,
				4,
				10
			}
		},
		{
			r = 700,
			dmg_mul = 1,
			recoil = {0.35, 0.55},
			mode = {
				0.2,
				2,
				4,
				10
			}
		},
		{
			r = 3000,
			dmg_mul = 1,
			recoil = {0.35, 0.55},
			mode = {
				0.2,
				2,
				4,
				10
			}
		},
		{
			r = 10000,
			dmg_mul = 1,
			recoil = {1.5, 3.1},
			mode = {
				3,
				1,
				0,
				0
			}
		}
	}
	presets.weapon.expert.mac11.aim_delay = {0, 0.2}
	presets.weapon.expert.mac11.focus_delay = 1
	presets.weapon.expert.mac11.focus_dis = 2000
	presets.weapon.expert.mac11.spread = 15
	presets.weapon.expert.mac11.miss_dis = 10
	presets.weapon.expert.mac11.hit_chance = {
		near = {0.1, 0.9},
		far = {0, 0.3}
	}
	presets.weapon.expert.mac11.RELOAD_SPEED = 1.5
	presets.weapon.expert.mac11.FALLOFF = {
		{
			r = 0,
			dmg_mul = 4,
			recoil = {0.35, 0.55},
			mode = {
				0.2,
				2,
				4,
				10
			}
		},
		{
			r = 700,
			dmg_mul = 1,
			recoil = {0.35, 0.55},
			mode = {
				0.2,
				2,
				4,
				10
			}
		},
		{
			r = 3000,
			dmg_mul = 1,
			recoil = {0.35, 0.55},
			mode = {
				0.2,
				2,
				4,
				10
			}
		},
		{
			r = 10000,
			dmg_mul = 1,
			recoil = {1.8, 3.5},
			mode = {
				4,
				1,
				0,
				0
			}
		}
	}
	presets.weapon.sniper = {
		m4 = {}
	}
	presets.weapon.sniper.m4.aim_delay = {0, 0.2}
	presets.weapon.sniper.m4.focus_delay = 1
	presets.weapon.sniper.m4.focus_dis = 10000
	presets.weapon.sniper.m4.spread = 5
	presets.weapon.sniper.m4.miss_dis = 7
	presets.weapon.sniper.m4.hit_chance = {
		near = {0.5, 1},
		far = {0.5, 1}
	}
	presets.weapon.sniper.m4.RELOAD_SPEED = 1
	presets.weapon.sniper.m4.FALLOFF = {
		{
			r = 0,
			dmg_mul = 5,
			recoil = {1, 3},
			mode = {
				1,
				1,
				1,
				1
			}
		},
		{
			r = 50000,
			dmg_mul = 5,
			recoil = {1, 3},
			mode = {
				1,
				1,
				1,
				1
			}
		}
	}
	presets.weapon.gang_member = {
		beretta92 = {},
		m4 = {},
		r870 = {},
		mp5 = {}
	}
	presets.weapon.gang_member.beretta92.aim_delay = {0, 0.2}
	presets.weapon.gang_member.beretta92.focus_delay = 1
	presets.weapon.gang_member.beretta92.focus_dis = 2000
	presets.weapon.gang_member.beretta92.spread = 15
	presets.weapon.gang_member.beretta92.miss_dis = 20
	presets.weapon.gang_member.beretta92.hit_chance = {
		near = {0.1, 0.6},
		far = {0, 0.3}
	}
	presets.weapon.gang_member.beretta92.RELOAD_SPEED = 1.5
	presets.weapon.gang_member.beretta92.FALLOFF = {
		{
			r = 0,
			dmg_mul = 1,
			recoil = {0.15, 0.25},
			mode = {
				1,
				0,
				0,
				0
			}
		},
		{
			r = 700,
			dmg_mul = 2,
			recoil = {0.15, 0.25},
			mode = {
				1,
				0,
				0,
				0
			}
		},
		{
			r = 3000,
			dmg_mul = 1,
			recoil = {0.25, 0.35},
			mode = {
				1,
				0,
				0,
				0
			}
		},
		{
			r = 10000,
			dmg_mul = 0.3,
			recoil = {2, 3},
			mode = {
				1,
				0,
				0,
				0
			}
		}
	}
	presets.weapon.gang_member.m4.aim_delay = {0, 0.2}
	presets.weapon.gang_member.m4.focus_delay = 1
	presets.weapon.gang_member.m4.focus_dis = 2000
	presets.weapon.gang_member.m4.spread = 15
	presets.weapon.gang_member.m4.miss_dis = 10
	presets.weapon.gang_member.m4.hit_chance = {
		near = {0.1, 0.6},
		far = {0, 0.3}
	}
	presets.weapon.gang_member.m4.RELOAD_SPEED = 1
	presets.weapon.gang_member.m4.FALLOFF = {
		{
			r = 0,
			dmg_mul = 1,
			recoil = {0.25, 0.45},
			mode = {
				0.2,
				2,
				4,
				10
			}
		},
		{
			r = 700,
			dmg_mul = 2,
			recoil = {0.25, 0.45},
			mode = {
				0.2,
				2,
				4,
				10
			}
		},
		{
			r = 3000,
			dmg_mul = 1,
			recoil = {0.45, 0.8},
			mode = {
				1,
				5,
				5,
				4
			}
		},
		{
			r = 10000,
			dmg_mul = 1,
			recoil = {1.5, 3},
			mode = {
				10,
				4,
				1,
				0
			}
		}
	}
	presets.weapon.gang_member.r870.aim_delay = {0, 0.02}
	presets.weapon.gang_member.r870.focus_delay = 1
	presets.weapon.gang_member.r870.focus_dis = 2000
	presets.weapon.gang_member.r870.spread = 15
	presets.weapon.gang_member.r870.miss_dis = 10
	presets.weapon.gang_member.r870.hit_chance = {
		near = {0.5, 0.9},
		far = {0, 0.3}
	}
	presets.weapon.gang_member.r870.RELOAD_SPEED = 2
	presets.weapon.gang_member.r870.FALLOFF = {
		{
			r = 0,
			dmg_mul = 1,
			recoil = {2, 2},
			mode = {
				1,
				0,
				0,
				0
			}
		},
		{
			r = 700,
			dmg_mul = 1,
			recoil = {2, 2},
			mode = {
				1,
				0,
				0,
				0
			}
		},
		{
			r = 1000,
			dmg_mul = 1,
			recoil = {2, 2},
			mode = {
				1,
				0,
				0,
				0
			}
		},
		{
			r = 2000,
			dmg_mul = 0.5,
			recoil = {2, 3},
			mode = {
				1,
				0,
				0,
				0
			}
		},
		{
			r = 10000,
			dmg_mul = 0.3,
			recoil = {2, 4},
			mode = {
				1,
				0,
				0,
				0
			}
		}
	}
	presets.weapon.gang_member.mp5.aim_delay = {0, 0.2}
	presets.weapon.gang_member.mp5.focus_delay = 1
	presets.weapon.gang_member.mp5.focus_dis = 2000
	presets.weapon.gang_member.mp5.spread = 15
	presets.weapon.gang_member.mp5.miss_dis = 10
	presets.weapon.gang_member.mp5.hit_chance = {
		near = {0.1, 0.6},
		far = {0, 0.3}
	}
	presets.weapon.gang_member.mp5.RELOAD_SPEED = 1.5
	presets.weapon.gang_member.mp5.FALLOFF = {
		{
			r = 0,
			dmg_mul = 1,
			recoil = {0.3, 0.5},
			mode = {
				0.2,
				2,
				4,
				10
			}
		},
		{
			r = 700,
			dmg_mul = 1,
			recoil = {0.3, 0.5},
			mode = {
				0.2,
				2,
				4,
				10
			}
		},
		{
			r = 3000,
			dmg_mul = 1,
			recoil = {0.35, 0.55},
			mode = {
				1,
				5,
				5,
				5
			}
		},
		{
			r = 10000,
			dmg_mul = 1,
			recoil = {0.35, 0.55},
			mode = {
				10,
				3,
				0.5,
				0
			}
		}
	}
	presets.detection = {}
	presets.detection.normal = {
		idle = {},
		combat = {},
		recon = {},
		guard = {}
	}
	presets.detection.normal.idle.dis_max = 10000
	presets.detection.normal.idle.angle_max = 140
	presets.detection.normal.idle.delay = {min = 0, max = 0}
	presets.detection.normal.combat.dis_max = 10000
	presets.detection.normal.combat.angle_max = 140
	presets.detection.normal.combat.delay = {min = 0, max = 0}
	presets.detection.normal.recon.dis_max = 10000
	presets.detection.normal.recon.angle_max = 140
	presets.detection.normal.recon.delay = {min = 0, max = 0}
	presets.detection.normal.guard.dis_max = 10000
	presets.detection.normal.guard.angle_max = 140
	presets.detection.normal.guard.delay = {min = 0, max = 0}
	presets.detection.guard = {
		idle = {},
		combat = {},
		recon = {},
		guard = {}
	}
	presets.detection.guard.idle.dis_max = 6000
	presets.detection.guard.idle.angle_max = 120
	presets.detection.guard.idle.delay = {min = 0, max = 0}
	presets.detection.guard.combat.dis_max = 10000
	presets.detection.guard.combat.angle_max = 90
	presets.detection.guard.combat.delay = {min = 0, max = 0}
	presets.detection.guard.recon.dis_max = 10000
	presets.detection.guard.recon.angle_max = 120
	presets.detection.guard.recon.delay = {min = 0, max = 0}
	presets.detection.guard.guard.dis_max = 10000
	presets.detection.guard.guard.angle_max = 100
	presets.detection.guard.guard.delay = {min = 0, max = 0}
	presets.detection.sniper = {
		idle = {},
		combat = {},
		recon = {},
		guard = {}
	}
	presets.detection.sniper.idle.dis_max = 10000
	presets.detection.sniper.idle.angle_max = 180
	presets.detection.sniper.idle.delay = {min = 0, max = 0}
	presets.detection.sniper.combat.dis_max = 10000
	presets.detection.sniper.combat.angle_max = 120
	presets.detection.sniper.combat.delay = {min = 0, max = 0}
	presets.detection.sniper.recon.dis_max = 10000
	presets.detection.sniper.recon.angle_max = 120
	presets.detection.sniper.recon.delay = {min = 0, max = 0}
	presets.detection.sniper.guard.dis_max = 10000
	presets.detection.sniper.guard.angle_max = 150
	presets.detection.sniper.guard.delay = {min = 0, max = 0}
	presets.detection.gang_member = {
		idle = {},
		combat = {},
		recon = {},
		guard = {}
	}
	presets.detection.gang_member.idle.dis_max = 10000
	presets.detection.gang_member.idle.angle_max = 120
	presets.detection.gang_member.idle.delay = {min = 0, max = 0}
	presets.detection.gang_member.combat.dis_max = 10000
	presets.detection.gang_member.combat.angle_max = 120
	presets.detection.gang_member.combat.delay = {min = 0, max = 0}
	presets.detection.gang_member.recon.dis_max = 10000
	presets.detection.gang_member.recon.angle_max = 120
	presets.detection.gang_member.recon.delay = {min = 0, max = 0}
	presets.detection.gang_member.guard.dis_max = 10000
	presets.detection.gang_member.guard.angle_max = 120
	presets.detection.gang_member.guard.delay = {min = 0, max = 0}
	self:_process_weapon_usage_table(presets.weapon.normal)
	self:_process_weapon_usage_table(presets.weapon.good)
	self:_process_weapon_usage_table(presets.weapon.expert)
	self:_process_weapon_usage_table(presets.weapon.gang_member)
	presets.detection.patrol = {
		idle = {},
		combat = {},
		recon = {},
		guard = {}
	}
	presets.detection.patrol.idle.dis_max = 1100
	presets.detection.patrol.idle.angle_max = 80
	presets.detection.patrol.idle.delay = {min = 1, max = 1.5}
	presets.detection.patrol.combat.dis_max = 4000
	presets.detection.patrol.combat.angle_max = 90
	presets.detection.patrol.combat.delay = {min = 0.25, max = 0.5}
	presets.detection.patrol.recon.dis_max = 1100
	presets.detection.patrol.recon.angle_max = 80
	presets.detection.patrol.recon.delay = {min = 1, max = 1.5}
	presets.detection.patrol.guard.dis_max = 1100
	presets.detection.patrol.guard.angle_max = 80
	presets.detection.patrol.guard.delay = {min = 1, max = 1.5}
	presets.dodge = {}
	presets.dodge.poor = {
		on_hurt = {},
		on_hit = {},
		on_contact = {},
		scared = {}
	}
	presets.dodge.poor.on_hurt.chance = 0.2
	presets.dodge.poor.on_hurt.variation = {0.8, 1}
	presets.dodge.poor.on_hit.chance = 1
	presets.dodge.poor.on_hit.variation = {0.8, 1}
	presets.dodge.poor.on_contact.chance = 1
	presets.dodge.poor.on_contact.variation = {0, 1}
	presets.dodge.poor.scared.chance = 0.2
	presets.dodge.poor.scared.variation = {0.8, 1}
	presets.dodge.normal = {
		on_hurt = {},
		on_hit = {},
		on_contact = {},
		scared = {}
	}
	presets.dodge.normal.on_hurt.chance = 0.4
	presets.dodge.normal.on_hurt.variation = {0.6, 0.8}
	presets.dodge.normal.on_hit.chance = 1
	presets.dodge.normal.on_hit.variation = {0.6, 0.8}
	presets.dodge.normal.on_contact.chance = 1
	presets.dodge.normal.on_contact.variation = {0, 1}
	presets.dodge.normal.scared.chance = 0.4
	presets.dodge.normal.scared.variation = {0.6, 0.8}
	presets.dodge.good = {
		on_hurt = {},
		on_hit = {},
		on_contact = {},
		scared = {}
	}
	presets.dodge.good.on_hurt.chance = 0.6
	presets.dodge.good.on_hurt.variation = {0.4, 0.7}
	presets.dodge.good.on_contact.chance = 1
	presets.dodge.good.on_contact.variation = {0, 1}
	presets.dodge.good.scared.chance = 0.5
	presets.dodge.good.scared.variation = {0.4, 0.7}
	presets.dodge.expert = {
		on_hurt = {},
		on_hit = {},
		on_contact = {},
		scared = {}
	}
	presets.dodge.expert.on_hurt.chance = 0.7
	presets.dodge.expert.on_hurt.variation = {0.2, 0.5}
	presets.dodge.expert.on_contact.chance = 1
	presets.dodge.expert.on_contact.variation = {0, 0.9}
	presets.dodge.expert.scared.chance = 0.5
	presets.dodge.expert.scared.variation = {0.2, 0.5}
	presets.dodge.ninja = {
		on_hurt = {},
		on_hit = {},
		on_contact = {},
		scared = {}
	}
	presets.dodge.ninja.on_hurt.chance = 1
	presets.dodge.ninja.on_hurt.variation = {0, 0.3}
	presets.dodge.ninja.on_contact.chance = 1
	presets.dodge.ninja.on_contact.variation = {0, 0.75}
	presets.dodge.ninja.scared.chance = 1
	presets.dodge.ninja.scared.variation = {0, 0.3}
	presets.enemy_chatter = {
		no_chatter = {},
		cop = {
			aggressive = true,
			retreat = true,
			go_go = true
		},
		swat = {
			aggressive = true,
			retreat = true,
			follow_me = true,
			clear = true,
			go_go = true,
			ready = true,
			smoke = true,
			incomming_tank = true,
			incomming_spooc = true,
			incomming_shield = true,
			incomming_taser = true
		},
		shield = {follow_me = true}
	}
	return presets
end
function CharacterTweakData:_create_table_structure()
	self.weap_ids = {
		"beretta92",
		"c45",
		"m4",
		"r870",
		"mp5",
		"mac11",
		"shield",
		"sniper_rifle"
	}
	self.weap_unit_names = {
		Idstring("units/weapons/beretta92_npc/beretta92_npc"),
		Idstring("units/weapons/c45_npc/c45_npc"),
		Idstring("units/weapons/m4_rifle_npc/m4_rifle_npc"),
		Idstring("units/weapons/r870_shotgun_npc/r870_shotgun_npc"),
		Idstring("units/weapons/mp5_npc/mp5_npc"),
		Idstring("units/weapons/mac11_npc/mac11_npc"),
		Idstring("units/weapons/shield_pistol_npc/shield_pistol_npc"),
		Idstring("units/weapons/sniper_rifle_npc/sniper_rifle_npc")
	}
end
function CharacterTweakData:_process_weapon_usage_table(weap_usage_table)
	for _, weap_id in ipairs(self.weap_ids) do
		local usage_data = weap_usage_table[weap_id]
		if usage_data then
			for i_range, range_data in ipairs(usage_data.FALLOFF) do
				local modes = range_data.mode
				local total = 0
				for i_firemode, value in ipairs(modes) do
					total = total + value
				end
				local prev_value
				for i_firemode, value in ipairs(modes) do
					prev_value = (prev_value or 0) + value / total
					modes[i_firemode] = prev_value
				end
			end
		end
	end
end
