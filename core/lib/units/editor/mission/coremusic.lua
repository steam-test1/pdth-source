CoreMusicUnitElement = CoreMusicUnitElement or class(MissionElement)
MusicUnitElement = MusicUnitElement or class(CoreMusicUnitElement)
function MusicUnitElement:init(...)
	CoreMusicUnitElement.init(self, ...)
end
function CoreMusicUnitElement:init(unit)
	MissionElement.init(self, unit)
	table.insert(self._save_values, "music_event")
end
function CoreMusicUnitElement:test_element()
	if self._hed.music_event then
		managers.editor:set_wanted_mute(false)
		managers.music:post_event(self._hed.music_event)
	end
end
function CoreMusicUnitElement:stop_test_element()
	managers.editor:set_wanted_mute(true)
	managers.music:stop()
end
function CoreMusicUnitElement:set_category()
	local value = self._paths_params.value
	CoreEWS.update_combobox_options(self._music_params, managers.music:music_events(value))
	CoreEWS.change_combobox_value(self._music_params, managers.music:music_events(value)[1])
	self._hed.music_event = self._music_params.value
end
function CoreMusicUnitElement:_build_panel(panel, panel_sizer)
	self:_create_panel()
	panel = panel or self._panel
	panel_sizer = panel_sizer or self._panel_sizer
	local paths = clone(managers.music:music_paths())
	if #paths <= 0 then
		local help = {}
		help.text = "No music available in project!"
		help.panel = panel
		help.sizer = panel_sizer
		self:add_help_text(help)
		return
	end
	self._hed.music_event = self._hed.music_event or managers.music:music_events(paths[1])[1]
	local path_value = managers.music:music_path(self._hed.music_event)
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
	self._music_params = {
		name = "Music:",
		panel = panel,
		sizer = panel_sizer,
		options = managers.music:music_events(self._paths_params.value),
		value = self._hed.music_event,
		tooltip = "Select a music event from the combobox",
		name_proportions = 1,
		ctrlr_proportions = 2,
		sorted = true
	}
	local music_events = CoreEWS.combobox(self._music_params)
	music_events:connect("EVT_COMMAND_COMBOBOX_SELECTED", callback(self, self, "set_element_data"), {
		ctrlr = music_events,
		value = "music_event"
	})
end
