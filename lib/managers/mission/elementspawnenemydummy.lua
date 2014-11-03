core:import("CoreMissionScriptElement")
ElementSpawnEnemyDummy = ElementSpawnEnemyDummy or class(CoreMissionScriptElement.MissionScriptElement)
ElementSpawnEnemyDummy._unit_destroy_clbk_key = "ElementSpawnEnemyDummy"
ElementSpawnEnemyDummy._spawn_actions = {
	"cop_car_exit_to_rifle_combat_front_l",
	"cop_car_exit_to_rifle_combat_front_r",
	"repel_through_wndw_short",
	"repel_through_wndw_long",
	"repel_vert",
	"repel_wall",
	"repel_wall_building1",
	"so_repel_bridge_high",
	"so_repel_bridge_mid",
	"so_repel_bridge_low",
	"corner_l_jump",
	"plant_on_window",
	"kick_fwd",
	"run_jumpdown",
	"move_std_corner_run_l",
	"move_std_corner_run_r",
	"move_std_corner_walk_l",
	"move_climbover_std",
	"so_climbover_std",
	"so_climbover1_5m_drop1_5m",
	"so_climbover1_5m_drop3m",
	"move_jump_down_far",
	"move_jump_down_far2",
	"move_jump_down_far3",
	"move_jump_down_far4",
	"move_jump_down_far5",
	"so_jump_down_far",
	"so_jump_down_far2",
	"so_jump_down_far3",
	"so_jump_down_far4",
	"so_check_door_left",
	"so_check_door_right",
	"move_ladder_climbover_std",
	"command_advance_l",
	"command_stop_l",
	"command_takecover_l",
	"command_advance_r",
	"command_stop_r",
	"command_takecover_r",
	"civ_face_scan",
	"stand_talk1",
	"spawn_civ_hrt_crawl",
	"spawn_swatbus_var1",
	"spawn_swatbus_var2",
	"spawn_jump_outoff_heli",
	"spawn_jump_outoff_heli_var2",
	"tank_spawn_jump_heli",
	"female_so_loop",
	"so_debug_tpose",
	"so_cbt_force_door",
	"so_hos_wave_at_chopper",
	"so_hos_jumpdown",
	"so_get_up_on_desk",
	"so_jump_over_desk",
	"so_jump_staircase",
	"so_jump_staircase2",
	"so_jump_railing_4_7m",
	"so_railing_slide",
	"so_cover_crh_left_loop",
	"so_cover_std_left_loop",
	"so_cover_std_right_loop",
	"so_dodge_left",
	"so_dodge_right",
	"so_ledge_looking",
	"so_tumbup_behind",
	"so_knock_on_door",
	"so_unarmed_lean_right_loop",
	"so_unarmed_arms_crossed_loop",
	"so_apartment_sit_idle",
	"so_apartment_point",
	"so_apartment_checkbag",
	"so_apartment_checkbag_short",
	"so_look_peek_right",
	"so_look_peek_left",
	"so_point_direction_right",
	"so_try_kick_door",
	"so_aim_rifle_loop",
	"so_decend_catwalk",
	"so_descend_scaffold",
	"so_look_crh_at_floor",
	"so_pissing",
	"so_look_peek_into_window",
	"so_react_on_explosion_var1",
	"so_react_on_explosion_var2",
	"so_react_on_explosion_var3",
	"so_react_on_explosion_var4",
	"so_move_under_low_obj_right",
	"so_move_under_low_obj_left",
	"so_run_fwd_low",
	"so_run_fwd",
	"so_point_direction_fwd",
	"so_point_edge_down",
	"so_thug_idle_standing",
	"so_thug_idle_lean_bwd",
	"so_thug_idle_lean_fwd",
	"so_thug_idle_sitting",
	"so_walk_talking_phone_loop",
	"so_wait_for_phone",
	"so_answer_phone",
	"so_car_sit_come_here_enter",
	"so_jump_through_hole",
	"so_jump_through_hole_var2",
	"so_jump_through_hole_var3",
	"so_climb_through_window",
	"so_container_jumpdown",
	"so_container_jumpdown2",
	"so_container_jumpup",
	"so_hood_slide",
	"so_crh_to_std",
	"so_jump_gap_3m",
	"so_roll_under_low_obj",
	"so_jump_over_car_front",
	"so_jump_over_car_back",
	"so_crawl_under_low_obj",
	"so_climb_up_4m",
	"so_climb_down_4m",
	"so_climb_into_chopper",
	"so_climb_into_chopper_scared",
	"so_wait_chopper",
	"so_escort_fuckoff",
	"spawn_hrt_escort_guy",
	"so_enter_ejectionchair",
	"so_climb_1floor_through_window",
	"so_cloaker_wallrun",
	"so_slide_under_low_obj",
	"so_stand_thug_idle",
	"so_sit_thug_idle1",
	"so_sit_thug_idle2",
	"so_snorting_thug_idle",
	"so_zipline",
	"so_jump_through_var1",
	"so_jump_through_var2",
	"so_diamondglobe_jump_1",
	"so_diamondglobe_jump_2",
	"so_thug_sit_stair1",
	"so_thug_sit_stair2",
	"so_thug_sit_stair1_exit",
	"so_thug_sit_stair2_exit",
	"spawn_climb_window_right",
	"spawn_climb_window_left",
	"spawn_climb_roof",
	"so_escort_suitcase_spawn_hurt",
	"sit_in_chopper_loop",
	"so_escort_fuckoff_loop",
	"so_slide_under_var2",
	"so_jump_over_1_5m",
	"so_diagonal_over_object_right",
	"so_diagonal_over_object_left",
	"so_repel_10m",
	"so_hiding_b1_idle",
	"so_hiding_b1_react",
	"so_hiding_b2_idle",
	"so_hiding_b2_react",
	"civ_spawn_crawl_var1",
	"spawn_prisonvan_var1",
	"spawn_prisonvan_var2",
	"spawn_prisonvan_var3",
	"spawn_prisonvan_var4",
	"spawn_prisonvan_var5",
	"spawn_prisonvan_var6",
	"spawn_prisonvan_var8",
	"spawn_prisonvan_var9",
	"spawn_prisonvan_var10",
	"so_husk_hiding1",
	"so_husk_hiding2",
	"so_husk_hiding3",
	"so_husk_hiding4",
	"spawn_husk_hospital_var1",
	"spawn_husk_hospital_var2",
	"spawn_husk_hospital_var3",
	"spawn_husk_hospital_var4",
	"teamai_idle_nervous_var1",
	"teamai_idle_nervous_var2",
	"teamai_idle_nervous_var3",
	"teamai_idle_nervous_var4",
	"so_search_walk_fwd",
	"so_search_walk_turn_left",
	"so_search_stop_look_behind",
	"so_husk_wait_chopper_wave",
	"so_husk_wait_chopper",
	"spawn_hurt_out_of_suburban",
	"so_plant_bomb_low",
	"so_search_check_camera",
	"so_repel_33m",
	"so_search_check_booth",
	"so_climb_into_chopper_scared",
	"so_jump_up_elevator_hatch",
	"so_prisonvan1_to_pnc",
	"so_prisonvan2_6_to_pnc",
	"so_prisonvan3_4_5_to_pnc",
	"so_escort_hurt_opens_door",
	"so_escort_before_door_enter",
	"spawn_behind_wall_jump_over",
	"so_repel_16m",
	"so_wallrun_jump",
	"so_climb_1_5m",
	"so_jumpdown_1_5m_var1",
	"so_jumpdown_1_5m_var2",
	"so_climb_2m_fast",
	"repel_vert_skylight",
	"repel_vert_skylight2",
	"spawn_jumpdown_and_jump_var2",
	"male_dance_loop",
	"jump_up_3_25m_var1",
	"jump_up_3_75m_var1",
	"jump_up_3_75m_var2",
	"jump_down_3_75m_var1",
	"jump_down_3_75m_var2",
	"jump_up_0_5m_var1",
	"jump_up_1m_down_1_5m_var1",
	"jump_up_1m_down_1_5m_var2",
	"jump_up_1m_down_1_5m_var3",
	"jump_up_1m_down_1_5m_var4",
	"jump_up_2_5m_down_1m_var1",
	"jump_up_1_5m_down_1m_var1",
	"jump_up_1_5m_down_1m_var2",
	"jump_up_1m_down_2m_var1",
	"jump_over_1m_var1",
	"jump_over_1m_var2",
	"jump_over_1_5m_var1",
	"jump_over_1_5m_var2",
	"jump_over_1_5m_var3",
	"jump_over_2_5m_var1",
	"jump_over_2_5m_var2",
	"jump_over_2_5m_var3",
	"jump_forward_4m_var1",
	"jump_forward_4m_var2",
	"jump_forward_5m_var1",
	"jump_down_0_5m_var1",
	"jump_down_0_5m_var2",
	"jump_down_1m_var1",
	"jump_down_2_0m_var1",
	"jump_down_3_5m_var1",
	"jump_down_3_5m_var2",
	"jump_down_2_5m_var1",
	"jump_down_5_5m_var1",
	"jump_down_5_5m_var2",
	"so_pull_valve",
	"so_roof_through_wndw_4_75m_var1",
	"so_roof_through_wndw_4m_var1",
	"slide_under_short_var1",
	"jump_up_1m_var1",
	"jump_up_1m_down_4_75m_var1",
	"jump_up_1m_down_4_75m_var2",
	"jump_over_1m_var3",
	"jump_over_1m_var4",
	"jump_over_1m_var5",
	"jump_over_1m_var6",
	"jump_over_1m_var7",
	"jump_over_1m_var8",
	"jump_over_1_5m_var4",
	"jump_over_1_5m_var5",
	"jump_over_2_5m_var4",
	"jump_up_1m_jump_down_3m_var1",
	"jump_down_1m_var2",
	"jump_down_1m_var3",
	"jump_down_1m_var4",
	"jump_down_2_0m_var2",
	"jump_down_2_0m_var3",
	"jump_down_3_25m_var1",
	"jump_down_5_5m_var3",
	"jump_down_5_5m_var4",
	"spawn_repel_17m",
	"jump_up_helipad",
	"slide_under_long_var1",
	"jump_up_2m_var1",
	"jump_up_1m_down_5m_var1",
	"jump_up_1m_down_5m_var2",
	"jump_up_3m_down_1m_var1",
	"jump_up_3m_down_1m_var2",
	"jump_up_3_5m_var1",
	"shield_jump_up_1m",
	"shield_jump_over_1m",
	"shield_jump_down_1m",
	"shield_jump_down_2m",
	"shield_jump_down_3_5m",
	"tank_jump_down_3_5m",
	"tank_jump_down_1m",
	"tank_jump_down_2m",
	"tank_jump_over_1m",
	"tank_jump_up_1m",
	"cloaker_wallrun_left",
	"jump_over_1_80m_var1",
	"secret_stash_stand_enter",
	"secret_stash_sit_enter",
	"secret_stash_sit_tied_enter",
	"secret_stash_sit_tied_loop",
	"secret_stash_sit_tied_react",
	"secret_stash_sit_tied_react2",
	"secret_stash_sit_tied_yes",
	"secret_stash_sit_tied_no",
	"secret_stash_sit_tied_fwd_hit",
	"secret_stash_sit_tied_bwd_hit",
	"secret_stash_sit_tied_faint",
	"secret_stash_sit_tied_fainted",
	"secret_stash_sit_tied_wakeup",
	"secret_stash_spawn_crashed_limo1",
	"secret_stash_spawn_crashed_limo2",
	"secret_stash_spawn_crashed_limo3",
	"secret_stash_spawn_crashed_limo4",
	"nav_left_corner_shoot",
	"nav_sneek_right",
	"fbi_idle_var1",
	"sec_room_guard_idle",
	"fbi_idle_var2",
	"so_open_door_to_stair",
	"doctor_enter_var1",
	"doctor_enter_var2",
	"doctor_enter_var3",
	"nav_slide_long",
	"jump_up_5m_down_1m_var1",
	"jump_up_5m_down_1m_var2",
	"jump_up_1m_down_3m_var1",
	"jump_over_2m_var1",
	"jump_over_2m_var2",
	"spawn_from_vent_var1",
	"bbq_idle",
	"bbq_start_talk",
	"bbq_start_walk",
	"bbq_enter_stair",
	"bbq_basement_react",
	"nurse_idle_start",
	"nurse_approach_first_room",
	"nurse_approach_second_room",
	"nurse_approach_third_room",
	"nurse_returns",
	"spawn_civ_elevator_var1",
	"spawn_civ_elevator_female",
	"bill_spawn_elevator_var1",
	"bill_spawn_elevator_var2",
	"so_civ_elevator_var1",
	"jump_up_1m_down_0_75m_var1",
	"spawn_slide_down_var1",
	"spawn_slide_down_var2",
	"spawn_slide_down_var3",
	"spawn_from_4_4m_var1",
	"spawn_from_4_4m_var2",
	"spawn_from_4_4m_var3",
	"jump_over_1m_var9",
	"jump_over_1m_var10",
	"jump_up_1_25_down_1_5_var1",
	"jump_up_1_5_down_1_25_var1",
	"jump_up_7_5_down_1m_var1",
	"jump_down_panic_room_var1",
	"jump_up_1m_down_4_3m_var1",
	"jump_up_panic_room_var1",
	"jump_up_11_5m_down_1m_var1",
	"climb_bridge_tower",
	"jump_down_elevator_top",
	"jump_down_elevator_bot",
	"spawn_from_1_5m_var1",
	"jump_up_2_45_down_0_4_var1",
	"jump_over_1m_shoot_var1",
	"over_2_5m_shoot_var1",
	"so_pull_switch",
	"so_pull_switch_crh",
	"nav_jumpdown_sewer",
	"spawn_repel_11m",
	"spawn_repel_12m",
	"climb_into_panic_room_floor",
	"jump_up_1m_down_18m_var1",
	"walk_fwd_shoot_var1",
	"jump_down_3m_var1",
	"jump_down_3m_var2",
	"jump_down_2_5m_var2",
	"jump_up_3m_var1",
	"jump_up_2_5m_var1",
	"jump_up_1m_down_4_5m_var1",
	"jump_up_1_5m_down_1m_var3",
	"jump_up_1_5m_down_1m_var4",
	"jump_down_0_5m_var3",
	"jump_up_0_5m_var2",
	"jump_up_sec_stash_platform_var1",
	"jump_up_sec_stash_platform_var2",
	"jump_down_sec_stash_platform_var1",
	"jump_down_sec_stash_platform_var2",
	"jump_down_9m_var1",
	"jump_down_stairs_left",
	"jump_down_stairs_right",
	"jump_up_stairs_left",
	"jump_up_stairs_right",
	"nav_slide_downhill",
	"nav_drop_down_9m",
	"run_fwd_turn_l_var1",
	"run_fwd_turn_r_var1",
	"up_1m_dwn_1m_shoot_var2",
	"repel_stairway_shoot_var1",
	"repel_stairway_shoot_var2",
	"walk_through_shoot_var1",
	"down_3_5m_shoot_var1",
	"ss_intro_limo2_hood_idle",
	"ss_intro_limo2_trade_enter",
	"ss_intro_limo2_handsup_enter",
	"ss_intro_limo1_deal_idle",
	"ss_intro_limo1_deal_enter",
	"ss_intro_limo1_talk_idle",
	"ss_intro_limo1_trade_enter",
	"ss_intro_limo1_handsup_enter",
	"ss_intro_limo1_enter_limo",
	"ss_intro_limo1_short_enter_limo",
	"ss_intro_fbi_right_enter",
	"ss_intro_fbi_right_gun_enter",
	"ss_intro_fbi_right_react_enter_limo",
	"ss_intro_fbi_left_enter",
	"ss_intro_fbi_left_gun_enter",
	"spawn_cbt_std_pis_left_car_exit",
	"spawn_cbt_std_pis_right_car_exit",
	"spawn_cbt_std_rfl_left_car_exit",
	"spawn_cbt_std_rfl_right_car_exit",
	"spawn_cbt_std_sewer",
	"spawn_cbt_std_manhole_var1",
	"spawn_cbt_std_manhole_var2",
	"spawn_cbt_std_manhole_var3",
	"spawn_spook_cbt_std_sewer",
	"react",
	"so_press_alarm",
	"so_press_alarm_low",
	"so_check_patient",
	"so_alert_guards",
	"so_civ_elevator_var1"
}
ElementSpawnEnemyDummy._spawn_stance_types = {
	"neutral",
	"hostile",
	"combat"
}
function ElementSpawnEnemyDummy:init(...)
	ElementSpawnEnemyDummy.super.init(self, ...)
	self._enemy_name = self._values.enemy and Idstring(self._values.enemy) or Idstring("units/characters/enemies/swat/swat")
	self._units = {}
	self._events = {}
end
function ElementSpawnEnemyDummy:enemy_name()
	return self._enemy_name
end
function ElementSpawnEnemyDummy:units()
	return self._units
end
function ElementSpawnEnemyDummy:produce(params)
	local units_spawned = {}
	if params then
		for i, data in ipairs(params) do
			local unit = safe_spawn_unit(data.name, self._values.position, self._values.rotation)
			unit:base():add_destroy_listener(self._unit_destroy_clbk_key, callback(self, self, "clbk_unit_destroyed"))
			managers.groupai:state():assign_enemy_to_group_ai(unit)
			unit:unit_data().mission_element = self
			local spawn_ai = self:_create_spawn_AI_parametric(data.stance, data.objective, self._values)
			unit:brain():set_spawn_ai(spawn_ai)
			table.insert(self._units, unit)
			table.insert(units_spawned, unit)
			self:event("spawn", unit)
			if self._values.force_pickup and self._values.force_pickup ~= "none" then
				unit:character_damage():set_pickup(self._values.force_pickup)
			end
		end
	else
		local unit = safe_spawn_unit(self._enemy_name, self._values.position, self._values.rotation)
		unit:base():add_destroy_listener(self._unit_destroy_clbk_key, callback(self, self, "clbk_unit_destroyed"))
		unit:unit_data().mission_element = self
		local objective
		local action = self:_create_action_data(self._values)
		if action.type == "act" then
			objective = {
				type = "act",
				action = action,
				stance = "cbt"
			}
		end
		local spawn_ai = {init_state = "idle", objective = objective}
		unit:brain():set_spawn_ai(spawn_ai)
		if self._values.participate_to_group_ai ~= false then
			managers.groupai:state():assign_enemy_to_group_ai(unit)
		end
		table.insert(self._units, unit)
		table.insert(units_spawned, unit)
		self:event("spawn", unit)
		if self._values.force_pickup and self._values.force_pickup ~= "none" then
			unit:character_damage():set_pickup(self._values.force_pickup)
		end
	end
	return units_spawned
end
function ElementSpawnEnemyDummy.produce_test(data, unit)
	local action_desc = ElementSpawnEnemyDummy._create_action_data(nil, data)
	unit:movement():action_request(action_desc)
	unit:movement():set_position(unit:position())
end
function ElementSpawnEnemyDummy:clbk_unit_destroyed(unit)
	local u_key = unit:key()
	for i, owned_unit in ipairs(self._units) do
		if owned_unit:key() == u_key then
			table.remove(self._units, i)
		end
	end
end
function ElementSpawnEnemyDummy:event(name, unit)
	if self._events[name] then
		for _, callback in ipairs(self._events[name]) do
			callback(unit)
		end
	end
end
function ElementSpawnEnemyDummy:add_event_callback(name, callback)
	self._events[name] = self._events[name] or {}
	table.insert(self._events[name], callback)
end
function ElementSpawnEnemyDummy:on_executed(instigator)
	if not self._values.enabled then
		return
	end
	if not managers.groupai:state():is_AI_enabled() and not Application:editor() then
		return
	end
	local units = self:produce()
	ElementSpawnEnemyDummy.super.on_executed(self, units[1])
end
function ElementSpawnEnemyDummy:_create_spawn_AI_parametric(stance, objective, spawn_properties)
	local entry_action = self:_create_action_data(spawn_properties)
	if entry_action.type == "act" then
		local followup_objective = objective
		objective = {
			type = "act",
			action = entry_action,
			followup_objective = followup_objective
		}
	end
	return {
		init_state = "idle",
		stance = stance,
		objective = objective,
		params = {scan = true}
	}
end
function ElementSpawnEnemyDummy:_create_action_data(spawn_properties)
	local action_name = spawn_properties.spawn_action or spawn_properties.state
	if not action_name or action_name == "none" then
		return {
			type = "idle",
			body_part = 1,
			sync = true
		}
	else
		return {
			type = "act",
			variant = action_name,
			body_part = 1,
			blocks = {
				action = -1,
				walk = -1,
				hurt = -1,
				heavy_hurt = -1
			},
			align_sync = true
		}
	end
end
function ElementSpawnEnemyDummy:unspawn_all_units()
	for _, unit in ipairs(self._units) do
		if alive(unit) then
			unit:brain():set_active(false)
			unit:base():set_slot(unit, 0)
		end
	end
end
function ElementSpawnEnemyDummy:execute_on_all_units(func)
	for _, unit in ipairs(self._units) do
		if alive(unit) then
			func(unit)
		end
	end
end
