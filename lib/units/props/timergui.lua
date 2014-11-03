TimerGui = TimerGui or class()
function TimerGui:init(unit)
	self._unit = unit
	self._visible = true
	self._powered = true
	self._jam_times = 3
	self._jammed = false
	self._can_jam = false
	self._gui_start = self._gui_start or "prop_timer_gui_start"
	self._gui_working = "prop_timer_gui_working"
	self._gui_malfunction = "prop_timer_gui_malfunction"
	self._gui_done = "prop_timer_gui_done"
	self._cull_distance = self._cull_distance or 5000
	self._size_multiplier = self._size_multiplier or 1
	self._gui_object = self._gui_object or "gui_name"
	self._new_gui = World:newgui()
	self:add_workspace(self._unit:get_object(Idstring(self._gui_object)))
	self:setup()
	self._unit:set_extension_update_enabled(Idstring("timer_gui"), false)
	self._update_enabled = false
end
function TimerGui:add_workspace(gui_object)
	self._ws = self._new_gui:create_object_workspace(0, 0, gui_object, Vector3(0, 0, 0))
	self._gui = self._ws:panel():gui(Idstring("guis/timer_gui"))
	self._gui_script = self._gui:script()
end
function TimerGui:setup()
	self._gui_script.working_text:set_render_template(Idstring("VertexColorTextured"))
	self._gui_script.time_header_text:set_render_template(Idstring("VertexColorTextured"))
	self._gui_script.time_text:set_render_template(Idstring("VertexColorTextured"))
	self._gui_script.drill_screen_background:set_size(self._gui_script.drill_screen_background:parent():size())
	self._gui_script.timer:set_h(120 * self._size_multiplier)
	self._gui_script.timer:set_w(self._gui_script.timer:parent():w() - self._gui_script.timer:parent():w() / 5)
	self._gui_script.timer:set_center_x(self._gui_script.timer:parent():w() / 2)
	self._gui_script.timer:set_center_y(self._gui_script.timer:parent():h() / 2)
	self._timer_lenght = self._gui_script.timer:w()
	self._gui_script.timer_background:set_h(self._gui_script.timer:h() + 20 * self._size_multiplier)
	self._gui_script.timer_background:set_w(self._gui_script.timer:w() + 20 * self._size_multiplier)
	self._gui_script.timer_background:set_center(self._gui_script.timer:center())
	self._gui_script.timer:set_w(0)
	self._gui_script.working_text:set_center_x(self._gui_script.working_text:parent():w() / 2)
	self._gui_script.working_text:set_center_y(self._gui_script.working_text:parent():h() / 4)
	self._gui_script.working_text:set_font_size(110 * self._size_multiplier)
	self._gui_script.working_text:set_text(managers.localization:text(self._gui_start))
	self._gui_script.working_text:set_visible(true)
	self._gui_script.time_header_text:set_font_size(80 * self._size_multiplier)
	self._gui_script.time_header_text:set_visible(false)
	self._gui_script.time_header_text:set_center_x(self._gui_script.working_text:parent():w() / 2)
	self._gui_script.time_header_text:set_center_y(self._gui_script.working_text:parent():h() / 1.35)
	self._gui_script.time_text:set_font_size(110 * self._size_multiplier)
	self._gui_script.time_text:set_visible(false)
	self._gui_script.time_text:set_center_x(self._gui_script.working_text:parent():w() / 2)
	self._gui_script.time_text:set_center_y(self._gui_script.working_text:parent():h() / 1.15)
	self._original_colors = {}
	for _, child in ipairs(self._gui_script.panel:children()) do
		self._original_colors[child:key()] = child:color()
	end
end
function TimerGui:_start(timer, current_timer)
	self._started = true
	self._done = false
	self._timer = timer or 5
	self._current_timer = current_timer or self._timer
	self._gui_script.timer:set_w(self._timer_lenght * (1 - self._current_timer / self._timer))
	self._gui_script.working_text:set_text(managers.localization:text(self._gui_working))
	self._unit:set_extension_update_enabled(Idstring("timer_gui"), true)
	self._update_enabled = true
	self:post_event(self._start_event)
	self._gui_script.time_header_text:set_visible(true)
	self._gui_script.time_text:set_visible(true)
	self._gui_script.time_text:set_text(math.floor(self._current_timer) .. " " .. managers.localization:text("prop_timer_gui_seconds"))
	self._unit:base():start()
	if Network:is_client() then
		return
	end
	self:_set_jamming_values()
end
function TimerGui:_set_jamming_values()
	if not self._can_jam then
		return
	end
	self._jamming_intervals = {}
	local jammed_times = math.random(self._jam_times)
	local interval = self._timer / jammed_times
	for i = 1, jammed_times do
		local start = interval / 2
		self._jamming_intervals[i] = start + math.rand(start / 1.25)
	end
	self._current_jam_timer = table.remove(self._jamming_intervals, 1)
end
function TimerGui:start(timer)
	if self._jammed then
		self:_set_jammed(false)
		return
	end
	if self._started then
		return
	end
	self:_start(timer)
	if managers.network:session() then
		managers.network:session():send_to_peers_synched("start_timer_gui", self._unit, timer)
	end
end
function TimerGui:sync_start(timer)
	self:_start(timer)
end
function TimerGui:update(unit, t, dt)
	if self._jammed then
		self._gui_script.drill_screen_background:set_color(self._gui_script.drill_screen_background:color():with_alpha(0.5 + (math.sin(t * 750) + 1) / 4))
		return
	end
	if not self._powered then
		return
	end
	if self._current_jam_timer then
		self._current_jam_timer = self._current_jam_timer - dt
		if self._current_jam_timer <= 0 then
			self:set_jammed(true)
			self._current_jam_timer = table.remove(self._jamming_intervals, 1)
			return
		end
	end
	self._current_timer = self._current_timer - dt
	self._gui_script.time_text:set_text(math.floor(self._current_timer) .. " " .. managers.localization:text("prop_timer_gui_seconds"))
	self._gui_script.timer:set_w(self._timer_lenght * (1 - self._current_timer / self._timer))
	if 0 >= self._current_timer then
		self._unit:set_extension_update_enabled(Idstring("timer_gui"), false)
		self._update_enabled = false
		self:done()
	else
		self._gui_script.working_text:set_color(self._gui_script.working_text:color():with_alpha(0.5 + (math.sin(t * 750) + 1) / 4))
	end
end
function TimerGui:set_visible(visible)
	self._visible = visible
	self._gui:set_visible(visible)
end
function TimerGui:sync_set_jammed(jammed)
	self:_set_jammed(jammed)
end
function TimerGui:set_jammed(jammed)
	if jammed and self._unit:damage() and self._unit:damage():has_sequence("jammed_trigger") then
		self._unit:damage():run_sequence_simple("jammed_trigger")
	end
	if managers.network:session() then
		managers.network:session():send_to_peers_synched("set_jammed_timer_gui", self._unit, jammed)
	end
	self:_set_jammed(jammed)
end
function TimerGui:_set_jammed(jammed)
	self._jammed = jammed
	if self._jammed then
		if self._unit:damage():has_sequence("set_is_jammed") then
			self._unit:damage():run_sequence_simple("set_is_jammed")
		end
		for _, child in ipairs(self._gui_script.panel:children()) do
			local color = self._original_colors[child:key()]
			local c = Color(color.a, 1, 0, 0)
			child:set_color(c)
		end
		self._gui_script.working_text:set_text(managers.localization:text(self._gui_malfunction))
		self._gui_script.time_text:set_text(managers.localization:text("prop_timer_gui_error"))
		if self._unit:interaction() then
			if self._jammed_tweak_data then
				self._unit:interaction():set_tweak_data(self._jammed_tweak_data)
			end
			self._unit:interaction():set_active(true)
		end
		self:post_event(self._jam_event)
	else
		for _, child in ipairs(self._gui_script.panel:children()) do
			child:set_color(self._original_colors[child:key()])
		end
		self._gui_script.working_text:set_text(managers.localization:text(self._gui_working))
		self._gui_script.time_text:set_text(math.floor(self._current_timer) .. " " .. managers.localization:text("prop_timer_gui_seconds"))
		self._gui_script.drill_screen_background:set_color(self._gui_script.drill_screen_background:color():with_alpha(1))
		self:post_event(self._resume_event)
	end
	self._unit:base():set_jammed(jammed)
end
function TimerGui:set_powered(powered)
	self:_set_powered(powered)
end
function TimerGui:_set_powered(powered)
	self._powered = powered
	if not self._powered then
		for _, child in ipairs(self._gui_script.panel:children()) do
			local color = self._original_colors[child:key()]
			local c = Color(color.a, color.r * 0, color.g * 0, color.b * 0.25)
			child:set_color(c)
		end
		self:post_event(self._jam_event)
	else
		for _, child in ipairs(self._gui_script.panel:children()) do
			child:set_color(self._original_colors[child:key()])
		end
		self:post_event(self._resume_event)
	end
	self._unit:base():set_powered(powered)
end
function TimerGui:done()
	self:_set_done()
	if self._unit:damage() then
		self._unit:damage():run_sequence_simple("timer_done")
	end
	self:post_event(self._done_event)
end
function TimerGui:_set_done()
	self._done = true
	self._gui_script.timer:set_w(self._timer_lenght)
	self._gui_script.working_text:set_color(self._gui_script.working_text:color():with_alpha(1))
	self._gui_script.working_text:set_text(managers.localization:text(self._gui_done))
	self._gui_script.time_header_text:set_visible(false)
	self._gui_script.time_text:set_visible(false)
	self._unit:base():done()
end
function TimerGui:post_event(event)
	if not event then
		return
	end
	self._unit:sound_source():post_event(event)
end
function TimerGui:lock_gui()
	self._ws:set_cull_distance(self._cull_distance)
	self._ws:set_frozen(true)
end
function TimerGui:destroy()
	if alive(self._new_gui) and alive(self._ws) then
		self._new_gui:destroy_workspace(self._ws)
		self._ws = nil
		self._new_gui = nil
	end
end
function TimerGui:save(data)
	local state = {}
	state.update_enabled = self._update_enabled
	state.timer = self._timer
	state.current_timer = self._current_timer
	state.jammed = self._jammed
	state.powered = self._powered
	state.done = self._done
	state.visible = self._visible
	data.TimerGui = state
end
function TimerGui:load(data)
	local state = data.TimerGui
	if state.done then
		self:_set_done()
	elseif state.update_enabled then
		self:_start(state.timer, state.current_timer)
		if state.jammed then
			self:_set_jammed(state.jammed)
		end
		if not state.powered then
			self:_set_powered(state.powered)
		end
	end
	self:set_visible(state.visible)
end
