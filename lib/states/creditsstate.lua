require("lib/states/GameState")
CreditsState = CreditsState or class(GameState)
function CreditsState:init(game_state_machine, setup)
	GameState.init(self, "menu_credits", game_state_machine)
	self._setup = false
	self._active = false
end
function CreditsState:set_controller_enabled(enabled)
	self._active = enabled
end
function CreditsState:setup()
	self._credits_list = PackageManager:script_data(Idstring("credits"), Idstring("gamedata/credits"))
	local meta_credits = {}
	meta_credits.__index = meta_credits
	meta_credits._index = 1
	meta_credits._sub_index = 0
	function meta_credits:has_next()
		return not not self[self._index]
	end
	function meta_credits:get_next(index, sub_index)
		local data = self[index]
		local name = ""
		local h = 23
		local fs = 23
		local o = 0
		if sub_index == 0 then
			name = data.name
			if data._meta == "header" then
				h = 125
				fs = 40
				o = 15
			else
				h = 55
				fs = 30
				o = 5
			end
		else
			name = data[sub_index].name
		end
		return {
			h = h,
			font_size = fs,
			offset = o,
			name = name
		}
	end
	function meta_credits:step()
		if self._index == 0 then
			self._index = 1
		else
			self._sub_index = self._sub_index + 1
		end
		if self._sub_index > #self[self._index] then
			self._sub_index = 0
			self._index = self._index + 1
		end
	end
	function meta_credits:next()
		local ret = self:get_next(self._index, self._sub_index)
		self:step()
		return ret
	end
	setmetatable(self._credits_list, meta_credits)
	local res = RenderSettings.resolution
	local gui = Overlay:gui()
	self._workspace = gui:create_screen_workspace()
	self._workspace:show()
	self._text_panel = self._workspace:panel():panel({
		h = 0,
		y = self._workspace:panel():h(),
		layer = 1
	})
	self:add_credit()
	self._setup = true
end
function CreditsState:add_credit()
	local data = self._credits_list:next()
	local offset = data.offset
	local text_params = {
		h = data.h,
		y = self._text_panel:h(),
		vertical = "bottom",
		align = "center",
		font = "fonts/font_fortress_22",
		font_size = data.font_size,
		text = data.name,
		color = Color.white
	}
	local text = self._text_panel:text(text_params)
	text:set_layer(1)
	text_params.color = Color.black
	self._text_panel:text(text_params):move(-2, -2)
	self._text_panel:text(text_params):move(2, -2)
	self._text_panel:text(text_params):move(2, 2)
	self._text_panel:text(text_params):move(-2, 2)
	self._text_panel:grow(0, text:h() + offset)
end
function CreditsState:at_enter(old_state)
	self:setup()
end
function CreditsState:at_exit(new_state)
	self._credits_list = nil
	self._setup = false
	Overlay:gui():destroy_workspace(self._workspace)
end
function CreditsState:continue()
	setup:load_start_menu()
end
function CreditsState:update(t, dt)
	if not self._setup or not self._active then
		return
	end
	if alive(self._text_panel:child(0)) and 0 >= self._text_panel:child(0):world_bottom() then
		self._text_panel:remove(self._text_panel:child(0))
	end
	self._text_panel:move(0, -dt * 25 * 3.55)
	if self._credits_list:has_next() then
		if self._text_panel:bottom() < self._text_panel:parent():h() then
			self:add_credit()
		end
	elseif 0 >= self._text_panel:bottom() then
		self:continue()
	end
end
