core:module("CoreEnvironmentAreaManager")
core:import("CoreShapeManager")
EnvironmentAreaManager = EnvironmentAreaManager or class()
function EnvironmentAreaManager:init()
	self._areas = {}
	self._current_area = nil
	self._area_iterator = 1
	self._areas_per_frame = 1
	self._blocks = 0
	self.GAME_DEFAULT_ENVIRONMENT = "core/environments/default"
	self._default_environment = self.GAME_DEFAULT_ENVIRONMENT
	self._current_environment = self.GAME_DEFAULT_ENVIRONMENT
	for _, vp in ipairs(managers.viewport:viewports()) do
		self:_set_environment(self.GAME_DEFAULT_ENVIRONMENT, 0, vp)
	end
	self._environment_changed_callback = {}
	self:set_default_transition_time(0.1)
	self.POSITION_OFFSET = 50
end
function EnvironmentAreaManager:set_default_transition_time(time)
	self._default_transition_time = time
end
function EnvironmentAreaManager:default_transition_time()
	return self._default_transition_time
end
function EnvironmentAreaManager:areas()
	return self._areas
end
function EnvironmentAreaManager:game_default_environment()
	return self.GAME_DEFAULT_ENVIRONMENT
end
function EnvironmentAreaManager:default_environment()
	return self._default_environment
end
function EnvironmentAreaManager:set_default_environment(environment, time, vp)
	self._default_environment = environment
	if not self._current_area then
		if not vp then
			for _, viewport in ipairs(managers.viewport:viewports()) do
				self:_set_environment(self._default_environment, time, viewport)
			end
		else
			self:_set_environment(self._default_environment, time, vp)
		end
	end
end
function EnvironmentAreaManager:set_to_current_environment(vp)
	self:_set_environment(self._current_environment, nil, vp)
end
function EnvironmentAreaManager:_set_environment(environment, time, vp)
	self._current_environment = environment
	vp:set_environment(environment, time)
end
function EnvironmentAreaManager:current_environment()
	return self._current_environment
end
function EnvironmentAreaManager:set_to_default()
	local vps = managers.viewport:active_viewports()
	for _, vp in ipairs(vps) do
		self:set_default_environment(self.GAME_DEFAULT_ENVIRONMENT, nil, vp)
	end
end
function EnvironmentAreaManager:add_area(area_params)
	local area = EnvironmentArea:new(area_params)
	table.insert(self._areas, area)
	return area
end
function EnvironmentAreaManager:remove_area(area)
	if area == self._current_area then
		self:_leave_current_area(self._current_area:transition_time())
	end
	table.delete(self._areas, area)
	self._area_iterator = 1
end
local mvec1 = Vector3()
local mvec2 = Vector3()
function EnvironmentAreaManager:update(t, dt)
	local vps = managers.viewport:active_viewports()
	for _, vp in ipairs(vps) do
		local camera = vp:camera()
		if not camera then
			return
		end
		if self._blocks > 0 then
			return
		end
		local check_pos = mvec1
		local c_fwd = mvec2
		camera:m_position(check_pos)
		mrotation.y(camera:rotation(), c_fwd)
		mvector3.multiply(c_fwd, self.POSITION_OFFSET)
		mvector3.add(check_pos, c_fwd)
		local still_inside
		if self._current_area then
			still_inside = self._current_area:still_inside(check_pos)
			if still_inside then
				return
			end
			local transition_time = self._current_area:transition_time()
			self._current_area = nil
			self:_check_inside(check_pos, vp)
			if self._current_area then
				return
			end
			self:_leave_current_area(transition_time, vp)
		end
		self:_check_inside(check_pos, vp)
	end
end
function EnvironmentAreaManager:_check_inside(check_pos, vp)
	if #self._areas > 0 then
		for i = 1, self._areas_per_frame do
			local area = self._areas[self._area_iterator]
			self._area_iterator = math.mod(self._area_iterator, #self._areas) + 1
			if area:is_inside(check_pos) then
				if area:environment() ~= self._current_environment then
					local transition_time = area:transition_time()
					if area:permanent() then
						self:set_default_environment(area:environment(), transition_time, vp)
						return
					else
						self:_set_environment(area:environment(), transition_time, vp)
					end
				end
				self._current_area = area
				break
			end
		end
	end
end
function EnvironmentAreaManager:_leave_current_area(transition_time, vp)
	self._current_area = nil
	if self._default_environment ~= self._current_environment then
		self:_set_environment(self._default_environment, transition_time, vp)
	end
end
function EnvironmentAreaManager:environment_at_position(pos)
	local environment = self._default_environment
	for _, area in ipairs(self._areas) do
		if area:is_inside(pos) then
			environment = area:environment()
		else
		end
	end
	return environment
end
function EnvironmentAreaManager:add_block()
	self._blocks = self._blocks + 1
end
function EnvironmentAreaManager:remove_block()
	self._blocks = self._blocks - 1
end
function EnvironmentAreaManager:add_environment_changed_callback(func)
	table.insert(self._environment_changed_callback, func)
end
function EnvironmentAreaManager:remove_environment_changed_callback(func)
	table.delete(self._environment_changed_callback, func)
end
EnvironmentArea = EnvironmentArea or class(CoreShapeManager.ShapeBox)
function EnvironmentArea:init(params)
	params.type = "box"
	EnvironmentArea.super.init(self, params)
	self._properties.environment = params.environment or managers.environment_area:game_default_environment()
	self._properties.permanent = params.permanent or false
	self._properties.transition_time = params.transition_time or managers.environment_area:default_transition_time()
end
function EnvironmentArea:name()
	return self._unit and self._unit:unit_data().name_id or self._name
end
function EnvironmentArea:environment()
	return self:property("environment")
end
function EnvironmentArea:set_environment(environment)
	self:set_property_string("environment", environment)
end
function EnvironmentArea:permanent()
	return self:property("permanent")
end
function EnvironmentArea:set_permanent(permanent)
	self._properties.permanent = permanent
end
function EnvironmentArea:transition_time()
	return self:property("transition_time")
end
function EnvironmentArea:set_transition_time(time)
	self._properties.transition_time = time
end
