core:module("CoreMenuItemSlider")
core:import("CoreMenuItem")
ItemSlider = ItemSlider or class(CoreMenuItem.Item)
ItemSlider.TYPE = "slider"
function ItemSlider:init(data_node, parameters)
	CoreMenuItem.Item.init(self, data_node, parameters)
	self._type = "slider"
	self._min = 0
	self._max = 1
	self._step = 0.1
	self._show_value = false
	if data_node then
		self._min = data_node.min or self._min
		self._max = data_node.max or self._max
		self._step = data_node.step or self._step
		self._show_value = data_node.show_value
	end
	self._min = tonumber(self._min)
	self._max = tonumber(self._max)
	self._step = tonumber(self._step)
	self._value = self._min
end
function ItemSlider:value()
	return self._value
end
function ItemSlider:show_value()
	return self._show_value
end
function ItemSlider:set_value(value)
	self._value = math.min(math.max(self._min, value), self._max)
	self:dirty()
end
function ItemSlider:set_value_by_percentage(percent)
	self:set_value(self._min + (self._max - self._min) * (percent / 100))
end
function ItemSlider:set_min(value)
	self._min = value
end
function ItemSlider:set_max(value)
	self._max = value
end
function ItemSlider:set_step(value)
	self._step = value
end
function ItemSlider:increase()
	self:set_value(self._value + self._step)
end
function ItemSlider:decrease()
	self:set_value(self._value - self._step)
end
function ItemSlider:percentage()
	return (self._value - self._min) / (self._max - self._min) * 100
end
