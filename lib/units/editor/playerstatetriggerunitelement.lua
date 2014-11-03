PlayerStateTriggerUnitElement = PlayerStateTriggerUnitElement or class(MissionElement)
function PlayerStateTriggerUnitElement:init(unit)
	PlayerStateTriggerUnitElement.super.init(self, unit)
	self._hed.trigger_times = 1
	self._hed.state = managers.player:default_player_state()
	table.insert(self._save_values, "state")
end
function PlayerStateTriggerUnitElement:_build_panel(panel, panel_sizer)
	self:_create_panel()
	panel = panel or self._panel
	panel_sizer = panel_sizer or self._panel_sizer
	local states_params = {
		name = "State:",
		panel = panel,
		sizer = panel_sizer,
		options = managers.player:player_states(),
		value = self._hed.state,
		tooltip = "Select a state from the combobox",
		name_proportions = 1,
		ctrlr_proportions = 2,
		sorted = true
	}
	local states = CoreEWS.combobox(states_params)
	states:connect("EVT_COMMAND_COMBOBOX_SELECTED", callback(self, self, "set_element_data"), {ctrlr = states, value = "state"})
	local help = {}
	help.text = "Set the player state the element should trigger on."
	help.panel = panel
	help.sizer = panel_sizer
	self:add_help_text(help)
end
