TeamAILogicSurrender = class(TeamAILogicBase)
function TeamAILogicSurrender.enter(data, new_logic_name, enter_params)
	TeamAILogicBase.enter(data, new_logic_name, enter_params)
	data.unit:brain():cancel_all_pathing_searches()
	local old_internal_data = data.internal_data
	local my_data = {
		unit = data.unit
	}
	my_data.enemy_detect_slotmask = managers.slot:get_mask("enemies")
	my_data.rsrv_pos = {}
	if old_internal_data then
		my_data.detected_enemies = old_internal_data.detected_enemies or {}
		my_data.rsrv_pos = old_internal_data.rsrv_pos or my_data.rsrv_pos
		if old_internal_data.nearest_cover then
			my_data.nearest_cover = old_internal_data.nearest_cover
			managers.navigation:reserve_cover(my_data.nearest_cover[1], data.pos_rsrv_id)
		end
	else
		my_data.detected_enemies = {}
	end
	local action_data = {
		type = "act",
		body_part = 1,
		variant = "tied"
	}
	data.unit:brain():action_request(action_data)
	data.unit:brain():set_update_enabled_state(false)
	data.internal_data = my_data
	data.unit:movement():set_allow_fire(false)
	data.unit:interaction():set_tweak_data("free")
	data.unit:interaction():set_active(true, false)
	data.unit:character_damage():set_invulnerable(true)
	data.unit:character_damage():stop_bleedout()
	data.unit:base():set_slot(data.unit, 24)
	managers.groupai:state():on_criminal_neutralized(data.unit)
	TeamAILogicDisabled._register_revive_SO(data, my_data, "untie")
	if data.objective then
		managers.groupai:state():on_criminal_objective_failed(data.unit, data.objective, true)
		data.unit:brain():set_objective(nil)
	end
end
function TeamAILogicSurrender.exit(data, new_logic_name, enter_params)
	TeamAILogicBase.exit(data, new_logic_name, enter_params)
	local my_data = data.internal_data
	my_data.exiting = true
	if my_data.nearest_cover then
		managers.navigation:release_cover(my_data.nearest_cover[1])
	end
	TeamAILogicDisabled._unregister_revive_SO(my_data)
	if new_logic_name ~= "inactive" then
		data.unit:brain():set_update_enabled_state(true)
		managers.groupai:state():on_criminal_recovered(data.unit)
		data.unit:base():set_slot(data.unit, 16)
		data.unit:character_damage():set_invulnerable(nil)
	end
	data.unit:interaction():set_active(false, false)
end
function TeamAILogicSurrender.action_complete_clbk(data, action)
end
function TeamAILogicSurrender.can_activate()
end
function TeamAILogicSurrender.on_detected_enemy_destroyed(data, enemy_unit)
	TeamAILogicIdle.on_cop_neutralized(data, enemy_unit:key())
end
function TeamAILogicSurrender.on_cop_neutralized(data, cop_key)
	TeamAILogicIdle.on_cop_neutralized(data, cop_key)
end
function TeamAILogicSurrender.on_alert(data, alert_data)
	local enemy = alert_data[4]
	local my_data = data.internal_data
	local enemy_key = enemy:key()
	local t = TimerManager:game():time()
	local enemy_data = CopLogicAttack._create_detected_enemy_data(data, enemy)
	my_data.detected_enemies[enemy_key] = enemy_data
end
function TeamAILogicSurrender.is_available_for_assignment(data)
end
function TeamAILogicSurrender.on_recovered(data, reviving_unit)
	return TeamAILogicDisabled.on_recovered(data, reviving_unit)
end
