core:module("CoreEnvironmentShadowSharedInterface")
core:import("CoreClass")
core:import("CoreEnvironmentShadowInterface")
EnvironmentShadowSharedInterface = EnvironmentShadowSharedInterface or CoreClass.class(CoreEnvironmentShadowInterface.EnvironmentShadowInterface)
EnvironmentShadowSharedInterface.DATA_PATH = {
	"post_effect",
	"shadow_processor",
	"shadow_rendering",
	"shadow_modifier"
}
EnvironmentShadowSharedInterface.SHARED = true
