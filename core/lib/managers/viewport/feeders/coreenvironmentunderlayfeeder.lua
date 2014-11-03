core:module("CoreEnvironmentUnderlayFeeder")
core:import("CoreClass")
EnvironmentUnderlayFeeder = EnvironmentUnderlayFeeder or CoreClass.class()
function EnvironmentUnderlayFeeder:init()
end
function EnvironmentUnderlayFeeder:end_feed(nr)
end
function EnvironmentUnderlayFeeder:feed(nr, scene, vp, data, block, ...)
	local args = {
		...
	}
	if args[1] == "underlay_effect" then
		if Underlay:loaded() then
			local material_name = args[2]
			local material = Underlay:material(Idstring(material_name))
			if not material then
				return true
			end
			for k, v in pairs(block) do
				local value = v
				if k == sun_color_scale or k == color0_scale or k == color1_scale or k == color2_scale or k == color_opposite_sun_scale or k == color_sun_scale or k == sky_intensity or k == sky_intensity then
					value = v * LightIntensityDB:platform_intensity_scale()
				end
				local scalar = block[k .. "_scale"]
				if scalar then
					material:set_variable(Idstring(k), value * scalar)
				else
					material:set_variable(Idstring(k), value)
				end
			end
		end
		return true
	end
	return false
end
