require("lib/units/enemies/cop/logics/CopLogicAttack")
TeamAILogicDisabled = class(TeamAILogicAssault)
function TeamAILogicDisabled.enter(data, new_logic_name, enter_params)
	TeamAILogicBase.enter(data, new_logic_name, enter_params)
	data.unit:brain():cancel_all_pathing_searches()
	local old_internal_data = data.internal_data
	local my_data = {
		unit = data.unit
	}
	data.internal_data = my_data
	my_data.ai_visibility_slotmask = managers.slot:get_mask("AI_visibility")
	my_data.detection = tweak_data.character[data.unit:base()._tweak_table].detection.combat
	my_data.enemy_detect_slotmask = managers.slot:get_mask("enemies")
	my_data.rsrv_pos = {}
	if old_internal_data then
		my_data.detected_enemies = old_internal_data.detected_enemies or {}
		my_data.focus_enemy = old_internal_data.focus_enemy
		my_data.rsrv_pos = old_internal_data.rsrv_pos or my_data.rsrv_pos
		CopLogicAttack._set_best_cover(data, my_data, old_internal_data.best_cover)
		CopLogicAttack._set_nearest_cover(my_data, old_internal_data.nearest_cover)
		my_data.attention = old_internal_data.attention
	else
		my_data.detected_enemies = {}
	end
	local key_str = tostring(data.unit:key())
	my_data.detection_task_key = "TeamAILogicDisabled._update_enemy_detection" .. key_str
	CopLogicBase.queue_task(my_data, my_data.detection_task_key, TeamAILogicDisabled._update_enemy_detection, data, data.t)
	my_data.stay_cool = nil
	if data.unit:character_damage():need_revive() then
		TeamAILogicDisabled._register_revive_SO(data, my_data, "revive")
	end
	data.unit:brain():set_update_enabled_state(false)
	if not data.unit:character_damage():bleed_out() then
		my_data.invulnerable = true
		data.unit:character_damage():set_invulnerable(true)
	end
	if data.objective then
		managers.groupai:state():on_criminal_objective_failed(data.unit, data.objective, true)
		data.unit:brain():set_objective(nil)
	end
end
function TeamAILogicDisabled.exit(data, new_logic_name, enter_params)
	TeamAILogicBase.exit(data, new_logic_name, enter_params)
	local my_data = data.internal_data
	my_data.exiting = true
	TeamAILogicDisabled._unregister_revive_SO(my_data)
	if my_data.invulnerable then
		data.unit:character_damage():set_invulnerable(false)
	end
	CopLogicBase.cancel_queued_tasks(my_data)
	if my_data.best_cover then
		managers.navigation:release_cover(my_data.best_cover[1])
	end
	if my_data.nearest_cover then
		managers.navigation:release_cover(my_data.nearest_cover[1])
	end
	if new_logic_name ~= "inactive" then
		data.unit:brain():set_update_enabled_state(true)
	end
end
function TeamAILogicDisabled._update_enemy_detection(data)
	data.t = TimerManager:game():time()
	local my_data = data.internal_data
	local delay = TeamAILogicIdle._detect_enemies(data, my_data)
	local enemies = my_data.detected_enemies
	local focus_enemy, focus_type, focus_enemy_key, nearest_dis
	for key, enemy_data in pairs(enemies) do
		local reaction = true
		if reaction and focus_enemy then
			if focus_enemy.verified and not enemy_data.verified then
				reaction = false
			elseif nearest_dis and nearest_dis < enemy_data.verified_dis then
				reaction = false
			end
		end
		if reaction then
			focus_enemy = enemy_data
			focus_type = reaction
			focus_enemy_key = key
			nearest_dis = enemy_data.verified_dis
		end
	end
	if focus_enemy then
		if not my_data.focus_enemy or my_data.focus_enemy.unit:key() ~= focus_enemy_key then
		end
	elseif my_data.focus_enemy then
	end
	my_data.focus_enemy = focus_enemy
	TeamAILogicDisabled._upd_aim(data, my_data)
	CopLogicBase.queue_task(my_data, my_data.detection_task_key, TeamAILogicDisabled._update_enemy_detection, data, data.t + delay)
end
function TeamAILogicDisabled.death_clbk(data, damage_info)
	local my_data = data.internal_data
	if my_data.focus_enemy then
		my_data.focus_enemy = nil
	end
end
function TeamAILogicDisabled.on_intimidated(data, amount, aggressor_unit)
end
function TeamAILogicDisabled._consider_surrender(data, my_data)
	my_data.stay_cool_chk_t = TimerManager:game():time()
	local my_health_ratio = data.unit:character_damage():health_ratio()
	if my_health_ratio < 0.1 then
		return
	end
	local my_health = my_health_ratio * data.unit:character_damage()._HEALTH_BLEEDOUT_INIT
	local total_scare = 0
	for e_key, e_data in pairs(my_data.detected_enemies) do
		if e_data.verified then
			local scare = tweak_data.character[e_data.unit:base()._tweak_table].HEALTH_INIT / my_health
			scare = scare * (1 - math.clamp(e_data.verified_dis - 300, 0, 2500) / 2500)
			total_scare = total_scare + scare
		end
	end
	for c_key, c_data in pairs(managers.groupai:state():all_player_criminals()) do
		if not c_data.status then
			local support = tweak_data.player.damage.HEALTH_INIT / my_health
			local dis = mvector3.distance(c_data.m_pos, data.m_pos)
			if dis < 700 then
				total_scare = 0
			else
				support = 3 * support * (1 - math.clamp(dis - 300, 0, 2500) / 2500)
				total_scare = total_scare - support
			end
		end
	end
	if total_scare > 1 then
		my_data.stay_cool = true
		if my_data.firing then
			data.unit:movement():set_allow_fire(false)
			my_data.firing = nil
		end
	else
		my_data.stay_cool = false
	end
end
function TeamAILogicDisabled.on_long_dis_interacted(data, other_unit)
	TeamAILogicIdle.on_long_dis_interacted(data, other_unit)
end
function TeamAILogicDisabled.on_new_objective(data, old_objective)
	TeamAILogicBase.on_new_objective(data, old_objective)
end
function TeamAILogicDisabled._upd_aim(data, my_data)
	local shoot, aim
	local focus_enemy = my_data.focus_enemy
	if my_data.stay_cool then
	elseif focus_enemy then
		if focus_enemy.verified then
			if focus_enemy.verified_dis < 2000 or my_data.alert_t and data.t - my_data.alert_t < 7 then
				shoot = true
			end
		elseif focus_enemy.verified_t and data.t - focus_enemy.verified_t < 10 then
			aim = true
			if my_data.shooting and data.t - focus_enemy.verified_t < 3 then
				shoot = true
			end
		elseif focus_enemy.verified_dis < 600 and my_data.walking_to_cover_shoot_pos then
			aim = true
		end
	end
	if aim or shoot then
		if focus_enemy.verified then
			if my_data.attention ~= focus_enemy.unit:key() then
				CopLogicBase._set_attention_on_unit(data, focus_enemy.unit)
				my_data.attention = focus_enemy.unit:key()
			end
		elseif my_data.attention ~= focus_enemy.verified_pos then
			CopLogicBase._set_attention_on_pos(data, mvector3.copy(focus_enemy.verified_pos))
			my_data.attention = mvector3.copy(focus_enemy.verified_pos)
		end
	else
		if my_data.shooting then
			local new_action
			if data.unit:anim_data().reload then
				new_action = {type = "reload", body_part = 3}
			else
				new_action = {type = "idle", body_part = 3}
			end
			data.unit:brain():action_request(new_action)
		end
		if my_data.attention then
			CopLogicBase._reset_attention(data)
			my_data.attention = nil
		end
	end
	if shoot then
		if not my_data.firing then
			data.unit:movement():set_allow_fire(true)
			my_data.firing = true
		end
	elseif my_data.firing then
		data.unit:movement():set_allow_fire(false)
		my_data.firing = nil
	end
end
function TeamAILogicDisabled.on_recovered(data, reviving_unit)
	local my_data = data.internal_data
	if reviving_unit and my_data.rescuer and my_data.rescuer:key() == reviving_unit:key() then
		my_data.rescuer = nil
	else
		TeamAILogicDisabled._unregister_revive_SO(my_data)
	end
	local objective_type = data.objective and data.objective.type
	if objective_type == "follow" or objective_type == "revive" then
		CopLogicBase._exit(data.unit, "travel")
	else
		CopLogicBase._exit(data.unit, "assault")
	end
end
function TeamAILogicDisabled._register_revive_SO(data, my_data, rescue_type)
	local followup_objective = {
		type = "act",
		scan = true,
		action = {
			type = "act",
			body_part = 1,
			variant = "crouch",
			blocks = {
				action = -1,
				walk = -1,
				hurt = -1,
				heavy_hurt = -1,
				aim = -1
			}
		}
	}
	local objective = {
		type = "revive",
		follow_unit = data.unit,
		called = true,
		scan = true,
		destroy_clbk_key = false,
		nav_seg = data.unit:movement():nav_tracker():nav_segment(),
		fail_clbk = callback(TeamAILogicDisabled, TeamAILogicDisabled, "on_revive_SO_failed", data),
		interrupt_on = "obstructed",
		interrupt_dmg_ratio = 0.75,
		action = {
			type = "act",
			variant = rescue_type,
			body_part = 1,
			blocks = {
				action = -1,
				walk = -1,
				light_hurt = -1,
				hurt = -1,
				heavy_hurt = -1,
				aim = -1
			},
			align_sync = true
		},
		interact_delay = tweak_data.interaction[data.name == "surrender" and "free" or "revive"].timer,
		followup_objective = followup_objective
	}
	local so_descriptor = {
		objective = objective,
		base_chance = 1,
		chance_inc = 0,
		interval = 6,
		search_dis = 1000,
		search_pos = mvector3.copy(data.m_pos),
		usage_amount = 1,
		AI_group = "friendlies",
		admin_clbk = callback(TeamAILogicDisabled, TeamAILogicDisabled, "on_revive_SO_administered", data)
	}
	local so_id = "TeamAIrevive" .. tostring(data.unit:key())
	my_data.SO_id = so_id
	managers.groupai:state():add_special_objective(so_id, so_descriptor)
	my_data.deathguard_SO_id = PlayerBleedOut._register_deathguard_SO(data.unit)
end
function TeamAILogicDisabled._unregister_revive_SO(my_data)
	if my_data.deathguard_SO_id then
		PlayerBleedOut._unregister_deathguard_SO(my_data.deathguard_SO_id)
		my_data.deathguard_SO_id = nil
	end
	if my_data.rescuer then
		local rescuer = my_data.rescuer
		my_data.rescuer = nil
		if rescuer:brain():objective() then
			managers.groupai:state():on_criminal_objective_failed(rescuer, rescuer:brain():objective())
		end
	elseif my_data.SO_id then
		managers.groupai:state():remove_special_objective(my_data.SO_id)
		my_data.SO_id = nil
	end
end
function TeamAILogicDisabled.is_available_for_assignment(data, new_objective)
	if not new_objective then
		return true
	end
end
function TeamAILogicDisabled.damage_clbk(data, damage_info)
	local my_data = data.internal_data
	if data.unit:character_damage():need_revive() and not my_data.SO_id and not my_data.rescuer then
		TeamAILogicDisabled._register_revive_SO(data, my_data, "revive")
	end
	if damage_info.result.type == "fatal" then
		CopLogicBase.cancel_queued_tasks(my_data)
		if not my_data.invulnerable then
			my_data.invulnerable = true
			data.unit:character_damage():set_invulnerable(true)
		end
	end
	TeamAILogicIdle.damage_clbk(data, damage_info)
end
function TeamAILogicDisabled.on_revive_SO_administered(ignore_this, data, receiver_unit)
	local my_data = data.internal_data
	my_data.rescuer = receiver_unit
	my_data.SO_id = nil
end
function TeamAILogicDisabled.on_revive_SO_failed(ignore_this, data)
	local my_data = data.internal_data
	if my_data.rescuer and (data.unit:character_damage():need_revive() or data.unit:character_damage():arrested()) and not my_data.exiting then
		my_data.rescuer = nil
		TeamAILogicDisabled._register_revive_SO(data, my_data, "revive")
	end
end
