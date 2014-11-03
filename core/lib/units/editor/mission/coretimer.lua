CoreTimerUnitElement = CoreTimerUnitElement or class(MissionElement)
TimerUnitElement = TimerUnitElement or class(CoreTimerUnitElement)
function TimerUnitElement:init(...)
	TimerUnitElement.super.init(self, ...)
end
function CoreTimerUnitElement:init(unit)
	CoreTimerUnitElement.super.init(self, unit)
	self._hed.timer = 0
	table.insert(self._save_values, "timer")
end
function CoreTimerUnitElement:_build_panel(panel, panel_sizer)
	self:_create_panel()
	panel = panel or self._panel
	panel_sizer = panel_sizer or self._panel_sizer
	local timer_params = {
		name = "Timer:",
		panel = panel,
		sizer = panel_sizer,
		value = self._hed.timer,
		floats = 1,
		tooltip = "Specifies how long time (in seconds) to wait before execute",
		min = 0,
		name_proportions = 1,
		ctrlr_proportions = 2,
		sorted = false
	}
	local timer = CoreEWS.number_controller(timer_params)
	timer:connect("EVT_COMMAND_TEXT_ENTER", callback(self, self, "set_element_data"), {ctrlr = timer, value = "timer"})
	timer:connect("EVT_KILL_FOCUS", callback(self, self, "set_element_data"), {ctrlr = timer, value = "timer"})
	local help = {}
	help.text = "Creates a timer element. When the timer runs out, execute will be run. The timer element can be operated on using the logic_timer_operator"
	help.panel = panel
	help.sizer = panel_sizer
	self:add_help_text(help)
end
CoreTimerOperatorUnitElement = CoreTimerOperatorUnitElement or class(MissionElement)
TimerOperatorUnitElement = TimerOperatorUnitElement or class(CoreTimerOperatorUnitElement)
function TimerOperatorUnitElement:init(...)
	TimerOperatorUnitElement.super.init(self, ...)
end
function CoreTimerOperatorUnitElement:init(unit)
	CoreTimerOperatorUnitElement.super.init(self, unit)
	self._hed.operation = "none"
	self._hed.time = 0
	self._hed.elements = {}
	table.insert(self._save_values, "operation")
	table.insert(self._save_values, "time")
	table.insert(self._save_values, "elements")
end
function CoreTimerOperatorUnitElement:draw_links(t, dt, selected_unit, all_units)
	CoreTimerOperatorUnitElement.super.draw_links(self, t, dt, selected_unit)
	for _, id in ipairs(self._hed.elements) do
		local unit = all_units[id]
		local draw = not selected_unit or unit == selected_unit or self._unit == selected_unit
		if draw then
			self:_draw_link({
				from_unit = self._unit,
				to_unit = unit,
				r = 0.75,
				g = 0.75,
				b = 0.25
			})
		end
	end
end
function CoreTimerOperatorUnitElement:update_editing()
end
function CoreTimerOperatorUnitElement:add_element()
	local ray = managers.editor:unit_by_raycast({mask = 10, ray_type = "editor"})
	if ray and ray.unit and ray.unit:name() == Idstring("core/units/mission_elements/logic_timer/logic_timer") then
		local id = ray.unit:unit_data().unit_id
		if table.contains(self._hed.elements, id) then
			table.delete(self._hed.elements, id)
		else
			table.insert(self._hed.elements, id)
		end
	end
end
function CoreTimerOperatorUnitElement:remove_links(unit)
	for _, id in ipairs(self._hed.elements) do
		if id == unit:unit_data().unit_id then
			table.delete(self._hed.elements, id)
		end
	end
end
function CoreTimerOperatorUnitElement:add_triggers(vc)
	vc:add_trigger(Idstring("lmb"), callback(self, self, "add_element"))
end
function CoreTimerOperatorUnitElement:_build_panel(panel, panel_sizer)
	self:_create_panel()
	panel = panel or self._panel
	panel_sizer = panel_sizer or self._panel_sizer
	local operation_params = {
		name = "Operation:",
		panel = panel,
		sizer = panel_sizer,
		default = "none",
		options = {
			"pause",
			"start",
			"add_time",
			"subtract_time",
			"reset",
			"set_time"
		},
		value = self._hed.operation,
		tooltip = "Select an operation for the selected elements",
		name_proportions = 1,
		ctrlr_proportions = 2,
		sorted = true
	}
	local operation = CoreEWS.combobox(operation_params)
	operation:connect("EVT_COMMAND_COMBOBOX_SELECTED", callback(self, self, "set_element_data"), {ctrlr = operation, value = "operation"})
	local time_params = {
		name = "Time:",
		panel = panel,
		sizer = panel_sizer,
		value = self._hed.time,
		floats = 1,
		tooltip = "Amount of time to add, subtract or set to the timers.",
		min = 0,
		name_proportions = 1,
		ctrlr_proportions = 2,
		sorted = false
	}
	local time = CoreEWS.number_controller(time_params)
	time:connect("EVT_COMMAND_TEXT_ENTER", callback(self, self, "set_element_data"), {ctrlr = time, value = "time"})
	time:connect("EVT_KILL_FOCUS", callback(self, self, "set_element_data"), {ctrlr = time, value = "time"})
	local help = {}
	help.text = "This element can modify logic_timer element. Select timers to modify using insert and clicking on the elements."
	help.panel = panel
	help.sizer = panel_sizer
	self:add_help_text(help)
end
CoreTimerTriggerUnitElement = CoreTimerTriggerUnitElement or class(MissionElement)
TimerTriggerUnitElement = TimerTriggerUnitElement or class(CoreTimerTriggerUnitElement)
function TimerTriggerUnitElement:init(...)
	TimerTriggerUnitElement.super.init(self, ...)
end
function CoreTimerTriggerUnitElement:init(unit)
	CoreTimerTriggerUnitElement.super.init(self, unit)
	self._hed.time = 0
	self._hed.elements = {}
	table.insert(self._save_values, "time")
	table.insert(self._save_values, "elements")
end
function CoreTimerTriggerUnitElement:draw_links(t, dt, selected_unit, all_units)
	CoreTimerTriggerUnitElement.super.draw_links(self, t, dt, selected_unit)
	for _, id in ipairs(self._hed.elements) do
		local unit = all_units[id]
		local draw = not selected_unit or unit == selected_unit or self._unit == selected_unit
		if draw then
			self:_draw_link({
				from_unit = unit,
				to_unit = self._unit,
				r = 0.85,
				g = 0.85,
				b = 0.25
			})
		end
	end
end
function CoreTimerTriggerUnitElement:update_editing()
end
function CoreTimerTriggerUnitElement:add_element()
	local ray = managers.editor:unit_by_raycast({mask = 10, ray_type = "editor"})
	if ray and ray.unit and ray.unit:name() == Idstring("core/units/mission_elements/logic_timer/logic_timer") then
		local id = ray.unit:unit_data().unit_id
		if table.contains(self._hed.elements, id) then
			table.delete(self._hed.elements, id)
		else
			table.insert(self._hed.elements, id)
		end
	end
end
function CoreTimerTriggerUnitElement:remove_links(unit)
	for _, id in ipairs(self._hed.elements) do
		if id == unit:unit_data().unit_id then
			table.delete(self._hed.elements, id)
		end
	end
end
function CoreTimerTriggerUnitElement:add_triggers(vc)
	vc:add_trigger(Idstring("lmb"), callback(self, self, "add_element"))
end
function CoreTimerTriggerUnitElement:_build_panel(panel, panel_sizer)
	self:_create_panel()
	panel = panel or self._panel
	panel_sizer = panel_sizer or self._panel_sizer
	local time_params = {
		name = "Time:",
		panel = panel,
		sizer = panel_sizer,
		value = self._hed.time,
		floats = 1,
		tooltip = "Specify how much time should be left on the timer to trigger.",
		min = 0,
		name_proportions = 1,
		ctrlr_proportions = 2,
		sorted = false
	}
	local time = CoreEWS.number_controller(time_params)
	time:connect("EVT_COMMAND_TEXT_ENTER", callback(self, self, "set_element_data"), {ctrlr = time, value = "time"})
	time:connect("EVT_KILL_FOCUS", callback(self, self, "set_element_data"), {ctrlr = time, value = "time"})
	local help = {}
	help.text = "This element is a trigger to logic_timer element."
	help.panel = panel
	help.sizer = panel_sizer
	self:add_help_text(help)
end
