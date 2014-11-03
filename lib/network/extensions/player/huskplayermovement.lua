local mvec3_set = mvector3.set
local mvec3_sub = mvector3.subtract
local mvec3_add = mvector3.add
local mvec3_mul = mvector3.multiply
local mvec3_norm = mvector3.normalize
local temp_vec1 = Vector3()
local temp_vec2 = Vector3()
HuskPlayerMovement = HuskPlayerMovement or class()
HuskPlayerMovement._walk_anim_velocities = {
	stand = {
		walk = {
			fwd = 300,
			bwd = 150,
			l = 137,
			r = 159
		},
		run = {
			fwd = 497,
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
	}
}
HuskPlayerMovement._walk_anim_lengths = {
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
		}
	}
}
for pose, speeds in pairs(HuskPlayerMovement._walk_anim_lengths) do
	for speed, sides in pairs(speeds) do
		for side, speed in pairs(sides) do
			sides[side] = speed * 0.03333
		end
	end
end
HuskPlayerMovement._matching_walk_anims = {
	fwd = {bwd = true},
	bwd = {fwd = true},
	l = {r = true},
	r = {l = true}
}
HuskPlayerMovement._char_name_to_index = {
	russian = 1,
	german = 2,
	american = 3,
	spanish = 4
}
HuskPlayerMovement._char_model_names = {
	russian = "g_russian",
	german = "g_body",
	american = "g_american",
	spanish = "g_spaniard"
}
HuskPlayerMovement._stance_names = {
	"ntl",
	"hos",
	"cbt"
}
HuskPlayerMovement._look_modifier_name = Idstring("action_upper_body")
HuskPlayerMovement._head_modifier_name = Idstring("look_head")
HuskPlayerMovement._arm_modifier_name = Idstring("aim_r_arm")
HuskPlayerMovement._mask_off_modifier_name = Idstring("look_mask_off")
function HuskPlayerMovement:init(unit)
	self._unit = unit
	self._machine = unit:anim_state_machine()
	self._m_pos = unit:position()
	self._m_rot = unit:rotation()
	self._look_dir = self._m_rot:y()
	self._sync_look_dir = nil
	self._look_ang_vel = 0
	self._move_data = nil
	self._sync_pos = nil
	self._nav_tracker = nil
	self._look_modifier = self._machine:get_modifier(self._look_modifier_name)
	self._head_modifier = self._machine:get_modifier(self._head_modifier_name)
	self._arm_modifier = self._machine:get_modifier(self._arm_modifier_name)
	self._mask_off_modifier = self._machine:get_modifier(self._mask_off_modifier_name)
	self._aim_up_expire_t = nil
	local stance = {}
	self._stance = stance
	stance.names = self._stance_names
	stance.values = {
		1,
		0,
		0
	}
	stance.blend = {
		0.8,
		0.5,
		0.3
	}
	self._m_stand_pos = mvector3.copy(self._m_pos)
	mvector3.set_z(self._m_stand_pos, self._m_pos.z + 140)
	self._m_com = math.lerp(self._m_pos, self._m_stand_pos, 0.5)
	self._obj_head = unit:get_object(Idstring("Head"))
	self._obj_spine = unit:get_object(Idstring("Spine1"))
	self._m_head_rot = Rotation(self._look_dir, math.UP)
	self._m_head_pos = self._obj_head:position()
	self._m_detect_pos = mvector3.copy(self._m_head_pos)
	self._footstep_style = nil
	self._footstep_event = ""
	self._state = "mask_off"
	self._pose_code = 1
	self._tase_effect_table = {
		effect = Idstring("effects/particles/weapons/taser_effect"),
		parent = self._unit:get_object(Idstring("e_taser"))
	}
	self._sequenced_events = {}
end
function HuskPlayerMovement:post_init()
	self._ext_anim = self._unit:anim_data()
	self._unit:inventory():add_listener("HuskPlayerMovement", {"equip"}, callback(self, self, "clbk_inventory_event"))
	if managers.navigation:is_data_ready() then
		self._nav_tracker = managers.navigation:create_nav_tracker(self._unit:position())
		self._standing_nav_seg_id = self._nav_tracker:nav_segment()
	end
	self._unit:inventory():synch_equipped_weapon(2)
end
function HuskPlayerMovement:set_character_anim_variables()
	local char_name = managers.criminals:character_name_by_unit(self._unit)
	if not char_name then
		return
	end
	local mesh_name = self._char_model_names[char_name] .. (managers.player._player_mesh_suffix or "")
	local mesh_obj = self._unit:get_object(Idstring(mesh_name))
	if mesh_obj then
		self._unit:get_object(Idstring(self._plr_mesh_name or self._char_model_names.german)):set_visibility(false)
		local char_index = self._char_name_to_index[char_name]
		self._machine:set_global("husk" .. tostring(char_index), 1)
		mesh_obj:set_visibility(true)
		self._plr_mesh_name = mesh_name
	end
end
function HuskPlayerMovement:update(unit, t, dt)
	self:_calculate_m_pose()
	self:_upd_sequenced_events(t, dt)
	if self._attention_updator then
		self._attention_updator(dt)
	end
	if not self._movement_updator and self._move_data and (self._state == "standard" or self._state == "mask_off" or self._state == "clean") then
		self._movement_updator = callback(self, self, "_upd_move_standard")
	end
	if self._movement_updator then
		self._movement_updator(t, dt)
	end
	self:_update_stance(t)
end
function HuskPlayerMovement:enable_update()
end
function HuskPlayerMovement:sync_look_dir(fwd)
	mvector3.normalize(fwd)
	self._sync_look_dir = fwd
end
function HuskPlayerMovement:set_look_dir_instant(fwd)
	self._look_dir = fwd
	self._look_modifier:set_target_y(self._look_dir)
	self._sync_look_dir = nil
end
function HuskPlayerMovement:m_pos()
	return self._m_pos
end
function HuskPlayerMovement:m_stand_pos()
	return self._m_stand_pos
end
function HuskPlayerMovement:m_com()
	return self._m_com
end
function HuskPlayerMovement:m_head_rot()
	return self._m_head_rot
end
function HuskPlayerMovement:m_head_pos()
	return self._m_head_pos
end
function HuskPlayerMovement:m_detect_pos()
	return self._m_detect_pos
end
function HuskPlayerMovement:m_rot()
	return self._m_rot
end
function HuskPlayerMovement:detect_look_dir()
	return self._sync_look_dir or self._look_dir
end
function HuskPlayerMovement:look_dir()
	return self._look_dir
end
function HuskPlayerMovement:_calculate_m_pose()
	mrotation.set_look_at(self._m_head_rot, self._look_dir, math.UP)
	mvector3.set(self._m_head_pos, self._obj_head:position())
	self._obj_spine:m_position(self._m_com)
	local det_pos = self._m_detect_pos
	if self._move_data then
		local path = self._move_data.path
		mvector3.set(det_pos, path[#path])
		mvector3.set_z(det_pos, det_pos.z + self._m_head_pos.z - self._m_pos.z)
	else
		mvector3.set(det_pos, self._m_head_pos)
	end
end
function HuskPlayerMovement:set_position(pos)
	mvector3.set(self._m_pos, pos)
	self._unit:set_position(pos)
	if self._nav_tracker then
		self._nav_tracker:move(pos)
		local nav_seg_id = self._nav_tracker:nav_segment()
		if self._standing_nav_seg_id ~= nav_seg_id then
			self._standing_nav_seg_id = nav_seg_id
			local location_id = managers.navigation:location_id(nav_seg_id)
			managers.hud:set_mugshot_location(self._unit:unit_data().mugshot_id, location_id)
		end
	end
end
function HuskPlayerMovement:get_location_id()
	return self._standing_nav_seg_id and managers.navigation:location_id(self._standing_nav_seg_id) or nil
end
function HuskPlayerMovement:set_rotation(rot)
	mrotation.set_yaw_pitch_roll(self._m_rot, rot:yaw(), 0, 0)
	self._unit:set_rotation(rot)
end
function HuskPlayerMovement:nav_tracker()
	return self._nav_tracker
end
function HuskPlayerMovement:play_redirect(redirect_name, at_time)
	local result = self._unit:play_redirect(Idstring(redirect_name), at_time)
	result = result ~= Idstring("") and result
	if result then
		return result
	end
	print("[HuskPlayerMovement:play_redirect] redirect", redirect_name, "failed in", self._machine:segment_state(Idstring("base")), self._machine:segment_state(Idstring("upper_body")))
	Application:stack_dump()
end
function HuskPlayerMovement:play_redirect_idstr(redirect_name, at_time)
	local result = self._unit:play_redirect(redirect_name, at_time)
	result = result ~= Idstring("") and result
	if result then
		return result
	end
	print("[HuskPlayerMovement:play_redirect_idstr] redirect", redirect_name, "failed in", self._machine:segment_state(Idstring("base")), self._machine:segment_state(Idstring("upper_body")))
	Application:stack_dump()
end
function HuskPlayerMovement:play_state(state_name, at_time)
	local result = self._unit:play_state(Idstring(state_name), at_time)
	result = result ~= Idstring("") and result
	if result then
		return result
	end
	print("[HuskPlayerMovement:play_state] state", state_name, "failed in", self._machine:segment_state(Idstring("base")), self._machine:segment_state(Idstring("upper_body")))
	Application:stack_dump()
end
function HuskPlayerMovement:play_state_idstr(state_name, at_time)
	local result = self._unit:play_state(state_name, at_time)
	result = result ~= Idstring("") and result
	if result then
		return result
	end
	print("[HuskPlayerMovement:play_state_idstr] state", state_name, "failed in", self._machine:segment_state(Idstring("base")), self._machine:segment_state(Idstring("upper_body")))
	Application:stack_dump()
end
function HuskPlayerMovement:set_need_revive(need_revive, down_time)
	if self._need_revive == need_revive then
		return
	end
	self._unit:character_damage():set_last_down_time(down_time)
	self._need_revive = need_revive
	self._unit:interaction():set_active(need_revive, false, down_time)
	if Network:is_server() then
		if need_revive and not self._revive_SO_id and not self._revive_rescuer then
			self:_register_revive_SO()
		elseif not need_revive and (self._revive_SO_id or self._revive_rescuer or self._deathguard_SO_id) then
			self:_unregister_revive_SO()
		end
	end
end
function HuskPlayerMovement:_register_revive_SO()
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
	local objective = {
		type = "revive",
		follow_unit = self._unit,
		called = true,
		destroy_clbk_key = false,
		nav_seg = self._unit:movement():nav_tracker():nav_segment(),
		fail_clbk = callback(self, self, "on_revive_SO_failed"),
		complete_clbk = callback(self, self, "on_revive_SO_completed"),
		scan = true,
		action = {
			type = "act",
			variant = self._state == "arrested" and "untie" or "revive",
			body_part = 1,
			blocks = {
				action = -1,
				walk = -1,
				light_hurt = -1,
				hurt = -1,
				heavy_hurt = -1,
				aim = -1
			},
			align_sync = true
		},
		interact_delay = tweak_data.interaction[self._state == "arrested" and "free" or "revive"].timer,
		followup_objective = followup_objective
	}
	local so_descriptor = {
		objective = objective,
		base_chance = 1,
		chance_inc = 0,
		interval = 6,
		search_dis = 100000,
		search_pos = self._unit:position(),
		usage_amount = 1,
		AI_group = "friendlies",
		admin_clbk = callback(self, self, "on_revive_SO_administered")
	}
	local so_id = "PlayerHusk_revive" .. tostring(self._unit:key())
	self._revive_SO_id = so_id
	managers.groupai:state():add_special_objective(so_id, so_descriptor)
	if not self._deathguard_SO_id then
		self._deathguard_SO_id = PlayerBleedOut._register_deathguard_SO(self._unit)
	end
end
function HuskPlayerMovement:_unregister_revive_SO()
	if self._deathguard_SO_id then
		PlayerBleedOut._unregister_deathguard_SO(self._deathguard_SO_id)
		self._deathguard_SO_id = nil
	end
	if self._revive_rescuer then
		local rescuer = self._revive_rescuer
		self._revive_rescuer = nil
		rescuer:brain():set_objective(nil)
	elseif self._revive_SO_id then
		managers.groupai:state():remove_special_objective(self._revive_SO_id)
		self._revive_SO_id = nil
	end
end
function HuskPlayerMovement:set_need_assistance(need_assistance)
	if self._need_assistance == need_assistance then
		return
	end
	self._need_assistance = need_assistance
	if Network:is_server() then
		if need_assistance and not self._assist_SO_id then
			local objective = {
				type = "follow",
				follow_unit = self._unit,
				called = true,
				destroy_clbk_key = false,
				scan = true,
				nav_seg = self._unit:movement():nav_tracker():nav_segment()
			}
			local so_descriptor = {
				objective = objective,
				base_chance = 1,
				chance_inc = 0,
				interval = 6,
				search_dis = 5000,
				search_pos = self._unit:position(),
				usage_amount = 1,
				AI_group = "friendlies"
			}
			local so_id = "PlayerHusk_assistance" .. tostring(self._unit:key())
			self._assist_SO_id = so_id
			managers.groupai:state():add_special_objective(so_id, so_descriptor)
		elseif not need_assistance and self._assist_SO_id then
			managers.groupai:state():remove_special_objective(self._assist_SO_id)
			self._assist_SO_id = nil
		end
	end
end
function HuskPlayerMovement:on_revive_SO_administered(receiver_unit)
	if self._revive_SO_id then
		self._revive_rescuer = receiver_unit
		self._revive_SO_id = nil
	end
end
function HuskPlayerMovement:on_revive_SO_failed(rescuer)
	if self._revive_rescuer then
		self._revive_rescuer = nil
		self:_register_revive_SO()
	end
end
function HuskPlayerMovement:on_revive_SO_completed(rescuer)
	self._revive_rescuer = nil
end
function HuskPlayerMovement:need_revive()
	return self._need_revive
end
function HuskPlayerMovement:downed()
	return self._need_revive or self._need_assistance
end
function HuskPlayerMovement:_upd_attention_mask_off(dt)
	if not self._atention_on then
		self._atention_on = true
		self._machine:force_modifier(self._mask_off_modifier_name)
	end
	if self._sync_look_dir then
		local arror_angle = self._sync_look_dir:angle(self._look_dir)
		local rot_speed_rel = math.pow(math.min(arror_angle / 90, 1), 0.5)
		local rot_speed = math.lerp(40, 360, rot_speed_rel)
		local rot_amount = math.min(rot_speed * dt, arror_angle)
		local error_axis = self._look_dir:cross(self._sync_look_dir)
		local rot_adj = Rotation(error_axis, rot_amount)
		self._look_dir = self._look_dir:rotate_with(rot_adj)
		self._mask_off_modifier:set_target_z(self._look_dir)
		if rot_amount == arror_angle then
			self._sync_look_dir = nil
		end
	end
end
function HuskPlayerMovement:_upd_attention_standard(dt)
	if not self._atention_on then
		if self._ext_anim.bleedout then
			if self._sync_look_dir and self._sync_look_dir ~= self._look_dir then
				self._look_dir = mvector3.copy(self._sync_look_dir)
			end
			return
		else
			self._atention_on = true
			self._machine:force_modifier(self._look_modifier_name)
		end
	end
	if self._sync_look_dir then
		local arror_angle = self._sync_look_dir:angle(self._look_dir)
		local rot_speed_rel = math.pow(math.min(arror_angle / 90, 1), 0.5)
		local rot_speed = math.lerp(40, 360, rot_speed_rel)
		local rot_amount = math.min(rot_speed * dt, arror_angle)
		local error_axis = self._look_dir:cross(self._sync_look_dir)
		local rot_adj = Rotation(error_axis, rot_amount)
		self._look_dir = self._look_dir:rotate_with(rot_adj)
		self._look_modifier:set_target_y(self._look_dir)
		if rot_amount == arror_angle then
			self._sync_look_dir = nil
		end
	end
end
function HuskPlayerMovement:_upd_attention_bleedout(dt)
	if self._sync_look_dir then
		local fwd = self._m_rot:y()
		if self._atention_on then
			if self._ext_anim.reload then
				self._atention_on = false
				local blend_out_t = 0.15
				self._machine:set_modifier_blend(self._head_modifier_name, blend_out_t)
				self._machine:set_modifier_blend(self._arm_modifier_name, blend_out_t)
				self._machine:forbid_modifier(self._head_modifier_name)
				self._machine:forbid_modifier(self._arm_modifier_name)
			end
		elseif self._ext_anim.bleedout_falling or self._ext_anim.reload then
			if self._sync_look_dir ~= self._look_dir then
				self._look_dir = mvector3.copy(self._sync_look_dir)
			end
			return
		else
			self._atention_on = true
			self._machine:force_modifier(self._head_modifier_name)
			self._machine:force_modifier(self._arm_modifier_name)
		end
		local arror_angle = self._sync_look_dir:angle(self._look_dir)
		local rot_speed_rel = math.pow(math.min(arror_angle / 90, 1), 0.5)
		local rot_speed = math.lerp(40, 360, rot_speed_rel)
		local rot_amount = math.min(rot_speed * dt, arror_angle)
		local error_axis = self._look_dir:cross(self._sync_look_dir)
		local rot_adj = Rotation(error_axis, rot_amount)
		self._look_dir = self._look_dir:rotate_with(rot_adj)
		self._arm_modifier:set_target_y(self._look_dir)
		self._head_modifier:set_target_z(self._look_dir)
		local aim_polar = self._look_dir:to_polar_with_reference(fwd, math.UP)
		local aim_spin = aim_polar.spin
		local anim = self._machine:segment_state(Idstring("base"))
		local fwd = 1 - math.clamp(math.abs(aim_spin / 90), 0, 1)
		self._machine:set_parameter(anim, "angle0", fwd)
		local bwd = math.clamp(math.abs(aim_spin / 90), 1, 2) - 1
		self._machine:set_parameter(anim, "angle180", bwd)
		local l = 1 - math.clamp(math.abs(aim_spin / 90 - 1), 0, 1)
		self._machine:set_parameter(anim, "angle90neg", l)
		local r = 1 - math.clamp(math.abs(aim_spin / 90 + 1), 0, 1)
		self._machine:set_parameter(anim, "angle90", r)
		if rot_amount == arror_angle then
			self._sync_look_dir = nil
		end
	end
end
function HuskPlayerMovement:_upd_attention_tased(dt)
end
function HuskPlayerMovement:_upd_attention_disarmed(dt)
end
function HuskPlayerMovement:_upd_sequenced_events(t, dt)
	local sequenced_events = self._sequenced_events
	local next_event = sequenced_events[1]
	if not next_event then
		return
	end
	if next_event.commencing then
		return
	end
	if self._tase_effect then
		World:effect_manager():fade_kill(self._tase_effect)
	end
	local event_type = next_event.type
	if event_type == "move" then
		next_event.commencing = true
		self:_start_movement(next_event.path)
	elseif event_type == "bleedout" then
		if self:_start_bleedout(next_event) then
			table.remove(sequenced_events, 1)
		end
	elseif event_type == "fatal" then
		if self:_start_fatal(next_event) then
			table.remove(sequenced_events, 1)
		end
	elseif event_type == "incapacitated" then
		if self:_start_incapacitated(next_event) then
			table.remove(sequenced_events, 1)
		end
	elseif event_type == "tased" then
		if self:_start_tased(next_event) then
			table.remove(sequenced_events, 1)
		end
	elseif event_type == "standard" then
		if self:_start_standard(next_event) then
			table.remove(sequenced_events, 1)
		end
	elseif event_type == "dead" then
		if self:_start_dead(next_event) then
			table.remove(sequenced_events, 1)
		end
	elseif event_type == "arrested" and self:_start_arrested(next_event) then
		table.remove(sequenced_events, 1)
	end
end
function HuskPlayerMovement:_add_sequenced_event(event_desc)
	table.insert(self._sequenced_events, event_desc)
end
function HuskPlayerMovement:_update_stance(t)
	if self._aim_up_expire_t and t > self._aim_up_expire_t then
		self._aim_up_expire_t = nil
		local new_stance_code = (self._state == "mask_off" or self._state == "clean") and 1 or 2
		self:_change_stance(new_stance_code)
	end
	local stance = self._stance
	if stance.transition then
		local transition = stance.transition
		if t > transition.next_upd_t then
			transition.next_upd_t = t + 0.033
			local values = stance.values
			local prog = (t - transition.start_t) / transition.duration
			if prog < 1 then
				local prog_smooth = math.clamp(math.bezier({
					0,
					0,
					1,
					1
				}, prog), 0, 1)
				local v_start = transition.start_values
				local v_end = transition.end_values
				local mlerp = math.lerp
				for i, v in ipairs(v_start) do
					values[i] = mlerp(v, v_end[i], prog_smooth)
				end
			else
				for i, v in ipairs(transition.end_values) do
					values[i] = v
				end
				if transition.delayed_shot then
					self:_shoot_blank(transition.delayed_shot.impact)
				end
				stance.transition = nil
			end
			local names = stance.names
			for i, v in ipairs(values) do
				self._machine:set_global(names[i], values[i])
			end
		end
	end
end
function HuskPlayerMovement:_upd_slow_pos_reservation(t, dt)
	local slow_dist = 100
	mvec3_set(temp_vec2, self._pos_reservation_slow.position)
	mvec3_sub(temp_vec2, self._pos_reservation.position)
	if slow_dist < mvec3_norm(temp_vec2) then
		mvec3_mul(temp_vec2, slow_dist)
		mvec3_add(temp_vec2, self._pos_reservation.position)
		mvec3_set(self._pos_reservation_slow.position, temp_vec2)
		managers.navigation:move_pos_rsrv(self._pos_reservation)
	end
end
function HuskPlayerMovement:_upd_move_downed(t, dt)
	if self._move_data then
		local data = self._move_data
		local path = data.path
		local end_pos = path[#path]
		local cur_pos = self._m_pos
		local new_pos = temp_vec1
		local displacement = 300 * dt
		local dis = mvector3.distance(cur_pos, end_pos)
		if displacement > dis then
			self._move_data = nil
			table.remove(self._sequenced_events, 1)
			mvector3.set(new_pos, end_pos)
		else
			mvector3.step(new_pos, cur_pos, end_pos, displacement)
		end
		self:set_position(new_pos)
	end
end
function HuskPlayerMovement:_upd_move_standard(t, dt)
	local look_dir_flat = self._look_dir:with_z(0)
	mvector3.normalize(look_dir_flat)
	local leg_fwd_cur = self._m_rot:y()
	local waist_twist = look_dir_flat:to_polar_with_reference(leg_fwd_cur, math.UP).spin
	local abs_waist_twist = math.abs(waist_twist)
	if self._ext_anim.bleedout_enter or self._ext_anim.bleedout_exit or self._ext_anim.fatal_enter or self._ext_anim.fatal_exit then
		return
	end
	if self._pose_code == 1 then
		if not self._ext_anim.stand then
			self:play_redirect("stand")
		end
	elseif not self._ext_anim.crouch then
		self:play_redirect("crouch")
	end
	if self._move_data then
		local data = self._move_data
		local new_pos
		local path_len_remaining = data.path_len - data.dis_in_seg
		local wanted_str8_vel, max_velocity
		if data.path_len > 300 then
			max_velocity = tweak_data.player.movement_state.standard.movement.speed.RUNNING_MAX * 1.3
			wanted_str8_vel = max_velocity
		else
			max_velocity = 500
			local min_velocity = 120
			local max_dis = 300
			local min_dis = 50
			local dis_lerp = math.clamp((path_len_remaining - min_dis) / (max_dis - min_dis), 0, 1)
			wanted_str8_vel = math.lerp(min_velocity, max_velocity, dis_lerp)
		end
		local max_acc = max_velocity * 1.5
		local velocity
		if wanted_str8_vel < data.velocity_len then
			data.velocity_len = math.clamp(data.velocity_len - dt * max_acc, wanted_str8_vel, max_velocity)
		else
			data.velocity_len = math.clamp(data.velocity_len + dt * max_acc, 0, wanted_str8_vel)
		end
		local wanted_travel_dis = data.velocity_len * dt
		local total_travel_dis = wanted_travel_dis + data.dis_in_seg
		while true do
			if total_travel_dis > data.seg_dis then
				if #data.path == 2 then
					new_pos = data.path[2]
					self._move_data = nil
					table.remove(self._sequenced_events, 1)
					break
				else
					total_travel_dis = total_travel_dis - data.seg_dis
					local old_seg_dir = data.seg_dir
					data.path_len = data.path_len - data.seg_dis
					data.dis_in_seg = 0
					data.seg_dir = data.path[3] - data.path[2]
					data.seg_dis = mvector3.normalize(data.seg_dir)
					local corner_dot = math.max(0, mvector3.dot(old_seg_dir, data.seg_dir))
					total_travel_dis = total_travel_dis * corner_dot
					data.velocity_len = data.velocity_len * corner_dot
					table.remove(data.path, 1)
				end
			else
				data.dis_in_seg = total_travel_dis
				new_pos = data.seg_dir * total_travel_dis
				mvector3.add(new_pos, data.path[1])
				break
			end
		end
		local displacement = new_pos - self._m_pos
		self:set_position(new_pos)
		local waist_twist_max = 45
		local sign_waist_twist = math.sign(waist_twist)
		local leg_max_angle_adj = math.min(abs_waist_twist, 120 * dt)
		local waist_twist_new = waist_twist - sign_waist_twist * leg_max_angle_adj
		if waist_twist_max < math.abs(waist_twist_new) then
			waist_twist_new = sign_waist_twist * waist_twist_max
		else
			waist_twist_new = waist_twist - sign_waist_twist * leg_max_angle_adj
		end
		local leg_rot_new = Rotation(look_dir_flat, math.UP) * Rotation(-waist_twist_new)
		self:set_rotation(leg_rot_new)
		local anim_velocity, anim_side
		if self._move_data then
			local fwd_new = self._m_rot:y()
			local right_new = fwd_new:cross(math.UP)
			local walk_dir_flat = data.seg_dir:with_z(0)
			mvector3.normalize(walk_dir_flat)
			local fwd_dot = walk_dir_flat:dot(fwd_new)
			local right_dot = walk_dir_flat:dot(right_new)
			if math.abs(fwd_dot) > math.abs(right_dot) then
				anim_side = fwd_dot > 0 and "fwd" or "bwd"
			else
				anim_side = right_dot > 0 and "r" or "l"
			end
			local vel = displacement / dt
			local vel_len = vel:length()
			if self._ext_anim.run then
				if vel_len > 250 and self._state ~= "mask_off" and self._state ~= "clean" then
					anim_velocity = "run"
				else
					anim_velocity = "walk"
				end
			elseif self._ext_anim.walk then
				if vel_len > 300 and self._state ~= "mask_off" and self._state ~= "clean" then
					anim_velocity = "run"
				else
					anim_velocity = "walk"
				end
			else
				anim_velocity = "walk"
			end
			self:_adjust_move_anim(anim_side, anim_velocity)
			local animated_walk_vel = self._walk_anim_velocities[self._ext_anim.pose][anim_velocity][anim_side]
			local anim_speed = vel_len / animated_walk_vel
			self:_adjust_walk_anim_speed(dt, anim_speed)
		elseif not self._ext_anim.idle then
			self:play_redirect("idle")
		end
	else
		if abs_waist_twist > 1 then
			local sign_waist_twist = math.sign(waist_twist)
			local side = "turn_" .. (sign_waist_twist > 0 and "l" or "r")
			self:_adjust_turn_anim(side, waist_twist)
			local leg_rot_new
			local waist_twist_max = 45
			local leg_max_angle_adj = math.min(abs_waist_twist, 120 * dt)
			local waist_twist_new = waist_twist - sign_waist_twist * leg_max_angle_adj
			if waist_twist_max < math.abs(waist_twist_new) then
				waist_twist_new = sign_waist_twist * waist_twist_max
			else
				waist_twist_new = waist_twist - sign_waist_twist * leg_max_angle_adj
			end
			leg_rot_new = Rotation(look_dir_flat, math.UP) * Rotation(-waist_twist_new)
			self:set_rotation(leg_rot_new)
		else
		end
	end
end
function HuskPlayerMovement:_adjust_move_anim(side, speed)
	local anim_data = self._ext_anim
	if anim_data[speed] and anim_data["move_" .. side] then
		return
	end
	local redirect_name = speed .. "_" .. side
	local enter_t
	local move_side = anim_data.move_side
	if move_side and (side == move_side or self._matching_walk_anims[side][move_side]) then
		local seg_rel_t = self._machine:segment_relative_time(Idstring("base"))
		local walk_anim_length = self._walk_anim_lengths[anim_data.pose][speed][side]
		enter_t = seg_rel_t * walk_anim_length
	end
	local redir_res = self:play_redirect(redirect_name, enter_t)
	return redir_res
end
function HuskPlayerMovement:_adjust_turn_anim(redirect_name, angle)
	local anim_data = self._ext_anim
	if anim_data[redirect_name] then
		return
	end
	local redir_res = self:play_redirect(redirect_name)
	if redir_res then
		local abs_angle = math.abs(angle)
		local anim_angle = "angle90"
		self._machine:set_parameter(redir_res, anim_angle, 1)
	end
	return redir_res
end
function HuskPlayerMovement:sync_action_walk_nav_point(pos)
	if Network:is_server() then
		if not self._pos_reservation then
			self._pos_reservation = {
				position = mvector3.copy(pos),
				radius = 100
			}
			self._pos_reservation_slow = {
				position = mvector3.copy(pos),
				radius = 100
			}
			managers.navigation:add_pos_reservation(self._pos_reservation)
			managers.navigation:add_pos_reservation(self._pos_reservation_slow)
		else
			self._pos_reservation.position = mvector3.copy(pos)
			managers.navigation:move_pos_rsrv(self._pos_reservation)
			self:_upd_slow_pos_reservation()
		end
	end
	local nr_seq_events = #self._sequenced_events
	if nr_seq_events == 1 and self._move_data then
		local path = self._move_data.path
		self._move_data.path_len = self._move_data.path_len + mvector3.distance(pos, path[#path])
		table.insert(path, pos)
	elseif nr_seq_events > 0 and self._sequenced_events[nr_seq_events].type == "move" then
		table.insert(self._sequenced_events[#self._sequenced_events].path, pos)
	else
		local event_desc = {
			type = "move",
			path = {pos}
		}
		self:_add_sequenced_event(event_desc)
	end
end
function HuskPlayerMovement:current_state()
	return self
end
function HuskPlayerMovement:_start_movement(path)
	local data = {}
	self._move_data = data
	table.insert(path, 1, self._unit:position())
	data.path = path
	data.seg_dir = data.path[2] - data.path[1]
	data.seg_dis = mvector3.normalize(data.seg_dir)
	data.dis_in_seg = 0
	data.velocity_len = 0
	local path_len = data.seg_dis
	local mvec3_dis = mvector3.distance
	local old_pos = path[2]
	local nr_nodes = #path
	local i = 3
	while nr_nodes >= i do
		local new_pos = path[i]
		path_len = path_len + mvec3_dis(new_pos, old_pos)
		old_pos = new_pos
		i = i + 1
	end
	data.path_len = path_len
end
function HuskPlayerMovement:_start_standard(event_desc)
	self:set_need_revive(false)
	self:set_need_assistance(false)
	managers.hud:set_mugshot_normal(self._unit:unit_data().mugshot_id)
	if self._state == "mask_off" or self._state == "clean" then
		self._unit:set_slot(5)
		self:_change_stance(1)
		self:_change_pose(1)
	else
		self._unit:set_slot(3)
		if Network:is_server() then
			managers.groupai:state():on_player_weapons_hot()
		end
		managers.groupai:state():on_criminal_recovered(self._unit)
	end
	local previous_state = event_desc.previous_state
	if previous_state == "mask_off" or previous_state == "clean" then
		local redir_res = self:play_redirect("equip")
		if redir_res then
			local weapon = self._unit:inventory():equipped_unit()
			if weapon then
				local weap_tweak = weapon:base():weapon_tweak_data()
				local weapon_hold = weap_tweak.hold
				self._machine:set_parameter(redir_res, "to_" .. weapon_hold, 1)
			end
		end
		self:_change_stance(2)
	end
	if not self._ext_anim.stand then
		local redir_res = self:play_redirect("stand")
		if not redir_res then
			self:play_state("std/stand/still/idle/look")
		end
	end
	if self._atention_on then
		self._machine:forbid_modifier(self._look_modifier_name)
		self._machine:forbid_modifier(self._head_modifier_name)
		self._machine:forbid_modifier(self._arm_modifier_name)
		self._machine:forbid_modifier(self._mask_off_modifier_name)
		self._atention_on = false
	end
	if self._state == "mask_off" or self._state == "clean" then
		self._attention_updator = callback(self, self, "_upd_attention_mask_off")
		self._mask_off_modifier:set_target_z(self._look_dir)
	else
		self._attention_updator = callback(self, self, "_upd_attention_standard")
		self._look_modifier:set_target_y(self._look_dir)
	end
	self._movement_updator = callback(self, self, "_upd_move_standard")
	return true
end
function HuskPlayerMovement:_start_bleedout(event_desc)
	local redir_res = self:play_redirect("bleedout")
	if not redir_res then
		print("[HuskPlayerMovement:_start_bleedout] redirect failed in", self._machine:segment_state(Idstring("base")), self._unit)
		return
	end
	self._unit:set_slot(3)
	managers.hud:set_mugshot_downed(self._unit:unit_data().mugshot_id)
	managers.groupai:state():on_criminal_disabled(self._unit)
	self._unit:interaction():set_tweak_data("revive")
	self:set_need_revive(true, event_desc.down_time)
	if self._atention_on then
		self._machine:forbid_modifier(self._look_modifier_name)
		self._machine:forbid_modifier(self._head_modifier_name)
		self._machine:forbid_modifier(self._arm_modifier_name)
		self._machine:forbid_modifier(self._mask_off_modifier_name)
		self._atention_on = false
	end
	self._attention_updator = callback(self, self, "_upd_attention_bleedout")
	self._movement_updator = callback(self, self, "_upd_move_downed")
	return true
end
function HuskPlayerMovement:_start_tased(event_desc)
	local redir_res = self:play_redirect("tased")
	if not redir_res then
		print("[HuskPlayerMovement:_start_tased] redirect failed in", self._machine:segment_state(Idstring("base")), self._unit)
		return
	end
	self._unit:set_slot(3)
	self:set_need_revive(false)
	managers.hud:set_mugshot_tased(self._unit:unit_data().mugshot_id)
	managers.groupai:state():on_criminal_disabled(self._unit, "electrified")
	self._tase_effect = World:effect_manager():spawn(self._tase_effect_table)
	self:set_need_assistance(true)
	if self._atention_on then
		self._machine:forbid_modifier(self._look_modifier_name)
		self._machine:forbid_modifier(self._head_modifier_name)
		self._machine:forbid_modifier(self._arm_modifier_name)
		self._machine:forbid_modifier(self._mask_off_modifier_name)
		self._atention_on = false
	end
	self._attention_updator = callback(self, self, "_upd_attention_tased")
	self._movement_updator = callback(self, self, "_upd_move_downed")
	return true
end
function HuskPlayerMovement:_start_fatal(event_desc)
	local redir_res = self:play_redirect("fatal")
	if not redir_res then
		print("[HuskPlayerMovement:_start_fatal] redirect failed in", self._machine:segment_state(Idstring("base")), self._unit)
		return
	end
	self._unit:set_slot(5)
	managers.hud:set_mugshot_downed(self._unit:unit_data().mugshot_id)
	managers.groupai:state():on_criminal_neutralized(self._unit)
	self._unit:interaction():set_tweak_data("revive")
	self:set_need_revive(true, event_desc.down_time)
	if self._atention_on then
		self._machine:forbid_modifier(self._look_modifier_name)
		self._machine:forbid_modifier(self._head_modifier_name)
		self._machine:forbid_modifier(self._arm_modifier_name)
		self._machine:forbid_modifier(self._mask_off_modifier_name)
		self._atention_on = false
	end
	self._attention_updator = false
	self._movement_updator = callback(self, self, "_upd_move_downed")
	return true
end
function HuskPlayerMovement:_start_incapacitated(event_desc)
	local redir_res = self:play_redirect("incapacitated")
	if not redir_res then
		print("[HuskPlayerMovement:_start_incapacitated] redirect failed in", self._machine:segment_state(Idstring("base")), self._unit)
		return
	end
	self:set_need_revive(true)
	if self._atention_on then
		self._machine:forbid_modifier(self._look_modifier_name)
		self._machine:forbid_modifier(self._head_modifier_name)
		self._machine:forbid_modifier(self._arm_modifier_name)
		self._machine:forbid_modifier(self._mask_off_modifier_name)
		self._atention_on = false
	end
	self._attention_updator = false
	self._movement_updator = callback(self, self, "_upd_move_downed")
	return true
end
function HuskPlayerMovement:_start_dead(event_desc)
	local redir_res = self:play_redirect("death")
	if not redir_res then
		print("[HuskPlayerMovement:_start_dead] redirect failed in", self._machine:segment_state(Idstring("base")), self._unit)
		return
	end
	if self._atention_on then
		local blend_out_t = 0.15
		self._machine:set_modifier_blend(self._look_modifier_name, blend_out_t)
		self._machine:set_modifier_blend(self._head_modifier_name, blend_out_t)
		self._machine:set_modifier_blend(self._arm_modifier_name, blend_out_t)
		self._machine:forbid_modifier(self._look_modifier_name)
		self._machine:forbid_modifier(self._head_modifier_name)
		self._machine:forbid_modifier(self._arm_modifier_name)
		self._machine:forbid_modifier(self._mask_off_modifier_name)
		self._atention_on = false
	end
	self._attention_updator = false
	self._movement_updator = callback(self, self, "_upd_move_downed")
	return true
end
function HuskPlayerMovement:_start_arrested(event_desc)
	if not self._ext_anim.hands_tied then
		local redir_res = self:play_redirect("tied")
		if not redir_res then
			print("[HuskPlayerMovement:_start_arrested] redirect failed in", self._machine:segment_state(Idstring("base")), self._unit)
			return
		end
	end
	self._unit:set_slot(5)
	managers.hud:set_mugshot_cuffed(self._unit:unit_data().mugshot_id)
	managers.groupai:state():on_criminal_neutralized(self._unit)
	self._unit:interaction():set_tweak_data("free")
	self:set_need_revive(true)
	if self._atention_on then
		self._machine:forbid_modifier(self._look_modifier_name)
		self._machine:forbid_modifier(self._head_modifier_name)
		self._machine:forbid_modifier(self._arm_modifier_name)
		self._machine:forbid_modifier(self._mask_off_modifier_name)
		self._atention_on = false
	end
	self._attention_updator = callback(self, self, "_upd_attention_disarmed")
	self._movement_updator = false
	return true
end
function HuskPlayerMovement:_adjust_walk_anim_speed(dt, target_speed)
	local state = self._machine:segment_state(Idstring("base"))
	local cur_speed = self._machine:get_speed(state)
	local max = 2
	local min = 0.05
	local new_speed
	if target_speed > cur_speed and cur_speed < max then
		new_speed = target_speed
	elseif target_speed < cur_speed and cur_speed > min then
		new_speed = target_speed
	end
	if new_speed then
		self._machine:set_speed(state, new_speed)
	end
end
function HuskPlayerMovement:sync_shot_blank(impact)
-- fail 32
null
6
	if self._state == "mask_off" or self._state == "clean" then
		return
	end
	local delay = self._stance.values[3] < 0.7
	if not delay then
		self:_shoot_blank(impact)
		self._aim_up_expire_t = TimerManager:game():time() + 2
	end
	self:_change_stance(3, {impact = impact})
end
function HuskPlayerMovement:_shoot_blank(impact)
	local equipped_weapon = self._unit:inventory():equipped_unit()
	if equipped_weapon and equipped_weapon:base().fire_blank then
		equipped_weapon:base():fire_blank(self._look_dir, impact)
		self._aim_up_expire_t = TimerManager:game():time() + 2
	end
end
function HuskPlayerMovement:sync_reload_weapon()
	self:play_redirect("reload")
end
function HuskPlayerMovement:sync_pose(pose_code)
	self:_change_pose(pose_code)
end
function HuskPlayerMovement:_change_stance(stance_code, delayed_shot)
	local stance = self._stance
	local end_values = {
		0,
		0,
		0
	}
	end_values[stance_code] = 1
	local start_values = {}
	for _, value in ipairs(stance.values) do
		table.insert(start_values, value)
	end
	local delay = stance.blend[stance_code]
	if delayed_shot then
		delay = delay * 0.3
	end
	local t = TimerManager:game():time()
	local transition = {
		end_values = end_values,
		start_values = start_values,
		duration = delay,
		start_t = t,
		next_upd_t = t + 0.07,
		delayed_shot = delayed_shot
	}
	stance.transition = transition
end
function HuskPlayerMovement:_change_pose(pose_code)
	local redirect = pose_code == 1 and "stand" or "crouch"
	self._pose_code = pose_code
	if self._ext_anim[redirect] then
		return
	end
	local enter_t
	local move_side = self._ext_anim.move_side
	if move_side then
		local seg_rel_t = self._machine:segment_relative_time(Idstring("base"))
		local speed = self._ext_anim.run and "run" or "walk"
		local walk_anim_length = self._walk_anim_lengths[self._ext_anim.pose][speed][move_side]
		enter_t = seg_rel_t * walk_anim_length
	end
	self:play_redirect(redirect, enter_t)
end
function HuskPlayerMovement:sync_movement_state(state, down_time)
	cat_print("george", "[HuskPlayerMovement:sync_movement_state]", state)
	local previous_state = self._state
	self._state = state
	self._last_down_time = down_time
	local peer = self._unit:network():peer()
	if peer then
		managers.player:update_crew_bonus_enabled(self._unit:network():peer():id(), state)
	end
	if state == "standard" then
		local event_desc = {type = "standard", previous_state = previous_state}
		self:_add_sequenced_event(event_desc)
	elseif state == "mask_off" then
		local event_desc = {type = "standard"}
		self:_add_sequenced_event(event_desc)
	elseif state == "fatal" then
		local event_desc = {type = "fatal", down_time = down_time}
		self:_add_sequenced_event(event_desc)
	elseif state == "bleed_out" then
		local event_desc = {type = "bleedout", down_time = down_time}
		self:_add_sequenced_event(event_desc)
	elseif state == "tased" then
		local event_desc = {type = "tased"}
		self:_add_sequenced_event(event_desc)
	elseif state == "incapacitated" then
		local event_desc = {type = "fatal", down_time = down_time}
		self:_add_sequenced_event(event_desc)
	elseif state == "arrested" then
		local event_desc = {type = "arrested"}
		self:_add_sequenced_event(event_desc)
	elseif state == "clean" then
		local event_desc = {type = "standard"}
		self:_add_sequenced_event(event_desc)
	end
end
function HuskPlayerMovement:on_disarmed()
	self._unit:network():send_to_unit({
		"sync_player_movement_state",
		self._unit,
		"arrested",
		0,
		self._unit:id()
	})
end
function HuskPlayerMovement:on_discovered()
	self._unit:network():send_to_unit({
		"sync_player_movement_state",
		self._unit,
		"standard",
		0,
		self._unit:id()
	})
end
function HuskPlayerMovement:on_SPOOCed()
	self._unit:network():send_to_unit({
		"sync_player_movement_state",
		self._unit,
		"incapacitated",
		0,
		self._unit:id()
	})
end
function HuskPlayerMovement:anim_clbk_footstep(unit)
	CopMovement.anim_clbk_footstep(self, unit, self._m_pos)
end
function HuskPlayerMovement:get_footstep_event()
	return CopMovement.get_footstep_event(self)
end
function HuskPlayerMovement:ground_ray()
end
function HuskPlayerMovement:clbk_inventory_event(unit, event)
	local weapon = self._unit:inventory():equipped_unit()
	if weapon then
		if self._weapon_hold then
			self._machine:set_global(self._weapon_hold, 0)
		end
		local weap_tweak = weapon:base():weapon_tweak_data()
		local weapon_hold = weap_tweak.hold
		self._machine:set_global(weapon_hold, 1)
		self._weapon_hold = weapon_hold
		if self._weapon_anim_global then
			self._machine:set_global(self._weapon_anim_global, 0)
		end
		local weapon_usage = weap_tweak.usage
		self._machine:set_global(weapon_usage, 1)
		self._weapon_anim_global = weapon_usage
	end
end
function HuskPlayerMovement:current_state_name()
	return self._state
end
function HuskPlayerMovement:tased()
	return self._state == "tased"
end
function HuskPlayerMovement:on_death_exit()
end
function HuskPlayerMovement:load(data)
	self.update = HuskPlayerMovement._post_load
	self._load_data = data
	self._post_load_start_t = Application:time()
end
function HuskPlayerMovement:_post_load(unit, t, dt)
	if not managers.network:session() then
		return
	end
	local peer = managers.network:session():peer(self._load_data.movement.peer_id)
	if peer or t > self._post_load_start_t + 10 then
		local data = self._load_data
		self.update = nil
		self._load_data = nil
		self._post_load_start_t = nil
		local my_data = data.movement
		if not my_data then
			return
		end
		UnitNetworkHandler.set_unit(UnitNetworkHandler, unit, my_data.character_name, my_data.peer_id)
		if managers.network:game():member_from_unit(unit) == nil then
			Application:error("[HuskPlayerBase:_post_load] A player husk who appears to not have an owning member was detached.")
			Network:detach_unit(unit)
			unit:set_slot(0)
			return
		end
		self:sync_movement_state(my_data.state_name, data.down_time)
		self:sync_pose(my_data.pose)
		local unit_rot = Rotation(my_data.look_fwd:with_z(0), math.UP)
		self:set_rotation(unit_rot)
		self:set_look_dir_instant(my_data.look_fwd)
	end
end
function HuskPlayerMovement:save(data)
	local peer_id = managers.network:game():member_from_unit(self._unit):peer():id()
	data.movement = {
		state_name = self._state,
		look_fwd = self:detect_look_dir(),
		pose = self._pose_code,
		peer_id = peer_id,
		character_name = managers.criminals:character_name_by_unit(self._unit)
	}
	data.down_time = self._last_down_time
end
function HuskPlayerMovement:pre_destroy(unit)
	if self._pos_reservation then
		managers.navigation:unreserve_pos(self._pos_reservation)
		managers.navigation:unreserve_pos(self._pos_reservation_slow)
		self._pos_reservation = nil
		self._pos_reservation_slow = nil
	end
	self:set_need_revive(false)
	self:set_need_assistance(false)
	if self._nav_tracker then
		managers.navigation:destroy_nav_tracker(self._nav_tracker)
		self._nav_tracker = nil
	end
end
