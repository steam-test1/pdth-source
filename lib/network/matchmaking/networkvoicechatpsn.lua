NetworkVoiceChatPSN = NetworkVoiceChatPSN or class()
function NetworkVoiceChatPSN:init()
	self._started = false
	self._room_id = nil
	self._team = 1
	self._restart_session = nil
	self:_load_globals()
	self._muted_players = {}
end
function NetworkVoiceChatPSN:check_status_information()
end
function NetworkVoiceChatPSN:open()
end
function NetworkVoiceChatPSN:voice_type()
	return "voice_psn"
end
function NetworkVoiceChatPSN:pause()
end
function NetworkVoiceChatPSN:resume()
end
function NetworkVoiceChatPSN:set_volume(volume)
	PSNVoice:set_volume(volume)
end
function NetworkVoiceChatPSN:init_voice()
	if self._started == false and not self._starting then
		self._starting = true
		PSNVoice:assign_callback(function(...)
			self:_callback(...)
		end)
		PSNVoice:init(4, 4, 50, 8000)
		self:set_volume(managers.user:get_setting("voice_volume"))
	end
end
function NetworkVoiceChatPSN:destroy_voice(disconnected)
	if self._started == true then
		self._started = false
		if self._room_id and not disconnected then
			self:close_session()
		end
		PSNVoice:destroy()
		self._closing = nil
		self._room_id = nil
		self._restart_session = nil
		self._team = 1
	end
end
function NetworkVoiceChatPSN:num_peers()
	local l = PSNVoice:get_players_info()
	if l then
		local x = 0
		for k, v in pairs(l) do
			if v.joined == 1 then
				x = x + 1
			end
		end
		return x >= #l
	end
	return true
end
function NetworkVoiceChatPSN:open_session(roomid)
	if self._room_id and self._room_id == roomid then
		return
	end
	if self._restart_session and self._restart_session == roomid then
		return
	end
	if self._closing or self._joining then
		self._restart_session = roomid
		return
	end
	if self._started == false then
		self._restart_session = roomid
		self:init_voice()
		return
	end
	if self._room_id then
		self._restart_session = roomid
		self:close_session()
		return
	end
	self._room_id = roomid
	self._joining = true
	PSNVoice:start_session(roomid)
end
function NetworkVoiceChatPSN:close_session()
	if self._joining then
		self._close = true
		return
	end
	if self._room_id and not self._closing then
		self._closing = true
		if not PSNVoice:stop_session() then
			self._closing = nil
			self._room_id = nil
			self._delay_frame = TimerManager:wall():time() + 1
		end
	elseif not self._closing then
		self._restart_session = nil
		self._delay_frame = nil
	end
end
function NetworkVoiceChatPSN:open_channel_to(player_info, context)
end
function NetworkVoiceChatPSN:close_channel_to(player_info)
end
function NetworkVoiceChatPSN:lost_peer(peer)
end
function NetworkVoiceChatPSN:close_all()
	if self._room_id then
		self:close_session()
	end
	self._room_id = nil
	self._closing = nil
end
function NetworkVoiceChatPSN:set_team(team)
	if self._room_id then
		PSN:change_team(self._room_id, PSN:get_local_userid(), team)
		PSNVoice:set_team_target(team)
	end
	self._team = team
end
function NetworkVoiceChatPSN:clear_team()
	if self._room_id and PSN:get_local_userid() then
		PSN:change_team(self._room_id, PSN:get_local_userid(), 1)
		PSNVoice:set_team_target(1)
		self._team = 1
	end
end
function NetworkVoiceChatPSN:set_drop_in(data)
	self._drop_in = data
end
function NetworkVoiceChatPSN:_load_globals()
	if Global.psn and Global.psn.voice then
		self._started = Global.psn.voice.started
	end
	if PSN:is_online() and Global.psn and Global.psn.voice then
		PSNVoice:assign_callback(function(...)
		end)
		self._room_id = Global.psn.voice.room
		self._team = Global.psn.voice.team
		if Global.psn.voice.drop_in then
			self:open_session(Global.psn.voice.drop_in.room_id)
		end
		if Global.psn.voice.restart then
			self._restart_session = restart
			self._delay_frame = TimerManager:wall():time() + 2
		else
			PSNVoice:assign_callback(function(...)
				self:_callback(...)
			end)
			if self._room_id then
				self:set_team(self._team)
			end
		end
		Global.psn.voice = nil
	end
end
function NetworkVoiceChatPSN:_save_globals(disable_voice)
	if disable_voice == nil then
		return
	end
	if not Global.psn then
		Global.psn = {}
	end
	local f = function(...)
	end
	PSNVoice:assign_callback(f)
	Global.psn.voice = {}
	Global.psn.voice.started = self._started
	Global.psn.voice.drop_in = self._drop_in
	if type(disable_voice) == "boolean" then
		if disable_voice == true then
			Global.psn.voice.room = self._room_id
			Global.psn.voice.team = self._team
		else
			Global.psn.voice.team = 1
		end
	else
		self:close_all()
		Global.psn.voice.restart = disable_voice
		Global.psn.voice.team = 1
	end
end
function NetworkVoiceChatPSN:_callback(info)
	if info and PSN:get_local_userid() then
		if info.load_succeeded ~= nil then
			self._starting = nil
			if info.load_succeeded then
				self._started = true
				self._delay_frame = TimerManager:wall():time() + 1
			end
			return
		end
		if info.join_succeeded ~= nil then
			self._joining = nil
			if info.join_succeeded == false then
				self._room_id = nil
			else
				self:set_team(self._team)
			end
			if self._restart_session then
				self._delay_frame = TimerManager:wall():time() + 1
			end
			if self._close then
				self._close = nil
				self:close_session()
			end
		end
		if info.leave_succeeded ~= nil then
			self._closing = nil
			self._room_id = nil
			if self._restart_session then
				self._delay_frame = TimerManager:wall():time() + 1
			end
		end
		if info.unload_succeeded ~= nil then
			local f = function(...)
			end
			PSNVoice:assign_callback(f)
		end
	end
end
function NetworkVoiceChatPSN:update()
	if self._delay_frame and TimerManager:wall():time() > self._delay_frame then
		self._delay_frame = nil
		if self._restart_session then
			PSNVoice:assign_callback(function(...)
				self:_callback(...)
			end)
			local r = self._restart_session
			self._restart_session = nil
			self:open_session(r)
		end
	end
end
function NetworkVoiceChatPSN:psn_session_destroyed(roomid)
	if self._room_id and self._room_id == roomid then
		self._room_id = nil
		self._closing = nil
	end
end
function NetworkVoiceChatPSN:_get_peer_user_id(peer)
	if not self._room_id then
		return
	end
	local members = PSN:get_info_session(self._room_id).memberlist
	local name = peer:name()
	for i, member in ipairs(members) do
		if tostring(member.user_id) == name then
			return member.user_id
		end
	end
end
function NetworkVoiceChatPSN:mute_player(peer, mute)
	local id = self:_get_peer_user_id(peer)
	if id then
		self._muted_players[peer:name()] = mute
		PSNVoice:mute_player(mute, id)
	end
end
function NetworkVoiceChatPSN:is_muted(peer)
	return self._muted_players[peer:name()] or false
end
