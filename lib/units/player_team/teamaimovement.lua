TeamAIMovement = TeamAIMovement or class(CopMovement)
TeamAIMovement._char_name_to_index = HuskPlayerMovement._char_name_to_index
TeamAIMovement._char_model_names = HuskPlayerMovement._char_model_names
function TeamAIMovement:_post_init()
	if not managers.groupai:state():player_weapons_hot() then
		self:set_cool()
	end
	self._standing_nav_seg_id = self._nav_tracker:nav_segment()
	self:play_redirect("idle")
end
function TeamAIMovement:set_character_anim_variables()
	HuskPlayerMovement.set_character_anim_variables(self)
end
function TeamAIMovement:m_detect_pos()
	return self._m_head_pos
end
function TeamAIMovement:set_position(pos)
	CopMovement.set_position(self, pos)
	self:_upd_location()
end
function TeamAIMovement:set_m_pos(pos)
	CopMovement.set_m_pos(self, pos)
	self:_upd_location()
end
function TeamAIMovement:_upd_location()
	local nav_seg_id = self._nav_tracker:nav_segment()
	if self._standing_nav_seg_id ~= nav_seg_id then
		self._standing_nav_seg_id = nav_seg_id
		local location_id = managers.navigation:location_id(nav_seg_id)
		managers.hud:set_mugshot_location(self._unit:unit_data().mugshot_id, location_id)
	end
end
function TeamAIMovement:get_location_id()
	return managers.navigation:location_id(self._standing_nav_seg_id)
end
function TeamAIMovement:on_disarmed()
	self._unit:brain():set_logic("surrender")
	self._unit:network():send("arrested")
	self._unit:character_damage():on_arrested()
end
function TeamAIMovement:on_SPOOCed()
	self._unit:brain():set_logic("surrender")
	self._unit:network():send("arrested")
	self._unit:character_damage():on_arrested()
end
function TeamAIMovement:on_discovered()
	if self._cool then
		self:_switch_to_not_cool()
	end
end
function TeamAIMovement:on_tase_ended()
	self._unit:character_damage():on_tase_ended()
end
function TeamAIMovement:tased()
	return self._unit:anim_data().tased
end
function TeamAIMovement:cool()
	return self._cool
end
function TeamAIMovement:downed()
	return self._unit:interaction()._active
end
function TeamAIMovement:set_cool()
	if self._cool then
		return
	end
	self._unit:base():set_slot(self._unit, 24)
	self._cool = true
	if not self._heat_listener_clbk then
		self._heat_listener_clbk = "TeamAIMovement" .. tostring(self._unit:key())
		managers.groupai:state():add_listener(self._heat_listener_clbk, {
			"player_weapons_hot"
		}, callback(self, self, "heat_clbk"))
	end
end
function TeamAIMovement:heat_clbk()
	if self._cool then
		self:_switch_to_not_cool()
	end
end
function TeamAIMovement:_switch_to_not_cool()
	managers.groupai:state():remove_listener(self._heat_listener_clbk)
	self._heat_listener_clbk = nil
	if not self._switch_to_not_cool_clbk_id then
		self._switch_to_not_cool_clbk_id = "switch_to_not_cool_clbk" .. tostring(self._unit:key())
		managers.enemy:add_delayed_clbk(self._switch_to_not_cool_clbk_id, callback(self, self, "_switch_to_not_cool_clbk_func"), Application:time() + math.random() * 1 + 0.5)
	end
end
function TeamAIMovement:_switch_to_not_cool_clbk_func()
	if self._switch_to_not_cool_clbk_id then
		self._switch_to_not_cool_clbk_id = nil
		self._cool = nil
		self._unit:base():set_slot(self._unit, 16)
		if self._unit:brain():is_available_for_assignment() then
			self._unit:brain():set_objective()
			self._unit:movement():action_request({
				type = "idle",
				body_part = 1,
				sync = true
			})
		end
		self:set_stance_by_code(2)
	end
end
function TeamAIMovement:pre_destroy()
	if self._heat_listener_clbk then
		managers.groupai:state():remove_listener(self._heat_listener_clbk)
		self._heat_listener_clbk = nil
	end
	if self._nav_tracker then
		managers.navigation:destroy_nav_tracker(self._nav_tracker)
		self._nav_tracker = nil
	end
	if self._switch_to_not_cool_clbk_id then
		managers.enemy:remove_delayed_clbk(self._switch_to_not_cool_clbk_id)
		self._switch_to_not_cool_clbk_id = nil
	end
	if self._link_data then
		self._link_data.parent:base():remove_destroy_listener("CopMovement" .. tostring(unit:key()))
	end
	if alive(self._rope) then
		self._rope:base():retract()
		self._rope = nil
	end
	self:_destroy_gadgets()
	for i_action, action in ipairs(self._active_actions) do
		if action and action.on_destroy then
			action:on_destroy()
		end
	end
	if self._attention and self._attention.destroy_listener_key then
		self._attention.unit:base():remove_destroy_listener(self._attention.destroy_listener_key)
		self._attention.destroy_listener_key = nil
	end
end
