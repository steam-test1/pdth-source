core:import("CoreWorldDefinition")
WorldDefinition = WorldDefinition or class(CoreWorldDefinition.WorldDefinition)
function WorldDefinition:init(...)
	WorldDefinition.super.init(self, ...)
end
function WorldDefinition:_project_assign_unit_data(unit, data)
	if not Application:editor() and unit:unit_data().secret_assignment_id then
		managers.secret_assignment:register_unit(unit)
	end
end
function WorldDefinition:get_cover_data()
	local path = self:world_dir() .. "cover_data"
	if not DB:has("cover_data", path) then
		return false
	end
	return self:_serialize_to_script("cover_data", path)
end
CoreClass.override_class(CoreWorldDefinition.WorldDefinition, WorldDefinition)
