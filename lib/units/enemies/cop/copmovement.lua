require("lib/units/enemies/cop/actions/lower_body/CopActionIdle")
require("lib/units/enemies/cop/actions/lower_body/CopActionWalk")
require("lib/units/enemies/cop/actions/full_body/CopActionAct")
require("lib/units/enemies/cop/actions/lower_body/CopActionTurn")
require("lib/units/enemies/cop/actions/full_body/CopActionHurt")
require("lib/units/enemies/cop/actions/lower_body/CopActionStand")
require("lib/units/enemies/cop/actions/lower_body/CopActionCrouch")
require("lib/units/enemies/cop/actions/upper_body/CopActionShoot")
require("lib/units/enemies/cop/actions/upper_body/CopActionReload")
require("lib/units/enemies/cop/actions/upper_body/CopActionTase")
require("lib/units/enemies/cop/actions/full_body/CopActionDodge")
require("lib/units/enemies/spooc/actions/lower_body/ActionSpooc")
require("lib/units/civilians/actions/lower_body/CivilianActionWalk")
require("lib/units/civilians/actions/lower_body/EscortWithSuitcaseActionWalk")
require("lib/units/enemies/tank/actions/lower_body/TankCopActionWalk")
require("lib/units/player_team/actions/lower_body/CriminalActionWalk")
local ids_movement = Idstring("movement")
local mvec3_set = mvector3.set
local mvec3_set_z = mvector3.set_z
local mvec3_lerp = mvector3.lerp
local mrot_set = mrotation.set_yaw_pitch_roll
local temp_vec1 = Vector3()
local temp_vec2 = Vector3()
local temp_vec3 = Vector3()
local stance_ctl_pts = {
	0,
	0,
	1,
	1
}
CopMovement = CopMovement or class()
CopMovement._gadgets = {
	aligns = {
		hand_l = Idstring("a_weapon_left_front"),
		hand_r = Idstring("a_weapon_right_front"),
		head = Idstring("Head")
	},
	cigarette = {
		Idstring("units/world/props/cigarette/cigarette")
	},
	briefcase = {
		Idstring("units/equipment/escort_suitcase/escort_suitcase_contour")
	},
	briefcase2 = {
		Idstring("units/equipment/escort_suitcase/escort_suitcase")
	},
	iphone = {
		Idstring("units/world/props/iphone/iphone")
	},
	baton = {
		Idstring("units/characters/accessories/baton/baton")
	},
	revolver = {
		Idstring("units/weapons/raging_bull_npc/raging_bull_npc")
	},
	c45 = {
		Idstring("units/weapons/c45_npc/c45_npc")
	},
	beretta = {
		Idstring("units/weapons/beretta92_npc/beretta92_npc")
	},
	m4 = {
		Idstring("units/weapons/m4_rifle_npc/m4_rifle_npc")
	},
	shotgun = {
		Idstring("units/weapons/r870_shotgun_npc/r870_shotgun_npc")
	},
	mp5 = {
		Idstring("units/weapons/mp5_npc/mp5_npc")
	},
	shield = {
		Idstring("units/weapons/shield/shield")
	},
	machinegun = {
		Idstring("units/weapons/hk21_npc/hk21_npc")
	},
	trip = {
		Idstring("units/weapons/trip_mine/trip_mine")
	},
	needle = {
		Idstring("units/characters/accessories/syringe/syringe")
	},
	pencil = {
		Idstring("units/world/brushes/desk_pencil/desk_pencil")
	},
	bbq_fork = {
		Idstring("units/world/props/barbecue/bbq_fork")
	},
	money_bag = {
		Idstring("units/world/architecture/secret_stash/luggage_bag/secret_stash_luggage_bag")
	},
	newspaper = {
		Idstring("units/world/props/suburbia_newspaper/suburbia_newspaper")
	},
	vail = {
		Idstring("units/world/props/hospital_veil_interaction/hospital_veil_full")
	},
	ivstand = {
		Idstring("units/world/architecture/hospital/props/iv_pole/iv_pole")
	},
	clipboard_paper = {
		Idstring("units/world/architecture/hospital/props/clipboard01/clipboard_paper")
	}
}
local action_variants = {
	security = {
		idle = CopActionIdle,
		act = CopActionAct,
		walk = CopActionWalk,
		turn = CopActionTurn,
		hurt = CopActionHurt,
		stand = CopActionStand,
		crouch = CopActionCrouch,
		shoot = CopActionShoot,
		reload = CopActionReload,
		spooc = ActionSpooc,
		tase = CopActionTase,
		dodge = CopActionDodge
	}
}
local security_variant = action_variants.security
action_variants.patrol = security_variant
action_variants.cop = security_variant
action_variants.fbi = security_variant
action_variants.swat = security_variant
action_variants.heavy_swat = security_variant
action_variants.nathan = security_variant
action_variants.sniper = security_variant
action_variants.gangster = security_variant
action_variants.dealer = security_variant
action_variants.shield = security_variant
action_variants.murky = security_variant
action_variants.tank = clone(security_variant)
action_variants.tank.walk = TankCopActionWalk
action_variants.spooc = security_variant
action_variants.taser = security_variant
action_variants.civilian = {
	idle = CopActionIdle,
	act = CopActionAct,
	walk = CivilianActionWalk,
	turn = CopActionTurn,
	hurt = CopActionHurt
}
action_variants.civilian_female = action_variants.civilian
action_variants.bank_manager = action_variants.civilian
action_variants.escort = action_variants.civilian
action_variants.escort_suitcase = clone(action_variants.civilian)
action_variants.escort_suitcase.walk = EscortWithSuitcaseActionWalk
action_variants.escort_prisoner = clone(action_variants.civilian)
action_variants.escort_prisoner.walk = EscortPrisonerActionWalk
action_variants.escort_cfo = action_variants.civilian
action_variants.escort_ralph = action_variants.civilian
action_variants.escort_undercover = clone(action_variants.civilian)
action_variants.escort_undercover.walk = EscortWithSuitcaseActionWalk
action_variants.russian = clone(security_variant)
action_variants.russian.walk = CriminalActionWalk
action_variants.german = action_variants.russian
action_variants.spanish = action_variants.russian
action_variants.american = action_variants.russian
security_variant = nil
CopMovement._action_variants = action_variants
action_variants = nil
CopMovement._stance = {}
CopMovement._stance.names = {
	"ntl",
	"hos",
	"cbt",
	"wnd"
}
CopMovement._stance.blend = {
	0.8,
	0.5,
	0.3,
	0.4
}
function CopMovement:init(unit)
	self._unit = unit
	self._machine = self._unit:anim_state_machine()
	self._nav_tracker_id = self._unit:key()
	self._nav_tracker = nil
	self._root_blend_ref = 0
	self._m_pos = unit:position()
	self._m_stand_pos = mvector3.copy(self._m_pos)
	mvec3_set_z(self._m_stand_pos, self._m_pos.z + 160)
	self._m_com = math.lerp(self._m_pos, self._m_stand_pos, 0.5)
	self._obj_head = unit:get_object(Idstring("Head"))
	self._m_head_rot = self._obj_head:rotation()
	self._m_head_pos = self._obj_head:position()
	self._obj_spine = unit:get_object(Idstring("Spine1"))
	self._m_rot = unit:rotation()
	self._footstep_style = nil
	self._footstep_event = ""
	self._obj_com = unit:get_object(Idstring("Hips"))
	self._slotmask_gnd_ray = managers.slot:get_mask("AI_graph_obstacle_check")
	self._actions = self._action_variants[self._unit:base()._tweak_table]
	self._active_actions = {
		false,
		false,
		false,
		false
	}
	self._need_upd = true
end
function CopMovement:post_init()
	local unit = self._unit
	self._ext_brain = unit:brain()
	self._ext_network = unit:network()
	self._ext_anim = unit:anim_data()
	self._ext_base = unit:base()
	self._ext_damage = unit:character_damage()
	self._ext_inventory = unit:inventory()
	self._tweak_data = tweak_data.character[self._ext_base._tweak_table]
	tweak_data:add_reload_callback(self, self.tweak_data_clbk_reload)
	self._machine = self._unit:anim_state_machine()
	self._machine:set_callback_object(self)
	self._stance = {
		values = {
			1,
			0,
			0,
			0
		}
	}
	if managers.navigation:is_data_ready() then
		self._nav_tracker = managers.navigation:create_nav_tracker(self._m_pos)
		self._pos_rsrv_id = managers.navigation:get_pos_reservation_id()
	else
		Application:error("[CopMovement:post_init] Spawned AI unit with incomplete navigation data.")
		self._unit:set_extension_update(ids_movement, false)
	end
	self._unit:kill_mover()
	self._unit:set_driving("script")
	self._unit:character_damage():add_listener("movement", {
		"bleedout",
		"light_hurt",
		"heavy_hurt",
		"hurt",
		"death",
		"fatal"
	}, callback(self, self, "damage_clbk"))
	local weap_name = self._ext_base:default_weapon_name()
	if weap_name then
		self._unit:inventory():add_listener("movement", {"equip"}, callback(self, self, "clbk_inventory"))
		self._unit:inventory():add_unit_by_name(weap_name, true, true)
	end
	local fwd = self._m_rot:y()
	self._action_common_data = {
		stance = self._stance,
		pos = self._m_pos,
		rot = self._m_rot,
		fwd = fwd,
		right = self._m_rot:x(),
		unit = unit,
		machine = self._machine,
		ext_movement = self,
		ext_brain = self._ext_brain,
		ext_anim = self._ext_anim,
		ext_inventory = self._ext_inventory,
		ext_base = self._ext_base,
		ext_network = self._ext_network,
		ext_damage = self._ext_damage,
		char_tweak = self._tweak_data,
		nav_tracker = self._nav_tracker,
		active_actions = self._active_actions,
		queued_actions = self._queued_actions,
		look_vec = mvector3.copy(fwd)
	}
	self:upd_ground_ray()
	if self._gnd_ray then
		self:set_position(self._gnd_ray.position)
	end
	self:_post_init()
end
function CopMovement:_post_init()
	self:set_character_anim_variables()
end
function CopMovement:set_character_anim_variables()
	if self._anim_global then
		self._machine:set_global(self._anim_global, 1)
	end
	if self._tweak_data.female then
		self._machine:set_global("female", 1)
	end
end
function CopMovement:nav_tracker()
	return self._nav_tracker
end
function CopMovement:warp_to(pos, rot)
	self._unit:warp_to(rot, pos)
end
function CopMovement:update(unit, t, dt)
	self._gnd_ray = nil
	local old_need_upd = self._need_upd
	self._need_upd = false
	self:_upd_actions(t)
	if self._need_upd ~= old_need_upd then
		unit:set_extension_update_enabled(ids_movement, self._need_upd)
	end
	if self._force_head_upd then
		self._force_head_upd = nil
		self:upd_m_head_pos()
	end
end
function CopMovement:_upd_actions(t)
	local a_actions = self._active_actions
	local has_no_action = true
	for i_action, action in ipairs(a_actions) do
		if action then
			if action.update then
				action:update(t)
			end
			if not self._need_upd and action.need_upd then
				self._need_upd = action:need_upd()
			end
			if action.expired and action:expired() then
				a_actions[i_action] = false
				if action.on_exit then
					action:on_exit()
				end
				self._ext_brain:action_complete_clbk(action)
				self._ext_base:chk_freeze_anims()
				for _, action in ipairs(a_actions) do
					if action then
						has_no_action = nil
						break
					end
				end
			else
				has_no_action = nil
			end
		end
	end
	if has_no_action and not self._queued_actions then
		self:action_request({type = "idle", body_part = 1})
	end
	self:_upd_stance(t)
	if not self._need_upd and (self._ext_anim.base_need_upd or self._stance.transition) then
		self._need_upd = true
	end
end
function CopMovement:_upd_stance(t)
	if self._stance.transition then
		local stance = self._stance
		local transition = stance.transition
		if t > transition.next_upd_t then
			transition.next_upd_t = t + 0.033
			local values = stance.values
			local prog = (t - transition.start_t) / transition.duration
			if prog < 1 then
				local prog_smooth = math.clamp(math.bezier(stance_ctl_pts, prog), 0, 1)
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
				stance.transition = nil
			end
			local names = CopMovement._stance.names
			for i, v in ipairs(values) do
				self._machine:set_global(names[i], v)
			end
		end
	end
end
function CopMovement:on_anim_freeze(state)
	self._frozen = state
end
function CopMovement:upd_m_head_pos()
	self._obj_head:m_position(self._m_head_pos)
	self._obj_spine:m_position(self._m_com)
end
function CopMovement:set_position(pos)
	mvec3_set(self._m_pos, pos)
	mvec3_set(self._m_stand_pos, pos)
	mvec3_set_z(self._m_stand_pos, pos.z + 160)
	self._obj_head:m_position(self._m_head_pos)
	self._obj_spine:m_position(self._m_com)
	self._nav_tracker:move(pos)
	self._unit:set_position(pos)
end
function CopMovement:set_m_pos(pos)
	mvec3_set(self._m_pos, pos)
	mvec3_set(self._m_stand_pos, pos)
	mvec3_set_z(self._m_stand_pos, pos.z + 160)
	self._obj_head:m_position(self._m_head_pos)
	self._nav_tracker:move(pos)
	self._obj_spine:m_position(self._m_com)
end
function CopMovement:set_m_rot(rot)
	mrot_set(self._m_rot, rot:yaw(), 0, 0)
	self._action_common_data.fwd = rot:y()
	self._action_common_data.right = rot:x()
end
function CopMovement:set_rotation(rot)
	mrot_set(self._m_rot, rot:yaw(), 0, 0)
	self._action_common_data.fwd = rot:y()
	self._action_common_data.right = rot:x()
	self._unit:set_rotation(rot)
end
function CopMovement:m_pos()
	return self._m_pos
end
function CopMovement:m_stand_pos()
	return self._m_stand_pos
end
function CopMovement:m_com()
	return self._m_com
end
function CopMovement:m_head_pos()
	return self._m_head_pos
end
function CopMovement:m_head_rot()
	return self._obj_head:rotation()
end
function CopMovement:m_fwd()
	return self._action_common_data.fwd
end
function CopMovement:m_rot()
	return self._m_rot
end
function CopMovement:set_m_host_stop_pos(pos)
	mvec3_set(self._m_host_stop_pos, pos)
end
function CopMovement:m_host_stop_pos()
	return self._m_host_stop_pos
end
function CopMovement:play_redirect(redirect_name, at_time)
	local result = self._unit:play_redirect(Idstring(redirect_name), at_time)
	return result ~= Idstring("") and result
end
function CopMovement:play_state(state_name, at_time)
	local result = self._unit:play_state(Idstring(state_name), at_time)
	return result ~= Idstring("") and result
end
function CopMovement:play_state_idstr(state_name, at_time)
	local result = self._unit:play_state(state_name, at_time)
	return result ~= Idstring("") and result
end
function CopMovement:set_root_blend(state)
	if state then
		if self._root_blend_ref == 1 then
			self._machine:set_root_blending(true)
		end
		self._root_blend_ref = self._root_blend_ref - 1
	else
		if self._root_blend_ref == 0 then
			self._machine:set_root_blending(false)
		end
		self._root_blend_ref = self._root_blend_ref + 1
	end
end
function CopMovement:chk_action_forbidden(action_type)
	local t = TimerManager:game():time()
	for i_action, action in ipairs(self._active_actions) do
		if action and action.chk_block and action:chk_block(action_type, t) then
			return true
		end
	end
end
function CopMovement:action_request(action_desc)
	if Network:is_server() and self._active_actions[1] and self._active_actions[1]:type() == "hurt" and self._active_actions[1]:hurt_type() == "death" then
		debug_pause_unit(self._unit, "[CopMovement:action_request] Dead man walking!!!", self._unit, inspect(action_desc))
	end
	self.has_no_action = nil
	local body_part = action_desc.body_part
	local active_actions = self._active_actions
	local interrupted_actions
	local function _interrupt_action(body_part)
		local old_action = active_actions[body_part]
		if old_action then
			active_actions[body_part] = false
			if old_action.on_exit then
				old_action:on_exit()
			end
			interrupted_actions = interrupted_actions or {}
			interrupted_actions[body_part] = old_action
		end
	end
	_interrupt_action(body_part)
	if body_part == 1 then
		_interrupt_action(2)
		_interrupt_action(3)
	elseif body_part == 2 or body_part == 3 then
		_interrupt_action(1)
	end
	if not self._actions[action_desc.type] then
		debug_pause("[CopMovement:action_request] invalid action started", inspect(self._actions), inspect(action_desc))
		return
	end
	local action, success = self._actions[action_desc.type]:new(action_desc, self._action_common_data)
	if success and (not action.expired or not action:expired()) then
		active_actions[body_part] = action
	end
	if interrupted_actions then
		for body_part, interrupted_action in pairs(interrupted_actions) do
			self._ext_brain:action_complete_clbk(interrupted_action)
		end
	end
	self._ext_base:chk_freeze_anims()
	return success and action
end
function CopMovement:get_action(body_part)
	return self._active_actions[body_part]
end
function CopMovement:set_attention(attention)
	if self._attention and self._attention.destroy_listener_key then
		self._attention.unit:base():remove_destroy_listener(self._attention.destroy_listener_key)
	end
	if attention then
		if attention.unit then
			local listener_key = "CopMovement" .. tostring(self._unit:key())
			attention.destroy_listener_key = listener_key
			attention.unit:base():add_destroy_listener(listener_key, callback(self, self, "attention_unit_destroy_clbk"))
			if self._ext_network and attention.unit:id() ~= -1 then
				self._ext_network:send("cop_set_attention_unit", attention.unit)
			end
		elseif self._ext_network then
			self._ext_network:send("cop_set_attention_pos", attention.pos)
		end
	elseif self._attention and Network:is_server() and self._unit:id() ~= -1 then
		self._ext_network:send("cop_reset_attention")
	end
	local old_attention = self._attention
	self._attention = attention
	self._action_common_data.attention = attention
	for _, action in ipairs(self._active_actions) do
		if action and action.on_attention then
			action:on_attention(attention, old_attention)
		end
	end
end
function CopMovement:set_stance(new_stance_name)
	for i_stance, stance_name in ipairs(CopMovement._stance.names) do
		if stance_name == new_stance_name then
			self:set_stance_by_code(i_stance)
			break
		end
	end
end
function CopMovement:set_stance_by_code(new_stance_code)
	if self._stance.transition or self._stance.values[new_stance_code] ~= 1 then
		self._ext_network:send("set_stance", new_stance_code)
		self:_change_stance(new_stance_code)
	end
end
function CopMovement:_change_stance(stance_code)
	local stance = self._stance
	local end_values = {}
	if stance_code == 4 then
		if stance.transition then
			end_values = stance.transition.end_values
		else
			for i, value in ipairs(stance.values) do
				end_values[i] = value
			end
		end
	elseif stance.transition then
		end_values = {
			0,
			0,
			0,
			stance.transition.end_values[4]
		}
	else
		end_values = {
			0,
			0,
			0,
			stance.values[4]
		}
	end
	end_values[stance_code] = 1
	local delay
	local vis_state = self._ext_base:lod_stage()
	if vis_state then
		delay = CopMovement._stance.blend[stance_code]
		if 2 < vis_state then
			delay = delay * 0.5
		end
	else
		stance.transition = nil
		if stance_code ~= 1 then
			self:_chk_play_equip_weapon()
		end
		local names = CopMovement._stance.names
		for i, v in ipairs(end_values) do
			if v ~= stance.values[i] then
				stance.values[i] = v
				self._machine:set_global(names[i], v)
			end
		end
		return
	end
	local start_values = {}
	for _, value in ipairs(stance.values) do
		table.insert(start_values, value)
	end
	local t = TimerManager:game():time()
	local transition = {
		end_values = end_values,
		start_values = start_values,
		duration = delay,
		start_t = t,
		next_upd_t = t + 0.07
	}
	stance.transition = transition
	if stance_code ~= 1 then
		self:_chk_play_equip_weapon()
	end
	self:enable_update()
end
function CopMovement:sync_stance(i_stance)
	self:_change_stance(i_stance)
end
function CopMovement:cool()
	if self._stance.transition then
		return self._stance.transition.end_values[1] ~= 0
	else
		return self._stance.values[1] ~= 0
	end
end
function CopMovement:_chk_play_equip_weapon()
	if self._stance.values[1] == 1 and not self._ext_anim.equip then
		local redir_res = self:play_redirect("equip")
		if redir_res then
			local weapon_unit = self._ext_inventory:equipped_unit()
			if weapon_unit then
				local weap_tweak = weapon_unit:base():weapon_tweak_data()
				local weapon_hold = weap_tweak.hold
				self._machine:set_parameter(redir_res, "to_" .. weapon_hold, 1)
			end
		end
	end
end
function CopMovement:synch_attention(attention)
	if self._attention and self._attention.destroy_listener_key then
		self._attention.unit:base():remove_destroy_listener(self._attention.destroy_listener_key)
	end
	if attention and attention.unit then
		local listener_key = "CopMovement" .. tostring(self._unit:key())
		attention.destroy_listener_key = listener_key
		attention.unit:base():add_destroy_listener(listener_key, callback(self, self, "attention_unit_destroy_clbk"))
	end
	self._attention = attention
	self._action_common_data.attention = attention
	for _, action in ipairs(self._active_actions) do
		if action and action.on_attention then
			action:on_attention(attention)
		end
	end
end
function CopMovement:attention()
	return self._attention
end
function CopMovement:attention_unit_destroy_clbk(unit)
	if Network:is_server() then
		self:set_attention()
	else
		self:synch_attention()
	end
end
function CopMovement:set_allow_fire_on_client(state, unit)
	if Network:is_server() then
		unit:network():send_to_unit({
			state and "cop_allow_fire" or "cop_forbid_fire",
			self._unit
		})
	end
end
function CopMovement:set_allow_fire(state)
	if self._allow_fire == state then
		return
	end
	self:synch_allow_fire(state)
	if Network:is_server() then
		self._ext_network:send(state and "cop_allow_fire" or "cop_forbid_fire")
	end
	self:enable_update()
end
function CopMovement:synch_allow_fire(state)
	for _, action in pairs(self._active_actions) do
		if action and action.allow_fire_clbk then
			action:allow_fire_clbk(state)
		end
	end
	self._allow_fire = state
	self._action_common_data.allow_fire = state
end
function CopMovement:linked(state, physical, parent_unit)
	if state then
		self._link_data = {physical = physical, parent = parent_unit}
		parent_unit:base():add_destroy_listener("CopMovement" .. tostring(self._unit:key()), callback(self, self, "parent_clbk_unit_destroyed"))
	else
		parent_unit:base():remove_destroy_listener("CopMovement" .. tostring(self._unit:key()))
		self._link_data = nil
	end
end
function CopMovement:parent_clbk_unit_destroyed(parent_unit, key)
	self._link_data = nil
	parent_unit:base():remove_destroy_listener("CopMovement" .. tostring(self._unit:key()))
end
function CopMovement:is_physically_linked()
	return self._link_data and self._link_data.physical
end
function CopMovement:move_vec()
	return self._move_dir
end
function CopMovement:upd_ground_ray(from_pos)
	local ground_z = self._nav_tracker:field_z()
	local safe_pos = temp_vec1
	mvec3_set(temp_vec1, from_pos or self._m_pos)
	mvec3_set_z(temp_vec1, ground_z + 100)
	local down_pos = temp_vec2
	mvec3_set(temp_vec2, safe_pos)
	mvec3_set_z(temp_vec2, ground_z - 140)
	local old_pos = self._m_pos
	local new_pos = from_pos or self._m_pos
	local hit_ray
	if old_pos.z == new_pos.z then
		local gnd_ray_1 = World:raycast("ray", temp_vec1, temp_vec2, "slot_mask", self._slotmask_gnd_ray, "ray_type", "walk")
		if gnd_ray_1 then
			ground_z = math.lerp(gnd_ray_1.position.z, self._m_pos.z, 0.5)
			hit_ray = gnd_ray_1
		end
	else
		local gnd_ray_1 = World:raycast("ray", temp_vec1, temp_vec2, "slot_mask", self._slotmask_gnd_ray, "ray_type", "walk")
		local move_vec = temp_vec3
		mvec3_set(move_vec, new_pos)
		mvector3.subtract(move_vec, old_pos)
		mvec3_set_z(move_vec, 0)
		local move_vec_len = mvector3.normalize(move_vec)
		mvector3.multiply(move_vec, 20)
		mvector3.add(temp_vec1, move_vec)
		mvector3.add(temp_vec2, move_vec)
		if gnd_ray_1 then
			hit_ray = gnd_ray_1
			local gnd_ray_2 = World:raycast("ray", temp_vec1, temp_vec2, "slot_mask", self._slotmask_gnd_ray, "ray_type", "walk")
			if gnd_ray_2 then
				ground_z = math.lerp(gnd_ray_1.position.z, gnd_ray_2.position.z, 0.5)
			else
				ground_z = math.lerp(gnd_ray_1.position.z, self._m_pos.z, 0.5)
			end
		else
			local gnd_ray_2 = World:raycast("ray", temp_vec1, temp_vec2, "slot_mask", self._slotmask_gnd_ray, "ray_type", "walk")
			if gnd_ray_2 then
				hit_ray = gnd_ray_2
				ground_z = math.lerp(gnd_ray_2.position.z, self._m_pos.z, 0.5)
			end
		end
	end
	local fake_ray = {
		position = new_pos:with_z(ground_z),
		ray = math.DOWN,
		unit = hit_ray and hit_ray.unit
	}
	self._action_common_data.gnd_ray = fake_ray
	self._gnd_ray = fake_ray
end
function CopMovement:damage_clbk(my_unit, damage_info)
	local hurt_type = damage_info.result.type
	if hurt_type == "death" and self._queued_actions then
		self._queued_actions = {}
	end
	if not hurt_type or Network:is_server() and self:chk_action_forbidden(hurt_type) then
		if hurt_type == "death" then
			debug_pause("[CopMovement:damage_clbk] Death action skipped!!!", self._unit)
			Application:draw_cylinder(self._m_pos, self._m_pos + math.UP * 5000, 30, 1, 0, 0)
			print("active_actions")
			for body_part, action in ipairs(self._active_actions) do
				if action then
					print(body_part, action:type(), inspect(action._blocks))
				end
			end
		end
		return
	end
	if hurt_type == "death" and self._rope then
		self._rope:base():retract()
		self._rope = nil
	end
	local attack_dir = damage_info.col_ray and damage_info.col_ray.ray or damage_info.attack_dir
	local hit_pos = damage_info.col_ray and damage_info.col_ray.position or damage_info.pos
	local lgt_hurt = hurt_type == "light_hurt"
	local body_part = lgt_hurt and 4 or 1
	local blocks
	if not lgt_hurt then
		blocks = {
			walk = -1,
			action = -1,
			act = -1,
			aim = -1,
			tase = -1
		}
		if hurt_type == "bleedout" then
			blocks.bleedout = -1
			blocks.hurt = -1
			blocks.heavy_hurt = -1
		end
	end
	local block_type
	if damage_info.variant == "tase" then
		block_type = "bleedout"
	else
		block_type = hurt_type
	end
	local client_interrupt
	if Network:is_client() and (hurt_type == "light_hurt" or hurt_type == "hurt" and damage_info.variant ~= "tase" or hurt_type == "heavy_hurt" or hurt_type == "death") then
		client_interrupt = true
	end
	local tweak = tweak_data.character[self._unit:base()._tweak_table]
	local action_data = {
		type = "hurt",
		block_type = block_type,
		hurt_type = hurt_type,
		variant = damage_info.variant,
		direction_vec = attack_dir,
		hit_pos = hit_pos,
		body_part = body_part,
		blocks = blocks,
		client_interrupt = client_interrupt,
		death_type = tweak.damage.death_severity and (damage_info.damage / tweak.HEALTH_INIT > tweak.damage.death_severity and "heavy" or "normal") or "normal"
	}
	if Network:is_server() or not self:chk_action_forbidden(action_data) then
		self:action_request(action_data)
		if hurt_type == "death" and self._queued_actions then
			self._queued_actions = {}
		end
	end
end
function CopMovement:anim_clbk_footstep(unit)
	managers.game_play_central:request_play_footstep(unit, self._m_pos)
end
function CopMovement:get_footstep_event()
	local event_name
	if self._footstep_style and self._unit:anim_data()[self._footstep_style] then
		event_name = self._footstep_event
	else
		self._footstep_style = self._unit:anim_data().run and "run" or "walk"
		event_name = "footstep_npc_" .. self._footwear .. "_" .. self._footstep_style
		self._footstep_event = event_name
	end
	return event_name
end
function CopMovement:get_walk_to_pos()
	local leg_action = self._active_actions[1] or self._active_actions[2]
	if leg_action and leg_action.get_walk_to_pos then
		return leg_action:get_walk_to_pos()
	end
end
function CopMovement:anim_clbk_death_drop(...)
	for _, action in ipairs(self._active_actions) do
		if action and action.on_death_drop then
			action:on_death_drop(...)
		end
	end
end
function CopMovement:on_death_exit()
	for _, action in ipairs(self._active_actions) do
		if action and action.on_death_exit then
			action:on_death_exit()
		end
	end
end
function CopMovement:anim_clbk_reload_exit()
	if self._ext_inventory:equipped_unit() then
		self._ext_inventory:equipped_unit():base():on_reload()
	end
end
function CopMovement:anim_clbk_force_ragdoll()
	for _, action in ipairs(self._active_actions) do
		if action and action.force_ragdoll then
			action:force_ragdoll()
		end
	end
end
function CopMovement:anim_clbk_rope(unit, state)
	if state == "on" then
		if self._rope then
			self._rope:retract()
		end
		local hips_obj = self._unit:get_object(Idstring("Hips"))
		self._rope = World:spawn_unit(Idstring("units/characters/accessories/rope/rope"), hips_obj:position(), Rotation())
		self._rope:base():setup(hips_obj)
	elseif self._rope then
		self._rope:base():retract()
		self._rope = nil
	end
end
function CopMovement:pos_rsrv_id()
	return self._pos_rsrv_id
end
function CopMovement:anim_clbk_wanted_item(unit, item_type, align_place, droppable)
	self._wanted_items = self._wanted_items or {}
	table.insert(self._wanted_items, {
		item_type,
		align_place,
		droppable
	})
end
function CopMovement:anim_clbk_block_info(unit, preset_name, block_state)
	local state_bool = block_state == "true" and true or false
	for body_part, action in pairs(self._active_actions) do
		if action and action.set_blocks then
			action:set_blocks(preset_name, state_bool)
		end
	end
end
function CopMovement:anim_clbk_ik_change(unit)
	local preset_name = self._ext_anim.base_aim_ik
	for body_part, action in pairs(self._active_actions) do
		if action and action.set_ik_preset then
			action:set_ik_preset(preset_name)
		end
	end
end
function CopMovement:spawn_wanted_items()
	if self._wanted_items then
		for _, spawn_info in ipairs(self._wanted_items) do
			self:_equip_item(unpack(spawn_info))
		end
		self._wanted_items = nil
	end
end
function CopMovement:_equip_item(item_type, align_place, droppable)
	local align_name = self._gadgets.aligns[align_place]
	if not align_name then
		print("[CopMovement:anim_clbk_equip_item] non existent align place:", align_place)
		return
	end
	local align_obj = self._unit:get_object(align_name)
	local available_items = self._gadgets[item_type]
	if not available_items then
		print("[CopMovement:anim_clbk_equip_item] non existent item_type:", item_type)
		return
	end
	local item_name = available_items[math.random(available_items)]
	print("[CopMovement:_equip_item]", item_name)
	local item_unit = World:spawn_unit(item_name, align_obj:position(), align_obj:rotation())
	self._unit:link(align_name, item_unit, item_unit:orientation_object():name())
	self._equipped_gadgets = self._equipped_gadgets or {}
	self._equipped_gadgets[align_place] = self._equipped_gadgets[align_place] or {}
	table.insert(self._equipped_gadgets[align_place], item_unit)
	if droppable then
		self._droppable_gadgets = self._droppable_gadgets or {}
		table.insert(self._droppable_gadgets, item_unit)
	end
end
function CopMovement:anim_clbk_drop_held_items()
	self:drop_held_items()
end
function CopMovement:anim_clbk_flush_wanted_items()
	self._wanted_items = nil
end
function CopMovement:drop_held_items()
	if not self._droppable_gadgets then
		return
	end
	for _, drop_item_unit in ipairs(self._droppable_gadgets) do
		if alive(drop_item_unit) then
			local wanted_item_key = drop_item_unit:key()
			for align_place, item_list in pairs(self._equipped_gadgets) do
				if wanted_item_key then
					for i_item, item_unit in ipairs(item_list) do
						if item_unit:key() == wanted_item_key then
							table.remove(item_list, i_item)
							wanted_item_key = nil
							break
						end
					end
				else
					break
				end
			end
			drop_item_unit:unlink()
			drop_item_unit:set_slot(0)
		else
			for align_place, item_list in pairs(self._equipped_gadgets) do
				if wanted_item_key then
					for i_item, item_unit in ipairs(item_list) do
						if not alive(item_unit) then
							table.remove(item_list, i_item)
						end
					end
				end
			end
		end
	end
	self._droppable_gadgets = nil
end
function CopMovement:_destroy_gadgets()
	if not self._equipped_gadgets then
		return
	end
	for align_place, item_list in pairs(self._equipped_gadgets) do
		for _, item_unit in ipairs(item_list) do
			if alive(item_unit) then
				item_unit:set_slot(0)
			end
		end
	end
	self._equipped_gadgets = nil
	self._droppable_gadgets = nil
end
function CopMovement:clbk_inventory(unit, event)
	local weapon = self._ext_inventory:equipped_unit()
	if weapon then
		if self._weapon_hold then
			self._machine:set_global(self._weapon_hold, 0)
		end
		if self._weapon_anim_global then
			self._machine:set_global(self._weapon_anim_global, 0)
		end
		local weap_tweak = weapon:base():weapon_tweak_data()
		local weapon_hold = weap_tweak.hold
		self._machine:set_global(weapon_hold, 1)
		self._weapon_hold = weapon_hold
		local weapon_usage = weap_tweak.usage
		self._machine:set_global(weapon_usage, 1)
		self._weapon_anim_global = weapon_usage
	end
	for _, action in ipairs(self._active_actions) do
		if action and action.on_inventory_event then
			action:on_inventory_event(event)
		end
	end
end
function CopMovement:sync_shot_blank(impact)
	local equipped_weapon = self._ext_inventory:equipped_unit()
	if equipped_weapon and equipped_weapon:base().fire_blank then
		local fire_dir
		if self._attention then
			if self._attention.unit then
				fire_dir = self._attention.unit:movement():m_head_pos() - self:m_head_pos()
				mvector3.normalize(fire_dir)
			else
				fire_dir = self._attention.pos - self:m_head_pos()
				mvector3.normalize(fire_dir)
			end
		else
			fire_dir = self._action_common_data.fwd
		end
		equipped_weapon:base():fire_blank(fire_dir, impact)
	end
end
function CopMovement:sync_taser_fire()
	local tase_action = self._active_actions[3]
	if tase_action and tase_action:type() == "tase" and not tase_action:expired() then
		tase_action:fire_taser()
	end
end
function CopMovement:save(save_data)
	local my_save_data = {}
	if self._stance.transition then
		my_save_data.stance = self._stance.transition.end_values
	elseif self._stance.values[1] ~= 1 then
		my_save_data.stance = self._stance.values
	end
	for _, action in ipairs(self._active_actions) do
		if action and action.save then
			local action_save_data = {}
			action:save(action_save_data)
			if next(action_save_data) then
				my_save_data.actions = my_save_data.actions or {}
				table.insert(my_save_data.actions, action_save_data)
			end
		end
	end
	if self._allow_fire then
		my_save_data.allow_fire = true
	end
	if self._attention then
		if self._attention.pos then
			my_save_data.attention = self._attention
		elseif self._attention.unit:id() == -1 then
			my_save_data.attention = {
				pos = self._attention.unit:movement():m_com()
			}
		else
			managers.enemy:add_delayed_clbk("clbk_sync_attention" .. tostring(self._unit:key()), callback(self, self, "clbk_sync_attention", {
				self._unit,
				self._attention.unit
			}), TimerManager:game():time() + 0.1)
		end
	end
	if self._equipped_gadgets then
		local equipped_items = {}
		my_save_data.equipped_gadgets = equipped_items
		local function _get_item_type_from_unit(item_unit)
			local wanted_item_name = item_unit:name()
			for item_type, item_unit_names in pairs(self._gadgets) do
				for i_item_unit_name, item_unit_name in ipairs(item_unit_names) do
					if item_unit_name == wanted_item_name then
						return item_type
					end
				end
			end
		end
		local function _is_item_droppable(item_unit)
			if not self._droppable_gadgets then
				return
			end
			local wanted_item_key = item_unit:key()
			for _, droppable_unit in ipairs(self._droppable_gadgets) do
				if droppable_unit:key() == wanted_item_key then
					return true
				end
			end
		end
		for align_place, item_list in pairs(self._equipped_gadgets) do
			for i_item, item_unit in ipairs(item_list) do
				if alive(item_unit) then
					table.insert(equipped_items, {
						_get_item_type_from_unit(item_unit),
						align_place,
						_is_item_droppable(item_unit)
					})
				end
			end
		end
	end
	if next(my_save_data) then
		save_data.movement = my_save_data
	end
end
function CopMovement:load(load_data)
	local my_load_data = load_data.movement
	if not my_load_data then
		return
	end
	local res = self:play_redirect("idle")
	if not res then
		debug_pause_unit(self._unit, "[CopMovement:load] failed idle redirect in ", self._machine:segment_state(Idstring("base")), self._unit)
	end
	self._allow_fire = my_load_data.allow_fire
	self._attention = my_load_data.attention
	if my_load_data.stance then
		for i_stance, v in ipairs(my_load_data.stance) do
			if 0 < v then
				self:_change_stance(i_stance)
			end
		end
	end
	if my_load_data.actions then
		for _, action_load_data in ipairs(my_load_data.actions) do
			self:action_request(action_load_data)
		end
	end
	if my_load_data.equipped_gadgets then
		for _, item_desc in ipairs(my_load_data.equipped_gadgets) do
			self:_equip_item(unpack(item_desc))
		end
	end
end
function CopMovement:tweak_data_clbk_reload()
	self._tweak_data = tweak_data.character[self._ext_base._tweak_table]
	self._action_common_data.char_tweak = self._tweak_data
end
function CopMovement:_chk_start_queued_action()
	local queued_actions = self._queued_actions
	while next(queued_actions) do
		local action_desc = queued_actions[1]
		if self:chk_action_forbidden(action_desc) then
			break
		else
			if action_desc.type == "walk" or action_desc.type == "spooc" then
				action_desc.nav_path[action_desc.path_index or 1] = mvector3.copy(self._m_pos)
			end
			table.remove(queued_actions, 1)
			CopMovement.action_request(self, action_desc)
		end
	end
end
function CopMovement:_push_back_queued_action(action_desc)
	table.insert(self._queued_actions, action_desc)
end
function CopMovement:_push_front_queued_action(action_desc)
	table.insert(self._queued_actions, 1, action_desc)
end
function CopMovement:_cancel_latest_action(search_type, explicit)
	for i = #self._queued_actions, 1, -1 do
		if self._queued_actions[i].type == search_type then
			table.remove(self._queued_actions, i)
			return
		end
	end
	for body_part, action in ipairs(self._active_actions) do
		if action and action:type() == search_type then
			self._active_actions[body_part] = false
			if action.on_exit then
				action:on_exit()
			end
			self:_chk_start_queued_action()
			self._ext_brain:action_complete_clbk(action)
			return
		end
	end
	if explicit then
		debug_pause("[CopMovement:_cancel_latest_action] no queued or ongoing ", search_type, "action", self._unit, inspect(self._queued_actions), inspect(self._active_actions))
	end
end
function CopMovement:_get_latest_walk_action()
	for i = #self._queued_actions, 1, -1 do
		if self._queued_actions[i].type == "walk" and self._queued_actions[i].persistent then
			return self._queued_actions[i], true
		end
	end
	if self._active_actions[2] and self._active_actions[2]:type() == "walk" then
		return self._active_actions[2]
	end
	debug_pause("[CopMovement:_get_latest_walk_action] no queued or ongoing walk action", self._unit, inspect(self._queued_actions), inspect(self._active_actions))
end
function CopMovement:_get_latest_act_action()
	for i = #self._queued_actions, 1, -1 do
		if self._queued_actions[i].type == "act" and not self._queued_actions[i].host_expired then
			return self._queued_actions[i], true
		end
	end
	if self._active_actions[1] and self._active_actions[1]:type() == "act" then
		return self._active_actions[1]
	end
end
function CopMovement:sync_action_walk_nav_point(pos)
	local walk_action, is_queued = self:_get_latest_walk_action()
	if is_queued then
		table.insert(walk_action.nav_path, pos)
	elseif walk_action then
		walk_action:append_nav_point(pos)
	else
		debug_pause("[CopMovement:sync_action_walk_nav_point] no walk action!!!", self._unit, pos)
	end
end
function CopMovement:sync_action_walk_nav_link(pos, rot, anim_index, from_idle)
	local nav_link = self._actions.walk.synthesize_nav_link(pos, rot, self._actions.act:_get_act_name_from_index(anim_index), from_idle)
	local walk_action, is_queued = self:_get_latest_walk_action()
	if is_queued then
		function nav_link.element.value(element, name)
			return element[name]
		end
		function nav_link.element.nav_link_wants_align_pos(element)
			return element.from_idle
		end
		table.insert(walk_action.nav_path, nav_link)
	elseif walk_action then
		walk_action:append_nav_point(nav_link)
	else
		debug_pause("[CopMovement:sync_action_walk_nav_link] no walk action!!!", self._unit, pos, rot, anim_index)
	end
end
function CopMovement:sync_action_walk_stop(pos)
	local walk_action, is_queued = self:_get_latest_walk_action()
	if is_queued then
		if not walk_action.nav_path[#walk_action.nav_path].x then
			walk_action.nav_path[#walk_action.nav_path] = self._actions.walk._nav_point_pos(walk_action.nav_path[#walk_action.nav_path])
		end
		table.insert(walk_action.nav_path, pos)
		walk_action.persistent = nil
	elseif walk_action then
		walk_action:stop(pos)
	else
		debug_pause("[CopMovement:sync_action_walk_stop] no walk action!!!", self._unit, pos)
	end
end
function CopMovement:_get_latest_spooc_action()
	if self._queued_actions then
		for i = #self._queued_actions, 1, -1 do
			if self._queued_actions[i].type == "spooc" and not self._queued_actions[i].stop_pos then
				return self._queued_actions[i], true
			end
		end
	end
	if self._active_actions[1] and self._active_actions[1]:type() == "spooc" then
		return self._active_actions[1]
	end
end
function CopMovement:sync_action_spooc_nav_point(pos)
	local spooc_action, is_queued = self:_get_latest_spooc_action()
	if is_queued then
		if not spooc_action.stop_pos or spooc_action.nr_expected_nav_points then
			table.insert(spooc_action.nav_path, pos)
			if spooc_action.nr_expected_nav_points then
				if spooc_action.nr_expected_nav_points == 1 then
					spooc_action.nr_expected_nav_points = nil
					table.insert(spooc_action.nav_path, spooc_action.stop_pos)
				else
					spooc_action.nr_expected_nav_points = spooc_action.nr_expected_nav_points - 1
				end
			end
		end
	elseif spooc_action then
		spooc_action:sync_append_nav_point(pos)
	end
end
function CopMovement:sync_action_spooc_stop(pos, nav_index)
	local spooc_action, is_queued = self:_get_latest_spooc_action()
	if is_queued then
		if spooc_action.host_stop_pos_inserted then
			nav_index = nav_index + spooc_action.host_stop_pos_inserted
		end
		local nav_path = spooc_action.nav_path
		while nav_index < #nav_path do
			table.remove(nav_path)
		end
		spooc_action.stop_pos = pos
		if #nav_path < nav_index - 1 then
			spooc_action.nr_expected_nav_points = nav_index - #nav_path + 1
		else
			table.insert(nav_path, pos)
			spooc_action.path_index = math.max(1, math.min(spooc_action.path_index, #nav_path - 1))
		end
	elseif spooc_action then
		spooc_action:sync_stop(pos, nav_index)
	end
end
function CopMovement:sync_action_spooc_strike(pos)
	local spooc_action, is_queued = self:_get_latest_spooc_action()
	if is_queued then
		if spooc_action.stop_pos and not spooc_action.nr_expected_nav_points then
			return
		end
		table.insert(spooc_action.nav_path, pos)
		spooc_action.strike = true
	elseif spooc_action then
		spooc_action:sync_strike(pos)
	end
end
function CopMovement:sync_action_tase_end()
	self:_cancel_latest_action("tase", true)
end
function CopMovement:sync_pose(pose_code)
	if self._ext_damage:dead() then
		return
	end
	local pose = pose_code == 1 and "stand" or "crouch"
	local new_action_data = {type = pose, body_part = 4}
	self:action_request(new_action_data)
end
function CopMovement:sync_action_act_start(index, blocks_hurt, start_rot, start_pos)
	if self._ext_damage:dead() then
		return
	end
	local redir_name = self._actions.act:_get_act_name_from_index(index)
	local action_data = {
		type = "act",
		body_part = 1,
		variant = redir_name,
		blocks = {
			act = -1,
			walk = -1,
			action = -1,
			idle = -1
		},
		start_rot = start_rot,
		start_pos = start_pos
	}
	if blocks_hurt then
		action_data.blocks.light_hurt = -1
		action_data.blocks.hurt = -1
		action_data.blocks.heavy_hurt = -1
	end
	self:action_request(action_data)
end
function CopMovement:sync_action_act_end()
	local act_action, queued = self:_get_latest_act_action()
	if queued then
		act_action.host_expired = true
	elseif act_action then
		self._active_actions[1] = false
		if act_action.on_exit then
			act_action:on_exit()
		end
		self:_chk_start_queued_action()
		self._ext_brain:action_complete_clbk(act_action)
	end
end
function CopMovement:sync_action_dodge_start(var, dir, rot)
	if self._ext_damage:dead() then
		return
	end
	local action_data = {
		type = "dodge",
		body_part = 1,
		variation = var,
		direction = dir,
		rotation = rot
	}
	self:action_request(action_data)
end
function CopMovement:sync_action_dodge_end()
	self:_cancel_latest_action("dodge")
end
function CopMovement:sync_action_aim_end()
	self:_cancel_latest_action("shoot", true)
end
function CopMovement:sync_action_hurt_end()
	for i = #self._queued_actions, 1, -1 do
		if self._queued_actions[i].type == "hurt" then
			table.remove(self._queued_actions, i)
			return
		end
	end
	local action = self._active_actions[1]
	if action and action:type() == "hurt" then
		self._active_actions[1] = false
		if action.on_exit then
			action:on_exit()
		end
		local hurt_type = action:hurt_type()
		if hurt_type == "bleedout" or hurt_type == "fatal" then
			local action_data = {
				type = "act",
				body_part = 1,
				variant = "stand",
				client_interrupt = true,
				blocks = {
					action = -1,
					walk = -1,
					hurt = -1,
					aim = -1,
					hurt = -1,
					heavy_hurt = -1,
					light_hurt = -1,
					stand = -1,
					crouch = -1
				}
			}
			local res = CopMovement.action_request(self, action_data)
		else
			self:_chk_start_queued_action()
			self._ext_brain:action_complete_clbk(action)
		end
		return
	end
	debug_pause("[CopMovement:sync_action_hurt_end] no queued or ongoing hurt action", self._unit, inspect(self._queued_actions), inspect(self._active_actions))
end
function CopMovement:enable_update(force_head_upd)
	if not self._need_upd then
		self._unit:set_extension_update_enabled(ids_movement, true)
		self._need_upd = true
		self._force_head_upd = force_head_upd
	end
end
function CopMovement:ground_ray()
	return self._gnd_ray
end
function CopMovement:on_nav_link_unregistered(element_id)
	for body_part, action in pairs(self._active_actions) do
		if action and action.on_nav_link_unregistered then
			action:on_nav_link_unregistered(element_id)
		end
	end
end
function CopMovement:pre_destroy()
	tweak_data:remove_reload_callback(self)
	if alive(self._rope) then
		self._rope:base():retract()
		self._rope = nil
	end
	if self._nav_tracker then
		managers.navigation:destroy_nav_tracker(self._nav_tracker)
		self._nav_tracker = nil
	end
	if self._pos_rsrv_id then
		managers.navigation:release_pos_reservation_id(self._pos_rsrv_id)
		self._pos_rsrv_id = nil
	end
	if self._link_data then
		self._link_data.parent:base():remove_destroy_listener("CopMovement" .. tostring(unit:key()))
	end
	self:_destroy_gadgets()
	for i_action, action in ipairs(self._active_actions) do
		if action and action.on_destroy then
			action:on_destroy()
		end
	end
	if self._attention and self._attention.destroy_listener_key then
		self._attention.unit:base():remove_destroy_listener(self._attention.destroy_listener_key)
		self._attention.destroy_listener_key = nil
	end
end
function CopMovement:on_anim_act_clbk(anim_act)
	for body_part, action in ipairs(self._active_actions) do
		if action and action.anim_act_clbk then
			action:anim_act_clbk(anim_act)
		end
	end
end
function CopMovement:clbk_sync_attention(data)
	local my_unit = data[1]
	local attention_unit = data[2]
	if alive(my_unit) and self._attention and self._attention.unit and self._attention.unit:key() == attention_unit:key() and attention_unit:id() ~= -1 then
		self._ext_network:send("cop_set_attention_unit", attention_unit)
	end
end
