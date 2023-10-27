MoneyManager = MoneyManager or class()
function MoneyManager:init()
	self:_setup()
end
function MoneyManager:_setup()
	if not Global.money_manager then
		Global.money_manager = {}
		Global.money_manager.total = 0
	end
	self._global = Global.money_manager
	self._heist_total = 0
	self._active_multipliers = {}
end
function MoneyManager:total_string()
	local total = math.round(self._global.total)
	total = tostring(total)
	local reverse = string.reverse(total)
	local s = ""
	for i = 1, string.len(reverse) do
		s = s .. string.sub(reverse, i, i) .. (math.mod(i, 3) == 0 and i ~= string.len(reverse) and "," or "")
	end
	return "$" .. string.reverse(s)
end
function MoneyManager:use_multiplier(multiplier)
	if not tweak_data.money_manager.multipliers[multiplier] then
		Application:error("Unknown multiplier \"" .. tostring(multiplier) .. " in money manager.")
		return
	end
	self._active_multipliers[multiplier] = tweak_data.money_manager.multipliers[multiplier]
end
function MoneyManager:remove_multiplier(multiplier)
	if not tweak_data.money_manager.multipliers[multiplier] then
		Application:error("Unknown multiplier \"" .. tostring(multiplier) .. " in money manager.")
		return
	end
	self._active_multipliers[multiplier] = nil
end
function MoneyManager:perform_action(action)
	if not tweak_data.money_manager.actions[action] then
		Application:error("Unknown action \"" .. tostring(action) .. " in money manager.")
		return
	end
	self:_add(tweak_data.money_manager.actions[action])
end
function MoneyManager:perform_action_interact(name)
	if not tweak_data.money_manager.actions.interact[name:key()] then
		return
	end
	self:_add(tweak_data.money_manager.actions.interact[name:key()])
end
function MoneyManager:perform_action_money_wrap(amount)
	self:_add(amount)
end
function MoneyManager:calculate_end_score(multipliers)
	local player_alive = managers.player:player_unit() and true or false
	if not player_alive then
		return 0
	end
	multipliers = multipliers or {}
	local end_score = self._heist_total
	for _, multiplier in ipairs(multipliers) do
		if not tweak_data.money_manager.end_multipliers[multiplier] then
			Application:error("Unknown end multiplier \"" .. tostring(multiplier) .. " in money manager.")
		end
		end_score = end_score * tweak_data.money_manager.end_multipliers[multiplier]
	end
	self._global.total = self._global.total + end_score
	return math.round(end_score)
end
function MoneyManager:total()
	return self._global.total
end
function MoneyManager:_add(amount)
	amount = self:_check_multipliers(amount)
	self._heist_total = self._heist_total + amount
	self:_present(amount)
end
function MoneyManager:_check_multipliers(amount)
	for _, multiplier in pairs(self._active_multipliers) do
		amount = amount * multiplier
	end
	return math.round(amount)
end
function MoneyManager:_present(amount)
	local s_amount = tostring(amount)
	local reverse = string.reverse(s_amount)
	local present = ""
	for i = 1, string.len(reverse) do
		present = present .. string.sub(reverse, i, i) .. (math.mod(i, 3) == 0 and i ~= string.len(reverse) and "," or "")
	end
	local event = "money_collect_small"
	if 999 < amount then
		event = "money_collect_large"
	elseif 101 < amount then
		event = "money_collect_medium"
	end
end
function MoneyManager:actions()
	local t = {}
	for action, _ in pairs(tweak_data.money_manager.actions) do
		table.insert(t, action)
	end
	table.sort(t)
	return t
end
function MoneyManager:multipliers()
	local t = {}
	for multiplier, _ in pairs(tweak_data.money_manager.multipliers) do
		table.insert(t, multiplier)
	end
	table.sort(t)
	return t
end
function MoneyManager:save(data)
	local state = {
		total = self._global.total
	}
	data.MoneyManager = state
end
function MoneyManager:load(data)
	local state = data.MoneyManager
	self._global.total = state.total
end
