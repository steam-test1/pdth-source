core:import("CoreMissionScriptElement")
ElementKillZone = ElementKillZone or class(CoreMissionScriptElement.MissionScriptElement)
function ElementKillZone:init(...)
	ElementKillZone.super.init(self, ...)
end
function ElementKillZone:on_executed(instigator)
	if not self._values.enabled then
		return
	end
	if alive(instigator) then
		self._values.type = self._values.type or "sniper"
		if instigator == managers.player:player_unit() then
			managers.killzone:set_unit(instigator, self._values.type)
		else
			local rpc_params = {
				"killzone_set_unit",
				self._values.type
			}
			instigator:network():send_to_unit(rpc_params)
		end
	end
	ElementKillZone.super.on_executed(self, self._unit or instigator)
end
