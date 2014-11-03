core:import("CoreEngineAccess")
CorePlayEffectUnitElement = CorePlayEffectUnitElement or class(MissionElement)
PlayEffectUnitElement = PlayEffectUnitElement or class(CorePlayEffectUnitElement)
function PlayEffectUnitElement:init(...)
	CorePlayEffectUnitElement.init(self, ...)
end
function CorePlayEffectUnitElement:init(unit)
	MissionElement.init(self, unit)
	self._hed.effect = "none"
	self._hed.screen_space = false
	self._hed.base_time = 0
	self._hed.random_time = 0
	self._hed.max_amount = 0
	table.insert(self._save_values, "effect")
	table.insert(self._save_values, "screen_space")
	table.insert(self._save_values, "base_time")
	table.insert(self._save_values, "random_time")
	table.insert(self._save_values, "max_amount")
end
function CorePlayEffectUnitElement:test_element()
	if self._hed.effect ~= "none" then
		self:stop_test_element()
		CoreEngineAccess._editor_load(Idstring("effect"), self._hed.effect:id())
		local position = self._hed.screen_space and Vector3() or self._unit:position()
		local rotation = self._hed.screen_space and Rotation() or self._unit:rotation()
		self._effect = World:effect_manager():spawn({
			effect = self._hed.effect:id(),
			position = position,
			rotation = rotation
		})
	end
end
function CorePlayEffectUnitElement:stop_test_element()
	if self._effect then
		World:effect_manager():kill(self._effect)
		self._effect = false
	end
end
function CorePlayEffectUnitElement:select_effect_btn()
	local dialog = SelectNameModal:new("Select effect", self:_effect_options())
	if dialog:cancelled() then
		return
	end
	for _, effect in ipairs(dialog:_selected_item_assets()) do
		self._hed.effect = effect
		CoreEws.change_combobox_value(self._effects_params, self._hed.effect)
	end
end
function CorePlayEffectUnitElement:_effect_options()
	local effect_options = {}
	for _, name in ipairs(managers.database:list_entries_of_type("effect")) do
		table.insert(effect_options, name)
	end
	return effect_options
end
function CorePlayEffectUnitElement:_build_panel(panel, panel_sizer)
	self:_create_panel()
	panel = panel or self._panel
	panel_sizer = panel_sizer or self._panel_sizer
	local screen_space = EWS:CheckBox(panel, "Play in Screen Space", "")
	screen_space:set_value(self._hed.screen_space)
	screen_space:connect("EVT_COMMAND_CHECKBOX_CLICKED", callback(self, self, "set_element_data"), {
		ctrlr = screen_space,
		value = "screen_space"
	})
	panel_sizer:add(screen_space, 0, 0, "EXPAND")
	local effect_sizer = EWS:BoxSizer("HORIZONTAL")
	panel_sizer:add(effect_sizer, 0, 1, "EXPAND,LEFT")
	local effects_params = {
		name = "Effect:",
		panel = panel,
		sizer = effect_sizer,
		default = "none",
		options = self:_effect_options(),
		value = self._hed.effect,
		tooltip = "Select and effect from the combobox",
		name_proportions = 1,
		ctrlr_proportions = 2,
		sizer_proportions = 1,
		sorted = true
	}
	local effects = CoreEWS.combobox(effects_params)
	self._effects_params = effects_params
	effects:connect("EVT_COMMAND_COMBOBOX_SELECTED", callback(self, self, "set_element_data"), {ctrlr = effects, value = "effect"})
	local toolbar = EWS:ToolBar(panel, "", "TB_FLAT,TB_NODIVIDER")
	toolbar:add_tool("SELECT_EFFECT", "Select effect", CoreEws.image_path("world_editor\\unit_by_name_list.png"), nil)
	toolbar:connect("SELECT_EFFECT", "EVT_COMMAND_MENU_SELECTED", callback(self, self, "select_effect_btn"), nil)
	toolbar:realize()
	effect_sizer:add(toolbar, 0, 1, "EXPAND,LEFT")
	local base_time_params = {
		name = "Base Time:",
		panel = panel,
		sizer = panel_sizer,
		value = self._hed.base_time,
		floats = 2,
		tooltip = "This is the minimum time to wait before spawning next effect",
		min = 0,
		name_proportions = 1,
		ctrlr_proportions = 2
	}
	local base_time = CoreEWS.number_controller(base_time_params)
	base_time:connect("EVT_COMMAND_TEXT_ENTER", callback(self, self, "set_element_data"), {ctrlr = base_time, value = "base_time"})
	base_time:connect("EVT_KILL_FOCUS", callback(self, self, "set_element_data"), {ctrlr = base_time, value = "base_time"})
	local random_time_params = {
		name = "Random Time:",
		panel = panel,
		sizer = panel_sizer,
		value = self._hed.random_time,
		floats = 2,
		tooltip = "Random time is added to minimum time to give the time between effect spawns",
		min = 0,
		name_proportions = 1,
		ctrlr_proportions = 2
	}
	local random_time = CoreEWS.number_controller(random_time_params)
	random_time:connect("EVT_COMMAND_TEXT_ENTER", callback(self, self, "set_element_data"), {
		ctrlr = random_time,
		value = "random_time"
	})
	random_time:connect("EVT_KILL_FOCUS", callback(self, self, "set_element_data"), {
		ctrlr = random_time,
		value = "random_time"
	})
	local max_amount_params = {
		name = "Max Amount:",
		panel = panel,
		sizer = panel_sizer,
		value = self._hed.max_amount,
		floats = 0,
		tooltip = "Maximum amount of spawns when repeating effects (0 = unlimited)",
		min = 0,
		name_proportions = 1,
		ctrlr_proportions = 2
	}
	local max_amount = CoreEWS.number_controller(max_amount_params)
	max_amount:connect("EVT_COMMAND_TEXT_ENTER", callback(self, self, "set_element_data"), {ctrlr = max_amount, value = "max_amount"})
	max_amount:connect("EVT_KILL_FOCUS", callback(self, self, "set_element_data"), {ctrlr = max_amount, value = "max_amount"})
	local help = {}
	help.text = [[
Choose an effect from the combobox. Use "Play in Screen Space" if the effect is set up to be played like that. 

Use base time and random time if you want to repeat playing the effect, keep them at 0 to only play it once. "Base Time" is the minimum time between effects. "Random Time" is added to base time to set the total time until next effect. "Max Amount" can be used to set how many times the effect should be repeated (when base time and random time are used). 

Be sure not to use a looping effect when using repeat or the effects will add to each other and wont be stoppable after run simulation or by calling kill or fade kill.]]
	help.panel = panel
	help.sizer = panel_sizer
	self:add_help_text(help)
end
function CorePlayEffectUnitElement:add_to_mission_package()
	if self._hed.effect and self._hed.effect ~= "none" then
		managers.editor:add_to_world_package({
			category = "effects",
			name = self._hed.effect,
			continent = self._unit:unit_data().continent
		})
	end
end
CoreStopEffectUnitElement = CoreStopEffectUnitElement or class(MissionElement)
StopEffectUnitElement = StopEffectUnitElement or class(CoreStopEffectUnitElement)
function StopEffectUnitElement:init(...)
	CoreStopEffectUnitElement.init(self, ...)
end
function CoreStopEffectUnitElement:init(unit)
	MissionElement.init(self, unit)
	self._hed.operation = "fade_kill"
	self._hed.elements = {}
	self._elements_units = {}
	table.insert(self._save_values, "operation")
	table.insert(self._save_values, "elements")
end
function CoreStopEffectUnitElement:layer_finished(...)
	MissionElement.layer_finished(self, ...)
	for _, id in ipairs(self._hed.elements) do
		local unit = managers.worlddefinition:get_mission_element_unit(id)
		table.insert(self._elements_units, unit)
	end
end
function CoreStopEffectUnitElement:draw_links(t, dt, selected_unit)
	MissionElement.draw_links(self, t, dt, selected_unit)
	for _, unit in ipairs(self._elements_units) do
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
function CoreStopEffectUnitElement:update_editing()
end
function CoreStopEffectUnitElement:add_element()
	local ray = managers.editor:unit_by_raycast({mask = 10, ray_type = "editor"})
	if ray and ray.unit and string.find(ray.unit:name():s(), "env_effect_play", 1, true) then
		local id = ray.unit:unit_data().unit_id
		if table.contains(self._hed.elements, id) then
			table.delete(self._hed.elements, id)
			table.delete(self._elements_units, ray.unit)
		else
			table.insert(self._hed.elements, id)
			table.insert(self._elements_units, ray.unit)
		end
	end
end
function CoreStopEffectUnitElement:remove_links(unit)
	MissionElement.remove_links(self, unit)
	for _, id in ipairs(self._hed.elements) do
		if id == unit:unit_data().unit_id then
			table.delete(self._hed.elements, id)
			table.delete(self._elements_units, unit)
		end
	end
end
function CoreStopEffectUnitElement:add_triggers(vc)
	vc:add_trigger(Idstring("lmb"), callback(self, self, "add_element"))
end
function CoreStopEffectUnitElement:_build_panel(panel, panel_sizer)
	self:_create_panel()
	panel = panel or self._panel
	panel_sizer = panel_sizer or self._panel_sizer
	local operation_params = {
		name = "Operation:",
		panel = panel,
		sizer = panel_sizer,
		options = {"kill", "fade_kill"},
		value = self._hed.operation,
		tooltip = "Select a kind of operation to perform on the added effects",
		name_proportions = 1,
		ctrlr_proportions = 2
	}
	local operation = CoreEWS.combobox(operation_params)
	operation:connect("EVT_COMMAND_COMBOBOX_SELECTED", callback(self, self, "set_element_data"), {ctrlr = operation, value = "operation"})
end
