CoreUnitSequenceUnitElement = CoreUnitSequenceUnitElement or class(MissionElement)
UnitSequenceUnitElement = UnitSequenceUnitElement or class(CoreUnitSequenceUnitElement)
function UnitSequenceUnitElement:init(...)
	CoreUnitSequenceUnitElement.init(self, ...)
end
function CoreUnitSequenceUnitElement:init(unit)
	MissionElement.init(self, unit)
	self._hed.trigger_list = {}
	table.insert(self._save_values, "trigger_list")
end
function CoreUnitSequenceUnitElement:update_unselected(...)
	MissionElement.update_unselected(self, ...)
end
function CoreUnitSequenceUnitElement:update_selected(...)
	MissionElement.update_selected(self, ...)
	self:_draw_trigger_units(0, 1, 1)
end
function CoreUnitSequenceUnitElement:draw_links_unselected(...)
	CoreUnitSequenceUnitElement.super.draw_links_unselected(self, ...)
	self:_draw_trigger_units(0, 0.75, 0.75)
end
function CoreUnitSequenceUnitElement:_draw_trigger_units(r, g, b)
	local trigger_data = self._unit:damage():get_editor_trigger_data()
	if trigger_data and #trigger_data > 0 then
		for _, data in ipairs(trigger_data) do
			if alive(data.notify_unit) then
				local params = {
					from_unit = self._unit,
					to_unit = data.notify_unit,
					r = r,
					g = g,
					b = b
				}
				self:_draw_link(params)
				Application:draw(data.notify_unit, r, g, b)
			end
		end
	end
end
function CoreUnitSequenceUnitElement:new_save_values(...)
	self:_set_trigger_list()
	return MissionElement.new_save_values(self, ...)
end
function CoreUnitSequenceUnitElement:save_values(...)
	self:_set_trigger_list()
	MissionElement.save_values(self, ...)
end
function CoreUnitSequenceUnitElement:_set_trigger_list()
	self._hed.trigger_list = {}
	local triggers = managers.sequence:get_trigger_list(self._unit:name())
	if #triggers > 0 then
		local trigger_data = self._unit:damage():get_editor_trigger_data()
		if trigger_data and #trigger_data > 0 then
			for _, data in ipairs(trigger_data) do
				table.insert(self._hed.trigger_list, {
					name = data.trigger_name,
					id = data.id,
					notify_unit_id = data.notify_unit:unit_data().unit_id,
					time = data.time,
					notify_unit_sequence = data.notify_unit_sequence
				})
			end
		end
	end
end
function CoreUnitSequenceUnitElement:_build_panel(panel, panel_sizer)
	self:_create_panel()
	panel = panel or self._panel
	panel_sizer = panel_sizer or self._panel_sizer
	local help = {}
	help.text = "Use the \"Edit Triggable\" interface, which you enable in the down left toolbar, to select and edit which units and sequences you want to run."
	help.panel = panel
	help.sizer = panel_sizer
	self:add_help_text(help)
end
function CoreUnitSequenceUnitElement:add_to_mission_package()
	managers.editor:add_to_world_package({
		category = "units",
		name = "core/units/run_sequence_dummy/run_sequence_dummy",
		continent = self._unit:unit_data().continent
	})
	managers.editor:add_to_world_package({
		category = "script_data",
		name = "core/units/run_sequence_dummy/run_sequence_dummy.sequence_manager",
		continent = self._unit:unit_data().continent
	})
end
