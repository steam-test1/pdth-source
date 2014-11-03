SpawnCivilianUnitElement = SpawnCivilianUnitElement or class(MissionElement)
function SpawnCivilianUnitElement:init(unit)
	SpawnCivilianUnitElement.super.init(self, unit)
	self._enemies = {}
	self._states = CopActionAct._civilian_actions
	self._options = {
		"units/characters/enemies/pilot/pilot",
		"units/characters/bank_manager/bank_manager_old_man",
		"units/characters/bank_manager/bank_manager2",
		"units/characters/civilians/suit_male_1/suit_male_1",
		"units/characters/civilians/suit_male_2/suit_male_2",
		"units/characters/civilians/suit_male_3/suit_male_3",
		"units/characters/civilians/suit_male_4/suit_male_4",
		"units/characters/civilians/suit_male_5/suit_male_5",
		"units/characters/civilians/suit_female_1/suit_female_1",
		"units/characters/civilians/suit_female_2/suit_female_2",
		"units/characters/civilians/suit_female_3/suit_female_3",
		"units/characters/civilians/casual_female_1/casual_female_1",
		"units/characters/civilians/casual_female_2/casual_female_2",
		"units/characters/civilians/casual_female_3/casual_female_3",
		"units/characters/civilians/casual_male_1/casual_male_1",
		"units/characters/civilians/casual_male_2/casual_male_2",
		"units/characters/civilians/casual_male_3/casual_male_3",
		"units/characters/civilians/casual_male_4/casual_male_4",
		"units/characters/civilians/casual_male_5/casual_male_5",
		"units/characters/civilians/casual_male_6/casual_male_6",
		"units/characters/civilians/casual_male_7/casual_male_7",
		"units/characters/civilians/escort_guy_1/escort_guy_1",
		"units/characters/civilians/escort_guy_2/escort_guy_2",
		"units/characters/civilians/escort_guy_3/escort_guy_3",
		"units/characters/civilians/escort_guy_4/escort_guy_4",
		"units/characters/civilians/escort_guy_5/escort_guy_5",
		"units/characters/civilians/escort_guy_undercover/escort_guy_undercover",
		"units/characters/civilians/escort_guy_undercover/escort_guy_undercover_civ",
		"units/characters/civilians/chavez/chavez",
		"units/characters/driver/driver",
		"units/characters/civilians/serversynced_civilian_male/serversynced_civilian_male",
		"units/characters/civilians/prisoner_1/prisoner_1",
		"units/characters/civilians/prisoner_2/prisoner_2",
		"units/characters/civilians/prisoner_3/prisoner_3",
		"units/characters/civilians/butcher_1/butcher_1",
		"units/characters/civilians/butcher_2/butcher_2",
		"units/characters/civilians/butcher_3/butcher_3",
		"units/characters/civilians/builder_1/builder_1",
		"units/characters/civilians/builder_2/builder_2",
		"units/characters/civilians/builder_3/builder_3",
		"units/characters/civilians/suburbia_male1/suburbia_male1",
		"units/characters/civilians/suburbia_male2/suburbia_male2",
		"units/characters/civilians/suburbia_male3/suburbia_male3",
		"units/characters/civilians/suburbia_male4/suburbia_male4",
		"units/characters/civilians/suburbia_female1/suburbia_female1",
		"units/characters/civilians/suburbia_female2/suburbia_female2",
		"units/characters/civilians/suburbia_female3/suburbia_female3",
		"units/characters/civilians/suburbia_female4/suburbia_female4",
		"units/characters/civilians/hospital_doctor1/hospital_doctor1",
		"units/characters/civilians/hospital_doctor2/hospital_doctor2",
		"units/characters/civilians/hospital_doctor3/hospital_doctor3",
		"units/characters/civilians/hospital_male_nurse1/hospital_male_nurse1",
		"units/characters/civilians/hospital_male_nurse2/hospital_male_nurse2",
		"units/characters/civilians/hospital_male_nurse3/hospital_male_nurse3",
		"units/characters/civilians/hospital_female_nurse1/hospital_female_nurse1",
		"units/characters/civilians/hospital_female_nurse2/hospital_female_nurse2",
		"units/characters/civilians/hospital_female_nurse3/hospital_female_nurse3",
		"units/characters/civilians/hospital_female_nurse4/hospital_female_nurse4",
		"units/characters/civilians/hospital_female_nurse5/hospital_female_nurse5",
		"units/characters/civilians/hospital_female_nurse6/hospital_female_nurse6",
		"units/characters/civilians/hospital_female1/hospital_female1",
		"units/characters/civilians/hospital_female2/hospital_female2",
		"units/characters/civilians/hospital_female3/hospital_female3",
		"units/characters/civilians/hospital_female4/hospital_female4",
		"units/characters/civilians/hospital_bill/hospital_bill"
	}
	self._hed.state = "none"
	self._hed.enemy = "units/characters/civilians/bank_client_1/bank_client_1"
	self._hed.force_pickup = "none"
	table.insert(self._save_values, "enemy")
	table.insert(self._save_values, "state")
	table.insert(self._save_values, "force_pickup")
end
function SpawnCivilianUnitElement:test_element()
	SpawnEnemyUnitElement.test_element(self)
end
function SpawnCivilianUnitElement:stop_test_element()
	for _, enemy in ipairs(self._enemies) do
		if enemy:base() and enemy:base().set_slot then
			enemy:base():set_slot(enemy, 0)
		else
			enemy:set_slot(0)
		end
	end
	self._enemies = {}
end
function SpawnCivilianUnitElement:select_civilian_btn()
	local dialog = SelectNameModal:new("Select unit", self._options)
	if dialog:cancelled() then
		return
	end
	for _, unit in ipairs(dialog:_selected_item_assets()) do
		self._hed.enemy = unit
		CoreEws.change_combobox_value(self._enemies_params, self._hed.enemy)
	end
end
function SpawnCivilianUnitElement:select_state_btn()
	local dialog = SelectNameModal:new("Select state", self._states)
	if dialog:cancelled() then
		return
	end
	for _, state in ipairs(dialog:_selected_item_assets()) do
		self._hed.state = state
		CoreEws.change_combobox_value(self._states_params, self._hed.state)
	end
end
function SpawnCivilianUnitElement:_build_panel(panel, panel_sizer)
	self:_create_panel()
	panel = panel or self._panel
	panel_sizer = panel_sizer or self._panel_sizer
	local enemy_sizer = EWS:BoxSizer("HORIZONTAL")
	panel_sizer:add(enemy_sizer, 0, 1, "EXPAND,LEFT")
	local enemies_params = {
		name = "Enemy:",
		panel = panel,
		sizer = enemy_sizer,
		options = self._options,
		value = self._hed.enemy,
		tooltip = "Select an enemy from the combobox",
		name_proportions = 1,
		ctrlr_proportions = 2,
		sizer_proportions = 1,
		sorted = true
	}
	local enemies = CoreEWS.combobox(enemies_params)
	enemies:connect("EVT_COMMAND_COMBOBOX_SELECTED", callback(self, self, "set_element_data"), {ctrlr = enemies, value = "enemy"})
	self._enemies_params = enemies_params
	local toolbar = EWS:ToolBar(panel, "", "TB_FLAT,TB_NODIVIDER")
	toolbar:add_tool("SELECT", "Select unit", CoreEws.image_path("world_editor\\unit_by_name_list.png"), nil)
	toolbar:connect("SELECT", "EVT_COMMAND_MENU_SELECTED", callback(self, self, "select_civilian_btn"), nil)
	toolbar:realize()
	enemy_sizer:add(toolbar, 0, 1, "EXPAND,LEFT")
	local state_sizer = EWS:BoxSizer("HORIZONTAL")
	panel_sizer:add(state_sizer, 0, 1, "EXPAND,LEFT")
	local states_params = {
		name = "State:",
		panel = panel,
		sizer = state_sizer,
		options = self._states,
		value = self._hed.state,
		default = "none",
		tooltip = "Select a state from the combobox",
		name_proportions = 1,
		ctrlr_proportions = 2,
		sizer_proportions = 1,
		sorted = true
	}
	local states = CoreEWS.combobox(states_params)
	states:connect("EVT_COMMAND_COMBOBOX_SELECTED", callback(self, self, "set_element_data"), {ctrlr = states, value = "state"})
	self._states_params = states_params
	local toolbar = EWS:ToolBar(panel, "", "TB_FLAT,TB_NODIVIDER")
	toolbar:add_tool("SELECT", "Select state", CoreEws.image_path("world_editor\\unit_by_name_list.png"), nil)
	toolbar:connect("SELECT", "EVT_COMMAND_MENU_SELECTED", callback(self, self, "select_state_btn"), nil)
	toolbar:realize()
	state_sizer:add(toolbar, 0, 1, "EXPAND,LEFT")
	local pickups = {}
	for name, _ in pairs(tweak_data.pickups) do
		table.insert(pickups, name)
	end
	local pickup_params = {
		name = "Force Pickup:",
		panel = panel,
		sizer = panel_sizer,
		options = pickups,
		value = self._hed.force_pickup,
		default = "none",
		tooltip = "Select a pickup to be forced spawned when characters from this element dies.",
		name_proportions = 1,
		ctrlr_proportions = 2,
		sorted = true
	}
	local force_pickup = CoreEWS.combobox(pickup_params)
	force_pickup:connect("EVT_COMMAND_COMBOBOX_SELECTED", callback(self, self, "set_element_data"), {
		ctrlr = force_pickup,
		value = "force_pickup"
	})
end
function SpawnCivilianUnitElement:add_to_mission_package()
end
