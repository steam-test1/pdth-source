SecretAssignmentManager = SecretAssignmentManager or class()
function SecretAssignmentManager:init()
	self._enabled = true
	self:_setup()
end
function SecretAssignmentManager:_setup()
	self._debug = false
	self._assignments = {}
	self._has_delegated = nil
	self._current_assignment = nil
	for name, data in pairs(tweak_data.secret_assignment_manager) do
		self._assignments[name] = {can_be_activated = false, enabled = true}
	end
	self._chance = {}
	self._chance.test_interval = 60
	self._chance.interval_timer = self._chance.test_interval
	self._chance.chance = 5
end
function SecretAssignmentManager:assignments()
	return self._assignments
end
function SecretAssignmentManager:update(t, dt)
	do return end
	if self._current_assignment and self._current_assignment.timer then
		self._current_assignment.timer = self._current_assignment.timer - dt
		managers.hud:feed_secret_assignment_timer(self._current_assignment.timer)
		if self._current_assignment.timer < 0 then
			self._current_assignment.timer = nil
			if tweak_data.secret_assignment_manager[self._current_assignment.name].time_limit_success then
				self:_complete_assignment(self._current_assignment.name)
			else
				self:_fail_assignment(self._current_assignment.name)
			end
		end
	end
	if Network:is_client() then
		return
	end
	if not self._enabled then
		return
	end
	if self._has_delegated then
		return
	end
	self._chance.interval_timer = self._chance.interval_timer - dt
	if 0 >= self._chance.interval_timer then
		self._chance.interval_timer = self._chance.test_interval
		if math.random(self._chance.chance) == 1 then
			self:delegate_assignment()
		end
	end
end
function SecretAssignmentManager:set_enabled(enabled)
	self._enabled = enabled
end
function SecretAssignmentManager:set_assignment_enabled(name, enabled)
	if self._assignments[name] then
		self._assignments[name].enabled = enabled
	else
		Application:error("Can't set enabled state for secret assignment " .. name)
	end
end
function SecretAssignmentManager:register_unit(unit)
	if not unit:unit_data().secret_assignment_id then
		return
	end
	local id = unit:unit_data().secret_assignment_id
	for name, data in pairs(tweak_data.secret_assignment_manager) do
		if name == id then
			self._assignments[name].can_be_activated = true
			if data.type == "interact" then
				self._assignments[name].available_units = self._assignments[name].available_units or {}
				table.insert(self._assignments[name].available_units, unit)
				if data.amount then
					self._assignments[name].can_be_activated = #self._assignments[name].available_units >= data.amount
				end
				break
			end
			if data.type == "kill" then
				self._assignments[name].unit = unit
				unit:unit_data().mission_element:add_event_callback("death", callback(self, self, "unregister_unit"))
			end
			break
		end
	end
end
function SecretAssignmentManager:register_civilian(unit)
	local name = "civilian_escape"
	self._assignments[name].amount_of_units = (self._assignments[name].amount_of_units or 0) + 1
	self._assignments[name].can_be_activated = self._assignments[name].amount_of_units > 0
	unit:unit_data().mission_element:add_event_callback("death", callback(self, self, "unregister_civilian"))
	unit:unit_data().mission_element:add_event_callback("fled", callback(self, self, "unregister_civilian"))
end
function SecretAssignmentManager:unregister_civilian(unit)
	local name = "civilian_escape"
	self._assignments[name].amount_of_units = self._assignments[name].amount_of_units - 1
	self._assignments[name].can_be_activated = self._assignments[name].amount_of_units > 0
end
function SecretAssignmentManager:unregister_unit(unit, failed)
	if not unit:unit_data().secret_assignment_id then
		return
	end
	local id = unit:unit_data().secret_assignment_id
	for name, data in pairs(tweak_data.secret_assignment_manager) do
		if name == id then
			if data.type == "interact" then
				for i, u in ipairs(self._assignments[name].available_units) do
					if u == unit then
						table.remove(self._assignments[name].available_units, i)
						break
					end
				end
				self._assignments[name].can_be_activated = #self._assignments[name].available_units > (data.amount or 0)
				break
			end
			if data.type == "kill" and self._assignments[name].unit == unit then
				if failed and self._assignments[name].assigned then
					self._assignments[name].peer:send_queued_sync("failed_secret_assignment", name)
				end
				self._assignments[name].unit = nil
				self._assignments[name].can_be_activated = false
			end
			break
		end
	end
end
function SecretAssignmentManager:interacted(name)
	if not self._assignments[name].assigned then
		Application:error("Assignment", name, "has not been given!")
		return
	end
	if self._current_assignment.counter then
		self._current_assignment.counter = self._current_assignment.counter + 1
		managers.hud:feed_secret_assignment_counter(self._current_assignment.counter, tweak_data.secret_assignment_manager[name].amount)
		if self._current_assignment.counter ~= tweak_data.secret_assignment_manager[name].amount then
			return
		end
	end
	self:_complete_assignment(name)
end
function SecretAssignmentManager:target_killed(unit)
	local name = unit:unit_data().secret_assignment_id
	self._assignments[name].peer:send_queued_sync("complete_secret_assignment", name)
end
function SecretAssignmentManager:civilian_escaped()
	if not self._has_delegated then
		return
	end
	local name = "civilian_escape"
	if self._has_delegated == name then
		self._assignments[name].peer:send_queued_sync("failed_secret_assignment", name)
	end
end
function SecretAssignmentManager:complete_secret_assignment(name)
	if not self._current_assignment then
		Application:error("Didn't have a current secret assignment")
		return
	end
	self:_complete_assignment(name)
end
function SecretAssignmentManager:failed_secret_assignment(name)
	if not self._current_assignment then
		Application:error("Didn't have a current secret assignment")
		return
	end
	self:_fail_assignment(name)
end
function SecretAssignmentManager:_complete_assignment(name)
	local data = tweak_data.secret_assignment_manager[name]
	local title = managers.localization:text("sa_prefix_completed")
	local text = managers.localization:text(data.title_id)
	managers.hud:present_mid_text({
		title = title,
		text = text,
		time = 4,
		icon = nil,
		event = "stinger_feedback_positive"
	})
	managers.hud:complete_secret_assignment({success = true})
	managers.experience:perform_action("secret_assignment")
	self._assignments[name].completed = true
	self._assignments[name].assigned = false
	self._current_assignment = nil
	if Network:is_server() then
		self:secret_assignment_done(name, true)
	else
		managers.network:session():send_to_host("secret_assignment_done", name, true)
	end
end
function SecretAssignmentManager:_fail_assignment(name)
	local data = tweak_data.secret_assignment_manager[name]
	local title = managers.localization:text("sa_prefix_failed")
	local text = managers.localization:text(data.title_id)
	managers.hud:present_mid_text({
		title = title,
		text = text,
		time = 4,
		icon = nil,
		event = "stinger_feedback_negative"
	})
	managers.hud:complete_secret_assignment({success = false})
	self._assignments[name].completed = true
	self._assignments[name].assigned = false
	if tweak_data.secret_assignment_manager[name].type == "interact" then
		for _, unit in ipairs(self._current_assignment.units) do
			unit:interaction():set_assignment(nil)
			unit:interaction():set_active(false)
		end
	end
	self._current_assignment = nil
	if Network:is_server() then
		self:secret_assignment_done(name, false)
	else
		managers.network:session():send_to_host("secret_assignment_done", name, false)
	end
end
function SecretAssignmentManager:secret_assignment_done(name, success)
	self._assignments[name].completed = success
	self._assignments[name].assigned = false
	self._has_delegated = false
end
function SecretAssignmentManager:delegate_assignment()
	local can_be_activated = self:_get_available_assignments()
	if #can_be_activated == 0 then
		return
	end
	local name = can_be_activated[math.random(#can_be_activated)]
	local peer = self:_get_peer()
	if not peer then
		return
	end
	self._assignments[name].peer = peer
	self._assignments[name].assigned = true
	if tweak_data.secret_assignment_manager[name].type == "kill" then
		self._assignments[name].unit:unit_data().mission_element:add_event_callback("death", callback(self, self, "target_killed"))
	end
	peer:send_queued_sync("assign_secret_assignment", name)
	self._has_delegated = name
end
function SecretAssignmentManager:_get_available_assignments()
	if managers.groupai:state():get_assault_mode() then
		return {}
	end
	local t = {}
	for name, data in pairs(self._assignments) do
		local level_filter = self:_check_level_filter(name)
		if data.can_be_activated and not self._debug and not data.assigned and not data.completed and data.enabled and level_filter then
			table.insert(t, name)
		end
	end
	return t
end
function SecretAssignmentManager:_check_level_filter(name)
	if not Global.level_data.level_id then
		return true
	end
	local level_filter = tweak_data.secret_assignment_manager[name].level_filter
	if not level_filter then
		return true
	end
	if level_filter.include then
		for _, lvl_id in ipairs(level_filter.include) do
			if lvl_id == Global.level_data.level_id then
				return true
			end
		end
		return false
	end
	if level_filter.exclude then
		for _, lvl_id in ipairs(level_filter.exclude) do
			if lvl_id == Global.level_data.level_id then
				return false
			end
		end
		return true
	end
	return true
end
function SecretAssignmentManager:_get_peer()
	if not managers.network:game() then
		return nil
	end
	local members = {}
	for id, member in pairs(managers.network:game():all_members()) do
		if member:unit() and member:unit():movement():current_state_name() ~= "mask_off" then
			table.insert(members, id)
		end
	end
	if 0 < #members then
		return managers.network:session():peer(members[math.random(#members)])
	end
	return nil
end
function SecretAssignmentManager:assign(name)
	local data = tweak_data.secret_assignment_manager[name]
	self._current_assignment = self._assignments[name]
	self._current_assignment.name = name
	self._current_assignment.timer = data.time_limit
	self._current_assignment.counter = data.amount and 0 or nil
	self._assignments[name].assigned = true
	local title = managers.localization:text("sa_prefix_assign")
	local text = managers.localization:text(data.title_id)
	managers.hud:present_mid_text({
		title = title,
		text = text,
		time = 4,
		icon = nil,
		event = "stinger_levelup"
	})
	local assignment = managers.localization:text(data.title_id)
	local description = managers.localization:text(data.description_id)
	local status_time = self._current_assignment.timer and true
	local status_counter = self._current_assignment.counter and true
	managers.hud:present_secret_assignment({
		assignment = assignment,
		description = description,
		status_time = status_time,
		status_counter = status_counter
	})
	if self._current_assignment.counter then
		managers.hud:feed_secret_assignment_counter(self._current_assignment.counter, data.amount)
	end
	if data.type == "interact" then
		self:_start_interact_assignment(name)
	elseif data.type == "kill" then
	end
end
function SecretAssignmentManager:_start_interact_assignment(name)
	self._current_assignment.units = {}
	local counter = tweak_data.secret_assignment_manager[name].amount or 1
	local t = {}
	for i = 1, #self._assignments[name].available_units do
		t[i] = i
	end
	for i = 1, counter do
		local t_val = math.random(#t)
		local val = table.remove(t, t_val)
		local unit = self._assignments[name].available_units[val]
		unit:interaction():set_assignment(name)
		unit:interaction():set_active(true)
		table.insert(self._current_assignment.units, unit)
	end
end
function SecretAssignmentManager:assignment_names()
	local t = {}
	for name, _ in pairs(tweak_data.secret_assignment_manager) do
		table.insert(t, name)
	end
	table.sort(t)
	return t
end
function SecretAssignmentManager:reset()
	self:_setup()
	managers.hud:complete_secret_assignment({})
end
