CreditsFotressLevel = CreditsFotressLevel or class()
function CreditsFotressLevel:init()
	self:_load_package()
end
function CreditsFotressLevel:_load_package()
	if not PackageManager:loaded("packages/credits") then
		PackageManager:load("packages/credits")
	end
end
function CreditsFotressLevel:post_init()
	game_state_machine:change_state_by_name("menu_credits")
	managers.menu:set_debug_menu_enabled(false)
end
