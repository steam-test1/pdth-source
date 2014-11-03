core:module("CoreElementArea")
core:import("CoreShapeManager")
core:import("CoreMissionScriptElement")
core:import("CoreTable")
ElementAreaTrigger = ElementAreaTrigger or class(CoreMissionScriptElement.MissionScriptElement)
function ElementAreaTrigger:init(...)
	ElementAreaTrigger.super.init(self, ...)
	self._last_project_amount_all = 0
	self._shape = CoreShapeManager.ShapeBoxMiddle:new({
		position = self._values.position,
		rotation = self._values.rotation,
		width = self._values.width,
		depth = self._values.depth,
		height = self._values.height
	})
	self._inside = {}
end
function ElementAreaTrigger:on_script_activated()
	self._mission_script:add_save_state_cb(self._id)
	if self._values.enabled then
		self:add_callback()
	end
end
function ElementAreaTrigger:set_enabled(enabled)
	if not enabled and Network:is_server() and self._values.trigger_on == "both" then
		for _, unit in ipairs(CoreTable.clone(self._inside)) do
			self:sync_exit_area(unit)
		end
	end
	ElementAreaTrigger.super.set_enabled(self, enabled)
	if enabled then
		self:add_callback()
	else
		self:remove_callback()
	end
end
function ElementAreaTrigger:add_callback()
	if not self._callback then
		self._callback = self._mission_script:add(callback(self, self, "update_area"), self._values.interval)
	end
end
function ElementAreaTrigger:remove_callback()
	if self._callback then
		self._mission_script:remove(self._callback)
		self._callback = nil
	end
end
function ElementAreaTrigger:on_executed(instigator)
	if not self._values.enabled then
		return
	end
	ElementAreaTrigger.super.on_executed(self, instigator)
	if not self._values.enabled then
		self:remove_callback()
	end
end
function ElementAreaTrigger:instigators()
	local instigators = self:project_instigators()
	for _, id in ipairs(self._values.spawn_unit_elements) do
		local element = self:get_mission_element(id)
		if element then
			for _, unit in ipairs(element:units()) do
				table.insert(instigators, unit)
			end
		end
	end
	return instigators
end
function ElementAreaTrigger:project_instigators()
	return {}
end
function ElementAreaTrigger:project_amount_all()
	return nil
end
function ElementAreaTrigger:update_area()
	if not self._values.enabled then
		return
	end
	if self._values.trigger_on == "on_empty" then
		if Network:is_server() then
			self._inside = {}
			for _, unit in ipairs(self:instigators()) do
				if alive(unit) then
					self:_should_trigger(unit)
				end
			end
			if #self._inside == 0 then
				self:on_executed()
			end
		end
	else
		local instigators = self:instigators()
		if #instigators == 0 and Network:is_server() then
			if self:_should_trigger(nil) then
				self:_check_amount(nil)
			end
		else
			for _, unit in ipairs(instigators) do
				if alive(unit) then
					if Network:is_client() then
						self:_client_check_state(unit)
					elseif self:_should_trigger(unit) then
						self:_check_amount(unit)
					end
				end
			end
		end
	end
end
function ElementAreaTrigger:sync_enter_area(unit)
	table.insert(self._inside, unit)
	if self._values.trigger_on == "on_enter" or self._values.trigger_on == "both" then
		self:_check_amount(unit)
	end
end
function ElementAreaTrigger:sync_exit_area(unit)
	table.delete(self._inside, unit)
	if self._values.trigger_on == "on_exit" or self._values.trigger_on == "both" then
		self:_check_amount(unit)
	end
end
function ElementAreaTrigger:_check_amount(unit)
	if self._values.trigger_on == "on_enter" then
		local amount = self._values.amount == "all" and self:project_amount_all()
		amount = amount or tonumber(self._values.amount)
		self:_clean_destroyed_units()
		if #self._inside > 0 and (amount and amount <= #self._inside or not amount) then
			self:on_executed(unit)
		end
	else
		self:on_executed(unit)
	end
end
function ElementAreaTrigger:_should_trigger(unit)
	if alive(unit) then
		local inside = self._shape:is_inside(unit:movement():m_pos())
		if table.contains(self._inside, unit) then
			if not inside then
				table.delete(self._inside, unit)
				if self._values.trigger_on == "on_exit" or self._values.trigger_on == "both" then
					return true
				end
			end
		elseif inside then
			table.insert(self._inside, unit)
			if self._values.trigger_on == "on_enter" or self._values.trigger_on == "both" then
				return true
			end
		end
	end
	if self._values.amount == "all" then
		local project_amount_all = self:project_amount_all()
		if project_amount_all ~= self._last_project_amount_all then
			self._last_project_amount_all = project_amount_all
			self:_clean_destroyed_units()
			return true
		end
	end
	return false
end
function ElementAreaTrigger:_clean_destroyed_units()
	for i, unit in pairs(CoreTable.clone(self._inside)) do
		if not alive(unit) then
			table.remove(self._inside, i)
		end
	end
end
function ElementAreaTrigger:_client_check_state(unit)
	local inside = self._shape:is_inside(unit:position())
	if table.contains(self._inside, unit) then
		if not inside then
			table.delete(self._inside, unit)
			managers.network:session():send_to_host("to_server_exit_area", self._id, unit)
		end
	elseif inside then
		table.insert(self._inside, unit)
		managers.network:session():send_to_host("to_server_enter_area", self._id, unit)
	end
end
function ElementAreaTrigger:save(data)
	data.enabled = self._values.enabled
end
function ElementAreaTrigger:load(data)
	self:set_enabled(data.enabled)
end
