core:module("CoreFreeFlight")
core:import("CoreEvent")
core:import("CoreApp")
core:import("CoreFreeFlightAction")
core:import("CoreFreeFlightModifier")
core:from_module_import("CoreManagerBase", "PRIO_FREEFLIGHT")
local FF_ON, FF_OFF, FF_ON_NOCON = 0, 1, 2
local MOVEMENT_SPEED_BASE = 1000
local TURN_SPEED_BASE = 1
local FAR_RANGE_MAX = 250000
local PITCH_LIMIT_MIN = -80
local PITCH_LIMIT_MAX = 80
local TEXT_FADE_TIME = 0.3
local TEXT_ON_SCREEN_TIME = 2
local FREEFLIGHT_HEADER_TEXT = "FREEFLIGHT, PRESS 'F' OR 'C'"
local DESELECTED = Color(0.5, 0.5, 0.5)
local SELECTED = Color(1, 1, 1)
FreeFlight = FreeFlight or class()
function FreeFlight:init(gsm, viewport_manager, controller_manager)
	assert(gsm)
	assert(viewport_manager)
	assert(controller_manager)
	self._state = FF_OFF
	self._gsm = gsm
	self._vpm = viewport_manager
	self._keyboard = Input:keyboard()
	self._mouse = Input:mouse()
	self._rot = Rotation()
	self._pos = Vector3(0, 0, 1000)
	self:_setup_F9_key()
	self:_setup_modifiers()
	self:_setup_actions()
	self:_setup_viewport(viewport_manager)
	self:_setup_controller(controller_manager)
	self:_setup_gui()
end
function FreeFlight:_setup_F9_key()
	if Global.DEBUG_MENU_ON or Application:production_build() then
		local keyboard = Input:keyboard()
		if keyboard and keyboard:has_button(Idstring("f9")) then
			self._f9_con = Input:create_virtual_controller()
			self._f9_con:connect(keyboard, Idstring("f9"), Idstring("btn_toggle"))
			self._f9_con:add_trigger(Idstring("btn_toggle"), callback(self, self, "_on_F9"))
		end
	end
end
function FreeFlight:_setup_modifiers()
	local FFM = CoreFreeFlightModifier.FreeFlightModifier
	local ms = FFM:new("MOVE SPEED", {
		0.02,
		0.05,
		0.1,
		0.2,
		0.3,
		0.4,
		0.5,
		1,
		2,
		3,
		4,
		5,
		8,
		11,
		14,
		18,
		25,
		30,
		40,
		50,
		60,
		70,
		80,
		100,
		120,
		140,
		160,
		180,
		200
	}, 9)
	local ts = FFM:new("TURN SPEED", {
		1,
		2,
		3,
		4,
		5,
		6,
		7,
		8,
		9,
		10
	}, 5)
	local gt = FFM:new("GAME TIMER", {
		0.1,
		0.2,
		0.3,
		0.4,
		0.5,
		0.6,
		0.7,
		0.8,
		0.9,
		1,
		1.1,
		1.2,
		1.3,
		1.4,
		1.5,
		1.6,
		1.7,
		1.8,
		1.9,
		2,
		2.5,
		3,
		3.5,
		4,
		4.5,
		5
	}, 10, callback(self, self, "_set_game_timer"))
	local fov = FFM:new("FOV", {
		10,
		20,
		30,
		40,
		50,
		55,
		60,
		65,
		70,
		75
	}, 10, callback(self, self, "_set_fov"))
	self._modifiers = {
		ms,
		ts,
		gt,
		fov
	}
	self._modifier_index = 1
	self._fov = fov
	self._move_speed = ms
	self._turn_speed = ts
end
function FreeFlight:_setup_actions()
	local FFA = CoreFreeFlightAction.FreeFlightAction
	local FFAT = CoreFreeFlightAction.FreeFlightActionToggle
	local dp = FFA:new("DROP PLAYER", callback(self, self, "_drop_player"))
	local pd = FFA:new("POSITION DEBUG", callback(self, self, "_position_debug"))
	local yc = FFA:new("YIELD CONTROL (F9 EXIT)", callback(self, self, "_yield_control"))
	local ef = FFA:new("EXIT FREEFLIGHT", callback(self, self, "_exit_freeflight"))
	local ps = FFAT:new("PAUSE", "UNPAUSE", callback(self, self, "_pause"), callback(self, self, "_unpause"))
	local ff = FFAT:new("FRUSTUM FREEZE", "FRUSTUM UNFREEZE", callback(self, self, "_frustum_freeze"), callback(self, self, "_frustum_unfreeze"))
	self._actions = {
		ps,
		dp,
		pd,
		yc,
		ff,
		ef
	}
	self._action_index = 1
end
function FreeFlight:_setup_viewport(viewport_manager)
	self._camera_object = World:create_camera()
	self._camera_object:set_far_range(FAR_RANGE_MAX)
	self._camera_object:set_fov(self._fov:value())
	self._vp = viewport_manager:new_vp(0, 0, 1, 1, "freeflight", PRIO_FREEFLIGHT)
	self._vp:set_camera(self._camera_object)
	self._camera_pos = self._camera_object:position()
	self._camera_rot = self._camera_object:rotation()
end
function FreeFlight:_setup_controller(controller_manager)
	self._con = controller_manager:create_controller("freeflight", nil, true, PRIO_FREEFLIGHT)
	self._con:add_trigger("freeflight_action_toggle", callback(self, self, "_action_toggle"))
	self._con:add_trigger("freeflight_action_execute", callback(self, self, "_action_execute"))
	self._con:add_trigger("freeflight_modifier_toggle", callback(self, self, "_next_modifier_toggle"))
	self._con:add_trigger("freeflight_modifier_up", callback(self, self, "_curr_modifier_up"))
	self._con:add_trigger("freeflight_modifier_down", callback(self, self, "_curr_modifier_down"))
end
function FreeFlight:_setup_gui()
	local gui_scene = Overlay:gui()
	local res = RenderSettings.resolution
	self._workspace = gui_scene:create_screen_workspace()
	self._workspace:set_timer(TimerManager:main())
	self._panel = self._workspace:panel()
	local SCREEN_RIGHT_OFFSET = 420
	local TEXT_HEIGHT_OFFSET = 27
	local config = {}
	config.font = "core/fonts/system_font"
	config.font_scale = 0.9
	config.color = DESELECTED
	config.x = 45
	config.y = 25
	config.layer = 1000000
	local function anim_fade_out_func(o)
		CoreEvent.over(TEXT_FADE_TIME, function(t)
			o:set_color(o:color():with_alpha(1 - t))
		end)
	end
	local function anim_fade_in_func(o)
		CoreEvent.over(TEXT_FADE_TIME, function(t)
			o:set_color(o:color():with_alpha(t))
		end)
	end
	local text_script = {fade_out = anim_fade_out_func, fade_in = anim_fade_in_func}
	self._action_gui = {}
	self._action_vis_time = nil
	for i, a in ipairs(self._actions) do
		local text = self._panel:text(config)
		text:set_script(text_script)
		text:set_text(a:name())
		text:set_y(text:y() + i * TEXT_HEIGHT_OFFSET)
		if i == self._action_index then
			text:set_color(SELECTED)
		end
		text:set_color(text:color():with_alpha(0))
		table.insert(self._action_gui, text)
	end
	self._modifier_gui = {}
	self._modifier_vis_time = nil
	for i, m in ipairs(self._modifiers) do
		local text = self._panel:text(config)
		text:set_script(text_script)
		text:set_text(m:name_value())
		text:set_y(text:y() + i * TEXT_HEIGHT_OFFSET)
		text:set_x(res.x - SCREEN_RIGHT_OFFSET)
		if i == self._modifier_index then
			text:set_color(SELECTED)
		end
		text:set_color(text:color():with_alpha(0))
		table.insert(self._modifier_gui, text)
	end
	self._workspace:hide()
end
function FreeFlight:enable()
	if self._gsm:current_state():allow_freeflight() then
		local active_vp = self._vpm:first_active_viewport()
		if active_vp then
			local env = active_vp:environment_mixer():current_environment()
			self._vp:environment_mixer():set_environment(env)
			self._start_cam = active_vp:camera()
			if self._start_cam then
				self:_set_camera(self._start_cam:position(), self._start_cam:rotation())
			end
		end
		self._state = FF_ON
		self._vp:set_active(true)
		self._con:enable()
		self._workspace:show()
		self:_draw_actions()
		self:_draw_modifiers()
		if managers.enemy then
			managers.enemy:set_gfx_lod_enabled(false)
		end
	end
end
function FreeFlight:disable()
	for _, a in ipairs(self._actions) do
		a:reset()
	end
	self._state = FF_OFF
	self._con:disable()
	self._workspace:hide()
	self._vp:set_active(false)
	if managers.enemy then
		managers.enemy:set_gfx_lod_enabled(true)
	end
end
function FreeFlight:enabled()
	return self._state ~= FF_OFF
end
function FreeFlight:_on_F9()
	if self._state == FF_ON then
		self:disable()
	elseif self._state == FF_OFF then
		self:enable()
	elseif self._state == FF_ON_NOCON then
		self._state = FF_ON
		self._con:enable()
	end
end
function FreeFlight:_action_toggle()
	if self:_actions_are_visible() then
		self._action_gui[self._action_index]:set_color(DESELECTED)
		self._action_index = self._action_index % #self._actions + 1
		self._action_gui[self._action_index]:set_color(SELECTED)
	end
	self:_draw_actions()
end
function FreeFlight:_action_execute()
	if self:_actions_are_visible() then
		self:_current_action():do_action()
	end
	self:_draw_actions()
end
function FreeFlight:_exit_freeflight()
	self:disable()
end
function FreeFlight:_yield_control()
	assert(self._state == FF_ON)
	self._state = FF_ON_NOCON
	self._con:disable()
end
function FreeFlight:_drop_player()
	local rot_new = Rotation(self._camera_rot:yaw(), 0, 0)
	self._gsm:current_state():freeflight_drop_player(self._camera_pos, rot_new)
end
function FreeFlight:_position_debug()
	local p = self._camera_pos
	cat_print("debug", "CAMERA POSITION: Vector3(" .. p.x .. "," .. p.y .. "," .. p.z .. ")")
end
function FreeFlight:_pause()
	Application:set_pause(true)
end
function FreeFlight:_unpause()
	Application:set_pause(false)
end
function FreeFlight:_frustum_freeze()
	local old_cam = self._camera_object
	local new_cam = World:create_camera()
	new_cam:set_fov(old_cam:fov())
	new_cam:set_position(old_cam:position())
	new_cam:set_rotation(old_cam:rotation())
	new_cam:set_far_range(old_cam:far_range())
	new_cam:set_near_range(old_cam:near_range())
	new_cam:set_aspect_ratio(old_cam:aspect_ratio())
	new_cam:set_width_multiplier(old_cam:width_multiplier())
	if self._start_cam then
		old_cam:set_far_range(self._start_cam:far_range())
	end
	Application:set_frustum_freeze_camera(old_cam, new_cam)
	self._frozen_camera = old_cam
	self._camera_object = new_cam
end
function FreeFlight:_frustum_unfreeze()
	local old_cam = self._frozen_camera
	old_cam:set_far_range(FAR_RANGE_MAX)
	Application:set_frustum_freeze_camera(old_cam, old_cam)
	self._camera_object = old_cam
	self._frozen_camera = nil
end
function FreeFlight:_next_modifier_toggle()
	if self:_modifiers_are_visible() then
		self._modifier_gui[self._modifier_index]:set_color(DESELECTED)
		self._modifier_index = self._modifier_index % #self._modifiers + 1
		self._modifier_gui[self._modifier_index]:set_color(SELECTED)
	end
	self:_draw_modifiers()
end
function FreeFlight:_curr_modifier_up()
	if self:_modifiers_are_visible() then
		self:_current_modifier():step_up()
		self._modifier_gui[self._modifier_index]:set_text(self:_current_modifier():name_value())
	end
	self:_draw_modifiers()
end
function FreeFlight:_curr_modifier_down()
	if self:_modifiers_are_visible() then
		self:_current_modifier():step_down()
		self._modifier_gui[self._modifier_index]:set_text(self:_current_modifier():name_value())
	end
	self:_draw_modifiers()
end
function FreeFlight:_set_fov(value)
	self._camera_object:set_fov(value)
end
function FreeFlight:_set_game_timer(value)
	TimerManager:game():set_multiplier(value)
	TimerManager:game_animation():set_multiplier(value)
end
function FreeFlight:_current_action()
	return self._actions[self._action_index]
end
function FreeFlight:_current_modifier()
	return self._modifiers[self._modifier_index]
end
function FreeFlight:_actions_are_visible()
	local t = TimerManager:main():time()
	return self._action_vis_time and t + TEXT_FADE_TIME < self._action_vis_time
end
function FreeFlight:_modifiers_are_visible()
	local t = TimerManager:main():time()
	return self._modifier_vis_time and t + TEXT_FADE_TIME < self._modifier_vis_time
end
function FreeFlight:_draw_actions()
	if not self:_actions_are_visible() then
		for i, text in ipairs(self._action_gui) do
			text:stop()
			text:animate(text:script().fade_in)
		end
	end
	for i, _ in ipairs(self._actions) do
		self._action_gui[i]:set_text(self._actions[i]:name())
	end
	self._action_vis_time = TimerManager:main():time() + TEXT_ON_SCREEN_TIME
end
function FreeFlight:_draw_modifiers()
	if not self:_modifiers_are_visible() then
		for _, text in ipairs(self._modifier_gui) do
			text:stop()
			text:animate(text:script().fade_in)
		end
	end
	self._modifier_vis_time = TimerManager:main():time() + TEXT_ON_SCREEN_TIME
end
function FreeFlight:_set_camera(pos, rot)
	self._camera_object:set_position(pos)
	self._camera_object:set_rotation(rot)
	self._camera_pos = pos
	self._camera_rot = rot
end
function FreeFlight:update(t, dt)
	local main_t = TimerManager:main():time()
	local main_dt = TimerManager:main():delta_time()
	if self:enabled() then
		self:_update_controller(main_t, main_dt)
		self:_update_gui(main_t, main_dt)
		self:_update_camera(main_t, main_dt)
		self:_update_frustum_debug_box(main_t, main_dt)
	end
end
function FreeFlight:_update_controller(t, dt)
end
function FreeFlight:_update_gui(t, dt)
	if self._action_vis_time and t > self._action_vis_time then
		for _, text in ipairs(self._action_gui) do
			text:stop()
			text:animate(text:script().fade_out)
		end
		self._action_vis_time = nil
	end
	if self._modifier_vis_time and t > self._modifier_vis_time then
		for _, text in ipairs(self._modifier_gui) do
			text:stop()
			text:animate(text:script().fade_out)
		end
		self._modifier_vis_time = nil
	end
end
function FreeFlight:_update_camera(t, dt)
	local axis_move = self._con:get_input_axis("freeflight_axis_move")
	local axis_look = self._con:get_input_axis("freeflight_axis_look")
	local btn_move_up = self._con:get_input_float("freeflight_move_up")
	local btn_move_down = self._con:get_input_float("freeflight_move_down")
	local move_dir = self._camera_rot:x() * axis_move.x + self._camera_rot:y() * axis_move.y
	move_dir = move_dir + btn_move_up * Vector3(0, 0, 1) + btn_move_down * Vector3(0, 0, -1)
	local move_delta = move_dir * self._move_speed:value() * MOVEMENT_SPEED_BASE * dt
	local pos_new = self._camera_pos + move_delta
	local yaw_new = self._camera_rot:yaw() + axis_look.x * -1 * self._turn_speed:value() * TURN_SPEED_BASE
	local pitch_new = math.clamp(self._camera_rot:pitch() + axis_look.y * self._turn_speed:value() * TURN_SPEED_BASE, PITCH_LIMIT_MIN, PITCH_LIMIT_MAX)
	local rot_new = Rotation(yaw_new, pitch_new, 0)
	if not CoreApp.arg_supplied("-vpslave") then
		self:_set_camera(pos_new, rot_new)
	end
end
function FreeFlight:_update_frustum_debug_box(t, dt)
	if self._frozen_camera then
		local near = self._frozen_camera:near_range()
		local far = self._frozen_camera:far_range()
		local R, G, B = 1, 0, 1
		local n1 = self._frozen_camera:screen_to_world(Vector3(-1, -1, near))
		local n2 = self._frozen_camera:screen_to_world(Vector3(1, -1, near))
		local n3 = self._frozen_camera:screen_to_world(Vector3(1, 1, near))
		local n4 = self._frozen_camera:screen_to_world(Vector3(-1, 1, near))
		local f1 = self._frozen_camera:screen_to_world(Vector3(-1, -1, far))
		local f2 = self._frozen_camera:screen_to_world(Vector3(1, -1, far))
		local f3 = self._frozen_camera:screen_to_world(Vector3(1, 1, far))
		local f4 = self._frozen_camera:screen_to_world(Vector3(-1, 1, far))
		Application:draw_line(n1, n2, R, G, B)
		Application:draw_line(n2, n3, R, G, B)
		Application:draw_line(n3, n4, R, G, B)
		Application:draw_line(n4, n1, R, G, B)
		Application:draw_line(n1, f1, R, G, B)
		Application:draw_line(n2, f2, R, G, B)
		Application:draw_line(n3, f3, R, G, B)
		Application:draw_line(n4, f4, R, G, B)
		Application:draw_line(f1, f2, R, G, B)
		Application:draw_line(f2, f3, R, G, B)
		Application:draw_line(f3, f4, R, G, B)
		Application:draw_line(f4, f1, R, G, B)
	end
end
function FreeFlight:destroy()
	if alive(self._con_toggle) then
		Input:destroy_virtual_controller(self._con_toggle)
		self._con_toggle = nil
	end
	if alive(self._con) then
		self._con:destroy()
		self._con = nil
	end
	self._vp:destroy()
	self._vp = nil
end
