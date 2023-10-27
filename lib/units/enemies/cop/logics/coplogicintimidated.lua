CopLogicIntimidated = class(CopLogicBase)
function CopLogicIntimidated.enter(data, new_logic_name, enter_params)
	CopLogicBase.enter(data, new_logic_name, enter_params)
	data.unit:brain():cancel_all_pathing_searches()
	local old_internal_data = data.internal_data
	local my_data = {
		unit = data.unit
	}
	my_data.rsrv_pos = {}
	if old_internal_data then
		my_data.detected_enemies = old_internal_data.detected_enemies or {}
		my_data.suspected_enemies = old_internal_data.suspected_enemies or {}
		if old_internal_data.focus_enemy then
			managers.groupai:state():on_enemy_disengaging(data.unit, old_internal_data.focus_enemy.unit:key())
		end
		my_data.rsrv_pos = old_internal_data.rsrv_pos or my_data.rsrv_pos
		if old_internal_data.nearest_cover then
			my_data.nearest_cover = old_internal_data.nearest_cover
			managers.navigation:reserve_cover(my_data.nearest_cover[1], data.pos_rsrv_id)
		end
	else
		my_data.detected_enemies = {}
	end
	local submission_max = data.char_tweak.submission_max
	my_data.submission_max = math.lerp(submission_max[1], submission_max[2], math.random())
	my_data.submission_meter = 0
	my_data.last_upd_t = data.t
	if data.unit:anim_data().hands_tied then
		CopLogicIntimidated._do_tied(data, nil)
	elseif not data.unit:movement():chk_action_forbidden("walk") then
		local action_data = {
			type = "act",
			body_part = 1,
			variant = "hands_up",
			clamp_to_graph = true
		}
		data.unit:brain():action_request(action_data)
		data.unit:brain():set_update_enabled_state(false)
	else
		data.unit:brain():set_update_enabled_state(true)
	end
	data.internal_data = my_data
	data.unit:movement():set_allow_fire(false)
	if data.objective then
		managers.groupai:state():on_objective_failed(data.unit, data.objective)
	end
	if managers.groupai:state():rescue_state() then
		CopLogicIntimidated._add_delayed_rescue_SO(data, my_data)
	end
	managers.groupai:state():add_to_surrendered(data.unit, callback(CopLogicIntimidated, CopLogicIntimidated, "queued_update", data))
	my_data.surrender_clbk_registered = true
	data.unit:sound():say("_s01x_sin", true)
	if data.unit:anim_data().hands_tied then
		my_data.tied = true
		my_data.is_hostage = true
		managers.groupai:state():on_hostage_state(true, data.key, true)
	end
end
function CopLogicIntimidated.exit(data, new_logic_name, enter_params)
	CopLogicBase.exit(data, new_logic_name, enter_params)
	local my_data = data.internal_data
	CopLogicIntimidated._unregister_rescue_SO(data, my_data)
	if new_logic_name ~= "inactive" then
		data.unit:base():set_slot(data.unit, 12)
	end
	if my_data.nearest_cover then
		managers.navigation:release_cover(my_data.nearest_cover[1])
	end
	if new_logic_name ~= "inactive" then
		data.unit:brain():set_update_enabled_state(true)
		managers.groupai:state():on_enemy_active_state_change(data.unit, true)
	end
	if my_data.tied then
		managers.groupai:state():on_enemy_untied(data.unit:key())
	end
	CopLogicIntimidated._unregister_harassment_SO(data, my_data)
	if my_data.surrender_clbk_registered then
		managers.groupai:state():remove_from_surrendered(data.unit)
	end
	if my_data.is_hostage then
		managers.groupai:state():on_hostage_state(false, data.key, true)
	end
end
function CopLogicIntimidated.death_clbk(data, damage_info)
	CopLogicIntimidated.super.death_clbk(data, damage_info)
end
function CopLogicIntimidated.queued_update(rubbish, data)
	local my_data = data.internal_data
	CopLogicIntimidated._update_enemy_detection(data, my_data)
	local anim_data = data.unit:anim_data()
	if my_data.submission_meter == 0 and (anim_data.hands_up or anim_data.hands_back) and not my_data.tied then
		my_data.surrender_clbk_registered = nil
		local new_action = {
			type = "act",
			variant = "idle",
			body_part = 1
		}
		data.unit:brain():action_request(new_action)
		data.unit:brain():set_logic("idle")
	else
		managers.groupai:state():add_to_surrendered(data.unit, callback(CopLogicIntimidated, CopLogicIntimidated, "queued_update", data))
	end
end
function CopLogicIntimidated._update_enemy_detection(data, my_data)
	local t = TimerManager:game():time()
	local delta_t = my_data.last_upd_t and t - my_data.last_upd_t or 0
	local enemies = managers.groupai:state():all_criminals()
	local visible
	local my_tracker = data.unit:movement():nav_tracker()
	local chk_vis_func = my_tracker.check_visibility
	for e_key, record in pairs(enemies) do
		local enemy_unit = record.unit
		if chk_vis_func(my_tracker, record.tracker) then
			if record.is_deployable then
				visible = true
				my_data.submission_meter = math.min(my_data.submission_max, my_data.submission_meter + delta_t)
			else
				local my_pos = data.unit:movement():m_head_pos()
				local enemy_pos = enemy_unit:movement():m_head_pos()
				local my_vec = my_pos - enemy_pos
				local dis = mvector3.normalize(my_vec)
				if dis < 300 then
					visible = true
				end
				local look_dir = enemy_unit:movement():m_head_rot():y()
				local focus = my_vec:dot(look_dir)
				if 0.65 < focus then
					visible = true
					if 0.85 < focus then
						my_data.submission_meter = math.min(my_data.submission_max, my_data.submission_meter + delta_t)
					end
				end
			end
		end
	end
	if not visible then
		my_data.submission_meter = math.max(0, my_data.submission_meter - delta_t)
	end
	my_data.last_upd_t = t
end
function CopLogicIntimidated.action_complete_clbk(data, action)
	local my_data = data.internal_data
	local action_type = action:type()
	if action_type == "act" and my_data.being_harassed then
		my_data.being_harassed = nil
		CopLogicIntimidated._add_delayed_rescue_SO(data, my_data)
	end
end
function CopLogicIntimidated.update(data)
	if not data.unit:movement():chk_action_forbidden("walk") then
		local action_data = {
			type = "act",
			body_part = 1,
			variant = "hands_up"
		}
		data.unit:brain():action_request(action_data)
		data.unit:brain():set_update_enabled_state(false)
	end
end
function CopLogicIntimidated.can_activate()
	return false
end
function CopLogicIntimidated.on_intimidated(data, amount, aggressor_unit)
	local my_data = data.internal_data
	local adj_submission = amount * data.char_tweak.submission_intimidate
	my_data.submission_meter = math.min(my_data.submission_max, my_data.submission_meter + adj_submission)
	if not my_data.tied then
		local anim_data = data.unit:anim_data()
		local anim
		if anim_data.hands_up then
			anim = "hands_back"
		elseif anim_data.hands_back then
			anim = "tied"
		else
			anim = "hands_up"
		end
		local action_data = {
			type = "act",
			body_part = 1,
			variant = anim,
			blocks = {
				light_hurt = -1,
				hurt = -1,
				heavy_hurt = -1
			}
		}
		local act_action = data.unit:brain():action_request(action_data)
		if action_data and anim == "tied" and not my_data.is_hostage then
			my_data.is_hostage = true
			managers.groupai:state():on_hostage_state(true, data.key, true)
		end
		if data.unit:anim_data().hands_tied then
			CopLogicIntimidated._do_tied(data, aggressor_unit)
		end
	end
end
function CopLogicIntimidated._register_harassment_SO(data, my_data)
	local objective_pos = data.unit:position() - data.unit:rotation():y() * 100
	local objective_rot = data.unit:rotation()
	local objective = {
		type = "act",
		pos = objective_pos,
		rot = objective_rot,
		interrupt_on = "obstructed",
		stance = "hos",
		scan = true,
		nav_seg = data.unit:movement():nav_tracker():nav_segment(),
		action_start_clbk = callback(CopLogicIntimidated, CopLogicIntimidated, "on_harassment_SO_action_start", data),
		fail_clbk = callback(CopLogicIntimidated, CopLogicIntimidated, "on_harassment_SO_failed", data),
		action = {
			type = "act",
			variant = "kick_fwd",
			body_part = 1,
			blocks = {action = -1, walk = -1}
		}
	}
	local so_descriptor = {
		objective = objective,
		base_chance = 1,
		chance_inc = 0,
		interval = 10,
		search_dis = 1500,
		search_pos = mvector3.copy(data.m_pos),
		usage_amount = 1,
		AI_group = "friendlies",
		admin_clbk = callback(CopLogicIntimidated, CopLogicIntimidated, "on_harassment_SO_administered", data)
	}
	local so_id = "harass" .. tostring(data.unit:key())
	my_data.harassment_SO_id = so_id
	managers.groupai:state():add_special_objective(so_id, so_descriptor)
end
function CopLogicIntimidated.on_harassment_SO_administered(ignore_this, data, receiver_unit)
	local my_data = data.internal_data
	my_data.harassment_SO_id = nil
end
function CopLogicIntimidated.on_harassment_SO_action_start(ignore_this, data, receiver_unit)
	local my_data = data.internal_data
	local action = {
		type = "act",
		variant = "harassed_kicked_from_behind",
		body_part = 1,
		blocks = {
			action = -1,
			walk = -1,
			light_hurt = -1,
			hurt = -1,
			heavy_hurt = -1
		}
	}
	my_data.being_harassed = data.unit:movement():action_request(action)
	managers.groupai:state():on_occasional_event("cop_harassment")
	CopLogicIntimidated._unregister_rescue_SO(data, my_data)
end
function CopLogicIntimidated.on_harassment_SO_failed(ignore_this, data, receiver_unit)
	local my_data = data.internal_data
	if my_data.being_harassed then
		local action_data = {
			type = "act",
			body_part = 1,
			variant = "tied",
			blocks = {
				light_hurt = -1,
				hurt = -1,
				heavy_hurt = -1
			}
		}
		data.unit:brain():action_request(action_data)
		my_data.being_harassed = nil
	end
end
function CopLogicIntimidated._unregister_harassment_SO(data, my_data)
	local my_data = data.internal_data
	if my_data.harassment_SO_id then
		managers.groupai:state():remove_special_objective(my_data.harassment_SO_id)
		my_data.harassment_SO_id = nil
	end
end
function CopLogicIntimidated._do_tied(data, aggressor_unit)
	local my_data = data.internal_data
	if my_data.surrender_clbk_registered then
		managers.groupai:state():remove_from_surrendered(data.unit)
		my_data.surrender_clbk_registered = nil
	end
	my_data.tied = true
	data.unit:inventory():destroy_all_items()
	data.unit:brain():set_update_enabled_state(false)
	if my_data.update_task_key then
		managers.enemy:unqueue_task(my_data.update_task_key)
		my_data.update_task_key = nil
	end
	local rsrv_pos = my_data.rsrv_pos
	if rsrv_pos.stand then
		managers.navigation:unreserve_pos(rsrv_pos.stand)
		rsrv_pos.stand = nil
	end
	managers.groupai:state():on_enemy_tied(data.unit:key())
	data.unit:base():set_slot(data.unit, 22)
	if aggressor_unit then
		data.unit:character_damage():drop_pickup()
		data.unit:character_damage():set_pickup(nil)
		if aggressor_unit == managers.player:player_unit() then
			managers.statistics:tied({
				name = data.unit:base()._tweak_table
			})
		else
			aggressor_unit:network():send_to_unit({
				"statistics_tied",
				data.unit:base()._tweak_table
			})
		end
	end
end
function CopLogicIntimidated.on_detected_enemy_destroyed(data, enemy_unit)
	CopLogicIdle.on_detected_enemy_destroyed(data, enemy_unit)
end
function CopLogicIntimidated.on_criminal_neutralized(data, criminal_key)
	CopLogicIdle.on_criminal_neutralized(data, criminal_key)
end
function CopLogicIntimidated.on_alert(data, alert_data)
	local enemy = alert_data[5] or alert_data[4]
	local my_data = data.internal_data
	local enemy_key = enemy:key()
	if managers.groupai:state():criminal_record(enemy_key) then
		local t = TimerManager:game():time()
		local enemy_data = CopLogicAttack._create_detected_enemy_data(data, enemy)
		my_data.detected_enemies[enemy_key] = enemy_data
		managers.groupai:state():criminal_spotted(enemy)
		managers.groupai:state():report_aggression(enemy)
	end
end
function CopLogicIntimidated.is_available_for_assignment(data)
	return false
end
function CopLogicIntimidated._add_delayed_rescue_SO(data, my_data)
	if data.char_tweak.flee_type == "hide" or data.unit:unit_data() and data.unit:unit_data().not_rescued then
	elseif my_data.delayed_clbks and my_data.delayed_clbks[my_data.delayed_rescue_SO_id] then
		managers.enemy:reschedule_delayed_clbk(my_data.delayed_rescue_SO_id, TimerManager:game():time() + 10)
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
		CopLogicBase.add_delayed_clbk(my_data, my_data.delayed_rescue_SO_id, callback(CopLogicIntimidated, CopLogicIntimidated, "register_rescue_SO", data), TimerManager:game():time() + 10)
	end
end
function CopLogicIntimidated.register_rescue_SO(ignore_this, data)
	local my_data = data.internal_data
	CopLogicBase.on_delayed_clbk(my_data, my_data.delayed_rescue_SO_id)
	my_data.delayed_rescue_SO_id = nil
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
	local objective = {
		type = "act",
		follow_unit = data.unit,
		pos = mvector3.copy(objective_pos),
		destroy_clbk_key = false,
		interrupt_on = "obstructed",
		stance = "hos",
		scan = true,
		nav_seg = data.unit:movement():nav_tracker():nav_segment(),
		fail_clbk = callback(CopLogicIntimidated, CopLogicIntimidated, "on_rescue_SO_failed", data),
		complete_clbk = callback(CopLogicIntimidated, CopLogicIntimidated, "on_rescue_SO_completed", data),
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
		search_pos = mvector3.copy(data.m_pos),
		usage_amount = 1,
		AI_group = "enemies",
		admin_clbk = callback(CopLogicIntimidated, CopLogicIntimidated, "on_rescue_SO_administered", data),
		verification_clbk = callback(CopLogicIntimidated, CopLogicIntimidated, "rescue_SO_verification")
	}
	local so_id = "rescue" .. tostring(data.unit:key())
	my_data.rescue_SO_id = so_id
	managers.groupai:state():add_special_objective(so_id, so_descriptor)
end
function CopLogicIntimidated._unregister_rescue_SO(data, my_data)
	if my_data.rescuer then
		local rescuer = my_data.rescuer
		my_data.rescuer = nil
		managers.groupai:state():on_objective_failed(rescuer, rescuer:brain():objective())
	elseif my_data.rescue_SO_id then
		managers.groupai:state():remove_special_objective(my_data.rescue_SO_id)
		my_data.rescue_SO_id = nil
	elseif my_data.delayed_rescue_SO_id then
		CopLogicBase.chk_cancel_delayed_clbk(my_data, my_data.delayed_rescue_SO_id)
	end
end
function CopLogicIntimidated.on_rescue_SO_administered(ignore_this, data, receiver_unit)
	local my_data = data.internal_data
	my_data.rescuer = receiver_unit
	my_data.rescue_SO_id = nil
end
function CopLogicIntimidated.rescue_SO_verification(ignore_this, unit)
	return tweak_data.character[unit:base()._tweak_table].rescue_hostages
end
function CopLogicIntimidated.on_rescue_SO_failed(ignore_this, data)
	local my_data = data.internal_data
	if my_data.rescuer then
		my_data.rescuer = nil
		my_data.delayed_rescue_SO_id = "rescue" .. tostring(data.unit:key())
		CopLogicBase.add_delayed_clbk(my_data, my_data.delayed_rescue_SO_id, callback(CopLogicIntimidated, CopLogicIntimidated, "register_rescue_SO", data), TimerManager:game():time() + 10)
	end
end
function CopLogicIntimidated.on_rescue_SO_completed(ignore_this, data, good_pig)
	if not data.unit:inventory():equipped_unit() then
		if data.unit:inventory():num_selections() <= 0 then
			local weap_name = data.unit:base():default_weapon_name()
			if weap_name then
				data.unit:inventory():add_unit_by_name(weap_name, true, true)
			end
		else
			data.unit:inventory():equip_selection(1, true)
		end
	end
	if data.unit:anim_data().hands_tied then
		local new_action = {
			type = "act",
			variant = "stand",
			body_part = 1
		}
		data.unit:brain():action_request(new_action)
	end
	CopLogicBase._exit(data.unit, "idle")
	good_pig:sound():say("_h01x_sin", true)
end
function CopLogicIntimidated.on_rescue_allowed_state(data, state)
	if state then
		if not data.unit:anim_data().move then
			CopLogicIntimidated._add_delayed_rescue_SO(data, data.internal_data)
		end
	else
		CopLogicIntimidated._unregister_rescue_SO(data, data.internal_data)
	end
end
function CopLogicIntimidated.anim_clbk(data, event_type)
	local my_data = data.internal_data
	if event_type == "harass_end" and my_data.being_harassed then
		my_data.being_harassed = nil
		CopLogicIntimidated._add_delayed_rescue_SO(data, data.internal_data)
	end
end
