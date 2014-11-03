require("core/lib/utils/dev/tools/material_editor/CoreSmartNode")
local CoreMaterialEditorParameter = require("core/lib/utils/dev/tools/material_editor/parameter_widgets/CoreMaterialEditorParameter")
local CoreMaterialEditorTexture = CoreMaterialEditorTexture or class(CoreMaterialEditorParameter)
function CoreMaterialEditorTexture:init(parent, editor, parameter_info, parameter_node)
	CoreMaterialEditorParameter.init(self, parent, editor, parameter_info, parameter_node)
	local text = self._global_texture and "environment_cubemap (Global)" or self._value
	self._text = EWS:StaticText(self._right_panel, text, "", "")
	self._text:set_font_family("FONTFAMILY_TELETYPE")
	self._text:set_font_weight("FONTWEIGHT_BOLD")
	self._right_box:add(self._text, 1, 4, "ALL,EXPAND")
	self._button = EWS:Button(self._right_panel, "Browse", "", "NO_BORDER")
	self._button:connect("", "EVT_COMMAND_BUTTON_CLICKED", self._on_browse, self)
	self._right_box:add(self._button, 0, 4, "ALL")
end
function CoreMaterialEditorTexture:update(t, dt)
end
function CoreMaterialEditorTexture:destroy()
	CoreMaterialEditorParameter.destroy(self)
end
function CoreMaterialEditorTexture:on_toggle_customize()
	self._customize = not self._customize
	self:_load_value()
	self._editor:_update_output()
	self._right_panel:set_enabled(self._customize)
	self._text:set_value(self._value)
	if self._customize then
		self:_on_browse()
	end
end
function CoreMaterialEditorTexture:on_open_texture()
	local str = os.getenv("MATEDOPEN")
	local s, e = string.find(str, "$FILE")
	if s and e then
		local first_part = string.sub(str, 1, s - 1)
		local last_part = string.sub(str, e + 1)
		if DB:has("texture", self._value) then
			str = "start " .. first_part .. "\"" .. Application:nice_path(managers.database:base_path() .. self._value .. ".dds\"", false) .. last_part
			os.execute(str)
		else
			EWS:MessageDialog(self._editor._main_frame, "Could not find texture entry: " .. self._value, "Open Texture", "OK,ICON_ERROR"):show_modal()
		end
	end
end
function CoreMaterialEditorTexture:on_pick_global_texture()
	local dialog = EWS:SingleChoiceDialog(self._editor._main_frame, "Pick a global texture.", "Global Textures", {
		"environment_cubemap"
	}, "")
	dialog:show_modal()
	local str = dialog:get_string_selection()
	if str ~= "" then
		self._value = "current_global_texture"
		self._global_texture = true
		self._global_texture_type = "cube"
		self._node:clear_parameter("file")
		self._node:set_parameter("global_texture", self._value)
		self._node:set_parameter("type", self._global_texture_type)
		self._text:set_value("environment_cubemap (Global)")
		self._editor:_update_output()
		self:update_live()
	end
end
function CoreMaterialEditorTexture:_on_browse()
	local node, path = managers.database:load_node_dialog(self._right_panel, "Textures (*.dds)|*.dds")
	if path then
		self._global_texture = false
		self._value = managers.database:entry_path(path)
		self._node:clear_parameter("global_texture")
		self._node:clear_parameter("type")
		self._node:set_parameter("file", self._value)
		if self._parameter_info.name:s() == "reflection_texture" then
			self._node:set_parameter("type", "cubemap")
		end
		self._text:set_value(self._value)
		self._editor:_update_output()
		self:update_live()
	end
end
return CoreMaterialEditorTexture
