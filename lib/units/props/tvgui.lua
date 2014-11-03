TvGui = TvGui or class()
function TvGui:init(unit)
	self._unit = unit
	self._visible = true
	self._video = self._video or "movies/level_alaska"
	self._gui_object = self._gui_object or "gui_name"
	self._new_gui = World:newgui()
	self:add_workspace(self._unit:get_object(Idstring(self._gui_object)))
	self:setup()
	self._unit:set_extension_update_enabled(Idstring("tv_gui"), false)
end
function TvGui:add_workspace(gui_object)
	self._ws = self._new_gui:create_object_workspace(0, 0, gui_object, Vector3(0, 0, 0))
end
function TvGui:setup()
	self._ws:panel():video({
		layer = 10,
		visible = true,
		video = self._video,
		loop = true
	})
end
function TvGui:_start()
end
function TvGui:start()
end
function TvGui:sync_start()
	self:_start()
end
function TvGui:set_visible(visible)
	self._visible = visible
	self._gui:set_visible(visible)
end
function TvGui:lock_gui()
	self._ws:set_cull_distance(self._cull_distance)
	self._ws:set_frozen(true)
end
function TvGui:destroy()
	if alive(self._new_gui) and alive(self._ws) then
		self._new_gui:destroy_workspace(self._ws)
		self._ws = nil
		self._new_gui = nil
	end
end
