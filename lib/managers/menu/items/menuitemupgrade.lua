core:import("CoreMenuItem")
MenuItemUpgrade = MenuItemUpgrade or class(CoreMenuItem.Item)
MenuItemUpgrade.TYPE = "upgrade"
function MenuItemUpgrade:init(data_node, parameters)
	CoreMenuItem.Item.init(self, data_node, parameters)
	self._parameters.upgrade_id = parameters.upgrade_id
	self._parameters.topic_text = parameters.topic_text
	self._type = MenuItemUpgrade.TYPE
end
