require("core/lib/setups/CoreLoadingSetup")
require("lib/utils/LevelLoadingScreenGuiScript")
LevelLoadingSetup = LevelLoadingSetup or class(CoreLoadingSetup)
function LevelLoadingSetup:init()
	self._camera = Scene:create_camera()
	LoadingViewport:set_camera(self._camera)
	self._gui_wrapper = LevelLoadingScreenGuiScript:new(Scene:gui(), arg.res, -1, arg.layer)
end
function LevelLoadingSetup:update(t, dt)
	self._gui_wrapper:update(-1, t, dt)
end
function LevelLoadingSetup:destroy()
	LevelLoadingSetup.super.destroy(self)
	Scene:delete_camera(self._camera)
end
setup = setup or LevelLoadingSetup:new()
setup:make_entrypoint()
