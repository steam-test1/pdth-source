core:module("CoreMissionScriptElement")
core:import("CoreXml")
core:import("CoreCode")
core:import("CoreClass")
MissionScriptElement = MissionScriptElement or class()
function MissionScriptElement:init(mission_script, data)
	self._mission_script = mission_script
	self._values_extensions = {}
	self._id = data.id
	self._editor_name = data.editor_name
	self._values = data.values
end
function MissionScriptElement:on_created()
end
function MissionScriptElement:on_script_activated()
end
function MissionScriptElement:get_mission_element(id)
	return self._mission_script:element(id)
end
function MissionScriptElement:editor_name()
	return self._editor_name
end
function MissionScriptElement:values()
	return self._values
end
function MissionScriptElement:value(name)
	return self._values[name]
end
function MissionScriptElement:enabled()
	return self._values.enabled
end
function MissionScriptElement:_check_instigator(instigator)
	if CoreClass.type_name(instigator) == "Unit" then
		return instigator
	end
	return managers.player:player_unit()
end
function MissionScriptElement:on_executed(instigator)
	if not self._values.enabled then
		return
	end
	instigator = self:_check_instigator(instigator)
	if Network:is_server() then
		if instigator and alive(instigator) and instigator:id() ~= -1 then
			managers.network:session():send_to_peers_synched("run_mission_element", self._id, instigator)
		else
			managers.network:session():send_to_peers_synched("run_mission_element_no_instigator", self._id)
		end
	end
	self:_print_debug_on_executed(instigator)
	self:_reduce_trigger_times()
	if self._values.base_delay > 0 then
		self._mission_script:add(callback(self, self, "execute_on_executed", instigator), self._values.base_delay, 1)
	else
		self:execute_on_executed(instigator)
	end
end
function MissionScriptElement:_print_debug_on_executed(instigator)
	if self:is_debug() then
		self:_print_debug("Element '" .. self._editor_name .. "' executed.", instigator)
		if instigator then
		end
	end
end
function MissionScriptElement:_print_debug(debug, instigator)
	if self:is_debug() then
		self._mission_script:debug_output(debug)
	end
end
function MissionScriptElement:_reduce_trigger_times()
	if self._values.trigger_times > 0 then
		self._values.trigger_times = self._values.trigger_times - 1
		if self._values.trigger_times <= 0 then
			self._values.enabled = false
		end
	end
end
function MissionScriptElement:execute_on_executed(instigator)
	for _, params in ipairs(self._values.on_executed) do
		local element = self:get_mission_element(params.id)
		if element then
			if params.delay > 0 then
				if self:is_debug() or element:is_debug() then
					self._mission_script:debug_output("  Executing element '" .. element:editor_name() .. "' in " .. params.delay .. " seconds ...", Color(1, 0.75, 0.75, 0.75))
				end
				self._mission_script:add(callback(element, element, "on_executed", instigator), params.delay, 1)
			else
				if self:is_debug() or element:is_debug() then
					self._mission_script:debug_output("  Executing element '" .. element:editor_name() .. "' ...", Color(1, 0.75, 0.75, 0.75))
				end
				element:on_executed(instigator)
			end
		end
	end
end
function MissionScriptElement:on_execute_element(element, instigator)
	element:on_executed(instigator)
end
function MissionScriptElement:set_enabled(enabled)
	self._values.enabled = enabled
end
function MissionScriptElement:on_toggle(value)
end
function MissionScriptElement:is_debug()
	return self._values.debug or self._mission_script:is_debug()
end
function MissionScriptElement:stop_simulation(...)
end
function MissionScriptElement:operation_add()
	if Application:editor() then
		managers.editor:output_error("Element " .. self:editor_name() .. " doesn't have an 'add' operator implemented.")
	end
end
function MissionScriptElement:operation_remove()
	if Application:editor() then
		managers.editor:output_error("Element " .. self:editor_name() .. " doesn't have a 'remove' operator implemented.")
	end
end
function MissionScriptElement:pre_destroy()
end
function MissionScriptElement:destroy()
end
