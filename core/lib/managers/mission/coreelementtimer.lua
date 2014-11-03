core:module("CoreElementTimer")
core:import("CoreMissionScriptElement")
ElementTimer = ElementTimer or class(CoreMissionScriptElement.MissionScriptElement)
function ElementTimer:init(...)
	ElementTimer.super.init(self, ...)
	self._timer = self._values.timer
	self._triggers = {}
end
function ElementTimer:on_script_activated()
end
function ElementTimer:set_enabled(enabled)
	ElementTimer.super.set_enabled(self, enabled)
end
function ElementTimer:add_updator()
	if not Network:is_server() then
		return
	end
	if not self._updator then
		self._updator = true
		self._mission_script:add_updator(self._id, callback(self, self, "update_timer"))
	end
end
function ElementTimer:remove_updator()
	if self._updator then
		self._mission_script:remove_updator(self._id)
		self._updator = nil
	end
end
function ElementTimer:update_timer(t, dt)
	self._timer = self._timer - dt
	if self._timer <= 0 then
		self:remove_updator()
		self:on_executed()
	end
	for id, cb_data in pairs(self._triggers) do
		if cb_data.time >= self._timer then
			cb_data.callback()
			self:remove_trigger(id)
		end
	end
end
function ElementTimer:client_on_executed(...)
end
function ElementTimer:on_executed(instigator)
	if not self._values.enabled then
		return
	end
	ElementTimer.super.on_executed(self, instigator)
end
function ElementTimer:timer_operation_pause()
	self:remove_updator()
end
function ElementTimer:timer_operation_start()
	self:add_updator()
end
function ElementTimer:timer_operation_add_time(time)
	self._timer = self._timer + time
end
function ElementTimer:timer_operation_subtract_time(time)
	self._timer = self._timer - time
end
function ElementTimer:timer_operation_reset()
	self._timer = self._values.timer
end
function ElementTimer:timer_operation_set_time(time)
	self._timer = time
end
function ElementTimer:add_trigger(id, time, callback)
	self._triggers[id] = {time = time, callback = callback}
end
function ElementTimer:remove_trigger(id)
	self._triggers[id] = nil
end
ElementTimerOperator = ElementTimerOperator or class(CoreMissionScriptElement.MissionScriptElement)
function ElementTimerOperator:init(...)
	ElementTimerOperator.super.init(self, ...)
end
function ElementTimerOperator:client_on_executed(...)
end
function ElementTimerOperator:on_executed(instigator)
	if not self._values.enabled then
		return
	end
	for _, id in ipairs(self._values.elements) do
		local element = self:get_mission_element(id)
		if element then
			if self._values.operation == "pause" then
				element:timer_operation_pause()
			elseif self._values.operation == "start" then
				element:timer_operation_start()
			elseif self._values.operation == "add_time" then
				element:timer_operation_add_time(self._values.time)
			elseif self._values.operation == "subtract_time" then
				element:timer_operation_subtract_time(self._values.time)
			elseif self._values.operation == "reset" then
				element:timer_operation_reset(self._values.time)
			elseif self._values.operation == "set_time" then
				element:timer_operation_set_time(self._values.time)
			end
		end
	end
	ElementTimerOperator.super.on_executed(self, instigator)
end
ElementTimerTrigger = ElementTimerTrigger or class(CoreMissionScriptElement.MissionScriptElement)
function ElementTimerTrigger:init(...)
	ElementTimerTrigger.super.init(self, ...)
end
function ElementTimerTrigger:on_script_activated()
	for _, id in ipairs(self._values.elements) do
		local element = self:get_mission_element(id)
		element:add_trigger(self._id, self._values.time, callback(self, self, "on_executed"))
	end
end
function ElementTimerTrigger:client_on_executed(...)
end
function ElementTimerTrigger:on_executed(instigator)
	if not self._values.enabled then
		return
	end
	ElementTimerTrigger.super.on_executed(self, instigator)
end
