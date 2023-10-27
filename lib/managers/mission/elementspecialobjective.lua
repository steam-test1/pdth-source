core:import("CoreMissionScriptElement")
ElementSpecialObjective = ElementSpecialObjective or class(CoreMissionScriptElement.MissionScriptElement)
ElementSpecialObjective._pathing_types = {
	"destination",
	"precise",
	"coarse"
}
ElementSpecialObjective._pathing_type_default = "destination"
function ElementSpecialObjective:init(...)
	ElementSpecialObjective.super.init(self, ...)
	if self._values.SO_access then
		local access_filter_version = self._values.access_flag_version or 1
		if access_filter_version ~= managers.navigation.ACCESS_FLAGS_VERSION then
			print("[ElementSpecialObjective:init] converting access flag", access_filter_version, self._values.SO_access)
			self._values.SO_access = managers.navigation:upgrade_access_filter(tonumber(self._values.SO_access), access_filter_version)
			print("[ElementSpecialObjective:init] converted to", self._values.SO_access)
		else
			self._values.SO_access = tonumber(self._values.SO_access)
		end
	end
	self._events = {}
end
function ElementSpecialObjective:event(name, unit)
	if self._events[name] then
		for _, callback in ipairs(self._events[name]) do
			callback(unit)
		end
	end
end
function ElementSpecialObjective:clbk_objective_action_start(unit)
	self:event("anim_start", unit)
end
function ElementSpecialObjective:clbk_objective_administered(unit)
	self._administered_to_unit = unit
	self:event("administered", unit)
end
function ElementSpecialObjective:clbk_objective_complete(unit)
	self._administered_to_unit = nil
	self:event("complete", unit)
end
function ElementSpecialObjective:clbk_objective_failed(unit)
	if managers.editor and managers.editor._stopping_simulation then
		return
	end
	self:event("fail", unit)
end
function ElementSpecialObjective:add_event_callback(name, callback)
	self._events[name] = self._events[name] or {}
	table.insert(self._events[name], callback)
end
function ElementSpecialObjective:on_executed(instigator)
	if not self._values.enabled or Network:is_client() then
		return
	end
	if not managers.groupai:state():is_AI_enabled() and not Application:editor() then
	elseif self._values.spawn_instigator_ids and next(self._values.spawn_instigator_ids) then
		local chosen_units = self:_select_units_from_spawners()
		if chosen_units then
			for _, chosen_unit in ipairs(chosen_units) do
				local objective = self:get_objective(chosen_unit)
				if objective then
					self:_administer_objective(chosen_unit, objective)
				end
			end
		end
	elseif self._values.use_instigator then
		if self:_is_nav_link() then
			Application:error("[ElementSpecialObjective:on_executed] Ambiguous nav_link/SO. Element id:", self._id)
		elseif alive(instigator) then
			if instigator:brain() then
				if not instigator:character_damage() or not instigator:character_damage():dead() then
					local objective = self:get_objective(instigator)
					if objective then
						self:_administer_objective(instigator, objective)
					end
				end
			else
				Application:error("[ElementSpecialObjective:on_executed] Special Objective instigator is not an AI unit. Possibly improper \"use instigator\" flag use. Element id:", self._id)
			end
		elseif not instigator then
			Application:error("[ElementSpecialObjective:on_executed] Special Objective missing instigator. Possibly improper \"use instigator\" flag use. Element id:", self._id)
		end
	elseif self:_is_nav_link() then
		if self._values.so_action and self._values.so_action ~= "none" then
			managers.navigation:register_anim_nav_link(self)
		else
			Application:error("[ElementSpecialObjective:on_executed] Nav link without animation specified. Element id:", self._id)
		end
	else
		local objective = self:get_objective(instigator)
		if objective then
			local search_dis_sq = self._values.search_distance
			search_dis_sq = search_dis_sq ~= 0 and search_dis_sq * search_dis_sq or nil
			local so_descriptor = {
				objective = objective,
				base_chance = self._values.base_chance,
				chance_inc = self._values.chance_inc,
				interval = self._values.interval,
				search_dis_sq = search_dis_sq,
				search_pos = self._values.search_position,
				usage_amount = self._values.trigger_times,
				AI_group = self._values.ai_group or "enemies",
				access = self._values.SO_access and tonumber(self._values.SO_access) or managers.navigation:convert_SO_AI_group_to_access(self._values.ai_group or "enemies"),
				repeatable = self._values.repeatable,
				admin_clbk = callback(self, self, "clbk_objective_administered")
			}
			if so_descriptor.usage_amount and so_descriptor.usage_amount < 1 then
				so_descriptor.usage_amount = nil
			end
			managers.groupai:state():add_special_objective(self._id, so_descriptor)
		end
	end
	ElementSpecialObjective.super.on_executed(self, instigator)
end
function ElementSpecialObjective:operation_remove()
	if self._nav_link then
		managers.navigation:unregister_anim_nav_link(self)
	else
		managers.groupai:state():remove_special_objective(self._id)
	end
end
function ElementSpecialObjective:get_objective(instigator)
	local is_AI_SO = self._is_AI_SO or string.begins(self._values.so_action, "AI")
	local pose, stance, attitude, path_style, pos, rot, interrupt, haste, trigger_on, interaction_voice = self:_get_misc_SO_params()
	local objective = {
		type = false,
		pos = pos,
		rot = rot,
		path_data = false,
		path_style = path_style,
		attitude = attitude,
		stance = stance,
		pose = pose,
		haste = haste,
		interrupt_on = interrupt,
		no_retreat = not interrupt,
		trigger_on = trigger_on,
		interaction_voice = interaction_voice,
		followup_SO = self._values.follow_up_id,
		action_start_clbk = callback(self, self, "clbk_objective_action_start"),
		fail_clbk = callback(self, self, "clbk_objective_failed"),
		complete_clbk = callback(self, self, "clbk_objective_complete"),
		scan = self._values.scan
	}
	if self._values.follow_up_id then
		local so_element = managers.mission:get_element_by_id(self._values.follow_up_id)
		if so_element:get_objective_trigger() then
			objective.followup_objective = so_element:get_objective()
			objective.followup_SO = nil
		end
	end
	if is_AI_SO then
		local objective_type = string.sub(self._values.so_action, 4)
		local last_pos, nav_seg
		if objective_type == "hunt" then
			nav_seg, last_pos = self:_get_hunt_location(instigator)
			if not nav_seg then
				return
			end
		else
			local path_name = self._values.patrol_path
			if path_name == "none" then
				last_pos = pos or self._values.position
			elseif path_style == "destination" then
				local path_data = managers.ai_data:destination_path(self._values.position, self._values.rotation)
				objective.path_data = path_data
				last_pos = self._values.position
			else
				local path_data = managers.ai_data:patrol_path(path_name)
				objective.path_data = path_data
				local points = path_data.points
				last_pos = points[#points].position
			end
			objective.pos = objective.pos or mvector3.copy(last_pos)
		end
		if objective_type == "search" or objective_type == "hunt" then
			objective.type = "investigate_area"
			objective.nav_seg = nav_seg or last_pos and managers.navigation:get_nav_seg_from_pos(last_pos)
		elseif objective_type == "defend" then
			objective.type = "defend_area"
			objective.scan = true
			objective.nav_seg = nav_seg or last_pos and managers.navigation:get_nav_seg_from_pos(last_pos)
		else
			objective.type = objective_type
			objective.nav_seg = nav_seg or pos and last_pos and managers.navigation:get_nav_seg_from_pos(last_pos)
			if objective_type == "sniper" then
				objective.no_retreat = true
			end
		end
	else
		local action
		if self._values.so_action ~= "none" then
			action = {
				type = "act",
				variant = self._values.so_action,
				body_part = 1,
				blocks = {
					action = -1,
					walk = -1,
					light_hurt = -1,
					hurt = -1,
					heavy_hurt = -1
				},
				align_sync = true,
				needs_full_blend = true
			}
			objective.type = "act"
		else
			objective.type = "free"
		end
		objective.action = action
		if self._values.align_position then
			objective.nav_seg = managers.navigation:get_nav_seg_from_pos(self._values.position)
			if path_style == "destination" then
				local path_data = managers.ai_data:destination_path(self._values.position, self._values.rotation)
				objective.path_data = path_data
			else
				local path_name = self._values.patrol_path
				local path_data = managers.ai_data:patrol_path(path_name)
				objective.path_data = path_data
				if not self._values.align_rotation then
					objective.rot = nil
				end
			end
		end
	end
	return objective
end
function ElementSpecialObjective:_get_hunt_location(instigator)
	if not alive(instigator) then
		return
	end
	local from_pos = instigator:movement():m_pos()
	local nearest_criminal, nearest_dis, nearest_pos
	local criminals = managers.groupai:state():all_criminals()
	for u_key, record in pairs(criminals) do
		if not record.status then
			local my_dis = mvector3.distance(from_pos, record.m_pos)
			if not nearest_dis or nearest_dis > my_dis then
				nearest_dis = my_dis
				nearest_criminal = record.unit
				nearest_pos = record.m_pos
			end
		end
	end
	if not nearest_criminal then
		print("[ElementSpecialObjective:_create_SO_hunt] Could not find a criminal to hunt")
		return
	end
	local criminal_tracker = nearest_criminal:movement():nav_tracker()
	local objective_nav_seg = criminal_tracker:nav_segment()
	return objective_nav_seg, criminal_tracker:field_position()
end
function ElementSpecialObjective:_get_misc_SO_params()
	local pose, stance, attitude, path_style, pos, rot, interrupt, haste, trigger_on, interaction_voice
	local values = self._values
	pos = values.align_position and values.position
	rot = values.align_rotation and values.rotation
	path_style = values.path_style
	attitude = values.attitude ~= "none" and values.attitude
	stance = values.path_stance ~= "none" and values.path_stance
	pose = values.pose ~= "none" and values.pose
	interrupt = values.interrupt_on ~= "none" and values.interrupt_on
	haste = values.path_haste ~= "none" and values.path_haste
	trigger_on = values.trigger_on ~= "none" and values.trigger_on
	interaction_voice = values.interaction_voice ~= "default" and values.interaction_voice
	return pose, stance, attitude, path_style, pos, rot, interrupt, haste, trigger_on, interaction_voice
end
function ElementSpecialObjective:nav_link_end_pos()
	return self._values.search_position
end
function ElementSpecialObjective:nav_link_access()
	local access
	if self._values.SO_access then
		access = tonumber(self._values.SO_access)
	else
		access = managers.navigation:convert_nav_link_maneuverability_to_SO_access(self._values.navigation_link)
	end
	return access
end
function ElementSpecialObjective:nav_link_delay()
	return self._values.interval
end
function ElementSpecialObjective:nav_link()
	return self._nav_link
end
function ElementSpecialObjective:_is_nav_link()
	return self._values.is_navigation_link or self._values.navigation_link and self._values.navigation_link ~= -1
end
function ElementSpecialObjective:set_nav_link(nav_link)
	self._nav_link = nav_link
end
function ElementSpecialObjective:nav_link_wants_align_pos()
	return self._values.align_position
end
function ElementSpecialObjective:_select_units_from_spawners()
	local candidates = {}
	for _, element_id in ipairs(self._values.spawn_instigator_ids) do
		local spawn_element = managers.mission:get_element_by_id(element_id)
		for _, unit in ipairs(spawn_element:units()) do
			if alive(unit) and unit:brain():is_available_for_assignment() then
				table.insert(candidates, unit)
			end
		end
	end
	local wanted_nr_units
	if self._values.trigger_times <= 0 then
		wanted_nr_units = 1
	else
		wanted_nr_units = self._values.trigger_times
	end
	wanted_nr_units = math.min(wanted_nr_units, #candidates)
	local chosen_units = {}
	for i = 1, wanted_nr_units do
		local chosen_unit = table.remove(candidates, math.random(#candidates))
		table.insert(chosen_units, chosen_unit)
	end
	return chosen_units
end
function ElementSpecialObjective:get_objective_trigger()
	return self._values.trigger_on ~= "none" and self._values.trigger_on
end
function ElementSpecialObjective:_administer_objective(unit, objective)
	if objective.trigger_on == "interact" then
		if not unit:brain():objective() then
			local idle_objective = {type = "free", followup_objective = objective}
			unit:brain():set_objective(idle_objective)
		end
		unit:brain():set_followup_objective(objective)
		return
	end
	if unit:brain():is_available_for_assignment(objective) or not unit:brain():objective() then
		if objective.nav_seg then
			local u_key = unit:key()
			local u_data = managers.enemy:all_enemies()[u_key]
			if u_data and u_data.assigned_area then
				managers.groupai:state():set_enemy_assigned(objective.nav_seg, u_key)
			end
		end
		unit:brain():set_objective(objective)
	else
		unit:brain():set_followup_objective(objective)
	end
end
