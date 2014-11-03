core:import("CoreMenuNodeGui")
require("lib/managers/menu/MenuNodeKitGui")
MenuKitRenderer = MenuKitRenderer or class(MenuLobbyRenderer)
function MenuKitRenderer:init(logic)
	local parameters = {layer = 0}
	MenuRenderer.init(self, logic, parameters)
end
function MenuKitRenderer:show_node(node)
	local parameters = {
		font = tweak_data.menu.default_font,
		background_color = tweak_data.menu.default_menu_background_color:with_alpha(0),
		row_item_color = tweak_data.menu.default_font_row_item_color,
		row_item_hightlight_color = tweak_data.menu.default_hightlight_row_item_color,
		node_gui_class = MenuNodeKitGui,
		font_size = tweak_data.menu.kit_default_font_size,
		spacing = node:parameters().spacing
	}
	MenuKitRenderer.super.super.show_node(self, node, parameters)
end
function MenuKitRenderer:open(...)
	self._all_items_enabled = true
	self._no_stencil = true
	self._server_state_string_id = "menu_lobby_server_state_in_game"
	MenuKitRenderer.super.open(self, ...)
	if self._player_slots then
		for _, slot in ipairs(self._player_slots) do
			slot.character:set_visible(false)
		end
	end
end
function MenuKitRenderer:_entered_menu()
	self:on_request_lobby_slot_reply()
	self:set_player_slots_kit(managers.network:session():local_peer():id())
	for peer_id, peer in pairs(managers.network:session():peers()) do
		self:set_slot_joining(peer, peer_id)
	end
end
function MenuKitRenderer:_set_player_slot(nr, params)
	local peer = managers.network:session():peer(nr)
	local ready = peer:waiting_for_player_ready()
	params.status = string.upper(managers.localization:text(ready and "menu_waiting_is_ready" or "menu_waiting_is_not_ready"))
	params.kit_panel_visible = true
	MenuKitRenderer.super._set_player_slot(self, nr, params)
end
function MenuKitRenderer:sync_chat_message(message, id)
	for _, node_gui in ipairs(self._node_gui_stack) do
		local row_item_chat = node_gui:row_item_by_name("chat")
		if row_item_chat then
			node_gui:sync_say(message, row_item_chat, id)
			return true
		end
	end
	return false
end
function MenuKitRenderer:set_all_items_enabled(enabled)
	self._all_items_enabled = enabled
	for _, node in ipairs(self._logic._node_stack) do
		for _, item in ipairs(node:items()) do
			if item:type() == "kitslot" or item:type() == "toggle" then
				item:set_enabled(enabled)
			end
		end
	end
end
function MenuKitRenderer:set_ready_items_enabled(enabled)
	if not self._all_items_enabled then
		return
	end
	for _, node in ipairs(self._logic._node_stack) do
		for _, item in ipairs(node:items()) do
			if item:type() == "kitslot" then
				item:set_enabled(enabled)
			end
		end
	end
end
function MenuKitRenderer:close(...)
	MenuKitRenderer.super.close(self, ...)
end
