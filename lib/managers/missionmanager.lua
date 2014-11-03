core:import("CoreMissionManager")
core:import("CoreClass")
require("lib/managers/mission/MissionScriptElement")
require("lib/managers/mission/ElementSpawnEnemyGroup")
require("lib/managers/mission/ElementEnemyPrefered")
require("lib/managers/mission/ElementAIGraph")
require("lib/managers/mission/ElementScenarioText")
require("lib/managers/mission/ElementWaypoint")
require("lib/managers/mission/ElementSpawnCivilian")
require("lib/managers/mission/ElementSpawnCivilianGroup")
require("lib/managers/mission/ElementLookAtTrigger")
require("lib/managers/mission/ElementMissionEnd")
require("lib/managers/mission/ElementObjective")
require("lib/managers/mission/ElementConsoleCommand")
require("lib/managers/mission/ElementDialogue")
require("lib/managers/mission/ElementHeat")
require("lib/managers/mission/ElementHint")
require("lib/managers/mission/ElementMoney")
require("lib/managers/mission/ElementFleePoint")
require("lib/managers/mission/ElementAiGlobalEvent")
require("lib/managers/mission/ElementEquipment")
require("lib/managers/mission/ElementAreaMinPoliceForce")
require("lib/managers/mission/ElementPlayerState")
require("lib/managers/mission/ElementKillZone")
require("lib/managers/mission/ElementActionMessage")
require("lib/managers/mission/ElementGameDirection")
require("lib/managers/mission/ElementPressure")
require("lib/managers/mission/ElementDangerZone")
require("lib/managers/mission/ElementScenarioEvent")
require("lib/managers/mission/ElementSpecialObjective")
require("lib/managers/mission/ElementSpecialObjectiveTrigger")
require("lib/managers/mission/ElementSecretAssignment")
require("lib/managers/mission/ElementDifficulty")
require("lib/managers/mission/ElementBlurZone")
require("lib/managers/mission/ElementAIRemove")
require("lib/managers/mission/ElementFlashlight")
require("lib/managers/mission/ElementTeammateComment")
require("lib/managers/mission/ElementCharacterOutline")
require("lib/managers/mission/ElementFakeAssaultState")
require("lib/managers/mission/ElementWhisperState")
require("lib/managers/mission/ElementDifficultyLevelCheck")
require("lib/managers/mission/ElementAwardAchievment")
require("lib/managers/mission/ElementPlayerNumberCheck")
require("lib/managers/mission/ElementPointOfNoReturn")
require("lib/managers/mission/ElementFadeToBlack")
require("lib/managers/mission/ElementAlertTrigger")
require("lib/managers/mission/ElementFeedback")
require("lib/managers/mission/ElementFilter")
require("lib/managers/mission/ElementDisableUnit")
require("lib/managers/mission/ElementSmokeGrenade")
require("lib/managers/mission/ElementDisableShout")
require("lib/managers/mission/ElementSetOutline")
require("lib/managers/mission/ElementExplosionDamage")
require("lib/managers/mission/ElementSequenceCharacter")
require("lib/managers/mission/ElementPlayerStyle")
require("lib/managers/mission/ElementDropinState")
require("lib/managers/mission/ElementBainState")
require("lib/managers/mission/ElementBlackscreenVariant")
require("lib/managers/mission/ElementMaskFilter")
require("lib/managers/mission/ElementPlayerSpawner")
require("lib/managers/mission/ElementAreaTrigger")
require("lib/managers/mission/ElementSpawnEnemyDummy")
require("lib/managers/mission/ElementEnemyDummyTrigger")
MissionManager = MissionManager or class(CoreMissionManager.MissionManager)
function MissionManager:init(...)
	MissionManager.super.init(self, ...)
	self:add_area_instigator_categories("player")
	self:add_area_instigator_categories("enemies")
	self:add_area_instigator_categories("civilians")
	self:add_area_instigator_categories("escorts")
	self:add_area_instigator_categories("criminals")
	self:set_default_area_instigator("player")
	self:set_global_event_list({
		"bankmanager_key",
		"chavez_key",
		"blue_key",
		"start_assault"
	})
end
function MissionManager:default_instigator()
	return managers.player:player_unit()
end
function MissionManager:activate_script(...)
	MissionManager.super.activate_script(self, ...)
end
function MissionManager:client_run_mission_element(id, unit)
	for name, data in pairs(self._scripts) do
		if data:element(id) then
			data:element(id):client_on_executed(unit)
			return
		end
	end
end
function MissionManager:server_run_mission_element_trigger(id, unit)
	for name, data in pairs(self._scripts) do
		local element = data:element(id)
		if element then
			element:on_executed(unit)
			return
		end
	end
end
function MissionManager:server_enter_area(id, unit)
	for name, data in pairs(self._scripts) do
		local element = data:element(id)
		if element then
			element:sync_enter_area(unit)
		end
	end
end
function MissionManager:server_exit_area(id, unit)
	for name, data in pairs(self._scripts) do
		local element = data:element(id)
		if element then
			element:sync_exit_area(unit)
		end
	end
end
CoreClass.override_class(CoreMissionManager.MissionManager, MissionManager)
MissionScript = MissionScript or class(CoreMissionManager.MissionScript)
function MissionScript:activate(...)
	if Network:is_server() then
		MissionScript.super.activate(self, ...)
		return
	end
	managers.mission:add_persistent_debug_output("")
	managers.mission:add_persistent_debug_output("Activate mission " .. self._name, Color(1, 0, 1, 0))
	for _, element in pairs(self._elements) do
		element:on_script_activated()
	end
	for _, element in pairs(self._elements) do
		if element:value("execute_on_startup") then
		end
	end
end
CoreClass.override_class(CoreMissionManager.MissionScript, MissionScript)
