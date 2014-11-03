core:import("CoreMissionScriptElement")
ElementSmokeGrenade = ElementSmokeGrenade or class(CoreMissionScriptElement.MissionScriptElement)
function ElementSmokeGrenade:init(...)
	ElementSmokeGrenade.super.init(self, ...)
end
function ElementSmokeGrenade:client_on_executed(...)
end
function ElementSmokeGrenade:on_executed(instigator)
	if not self._values.enabled then
		return
	end
	if self._values.immediate then
		if managers.groupai:state():get_assault_mode() or self._values.ignore_control then
			managers.network:session():send_to_peers("sync_smoke_grenade_kill")
			managers.groupai:state():sync_smoke_grenade_kill()
			local pos = self._values.position
			managers.network:session():send_to_peers("sync_smoke_grenade", pos, pos, self._values.duration)
			managers.groupai:state():sync_smoke_grenade(pos, pos, self._values.duration)
			managers.groupai:state()._smoke_grenade_ignore_control = self._values.ignore_control
		end
	else
		managers.groupai:state()._smoke_grenade_queued = {
			self._values.position,
			self._values.duration,
			self._values.ignore_control
		}
	end
	print("SMOOOOOOOKEEEEEEEE")
	ElementSmokeGrenade.super.on_executed(self, instigator)
end
