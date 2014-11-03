core:module("CoreEnvironmentPostProcessorFeeder")
core:import("CoreClass")
core:import("CoreCode")
EnvironmentPostProcessorFeeder = EnvironmentPostProcessorFeeder or CoreClass.class()
function EnvironmentPostProcessorFeeder:init()
	self._cached_processor = {}
end
function EnvironmentPostProcessorFeeder:end_feed(nr)
end
function EnvironmentPostProcessorFeeder:processor(scene, vp, processor_name, effect_name)
	local name = tostring(scene) .. processor_name .. effect_name
	local proc = self._cached_processor[name]
	if not CoreCode.alive(proc) then
		proc = vp:get_post_processor_effect(scene, Idstring(processor_name), Idstring(effect_name))
		self._cached_processor[name] = vp:get_post_processor_effect(scene, Idstring(processor_name), Idstring(effect_name))
	end
	return proc
end
function EnvironmentPostProcessorFeeder:feed(nr, scene, vp, data, block, ...)
	local args = {
		...
	}
	if args[1] == "post_effect" then
		local processor_name = args[2]
		local effect_name = args[3]
		local modifier_name = args[4]
		local processor = self:processor(scene, vp, processor_name, effect_name)
		if processor then
			local modifier = processor:modifier(Idstring(modifier_name))
			if modifier then
				local material = modifier:material()
				if material then
					for k, v in pairs(block) do
						local value = v
						if k == "luminance_clamp" or k == "start_color" or k == "color0" or k == "color1" or k == "color2" or k == "environment_map_intensity" or k == "environment_map_intensity_shadow" or k == "ambient_color" or k == "sky_top_color" or k == "sky_bottom_color" or k == "sky_reflection_bottom_color" or k == "sky_reflection_top_color" or k == "sun_specular_color" then
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
			end
		end
		return true
	end
	return false
end
