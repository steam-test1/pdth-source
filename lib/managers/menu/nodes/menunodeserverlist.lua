core:import("CoreMenuNode")
core:import("CoreSerialize")
core:import("CoreMenuItem")
core:import("CoreMenuItemToggle")
MenuNodeServerList = MenuNodeServerList or class(MenuNodeTable)
function MenuNodeServerList:init(data_node)
	MenuNodeServerList.super.init(self, data_node)
end
function MenuNodeServerList:update(t, dt)
	MenuNodeServerList.super.update(self, t, dt)
end
function MenuNodeServerList:_setup_columns()
	self:_add_column({
		text = string.upper(""),
		proportions = 1.9,
		align = "left"
	})
	self:_add_column({
		text = string.upper(""),
		proportions = 1.7,
		align = "right"
	})
	self:_add_column({
		text = string.upper(""),
		proportions = 1,
		align = "right"
	})
	self:_add_column({
		text = string.upper(""),
		proportions = 0.225,
		align = "right"
	})
end
