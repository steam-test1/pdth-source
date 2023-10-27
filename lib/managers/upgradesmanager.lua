UpgradesManager = UpgradesManager or class()
function UpgradesManager:init()
	self:_setup()
end
function UpgradesManager:_setup()
	if not Global.upgrades_manager then
		Global.upgrades_manager = {}
		Global.upgrades_manager.aquired = {}
		Global.upgrades_manager.automanage = false
		Global.upgrades_manager.progress = {
			0,
			0,
			0,
			0
		}
		Global.upgrades_manager.target_tree = self:_autochange_tree()
		Global.upgrades_manager.disabled_visual_upgrades = {}
	end
	self._global = Global.upgrades_manager
end
function UpgradesManager:setup_current_weapon()
	local p_unit = managers.player:player_unit()
	if not p_unit then
		return
	end
	local weapon_unit = p_unit:inventory():equipped_unit()
	local weapon_name = weapon_unit:base().name_id
	self:_apply_visual_weapon_upgrade(weapon_unit, tweak_data.upgrades.visual.upgrade[weapon_name])
	local aquired_updgrades = {}
	for upgrade_id, upgrade in pairs(self._global.aquired) do
		if not self._global.disabled_visual_upgrades[upgrade_id] then
			local upgrade_def = tweak_data.upgrades.definitions[upgrade_id]
			if upgrade_def and upgrade_def.upgrade and upgrade_def.upgrade.category == weapon_name then
				table.insert(aquired_updgrades, {id = upgrade_id})
			end
		end
	end
	for _, upgrade_data in ipairs(aquired_updgrades) do
		self:_apply_visual_weapon_upgrade(weapon_unit, tweak_data.upgrades.visual.upgrade[upgrade_data.id])
	end
end
function UpgradesManager:visual_weapon_upgrade_active(upgrade)
	return not self._global.disabled_visual_upgrades[upgrade]
end
function UpgradesManager:toggle_visual_weapon_upgrade(upgrade)
	if self._global.disabled_visual_upgrades[upgrade] then
		self._global.disabled_visual_upgrades[upgrade] = nil
	else
		self._global.disabled_visual_upgrades[upgrade] = true
	end
end
function UpgradesManager:_apply_visual_weapon_upgrade(weapon_unit, upgrade)
	if not upgrade then
		return
	end
	for obj_name, vis in pairs(upgrade.objs) do
		weapon_unit:get_object(Idstring(obj_name)):set_visibility(vis)
	end
	if upgrade.fire_obj then
		local fire_obj = weapon_unit:get_object(Idstring(upgrade.fire_obj))
		weapon_unit:base():change_fire_object(fire_obj)
	end
end
function UpgradesManager:set_target_tree(tree)
	local level = managers.experience:current_level()
	local step = self._global.progress[tree]
	local cap = tweak_data.upgrades.tree_caps[self._global.progress[tree] + 1]
	if cap and level < cap then
		return
	end
	self:_set_target_tree(tree)
	self:present_target()
end
function UpgradesManager:_set_target_tree(tree)
	local i = self._global.progress[tree] + 1
	local upgrade = tweak_data.upgrades.definitions[tweak_data.upgrades.progress[tree][i]]
	self._global.target_tree = tree
end
function UpgradesManager:current_tree_name()
	return self:tree_name(self._global.target_tree)
end
function UpgradesManager:tree_name(tree)
	return managers.localization:text(tweak_data.upgrades.trees[tree].name_id)
end
function UpgradesManager:tree_allowed(tree, level)
	level = level or managers.experience:current_level()
	local cap = tweak_data.upgrades.tree_caps[self._global.progress[tree] + 1]
	return not cap or not (level < cap), cap
end
function UpgradesManager:current_tree()
	return self._global.target_tree
end
function UpgradesManager:next_upgrade(tree)
end
function UpgradesManager:aquire_target()
	self._global.progress[self._global.target_tree] = self._global.progress[self._global.target_tree] + 1
	local upgrade = tweak_data.upgrades.progress[self._global.target_tree][self._global.progress[self._global.target_tree]]
	self:aquire(upgrade)
	if self._global.automanage then
		self:_set_target_tree(self:_autochange_tree())
	end
	local level = managers.experience:current_level() + 1
	local cap = tweak_data.upgrades.tree_caps[self._global.progress[self._global.target_tree] + 1]
	if cap and level < cap then
		self:_set_target_tree(self:_autochange_tree(self._global.target_tree))
	end
end
function UpgradesManager:_next_tree()
	local tree
	if self._global.automanage then
		tree = self:_autochange_tree()
	end
	local level = managers.experience:current_level() + 1
	local cap = tweak_data.upgrades.tree_caps[self._global.progress[self._global.target_tree] + 1]
	if cap and level < cap then
		tree = self:_autochange_tree(self._global.target_tree)
	end
	return tree or self._global.target_tree
end
function UpgradesManager:num_trees()
	return managers.dlc:has_dlc1() and 4 or 3
end
function UpgradesManager:_autochange_tree(exlude_tree)
	local progress = clone(Global.upgrades_manager.progress)
	if exlude_tree then
		progress[exlude_tree] = nil
	end
	if not managers.dlc:has_dlc1() then
		progress[4] = nil
	end
	local n_tree = 0
	local n_v = 100
	for tree, v in pairs(progress) do
		if v < n_v then
			n_tree = tree
			n_v = v
		end
	end
	return n_tree
end
function UpgradesManager:aquired(id)
	if self._global.aquired[id] then
		return true
	end
end
function UpgradesManager:aquire_default(id)
	if not tweak_data.upgrades.definitions[id] then
		Application:error("Tried to aquire an upgrade that doesn't exist: " .. id .. "")
		return
	end
	if self._global.aquired[id] then
		return
	end
	self._global.aquired[id] = true
	local upgrade = tweak_data.upgrades.definitions[id]
	self:_aquire_upgrade(upgrade, id)
end
function UpgradesManager:aquire(id)
	if not tweak_data.upgrades.definitions[id] then
		Application:error("Tried to aquire an upgrade that doesn't exist: " .. (id or "nil") .. "")
		return
	end
	if self._global.aquired[id] then
		Application:error("Tried to aquire an upgrade that has allready been aquired: " .. id .. "")
		return
	end
	local level = managers.experience:current_level() + 1
	self._global.aquired[id] = true
	local upgrade = tweak_data.upgrades.definitions[id]
	self:_aquire_upgrade(upgrade, id)
	self:setup_current_weapon()
	managers.hud:present({
		level_up = true,
		level = level,
		tree = self._global.target_tree,
		next_tree = self:_next_tree(),
		time = 4,
		upgrade = upgrade,
		upgrade_id = id,
		icon = upgrade.icon,
		progress = clone(self._global.progress),
		alternative_upgrades = self:alternative_upgrades()
	})
end
function UpgradesManager:_aquire_upgrade(upgrade, id)
	if upgrade.category == "weapon" then
		self:_aquire_weapon(upgrade, id)
	elseif upgrade.category == "feature" then
		self:_aquire_feature(upgrade, id)
	elseif upgrade.category == "outfit" then
		self:_aquire_outfit(upgrade, id)
	elseif upgrade.category == "weapon_upgrade" then
		self:_aquire_weapon_upgrade(upgrade, id)
	elseif upgrade.category == "money_multiplier" then
		self:_aquire_money_upgrade(upgrade, id)
	elseif upgrade.category == "equipment" then
		self:_aquire_equipment(upgrade, id)
	elseif upgrade.category == "equipment_upgrade" then
		self:_aquire_equipment_upgrade(upgrade, id)
	elseif upgrade.category == "crew_bonus" then
		self:_aquire_crew_bonus(upgrade, id)
	end
end
function UpgradesManager:_aquire_weapon(upgrade, id)
	managers.player:aquire_weapon(upgrade, id)
end
function UpgradesManager:_aquire_feature(feature)
	if feature.incremental then
		managers.player:aquire_incremental_upgrade(feature.upgrade)
	else
		managers.player:aquire_upgrade(feature.upgrade)
	end
end
function UpgradesManager:_aquire_outfit(upgrade)
	print("Aquired an outfit", upgrade.name_id)
end
function UpgradesManager:_aquire_weapon_upgrade(upgrade)
	print("Aquired a weapon upgrade", upgrade.name_id)
end
function UpgradesManager:_aquire_money_upgrade(upgrade)
	managers.money:use_multiplier(upgrade.multiplier)
end
function UpgradesManager:_aquire_equipment(equipment, id)
	managers.player:aquire_equipment(equipment, id)
end
function UpgradesManager:_aquire_equipment_upgrade(equipment_upgrade)
	managers.player:aquire_upgrade(equipment_upgrade.upgrade)
end
function UpgradesManager:_aquire_crew_bonus(crew_bonus, id)
	managers.player:aquire_upgrade(crew_bonus.upgrade, id)
end
function UpgradesManager:update_target()
	self:present_target()
end
function UpgradesManager:present_target()
	local hud = managers.hud and managers.hud:script(Idstring("guis/experience_hud"))
	if not hud then
		return
	end
	local i = self._global.progress[self._global.target_tree] + 1
	local upgrade_id = tweak_data.upgrades.progress[self._global.target_tree][i]
	local upgrade = tweak_data.upgrades.definitions[upgrade_id]
	local upgrade_text = upgrade and (self:complete_title(upgrade_id, "single") or self:name(upgrade_id))
	hud:set_target_upgrade_text(upgrade and upgrade_text)
	local icon, texture_rect
	if upgrade then
		icon, texture_rect = tweak_data.hud_icons:get_icon_data(upgrade.icon)
	end
	hud:set_target_upgrade_icon(icon, texture_rect)
end
function UpgradesManager:alternative_upgrades()
	local t = {}
	for i, progress in ipairs(self._global.progress) do
		local upgrade = tweak_data.upgrades.progress[i][progress + 1]
		t[i] = upgrade or "mr_nice_guy"
	end
	return t
end
function UpgradesManager:is_locked(step)
	local level = managers.experience:current_level()
	for i, d in ipairs(tweak_data.upgrades.itree_caps) do
		if level < d.level then
			return step >= d.step
		end
	end
	return false
end
function UpgradesManager:get_level_from_step(step)
	for i, d in ipairs(tweak_data.upgrades.itree_caps) do
		if step == d.step then
			return d.level
		end
	end
	return 0
end
function UpgradesManager:progress()
	if managers.dlc:has_dlc1() then
		return {
			self._global.progress[1],
			self._global.progress[2],
			self._global.progress[3],
			self._global.progress[4]
		}
	end
	return {
		self._global.progress[1],
		self._global.progress[2],
		self._global.progress[3]
	}
end
function UpgradesManager:progress_by_tree(tree)
	return self._global.progress[tree]
end
function UpgradesManager:name(id)
	if not tweak_data.upgrades.definitions[id] then
		Application:error("Tried to get name from an upgrade that doesn't exist: " .. id .. "")
		return
	end
	local upgrade = tweak_data.upgrades.definitions[id]
	return managers.localization:text(upgrade.name_id)
end
function UpgradesManager:title(id)
	if not tweak_data.upgrades.definitions[id] then
		Application:error("Tried to get title from an upgrade that doesn't exist: " .. id .. "")
		return
	end
	local upgrade = tweak_data.upgrades.definitions[id]
	return upgrade.title_id and managers.localization:text(upgrade.title_id) or nil
end
function UpgradesManager:subtitle(id)
	if not tweak_data.upgrades.definitions[id] then
		Application:error("Tried to get subtitle from an upgrade that doesn't exist: " .. id .. "")
		return
	end
	local upgrade = tweak_data.upgrades.definitions[id]
	return upgrade.subtitle_id and managers.localization:text(upgrade.subtitle_id) or nil
end
function UpgradesManager:complete_title(id, type)
	local title = self:title(id)
	if not title then
		return nil
	end
	local subtitle = self:subtitle(id)
	if not subtitle then
		return title
	end
	if type then
		if type == "single" then
			return title .. " " .. subtitle
		else
			return title .. type .. subtitle
		end
	end
	return title .. "\n" .. subtitle
end
function UpgradesManager:description(id)
	if not tweak_data.upgrades.definitions[id] then
		Application:error("Tried to get description from an upgrade that doesn't exist: " .. id .. "")
		return
	end
	local upgrade = tweak_data.upgrades.definitions[id]
	return upgrade.subtitle_id and managers.localization:text(upgrade.description_text_id or id) or nil
end
function UpgradesManager:image(id)
	local image = tweak_data.upgrades.definitions[id].image
	if not image then
		return nil, nil
	end
	return tweak_data.hud_icons:get_icon_data(image)
end
function UpgradesManager:image_slice(id)
	local image_slice = tweak_data.upgrades.definitions[id].image_slice
	if not image_slice then
		return nil, nil
	end
	return tweak_data.hud_icons:get_icon_data(image_slice)
end
function UpgradesManager:icon(id)
	if not tweak_data.upgrades.definitions[id] then
		Application:error("Tried to aquire an upgrade that doesn't exist: " .. id .. "")
		return
	end
	return tweak_data.upgrades.definitions[id].icon
end
function UpgradesManager:aquired_by_category(category)
	local t = {}
	for name, _ in pairs(self._global.aquired) do
		if tweak_data.upgrades.definitions[name].category == category then
			table.insert(t, name)
		end
	end
	return t
end
function UpgradesManager:aquired_features()
	return self:aquired_by_category("feature")
end
function UpgradesManager:aquired_outfits()
	return self:aquired_by_category("outfit")
end
function UpgradesManager:aquired_weapons()
	return self:aquired_by_category("weapon")
end
function UpgradesManager:print_aquired_tree()
	local tree = {}
	for name, data in pairs(self._global.aquired) do
		tree[data.level] = {name = name}
	end
	for i, data in pairs(tree) do
		print(self:name(data.name))
	end
end
function UpgradesManager:analyze()
	local not_placed = {}
	local placed = {}
	local features = {}
	local amount = 0
	for lvl, upgrades in pairs(tweak_data.upgrades.levels) do
		print("Upgrades at level " .. lvl .. ":")
		for _, upgrade in ipairs(upgrades) do
			print("\t" .. upgrade)
		end
	end
	for name, data in pairs(tweak_data.upgrades.definitions) do
		amount = amount + 1
		for lvl, upgrades in pairs(tweak_data.upgrades.levels) do
			for _, upgrade in ipairs(upgrades) do
				if upgrade == name then
					if placed[name] then
						print("ERROR: Upgrade " .. name .. " is already placed in level " .. placed[name] .. "!")
					else
						placed[name] = lvl
					end
					if data.category == "feature" then
						features[data.upgrade.category] = features[data.upgrade.category] or {}
						table.insert(features[data.upgrade.category], {level = lvl, name = name})
					end
				end
			end
		end
		if not placed[name] then
			not_placed[name] = true
		end
	end
	for name, lvl in pairs(placed) do
		print("Upgrade " .. name .. " is placed in level\t\t " .. lvl .. ".")
	end
	for name, _ in pairs(not_placed) do
		print("Upgrade " .. name .. " is not placed any level!")
	end
	print("")
	for category, upgrades in pairs(features) do
		print("Upgrades for category " .. category .. " is recieved at:")
		for _, upgrade in ipairs(upgrades) do
			print("  Level: " .. upgrade.level .. ", " .. upgrade.name .. "")
		end
	end
	print([[

Total upgrades ]] .. amount .. ".")
end
function UpgradesManager:tree_stats()
	local t = {
		{
			u = {},
			a = 0
		},
		{
			u = {},
			a = 0
		},
		{
			u = {},
			a = 0
		}
	}
	for name, d in pairs(tweak_data.upgrades.definitions) do
		if d.tree then
			t[d.tree].a = t[d.tree].a + 1
			table.insert(t[d.tree].u, name)
		end
	end
	for i, d in ipairs(t) do
		print(inspect(d.u))
		print(d.a)
	end
end
function UpgradesManager:save(data)
	local state = {
		automanage = self._global.automanage,
		progress = self._global.progress,
		target_tree = self._global.target_tree,
		disabled_visual_upgrades = self._global.disabled_visual_upgrades
	}
	if self._global.incompatible_data_loaded and self._global.incompatible_data_loaded.progress then
		state.progress = clone(self._global.progress)
		for i, k in pairs(self._global.incompatible_data_loaded.progress) do
			print("saving incompatible data", i, k)
			state.progress[i] = math.max(state.progress[i], k)
		end
	end
	data.UpgradesManager = state
end
function UpgradesManager:load(data)
	local state = data.UpgradesManager
	self._global.automanage = state.automanage
	self._global.progress = state.progress
	self._global.target_tree = state.target_tree
	self._global.disabled_visual_upgrades = state.disabled_visual_upgrades
	self:_verify_loaded_data()
end
function UpgradesManager:_verify_loaded_data()
	while #self._global.progress < #tweak_data.upgrades.progress do
		table.insert(self._global.progress, 0)
	end
	while #self._global.progress > #tweak_data.upgrades.progress do
		table.remove(self._global.progress)
	end
	if self._global.progress[4] and not managers.dlc:has_dlc1() then
		self._global.incompatible_data_loaded = self._global.incompatible_data_loaded or {}
		self._global.incompatible_data_loaded.progress = {
			[4] = self._global.progress[4]
		}
		print("loading incompatible data", inspect(self._global.incompatible_data_loaded))
		self._global.progress[4] = 0
		if self._global.target_tree == 4 then
			self:_set_target_tree(self:_autochange_tree())
		end
	end
	if self._global.progress[self._global.target_tree] >= 48 then
		self:_set_target_tree(self:_autochange_tree())
	end
	if self._global.target_tree > #self._global.progress then
		self:_set_target_tree(self:_autochange_tree())
	end
	for tree, lvl in ipairs(self._global.progress) do
		for i = 1, lvl do
			local id = tweak_data.upgrades.progress[tree][i]
			local upgrade = tweak_data.upgrades.definitions[id]
			self:_aquire_upgrade(upgrade, id)
			self._global.aquired[id] = true
		end
	end
	if not self._global.disabled_visual_upgrades then
		self._global.disabled_visual_upgrades = {}
	end
end
function UpgradesManager:reset()
	Global.upgrades_manager = nil
	self:_setup()
end
