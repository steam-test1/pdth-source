core:import("CoreClass")
core:import("CoreEvent")
core:import("CoreEws")
core:import("CoreColorPickerPanel")
require("core/lib/utils/dev/tools/CoreEnvEditorTabs")
require("core/lib/utils/dev/tools/CoreEnvEditorDialogs")
require("core/lib/utils/dev/tools/CoreEnvEditorFormulas")
require("core/lib/utils/dev/tools/CoreEnvEditorShadowTab")
CoreEnvEditor = CoreEnvEditor or class()
CoreEnvEditor.TEMPLATE_IDENTIFIER = "template"
CoreEnvEditor.MIX_MUL = 200
CoreEnvEditor.REMOVE_DEPRECATED_DURING_LOAD = true
function CoreEnvEditor:init(env_file_name)
	self._env_path = assert(managers.viewport:first_active_viewport():environment_mixer():current_environment()) or "core/environments/default"
	self._env_name = self._env_path
	self:read_mode()
	self:create_main_frame()
	self._value_is_changed = true
	self._undo_index = 0
	self._undo = {}
	self._template_environment_names = {}
	self._template_effects = {}
	self._template_underlays = {}
	self._template_skies = {}
	self._mixer_widgets = {}
	self._updators = {}
	self._tabs = {}
	self._posteffect = {}
	self._underlayeffect = {}
	self._sky = {}
	if self._simple_mode then
		self:read_templates()
		self:create_tab("Global Illumination")
		self:create_tab("Post Processor")
		self:create_tab("Skydome")
		self:create_tab("Flare")
		self:create_simple_interface()
		self:build_tab("Global Illumination")
		self:build_tab("Post Processor")
		self:build_tab("Skydome")
		self:build_tab("Flare")
	else
		self:create_tab("Global Illumination")
		self:create_tab("Post Processor")
		self:create_tab("Skydome")
		self:create_tab("Flare")
		self:create_interface()
		self:build_tab("Global Illumination")
		self:build_tab("Post Processor")
		self:build_tab("Skydome")
		self:build_tab("Flare")
	end
	self._skies_to_remove = {}
	self._posteffects_to_remove = {}
	self._underlays_to_remove = {}
	self._environments_to_remove = {}
	self:init_shadow_tab()
	self._debug_draw = Global.render_debug.draw_enabled
	Global.render_debug.draw_enabled = true
	self._prev_environment = self._env_path
	self:database_load_env(self._env_path)
	managers.viewport:first_active_viewport():editor_callback(function(data)
		self:feed(data)
	end)
	managers.viewport:first_active_viewport():reset_network_cache()
	self:check_news(true)
end
function CoreEnvEditor:read_mode()
end
function CoreEnvEditor:read_templates()
	for _, name in ipairs(managers.database:list_entries_of_type("environment")) do
		if string.find(name, self.TEMPLATE_IDENTIFIER) then
			table.insert(self._template_environment_names, name)
		end
	end
	table.sort(self._template_environment_names)
	for _, env_name in ipairs(self._template_environment_names) do
		self._template_effects[env_name] = DB:load_node("environment_effect", env_name)
		self._template_underlays[env_name] = DB:load_node("environment_underlay", env_name)
		self._template_skies[env_name] = DB:load_node("environment_sky", env_name)
	end
end
function CoreEnvEditor:on_check_news()
	self:check_news()
end
function CoreEnvEditor:reg_mixer(widget)
	table.insert(self._mixer_widgets, widget)
end
function CoreEnvEditor:update_mix(env1, env2, blend)
	for _, widget in ipairs(self._mixer_widgets) do
		widget:update_mix(env1, env2, blend)
	end
end
function CoreEnvEditor:check_news(new_only)
	local news
	if new_only then
		news = managers.news:get_news("env_editor", self._main_frame)
	else
		news = managers.news:get_old_news("env_editor", self._main_frame)
	end
	if news then
		local str
		for _, n in ipairs(news) do
			if not str then
				str = n
			else
				str = str .. "\n" .. n
			end
		end
		EWS:MessageDialog(self._main_frame, str, "New Features!", "OK,ICON_INFORMATION"):show_modal()
	end
end
function CoreEnvEditor:feed(data)
	for k, v in pairs(data:data_root()) do
		if k == "post_effect" then
			for kpro, vpro in pairs(v) do
				if kpro == "shadow_processor" then
					self:shadow_feed_params(vpro.shadow_rendering.shadow_modifier)
				else
					for keffect, veffect in pairs(vpro) do
						for kmod, vmod in pairs(veffect) do
							for kpar, vpar in pairs(vmod) do
								vmod[kpar] = assert(self._posteffect.post_processors[kpro].modifiers[kmod].params[kpar]:get_value(), kpar)
							end
						end
					end
				end
			end
		elseif k == "underlay_effect" then
			for kmat, vmat in pairs(v) do
				for kpar, vpar in pairs(vmat) do
					vmat[kpar] = assert(self._underlayeffect.materials[kmat].params[kpar]:get_value(), kpar)
				end
			end
		elseif k == "others" then
			for kpar, vpar in pairs(v) do
				if kpar ~= "underlay" or self._sky.params[kpar]:get_value() ~= "" then
					v[kpar] = assert(self._sky.params[kpar]:get_value(), kpar)
				end
			end
		elseif k == "sky_orientation" then
			for kpar, vpar in pairs(v) do
			end
		else
			error("Corrupt environment!")
		end
	end
	managers.viewport:first_active_viewport():feed_params()
	return data
end
function CoreEnvEditor:create_main_frame()
	self._main_frame = EWS:Frame("", Vector3(250, 0, 0), Vector3(450, 800, 0), "FRAME_FLOAT_ON_PARENT,DEFAULT_FRAME_STYLE", Global.frame)
	self:set_title()
	local main_box = EWS:BoxSizer("HORIZONTAL")
	local menu_bar = EWS:MenuBar()
	local file_menu = EWS:Menu("")
	file_menu:append_item("ENVOPEN", "Open...\tCtrl+O", "")
	file_menu:append_item("ENVSAVE", "Save \tCtrl+S", "")
	file_menu:append_item("ENVSAVEAS", "Save As.. \tCtrl+Alt+S", "")
	file_menu:append_separator()
	file_menu:append_item("ENCODE_PARAMETERS", "Encode Parameters", "")
	file_menu:append_separator()
	file_menu:append_item("NEWS", "Get Latest News", "")
	file_menu:append_separator()
	file_menu:append_item("EXIT", "Exit", "")
	menu_bar:append(file_menu, "File")
	local edit_menu = EWS:Menu("")
	edit_menu:append_item("UNDO", "Undo\tCtrl+Z", "")
	edit_menu:append_item("REDO", "Redo\tCtrl+Y", "")
	menu_bar:append(edit_menu, "Edit")
	self._main_frame:set_menu_bar(menu_bar)
	self._main_frame:connect("ENVOPEN", "EVT_COMMAND_MENU_SELECTED", callback(self, self, "on_open_file"), "")
	self._main_frame:connect("ENVSAVE", "EVT_COMMAND_MENU_SELECTED", callback(self, self, "on_save_file"), "")
	self._main_frame:connect("ENVSAVEAS", "EVT_COMMAND_MENU_SELECTED", callback(self, self, "on_save_file_as"), "")
	self._main_frame:connect("ENCODE_PARAMETERS", "EVT_COMMAND_MENU_SELECTED", callback(self, self, "on_encode_parameters"), "")
	self._main_frame:connect("NEWS", "EVT_COMMAND_MENU_SELECTED", callback(self, self, "on_check_news"), "")
	self._main_frame:connect("EXIT", "EVT_COMMAND_MENU_SELECTED", callback(self, self, "on_close"), "")
	self._main_frame:connect("UNDO", "EVT_COMMAND_MENU_SELECTED", callback(self, self, "on_undo"), "")
	self._main_frame:connect("REDO", "EVT_COMMAND_MENU_SELECTED", callback(self, self, "on_redo"), "")
	self._main_frame:connect("", "EVT_CLOSE_WINDOW", callback(self, self, "on_close"), "")
	self._main_notebook = EWS:Notebook(self._main_frame, "", "")
	main_box:add(self._main_notebook, 1, 0, "EXPAND")
	self._connect_dialog = ConnectDialog:new(self._main_frame)
	self._encode_parameters_dialog = EWS:MessageDialog(self._main_frame, "This will encode all parameters to disk. Proceed?", "Encode Parameters", "YES_NO,ICON_QUESTION")
	self._main_frame:set_sizer(main_box)
	self._main_frame:set_visible(true)
end
function CoreEnvEditor:add_post_processors_param(pro, mod, param, gui)
	if not self._posteffect.post_processors then
		self._posteffect.post_processors = {}
	end
	if not self._posteffect.post_processors[pro] then
		self._posteffect.post_processors[pro] = {}
	end
	if not self._posteffect.post_processors[pro].modifiers then
		self._posteffect.post_processors[pro].modifiers = {}
	end
	if not self._posteffect.post_processors[pro].modifiers[mod] then
		self._posteffect.post_processors[pro].modifiers[mod] = {}
	end
	if not self._posteffect.post_processors[pro].modifiers[mod].params then
		self._posteffect.post_processors[pro].modifiers[mod].params = {}
	end
	self._posteffect.post_processors[pro].modifiers[mod].params[param] = gui
	local e = "default"
	if pro == "fog_processor" then
		e = "fog"
	elseif pro == "deferred" then
		e = "deferred_lighting"
	end
	local processor = managers.viewport:first_active_viewport():vp():get_post_processor_effect("World", Idstring(pro))
	if processor then
		local modifier = processor:modifier(Idstring(mod))
		if modifier and modifier:material():variable_exists(Idstring(param)) then
			local value = modifier:material():get_variable(Idstring(param))
			if value then
				gui:set_value(value)
			end
		end
	end
	return gui
end
function CoreEnvEditor:add_underlay_param(mat, param, gui)
	if not self._underlayeffect.materials then
		self._underlayeffect.materials = {}
	end
	if not self._underlayeffect.materials[mat] then
		self._underlayeffect.materials[mat] = {}
	end
	if not self._underlayeffect.materials[mat].params then
		self._underlayeffect.materials[mat].params = {}
	end
	self._underlayeffect.materials[mat].params[param] = gui
	local material = Underlay:material(Idstring(mat))
	if material and material:variable_exists(Idstring(param)) then
		local value = material:get_variable(Idstring(param))
		if value then
			gui:set_value(value)
		end
	end
	return gui
end
function CoreEnvEditor:add_sky_param(param, gui)
	if not self._sky.params then
		self._sky.params = {}
	end
	self._sky.params[param] = gui
	return gui
end
function CoreEnvEditor:retrive_posteffect_param(node, pro, mod, param)
	for post_processor in node:children() do
		if post_processor:parameter("name") == pro then
			for modifier in post_processor:children() do
				if modifier:parameter("name") == mod then
					for parameter in modifier:children() do
						if parameter:parameter("key") == param then
							local p = parameter:parameter("value")
							if math.string_is_good_vector(p) then
								return math.string_to_vector(p)
							elseif tonumber(p) then
								return tonumber(p)
							else
								return p
							end
						end
					end
				end
			end
		end
	end
end
function CoreEnvEditor:retrive_underlay_param(node, mat, param)
	for material in node:children() do
		if material:parameter("name") == mat then
			for parameter in material:children() do
				if parameter:parameter("key") == param then
					local p = parameter:parameter("value")
					if math.string_is_good_vector(p) then
						return math.string_to_vector(p)
					elseif tonumber(p) then
						return tonumber(p)
					else
						return p
					end
				end
			end
		end
	end
end
function CoreEnvEditor:retrive_sky_param(node, param)
	for parameter in node:children() do
		if parameter:parameter("key") == param then
			local p = parameter:parameter("value")
			if math.string_is_good_vector(p) then
				return math.string_to_vector(p)
			elseif tonumber(p) then
				return tonumber(p)
			else
				return p
			end
		end
	end
end
function CoreEnvEditor:flipp(...)
	local v = {
		...
	}
	if #v > 1 then
		local a = v[#v]
		v[#v] = v[1]
		v[1] = a
		return unpack(v)
	else
		return ...
	end
end
function CoreEnvEditor:add_gui_element(gui, tab, ...)
	local list = {
		...
	}
	self:add_box(gui, self._tabs[tab], list, 1)
end
function CoreEnvEditor:create_tab(tab)
	if not self._tabs[tab] then
		self._tabs[tab] = {}
		self._tabs[tab].child = {}
		self._tabs[tab].panel = EWS:Panel(self._main_notebook, "", "")
		self._tabs[tab].panel_box = EWS:BoxSizer("VERTICAL")
		self._tabs[tab].panel:freeze()
		self._tabs[tab].scrolled_window = EWS:ScrolledWindow(self._tabs[tab].panel, "", "VSCROLL")
		self._tabs[tab].scrolled_window:set_scroll_rate(Vector3(0, 1, 0))
		self._tabs[tab].scrolled_window:set_virtual_size_hints(Vector3(0, 0, 0), Vector3(1, -1, -1))
		self._tabs[tab].scrolled_window:set_virtual_size(Vector3(200, 2000, 0))
		self._tabs[tab].box = EWS:BoxSizer("VERTICAL")
	end
end
function CoreEnvEditor:build_tab(tab)
	if self._tabs[tab] then
		self._tabs[tab].scrolled_window:set_sizer(self._tabs[tab].box)
		self._tabs[tab].panel_box:add(self._tabs[tab].scrolled_window, 1, 0, "EXPAND")
		self._tabs[tab].panel:set_sizer(self._tabs[tab].panel_box)
		self._main_notebook:add_page(self._tabs[tab].panel, tab, false)
		self._tabs[tab].panel:thaw()
		self._tabs[tab].panel:refresh()
	end
end
function CoreEnvEditor:get_tab(tab)
	if self._tabs[tab] then
		return self._tabs[tab].scrolled_window
	end
end
function CoreEnvEditor:add_box(gui, parent, list, index)
	local this = parent.child[list[index]]
	if not this then
		this = {}
		this.child = {}
		this.box = EWS:StaticBoxSizer(parent.scrolled_window, "VERTICAL", list[index])
		this.scrolled_window = parent.scrolled_window
		parent.box:add(this.box, 0, 2, "ALL,EXPAND")
		parent.child[list[index]] = this
	end
	index = index + 1
	if list[index] then
		self:add_box(gui, this, list, index)
	else
		this.box:add(gui._box, 0, 2, "ALL,EXPAND")
	end
end
function CoreEnvEditor:set_title()
	self._main_frame:set_title(self._env_name .. " - Environment Editor")
end
function CoreEnvEditor:value_is_changed()
	self._value_is_changed = true
	managers.viewport:first_active_viewport():feed_params()
end
function CoreEnvEditor:add_updator(upd)
	table.insert(self._updators, upd)
end
function CoreEnvEditor:get_child(node, name)
	for child in node:children() do
		if child:name() == name then
			return child
		end
	end
	Application:error("Can't find child!")
end
function CoreEnvEditor:on_encode_parameters()
	local current_env = self._env_path
	if self._encode_parameters_dialog:show_modal() == "ID_YES" and managers and managers.environment then
		for _, env in ipairs(managers.database:list_entries_of_type("environment")) do
			self:database_load_env(env)
			self:write_to_disk(managers.database:entry_expanded_path("environment", self._env_path))
			self:set_title()
		end
	end
	self:database_load_env(current_env)
end
function CoreEnvEditor:write_to_disk(path, new_name)
	local file = SystemFS:open(path, "w")
	if file then
		file:print("<environment>\n")
		file:print("\t<metadata>\n")
		file:print("\t</metadata>\n")
		file:print("\t<data>\n")
		self:write_sky_orientation(file)
		self:write_sky(file)
		self:write_posteffect(file)
		self:write_underlayeffect(file)
		file:print("\t</data>\n")
		file:print("</environment>\n")
		file:close()
	end
end
function CoreEnvEditor:write_sky_orientation(file)
	file:print("\t\t<sky_orientation>\n")
	file:print("\t\t\t<param key=\"rotation\" value=\"0\" />\n")
	file:print("\t\t</sky_orientation>\n")
end
function CoreEnvEditor:write_posteffect(file)
	file:print("\t\t<post_effect>\n")
	for post_processor_name, post_processor in pairs(self._posteffect.post_processors) do
		file:print("\t\t\t<" .. post_processor_name .. ">\n")
		if post_processor_name == "shadow_processor" then
			self:write_shadow_params(file)
		else
			local e = "default"
			if post_processor_name == "fog_processor" then
				e = "fog"
			elseif post_processor_name == "deferred" then
				e = "deferred_lighting"
			elseif post_processor_name == "shadow_processor" then
				e = "shadow_rendering"
			end
			file:print("\t\t\t\t<" .. e .. ">\n")
			for modifier_name, mod in pairs(post_processor.modifiers) do
				file:print("\t\t\t\t\t<" .. modifier_name .. ">\n")
				for param_name, param in pairs(mod.params) do
					local v = param:get_value()
					if getmetatable(v) == _G.Vector3 then
						v = "" .. param:get_value().x .. " " .. param:get_value().y .. " " .. param:get_value().z
					else
						v = tostring(param:get_value())
					end
					file:print("\t\t\t\t\t\t<param key=\"" .. param_name .. "\" value=\"" .. v .. "\"/>\n")
				end
				file:print("\t\t\t\t\t</" .. modifier_name .. ">\n")
			end
			file:print("\t\t\t\t</" .. e .. ">\n")
		end
		file:print("\t\t\t</" .. post_processor_name .. ">\n")
	end
	file:print("\t\t</post_effect>\n")
end
function CoreEnvEditor:write_shadow_params(file)
	local params = self:shadow_feed_params({})
	file:print("\t\t\t\t<shadow_rendering>\n")
	file:print("\t\t\t\t\t<shadow_modifier>\n")
	for param_name, param in pairs(params) do
		local v = param
		if getmetatable(v) == _G.Vector3 then
			v = "" .. param.x .. " " .. param.y .. " " .. param.z
		else
			v = tostring(param)
		end
		file:print("\t\t\t\t\t\t<param key=\"" .. param_name .. "\" value=\"" .. v .. "\"/>\n")
	end
	file:print("\t\t\t\t\t</shadow_modifier>\n")
	file:print("\t\t\t\t</shadow_rendering>\n")
end
function CoreEnvEditor:write_underlayeffect(file)
	file:print("\t\t<underlay_effect>\n")
	for underlay_name, material in pairs(self._underlayeffect.materials) do
		file:print("\t\t\t<" .. underlay_name .. ">\n")
		for param_name, param in pairs(material.params) do
			local v = param:get_value()
			if getmetatable(v) == _G.Vector3 then
				v = "" .. param:get_value().x .. " " .. param:get_value().y .. " " .. param:get_value().z
			else
				v = tostring(param:get_value())
			end
			file:print("\t\t\t\t<param key=\"" .. param_name .. "\" value=\"" .. v .. "\"/>\n")
		end
		file:print("\t\t\t</" .. underlay_name .. ">\n")
	end
	file:print("\t\t</underlay_effect>\n")
end
function CoreEnvEditor:write_sky(file)
	file:print("\t\t<others>\n")
	for param_name, param in pairs(self._sky.params) do
		local v = param:get_value()
		if getmetatable(v) == _G.Vector3 then
			v = "" .. param:get_value().x .. " " .. param:get_value().y .. " " .. param:get_value().z
		else
			v = tostring(param:get_value())
		end
		file:print("\t\t\t<param key=\"" .. param_name .. "\" value=\"" .. v .. "\"/>\n")
	end
	file:print("\t\t</others>\n")
end
function CoreEnvEditor:on_close()
	managers.toolhub:close("Environment Editor")
end
function CoreEnvEditor:database_load_posteffect(post_effect_node)
	for post_processor in post_effect_node:children() do
		local post_pro = self._posteffect.post_processors[post_processor:name()]
		if not post_pro then
			self._posteffect.post_processors[post_processor:name()] = {}
			post_pro = self._posteffect.post_processors[post_processor:name()]
			post_pro.modifiers = {}
		end
		for effect in post_processor:children() do
			post_pro._effect = effect:name()
			for modifier in effect:children() do
				local mod = post_pro.modifiers[modifier:name()]
				if not mod then
					post_pro.modifiers[modifier:name()] = {}
					mod = post_pro.modifiers[modifier:name()]
					mod.params = {}
				end
				for param in modifier:children() do
					if param:name() == "param" and param:parameter("key") and param:parameter("key") ~= "" and param:parameter("value") and param:parameter("value") ~= "" then
						local k = param:parameter("key")
						local l = string.len(k)
						local parameter = mod.params[k]
						local remove_param = false
						if not parameter and not remove_param then
							mod.params[k] = DummyWidget:new()
							parameter = mod.params[k]
						end
						if not remove_param then
							local value = param:parameter("value")
							if math.string_is_good_vector(value) then
								parameter:set_value(math.string_to_vector(value))
							elseif tonumber(value) then
								parameter:set_value(tonumber(value))
							else
								parameter:set_value(tostring(value))
							end
						end
					end
				end
			end
		end
	end
	self:set_title()
end
function CoreEnvEditor:database_load_underlay(underlay_effect_node)
	if underlay_effect_node:name() == "underlay_effect" then
		for material in underlay_effect_node:children() do
			local mat = self._underlayeffect.materials[material:name()]
			if not mat then
				self._underlayeffect.materials[material:name()] = {}
				mat = self._underlayeffect.materials[material:name()]
				mat.params = {}
			end
			for param in material:children() do
				if param:name() == "param" and param:parameter("key") and param:parameter("key") ~= "" and param:parameter("value") and param:parameter("value") ~= "" then
					local k = param:parameter("key")
					local l = string.len(k)
					local parameter = mat.params[k]
					local remove_param = false
					if not parameter then
						if string.sub(k, l - 5, l) ~= "_scale" or not mat.params[string.sub(k, 1, l - 6)] then
							cat_print("debug", "[CoreEnvEditor] [Underlay] Deprecated in: " .. self._env_path .. " " .. material:parameter("name") .. " " .. k)
							if self.REMOVE_DEPRECATED_DURING_LOAD then
								cat_print("debug", "[CoreEnvEditor] Removing it!")
								mat.params[k] = nil
								remove_param = true
							end
						end
						if not remove_param then
							mat.params[k] = DummyWidget:new()
							parameter = mat.params[k]
						end
					end
					if not remove_param then
						local value = param:parameter("value")
						if math.string_is_good_vector(value) then
							parameter:set_value(math.string_to_vector(value))
						elseif tonumber(value) then
							parameter:set_value(tonumber(value))
						else
							parameter:set_value(tostring(value))
						end
					end
				end
			end
		end
	else
		cat_print("debug", "[CoreEnvEditor] Failed to load underlay in: " .. self._env_path)
	end
	self:set_title()
end
function CoreEnvEditor:database_load_sky(sky_node)
	if sky_node:name() == "others" then
		for param in sky_node:children() do
			if param:name() == "param" and param:parameter("key") and param:parameter("key") ~= "" and param:parameter("value") and param:parameter("value") ~= "" then
				local k = param:parameter("key")
				local l = string.len(k)
				local parameter = self._sky.params[k]
				local remove_param = false
				if not self._sky.params[k] then
					if string.sub(k, l - 5, l) ~= "_scale" or not self._sky.params[string.sub(k, 1, l - 6)] then
						cat_print("debug", "[CoreEnvEditor] [Sky] Deprecated in: " .. self._env_path .. " " .. k)
						if self.REMOVE_DEPRECATED_DURING_LOAD then
							cat_print("debug", "[CoreEnvEditor] Removig it!")
							self._sky.params[k] = nil
							remove_param = true
						end
					end
					if not remove_param then
						self._sky.params[k] = DummyWidget:new()
					end
				end
				if not remove_param then
					local value = param:parameter("value")
					if math.string_is_good_vector(value) then
						self._sky.params[param:parameter("key")]:set_value(math.string_to_vector(value))
					elseif tonumber(value) then
						self._sky.params[param:parameter("key")]:set_value(tonumber(value))
					else
						self._sky.params[param:parameter("key")]:set_value(value)
					end
				end
			end
		end
	else
		cat_print("debug", "[CoreEnvEditor] Failed to load sky in: " .. self._env_path)
	end
	self:set_title()
end
function CoreEnvEditor:database_load_env(env_path)
	local full_path = managers.database:entry_expanded_path("environment", env_path)
	local env = managers.database:has(full_path) and managers.database:load_node(full_path)
	if env then
		self._env_path = env_path
		self._env_name = managers.database:entry_name(env_path)
		if env:name() == "environment" then
			for param in env:child(1):children() do
				if param:name() == "others" then
					self:database_load_sky(param)
				elseif param:name() == "post_effect" then
					self:database_load_posteffect(param)
				elseif param:name() == "underlay_effect" then
					self:database_load_underlay(param)
				end
			end
		end
	end
	self:parse_shadow_data()
	self:set_title()
	return env
end
function CoreEnvEditor:on_open_file()
	local path = managers.database:open_file_dialog(self._main_frame, "Environments (*.environment)|*.environment")
	if path then
		self:database_load_env(managers.database:entry_path(path))
	end
end
function CoreEnvEditor:on_save_file()
	self:write_to_disk(managers.database:base_path() .. string.gsub(self._env_path, "/", "\\") .. ".environment")
end
function CoreEnvEditor:on_save_file_as()
	local path = managers.database:save_file_dialog(self._main_frame, false, "Environments (*.environment)|*.environment")
	if path then
		self:write_to_disk(path, managers.database:entry_name(path))
		self:database_load_env(managers.database:entry_name(path))
	end
end
function CoreEnvEditor:on_manager_flush()
	if managers and managers.environment then
		managers.environment:flush()
	end
end
function CoreEnvEditor:destroy()
	if alive(self._main_frame) then
		self._main_frame:destroy()
		self._main_frame = nil
	end
end
function CoreEnvEditor:close()
	self._main_frame:destroy()
	Global.render_debug.draw_enabled = self._debug_draw
	if self._database_frame then
		self._database_frame:destroy()
		self._database_frame = nil
	end
	if self._environment_frame then
		self._environment_frame:destroy()
		self._environment_frame = nil
	end
	managers.viewport:first_active_viewport():editor_callback(nil)
	managers.viewport:first_active_viewport():environment_mixer():set_environment(self._prev_environment)
	managers.viewport:first_active_viewport():reset_network_cache()
end
function CoreEnvEditor:set_position(newpos)
	self._main_frame:set_position(newpos)
end
function CoreEnvEditor:update(t, dt)
	self:sync()
	for _, upd in ipairs(self._updators) do
		upd:update(t, dt)
	end
	if EWS:get_key_state("K_SHIFT") then
		if self._update_pick_element and self._update_pick_element_type == "color" then
			local pixel = EWS:get_screen_pixel(EWS:get_screen_mouse_pos())
			local color = Vector3(pixel.x / 255, pixel.y / 255, pixel.z / 255)
			self._update_pick_element:set_value(color)
		elseif self._update_pick_element and self._update_pick_element_type == "depth" then
			self._update_pick_element:set_value(self:pick_depth())
		elseif self._update_pick_element and self._update_pick_element_type == "depth_x" then
			local old_val = self._update_pick_element:get_value()
			self._update_pick_element:set_value(Vector3(self:pick_depth(), old_val.y, old_val.z))
		elseif self._update_pick_element and self._update_pick_element_type == "depth_y" then
			local old_val = self._update_pick_element:get_value()
			self._update_pick_element:set_value(Vector3(old_val.x, self:pick_depth(), old_val.z))
		elseif self._update_pick_element and self._update_pick_element_type == "height" then
			self._update_pick_element:set_value(self:pick_height())
		elseif self._update_pick_element and self._update_pick_element_type == "height_x" then
			local old_val = self._update_pick_element:get_value()
			self._update_pick_element:set_value(Vector3(self:pick_height(), old_val.y, old_val.z))
		elseif self._update_pick_element and self._update_pick_element_type == "height_y" then
			local old_val = self._update_pick_element:get_value()
			self._update_pick_element:set_value(Vector3(old_val.x, self:pick_height(), old_val.z))
		end
	end
	if self._update_pick_element and self._update_pick_element_type ~= "color" then
		self:draw_cursor()
	end
end
function CoreEnvEditor:step()
	local undo = self._undo[self._undo_index]
	if undo._sky and self._sky then
		for key, value in pairs(undo._sky.params) do
			self._sky.params[key]:set_value(value)
		end
	end
	if undo._underlay and self._underlayeffect then
		for material, material_value in pairs(undo._underlay.materials) do
			for key, value in pairs(material_value.params) do
				self._underlayeffect.materials[material].params[key]:set_value(value)
			end
		end
	end
	if undo._posteffect and self._posteffect then
		for post_processor, post_processor_value in pairs(undo._posteffect.post_processors) do
			for modifier, modifier_value in pairs(post_processor_value.modifiers) do
				for key, value in pairs(modifier_value.params) do
					self._posteffect.post_processors[post_processor].modifiers[modifier].params[key]:set_value(value)
				end
			end
		end
	end
end
function CoreEnvEditor:on_undo()
	if self._undo_index > 1 then
		self._undo_index = self._undo_index - 1
		self:step()
		self._value_is_changed = false
	end
end
function CoreEnvEditor:on_redo()
	if self._undo_index <= self._max_undo_index then
		self._undo_index = self._undo_index + 1
		self:step()
		self._value_is_changed = false
	end
end
function CoreEnvEditor:get_cursor_look_point(camera, dist)
	local mouse_local = Vector3(0, 0, 0)
	local cursor_pos = Vector3(mouse_local.x / self._screen_borders.x * 2 - 1, mouse_local.y / self._screen_borders.y * 2 - 1, dist)
	return camera:screen_to_world(cursor_pos)
end
function CoreEnvEditor:draw_cursor()
	if managers.viewport and managers.viewport.get_current_camera then
		local camera = managers.viewport:get_current_camera()
		if alive(camera) then
			local pos = self:get_cursor_look_point(camera, 100)
			Application:draw_sphere(pos, 1, 1, 0, 0)
		end
	end
end
function CoreEnvEditor:pick_depth()
	if managers.viewport and managers.viewport.get_current_camera then
		local camera = managers.viewport:get_current_camera()
		if alive(camera) then
			local from = self:get_cursor_look_point(camera, 0)
			local to = self:get_cursor_look_point(camera, 1000000)
			local ray = World:raycast("ray", from, to)
			if ray then
				local pos = ray.position
				return math.clamp(camera:world_to_screen(pos).z, 0, camera:far_range())
			end
		end
	end
	return 0
end
function CoreEnvEditor:pick_height()
	if managers.viewport and managers.viewport.get_current_camera then
		local camera = managers.viewport:get_current_camera()
		if alive(camera) then
			local from = self:get_cursor_look_point(camera, 0)
			local to = self:get_cursor_look_point(camera, 1000000)
			local ray = World:raycast("ray", from, to)
			if ray then
				return ray.position.z
			end
		end
	end
	return 0
end
function CoreEnvEditor:sync()
	local undo_struct = {}
	if self._out_sky then
		undo_struct._sky = {}
		undo_struct._sky.params = {}
		for key, value in pairs(self._sky.params) do
			self._out_sky:set_value(key, value:get_value())
			local v = value:get_value()
			if not v then
				cat_print("debug", "[CoreEnvEditor] Deprecated! Open this environment in the advanced environment editor and save it again.")
			else
				local out
				if type(v) ~= "string" and type(v) ~= "number" then
					out = Vector3(v.x, v.y, v.z)
				elseif type(v) == "number" then
					out = v
				elseif string.sub(v, 1, 1) == "#" then
					out = self:value_database_lookup(string.sub(v, 2))
				else
					out = v
				end
				undo_struct._sky.params[key] = out
			end
		end
	end
	if self._out_underlayeffect then
		undo_struct._underlay = {}
		undo_struct._underlay.materials = {}
		for material, material_value in pairs(self._underlayeffect.materials) do
			undo_struct._underlay.materials[material] = {}
			undo_struct._underlay.materials[material].params = {}
			for key, value in pairs(material_value.params) do
				self._out_underlayeffect:set_value(material, key, value:get_value())
				local v = value:get_value()
				if not v then
					cat_print("debug", "[CoreEnvEditor] Deprecated! Open this environment in the advanced environment editor and save it again.")
				else
					local out
					if type(v) ~= "string" and type(v) ~= "number" then
						out = Vector3(v.x, v.y, v.z)
					elseif type(v) == "number" then
						out = v
					elseif string.sub(v, 1, 1) == "#" then
						out = self:value_database_lookup(string.sub(v, 2))
					else
						out = v
					end
					undo_struct._underlay.materials[material].params[key] = out
				end
			end
		end
	end
	if self._out_posteffect then
		undo_struct._posteffect = {}
		undo_struct._posteffect.post_processors = {}
		for post_processor, post_processor_value in pairs(self._posteffect.post_processors) do
			undo_struct._posteffect.post_processors[post_processor] = {}
			undo_struct._posteffect.post_processors[post_processor].modifiers = {}
			for modifier, modifier_value in pairs(post_processor_value.modifiers) do
				undo_struct._posteffect.post_processors[post_processor].modifiers[modifier] = {}
				undo_struct._posteffect.post_processors[post_processor].modifiers[modifier].params = {}
				for key, value in pairs(modifier_value.params) do
					self._out_posteffect:set_value(post_processor, modifier, key, value:get_value())
					local v = value:get_value()
					if not v then
						cat_print("debug", "[CoreEnvEditor] Deprecated! Open this environment in the advanced environment editor and save it again.")
					else
						local out
						if type(v) ~= "string" and type(v) ~= "number" then
							out = Vector3(v.x, v.y, v.z)
						elseif type(v) == "number" then
							out = v
						elseif string.sub(v, 1, 1) == "#" then
							out = self:value_database_lookup(string.sub(v, 2))
						else
							out = v
						end
						undo_struct._posteffect.post_processors[post_processor].modifiers[modifier].params[key] = out
					end
					local e = "default"
					if post_processor == "fog_processor" then
						e = "fog"
					elseif post_processor == "deferred" then
						e = "deferred_lighting"
					end
					self._out_posteffect._post_processors[post_processor]._effect = e
				end
			end
		end
	end
	if self._value_is_changed then
		self._max_undo_index = self._undo_index
		self._undo_index = self._undo_index + 1
		self._undo[self._undo_index] = undo_struct
		self._value_is_changed = false
	end
end
function CoreEnvEditor:value_database_lookup(str)
	local i = string.find(str, "#")
	local db_key = string.sub(str, 1, i - 1)
	local value_key = string.sub(str, i + 1)
	assert(db_key == "LightIntensityDB")
	local value = LightIntensityDB:lookup(value_key)
	assert(value)
	return value
end
