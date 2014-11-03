local mvec3_set = mvector3.set
local mvec3_sub = mvector3.subtract
local mvec3_dir = mvector3.direction
local mvec3_dot = mvector3.dot
local mvec3_dis = mvector3.distance
local t_rem = table.remove
local t_ins = table.insert
local m_min = math.min
local tmp_vec1 = Vector3()
EnemyManager = EnemyManager or class()
EnemyManager._MAX_NR_CORPSES = 8
EnemyManager._nr_i_lod = {
	{2, 2},
	{5, 2},
	{10, 5}
}
function EnemyManager:init()
	self._slotmask_criminals = managers.slot:get_mask("criminals")
	self:_init_enemy_data()
	self._unit_clbk_key = "EnemyManager"
	self._corpse_disposal_upd_interval = 5
end
function EnemyManager:update(t, dt)
	self._t = t
	self._queued_task_executed = nil
	self:_update_gfx_lod()
	self:_update_queued_tasks(t)
end
function EnemyManager:_update_gfx_lod()
	if self._gfx_lod_data.enabled and managers.navigation:is_data_ready() then
		local camera_rot = managers.viewport:get_current_camera_rotation()
		if camera_rot then
			local pl_tracker, cam_pos
			local pl_fwd = camera_rot:y()
			local player = managers.player:player_unit()
			if player then
				pl_tracker = player:movement():nav_tracker()
				cam_pos = player:movement():m_head_pos()
			else
				pl_tracker = false
				cam_pos = managers.viewport:get_current_camera_position()
			end
			local entries = self._gfx_lod_data.entries
			local units = entries.units
			local states = entries.states
			local move_ext = entries.move_ext
			local trackers = entries.trackers
			local com = entries.com
			local chk_vis_func = pl_tracker and pl_tracker.check_visibility
			local unit_occluded = Unit.occluded
			local occ_skip_units = managers.occlusion._skip_occlusion
			local dt_lmt = math.cos(managers.user:get_setting("fov_standard") / 2) - 0.2
			for i, state in ipairs(states) do
				if not state and (occ_skip_units[units[i]:key()] or (not pl_tracker or chk_vis_func(pl_tracker, trackers[i])) and not unit_occluded(units[i])) then
					local distance = mvec3_dir(tmp_vec1, cam_pos, com[i])
					if mvec3_dot(tmp_vec1, pl_fwd) > dt_lmt + 0.05 or distance < 200 then
						states[i] = 1
						units[i]:base():set_visibility_state(1)
					end
				end
			end
			if #states > 0 then
				local anim_lod = managers.user:get_setting("video_animation_lod")
				local nr_lod_1 = self._nr_i_lod[anim_lod][1]
				local nr_lod_2 = self._nr_i_lod[anim_lod][2]
				local nr_lod_total = nr_lod_1 + nr_lod_2
				local imp_i_list = self._gfx_lod_data.prio_i
				local imp_wgt_list = self._gfx_lod_data.prio_weights
				local nr_entries = #states
				local i = self._gfx_lod_data.next_chk_prio_i
				if nr_entries < i then
					i = 1
				end
				local start_i = i
				repeat
					if states[i] then
						if not occ_skip_units[units[i]:key()] and (pl_tracker and not chk_vis_func(pl_tracker, trackers[i]) or unit_occluded(units[i])) then
							states[i] = false
							units[i]:base():set_visibility_state(false)
							self:_remove_i_from_lod_prio(i, anim_lod)
							self._gfx_lod_data.next_chk_prio_i = i + 1
							break
						else
							local my_wgt = mvec3_dir(tmp_vec1, cam_pos, com[i])
							local dot = mvec3_dot(tmp_vec1, pl_fwd)
							if dt_lmt > dot and my_wgt > 210 then
								states[i] = false
								units[i]:base():set_visibility_state(false)
								self:_remove_i_from_lod_prio(i, anim_lod)
								self._gfx_lod_data.next_chk_prio_i = i + 1
								break
							else
								local previous_prio
								for prio, i_entry in ipairs(imp_i_list) do
									if i == i_entry then
										previous_prio = prio
									else
									end
								end
								my_wgt = my_wgt * my_wgt * (1 - dot)
								local i_wgt = #imp_wgt_list
								while true do
									if not (i_wgt > 0) or previous_prio ~= i_wgt and my_wgt >= imp_wgt_list[i_wgt] then
										break
									end
									i_wgt = i_wgt - 1
								end
								if not previous_prio or previous_prio >= i_wgt then
									i_wgt = i_wgt + 1
								end
								if i_wgt ~= previous_prio then
									if previous_prio then
										t_rem(imp_i_list, previous_prio)
										t_rem(imp_wgt_list, previous_prio)
										if nr_lod_1 >= previous_prio and nr_lod_1 < i_wgt and nr_lod_1 <= #imp_i_list then
											local promote_i = imp_i_list[nr_lod_1]
											states[promote_i] = 1
											units[promote_i]:base():set_visibility_state(1)
										elseif nr_lod_1 < previous_prio and nr_lod_1 >= i_wgt then
											local denote_i = imp_i_list[nr_lod_1]
											states[denote_i] = 2
											units[denote_i]:base():set_visibility_state(2)
										end
									elseif nr_lod_total >= i_wgt and #imp_i_list == nr_lod_total then
										local kick_i = imp_i_list[nr_lod_total]
										states[kick_i] = 3
										units[kick_i]:base():set_visibility_state(3)
										t_rem(imp_wgt_list)
										t_rem(imp_i_list)
									end
									local lod_stage
									if nr_lod_total >= i_wgt then
										t_ins(imp_wgt_list, i_wgt, my_wgt)
										t_ins(imp_i_list, i_wgt, i)
										lod_stage = nr_lod_1 >= i_wgt and 1 or 2
									else
										lod_stage = 3
										self:_remove_i_from_lod_prio(i, anim_lod)
									end
									if states[i] ~= lod_stage then
										states[i] = lod_stage
										units[i]:base():set_visibility_state(lod_stage)
									end
								end
								self._gfx_lod_data.next_chk_prio_i = i + 1
								break
							end
						end
					end
					if i == nr_entries then
						i = 1
					else
						i = i + 1
					end
				until i == start_i
			end
		end
	end
end
function EnemyManager:_remove_i_from_lod_prio(i, anim_lod)
	anim_lod = anim_lod or managers.user:get_setting("video_animation_lod")
	local nr_i_lod1 = self._nr_i_lod[anim_lod][1]
	for prio, i_entry in ipairs(self._gfx_lod_data.prio_i) do
		if i == i_entry then
			table.remove(self._gfx_lod_data.prio_i, prio)
			table.remove(self._gfx_lod_data.prio_weights, prio)
			if prio <= nr_i_lod1 and nr_i_lod1 < #self._gfx_lod_data.prio_i then
				local promoted_i_entry = self._gfx_lod_data.prio_i[prio]
				self._gfx_lod_data.entries.states[promoted_i_entry] = 1
				self._gfx_lod_data.entries.units[promoted_i_entry]:base():set_visibility_state(1)
			end
			return
		end
	end
end
function EnemyManager:_create_unit_gfx_lod_data(unit, alerted)
	local lod_entries = self._gfx_lod_data.entries
	table.insert(lod_entries.units, unit)
	table.insert(lod_entries.states, 1)
	table.insert(lod_entries.move_ext, unit:movement())
	table.insert(lod_entries.trackers, unit:movement():nav_tracker())
	table.insert(lod_entries.com, unit:movement():m_com())
	table.insert(lod_entries.alerted, alerted)
end
function EnemyManager:_destroy_unit_gfx_lod_data(u_key)
	local lod_entries = self._gfx_lod_data.entries
	for i, unit in ipairs(lod_entries.units) do
		if u_key == unit:key() then
			if not lod_entries.states[i] then
				unit:base():set_visibility_state(1)
			end
			local nr_entries = #lod_entries.units
			self:_remove_i_from_lod_prio(i)
			for prio, i_entry in ipairs(self._gfx_lod_data.prio_i) do
				if i_entry == nr_entries then
					self._gfx_lod_data.prio_i[prio] = i
				else
				end
			end
			lod_entries.units[i] = lod_entries.units[nr_entries]
			table.remove(lod_entries.units)
			lod_entries.states[i] = lod_entries.states[nr_entries]
			table.remove(lod_entries.states)
			lod_entries.move_ext[i] = lod_entries.move_ext[nr_entries]
			table.remove(lod_entries.move_ext)
			lod_entries.trackers[i] = lod_entries.trackers[nr_entries]
			table.remove(lod_entries.trackers)
			lod_entries.com[i] = lod_entries.com[nr_entries]
			table.remove(lod_entries.com)
			lod_entries.alerted[i] = lod_entries.alerted[nr_entries]
			table.remove(lod_entries.alerted)
		else
		end
	end
end
function EnemyManager:set_gfx_lod_enabled(state)
	if state then
		self._gfx_lod_data.enabled = state
	elseif self._gfx_lod_data.enabled then
		self._gfx_lod_data.enabled = state
		local entries = self._gfx_lod_data.entries
		local units = entries.units
		local states = entries.states
		for i, state in ipairs(states) do
			states[i] = 1
			units[i]:base():set_visibility_state(1)
		end
	end
end
function EnemyManager:_init_enemy_data()
	local enemy_data = {}
	local unit_data = {}
	self._enemy_data = enemy_data
	enemy_data.unit_data = unit_data
	enemy_data.nr_units = 0
	enemy_data.nr_active_units = 0
	enemy_data.nr_inactive_units = 0
	enemy_data.inactive_units = {}
	enemy_data.max_nr_active_units = 20
	enemy_data.corpses = {}
	enemy_data.nr_corpses = 0
	self._civilian_data = {
		unit_data = {}
	}
	self._queued_tasks = {}
	self._queued_task_executed = nil
	self._delayed_clbks = {}
	self._t = 0
	self._gfx_lod_data = {}
	self._gfx_lod_data.enabled = true
	self._gfx_lod_data.prio_i = {}
	self._gfx_lod_data.prio_weights = {}
	self._gfx_lod_data.next_chk_prio_i = 1
	self._gfx_lod_data.entries = {}
	local lod_entries = self._gfx_lod_data.entries
	lod_entries.units = {}
	lod_entries.states = {}
	lod_entries.move_ext = {}
	lod_entries.trackers = {}
	lod_entries.com = {}
	lod_entries.alerted = {}
end
function EnemyManager:all_enemies()
	return self._enemy_data.unit_data
end
function EnemyManager:all_civilians()
	return self._civilian_data.unit_data
end
function EnemyManager:queue_task(id, task_clbk, data, execute_t, verification_clbk, asap)
	local task_data = {
		clbk = task_clbk,
		id = id,
		data = data,
		t = execute_t,
		v_cb = verification_clbk,
		asap = asap
	}
	table.insert(self._queued_tasks, task_data)
	if not execute_t and not (#self._queued_tasks > 1) and not self._queued_task_executed then
		self:_execute_queued_task(1)
	end
end
function EnemyManager:unqueue_task(id)
	local tasks = self._queued_tasks
	local i = #tasks
	while i > 0 do
		if tasks[i].id == id then
			table.remove(tasks, i)
			return
		end
		i = i - 1
	end
	debug_pause("[EnemyManager:unqueue_task] task", id, "was not queued!!!")
end
function EnemyManager:unqueue_task_debug(id)
	if not id then
		Application:stack_dump()
	end
	local tasks = self._queued_tasks
	local i = #tasks
	local removed
	while i > 0 do
		if tasks[i].id == id then
			if removed then
				debug_pause("DOUBLE TASK AT ", i, id)
			else
				table.remove(tasks, i)
				removed = true
			end
		end
		i = i - 1
	end
	if not removed then
		debug_pause("[EnemyManager:unqueue_task] task", id, "was not queued!!!")
	end
end
function EnemyManager:has_task(id)
	local tasks = self._queued_tasks
	local i = #tasks
	local count = 0
	while i > 0 do
		if tasks[i].id == id then
			count = count + 1
		end
		i = i - 1
	end
	return count > 0 and count
end
function EnemyManager:_execute_queued_task(i)
	local task = table.remove(self._queued_tasks, i)
	self._queued_task_executed = true
	if task.data and task.data.unit and not alive(task.data.unit) then
		print("[EnemyManager:_execute_queued_task] dead unit", inspect(task))
		Application:stack_dump()
	end
	if task.v_cb then
		task.v_cb(task.id)
	end
	task.clbk(task.data)
end
function EnemyManager:_update_queued_tasks(t)
	local i_asap_task, asp_task_t
	for i_task, task_data in ipairs(self._queued_tasks) do
		if not task_data.t or t > task_data.t then
			self:_execute_queued_task(i_task)
			break
		elseif task_data.asap and (not asp_task_t or asp_task_t > task_data.t) then
			i_asap_task = i_task
			asp_task_t = task_data.t
		end
	end
	if i_asap_task and not self._queued_task_executed then
		self:_execute_queued_task(i_asap_task)
	end
	local all_clbks = self._delayed_clbks
	if all_clbks[1] and t > all_clbks[1][2] then
		local clbk = table.remove(all_clbks, 1)[3]
		clbk()
	end
end
function EnemyManager:add_delayed_clbk(id, clbk, execute_t)
	if not clbk then
		debug_pause("[EnemyManager:add_delayed_clbk] Empty callback object!!!")
	end
	local clbk_data = {
		id,
		execute_t,
		clbk
	}
	local all_clbks = self._delayed_clbks
	local i = #all_clbks
	while i > 0 and execute_t < all_clbks[i][2] do
		i = i - 1
	end
	table.insert(all_clbks, i + 1, clbk_data)
end
function EnemyManager:remove_delayed_clbk(id)
	local all_clbks = self._delayed_clbks
	for i, clbk_data in ipairs(all_clbks) do
		if clbk_data[1] == id then
			table.remove(all_clbks, i)
			return
		end
	end
	debug_pause("[EnemyManager:remove_delayed_clbk] id", id, "was not scheduled!!!")
end
function EnemyManager:reschedule_delayed_clbk(id, execute_t)
	local all_clbks = self._delayed_clbks
	local clbk_data
	for i, clbk_d in ipairs(all_clbks) do
		if clbk_d[1] == id then
			clbk_data = table.remove(all_clbks, i)
		else
		end
	end
	if clbk_data then
		clbk_data[2] = execute_t
		local i = #all_clbks
		while i > 0 and execute_t < all_clbks[i][2] do
			i = i - 1
		end
		table.insert(all_clbks, i + 1, clbk_data)
		return
	end
	debug_pause("[EnemyManager:reschedule_delayed_clbk] id", id, "was not scheduled!!!")
end
function EnemyManager:queued_tasks_by_callback()
	local t = TimerManager:game():time()
	local categorised_queued_tasks = {}
	local congestion = 0
	for i_task, task_data in ipairs(self._queued_tasks) do
		if categorised_queued_tasks[task_data.clbk] then
			categorised_queued_tasks[task_data.clbk].amount = categorised_queued_tasks[task_data.clbk].amount + 1
		else
			categorised_queued_tasks[task_data.clbk] = {
				amount = 1,
				key = task_data.id
			}
		end
		if not task_data.t or t > task_data.t then
			congestion = congestion + 1
		end
	end
	print("congestion", congestion)
	for clbk, data in pairs(categorised_queued_tasks) do
		print(data.key, data.amount)
	end
end
function EnemyManager:register_enemy(enemy)
	local char_tweak = tweak_data.character[enemy:base()._tweak_table]
	local u_data = {
		unit = enemy,
		m_pos = enemy:movement():m_pos(),
		tracker = enemy:movement():nav_tracker(),
		importance = 0,
		char_tweak = char_tweak,
		so_access = managers.navigation:convert_access_flag(char_tweak.access)
	}
	self._enemy_data.unit_data[enemy:key()] = u_data
	enemy:base():add_destroy_listener(self._unit_clbk_key, callback(self, self, "on_enemy_destroyed"))
	self:on_enemy_registered(enemy)
end
function EnemyManager:on_enemy_died(dead_unit, damage_info)
	local u_key = dead_unit:key()
	local enemy_data = self._enemy_data
	local u_data = enemy_data.unit_data[u_key]
	self:on_enemy_unregistered(dead_unit)
	enemy_data.unit_data[u_key] = nil
	if enemy_data.nr_corpses == 0 then
		self:queue_task("EnemyManager._upd_corpse_disposal", EnemyManager._upd_corpse_disposal, self, self._t + self._corpse_disposal_upd_interval)
	end
	enemy_data.nr_corpses = enemy_data.nr_corpses + 1
	enemy_data.corpses[u_key] = u_data
	u_data.death_t = self._t
	self:_destroy_unit_gfx_lod_data(u_key)
	Network:detach_unit(dead_unit)
end
function EnemyManager:on_enemy_destroyed(enemy)
	local u_key = enemy:key()
	local enemy_data = self._enemy_data
	if enemy_data.unit_data[u_key] then
		self:on_enemy_unregistered(enemy)
		enemy_data.unit_data[u_key] = nil
		self:_destroy_unit_gfx_lod_data(u_key)
	elseif enemy_data.corpses[u_key] then
		enemy_data.nr_corpses = enemy_data.nr_corpses - 1
		enemy_data.corpses[u_key] = nil
		if enemy_data.nr_corpses == 0 then
			self:unqueue_task("EnemyManager._upd_corpse_disposal")
		end
	end
end
function EnemyManager:on_enemy_registered(unit)
	self._enemy_data.nr_units = self._enemy_data.nr_units + 1
	self:_create_unit_gfx_lod_data(unit, true)
	managers.groupai:state():on_enemy_registered(unit)
end
function EnemyManager:on_enemy_unregistered(unit)
	self._enemy_data.nr_units = self._enemy_data.nr_units - 1
	managers.groupai:state():on_enemy_unregistered(unit)
end
function EnemyManager:register_civilian(unit)
	unit:base():add_destroy_listener(self._unit_clbk_key, callback(self, self, "on_civilian_destroyed"))
	self:_create_unit_gfx_lod_data(unit, true)
	local char_tweak = tweak_data.character[unit:base()._tweak_table]
	self._civilian_data.unit_data[unit:key()] = {
		unit = unit,
		m_pos = unit:movement():m_pos(),
		tracker = unit:movement():nav_tracker(),
		char_tweak = char_tweak,
		so_access = managers.navigation:convert_access_flag(char_tweak.access)
	}
end
function EnemyManager:on_civilian_died(dead_unit, damage_info)
	local u_key = dead_unit:key()
	if Network:is_server() and damage_info.attacker_unit and not dead_unit:base().enemy then
		managers.groupai:state():hostage_killed(damage_info.attacker_unit)
	end
	local u_data = self._civilian_data.unit_data[u_key]
	local enemy_data = self._enemy_data
	if enemy_data.nr_corpses == 0 then
		self:queue_task("EnemyManager._upd_corpse_disposal", EnemyManager._upd_corpse_disposal, self, self._t + self._corpse_disposal_upd_interval)
	end
	enemy_data.nr_corpses = enemy_data.nr_corpses + 1
	enemy_data.corpses[u_key] = u_data
	u_data.death_t = TimerManager:game():time()
	self._civilian_data.unit_data[u_key] = nil
	self:_destroy_unit_gfx_lod_data(u_key)
	Network:detach_unit(dead_unit)
end
function EnemyManager:on_civilian_destroyed(enemy)
	local u_key = enemy:key()
	local enemy_data = self._enemy_data
	if enemy_data.corpses[u_key] then
		enemy_data.nr_corpses = enemy_data.nr_corpses - 1
		enemy_data.corpses[u_key] = nil
		if enemy_data.nr_corpses == 0 then
			self:unqueue_task("EnemyManager._upd_corpse_disposal")
		end
	else
		self._civilian_data.unit_data[u_key] = nil
		self:_destroy_unit_gfx_lod_data(u_key)
	end
end
function EnemyManager:on_criminal_registered(unit)
	self:_create_unit_gfx_lod_data(unit, false)
end
function EnemyManager:on_criminal_unregistered(u_key)
	self:_destroy_unit_gfx_lod_data(u_key)
end
function EnemyManager:_upd_corpse_disposal()
	local t = TimerManager:game():time()
	local enemy_data = self._enemy_data
	local nr_corpses = enemy_data.nr_corpses
	local disposals_needed = nr_corpses - self._MAX_NR_CORPSES
	local corpses = enemy_data.corpses
	local nav_mngr = managers.navigation
	local player = managers.player:player_unit()
	local pl_tracker, cam_pos, cam_fwd
	if player then
		pl_tracker = player:movement():nav_tracker()
		cam_pos = player:movement():m_head_pos()
		cam_fwd = player:camera():forward()
	elseif managers.viewport:get_current_camera() then
		cam_pos = managers.viewport:get_current_camera_position()
		cam_fwd = managers.viewport:get_current_camera_rotation():y()
	end
	local to_dispose = {}
	local nr_found = 0
	if pl_tracker then
		for u_key, u_data in pairs(corpses) do
			local u_tracker = u_data.tracker
			if not pl_tracker:check_visibility(u_tracker) then
				to_dispose[u_key] = true
				nr_found = nr_found + 1
			end
		end
	end
	if disposals_needed > #to_dispose then
		if cam_pos then
			for u_key, u_data in pairs(corpses) do
				local u_pos = u_data.m_pos
				if not to_dispose[u_key] and mvec3_dis(cam_pos, u_pos) > 300 and 0 > mvector3.dot(cam_fwd, u_pos - cam_pos) then
					to_dispose[u_key] = true
					nr_found = nr_found + 1
					if nr_found == disposals_needed then
					end
				else
				end
			end
		end
		if disposals_needed > nr_found then
			local oldest_u_key, oldest_t
			for u_key, u_data in pairs(corpses) do
				if (not oldest_t or oldest_t > u_data.death_t) and not to_dispose[u_key] then
					oldest_u_key = u_key
					oldest_t = u_data.death_t
				end
			end
			if oldest_u_key then
				to_dispose[oldest_u_key] = true
				nr_found = nr_found + 1
			end
		end
	end
	for u_key, _ in pairs(to_dispose) do
		local u_data = corpses[u_key]
		u_data.unit:base():set_slot(u_data.unit, 0)
		corpses[u_key] = nil
	end
	enemy_data.nr_corpses = nr_corpses - nr_found
	if nr_corpses > 0 then
		local delay = enemy_data.nr_corpses > self._MAX_NR_CORPSES and 0 or self._corpse_disposal_upd_interval
		self:queue_task("EnemyManager._upd_corpse_disposal", EnemyManager._upd_corpse_disposal, self, t + delay)
	end
end
function EnemyManager:on_simulation_ended()
end
function EnemyManager:dispose_all_corpses()
	for u_key, corpse_data in pairs(self._enemy_data.corpses) do
		corpse_data.unit:base():set_slot(corpse_data.unit, 0)
	end
end
