core:import("CoreMenuItem")
core:import("CoreMenuItemOption")
MenuItemMultiChoice = MenuItemMultiChoice or class(CoreMenuItem.Item)
MenuItemMultiChoice.TYPE = "multi_choice"
function MenuItemMultiChoice:init(data_node, parameters)
	CoreMenuItem.Item.init(self, data_node, parameters)
	self._type = MenuItemMultiChoice.TYPE
	self._options = {}
	self._current_index = 1
	self._all_options = {}
	if data_node then
		for _, c in ipairs(data_node) do
			local type = c._meta
			if type == "option" then
				local option = CoreMenuItemOption.ItemOption:new(c)
				self:add_option(option)
				local visible_callback = c.visible_callback
				if visible_callback then
					option.visible_callback_names = string.split(visible_callback, " ")
				end
			end
		end
	end
	self._enabled = true
	self:_show_options(nil)
end
function MenuItemMultiChoice:set_enabled(enabled)
	self._enabled = enabled
	self:dirty()
end
function MenuItemMultiChoice:set_callback_handler(callback_handler)
	MenuItemMultiChoice.super.set_callback_handler(self, callback_handler)
end
function MenuItemMultiChoice:visible(...)
	self:_show_options(self._callback_handler)
	return MenuItemMultiChoice.super.visible(self, ...)
end
function MenuItemMultiChoice:_show_options(callback_handler)
	local selected_value = self:selected_option() and self:selected_option():value()
	self._options = {}
	for _, option in ipairs(self._all_options) do
		local show = true
		if callback_handler and option.visible_callback_names then
			for _, id in ipairs(option.visible_callback_names) do
				if not callback_handler[id](callback_handler, option) then
					show = false
					break
				end
			end
		end
		if show then
			table.insert(self._options, option)
		end
	end
	if selected_value then
		self:set_current_index(1)
		self:set_value(selected_value)
	end
end
function MenuItemMultiChoice:add_option(option)
	table.insert(self._all_options, option)
end
function MenuItemMultiChoice:options()
	return self._options
end
function MenuItemMultiChoice:selected_option()
	return self._options[self._current_index]
end
function MenuItemMultiChoice:current_index()
	return self._current_index
end
function MenuItemMultiChoice:set_current_index(index)
	self._current_index = index
	self:dirty()
end
function MenuItemMultiChoice:set_value(value)
	for i, option in ipairs(self._options) do
		if option:parameters().value == value then
			self._current_index = i
			break
		end
	end
	self:dirty()
end
function MenuItemMultiChoice:value()
	local value = ""
	local selected_option = self:selected_option()
	if selected_option then
		value = selected_option:parameters().value
	end
	return value
end
function MenuItemMultiChoice:_highest_option_index()
	local index = 1
	for i, option in ipairs(self._options) do
		if not option:parameters().exclude then
			index = i
		end
	end
	return index
end
function MenuItemMultiChoice:_lowest_option_index()
	for i, option in ipairs(self._options) do
		if not option:parameters().exclude then
			return i
		end
	end
end
function MenuItemMultiChoice:next()
	if not self._enabled then
		return
	end
	if #self._options < 2 then
		return
	end
	if self._current_index == self:_highest_option_index() then
		return
	end
	repeat
		self._current_index = self._current_index == #self._options and 1 or self._current_index + 1
	until not self._options[self._current_index]:parameters().exclude
	return true
end
function MenuItemMultiChoice:previous()
	if not self._enabled then
		return
	end
	if #self._options < 2 then
		return
	end
	if self._current_index == self:_lowest_option_index() then
		return
	end
	repeat
		self._current_index = self._current_index == 1 and #self._options or self._current_index - 1
	until not self._options[self._current_index]:parameters().exclude
	return true
end
function MenuItemMultiChoice:left_arrow_visible()
	return self._current_index > self:_lowest_option_index() and self._enabled
end
function MenuItemMultiChoice:right_arrow_visible()
	return self._current_index < self:_highest_option_index() and self._enabled
end
function MenuItemMultiChoice:arrow_visible()
	return #self._options > 1
end
