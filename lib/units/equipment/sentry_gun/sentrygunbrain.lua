local mvec3_dir = mvector3.direction
local mvec3_dot = mvector3.dot
local math_max = math.max
local tmp_vec1 = Vector3()
SentryGunBrain = SentryGunBrain or class()
function SentryGunBrain:init(unit)
	self._unit = unit
	self._active = false
	self._unit:set_extension_update_enabled(Idstring("brain"), false)
	self._AI_data = {
		detected_enemies = {},
		detection = {
			dis_max = tweak_data.weapon.sentry_gun.DETECTION_RANGE
		}
	}
	self._eye_object_pos = self._unit:get_object(Idstring("a_detect")):position()
	self._visibility_slotmask = managers.slot:get_mask("AI_visibility_sentry_gun")
	self._firing = false
end
function SentryGunBrain:post_init()
	self._ext_movement = self._unit:movement()
	self._m_head_object_pos = self._ext_movement:m_head_pos()
end
function SentryGunBrain:update(unit, t, dt)
	if Network:is_server() then
		self:_chk_enemies_valid(t)
		self:_chk_focus_enemy_valid()
		self:_choose_focus_enemy()
	end
	self:_check_fire(t)
end
function SentryGunBrain:is_active()
	return self._active
end
function SentryGunBrain:set_active(state)
	state = state and true or false
	if self._active == state then
		return
	end
	self._unit:set_extension_update_enabled(Idstring("brain"), state)
	self._active = state
	if not state and self._firing then
		self._unit:weapon():stop_autofire()
		self._firing = false
		if Network:is_server() then
			self._unit:network():send("cop_forbid_fire")
		end
	end
end
function SentryGunBrain:_chk_focus_enemy_valid()
	local focus_enemy = self._AI_data.focus_enemy
	if not focus_enemy then
		return
	end
	if not focus_enemy.verified and (not focus_enemy.verified_t or t - focus_enemy.verified_t > tweak_data.weapon.sentry_gun.LOST_SIGHT_VERIFICATION) or focus_enemy.unit:brain()._current_logic_name == "trade" then
		self._AI_data.focus_enemy = nil
		self._ext_movement:set_attention()
	end
end
function SentryGunBrain:_chk_enemies_valid(t)
	for e_key, enemy_data in pairs(self._AI_data.detected_enemies) do
		if enemy_data.death_verify_t and t > enemy_data.death_verify_t then
			self._AI_data.detected_enemies[e_key] = nil
			if enemy_data == self._AI_data.focus_enemy then
				self._AI_data.focus_enemy = nil
				self._ext_movement:set_attention()
			end
		end
	end
end
function SentryGunBrain:_choose_focus_enemy(t)
	local delay = 1
	local enemies = managers.enemy:all_enemies()
	local my_tracker = self._unit:movement():nav_tracker()
	local chk_vis_func = my_tracker.check_visibility
	local my_pos = self._m_head_object_pos
	for e_key, enemy_data in pairs(enemies) do
		local enemy_unit = enemy_data.unit
		if enemy_unit:brain()._current_logic_name == "trade" then
			self._AI_data.detected_enemies[e_key] = nil
		elseif self._AI_data.detected_enemies[e_key] then
			local enemy_data = self._AI_data.detected_enemies[e_key]
			local visible
			local enemy_pos = enemy_data.m_com
			local vis_ray = World:raycast("ray", my_pos, enemy_pos, "slot_mask", self._visibility_slotmask, "ray_type", "ai_vision", "report")
			if not vis_ray then
				visible = true
			end
			enemy_data.verified = visible
			if visible then
				delay = math.min(0.6, delay)
				enemy_data.verified_t = t
				enemy_data.verified_dis = mvector3.distance(enemy_pos, my_pos)
			elseif not enemy_data.verified_t or t - enemy_data.verified_t > 3 then
				enemy_unit:base():remove_destroy_listener(enemy_data.destroy_clbk_key)
				enemy_unit:character_damage():remove_listener(enemy_data.death_clbk_key)
				self._AI_data.detected_enemies[e_key] = nil
			end
		elseif chk_vis_func(my_tracker, enemy_data.tracker) then
			local my_pos = self._m_head_object_pos
			local enemy_pos = enemy_unit:movement():m_head_pos()
			local enemy_dis = mvector3.distance(enemy_pos, my_pos)
			local dis_multiplier
			dis_multiplier = enemy_dis / self._AI_data.detection.dis_max
			if dis_multiplier < 1 then
				delay = math.min(delay, dis_multiplier)
				if not World:raycast("ray", my_pos, enemy_pos, "slot_mask", self._visibility_slotmask, "ray_type", "ai_vision", "report") then
					local enemy_data = self:_create_enemy_detection_data(enemy_unit)
					enemy_data.verified_t = t
					enemy_data.verified = true
					self._AI_data.detected_enemies[e_key] = enemy_data
				end
			end
		end
	end
	local focus_enemy = self._AI_data.focus_enemy
	local cam_fwd
	if focus_enemy then
		cam_fwd = tmp_vec1
		mvec3_dir(cam_fwd, my_pos, focus_enemy.m_com)
	else
		cam_fwd = self._ext_movement:m_head_fwd()
	end
	local max_dis = 15000
	local function _get_weight(enemy_data)
		local dis = mvec3_dir(tmp_vec1, my_pos, enemy_data.m_com)
		local dis_weight = math_max(0, (max_dis - dis) / max_dis)
		local dot_weight = 1 + mvec3_dot(tmp_vec1, cam_fwd)
		return dot_weight * dot_weight * dot_weight * dis_weight
	end
	local focus_enemy_weight
	if focus_enemy then
		focus_enemy_weight = _get_weight(focus_enemy) * 4
	end
	for e_key, enemy_data in pairs(self._AI_data.detected_enemies) do
		if not enemy_data.death_verify_t then
			local weight = _get_weight(enemy_data)
			if not focus_enemy_weight or focus_enemy_weight < weight then
				focus_enemy_weight = weight
				focus_enemy = enemy_data
			end
		end
	end
	if self._AI_data.focus_enemy ~= focus_enemy then
		if focus_enemy then
			local attention = {
				unit = focus_enemy.unit
			}
			self._ext_movement:set_attention(attention)
		else
			self._ext_movement:set_attention()
		end
		self._AI_data.focus_enemy = focus_enemy
	end
	return delay
end
function SentryGunBrain:_create_enemy_detection_data(enemy_unit, suspected)
	local destroy_clbk_key = "SentryGunBase" .. tostring(self._unit:key())
	enemy_unit:base():add_destroy_listener(destroy_clbk_key, callback(self, self, "on_enemy_destroyed"))
	enemy_unit:character_damage():add_listener(destroy_clbk_key, {"death"}, callback(self, self, "on_enemy_killed"))
	local enemy_m_pos = enemy_unit:movement():m_pos()
	local enemy_m_head_pos = enemy_unit:movement():m_head_pos()
	local enemy_data = {
		key = enemy_unit:key(),
		unit = enemy_unit,
		m_pos = enemy_m_pos,
		m_head_pos = enemy_m_head_pos,
		m_com = enemy_unit:movement():m_com(),
		verified_t = false,
		verified = false,
		destroy_clbk_key = destroy_clbk_key,
		death_clbk_key = destroy_clbk_key
	}
	return enemy_data
end
function SentryGunBrain:_check_fire(t)
	if Network:is_client() then
		if self._firing then
			self._unit:weapon():trigger_held(true, false)
		end
		return
	end
	local focus_enemy = self._AI_data.focus_enemy
	if self._unit:weapon():out_of_ammo() then
		self:switch_off()
	elseif focus_enemy and not self._ext_movement:warming_up(t) then
		if self._firing then
			self._unit:weapon():trigger_held(false, true)
		else
			mvec3_dir(tmp_vec1, self._eye_object_pos, focus_enemy.m_com)
			if mvec3_dot(tmp_vec1, self._ext_movement:m_head_fwd()) > tweak_data.weapon.sentry_gun.KEEP_FIRE_ANGLE then
				self._unit:weapon():start_autofire()
				self._unit:weapon():trigger_held(false, true)
				self._firing = true
				self._unit:network():send("cop_allow_fire")
			end
		end
	elseif self._firing then
		self._unit:weapon():stop_autofire()
		self._firing = false
		self._unit:network():send("cop_forbid_fire")
	end
end
function SentryGunBrain:on_enemy_destroyed(destroyed_unit)
	local destroyed_unit_key = destroyed_unit:key()
	self._AI_data.detected_enemies[destroyed_unit_key] = nil
	if self._AI_data.focus_enemy and self._AI_data.focus_enemy.key == destroyed_unit_key then
		self._AI_data.focus_enemy = nil
	end
end
function SentryGunBrain:on_enemy_killed(killed_unit)
	local killed_unit_key = killed_unit:key()
	if self._AI_data.detected_enemies[killed_unit_key] then
		local verif_data = tweak_data.weapon.sentry_gun.DEATH_VERIFICATION
		self._AI_data.detected_enemies[killed_unit_key].death_verify_t = TimerManager:game():time() + math.lerp(verif_data[1], verif_data[2], math.random())
	end
end
function SentryGunBrain:synch_allow_fire(state)
	if state and not self._firing then
		self._unit:weapon():start_autofire()
		self._unit:weapon():trigger_held(true, false)
	elseif not state then
		if self._unit:weapon():out_of_ammo() then
			self:switch_off()
		elseif self._firing then
			self._unit:weapon():stop_autofire()
		end
	end
	self._firing = state
end
function SentryGunBrain:switch_off()
	self._unit:damage():run_sequence_simple("laser_off")
	local is_server = Network:is_server()
	if is_server then
		self._ext_movement:set_attention()
	end
	self:set_active(false)
	self._ext_movement:switch_off()
	self._unit:set_slot(26)
	managers.groupai:state():on_criminal_neutralized(self._unit)
end
function SentryGunBrain:save(save_data)
	local my_save_data = {}
	if self._firing then
		my_save_data.firing = true
	end
	if next(my_save_data) then
		save_data.brain = my_save_data
	end
end
function SentryGunBrain:load(save_data)
	if not save_data or not save_data.brain then
		return
	end
	if save_data.brain.firing then
		self:synch_allow_fire(true)
	end
end
function SentryGunBrain:pre_destroy()
	for key, enemy_data in pairs(self._AI_data.detected_enemies) do
		enemy_data.unit:base():remove_destroy_listener(enemy_data.destroy_clbk_key)
	end
	self:set_active(false)
end
