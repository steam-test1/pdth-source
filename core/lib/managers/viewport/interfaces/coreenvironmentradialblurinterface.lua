core:module("CoreEnvironmentRadialBlurInterface")
core:import("CoreClass")
EnvironmentRadialBlurInterface = EnvironmentRadialBlurInterface or CoreClass.class()
EnvironmentRadialBlurInterface.DATA_PATH = {
	"post_effect",
	"hdr_post_processor",
	"default",
	"radial_blur"
}
EnvironmentRadialBlurInterface.SHARED = false
function EnvironmentRadialBlurInterface:init(handle)
	self._handle = handle
end
function EnvironmentRadialBlurInterface:parameters()
	return table.list_copy(self._handle:parameters())
end
function EnvironmentRadialBlurInterface:_process_return(params)
	assert(table.maxn(params) == 4, "[EnvironmentRadialBlurInterface] You did not return all parameters!")
	return params
end
