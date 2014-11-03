core:import("CoreMissionScriptElement")
ElementFleePoint = ElementFleePoint or class(CoreMissionScriptElement.MissionScriptElement)
function ElementFleePoint:init(...)
	ElementFleePoint.super.init(self, ...)
	self._network_execute = true
end
function ElementFleePoint:on_executed(instigator)
	if not self._values.enabled then
		return
	end
	self:operation_add()
	ElementFleePoint.super.on_executed(self, instigator)
end
function ElementFleePoint:operation_add()
	managers.groupai:state():add_flee_point(self._id, self._values.position)
end
function ElementFleePoint:operation_remove()
	managers.groupai:state():remove_flee_point(self._id)
end
