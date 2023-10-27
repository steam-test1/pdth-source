GroupAIStateBesiege = GroupAIStateBesiege or class(GroupAIStateBase)
function GroupAIStateBesiege:init()
	GroupAIStateBesiege.super.init(self)
	if Network:is_server() and not self._police_upd_task_queued and managers.navigation:is_data_ready() then
		self:_queue_police_upd_task()
	end
end
function GroupAIStateBesiege:_init_misc_data()
	GroupAIStateBesiege.super:_init_misc_data(self)
	if managers.navigation:is_data_ready() then
		self._police_force_max = 25
		self._police_force_calm = 18
		self._criminal_drama_demand = 4
		self._nr_active_units = 0
		self._nr_dynamic_waves = 0
		self._nr_waves = 0
		self:_create_area_data()
		self._task_data = {}
		self._task_data.reenforce = {
			tasks = {},
			next_dispatch_t = 0
		}
		self._task_data.recon = {
			tasks = {},
			next_dispatch_t = 0
		}
		self._task_data.assault = {disabled = true, is_first = true}
		self._task_data.regroup = {}
		local all_areas = self._area_data
		for u_key, u_data in pairs(self._police) do
			if not u_data.assigned_area then
				local nav_seg = u_data.unit:movement():nav_tracker():nav_segment()
				self:_set_enemy_assigned(all_areas[nav_seg], u_key)
			end
		end
	end
end
function GroupAIStateBesiege:update(t, dt)
	GroupAIStateBesiege.super.update(self, t, dt)
	if Network:is_server() then
		if not self._police_upd_task_queued then
			self:_queue_police_upd_task()
		end
		if managers.navigation:is_data_ready() and self._draw_enabled then
			self:_draw_enemy_activity(t)
			self:_draw_spawn_points()
		end
	end
end
function GroupAIStateBesiege:paused_update(t, dt)
	GroupAIStateBesiege.super.paused_update(self, t, dt)
	if Network:is_server() then
		self:_draw_spawn_points()
		if managers.navigation:is_data_ready() and self._draw_enabled then
			self:_draw_enemy_activity(t)
		end
	end
end
function GroupAIStateBesiege:_queue_police_upd_task()
	self._police_upd_task_queued = true
	managers.enemy:queue_task("GroupAIStateBesiege._upd_police_activity", GroupAIStateBesiege._upd_police_activity, self, self._t + 2)
end
function GroupAIStateBesiege:assign_enemy_to_group_ai(unit)
	local u_tracker = unit:movement():nav_tracker()
	local seg = u_tracker:nav_segment()
	self:_set_enemy_assigned(self._area_data[seg], unit:key())
end
function GroupAIStateBesiege:on_enemy_unregistered(unit)
	GroupAIStateBesiege.super.on_enemy_unregistered(self, unit)
	if self._is_server then
		self:_set_enemy_assigned(nil, unit:key())
		local objective = unit:brain():objective()
		if objective and objective.fail_clbk then
			local fail_clbk = objective.fail_clbk
			objective.fail_clbk = nil
			fail_clbk(unit)
		end
	end
end
function GroupAIStateBesiege:on_enemy_active_state_change(unit, state)
	local u_properties = self._police[unit:key()]
	self:_mark_enemy_active_state(u_properties, state)
end
function GroupAIStateBesiege:_mark_enemy_active_state(u_properties, state)
	if state then
		if not u_properties.active then
			self._nr_active_units = self._nr_active_units + 1
			u_properties.active = true
			if u_properties.active == false then
				self._nr_active_units = self._nr_active_units - 1
			end
		end
	else
		if u_properties.active then
			self._nr_active_units = self._nr_active_units - 1
		end
		if u_properties.active ~= false then
			self._nr_active_units = self._nr_active_units + 1
			u_properties.active = false
		end
	end
end
function GroupAIStateBesiege:_upd_police_activity()
	self._police_upd_task_queued = false
	if self._ai_enabled then
		self:_upd_SO()
		if self._player_weapons_hot then
			self:_claculate_drama_value()
			self:_upd_regroup_task()
			self:_upd_reenforce_tasks()
			self:_upd_recon_tasks()
			self:_upd_assault_task()
			self:_begin_new_tasks()
		end
	end
	self:_queue_police_upd_task()
end
function GroupAIStateBesiege:_upd_SO()
	local t = self._t
	local trash
	for id, so in pairs(self._special_objectives) do
		if t > so.delay_t then
			so.delay_t = t + so.data.interval
			if math.random() <= so.chance then
				local so_data = so.data
				so.chance = so_data.base_chance
				if so_data.objective.follow_unit and not alive(so_data.objective.follow_unit) then
					trash = trash or {}
					table.insert(trash, id)
				else
					local closest_u_data = GroupAIStateBase._execute_so(self, so_data, so.rooms, so.administered)
					if closest_u_data then
						if so.remaining_usage then
							if so.remaining_usage == 1 then
								trash = trash or {}
								table.insert(trash, id)
							else
								so.remaining_usage = so.remaining_usage - 1
							end
						end
						if so.non_repeatable then
							so.administered[closest_u_data.unit:key()] = true
						end
					end
				end
			else
				so.chance = so.chance + so.data.chance_inc
			end
			if so.data.interval < 0 then
				trash = trash or {}
				table.insert(trash, id)
			end
		end
	end
	if trash then
		for _, so_id in ipairs(trash) do
			self:remove_special_objective(so_id)
		end
	end
end
function GroupAIStateBesiege:_begin_new_tasks()
	local all_areas = self._area_data
	local nav_manager = managers.navigation
	local all_nav_segs = nav_manager._nav_segments
	local task_data = self._task_data
	local t = self._t
	local reenforce_candidates
	local reenforce_data = task_data.reenforce
	if reenforce_data.next_dispatch_t and t > reenforce_data.next_dispatch_t then
		reenforce_candidates = {}
	end
	local recon_candidates
	local recon_data = task_data.recon
	if recon_data.next_dispatch_t and t > recon_data.next_dispatch_t and not task_data.assault.active and not task_data.regroup.active then
		recon_candidates = {}
	end
	local assault_candidates
	local assault_data = task_data.assault
	if assault_data.next_dispatch_t and t > assault_data.next_dispatch_t and not task_data.regroup.active then
		assault_candidates = {}
	end
	if not reenforce_candidates and not recon_candidates and not assault_candidates then
		return
	end
	local found_segs = {}
	local to_search_segs = {}
	for nav_seg, area_data in pairs(all_areas) do
		if area_data.spawn_points and not all_nav_segs[nav_seg].disabled then
			for _, sp_data in pairs(area_data.spawn_points) do
				if t >= sp_data.delay_t then
					table.insert(to_search_segs, nav_seg)
					found_segs[nav_seg] = true
					break
				end
			end
		end
	end
	if #to_search_segs == 0 then
		return
	end
	if assault_candidates and self._hunt_mode then
		for criminal_key, criminal_data in pairs(self._criminals) do
			if not criminal_data.status then
				local nav_seg = criminal_data.tracker:nav_segment()
				found_segs[nav_seg] = true
				table.insert(assault_candidates, nav_seg)
			end
		end
	end
	local i = 1
	repeat
		local search_seg = to_search_segs[i]
		local area = all_areas[search_seg]
		local force_factor = area.factors.force
		local demand = force_factor and force_factor.force
		local nr_police = table.size(area.police.units)
		local nr_criminals = table.size(area.criminal.units)
		local undershot = demand and demand - nr_police
		if reenforce_candidates and undershot and 0 < undershot and nr_criminals == 0 then
			local area_free = true
			for i_task, reenforce_task_data in ipairs(reenforce_data.tasks) do
				if reenforce_task_data.target_area == search_seg then
					area_free = false
					break
				end
			end
			if area_free then
				table.insert(reenforce_candidates, {search_seg, undershot})
			end
		end
		if recon_candidates and not area.is_safe and nr_criminals == 0 and nr_police == 0 then
			table.insert(recon_candidates, search_seg)
		end
		if assault_candidates then
			for criminal_key, _ in pairs(area.criminal.units) do
				if not self._criminals[criminal_key].status then
					table.insert(assault_candidates, search_seg)
					break
				end
			end
		end
		if nr_criminals == 0 then
			for _neigh_seg_id, doors in pairs(all_nav_segs[search_seg].neighbours) do
				if not found_segs[_neigh_seg_id] then
					if not all_nav_segs[_neigh_seg_id].disabled then
						table.insert(to_search_segs, _neigh_seg_id)
					end
					found_segs[_neigh_seg_id] = true
				end
			end
		end
		i = i + 1
	until i > #to_search_segs
	if assault_candidates and 0 < #assault_candidates then
		self:_begin_assault_task(assault_candidates)
		recon_candidates = nil
	end
	if reenforce_candidates and 0 < #reenforce_candidates then
		local lucky_i_candidate = math.random(#reenforce_candidates)
		local reenforce_area = reenforce_candidates[lucky_i_candidate][1]
		local undershot = reenforce_candidates[lucky_i_candidate][2]
		self:_begin_reenforce_task(reenforce_area, undershot)
		recon_candidates = nil
	end
	if recon_candidates and 0 < #recon_candidates then
		local best_i_candidate, best_has_hostages
		for i_area, seg_id in ipairs(recon_candidates) do
			for u_key, u_data in ipairs(managers.enemy:all_civilians()) do
				if seg_id == u_data.tracker:nav_segment() then
					local so_id = u_data.unit:brain():wants_rescue()
					if so_id then
						best_has_hostages = true
						best_i_candidate = i_area
						break
					end
				end
			end
			if best_has_hostages then
				break
			end
		end
		best_i_candidate = best_i_candidate or math.random(#recon_candidates)
		local recon_area = recon_candidates[best_i_candidate]
		self:_begin_recon_task(recon_area)
	end
end
function GroupAIStateBesiege:_begin_assault_task(assault_areas)
	local assault_task = self._task_data.assault
	assault_task.active = true
	assault_task.next_dispatch_t = nil
	assault_task.target_areas = assault_areas
	assault_task.phase = "anticipation"
	assault_task.start_t = self._t
	local anticipation_duration = self:_get_anticipation_duration(tweak_data.group_ai.besiege.assault.anticipation_duration, assault_task.is_first)
	assault_task.is_first = nil
	assault_task.phase_end_t = self._t + anticipation_duration
	assault_task.force = math.ceil(self:_get_difficulty_dependent_value(tweak_data.group_ai.besiege.assault.force))
	assault_task.use_smoke = true
	assault_task.use_smoke_timer = 0
	assault_task.use_spawn_event = true
	self._downs_during_assault = 0
	if self._hunt_mode then
		assault_task.phase_end_t = 0
	else
		managers.hud:setup_anticipation(anticipation_duration)
		managers.hud:start_anticipation()
	end
	if self._draw_drama then
		table.insert(self._draw_drama.assault_hist, {
			self._t
		})
	end
end
function GroupAIStateBesiege:_upd_assault_task()
	local task_data = self._task_data.assault
	if not task_data.active then
		return
	end
	local t = self._t
	if task_data.phase == "anticipation" then
		if t > task_data.phase_end_t then
			managers.hud:start_assault()
			self:_set_rescue_state(false)
			task_data.phase = "build"
			task_data.phase_end_t = self._t + tweak_data.group_ai.besiege.assault.build_duration
			self:set_assault_mode(true)
			managers.trade:set_trade_countdown(false)
		else
			managers.hud:check_anticipation_voice(task_data.phase_end_t - t)
			managers.hud:check_start_anticipation_music(task_data.phase_end_t - t)
		end
	elseif task_data.phase == "build" then
		if t > task_data.phase_end_t or self._drama_data.zone == "high" then
			task_data.phase = "sustain"
			task_data.phase_end_t = t + math.lerp(self:_get_difficulty_dependent_value(tweak_data.group_ai.besiege.assault.sustain_duration_min), self:_get_difficulty_dependent_value(tweak_data.group_ai.besiege.assault.sustain_duration_max), math.random())
		end
	elseif task_data.phase == "sustain" then
		if t > task_data.phase_end_t and not self._hunt_mode then
			task_data.phase = "fade"
			task_data.use_smoke = false
			task_data.use_smoke_timer = t + 20
			task_data.phase_end_t = t + 10
		end
	elseif t > task_data.phase_end_t - 8 and not task_data.said_retreat then
		if self._drama_data.amount < tweak_data.drama.assault_fade_end then
			task_data.said_retreat = true
			self:_police_announce_retreat()
		end
	elseif t > task_data.phase_end_t and self._drama_data.amount < tweak_data.drama.assault_fade_end then
		task_data.active = nil
		task_data.phase = nil
		task_data.said_retreat = nil
		if self._draw_drama then
			self._draw_drama.assault_hist[#self._draw_drama.assault_hist][2] = t
		end
		self:_begin_regroup_task()
		return
	end
	local primary_target_area = task_data.target_areas[1]
	local area_data = self._area_data[primary_target_area]
	local area_safe = true
	for criminal_key, _ in pairs(area_data.criminal.units) do
		local criminal_data = self._criminals[criminal_key]
		if not criminal_data.status then
			local crim_area = criminal_data.tracker:nav_segment()
			if crim_area == primary_target_area then
				area_safe = nil
				break
			end
		end
	end
	if area_safe then
		local target_pos = managers.navigation._nav_segments[primary_target_area].pos
		local nearest_area, nearest_dis
		for criminal_key, criminal_data in pairs(self._criminals) do
			if not criminal_data.status then
				local dis = mvector3.distance_sq(target_pos, criminal_data.m_pos)
				if not nearest_dis or nearest_dis > dis then
					nearest_dis = dis
					nearest_area = criminal_data.tracker:nav_segment()
				end
			end
		end
		if nearest_area then
			primary_target_area = nearest_area
			task_data.target_areas[1] = nearest_area
		end
	end
	if task_data.phase == "anticipation" then
		local spawn_threshold = math.max(0, self._police_force_max - self._police_force - 5)
		if 0 < spawn_threshold then
			local nr_wanted = math.min(spawn_threshold, task_data.force - self._police_force)
			if 0 < nr_wanted then
				nr_wanted = math.min(3, nr_wanted)
				local spawn_points = self:_find_spawn_points_near_area(primary_target_area, nr_wanted, nil, 10000, callback(self, self, "_verify_anticipation_spawn_point"))
				if spawn_points then
					local objectives = {}
					local function complete_clbk(chatter_unit)
						if not chatter_unit:sound():speaking(self._t) and tweak_data.character[chatter_unit:base()._tweak_table].chatter.ready then
							self:chk_say_enemy_chatter(chatter_unit, chatter_unit:movement():m_pos(), "ready")
						end
					end
					for _, sp_data in ipairs(spawn_points) do
						local new_objective = {
							type = "investigate_area",
							nav_seg = sp_data.nav_seg,
							attitude = "avoid",
							stance = "hos",
							interrupt_on = "obstructed",
							scan = true,
							complete_clbk = complete_clbk
						}
						table.insert(objectives, new_objective)
					end
					GroupAIStateStreet._spawn_cops_with_objectives(self, spawn_points, objectives, tweak_data.group_ai.besiege.assault.units)
				end
			end
		end
		return
	end
	if task_data.phase ~= "fade" and task_data.phase ~= "anticipation" then
		local spawn_threshold = math.max(0, self._police_force_max - self._police_force)
		if 0 < spawn_threshold then
			local nr_wanted = math.min(spawn_threshold, task_data.force - self._police_force)
			if 0 < nr_wanted then
				local used_event
				if task_data.use_spawn_event then
					task_data.use_spawn_event = false
					if self:_try_use_task_spawn_event(t, primary_target_area, "assault") then
						used_event = true
					end
				end
				if not used_event then
					nr_wanted = math.min(3, nr_wanted)
					local spawn_points = self:_find_spawn_points_near_area(primary_target_area, nr_wanted)
					if spawn_points then
						self:_spawn_cops_to_recon(primary_target_area, spawn_points, "engage", "assault")
					end
				end
			end
		end
		local existing_cops = self:_find_surplus_cops_around_area(primary_target_area, 100, 0)
		if existing_cops then
			self:_assign_cops_to_recon(primary_target_area, existing_cops, "engage")
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
			local door_found
			local shoot_from_neighbours = managers.navigation:get_nav_seg_neighbours(primary_target_area)
			for u_key, u_data in pairs(self._police) do
				local nav_seg = u_data.tracker:nav_segment()
				if nav_seg == primary_target_area then
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
				managers.network:session():send_to_peers("sync_smoke_grenade", detonate_pos, shooter_pos, duration)
				self:sync_smoke_grenade(detonate_pos, shooter_pos, duration)
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
function GroupAIStateBesiege:_verify_anticipation_spawn_point(sp_data)
	local sp_nav_seg = sp_data.nav_seg
	local area = self._area_data[sp_nav_seg]
	if area.is_safe then
		return true
	else
		for criminal_key, c_data in pairs(self._criminals) do
			if not c_data.status and mvector3.distance(sp_data.pos, c_data.m_pos) < 2500 and math.abs(sp_data.pos.z - c_data.m_pos.z) < 300 then
				return
			end
		end
	end
	return true
end
function GroupAIStateBesiege:is_smoke_grenade_active()
	return self._smoke_end_t and Application:time() < self._smoke_end_t
end
function GroupAIStateBesiege:_begin_reenforce_task(reenforce_area, undershot)
	local force = tweak_data.group_ai.besiege.reenforce.group_size
	local new_task = {
		target_area = reenforce_area,
		start_t = self._t,
		force_required = math.min(undershot, math.random(force[1], force[2])),
		force_assigned = 0,
		use_spawn_event = true
	}
	table.insert(self._task_data.reenforce.tasks, new_task)
	self._task_data.reenforce.active = true
	self._task_data.reenforce.next_dispatch_t = self._t + self:_get_difficulty_dependent_value(tweak_data.group_ai.besiege.reenforce.interval)
end
function GroupAIStateBesiege:_begin_recon_task(recon_area)
	local group_size = tweak_data.group_ai.besiege.recon.group_size
	local force = math.ceil(self:_get_difficulty_dependent_value(group_size))
	local new_task = {
		target_area = recon_area,
		start_t = self._t,
		force_required = force,
		force_assigned = 0,
		use_spawn_event = true
	}
	table.insert(self._task_data.recon.tasks, new_task)
	self._task_data.recon.next_dispatch_t = nil
end
function GroupAIStateBesiege:_begin_regroup_task()
	self._task_data.regroup.start_t = self._t
	self._task_data.regroup.end_t = self._t + self:_get_difficulty_dependent_value(tweak_data.group_ai.besiege.regroup.duration)
	self._task_data.regroup.active = true
	if self._draw_drama then
		table.insert(self._draw_drama.regroup_hist, {
			self._t
		})
	end
end
function GroupAIStateBesiege:_end_regroup_task()
	if self._task_data.regroup.active then
		self._task_data.regroup.active = nil
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
		self:_mark_hostage_areas_as_unsafe()
		self:_set_rescue_state(true)
		if not self._task_data.assault.next_dispatch_t then
			local assault_delay = tweak_data.group_ai.besiege.assault.delay
			self._task_data.assault.next_dispatch_t = self._t + self:_get_difficulty_dependent_value(assault_delay)
		end
		if self._draw_drama then
			self._draw_drama.regroup_hist[#self._draw_drama.regroup_hist][2] = self._t
		end
	end
end
function GroupAIStateBesiege:_upd_regroup_task()
	local regroup_task = self._task_data.regroup
	if regroup_task.active then
		local template_objective = {
			type = "free",
			attitude = "avoid",
			scan = true,
			stance = "hos",
			interrupt_on = "obstructed"
		}
		local nr_assigned = 0
		for u_key, u_data in pairs(self._police) do
			if u_data.assigned_area then
				local current_objective = u_data.unit:brain():objective()
				if current_objective and current_objective.attitude == "engage" and u_data.unit:brain():is_available_for_assignment(template_objective) then
					local seg = u_data.tracker:nav_segment()
					local nearest_safe_seg = self:_find_nearest_safe_area(seg, u_data.m_pos)
					local new_objective = clone(template_objective)
					if nearest_safe_seg then
						new_objective.nav_seg = nearest_safe_seg
					else
						new_objective.nav_seg = seg
					end
					u_data.unit:brain():set_objective(new_objective)
					self:_set_enemy_assigned(self._area_data[seg], u_key)
					if not u_data.unit:sound():speaking(self._t) then
						self:chk_say_enemy_chatter(u_data.unit, u_data.m_pos, "retreat")
					end
					if nr_assigned == 2 then
						break
					else
						nr_assigned = nr_assigned + 1
					end
				end
			end
		end
		if self._t > regroup_task.end_t or self._drama_data.zone == "low" and nr_assigned == 0 then
			self:_end_regroup_task()
		end
	end
end
function GroupAIStateBesiege:_find_nearest_safe_area(nav_seg_id, start_pos)
	local mvec3_dis_sq = mvector3.distance_sq
	local all_areas = self._area_data
	local all_nav_segs = managers.navigation._nav_segments
	local all_doors = managers.navigation._room_doors
	local my_enemy_pos, my_enemy_dis_sq
	for c_key, c_data in pairs(self._criminals) do
		local my_dis = mvec3_dis_sq(start_pos, c_data.m_pos)
		if (not my_enemy_pos or my_enemy_dis_sq < my_dis) and math.abs(mvector3.z(c_data.m_pos) - mvector3.z(start_pos)) < 300 then
			my_enemy_pos = c_data.m_pos
			my_enemy_dis_sq = my_dis
		end
	end
	if not my_enemy_pos or 9000000 < my_enemy_dis_sq then
		return
	end
	local closest_dis, closest_safe_nav_seg_id
	local start_neighbours = all_nav_segs[nav_seg_id].neighbours
	for neighbour_seg_id, door_list in pairs(start_neighbours) do
		local neighbour_area = all_areas[neighbour_seg_id]
		if not next(neighbour_area.criminal.units) then
			local neighbour_nav_seg = all_nav_segs[neighbour_seg_id]
			if not neighbour_nav_seg.disabled and my_enemy_dis_sq < mvec3_dis_sq(my_enemy_pos, neighbour_nav_seg.pos) then
				for _, i_door in ipairs(door_list) do
					if type(i_door) == "number" then
						local door = all_doors[i_door]
						local my_dis = mvec3_dis_sq(door.center, start_pos)
						if not closest_dis or closest_dis > my_dis then
							closest_dis = my_dis
							closest_safe_nav_seg_id = neighbour_seg_id
						end
					end
				end
			end
		end
	end
	return closest_safe_nav_seg_id
end
function GroupAIStateBesiege:_upd_recon_tasks()
	local recon_tasks = self._task_data.recon.tasks
	local t = self._t
	local i = #recon_tasks
	while 0 < i do
		local task_data = recon_tasks[i]
		local target_pos = managers.navigation._nav_segments[task_data.target_area].pos
		local undershot = task_data.force_required - task_data.force_assigned
		if 0 < undershot then
			local spawn_threshold = math.max(0, self._police_force_calm - self._police_force)
			if 0 < spawn_threshold then
				local used_event
				if task_data.use_spawn_event then
					task_data.use_spawn_event = false
					if task_data.force_assigned == 0 and self:_try_use_task_spawn_event(t, task_data.target_area, "recon") then
						task_data.force_assigned = task_data.force_required
						undershot = 0
						used_event = true
					end
				end
				if not used_event then
					local nr_wanted = math.min(spawn_threshold, undershot)
					local spawn_points = self:_find_spawn_points_near_area(task_data.target_area, nr_wanted)
					if spawn_points then
						self:_spawn_cops_to_recon(task_data.target_area, spawn_points, "avoid", "recon")
						task_data.force_assigned = task_data.force_assigned + #spawn_points
						undershot = undershot - #spawn_points
					end
				end
			end
			if 0 < undershot then
				local existing_cops = self:_find_surplus_cops_around_area(task_data.target_area, undershot, 0)
				if existing_cops then
					self:_assign_cops_to_recon(task_data.target_area, existing_cops, "avoid")
					undershot = undershot - #existing_cops
					task_data.force_assigned = task_data.force_assigned + #existing_cops
				end
			end
		end
		if task_data.force_assigned == 0 or task_data.force_assigned >= task_data.force_required then
			recon_tasks[i] = recon_tasks[#recon_tasks]
			table.remove(recon_tasks)
			self._task_data.recon.next_dispatch_t = t + math.ceil(self:_get_difficulty_dependent_value(tweak_data.group_ai.besiege.recon.interval)) + math.random() * tweak_data.group_ai.besiege.recon.interval_variation
		end
		i = i - 1
	end
end
function GroupAIStateBesiege:_assign_cops_to_recon(area, units, attitude)
	local nr_units = #units
	local unit_data = self._police
	local area_data = self._area_data[area]
	for _, unit in ipairs(units) do
		local u_key = unit:key()
		local u_data = unit_data[u_key]
		if u_data.assigned_area then
			self:_set_enemy_assigned(area_data, u_key)
			if not u_data.active then
				unit:brain():set_active(true)
				self:_mark_enemy_active_state(u_data, true)
			end
			local new_objective = {
				type = "investigate_area",
				nav_seg = area,
				attitude = attitude,
				stance = "hos",
				scan = true,
				interrupt_on = "obstructed"
			}
			unit:brain():set_objective(new_objective)
		end
	end
end
function GroupAIStateBesiege:_find_spawn_points_near_area(target_area, nr_wanted, target_pos, max_dis, verify_clbk)
	local all_areas = self._area_data
	local all_nav_segs = managers.navigation._nav_segments
	local mvec3_dis = mvector3.distance
	local t = self._t
	local distances = {}
	local s_points = {}
	target_pos = target_pos or all_nav_segs[target_area].pos
	local to_search_segs = {target_area}
	local found_segs = {}
	found_segs[target_area] = true
	repeat
		local search_seg = table.remove(to_search_segs, 1)
		local area_data = all_areas[search_seg]
		local spawn_points = area_data.spawn_points
		if spawn_points then
			for _, sp_data in ipairs(spawn_points) do
				if t >= sp_data.delay_t and (not verify_clbk or verify_clbk(sp_data)) then
					local my_dis = mvec3_dis(target_pos, sp_data.pos)
					if not max_dis or max_dis > my_dis then
						local i = #distances
						while true do
							if not (0 < i) or my_dis > distances[i] then
								break
							end
							i = i - 1
						end
						if i < #distances then
							if #distances == nr_wanted then
								distances[nr_wanted] = my_dis
								s_points[nr_wanted] = sp_data
							else
								table.remove(distances)
								table.remove(s_points)
								table.insert(distances, i + 1, my_dis)
								table.insert(s_points, i + 1, sp_data)
							end
						elseif nr_wanted > i then
							table.insert(distances, my_dis)
							table.insert(s_points, sp_data)
						end
					end
				end
			end
		end
		if #s_points == nr_wanted then
			break
		end
		for _seg_id, nav_seg_data in pairs(all_nav_segs) do
			if nav_seg_data.neighbours and not found_segs[_seg_id] and not nav_seg_data.disabled and nav_seg_data.neighbours[search_seg] then
				table.insert(to_search_segs, _seg_id)
				found_segs[_seg_id] = true
			end
		end
	until #to_search_segs == 0
	return 0 < #s_points and s_points
end
function GroupAIStateBesiege:_spawn_cops_to_recon(area, spawn_points, attitude, task)
	local produce_data = {
		{
			name = true,
			spawn_ai = {}
		}
	}
	local nr_sp = #spawn_points
	local i_sp = math.random(nr_sp)
	local i_unit = nr_sp
	local unit_weights = tweak_data.group_ai.besiege[task].units
	repeat
		local sp_data = spawn_points[i_sp]
		local spawn_point = sp_data.spawn_point
		local accessibility = sp_data.accessibility
		local unit_name = self:_get_spawn_unit_name(unit_weights, accessibility)
		if unit_name then
			produce_data[1].name = unit_name
			local spawned_enemy = spawn_point:produce(produce_data)[1]
			sp_data.delay_t = self._t + sp_data.interval
			if sp_data.amount then
				if sp_data.amount == 1 then
					self:_remove_preferred_spawn_point_from_area(sp_data.nav_seg, sp_data)
				else
					sp_data.amount = sp_data.amount - 1
				end
			end
			local u_key = spawned_enemy:key()
			self:_set_enemy_assigned(self._area_data[area], u_key)
			local objective = {
				type = "investigate_area",
				nav_seg = area,
				attitude = attitude,
				stance = "hos",
				interrupt_on = "obstructed",
				scan = true
			}
			if spawned_enemy:brain():is_available_for_assignment(objective) then
				spawned_enemy:brain():set_objective(objective)
			else
				spawned_enemy:brain():set_followup_objective(objective)
			end
		end
		i_unit = i_unit - 1
		if i_sp == 1 then
			i_sp = nr_sp
		else
			i_sp = i_sp - 1
		end
	until i_unit == 0
end
function GroupAIStateBesiege:_upd_reenforce_tasks()
	local reenforce_tasks = self._task_data.reenforce.tasks
	local t = self._t
	local i = #reenforce_tasks
	while 0 < i do
		local task_data = reenforce_tasks[i]
		local force_data = self._area_data[task_data.target_area].factors.force
		if force_data then
			task_data.force_required = force_data.force
			local undershot = task_data.force_required - task_data.force_assigned
			if 0 < undershot and not self._task_data.regroup.active and self._task_data.assault.phase ~= "fade" then
				local spawn_threshold = math.max(0, self._police_force_calm - self._police_force)
				if 0 < spawn_threshold then
					local used_event
					if task_data.use_spawn_event then
						task_data.use_spawn_event = false
						if task_data.force_assigned == 0 and self:_try_use_task_spawn_event(t, task_data.target_area, "regroup") then
							task_data.force_assigned = task_data.force_required
							undershot = 0
							used_event = true
						end
					end
					if not used_event then
						local nr_wanted = math.min(spawn_threshold, undershot)
						local spawn_points = self:_find_spawn_points_near_area(task_data.target_area, nr_wanted)
						if spawn_points then
							self:_spawn_cops_to_reenforce(task_data.target_area, spawn_points)
							task_data.force_assigned = task_data.force_assigned + #spawn_points
							undershot = undershot - #spawn_points
						end
					end
				end
				if 0 < undershot then
					local existing_cops = self:_find_surplus_cops_around_area(task_data.target_area, undershot, 0)
					if existing_cops then
						self:_assign_cops_to_reenforce(task_data.target_area, existing_cops)
						undershot = undershot - #existing_cops
						task_data.force_assigned = task_data.force_assigned + #existing_cops
					end
				end
			end
		else
			reenforce_tasks[i] = reenforce_tasks[#reenforce_tasks]
			table.remove(reenforce_tasks)
			self._task_data.reenforce.next_dispatch_t = t + self:_get_difficulty_dependent_value(tweak_data.group_ai.besiege.reenforce.interval)
		end
		i = i - 1
	end
end
function GroupAIStateBesiege:_spawn_cops_to_reenforce(area, spawn_points)
	local produce_data = {
		{
			name = true,
			spawn_ai = {}
		}
	}
	local nr_sp = #spawn_points
	local i_sp = math.random(nr_sp)
	local i_unit = nr_sp
	local unit_weights = tweak_data.group_ai.besiege.reenforce.units
	repeat
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
			local objective = {
				type = "defend_area",
				nav_seg = area,
				stance = "hos",
				attitude = "avoid",
				interrupt_on = "obstructed",
				scan = true
			}
			if spawned_enemy:brain():is_available_for_assignment(objective) then
				spawned_enemy:brain():set_objective(objective)
			else
				spawned_enemy:brain():set_followup_objective(objective)
			end
		end
		i_unit = i_unit - 1
		if i_sp == 1 then
			i_sp = nr_sp
		else
			i_sp = i_sp - 1
		end
	until i_unit == 0
end
function GroupAIStateBesiege:_assign_cops_to_reenforce(area, units)
	local nr_units = #units
	local unit_data = self._police
	local area_data = self._area_data[area]
	for _, unit in ipairs(units) do
		local u_key = unit:key()
		local u_data = unit_data[u_key]
		if u_data.assigned_area then
			self:_set_enemy_assigned(area_data, u_key)
			local new_objective = {
				type = "defend_area",
				nav_seg = area,
				status = "in_progress",
				stance = "hos",
				attitude = "avoid",
				interrupt_on = "obstructed",
				scan = true
			}
			unit:brain():set_objective(new_objective)
		end
	end
end
function GroupAIStateBesiege:is_area_safe(nav_seg)
	local all_areas = self._area_data
	local area = all_areas[nav_seg]
	return area and area.is_safe
end
function GroupAIStateBesiege:_find_surplus_cops_around_area(nav_seg, wanted_nr_units, spawn_threshold)
	local all_nav_segs = managers.navigation._nav_segments
	local area_data = self._area_data
	local area = area_data[nav_seg]
	local unit_data = self._police
	local lazy_bastards = {}
	local busy_bastards = {}
	local very_busy_bastards = {}
	local to_search_segs = {nav_seg}
	local found_segs = {}
	found_segs[nav_seg] = true
	local objective_desc = {
		type = "investigate_area"
	}
	repeat
		local search_seg = table.remove(to_search_segs, 1)
		area = area_data[search_seg]
		local police_units = area.police.units
		local min_force
		local force_factor = area.factors.force
		if force_factor then
			min_force = force_factor.force
		else
			min_force = 0
		end
		local lazy_alloc = 0
		local nr_police = table.size(police_units)
		for u_key, activity in pairs(police_units) do
			local unit = unit_data[u_key].unit
			if unit:brain():is_available_for_assignment(objective_desc) then
				local objective = unit:brain():objective()
				if not objective or objective.type == "free" then
					table.insert(lazy_bastards, unit)
				elseif objective.type == "defend_area" then
					if nr_police > lazy_alloc + min_force then
						table.insert(lazy_bastards, unit)
						lazy_alloc = lazy_alloc + 1
					end
				elseif objective.type == "guard" then
					if objective.guard_obj.from_seg == nav_seg then
						table.insert(busy_bastards, unit)
					else
						table.insert(very_busy_bastards, unit)
					end
				end
			end
			if #lazy_bastards == wanted_nr_units then
				return lazy_bastards
			end
		end
		for _seg_id, nav_seg_data in pairs(all_nav_segs) do
			if nav_seg_data.neighbours and not found_segs[_seg_id] and not nav_seg_data.disabled and nav_seg_data.neighbours[search_seg] then
				table.insert(to_search_segs, _seg_id)
				found_segs[_seg_id] = true
			end
		end
	until #to_search_segs == 0
	local undershot = wanted_nr_units - (#lazy_bastards + spawn_threshold)
	if 0 < undershot then
		local i = 1
		while busy_bastards[i] and undershot >= i do
			table.insert(lazy_bastards, busy_bastards[i])
			i = i + 1
		end
		undershot = wanted_nr_units - (#lazy_bastards + spawn_threshold)
		if 0 < undershot then
			i = 1
			while very_busy_bastards[i] and undershot >= i do
				table.insert(lazy_bastards, very_busy_bastards[i])
				i = i + 1
			end
		end
	end
	return #lazy_bastards ~= 0 and lazy_bastards
end
function GroupAIStateBesiege:set_enemy_assigned(nav_seg, unit_key)
	self:_set_enemy_assigned(self._area_data[nav_seg], unit_key)
end
function GroupAIStateBesiege:_set_enemy_assigned(area_data, unit_key)
	local u_data = self._police[unit_key]
	if u_data.assigned_area then
		u_data.assigned_area.police.units[unit_key] = nil
	end
	if area_data then
		area_data.police.units[unit_key] = u_data
		u_data.assigned_area = area_data
	else
		u_data.assigned_area = nil
	end
end
function GroupAIStateBesiege:register_criminal(unit)
	GroupAIStateBesiege.super.register_criminal(self, unit)
	if not Network:is_server() then
		return
	end
	local u_key = unit:key()
	local record = self._criminals[u_key]
	local area_data = self._area_data[record.seg]
	area_data.criminal.units[u_key] = {}
end
function GroupAIStateBesiege:unregister_criminal(unit)
	if Network:is_server() then
		local u_key = unit:key()
		local record = self._criminals[u_key]
		self._area_data[record.seg].criminal.units[u_key] = nil
	end
	GroupAIStateBesiege.super.unregister_criminal(self, unit)
end
function GroupAIStateBesiege:criminal_spotted(unit)
	local u_key = unit:key()
	local u_sighting = self._criminals[u_key]
	local prev_seg = u_sighting.seg
	GroupAIStateBesiege.super.criminal_spotted(self, unit)
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
function GroupAIStateBesiege:on_objective_complete(unit, objective)
	local new_objective, so_element
	if objective.followup_objective then
		if not objective.followup_objective.trigger_on then
			new_objective = objective.followup_objective
		else
			new_objective = {
				type = "free",
				followup_objective = objective.followup_objective,
				interrupt_on = objective.interrupt_on
			}
		end
	elseif objective.followup_SO then
		so_element = managers.mission:get_element_by_id(objective.followup_SO)
		new_objective = so_element:get_objective(unit)
	end
	if new_objective then
		if new_objective.nav_seg then
			local u_key = unit:key()
			local u_data = self._police[u_key]
			if u_data and u_data.assigned_area then
				self:_set_enemy_assigned(self._area_data[new_objective.nav_seg], u_key)
			end
		end
	else
		local seg = unit:movement():nav_tracker():nav_segment()
		local area_data = self._area_data[seg]
		if self:rescue_state() and tweak_data.character[unit:base()._tweak_table].rescue_hostages then
			for u_key, u_data in pairs(managers.enemy:all_civilians()) do
				if seg == u_data.tracker:nav_segment() then
					local so_id = u_data.unit:brain():wants_rescue()
					if so_id then
						local so = self._special_objectives[so_id]
						local so_data = so.data
						local so_objective = so_data.objective
						local fail_clbk = so_objective.fail_clbk
						local complete_clbk = so_objective.complete_clbk
						so_objective.fail_clbk = nil
						so_objective.complete_clbk = nil
						local objective_copy = deep_clone(so_objective)
						so_objective.fail_clbk = fail_clbk
						so_objective.complete_clbk = complete_clbk
						objective_copy.fail_clbk = fail_clbk
						objective_copy.complete_clbk = complete_clbk
						new_objective = objective_copy
						if so_data.admin_clbk then
							so_data.admin_clbk(unit)
						end
						self:remove_special_objective(so_id)
						break
					end
				end
			end
		end
		if not new_objective then
			if objective.type == "investigate_area" then
				if objective.guard_obj then
					new_objective = {
						type = "guard",
						nav_seg = seg,
						vis_group = objective.vis_group,
						guard_obj = objective.guard_obj,
						interrupt_on = "obstructed",
						in_place = true,
						scan = objective.scan
					}
				end
			elseif objective.type == "free" then
				new_objective = {
					type = "free",
					attitude = objective.attitude,
					stance = objective.stance,
					scan = objective.scan
				}
			end
		end
		if not area_data.is_safe then
			area_data.is_safe = true
			self:_on_area_safety_status(seg, {reason = "guard", unit = unit})
		end
	end
	objective.fail_clbk = nil
	unit:brain():set_objective(new_objective)
	if objective.complete_clbk then
		objective.complete_clbk(unit)
	end
	if so_element then
		so_element:clbk_objective_administered(unit)
	end
end
function GroupAIStateBesiege:on_defend_travel_end(unit, objective)
	local seg = objective.nav_seg
	local area_data = self._area_data[seg]
	if not area_data.is_safe then
		area_data.is_safe = true
		self:_on_area_safety_status(seg, {reason = "guard", unit = unit})
	end
end
function GroupAIStateBesiege:on_cop_jobless(unit)
	local u_key = unit:key()
	if not self._police[u_key].assigned_area then
		return
	end
	local nav_seg = unit:movement():nav_tracker():nav_segment()
	local new_occupation = self:find_occupation_in_area(nav_seg)
	local area = self._area_data[nav_seg]
	local force_factor = area.factors.force
	local demand = force_factor and force_factor.force
	local nr_police = table.size(area.police.units)
	local undershot = demand and demand - nr_police
	if undershot and 0 < undershot then
		local new_objective = {
			type = "defend_area",
			nav_seg = nav_seg,
			attitude = "avoid",
			stance = "hos",
			interrupt_on = "obstructed",
			in_place = true,
			scan = true
		}
		self:_set_enemy_assigned(self._area_data[nav_seg], u_key)
		unit:brain():set_objective(new_objective)
		return true
	end
	if not area.is_safe then
		local new_objective = {
			type = "free",
			nav_seg = nav_seg,
			attitude = "avoid",
			stance = "hos",
			in_place = true,
			scan = true
		}
		self:_set_enemy_assigned(self._area_data[nav_seg], u_key)
		unit:brain():set_objective(new_objective)
		return true
	end
end
function GroupAIStateBesiege:_empty_area_data()
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
function GroupAIStateBesiege:_map_spawn_points_to_respective_areas(id, spawn_points)
	local all_areas = self._area_data
	local nav_manager = managers.navigation
	local t = self._t
	for _, new_spawn_point in ipairs(spawn_points) do
		local pos = new_spawn_point:value("position")
		local interval = new_spawn_point:value("interval")
		local amount = new_spawn_point:value("amount")
		local nav_seg = nav_manager:get_nav_seg_from_pos(pos, true)
		local accessibility = new_spawn_point:value("accessibility")
		local new_spawn_point_data = {
			id = id,
			pos = pos,
			nav_seg = nav_seg,
			spawn_point = new_spawn_point,
			amount = 0 < amount and amount,
			interval = interval,
			delay_t = -1,
			accessibility = accessibility ~= "any" and accessibility
		}
		local area_data = all_areas[nav_seg]
		local area_spawn_points = area_data.spawn_points
		if area_spawn_points then
			table.insert(area_spawn_points, new_spawn_point_data)
		else
			area_spawn_points = {new_spawn_point_data}
			area_data.spawn_points = area_spawn_points
		end
	end
end
function GroupAIStateBesiege:add_preferred_spawn_points(id, spawn_points)
	self:_map_spawn_points_to_respective_areas(id, spawn_points)
	self._spawn_points[id] = spawn_points
end
function GroupAIStateBesiege:remove_preferred_spawn_points(id)
	for nav_seg, area_data in pairs(self._area_data) do
		local area_spawn_points = area_data.spawn_points
		if area_spawn_points then
			local i_sp = #area_spawn_points
			while 0 < i_sp do
				local sp_data = area_spawn_points[i_sp]
				if sp_data.id == id then
					area_spawn_points[i_sp] = area_spawn_points[#area_spawn_points]
					table.remove(area_spawn_points)
				end
				i_sp = i_sp - 1
			end
			if #area_spawn_points == 0 then
				area_data.spawn_points = nil
			end
		end
	end
	self._spawn_points[id] = nil
end
function GroupAIStateBesiege:_remove_preferred_spawn_point_from_area(area, sp_data)
	local area_data = self._area_data[area]
	for i, sp_data_ in ipairs(area_data) do
		if sp_data_ == sp_data then
			area_data[i] = area_data[#area_data]
			table.remove(area_data)
			break
		end
	end
end
function GroupAIStateBesiege:_create_area_data()
	local all_areas = {}
	local all_nav_segs = managers.navigation._nav_segments
	for seg_id, nav_seg in pairs(all_nav_segs) do
		local new_area_data = self:_empty_area_data()
		local seg_neighbours = nav_seg.neighbours
		local area_neighbours = new_area_data.neighbours
		for neighbour_id, door_list in pairs(seg_neighbours) do
			if not all_nav_segs[neighbour_id].disabled then
				table.insert(area_neighbours, {seg = neighbour_id, doors = door_list})
			end
		end
		all_areas[seg_id] = new_area_data
	end
	self._area_data = all_areas
	for id, spawn_points in pairs(self._spawn_points) do
		self:_map_spawn_points_to_respective_areas(id, spawn_points)
	end
end
function GroupAIStateBesiege:_draw_enemy_activity(t)
	local draw_data = self._AI_draw_data
	local brush_area = draw_data.brush_area
	local area_normal = -math.UP
	for nav_seg, area_data in pairs(self._area_data) do
		local area_pos = managers.navigation._nav_segments[nav_seg].pos
		local activity_types = {}
		local u_positions = {}
		local nr_units = 0
		for u_key, activity in pairs(area_data.police.units) do
			local entry = self._police[u_key]
			if entry then
				local unit = entry.unit
				local objective = unit:brain():objective()
				local activity_type = objective and objective.type or "idle"
				if activity_type == "follow" then
					Application:draw_line(objective.follow_unit:movement():m_head_pos(), unit:movement():m_head_pos(), 0.1, 0.5, 0.8)
				end
				local u_pos = unit:movement():m_com()
				table.insert(activity_types, activity_type)
				table.insert(u_positions, u_pos)
				nr_units = nr_units + 1
			end
		end
		if 0 < nr_units then
			brush_area:half_sphere(area_pos, 22, area_normal)
			for i, u_pos in ipairs(u_positions) do
				local brush
				local activity = activity_types[i]
				if activity == "guard" then
					brush = draw_data.brush_guard
				elseif activity == "investigate_area" then
					brush = draw_data.brush_investigate
				elseif activity == "defend_area" then
					brush = draw_data.brush_defend
				elseif activity == "free" then
					brush = draw_data.brush_free
				elseif activity == "act" then
					brush = draw_data.brush_act
				else
					brush = draw_data.brush_misc
				end
				brush:cylinder(u_pos, area_pos, 4, 3)
				brush:sphere(u_pos, 24)
			end
		end
	end
	local logic_name_texts = draw_data.logic_name_texts
	local panel = draw_data.panel
	local camera = managers.viewport:get_current_camera()
	if camera then
		local ws = draw_data.workspace
		local mid_pos1 = Vector3()
		local mid_pos2 = Vector3()
		local focus_enemy_pen = draw_data.pen_focus_enemy
		local focus_player_brush = draw_data.brush_focus_player
		local function _f_draw_logic_name(u_key, l_data)
			local logic_name_text = logic_name_texts[u_key]
			if not logic_name_text then
				logic_name_text = panel:text({
					name = "text",
					text = "blah",
					font = "fonts/font_univers_530_bold",
					font_size = 20,
					color = Color(1, 0, 1, 0),
					layer = 1
				})
				logic_name_texts[u_key] = logic_name_text
			end
			local my_head_pos = mid_pos1
			mvector3.set(my_head_pos, l_data.unit:movement():m_head_pos())
			mvector3.set_z(my_head_pos, my_head_pos.z + 30)
			logic_name_text:set_text(l_data.name)
			local my_head_pos_screen = camera:world_to_screen(my_head_pos)
			if 0 < my_head_pos_screen.z then
				local screen_x = (my_head_pos_screen.x + 1) * 0.5 * RenderSettings.resolution.x
				local screen_y = (my_head_pos_screen.y + 1) * 0.5 * RenderSettings.resolution.y
				logic_name_text:set_x(screen_x)
				logic_name_text:set_y(screen_y)
			end
		end
		for u_key, u_data in pairs(self._police) do
			local l_data = u_data.unit:brain()._logic_data
			_f_draw_logic_name(u_key, l_data)
			local my_head_pos = l_data.unit:movement():m_head_pos()
			local i_data = l_data.internal_data
			if i_data and i_data.focus_enemy then
				local e_pos = i_data.focus_enemy.m_head_pos
				local dis = mvector3.distance(my_head_pos, e_pos)
				mvector3.step(mid_pos2, my_head_pos, e_pos, 300)
				mvector3.lerp(mid_pos1, my_head_pos, mid_pos2, t % 0.5)
				mvector3.step(mid_pos2, mid_pos1, e_pos, 50)
				focus_enemy_pen:line(mid_pos1, mid_pos2)
				if i_data.focus_enemy.unit:base().is_local_player then
					focus_player_brush:sphere(my_head_pos, 20)
				end
			end
		end
	end
	for u_key, gui_text in pairs(logic_name_texts) do
		if not self._police[u_key] then
			panel:remove(gui_text)
			logic_name_texts[u_key] = nil
		end
	end
end
function GroupAIStateBesiege:on_nav_segment_state_change(changed_seg, state)
	local all_nav_segs = managers.navigation._nav_segments
	local changed_seg_data = all_nav_segs[changed_seg]
	local changed_seg_neighbours = changed_seg_data.neighbours
	local all_areas = self._area_data
	local changed_area = all_areas[changed_seg]
	local changed_area_neighbours = changed_area.neighbours
	for neighbour_id, door_list in pairs(changed_seg_neighbours) do
		local neighbour_area_data = all_areas[neighbour_id]
		local neighbour_area_neighbours = neighbour_area_data.neighbours
		if state then
			table.insert(neighbour_area_neighbours, {seg = changed_seg, doors = door_list})
		else
			local i = #neighbour_area_neighbours
			while 0 < i do
				if neighbour_area_neighbours[i].seg == changed_seg then
					neighbour_area_neighbours[i] = neighbour_area_neighbours[#neighbour_area_neighbours]
					table.remove(neighbour_area_neighbours)
					break
				end
				i = i - 1
			end
		end
	end
end
function GroupAIStateBesiege:find_occupation_in_area(nav_seg)
	local doors = managers.navigation:find_segment_doors(nav_seg, callback(self, self, "filter_area_unsafe"))
	if not next(doors) then
		return
	end
	for other_seg, door_list in ipairs(doors) do
		for i_door, door_data in ipairs(door_list) do
			door_data.weight = 0
		end
	end
	local tmp_vec1 = Vector3()
	local tmp_vec2 = Vector3()
	local math_max = math.max
	local mvec3_lerp = mvector3.lerp
	local mvec3_dis_sq = mvector3.distance_sq
	local nav_manager = managers.navigation
	local area_data = self._area_data[nav_seg]
	local area_police = area_data.police.units
	local unit_data = self._police
	local guarded_doors = {}
	for u_key, _ in pairs(area_police) do
		local objective = unit_data[u_key].unit:brain():objective()
		if objective and objective.guard_obj then
			local door_list = doors[objective.from_seg]
			if door_list then
				mvec3_lerp(tmp_vec1, objective.guard_obj.door.low_pos, objective.guard_obj.door.high_pos, 0.5)
				for i_door, door_data in ipairs(door_list) do
					mvec3_lerp(tmp_vec2, door_data.low_pos, door_dataoor.high_pos, 0.5)
					local weight = 1 / math_max(1, mvec3_dis_sq(tmp_vec1, tmp_vec2))
					door_data.weight = door_data.weight + weight
				end
			end
		end
	end
	local best_door, best_door_weight, best_door_nav_seg
	for other_seg, door_list in ipairs(doors) do
		for i_door, door_data in ipairs(door_list) do
			if not best_door or best_door_weight > door_data.weight then
				best_door = door_data.center
				best_door_weight = door_data.weight
				best_door_nav_seg = other_seg
			end
		end
	end
	for other_seg, door_list in ipairs(doors) do
		for i_door, door_data in ipairs(door_list) do
			door_data.weight = nil
		end
	end
	if best_door then
		local center = mvector3.copy(best_door.low_pos)
		mvec3_lerp(center, center, best_door.heigh_pos, 0.5)
		best_door.center = center
		return {
			type = "guard",
			door = best_door,
			from_seg = best_door_nav_seg
		}
	end
end
function GroupAIStateBesiege:verify_occupation_in_area(objective)
	local nav_seg = objective.nav_seg
	return self:find_occupation_in_area(nav_seg)
end
function GroupAIStateBesiege:filter_area_unsafe(nav_seg)
	return not self:is_area_safe(nav_seg)
end
function GroupAIStateBesiege:_on_area_safety_status(seg, event)
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
function GroupAIStateBesiege:add_flee_point(id, pos)
	self._flee_points[id] = pos
end
function GroupAIStateBesiege:remove_flee_point(id)
	self._flee_points[id] = nil
end
function GroupAIStateBesiege:flee_point(unit)
	local flee_point_id, flee_point = next(self._flee_points)
	return flee_point
end
function GroupAIStateBesiege:_draw_spawn_points()
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
function GroupAIStateBesiege:on_hostage_fleeing(unit)
	self._hostage_fleeing = unit
end
function GroupAIStateBesiege:on_hostage_flee_end()
	self._hostage_fleeing = nil
end
function GroupAIStateBesiege:can_hostage_flee()
	return not self._hostage_fleeing
end
function GroupAIStateBesiege:add_to_surrendered(unit, update)
	local hos_data = self._hostage_data
	local nr_entries = #hos_data
	local entry = {
		u_key = unit:key(),
		clbk = update
	}
	if not self._hostage_upd_key then
		self._hostage_upd_key = "GroupAIStateBesiege:_upd_hostage_task"
		managers.enemy:queue_task(self._hostage_upd_key, self._upd_hostage_task, self, self._t + 1)
	end
	table.insert(hos_data, entry)
end
function GroupAIStateBesiege:remove_from_surrendered(unit)
	local hos_data = self._hostage_data
	local u_key = unit:key()
	for i, entry in ipairs(hos_data) do
		if u_key == entry.u_key then
			table.remove(hos_data, i)
			break
		end
	end
	if #hos_data == 0 then
		managers.enemy:unqueue_task(self._hostage_upd_key)
		self._hostage_upd_key = nil
	end
end
function GroupAIStateBesiege:_upd_hostage_task()
	self._hostage_upd_key = nil
	local hos_data = self._hostage_data
	local first_entry = hos_data[1]
	table.remove(hos_data, 1)
	first_entry.clbk()
	if not self._hostage_upd_key and 0 < #hos_data then
		self._hostage_upd_key = "GroupAIStateBesiege:_upd_hostage_task"
		managers.enemy:queue_task(self._hostage_upd_key, self._upd_hostage_task, self, self._t + 1)
	end
end
function GroupAIStateBesiege:get_unit_assigned_area(u_key)
	local u_area_data = self._police[u_key].assigned_area
	if u_area_data then
		for nav_seg, area_data in pairs(self._area_data) do
			if area_data == u_area_data then
				return nav_seg
			end
		end
	end
end
function GroupAIStateBesiege:set_area_min_police_force(id, force, pos)
	if force then
		local nav_seg = managers.navigation:get_nav_seg_from_pos(pos, true)
		local factors = self._area_data[nav_seg].factors
		factors.force = {id = id, force = force}
	else
		for nav_seg, area_data in pairs(self._area_data) do
			local force_factor = area_data.factors.force
			if force_factor and force_factor.id == id then
				area_data.factors.force = nil
				return
			end
		end
	end
end
function GroupAIStateBesiege:set_wave_mode(flag)
	local old_wave_mode = self._wave_mode
	self._wave_mode = flag
	self._hunt_mode = nil
	if flag == "hunt" then
		self._hunt_mode = true
		self._wave_mode = "besiege"
		managers.hud:start_assault()
		self:_set_rescue_state(false)
		self:set_assault_mode(true)
		managers.trade:set_trade_countdown(false)
		self:_end_regroup_task()
		if self._task_data.assault.active then
			self._task_data.assault.phase = "sustain"
			self._task_data.use_smoke = true
			self._task_data.use_smoke_timer = 0
		else
			self._task_data.assault.next_dispatch_t = self._t
		end
	elseif flag == "besiege" then
		if self._task_data.regroup.active then
			self._task_data.assault.next_dispatch_t = self._task_data.regroup.end_t
		elseif not self._task_data.assault.active then
			self._task_data.assault.next_dispatch_t = self._t
		end
	elseif flag == "quiet" then
		self._hunt_mode = nil
	else
		self._wave_mode = old_wave_mode
		Application:error("[GroupAIStateStreet:set_wave_mode] flag", flag, " does not apply to the current Group AI state.")
	end
end
function GroupAIStateBesiege:set_dynamic_spawning_enabled(ratio)
	if ratio == 0 then
		ratio = false
	end
	if ratio and not self._dynamic_spawning then
		self._nr_dynamic_waves = 0
		self._nr_waves = 0
	end
	self._dynamic_spawning = ratio
end
function GroupAIStateBesiege:nr_groupai_cops()
	local nr_active = 0
	for u_key, u_data in pairs(self._police) do
		if u_data.assigned_area then
			nr_active = nr_active + 1
		end
	end
	return nr_active
end
function GroupAIStateBesiege:on_simulation_ended()
	GroupAIStateBesiege.super.on_simulation_ended(self)
	if managers.navigation:is_data_ready() then
		self._criminal_drama_demand = 4
		self._nr_active_units = 0
		self:_create_area_data()
		self._task_data = {}
		self._task_data.reenforce = {
			tasks = {},
			next_dispatch_t = 0
		}
		self._task_data.recon = {
			tasks = {},
			next_dispatch_t = 0
		}
		self._task_data.assault = {disabled = true, is_first = true}
		self._task_data.regroup = {}
	end
	if self._police_upd_task_queued then
		self._police_upd_task_queued = nil
		managers.enemy:unqueue_task("GroupAIStateBesiege._upd_police_activity")
	end
end
function GroupAIStateBesiege:on_simulation_started()
	GroupAIStateBesiege.super.on_simulation_started(self)
	if managers.navigation:is_data_ready() then
		self._police_force_max = 25
		self._police_force_calm = 18
		self._criminal_drama_demand = 4
		self._nr_active_units = 0
		self._task_data = {}
		self._task_data.reenforce = {
			tasks = {},
			next_dispatch_t = 0
		}
		self._task_data.recon = {
			tasks = {},
			next_dispatch_t = 0
		}
		self._task_data.assault = {disabled = true, is_first = true}
		self._task_data.regroup = {}
	end
	if not self._police_upd_task_queued then
		self:_queue_police_upd_task()
	end
end
function GroupAIStateBesiege:on_player_weapons_hot()
	if not self._player_weapons_hot then
		self._task_data.assault.disabled = nil
		self._task_data.assault.next_dispatch_t = self._t + 30
	end
	GroupAIStateBesiege.super.on_player_weapons_hot(self)
end
function GroupAIStateBesiege:is_detection_persistent()
	return self._task_data.assault.active
end
