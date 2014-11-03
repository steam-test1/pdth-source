PlayerManager = PlayerManager or class()
PlayerManager.WEAPON_SLOTS = 3
function PlayerManager:init()
	self._player_name = Idstring("units/multiplayer/mp_fps_mover/mp_fps_mover")
	self._players = {}
	self._nr_players = Global.nr_players or 1
	self._last_id = 1
	self._viewport_configs = {}
	self._viewport_configs[1] = {}
	self._viewport_configs[1][1] = {
		dimensions = {
			x = 0,
			y = 0,
			w = 1,
			h = 1
		}
	}
	self._viewport_configs[2] = {}
	self._viewport_configs[2][1] = {
		dimensions = {
			x = 0,
			y = 0,
			w = 1,
			h = 0.5
		}
	}
	self._viewport_configs[2][2] = {
		dimensions = {
			x = 0,
			y = 0.5,
			w = 1,
			h = 0.5
		}
	}
	self:_setup_rules()
	self._player_states = {
		standard = "ingame_standard",
		mask_off = "ingame_mask_off",
		bleed_out = "ingame_bleed_out",
		fatal = "ingame_fatal",
		arrested = "ingame_arrested",
		tased = "ingame_electrified",
		incapacitated = "ingame_incapacitated",
		clean = "ingame_clean"
	}
	self._DEFAULT_STATE = "mask_off"
	self._current_state = self._DEFAULT_STATE
	self._sync_states = {
		"clean",
		"mask_off",
		"standard"
	}
	self._current_sync_state = self._DEFAULT_STATE
	self:_setup()
end
function PlayerManager:_setup()
	self._equipment = {
		selections = {},
		specials = {},
		selected_index = nil
	}
	self._listener_holder = EventListenerHolder:new()
	self._player_mesh_suffix = ""
	if not Global.player_manager then
		Global.player_manager = {}
		Global.player_manager.upgrades = {}
		Global.player_manager.weapons = {}
		Global.player_manager.equipment = {}
		Global.player_manager.kit = {
			weapon_slots = {"beretta92", "m4"},
			equipment_slots = {
				"trip_mine",
				"extra_cable_tie"
			},
			special_equipment_slots = {},
			crew_bonus_slots = {
				"sharpshooters"
			}
		}
	end
	Global.player_manager.default_kit = {
		weapon_slots = {"beretta92", "m4"},
		equipment_slots = {},
		special_equipment_slots = {"cable_tie"},
		crew_bonus_slots = {}
	}
	Global.player_manager.synced_bonuses = {}
	Global.player_manager.synced_equipment_possession = {}
	self._global = Global.player_manager
end
function PlayerManager:_setup_rules()
	self._rules = {no_run = 0}
end
function PlayerManager:aquire_default_upgrades()
	managers.upgrades:aquire_default("beretta92")
	managers.upgrades:aquire_default("m4")
	managers.upgrades:aquire_default("cable_tie")
	managers.upgrades:aquire_default("welcome_to_the_gang")
	for i = 1, PlayerManager.WEAPON_SLOTS do
		if not managers.player:weapon_in_slot(i) then
			self._global.kit.weapon_slots[i] = managers.player:availible_weapons(i)[1]
		end
	end
	for i = 1, 3 do
		if not managers.player:equipment_in_slot(i) then
			self._global.kit.equipment_slots[i] = managers.player:availible_equipment(i)[1]
		end
	end
end
function PlayerManager:update_kit_to_peer(peer)
	local peer_id = managers.network:session():local_peer():id()
	for i = 1, PlayerManager.WEAPON_SLOTS do
		local weapon = self:weapon_in_slot(i)
		if weapon then
			peer:send_after_load("set_kit_selection", peer_id, "weapon", weapon, i)
		end
	end
	for i = 1, 3 do
		local equipment = self:equipment_in_slot(i)
		if equipment then
			peer:send_after_load("set_kit_selection", peer_id, "equipment", equipment, i)
		end
	end
	local crew_bonus = self:crew_bonus_in_slot(1)
	if crew_bonus then
		peer:send_after_load("set_kit_selection", peer_id, "crew_bonus", self:crew_bonus_in_slot(1), 1)
	end
end
function PlayerManager:update_crew_bonus_to_peers()
	local upgrade = self:crew_bonus_in_slot(1)
	if upgrade then
		local level = managers.player:upgrade_level("crew_bonus", upgrade)
		if level ~= 0 then
			local peer_id = managers.network:session():local_peer():id()
			managers.network:session():send_to_peers_synched("set_crew_bonus", peer_id, upgrade, level)
		end
	end
end
function PlayerManager:update_crew_bonus_to_peer(peer)
	local upgrade = self:crew_bonus_in_slot(1)
	if upgrade then
		local level = managers.player:upgrade_level("crew_bonus", upgrade)
		if level ~= 0 then
			local peer_id = managers.network:session():local_peer():id()
			peer:send_after_load("set_crew_bonus", peer_id, upgrade, level)
		end
	end
end
function PlayerManager:set_crew_bonus(peer_id, upgrade, level)
	local member = managers.network:game():member(peer_id)
	local state = member:unit() and member:unit():movement():current_state_name() or false
	local enabled = state == "standard"
	for _, data in ipairs(self._global.synced_bonuses) do
		if data.peer_id == peer_id then
			data.upgrade = upgrade
			data.level = level
			data.enabled = enabled
			self:_crew_bonus_consequence(upgrade)
			return
		end
	end
	table.insert(self._global.synced_bonuses, {
		peer_id = peer_id,
		upgrade = upgrade,
		level = level,
		enabled = enabled
	})
	self:_crew_bonus_consequence(upgrade)
	if member:unit() then
		managers.hud:set_mugshot_crewbonus(member:unit():unit_data().mugshot_id, tweak_data.upgrades.definitions[upgrade].icon)
	end
end
function PlayerManager:remove_crew_bonus(peer_id)
	local upgrade
	for i, data in ipairs(self._global.synced_bonuses) do
		if data.peer_id == peer_id then
			upgrade = data.upgrade
			table.remove(self._global.synced_bonuses, i)
			self:_crew_bonus_consequence(upgrade)
		else
		end
	end
end
function PlayerManager:_crew_bonus_consequence(upgrade)
	local player = self:player_unit()
	if not player then
		return
	end
	if upgrade == "aggressor" then
		for _, weapon in pairs(player:inventory():available_selections()) do
			weapon.unit:base():update_damage()
		end
	elseif upgrade == "sharpshooters" then
		self:spread_multiplier()
	end
end
function PlayerManager:update_crew_bonus_enabled(peer_id, state)
	for _, data in ipairs(self._global.synced_bonuses) do
		if data.peer_id == peer_id then
			data.enabled = state == "standard"
			self:_crew_bonus_consequence(data.upgrade)
			return
		end
	end
end
function PlayerManager:get_crew_bonus_by_peer(peer_id)
	for _, data in ipairs(self._global.synced_bonuses) do
		if data.peer_id == peer_id then
			return data.upgrade
		end
	end
	return nil
end
function PlayerManager:update(t, dt)
end
function PlayerManager:add_listener(key, events, clbk)
	self._listener_holder:add(key, events, clbk)
end
function PlayerManager:remove_listener(key)
	self._listener_holder:remove(key)
end
function PlayerManager:preload()
end
function PlayerManager:_internal_load()
	local player = self:player_unit()
	if not player then
		return
	end
	for i, name in ipairs(self._global.kit.weapon_slots) do
		if i <= PlayerManager.WEAPON_SLOTS then
			local ok_name = self._global.weapons[name] and name or self._global.weapons[self._global.default_kit.weapon_slots[i]] and self._global.default_kit.weapon_slots[i]
			if ok_name then
				local upgrade = tweak_data.upgrades.definitions[ok_name]
				if upgrade then
					player:inventory():add_unit_by_name(upgrade.unit_name, i == 1)
				end
			end
		end
	end
	if self._respawn then
	else
		self:_add_level_equipment(player)
		for i, name in ipairs(self._global.default_kit.special_equipment_slots) do
			local ok_name = self._global.equipment[name] and name
			if ok_name then
				local upgrade = tweak_data.upgrades.definitions[ok_name]
				if upgrade and (upgrade.slot and upgrade.slot < 2 or not upgrade.slot) then
					self:add_equipment({
						equipment = upgrade.equipment_id,
						silent = true
					})
				end
			end
		end
		for i, name in ipairs(self._global.kit.equipment_slots) do
			local ok_name = self._global.equipment[name] and name or self._global.default_kit.equipment_slots[i]
			if ok_name then
				local upgrade = tweak_data.upgrades.definitions[ok_name]
				if upgrade and (upgrade.slot and upgrade.slot < 2 or not upgrade.slot) then
					self:add_equipment({
						equipment = upgrade.equipment_id,
						silent = true
					})
				end
			end
		end
	end
	for i, name in ipairs(self._global.default_kit.crew_bonus_slots) do
	end
	if managers.experience:current_level() >= 5 then
		table.delete(self._global.default_kit.crew_bonus_slots, "welcome_to_the_gang")
	end
end
function PlayerManager:_add_level_equipment(player)
	local id = Global.running_simulation and managers.editor:layer("Level Settings"):get_setting("simulation_level_id")
	if id == "none" or not id then
		id = nil
	end
	id = id or Global.level_data.level_id
	if not id then
		return
	end
	local equipment = tweak_data.levels[id].equipment
	if not equipment then
		return
	end
	for _, eq in ipairs(equipment) do
		self:add_equipment({equipment = eq, silent = true})
	end
end
function PlayerManager:nr_players()
	return self._nr_players
end
function PlayerManager:set_nr_players(nr)
	self._nr_players = nr
end
function PlayerManager:player_id(unit)
	local id = self._last_id
	for k, player in ipairs(self._players) do
		if player == unit then
			id = k
		end
	end
	return id
end
function PlayerManager:setup_viewports()
	local configs = self._viewport_configs[self._last_id]
	if configs then
		for k, player in ipairs(self._players) do
			player:camera():setup_viewport(configs[k])
		end
	else
		Application:error("Unsupported number of players: " .. tostring(self._last_id))
	end
end
function PlayerManager:player_states()
	local ret = {}
	for k, _ in pairs(self._player_states) do
		table.insert(ret, k)
	end
	return ret
end
function PlayerManager:current_state()
	return self._current_state
end
function PlayerManager:default_player_state()
	return self._DEFAULT_STATE
end
function PlayerManager:set_player_state(state)
	state = state or self._current_state
	if state == self._current_state then
		return
	end
	if not self._player_states[state] then
		Application:error("State '" .. tostring(state) .. "' does not exist in list of available states.")
		state = self._DEFAULT_STATE
	end
	if table.contains(self._sync_states, state) then
		self._current_sync_state = state
	end
	self._current_state = state
	self:_change_player_state()
	if state == "clean" or state == "mask_off" then
		managers.groupai:state():calm_ai()
	end
end
function PlayerManager:spawn_players(position, rotation, state)
	for var = 1, self._nr_players do
		self._last_id = var
	end
	self:spawned_player(self._last_id, safe_spawn_unit(self:player_unit_name(), position, rotation))
	self:_flush_item_queue(self._last_id, self._players[self._last_id])
	return self._players[1]
end
function PlayerManager:spawned_player(id, unit)
	self._players[id] = unit
	self:setup_viewports()
	self:_internal_load()
	self:_change_player_state()
end
function PlayerManager:_change_player_state()
	local unit = self:player_unit()
	if not unit then
		return
	end
	self._listener_holder:call(self._current_state, unit)
	game_state_machine:change_state_by_name(self._player_states[self._current_state])
	unit:movement():change_state(self._current_state)
end
function PlayerManager:player_destroyed(id)
	self._players[id] = nil
	self._respawn = true
end
function PlayerManager:players()
	return self._players
end
function PlayerManager:player_unit_name()
	return self._player_name
end
function PlayerManager:player_unit(id)
	local p_id = id or 1
	return self._players[p_id]
end
function PlayerManager:warp_to(pos, rot, id)
	local player = self._players[id or 1]
	if alive(player) then
		player:movement():warp_to(pos, rot)
	end
end
function PlayerManager:aquire_weapon(upgrade, id)
	if self._global.weapons[id] then
		return
	end
	self._global.weapons[id] = upgrade
	local player = self:player_unit()
	if not player then
		return
	end
	local slot = tweak_data.weapon[id].use_data.selection_index
	if not player:inventory():available_selections()[slot] then
		player:inventory():add_unit_by_name(upgrade.unit_name, false)
	end
end
function PlayerManager:aquire_equipment(upgrade, id)
	if self._global.equipment[id] then
		return
	end
	self._global.equipment[id] = upgrade
	if upgrade.aquire then
		managers.upgrades:aquire_default(upgrade.aquire.upgrade)
	end
	local player = self:player_unit()
	if not player then
		return
	end
	if upgrade.slot == 1 and not self._global.kit.equipment_slots[upgrade.slot] then
		self._global.kit.equipment_slots[upgrade.slot] = id
		self:add_equipment({equipment = id})
	end
end
function PlayerManager:aquire_upgrade(upgrade)
	self._global.upgrades[upgrade.category] = self._global.upgrades[upgrade.category] or {}
	self._global.upgrades[upgrade.category][upgrade.upgrade] = upgrade.value
	if upgrade.category == "crew_bonus" and not managers.player:crew_bonus_in_slot(1) and managers.player:availible_crew_bonuses(1)[1] then
		self._global.kit.crew_bonus_slots[1] = managers.player:availible_crew_bonuses(1)[1]
	end
	local value = tweak_data.upgrades.values[upgrade.category][upgrade.upgrade][upgrade.value]
	if self[upgrade.upgrade] then
		self[upgrade.upgrade](self, value)
	end
end
function PlayerManager:aquire_incremental_upgrade(upgrade)
	self._global.upgrades[upgrade.category] = self._global.upgrades[upgrade.category] or {}
	local val = self._global.upgrades[upgrade.category][upgrade.upgrade]
	self._global.upgrades[upgrade.category][upgrade.upgrade] = (val or 0) + 1
	local value = tweak_data.upgrades.values[upgrade.category][upgrade.upgrade][self._global.upgrades[upgrade.category][upgrade.upgrade]]
	if self[upgrade.upgrade] then
		self[upgrade.upgrade](self, value)
	end
end
function PlayerManager:upgrade_value(category, upgrade, default)
	if not self._global.upgrades[category] then
		return default or 0
	end
	if not self._global.upgrades[category][upgrade] then
		return default or 0
	end
	local level = self._global.upgrades[category][upgrade]
	local value = tweak_data.upgrades.values[category][upgrade][level]
	return value
end
function PlayerManager:upgrade_level(category, upgrade, default)
	if not self._global.upgrades[category] then
		return default or 0
	end
	if not self._global.upgrades[category][upgrade] then
		return default or 0
	end
	local level = self._global.upgrades[category][upgrade]
	return level
end
function PlayerManager:upgrade_value_by_level(category, upgrade, level, default)
	return tweak_data.upgrades.values[category][upgrade][level] or default or 0
end
function PlayerManager:equipped_upgrade_value(equipped, category, upgrade)
	if not self:has_category_upgrade(category, upgrade) then
		return 0
	end
	if not table.contains(self._global.kit.equipment_slots, equipped) then
		return 0
	end
	return self:upgrade_value(category, upgrade)
end
function PlayerManager:synced_crew_bonus_upgrade_value(upgrade, default, ignore_enabled)
	local level = 0
	for _, data in ipairs(self._global.synced_bonuses) do
		if data.upgrade == upgrade and (ignore_enabled or data.enabled) then
			level = math.max(level, data.level)
		end
	end
	if level == 0 then
		return default
	end
	return self:upgrade_value_by_level("crew_bonus", upgrade, level)
end
function PlayerManager:has_category_upgrade(category, upgrade)
	if not self._global.upgrades[category] then
		return false
	end
	if not self._global.upgrades[category][upgrade] then
		return false
	end
	return true
end
function PlayerManager:body_armor_value()
	if not self:has_category_upgrade("player", "body_armor") then
		return 0
	end
	return self:upgrade_value("player", "body_armor")
end
function PlayerManager:thick_skin_value()
	if not self:has_category_upgrade("player", "thick_skin") then
		return 0
	end
	if not table.contains(self._global.kit.equipment_slots, "thick_skin") then
		return 0
	end
	return self:upgrade_value("player", "thick_skin")
end
function PlayerManager:toolset_value()
	if not self:has_category_upgrade("player", "toolset") then
		return 1
	end
	if not table.contains(self._global.kit.equipment_slots, "toolset") then
		return 1
	end
	return self:upgrade_value("player", "toolset")
end
function PlayerManager:inspect_current_upgrades()
	for name, upgrades in pairs(self._global.upgrades) do
		print("Weapon " .. name .. ":")
		for upgrade, level in pairs(upgrades) do
			print("Upgrade:", upgrade, "is at level", level, "and has value", string.format("%.2f", tweak_data.upgrades.values[name][upgrade][level]))
		end
		print("\n")
	end
end
function PlayerManager:spread_multiplier()
	if not alive(self:player_unit()) then
		return
	end
	self:player_unit():movement()._current_state:_update_crosshair_offset()
end
function PlayerManager:weapon_upgrade_progress(weapon_id)
	local current = 0
	local total = 0
	if self._global.upgrades[weapon_id] then
		for upgrade, value in pairs(self._global.upgrades[weapon_id]) do
			current = current + value
		end
	end
	for _, values in pairs(tweak_data.upgrades.values[weapon_id]) do
		total = total + #values
	end
	return current, total
end
function PlayerManager:crewbonus_upgrade_progress(bonus_id)
	local current = 0
	local total = 0
	if self._global.upgrades.crew_bonus[bonus_id] then
		current = self._global.upgrades.crew_bonus[bonus_id]
	end
	total = #tweak_data.upgrades.values.crew_bonus[bonus_id]
	return current, total
end
function PlayerManager:equipment_upgrade_progress(equipment_id)
	local current = 0
	local total = 0
	if tweak_data.upgrades.values[equipment_id] then
		if self._global.upgrades[equipment_id] then
			for upgrade, value in pairs(self._global.upgrades[equipment_id]) do
				current = current + value
			end
		end
		for _, values in pairs(tweak_data.upgrades.values[equipment_id]) do
			total = total + #values
		end
		return current, total
	end
	if tweak_data.upgrades.values.player[equipment_id] then
		if self._global.upgrades.player and self._global.upgrades.player[equipment_id] then
			current = self._global.upgrades.player[equipment_id]
		end
		total = #tweak_data.upgrades.values.player[equipment_id]
		return current, total
	end
	if tweak_data.upgrades.definitions[equipment_id] and tweak_data.upgrades.definitions[equipment_id].aquire then
		local upgrade = tweak_data.upgrades.definitions[tweak_data.upgrades.definitions[equipment_id].aquire.upgrade]
		return self:equipment_upgrade_progress(upgrade.upgrade.upgrade)
	end
	return current, total
end
function PlayerManager:has_weapon(name)
	return managers.player._global.weapons[name]
end
function PlayerManager:has_aquired_equipment(name)
	return managers.player._global.equipment[name]
end
function PlayerManager:availible_weapons(slot)
	local weapons = {}
	for name, _ in pairs(managers.player._global.weapons) do
		if not slot or slot and tweak_data.weapon[name].use_data.selection_index == slot then
			table.insert(weapons, name)
		end
	end
	return weapons
end
function PlayerManager:weapon_in_slot(slot)
	local weapon = self._global.kit.weapon_slots[slot]
	if self._global.weapons[weapon] then
		return weapon
	end
	local weapon = self._global.default_kit.weapon_slots[slot]
	return self._global.weapons[weapon] and weapon
end
function PlayerManager:availible_equipment(slot)
	local equipment = {}
	for name, _ in pairs(self._global.equipment) do
		if not slot or slot and tweak_data.upgrades.definitions[name].slot == slot then
			table.insert(equipment, name)
		end
	end
	return equipment
end
function PlayerManager:equipment_in_slot(slot)
	local equipment = self._global.kit.equipment_slots[slot]
	if self._global.equipment[equipment] then
		return equipment
	end
	local equipment = self._global.default_kit.equipment_slots[slot]
	return self._global.equipment[equipment] and equipment
end
function PlayerManager:availible_crew_bonuses(slot)
	if not self._global.upgrades.crew_bonus then
		return {}
	end
	local bonuses = {}
	for name, _ in pairs(self._global.upgrades.crew_bonus) do
		if name ~= "welcome_to_the_gang" or Global.experience_manager.level <= 5 then
			table.insert(bonuses, name)
		end
	end
	return bonuses
end
function PlayerManager:crew_bonus_in_slot(slot)
	if Global.experience_manager.level <= 5 and slot == 1 then
		return "welcome_to_the_gang"
	end
	local crew_bonus = self._global.kit.crew_bonus_slots[slot]
	if self._global.upgrades.crew_bonus[crew_bonus] then
		return crew_bonus
	end
	local crew_bonus = self._global.default_kit.crew_bonus_slots[slot]
	return self._global.upgrades.crew_bonus[crew_bonus] and crew_bonus
end
function PlayerManager:toggle_player_rule(rule)
	self._rules[rule] = not self._rules[rule]
	if rule == "no_run" and self._rules[rule] then
		local player = self:player_unit()
		if player:movement():current_state()._interupt_action_running then
			player:movement():current_state():_interupt_action_running(Application:time())
		end
	end
end
function PlayerManager:set_player_rule(rule, value)
	self._rules[rule] = self._rules[rule] + (value and 1 or -1)
	if rule == "no_run" and self:get_player_rule(rule) then
		local player = self:player_unit()
		if player:movement():current_state()._interupt_action_running then
			player:movement():current_state():_interupt_action_running(Application:time())
		end
	end
end
function PlayerManager:get_player_rule(rule)
	return self._rules[rule] > 0
end
function PlayerManager:add_equipment_possession(peer_id, equipment)
	self._global.synced_equipment_possession[peer_id] = self._global.synced_equipment_possession[peer_id] or {}
	if self._global.synced_equipment_possession[peer_id][equipment] then
		return
	end
	self._global.synced_equipment_possession[peer_id][equipment] = true
	local unit = managers.network:game():unit_from_peer_id(peer_id)
	if unit then
		managers.hud:add_mugshot_equipment(unit:unit_data().mugshot_id, equipment)
	end
end
function PlayerManager:remove_equipment_possession(peer_id, equipment)
	if not self._global.synced_equipment_possession[peer_id] then
		return
	end
	self._global.synced_equipment_possession[peer_id][equipment] = nil
	local unit = managers.network:game():unit_from_peer_id(peer_id)
	if not unit then
		return
	end
	managers.hud:remove_mugshot_equipment(unit:unit_data().mugshot_id, equipment)
end
function PlayerManager:get_synced_equipment_possession(peer_id)
	return self._global.synced_equipment_possession[peer_id]
end
function PlayerManager:update_equipment_possession_to_peer(peer)
	local peer_id = managers.network:session():local_peer():id()
	if self._global.synced_equipment_possession[peer_id] then
		for name, _ in pairs(self._global.synced_equipment_possession[peer_id]) do
			peer:send_after_load("sync_add_equipment_possession", peer_id, name)
		end
	end
end
function PlayerManager:peer_dropped_out(peer)
	local peer_id = peer:id()
	if Network:is_server() and self._global.synced_equipment_possession[peer_id] then
		local peers = {
			managers.network:session():local_peer()
		}
		for _, p in pairs(managers.network:session():peers()) do
			table.insert(peers, p)
		end
		for name, _ in pairs(self._global.synced_equipment_possession[peer_id]) do
			for _, p in pairs(peers) do
				local id = p:id()
				if not self._global.synced_equipment_possession[id] or not self._global.synced_equipment_possession[id][name] then
					if p == managers.network:session():local_peer() then
						managers.player:add_special({name = name})
					else
						p:send("give_equipment", name)
					end
				else
				end
			end
		end
	end
	self._global.synced_equipment_possession[peer_id] = nil
end
function PlayerManager:add_equipment(params)
	if tweak_data.equipments[params.equipment or params.name] then
		self:_add_equipment(params)
		return
	end
	if tweak_data.equipments.specials[params.equipment or params.name] then
		self:add_special(params)
		return
	end
	Application:error("No equipment or special equipment named", params.equipment or params.name)
end
function PlayerManager:_add_equipment(params)
	if self:has_equipment(params.equipment) then
		print("Allready have equipment", params.equipment)
		return
	end
	local equipment = params.equipment
	local tweak_data = tweak_data.equipments[equipment]
	local amount = params.amount or (tweak_data.quantity or 0) + self:upgrade_value(equipment, "quantity")
	local icon = params.icon or tweak_data and tweak_data.icon
	local use_function_name = params.use_function_name or tweak_data and tweak_data.use_function_name
	local use_function = use_function_name or nil
	table.insert(self._equipment.selections, {
		equipment = equipment,
		amount = 0,
		use_function = use_function,
		action_timer = tweak_data.action_timer
	})
	self._equipment.selected_index = self._equipment.selected_index or 1
	managers.hud:add_item({amount = amount, icon = icon})
	self:add_equipment_amount(equipment, amount)
end
function PlayerManager:add_equipment_amount(equipment, amount)
	local data, index = self:equipment_data_by_name(equipment)
	if data then
		data.amount = data.amount + amount
		managers.hud:set_item_amount(index, data.amount)
	end
end
function PlayerManager:equipment_data_by_name(equipment)
	for i, equipments in ipairs(self._equipment.selections) do
		if equipments.equipment == equipment then
			return equipments, i
		end
	end
	return nil
end
function PlayerManager:has_equipment(equipment)
	for i, equipments in ipairs(self._equipment.selections) do
		if equipments.equipment == equipment then
			return true
		end
	end
	return false
end
function PlayerManager:select_next_item()
	if not self._equipment.selected_index then
		return
	end
	self._equipment.selected_index = self._equipment.selected_index + 1 <= #self._equipment.selections and self._equipment.selected_index + 1 or 1
	managers.hud:set_next_item_selected()
end
function PlayerManager:select_previous_item()
	if not self._equipment.selected_index then
		return
	end
	self._equipment.selected_index = 1 <= self._equipment.selected_index - 1 and self._equipment.selected_index - 1 or #self._equipment.selections
	managers.hud:set_previous_item_selected()
end
function PlayerManager:clear_equipment()
	for i, equipment in ipairs(self._equipment.selections) do
		equipment.amount = 0
		managers.hud:set_item_amount(i, equipment.amount)
	end
end
function PlayerManager:from_server_equipment_place_result(selected_index, unit)
	if alive(unit) then
		unit:equipment():from_server_sentry_gun_place_result(selected_index ~= 0)
	end
	local equipment = self._equipment.selections[selected_index]
	if not equipment then
		return
	end
	equipment.amount = equipment.amount - 1
	managers.hud:set_item_amount(self._equipment.selected_index, equipment.amount)
end
function PlayerManager:use_selected_equipment(unit)
	local equipment = self._equipment.selections[self._equipment.selected_index]
	if not equipment or equipment.amount == 0 then
		return
	end
	local used_one = false
	local redirect
	if equipment.use_function then
		used_one, redirect = unit:equipment()[equipment.use_function](unit:equipment(), self._equipment.selected_index)
	else
		used_one = true
	end
	if used_one then
		equipment.amount = equipment.amount - 1
		managers.hud:set_item_amount(self._equipment.selected_index, equipment.amount)
	end
	return {
		expire_timer = equipment.action_timer,
		redirect = redirect
	}
end
function PlayerManager:add_special(params)
	local name = params.equipment or params.name
	if not tweak_data.equipments.specials[name] then
		Application:error("Special equipment " .. name .. " doesn't exist!")
		return
	end
	local unit = self:player_unit()
	local respawn = params.amount and true or false
	local equipment = tweak_data.equipments.specials[name]
	local amount = params.amount or equipment.quantity
	local extra = self:_equipped_upgrade_value(equipment)
	if self._equipment.specials[name] then
		if equipment.quantity then
			self._equipment.specials[name].amount = math.min(self._equipment.specials[name].amount + amount, equipment.quantity + extra)
			managers.hud:set_special_equipment_amount(self._equipment.specials[name].hud_id, self._equipment.specials[name].amount)
		end
		return
	end
	local icon = equipment.icon
	local action_message = equipment.action_message
	local dialog = equipment.dialog_id
	if not params.silent then
		local text = managers.localization:text(equipment.text_id)
		local title = managers.localization:text("present_obtained_mission_equipment_title")
		managers.hud:present_mid_text({
			text = text,
			title = title,
			icon = icon,
			time = 4
		})
		if dialog then
			managers.dialog:queue_dialog(dialog, {})
		end
		if action_message and alive(unit) then
			managers.network:session():send_to_peers("sync_show_action_message", unit, action_message)
		end
	end
	if equipment.sync_possession then
		managers.network:session():send_to_peers("sync_add_equipment_possession", managers.network:session():local_peer():id(), name)
		self:add_equipment_possession(managers.network:session():local_peer():id(), name)
	end
	local quantity = equipment.quantity and (not respawn or not math.min(params.amount, equipment.quantity + extra)) and equipment.quantity and math.min(amount + extra, equipment.quantity + extra)
	local hud_id = managers.hud:add_special_equipment({
		icon = icon,
		amount = quantity or nil
	})
	self._equipment.specials[name] = {
		hud_id = hud_id,
		amount = quantity or nil
	}
	if equipment.player_rule then
		self:set_player_rule(equipment.player_rule, true)
	end
end
function PlayerManager:_equipped_upgrade_value(equipment)
	if not equipment.extra_quantity then
		return 0
	end
	local equipped_upgrade = equipment.extra_quantity.equipped_upgrade
	local category = equipment.extra_quantity.category
	local upgrade = equipment.extra_quantity.upgrade
	return self:equipped_upgrade_value(equipped_upgrade, category, upgrade)
end
function PlayerManager:has_special_equipment(name)
	return self._equipment.specials[name]
end
function PlayerManager:can_pickup_equipment(name)
	if self._equipment.specials[name] then
		if self._equipment.specials[name].amount then
			local equipment = tweak_data.equipments.specials[name]
			local extra = self:_equipped_upgrade_value(equipment)
			return self._equipment.specials[name].amount < equipment.quantity + extra
		end
		return false
	end
	return true
end
function PlayerManager:remove_special(name)
	if not self._equipment.specials[name] then
		return
	end
	if self._equipment.specials[name].amount then
		self._equipment.specials[name].amount = self._equipment.specials[name].amount - 1
		managers.hud:set_special_equipment_amount(self._equipment.specials[name].hud_id, self._equipment.specials[name].amount)
	end
	if not self._equipment.specials[name].amount or self._equipment.specials[name].amount <= 0 then
		local hud_id = self._equipment.specials[name].hud_id
		managers.hud:remove_special_equipment(hud_id)
		self._equipment.specials[name] = nil
		local equipment = tweak_data.equipments.specials[name]
		if equipment.player_rule then
			self:set_player_rule(equipment.player_rule, false)
		end
		if equipment.sync_possession then
			managers.network:session():send_to_peers_synched("sync_remove_equipment_possession", managers.network:session():local_peer():id(), name)
			self:remove_equipment_possession(managers.network:session():local_peer():id(), name)
		end
	end
end
function PlayerManager:change_player_look(new_look)
	self._player_mesh_suffix = new_look
	for _, unit in pairs(managers.groupai:state():all_char_criminals()) do
		unit.unit:movement():set_character_anim_variables()
	end
end
function PlayerManager:save(data)
	local state = {
		kit = self._global.kit
	}
	data.PlayerManager = state
end
function PlayerManager:load(data)
	self:aquire_default_upgrades()
	local state = data.PlayerManager
	if state then
		self._global.kit = state.kit or self._global.kit
		self:_verify_loaded_data()
	end
end
function PlayerManager:_verify_loaded_data()
end
function PlayerManager:sync_save(data)
	local state = {
		current_sync_state = self._current_sync_state,
		player_mesh_suffix = self._player_mesh_suffix
	}
	data.PlayerManager = state
end
function PlayerManager:sync_load(data)
	local state = data.PlayerManager
	if state then
		self:set_player_state(state.current_sync_state)
		self:change_player_look(state.player_mesh_suffix)
	end
end
function PlayerManager:on_simulation_started()
	self._respawn = false
end
function PlayerManager:reset()
	if managers.hud then
		managers.hud:clear_items()
		managers.hud:clear_special_equipments()
	end
	Global.player_manager = nil
	self:_setup()
	self:_setup_rules()
	self:aquire_default_upgrades()
end
function PlayerManager:add_item(player_index, slot_name, item)
	local player = self:player_unit(player_index)
	if alive(player) then
		player:outfit():equip(item, slot_name)
	else
		self:_set_item_queue(player_index, slot_name, item)
	end
end
function PlayerManager:remove_item(player_index, slot_name)
	local player = self:player_unit(player_index)
	if alive(player) then
		player:outfit():equip(nil, slot_name)
	else
		self:_set_item_queue(player_index, slot_name, false)
	end
end
function PlayerManager:_set_item_queue(player_index, slot_name, item)
	self._queued_item_map = self._queued_item_map or {}
	self._queued_item_map[player_index] = self._queued_item_map[player_index] or {}
	self._queued_item_map[player_index][slot_name] = item
end
function PlayerManager:_flush_item_queue(player_index, player)
	if self._queued_item_map then
		queued_player_item_map = self._queued_item_map[player_index]
		if queued_player_item_map then
			for slot_name, item in pairs(queued_player_item_map) do
				player:outfit():equip(item, slot_name)
			end
			self._queued_item_map[player_index] = nil
			if not next(self._queued_item_map) then
				self._queued_item_map = nil
			end
		end
	end
end
function PlayerManager:on_peer_synch_request(peer)
	self:player_unit():network():synch_to_peer(peer)
end
