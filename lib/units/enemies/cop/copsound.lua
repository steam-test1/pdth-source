CopSound = CopSound or class()
CopSound._event_list = {
	"_i01x_sin",
	"_r01x_sin",
	"_r02x_sin",
	"_r03x_sin",
	"_m01x_sin",
	"_i03x_sin",
	"_s01x_sin",
	"_h01x_sin",
	"_m01x_plu",
	"_g90",
	"_c01x_plu",
	"_m01x_plu",
	"_clr",
	"_mov",
	"_rdy",
	"_tsr",
	"_bdz",
	"_shd",
	"_clk",
	"_gas",
	"_a01",
	"_a02",
	"_a01x_any",
	"_a02x_any",
	"_a03x_any",
	"dispatch_generic_message",
	"dia_guard_radio",
	"taser_charge",
	"shield_identification",
	"_punch_3rd_person_3p"
}
CopSound._event_id_transl_map = {}
local event_id_tr_map = CopSound._event_id_transl_map
for i_event, event_name in ipairs(CopSound._event_list) do
	event_id_tr_map[event_name] = i_event
end
event_id_tr_map = nil
function CopSound:init(unit)
	self._unit = unit
	self._speak_expire_t = 0
	self._prefix = self.speech_prefix or tweak_data.character[unit:base()._tweak_table].speech_prefix
	local prefix_suffix_max = self.speech_prefix_count or tweak_data.character[unit:base()._tweak_table].speech_prefix_count
	if prefix_suffix_max then
		self._prefix = self._prefix .. tostring(math.random(1, prefix_suffix_max))
	end
	unit:base():post_init()
end
function CopSound:destroy(unit)
	unit:base():pre_destroy(unit)
end
function CopSound:_play(sound_name, source_name)
	local source
	if source_name then
		source = Idstring(source_name)
	end
	local event = self._unit:sound_source(source):post_event(sound_name)
	if not event then
		Application:error("[CopSound:_play] " .. sound_name .. " could not be found in wwise", self._unit)
		Application:stack_dump()
	end
	return event
end
function CopSound:play(sound_name, source_name, sync)
	local event = self:_play(sound_name, source_name)
	if sync then
		local event_id = self._event_id_transl_map[sound_name]
		if event_id then
			self._unit:network():send("unit_sound_play", event_id)
		else
			Application:error("[CopSound:play] " .. sound_name .. " cannot be network-synced since it is not on the translation map")
		end
	end
	return event
end
function CopSound:stop(source_name)
	local source
	if source_name then
		source = Idstring(source_name)
	end
	self._unit:sound_source(source):stop()
end
function CopSound:say(sound_name, sync, skip_prefix, sync_as_string)
	if self._last_speech then
		self._last_speech:stop()
	end
	local full_sound
	if not skip_prefix then
		full_sound = self._prefix .. sound_name
	else
		full_sound = sound_name
	end
	self._last_speech = self:_play(full_sound)
	if sync then
		if sync_as_string then
			self._unit:network():send("say_str", full_sound)
		else
			local event_id = self._event_id_transl_map[sound_name]
			if event_id then
				self._unit:network():send("say", event_id)
			else
				Application:error("[CopSound:say] " .. sound_name .. " cannot be network-synced since it is not on the translation map")
			end
		end
	end
	self._speak_expire_t = TimerManager:game():time() + 2
end
function CopSound:sync_say(event_id)
	local sound_name = self._event_list[event_id]
	local full_sound = self._prefix .. sound_name
	if self._last_speech then
		self._last_speech:stop()
	end
	self._last_speech = self:play(full_sound)
end
function CopSound:sync_say_str(full_sound)
	if self._last_speech then
		self._last_speech:stop()
	end
	self._last_speech = self:play(full_sound)
end
function CopSound:sync_play(event_id)
	local sound_name = self._event_list[event_id]
	self:_play(sound_name)
end
function CopSound:speaking(t)
	return t < self._speak_expire_t
end
function CopSound:anim_clbk_play_sound(unit, queue_name)
	self:_play(queue_name)
end
