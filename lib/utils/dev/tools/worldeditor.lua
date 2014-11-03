core:import("CoreAiLayer")
core:import("CoreHeatmapLayer")
require("lib/units/editor/SpawnEnemyGroupElement")
require("lib/units/editor/EnemyPreferedElement")
require("lib/units/editor/AIGraphElement")
require("lib/units/editor/ScenarioTextElement")
require("lib/units/editor/WaypointElement")
require("lib/units/editor/SpawnCivilianElement")
require("lib/units/editor/SpawnCivilianGroupElement")
require("lib/units/editor/LookAtTrigger")
require("lib/units/editor/MissionEnd")
require("lib/units/editor/ObjectiveElement")
require("lib/units/editor/ConsoleCommandElement")
require("lib/units/editor/DialogueElement")
require("lib/units/editor/HeatElement")
require("lib/units/editor/HintElement")
require("lib/units/editor/MoneyElement")
require("lib/units/editor/AiGlobalEventElement")
require("lib/units/editor/EquipmentElement")
require("lib/units/editor/AreaMinPoliceForceUnitElement")
require("lib/units/editor/PlayerStateUnitElement")
require("lib/units/editor/ActionMessageUnitElement")
require("lib/units/editor/GameDirectionElement")
require("lib/units/editor/PressureElement")
require("lib/units/editor/DangerZoneElement")
require("lib/units/editor/ScenarioEventElement")
require("lib/units/editor/KillzoneElement")
require("lib/units/editor/SpecialObjectiveElement")
require("lib/units/editor/SpecialObjectiveTriggerElement")
require("lib/units/editor/SecretAssignmentElement")
require("lib/units/editor/PlayerStateTriggerUnitElement")
require("lib/units/editor/DifficultyElement")
require("lib/units/editor/BlurZoneElement")
require("lib/units/editor/AIRemoveElement")
require("lib/units/editor/FlashlightElement")
require("lib/units/editor/TeammateCommentElement")
require("lib/units/editor/FakeAssaultStateElement")
require("lib/units/editor/WhisperStateElement")
require("lib/units/editor/DifficultyLevelCheckElement")
require("lib/units/editor/AwardAchievmentElement")
require("lib/units/editor/PlayerNumberCheckElement")
require("lib/units/editor/PointOfNoReturnElement")
require("lib/units/editor/FadeToBlackElement")
require("lib/units/editor/AlertTriggerElement")
require("lib/units/editor/FeedbackElement")
require("lib/units/editor/FilterElement")
require("lib/units/editor/DisableUnitElement")
require("lib/units/editor/SmokeGrenadeElement")
require("lib/units/editor/SetOutlineElement")
require("lib/units/editor/DisableShoutElement")
require("lib/units/editor/ExplosionDamageElement")
require("lib/units/editor/SequenceCharacterElement")
require("lib/units/editor/PlayerStyleElement")
require("lib/units/editor/DropinStateElement")
require("lib/units/editor/BainStateElement")
require("lib/units/editor/BlackscreenVariantElement")
require("lib/units/editor/MaskFilterElement")
require("lib/units/editor/SpawnPlayerElement")
require("lib/units/editor/EnemyDummyTrigger")
require("lib/units/editor/SpawnEnemyElement")
WorldEditor = WorldEditor or class(CoreEditor)
function WorldEditor:init(game_state_machine)
	WorldEditor.super.init(self, game_state_machine)
	Network:set_multiplayer(true)
	managers.network:host_game()
end
function WorldEditor:_init_mission_difficulties()
	self._mission_difficulties = {
		"easy",
		"normal",
		"hard",
		"overkill",
		"overkill_145"
	}
	self._mission_difficulty = "normal"
end
function WorldEditor:_init_mission_players()
	self._mission_players = {
		1,
		2,
		3,
		4
	}
	self._mission_player = 1
end
function WorldEditor:_project_init_layer_classes()
	self:add_layer("Ai", CoreAiLayer.AiLayer)
	self:add_layer("Heatmap", CoreHeatmapLayer.HeatmapLayer)
end
function WorldEditor:_project_init_slot_masks()
	self._go_through_units_before_simulaton_mask = self._go_through_units_before_simulaton_mask + 15
end
function WorldEditor:project_run_simulation(with_mission)
	Global.game_settings.difficulty = self._mission_difficulty
	managers.network:host_game()
	managers.statistics:start_session({from_beginning = true})
	managers.player:on_simulation_started()
	managers.navigation:on_simulation_started()
	managers.groupai:on_simulation_started()
	if not with_mission then
		managers.player:set_player_state("standard")
		managers.groupai:state():set_AI_enabled(false)
		managers.network:register_spawn_point(-1, {
			position = self._vp:camera():position(),
			rotation = Rotation:yaw_pitch_roll(self._vp:camera():rotation():yaw(), 0, 0)
		})
	end
	managers.network:game():on_load_complete()
	managers.network:game():spawn_players()
end
function WorldEditor:_project_check_unit(unit)
	if unit:unit_data().secret_assignment_id then
		managers.secret_assignment:register_unit(unit)
	end
end
function WorldEditor:project_stop_simulation()
	managers.hud:on_simulation_ended()
	managers.hud:clear_waypoints()
	managers.network:unregister_all_spawn_points()
	managers.menu:close_menu("menu_pause")
	managers.objectives:reset()
	setup:freeflight():disable()
	managers.groupai:on_simulation_ended()
	managers.enemy:on_simulation_ended()
	managers.navigation:on_simulation_ended()
	managers.dialog:on_simulation_ended()
	managers.hint:on_simulation_ended()
	managers.experience:reset()
	managers.secret_assignment:reset()
	managers.statistics:stop_session()
	managers.environment_controller:set_blurzone(0)
	managers.music:stop()
	managers.game_play_central:on_simulation_ended()
	managers.criminals:on_simulation_ended()
end
function WorldEditor:project_clear_units()
	local units = World:find_units_quick("all", World:make_slot_mask(2, 4, 5, 6, 8, 9, 11, 12, 13, 14, 15, 16, 17, 18, 20, 21, 22, 23, 24, 25, 38))
	for _, unit in ipairs(units) do
		unit:set_slot(0)
	end
end
function WorldEditor:project_clear_layers()
end
function WorldEditor:project_recreate_layers()
end
