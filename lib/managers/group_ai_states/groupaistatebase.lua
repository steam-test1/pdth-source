GroupAIStateBase = GroupAIStateBase or class()
GroupAIStateBase._nr_important_cops = 3
function GroupAIStateBase:init()
	Global.criminal_team_AI_disabled = not Global.game_settings.team_ai
	self:_init_misc_data()
end
function GroupAIStateBase:update(t, dt)
	self._t = t
	if self._draw_drama then
		self:_debug_draw_drama(t)
	end
end
function GroupAIStateBase:paused_update(t, dt)
	if self._draw_drama then
		self:_debug_draw_drama(self._t)
	end
end
function GroupAIStateBase:get_assault_mode()
	return self._assault_mode
end
function GroupAIStateBase:get_hunt_mode()
	return self._hunt_mode
end
function GroupAIStateBase:is_AI_enabled()
	return self._ai_enabled
end
function GroupAIStateBase:set_AI_enabled(state)
	self._ai_enabled = state
	self._forbid_drop_in = state
	if Network:is_server() then
		for u_key, u_data in pairs(managers.enemy:all_enemies()) do
			local is_active = u_data.unit:brain():is_active()
			if state and not is_active or not state and is_active then
				u_data.unit:brain():set_active(state)
			end
		end
		for u_key, u_data in pairs(self._criminals) do
			if u_data.ai then
				local is_active = u_data.unit:brain():is_active()
				if state and not is_active or not state and is_active then
					u_data.unit:brain():set_active(state)
				end
			end
		end
		for u_key, u_data in pairs(managers.enemy:all_civilians()) do
			local is_active = u_data.unit:brain():is_active()
			if state and not is_active or not state and is_active then
				u_data.unit:brain():set_active(state)
			end
		end
	end
	managers.enemy:dispose_all_corpses()
	if not state then
		for u_key, u_data in pairs(managers.enemy:all_enemies()) do
			Network:detach_unit(u_data.unit)
			u_data.unit:base():set_slot(u_data.unit, 0)
		end
		for u_key, u_data in pairs(self._criminals) do
			if u_data.ai then
				Network:detach_unit(u_data.unit)
				u_data.unit:base():set_slot(u_data.unit, 0)
			elseif u_data.is_deployable then
				u_data.unit:base():set_slot(u_data.unit, 0)
			end
		end
		for u_key, u_data in pairs(managers.enemy:all_civilians()) do
			Network:detach_unit(u_data.unit)
			u_data.unit:base():set_slot(u_data.unit, 0)
		end
		for _, char in ipairs(managers.criminals:characters()) do
			if char.ai == false and alive(char.unit) then
				Network:detach_unit(char.unit)
				unit:set_extension_update_enabled(Idstring("movement"), false)
			end
		end
		local all_weapons = World:find_units_quick("all", 13)
		local local_player = managers.player:player_unit()
		local player_weapon_key
		if alive(local_player) then
			local equipped_weapon = local_player:inventory():equipped_unit()
			if alive(equipped_weapon) then
				player_weapon_key = equipped_weapon:key()
			end
		end
		for _, weapon_unit in ipairs(all_weapons) do
			if player_weapon_key ~= weapon_unit:key() then
				weapon_unit:set_slot(0)
			end
		end
	end
end
function GroupAIStateBase:_init_misc_data()
	self._t = TimerManager:game():time()
	self:_parse_teammate_comments()
	self._is_server = Network:is_server()
	self._spawn_points = {}
	self._flee_points = {}
	self._hostage_data = {}
	self._spawn_events = {}
	self._special_objectives = {}
	self._occasional_events = {}
	local drama_tweak = tweak_data.drama
	self._drama_data = {
		decay_period = tweak_data.drama.decay_period,
		last_calculate_t = 0,
		amount = 0,
		zone = "low",
		low_p = drama_tweak.low,
		high_p = drama_tweak.peak,
		actions = drama_tweak.drama_actions,
		max_dis = drama_tweak.max_dis,
		dis_mul = drama_tweak.max_dis_mul
	}
	self._ai_enabled = true
	self._downs_during_assault = 0
	self._hostage_headcount = 0
	self._police_hostage_headcount = 0
	self:sync_assault_mode(false)
	self._fake_assault_mode = false
	self:set_whisper_mode(false)
	self:set_bain_state(true)
	self._allow_dropin = true
	self._police = managers.enemy:all_enemies()
	self._char_criminals = {}
	self._criminals = {}
	self._ai_criminals = {}
	self._player_criminals = {}
	self._special_units = {}
	self._special_unit_types = {
		tank = true,
		spooc = true,
		shield = true,
		taser = true
	}
	self._anticipated_police_force = 0
	self._police_force = table.size(self._police)
	self._fleeing_civilians = {}
	self._hostage_keys = {}
	self._enemy_chatter = {}
	self._teamAI_last_combat_chatter_t = 0
	self:_set_rescue_state(true)
	self._criminal_AI_respawn_clbks = {}
	self._listener_holder = EventListenerHolder:new()
	self:set_difficulty(0)
	self:set_drama_draw_state(Global.drama_draw_state)
	self._alert_elements = {}
end
function GroupAIStateBase:add_alert_listener(id, element)
	self._alert_elements[id] = element
end
function GroupAIStateBase:remove_alert_listener(id)
	self._alert_elements[id] = nil
end
function GroupAIStateBase:propagate_alert(alert_data)
	local lod_entries = managers.enemy._gfx_lod_data.entries
	local entries_com = lod_entries.com
	local entries_unit = lod_entries.units
	local entries_alerted = lod_entries.alerted
	local mvec3_dis = mvector3.distance_sq
	local event_pos = alert_data[2]
	local event_rad = alert_data[3] * alert_data[3]
	for i, com in ipairs(entries_com) do
		if entries_alerted[i] and event_rad > mvec3_dis(com, event_pos) then
			entries_unit[i]:brain():on_alert(alert_data)
		end
	end
	for _, ele in pairs(self._alert_elements) do
		local ele_pos = ele:value("position")
		if event_rad > mvec3_dis(ele_pos, event_pos) then
			ele:do_synced_execute(alert_data[4], alert_data)
		end
	end
end
function GroupAIStateBase:propagate_alert_cyl(alert_data)
	local mvec3_dot = mvector3.dot
	local mvec3_set = mvector3.set
	local mvec3_sub = mvector3.subtract
	local mvec3_l_sq = mvector3.length_sq
	local lod_entries = managers.enemy._gfx_lod_data.entries
	local entries_com = lod_entries.com
	local entries_unit = lod_entries.units
	local entries_state = lod_entries.states
	local entries_alerted = lod_entries.alerted
	local head = alert_data[2]
	local tail = alert_data[3]
	local rad = alert_data[4] * alert_data[4]
	local alert_dir = head - tail
	local cyl_len = mvector3.normalize(alert_dir)
	local u_vec = Vector3()
	for i, com in ipairs(entries_com) do
		if entries_alerted[i] then
			mvec3_set(u_vec, com)
			mvec3_sub(u_vec, tail)
			local u_dot = mvec3_dot(u_vec, alert_dir)
			if cyl_len > u_dot and u_dot > 0 then
				local dis = mvec3_l_sq(u_vec) - u_dot * u_dot
				if rad > dis then
					entries_unit[i]:brain():on_alert(alert_data)
				end
			end
		end
	end
	for _, ele in pairs(self._alert_elements) do
		local ele_pos = ele:value("position")
		mvec3_set(u_vec, ele_pos)
		mvec3_sub(u_vec, tail)
		local u_dot = mvec3_dot(u_vec, alert_dir)
		if cyl_len > u_dot and u_dot > 0 then
			local dis = mvec3_l_sq(u_vec) - u_dot * u_dot
			if rad > dis then
				ele:do_synced_execute(alert_data[5], alert_data)
			end
		end
	end
end
function GroupAIStateBase:set_heat_build_period(period)
	Application:error("[GroupAIStateBase:set_heat_build_period] Heat functionality is deprecated.")
end
function GroupAIStateBase:set_drama_decay_period(period)
	self:_claculate_drama_value()
	self._drama_data.decay_period = period
	self._drama_data.last_calculate_t = self._t
end
function GroupAIStateBase:_claculate_drama_value()
	local drama_data = self._drama_data
	local dt = self._t - drama_data.last_calculate_t
	local adj = -dt / drama_data.decay_period
	drama_data.last_calculate_t = self._t
	self:_add_drama(adj)
end
function GroupAIStateBase:_add_drama(amount)
	local drama_data = self._drama_data
	local new_val = math.clamp(drama_data.amount + amount, 0, 1)
	drama_data.amount = new_val
	if new_val > drama_data.high_p then
		if drama_data.zone ~= "high" then
			drama_data.zone = "high"
			self:_on_drama_zone_change()
		end
	elseif new_val < drama_data.low_p then
		if drama_data.zone ~= "low" then
			drama_data.zone = "low"
			self:_on_drama_zone_change()
		end
	elseif drama_data.zone then
		drama_data.zone = nil
		self:_on_drama_zone_change()
	end
end
function GroupAIStateBase:_on_drama_zone_change()
end
function GroupAIStateBase:calm_ai()
	self._player_weapons_hot = false
	self._enemy_weapons_hot = false
	if Network:is_server() then
		for crim_key, crim in pairs(self:all_AI_criminals()) do
			if not crim.unit:movement():cool() then
				if not crim.unit:anim_data().stand then
					crim.unit:movement():action_request({type = "stand", body_part = 4})
				end
				if not crim.unit:anim_data().upper_body_empty then
					crim.unit:movement():action_request({
						type = "idle",
						body_part = 3,
						sync = true
					})
				end
				crim.unit:movement():set_cool()
				crim.unit:movement():set_stance_by_code(1)
				crim.unit:brain():set_objective()
				for key, data in pairs(self._police) do
					data.unit:brain():on_criminal_neutralized(crim_key)
				end
			end
		end
	end
	for crim_key, crim in pairs(self:all_char_criminals()) do
		crim.unit:inventory():set_mask_visibility(false)
	end
end
function GroupAIStateBase:on_player_weapons_hot()
	if not self._player_weapons_hot then
		self._player_weapons_hot = true
		self:_call_listeners("player_weapons_hot")
	end
end
function GroupAIStateBase:player_weapons_hot()
	return self._player_weapons_hot
end
function GroupAIStateBase:on_enemy_weapons_hot()
	if not self._enemy_weapons_hot then
		self._enemy_weapons_hot = true
		self:_call_listeners("enemy_weapons_hot")
		self._radio_clbk = callback(self, self, "_radio_chatter_clbk")
		managers.enemy:add_delayed_clbk("_radio_chatter_clbk", self._radio_clbk, Application:time() + 30)
		if not self._hstg_hint_clbk then
			self._first_hostage_hint = true
			self._hstg_hint_clbk = callback(self, self, "_hostage_hint_clbk")
			managers.enemy:add_delayed_clbk("_hostage_hint_clbk", self._hstg_hint_clbk, Application:time() + 45)
		end
	end
end
function GroupAIStateBase:enemy_weapons_hot()
	return self._enemy_weapons_hot
end
function GroupAIStateBase:_hostage_hint_clbk()
	if not self._ai_enabled then
		return
	end
	if not self._first_hostage_hint then
		self._hstg_hint_clbk = nil
	end
	if self._hostage_headcount == 0 then
		if self._first_hostage_hint then
			managers.hint:show_hint("control_civilians", nil, nil, {
				BTN_INTERACT = managers.localization:btn_macro("interact")
			})
			self._first_hostage_hint = nil
			managers.enemy:add_delayed_clbk("_hostage_hint_clbk", self._hstg_hint_clbk, Application:time() + 120)
		else
			managers.hint:show_hint("take_hostages", nil, nil, {
				BTN_INTERACT = managers.localization:btn_macro("interact")
			})
		end
	else
		self._hstg_hint_clbk = nil
	end
end
function GroupAIStateBase:_radio_chatter_clbk()
	if self._ai_enabled and not self:get_assault_mode() then
		local optimal_dist = 500
		local best_dist, best_cop, radio_msg
		for _, c_record in pairs(self._player_criminals) do
			for i, e_key in ipairs(c_record.important_enemies) do
				local cop = self._police[e_key]
				local use_radio = tweak_data.character[cop.unit:base()._tweak_table].use_radio
				if use_radio then
					local dist = math.abs(mvector3.distance(cop.m_pos, c_record.m_pos))
					if not best_dist or best_dist > dist then
						best_dist = dist
						best_cop = cop
						radio_msg = use_radio
					end
				end
			end
		end
		if best_cop then
			best_cop.unit:sound():play(radio_msg, nil, true)
		end
	end
	self._radio_clbk = callback(self, self, "_radio_chatter_clbk")
	managers.enemy:add_delayed_clbk("_radio_chatter_clbk", self._radio_clbk, Application:time() + 30 + math.random(0, 20))
end
function GroupAIStateBase:police_hostage_count()
	return self._police_hostage_headcount
end
function GroupAIStateBase:hostage_count()
	return self._hostage_headcount
end
GroupAIStateBase.PATH = "gamedata/comments"
GroupAIStateBase.FILE_EXTENSION = "comment"
GroupAIStateBase.FULL_PATH = GroupAIStateBase.PATH .. "." .. GroupAIStateBase.FILE_EXTENSION
function GroupAIStateBase:_parse_teammate_comments()
	local list = PackageManager:script_data(self.FILE_EXTENSION:id(), self.PATH:id())
	self.teammate_comments = {}
	self.teammate_comment_names = {}
	for _, data in ipairs(list) do
		if data._meta == "comment" then
			self:_parse_teammate_comment(data)
		else
			Application:error("Unknown node \"" .. tostring(data._meta) .. "\" in \"" .. self.FULL_PATH .. "\". Expected \"comment\" node.")
		end
	end
end
function GroupAIStateBase:_parse_teammate_comment(data)
	local event = data.event
	local allow = data.allow_first_person or false
	table.insert(self.teammate_comments, {event = event, allow_first_person = allow})
	table.insert(self.teammate_comment_names, event)
end
function GroupAIStateBase:teammate_comment(trigger_unit, message, pos, pos_based, radius, sync)
	if radius == 0 then
		radius = nil
	end
	local message_id
	for index, sound in ipairs(self.teammate_comment_names) do
		if sound == message then
			message_id = index
		else
		end
	end
	if not message_id then
		Application:error("[GroupAIStateBase:teammate_comment] " .. message .. " cannot be found")
		return
	end
	local allow_first_person = self.teammate_comments[message_id].allow_first_person
	local close_pos = pos_based and pos or managers.player:player_unit() and managers.player:player_unit():position() or Vector3()
	local close_criminal, close_criminal_d
	if trigger_unit and alive(trigger_unit) then
		radius = nil
		close_criminal = trigger_unit
	else
		for u_key, u_data in pairs(self._criminals) do
			if not u_data.is_deployable and (allow_first_person or not u_data.unit:base().is_local_player) and alive(u_data.unit) and not u_data.unit:movement():downed() and not u_data.unit:sound():speaking() then
				local d = mvector3.distance_sq(close_pos, u_data.m_pos)
				local ed = radius and (pos_based and d or mvector3.distance_sq(pos, u_data.m_pos))
				if (not radius or ed < radius * radius) and (not close_criminal_d or close_criminal_d > d) then
					close_criminal = u_data.unit
					close_criminal_d = d
				end
			end
		end
	end
	if close_criminal then
		close_criminal:sound():say(message, false)
	end
	if sync then
		if trigger_unit and alive(trigger_unit) then
			managers.network:session():send_to_peers_synched("sync_teammate_comment_instigator", trigger_unit, message_id)
		else
			managers.network:session():send_to_peers_synched("sync_teammate_comment", message_id, pos or Vector3(0, 0, 0), pos_based, radius or 0)
		end
	end
end
function GroupAIStateBase:sync_teammate_comment(message, pos, pos_based, radius)
	self:teammate_comment(nil, self.teammate_comment_names[message], pos, pos_based, radius, false)
end
function GroupAIStateBase:sync_teammate_comment_instigator(unit, message)
	self:teammate_comment(unit, self.teammate_comment_names[message], nil, false, nil, false)
end
function GroupAIStateBase:on_hostage_state(state, key, police)
	local d = state and 1 or -1
	if state then
		for i, h_key in ipairs(self._hostage_keys) do
			if key == h_key then
				debug_pause("double-registered hostage")
				return
			end
		end
		table.insert(self._hostage_keys, key)
	else
		for i, h_key in ipairs(self._hostage_keys) do
			if key == h_key then
				table.remove(self._hostage_keys, i)
			else
			end
		end
	end
	self._hostage_headcount = self._hostage_headcount + d
	self:sync_hostage_headcount()
	if police then
		self._police_hostage_headcount = self._police_hostage_headcount + d
	end
	if self._hstg_hint_clbk then
		managers.enemy:remove_delayed_clbk("_hostage_hint_clbk")
		self._hstg_hint_clbk = nil
	end
	if self._hostage_headcount ~= #self._hostage_keys then
		debug_pause("[GroupAIStateBase:on_hostage_state] Headcount mismatch", self._hostage_headcount, #self._hostage_keys, key, inspect(self._hostage_keys))
	end
end
function GroupAIStateBase:_police_announce_retreat()
	managers.groupai:state():teammate_comment(nil, "g51", nil, false, nil, true)
end
function GroupAIStateBase:set_difficulty(value)
	print("Set diff:", value)
	self._difficulty_value = value
	self:_calculate_difficulty_ratio()
end
function GroupAIStateBase:set_debug_draw_state(b)
	if b and not self._draw_enabled then
		local ws = Overlay:newgui():create_screen_workspace()
		local panel = ws:panel()
		self._AI_draw_data = {
			brush_area = Draw:brush(Color(0.33, 1, 1, 1)),
			brush_guard = Draw:brush(Color(0.5, 0, 0, 1)),
			brush_investigate = Draw:brush(Color(0.5, 0, 1, 0)),
			brush_defend = Draw:brush(Color(0.5, 0, 0.3, 0)),
			brush_free = Draw:brush(Color(0.5, 0.6, 0.3, 0)),
			brush_act = Draw:brush(Color(0.5, 1, 0.8, 0.8)),
			brush_misc = Draw:brush(Color(0.5, 1, 1, 1)),
			brush_detection = Draw:brush(Color(0.6, 1, 1, 1)),
			pen_focus_enemy = Draw:pen(Color(0.5, 1, 0.2, 0)),
			brush_focus_player = Draw:brush(Color(0.5, 1, 0, 0)),
			workspace = ws,
			panel = panel,
			logic_name_texts = {}
		}
	elseif not b and self._draw_enabled then
		Overlay:newgui():destroy_workspace(self._AI_draw_data.workspace)
		self._AI_draw_data = nil
	end
	self._draw_enabled = b
end
function GroupAIStateBase:on_unit_detection_updated(unit)
	if self._draw_enabled then
		local draw_pos = unit:movement():m_head_pos()
		self._AI_draw_data.brush_detection:cone(draw_pos, draw_pos + math.UP * 40, 30)
	end
end
function GroupAIStateBase:_calculate_difficulty_ratio()
	local ramp = tweak_data.group_ai.difficulty_curve_points
	local diff = self._difficulty_value
	local i = 1
	while diff > (ramp[i] or 1) do
		i = i + 1
	end
	self._difficulty_point_index = i
	self._difficulty_ramp = (diff - (ramp[i - 1] or 0)) / ((ramp[i] or 1) - (ramp[i - 1] or 0))
end
function GroupAIStateBase:_get_difficulty_dependent_value(tweak_values)
	return math.lerp(tweak_values[self._difficulty_point_index], tweak_values[self._difficulty_point_index + 1], self._difficulty_ramp)
end
function GroupAIStateBase:_get_spawn_unit_name(weights, wanted_access_type)
	local unit_categories = tweak_data.group_ai.unit_categories
	local total_weight = 0
	local candidates = {}
	local candidate_weights = {}
	for cat_name, cat_weights in pairs(weights) do
		local cat_weight = self:_get_difficulty_dependent_value(cat_weights)
		local suitable = cat_weight > 0
		local cat_data = unit_categories[cat_name]
		if suitable and cat_data.max_amount then
			local special_type = cat_data.special_type
			local nr_active = self._special_units[special_type] and table.size(self._special_units[special_type]) or 0
			if nr_active >= cat_data.max_amount then
				suitable = false
			end
		end
		if suitable and cat_data.special_type and not self._special_units[cat_name] then
			local nr_boss_types_present = table.size(self._special_units)
			if nr_boss_types_present >= tweak_data.group_ai.max_nr_simultaneous_boss_types then
				suitable = false
			end
		end
		if suitable and wanted_access_type then
			suitable = false
			for _, available_access_type in ipairs(cat_data.access) do
				if wanted_access_type == available_access_type then
					suitable = true
				else
				end
			end
		end
		if suitable then
			total_weight = total_weight + cat_weight
			table.insert(candidates, cat_name)
			table.insert(candidate_weights, total_weight)
		end
	end
	if total_weight == 0 then
		cat_print("george", "[GroupAIStateBase:_get_spawn_unit_name] Unable to find suitable unit to spawn")
		return
	end
	local lucky_nr = math.random() * total_weight
	local i_candidate = 1
	while lucky_nr > candidate_weights[i_candidate] do
		i_candidate = i_candidate + 1
	end
	local lucky_cat_name = candidates[i_candidate]
	local lucky_unit_names = unit_categories[lucky_cat_name].units
	local spawn_unit_name = lucky_unit_names[math.random(#lucky_unit_names)]
	return spawn_unit_name
end
function GroupAIStateBase:criminal_spotted(unit)
	local u_key = unit:key()
	local tracker = unit:movement():nav_tracker()
	local seg = tracker:nav_segment()
	local sightings = self._criminals
	local u_sighting = sightings[u_key]
	if u_sighting.undetected then
		u_sighting.undetected = nil
		self:on_enemy_weapons_hot()
	end
	u_sighting.seg = seg
	mvector3.set(u_sighting.pos, tracker:position())
	u_sighting.det_t = self._t
end
function GroupAIStateBase:criminal_record(u_key)
	return self._criminals[u_key]
end
function GroupAIStateBase:on_enemy_engaging(unit, other_u_key)
	local u_key = unit:key()
	local sighting = self._criminals[other_u_key]
	local force = sighting.engaged_force + 1
	sighting.engaged_force = force
	sighting.engaged[u_key] = true
end
function GroupAIStateBase:on_enemy_disengaging(unit, other_u_key)
	local u_key = unit:key()
	local sighting = self._criminals[other_u_key]
	local force = sighting.engaged_force - 1
	sighting.engaged_force = force
	sighting.engaged[u_key] = nil
end
function GroupAIStateBase:on_tase_start(cop_key, criminal_key)
	self._criminals[criminal_key].being_tased = cop_key
end
function GroupAIStateBase:on_tase_end(criminal_key)
	local record = self._criminals[criminal_key]
	if record then
		self._criminals[criminal_key].being_tased = nil
	end
end
function GroupAIStateBase:on_arrest_start(enemy_key, criminal_key)
	local sighting = self._criminals[criminal_key]
	local arrest = sighting.being_arrested
	if arrest then
		sighting.being_arrested[enemy_key] = true
	else
		sighting.being_arrested = {
			[enemy_key] = true
		}
	end
end
function GroupAIStateBase:on_arrest_end(enemy_key, criminal_key)
	local sighting = self._criminals[criminal_key]
	sighting.being_arrested[enemy_key] = nil
	if not next(sighting.being_arrested) then
		sighting.being_arrested = nil
		sighting.arrest_warn_timeout = nil
		sighting.arrest_warn_pos = nil
	end
end
function GroupAIStateBase:on_disarm_start(enemy_key, criminal_key)
	local sighting = self._criminals[criminal_key]
	sighting.being_disarmed = enemy_key
end
function GroupAIStateBase:on_disarm_end(criminal_key)
	local sighting = self._criminals[criminal_key]
	sighting.being_disarmed = nil
end
function GroupAIStateBase:on_simulation_started()
	self:set_AI_enabled(true)
	self._t = TimerManager:game():time()
	self._spawn_points = {}
	self._hostage_data = {}
	self._spawn_events = {}
	local drama_tweak = tweak_data.drama
	self._drama_data = {
		decay_period = tweak_data.drama.decay_period,
		last_calculate_t = 0,
		amount = 0,
		zone = "low",
		low_p = drama_tweak.low,
		high_p = drama_tweak.peak,
		actions = drama_tweak.drama_actions,
		max_dis = drama_tweak.max_dis,
		dis_mul = drama_tweak.max_dis_mul
	}
	self._ai_enabled = true
	self._hostage_headcount = 0
	self._police = managers.enemy:all_enemies()
	self._police_force = table.size(self._police)
	self._criminals = {}
	self._ai_criminals = {}
	self._player_criminals = {}
	self._special_unit_types = {
		tank = true,
		spooc = true,
		shield = true,
		taser = true
	}
	self._listener_holder = EventListenerHolder:new()
	self:set_drama_draw_state(Global.drama_draw_state)
end
function GroupAIStateBase:on_simulation_ended()
	self:set_AI_enabled(false)
	self._t = TimerManager:game():time()
	self._player_weapons_hot = nil
	self._enemy_weapons_hot = nil
	self._spawn_points = {}
	self._flee_points = {}
	self._hostage_data = {}
	self._spawn_events = {}
	self._special_objectives = {}
	self._occasional_events = {}
	self._hostage_headcount = 0
	self._enemy_chatter = {}
	self._forbid_drop_in = nil
	local drama_tweak = tweak_data.drama
	self._drama_data = {
		decay_period = tweak_data.drama.decay_period,
		last_calculate_t = 0,
		amount = 0,
		zone = "low",
		low_p = drama_tweak.low,
		high_p = drama_tweak.peak,
		actions = drama_tweak.drama_actions,
		max_dis = drama_tweak.max_dis,
		dis_mul = drama_tweak.max_dis_mul
	}
	self._police = managers.enemy:all_enemies()
	for char_name, id in pairs(self._criminal_AI_respawn_clbks) do
		managers.enemy:remove_delayed_clbk(id)
	end
	self._criminal_AI_respawn_clbks = {}
	self:set_drama_draw_state(false)
end
function GroupAIStateBase:on_enemy_registered(unit)
	if self._anticipated_police_force > 0 then
		self._anticipated_police_force = self._anticipated_police_force - 1
	else
		self._police_force = self._police_force + 1
	end
	if Network:is_server() then
		local unit_type = unit:base()._tweak_table
		if self._special_unit_types[unit_type] then
			self:register_special_unit(unit:key(), unit_type)
		end
	end
end
function GroupAIStateBase:criminal_hurt_drama(unit, attacker, dmg_percent)
	local drama_data = self._drama_data
	local drama_amount = drama_data.actions.criminal_hurt * dmg_percent
	if alive(attacker) then
		local max_dis = drama_data.max_dis
		local dis_lerp = math.min(1, mvector3.distance(attacker:movement():m_pos(), unit:movement():m_pos()) / drama_data.max_dis)
		dis_lerp = math.lerp(1, drama_data.dis_mul, dis_lerp)
		drama_amount = drama_amount * dis_lerp
	end
	self:_add_drama(drama_amount)
end
function GroupAIStateBase:on_enemy_unregistered(unit)
	self._police_force = self._police_force - 1
	if Network:is_server() then
		local u_key = unit:key()
		local e_data = self._police[u_key]
		if e_data.importance > 0 then
			for c_key, c_data in pairs(self._player_criminals) do
				local imp_keys = c_data.important_enemies
				for i, test_e_key in ipairs(imp_keys) do
					if test_e_key == u_key then
						table.remove(imp_keys, i)
						table.remove(c_data.important_dis, i)
					else
					end
				end
			end
		end
		for crim_key, record in pairs(self._ai_criminals) do
			record.unit:brain():on_cop_neutralized(u_key)
		end
		local unit_type = unit:base()._tweak_table
		if self._special_unit_types[unit_type] then
			self:unregister_special_unit(u_key, unit_type)
		end
		if e_data.assigned_area and unit:character_damage():dead() then
			local spawn_point = unit:unit_data().mission_element
			if spawn_point then
				local spawn_pos = spawn_point:value("position")
				local u_pos = e_data.m_pos
				if mvector3.distance(spawn_pos, u_pos) < 700 and math.abs(spawn_pos.z - u_pos.z) < 300 then
					local found
					for nav_seg, area_data in pairs(self._area_data) do
						local area_spawn_points = area_data.spawn_points
						if area_spawn_points then
							for _, sp_data in ipairs(area_spawn_points) do
								if sp_data.spawn_point == spawn_point then
									found = true
									sp_data.delay_t = math.max(sp_data.delay_t, self._t + math.random(30, 60))
								else
								end
							end
							if found then
							end
						else
						end
					end
				end
			end
		end
	end
end
function GroupAIStateBase:report_aggression(unit)
	self._criminals[unit:key()].assault_t = self._t
end
function GroupAIStateBase:register_fleeing_civilian(u_key, unit)
	self._fleeing_civilians[u_key] = unit
end
function GroupAIStateBase:unregister_fleeing_civilian(u_key)
	self._fleeing_civilians[u_key] = nil
end
function GroupAIStateBase:register_special_unit(u_key, category_name)
	local category = self._special_units[category_name]
	if not category then
		category = {}
		self._special_units[category_name] = category
	end
	category[u_key] = true
end
function GroupAIStateBase:unregister_special_unit(u_key, category_name)
	local category = self._special_units[category_name]
	category[u_key] = nil
	if not next(category) then
		self._special_units[category_name] = nil
	end
end
function GroupAIStateBase:register_criminal(unit)
	local u_key = unit:key()
	local ext_mv = unit:movement()
	local tracker = ext_mv:nav_tracker()
	local seg = tracker:nav_segment()
	local is_AI
	if unit:base()._tweak_table then
		is_AI = true
	end
	local is_deployable = unit:base().sentry_gun
	local u_sighting = {
		unit = unit,
		ai = is_AI,
		tracker = tracker,
		seg = seg,
		pos = mvector3.copy(ext_mv:m_pos()),
		m_pos = ext_mv:m_pos(),
		m_det_pos = ext_mv:m_detect_pos(),
		det_t = self._t,
		engaged = {},
		engaged_force = 0,
		dispatch_t = 0,
		assault_t = -100,
		arrest_timeout = -100,
		important_enemies = not is_AI and {} or nil,
		important_dis = not is_AI and {} or nil,
		undetected = true,
		is_deployable = is_deployable
	}
	self._criminals[u_key] = u_sighting
	if is_AI then
		self._ai_criminals[u_key] = u_sighting
		u_sighting.so_access = managers.navigation:convert_access_flag(tweak_data.character[unit:base()._tweak_table].access)
	elseif not is_deployable then
		self._player_criminals[u_key] = u_sighting
	end
	if not is_deployable then
		self._char_criminals[u_key] = u_sighting
	end
	if not unit:base().is_local_player then
		managers.enemy:on_criminal_registered(unit)
	end
end
function GroupAIStateBase:unregister_criminal(unit)
	local u_key = unit:key()
	local record = self._criminals[u_key]
	local is_server = self._is_server
	if is_server and record.status ~= "dead" then
		record.status = "dead"
		for key, data in pairs(self._police) do
			data.unit:brain():on_criminal_neutralized(u_key)
		end
	end
	if record.ai then
		self._ai_criminals[u_key] = nil
		if is_server then
			local objective = unit:brain():objective()
			if objective and objective.fail_clbk then
				local fail_clbk = objective.fail_clbk
				objective.fail_clbk = nil
				fail_clbk(unit)
			end
		end
	else
		if Network:is_server() then
			for i, e_key in ipairs(record.important_enemies) do
				self:_adjust_cop_importance(e_key, -1)
			end
		end
		self._player_criminals[u_key] = nil
	end
	self._char_criminals[u_key] = nil
	self._criminals[u_key] = nil
	managers.hud:remove_hud_info_by_unit(unit)
	if not unit:base().is_local_player then
		managers.enemy:on_criminal_unregistered(u_key)
	end
	self:check_gameover_conditions()
end
function GroupAIStateBase:check_gameover_conditions()
	if not Network:is_server() or managers.platform:presence() ~= "Playing" then
		return false
	end
	if game_state_machine:current_state().game_ended and game_state_machine:current_state():game_ended() then
		return false
	end
	if Global.load_start_menu or Application:editor() then
		return false
	end
	local plrs_alive = false
	local plrs_disabled = true
	for u_key, u_data in pairs(self._player_criminals) do
		plrs_alive = true
		if u_data.status ~= "dead" and u_data.status ~= "disabled" then
			plrs_disabled = false
		else
		end
	end
	local ai_alive = false
	local ai_disabled = true
	for u_key, u_data in pairs(self._ai_criminals) do
		ai_alive = true
		if u_data.status ~= "dead" and u_data.status ~= "disabled" then
			ai_disabled = false
		else
		end
	end
	local gameover = false
	if not plrs_alive then
		gameover = true
	elseif plrs_disabled and not ai_alive then
		gameover = true
	elseif plrs_disabled and ai_disabled then
		gameover = true
	end
	if gameover and not self._gameover_clbk then
		self._gameover_clbk = callback(self, self, "_gameover_clbk_func")
		managers.enemy:add_delayed_clbk("_gameover_clbk", self._gameover_clbk, Application:time() + 4)
	end
	return gameover
end
function GroupAIStateBase:_gameover_clbk_func()
	local govr = self:check_gameover_conditions()
	self._gameover_clbk = nil
	if govr then
		managers.network:session():send_to_peers("begin_gameover_fadeout")
		self:begin_gameover_fadeout()
	end
end
function GroupAIStateBase:begin_gameover_fadeout()
	game_state_machine:change_state_by_name("gameoverscreen")
end
function GroupAIStateBase:report_criminal_downed(unit)
	if not self:bain_state() then
		return
	end
	local character_code = managers.criminals:character_static_data_by_unit(unit).ssuffix
	local bain_line = "ban_q01" .. character_code
	if unit ~= managers.player:player_unit() then
		managers.dialog:queue_dialog(bain_line, {})
	end
	managers.network:session():send_to_peers("bain_comment", bain_line)
end
function GroupAIStateBase:on_criminal_disabled(unit, custom_status)
	local criminal_key = unit:key()
	local record = self._criminals[criminal_key]
	record.disabled_t = self._t
	record.status = custom_status or "disabled"
	if Network:is_server() then
		self._downs_during_assault = self._downs_during_assault + 1
		for key, data in pairs(self._police) do
			data.unit:brain():on_criminal_neutralized(criminal_key)
		end
		self:_add_drama(self._drama_data.actions.criminal_disabled)
		self:check_gameover_conditions()
	end
end
function GroupAIStateBase:on_criminal_neutralized(unit)
	local criminal_key = unit:key()
	local record = self._criminals[criminal_key]
	record.status = "dead"
	record.arrest_timeout = 0
	if Network:is_server() then
		self._downs_during_assault = self._downs_during_assault + 1
		for key, data in pairs(self._police) do
			data.unit:brain():on_criminal_neutralized(criminal_key)
		end
		self:_add_drama(self._drama_data.actions.criminal_dead)
		self:check_gameover_conditions()
	end
end
function GroupAIStateBase:on_criminal_recovered(criminal_unit)
	local record = self._criminals[criminal_unit:key()]
	if record.status then
		record.status = nil
		if Network:is_server() then
			self:check_gameover_conditions()
		end
	end
end
function GroupAIStateBase:on_civilian_try_freed()
	if not self._warned_about_deploy_this_control then
		self._warned_about_deploy_this_control = true
		if not self._warned_about_deploy then
			self:sync_warn_about_civilian_free(1)
			managers.network:session():send_to_peers("warn_about_civilian_free", 1)
			self._warned_about_deploy = true
		else
			self:sync_warn_about_civilian_free(2)
			managers.network:session():send_to_peers("warn_about_civilian_free", 2)
		end
	end
end
function GroupAIStateBase:on_civilian_freed()
	if not self._warned_about_freed_this_control then
		self._warned_about_freed_this_control = true
		if not self._warned_about_freed then
			self:sync_warn_about_civilian_free(3)
			managers.network:session():send_to_peers("warn_about_civilian_free", 3)
			self._warned_about_freed = true
		else
			self:sync_warn_about_civilian_free(4)
			managers.network:session():send_to_peers("warn_about_civilian_free", 4)
		end
	end
end
function GroupAIStateBase:sync_warn_about_civilian_free(i)
	if not self:bain_state() then
		return
	end
	if i == 1 then
		managers.dialog:queue_dialog("ban_r01", {})
	elseif i == 2 then
		managers.dialog:queue_dialog("ban_r02", {})
	elseif i == 3 then
		managers.dialog:queue_dialog("ban_r03", {})
	elseif i == 4 then
		managers.dialog:queue_dialog("ban_r04", {})
	end
end
function GroupAIStateBase:on_enemy_tied(u_key)
end
function GroupAIStateBase:on_enemy_untied(u_key)
end
function GroupAIStateBase:on_civilian_tied(u_key)
end
function GroupAIStateBase:_debug_draw_drama(t)
	local draw_data = self._draw_drama
	local drama_data = self._drama_data
	draw_data.background_brush:quad(draw_data.bg_bottom_l, draw_data.bg_bottom_r, draw_data.bg_top_r, draw_data.bg_top_l)
	draw_data.low_zone_pen:line(draw_data.low_zone_l, draw_data.low_zone_r)
	draw_data.high_zone_pen:line(draw_data.high_zone_l, draw_data.high_zone_r)
	if t - self._drama_data.last_calculate_t > 1 then
		self:_claculate_drama_value()
	end
	local t_span = draw_data.t_span
	local drama_hist = draw_data.drama_hist
	if t > drama_hist[#drama_hist][2] then
		if #drama_hist == 1 then
			table.insert(drama_hist, {
				drama_data.amount,
				t
			})
		else
			local tan1 = (drama_data.amount - drama_hist[#drama_hist][1]) / (t - drama_hist[#drama_hist][2])
			local tan2 = (drama_hist[#drama_hist][1] - drama_hist[#drama_hist - 1][1]) / (drama_hist[#drama_hist][2] - drama_hist[#drama_hist - 1][2])
			if #drama_hist > 1 and math.abs(tan1 - tan2) < 0.5 then
				drama_hist[#drama_hist][2] = t
			else
				table.insert(drama_hist, {
					drama_data.amount,
					t
				})
			end
		end
	end
	while drama_hist[2] and t_span < t - drama_hist[2][2] do
		table.remove(drama_hist, 1)
	end
	local mvec3_set_st = mvector3.set_static
	local mvec3_set = mvector3.set
	local height = draw_data.height
	local width = draw_data.width
	local right_limit = draw_data.offset_x + width
	local bottom_limit = draw_data.offset_y
	local prev_pos = Vector3()
	local new_pos = Vector3()
	local drama_pen = draw_data.drama_pen
	for i, entry in ipairs(drama_hist) do
		local new_x = right_limit - width * (t - entry[2]) / t_span
		local new_y = bottom_limit + entry[1] * height
		mvec3_set_st(new_pos, new_x, new_y, 90)
		if i > 1 then
			drama_pen:line(prev_pos, new_pos)
		end
		mvec3_set(prev_pos, new_pos)
	end
	local pop_hist = draw_data.pop_hist
	local pop_hist_size = #pop_hist
	local last_entry = pop_hist[pop_hist_size]
	if t > last_entry[2] then
		local police_force = self._police_force
		if pop_hist_size > 1 and last_entry[1] == police_force and pop_hist[pop_hist_size - 1][1] == police_force then
			last_entry[2] = t
		else
			table.insert(pop_hist, {police_force, t})
		end
	end
	while pop_hist[2] and t_span < t - pop_hist[2][2] do
		table.remove(pop_hist, 1)
	end
	local max_force = self._police_force_max
	local pop_pen = draw_data.population_pen
	for i, entry in ipairs(pop_hist) do
		local new_x = right_limit - width * (t - entry[2]) / t_span
		local new_y = bottom_limit + entry[1] * height / max_force
		mvec3_set_st(new_pos, new_x, new_y, 80)
		if i > 1 then
			pop_pen:line(prev_pos, new_pos)
		end
		mvec3_set(prev_pos, new_pos)
	end
	local mvec3_setx = mvector3.set_x
	local top_l = Vector3(0, draw_data.bg_top_l.y, 90)
	local bottom_l = Vector3(0, draw_data.bg_bottom_l.y, 90)
	local top_r = Vector3(0, draw_data.bg_top_l.y, 90)
	local bottom_r = Vector3(0, draw_data.bg_bottom_l.y, 90)
	local function _draw_events(event_brush, event_list)
		while event_list[1] and event_list[1][2] and t - event_list[1][2] > t_span do
			table.remove(event_list, 1)
		end
		for i, entry in ipairs(event_list) do
			local new_x = right_limit - width * (t - entry[1]) / t_span
			mvec3_setx(top_l, new_x)
			mvec3_setx(bottom_l, new_x)
			if entry[2] then
				local new_x = right_limit - width * (t - entry[2]) / t_span
				mvec3_setx(top_r, new_x)
				mvec3_setx(bottom_r, new_x)
			else
				mvec3_setx(top_r, right_limit)
				mvec3_setx(bottom_r, right_limit)
			end
			event_brush:quad(top_l, top_r, bottom_r, bottom_l)
		end
	end
	_draw_events(draw_data.assault_brush, draw_data.assault_hist)
	_draw_events(draw_data.regroup_brush, draw_data.regroup_hist)
end
function GroupAIStateBase:toggle_drama_draw_state()
	Global.drama_draw_state = not Global.drama_draw_state
	self:set_drama_draw_state(Global.drama_draw_state)
end
function GroupAIStateBase:set_drama_draw_state(state)
	if state then
		local depth = 100
		local offset = Vector3(-0.98, -0.98)
		local width = 1
		local height = 0.3
		local low_zone_color = Color(1, 0.2, 0.2, 0.7)
		local high_zone_color = Color(1, 0.7, 0.2, 0.2)
		local background_color = Color(0.2, 0.2, 0.2, 0.2)
		local assault_color = Color(0.1, 0.5, 0, 0)
		local regroup_color = Color(0.1, 0, 0.1, 0.5)
		local zone = self._drama_data.zone
		local drama_line_color = Color(0.3, 1, 1, 1)
		local population_line_color = Color(0.3, 0.6, 0.4, 0.15)
		local bg_bottom_l = offset + Vector3(0, 0, depth)
		local bg_bottom_r = offset + Vector3(width, 0, depth)
		local bg_top_l = offset + Vector3(0, height, depth)
		local bg_top_r = offset + Vector3(width, height, depth)
		local low_zone_l = bg_bottom_l:with_y(bg_bottom_l.y + self._drama_data.low_p * height)
		local low_zone_r = low_zone_l:with_x(bg_bottom_r.x)
		local high_zone_l = bg_bottom_l:with_y(bg_bottom_l.y + self._drama_data.high_p * height)
		local high_zone_r = high_zone_l:with_x(bg_bottom_r.x)
		self._draw_drama = {
			background_brush = Draw:brush(background_color),
			assault_brush = Draw:brush(assault_color),
			regroup_brush = Draw:brush(regroup_color),
			drama_pen = Draw:pen("screen", drama_line_color),
			population_pen = Draw:pen("screen", population_line_color),
			low_zone_pen = Draw:pen("screen", low_zone_color),
			high_zone_pen = Draw:pen("screen", high_zone_color),
			bg_bottom_l = bg_bottom_l,
			bg_bottom_r = bg_bottom_r,
			bg_top_l = bg_top_l,
			bg_top_r = bg_top_r,
			low_zone_l = low_zone_l,
			low_zone_r = low_zone_r,
			high_zone_l = high_zone_l,
			high_zone_r = high_zone_r,
			width = width,
			height = height,
			offset_x = offset.x,
			offset_y = offset.y,
			start_t = self._t,
			drama_hist = {
				{
					self._drama_data.amount,
					self._t
				}
			},
			pop_hist = {
				{
					self._police_force,
					self._t
				}
			},
			assault_hist = {},
			regroup_hist = {},
			t_span = 180
		}
		self._draw_drama.background_brush:set_screen(true)
		self._draw_drama.assault_brush:set_screen(true)
		self._draw_drama.regroup_brush:set_screen(true)
		if self._task_data then
			for _, task_type in ipairs({"assault", "blockade"}) do
				if self._task_data[task_type] and self._task_data[task_type].active then
					table.insert(self._draw_drama.assault_hist, {
						self._task_data[task_type].start_t
					})
				else
				end
			end
			if self._task_data.regroup and self._task_data.regroup.active then
				table.insert(self._draw_drama.regroup_hist, {
					self._task_data.regroup.start_t
				})
			end
		end
	else
		self._draw_drama = nil
	end
end
function GroupAIStateBase:task_names()
	return {
		"any",
		"assault",
		"blockade",
		"recon",
		"reenforce",
		"rescue"
	}
end
function GroupAIStateBase:add_spawn_event(id, event_data)
	self._spawn_events[id] = event_data
	event_data.chance = event_data.base_chance
end
function GroupAIStateBase:remove_spawn_event(id)
	self._spawn_events[id] = nil
end
function GroupAIStateBase:_try_use_task_spawn_event(t, target_area, task_type, target_pos, force)
	local max_dis = 3000
	local mvec3_dis = mvector3.distance
	target_pos = target_pos or managers.navigation._nav_segments[target_area].pos
	for event_id, event_data in pairs(self._spawn_events) do
		if event_data.task_type == task_type or event_data.task_type == "any" then
			local dis = mvec3_dis(target_pos, event_data.pos)
			if max_dis > dis then
				if force or math.random() < event_data.chance then
					self._anticipated_police_force = self._anticipated_police_force + event_data.amount
					self._police_force = self._police_force + event_data.amount
					self:_use_spawn_event(event_data)
					return
				else
					event_data.chance = math.min(1, event_data.chance + event_data.chance_inc)
				end
			end
		end
	end
end
function GroupAIStateBase:_use_spawn_event(event_data)
	event_data.chance = event_data.base_chance
	event_data.element:on_executed()
end
function GroupAIStateBase:on_objective_failed(unit, objective)
	local new_objective
	if unit:brain():objective() == objective then
		local u_key = unit:key()
		local u_data = self._police[u_key]
		if u_data then
			new_objective = {
				type = "free",
				attitude = objective.attitude,
				stance = objective.stance,
				scan = objective.scan
			}
			if u_data.assigned_area then
				local seg = unit:movement():nav_tracker():nav_segment()
				self:_set_enemy_assigned(self._area_data[seg], u_key)
			end
		end
	end
	local fail_clbk = objective.fail_clbk
	objective.fail_clbk = nil
	if new_objective then
		unit:brain():set_objective(new_objective)
	end
	if fail_clbk then
		fail_clbk(unit)
	end
end
function GroupAIStateBase:add_special_objective(id, objective_data)
	if self._special_objectives[id] then
		self:remove_special_objective(id)
	end
	local interval = objective_data.chance_inc >= 0 and 0 <= objective_data.interval and objective_data.interval
	local chance = objective_data.base_chance
	local so = {
		data = objective_data,
		delay_t = 0,
		chance = chance,
		chance_inc = objective_data.chance_inc,
		interval = objective_data.interval,
		remaining_usage = objective_data.usage_amount,
		non_repeatable = not objective_data.repeatable,
		administered = not objective_data.repeatable and {}
	}
	if not objective_data.access then
		objective_data.access = managers.navigation:convert_SO_AI_group_to_access(objective_data.AI_group)
	end
	self._special_objectives[id] = so
	if objective_data.objective and objective_data.objective.nav_seg then
		local nav_seg = objective_data.objective.nav_seg
		local area_data = self._area_data[nav_seg]
		area_data.SO = area_data.SO or {}
		table.insert(area_data.SO, id)
	end
end
function GroupAIStateBase:_execute_so(so_data, so_rooms, so_administered)
	local max_dis = so_data.search_dis_sq
	local pos = so_data.search_pos
	local ai_group = so_data.AI_group
	local so_access = so_data.access
	local mvec3_dis_sq = mvector3.distance_sq
	local closest_u_data, closest_dis
	local so_objective = so_data.objective
	local nav_manager = managers.navigation
	local access_f = nav_manager.check_access
	if ai_group == "enemies" then
		for e_key, enemy_unit_data in pairs(self._police) do
			if enemy_unit_data.assigned_area and (not so_administered or not so_administered[e_key]) and enemy_unit_data.unit:brain():is_available_for_assignment(so_objective) and (not so_data.verification_clbk or so_data.verification_clbk(enemy_unit_data.unit)) and access_f(nav_manager, so_access, enemy_unit_data.so_access, 0) then
				local dis = mvec3_dis_sq(enemy_unit_data.m_pos, pos)
				if (not closest_dis or closest_dis > dis) and (not max_dis or max_dis > dis) then
					closest_u_data = enemy_unit_data
					closest_dis = dis
				end
			end
		end
	elseif ai_group == "friendlies" then
		for u_key, u_unit_data in pairs(self._ai_criminals) do
			if (not so_administered or not so_administered[u_key]) and u_unit_data.unit:brain():is_available_for_assignment(so_objective) and (not so_data.verification_clbk or so_data.verification_clbk(u_unit_data.unit)) and access_f(nav_manager, so_access, u_unit_data.so_access, 0) then
				local dis = mvec3_dis_sq(u_unit_data.m_pos, pos)
				if (not closest_dis or closest_dis > dis) and (not max_dis or max_dis > dis) then
					closest_u_data = u_unit_data
					closest_dis = dis
				end
			end
		end
	elseif ai_group == "civilians" then
		for u_key, u_unit_data in pairs(managers.enemy:all_civilians()) do
			if (not so_administered or not so_administered[u_key]) and u_unit_data.unit:brain():is_available_for_assignment(so_objective) and (not so_data.verification_clbk or so_data.verification_clbk(u_unit_data.unit)) and access_f(nav_manager, so_access, u_unit_data.so_access, 0) then
				local dis = mvec3_dis_sq(u_unit_data.m_pos, pos)
				if (not closest_dis or closest_dis > dis) and (not max_dis or max_dis > dis) then
					closest_u_data = u_unit_data
					closest_dis = dis
				end
			end
		end
	else
		for u_key, civ_unit_data in pairs(managers.enemy:all_civilians()) do
			if access_f(nav_manager, so_access, civ_unit_data.so_access, 0) then
				closest_u_data = civ_unit_data
			else
			end
		end
	end
	if closest_u_data then
		local fail_clbk = so_objective.fail_clbk
		local complete_clbk = so_objective.complete_clbk
		so_objective.fail_clbk = nil
		so_objective.complete_clbk = nil
		local objective_copy = deep_clone(so_objective)
		so_objective.fail_clbk = fail_clbk
		so_objective.complete_clbk = complete_clbk
		objective_copy.fail_clbk = fail_clbk
		objective_copy.complete_clbk = complete_clbk
		closest_u_data.unit:brain():set_objective(objective_copy)
		if so_data.admin_clbk then
			so_data.admin_clbk(closest_u_data.unit)
		end
	end
	return closest_u_data
end
function GroupAIStateBase:remove_special_objective(id)
	local so = self._special_objectives[id]
	if not so then
		return
	end
	local nav_seg = so.data.objective and so.data.objective.nav_seg
	self._special_objectives[id] = nil
	if not nav_seg then
		return
	end
	local area_data = self._area_data[nav_seg]
	local area_so = area_data.SO
	if #area_so == 1 then
		area_data.SO = nil
	else
		for i, so_id in ipairs(area_so) do
			if so_id == id then
				so[i] = area_so[#area_so]
				table.remove(area_so)
			end
			return
		end
	end
end
function GroupAIStateBase:save(save_data)
	local my_save_data = {}
	save_data.group_ai = my_save_data
	my_save_data.control_value = self._control_value
	my_save_data._assault_mode = self._assault_mode
	my_save_data._hunt_mode = self._hunt_mode
	my_save_data._fake_assault_mode = self._fake_assault_mode
	my_save_data._whisper_mode = self._whisper_mode
	my_save_data._bain_state = self._bain_state
	my_save_data._point_of_no_return_timer = self._point_of_no_return_timer
	my_save_data._point_of_no_return_id = self._point_of_no_return_id
	if self._hostage_headcount > 0 then
		my_save_data.hostage_headcount = self._hostage_headcount
	end
end
function GroupAIStateBase:load(load_data)
	local my_load_data = load_data.group_ai
	self._control_value = my_load_data.control_value
	self:_calculate_difficulty_ratio()
	self._hunt_mode = my_load_data._hunt_mode
	self:sync_assault_mode(my_load_data._assault_mode)
	self:set_fake_assault_mode(my_load_data._fake_assault_mode)
	self:set_whisper_mode(my_load_data._whisper_mode)
	self:set_bain_state(my_load_data._bain_state)
	self:set_point_of_no_return_timer(my_load_data._point_of_no_return_timer, my_load_data._point_of_no_return_id)
	if my_load_data.hostage_headcount then
		self:sync_hostage_headcount(my_load_data.hostage_headcount)
	end
end
function GroupAIStateBase:set_point_of_no_return_timer(time, point_of_no_return_id)
	if time == nil then
		return
	end
	self._forbid_drop_in = true
	managers.network.matchmake:set_server_joinable(false)
	if not self._peers_inside_point_of_no_return then
		self._peers_inside_point_of_no_return = {}
	end
	self._point_of_no_return_timer = time
	self._point_of_no_return_id = point_of_no_return_id
	self._point_of_no_return_areas = nil
	managers.hud:show_point_of_no_return_timer()
	managers.hud:add_updator("point_of_no_return", callback(self, self, "_update_point_of_no_return"))
end
function GroupAIStateBase:set_is_inside_point_of_no_return(peer_id, is_inside)
	self._peers_inside_point_of_no_return[peer_id] = is_inside
end
function GroupAIStateBase:_update_point_of_no_return(t, dt)
	local get_mission_script_element = function(id)
		for name, script in pairs(managers.mission:scripts()) do
			if script:element(id) then
				return script:element(id)
			end
		end
	end
	local prev_time = self._point_of_no_return_timer
	self._point_of_no_return_timer = self._point_of_no_return_timer - dt
	local sec = math.floor(self._point_of_no_return_timer)
	if sec < math.floor(prev_time) then
		managers.hud:flash_point_of_no_return_timer(sec <= 10)
	end
	if not self._point_of_no_return_areas then
		self._point_of_no_return_areas = {}
		local element = get_mission_script_element(self._point_of_no_return_id)
		for _, id in ipairs(element._values.elements) do
			local area = get_mission_script_element(id)
			if area then
				table.insert(self._point_of_no_return_areas, area)
			end
		end
	end
	local is_inside = false
	local plr_unit = managers.criminals:character_unit_by_name(managers.criminals:local_character_name())
	if plr_unit and alive(plr_unit) then
		for _, area in ipairs(self._point_of_no_return_areas) do
			if area._shape:is_inside(plr_unit:movement():m_pos()) then
				is_inside = true
			else
			end
		end
	end
	if is_inside ~= self._is_inside_point_of_no_return then
		self._is_inside_point_of_no_return = is_inside
		if managers.network:session() then
			if not Network:is_server() then
				managers.network:session():send_to_host("is_inside_point_of_no_return", is_inside, managers.network:session():local_peer():id())
			else
				self:set_is_inside_point_of_no_return(managers.network:session():local_peer():id(), is_inside)
			end
		end
	end
	if self._point_of_no_return_timer <= 0 then
		managers.hud:remove_updator("point_of_no_return")
		if not is_inside then
			self._failed_point_of_no_return = true
		end
		if Network:is_server() then
			if managers.platform:presence() == "Playing" then
				local num_is_inside = 0
				for _, peer_inside in pairs(self._peers_inside_point_of_no_return) do
					num_is_inside = num_is_inside + (peer_inside and 1 or 0)
				end
				if num_is_inside > 0 then
					local num_winners = num_is_inside + self:amount_of_winning_ai_criminals()
					managers.network:session():send_to_peers("mission_ended", true, num_winners)
					game_state_machine:change_state_by_name("victoryscreen", {num_winners = num_winners, personal_win = is_inside})
				else
					managers.network:session():send_to_peers("mission_ended", false, 0)
					game_state_machine:change_state_by_name("gameoverscreen")
				end
			end
			local element = get_mission_script_element(self._point_of_no_return_id)
			for _, id in ipairs(element._values.elements) do
				local area = get_mission_script_element(id)
				if area then
					area:execute_on_executed(nil)
				end
			end
		end
		managers.hud:feed_point_of_no_return_timer(0, is_inside)
	else
		managers.hud:feed_point_of_no_return_timer(self._point_of_no_return_timer, is_inside)
	end
end
function GroupAIStateBase:spawn_one_teamAI(is_drop_in, char_name, spawn_on_unit)
	if Global.criminal_team_AI_disabled or not self._ai_enabled then
		return
	end
	local objective = self:_determine_spawn_objective_for_criminal_AI()
	if objective and objective.type == "follow" then
		local player = spawn_on_unit or objective.follow_unit
		local player_pos = player:position()
		local tracker = player:movement():nav_tracker()
		local spawn_pos, spawn_rot
		if is_drop_in or spawn_on_unit then
			local spawn_fwd = player:movement():m_head_rot():y()
			mvector3.set_z(spawn_fwd, 0)
			mvector3.normalize(spawn_fwd)
			spawn_rot = Rotation(spawn_fwd, math.UP)
			spawn_pos = player_pos
			if not tracker:lost() then
				local search_pos = player_pos - spawn_fwd * 200
				local ray_params = {
					tracker_from = tracker,
					allow_entry = false,
					pos_to = search_pos,
					trace = true
				}
				local ray_hit = managers.navigation:raycast(ray_params)
				if ray_hit then
					spawn_pos = ray_params.trace[1]
				else
					spawn_pos = search_pos
				end
			end
		else
			local spawn_point = managers.network:game():get_next_spawn_point()
			spawn_pos = spawn_point.pos_rot[1]
			spawn_rot = spawn_point.pos_rot[2]
			objective.in_place = true
		end
		local character_name = char_name or managers.criminals:get_free_character_name()
		local lvl_tweak_data = Global.level_data and Global.level_data.level_id and tweak_data.levels[Global.level_data.level_id]
		local unit_folder = lvl_tweak_data and lvl_tweak_data.unit_suit or "suit"
		local unit_name = Idstring("units/characters/npc/criminal/" .. unit_folder .. "/" .. character_name .. "_npc")
		local unit = World:spawn_unit(unit_name, spawn_pos, spawn_rot)
		managers.network:session():send_to_peers_synched("set_unit", unit, character_name, 0)
		if char_name and not is_drop_in then
			managers.criminals:set_unit(character_name, unit)
		else
			managers.criminals:add_character(character_name, unit, nil, true)
		end
		unit:movement():set_character_anim_variables()
		unit:brain():set_spawn_ai({
			init_state = "idle",
			params = {scan = true},
			objective = objective
		})
		return unit
	end
end
function GroupAIStateBase:is_teamAI_marked_for_removal(name)
	if not self._marked_AI then
		return false
	end
	return self._marked_AI[name]
end
function GroupAIStateBase:mark_one_teamAI_for_removal(member_downed, member_dead)
	if not self._marked_AI then
		self._marked_AI = {}
	end
	local dead_ais = {}
	local downed_ais = {}
	local healthy_ais = {}
	for id, data in pairs(managers.criminals._characters) do
		if data.taken and data.data.ai and not self._marked_AI[data.name] then
			if alive(data.unit) and (data.unit:character_damage():bleed_out() or data.unit:character_damage():fatal() or data.unit:character_damage():arrested() or data.unit:character_damage():need_revive() or data.unit:character_damage():dead()) then
				table.insert(downed_ais, data.name)
			elseif managers.trade:is_criminal_in_custody(data.name) then
				table.insert(dead_ais, data.name)
			else
				table.insert(healthy_ais, data.name)
			end
		end
	end
	local name
	if #dead_ais > 0 and member_dead then
		name = dead_ais[math.random(1, #dead_ais)]
	elseif #downed_ais > 0 and (member_dead or member_downed) then
		name = downed_ais[math.random(1, #downed_ais)]
	elseif #healthy_ais > 0 then
		name = healthy_ais[math.random(1, #healthy_ais)]
	elseif #downed_ais > 0 then
		name = downed_ais[math.random(1, #downed_ais)]
	elseif #dead_ais > 0 then
		name = dead_ais[math.random(1, #dead_ais)]
	end
	if name ~= nil then
		self._marked_AI[name] = true
		return name
	end
end
function GroupAIStateBase:demark_one_teamAI_for_removal(name)
	if not self._marked_AI then
		return
	end
	self._marked_AI[name] = nil
end
function GroupAIStateBase:remove_one_teamAI(name_to_remove, replace_with_player)
	local u_key, u_data
	if not name_to_remove then
		u_key, u_data = next(self._ai_criminals)
	else
		for uk, ud in pairs(self._ai_criminals) do
			if managers.criminals:character_name_by_unit(ud.unit) == name_to_remove then
				u_key, u_data = uk, ud
			else
			end
		end
	end
	local name, unit
	if u_key then
		name = managers.criminals:character_name_by_unit(u_data.unit)
		u_data.status = "removed"
		for key, data in pairs(self._police) do
			data.unit:brain():on_criminal_neutralized(u_key)
		end
		unit = u_data.unit
	else
		local unit
		for id, data in pairs(managers.criminals._characters) do
			if data.taken and data.data.ai and (not name_to_remove or data.name == name_to_remove) then
				unit = data.unit
				name = data.name
			end
		end
		if not unit then
			return
		end
	end
	if self._marked_AI then
		self._marked_AI[name] = nil
	end
	local trade_entry = self:sync_remove_one_teamAI(name, replace_with_player)
	managers.network:session():send_to_peers_synched("sync_remove_one_teamAI", name, replace_with_player)
	if alive(unit) then
		unit:brain():set_active(false)
		unit:base():set_slot(unit, 0)
		unit:base():unregister()
	end
	return trade_entry, unit
end
function GroupAIStateBase:sync_remove_one_teamAI(name, replace_with_player)
	managers.criminals:remove_character_by_name(name)
	if not replace_with_player then
		managers.trade:remove_from_trade(name)
		return true
	else
		return managers.trade:replace_ai_with_player(name, name)
	end
end
function GroupAIStateBase:fill_criminal_team_with_AI(is_drop_in)
	while true do
		if managers.navigation:is_data_ready() and self._ai_enabled and not Global.criminal_team_AI_disabled then
		elseif not managers.criminals:get_free_character_name() or not self:spawn_one_teamAI(is_drop_in) then
			break
		end
	end
end
function GroupAIStateBase:on_civilian_objective_complete(unit, objective)
	local new_objective
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
		local so_element = managers.mission:get_element_by_id(objective.followup_SO)
		new_objective = so_element:get_objective(unit)
	end
	objective.fail_clbk = nil
	unit:brain():set_objective(new_objective)
	if objective.complete_clbk then
		objective.complete_clbk(unit)
	end
end
function GroupAIStateBase:on_civilian_objective_failed(unit, objective)
	local fail_clbk = objective.fail_clbk
	objective.fail_clbk = nil
	if fail_clbk then
		fail_clbk(unit)
	end
	unit:brain():set_objective({type = "free"})
end
function GroupAIStateBase:on_criminal_objective_complete(unit, objective)
	local new_objective, so_element
	if objective.followup_objective then
		if not objective.followup_objective.trigger_on then
			new_objective = objective.followup_objective
		else
			new_objective = self:_determine_objective_for_criminal_AI(unit)
			if new_objective then
				new_objective.followup_objective = objective.followup_objective
			end
		end
	elseif objective.followup_SO then
		so_element = managers.mission:get_element_by_id(objective.followup_SO)
		new_objective = so_element:get_objective(unit)
	else
		new_objective = self:_determine_objective_for_criminal_AI(unit)
	end
	objective.fail_clbk = nil
	unit:brain():set_objective(new_objective)
	if objective.complete_clbk then
		objective.complete_clbk(unit)
	end
end
function GroupAIStateBase:on_criminal_objective_failed(unit, objective, no_new_objective)
	local fail_clbk = objective.fail_clbk
	objective.fail_clbk = nil
	if fail_clbk then
		fail_clbk(unit)
	end
	if not no_new_objective then
		unit:brain():set_objective(nil)
	end
end
function GroupAIStateBase:on_criminal_jobless(unit)
	local new_objective = self:_determine_objective_for_criminal_AI(unit)
	if new_objective then
		unit:brain():set_objective(new_objective)
	end
end
function GroupAIStateBase:_determine_spawn_objective_for_criminal_AI()
	local new_objective
	local valid_criminals = {}
	for pl_key, pl_record in pairs(self._player_criminals) do
		if pl_record.status ~= "dead" then
			table.insert(valid_criminals, pl_key)
		end
	end
	if #valid_criminals > 0 then
		local follow_unit = self._player_criminals[valid_criminals[math.random(#valid_criminals)]].unit
		new_objective = {
			type = "follow",
			follow_unit = follow_unit,
			scan = true
		}
	end
	return new_objective
end
function GroupAIStateBase:_determine_objective_for_criminal_AI(unit)
	local new_objective, closest_dis, closest_record
	local ai_pos = self._ai_criminals[unit:key()].m_pos
	for pl_key, pl_record in pairs(self._player_criminals) do
		if pl_record.status ~= "dead" then
			local my_dis = mvector3.distance(ai_pos, pl_record.m_pos)
			if not closest_dis or closest_dis > my_dis then
				closest_dis = my_dis
				closest_record = pl_record
			end
		end
	end
	if closest_record then
		new_objective = {
			type = "follow",
			scan = true,
			follow_unit = closest_record.unit
		}
	end
	return new_objective
end
function GroupAIStateBase:_coach_last_man_clbk()
	if table.size(self:all_char_criminals()) == 1 and self:bain_state() then
		local _, crim = next(self:all_char_criminals())
		local standing_name = managers.criminals:character_name_by_unit(crim.unit)
		if standing_name == managers.criminals:local_character_name() then
			local ssuffix = managers.criminals:character_static_data_by_name(standing_name).ssuffix
			if self:hostage_count() <= 0 then
				managers.dialog:queue_dialog("ban_h40" .. ssuffix, {})
			else
				managers.dialog:queue_dialog("ban_h42" .. ssuffix, {})
			end
		end
	end
end
function GroupAIStateBase:set_assault_mode(enabled)
	if self._assault_mode ~= enabled then
		self._assault_mode = enabled
		SoundDevice:set_state("wave_flag", enabled and "assault" or "control")
		managers.network:session():send_to_peers_synched("sync_assault_mode", enabled)
		if not enabled then
			self._warned_about_deploy_this_control = nil
			self._warned_about_freed_this_control = nil
			if table.size(self:all_char_criminals()) == 1 then
				self._coach_clbk = callback(self, self, "_coach_last_man_clbk")
				managers.enemy:add_delayed_clbk("_coach_last_man_clbk", self._coach_clbk, Application:time() + 15)
			end
		end
	end
	if SystemInfo:platform() == Idstring("WIN32") and managers.network.account:has_alienware() then
		if self._assault_mode then
			LightFX:set_lamps(255, 0, 0, 255)
		else
			LightFX:set_lamps(0, 255, 0, 255)
		end
	end
end
function GroupAIStateBase:sync_assault_mode(enabled)
	if self._assault_mode ~= enabled then
		self._assault_mode = enabled
		SoundDevice:set_state("wave_flag", enabled and "assault" or "control")
	end
	if SystemInfo:platform() == Idstring("WIN32") and managers.network and managers.network.account:has_alienware() then
		if self._assault_mode then
			LightFX:set_lamps(255, 0, 0, 255)
		else
			LightFX:set_lamps(0, 255, 0, 255)
		end
	end
end
function GroupAIStateBase:set_fake_assault_mode(enabled)
	if self._fake_assault_mode ~= enabled then
		self._fake_assault_mode = enabled
		if self._assault_mode ~= enabled or not self._assault_mode then
			SoundDevice:set_state("wave_flag", enabled and "assault" or "control")
			managers.music:post_event(tweak_data.levels:get_music_event(enabled and "fake_assault" or "control"))
		end
	end
end
function GroupAIStateBase:whisper_mode()
	return self._whisper_mode
end
function GroupAIStateBase:set_whisper_mode(enabled)
	self._whisper_mode = enabled
end
function GroupAIStateBase:set_blackscreen_variant(variant)
	self._blackscreen_variant = variant
end
function GroupAIStateBase:blackscreen_variant(variant)
	return self._blackscreen_variant
end
function GroupAIStateBase:bain_state()
	return self._bain_state
end
function GroupAIStateBase:set_bain_state(enabled)
	self._bain_state = enabled
end
function GroupAIStateBase:set_allow_dropin(enabled)
	self._allow_dropin = enabled
	if Network:is_server() then
		managers.network:session():chk_server_joinable_state()
	end
end
function GroupAIStateBase:sync_hostage_killed_warning(warning)
	if not self:bain_state() then
		return
	end
	if warning == 1 then
		return managers.dialog:queue_dialog("Play_ban_c01", {})
	elseif warning == 2 then
		return managers.dialog:queue_dialog("Play_ban_c02", {})
	elseif warning == 3 then
		return managers.dialog:queue_dialog("Play_ban_c03", {})
	end
end
function GroupAIStateBase:hostage_killed(killer_unit)
	self._hostages_killed = (self._hostages_killed or 0) + 1
	if not self._hunt_mode then
		if self._hostages_killed >= 1 and not self._hostage_killed_warning_lines then
			if self:sync_hostage_killed_warning(1) then
				managers.network:session():send_to_peers_synched("sync_hostage_killed_warning", 1)
				self._hostage_killed_warning_lines = 1
			end
		elseif self._hostages_killed >= 3 and self._hostage_killed_warning_lines == 1 then
			if self:sync_hostage_killed_warning(2) then
				managers.network:session():send_to_peers_synched("sync_hostage_killed_warning", 2)
				self._hostage_killed_warning_lines = 2
			end
		elseif self._hostages_killed >= 7 and self._hostage_killed_warning_lines == 2 and self:sync_hostage_killed_warning(3) then
			managers.network:session():send_to_peers_synched("sync_hostage_killed_warning", 3)
			self._hostage_killed_warning_lines = 3
		end
	end
	if not alive(killer_unit) then
		return
	end
	local key = killer_unit:key()
	local criminal = self._criminals[key]
	if criminal and not criminal.is_deployable then
		local tweak
		if killer_unit:base().is_local_player or killer_unit:base().is_husk_player then
			tweak = tweak_data.player.damage
		else
			tweak = tweak_data.character[killer_unit:base()._tweak_table].damage
		end
		local respawn_penalty = criminal.respawn_penalty or tweak.base_respawn_time_penalty
		criminal.respawn_penalty = respawn_penalty + tweak.respawn_time_penalty
		criminal.hostages_killed = (criminal.hostages_killed or 0) + 1
		print("RC: respawn_penalty", criminal.respawn_penalty)
	end
end
function GroupAIStateBase:on_AI_criminal_death(criminal_name, unit)
	managers.hint:show_hint("teammate_dead", nil, false, {
		TEAMMATE = unit:base():nick_name()
	})
	if not Network:is_server() then
		return
	end
	local respawn_penalty = self._criminals[unit:key()].respawn_penalty or tweak_data.character[unit:base()._tweak_table].damage.base_respawn_time_penalty
	managers.trade:on_AI_criminal_death(criminal_name, respawn_penalty, self._criminals[unit:key()].hostages_killed or 0)
end
function GroupAIStateBase:on_player_criminal_death(peer_id)
	local unit = managers.network:game():unit_from_peer_id(peer_id)
	if not unit then
		return
	end
	local my_peer_id = managers.network:session():local_peer():id()
	if my_peer_id ~= peer_id then
		managers.hint:show_hint("teammate_dead", nil, false, {
			TEAMMATE = unit:base():nick_name()
		})
	end
	if not Network:is_server() then
		return
	end
	local criminal_name = managers.criminals:character_name_by_peer_id(peer_id)
	local respawn_penalty = self._criminals[unit:key()].respawn_penalty or tweak_data.player.damage.base_respawn_time_penalty
	managers.trade:on_player_criminal_death(criminal_name, respawn_penalty, self._criminals[unit:key()].hostages_killed or 0)
end
function GroupAIStateBase:all_AI_criminals()
	return self._ai_criminals
end
function GroupAIStateBase:all_player_criminals()
	return self._player_criminals
end
function GroupAIStateBase:all_criminals()
	return self._criminals
end
function GroupAIStateBase:all_char_criminals()
	return self._char_criminals
end
function GroupAIStateBase:amount_of_ai_criminals()
	local amount = 0
	for _, _ in pairs(self._ai_criminals) do
		amount = amount + 1
	end
	return amount
end
function GroupAIStateBase:amount_of_winning_ai_criminals()
	local amount = 0
	for _, u_data in pairs(self._ai_criminals) do
		if alive(u_data.unit) and not u_data.unit:character_damage():bleed_out() and not u_data.unit:character_damage():fatal() and not u_data.unit:character_damage():arrested() and not u_data.unit:character_damage():dead() then
			amount = amount + 1
		end
	end
	return amount
end
function GroupAIStateBase:fleeing_civilians()
	return self._fleeing_civilians
end
function GroupAIStateBase:all_hostages()
	return self._hostage_keys
end
function GroupAIStateBase:on_criminal_team_AI_enabled_state_changed()
	if Network:is_client() then
		return
	end
	if Global.criminal_team_AI_disabled then
		for i = 1, 3 do
			self:remove_one_teamAI()
		end
	else
		self:fill_criminal_team_with_AI()
	end
end
function GroupAIStateBase:_draw_enemy_importancies()
	for e_key, e_data in pairs(self._police) do
		local imp = e_data.importance
		while imp > 0 do
			Application:draw_sphere(e_data.m_pos, 50 * imp, 1, 1, 1)
			imp = imp - 1
		end
		if e_data.unit:brain()._important then
			Application:draw_cylinder(e_data.m_pos, e_data.m_pos + math.UP * 300, 35, 0, 1, 0)
		end
	end
	for c_key, c_data in pairs(self._player_criminals) do
		local imp_enemies = c_data.important_enemies
		for imp, e_key in ipairs(imp_enemies) do
			local tint = math.clamp(1 - imp / self._nr_important_cops, 0, 1)
			Application:draw_cylinder(self._police[e_key].m_pos, c_data.m_pos, 10, tint, 0, 0, 1 - tint)
		end
	end
end
function GroupAIStateBase:report_cop_to_criminal_dis(cop_unit, dis_report)
	if #dis_report == 0 then
		return
	end
	local t_rem = table.remove
	local t_ins = table.insert
	local max_nr_imp = self._nr_important_cops
	local e_key = cop_unit:key()
	local imp_adj = 0
	local criminals = self._player_criminals
	local cops = self._police
	for i_dis_rep = #dis_report - 1, 1, -2 do
		local c_key = dis_report[i_dis_rep]
		local c_dis = dis_report[i_dis_rep + 1]
		local c_record = criminals[c_key]
		local imp_enemies = c_record.important_enemies
		local imp_dis = c_record.important_dis
		local was_imp
		for i_imp = #imp_enemies, 1, -1 do
			if imp_enemies[i_imp] == e_key then
				table.remove(imp_enemies, i_imp)
				table.remove(imp_dis, i_imp)
				was_imp = true
				break
			end
		end
		local i_imp = #imp_dis
		while true do
			if not (i_imp > 0) or c_dis >= imp_dis[i_imp] then
				break
			end
			i_imp = i_imp - 1
		end
		if max_nr_imp > i_imp then
			i_imp = i_imp + 1
			while max_nr_imp <= #imp_enemies do
				local dump_e_key = imp_enemies[#imp_enemies]
				self:_adjust_cop_importance(dump_e_key, -1)
				t_rem(imp_enemies)
				t_rem(imp_dis)
			end
			t_ins(imp_enemies, i_imp, e_key)
			t_ins(imp_dis, i_imp, c_dis)
			if not was_imp then
				imp_adj = imp_adj + 1
			end
		elseif was_imp then
			imp_adj = imp_adj - 1
		end
	end
	if imp_adj ~= 0 then
		self:_adjust_cop_importance(e_key, imp_adj)
	end
end
function GroupAIStateBase:_adjust_cop_importance(e_key, imp_adj)
	local e_data = self._police[e_key]
	local old_imp = e_data.importance
	e_data.importance = old_imp + imp_adj
	if old_imp == 0 or e_data.importance == 0 then
		e_data.unit:brain():set_important(old_imp == 0)
	end
end
function GroupAIStateBase:sync_smoke_grenade(detonate_pos, shooter_pos, duration)
	self._smoke_grenade = World:spawn_unit(Idstring("units/weapons/smoke_grenade_quick/smoke_grenade_quick"), detonate_pos, Rotation())
	local smoke_duration = duration == 0 and 15 or duration
	self._smoke_grenade:base():activate(shooter_pos or detonate_pos, smoke_duration)
	self._smoke_end_t = Application:time() + smoke_duration
	self._smoke_grenade_queued = nil
	self._smoke_grenade_ignore_control = nil
	managers.groupai:state():teammate_comment(nil, "g40x_any", detonate_pos, true, 2000, false)
end
function GroupAIStateBase:sync_smoke_grenade_kill()
	if alive(self._smoke_grenade) then
		self._smoke_grenade:base():preemptive_kill()
		self._smoke_grenade = nil
	end
	self._smoke_end_t = nil
end
function GroupAIStateBase:_call_listeners(event)
	self._listener_holder:call(event)
end
function GroupAIStateBase:add_listener(key, events, clbk)
	self._listener_holder:add(key, events, clbk)
end
function GroupAIStateBase:remove_listener(key)
	self._listener_holder:remove(key)
end
function GroupAIStateBase:sync_hostage_headcount(nr_hostages)
	if nr_hostages then
		self._hostage_headcount = nr_hostages
	elseif Network:is_server() then
		managers.network:session():send_to_peers_synched("sync_hostage_headcount", math.min(self._hostage_headcount, 63))
	end
	managers.hud:set_control_info({
		nr_hostages = self._hostage_headcount
	})
end
function GroupAIStateBase:_set_rescue_state(state)
	self._rescue_allowed = state
	local all_civilians = managers.enemy:all_civilians()
	for u_key, civ_data in pairs(all_civilians) do
		civ_data.unit:brain():on_rescue_allowed_state(state)
	end
	for u_key, e_data in pairs(self._police) do
		e_data.unit:brain():on_rescue_allowed_state(state)
	end
end
function GroupAIStateBase:rescue_state()
	return self._rescue_allowed
end
function GroupAIStateBase:find_followers_to_unit(leader_key, leader_data)
	local leader_u_data = self._police[leader_key]
	if not leader_u_data then
		return
	end
	leader_u_data.followers = leader_u_data.followers or {}
	local followers = leader_u_data.followers
	local nr_followers = #followers
	local max_nr_followers = leader_data.max_nr_followers
	if nr_followers >= max_nr_followers then
		return
	end
	local wanted_nr_new_followers = max_nr_followers - nr_followers
	local leader_unit = leader_u_data.unit
	local leader_nav_seg = leader_u_data.tracker:nav_segment()
	local objective = {
		type = "follow",
		follow_unit = leader_unit,
		scan = true,
		nav_seg = leader_nav_seg,
		stance = "cbt",
		distance = 600
	}
	local candidates = {}
	for u_key, u_data in pairs(self._police) do
		if u_data.assigned_area and not u_data.follower and u_data.char_tweak.follower and u_data.tracker:nav_segment() == leader_nav_seg and u_data.unit:brain():is_available_for_assignment(objective) then
			table.insert(followers, u_key)
			u_data.follower = leader_key
			local new_follow_objective = clone(objective)
			new_follow_objective.fail_clbk = callback(self, self, "clbk_follow_objective_failed", {
				leader_u_data = leader_u_data,
				follower_unit = u_data.unit
			})
			u_data.unit:brain():set_objective(new_follow_objective)
			if #candidates == wanted_nr_new_followers then
			end
		else
		end
	end
end
function GroupAIStateBase:chk_has_followers(leader_key)
	local leader_u_data = self._police[leader_key]
	if leader_u_data and next(leader_u_data.followers) then
		return true
	end
end
function GroupAIStateBase:are_followers_ready(leader_key)
	local leader_u_data = self._police[leader_key]
	if not leader_u_data or not leader_u_data.followers then
		return true
	end
	for i, follower_key in ipairs(leader_u_data.followers) do
		local follower_u_data = self._police[follower_key]
		local objective = follower_u_data.unit:brain():objective()
		if objective and not objective.in_place then
			return
		end
	end
	return true
end
function GroupAIStateBase:dismiss_followers(leader_key)
	local leader_u_data = self._police[leader_key]
	if leader_u_data.followers then
		for i, follower_key in ipairs(leader_u_data.followers) do
			local follower_u_data = self._police[follower_key]
			local follower_objective = follower_u_data.unit:brain():objective()
			if follower_u_data then
				follower_u_data.follower = nil
			end
			self:on_objective_complete(follower_u_data.unit, follower_objective)
		end
		leader_u_data.followers = nil
	end
end
function GroupAIStateBase:clbk_follow_objective_failed(data)
	local leader_u_data = data.leader_u_data
	local follower_unit = data.follower_unit
	local follower_key = follower_unit:key()
	for i, _follower_key in ipairs(leader_u_data.followers) do
		if _follower_key == follower_key then
			table.remove(leader_u_data.followers, i)
		else
		end
	end
	local follower_u_data = self._police[follower_key]
	if follower_u_data then
		follower_u_data.follower = nil
	end
end
function GroupAIStateBase:chk_area_leads_to_enemy(start_nav_seg_id, test_nav_seg_id, enemy_is_criminal)
	local enemy_areas = {}
	for c_key, c_data in pairs(enemy_is_criminal and self._criminals or self._police) do
		enemy_areas[c_data.tracker:nav_segment()] = true
	end
	local all_nav_segs = managers.navigation._nav_segments
	local found_nav_segs = {
		[start_nav_seg_id] = true,
		[test_nav_seg_id] = true
	}
	local to_search_nav_segs = {test_nav_seg_id}
	repeat
		local chk_nav_seg_id = table.remove(to_search_nav_segs)
		local chk_nav_seg = all_nav_segs[chk_nav_seg_id]
		if enemy_areas[chk_nav_seg_id] then
			return true
		end
		local neighbours = chk_nav_seg.neighbours
		for neighbour_seg_id, door_list in pairs(neighbours) do
			if not all_nav_segs[neighbour_seg_id].disabled and not found_nav_segs[neighbour_seg_id] then
				found_nav_segs[neighbour_seg_id] = true
				table.insert(to_search_nav_segs, neighbour_seg_id)
			end
		end
	until #to_search_nav_segs == 0
end
function GroupAIStateBase:occasional_event_info(event_type)
	return self._occasional_events[event_type]
end
function GroupAIStateBase:on_occasional_event(event_type)
	local event_data = self._occasional_events[event_type]
	if not event_data then
		event_data = {}
		self._occasional_events[event_type] = event_data
	end
	event_data.count = (event_data.count or 0) + 1
	event_data.last_occurence_t = TimerManager:game():time()
end
function GroupAIStateBase:on_player_spawn_state_set(state_name)
	if state_name == "standard" then
		self:on_enemy_weapons_hot()
	end
end
function GroupAIStateBase:chk_say_enemy_chatter(unit, unit_pos, chatter_type)
	local chatter_tweak = tweak_data.group_ai.enemy_chatter[chatter_type]
	local chatter_type_hist = self._enemy_chatter[chatter_type]
	if not chatter_type_hist then
		chatter_type_hist = {
			cooldown_t = 0,
			events = {}
		}
		self._enemy_chatter[chatter_type] = chatter_type_hist
	end
	local t = self._t
	if t < chatter_type_hist.cooldown_t then
		return
	end
	local nr_events_in_area = 0
	for i_event, event_data in pairs(chatter_type_hist.events) do
		if t > event_data.expire_t then
			chatter_type_hist[i_event] = nil
		elseif mvector3.distance(unit_pos, event_data.epicenter) < chatter_tweak.radius then
			if nr_events_in_area == chatter_tweak.max_nr - 1 then
				return
			else
				nr_events_in_area = nr_events_in_area + 1
			end
		end
	end
	local group_requirement = chatter_tweak.group_min
	if group_requirement and group_requirement > 1 then
		local nr_in_group = 0
		local group_dis_sq = 360000
		for e_key, e_data in pairs(self._police) do
			if group_dis_sq > mvector3.distance_sq(unit_pos, e_data.m_pos) then
				local is_free = true
				for _, h_key in ipairs(self._hostage_keys) do
					if e_key == h_key then
						is_free = false
					else
					end
				end
				if is_free then
					nr_in_group = nr_in_group + 1
					if nr_in_group == group_requirement then
					end
				end
			else
			end
		end
		if group_requirement > nr_in_group then
			return
		end
	end
	chatter_type_hist.cooldown_t = t + math.lerp(chatter_tweak.interval[1], chatter_tweak.interval[2], math.random())
	local new_event = {
		epicenter = mvector3.copy(unit_pos),
		expire_t = t + math.lerp(chatter_tweak.duration[1], chatter_tweak.duration[2], math.random())
	}
	table.insert(chatter_type_hist.events, new_event)
	unit:sound():say(chatter_tweak.queue, true)
	return true
end
function GroupAIStateBase:chk_say_teamAI_combat_chatter(unit)
	if not self:is_detection_persistent() then
		return
	end
	local drama_amount = self._drama_data.amount
	local frequency_lerp = drama_amount
	local delay = math.lerp(5, 0.5, frequency_lerp)
	local delay_t = self._teamAI_last_combat_chatter_t + delay
	if delay_t > self._t then
		return
	end
	local frequency_lerp_clamp = math.clamp(frequency_lerp ^ 2, 0, 1)
	local chance = math.lerp(0.01, 0.1, frequency_lerp_clamp)
	if chance < math.random() then
		return
	end
	unit:sound():say("g90", true, true)
end
function GroupAIStateBase:_mark_hostage_areas_as_unsafe()
	local all_areas = self._area_data
	for u_key, u_data in pairs(managers.enemy:all_civilians()) do
		if tweak_data.character[u_data.unit:base()._tweak_table].flee_type == "escape" then
			all_areas[u_data.tracker:nav_segment()].is_safe = nil
		end
	end
end
function GroupAIStateBase:on_nav_link_unregistered(element_id)
	local all_ai = {
		self._police,
		self._ai_criminals,
		managers.enemy:all_civilians()
	}
	for _, ai_group in pairs(all_ai) do
		for u_key, u_data in pairs(ai_group) do
			u_data.unit:movement():on_nav_link_unregistered(element_id)
			u_data.unit:brain():on_nav_link_unregistered(element_id)
		end
	end
end
function GroupAIStateBase:chk_allow_drop_in()
	if self._forbid_drop_in or not self._allow_dropin then
		return false
	end
	return true
end
function GroupAIStateBase:_get_anticipation_duration(anticipation_duration_table, is_first)
	local anticipation_duration = anticipation_duration_table[1][1]
	if not is_first then
		local rand = math.random()
		local accumulated_chance = 0
		for i, setting in pairs(anticipation_duration_table) do
			accumulated_chance = accumulated_chance + setting[2]
			if rand <= accumulated_chance then
				anticipation_duration = setting[1]
			else
			end
		end
	end
	return anticipation_duration
end
