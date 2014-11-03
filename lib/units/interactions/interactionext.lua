BaseInteractionExt = BaseInteractionExt or class()
function BaseInteractionExt:init(unit)
	self._unit = unit
	self._unit:set_extension_update_enabled(Idstring("interaction"), false)
	self:refresh_material()
	self:set_tweak_data(self.tweak_data)
	self:set_active(self._tweak_data.start_active or self._tweak_data.start_active == nil and true)
	self._interact_obj = self._interact_object and self._unit:get_object(Idstring(self._interact_object))
	self._interact_position = self._interact_obj and self._interact_obj:position() or self._unit:position()
	local rotation = self._interact_obj and self._interact_obj:rotation() or self._unit:rotation()
	self._interact_axis = self._tweak_data.axis and rotation[self._tweak_data.axis](rotation) or nil
	self:_update_interact_position()
end
local ids_material = Idstring("material")
function BaseInteractionExt:refresh_material()
	self._materials = self._unit:get_objects_by_type(ids_material)
end
function BaseInteractionExt:set_tweak_data(id)
	self.tweak_data = id
	self._tweak_data = tweak_data.interaction[id]
end
function BaseInteractionExt:interact_position()
	self:_update_interact_position()
	return self._interact_position
end
function BaseInteractionExt:interact_axis()
	self:_update_interact_axis()
	return self._interact_axis
end
function BaseInteractionExt:_update_interact_position()
	if self._unit:moving() then
		self._interact_position = self._interact_obj and self._interact_obj:position() or self._unit:position()
	end
end
function BaseInteractionExt:_update_interact_axis()
	if self._tweak_data.axis and self._unit:moving() then
		local rotation = self._interact_obj and self._interact_obj:rotation() or self._unit:rotation()
		self._interact_axis = self._tweak_data.axis and rotation[self._tweak_data.axis](rotation) or nil
	end
end
function BaseInteractionExt:interact_distance()
	return self._tweak_data.interact_distance or tweak_data.interaction.INTERACT_DISTANCE
end
function BaseInteractionExt:update(distance_to_player)
end
local is_PS3 = SystemInfo:platform() == Idstring("PS3")
function BaseInteractionExt:_btn_interact()
	if is_PS3 then
		return nil
	end
	local type = managers.controller:get_default_wrapper_type()
	return "[" .. managers.controller:get_settings(type):get_connection("interact"):get_input_name_list()[1] .. "]"
end
function BaseInteractionExt:selected(player)
	if self._tweak_data.special_equipment_block and managers.player:has_special_equipment(self._tweak_data.special_equipment_block) then
		return
	end
	local text = managers.localization:text(self._tweak_data.text_id, {
		BTN_INTERACT = self:_btn_interact()
	})
	local icon = self._tweak_data.icon
	if self._tweak_data.special_equipment and not managers.player:has_special_equipment(self._tweak_data.special_equipment) then
		text = managers.localization:text(self._tweak_data.equipment_text_id, {
			BTN_INTERACT = self:_btn_interact()
		})
		icon = self.no_equipment_icon or self._tweak_data.no_equipment_icon or icon
	end
	self:_set_contour("selected_color", 1)
	managers.hud:show_interact({text = text, icon = icon})
end
function BaseInteractionExt:unselect()
	self:_set_contour("standard_color", 1)
end
function BaseInteractionExt:_interact_say(data)
	local player = data[1]
	local say_line = data[2]
	self._interact_say_clbk = nil
	player:sound():say(say_line, true)
end
function BaseInteractionExt:interact_start(player)
	if self:_interact_blocked(player) then
		if self._tweak_data.blocked_hint then
			managers.hint:show_hint(self._tweak_data.blocked_hint)
		end
		return false
	end
	local has_equipment = not self._tweak_data.special_equipment and true or managers.player:has_special_equipment(self._tweak_data.special_equipment)
	local sound = has_equipment and (self._tweak_data.say_waiting or "") or self.say_waiting
	if sound and sound ~= "" then
		local delay = (self._tweak_data.timer or 0) * managers.player:toolset_value()
		delay = delay / 3 + math.random() * delay / 3
		local say_t = Application:time() + delay
		self._interact_say_clbk = "interact_say_waiting"
		managers.enemy:add_delayed_clbk(self._interact_say_clbk, callback(self, self, "_interact_say", {player, sound}), say_t)
	end
	if self._tweak_data.timer then
		if not self:can_interact(player) then
			if self._tweak_data.blocked_hint then
				managers.hint:show_hint(self._tweak_data.blocked_hint)
			end
			return false
		end
		self:_post_event(player, "sound_start")
		self:_at_interact_start(player)
		return false, self._tweak_data.timer * managers.player:toolset_value()
	end
	return self:interact(player)
end
function BaseInteractionExt:interact_interupt(player)
	self:_post_event(player, "sound_interupt")
	if self._interact_say_clbk then
		managers.enemy:remove_delayed_clbk(self._interact_say_clbk)
		self._interact_say_clbk = nil
	end
	self:_at_interact_interupt(player)
end
function BaseInteractionExt:_post_event(player, sound_type)
	if not alive(player) then
		return
	end
	if player ~= managers.player:player_unit() then
		return
	end
	if self._tweak_data[sound_type] then
		player:sound():play(self._tweak_data[sound_type])
	end
end
function BaseInteractionExt:_at_interact_start()
end
function BaseInteractionExt:_at_interact_interupt()
end
function BaseInteractionExt:interact(player)
	self:_post_event(player, "sound_done")
end
function BaseInteractionExt:can_interact(player)
	if self._tweak_data.special_equipment_block and managers.player:has_special_equipment(self._tweak_data.special_equipment_block) then
		return false
	end
	if not self._tweak_data.special_equipment or self._tweak_data.dont_need_equipment then
		return true
	end
	return managers.player:has_special_equipment(self._tweak_data.special_equipment)
end
function BaseInteractionExt:_interact_blocked(player)
	return false
end
function BaseInteractionExt:active()
	return self._active
end
function BaseInteractionExt:set_active(active, sync)
	if not active and self._active then
		managers.interaction:remove_object(self._unit)
		if not self._tweak_data.no_contour then
			managers.occlusion:add_occlusion(self._unit)
		end
	elseif active and not self._active then
		managers.interaction:add_object(self._unit)
		if not self._tweak_data.no_contour then
			managers.occlusion:remove_occlusion(self._unit)
		end
	end
	self._active = active
	self:_set_contour("standard_color", 1)
	if sync and managers.network:session() then
		managers.network:session():send_to_peers_synched("sync_interaction_set_active", self._unit, active)
	end
end
function BaseInteractionExt:set_assignment(name)
	self._assignment = name
end
local ids_contour_color = Idstring("contour_color")
local ids_contour_opacity = Idstring("contour_opacity")
function BaseInteractionExt:_set_contour(color, opacity)
	if self._tweak_data.no_contour then
		return
	end
	for _, m in ipairs(self._materials) do
		m:set_variable(ids_contour_color, tweak_data.contour[self._tweak_data.contour or "interactable"][color])
		m:set_variable(ids_contour_opacity, self._active and opacity or 0)
	end
end
function BaseInteractionExt:save(data)
	local state = {}
	state.active = self._active
	data.InteractionExt = state
end
function BaseInteractionExt:load(data)
	local state = data.InteractionExt
	if state then
		self:set_active(state.active)
	end
end
function BaseInteractionExt:remove_interact()
	if not managers.interaction:active_object() or self._unit == managers.interaction:active_object() then
		managers.hud:remove_interact()
	end
end
function BaseInteractionExt:destroy()
	self:remove_interact()
	self:set_active(false, false)
	if self._unit == managers.interaction:active_object() then
		self:_post_event(managers.player:player_unit(), "sound_interupt")
	end
	if not self._tweak_data.no_contour then
		managers.occlusion:add_occlusion(self._unit)
	end
end
UseInteractionExt = UseInteractionExt or class(BaseInteractionExt)
function UseInteractionExt:unselect()
	UseInteractionExt.super.unselect(self)
	managers.hud:remove_interact()
end
function UseInteractionExt:interact(player)
	if not self:can_interact(player) then
		return
	end
	UseInteractionExt.super.interact(self, player)
	if self._tweak_data.equipment_consume then
		managers.player:remove_special(self._tweak_data.special_equipment)
		if self._tweak_data.special_equipment == "planks" and Global.level_data.level_id == "secret_stash" then
			UseInteractionExt._saviour_count = (UseInteractionExt._saviour_count or 0) + 1
			if UseInteractionExt._saviour_count >= 20 then
				managers.challenges:set_flag("saviour")
			end
		end
	end
	if self._tweak_data.sound_event then
		player:sound():play(self._tweak_data.sound_event)
	end
	self:remove_interact()
	if self._unit:damage() then
		self._unit:damage():run_sequence_simple("interact", {unit = player})
	end
	managers.network:session():send_to_peers_synched("sync_interacted", self._unit)
	if self._assignment then
		managers.secret_assignment:interacted(self._assignment)
	end
	self:set_active(false)
end
function UseInteractionExt:sync_interacted()
	self:remove_interact()
	self:set_active(false)
	if self._unit:damage() then
		self._unit:damage():run_sequence_simple("interact")
	end
end
function UseInteractionExt:destroy()
	UseInteractionExt.super.destroy(self)
end
TripMineInteractionExt = TripMineInteractionExt or class(UseInteractionExt)
function TripMineInteractionExt:interact(player)
	TripMineInteractionExt.super.super.interact(self, player)
	local armed = not self._unit:base():armed()
	self._unit:base():set_armed(armed)
end
ReviveInteractionExt = ReviveInteractionExt or class(BaseInteractionExt)
function ReviveInteractionExt:init(unit, ...)
	self._wp_id = "ReviveInteractionExt" .. unit:id()
	ReviveInteractionExt.super.init(self, unit, ...)
end
function ReviveInteractionExt:_at_interact_start(player)
	if self.tweak_data == "revive" then
		self:_at_interact_start_revive(player)
	elseif self.tweak_data == "free" then
		self:_at_interact_start_free(player)
	end
	self:set_waypoint_paused(true)
	managers.network:session():send_to_peers_synched("interaction_set_waypoint_paused", self._unit, true)
end
function ReviveInteractionExt:_at_interact_start_revive(player)
	if self._unit:base().is_husk_player then
		local revive_rpc_params = {
			"start_revive_player"
		}
		self._unit:network():send_to_unit(revive_rpc_params)
	else
		self._unit:character_damage():pause_bleed_out()
	end
	if player:base().is_local_player then
		managers.achievment:set_script_data("player_reviving", true)
	end
end
function ReviveInteractionExt:_at_interact_start_free(player)
	if self._unit:base().is_husk_player then
		local revive_rpc_params = {
			"start_free_player"
		}
		self._unit:network():send_to_unit(revive_rpc_params)
	else
		self._unit:character_damage():pause_arrested_timer()
	end
end
function ReviveInteractionExt:_at_interact_interupt(player)
	if self.tweak_data == "revive" then
		self:_at_interact_interupt_revive(player)
	elseif self.tweak_data == "free" then
		self:_at_interact_interupt_free(player)
	end
	self:set_waypoint_paused(false)
	if self._unit:id() ~= -1 then
		managers.network:session():send_to_peers_synched("interaction_set_waypoint_paused", self._unit, false)
	end
end
function ReviveInteractionExt:_at_interact_interupt_revive(player)
	if self._unit:base().is_husk_player then
		local revive_rpc_params = {
			"interupt_revive_player"
		}
		self._unit:network():send_to_unit(revive_rpc_params)
	else
		self._unit:character_damage():unpause_bleed_out()
	end
	if player:base().is_local_player then
		managers.achievment:set_script_data("player_reviving", false)
	end
end
function ReviveInteractionExt:_at_interact_interupt_free(player)
	if self._unit:base().is_husk_player then
		local revive_rpc_params = {
			"interupt_free_player"
		}
		self._unit:network():send_to_unit(revive_rpc_params)
	else
		self._unit:character_damage():unpause_arrested_timer()
	end
end
function ReviveInteractionExt:set_waypoint_paused(paused)
	if self._active_wp then
		managers.hud:set_waypoint_timer_pause(self._wp_id, paused)
	end
end
function ReviveInteractionExt:get_waypoint_time()
	if self._active_wp then
		local data = managers.hud:get_waypoint_data(self._wp_id)
		if data then
			return data.timer
		end
	end
	return nil
end
local is_win32 = SystemInfo:platform() == Idstring("WIN32")
function ReviveInteractionExt:set_active(active, sync, down_time)
	ReviveInteractionExt.super.set_active(self, active)
	if not managers.hud:exists("guis/player_hud") then
		return
	end
	if self._active then
		local hint = self.tweak_data == "revive" and "teammate_downed" or "teammate_arrested"
		if hint == "teammate_downed" then
			managers.achievment:set_script_data("stand_together_fail", true)
		end
		local location_id = self._unit:movement():get_location_id()
		local location = location_id and " " .. managers.localization:text(location_id) or ""
		managers.hint:show_hint(hint, nil, false, {
			TEAMMATE = self._unit:base():nick_name(),
			LOCATION = location
		})
		if not self._active_wp then
			down_time = down_time or 999
			local text = managers.localization:text(self.tweak_data == "revive" and "debug_team_mate_need_revive" or "debug_team_mate_need_free")
			local icon = self.tweak_data == "revive" and "wp_revive" or "wp_rescue"
			local timer = self.tweak_data == "revive" and (self._unit:base().is_husk_player and down_time or tweak_data.character[self._unit:base()._tweak_table].damage.DOWNED_TIME) or self._unit:base().is_husk_player and tweak_data.player.damage.ARRESTED_TIME or tweak_data.character[self._unit:base()._tweak_table].damage.ARRESTED_TIME
			managers.hud:add_waypoint(self._wp_id, {
				text = text,
				icon = icon,
				unit = self._unit,
				distance = is_win32,
				present_timer = 1,
				timer = timer
			})
			self._active_wp = true
		end
	elseif self._active_wp then
		managers.hud:remove_waypoint(self._wp_id)
		self._active_wp = false
	end
end
function ReviveInteractionExt:unselect()
	managers.hud:remove_interact()
end
function ReviveInteractionExt:interact(reviving_unit)
	if reviving_unit and reviving_unit == managers.player:player_unit() then
		if not self:can_interact(reviving_unit) then
			return
		end
		if self._tweak_data.equipment_consume then
			managers.player:remove_special(self._tweak_data.special_equipment)
		end
		if self._tweak_data.sound_event then
			reviving_unit:sound():play(self._tweak_data.sound_event)
		end
		ReviveInteractionExt.super.interact(self, reviving_unit)
		managers.achievment:set_script_data("player_reviving", false)
	end
	self:remove_interact()
	if self._unit:damage() then
		self._unit:damage():run_sequence_simple("interact")
	end
	if self._unit:base().is_husk_player then
		local revive_rpc_params = {
			"revive_player"
		}
		managers.statistics:revived({npc = false, reviving_unit = reviving_unit})
		self._unit:network():send_to_unit(revive_rpc_params)
	else
		self._unit:character_damage():revive(reviving_unit)
		managers.statistics:revived({npc = true, reviving_unit = reviving_unit})
	end
	if Network:is_server() then
		local hint = self.tweak_data == "revive" and 2 or 3
		managers.network:session():send_to_peers_synched("sync_teammate_helped_hint", hint, self._unit, reviving_unit)
		managers.trade:sync_teammate_helped_hint(self._unit, reviving_unit, hint)
	end
end
function ReviveInteractionExt:save(data)
	ReviveInteractionExt.super.save(self, data)
	local state = {}
	state.active_wp = self._active_wp
	state.wp_id = self._wp_id
	data.ReviveInteractionExt = state
end
function ReviveInteractionExt:load(data)
	local state = data.ReviveInteractionExt
	if state then
		self._active_wp = state.active_wp
		self._wp_id = state.wp_id
	end
	ReviveInteractionExt.super.load(self, data)
end
AmmoBagInteractionExt = AmmoBagInteractionExt or class(UseInteractionExt)
function AmmoBagInteractionExt:_interact_blocked(player)
	return not player:inventory():need_ammo()
end
function AmmoBagInteractionExt:interact(player)
	AmmoBagInteractionExt.super.super.interact(self, player)
	local interacted = self._unit:base():take_ammo(player)
	managers.hud:set_ammo_amount(player:inventory():equipped_unit():base():ammo_info())
	for _, weapon in pairs(player:inventory():available_selections()) do
		managers.hud:set_weapon_ammo_by_unit(weapon.unit)
	end
	return interacted
end
DoctorBagBaseInteractionExt = DoctorBagBaseInteractionExt or class(UseInteractionExt)
function DoctorBagBaseInteractionExt:_interact_blocked(player)
	return player:character_damage():full_health()
end
function DoctorBagBaseInteractionExt:interact(player)
	DoctorBagBaseInteractionExt.super.super.interact(self, player)
	local interacted = self._unit:base():take(player)
	return interacted
end
C4BagInteractionExt = C4BagInteractionExt or class(UseInteractionExt)
function C4BagInteractionExt:_interact_blocked(player)
	return not managers.player:can_pickup_equipment("c4")
end
function C4BagInteractionExt:interact(player)
	C4BagInteractionExt.super.super.interact(self, player)
	managers.player:add_special({name = "c4"})
	return true
end
VeilInteractionExt = VeilInteractionExt or class(UseInteractionExt)
function VeilInteractionExt:_interact_blocked(player)
	return not managers.player:can_pickup_equipment("blood_sample")
end
function VeilInteractionExt:interact(player)
	VeilInteractionExt.super.super.interact(self, player)
	managers.player:add_special({
		name = "blood_sample"
	})
	return true
end
VeilTakeInteractionExt = VeilTakeInteractionExt or class(UseInteractionExt)
function VeilTakeInteractionExt:_interact_blocked(player)
	return not managers.player:can_pickup_equipment("blood_sample_verified")
end
function VeilTakeInteractionExt:interact(player)
	VeilTakeInteractionExt.super.interact(self, player)
	managers.player:add_special({
		name = "blood_sample_verified"
	})
	if self._unit:damage():has_sequence("got_blood_sample") then
		self._unit:damage():run_sequence_simple("got_blood_sample")
	end
	return true
end
function VeilTakeInteractionExt:sync_interacted()
	if self._unit:damage():has_sequence("got_blood_sample") then
		self._unit:damage():run_sequence_simple("got_blood_sample")
	end
	VeilTakeInteractionExt.super.sync_interacted(self)
end
MoneyWrapInteractionExt = MoneyWrapInteractionExt or class(UseInteractionExt)
function MoneyWrapInteractionExt:interact(player)
	MoneyWrapInteractionExt.super.super.interact(self, player)
	self._unit:base():take_money(player)
end
DiamondInteractionExt = DiamondInteractionExt or class(UseInteractionExt)
function DiamondInteractionExt:interact(player)
	DiamondInteractionExt.super.interact(self, player)
	self._unit:base():take_money(player)
end
IntimitateInteractionExt = IntimitateInteractionExt or class(BaseInteractionExt)
function IntimitateInteractionExt:init(unit, ...)
	IntimitateInteractionExt.super.init(self, unit, ...)
end
function IntimitateInteractionExt:unselect()
	UseInteractionExt.super.unselect(self)
	managers.hud:remove_interact()
end
function IntimitateInteractionExt:interact(player)
	if not self:can_interact(player) then
		return
	end
	local has_equipment = managers.player:has_special_equipment(self._tweak_data.special_equipment)
	if self._tweak_data.equipment_consume and has_equipment then
		managers.player:remove_special(self._tweak_data.special_equipment)
	end
	if self._tweak_data.sound_event then
		player:sound():play(self._tweak_data.sound_event)
	end
	self:remove_interact()
	if self._unit:damage() and self._unit:damage():has_sequence("interact") then
		self._unit:damage():run_sequence_simple("interact")
	end
	self:set_active(false)
	if self._tweak_data.dont_need_equipment and not has_equipment then
		self._unit:brain():on_tied(player, true)
	elseif self.tweak_data == "hostage_trade" then
		self._unit:brain():on_trade(player)
		managers.challenges:set_flag("diplomatic")
		managers.statistics:trade({
			name = self._unit:base()._tweak_table
		})
	else
		player:sound():play("cable_tie_apply")
		self._unit:brain():on_tied(player)
	end
end
NPCInteractionExt = NPCInteractionExt or class(BaseInteractionExt)
function NPCInteractionExt:init(unit)
	BaseInteractionExt.init(self, unit)
	self._ws = World:newgui():create_world_workspace(150, 100, unit:position() + Vector3(-25, 0, 250), Vector3(50, 0, 0), Vector3(0, 0, -50))
	self._ws:set_billboard(self._ws.BILLBOARD_Y)
	self._panel = self._ws:panel()
	self._bg = self._panel:rect({
		name = "bg",
		x = 0,
		y = 0,
		w = 150,
		h = 100,
		color = Color.yellow
	})
	self._text = self._panel:text({
		name = "text",
		text = self:_default_text(),
		align = "center",
		vertical = "center",
		font = "fonts/font_fortress_22",
		font_size = 60,
		color = Color.black,
		layer = 2
	})
	self._toggle = false
	self._panel:hide()
end
function NPCInteractionExt:destroy()
	if alive(self._ws) then
		World:newgui():destroy_workspace(self._ws)
	end
end
function NPCInteractionExt:update(distance_to_player)
	local t = 1 - math.clamp((distance_to_player - tweak_data.interaction.INTERACT_DISTANCE) / (tweak_data.interaction.CULLING_DISTANCE - tweak_data.interaction.INTERACT_DISTANCE), 0, 1)
	if t <= 0 and self._panel:visible() then
		self._panel:hide()
	end
	if not self._panel:visible() then
		self._panel:show()
	end
	self._bg:set_color(self._bg:color():with_alpha(t))
	self._text:set_color(self._text:color():with_alpha(t))
end
function NPCInteractionExt:selected(player)
	self:_set_color(true)
	if managers.player:current_state() ~= "dialog" and managers.player:current_state() ~= "minigame" then
		managers.player:set_player_state("adventure")
	end
end
function NPCInteractionExt:unselect()
	self:_set_color(false)
	managers.player:set_player_state(managers.player:default_player_state())
end
function NPCInteractionExt:interact(player)
	self._unit:set_rotation(Rotation(self._unit:position() - player:position():with_z(0):normalized(), Vector3(0, 0, 1)))
	self._text:set_text(":)")
	self:_do_interact()
end
function NPCInteractionExt:_set_color(set)
	if set == self._toggle then
		return
	end
	self._toggle = set
	self._bg:set_color(self._toggle and Color.green or Color.yellow)
	self._text:set_text(self._toggle and "!" or self:_default_text())
end
NPCDialogInteractionExt = NPCDialogInteractionExt or class(NPCInteractionExt)
function NPCDialogInteractionExt:_default_text()
	return "Talk"
end
function NPCDialogInteractionExt:_do_interact()
	managers.player:set_player_state("dialog")
end
NPCMinigameInteractionExt = NPCMinigameInteractionExt or class(NPCInteractionExt)
function NPCMinigameInteractionExt:_default_text()
	return "Game"
end
function NPCMinigameInteractionExt:_do_interact()
	managers.player:set_player_state("minigame")
end
BoxInteractionExt = BoxInteractionExt or class(BaseInteractionExt)
function BoxInteractionExt:init(unit)
	BaseInteractionExt.init(self, unit)
end
function BoxInteractionExt:interact(player)
	self._unit:push(10, Vector3(0, 0, 1) * 1000)
end
MimicInteractionExt = MimicInteractionExt or class(BaseInteractionExt)
function MimicInteractionExt:init(unit)
	BaseInteractionExt.init(self, unit)
end
function MimicInteractionExt:destroy()
end
function MimicInteractionExt:selected(player)
	if managers.player:current_state() ~= "mimic" and managers.player:current_state() ~= "mimic_interaction" then
		managers.player:set_player_state("mimic_interaction")
		self._unit:mimic():set_mimic("interaction")
	end
end
function MimicInteractionExt:unselect()
	if managers.player:current_state() ~= "mimic" then
		managers.player:set_player_state(managers.player:default_player_state())
	end
end
function MimicInteractionExt:interact(player)
	self._unit:mimic():activate_mimic("interaction")
	self._unit:mimic():add_player_to_mimic(managers.player:player_unit())
	managers.player:set_player_state("mimic")
end
