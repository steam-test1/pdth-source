NetworkMember = NetworkMember or class()
function NetworkMember:init(peer)
	self._peer = peer
end
function NetworkMember:delete()
	if managers.criminals then
		managers.criminals:remove_character_by_peer_id(self._peer:id())
	end
	if alive(self._unit) then
		if self._unit:id() ~= -1 then
			Network:detach_unit(self._unit)
		end
		if self._unit:base() and self._unit:base().set_slot then
			self._unit:base():set_slot(self._unit, 0)
		else
			self._unit:set_slot(0)
		end
	end
	self._unit = nil
	if self._assigned_name then
		managers.groupai:state():demark_one_teamAI_for_removal(self._assigned_name)
		self._assigned_name = nil
	end
	managers.player:remove_crew_bonus(self._peer:id())
end
function NetworkMember:load(data)
	self._peer = managers.network:session():peer(data.id)
end
function NetworkMember:save()
	local data = {}
	data.id = self._peer:id()
	return data
end
function NetworkMember:peer()
	return self._peer
end
function NetworkMember:unit()
	return self._unit
end
function NetworkMember:_get_old_entry()
	local peer_ident = SystemInfo:platform() == Idstring("WIN32") and self._peer:user_id() or self._peer:name()
	local old_plr_entry = managers.network:game()._old_players[peer_ident]
	local member_downed
	local health = 1
	local used_deployable = false
	local member_dead
	if old_plr_entry and old_plr_entry.t + 180 > Application:time() then
		member_downed = old_plr_entry.member_downed
		health = old_plr_entry.health
		used_deployable = old_plr_entry.used_deployable
		member_dead = old_plr_entry.member_dead
	end
	return member_downed, member_dead, health, used_deployable
end
function NetworkMember:assign_character_name()
	local character_name = managers.criminals:character_name_by_unit(self._unit)
	if not character_name then
		character_name = managers.criminals:get_free_character_name()
		if not character_name then
			local member_downed, member_dead, health, used_deployable = self:_get_old_entry()
			character_name = managers.groupai:state():mark_one_teamAI_for_removal(member_downed, member_dead)
		end
	end
	self._assigned_name = character_name
	return character_name
end
function NetworkMember:spawn_unit(spawn_point_id, is_drop_in, spawn_as)
	if self._unit then
		return
	end
	if not self._peer:synched() then
		return
	end
	local peer_id = self._peer:id()
	self._spawn_unit_called = true
	local pos_rot
	if is_drop_in then
		local spawn_on
		if Global.local_member and alive(Global.local_member:unit()) then
			spawn_on = Global.local_member:unit()
		end
		if not spawn_on then
			local u_key, u_data = next(managers.groupai:state():all_char_criminals())
			if u_data and alive(u_data.unit) then
				spawn_on = u_data.unit
			end
		end
		if spawn_on then
			local pos = spawn_on:position()
			local rot = spawn_on:rotation()
			pos_rot = {pos, rot}
		else
			local spawn_point = managers.network:game():get_next_spawn_point() or managers.network:spawn_point(1)
			pos_rot = spawn_point.pos_rot
		end
	else
		pos_rot = managers.network:spawn_point(spawn_point_id).pos_rot
	end
	local member_downed, member_dead, health, used_deployable = self:_get_old_entry()
	local character_name, trade_entry, need_revive, need_res
	if self._assigned_name then
		print("[NetworkMember:spawn_unit] Member assigned as", self._assigned_name)
		local old_unit
		trade_entry, old_unit = managers.groupai:state():remove_one_teamAI(self._assigned_name, member_dead)
		if trade_entry and member_dead then
			trade_entry.peer_id = peer_id
		end
		character_name = self._assigned_name
		self._assigned_name = nil
		if alive(old_unit) then
			need_revive = old_unit:character_damage():bleed_out() or old_unit:character_damage():fatal() or old_unit:character_damage():arrested() or old_unit:character_damage():need_revive() or old_unit:character_damage():dead()
		end
		need_revive = need_revive or Global.criminal_team_AI_disabled or not managers.groupai:state():is_AI_enabled()
		need_res = trade_entry and true or Global.criminal_team_AI_disabled or not managers.groupai:state():is_AI_enabled()
	else
		character_name = managers.criminals:character_name_by_peer_id(peer_id)
		if not character_name then
			if spawn_as and not managers.criminals:is_taken(spawn_as) then
				character_name = spawn_as
			else
				character_name = managers.criminals:get_free_character_name()
			end
			if not character_name then
				cat_error("multiplayer_base", "[NetworkMember:spawn_unit] failed to find available character name for peer", peer_id)
				return
			end
		end
	end
	local lvl_tweak_data = Global.level_data and Global.level_data.level_id and tweak_data.levels[Global.level_data.level_id]
	local unit_name_suffix = lvl_tweak_data and lvl_tweak_data.unit_suit or "suit"
	local unit_name = Idstring("units/multiplayer/mp_fps_mover/mp_fps_mover_" .. unit_name_suffix)
	local unit
	if self == Global.local_member then
		unit = World:spawn_unit(unit_name, pos_rot[1], pos_rot[2])
	else
		unit = Network:spawn_unit_on_client(self._peer:rpc(), unit_name, pos_rot[1], pos_rot[2])
	end
	self:set_unit(unit, character_name)
	managers.network:session():send_to_peers_synched("set_unit", unit, character_name, peer_id)
	if is_drop_in then
		self._peer:set_used_deployable(used_deployable)
		self._peer:send_queued_sync("spawn_dropin_penalty", (need_res or need_revive) and member_dead, (need_res or need_revive) and member_downed, health, used_deployable)
	end
	return unit
end
function NetworkMember:set_unit(unit, character_name)
	local is_new_unit = unit and (not self._unit or self._unit:key() ~= unit:key())
	self._unit = unit
	if is_new_unit and self == Global.local_member then
		managers.player:spawned_player(1, unit)
	end
	if unit then
		if not managers.criminals:character_name_by_peer_id(self._peer:id()) then
			managers.criminals:add_character(character_name, unit, self._peer:id(), false)
		else
			managers.criminals:set_unit(character_name, unit)
		end
	end
	if is_new_unit then
		unit:movement():set_character_anim_variables()
		if self ~= Global.local_member then
			managers.player:update_crew_bonus_enabled(self._peer:id(), unit:movement():current_state_name())
		end
	end
end
function NetworkMember:sync_lobby_data(peer)
	print("[NetworkMember:sync_lobby_data] to", peer:id())
	local peer_id = managers.network:session():local_peer():id()
	local level = managers.experience:current_level()
	local character = managers.network:session():local_peer():character()
	local mask_set = managers.network:session():local_peer():mask_set()
	local progress = managers.upgrades:progress()
	cat_print("multiplayer_base", "NetworkMember:sync_lobby_data to", peer:id(), " : ", peer_id, level)
	peer:send_after_load("lobby_info", peer_id, level, character, mask_set, progress[1], progress[2], progress[3], progress[4] or -1)
	if Network:is_server() then
		local level_id_index = tweak_data.levels:get_index_from_level_id(Global.game_settings.level_id)
		peer:send_after_load("lobby_sync_update_level_id", level_id_index)
		local difficulty = Global.game_settings.difficulty
		peer:send_after_load("lobby_sync_update_difficulty", difficulty)
	end
end
function NetworkMember:sync_data(peer)
	print("[NetworkMember:sync_data] to", peer:id())
	managers.player:update_crew_bonus_to_peer(peer)
	managers.player:update_kit_to_peer(peer)
	managers.player:update_equipment_possession_to_peer(peer)
	if self._unit then
	end
end
function NetworkMember:spawn_unit_called()
	return self._spawn_unit_called
end
function NetworkMember:drop_in_progress()
	return self._dropin_progress
end
function NetworkMember:set_drop_in_progress(dropin_progress)
	self._dropin_progress = dropin_progress
end
function NetworkMember:character_name()
	return self._assigned_name
end
