ActionSpooc = ActionSpooc or class()
ActionSpooc._walk_anim_velocities = CopActionWalk._walk_anim_velocities
ActionSpooc._walk_anim_lengths = CopActionWalk._walk_anim_lengths
ActionSpooc._matching_walk_anims = CopActionWalk._matching_walk_anims
ActionSpooc._walk_side_rot = CopActionWalk._walk_side_rot
ActionSpooc._anim_movement = CopActionWalk._anim_movement
function ActionSpooc:init(action_desc, common_data)
	self._tmp_vec1 = Vector3()
	self._common_data = common_data
	self._ext_movement = common_data.ext_movement
	self._ext_anim = common_data.ext_anim
	self._ext_base = common_data.ext_base
	self._ext_network = common_data.ext_network
	self._machine = common_data.machine
	self._unit = common_data.unit
	if not self._ext_anim.pose then
		print("[ActionSpooc:init] no pose in anim", self._machine:segment_state(Idstring("base")), common_data.unit)
		common_data.ext_movement:play_redirect("idle")
		if not self._ext_anim.pose then
			debug_pause()
			return
		end
	end
	self._nav_path = action_desc.nav_path or {
		mvector3.copy(common_data.pos)
	}
	self._ext_movement:enable_update()
	self._host_stop_pos_inserted = action_desc.host_stop_pos_inserted
	self._stop_pos = action_desc.stop_pos
	self._nav_index = action_desc.path_index or 1
	self._stroke = action_desc.stroke
	self._strike_nav_index = action_desc.strike_nav_index
	self._haste = "run"
	self._nr_expected_nav_points = action_desc.nr_expected_nav_points
	self._was_interrupted = action_desc.interrupted
	local is_server = Network:is_server()
	local is_local
	if self._was_interrupted then
		is_local = action_desc.is_local
	else
		local attention = self._ext_movement:attention()
		self._target_unit = attention and attention.unit
		is_local = self._target_unit and (self._target_unit:base().is_local_player or is_server and not self._target_unit:base().is_husk_player)
	end
	if not is_server then
		local host_stop_pos = self._ext_movement:m_host_stop_pos()
		if host_stop_pos ~= common_data.pos then
			table.insert(self._nav_path, 2, mvector3.copy(host_stop_pos))
			self._host_stop_pos_inserted = (self._host_stop_pos_inserted or 0) + 1
		end
	end
	self._is_local = is_local
	if is_server then
		self._ext_network:send("action_spooc_start")
	end
	self._walk_velocity = self:_get_max_walk_speed()
	self._last_vel_z = 0
	self._cur_vel = 0
	self._last_pos = mvector3.copy(common_data.pos)
	CopActionAct._create_blocks_table(self, action_desc.blocks)
	if self._was_interrupted then
		if self._nav_path[self._nav_index + 1] then
			self:_start_sprint()
		else
			self:_wait()
		end
	elseif is_local then
		if not is_server and self:_chk_target_invalid() then
			self:_wait()
		else
			self._chase_tracker = self._target_unit:movement():nav_tracker()
			local chase_pos = self._chase_tracker:field_position()
			table.insert(self._nav_path, chase_pos)
			self._last_sent_pos = mvector3.copy(common_data.pos)
			self:_set_updator("_upd_chk_walkway")
		end
	else
		self:_wait()
	end
	return true
end
function ActionSpooc:_upd_chk_walkway(t)
	if self:_chk_target_invalid() then
		if Network:is_server() then
			self:_expire()
		else
			self:_wait()
		end
		return
	end
	if self:_chk_can_strike() then
		self:_strike()
		return
	end
	if self._common_data.nav_tracker:lost() then
		self:_expire()
	end
	local ray_params = {
		tracker_from = self._common_data.nav_tracker,
		tracker_to = self._chase_tracker
	}
	if self._chase_tracker:lost() then
		ray_params.pos_to = self._chase_tracker:field_position()
	end
	local walk_ray = managers.navigation:raycast(ray_params)
	if not walk_ray then
		self:_start_sprint()
		self:update(t)
		return
	end
end
function ActionSpooc:on_exit()
	if self._root_blend_disabled then
		self._ext_movement:set_root_blend(true)
	end
	if self._changed_driving then
		self._common_data.unit:set_driving("script")
		self._changed_driving = nil
	end
	if self._expired and self._common_data.ext_anim.move then
		self:_stop_walk()
	end
	self._ext_movement:drop_held_items()
	if Network:is_server() then
		local stop_nav_index = math.min(256, self._nav_index - (self._host_stop_pos_inserted or 0))
		self._ext_network:send("action_spooc_stop", mvector3.copy(self._ext_movement:m_pos()), stop_nav_index)
	else
		self._ext_movement:set_m_host_stop_pos(self._ext_movement:m_pos())
	end
end
function ActionSpooc:_chk_can_strike()
	if self._stroke then
		return
	end
	local my_pos = self._common_data.pos
	local target_pos = self._tmp_vec1
	self._chase_tracker:m_position(target_pos)
	local function _dis_chk(pos)
		mvector3.subtract(pos, my_pos)
		local dif_z = math.abs(mvector3.z(pos))
		mvector3.set_z(pos, 0)
		return mvector3.length_sq(pos) < 10000 and dif_z < 75
	end
	if not _dis_chk(target_pos) then
		return
	end
	mvector3.set(target_pos, self._nav_path[#self._nav_path])
	if _dis_chk(target_pos) then
		return true
	end
end
function ActionSpooc:_chk_target_invalid()
	if not self._target_unit then
		return true
	end
	local record = managers.groupai:state():criminal_record(self._target_unit:key())
	if not record or record.status then
		return true
	end
end
function ActionSpooc:_start_sprint()
	CopActionWalk._chk_start_anim(self, self._nav_path[self._nav_index + 1])
	if self._start_run then
		self:_set_updator("_upd_start_anim_first_frame")
	else
		self:_set_updator("_upd_sprint")
		self._common_data.unit:base():chk_freeze_anims()
	end
end
function ActionSpooc:_strike()
	self._strike_now = nil
	self:_set_updator("_upd_strike_first_frame")
end
function ActionSpooc:_wait()
	self._end_of_path = true
	self:_set_updator("_upd_wait")
	if self._ext_anim.move then
		self:_stop_walk()
	end
end
function ActionSpooc:_upd_strike_first_frame(t)
	if self._is_local and self:_chk_target_invalid() then
		if Network:is_server() then
			self:_expire()
		else
			self:_wait()
		end
		return
	end
	local redir_result = self._ext_movement:play_redirect("spooc_strike")
	if redir_result then
		self._ext_movement:spawn_wanted_items()
	end
	self._stroke = true
	if self._is_local then
		mvector3.set(self._last_sent_pos, self._common_data.pos)
		self._ext_network:send("action_spooc_strike", mvector3.copy(self._common_data.pos))
		self._nav_path[self._nav_index + 1] = mvector3.copy(self._common_data.pos)
		self._strike_unit = self._target_unit
		self._target_unit:movement():on_SPOOCed()
		self._unit:sound():say("_punch_3rd_person_3p", true)
	end
	self:_set_updator("_upd_striking")
	self._common_data.unit:base():chk_freeze_anims()
end
function ActionSpooc:_upd_chase_path()
	local ray_params = {
		tracker_from = self._common_data.nav_tracker,
		tracker_to = self._chase_tracker,
		trace = true,
		allow_entry = true
	}
	local chase_pos
	local chasing_lost = self._chase_tracker:lost()
	if chasing_lost then
		chase_pos = self._chase_tracker:field_position()
		ray_params.pos_to = chase_pos
	else
		chase_pos = self._chase_tracker:position()
	end
	local simplified
	if self._nav_index < #self._nav_path - 1 then
		local walk_ray = managers.navigation:raycast(ray_params)
		if not walk_ray then
			simplified = true
			for i = self._nav_index + 2, #self._nav_path do
				table.remove(self._nav_path)
			end
		end
	end
	local walk_ray
	if not simplified then
		ray_params.tracker_from = nil
		ray_params.pos_from = self._nav_path[#self._nav_path - 1]
		walk_ray = managers.navigation:raycast(ray_params)
	end
	if walk_ray then
		table.insert(self._nav_path, mvector3.copy(chase_pos))
	else
		mvector3.set(self._nav_path[#self._nav_path], ray_params.trace[1])
	end
end
function ActionSpooc:_upd_sprint(t)
	if self._is_local and not self._was_interrupted then
		if self:_chk_target_invalid() then
			if Network:is_server() then
				self:_expire()
			else
				self:_wait()
			end
			return
		end
		self:_upd_chase_path()
		if self:_chk_can_strike() then
			self:_strike()
			return
		end
	end
	local dt = TimerManager:game():delta_time()
	local pos_new
	if self._end_of_path then
		if self._stop_pos or Network:is_server() and self._stroke then
			self:_expire()
		else
			self:_wait()
		end
	else
		self:_nav_chk(t, dt)
	end
	local move_dir = self._last_pos - self._common_data.pos
	mvector3.set_z(move_dir, 0)
	if self._cur_vel < 0.1 then
		move_dir = nil
	end
	self._move_dir = move_dir
	local anim_data = self._ext_anim
	local face_fwd, face_right
	if self._move_dir then
		local attention = self._attention
		if attention then
			if attention.unit then
				face_fwd = attention.unit:movement():m_pos() - self._common_data.pos
			else
				face_fwd = attention.pos - self._common_data.pos
			end
		else
			face_fwd = self._move_dir
		end
		local move_dir_norm = self._move_dir:normalized()
		mvector3.set_z(face_fwd, 0)
		mvector3.normalize(face_fwd)
		face_right = face_fwd:cross(math.UP)
		mvector3.normalize(face_right)
		local right_dot = mvector3.dot(move_dir_norm, face_right)
		local fwd_dot = mvector3.dot(move_dir_norm, face_fwd)
		local wanted_walk_dir
		if math.abs(fwd_dot) > math.abs(right_dot) then
			if (anim_data.move_l and right_dot < 0 or anim_data.move_r and right_dot > 0) and math.abs(fwd_dot) < 0.73 then
				wanted_walk_dir = anim_data.move_side
			else
				wanted_walk_dir = fwd_dot > 0 and "fwd" or "bwd"
			end
		elseif (anim_data.move_fwd and fwd_dot > 0 or anim_data.move_bwd and fwd_dot < 0) and math.abs(right_dot) < 0.73 then
			wanted_walk_dir = anim_data.move_side
		else
			wanted_walk_dir = right_dot > 0 and "r" or "l"
		end
		local wanted_u_fwd = self._move_dir:rotate_with(self._walk_side_rot[wanted_walk_dir])
		local rot_new = self._common_data.rot:slerp(Rotation(wanted_u_fwd, math.UP), math.min(1, dt * 5))
		self._ext_movement:set_rotation(rot_new)
		local real_velocity = self._cur_vel
		local variant = "run"
		if variant == "run" and not self._no_walk then
			local run_limit = 300
			if anim_data.run then
				if real_velocity < 280 and anim_data.move then
					variant = "walk"
				else
					variant = "run"
				end
			elseif real_velocity >= 300 then
				variant = "run"
			else
				variant = "walk"
			end
		end
		self:_adjust_move_anim(wanted_walk_dir, variant)
		local pose = self._ext_anim.pose
		local anim_walk_speed = self._walk_anim_velocities[pose][variant][wanted_walk_dir]
		local wanted_walk_anim_speed = real_velocity / anim_walk_speed
		self:_adjust_walk_anim_speed(dt, wanted_walk_anim_speed)
	end
	self:_set_new_pos(dt)
	if self._strike_now then
		self:_strike()
	end
end
function ActionSpooc:_upd_start_anim_first_frame(t)
	local pose = self._ext_anim.pose
	local speed_mul = self._walk_velocity / self._walk_anim_velocities[pose].run.fwd
	self:_start_move_anim(self._start_run_turn and self._start_run_turn[3] or self._start_run_straight, "run", speed_mul, self._start_run_turn)
	self:_set_updator("_upd_start_anim")
	self._common_data.unit:base():chk_freeze_anims()
end
function ActionSpooc:_upd_start_anim(t)
	if self._is_local and not self._was_interrupted then
		if self:_chk_target_invalid() then
			if Network:is_server() then
				self:_expire()
			else
				self:_wait()
			end
			return
		end
		self:_upd_chase_path()
		if self:_chk_can_strike() then
			self:_strike()
			return
		end
	end
	if not self._ext_anim.run_start then
		self._start_run = nil
		self._start_run_turn = nil
		self._start_run_straight = nil
		self._last_pos = mvector3.copy(self._common_data.pos)
		self:_set_updator("_upd_sprint")
		self:update(t)
		return
	end
	local dt = TimerManager:game():delta_time()
	if self._start_run_turn then
		local seg_rel_t = self._machine:segment_relative_time(Idstring("base"))
		if seg_rel_t > 0.1 then
			local delta_pos = self._common_data.unit:get_animation_delta_position()
			mvector3.multiply(delta_pos, 2)
			if seg_rel_t > 0.6 then
				if self._correct_vel_from then
					local lerp = (math.clamp(seg_rel_t, 0, 0.9) - 0.6) / 0.3
					self._cur_vel = math.lerp(self._correct_vel_from, self._walk_velocity, lerp)
				else
					self._correct_vel_from = self._cur_vel
				end
				mvector3.set_length(delta_pos, self._cur_vel * dt)
			else
				self._cur_vel = delta_pos:length() / dt
			end
			local new_pos = self._common_data.pos + delta_pos
			local ray_params = {
				tracker_from = self._common_data.nav_tracker,
				allow_entry = true,
				pos_to = new_pos,
				trace = true
			}
			local collision_pos = managers.navigation:raycast(ray_params)
			if collision_pos then
				new_pos = ray_params.trace[1]
			end
			self._last_pos = new_pos
			local seg_rel_t_clamp = math.clamp((seg_rel_t - 0.1) / 0.77, 0, 1)
			local prg_angle = self._start_run_turn[2] * seg_rel_t_clamp
			local new_yaw = self._start_run_turn[1] + prg_angle
			local rot_new = Rotation(new_yaw, 0, 0)
			self._ext_movement:set_rotation(rot_new)
		end
	else
		if self._end_of_path then
			self._start_run = nil
			if self._stop_pos or Network:is_server() and self._stroke then
				self:_expire()
			else
				self:_wait()
			end
			return
		else
			self:_nav_chk(t, dt)
		end
		if not self._end_of_path then
			local move_dir = self._nav_path[self._nav_index + 1] - self._common_data.pos
			local wanted_u_fwd = move_dir:rotate_with(self._walk_side_rot[self._start_run_straight])
			local rot_new = self._common_data.rot:slerp(Rotation(wanted_u_fwd, math.UP), math.min(1, dt * 5))
			mrotation.set_yaw_pitch_roll(rot_new, rot_new:yaw(), 0, 0)
			self._ext_movement:set_rotation(rot_new)
		end
	end
	self:_set_new_pos(dt)
	if self._strike_now then
		self:_strike()
		self._start_run = nil
		self._start_run_turn = nil
		self._start_run_straight = nil
		return
	end
end
function ActionSpooc:_set_new_pos(dt)
	CopActionWalk._set_new_pos(self, dt)
end
function ActionSpooc._apply_freefall(...)
	return CopActionWalk._apply_freefall(...)
end
function ActionSpooc:type()
	return "spooc"
end
function ActionSpooc:get_husk_interrupt_desc()
	local old_action_desc = {
		type = "spooc",
		body_part = 1,
		block_type = "walk",
		interrupted = true,
		stop_pos = self._stop_pos,
		path_index = self._nav_index,
		nav_path = self._nav_path,
		strike_nav_index = self._strike_nav_index,
		stroke = (self._stroke or self._is_local) and true,
		host_stop_pos_inserted = self._host_stop_pos_inserted,
		nr_expected_nav_points = self._nr_expected_nav_points,
		is_local = self._is_local
	}
	if self._blocks then
		local blocks = {}
		for i, k in pairs(self._blocks) do
			blocks[i] = -1
		end
		old_action_desc.blocks = blocks
	end
	return old_action_desc
end
function ActionSpooc:expired()
	return self._expired
end
function ActionSpooc:_expire()
	self._expired = true
end
function ActionSpooc:_get_max_walk_speed()
	return self._common_data.char_tweak.SPEED_SPRINT
end
function ActionSpooc:save(save_data)
	save_data.type = "spooc"
	save_data.body_part = 1
	save_data.block_type = "walk"
	save_data.interrupted = true
	save_data.stop_pos = self._stop_pos
	save_data.path_index = self._nav_index
	save_data.strike_nav_index = self._strike_nav_index
	save_data.blocks = {
		walk = -1,
		act = -1,
		turn = -1,
		idle = -1
	}
	local t_ins = table.insert
	local sync_path = {}
	local nav_path = self._nav_path
	for i = 1, self._nav_index + 1 do
		local nav_point = nav_path[i]
		t_ins(sync_path, nav_point)
	end
	save_data.nav_path = sync_path
end
function ActionSpooc:_nav_chk(t, dt)
	local path = self._nav_path
	local old_nav_index = self._nav_index
	local vel = self._walk_velocity
	local walk_dis = vel * dt
	local cur_pos = self._common_data.pos
	local new_pos, complete, new_nav_index
	mvector3.set(path[old_nav_index], cur_pos)
	new_pos, new_nav_index, complete = CopActionWalk._walk_spline(path, cur_pos, old_nav_index, walk_dis)
	if not self._stroke and self._strike_nav_index and (new_nav_index >= self._strike_nav_index or complete and self._strike_nav_index == new_nav_index + 1) then
		new_nav_index = self._strike_nav_index - 1
		new_pos = mvector3.copy(path[self._strike_nav_index])
		self._strike_now = true
	end
	if complete then
		self._end_of_path = true
	end
	self._nav_index = new_nav_index
	local wanted_vel
	if self._turn_vel then
		local dis = mvector3.distance(path[old_nav_index + 1]:with_z(cur_pos.z), cur_pos)
		if dis < 70 then
			wanted_vel = math.lerp(self._turn_vel, vel, dis / 70)
		end
	end
	wanted_vel = wanted_vel or vel
	if self._start_run then
		local delta_pos = self._common_data.unit:get_animation_delta_position()
		walk_dis = 2 * delta_pos:length()
		self._cur_vel = walk_dis / dt
	else
		local c_vel = self._cur_vel
		if c_vel ~= wanted_vel then
			local adj = vel * 2 * dt
			c_vel = math.step(c_vel, wanted_vel, adj)
			self._cur_vel = c_vel
		end
		walk_dis = c_vel * dt
	end
	if old_nav_index ~= new_nav_index then
		if self._is_local and not self._was_interrupted then
			self:_send_nav_point(mvector3.copy(path[old_nav_index]))
		end
		local future_pos = path[new_nav_index + 2]
		local next_pos = path[new_nav_index + 1]
		local back_pos = path[new_nav_index]
		local cur_vec = next_pos - back_pos
		mvector3.set_z(cur_vec, 0)
		if future_pos then
			mvector3.normalize(cur_vec)
			local next_vec = future_pos - next_pos
			mvector3.set_z(next_vec, 0)
			mvector3.normalize(next_vec)
			local turn_dot = mvector3.dot(cur_vec, next_vec)
			local dot_lerp = math.max(0, turn_dot)
			local turn_vel = math.lerp(math.min(vel, math.max(100, vel * 0.3)), vel, dot_lerp)
			self._turn_vel = turn_vel
		end
	elseif self._is_local and not self._was_interrupted and mvector3.distance(self._last_sent_pos, cur_pos) > 200 then
		self._nav_index = self._nav_index + 1
		table.insert(self._nav_path, self._nav_index, mvector3.copy(cur_pos))
		self:_send_nav_point(cur_pos)
	end
	self._last_pos = mvector3.copy(new_pos)
end
function ActionSpooc:_adjust_walk_anim_speed(dt, target_speed)
	local state = self._machine:segment_state(Idstring("base"))
	self._machine:set_speed(state, target_speed)
end
function ActionSpooc:_adjust_move_anim(...)
	return CopActionWalk._adjust_move_anim(self, ...)
end
function ActionSpooc:_start_move_anim(...)
	return CopActionWalk._start_move_anim(self, ...)
end
function ActionSpooc:_stop_walk()
	return CopActionWalk._stop_walk(self)
end
function ActionSpooc:_upd_wait(t)
	if self._ext_anim.move then
		self:_stop_walk()
	end
end
function ActionSpooc:_upd_striking(t)
	if self._ext_anim.act then
		if self._is_local then
			if not self._ext_anim.spooc_exit and not self._ext_anim.spooc_enter and (not alive(self._strike_unit) or not self._strike_unit:character_damage().incapacitated or not self._strike_unit:character_damage():incapacitated()) then
				self._ext_movement:play_redirect("spooc_exit")
			end
		elseif not self._ext_anim.spooc_exit and not self._ext_anim.spooc_enter and self._end_of_path then
			self._ext_movement:drop_held_items()
			self:_start_sprint()
		end
	else
		self._ext_movement:drop_held_items()
		self:_start_sprint()
	end
end
function ActionSpooc:sync_stop(pos, stop_nav_index)
	if self._host_stop_pos_inserted then
		stop_nav_index = stop_nav_index + self._host_stop_pos_inserted
	end
	local nav_path = self._nav_path
	while stop_nav_index < #nav_path do
		table.remove(nav_path)
	end
	self._stop_pos = pos
	if #nav_path < stop_nav_index - 1 then
		self._nr_expected_nav_points = stop_nav_index - #nav_path + 1
	else
		table.insert(nav_path, pos)
	end
	self._nav_index = math.min(self._nav_index, #nav_path - 1)
	if self._end_of_path and not self._nr_expected_nav_points then
		self._end_of_path = nil
		self:_start_sprint()
	end
end
function ActionSpooc:sync_append_nav_point(nav_point)
	if self._stop_pos and not self._nr_expected_nav_points then
		return
	end
	table.insert(self._nav_path, nav_point)
	if self._end_of_path then
		self._end_of_path = nil
		local nav_index = math.min(#self._nav_path - 1, self._nav_index + 1)
		self._nav_index = nav_index
		self._cur_vel = 0
		if self._nr_expected_nav_points then
			if self._nr_expected_nav_points == 1 then
				self._nr_expected_nav_points = nil
				table.insert(self._nav_path, self._stop_pos)
			else
				self._nr_expected_nav_points = self._nr_expected_nav_points - 1
			end
		end
		self:_start_sprint()
	end
end
function ActionSpooc:sync_strike(pos)
	if self._stop_pos and not self._nr_expected_nav_points then
		return
	end
	table.insert(self._nav_path, pos)
	self._strike_nav_index = #self._nav_path
	if self._nr_expected_nav_points then
		if self._nr_expected_nav_points == 1 then
			self._nr_expected_nav_points = nil
			table.insert(self._nav_path, self._stop_pos)
		else
			self._nr_expected_nav_points = self._nr_expected_nav_points - 1
		end
	end
	if self._end_of_path then
		self._end_of_path = nil
		self._cur_vel = 0
		self:_start_sprint()
	end
end
function ActionSpooc:chk_block(action_type, t)
	return CopActionAct.chk_block(self, action_type, t)
end
function ActionSpooc:chk_block_client(action_desc, action_type, t)
	if CopActionAct.chk_block(self, action_type, t) and (not action_desc or action_desc.body_part ~= 3) then
		return true
	end
end
function ActionSpooc:need_upd()
	return true
end
function ActionSpooc:_send_nav_point(nav_point)
	self._ext_network:send("action_spooc_nav_point", nav_point)
	mvector3.set(self._last_sent_pos, nav_point)
end
function ActionSpooc:_set_updator(name)
	self.update = self[name]
end
function ActionSpooc:on_attention(attention)
	if self._target_unit and attention and attention.unit and attention.unit:key() == self._target_unit:key() then
		return
	end
	self._target_unit = nil
end
