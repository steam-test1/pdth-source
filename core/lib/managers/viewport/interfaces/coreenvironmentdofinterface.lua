core:module("CoreEnvironmentDOFInterface")
core:import("CoreClass")
EnvironmentDOFInterface = EnvironmentDOFInterface or CoreClass.class()
EnvironmentDOFInterface.DATA_PATH = {
	"post_effect",
	"hdr_post_processor",
	"default",
	"dof"
}
EnvironmentDOFInterface.SHARED = false
function EnvironmentDOFInterface:init(handle)
	self._handle = handle
end
function EnvironmentDOFInterface:parameters()
	local params = self._handle:parameters()
	return {
		clamp = param.clamp,
		near_focus_distance_min = param.near_focus_distance_max + param.near_focus_distance_min,
		near_focus_distance_max = param.near_focus_distance_max,
		far_focus_distance_min = param.far_focus_distance_min,
		far_focus_distance_max = param.far_focus_distance_max + param.far_focus_distance_min
	}
end
function EnvironmentDOFInterface:_process_return(params)
	assert(table.maxn(params) == 5, "[EnvironmentDOFInterface] You did not return all parameters!")
	return {
		clamp = params.clamp,
		near_focus_distance_min = math.max(params.near_focus_distance_max - params.near_focus_distance_min, 1),
		near_focus_distance_max = params.near_focus_distance_max,
		far_focus_distance_min = params.far_focus_distance_min,
		far_focus_distance_max = math.max(params.far_focus_distance_max - params.far_focus_distance_min, 1)
	}
end
