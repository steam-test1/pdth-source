local ids_lod = Idstring("lod")
local ids_lod1 = Idstring("lod1")
local ids_ik_aim = Idstring("ik_aim")
CopBase = CopBase or class(UnitBase)
CopBase._anim_lods = {
	{
		2,
		500,
		100,
		5000
	},
	{
		2,
		0,
		100,
		1
	},
	{
		3,
		0,
		100,
		1
	}
}
local material_translation_map = {
	[tostring(Idstring("units/characters/enemies/police_force"):key())] = "units/characters/enemies/police_force_contour",
	[tostring(Idstring("units/characters/enemies/police_force_contour"):key())] = "units/characters/enemies/police_force",
	[tostring(Idstring("units/characters/enemies/gangster"):key())] = "units/characters/enemies/gangster_contour",
	[tostring(Idstring("units/characters/enemies/gangster_contour"):key())] = "units/characters/enemies/gangster",
	[tostring(Idstring("units/characters/civilians/casual_male"):key())] = "units/characters/civilians/casual_male_contour",
	[tostring(Idstring("units/characters/civilians/casual_male_contour"):key())] = "units/characters/civilians/casual_male",
	[tostring(Idstring("units/characters/civilians/suit_male"):key())] = "units/characters/civilians/suit_male_contour",
	[tostring(Idstring("units/characters/civilians/suit_male_contour"):key())] = "units/characters/civilians/suit_male",
	[tostring(Idstring("units/characters/civilians/civilians"):key())] = "units/characters/civilians/civilians_contour",
	[tostring(Idstring("units/characters/civilians/civilians_contour"):key())] = "units/characters/civilians/civilians",
	[tostring(Idstring("units/characters/civilians/female"):key())] = "units/characters/civilians/female_contour",
	[tostring(Idstring("units/characters/civilians/female_contour"):key())] = "units/characters/civilians/female",
	[tostring(Idstring("units/characters/civilians/escort_guy"):key())] = "units/characters/civilians/escort_guy_contour",
	[tostring(Idstring("units/characters/civilians/escort_guy_contour"):key())] = "units/characters/civilians/escort_guy",
	[tostring(Idstring("units/characters/civilians/escort_guy_2"):key())] = "units/characters/civilians/escort_guy_2_contour",
	[tostring(Idstring("units/characters/civilians/escort_guy_2_contour"):key())] = "units/characters/civilians/escort_guy_2",
	[tostring(Idstring("units/characters/civilians/escort_guy_3"):key())] = "units/characters/civilians/escort_guy_3_contour",
	[tostring(Idstring("units/characters/civilians/escort_guy_3_contour"):key())] = "units/characters/civilians/escort_guy_3",
	[tostring(Idstring("units/characters/civilians/escort_guy_4"):key())] = "units/characters/civilians/escort_guy_4_contour",
	[tostring(Idstring("units/characters/civilians/escort_guy_4_contour"):key())] = "units/characters/civilians/escort_guy_4",
	[tostring(Idstring("units/characters/civilians/escort_guy_undercover"):key())] = "units/characters/civilians/escort_guy_undercover_contour",
	[tostring(Idstring("units/characters/civilians/escort_guy_undercover_contour"):key())] = "units/characters/civilians/escort_guy_undercover",
	[tostring(Idstring("units/characters/civilians/builder"):key())] = "units/characters/civilians/builder_contour",
	[tostring(Idstring("units/characters/civilians/builder_contour"):key())] = "units/characters/civilians/builder",
	[tostring(Idstring("units/characters/civilians/butcher"):key())] = "units/characters/civilians/butcher_contour",
	[tostring(Idstring("units/characters/civilians/butcher_contour"):key())] = "units/characters/civilians/butcher",
	[tostring(Idstring("units/characters/civilians/prisoner_set"):key())] = "units/characters/civilians/prisoner_set_contour",
	[tostring(Idstring("units/characters/civilians/prisoner_set_contour"):key())] = "units/characters/civilians/prisoner_set",
	[tostring(Idstring("units/characters/civilians/suburbia_females"):key())] = "units/characters/civilians/suburbia_females_contour",
	[tostring(Idstring("units/characters/civilians/suburbia_females_contour"):key())] = "units/characters/civilians/suburbia_females",
	[tostring(Idstring("units/characters/civilians/suburbia_males"):key())] = "units/characters/civilians/suburbia_males_contour",
	[tostring(Idstring("units/characters/civilians/suburbia_males_contour"):key())] = "units/characters/civilians/suburbia_males",
	[tostring(Idstring("units/characters/civilians/hospital_doctor"):key())] = "units/characters/civilians/hospital_doctor_contour",
	[tostring(Idstring("units/characters/civilians/hospital_doctor_contour"):key())] = "units/characters/civilians/hospital_doctor",
	[tostring(Idstring("units/characters/civilians/hospital_bill"):key())] = "units/characters/civilians/hospital_bill_contour",
	[tostring(Idstring("units/characters/civilians/hospital_bill_contour"):key())] = "units/characters/civilians/hospital_bill"
}
function CopBase:init(unit)
	UnitBase.init(self, unit, false)
	self._unit = unit
	self._visibility_state = true
	self._foot_obj_map = {}
	self._foot_obj_map.right = self._unit:get_object(Idstring("RightToeBase"))
	self._foot_obj_map.left = self._unit:get_object(Idstring("LeftToeBase"))
end
function CopBase:post_init()
	self._ext_movement = self._unit:movement()
	self:set_anim_lod(1)
	self._lod_stage = 1
	self._ext_movement:post_init(true)
	self._unit:brain():post_init()
	managers.enemy:register_enemy(self._unit)
	self._allow_invisible = true
end
function CopBase:default_weapon_name()
	local default_weapon_id = self._default_weapon_id
	local weap_ids = tweak_data.character.weap_ids
	for i_weap_id, weap_id in ipairs(weap_ids) do
		if default_weapon_id == weap_id then
			return tweak_data.character.weap_unit_names[i_weap_id]
		end
	end
end
function CopBase:visibility_state()
	return self._visibility_state
end
function CopBase:lod_stage()
	return self._lod_stage
end
function CopBase:set_allow_invisible(allow)
	self._allow_invisible = allow
end
function CopBase:set_visibility_state(stage)
	local state = stage and true
	if not state and not self._allow_invisible then
		state = true
		stage = 1
	end
	if self._lod_stage == stage then
		return
	end
	local inventory = self._unit:inventory()
	local weapon = inventory and inventory.get_weapon and inventory:get_weapon()
	if weapon then
		weapon:base():set_flashlight_light_lod_enabled(stage ~= 2 and not not stage)
	end
	if self._visibility_state ~= state then
		local unit = self._unit
		if inventory then
			inventory:set_visibility_state(state)
		end
		unit:set_visible(state)
		if state or self._unit:anim_data().can_freeze then
			unit:set_animatable_enabled(ids_lod, state)
			unit:set_animatable_enabled(ids_ik_aim, state)
		end
		self._visibility_state = state
	end
	if state then
		self:set_anim_lod(stage)
		self._unit:movement():enable_update(true)
		if stage == 1 then
			self._unit:set_animatable_enabled(ids_lod1, true)
		elseif self._lod_stage == 1 then
			self._unit:set_animatable_enabled(ids_lod1, false)
		end
	end
	self._lod_stage = stage
	self:chk_freeze_anims()
end
function CopBase:set_anim_lod(stage)
	self._unit:set_animation_lod(unpack(self._anim_lods[stage]))
end
function CopBase:on_death_exit()
	self._unit:set_animations_enabled(false)
end
function CopBase:chk_freeze_anims()
	if (not self._lod_stage or self._lod_stage > 1) and self._unit:anim_data().can_freeze then
		if not self._anims_frozen then
			self._anims_frozen = true
			self._unit:set_animations_enabled(false)
			self._ext_movement:on_anim_freeze(true)
		end
	elseif self._anims_frozen then
		self._anims_frozen = nil
		self._unit:set_animations_enabled(true)
		self._ext_movement:on_anim_freeze(false)
	end
end
function CopBase:anim_act_clbk(unit, anim_act, nav_link)
	if nav_link then
		unit:movement():on_anim_act_clbk(anim_act)
	elseif unit:unit_data().mission_element then
		unit:unit_data().mission_element:event(anim_act, unit)
	end
end
function CopBase:save(data)
	if self._contour_state then
		data.base_contour_on = true
	end
	if self._unit:interaction() and self._unit:interaction().tweak_data == "hostage_trade" then
		data.is_hostage_trade = true
	end
end
function CopBase:load(data)
	if data.base_contour_on then
		self._contour_on_clbk_id = "clbk_set_contour_on" .. tostring(self._unit:key())
		managers.enemy:add_delayed_clbk(self._contour_on_clbk_id, callback(self, self, "clbk_set_contour_on"), TimerManager:game():time() + 1)
	end
	if data.is_hostage_trade then
		CopLogicTrade.hostage_trade(self._unit, true)
	end
end
function CopBase:clbk_set_contour_on(data)
	if not self._contour_on_clbk_id or not alive(self._unit) then
		return
	end
	self._contour_on_clbk_id = nil
	self:set_contour(self._unit, true)
end
local ids_materials = Idstring("material")
local ids_contour_color = Idstring("contour_color")
local ids_contour_opacity = Idstring("contour_opacity")
function CopBase:set_contour(state)
	if not alive(self._unit) then
		return
	end
	if (self._contour_state or false) == (state or false) then
		return
	end
	if Network:is_server() then
		self._unit:network():send("set_contour", state)
	end
	if not self._unit:interaction() then
		return
	end
	local opacity
	if state then
		self:swap_material_config()
		managers.occlusion:remove_occlusion(self._unit)
		self._unit:interaction():set_tweak_data(self._unit:interaction().orig_tweak_data_contour or "intimidate_with_contour")
		self._unit:base():set_allow_invisible(false)
		self:set_visibility_state(1)
		opacity = 1
	else
		self:swap_material_config()
		managers.occlusion:add_occlusion(self._unit)
		self._unit:interaction():set_tweak_data(self._unit:interaction().orig_tweak_data or "intimidate")
		self._unit:base():set_allow_invisible(true)
		opacity = 0
	end
	local materials = self._unit:get_objects_by_type(ids_materials)
	for _, m in ipairs(materials) do
		m:set_variable(ids_contour_color, tweak_data.contour.interactable.standard_color)
		m:set_variable(ids_contour_opacity, opacity)
	end
	self._contour_state = state
end
function CopBase:swap_material_config()
	local new_material = material_translation_map[tostring(self._unit:material_config():key())]
	if new_material then
		self._unit:set_material_config(Idstring(new_material), true)
		if self._unit:interaction() then
			self._unit:interaction():refresh_material()
		end
	else
		print("[CopBase:swap_material_config] fail", self._unit:material_config(), self._unit)
		Application:stack_dump()
	end
end
function CopBase:pre_destroy(unit)
	if unit:unit_data().secret_assignment_id and alive(unit) then
		managers.secret_assignment:unregister_unit(unit)
	end
	if self._contour_on_clbk_id then
		managers.enemy:remove_delayed_clbk(self._contour_on_clbk_id)
	end
	unit:brain():pre_destroy(unit)
	self._ext_movement:pre_destroy()
	UnitBase.pre_destroy(self, unit)
end
