core:import("CoreSubtitlePresenter")
DramaExt = DramaExt or class()
function DramaExt:init(unit)
	self._unit = unit
	self._cue = nil
end
function DramaExt:name()
	return self.character_name
end
function DramaExt:play_cue(id)
	self._cue = managers.drama:cue(id)
	if not self._cue then
		Application:throw_exception("The drama script tries to access a cue id '" .. tostring(id) .. "' which doesn't seem to exist!")
	end
	local duration = self._cue.duration
	if duration == "sound" then
		duration = 0
		managers.dialog:pause_dialog()
	elseif duration == "animation" then
		duration = tweak_data.dialog.MINIMUM_DURATION
	end
	if self._cue.string_id then
		managers.subtitle:set_visible(true)
		managers.subtitle:set_enabled(true)
		if duration == 0 then
			managers.subtitle:show_subtitle(self._cue.string_id, 100000)
		else
			managers.subtitle:show_subtitle(self._cue.string_id, duration)
		end
	end
	if self._cue.sound then
		managers.hud:set_mugshot_talk(self._unit:unit_data().mugshot_id, true)
		local playing = self._unit:sound_source(self._cue.sound_source):post_event(self._cue.sound, self.sound_callback, self._unit, "marker", "end_of_event")
		if not playing then
			self:sound_callback(nil, "end_of_event", self._unit, self._cue.sound_source, nil, nil, nil)
			Application:error("[DramaExt:play_cue] Wasn't able to play sound event " .. self._cue.sound)
			Application:stack_dump()
		end
	end
	if self._cue.animation then
	end
	return duration
end
function DramaExt:stop_cue(id)
	if self._cue then
		if self._cue.string_id then
			managers.subtitle:set_visible(false)
			managers.subtitle:set_enabled(false)
		end
		if self._cue.sound then
			self._unit:sound_source(self._cue.sound_source):stop()
		end
		self._cue = nil
	end
end
function DramaExt:sound_callback(instance, event_type, unit, sound_source, label, identifier, position)
	if event_type == "end_of_event" then
		managers.subtitle:set_visible(false)
		managers.subtitle:set_enabled(false)
		managers.hud:set_mugshot_talk(unit:unit_data().mugshot_id, false)
		managers.dialog:play_dialog()
	elseif event_type == "marker" and sound_source then
		managers.subtitle:set_visible(true)
		managers.subtitle:set_enabled(true)
		managers.subtitle:show_subtitle(sound_source, DramaExt._subtitle_len(DramaExt, sound_source))
	end
end
function DramaExt:_subtitle_len(id)
	local text = managers.localization:text(id)
	local duration = text:len() * tweak_data.dialog.DURATION_PER_CHAR
	if duration < tweak_data.dialog.MINIMUM_DURATION then
		duration = tweak_data.dialog.MINIMUM_DURATION
	end
	return duration
end
