core:module("CoreEnvironmentOthersFeeder")
core:import("CoreClass")
core:import("CoreCode")
core:import("CoreApp")
core:import("CoreEngineAccess")
EnvironmentOthersFeeder = EnvironmentOthersFeeder or CoreClass.class()
function EnvironmentOthersFeeder:init()
end
function EnvironmentOthersFeeder:end_feed(nr)
end
function EnvironmentOthersFeeder:feed(nr, scene, vp, data, block, ...)
	local args = {
		...
	}
	if args[1] == "others" then
		local underlay_name = block.underlay
		local sun_anim = block.sun_anim
		local sun_anim_x = block.sun_anim_x or 0
		local sun_ray_color = block.sun_ray_color
		local sun_ray_color_scale = block.sun_ray_color_scale
		local global_texture = block.global_texture
		if not Global._current_underlay_name or not Underlay:loaded() or Global._current_underlay_name ~= underlay_name then
			Global._current_underlay_name = underlay_name
			if CoreCode.alive(Global._global_light) then
				World:delete_light(Global._global_light)
				Global._global_light = nil
			end
			if CoreCode.alive(Global._underlay_ref_camera) then
				Underlay:delete_camera(Global._underlay_ref_camera)
				Global._underlay_ref_camera = nil
			end
			local entry_path = managers.database and managers.database:entry_path(underlay_name) or underlay_name
			if Application:editor() or CoreApp.arg_value("-slave") then
				CoreEngineAccess._editor_load(Idstring("scene"), entry_path:id())
			end
			Underlay:load(entry_path)
			managers.environment_controller:feed_params()
		end
		if not CoreCode.alive(Global._global_light) then
			Global._global_light = World:create_light("directional|specular")
			Global._global_light:link(Underlay:get_object(Idstring("d_sun")))
			Global._global_light:set_local_rotation(Rotation(0, 0, 0))
			World:set_global_shadow_caster(Global._global_light)
		end
		if not CoreCode.alive(Global._underlay_ref_camera) then
			Global._underlay_ref_camera = Underlay:create_camera()
			Global._underlay_ref_camera:set_near_range(1000)
			Global._underlay_ref_camera:set_far_range(10000000)
			Global._underlay_ref_camera:set_fov(75)
			local camrefpos = Underlay:get_object(Idstring("rp_skydome"))
			if not camrefpos then
				Global._underlay_ref_camera:set_local_position(Vector3(0, 0, 0))
			else
				Global._underlay_ref_camera:set_local_position(camrefpos:position())
			end
			Underlay:set_reference_camera(Global._underlay_ref_camera)
		end
		Global._global_light:set_color(sun_ray_color * sun_ray_color_scale)
		Underlay:set_time(Idstring("sun_vertical"), sun_anim * Underlay:length(Idstring("sun_vertical")))
		if Underlay:get_object(Idstring("d_sun_horizontal")) then
			Underlay:set_time(Idstring("sun_horizontal"), sun_anim_x * Underlay:length(Idstring("sun_horizontal")))
		end
		if not self._global_texture or self._global_texture ~= global_texture then
			if global_texture and global_texture ~= "" then
				managers.global_texture:set_texture(global_texture, "CUBEMAP")
			else
				print("[EnvironmentOthersFeeder] VARNING! This environment has no cubemap!")
			end
			self._global_texture = global_texture
		end
		return true
	elseif args[1] == "sky_orientation" then
		if nr == 1 then
			Underlay:get_object(Idstring("rp_skydome")):set_rotation(Rotation(-block.rotation, 0, 0))
		end
		return true
	end
	return false
end
