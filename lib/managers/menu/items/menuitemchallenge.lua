core:import("CoreMenuItem")
MenuItemChallenge = MenuItemChallenge or class(CoreMenuItem.Item)
MenuItemChallenge.TYPE = "challenge"
function MenuItemChallenge:init(data_node, parameters)
	CoreMenuItem.Item.init(self, data_node, parameters)
	self._parameters.description = parameters.description_text
	self._parameters.challenge = parameters.challenge
	self._type = MenuItemChallenge.TYPE
end
