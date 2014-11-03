AlertTriggerElement = AlertTriggerElement or class(MissionElement)
function AlertTriggerElement:init(unit)
	AlertTriggerElement.super.init(self, unit)
end
function AlertTriggerElement:_build_panel(panel, panel_sizer)
	self:_create_panel()
	panel = panel or self._panel
	local help = {}
	help.text = "Get executed if alerted."
	help.panel = panel
	help.sizer = panel_sizer
	self:add_help_text(help)
end
