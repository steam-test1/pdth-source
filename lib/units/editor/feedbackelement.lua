FeedbackUnitElement = FeedbackUnitElement or class(MissionElement)
function FeedbackUnitElement:init(unit)
	FeedbackUnitElement.super.init(self, unit)
	self._hed.effect = "mission_triggered"
	self._hed.range = 0
	self._hed.use_camera_shake = true
	self._hed.use_rumble = true
	self._hed.camera_shake_amplitude = 1
	self._hed.camera_shake_attack = 0.1
	self._hed.camera_shake_sustain = 0.3
	self._hed.camera_shake_decay = 2.1
	self._hed.rumble_peak = 1
	self._hed.rumble_attack = 0.1
	self._hed.rumble_sustain = 0.3
	self._hed.rumble_release = 2.1
	self._hed.above_camera_effect = "none"
	self._hed.above_camera_effect_distance = 0.5
	table.insert(self._save_values, "effect")
	table.insert(self._save_values, "range")
	table.insert(self._save_values, "use_camera_shake")
	table.insert(self._save_values, "use_rumble")
	table.insert(self._save_values, "camera_shake_amplitude")
	table.insert(self._save_values, "camera_shake_attack")
	table.insert(self._save_values, "camera_shake_sustain")
	table.insert(self._save_values, "camera_shake_decay")
	table.insert(self._save_values, "rumble_peak")
	table.insert(self._save_values, "rumble_attack")
	table.insert(self._save_values, "rumble_sustain")
	table.insert(self._save_values, "rumble_release")
	table.insert(self._save_values, "above_camera_effect")
	table.insert(self._save_values, "above_camera_effect_distance")
end
function FeedbackUnitElement:update_selected()
	local brush = Draw:brush()
	brush:set_color(Color(0.15, 1, 1, 1))
	local pen = Draw:pen(Color(0.15, 0.5, 0.5, 0.5))
	brush:sphere(self._unit:position(), self._hed.range, 4)
	pen:sphere(self._unit:position(), self._hed.range)
	brush:set_color(Color(0.15, 0, 1, 0))
	pen:set(Color(0.15, 0, 1, 0))
	brush:sphere(self._unit:position(), self._hed.range * self._hed.above_camera_effect_distance, 4)
	pen:sphere(self._unit:position(), self._hed.range * self._hed.above_camera_effect_distance)
end
function FeedbackUnitElement:_build_panel(panel, panel_sizer)
	self:_create_panel()
	panel = panel or self._panel
	panel_sizer = panel_sizer or self._panel_sizer
	local range_params = {
		name = "Range:",
		panel = panel,
		sizer = panel_sizer,
		value = self._hed.range,
		floats = 0,
		tooltip = "The range the effect should be felt. 0 means that it will be felt everywhere",
		min = -1,
		name_proportions = 1,
		ctrlr_proportions = 2
	}
	local range = CoreEws.number_controller(range_params)
	range:connect("EVT_COMMAND_TEXT_ENTER", callback(self, self, "set_element_data"), {ctrlr = range, value = "range"})
	range:connect("EVT_KILL_FOCUS", callback(self, self, "set_element_data"), {ctrlr = range, value = "range"})
	local camera_shaker_sizer = EWS:StaticBoxSizer(panel, "VERTICAL", "Camera shake")
	panel_sizer:add(camera_shaker_sizer, 0, 0, "EXPAND")
	local use_camera_shake = EWS:CheckBox(panel, "Use camera shake", "")
	use_camera_shake:set_value(self._hed.use_camera_shake)
	use_camera_shake:connect("EVT_COMMAND_CHECKBOX_CLICKED", callback(self, self, "set_element_data"), {
		ctrlr = use_camera_shake,
		value = "use_camera_shake"
	})
	camera_shaker_sizer:add(use_camera_shake, 0, 0, "EXPAND")
	local camera_shake_amplitude_params = {
		name = "Amplitude:",
		panel = panel,
		sizer = camera_shaker_sizer,
		value = self._hed.camera_shake_amplitude,
		floats = 2,
		tooltip = "Amplitude basicly decides the strenght of the shake",
		min = -1,
		name_proportions = 1,
		ctrlr_proportions = 2
	}
	local camera_shake_amplitude = CoreEws.number_controller(camera_shake_amplitude_params)
	camera_shake_amplitude:connect("EVT_COMMAND_TEXT_ENTER", callback(self, self, "set_element_data"), {
		ctrlr = camera_shake_amplitude,
		value = "camera_shake_amplitude"
	})
	camera_shake_amplitude:connect("EVT_KILL_FOCUS", callback(self, self, "set_element_data"), {
		ctrlr = camera_shake_amplitude,
		value = "camera_shake_amplitude"
	})
	local camera_shake_attack_params = {
		name = "Attack:",
		panel = panel,
		sizer = camera_shaker_sizer,
		value = self._hed.camera_shake_attack,
		floats = 2,
		tooltip = "Time to reach maximum shake",
		min = -1,
		name_proportions = 1,
		ctrlr_proportions = 2
	}
	local camera_shake_attack = CoreEws.number_controller(camera_shake_attack_params)
	camera_shake_attack:connect("EVT_COMMAND_TEXT_ENTER", callback(self, self, "set_element_data"), {
		ctrlr = camera_shake_attack,
		value = "camera_shake_attack"
	})
	camera_shake_attack:connect("EVT_KILL_FOCUS", callback(self, self, "set_element_data"), {
		ctrlr = camera_shake_attack,
		value = "camera_shake_attack"
	})
	local camera_shake_sustain_params = {
		name = "Sustain:",
		panel = panel,
		sizer = camera_shaker_sizer,
		value = self._hed.camera_shake_sustain,
		floats = 2,
		tooltip = "Time to sustain maximum shake",
		min = -1,
		name_proportions = 1,
		ctrlr_proportions = 2
	}
	local camera_shake_sustain = CoreEws.number_controller(camera_shake_sustain_params)
	camera_shake_sustain:connect("EVT_COMMAND_TEXT_ENTER", callback(self, self, "set_element_data"), {
		ctrlr = camera_shake_sustain,
		value = "camera_shake_sustain"
	})
	camera_shake_sustain:connect("EVT_KILL_FOCUS", callback(self, self, "set_element_data"), {
		ctrlr = camera_shake_sustain,
		value = "camera_shake_sustain"
	})
	local camera_shake_decay_params = {
		name = "Decay:",
		panel = panel,
		sizer = camera_shaker_sizer,
		value = self._hed.camera_shake_decay,
		floats = 2,
		tooltip = "Time to decay from maximum shake to zero",
		min = -1,
		name_proportions = 1,
		ctrlr_proportions = 2
	}
	local camera_shake_decay = CoreEws.number_controller(camera_shake_decay_params)
	camera_shake_decay:connect("EVT_COMMAND_TEXT_ENTER", callback(self, self, "set_element_data"), {
		ctrlr = camera_shake_decay,
		value = "camera_shake_decay"
	})
	camera_shake_decay:connect("EVT_KILL_FOCUS", callback(self, self, "set_element_data"), {
		ctrlr = camera_shake_decay,
		value = "camera_shake_decay"
	})
	local rumble_sizer = EWS:StaticBoxSizer(panel, "VERTICAL", "Rumble")
	panel_sizer:add(rumble_sizer, 0, 0, "EXPAND")
	local use_rumble = EWS:CheckBox(panel, "Use rumble", "")
	use_rumble:set_value(self._hed.use_rumble)
	use_rumble:connect("EVT_COMMAND_CHECKBOX_CLICKED", callback(self, self, "set_element_data"), {ctrlr = use_rumble, value = "use_rumble"})
	rumble_sizer:add(use_rumble, 0, 0, "EXPAND")
	local rumble_peak_params = {
		name = "Peak:",
		panel = panel,
		sizer = rumble_sizer,
		value = self._hed.rumble_peak,
		floats = 2,
		tooltip = "A value to determine the strength of the rumble",
		min = -1,
		max = 1,
		name_proportions = 1,
		ctrlr_proportions = 2
	}
	local rumble_peak = CoreEws.number_controller(rumble_peak_params)
	rumble_peak:connect("EVT_COMMAND_TEXT_ENTER", callback(self, self, "set_element_data"), {
		ctrlr = rumble_peak,
		value = "rumble_peak"
	})
	rumble_peak:connect("EVT_KILL_FOCUS", callback(self, self, "set_element_data"), {
		ctrlr = rumble_peak,
		value = "rumble_peak"
	})
	local rumble_attack_params = {
		name = "Attack:",
		panel = panel,
		sizer = rumble_sizer,
		value = self._hed.rumble_attack,
		floats = 2,
		tooltip = "Time to reach maximum rumble",
		min = -1,
		name_proportions = 1,
		ctrlr_proportions = 2
	}
	local rumble_attack = CoreEws.number_controller(rumble_attack_params)
	rumble_attack:connect("EVT_COMMAND_TEXT_ENTER", callback(self, self, "set_element_data"), {
		ctrlr = rumble_attack,
		value = "rumble_attack"
	})
	rumble_attack:connect("EVT_KILL_FOCUS", callback(self, self, "set_element_data"), {
		ctrlr = rumble_attack,
		value = "rumble_attack"
	})
	local rumble_sustain_params = {
		name = "Sustain:",
		panel = panel,
		sizer = rumble_sizer,
		value = self._hed.rumble_sustain,
		floats = 2,
		tooltip = "Time to sustain maximum rumble",
		min = -1,
		name_proportions = 1,
		ctrlr_proportions = 2
	}
	local rumble_sustain = CoreEws.number_controller(rumble_sustain_params)
	rumble_sustain:connect("EVT_COMMAND_TEXT_ENTER", callback(self, self, "set_element_data"), {
		ctrlr = rumble_sustain,
		value = "rumble_sustain"
	})
	rumble_sustain:connect("EVT_KILL_FOCUS", callback(self, self, "set_element_data"), {
		ctrlr = rumble_sustain,
		value = "rumble_sustain"
	})
	local rumble_release_params = {
		name = "Release:",
		panel = panel,
		sizer = rumble_sizer,
		value = self._hed.rumble_release,
		floats = 2,
		tooltip = "Time to decay from maximum rumble to zero",
		min = -1,
		name_proportions = 1,
		ctrlr_proportions = 2
	}
	local rumble_release = CoreEws.number_controller(rumble_release_params)
	rumble_release:connect("EVT_COMMAND_TEXT_ENTER", callback(self, self, "set_element_data"), {
		ctrlr = rumble_release,
		value = "rumble_release"
	})
	rumble_release:connect("EVT_KILL_FOCUS", callback(self, self, "set_element_data"), {
		ctrlr = rumble_release,
		value = "rumble_release"
	})
	local above_camera_effect_sizer = EWS:StaticBoxSizer(panel, "VERTICAL", "Above camera effect")
	panel_sizer:add(above_camera_effect_sizer, 0, 0, "EXPAND")
	local effect_sizer = EWS:BoxSizer("HORIZONTAL")
	above_camera_effect_sizer:add(effect_sizer, 0, 1, "EXPAND,LEFT")
	local above_camera_effect_params = {
		name = "Effect:",
		panel = panel,
		sizer = effect_sizer,
		default = "none",
		options = self:_effect_options(),
		value = self._hed.above_camera_effect,
		tooltip = "Select and above camera effect from the combobox",
		name_proportions = 1,
		ctrlr_proportions = 2,
		sizer_proportions = 1,
		sorted = true
	}
	local above_camera_effect = CoreEWS.combobox(above_camera_effect_params)
	self._above_camera_effect_params = above_camera_effect_params
	above_camera_effect:connect("EVT_COMMAND_COMBOBOX_SELECTED", callback(self, self, "set_element_data"), {
		ctrlr = above_camera_effect,
		value = "above_camera_effect"
	})
	local toolbar = EWS:ToolBar(panel, "", "TB_FLAT,TB_NODIVIDER")
	toolbar:add_tool("SELECT_EFFECT", "Select effect", CoreEws.image_path("world_editor\\unit_by_name_list.png"), nil)
	toolbar:connect("SELECT_EFFECT", "EVT_COMMAND_MENU_SELECTED", callback(self, self, "select_above_camera_effect_btn"), nil)
	toolbar:realize()
	effect_sizer:add(toolbar, 0, 1, "EXPAND,LEFT")
	local above_camera_effect_distance_params = {
		name = "Distance filter:",
		panel = panel,
		sizer = above_camera_effect_sizer,
		value = self._hed.above_camera_effect_distance,
		floats = 2,
		tooltip = "A filter value to use with the range. A value of 1 means that the effect will be played whenever inside the range, a lower value means you need to be closer to the position.",
		min = 0,
		max = 1,
		name_proportions = 1,
		ctrlr_proportions = 2
	}
	local above_camera_effect_distance = CoreEws.number_controller(above_camera_effect_distance_params)
	above_camera_effect_distance:connect("EVT_COMMAND_TEXT_ENTER", callback(self, self, "set_element_data"), {
		ctrlr = above_camera_effect_distance,
		value = "above_camera_effect_distance"
	})
	above_camera_effect_distance:connect("EVT_KILL_FOCUS", callback(self, self, "set_element_data"), {
		ctrlr = above_camera_effect_distance,
		value = "above_camera_effect_distance"
	})
end
function FeedbackUnitElement:select_above_camera_effect_btn()
	local dialog = SelectNameModal:new("Select effect", self:_effect_options())
	if dialog:cancelled() then
		return
	end
	for _, effect in ipairs(dialog:_selected_item_assets()) do
		self._hed.above_camera_effect = effect
		CoreEws.change_combobox_value(self._above_camera_effect_params, self._hed.above_camera_effect)
	end
end
function FeedbackUnitElement:_effect_options()
	local effect_options = {}
	for _, name in ipairs(managers.database:list_entries_of_type("effect")) do
		table.insert(effect_options, name)
	end
	return effect_options
end
function FeedbackUnitElement:add_to_mission_package()
	if self._hed.effect and self._hed.above_camera_effect ~= "none" then
		managers.editor:add_to_world_package({
			category = "effects",
			name = self._hed.above_camera_effect,
			continent = self._unit:unit_data().continent
		})
	end
end
