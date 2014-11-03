core:module("CoreOverlayEffectManager")
core:import("CoreCode")
OverlayEffectManager = OverlayEffectManager or class()
function OverlayEffectManager:init()
	local gui = Overlay:newgui()
	self._vp_overlay = Application:create_scene_viewport(0, 0, 1, 1)
	self._overlay_camera = Overlay:create_camera()
	self._vp_overlay:set_camera(self._overlay_camera)
	self._ws = gui:create_screen_workspace()
	self._ws:set_timer(TimerManager:main())
	self._playing_effects = {}
	self._paused = nil
	self._presets = {}
	self:add_preset("custom", {
		blend_mode = "normal",
		sustain = 0,
		fade_in = 0,
		fade_out = 0,
		color = Color(1, 0, 0, 0)
	})
	self:set_default_layer(30)
	managers.viewport:add_resolution_changed_func(callback(self, self, "change_resolution"))
end
function OverlayEffectManager:set_visible(visible)
	self._ws:panel():set_visible(visible)
end
function OverlayEffectManager:add_preset(name, settings)
	self._presets[name] = settings
end
function OverlayEffectManager:presets()
	return self._presets
end
function OverlayEffectManager:set_default_layer(layer)
	self._default_layer = layer
end
function OverlayEffectManager:update(t, dt)
	self._vp_overlay:update()
	self:check_pause_state()
	self:progress_effects(t, dt)
end
function OverlayEffectManager:destroy()
	if CoreCode.alive(self._overlay_camera) then
		Overlay:delete_camera(self._overlay_camera)
		self._overlay_camera = nil
	end
	if self._vp_overlay then
		Application:destroy_viewport(self._vp_overlay)
		self._vp_overlay = nil
	end
	if CoreCode.alive(self._ws) then
		Overlay:newgui():destroy_workspace(self._ws)
		self._ws = nil
	end
end
function OverlayEffectManager:render()
	if Global.render_debug.render_overlay then
		Application:render("Overlay", self._vp_overlay)
	end
end
function OverlayEffectManager:progress_effects(t, dt, paused)
	for key, effect in pairs(self._playing_effects) do
		local data = effect.data
		if not paused or data.play_paused then
			local eff_t = data.timer and data.timer:time() or paused and TimerManager:game():time() or t
			local fade_in_end_t = effect.start_t + data.fade_in
			local sustain_end_t = data.sustain and fade_in_end_t + data.sustain
			local effect_end_t = sustain_end_t and sustain_end_t + data.fade_out
			local new_alpha
			if eff_t < fade_in_end_t then
				new_alpha = (eff_t - effect.start_t) / data.fade_in
			elseif not sustain_end_t or eff_t < sustain_end_t then
				new_alpha = 1
			elseif eff_t < effect_end_t then
				new_alpha = 1 - (eff_t - sustain_end_t) / data.fade_out
			else
				self._ws:panel():remove(effect.rectangle)
				self._playing_effects[key] = nil
			end
			if new_alpha then
				new_alpha = new_alpha * data.color.alpha
				effect.current_alpha = new_alpha
				if effect.gradient_points then
					for i = 2, #effect.gradient_points, 2 do
						effect.gradient_points[i] = effect.gradient_points[i]:with_alpha(new_alpha)
					end
					effect.rectangle:set_gradient_points(effect.gradient_points)
				else
					effect.rectangle:set_color(data.color:with_alpha(new_alpha))
				end
			end
		end
	end
end
function OverlayEffectManager:paused_update(t, dt)
	self:check_pause_state(true)
	self:progress_effects(t, dt, true)
end
function OverlayEffectManager:check_pause_state(paused)
	if self._paused then
		if not paused then
			for key, effect in pairs(self._playing_effects) do
				effect.rectangle:show()
			end
			self._paused = nil
		end
	elseif paused then
		for _, effect in pairs(self._playing_effects) do
			if not effect.data.play_paused then
				effect.rectangle:hide()
			end
		end
		self._paused = true
	end
end
function OverlayEffectManager:play_effect(data)
	if data then
		local spawn_alpha = data.color.alpha * (data.fade_in > 0 and 0 or 1)
		local rectangle
		if data.gradient_points then
			rectangle = self._ws:panel():gradient({
				w = RenderSettings.resolution.x,
				h = RenderSettings.resolution.y,
				color = data.color:with_alpha(spawn_alpha),
				gradient_points = data.gradient_points,
				orientation = data.orientation
			})
		else
			rectangle = self._ws:panel():rect({
				w = RenderSettings.resolution.x,
				h = RenderSettings.resolution.y,
				color = data.color:with_alpha(spawn_alpha)
			})
		end
		rectangle:set_layer(self._default_layer)
		rectangle:set_blend_mode(data.blend_mode)
		if data.play_paused or not self._paused then
			rectangle:show()
		else
			rectangle:hide()
		end
		local effect = {
			rectangle = rectangle,
			start_t = data.timer or TimerManager:game():time(),
			data = {},
			current_alpha = spawn_alpha,
			gradient_points = data.gradient_points
		}
		for key, value in pairs(data) do
			effect.data[key] = value
		end
		local id = 1
		while self._playing_effects[id] do
			id = id + 1
		end
		table.insert(self._playing_effects, id, effect)
		return id
	else
		cat_error("georgios", "OverlayEffectManager, no effect_data sent to play_effect")
	end
end
function OverlayEffectManager:stop_effect(id)
	if id then
		if self._playing_effects[id] then
			self._ws:panel():remove(self._playing_effects[id].rectangle)
			self._playing_effects[id] = nil
		end
	else
		for key, effect in pairs(self._playing_effects) do
			self._ws:panel():remove(effect.rectangle)
			self._playing_effects[key] = nil
		end
	end
end
function OverlayEffectManager:fade_out_effect(id)
	if id then
		local effect = self._playing_effects[id]
		if effect then
			effect.start_t = effect.data.timer or TimerManager:game():time()
			effect.data.sustain = 0
			effect.data.fade_in = 0
			effect.data.color = effect.data.color:with_alpha(effect.current_alpha)
		end
	else
		for key, effect in pairs(self._playing_effects) do
			effect.start_t = effect.data.timer or TimerManager:game():time()
			effect.data.sustain = 0
			effect.data.fade_in = 0
			effect.data.color = effect.data.color:with_alpha(effect.current_alpha)
		end
	end
end
function OverlayEffectManager:change_resolution()
	local res = RenderSettings.resolution
	for _, effect in pairs(self._playing_effects) do
		effect.rectangle:configure({
			w = res.x,
			h = res.y
		})
	end
end
