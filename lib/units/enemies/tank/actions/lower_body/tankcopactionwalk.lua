TankCopActionWalk = TankCopActionWalk or class(CopActionWalk)
TankCopActionWalk._walk_anim_velocities = {
	stand = {
		walk = {
			fwd = 85,
			bwd = 125,
			l = 118,
			r = 131
		},
		run = {
			fwd = 370,
			bwd = 220,
			l = 210,
			r = 280
		}
	}
}
TankCopActionWalk._walk_anim_lengths = {
	stand = {
		walk = {
			fwd = 53,
			bwd = 40,
			l = 40,
			r = 40
		},
		run = {
			fwd = 23,
			bwd = 23,
			l = 23,
			r = 23
		}
	}
}
for pose, speeds in pairs(TankCopActionWalk._walk_anim_lengths) do
	for speed, sides in pairs(speeds) do
		for side, speed in pairs(sides) do
			sides[side] = speed * 0.03333
		end
	end
end
function TankCopActionWalk:_sanitize()
	return CopActionWalk._sanitize(self)
end
