DisableShoutElement = DisableShoutElement or class(MissionElement)
function DisableShoutElement:init(unit)
	DisableShoutElement.super.init(self, unit)
	self._hed.elements = {}
	self._hed.disable_shout = true
	table.insert(self._save_values, "elements")
	table.insert(self._save_values, "disable_shout")
end
function DisableShoutElement:_build_panel(panel, panel_sizer)
	self:_create_panel()
	panel = panel or self._panel
	panel_sizer = panel_sizer or self._panel_sizer
	local dis_shout = EWS:CheckBox(panel, "Disable shout", "")
	dis_shout:set_value(self._hed.disable_shout)
	dis_shout:connect("EVT_COMMAND_CHECKBOX_CLICKED", callback(self, self, "set_element_data"), {
		ctrlr = dis_shout,
		value = "disable_shout"
	})
	panel_sizer:add(dis_shout, 0, 0, "EXPAND")
end
function DisableShoutElement:update_editing()
end
function DisableShoutElement:update_selected(t, dt, selected_unit, all_units)
	for _, id in ipairs(self._hed.elements) do
		local unit = all_units[id]
		local draw = not selected_unit or unit == selected_unit or self._unit == selected_unit
		if draw then
			self:_draw_link({
				from_unit = self._unit,
				to_unit = unit,
				r = 0.9,
				g = 0.5,
				b = 1
			})
		end
	end
end
function DisableShoutElement:add_element()
	local ray = managers.editor:unit_by_raycast({mask = 10, ray_type = "editor"})
	if ray and ray.unit and (string.find(ray.unit:name():s(), "ai_spawn_enemy", 1, true) or string.find(ray.unit:name():s(), "ai_spawn_civilian", 1, true)) then
		local id = ray.unit:unit_data().unit_id
		if table.contains(self._hed.elements, id) then
			table.delete(self._hed.elements, id)
		else
			table.insert(self._hed.elements, id)
		end
	end
end
function DisableShoutElement:remove_links(unit)
	for _, id in ipairs(self._hed.elements) do
		if id == unit:unit_data().unit_id then
			table.delete(self._hed.elements, id)
		end
	end
end
function DisableShoutElement:add_triggers(vc)
	vc:add_trigger(Idstring("lmb"), callback(self, self, "add_element"))
end
