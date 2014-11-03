require("lib/units/player_team/logics/TeamAILogicBase")
require("lib/units/player_team/logics/TeamAILogicInactive")
require("lib/units/player_team/logics/TeamAILogicIdle")
require("lib/units/player_team/logics/TeamAILogicSurrender")
require("lib/units/player_team/logics/TeamAILogicTravel")
require("lib/units/player_team/logics/TeamAILogicAssault")
require("lib/units/player_team/logics/TeamAILogicDisabled")
TeamAIBrain = TeamAIBrain or class(CopBrain)
TeamAIBrain._logics = {
	inactive = TeamAILogicInactive,
	idle = TeamAILogicIdle,
	surrender = TeamAILogicSurrender,
	travel = TeamAILogicTravel,
	assault = TeamAILogicAssault,
	disabled = TeamAILogicDisabled
}
local reload
if TeamAIBrain._reload_clbks then
	reload = true
else
	TeamAIBrain._reload_clbks = {}
end
function TeamAIBrain:init(unit)
	self._unit = unit
	self._timer = TimerManager:game()
	self:set_update_enabled_state(false)
	self._current_logic = nil
	self._current_logic_name = nil
	self._active = true
	self._reload_clbks[unit:key()] = callback(self, self, "on_reload")
end
function TeamAIBrain:post_init()
	self:_reset_logic_data()
	local my_key = tostring(self._unit:key())
	self._unit:character_damage():add_listener("TeamAIBrain_hurt" .. my_key, {
		"bleedout",
		"hurt",
		"light_hurt",
		"heavy_hurt",
		"fatal",
		"none"
	}, callback(self, self, "clbk_damage"))
	self._unit:character_damage():add_listener("TeamAIBrain_death" .. my_key, {"death"}, callback(self, self, "clbk_death"))
	managers.groupai:state():add_listener("TeamAIBrain" .. my_key, {
		"enemy_weapons_hot"
	}, callback(self, self, "clbk_heat"))
	if not self._current_logic then
		self:set_init_logic("idle")
	end
end
function TeamAIBrain:set_spawn_ai(spawn_ai)
	TeamAIBrain.super.set_spawn_ai(self, spawn_ai)
	self:clbk_heat()
	TeamAILogicAssault._chk_change_weapon(self._logic_data, self._logic_data.internal_data)
end
function TeamAIBrain:clbk_damage(my_unit, damage_info)
	self._current_logic.damage_clbk(self._logic_data, damage_info)
end
function TeamAIBrain:clbk_death(my_unit, damage_info)
	TeamAIBrain.super.clbk_death(self, my_unit, damage_info)
	self:set_objective()
end
function TeamAIBrain:on_cop_neutralized(cop_key)
	return self._current_logic.on_cop_neutralized(self._logic_data, cop_key)
end
function TeamAIBrain:on_long_dis_interacted(other_unit)
	return self._current_logic.on_long_dis_interacted(self._logic_data, other_unit)
end
function TeamAIBrain:on_recovered(reviving_unit)
	self._current_logic.on_recovered(self._logic_data, reviving_unit)
end
function TeamAIBrain:clbk_heat()
	self._current_logic.clbk_heat(self._logic_data)
end
function TeamAIBrain:pre_destroy(unit)
	TeamAIBrain.super.pre_destroy(self, unit)
	managers.groupai:state():remove_listener("TeamAIBrain" .. tostring(self._unit:key()))
end
function TeamAIBrain:set_active(state)
	TeamAIBrain.super.set_active(self, state)
	if not state then
		self:set_objective()
	end
	self._unit:character_damage():disable()
end
