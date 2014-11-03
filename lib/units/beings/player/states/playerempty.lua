PlayerEmpty = PlayerEmpty or class(PlayerMovementState)
function PlayerEmpty:init(unit)
	PlayerMovementState.init(self, unit)
end
function PlayerEmpty:enter(enter_data)
	PlayerMovementState.enter(self)
end
function PlayerEmpty:exit()
	PlayerMovementState.exit(self)
end
function PlayerEmpty:update(t, dt)
	PlayerMovementState.update(self, t, dt)
end
function PlayerEmpty:destroy()
end
