core:module("CoreElementCounter")
core:import("CoreMissionScriptElement")
ElementCounter = ElementCounter or class(CoreMissionScriptElement.MissionScriptElement)
function ElementCounter:init(...)
	ElementCounter.super.init(self, ...)
end
function ElementCounter:on_executed(instigator)
	if not self._values.enabled then
		return
	end
	if self._values.counter_target > 0 then
		self._values.counter_target = self._values.counter_target - 1
		if self:is_debug() then
			self._mission_script:debug_output("Counter " .. self._editor_name .. ": " .. self._values.counter_target .. " Previous value: " .. self._values.counter_target + 1, Color(1, 0, 0.75, 0))
		end
		if self._values.counter_target == 0 then
			ElementCounter.super.on_executed(self, instigator)
		end
	elseif self:is_debug() then
		self._mission_script:debug_output("Counter " .. self._editor_name .. ": already exhausted!", Color(1, 0, 0.75, 0))
	end
end
function ElementCounter:reset_counter_target(counter_target)
	self._values.counter_target = counter_target
end
ElementCounterReset = ElementCounterReset or class(CoreMissionScriptElement.MissionScriptElement)
function ElementCounterReset:init(...)
	ElementCounterReset.super.init(self, ...)
end
function ElementCounterReset:on_executed(instigator)
	if not self._values.enabled then
		return
	end
	for _, id in ipairs(self._values.elements) do
		local element = self:get_mission_element(id)
		if element then
			if self:is_debug() then
				self._mission_script:debug_output("Counter reset " .. element:editor_name() .. " to: " .. self._values.counter_target, Color(1, 0, 0.75, 0))
			end
			element:reset_counter_target(self._values.counter_target)
		end
	end
	ElementCounterReset.super.on_executed(self, instigator)
end
