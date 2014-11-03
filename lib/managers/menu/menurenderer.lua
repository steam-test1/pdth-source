core:import("CoreMenuRenderer")
require("lib/managers/menu/MenuNodeGui")
require("lib/managers/menu/renderers/MenuNodeTableGui")
require("lib/managers/menu/renderers/MenuNodeStatsGui")
require("lib/managers/menu/renderers/MenuNodeCreditsGui")
require("lib/managers/menu/renderers/MenuNodeButtonLayoutGui")
MenuRenderer = MenuRenderer or class(CoreMenuRenderer.Renderer)
function MenuRenderer:init(logic, ...)
	MenuRenderer.super.init(self, logic, ...)
	self._sound_source = SoundDevice:create_source("MenuRenderer")
end
function MenuRenderer:show_node(node)
	local gui_class = MenuNodeGui
	if node:parameters().gui_class then
		gui_class = CoreSerialize.string_to_classtable(node:parameters().gui_class)
	end
	local parameters = {
		font = tweak_data.menu.default_font,
		background_color = tweak_data.menu.main_menu_background_color:with_alpha(0),
		row_item_color = tweak_data.menu.default_font_row_item_color,
		row_item_hightlight_color = tweak_data.menu.default_hightlight_row_item_color,
		font_size = tweak_data.menu.default_font_size,
		node_gui_class = gui_class,
		spacing = node:parameters().spacing
	}
	MenuRenderer.super.show_node(self, node, parameters)
	if self._menu_video then
		self._video_anim_f = 1
	end
end
function MenuRenderer:open(...)
	MenuRenderer.super.open(self, ...)
	do break end
	if SystemInfo:platform() == Idstring("WIN32") then
		self._menu_video = self._main_panel:video({
			video = "movies/menu",
			loop = true,
			blend_mode = "add"
		})
	end
	self:_layout_video()
	self._menu_bg = self._main_panel:bitmap({
		texture = tweak_data.menu_themes[managers.user:get_setting("menu_theme")].background
	})
	self._menu_stencil_align = "left"
	self._menu_stencil_default_image = "guis/textures/empty"
	self._menu_stencil_image = self._menu_stencil_default_image
	self._menu_stencil = self._main_panel:bitmap({
		texture = self._menu_stencil_image,
		layer = 1,
		blend_mode = "normal"
	})
	self:setup_frames_and_logo()
	self:_layout_menu_bg()
end
function MenuRenderer:setup_frames_and_logo()
	self._upper_frame_gradient = self._main_panel:rect({
		x = 0,
		y = 0,
		w = 0,
		h = 48,
		layer = 1,
		color = Color.black
	})
	self._lower_frame_gradient = self._main_panel:rect({
		x = 0,
		y = 0,
		w = 0,
		h = 48,
		layer = 1,
		color = Color.black
	})
	self._stonecold_small_logo = self.safe_rect_panel:bitmap({
		name = "stonecold_small_logo",
		texture = tweak_data.load_level.stonecold_small_logo,
		texture_rect = {
			0,
			0,
			256,
			56
		},
		layer = 2,
		h = 56
	})
end
function MenuRenderer:layout_frames_and_logo()
	local res = RenderSettings.resolution
	local safe_rect_pixels = managers.viewport:get_safe_rect_pixels()
	self._upper_frame_gradient:set_w(res.x)
	self._upper_frame_gradient:set_h(safe_rect_pixels.y + tweak_data.menu.upper_saferect_border)
	self._lower_frame_gradient:set_w(res.x)
	self._lower_frame_gradient:set_top(safe_rect_pixels.y + safe_rect_pixels.height - tweak_data.menu.upper_saferect_border)
	self._lower_frame_gradient:set_h(safe_rect_pixels.y + tweak_data.menu.upper_saferect_border)
	self._stonecold_small_logo:set_size(256 * tweak_data.scale.menu_logo_multiplier, 56 * tweak_data.scale.menu_logo_multiplier)
	self._stonecold_small_logo:set_right(safe_rect_pixels.width)
	self._stonecold_small_logo:set_bottom(tweak_data.load_level.upper_saferect_border - tweak_data.load_level.border_pad)
end
function MenuRenderer:close(...)
	if self._menu_video then
	end
	MenuRenderer.super.close(self, ...)
end
function MenuRenderer:_layout_menu_bg()
	local res = RenderSettings.resolution
	local safe_rect_pixels = managers.viewport:get_safe_rect_pixels()
	self._menu_bg:set_size(res.y * 2, res.y)
	self._menu_bg:set_center(self._menu_bg:parent():center())
	self:layout_frames_and_logo()
	self:set_stencil_align(self._menu_stencil_align, self._menu_stencil_align_percent)
end
function MenuRenderer:update(t, dt)
	MenuRenderer.super.update(self, t, dt)
	if self._video_anim_t then
		local res = RenderSettings.resolution
		local w = self._menu_video:video_width()
		local h = self._menu_video:video_height()
		local m = h / w
		self._video_anim_t = self._video_anim_t - dt * 2.5
		if self._video_anim_t <= 0 then
			self._video_anim_t = nil
			self._menu_video:set_size(res.y / m, res.y)
			self._menu_video:set_center(res.x / 2, res.y / 2)
		else
			local x = res.x + self._video_anim_t * 2000
			self._menu_video:set_size(x, x * m)
			self._menu_video:set_center(res.x / 2, res.y / 2)
			self._menu_video_bg:set_color(Color(self._video_anim_t, self._video_anim_t, self._video_anim_t))
		end
	end
	if self._video_anim_f then
		local res = RenderSettings.resolution
		local w = self._menu_video:video_width()
		local h = self._menu_video:video_height()
		local m = h / w
		self._video_anim_f = self._video_anim_f - dt * 2.5
		if 0 >= self._video_anim_f then
			self._video_anim_f = nil
			self._menu_video:set_size(res.y / m, res.y)
			self._menu_video:set_center(res.x / 2, res.y / 2)
		else
			local x = res.x + (2000 - self._video_anim_f * 2000)
			self._menu_video:set_size(x, x * m)
			self._menu_video:set_center(res.x / 2, res.y / 2)
			self._menu_video_bg:set_color(Color(self._video_anim_f, self._video_anim_f, self._video_anim_f))
		end
	end
end
local mugshot_stencil = {
	random = {
		"bg_lobby_fullteam",
		65
	},
	undecided = {
		"bg_lobby_fullteam",
		65
	},
	american = {"bg_hoxton", 65},
	german = {"bg_wolf", 55},
	russian = {"bg_dallas", 65},
	spanish = {"bg_chains", 60}
}
function MenuRenderer:highlight_item(item, ...)
	MenuRenderer.super.highlight_item(self, item, ...)
	if self:active_node_gui().name == "play_single_player" then
		local character = managers.network:session():local_peer():character()
		managers.menu:active_menu().renderer:set_stencil_image(mugshot_stencil[character][1])
		managers.menu:active_menu().renderer:set_stencil_align("manual", mugshot_stencil[character][2])
	end
	self:post_event("highlight")
end
function MenuRenderer:trigger_item(item)
	MenuRenderer.super.trigger_item(self, item)
	if item and item:visible() and item:parameters().sound ~= "false" then
		local item_type = item:type()
		if item_type == "" then
			self:post_event("menu_enter")
		elseif item_type == "toggle" then
			if item:value() == "on" then
				self:post_event("box_tick")
			else
				self:post_event("box_untick")
			end
		elseif item_type == "slider" then
			local percentage = item:percentage()
		elseif percentage > 0 and not (percentage < 100) or item_type == "multi_choice" then
		end
	end
end
function MenuRenderer:post_event(event)
	self._sound_source:post_event(event)
end
function MenuRenderer:navigate_back()
	MenuRenderer.super.navigate_back(self)
	self:post_event("menu_exit")
	if self._menu_video then
		self._video_anim_t = 1
	end
end
function MenuRenderer:resolution_changed(...)
	MenuRenderer.super.resolution_changed(self, ...)
	self:_layout_video()
	self:_layout_menu_bg()
end
function MenuRenderer:_layout_video()
	if alive(self._menu_video) then
		local res = RenderSettings.resolution
		local w = self._menu_video:video_width()
		local h = self._menu_video:video_height()
		local m = h / w
		self._menu_video_bg:set_shape(0, 0, res.x, res.y)
		self._menu_video:set_size(res.y / m, res.y)
		self._menu_video:set_center(res.x / 2, res.y / 2)
	end
end
function MenuRenderer:set_bg_visible(visible)
	self._menu_bg:set_visible(visible)
end
function MenuRenderer:set_stencil_image(image)
	if not self._menu_stencil then
		return
	end
	self._menu_stencil_image_name = image
	image = tweak_data.menu_themes[managers.user:get_setting("menu_theme")][image]
	if self._menu_stencil_image == image then
		return
	end
	self._menu_stencil_image = image or self._menu_stencil_default_image
	self._menu_stencil:set_image(self._menu_stencil_image)
	self:set_stencil_align(self._menu_stencil_align, self._menu_stencil_align_percent)
end
function MenuRenderer:refresh_theme()
	self:set_stencil_image(self._menu_stencil_image_name)
	self._menu_bg:set_image(tweak_data.menu_themes[managers.user:get_setting("menu_theme")].background)
end
function MenuRenderer:set_stencil_align(align, percent)
	if not self._menu_stencil then
		return
	end
	self._menu_stencil_align = align
	self._menu_stencil_align_percent = percent
	local res = RenderSettings.resolution
	local safe_rect_pixels = managers.viewport:get_safe_rect_pixels()
	local y = safe_rect_pixels.height - tweak_data.load_level.upper_saferect_border * 2 + 2
	local m = self._menu_stencil:texture_width() / self._menu_stencil:texture_height()
	self._menu_stencil:set_size(y * m, y)
	self._menu_stencil:set_center_y(res.y / 2)
	local w = self._menu_stencil:texture_width()
	local h = self._menu_stencil:texture_height()
	if align == "right" then
		self._menu_stencil:set_texture_rect(0, 0, w, h)
		self._menu_stencil:set_right(res.x)
	elseif align == "left" then
		self._menu_stencil:set_texture_rect(0, 0, w, h)
		self._menu_stencil:set_left(0)
	elseif align == "center" then
		self._menu_stencil:set_texture_rect(0, 0, w, h)
		self._menu_stencil:set_center_x(res.x / 2)
	elseif align == "center-right" then
		self._menu_stencil:set_texture_rect(0, 0, w, h)
		self._menu_stencil:set_center_x(res.x * 0.66)
	elseif align == "center-left" then
		self._menu_stencil:set_texture_rect(0, 0, w, h)
		self._menu_stencil:set_center_x(res.x * 0.33)
	elseif align == "manual" then
		self._menu_stencil:set_texture_rect(0, 0, w, h)
		percent = percent / 100
		self._menu_stencil:set_left(res.x * percent - y * m * percent)
	end
end
function MenuRenderer:current_menu_text(topic_id)
	local ids = {}
	for i, node_gui in ipairs(self._node_gui_stack) do
		table.insert(ids, node_gui.node:parameters().topic_id)
	end
	table.insert(ids, topic_id)
	local s = ""
	for i, id in ipairs(ids) do
		s = s .. managers.localization:text(id)
		s = s .. (i < #ids and " > " or "")
	end
	return s
end
