CopActionTase = CopActionTase or class()
local temp_vec1 = Vector3()
local temp_vec2 = Vector3()
function CopActionTase:init(action_desc, common_data)
	self._common_data = common_data
	self._ext_movement = common_data.ext_movement
	self._ext_anim = common_data.ext_anim
	self._ext_brain = common_data.ext_brain
	self._ext_inventory = common_data.ext_inventory
	self._body_part = action_desc.body_part
	self._machine = common_data.machine
	self._modifier_name = Idstring("action_upper_body")
	self._modifier = self._machine:get_modifier(self._modifier_name)
	local attention = common_data.attention
	if (not attention or not attention.unit) and Network:is_server() then
		debug_pause("[CopActionTase:init] no attention", inspect(action_desc))
		return
	end
	local weapon_unit = self._ext_inventory:equipped_unit()
	self:on_attention(attention)
	if Network:is_server() then
		self._ext_movement:set_stance_by_code(3)
	end
	self._tase_effect_table = {
		effect = Idstring("effects/particles/weapons/taser_thread"),
		parent = weapon_unit:get_object(Idstring("fire")),
		force_synch = true
	}
	CopActionAct._create_blocks_table(self, action_desc.block_desc)
	return true
end
function CopActionTase:expired()
	return self._expired
end
function CopActionTase:on_attention(attention)
	if Network:is_server() and self._attention then
		self._attention = attention
		self._expired = true
		self.update = self._upd_empty
		return
	elseif not attention or not attention.unit then
		self.update = self._upd_empty
		return
	elseif self._attention then
		return
	end
	local attention_unit = attention.unit
	self.update = nil
	local weapon_unit = self._ext_inventory:equipped_unit()
	local weap_tweak = weapon_unit:base():weapon_tweak_data()
	local weapon_usage_tweak = self._common_data.char_tweak.weapon[weap_tweak.usage]
	self._weap_tweak = weap_tweak
	self._w_usage_tweak = weapon_usage_tweak
	self._falloff = weapon_usage_tweak.FALLOFF
	self._turn_allowed = Network:is_client()
	self._attention = attention
	local t = TimerManager:game():time()
	local target_pos = attention_unit:movement():m_head_pos()
	local focus_error_roll = math.random(360)
	local shoot_hist = self._shoot_history
	if shoot_hist then
		shoot_hist.focus_error_roll = focus_error_roll
		local displacement = mvector3.distance(target_pos, shoot_hist.m_last_pos)
		local focus_delay = weapon_usage_tweak.focus_delay * math.min(1, displacement / weapon_usage_tweak.focus_dis)
		shoot_hist.focus_start_t = t
		shoot_hist.focus_delay = focus_delay
		shoot_hist.m_last_pos = mvector3.copy(target_pos)
	else
		shoot_hist = {
			focus_error_roll = focus_error_roll,
			focus_start_t = t,
			focus_delay = weapon_usage_tweak.focus_delay,
			m_last_pos = mvector3.copy(target_pos)
		}
		self._shoot_history = shoot_hist
	end
	local shoot_from_pos = self._ext_movement:m_head_pos()
	local target_vec = target_pos - shoot_from_pos
	self._modifier:set_target_y(target_vec)
	local aim_delay = weapon_usage_tweak.aim_delay_tase or weapon_usage_tweak.aim_delay
	local lerp_dis = math.min(1, target_vec:length() / self._falloff[#self._falloff].r)
	local shoot_delay = math.lerp(aim_delay[1], aim_delay[2], lerp_dis)
	self._mod_enable_t = t + shoot_delay
	if Network:is_server() then
		self._common_data.ext_network:send("action_tase_start")
		if not attention_unit:base().is_husk_player then
			self._shoot_t = TimerManager:game():time() + shoot_delay
			self._tasing_local_unit = attention_unit
			self._line_of_fire_slotmask = managers.slot:get_mask("bullet_impact_targets_no_criminals")
			self._tasing_player = attention_unit:base().is_local_player
		end
	elseif attention_unit:base().is_local_player then
		self._shoot_t = TimerManager:game():time() + shoot_delay
		self._tasing_local_unit = attention_unit
		self._line_of_fire_slotmask = managers.slot:get_mask("bullet_impact_targets")
		self._tasing_player = true
	end
end
function CopActionTase:save(save_data)
	save_data.type = "tase"
	save_data.body_part = self._body_part
end
function CopActionTase:on_exit()
	if self._tase_effect then
		World:effect_manager():fade_kill(self._tase_effect)
	end
	if self._discharging and alive(self._tasing_local_unit) then
		self._tasing_local_unit:movement():on_tase_ended()
	end
	if Network:is_server() then
		self._ext_movement:set_stance_by_code(2)
	end
	if self._modifier_on then
		self._machine:allow_modifier(self._modifier_name)
	end
	if Network:is_server() then
		self._common_data.unit:network():send("action_tase_end")
		if self._expired then
			self._ext_movement:action_request({type = "idle", body_part = 3})
		end
	end
	if self._tasered_sound then
		self._tasered_sound:stop()
		self._common_data.unit:sound():play("tasered_3rd_stop", nil)
	end
end
function CopActionTase:update(t)
	if self._expired then
		return
	end
	local shoot_from_pos = self._ext_movement:m_head_pos()
	local target_dis
	local target_vec = temp_vec1
	local target_pos = temp_vec2
	self._attention.unit:character_damage():shoot_pos_mid(target_pos)
	mvector3.set(target_vec, target_pos)
	mvector3.subtract(target_vec, shoot_from_pos)
	target_dis = mvector3.normalize(target_vec)
	local target_vec_flat = target_vec:with_z(0)
	mvector3.normalize(target_vec_flat)
	local fwd_dot = mvector3.dot(self._common_data.fwd, target_vec_flat)
	if 0.7 < fwd_dot then
		if not self._modifier_on then
			self._modifier_on = true
			self._machine:force_modifier(self._modifier_name)
			self._mod_enable_t = t + 0.5
		end
		self._modifier:set_target_y(target_vec)
	else
		if self._modifier_on then
			self._modifier_on = nil
			self._machine:allow_modifier(self._modifier_name)
		end
		if self._turn_allowed and not self._ext_anim.walk and not self._ext_anim.turn and not self._ext_movement:chk_action_forbidden("walk") then
			local spin = target_vec:to_polar_with_reference(self._common_data.fwd, math.UP).spin
			local abs_spin = math.abs(spin)
			if 27 < abs_spin then
				local new_action_data = {}
				new_action_data.type = "turn"
				new_action_data.body_part = 2
				new_action_data.angle = spin
				self._ext_movement:action_request(new_action_data)
			end
		end
		target_vec = nil
	end
	if self._ext_anim.reload or self._ext_anim.equip then
	elseif self._discharging then
		if not self._tasing_local_unit:movement():tased() then
			if Network:is_server() then
				self._expired = true
			end
			self._discharging = nil
		end
	elseif self._shoot_t and target_vec and self._common_data.allow_fire and t > self._shoot_t and t > self._mod_enable_t then
		if self._tase_effect then
			World:effect_manager():fade_kill(self._tase_effect)
		end
		self._tase_effect = World:effect_manager():spawn(self._tase_effect_table)
		if self._tasing_local_unit and mvector3.distance(shoot_from_pos, target_pos) < self._w_usage_tweak.tase_distance then
			local record = managers.groupai:state():criminal_record(self._tasing_local_unit:key())
			if record.status or self._tasing_local_unit:movement():chk_action_forbidden("hurt") then
				if Network:is_server() then
					self._expired = true
				end
			else
				local vis_ray = self._common_data.unit:raycast("ray", shoot_from_pos, target_pos, "slot_mask", self._line_of_fire_slotmask, "ignore_unit", self._tasing_local_unit)
				if not vis_ray then
					self._common_data.ext_network:send("action_tase_fire")
					local attack_data = {
						attacker_unit = self._common_data.unit
					}
					self._attention.unit:character_damage():damage_tase(attack_data)
					self._discharging = true
					if not self._tasing_local_unit:base().is_local_player then
						self._tasered_sound = self._common_data.unit:sound():play("tasered_3rd", nil)
					end
					local redir_res = self._ext_movement:play_redirect("recoil")
					if redir_res then
						self._machine:set_parameter(redir_res, "hvy", 0)
					end
					self._shoot_t = nil
				end
			end
		elseif not self._tasing_local_unit then
			self._tasered_sound = self._common_data.unit:sound():play("tasered_3rd", nil)
			local redir_res = self._ext_movement:play_redirect("recoil")
			if redir_res then
				self._machine:set_parameter(redir_res, "hvy", 0)
			end
			self._shoot_t = nil
		end
	end
end
function CopActionTase:type()
	return "tase"
end
function CopActionTase:fire_taser()
	self._shoot_t = 0
end
function CopActionTase:chk_block(action_type, t)
	return CopActionAct.chk_block(self, action_type, t)
end
function CopActionTase:_upd_empty(t)
end
function CopActionTase:need_upd()
	return true
end
function CopActionTase:get_husk_interrupt_desc()
	local action_desc = {
		type = "tase",
		body_part = 3,
		block_type = "action"
	}
	return action_desc
end
