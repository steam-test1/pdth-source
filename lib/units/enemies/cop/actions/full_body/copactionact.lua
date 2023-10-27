local mvec3_set_z = mvector3.set_z
local mvec3_set = mvector3.set
local mvec3_sub = mvector3.subtract
local mvec3_norm = mvector3.normalize
local mvec3_add = mvector3.add
local tmp_vec1 = Vector3()
local ids_aim = Idstring("aim")
CopActionAct = CopActionAct or class()
CopActionAct._act_redirects = {
	"surprised",
	"hands_up",
	"hands_back",
	"tied",
	"react",
	"drop",
	"panic",
	"idle",
	"halt",
	"stand",
	"crouch",
	"revive",
	"untie",
	"cop_car_exit_to_rifle_combat_front_l",
	"cop_car_exit_to_rifle_combat_front_r",
	"repel_through_wndw_short",
	"repel_through_wndw_long",
	"repel_vert",
	"repel_wall",
	"repel_wall_building1",
	"jump_down_elevator_top",
	"jump_down_elevator_bot",
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
	"so_check_door_left",
	"so_check_door_right",
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
	"arrest",
	"stop",
	"move_jump_down_far",
	"move_jump_down_far2",
	"move_jump_down_far3",
	"move_jump_down_far4",
	"move_jump_down_far5",
	"so_jump_down_far",
	"so_jump_down_far2",
	"so_jump_down_far3",
	"so_jump_down_far4",
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
	"so_enter_ejectionchair",
	"so_wait_chopper",
	"so_escort_fuckoff",
	"so_cloaker_wallrun",
	"so_slide_under_low_obj",
	"so_climb_1floor_through_window",
	"so_stand_thug_idle",
	"so_sit_thug_idle1",
	"so_sit_thug_idle2",
	"so_snorting_thug_idle",
	"so_zipline",
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
	"sit_in_chopper_loop",
	"so_escort_suitcase_spawn_hurt",
	"so_escort_get_up_hesitant",
	"so_climb_into_chopper_scared",
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
	"so_pull_valve",
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
	"fbi_idle_var2",
	"sec_room_guard_idle",
	"so_open_door_to_stair",
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
	"up_1m_dwn_1m_shoot_var2",
	"repel_stairway_shoot_var1",
	"repel_stairway_shoot_var2",
	"walk_through_shoot_var1",
	"down_3_5m_shoot_var1",
	"run_fwd_turn_l_var1",
	"run_fwd_turn_r_var1",
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
	"doctor_enter_var1",
	"doctor_enter_var2",
	"doctor_enter_var3",
	"so_press_alarm",
	"so_press_alarm_low",
	"so_check_patient",
	"so_alert_guards"
}
CopActionAct._civilian_actions = {
	"stand_typing1",
	"lean_fwd_high",
	"lean_fwd_low1",
	"lean_fwd_low2",
	"lean_right_high",
	"lean_left_high",
	"sit_typing1",
	"sit_typing2",
	"sit_arms_crossed",
	"sit_idle",
	"sit_in_sofa1",
	"sit_in_sofa2",
	"sit_male_newspaper",
	"sit_smoke_fwd1",
	"sit_smoke_fwd2",
	"sit_armes_on_table1",
	"sit_armes_on_table2",
	"sit_feets_on_table",
	"stand_typing1",
	"stand_typing2",
	"stand_talk1",
	"stand_talk2",
	"stand_talk3",
	"stand_talk_smoke",
	"stand_arms_crossed1",
	"stand_arms_crossed2",
	"stand_arms_behind",
	"stand_idle1",
	"stand_idle2",
	"stand_idle3",
	"stand_idle4",
	"stand_idle5",
	"stand_idle6",
	"stand_idle_basic1",
	"stand_idle_basic2",
	"stand_write",
	"stand_interact_screen",
	"female_so_loop",
	"so_debug_tpose",
	"so_walk_talking_phone_loop",
	"so_wait_for_phone",
	"so_answer_phone",
	"so_car_sit_come_here_enter",
	"female_stand_idle1",
	"female_stand_idle2",
	"female_stand_idle3",
	"female_stand_idle4",
	"female_stand_idle5",
	"female_stand_idle6",
	"female_lean_fwd",
	"on_ground_hurt",
	"hiding_behind_car",
	"reviving_with_cpr",
	"revived_by_cpr",
	"take_care_wounded",
	"taken_cared",
	"Phone_booth",
	"stand_thug_idle",
	"sit_thug_idle1",
	"sit_thug_idle2",
	"sit_in_chopper_loop",
	"snorting_thug_idle",
	"so_climb_into_chopper",
	"so_enter_ejectionchair",
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
	"so_escort_fuckoff_loop",
	"female_dance",
	"female_dance2",
	"male_dance2",
	"male_dance",
	"male_dance_loop",
	"so_hiding_b1_idle",
	"so_hiding_b1_react",
	"so_hiding_b2_idle",
	"so_hiding_b2_react",
	"spawn_husk_hospital_var1",
	"spawn_husk_hospital_var2",
	"spawn_husk_hospital_var3",
	"spawn_husk_hospital_var4",
	"so_climb_into_chopper_scared",
	"pose01_c45_and_beretta",
	"pose02_c45",
	"pose03_c45_and_beretta",
	"pose04_c45_and_beretta",
	"pose05_c45_and_beretta",
	"pose06_revolver",
	"pose07_m4",
	"pose08_m4",
	"pose09_shotgun",
	"pose10_shotgun",
	"pose11_pistol_briefcase",
	"pose12_pistol_briefcase",
	"pose13_victim1",
	"pose14_victim2",
	"pose14_hostage2",
	"pose13_hostage1",
	"pose15_2sneek1",
	"pose15_2sneek2",
	"pose16_point",
	"pose17_point",
	"pose18_pistol_briefcase",
	"pose19_hostage3",
	"pose19_victim3",
	"pose20_hack_box",
	"pose21_plant_trip",
	"pose22_wait_melee",
	"pose23_wait_corner",
	"pose24_guard_sit",
	"pose25_pistol_whip",
	"pose26_m4supportedbycar",
	"pose27_m4sitaim",
	"pose28_m4reloadpose",
	"pose29_m4aimpose",
	"pose30_hk21shooting",
	"pose31_hk21scoutpose",
	"pose32_m4_deadcop",
	"pose33_m4_fallingcop",
	"pose34_pistol_host_pose",
	"pose35_pistol_ntl_pose",
	"pose36_rifle_host_pose",
	"pose37_rifle_cbt_pose",
	"pose38_mp5_ntl_pose",
	"pose39_shotgun_ntl_pose",
	"pose40_shield_ntl_pose",
	"pose41_pistol_host3_pose",
	"pose42_pistol_pose",
	"pose43_pistol_pose",
	"pose44_pistol_pose",
	"pose45_pistol_a_rifle_pose",
	"pose46_president_1",
	"pose47_president_2",
	"pose48_president_3",
	"so_prisonvan1_to_pnc",
	"so_prisonvan2_6_to_pnc",
	"so_prisonvan3_4_5_to_pnc",
	"so_escort_hurt_opens_door",
	"so_escort_before_door_enter",
	"spawn_behind_wall_jump_over",
	"so_repel_16m",
	"thug_boxer",
	"thug_boxer_coach",
	"piano_player_female",
	"workout_female",
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
	"so_open_door_to_stair",
	"doctor_enter_var1",
	"doctor_enter_var2",
	"doctor_enter_var3",
	"sit_smoking_female",
	"lying_female",
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
	"ss_intro_limo1_deal_idle",
	"ss_intro_limo1_deal_enter",
	"ss_intro_limo2_hood_idle",
	"ss_intro_limo2_trade_enter",
	"ss_intro_limo2_handsup_enter",
	"ss_intro_limo1_talk_idle",
	"ss_intro_limo1_trade_enter",
	"ss_intro_limo1_handsup_enter",
	"ss_intro_limo1_enter_limo",
	"ss_intro_limo1_short_enter_limo",
	"standing_female_talking",
	"waxing_boat",
	"sitting_female_idle",
	"female_calls_cop_suburbia",
	"female_checking_vail",
	"male_take_a_nap",
	"stand_drink_beer",
	"so_press_alarm",
	"so_press_alarm_low",
	"so_alert_guards",
	"sick_female_on_bed",
	"typing_female",
	"lying_on_stretcher",
	"so_check_patient",
	"walk_with_iv_stand"
}
function CopActionAct:init(action_desc, common_data)
	self._common_data = common_data
	self._action_desc = action_desc
	self._ext_base = common_data.ext_base
	self._ext_movement = common_data.ext_movement
	self._ext_anim = common_data.ext_anim
	self._unit = common_data.unit
	self._machine = common_data.machine
	self._host_expired = action_desc.host_expired
	self._skipped_frames = 0
	self._last_vel_z = 0
	self:_init_ik()
	self:_create_blocks_table(action_desc.blocks)
	if self._ext_anim.act_idle then
		self._blocks.walk = nil
	end
	if action_desc.needs_full_blend and self._ext_anim.idle and not self._ext_anim.idle_full_blend then
		self._waiting_full_blend = true
		self:_set_updator("_upd_wait_for_full_blend")
	elseif not self:_play_anim() then
		return
	end
	self:_sync_anim_play()
	self._ext_movement:enable_update()
	if self._host_expired and not self._waiting_full_blend then
		self._expired = true
	end
	return true
end
function CopActionAct:on_exit()
	if self._changed_driving then
		self._unit:set_driving("script")
		self._changed_driving = nil
		self._ext_movement:set_m_rot(self._unit:rotation())
		self._ext_movement:set_m_pos(self._unit:position())
	end
	self._ext_movement:drop_held_items()
	if self._ext_anim.stop_talk_on_action_exit then
		self._unit:sound():stop()
	end
	if self._modifier_on then
		self._modifier_on = nil
		self._machine:forbid_modifier(self._modifier_name)
	end
	if Network:is_client() then
		self._ext_movement:set_m_host_stop_pos(self._ext_movement:m_pos())
	elseif not self._expired then
		self._common_data.ext_network:send("action_act_end")
	end
end
function CopActionAct:_init_ik()
	self._look_vec = mvector3.copy(self._common_data.fwd)
	self._ik_update = callback(self, self, "_ik_update_func")
	self._m_head_pos = self._ext_movement:m_head_pos()
	self:on_attention(self._common_data.attention)
end
function CopActionAct:_ik_update_func(t)
	self:_update_ik_type()
	if self._attention and self._ik_type then
		local look_from_pos = self._m_head_pos
		self._look_vec = self._look_vec or mvector3.copy(self._common_data.fwd)
		local target_vec = self._look_vec
		if self._attention.unit then
			mvec3_set(target_vec, self._m_attention_head_pos)
			mvec3_sub(target_vec, look_from_pos)
		else
			mvec3_set(target_vec, self._attention.pos)
			mvec3_sub(target_vec, look_from_pos)
		end
		mvec3_set(tmp_vec1, target_vec)
		mvec3_set_z(tmp_vec1, 0)
		mvec3_norm(tmp_vec1)
		local fwd_dot = mvector3.dot(self._common_data.fwd, tmp_vec1)
		if fwd_dot < 0.2 then
			if self._modifier_on then
				self._modifier_on = nil
				self._machine:allow_modifier(self._modifier_name)
			end
		elseif not self._modifier_on then
			self._modifier_on = true
			self._machine:force_modifier(self._modifier_name)
			local old_look_vec = self._modifier_name == Idstring("look_head") and self._unit:get_object(Idstring("Head")):rotation():z() or self._unit:get_object(ids_aim):rotation():y()
			local duration = math.lerp(0.1, 1, target_vec:angle(old_look_vec) / 90)
			self._look_trans = {
				start_t = TimerManager:game():time(),
				duration = duration,
				start_vec = old_look_vec
			}
		end
		if self._look_trans then
			local look_trans = self._look_trans
			local prog = (t - look_trans.start_t) / look_trans.duration
			if 1 < prog then
				self._look_trans = nil
			else
				local end_vec
				if look_trans.end_vec then
					end_vec = look_trans.end_vec
				else
					end_vec = tmp_vec1
					mvec3_set(end_vec, target_vec)
					mvec3_norm(end_vec)
				end
				local prog_smooth = math.bezier({
					0,
					0,
					1,
					1
				}, prog)
				mvector3.lerp(target_vec, look_trans.start_vec, end_vec, prog_smooth)
			end
		end
		if self._modifier_on then
			self._modifier:set_target_z(target_vec)
		end
	elseif self._modifier_on then
		self._modifier_on = nil
		self._machine:allow_modifier(self._modifier_name)
	end
end
function CopActionAct:on_attention(attention)
	self:_update_ik_type()
	self._m_attention_head_pos = attention and attention.unit and attention.unit:movement():m_head_pos()
	self._attention = attention
	self._ext_movement:enable_update()
end
function CopActionAct:_update_ik_type()
	local new_ik_type = self._ext_anim.ik_type
	if self._ik_type ~= new_ik_type then
		if new_ik_type == "head" then
			self._ik_type = new_ik_type
			self._modifier_name = Idstring("look_head")
			self._modifier = self._machine:get_modifier(self._modifier_name)
		elseif new_ik_type == "upper_body" then
			self._ik_type = new_ik_type
			self._modifier_name = Idstring("look_upper_body")
			self._modifier = self._machine:get_modifier(self._modifier_name)
		else
			self._ik_type = nil
		end
	end
end
function CopActionAct:_upd_wait_for_full_blend()
	if not self._ext_anim.idle or self._ext_anim.idle_full_blend then
		self._waiting_full_blend = nil
		if not self:_play_anim() then
			if Network:is_server() then
				self._expired = true
				self._common_data.ext_network:send("action_act_end")
			end
			return
		end
		if self._host_expired then
			self._expired = true
		end
	end
end
function CopActionAct:_clamping_update(t)
	if self._ext_anim.act then
		local dt = TimerManager:game():delta_time()
		self._last_pos = CopActionHurt._get_pos_clamped_to_graph(self)
		CopActionWalk._set_new_pos(self, dt)
		local new_rot = self._unit:get_animation_delta_rotation()
		new_rot = self._common_data.rot * new_rot
		mrotation.set_yaw_pitch_roll(new_rot, new_rot:yaw(), 0, 0)
		self._ext_movement:set_rotation(new_rot)
	else
		self._expired = true
	end
	if self._ik_update then
		self._ik_update(t)
	end
end
function CopActionAct:update(t)
	if not self._ext_anim.act then
		self._expired = true
	end
	local vis_state = self._ext_base:lod_stage()
	vis_state = vis_state or 4
	if vis_state == 1 or self._freefall then
	elseif vis_state > self._skipped_frames then
		self._skipped_frames = self._skipped_frames + 1
		return
	else
		self._skipped_frames = 1
	end
	if self._ik_update then
		self._ik_update(t)
	end
	if self._freefall then
		if self._ext_anim.freefall then
			local pos_new = tmp_vec1
			local delta_pos = self._unit:get_animation_delta_position()
			self._unit:m_position(pos_new)
			mvec3_add(pos_new, delta_pos)
			self._ext_movement:upd_ground_ray(pos_new, true)
			local gnd_z = self._common_data.gnd_ray.position.z
			if gnd_z < pos_new.z then
				self._last_vel_z = CopActionWalk._apply_freefall(pos_new, self._last_vel_z, gnd_z, TimerManager:game():delta_time())
			else
				if gnd_z > pos_new.z then
					mvec3_set_z(pos_new, gnd_z)
				end
				self._last_vel_z = 0
			end
			local new_rot = self._unit:get_animation_delta_rotation()
			new_rot = self._common_data.rot * new_rot
			mrotation.set_yaw_pitch_roll(new_rot, new_rot:yaw(), 0, 0)
			self._ext_movement:set_rotation(new_rot)
			self._ext_movement:set_position(pos_new)
		else
			self._freefall = nil
			self._last_vel_z = nil
			self._unit:set_driving("animation")
			self._changed_driving = true
		end
	else
		self._ext_movement:set_m_rot(self._unit:rotation())
		self._ext_movement:set_m_pos(self._unit:position())
	end
end
function CopActionAct:type()
	return "act"
end
function CopActionAct:expired()
	return self._expired
end
function CopActionAct:save(save_data)
	for k, v in pairs(self._action_desc) do
		save_data[k] = v
	end
	save_data.blocks = save_data.blocks or {
		act = -1,
		walk = -1,
		action = -1
	}
	save_data.start_anim_time = self._machine:segment_real_time(Idstring("base"))
	if save_data.variant then
		local state_name = self._machine:segment_state(Idstring("base"))
		local state_index = self._machine:state_name_to_index(state_name)
		save_data.variant = state_index
	end
end
function CopActionAct:need_upd()
	return self._attention or self._waiting_full_blend
end
function CopActionAct:chk_block(action_type, t)
	local unblock_t = self._blocks[action_type]
	return unblock_t and (unblock_t == -1 or t < unblock_t)
end
function CopActionAct:_create_blocks_table(block_desc)
	local blocks = self._blocks or {}
	if block_desc then
		local t = TimerManager:game():time()
		for action_type, block_duration in pairs(block_desc) do
			blocks[action_type] = block_duration == -1 and -1 or t + block_duration
		end
	end
	self._blocks = blocks
end
function CopActionAct:_get_act_index(anim_name)
	for action_index, action_name in ipairs(self._act_redirects) do
		if action_name == anim_name then
			return action_index
		end
	end
	for action_index, action_name in ipairs(self._civilian_actions) do
		if action_name == anim_name then
			return #self._act_redirects + action_index
		end
	end
	debug_pause("[CopActionAct:_get_act_index] animation", anim_name, "not found on look-up table.")
end
function CopActionAct:_get_act_name_from_index(index)
	if index > #self._act_redirects then
		return self._civilian_actions[index - #self._act_redirects]
	else
		return self._act_redirects[index]
	end
end
function CopActionAct:_play_anim()
	local redir_name, redir_res
	if type(self._action_desc.variant) == "number" then
		redir_name = self._machine:index_to_state_name(self._action_desc.variant)
		redir_res = self._ext_movement:play_state_idstr(redir_name, self._action_desc.start_anim_time)
	else
		redir_name = self._action_desc.variant
		redir_res = self._ext_movement:play_redirect(redir_name, self._action_desc.start_anim_time)
	end
	if not redir_res then
		debug_pause_unit(self._unit, "[CopActionAct:init] redirect", redir_name, "failed in", self._machine:segment_state(Idstring("base")), self._unit)
		self._expired = true
		return
	end
	if Network:is_client() and self._action_desc.start_rot then
		self._ext_movement:set_rotation(self._action_desc.start_rot)
		self._ext_movement:set_position(self._action_desc.start_pos)
	end
	if self._action_desc.clamp_to_graph then
		self:_set_updator("_clamping_update")
	else
		if not self._ext_anim.freefall then
			self._unit:set_driving("animation")
			self._changed_driving = true
		end
		self:_set_updator()
	end
	if self._ext_anim.freefall then
		self._freefall = true
		self._last_vel_z = 0
	end
	self._ext_movement:set_root_blend(false)
	self._ext_movement:spawn_wanted_items()
	if self._ext_anim.ik_type then
		self:_update_ik_type()
	end
	return true
end
function CopActionAct:_sync_anim_play()
	if Network:is_server() then
		local action_index = self:_get_act_index(self._action_desc.variant)
		if action_index then
			if self._action_desc.align_sync then
				local yaw = mrotation.yaw(self._common_data.rot)
				if yaw < 0 then
					yaw = 360 + yaw
				end
				local sync_yaw = 1 + math.ceil(yaw * 254 / 360)
				self._common_data.ext_network:send("action_act_start_align", action_index, self._blocks.heavy_hurt and true or false, sync_yaw, mvector3.copy(self._common_data.pos))
			else
				self._common_data.ext_network:send("action_act_start", action_index, self._blocks.heavy_hurt and true or false)
			end
		else
			print("[CopActionAct:_sync_anim_play] redirect", self._action_desc.variant, "not found")
		end
	end
end
function CopActionAct:_set_updator(func_name)
	self.update = func_name and self[func_name] or nil
end
CopActionAct._apply_freefall = CopActionWalk._apply_freefall
