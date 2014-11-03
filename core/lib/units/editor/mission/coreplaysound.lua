CorePlaySoundUnitElement = CorePlaySoundUnitElement or class(MissionElement)
PlaySoundUnitElement = PlaySoundUnitElement or class(CorePlaySoundUnitElement)
function PlaySoundUnitElement:init(...)
	PlaySoundUnitElement.super.init(self, ...)
end
function CorePlaySoundUnitElement:init(unit)
	CorePlaySoundUnitElement.super.init(self, unit)
	self._hed.elements = {}
	self._hed.append_prefix = false
	table.insert(self._save_values, "sound_event")
	table.insert(self._save_values, "elements")
	table.insert(self._save_values, "append_prefix")
end
function CorePlaySoundUnitElement:draw_links(t, dt, selected_unit, all_units)
	MissionElement.draw_links(self, t, dt, selected_unit, all_units)
end
function CorePlaySoundUnitElement:update_editing()
end
function CorePlaySoundUnitElement:update_selected(t, dt, selected_unit, all_units)
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
function CorePlaySoundUnitElement:add_element()
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
function CorePlaySoundUnitElement:remove_links(unit)
	for _, id in ipairs(self._hed.elements) do
		if id == unit:unit_data().unit_id then
			table.delete(self._hed.elements, id)
		end
	end
end
function CorePlaySoundUnitElement:add_triggers(vc)
	vc:add_trigger(Idstring("lmb"), callback(self, self, "add_element"))
end
function CorePlaySoundUnitElement:post_init(...)
	CorePlaySoundUnitElement.super.post_init(self, ...)
	self:_add_soundbank()
end
function CorePlaySoundUnitElement:test_element()
	if self._hed.sound_event then
		managers.editor:set_wanted_mute(false)
		managers.editor:set_listener_enabled(true)
		if self._ss then
			self._ss:stop()
		end
		self._ss = SoundDevice:create_source(self._unit:unit_data().name_id)
		self._ss:set_position(self._unit:position())
		self._ss:set_orientation(self._unit:rotation())
		self._ss:post_event(self._hed.sound_event)
	end
end
function CorePlaySoundUnitElement:stop_test_element()
	managers.editor:set_wanted_mute(true)
	managers.editor:set_listener_enabled(false)
	if self._ss then
		self._ss:stop()
	end
end
function CorePlaySoundUnitElement:set_category()
	local value = self._paths_params.value
	CoreEWS.update_combobox_options(self._sound_params, managers.sound_environment:scene_events(value))
	CoreEWS.change_combobox_value(self._sound_params, managers.sound_environment:scene_events(value)[1])
	self._hed.sound_event = self._sound_params.value
	self:_add_soundbank()
end
function CorePlaySoundUnitElement:_add_soundbank()
	self:stop_test_element()
	managers.sound_environment:add_soundbank(managers.sound_environment:scene_soundbank(self._hed.sound_event))
end
function CorePlaySoundUnitElement:_build_panel(panel, panel_sizer)
	self:_create_panel()
	panel = panel or self._panel
	panel_sizer = panel_sizer or self._panel_sizer
	local paths = managers.sound_environment:scene_paths()
	if #paths <= 0 then
		local help = {}
		help.text = "No scene sounds available in project!"
		help.panel = panel
		help.sizer = panel_sizer
		self:add_help_text(help)
		return
	end
	self._hed.sound_event = self._hed.sound_event or managers.sound_environment:scene_events(paths[1])[1]
	self:_add_soundbank()
	local path_value = managers.sound_environment:scene_path(self._hed.sound_event)
	self._paths_params = {
		name = "Category:",
		panel = panel,
		sizer = panel_sizer,
		options = paths,
		value = path_value,
		tooltip = "Select a category from the combobox",
		name_proportions = 1,
		ctrlr_proportions = 2,
		sorted = true
	}
	local paths = CoreEWS.combobox(self._paths_params)
	paths:connect("EVT_COMMAND_COMBOBOX_SELECTED", callback(self, self, "set_category"), nil)
	self._sound_params = {
		name = "Event:",
		panel = panel,
		sizer = panel_sizer,
		options = managers.sound_environment:scene_events(self._paths_params.value),
		value = self._hed.sound_event,
		tooltip = "Select a sound event from the combobox",
		name_proportions = 1,
		ctrlr_proportions = 2,
		sorted = true
	}
	local sound_events = CoreEWS.combobox(self._sound_params)
	sound_events:connect("EVT_COMMAND_COMBOBOX_SELECTED", callback(self, self, "set_element_data"), {
		ctrlr = sound_events,
		value = "sound_event"
	})
	sound_events:connect("EVT_COMMAND_COMBOBOX_SELECTED", callback(self, self, "_add_soundbank"), nil)
	local prefix = EWS:CheckBox(panel, "Append unit prefix", "")
	prefix:set_value(self._hed.append_prefix)
	prefix:connect("EVT_COMMAND_CHECKBOX_CLICKED", callback(self, self, "set_element_data"), {
		ctrlr = prefix,
		value = "append_prefix"
	})
	panel_sizer:add(prefix, 0, 0, "EXPAND")
end
function CorePlaySoundUnitElement:add_to_mission_package()
	managers.editor:add_to_sound_package({
		category = "soundbanks",
		name = managers.sound_environment:scene_soundbank(self._hed.sound_event)
	})
end
function CorePlaySoundUnitElement:destroy()
	self:stop_test_element()
	CorePlaySoundUnitElement.super.destroy(self)
end
