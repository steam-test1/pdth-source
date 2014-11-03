core:import("CoreMenuItem")
MenuItemCustomizeController = MenuItemCustomizeController or class(CoreMenuItem.Item)
MenuItemCustomizeController.TYPE = "customize_controller"
function MenuItemCustomizeController:init(data_node, parameters)
	CoreMenuItem.Item.init(self, data_node, parameters)
	self._type = MenuItemCustomizeController.TYPE
end
