Drill = Drill or class(UnitBase)
Drill.active_drills = Drill.active_drills or 0
Drill.jammed_drills = Drill.jammed_drills or 0
Drill._drill_remind_clbk_id = "_drill_remind_clbk"
function Drill:init(unit)
	Drill.super.init(self, unit, false)
	self._unit = unit
	self._jammed = false
	self._jammed_count = 0
	self._powered = true
	self._use_effect = true
	self._active_effect_name = "effects/particles/equipment/vault_drill/drill_active"
end
function Drill:update(unit, t, dt)
end
function Drill:start()
	self:_start_drill_effect()
	if not self.started then
		self.started = true
		Drill.active_drills = Drill.active_drills + 1
	end
end
function Drill:stop()
	self:set_jammed(false)
end
function Drill:done()
	self:set_jammed(false)
	self:_kill_drill_effect()
	if self.started then
		self.started = nil
		Drill.active_drills = Drill.active_drills - 1
	end
end
function Drill:_start_drill_effect()
	if self._drill_effect then
		return
	end
	if self._use_effect then
		local params = {}
		params.effect = Idstring(self._active_effect_name)
		params.parent = self._unit:get_object(Idstring("e_drill_particles"))
		self._drill_effect = World:effect_manager():spawn(params)
	end
end
function Drill:_kill_drill_effect()
	if not self._drill_effect then
		return
	end
	if self._use_effect then
		World:effect_manager():fade_kill(self._drill_effect)
	end
	self._drill_effect = nil
end
function Drill:_kill_jammed_effect()
	if not self._jammed_effect then
		return
	end
	if self._use_effect then
		World:effect_manager():fade_kill(self._jammed_effect)
	end
	self._jammed_effect = nil
end
function Drill:set_jammed(jammed)
	if (self._jammed or false) == (jammed or false) then
		return
	end
	self._jammed = jammed
	if self._jammed then
		self._jammed_count = self._jammed_count + 1
		self:_kill_drill_effect()
		if self._use_effect then
			local params = {}
			params.effect = Idstring("effects/particles/equipment/vault_drill/drill_jammed")
			params.parent = self._unit:get_object(Idstring("e_drill_particles"))
			self._jammed_effect = World:effect_manager():spawn(params)
		end
	elseif self._jammed_effect then
		self:_kill_jammed_effect()
		self:_start_drill_effect()
		if not self.is_hacking_device and not self.is_saw then
			managers.groupai:state():teammate_comment(nil, "g22", self._unit:position(), true, 500, false)
		end
	end
	self:_change_num_jammed_drills(self._jammed and 1 or -1)
end
function Drill:_change_num_jammed_drills(d)
	Drill.jammed_drills = Drill.jammed_drills + d
	if Drill.jammed_drills > 0 and not Drill._drll_remind_clbk then
		Drill._drll_remind_clbk = callback(self, self, "_drill_remind_clbk")
		managers.enemy:add_delayed_clbk(Drill._drill_remind_clbk_id, Drill._drll_remind_clbk, Application:time() + 20)
	end
	if Drill.jammed_drills <= 0 and Drill._drll_remind_clbk then
		managers.enemy:remove_delayed_clbk(Drill._drill_remind_clbk_id)
		Drill._drll_remind_clbk = nil
	end
end
function Drill:_drill_remind_clbk()
	if not self.is_hacking_device then
		local suffix = Drill.active_drills > 1 and "plu" or "sin"
		if 1 >= self._jammed_count then
			managers.groupai:state():teammate_comment(nil, (self.is_saw and "d03_" or "d01x_") .. suffix, nil, false, nil, false)
		else
			managers.groupai:state():teammate_comment(nil, (self.is_saw and "d04_" or "d02x_") .. suffix, nil, false, nil, false)
		end
	elseif managers.groupai:state():bain_state() then
		managers.dialog:queue_dialog("Play_ban_d01", {})
	end
	managers.enemy:add_delayed_clbk(Drill._drill_remind_clbk_id, Drill._drll_remind_clbk, Application:time() + 45)
end
function Drill:set_powered(powered)
	if (self._powered or false) == (powered or false) then
		return
	end
	self._powered = powered
	if not self._powered then
		self:_kill_drill_effect()
	else
		self:_start_drill_effect()
		if not self.is_hacking_device and not self.is_saw then
			managers.groupai:state():teammate_comment(nil, "g22", self._unit:position(), true, 500, false)
		end
	end
end
function Drill:destroy()
	self:_kill_jammed_effect()
	self:_kill_drill_effect()
	self:set_jammed(false)
end
