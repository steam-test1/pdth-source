core:module("CoreLocalizationManager")
core:import("CoreClass")
core:import("CoreEvent")
LocalizationManager = LocalizationManager or CoreClass.class()
function LocalizationManager:init()
	Localizer:set_post_processor(CoreEvent.callback(self, self, "_localizer_post_process"))
	self._default_macros = {}
	self:set_default_macro("NL", "\n")
	self:set_default_macro("EMPTY", "")
	local platform_id = SystemInfo:platform()
	if platform_id == Idstring("X360") then
		self._platform = "X360"
	elseif platform_id == Idstring("PS3") then
		self._platform = "PS3"
	else
		self._platform = "WIN32"
	end
end
function LocalizationManager:add_default_macro(macro, value)
	self:set_default_macro(macro, value)
end
function LocalizationManager:set_default_macro(macro, value)
	if not self._default_macros then
		self._default_macros = {}
	end
	self._default_macros["$" .. macro .. ";"] = tostring(value)
end
function LocalizationManager:exists(string_id)
	return Localizer:exists(Idstring(string_id))
end
function LocalizationManager:text(string_id, macros)
	local return_string = "ERROR: " .. string_id
	local str_id
	if not string_id or string_id == "" then
		return_string = ""
	elseif self:exists(string_id .. "_" .. self._platform) then
		str_id = string_id .. "_" .. self._platform
	elseif self:exists(string_id) then
		str_id = string_id
	end
	if str_id then
		self._macro_context = macros
		return_string = Localizer:lookup(Idstring(str_id))
		self._macro_context = nil
	end
	return return_string
end
function LocalizationManager:_localizer_post_process(string)
	local localized_string = string
	local macros = {}
	if type(self._macro_context) ~= "table" then
		self._macro_context = {}
	end
	for k, v in pairs(self._default_macros) do
		macros[k] = v
	end
	for k, v in pairs(self._macro_context) do
		macros["$" .. k .. ";"] = tostring(v)
	end
	if self._pre_process_func then
		self._pre_process_func(macros)
	end
	localized_string = string.gsub(localized_string, "%b$;", macros)
	return localized_string
end
