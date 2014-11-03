SandboxLevel = SandboxLevel or class()
function SandboxLevel:post_init()
	self._ctrlr_debug = Input:create_virtual_controller()
	if Input:keyboard():has_button("right shift") then
		local connection_name = "Debug spawn dummy"
		self._ctrlr_debug:connect(Input:keyboard(), "right shift", connection_name)
		self._ctrlr_debug:add_trigger(connection_name, callback(self, self, "spawn_dummy"))
	end
	self._debug_unit_name = "dummy_duel"
	self._dummy_unit = nil
end
function SandboxLevel:spawn_pos()
	return managers.viewport:get_current_camera():position() + managers.viewport:get_current_camera():rotation():y() * 750
end
function SandboxLevel:spawn_dummy()
	if not self._dummy_unit then
		self._dummy_unit = World:spawn_unit(self._debug_unit_name, self:spawn_pos())
		self._dummy_unit:base():setup(self._ctrlr_debug)
	else
		self._dummy_unit:warp_to_floor(self._dummy_unit:rotation(), self:spawn_pos())
	end
end
