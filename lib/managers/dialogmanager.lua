DialogManager = DialogManager or class()
DialogManager.DialogNodeClasses = {
	sequence_node = "DialogNodeSequence",
	select_node = "DialogNodeSelect",
	random_node = "DialogNodeRandom",
	case_node = "DialogNodeCase"
}
DialogManager.DialogActionClasses = {
	dialog_line = "DialogActionLine",
	go_to_node = "DialogActionGoto",
	set = "DialogActionVariable",
	lua = "DialogActionCallback",
	quit = "DialogActionQuit"
}
function DialogManager:init()
	self._pause = false
	self._current_dialog = nil
	self._current_node_id = 0
	self._current_node_timer = 0
	self._queued_dialog = nil
	self._option_list = {}
	self._variables = {}
	self._variables.global = {}
	self._variables["local"] = {}
	self._bain_unit = World:spawn_unit(Idstring("units/characters/bain/bain"), Vector3(), Rotation())
end
function DialogManager:init_finalize()
	self._node_definition_list = {}
	self._conversation_list = {}
	self:_load_dialogs()
end
function DialogManager:on_simulation_ended()
	if self._current_dialog then
		self._current_dialog[self._current_node_id]:stop()
	end
	self:quit_dialog()
end
function DialogManager:update(t, dt)
	if not self._pause and self._current_dialog then
		self._current_node_timer = self._current_node_timer - dt
		if self._current_node_timer <= 0 then
			local node_data = self._current_dialog[self._current_node_id]
			if not self._queued_dialog then
				node_data:update(self._current_dialog_params)
			else
				node_data:stop()
				self._current_dialog = self._queued_dialog
				self._current_node_timer = 0
				self._current_node_id = self._current_dialog._start
				self._queued_dialog = nil
			end
		end
	end
end
function DialogManager:queue_dialog(id, params)
	if not params.skip_idle_check and managers.platform:presence() == "Idle" then
		return
	end
	if not self._current_dialog then
		self._current_dialog = self._conversation_list[id]
		if not self._current_dialog then
			Application:throw_exception("The dialog script tries to queue a dialog with id '" .. tostring(id) .. "' which doesn't seem to exist!")
		end
		self._current_dialog_params = params
		self._current_node_timer = 0
		self._current_node_id = self._current_dialog._start
	else
		local dialog = self._conversation_list[id]
		if not dialog then
			Application:throw_exception("The dialog script tries to queue a dialog with id '" .. tostring(id) .. "' which doesn't seem to exist!")
		end
		if self._queued_dialog and dialog._priority > self._queued_dialog._priority then
			return
		end
		if dialog._priority < self._current_dialog._priority then
			self._queued_dialog = dialog
		end
	end
	return true
end
function DialogManager:is_active()
	if self._current_dialog then
		return true
	end
	return false
end
function DialogManager:variable(var)
	return self._variables.global[var]
end
function DialogManager:go_to_node(node_id)
	self._current_node_timer = 0
	self._current_node_id = node_id
	self._pause = false
end
function DialogManager:pause_dialog()
	self._pause = true
end
function DialogManager:play_dialog()
	self._pause = false
end
function DialogManager:quit_dialog()
	managers.subtitle:set_visible(false)
	managers.subtitle:set_enabled(false)
	self._current_dialog = nil
	self._queued_dialog = nil
	self._pause = false
end
function DialogManager:option_list()
	return self._option_list
end
function DialogManager:conversation_names()
	local t = {}
	for name, _ in pairs(self._conversation_list) do
		table.insert(t, name)
	end
	table.sort(t)
	return t
end
function DialogManager:_set_option_list(list)
	self._option_list = list
end
function DialogManager:_node_definition(id)
	return self._node_definition_list[id]
end
function DialogManager:_unit(id)
	return self._unit_list[id]
end
function DialogManager:_variable(type, var)
	return self._variables[type][var]
end
function DialogManager:_set_variable(type, var, value)
	self._variables[type][var] = value
end
function DialogManager:_set_duration(value)
	self._current_node_timer = value
end
function DialogManager:_load_units()
	local units = World:find_units_quick("all")
	for _, unit in pairs(units) do
		if unit:drama() then
			self._unit_list[unit:drama():name()] = unit
		end
	end
end
function DialogManager:_load_dialogs()
	local file_name = "gamedata/dialogs/index"
	local data = PackageManager:script_data(Idstring("dialog_index"), file_name:id())
	for _, c in ipairs(data) do
		if c.name then
			self:_load_dialog_data(c.name)
		end
	end
end
function DialogManager:_load_dialog_data(name)
	local file_name = "gamedata/dialogs/" .. name
	local data = PackageManager:script_data(Idstring("dialog"), file_name:id())
	for _, c in ipairs(data) do
		if c._meta == "node_definitions" then
			for _, node in ipairs(c) do
				if node.id and node.character and node.drama_cue then
					self._node_definition_list[node.id] = {
						character = node.character,
						drama_cue = node.drama_cue
					}
				else
					Application:throw_exception("Error in '" .. file_name .. "'! A node definition must have an id, character and drama_cue parameters!")
				end
			end
		elseif c._meta == "conversation" then
			if c.id then
				local id = c.id
				if self._conversation_list[id] then
					Application:throw_exception("Error in '" .. file_name .. "'! A conversation with the ID '" .. tostring(id) .. "' already exist. Choose a unique ID!")
				end
				self:_load_nodes(id, c)
			else
				Application:throw_exception("Error in '" .. file_name .. "'! A conversation must have an id parameter!")
			end
		end
	end
end
function DialogManager:_load_nodes(id, data_node)
	self._conversation_list[id] = {}
	local list = self._conversation_list[id]
	if data_node.priority then
		list._priority = tonumber(data_node.priority)
	else
		list._priority = tweak_data.dialog.DEFAULT_PRIORITY
	end
	local nodes = 0
	for _, c in ipairs(data_node) do
		if c.id then
			local node_id = c.id
			if list[node_id] then
				Application:throw_exception("Error in 'gamedata/dialogs/'! A sequence with the ID '" .. tostring(node_id) .. "' already exist. Choose a unique ID!")
			end
			if not list._start then
				list._start = c.id
			end
			local class = _G[self.DialogNodeClasses[c._meta]]
			if class then
				list[node_id] = class:new(c)
			else
				Application:throw_exception("Error in 'gamedata/dialogs/'! The node class '" .. tostring(c._meta) .. "' is missing from the class list!")
			end
		else
			Application:throw_exception("Error in 'gamedata/dialogs/'! The node '" .. tostring(c._meta) .. "' is missing an ID!")
		end
		nodes = nodes + 1
	end
	if nodes == 0 then
		Application:throw_exception("Error in 'gamedata/dialogs/'! The conversation '" .. tostring(data_node.id) .. "' is empty!")
	end
end
DialogAction = DialogAction or class()
function DialogAction:init()
end
function DialogAction:stop()
end
function DialogAction:setup_variable(data_node)
	local variable = {}
	if data_node.variable then
		variable.name, variable.type = self:_process_variable(data_node.variable)
		local condition_list = {
			"equal",
			"less_than",
			"greater_than",
			"not_equal"
		}
		for _, k in pairs(condition_list) do
			if data_node[k] then
				variable.condition = k
				variable.value = tonumber(data_node[k])
				if variable.value == nil then
					variable.value = data_node[k]
				end
			else
			end
		end
		if not variable.condition then
			Application:throw_exception("Error in 'gamedata/dialogs/'! The variable in a 'dialog_line' action doesn't have a valid value! (Use 'equal', 'less_than', 'greater_than' or 'not_equal')")
		end
	end
	return variable
end
function DialogAction:check_variable(variable)
	if not variable.name then
		return true
	else
		local value = managers.dialog:_variable(variable.type, variable.name)
		value = value or 0
		if variable.condition == "equal" then
			if variable.value == value then
				return true
			end
		elseif variable.condition == "less_than" then
			if value < variable.value then
				return true
			end
		elseif variable.condition == "greater_than" then
			if value > variable.value then
				return true
			end
		elseif variable.condition == "not_equal" and variable.value ~= value then
			return true
		end
	end
	return false
end
function DialogAction:_process_variable(variable)
	local var_type = "local"
	local pos_begin, pos_end = variable:find("local")
	if pos_begin ~= 1 then
		pos_begin, pos_end = variable:find("global")
		if pos_begin == 1 then
			var_type = "global"
		else
			pos_begin = 1
			pos_end = -1
		end
	end
	local var_data = variable:sub(pos_end + 2)
	return var_data, var_type
end
DialogNode = DialogNode or class()
function DialogNode:init()
end
function DialogNode:update(...)
end
function DialogNode:stop()
end
DialogNodeSequence = DialogNodeSequence or class(DialogNode)
function DialogNodeSequence:init(data_node)
	self._action_list = {}
	self._current_action_id = 1
	for _, c in ipairs(data_node) do
		local class = _G[managers.dialog.DialogActionClasses[c._meta]]
		if class then
			table.insert(self._action_list, class:new(c))
		else
			Application:throw_exception("Error in 'gamedata/dialogs/'! The action class '" .. tostring(c._meta) .. "' is missing from the class list!")
		end
	end
	if #self._action_list == 0 then
		Application:throw_exception("Error in 'gamedata/dialogs/'! The sequence node '" .. tostring(data_node.id) .. "' is empty!")
	end
end
function DialogNodeSequence:update(...)
	local action = self._action_list[self._current_action_id]
	local duration = action:execute(...)
	managers.dialog:_set_duration(duration)
	self._current_action_id = self._current_action_id + 1
	if not self._action_list[self._current_action_id] then
		self._current_action_id = 1
	end
end
function DialogNodeSequence:stop()
	local action = self._action_list[self._current_action_id]
	action:stop()
	self._current_action_id = 1
end
DialogNodeSelect = DialogNodeSelect or class(DialogNode)
function DialogNodeSelect:init(data_node)
	self._action_list = {}
	for _, c in ipairs(data_node) do
		table.insert(self._action_list, DialogActionOption:new(c))
	end
	if #self._action_list == 0 then
		Application:throw_exception("Error in 'gamedata/dialogs/'! The select node '" .. tostring(data_node.id) .. "' is empty!")
	end
end
function DialogNodeSelect:update(...)
	local option_list = {}
	for _, k in pairs(self._action_list) do
		local data = k:data()
		if data then
			table.insert(option_list, data)
		end
	end
	managers.dialog:_set_option_list(option_list)
	managers.dialog:pause_dialog()
	managers.menu:open_menu("menu_dialog_options")
end
DialogNodeRandom = DialogNodeRandom or class(DialogNode)
function DialogNodeRandom:init(data_node)
	self._action_list = {}
	for _, c in ipairs(data_node) do
		table.insert(self._action_list, DialogActionRandom:new(c))
	end
	if #self._action_list == 0 then
		Application:throw_exception("Error in 'gamedata/dialogs/'! The random node '" .. tostring(data_node.id) .. "' is empty!")
	end
end
function DialogNodeRandom:update(...)
	local option = math.random(#self._action_list)
	local node = self._action_list[option]
	node:execute(...)
end
DialogNodeCase = DialogNodeCase or class(DialogNode)
function DialogNodeCase:init(data_node)
	self._action_list = {}
	for _, c in ipairs(data_node) do
		local case = DialogActionCase:new(c)
		self._action_list[case:value()] = case
	end
	if not next(self._action_list) then
		Application:throw_exception("Error in 'gamedata/dialogs/'! The case node '" .. tostring(data_node.id) .. "' is empty!")
	end
end
function DialogNodeCase:update(params)
	if not params or not params.case then
		Application:throw_exception("DialogNodeCase didn't recieve a params or case value!")
	end
	local case_node = self._action_list[params.case]
	if not case_node then
		managers.dialog:quit_dialog()
		return
	end
	case_node:execute(params)
end
DialogActionLine = DialogActionLine or class(DialogAction)
function DialogActionLine:init(data_node)
	if not data_node.id then
		Application:throw_exception("Error in 'gamedata/dialogs/'! The action '" .. tostring(data_node._meta) .. "' doesn't have an ID!")
	end
	self._unit = nil
	self._id = data_node.id
	self._node = managers.dialog:_node_definition(self._id)
	self._variable = DialogAction:setup_variable(data_node)
	if not self._node then
		Application:throw_exception("The dialog script tries to access a node definition id '" .. tostring(self._id) .. "', which doesn't seem to exist!")
	end
end
function DialogActionLine:execute(params)
	if DialogAction:check_variable(self._variable) then
		self._unit = not params.on_unit and params.override_characters and managers.player:player_unit()
		if not alive(self._unit) then
			if self._node.character == "dispatch" then
				self._unit = managers.dialog._bain_unit
			else
				self._unit = managers.criminals:character_unit_by_name(self._node.character)
			end
		end
		if not alive(self._unit) then
			Application:error("The dialog script tries to access a unit named '" .. tostring(self._node.character) .. "', which doesn't seem to exist. Line will be skipped.")
		end
		if alive(self._unit) then
			local duration = self._unit:drama():play_cue(self._node.drama_cue)
			return duration
		end
	end
	return 0
end
function DialogActionLine:stop()
	if self._unit then
		self._unit:drama():stop_cue(self._node.drama_cue)
	end
end
DialogActionGoto = DialogActionGoto or class(DialogAction)
function DialogActionGoto:init(data_node)
	if not data_node.id then
		Application:throw_exception("Error in 'gamedata/dialogs/'! The action '" .. tostring(data_node._meta) .. "' doesn't have an ID!")
	end
	self._id = data_node.id
	self._variable = DialogAction:setup_variable(data_node)
end
function DialogActionGoto:execute(...)
	if DialogAction:check_variable(self._variable) then
		managers.dialog:go_to_node(self._id)
	end
	return 0
end
DialogActionVariable = DialogActionVariable or class(DialogAction)
function DialogActionVariable:init(data_node)
	if not data_node.variable or data_node.value == nil then
		Application:throw_exception("Error in 'gamedata/dialogs/'! The action '" .. tostring(data_node._meta) .. "' doesn't have an variable or value parameter!")
	end
	self._variable, self._type = DialogAction:_process_variable(data_node.variable)
	self._value, self._sign = self:_process_value(data_node.value)
end
function DialogActionVariable:execute(...)
	local value = self._value
	if self._sign then
		local old_value = managers.dialog:_variable(self._type, self._variable)
		old_value = old_value or 0
		if self._sign == "++" then
			value = old_value + value
		elseif self._sign == "--" then
			value = old_value - value
		end
	end
	managers.dialog:_set_variable(self._type, self._variable, value)
	return 0
end
function DialogActionVariable:_process_value(value)
	local content
	local sign = value:sub(1, 2)
	if sign == "++" or sign == "--" then
		content = tonumber(value:sub(3))
		if not content then
			sign = nil
			content = value
		end
	else
		sign = nil
		content = tonumber(value)
		if not value then
			content = value
		end
	end
	return content, sign
end
DialogActionCallback = DialogActionCallback or class(DialogAction)
function DialogActionCallback:init(data_node)
	if not data_node.callback then
		Application:throw_exception("Error in 'gamedata/dialogs/'! The action '" .. tostring(data_node._meta) .. "' doesn't have an callback parameter!")
	end
	self._callback = data_node.callback
	self._class = data_node.class
	self._variable = DialogAction:setup_variable(data_node)
	if self._class then
		local class = _G[self._class]
		if not class then
			Application:throw_exception("Error in 'gamedata/dialogs/'! The class '" .. tostring(self._class) .. "' doesn't exist!")
		end
		if not class[self._callback] then
			Application:throw_exception("Error in 'gamedata/dialogs/'! The function '" .. tostring(self._callback) .. "' doesn't exist in '" .. tostring(self._class) .. "' class!")
		end
	elseif not DialogCallbacks[self._callback] then
		Application:throw_exception("Error in 'gamedata/dialogs/'! The function '" .. tostring(self._callback) .. "' doesn't exist in 'DialogCallbacks' class!")
	end
end
function DialogActionCallback:execute(...)
	if DialogAction:check_variable(self._variable) and self._callback then
		if self._class then
			local class = _G[self._class]
			class[self._callback]()
		else
			DialogCallbacks[self._callback]()
		end
	end
	return 0
end
DialogActionQuit = DialogActionQuit or class(DialogAction)
function DialogActionQuit:init(data_node)
	self._variable = DialogAction:setup_variable(data_node)
end
function DialogActionQuit:execute(...)
	if DialogAction:check_variable(self._variable) then
		managers.dialog:quit_dialog()
	end
end
DialogActionOption = DialogActionOption or class(DialogAction)
function DialogActionOption:init(data_node)
	if not data_node.string_id or not data_node.go_to_node then
		Application:throw_exception("Error in 'gamedata/dialogs/'! The action '" .. tostring(data_node._meta) .. "' doesn't have an string_id or go_to_node parameter!")
	end
	self._data = {
		string_id = data_node.string_id,
		go_to_node = data_node.go_to_node
	}
	self._variable = DialogAction:setup_variable(data_node)
end
function DialogActionOption:data()
	if DialogAction:check_variable(self._variable) then
		return self._data
	end
	return nil
end
DialogActionRandom = DialogActionRandom or class(DialogAction)
function DialogActionRandom:init(data_node)
	if not data_node.go_to_node then
		Application:throw_exception("Error in 'gamedata/dialogs/'! The action '" .. tostring(data_node._meta) .. "' doesn't have an 'go_to_node' parameter!")
	end
	self._go_to_node = data_node.go_to_node
end
function DialogActionRandom:execute(...)
	managers.dialog:go_to_node(self._go_to_node)
end
DialogActionCase = DialogActionCase or class(DialogAction)
function DialogActionCase:init(data_node)
	if not data_node.value then
		Application:throw_exception("Error in 'gamedata/dialogs/'! The action '" .. tostring(data_node._meta) .. "' doesn't have an 'value' parameter!")
	end
	if not data_node.go_to_node then
		Application:throw_exception("Error in 'gamedata/dialogs/'! The action '" .. tostring(data_node._meta) .. "' doesn't have an 'go_to_node' parameter!")
	end
	self._value = data_node.value
	self._go_to_node = data_node.go_to_node
end
function DialogActionCase:value()
	return self._value
end
function DialogActionCase:execute(...)
	managers.dialog:go_to_node(self._go_to_node)
end
DialogCallbacks = DialogCallbacks or class()
function DialogCallbacks:init()
end
