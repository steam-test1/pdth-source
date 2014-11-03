UpgradesVisualTweakData = UpgradesVisualTweakData or class()
function UpgradesVisualTweakData:init()
	self.upgrade = {}
	self.upgrade.c45 = {
		fire_obj = "fire",
		objs = {g_extension = false, g_extension1 = false},
		base = true
	}
	self.upgrade.c45_mag1 = nil
	self.upgrade.c45_mag2 = nil
	self.upgrade.c45_recoil1 = {
		fire_obj = "fire_2",
		objs = {g_extension = true, g_extension1 = false}
	}
	self.upgrade.c45_recoil2 = nil
	self.upgrade.c45_recoil3 = {
		fire_obj = "fire_2",
		objs = {g_extension = false, g_extension1 = true}
	}
	self.upgrade.c45_recoil4 = nil
	self.upgrade.c45_damage1 = nil
	self.upgrade.c45_damage2 = nil
	self.upgrade.c45_damage3 = nil
	self.upgrade.c45_damage4 = nil
	self.upgrade.beretta92 = {
		fire_obj = "fire",
		objs = {g_silencer = true, g_silencer_2 = false},
		base = true
	}
	self.upgrade.beretta_mag1 = nil
	self.upgrade.beretta_mag2 = nil
	self.upgrade.beretta_recoil1 = nil
	self.upgrade.beretta_recoil2 = nil
	self.upgrade.beretta_recoil3 = {
		fire_obj = "fire_2",
		objs = {g_silencer = false, g_silencer_2 = true}
	}
	self.upgrade.beretta_recoil4 = nil
	self.upgrade.beretta_spread1 = nil
	self.upgrade.beretta_spread2 = nil
	self.upgrade.raging_bull = {
		fire_obj = "fire",
		objs = {
			g_6_bullets_not_empty = true,
			g_6_bullets = true,
			g_shell_1 = true,
			g_shell_2 = true,
			g_shell_3 = true,
			g_shell_4 = true,
			g_shell_5 = true,
			g_shell_6 = true,
			g_6_bullets_dumdum_not_empty = false,
			g_6_bullets_dumdum = false,
			g_shell_1_dumdum = false,
			g_shell_2_dumdum = false,
			g_shell_3_dumdum = false,
			g_shell_4_dumdum = false,
			g_shell_5_dumdum = false,
			g_shell_6_dumdum = false,
			g_muzzle_1 = true,
			g_muzzle_2 = false,
			g_sight = false,
			g_sight_short = true
		},
		base = true
	}
	self.upgrade.raging_bull_spread1 = {
		fire_obj = "fire_2",
		objs = {
			g_muzzle_1 = false,
			g_muzzle_2 = true,
			g_sight = true,
			g_sight_short = false
		}
	}
	self.upgrade.raging_bull_spread2 = nil
	self.upgrade.raging_bull_spread3 = nil
	self.upgrade.raging_bull_spread4 = nil
	self.upgrade.raging_bull_reload_speed1 = nil
	self.upgrade.raging_bull_reload_speed2 = nil
	self.upgrade.raging_bull_damage1 = nil
	self.upgrade.raging_bull_damage2 = nil
	self.upgrade.raging_bull_damage3 = {
		objs = {
			g_6_bullets_not_empty = false,
			g_6_bullets = false,
			g_shell_1 = false,
			g_shell_2 = false,
			g_shell_3 = false,
			g_shell_4 = false,
			g_shell_5 = false,
			g_shell_6 = false,
			g_6_bullets_dumdum_not_empty = true,
			g_6_bullets_dumdum = true,
			g_shell_1_dumdum = true,
			g_shell_2_dumdum = true,
			g_shell_3_dumdum = true,
			g_shell_4_dumdum = true,
			g_shell_5_dumdum = true,
			g_shell_6_dumdum = true
		}
	}
	self.upgrade.raging_bull_damage4 = nil
	self.upgrade.m4 = {
		fire_obj = "fire",
		objs = {
			g_handle_sight = true,
			g_front_steelsight = true,
			g_front_steelsight_down = true,
			g_sight_il = true,
			g_reddot = false,
			g_sight = false,
			g_gfx_lens = false,
			g_nozzle_1 = true,
			g_nozzle_2 = false
		},
		base = true
	}
	self.upgrade.m4_mag1 = nil
	self.upgrade.m4_mag2 = nil
	self.upgrade.m4_spread1 = nil
	self.upgrade.m4_spread2 = {
		fire_obj = "fire_nozzle_2",
		objs = {g_nozzle_1 = false, g_nozzle_2 = true}
	}
	self.upgrade.m4_spread3 = nil
	self.upgrade.m4_spread4 = {
		objs = {
			g_handle_sight = false,
			g_front_steelsight = false,
			g_front_steelsight_down = true,
			g_sight_il = false,
			g_reddot = true,
			g_gfx_lens = true,
			g_sight = true
		}
	}
	self.upgrade.m4_damage1 = nil
	self.upgrade.m4_damage2 = nil
	self.upgrade.m14 = {
		objs = {
			g_iron_sight_1 = true,
			g_iron_sight_2 = false,
			g_reddot = false,
			g_sight = false,
			g_sight_lens = false
		},
		base = true
	}
	self.upgrade.m14_mag1 = nil
	self.upgrade.m14_mag2 = nil
	self.upgrade.m14_spread1 = nil
	self.upgrade.m14_spread2 = {
		objs = {
			g_iron_sight_1 = false,
			g_iron_sight_2 = true,
			g_reddot = true,
			g_sight = true,
			g_sight_lens = true
		}
	}
	self.upgrade.m14_damage1 = nil
	self.upgrade.m14_damage2 = nil
	self.upgrade.m14_recoil1 = nil
	self.upgrade.m14_recoil2 = nil
	self.upgrade.m14_recoil3 = nil
	self.upgrade.m14_recoil4 = nil
	self.upgrade.mp5 = {
		objs = {
			g_mag = true,
			g_mag_straight = false,
			g_double = false,
			g_standard_grip = true,
			g_standard_grip_not = false
		},
		base = true
	}
	self.upgrade.mp5_spread1 = nil
	self.upgrade.mp5_spread2 = {
		objs = {g_standard_grip = false, g_standard_grip_not = true}
	}
	self.upgrade.mp5_recoil1 = nil
	self.upgrade.mp5_recoil2 = nil
	self.upgrade.mp5_reload_speed1 = {
		objs = {
			g_mag = false,
			g_mag_straight = true,
			g_double = false
		}
	}
	self.upgrade.mp5_reload_speed2 = nil
	self.upgrade.mp5_reload_speed3 = {
		objs = {
			g_mag = false,
			g_mag_straight = false,
			g_double = true
		}
	}
	self.upgrade.mp5_reload_speed4 = nil
	self.upgrade.mp5_enter_steelsight_speed1 = nil
	self.upgrade.mp5_enter_steelsight_speed2 = nil
	self.upgrade.mac11 = {
		objs = {
			g_silencer_big = true,
			g_silencer_bigger = false,
			g_mag = true,
			g_mag_extended = false
		},
		base = true
	}
	self.upgrade.mac11_recoil1 = nil
	self.upgrade.mac11_recoil2 = nil
	self.upgrade.mac11_recoil3 = nil
	self.upgrade.mac11_recoil4 = {
		objs = {g_silencer_big = false, g_silencer_bigger = true}
	}
	self.upgrade.mac11_enter_steelsight_speed1 = nil
	self.upgrade.mac11_enter_steelsight_speed2 = nil
	self.upgrade.mac11_mag1 = {
		objs = {g_mag = false, g_mag_extended = true}
	}
	self.upgrade.mac11_mag2 = nil
	self.upgrade.mac11_mag3 = nil
	self.upgrade.mac11_mag4 = nil
	self.upgrade.r870_shotgun = {
		objs = {
			g_rail = true,
			g_kylflans = false,
			g_extender = false
		},
		base = true
	}
	self.upgrade.remington_mag1 = {
		objs = {g_extender = true}
	}
	self.upgrade.remington_mag2 = nil
	self.upgrade.remington_recoil1 = nil
	self.upgrade.remington_recoil2 = nil
	self.upgrade.remington_recoil3 = nil
	self.upgrade.remington_recoil4 = {
		objs = {g_rail = false, g_kylflans = true}
	}
	self.upgrade.remington_damage1 = nil
	self.upgrade.remington_damage2 = nil
	self.upgrade.remington_damage3 = nil
	self.upgrade.remington_damage4 = nil
	self.upgrade.mossberg = {
		objs = {
			g_pump_1 = true,
			g_pump_2 = false,
			g_shell_extension = false,
			g_reload_pipe = true,
			g_reload_pipe_2 = false
		},
		base = true
	}
	self.upgrade.mossberg_mag1 = nil
	self.upgrade.mossberg_mag2 = {
		objs = {g_shell_extension = true}
	}
	self.upgrade.mossberg_reload_speed1 = nil
	self.upgrade.mossberg_reload_speed2 = nil
	self.upgrade.mossberg_fire_rate_multiplier1 = nil
	self.upgrade.mossberg_fire_rate_multiplier2 = {
		objs = {g_reload_pipe = false, g_reload_pipe_2 = true}
	}
	self.upgrade.mossberg_fire_rate_multiplier3 = nil
	self.upgrade.mossberg_fire_rate_multiplier4 = {
		objs = {g_pump_1 = false, g_pump_2 = true}
	}
	self.upgrade.mossberg_recoil_multiplier1 = nil
	self.upgrade.mossberg_recoil_multiplier2 = nil
	self.upgrade.hk21 = {
		objs = {
			g_lens = false,
			g_sight_iron = true,
			g_sight = false,
			g_reddot = false,
			g_l_bipod = false,
			g_r_bipod = false,
			g_mag = false,
			g_mag_plast = false,
			g_mag_rund = true
		},
		base = true
	}
	self.upgrade.hk21_mag1 = nil
	self.upgrade.hk21_mag2 = nil
	self.upgrade.hk21_mag3 = nil
	self.upgrade.hk21_mag4 = {
		objs = {
			g_mag = true,
			g_mag_plast = true,
			g_mag_rund = false
		}
	}
	self.upgrade.hk21_recoil1 = {
		objs = {g_l_bipod = true, g_r_bipod = true}
	}
	self.upgrade.hk21_recoil2 = {
		objs = {
			g_sight_iron = false,
			g_sight = true,
			g_lens = true,
			g_reddot = true
		}
	}
	self.upgrade.hk21_damage1 = nil
	self.upgrade.hk21_damage2 = nil
	self.upgrade.hk21_damage3 = nil
	self.upgrade.hk21_damage4 = nil
	self.upgrade.ak47 = {
		objs = {
			g_steelsight = true,
			g_il_steelsight = true,
			g_wood = true,
			g_plastic = false,
			g_dot_sight = false,
			g_lens = false,
			g_dot = false
		},
		base = true
	}
	self.upgrade.ak47_damage1 = nil
	self.upgrade.ak47_damage2 = nil
	self.upgrade.ak47_damage3 = nil
	self.upgrade.ak47_damage4 = nil
	self.upgrade.ak47_mag1 = nil
	self.upgrade.ak47_mag2 = nil
	self.upgrade.ak47_recoil1 = nil
	self.upgrade.ak47_recoil2 = nil
	self.upgrade.ak47_recoil3 = {
		objs = {g_wood = false, g_plastic = true}
	}
	self.upgrade.ak47_recoil4 = nil
	self.upgrade.ak47_spread1 = {
		objs = {
			g_steelsight = false,
			g_il_steelsight = false,
			g_dot_sight = true,
			g_lens = true,
			g_dot = true
		}
	}
	self.upgrade.ak47_spread2 = nil
	self.upgrade.glock = {
		objs = {g_mag = true, g_mag_long = false},
		base = true
	}
	self.upgrade.glock_damage1 = nil
	self.upgrade.glock_damage2 = nil
	self.upgrade.glock_mag1 = {
		objs = {g_mag = false, g_mag_long = true}
	}
	self.upgrade.glock_mag2 = nil
	self.upgrade.glock_mag3 = nil
	self.upgrade.glock_mag4 = nil
	self.upgrade.glock_recoil1 = nil
	self.upgrade.glock_recoil2 = nil
	self.upgrade.glock_reload_speed1 = nil
	self.upgrade.glock_reload_speed2 = nil
	self.upgrade.m79 = {
		objs = {
			g_sight = false,
			g_grenade = true,
			g_grenade_high_explosive = false
		},
		base = true
	}
	self.upgrade.m79_clip_num1 = nil
	self.upgrade.m79_clip_num2 = nil
	self.upgrade.m79_damage1 = nil
	self.upgrade.m79_damage2 = nil
	self.upgrade.m79_damage3 = nil
	self.upgrade.m79_damage4 = {
		objs = {g_grenade = false, g_grenade_high_explosive = true}
	}
	self.upgrade.m79_expl_range1 = nil
	self.upgrade.m79_expl_range2 = {
		objs = {g_sight = true}
	}
end
