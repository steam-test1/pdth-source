core:import("CoreMissionScriptElement")
ElementAlertTrigger = ElementAlertTrigger or class(CoreMissionScriptElement.MissionScriptElement)
function ElementAlertTrigger:init(...)
	ElementAlertTrigger.super.init(self, ...)
end
function ElementAlertTrigger:client_on_executed(...)
end
function ElementAlertTrigger:on_executed(instigator)
	ElementAlertTrigger.super.on_executed(self, instigator)
end
function ElementAlertTrigger:do_synced_execute(instigator, alert_data)
	if alert_data[1] == "voice" then
		return
	end
	if Network:is_server() then
		self:on_executed(instigator)
	else
		managers.network:session():send_to_host("to_server_mission_element_trigger", self._id, instigator)
	end
end
function ElementAlertTrigger:operation_add()
	managers.groupai:state():add_alert_listener(self._id, self)
end
function ElementAlertTrigger:operation_remove()
	managers.groupai:state():remove_alert_listener(self._id)
end
