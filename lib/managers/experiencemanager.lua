ExperienceManager = ExperienceManager or class()
ExperienceManager.IDS_EXPERIENCE_HUD = Idstring("guis/experience_hud")
function ExperienceManager:init()
	self:_setup()
end
function ExperienceManager:_setup()
	self._total_levels = #tweak_data.experience_manager.levels
	if not Global.experience_manager then
		Global.experience_manager = {}
		Global.experience_manager.total = 0
		Global.experience_manager.level = 0
	end
	self._global = Global.experience_manager
	if not self._global.next_level_data then
		self:_set_next_level_data(1)
	end
	self._cash_tousand_separator = managers.localization:text("cash_tousand_separator")
	self._cash_sign = managers.localization:text("cash_sign")
	self:present()
end
function ExperienceManager:_set_next_level_data(level)
	if level > self._total_levels then
		Application:error("Reached the level cap")
		return
	end
	local level_data = tweak_data.experience_manager.levels[level]
	self._global.next_level_data = {}
	self._global.next_level_data.points = level_data.points
	self._global.next_level_data.current_points = 0
	managers.upgrades:update_target()
end
function ExperienceManager:perform_action_interact(name)
end
function ExperienceManager:perform_action(action)
	if managers.platform:presence() ~= "Playing" and managers.platform:presence() ~= "Mission_end" then
		return
	end
	if not tweak_data.experience_manager.actions[action] then
		Application:error("Unknown action \"" .. tostring(action) .. " in experience manager.")
		return
	end
	local size = tweak_data.experience_manager.actions[action]
	local points = tweak_data.experience_manager.values[size]
	if not points then
		Application:error("Unknown size \"" .. tostring(size) .. " in experience manager.")
		return
	end
	managers.statistics:recieved_experience({action = action, size = size})
	self:add_points(points, true)
end
function ExperienceManager:debug_add_points(points, present_xp)
	self:add_points(points, present_xp, true)
end
function ExperienceManager:add_points(points, present_xp, debug)
	if not debug and managers.platform:presence() ~= "Playing" and managers.platform:presence() ~= "Mission_end" then
		return
	end
	local multiplier = managers.player:synced_crew_bonus_upgrade_value("welcome_to_the_gang", 1)
	multiplier = multiplier * managers.player:synced_crew_bonus_upgrade_value("mr_nice_guy", 1)
	points = math.floor(points * multiplier)
	if not managers.dlc:has_full_game() and self._global.level >= 10 then
		self._global.total = self._global.total + points
		self._global.next_level_data.current_points = 0
		self:present()
		managers.challenges:aquired_money()
		managers.statistics:aquired_money(points)
		return
	end
	if self._global.level >= self:level_cap() then
		self._global.total = self._global.total + points
		managers.challenges:aquired_money()
		managers.statistics:aquired_money(points)
		return
	end
	if present_xp then
		self:_present_xp(points)
	end
	local points_left = self._global.next_level_data.points - self._global.next_level_data.current_points
	if points < points_left then
		self._global.total = self._global.total + points
		self._global.next_level_data.current_points = self._global.next_level_data.current_points + points
		self:present()
		managers.challenges:aquired_money()
		managers.statistics:aquired_money(points)
		return
	end
	self._global.total = self._global.total + points_left
	self._global.next_level_data.current_points = self._global.next_level_data.current_points + points_left
	self:present()
	self:_level_up()
	managers.statistics:aquired_money(points_left)
	self:add_points(points - points_left)
end
function ExperienceManager:_level_up()
	local target_tree = managers.upgrades:current_tree()
	managers.upgrades:aquire_target()
	self._global.level = self._global.level + 1
	self:_set_next_level_data(self._global.level + 1)
	local player = managers.player:player_unit()
	if alive(player) and tweak_data:difficulty_to_index(Global.game_settings.difficulty) < 4 then
		player:base():replenish()
	end
	managers.challenges:check_active_challenges()
	if managers.groupai:state():is_AI_enabled() then
		if target_tree == 1 and managers.groupai:state():get_assault_mode() then
			managers.challenges:set_flag("aint_afraid")
		elseif target_tree == 2 and managers.statistics._last_kill == "sniper" then
			managers.challenges:set_flag("crack_bang")
		elseif target_tree == 3 and managers.achievment:get_script_data("player_reviving") then
			managers.challenges:set_flag("lay_on_hands")
		end
	end
	if managers.network:session() then
		managers.network:session():send_to_peers_synched("sync_level_up", managers.network:session():local_peer():id(), self._global.level)
	end
	if self._global.level >= 145 then
		managers.challenges:set_flag("president")
	end
end
function ExperienceManager:present()
	local hud = managers.hud and managers.hud:script(self.IDS_EXPERIENCE_HUD)
	if not hud then
		return
	end
	hud:set_bar_lenght(self._global.next_level_data.current_points, self._global.next_level_data.points)
	hud:update_show_stats(managers.experience:cash_string(self._global.next_level_data.current_points), managers.experience:cash_string(self._global.next_level_data.points), self._global.level)
end
function ExperienceManager:_present_xp(amount)
	local event = "money_collect_small"
	if amount > 999 then
		event = "money_collect_large"
	elseif amount > 101 then
		event = "money_collect_medium"
	end
	managers.hud:present_text({
		text = self:cash_string(amount) .. managers.localization:text("gain_xp_postfix"),
		time = 0.75,
		event = event
	})
end
function ExperienceManager:current_level()
	return self._global.level
end
function ExperienceManager:total()
	return self._global.total
end
function ExperienceManager:cash_string(cash)
	local sign = ""
	if cash < 0 then
		sign = "-"
	end
	local total = tostring(math.round(math.abs(cash)))
	local reverse = string.reverse(total)
	local s = ""
	for i = 1, string.len(reverse) do
		s = s .. string.sub(reverse, i, i) .. (math.mod(i, 3) == 0 and i ~= string.len(reverse) and self._cash_tousand_separator or "")
	end
	return sign .. self._cash_sign .. string.reverse(s)
end
function ExperienceManager:total_cash_string()
	return self:cash_string(self._global.total) .. (self._global.total > 0 and self._cash_tousand_separator .. "000" or "")
end
function ExperienceManager:show_stats()
	local hud = managers.hud:script(self.IDS_EXPERIENCE_HUD)
	if not hud then
		return
	end
	hud:show_stats()
end
function ExperienceManager:hide_stats()
	local hud = managers.hud:script(self.IDS_EXPERIENCE_HUD)
	if not hud then
		return
	end
	hud:hide_stats()
end
function ExperienceManager:actions()
	local t = {}
	for action, _ in pairs(tweak_data.experience_manager.actions) do
		table.insert(t, action)
	end
	table.sort(t)
	return t
end
function ExperienceManager:level_cap()
	return 48 * managers.upgrades:num_trees() + 1
end
function ExperienceManager:reached_level_cap()
	return self._global.level >= self:level_cap()
end
function ExperienceManager:save(data)
	local state = {
		total = self._global.total,
		next_level_data = self._global.next_level_data
	}
	data.ExperienceManager = state
end
function ExperienceManager:load(data)
	local state = data.ExperienceManager
	if state then
		self._global.total = state.total
		self._global.next_level_data = state.next_level_data
		local level = 0
		for _, lvl in ipairs(managers.upgrades._global.progress) do
			level = level + lvl
		end
		self._global.level = level
		if not self._global.next_level_data or not tweak_data.experience_manager.levels[level + 1] or self._global.next_level_data.points ~= tweak_data.experience_manager.levels[level + 1].points then
			self:_set_next_level_data(level + 1)
		end
	end
	managers.network.account:experience_loaded()
end
function ExperienceManager:reset()
	managers.upgrades:reset()
	managers.player:reset()
	Global.experience_manager = nil
	self:_setup()
end
function ExperienceManager:chk_ask_use_backup(savegame_data, backup_savegame_data)
	local savegame_exp_total, backup_savegame_exp_total
	local state = savegame_data.ExperienceManager
	if state then
		savegame_exp_total = state.total
	end
	state = backup_savegame_data.ExperienceManager
	if state then
		backup_savegame_exp_total = state.total
	end
	if savegame_exp_total and backup_savegame_exp_total and savegame_exp_total < backup_savegame_exp_total then
		return true
	end
end
