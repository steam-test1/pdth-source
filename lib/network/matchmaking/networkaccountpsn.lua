require("lib/network/matchmaking/NetworkAccount")
NetworkAccountPSN = NetworkAccountPSN or class(NetworkAccount)
function NetworkAccountPSN:init()
	NetworkAccount.init(self)
end
function NetworkAccountPSN:signin_state()
	if PSN:is_online() == true then
		return "signed in"
	end
	return "not signed in"
end
function NetworkAccountPSN:local_signin_state()
	if not PSN:cable_connected() then
		return false
	end
	local n = PSN:get_localinfo()
	if not n then
		return false
	end
	if not n.local_ip then
		return false
	end
	return true
end
function NetworkAccountPSN:show_signin_ui()
	PSN:display_online_connection()
end
function NetworkAccountPSN:username_id()
	local online_name = PSN:get_npid_user()
	if online_name then
		return online_name
	else
		local local_user_info_name = PS3:get_userinfo()
		if local_user_info_name then
			return local_user_info_name
		end
	end
	return managers.localization:text("menu_mp_player")
end
function NetworkAccountPSN:player_id()
	if PSN:get_npid_user() == nil then
		local n = PSN:get_localinfo()
		if n and n.local_ip then
			return n.local_ip
		end
		Application:error("Could not get local ip, returning \"player_id\" VERY BAD!.")
		return "player_id"
	end
	return PSN:get_npid_user()
end
function NetworkAccountPSN:is_connected()
	return true
end
function NetworkAccountPSN:lan_connection()
	return PSN:cable_connected()
end
function NetworkAccountPSN:_lan_ip()
	local l = PSN:get_lan_info()
	if l and l.lan_ip then
		return l.lan_ip
	end
	return "player_lan"
end
function NetworkAccountPSN:has_mask(mask)
	return false
end
function NetworkAccountPSN:achievements_fetched()
	self._achievements_fetched = true
	self:_check_for_unawarded_achievements()
end
function NetworkAccountPSN:challenges_loaded()
	self._challenges_loaded = true
	self:_check_for_unawarded_achievements()
end
function NetworkAccountPSN:experience_loaded()
	self._experience_loaded = true
	self:_check_for_unawarded_achievements()
end
function NetworkAccountPSN:_check_for_unawarded_achievements()
	if not self._achievements_fetched or not self._challenges_loaded or not self._experience_loaded then
		return
	end
	print("[NetworkAccountPSN:_check_for_unawarded_achievements]")
	for _, challenge in ipairs(managers.challenges:get_completed()) do
		local achievement = managers.challenges:get_awarded_achievment(challenge.id)
		if achievement and not managers.achievment:get_info(achievement).awarded then
			managers.challenges:add_already_awarded_challenge(challenge.id)
		end
	end
end
