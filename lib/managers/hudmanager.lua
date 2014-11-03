HUDManager = HUDManager or class()
HUDManager.WAITING_SAFERECT = Idstring("guis/waiting_saferect")
HUDManager.STATS_SCREEN_SAFERECT = Idstring("guis/stats_screen/stats_screen_saferect")
HUDManager.STATS_SCREEN_FULLSCREEN = Idstring("guis/stats_screen/stats_screen_fullscreen")
HUDManager.SCENARIO = Idstring("guis/scenario")
HUDManager.ANNOUNCEMENT_HUD = Idstring("guis/announcement_hud")
HUDManager.ANNOUNCEMENT_HUD_FULLSCREEN = Idstring("guis/announcement_hud_fullscreen")
HUDManager.WAITING_FOR_PLAYERS_SAFERECT = Idstring("guis/waiting_saferect")
HUDManager.ASSAULT_DIALOGS = {
	"gen_ban_b01a",
	"gen_ban_b01b",
	"gen_ban_b02a",
	"gen_ban_b02b",
	"gen_ban_b02c",
	"gen_ban_b03x",
	"gen_ban_b04x",
	"gen_ban_b05x",
	"gen_ban_b10",
	"gen_ban_b11",
	"gen_ban_b12"
}
core:import("CoreEvent")
function HUDManager:init()
	self._component_map = {}
	local safe_rect_pixels = managers.viewport:get_safe_rect_pixels()
	local safe_rect = managers.viewport:get_safe_rect()
	local res = RenderSettings.resolution
	self._workspace_size = {
		x = 0,
		y = 0,
		w = res.x,
		h = res.y
	}
	self._saferect_size = {
		x = safe_rect.x,
		y = safe_rect.y,
		w = safe_rect.width,
		h = safe_rect.height
	}
	self._saferect = Overlay:gui():create_scaled_screen_workspace(self._workspace_size.w * safe_rect.width, self._workspace_size.h * safe_rect.height, safe_rect_pixels.x, safe_rect_pixels.y, safe_rect_pixels.width, safe_rect_pixels.height)
	self._workspace = Overlay:gui():create_scaled_screen_workspace(self._workspace_size.w, self._workspace_size.h, self._workspace_size.x, self._workspace_size.y, RenderSettings.resolution.x, RenderSettings.resolution.y)
	self._updators = {}
	managers.viewport:add_resolution_changed_func(callback(self, self, "resolution_changed"))
	if not self:exists(self.SCENARIO) then
		self:load_hud(self.SCENARIO, false, false, true, {})
	end
	self._sound_source = SoundDevice:create_source("hud")
	self._reached_level_s = managers.localization:text("debug_lu_reached_level")
	self._current_spec_s = managers.localization:text("debug_lu_current_spec")
	self._unlocked_s = managers.localization:text("debug_lu_unlocked")
	self._level_locked_s = managers.localization:text("debug_lu_level_locked")
	self._tree_assault_s = managers.localization:text("debug_upgrade_tree_assault")
	self._tree_sharpshooter_s = managers.localization:text("debug_upgrade_tree_sharpshooter")
	self._tree_support_s = managers.localization:text("debug_upgrade_tree_support")
	self._tree_technician_s = managers.localization:text("debug_upgrade_tree_technician")
	managers.user:add_setting_changed_callback("controller_mod", callback(self, self, "controller_mod_changed"), true)
	self:_init_player_hud_values()
	self._chatinput_changed_callback_handler = CoreEvent.CallbackEventHandler:new()
end
function HUDManager:saferect_w()
	return self._saferect:width()
end
function HUDManager:saferect_h()
	return self._saferect:height()
end
function HUDManager:add_chatinput_changed_callback(callback_func)
	self._chatinput_changed_callback_handler:add(callback_func)
end
function HUDManager:remove_chatinput_changed_callback(callback_func)
	self._chatinput_changed_callback_handler:remove(callback_func)
end
function HUDManager:controller_mod_changed()
	self:_selected_item_icon_text()
end
local is_PS3 = SystemInfo:platform() == Idstring("PS3")
function HUDManager:_selected_item_icon_text()
	local hud = self:script(PlayerBase.PLAYER_HUD)
	if not hud then
		return
	end
	if is_PS3 then
		hud.selected_item_icon:set_text(string.upper(managers.localization:text("debug_button_y")))
		return
	end
	local type = managers.controller:get_default_wrapper_type()
	local text = "[" .. managers.controller:get_settings(type):get_connection("use_item"):get_input_name_list()[1] .. "]"
	hud.selected_item_icon:set_text(string.upper(text))
	local _, _, w, h = hud.selected_item_icon:text_rect()
	hud.selected_item_icon:set_size(w, h)
	self:set_item_selected()
end
function HUDManager:init_finalize()
	if not self:exists(self.ANNOUNCEMENT_HUD_FULLSCREEN) then
		self:load_hud(self.ANNOUNCEMENT_HUD_FULLSCREEN, true, false, false, {})
		self:load_hud(self.ANNOUNCEMENT_HUD, true, false, true, {})
	end
	if not self:exists(self.WAITING_FOR_PLAYERS_SAFERECT) then
		managers.hud:load_hud(self.WAITING_FOR_PLAYERS_SAFERECT, false, true, true, {})
	end
end
function HUDManager:set_safe_rect(rect)
	self._saferect_size = rect
	self._saferect:set_screen(rect.w, rect.h, rect.x, rect.y, RenderSettings.resolution.x)
end
function HUDManager:load_hud(name, visible, using_collision, using_saferect, mutex_list, bounding_box_list)
	if self._component_map[name:key()] then
		Application:error("ERROR! Component " .. tostring(name) .. " have already been loaded!")
		return
	end
	local bounding_box = {}
	local panel
	if using_saferect then
		panel = self._saferect:panel():gui(name, {})
	else
		panel = self._workspace:panel():gui(name, {})
	end
	panel:hide()
	local bb_list = bounding_box_list
	if not bb_list and panel:has_script() then
		for k, v in pairs(panel:script()) do
			if k == "get_bounding_box_list" then
				if type(v) == "function" then
					bb_list = v()
				end
			else
			end
		end
	end
	if bb_list then
		if bb_list.x then
			table.insert(bb_list, {
				x1 = bb_list.x,
				y1 = bb_list.y,
				x2 = bb_list.x + bb_list.w,
				y2 = bb_list.y + bb_list.h
			})
		else
			for _, rect in pairs(bb_list) do
				table.insert(bounding_box, {
					x1 = rect.x,
					y1 = rect.y,
					x2 = rect.x + rect.w,
					y2 = rect.y + rect.h
				})
			end
		end
	else
		bounding_box = self:_create_bounding_boxes(panel)
	end
	self._component_map[name:key()] = {}
	self._component_map[name:key()].panel = panel
	self._component_map[name:key()].bb_list = bounding_box
	self._component_map[name:key()].mutex_list = {}
	self._component_map[name:key()].overlay_list = {}
	self._component_map[name:key()].idstring = name
	self._component_map[name:key()].load_visible = visible
	self._component_map[name:key()].load_using_collision = using_collision
	self._component_map[name:key()].load_using_saferect = using_saferect
	if mutex_list then
		self._component_map[name:key()].mutex_list = mutex_list
	end
	if using_collision then
		self._component_map[name:key()].overlay_list = self:_create_overlay_list(name)
	end
	if visible then
		panel:show()
	end
	self:layout(name)
end
function HUDManager:layout(name)
	local panel = self:script(name).panel
	if not panel:has_script() then
		return
	end
	for k, v in pairs(panel:script()) do
		if k == "layout" then
			panel:script().layout(self)
		else
		end
	end
end
function HUDManager:delete(name)
	self._component_map[name:key()] = nil
end
function HUDManager:set_disabled()
	self._disabled = true
	for name, gui in pairs(self._component_map) do
		self:hide(gui.idstring)
	end
end
function HUDManager:reload_player_hud()
	local name = PlayerBase.PLAYER_HUD
	local recreate = self._component_map[name:key()]
	self:reload()
	if recreate then
		self:hide(name)
		self:delete(name)
		self:load_hud(name, false, false, true, {})
		self:show(name)
		self:_player_hud_layout()
	end
end
function HUDManager:reload_all()
	self:reload()
	for name, gui in pairs(clone(self._component_map)) do
		local visible = self:visible(gui.idstring)
		self:hide(gui.idstring)
		self:delete(gui.idstring)
		self:load_hud(gui.idstring, gui.load_visible, gui.load_using_collision, gui.load_using_saferect, {})
		if visible then
			self:show(gui.idstring)
		end
	end
end
function HUDManager:reload()
	self:_recompile(managers.database:root_path() .. "assets\\guis\\")
end
function HUDManager:_recompile(dir)
	local source_files = self:_source_files(dir)
	local t = {
		platform = "win32",
		source_root = managers.database:root_path() .. "/assets",
		target_db_root = managers.database:root_path() .. "/packages/win32/assets",
		target_db_name = "all",
		source_files = source_files,
		verbose = false,
		send_idstrings = false
	}
	Application:data_compile(t)
	DB:reload()
	managers.database:clear_all_cached_indices()
	for _, file in ipairs(source_files) do
		PackageManager:reload(managers.database:entry_type(file):id(), managers.database:entry_path(file):id())
	end
end
function HUDManager:_source_files(dir)
	local files = {}
	local entry_path = managers.database:entry_path(dir) .. "/"
	for _, file in ipairs(SystemFS:list(dir)) do
		table.insert(files, entry_path .. file)
	end
	for _, sub_dir in ipairs(SystemFS:list(dir, true)) do
		for _, file in ipairs(SystemFS:list(dir .. "/" .. sub_dir)) do
			table.insert(files, entry_path .. sub_dir .. "/" .. file)
		end
	end
	return files
end
function HUDManager:panel(name)
	if not self._component_map[name:key()] then
		Application:error("ERROR! Component " .. tostring(name) .. " isn't loaded!")
	else
		return self._component_map[name:key()].panel
	end
end
function HUDManager:alive(name)
	local component = self._component_map[name:key()]
	return component and alive(component.panel)
end
function HUDManager:script(name)
	local component = self._component_map[name:key()]
	if component and alive(component.panel) then
		return self._component_map[name:key()].panel:script()
	else
	end
end
function HUDManager:exists(name)
	return not not self._component_map[name:key()]
end
function HUDManager:show(name)
	if self._disabled then
		return
	end
	if self._component_map[name:key()] then
		for _, mutex_name in pairs(self._component_map[name:key()].mutex_list) do
			if self._component_map[mutex_name:key()].panel:visible() then
				self._component_map[mutex_name:key()].panel:hide()
			end
		end
		if self:_validate_components(name) then
			self._component_map[name:key()].panel:show()
		end
	else
		Application:error("ERROR! Component " .. tostring(name) .. " isn't loaded!")
	end
end
function HUDManager:hide(name)
	local component = self._component_map[name:key()]
	if component and alive(component.panel) then
		component.panel:hide()
	elseif not component then
		Application:error("ERROR! Component " .. tostring(name) .. " isn't loaded!")
	end
end
function HUDManager:visible(name)
	if self._component_map[name:key()] then
		return self._component_map[name:key()].panel:visible()
	else
		Application:error("ERROR! Component " .. tostring(name) .. " isn't loaded!")
	end
end
function HUDManager:_collision(rect1_map, rect2_map)
	if rect1_map.x1 >= rect2_map.x2 then
		return false
	end
	if rect1_map.x2 <= rect2_map.x1 then
		return false
	end
	if rect1_map.y1 >= rect2_map.y2 then
		return false
	end
	if rect1_map.y2 <= rect2_map.y1 then
		return false
	end
	return true
end
function HUDManager:_inside(rect1_map, rect2_map)
	if rect1_map.x1 < rect2_map.x1 or rect1_map.x1 > rect2_map.x2 then
		return false
	end
	if rect1_map.y1 < rect2_map.y1 or rect1_map.y1 > rect2_map.y2 then
		return false
	end
	if rect1_map.x2 < rect2_map.x1 or rect1_map.x2 > rect2_map.x2 then
		return false
	end
	if rect1_map.y2 < rect2_map.x1 or rect1_map.y2 > rect2_map.y2 then
		return false
	end
	return true
end
function HUDManager:_collision_rects(rect1_list, rect2_list)
	for _, rc1_map in pairs(rect1_list) do
		for _, rc2_map in pairs(rect2_list) do
			if self:_collision(rc1_map, rc2_map) then
				return true
			end
		end
	end
	return false
end
function HUDManager:_is_mutex(component_map, name)
	for _, mutex_name in pairs(component_map.mutex_list) do
		if mutex_name:key() == name then
			return true
		end
	end
	return false
end
function HUDManager:_create_bounding_boxes(panel)
	local bounding_box_list = {}
	local childrens = panel:children()
	local rect_map = {}
	for _, object in pairs(childrens) do
		rect_map = {
			x1 = object:x(),
			y1 = object:y(),
			x2 = object:x() + object:w(),
			y2 = object:y() + object:h()
		}
		if #bounding_box_list == 0 then
			table.insert(bounding_box_list, rect_map)
		else
			for _, bb_rect_map in pairs(bounding_box_list) do
				if self:_inside(rect_map, bb_rect_map) == false then
					table.insert(bounding_box_list, rect_map)
				else
				end
			end
		end
	end
	return bounding_box_list
end
function HUDManager:_create_overlay_list(name)
	local component = self._component_map[name:key()]
	local overlay_list = {}
	for cmp_name, cmp_map in pairs(self._component_map) do
		if name:key() ~= cmp_name and not self:_is_mutex(cmp_map, name:key()) and self:_collision_rects(component.bb_list, cmp_map.bb_list) then
			table.insert(overlay_list, cmp_map.idstring)
			if not self:_is_mutex(component, cmp_name) then
				table.insert(self._component_map[cmp_name].overlay_list, name)
			end
			if Application:production_build() then
				Application:error("WARNING! Component " .. tostring(name) .. " collides with " .. tostring(cmp_map.idstring))
			end
		end
	end
	return overlay_list
end
function HUDManager:_validate_components(name)
	for _, overlay_name in pairs(self._component_map[name:key()].overlay_list) do
		if self._component_map[overlay_name:key()] and self._component_map[overlay_name:key()].panel:visible() then
			Application:error("WARNING! Component " .. tostring(name) .. " collides with " .. tostring(overlay_name))
			return false
		end
	end
	return true
end
function HUDManager:resolution_changed()
	local res = RenderSettings.resolution
	local safe_rect_pixels = managers.viewport:get_safe_rect_pixels()
	local safe_rect = managers.viewport:get_safe_rect()
	self._workspace:set_screen(res.x, res.y, 0, 0, res.x)
	self._saferect:set_screen(res.x * safe_rect.width, res.y * safe_rect.height, safe_rect_pixels.x, safe_rect_pixels.y, safe_rect_pixels.width, safe_rect_pixels.height)
	for name, gui in pairs(self._component_map) do
		self:layout(gui.idstring)
	end
end
function HUDManager:update(t, dt)
	for _, cb in pairs(self._updators) do
		cb(t, dt)
	end
	self:_update_name_labels(t, dt)
	self:_update_waypoints(t, dt)
	if self._chat_state and t > self._chat_state.start_fade then
		self._chat_state.fade = self._chat_state.fade - dt
		self:_set_chat_alpha(self._chat_state.scrollus, self._chat_state.scrolllines, self._chat_state.fade)
		if self._chat_state.fade <= 0 then
			self:_set_chat_alpha(self._chat_state.scrollus, self._chat_state.scrolllines, 0)
			self._chat_state = nil
		end
	end
	if self._debug then
		local cam_pos = managers.viewport:get_current_camera_position()
		if cam_pos then
			self._debug.coord:set_text(string.format("Cam pos:   \"%.0f %.0f %.0f\" [cm]", cam_pos.x, cam_pos.y, cam_pos.z))
		end
	end
end
function HUDManager:add_updator(id, cb)
	self._updators[id] = cb
end
function HUDManager:remove_updator(id)
	self._updators[id] = nil
end
local nl_w_pos = Vector3()
local nl_pos = Vector3()
local nl_dir = Vector3()
local nl_dir_normalized = Vector3()
local nl_cam_forward = Vector3()
function HUDManager:_update_name_labels(t, dt)
	local cam = managers.viewport:get_current_camera()
	if not cam then
		return
	end
	local cam_pos = managers.viewport:get_current_camera_position()
	local cam_rot = managers.viewport:get_current_camera_rotation()
	mrotation.y(cam_rot, nl_cam_forward)
	local panel
	for _, data in ipairs(self._hud.name_labels) do
		local text = data.text
		panel = panel or text:parent()
		local movement = data.movement
		mvector3.set(nl_w_pos, movement:m_pos())
		mvector3.set_z(nl_w_pos, mvector3.z(movement:m_head_pos()) + 30)
		mvector3.set(nl_pos, self._workspace:world_to_screen(cam, nl_w_pos))
		mvector3.set(nl_dir, nl_w_pos)
		mvector3.subtract(nl_dir, cam_pos)
		mvector3.set(nl_dir_normalized, nl_dir)
		mvector3.normalize(nl_dir_normalized)
		local dot = mvector3.dot(nl_cam_forward, nl_dir_normalized)
		if dot < 0 or panel:outside(mvector3.x(nl_pos), mvector3.y(nl_pos)) then
			if text:visible() then
				text:set_visible(false)
			end
		elseif mvector3.distance_sq(cam_pos, nl_w_pos) < 250000 then
			text:set_visible(true)
		elseif dot > 0.925 then
			text:set_visible(true)
		else
			text:set_visible(false)
		end
		if text:visible() then
			text:set_center(nl_pos.x, nl_pos.y)
		end
	end
end
function HUDManager:_init_player_hud_values()
	self._hud = self._hud or {}
	self._hud.MAX_CLIP = 140
	self._hud.current_clip = self._hud.current_clip or 140
	self._hud.waypoints = self._hud.waypoints or {}
	self._hud.stored_waypoints = self._hud.stored_waypoints or {}
	self._hud.items = self._hud.items or {}
	self._hud.special_equipments = self._hud.special_equipments or {}
	self._hud.weapons = self._hud.weapons or {}
	self._hud.pressed_d_pad = self._hud.pressed_d_pad or {}
	self._hud.mugshots = self._hud.mugshots or {}
	self._hud.name_labels = self._hud.name_labels or {}
end
function HUDManager:_announcement_hud_layout()
	local hud = managers.hud:script(self.ANNOUNCEMENT_HUD)
	local full_hud = managers.hud:script(self.ANNOUNCEMENT_HUD_FULLSCREEN)
	local safe_rect_pixels = managers.viewport:get_safe_rect_pixels()
	local res = RenderSettings.resolution
	hud.upgrade_awarded:set_font_size(tweak_data.hud.upgrade_awarded_font_size)
	hud.upgrade_awarded:set_shape(hud.upgrade_awarded:text_rect())
	local header_h = hud.upgrade_awarded:h() + 4 * tweak_data.scale.level_up_multiplier
	hud.upgrade_awarded:set_h(header_h)
	hud.upgrade_awarded:set_w(hud.upgrade_awarded:w())
	hud.level_up_image:set_size(340 * tweak_data.scale.level_up_multiplier, 150 * tweak_data.scale.level_up_multiplier)
	hud.level_up_image:set_top(hud.upgrade_awarded:bottom())
	hud.level_up_image_frame:set_size(340 * tweak_data.scale.level_up_multiplier, 150 * tweak_data.scale.level_up_multiplier)
	hud.level_up_image_frame:set_center(hud.level_up_image:center())
	local image, rect = tweak_data.hud_icons:get_icon_data("level_up_image_frame")
	hud.level_up_image_frame:set_image(image, rect[1], rect[2], rect[3], rect[4])
	hud.left_overlay:set_shape(hud.level_up_image:shape())
	hud.level_up_current_spec:set_font_size(tweak_data.hud.small_font_size)
	hud.level_up_current_spec:set_top(hud.level_up_image:bottom())
	hud.level_up_unlocked:set_font_size(tweak_data.hud.small_font_size)
	hud.level_up_unlocked:set_bottom(hud.level_up_image:bottom() - 8 * tweak_data.scale.level_up_multiplier)
	hud.level_up_unlocked:set_x(hud.level_up_image:left() + 8 * tweak_data.scale.level_up_multiplier)
	hud.level_up_right:set_right(hud.panel:right())
	hud.next_level_text:set_font_size(tweak_data.hud.upgrade_awarded_font_size)
	hud.next_level_text:set_shape(hud.next_level_text:text_rect())
	hud.next_level_text:set_h(header_h)
	hud.next_level_text:set_right(hud.next_level_text:parent():w())
	local w, h = 340 * tweak_data.scale.level_up_multiplier, 150 * tweak_data.scale.level_up_multiplier
	hud.next_level_upgrade_panel:set_size(w, h)
	hud.next_level_upgrade_image:set_shape(0, 0, w, h)
	hud.next_level_upgrade_panel:set_righttop(hud.next_level_text:rightbottom())
	hud.next_level_upgrade:set_font_size(tweak_data.hud.next_upgrade_font_size)
	hud.next_level_upgrade:set_x(8 * tweak_data.scale.level_up_multiplier)
	hud.next_level_upgrade:set_bottom(hud.next_level_upgrade_image:bottom() - 8 * tweak_data.scale.level_up_multiplier)
	hud.next_level_upgrade_upgrade:set_font_size(tweak_data.hud.next_upgrade_font_size)
	hud.next_level_upgrade_upgrade:set_size(hud.next_level_upgrade_panel:size())
	hud.next_level_upgrade_upgrade:set_x(-8 * tweak_data.scale.level_up_multiplier)
	hud.next_level_upgrade_upgrade:set_center_y(hud.next_level_upgrade_panel:h() / 2)
	hud.next_level_upgrade_upgrade:set_bottom(hud.next_level_upgrade_image:bottom() - 8 * tweak_data.scale.level_up_multiplier)
	hud.next_level_upgrade_image_frame:set_size(w, h)
	hud.next_level_upgrade_image_frame:set_center(hud.next_level_upgrade_image:center())
	hud.next_level_upgrade_image_frame:set_image(image, rect[1], rect[2], rect[3], rect[4])
	hud.right_overlay:set_size(hud.next_level_upgrade_panel:w(), hud.next_level_upgrade_panel:h())
	hud.right_overlay:set_position(hud.next_level_upgrade_panel:position())
	hud.next_level_menu_help:set_font_size(tweak_data.hud.small_font_size)
	hud.next_level_menu_help:set_righttop(hud.next_level_upgrade_panel:rightbottom())
	full_hud.panel:set_x(0)
	full_hud.panel:set_h(full_hud.spat_left:texture_height() * tweak_data.scale.level_up_multiplier)
	full_hud.panel:set_w(res.x)
	full_hud.panel:set_center_y(safe_rect_pixels.y + hud.upgrade_awarded:h() + hud.level_up_image:h() / 2)
	full_hud.present_background:set_center_y(full_hud.present_background:parent():h() / 2)
	full_hud.present_background:set_w(res.x)
	full_hud.present_background:set_texture_rect(0, 0, 512 * (full_hud.present_background:w() / 512), 256)
	local w, h = full_hud.spat_left:texture_width(), full_hud.spat_left:texture_height()
	full_hud.spat_left:set_size(w * tweak_data.scale.level_up_multiplier, h * tweak_data.scale.level_up_multiplier)
	full_hud.spat_left:set_center_y(full_hud.present_background:center_y())
	full_hud.spat_left:set_center_x(safe_rect_pixels.x + hud.level_up_image:w() / 2 + 25)
	local w, h = full_hud.spat_right:texture_width(), full_hud.spat_right:texture_height()
	full_hud.spat_right:set_size(w * tweak_data.scale.level_up_multiplier, h * tweak_data.scale.level_up_multiplier)
	full_hud.spat_right:set_center_y(full_hud.present_background:center_y() + 10)
	full_hud.spat_right:set_center_x(safe_rect_pixels.x + safe_rect_pixels.width - hud.level_up_image:w() / 2)
	hud.level_up_text:set_kern(tweak_data.scale.level_up_text_kern)
	hud.level_up_text:set_font_size(tweak_data.hud.level_up_font_size)
	hud.level_up_text:set_shape(hud.level_up_text:text_rect())
	hud.level_up_text:set_w(hud.level_up_text:w() + 64)
	hud.level_up_text:set_center_x(hud.level_up_text:parent():center_x())
	hud.level_up_text:set_center_y(hud.next_level_text:h() + 150 * tweak_data.scale.level_up_multiplier / 2)
end
function HUDManager:_player_info_hud_layout()
	if not self:alive(PlayerBase.PLAYER_INFO_HUD) then
		return
	end
	local safe_rect_pixels = managers.viewport:get_safe_rect_pixels()
	local res = RenderSettings.resolution
	local hud = managers.hud:script(PlayerBase.PLAYER_INFO_HUD)
	local full_hud = managers.hud:script(PlayerBase.PLAYER_INFO_HUD_FULLSCREEN)
	full_hud.present_background:set_w(res.x)
	hud.hint_text:set_font_size(tweak_data.hud.hint_font_size)
	hud.hint_shadow_text:set_font_size(tweak_data.hud.hint_font_size)
	local x = hud.hint_text:parent():center_x()
	local y = hud.hint_text:parent():center_y() / 2.5
	hud.hint_text:set_center(x, y)
	hud.hint_shadow_text:set_center(x + 1, y + 1)
	hud.location_text:set_font_size(tweak_data.hud.location_font_size)
	hud.location_text:set_top(0)
	hud.location_text:set_center_x(hud.location_text:parent():w() / 2)
	local x = hud.present_mid_text:parent():center_x()
	local y = hud.present_mid_text:parent():center_y() / 1.1
	hud.present_mid_text:set_font_size(tweak_data.hud.present_mid_text_font_size)
	hud.present_mid_text:set_center(x, y)
	hud.present_mid_text:set_left(50)
	hud.title_mid_text:set_font_size(tweak_data.hud.small_font_size)
	hud.title_mid_text:set_bottom(hud.present_mid_text:top())
	hud.title_mid_text:set_left(50)
	hud.present_mid_icon:set_size(48 * tweak_data.scale.present_multiplier, 48 * tweak_data.scale.present_multiplier)
	hud.present_mid_icon:set_top(hud.title_mid_text:top())
	hud.present_mid_icon:set_right(hud.present_mid_text:left() - 2)
	hud.messages_panel:set_center_x(safe_rect_pixels.width / 2)
	local hp_c = hud.health_health:h()
	local hp_t = hud.health_background:h()
	local a_c = hud.health_armor:h()
	hud.health_panel:set_size(64 * tweak_data.scale.hud_health_multiplier, 130 * tweak_data.scale.hud_health_multiplier)
	hud.health_panel:set_left(0)
	hud.health_panel:set_bottom(hud.health_panel:parent():bottom() - (22 * tweak_data.scale.experience_bar_multiplier + 2 * tweak_data.scale.hud_health_multiplier))
	hud.health_name:set_font_size(tweak_data.hud.small_font_size)
	local _, _, w, h = hud.health_name:text_rect()
	hud.health_name:set_size(hud.health_panel:w(), h)
	hud.health_name:set_bottom(hud.health_panel:h() - 2 * tweak_data.scale.hud_health_multiplier)
	self:set_player_health({current = hp_c, total = hp_t})
	self:set_player_armor({current = a_c, total = hp_t})
	hud.control_hostages:set_font_size(tweak_data.hud.small_font_size)
	local _, _, w, h = hud.control_hostages:text_rect()
	hud.control_hostages:set_h(h)
	local image, rect = tweak_data.hud_icons:get_icon_data("assault")
	hud.assault_image:set_image(image, rect[1], rect[2], rect[3], rect[4])
	hud.assault_image:set_size(rect[3] * tweak_data.scale.hud_assault_image_multiplier, rect[4] * tweak_data.scale.hud_assault_image_multiplier)
	hud.control_panel:set_w(362)
	hud.control_panel:set_h(h + rect[4])
	hud.control_panel:set_center_x(hud.control_panel:parent():w() / 2)
	hud.control_panel:set_bottom(hud.control_panel:parent():h())
	hud.control_hostages:set_center_x(hud.control_hostages:parent():w() / 2)
	hud.control_hostages:set_bottom(hud.control_hostages:parent():h())
	hud.assault_image:set_center_x(hud.assault_image:parent():w() / 2)
	hud.assault_image:set_bottom(hud.control_hostages:top())
	hud.control_assault_title:set_text(managers.localization:text("menu_assault"))
	hud.control_assault_title:set_font_size(tweak_data.hud.assault_title_font_size)
	hud.control_assault_title:set_shape(hud.control_assault_title:text_rect())
	hud.control_assault_title:set_center_x(hud.assault_image:center_x())
	hud.control_assault_title:set_center_y(hud.assault_image:center_y() * 1.2)
	hud.control_hostages:set_text(managers.localization:text("debug_control_hostages") .. " " .. "0")
	self:_layout_point_of_no_return_panel()
	self:_layout_mugshots()
	if not is_PS3 then
		local say_text = full_hud.panel:child("say_text")
		say_text:set_font_size(tweak_data.hud.chatinput_size)
		local _, _, w, h = say_text:text_rect()
		say_text:set_size(w, h)
		say_text:set_position(4, 4)
		full_hud.panel:child("chat_input"):set_size(500 * tweak_data.scale.chat_multiplier, 25 * tweak_data.scale.chat_multiplier)
		full_hud.panel:child("chat_input"):set_y(4)
		full_hud.panel:child("chat_input"):set_left(say_text:right())
		full_hud.panel:child("chat_input"):script().text:set_font_size(tweak_data.hud.chatinput_size)
		full_hud.panel:child("textscroll"):set_size(400 * tweak_data.scale.chat_multiplier, 118 * tweak_data.scale.chat_multiplier)
		full_hud.panel:child("textscroll"):script().scrollus:set_font_size(tweak_data.hud.chatoutput_size)
		full_hud.panel:child("textscroll"):set_x(4)
		self:_layout_chat_output()
	end
end
function HUDManager:_layout_chat_output()
	local hud = managers.hud:script(PlayerBase.PLAYER_INFO_HUD)
	local full_hud = managers.hud:script(PlayerBase.PLAYER_INFO_HUD_FULLSCREEN)
	local state = full_hud:chat_output_state()
	if state == "default" then
		full_hud.panel:child("textscroll"):set_bottom(hud.health_panel:top() + self._saferect_size.y * self._workspace_size.h - 12)
	else
		full_hud.panel:child("textscroll"):set_bottom(hud.health_panel:bottom() + self._saferect_size.y * self._workspace_size.h - 4)
	end
end
function HUDManager:set_chat_output_state(state)
	if is_PS3 then
		return
	end
	if not self:alive(PlayerBase.PLAYER_INFO_HUD_FULLSCREEN) then
		return
	end
	local full_hud = managers.hud:script(PlayerBase.PLAYER_INFO_HUD_FULLSCREEN)
	full_hud:set_chat_output_state(state)
	self:_layout_chat_output()
end
function HUDManager:_layout_player_info_hud_fullscreen()
	if not self:alive(PlayerBase.PLAYER_INFO_HUD_FULLSCREEN) then
		return
	end
	if is_PS3 then
		return
	end
	local hud = managers.hud:script(PlayerBase.PLAYER_INFO_HUD_FULLSCREEN)
	if not hud.panel:child("textscroll") then
		hud.panel:gui(Idstring("guis/chat/textscroll"), {
			name = "textscroll",
			layer = 0,
			h = 118,
			w = 400,
			valign = "grow",
			halign = "grow"
		})
		hud.panel:gui(Idstring("guis/chat/chat_input"), {
			name = "chat_input",
			h = 25,
			w = 500,
			layer = 5,
			valign = "bottom",
			halign = "grow",
			y = 125
		})
		hud.panel:child("chat_input"):script().enter_callback = callback(self, self, "_cb_chat")
		hud.panel:child("chat_input"):script().esc_callback = callback(self, self, "_cb_unlock")
		hud.panel:child("chat_input"):script().typing_callback = callback(self, self, "_cb_lock")
		hud.panel:child("textscroll"):script().background:set_visible(false)
		hud.panel:child("chat_input"):script().background:set_visible(false)
		hud.panel:text({
			name = "say_text",
			text = string.upper(managers.localization:text("debug_chat_say")),
			color = Color.white,
			font = "fonts/font_univers_530_bold",
			font_size = 22,
			align = "center",
			vertical = "center",
			layer = 5
		})
		hud.panel:child("say_text"):set_visible(false)
	end
end
function HUDManager:_cb_chat()
	local hud = managers.hud:script(PlayerBase.PLAYER_INFO_HUD_FULLSCREEN)
	local chat_text = hud.panel:child("chat_input"):child("text"):text()
	if managers.network:session() and chat_text and tostring(chat_text) ~= "" then
		local name = string.upper(managers.network:session():local_peer():name())
		local say = name .. ": " .. tostring(chat_text)
		self:_say(say, managers.network:session():local_peer():id())
		managers.network:session():send_to_peers("sync_chat_message", say)
	end
	self._chatbox_typing = false
	hud.panel:child("chat_input"):child("text"):set_text("")
	hud.panel:child("chat_input"):child("text"):set_selection(0, 0)
	setup:add_end_frame_clbk(function()
		self:set_chat_focus(false)
	end)
end
function HUDManager:sync_say(...)
	self:_say(...)
	if not self._chat_focus then
		local hud = managers.hud:script(PlayerBase.PLAYER_INFO_HUD_FULLSCREEN)
		local s = hud.panel:child("textscroll"):script()
		self._chat_state = {
			start_fade = Application:time() + 10,
			fade = 1,
			scrollus = s.scrollus,
			scrolllines = s.scrolllines
		}
	end
end
function HUDManager:_say(message, id)
	print("_say", message, id)
	self._sound_source:post_event("prompt_exit")
	local hud = managers.hud:script(PlayerBase.PLAYER_INFO_HUD_FULLSCREEN)
	local s = hud.panel:child("textscroll"):script()
	local i = utf8.find_char(message, ":")
	s.box_print(message, tweak_data.chat_colors[id], i)
	s.scrollus:set_color(Color.white)
end
function HUDManager:_cb_unlock()
	setup:add_end_frame_clbk(function()
		self:set_chat_focus(false)
	end)
end
function HUDManager:_cb_lock()
end
function HUDManager:toggle_chatinput()
	self:set_chat_focus(true)
end
function HUDManager:_set_chat_alpha(scrollus, scrolllines, alpha)
	scrollus:set_color(Color.white:with_alpha(alpha))
	for _, line in ipairs(scrolllines) do
		scrollus:set_range_color(line.si, line.si + line.i, line.c:with_alpha(alpha))
	end
end
function HUDManager:set_chat_focus(focus)
	if not self:alive(PlayerBase.PLAYER_INFO_HUD_FULLSCREEN) then
		return
	end
	if self._chat_focus == focus then
		return
	end
	self._chat_focus = focus
	self._chatinput_changed_callback_handler:dispatch(self._chat_focus)
	local hud = managers.hud:script(PlayerBase.PLAYER_INFO_HUD_FULLSCREEN)
	hud.panel:child("chat_input"):script().set_focus(self._chat_focus, true)
	hud.panel:child("chat_input"):script().background:set_visible(self._chat_focus)
	hud.panel:child("say_text"):set_visible(self._chat_focus)
	self._chat_state = nil
	local s = hud.panel:child("textscroll"):script()
	self:_set_chat_alpha(s.scrollus, s.scrolllines, 1)
	if self._chat_focus then
		self._workspace:connect_keyboard(Input:keyboard())
	else
		self._chat_state = {
			start_fade = Application:time() + 10,
			fade = 1,
			scrollus = s.scrollus,
			scrolllines = s.scrolllines
		}
		self._workspace:disconnect_keyboard()
	end
end
function HUDManager:_player_hud_layout()
	if not self:alive(PlayerBase.PLAYER_HUD) then
		return
	end
	self:_layout_player_info_hud_fullscreen()
	local safe_rect_pixels = managers.viewport:get_safe_rect_pixels()
	self:_init_player_hud_values()
	local hud = managers.hud:script(PlayerBase.PLAYER_HUD)
	hud.crosshair_panel:set_center(hud.crosshair_panel:parent():center())
	hud.interact_bitmap:set_center_y(hud.interact_bitmap:parent():center_y() / 1.65)
	hud.interact_bitmap:set_right(48 + safe_rect_pixels.width / 2 - 360 / (2 / math.max(1, tweak_data.scale.w_interact_multiplier)))
	hud.interact_background:set_h(22 * tweak_data.scale.small_font_multiplier)
	hud.interact_background:set_w(360 * (tweak_data.scale.w_interact_multiplier or tweak_data.scale.small_font_multiplier))
	hud.interact_background:set_left(hud.interact_bitmap:right() + 2)
	hud.interact_background:set_center_y(hud.interact_bitmap:center_y())
	hud.interact_bar:set_h(hud.interact_background:h() - 2)
	hud.interact_bar:set_w(hud.interact_background:w() - 2)
	hud.interact_bar:set_center(hud.interact_background:center())
	hud.interact_bar_stop:set_size(8 * tweak_data.scale.small_font_multiplier, 22 * tweak_data.scale.small_font_multiplier)
	hud.interact_bar_stop:set_right(hud.interact_bar:right() + 1)
	hud.interact_bar_stop:set_center_y(hud.interact_bar:center_y())
	hud.interact_text:set_font_size(tweak_data.hud.small_font_size)
	hud.interact_text:set_w(hud.interact_background:w() - 8)
	hud.interact_text:set_left(hud.interact_background:left() + 4)
	hud.interact_text:set_top(hud.interact_background:top() + 2)
	hud.ammo_warning_text:set_font_size(tweak_data.hud.default_font_size)
	hud.ammo_warning_shadow_text:set_font_size(tweak_data.hud.default_font_size)
	local x = hud.ammo_warning_text:parent():center_x()
	local y = hud.ammo_warning_text:parent():center_y() + hud.ammo_warning_text:parent():center_y() / 4
	hud.ammo_warning_text:set_center(x, y)
	hud.ammo_warning_shadow_text:set_center(x + 1, y + 1)
	local x = safe_rect_pixels.width / 3
	local y = hud.present_text:parent():bottom() - 22
	hud.present_text:set_right(x)
	hud.present_text:set_bottom(y)
	hud.objective_title:set_left(hud.objective_title:parent():left())
	hud.objective_text:set_lefttop(hud.objective_title:leftbottom())
	hud.d_pad_panel:set_visible(SystemInfo:platform() == Idstring("PS3"))
	hud.d_pad_panel:set_size(64 * tweak_data.scale.hud_equipment_icon_multiplier, 64 * tweak_data.scale.hud_equipment_icon_multiplier)
	hud.d_pad_panel:set_right(hud.d_pad_panel:parent():right())
	hud.d_pad_panel:set_bottom(hud.d_pad_panel:parent():bottom() - 32 * tweak_data.scale.hud_equipment_icon_multiplier)
	hud.weapon_panel:set_right(hud.d_pad_panel:left())
	hud.weapon_panel:set_center_y(hud.d_pad_panel:center_y())
	self:_layout_items()
	hud.item_panel:set_bottom(hud.d_pad_panel:top())
	hud.item_panel:set_center_x(hud.d_pad_panel:center_x())
	hud.selected_item_icon:set_font_size(tweak_data.hud.default_font_size)
	self:_selected_item_icon_text()
	self:_layout_special_equipment()
	self:_layout_special_equipments()
	hud.ammo_panel:set_size(512 * tweak_data.scale.hud_equipment_icon_multiplier, 128 * tweak_data.scale.hud_equipment_icon_multiplier)
	hud.ammo_panel:set_right(hud.d_pad_panel:left())
	hud.ammo_panel:set_bottom(hud.ammo_panel:parent():bottom())
	hud.weapon_name:set_font_size(tweak_data.hud.default_font_size)
	hud.weapon_name:set_w(hud.ammo_panel:w() - 24)
	hud.weapon_name:set_y(0)
	self:_arrange_weapons()
	hud.danger_zone1:set_top(hud.panel:h() / 2)
	hud.danger_zone1:set_right(hud.crosshair_panel:left())
	hud.danger_zone2:set_top(hud.panel:h() / 2)
	hud.danger_zone2:set_left(hud.crosshair_panel:right())
	hud.ammo_amount:set_size(48 * tweak_data.scale.hud_default_font_multiplier, 32 * tweak_data.scale.hud_default_font_multiplier)
	hud.ammo_amount:set_font_size(tweak_data.hud.ammo_font_size)
	hud.ammo_amount:set_rightbottom(hud.ammo_amount:parent():size())
	hud.ammo_current:set_rightbottom(hud.ammo_amount:leftbottom())
	local player = managers.player:player_unit()
	if alive(player) then
		self:set_ammo_amount(player:inventory():equipped_unit():base():ammo_info())
	end
	local x, y = hud.ammo_amount:righttop()
	self:set_crosshair_offset(tweak_data.weapon.crosshair.DEFAULT_OFFSET)
	self._ch_current_offset = self._ch_offset
	self:_layout_crosshair()
	self:_layout_d_pad()
	self:_layout_secret_assignment_panel()
	for id, data in pairs(self._hud.stored_waypoints) do
		self:add_waypoint(id, data)
	end
end
function HUDManager:add_waypoint(id, data)
	if self._hud.waypoints[id] then
		self:remove_waypoint(id)
	end
	local hud = managers.hud:script(PlayerBase.PLAYER_INFO_HUD)
	if not hud then
		self._hud.stored_waypoints[id] = data
		return
	end
	local icon = data.icon or "wp_standard"
	local text = data.text or "Get to the chopper!"
	local icon, texture_rect = tweak_data.hud_icons:get_icon_data(icon, {
		0,
		0,
		32,
		32
	})
	local bitmap = hud.waypoint_panel:bitmap({
		name = "bitmap" .. id,
		texture = icon,
		texture_rect = texture_rect,
		layer = 2,
		w = texture_rect[3],
		h = texture_rect[4]
	})
	local arrow_icon, arrow_texture_rect = tweak_data.hud_icons:get_icon_data("wp_arrow")
	local arrow = hud.waypoint_panel:bitmap({
		name = "arrow" .. id,
		texture = arrow_icon,
		texture_rect = arrow_texture_rect,
		color = Color.white:with_alpha(0.75),
		visible = false,
		layer = 2,
		w = arrow_texture_rect[3],
		h = arrow_texture_rect[4]
	})
	local distance
	if data.distance then
		distance = hud.waypoint_panel:text({
			name = "distance" .. id,
			text = "16.5",
			color = tweak_data.hud.prime_color,
			font = "fonts/font_univers_530_bold",
			font_size = tweak_data.hud.default_font_size,
			align = "center",
			vertical = "center",
			w = 128,
			h = 24,
			layer = 2
		})
		distance:set_visible(false)
	end
	local timer = data.timer and hud.waypoint_panel:text({
		name = "timer" .. id,
		text = (math.round(data.timer) < 10 and "0" or "") .. math.round(data.timer),
		font = "fonts/font_univers_530_bold",
		font_size = 32,
		align = "center",
		vertical = "center",
		w = 32,
		h = 32,
		layer = 2
	})
	text = hud.waypoint_panel:text({
		name = "text" .. id,
		text = string.upper(" " .. text),
		font = tweak_data.hud.small_font,
		font_size = tweak_data.hud.small_font_size,
		align = "center",
		vertical = "center",
		w = 512,
		h = 24,
		layer = 2
	})
	local _, _, w, _ = text:text_rect()
	text:set_w(w)
	local w, h = bitmap:size()
	self._hud.waypoints[id] = {
		init_data = data,
		state = "present",
		present_timer = data.present_timer or 2,
		bitmap = bitmap,
		arrow = arrow,
		size = Vector3(w, h, 0),
		text = text,
		distance = distance,
		timer_gui = timer,
		timer = data.timer,
		pause_timer = not data.pause_timer and data.timer and 0,
		position = data.position,
		unit = data.unit,
		move_speed = 1
	}
	self._hud.waypoints[id].init_data.position = data.position or data.unit:position()
	local slot = 1
	local t = {}
	for _, data in pairs(self._hud.waypoints) do
		if data.slot then
			t[data.slot] = data.text:w()
		end
	end
	for i = 1, 10 do
		if not t[i] then
			self._hud.waypoints[id].slot = i
			break
		end
	end
	self._hud.waypoints[id].slot_x = 0
	if self._hud.waypoints[id].slot == 2 then
		self._hud.waypoints[id].slot_x = t[1] / 2 + self._hud.waypoints[id].text:w() / 2 + 10
	elseif self._hud.waypoints[id].slot == 3 then
		self._hud.waypoints[id].slot_x = -t[1] / 2 - self._hud.waypoints[id].text:w() / 2 - 10
	elseif self._hud.waypoints[id].slot == 4 then
		self._hud.waypoints[id].slot_x = t[1] / 2 + t[2] + self._hud.waypoints[id].text:w() / 2 + 20
	elseif self._hud.waypoints[id].slot == 5 then
		self._hud.waypoints[id].slot_x = -t[1] / 2 - t[3] - self._hud.waypoints[id].text:w() / 2 - 20
	end
end
function HUDManager:remove_waypoint(id)
	self._hud.stored_waypoints[id] = nil
	if not self._hud.waypoints[id] then
		Application:error("Trying to remove waypoint that hasn't been added! Id: " .. id .. ".")
		return
	end
	local hud = managers.hud:script(PlayerBase.PLAYER_INFO_HUD)
	hud.waypoint_panel:remove(self._hud.waypoints[id].bitmap)
	hud.waypoint_panel:remove(self._hud.waypoints[id].text)
	hud.waypoint_panel:remove(self._hud.waypoints[id].arrow)
	if self._hud.waypoints[id].timer_gui then
		hud.waypoint_panel:remove(self._hud.waypoints[id].timer_gui)
	end
	if self._hud.waypoints[id].distance then
		hud.waypoint_panel:remove(self._hud.waypoints[id].distance)
	end
	self._hud.waypoints[id] = nil
end
function HUDManager:set_waypoint_timer_pause(id, pause)
	if not self._hud.waypoints[id] then
		return
	end
	self._hud.waypoints[id].pause_timer = self._hud.waypoints[id].pause_timer + (pause and 1 or -1)
end
function HUDManager:get_waypoint_data(id)
	return self._hud.waypoints[id]
end
function HUDManager:clear_waypoints()
	for id, _ in pairs(clone(self._hud.waypoints)) do
		self:remove_waypoint(id)
	end
end
function HUDManager:add_item(data)
	local hud = managers.hud:script(PlayerBase.PLAYER_HUD)
	local icon, texture_rect = tweak_data.hud_icons:get_icon_data(data.icon)
	local bitmap = hud.item_panel:bitmap({
		name = "bitmap",
		texture = icon,
		color = Color(0.4, 0.8, 0.8, 0.8),
		layer = 2,
		texture_rect = texture_rect,
		w = 48 * tweak_data.scale.hud_equipment_icon_multiplier,
		h = 48 * tweak_data.scale.hud_equipment_icon_multiplier
	})
	data.amount = data.amount or 0
	local amount = hud.item_panel:text({
		name = "text",
		text = tostring(data.amount),
		font = "fonts/font_univers_530_bold",
		font_size = tweak_data.hud.equipment_font_size,
		color = Color.white,
		align = "right",
		vertical = "bottom",
		layer = 3,
		w = 48 * tweak_data.scale.hud_equipment_icon_multiplier,
		h = 48 * tweak_data.scale.hud_equipment_icon_multiplier
	})
	table.insert(self._hud.items, {
		texture_rect = texture_rect,
		bitmap = bitmap,
		amount = amount
	})
	local sx, sy = hud.item_panel:size()
	bitmap:set_center_x(sx / 2)
	bitmap:set_bottom(self._hud.items[#self._hud.items - 1] and self._hud.items[#self._hud.items - 1].bitmap:top() or sy)
	amount:set_center(bitmap:center())
	if #self._hud.items == 1 then
		self:set_item_selected(1)
	end
	self:_layout_special_equipment()
	return #self._hud.items
end
function HUDManager:remove_item(id)
	local hud = managers.hud:script(PlayerBase.PLAYER_HUD)
	hud.item_panel:remove(self._hud.items[id].bitmap)
	hud.item_panel:remove(self._hud.items[id].amount)
	self._hud.items[id] = nil
	self:_layout_special_equipment()
end
function HUDManager:clear_items()
	local hud = managers.hud:script(PlayerBase.PLAYER_HUD)
	if not hud then
		return
	end
	for _, data in ipairs(self._hud.items) do
		hud.item_panel:remove(data.bitmap)
		hud.item_panel:remove(data.amount)
	end
	hud.selected_item_icon:set_visible(false)
	self._hud.items = {}
	self:_layout_special_equipment()
end
function HUDManager:set_next_item_selected()
	if not self._hud.selected_item or #self._hud.items == 0 then
		return
	end
	self:set_item_selected(self._hud.selected_item + 1 <= #self._hud.items and self._hud.selected_item + 1 or 1)
end
function HUDManager:set_previous_item_selected()
	if not self._hud.selected_item or #self._hud.items == 0 then
		return
	end
	self:set_item_selected(1 <= self._hud.selected_item - 1 and self._hud.selected_item - 1 or #self._hud.items)
end
function HUDManager:set_item_selected(id)
	self._hud.selected_item = id or self._hud.selected_item
	for i, data in ipairs(self._hud.items) do
		data.bitmap:set_color(data.bitmap:color():with_alpha(self._hud.selected_item == i and 1 or 0.4))
	end
	if not self._hud.selected_item or not self._hud.items[self._hud.selected_item] then
		return
	end
	local hud = managers.hud:script(PlayerBase.PLAYER_HUD)
	local align = self._hud.items[self._hud.selected_item].bitmap
	hud.selected_item_icon:set_visible(true)
	hud.selected_item_icon:set_center_y(align:center_y() + align:parent():y())
	hud.selected_item_icon:set_right(align:left() + 0 + align:parent():x())
end
function HUDManager:set_item_amount(index, amount)
	self._hud.items[index].amount:set_text(tostring(amount))
end
function HUDManager:_layout_items()
	local hud = managers.hud:script(PlayerBase.PLAYER_HUD)
	for i, data in ipairs(self._hud.items) do
		local sx, sy = hud.item_panel:size()
		data.bitmap:set_size(data.texture_rect[3] * tweak_data.scale.hud_equipment_icon_multiplier, data.texture_rect[4] * tweak_data.scale.hud_equipment_icon_multiplier)
		data.bitmap:set_center_x(sx / 2)
		data.bitmap:set_bottom(self._hud.items[#self._hud.items - 1] and self._hud.items[#self._hud.items - 1].bitmap:top() or sy)
		if data.amount then
			data.amount:set_font_size(tweak_data.hud.equipment_font_size)
			data.amount:set_size(data.texture_rect[3] * tweak_data.scale.hud_equipment_icon_multiplier, data.texture_rect[4] * tweak_data.scale.hud_equipment_icon_multiplier)
			data.amount:set_center(data.bitmap:center())
		end
	end
	if self._hud.selected_item then
		self:set_item_selected(self._hud.selected_item)
	end
end
function HUDManager:add_special_equipment(data)
	local hud = managers.hud:script(PlayerBase.PLAYER_HUD)
	local icon, texture_rect = tweak_data.hud_icons:get_icon_data(data.icon)
	local bitmap = hud.special_equipment_panel:bitmap({
		name = "bitmap",
		texture = icon,
		color = Color.white,
		layer = 2,
		texture_rect = texture_rect,
		w = texture_rect[3] * tweak_data.scale.hud_equipment_icon_multiplier,
		h = texture_rect[4] * tweak_data.scale.hud_equipment_icon_multiplier
	})
	local amount
	if data.amount then
		amount = hud.special_equipment_panel:text({
			name = "text",
			text = tostring(data.amount),
			font = "fonts/font_univers_530_bold",
			font_size = tweak_data.hud.equipment_font_size,
			color = Color.white,
			align = "right",
			vertical = "bottom",
			layer = 4,
			w = 48 * tweak_data.scale.hud_equipment_icon_multiplier,
			h = 48 * tweak_data.scale.hud_equipment_icon_multiplier
		})
	end
	local last_id = self._hud.special_equipments[#self._hud.special_equipments] and self._hud.special_equipments[#self._hud.special_equipments].id or 0
	local id = last_id + 1
	local flash_icon = hud.special_equipment_panel:bitmap({
		name = "bitmap",
		texture = icon,
		color = tweak_data.hud.prime_color,
		layer = 3,
		texture_rect = texture_rect,
		w = texture_rect[3] * tweak_data.scale.hud_equipment_icon_multiplier,
		h = texture_rect[4] * tweak_data.scale.hud_equipment_icon_multiplier
	})
	table.insert(self._hud.special_equipments, {
		texture_rect = texture_rect,
		bitmap = bitmap,
		amount = amount,
		id = id,
		flash_icon = flash_icon
	})
	local sx, sy = hud.special_equipment_panel:size()
	bitmap:set_center_x(sx / 2)
	bitmap:set_bottom(self._hud.special_equipments[#self._hud.special_equipments - 1] and self._hud.special_equipments[#self._hud.special_equipments - 1].bitmap:top() or sy)
	if amount then
		amount:set_center(bitmap:center())
	end
	flash_icon:set_center(bitmap:center())
	flash_icon:animate(hud.flash_icon, nil, hud.special_equipment_panel)
	return id
end
function HUDManager:remove_special_equipment(id)
	local hud = managers.hud:script(PlayerBase.PLAYER_HUD)
	for i, data in ipairs(self._hud.special_equipments) do
		if data.id == id then
			local data = table.remove(self._hud.special_equipments, i)
			hud.special_equipment_panel:remove(data.bitmap)
			if alive(data.flash_icon) then
				hud.special_equipment_panel:remove(data.flash_icon)
			end
			if data.amount then
				hud.special_equipment_panel:remove(data.amount)
			end
			self:_layout_special_equipments()
			return
		end
	end
end
function HUDManager:_layout_special_equipments()
	print("HUDManager:_layout_special_equipments()")
	local hud = managers.hud:script(PlayerBase.PLAYER_HUD)
	for i, data in ipairs(self._hud.special_equipments) do
		print("data.bitmap", tweak_data.scale.hud_equipment_icon_multiplier)
		local sx, sy = hud.special_equipment_panel:size()
		data.bitmap:set_size(data.texture_rect[3] * tweak_data.scale.hud_equipment_icon_multiplier, data.texture_rect[4] * tweak_data.scale.hud_equipment_icon_multiplier)
		data.bitmap:set_center_x(sx / 2)
		data.bitmap:set_bottom(self._hud.special_equipments[i - 1] and self._hud.special_equipments[i - 1].bitmap:top() or sy)
		if data.amount then
			data.amount:set_font_size(tweak_data.hud.equipment_font_size)
			data.amount:set_size(data.texture_rect[3] * tweak_data.scale.hud_equipment_icon_multiplier, data.texture_rect[4] * tweak_data.scale.hud_equipment_icon_multiplier)
			data.amount:set_center(data.bitmap:center())
		end
		if alive(data.flash_icon) then
			data.flash_icon:set_center(data.bitmap:center())
		end
		if data.amount then
			data.amount:set_center(data.bitmap:center())
		end
	end
end
function HUDManager:clear_special_equipments()
	local hud = managers.hud:script(PlayerBase.PLAYER_HUD)
	for _, data in ipairs(self._hud.special_equipments) do
		if data then
			hud.special_equipment_panel:remove(data.bitmap)
			if data.amount then
				hud.special_equipment_panel:remove(data.amount)
			end
		end
	end
	self._hud.special_equipments = {}
end
function HUDManager:set_special_equipment_amount(id, amount)
	for i, data in ipairs(self._hud.special_equipments) do
		if data.id == id then
			data.amount:set_text(tostring(amount))
			return
		end
	end
end
function HUDManager:_layout_special_equipment()
	local hud = managers.hud:script(PlayerBase.PLAYER_HUD)
	if not hud then
		return
	end
	local offset = 8
	for _, data in ipairs(self._hud.items) do
		local x, y = data.bitmap:size()
		offset = offset + y
	end
	hud.special_equipment_panel:set_bottom(hud.d_pad_panel:top() - offset)
	hud.special_equipment_panel:set_center_x(hud.d_pad_panel:center_x())
end
function HUDManager:_arrange_weapons()
	local hud = managers.hud:script(PlayerBase.PLAYER_HUD)
	local last
	local sx, sy = hud.weapon_panel:size()
	for i = 3, 1, -1 do
		local data = self._hud.weapons[i]
		if data then
			data.bitmap:set_size(data.texture_rect[3] * tweak_data.scale.hud_equipment_icon_multiplier, data.texture_rect[4] * tweak_data.scale.hud_equipment_icon_multiplier)
			data.bitmap:set_center_y(sy / 2)
			data.bitmap:set_right(last and last.bitmap:left() or sx)
			data.amount:set_font_size(tweak_data.hud.weapon_ammo_font_size)
			data.amount:set_size(data.bitmap:size())
			data.amount:set_center(data.bitmap:center())
			if alive(data.b2) then
				local x, y = hud.weapon_panel:lefttop()
				local x_, y_ = data.bitmap:center()
				data.b2:set_center(x + x_, y + y_)
			end
			last = data
		end
	end
end
function HUDManager:add_weapon(data)
	local hud = managers.hud:script(PlayerBase.PLAYER_HUD)
	local icon, texture_rect = tweak_data.hud_icons:get_icon_data(data.unit:base():weapon_tweak_data().hud_icon)
	local bitmap = hud.weapon_panel:bitmap({
		name = "bitmap",
		texture = icon,
		color = Color(0.4, 0.8, 0.8, 0.8),
		layer = 2,
		texture_rect = texture_rect,
		w = 48 * tweak_data.scale.hud_equipment_icon_multiplier,
		h = 48 * tweak_data.scale.hud_equipment_icon_multiplier
	})
	data.amount = data.amount or 0
	local amount = hud.weapon_panel:text({
		name = "text",
		text = tostring(data.amount),
		font = "fonts/font_univers_530_bold",
		font_size = tweak_data.hud.weapon_ammo_font_size,
		color = Color(1, 1, 1, 1),
		align = "right",
		vertical = "bottom",
		layer = 3,
		w = 48 * tweak_data.scale.hud_equipment_icon_multiplier,
		h = 48 * tweak_data.scale.hud_equipment_icon_multiplier
	})
	self._hud.weapons[data.inventory_index] = {
		texture_rect = texture_rect,
		bitmap = bitmap,
		amount = amount,
		inventory_index = data.inventory_index,
		unit = data.unit
	}
	if data.is_equip then
		self:set_weapon_selected_by_inventory_index(data.inventory_index)
	else
		local b2 = hud.panel:bitmap({
			name = "bitmap",
			texture = icon,
			color = Color(0.4, 1, 1, 0.9),
			layer = 3,
			texture_rect = texture_rect,
			w = 48 * tweak_data.scale.hud_equipment_icon_multiplier,
			h = 48 * tweak_data.scale.hud_equipment_icon_multiplier
		})
		local x, y = hud.weapon_panel:lefttop()
		local x1, y2 = bitmap:center()
		b2:set_center(x + x1, y + y2)
		b2:animate(hud.flash_icon)
		self._hud.weapons[data.inventory_index].b2 = b2
	end
	self:_arrange_weapons()
end
function HUDManager:set_weapon_selected_by_inventory_index(inventory_index)
	for i, data in pairs(self._hud.weapons) do
		if data.inventory_index == inventory_index then
			self:_set_weapon_selected(i)
			return
		end
	end
end
function HUDManager:_set_weapon_selected(id)
	self._hud.selected_weapon = id
	for i, data in pairs(self._hud.weapons) do
		data.bitmap:set_color(data.bitmap:color():with_alpha(id == i and 1 or 0.4))
		data.amount:set_visible(id ~= i)
		self:set_weapon_ammo_by_unit(data.unit)
		if id == i then
			self:_set_hud_ammo(data.unit)
		end
	end
end
function HUDManager:_set_hud_ammo(unit)
	local hud = managers.hud:script(PlayerBase.PLAYER_HUD)
	if not hud then
		return
	end
	local hud_ammo = unit:base():weapon_tweak_data().hud_ammo or "guis/textures/ammo"
	hud.ammo_current:set_image(hud_ammo)
	hud.ammo_used:set_image(hud_ammo)
end
function HUDManager:set_weapon_ammo_by_unit(unit)
	for i, data in pairs(self._hud.weapons) do
		if data.unit == unit then
			local _, _, amount = unit:base():ammo_info()
			data.amount:set_text(tostring(amount))
		end
	end
end
function HUDManager:clear_weapons()
	local hud = managers.hud:script(PlayerBase.PLAYER_HUD)
	for _, data in pairs(self._hud.weapons) do
		hud.weapon_panel:remove(data.bitmap)
		hud.weapon_panel:remove(data.amount)
	end
	self._hud.weapons = {}
end
function HUDManager:add_mugshot_by_unit(unit)
	if unit:base().is_local_player then
		return
	end
	local character_name = unit:base():nick_name()
	local name_label_id = managers.hud:_add_name_label({name = character_name, unit = unit})
	unit:unit_data().name_label_id = name_label_id
	local is_husk_player = unit:base().is_husk_player
	local location_id = unit:movement().get_location_id and unit:movement():get_location_id()
	local location_text = string.upper(location_id and managers.localization:text(location_id) or "")
	local character_name_id = managers.criminals:character_name_by_unit(unit)
	for i, data in ipairs(self._hud.mugshots) do
		if data.character_name_id == character_name_id then
			if is_husk_player and not data.peer_id then
				self:_remove_mugshot(data.id)
				break
			else
				unit:unit_data().mugshot_id = data.id
				managers.hud:set_mugshot_normal(unit:unit_data().mugshot_id)
				managers.hud:set_mugshot_armor(unit:unit_data().mugshot_id, 1)
				managers.hud:set_mugshot_health(unit:unit_data().mugshot_id, 1)
				managers.hud:set_mugshot_location(unit:unit_data().mugshot_id, location_id)
				return
			end
		end
	end
	local crew_bonus, peer_id
	if is_husk_player then
		peer_id = unit:network():peer():id()
		crew_bonus = managers.player:get_crew_bonus_by_peer(peer_id)
	end
	local mask_name = managers.criminals:character_data_by_name(character_name_id).mask_icon
	local mask_icon, mask_texture_rect = tweak_data.hud_icons:get_icon_data(mask_name)
	local use_lifebar = is_husk_player and true or false
	local mugshot_id = managers.hud:add_mugshot({
		name = string.upper(character_name),
		use_lifebar = use_lifebar,
		mask_icon = mask_icon,
		mask_texture_rect = mask_texture_rect,
		crew_bonus = crew_bonus,
		peer_id = peer_id,
		character_name_id = character_name_id,
		location_text = location_text
	})
	unit:unit_data().mugshot_id = mugshot_id
	return mugshot_id
end
function HUDManager:add_mugshot_without_unit(char_name, ai, peer_id, name)
	local character_name = name
	local character_name_id = char_name
	local crew_bonus, peer_id
	if not ai then
		crew_bonus = managers.player:get_crew_bonus_by_peer(peer_id)
	end
	local mask_name = managers.criminals:character_data_by_name(character_name_id).mask_icon
	local mask_icon, mask_texture_rect = tweak_data.hud_icons:get_icon_data(mask_name)
	local use_lifebar = not ai
	local mugshot_id = managers.hud:add_mugshot({
		name = string.upper(character_name),
		use_lifebar = use_lifebar,
		mask_icon = mask_icon,
		mask_texture_rect = mask_texture_rect,
		crew_bonus = crew_bonus,
		peer_id = peer_id,
		character_name_id = character_name_id,
		location_text = ""
	})
	return mugshot_id
end
function HUDManager:add_mugshot(data)
	local hud = managers.hud:script(PlayerBase.PLAYER_INFO_HUD)
	local icon = data.icon or "guis/textures/mugshot1"
	local name = data.name or "SIMON ANDERSSON"
	local icon_size = 34
	local pad = 4
	local panel = hud.panel:panel({
		name = "panel",
		w = 176 * tweak_data.scale.hud_mugshot_multiplier,
		h = (icon_size + pad * 2) * tweak_data.scale.hud_mugshot_multiplier
	})
	local gradient = panel:gradient({
		x = 0,
		y = 0,
		w = 176 * tweak_data.scale.hud_mugshot_multiplier,
		h = (icon_size + pad * 2) * tweak_data.scale.hud_mugshot_multiplier,
		layer = 0,
		gradient_points = {
			0,
			Color(0.4, 0, 0, 0),
			1,
			Color(0, 0, 0, 0)
		}
	})
	local mask = panel:bitmap({
		name = "mask",
		texture = data.mask_icon,
		layer = 1,
		texture_rect = data.mask_texture_rect,
		w = icon_size,
		h = icon_size
	})
	local state_icon = panel:bitmap({
		name = "state",
		visible = false,
		texture = data.mask_icon,
		layer = 2,
		texture_rect = data.mask_texture_rect,
		w = icon_size,
		h = icon_size
	})
	local talk_icon, talk_texture_rect = tweak_data.hud_icons:get_icon_data("mugshot_talk")
	local talk = panel:bitmap({
		name = "talk",
		texture = talk_icon,
		visible = false,
		layer = 4,
		texture_rect = talk_texture_rect,
		w = talk_texture_rect[3],
		h = talk_texture_rect[4]
	})
	local voice_icon, voice_texture_rect = tweak_data.hud_icons:get_icon_data("mugshot_talk")
	local voice = panel:bitmap({
		name = "voice",
		texture = voice_icon,
		visible = false,
		layer = 4,
		texture_rect = voice_texture_rect,
		w = voice_texture_rect[3],
		h = voice_texture_rect[4],
		color = Color.white
	})
	local font_size = 14 * tweak_data.scale.hud_mugshot_multiplier
	local name = panel:text({
		name = "text",
		text = name,
		font = tweak_data.hud.small_font,
		font_size = font_size,
		color = Color(1, 1, 1, 1),
		align = "left",
		vertical = "top",
		layer = 1,
		w = 256,
		h = 18
	})
	local state_text = panel:text({
		name = "text",
		visible = false,
		text = "",
		font = tweak_data.hud.small_font,
		font_size = font_size,
		color = tweak_data.hud.prime_color,
		align = "left",
		vertical = "top",
		layer = 1,
		w = 256,
		h = 18
	})
	local timer_text = panel:text({
		name = "timer_text",
		visible = false,
		text = "" .. math.random(60),
		font = tweak_data.hud.small_font,
		font_size = tweak_data.hud.small_font_size,
		color = Color.white,
		align = "center",
		vertical = "center",
		layer = 3,
		w = icon_size,
		h = icon_size
	})
	local location_text = panel:text({
		name = "text",
		visible = true,
		text = data.location_text,
		font = tweak_data.hud.small_font,
		font_size = font_size,
		color = Color.white,
		align = "left",
		vertical = "top",
		layer = 1,
		w = 256,
		h = 18
	})
	local crew_bonus
	if data.crew_bonus then
		local icon, texture_rect = tweak_data.hud_icons:get_icon_data(tweak_data.upgrades.definitions[data.crew_bonus].icon)
		crew_bonus = panel:bitmap({
			name = "crew_bonus",
			texture = icon,
			layer = 1,
			texture_rect = texture_rect,
			w = icon_size / 2,
			h = icon_size / 2
		})
	end
	local equipment = {}
	if data.peer_id then
		local peer_equipment = managers.player:get_synced_equipment_possession(data.peer_id) or {}
		for equip, _ in pairs(peer_equipment) do
			local icon, texture_rect = tweak_data.hud_icons:get_icon_data(tweak_data.equipments.specials[equip].icon)
			icon = panel:bitmap({
				name = equipment,
				texture = icon,
				layer = 1,
				texture_rect = texture_rect,
				w = icon_size / 2,
				h = icon_size / 2
			})
			table.insert(equipment, {equipment = equip, icon = icon})
		end
	end
	local icon, texture_rect, armor_texture_rect, health_texture_rect, health_background, health_armor, health_health
	icon, texture_rect = tweak_data.hud_icons:get_icon_data("mugshot_health_background")
	health_background = panel:bitmap({
		name = "mask",
		visible = data.use_lifebar,
		texture = icon,
		layer = 1,
		texture_rect = texture_rect,
		w = texture_rect[3],
		h = icon_size
	})
	icon, armor_texture_rect = tweak_data.hud_icons:get_icon_data("mugshot_health_armor")
	health_armor = panel:bitmap({
		name = "mask",
		visible = data.use_lifebar,
		texture = icon,
		layer = 3,
		texture_rect = armor_texture_rect,
		w = armor_texture_rect[3],
		h = icon_size
	})
	icon, health_texture_rect = tweak_data.hud_icons:get_icon_data("mugshot_health_health")
	health_health = panel:bitmap({
		name = "mask",
		visible = data.use_lifebar,
		texture = icon,
		layer = 2,
		color = Color(0.5, 0.8, 0.4),
		texture_rect = health_texture_rect,
		w = health_texture_rect[3],
		h = icon_size
	})
	local last_id = self._hud.mugshots[#self._hud.mugshots] and self._hud.mugshots[#self._hud.mugshots].id or 0
	local id = last_id + 1
	table.insert(self._hud.mugshots, {
		panel = panel,
		gradient = gradient,
		mask = mask,
		state_icon = state_icon,
		state_text = state_text,
		location_text = location_text,
		timer_text = timer_text,
		health_background = health_background,
		health_armor = health_armor,
		armor_texture_rect = armor_texture_rect,
		health_health = health_health,
		health_texture_rect = health_texture_rect,
		icon_size = icon_size,
		crew_bonus = crew_bonus,
		equipment = equipment,
		talk = talk,
		voice = voice,
		name = name,
		id = id,
		character_name_id = data.character_name_id,
		peer_id = data.peer_id,
		state_name = "mugshot_normal"
	})
	self:_layout_mugshots()
	return id
end
function HUDManager:remove_hud_info_by_unit(unit)
	if unit:unit_data().name_label_id then
		self:_remove_name_label(unit:unit_data().name_label_id)
	end
end
function HUDManager:remove_mugshot_by_peer_id(peer_id)
	for i, data in ipairs(self._hud.mugshots) do
		if data.peer_id == peer_id then
			self:_remove_mugshot(data.id)
		else
		end
	end
end
function HUDManager:remove_mugshot_by_character_name(character_name)
	for i, data in ipairs(self._hud.mugshots) do
		if data.character_name_id == character_name then
			self:_remove_mugshot(data.id)
		else
		end
	end
end
function HUDManager:remove_mugshot(id)
	self:_remove_mugshot(id)
end
function HUDManager:_remove_mugshot(id)
	local hud = managers.hud:script(PlayerBase.PLAYER_INFO_HUD)
	if not hud then
		return
	end
	for i, data in ipairs(self._hud.mugshots) do
		if data.id == id then
			hud.panel:remove(data.panel)
			table.remove(self._hud.mugshots, i)
		else
		end
	end
	self:_layout_mugshots()
end
function HUDManager:set_mugshot_crewbonus(id, hud_icon_id)
	local hud = managers.hud:script(PlayerBase.PLAYER_INFO_HUD)
	if not hud then
		return
	end
	for i, data in ipairs(self._hud.mugshots) do
		if data.id == id then
			local icon, texture_rect = tweak_data.hud_icons:get_icon_data(hud_icon_id)
			if data.crew_bonus then
				data.crew_bonus:set_image(icon, texture_rect[1], texture_rect[2], data.icon_size / 2, data.icon_size / 2)
			else
				data.crew_bonus = data.panel:bitmap({
					name = "crew_bonus",
					texture = icon,
					layer = 1,
					texture_rect = texture_rect,
					w = data.icon_size / 2,
					h = data.icon_size / 2
				})
			end
			self:_layout_mugshot_equipment(data)
		else
		end
	end
end
function HUDManager:set_mugshot_weapon(id, hud_icon_id)
	for i, data in ipairs(self._hud.mugshots) do
		if data.id == id then
		else
		end
	end
end
function HUDManager:set_mugshot_location(id, location_id)
	if not location_id then
		return
	end
	for i, data in ipairs(self._hud.mugshots) do
		if data.id == id then
			local s = string.upper(managers.localization:text(location_id))
			data.location_text:set_text(string.upper(s))
			local _, _, w, _ = data.location_text:text_rect()
			data.location_text:set_w(w)
			self:_update_mugshot_panel_size(data)
		else
		end
	end
end
function HUDManager:_update_mugshot_panel_size(mugshot)
	mugshot.panel:set_w(64 + mugshot.name:w() + 4 + mugshot.state_text:w() + 4 + mugshot.location_text:w())
end
function HUDManager:set_mugshot_damage_taken(id)
	if not id then
		return
	end
	local hud = managers.hud:script(PlayerBase.PLAYER_INFO_HUD)
	for i, data in ipairs(self._hud.mugshots) do
		if data.id == id then
			data.gradient:animate(hud.mugshot_damage_taken)
		else
		end
	end
end
function HUDManager:set_mugshot_armor(id, amount)
	if not id then
		return
	end
	local hud = managers.hud:script(PlayerBase.PLAYER_INFO_HUD)
	for i, data in ipairs(self._hud.mugshots) do
		if data.id == id then
			data.armor_amount = amount
			self:layout_mugshot_armor(data, amount)
		else
		end
	end
end
function HUDManager:layout_mugshot_armor(data, amount)
	local x = data.armor_texture_rect[1]
	local y = data.armor_texture_rect[2]
	local h = data.health_background:h()
	local y_offset = data.armor_texture_rect[4] * (1 - amount)
	local h_offset = h * (1 - amount)
	data.health_armor:set_texture_rect(x, y + y_offset, data.armor_texture_rect[3], data.armor_texture_rect[4] - y_offset)
	data.health_armor:set_h(h - h_offset)
	data.health_armor:set_bottom(data.health_background:bottom())
end
function HUDManager:set_mugshot_health(id, amount)
	if not id then
		return
	end
	local hud = managers.hud:script(PlayerBase.PLAYER_INFO_HUD)
	for i, data in ipairs(self._hud.mugshots) do
		if data.id == id then
			data.health_amount = amount
			self:layout_mugshot_health(data, amount)
		else
		end
	end
end
function HUDManager:layout_mugshot_health(data, amount)
	local x = data.health_texture_rect[1]
	local y = data.health_texture_rect[2]
	local h = data.health_background:h()
	local y_offset = data.health_texture_rect[4] * (1 - amount)
	local h_offset = h * (1 - amount)
	data.health_health:set_texture_rect(x, y + y_offset, data.health_texture_rect[3], data.health_texture_rect[4] - y_offset)
	data.health_health:set_h(h - h_offset)
	data.health_health:set_bottom(data.health_background:bottom())
	local color = amount < 0.33 and Color(1, 0, 0) or Color(0.5, 0.8, 0.4)
	data.health_health:set_color(color)
end
function HUDManager:set_mugshot_talk(id, active)
	if not id then
		return
	end
	for i, data in ipairs(self._hud.mugshots) do
		if data.id == id then
			if not data.peer_id then
				data.talk:set_visible(active)
			end
		else
		end
	end
end
function HUDManager:set_mugshot_voice(id, active)
	if not id then
		return
	end
	for i, data in ipairs(self._hud.mugshots) do
		if data.id == id then
			data.voice:set_visible(active)
		else
		end
	end
end
function HUDManager:set_mugshot_name(id, name)
	for i, data in ipairs(self._hud.mugshots) do
		if data.id == id then
			data.name:set_text(name)
		else
		end
	end
end
function HUDManager:_get_mugshot_data(id)
	if not id then
		return nil
	end
	for i, data in ipairs(self._hud.mugshots) do
		if data.id == id then
			return data
		end
	end
	return nil
end
function HUDManager:set_mugshot_normal(id)
	local data = self:_get_mugshot_data(id)
	if not data then
		return
	end
	data.state_name = "mugshot_normal"
	data.state_text:set_text("")
	local _, _, w, _ = data.state_text:text_rect()
	data.state_text:set_w(w)
	data.state_icon:set_visible(false)
	data.location_text:set_visible(true)
	data.mask:set_color(data.mask:color():with_alpha(1))
	data.location_text:set_left(data.name:right() + 4)
	self:_update_mugshot_panel_size(data)
end
function HUDManager:set_mugshot_downed(id)
	self:_set_mugshot_state(id, "mugshot_downed", managers.localization:text("debug_mugshot_downed"))
end
function HUDManager:set_mugshot_custody(id)
	self:set_mugshot_talk(id, false)
	local data = self:_set_mugshot_state(id, "mugshot_in_custody", managers.localization:text("debug_mugshot_in_custody"))
	if data then
		data.location_text:set_visible(false)
	end
end
function HUDManager:set_mugshot_cuffed(id)
	self:_set_mugshot_state(id, "mugshot_cuffed", managers.localization:text("debug_mugshot_cuffed"))
end
function HUDManager:set_mugshot_tased(id)
	self:_set_mugshot_state(id, "mugshot_electrified", managers.localization:text("debug_mugshot_electrified"))
end
function HUDManager:_set_mugshot_state(id, icon_data, text)
	local data = self:_get_mugshot_data(id)
	if not data then
		return
	end
	data.state_name = icon_data
	data.mask:set_color(data.mask:color():with_alpha(0.5))
	data.state_icon:set_visible(true)
	local icon, texture_rect = tweak_data.hud_icons:get_icon_data(icon_data)
	data.state_icon:set_image(icon, texture_rect[1], texture_rect[2], texture_rect[3], texture_rect[4])
	data.state_text:set_visible(true)
	data.state_text:set_text(string.upper(text))
	local x, y, w, h = data.state_text:text_rect()
	data.state_text:set_w(w)
	data.location_text:set_left(data.state_text:right() + 4)
	self:_update_mugshot_panel_size(data)
	return data
end
function HUDManager:show_mugshot_timer(id)
	local data = self:_get_mugshot_data(id)
	if not data then
		return
	end
	data.timer_text:set_visible(true)
end
function HUDManager:hide_mugshot_timer(id)
	local data = self:_get_mugshot_data(id)
	if not data then
		return
	end
	data.timer_text:set_visible(false)
end
function HUDManager:set_mugshot_timer(id, time)
	local data = self:_get_mugshot_data(id)
	if not data then
		return
	end
	data.timer_text:set_text(tostring(math.floor(time)))
end
function HUDManager:add_mugshot_equipment(id, equipment)
	if not id then
		return
	end
	for i, data in ipairs(self._hud.mugshots) do
		if data.id == id then
			local icon, texture_rect = tweak_data.hud_icons:get_icon_data(tweak_data.equipments.specials[equipment].icon)
			icon = data.panel:bitmap({
				name = equipment,
				texture = icon,
				layer = 1,
				texture_rect = texture_rect,
				w = data.icon_size / 2,
				h = data.icon_size / 2
			})
			table.insert(data.equipment, {equipment = equipment, icon = icon})
			self:_layout_mugshot_equipment(data)
		else
		end
	end
end
function HUDManager:remove_mugshot_equipment(id, equipment)
	if not id then
		return
	end
	for i, data in ipairs(self._hud.mugshots) do
		if data.id == id then
			for i, e_data in ipairs(data.equipment) do
				if e_data.equipment == equipment then
					data.panel:remove(e_data.icon)
					table.remove(data.equipment, i)
				else
				end
			end
			self:_layout_mugshot_equipment(data)
		else
		end
	end
end
function HUDManager:_layout_mugshot_equipment(data)
	local icon_size = 34
	if data.crew_bonus then
		data.crew_bonus:set_size(icon_size / 2 * tweak_data.scale.hud_health_multiplier, icon_size / 2 * tweak_data.scale.hud_health_multiplier)
		data.crew_bonus:set_left(data.mask:right() + 4 * tweak_data.scale.hud_mugshot_multiplier)
		data.crew_bonus:set_bottom(data.mask:bottom())
	end
	for i, e_data in ipairs(data.equipment) do
		local align = i == 1 and (data.crew_bonus or data.mask) or data.equipment[i - 1].icon
		e_data.icon:set_size(icon_size / 2 * tweak_data.scale.hud_health_multiplier, icon_size / 2 * tweak_data.scale.hud_health_multiplier)
		e_data.icon:set_left(align:right() + 4 * tweak_data.scale.hud_mugshot_multiplier)
		e_data.icon:set_bottom(align:bottom())
	end
end
function HUDManager:clear_mugshots()
	local hud = managers.hud:script(PlayerBase.PLAYER_INFO_HUD)
	for _, mugshot in ipairs(self._hud.mugshots) do
		hud.panel:remove(mugshot.panel)
	end
	self._hud.mugshots = {}
end
function HUDManager:_layout_mugshots()
	local hud = managers.hud:script(PlayerBase.PLAYER_HUD)
	local info_hud = managers.hud:script(PlayerBase.PLAYER_INFO_HUD)
	local _, hy = hud.panel:center()
	for i, mugshot in ipairs(self._hud.mugshots) do
		local alpha = 0.5
		for _, child in ipairs(mugshot.panel:children()) do
			if child.set_color then
			end
		end
		local _, sy = mugshot.panel:size()
		local y = i == 1 and info_hud.health_panel:bottom() or i == 2 and self._hud.mugshots[1].panel:top() - 2 * tweak_data.scale.hud_health_multiplier or i == 3 and self._hud.mugshots[2].panel:top() - 2 * tweak_data.scale.hud_health_multiplier
		local icon_size = 34
		local pad = 4
		local w, h = 176 * tweak_data.scale.hud_mugshot_multiplier, (icon_size + pad * 2) * tweak_data.scale.hud_mugshot_multiplier
		mugshot.panel:set_size(w, h)
		mugshot.panel:set_left(info_hud.health_panel:right() + 2)
		mugshot.panel:set_bottom(y)
		mugshot.gradient:set_size(w, h)
		local _, background_rect = tweak_data.hud_icons:get_icon_data("mugshot_health_background")
		mugshot.health_background:set_size(background_rect[3] * tweak_data.scale.hud_mugshot_multiplier, icon_size * tweak_data.scale.hud_mugshot_multiplier)
		mugshot.health_background:set_left(4 * tweak_data.scale.hud_mugshot_multiplier)
		mugshot.mask:set_size(icon_size * tweak_data.scale.hud_mugshot_multiplier, icon_size * tweak_data.scale.hud_mugshot_multiplier)
		mugshot.mask:set_left(mugshot.health_background:right() + 4 * tweak_data.scale.hud_mugshot_multiplier)
		mugshot.mask:set_center_y(mugshot.gradient:h() / 2)
		mugshot.state_icon:set_shape(mugshot.mask:shape())
		mugshot.talk:set_righttop(mugshot.mask:righttop())
		mugshot.voice:set_righttop(mugshot.mask:righttop())
		mugshot.health_background:set_top(mugshot.mask:top())
		mugshot.health_armor:set_size(background_rect[3] * tweak_data.scale.hud_mugshot_multiplier, icon_size * tweak_data.scale.hud_mugshot_multiplier)
		mugshot.health_armor:set_center_x(mugshot.health_background:center_x())
		mugshot.health_armor:set_bottom(mugshot.health_background:bottom())
		mugshot.health_health:set_size(background_rect[3] * tweak_data.scale.hud_mugshot_multiplier, icon_size * tweak_data.scale.hud_mugshot_multiplier)
		mugshot.health_health:set_center_x(mugshot.health_background:center_x())
		mugshot.health_health:set_bottom(mugshot.health_background:bottom())
		self:layout_mugshot_health(mugshot, mugshot.health_amount or 1)
		self:layout_mugshot_armor(mugshot, mugshot.armor_amount or 1)
		if mugshot.crew_bonus then
			mugshot.crew_bonus:set_left(mugshot.mask:right() + 4)
			mugshot.crew_bonus:set_bottom(mugshot.mask:bottom())
		end
		self:_layout_mugshot_equipment(mugshot)
		local font_size = 14 * tweak_data.scale.hud_mugshot_multiplier
		mugshot.name:set_font_size(font_size)
		mugshot.name:set_kern(tweak_data.scale.mugshot_name_kern)
		local _, _, w, _ = mugshot.name:text_rect()
		mugshot.name:set_w(w)
		mugshot.name:set_left(mugshot.mask:right() + 4 * tweak_data.scale.hud_mugshot_multiplier)
		mugshot.name:set_top(mugshot.mask:top() * tweak_data.scale.hud_mugshot_multiplier)
		mugshot.state_text:set_kern(tweak_data.scale.mugshot_name_kern)
		mugshot.state_text:set_font_size(font_size)
		mugshot.state_text:set_left(mugshot.name:right() + 4)
		mugshot.state_text:set_top(mugshot.name:top())
		mugshot.location_text:set_kern(tweak_data.scale.mugshot_name_kern)
		mugshot.location_text:set_font_size(font_size)
		if mugshot.state_name ~= "mugshot_normal" or not mugshot.name:right() then
		end
		mugshot.location_text:set_left(mugshot.state_text:right() + 4)
		mugshot.location_text:set_top(mugshot.name:top())
		mugshot.panel:set_w(mugshot.name:w() + 4 + mugshot.state_text:w())
		mugshot.timer_text:set_font_size(tweak_data.hud.small_font_size)
		mugshot.timer_text:set_center(mugshot.health_background:center())
		self:_update_mugshot_panel_size(mugshot)
	end
end
function HUDManager:_add_name_label(data)
	local hud = managers.hud:script(PlayerBase.PLAYER_INFO_HUD_FULLSCREEN)
	local last_id = self._hud.name_labels[#self._hud.name_labels] and self._hud.name_labels[#self._hud.name_labels].id or 0
	local id = last_id + 1
	local character_name = data.name
	local peer_id
	local is_husk_player = data.unit:base().is_husk_player
	if is_husk_player then
		peer_id = data.unit:network():peer():id()
		local level = data.unit:network():peer():level()
		data.name = data.name .. " [" .. level .. "]"
	end
	local text = hud.panel:text({
		name = "text",
		text = string.upper(data.name),
		font = "fonts/font_univers_530_bold",
		font_size = tweak_data.hud.name_label_font_size,
		color = Color(1, 1, 1, 1),
		align = "center",
		vertical = "center",
		layer = -2,
		w = 256,
		h = 18
	})
	local _, _, w, h = text:text_rect()
	text:set_size(w + 4, h)
	table.insert(self._hud.name_labels, {
		movement = data.unit:movement(),
		text = text,
		character_name = character_name,
		id = id,
		peer_id = peer_id
	})
	return id
end
function HUDManager:_remove_name_label(id)
	local hud = managers.hud:script(PlayerBase.PLAYER_INFO_HUD_FULLSCREEN)
	if not hud then
		return
	end
	for i, data in ipairs(self._hud.name_labels) do
		if data.id == id then
			hud.panel:remove(data.text)
			table.remove(self._hud.name_labels, i)
		else
		end
	end
end
function HUDManager:update_name_label_by_peer(peer)
	for _, data in pairs(self._hud.name_labels) do
		if data.peer_id == peer:id() then
			local name = data.character_name .. " [" .. peer:level() .. "]"
			data.text:set_text(string.upper(name))
			local _, _, w, h = data.text:text_rect()
			data.text:set_size(w + 4, h)
		else
		end
	end
end
function HUDManager:set_control_info(data)
	local hud = managers.hud:script(PlayerBase.PLAYER_INFO_HUD)
	if not hud then
		return
	end
	hud.control_hostages:set_text(managers.localization:text("debug_control_hostages") .. " " .. data.nr_hostages)
end
function HUDManager:start_anticipation(data)
	local hud = managers.hud:script(PlayerBase.PLAYER_HUD)
	if not hud then
		return
	end
end
function HUDManager:sync_start_anticipation()
end
function HUDManager:check_start_anticipation_music(t)
	if not self._anticipation_music_started and t < 30 then
		self._anticipation_music_started = true
		managers.network:session():send_to_peers("sync_start_anticipation_music")
		self:sync_start_anticipation_music()
	end
end
function HUDManager:sync_start_anticipation_music()
	managers.music:post_event(tweak_data.levels:get_music_event("anticipation"))
end
function HUDManager:start_assault(data)
	self._hud.in_assault = true
	managers.network:session():send_to_peers("sync_start_assault")
	self:sync_start_assault(data)
	managers.mission:call_global_event("start_assault")
end
function HUDManager:sync_start_assault(data)
	managers.music:post_event(tweak_data.levels:get_music_event("assault"))
	local hud = managers.hud:script(PlayerBase.PLAYER_INFO_HUD)
	if not hud then
		return
	end
	if not managers.groupai:state():get_hunt_mode() and managers.groupai:state():bain_state() then
		managers.dialog:queue_dialog("gen_ban_b02c", {})
	end
	hud.assault_image:set_visible(true)
	hud.control_assault_title:set_visible(true)
	hud.control_assault_title:animate(hud.flash_assault_title)
	hud.assault_image:animate(hud.flash_assault_title)
	hud.control_hostages:set_color(Color.white / 1.5)
end
function HUDManager:end_assault(result)
	self._anticipation_music_started = false
	self._hud.in_assault = false
	self:sync_end_assault(result)
	managers.network:session():send_to_peers("sync_end_assault", result)
end
function HUDManager:sync_end_assault(result)
	managers.music:post_event(tweak_data.levels:get_music_event("control"))
	local hud = managers.hud:script(PlayerBase.PLAYER_INFO_HUD)
	if not hud then
		return
	end
	local result_diag = {
		"gen_ban_b12",
		"gen_ban_b11",
		"gen_ban_b10"
	}
	if result and managers.groupai:state():bain_state() then
		managers.dialog:queue_dialog(result_diag[result + 1], {})
	end
	hud.assault_image:set_visible(false)
	hud.control_assault_title:set_visible(false)
	hud.assault_image:stop()
	hud.control_assault_title:stop()
	hud.control_hostages:set_color(Color.white)
end
function HUDManager:setup_anticipation(total_t)
	local exists = self._anticipation_dialogs and true or false
	self._anticipation_dialogs = {}
	if not exists and total_t == 45 then
		table.insert(self._anticipation_dialogs, {time = 45, dialog = 1})
		table.insert(self._anticipation_dialogs, {time = 30, dialog = 2})
	elseif exists and total_t == 45 then
		table.insert(self._anticipation_dialogs, {time = 30, dialog = 6})
	end
	if total_t == 45 then
		table.insert(self._anticipation_dialogs, {time = 20, dialog = 3})
		table.insert(self._anticipation_dialogs, {time = 10, dialog = 4})
	end
	if total_t == 35 then
		table.insert(self._anticipation_dialogs, {time = 20, dialog = 7})
		table.insert(self._anticipation_dialogs, {time = 10, dialog = 4})
	end
	if total_t == 25 then
		table.insert(self._anticipation_dialogs, {time = 10, dialog = 8})
	end
end
function HUDManager:check_anticipation_voice(t)
	if not self._anticipation_dialogs[1] then
		return
	end
	if t < self._anticipation_dialogs[1].time then
		local data = table.remove(self._anticipation_dialogs, 1)
		self:sync_assault_dialog(data.dialog)
		managers.network:session():send_to_peers("sync_assault_dialog", data.dialog)
	end
end
function HUDManager:sync_assault_dialog(index)
	if not managers.groupai:state():bain_state() then
		return
	end
	local dialog = HUDManager.ASSAULT_DIALOGS[index]
	managers.dialog:queue_dialog(dialog, {})
end
function HUDManager:_layout_point_of_no_return_panel()
	local hud = managers.hud:script(PlayerBase.PLAYER_INFO_HUD)
	if not hud then
		return
	end
	hud.point_of_no_return_title:set_text(managers.localization:text(managers.dlc:is_trial() and "time_trial" or "time_escape"))
	hud.point_of_no_return_title:set_font_size(tweak_data.hud.completed_objective_title_font_size)
	local x, y, w, h = hud.point_of_no_return_title:text_rect()
	hud.point_of_no_return_title:set_right(hud.point_of_no_return_panel:w())
	hud.point_of_no_return_title:set_top(0)
	hud.point_of_no_return_title:set_height(h)
	hud.point_of_no_return_panel:set_right(hud.panel:right())
	hud.point_of_no_return_timer:set_font_size(tweak_data.hud.timer_font_size)
	hud.point_of_no_return_timer:set_top(hud.point_of_no_return_title:bottom())
	hud.point_of_no_return_timer:set_left(hud.point_of_no_return_title:left())
	hud.point_of_no_return_title:set_align("right")
	hud.point_of_no_return_timer:set_align("right")
end
function HUDManager:feed_point_of_no_return_timer(time, is_inside)
	local hud = managers.hud:script(PlayerBase.PLAYER_INFO_HUD)
	if not hud then
		return
	end
	time = math.floor(time)
	local minutes = math.floor(time / 60)
	local seconds = math.round(time - minutes * 60)
	local text = (minutes < 10 and "0" .. minutes or minutes) .. ":" .. (seconds < 10 and "0" .. seconds or seconds)
	hud.point_of_no_return_timer:set_text(text .. " ")
	local color = is_inside and Color.green or Color.red
	if self._point_of_no_return_color ~= color then
		self._point_of_no_return_color = color
		hud.point_of_no_return_title:set_color(self._point_of_no_return_color)
		hud.point_of_no_return_timer:set_color(self._point_of_no_return_color)
	end
end
function HUDManager:show_point_of_no_return_timer()
	local hud = managers.hud:script(PlayerBase.PLAYER_INFO_HUD)
	if not hud then
		return
	end
	hud.point_of_no_return_panel:set_visible(true)
end
function HUDManager:flash_point_of_no_return_timer(beep)
	local hud = managers.hud:script(PlayerBase.PLAYER_INFO_HUD)
	if not hud then
		return
	end
	if beep then
		self._sound_source:post_event("last_10_seconds_beep")
	end
	local function flash_timer(o)
		local t = 0
		while t < 0.5 do
			t = t + coroutine.yield()
			local n = 1 - math.sin(t * 180)
			local r = math.lerp(self._point_of_no_return_color.r, 1, n)
			local g = math.lerp(self._point_of_no_return_color.g, 0.8, n)
			local b = math.lerp(self._point_of_no_return_color.b, 0.2, n)
			o:set_color(Color(r, g, b))
			o:set_font_size(math.lerp(tweak_data.hud.timer_font_size, tweak_data.hud.timer_font_size * 1.25, n))
		end
	end
	hud.point_of_no_return_timer:animate(flash_timer)
end
function HUDManager:_layout_secret_assignment_panel()
	local hud = managers.hud:script(PlayerBase.PLAYER_HUD)
	if not hud then
		return
	end
	hud.secret_assignment_title:set_font_size(tweak_data.hud.small_font_size)
	hud.secret_assignment_panel:set_right(hud.panel:right())
	hud.secret_assignment_title:set_top(4)
	hud.secret_assignment_title:set_right(hud.secret_assignment_panel:w() - 4)
	hud.secret_assignment_text:set_font_size(tweak_data.hud.small_font_size)
	hud.secret_assignment_text:set_righttop(hud.secret_assignment_title:rightbottom())
	hud.secret_assignment_status_timer:set_font_size(tweak_data.hud.medium_deafult_font_size)
	hud.secret_assignment_status_timer:set_righttop(hud.secret_assignment_text:rightbottom())
	hud.secret_assignment_status_counter:set_font_size(tweak_data.hud.medium_deafult_font_size)
	hud.secret_assignment_status_counter:set_righttop(hud.secret_assignment_text:rightbottom())
	hud.secret_assignment_description:set_font_size(tweak_data.hud.small_font_size)
	hud.secret_assignment_description:set_right(hud.secret_assignment_panel:width() - 4)
	hud.secret_assignment_description:set_top(hud.secret_assignment_status_timer:bottom() + 16)
end
function HUDManager:present_secret_assignment(params)
	local hud = managers.hud:script(PlayerBase.PLAYER_HUD)
	if not hud then
		return
	end
	local assignment = params.assignment or "Test"
	hud.secret_assignment_text:set_text(string.upper(assignment))
	local description = params.description or "description"
	hud.secret_assignment_description:set_text(string.upper(description))
	hud.secret_assignment_status_timer:set_visible(params.status_time)
	hud.secret_assignment_status_counter:set_visible(params.status_counter)
	local x1, _, w1, _ = hud.secret_assignment_text:text_rect()
	local x2, _, w2, _ = hud.secret_assignment_title:text_rect()
	local w = math.max(w1, w2)
	local x = w1 > w2 and x1 or x2
	hud.secret_assignment_status_timer:set_left(x - hud.secret_assignment_panel:x())
	hud.secret_assignment_panel:animate(hud.present_secret_assignment_panel)
end
function HUDManager:complete_secret_assignment(params)
	local hud = managers.hud:script(PlayerBase.PLAYER_HUD)
	if not hud then
		return
	end
	hud.secret_assignment_panel:animate(hud.complete_secret_assignment_panel, params.success)
end
function HUDManager:feed_secret_assignment_timer(time)
	local hud = managers.hud:script(PlayerBase.PLAYER_HUD)
	if not hud then
		return
	end
	time = math.round(time)
	local minutes = math.floor(time / 60)
	local seconds = math.round(time - minutes * 60)
	local text = (minutes < 10 and "0" .. minutes or minutes) .. ":" .. (seconds < 10 and "0" .. seconds or seconds)
	hud.secret_assignment_status_timer:set_text(text)
end
function HUDManager:feed_secret_assignment_counter(counter, amount)
	local hud = managers.hud:script(PlayerBase.PLAYER_HUD)
	if not hud then
		return
	end
	local text = "" .. counter .. "/" .. amount
	hud.secret_assignment_status_counter:set_text(text)
end
function HUDManager:set_crosshair_offset(offset)
	self._ch_offset = math.lerp(tweak_data.weapon.crosshair.MIN_OFFSET, tweak_data.weapon.crosshair.MAX_OFFSET, offset)
end
function HUDManager:set_crosshair_visible(visible)
	self:script("guis/player_hud").crosshair_panel:set_visible(visible)
end
function HUDManager:set_ammo_amount(max_clip, current_clip, current_left)
	local hud = managers.hud:script(PlayerBase.PLAYER_HUD)
	hud.ammo_amount:set_text(current_left)
	local width = hud.ammo_current:texture_width()
	local height = hud.ammo_current:texture_height()
	local d = max_clip / ((512 - hud.ammo_amount:w() - 140) / width)
	width = width / (d < 1 and 1 or d)
	local scale = max_clip > 100 and tweak_data.scale.hud_ammo_clip_large_multiplier or tweak_data.scale.hud_ammo_clip_multiplier
	hud.ammo_current:set_w(current_clip * width * scale)
	hud.ammo_current:set_h(height * scale)
	hud.ammo_current:set_texture_rect(0, 0, width * current_clip, height)
	hud.ammo_used:set_w((max_clip - current_clip) * width * scale)
	hud.ammo_used:set_h(height * scale)
	hud.ammo_used:set_texture_rect(0, 0, (max_clip - current_clip) * width, height)
	local r, g, b = 1, 1, 1
	if current_clip <= math.round(max_clip / 4) then
		g = current_clip / (max_clip / 2)
		b = current_clip / (max_clip / 2)
	end
	hud.ammo_current:set_color(Color(0.8, r, g, b))
	hud.ammo_current:set_rightbottom(hud.ammo_amount:leftbottom())
	hud.ammo_used:set_color(Color(0.2, r, g, b))
	hud.ammo_used:set_rightbottom(hud.ammo_current:leftbottom())
	self:_set_ammo_warning(max_clip, current_clip, current_left)
end
function HUDManager:_set_ammo_warning(max_clip, current_clip, current_left)
	local hud = managers.hud:script(PlayerBase.PLAYER_HUD)
	local reload = current_clip <= math.round(max_clip / 4)
	local low_ammo = current_left <= math.round(max_clip / 2)
	local out_of_ammo = current_left <= 0
	local visible = reload or low_ammo or out_of_ammo
	hud.ammo_warning_text:set_visible(visible)
	hud.ammo_warning_shadow_text:set_visible(visible)
	if not visible then
		if self._hud.ammo_flash_thread then
			hud.ammo_warning_text:stop(self._hud.ammo_flash_thread)
			self._hud.ammo_flash_thread = nil
		end
		return
	end
	local color = out_of_ammo and Color(0.9, 0.3, 0.3)
	color = color or low_ammo and Color(0.9, 0.9, 0.3)
	color = color or reload and Color.white
	hud.ammo_warning_text:set_color(color)
	self._hud.ammo_flash_thread = self._hud.ammo_flash_thread or hud.ammo_warning_text:animate(hud.flash_warning)
	local text = out_of_ammo and managers.localization:text("debug_no_ammo")
	text = text or low_ammo and managers.localization:text("debug_low_ammo")
	text = text or reload and managers.localization:text("debug_reload")
	hud.ammo_warning_text:set_text(text)
	hud.ammo_warning_shadow_text:set_text(text)
	if low_ammo or out_of_ammo then
		local eq, _ = managers.player:equipment_data_by_name("ammo_bag")
		if eq and 0 < eq.amount then
			managers.hint:show_hint("ammo_bag", nil, nil, {
				BTN_USE_ITEM = managers.localization:btn_macro("use_item")
			})
		else
			managers.hint:show_hint("pickup_ammo")
		end
	elseif reload then
		managers.hint:show_hint("reload", nil, nil, {
			BTN_RELOAD = managers.localization:btn_macro("reload")
		})
	end
end
function HUDManager:set_weapon_name(name_id)
	local hud = managers.hud:script(PlayerBase.PLAYER_HUD)
	self._hud.weapon_name = {}
	self._hud.weapon_name.persistant_time = 3
	self._hud.weapon_name.fade_time = 1.5
	self._hud.weapon_name.fade_timer = self._hud.weapon_name.fade_time
	self._hud.weapon_name.gui = hud.weapon_name
	hud.weapon_name:set_color(hud.weapon_name:color():with_alpha(1))
	hud.weapon_name:set_text(string.upper(managers.localization:text(name_id)))
end
function HUDManager:show_hint(params)
	local hud = managers.hud:script(PlayerBase.PLAYER_INFO_HUD)
	if not hud then
		return
	end
	local text = params.text
	hud.hint_text:set_text(string.upper(text))
	hud.hint_shadow_text:set_text(string.upper(text))
	if self._hud.show_hint_thread then
		hud.hint_text:stop(self._hud.show_hint_thread)
	end
	if params.event then
		self._sound_source:post_event(params.event)
	end
	self._hud.show_hint_thread = hud.hint_text:animate(hud.show_hint, hud.hint_shadow_text, callback(self, self, "show_hint_done"), params.time or 4)
end
function HUDManager:show_hint_done()
	self._hud.show_hint_thread = nil
end
function HUDManager:present_text(params)
	local hud = managers.hud:script(PlayerBase.PLAYER_HUD)
	if not hud then
		return
	end
	self._hud.present_text_queue = self._hud.present_text_queue or {}
	if self._hud.present_text_thread then
		table.insert(self._hud.present_text_queue, params)
		return
	end
	hud.present_text:set_text(params.text)
	if params.event then
		self._sound_source:post_event(params.event)
	end
	self._hud.present_text_thread = hud.present_text:animate(hud.show_present_text, callback(self, self, "present_text_done"), params.time or 1)
end
function HUDManager:present_text_done()
	self._hud.present_text_thread = nil
	local queued = table.remove(self._hud.present_text_queue, 1)
	if queued then
		self:present_text(queued)
	end
end
function HUDManager:present(params)
	self._hud.present_queue = self._hud.present_queue or {}
	if self._hud.present_thread then
		table.insert(self._hud.present_queue, params)
		return
	end
	if params.level_up then
		self:_present_level_up(params)
	end
	if params.present_mid_text then
		self:_present_mid_text(params)
	end
end
function HUDManager:_present_level_up(params)
	local hud = managers.hud:script(self.ANNOUNCEMENT_HUD)
	local full_hud = managers.hud:script(self.ANNOUNCEMENT_HUD_FULLSCREEN)
	local name = managers.upgrades:complete_title(params.upgrade_id, nil) or managers.upgrades:name(params.upgrade_id)
	hud.level_up_text:set_text(self._reached_level_s .. " " .. params.level .. "!")
	local post_fix = " [" .. params.progress[params.tree] .. "/" .. #tweak_data.upgrades.progress[params.tree] - 1 .. "]"
	if params.progress[params.tree] > #tweak_data.upgrades.progress[params.tree] - 1 then
		post_fix = ""
	end
	hud.level_up_current_spec:set_text(self._current_spec_s .. " " .. managers.upgrades:tree_name(params.tree) .. post_fix)
	hud.level_up_unlocked:set_text(string.upper(name))
	if params.upgrade.image then
		local image, texture_rect = tweak_data.hud_icons:get_icon_data(params.upgrade.image)
		hud.level_up_image:set_image(image, texture_rect[1], texture_rect[2], texture_rect[3], texture_rect[4])
	else
		hud.level_up_image:set_image(nil)
	end
	if params.level < managers.experience:level_cap() then
		local next_tree = params.next_tree
		local total = #tweak_data.upgrades.progress[next_tree] - 1
		local progress = math.clamp(params.progress[next_tree] + 1, 0, total)
		local texts = {
			self._tree_assault_s,
			self._tree_sharpshooter_s,
			self._tree_support_s,
			self._tree_technician_s
		}
		hud.next_level_upgrade:set_text(texts[next_tree] .. " [" .. progress .. "/" .. total .. "]")
		local upgrades = params.alternative_upgrades
		local tree_text = managers.upgrades:complete_title(upgrades[next_tree], nil) or managers.upgrades:name(upgrades[next_tree])
		hud.next_level_upgrade_upgrade:set_color(Color.white)
		hud.next_level_upgrade_upgrade:set_text(string.upper(tree_text))
		local image, rect = managers.upgrades:image(upgrades[next_tree])
		hud.next_level_upgrade_image:set_image(image, rect and rect[1], rect and rect[2], rect and rect[3], rect and rect[4])
	end
	self._sound_source:post_event("stinger_levelup")
	self._hud.animate_bg_thread = full_hud.present_background:animate(hud.animate_bg, full_hud.present_background)
	self._hud.present_thread = hud.level_up_left:animate(hud.present_level_up, full_hud.present_background, params.level, callback(self, self, "present_done"), params.time or 1)
end
function HUDManager:present_done()
	if self._hud.animate_bg_thread then
		local full_hud = managers.hud:script(self.ANNOUNCEMENT_HUD_FULLSCREEN)
		full_hud.present_background:stop(self._hud.animate_bg_thread)
		self._hud.animate_bg_thread = nil
	end
	self._hud.present_thread = nil
	local queued = table.remove(self._hud.present_queue, 1)
	if queued then
		if queued.level_up then
			self:_present_level_up(queued)
		end
		if queued.present_mid_text then
			self:_present_mid_text(queued)
		end
	end
end
function HUDManager:_present_mid_text(params)
	local text = params.text
	local hud = managers.hud:script(PlayerBase.PLAYER_INFO_HUD)
	local full_hud = managers.hud:script(PlayerBase.PLAYER_INFO_HUD_FULLSCREEN)
	if not hud then
		return
	end
	self._mid_text_presenting = params
	hud.title_mid_text:set_text(params.title or "ERROR")
	hud.present_mid_text:set_text(string.upper(text))
	hud.present_mid_text:set_font_size(tweak_data.hud.present_mid_text_font_size)
	local x, y, w, h = hud.present_mid_text:text_rect()
	local scale = w > 880 and 880 / w or 1
	local icon, texture_rect
	if params.icon then
		icon, texture_rect = tweak_data.hud_icons:get_icon_data(params.icon)
		hud.present_mid_icon:set_image(icon, texture_rect[1], texture_rect[2], texture_rect[3], texture_rect[4])
		icon = hud.present_mid_icon
	end
	if params.event then
		self._sound_source:post_event(params.event)
	end
	self._hud.present_thread = hud.present_mid_text:animate(hud.show_present_mid_text, full_hud.present_background, callback(self, self, "present_done"), params.time or 1, icon, scale)
	local safe_rect_pixels = managers.viewport:get_safe_rect_pixels()
	full_hud.present_background:set_h(56 * tweak_data.scale.present_multiplier)
	full_hud.present_background:set_center_y(hud.present_mid_icon:center_y() + safe_rect_pixels.y - 2 * tweak_data.scale.present_multiplier)
end
function HUDManager:present_mid_text(params)
	params.present_mid_text = true
	self:present(params)
end
function HUDManager:_kick_crosshair_offset(offset)
	self._ch_current_offset = self._ch_current_offset or 0
	if self._ch_current_offset > tweak_data.weapon.crosshair.MAX_OFFSET then
		self._ch_current_offset = tweak_data.weapon.crosshair.MAX_OFFSET
	end
	self._ch_current_offset = self._ch_current_offset + math.lerp(tweak_data.weapon.crosshair.MIN_KICK_OFFSET, tweak_data.weapon.crosshair.MAX_KICK_OFFSET, offset)
	self:_layout_crosshair()
end
function HUDManager:_layout_crosshair()
	local hud = managers.hud:script(PlayerBase.PLAYER_HUD)
	local x = hud.crosshair_panel:center_x() - hud.crosshair_panel:left()
	local y = hud.crosshair_panel:center_y() - hud.crosshair_panel:top()
	self._hud.crosshair_parts = self._hud.crosshair_parts or {
		hud.crosshair_part_left,
		hud.crosshair_part_top,
		hud.crosshair_part_right,
		hud.crosshair_part_bottom
	}
	for _, part in ipairs(self._hud.crosshair_parts) do
		local rotation = part:rotation()
		part:set_center_x(x + math.cos(rotation) * self._ch_current_offset * tweak_data.scale.hud_crosshair_offset_multiplier)
		part:set_center_y(y + math.sin(rotation) * self._ch_current_offset * tweak_data.scale.hud_crosshair_offset_multiplier)
	end
end
function HUDManager:_layout_d_pad()
	local hud = managers.hud:script(PlayerBase.PLAYER_HUD)
	local x, y = hud.d_pad_panel:size()
	local offset = 12 * tweak_data.scale.hud_equipment_icon_multiplier
	for _, part in ipairs({
		hud.d_pad_up,
		hud.d_pad_down,
		hud.d_pad_left,
		hud.d_pad_right
	}) do
		local rotation = part:rotation()
		part:set_size(16 * tweak_data.scale.hud_equipment_icon_multiplier, 16 * tweak_data.scale.hud_equipment_icon_multiplier)
		part:set_center_x(x / 2 + math.cos(rotation) * offset)
		part:set_center_y(y / 2 + math.sin(rotation) * offset)
		part:set_color(Color.white:with_alpha(0.4))
	end
end
function HUDManager:pressed_d_pad(dir)
	local hud = managers.hud:script(PlayerBase.PLAYER_HUD)
	self._hud.pressed_d_pad[dir] = {}
	local bitmap = dir == "right" and hud.d_pad_right or dir == "left" and hud.d_pad_left or dir == "up" and hud.d_pad_up or dir == "down" and hud.d_pad_down
	local color = (dir == "right" or dir == "left") and Color.white:with_alpha(1) or Color(1, 0, 0.99215686, 0.73333335)
	bitmap:set_color(color)
	self._hud.pressed_d_pad[dir].bitmap = bitmap
	self._hud.pressed_d_pad[dir].timer = 0.25
end
function HUDManager:_update_crosshair_offset(t, dt)
	if self._ch_current_offset and self._ch_current_offset > self._ch_offset then
		self:_kick_crosshair_offset(-dt * 3)
		if self._ch_current_offset < self._ch_offset then
			self._ch_current_offset = self._ch_offset
			self:_layout_crosshair()
		end
	elseif self._ch_current_offset and self._ch_current_offset < self._ch_offset then
		self:_kick_crosshair_offset(dt * 3)
		if self._ch_current_offset > self._ch_offset then
			self._ch_current_offset = self._ch_offset
			self:_layout_crosshair()
		end
	end
	if self._hud.weapon_name then
		self._hud.weapon_name.persistant_time = self._hud.weapon_name.persistant_time - dt
		if self._hud.weapon_name.persistant_time <= 0 then
			self._hud.weapon_name.fade_timer = self._hud.weapon_name.fade_timer - dt
			self._hud.weapon_name.gui:set_color(self._hud.weapon_name.gui:color():with_alpha(self._hud.weapon_name.fade_timer / self._hud.weapon_name.fade_time))
			if 0 >= self._hud.weapon_name.fade_timer then
				self._hud.weapon_name.gui:set_color(self._hud.weapon_name.gui:color():with_alpha(0))
				self._hud.weapon_name = nil
			end
		end
	end
	self:_update_pressed_d_pad(t, dt)
end
function HUDManager:_update_pressed_d_pad(t, dt)
	for dir, data in pairs(self._hud.pressed_d_pad) do
		data.timer = data.timer - dt
		if data.timer < 0 then
			data.bitmap:set_color(Color.white:with_alpha(0.4))
			self._hud.pressed_d_pad[dir] = nil
		end
	end
end
local wp_pos = Vector3()
local wp_dir = Vector3()
local wp_dir_normalized = Vector3()
local wp_cam_forward = Vector3()
local wp_onscreen_direction = Vector3()
local wp_onscreen_target_pos = Vector3()
function HUDManager:_update_waypoints(t, dt)
	local cam = managers.viewport:get_current_camera()
	if not cam then
		return
	end
	local cam_pos = managers.viewport:get_current_camera_position()
	local cam_rot = managers.viewport:get_current_camera_rotation()
	mrotation.y(cam_rot, wp_cam_forward)
	for id, data in pairs(self._hud.waypoints) do
		local panel = data.bitmap:parent()
		if data.state == "dirty" then
		end
		if data.state == "present" then
			data.current_position = Vector3(panel:center_x() + data.slot_x, panel:center_y() + panel:center_y() / 2)
			data.bitmap:set_center_x(data.current_position.x)
			data.bitmap:set_center_y(data.current_position.y)
			data.text:set_center_x(data.bitmap:center_x())
			data.text:set_top(data.bitmap:bottom())
			data.present_timer = data.present_timer - dt
			if data.present_timer <= 0 then
				data.slot = nil
				data.current_scale = 1
				data.state = "present_ended"
				data.text_alpha = 0.5
				data.in_timer = 0
				data.target_scale = 1
				if data.distance then
					data.distance:set_visible(true)
				end
			end
		else
			if data.text_alpha ~= 0 then
				data.text_alpha = math.clamp(data.text_alpha - dt, 0, 1)
				data.text:set_color(data.text:color():with_alpha(data.text_alpha))
			end
			data.position = data.unit and data.unit:position() or data.position
			mvector3.set(wp_pos, self._saferect:world_to_screen(cam, data.position))
			mvector3.set(wp_dir, data.position)
			mvector3.subtract(wp_dir, cam_pos)
			mvector3.set(wp_dir_normalized, wp_dir)
			mvector3.normalize(wp_dir_normalized)
			local dot = mvector3.dot(wp_cam_forward, wp_dir_normalized)
			if dot < 0 or panel:outside(mvector3.x(wp_pos), mvector3.y(wp_pos)) then
				if data.state ~= "offscreen" then
					data.state = "offscreen"
					data.arrow:set_visible(true)
					data.bitmap:set_color(data.bitmap:color():with_alpha(0.75))
					data.off_timer = 0 - (1 - data.in_timer)
					data.target_scale = 0.75
					if data.distance then
						data.distance:set_visible(false)
					end
					if data.timer_gui then
						data.timer_gui:set_visible(false)
					end
				end
				local polar = wp_cam_forward:to_polar_with_reference(wp_dir, math.UP)
				local direction = wp_onscreen_direction
				mvector3.set_static(direction, polar.spin, polar.pitch, 0)
				mvector3.normalize(direction)
				local distance = 150 * tweak_data.scale.hud_crosshair_offset_multiplier
				local pos_x, pos_y = panel:center()
				local target_pos = wp_onscreen_target_pos
				mvector3.set_static(target_pos, pos_x + mvector3.x(direction) * distance, pos_y + mvector3.y(direction) * distance, 0)
				data.off_timer = math.clamp(data.off_timer + dt / data.move_speed, 0, 1)
				if data.off_timer ~= 1 then
					mvector3.set(data.current_position, math.bezier({
						data.current_position,
						data.current_position,
						target_pos,
						target_pos
					}, data.off_timer))
					data.current_scale = math.bezier({
						data.current_scale,
						data.current_scale,
						data.target_scale,
						data.target_scale
					}, data.off_timer)
					data.bitmap:set_size(data.size.x * data.current_scale, data.size.y * data.current_scale)
				else
					mvector3.set(data.current_position, target_pos)
				end
				data.bitmap:set_center(mvector3.x(data.current_position), mvector3.y(data.current_position))
				data.arrow:set_center(mvector3.x(data.current_position) + direction.x * 24, mvector3.y(data.current_position) + direction.y * 24)
				local angle = math.X:angle(direction) * math.sign(direction.y)
				data.arrow:set_rotation(angle)
				if data.text_alpha ~= 0 then
					data.text:set_center_x(data.bitmap:center_x())
					data.text:set_top(data.bitmap:bottom())
				end
			else
				if data.state == "offscreen" then
					data.state = "onscreen"
					data.arrow:set_visible(false)
					data.bitmap:set_color(data.bitmap:color():with_alpha(1))
					data.in_timer = 0 - (1 - data.off_timer)
					data.target_scale = 1
					if data.distance then
						data.distance:set_visible(true)
					end
					if data.timer_gui then
						data.timer_gui:set_visible(true)
					end
				end
				local alpha = 0.8
				if dot > 0.99 then
					alpha = math.clamp((1 - dot) / 0.01, 0.4, alpha)
				end
				if data.bitmap:color().alpha ~= alpha then
					data.bitmap:set_color(data.bitmap:color():with_alpha(alpha))
					if data.distance then
						data.distance:set_color(data.distance:color():with_alpha(alpha))
					end
					if data.timer_gui then
						data.timer_gui:set_color(data.bitmap:color():with_alpha(alpha))
					end
				end
				if data.in_timer ~= 1 then
					data.in_timer = math.clamp(data.in_timer + dt / data.move_speed, 0, 1)
					mvector3.set(data.current_position, math.bezier({
						data.current_position,
						data.current_position,
						wp_pos,
						wp_pos
					}, data.in_timer))
					data.current_scale = math.bezier({
						data.current_scale,
						data.current_scale,
						data.target_scale,
						data.target_scale
					}, data.in_timer)
					data.bitmap:set_size(data.size.x * data.current_scale, data.size.y * data.current_scale)
				else
					mvector3.set(data.current_position, wp_pos)
				end
				data.bitmap:set_center(mvector3.x(data.current_position), mvector3.y(data.current_position))
				if data.text_alpha ~= 0 then
					data.text:set_center_x(data.bitmap:center_x())
					data.text:set_top(data.bitmap:bottom())
				end
				if data.distance then
					local length = wp_dir:length()
					data.distance:set_text(string.format("%.0f", length / 100) .. "m")
					data.distance:set_center_x(data.bitmap:center_x())
					data.distance:set_top(data.bitmap:bottom())
				end
			end
		end
		if data.timer_gui then
			data.timer_gui:set_center_x(data.bitmap:center_x())
			data.timer_gui:set_bottom(data.bitmap:top())
			if data.pause_timer == 0 then
				data.timer = data.timer - dt
				local text = 0 > data.timer and "00" or (math.round(data.timer) < 10 and "0" or "") .. math.round(data.timer)
				data.timer_gui:set_text(text)
			end
		end
	end
end
function HUDManager:set_player_location(location_id)
	if location_id then
		local hud = managers.hud:script(PlayerBase.PLAYER_INFO_HUD)
		hud.location_text:set_text(string.upper(managers.localization:text(location_id)))
	end
end
function HUDManager:reset_player_hpbar()
	local hud = managers.hud:script(PlayerBase.PLAYER_INFO_HUD)
	if not hud then
		return
	end
	local crim_entry = managers.criminals:character_static_data_by_name(managers.criminals:local_character_name())
	if not crim_entry then
		return
	end
	local mask_set = managers.network:session():local_peer():mask_set()
	local health_gui_image = tweak_data.mask_sets[mask_set].health_gui_image
	hud.health_background:set_image(health_gui_image)
	hud.health_health:set_image(health_gui_image)
	hud.health_armor:set_image(health_gui_image)
	local x = tweak_data.mask_sets[mask_set][crim_entry.mask_id].health_gui_offset
	hud.health_health:set_texture_rect(x, 0, 64, 130)
	hud.health_armor:set_texture_rect(x, 130, 64, 130)
	hud.health_background:set_texture_rect(x, 260, 64, 130)
	hud.health_health:set_h(130 * tweak_data.scale.hud_health_multiplier)
	hud.health_health:set_bottom(hud.health_health:parent():h())
	hud.health_armor:set_h(130 * tweak_data.scale.hud_health_multiplier)
	hud.health_armor:set_bottom(hud.health_health:parent():h())
	hud.health_name:set_text(string.upper(managers.localization:text("debug_" .. managers.criminals:local_character_name())))
	local _, _, w, h = hud.health_name:text_rect()
	hud.health_name:set_size(hud.health_panel:w(), h)
end
function HUDManager:set_player_armor(data)
	if data.current == 0 and not data.no_hint then
		managers.hint:show_hint("damage_pad")
	end
	local hud = managers.hud:script(PlayerBase.PLAYER_INFO_HUD)
	if not hud then
		return
	end
	local crim_entry = managers.criminals:character_static_data_by_name(managers.criminals:local_character_name())
	if not crim_entry then
		return
	end
	local mask_set = managers.network:session():local_peer():mask_set()
	local x = tweak_data.mask_sets[mask_set][crim_entry.mask_id].health_gui_offset
	local y = 130
	local y_offset = 130 * (1 - data.current / data.total)
	hud.health_armor:set_texture_rect(x, y + y_offset, 64, 130 - y_offset)
	hud.health_armor:set_h((130 - y_offset) * tweak_data.scale.hud_health_multiplier)
	hud.health_armor:set_bottom(hud.health_health:parent():h())
end
function HUDManager:set_player_health(data)
	local hud = managers.hud:script(PlayerBase.PLAYER_INFO_HUD)
	if not hud then
		return
	end
	local crim_entry = managers.criminals:character_static_data_by_name(managers.criminals:local_character_name())
	if not crim_entry then
		return
	end
	local mask_set = managers.network:session():local_peer():mask_set()
	local x = tweak_data.mask_sets[mask_set][crim_entry.mask_id].health_gui_offset
	local y = 0
	local amount = data.current / data.total
	local y_offset = 130 * (1 - amount)
	hud.health_health:set_texture_rect(x, y + y_offset, 64, 130 - y_offset)
	hud.health_health:set_h((130 - y_offset) * tweak_data.scale.hud_health_multiplier)
	hud.health_health:set_bottom(hud.health_health:parent():h())
	local color = amount < 0.33 and Color(1, 0, 0) or Color(0.5, 0.8, 0.4)
	hud.health_health:set_color(color)
end
function HUDManager:show_scenario(text)
	local scenario = managers.hud:script(self.SCENARIO)
	if self:exists(PlayerBase.PLAYER_HUD) then
		scenario.data.player_hud_visible = scenario.data.player_hud_visible or self:visible(PlayerBase.PLAYER_HUD)
		self:hide(PlayerBase.PLAYER_HUD)
	end
	self:show(self.SCENARIO)
	scenario.scenario:set_text(text)
	scenario.scenario:set_color(scenario.scenario:color():with_alpha(0))
	scenario.data.update = true
	scenario.data.attack_duration = 0.5
	scenario.data.attack = scenario.data.attack_duration
	scenario.data.sustain_duration = 4
	scenario.data.sustain = scenario.data.sustain_duration
	scenario.data.decay_duration = 1
	scenario.data.decay = scenario.data.decay_duration
end
function HUDManager:showing_scenario()
	local scenario = managers.hud:script(self.SCENARIO)
	return scenario.data.update
end
function HUDManager:_update_scenario(t, dt)
	local scenario = managers.hud:script(self.SCENARIO)
	if not scenario.data.update then
		return
	end
	if scenario.data.attack >= 0 then
		scenario.data.attack = scenario.data.attack - dt
		scenario.scenario:set_color(scenario.scenario:color():with_alpha((scenario.data.attack_duration - scenario.data.attack) / scenario.data.attack_duration))
	elseif 0 <= scenario.data.sustain then
		scenario.data.sustain = scenario.data.sustain - dt
	elseif 0 <= scenario.data.decay then
		scenario.data.decay = scenario.data.decay - dt
		scenario.scenario:set_color(scenario.scenario:color():with_alpha(1 - (scenario.data.decay_duration - scenario.data.decay) / scenario.data.decay_duration))
	else
		self:hide(self.SCENARIO)
		if self:exists(PlayerBase.PLAYER_HUD) then
			self[scenario.data.player_hud_visible and "show" or "hide"](self, PlayerBase.PLAYER_HUD)
			scenario.data.player_hud_visible = nil
		end
		scenario.data.update = false
	end
end
function HUDManager:show_interact(data)
	self:remove_interact()
	local hud = self:script(PlayerBase.PLAYER_HUD)
	local text = string.upper(data.text or "Press 'F' to interact")
	local icon, texture_rect = tweak_data.hud_icons:get_icon_data(data.icon)
	hud.interact_text:set_visible(true)
	hud.interact_background:set_visible(true)
	hud.interact_bitmap:set_visible(true)
	hud.interact_text:set_text(text)
	hud.interact_bitmap:set_image(icon, texture_rect[1], texture_rect[2], texture_rect[3], texture_rect[4])
end
function HUDManager:remove_interact()
	local hud = self:script(PlayerBase.PLAYER_HUD)
	if not hud then
		return
	end
	hud.interact_text:set_visible(false)
	hud.interact_background:set_visible(false)
	hud.interact_bitmap:set_visible(false)
end
function HUDManager:show_interaction_bar(current, total)
	local hud = self:script(PlayerBase.PLAYER_HUD)
	if not hud then
		return
	end
	hud.interact_bar:set_w(current)
	hud.interact_bar:set_visible(true)
	hud.interact_bar_stop:set_visible(true)
end
function HUDManager:hide_interaction_bar()
	local hud = self:script(PlayerBase.PLAYER_HUD)
	if not hud then
		return
	end
	hud.interact_bar:set_visible(false)
	hud.interact_bar_stop:set_visible(false)
end
function HUDManager:set_interaction_bar_width(current, total)
	local hud = self:script(PlayerBase.PLAYER_HUD)
	if not hud then
		return
	end
	local _, texture_rect = tweak_data.hud_icons:get_icon_data("interaction_bar")
	local mul = current / total
	local width = mul * (hud.interact_background:width() - 2)
	hud.interact_bar:set_w(width)
	hud.interact_bar:set_texture_rect(texture_rect[1], texture_rect[2], texture_rect[3] * mul, texture_rect[4])
end
function HUDManager:activate_objective(data)
	local hud = self:script(PlayerBase.PLAYER_INFO_HUD)
	if not hud then
		return
	end
	local panel = hud.objectives_panel:panel({
		name = data.text,
		w = 176,
		h = 64
	})
	local text = panel:text({
		name = "text",
		text = "- " .. string.upper(data.text),
		font = tweak_data.hud.small_font,
		font_size = tweak_data.hud.small_font_size,
		color = Color(1, 1, 1, 1),
		align = "left",
		vertical = "center",
		layer = 5,
		w = 256,
		h = 18
	})
	local x, y, w, h = text:text_rect()
	text:set_size(w, h)
	for id, data in pairs(data.sub_objectives) do
		local sub_panel = panel:panel({
			name = id,
			w = 176,
			h = 64
		})
		local sub_text = sub_panel:text({
			name = id,
			text = string.upper(data.text),
			font = tweak_data.hud.small_font,
			font_size = tweak_data.hud.small_font_size,
			color = Color(1, 1, 1, 1),
			align = "left",
			vertical = "center",
			layer = 5,
			w = 256,
			h = 18
		})
		local sub_bitmap = sub_panel:bitmap({
			name = "bitmap" .. id,
			texture = "guis/textures/menu_tickbox",
			layer = 5,
			texture_rect = {
				0,
				0,
				24,
				24
			},
			w = 24,
			h = 24,
			color = Color(1, 1, 1, 1)
		})
		local x, y, w, h = sub_text:text_rect()
		sub_panel:set_left(12)
		sub_text:set_left(sub_bitmap:right() + 4)
		sub_text:set_center_y(sub_bitmap:center_y())
		sub_text:set_size(w, h)
		sub_panel:set_size(w + sub_bitmap:w() + 4 + 12, math.max(h, sub_bitmap:h()))
	end
	if data.amount then
		local amount_text = panel:text({
			name = "amount" .. data.id,
			text = (data.current_amount or 0) .. " / " .. data.amount .. " " .. data.amount_text,
			font = "fonts/font_univers_530_bold",
			font_size = 18,
			color = Color(1, 1, 1, 1),
			align = "left",
			vertical = "center",
			layer = 5,
			w = 256,
			h = 18
		})
		local x, y, w, h = amount_text:text_rect()
		amount_text:set_size(w + 12, h)
		amount_text:set_left(12)
	end
	local panel_h = h
	local panel_w = w
	for i = 1, #panel:children() - 1 do
		panel_h = panel_h + panel:child(i):h()
		panel:child(i):set_top(panel:child(i - 1):bottom())
		local cw, ch = panel:child(i):size()
		panel_w = math.max(cw, panel_w)
	end
	panel:set_size(panel_w, panel_h)
	local h = 8 + hud.objectives_title:h()
	for i = 1, #hud.objectives_panel:children() - 1 do
		hud.objectives_panel:child(i):set_lefttop(hud.objectives_panel:child(i - 1):leftbottom())
		h = h + hud.objectives_panel:child(i):h()
	end
end
function HUDManager:complete_sub_objective(data)
	local hud = self:script(PlayerBase.PLAYER_INFO_HUD)
	if not hud then
		return
	end
	local panel = hud.objectives_panel:child(data.text)
	local sub_panel = panel:child(data.sub_id)
	local bitmap = sub_panel:child("bitmap" .. data.sub_id)
	bitmap:set_image("guis/textures/menu_tickbox", 24, 0, 24, 24)
end
function HUDManager:update_amount_objective(data)
	local hud = self:script(PlayerBase.PLAYER_INFO_HUD)
	if not hud then
		return
	end
	local panel = hud.objectives_panel:child(data.text)
	local amount = panel:child("amount" .. data.id)
	amount:set_text(data.current_amount .. " / " .. data.amount .. " " .. data.amount_text)
end
function HUDManager:complete_objective(data)
	local hud = self:script(PlayerBase.PLAYER_INFO_HUD)
	if not hud then
		return
	end
	if data.remove then
		hud.objectives_panel:child(data.text):animate(hud.remove_objective)
	else
		hud.objectives_panel:child(data.text):animate(hud.complete_objective)
	end
end
function HUDManager:clear_objectives()
	local hud = self:script(PlayerBase.PLAYER_INFO_HUD)
	if not hud then
		return
	end
	local to = #hud.objectives_panel:children() - 1
	for i = 1, to do
		hud.objectives_panel:remove(hud.objectives_panel:child(1))
	end
end
function HUDManager:show_stats_screen()
	local safe = self.STATS_SCREEN_SAFERECT
	local full = self.STATS_SCREEN_FULLSCREEN
	if not self:exists(safe) then
		self:load_hud(safe, false, true, true, {})
		self:load_hud(full, false, true, false, {})
	end
	self:script(safe):layout()
	managers.hud:show(safe)
	managers.hud:show(full)
	local hud = self:script(PlayerBase.PLAYER_HUD)
	if hud then
		hud.secret_assignment_description:set_visible(true)
	end
	self._showing_stats_screen = true
end
function HUDManager:hide_stats_screen()
	self._showing_stats_screen = false
	local safe = self.STATS_SCREEN_SAFERECT
	local full = self.STATS_SCREEN_FULLSCREEN
	if not self:exists(safe) then
		return
	end
	self:script(safe):hide()
	managers.hud:hide(safe)
	managers.hud:hide(full)
	local hud = self:script(PlayerBase.PLAYER_HUD)
	if hud then
		hud.secret_assignment_description:set_visible(false)
	end
end
function HUDManager:showing_stats_screen()
	return self._showing_stats_screen
end
function HUDManager:set_danger_visible(visible, params)
	local hud = self:script(PlayerBase.PLAYER_HUD)
	hud.danger_zone1:set_visible(visible)
	hud.danger_zone2:set_visible(visible)
	if visible then
		local texture = params and params.texture or "guis/textures/warning_gas"
		self._hud.danger_zone1_flash_thread = self._hud.danger_zone1_flash_thread or hud.danger_zone1:animate(hud.flash_warning)
		self._hud.danger_zone2_flash_thread = self._hud.danger_zone2_flash_thread or hud.danger_zone2:animate(hud.flash_warning)
		hud.danger_zone1:set_image(texture)
		hud.danger_zone2:set_image(texture)
	else
		if self._hud.danger_zone1_flash_thread then
			hud.ammo_warning_text:stop(self._hud.danger_zone1_flash_thread)
			self._hud.danger_zone1_flash_thread = nil
		end
		if self._hud.danger_zone2_flash_thread then
			hud.ammo_warning_text:stop(self._hud.danger_zone2_flash_thread)
			self._hud.danger_zone2_flash_thread = nil
		end
	end
end
function HUDManager:wfp_add_member(peer_id)
	local hud = managers.hud:script(self.WAITING_SAFERECT)
	if not hud.members:child(tostring(peer_id)) then
		local peer = managers.network:session():peer(peer_id)
		local name = peer:name()
		local panel = hud.members:panel({
			visible = false,
			name = tostring(peer_id),
			w = hud.members:w(),
			h = hud.members:h() / 3,
			y = #hud.members:children() * (hud.members:h() / 3)
		})
		panel:text({
			name = "name",
			text = name,
			font = "fonts/font_univers_530_bold",
			font_size = 24,
			color = Color(1, 1, 1, 1),
			align = "left",
			vertical = "center",
			y = 0,
			h = 30
		})
		panel:text({
			name = "text",
			text = managers.localization:text("menu_waiting_is_joining"),
			font = "fonts/font_univers_530_bold",
			font_size = 24,
			color = Color(1, 1, 1, 1),
			align = "right",
			vertical = "center",
			y = 0,
			h = 30,
			w = 52 * (PlayerManager.WEAPON_SLOTS + 4) - 16
		})
		for slot = 1, PlayerManager.WEAPON_SLOTS + 4 do
			local x = (slot - 1) * 52
			local icon, texture_rect = tweak_data.hud_icons:get_icon_data("fallback")
			panel:bitmap({
				name = tostring(slot),
				texture = icon,
				layer = 2,
				texture_rect = texture_rect,
				x = x,
				y = 48,
				w = 36,
				h = 36
			})
		end
	end
end
function HUDManager:wfp_member_loaded_done(peer_id)
	local hud = managers.hud:script(self.WAITING_SAFERECT)
	self:wfp_add_member(peer_id)
end
function HUDManager:wfp_set_kit_selection(peer_id, category, id, slot)
	local hud = managers.hud:script(self.WAITING_SAFERECT)
	if not hud.members:child(tostring(peer_id)) then
		return
	end
	local icon, texture_rect = tweak_data.hud_icons:get_icon_data("fallback")
	local panel = hud.members:child(tostring(peer_id))
	if category == "weapon" then
		icon, texture_rect = tweak_data.hud_icons:get_icon_data(tweak_data.weapon[id].hud_icon)
	elseif category == "equipment" then
		slot = slot + PlayerManager.WEAPON_SLOTS
		local equipment_id = tweak_data.upgrades.definitions[id].equipment_id
		icon, texture_rect = tweak_data.hud_icons:get_icon_data(tweak_data.equipments.specials[equipment_id] or tweak_data.equipments[equipment_id].icon)
	elseif category == "crew_bonus" then
		slot = slot + (PlayerManager.WEAPON_SLOTS + 3)
		icon, texture_rect = tweak_data.hud_icons:get_icon_data(tweak_data.upgrades.definitions[id].icon)
	end
	local x = (slot - 1) * 52
	if panel:child(tostring(slot)) then
		panel:child(tostring(slot)):set_image(icon, texture_rect[1], texture_rect[2], texture_rect[3], texture_rect[4])
	else
		panel:bitmap({
			name = tostring(slot),
			texture = icon,
			layer = 2,
			texture_rect = texture_rect,
			x = x,
			y = 48,
			w = 36,
			h = 36
		})
	end
end
function HUDManager:wfp_member_is_not_ready(peer_id)
	local hud = managers.hud:script(self.WAITING_SAFERECT)
	self:wfp_add_member(peer_id)
	local text = hud.members:child(tostring(peer_id)):child("text")
	local peer = managers.network:session():peer(peer_id)
	local name = peer:name()
	text:set_text(managers.localization:text("menu_waiting_is_not_ready"))
end
function HUDManager:wfp_member_ready(peer_id)
	local hud = managers.hud:script(self.WAITING_SAFERECT)
	self:wfp_add_member(peer_id)
	local text = hud.members:child(tostring(peer_id)):child("text")
	local peer = managers.network:session():peer(peer_id)
	local name = peer:name()
	text:set_text(managers.localization:text("menu_waiting_is_ready"))
end
function HUDManager:wfp_remove_member(peer_id)
	local hud = managers.hud:script(self.WAITING_SAFERECT)
	if not hud.members:child(tostring(peer_id)) then
		return
	end
	hud.members:remove(hud.members:child(tostring(peer_id)))
	for i, child in ipairs(hud.members:children()) do
		child:set_y((i - 1) * hud.members:h() / 3)
	end
end
function HUDManager:pd_start_progress(current, total, msg, icon_id)
	local hud = self:script(PlayerBase.PLAYER_DOWNED_HUD)
	if not hud then
		return
	end
	hud.timer:set_visible(false)
	hud.info_text:set_visible(true)
	hud.info_text:set_text(string.upper(managers.localization:text(msg)))
	hud.info_bar:set_w(current)
	hud.info_bar_panel:set_visible(true)
	if icon_id then
		local icon, texture_rect = tweak_data.hud_icons:get_icon_data(icon_id)
		hud.info_bitmap:set_image(icon, texture_rect[1], texture_rect[2], texture_rect[3], texture_rect[4])
		hud.info_bitmap:set_visible(true)
	end
	if self._hud.animate_info_bar_thread then
		hud.info_bar:stop(self._hud.animate_info_bar_thread)
	end
	self._hud.animate_info_bar_thread = hud.info_bar:animate(hud.animate_info_bar, total)
end
function HUDManager:pd_stop_progress()
	local hud = self:script(PlayerBase.PLAYER_DOWNED_HUD)
	if not hud then
		return
	end
	hud.timer:set_visible(true)
	hud.info_text:set_visible(false)
	hud.info_bar_panel:set_visible(false)
	hud.info_bitmap:set_visible(false)
end
function HUDManager:pd_set_info_bar_width(current, total)
	local hud = self:script(PlayerBase.PLAYER_DOWNED_HUD)
	if not hud then
		return
	end
	local _, texture_rect = tweak_data.hud_icons:get_icon_data("interaction_bar")
	local mul = current / total
	local width = mul * (hud.info_bar_background:width() - 2)
	hud.info_bar:set_w(width)
	hud.info_bar:set_texture_rect(texture_rect[1], texture_rect[2], texture_rect[3] * mul, texture_rect[4])
end
function HUDManager:pd_start_timer(data)
	self:pd_stop_timer()
	local time = data.time or 10
	local hud = managers.hud:script(PlayerBase.PLAYER_DOWNED_HUD)
	self._hud.timer_thread = hud.timer:animate(hud.start_timer, time)
	hud.arrest_finished_text:set_visible(false)
end
function HUDManager:pd_pause_timer()
	local hud = managers.hud:script(PlayerBase.PLAYER_DOWNED_HUD)
	hud.pause_timer()
end
function HUDManager:pd_unpause_timer()
	local hud = managers.hud:script(PlayerBase.PLAYER_DOWNED_HUD)
	hud.unpause_timer()
end
function HUDManager:pd_stop_timer()
	local hud = managers.hud:script(PlayerBase.PLAYER_DOWNED_HUD)
	if self._hud.timer_thread then
		hud.timer:stop(self._hud.timer_thread)
		self._hud.timer_thread = nil
	end
	hud.unpause_timer()
end
function HUDManager:pd_show_text()
	local hud = managers.hud:script(PlayerBase.PLAYER_DOWNED_HUD)
	hud.timer:set_visible(false)
	hud.info_text:set_visible(false)
	hud.info_bar_panel:set_visible(false)
	hud.arrest_finished_text:set_visible(true)
end
function HUDManager:pd_hide_text()
	local hud = managers.hud:script(PlayerBase.PLAYER_DOWNED_HUD)
	hud.arrest_finished_text:set_visible(false)
end
function HUDManager:on_simulation_ended()
	self:remove_updator("point_of_no_return")
	self:end_assault()
end
function HUDManager:debug_show_coordinates()
	if self._debug then
		return
	end
	self._debug = {}
	self._debug.ws = Overlay:newgui():create_screen_workspace()
	self._debug.panel = self._debug.ws:panel()
	self._debug.coord = self._debug.panel:text({
		name = "debug_coord",
		x = 14,
		y = 14,
		text = "",
		font = "fonts/font_univers_530_medium",
		font_size = 14,
		color = Color.white,
		layer = 2000
	})
end
function HUDManager:debug_hide_coordinates()
	if not self._debug then
		return
	end
	Overlay:newgui():destroy_workspace(self._debug.ws)
	self._debug = nil
end
function HUDManager:save(data)
	local state = {
		waypoints = {},
		in_assault = self._hud.in_assault
	}
	for id, data in pairs(self._hud.waypoints) do
		state.waypoints[id] = data.init_data
		state.waypoints[id].timer = data.timer
		state.waypoints[id].pause_timer = data.pause_timer
		state.waypoints[id].unit = nil
	end
	data.HUDManager = state
end
function HUDManager:load(data)
	local state = data.HUDManager
	for id, init_data in pairs(state.waypoints) do
		self:add_waypoint(id, init_data)
	end
	if state.in_assault then
		self:sync_start_assault()
	end
end
