core:module("RumbleManager")
core:import("CoreRumbleManager")
core:import("CoreClass")
RumbleManager = RumbleManager or class(CoreRumbleManager.RumbleManager)
function RumbleManager:init()
	RumbleManager.super.init(self)
	_G.tweak_data:add_reload_callback(self, callback(self, self, "setup_preset_rumbles"))
	self:setup_preset_rumbles()
end
function RumbleManager:setup_preset_rumbles()
	self:add_preset_rumbles("weapon_fire", {
		engine = "both",
		peak = 0.5,
		sustain = 0.1,
		release = 0.05,
		cumulative = false
	})
	self:add_preset_rumbles("land", {
		engine = "both",
		peak = 0.5,
		sustain = 0.1,
		release = 0.1,
		cumulative = false
	})
	self:add_preset_rumbles("hard_land", {
		engine = "both",
		peak = 1,
		sustain = 0.3,
		release = 0.1,
		cumulative = false
	})
	self:add_preset_rumbles("electrified", {
		engine = "both",
		peak = 0.5,
		release = 0.05,
		cumulative = false
	})
	self:add_preset_rumbles("electric_shock", {
		engine = "both",
		peak = 1,
		sustain = 0.2,
		release = 0.1,
		cumulative = true
	})
	self:add_preset_rumbles("incapacitated_shock", {
		engine = "both",
		peak = 0.75,
		sustain = 0.2,
		release = 0.1,
		cumulative = true
	})
	self:add_preset_rumbles("damage_bullet", {
		engine = "both",
		peak = 1,
		sustain = 0.2,
		release = 0,
		cumulative = true
	})
	self:add_preset_rumbles("bullet_whizby", {
		engine = "both",
		peak = 1,
		sustain = 0.075,
		release = 0,
		cumulative = true
	})
	self:add_preset_rumbles("melee_hit", {
		engine = "both",
		peak = 1,
		sustain = 0.15,
		release = 0,
		cumulative = true
	})
	self:add_preset_rumbles("mission_triggered", {
		engine = "both",
		peak = 1,
		attack = 0.1,
		sustain = 0.3,
		release = 2.1,
		cumulative = true
	})
end
CoreClass.override_class(CoreRumbleManager.RumbleManager, RumbleManager)
