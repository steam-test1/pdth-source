EnemyPreferedAddUnitElement = EnemyPreferedAddUnitElement or class(MissionElement)
function EnemyPreferedAddUnitElement:init(unit)
	EnemyPreferedRemoveUnitElement.super.init(self, unit)
	self._hed.elements = {}
	table.insert(self._save_values, "elements")
end
function EnemyPreferedAddUnitElement:draw_links(t, dt, selected_unit, all_units)
	EnemyPreferedRemoveUnitElement.super.draw_links(self, t, dt, selected_unit, all_units)
end
function EnemyPreferedAddUnitElement:update_selected(t, dt, selected_unit, all_units)
	for _, id in ipairs(self._hed.elements) do
		local unit = all_units[id]
		local draw = not selected_unit or unit == selected_unit or self._unit == selected_unit
		if draw then
			self:_draw_link({
				from_unit = self._unit,
				to_unit = unit,
				r = 0,
				g = 0,
				b = 0.75
			})
		end
	end
end
function EnemyPreferedAddUnitElement:update_editing()
end
function EnemyPreferedAddUnitElement:add_element()
	local ray = managers.editor:unit_by_raycast({mask = 10, ray_type = "editor"})
	if ray and ray.unit and string.find(ray.unit:name():s(), "ai_spawn_enemy", 1, true) then
		local id = ray.unit:unit_data().unit_id
		if table.contains(self._hed.elements, id) then
			table.delete(self._hed.elements, id)
		else
			table.insert(self._hed.elements, id)
		end
	end
end
function EnemyPreferedAddUnitElement:remove_links(unit)
	for _, id in ipairs(self._hed.elements) do
		if id == unit:unit_data().unit_id then
			table.delete(self._hed.elements, id)
		end
	end
end
function EnemyPreferedAddUnitElement:add_triggers(vc)
	vc:add_trigger(Idstring("lmb"), callback(self, self, "add_element"))
end
function EnemyPreferedAddUnitElement:_build_panel(panel, panel_sizer)
	self:_create_panel()
	panel = panel or self._panel
	panel_sizer = panel_sizer or self._panel_sizer
end
EnemyPreferedRemoveUnitElement = EnemyPreferedRemoveUnitElement or class(MissionElement)
function EnemyPreferedRemoveUnitElement:init(unit)
	EnemyPreferedRemoveUnitElement.super.init(self, unit)
	self._hed.elements = {}
	table.insert(self._save_values, "elements")
end
function EnemyPreferedRemoveUnitElement:update_editing()
end
function EnemyPreferedRemoveUnitElement:draw_links(t, dt, selected_unit, all_units)
	EnemyPreferedRemoveUnitElement.super.draw_links(self, t, dt, selected_unit)
	for _, id in ipairs(self._hed.elements) do
		local unit = all_units[id]
		local draw = not selected_unit or unit == selected_unit or self._unit == selected_unit
		if draw then
			self:_draw_link({
				from_unit = self._unit,
				to_unit = unit,
				r = 0.75,
				g = 0,
				b = 0
			})
		end
	end
end
function EnemyPreferedRemoveUnitElement:add_element()
	local ray = managers.editor:unit_by_raycast({mask = 10, ray_type = "editor"})
	if ray and ray.unit and string.find(ray.unit:name():s(), "ai_enemy_prefered_add", 1, true) then
		local id = ray.unit:unit_data().unit_id
		if table.contains(self._hed.elements, id) then
			table.delete(self._hed.elements, id)
		else
			table.insert(self._hed.elements, id)
		end
	end
end
function EnemyPreferedRemoveUnitElement:remove_links(unit)
	for _, id in ipairs(self._hed.elements) do
		if id == unit:unit_data().unit_id then
			table.delete(self._hed.elements, id)
		end
	end
end
function EnemyPreferedRemoveUnitElement:add_triggers(vc)
	vc:add_trigger(Idstring("lmb"), callback(self, self, "add_element"))
end
