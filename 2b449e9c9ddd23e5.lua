GroupAIStateAirport = GroupAIStateAirport or class(GroupAIStateStreet)
function GroupAIStateAirport:_upd_police_activity(t)
	if not (self._heat_data.i_stage > 0) or not self._ai_enabled or not self._mission_fwd_vector then
		return
	end
	if self._event_chk_t < self._t then
		self._event_chk_t = self._event_chk_t + 60
		self:_calculate_criminal_center()
		self:_remove_lost_cops()
		self:_claculate_drama_value()
		self:_reassign_cops()
		local spawn_threshold = math.max(0, self._police_force_max - self._police_force)
		if spawn_threshold > 0 then
			local next_wave = self:_decide_on_next_wave(spawn_threshold)
			if next_wave then
				self._current_wave = next_wave
				self:_dispatch_wave(next_wave)
			end
		end
	end
end
