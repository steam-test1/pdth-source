ScriptUnitData = ScriptUnitData or class(CoreScriptUnitData)
function ScriptUnitData:init(unit)
	CoreScriptUnitData.init(self)
	if managers.occlusion and self.skip_occlusion then
		managers.occlusion:remove_occlusion(unit)
	end
end
function ScriptUnitData:destroy(unit)
	if managers.occlusion and self.skip_occlusion then
		managers.occlusion:add_occlusion(unit)
	end
end
