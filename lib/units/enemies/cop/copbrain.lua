require("lib/units/enemies/cop/logics/CopLogicBase")
require("lib/units/enemies/cop/logics/CopLogicInactive")
require("lib/units/enemies/cop/logics/CopLogicIdle")
require("lib/units/enemies/cop/logics/CopLogicAttack")
require("lib/units/enemies/cop/logics/CopLogicIntimidated")
require("lib/units/enemies/cop/logics/CopLogicTravel")
require("lib/units/enemies/cop/logics/CopLogicArrest")
require("lib/units/enemies/cop/logics/CopLogicDisarm")
require("lib/units/enemies/cop/logics/CopLogicGuard")
require("lib/units/enemies/cop/logics/CopLogicFlee")
require("lib/units/enemies/cop/logics/CopLogicSecurityOnDuty")
require("lib/units/enemies/cop/logics/CopLogicSniper")
require("lib/units/enemies/cop/logics/CopLogicTrade")
require("lib/units/enemies/tank/logics/TankCopLogicAttack")
require("lib/units/enemies/shield/logics/ShieldLogicAttack")
require("lib/units/enemies/spooc/logics/SpoocLogicAttack")
require("lib/units/enemies/taser/logics/TaserLogicAttack")
CopBrain = CopBrain or class()
local logic_variants = {
	security = {
		idle = CopLogicIdle,
		attack = CopLogicAttack,
		travel = CopLogicTravel,
		inactive = CopLogicInactive,
		intimidated = CopLogicIntimidated,
		arrest = CopLogicArrest,
		disarm = CopLogicDisarm,
		guard = CopLogicGuard,
		flee = CopLogicFlee,
		security = CopLogicSecurityOnDuty,
		sniper = CopLogicSniper,
		trade = CopLogicTrade
	}
}
local security_variant = logic_variants.security
logic_variants.patrol = security_variant
logic_variants.cop = security_variant
logic_variants.fbi = security_variant
logic_variants.swat = security_variant
logic_variants.heavy_swat = security_variant
logic_variants.nathan = security_variant
logic_variants.sniper = security_variant
logic_variants.gangster = security_variant
logic_variants.dealer = security_variant
logic_variants.murky = security_variant
for _, tweak_table_name in pairs({
	"shield",
	"tank",
	"spooc",
	"taser"
}) do
	logic_variants[tweak_table_name] = clone(security_variant)
end
logic_variants.shield.attack = ShieldLogicAttack
logic_variants.shield.disarm = nil
logic_variants.shield.intimidated = nil
logic_variants.shield.flee = nil
logic_variants.tank.attack = TankCopLogicAttack
logic_variants.spooc.attack = SpoocLogicAttack
logic_variants.taser.attack = TaserLogicAttack
security_variant = nil
CopBrain._logic_variants = logic_variants
logic_varaints = nil
local reload
if CopBrain._reload_clbks then
	reload = true
else
	CopBrain._reload_clbks = {}
end
function CopBrain:init(unit)
	self._unit = unit
	self._timer = TimerManager:game()
	self:set_update_enabled_state(false)
	self._current_logic = nil
	self._current_logic_name = nil
	self._active = true
	self._slotmask_enemies = managers.slot:get_mask("criminals")
	self._reload_clbks[unit:key()] = callback(self, self, "on_reload")
end
function CopBrain:post_init()
	self._logics = CopBrain._logic_variants[self._unit:base()._tweak_table]
	self:_reset_logic_data()
	local my_key = tostring(self._unit:key())
	self._unit:character_damage():add_listener("CopBrain_hurt" .. my_key, {
		"hurt",
		"light_hurt",
		"heavy_hurt"
	}, callback(self, self, "clbk_damage"))
	self._unit:character_damage():add_listener("CopBrain_death" .. my_key, {"death"}, callback(self, self, "clbk_death"))
	if not self._current_logic then
		self:set_init_logic("idle")
	end
end
function CopBrain:update(unit, t, dt)
	local logic = self._current_logic
	if logic.update then
		local l_data = self._logic_data
		l_data.t = t
		l_data.dt = dt
		logic.update(l_data)
	end
end
function CopBrain:set_update_enabled_state(state)
	self._unit:set_extension_update_enabled(Idstring("brain"), state)
end
function CopBrain:set_spawn_ai(spawn_ai)
	self._spawn_ai = spawn_ai
	self:set_update_enabled_state(true)
	if spawn_ai.init_state then
		self:set_logic(spawn_ai.init_state, spawn_ai.params)
	end
	if spawn_ai.stance then
		self._unit:movement():set_stance(spawn_ai.stance)
	end
	if spawn_ai.objective then
		self:set_objective(spawn_ai.objective)
	end
end
function CopBrain:set_objective(new_objective)
	local old_objective = self._logic_data.objective
	self._logic_data.objective = new_objective
	if new_objective and new_objective.followup_objective and new_objective.followup_objective.interaction_voice then
		self._unit:network():send("set_interaction_voice", new_objective.followup_objective.interaction_voice)
	elseif old_objective and old_objective.followup_objective and old_objective.followup_objective.interaction_voice then
		self._unit:network():send("set_interaction_voice", "")
	end
	self._current_logic.on_new_objective(self._logic_data, old_objective)
end
function CopBrain:set_followup_objective(followup_objective)
	local old_followup = self._logic_data.objective.followup_objective
	self._logic_data.objective.followup_objective = followup_objective
	if followup_objective and followup_objective.interaction_voice then
		self._unit:network():send("set_interaction_voice", followup_objective.interaction_voice)
	elseif old_followup and old_followup.interaction_voice then
		self._unit:network():send("set_interaction_voice", "")
	end
end
function CopBrain:save(save_data)
	local my_save_data = {}
	if self._logic_data.objective and self._logic_data.objective.followup_objective and self._logic_data.objective.followup_objective.interaction_voice then
		my_save_data.interaction_voice = self._logic_data.objective.followup_objective.interaction_voice
	else
		my_save_data.interaction_voice = nil
	end
	save_data.brain = my_save_data
end
function CopBrain:objective()
	return self._logic_data.objective
end
function CopBrain:is_available_for_assignment(objective)
	return self._current_logic.is_available_for_assignment(self._logic_data, objective)
end
function CopBrain:_reset_logic_data()
	self._logic_data = {
		unit = self._unit,
		active_searches = {},
		m_pos = self._unit:movement():m_pos(),
		char_tweak = tweak_data.character[self._unit:base()._tweak_table],
		key = self._unit:key(),
		pos_rsrv_id = self._unit:movement():pos_rsrv_id()
	}
end
function CopBrain:set_init_logic(name, enter_params)
	local logic = self._logics[name]
	local l_data = self._logic_data
	l_data.t = self._timer:time()
	l_data.dt = self._timer:delta_time()
	l_data.name = name
	l_data.logic = logic
	self._current_logic = logic
	self._current_logic_name = name
	logic.enter(l_data, name, enter_params)
end
function CopBrain:set_logic(name, enter_params)
	local logic = self._logics[name]
	local l_data = self._logic_data
	l_data.t = self._timer:time()
	l_data.dt = self._timer:delta_time()
	self._current_logic.exit(l_data, name, enter_params)
	l_data.name = name
	l_data.logic = logic
	self._current_logic = logic
	self._current_logic_name = name
	logic.enter(l_data, name, enter_params)
end
function CopBrain:search_for_path_to_unit(search_id, other_unit, access_neg)
	local enemy_tracker = other_unit:movement():nav_tracker()
	local pos_to = enemy_tracker:field_position()
	local params = {
		tracker_from = self._unit:movement():nav_tracker(),
		tracker_to = enemy_tracker,
		result_clbk = callback(self, self, "clbk_pathing_results", search_id),
		id = search_id,
		access_pos = managers.navigation._quad_field:convert_nav_link_flag_to_bitmask(self._logic_data.char_tweak.access),
		access_neg = access_neg
	}
	self._logic_data.active_searches[search_id] = true
	managers.navigation:search_pos_to_pos(params)
	return true
end
function CopBrain:search_for_path(search_id, to_pos, prio, access_neg)
	local params = {
		tracker_from = self._unit:movement():nav_tracker(),
		pos_to = to_pos,
		result_clbk = callback(self, self, "clbk_pathing_results", search_id),
		id = search_id,
		prio = prio,
		access_pos = managers.navigation._quad_field:convert_nav_link_flag_to_bitmask(self._logic_data.char_tweak.access),
		access_neg = access_neg
	}
	self._logic_data.active_searches[search_id] = true
	managers.navigation:search_pos_to_pos(params)
	return true
end
function CopBrain:search_for_path_from_pos(search_id, from_pos, to_pos, prio, access_neg)
	local params = {
		pos_from = from_pos,
		pos_to = to_pos,
		result_clbk = callback(self, self, "clbk_pathing_results", search_id),
		id = search_id,
		prio = prio,
		access_pos = managers.navigation._quad_field:convert_nav_link_flag_to_bitmask(self._logic_data.char_tweak.access),
		access_neg = access_neg
	}
	self._logic_data.active_searches[search_id] = true
	managers.navigation:search_pos_to_pos(params)
	return true
end
function CopBrain:search_for_path_to_cover(search_id, cover, offset_pos, access_neg)
	local params = {
		tracker_from = self._unit:movement():nav_tracker(),
		tracker_to = cover[3],
		result_clbk = callback(self, self, "clbk_pathing_results", search_id),
		id = search_id,
		access_pos = managers.navigation._quad_field:convert_nav_link_flag_to_bitmask(self._logic_data.char_tweak.access),
		access_neg = access_neg
	}
	self._logic_data.active_searches[search_id] = true
	managers.navigation:search_pos_to_pos(params)
	return true
end
function CopBrain:search_for_coarse_path(search_id, to_seg, verify_clbk, access_neg)
	local params = {
		from_tracker = self._unit:movement():nav_tracker(),
		to_seg = to_seg,
		access = {"walk"},
		id = search_id,
		results_clbk = callback(self, self, "clbk_coarse_pathing_results", search_id),
		verify_clbk = verify_clbk,
		access_pos = self._logic_data.char_tweak.access,
		access_neg = access_neg
	}
	self._logic_data.active_searches[search_id] = 2
	managers.navigation:search_coarse(params)
	return true
end
function CopBrain:action_request(new_action_data)
	return self._unit:movement():action_request(new_action_data)
end
function CopBrain:action_complete_clbk(action)
	self._current_logic.action_complete_clbk(self._logic_data, action)
end
function CopBrain:clbk_coarse_pathing_results(search_id, path)
	self:_add_pathing_result(search_id, path)
end
function CopBrain:clbk_pathing_results(search_id, path)
	self:_add_pathing_result(search_id, path)
	if path then
		local t
		for i, nav_point in ipairs(path) do
			if not nav_point.x and nav_point:script_data().element:nav_link_delay() > 0 then
				t = t or TimerManager:game():time()
				nav_point:set_delay_time(t + nav_point:script_data().element:nav_link_delay())
			end
		end
	end
end
function CopBrain:_add_pathing_result(search_id, path)
	self._logic_data.active_searches[search_id] = nil
	self._logic_data.pathing_results = self._logic_data.pathing_results or {}
	self._logic_data.pathing_results[search_id] = path or "failed"
end
function CopBrain:cancel_all_pathing_searches()
	for search_id, search_type in pairs(self._logic_data.active_searches) do
		if search_type == 2 then
			managers.navigation:cancel_coarse_search(search_id)
		else
			managers.navigation:cancel_pathing_search(search_id)
		end
	end
	self._logic_data.active_searches = {}
	self._logic_data.pathing_results = nil
end
function CopBrain:clbk_damage(my_unit, damage_info)
	if damage_info.attacker_unit and damage_info.attacker_unit:in_slot(self._slotmask_enemies) then
		self._current_logic.damage_clbk(self._logic_data, damage_info)
	end
end
function CopBrain:clbk_death(my_unit, damage_info)
	self._current_logic.death_clbk(self._logic_data, damage_info)
	self:set_logic("inactive")
end
function CopBrain:can_deactivate()
	return self._current_logic.can_deactivate(self._logic_data)
end
function CopBrain:can_activate()
	return self._current_logic.can_activate(self._logic_data)
end
function CopBrain:is_active()
	return self._active
end
function CopBrain:set_active(state)
	self._active = state
	if state then
		self:set_logic("idle")
	elseif self._current_logic_name ~= "inactive" then
		self:set_logic("inactive")
	end
end
function CopBrain:cancel_trade()
	self:set_logic("intimidated")
end
function CopBrain:interaction_voice()
	if self._logic_data.objective and self._logic_data.objective.followup_objective and self._logic_data.objective.followup_objective.trigger_on == "interact" and (not (self._logic_data.objective and self._logic_data.objective.nav_seg) or not not self._logic_data.objective.in_place) and not self._unit:anim_data().unintimidateable then
		return self._logic_data.objective.followup_objective.interaction_voice
	end
end
function CopBrain:on_intimidated(amount, aggressor_unit)
	if self._logic_data.objective and self._logic_data.objective.followup_objective and self._logic_data.objective.followup_objective.trigger_on == "interact" and (not (self._logic_data.objective and self._logic_data.objective.nav_seg) or not not self._logic_data.objective.in_place) and not self._unit:anim_data().unintimidateable then
		self:set_objective(self._logic_data.objective.followup_objective)
		return self._logic_data.objective.interaction_voice
	else
		self._current_logic.on_intimidated(self._logic_data, amount, aggressor_unit)
	end
end
function CopBrain:on_tied(aggressor_unit, not_tied)
	return self._current_logic.on_tied(self._logic_data, aggressor_unit, not_tied)
end
function CopBrain:on_trade(aggressor_unit)
	return self._current_logic.on_trade(self._logic_data, aggressor_unit)
end
function CopBrain:pre_destroy(unit)
	if self._current_logic_name ~= "inactive" then
		self:set_logic("inactive")
	end
	self._reload_clbks[unit:key()] = nil
end
function CopBrain:on_detected_enemy_destroyed(destroyed_unit)
	self._current_logic.on_detected_enemy_destroyed(self._logic_data, destroyed_unit)
end
function CopBrain:on_criminal_neutralized(criminal_key)
	self._current_logic.on_criminal_neutralized(self._logic_data, criminal_key)
end
function CopBrain:on_alert(alert_data)
	self._current_logic.on_alert(self._logic_data, alert_data)
end
function CopBrain:filter_area_unsafe(nav_seg)
	return not managers.groupai:state():is_area_safe(nav_seg)
end
function CopBrain:on_area_safety(...)
	self._current_logic.on_area_safety(self._logic_data, ...)
end
function CopBrain:draw_reserved_positions()
	self._current_logic.draw_reserved_positions(self._logic_data)
end
function CopBrain:draw_reserved_covers()
	self._current_logic.draw_reserved_covers(self._logic_data)
end
function CopBrain:set_important(state)
	self._important = state
	self._logic_data.important = state
	self._current_logic.on_importance(self._logic_data)
end
function CopBrain:is_important()
	return self._important
end
function CopBrain:on_reload()
	self._logic_data.char_tweak = tweak_data.character[self._unit:base()._tweak_table]
	self._logics = CopBrain._logic_variants[self._unit:base()._tweak_table]
	self._current_logic = self._logics[self._current_logic_name]
end
function CopBrain:on_rescue_allowed_state(state)
	if self._current_logic.on_rescue_allowed_state then
		self._current_logic.on_rescue_allowed_state(self._logic_data, state)
	end
end
function CopBrain:on_objective_unit_destroyed(unit)
	return self._current_logic.on_objective_unit_destroyed(self._logic_data, unit)
end
function CopBrain:on_objective_unit_damaged(unit, damage_info)
	if unit:character_damage().dead and unit:character_damage():dead() then
		return self._current_logic.on_objective_unit_damaged(self._logic_data, unit, damage_info.attacker_unit)
	end
end
function CopBrain:is_advancing()
	return self._current_logic.is_advancing(self._logic_data)
end
function CopBrain:anim_clbk(unit, ...)
	self._current_logic.anim_clbk(self._logic_data, ...)
end
function CopBrain:on_nav_link_unregistered(element_id)
	if self._logic_data.pathing_results then
		local failed_search_ids
		for path_name, path in pairs(self._logic_data.pathing_results) do
			if type(path) == "table" and path[1] and type(path[1]) ~= "table" then
				for i, nav_point in ipairs(path) do
					if not nav_point.x and nav_point:script_data().element._id == element_id then
						failed_search_ids = failed_search_ids or {}
						failed_search_ids[path_name] = true
						break
					end
				end
			end
		end
		if failed_search_ids then
			for search_id, _ in pairs(failed_search_ids) do
				self._logic_data.pathing_results[search_id] = "failed"
			end
		end
	end
	local paths = self._current_logic._get_all_paths and self._current_logic._get_all_paths(self._logic_data)
	if not paths then
		return
	end
	local verified_paths = {}
	for path_name, path in pairs(paths) do
		local path_is_ok = true
		for i, nav_point in ipairs(path) do
			if not nav_point.x and nav_point:script_data().element._id == element_id then
				path_is_ok = false
				break
			end
		end
		if path_is_ok then
			verified_paths[path_name] = path
		end
	end
	self._current_logic._set_verified_paths(self._logic_data, verified_paths)
end
if reload then
	for k, clbk in pairs(CopBrain._reload_clbks) do
		clbk()
	end
end
