HuskCopBrain = HuskCopBrain or class()
function HuskCopBrain:init(unit)
	self._unit = unit
end
function HuskCopBrain:interaction_voice()
	return self._interaction_voice
end
function HuskCopBrain:on_intimidated(amount, aggressor_unit)
	local amount = math.clamp(math.floor(amount * 10), 1, 10)
	self._unit:network():send_to_host("cop_on_intimidated", amount, aggressor_unit)
	return self._interaction_voice
end
function HuskCopBrain:set_interaction_voice(voice)
	self._interaction_voice = voice
end
function HuskCopBrain:load(load_data)
	local my_load_data = load_data.brain
	self:set_interaction_voice(my_load_data.interaction_voice)
end
function HuskCopBrain:on_tied(aggressor_unit)
	self._unit:network():send_to_host("unit_tied", aggressor_unit)
end
function HuskCopBrain:on_trade(trading_unit)
	self._unit:network():send_to_host("unit_traded", trading_unit)
end
function HuskCopBrain:action_complete_clbk(action)
end
function HuskCopBrain:on_alert(alert_data)
	if self._unit:id() == -1 then
		return
	end
	self._unit:network():send_to_host("alert", alert_data[5] or alert_data[4])
end
function HuskCopBrain:on_long_dis_interacted(aggressor_unit)
	self._unit:network():send_to_host("cop_on_intimidated", 1, aggressor_unit)
end
