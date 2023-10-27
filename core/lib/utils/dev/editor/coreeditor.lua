core:import("CoreWorldCameraLayer")
core:import("CoreBrushLayer")
core:import("CoreWireLayer")
core:import("CorePortalLayer")
core:import("CoreEnvironmentLayer")
core:import("CoreSoundLayer")
core:import("CoreStaticsLayer")
core:import("CoreDynamicsLayer")
core:import("CoreMissionLayer")
core:import("CoreAiLayer")
core:import("CoreLevelSettingsLayer")
core:import("CoreEngineAccess")
core:import("CoreInput")
core:import("CoreEditorUtils")
core:import("CoreEditorSave")
require("core/lib/utils/dev/editor/ews_classes/CoreEditorEwsClasses")
require("core/lib/utils/dev/editor/ews_classes/UnitByName")
require("core/lib/utils/dev/editor/ews_classes/SelectByName")
require("core/lib/utils/dev/editor/ews_classes/SelectUnitByNameModal")
require("core/lib/utils/dev/editor/ews_classes/SelectGroupByName")
require("core/lib/utils/dev/editor/ews_classes/SelectWorkView")
require("core/lib/utils/dev/editor/ews_classes/MissionElementTimeline")
require("core/lib/utils/dev/editor/ews_classes/EditUnitDialog")
require("core/lib/utils/dev/editor/ews_classes/EditLight")
require("core/lib/utils/dev/editor/ews_classes/EditTriggable")
require("core/lib/utils/dev/editor/ews_classes/EditSettings")
require("core/lib/utils/dev/editor/ews_classes/EditVariation")
require("core/lib/utils/dev/editor/ews_classes/EditEditableGui")
require("core/lib/utils/dev/editor/ews_classes/Continents")
require("core/lib/utils/dev/editor/ews_classes/UnhideByName")
require("core/lib/utils/dev/editor/ews_classes/CreateWorldSettingFile")
require("core/lib/utils/dev/editor/ews_classes/SelectNameModal")
require("core/lib/utils/dev/SettingsHandling")
require("core/lib/units/editor/CoreMissionElement")
require("core/lib/units/data/CoreMissionElementData")
require("core/lib/units/editor/mission/CoreArea")
require("core/lib/units/editor/mission/CoreAreaTrigger")
require("core/lib/units/editor/mission/CoreWorldCamera")
require("core/lib/units/editor/mission/CoreWorldCameraTrigger")
require("core/lib/units/editor/mission/CoreCounter")
require("core/lib/units/editor/mission/CoreCounterReset")
require("core/lib/units/editor/mission/CoreToggle")
require("core/lib/units/editor/mission/CorePlayEffect")
require("core/lib/units/editor/mission/CorePhysicsPush")
require("core/lib/units/editor/mission/CoreSpawnUnit")
require("core/lib/units/editor/mission/CoreActivateScript")
require("core/lib/units/editor/mission/CoreUnitSequence")
require("core/lib/units/editor/mission/CoreUnitSequenceTrigger")
require("core/lib/units/editor/mission/CoreMusic")
require("core/lib/units/editor/mission/CoreOperator")
require("core/lib/units/editor/mission/CoreOverlayEffect")
require("core/lib/units/editor/mission/CorePlaySound")
require("core/lib/units/editor/mission/CoreExecuteInOtherMission")
require("core/lib/units/editor/mission/CoreLogicChance")
require("core/lib/units/editor/mission/CoreRandom")
require("core/lib/units/editor/mission/CoreGlobalEventTriggerUnitElement")
require("core/lib/units/editor/mission/CoreTimer")
require("core/lib/units/editor/CoreDebug")
CoreEditor = CoreEditor or class()
require("core/lib/utils/dev/editor/CoreEditorMenubar")
require("core/lib/utils/dev/editor/CoreEditorToolbar")
require("core/lib/utils/dev/editor/CoreEditorConfiguration")
require("core/lib/utils/dev/editor/CoreEditorMarkers")
require("core/lib/utils/dev/editor/CoreEditorLeftToolbars")
require("core/lib/utils/dev/editor/CoreEditorEditGui")
require("core/lib/utils/dev/editor/CoreEditorLowerPanel")
require("core/lib/utils/dev/editor/CoreEditorGroups")
require("core/lib/utils/dev/editor/CoreEditorCubeMap")
require("core/lib/utils/dev/editor/utils/CoreFCCEditorController")
function CoreEditor:init(game_state_machine, session_state)
	assert(game_state_machine)
	self._gsm = game_state_machine
	self._session_state = session_state
	World:get_object(Idstring("ref")):set_visibility(false)
	self._WORKING_ON_CONTINENTS = true
	self._skipped_freeflight_frames = 1
	self._editor_name = "Bringer of Worlds"
	self._max_id = 0
	self._STEP_ID = 1
	self._unit_ids = {}
	self._gui_id = 0
	self._triggers_added = false
	self._enabled = false
	self._confirm_on_new = true
	self._continents = {}
	self._current_continent = nil
	self._world_holder = WorldHolder:new({})
	self:_load_packages()
	self:_init_viewport()
	self:_init_listener()
	self:_init_mute()
	self:_init_gui()
	self:_init_editor_data()
	self:_init_groups()
	CoreEditorUtils.parse_layer_types()
	self:_init_layer_classes()
	self:_init_controller()
	self:_clear_values()
	self:_init_configuration_values()
	self:_init_head_lamp()
	self._special_units = {}
	self._ews_triggers = {}
	self._dialogs = {}
	self._dialogs_settings = {}
	self._news_version = 0
	self._show_markers = false
	self._show_camera_position = true
	self._show_center = true
	self._draw_occluders = false
	self._draw_bodies_on = false
	self._simulation_debug_areas = false
	self._simulation_world_setting_path = nil
	self._hidden_units = {}
	self._draw_hidden_units = false
	self._layer_replace_dialogs = {}
	self._markers = {}
	self._recent_files_limit = 10
	self._recent_files = {}
	self:_init_slot_masks()
	self:_init_layer_values()
	self:_init_edit_setting_values()
	self:_replace_unit_categories()
	self:_init_paths()
	self:_load_editor_settings()
	self:_load_configuration()
	self:_load_edit_setting_values()
	self:_init_mission_difficulties()
	self:_init_mission_players()
	self:_init_mission_platforms()
	self:_init_title_messages()
	self:_init_edit_unit_dialog()
end
function CoreEditor:_load_packages()
	if not PackageManager:loaded("core/packages/editor") then
		PackageManager:load("core/packages/editor")
	end
end
function CoreEditor:_init_viewport()
	self._camera_fov = 75
	self._camera_near_range = 20
	self._camera_far_range = 250000
	local camera = World:create_camera()
	camera:set_near_range(self._camera_near_range)
	camera:set_far_range(self._camera_far_range)
	camera:set_fov(self._camera_fov)
	camera:set_position(Vector3(0, 0, 220))
	self._vp = managers.viewport:new_vp(0, 0, 1, 1)
	self._vp:set_camera(camera)
	self._default_post_processor_effect = Idstring("empty")
end
function CoreEditor:_init_listener()
	self._listener_id = managers.listener:add_listener("editor", self._vp:camera(), self._vp:camera(), nil, true)
	self._activate_listener_id = nil
	managers.listener:add_set("editor", {"editor"})
	self._listener_always_enabled = false
	self._sound_check_object = managers.sound_environment:add_check_object({
		object = self:camera(),
		active = true,
		primary = true
	})
end
function CoreEditor:_init_mute()
	self._mute_source = SoundDevice:create_source("editor_mute")
	self._mute_states = {wanted = true, current = false}
end
function CoreEditor:_init_gui()
	self._workspace = Overlay:newgui():create_screen_workspace()
	self._workspace:set_timer(TimerManager:main())
	self._gui = self._workspace:panel():gui(Idstring("core/guis/core_editor"))
end
function CoreEditor:_init_editor_data()
	self._editor_data = {}
	self._editor_data.keyboard_available = true
	self._editor_data.virtual_controller = Input:create_virtual_controller("editor_layer")
end
function CoreEditor:_init_groups()
	self._using_groups = false
	self._debug_draw_groups = false
	self._groups = CoreEditorGroups:new()
end
function CoreEditor:_init_layer_classes()
	self._layers = {}
	self._current_layer = nil
	self._mission_layer_name = "Mission"
	self:add_layer("Brush", CoreBrushLayer.BrushLayer)
	self:add_layer("Sound", CoreSoundLayer.SoundLayer)
	self:add_layer("Mission", CoreMissionLayer.MissionLayer)
	self:add_layer("Environment", CoreEnvironmentLayer.EnvironmentLayer)
	self:add_layer("WorldCamera", CoreWorldCameraLayer.WorldCameraLayer)
	self:add_layer("Portals", CorePortalLayer.PortalLayer)
	self:add_layer("Wires", CoreWireLayer.WireLayer)
	self:add_layer("Statics", CoreStaticsLayer.StaticsLayer)
	self:add_layer("Dynamics", CoreDynamicsLayer.DynamicsLayer)
	self:add_layer("Level Settings", CoreLevelSettingsLayer.LevelSettingsLayer)
	self:_project_init_layer_classes()
end
function CoreEditor:_project_init_layer_classes()
end
function CoreEditor:_clear_values()
	self._values = {}
	self._values.world = {}
	self._values.world.workviews = {}
end
function CoreEditor:_init_configuration_values()
	self._autosave_time = 5
	self._autosave_timer = 0
	self._notes = "Hail to the King!"
	self._invert_move_shift = false
	self._always_global_select_unit = false
	self._use_timestamp = false
	self._reset_camera_on_new = false
	self._dialogs_stay_on_top = false
	self._save_edit_setting_values = false
	self._save_dialog_states = false
	self._use_edit_light_dialog = false
end
function CoreEditor:_init_slot_masks()
	self._surface_move_mask = managers.slot:get_mask("surface_move")
	self._portal_units_mask = World:make_slot_mask(1, 11, 38)
	self._go_through_units_before_simulaton_mask = World:make_slot_mask(1, 11, 17, 19, 32, 36, 38)
	self:_project_init_slot_masks()
end
function CoreEditor:_project_init_slot_masks()
end
function CoreEditor:_init_layer_values()
	self._coordinate_systems = {"Local", "World"}
	self._coordinate_system = "Local"
	self._grid_sizes = {
		1,
		25,
		50,
		100,
		250,
		500,
		1000,
		2000,
		10000
	}
	self._grid_size = self._grid_sizes[5]
	self._snap_rotations = {
		1,
		2,
		5,
		10,
		15,
		30,
		45,
		60,
		90,
		180
	}
	self._snap_rotation = self._snap_rotations[7]
	self._snap_rotation_axis = "z"
	self._rotation_speed = 35
	self._use_surface_move = false
	self._use_snappoints = false
	self._layer_draw_grid = true
	self._layer_draw_marker = true
	self._grid_altitude = 0
end
function CoreEditor:_init_edit_setting_values()
	self._edit_setting_values = {}
	table.insert(self._edit_setting_values, "_coordinate_system")
	table.insert(self._edit_setting_values, "_grid_size")
	table.insert(self._edit_setting_values, "_snap_rotation")
	table.insert(self._edit_setting_values, "_snap_rotation_axis")
	table.insert(self._edit_setting_values, "_rotation_speed")
	table.insert(self._edit_setting_values, "_use_surface_move")
	table.insert(self._edit_setting_values, "_use_snappoints")
end
function CoreEditor:_replace_unit_categories()
	self._replace_unit_categories = {
		"none",
		"mission_element"
	}
	self:_populate_replace_unit_categories_from_layer_types()
end
function CoreEditor:_init_paths()
	self._lastdir = "levels\\"
	self._version_path = "lib/utils/dev/editor/xml/version"
	self._configuration_path = "lib/utils/dev/editor/xml/editor_configuration"
	self._edit_setting_values_path = "lib/utils/dev/editor/xml/editor_edit_setting_values"
	self._layout_path = "lib/utils/dev/editor/xml/editor_layout"
	self._editor_settings_path = "lib/utils/dev/editor/xml/editor"
	self._group_presets_path = managers.database:base_path() .. "levels\\groups"
	self._editor_temp_path = managers.database:root_path() .. "assets\\core\\temp\\editor_temp"
	self._simulation_path = managers.database:root_path() .. "assets\\core\\temp\\editor_temp\\simulation"
	self._simulation_cube_lights_path = managers.database:root_path() .. "assets\\core\\temp\\editor_temp\\simulation\\cube_lights"
	if not SystemFS:exists(self._editor_temp_path) then
		SystemFS:make_dir(self._editor_temp_path)
	end
	if not SystemFS:exists(self._simulation_path) then
		SystemFS:make_dir(self._simulation_path)
	end
	if not SystemFS:exists(self._simulation_cube_lights_path) then
		SystemFS:make_dir(self._simulation_cube_lights_path)
	end
end
function CoreEditor:_init_mission_difficulties()
	self._mission_difficulties = {
		"easy",
		"medium",
		"hard"
	}
	self._mission_difficulty = "medium"
end
function CoreEditor:_init_mission_players()
	self._mission_players = {1}
	self._mission_player = 1
end
function CoreEditor:_init_mission_platforms()
	self._mission_platforms = {"WIN32", "PS3"}
	self._mission_platform = "WIN32"
end
function CoreEditor:_init_title_messages()
	self._title_messages = {}
	self:add_title_message("Ask yourself, is this good for the company? ")
	self:add_title_message("Hatarakazaru mono, kuu bekarazu. ")
	self:add_title_message("Those who do not work, should not eat. ")
	self:add_title_message("Don't waste you time or time will waste you. ")
	self:add_title_message("Fill your head with rock. ")
end
function CoreEditor:_init_edit_unit_dialog()
	self:show_dialog("edit_unit", "EditUnitDialog")
	EditUnitLight:new(self)
	EditUnitTriggable:new(self)
	EditUnitVariation:new(self)
	EditUnitEditableGui:new(self)
	EditUnitSettings:new(self)
end
function CoreEditor:_populate_replace_unit_categories_from_layer_types()
	for layer_name, types in pairs(CoreEditorUtils.get_layer_types()) do
		for _, name in ipairs(types) do
			table.insert(self._replace_unit_categories, name)
		end
	end
end
function CoreEditor:_init_head_lamp()
	self._light = World:create_light("omni|specular")
	self._light:set_far_range(20000)
	self._light:set_color(Vector3(1, 1, 1))
	self._light:set_multiplier(LightIntensityDB:lookup(Idstring("identity")))
	self._light:set_enable(false)
end
function CoreEditor:add_title_message(msg)
	table.insert(self._title_messages, msg)
end
function CoreEditor:add_layer(name, layer_class)
	if self._layers[name] then
		Application:throw_exception("[CoreEditor] Layer referens named " .. name .. " already added. (Probably because Statics and Dynamics have been moved from project to Core. Remove project added layer from project WorldEditor)")
	end
	self._layers[name] = layer_class:new(self)
end
function CoreEditor:check_news(file, devices)
	self._world_editor_news = WorldEditorNews:new()
	if DB:has("editor_version", self._version_path) then
		local file = DB:open("editor_version", self._version_path)
		local versions = ScriptSerializer:from_generic_xml(file:read())
		self._news_version = versions.news
	end
	if self._news_version >= self._world_editor_news:version() then
		self._world_editor_news:set_visible(false)
	else
		self._news_version = self._world_editor_news:version()
		local f = SystemFS:open(managers.database:base_path() .. self._version_path .. ".editor_version", "w")
		f:puts(ScriptSerializer:to_generic_xml({
			news = self._news_version
		}))
		SystemFS:close(f)
	end
end
function CoreEditor:ctrl_bindings()
	return self._ctrl_bindings
end
function CoreEditor:ctrl_layer_bindings()
	return self._ctrl_layer_bindings
end
function CoreEditor:ctrl_menu_bindings()
	return self._ctrl_menu_bindings
end
function CoreEditor:ctrl_binding(name)
	return self._ctrl_bindings[name] or ""
end
function CoreEditor:ctrl_layer_binding(name)
	return self._ctrl_layer_bindings[name] or ""
end
function CoreEditor:ctrl_menu_binding(name)
	return self._ctrl_menu_bindings[name] or ""
end
function CoreEditor:_parse_controller_file(file, devices)
	if DB:has("controller", file) then
		local controllers = DB:load_node("controller", file)
		for controller in controllers:children() do
			for button in controller:children() do
				if controller:name() == "base" then
					self._bindings[button:name()] = {
						device = devices[button:parameter("device")],
						key = button:parameter("shortkey")
					}
				elseif controller:name() == "layer" then
					self._layer_bindings[button:name()] = {
						device = devices[button:parameter("device")],
						key = button:parameter("shortkey")
					}
				elseif controller:name() == "menu" then
					self._menu_bindings[button:name()] = {
						key = button:parameter("shortkey")
					}
				end
			end
		end
	end
end
function CoreEditor:_init_controller()
	local mouse = Input:mouse()
	local kb = Input:keyboard()
	local devices = {keyboard = kb, mouse = mouse}
	self._ctrl = Input:create_virtual_controller("editor")
	local ctrl_layer = self._editor_data.virtual_controller
	self._bindings = {}
	self._layer_bindings = {}
	self._menu_bindings = {}
	self:_parse_controller_file("core/lib/utils/dev/editor/xml/default_controller", devices)
	self:_parse_controller_file("lib/utils/dev/editor/xml/project_controller", devices)
	self:_parse_controller_file("lib/utils/dev/editor/xml/custom_controller", devices)
	self._ctrl_bindings = {}
	self._ctrl_layer_bindings = {}
	self._ctrl_menu_bindings = {}
	for name, data in pairs(self._bindings) do
		self._ctrl:connect(data.device, Idstring(data.key), Idstring(name))
		self._ctrl_bindings[name] = data.key
	end
	for name, data in pairs(self._layer_bindings) do
		ctrl_layer:connect(data.device, Idstring(data.key), Idstring(name))
		self._ctrl_layer_bindings[name] = data.key
	end
	for name, data in pairs(self._menu_bindings) do
		self._ctrl_menu_bindings[name] = data.key
	end
	self._bindings = nil
	self._layer_bindings = nil
	ctrl_layer:connect(mouse, Idstring("0"), Idstring("lmb"))
	ctrl_layer:connect(mouse, Idstring("1"), Idstring("rmb"))
	ctrl_layer:connect(mouse, Idstring("2"), Idstring("mmb"))
	ctrl_layer:connect(mouse, Idstring("3"), Idstring("emb"))
	ctrl_layer:connect(kb, Idstring("enter"), Idstring("enter"))
	ctrl_layer:connect(kb, Idstring("backspace"), Idstring("back"))
	ctrl_layer:connect(kb, Idstring("insert"), Idstring("insert"))
	ctrl_layer:connect(kb, Idstring("num +"), Idstring("increase"))
	ctrl_layer:connect(kb, Idstring("num -"), Idstring("decrease"))
	ctrl_layer:connect(kb, Idstring("home"), Idstring("home"))
	ctrl_layer:connect(kb, Idstring("end"), Idstring("end"))
	self._ctrl:connect(kb, Idstring("tab"), Idstring("tab"))
	self._ctrl:connect(kb, Idstring("esc"), Idstring("esc"))
	self._ctrl:connect(kb, Idstring("space"), Idstring("toggle_mixed_input_mode"))
	self._ctrl:connect(kb, Idstring("z"), Idstring("undo"))
	self._ctrl:connect(mouse, Idstring("0"), Idstring("lmb"))
	self._ctrl:connect(mouse, Idstring("mouse"), Idstring("look"))
end
function CoreEditor:viewport()
	return self._vp
end
function CoreEditor:_set_vp_active(active)
	self._vp:set_active(active)
end
function CoreEditor:set_camera(pos, rot)
	self._camera_controller:set_camera_pos(pos)
	self._camera_controller:set_camera_rot(rot)
end
function CoreEditor:set_camera_roll(roll)
	if not self._camera_controller then
		return
	end
	self._camera_controller:set_camera_roll(roll)
end
function CoreEditor:camera()
	return self._vp:camera()
end
function CoreEditor:camera_position()
	return self._camera_controller:get_camera_pos()
end
function CoreEditor:camera_rotation()
	return self._camera_controller:get_camera_rot()
end
function CoreEditor:default_camera_fov()
	return self._camera_fov
end
function CoreEditor:set_default_camera_fov(fov)
	self._camera_fov = fov
	self:set_camera_fov(self._camera_fov)
end
function CoreEditor:camera_fov()
	return self:camera():fov()
end
function CoreEditor:set_camera_fov(fov)
	if math.round(self:camera():fov()) ~= fov then
		self._vp:pop_ref_fov()
		self._vp:push_ref_fov(fov)
		self:camera():set_fov(fov)
	end
end
function CoreEditor:camera_far_range()
	return self:camera():far_range()
end
function CoreEditor:set_camera_near_range(range)
	self._camera_near_range = range
	return self:camera():set_near_range(self._camera_near_range)
end
function CoreEditor:set_camera_far_range(range)
	self._camera_far_range = range
	return self:camera():set_far_range(self._camera_far_range)
end
function CoreEditor:groups()
	return self._groups
end
function CoreEditor:create_group(...)
	local group = self._groups:create(...)
	self:group_created(group)
end
function CoreEditor:remove_group(name, ...)
	self:group_removed(self._groups:groups()[name])
	self._groups:remove(name, ...)
end
function CoreEditor:toggle()
	if self._current then
		self:close()
	else
		self:open()
	end
end
function CoreEditor:open()
	if managers.editor and not self._current then
		self:close()
		self._current = true
		self._screen_borders = Application:screen_resolution()
		self:pickup_tool()
	end
end
function CoreEditor:close()
	if self._current then
		self:putdown_tool()
		self._current = nil
		Application:set_pause(false)
		self._workspace:hide()
		self._workspace:disconnect_all_controllers()
		self:_set_vp_active(false)
	end
end
function CoreEditor:pickup_tool()
	cat_print("editor", "CoreEditor:pickup_tool")
	Global.render_debug.draw_enabled = true
	Global.category_print.editor = true
	if not self._ews_editor_frame then
		self._ews_editor_frame = EWS:Panel(Global.frame_panel, self._editor_name, "TAB_TRAVERSAL")
		self._main_sizer = EWS:BoxSizer("VERTICAL")
		self._ews_editor_frame:set_sizer(self._main_sizer)
		Global.application_window:connect("EVT_LEAVE_WINDOW", callback(self, self, "leaving_window"))
		Global.application_window:connect("EVT_ENTER_WINDOW", callback(self, self, "entering_window"))
		self:build_configuration()
		self:build_left_toolbar()
		Global.v_sizer:add(self:build_lower_panel(), 1, 0, "EXPAND")
		self._main_sizer:add(self:build_editor_controls(), 1, 0, "EXPAND")
		self:add_notebook_pages()
		self:build_menubar()
		Global.frame:set_status_bar(EWS:StatusBar(Global.frame, "", ""))
		self:build_toolbar()
		Global.main_sizer:add(self._ews_editor_frame, 1, 0, "EXPAND")
		Global.frame:set_visible(true)
		Global.frame_panel:layout()
		Global.frame_panel:refresh()
		Global.frame_panel:set_visible(true)
		self._marker_panel:set_visible(self._show_markers)
		self._ews_editor_frame:layout()
		self._confirm_on_new = false
		self:on_new()
		Global.application_window:connect("EVT_SIZE", callback(self, self, "appwin_size_event"))
		self._resizing_appwin = true
		self._move_transform_type_in = MoveTransformTypeIn:new()
		self._rotate_transform_type_in = RotateTransformTypeIn:new()
		self._camera_transform_type_in = CameraTransformTypeIn:new()
		self:load_layout()
		self:check_news()
	end
	self._enabled = true
	self:_set_vp_active(true)
	self:viewport():vp():set_post_processor_effect("World", Idstring("hdr_post_processor"), self._default_post_processor_effect)
	self._workspace:connect_controller(self._ctrl, false)
	self:add_triggers()
	Application:set_pause(false)
	if not self._camera_controller then
		self._camera_controller = FFCEditorController:new(self._vp:camera(), self._ctrl)
	end
	self._workspace:show()
	self._light:set_enable(false)
	self:set_camera_locked(true)
	self:set_in_mixed_input_mode(true)
	self:set_wanted_mute(true)
	self:set_listener_active(true)
	managers.sound_environment:set_check_object_active(self._sound_check_object, true)
	managers.sequence:set_collisions_enabled(false)
	managers.sequence:set_proximity_enabled(false)
	if Global.running_simulation then
		Global.running_simulation = false
		self:stop_simulation()
	end
	self:force_editor_state()
end
function CoreEditor:run_simulation_callback(...)
	if self._stopping_simulation then
		return
	end
	self:run_simulation(...)
end
function CoreEditor:run_simulation(with_mission)
	if not Global.running_simulation then
		if self._lastdir then
		end
		local file = self._simulation_path .. "/test_level.world"
		local save_continents = true
		self:do_save(file, self._simulation_path, save_continents)
		self._world_holder = WorldHolder:new({
			file_type = "world",
			file_path = managers.database:entry_path(file),
			cube_lights_path = managers.database:entry_path(self._lastdir) .. "/"
		})
	end
	if not Global.running_simulation then
		self._saved_simulation_values = {}
		self._error_log = {}
		self._notebook:set_enabled(false)
		Global.render_debug.draw_enabled = false
		Global.running_simulation = true
		Global.running_simulation_with_mission = with_mission
		self:set_in_mixed_input_mode(false)
		self:toggle()
		managers.editor:unit_output()
		managers.editor:has_editables()
		self:_hide_dialogs()
		local mission = self._layers[self._mission_layer_name]
		mission:set_enabled(false)
		self._saved_simulation_values.script = mission:current_script()
		if with_mission then
			managers.editor:output("Start simulation with mission script.", nil, Vector3(0, 0, 255))
			local script = mission:simulate_with_current_script() and mission:current_script()
			local mission_params = {
				file_path = managers.database:entry_path(self._simulation_path .. "\\mission"),
				activate_mission = script
			}
			managers.mission:parse(mission_params)
		else
			managers.editor:output("Start simulation without mission script.", nil, Vector3(0, 0, 255))
		end
		self._current_layer:deactivate({simulation = true})
		self:set_up_portals(self._portal_units_mask)
		managers.helper_unit:clear()
		self:go_through_all_units(self._go_through_units_before_simulaton_mask)
		managers.sequence:set_collisions_enabled(true)
		managers.sequence:set_proximity_enabled(true)
		self:_simulation_disable_continents()
		self:project_run_simulation(with_mission)
		if self._session_state then
			self._session_state:player_slots():primary_slot():request_debug_local_user_binding()
			self._session_state:session_info():set_run_mission_script(with_mission)
			self._session_state:session_info():set_should_load_level(false)
			self._session_state:join_standard_session()
		end
	else
		self:toggle()
	end
end
function CoreEditor:_simulation_disable_continents()
	local t = {}
	if self._simulation_world_setting_path then
		t = self:parse_simulation_world_setting_path(self._simulation_world_setting_path)
	end
	for name, continent in pairs(self._continents) do
		continent:set_simulation_state(t[name])
	end
end
function CoreEditor:project_run_simulation(with_mission)
end
function CoreEditor:set_up_portals(mask)
	local portals = self._layers.Portals
	for name, portal in pairs(portals:get_portal_shapes()) do
		local t = {}
		for _, unit in ipairs(portal.portal) do
			table.insert(t, unit:position())
		end
		local top = portal.top
		local bottom = portal.bottom
		if top == 0 and bottom == 0 then
			top = nil
			bottom = nil
		end
		managers.portal:add_portal(t, bottom, top)
	end
	local units = World:find_units_quick("all", mask)
	for _, unit in ipairs(units) do
		if unit:name() ~= Idstring("light_streaks") and unit:unit_data() and not unit:unit_data().only_visible_in_editor and not unit:unit_data().only_exists_in_editor then
			managers.portal:add_unit(unit)
		end
	end
end
function CoreEditor:go_through_all_units(mask)
	local units = World:find_units_quick("all", mask)
	for _, unit in ipairs(units) do
		if unit:unit_data() then
			if unit:unit_data().only_visible_in_editor then
				unit:set_visible(false)
			end
			if unit:unit_data().only_exists_in_editor then
				unit:set_enabled(false)
			end
			if unit:unit_data().helper_type and unit:unit_data().helper_type ~= "none" then
				managers.helper_unit:add_unit(unit, unit:unit_data().helper_type)
			end
			self:_project_check_unit(unit)
		end
	end
	return units
end
function CoreEditor:_project_check_unit(...)
end
function CoreEditor:_hide_dialogs()
	if self._dialogs.edit_unit then
		self._dialogs.edit_unit:set_visible(false)
	end
end
function CoreEditor:force_editor_state()
	self._gsm:current_state():force_editor_state()
end
function CoreEditor:stop_simulation()
	self._stopping_simulation = true
	self._notebook:set_enabled(true)
	managers.editor:output("End simulation.", nil, Vector3(0, 0, 255))
	managers.mission:stop_simulation()
	managers.worldcamera:stop_simulation()
	managers.environment_effects:kill_all_mission_effects()
	managers.music:stop()
	if self._session_state then
		self._session_state:quit_session()
	end
	self:project_stop_simulation()
	self:clear_layers_and_units()
	self:change_layer_name(self:layer_name(self._current_layer))
	if self._unit_list then
		self._unit_list:reset()
	end
	if self._dialogs.select_by_name then
		self._dialogs.select_by_name:reset()
	end
	self:on_enable_all_layers()
	self:_show_error_log()
end
function CoreEditor:clear_layers_and_units()
	self:clear_layers()
	self:project_clear_layers()
	self:clear_units()
	self:project_clear_units()
	self:recreate_layers()
	self:project_recreate_layers()
	self._clear_and_reset_layer_timer = 10
end
function CoreEditor:clear_units()
end
function CoreEditor:project_stop_simulation()
end
function CoreEditor:project_clear_layers()
end
function CoreEditor:project_clear_units()
end
function CoreEditor:project_recreate_layers()
end
function CoreEditor:_show_error_log()
	if self._error_log and #self._error_log > 0 then
		local errors = "You have " .. #self._error_log .. [[
 new errors:

]]
		for _, msg in ipairs(self._error_log) do
			errors = errors .. "#  " .. msg .. [[


]]
		end
		local dialog = EWS:Dialog(nil, "You got errors!", "", Vector3(400, 200, 0), Vector3(400, 400, 0), "DEFAULT_DIALOG_STYLE,RESIZE_BORDER,STAY_ON_TOP,MAXIMIZE_BOX")
		local dialog_sizer = EWS:BoxSizer("VERTICAL")
		dialog:set_sizer(dialog_sizer)
		dialog_sizer:add(EWS:TextCtrl(dialog, errors, "", "TE_MULTILINE,TE_NOHIDESEL,TE_RICH2,TE_DONTWRAP,TE_READONLY"), 1, 0, "EXPAND")
		dialog:set_visible(true)
	end
end
function CoreEditor:connect_slave()
	if not self._slave_host_name or self._slave_host_name == "" then
		self:on_configuration()
	else
		self:output("Connecting to slave: " .. self._slave_host_name)
		if not managers.slave:act_master(self._slave_host_name, self._slave_port > 0 and self._slave_port, 0 < self._slave_lsport and self._slave_lsport) then
			EWS:message_box(Global.frame, "Could not connect to: " .. self._slave_host_name, "Slave System", "ICON_ERROR,OK", Vector3(-1, -2))
		else
			managers.slave:set_batch_count(self._slave_num_batches)
			self:output("Connected!")
		end
	end
end
function CoreEditor:clear_layers()
	self._layers[self._mission_layer_name]:clear()
	self._layers.Dynamics:clear()
	self._layers.Statics:clear()
	self._layers.Portals:clear()
end
function CoreEditor:recreate_layers()
	self._layers.Portals:load(self._world_holder, Vector3(0, 0, 0))
	self._layers.Statics:load(self._world_holder, Vector3(0, 0, 0))
end
function CoreEditor:reset_layers()
	self._layers.Dynamics:load(self._world_holder, Vector3(0, 0, 0))
	self._layers[self._mission_layer_name]:load(self._world_holder, Vector3(0, 0, 0))
	self._groups:load(self._world_holder, Vector3(0, 0, 0))
	self._layers[self._mission_layer_name]:set_script(self._saved_simulation_values.script)
	self._stopping_simulation = false
end
function CoreEditor:set_show_camera_info(value)
	self._gui:child("camera"):set_visible(value)
end
function CoreEditor:build_editor_controls()
	local editor_sizer = EWS:BoxSizer("VERTICAL")
	editor_sizer:add(self:build_marker_panel(), 0, 0, "EXPAND")
	local sp = EWS:SplitterWindow(self._ews_editor_frame, "", "")
	self._continents_panel = ContinentPanel:new(sp)
	self._notebook = EWS:Notebook(sp, "_notebook", "NB_TOP,NB_MULTILINE")
	self._ews_editor_frame:connect("_notebook", "EVT_COMMAND_NOTEBOOK_PAGE_CHANGED", callback(self, self, "change_layer"), self._notebook)
	sp:split_horizontally(self._continents_panel:panel(), self._notebook, 140)
	sp:set_minimum_pane_size(75)
	editor_sizer:add(sp, 1, 0, "EXPAND")
	return editor_sizer
end
function CoreEditor:close_editing()
	for _, btn in pairs(self._edit_buttons) do
		self._left_toolbar:set_tool_enabled(btn, false)
	end
	self._info_frame:set_visible(true)
	self._edit_panel:set_visible(false)
	self._edit_panel:layout()
	self._lower_panel:layout()
end
function CoreEditor:output_error(text, no_time_stamp)
	self:output(text, no_time_stamp, Vector3(255, 0, 0), "FONTWEIGHT_BOLD")
	EWS:MessageDialog(Global.frame_panel, text, "You are err0r...", "OK,ICON_HAND,STAY_ON_TOP"):show_modal()
	if Global.running_simulation then
		table.insert(self._error_log, text)
	end
end
function CoreEditor:output_warning(text, no_time_stamp)
	self:output(text, no_time_stamp, Vector3(200, 200, 0), "FONTWEIGHT_BOLD")
end
function CoreEditor:output_info(text, no_time_stamp)
	self:output(text, no_time_stamp, Vector3(0, 200, 0), "FONTWEIGHT_BOLD")
end
function CoreEditor:output(text, no_time_stamp, colour, weight)
	if colour then
		self._outputctrl:set_default_style_colour(colour)
	end
	if weight then
		self._outputctrl:set_default_style_font_weight(weight)
	end
	local timestamp = ""
	if self._use_timestamp and not no_time_stamp then
		timestamp = Application:date("%X") .. ": "
	end
	local new_text = timestamp .. text .. "\n"
	self._outputctrl:append(new_text)
	self._outputctrl:show_position(self._outputctrl:get_last_position())
	self._info_frame:refresh()
	self._info_frame:update()
	self._outputctrl:set_default_style_colour(Vector3(0, 0, 0))
	self._outputctrl:set_default_style_font_weight("FONTWEIGHT_NORMAL")
end
function CoreEditor:toggle_mixed_input_mode()
	self:set_in_mixed_input_mode(not self._in_mixed_input_mode)
end
function CoreEditor:in_mixed_input_mode()
	return self._in_mixed_input_mode
end
function CoreEditor:set_in_mixed_input_mode(mixed_input)
	self._in_mixed_input_mode = mixed_input
	if not self._in_mixed_input_mode then
		Input:mouse():acquire()
		Input:mouse():set_deviceless(false)
		self._workspace:set_relative_mouse()
		if self._camera_locked then
			self:set_camera_locked(false)
		end
		self._skipped_freeflight_frames = 0
	else
		Input:mouse():unacquire()
		Input:mouse():set_deviceless(true)
		self._workspace:set_absolute_mouse()
		Global.application_window:set_focus()
		if not self._camera_locked then
			self:set_camera_locked(true)
		end
	end
end
function CoreEditor:set_camera_locked(locked)
	self._camera_locked = locked
	self._workspace:disconnect_mouse()
	if self._camera_locked then
		self._workspace:connect_mouse(Input:mouse())
	end
end
function CoreEditor:hidden_units()
	return self._hidden_units
end
function CoreEditor:on_hide_selected()
	if self._current_layer then
		for _, unit in ipairs(clone(self._current_layer:selected_units())) do
			self:set_unit_visible(unit, false)
		end
		self._current_layer:update_unit_settings()
	end
end
function CoreEditor:on_hide_unselected()
	for _, layer in pairs(self._layers) do
		for _, unit in ipairs(layer:created_units()) do
			if not table.contains(layer:selected_units(), unit) then
				self:set_unit_visible(unit, false)
			end
		end
	end
end
function CoreEditor:on_unhide_all()
	local to_hide = clone(self._hidden_units)
	for _, unit in ipairs(to_hide) do
		self:set_unit_visible(unit, true)
	end
end
function CoreEditor:on_hide_current_layer()
	if self._current_layer then
		self._current_layer:hide_all()
	end
end
function CoreEditor:on_hide_all_layers()
	for _, layer in pairs(self._layers) do
		if layer ~= self._current_layer then
			layer:hide_all()
		end
	end
end
function CoreEditor:set_unit_visible(unit, visible)
	if unit:mission_element() then
		unit:mission_element():on_set_visible(visible)
	end
	unit:set_visible(visible)
	if not unit:visible() then
		if not table.contains(self._hidden_units, unit) then
			self:unselect_unit(unit)
			self:insert_hidden_unit(unit)
		end
	else
		self:delete_hidden_unit(unit)
	end
end
function CoreEditor:unselect_unit(unit)
	local layer = self:unit_in_layer(unit)
	if layer then
		layer:remove_select_unit(unit)
		layer:check_referens_exists()
	end
end
function CoreEditor:insert_hidden_unit(unit)
	table.insert(self._hidden_units, unit)
	if self._dialogs.unhide_by_name then
		self._dialogs.unhide_by_name:hid_unit(unit)
	end
end
function CoreEditor:delete_hidden_unit(unit)
	table.delete(self._hidden_units, unit)
	if self._dialogs.unhide_by_name then
		self._dialogs.unhide_by_name:unhid_unit(unit)
	end
end
function CoreEditor:deleted_unit(unit)
	self:delete_hidden_unit(unit)
	if self._unit_list then
		self._unit_list:deleted_unit(unit)
	end
	if self._dialogs.select_by_name then
		self._dialogs.select_by_name:deleted_unit(unit)
	end
	if self._dialogs.global_select_unit then
		self._dialogs.global_select_unit:deleted_unit(unit)
	end
	for name, dialog in pairs(self._layer_replace_dialogs) do
		if dialog:visible() then
			dialog:deleted_unit(unit)
		end
	end
	if unit:unit_data().editor_groups then
		local groups = clone(unit:unit_data().editor_groups)
		for _, group in ipairs(groups) do
			group:remove_unit(unit)
		end
	end
end
function CoreEditor:spawned_unit(unit)
	if self._unit_list then
		self._unit_list:spawned_unit(unit)
	end
	if self._dialogs.select_by_name then
		self._dialogs.select_by_name:spawned_unit(unit)
	end
	if self._dialogs.global_select_unit then
		self._dialogs.global_select_unit:spawned_unit(unit)
	end
	for name, dialog in pairs(self._layer_replace_dialogs) do
		if dialog:visible() then
			dialog:spawned_unit(unit)
		end
	end
	self:on_selected_unit(unit)
end
function CoreEditor:unit_name_changed(unit)
	if self._unit_list then
		self._unit_list:unit_name_changed(unit)
	end
	if self._dialogs.select_by_name then
		self._dialogs.select_by_name:unit_name_changed(unit)
	end
	if self._dialogs.unhide_by_name then
		self._dialogs.unhide_by_name:unit_name_changed(unit)
	end
end
function CoreEditor:on_selected_unit(unit)
	if self._unit_list then
		self._unit_list:selected_unit(unit)
	end
	for _, callback_func in ipairs(self._selected_unit_callbacks or {}) do
		callback_func(unit)
	end
end
function CoreEditor:on_reference_unit(unit)
	if self._move_transform_type_in then
		self._move_transform_type_in:set_unit(unit)
	end
	if self._rotate_transform_type_in then
		self._rotate_transform_type_in:set_unit(unit)
	end
end
function CoreEditor:group_created(group)
	if self._dialogs.select_group_by_name then
		self._dialogs.select_group_by_name:group_created(group)
	end
end
function CoreEditor:group_removed(group)
	if self._dialogs.select_group_by_name then
		self._dialogs.select_group_by_name:group_removed(group)
	end
end
function CoreEditor:group_selected(group)
	if self._dialogs.select_group_by_name then
		self._dialogs.select_group_by_name:group_selected(group)
	end
end
function CoreEditor:set_selected_units_position(pos)
	if self._current_layer then
		self._current_layer:set_unit_positions(pos)
	end
end
function CoreEditor:set_selected_units_rotation(rot)
	if self._current_layer then
		self._current_layer:set_unit_rotations(rot)
	end
end
function CoreEditor:selected_units(units)
	if self._dialogs.select_by_name then
		self._dialogs.select_by_name:selected_units(units)
	end
end
function CoreEditor:show_layer_replace_dialog(layer)
	local layer_name = self:layer_name(layer)
	if self._layer_replace_dialogs[layer_name] then
		self._layer_replace_dialogs[layer_name]:set_visible(true)
	else
		self._layer_replace_dialogs[layer_name] = LayerReplaceUnit:new(layer)
	end
end
function CoreEditor:layer_name(layer)
	for name, l in pairs(self._layers) do
		if l == layer then
			return name
		end
	end
end
function CoreEditor:current_layer_name()
	return self:layer_name(self._current_layer)
end
function CoreEditor:current_layer()
	return self._current_layer
end
function CoreEditor:freeze_gui_lists()
	if self._unit_list then
		self._unit_list:freeze()
	end
	if self._dialogs.select_by_name then
		self._dialogs.select_by_name:freeze()
	end
end
function CoreEditor:thaw_gui_lists()
	if self._unit_list then
		self._unit_list:thaw()
	end
	if self._dialogs.select_by_name then
		self._dialogs.select_by_name:thaw()
	end
end
function CoreEditor:reset_dialog(name)
	if self._dialogs[name] then
		self._dialogs[name]:reset()
	end
end
function CoreEditor:_reset_dialogs()
	for name, dialog in pairs(self._dialogs) do
		dialog:reset()
	end
end
function CoreEditor:_recreate_dialogs()
	for name, dialog in pairs(self._dialogs) do
		dialog:recreate()
	end
end
function CoreEditor:get_real_name(name)
	local fs = " %*"
	if string.find(name, fs) then
		local e = string.find(name, fs)
		name = string.sub(name, 1, e - 1)
	end
	return name
end
function CoreEditor:add_selected_unit_callback(callback_func)
	self._selected_unit_callbacks = self._selected_unit_callbacks or {}
	table.insert(self._selected_unit_callbacks, callback_func)
	return callback_func
end
function CoreEditor:remove_selected_unit_callback(callback_func)
	if self._selected_unit_callbacks then
		table.delete(self._selected_unit_callbacks, callback_func)
	end
end
function CoreEditor:set_open_file_and_dir(path, dir)
	self._openfile = path
	self._opendir = dir
end
function CoreEditor:update_load_progress(num, title)
	if self._load_progress then
		self._load_progress:update_bar(num, title)
	end
end
function CoreEditor:recent_file(path)
	for _, file in ipairs(self._recent_files) do
		if file.path == path then
			return file
		end
	end
end
function CoreEditor:save_editor_settings(path, dir)
	self._lastfile = path
	self._lastdir = dir
	self._title = self._editor_name .. " - " .. self._lastfile
	Global.frame:set_title(self._title)
	for i, file in ipairs(self._recent_files) do
		Global.frame:disconnect(file.path, "EVT_COMMAND_MENU_SELECTED", self._recent_files_callback)
	end
	table.delete(self._recent_files, self:recent_file(self._lastfile))
	table.insert(self._recent_files, 1, {
		path = self._lastfile,
		dir = self._lastdir
	})
	self._recent_files[self._recent_files_limit + 1] = nil
	self._rf_menu:clear()
	for i, file in ipairs(self._recent_files) do
		self._rf_menu:append_item(file.path, i .. " " .. file.path, "")
		Global.frame:connect(file.path, "EVT_COMMAND_MENU_SELECTED", self._recent_files_callback, i)
	end
	local f = SystemFS:open(managers.database:base_path() .. self._editor_settings_path .. ".xml", "w")
	f:puts("<editor>")
	local t = "\t"
	f:puts(t .. "<last_dir value=\"" .. dir .. "\\\"/>")
	for i, file in ipairs(self._recent_files) do
		f:puts(t .. "<recent_file index=\"" .. i .. "\" path=\"" .. file.path .. "\" dir=\"" .. file.dir .. "\"/>")
	end
	f:puts("</editor>")
	SystemFS:close(f)
end
function CoreEditor:_load_editor_settings()
	if DB:has("xml", self._editor_settings_path) then
		local node = DB:load_node("xml", self._editor_settings_path)
		for setting in node:children() do
			if setting:name() == "last_dir" then
				self._lastdir = setting:parameter("value")
			elseif setting:name() == "recent_file" and setting:has_parameter("index") then
				local index = tonumber(setting:parameter("index"))
				table.insert(self._recent_files, index, {
					path = setting:parameter("path"),
					dir = setting:parameter("dir")
				})
			end
		end
	end
end
function CoreEditor:save_layout()
	local params = {
		save_dialog_states = self._save_dialog_states,
		dialogs = self._dialogs,
		dialogs_settings = self._dialogs_settings,
		file = managers.database:base_path() .. self._layout_path .. ".editor_layout"
	}
	CoreEditorSave.save_layout(params)
end
function CoreEditor:load_layout()
	if DB:has("editor_layout", self._layout_path) then
		local params = {
			dialogs_settings = self._dialogs_settings,
			file = DB:open("editor_layout", self._layout_path)
		}
		CoreEditorSave.load_layout(params)
	end
end
function CoreEditor:show_dialog(name, class_name)
	if not self._dialogs[name] then
		local settings = self._dialogs_settings[name]
		self._dialogs[name] = _G[class_name]:new(settings)
	else
		self._dialogs[name]:set_visible(true)
	end
end
function CoreEditor:hide_dialog(name)
	if self._dialogs[name] then
		self._dialogs[name]:set_visible(false)
	end
end
function CoreEditor:save_configuration()
	local f = SystemFS:open(managers.database:base_path() .. self._configuration_path .. ".xml", "w")
	f:puts("<editor_configuration>")
	local t = "\t"
	for value, ctrlr in pairs(self._config) do
		f:puts(t .. "<" .. value .. " value=\"" .. tostring(self[value]) .. "\" type=\"" .. type_name(self[value]) .. "\"/>")
	end
	f:puts("</editor_configuration>")
	SystemFS:close(f)
end
function CoreEditor:_load_configuration()
	if DB:has("xml", self._configuration_path) then
		local node = DB:load_node("xml", self._configuration_path)
		for setting in node:children() do
			self[setting:name()] = string_to_value(setting:parameter("type"), setting:parameter("value"))
		end
	end
end
function CoreEditor:save_edit_setting_values()
	if not self._save_edit_setting_values then
		if SystemFS:exists(managers.database:base_path() .. self._edit_setting_values_path .. ".xml") then
			SystemFS:delete_file(managers.database:base_path() .. self._edit_setting_values_path .. ".xml")
		end
		return
	end
	local f = SystemFS:open(managers.database:base_path() .. self._edit_setting_values_path .. ".xml", "w")
	f:puts("<edit_setting_values>")
	local t = "\t"
	for _, value in ipairs(self._edit_setting_values) do
		f:puts(t .. "<" .. value .. " value=\"" .. tostring(self[value]) .. "\" type=\"" .. type_name(self[value]) .. "\"/>")
	end
	f:puts("</edit_setting_values>")
	SystemFS:close(f)
end
function CoreEditor:_load_edit_setting_values()
	if not DB:has("xml", self._edit_setting_values_path) then
		return
	end
	local node = DB:load_node("xml", self._edit_setting_values_path)
	for setting in node:children() do
		self[setting:name()] = string_to_value(setting:parameter("type"), setting:parameter("value"))
	end
end
function CoreEditor:select_unit_name(name)
	local ud = CoreEngineAccess._editor_unit_data(name:id())
	for layer_name, layer in pairs(self._layers) do
		for _, u_type in ipairs(layer:unit_types()) do
			if ud:type():s() == u_type then
				for i = 0, self._notebook:get_page_count() - 1 do
					if self._notebook:get_page_text(i) == layer_name then
						self._notebook:set_page(i)
						local units_notebook = layer:units_notebook()
						if units_notebook then
							local nb_type = self:category_name(ud:type():s())
							for j = 0, units_notebook:get_page_count() - 1 do
								if units_notebook:get_page_text(j) == nb_type then
									units_notebook:set_page(j)
								end
							end
							local units_page = layer:notebook_unit_list(nb_type)
							units_page.filter:set_value("")
							local units_list = units_page.units
							for k = 0, units_list:item_count() - 1 do
								if layer:get_real_name(units_list:get_item_data(k)) == name:s() then
									units_list:set_item_selected(k, true)
									return "Found " .. name:s() .. " in layer " .. layer_name .. " with category " .. nb_type
								end
							end
						end
						return "Found " .. name:s() .. " in layer " .. layer_name .. ". No category."
					end
				end
			end
		end
	end
	return name:s() .. " type " .. ud:type():s() .. " is in no layer."
end
function CoreEditor:select_unit(unit)
	local ud = CoreEngineAccess._editor_unit_data(unit:name():id())
	for layer_name, layer in pairs(self._layers) do
		for _, u_type in ipairs(layer:unit_types()) do
			if ud:type():s() == u_type then
				for i = 0, self._notebook:get_page_count() - 1 do
					if self._notebook:get_page_text(i) == layer_name then
						self._notebook:set_page(i)
						self._current_layer:set_select_unit(unit)
					end
				end
			end
		end
	end
end
function CoreEditor:show_replace_unit()
	if not self._replace_dialog then
		self._replace_dialog = ReplaceUnit:new("Replace Units", self._replace_unit_categories)
	else
		self._replace_dialog:show_modal()
	end
	return self._replace_dialog:result()
end
function CoreEditor:show_replace_massunit()
	if not self._replace_massunit_dialog then
		self._replace_massunit_dialog = ReplaceUnit:new("Replace Massunits", {"brush"})
	else
		self._replace_massunit_dialog:show_modal()
	end
	return self._replace_massunit_dialog:result()
end
function CoreEditor:reload_units(unit_names, small_compile)
	if #unit_names <= 0 then
		return
	end
	local reload_data = self._current_layer:prepare_replace(unit_names)
	if small_compile == true then
		local files = {}
		for _, unit_name in ipairs(unit_names) do
			local unit_data = PackageManager:unit_data(unit_name)
			local sequence_file = unit_data:sequence_manager_filename()
			if sequence_file then
				table.insert(files, sequence_file:s() .. ".sequence_manager")
			end
			table.insert(files, managers.database:entry_relative_path(unit_name:s() .. ".unit"))
			table.insert(files, managers.database:entry_relative_path(unit_name:s() .. ".object"))
			table.insert(files, managers.database:entry_relative_path(unit_name:s() .. ".model"))
		end
		Application:data_compile({
			platform = string.lower(SystemInfo:platform():s()),
			source_root = managers.database:base_path(),
			target_db_root = Application:base_path() .. "/assets",
			target_db_name = "all",
			source_files = files,
			verbose = false,
			send_idstrings = false
		})
		DB:reload()
		managers.database:clear_all_cached_indices()
	else
		managers.database:recompile()
	end
	for _, unit_name in ipairs(unit_names) do
		managers.sequence:reload(unit_name, true)
		CoreEngineAccess._editor_reload(Idstring("unit"), unit_name:id())
		local material_config = CoreEngineAccess._editor_unit_data(unit_name:id()):material_config()
		Application:reload_material_config(material_config:id())
	end
	self._current_layer:recreate_units(nil, reload_data)
end
function CoreEditor:entering_window(user_data, event_object)
	if Global.running_simulation then
		self:set_in_mixed_input_mode(false)
		return
	end
	if self._wants_to_leave_window then
		self._wants_to_leave_window = false
		return
	end
	self._in_window = true
	self:add_triggers()
	self._editor_data.keyboard_available = true
end
function CoreEditor:leaving_window(user_data, event_object)
	if Global.running_simulation then
		return
	end
	self:leave_window()
end
function CoreEditor:leave_window()
	self._wants_to_leave_window = false
	self._in_window = false
	self:clear_triggers()
	self._editor_data.keyboard_available = false
end
function CoreEditor:menu_toolbar_toggle(data, event)
	self[data.value] = self[data.menu]:is_checked(event:get_id())
	if data.toolbar then
		local toolbar = self[data.toolbar]
		toolbar:set_tool_state(event:get_id(), self[data.value])
	end
end
function CoreEditor:toolbar_toggle(data, event)
	local toolbar = self[data.toolbar] or self._toolbar
	self[data.value] = toolbar:tool_state(event:get_id())
	if self[data.menu] then
		self[data.menu]:set_checked(event:get_id(), self[data.value])
	end
end
function CoreEditor:toolbar_toggle_trg(data)
	local toolbar = self[data.toolbar] or self._toolbar
	toolbar:set_tool_state(data.id, not toolbar:tool_state(data.id))
	self[data.value] = toolbar:tool_state(data.id)
	if self[data.menu] then
		self[data.menu]:set_checked(data.id, self[data.value])
	end
end
function CoreEditor:coordinate_system()
	return self._coordinate_system
end
function CoreEditor:is_coordinate_system(coor)
	return self._coordinate_system == coor
end
function CoreEditor:use_surface_move()
	return self._use_surface_move
end
function CoreEditor:use_snappoints()
	return self._use_snappoints
end
function CoreEditor:grid_size()
	return ctrl() and 1 or self._grid_size
end
function CoreEditor:snap_rotation()
	return ctrl() and 1 or self._snap_rotation
end
function CoreEditor:snap_rotation_axis()
	return self._snap_rotation_axis
end
function CoreEditor:rotation_speed()
	return self._rotation_speed
end
function CoreEditor:layer_draw_grid()
	return self._layer_draw_grid
end
function CoreEditor:layer_draw_marker()
	return self._layer_draw_marker
end
function CoreEditor:grid_altitude()
	return self._grid_altitude
end
function CoreEditor:set_grid_altitude(altitude)
	self._grid_altitude = altitude
end
function CoreEditor:using_move_widget()
	return self._use_move_widget
end
function CoreEditor:using_rotate_widget()
	return self._use_rotate_widget
end
function CoreEditor:using_groups()
	return self._using_groups
end
function CoreEditor:debug_draw_groups()
	return self._debug_draw_groups
end
function CoreEditor:simulation_debug_areas()
	return self._simulation_debug_areas
end
function CoreEditor:appwin_size_event(data, event)
	self._resizing_appwin = true
	event:skip()
end
function CoreEditor:resize_appwin_done()
	if Global.frame:is_iconized() then
		return
	end
	if self._appwin_fixed_resolution then
		if self._appwin_fixed_resolution ~= Global.application_window:get_size() then
			Global.application_window:set_size(self._appwin_fixed_resolution)
		end
		return
	end
	local size = Global.application_window:get_size()
	self:_update_screen_values(size)
end
function CoreEditor:_update_screen_values(size)
	Application:set_mode(size.x, size.y, false, -1, true, false)
	managers.viewport:set_aspect_ratio2(size.x / size.y)
	self._screen_borders = Application:screen_resolution()
	if self._orthographic then
		self._camera_controller:set_orthographic_screen()
	end
	if managers.viewport then
		managers.viewport:resolution_changed()
	end
end
function CoreEditor:_set_appwin_fixed_resolution(size)
	self._appwin_fixed_resolution = size
	if not size then
		Global.frame_panel:layout()
		return
	end
	Global.application_window:set_size(size)
	self:_update_screen_values(size)
end
function CoreEditor:add_notebook_pages()
	local ordered = {
		"Statics",
		"Mission",
		"Ai",
		"Brush"
	}
	for _, name in ipairs(ordered) do
		local layer = self._layers[name]
		local panel, start_page = layer:build_panel(self._notebook)
		if panel then
			self._notebook:add_page(panel, name, start_page)
		end
	end
	for name, layer in pairs(self._layers) do
		if not table.contains(ordered, name) then
			local panel, start_page = layer:build_panel(self._notebook)
			if panel then
				self._notebook:add_page(panel, name, start_page)
			end
		end
	end
end
function CoreEditor:putdown_tool()
	cat_print("editor", "CoreEditor:putdown_tool")
	self._enabled = false
	self:clear_triggers()
	self._light:set_enable(false)
	self:set_wanted_mute(false)
	self:set_listener_active(false)
	managers.sound_environment:set_check_object_active(self._sound_check_object, false)
	self:viewport():vp():set_post_processor_effect("World", Idstring("hdr_post_processor"), Idstring("default"))
end
function CoreEditor:set_listener_enabled(enabled)
	enabled = self._listener_always_enabled or enabled
	managers.listener:set_listener_enabled(self._listener_id, enabled)
end
function CoreEditor:set_listener_always_enabled(enabled)
	self._listener_always_enabled = enabled
end
function CoreEditor:listener_always_enabled()
	return self._listener_always_enabled
end
function CoreEditor:sound_check_object_active(active)
	managers.sound_environment:set_check_object_active(self._sound_check_object, active)
end
function CoreEditor:set_listener_active(active)
	if active then
		if not self._listener_activation_id then
			self._listener_activation_id = managers.listener:activate_set("main", "editor")
		end
	elseif self._listener_activation_id then
		managers.listener:deactivate_set(self._listener_activation_id)
		self._listener_activation_id = nil
	end
end
function CoreEditor:set_wanted_mute(mute)
	self._mute_states.wanted = mute
end
function CoreEditor:left_mouse_btn()
	if self._trigger_add_unit then
		local ray = self:unit_by_raycast({
			mask = managers.slot:get_mask("all"),
			sample = true
		})
		if ray and ray.unit then
			self._trigger_add_unit(ray.unit)
		end
	end
end
function CoreEditor:set_trigger_add_unit(cb)
	self._trigger_add_unit = cb
end
function CoreEditor:conditions()
	return self._trigger_add_unit and true
end
function CoreEditor:add_triggers()
	if not self._triggers_added and self._in_window then
		self._ctrl:add_trigger(Idstring("undo"), callback(self, self, "undo"))
		self._ctrl:add_trigger(Idstring("toggle_mixed_input_mode"), callback(self, self, "toggle_mixed_input_mode"))
		self._ctrl:add_trigger(Idstring("move_speed_up"), callback(self, self, "move_speed_up"))
		self._ctrl:add_trigger(Idstring("move_speed_down"), callback(self, self, "move_speed_down"))
		self._ctrl:add_trigger(Idstring("lmb"), callback(self, self, "left_mouse_btn"))
		self._ctrl:add_trigger(Idstring("esc"), callback(self, self, "close_editing"))
		self._ctrl:add_trigger(Idstring("ruler_points"), callback(self, self, "set_ruler_points"))
		self._ctrl:add_trigger(Idstring("change_continent_by_unit"), callback(self, self, "change_continent_by_unit"))
		for k, cb in pairs(self._ews_triggers) do
			self._ctrl:add_trigger(Idstring(k), cb)
		end
		if self._current_layer then
			self._current_layer:add_triggers()
		end
		self._triggers_added = true
		return true
	end
	return false
end
function CoreEditor:clear_triggers()
	if self._triggers_added then
		self._ctrl:clear_triggers()
		if self._current_layer then
			self._current_layer:clear_triggers()
		end
		self._triggers_added = false
	end
end
function CoreEditor:layers()
	return self._layers
end
function CoreEditor:layer(name)
	return self._layers[name]
end
function CoreEditor:get_level_path()
	return self._lastdir
end
function CoreEditor:get_open_dir()
	return self._opendir
end
function CoreEditor:lastfile()
	return self._lastfile
end
function CoreEditor:set_world_holder(path)
	Application:error("FIXME: Either unused or broken.")
	self._world_holder = WorldHolder:new({file_type = "world", file_path = path})
end
function CoreEditor:get_world_holder_path()
	Application:error("FIXME: Either unused or broken.")
	return self._world_holder:get_world_file()
end
function CoreEditor:undo()
	if self._current_layer and ctrl() then
		self._current_layer:undo()
	end
end
function CoreEditor:list_terminated()
	local units = {}
	for _, unit in ipairs(World:find_units_quick("all")) do
		if unit:type():s() == "termination" then
			self:output_warning("Unit " .. unit:unit_data().name_id .. " at " .. unit:position() .. " is terminated.")
		end
	end
end
function CoreEditor:convert_position(fract_position)
	return Vector3(fract_position.x * self._screen_borders.x, fract_position.y * self._screen_borders.y, fract_position.z * 100)
end
function CoreEditor:step_id()
	return self._STEP_ID
end
function CoreEditor:get_unit_id(unit)
	if unit:unit_data().continent then
		return unit:unit_data().continent:get_unit_id(unit)
	end
	local i = self._max_id
	while self._unit_ids[i] do
		i = i + 1
	end
	unit:unit_data().unit_id = i
	self:register_unit_id(unit)
	return i
end
function CoreEditor:register_unit_id(unit)
	if unit:unit_data().continent then
		unit:unit_data().continent:register_unit_id(unit)
		return
	end
	self._unit_ids[unit:unit_data().unit_id] = unit
end
function CoreEditor:remove_unit_id(unit)
	if unit:unit_data().continent then
		unit:unit_data().continent:remove_unit_id(unit)
		return
	end
	self._unit_ids[unit:unit_data().unit_id] = nil
end
function CoreEditor:get_gui_id()
	self._gui_id = self._gui_id + 1
	return self._gui_id
end
function CoreEditor:max_id()
	return self._max_id
end
function CoreEditor:set_value_info_pos(position)
	local res = Application:screen_resolution()
	position = position:with_x((1 + position.x) / 2 * res.x)
	position = position:with_y((1 + position.y) / 2 * res.y - 100)
	self._gui:child("value"):set_center(position.x, position.y)
end
function CoreEditor:set_value_info(info)
	self._gui:child("value"):set_text(info)
end
function CoreEditor:set_value_info_visibility(vis)
	self._gui:child("value"):set_visible(vis)
end
function CoreEditor:draw_occluders(t, dt)
	local brush = Draw:brush()
	local cam_pos = self._vp:camera():position()
	local cam_far_range = self._vp:camera():far_range()
	local cam_dir = self._vp:camera():rotation():y()
	for _, layer in pairs(self._layers) do
		local units = layer:created_units()
		for _, unit in ipairs(units) do
			local unit_pos = unit:position()
			if cam_far_range > (unit_pos - cam_pos):length() then
				local objects = unit:get_objects("oc_*")
				for _, object in ipairs(objects) do
					local object_dir = object:rotation():y()
					local a, r, g, b = 0.05, 1, 0, 0
					local d = object_dir:dot(cam_dir)
					if d < 0 then
						local object_pos = object:position()
						local c = object_dir:dot(object_pos - cam_pos)
						if c < 0 then
							a, r, g, b = 0.1, 0, 1, 0
						end
					end
					brush:set_color(Color(a, r, g, b))
					brush:object(object)
					Application:draw(object, r, g, b)
				end
			end
		end
	end
end
function CoreEditor:_should_draw_body(body)
	if not body:enabled() then
		return false
	end
	if body:has_ray_type(Idstring("editor")) and not body:has_ray_type(Idstring("walk")) and not body:has_ray_type(Idstring("mover")) then
		return false
	end
	return true
end
function CoreEditor:_body_color(body)
	if body:has_ray_type(Idstring("editor")) or not body:has_ray_type(Idstring("body")) then
		if body:has_ray_type(Idstring("walk")) and not body:has_ray_type(Idstring("body")) then
			if body:has_ray_type(Idstring("mover")) then
				return Color(1, 1, 0.25, 1)
			end
			if not body:has_ray_type(Idstring("mover")) then
				return Color(1, 0.25, 1, 1)
			end
		end
		if body:has_ray_type(Idstring("mover")) then
			return Color(1, 1, 1, 0.25)
		end
	end
	return Color(1, 0.5, 0.5, 0.85)
end
function CoreEditor:_draw_bodies(t, dt)
	local pen = Draw:pen(Color(0.15, 1, 1, 1))
	local units = self._current_layer:selected_units()
	if 0 < #units then
		local brush = Draw:brush(Color(0.15, 1, 1, 1))
		brush:set_font(Idstring("core/fonts/nice_editor_font"), 16)
		brush:set_render_template(Idstring("OverlayVertexColorTextured"))
		for _, unit in ipairs(units) do
			if alive(unit) then
				local num = unit:num_bodies()
				for i = 0, num - 1 do
					local body = unit:body(i)
					if self:_should_draw_body(body) then
						pen:set(self:_body_color(body), "no_z")
						pen:body(body)
						brush:set_color(self:_body_color(body))
						local offset = Vector3(0, 0, unit:bounding_sphere_radius())
						brush:center_text(body:oobb():center(), body:name():s())
					end
				end
			end
		end
		return
	end
	local bodies = World:find_bodies("intersect", "sphere", self:camera_position(), 2500)
	for _, body in ipairs(bodies) do
		if self:_should_draw_body(body) then
			pen:set(self:_body_color(body))
			pen:body(body)
		end
	end
end
function CoreEditor:update(time, rel_time)
	if self._enabled then
		self:update_title_bar(time, rel_time)
		if self._in_window then
			entering_window()
		end
		if #managers.editor._editor_data.virtual_controller:down_list() == 0 and self._wants_to_leave_window then
			self:leave_window()
		end
		if 0 < #managers.editor._editor_data.virtual_controller:pressed_list() then
			self._confirm_on_new = true
		end
		if self._clear_and_reset_layer_timer then
			if self._clear_and_reset_layer_timer == 0 then
				self._clear_and_reset_layer_timer = nil
				self:reset_layers()
			else
				self._clear_and_reset_layer_timer = self._clear_and_reset_layer_timer - 1
			end
		end
		if self._resizing_appwin then
			self._resizing_appwin = false
			self:resize_appwin_done()
		end
		if self._draw_occluders then
			self:draw_occluders(time, rel_time)
		end
		if self._draw_bodies_on then
			self:_draw_bodies(time, rel_time)
		end
		if self._camera_controller then
			local camera = self._vp:camera()
			local cam_pos = camera:position()
			local cam_rot = camera:rotation()
			local far_range = camera:far_range()
			self._gui:child("camera"):child("cam_pos"):set_text(string.format("Cam pos:   \"%.2f %.2f %.2f\" [cm]", cam_pos.x, cam_pos.y, cam_pos.z))
			self._gui:child("camera"):child("cam_rot"):set_text(string.format("Cam rot:   \"%.2f %.2f %.2f\"", cam_rot:yaw(), cam_rot:pitch(), cam_rot:roll()))
			self._gui:child("camera"):child("far_range"):set_text(string.format("Far range: %.2f [m]", far_range / 100))
			self._light:set_local_position(cam_pos)
			if not self._camera_locked or self._camera_controller:creating_cube_map() then
				if not self._orthographic then
					if 0 < self._skipped_freeflight_frames then
						self._camera_controller:update(time, rel_time)
					else
						self._skipped_freeflight_frames = self._skipped_freeflight_frames + 1
					end
				else
					self._camera_controller:update_orthographic(time, rel_time)
				end
			end
			if self._draw_hidden_units then
				for _, unit in ipairs(self._hidden_units) do
					Application:draw(unit, 0, 0, 0.75)
				end
			end
			self._groups:update(time, rel_time)
			if not self._camera_controller:creating_cube_map() then
				if self._current_layer then
					self._current_layer:update(time, rel_time)
				end
				for _, layer in pairs(self._layers) do
					layer:update_always(time, rel_time)
				end
			end
			if 0 < self._autosave_time then
				self._autosave_timer = self._autosave_timer + rel_time
				if self._autosave_timer > self._autosave_time * 60 then
					self._autosave_timer = 0
					self:autosave()
				end
			end
			if not ctrl() and not alt() and not shift() then
				if self._ctrl:down(Idstring("decrease_view_distance")) then
					camera:set_far_range(camera:far_range() - 5000 * rel_time)
				end
				if self._ctrl:down(Idstring("increase_view_distance")) then
					camera:set_far_range(camera:far_range() + 5000 * rel_time)
				end
			end
			if shift() then
				if self._ctrl:pressed(Idstring("increase_grid_altitude")) then
					self:set_grid_altitude(self:grid_altitude() + self:grid_size())
				end
				if self._ctrl:pressed(Idstring("decrease_grid_altitude")) then
					self:set_grid_altitude(self:grid_altitude() - self:grid_size())
				end
			end
			if self._show_center then
				local pos = Vector3(0, 0, 0)
				local rot = Rotation:yaw_pitch_roll(0, 0, 0)
				Application:draw_sphere(pos, 50, 1, 1, 1)
				Application:draw_rotation(pos, rot)
				local length = (cam_pos - pos):length()
				local from = Vector3(pos.x, pos.y, pos.z - length / 2)
				local to = Vector3(pos.x, pos.y, pos.z + length / 2)
				Application:draw_cylinder(from, to, 50, 1, 1, 1)
			end
			self._move_transform_type_in:update(time, rel_time)
			self._rotate_transform_type_in:update(time, rel_time)
			self._camera_transform_type_in:update(time, rel_time)
			if self._mission_graph then
				self._mission_graph:update(time, rel_time)
			end
		end
		for _, marker in pairs(self._markers) do
			marker:draw()
		end
		self:update_ruler(time, rel_time)
		if self._dialogs.edit_unit then
			self._dialogs.edit_unit:update(time, rel_time)
		end
	end
	self:_update_mute_state(time, rel_time)
end
function CoreEditor:_update_mute_state(t, dt)
	if self._mute_states.wanted ~= self._mute_states.current then
		if self._mute_states.wanted then
			self._mute_source:post_event("mute")
		else
			self._mute_source:post_event("unmute")
		end
		self._mute_states.current = self._mute_states.wanted
	end
end
function CoreEditor:update_ruler(t, dt)
	if not self._ruler_points or #self._ruler_points == 0 then
		return
	end
	local pos = self._ruler_points[1]
	Application:draw_sphere(pos, 10, 1, 1, 1)
	local ray = self:select_unit_by_raycast(managers.slot:get_mask("all"), "body editor")
	if not ray or not ray.position then
		return
	end
	local len = (pos - ray.position):length()
	Application:draw_sphere(ray.position, 10, 1, 1, 1)
	Application:draw_line(pos, ray.position, 1, 1, 1)
	self:set_value_info(string.format("Length: %.2fm", len / 100))
	self:set_value_info_pos(self:world_to_screen(ray.position))
end
function CoreEditor:current_orientation(offset_move_vec, unit)
	local current_pos, current_rot
	local p1 = self:get_cursor_look_point(0)
	if not self:use_surface_move() then
		local p2 = self:get_cursor_look_point(100)
		if p1.z - p2.z ~= 0 then
			local t = (p1.z - self:grid_altitude()) / (p1.z - p2.z)
			local p = p1 + (p2 - p1) * t + offset_move_vec
			if t < 1000 and -1000 < t then
				local x = math.round(p.x / self:grid_size()) * self:grid_size()
				local y = math.round(p.y / self:grid_size()) * self:grid_size()
				local z = math.round(p.z / self:grid_size()) * self:grid_size()
				current_pos = Vector3(x, y, z)
			end
		end
	else
		local p2 = self:get_cursor_look_point(25000)
		local ray
		local rays = World:raycast_all(p1, p2, nil, self._surface_move_mask)
		if rays then
			for _, unit_r in ipairs(rays) do
				if unit_r.unit ~= unit and unit_r.unit:visible() then
					ray = unit_r
					break
				end
			end
		end
		if ray then
			local p = ray.position + offset_move_vec
			local x = math.round(p.x / self:grid_size()) * self:grid_size()
			local y = math.round(p.y / self:grid_size()) * self:grid_size()
			current_pos = Vector3(x, y, p.z)
			local n = ray.normal
			Application:draw_line(current_pos, current_pos + n * 2000, 0, 0, 1)
			if alive(unit) then
				local u_rot = unit:rotation()
				local z = n
				local x = (u_rot:x() - z * z:dot(u_rot:x())):normalized()
				local y = z:cross(x)
				local rot = Rotation(x, y, z)
				current_rot = rot * unit:rotation():inverse()
			end
		end
	end
	if alive(unit) and self:use_snappoints() and current_pos then
		local r = 1100
		local pos = current_pos
		Application:draw_sphere(pos, r, 1, 0, 1)
		local units = unit:find_units("intersect", "force_physics", "sphere", pos, r)
		local closest_snap
		for _, unit in ipairs(units) do
			local aligns = unit:get_objects("snap*")
			if 0 < #aligns then
				table.insert(aligns, unit:orientation_object())
			end
			for _, o in ipairs(aligns) do
				local len = (o:position() - pos):length()
				if r > len and (not closest_snap or len < (closest_snap:position() - pos):length()) then
					closest_snap = o
				end
				Application:draw_rotation_size(o:position(), o:rotation(), 400)
				Application:draw_sphere(o:position(), 50, 0, 1, 1)
			end
			Application:draw(unit, 1, 0, 0)
		end
		if closest_snap then
			current_pos = closest_snap:position()
			current_rot = closest_snap:rotation() * unit:rotation():inverse()
		end
	end
	self._current_pos = current_pos or self._current_pos
	return current_pos, current_rot
end
function CoreEditor:draw_grid(unit)
	if not managers.editor:layer_draw_grid() then
		return
	end
	local rot = Rotation(0, 0, 0)
	if alive(unit) and self:is_coordinate_system("Local") then
		rot = unit:rotation()
	end
	for i = -5, 5 do
		local from_x = self._current_pos + rot:x() * (i * self:grid_size()) - rot:y() * (6 * self:grid_size())
		local to_x = self._current_pos + rot:x() * (i * self:grid_size()) + rot:y() * (6 * self:grid_size())
		Application:draw_line(from_x, to_x, 0, 0.5, 0)
		local from_y = self._current_pos + rot:y() * (i * self:grid_size()) - rot:x() * (6 * self:grid_size())
		local to_y = self._current_pos + rot:y() * (i * self:grid_size()) + rot:x() * (6 * self:grid_size())
		Application:draw_line(from_y, to_y, 0, 0.5, 0)
	end
end
function CoreEditor:update_title_bar(time, rel_time)
	self._title_nr = self._title_nr or 0
	self._title_speed = self._title_speed or 30
	self._title_wait_time = self._title_wait_time or 30
	local title = self._title
	self._title_show_time = self._title_speed * 100
	if self._title_show_msg then
		self._title_show_time = self._title_speed
		title = self._title_msg
	end
	if not self._title_down then
		self._title_nr = self._title_nr + self._title_speed * rel_time
		if self._title_nr >= string.len(title) then
			self._title_down = true
			self._title_show_msg = not self._title_show_msg
			if self._title_show_msg then
				self._title_msg = self._title_messages[math.ceil(math.rand(table.maxn(self._title_messages)))]
				self._title_nr = string.len(self._title_msg)
			end
		end
	elseif self._title_down then
		self._title_nr = self._title_nr - self._title_speed * rel_time
		if self._title_nr <= -self._title_show_time then
			self._title_nr = 0
			self._title_down = false
		end
	end
	title = string.sub(title, math.round(math.clamp(self._title_nr, 0, string.len(title))))
	Global.frame:set_title(title)
end
function CoreEditor:get_controller()
	return self._ctrl
end
function CoreEditor:move_speed_up()
	local change = math.clamp(self._camera_controller:get_move_speed() * 0.2, 5, 8000)
	local m_speed = math.clamp(self._camera_controller:get_move_speed() + change, 10, 80000)
	self._camera_controller:set_move_speed(m_speed)
end
function CoreEditor:move_speed_down()
	local change = math.clamp(self._camera_controller:get_move_speed() * 0.2, 5, 8000)
	local m_speed = math.clamp(self._camera_controller:get_move_speed() - change, 10, 80000)
	self._camera_controller:set_move_speed(m_speed)
end
function CoreEditor:get_cursor_look_point(dist)
	return self._vp:camera():screen_to_world(self:cursor_pos() + Vector3(0, 0, dist))
end
function CoreEditor:cursor_pos()
	local x, y = self._workspace:mouse_position()
	return Vector3(x / self._screen_borders.x * 2 - 1, y / self._screen_borders.y * 2 - 1, 0)
end
function CoreEditor:mouse_pos(pos)
	local x, y = self._workspace:mouse_position()
	return Vector3(x, y, 0)
end
function CoreEditor:screen_pos(pos)
	return Vector3(self._screen_borders.x * ((pos.x + 1) / 2), self._screen_borders.y * ((pos.y + 1) / 2), 0)
end
function CoreEditor:world_to_screen(pos)
	return self._vp:camera():world_to_screen(pos)
end
function CoreEditor:screen_to_world(pos, dist)
	return self._vp:camera():screen_to_world(pos + Vector3(0, 0, dist))
end
function CoreEditor:unit_by_raycast(data)
	local rays = self:_unit_raycasts(data.mask, data.ray_type, data.from, data.to)
	if rays then
		for _, ray in ipairs(rays) do
			if data.sample then
				if self:sample_unit_ok_conditions(ray.unit) then
					return ray
				end
			elseif self:select_unit_ok_conditions(ray.unit) then
				return ray
			end
		end
	end
	return nil
end
function CoreEditor:_unit_raycasts(mask, ray_type, from, to)
	local from = from or self:get_cursor_look_point(0)
	local to = to or self:get_cursor_look_point(200000)
	local rays
	if ray_type then
		rays = World:raycast_all("ray", from, to, "ray_type", ray_type, "slot_mask", mask)
	else
		rays = World:raycast_all(from, to, nil, mask)
	end
	return rays
end
function CoreEditor:select_unit_by_raycast(mask, ray_type, from, to)
	local rays = self:_unit_raycasts(mask, ray_type, from, to)
	if rays then
		for _, ray in ipairs(rays) do
			if self:select_unit_ok_conditions(ray.unit) then
				return ray
			end
		end
	end
	return nil
end
function CoreEditor:select_unit_ok_conditions(unit, layer)
	if unit:visible() then
		if self:current_continent() then
			if unit:unit_data().continent then
				layer = layer or self:unit_in_layer(unit)
				if layer and layer:uses_continents() and self:current_continent() == unit:unit_data().continent then
					return true
				end
			else
				return true
			end
		else
			return true
		end
	end
	return false
end
function CoreEditor:sample_unit_ok_conditions(unit, layer)
	if unit:visible() then
		return true
	end
	return false
end
function CoreEditor:click_select_unit(layer)
	if layer:condition() or layer:grab() then
		return
	end
	local rays = self:_unit_raycasts(managers.slot:get_mask("editor_all"), "body editor")
	for _, ray in ipairs(rays) do
		local unit = ray.unit
		if self:select_unit_ok_conditions(unit) then
			if self:_global_select() then
				self:select_unit(unit)
				return
			elseif layer == self:unit_in_layer(unit) then
				layer:set_select_unit(unit)
				return
			elseif self._special_units[unit:key()] == self:layer_name(layer) then
				layer:set_select_unit(unit)
				return
			end
		end
	end
	layer:set_select_unit(nil)
end
function CoreEditor:_global_select()
	if CoreInput.ctrl() or CoreInput.alt() then
		return false
	end
	return self:always_global_select_unit() ~= CoreInput.shift()
end
function CoreEditor:change_layer(notebook)
	local s = notebook:get_page_count()
	local c_page = notebook:get_current_page()
	for i = 0, s - 1 do
		if notebook:get_page(i) == c_page then
			self:change_layer_name(notebook:get_page_text(i))
			break
		end
	end
end
function CoreEditor:change_layer_name(name)
	self:clear_triggers()
	if self._current_layer then
		self._current_layer:deactivate()
	end
	self._current_layer = self._layers[name]
	if self._current_layer then
		self:output("Changed layer to " .. name)
		self._current_layer:activate()
	end
	self:add_triggers()
end
function CoreEditor:change_layer_notebook(name)
	for i = 0, self._notebook:get_page_count() - 1 do
		if self._notebook:get_page_text(i) == name then
			self._notebook:set_page(i)
		end
	end
end
function CoreEditor:copy_incremental(dir, src_dir, rules)
	dir = dir .. "\\" .. Application:date("%Y-%m-%d_%H_%M_%S")
	SystemFS:make_dir(dir)
	self:_copy_files(src_dir, dir, rules)
end
function CoreEditor:_copy_files(src, dest, rules)
	rules = rules or {}
	local files = {}
	for _, file in ipairs(SystemFS:list(src)) do
		table.insert(files, {
			file = src .. "/" .. file,
			sub_dir = ""
		})
	end
	for _, sub_dir in ipairs(SystemFS:list(src, true)) do
		for _, file in ipairs(SystemFS:list(src .. "/" .. sub_dir)) do
			table.insert(files, {
				file = src .. "/" .. sub_dir .. "/" .. file,
				sub_dir = sub_dir .. "\\"
			})
		end
	end
	for _, file in ipairs(files) do
		local name = managers.database:entry_name(file.file)
		local type = managers.database:entry_type(file.file)
		if not rules.ignore or not rules.ignore[type] then
			local to = dest .. "\\" .. file.sub_dir
			if not SystemFS:exists(to) then
				SystemFS:make_dir(to)
			end
			local to = to .. name .. "." .. type
			local success = SystemFS:copy_file(file.file, to)
		end
	end
end
function CoreEditor:autosave()
	if self._lastdir and self._lastfile then
		self:save_incremental(self:create_temp_saves("autosave"), "world")
	end
end
function CoreEditor:save_incremental(dir, f_name)
	dir = dir .. "\\" .. Application:date("%Y-%m-%d_%H_%M_%S")
	SystemFS:make_dir(dir)
	local path = dir .. "\\" .. f_name .. ".world"
	local save_continents = true
	self:do_save(path, dir, save_continents)
end
function CoreEditor:do_save(path, dir, save_continents)
	if not path and not dir then
		Application:error("No path or dir specified when trying to save")
		return
	end
	self._world_package_table = {}
	self._world_init_package_table = {}
	self._continent_package_table = {}
	self._continent_init_package_table = {}
	self._world_sound_package_table = {}
	self._world_save_table = {}
	self._continent_save_tables = {}
	self._world_save_table.world_data = {
		max_id = self._max_id,
		markers = self._markers,
		values = self._values.world,
		editor_groups = nil,
		continents_file = "continents"
	}
	for continent, values in pairs(self._values) do
		local t = {
			entry = "values",
			continent = continent,
			single_data_block = true,
			data = values
		}
		self:add_save_data(t)
	end
	for _, layer in pairs(self._layers) do
		local save_params = {dir = dir}
		layer:save(save_params)
	end
	self._groups:save()
	local f = self:_open_file(path)
	f:puts(ScriptSerializer:to_generic_xml(self._world_save_table))
	SystemFS:close(f)
	self:_add_files_to_package(dir)
	self:_save_continent_files(dir)
	self:_save_continents_file(dir)
	self:_save_mission_file(dir)
	self:_save_cover_ai_data(dir)
	self:_save_packages(dir)
	self:_save_unit_stats(dir)
	self:_recompile(dir)
	self:output("Saved to " .. path)
	cat_debug("editor", "Saved to ", path)
end
function CoreEditor:_recompile(dir)
	local source_files = self:_source_files(dir)
	local t = {
		platform = "win32",
		source_root = managers.database:root_path() .. "/assets",
		target_db_root = managers.database:root_path() .. "/packages/win32/assets",
		target_db_name = "all",
		source_files = source_files,
		verbose = false,
		send_idstrings = false
	}
	Application:data_compile(t)
	DB:reload()
	managers.database:clear_all_cached_indices()
	for _, file in ipairs(source_files) do
		PackageManager:reload(managers.database:entry_type(file):id(), managers.database:entry_path(file):id())
	end
end
function CoreEditor:_source_files(dir)
	local files = {}
	local entry_path = managers.database:entry_path(dir) .. "/"
	for _, file in ipairs(SystemFS:list(dir)) do
		table.insert(files, entry_path .. file)
	end
	for _, sub_dir in ipairs(SystemFS:list(dir, true)) do
		for _, file in ipairs(SystemFS:list(dir .. "/" .. sub_dir)) do
			table.insert(files, entry_path .. sub_dir .. "/" .. file)
		end
	end
	return files
end
function CoreEditor:add_to_world_package(params)
	local name = params.name
	local path = params.path
	local category = params.category
	local continent = params.continent
	if continent and not self:_check_package_duplicity(params) then
		local t = params.init and self._continent_init_package_table or self._continent_package_table
		t[continent:name()] = t[continent:name()] or {}
		local package_table = t[continent:name()]
		package_table[category] = package_table[category] or {}
		if not table.contains(package_table[category], name or path) then
			table.insert(package_table[category], name or path)
		end
		return
	end
	local t = params.init and self._world_init_package_table or self._world_package_table
	t[category] = t[category] or {}
	if not table.contains(t[category], name or path) then
		table.insert(t[category], name or path)
	end
end
function CoreEditor:add_to_sound_package(params)
	local name = params.name
	local path = params.path
	local category = params.category
	local continent = params.continent
	self._world_sound_package_table[category] = self._world_sound_package_table[category] or {}
	if not table.contains(self._world_sound_package_table[category], name or path) then
		table.insert(self._world_sound_package_table[category], name or path)
	end
end
function CoreEditor:_save_packages(dir)
	local package = SystemFS:open(dir .. "\\world.package", "w")
	self:_save_package(package, self._world_package_table)
	local init_package = SystemFS:open(dir .. "\\world_init.package", "w")
	self:_save_package(init_package, self._world_init_package_table)
	for continent, package_table in pairs(self._continent_package_table) do
		local file = SystemFS:open(dir .. "\\" .. continent .. "\\" .. continent .. ".package", "w")
		self:_save_package(file, package_table)
	end
	for continent, package_table in pairs(self._continent_init_package_table) do
		local file = SystemFS:open(dir .. "\\" .. continent .. "\\" .. continent .. "_init.package", "w")
		self:_save_package(file, package_table)
	end
	local sound_package = SystemFS:open(dir .. "\\world_sounds.package", "w")
	self:_save_package(sound_package, self._world_sound_package_table)
end
function CoreEditor:_check_package_duplicity(params)
	local name = params.name
	local path = params.path
	local category = params.category
	local continent = params.continent
	local world_package_table = params.init and self._world_init_package_table or self._world_package_table
	local continent_package_table = params.init and self._continent_init_package_table or self._continent_package_table
	if world_package_table[category] and table.contains(world_package_table[category], name) then
		return true
	end
	local found = false
	for c_name, package in pairs(continent_package_table) do
		if c_name ~= continent:name() then
			for p_category, data in pairs(package) do
				if p_category == category and table.contains(data, name) then
					found = true
					table.delete(data, name)
				end
			end
		end
	end
	return found
end
function CoreEditor:_save_package(file, package_table)
	file:puts("<package>")
	for category, names in pairs(package_table) do
		local entry
		if category == "units" then
			entry = "unit"
		elseif category == "massunits" then
			entry = "massunit"
		elseif category == "physic_effects" then
			entry = "physic_effect"
		elseif category == "fonts" then
			entry = "font"
		elseif category == "effects" then
			entry = "effect"
		elseif category == "scenes" then
			entry = "scene"
		elseif category == "soundbanks" then
			entry = "bnk"
		elseif category == "guis" then
			entry = "gui"
		elseif category == "script_data" then
			entry = ""
		end
		file:puts("\t<" .. category .. ">")
		if entry then
			for _, name in ipairs(names) do
				if category == "script_data" then
					entry = managers.database:entry_type(name)
					name = managers.database:entry_path(name)
				end
				file:puts("\t\t<" .. entry .. " name=\"" .. name .. "\"/>")
			end
		end
		file:puts("\t</" .. category .. ">")
	end
	file:puts("</package>")
	SystemFS:close(file)
end
function CoreEditor:_save_shadow_textures(dir)
	local path = dir .. "/shadow_textures.gui"
	local gui_file = SystemFS:open(path, "w")
	gui_file:puts("<gui>")
	print("dir", dir)
	dir = dir .. "/cube_lights"
	local files = self:_source_files(dir)
	print(inspect(files))
	for _, file in ipairs(files) do
		local name = managers.database:entry_name(file)
		print("is used", name, self:_shadow_texture_is_used(name))
		if self:_shadow_texture_is_used(name) then
			gui_file:puts("\t<preload texture=\"" .. managers.database:entry_path(file) .. "\"/>")
		end
		print(managers.database:entry_type(file))
		print(managers.database:entry_name(file))
		print(managers.database:entry_path(file))
	end
	gui_file:puts("</gui>")
	SystemFS:close(gui_file)
	print("managers.database:entry_relative_path( path )", path, managers.database:entry_relative_path(path))
	managers.editor:add_to_world_package({
		category = "guis",
		path = managers.database:entry_path(path)
	})
end
function CoreEditor:_shadow_texture_is_used(name_id)
	for _, continent in pairs(self._continents) do
		if continent._unit_ids[tonumber(name_id)] then
			return true
		end
	end
	return false
end
function CoreEditor:_add_files_to_package(dir)
	local types = {
		"world_setting"
	}
	local files = self:_source_files(dir)
	for _, file in ipairs(files) do
		for _, type in ipairs(types) do
			if type == managers.database:entry_type(file) then
				self:add_to_world_package({
					name = file,
					category = "script_data"
				})
			end
		end
	end
end
function CoreEditor:_save_continent_files(dir)
	for continent, data in pairs(self._continent_save_tables) do
		local continent_dir = dir .. "/" .. continent .. "/"
		self:_make_dir(continent_dir)
		local f = self:_open_file(continent_dir .. continent .. ".continent", self._continents[continent], true)
		f:puts(ScriptSerializer:to_generic_xml(data))
		SystemFS:close(f)
		self:_save_continent_mission_file({
			path = continent_dir .. continent .. ".mission",
			dir = continent_dir,
			name = continent,
			continent = self._continents[continent]
		})
	end
end
function CoreEditor:_save_continent_mission_file(params)
	local file = self:_open_file(params.path, params.continent, true)
	file:puts(ScriptSerializer:to_generic_xml(self._layers[self._mission_layer_name]:save_mission(params)))
	SystemFS:close(file)
end
function CoreEditor:_save_continents_file(dir)
	local continents = {}
	for name, continent in pairs(self._continents) do
		continents[name] = continent:values()
	end
	local file = self:_open_file(dir .. "\\continents.continents")
	file:puts(ScriptSerializer:to_generic_xml(continents))
	SystemFS:close(file)
end
function CoreEditor:_save_mission_file(dir)
	local t = {}
	for name, continent in pairs(self._continents) do
		t[name] = {
			file = name .. "/" .. name
		}
	end
	local mission = self:_open_file(dir .. "\\mission.mission")
	mission:puts(ScriptSerializer:to_generic_xml(t))
	SystemFS:close(mission)
end
function CoreEditor:_save_nav_manager_data(dir)
	local nav_data = self:_open_file(dir .. "\\nav_manager_data.nav_data")
	local t = managers.navigation:get_save_data()
	nav_data:puts(t)
	SystemFS:close(nav_data)
end
function CoreEditor:_save_cover_ai_data(dir)
	local all_cover_units = World:find_units_quick("all", managers.slot:get_mask("cover"))
	local covers = {}
	for i, unit in pairs(all_cover_units) do
		local pos = unit:position()
		local rot = unit:rotation()
		table.insert(covers, {
			Vector3(math.round(pos.x), math.round(pos.y), math.round(pos.z)),
			math.round(rot:yaw())
		})
	end
	local cover_ai_data = self:_open_file(dir .. "\\cover_data.cover_data")
	cover_ai_data:puts(ScriptSerializer:to_generic_xml(covers))
	SystemFS:close(cover_ai_data)
end
function CoreEditor:_open_file(path, continent, init)
	managers.editor:add_to_world_package({
		category = "script_data",
		path = managers.database:entry_relative_path(path),
		continent = continent,
		init = init
	})
	return SystemFS:open(path, "w")
end
function CoreEditor:_make_dir(dir)
	if not SystemFS:exists(dir) then
		SystemFS:make_dir(dir)
	end
end
function CoreEditor:add_save_data(values)
	if values.continent then
		self._continent_save_tables[values.continent] = self._continent_save_tables[values.continent] or {}
		self._continent_save_tables[values.continent][values.entry] = self._continent_save_tables[values.continent][values.entry] or {}
		if values.single_data_block then
			self._continent_save_tables[values.continent][values.entry] = values.data
		else
			table.insert(self._continent_save_tables[values.continent][values.entry], values.data)
		end
	else
		self._world_save_table[values.entry] = self._world_save_table[values.entry] or {}
		if values.single_data_block then
			self._world_save_table[values.entry] = values.data
		else
			table.insert(self._world_save_table[values.entry], values.data)
		end
	end
end
function CoreEditor:_save_unit_stats(dir)
	local unit_stats = SystemFS:open(dir .. "\\unit_stats.unit_stats", "w")
	local data, total = self:get_unit_stats()
	unit_stats:puts("Name,Amount,Geometry Memory,Models,Bodies,Slot,Mass,Textures,Materials,Vertices/Triangles,Instanced,Author,Unit Filename,Object filename,Diesel Filename,Material Filename,Last Exported From")
	for name, t in pairs(data) do
		unit_stats:puts(name .. "," .. t.amount .. "," .. t.memory .. "," .. t.models .. "," .. t.nr_bodies .. "," .. t.slot .. "," .. t.mass .. "," .. t.nr_textures .. "," .. t.nr_materials .. "," .. t.vertices_per_tris .. "," .. tostring(t.instanced) .. "," .. t.author .. "," .. t.unit_filename .. "," .. t.model_filename .. "," .. t.diesel_filename .. "," .. t.material_filename .. "," .. t.last_exported_from)
	end
	unit_stats:puts("")
	unit_stats:puts("Total," .. total.amount .. "," .. total.geometry_memory)
	SystemFS:close(unit_stats)
end
function CoreEditor:get_unit_stats()
	local units = World:find_units_quick("all")
	local data = {}
	local total = {}
	total.amount = 0
	total.geometry_memory = 0
	for _, u in ipairs(units) do
		total.amount = total.amount + 1
		if data[u:name():s()] then
			data[u:name():s()].amount = data[u:name():s()].amount + 1
		else
			local t = self:get_unit_stat(u)
			t.amount = 1
			data[u:name():s()] = t
			total.geometry_memory = total.geometry_memory + t.memory
		end
	end
	return data, total
end
function CoreEditor:get_unit_stat(u)
	local t = {}
	t.memory = u:geometry_memory_use()
	t.models = u:nr_models()
	t.author = u:author():s()
	t.nr_bodies = u:num_bodies()
	t.slot = u:slot()
	t.mass = string.format("%.4f", u:mass())
	t.nr_textures = #u:used_texture_names()
	t.nr_materials = #u:get_objects_by_type(Idstring("material"))
	t.vertices_per_tris = self:vertices_per_tris(u)
	t.instanced = self:_is_instanced(u)
	t.unit_filename = u:unit_filename()
	t.model_filename = u:model_filename()
	t.diesel_filename = u:diesel_filename()
	t.material_filename = u:material_config():s()
	t.last_exported_from = u:last_export_source()
	return t
end
function CoreEditor:vertices_per_tris(u)
	local vertices = 0
	local tris = 0
	for i = 0, u:nr_models() - 1 do
		vertices = vertices + u:vertex_count(i)
		tris = tris + u:triangle_count(i)
	end
	if tris == 0 then
		return 0
	end
	return string.format("%.4f", vertices / tris)
end
function CoreEditor:model_vertices(u, prefix)
	local vertices = 0
	for i, model in ipairs(u:get_objects_by_type(Idstring("model"))) do
		if string.match(model:name():s(), prefix) then
			vertices = vertices + u:vertex_count(i - 1)
		end
	end
	return string.format("%.4f", vertices)
end
function CoreEditor:_is_instanced(u)
	for i = 0, u:nr_models() - 1 do
		if u:is_model_instance(i) then
			return true
		end
	end
	return false
end
function CoreEditor:load_level(dir, path)
	self:output("Open file " .. path)
	self._load_progress = EWS:ProgressDialog(Global.frame_panel, "Loading..", "Parsing world file", 100, "PD_AUTO_HIDE,PD_SMOOTH,PD_ESTIMATED_TIME,PD_REMAINING_TIME")
	self._world_holder = WorldHolder:new({
		file_type = "world",
		file_path = managers.database:entry_path(path)
	})
	if self._world_holder:is_ok() then
		self:set_open_file_and_dir(path, dir)
		self:do_load()
		self:save_editor_settings(path, dir)
	else
		self:output("Wrong file format!")
	end
	self:update_load_progress(100)
end
function CoreEditor:do_load()
	self._loading = true
	self:clear_all()
	self._max_id = self._world_holder:get_max_id("world")
	self._max_id = math.ceil(self._max_id / 10) * 10
	local offset = Vector3(0, 0, 0)
	self:load_markers(self._world_holder, offset)
	self:load_continents(self._world_holder, offset)
	self:load_values(self._world_holder, offset)
	local progress_i = 50
	local layers_amount = table.size(self._layers)
	for name, layer in pairs(self._layers) do
		progress_i = progress_i + 50 / layers_amount
		self:update_load_progress(progress_i, "Create Layer: " .. name)
		layer:load(self._world_holder, offset)
	end
	self._groups:load(self._world_holder, offset)
	for _, continent in pairs(self._continents) do
		continent:set_need_saving(false)
	end
	self:_reset_dialogs()
	self:_recreate_dialogs()
	for name, dialog in pairs(self._layer_replace_dialogs) do
		dialog:reset()
	end
	self._loading = false
end
function CoreEditor:loading()
	return self._loading
end
function CoreEditor:clear_all()
	if self._reset_camera_on_new and self._camera_controller then
		self._camera_controller:set_camera_pos(Vector3(0, 0, 0))
		self._camera_controller:set_camera_rot(Rotation())
	end
	self._max_id = 0
	self._continents = {}
	self._continents_panel:destroy_all_continents()
	self:create_continent("world", {})
	self:set_simulation_world_setting_path(nil)
	for _, layer in pairs(self._layers) do
		layer:clear()
	end
	self:clear_markers()
	self:has_editables()
	self:_clear_values()
	self:_recreate_dialogs()
end
function CoreEditor:load_markers(world_holder, offset)
	local markers = world_holder:create_world("world", "markers", offset)
	for _, marker in pairs(markers) do
		local n = marker._name
		local p = marker._pos
		local r = marker._rot
		self:create_marker(n, p, r)
		self._ews_markers:append(n)
	end
end
function CoreEditor:load_values(world_holder, offset)
	local values = world_holder:create_world("world", "values", offset)
	if not values.world then
		return
	end
	self._values = clone(values)
end
function CoreEditor:load_continents(world_holder, offset)
	local continents = world_holder:create_world("world", "continents", offset)
	for name, data in pairs(continents) do
		local continent = self:create_continent(name, data)
	end
	self:set_continent("world")
end
function CoreEditor:invert_move_shift()
	return self._invert_move_shift
end
function CoreEditor:always_global_select_unit()
	return self._always_global_select_unit
end
function CoreEditor:dialogs_stay_on_top()
	return self._dialogs_stay_on_top
end
function CoreEditor:add_unit_edit_page(name)
	if not self._dialogs.edit_unit then
		self:show_dialog("edit_unit", "EditUnitDialog")
	end
	return self._dialogs.edit_unit:add_page(name)
end
function CoreEditor:toggle_edit_unit_dialog()
	if self._dialogs.edit_unit then
		if self._dialogs.edit_unit:visible() then
			self:hide_dialog("edit_unit")
		else
			self:show_dialog("edit_unit")
		end
	end
end
function CoreEditor:has_editables(unit, units)
	if self._dialogs.edit_unit then
		self._dialogs.edit_unit:set_enabled(unit, units)
	end
	local enable = self:check_has_editables(unit, units)
	local is_any_visible = self:is_any_editable_visible()
	if not enable or not is_any_visible then
		self._edit_panel:set_visible(false)
		self._info_frame:set_visible(true)
	end
	self._edit_panel:layout()
	self._lower_panel:layout()
end
function CoreEditor:check_has_editables(unit, units)
	return false
end
function CoreEditor:is_any_editable_visible()
	return false
end
function CoreEditor:category_name(n)
	n = string.gsub(n, "_", " ")
	n = string.upper(string.sub(n, 1, 1)) .. string.sub(n, 2)
	local s = ""
	local toupper = false
	for i = 1, string.len(n) do
		if toupper then
			toupper = false
			s = s .. string.upper(string.sub(n, i, i))
		else
			s = s .. string.sub(n, i, i)
		end
		if string.sub(n, i, i) == " " then
			toupper = true
		end
	end
	return s
end
function CoreEditor:selected_unit()
	if self._current_layer and self._current_layer:selected_unit() then
		return self._current_layer:selected_unit()
	end
end
function CoreEditor:select_units(units)
	local id = Profiler:start("select_units")
	local layers = {}
	for _, unit in ipairs(units) do
		local layer = self:unit_in_layer(unit)
		if layer then
			if layers[layer] then
				table.insert(layers[layer], unit)
			else
				layers[layer] = {unit}
			end
		end
	end
	for layer, units in pairs(layers) do
		layer:set_selected_units(units)
	end
	Profiler:stop(id)
	Profiler:counter_time("select_units")
end
function CoreEditor:select_group(group)
	self._current_layer:select_group(group)
end
function CoreEditor:center_view_on_unit(unit)
	if alive(unit) then
		local rot = Rotation:look_at(managers.editor:camera_position(), unit:position(), Vector3(0, 0, 1))
		local pos = unit:position() - rot:y() * unit:bounding_sphere_radius() * 2
		managers.editor:set_camera(pos, rot)
	end
end
function CoreEditor:change_layer_based_on_unit(unit)
	if not unit then
		return
	end
	local ud = CoreEngineAccess._editor_unit_data(unit:name():id())
	for layer_name, layer in pairs(self._layers) do
		for _, u_type in ipairs(layer:unit_types()) do
			if ud:type():s() == u_type then
				for i = 0, self._notebook:get_page_count() - 1 do
					if self._notebook:get_page_text(i) == layer_name then
						self._notebook:set_page(i)
					end
				end
			end
		end
	end
end
function CoreEditor:unit_in_layer(unit)
	for _, layer in pairs(self._layers) do
		if table.contains(layer:created_units(), unit) then
			return layer
		end
	end
end
function CoreEditor:unit_in_layer_name(unit)
	for name, layer in pairs(self._layers) do
		if table.contains(layer:created_units(), unit) then
			return name
		end
	end
end
function CoreEditor:delete_unit(unit)
	self:unit_in_layer(unit):delete_unit(unit)
end
function CoreEditor:delete_selected_unit()
	if self._current_layer then
		self._current_layer:delete_unit(self._current_layer:selected_unit())
	end
end
function CoreEditor:unit_with_id(id)
	for _, layer in pairs(self._layers) do
		for _, unit in ipairs(layer:created_units()) do
			if unit:unit_data().unit_id == id then
				return unit
			end
		end
	end
end
function CoreEditor:mission_element_panel()
	return self._layers[self._mission_layer_name]:missionelement_panel()
end
function CoreEditor:hub_element_panel()
	Application:stack_dump_error("CoreEditor:hub_element_panel is deprecated, use CoreEditor:mission_element_panel instead.")
	return self:mission_element_panel()
end
function CoreEditor:mission_element_sizer()
	return self._layers[self._mission_layer_name]:missionelement_sizer()
end
function CoreEditor:hub_element_sizer()
	Application:stack_dump_error("CoreEditor:hub_element_sizer is deprecated, use CoreEditor:mission_element_sizer instead.")
	return self:mission_element_sizer()
end
function CoreEditor:create_continent(name, values)
	if self._continents[name] then
		self._continents[name]:load_values(values)
		self._continents_panel:update_continent_panel(self._continents[name])
		return self._continents[name]
	end
	values.base_id = values.base_id or self:_new_base_id()
	self._continents[name] = CoreEditorContinent:new(name, values)
	local continent = self._continents[name]
	self._continents_panel:add_continent({
		visible = continent:value("visible"),
		locked = continent:value("locked"),
		enabled_in_simulation = continent:value("enabled_in_simulation"),
		editor_only = continent:value("editor_only"),
		continent = continent
	})
	self:set_continent(name)
	self._values[name] = {}
	self._values[name].workviews = {}
	self:_recreate_dialogs()
	return self._continents[name]
end
function CoreEditor:_new_base_id()
	local i = 100000
	while not self:_base_id_availible(i) do
		i = i + 100000
	end
	return i
end
function CoreEditor:_base_id_availible(id)
	for _, continent in pairs(self._continents) do
		if continent:value("base_id") == id then
			return false
		end
	end
	return true
end
function CoreEditor:delete_continent(name)
	local continent = name and self._continents[name] or self._current_continent
	if not continent then
		return
	end
	name = name or continent:name()
	if name == "world" then
		EWS:message_box(Global.frame_panel, "Continent " .. name .. " can currently not be deleted", "Continent", "OK,ICON_INFORMATION", Vector3(-1, -1, 0))
		return
	end
	local confirm = EWS:message_box(Global.frame_panel, "Delete continent " .. name .. "? This will delete all units in the continent.", "Continent", "YES_NO,ICON_QUESTION", Vector3(-1, -1, 0))
	if confirm == "NO" then
		return
	end
	continent:delete()
	self._continents_panel:destroy_continent(continent)
	if continent == self._current_continent then
		self:set_continent("world")
	end
	self._continents[name] = nil
	self:_recreate_dialogs()
end
function CoreEditor:set_continent(name)
	local changed = not self._current_continent or self._current_continent ~= self._continents[name]
	self._current_continent = self._continents[name]
	self._continents_panel:set_continent(self._current_continent)
	if not changed then
		return
	end
	for _, layer in pairs(self._layers) do
		if layer:uses_continents() then
			layer:clear_selected_units()
		end
	end
end
function CoreEditor:current_continent()
	return self._current_continent
end
function CoreEditor:current_continent_name()
	return self:current_continent() and self:current_continent():name()
end
function CoreEditor:continents()
	return self._continents
end
function CoreEditor:continent(name)
	return self._continents[name]
end
function CoreEditor:add_unit_to_continent(name, unit)
	self._continents[name]:add_unit(unit)
end
function CoreEditor:change_continent_for_unit(unit, continent)
	unit:unit_data().continent:remove_unit(unit)
	continent:add_unit(unit)
end
function CoreEditor:change_continent_by_unit()
	local ray = self:unit_by_raycast({
		mask = managers.slot:get_mask("all"),
		sample = true,
		ray_type = "body editor"
	})
	if ray and ray.unit and ray.unit:unit_data().continent then
		self:set_continent(ray.unit:unit_data().continent:name())
	end
end
function CoreEditor:simulation_world_setting_path()
	return self._simulation_world_setting_path
end
function CoreEditor:set_simulation_world_setting_path(path)
	if path and not DB:has("world_setting", path) then
		local confirm = EWS:message_box(Global.frame_panel, "Can't set simulation world setting path to " .. path, "Continent", "OK,ICON_ERROR", Vector3(-1, -1, 0))
		return
	end
	self._simulation_world_setting_path = path
	self._continents_panel:set_world_setting_path(self._simulation_world_setting_path)
end
function CoreEditor:parse_simulation_world_setting_path(path)
	local settings = SystemFS:parse_xml(managers.database:entry_expanded_path("world_setting", path))
	if settings:name() == "settings" then
		local t = {}
		for continent in settings:children() do
			t[continent:parameter("name")] = toboolean(continent:parameter("exclude"))
		end
		return t
	else
		return PackageManager:editor_load_script_data(("world_setting"):id(), path:id())
	end
end
function CoreEditor:values(continent)
	return continent and self._values[continent] or self._values
end
function CoreEditor:add_workview(name)
	local continent = self:current_continent_name()
	self._values[continent].workviews[name] = {
		position = self:camera():position(),
		rotation = self:camera():rotation(),
		text = ""
	}
	if self._dialogs.workview_by_name then
		self._dialogs.workview_by_name:workview_added()
	end
end
function CoreEditor:goto_workview(view)
	self:set_camera(view.position, view.rotation)
end
function CoreEditor:delete_workview(continent, view_name)
	self._values[continent].workviews[view_name] = nil
end
function CoreEditor:set_ruler_points()
	if not shift() then
		return
	end
	if not self._ruler_points then
		self._ruler_points = {}
	end
	local ray = self:select_unit_by_raycast(managers.slot:get_mask("all"), "body editor")
	if not ray or not ray.position then
		return
	end
	if #self._ruler_points == 0 then
		table.insert(self._ruler_points, ray.position)
		self:set_value_info_visibility(true)
	else
		self:set_value_info_visibility(false)
		self._ruler_points = {}
	end
end
function CoreEditor:add_special_unit(unit, for_layer)
	self._special_units[unit:key()] = for_layer
end
function CoreEditor:dump_mesh(...)
	CoreEditorUtils.dump_mesh(...)
end
function CoreEditor:dump_all(...)
	CoreEditorUtils.dump_all(...)
end
function CoreEditor:destroy()
	if self._editor_data.virtual_controller then
		Input:destroy_virtual_controller(self._editor_data.virtual_controller)
	end
	if self._ctrl then
		Input:destroy_virtual_controller(self._ctrl)
	end
	if self._listener_id then
		managers.listener:remove_listener(self._listener_id)
		managers.listener:remove_set("editor")
		self._listener_id = nil
	end
	if self._vp then
		self._vp:destroy()
		self._vp = nil
	end
end
CoreEditorContinent = CoreEditorContinent or class()
function CoreEditorContinent:init(name, values)
	self._unit_ids = {}
	self._name = name
	self._need_saving = true
	self._units = {}
	self._values = {}
	self._values.name = name
	self:load_values(values)
end
function CoreEditorContinent:load_values(values)
	self._values.base_id = values.base_id
	self._values.visible = values.visible or values.visible == nil and true
	self._values.enabled = values.enabled or values.enabled == nil and true
	self._values.locked = values.locked or values.locked == nil and false
	self._values.enabled_in_simulation = values.enabled_in_simulation or values.enabled_in_simulation == nil and true
	self._values.editor_only = values.editor_only or values.editor_only == nil and false
end
function CoreEditorContinent:values()
	return self._values
end
function CoreEditorContinent:base_id()
	return self._values.base_id
end
function CoreEditorContinent:get_unit_id(unit)
	local i = self._values.base_id
	while self._unit_ids[i] do
		i = i + 1
	end
	unit:unit_data().unit_id = i
	self:register_unit_id(unit)
	return i
end
function CoreEditorContinent:register_unit_id(unit)
	self._unit_ids[unit:unit_data().unit_id] = unit
end
function CoreEditorContinent:remove_unit_id(unit)
	self._unit_ids[unit:unit_data().unit_id] = nil
end
function CoreEditorContinent:name()
	return self._name
end
function CoreEditorContinent:set_name(name)
	self._name = name
end
function CoreEditorContinent:set_need_saving(need_saving)
	self._need_saving = need_saving
end
function CoreEditorContinent:add_unit(unit)
	unit:unit_data().continent = self
	table.insert(self._units, unit)
	unit:set_enabled(not self._values.locked)
	self:set_need_saving(true)
end
function CoreEditorContinent:remove_unit(unit)
	table.delete(self._units, unit)
	self:set_need_saving(true)
end
function CoreEditorContinent:set_visible(visible)
	self._values.visible = visible
	for _, unit in ipairs(self._units) do
		managers.editor:set_unit_visible(unit, self._values.visible)
	end
end
function CoreEditorContinent:set_simulation_state(exclude)
	local enabled = self._values.enabled_in_simulation and not exclude
	if not self._values.locked and enabled or self._values.locked and not enabled then
		return
	end
	for _, unit in ipairs(self._units) do
		unit:set_enabled(enabled)
	end
end
function CoreEditorContinent:set_locked(locked)
	self._values.locked = locked
	for _, unit in ipairs(self._units) do
		unit:set_enabled(not locked)
		if locked then
			managers.editor:unselect_unit(unit)
		end
	end
	managers.editor:reset_dialog("select_by_name")
end
function CoreEditorContinent:set_enabled(enabled)
	self._values.enabled = enabled
	for _, unit in ipairs(self._units) do
		unit:set_enabled(enabled)
	end
end
function CoreEditorContinent:set_enabled_in_simulation(enabled_in_simulation)
	self:set_value("enabled_in_simulation", enabled_in_simulation)
end
function CoreEditorContinent:set_editor_only(editor_only)
	self:set_value("editor_only", editor_only)
end
function CoreEditorContinent:set_value(value, new_value)
	self._values[value] = new_value
end
function CoreEditorContinent:value(value)
	return self._values[value]
end
function CoreEditorContinent:delete()
	for _, unit in ipairs(clone(self._units)) do
		managers.editor:delete_unit(unit)
	end
end
