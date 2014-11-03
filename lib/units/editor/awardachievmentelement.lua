AwardAchievmentElement = AwardAchievmentElement or class(MissionElement)
function AwardAchievmentElement:init(unit)
	AwardAchievmentElement.super.init(self, unit)
	self._hed.achievment = nil
	table.insert(self._save_values, "achievment")
end
function AwardAchievmentElement:_build_panel(panel, panel_sizer)
	self:_create_panel()
	panel = panel or self._panel
	panel_sizer = panel_sizer or self._panel_sizer
	local achievment_list = {}
	for ach, _ in pairs(managers.achievment.achievments) do
		table.insert(achievment_list, ach)
	end
	local achievment_params = {
		name = "Achievment:",
		panel = panel,
		sizer = panel_sizer,
		options = achievment_list,
		default = "none",
		value = self._hed.achievment,
		tooltip = "Select an achievment to award",
		name_proportions = 1,
		ctrlr_proportions = 2,
		sorted = true
	}
	local achievments = CoreEWS.combobox(achievment_params)
	achievments:connect("EVT_COMMAND_COMBOBOX_SELECTED", callback(self, self, "set_element_data"), {ctrlr = achievments, value = "achievment"})
	local help = {}
	help.text = "Awards a PSN Trophy or Steam Achievment"
	help.panel = panel
	help.sizer = panel_sizer
	self:add_help_text(help)
end
