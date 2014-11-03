CivilianActionWalk = CivilianActionWalk or class(CopActionWalk)
CivilianActionWalk._walk_anim_velocities = {
	stand = {
		walk = {fwd = 170},
		run = {
			fwd = 455,
			bwd = 360,
			l = 350,
			r = 410
		}
	},
	panic = {
		run = {
			fwd = 455,
			bwd = 360,
			l = 350,
			r = 410
		}
	}
}
