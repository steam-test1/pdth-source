SpecialObjectiveUnitElement = SpecialObjectiveUnitElement or class(MissionElement)
SpecialObjectiveUnitElement._AI_SO_types = {
	"AI_defend",
	"AI_security",
	"AI_hunt",
	"AI_search",
	"AI_idle",
	"AI_escort",
	"AI_sniper"
}
function SpecialObjectiveUnitElement:init(unit)
	SpecialObjectiveUnitElement.super.init(self, unit)
	self._enemies = {}
	self._nav_link_filter = {}
	self._nav_link_filter_check_boxes = {}
	self._hed.ai_group = "enemies"
	self._hed.align_rotation = true
	self._hed.align_position = true
	self._hed.repeatable = false
	self._hed.use_instigator = false
	self._hed.scan = true
	self._hed.patrol_path = "none"
	self._hed.path_style = ElementSpecialObjective._pathing_type_default
	self._hed.path_haste = "none"
	self._hed.path_stance = "none"
	self._hed.pose = "none"
	self._hed.so_action = "none"
	self._hed.search_position = self._unit:position()
	self._hed.search_distance = 0
	self._hed.interval = -1
	self._hed.base_chance = 1
	self._hed.chance_inc = 0
	self._hed.follow_up_id = nil
	self._hed.interrupt_on = "obstructed"
	self._hed.attitude = "avoid"
	self._hed.follow_up_id = nil
	self._hed.spawn_instigator_ids = {}
	self._hed.trigger_on = nil
	self._hed.interaction_voice = nil
	self._hed.SO_access = "0"
	self._hed.is_navigation_link = false
	self._hed.access_flag_version = 1
	table.insert(self._save_values, "ai_group")
	table.insert(self._save_values, "align_rotation")
	table.insert(self._save_values, "align_position")
	table.insert(self._save_values, "repeatable")
	table.insert(self._save_values, "use_instigator")
	table.insert(self._save_values, "scan")
	table.insert(self._save_values, "patrol_path")
	table.insert(self._save_values, "path_style")
	table.insert(self._save_values, "path_haste")
	table.insert(self._save_values, "path_stance")
	table.insert(self._save_values, "pose")
	table.insert(self._save_values, "so_action")
	table.insert(self._save_values, "search_position")
	table.insert(self._save_values, "search_distance")
	table.insert(self._save_values, "interval")
	table.insert(self._save_values, "base_chance")
	table.insert(self._save_values, "chance_inc")
	table.insert(self._save_values, "interrupt_on")
	table.insert(self._save_values, "attitude")
	table.insert(self._save_values, "follow_up_id")
	table.insert(self._save_values, "spawn_instigator_ids")
	table.insert(self._save_values, "trigger_on")
	table.insert(self._save_values, "interaction_voice")
	table.insert(self._save_values, "SO_access")
	table.insert(self._save_values, "is_navigation_link")
	table.insert(self._save_values, "access_flag_version")
end
function SpecialObjectiveUnitElement:post_init()
	if self._hed.navigation_link and self._hed.navigation_link ~= -1 and tonumber(self._hed.SO_access) == 0 then
		self._hed.SO_access = tostring(managers.navigation:convert_nav_link_maneuverability_to_SO_access(self._hed.navigation_link))
	end
	if self._hed.navigation_link and self._hed.navigation_link ~= -1 and not self._hed.is_navigation_link then
		self._hed.is_navigation_link = true
	end
	if not self._hed.is_navigation_link and (not self._hed.SO_access or self._hed.SO_access == "0") then
		self._hed.SO_access = tostring(managers.navigation:convert_SO_AI_group_to_access(self._hed.ai_group))
	end
	self._nav_link_filter = managers.navigation:convert_SO_access_filter(tonumber(self._hed.SO_access))
end
function SpecialObjectiveUnitElement:test_element()
	local SO_access_strings = managers.navigation:convert_SO_access_filter(tonumber(self._hed.SO_access))
	local spawn_unit_name
	for _, access_category in ipairs(SO_access_strings) do
		if access_category == "civ_male" then
			spawn_unit_name = Idstring("units/characters/civilians/casual_male_2/casual_male_2")
		elseif access_category == "civ_female" then
			spawn_unit_name = Idstring("units/characters/civilians/suit_female_2/suit_female_2")
		else
			spawn_unit_name = Idstring("units/characters/enemies/swat/swat")
		end
	end
	spawn_unit_name = spawn_unit_name or Idstring("units/characters/enemies/swat/swat")
	local enemy = safe_spawn_unit(spawn_unit_name, self._unit:position(), self._unit:rotation())
	table.insert(self._enemies, enemy)
	ElementSpawnEnemyDummy.produce_test(self._hed, enemy)
	local t = {
		id = self._unit:unit_data().unit_id,
		editor_name = self._unit:unit_data().name_id
	}
	t.values = self:new_save_values()
	t.values.use_instigator = true
	t.values.is_navigation_link = false
	t.values.follow_up_id = nil
	t.values.trigger_on = "none"
	t.values.spawn_instigator_ids = {}
	self._script = MissionScript:new({
		elements = {}
	})
	self._so_class = ElementSpecialObjective:new(self._script, t)
	self._so_class:on_executed(enemy)
	self._start_test_t = Application:time()
end
function SpecialObjectiveUnitElement:stop_test_element()
	for _, enemy in ipairs(self._enemies) do
		enemy:set_slot(0)
	end
	self._enemies = {}
	print("Stop test time", self._start_test_t and Application:time() - self._start_test_t or 0)
end
function SpecialObjectiveUnitElement:draw_links(t, dt, selected_unit, all_units)
	SpecialObjectiveUnitElement.super.draw_links(self, t, dt, selected_unit)
	self:_draw_follow_up(selected_unit, all_units)
end
function SpecialObjectiveUnitElement:update_selected(t, dt, selected_unit, all_units)
	if self._hed.patrol_path ~= "none" then
		managers.editor:layer("Ai"):draw_patrol_path_externaly(self._hed.patrol_path)
	end
	local brush = Draw:brush()
	brush:set_color(Color(0.15, 1, 1, 1))
	local pen = Draw:pen(Color(0.15, 0.5, 0.5, 0.5))
	brush:sphere(self._hed.search_position, self._hed.search_distance, 4)
	pen:sphere(self._hed.search_position, self._hed.search_distance)
	brush:sphere(self._hed.search_position, 10, 4)
	Application:draw_line(self._hed.search_position, self._unit:position(), 0, 1, 0)
	self:_draw_follow_up(selected_unit, all_units)
	for _, id in ipairs(self._hed.spawn_instigator_ids) do
		local unit = all_units[id]
		local draw = not selected_unit or unit == selected_unit or self._unit == selected_unit
		if draw then
			self:_draw_link({
				from_unit = unit,
				to_unit = self._unit,
				r = 0,
				g = 0,
				b = 0.75
			})
		end
	end
	self:_highlight_if_outside_the_nav_field(t)
end
function SpecialObjectiveUnitElement:_highlight_if_outside_the_nav_field(t)
	if managers.navigation:is_data_ready() then
		local my_pos = self._unit:position()
		local nav_tracker = managers.navigation._quad_field:create_nav_tracker(my_pos, true)
		if nav_tracker:lost() then
			local t1 = t % 0.5
			local t2 = t % 1
			local alpha
			if t2 > 0.5 then
				alpha = t1
			else
				alpha = 0.5 - t1
			end
			alpha = math.lerp(0.1, 0.5, alpha)
			local nav_color = Color(alpha, 1, 0, 0)
			Draw:brush(nav_color):cylinder(my_pos, my_pos + math.UP * 80, 20, 4)
		end
		managers.navigation:destroy_nav_tracker(nav_tracker)
	end
end
function SpecialObjectiveUnitElement:update_unselected(t, dt, selected_unit, all_units)
	if self._hed.follow_up_id and not alive(all_units[self._hed.follow_up_id]) then
		self._hed.follow_up_id = nil
	end
	for i, id in ipairs(self._hed.spawn_instigator_ids) do
		if not alive(all_units[id]) then
			table.remove(self._hed.spawn_instigator_ids, i)
		end
	end
end
function SpecialObjectiveUnitElement:_draw_follow_up(selected_unit, all_units)
	if self._hed.follow_up_id then
		local unit = all_units[self._hed.follow_up_id]
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
function SpecialObjectiveUnitElement:update_editing()
	self:_so_raycast()
	self:_spawn_raycast()
	self:_raycast()
end
function SpecialObjectiveUnitElement:_so_raycast()
	local ray = managers.editor:unit_by_raycast({mask = 10, ray_type = "editor"})
	if ray and ray.unit and string.find(ray.unit:name():s(), "point_special_objective", 1, true) then
		local id = ray.unit:unit_data().unit_id
		Application:draw(ray.unit, 0, 1, 0)
		return id
	end
	return nil
end
function SpecialObjectiveUnitElement:_spawn_raycast()
	local ray = managers.editor:unit_by_raycast({mask = 10, ray_type = "editor"})
	if not ray or not ray.unit then
		return
	end
	local id
	if string.find(ray.unit:name():s(), "ai_enemy_group", 1, true) or string.find(ray.unit:name():s(), "ai_spawn_enemy", 1, true) or string.find(ray.unit:name():s(), "ai_civilian_group", 1, true) or string.find(ray.unit:name():s(), "ai_spawn_civilian", 1, true) then
		id = ray.unit:unit_data().unit_id
		Application:draw(ray.unit, 0, 0, 1)
	end
	return id
end
function SpecialObjectiveUnitElement:_raycast()
	local from = managers.editor:get_cursor_look_point(0)
	local to = managers.editor:get_cursor_look_point(100000)
	local ray = World:raycast(from, to, nil, managers.slot:get_mask("all"))
	if ray and ray.position then
		Application:draw_sphere(ray.position, 10, 1, 1, 1)
		return ray.position
	end
	return nil
end
function SpecialObjectiveUnitElement:_lmb()
	local id = self:_so_raycast()
	if id then
		if self._hed.follow_up_id == id then
			self._hed.follow_up_id = nil
		else
			self._hed.follow_up_id = id
		end
		return
	end
	local id = self:_spawn_raycast()
	if id then
		for i, si_id in ipairs(self._hed.spawn_instigator_ids) do
			if si_id == id then
				table.remove(self._hed.spawn_instigator_ids, i)
				return
			end
		end
		table.insert(self._hed.spawn_instigator_ids, id)
		return
	end
	self._hed.search_position = self:_raycast() or self._hed.search_position
end
function SpecialObjectiveUnitElement:add_triggers(vc)
	vc:add_trigger(Idstring("lmb"), callback(self, self, "_lmb"))
end
function SpecialObjectiveUnitElement:selected()
	SpecialObjectiveUnitElement.super.selected(self)
	if not managers.ai_data:patrol_path(self._hed.patrol_path) then
		self._hed.patrol_path = "none"
	end
	CoreEws.update_combobox_options(self._patrol_path_params, managers.ai_data:patrol_path_names())
	CoreEws.change_combobox_value(self._patrol_path_params, self._hed.patrol_path)
end
function SpecialObjectiveUnitElement:_apply_preset(params)
	local value = params.ctrlr:get_value()
	local confirm = EWS:message_box(Global.frame_panel, "Apply preset " .. value .. "?", "Special objective", "YES_NO,ICON_QUESTION", Vector3(-1, -1, 0))
	if confirm == "NO" then
		return
	end
	if value == "clear" then
		self:_clear_all_nav_link_filters()
	elseif value == "all" then
		self:_enable_all_nav_link_filters()
	else
		print("Didn't have preset", value, "yet.")
	end
end
function SpecialObjectiveUnitElement:_enable_all_nav_link_filters()
	for name, ctrlr in pairs(self._nav_link_filter_check_boxes) do
		ctrlr:set_value(true)
		self:_toggle_nav_link_filter_value({ctrlr = ctrlr, name = name})
	end
end
function SpecialObjectiveUnitElement:_clear_all_nav_link_filters()
	for name, ctrlr in pairs(self._nav_link_filter_check_boxes) do
		ctrlr:set_value(false)
		self:_toggle_nav_link_filter_value({ctrlr = ctrlr, name = name})
	end
end
function SpecialObjectiveUnitElement:_toggle_nav_link_filter_value(params)
	local value = params.ctrlr:get_value()
	if value then
		table.insert(self._nav_link_filter, params.name)
	else
		table.delete(self._nav_link_filter, params.name)
	end
	self._hed.SO_access = tostring(managers.navigation:convert_SO_access_filter(self._nav_link_filter))
end
function SpecialObjectiveUnitElement:select_action_btn()
	local dialog = SelectNameModal:new("Select action", ElementSpawnEnemyDummy._spawn_actions)
	if dialog:cancelled() then
		return
	end
	for _, action in ipairs(dialog:_selected_item_assets()) do
		self._hed.so_action = action
		CoreEws.change_combobox_value(self._so_action_params, self._hed.so_action)
	end
end
function SpecialObjectiveUnitElement:_build_panel(panel, panel_sizer)
	self:_create_panel()
	panel = panel or self._panel
	panel_sizer = panel_sizer or self._panel_sizer
	if self._hed.navigation_link and self._hed.navigation_link ~= -1 and tonumber(self._hed.SO_access) == 0 then
		self._hed.SO_access = tostring(managers.navigation:convert_nav_link_maneuverability_to_SO_access(self._hed.navigation_link))
	end
	if self._hed.navigation_link and self._hed.navigation_link ~= -1 and not self._hed.is_navigation_link then
		self._hed.is_navigation_link = true
	end
	self._nav_link_filter = managers.navigation:convert_SO_access_filter(tonumber(self._hed.SO_access))
	local opt_sizer = EWS:StaticBoxSizer(panel, "VERTICAL", "Filter")
	local filter_preset_params = {
		name = "Preset:",
		panel = panel,
		sizer = opt_sizer,
		options = {"clear", "all"},
		tooltip = "Select a preset.",
		name_proportions = 1,
		ctrlr_proportions = 2,
		sorted = true
	}
	local filter_preset = CoreEWS.combobox(filter_preset_params)
	filter_preset:connect("EVT_COMMAND_COMBOBOX_SELECTED", callback(self, self, "_apply_preset"), {ctrlr = filter_preset})
	local filter_sizer = EWS:BoxSizer("HORIZONTAL")
	local opt1_sizer = EWS:BoxSizer("VERTICAL")
	local opt2_sizer = EWS:BoxSizer("VERTICAL")
	local opt3_sizer = EWS:BoxSizer("VERTICAL")
	local opt = NavigationManager.ACCESS_FLAGS
	for i, o in ipairs(opt) do
		local check = EWS:CheckBox(panel, o, "")
		check:set_value(table.contains(self._nav_link_filter, o))
		check:connect("EVT_COMMAND_CHECKBOX_CLICKED", callback(self, self, "_toggle_nav_link_filter_value"), {ctrlr = check, name = o})
		self._nav_link_filter_check_boxes[o] = check
		if i <= math.round(#opt / 3) then
			opt1_sizer:add(check, 0, 0, "EXPAND")
		elseif i <= math.round(#opt / 3) * 2 then
			opt2_sizer:add(check, 0, 0, "EXPAND")
		else
			opt3_sizer:add(check, 0, 0, "EXPAND")
		end
	end
	filter_sizer:add(opt1_sizer, 1, 0, "EXPAND")
	filter_sizer:add(opt2_sizer, 1, 0, "EXPAND")
	filter_sizer:add(opt3_sizer, 1, 0, "EXPAND")
	opt_sizer:add(filter_sizer, 1, 0, "EXPAND")
	panel_sizer:add(opt_sizer, 0, 0, "EXPAND")
	local ai_group_params = {
		name = "AI group:",
		panel = panel,
		sizer = panel_sizer,
		options = {
			"enemies",
			"friendlies",
			"civilians",
			"bank_manager_old_man",
			"escort_guy_1",
			"escort_guy_2",
			"escort_guy_3",
			"escort_guy_4",
			"escort_guy_5",
			"chavez"
		},
		value = self._hed.ai_group,
		tooltip = "Select an ai group.",
		name_proportions = 1,
		ctrlr_proportions = 2,
		sorted = true
	}
	local ai_group = CoreEWS.combobox(ai_group_params)
	ai_group:connect("EVT_COMMAND_COMBOBOX_SELECTED", callback(self, self, "set_element_data"), {ctrlr = ai_group, value = "ai_group"})
	local is_navigation_link = EWS:CheckBox(panel, "Navigation link", "")
	is_navigation_link:set_value(self._hed.is_navigation_link)
	is_navigation_link:connect("EVT_COMMAND_CHECKBOX_CLICKED", callback(self, self, "set_element_data"), {
		ctrlr = is_navigation_link,
		value = "is_navigation_link"
	})
	panel_sizer:add(is_navigation_link, 0, 0, "EXPAND")
	local align_rotation = EWS:CheckBox(panel, "Align rotation", "")
	align_rotation:set_value(self._hed.align_rotation)
	align_rotation:connect("EVT_COMMAND_CHECKBOX_CLICKED", callback(self, self, "set_element_data"), {
		ctrlr = align_rotation,
		value = "align_rotation"
	})
	panel_sizer:add(align_rotation, 0, 0, "EXPAND")
	local align_position = EWS:CheckBox(panel, "Align position", "")
	align_position:set_value(self._hed.align_position)
	align_position:connect("EVT_COMMAND_CHECKBOX_CLICKED", callback(self, self, "set_element_data"), {
		ctrlr = align_position,
		value = "align_position"
	})
	panel_sizer:add(align_position, 0, 0, "EXPAND")
	local repeatable = EWS:CheckBox(panel, "Repeatable", "")
	repeatable:set_value(self._hed.repeatable)
	repeatable:connect("EVT_COMMAND_CHECKBOX_CLICKED", callback(self, self, "set_element_data"), {ctrlr = repeatable, value = "repeatable"})
	panel_sizer:add(repeatable, 0, 0, "EXPAND")
	local use_instigator = EWS:CheckBox(panel, "Use instigator", "")
	use_instigator:set_value(self._hed.use_instigator)
	use_instigator:connect("EVT_COMMAND_CHECKBOX_CLICKED", callback(self, self, "set_element_data"), {
		ctrlr = use_instigator,
		value = "use_instigator"
	})
	panel_sizer:add(use_instigator, 0, 0, "EXPAND")
	local idle_scan = EWS:CheckBox(panel, "Idle scan", "")
	idle_scan:set_value(self._hed.scan)
	idle_scan:connect("EVT_COMMAND_CHECKBOX_CLICKED", callback(self, self, "set_element_data"), {ctrlr = idle_scan, value = "scan"})
	panel_sizer:add(idle_scan, 0, 0, "EXPAND")
	local search_distance_params = {
		name = "Search distance:",
		panel = panel,
		sizer = panel_sizer,
		value = self._hed.search_distance,
		floats = 0,
		tooltip = "Used to specify the distance to use when searching for an AI",
		min = 0,
		name_proportions = 1,
		ctrlr_proportions = 2
	}
	local search_distance = CoreEws.number_controller(search_distance_params)
	search_distance:connect("EVT_COMMAND_TEXT_ENTER", callback(self, self, "set_element_data"), {
		ctrlr = search_distance,
		value = "search_distance"
	})
	search_distance:connect("EVT_KILL_FOCUS", callback(self, self, "set_element_data"), {
		ctrlr = search_distance,
		value = "search_distance"
	})
	local action_sizer = EWS:BoxSizer("HORIZONTAL")
	panel_sizer:add(action_sizer, 0, 1, "EXPAND,LEFT")
	local so_action_params = {
		name = "Action:",
		panel = panel,
		sizer = action_sizer,
		options = clone(ElementSpawnEnemyDummy._spawn_actions),
		value = self._hed.so_action,
		default = "none",
		tooltip = "Select a action that the unit should start with.",
		name_proportions = 1,
		ctrlr_proportions = 2,
		sizer_proportions = 1,
		sorted = true
	}
	for _, val in ipairs(self._AI_SO_types) do
		table.insert(so_action_params.options, val)
	end
	local so_action = CoreEws.combobox(so_action_params)
	self._so_action_params = so_action_params
	so_action:connect("EVT_COMMAND_COMBOBOX_SELECTED", callback(self, self, "set_element_data"), {ctrlr = so_action, value = "so_action"})
	local toolbar = EWS:ToolBar(panel, "", "TB_FLAT,TB_NODIVIDER")
	toolbar:add_tool("SELECT", "Select action", CoreEws.image_path("world_editor\\unit_by_name_list.png"), nil)
	toolbar:connect("SELECT", "EVT_COMMAND_MENU_SELECTED", callback(self, self, "select_action_btn"), nil)
	toolbar:realize()
	action_sizer:add(toolbar, 0, 1, "EXPAND,LEFT")
	self._patrol_path_params = {
		name = "Patrol path:",
		panel = panel,
		sizer = panel_sizer,
		options = managers.ai_data:patrol_path_names(),
		value = self._hed.patrol_path,
		default = "none",
		tooltip = "Select a patrol path to use from the spawn point. Different objectives and behaviors will interpet the path different.",
		name_proportions = 1,
		ctrlr_proportions = 2,
		sorted = true
	}
	local patrol_path = CoreEws.combobox(self._patrol_path_params)
	patrol_path:connect("EVT_COMMAND_COMBOBOX_SELECTED", callback(self, self, "set_element_data"), {
		ctrlr = patrol_path,
		value = "patrol_path"
	})
	local path_style_params = {
		name = "Path style:",
		panel = panel,
		sizer = panel_sizer,
		options = clone(ElementSpecialObjective._pathing_types),
		value = self._hed.path_style,
		tooltip = "Specifies how the patrol path should be used.",
		name_proportions = 1,
		ctrlr_proportions = 2,
		sorted = true
	}
	local path_style = CoreEws.combobox(path_style_params)
	path_style:connect("EVT_COMMAND_COMBOBOX_SELECTED", callback(self, self, "set_element_data"), {ctrlr = path_style, value = "path_style"})
	local path_haste_params = {
		name = "Path haste:",
		panel = panel,
		sizer = panel_sizer,
		options = {"walk", "run"},
		value = self._hed.path_haste,
		default = "none",
		tooltip = "Select path haste to use.",
		name_proportions = 1,
		ctrlr_proportions = 2,
		sorted = true
	}
	local path_haste = CoreEws.combobox(path_haste_params)
	path_haste:connect("EVT_COMMAND_COMBOBOX_SELECTED", callback(self, self, "set_element_data"), {ctrlr = path_haste, value = "path_haste"})
	local path_stance_params = {
		name = "Path stance:",
		panel = panel,
		sizer = panel_sizer,
		options = {
			"ntl",
			"hos",
			"cbt"
		},
		value = self._hed.path_stance,
		default = "none",
		tooltip = "Select path stance to use.",
		name_proportions = 1,
		ctrlr_proportions = 2,
		sorted = true
	}
	local path_stance = CoreEws.combobox(path_stance_params)
	path_stance:connect("EVT_COMMAND_COMBOBOX_SELECTED", callback(self, self, "set_element_data"), {
		ctrlr = path_stance,
		value = "path_stance"
	})
	local pose_params = {
		name = "Pose:",
		panel = panel,
		sizer = panel_sizer,
		options = {"crouch", "stand"},
		value = self._hed.pose,
		default = "none",
		tooltip = "Select path stance to use.",
		name_proportions = 1,
		ctrlr_proportions = 2,
		sorted = true
	}
	local pose = CoreEws.combobox(pose_params)
	pose:connect("EVT_COMMAND_COMBOBOX_SELECTED", callback(self, self, "set_element_data"), {ctrlr = pose, value = "pose"})
	local interrupt_on_params = {
		name = "Interrupt:",
		panel = panel,
		sizer = panel_sizer,
		options = {"obstructed", "contact"},
		value = self._hed.interrupt_on,
		default = "none",
		tooltip = "Select interrupt condition.",
		name_proportions = 1,
		ctrlr_proportions = 2,
		sorted = true
	}
	local interrupt_on = CoreEws.combobox(interrupt_on_params)
	interrupt_on:connect("EVT_COMMAND_COMBOBOX_SELECTED", callback(self, self, "set_element_data"), {
		ctrlr = interrupt_on,
		value = "interrupt_on"
	})
	local attitude_params = {
		name = "Attitude:",
		panel = panel,
		sizer = panel_sizer,
		options = {"avoid", "engage"},
		value = self._hed.attitude,
		default = "none",
		tooltip = "Select combat attitude.",
		name_proportions = 1,
		ctrlr_proportions = 2,
		sorted = true
	}
	local attitude = CoreEws.combobox(attitude_params)
	attitude:connect("EVT_COMMAND_COMBOBOX_SELECTED", callback(self, self, "set_element_data"), {ctrlr = attitude, value = "attitude"})
	local trigger_on_params = {
		name = "Trigger on:",
		panel = panel,
		sizer = panel_sizer,
		options = {"none", "interact"},
		value = self._hed.trigger_on,
		tooltip = "Select when to trigger objective.",
		name_proportions = 1,
		ctrlr_proportions = 2
	}
	local trigger_on = CoreEws.combobox(trigger_on_params)
	trigger_on:connect("EVT_COMMAND_COMBOBOX_SELECTED", callback(self, self, "set_element_data"), {ctrlr = trigger_on, value = "trigger_on"})
	local interaction_voice_params = {
		name = "Interaction voice:",
		panel = panel,
		sizer = panel_sizer,
		options = {
			"default",
			"cuff_cop",
			"down_cop",
			"stop_cop",
			"escort_keep",
			"escort_go",
			"escort",
			"stop",
			"down_stay",
			"down",
			"bridge_codeword",
			"bridge_chair",
			"undercover_interrogate"
		},
		value = self._hed.interaction_voice,
		tooltip = "Select what voice to use when interacting with the character.",
		name_proportions = 1,
		ctrlr_proportions = 2
	}
	local interaction_voice = CoreEws.combobox(interaction_voice_params)
	interaction_voice:connect("EVT_COMMAND_COMBOBOX_SELECTED", callback(self, self, "set_element_data"), {
		ctrlr = interaction_voice,
		value = "interaction_voice"
	})
	local interval_params = {
		name = "Interval:",
		panel = panel,
		sizer = panel_sizer,
		value = self._hed.interval,
		floats = 2,
		tooltip = "Used to specify how often the SO should search for an actor. A negative value means it will check only once.",
		min = -1,
		name_proportions = 1,
		ctrlr_proportions = 2
	}
	local interval = CoreEws.number_controller(interval_params)
	interval:connect("EVT_COMMAND_TEXT_ENTER", callback(self, self, "set_element_data"), {ctrlr = interval, value = "interval"})
	interval:connect("EVT_KILL_FOCUS", callback(self, self, "set_element_data"), {ctrlr = interval, value = "interval"})
	local base_chance_params = {
		name = "Base chance:",
		panel = panel,
		sizer = panel_sizer,
		value = self._hed.base_chance,
		floats = 2,
		tooltip = "Used to specify chance to happen (1==absolutely!)",
		min = 0,
		max = 1,
		name_proportions = 1,
		ctrlr_proportions = 2
	}
	local base_chance = CoreEws.number_controller(base_chance_params)
	base_chance:connect("EVT_COMMAND_TEXT_ENTER", callback(self, self, "set_element_data"), {
		ctrlr = base_chance,
		value = "base_chance"
	})
	base_chance:connect("EVT_KILL_FOCUS", callback(self, self, "set_element_data"), {
		ctrlr = base_chance,
		value = "base_chance"
	})
	local chance_inc_params = {
		name = "Chance incremental:",
		panel = panel,
		sizer = panel_sizer,
		value = self._hed.chance_inc,
		floats = 2,
		tooltip = "Used to specify an incremental chance to happen",
		min = 0,
		max = 1,
		name_proportions = 1,
		ctrlr_proportions = 2
	}
	local chance_inc = CoreEws.number_controller(chance_inc_params)
	chance_inc:connect("EVT_COMMAND_TEXT_ENTER", callback(self, self, "set_element_data"), {ctrlr = chance_inc, value = "chance_inc"})
	chance_inc:connect("EVT_KILL_FOCUS", callback(self, self, "set_element_data"), {ctrlr = chance_inc, value = "chance_inc"})
end
function SpecialObjectiveUnitElement:add_to_mission_package()
end
