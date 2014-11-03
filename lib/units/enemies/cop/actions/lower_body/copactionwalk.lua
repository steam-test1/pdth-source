local mvec3_set = mvector3.set
local mvec3_z = mvector3.z
local mvec3_set_z = mvector3.set_z
local mvec3_sub = mvector3.subtract
local mvec3_norm = mvector3.normalize
local mvec3_add = mvector3.add
local mvec3_mul = mvector3.multiply
local mvec3_lerp = mvector3.lerp
local mvec3_cpy = mvector3.copy
local mvec3_set_l = mvector3.set_length
local mvec3_dot = mvector3.dot
local mvec3_cross = mvector3.cross
local mvec3_dis = mvector3.distance
local mvec3_dis_sq = mvector3.distance_sq
local mvec3_len = mvector3.length
local mvec3_rot = mvector3.rotate_with
local mrot_lookat = mrotation.set_look_at
local mrot_slerp = mrotation.slerp
local math_abs = math.abs
local math_max = math.max
local math_min = math.min
local tmp_vec1 = Vector3()
local tmp_vec2 = Vector3()
local tmp_vec3 = Vector3()
local temp_rot1 = Rotation()
local idstr_base = Idstring("base")
CopActionWalk = CopActionWalk or class()
CopActionWalk._walk_anim_velocities = {
	stand = {
		walk = {
			fwd = 200,
			bwd = 160,
			l = 157,
			r = 179
		},
		run = {
			fwd = 366,
			bwd = 373,
			l = 345,
			r = 400
		}
	},
	crouch = {
		walk = {
			fwd = 148,
			bwd = 114,
			l = 122,
			r = 135
		},
		run = {
			fwd = 276,
			bwd = 230,
			l = 246,
			r = 224
		}
	},
	wounded = {
		walk = {
			fwd = 148,
			bwd = 114,
			l = 122,
			r = 135
		},
		run = {
			fwd = 280,
			bwd = 230,
			l = 246,
			r = 224
		}
	},
	panic = {
		run = {
			fwd = 455,
			bwd = 360,
			l = 350,
			r = 410
		}
	}
}
CopActionWalk._walk_anim_lengths = {
	stand = {
		walk = {
			fwd = 32,
			bwd = 32,
			l = 30,
			r = 30
		},
		run = {
			fwd = 23,
			bwd = 15,
			l = 15,
			r = 16
		},
		run_start = {
			fwd = 31,
			bwd = 34,
			l = 27,
			r = 26
		},
		run_start_turn = {
			bwd = 29,
			l = 33,
			r = 31
		},
		run_stop = {
			fwd = 31,
			bwd = 37,
			l = 32,
			r = 36
		}
	},
	crouch = {
		walk = {
			fwd = 28,
			bwd = 29,
			l = 29,
			r = 29
		},
		run = {
			fwd = 19,
			bwd = 18,
			l = 19,
			r = 19
		},
		run_start = {
			fwd = 35,
			bwd = 19,
			l = 33,
			r = 33
		},
		run_start_turn = {
			bwd = 31,
			l = 40,
			r = 37
		},
		run_stop = {
			fwd = 35,
			bwd = 19,
			l = 27,
			r = 30
		}
	},
	wounded = {
		walk = {
			fwd = 28,
			bwd = 29,
			l = 29,
			r = 29
		},
		run = {
			fwd = 19,
			bwd = 18,
			l = 19,
			r = 19
		}
	},
	panic = {
		run = {
			fwd = 15,
			bwd = 15,
			l = 15,
			r = 16
		}
	}
}
for pose, speeds in pairs(CopActionWalk._walk_anim_lengths) do
	for speed, sides in pairs(speeds) do
		for side, speed in pairs(sides) do
			sides[side] = speed * 0.03333
		end
	end
end
CopActionWalk._matching_walk_anims = {
	fwd = {bwd = true},
	bwd = {fwd = true},
	l = {r = true},
	r = {l = true}
}
CopActionWalk._walk_side_rot = {
	fwd = Rotation(),
	bwd = Rotation(180),
	l = Rotation(-90),
	r = Rotation(90)
}
CopActionWalk._anim_movement = {
	stand = {
		run_start_turn_bwd = {
			ds = Vector3(25, -152, 0)
		},
		run_start_turn_l = {
			ds = Vector3(-230, 50, 0)
		},
		run_start_turn_r = {
			ds = Vector3(230, 50, 0)
		},
		run_stop_fwd = 163,
		run_stop_bwd = 150,
		run_stop_l = 160,
		run_stop_r = 210
	},
	crouch = {
		run_start_turn_bwd = {
			ds = Vector3(49, -161, 0)
		},
		run_start_turn_l = {
			ds = Vector3(-250, 90, 0)
		},
		run_start_turn_r = {
			ds = Vector3(240, 68, 0)
		},
		run_stop_fwd = 120,
		run_stop_bwd = 50,
		run_stop_l = 110,
		run_stop_r = 80
	},
	panic = {
		run_start_turn_bwd = {
			ds = Vector3(49, -161, 0)
		},
		run_start_turn_l = {
			ds = Vector3(-250, 90, 0)
		},
		run_start_turn_r = {
			ds = Vector3(240, 68, 0)
		},
		run_stop_fwd = 120,
		run_stop_bwd = 50,
		run_stop_l = 110,
		run_stop_r = 80
	}
}
CopActionWalk._anim_block_presets = {
	block_all = {
		idle = -1,
		action = -1,
		walk = -1,
		crouch = -1,
		stand = -1,
		dodge = -1,
		shoot = -1,
		turn = -1,
		light_hurt = -1,
		hurt = -1,
		heavy_hurt = -1,
		act = -1
	},
	block_lower = {
		idle = -1,
		walk = -1,
		crouch = -1,
		stand = -1,
		dodge = -1,
		turn = -1,
		light_hurt = -1,
		hurt = -1,
		heavy_hurt = -1,
		act = -1
	},
	block_upper = {
		shoot = -1,
		action = -1,
		crouch = -1,
		stand = -1
	},
	block_none = {stand = -1, crouch = -1}
}
function CopActionWalk:init(action_desc, common_data)
	self._common_data = common_data
	self._unit = common_data.unit
	self._ext_movement = common_data.ext_movement
	self._ext_anim = common_data.ext_anim
	self._ext_base = common_data.ext_base
	self._ext_network = common_data.ext_network
	self._body_part = action_desc.body_part
	self._machine = common_data.machine
	self:on_attention(common_data.attention)
	self._stance = common_data.stance
	if not self:_sanitize() then
		return
	end
	self._ext_movement:enable_update()
	self._persistent = action_desc.persistent
	self._haste = action_desc.variant
	self._start_t = TimerManager:game():time()
	self._no_walk = action_desc.no_walk
	self._no_strafe = action_desc.no_strafe
	self._last_pos = mvec3_cpy(common_data.pos)
	self._nav_path = action_desc.nav_path
	self._last_upd_t = self._start_t - 0.001
	self._host_stop_pos_inserted = action_desc.host_stop_pos_inserted
	if Network:is_client() then
		for i, nav_point in ipairs(self._nav_path) do
			if not nav_point.x then
				function nav_point.element.value(element, name)
					return element[name]
				end
				function nav_point.element.nav_link_wants_align_pos(element)
					return element.from_idle
				end
			end
		end
		local new_host_pos_inserted
		if not action_desc.interrupted then
			local ray_params = {
				tracker_from = common_data.nav_tracker,
				pos_to = self._nav_point_pos(self._nav_path[2])
			}
			if managers.navigation:raycast(ray_params) then
				table.insert(self._nav_path, 2, mvec3_cpy(self._ext_movement:m_host_stop_pos()))
				self._host_stop_pos_inserted = (self._host_stop_pos_inserted or 0) + 1
				new_host_pos_inserted = true
			end
		end
		if action_desc.path_index then
			self._simplified_path_index = action_desc.path_index
			if new_host_pos_inserted and 1 < self._simplified_path_index then
				self._simplified_path_index = math.min(self._simplified_path_index + 1, #self._nav_path - 1)
			end
		end
	else
		if managers.groupai:state():all_AI_criminals()[common_data.unit:key()] then
			self._nav_link_invul = true
		end
		local nav_path = {}
		for i, nav_point in ipairs(self._nav_path) do
			if nav_point.x then
				table.insert(nav_path, nav_point)
			elseif alive(nav_point) then
				table.insert(nav_path, {
					element = nav_point:script_data().element,
					c_class = nav_point
				})
			else
				debug_pause_unit(self._unit, "dead nav_link", self._unit)
				return false
			end
		end
		self._nav_path = nav_path
	end
	if action_desc.path_simplified then
		local t_ins = table.insert
		local original_path = self._nav_path
		local s_path = {}
		self._simplified_path = s_path
		for _, nav_point in ipairs(original_path) do
			t_ins(s_path, nav_point.x and mvec3_cpy(nav_point) or nav_point)
		end
	else
		local good_pos = common_data.nav_tracker:lost() and common_data.nav_tracker:field_position() or common_data.nav_tracker:position()
		self._simplified_path = self._calculate_simplified_path(good_pos, self._nav_path)
	end
	self:_advance_simplified_path(self._simplified_path_index or 1)
	self._curve_path_index = 1
	self:_chk_start_anim(CopActionWalk._nav_point_pos(self._simplified_path[self._simplified_path_index + 1]))
	if self._start_run then
		self:_set_updator("_upd_start_anim_first_frame")
	end
	if not self._start_run_turn and mvec3_dis(self._nav_point_pos(self._simplified_path[self._simplified_path_index + 1]), self._simplified_path[self._simplified_path_index]) > 400 and self._ext_base:lod_stage() == 1 then
		self._curve_path = self:_calculate_curved_path(self._simplified_path, self._simplified_path_index, 1)
	else
		self._curve_path = {
			self._simplified_path[self._simplified_path_index],
			mvec3_cpy(self._nav_point_pos(self._simplified_path[self._simplified_path_index + 1]))
		}
	end
	if #self._simplified_path == 2 and not self._no_walk and self._haste ~= "walk" and not (mvec3_dis(self._curve_path[2], self._curve_path[1]) < 120) then
		self._chk_stop_dis = 210
	end
	self._walk_velocity = self:_get_max_walk_speed()
	self._last_vel_z = 0
	self._cur_vel = 0
	self._end_rot = action_desc.end_rot
	CopActionAct._create_blocks_table(self, action_desc.blocks)
	if Network:is_server() then
		self._sync = true
		local sync_yaw = 0
		if self._end_rot then
			local yaw = self._end_rot:yaw()
			if yaw < 0 then
				yaw = 360 + yaw
			end
			sync_yaw = 1 + math.ceil(yaw * 254 / 360)
		end
		local sync_haste = self._haste == "walk" and 1 or 2
		local nav_link_act_index, nav_link_act_yaw
		local next_nav_point = self._simplified_path[2]
		local nav_link_from_idle = false
		if next_nav_point.x then
			nav_link_act_index = 0
			nav_link_act_yaw = 1
		else
			nav_link_act_index = CopActionAct._get_act_index(CopActionAct, next_nav_point.element:value("so_action"))
			nav_link_act_yaw = next_nav_point.element:value("rotation"):yaw()
			if nav_link_act_yaw < 0 then
				nav_link_act_yaw = 360 + nav_link_act_yaw
			end
			nav_link_act_yaw = math.ceil(255 * nav_link_act_yaw / 360)
			if nav_link_act_yaw == 0 then
				nav_link_act_yaw = 255
			end
			nav_link_from_idle = next_nav_point.element:nav_link_wants_align_pos() and true or false
		end
		self._ext_network:send("action_walk_start", self._nav_point_pos(next_nav_point), nav_link_act_yaw, nav_link_act_index, nav_link_from_idle, sync_haste, sync_yaw, self._no_walk and true or false, self._no_strafe and true or false)
	end
	self._skipped_frames = 1
	return true
end
function CopActionWalk:_sanitize()
	if not self._ext_anim.pose then
		debug_pause("[CopActionWalk:init] no pose in anim", self._machine:segment_state(idstr_base), self._common_data.unit)
		local res = self._ext_movement:play_redirect("idle")
		if not self._ext_anim.pose then
			print("[CopActionWalk:init] failed restoring pose with anim", self._machine:segment_state(idstr_base), res)
			if not self._ext_movement:play_state("std/stand/still/idle/look") then
				debug_pause()
				return
			end
		end
	end
	if Network:is_client() and not self._walk_anim_lengths[self._ext_anim.pose] then
		self._ext_movement:play_redirect("stand")
	end
	return true
end
function CopActionWalk:_chk_start_anim(next_pos)
	if self._haste ~= "run" then
		return
	end
	local lod_stage = self._ext_base:lod_stage()
	if not lod_stage or lod_stage > 2 then
		return
	end
	local can_turn_and_fire = true
	local path_dir = next_pos - self._common_data.pos
	mvec3_set_z(path_dir, 0)
	local path_len = mvec3_norm(path_dir)
	local path_angle = path_dir:to_polar_with_reference(self._common_data.fwd, math.UP).spin
	if self._attention_pos then
		local target_vec
		target_vec = self._attention_pos - self._common_data.pos
		local target_vec_flat = target_vec:with_z(0)
		mvec3_norm(target_vec_flat)
		local fwd_dot = mvec3_dot(path_dir, target_vec_flat)
		if fwd_dot < 0.7 then
			can_turn_and_fire = nil
		end
	end
	if math_abs(path_angle) > 135 then
		if can_turn_and_fire then
			local pose = self._ext_anim.pose
			local spline_data = self._anim_movement[pose].run_start_turn_bwd
			local ds = spline_data.ds
			if ds:length() < path_len - 100 then
				if path_angle > 0 then
					path_angle = path_angle - 360
				end
				self._start_run_turn = {
					self._common_data.rot:yaw(),
					path_angle,
					"bwd"
				}
			end
		end
	elseif path_angle < -65 then
		if can_turn_and_fire then
			local pose = self._ext_anim.pose
			local spline_data = self._anim_movement[pose].run_start_turn_r
			local ds = spline_data.ds
			if ds:length() < path_len - 100 then
				self._start_run_turn = {
					self._common_data.rot:yaw(),
					path_angle,
					"r"
				}
			end
		end
	elseif path_angle > 65 and can_turn_and_fire then
		local pose = self._ext_anim.pose
		local spline_data = self._anim_movement[pose].run_start_turn_l
		local ds = spline_data.ds
		if ds:length() < path_len - 100 then
			self._start_run_turn = {
				self._common_data.rot:yaw(),
				path_angle,
				"l"
			}
		end
	end
	self._start_run = true
	self._root_blend_disabled = true
	self._ext_movement:set_root_blend(false)
	if not self._start_run_turn then
		local right_dot = mvec3_dot(path_dir, self._common_data.right)
		local fwd_dot = mvec3_dot(path_dir, self._common_data.fwd)
		local wanted_walk_dir
		if math_abs(fwd_dot) > math_abs(right_dot) then
			self._start_run_straight = fwd_dot > 0 and "fwd" or "bwd"
		else
			self._start_run_straight = right_dot > 0 and "r" or "l"
		end
	end
end
function CopActionWalk._calculate_shortened_path(path)
	local index = 2
	local test_pos = tmp_vec1
	while index < #path do
		if path[index].x and path[index - 1].x then
			mvec3_lerp(test_pos, path[index - 1], path[index], 0.8)
			local fwd_pos = CopActionWalk._nav_point_pos(path[index + 1])
			local ray_fwd, trace = CopActionWalk._chk_shortcut_pos_to_pos(test_pos, fwd_pos, true)
			if not ray_fwd then
				mvec3_set(path[index], test_pos)
			end
		end
		index = index + 1
	end
end
function CopActionWalk._apply_padding_to_simplified_path(path)
	local dim_mag = 212.132
	mvector3.set_static(tmp_vec1, dim_mag, dim_mag, 0)
	mvector3.set_static(tmp_vec2, dim_mag, -dim_mag, 0)
	local diagonals = {tmp_vec1, tmp_vec2}
	local index = 2
	local offset = tmp_vec3
	local to_pos = Vector3()
	while index < #path do
		local pos = path[index]
		if pos.x then
			for _, diagonal in ipairs(diagonals) do
				mvec3_set(to_pos, pos)
				mvec3_add(to_pos, diagonal)
				local col_pos, trace = CopActionWalk._chk_shortcut_pos_to_pos(pos, to_pos, true)
				mvec3_set(offset, trace[1])
				mvec3_set(to_pos, pos)
				mvec3_mul(diagonal, -1)
				mvec3_add(to_pos, diagonal)
				col_pos, trace = CopActionWalk._chk_shortcut_pos_to_pos(pos, to_pos, true)
				mvec3_lerp(offset, offset, trace[1], 0.5)
				local ray_fwd = CopActionWalk._chk_shortcut_pos_to_pos(offset, CopActionWalk._nav_point_pos(path[index + 1]))
				if ray_fwd then
					break
				else
					local ray_bwd = CopActionWalk._chk_shortcut_pos_to_pos(offset, CopActionWalk._nav_point_pos(path[index - 1]))
					if ray_bwd then
				end
				else
					mvec3_set(pos, offset)
				end
			end
			index = index + 1
		else
			index = index + 2
		end
	end
end
function CopActionWalk:_calculate_curved_path(path, index, curvature_factor, enter_dir)
	local curved_path = {}
	local p1 = self._nav_point_pos(path[index])
	local p4 = self._nav_point_pos(path[index + 1])
	local p2, p3
	local segment_vec = p4 - p1
	local segment_dis = segment_vec:length()
	local bezier_func
	local bezier_params = {}
	local vec_out = Vector3()
	local vec_in = Vector3()
	if enter_dir or path[index - 1] and path[index - 1].x then
		if enter_dir then
			mvec3_set(vec_out, enter_dir)
		else
			mvec3_set(vec_out, p1)
			mvec3_sub(vec_out, path[index - 1])
		end
		mvec3_set_l(vec_out, segment_dis)
		mvec3_set(vec_in, p4)
		mvec3_sub(vec_in, p1)
		mvec3_set_l(vec_in, segment_dis * curvature_factor)
		mvec3_add(vec_out, vec_in)
		mvec3_set_z(vec_out, 0)
		mvec3_set_l(vec_out, segment_dis * 0.3)
		p2 = p1 + vec_out
		table.insert(bezier_params, p2)
	end
	if path[index + 2] and p2 then
		mvec3_set(vec_out, p4)
		mvec3_sub(vec_out, self._nav_point_pos(path[index + 2]))
		mvec3_set_l(vec_out, segment_dis)
		mvec3_set(vec_in, p1)
		mvec3_sub(vec_in, p2)
		mvec3_set_l(vec_in, segment_dis * curvature_factor)
		mvec3_add(vec_out, vec_in)
		mvec3_set_z(vec_out, 0)
		mvec3_set_l(vec_out, segment_dis * 0.3)
		p3 = p4 + vec_out
		table.insert(bezier_params, p3)
	end
	table.insert(bezier_params, 1, p1)
	table.insert(bezier_params, p4)
	bezier_func = #bezier_params == 4 and math.bezier or #bezier_params == 3 and math.quadratic_bezier
	table.insert(curved_path, mvec3_cpy(p1))
	local raycast_params = {}
	local function _on_fail()
		if curvature_factor < 1 then
			return {
				mvec3_cpy(p1),
				mvec3_cpy(p4)
			}
		else
			return self:_calculate_curved_path(path, index, 0.5, enter_dir)
		end
	end
	if bezier_func then
		local nr_samples = 7
		local prev_pos = curved_path[1]
		for i = 1, nr_samples - 1 do
			local pos = bezier_func(bezier_params, i / nr_samples)
			raycast_params.pos_from = prev_pos
			raycast_params.pos_to = pos
			local shortcut_raycast = managers.navigation:raycast(raycast_params)
			if shortcut_raycast then
				return _on_fail()
			end
			table.insert(curved_path, pos)
			prev_pos = pos
		end
		raycast_params.pos_from = prev_pos
		raycast_params.pos_to = p4
		local shortcut_raycast = managers.navigation:raycast(raycast_params)
		if shortcut_raycast then
			return _on_fail()
		end
		table.insert(curved_path, mvec3_cpy(p4))
	else
		table.insert(curved_path, mvec3_cpy(p4))
	end
	return curved_path
end
function CopActionWalk:on_exit()
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
	if self._sync then
		self._ext_network:send("action_walk_stop", mvec3_cpy(self._ext_movement:m_pos()))
	else
		self._ext_movement:set_m_host_stop_pos(self._ext_movement:m_pos())
	end
	if self._nav_link_invul_on then
		self._nav_link_invul_on = nil
		self._common_data.ext_damage:set_invulnerable(false)
	end
	if self._ext_anim.act and not self._unit:character_damage():dead() and self._unit:movement():chk_action_forbidden("walk") then
		debug_pause("[CopActionWalk:on_exit] possible illegal exit!", self._unit, self._machine:segment_state(idstr_base))
		Application:draw_cylinder(self._common_data.pos, self._common_data.pos + math.UP * 5000, 30, 1, 0, 0)
	end
end
function CopActionWalk:update(t)
	local dt
	local vis_state = self._ext_base:lod_stage()
	vis_state = vis_state or 4
	if vis_state == 1 then
		dt = t - self._last_upd_t
		self._last_upd_t = TimerManager:game():time()
	elseif vis_state > self._skipped_frames then
		self._skipped_frames = self._skipped_frames + 1
		return
	else
		self._skipped_frames = 1
		dt = t - self._last_upd_t
		self._last_upd_t = TimerManager:game():time()
	end
	local pos_new
	if self._end_of_path then
		if self._next_is_nav_link then
			self:_set_updator("_upd_nav_link_first_frame")
			self:update(t)
			return
		elseif self._persistent then
			self:_set_updator("_upd_wait")
		else
			self._expired = true
			if self._end_rot then
				self._ext_movement:set_rotation(self._end_rot)
			end
		end
	else
		self:_nav_chk_walk(t, dt, vis_state)
	end
	local move_dir = tmp_vec3
	mvec3_set(move_dir, self._last_pos)
	mvec3_sub(move_dir, self._common_data.pos)
	mvec3_set_z(move_dir, 0)
	if self._cur_vel < 0.1 then
		move_dir = nil
	end
	local anim_data = self._ext_anim
	if move_dir and not self._expired then
		local face_fwd = tmp_vec1
		local wanted_walk_dir
		local move_dir_norm = move_dir:normalized()
		if self._no_strafe then
			wanted_walk_dir = "fwd"
		else
			if self._attention_pos then
				mvec3_set(face_fwd, self._attention_pos)
				mvec3_sub(face_fwd, self._common_data.pos)
			elseif self._footstep_pos then
				mvec3_set(face_fwd, self._footstep_pos)
				mvec3_sub(face_fwd, self._common_data.pos)
			else
				mvec3_set(face_fwd, self._common_data.fwd)
			end
			mvec3_set_z(face_fwd, 0)
			mvec3_norm(face_fwd)
			local face_right = tmp_vec2
			mvec3_cross(face_right, face_fwd, math.UP)
			mvec3_norm(face_right)
			local right_dot = mvec3_dot(move_dir_norm, face_right)
			local fwd_dot = mvec3_dot(move_dir_norm, face_fwd)
			if math_abs(fwd_dot) > math_abs(right_dot) then
				if (anim_data.move_l and right_dot < 0 or anim_data.move_r and right_dot > 0) and math_abs(fwd_dot) < 0.73 then
					wanted_walk_dir = anim_data.move_side
				else
					wanted_walk_dir = fwd_dot > 0 and "fwd" or "bwd"
				end
			elseif (anim_data.move_fwd and fwd_dot > 0 or anim_data.move_bwd and fwd_dot < 0) and math_abs(right_dot) < 0.73 then
				wanted_walk_dir = anim_data.move_side
			else
				wanted_walk_dir = right_dot > 0 and "r" or "l"
			end
		end
		local rot_new
		if self._curve_path_end_rot then
			local dis_lerp = 1 - math.min(1, mvec3_dis(self._last_pos, self._footstep_pos) / 140)
			rot_new = temp_rot1
			mrot_slerp(rot_new, self._curve_path_end_rot, self._nav_link_rot or self._end_rot, dis_lerp)
		else
			local wanted_u_fwd = tmp_vec1
			mvec3_set(wanted_u_fwd, move_dir_norm)
			mvec3_rot(wanted_u_fwd, self._walk_side_rot[wanted_walk_dir])
			mrot_lookat(temp_rot1, wanted_u_fwd, math.UP)
			rot_new = temp_rot1
			mrot_slerp(rot_new, self._common_data.rot, rot_new, math.min(1, dt * 5))
		end
		self._ext_movement:set_rotation(rot_new)
		if self._chk_stop_dis and self._ext_anim.move then
			local end_dis = mvec3_dis(self._nav_point_pos(self._simplified_path[#self._simplified_path]), self._last_pos)
			if end_dis < self._chk_stop_dis then
				local stop_dis = CopActionWalk._anim_movement[self._ext_anim.pose]["run_stop_" .. wanted_walk_dir]
				if end_dis < stop_dis then
					self._stop_anim_fwd = not self._nav_link_rot and self._end_rot and self._end_rot:y() or move_dir_norm:rotate_with(self._walk_side_rot[wanted_walk_dir])
					self._stop_anim_side = wanted_walk_dir
					self._stop_dis = stop_dis
					self:_set_updator("_upd_stop_anim_first_frame")
				end
			end
		end
		local real_velocity = self._cur_vel
		local variant = self._haste
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
		local pose = 0 < self._stance.values[4] and "wounded" or self._ext_anim.pose or "stand"
		if not self._walk_anim_velocities[pose] or not self._walk_anim_velocities[pose][variant] or not self._walk_anim_velocities[pose][variant][wanted_walk_dir] then
			debug_pause("Boom...", self._common_data.unit, "pose", pose, "variant", variant, "wanted_walk_dir", wanted_walk_dir, self._machine:segment_state(Idstring("base")))
			return
		end
		local anim_walk_speed = self._walk_anim_velocities[pose][variant][wanted_walk_dir]
		local wanted_walk_anim_speed = real_velocity / anim_walk_speed
		self:_adjust_walk_anim_speed(dt, wanted_walk_anim_speed)
	end
	self:_set_new_pos(dt)
end
function CopActionWalk:_upd_start_anim_first_frame(t)
	local pose = self._ext_anim.pose or "stand"
	local speed_mul = self._walk_velocity / self._walk_anim_velocities[pose][self._haste].fwd
	self:_start_move_anim(self._start_run_turn and self._start_run_turn[3] or self._start_run_straight, "run", speed_mul, self._start_run_turn)
	self._start_max_vel = 0
	self:_set_updator("_upd_start_anim")
	self._ext_base:chk_freeze_anims()
end
function CopActionWalk:_upd_start_anim(t)
	if not self._ext_anim.run_start then
		self._start_run = nil
		self._start_run_turn = nil
		local old_pos = self._curve_path[1]
		self._curve_path[1] = mvec3_cpy(self._common_data.pos)
		while self._curve_path[3] do
			mvec3_set(tmp_vec1, self._curve_path[2])
			mvec3_sub(tmp_vec1, self._curve_path[1])
			mvec3_set(tmp_vec2, self._curve_path[1])
			mvec3_sub(tmp_vec2, old_pos)
			if mvec3_dot(tmp_vec1, tmp_vec2) < 0 and not CopActionWalk._chk_shortcut_pos_to_pos(self._curve_path[1], self._curve_path[3], nil) then
				table.remove(self._curve_path, 2)
			else
				break
			end
		end
		self._last_pos = mvec3_cpy(self._common_data.pos)
		self._curve_path_index = 1
		self._start_max_vel = nil
		self:_set_updator(nil)
		self:update(t)
		return
	end
	local dt = TimerManager:game():delta_time()
	if self._start_run_turn then
		if self._ext_anim.run_start_full_blend then
			local seg_rel_t = self._machine:segment_relative_time(idstr_base)
			if not self._start_run_turn.start_seg_rel_t then
				self._start_run_turn.start_seg_rel_t = seg_rel_t
			end
			local delta_pos = self._common_data.unit:get_animation_delta_position()
			self._cur_vel = math_max(delta_pos:length() / dt, self._start_max_vel)
			self._start_max_vel = self._cur_vel
			local new_pos = self._common_data.pos + delta_pos
			local ray_params = {
				tracker_from = self._common_data.nav_tracker,
				allow_entry = true,
				pos_to = new_pos,
				trace = true
			}
			local collision = managers.navigation:raycast(ray_params)
			if collision then
				new_pos = ray_params.trace[1]
			end
			self._last_pos = new_pos
			local seg_rel_t_clamp = math.clamp((seg_rel_t - self._start_run_turn.start_seg_rel_t) / 0.77, 0, 1)
			local prg_angle = self._start_run_turn[2] * seg_rel_t_clamp
			local new_yaw = self._start_run_turn[1] + prg_angle
			local rot_new = temp_rot1
			mrotation.set_yaw_pitch_roll(rot_new, new_yaw, 0, 0)
			self._ext_movement:set_rotation(rot_new)
		else
			self._start_run_turn.start_seg_rel_t = self._machine:segment_relative_time(idstr_base)
		end
	else
		if self._end_of_path then
			if self._next_is_nav_link then
				self._start_run = nil
				self:_set_updator("_upd_nav_link_first_frame")
				self:update(t)
				return
			elseif self._persistent then
				self._start_run = nil
				self:_set_updator("_upd_wait")
			else
				self._expired = true
				if self._end_rot then
					self._ext_movement:set_rotation(self._end_rot)
				end
			end
			return
		else
			self:_nav_chk_walk(t, dt, 1)
		end
		if not self._end_of_curved_path then
			local wanted_u_fwd = tmp_vec1
			mvector3.direction(wanted_u_fwd, self._common_data.pos, self._curve_path[self._curve_path_index + 1])
			mvec3_rot(wanted_u_fwd, self._walk_side_rot[self._start_run_straight])
			mrot_lookat(temp_rot1, wanted_u_fwd, math.UP)
			mrot_slerp(temp_rot1, self._common_data.rot, temp_rot1, math.min(1, dt * 5))
			self._ext_movement:set_rotation(temp_rot1)
		end
	end
	self:_set_new_pos(dt)
end
function CopActionWalk:_set_new_pos(dt)
	local path_pos = self._last_pos
	local path_z = path_pos.z
	self._ext_movement:upd_ground_ray(path_pos, true)
	local gnd_z = self._common_data.gnd_ray.position.z
	gnd_z = math.clamp(gnd_z, path_z - 80, path_z + 80)
	local pos_new = tmp_vec1
	mvec3_set(pos_new, path_pos)
	mvec3_set_z(pos_new, self._common_data.pos.z)
	if gnd_z < pos_new.z then
		self._last_vel_z = self._apply_freefall(pos_new, self._last_vel_z, gnd_z, dt)
	else
		if gnd_z > pos_new.z then
			mvec3_set_z(pos_new, gnd_z)
		end
		self._last_vel_z = 0
	end
	self._ext_movement:set_position(pos_new)
end
function CopActionWalk:type()
	return "walk"
end
function CopActionWalk:get_husk_interrupt_desc()
	local old_action_desc = {
		type = "walk",
		body_part = 2,
		end_rot = self._end_rot,
		variant = self._haste,
		nav_path = self._simplified_path,
		path_index = self._simplified_path_index,
		path_simplified = true,
		persistent = self._persistent,
		no_walk = self._no_walk,
		no_strafe = self._no_strafe,
		host_stop_pos_inserted = self._host_stop_pos_inserted,
		interrupted = true
	}
	if self._blocks or self._old_blocks then
		local blocks = {}
		for i, k in pairs(self._old_blocks or self._blocks) do
			blocks[i] = -1
		end
		old_action_desc.blocks = blocks
	end
	return old_action_desc
end
function CopActionWalk:expired()
	return self._expired
end
function CopActionWalk:on_attention(attention)
	if attention then
		if attention.unit then
			self._attention_pos = attention.unit:movement():m_pos()
		else
			self._attention_pos = attention.pos
		end
	else
		self._attention_pos = false
	end
end
function CopActionWalk:_get_max_walk_speed()
	return self._haste == "walk" and self._common_data.char_tweak.SPEED_WALK or self._common_data.char_tweak.SPEED_RUN
end
function CopActionWalk:save(save_data)
	save_data.type = "walk"
	save_data.body_part = self._body_part
	save_data.variant = self._haste
	save_data.end_rot = self._end_rot
	save_data.no_walk = self._no_walk
	save_data.no_strafe = self._no_strafe
	save_data.persistent = true
	save_data.path_simplified = true
	save_data.blocks = {
		walk = -1,
		act = -1,
		turn = -1,
		idle = -1
	}
	local t_ins = table.insert
	local sync_path = {}
	local s_path = self._simplified_path
	for i = 1, self._simplified_path_index + 1 do
		local nav_point = s_path[i]
		if nav_point.x then
			t_ins(sync_path, nav_point)
		else
			local element = nav_point.element
			t_ins(sync_path, self.synthesize_nav_link(element:value("position"), element:value("rotation"), element:value("so_action")))
		end
	end
	sync_path[self._simplified_path_index] = self._nav_point_pos(s_path[self._simplified_path_index])
	save_data.nav_path = sync_path
	save_data.path_index = self._simplified_path_index
end
function CopActionWalk.synthesize_nav_link(pos, rot, anim, from_idle)
	local fake_element = {
		position = pos,
		rotation = rot,
		so_action = anim,
		from_idle = from_idle
	}
	local nav_link = {element = fake_element}
	return nav_link
end
CopActionWalk._chk_shortcut_pos_to_pos_params = {allow_entry = true}
function CopActionWalk._chk_shortcut_pos_to_pos(from, to, trace)
	local params = CopActionWalk._chk_shortcut_pos_to_pos_params
	params.pos_from = from
	params.pos_to = to
	params.trace = trace
	local res = managers.navigation:raycast(params)
	return res, params.trace
end
function CopActionWalk._calculate_simplified_path(good_pos, path)
	local simplified_path = {good_pos}
	local size_path = #path
	if size_path > 2 then
		local index_from = 1
		while index_from < #path do
			local index_to = index_from + 2
			while index_to <= #path do
				if path[index_to - 1].x then
					local pos_from = path[index_from]
					local pos_to = CopActionWalk._nav_point_pos(path[index_to])
					local pos_mid = path[index_to - 1]
					local add_point = math.abs(pos_from.z - pos_mid.z - (pos_mid.z - pos_to.z)) > 30
					add_point = add_point or CopActionWalk._chk_shortcut_pos_to_pos(pos_from, pos_to)
					if add_point then
						table.insert(simplified_path, mvec3_cpy(path[index_to - 1]))
						index_from = index_to - 1
						break
					end
				else
					table.insert(simplified_path, path[index_to - 1])
					if path[index_to].x then
						table.insert(simplified_path, mvec3_cpy(path[index_to]))
						index_from = index_to
						break
					end
					index_from = index_to - 1
					break
				end
				index_to = index_to + 1
			end
			if index_to > #path then
				break
			end
		end
	end
	table.insert(simplified_path, mvec3_cpy(path[#path]))
	simplified_path[1] = mvec3_cpy(path[1])
	if #simplified_path > 2 then
		CopActionWalk._calculate_shortened_path(simplified_path)
		CopActionWalk._apply_padding_to_simplified_path(simplified_path)
	end
	return simplified_path
end
function CopActionWalk:_nav_chk_walk(t, dt, vis_state)
	local s_path = self._simplified_path
	local c_path = self._curve_path
	local c_index = self._curve_path_index
	local vel = self._walk_velocity
	if not self._sync and not self._start_run and self:_husk_needs_speedup() then
		vel = 1.25 * vel
	end
	local walk_dis = vel * dt
	local footstep_length = 200
	local nav_advanced
	local cur_pos = self._common_data.pos
	local new_pos, new_c_index, complete, upd_footstep, reservation_failed
	while not self._end_of_curved_path do
		new_pos, new_c_index, complete = self._walk_spline(c_path, self._last_pos, c_index, walk_dis + footstep_length)
		upd_footstep = true
		if complete then
			local s_index = self._simplified_path_index
			if s_index == #s_path - 1 then
				self._end_of_curved_path = true
				if self._end_rot and not self._persistent then
					self._curve_path_end_rot = Rotation(mrotation.yaw(self._common_data.rot), 0, 0)
				end
				nav_advanced = true
				break
			elseif self._next_is_nav_link then
				self._end_of_curved_path = true
				self._nav_link_rot = self._next_is_nav_link.element:value("rotation")
				self._curve_path_end_rot = Rotation(mrotation.yaw(self._common_data.rot), 0, 0)
				break
			else
				s_index = s_index + 1
				self:_advance_simplified_path(s_index)
				if not self._sync or self._next_is_nav_link or not s_path[s_index + 2] or not self:_reserve_nav_pos(self._nav_point_pos(s_path[s_index + 1]), self._nav_point_pos(s_path[s_index + 2]), self._nav_point_pos(c_path[#c_path]), vel) then
				end
				local next_pos = self._nav_point_pos(s_path[s_index + 1])
				if not s_path[s_index].x then
					debug_pause("[CopActionWalk:_nav_chk_walk] missed nav_link", self._unit, s_index, inspect(s_path))
					Application:draw_cylinder(self._common_data.pos, self._common_data.pos + math.UP * 5000, 30, 1, 0, 0)
					s_path[s_index] = self._nav_point_pos(s_path[s_index])
				end
				local dis_sq = mvec3_dis_sq(s_path[s_index], next_pos)
				local new_c_path
				if dis_sq > 490000 and self._ext_base:lod_stage() == 1 then
					new_c_path = self:_calculate_curved_path(s_path, s_index, 1)
				else
					new_c_path = {
						s_path[s_index],
						next_pos
					}
				end
				local i = #c_path - 1
				while c_index <= i do
					table.insert(new_c_path, 1, c_path[i])
					i = i - 1
				end
				self._curve_path = new_c_path
				self._curve_path_index = 1
				c_path = self._curve_path
				c_index = 1
				if self._sync then
					self:_send_nav_point(s_path[s_index + 1])
				end
				nav_advanced = true
			end
		else
			break
		end
	end
	if upd_footstep then
		self._footstep_pos = new_pos:with_z(cur_pos.z)
	end
	if not reservation_failed then
		local wanted_vel
		if self._turn_vel and vis_state == 1 then
			mvec3_set(tmp_vec1, c_path[c_index + 1])
			mvec3_set_z(tmp_vec1, mvec3_z(cur_pos))
			local dis = mvec3_dis_sq(tmp_vec1, cur_pos)
			if dis < 4900 then
				wanted_vel = math.lerp(self._turn_vel, vel, dis / 4900)
			end
		end
		wanted_vel = wanted_vel or vel
		if self._start_run then
			local delta_pos = self._common_data.unit:get_animation_delta_position()
			walk_dis = mvec3_len(delta_pos)
			self._cur_vel = walk_dis / dt
			self._cur_vel = math_min(self._walk_velocity, math_max(walk_dis / dt, self._start_max_vel))
			if self._cur_vel < self._start_max_vel then
				self._cur_vel = self._start_max_vel
				walk_dis = self._cur_vel * dt
			else
				self._start_max_vel = self._cur_vel
			end
		else
			local c_vel = self._cur_vel
			if c_vel ~= wanted_vel then
				local adj = vel * (wanted_vel > c_vel and 1.5 or 4) * dt
				c_vel = math.step(c_vel, wanted_vel, adj)
				self._cur_vel = c_vel
			end
			walk_dis = c_vel * dt
		end
		new_pos, new_c_index, complete = self._walk_spline(c_path, self._last_pos, c_index, walk_dis)
		if complete then
			if self._next_is_nav_link then
				self._end_of_path = true
				if self._sync then
					if alive(self._next_is_nav_link.c_class) and self._next_is_nav_link.element:nav_link_delay() then
						self._next_is_nav_link.c_class:set_delay_time(t + self._next_is_nav_link.element:nav_link_delay())
					else
						debug_pause_unit(self._unit, "dead nav_link", self._unit)
					end
				end
			elseif self._simplified_path_index == #s_path - 1 then
				self._end_of_path = true
			end
		elseif new_c_index ~= self._curve_path_index or nav_advanced then
			local future_pos = c_path[new_c_index + 2]
			local next_pos = c_path[new_c_index + 1]
			local back_pos = c_path[new_c_index]
			local cur_vec = tmp_vec2
			mvec3_set(cur_vec, next_pos)
			mvec3_sub(cur_vec, back_pos)
			mvec3_set_z(cur_vec, 0)
			if future_pos then
				mvec3_norm(cur_vec)
				local next_vec = tmp_vec1
				mvec3_set(next_vec, future_pos)
				mvec3_sub(next_vec, next_pos)
				mvec3_set_z(next_vec, 0)
				mvec3_norm(next_vec)
				local turn_dot = mvec3_dot(cur_vec, next_vec)
				turn_dot = turn_dot * turn_dot
				local dot_lerp = math_max(0, turn_dot)
				local turn_vel = math.lerp(math.min(vel, 100), self._walk_velocity, dot_lerp)
				self._turn_vel = turn_vel
			elseif self._end_of_curved_path and not self._no_walk and self._haste ~= "walk" and not (mvec3_dis(c_path[new_c_index + 1], new_pos) < 120) and not not self._ext_anim.run and vis_state < 3 then
				self._chk_stop_dis = 210
			end
		end
		self._curve_path_index = new_c_index
		self._last_pos = mvec3_cpy(new_pos)
	end
end
function CopActionWalk._walk_spline(path, pos, index, walk_dis)
	while true do
		mvec3_set(tmp_vec1, path[index + 1])
		mvec3_sub(tmp_vec1, path[index])
		mvec3_set_z(tmp_vec1, 0)
		local dis = mvec3_norm(tmp_vec1)
		mvec3_set(tmp_vec2, pos)
		mvec3_sub(tmp_vec2, path[index])
		mvec3_set_z(tmp_vec2, 0)
		local my_dis = mvec3_dot(tmp_vec2, tmp_vec1)
		if dis == 0 or dis <= my_dis + walk_dis and walk_dis >= 0 then
			if index == #path - 1 then
				return path[index + 1], index, true
			else
				index = index + 1
			end
		elseif my_dis + walk_dis < 0 and walk_dis < 0 then
			if index == 1 then
				return path[index], index
			else
				index = index - 1
			end
		else
			local return_vec = Vector3()
			mvec3_lerp(return_vec, path[index], path[index + 1], (walk_dis + my_dis) / dis)
			return return_vec, index
		end
	end
end
function CopActionWalk:_reserve_nav_pos(nav_pos, next_pos, from_pos, vel)
	local step_vec = nav_pos - self._common_data.pos
	local dis = step_vec:length()
	mvector3.cross(step_vec, step_vec, math.UP)
	mvec3_set_l(step_vec, 65)
	local data = {
		start_pos = nav_pos,
		fwd_pos = next_pos,
		bwd_pos = from_pos,
		step_vec = step_vec,
		step_mul = 1,
		nr_attempts = 0
	}
	local step_clbk = callback(self, CopActionWalk, "_rserve_pos_step_clbk", data)
	local eta = dis / vel
	local res_pos = managers.navigation:reserve_pos(TimerManager:game():time() + eta, 1, nav_pos, step_clbk, 40, self._ext_movement:pos_rsrv_id())
	if res_pos then
		mvec3_set(nav_pos, res_pos.position)
		return true
	end
end
function CopActionWalk:_rserve_pos_step_clbk(data, test_pos)
	local nav_manager = managers.navigation
	local step_vec = data.step_vec
	local step_mul = data.step_mul
	mvec3_set(test_pos, step_vec)
	mvec3_mul(test_pos, step_mul)
	mvec3_add(test_pos, data.start_pos)
	local params = {
		pos_from = data.start_pos,
		pos_to = test_pos,
		allow_entry = false
	}
	local blocked = nav_manager:raycast(params)
	if not blocked then
		params.pos_from = test_pos
		params.pos_to = data.fwd_pos
		blocked = nav_manager:raycast(params)
		if not blocked then
			params.pos_to = data.bwd_pos
			blocked = nav_manager:raycast(params)
		end
	end
	if blocked then
		if data.block then
			return false
		end
		data.block = true
		if step_mul > 0 then
			data.step_mul = -step_mul
		else
			data.step_mul = -step_mul + 1
		end
		if data.nr_attempts < 8 then
			data.nr_attempts = data.nr_attempts + 1
			return self:_rserve_pos_step_clbk(data, test_pos)
		else
			return false
		end
	elseif data.block then
		data.step_mul = step_mul + math.sign(step_mul)
	elseif step_mul > 0 then
		data.step_mul = -step_mul
	else
		data.step_mul = -step_mul + 1
	end
	return true
end
function CopActionWalk:_adjust_walk_anim_speed(dt, target_speed)
	local state = self._machine:segment_state(idstr_base)
	self._machine:set_speed(state, target_speed)
end
function CopActionWalk:_adjust_move_anim(side, speed)
	local anim_data = self._ext_anim
	if anim_data[speed] and anim_data["move_" .. side] then
		return
	end
	local redirect_name = speed .. "_" .. side
	local enter_t
	local move_side = anim_data.move_side
	if move_side and (side == move_side or self._matching_walk_anims[side][move_side]) then
		local seg_rel_t = self._machine:segment_relative_time(idstr_base)
		if not self._walk_anim_lengths[anim_data.pose] or not self._walk_anim_lengths[anim_data.pose][speed] or not self._walk_anim_lengths[anim_data.pose][speed][side] then
			debug_pause("Boom...", self._common_data.unit, "pose", anim_data.pose, "speed", speed, "side", side, self._machine:segment_state(Idstring("base")))
			return
		end
		local walk_anim_length = self._walk_anim_lengths[anim_data.pose][speed][side]
		enter_t = seg_rel_t * walk_anim_length
	end
	local could_freeze = anim_data.can_freeze
	local redir_res = self._ext_movement:play_redirect(redirect_name, enter_t)
	if could_freeze then
		self._ext_base:chk_freeze_anims()
	end
	if not redir_res then
		print("CopActionWalk:_adjust_move_anim()", redirect_name, " failed in", self._machine:segment_state(idstr_base), self._machine:segment_state(Idstring("upper_body")))
	end
	return redir_res
end
function CopActionWalk:_start_move_anim(side, speed, speed_mul, turn)
	local redirect_name = speed .. "_start_" .. (turn and "turn_" or "") .. side
	local redir_res = self._ext_movement:play_redirect(redirect_name)
	if not redir_res then
		print("[CopActionWalk:_start_move_anim]", redirect_name, " failed in", self._machine:segment_state(idstr_base), self._machine:segment_state(Idstring("upper_body")))
		return
	end
	self._machine:set_speed(redir_res, speed_mul)
	return redir_res
end
function CopActionWalk:_stop_walk()
	local redir_res = self._ext_movement:play_redirect("idle")
	if not redir_res then
		debug_pause_unit(self._unit, "[CopActionWalk:_stop_walk] redirect failed in", self._machine:segment_state(idstr_base), self._unit)
		return false
	end
	return redir_res
end
function CopActionWalk._apply_freefall(pos, vel, gnd_z, dt)
	local vel_z = vel - dt * 981
	local new_z = pos.z + vel_z * dt
	mvec3_set_z(pos, gnd_z and math_max(gnd_z, new_z) or new_z)
	return vel_z
end
function CopActionWalk:get_walk_to_pos()
	return self._nav_point_pos(self._simplified_path[self._simplified_path_index + 1])
end
function CopActionWalk:_upd_wait(t)
	if self._ext_anim.move then
		self:_stop_walk()
	end
	if not self._end_of_curved_path or not self._persistent then
		self._curve_path_index = 1
		local s_index = math.min(#self._simplified_path - 1, self._simplified_path_index + 1)
		self:_advance_simplified_path(s_index)
		self:_chk_start_anim(CopActionWalk._nav_point_pos(self._simplified_path[self._simplified_path_index + 1]))
		if self._start_run then
			self:_set_updator("_upd_start_anim_first_frame")
		else
			self:_set_updator(nil)
		end
		self._curve_path = {
			self._nav_point_pos(self._simplified_path[s_index]),
			self._nav_point_pos(self._simplified_path[s_index + 1])
		}
		self._cur_vel = 0
	end
end
function CopActionWalk:_upd_stop_anim_first_frame(t)
	local enter_t
	local redir_name = "run_stop_" .. self._stop_anim_side
	local redir_res = self._ext_movement:play_redirect(redir_name, enter_t)
	if not redir_res then
		debug_pause("[CopActionWalk:_upd_stop_anim_first_frame] Redirect", redir_name, "failed in", self._machine:segment_state(idstr_base), self._common_data.unit)
		return
	end
	local speed_mul = self._walk_velocity / self._walk_anim_velocities[self._ext_anim.pose][self._haste][self._stop_anim_side]
	self._machine:set_speed(redir_res, speed_mul)
	self._stop_anim_init_pos = mvec3_cpy(self._last_pos)
	self._stop_anim_end_pos = mvec3_cpy(self._nav_point_pos(self._simplified_path[#self._simplified_path]))
	self._chk_stop_dis = nil
	self:_set_updator("_upd_stop_anim")
	if self._ext_anim.pose ~= "crouch" then
		if self._stop_anim_side == "fwd" then
			function self._stop_anim_displacement_f(p1, p2, t)
				local t_clamp = (math.clamp(t, 0, 0.6) / 0.6) ^ 0.8
				return math.lerp(p1, p2, t_clamp)
			end
		elseif self._stop_anim_side == "bwd" then
			function self._stop_anim_displacement_f(p1, p2, t)
				local low = 0.97
				local p_1_5 = 0.9
				local t_clamp = math.clamp(t, 0, 0.8) / 0.8
				if p_1_5 > t_clamp then
					t_clamp = low * (1 - (p_1_5 - t_clamp) / p_1_5)
				else
					t_clamp = low + (1 - low) * (t_clamp - p_1_5) / (1 - p_1_5)
				end
				return math.lerp(p1, p2, t_clamp)
			end
		elseif self._stop_anim_side == "l" then
			function self._stop_anim_displacement_f(p1, p2, t)
				local p_1_5 = 0.6
				local low = 0.8
				local t_clamp = math.clamp(t, 0, 0.75) / 0.75
				if p_1_5 > t_clamp then
					t_clamp = low * t_clamp / p_1_5
				else
					t_clamp = low + (1 - low) * (t_clamp - p_1_5) / (1 - p_1_5)
				end
				return math.lerp(p1, p2, t_clamp)
			end
		else
			function self._stop_anim_displacement_f(p1, p2, t)
				local low = 0.9
				local p_1_5 = 0.85
				local t_clamp = math.clamp(t, 0, 0.8) / 0.8
				if p_1_5 > t_clamp then
					t_clamp = low * (1 - (p_1_5 - t_clamp) / p_1_5)
				else
					t_clamp = low + (1 - low) * (t_clamp - p_1_5) / (1 - p_1_5)
				end
				return math.lerp(p1, p2, t_clamp)
			end
		end
	elseif self._stop_anim_side == "fwd" then
		function self._stop_anim_displacement_f(p1, p2, t)
			local t_clamp = math.clamp(t, 0, 0.7) / 0.7
			t_clamp = t_clamp ^ 0.85
			return math.lerp(p1, p2, t_clamp)
		end
	elseif self._stop_anim_side == "bwd" then
		function self._stop_anim_displacement_f(p1, p2, t)
			local low = 0.97
			local p_1_5 = 0.9
			local t_clamp = t
			return math.lerp(p1, p2, t_clamp)
		end
	elseif self._stop_anim_side == "l" then
		function self._stop_anim_displacement_f(p1, p2, t)
			local p_1_5 = 0.6
			local low = 0.8
			local t_clamp = math.clamp(t, 0, 0.75) / 0.75
			if p_1_5 > t_clamp then
				t_clamp = low * t_clamp / p_1_5
			else
				t_clamp = low + (1 - low) * (t_clamp - p_1_5) / (1 - p_1_5)
			end
			return math.lerp(p1, p2, t_clamp)
		end
	else
		function self._stop_anim_displacement_f(p1, p2, t)
			local low = 0.9
			local p_1_5 = 0.85
			local t_clamp = math.clamp(t, 0, 0.75) / 0.75
			if p_1_5 > t_clamp then
				t_clamp = low * (1 - (p_1_5 - t_clamp) / p_1_5)
			else
				t_clamp = low + (1 - low) * (t_clamp - p_1_5) / (1 - p_1_5)
			end
			return math.lerp(p1, p2, t_clamp)
		end
	end
	self._ext_base:chk_freeze_anims()
	self:update(t)
end
function CopActionWalk:_upd_stop_anim(t)
	local dt = TimerManager:game():delta_time()
	local rot_new = self._common_data.rot:slerp(Rotation(self._stop_anim_fwd, math.UP), math.min(1, dt * 5))
	self._ext_movement:set_rotation(rot_new)
	if not self._ext_anim.run_stop then
		if self._simplified_path_index < #self._simplified_path - 1 or self._next_is_nav_link then
			self:_set_updator(nil)
		elseif self._persistent then
			self:_set_updator("_upd_wait")
		else
			self._expired = true
			if self._end_rot then
				self._ext_movement:set_rotation(self._end_rot)
			end
		end
		self._last_pos = mvec3_cpy(self._stop_anim_end_pos)
		self._stop_anim_displacement_f = nil
		self._stop_anim_end_pos = nil
		self._stop_anim_fwd = nil
		self._stop_anim_init_pos = nil
		self._stop_anim_side = nil
		self._stop_dis = nil
	else
		local seg_rel_t = self._machine:segment_relative_time(idstr_base)
		self._last_pos = self._stop_anim_displacement_f(self._stop_anim_init_pos, self._stop_anim_end_pos, seg_rel_t)
	end
	self:_set_new_pos(dt)
end
function CopActionWalk:stop(pos)
	local s_path = self._simplified_path
	if not s_path[#s_path].x then
		s_path[#s_path] = self._nav_point_pos(s_path[#s_path])
	end
	table.insert(s_path, pos)
	self._persistent = false
	if self.update == self._upd_wait then
		self._end_of_curved_path = nil
		self._end_of_path = nil
	elseif not self._next_is_nav_link then
		self._end_of_curved_path = nil
	end
	if self.update ~= self._upd_nav_link and self.update ~= self._upd_nav_link_first_frame and self.update ~= self._upd_nav_link_blend_to_idle then
		local ray_params = {
			tracker_from = self._common_data.nav_tracker,
			pos_to = pos
		}
		if not managers.navigation:raycast(ray_params) then
			self._next_is_nav_link = nil
			self._end_of_curved_path = nil
			self._end_of_path = nil
			self._curve_path_index = 1
			local stop_pos = mvector3.copy(pos)
			self._curve_path = {
				mvector3.copy(self._common_data.pos),
				stop_pos
			}
			local i = self._simplified_path_index + 1
			while i < #s_path do
				table.remove(s_path, i)
			end
		end
	end
end
function CopActionWalk:append_nav_point(nav_point)
	if not nav_point.x then
		function nav_point.element.value(element, name)
			return element[name]
		end
		function nav_point.element.nav_link_wants_align_pos(element)
			return element.from_idle
		end
	end
	table.insert(self._simplified_path, nav_point)
	if self.update == self._upd_wait then
		self._end_of_curved_path = nil
		self._end_of_path = nil
	elseif not self._next_is_nav_link then
		self._end_of_curved_path = nil
	end
	self:_advance_simplified_path(self._simplified_path_index)
end
function CopActionWalk:chk_block(action_type, t)
	return CopActionAct.chk_block(self, action_type, t)
end
function CopActionWalk:chk_block_client(action_desc, action_type, t)
	if CopActionAct.chk_block(self, action_type, t) and (not action_desc or action_desc.body_part ~= 3) then
		return true
	end
end
function CopActionWalk:set_blocks(preset_name, state)
	if state then
		if not self._old_blocks then
			self._old_blocks = self._blocks
		end
		self:_set_blocks(self._anim_block_presets[preset_name])
	elseif self._old_blocks then
		self:_set_blocks(self._old_blocks)
		self._old_blocks = nil
	end
	if self._blocks.action then
		self._ext_movement:action_request({
			type = "idle",
			body_part = 3,
			client_interrupt = true,
			non_persistent = true
		})
	end
end
function CopActionWalk:_set_blocks(blocks)
	self._blocks = blocks
end
function CopActionWalk:need_upd()
	return true
end
function CopActionWalk:_upd_nav_link_first_frame(t)
	if self._next_is_nav_link.element:nav_link_wants_align_pos() and self:_stop_walk() then
		self:_set_updator("_upd_nav_link_blend_to_idle")
		return
	end
	self:_play_nav_link_anim(t)
end
function CopActionWalk:_upd_nav_link_blend_to_idle(t)
	if self._ext_anim.idle and not self._ext_anim.idle_full_blend then
		return
	end
	self:_play_nav_link_anim(t)
end
function CopActionWalk:_play_nav_link_anim(t)
	self._old_blocks = self._blocks
	self:_set_blocks(self._anim_block_presets.block_all)
	if self._nav_link_invul and not self._nav_link_invul_on then
		self._common_data.ext_damage:set_invulnerable(true)
		self._nav_link_invul_on = true
	end
	local nav_link = self._next_is_nav_link
	local anim = nav_link.element:value("so_action")
	self._ext_movement:set_rotation(nav_link.element:value("rotation"))
	self._last_pos = mvector3.copy(nav_link.element:value("position"))
	self:_set_new_pos(TimerManager:game():delta_time())
	self._nav_link = self._next_is_nav_link
	self._next_is_nav_link = nil
	self._end_of_curved_path = nil
	self._end_of_path = nil
	self._curve_path_end_rot = nil
	self._nav_link_rot = nil
	local s_index = self._simplified_path_index + 1
	self:_advance_simplified_path(s_index)
	if self._sync then
		self:_send_nav_point(self._simplified_path[s_index + 1])
	end
	local result = self._ext_movement:play_redirect(anim)
	if result then
		self:_set_updator("_upd_nav_link")
		self._common_data.unit:set_driving("animation")
		self._changed_driving = true
		if self._blocks == self._anim_block_presets.block_all then
			self._ext_movement:action_request({
				type = "idle",
				body_part = 3,
				client_interrupt = true,
				non_persistent = true
			})
		end
	else
		debug_pause("[CopActionWalk:_upd_nav_link_first_frame] redirect", anim, "failed in", self._machine:segment_state(idstr_base), self._common_data.unit)
		if mvec3_dis(self._common_data.pos, self._nav_point_pos(self._simplified_path[s_index + 1])) > 400 and self._ext_base:lod_stage() == 1 then
			self._curve_path = self:_calculate_curved_path(self._simplified_path, s_index, 1, self._common_data.fwd)
		else
			self._curve_path = {
				self._common_data.pos,
				self._nav_point_pos(self._simplified_path[s_index + 1])
			}
		end
		self._curve_path_index = 1
		if self._nav_link_invul_on then
			self._nav_link_invul_on = nil
			self._common_data.ext_damage:set_invulnerable(false)
		end
		self._cur_vel = 0
		self:_set_blocks(self._old_blocks)
		self._old_blocks = nil
		self:_set_updator(nil)
		self:update(t)
	end
end
function CopActionWalk:_upd_nav_link(t)
	if self._ext_anim.act then
		self._last_pos = self._unit:position()
		self._ext_movement:set_m_pos(self._last_pos)
		self._ext_movement:set_m_rot(self._unit:rotation())
	elseif self._simplified_path[self._simplified_path_index + 1] then
		self._common_data.unit:set_driving("script")
		self._changed_driving = nil
		local s_index = self._simplified_path_index
		self._simplified_path[s_index] = mvec3_cpy(self._common_data.pos)
		if self._sync then
			local ray_params = {
				tracker_from = self._common_data.nav_tracker,
				pos_to = self._nav_point_pos(self._simplified_path[s_index + 1])
			}
			local res = managers.navigation:raycast(ray_params)
			if res then
				local end_pos = self._nav_link.c_class:end_position()
				table.insert(self._simplified_path, s_index + 1, end_pos)
				self._next_is_nav_link = nil
				self:_send_nav_point(self._simplified_path[s_index + 1])
			end
		end
		if mvec3_dis(self._common_data.pos, self._nav_point_pos(self._simplified_path[s_index + 1])) > 400 and self._ext_base:lod_stage() == 1 then
			self._curve_path = self:_calculate_curved_path(self._simplified_path, s_index, 1, self._common_data.fwd)
		else
			self._curve_path = {
				mvec3_cpy(self._common_data.pos),
				self._nav_point_pos(self._simplified_path[s_index + 1])
			}
		end
		self._curve_path_index = 1
		if self._nav_link_invul_on then
			self._nav_link_invul_on = nil
			self._common_data.ext_damage:set_invulnerable(false)
		end
		self._nav_link = nil
		self._cur_vel = 0
		self._last_vel_z = 0
		self:_set_blocks(self._old_blocks)
		self._old_blocks = nil
		self:_set_updator(nil)
		self:update(t)
	elseif not self._persistent then
		self._common_data.unit:set_driving("script")
		self._changed_driving = nil
		self._end_of_curved_path = true
		if self._nav_link_invul_on then
			self._nav_link_invul_on = nil
			self._common_data.ext_damage:set_invulnerable(false)
		end
		self._cur_vel = 0
		self._last_vel_z = 0
		self:_set_blocks(self._old_blocks)
		self._old_blocks = nil
		self:_set_updator("_upd_wait")
	end
end
function CopActionWalk._nav_point_pos(nav_point)
	return nav_point.x and nav_point or nav_point.element:value("position")
end
function CopActionWalk:_send_nav_point(nav_point)
	if nav_point.x then
		self._ext_network:send("action_walk_nav_point", nav_point)
	else
		local element = nav_point.element
		local anim_index = CopActionAct._get_act_index(CopActionAct, element:value("so_action"))
		local sync_yaw = element:value("rotation"):yaw()
		if sync_yaw < 0 then
			sync_yaw = 360 + sync_yaw
		end
		sync_yaw = math.ceil(255 * sync_yaw / 360)
		if sync_yaw == 0 then
			sync_yaw = 255
		end
		self._ext_network:send("action_walk_nav_link", element:value("position"), sync_yaw, anim_index, element:nav_link_wants_align_pos() and true or false)
	end
end
function CopActionWalk:_set_updator(name)
	self.update = self[name]
	if not name then
		self._last_upd_t = TimerManager:game():time() - 0.001
	end
end
function CopActionWalk:on_nav_link_unregistered(element_id)
	if self._next_is_nav_link and self._next_is_nav_link.element._id == element_id then
		self._ext_movement:action_request({type = "idle", body_part = 2})
		return
	end
	for i, nav_point in ipairs(self._simplified_path) do
		if not nav_point.x and nav_point.element._id == element_id then
			self._ext_movement:action_request({type = "idle", body_part = 2})
			return
		end
	end
end
function CopActionWalk:anim_act_clbk(anim_act)
	if not self._sync then
		return
	end
	local nav_point = self._simplified_path[self._simplified_path_index]
	if not nav_point.x then
		nav_point.element:event(anim_act, self._unit)
		return
	end
end
function CopActionWalk:_advance_simplified_path(nav_index)
	self._simplified_path_index = nav_index
	if self._simplified_path[nav_index + 1] and not self._simplified_path[nav_index + 1].x then
		self._next_is_nav_link = self._simplified_path[nav_index + 1]
	end
end
function CopActionWalk:_husk_needs_speedup()
	if next(self._ext_movement._queued_actions) then
		return true
	elseif #self._simplified_path > self._simplified_path_index + 1 then
		local sz_path = #self._simplified_path
		local prev_pos = self._common_data.pos
		local i = self._simplified_path_index + 1
		local dis_error_total = 0
		while sz_path >= i do
			local next_pos = self._nav_point_pos(self._simplified_path[i])
			dis_error_total = dis_error_total + mvec3_dis_sq(prev_pos, next_pos)
			prev_pos = next_pos
			i = i + 1
		end
		if dis_error_total > 90000 then
			return true
		end
	end
end
