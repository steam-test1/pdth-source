CopLogicBase = class()
function CopLogicBase.enter(data, new_logic_name, enter_params)
end
function CopLogicBase.exit(data, new_logic_name, enter_params)
	if data.internal_data then
		data.internal_data.exiting = true
	end
end
function CopLogicBase.action_data(data)
	return data.action_data
end
function CopLogicBase.can_activate(data)
	return true
end
function CopLogicBase.can_deactivate(data)
	return true
end
function CopLogicBase.on_intimidated(data, amount, aggressor_unit)
end
function CopLogicBase.on_tied(data, aggressor_unit)
end
function CopLogicBase.on_criminal_neutralized(data, criminal_key)
	local my_data = data.internal_data
	if my_data then
		if my_data.detected_enemies then
			my_data.detected_enemies[criminal_key] = nil
		end
		if my_data.suspected_enemies then
			my_data.suspected_enemies[criminal_key] = nil
		end
		if my_data.focus_enemy and my_data.focus_enemy.unit:key() == criminal_key then
			managers.groupai:state():on_enemy_disengaging(data.unit, criminal_key)
			my_data.focus_enemy = nil
		end
	end
end
function CopLogicBase._set_attention_on_unit(data, attention_unit)
	local attention_data = {unit = attention_unit}
	data.unit:movement():set_attention(attention_data)
end
function CopLogicBase._set_attention_on_pos(data, pos)
	local attention_data = {pos = pos}
	data.unit:movement():set_attention(attention_data)
end
function CopLogicBase._reset_attention(data)
	data.unit:movement():set_attention()
end
function CopLogicBase.is_available_for_assignment(data)
	return true
end
function CopLogicBase.action_complete_clbk(data, action)
end
function CopLogicBase.damage_clbk(data, result, attack_unit)
end
function CopLogicBase.death_clbk(data, result, attack_unit)
end
function CopLogicBase.dodge(data)
end
function CopLogicBase.on_alert(data, alert_data)
end
function CopLogicBase.on_area_safety(data, nav_seg, safe)
end
function CopLogicBase.draw_reserved_positions(data)
	local my_pos = data.m_pos
	local my_data = data.internal_data
	local rsrv_pos = my_data.rsrv_pos
	if rsrv_pos.path then
		Application:draw_cylinder(rsrv_pos.path.pos, my_pos, 6, 0, 0.3, 0.3)
	end
	if rsrv_pos.move_dest then
		Application:draw_cylinder(rsrv_pos.move_dest.pos, my_pos, 6, 0.3, 0.3, 0)
	end
	if rsrv_pos.stand then
		Application:draw_cylinder(rsrv_pos.stand.pos, my_pos, 6, 0.3, 0, 0.3)
	end
	if my_data.best_cover then
		local cover_pos = my_data.best_cover[1][5].pos
		Application:draw_cylinder(cover_pos, my_pos, 2, 0.2, 0.3, 0.6)
		Application:draw_sphere(cover_pos, 10, 0.2, 0.3, 0.6)
	end
	if my_data.nearest_cover then
		local cover_pos = my_data.nearest_cover[1][5].pos
		Application:draw_cylinder(cover_pos, my_pos, 2, 0.2, 0.6, 0.3)
		Application:draw_sphere(cover_pos, 8, 0.2, 0.6, 0.3)
	end
	if my_data.moving_to_cover then
		local cover_pos = my_data.moving_to_cover[1][5].pos
		Application:draw_cylinder(cover_pos, my_pos, 2, 0.3, 0.6, 0.2)
		Application:draw_sphere(cover_pos, 8, 0.3, 0.6, 0.2)
	end
end
function CopLogicBase.draw_reserved_covers(data)
	local my_pos = data.m_pos
	local my_data = data.internal_data
	if my_data.best_cover then
		local cover_pos = my_data.best_cover[1][5].pos
		Application:draw_cylinder(cover_pos, my_pos, 2, 0.2, 0.3, 0.6)
		Application:draw_sphere(cover_pos, 10, 0.2, 0.3, 0.6)
	end
	if my_data.nearest_cover then
		local cover_pos = my_data.nearest_cover[1][5].pos
		Application:draw_cylinder(cover_pos, my_pos, 2, 0.2, 0.6, 0.3)
		Application:draw_sphere(cover_pos, 8, 0.2, 0.6, 0.3)
	end
	if my_data.moving_to_cover then
		local cover_pos = my_data.moving_to_cover[1][5].pos
		Application:draw_cylinder(cover_pos, my_pos, 2, 0.3, 0.6, 0.2)
		Application:draw_sphere(cover_pos, 8, 0.3, 0.6, 0.2)
	end
end
function CopLogicBase._exit(unit, state_name, params)
	unit:brain():set_logic(state_name, params)
end
function CopLogicBase.on_detected_enemy_destroyed(data, enemy_unit)
end
function CopLogicBase._can_move(data)
	return true
end
function CopLogicBase._report_detections(enemies)
	local group = managers.groupai:state()
	for key, data in pairs(enemies) do
		if data.verified then
			group:criminal_spotted(data.unit)
		end
	end
end
function CopLogicBase.on_importance(data)
end
function CopLogicBase.queue_task(internal_data, id, func, data, exec_t, asap)
	if internal_data.unit and internal_data ~= internal_data.unit:brain()._logic_data.internal_data then
		debug_pause("[CopLogicBase.queue_task] Task queued from the wrong logic", internal_data.unit, id, func, data, exec_t, asap)
	end
	local qd_tasks = internal_data.queued_tasks
	if qd_tasks then
		if qd_tasks[id] then
			debug_pause("[CopLogicBase.queue_task] Task queued twice", internal_data.unit, id, func, data, exec_t, asap)
		end
		qd_tasks[id] = true
	else
		internal_data.queued_tasks = {
			[id] = true
		}
	end
	managers.enemy:queue_task(id, func, data, exec_t, callback(CopLogicBase, CopLogicBase, "on_queued_task", internal_data), asap)
end
function CopLogicBase.cancel_queued_tasks(internal_data)
	local qd_tasks = internal_data.queued_tasks
	if qd_tasks then
		local e_manager = managers.enemy
		for id, _ in pairs(qd_tasks) do
			e_manager:unqueue_task(id)
		end
		internal_data.queued_tasks = nil
	end
end
function CopLogicBase.unqueue_task(internal_data, id)
	managers.enemy:unqueue_task(id)
	internal_data.queued_tasks[id] = nil
	if not next(internal_data.queued_tasks) then
		internal_data.queued_tasks = nil
	end
end
function CopLogicBase.chk_unqueue_task(internal_data, id)
	if internal_data.queued_tasks and internal_data.queued_tasks[id] then
		managers.enemy:unqueue_task(id)
		internal_data.queued_tasks[id] = nil
		if not next(internal_data.queued_tasks) then
			internal_data.queued_tasks = nil
		end
	end
end
function CopLogicBase.on_queued_task(ignore_this, internal_data, id)
	if not internal_data.queued_tasks or not internal_data.queued_tasks[id] then
		debug_pause("[CopLogicBase.on_queued_task] the task is not queued", internal_data.unit, id)
		return
	end
	internal_data.queued_tasks[id] = nil
	if not next(internal_data.queued_tasks) then
		internal_data.queued_tasks = nil
	end
end
function CopLogicBase.add_delayed_clbk(internal_data, id, clbk, exec_t)
	if internal_data.unit and internal_data ~= internal_data.unit:brain()._logic_data.internal_data then
		debug_pause("[CopLogicBase.add_delayed_clbk] Clbk added from the wrong logic", internal_data.unit, id, clbk, exec_t)
	end
	local clbks = internal_data.delayed_clbks
	if clbks then
		if clbks[id] then
			debug_pause("[CopLogicBase.queue_task] Callback added twice", internal_data.unit, id, clbk, exec_t)
		end
		clbks[id] = true
	else
		internal_data.delayed_clbks = {
			[id] = true
		}
	end
	managers.enemy:add_delayed_clbk(id, clbk, exec_t)
end
function CopLogicBase.cancel_delayed_clbks(internal_data)
	local clbks = internal_data.delayed_clbks
	if clbks then
		local e_manager = managers.enemy
		for id, _ in pairs(clbks) do
			e_manager:remove_delayed_clbk(id)
		end
		internal_data.delayed_clbks = nil
	end
end
function CopLogicBase.cancel_delayed_clbk(internal_data, id)
	if not internal_data.delayed_clbks or not internal_data.delayed_clbks[id] then
		debug_pause("[CopLogicBase.cancel_delayed_clbk] Tried to cancel inexistent clbk", internal_data.unit, id, internal_data.delayed_clbks and inspect(internal_data.delayed_clbks))
	end
	managers.enemy:remove_delayed_clbk(id)
	internal_data.delayed_clbks[id] = nil
	if not next(internal_data.delayed_clbks) then
		internal_data.delayed_clbks = nil
	end
end
function CopLogicBase.chk_cancel_delayed_clbk(internal_data, id)
	if internal_data.delayed_clbks and internal_data.delayed_clbks[id] then
		managers.enemy:remove_delayed_clbk(id)
		internal_data.delayed_clbks[id] = nil
		if not next(internal_data.delayed_clbks) then
			internal_data.delayed_clbks = nil
		end
	end
end
function CopLogicBase.on_delayed_clbk(internal_data, id)
	if not internal_data.delayed_clbks or not internal_data.delayed_clbks[id] then
		debug_pause("[CopLogicBase.on_delayed_clbk] Callback not added", internal_data.unit, id, internal_data.delayed_clbks and inspect(internal_data.delayed_clbks))
	end
	internal_data.delayed_clbks[id] = nil
	if not next(internal_data.delayed_clbks) then
		internal_data.delayed_clbks = nil
	end
end
function CopLogicBase.on_objective_unit_damaged(data, unit, attacker_unit)
end
function CopLogicBase.on_objective_unit_destroyed(data, unit)
	data.objective.destroy_clbk_key = nil
	data.objective.death_clbk_key = nil
	managers.groupai:state():on_objective_failed(data.unit, data.objective)
end
function CopLogicBase.on_new_objective(data, old_objective)
	if old_objective and (old_objective.type == "follow" or old_objective.type == "revive") then
		if old_objective.destroy_clbk_key then
			old_objective.follow_unit:base():remove_destroy_listener(old_objective.destroy_clbk_key)
			old_objective.destroy_clbk_key = nil
		end
		if old_objective.death_clbk_key then
			old_objective.follow_unit:character_damage():remove_listener(old_objective.death_clbk_key)
			old_objective.death_clbk_key = nil
		end
	end
	local new_objective = data.objective
	if new_objective and (new_objective.type == "follow" or new_objective.type == "revive") then
		local ext_brain = data.unit:brain()
		local destroy_clbk_key = "objective_" .. new_objective.type .. tostring(data.unit:key())
		new_objective.destroy_clbk_key = destroy_clbk_key
		new_objective.follow_unit:base():add_destroy_listener(destroy_clbk_key, callback(ext_brain, ext_brain, "on_objective_unit_destroyed"))
		if new_objective.follow_unit:character_damage() then
			new_objective.death_clbk_key = destroy_clbk_key
			new_objective.follow_unit:character_damage():add_listener(destroy_clbk_key, {"death", "hurt"}, callback(ext_brain, ext_brain, "on_objective_unit_damaged"))
		end
	end
end
function CopLogicBase.is_advancing(data)
end
function CopLogicBase.anim_clbk(...)
end
