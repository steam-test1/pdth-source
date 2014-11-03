PlayerSound = PlayerSound or class()
PlayerSound._event_list = {
	"f02x_sin",
	"f03a_sin",
	"f02x_plu",
	"f03a_plu",
	"l01x_sin",
	"l02x_sin",
	"l03x_sin",
	"f21a_sin",
	"f21b_sin",
	"f21c_sin",
	"f21d_sin",
	"f11a_sin",
	"f11b_sin",
	"f11c_sin",
	"f11d_sin",
	"f13a_sin",
	"f13b_sin",
	"f13c_sin",
	"f13d_sin",
	"f03b_any",
	"s01x_plu",
	"s02x_plu",
	"a01x_any",
	"s05x_sin",
	"f30x_any",
	"f31x_any",
	"f32x_any",
	"f33x_any",
	"Dia_10x_any",
	"f30y_any",
	"f31y_any",
	"f32y_any",
	"f33y_any",
	"s07x_sin",
	"i01x_any",
	"e01x_sin",
	"e02x_sin",
	"e03x_sin",
	"e04x_sin",
	"e05x_sin",
	"fwb_03",
	"fwb_14",
	"fwb_29",
	"bri_14",
	"bri_29",
	"und_18",
	"s20x_sin",
	"s21x_sin",
	"s09a",
	"s09b",
	"s09c",
	"g30x_any",
	"g31x_any",
	"g32x_any",
	"g33x_any",
	"g80x_plu",
	"g81x_plu",
	"f11e_plu",
	"r01x_sin",
	"r02a_sin",
	"g90"
}
PlayerSound._event_id_transl_map = {}
local event_id_tr_map = PlayerSound._event_id_transl_map
for i_event, event_name in ipairs(PlayerSound._event_list) do
	event_id_tr_map[event_name] = i_event
end
event_id_tr_map = nil
function PlayerSound:init(unit)
	self._unit = unit
	unit:base():post_init()
	local ss = unit:sound_source()
	ss:set_switch("robber", "rb3")
	if unit:base().is_local_player then
		ss:set_switch("int_ext", "first")
	else
		ss:set_switch("int_ext", "third")
	end
end
function PlayerSound:destroy(unit)
	unit:base():pre_destroy(unit)
end
function PlayerSound:play(sound_name, source_name, important_say)
	local source
	if source_name then
		source = Idstring(source_name)
	end
	local event = self._unit:sound_source(source):post_event(sound_name, self.sound_callback, self._unit, "marker", "end_of_event")
	if important_say then
		managers.hud:set_mugshot_talk(self._unit:unit_data().mugshot_id, true)
		self._speaking = true
	end
	if not event then
		Application:error("[PlayerSound:play] " .. sound_name .. " could not be found in wwise")
		Application:stack_dump()
		self:sound_callback(nil, "end_of_event", self._unit, source, nil, nil, nil)
	end
	return event
end
function PlayerSound:sound_callback(instance, event_type, unit, sound_source, label, identifier, position)
	if not alive(unit) then
		return
	end
	if event_type == "end_of_event" then
		managers.hud:set_mugshot_talk(unit:unit_data().mugshot_id, false)
		unit:sound()._speaking = nil
	end
end
function PlayerSound:sync_play(sound_name, source_name)
	self:play(sound_name, source_name)
	source_name = source_name or "nil"
	self._unit:network():send("sync_player_sound", sound_name, source_name)
end
function PlayerSound:stop(source_name)
	local source
	if source_name then
		source = Idstring(source_name)
	end
	self._unit:sound_source(source):stop()
end
function PlayerSound:play_footstep(foot, material_name)
	local material_name = tweak_data.materials[material_name:key()]
	self._unit:sound_source(Idstring("root")):set_switch("materials", material_name or "no_material")
	self:play(self._unit:movement():running() and "footstep_run" or "footstep_walk")
end
function PlayerSound:play_land(material_name)
	local material_name = tweak_data.materials[material_name:key()]
	self._unit:sound_source(Idstring("root")):set_switch("materials", material_name or "concrete")
	self:play("footstep_land")
end
function PlayerSound:play_whizby(params)
	local sound_source = SoundDevice:create_source("whizby")
	sound_source:set_position(params.position)
	sound_source:post_event("bullet_whizby_medium")
end
function PlayerSound:say(sound_name, sync)
	if self._last_speech and self._speaking then
		self._last_speech:stop()
		self._speaking = nil
	end
	self._last_speech = self:play(sound_name, nil, true)
	if sync then
		local event_id = PlayerSound._event_id_transl_map[sound_name]
		if event_id then
			self._unit:network():send("say", event_id)
		else
			Application:error("[PlayerSound:say] " .. sound_name .. " cannot be network-synced")
		end
	end
	return self._last_speech
end
function PlayerSound:sync_say(event_id)
	local sound_name = self._event_list[event_id]
	if self._last_speech and self._speaking then
		self._last_speech:stop()
		self._speaking = nil
	end
	self._last_speech = self:play(sound_name, nil, true)
end
function PlayerSound:speaking()
	return self._speaking
end
function PlayerSound:set_voice(voice)
	local ss = self._unit:sound_source()
	ss:set_switch("robber", voice)
end
