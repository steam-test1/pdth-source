SpawnCivilianGroupUnitElement = SpawnCivilianGroupUnitElement or class(MissionElement)
function SpawnCivilianGroupUnitElement:init(unit)
	SpawnCivilianGroupUnitElement.super.init(self, unit)
	self._hed.random = false
	self._hed.ignore_disabled = false
	self._hed.amount = 1
	self._hed.elements = {}
	table.insert(self._save_values, "elements")
	table.insert(self._save_values, "random")
	table.insert(self._save_values, "ignore_disabled")
	table.insert(self._save_values, "amount")
end
function SpawnCivilianGroupUnitElement:draw_links(t, dt, selected_unit, all_units)
	SpawnCivilianGroupUnitElement.super.draw_links(self, t, dt, selected_unit, all_units)
end
function SpawnCivilianGroupUnitElement:update_editing()
end
function SpawnCivilianGroupUnitElement:update_selected(t, dt, selected_unit, all_units)
	for _, id in ipairs(self._hed.elements) do
		local unit = all_units[id]
		local draw = not selected_unit or unit == selected_unit or self._unit == selected_unit
		if draw then
			self:_draw_link({
				from_unit = self._unit,
				to_unit = unit,
				r = 0,
				g = 0.75,
				b = 0
			})
		end
	end
end
function SpawnCivilianGroupUnitElement:add_element()
	local ray = managers.editor:unit_by_raycast({mask = 10, ray_type = "editor"})
	if ray and ray.unit and string.find(ray.unit:name():s(), "ai_spawn_civilian", 1, true) then
		local id = ray.unit:unit_data().unit_id
		if table.contains(self._hed.elements, id) then
			table.delete(self._hed.elements, id)
		else
			table.insert(self._hed.elements, id)
		end
	end
end
function SpawnCivilianGroupUnitElement:remove_links(unit)
	for _, id in ipairs(self._hed.elements) do
		if id == unit:unit_data().unit_id then
			table.delete(self._hed.elements, id)
		end
	end
end
function SpawnCivilianGroupUnitElement:add_triggers(vc)
	vc:add_trigger(Idstring("lmb"), callback(self, self, "add_element"))
end
function SpawnCivilianGroupUnitElement:_build_panel(panel, panel_sizer)
	self:_create_panel()
	panel = panel or self._panel
	panel_sizer = panel_sizer or self._panel_sizer
	local random = EWS:CheckBox(panel, "Random", "")
	random:set_tool_tip("Select spawn points randomly")
	random:set_value(self._hed.random)
	random:connect("EVT_COMMAND_CHECKBOX_CLICKED", callback(self, self, "set_element_data"), {ctrlr = random, value = "random"})
	panel_sizer:add(random, 0, 0, "EXPAND")
	local ignore_disabled = EWS:CheckBox(panel, "Ignore disabled", "")
	ignore_disabled:set_tool_tip("Select if disabled spawn points should be ignored or not")
	ignore_disabled:set_value(self._hed.ignore_disabled)
	ignore_disabled:connect("EVT_COMMAND_CHECKBOX_CLICKED", callback(self, self, "set_element_data"), {
		ctrlr = ignore_disabled,
		value = "ignore_disabled"
	})
	panel_sizer:add(ignore_disabled, 0, 0, "EXPAND")
	local amount_params = {
		name = "Amount :",
		panel = panel,
		sizer = panel_sizer,
		value = self._hed.amount,
		floats = 0,
		tooltip = "Specify amount of enemies to spawn from group",
		min = 0,
		name_proportions = 1,
		ctrlr_proportions = 2
	}
	local amount = CoreEWS.number_controller(amount_params)
	amount:connect("EVT_COMMAND_TEXT_ENTER", callback(self, self, "set_element_data"), {ctrlr = amount, value = "amount"})
	amount:connect("EVT_KILL_FOCUS", callback(self, self, "set_element_data"), {ctrlr = amount, value = "amount"})
end
