UnitNetworkHandler = UnitNetworkHandler or class(BaseNetworkHandler)
function UnitNetworkHandler:set_unit(unit, character_name, peer_id)
	print("[UnitNetworkHandler:set_unit]", unit, character_name, peer_id)
	Application:stack_dump()
	if not alive(unit) then
		return
	end
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) then
		return
	end
	if peer_id == 0 then
		local crim_data = managers.criminals:character_data_by_name(character_name)
		if not crim_data or not crim_data.ai then
			managers.criminals:add_character(character_name, unit, peer_id, true)
		else
			managers.criminals:set_unit(character_name, unit)
		end
		unit:movement():set_character_anim_variables()
		return
	end
	local peer = managers.network:session():peer(peer_id)
	if not peer then
		return
	end
	local member = managers.network:game():member_peer(peer)
	if member then
		member:set_unit(unit, character_name)
	elseif unit then
		if unit:base() and unit:base().set_slot then
			unit:base():set_slot(unit, 0)
		else
			unit:set_slot(0)
		end
	end
	self:_chk_flush_unit_too_early_packets(unit)
end
function UnitNetworkHandler:set_equipped_weapon(unit, item_index, sender)
	if not self._verify_character_and_sender(unit, sender) then
		return
	end
	unit:inventory():synch_equipped_weapon(item_index)
end
function UnitNetworkHandler:set_look_dir(unit, dir, sender)
	if not self._verify_character_and_sender(unit, sender) then
		return
	end
	unit:movement():sync_look_dir(dir)
end
function UnitNetworkHandler:action_walk_start(unit, first_nav_point, nav_link_yaw, nav_link_act_index, from_idle, haste_code, end_yaw, no_walk, no_strafe)
	if not self._verify_character(unit) or not self._verify_gamestate(self._gamestate_filter.any_ingame) then
		return
	end
	local end_rot
	if end_yaw ~= 0 then
		end_rot = Rotation(360 * (end_yaw - 1) / 254, 0, 0)
	end
	local nav_path = {
		unit:position()
	}
	if nav_link_act_index ~= 0 then
		local nav_link_rot = Rotation(360 * nav_link_yaw / 255, 0, 0)
		local nav_link = unit:movement()._actions.walk.synthesize_nav_link(first_nav_point, nav_link_rot, unit:movement()._actions.act:_get_act_name_from_index(nav_link_act_index), from_idle)
		function nav_link.element.value(element, name)
			return element[name]
		end
		function nav_link.element.nav_link_wants_align_pos(element)
			return element.from_idle
		end
		table.insert(nav_path, nav_link)
	else
		table.insert(nav_path, first_nav_point)
	end
	local action_desc = {
		type = "walk",
		variant = haste_code == 1 and "walk" or "run",
		end_rot = end_rot,
		body_part = 2,
		nav_path = nav_path,
		path_simplified = true,
		persistent = true,
		no_walk = no_walk,
		no_strafe = no_strafe,
		blocks = {
			walk = -1,
			turn = -1,
			act = -1,
			idle = -1
		}
	}
	unit:movement():action_request(action_desc)
end
function UnitNetworkHandler:action_walk_nav_point(unit, nav_point, sender)
	if not self._verify_character_and_sender(unit, sender) or not self._verify_gamestate(self._gamestate_filter.any_ingame) then
		return
	end
	unit:movement():sync_action_walk_nav_point(nav_point)
end
function UnitNetworkHandler:action_walk_stop(unit, pos)
	if not self._verify_character(unit) or not self._verify_gamestate(self._gamestate_filter.any_ingame) then
		return
	end
	unit:movement():sync_action_walk_stop(pos)
end
function UnitNetworkHandler:action_walk_nav_link(unit, pos, yaw, anim_index, from_idle)
	if not self._verify_character(unit) or not self._verify_gamestate(self._gamestate_filter.any_ingame) then
		return
	end
	local rot = Rotation(360 * yaw / 255, 0, 0)
	unit:movement():sync_action_walk_nav_link(pos, rot, anim_index, from_idle)
end
function UnitNetworkHandler:action_spooc_start(unit)
	if not self._verify_character(unit) or not self._verify_gamestate(self._gamestate_filter.any_ingame) then
		return
	end
	local action_desc = {
		type = "spooc",
		body_part = 1,
		block_type = "walk",
		nav_path = {
			unit:position()
		},
		path_index = 1,
		blocks = {
			walk = -1,
			turn = -1,
			act = -1,
			idle = -1
		}
	}
	unit:movement():action_request(action_desc)
end
function UnitNetworkHandler:action_spooc_stop(unit, pos, nav_index)
	if not self._verify_character(unit) then
		return
	end
	unit:movement():sync_action_spooc_stop(pos, nav_index)
end
function UnitNetworkHandler:action_spooc_nav_point(unit, pos, sender)
	if not self._verify_character_and_sender(unit, sender) or not self._verify_gamestate(self._gamestate_filter.any_ingame) then
		return
	end
	unit:movement():sync_action_spooc_nav_point(pos)
end
function UnitNetworkHandler:action_spooc_strike(unit, pos, sender)
	if not self._verify_character_and_sender(unit, sender) or not self._verify_gamestate(self._gamestate_filter.any_ingame) then
		return
	end
	unit:movement():sync_action_spooc_strike(pos)
end
function UnitNetworkHandler:friendly_fire_hit(subject_unit)
	if not self._verify_character(subject_unit) or not self._verify_gamestate(self._gamestate_filter.any_ingame) then
		return
	end
	subject_unit:character_damage():friendly_fire_hit()
end
function UnitNetworkHandler:damage_bullet(subject_unit, attacker_unit, damage, i_body, height_offset, sender)
	if not self._verify_character_and_sender(subject_unit, sender) or not self._verify_gamestate(self._gamestate_filter.any_ingame) then
		return
	end
	if not alive(attacker_unit) or attacker_unit:key() == subject_unit:key() then
		attacker_unit = nil
	end
	subject_unit:character_damage():sync_damage_bullet(attacker_unit, damage, i_body, height_offset)
end
function UnitNetworkHandler:damage_explosion(subject_unit, attacker_unit, damage, i_body, sender)
	if not self._verify_character_and_sender(subject_unit, sender) or not self._verify_gamestate(self._gamestate_filter.any_ingame) then
		return
	end
	if not alive(attacker_unit) or attacker_unit:key() == subject_unit:key() then
		attacker_unit = nil
	end
	subject_unit:character_damage():sync_damage_explosion(attacker_unit, damage, i_body)
end
function UnitNetworkHandler:damage_melee(subject_unit, attacker_unit, damage, i_body, height_offset, sender)
	if not self._verify_character_and_sender(subject_unit, sender) or not self._verify_gamestate(self._gamestate_filter.any_ingame) then
		return
	end
	if not alive(attacker_unit) or attacker_unit:key() == subject_unit:key() then
		attacker_unit = nil
	end
	subject_unit:character_damage():sync_damage_melee(attacker_unit, damage, i_body, height_offset)
end
function UnitNetworkHandler:from_server_damage_bullet(subject_unit, attacker_unit, hit_offset_height, result_index, sender)
	if not self._verify_character_and_sender(subject_unit, sender) or not self._verify_gamestate(self._gamestate_filter.any_ingame) then
		return
	end
	if not alive(attacker_unit) or attacker_unit:key() == subject_unit:key() then
		attacker_unit = nil
	end
	subject_unit:character_damage():sync_damage_bullet(attacker_unit, hit_offset_height, result_index)
end
function UnitNetworkHandler:from_server_damage_explosion(subject_unit, attacker_unit, result_index, sender)
	if not self._verify_character(subject_unit) or not self._verify_gamestate(self._gamestate_filter.any_ingame) then
		return
	end
	if not alive(attacker_unit) or attacker_unit:key() == subject_unit:key() then
		attacker_unit = nil
	end
	subject_unit:character_damage():sync_damage_explosion(attacker_unit, result_index)
end
function UnitNetworkHandler:from_server_damage_melee(subject_unit, attacker_unit, hit_offset_height, result_index, sender)
	if not self._verify_character(subject_unit) or not self._verify_gamestate(self._gamestate_filter.any_ingame) then
		return
	end
	if not alive(attacker_unit) or attacker_unit:key() == subject_unit:key() then
		attacker_unit = nil
	end
	subject_unit:character_damage():sync_damage_melee(attacker_unit, attacker_unit, hit_offset_height, result_index)
end
function UnitNetworkHandler:from_server_damage_incapacitated(subject_unit, sender)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) or not self._verify_character(subject_unit) then
		return
	end
	subject_unit:character_damage():sync_damage_incapacitated()
end
function UnitNetworkHandler:from_server_damage_bleeding(subject_unit)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) or not self._verify_character(subject_unit) then
		return
	end
	subject_unit:character_damage():sync_damage_bleeding()
end
function UnitNetworkHandler:from_server_damage_tase(subject_unit)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) or not self._verify_character(subject_unit) then
		return
	end
	subject_unit:character_damage():sync_damage_tase()
end
function UnitNetworkHandler:from_server_unit_recovered(subject_unit)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) or not self._verify_character(subject_unit) then
		return
	end
	subject_unit:character_damage():sync_unit_recovered()
end
function UnitNetworkHandler:shot_blank(shooting_unit, impact, sender)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) or not self._verify_character_and_sender(shooting_unit, sender) then
		return
	end
	shooting_unit:movement():sync_shot_blank(impact)
end
function UnitNetworkHandler:reload_weapon(unit, sender)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) or not self._verify_character_and_sender(unit, sender) then
		return
	end
	unit:movement():sync_reload_weapon()
end
function UnitNetworkHandler:run_mission_element(id, unit)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) then
		return
	end
	managers.mission:client_run_mission_element(id, unit)
end
function UnitNetworkHandler:run_mission_element_no_instigator(id)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) then
		return
	end
	managers.mission:client_run_mission_element(id)
end
function UnitNetworkHandler:to_server_mission_element_trigger(id, unit)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) then
		return
	end
	managers.mission:server_run_mission_element_trigger(id, unit)
end
function UnitNetworkHandler:to_server_enter_area(id, unit)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) then
		return
	end
	managers.mission:server_enter_area(id, unit)
end
function UnitNetworkHandler:to_server_exit_area(id, unit)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) then
		return
	end
	managers.mission:server_exit_area(id, unit)
end
function UnitNetworkHandler:sync_body_damage_bullet(body, attacker, normal, position, direction, damage)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) then
		return
	end
	if not alive(body) then
		return
	end
	if not body:extension() then
		print("[UnitNetworkHandler:sync_body_damage_bullet] body has no extension", body:name(), body:unit():name())
		return
	end
	if not body:extension().damage then
		print("[UnitNetworkHandler:sync_body_damage_bullet] body has no damage extension", body:name(), body:unit():name())
		return
	end
	if not body:extension().damage.damage_bullet then
		print("[UnitNetworkHandler:sync_body_damage_bullet] body has no damage damage_bullet function", body:name(), body:unit():name())
		return
	end
	body:extension().damage:damage_bullet(attacker, normal, position, direction, 1)
	body:extension().damage:damage_damage(attacker, normal, position, direction, damage)
end
function UnitNetworkHandler:sync_body_damage_bullet_no_attacker(body, normal, position, direction, damage)
	self:sync_body_damage_bullet(body, nil, normal, position, direction, damage)
end
function UnitNetworkHandler:sync_body_damage_explosion(body, attacker, normal, position, direction, damage)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) then
		return
	end
	if not alive(body) then
		return
	end
	if not body:extension() then
		print("[UnitNetworkHandler:sync_body_damage_explosion] body has no extension", body:name(), body:unit():name())
		return
	end
	if not body:extension().damage then
		print("[UnitNetworkHandler:sync_body_damage_explosion] body has no damage extension", body:name(), body:unit():name())
		return
	end
	if not body:extension().damage.damage_explosion then
		print("[UnitNetworkHandler:sync_body_damage_explosion] body has no damage damage_explosion function", body:name(), body:unit():name())
		return
	end
	body:extension().damage:damage_explosion(attacker, normal, position, direction, damage)
	body:extension().damage:damage_damage(attacker, normal, position, direction, damage)
end
function UnitNetworkHandler:sync_body_damage_explosion_no_attacker(body, normal, position, direction, damage)
	self:sync_body_damage_explosion(body, nil, normal, position, direction, damage)
end
function UnitNetworkHandler:sync_body_damage_melee(body, attacker, normal, position, direction, damage)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) then
		return
	end
	if not alive(body) then
		return
	end
	if not body:extension() then
		print("[UnitNetworkHandler:sync_body_damage_melee] body has no extension", body:name(), body:unit():name())
		return
	end
	if not body:extension().damage then
		print("[UnitNetworkHandler:sync_body_damage_melee] body has no damage extension", body:name(), body:unit():name())
		return
	end
	if not body:extension().damage.damage_melee then
		print("[UnitNetworkHandler:sync_body_damage_melee] body has no damage damage_melee function", body:name(), body:unit():name())
		return
	end
	body:extension().damage:damage_melee(attacker, normal, position, direction, damage)
end
function UnitNetworkHandler:sync_interacted(unit)
	if not alive(unit) or not self._verify_gamestate(self._gamestate_filter.any_ingame) then
		return
	end
	unit:interaction():sync_interacted()
end
function UnitNetworkHandler:sync_interaction_set_active(unit, active, sender)
	if not (alive(unit) and self._verify_gamestate(self._gamestate_filter.any_ingame)) or not self._verify_sender(sender) then
		return
	end
	unit:interaction():set_active(active)
end
function UnitNetworkHandler:action_aim_start(cop)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) or not self._verify_character(cop) then
		return
	end
	local shoot_action = {
		type = "shoot",
		body_part = 3,
		block_type = "action"
	}
	cop:movement():action_request(shoot_action)
end
function UnitNetworkHandler:action_aim_end(cop)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) or not self._verify_character(cop) then
		return
	end
	cop:movement():sync_action_aim_end()
end
function UnitNetworkHandler:action_hurt_end(unit)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) or not self._verify_character(unit) then
		return
	end
	unit:movement():sync_action_hurt_end()
end
function UnitNetworkHandler:cop_set_attention_unit(unit, target_unit)
	if not (self._verify_gamestate(self._gamestate_filter.any_ingame) and self._verify_character(unit)) or not self._verify_character(target_unit) then
		return
	end
	unit:movement():synch_attention({unit = target_unit})
end
function UnitNetworkHandler:cop_set_attention_pos(unit, pos)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) or not self._verify_character(unit) then
		return
	end
	unit:movement():synch_attention({pos = pos})
end
function UnitNetworkHandler:cop_reset_attention(unit)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) or not self._verify_character(unit) then
		return
	end
	unit:movement():synch_attention()
end
function UnitNetworkHandler:cop_allow_fire(unit)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) or not self._verify_character(unit) then
		return
	end
	unit:movement():synch_allow_fire(true)
end
function UnitNetworkHandler:cop_forbid_fire(unit)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) or not self._verify_character(unit) then
		return
	end
	unit:movement():synch_allow_fire(false)
end
function UnitNetworkHandler:set_stance(unit, stance_code, sender)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) or not self._verify_character_and_sender(unit, sender) then
		return
	end
	unit:movement():sync_stance(stance_code)
end
function UnitNetworkHandler:set_pose(unit, pose_code, sender)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) or not self._verify_character_and_sender(unit, sender) then
		return
	end
	unit:movement():sync_pose(pose_code)
end
function UnitNetworkHandler:cop_on_intimidated(cop, amount, aggressor)
	if not (self._verify_gamestate(self._gamestate_filter.any_ingame) and self._verify_character(cop)) or not alive(aggressor) then
		return
	end
	if cop:in_slot(managers.slot:get_mask("criminals")) or cop:in_slot(managers.slot:get_mask("harmless_criminals")) then
		if aggressor:in_slot(managers.slot:get_mask("criminals")) then
			cop:brain():on_long_dis_interacted(aggressor)
		else
			cop:brain():on_intimidated(amount / 10, aggressor)
		end
	else
		cop:brain():on_intimidated(amount / 10, aggressor)
	end
end
function UnitNetworkHandler:unit_tied(unit, aggressor)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) or not self._verify_character(unit) then
		return
	end
	unit:brain():on_tied(aggressor)
end
function UnitNetworkHandler:unit_traded(unit, trader)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) or not self._verify_character(unit) then
		return
	end
	unit:brain():on_trade(trader)
end
function UnitNetworkHandler:hostage_trade(unit, enable)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) or not self._verify_character(unit) then
		return
	end
	CopLogicTrade.hostage_trade(unit, enable)
end
function UnitNetworkHandler:set_unit_invulnerable(unit, enable)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) or not self._verify_character(unit) then
		return
	end
	unit:character_damage():set_invulnerable(enable)
end
function UnitNetworkHandler:set_trade_countdown(enable)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) then
		return
	end
	managers.trade:set_trade_countdown(enable)
end
function UnitNetworkHandler:set_trade_death(criminal_name, respawn_penalty, hostages_killed)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) then
		return
	end
	managers.trade:sync_set_trade_death(criminal_name, respawn_penalty, hostages_killed)
end
function UnitNetworkHandler:set_trade_spawn(criminal_name)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) then
		return
	end
	managers.trade:sync_set_trade_spawn(criminal_name)
end
function UnitNetworkHandler:set_trade_replace(replace_ai, criminal_name1, criminal_name2, respawn_penalty)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) then
		return
	end
	managers.trade:sync_set_trade_replace(replace_ai, criminal_name1, criminal_name2, respawn_penalty)
end
function UnitNetworkHandler:action_idle_start(unit, body_part, sender)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) or not self._verify_character(unit) then
		return
	end
	unit:movement():action_request({type = "idle", body_part = body_part})
end
function UnitNetworkHandler:action_act_start(unit, act_index, blocks_hurt)
	self:action_act_start_align(unit, act_index, blocks_hurt, nil, nil)
end
function UnitNetworkHandler:action_act_start_align(unit, act_index, blocks_hurt, start_yaw, start_pos)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) or not self._verify_character(unit) then
		return
	end
	local start_rot
	if start_yaw and start_yaw ~= 0 then
		start_rot = Rotation(360 * (start_yaw - 1) / 254, 0, 0)
	end
	unit:movement():sync_action_act_start(act_index, blocks_hurt, start_rot, start_pos)
end
function UnitNetworkHandler:action_act_end(unit)
	if not alive(unit) or unit:character_damage():dead() then
		return
	end
	unit:movement():sync_action_act_end()
end
function UnitNetworkHandler:action_dodge_start(unit, variation, direction, rotation)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) or not self._verify_character(unit) then
		return
	end
	unit:movement():sync_action_dodge_start(variation, direction, rotation)
end
function UnitNetworkHandler:action_dodge_end(unit)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) or not self._verify_character(unit) then
		return
	end
	unit:movement():sync_action_dodge_end()
end
function UnitNetworkHandler:action_tase_start(unit)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) or not self._verify_character(unit) then
		return
	end
	local tase_action = {type = "tase", body_part = 3}
	unit:movement():action_request(tase_action)
end
function UnitNetworkHandler:action_tase_end(unit)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) or not self._verify_character(unit) then
		return
	end
	unit:movement():sync_action_tase_end()
end
function UnitNetworkHandler:action_tase_fire(unit, sender)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) or not self._verify_character_and_sender(unit, sender) then
		return
	end
	unit:movement():sync_taser_fire()
end
function UnitNetworkHandler:alert(alerted_unit, aggressor)
	if not (self._verify_gamestate(self._gamestate_filter.any_ingame) and self._verify_character(alerted_unit)) or not self._verify_character(aggressor) then
		return
	end
	local record = managers.groupai:state():criminal_record(aggressor:key())
	if not record then
		return
	end
	alerted_unit:brain():on_alert({
		false,
		aggressor:position(),
		false,
		aggressor
	})
end
function UnitNetworkHandler:revive_player(sender)
	if not self._verify_gamestate(self._gamestate_filter.need_revive) or not self._verify_sender(sender) then
		return
	end
	managers.player:player_unit():character_damage():revive()
end
function UnitNetworkHandler:start_revive_player(sender)
	if not self._verify_gamestate(self._gamestate_filter.downed) or not self._verify_sender(sender) then
		return
	end
	local player = managers.player:player_unit()
	player:character_damage():pause_downed_timer()
end
function UnitNetworkHandler:interupt_revive_player(sender)
	if not self._verify_gamestate(self._gamestate_filter.downed) or not self._verify_sender(sender) then
		return
	end
	local player = managers.player:player_unit()
	player:character_damage():unpause_downed_timer()
end
function UnitNetworkHandler:start_free_player(sender)
	if not self._verify_gamestate(self._gamestate_filter.arrested) or not self._verify_sender(sender) then
		return
	end
	local player = managers.player:player_unit()
	player:character_damage():pause_arrested_timer()
end
function UnitNetworkHandler:interupt_free_player(sender)
	if not self._verify_gamestate(self._gamestate_filter.arrested) or not self._verify_sender(sender) then
		return
	end
	local player = managers.player:player_unit()
	player:character_damage():unpause_arrested_timer()
end
function UnitNetworkHandler:pause_arrested_timer(unit, sender)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) or not self._verify_character_and_sender(unit, sender) then
		return
	end
	unit:character_damage():pause_arrested_timer()
end
function UnitNetworkHandler:unpause_arrested_timer(unit, sender)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) or not self._verify_character_and_sender(unit, sender) then
		return
	end
	unit:character_damage():unpause_arrested_timer()
end
function UnitNetworkHandler:revive_unit(unit, reviving_unit)
	if not (self._verify_gamestate(self._gamestate_filter.any_ingame) and self._verify_character(unit)) or not alive(reviving_unit) then
		return
	end
	unit:interaction():interact(reviving_unit)
end
function UnitNetworkHandler:pause_bleed_out(unit, sender)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) or not self._verify_character_and_sender(unit, sender) then
		return
	end
	unit:character_damage():pause_bleed_out()
end
function UnitNetworkHandler:unpause_bleed_out(unit, sender)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) or not self._verify_character_and_sender(unit, sender) then
		return
	end
	unit:character_damage():unpause_bleed_out()
end
function UnitNetworkHandler:interaction_set_waypoint_paused(unit, paused, sender)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) or not self._verify_sender(sender) then
		return
	end
	if not alive(unit) then
		return
	end
	if not unit:interaction() then
		return
	end
	unit:interaction():set_waypoint_paused(paused)
end
function UnitNetworkHandler:attach_device(pos, normal, rpc)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) then
		return
	end
	local rot = Rotation(normal, math.UP)
	local peer = self._verify_sender(rpc)
	local unit = TripMineBase.spawn(pos, rot)
	unit:base():set_server_information(peer:id())
	rpc:activate_trip_mine(unit)
end
function UnitNetworkHandler:activate_trip_mine(unit)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) then
		return
	end
	if alive(unit) then
		unit:base():set_active(true, managers.player:player_unit())
	end
end
function UnitNetworkHandler:sync_trip_mine_explode(unit, user_unit, ray_from, ray_to, damage_size, damage, sender)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) or not self._verify_sender(sender) then
		return
	end
	if not alive(user_unit) then
		user_unit = nil
	end
	if alive(unit) then
		unit:base():sync_trip_mine_explode(user_unit, ray_from, ray_to, damage_size, damage)
	end
end
function UnitNetworkHandler:sync_trip_mine_explode_no_user(unit, ray_from, ray_to, damage_size, damage, sender)
	self:sync_trip_mine_explode(unit, nil, ray_from, ray_to, damage_size, damage, sender)
end
function UnitNetworkHandler:sync_trip_mine_set_armed(unit, bool, lenght, sender)
	if not (alive(unit) and self._verify_gamestate(self._gamestate_filter.any_ingame)) or not self._verify_sender(sender) then
		return
	end
	unit:base():sync_trip_mine_set_armed(bool, lenght)
end
function UnitNetworkHandler:sync_trip_mine_beep_explode(unit, sender)
	if not (alive(unit) and self._verify_gamestate(self._gamestate_filter.any_ingame)) or not self._verify_sender(sender) then
		return
	end
	unit:base():sync_trip_mine_beep_explode()
end
function UnitNetworkHandler:m79grenade_explode_on_client(position, normal, user, damage, range, curve_pow, sender)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) or not self._verify_character_and_sender(user, sender) then
		return
	end
	M79GrenadeBase._explode_on_client(position, normal, user, damage, range, curve_pow)
end
function UnitNetworkHandler:place_sentry_gun(pos, rot, ammo_upgrade_lvl, armour_upgrade_lvl, equipment_selection_index, user_unit, rpc)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) or not self._verify_sender(rpc) then
		return
	end
	local peer = self._verify_sender(rpc)
	local unit = SentryGunBase.spawn(pos, rot, ammo_upgrade_lvl, armour_upgrade_lvl)
	if unit then
		unit:base():set_server_information(peer:id())
	end
	if alive(user_unit) and user_unit:id() ~= -1 then
		managers.network:session():send_to_peer_synched(peer, "from_server_sentry_gun_place_result", unit and equipment_selection_index or 0, user_unit)
	end
end
function UnitNetworkHandler:from_server_sentry_gun_place_result(equipment_selection_index, user_unit, rpc)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) or not self._verify_sender(rpc) then
		return
	end
	managers.player:from_server_equipment_place_result(equipment_selection_index, user_unit)
end
function UnitNetworkHandler:place_ammo_bag(pos, rot, ammo_upgrade_lvl, rpc)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) or not self._verify_sender(rpc) then
		return
	end
	local peer = self._verify_sender(rpc)
	local unit = AmmoBagBase.spawn(pos, rot, ammo_upgrade_lvl)
	unit:base():set_server_information(peer:id())
end
function UnitNetworkHandler:sentrygun_ammo(unit, ammo_ratio)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) then
		return
	end
	unit:weapon():sync_ammo(ammo_ratio)
end
function UnitNetworkHandler:sentrygun_health(unit, health_ratio)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) then
		return
	end
	unit:character_damage():sync_health(health_ratio)
end
function UnitNetworkHandler:sync_ammo_bag_setup(unit, ammo_upgrade_lvl)
	if not alive(unit) or not self._verify_gamestate(self._gamestate_filter.any_ingame) then
		return
	end
	unit:base():sync_setup(ammo_upgrade_lvl)
end
function UnitNetworkHandler:sync_ammo_bag_ammo_taken(unit, amount, sender)
	if not (alive(unit) and self._verify_gamestate(self._gamestate_filter.any_ingame)) or not self._verify_sender(sender) then
		return
	end
	unit:base():sync_ammo_taken(amount)
end
function UnitNetworkHandler:place_doctor_bag(pos, rot, amount_upgrade_lvl, rpc)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) or not self._verify_sender(rpc) then
		return
	end
	local peer = self._verify_sender(rpc)
	local unit = DoctorBagBase.spawn(pos, rot, amount_upgrade_lvl)
	unit:base():set_server_information(peer:id())
end
function UnitNetworkHandler:sync_doctor_bag_setup(unit, amount_upgrade_lvl)
	if not alive(unit) or not self._verify_gamestate(self._gamestate_filter.any_ingame) then
		return
	end
	unit:base():sync_setup(amount_upgrade_lvl)
end
function UnitNetworkHandler:sync_doctor_bag_taken(unit, amount, sender)
	if not (alive(unit) and self._verify_gamestate(self._gamestate_filter.any_ingame)) or not self._verify_sender(sender) then
		return
	end
	unit:base():sync_taken(amount)
end
function UnitNetworkHandler:sync_money_wrap_money_taken(unit, sender)
	if not (alive(unit) and self._verify_gamestate(self._gamestate_filter.any_ingame)) or not self._verify_sender(sender) then
		return
	end
	unit:base():sync_money_taken()
end
function UnitNetworkHandler:sync_pickup(unit)
	if not alive(unit) or not self._verify_gamestate(self._gamestate_filter.any_ingame) then
		return
	end
	unit:base():sync_pickup()
end
function UnitNetworkHandler:unit_sound_play(unit, event_index, sender)
	if alive(unit) and self._verify_sender(sender) then
		unit:sound():sync_play(event_index)
	end
end
function UnitNetworkHandler:sync_player_sound(unit, event, source, sender)
	if not (alive(unit) and self._verify_gamestate(self._gamestate_filter.any_ingame)) or not self._verify_sender(sender) then
		return
	end
	if source == "nil" then
		source = nil
	end
	unit:sound():play(event, source)
end
function UnitNetworkHandler:sync_remove_one_teamAI(name, replace_with_player)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) then
		return
	end
	managers.groupai:state():sync_remove_one_teamAI(name, replace_with_player)
end
function UnitNetworkHandler:sync_smoke_grenade(detonate_pos, shooter_pos, duration)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) then
		return
	end
	managers.groupai:state():sync_smoke_grenade(detonate_pos, shooter_pos, duration)
end
function UnitNetworkHandler:sync_smoke_grenade_kill()
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) then
		return
	end
	managers.groupai:state():sync_smoke_grenade_kill()
end
function UnitNetworkHandler:sync_hostage_headcount(value)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) then
		return
	end
	managers.groupai:state():sync_hostage_headcount(value)
end
function UnitNetworkHandler:play_distance_interact_redirect(unit, redirect, sender)
	if not (alive(unit) and self._verify_gamestate(self._gamestate_filter.any_ingame)) or not self._verify_sender(sender) then
		return
	end
	unit:movement():play_redirect(redirect)
end
function UnitNetworkHandler:start_timer_gui(unit, timer, sender)
	if not (alive(unit) and self._verify_gamestate(self._gamestate_filter.any_ingame)) or not self._verify_sender(sender) then
		return
	end
	unit:timer_gui():sync_start(timer)
end
function UnitNetworkHandler:set_jammed_timer_gui(unit, bool)
	if not alive(unit) or not self._verify_gamestate(self._gamestate_filter.any_ingame) then
		return
	end
	unit:timer_gui():sync_set_jammed(bool)
end
function UnitNetworkHandler:give_equipment(equipment, sender)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) or not self._verify_sender(sender) then
		return
	end
	managers.player:add_special({name = equipment})
end
function UnitNetworkHandler:killzone_set_unit(type)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) then
		return
	end
	managers.killzone:set_unit(managers.player:player_unit(), type)
end
function UnitNetworkHandler:dangerzone_set_level(level)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) then
		return
	end
	managers.player:player_unit():character_damage():set_danger_level(level)
end
function UnitNetworkHandler:sync_player_movement_state(unit, state, down_time, unit_id_str)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) then
		return
	end
	self:_chk_unit_too_early(unit, unit_id_str, "sync_player_movement_state", 1, unit, state, down_time, unit_id_str)
	if not alive(unit) then
		return
	end
	if Global.local_member:unit() and unit:key() == Global.local_member:unit():key() then
		local valid_transitions = {
			standard = {
				bleed_out = true,
				arrested = true,
				tased = true,
				incapacitated = true
			},
			mask_off = {standard = true},
			bleed_out = {fatal = true, standard = true},
			fatal = {standard = true},
			arrested = {standard = true},
			tased = {standard = true, incapacitated = true},
			incapacitated = {standard = true},
			clean = {mask_off = true, standard = true}
		}
		if valid_transitions[unit:movement():current_state_name()][state] then
			managers.player:set_player_state(state)
		else
			print("[UnitNetworkHandler:sync_player_movement_state] received invalid transition", unit:movement():current_state_name(), "->", state)
		end
	else
		unit:movement():sync_movement_state(state, down_time)
	end
end
function UnitNetworkHandler:sync_show_hint(id, sender)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) or not self._verify_sender(sender) then
		return
	end
	managers.hint:sync_show_hint(id)
end
function UnitNetworkHandler:sync_show_action_message(unit, id, sender)
	if not (alive(unit) and self._verify_gamestate(self._gamestate_filter.any_ingame)) or not self._verify_sender(sender) then
		return
	end
	managers.action_messaging:sync_show_message(id, unit)
end
function UnitNetworkHandler:say(unit, event_id, sender)
	if not (alive(unit) and self._verify_gamestate(self._gamestate_filter.any_ingame)) or not self._verify_sender(sender) then
		return
	end
	unit:sound():sync_say(event_id)
end
function UnitNetworkHandler:say_str(unit, sound_name, sender)
	if not (alive(unit) and self._verify_gamestate(self._gamestate_filter.any_ingame)) or not self._verify_sender(sender) then
		return
	end
	unit:sound():sync_say_str(sound_name)
end
function UnitNetworkHandler:sync_waiting_for_player_start(variant)
	if not self._verify_gamestate(self._gamestate_filter.waiting_for_players) then
		return
	end
	game_state_machine:current_state():sync_start(variant)
end
function UnitNetworkHandler:criminal_hurt(criminal_unit, attacker_unit, damage_ratio, sender)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) or not self._verify_character_and_sender(criminal_unit, sender) then
		return
	end
	if not alive(attacker_unit) or criminal_unit:key() == attacker_unit:key() then
		attacker_unit = nil
	end
	managers.hud:set_mugshot_damage_taken(criminal_unit:unit_data().mugshot_id)
	managers.groupai:state():criminal_hurt_drama(criminal_unit, attacker_unit, damage_ratio * 0.01)
end
function UnitNetworkHandler:assign_secret_assignment(assignment)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) then
		return
	end
	managers.secret_assignment:assign(assignment)
end
function UnitNetworkHandler:complete_secret_assignment(assignment, sender)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) or not self._verify_sender(sender) then
		return
	end
	managers.secret_assignment:complete_secret_assignment(assignment)
end
function UnitNetworkHandler:failed_secret_assignment(assignment)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) then
		return
	end
	managers.secret_assignment:failed_secret_assignment(assignment)
end
function UnitNetworkHandler:secret_assignment_done(assignment, success)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) then
		return
	end
	managers.secret_assignment:secret_assignment_done(assignment, success)
end
function UnitNetworkHandler:arrested(unit)
	if not alive(unit) then
		return
	end
	unit:movement():sync_arrested()
end
function UnitNetworkHandler:set_crew_bonus(peer_id, upgrade, level, sender)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) or not self._verify_sender(sender) then
		return
	end
	managers.player:set_crew_bonus(peer_id, upgrade, level)
end
function UnitNetworkHandler:set_kit_selection(peer_id, category, id, slot, sender)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) or not self._verify_sender(sender) then
		return
	end
	managers.hud:wfp_set_kit_selection(peer_id, category, id, slot)
	managers.menu:get_menu("kit_menu").renderer:set_kit_selection(peer_id, category, id, slot)
end
function UnitNetworkHandler:set_armor(unit, percent, sender)
	if not (alive(unit) and self._verify_gamestate(self._gamestate_filter.any_ingame)) or not self._verify_sender(sender) then
		return
	end
	managers.hud:set_mugshot_armor(unit:unit_data().mugshot_id, percent / 100)
end
function UnitNetworkHandler:set_health(unit, percent, sender)
	if not (alive(unit) and self._verify_gamestate(self._gamestate_filter.any_ingame)) or not self._verify_sender(sender) then
		return
	end
	managers.hud:set_mugshot_health(unit:unit_data().mugshot_id, percent / 100)
end
function UnitNetworkHandler:sync_add_equipment_possession(peer_id, equipment, sender)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) or not self._verify_sender(sender) then
		return
	end
	local equipment_peer = managers.network:session():peer(peer_id)
	if not equipment_peer then
		print("[UnitNetworkHandler:sync_add_equipment_possession] unknown peer", peer_id)
		return
	end
	managers.player:add_equipment_possession(peer_id, equipment)
end
function UnitNetworkHandler:sync_remove_equipment_possession(peer_id, equipment, sender)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) or not self._verify_sender(sender) then
		return
	end
	local equipment_peer = managers.network:session():peer(peer_id)
	if not equipment_peer then
		print("[UnitNetworkHandler:sync_remove_equipment_possession] unknown peer", peer_id)
		return
	end
	managers.player:remove_equipment_possession(peer_id, equipment)
end
function UnitNetworkHandler:sync_start_anticipation()
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) then
		return
	end
	managers.hud:sync_start_anticipation()
end
function UnitNetworkHandler:sync_start_anticipation_music()
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) then
		return
	end
	managers.hud:sync_start_anticipation_music()
end
function UnitNetworkHandler:sync_start_assault()
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) then
		return
	end
	managers.hud:sync_start_assault()
end
function UnitNetworkHandler:sync_end_assault(result)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) then
		return
	end
	managers.hud:sync_end_assault(result)
end
function UnitNetworkHandler:sync_assault_dialog(index)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) then
		return
	end
	managers.hud:sync_assault_dialog(index)
end
function UnitNetworkHandler:set_contour(unit, state)
	if not alive(unit) then
		return
	end
	unit:base():set_contour(state)
end
function UnitNetworkHandler:long_dis_interacted(unit, sender)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) or not self._verify_character_and_sender(unit, sender) then
		return
	end
	managers.game_play_central:flash_contour(unit)
end
function UnitNetworkHandler:mark_enemy(unit, sender)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) or not self._verify_character_and_sender(unit, sender) then
		return
	end
	managers.game_play_central:add_enemy_contour(unit)
end
function UnitNetworkHandler:sync_teammate_helped_hint(hint, helped_unit, helping_unit, sender)
	if not (self._verify_gamestate(self._gamestate_filter.any_ingame) and self._verify_character_and_sender(helped_unit, sender)) or not self._verify_character(helping_unit, sender) then
		return
	end
	managers.trade:sync_teammate_helped_hint(helped_unit, helping_unit, hint)
end
function UnitNetworkHandler:sync_assault_mode(enabled)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) then
		return
	end
	managers.groupai:state():sync_assault_mode(enabled)
end
function UnitNetworkHandler:sync_hostage_killed_warning(warning)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) then
		return
	end
	managers.groupai:state():sync_hostage_killed_warning(warning)
end
function UnitNetworkHandler:set_interaction_voice(unit, voice, sender)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) or not self._verify_character_and_sender(unit, sender) then
		return
	end
	unit:brain():set_interaction_voice(voice ~= "" and voice or nil)
end
function UnitNetworkHandler:award_achievment(achievment, sender)
	if not self._verify_sender(sender) then
		return
	end
	if not managers.statistics:is_dropin() then
		managers.challenges:set_flag(achievment)
	end
end
function UnitNetworkHandler:sync_teammate_comment(message, pos, pos_based, radius, sender)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) or not self._verify_sender(sender) then
		return
	end
	managers.groupai:state():sync_teammate_comment(message, pos, pos_based, radius)
end
function UnitNetworkHandler:sync_teammate_comment_instigator(unit, message)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) or not self._verify_sender(sender) then
		return
	end
	managers.groupai:state():sync_teammate_comment_instigator(unit, message)
end
function UnitNetworkHandler:begin_gameover_fadeout()
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) then
		return
	end
	managers.groupai:state():begin_gameover_fadeout()
end
function UnitNetworkHandler:send_statistics(peer_id, total_kills, total_specials_kills, total_head_shots, accuracy, downs)
	if not self._verify_gamestate(self._gamestate_filter.any_end_game) then
		return
	end
	managers.network:game():on_statistics_recieved(peer_id, total_kills, total_specials_kills, total_head_shots, accuracy, downs)
end
function UnitNetworkHandler:sync_statistics_result(...)
	if game_state_machine:current_state().on_statistics_result then
		game_state_machine:current_state():on_statistics_result(...)
	end
end
function UnitNetworkHandler:statistics_tied(name, sender)
	if not self._verify_sender(sender) then
		return
	end
	managers.statistics:tied({name = name})
end
function UnitNetworkHandler:bain_comment(bain_line, sender)
	if not self._verify_sender(sender) then
		return
	end
	if managers.dialog and managers.groupai and managers.groupai:state():bain_state() then
		managers.dialog:queue_dialog(bain_line, {})
	end
end
function UnitNetworkHandler:is_inside_point_of_no_return(is_inside, peer_id, sender)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) or not self._verify_sender(sender) then
		return
	end
	managers.groupai:state():set_is_inside_point_of_no_return(peer_id, is_inside)
end
function UnitNetworkHandler:mission_ended(win, num_is_inside, sender)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) or not self._verify_sender(sender) then
		return
	end
	if managers.platform:presence() == "Playing" then
		if win then
			game_state_machine:change_state_by_name("victoryscreen", {
				num_winners = num_is_inside,
				personal_win = not managers.groupai:state()._failed_point_of_no_return and alive(managers.player:player_unit())
			})
		else
			game_state_machine:change_state_by_name("gameoverscreen")
		end
	end
end
function UnitNetworkHandler:sync_level_up(peer_id, level, sender)
	if not self._verify_sender(sender) then
		return
	end
	local peer = managers.network:session():peer(peer_id)
	if not peer then
		return
	end
	peer:set_level(level)
end
function UnitNetworkHandler:sync_set_outline(unit, state, sender)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) or not self._verify_character_and_sender(unit, sender) then
		return
	end
	ElementSetOutline.sync_function(unit, state)
end
function UnitNetworkHandler:sync_disable_shout(unit, state, sender)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) or not self._verify_character_and_sender(unit, sender) then
		return
	end
	ElementDisableShout.sync_function(unit, state)
end
function UnitNetworkHandler:sync_run_sequence_char(unit, seq, sender)
	if not self._verify_gamestate(self._gamestate_filter.any_ingame) or not self._verify_character_and_sender(unit, sender) then
		return
	end
	ElementSequenceCharacter.sync_function(unit, seq)
end
function UnitNetworkHandler:sync_player_kill_statistic(tweak_table_name, is_headshot, weapon_unit, variant, sender)
	if not (self._verify_gamestate(self._gamestate_filter.any_ingame) and self._verify_sender(sender)) or not alive(weapon_unit) then
		return
	end
	local data = {
		name = tweak_table_name,
		head_shot = is_headshot,
		weapon_unit = weapon_unit,
		variant = variant
	}
	managers.statistics:killed_by_anyone(data)
	local attacker_state = managers.player:current_state()
	data.attacker_state = attacker_state
	managers.statistics:killed(data)
end
