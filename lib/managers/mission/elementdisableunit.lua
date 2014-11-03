core:import("CoreMissionScriptElement")
ElementDisableUnit = ElementDisableUnit or class(CoreMissionScriptElement.MissionScriptElement)
function ElementDisableUnit:init(...)
	ElementDisableUnit.super.init(self, ...)
	self._units = {}
end
function ElementDisableUnit:on_script_activated()
	print(inspect(self._values.unit_ids))
	for _, id in ipairs(self._values.unit_ids) do
		if Global.running_simulation then
			table.insert(self._units, managers.editor:unit_with_id(id))
		else
			local unit = managers.worlddefinition:get_unit_on_load(id, callback(self, self, "_load_unit"))
			if unit then
				print("ElementDisableUnit FOUND DIRECTLY", unit)
				table.insert(self._units, unit)
			end
		end
	end
end
function ElementDisableUnit:_load_unit(unit)
	print("ElementDisableUnit FOUND LATER", unit)
	Application:stack_dump()
	table.insert(self._units, unit)
end
function ElementDisableUnit:client_on_executed(...)
	self:on_executed(...)
end
function ElementDisableUnit:on_executed(instigator)
	if not self._values.enabled then
		return
	end
	print("ElementDisableUnit:on_executed")
	for _, unit in ipairs(self._units) do
		print("unit", unit)
		managers.game_play_central:mission_disable_unit(unit)
	end
	ElementDisableUnit.super.on_executed(self, instigator)
end
