core:import("CoreMissionScriptElement")
ElementAwardAchievment = ElementAwardAchievment or class(CoreMissionScriptElement.MissionScriptElement)
function ElementAwardAchievment:init(...)
	ElementAwardAchievment.super.init(self, ...)
end
function ElementAwardAchievment:client_on_executed(...)
	self:on_executed(...)
end
function ElementAwardAchievment:on_executed(instigator)
	if not self._values.enabled then
		return
	end
	if (not managers.statistics:is_dropin() or self._values.achievment == "quick_hands") and alive(managers.player:player_unit()) and not managers.groupai:state()._failed_point_of_no_return then
		if self._values.achievment == "dozen_angry" then
			if managers.trade:num_in_trade_queue() == 0 then
				managers.challenges:set_flag(self._values.achievment)
			end
		else
			managers.challenges:set_flag(self._values.achievment)
		end
	end
	ElementAwardAchievment.super.on_executed(self, instigator)
end
