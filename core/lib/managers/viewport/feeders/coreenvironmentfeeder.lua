core:module("CoreEnvironmentFeeder")
core:import("CoreClass")
core:import("CoreEnvironmentNetworkFeeder")
core:import("CoreEnvironmentPostProcessorFeeder")
core:import("CoreEnvironmentUnderlayFeeder")
core:import("CoreEnvironmentOthersFeeder")
EnvironmentFeeder = EnvironmentFeeder or CoreClass.class()
function EnvironmentFeeder:init()
	self._production_feeders = {
		CoreEnvironmentNetworkFeeder.EnvironmentNetworkFeeder:new(),
		CoreEnvironmentPostProcessorFeeder.EnvironmentPostProcessorFeeder:new(),
		CoreEnvironmentUnderlayFeeder.EnvironmentUnderlayFeeder:new(),
		CoreEnvironmentOthersFeeder.EnvironmentOthersFeeder:new()
	}
	self._feeders = {
		CoreEnvironmentPostProcessorFeeder.EnvironmentPostProcessorFeeder:new(),
		CoreEnvironmentUnderlayFeeder.EnvironmentUnderlayFeeder:new(),
		CoreEnvironmentOthersFeeder.EnvironmentOthersFeeder:new()
	}
end
function EnvironmentFeeder:feed(data, nr, scene, vp)
	data:for_each(function(block, ...)
		for _, feeder in ipairs(self:feeders()) do
			if feeder:feed(nr, scene, vp, data, block, ...) then
				return
			end
		end
		error("[EnvironmentFeeder] No suitable feeder found! Data: ", ...)
	end)
	for _, feeder in ipairs(self:feeders()) do
		feeder:end_feed(nr)
	end
end
function EnvironmentFeeder:feeders()
	return managers.slave:connected() and self._enable_slaving and self._production_feeders or self._feeders
end
function EnvironmentFeeder:slaving()
	return self._enable_slaving and true
end
function EnvironmentFeeder:set_slaving(slaving)
	self._enable_slaving = slaving
end
