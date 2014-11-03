Pickup = Pickup or class(UnitBase)
function Pickup:init(unit)
	Pickup.super.init(self, unit, false)
	self._unit = unit
	self._active = true
end
function Pickup:sync_pickup()
	self:consume()
end
function Pickup:_pickup()
	Application:error("Pickup didn't have a _pickup() function!")
end
function Pickup:pickup(unit)
	if not self._active then
		return
	end
	return self:_pickup(unit)
end
function Pickup:consume()
	self:delete_unit()
end
function Pickup:set_active(active)
	self._active = active
end
function Pickup:delete_unit()
	World:delete_unit(self._unit)
end
function Pickup:save(data)
	local state = {}
	state.active = self._active
	data.Pickup = state
end
function Pickup:load(data)
	local state = data.Pickup
	if state then
		self:set_active(state.active)
	end
end
function Pickup:destroy(unit)
end
