core:register_module("lib/managers/RumbleManager")
core:import("CoreAiDataManager")
require("lib/setups/Setup")
require("lib/utils/ListenerHolder")
require("lib/managers/SlotManager")
require("lib/managers/MissionManager")
require("lib/utils/dev/editor/WorldDefinition")
require("lib/managers/ObjectInteractionManager")
require("lib/managers/LocalizationManager")
require("lib/managers/DramaManager")
require("lib/managers/DialogManager")
require("lib/managers/EnemyManager")
require("lib/managers/SpawnManager")
require("lib/managers/HUDManager")
require("lib/managers/RumbleManager")
require("lib/managers/NavigationManager")
require("lib/managers/EnvironmentEffectsManager")
require("lib/managers/OverlayEffectManager")
require("lib/managers/ObjectivesManager")
require("lib/managers/GamePlayCentralManager")
require("lib/managers/HintManager")
require("lib/managers/MoneyManager")
require("lib/managers/ChallengesManager")
require("lib/managers/KillzoneManager")
require("lib/managers/ActionMessagingManager")
require("lib/managers/GroupAIManager")
require("lib/managers/SecretAssignmentManager")
require("lib/managers/StatisticsManager")
require("lib/managers/OcclusionManager")
require("lib/managers/TradeManager")
require("lib/managers/CriminalsManager")
require("lib/managers/FeedBackManager")
core:import("SequenceManager")
if Application:editor() then
	require("lib/utils/dev/tools/WorldEditor")
end
require("lib/units/SimpleCharacter")
require("lib/units/ScriptUnitData")
require("lib/units/UnitBase")
require("lib/units/SyncUnitData")
require("lib/units/beings/player/PlayerBase")
require("lib/units/beings/player/PlayerCamera")
require("lib/units/beings/player/PlayerSound")
require("lib/units/beings/player/PlayerAnimationData")
require("lib/units/beings/player/PlayerDamage")
require("lib/units/beings/player/PlayerInventory")
require("lib/units/beings/player/PlayerEquipment")
require("lib/units/beings/player/PlayerMovement")
require("lib/network/base/extensions/NetworkBaseExtension")
require("lib/network/extensions/player/HuskPlayerMovement")
require("lib/network/extensions/player/HuskPlayerInventory")
require("lib/network/extensions/player/HuskPlayerBase")
require("lib/network/extensions/player/HuskPlayerDamage")
require("lib/utils/SineSpline")
require("lib/units/cameras/AnimatedCamera")
require("lib/units/cameras/FPCameraPlayerBase")
require("lib/units/cameras/PrevisCamera")
require("lib/units/cameras/WaitingForPlayersCamera")
require("lib/units/enemies/cop/CopBase")
require("lib/units/enemies/cop/CopDamage")
require("lib/units/enemies/cop/CopBrain")
require("lib/units/enemies/cop/CopSound")
require("lib/units/enemies/cop/CopInventory")
require("lib/units/enemies/cop/CopMovement")
require("lib/units/enemies/tank/TankCopDamage")
require("lib/network/extensions/cop/HuskTankCopDamage")
require("lib/network/extensions/cop/HuskCopBase")
require("lib/network/extensions/cop/HuskCopInventory")
require("lib/network/extensions/cop/HuskCopDamage")
require("lib/network/extensions/cop/HuskCopBrain")
require("lib/network/extensions/cop/HuskCopMovement")
require("lib/units/civilians/DummyCivilianBase")
require("lib/units/civilians/CivilianBase")
require("lib/units/civilians/CivilianBrain")
require("lib/units/civilians/CivilianDamage")
require("lib/units/civilians/ServerSyncedCivilianDamage")
require("lib/network/extensions/civilian/HuskCivilianBase")
require("lib/network/extensions/civilian/HuskCivilianDamage")
require("lib/network/extensions/civilian/HuskServerSyncedCivilianDamage")
require("lib/units/player_team/TeamAIBase")
require("lib/units/player_team/TeamAIBrain")
require("lib/units/player_team/TeamAIDamage")
require("lib/network/extensions/player_team/HuskTeamAIDamage")
require("lib/units/player_team/TeamAIInventory")
require("lib/network/extensions/player_team/HuskTeamAIInventory")
require("lib/units/player_team/TeamAIMovement")
require("lib/network/extensions/player_team/HuskTeamAIMovement")
require("lib/units/player_team/TeamAISound")
require("lib/network/extensions/player_team/HuskTeamAIBase")
require("lib/units/vehicles/helicopter/AnimatedHeliBase")
require("lib/levels/FortressLevel")
require("lib/levels/SandboxLevel")
require("lib/units/interactions/InteractionExt")
require("lib/units/DramaExt")
require("lib/units/pickups/Pickup")
require("lib/units/pickups/AmmoClip")
require("lib/units/pickups/SpecialEquipmentPickup")
require("lib/units/equipment/ammo_bag/AmmoBagBase")
require("lib/units/equipment/doctor_bag/DoctorBagBase")
require("lib/units/equipment/sentry_gun/SentryGunBase")
require("lib/units/equipment/sentry_gun/SentryGunBrain")
require("lib/units/equipment/sentry_gun/SentryGunMovement")
require("lib/units/equipment/sentry_gun/SentryGunDamage")
require("lib/units/weapons/RaycastWeaponBase")
require("lib/units/weapons/NPCRaycastWeaponBase")
require("lib/units/weapons/NPCSniperRifleBase")
require("lib/units/weapons/trip_mine/TripMineBase")
require("lib/units/weapons/shotgun/ShotgunBase")
require("lib/units/weapons/shotgun/NPCShotgunBase")
require("lib/units/weapons/grenades/GrenadeBase")
require("lib/units/weapons/grenades/FragGrenade")
require("lib/units/weapons/grenades/FlashGrenade")
require("lib/units/weapons/grenades/SmokeGrenade")
require("lib/units/weapons/grenades/QuickSmokeGrenade")
require("lib/units/equipment/repel_rope/RepelRopeBase")
require("lib/units/weapons/GrenadeLauncherBase")
require("lib/units/weapons/NPCGrenadeLauncherBase")
require("lib/units/weapons/grenades/M79GrenadeBase")
require("lib/units/weapons/SentryGunWeapon")
require("lib/network/NetworkSpawnPointExt")
require("lib/units/props/SecurityCamera")
require("lib/units/props/TimerGui")
require("lib/units/props/MoneyWrapBase")
require("lib/units/props/Drill")
require("lib/units/props/SecurityLockGui")
require("lib/units/props/ChristmasPresentBase")
require("lib/units/props/TvGui")
GameSetup = GameSetup or class(Setup)
function GameSetup:load_packages()
	Setup.load_packages(self)
	if not PackageManager:loaded("packages/game_base") then
		PackageManager:load("packages/game_base")
	end
	local level_package
	if not Global.level_data or not Global.level_data.level_id then
		level_package = "packages/level_debug"
	else
		local lvl_tweak_data = Global.level_data and Global.level_data.level_id and tweak_data.levels[Global.level_data.level_id]
		level_package = lvl_tweak_data and lvl_tweak_data.package
	end
	if level_package and not PackageManager:loaded(level_package) then
		self._loaded_level_package = level_package
		PackageManager:load(level_package)
	end
end
function GameSetup:unload_packages()
	Setup.unload_packages(self)
	if Global.load_level or PackageManager:loaded("packages/game_base") then
	end
	if PackageManager:loaded(self._loaded_level_package) then
		PackageManager:unload(self._loaded_level_package)
		self._loaded_level_package = nil
	end
end
function GameSetup:init_managers(managers)
	Setup.init_managers(self, managers)
	managers.interaction = ObjectInteractionManager:new()
	managers.drama = DramaManager:new()
	managers.dialog = DialogManager:new()
	managers.enemy = EnemyManager:new()
	managers.spawn = SpawnManager:new()
	managers.hud = HUDManager:new()
	managers.navigation = NavigationManager:new()
	managers.objectives = ObjectivesManager:new()
	managers.game_play_central = GamePlayCentralManager:new()
	managers.hint = HintManager:new()
	managers.money = MoneyManager:new()
	managers.challenges = ChallengesManager:new()
	managers.killzone = KillzoneManager:new()
	managers.action_messaging = ActionMessagingManager:new()
	managers.groupai = GroupAIManager:new()
	managers.statistics = StatisticsManager:new()
	managers.ai_data = CoreAiDataManager.AiDataManager:new()
	managers.secret_assignment = SecretAssignmentManager:new()
	managers.occlusion = _OcclusionManager:new()
	managers.criminals = CriminalsManager:new()
	managers.trade = TradeManager:new()
	managers.feedback = FeedBackManager:new()
end
function GameSetup:init_game()
	local gsm = Setup.init_game(self)
	if not Application:editor() then
		local engine_package = PackageManager:package("engine-package")
		engine_package:unload_all_temp()
		local level = Global.level_data.level
		local mission = Global.level_data.mission
		local world_setting = Global.level_data.world_setting
		local level_class_name = Global.level_data.level_class_name
		local level_class = level_class_name and rawget(_G, level_class_name)
		if level then
			if level_class then
				script_data.level_script = level_class:new()
			end
			local level_path = "levels/" .. tostring(level)
			local t = {
				file_path = level_path .. "/world",
				file_type = "world",
				world_setting = world_setting
			}
			assert(WorldHolder:new(t):create_world("world", "all", Vector3()), "Cant load the level!")
			local mission_params = {
				file_path = level_path .. "/mission",
				activate_mission = mission,
				stage_name = "stage1"
			}
			managers.mission:parse(mission_params)
		else
			error("No level loaded! Use -level 'levelname'")
		end
		managers.worlddefinition:init_done()
	end
	return gsm
end
function GameSetup:init_finalize()
	if script_data.level_script and script_data.level_script.post_init then
		script_data.level_script:post_init()
	end
	Setup.init_finalize(self)
	managers.hud:init_finalize()
	managers.dialog:init_finalize()
	if not Application:editor() then
		managers.navigation:on_game_started()
	end
	if not Application:editor() then
		game_state_machine:change_state_by_name("ingame_waiting_for_players")
	end
	if SystemInfo:platform() == Idstring("PS3") then
		managers.achievment:chk_install_trophies()
	end
	self._keyboard = Input:keyboard()
end
function GameSetup:update(t, dt)
	Setup.update(self, t, dt)
	managers.interaction:update(t, dt)
	managers.dialog:update(t, dt)
	managers.enemy:update(t, dt)
	managers.groupai:update(t, dt)
	managers.spawn:update(t, dt)
	managers.navigation:update(t, dt)
	managers.hud:update(t, dt)
	managers.killzone:update(t, dt)
	managers.secret_assignment:update(t, dt)
	managers.game_play_central:update(t, dt)
	managers.trade:update(t, dt)
	managers.statistics:update(t, dt)
	if script_data.level_script and script_data.level_script.update then
		script_data.level_script:update(t, dt)
	end
	self:_update_debug_input()
end
function GameSetup:paused_update(t, dt)
	Setup.paused_update(self, t, dt)
	managers.groupai:paused_update(t, dt)
	if script_data.level_script and script_data.level_script.paused_update then
		script_data.level_script:paused_update(t, dt)
	end
	self:_update_debug_input()
end
function GameSetup:destroy()
	Setup.destroy(self)
	if script_data.level_script and script_data.level_script.destroy then
		script_data.level_script:destroy()
	end
	managers.navigation:destroy()
end
function GameSetup:end_update(t, dt)
	Setup.end_update(self, t, dt)
	managers.game_play_central:end_update(t, dt)
end
function GameSetup:save(data)
	Setup.save(self, data)
	managers.game_play_central:save(data)
	managers.hud:save(data)
	managers.objectives:save(data)
	managers.music:save(data)
	managers.environment_effects:save(data)
	managers.mission:save(data)
	managers.groupai:state():save(data)
	managers.player:sync_save(data)
	managers.trade:save(data)
	managers.groupai:state():save(data)
end
function GameSetup:load(data)
	Setup.load(self, data)
	managers.game_play_central:load(data)
	managers.hud:load(data)
	managers.objectives:load(data)
	managers.music:load(data)
	managers.environment_effects:load(data)
	managers.mission:load(data)
	managers.groupai:state():load(data)
	managers.player:sync_load(data)
	managers.trade:load(data)
	managers.groupai:state():load(data)
end
function GameSetup:_update_debug_input()
	local editor_ok = not Application:editor() or Global.running_simulation
	local debug_on_ok = Global.DEBUG_MENU_ON or Application:production_build()
	if not editor_ok or not debug_on_ok then
		return
	end
	if self._keyboard then
		if self._keyboard:pressed(59) then
			print("[GameSetup:_update_debug_input]", Application:paused() and "UNPAUSING" or "PAUSING")
			Application:set_pause(not Application:paused())
		elseif self._keyboard:pressed(60) then
			if self._framerate_low then
				self._framerate_low = nil
				Application:cap_framerate(self._framerate_cap)
			else
				self._framerate_low = true
				Application:cap_framerate(30)
			end
		end
	end
end
return GameSetup
