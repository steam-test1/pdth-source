GroupAIStateStreet = GroupAIStateStreet or class(GroupAIStateBase)
function GroupAIStateStreet:init()
	GroupAIStateStreet.super.init(self)
	if Network:is_server() and not self._police_upd_task_queued then
		self:_queue_police_upd_task()
	end
end
function GroupAIStateStreet:_init_misc_data()
	GroupAIStateStreet.super:_init_misc_data(self)
	if managers.navigation:is_data_ready() then
		self._police_force_max = 25
		self._earliest_spawn_t = 0
		self._nr_active_units = 0
		self._event_chk_t = 0
		self._criminal_slotmask = managers.slot:get_mask("criminals")
		GroupAIStateBesiege._create_area_data(self)
		self._blockade_spots_mapped = nil
		local all_areas = self._area_data
		for u_key, u_data in pairs(self._police) do
			if not u_data.assigned_area then
				local nav_seg = u_data.unit:movement():nav_tracker():nav_segment()
				self:_set_enemy_assigned(all_areas[nav_seg], u_key)
			end
		end
		self._is_first_assault = true
		self._task_data = {}
		self._task_data.blockade = {}
		self._task_data.assault = {}
		self._task_data.regroup = {}
		self._task_data.reenforce = {
			tasks = {}
		}
	end
end
function GroupAIStateStreet:update(t, dt)
	GroupAIStateBesiege.update(self, t, dt)
end
function GroupAIStateStreet:paused_update(t, dt)
	GroupAIStateBesiege.paused_update(self, t, dt)
end
function GroupAIStateStreet:_queue_police_upd_task()
	self._police_upd_task_queued = true
	managers.enemy:queue_task("GroupAIStateStreet._upd_police_activity", GroupAIStateStreet._upd_police_activity, self, self._t + 2)
end
function GroupAIStateStreet:assign_enemy_to_group_ai(unit)
	GroupAIStateBesiege.assign_enemy_to_group_ai(self, unit)
end
function GroupAIStateStreet:on_enemy_unregistered(unit)
	GroupAIStateBesiege.on_enemy_unregistered(self, unit)
end
function GroupAIStateStreet:on_enemy_active_state_change(unit, state)
	GroupAIStateBesiege.on_enemy_active_state_change(self, unit, state)
end
function GroupAIStateStreet:_mark_enemy_active_state(u_properties, state)
	GroupAIStateBesiege._mark_enemy_active_state(self, u_properties, state)
end
function GroupAIStateStreet:_upd_police_activity()
	self._police_upd_task_queued = false
	if self._ai_enabled then
		local t = self._t
		GroupAIStateBesiege._upd_SO(self, t)
		if self._player_weapons_hot then
			if self._blockade_spots_mapped then
				self:_claculate_drama_value()
				self:_upd_reenforce_tasks(t)
				self:_upd_blockade_task(t)
				self:_upd_regroup_task(t)
				self:_upd_assault_task(t)
				self:_begin_new_tasks(t)
			else
				self:_map_ai_blockade_spots()
			end
		end
	end
	self:_queue_police_upd_task()
end
function GroupAIStateStreet:_begin_new_tasks(t)
	local all_areas = self._area_data
	local nav_manager = managers.navigation
	local all_nav_segs = nav_manager._nav_segments
	local task_data = self._task_data
	if self._wave_mode == "blockade" then
		local blockade_data = task_data.blockade
		if not blockade_data.active then
			self:_begin_blockade_task(t)
		end
	elseif self._wave_mode == "assault" then
		local assault_data = task_data.assault
		if assault_data.next_dispatch_t and t > assault_data.next_dispatch_t then
			self:_begin_assault_task(t)
		end
	end
end
function GroupAIStateStreet:_begin_blockade_task(t)
	local event = self:_find_blockade_event(t)
	if not event then
		return
	end
	local task_data = self._task_data.blockade
	task_data.active = true
	task_data.event = event
	task_data.target_area = event.nav_seg
	task_data.compromise_dis = 1000
	task_data.phase = nil
	task_data.start_t = self._t
	task_data.phase_end_t = nil
	task_data.force_required = tweak_data.group_ai.street.blockade.force
	task_data.force_required = {}
	task_data.force_required.defend = math.ceil(self:_get_difficulty_dependent_value(tweak_data.group_ai.street.blockade.force.defend))
	task_data.force_required.frontal = math.ceil(self:_get_difficulty_dependent_value(tweak_data.group_ai.street.blockade.force.frontal))
	task_data.flank_assault = {
		next_dispatch_t = t + math.random(5, 30)
	}
	task_data.mission_fwd = event.rot:y()
	function task_data.dispatch()
		task_data.next_dispatch_t = nil
		task_data.phase = "anticipation"
		local anticipation_duration = self:_get_anticipation_duration(tweak_data.group_ai.street.blockade.anticipation_duration, self._is_first_assault)
		self._is_first_assault = nil
		task_data.phase_end_t = self._t + anticipation_duration
		managers.hud:setup_anticipation(anticipation_duration)
		managers.hud:start_anticipation()
		if self._draw_drama then
			table.insert(self._draw_drama.assault_hist, {
				self._t
			})
		end
	end
	self:_use_spawn_event(event)
end
function GroupAIStateStreet:_upd_blockade_task(t)
	local task_data = self._task_data.blockade
	if not task_data.active then
		return
	end
	local mvec3_dis = mvector3.distance
	local event = task_data.event
	local target_pos = event.pos
	local phase = task_data.phase
	if not phase and not task_data.passive and task_data.next_dispatch_t and t > task_data.next_dispatch_t then
		task_data.dispatch()
		phase = task_data.phase
	end
	local relevant_areas = event.relevant_areas
	local relevant_players = {}
	local has_irrelevant_players
	for c_key, c_data in pairs(self._player_criminals) do
		local nav_seg = c_data.tracker:nav_segment()
		if relevant_areas[nav_seg] then
			if not c_data.status then
				relevant_players[c_key] = c_data
			end
		else
			has_irrelevant_players = true
		end
	end
	local failed_to_change_event
	if has_irrelevant_players then
		local event = self:_find_blockade_event(t)
		if event then
			task_data.event = event
			task_data.target_area = event.nav_seg
			task_data.mission_fwd = event.rot:y()
			self:_use_spawn_event(event)
			event = task_data.event
			target_pos = event.pos
		else
			failed_to_change_event = true
		end
	end
	local nearest_player_record
	local compromise_dis = task_data.compromise_dis
	local nearest_dis, compromised
	for _, blockade_point in ipairs(event.blockade_points) do
		local blockade_pos = blockade_point[2]
		for c_key, c_record in pairs(relevant_players) do
			local pl_dis = mvec3_dis(c_record.m_pos, blockade_pos)
			if not failed_to_change_event and compromise_dis > pl_dis then
				local event = self:_find_blockade_event(t)
				if event then
					task_data.event = event
					task_data.target_area = event.nav_seg
					task_data.mission_fwd = event.rot:y()
					self:_use_spawn_event(event)
					return
				else
				end
			elseif not nearest_dis or nearest_dis > pl_dis then
				nearest_dis = pl_dis
				nearest_player_record = c_record
			end
		end
	end
	if phase == "anticipation" then
		if t > task_data.phase_end_t then
			managers.hud:start_assault()
			self:_set_rescue_state(false)
			task_data.phase = "build"
			phase = task_data.phase
			task_data.phase_end_t = self._t + tweak_data.group_ai.street.blockade.build_duration
			self:set_assault_mode(true)
			managers.trade:set_trade_countdown(false)
		else
			managers.hud:check_anticipation_voice(task_data.phase_end_t - t)
			managers.hud:check_start_anticipation_music(task_data.phase_end_t - t)
		end
	elseif phase == "build" then
		if t > task_data.phase_end_t or self._drama_data.zone == "high" then
			task_data.phase = "sustain"
			phase = task_data.phase
			task_data.phase_end_t = t + math.lerp(self:_get_difficulty_dependent_value(tweak_data.group_ai.street.blockade.sustain_duration_min), self:_get_difficulty_dependent_value(tweak_data.group_ai.street.blockade.sustain_duration_max), math.random())
		end
	elseif phase == "sustain" then
		if t > task_data.phase_end_t and not self._hunt_mode then
			task_data.phase = "fade"
			phase = task_data.phase
			task_data.phase_end_t = nil
			task_data.phase_end_t = t + 10
		end
	elseif phase == "fade" then
		if t > task_data.phase_end_t - 8 and not task_data.said_retreat then
			if self._drama_data.zone ~= "high" then
				task_data.said_retreat = true
				self:_police_announce_retreat()
			end
		elseif t > task_data.phase_end_t and self._drama_data.zone ~= "high" then
			task_data.active = nil
			task_data.phase = nil
			phase = task_data.phase
			task_data.said_retreat = nil
			if self._draw_drama then
				self._draw_drama.assault_hist[#self._draw_drama.assault_hist][2] = t
			end
			self:_begin_regroup_task(true)
			return
		end
	end
	local attitude = phase and "engage" or "avoid"
	local cops_in_area = self._area_data[task_data.target_area].police.units
	local mvec3_set = mvector3.set
	local mvec3_sub = mvector3.subtract
	local mvec3_dot = mvector3.dot
	local blocker_pigs = {}
	local front_pigs = 0
	local crim_center = nearest_player_record and nearest_player_record.m_pos
	local mission_fwd = task_data.mission_fwd
	for u_key, u_data in pairs(self._police) do
		if u_data.assigned_area then
			if cops_in_area[u_key] and u_data.unit:brain():objective() and u_data.unit:brain():objective().type == "defend_area" then
				table.insert(blocker_pigs, u_key)
			else
				front_pigs = front_pigs + 1
			end
		end
	end
	local undershot = task_data.force_required.defend - #blocker_pigs
	local spawn_threshold = math.max(0, self._police_force_max - self._police_force)
	if undershot > 0 then
		if spawn_threshold > 0 and not self:_try_use_task_spawn_event(t, task_data.target_area, "assault") then
			local nr_wanted = math.min(spawn_threshold, undershot, math.random(2, 3))
			local spawn_points = self:_find_spawn_points_behind_pos(task_data.target_area, target_pos, nr_wanted, task_data.mission_fwd)
			if spawn_points then
				local objectives = {}
				local objective = {
					type = "defend_area",
					nav_seg = task_data.target_area,
					pos = target_pos,
					defend_dir = -task_data.mission_fwd,
					status = "in_progress",
					stance = "cbt",
					attitude = attitude
				}
				for _, sp_data in ipairs(spawn_points) do
					local my_objective = deep_clone(objective)
					my_objective.pos = mvector3.copy(event.blockade_points[math.random(#event.blockade_points)][2])
					table.insert(objectives, my_objective)
				end
				self:_spawn_cops_with_objectives(spawn_points, objectives, tweak_data.group_ai.street.blockade.units.defend)
				spawn_threshold = spawn_threshold - #spawn_points
			end
		end
	elseif undershot < 0 then
		for i = 1, -undershot do
			local u_key = blocker_pigs[#blocker_pigs]
			table.remove(blocker_pigs)
			local u_data = self._police[u_key]
			u_data.unit:brain():set_objective(nil)
		end
	end
	if not self._task_data.regroup.active then
		if spawn_threshold > 0 then
			local flank_assault = task_data.flank_assault
			if flank_assault.sneak_unit_key and not self._police[flank_assault.sneak_unit_key] then
				flank_assault.sneak_unit_key = nil
				flank_assault.next_dispatch_t = t + math.random(45, 300)
			end
			if not flank_assault.sneak_unit_key and t > flank_assault.next_dispatch_t then
				local search_start_area = task_data.target_area
				local target_area_neighbours = managers.navigation._nav_segments[task_data.target_area].neighbours
				for nav_seg, _ in pairs(relevant_areas) do
					if target_area_neighbours[nav_seg] then
						search_start_area = nav_seg
					else
					end
				end
				local spawn_points = self:_find_spawn_points_behind_pos(search_start_area, target_pos, 1, -task_data.mission_fwd, relevant_areas)
				if spawn_points then
					local sp_data = spawn_points[1]
					local my_objective = {
						type = "investigate_area",
						status = "in_progress",
						stance = "hos",
						attitude = attitude,
						interrupt_on = "obstructed"
					}
					local closest_criminal_data, closest_dis
					for c_key, c_data in pairs(relevant_players) do
						if not c_data.status then
							local my_dis = mvec3_dis(c_data.m_pos, target_pos)
							if not closest_dis or closest_dis < my_dis then
								closest_dis = my_dis
								closest_criminal_data = c_data
							end
						end
					end
					if closest_criminal_data then
						my_objective.nav_seg = closest_criminal_data.tracker:nav_segment()
					else
						my_objective.nav_seg = task_data.target_area
					end
					local spawned_units = {}
					self:_spawn_cops_with_objectives(spawn_points, {my_objective}, tweak_data.group_ai.street.blockade.units.flank, spawned_units)
					local sneak_unit = spawned_units[1]
					if sneak_unit then
						flank_assault.sneak_unit_key = sneak_unit:key()
					end
				end
			end
		end
		if spawn_threshold > 0 and (phase == "build" or phase == "sustain") then
			local wanted_fwd = math.min(task_data.force_required.frontal - front_pigs, spawn_threshold)
			if wanted_fwd > 0 and not self:_try_use_task_spawn_event(t, task_data.target_area, "assault") then
				wanted_fwd = math.min(wanted_fwd, math.random(2, 3))
				local spawn_points = self:_find_spawn_points_behind_pos(task_data.target_area, target_pos, wanted_fwd, task_data.mission_fwd, nil)
				if spawn_points then
					local objectives = {}
					local objective = {
						type = "investigate_area",
						status = "in_progress",
						stance = "hos",
						attitude = attitude,
						interrupt_on = "obstructed"
					}
					for _, sp_data in ipairs(spawn_points) do
						local sp_pos = sp_data.pos
						local my_objective = deep_clone(objective)
						local closest_criminal_data, closest_dis
						for c_key, c_data in pairs(self._criminals) do
							if not c_data.status then
								local my_dis = mvec3_dis(c_data.m_pos, sp_pos)
								if not closest_dis or closest_dis > my_dis then
									closest_dis = my_dis
									closest_criminal_data = c_data
								end
							end
						end
						if closest_criminal_data then
							my_objective.nav_seg = closest_criminal_data.tracker:nav_segment()
						else
							my_objective.nav_seg = task_data.target_area
						end
						table.insert(objectives, my_objective)
					end
					self:_spawn_cops_with_objectives(spawn_points, objectives, tweak_data.group_ai.street.blockade.units.frontal)
					spawn_threshold = spawn_threshold - #spawn_points
				end
			end
		end
	end
	for u_key, u_data in pairs(self._police) do
		if u_data.assigned_area then
			if u_data.unit:brain():is_available_for_assignment({
				type = "investigate_area",
				interrupt_on = "obstructed"
			}) then
				local objective = u_data.unit:brain():objective()
				if not objective or objective.type == "free" then
					local closest_criminal_data, closest_dis
					for c_key, c_data in pairs(relevant_players) do
						if not c_data.status then
							local my_dis = mvec3_dis(c_data.m_pos, u_data.m_pos)
							if not closest_dis or closest_dis > my_dis then
								closest_dis = my_dis
								closest_criminal_data = c_data
							end
						end
					end
					if closest_criminal_data and closest_dis > 5000 then
						local move_area = closest_criminal_data.tracker:nav_segment()
						local new_objective = {
							type = "investigate_area",
							nav_seg = move_area,
							status = "in_progress",
							attitude = attitude,
							stance = "hos",
							interrupt_on = "obstructed",
							pos = mvector3.copy(closest_criminal_data.m_pos)
						}
						u_data.unit:brain():set_objective(new_objective)
						self:_set_enemy_assigned(self._area_data[move_area], u_key)
					end
				end
			end
		end
	end
end
function GroupAIStateStreet:_find_blockade_event(t)
	local mvec3_dis = mvector3.distance
	local min_dis = tweak_data.group_ai.street.blockade.min_distance
	for event_id, event_data in pairs(self._spawn_events) do
		if event_data.task_type == "blockade" and not event_data.broken then
			local invalid
			if not event_data.blockade_points then
				local area_data = self._area_data[event_data.nav_seg]
				event_data.blockade_points = area_data.blockade_spots
				if not event_data.blockade_points then
					event_data.broken = true
					invalid = true
					print("[GroupAIStateStreet:_begin_blockade_task] failed to find blockade points for event", event_id, "in nav_segment", event_data.nav_seg)
				end
			end
			if not invalid then
				for c_key, c_record in pairs(self._player_criminals) do
					if not event_data.relevant_areas[c_record.tracker:nav_segment()] then
						invalid = true
					else
					end
				end
				if not invalid then
					for _, blockade_point in ipairs(event_data.blockade_points) do
						local blockade_pos = blockade_point[2]
						local blockade_fwd = blockade_point[3]
						local invalid
						for c_key, c_record in pairs(self._player_criminals) do
							if min_dis > mvec3_dis(c_record.m_pos, blockade_pos) then
								invalid = true
							else
							end
						end
						if invalid then
						else
						end
					end
					if not invalid then
						return event_data
					end
				end
			end
		end
	end
end
function GroupAIStateStreet:_begin_reenforce_task(nav_seg, force)
	self._task_data.reenforce.active = true
	local new_task = {
		target_area = nav_seg,
		start_t = self._t,
		force_required = force
	}
	table.insert(self._task_data.reenforce.tasks, new_task)
end
function GroupAIStateStreet:_upd_reenforce_tasks(t)
	for i_task, task_data in ipairs(self._task_data.reenforce.tasks) do
		local target_area = task_data.target_area
		local target_area_data = self._area_data[target_area]
		local force_assigned = {}
		for u_key, u_data in pairs(target_area_data.police.units) do
			local objective = u_data.unit:brain():objective()
			if objective.type == "defend_area" then
				table.insert(force_assigned, u_key)
			end
		end
		local spawn_threshold = self._police_force_max - self._police_force
		local undershot = task_data.force_required - #force_assigned
		undershot = math.min(undershot, spawn_threshold)
		if undershot < 0 then
			for i = 0, undershot do
				local u_key, u_data = next(target_area_data.police.units)
				local unit = u_data.unit
				local objective = u_data.unit:brain():objective()
				local seg = unit:movement():nav_tracker():nav_segment()
				local new_objective = {
					type = "free",
					nav_seg = seg,
					attitude = objective.attitude,
					stance = objective.stance,
					scan = true
				}
				self:_set_enemy_assigned(self._area_data[seg], u_key)
				unit:brain():set_objective(new_objective)
			end
		elseif undershot > 0 then
			local existing_cops = GroupAIStateBesiege._find_surplus_cops_around_area(self, target_area, math.min(undershot, math.random(1, 3)), spawn_threshold)
			if existing_cops then
				for _, unit in ipairs(existing_cops) do
					local new_objective = {
						type = "defend_area",
						nav_seg = target_area,
						status = "in_progress",
						attitude = "avoid",
						stance = "hos",
						interrupt_on = "obstructed"
					}
					unit:brain():set_objective(new_objective)
					self:_set_enemy_assigned(self._area_data[target_area], unit:key())
				end
				undershot = undershot - #existing_cops
			end
			if undershot > 0 then
				local spawn_points = GroupAIStateBesiege._find_spawn_points_near_area(self, target_area, undershot, nil, 4000)
				if spawn_points then
					local objective = {
						type = "defend_area",
						nav_seg = target_area,
						status = "in_progress",
						attitude = "avoid",
						stance = "hos",
						scan = true,
						interrupt_on = "obstructed"
					}
					self:_spawn_cops_with_objective(target_area, spawn_points, objective, tweak_data.group_ai.besiege.reenforce.units)
				end
			end
		end
	end
end
function GroupAIStateStreet:_begin_assault_task(t)
	local available_criminals = {}
	for c_key, c_data in pairs(self._player_criminals) do
		if not c_data.status then
			table.insert(available_criminals, c_key)
		end
	end
	if #available_criminals == 0 then
		print("[GroupAIStateStreet:_begin_assault_task] Could not find any active criminal players")
		return
	end
	local target_criminal_record = self._player_criminals[available_criminals[math.random(#available_criminals)]]
	local target_area = target_criminal_record.tracker:nav_segment()
	local assault_task = self._task_data.assault
	assault_task.active = true
	assault_task.next_dispatch_t = nil
	assault_task.target_area = target_area
	assault_task.phase = "anticipation"
	assault_task.start_t = self._t
	local anticipation_duration = self:_get_anticipation_duration(tweak_data.group_ai.street.assault.anticipation_duration, self._is_first_assault)
	self._is_first_assault = nil
	assault_task.phase_end_t = self._t + anticipation_duration
	assault_task.force = {}
	assault_task.force.aggressive = math.ceil(self:_get_difficulty_dependent_value(tweak_data.group_ai.street.assault.force.aggressive))
	assault_task.force.defensive = math.ceil(self:_get_difficulty_dependent_value(tweak_data.group_ai.street.assault.force.defensive))
	assault_task.use_smoke = true
	assault_task.use_smoke_timer = 0
	assault_task.use_spawn_event = true
	self._downs_during_assault = 0
	if not self._hunt_mode then
		managers.hud:setup_anticipation(anticipation_duration)
		managers.hud:start_anticipation()
	else
		assault_task.phase_end_t = 0
	end
	if self._draw_drama then
		table.insert(self._draw_drama.assault_hist, {
			self._t
		})
	end
end
function GroupAIStateStreet:_upd_assault_task(t)
	local task_data = self._task_data.assault
	if not task_data.active then
		return
	end
	local task_phase = task_data.phase
	if task_data.phase == "anticipation" then
		if t > task_data.phase_end_t then
			managers.hud:start_assault()
			self:_set_rescue_state(false)
			task_data.phase = "build"
			task_data.phase_end_t = self._t + tweak_data.group_ai.street.assault.build_duration
			self:set_assault_mode(true)
			managers.trade:set_trade_countdown(false)
		else
			managers.hud:check_anticipation_voice(task_data.phase_end_t - t)
			managers.hud:check_start_anticipation_music(task_data.phase_end_t - t)
		end
	elseif task_data.phase == "build" then
		if t > task_data.phase_end_t or self._drama_data.zone == "high" then
			task_data.phase = "sustain"
			task_phase = task_data.phase
			task_data.phase_end_t = t + math.lerp(self:_get_difficulty_dependent_value(tweak_data.group_ai.street.assault.sustain_duration_min), self:_get_difficulty_dependent_value(tweak_data.group_ai.street.assault.sustain_duration_max), math.random())
		end
	elseif task_phase == "sustain" then
		if t > task_data.phase_end_t and not self._hunt_mode then
			task_data.phase = "fade"
			task_phase = task_data.phase
			task_data.use_smoke = false
			task_data.use_smoke_timer = t + 20
			task_data.phase_end_t = nil
			task_data.phase_end_t = t + 10
		end
	elseif t > task_data.phase_end_t - 8 and not task_data.said_retreat then
		if self._drama_data.zone ~= "high" then
			task_data.said_retreat = true
			self:_police_announce_retreat()
		end
	elseif t > task_data.phase_end_t and self._drama_data.zone ~= "high" then
		task_data.active = nil
		task_data.phase = nil
		task_data.said_retreat = nil
		if self._draw_drama then
			self._draw_drama.assault_hist[#self._draw_drama.assault_hist][2] = t
		end
		self:_begin_regroup_task(true)
		return
	end
	local aggressive_cops = {}
	local nr_agressive_cops = 0
	local defensive_cops = {}
	local nr_defensive_cops = 0
	for u_key, u_data in pairs(self._police) do
		if u_data.assigned_area then
			local objective = u_data.unit:brain():objective()
			if not objective then
				defensive_cops[u_key] = u_data
				nr_defensive_cops = nr_defensive_cops + 1
			elseif objective.type == "defend_area" then
				if not u_data.assigned_area.factors or not u_data.assigned_area.factors.force then
					defensive_cops[u_key] = u_data
					nr_defensive_cops = nr_defensive_cops + 1
				end
			elseif objective.attitude == "engage" then
				aggressive_cops[u_key] = u_data
				nr_agressive_cops = nr_agressive_cops + 1
			else
				defensive_cops[u_key] = u_data
				nr_defensive_cops = nr_defensive_cops + 1
			end
		end
	end
	local target_area = task_data.target_area
	local area_data = self._area_data[target_area]
	local area_safe = true
	for criminal_key, _ in pairs(area_data.criminal.units) do
		local criminal_data = self._criminals[criminal_key]
		if not criminal_data.status then
			local crim_area = criminal_data.tracker:nav_segment()
			if crim_area == target_area then
				area_safe = nil
			end
		else
		end
	end
	if area_safe then
		local target_pos = managers.navigation._nav_segments[target_area].pos
		local nearest_area, nearest_dis
		for criminal_key, criminal_data in pairs(self._criminals) do
			if not criminal_data.status then
				local dis = mvector3.distance(target_pos, criminal_data.m_pos)
				if not nearest_dis or nearest_dis > dis then
					nearest_dis = dis
					nearest_area = criminal_data.tracker:nav_segment()
				end
			end
		end
		if nearest_area then
			target_area = nearest_area
			task_data.target_area = nearest_area
		end
	end
	local mvec3_dis = mvector3.distance
	local all_criminals = self._criminals
	local healthy_criminals = {}
	for c_key, c_data in pairs(all_criminals) do
		if not c_data.status then
			healthy_criminals[c_key] = c_data
		end
	end
	if task_phase == "anticipation" then
		local spawn_threshold = math.max(0, self._police_force_max - self._police_force - 5)
		if spawn_threshold > 0 then
			local nr_wanted = math.min(spawn_threshold, task_data.force.defensive + task_data.force.aggressive - self._police_force)
			if nr_wanted > 0 then
				nr_wanted = math.min(3, nr_wanted)
				local spawn_points = GroupAIStateBesiege._find_spawn_points_near_area(self, target_area, nr_wanted, nil, 10000, callback(self, GroupAIStateBesiege, "_verify_anticipation_spawn_point"), self)
				if spawn_points then
					local objectives = {}
					for _, sp_data in ipairs(spawn_points) do
						local new_objective = {
							type = "investigate_area",
							nav_seg = sp_data.nav_seg,
							attitude = "avoid",
							stance = "hos",
							interrupt_on = "obstructed",
							scan = true
						}
						table.insert(objectives, new_objective)
					end
					self:_spawn_cops_with_objectives(spawn_points, objectives, tweak_data.group_ai.besiege.assault.units)
				end
			end
		end
		return
	else
		local spawn_threshold = task_phase == "fade" and 0 or math.max(0, self._police_force_max - self._police_force)
		local objective_attitude = "engage"
		local objective_interrupt = "obstructed"
		if task_phase == "anticipation" then
			objective_attitude = "avoid"
			spawn_threshold = math.max(0, spawn_threshold - 5)
		end
		local wanted_nr_aggressive_cops = task_data.force.aggressive
		local undershot_aggressive = wanted_nr_aggressive_cops - nr_agressive_cops
		if undershot_aggressive > 0 then
			local u_key, u_data
			while undershot_aggressive > 0 and nr_defensive_cops > 0 do
				u_key, u_data = next(defensive_cops, u_key)
				if not u_key then
					break
				end
				local unit = u_data.unit
				if not u_data.follower then
					if u_data.unit:brain():is_available_for_assignment({
						type = "investigate_area",
						interrupt_on = objective_interrupt
					}) then
						local closest_dis, closest_criminal_data
						for c_key, c_data in pairs(healthy_criminals) do
							local my_dis = mvec3_dis(c_data.m_pos, u_data.m_pos)
							if not closest_dis or closest_dis > my_dis then
								closest_dis = my_dis
								closest_criminal_data = c_data
							end
						end
						if closest_criminal_data then
							local crim_area = closest_criminal_data.tracker:nav_segment()
							local new_objective = {
								type = "investigate_area",
								nav_seg = crim_area,
								attitude = objective_attitude,
								stance = "hos",
								interrupt_on = objective_interrupt,
								scan = true,
								pos = mvector3.copy(closest_criminal_data.m_pos)
							}
							unit:brain():set_objective(new_objective)
							self:_set_enemy_assigned(self._area_data[crim_area], unit:key())
							defensive_cops[u_key] = nil
							nr_defensive_cops = nr_defensive_cops - 1
							aggressive_cops[u_key] = u_data
							nr_agressive_cops = nr_agressive_cops + 1
							undershot_aggressive = undershot_aggressive - 1
						end
					end
				end
			end
			if undershot_aggressive > 0 and spawn_threshold > 0 then
				local spawn_amount = math.min(undershot_aggressive, spawn_threshold)
				local spawn_points = GroupAIStateBesiege._find_spawn_points_near_area(self, target_area, spawn_amount)
				if spawn_points then
					local objectives = {}
					for _, sp_data in ipairs(spawn_points) do
						local closest_dis, closest_criminal_data
						for c_key, c_data in pairs(healthy_criminals) do
							local my_dis = mvec3_dis(c_data.m_pos, sp_data.pos)
							if not closest_dis or closest_dis > my_dis then
								closest_dis = my_dis
								closest_criminal_data = c_data
							end
						end
						if closest_criminal_data then
							local crim_area = closest_criminal_data.tracker:nav_segment()
							local new_objective = {
								type = "investigate_area",
								nav_seg = crim_area,
								attitude = objective_attitude,
								stance = "hos",
								interrupt_on = objective_interrupt,
								scan = true,
								pos = mvector3.copy(closest_criminal_data.m_pos)
							}
							table.insert(objectives, new_objective)
						end
					end
					self:_spawn_cops_with_objectives(spawn_points, objectives, tweak_data.group_ai.street.assault.units)
					spawn_threshold = spawn_threshold - #spawn_points
				end
			end
		elseif undershot_aggressive < 0 and task_phase ~= "fade" then
			local u_key, u_data
			while undershot_aggressive < 0 do
				u_key, u_data = next(aggressive_cops, u_key)
				if not u_key then
					break
				end
				if not u_data.follower and not u_data.unit:brain()._important then
					local unit = u_data.unit
					local old_objective = unit:brain():objective()
					if old_objective and u_data.unit:brain():is_available_for_assignment() then
						local new_objective = deep_clone(old_objective)
						new_objective.attitude = "avoid"
						unit:brain():set_objective(new_objective)
						aggressive_cops[u_key] = nil
						nr_agressive_cops = nr_agressive_cops - 1
						undershot_aggressive = undershot_aggressive + 1
						defensive_cops[u_key] = u_data
						nr_defensive_cops = nr_defensive_cops + 1
					end
				end
			end
		end
		local wanted_nr_defensive_cops = task_data.force.defensive
		local undershot_defensive = wanted_nr_defensive_cops - nr_defensive_cops
		if undershot_defensive > 0 and spawn_threshold > 0 then
			local spawn_amount = math.min(undershot_defensive, spawn_threshold)
			local spawn_points = GroupAIStateBesiege._find_spawn_points_near_area(self, target_area, spawn_amount)
			if spawn_points then
				local objectives = {}
				for _, sp_data in ipairs(spawn_points) do
					local closest_dis, closest_criminal_data
					for c_key, c_data in pairs(healthy_criminals) do
						local my_dis = mvec3_dis(c_data.m_pos, sp_data.pos)
						if not closest_dis or closest_dis > my_dis then
							closest_dis = my_dis
							closest_criminal_data = c_data
						end
					end
					if closest_criminal_data then
						local crim_area = closest_criminal_data.tracker:nav_segment()
						local new_objective = {
							type = "investigate_area",
							nav_seg = crim_area,
							attitude = "avoid",
							stance = "hos",
							interrupt_on = "obstructed",
							scan = true,
							pos = mvector3.copy(closest_criminal_data.m_pos)
						}
						table.insert(objectives, new_objective)
					end
				end
				self:_spawn_cops_with_objectives(spawn_points, objectives, tweak_data.group_ai.street.assault.units)
				spawn_threshold = spawn_threshold - #spawn_points
			end
		elseif task_phase == "fade" then
			for u_key, u_data in pairs(defensive_cops) do
				local unit = u_data.unit
				if not u_data.follower then
					if u_data.unit:brain():is_available_for_assignment({
						type = "investigate_area",
						interrupt_on = "contact"
					}) then
						local closest_dis, closest_criminal_data
						for c_key, c_data in pairs(healthy_criminals) do
							local my_dis = mvec3_dis(c_data.m_pos, u_data.m_pos)
							if not closest_dis or closest_dis > my_dis then
								closest_dis = my_dis
								closest_criminal_data = c_data
							end
						end
						if closest_criminal_data then
							local crim_area = closest_criminal_data.tracker:nav_segment()
							local new_objective = {
								type = "investigate_area",
								nav_seg = crim_area,
								attitude = "engage",
								stance = "hos",
								interrupt_on = "contact",
								scan = true,
								pos = mvector3.copy(closest_criminal_data.m_pos)
							}
							unit:brain():set_objective(new_objective)
							self:_set_enemy_assigned(self._area_data[crim_area], unit:key())
							defensive_cops[u_key] = nil
							nr_defensive_cops = nr_defensive_cops - 1
							aggressive_cops[u_key] = u_data
							nr_agressive_cops = nr_agressive_cops + 1
							undershot_aggressive = undershot_aggressive - 1
						end
					end
				end
			end
		end
		for u_key, u_data in pairs(defensive_cops) do
			if not u_data.unit:brain():objective() then
				local closest_dis, closest_criminal_data
				for c_key, c_data in pairs(healthy_criminals) do
					local my_dis = mvec3_dis(c_data.m_pos, u_data.m_pos)
					if not closest_dis or closest_dis > my_dis then
						closest_dis = my_dis
						closest_criminal_data = c_data
					end
				end
				if closest_criminal_data then
					local crim_area = closest_criminal_data.tracker:nav_segment()
					local new_objective = {
						type = "investigate_area",
						nav_seg = crim_area,
						attitude = "avoid",
						stance = "hos",
						interrupt_on = "contact",
						scan = true,
						pos = mvector3.copy(closest_criminal_data.m_pos)
					}
				end
			end
		end
		if t > task_data.use_smoke_timer then
			task_data.use_smoke = true
		end
		if task_data.use_smoke and not self:is_smoke_grenade_active() then
			local shoot_smoke, shooter_pos, shooter_u_data, detonate_pos
			local duration = 0
			if self._smoke_grenade_queued then
				shoot_smoke = true
				shooter_pos = self._smoke_grenade_queued[1]
				detonate_pos = self._smoke_grenade_queued[1]
				duration = self._smoke_grenade_queued[2]
			else
				local target_area = task_data.target_area
				local shoot_from_neighbours = managers.navigation:get_nav_seg_neighbours(target_area)
				local door_found
				for u_key, u_data in pairs(self._police) do
					local nav_seg = u_data.tracker:nav_segment()
					if nav_seg == target_area then
						task_data.use_smoke = false
						door_found = nil
						break
					elseif not door_found then
						local door_ids = shoot_from_neighbours[nav_seg]
						if door_ids and tweak_data.character[u_data.unit:base()._tweak_table].use_smoke then
							local random_door_id = door_ids[math.random(#door_ids)]
							if type(random_door_id) == "number" then
								door_found = managers.navigation._room_doors[random_door_id]
								shooter_pos = mvector3.copy(u_data.m_pos)
								shooter_u_data = u_data
							end
						end
					end
				end
				if door_found then
					detonate_pos = mvector3.copy(door_found.center)
					shoot_smoke = true
				end
			end
			if shoot_smoke then
				task_data.use_smoke_timer = t + math.lerp(10, 40, math.rand(0, 1) ^ 0.5)
				task_data.use_smoke = false
				if Network:is_server() then
					local ignore_ctrl
					if self._smoke_grenade_queued and self._smoke_grenade_queued[3] then
						ignore_ctrl = true
					end
					managers.network:session():send_to_peers("sync_smoke_grenade", detonate_pos, shooter_pos, 0)
					self:sync_smoke_grenade(detonate_pos, shooter_pos, 0)
					if ignore_ctrl then
						self._smoke_grenade_ignore_control = true
					end
					if shooter_u_data and not shooter_u_data.unit:sound():speaking(self._t) and tweak_data.character[shooter_u_data.unit:base()._tweak_table].chatter.smoke then
						self:chk_say_enemy_chatter(shooter_u_data.unit, shooter_u_data.m_pos, "smoke")
					end
				end
			end
		end
	end
end
function GroupAIStateStreet:_find_spawn_points_behind_pos(start_nav_seg, target_pos, nr_wanted, fwd, nav_segs, max_dis)
	local all_areas = self._area_data
	local all_nav_segs = managers.navigation._nav_segments
	local mvec3_dis = mvector3.distance
	local mvec3_dot = mvector3.dot
	local mvec3_set = mvector3.set
	local mvec3_sub = mvector3.subtract
	local t = self._t
	local distances = {}
	local s_points = {}
	local my_vec = Vector3()
	local to_search_segs = {start_nav_seg}
	local found_segs = {}
	found_segs[start_nav_seg] = true
	if nav_segs then
		for nav_seg_id, _ in pairs(nav_segs) do
			table.insert(to_search_segs, nav_seg_id)
			found_segs[nav_seg_id] = true
		end
	end
	repeat
		local search_seg = table.remove(to_search_segs, 1)
		local area_data = all_areas[search_seg]
		local spawn_points = area_data.spawn_points
		if spawn_points then
			for _, sp_data in ipairs(spawn_points) do
				if t >= sp_data.delay_t then
					local my_dis = mvec3_dis(target_pos, sp_data.pos)
					if not max_dis or max_dis > my_dis then
						mvec3_set(my_vec, target_pos)
						mvec3_sub(my_vec, sp_data.pos)
						local my_dot = mvec3_dot(my_vec, fwd)
						if my_dot > 0 then
							local i = #distances
							while true do
								if not (i > 0) or my_dot > distances[i] then
									break
								end
								i = i - 1
							end
							if i < #distances then
								if #distances == nr_wanted then
									distances[nr_wanted] = my_dot
									s_points[nr_wanted] = sp_data
								else
									table.remove(distances)
									table.remove(s_points)
									table.insert(distances, i + 1, my_dot)
									table.insert(s_points, i + 1, sp_data)
								end
							elseif nr_wanted > i then
								table.insert(distances, my_dot)
								table.insert(s_points, sp_data)
							end
						end
					end
				end
			end
		end
		if #s_points == nr_wanted then
			break
		end
		for _seg_id, nav_seg_data in pairs(nav_segs or all_nav_segs) do
			if nav_segs then
				nav_seg_data = all_nav_segs[_seg_id]
			end
			if nav_seg_data.neighbours and not found_segs[_seg_id] and not nav_seg_data.disabled and nav_seg_data.neighbours[search_seg] then
				table.insert(to_search_segs, _seg_id)
				found_segs[_seg_id] = true
			end
		end
	until #to_search_segs == 0
	return #s_points > 0 and s_points
end
function GroupAIStateStreet:_spawn_cops_with_objective(area, spawn_points, objective, unit_weights)
	local produce_data = {
		{
			name = true,
			spawn_ai = {}
		}
	}
	for i_sp = 1, #spawn_points do
		local sp_data = spawn_points[i_sp]
		local spawn_point = sp_data.spawn_point
		local accessibility = sp_data.accessibility
		local unit_name = self:_get_spawn_unit_name(unit_weights, accessibility)
		if unit_name then
			produce_data[1].name = unit_name
			local sp_data = spawn_points[i_sp]
			local spawn_point = sp_data.spawn_point
			local spawned_enemy = spawn_point:produce(produce_data)[1]
			sp_data.delay_t = self._t + sp_data.interval
			local u_key = spawned_enemy:key()
			self:_set_enemy_assigned(self._area_data[area], u_key)
			if spawned_enemy:brain():objective() then
				spawned_enemy:brain():set_followup_objective(deep_clone(objective))
			else
				spawned_enemy:brain():set_objective(deep_clone(objective))
			end
		end
	end
end
function GroupAIStateStreet:_spawn_cops_with_objectives(spawn_points, objectives, unit_weights, spawned_units)
	local produce_data = {
		{
			name = true,
			spawn_ai = {}
		}
	}
	local nr_spawns = math.min(#spawn_points, #objectives)
	for i_sp = 1, nr_spawns do
		local sp_data = spawn_points[i_sp]
		local accessibility = sp_data.accessibility
		local unit_name = self:_get_spawn_unit_name(unit_weights, accessibility)
		if unit_name then
			produce_data[1].name = unit_name
			local spawn_point = sp_data.spawn_point
			local spawned_enemy = spawn_point:produce(produce_data)[1]
			sp_data.delay_t = self._t + sp_data.interval
			local u_key = spawned_enemy:key()
			self:_set_enemy_assigned(self._area_data[objectives[i_sp].nav_seg], u_key)
			if spawned_enemy:brain():objective() then
				spawned_enemy:brain():set_followup_objective(objectives[i_sp])
			else
				spawned_enemy:brain():set_objective(objectives[i_sp])
			end
			if spawned_units then
				table.insert(spawned_units, spawned_enemy)
			end
		end
	end
end
function GroupAIStateStreet:_begin_regroup_task(from_assault)
	self._task_data.regroup.start_t = self._t
	self._task_data.regroup.end_t = self._t + self:_get_difficulty_dependent_value(tweak_data.group_ai.street.regroup.duration)
	self._task_data.regroup.active = true
	self._task_data.regroup.from_assault = from_assault
	if self._draw_drama then
		table.insert(self._draw_drama.regroup_hist, {
			self._t
		})
	end
end
function GroupAIStateStreet:_upd_regroup_task(t)
	GroupAIStateBesiege._upd_regroup_task(self)
end
function GroupAIStateStreet:_find_nearest_safe_area(nav_seg_id, start_pos)
	return GroupAIStateBesiege._find_nearest_safe_area(self, nav_seg_id, start_pos)
end
function GroupAIStateStreet:_end_regroup_task(regroup_task)
	regroup_task = regroup_task or self._task_data.regroup
	if self._wave_mode then
		local assault_delay = tweak_data.group_ai.street[self._wave_mode].delay
		self._task_data[self._wave_mode].next_dispatch_t = self._t + math.lerp(assault_delay[1], assault_delay[2], math.random())
	end
	regroup_task.active = nil
	regroup_task.end_t = nil
	regroup_task.start_t = nil
	if regroup_task.from_assault then
		managers.trade:set_trade_countdown(true)
		self:set_assault_mode(false)
		if not self._smoke_grenade_ignore_control then
			managers.network:session():send_to_peers("sync_smoke_grenade_kill")
			self:sync_smoke_grenade_kill()
		end
		local dmg = self._downs_during_assault
		local limits = tweak_data.group_ai.bain_assault_praise_limits
		local result = dmg < limits[1] and 0 or dmg < limits[2] and 1 or 2
		print("self._downs_during_assault", result, dmg)
		managers.hud:end_assault(result)
	end
	self:_mark_hostage_areas_as_unsafe()
	self:_set_rescue_state(true)
	if self._draw_drama then
		self._draw_drama.regroup_hist[#self._draw_drama.regroup_hist][2] = self._t
	end
end
function GroupAIStateStreet:is_area_safe(nav_seg)
	local all_areas = self._area_data
	local area = all_areas[nav_seg]
	return area and area.is_safe
end
function GroupAIStateStreet:set_enemy_assigned(nav_seg, unit_key)
	GroupAIStateBesiege._set_enemy_assigned(self, self._area_data[nav_seg], unit_key)
end
function GroupAIStateStreet:_set_enemy_assigned(area_data, unit_key)
	GroupAIStateBesiege._set_enemy_assigned(self, area_data, unit_key)
end
function GroupAIStateStreet:criminal_spotted(unit)
	local u_key = unit:key()
	local u_sighting = self._criminals[u_key]
	local prev_seg = u_sighting.seg
	GroupAIStateStreet.super.criminal_spotted(self, unit)
	local seg = u_sighting.seg
	local area_data = self._area_data[seg]
	if prev_seg ~= seg then
		local old_area_data = self._area_data[prev_seg]
		if old_area_data then
			old_area_data.criminal.units[u_key] = nil
		end
		area_data.criminal.units[u_key] = {}
	end
	if area_data.is_safe then
		area_data.is_safe = nil
		self:_on_area_safety_status(seg, {reason = "criminal", record = u_sighting})
	end
end
function GroupAIStateStreet:on_objective_complete(unit, objective)
	GroupAIStateBesiege.on_objective_complete(self, unit, objective)
end
function GroupAIStateStreet:on_defend_travel_end(unit, objective)
	local seg = objective.nav_seg
	local area_data = self._area_data[seg]
	if not area_data.is_safe then
		area_data.is_safe = true
		self:_on_area_safety_status(seg, {reason = "guard", unit = unit})
	end
end
function GroupAIStateStreet:on_cop_jobless(unit)
end
function GroupAIStateStreet:_empty_area_data()
	return {
		police = {
			units = {}
		},
		criminal = {
			units = {}
		},
		factors = {},
		neighbours = {}
	}
end
function GroupAIStateStreet:_map_spawn_points_to_respective_areas(id, spawn_points)
	GroupAIStateBesiege._map_spawn_points_to_respective_areas(self, id, spawn_points)
end
function GroupAIStateStreet:add_preferred_spawn_points(id, spawn_points)
	GroupAIStateBesiege.add_preferred_spawn_points(self, id, spawn_points)
end
function GroupAIStateStreet:remove_preferred_spawn_points(id)
	GroupAIStateBesiege.remove_preferred_spawn_points(self, id)
end
function GroupAIStateStreet:_draw_enemy_activity(t)
	GroupAIStateBesiege._draw_enemy_activity(self, t)
end
function GroupAIStateStreet:on_nav_segment_state_change(changed_seg, state)
	GroupAIStateBesiege.on_nav_segment_state_change(self, changed_seg, state)
end
function GroupAIStateStreet:find_occupation_in_area(nav_seg)
	return GroupAIStateBesiege.find_occupation_in_area(self, nav_seg)
end
function GroupAIStateStreet:verify_occupation_in_area(objective)
	return GroupAIStateBesiege.verify_occupation_in_area(self, objective)
end
function GroupAIStateStreet:filter_area_unsafe(nav_seg)
	return not self:is_area_safe()
end
function GroupAIStateStreet:_on_area_safety_status(seg, event)
	local all_areas = self._area_data
	local area_data = all_areas[seg]
	local safe = area_data.is_safe
	local unit_data = self._police
	for u_key, _ in pairs(area_data.police.units) do
		local unit = unit_data[u_key].unit
		unit:brain():on_area_safety(seg, safe, event)
	end
	if area_data.neighbours then
		for _, neighbour_data in pairs(area_data.neighbours) do
			for u_key, _ in pairs(all_areas[neighbour_data.seg].police.units) do
				local unit = unit_data[u_key].unit
				unit:brain():on_area_safety(seg, safe, event)
			end
		end
	end
end
function GroupAIStateStreet:add_flee_point(id, pos)
	self._flee_points[id] = pos
end
function GroupAIStateStreet:remove_flee_point(id)
	self._flee_points[id] = nil
end
function GroupAIStateStreet:flee_point(unit)
	local flee_point_id, flee_point = next(self._flee_points)
	return flee_point
end
function GroupAIStateStreet:_draw_spawn_points()
	local all_areas = self._area_data
	for seg_id, area_data in pairs(all_areas) do
		local area_spawn_points = area_data.spawn_points
		if area_spawn_points then
			for _, sp_data in ipairs(area_spawn_points) do
				Application:draw_sphere(sp_data.pos, 220, 0.1, 0.4, 0.6)
			end
		end
	end
end
function GroupAIStateStreet:on_hostage_fleeing(unit)
	self._hostage_fleeing = unit
end
function GroupAIStateStreet:on_hostage_flee_end()
	self._hostage_fleeing = nil
end
function GroupAIStateStreet:can_hostage_flee()
	return not self._hostage_fleeing
end
function GroupAIStateStreet:add_to_surrendered(unit, update)
	local hos_data = self._hostage_data
	local nr_entries = #hos_data
	local entry = {
		u_key = unit:key(),
		clbk = update
	}
	if not self._hostage_upd_key then
		self._hostage_upd_key = "GroupAIStateStreet:_upd_hostage_task"
		managers.enemy:queue_task(self._hostage_upd_key, self._upd_hostage_task, self, self._t + 1)
	end
	table.insert(hos_data, entry)
end
function GroupAIStateStreet:remove_from_surrendered(unit)
	local hos_data = self._hostage_data
	local u_key = unit:key()
	for i, entry in ipairs(hos_data) do
		if u_key == entry.u_key then
			table.remove(hos_data, i)
		else
		end
	end
	if #hos_data == 0 then
		managers.enemy:unqueue_task(self._hostage_upd_key)
		self._hostage_upd_key = nil
	end
end
function GroupAIStateStreet:_upd_hostage_task()
	self._hostage_upd_key = nil
	local hos_data = self._hostage_data
	local first_entry = hos_data[1]
	table.remove(hos_data, 1)
	first_entry.clbk()
	if not self._hostage_upd_key and #hos_data > 0 then
		self._hostage_upd_key = "GroupAIStateStreet:_upd_hostage_task"
		managers.enemy:queue_task(self._hostage_upd_key, self._upd_hostage_task, self, self._t + 1)
	end
end
function GroupAIStateStreet:get_unit_assigned_area(u_key)
	local u_area_data = self._police[u_key].assigned_area
	if u_area_data then
		for nav_seg, area_data in pairs(self._area_data) do
			if area_data == u_area_data then
				return nav_seg
			end
		end
	end
end
function GroupAIStateStreet:set_area_min_police_force(id, force, pos)
	GroupAIStateBesiege.set_area_min_police_force(self, id, force, pos)
	if force and force > 0 then
		local nav_seg = managers.navigation:get_nav_seg_from_pos(pos)
		local factors = self._area_data[nav_seg].factors
		factors.force = {id = id, force = force}
		for i_task, task_data in ipairs(self._task_data.reenforce.tasks) do
			if task_data.target_area == nav_seg then
				task_data.force_required = force
				return
			end
		end
		self:_begin_reenforce_task(nav_seg, force)
	else
		for nav_seg, area_data in pairs(self._area_data) do
			local force_factor = area_data.factors.force
			if force_factor and force_factor.id == id then
				area_data.factors.force = nil
				local tasks = self._task_data.reenforce.tasks
				for i_task, task_data in ipairs(tasks) do
					if task_data.target_area == nav_seg then
						tasks[i_task] = tasks[#tasks]
						table.remove(tasks)
						if #tasks == 0 then
							self._task_data.reenforce.active = nil
						end
					else
					end
				end
				return
			end
		end
	end
end
function GroupAIStateStreet:set_mission_fwd_vector(direction, position)
	Application:error("[GroupAIStateStreet:set_mission_fwd_vector] Redundant function call.")
end
function GroupAIStateStreet:register_criminal(unit)
	GroupAIStateBesiege.register_criminal(self, unit)
end
function GroupAIStateStreet:unregister_criminal(unit)
	GroupAIStateBesiege.unregister_criminal(self, unit)
end
function GroupAIStateStreet:set_wave_mode(flag)
	local old_wave_mode = self._wave_mode
	self._wave_mode = flag
	local task_data = self._task_data
	self._hunt_mode = nil
	if flag == "blockade" then
		task_data.blockade.passive = nil
		if old_wave_mode ~= flag then
			local next_dispatch_t = task_data.assault.next_dispatch_t
			task_data.assault.active = nil
			if next_dispatch_t then
				task_data.assault.next_dispatch_t = nil
				task_data.blockade.next_dispatch_t = next_dispatch_t
			elseif not task_data.regroup.active then
				task_data.blockade.next_dispatch_t = self._t
			end
		end
	elseif flag == "assault" then
		if old_wave_mode ~= flag then
			task_data.blockade.active = nil
			local next_dispatch_t = task_data.blockade.next_dispatch_t
			if next_dispatch_t then
				task_data.blockade.next_dispatch_t = nil
				task_data.assault.next_dispatch_t = next_dispatch_t
			elseif not task_data.regroup.active then
				task_data.assault.next_dispatch_t = self._t
			end
		else
			self:_begin_assault_task(self._t)
		end
	elseif flag == "hunt" then
		self._hunt_mode = true
		self._wave_mode = "assault"
		task_data.blockade.active = nil
		task_data.blockade.next_dispatch_t = nil
		managers.hud:start_assault()
		self:_set_rescue_state(false)
		self:set_assault_mode(true)
		managers.trade:set_trade_countdown(false)
		self:_end_regroup_task(self._task_data.regroup)
		if task_data.assault.active then
			task_data.assault.phase = "sustain"
			task_data.use_smoke = true
			task_data.use_smoke_timer = 0
		else
			task_data.assault.next_dispatch_t = self._t
		end
	elseif flag == "quiet" then
		task_data.blockade.next_dispatch_t = nil
		task_data.assault.next_dispatch_t = nil
	elseif flag == "passive" then
		task_data.blockade.passive = true
		self._wave_mode = old_wave_mode
	else
		self._wave_mode = old_wave_mode
		Application:error("[GroupAIStateStreet:set_wave_mode] flag", flag, " does not apply to the current Group AI state.")
	end
end
function GroupAIStateStreet:on_simulation_ended()
	GroupAIStateStreet.super.on_simulation_ended(self)
	if managers.navigation:is_data_ready() then
		self._criminal_drama_demand = 4
		self._nr_active_units = 0
		self._blockade_spots_mapped = nil
		GroupAIStateBesiege._create_area_data(self)
		self._is_first_assault = true
		self._task_data = {}
		self._task_data.blockade = {}
		self._task_data.assault = {}
		self._task_data.regroup = {}
		self._task_data.reenforce = {
			tasks = {}
		}
	end
	if self._police_upd_task_queued then
		self._police_upd_task_queued = nil
		managers.enemy:unqueue_task("GroupAIStateStreet._upd_police_activity")
	end
end
function GroupAIStateStreet:on_simulation_started()
	GroupAIStateStreet.super.on_simulation_started(self)
	if managers.navigation:is_data_ready() then
		self._police_force_max = 25
		self._police_force_calm = 18
		self._nr_active_units = 0
		self._blockade_spots_mapped = nil
	end
	if not self._police_upd_task_queued then
		self:_queue_police_upd_task()
	end
end
function GroupAIStateStreet:add_spawn_event(id, event_data)
	GroupAIStateStreet.super.add_spawn_event(self, id, event_data)
	if event_data.task_type == "blockade" then
		local nav_seg = managers.navigation:get_nav_seg_from_pos(event_data.pos)
		event_data.nav_seg = nav_seg
		local relevant_nav_segments = managers.navigation:get_nav_segments_in_direction(nav_seg, event_data.rot:y())
		event_data.relevant_areas = relevant_nav_segments
	end
end
function GroupAIStateStreet:_map_ai_blockade_spots()
	self._blockade_spots_mapped = true
	local nav_manager = managers.navigation
	local nav_seg_func = nav_manager.get_nav_seg_from_pos
	local all_areas = self._area_data
	local all_spots = managers.helper_unit:get_units_by_type("ai_blockade")
	for _, spot_unit in ipairs(all_spots) do
		local pos = spot_unit:position()
		local nav_seg = nav_seg_func(nav_manager, pos, true)
		local entry = {
			spot_unit,
			pos,
			spot_unit:rotation():y()
		}
		local area = all_areas[nav_seg]
		area.blockade_spots = area.blockade_spots or {}
		table.insert(area.blockade_spots, entry)
	end
end
function GroupAIStateStreet:is_detection_persistent()
	return not self._task_data.assault.active and (not self._task_data.regroup.active or not self._task_data.regroup.phase) and self._task_data.blockade.active and self._task_data.blockade.phase
end
function GroupAIStateStreet:is_smoke_grenade_active()
	return self._smoke_end_t and Application:time() < self._smoke_end_t
end
