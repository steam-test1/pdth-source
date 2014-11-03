core:import("CoreLocalizationManager")
core:import("CoreClass")
LocalizationManager = LocalizationManager or class(CoreLocalizationManager.LocalizationManager)
function LocalizationManager:init()
	LocalizationManager.super.init(self)
	self:_setup_macros()
	Application:set_default_letter(95)
end
function LocalizationManager:_setup_macros()
	local btn_a = utf8.char(57344)
	local btn_b = utf8.char(57345)
	local btn_x = utf8.char(57346)
	local btn_y = utf8.char(57347)
	local btn_back = utf8.char(57348)
	local btn_start = utf8.char(57349)
	local stick_l = utf8.char(57350)
	local stick_r = utf8.char(57351)
	local btn_top_l = utf8.char(57352)
	local btn_top_r = utf8.char(57353)
	local btn_bottom_l = utf8.char(57354)
	local btn_bottom_r = utf8.char(57355)
	local btn_stick_l = utf8.char(57356)
	local btn_stick_r = utf8.char(57357)
	local btn_accept = btn_a
	local btn_cancel = btn_b
	local btn_attack = btn_a
	local btn_block = btn_b
	local btn_interact = btn_bottom_r
	local btn_use_item = btn_bottom_l
	local btn_primary = btn_top_r
	local btn_secondary = btn_top_l
	local btn_reload = btn_x
	local swap_accept = false
	if SystemInfo:platform() == Idstring("PS3") and PS3:pad_cross_circle_inverted() then
		swap_accept = true
	end
	if swap_accept then
		btn_accept = btn_b
		btn_cancel = btn_a
	end
	if SystemInfo:platform() ~= Idstring("PS3") then
		btn_stick_r = stick_r
		btn_stick_l = stick_l
	end
	self:set_default_macro("BTN_BACK", btn_back)
	self:set_default_macro("BTN_START", btn_start)
	self:set_default_macro("BTN_A", btn_a)
	self:set_default_macro("BTN_B", btn_b)
	self:set_default_macro("BTN_X", btn_x)
	self:set_default_macro("BTN_Y", btn_y)
	self:set_default_macro("BTN_TOP_L", btn_top_l)
	self:set_default_macro("BTN_TOP_R", btn_top_r)
	self:set_default_macro("BTN_BOTTOM_L", btn_bottom_l)
	self:set_default_macro("BTN_BOTTOM_R", btn_bottom_r)
	self:set_default_macro("BTN_STICK_L", btn_stick_l)
	self:set_default_macro("BTN_STICK_R", btn_stick_r)
	self:set_default_macro("STICK_L", stick_l)
	self:set_default_macro("STICK_R", stick_r)
	self:set_default_macro("BTN_INTERACT", btn_interact)
	self:set_default_macro("BTN_USE_ITEM", btn_use_item)
	self:set_default_macro("BTN_PRIMARY", btn_primary)
	self:set_default_macro("BTN_SECONDARY", btn_secondary)
	self:set_default_macro("BTN_RELOAD", btn_reload)
	self:set_default_macro("BTN_ACCEPT", btn_accept)
	self:set_default_macro("BTN_CANCEL", btn_cancel)
	self:set_default_macro("BTN_ATTACK", btn_attack)
	self:set_default_macro("BTN_BLOCK", btn_block)
end
local is_PS3 = SystemInfo:platform() == Idstring("PS3")
function LocalizationManager:btn_macro(button)
	if is_PS3 then
		return
	end
	local type = managers.controller:get_default_wrapper_type()
	local text = "[" .. managers.controller:get_settings(type):get_connection(button):get_input_name_list()[1] .. "]"
	return text
end
function LocalizationManager:ids(file)
	return Localizer:ids(Idstring(file))
end
CoreClass.override_class(CoreLocalizationManager.LocalizationManager, LocalizationManager)
