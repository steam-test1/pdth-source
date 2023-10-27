require("lib/units/enemies/cop/logics/CopLogicIdle")
require("lib/units/enemies/cop/logics/CopLogicTravel")
local tmp_vec1 = Vector3()
local tmp_vec2 = Vector3()
local tmp_vec3 = Vector3()
TeamAILogicIdle = TeamAILogicIdle or class(TeamAILogicBase)
function TeamAILogicIdle.enter(data, new_logic_name, enter_params)
	TeamAILogicBase.enter(data, new_logic_name, enter_params)
	local my_data = {
		unit = data.unit
	}
	my_data.detection = tweak_data.character[data.unit:base()._tweak_table].detection.idle
	my_data.enemy_detect_slotmask = managers.slot:get_mask("enemies")
	my_data.ai_visibility_slotmask = managers.slot:get_mask("AI_visibility")
	my_data.rsrv_pos = {}
	local old_internal_data = data.internal_data
	if old_internal_data then
		my_data.detected_enemies = old_internal_data.detected_enemies or {}
		my_data.rsrv_pos = old_internal_data.rsrv_pos or my_data.rsrv_pos
		if old_internal_data.best_cover then
			my_data.best_cover = old_internal_data.best_cover
			managers.navigation:reserve_cover(my_data.best_cover[1], data.pos_rsrv_id)
		end
		if old_internal_data.nearest_cover then
			my_data.nearest_cover = old_internal_data.nearest_cover
			managers.navigation:reserve_cover(my_data.nearest_cover[1], data.pos_rsrv_id)
		end
	else
		my_data.detected_enemies = {}
	end
	data.internal_data = my_data
	local key_str = tostring(data.unit:key())
	if not data.unit:movement():cool() then
		my_data.detection_task_key = "TeamAILogicIdle._update_enemy_detection" .. key_str
		CopLogicBase.queue_task(my_data, my_data.detection_task_key, TeamAILogicIdle._update_enemy_detection, data, data.t)
	end
	if my_data.nearest_cover or my_data.best_cover then
		my_data.cover_update_task_key = "CopLogicIdle._update_cover" .. key_str
		CopLogicBase.add_delayed_clbk(my_data, my_data.cover_update_task_key, callback(CopLogicTravel, CopLogicTravel, "_update_cover", data), data.t + 1)
	end
	my_data.stare_path_search_id = "stare" .. key_str
	my_data.relocate_chk_t = 0
	CopLogicBase._reset_attention(data)
	data.unit:movement():set_allow_fire(false)
	if managers.groupai:state():player_weapons_hot() then
		data.unit:movement():set_stance("hos")
	end
	local objective = data.objective
	local entry_action = enter_params and enter_params.action
	if objective then
		if objective.type == "revive" then
			if objective.action_start_clbk then
				objective.action_start_clbk(data.unit)
			end
			local success
			local revive_unit = objective.follow_unit
			if revive_unit:interaction() then
				if revive_unit:interaction():active() and data.unit:brain():action_request(objective.action) then
					revive_unit:interaction():interact_start(data.unit)
					success = true
				end
			elseif revive_unit:character_damage():arrested() then
				if data.unit:brain():action_request(objective.action) then
					revive_unit:character_damage():pause_arrested_timer()
					success = true
				end
			elseif revive_unit:character_damage():need_revive() and data.unit:brain():action_request(objective.action) then
				revive_unit:character_damage():pause_downed_timer()
				success = true
			end
			if success then
				my_data.performing_act_objective = objective
				my_data.reviving = revive_unit
				my_data.acting = true
				my_data.revive_complete_clbk_id = "TeamAILogicIdle_revive" .. tostring(data.key)
				local revive_t = TimerManager:game():time() + (objective.interact_delay or 0)
				CopLogicBase.add_delayed_clbk(my_data, my_data.revive_complete_clbk_id, callback(TeamAILogicIdle, TeamAILogicIdle, "clbk_revive_complete", data), revive_t)
				if not revive_unit:character_damage():arrested() then
					local suffix = "a"
					local downed_time = revive_unit:character_damage():down_time()
					if downed_time <= tweak_data.player.damage.DOWNED_TIME_MIN then
						suffix = "c"
					elseif downed_time <= tweak_data.player.damage.DOWNED_TIME / 2 + tweak_data.player.damage.DOWNED_TIME_DEC then
						suffix = "b"
					end
					data.unit:sound():say("s09" .. suffix, true)
				end
			else
				data.unit:brain():set_objective()
				return
			end
		elseif objective.type == "act" then
			if data.unit:brain():action_request(objective.action) then
				my_data.acting = true
			end
			my_data.performing_act_objective = objective
			if objective.action_start_clbk then
				objective.action_start_clbk(data.unit)
			end
		elseif objective.type == "follow" then
		end
		if objective.scan then
			my_data.scan = true
			if not my_data.acting then
				my_data.wall_stare_task_key = "CopLogicIdle._chk_stare_into_wall" .. tostring(data.key)
				CopLogicBase.queue_task(my_data, my_data.wall_stare_task_key, CopLogicIdle._chk_stare_into_wall_1, data, data.t)
			end
		end
	end
end
function TeamAILogicIdle.exit(data, new_logic_name, enter_params)
	TeamAILogicBase.exit(data, new_logic_name, enter_params)
	local my_data = data.internal_data
	if my_data.delayed_clbks and my_data.delayed_clbks[my_data.revive_complete_clbk_id] then
		local revive_unit = my_data.reviving
		if alive(revive_unit) then
			if revive_unit:interaction() then
				revive_unit:interaction():interact_interupt(data.unit)
			elseif revive_unit:character_damage():arrested() then
				revive_unit:character_damage():unpause_arrested_timer()
			elseif revive_unit:character_damage():need_revive() then
				revive_unit:character_damage():unpause_downed_timer()
			end
		end
		my_data.performing_act_objective = nil
		local crouch_action = {
			type = "act",
			body_part = 1,
			variant = "crouch",
			blocks = {
				action = -1,
				walk = -1,
				hurt = -1,
				heavy_hurt = -1,
				aim = -1
			}
		}
		data.unit:movement():action_request(crouch_action)
	end
	data.unit:brain():cancel_all_pathing_searches()
	CopLogicBase.cancel_queued_tasks(my_data)
	CopLogicBase.cancel_delayed_clbks(my_data)
	if my_data.best_cover then
		managers.navigation:release_cover(my_data.best_cover[1])
	end
	if my_data.nearest_cover then
		managers.navigation:release_cover(my_data.nearest_cover[1])
	end
	local rsrv_pos = my_data.rsrv_pos
	if rsrv_pos.path then
		managers.navigation:unreserve_pos(rsrv_pos.path)
		rsrv_pos.path = nil
	end
	if rsrv_pos.move_dest then
		managers.navigation:unreserve_pos(rsrv_pos.move_dest)
		rsrv_pos.move_dest = nil
	end
end
function TeamAILogicIdle.update(data)
	local my_data = data.internal_data
	CopLogicIdle._upd_pathing(data, my_data)
	CopLogicIdle._upd_scan(data, my_data)
	local objective = data.objective
	if objective then
		if not my_data.acting then
			if objective.type == "follow" then
				if my_data.relocation_pathing then
					TeamAILogicIdle._check_should_relocate(data, my_data, objective)
				elseif my_data.should_relocate then
					objective.in_place = nil
					TeamAILogicBase._exit(data.unit, "travel")
				elseif data.t > my_data.relocate_chk_t then
					TeamAILogicIdle._calculate_should_relocate(data, my_data, objective)
				end
			elseif objective.type == "revive" then
				objective.in_place = nil
				TeamAILogicBase._exit(data.unit, "travel")
			end
		end
	else
		managers.groupai:state():on_criminal_jobless(data.unit)
	end
end
function TeamAILogicIdle._detect_enemies(data, my_data)
	local delay = 1
	local enemies = managers.enemy:all_enemies()
	local my_engaged_enemies = managers.groupai:state():all_AI_criminals()[data.key].engaged
	local my_tracker = data.unit:movement():nav_tracker()
	local chk_vis_func = my_tracker.check_visibility
	for e_key, enemy_data in pairs(enemies) do
		local enemy_unit = enemy_data.unit
		if enemy_unit:anim_data().surrender or enemy_unit:brain()._current_logic_name == "trade" then
			my_data.detected_enemies[e_key] = nil
		elseif my_data.detected_enemies[e_key] then
			local enemy_data = my_data.detected_enemies[e_key]
			local visible
			local my_pos = data.unit:movement():m_head_pos()
			local enemy_pos = enemy_data.m_head_pos
			local vis_ray = World:raycast("ray", my_pos, enemy_pos, "slot_mask", my_data.ai_visibility_slotmask, "ray_type", "ai_vision")
			if not vis_ray then
				visible = true
			end
			enemy_data.mark_t = enemy_unit:brain()._mark_t
			enemy_data.verified = visible
			if visible then
				delay = math.min(0.6, delay)
				enemy_data.verified_t = data.t
				mvector3.set(enemy_data.verified_pos, enemy_pos)
				enemy_data.verified_dis = mvector3.distance(enemy_pos, my_pos)
			else
				local verified_pos = enemy_data.verified_pos
				if mvector3.distance(enemy_pos, verified_pos) > 700 then
					enemy_unit:base():remove_destroy_listener(enemy_data.destroy_clbk_key)
					my_data.detected_enemies[e_key] = nil
				else
					delay = math.min(0.2, delay)
					enemy_data.verified_dis = mvector3.distance(enemy_data.verified_pos, my_pos)
				end
			end
		elseif my_engaged_enemies[e_key] then
			local enemy_data = CopLogicAttack._create_detected_enemy_data(data, enemy_unit)
			enemy_data.mark_t = enemy_unit:brain()._mark_t
			my_data.detected_enemies[e_key] = enemy_data
		elseif chk_vis_func(my_tracker, enemy_data.tracker) then
			local my_pos = data.unit:movement():m_head_pos()
			local enemy_pos = enemy_unit:movement():m_head_pos()
			local enemy_vec = enemy_pos - my_pos
			local enemy_dis = mvector3.normalize(enemy_vec)
			local dis_multiplier, angle_multiplier
			dis_multiplier = enemy_dis / my_data.detection.dis_max
			if dis_multiplier < 1 then
				delay = math.min(delay, dis_multiplier)
				local my_fwd = data.unit:movement():m_head_rot():z()
				local enemy_dot = mvector3.dot(my_fwd, enemy_vec)
				local enemy_angle = math.acos(enemy_dot)
				local max_angle = math.lerp(180, my_data.detection.angle_max, math.clamp((enemy_dis - 150) / 600, 0, 1))
				angle_multiplier = enemy_angle / max_angle
				if angle_multiplier < 1 and not World:raycast("ray", my_pos, enemy_pos, "slot_mask", my_data.ai_visibility_slotmask, "ray_type", "ai_vision", "report") then
					local enemy_data = CopLogicAttack._create_detected_enemy_data(data, enemy_unit)
					enemy_data.verified_t = data.t
					enemy_data.verified = true
					enemy_data.mark_t = enemy_unit:brain()._mark_t
					my_data.detected_enemies[e_key] = enemy_data
				end
			end
		end
	end
	return delay
end
function TeamAILogicIdle.on_detected_enemy_destroyed(data, enemy_unit)
	TeamAILogicIdle.on_cop_neutralized(data, enemy_unit:key())
end
function TeamAILogicIdle.on_cop_neutralized(data, cop_key)
	local my_data = data.internal_data
	my_data.detected_enemies[cop_key] = nil
	if my_data.focus_enemy and my_data.focus_enemy.unit:key() == cop_key then
		my_data.focus_enemy = nil
		if my_data.firing then
			data.unit:movement():set_allow_fire(false)
			my_data.firing = nil
		end
	end
end
function TeamAILogicIdle.damage_clbk(data, damage_info)
	local enemy = damage_info.attacker_unit
	local my_data = data.internal_data
	if enemy and enemy:in_slot(my_data.enemy_detect_slotmask) then
		local enemy_key = enemy:key()
		local enemy_data = my_data.detected_enemies[enemy_key]
		local t = TimerManager:game():time()
		if enemy_data then
			enemy_data.verified_t = t
			enemy_data.verified = true
			enemy_data.alert_t = t
			enemy_data.dmg_t = t
			enemy_data.verified_pos = mvector3.copy(enemy:movement():m_stand_pos())
			enemy_data.verified_dis = mvector3.distance(enemy_data.verified_pos, data.unit:movement():m_stand_pos())
		else
			local enemy_data = CopLogicAttack._create_detected_enemy_data(data, enemy)
			enemy_data.verified_t = t
			enemy_data.alert_t = t
			enemy_data.dmg_t = t
			enemy_data.verified = true
			my_data.detected_enemies[enemy_key] = enemy_data
		end
		my_data.alert_t = t
	end
	if damage_info.result.type == "bleedout" or damage_info.variant == "tase" then
		CopLogicBase._exit(data.unit, "disabled")
	end
end
function TeamAILogicIdle.on_objective_unit_damaged(data, unit, attacker_unit)
	if attacker_unit ~= nil then
		TeamAILogicIdle.on_alert(data, {
			nil,
			nil,
			nil,
			attacker_unit
		})
	end
end
function TeamAILogicIdle.on_alert(data, alert_data)
	local enemy = alert_data[4]
	local my_data = data.internal_data
	local enemy_key = enemy:key()
	local enemy_data = my_data.detected_enemies[enemy_key]
	local t = TimerManager:game():time()
	if enemy_data then
		enemy_data.verified_pos = mvector3.copy(enemy:movement():m_stand_pos())
		enemy_data.verified_dis = mvector3.distance(enemy_data.verified_pos, data.unit:movement():m_stand_pos())
		enemy_data.alert_t = t
	else
		local enemy_data = CopLogicAttack._create_detected_enemy_data(data, enemy)
		enemy_data.alert_t = t
		my_data.detected_enemies[enemy_key] = enemy_data
	end
	my_data.alert_t = t
end
function TeamAILogicIdle.on_long_dis_interacted(data, other_unit)
	local objective_type, objective_action, interrupt
	if other_unit:base().is_local_player then
		if other_unit:character_damage():need_revive() then
			objective_type = "revive"
			objective_action = "revive"
		elseif other_unit:character_damage():arrested() then
			objective_type = "revive"
			objective_action = "untie"
		else
			objective_type = "follow"
		end
	elseif other_unit:movement():need_revive() then
		objective_type = "revive"
		if other_unit:movement():current_state_name() == "arrested" then
			objective_action = "untie"
		else
			objective_action = "revive"
		end
	else
		objective_type = "follow"
	end
	local objective
	if objective_type == "follow" then
		objective = {
			type = objective_type,
			follow_unit = other_unit,
			called = true,
			destroy_clbk_key = false,
			scan = true
		}
		data.unit:sound():say("r01x_sin", true)
	else
		local followup_objective = {
			type = "act",
			scan = true,
			action = {
				type = "act",
				body_part = 1,
				variant = "crouch",
				blocks = {
					action = -1,
					walk = -1,
					hurt = -1,
					heavy_hurt = -1,
					aim = -1
				}
			}
		}
		objective = {
			type = "revive",
			follow_unit = other_unit,
			called = true,
			destroy_clbk_key = false,
			nav_seg = other_unit:movement():nav_tracker():nav_segment(),
			scan = true,
			action = {
				type = "act",
				variant = objective_action,
				body_part = 1,
				blocks = {
					action = -1,
					walk = -1,
					hurt = -1,
					light_hurt = -1,
					heavy_hurt = -1,
					aim = -1
				},
				align_sync = true
			},
			interact_delay = tweak_data.interaction[objective_action == "untie" and "free" or objective_action].timer,
			followup_objective = followup_objective
		}
		data.unit:sound():say("r02a_sin", true)
	end
	data.unit:brain():set_objective(objective)
end
function TeamAILogicIdle.on_new_objective(data, old_objective)
	local new_objective = data.objective
	TeamAILogicBase.on_new_objective(data, old_objective)
	local my_data = data.internal_data
	if not my_data.exiting then
		if new_objective then
			if (new_objective.nav_seg or new_objective.follow_unit) and not new_objective.in_place then
				CopLogicBase._exit(data.unit, "travel")
			else
				CopLogicBase._exit(data.unit, "idle")
			end
		else
			CopLogicBase._exit(data.unit, "idle")
		end
	else
		debug_pause("[TeamAILogicIdle.on_new_objective] Already exiting", data.name, data.unit, old_objective and inspect(old_objective), new_objective and inspect(new_objective))
	end
	if old_objective and old_objective.fail_clbk then
		old_objective.fail_clbk()
	end
end
function TeamAILogicIdle._update_enemy_detection(data)
	data.t = TimerManager:game():time()
	local my_data = data.internal_data
	local delay = TeamAILogicIdle._detect_enemies(data, my_data)
	local enemies = my_data.detected_enemies
	local focus_enemy, focus_type, focus_enemy_key
	local target, threat = TeamAILogicAssault._get_priority_enemy(data, enemies)
	if target then
		focus_enemy = target.enemy_data
		focus_type = target.reaction
		focus_enemy_key = target.key
	end
	if focus_enemy then
		my_data.focus_enemy = focus_enemy
		my_data.focus_type = focus_type
		local exit_state
		if my_data.performing_act_objective then
			local interrupt = my_data.performing_act_objective.interrupt_on
			if interrupt == "contact" then
				exit_state = focus_type
			elseif interrupt == "obstructed" then
				if TeamAILogicIdle.is_obstructed(data, data.objective) then
					exit_state = focus_type
				end
				local objective = data.objective.type
				if objective.type == "revive" then
					local revive_unit = objective.follow_unit
					local timer
					if revive_unit:base().is_local_player then
						timer = revive_unit:character_damage()._downed_timer
					elseif revive_unit:interaction().get_waypoint_time then
						timer = revive_unit:interaction():get_waypoint_time()
					end
					if timer and timer <= 10 then
						exit_state = nil
					end
				end
			end
		else
			exit_state = focus_type
		end
		if exit_state then
			my_data.detection_task_key = nil
			my_data.focus_enemy = focus_enemy
			my_data.focus_type = focus_type
			my_data.exiting = true
			if data.objective and data.objective.type ~= "follow" then
				managers.groupai:state():on_criminal_objective_failed(data.unit, data.objective, true)
				local old_objective = data.objective
				data.objective = nil
				CopLogicBase.on_new_objective(data, old_objective)
			end
			if my_data == data.internal_data then
				CopLogicBase._exit(data.unit, exit_state)
			end
			return
		end
	end
	if (not my_data._intimidate_t or my_data._intimidate_t + 2 < data.t) and not my_data._turning_to_intimidate and not my_data.acting then
		local can_turn = not data.unit:movement():chk_action_forbidden("walk")
		local civ = TeamAILogicIdle.find_civilian_to_intimidate(data.unit, can_turn and 180 or 90, 1200)
		if civ then
			my_data._intimidate_t = data.t
			if can_turn and CopLogicAttack._chk_request_action_turn_to_enemy(data, my_data, data.m_pos, civ:movement():m_pos()) then
				my_data._turning_to_intimidate = true
				my_data._primary_intimidation_target = civ
			else
				TeamAILogicIdle.intimidate_civilians(data, data.unit, true, true)
			end
		end
	end
	CopLogicBase.queue_task(my_data, my_data.detection_task_key, TeamAILogicIdle._update_enemy_detection, data, data.t + delay)
end
function TeamAILogicIdle.find_civilian_to_intimidate(criminal, max_angle, max_dis)
	local best_civ = TeamAILogicIdle._find_intimidateable_civilians(criminal, false, max_angle, max_dis)
	return best_civ
end
function TeamAILogicIdle._find_intimidateable_civilians(criminal, use_default_shout_shape, max_angle, max_dis)
	local head_pos = criminal:movement():m_head_pos()
	local look_vec = criminal:movement():m_rot():y()
	local close_dis = 400
	local intimidateable_civilians = {}
	local best_civ
	local best_civ_wgt = false
	local best_civ_angle
	local highest_wgt = 1
	local my_tracker = criminal:movement():nav_tracker()
	local chk_vis_func = my_tracker.check_visibility
	for key, unit in pairs(managers.groupai:state():fleeing_civilians()) do
		if chk_vis_func(my_tracker, unit:movement():nav_tracker()) and tweak_data.character[unit:base()._tweak_table].intimidateable and not unit:base().unintimidateable and not unit:anim_data().unintimidateable then
			local u_head_pos = unit:movement():m_head_pos() + math.UP * 30
			local vec = u_head_pos - head_pos
			local dis = mvector3.normalize(vec)
			local angle = vec:angle(look_vec)
			if use_default_shout_shape then
				max_angle = math.max(8, math.lerp(90, 30, dis / 1200))
				max_dis = 1200
			end
			if close_dis > dis or dis < max_dis and angle < max_angle then
				local slotmask = managers.slot:get_mask("AI_visibility")
				local ray = World:raycast("ray", head_pos, u_head_pos, "slot_mask", slotmask, "ray_type", "ai_vision")
				if not ray then
					local inv_wgt = dis * dis * (1 - vec:dot(look_vec))
					table.insert(intimidateable_civilians, {
						unit = unit,
						key = key,
						inv_wgt = inv_wgt
					})
					if not best_civ_wgt or best_civ_wgt > inv_wgt then
						best_civ_wgt = inv_wgt
						best_civ = unit
						best_civ_angle = angle
					end
					if highest_wgt < inv_wgt then
						highest_wgt = inv_wgt
					end
				end
			end
		end
	end
	return best_civ, highest_wgt, intimidateable_civilians
end
function TeamAILogicIdle.intimidate_civilians(data, criminal, play_sound, play_action, primary_target)
	local best_civ, highest_wgt, intimidateable_civilians = TeamAILogicIdle._find_intimidateable_civilians(criminal, true)
	local plural = false
	if 1 < #intimidateable_civilians then
		plural = true
	elseif #intimidateable_civilians <= 0 then
		return false
	end
	local act_name, sound_name
	local sound_suffix = plural and "plu" or "sin"
	if best_civ:anim_data().move then
		act_name = "stop"
		sound_name = "f02x_" .. sound_suffix
	else
		act_name = "arrest"
		sound_name = "f02x_" .. sound_suffix
	end
	if play_sound then
		criminal:sound():say(sound_name, true)
	end
	if play_action and not criminal:movement():chk_action_forbidden("action") then
		local new_action = {
			type = "act",
			variant = act_name,
			body_part = 3,
			align_sync = true
		}
		if criminal:brain():action_request(new_action) then
			data.internal_data.gesture_arrest = true
		end
	end
	local intimidated_primary_target = false
	for _, civ in ipairs(intimidateable_civilians) do
		local amount = civ.inv_wgt / highest_wgt
		if best_civ == civ.unit then
			amount = 1
		end
		if primary_target == civ.unit then
			intimidated_primary_target = true
			amount = 1
		end
		civ.unit:brain():on_intimidated(amount, criminal)
	end
	if not intimidated_primary_target and primary_target then
		primary_target:brain():on_intimidated(1, criminal)
	end
	return primary_target or best_civ
end
function TeamAILogicIdle.action_complete_clbk(data, action)
	local my_data = data.internal_data
	local action_type = action:type()
	if action_type == "turn" then
		data.internal_data.turning = nil
		if my_data._turning_to_intimidate then
			my_data._turning_to_intimidate = nil
			TeamAILogicIdle.intimidate_civilians(data, data.unit, true, true, my_data._primary_intimidation_target)
			my_data._primary_intimidation_target = nil
		end
	elseif action_type == "act" then
		my_data.acting = nil
		if my_data.scan and not my_data.exiting and (not my_data.queued_tasks or not my_data.queued_tasks[my_data.wall_stare_task_key]) and not my_data.stare_path_pos then
			my_data.wall_stare_task_key = "CopLogicIdle._chk_stare_into_wall" .. tostring(data.unit:key())
			CopLogicBase.queue_task(my_data, my_data.wall_stare_task_key, CopLogicIdle._chk_stare_into_wall_1, data, data.t)
		end
		if my_data.performing_act_objective then
			local old_objective = my_data.performing_act_objective
			my_data.performing_act_objective = nil
			if my_data.delayed_clbks and my_data.delayed_clbks[my_data.revive_complete_clbk_id] then
				CopLogicBase.cancel_delayed_clbk(my_data, my_data.revive_complete_clbk_id)
				my_data.revive_complete_clbk_id = nil
				local revive_unit = my_data.reviving
				if revive_unit:interaction() then
					if revive_unit:interaction():active() then
						revive_unit:interaction():interact_interupt(data.unit)
					end
				elseif revive_unit:character_damage():arrested() then
					revive_unit:character_damage():unpause_arrested_timer()
				elseif revive_unit:character_damage():need_revive() then
					revive_unit:character_damage():unpause_downed_timer()
				end
				my_data.reviving = nil
				managers.groupai:state():on_criminal_objective_failed(data.unit, old_objective)
			elseif action:expired() then
				managers.groupai:state():on_criminal_objective_complete(data.unit, old_objective)
			else
				managers.groupai:state():on_criminal_objective_failed(data.unit, old_objective)
			end
		end
	end
end
function TeamAILogicIdle.is_available_for_assignment(data, new_objective)
	if data.internal_data.exiting then
		return
	elseif data.objective then
		if data.internal_data.performing_act_objective and not data.unit:anim_data().act_idle then
			return
		end
		if new_objective and new_objective.interrupt_on == "obstructed" and TeamAILogicIdle.is_obstructed_strict(data, new_objective) then
			return
		end
		local old_objective_type = data.objective.type
		if not new_objective then
		elseif old_objective_type == "revive" then
			return
		elseif old_objective_type == "follow" and data.objective.called then
			return
		end
	end
	return true
end
function TeamAILogicIdle.is_obstructed_strict(data, objective)
	local my_data = data.internal_data
	if my_data.focus_enemy then
		if not my_data.focus_enemy.verified and my_data.focus_enemy.verified_dis < 500 and math.abs(my_data.focus_enemy.m_pos.z - data.m_pos.z) < 350 then
			return true
		end
		if my_data.focus_enemy.verified and mvector3.distance(my_data.focus_enemy.m_pos, data.m_pos) < 800 and math.abs(my_data.focus_enemy.m_pos.z - data.m_pos.z) < 300 then
			return true
		end
		if my_data.focus_enemy.dmg_t and data.t - my_data.focus_enemy.dmg_t < 7.5 and objective.interrupt_dmg_ratio and data.unit:character_damage():health_ratio() < (objective and objective.interrupt_dmg_ratio ^ 0.5 or 1) then
			return true
		end
	end
	return false
end
function TeamAILogicIdle.clbk_heat(data)
	local inventory = data.unit:inventory()
	if not inventory:is_selection_available(2) then
		inventory:add_unit_by_name(Idstring("units/weapons/m4_rifle_npc/m4_rifle_npc"), false, false)
	end
	if not inventory:is_selection_available(3) then
		inventory:add_unit_by_name(Idstring("units/weapons/r870_shotgun_npc/r870_shotgun_npc"), false, false)
	end
	if not inventory:is_selection_available(4) then
		inventory:add_unit_by_name(Idstring("units/weapons/mp5_npc/mp5_npc"), false, false)
	end
end
function TeamAILogicIdle.dodge(data)
	local my_data = data.internal_data
	if (not my_data.performing_act_objective or my_data.performing_act_objective.interrupt_on == "contact") and not data.unit:movement():chk_action_forbidden("walk") then
		return TeamAILogicIdle.try_dodge(data)
	end
end
function TeamAILogicIdle.try_dodge(data)
	local action_data = CopActionDodge.try_dodge(data.unit, 2)
	if action_data then
		return data.unit:movement():action_request(action_data)
	end
	return nil
end
function TeamAILogicIdle.clbk_revive_complete(ignore_this, data)
	local my_data = data.internal_data
	CopLogicBase.on_delayed_clbk(my_data, my_data.revive_complete_clbk_id)
	my_data.revive_complete_clbk_id = nil
	local revive_unit = my_data.reviving
	my_data.reviving = nil
	if alive(revive_unit) then
		managers.groupai:state():on_criminal_objective_complete(data.unit, my_data.performing_act_objective)
		if revive_unit:interaction() then
			if revive_unit:interaction():active() then
				revive_unit:interaction():interact(data.unit)
			end
		elseif revive_unit:character_damage() and (revive_unit:character_damage():need_revive() or revive_unit:character_damage():arrested()) then
			local hint = revive_unit:character_damage():need_revive() and 2 or 3
			managers.network:session():send_to_peers_synched("sync_teammate_helped_hint", hint, revive_unit, data.unit)
			revive_unit:character_damage():revive(data.unit)
		end
	else
		print("[TeamAILogicIdle.clbk_revive_complete] Revive unit dead.", revive_unit, data.unit)
		managers.groupai:state():on_criminal_objective_failed(data.unit, my_data.performing_act_objective)
	end
end
function TeamAILogicIdle._calculate_should_relocate(data, my_data, objective)
	if my_data.relocation_pathing then
		return
	end
	local unit = data.unit
	my_data.relocation_search_id = tostring(data.key) .. "relocation_check"
	unit:brain():search_for_path_to_unit(my_data.relocation_search_id, objective.follow_unit)
	my_data.relocation_pathing = true
	my_data.should_relocate = false
	my_data.relocate_chk_t = data.t + (data.unit:movement():cool() and 3 or 6)
end
function TeamAILogicIdle._check_should_relocate(data, my_data, objective)
	if data.pathing_results then
		local path = data.pathing_results[my_data.relocation_search_id]
		if path then
			data.pathing_results[my_data.relocation_search_id] = nil
			if not next(data.pathing_results) then
				data.pathing_results = nil
			end
			my_data.relocation_pathing = false
			if path ~= "failed" then
				my_data.should_relocate = false
				local max_len = 800
				for i = 1, #path - 1 do
					max_len = max_len - mvector3.distance(CopLogicIdle._nav_point_pos(path[i]), CopLogicIdle._nav_point_pos(path[i + 1]))
					if max_len < 0 then
						my_data.should_relocate = true
						break
					end
				end
			else
				my_data.should_relocate = true
				print("[TeamAILogicIdle._check_should_relocate] relocation path failed")
			end
		end
	end
end
function TeamAILogicIdle.is_obstructed(data, objective)
	return CopLogicAttack.is_obstructed(data, objective)
end
function TeamAILogicIdle._chk_is_enemy_nearly_visible(data, focus_enemy)
	local my_data = data.internal_data
	local nearly_visible
	if not focus_enemy.visible then
		local my_pos = data.unit:movement():m_head_pos()
		local enemy_pos = focus_enemy.m_head_pos
		if data.unit:anim_data().crouch then
			mvector3.set(tmp_vec1, my_pos)
			mvector3.set_z(tmp_vec1, mvector3.z(tmp_vec1) + 50)
			mvector3.step(tmp_vec2, tmp_vec1, enemy_pos, 300)
			local vis_ray_up = World:raycast("ray", tmp_vec1, tmp_vec2, "slot_mask", my_data.ai_visibility_slotmask, "ray_type", "ai_vision")
			if not vis_ray_up then
				nearly_visible = true
			end
		end
		if not nearly_visible then
			mvector3.set(tmp_vec1, enemy_pos)
			mvector3.subtract(tmp_vec1, my_pos)
			mvector3.cross(tmp_vec1, tmp_vec1, math.UP)
			mvector3.set_length(tmp_vec1, 150)
			mvector3.set(tmp_vec3, tmp_vec1)
			mvector3.add(tmp_vec3, my_pos)
			mvector3.step(tmp_vec2, tmp_vec3, enemy_pos, 300)
			local vis_ray_r = World:raycast("ray", tmp_vec3, tmp_vec2, "slot_mask", my_data.ai_visibility_slotmask, "ray_type", "ai_vision", "report")
			if not vis_ray_r then
				nearly_visible = true
			end
		end
		if not nearly_visible then
			mvector3.negate(tmp_vec1, -1)
			mvector3.add(tmp_vec1, my_pos)
			mvector3.step(tmp_vec2, tmp_vec1, enemy_pos, 300)
			local vis_ray_l = World:raycast("ray", tmp_vec1, tmp_vec2, "slot_mask", my_data.ai_visibility_slotmask, "ray_type", "ai_vision", "report")
			if not vis_ray_l then
				nearly_visible = true
			end
		end
	end
	return nearly_visible
end
