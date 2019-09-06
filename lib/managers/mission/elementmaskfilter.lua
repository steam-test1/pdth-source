core:import("CoreMissionScriptElement")
ElementMaskFilter = ElementMaskFilter or class(CoreMissionScriptElement.MissionScriptElement)
function ElementMaskFilter:init(...)
	ElementMaskFilter.super.init(self, ...)
end
function ElementMaskFilter:client_on_executed(...)
end
function ElementMaskFilter:on_executed(instigator)
	if not self._values.enabled then
		return
	end
	local session = managers.network:session()
	if not session then
		return
	end
	local wanted_mask = self._values.mask
	print("[ElementMaskFilter:on_executed] wanted_mask", wanted_mask)
	local peers = session:peers()
	for peer_id, peer in pairs(peers) do
		if peer:mask_set() ~= wanted_mask then
			print("wrong mask", peer:mask_set())
			return
		end
	end
	ElementMaskFilter.super.on_executed(self, instigator)
end
