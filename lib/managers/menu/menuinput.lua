core:import("CoreMenuInput")
MenuInput = MenuInput or class(CoreMenuInput.MenuInput)
function MenuInput:init(logic, ...)
	MenuInput.super.init(self, logic, ...)
	self._move_axis_limit = 0.5
	self._sound_source = SoundDevice:create_source("MenuInput")
	self._item_input_action_map[ItemColumn.TYPE] = callback(self, self, "input_item")
	self._item_input_action_map[ItemServerColumn.TYPE] = callback(self, self, "input_item")
	self._item_input_action_map[MenuItemLevel.TYPE] = callback(self, self, "input_item")
	self._item_input_action_map[MenuItemChallenge.TYPE] = callback(self, self, "input_item")
	self._item_input_action_map[MenuItemKitSlot.TYPE] = callback(self, self, "input_kitslot")
	self._item_input_action_map[MenuItemUpgrade.TYPE] = callback(self, self, "input_item")
	self._item_input_action_map[MenuItemMultiChoice.TYPE] = callback(self, self, "input_multi_choice")
	self._item_input_action_map[MenuItemChat.TYPE] = callback(self, self, "input_chat")
	self._item_input_action_map[MenuItemFriend.TYPE] = callback(self, self, "input_item")
	self._item_input_action_map[MenuItemCustomizeController.TYPE] = callback(self, self, "input_customize_controller")
end
function MenuInput:back(...)
	self._slider_marker = nil
	local node_gui = managers.menu:active_menu().renderer:active_node_gui()
	if node_gui and node_gui._listening_to_input then
		return
	end
	MenuInput.super.back(self, ...)
end
function MenuInput:activate_mouse()
	if self._controller.TYPE ~= "pc" then
		return
	end
	self._mouse_active = true
	local data = {}
	data.mouse_move = callback(self, self, "mouse_moved")
	data.mouse_press = callback(self, self, "mouse_pressed")
	data.mouse_release = callback(self, self, "mouse_released")
	data.mouse_click = callback(self, self, "mouse_clicked")
	data.id = self._menu_name
	managers.mouse_pointer:use_mouse(data)
end
function MenuInput:deactivate_mouse()
	if not self._mouse_active then
		return
	end
	self._mouse_active = false
	managers.mouse_pointer:remove_mouse(self._menu_name)
end
function MenuInput:open(...)
	MenuInput.super.open(self, ...)
	self.AXIS_STATUS_UP = 0
	self.AXIS_STATUS_PRESSED = 1
	self.AXIS_STATUS_DOWN = 2
	self.AXIS_STATUS_RELEASED = 3
	self._axis_status = {
		x = self.AXIS_STATUS_UP,
		y = self.AXIS_STATUS_UP
	}
	self:activate_mouse()
end
function MenuInput:close(...)
	MenuInput.super.close(self, ...)
	self:deactivate_mouse()
end
function MenuInput:mouse_moved(o, x, y)
	self._keyboard_used = false
	if self._slider_marker then
		local row_item = self._slider_marker.row_item
		local where = (x - row_item.gui_slider:world_left()) / (row_item.gui_slider:world_right() - row_item.gui_slider:world_left())
		local item = self._slider_marker.item
		item:set_value_by_percentage(where * 100)
		self._logic:trigger_item(true, item)
		return
	end
	local node_gui = managers.menu:active_menu().renderer:active_node_gui()
	local select_item
	if node_gui then
		for _, row_item in pairs(node_gui.row_items) do
			if row_item.gui_panel:inside(x, y) then
				select_item = row_item.name
			end
		end
	end
	if select_item and (not managers.menu:active_menu().logic:selected_item() or select_item ~= managers.menu:active_menu().logic:selected_item():name()) then
		managers.menu:active_menu().logic:mouse_over_select_item(select_item, false)
	end
end
function MenuInput:input_kitslot(item, controller, mouse_click)
	local slider_delay_down = 0.1
	local slider_delay_pressed = 0.2
	if self:menu_right_input_bool() then
		if item:next() then
			self:post_event("selection_next")
		end
		self._logic:trigger_item(true, item)
		self:set_axis_x_timer(slider_delay_down)
		if self:menu_right_pressed() then
			self:set_axis_x_timer(slider_delay_pressed)
		end
	elseif self:menu_left_input_bool() then
		if item:previous() then
			self:post_event("selection_previous")
		end
		self._logic:trigger_item(true, item)
		self:set_axis_x_timer(slider_delay_down)
		if self:menu_left_pressed() then
			self:set_axis_x_timer(slider_delay_pressed)
		end
	end
	if controller:get_input_pressed("confirm") or mouse_click then
		if item:next() then
			self:post_event("selection_next")
		end
		self._logic:trigger_item(true, item)
	end
end
function MenuInput:input_multi_choice(item, controller, mouse_click)
	local slider_delay_down = 0.1
	local slider_delay_pressed = 0.2
	if self:menu_right_input_bool() then
		if item:next() then
			self:post_event("selection_next")
			self._logic:trigger_item(true, item)
		end
		self:set_axis_x_timer(slider_delay_down)
		if self:menu_right_pressed() then
			self:set_axis_x_timer(slider_delay_pressed)
		end
	elseif self:menu_left_input_bool() then
		if item:previous() then
			self:post_event("selection_previous")
			self._logic:trigger_item(true, item)
		end
		self:set_axis_x_timer(slider_delay_down)
		if self:menu_left_pressed() then
			self:set_axis_x_timer(slider_delay_pressed)
		end
	end
	if (controller:get_input_pressed("confirm") or mouse_click) and item:next() then
		self:post_event("selection_next")
		self._logic:trigger_item(true, item)
	end
end
function MenuInput:input_chat(item, controller, mouse_click)
	if controller:get_input_pressed("confirm") or mouse_click then
	end
end
function MenuInput:input_customize_controller(item, controller, mouse_click)
	if controller:get_input_pressed("confirm") or mouse_click then
		local node_gui = managers.menu:active_menu().renderer:active_node_gui()
		if node_gui and node_gui._listening_to_input then
			return
		end
		local node_gui = managers.menu:active_menu().renderer:active_node_gui()
		node_gui:activate_customize_controller(item)
	end
end
function MenuInput:mouse_pressed(o, button, x, y)
	if not self._accept_input then
		return
	end
	self._keyboard_used = false
	if button == Idstring("0") then
		local node_gui = managers.menu:active_menu().renderer:active_node_gui()
		if not node_gui then
			return
		end
		for _, row_item in pairs(node_gui.row_items) do
			if row_item.gui_panel:inside(x, y) then
				if row_item.type == "slider" then
					self:post_event("slider_grab")
					if row_item.gui_slider_marker:inside(x, y) then
						self._slider_marker = {
							button = button,
							item = self._logic:selected_item(),
							row_item = row_item
						}
					elseif row_item.gui_slider:inside(x, y) then
						local where = (x - row_item.gui_slider:world_left()) / (row_item.gui_slider:world_right() - row_item.gui_slider:world_left())
						local item = self._logic:selected_item()
						item:set_value_by_percentage(where * 100)
						self._logic:trigger_item(true, item)
						self._slider_marker = {
							button = button,
							item = self._logic:selected_item(),
							row_item = row_item
						}
					end
				elseif row_item.type == "kitslot" then
					local item = self._logic:selected_item()
					if row_item.arrow_right:inside(x, y) then
						item:next()
						self._logic:trigger_item(true, item)
						if row_item.arrow_right:visible() then
							self:post_event("selection_next")
						end
					elseif row_item.arrow_left:inside(x, y) then
						item:previous()
						self._logic:trigger_item(true, item)
						if row_item.arrow_left:visible() then
							self:post_event("selection_previous")
						end
					elseif not row_item.choice_panel:inside(x, y) then
						self._item_input_action_map[item.TYPE](item, self._controller, true)
						return
					end
				elseif row_item.type == "multi_choice" then
					local item = self._logic:selected_item()
					if row_item.arrow_right:inside(x, y) then
						if item:next() then
							self:post_event("selection_next")
							self._logic:trigger_item(true, item)
						end
					elseif row_item.arrow_left:inside(x, y) then
						if item:previous() then
							self:post_event("selection_previous")
							self._logic:trigger_item(true, item)
						end
					elseif not row_item.choice_panel:inside(x, y) then
						self._item_input_action_map[item.TYPE](item, self._controller, true)
						return
					end
				elseif row_item.type == "chat" then
					local item = self._logic:selected_item()
					if row_item.chat_input:inside(x, y) then
						row_item.chat_input:script().set_focus(true)
					end
				else
					local item = self._logic:selected_item()
					if item then
						self._item_input_action_map[item.TYPE](item, self._controller, true)
						return
					end
				end
			end
		end
	end
end
function MenuInput:mouse_released(o, button, x, y)
	if self._slider_marker then
		self:post_event("slider_release")
	end
	self._slider_marker = nil
end
function MenuInput:mouse_clicked(o, button, x, y)
end
function MenuInput:update(t, dt)
	if self._menu_plane then
		self._menu_plane:set_rotation(Rotation(math.sin(t * 60) * 40, math.sin(t * 50) * 30, 0))
	end
	self:_update_axis_status()
	MenuInput.super.update(self, t, dt)
	if not self._keyboard_used and self._mouse_active then
		self:mouse_moved(managers.mouse_pointer:mouse(), managers.mouse_pointer:world_position())
	end
end
function MenuInput:menu_axis_move()
	local axis_moved = {x = 0, y = 0}
	if self._controller then
		local move = self._controller:get_input_axis("menu_move")
		if move then
			axis_moved = move
		end
	end
	return axis_moved
end
function MenuInput:post_event(event)
	self._sound_source:post_event(event)
end
function MenuInput:menu_up_input_bool()
	return MenuInput.super.menu_up_input_bool(self) or self:menu_axis_move().y > self._move_axis_limit
end
function MenuInput:menu_up_pressed()
	return MenuInput.super.menu_up_pressed(self) or self._axis_status.y == self.AXIS_STATUS_PRESSED and self:menu_axis_move().y > 0
end
function MenuInput:menu_up_released()
	return MenuInput.super.menu_up_released(self) or self._axis_status.y == self.AXIS_STATUS_RELEASED
end
function MenuInput:menu_down_input_bool()
	return MenuInput.super.menu_down_input_bool(self) or self:menu_axis_move().y < -self._move_axis_limit
end
function MenuInput:menu_down_pressed()
	return MenuInput.super.menu_down_pressed(self) or self._axis_status.y == self.AXIS_STATUS_PRESSED and self:menu_axis_move().y < 0
end
function MenuInput:menu_down_released()
	return MenuInput.super.menu_down_released(self) or self._axis_status.y == self.AXIS_STATUS_RELEASED
end
function MenuInput:menu_left_input_bool()
	return MenuInput.super.menu_left_input_bool(self) or self:menu_axis_move().x < -self._move_axis_limit
end
function MenuInput:menu_left_pressed()
	return MenuInput.super.menu_left_pressed(self) or self._axis_status.x == self.AXIS_STATUS_PRESSED and self:menu_axis_move().x < 0
end
function MenuInput:menu_left_released()
	return MenuInput.super.menu_left_released(self) or self._axis_status.x == self.AXIS_STATUS_RELEASED
end
function MenuInput:menu_right_input_bool()
	return MenuInput.super.menu_right_input_bool(self) or self:menu_axis_move().x > self._move_axis_limit
end
function MenuInput:menu_right_pressed()
	return MenuInput.super.menu_right_pressed(self) or self._axis_status.x == self.AXIS_STATUS_PRESSED and self:menu_axis_move().x > 0
end
function MenuInput:menu_right_released()
	return MenuInput.super.menu_right_released(self) or self._axis_status.x == self.AXIS_STATUS_RELEASED
end
function MenuInput:_update_axis_status()
	local axis_moved = self:menu_axis_move()
	if self._axis_status.x == self.AXIS_STATUS_UP and math.abs(axis_moved.x) - self._move_axis_limit > 0 then
		self._axis_status.x = self.AXIS_STATUS_PRESSED
	elseif math.abs(axis_moved.x) - self._move_axis_limit > 0 then
		self._axis_status.x = self.AXIS_STATUS_DOWN
	elseif self._axis_status.x == self.AXIS_STATUS_PRESSED or self._axis_status.x == self.AXIS_STATUS_DOWN then
		self._axis_status.x = self.AXIS_STATUS_RELEASED
	else
		self._axis_status.x = self.AXIS_STATUS_UP
	end
	if self._axis_status.y == self.AXIS_STATUS_UP and 0 < math.abs(axis_moved.y) - self._move_axis_limit then
		self._axis_status.y = self.AXIS_STATUS_PRESSED
	elseif 0 < math.abs(axis_moved.y) - self._move_axis_limit then
		self._axis_status.y = self.AXIS_STATUS_DOWN
	elseif self._axis_status.y == self.AXIS_STATUS_PRESSED or self._axis_status.y == self.AXIS_STATUS_DOWN then
		self._axis_status.y = self.AXIS_STATUS_RELEASED
	else
		self._axis_status.y = self.AXIS_STATUS_UP
	end
end
