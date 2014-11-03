NetworkAccount = NetworkAccount or class()
function NetworkAccount:init()
	self._postprocess_username = callback(self, self, "_standard_username")
end
function NetworkAccount:create_account(name, password, email)
end
function NetworkAccount:reset_password(name, email)
end
function NetworkAccount:login(name, password, cdkey)
end
function NetworkAccount:logout()
end
function NetworkAccount:register_callback(event, callback)
end
function NetworkAccount:register_post_username(cb)
	self._postprocess_username = cb
end
function NetworkAccount:username()
	return self._postprocess_username(self:username_id())
end
function NetworkAccount:clan_tag()
	if managers.save.get_profile_setting and managers.save:get_profile_setting("clan_tag") and string.len(managers.save:get_profile_setting("clan_tag")) > 0 then
		return "[" .. managers.save:get_profile_setting("clan_tag") .. "]"
	end
	return ""
end
function NetworkAccount:_standard_username(name)
	return name
end
