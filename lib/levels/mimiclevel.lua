MimicLevel = MimicLevel or class()
function MimicLevel:init()
	self:_load_package()
end
function MimicLevel:_load_package()
	if not PackageManager:loaded("packages/mimic") then
		PackageManager:load("packages/mimic")
	end
end
function MimicLevel:post_init()
	self._ctrlr_debug = Input:create_virtual_controller()
	local keyboard = Input:keyboard()
	if keyboard:has_button(Idstring("right shift")) then
		local connection_name = "Debug Spawn"
		self._ctrlr_debug:connect(keyboard, Idstring("right shift"), Idstring(connection_name))
		self._ctrlr_debug:add_trigger(Idstring(connection_name), callback(self, self, "spawn_dummy"))
	end
end
function MimicLevel:spawn_pos()
	return managers.viewport:get_current_camera():position() + managers.viewport:get_current_camera():rotation():y() * 750
end
function MimicLevel:spawn_dummy()
	local debug_unit_name = Idstring("units/characters/archelusia_light_infantry/archelusia_light_infantry")
	local dummy_unit = World:spawn_unit(debug_unit_name, self:spawn_pos())
end
