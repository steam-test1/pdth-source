core:import("CoreMenuRenderer")
require("lib/managers/menu/MenuNodeGui")
require("lib/managers/menu/renderers/MenuNodeTableGui")
require("lib/managers/menu/renderers/MenuNodeStatsGui")
MenuLobbyRenderer = MenuLobbyRenderer or class(CoreMenuRenderer.Renderer)
function MenuLobbyRenderer:init(logic, ...)
	MenuLobbyRenderer.super.init(self, logic, ...)
	self._sound_source = SoundDevice:create_source("MenuLobbyRenderer")
end
function MenuLobbyRenderer:show_node(node)
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
	MenuLobbyRenderer.super.show_node(self, node, parameters)
end
local mugshots = {
	random = "mugshot_random",
	undecided = "mugshot_unassigned",
	american = 1,
	german = 2,
	russian = 3,
	spanish = 4
}
local mugshot_stencil = {
	random = {
		"bg_lobby_fullteam",
		65
	},
	undecided = {
		"bg_lobby_fullteam",
		65
	},
	american = {"bg_hoxton", 80},
	german = {"bg_wolf", 55},
	russian = {"bg_dallas", 65},
	spanish = {"bg_chains", 60}
}
function MenuLobbyRenderer:open(...)
	MenuLobbyRenderer.super.open(self, ...)
	local safe_rect_pixels = managers.viewport:get_safe_rect_pixels()
	self._info_bg_rect = self.safe_rect_panel:rect({
		visible = true,
		x = 0,
		y = tweak_data.load_level.upper_saferect_border,
		w = safe_rect_pixels.width * 0.41,
		h = safe_rect_pixels.height - tweak_data.load_level.upper_saferect_border * 2,
		layer = -1,
		color = Color(0.5, 0, 0, 0)
	})
	self._gui_info_panel = self.safe_rect_panel:panel({
		visible = true,
		layer = 0,
		x = 0,
		y = 0,
		w = 0,
		h = 0
	})
	self._level_id = Global.game_settings.level_id
	local level_data = tweak_data.levels[self._level_id]
	self._level_video = self._gui_info_panel:video({
		video = level_data.movie,
		loop = true,
		blend_mode = "normal",
		w = 320,
		h = 180,
		color = Color(1, 0.4, 0.4, 0.4)
	})
	managers.video:add_video(self._level_video)
	local is_server = Network:is_server()
	local server_peer = is_server and managers.network:session():local_peer() or managers.network:session():server_peer()
	local is_single_player = Global.game_settings.single_player
	local is_multiplayer = not is_single_player
	if not server_peer then
		return
	end
	local font_size = tweak_data.menu.lobby_info_font_size
	self._server_title = self._gui_info_panel:text({
		visible = is_multiplayer,
		name = "server_title",
		text = string.upper(managers.localization:text("menu_lobby_server_title")),
		font = "fonts/font_univers_530_bold",
		font_size = font_size,
		align = "left",
		vertical = "center",
		w = 256,
		h = font_size,
		layer = 1
	})
	self._server_text = self._gui_info_panel:text({
		visible = is_multiplayer,
		name = "server_text",
		text = string.upper("" .. server_peer:name()),
		font = "fonts/font_univers_530_bold",
		color = tweak_data.hud.prime_color,
		font_size = font_size,
		align = "left",
		vertical = "center",
		w = 256,
		h = font_size,
		layer = 1
	})
	self._server_info_title = self._gui_info_panel:text({
		visible = is_multiplayer,
		name = "server_info_title",
		text = string.upper(managers.localization:text("menu_lobby_server_state_title")),
		font = "fonts/font_univers_530_bold",
		font_size = font_size,
		align = "left",
		vertical = "center",
		w = 256,
		h = font_size,
		layer = 1
	})
	self._server_info_text = self._gui_info_panel:text({
		visible = is_multiplayer,
		name = "server_info_text",
		text = string.upper(managers.localization:text(self._server_state_string_id or "menu_lobby_server_state_in_lobby")),
		font = "fonts/font_univers_530_bold",
		color = tweak_data.hud.prime_color,
		font_size = font_size,
		align = "left",
		vertical = "center",
		w = 256,
		h = font_size,
		layer = 1
	})
	self._level_title = self._gui_info_panel:text({
		name = "level_title",
		text = string.upper(managers.localization:text("menu_lobby_campaign_title")),
		font = "fonts/font_univers_530_bold",
		font_size = font_size,
		align = "left",
		vertical = "center",
		w = 256,
		h = font_size,
		layer = 1
	})
	self._level_text = self._gui_info_panel:text({
		name = "level_text",
		text = string.upper("" .. managers.localization:text(level_data.name_id)),
		font = "fonts/font_univers_530_bold",
		color = tweak_data.hud.prime_color,
		font_size = font_size,
		align = "left",
		vertical = "center",
		w = 256,
		h = font_size,
		layer = 1
	})
	self._difficulty_title = self._gui_info_panel:text({
		name = "difficulty_title",
		text = string.upper(managers.localization:text("menu_lobby_difficulty_title")),
		font = "fonts/font_univers_530_bold",
		font_size = font_size,
		align = "left",
		vertical = "center",
		w = 256,
		h = font_size,
		layer = 1
	})
	self._difficulty_text = self._gui_info_panel:text({
		name = "difficulty_text",
		text = "",
		font = "fonts/font_univers_530_bold",
		color = tweak_data.hud.prime_color,
		font_size = font_size,
		align = "left",
		vertical = "center",
		w = 256,
		h = font_size,
		layer = 1
	})
	if is_server then
		self:update_level_id()
		self:update_difficulty()
	else
		self:_update_difficulty(Global.game_settings.difficulty)
	end
	self._player_slots = {}
	for i = 1, is_single_player and 1 or 4 do
		local t = {}
		t.player = {}
		t.free = true
		t.panel = self._gui_info_panel:panel({
			layer = 1,
			w = 256,
			h = 50 * tweak_data.scale.lobby_info_offset_multiplier
		})
		local image, rect = tweak_data.hud_icons:get_icon_data(mugshots.undecided)
		t.mugshot = t.panel:bitmap({
			texture = image,
			texture_rect = rect,
			layer = 1
		})
		local voice_icon, voice_texture_rect = tweak_data.hud_icons:get_icon_data("mugshot_talk")
		t.voice = t.panel:bitmap({
			name = "voice",
			texture = voice_icon,
			visible = false,
			layer = 2,
			texture_rect = voice_texture_rect,
			w = voice_texture_rect[3],
			h = voice_texture_rect[4],
			color = Color.white
		})
		t.bg_rect = self.safe_rect_panel:rect({
			visible = false,
			color = Color.white:with_alpha(0.1),
			layer = 0,
			w = 256,
			h = 42 * tweak_data.scale.lobby_info_offset_multiplier
		})
		t.name = t.panel:text({
			name = "name" .. i,
			text = string.upper(managers.localization:text("menu_lobby_player_slot_available")),
			font = "fonts/font_univers_530_bold",
			font_size = tweak_data.menu.lobby_name_font_size,
			color = Color(1, 0.5, 0.5, 0.5),
			align = "left",
			vertical = "top",
			w = 256,
			h = 24,
			layer = 1
		})
		t.character = t.panel:text({
			visible = true,
			name = "character" .. i,
			text = string.upper(managers.localization:text("debug_random")),
			font = tweak_data.hud.small_font,
			font_size = tweak_data.hud.small_font_size,
			color = Color(1, 0.5, 0.5, 0.5),
			align = "left",
			vertical = "bottom",
			w = 256,
			h = 24,
			layer = 1
		})
		t.level = t.panel:text({
			name = "level" .. i,
			visible = false,
			text = managers.localization:text("menu_lobby_level"),
			font = "fonts/font_univers_530_bold",
			font_size = tweak_data.hud.lobby_name_font_size,
			align = "right",
			vertical = "top",
			w = 256,
			h = 24,
			layer = 1
		})
		t.status = t.panel:text({
			name = "status" .. i,
			visible = true,
			text = "",
			font = tweak_data.hud.small_font,
			font_size = tweak_data.hud.small_font_size,
			align = "right",
			vertical = "bottom",
			w = 256,
			h = 24,
			layer = 1
		})
		t.frame = t.panel:polyline({
			visible = false,
			name = "frame" .. i,
			color = Color.white,
			layer = 1,
			line_width = 1,
			closed = true,
			points = {
				Vector3(),
				Vector3(10, 0, 0),
				Vector3(10, 10, 0),
				Vector3(0, 10, 0)
			}
		})
		t.kit_panel = t.panel:panel({
			visible = false,
			layer = 1,
			w = t.panel:w(),
			h = t.panel:h() / 2
		})
		t.kit_slots = {}
		for slot = 1, PlayerManager.WEAPON_SLOTS + 3 do
			local icon, texture_rect = tweak_data.hud_icons:get_icon_data("fallback")
			local kit_slot = t.kit_panel:bitmap({
				name = tostring(slot),
				texture = icon,
				layer = 0,
				texture_rect = texture_rect,
				x = 0,
				y = 0,
				w = 10,
				h = 10
			})
			table.insert(t.kit_slots, kit_slot)
		end
		t.p_panel = t.panel:panel({
			visible = false,
			layer = 0,
			w = 38,
			h = 17
		})
		t.p_bg = t.p_panel:rect({
			color = Color.black,
			layer = 0,
			w = 38,
			h = 17
		})
		t.p_ass_bg = t.p_panel:rect({
			color = Color(1, 0.5, 0.5, 0.5),
			layer = 1,
			w = 36,
			h = 3
		})
		t.p_ass = t.p_panel:rect({
			color = Color.white,
			layer = 2,
			w = 15,
			h = 3
		})
		t.p_sha_bg = t.p_panel:rect({
			color = Color(1, 0.5, 0.5, 0.5),
			layer = 1,
			w = 36,
			h = 3
		})
		t.p_sha = t.p_panel:rect({
			color = Color.white,
			layer = 2,
			w = 10,
			h = 3
		})
		t.p_sup_bg = t.p_panel:rect({
			color = Color(1, 0.5, 0.5, 0.5),
			layer = 1,
			w = 36,
			h = 3
		})
		t.p_sup = t.p_panel:rect({
			color = Color.white,
			layer = 2,
			w = 24,
			h = 3
		})
		t.p_tec_bg = t.p_panel:rect({
			color = Color(1, 0.5, 0.5, 0.5),
			layer = 1,
			w = 36,
			h = 3
		})
		t.p_tec = t.p_panel:rect({
			color = Color.white,
			layer = 2,
			w = 20,
			h = 3
		})
		table.insert(self._player_slots, t)
	end
	self:_layout_info_panel()
	self:_layout_video()
	self._menu_bg = self._main_panel:bitmap({
		texture = tweak_data.menu_themes[managers.user:get_setting("menu_theme")].background,
		layer = -3
	})
	if not self._no_stencil and not Global.load_level then
		self._menu_stencil_align = "right"
		self._menu_stencil_default_image = "guis/textures/empty"
		self._menu_stencil_image = self._menu_stencil_default_image
		self._menu_stencil = self._main_panel:bitmap({
			texture = self._menu_stencil_image,
			layer = -2,
			blend_mode = "normal"
		})
	end
	self:_entered_menu()
	MenuRenderer.setup_frames_and_logo(self)
	self:_layout_menu_bg()
end
function MenuLobbyRenderer:_entered_menu()
	local is_server = Network:is_server()
	local local_peer = managers.network:session():local_peer()
	managers.network:game():on_entered_lobby()
	self:on_request_lobby_slot_reply()
end
function MenuLobbyRenderer:close(...)
	self:set_choose_character_enabled(true)
	managers.video:remove_video(self._level_video)
	MenuLobbyRenderer.super.close(self, ...)
end
function MenuLobbyRenderer:update_level_id(level_id)
	if self._level_id == (level_id or Global.game_settings.level_id) then
		return
	end
	level_id = level_id or Global.game_settings.level_id
	local level_id_index = tweak_data.levels:get_index_from_level_id(level_id)
	managers.network:session():send_to_peers("lobby_sync_update_level_id", level_id_index)
	self:_update_level_id(level_id)
end
function MenuLobbyRenderer:sync_update_level_id(level_id)
	if self._level_id == level_id then
		return
	end
	Global.game_settings.level_id = level_id
	self:_update_level_id(level_id)
end
function MenuLobbyRenderer:_update_level_id(level_id)
	print(">>>>>>>>>>>>> function MenuLobbyRenderer:_update_level_id( level_id )", level_id, self._level_id)
	Application:stack_dump()
	self._level_id = level_id
	local level_data = tweak_data.levels[level_id]
	managers.video:remove_video(self._level_video)
	self._level_video:set_video(level_data.movie)
	managers.video:add_video(self._level_video)
	self._level_text:set_text(string.upper("" .. managers.localization:text(level_data.name_id)))
end
function MenuLobbyRenderer:update_difficulty()
	local difficulty = Global.game_settings.difficulty
	managers.network:session():send_to_peers_loaded("lobby_sync_update_difficulty", difficulty)
	self:_update_difficulty(difficulty)
end
function MenuLobbyRenderer:sync_update_difficulty(difficulty)
	Global.game_settings.difficulty = difficulty
	self:_update_difficulty(difficulty)
end
function MenuLobbyRenderer:_update_difficulty(difficulty)
	self._difficulty_text:set_text(string.upper(managers.localization:text("menu_difficulty_" .. difficulty)))
end
function MenuLobbyRenderer:set_slot_joining(peer, peer_id)
	local slot = self._player_slots[peer_id]
	if not alive(slot.name) then
		return
	end
	slot.name:set_text(string.upper(peer:name()))
	slot.name:set_color(Color.white)
	self:set_character(peer_id, peer:character())
	slot.status:set_visible(true)
	slot.status:set_text(string.upper(managers.localization:text("menu_waiting_is_joining")))
	slot.peer_id = peer_id
end
function MenuLobbyRenderer:set_slot_ready(peer, peer_id)
	local slot = self._player_slots[peer_id]
	if not slot then
		return
	end
	print("[MenuLobbyRenderer:set_slot_ready]")
	slot.status:set_text(string.upper(managers.localization:text("menu_waiting_is_ready")))
end
function MenuLobbyRenderer:set_dropin_progress(peer_id, progress_percentage)
	local slot = self._player_slots[peer_id]
	if not slot then
		return
	end
	if alive(slot.status) then
		slot.status:set_text(string.upper(managers.localization:text("menu_waiting_is_joining")) .. " " .. tostring(progress_percentage) .. "%")
	end
end
function MenuLobbyRenderer:set_slot_not_ready(peer, peer_id)
	local slot = self._player_slots[peer_id]
	if not slot then
		return
	end
	print("[MenuLobbyRenderer:set_slot_not_ready]")
	slot.status:set_text(string.upper(managers.localization:text("menu_waiting_is_not_ready")))
end
function MenuLobbyRenderer:set_player_slots_kit(slot)
	local peer_id = self._player_slots[slot].peer_id
	for i = 1, PlayerManager.WEAPON_SLOTS do
		local weapon = managers.player:weapon_in_slot(i)
		if weapon then
			self:set_kit_selection(peer_id, "weapon", weapon, i)
		end
	end
	for i = 1, 3 do
		local equipment = managers.player:equipment_in_slot(i)
		if equipment then
			self:set_kit_selection(peer_id, "equipment", equipment, i)
		end
	end
	local crew_bonus = managers.player:crew_bonus_in_slot(1)
	if crew_bonus then
		self:set_kit_selection(peer_id, "crew_bonus", crew_bonus, 1)
	end
end
function MenuLobbyRenderer:set_kit_selection(peer_id, category, id, slot)
	local player_slot = self:get_player_slot_by_peer_id(peer_id)
	if not player_slot or not alive(player_slot.name) then
		return
	end
	local icon, texture_rect
	if category == "weapon" then
		icon, texture_rect = tweak_data.hud_icons:get_icon_data(tweak_data.weapon[id].hud_icon)
	elseif category == "equipment" then
		slot = slot + PlayerManager.WEAPON_SLOTS
		local equipment_id = tweak_data.upgrades.definitions[id].equipment_id
		icon, texture_rect = tweak_data.hud_icons:get_icon_data(tweak_data.equipments.specials[equipment_id] or tweak_data.equipments[equipment_id].icon)
	elseif category == "crew_bonus" then
		slot = slot + (PlayerManager.WEAPON_SLOTS + 2)
		icon, texture_rect = tweak_data.hud_icons:get_icon_data(tweak_data.upgrades.definitions[id].icon)
	end
	local kit_slot = player_slot.kit_slots[slot]
	kit_slot:set_image(icon, texture_rect[1], texture_rect[2], texture_rect[3], texture_rect[4])
end
function MenuLobbyRenderer:set_slot_voice(peer, peer_id, active)
	local slot = self._player_slots[peer_id]
	if not slot then
		return
	end
	slot.voice:set_visible(active)
end
function MenuLobbyRenderer:_set_player_slot(nr, params)
	local my_slot = params.peer_id == managers.network:session():local_peer():id()
	local slot = self._player_slots[nr]
	print("_set_player_slot", nr, my_slot)
	Application:stack_dump()
	slot.free = false
	slot.peer_id = params.peer_id
	slot.params = params
	if not alive(slot.name) then
		return
	end
	slot.name:set_text(string.upper(params.name))
	slot.name:set_color(Color.white)
	slot.frame:set_color(tweak_data.hud.prime_color)
	local _, _, tw = slot.name:text_rect()
	local tp = tw / slot.name:parent():w()
	local rep_txt = #params.name > 14 and tp > 0.6 and "" or managers.localization:text("menu_lobby_level")
	slot.level:set_text(string.upper(rep_txt .. params.level))
	slot.level:set_visible(true)
	if params.status then
		slot.status:set_text(params.status)
	end
	slot.kit_panel:set_visible(params.kit_panel_visible)
	slot.bg_rect:set_visible(my_slot)
	self:set_character(nr, params.character)
	slot.p_panel:set_visible(true)
	self:_layout_slot_progress_panel(slot, params.progress)
	if not slot.join_msg_shown then
		local msg = managers.localization:text("menu_lobby_messenger_title") .. managers.network:session():peer(params.peer_id):name() .. " " .. managers.localization:text("menu_lobby_message_has_joined")
		slot.join_msg_shown = self:sync_chat_message(msg, 1)
		print("slot.join_msg_shown", slot.join_msg_shown)
	end
end
function MenuLobbyRenderer:remove_player_slot_by_peer_id(peer, reason)
	if not self._player_slots then
		return
	end
	local peer_id = peer:id()
	for _, slot in ipairs(self._player_slots) do
		if slot.peer_id == peer_id then
			slot.peer_id = nil
			slot.params = nil
			slot.free = true
			slot.join_msg_shown = nil
			if not alive(slot.name) then
			else
				slot.name:set_text(string.upper(managers.localization:text("menu_lobby_player_slot_available")))
				slot.name:set_color(Color(1, 0.5, 0.5, 0.5))
				slot.level:set_text(string.upper(managers.localization:text("menu_lobby_level")))
				slot.level:set_visible(false)
				slot.status:set_text(string.upper(""))
				slot.status:set_visible(false)
				slot.character:set_text(string.upper(managers.localization:text("debug_random")))
				slot.character:set_color(Color(1, 0.5, 0.5, 0.5))
				local image, rect = tweak_data.hud_icons:get_icon_data(mugshots.undecided)
				slot.mugshot:set_image(image, rect[1], rect[2], rect[3], rect[4])
				slot.frame:set_color(Color.white)
				slot.bg_rect:set_visible(false)
				slot.p_panel:set_visible(false)
				slot.voice:set_visible(false)
				slot.kit_panel:set_visible(false)
				for i, kit_slot in ipairs(slot.kit_slots) do
					local icon, texture_rect = tweak_data.hud_icons:get_icon_data("fallback")
					kit_slot:set_image(icon, texture_rect[1], texture_rect[2], texture_rect[3], texture_rect[4])
				end
				reason = reason or "left"
				local peer_name = peer:name()
				local reason_msg = managers.localization:text("menu_lobby_message_has_" .. reason, {NAME = peer_name})
				local prefix = reason == "removed_dead" and "" or peer_name .. " "
				local msg = managers.localization:text("menu_lobby_messenger_title") .. prefix .. reason_msg
				self:sync_chat_message(msg, 1)
			end
		else
		end
	end
end
function MenuLobbyRenderer:set_character(id, character)
	local slot = self._player_slots[id]
	slot.character:set_text(string.upper(managers.localization:text("debug_" .. character)))
	slot.character:set_color(Color.white)
	local mugshot
	if character == "random" then
		mugshot = mugshots.random
	else
		local mask_set = managers.network:session():peer(id):mask_set()
		local mask_id = mugshots[character]
		local set = tweak_data.mask_sets[mask_set][mask_id]
		mugshot = set.mask_icon
	end
	local image, rect = tweak_data.hud_icons:get_icon_data(mugshot)
	slot.mugshot:set_image(image, rect[1], rect[2], rect[3], rect[4])
	if managers.network:session():local_peer():id() == id then
		managers.menu:active_menu().renderer:set_stencil_image(mugshot_stencil[character][1])
		managers.menu:active_menu().renderer:set_stencil_align("manual", mugshot_stencil[character][2])
	end
end
function MenuLobbyRenderer:set_choose_character_enabled(enabled)
	for _, node in ipairs(self._logic._node_stack) do
		for _, item in ipairs(node:items()) do
			if item:parameters().name == "choose_character" then
				item:set_enabled(enabled)
			else
			end
		end
	end
end
function MenuLobbyRenderer:set_server_state(state)
	local s = ""
	if state == "loading" then
		s = string.upper(managers.localization:text("menu_lobby_server_state_loading"))
		self:set_choose_character_enabled(false)
	end
	self._server_info_text:set_text(string.upper(s))
	local msg = managers.localization:text("menu_lobby_messenger_title") .. managers.localization:text("menu_lobby_message_server_is_loading")
	self:sync_chat_message(msg, 1)
end
function MenuLobbyRenderer:on_request_lobby_slot_reply()
	local local_peer = managers.network:session():local_peer()
	local local_peer_id = local_peer:id()
	local level = managers.experience:current_level()
	local character = local_peer:character()
	local progress = managers.upgrades:progress()
	local mask_set = local_peer:mask_set()
	self:_set_player_slot(local_peer_id, {
		name = local_peer:name(),
		peer_id = local_peer_id,
		level = level,
		character = character,
		progress = progress
	})
	managers.network:session():send_to_peers_loaded("lobby_info", local_peer_id, level, character, mask_set, progress[1], progress[2], progress[3], progress[4] or -1)
end
function MenuLobbyRenderer:get_player_slot_by_peer_id(id)
	for _, slot in ipairs(self._player_slots) do
		if slot.peer_id and slot.peer_id == id then
			return slot
		end
	end
	return self._player_slots[id]
end
function MenuLobbyRenderer:get_player_slot_nr_by_peer_id(id)
	for i, slot in ipairs(self._player_slots) do
		if slot.peer_id and slot.peer_id == id then
			return i
		end
	end
	return nil
end
function MenuLobbyRenderer:sync_chat_message(message, id)
	for _, node_gui in ipairs(self._node_gui_stack) do
		local row_item_chat = node_gui:row_item_by_name("chat")
		if row_item_chat then
			node_gui:sync_say(message, row_item_chat, id)
			return true
		end
	end
	return false
end
function MenuLobbyRenderer:update(t, dt)
	MenuLobbyRenderer.super.update(self, t, dt)
end
function MenuLobbyRenderer:highlight_item(item, ...)
	MenuLobbyRenderer.super.highlight_item(self, item, ...)
	local character = managers.network:session():local_peer():character()
	managers.menu:active_menu().renderer:set_stencil_image(mugshot_stencil[character][1])
	managers.menu:active_menu().renderer:set_stencil_align("manual", mugshot_stencil[character][2])
	self:post_event("highlight")
end
function MenuLobbyRenderer:trigger_item(item)
	MenuRenderer.super.trigger_item(self, item)
	if item and item:parameters().sound ~= "false" then
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
function MenuLobbyRenderer:post_event(event)
	self._sound_source:post_event(event)
end
function MenuLobbyRenderer:navigate_back()
	MenuLobbyRenderer.super.navigate_back(self)
	self:post_event("menu_exit")
end
function MenuLobbyRenderer:resolution_changed(...)
	MenuLobbyRenderer.super.resolution_changed(self, ...)
	local safe_rect_pixels = managers.viewport:get_safe_rect_pixels()
	self._info_bg_rect:set_shape(0, tweak_data.load_level.upper_saferect_border, safe_rect_pixels.width * 0.41, safe_rect_pixels.height - tweak_data.load_level.upper_saferect_border * 2)
	self:_layout_info_panel()
	self:_layout_video()
	self:_layout_menu_bg()
end
function MenuLobbyRenderer:_layout_menu_bg()
	local res = RenderSettings.resolution
	local safe_rect_pixels = managers.viewport:get_safe_rect_pixels()
	self._menu_bg:set_size(res.y * 2, res.y)
	self._menu_bg:set_center(self._menu_bg:parent():center())
	self:set_stencil_align(self._menu_stencil_align, self._menu_stencil_align_percent)
	MenuRenderer.layout_frames_and_logo(self)
end
function MenuLobbyRenderer:_layout_slot_progress_panel(slot, progress)
	print("MenuLobbyRenderer:_layout_slot_progress_panel()", slot, progress)
	local h = 16
	local sh = 4
	if progress[4] then
		h = 17
		sh = 3
	end
	slot.p_panel:set_size(38 * tweak_data.scale.lobby_info_offset_multiplier, h)
	slot.p_bg:set_size(slot.p_panel:size())
	slot.p_ass_bg:set_size(slot.p_panel:w() - 2, sh)
	slot.p_sha_bg:set_size(slot.p_panel:w() - 2, sh)
	slot.p_sup_bg:set_size(slot.p_panel:w() - 2, sh)
	slot.p_tec_bg:set_size(slot.p_panel:w() - 2, sh)
	if progress[4] then
		slot.p_tec:set_visible(true)
		slot.p_tec_bg:set_visible(true)
		slot.p_ass_bg:set_position(1, 1)
		slot.p_sha_bg:set_position(1, 5)
		slot.p_sup_bg:set_position(1, 9)
		slot.p_tec_bg:set_position(1, 13)
	else
		slot.p_tec:set_visible(false)
		slot.p_tec_bg:set_visible(false)
		slot.p_ass_bg:set_position(1, 1)
		slot.p_sha_bg:set_position(1, 6)
		slot.p_sup_bg:set_position(1, 11)
	end
	slot.p_ass:set_shape(slot.p_ass_bg:shape())
	slot.p_sha:set_shape(slot.p_sha_bg:shape())
	slot.p_sup:set_shape(slot.p_sup_bg:shape())
	slot.p_tec:set_shape(slot.p_tec_bg:shape())
	slot.p_ass:set_w(slot.params and slot.p_ass_bg:w() * (progress[1] / 49) or slot.p_ass:w())
	slot.p_sha:set_w(slot.params and slot.p_sha_bg:w() * (progress[2] / 49) or slot.p_sha:w())
	slot.p_sup:set_w(slot.params and slot.p_sup_bg:w() * (progress[3] / 49) or slot.p_sup:w())
	if slot.params then
	else
	end
	slot.p_tec:set_w(slot.p_sup_bg:w() * ((progress[4] or 0) / 49) or slot.p_tec:w())
end
function MenuLobbyRenderer:_layout_info_panel()
	local res = RenderSettings.resolution
	local safe_rect = managers.viewport:get_safe_rect_pixels()
	local is_single_player = Global.game_settings.single_player
	local is_multiplayer = not is_single_player
	self._gui_info_panel:set_shape(self._info_bg_rect:x() + tweak_data.menu.info_padding, self._info_bg_rect:y() + tweak_data.menu.info_padding, self._info_bg_rect:w() - tweak_data.menu.info_padding * 2, self._info_bg_rect:h() - tweak_data.menu.info_padding * 2)
	local font_size = tweak_data.menu.lobby_info_font_size
	local offset = 22 * tweak_data.scale.lobby_info_offset_multiplier
	self._server_title:set_font_size(font_size)
	self._server_text:set_font_size(font_size)
	local x, y, w, h = self._server_title:text_rect()
	self._server_title:set_x(tweak_data.menu.info_padding)
	self._server_title:set_y(tweak_data.menu.info_padding)
	self._server_title:set_w(w)
	self._server_text:set_lefttop(self._server_title:righttop())
	self._server_text:set_w(self._gui_info_panel:w())
	self._server_info_title:set_font_size(font_size)
	self._server_info_text:set_font_size(font_size)
	local x, y, w, h = self._server_info_title:text_rect()
	self._server_info_title:set_x(tweak_data.menu.info_padding)
	self._server_info_title:set_y(tweak_data.menu.info_padding + offset)
	self._server_info_title:set_w(w)
	self._server_info_text:set_lefttop(self._server_info_title:righttop())
	self._server_info_text:set_w(self._gui_info_panel:w())
	self._level_title:set_font_size(font_size)
	self._level_text:set_font_size(font_size)
	local x, y, w, h = self._level_title:text_rect()
	self._level_title:set_x(tweak_data.menu.info_padding)
	self._level_title:set_y(is_multiplayer and tweak_data.menu.info_padding + offset * 2 or tweak_data.menu.info_padding)
	self._level_title:set_w(w)
	self._level_text:set_lefttop(self._level_title:righttop())
	self._level_text:set_w(self._gui_info_panel:w())
	self._difficulty_title:set_font_size(font_size)
	self._difficulty_text:set_font_size(font_size)
	local x, y, w, h = self._difficulty_title:text_rect()
	self._difficulty_title:set_x(tweak_data.menu.info_padding)
	self._difficulty_title:set_y(tweak_data.menu.info_padding + offset * (is_multiplayer and 3 or 1))
	self._difficulty_title:set_w(w)
	self._difficulty_text:set_lefttop(self._difficulty_title:righttop())
	self._difficulty_text:set_w(self._gui_info_panel:w())
	local pad = 3 * tweak_data.scale.lobby_info_offset_multiplier
	for i, slot in ipairs(self._player_slots) do
		slot.panel:set_h(50 * tweak_data.scale.lobby_info_offset_multiplier)
		slot.panel:set_w(slot.panel:parent():w())
		slot.panel:set_bottom(self._gui_info_panel:h() - (4 - i) * (slot.panel:h() + 4))
		if slot.params then
			self:_layout_slot_progress_panel(slot, slot.params.progress)
		end
		slot.mugshot:set_size(slot.panel:h() - pad, slot.panel:h() - pad)
		slot.mugshot:set_x(0)
		slot.mugshot:set_center_y(slot.panel:h() / 2)
		slot.voice:set_righttop(slot.mugshot:righttop())
		local x, y, w, h = slot.level:text_rect()
		slot.level:set_w(100)
		slot.bg_rect:set_position(0, 0)
		slot.bg_rect:set_size(self._info_bg_rect:w(), slot.panel:h())
		slot.bg_rect:set_position(self._info_bg_rect:x(), self._gui_info_panel:y() + slot.panel:y())
		slot.name:set_font_size(tweak_data.menu.lobby_name_font_size)
		slot.name:set_lefttop(slot.mugshot:w() + pad, pad)
		slot.level:set_top(0 + pad)
		slot.p_panel:set_w(38 * tweak_data.scale.lobby_info_offset_multiplier)
		slot.p_panel:set_top(slot.level:top())
		slot.p_panel:set_right(slot.p_panel:parent():w())
		slot.level:set_font_size(tweak_data.menu.lobby_name_font_size)
		slot.level:set_right(slot.p_panel:left() - pad)
		slot.status:set_font_size(tweak_data.menu.small_font_size)
		slot.status:set_right(slot.panel:w() - pad)
		slot.status:set_bottom(slot.panel:h() - pad)
		slot.character:set_font_size(tweak_data.menu.small_font_size)
		slot.character:set_leftbottom(slot.mugshot:w() + pad, slot.panel:h() - pad)
		local bg = slot.bg_rect
		slot.frame:set_points({
			Vector3(bg:left(), bg:top(), 0),
			Vector3(bg:right(), bg:top(), 0),
			Vector3(bg:right(), bg:bottom(), 0),
			Vector3(bg:left(), bg:bottom(), 0)
		})
		slot.kit_panel:set_w(slot.panel:w() - slot.mugshot:w() - pad)
		slot.kit_panel:set_h(slot.panel:h() / 2 - pad)
		slot.kit_panel:set_x(slot.mugshot:w() + pad)
		slot.kit_panel:set_y(slot.panel:h() / 2)
		for i, kit_slot in ipairs(slot.kit_slots) do
			kit_slot:set_size(slot.kit_panel:h(), slot.kit_panel:h())
			kit_slot:set_position(slot.kit_panel:h() * (i - 1), 0)
		end
	end
end
function MenuLobbyRenderer:_layout_video()
	if self._level_video then
		local w = self._gui_info_panel:w()
		local m = self._level_video:video_width() / self._level_video:video_height()
		self._level_video:set_size(w, w / m)
		self._level_video:set_y(0)
		self._level_video:set_center_x(self._gui_info_panel:w() / 2)
	end
end
function MenuLobbyRenderer:set_bg_visible(visible)
	self._menu_bg:set_visible(visible)
end
function MenuLobbyRenderer:set_stencil_image(image)
	MenuRenderer.set_stencil_image(self, image)
end
function MenuLobbyRenderer:refresh_theme()
	MenuRenderer.refresh_theme(self)
end
function MenuLobbyRenderer:set_stencil_align(align, percent)
	if not self._menu_stencil then
		return
	end
	local d = self._menu_stencil:texture_height()
	if d == 0 then
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
function MenuLobbyRenderer:current_menu_text(topic_id)
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
