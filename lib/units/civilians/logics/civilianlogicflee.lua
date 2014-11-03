CivilianLogicFlee = class(CopLogicBase)
function CivilianLogicFlee.enter(data, new_logic_name, enter_params)
	CopLogicBase.enter(data, new_logic_name, enter_params)
	data.unit:brain():cancel_all_pathing_searches()
	local old_internal_data = data.internal_data
	local my_data = {
		unit = data.unit
	}
	data.internal_data = my_data
	my_data.enemy_detect_slotmask = managers.slot:get_mask("criminals")
	my_data.ai_visibility_slotmask = managers.slot:get_mask("AI_visibility")
	my_data.rsrv_pos = {}
	if old_internal_data then
		my_data.suspected_enemies = old_internal_data.suspected_enemies or {}
		my_data.detected_enemies = old_internal_data.detected_enemies or {}
		my_data.focus_enemy = old_internal_data.focus_enemy
		my_data.has_outline = old_internal_data.has_outline
		my_data.been_outlined = old_internal_data.been_outlined
		if old_internal_data.focus_enemy then
			managers.groupai:state():on_enemy_disengaging(data.unit, old_internal_data.focus_enemy.unit:key())
		end
		my_data.rsrv_pos = old_internal_data.rsrv_pos or my_data.rsrv_pos
	else
		my_data.suspected_enemies = {}
		my_data.detected_enemies = {}
	end
	CopLogicBase._reset_attention(data)
	data.unit:brain():set_update_enabled_state(false)
	managers.groupai:state():register_fleeing_civilian(data.unit:key(), data.unit)
	local start_pos = data.unit:brain():panic_pos()
	if not start_pos then
		start_pos = mvector3.copy(data.m_pos)
		data.unit:brain():set_panic_pos(start_pos)
	end
	my_data.start_pos = start_pos
	my_data.flee_radius = 1000
	if not data.unit:anim_data().move and managers.groupai:state():rescue_state() then
		CivilianLogicFlee._add_delayed_rescue_SO(data, my_data)
	end
	if enter_params then
		if enter_params.alert_data then
			CivilianLogicFlee.on_alert(data, enter_params.alert_data)
		elseif enter_params.dmg_info then
			CivilianLogicFlee.damage_clbk(data, enter_params.dmg_info)
		elseif enter_params.was_rescued then
			CivilianLogicFlee._do_rescued(data)
			managers.groupai:state():on_civilian_freed()
		end
	end
	if not my_data.been_outlined and tweak_data.character[data.unit:base()._tweak_table].outline_on_discover then
		my_data.outline_detection_task_key = "CivilianLogicIdle._upd_outline_detection" .. tostring(data.key)
		CopLogicBase.queue_task(my_data, my_data.outline_detection_task_key, CivilianLogicIdle._upd_outline_detection, data, data.t + 2)
	end
end
function CivilianLogicFlee.exit(data, new_logic_name, enter_params)
	CopLogicBase.exit(data, new_logic_name, enter_params)
	CopLogicBase._reset_attention(data)
	local my_data = data.internal_data
	CivilianLogicFlee._unregister_rescue_SO(data, my_data)
	data.unit:brain():cancel_all_pathing_searches()
	CopLogicBase.cancel_delayed_clbks(my_data)
	managers.groupai:state():unregister_fleeing_civilian(data.unit:key())
	CopLogicBase.cancel_queued_tasks(my_data)
	if my_data.best_cover then
		managers.navigation:release_cover(my_data.best_cover[1])
	end
	if my_data.nearest_cover then
		managers.navigation:release_cover(my_data.nearest_cover[1])
	end
end
function CivilianLogicFlee.update(data)
	local exit_state
	local unit = data.unit
	local my_data = data.internal_data
	local objective = data.objective
	local t = data.t
	if my_data.flee_path_search_id or my_data.coarse_path_search_id then
		CivilianLogicFlee._update_pathing(data, my_data)
	elseif my_data.flee_path then
		if not unit:movement():chk_action_forbidden("walk") then
			CivilianLogicFlee._start_moving_to_cover(data, my_data)
		end
	elseif my_data.flee_target then
		if not my_data.advancing then
			if my_data.coarse_path then
				local coarse_path = my_data.coarse_path
				local cur_index = my_data.coarse_path_index
				local total_nav_points = #coarse_path
				if cur_index == total_nav_points then
					managers.hint:show_hint("civilian_escaped")
					if data.unit:unit_data().mission_element then
						data.unit:unit_data().mission_element:event("fled", data.unit)
					end
					managers.secret_assignment:civilian_escaped()
					data.unit:base():set_slot(unit, 0)
				else
					local to_pos
					if cur_index == total_nav_points - 1 then
						to_pos = my_data.flee_target.pos
					else
						local end_pos = coarse_path[cur_index + 1][2]
						to_pos = end_pos
					end
					local reservation = managers.navigation:reserve_pos(nil, nil, to_pos, nil, 30, data.pos_rsrv_id)
					my_data.rsrv_pos.path = reservation
					my_data.flee_path_search_id = tostring(unit:key()) .. "flee"
					unit:brain():search_for_path(my_data.flee_path_search_id, to_pos)
				end
			else
				local search_id = tostring(unit:key()) .. "coarseflee"
				local verify_clbk
				if not my_data.coarse_search_failed then
					verify_clbk = callback(CivilianLogicFlee, CivilianLogicFlee, "_flee_coarse_path_verify_clbk")
				end
				my_data.coarse_path_search_id = search_id
				unit:brain():search_for_coarse_path(search_id, my_data.flee_target.nav_seg, verify_clbk)
			end
		end
	elseif my_data.best_cover then
		local best_cover = my_data.best_cover
		if my_data.moving_to_cover and my_data.moving_to_cover == best_cover or my_data.in_cover and my_data.in_cover == best_cover then
		else
			if not unit:anim_data().panic then
				local action_data = {
					type = "act",
					body_part = 1,
					variant = "panic",
					clamp_to_graph = true
				}
				data.unit:brain():action_request(action_data)
				data.unit:brain():set_update_enabled_state(true)
			end
			my_data.pathing_to_cover = my_data.best_cover
			local search_id = tostring(unit:key()) .. "cover"
			my_data.flee_path_search_id = search_id
			data.unit:brain():search_for_path_to_cover(search_id, my_data.best_cover[1])
		end
	end
end
function CivilianLogicFlee._update_pathing(data, my_data)
	if data.pathing_results then
		local pathing_results = data.pathing_results
		data.pathing_results = nil
		my_data.has_cover_path = nil
		local path = my_data.flee_path_search_id and pathing_results[my_data.flee_path_search_id]
		if path then
			if path ~= "failed" then
				my_data.flee_path = path
				if my_data.pathing_to_cover then
					my_data.has_path_to_cover = my_data.pathing_to_cover
				end
			else
			end
			my_data.pathing_to_cover = nil
			my_data.flee_path_search_id = nil
		end
		path = my_data.coarse_path_search_id and pathing_results[my_data.coarse_path_search_id]
		if path then
			if path ~= "failed" then
				my_data.coarse_path = path
				my_data.coarse_path_index = 1
			else
				if my_data.coarse_search_failed then
				end
				my_data.coarse_search_failed = true
			end
			my_data.coarse_path_search_id = nil
		end
	end
end
function CivilianLogicFlee.action_complete_clbk(data, action)
	if action:type() == "walk" then
		local my_data = data.internal_data
		if action:expired() then
			my_data.rsrv_pos.stand = my_data.rsrv_pos.move_dest
			my_data.rsrv_pos.move_dest = nil
			if my_data.moving_to_cover then
				data.unit:sound():say("_a03x_any", true)
				my_data.in_cover = my_data.moving_to_cover
				CopLogicAttack._set_nearest_cover(my_data, my_data.in_cover)
				if not my_data.exiting and managers.groupai:state():rescue_state() then
					CivilianLogicFlee._add_delayed_rescue_SO(data, my_data)
				end
			elseif my_data.coarse_path_index then
				my_data.coarse_path_index = my_data.coarse_path_index + 1
			end
		elseif my_data.rsrv_pos.move_dest then
			if not my_data.rsrv_pos.stand then
				my_data.rsrv_pos.stand = managers.navigation:add_pos_reservation({
					position = mvector3.copy(data.m_pos),
					radius = 45,
					filter = data.pos_rsrv_id
				})
			end
			managers.navigation:unreserve_pos(my_data.rsrv_pos.move_dest)
			my_data.rsrv_pos.move_dest = nil
		end
		my_data.moving_to_cover = nil
		my_data.advancing = nil
		if not my_data.coarse_path_index then
			data.unit:brain():set_update_enabled_state(false)
		end
	end
end
function CivilianLogicFlee.can_deactivate(data)
	return false
end
function CivilianLogicFlee.on_alert(data, alert_data)
	if managers.groupai:state():whisper_mode() then
		return
	end
	local my_data = data.internal_data
	if my_data.flee_target then
		return
	end
	local anim_data = data.unit:anim_data()
	if anim_data.react_enter then
		return
	elseif anim_data.peaceful then
		local action_data = {
			type = "act",
			body_part = 1,
			variant = "react"
		}
		data.unit:brain():action_request(action_data)
		data.unit:sound():say("_a01x_any", true)
		if data.unit:unit_data().mission_element then
			data.unit:unit_data().mission_element:event("panic", data.unit)
		end
		return
	elseif alert_data[1] == "voice" then
		return
	elseif anim_data.react or anim_data.drop then
		local action_data = {
			type = "act",
			body_part = 1,
			variant = "panic"
		}
		data.unit:brain():action_request(action_data)
		data.unit:sound():say("_a01x_any", true)
		if data.unit:unit_data().mission_element then
			data.unit:unit_data().mission_element:event("panic", data.unit)
		end
		CopLogicBase._reset_attention(data)
		return
	end
	local avoid_pos
	if alert_data[5] then
		local tail = alert_data[2]
		local head = alert_data[3]
		local alert_dir = head - tail
		local alert_len = mvector3.normalize(alert_dir)
		avoid_pos = data.m_pos - tail
		local my_dot = mvector3.dot(alert_dir, avoid_pos)
		mvector3.set(avoid_pos, alert_dir)
		mvector3.multiply(avoid_pos, my_dot)
		mvector3.add(avoid_pos, tail)
	else
		avoid_pos = alert_data[2] or alert_data[4]:position()
	end
	my_data.avoid_pos = avoid_pos
	if not my_data.cover_search_task_key then
		my_data.cover_search_task_key = "CivilianLogicFlee._find_hide_cover" .. tostring(data.unit:key())
		CopLogicBase.queue_task(my_data, my_data.cover_search_task_key, CivilianLogicFlee._find_hide_cover, data)
	end
end
function CivilianLogicFlee._flee_coarse_path_verify_clbk(shait, data, nav_seg)
	return managers.groupai:state():is_area_safe(nav_seg)
end
function CivilianLogicFlee.on_intimidated(data, amount, aggressor_unit)
	if not tweak_data.character[data.unit:base()._tweak_table].intimidateable or data.unit:base().unintimidateable or data.unit:anim_data().unintimidateable then
		return
	end
	local my_data = data.internal_data
	if not my_data.delayed_intimidate_id then
		my_data.delayed_intimidate_id = "intimidate" .. tostring(data.unit:key())
		local delay = 1 - amount + math.random() * 0.2
		CopLogicBase.add_delayed_clbk(my_data, my_data.delayed_intimidate_id, callback(CivilianLogicFlee, CivilianLogicFlee, "_delayed_intimidate_clbk", {
			data,
			amount,
			aggressor_unit
		}), TimerManager:game():time() + delay)
	end
end
function CivilianLogicFlee._delayed_intimidate_clbk(ignore_this, params)
	local my_data = params[1].internal_data
	CopLogicBase.on_delayed_clbk(my_data, my_data.delayed_intimidate_id)
	my_data.delayed_intimidate_id = nil
	if not alive(params[1].unit) then
		return
	end
	local logic_params = {
		amount = params[2],
		aggressor_unit = params[3]
	}
	local anim_data = params[1].unit:anim_data()
	if anim_data.run then
		logic_params.initial_act = "halt"
	end
	params[1].unit:sound():say("_a02x_any", true)
	CivilianLogicIdle.switch_logic(params[1], {type = "free", surrender_data = logic_params}, "surrender", logic_params)
end
function CivilianLogicFlee._cancel_pathing(data, my_data)
	data.unit:brain():cancel_all_pathing_searches()
	my_data.pathing_to_cover = nil
	my_data.has_path_to_cover = nil
	my_data.coarse_path_search_id = nil
	my_data.coarse_search_failed = nil
	my_data.coarse_path = nil
	my_data.coarse_path_index = nil
end
function CivilianLogicFlee._find_hide_cover(data)
	local my_data = data.internal_data
	my_data.cover_search_task_key = nil
	if data.unit:anim_data().dont_flee then
		return
	end
	local avoid_pos = my_data.avoid_pos
	if my_data.best_cover then
		local best_cover_vec = avoid_pos - my_data.best_cover[1][1]
		if mvector3.dot(best_cover_vec, my_data.best_cover[1][2]) > 0.7 then
			return
		end
	end
	local cover = managers.navigation:find_cover_away_from_pos(my_data.start_pos, avoid_pos, my_data.flee_radius, false)
	if cover then
		if not data.unit:anim_data().panic then
			local action_data = {
				type = "act",
				body_part = 1,
				variant = "panic"
			}
			data.unit:brain():action_request(action_data)
		end
		CivilianLogicFlee._cancel_pathing(data, my_data)
		CopLogicAttack._set_best_cover(data, my_data, {cover})
		data.unit:brain():set_update_enabled_state(true)
	end
end
function CivilianLogicFlee._start_moving_to_cover(data, my_data)
	data.unit:sound():say("_a03x_any", true)
	CivilianLogicFlee._unregister_rescue_SO(data, my_data)
	CopLogicAttack._correct_path_start_pos(data, my_data.flee_path)
	local new_action_data = {}
	new_action_data.type = "walk"
	new_action_data.nav_path = my_data.flee_path
	new_action_data.variant = "run"
	new_action_data.body_part = 2
	new_action_data.no_walk = true
	my_data.advancing = data.unit:brain():action_request(new_action_data)
	my_data.flee_path = nil
	if my_data.has_path_to_cover then
		my_data.moving_to_cover = my_data.has_path_to_cover
		my_data.has_path_to_cover = nil
	end
	my_data.rsrv_pos.move_dest = my_data.rsrv_pos.path
	my_data.rsrv_pos.path = nil
	if my_data.rsrv_pos.stand then
		managers.navigation:unreserve_pos(my_data.rsrv_pos.stand)
		my_data.rsrv_pos.stand = nil
	end
end
function CivilianLogicFlee._add_delayed_rescue_SO(data, my_data)
	if data.char_tweak.flee_type == "hide" or data.unit:unit_data() and data.unit:unit_data().not_rescued then
	elseif my_data.delayed_clbks and my_data.delayed_clbks[my_data.delayed_rescue_SO_id] then
		managers.enemy:reschedule_delayed_clbk(my_data.delayed_rescue_SO_id, TimerManager:game():time() + 1)
	else
		if my_data.rescuer then
			local objective = my_data.rescuer:brain():objective()
			local rescuer = my_data.rescuer
			my_data.rescuer = nil
			managers.groupai:state():on_objective_failed(rescuer, objective)
		elseif my_data.rescue_SO_id then
			managers.groupai:state():remove_special_objective(my_data.rescue_SO_id)
			my_data.rescue_SO_id = nil
		end
		my_data.delayed_rescue_SO_id = "rescue" .. tostring(data.unit:key())
		CopLogicBase.add_delayed_clbk(my_data, my_data.delayed_rescue_SO_id, callback(CivilianLogicFlee, CivilianLogicFlee, "register_rescue_SO", data), TimerManager:game():time() + 1)
	end
end
function CivilianLogicFlee.register_rescue_SO(ignore_this, data)
	local my_data = data.internal_data
	CopLogicBase.on_delayed_clbk(my_data, my_data.delayed_rescue_SO_id)
	my_data.delayed_rescue_SO_id = nil
	if data.unit:anim_data().dont_flee then
		return
	end
	local my_tracker = data.unit:movement():nav_tracker()
	local objective_pos = my_tracker:field_position()
	local followup_objective = {
		type = "act",
		stance = "hos",
		scan = true,
		action = {
			type = "act",
			variant = "idle",
			body_part = 1,
			blocks = {action = -1, walk = -1}
		},
		act_duration = tweak_data.interaction.free.timer
	}
	local side = data.unit:movement():m_rot():x()
	mvector3.multiply(side, 65)
	local test_pos = mvector3.copy(objective_pos)
	mvector3.add(test_pos, side)
	local so_pos, so_rot
	local ray_params = {
		tracker_from = data.unit:movement():nav_tracker(),
		pos_to = test_pos,
		allow_entry = false,
		trace = true
	}
	if not managers.navigation:raycast(ray_params) then
		so_pos = test_pos
		so_rot = Rotation(-side, math.UP)
	else
		test_pos = mvector3.copy(objective_pos)
		mvector3.subtract(test_pos, side)
		ray_params.pos_to = test_pos
		if not managers.navigation:raycast(ray_params) then
			so_pos = test_pos
			so_rot = Rotation(side, math.UP)
		else
			so_pos = mvector3.copy(objective_pos)
			so_rot = nil
		end
	end
	local objective = {
		type = "act",
		follow_unit = data.unit,
		pos = so_pos,
		rot = so_rot,
		destroy_clbk_key = false,
		interrupt_on = "obstructed",
		stance = "hos",
		scan = true,
		nav_seg = data.unit:movement():nav_tracker():nav_segment(),
		fail_clbk = callback(CivilianLogicFlee, CivilianLogicFlee, "on_rescue_SO_failed", data),
		complete_clbk = callback(CivilianLogicFlee, CivilianLogicFlee, "on_rescue_SO_completed", data),
		action = {
			type = "act",
			variant = "untie",
			body_part = 1,
			blocks = {action = -1, walk = -1}
		},
		act_duration = tweak_data.interaction.free.timer,
		followup_objective = followup_objective
	}
	local so_descriptor = {
		objective = objective,
		base_chance = 1,
		chance_inc = 0,
		interval = 10,
		search_dis = 1000,
		search_pos = mvector3.copy(my_data.start_pos),
		usage_amount = 1,
		AI_group = "enemies",
		admin_clbk = callback(CivilianLogicFlee, CivilianLogicFlee, "on_rescue_SO_administered", data),
		verification_clbk = callback(CivilianLogicFlee, CivilianLogicFlee, "rescue_SO_verification")
	}
	local so_id = "rescue" .. tostring(data.unit:key())
	my_data.rescue_SO_id = so_id
	managers.groupai:state():add_special_objective(so_id, so_descriptor)
end
function CivilianLogicFlee._unregister_rescue_SO(data, my_data)
	if my_data.rescuer then
		local rescuer = my_data.rescuer
		my_data.rescuer = nil
		managers.groupai:state():on_objective_failed(rescuer, rescuer:brain():objective())
	elseif my_data.rescue_SO_id then
		managers.groupai:state():remove_special_objective(my_data.rescue_SO_id)
		my_data.rescue_SO_id = nil
	elseif my_data.delayed_rescue_SO_id then
		CopLogicBase.chk_cancel_delayed_clbk(my_data, my_data.delayed_rescue_SO_id)
		my_data.delayed_rescue_SO_id = nil
	end
end
function CivilianLogicFlee.on_rescue_SO_administered(ignore_this, data, receiver_unit)
	managers.groupai:state():on_civilian_try_freed()
	local my_data = data.internal_data
	my_data.rescuer = receiver_unit
	my_data.rescue_SO_id = nil
end
function CivilianLogicFlee.rescue_SO_verification(ignore_this, unit)
	return tweak_data.character[unit:base()._tweak_table].rescue_hostages
end
function CivilianLogicFlee.on_rescue_SO_failed(ignore_this, data)
	local my_data = data.internal_data
	if my_data.rescuer then
		my_data.rescuer = nil
		CivilianLogicFlee._add_delayed_rescue_SO(data, data.internal_data)
	end
end
function CivilianLogicFlee.on_rescue_SO_completed(ignore_this, data, good_pig)
	if data.internal_data.rescuer and good_pig:key() == data.internal_data.rescuer:key() then
		data.internal_data.rescuer = nil
		if data.unit:brain()._current_logic_name == "surrender" then
			if data.unit:anim_data().tied then
				local new_action = {
					type = "act",
					variant = "stand",
					body_part = 1
				}
				data.unit:brain():action_request(new_action)
			end
			CivilianLogicIdle.switch_logic(data, {
				type = "free",
				flee_data = {}
			}, "flee", {was_rescued = true})
		else
			CivilianLogicFlee._do_rescued(data)
		end
	end
	managers.groupai:state():on_civilian_freed()
	good_pig:sound():say("_h01x_sin", true)
end
function CivilianLogicFlee._do_rescued(data)
	local flee_pos = managers.groupai:state():flee_point(data.unit)
	if flee_pos then
		local nav_seg = managers.navigation:get_nav_seg_from_pos(flee_pos)
		data.internal_data.flee_target = {nav_seg = nav_seg, pos = flee_pos}
		data.unit:brain():set_update_enabled_state(true)
	end
end
function CivilianLogicFlee.on_new_objective(data, old_objective)
	CivilianLogicIdle.on_new_objective(data, old_objective)
end
function CivilianLogicFlee.on_rescue_allowed_state(data, state)
	local my_data = data.internal_data
	if state then
		if not my_data.advancing and not my_data.delayed_rescue_SO_id then
			CivilianLogicFlee._add_delayed_rescue_SO(data, my_data)
		end
	else
		CivilianLogicFlee._unregister_rescue_SO(data, my_data)
	end
end
function CivilianLogicFlee.wants_rescue(data)
	return data.internal_data.rescue_SO_id
end
function CivilianLogicFlee._get_all_paths(data)
	return {
		flee_path = data.internal_data.flee_path
	}
end
function CivilianLogicFlee._set_verified_paths(data, verified_paths)
	data.internal_data.flee_path = verified_paths.flee_path
end
