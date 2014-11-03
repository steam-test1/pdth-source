core:module("CoreStaticsLayer")
core:import("CoreStaticLayer")
core:import("CoreEditorUtils")
StaticsLayer = StaticsLayer or class(CoreStaticLayer.StaticLayer)
function StaticsLayer:init(owner)
	local types = CoreEditorUtils.layer_type("statics")
	StaticsLayer.super.init(self, owner, "statics", types, "statics_layer")
	self._uses_continents = true
end
function StaticsLayer:build_panel(notebook)
	StaticsLayer.super.build_panel(self, notebook)
	return self._ews_panel, true
end
function StaticsLayer:set_enabled(enabled)
	if not enabled then
		managers.editor:output_warning("Don't want to disable Statics layer since it would cause all dynamics to fall.")
	end
	return false
end
