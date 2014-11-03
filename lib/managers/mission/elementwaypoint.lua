core:import("CoreMissionScriptElement")
ElementWaypoint = ElementWaypoint or class(CoreMissionScriptElement.MissionScriptElement)
function ElementWaypoint:init(...)
	ElementWaypoint.super.init(self, ...)
	self._network_execute = true
	if self._values.icon == "guis/textures/waypoint2" or self._values.icon == "guis/textures/waypoint" then
		self._values.icon = "wp_standard"
	end
end
function ElementWaypoint:on_script_activated()
	self._mission_script:add_save_state_cb(self._id)
end
function ElementWaypoint:client_on_executed(...)
	self:on_executed(...)
end
function ElementWaypoint:on_executed(instigator)
	if not self._values.enabled then
		return
	end
	local text = managers.localization:text(self._values.text_id)
	managers.hud:add_waypoint(self._id, {
		text = text,
		icon = self._values.icon,
		position = self._values.position,
		distance = true
	})
	ElementWaypoint.super.on_executed(self, instigator)
end
function ElementWaypoint:operation_remove()
	managers.hud:remove_waypoint(self._id)
end
function ElementWaypoint:save(data)
	data.enabled = self._values.enabled
end
function ElementWaypoint:load(data)
	self:set_enabled(data.enabled)
end
