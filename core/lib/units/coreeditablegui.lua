CoreEditableGui = CoreEditableGui or class()
function CoreEditableGui:init(unit)
	self._unit = unit
	self._text = self._text or "Default Text"
	self._cull_distance = self._cull_distance or 5000
	self._sides = self._sides or 1
	self._gui_movie = self._gui_movie or "default_text"
	self._gui_object = self._gui_object or "gui_name"
	self._font = self._font or "core/fonts/diesel"
	self._gui = World:newgui()
	self._guis = {}
	if self._sides == 1 then
		self:add_workspace(self._unit:get_object(Idstring(self._gui_object)))
	else
		for i = 1, self._sides do
			self:add_workspace(self._unit:get_object(Idstring(self._gui_object .. i)))
		end
	end
	local text_object = self._guis[1].gui:child("std_text")
	self._font_size = text_object:font_size()
	self:set_font_size(self._font_size)
	self._font_color = Vector3(text_object:color().red, text_object:color().green, text_object:color().blue)
end
function CoreEditableGui:add_workspace(gui_object)
	local ws = self._gui:create_object_workspace(0, 0, gui_object, Vector3(0, 0, 0))
	local gui = ws:panel():gui(Idstring("core/guis/core_editable_gui"))
	local panel = gui:panel()
	gui:child("std_text"):set_font(Idstring(self._font))
	gui:child("std_text"):set_text(self._text)
	table.insert(self._guis, {
		workspace = ws,
		gui = gui,
		panel = panel
	})
end
function CoreEditableGui:text()
	return self._text
end
function CoreEditableGui:set_text(text)
	self._text = text
	for _, gui in ipairs(self._guis) do
		gui.gui:child("std_text"):set_text(self._text)
	end
end
function CoreEditableGui:font_size()
	return self._font_size
end
function CoreEditableGui:set_font_size(font_size)
	self._font_size = font_size
	for _, gui in ipairs(self._guis) do
		gui.gui:child("std_text"):set_font_size(self._font_size * (10 * gui.gui:child("std_text"):height() / 100))
	end
end
function CoreEditableGui:font_color()
	return self._font_color
end
function CoreEditableGui:set_font_color(font_color)
	self._font_color = font_color
	for _, gui in ipairs(self._guis) do
		gui.gui:child("std_text"):set_color(Color(1, font_color.x, font_color.y, font_color.z))
	end
end
function CoreEditableGui:lock_gui()
	for _, gui in ipairs(self._guis) do
		gui.workspace:set_cull_distance(self._cull_distance)
		gui.workspace:set_frozen(true)
	end
end
function CoreEditableGui:destroy()
	for _, gui in ipairs(self._guis) do
		if alive(self._gui) and alive(gui.workspace) then
			self._gui:destroy_workspace(gui.workspace)
		end
	end
	self._guis = nil
end
