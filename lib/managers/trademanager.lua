TradeManager = TradeManager or class()
function TradeManager:init()
	self._criminals_to_respawn = {}
	self._criminals_to_add = {}
	self._trade_counter_tick = 1
	self._num_trades = 0
	self:set_trade_countdown(true)
end
function TradeManager:save(save_data)
	local my_save_data = {}
	save_data.trade = my_save_data
	my_save_data.criminals = self._criminals_to_respawn
end
function TradeManager:load(load_data)
	local my_load_data = load_data.trade
	self._criminals_to_respawn = my_load_data.criminals
	self._criminals_to_add = {}
	for _, crim in ipairs(self._criminals_to_respawn) do
		if not crim.ai and not managers.network:session():peer(crim.peer_id) then
			if crim.peer_id then
				self._criminals_to_add[crim.peer_id] = crim
			end
		else
			managers.criminals:add_character(crim.id, nil, crim.peer_id, crim.ai)
		end
	end
end
function TradeManager:handshake_complete(peer_id)
	local crim = self._criminals_to_add[peer_id]
	if crim then
		managers.criminals:add_character(crim.id, nil, crim.peer_id, crim.ai)
		self._criminals_to_add[peer_id] = nil
	end
end
function TradeManager:is_peer_in_custody(peer_id)
	for _, crim in ipairs(self._criminals_to_respawn) do
		if crim.peer_id == peer_id then
			return true
		end
	end
end
function TradeManager:is_criminal_in_custody(name)
	for _, crim in ipairs(self._criminals_to_respawn) do
		if crim.id == name then
			return true
		end
	end
end
function TradeManager:respawn_delay_by_name(character_name)
	for _, crim in ipairs(self._criminals_to_respawn) do
		if crim.id == character_name then
			return crim.respawn_penalty
		end
	end
	return 0
end
function TradeManager:hostages_killed_by_name(character_name)
	for _, crim in ipairs(self._criminals_to_respawn) do
		if crim.id == character_name then
			return crim.hostages_killed
		end
	end
	return 0
end
function TradeManager:update(t, dt)
	self._t = t
	if not managers.criminals or not managers.hud then
		return
	end
	if not self._hostage_remind_t or t > self._hostage_remind_t then
		if not self._trading_hostage and not self._hostage_trade_clbk and #self._criminals_to_respawn > 0 and 0 >= managers.groupai:state():hostage_count() and managers.groupai:state():is_AI_enabled() and managers.groupai:state():bain_state() then
			local cable_tie_data = managers.player:has_special_equipment("cable_tie")
			if cable_tie_data and 0 < cable_tie_data.amount then
				managers.dialog:queue_dialog("ban_h01x", {})
			elseif self:get_criminal_to_trade() ~= nil then
				managers.dialog:queue_dialog("Play_ban_h22x", {})
			end
		end
		self._hostage_remind_t = t + math.random(60, 120)
	end
	self._trade_counter_tick = self._trade_counter_tick - dt
	if 0 >= self._trade_counter_tick then
		self._trade_counter_tick = self._trade_counter_tick + 1
		if self._hostage_to_trade and not alive(self._hostage_to_trade.unit) then
			self:cancel_trade()
		end
		for _, crim in ipairs(self._criminals_to_respawn) do
			local crim_data = managers.criminals:character_data_by_name(crim.id)
			local mugshot_id = crim_data and crim_data.mugshot_id
			local mugshot_data = mugshot_id and managers.hud:_get_mugshot_data(mugshot_id)
			if mugshot_data and not mugshot_data.state_name ~= "mugshot_in_custody" then
				managers.hud:set_mugshot_custody(mugshot_id)
				if 0 < crim.respawn_penalty then
					managers.hud:show_mugshot_timer(mugshot_id)
				end
			end
			if 0 < crim.respawn_penalty then
				crim.respawn_penalty = self._trade_countdown and crim.respawn_penalty - 1 or crim.respawn_penalty
				managers.hud:set_mugshot_timer(mugshot_id, crim.respawn_penalty)
				if 0 >= crim.respawn_penalty then
					crim.respawn_penalty = 0
					managers.hud:hide_mugshot_timer(mugshot_id)
				end
			end
		end
	end
	if not self._trade_countdown or not Network:is_server() or self._trading_hostage or self._hostage_trade_clbk or not (#self._criminals_to_respawn > 0) or self:get_criminal_to_trade() == nil or 0 >= managers.groupai:state():hostage_count() then
	else
		self._cancel_trade = nil
		local respawn_t = self._t + math.random(2, 5)
		local clbk_id = "begin_hostage_trade_dialog"
		self._hostage_trade_clbk = clbk_id
		managers.enemy:add_delayed_clbk(clbk_id, callback(self, self, "begin_hostage_trade_dialog", 1), respawn_t)
	end
end
function TradeManager:num_in_trade_queue()
	return #self._criminals_to_respawn
end
function TradeManager:get_criminal_to_trade()
	for _, crim in ipairs(self._criminals_to_respawn) do
		if crim.respawn_penalty <= 0 then
			return crim
		end
	end
end
function TradeManager:sync_set_trade_death(criminal_name, respawn_penalty, hostages_killed, from_local)
	if not from_local then
		local crim_data = managers.criminals:character_data_by_name(criminal_name)
		if not crim_data then
			return
		end
		if crim_data.ai then
			self:on_AI_criminal_death(criminal_name, respawn_penalty, hostages_killed)
		else
			self:on_player_criminal_death(criminal_name, respawn_penalty, hostages_killed)
		end
	end
	self:play_custody_voice(criminal_name)
	if managers.criminals:local_character_name() == criminal_name and not Network:is_server() and game_state_machine:current_state_name() == "ingame_waiting_for_respawn" then
		game_state_machine:current_state():trade_death(respawn_penalty, hostages_killed)
	end
end
function TradeManager:_announce_spawn(criminal_name)
	if not managers.groupai:state():bain_state() then
		return
	end
	local character_code = managers.criminals:character_static_data_by_name(criminal_name).ssuffix
	managers.dialog:queue_dialog("ban_q02" .. character_code, {})
end
function TradeManager:sync_set_trade_spawn(criminal_name)
	local crim_data = managers.criminals:character_data_by_name(criminal_name)
	self:_announce_spawn(criminal_name)
	self._num_trades = self._num_trades + 1
	if crim_data then
		managers.hud:hide_mugshot_timer(crim_data.mugshot_id)
		managers.hud:set_mugshot_normal(crim_data.mugshot_id)
	end
	for i, crim in ipairs(self._criminals_to_respawn) do
		if crim.id == criminal_name then
			table.remove(self._criminals_to_respawn, i)
		else
		end
	end
end
function TradeManager:sync_set_trade_replace(replace_ai, criminal_name1, criminal_name2, respawn_penalty)
	if replace_ai then
		self:replace_ai_with_player(criminal_name1, criminal_name2, respawn_penalty)
	else
		self:replace_player_with_ai(criminal_name1, criminal_name2, respawn_penalty)
	end
end
function TradeManager:play_custody_voice(criminal_name)
	if managers.criminals:local_character_name() == criminal_name then
		return
	end
	if #self._criminals_to_respawn == 3 then
		local criminal_left
		for _, crim_data in pairs(managers.groupai:state():all_char_criminals()) do
			if not crim_data.unit:movement():downed() then
				criminal_left = managers.criminals:character_name_by_unit(crim_data.unit)
			else
			end
		end
		if managers.criminals:local_character_name() == criminal_left then
			managers.achievment:set_script_data("last_man_standing", true)
			if managers.groupai:state():bain_state() then
				local character_code = managers.criminals:character_static_data_by_name(criminal_left).ssuffix
				managers.dialog:queue_dialog("Play_ban_i20" .. character_code, {})
			end
			return
		end
	end
	if managers.groupai:state():bain_state() then
		local character_code = managers.criminals:character_static_data_by_name(criminal_name).ssuffix
		managers.dialog:queue_dialog("Play_ban_h11" .. character_code, {})
	end
end
function TradeManager:on_AI_criminal_death(criminal_name, respawn_penalty, hostages_killed, skip_netsend)
	if not managers.hud then
		return
	end
	local crim_data = managers.criminals:character_data_by_name(criminal_name)
	if crim_data then
		managers.hud:set_mugshot_custody(crim_data.mugshot_id)
		managers.hud:set_mugshot_timer(crim_data.mugshot_id, respawn_penalty)
		managers.hud:show_mugshot_timer(crim_data.mugshot_id)
	end
	local crim = {
		id = criminal_name,
		ai = true,
		respawn_penalty = respawn_penalty,
		hostages_killed = hostages_killed
	}
	table.insert(self._criminals_to_respawn, crim)
	if Network:is_server() and not skip_netsend then
		managers.network:session():send_to_peers("set_trade_death", criminal_name, respawn_penalty, hostages_killed)
		self:sync_set_trade_death(criminal_name, respawn_penalty, hostages_killed, true)
	end
	print("RC: ai criminal death", criminal_name)
	return crim
end
function TradeManager:on_player_criminal_death(criminal_name, respawn_penalty, hostages_killed, skip_netsend)
	if not managers.hud then
		return
	end
	for _, crim in ipairs(self._criminals_to_respawn) do
		if crim.id == criminal_name then
			print("RC: player already dead", criminal_name)
			return
		end
	end
	if tweak_data.player.damage.automatic_respawn_time then
		respawn_penalty = math.min(respawn_penalty, tweak_data.player.damage.automatic_respawn_time)
	end
	local crim_data = managers.criminals:character_data_by_name(criminal_name)
	if crim_data then
		managers.hud:set_mugshot_custody(crim_data.mugshot_id)
		managers.hud:set_mugshot_timer(crim_data.mugshot_id, respawn_penalty)
		managers.hud:show_mugshot_timer(crim_data.mugshot_id)
	end
	local crim = {
		id = criminal_name,
		ai = false,
		respawn_penalty = respawn_penalty,
		hostages_killed = hostages_killed,
		peer_id = managers.criminals:character_peer_id_by_name(criminal_name)
	}
	local inserted = false
	for i, crim_to_respawn in ipairs(self._criminals_to_respawn) do
		if crim_to_respawn.ai == true or respawn_penalty < crim_to_respawn.respawn_penalty then
			table.insert(self._criminals_to_respawn, i, crim)
			inserted = true
		else
		end
	end
	if not inserted then
		table.insert(self._criminals_to_respawn, crim)
	end
	if Network:is_server() and not skip_netsend then
		managers.network:session():send_to_peers("set_trade_death", criminal_name, respawn_penalty, hostages_killed)
		self:sync_set_trade_death(criminal_name, respawn_penalty, hostages_killed, true)
	end
	print("RC: player criminal death", criminal_name)
	return crim
end
function TradeManager:set_trade_countdown(enabled)
	self._trade_countdown = enabled
	if Network:is_server() and managers.network then
		managers.network:session():send_to_peers("set_trade_countdown", enabled)
	end
end
function TradeManager:replace_ai_with_player(ai_criminal, player_criminal, new_respawn_penalty)
	print("[TradeManager:replace_ai_with_player]", ai_criminal)
	local first_crim = self._criminals_to_respawn[1]
	if first_crim and first_crim.id == ai_criminal then
		self:cancel_trade()
	end
	local respawn_penalty, hostages_killed
	for i, c in ipairs(self._criminals_to_respawn) do
		if c.id == ai_criminal then
			respawn_penalty = new_respawn_penalty or c.respawn_penalty
			hostages_killed = c.hostages_killed
			table.remove(self._criminals_to_respawn, i)
		else
		end
	end
	if respawn_penalty then
		if respawn_penalty <= 0 then
			respawn_penalty = 1
		end
		return self:on_player_criminal_death(player_criminal, respawn_penalty, hostages_killed, true)
	end
end
function TradeManager:replace_player_with_ai(player_criminal, ai_criminal, new_respawn_penalty)
	print("[TradeManager:replace_player_with_ai]", player_criminal)
	local first_crim = self._criminals_to_respawn[1]
	if first_crim and first_crim.id == player_criminal then
		self:cancel_trade()
	end
	local respawn_penalty, hostages_killed
	for i, c in ipairs(self._criminals_to_respawn) do
		if c.id == player_criminal then
			respawn_penalty = new_respawn_penalty or c.respawn_penalty
			hostages_killed = c.hostages_killed
			table.remove(self._criminals_to_respawn, i)
		else
		end
	end
	if respawn_penalty then
		if respawn_penalty <= 0 then
			respawn_penalty = 1
		end
		if not Global.criminal_team_AI_disabled and managers.groupai:state():is_AI_enabled() then
			return self:on_AI_criminal_death(ai_criminal, respawn_penalty, hostages_killed, true)
		end
	end
end
function TradeManager:remove_from_trade(criminal)
	local first_crim = self._criminals_to_respawn[1]
	if first_crim and first_crim.id == criminal then
		self:cancel_trade()
	end
	for i, c in ipairs(self._criminals_to_respawn) do
		if c.id == criminal then
			table.remove(self._criminals_to_respawn, i)
		else
		end
	end
end
function TradeManager:_send_finish_trade(criminal, respawn_delay, hostages_killed)
	if criminal.ai == true then
		return
	end
	local peer_id = managers.criminals:character_peer_id_by_name(criminal.id)
	if peer_id == 1 then
		if game_state_machine:current_state_name() == "ingame_waiting_for_respawn" then
			game_state_machine:current_state():finish_trade()
		end
	else
		local peer = managers.network:session():peer(peer_id)
		if peer then
			peer:send_queued_sync("finish_trade")
		end
	end
end
function TradeManager:_send_begin_trade(criminal)
	if criminal.ai == true then
		return
	end
	local peer_id = managers.criminals:character_peer_id_by_name(criminal.id)
	if peer_id == 1 then
		if game_state_machine:current_state_name() == "ingame_waiting_for_respawn" then
			game_state_machine:current_state():begin_trade()
		end
	else
		local peer = managers.network:session():peer(peer_id)
		if peer then
			peer:send_queued_sync("begin_trade")
		end
	end
end
function TradeManager:_send_cancel_trade(criminal)
	if criminal.ai == true then
		return
	end
	local peer_id = managers.criminals:character_peer_id_by_name(criminal.id)
	if peer_id == 1 then
		if game_state_machine:current_state_name() == "ingame_waiting_for_respawn" then
			game_state_machine:current_state():cancel_trade()
		end
	else
		local peer = managers.network:session():peer(peer_id)
		if peer then
			peer:send_queued_sync("cancel_trade")
		end
	end
end
function TradeManager:change_hostage()
	self:sync_hostage_trade_dialog(6)
	managers.network:session():send_to_peers("hostage_trade_dialog", 6)
	self:cancel_trade()
end
function TradeManager:cancel_trade()
	if not next(managers.groupai:state():all_player_criminals()) then
		return
	end
	self._trading_hostage = nil
	if #self._criminals_to_respawn > 0 then
		self:_send_cancel_trade(self._criminals_to_respawn[1])
	end
	if self._hostage_trade_clbk then
		self._cancel_trade = true
	end
	if self._hostage_to_trade then
		if alive(self._hostage_to_trade.unit) then
			self._hostage_to_trade.unit:brain():cancel_trade()
		end
		self._hostage_to_trade = nil
	end
end
function TradeManager:_get_megaphone_sound_source()
	local level_id = Global.level_data.level_id
	local pos
	if not level_id then
		pos = Vector3(0, 0, 0)
		Application:error("[TradeManager:_get_megaphone_sound_source] This level has no megaphone position!")
	elseif not tweak_data.levels[level_id].megaphone_pos then
		pos = Vector3(0, 0, 0)
	else
		pos = tweak_data.levels[level_id].megaphone_pos
	end
	local sound_source = SoundDevice:create_source("megaphone")
	sound_source:set_position(pos)
	return sound_source
end
function TradeManager:sync_hostage_trade_dialog(i)
	if game_state_machine:current_state_name() == "ingame_waiting_for_respawn" or not managers.groupai:state():bain_state() then
		return
	end
	if i == 1 then
		print("Playing mga_t01a_con_plu")
		self:_get_megaphone_sound_source():post_event("mga_t01a_con_plu")
	elseif i == 2 then
		managers.dialog:queue_dialog("ban_h02a", {})
	elseif i == 3 then
		managers.dialog:queue_dialog("ban_h02b", {})
	elseif i == 4 then
		managers.dialog:queue_dialog("ban_h02c", {})
	elseif i == 5 then
		managers.dialog:queue_dialog("ban_h02d", {})
	elseif i == 6 then
		managers.dialog:queue_dialog("Play_ban_h50x", {})
	end
end
function TradeManager:begin_hostage_trade_dialog(i)
	print("begin_hostage_trade_dialog", i)
	if self._cancel_trade then
		self._hostage_trade_clbk = nil
		self._cancel_trade = nil
		return
	end
	if i == 1 then
		self._megaphone_sound_source = self:_get_megaphone_sound_source()
		print("Snd: megaphone", self._megaphone_sound_source)
		if not self._megaphone_sound_source:post_event("mga_t01a_con_plu", callback(self, self, "begin_hostage_trade_dialog", 2), nil, "end_of_event") then
			self:begin_hostage_trade_dialog(2)
			print("Megaphone fail")
		end
	elseif i == 2 then
		local ssuffix = managers.criminals:character_static_data_by_name(self:get_criminal_to_trade().id).ssuffix
		if ssuffix == "a" then
			i = 2
		elseif ssuffix == "b" then
			i = 3
		elseif ssuffix == "c" then
			i = 4
		elseif ssuffix == "d" then
			i = 5
		end
		self:sync_hostage_trade_dialog(i)
		local respawn_t = self._t + 5
		managers.enemy:add_delayed_clbk(self._hostage_trade_clbk, callback(self, self, "begin_hostage_trade"), respawn_t)
	end
	managers.network:session():send_to_peers("hostage_trade_dialog", i)
end
function TradeManager:begin_hostage_trade()
	print("begin_hostage_trade")
	if self._cancel_trade then
		self._hostage_trade_clbk = nil
		self._cancel_trade = nil
		return
	end
	self._hostage_trade_clbk = nil
	self:_send_begin_trade(self._criminals_to_respawn[1])
	local possible_criminals = {}
	for u_key, u_data in pairs(managers.groupai:state():all_player_criminals()) do
		if u_data.status ~= "dead" then
			table.insert(possible_criminals, u_key)
		end
	end
	local rescuing_criminal = possible_criminals[math.random(1, #possible_criminals)]
	rescuing_criminal = managers.groupai:state():all_criminals()[rescuing_criminal]
	local rescuing_criminal_pos
	local civilians = managers.enemy:all_civilians()
	if rescuing_criminal then
		rescuing_criminal_pos = rescuing_criminal.m_pos
	else
		local _, first_civ = next(civilians)
		rescuing_criminal_pos = first_civ and first_civ.m_pos
	end
	local trade_dist = tweak_data.group_ai.optimal_trade_distance
	local optimal_trade_dist = math.random(trade_dist[1], trade_dist[2])
	local best_hostage_d, best_hostage
	for _, h_key in ipairs(managers.groupai:state():all_hostages()) do
		local civ = civilians[h_key]
		if civ and civ.unit:character_damage():pickup() then
			civ = nil
		end
		local hostage = civ or managers.enemy:all_enemies()[h_key]
		if hostage then
			local d = math.abs(mvector3.distance(hostage.m_pos, rescuing_criminal_pos) - optimal_trade_dist)
			if not best_hostage_d or best_hostage_d > d then
				best_hostage_d = d
				best_hostage = hostage
			end
		end
	end
	if best_hostage then
		self._trading_hostage = true
		self._hostage_to_trade = best_hostage
		best_hostage.unit:brain():set_logic("trade")
		if not rescuing_criminal then
		end
	end
end
function TradeManager:on_hostage_traded(trading_unit)
	print("RC: Traded hostage!!")
	if self._criminal_respawn_clbk then
		return
	end
	self._hostage_to_trade = nil
	local respawn_criminal = self:get_criminal_to_trade()
	local respawn_delay = respawn_criminal.respawn_penalty
	self:_send_finish_trade(respawn_criminal, respawn_delay, respawn_criminal.hostages_killed)
	local respawn_t = self._t + 2
	local clbk_id = "Respawn_criminal_on_trade"
	self._criminal_respawn_clbk = clbk_id
	managers.enemy:add_delayed_clbk(clbk_id, callback(self, self, "clbk_respawn_criminal", trading_unit), respawn_t)
end
function TradeManager:clbk_respawn_criminal(trading_unit)
	self._criminal_respawn_clbk = nil
	self._trading_hostage = nil
	local spawn_on_unit = trading_unit
	if not alive(spawn_on_unit) then
		local possible_criminals = {}
		for u_key, u_data in pairs(managers.groupai:state():all_char_criminals()) do
			if u_data.status ~= "dead" then
				table.insert(possible_criminals, u_data.unit)
			end
		end
		if #possible_criminals <= 0 then
			return
		end
		spawn_on_unit = possible_criminals[math.random(1, #possible_criminals)]
	end
	local respawn_criminal = self:get_criminal_to_trade()
	if not respawn_criminal then
		return
	end
	print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
	print("Found criminal to respawn ", respawn_criminal and inspect(respawn_criminal))
	for i, crim in ipairs(self._criminals_to_respawn) do
		if crim == respawn_criminal then
			print("Removing from list")
			table.remove(self._criminals_to_respawn, i)
		else
		end
	end
	self._num_trades = self._num_trades + 1
	managers.network:session():send_to_peers_synched("set_trade_spawn", respawn_criminal.id)
	self:_announce_spawn(respawn_criminal.id)
	local spawned_unit
	if respawn_criminal.ai then
		print("RC: respawn AI", respawn_criminal.id)
		spawned_unit = managers.groupai:state():spawn_one_teamAI(false, respawn_criminal.id, spawn_on_unit)
	else
		print("RC: respawn human", respawn_criminal.id)
		local sp_id = "clbk_respawn_criminal"
		local spawn_point = {
			position = spawn_on_unit:position(),
			rotation = spawn_on_unit:rotation()
		}
		managers.network:register_spawn_point(sp_id, spawn_point)
		local peer_id = managers.criminals:character_peer_id_by_name(respawn_criminal.id)
		spawned_unit = managers.network:game():spawn_member_by_id(peer_id, sp_id, true)
		managers.network:unregister_spawn_point(sp_id)
	end
	if alive(spawned_unit) and alive(trading_unit) then
		self:sync_teammate_helped_hint(spawned_unit, trading_unit, 1)
		managers.network:session():send_to_peers_synched("sync_teammate_helped_hint", 1, spawned_unit, trading_unit)
	end
end
function TradeManager:sync_teammate_helped_hint(helped_unit, helping_unit, hint)
	if not alive(helped_unit) or not alive(helping_unit) then
		return
	end
	local peer_id = managers.network:session():local_peer():id()
	if not managers.network:game():member(peer_id) then
		debug_pause("[TradeManager:sync_teammate_helped_hint] Couldn't get local unit! ", peer_id)
	end
	local local_unit = managers.criminals:character_unit_by_name(managers.criminals:local_character_name())
	local hint_id = "teammate"
	if local_unit == helped_unit then
		hint_id = "you_were"
	elseif local_unit == helping_unit then
		hint_id = "you"
	end
	if not hint or hint == 1 then
		hint_id = hint_id .. "_revived"
	elseif hint == 2 then
		hint_id = hint_id .. "_helpedup"
	elseif hint == 3 then
		hint_id = hint_id .. "_rescued"
	end
	if hint_id then
		managers.hint:show_hint(hint_id, nil, false, {
			TEAMMATE = helped_unit:base():nick_name(),
			HELPER = helping_unit:base():nick_name()
		})
	end
end
