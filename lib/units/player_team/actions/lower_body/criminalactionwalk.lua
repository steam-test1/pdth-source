CriminalActionWalk = CriminalActionWalk or class(CopActionWalk)
CriminalActionWalk._anim_block_presets = {
	block_all = {
		idle = -1,
		action = -1,
		walk = -1,
		crouch = -1,
		stand = -1,
		dodge = -1,
		shoot = -1,
		turn = -1,
		light_hurt = -1,
		hurt = -1,
		heavy_hurt = -1,
		act = -1,
		death = -1
	},
	block_lower = {
		idle = -1,
		walk = -1,
		crouch = -1,
		stand = -1,
		dodge = -1,
		turn = -1,
		light_hurt = -1,
		hurt = -1,
		heavy_hurt = -1,
		act = -1,
		death = -1
	},
	block_upper = {
		shoot = -1,
		action = -1,
		stand = -1,
		crouch = -1
	},
	block_none = {stand = -1, crouch = -1}
}
