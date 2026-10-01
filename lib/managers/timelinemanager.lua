TimelineManager = TimelineManager or class()
TimelineManager.PATH = "gamedata/timeline"
TimelineManager.FILE_EXTENSION = "timeline"
TimelineManager.FULL_PATH = TimelineManager.PATH .. "." .. TimelineManager.FILE_EXTENSION
function TimelineManager:init()
	if not Global.timeline_manager then
		self:setup()
	end
	self._load_done_callback = callback(self, self, "load_game_callback")
end
function TimelineManager:init_finalize()
	if Global.timeline_manager.init_load_savefile then
		managers.savefile:load_game(managers.savefile:current_game_cache_slot(), true)
		self:_set_init_load_savefile(false)
	end
	if Global.timeline_manager.init_save_savefile then
		managers.savefile:save_game(SavefileManager.AUTO_SAVE_SLOT, false)
		self:_set_init_save_savefile(false)
	end
end
function TimelineManager:setup()
	Global.timeline_manager = {
		init_load_savefile = nil,
		init_save_savefile = nil,
		event_map = {},
		event_list = {}
	}
	local list = PackageManager:script_data(self.FILE_EXTENSION:id(), self.PATH:id())
	for _, data in ipairs(list) do
		if data._meta == "event" then
			self:_parse_event(data)
		else
			Application:error("Unknown node \"" .. tostring(data._meta) .. "\" in \"" .. self.FULL_PATH .. "\". Expected \"event\" node.")
		end
	end
end
function TimelineManager:event_list()
	return Global.timeline_manager.event_list
end
function TimelineManager:event_ids()
	local t = {}
	for _, event in ipairs(Global.timeline_manager.event_list) do
		table.insert(t, event.id)
	end
	table.sort(t)
	return t
end
function TimelineManager:load_game(slot)
	managers.savefile:add_load_done_callback(self._load_done_callback)
	managers.savefile:load_game(slot, false)
end
function TimelineManager:load_game_callback()
	managers.savefile:remove_load_done_callback(self._load_done_callback)
	self:jump(self._event_id, self._checkpoint_index, true, false, self._level, self._mission, self._world_setting, self._level_class_name)
end
function TimelineManager:debug_level_jump(level, mission, world_setting, level_class_name)
	Global.timeline_manager.current_event_id = nil
	self._event_id = nil
	self._checkpoint_index = nil
	self:jump(nil, nil, false, false, level, mission, world_setting, level_class_name)
end
function TimelineManager:level_jump(level, mission, world_setting, level_class_name)
	self:jump(nil, nil, false, false, level, mission, world_setting, level_class_name)
end
function TimelineManager:return_to_timeline()
	self:jump(self._event_id, self._checkpoint_index, false, false, nil, nil, nil, nil)
end
function TimelineManager:jump(event_id, checkpoint_index, is_loading, load_debug_data, level, mission, world_setting, level_class_name)
	cat_print("timeline_manager", "[TimelineManager] Jump in timeline. Event id: " .. tostring(event_id) .. ", Checkpoint index: " .. tostring(checkpoint_index) .. ", Level: " .. tostring(level) .. ", Mission: " .. tostring(mission) .. ", class: " .. tostring(level_class_name))
	self._level = level
	self._mission = mission
	self._world_setting = world_setting
	self._level_class_name = level_class_name
	if event_id then
		local event_data = Global.timeline_manager.event_map[event_id]
		if not event_data then
			error("Tried to load to non-existing event id \"" .. tostring(event_id) .. "\".")
		end
		local checkpoint_data
		if checkpoint_index then
			checkpoint_data = event_data.checkpoint_list and event_data.checkpoint_list[checkpoint_index]
			if not checkpoint_data then
				error("Tried to load to non-existing checkpoint index \"" .. tostring(checkpoint_index) .. "\" in event id \"" .. tostring(event:id()) .. "\".")
			end
		end
		if load_debug_data then
			self:_load_debug_dynamic_data(event_data.index)
		end
		if not level then
			level = event_data.level
			level_class_name = event_data.level_class_name
			if checkpoint_data then
				mission = checkpoint_data.mission
				world_setting = checkpoint_data.world_setting
			else
				mission = event_data.mission
				world_setting = event_data.world_setting
			end
		end
		Global.timeline_manager.current_event_id = event_id
		self._event_id = event_id
		self._checkpoint_index = checkpoint_index
	end
	if not level then
		Application:error("Tried to load a nil level.")
	else
		if not is_loading then
			managers.savefile:save_game(SavefileManager.AUTO_SAVE_SLOT, true)
		end
		setup:load_level(level, mission, world_setting, level_class_name)
		self:_set_init_load_savefile(true)
		self:_set_init_save_savefile(not is_loading)
	end
end
function TimelineManager:activate_next_event()
	local event_data = Global.timeline_manager.event_map[self._event_id]
	if not event_data then
		Application:error("Tried to activate next event on a debug level. Make sure it exists in \"" .. tostring(self.FULL_PATH) .. "\" if you want it to trigger events and checkpoints.")
	else
		local next_event_data = Global.timeline_manager.event_list[event_data.index + 1]
		if not next_event_data then
			Application:error("Tried to activate next event when it was at the end of event list in file \"" .. tostring(self.FULL_PATH) .. "\". Event id: \"" .. tostring(event_data.id) .. "\"")
		elseif Application:editor() then
			cat_debug("debug", "Level activated next event in timeline but was skipped since it was in the editor. Current event id: \"" .. tostring(event_data.id) .. "\", Activated event id: \"" .. tostring(next_event_data.id) .. "\"")
		else
			self:jump(next_event_data.id, nil, false, false)
		end
	end
end
function TimelineManager:checkpoint_reached(event_id, next_checkpoint_index)
	if event_id then
		Application:error("Checkpoint reached on a debug level. Make sure it exists in \"" .. tostring(self.FULL_PATH) .. "\" if you want it to trigger events and checkpoints.")
	elseif event_id ~= self._event_id then
		Application:error("Checkpoint index " .. tostring(next_checkpoint_index) .. " reached in event \"" .. tostring(event_id) .. "\" but the timeline (\"" .. tostring(self.FULL_PATH) .. "\") are currently in event id \"" .. tostring(self._event_id) .. "\".")
	else
		local event_data = Global.timeline_manager.event_map[event_id]
		local checkpoint_list = event_data.checkpoint_list
		if not checkpoint_list then
			Application:error("Checkpoint index \"" .. tostring(next_checkpoint_index) .. "\" reached in event \"" .. tostring(event_id) .. "\" but the timeline (\"" .. tostring(self.FULL_PATH) .. "\") doesn't contain any checkpoints.")
		elseif not checkpoint_list[next_checkpoint_index] then
			Application:error("Checkpoint index \"" .. tostring(next_checkpoint_index) .. "\" reached in event \"" .. tostring(event_id) .. "\" but the timeline (\"" .. tostring(self.FULL_PATH) .. "\") only have " .. #checkpoint_list .. " checkpoints.")
		else
			local expected_checkpoint_index = (self._checkpoint_index or 0) + 1
			if next_checkpoint_index ~= expected_checkpoint_index then
				Application:error("Checkpoint index \"" .. tostring(next_checkpoint_index) .. "\" reached in event \"" .. tostring(event_id) .. "\" but the timeline (\"" .. tostring(self.FULL_PATH) .. "\") expected checkpoint index " .. expected_checkpoint_index .. ".")
			else
				self._checkpoint_index = next_checkpoint_index
			end
		end
	end
end
function TimelineManager:restart()
	if Application:editor() then
		return
	end
	if self._event_id or self._level then
		self:jump(self._event_id, self._checkpoint_index, false, true, self._level, self._mission, self._world_setting, self._level_class_name)
	elseif Global.to_roaming_map then
		Global.to_roaming_map = nil
		setup:load_roaming_map()
	else
		setup:load_start_menu()
	end
end
function TimelineManager:get_name(event_id, checkpoint_index)
	event_id = event_id or self._event_id
	checkpoint_index = checkpoint_index or self._checkpoint_index
	if event_id then
		local event_data = Global.timeline_manager.event_map[event_id]
		local checkpoint_data = event_data.checkpoint_list and event_data.checkpoint_list[checkpoint_index]
		local name = checkpoint_data and checkpoint_data.name or event_data.name
		return managers.localization:text(tostring(name))
	else
		return managers.localization:text("debug_level", {
			DEBUG_LEVEL_NAME = tostring(Global.level_data.level)
		})
	end
end
function TimelineManager:get_description(event_id, checkpoint_index)
	event_id = event_id or self._event_id
	checkpoint_index = checkpoint_index or self._checkpoint_index
	if event_id then
		local event_data = Global.timeline_manager.event_map[event_id]
		local checkpoint_data = event_data.checkpoint_list and event_data.checkpoint_list[checkpoint_index]
		local description = checkpoint_data and checkpoint_data.description or event_data.description
		return managers.localization:text(tostring(description))
	else
		return managers.localization:text("debug_level_description")
	end
end
function TimelineManager:_parse_event(node)
	local id = node.id
	local index = #Global.timeline_manager.event_list + 1
	local data
	if not id then
		local hint_string
		if index == 1 then
			hint_string = ""
		else
			hint_string = " It was defined after event with id \"" .. tostring(Global.timeline_manager.event_list[index].id) .. "\"."
		end
		Application:error("Event nr " .. index .. " lacks an id in \"" .. self.FULL_PATH .. "\"." .. hint_string)
	elseif Global.timeline_manager.event_map[id] then
		Application:error("Event id \"" .. tostring(id) .. "\" is already defined in \"" .. self.FULL_PATH .. "\".")
	else
		data = {
			id = id,
			index = index,
			level = node.level,
			level_class_name = node.level_class_name,
			mission = node.mission,
			world_setting = node.world_setting,
			name = node.name,
			description = node.description
		}
		for _, child_node in ipairs(node) do
			local child_node_name = child_node._meta
			if child_node_name == "checkpoints" then
				if data.checkpoint_list then
					Application:error("Multiple \"checkpoints\" nodes found in \"" .. TimelineManager.FULL_PATH .. "\" within event id \"" .. tostring(id) .. "\".")
				else
					data.checkpoint_list = {}
					for _, checkpoint_node in ipairs(child_node) do
						local checkpoint_node_name = checkpoint_node._meta
						if checkpoint_node_name ~= "checkpoint" then
							Application:error("Unknown node \"" .. tostring(checkpoint_node_name) .. "\" in \"" .. TimelineManager.FULL_PATH .. "\". Expected \"checkpoint\" node.")
						else
							local checkpoint_data = self:_parse_checkpoint(checkpoint_node)
							table.insert(data.checkpoint_list, checkpoint_data)
						end
					end
				end
			elseif child_node_name == "debug_dynamic_data" then
				if data.debug_dynamic_data then
					Application:error("Multiple \"debug_dynamic_data\" nodes found in \"" .. TimelineManager.FULL_PATH .. "\" within event id \"" .. tostring(id) .. "\".")
				else
					data.debug_dynamic_data = self:_parse_debug_dynamic_data(child_node, index)
				end
			else
				Application:error("Unknown node \"" .. tostring(child_node_name) .. "\" in \"" .. TimelineManager.FULL_PATH .. "\". Expected \"checkpoints\" or \"debug_dynamic_data\" node.")
			end
		end
	end
	if data then
		Global.timeline_manager.event_map[id] = data
		table.insert(Global.timeline_manager.event_list, data)
	end
	return id, data
end
function TimelineManager:_parse_checkpoint(node)
	local data = {
		mission = node.mission,
		world_setting = node.world_setting,
		name = node.name,
		description = node.description
	}
	return data
end
function TimelineManager:_parse_debug_dynamic_data(node, event_index)
	local data = {}
	for _, child_node in ipairs(node) do
		local child_node_name = child_node._meta
		if child_node_name == "inventory" then
			local inventory_data = {
				item_name = child_node.item_name,
				slot_name = child_node.slot_name or "right_hand",
				player_index = child_node.player_index
			}
			if not child_node.remove then
				data.add_inventory_list = data.add_inventory_list or {}
				table.insert(data.add_inventory_list, inventory_data)
			else
				data.remove_inventory_list = data.remove_inventory_list or {}
				table.insert(data.remove_inventory_list, inventory_data)
			end
		else
			Application:error("Unknown node \"" .. tostring(child_node_name) .. "\" in \"" .. TimelineManager.FULL_PATH .. "\". Expected \"inventory\" node.")
		end
	end
	return data
end
function TimelineManager:_load_debug_dynamic_data(event_index)
	local inventory_map = {}
	for index = 1, event_index do
		local event_data = Global.timeline_manager.event_list[index]
		local debug_dynamic_data = event_data.debug_dynamic_data
		if debug_dynamic_data then
			if debug_dynamic_data.add_inventory_list then
				for _, inventory in ipairs(debug_dynamic_data.add_inventory_list) do
					if inventory_map[inventory.slot_name] then
						Application:error("Tried to add inventory item name \"" .. tostring(inventory.item_name) .. "\" to slot name \"" .. tostring(inventory.slot_name) .. "\" twice in event at index \"" .. index .. "\".")
					else
						inventory_map[inventory.slot_name] = tostring(inventory.item_name)
					end
				end
			end
			if debug_dynamic_data.remove_inventory_list then
				for _, inventory in ipairs(debug_dynamic_data.remove_inventory_list) do
					if inventory_map[inventory.slot_name] ~= inventory.item_name then
						Application:error("Tried to remove non-existing inventory item name \"" .. tostring(inventory.item_name) .. "\" on slot name \"" .. tostring(inventory.slot_name) .. "\" in event at index \"" .. index .. "\". Current item on slot: \"" .. tostring(inventory_map[inventory.slot_name]) .. "\".")
					else
						inventory_map[inventory.slot_name] = nil
					end
				end
			end
		end
	end
	if Global.category_print.timeline_manager then
		local inventory_string
		for slot_name, item_name in pairs(inventory_map) do
			if inventory_string then
				inventory_string = inventory_string .. ", "
			else
				inventory_string = ""
			end
			inventory_string = inventory_string .. tostring(item_name) .. " (" .. tostring(slot_name) .. ")"
		end
		cat_print("timeline_manager", "[TimelineManager] Loaded debug dynamic data. Inventory: " .. tostring(inventory_string))
	end
	local player_count = managers.player:nr_players()
	for slot_name, item_name in pairs(inventory_map) do
		for player_index = 1, player_count do
			local item = managers.item:item(item_name)
			if item then
				managers.player:add_item(player_index, slot_name, item)
			else
				Application:error("No such inventory item name \"" .. tostring(item_name) .. "\" on slot name \"" .. tostring(slot_name) .. "\" in event at index \"" .. tostring(event_index) .. "\".")
			end
		end
	end
end
function TimelineManager:save(data)
	local state = {
		event_id = self._event_id,
		checkpoint_index = self._checkpoint_index,
		level = self._level,
		mission = self._mission,
		world_setting = self._world_setting,
		level_class_name = self._level_class_name
	}
	data.TimelineManager = state
end
function TimelineManager:load(data)
	local state = data.TimelineManager
	if state then
		self._event_id = state.event_id
		self._checkpoint_index = state.checkpoint_index
		self._level = state.level
		self._mission = state.mission
		self._world_setting = state.world_setting
		self._level_class_name = state.level_class_name
	end
end
function TimelineManager:_set_init_load_savefile(init_load_savefile)
	if not Global.timeline_manager.init_load_savefile ~= not init_load_savefile then
		Global.timeline_manager.init_load_savefile = init_load_savefile
		cat_print("timeline_manager", "[TimelineManager] Will load savefile at init: " .. tostring(init_load_savefile))
	end
end
function TimelineManager:_set_init_save_savefile(init_save_savefile)
	if not Global.timeline_manager.init_save_savefile ~= not init_save_savefile then
		Global.timeline_manager.init_save_savefile = init_save_savefile
		cat_print("timeline_manager", "[TimelineManager] Will save savefile at init: " .. tostring(init_save_savefile))
	end
end
