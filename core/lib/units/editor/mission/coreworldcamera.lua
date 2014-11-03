CoreWorldCameraUnitElement = CoreWorldCameraUnitElement or class(MissionElement)
WorldCameraUnitElement = WorldCameraUnitElement or class(CoreWorldCameraUnitElement)
function WorldCameraUnitElement:init(...)
	CoreWorldCameraUnitElement.init(self, ...)
end
function CoreWorldCameraUnitElement:init(unit)
	MissionElement.init(self, unit)
	self._hed.worldcamera = "none"
	self._hed.worldcamera_sequence = "none"
	table.insert(self._save_values, "worldcamera")
	table.insert(self._save_values, "worldcamera_sequence")
end
function CoreWorldCameraUnitElement:test_element()
	if self._hed.worldcamera_sequence ~= "none" then
		managers.worldcamera:play_world_camera_sequence(self._hed.worldcamera_sequence)
	elseif self._hed.worldcamera ~= "none" then
		managers.worldcamera:play_world_camera(self._hed.worldcamera)
	end
end
function CoreWorldCameraUnitElement:selected()
	MissionElement.selected(self)
	self:_populate_worldcameras()
	if not managers.worldcamera:all_world_cameras()[self._hed.worldcamera] then
		self._hed.worldcamera = "none"
		self._worldcameras:set_value(self._hed.worldcamera)
	end
	self:_populate_sequences()
	if not managers.worldcamera:all_world_camera_sequences()[self._hed.worldcamera_sequence] then
		self._hed.worldcamera_sequence = "none"
		self._sequences:set_value(self._hed.worldcamera_sequence)
	end
end
function CoreWorldCameraUnitElement:_populate_worldcameras()
	self._worldcameras:clear()
	self._worldcameras:append("none")
	for name, _ in pairs(managers.worldcamera:all_world_cameras()) do
		self._worldcameras:append(name)
	end
	self._worldcameras:set_value(self._hed.worldcamera)
end
function CoreWorldCameraUnitElement:_populate_sequences()
	self._sequences:clear()
	self._sequences:append("none")
	for name, _ in pairs(managers.worldcamera:all_world_camera_sequences()) do
		self._sequences:append(name)
	end
	self._sequences:set_value(self._hed.worldcamera_sequence)
end
function CoreWorldCameraUnitElement:_build_panel(panel, panel_sizer)
	self:_create_panel()
	panel = panel or self._panel
	panel_sizer = panel_sizer or self._panel_sizer
	local sequence_sizer = EWS:BoxSizer("HORIZONTAL")
	sequence_sizer:add(EWS:StaticText(self._panel, "Sequence:", 0, ""), 1, 0, "ALIGN_CENTER_VERTICAL")
	self._sequences = EWS:ComboBox(self._panel, "", "", "CB_DROPDOWN,CB_READONLY")
	self:_populate_sequences()
	self._sequences:set_value(self._hed.worldcamera_sequence)
	self._sequences:connect("EVT_COMMAND_COMBOBOX_SELECTED", callback(self, self, "set_element_data"), {
		ctrlr = self._sequences,
		value = "worldcamera_sequence"
	})
	sequence_sizer:add(self._sequences, 3, 0, "EXPAND")
	self._panel_sizer:add(sequence_sizer, 0, 0, "EXPAND")
	local worldcamera_sizer = EWS:BoxSizer("HORIZONTAL")
	worldcamera_sizer:add(EWS:StaticText(self._panel, "Camera:", 0, ""), 1, 0, "ALIGN_CENTER_VERTICAL")
	self._worldcameras = EWS:ComboBox(self._panel, "", "", "CB_DROPDOWN,CB_READONLY")
	self:_populate_worldcameras()
	self._worldcameras:set_value(self._hed.worldcamera)
	self._worldcameras:connect("EVT_COMMAND_COMBOBOX_SELECTED", callback(self, self, "set_element_data"), {
		ctrlr = self._worldcameras,
		value = "worldcamera"
	})
	worldcamera_sizer:add(self._worldcameras, 3, 0, "EXPAND")
	self._panel_sizer:add(worldcamera_sizer, 0, 0, "EXPAND")
end
