DifficultyLevelCheckElement = DifficultyLevelCheckElement or class(MissionElement)
function DifficultyLevelCheckElement:init(unit)
	DifficultyLevelCheckElement.super.init(self, unit)
	self._hed.difficulty = "easy"
	table.insert(self._save_values, "difficulty")
end
function DifficultyLevelCheckElement:_build_panel(panel, panel_sizer)
	self:_create_panel()
	panel = panel or self._panel
	panel_sizer = panel_sizer or self._panel_sizer
	local difficulty_params = {
		name = "Difficulty:",
		panel = panel,
		sizer = panel_sizer,
		default = "easy",
		options = {
			"normal",
			"hard",
			"overkill"
		},
		value = self._hed.difficulty,
		tooltip = "Select a difficulty",
		name_proportions = 1,
		ctrlr_proportions = 2,
		sorted = false
	}
	local difficulty = CoreEWS.combobox(difficulty_params)
	difficulty:connect("EVT_COMMAND_COMBOBOX_SELECTED", callback(self, self, "set_element_data"), {ctrlr = difficulty, value = "difficulty"})
	local help = {}
	help.text = "The element will only execute if the difficulty level is set to what you pick."
	help.panel = panel
	help.sizer = panel_sizer
	self:add_help_text(help)
end
