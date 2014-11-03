require("lib/units/enemies/cop/logics/CopLogicBase")
TeamAILogicBase = TeamAILogicBase or class(CopLogicBase)
function TeamAILogicBase.on_long_dis_interacted(data, other_unit)
end
function TeamAILogicBase.on_cop_neutralized(data, cop_key)
end
function TeamAILogicBase.on_recovered(data, reviving_unit)
end
function TeamAILogicBase.clbk_heat(data)
end
function TeamAILogicBase.on_objective_unit_destroyed(data, unit)
	data.objective.destroy_clbk_key = nil
	data.objective.death_clbk_key = nil
	managers.groupai:state():on_criminal_objective_failed(data.unit, data.objective)
end
