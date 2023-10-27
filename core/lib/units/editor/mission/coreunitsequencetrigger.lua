CoreUnitSequenceTriggerUnitElement = CoreUnitSequenceTriggerUnitElement or class(MissionElement)
UnitSequenceTriggerUnitElement = UnitSequenceTriggerUnitElement or class(CoreUnitSequenceTriggerUnitElement)
function UnitSequenceTriggerUnitElement:init(...)
	CoreUnitSequenceTriggerUnitElement.init(self, ...)
end
function CoreUnitSequenceTriggerUnitElement:init(unit)
	MissionElement.init(self, unit)
	self._hed.trigger_times = 1
	self._hed.sequence_list = {}
	table.insert(self._save_values, "sequence_list")
	self._guis = {}
	self._sequences = {}
	self._sequence_units = {}
end
function CoreUnitSequenceTriggerUnitElement:layer_finished()
	MissionElement.layer_finished(self)
	if self._hed.unit_id then
		table.insert(self._hed.sequence_list, {
			unit_id = self._hed.unit_id,
			sequence = self._hed.sequence
		})
	end
	for _, data in pairs(self._hed.sequence_list) do
		local unit = managers.worlddefinition:get_unit_on_load(data.unit_id, callback(self, self, "load_unit"))
		if unit then
			self._sequence_units[unit:unit_data().unit_id] = unit
		end
	end
end
function CoreUnitSequenceTriggerUnitElement:load_unit(unit)
	if unit then
		self._sequence_units[unit:unit_data().unit_id] = unit
	end
end
function CoreUnitSequenceTriggerUnitElement:update_selected()
	for id, unit in pairs(self._sequence_units) do
		if not alive(unit) then
			self:_remove_by_unit_id(id)
			self._sequence_units[id] = nil
		else
			local params = {
				from_unit = unit,
				to_unit = self._unit,
				r = 0,
				g = 0,
				b = 1
			}
			self:_draw_link(params)
			Application:draw(unit, 0, 0, 1)
		end
	end
end
function CoreUnitSequenceTriggerUnitElement:update_unselected(t, dt, selected_unit, all_units)
	self:_check_alive_units()
end
function CoreUnitSequenceTriggerUnitElement:_check_alive_units()
	for id, unit in pairs(self._sequence_units) do
		if not alive(unit) then
			self:_remove_by_unit_id(id)
			self._sequence_units[id] = nil
		end
	end
end
function CoreUnitSequenceTriggerUnitElement:draw_links_unselected(...)
	CoreUnitSequenceTriggerUnitElement.super.draw_links_unselected(self, ...)
	for id, unit in pairs(self._sequence_units) do
		local params = {
			from_unit = unit,
			to_unit = self._unit,
			r = 0,
			g = 0,
			b = 0.5
		}
		self:_draw_link(params)
		Application:draw(unit, 0, 0, 0.5)
	end
end
function CoreUnitSequenceTriggerUnitElement:update_editing()
	local ray = managers.editor:unit_by_raycast({
		sample = true,
		mask = managers.slot:get_mask("all"),
		ray_type = "body editor"
	})
	if ray and ray.unit then
		local sequences = managers.sequence:get_sequence_list(ray.unit:name())
		if 0 < #sequences then
			Application:draw(ray.unit, 0, 1, 0)
		end
	end
end
function CoreUnitSequenceTriggerUnitElement:select_unit()
	local ray = managers.editor:unit_by_raycast({
		sample = true,
		mask = managers.slot:get_mask("all"),
		ray_type = "body editor"
	})
	if ray and ray.unit then
		local unit = ray.unit
		local sequences = managers.sequence:get_sequence_list(unit:name())
		if 0 < #sequences then
			self._sequence_units[unit:unit_data().unit_id] = unit
			local sequence_list_data = {
				unit_id = unit:unit_data().unit_id,
				sequence = "none"
			}
			table.insert(self._hed.sequence_list, sequence_list_data)
			self:_add_unit(unit, sequences, sequence_list_data)
		end
	end
end
function CoreUnitSequenceTriggerUnitElement:add_triggers(vc)
	vc:add_trigger(Idstring("lmb"), callback(self, self, "select_unit"))
end
function CoreUnitSequenceTriggerUnitElement:_build_panel(panel, panel_sizer)
	self:_check_alive_units()
	self:_create_panel()
	panel = panel or self._panel
	panel_sizer = panel_sizer or self._panel_sizer
	for _, data in pairs(self._hed.sequence_list) do
		local unit = self._sequence_units[data.unit_id]
		local sequences = managers.sequence:get_sequence_list(unit:name())
		self:_add_unit(unit, sequences, data)
	end
end
function CoreUnitSequenceTriggerUnitElement:_remove_by_unit_id(unit_id)
	local remove_entries = {}
	for id, entry in pairs(self._guis) do
		if entry.unit_id == unit_id then
			table.insert(remove_entries, id)
		end
	end
	for _, id in ipairs(remove_entries) do
		self:remove_entry(id)
	end
	for i, data in ipairs(clone(self._hed.sequence_list)) do
		if data.unit_id == unit_id then
			table.remove(self._hed.sequence_list, i)
		end
	end
	self:_remove_from_sequence_list(unit_id)
end
function CoreUnitSequenceTriggerUnitElement:remove_entry(id)
	local unit_id = self._guis[id].unit_id
	self._guis[id].unit_id_ctrlr:destroy()
	self._guis[id].sequence:destroy()
	self._guis[id].name_ctrlr:destroy()
	self._guis[id].toolbar:destroy()
	self._guis[id] = nil
	self._panel:layout()
	for i, entry in pairs(clone(self._hed.sequence_list)) do
		if entry.guis_id == id then
			table.remove(self._hed.sequence_list, i)
		end
	end
	for _, guis in pairs(self._guis) do
		if guis.unit_id == unit_id then
			return
		end
	end
	self._sequence_units[unit_id] = nil
end
function CoreUnitSequenceTriggerUnitElement:_remove_from_sequence_list(unit_id)
	for i, entry in pairs(clone(self._hed.sequence_list)) do
		if entry.unit_id == unit_id then
			table.insert(self._hed.sequence_list, i)
		end
	end
end
function CoreUnitSequenceTriggerUnitElement:_add_unit(unit, sequences, sequence_list_data)
	local panel = self._panel
	local panel_sizer = self._panel_sizer
	local unit_id = EWS:StaticText(panel, "" .. unit:unit_data().name_id, 0, "")
	panel_sizer:add(unit_id, 0, 0, "EXPAND")
	local h_sizer = EWS:BoxSizer("HORIZONTAL")
	panel_sizer:add(h_sizer, 0, 1, "EXPAND,LEFT")
	local sequence_params = {
		name = "Sequence:",
		panel = panel,
		sizer = h_sizer,
		options = sequences,
		default = "none",
		value = sequence_list_data.sequence,
		tooltip = "Select a sequence from the combobox",
		name_proportions = 1,
		ctrlr_proportions = 2,
		sizer_proportions = 1,
		sorted = true
	}
	local sequence = CoreEws.combobox(sequence_params)
	self._guis_id = self._guis_id or 0
	self._guis_id = self._guis_id + 1
	sequence_list_data.guis_id = self._guis_id
	local toolbar = EWS:ToolBar(panel, "", "TB_FLAT,TB_NODIVIDER")
	toolbar:add_tool("SELECT", "Select dialog", CoreEws.image_path("toolbar\\delete_16x16.png"), nil)
	toolbar:connect("SELECT", "EVT_COMMAND_MENU_SELECTED", callback(self, self, "remove_entry"), self._guis_id)
	toolbar:realize()
	self._guis[self._guis_id] = {
		unit_id_ctrlr = unit_id,
		unit = unit,
		unit_id = unit:unit_data().unit_id,
		sequence = sequence,
		name_ctrlr = sequence_params.name_ctrlr,
		toolbar = toolbar,
		guis_id = self._guis_id
	}
	h_sizer:add(toolbar, 0, 1, "EXPAND,LEFT")
	sequence:connect("EVT_COMMAND_COMBOBOX_SELECTED", callback(self, self, "set_sequence_data"), self._guis_id)
	panel:layout()
end
function CoreUnitSequenceTriggerUnitElement:set_sequence_data(guis_id)
	local sequence = self._guis[guis_id].sequence:get_value()
	for i, entry in pairs(self._hed.sequence_list) do
		if entry.guis_id == guis_id then
			entry.sequence = sequence
			break
		end
	end
end
