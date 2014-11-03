CoreLogicChanceUnitElement = CoreLogicChanceUnitElement or class(MissionElement)
LogicChanceUnitElement = LogicChanceUnitElement or class(CoreLogicChanceUnitElement)
function LogicChanceUnitElement:init(...)
	CoreLogicChanceUnitElement.init(self, ...)
end
function CoreLogicChanceUnitElement:init(unit)
	MissionElement.init(self, unit)
	self._hed.chance = 100
	table.insert(self._save_values, "chance")
end
function CoreLogicChanceUnitElement:_build_panel(panel, panel_sizer)
	self:_create_panel()
	panel = panel or self._panel
	panel_sizer = panel_sizer or self._panel_sizer
	local chance_params = {
		name = "Chance:",
		panel = panel,
		sizer = panel_sizer,
		value = self._hed.chance,
		floats = 0,
		tooltip = "Specifies chance that this element will call its on executed elements (in percent)",
		min = 0,
		max = 100,
		name_proportions = 1,
		ctrlr_proportions = 2
	}
	local chance = CoreEWS.number_controller(chance_params)
	chance:connect("EVT_COMMAND_TEXT_ENTER", callback(self, self, "set_element_data"), {ctrlr = chance, value = "chance"})
	chance:connect("EVT_KILL_FOCUS", callback(self, self, "set_element_data"), {ctrlr = chance, value = "chance"})
end
CoreLogicChanceOperatorUnitElement = CoreLogicChanceOperatorUnitElement or class(MissionElement)
LogicChanceOperatorUnitElement = LogicChanceOperatorUnitElement or class(CoreLogicChanceOperatorUnitElement)
function LogicChanceOperatorUnitElement:init(...)
	LogicChanceOperatorUnitElement.super.init(self, ...)
end
function CoreLogicChanceOperatorUnitElement:init(unit)
	CoreLogicChanceOperatorUnitElement.super.init(self, unit)
	self._hed.operation = "none"
	self._hed.chance = 0
	self._hed.elements = {}
	table.insert(self._save_values, "operation")
	table.insert(self._save_values, "chance")
	table.insert(self._save_values, "elements")
end
function CoreLogicChanceOperatorUnitElement:draw_links(t, dt, selected_unit, all_units)
	CoreLogicChanceOperatorUnitElement.super.draw_links(self, t, dt, selected_unit)
	for _, id in ipairs(self._hed.elements) do
		local unit = all_units[id]
		local draw = not selected_unit or unit == selected_unit or self._unit == selected_unit
		if draw then
			self:_draw_link({
				from_unit = self._unit,
				to_unit = unit,
				r = 0.75,
				g = 0.75,
				b = 0.25
			})
		end
	end
end
function CoreLogicChanceOperatorUnitElement:update_editing()
end
function CoreLogicChanceOperatorUnitElement:add_element()
	local ray = managers.editor:unit_by_raycast({mask = 10, ray_type = "editor"})
	if ray and ray.unit and ray.unit:name() == Idstring("core/units/mission_elements/logic_chance/logic_chance") then
		local id = ray.unit:unit_data().unit_id
		if table.contains(self._hed.elements, id) then
			table.delete(self._hed.elements, id)
		else
			table.insert(self._hed.elements, id)
		end
	end
end
function CoreLogicChanceOperatorUnitElement:remove_links(unit)
	for _, id in ipairs(self._hed.elements) do
		if id == unit:unit_data().unit_id then
			table.delete(self._hed.elements, id)
		end
	end
end
function CoreLogicChanceOperatorUnitElement:add_triggers(vc)
	vc:add_trigger(Idstring("lmb"), callback(self, self, "add_element"))
end
function CoreLogicChanceOperatorUnitElement:_build_panel(panel, panel_sizer)
	self:_create_panel()
	panel = panel or self._panel
	panel_sizer = panel_sizer or self._panel_sizer
	local operation_params = {
		name = "Operation:",
		panel = panel,
		sizer = panel_sizer,
		default = "none",
		options = {
			"add_chance",
			"subtract_chance",
			"reset",
			"set_chance"
		},
		value = self._hed.operation,
		tooltip = "Select an operation for the selected elements",
		name_proportions = 1,
		ctrlr_proportions = 2,
		sorted = true
	}
	local operation = CoreEWS.combobox(operation_params)
	operation:connect("EVT_COMMAND_COMBOBOX_SELECTED", callback(self, self, "set_element_data"), {ctrlr = operation, value = "operation"})
	local chance_params = {
		name = "Chance:",
		panel = panel,
		sizer = panel_sizer,
		value = self._hed.chance,
		floats = 0,
		tooltip = "Amount of chance to add, subtract or set to the logic chance elements.",
		min = 0,
		max = 100,
		name_proportions = 1,
		ctrlr_proportions = 2,
		sorted = false
	}
	local chance = CoreEWS.number_controller(chance_params)
	chance:connect("EVT_COMMAND_TEXT_ENTER", callback(self, self, "set_element_data"), {ctrlr = chance, value = "chance"})
	chance:connect("EVT_KILL_FOCUS", callback(self, self, "set_element_data"), {ctrlr = chance, value = "chance"})
	local help = {}
	help.text = "This element can modify logic_chance element. Select logic chance elements to modify using insert and clicking on the elements."
	help.panel = panel
	help.sizer = panel_sizer
	self:add_help_text(help)
end
CoreLogicChanceTriggerUnitElement = CoreLogicChanceTriggerUnitElement or class(MissionElement)
LogicChanceTriggerUnitElement = LogicChanceTriggerUnitElement or class(CoreLogicChanceTriggerUnitElement)
function LogicChanceTriggerUnitElement:init(...)
	LogicChanceTriggerUnitElement.super.init(self, ...)
end
function CoreLogicChanceTriggerUnitElement:init(unit)
	CoreLogicChanceTriggerUnitElement.super.init(self, unit)
	self._hed.outcome = "fail"
	self._hed.elements = {}
	table.insert(self._save_values, "outcome")
	table.insert(self._save_values, "elements")
end
function CoreLogicChanceTriggerUnitElement:draw_links(t, dt, selected_unit, all_units)
	CoreLogicChanceTriggerUnitElement.super.draw_links(self, t, dt, selected_unit)
	for _, id in ipairs(self._hed.elements) do
		local unit = all_units[id]
		local draw = not selected_unit or unit == selected_unit or self._unit == selected_unit
		if draw then
			self:_draw_link({
				from_unit = unit,
				to_unit = self._unit,
				r = 0.85,
				g = 0.85,
				b = 0.25
			})
		end
	end
end
function CoreLogicChanceTriggerUnitElement:update_editing()
end
function CoreLogicChanceTriggerUnitElement:add_element()
	local ray = managers.editor:unit_by_raycast({mask = 10, ray_type = "editor"})
	if ray and ray.unit and ray.unit:name() == Idstring("core/units/mission_elements/logic_chance/logic_chance") then
		local id = ray.unit:unit_data().unit_id
		if table.contains(self._hed.elements, id) then
			table.delete(self._hed.elements, id)
		else
			table.insert(self._hed.elements, id)
		end
	end
end
function CoreLogicChanceTriggerUnitElement:remove_links(unit)
	for _, id in ipairs(self._hed.elements) do
		if id == unit:unit_data().unit_id then
			table.delete(self._hed.elements, id)
		end
	end
end
function CoreLogicChanceTriggerUnitElement:add_triggers(vc)
	vc:add_trigger(Idstring("lmb"), callback(self, self, "add_element"))
end
function CoreLogicChanceTriggerUnitElement:_build_panel(panel, panel_sizer)
	self:_create_panel()
	panel = panel or self._panel
	panel_sizer = panel_sizer or self._panel_sizer
	local outcome_params = {
		name = "Outcome:",
		panel = panel,
		sizer = panel_sizer,
		options = {"fail", "success"},
		value = self._hed.outcome,
		tooltip = "Select an outcome to trigger on",
		name_proportions = 1,
		ctrlr_proportions = 2,
		sorted = true
	}
	local outcome = CoreEWS.combobox(outcome_params)
	outcome:connect("EVT_COMMAND_COMBOBOX_SELECTED", callback(self, self, "set_element_data"), {ctrlr = outcome, value = "outcome"})
	local help = {}
	help.text = "This element is a trigger to logic_chance element."
	help.panel = panel
	help.sizer = panel_sizer
	self:add_help_text(help)
end
