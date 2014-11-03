core:import("CoreMissionScriptElement")
ElementSetOutline = ElementSetOutline or class(CoreMissionScriptElement.MissionScriptElement)
function ElementSetOutline:init(...)
	ElementSetOutline.super.init(self, ...)
end
function ElementSetOutline:client_on_executed(...)
end
function ElementSetOutline.sync_function(unit, state)
	unit:base():set_contour(state)
end
function ElementSetOutline:on_executed(instigator)
	if not self._values.enabled then
		return
	end
	local function f(unit)
		ElementSetOutline.sync_function(unit, self._values.set_outline)
		managers.network:session():send_to_peers_synched("sync_set_outline", unit, self._values.set_outline)
	end
	for _, id in ipairs(self._values.elements) do
		local element = self:get_mission_element(id)
		element:execute_on_all_units(f)
	end
	ElementSetOutline.super.on_executed(self, instigator)
end
