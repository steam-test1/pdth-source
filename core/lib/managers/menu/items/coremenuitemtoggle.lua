core:module("CoreMenuItemToggle")
core:import("CoreMenuItem")
core:import("CoreMenuItemOption")
ItemToggle = ItemToggle or class(CoreMenuItem.Item)
ItemToggle.TYPE = "toggle"
function ItemToggle:init(data_node, parameters)
	CoreMenuItem.Item.init(self, data_node, parameters)
	self._type = "toggle"
	local params = self._parameters
	self.options = {}
	self.selected = 1
	if data_node then
		for _, c in ipairs(data_node) do
			local type = c._meta
			if type == "option" then
				local option = CoreMenuItemOption.ItemOption:new(c)
				self:add_option(option)
			end
		end
	end
end
function ItemToggle:add_option(option)
	table.insert(self.options, option)
end
function ItemToggle:toggle()
	if not self._enabled then
		return
	end
	self.selected = self.selected + 1
	if self.selected > #self.options then
		self.selected = 1
	end
	self:dirty()
end
function ItemToggle:toggle_back()
	if not self._enabled then
		return
	end
	self.selected = self.selected - 1
	if self.selected <= 0 then
		self.selected = #self.options
	end
	self:dirty()
end
function ItemToggle:selected_option()
	return self.options[self.selected]
end
function ItemToggle:value()
	local value = ""
	local selected_option = self:selected_option()
	if selected_option then
		value = selected_option:parameters().value
	end
	return value
end
function ItemToggle:set_value(value)
	for i, option in ipairs(self.options) do
		if option:parameters().value == value then
			self.selected = i
		else
		end
	end
	self:dirty()
end
