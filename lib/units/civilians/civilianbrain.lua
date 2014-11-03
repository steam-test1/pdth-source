require("lib/units/enemies/cop/logics/CopLogicBase")
require("lib/units/civilians/logics/CivilianLogicIdle")
require("lib/units/civilians/logics/CivilianLogicFlee")
require("lib/units/civilians/logics/CivilianLogicSurrender")
require("lib/units/civilians/logics/CivilianLogicEscort")
require("lib/units/civilians/logics/CivilianLogicTravel")
require("lib/units/civilians/logics/CivilianLogicTrade")
CivilianBrain = CivilianBrain or class(CopBrain)
CivilianBrain._logics = {
	inactive = CopLogicInactive,
	idle = CivilianLogicIdle,
	surrender = CivilianLogicSurrender,
	flee = CivilianLogicFlee,
	escort = CivilianLogicEscort,
	travel = CivilianLogicTravel,
	trade = CivilianLogicTrade
}
function CivilianBrain:init(unit)
	self._unit = unit
	self._timer = TimerManager:game()
	self:set_update_enabled_state(false)
	self._current_logic = nil
	self._current_logic_name = nil
	self._active = true
	self._slotmask_criminals = managers.slot:get_mask("criminals")
	CopBrain._reload_clbks[unit:key()] = callback(self, self, "on_reload")
end
function CivilianBrain:update(unit, t, dt)
	local logic = self._current_logic
	if logic.update then
		local l_data = self._logic_data
		l_data.t = t
		l_data.dt = dt
		logic.update(l_data)
	end
end
function CivilianBrain:is_available_for_assignment(objective)
	return self._current_logic.is_available_for_assignment(self._logic_data, objective)
end
function CivilianBrain:cancel_trade()
	self:set_logic("surrender")
end
function CivilianBrain:set_panic_pos(pos)
	self._panic_center = pos
end
function CivilianBrain:panic_pos()
	return self._panic_center
end
function CivilianBrain:on_rescue_allowed_state(state)
	if self._current_logic.on_rescue_allowed_state then
		self._current_logic.on_rescue_allowed_state(self._logic_data, state)
	end
end
function CivilianBrain:wants_rescue()
	if self._current_logic.wants_rescue then
		return self._current_logic.wants_rescue(self._logic_data)
	end
end
