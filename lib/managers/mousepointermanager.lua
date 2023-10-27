MousePointerManager = MousePointerManager or class()
function MousePointerManager:init()
	self:_setup()
end
function MousePointerManager:_setup()
	self._mouse_callbacks = {}
	self._id = 0
	self._ws = Overlay:gui():create_screen_workspace()
	local x, y = 640, 360
	self._ws:connect_mouse(Input:mouse())
	self._ws:feed_mouse_position(x, y)
	self._mouse = self._ws:panel():bitmap({
		texture = "guis/textures/mouse_pointer",
		name_s = "mouse",
		name = "mouse",
		texture_rect = {
			0,
			0,
			32,
			32
		},
		x = x,
		y = y,
		w = 32,
		h = 32,
		layer = tweak_data.gui.MOUSE_LAYER,
		color = Color(1, 0.7, 0.7, 0.7)
	})
	self._ws:hide()
end
function MousePointerManager:get_id()
	local id = "mouse_pointer_id" .. tostring(self._id)
	self._id = self._id + 1
	return id
end
function MousePointerManager:use_mouse(params)
	if managers.controller:get_default_wrapper_type() ~= "pc" then
		return
	end
	table.insert(self._mouse_callbacks, params)
	self:_activate()
end
function MousePointerManager:remove_mouse(id)
	if managers.controller:get_default_wrapper_type() ~= "pc" then
		return
	end
	local removed = false
	if id then
		for i, params in ipairs(self._mouse_callbacks) do
			if params.id == id then
				removed = true
				table.remove(self._mouse_callbacks, i)
				break
			end
		end
	end
	if not removed then
		table.remove(self._mouse_callbacks)
	end
	if #self._mouse_callbacks <= 0 then
		self:_deactivate()
	end
end
function MousePointerManager:_activate()
	if self._active then
		return
	end
	self._active = true
	self._ws:show()
	self._ws:feed_mouse_position(self._mouse:world_position())
	self._mouse:mouse_move(callback(self, self, "_mouse_move"))
	self._mouse:mouse_press(callback(self, self, "_mouse_press"))
	self._mouse:mouse_release(callback(self, self, "_mouse_release"))
	self._mouse:mouse_click(callback(self, self, "_mouse_click"))
end
function MousePointerManager:_deactivate()
	self._active = false
	self._ws:hide()
	self._mouse:mouse_move(nil)
	self._mouse:mouse_press(nil)
	self._mouse:mouse_release(nil)
	self._mouse:mouse_click(nil)
end
function MousePointerManager:_mouse_move(o, x, y)
	o:set_position(x, y)
	if self._mouse_callbacks[#self._mouse_callbacks] and self._mouse_callbacks[#self._mouse_callbacks].mouse_move then
		self._mouse_callbacks[#self._mouse_callbacks].mouse_move(o, x, y)
	end
end
function MousePointerManager:_mouse_press(o, button, x, y)
	if self._mouse_callbacks[#self._mouse_callbacks] and self._mouse_callbacks[#self._mouse_callbacks].mouse_press then
		self._mouse_callbacks[#self._mouse_callbacks].mouse_press(o, button, x, y)
	end
end
function MousePointerManager:_mouse_release(o, button, x, y)
	if self._mouse_callbacks[#self._mouse_callbacks] and self._mouse_callbacks[#self._mouse_callbacks].mouse_release then
		self._mouse_callbacks[#self._mouse_callbacks].mouse_release(o, button, x, y)
	end
end
function MousePointerManager:_mouse_click(o, button, x, y)
	if self._mouse_callbacks[#self._mouse_callbacks] and self._mouse_callbacks[#self._mouse_callbacks].mouse_click then
		self._mouse_callbacks[#self._mouse_callbacks].mouse_click(o, button, x, y)
	end
end
function MousePointerManager:mouse()
	return self._mouse
end
function MousePointerManager:world_position()
	return self._mouse:world_position()
end
