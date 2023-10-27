core:import("CoreMenuItem")
MenuItemKitSlot = MenuItemKitSlot or class(CoreMenuItem.Item)
MenuItemKitSlot.TYPE = "kitslot"
function MenuItemKitSlot:init(data_node, parameters)
	CoreMenuItem.Item.init(self, data_node, parameters)
	self._type = MenuItemKitSlot.TYPE
	self._options = {}
	self._current_index = 1
	if self._parameters.category == "weapon" then
		self._options = managers.player:availible_weapons(self._parameters.slot)
		local selected_weapon = managers.player:weapon_in_slot(self._parameters.slot)
		for i, option in ipairs(self._options) do
			if option == selected_weapon then
				self._current_index = i
				break
			end
		end
	elseif self._parameters.category == "equipment" then
		self._options = managers.player:availible_equipment(self._parameters.slot)
		local selected = managers.player:equipment_in_slot(self._parameters.slot)
		for i, option in ipairs(self._options) do
			if option == selected then
				self._current_index = i
				break
			end
		end
	elseif self._parameters.category == "crew_bonus" then
		self._options = managers.player:availible_crew_bonuses(self._parameters.slot)
		local selected = Global.player_manager.kit.crew_bonus_slots[self._parameters.slot]
		for i, option in ipairs(self._options) do
			if option == selected then
				self._current_index = i
				break
			end
		end
	end
end
function MenuItemKitSlot:next()
	if not self._enabled then
		return
	end
	if #self._options < 2 then
		return
	end
	if self._current_index == #self._options then
		return
	end
	self._current_index = self._current_index == #self._options and 1 or self._current_index + 1
	if self._parameters.category == "weapon" then
		Global.player_manager.kit.weapon_slots[self._parameters.slot] = self._options[self._current_index]
	end
	if self._parameters.category == "equipment" then
		Global.player_manager.kit.equipment_slots[self._parameters.slot] = self._options[self._current_index]
	end
	if self._parameters.category == "crew_bonus" then
		Global.player_manager.kit.crew_bonus_slots[self._parameters.slot] = self._options[self._current_index]
		managers.player:update_crew_bonus_to_peers()
	end
	if not managers.network:session() then
		return
	end
	local peer_id = managers.network:session():local_peer():id()
	managers.network:session():send_to_peers_synched("set_kit_selection", peer_id, self._parameters.category, self._options[self._current_index], self._parameters.slot)
	managers.menu:get_menu("kit_menu").renderer:set_kit_selection(peer_id, self._parameters.category, self._options[self._current_index], self._parameters.slot)
	return true
end
function MenuItemKitSlot:previous()
	if not self._enabled then
		return
	end
	if #self._options < 2 then
		return
	end
	if self._current_index == 1 then
		return
	end
	self._current_index = self._current_index == 1 and #self._options or self._current_index - 1
	if self._parameters.category == "weapon" then
		Global.player_manager.kit.weapon_slots[self._parameters.slot] = self._options[self._current_index]
	end
	if self._parameters.category == "equipment" then
		Global.player_manager.kit.equipment_slots[self._parameters.slot] = self._options[self._current_index]
	end
	if self._parameters.category == "crew_bonus" then
		Global.player_manager.kit.crew_bonus_slots[self._parameters.slot] = self._options[self._current_index]
		managers.player:update_crew_bonus_to_peers()
	end
	if not managers.network:session() then
		return
	end
	local peer_id = managers.network:session():local_peer():id()
	managers.network:session():send_to_peers_synched("set_kit_selection", peer_id, self._parameters.category, self._options[self._current_index], self._parameters.slot)
	managers.menu:get_menu("kit_menu").renderer:set_kit_selection(peer_id, self._parameters.category, self._options[self._current_index], self._parameters.slot)
	return true
end
function MenuItemKitSlot:left_arrow_visible()
	return self._current_index > 1 and self._enabled
end
function MenuItemKitSlot:right_arrow_visible()
	return self._current_index < #self._options and self._enabled
end
function MenuItemKitSlot:arrow_visible()
	return #self._options > 0
end
function MenuItemKitSlot:text()
	if #self._options == 0 then
		return managers.localization:text("menu_kit_locked")
	end
	if self._parameters.category == "weapon" then
		local id = self._options[self._current_index]
		local name_id = tweak_data.weapon[id].name_id
		return managers.localization:text(name_id)
	elseif self._parameters.category == "equipment" then
		local id = self._options[self._current_index]
		local equipment_id = tweak_data.upgrades.definitions[id].equipment_id
		local name_id = (tweak_data.equipments.specials[equipment_id] or tweak_data.equipments[equipment_id]).text_id
		return managers.localization:text(name_id)
	elseif self._parameters.category == "crew_bonus" then
		local id = self._options[self._current_index]
		local name_id = tweak_data.upgrades.definitions[id].name_id
		return managers.localization:text(name_id)
	end
end
function MenuItemKitSlot:icon_and_description()
	if #self._options == 0 then
		return "locked", managers.localization:text("des_locked")
	end
	if self._parameters.category == "weapon" then
		local id = self._options[self._current_index]
		local hud_icon = tweak_data.weapon[id].hud_icon
		local description_id = tweak_data.weapon[id].description_id
		local name_id = tweak_data.weapon[id].name_id
		return hud_icon, managers.localization:text(description_id)
	elseif self._parameters.category == "equipment" then
		local id = self._options[self._current_index]
		local equipment_id = tweak_data.upgrades.definitions[id].equipment_id
		local tweak_data = tweak_data.equipments.specials[equipment_id] or tweak_data.equipments[equipment_id]
		local description_id = tweak_data.description_id
		local hud_icon = tweak_data.icon
		return hud_icon, description_id and managers.localization:text(description_id) or "NO DESCRIPTION"
	elseif self._parameters.category == "crew_bonus" then
		local id = self._options[self._current_index]
		local description_id = tweak_data.upgrades.definitions[id].description_id
		local hud_icon = tweak_data.upgrades.definitions[id].icon
		return hud_icon, managers.localization:text(description_id)
	end
end
function MenuItemKitSlot:upgrade_progress()
	if #self._options == 0 then
		return 0, 0
	end
	if self._parameters.category == "weapon" then
		local id = self._options[self._current_index]
		return managers.player:weapon_upgrade_progress(id)
	elseif self._parameters.category == "equipment" then
		local id = self._options[self._current_index]
		local equipment_id = tweak_data.upgrades.definitions[id].equipment_id
		return managers.player:equipment_upgrade_progress(equipment_id)
	elseif self._parameters.category == "crew_bonus" then
		local id = self._options[self._current_index]
		return managers.player:crewbonus_upgrade_progress(id)
	end
	return 0, 0
end
function MenuItemKitSlot:percentage()
	return 66
end
function MenuItemKitSlot.clbk_msg_set_kit_selection(overwrite_data, msg_queue, rpc_name, peer_id, category, selection_name, slot)
	if msg_queue then
		local category_data = overwrite_data.categories[category]
		if not category_data then
			category_data = {}
			overwrite_data.categories[category] = category_data
		end
		local item_index = category_data[slot]
		if item_index then
			msg_queue[item_index] = {
				rpc_name,
				peer_id,
				category,
				selection_name,
				slot
			}
		else
			table.insert(msg_queue, {
				rpc_name,
				peer_id,
				category,
				selection_name,
				slot
			})
			category_data[slot] = #msg_queue
		end
	else
		for cat_name, cat_data in pairs(overwrite_data.categories) do
			for _slot, _ in pairs(cat_data) do
				cat_data[_slot] = nil
			end
		end
	end
end
