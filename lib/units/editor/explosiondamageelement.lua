ExplosionDamageUnitElement = ExplosionDamageUnitElement or class(MissionElement)
function ExplosionDamageUnitElement:init(unit)
	ExplosionDamageUnitElement.super.init(self, unit)
	self._hed.range = 100
	self._hed.damage = 40
	table.insert(self._save_values, "range")
	table.insert(self._save_values, "damage")
end
function ExplosionDamageUnitElement:update_selected()
	local brush = Draw:brush()
	brush:set_color(Color(0.15, 1, 1, 1))
	local pen = Draw:pen(Color(0.15, 0.5, 0.5, 0.5))
	brush:sphere(self._unit:position(), self._hed.range, 4)
	pen:sphere(self._unit:position(), self._hed.range)
end
function ExplosionDamageUnitElement:_build_panel(panel, panel_sizer)
	self:_create_panel()
	panel = panel or self._panel
	panel_sizer = panel_sizer or self._panel_sizer
	local range_params = {
		name = "Range:",
		panel = panel,
		sizer = panel_sizer,
		value = self._hed.range,
		floats = 0,
		tooltip = "The range the explosion should reach",
		min = 0,
		name_proportions = 1,
		ctrlr_proportions = 2
	}
	local range = CoreEws.number_controller(range_params)
	range:connect("EVT_COMMAND_TEXT_ENTER", callback(self, self, "set_element_data"), {ctrlr = range, value = "range"})
	range:connect("EVT_KILL_FOCUS", callback(self, self, "set_element_data"), {ctrlr = range, value = "range"})
	local damage_params = {
		name = "Damage:",
		panel = panel,
		sizer = panel_sizer,
		value = self._hed.damage,
		floats = 0,
		tooltip = "The damage from the explosion",
		min = 0,
		name_proportions = 1,
		ctrlr_proportions = 2
	}
	local damage = CoreEws.number_controller(damage_params)
	damage:connect("EVT_COMMAND_TEXT_ENTER", callback(self, self, "set_element_data"), {ctrlr = damage, value = "damage"})
	damage:connect("EVT_KILL_FOCUS", callback(self, self, "set_element_data"), {ctrlr = damage, value = "damage"})
end
