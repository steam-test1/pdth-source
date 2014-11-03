core:module("CoreEnvironmentShadowInterface")
core:import("CoreClass")
EnvironmentShadowInterface = EnvironmentShadowInterface or CoreClass.class()
EnvironmentShadowInterface.DATA_PATH = {
	"post_effect",
	"shadow_processor",
	"shadow_rendering",
	"shadow_modifier"
}
EnvironmentShadowInterface.SHARED = false
function EnvironmentShadowInterface:init(handle)
	self._handle = handle
end
function EnvironmentShadowInterface:parameters()
	return self:convert_to_interface(self._handle:parameters())
end
function EnvironmentShadowInterface:convert_to_interface(params)
	local interface_params = {}
	interface_params.d0 = params.shadow_slice_depths.x
	interface_params.d1 = params.shadow_slice_depths.y
	interface_params.d2 = params.shadow_slice_depths.z
	interface_params.d3 = params.slice3.y
	interface_params.o1 = params.shadow_slice_overlap.x
	interface_params.o2 = params.shadow_slice_overlap.y
	interface_params.o3 = params.shadow_slice_overlap.z
	interface_params.f = params.shadow_fadeout.x - interface_params.d3
	return interface_params
end
function EnvironmentShadowInterface:_process_return(block)
	if block and block.d0 and block.d1 and block.d2 and block.d3 and block.o1 and block.o2 and block.o3 then
		local return_block = {}
		local s0 = Vector3(0, block.d0, 0)
		local s1 = Vector3(block.d0 - block.o1, block.d1, 0)
		local s2 = Vector3(block.d1 - block.o2, block.d2, 0)
		local s3 = Vector3(block.d2 - block.o3, block.d3, 0)
		local shadow_slice_depths = Vector3(block.d0, block.d1, block.d2)
		local shadow_slice_overlaps = Vector3(block.o1, block.o2, block.o3)
		return_block.slice0 = s0
		return_block.slice1 = s1
		return_block.slice2 = s2
		return_block.slice3 = s3
		return_block.shadow_slice_depths = shadow_slice_depths
		return_block.shadow_slice_overlap = shadow_slice_overlaps
		return_block.shadow_fadeout = Vector3(block.d3 - block.f, block.d3, 0)
		return return_block
	elseif block.slice0 and block.slice1 and block.slice2 and block.slice3 and block.shadow_slice_depths and block.shadow_slice_overlap and block.shadow_fadeout then
		return block
	else
		local error_msg = "[EnvironmentShadowInterface] You did not return all shadow parameters! "
		for k, v in pairs(block) do
			error_msg = error_msg .. k .. " " .. v
		end
		Application:error(error_msg)
	end
end
