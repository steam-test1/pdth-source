AchievmentManager = AchievmentManager or class()
AchievmentManager.PATH = "gamedata/achievments"
AchievmentManager.FILE_EXTENSION = "achievment"
function AchievmentManager:init()
	self.exp_awards = {
		none = 0,
		a = 500,
		b = 1500,
		c = 5000
	}
	self.script_data = {}
	if SystemInfo:platform() == Idstring("WIN32") then
		AchievmentManager.do_award = AchievmentManager.award_steam
		if not Global.achievment_manager then
			self:_parse_achievments("Steam")
			self.handler = Steam:sa_handler()
			self.handler:initialized_callback(AchievmentManager.fetch_achievments)
			self.handler:init()
			Global.achievment_manager = {
				handler = self.handler,
				achievments = self.achievments
			}
		else
			self.handler = Global.achievment_manager.handler
			self.achievments = Global.achievment_manager.achievments
		end
	elseif SystemInfo:platform() == Idstring("PS3") then
		self:_parse_achievments("PSN")
		AchievmentManager.do_award = AchievmentManager.award_psn
		self._requests = {}
	else
		Application:error("[AchievmentManager:init] Unsupported platform")
	end
end
function AchievmentManager:fetch_trophies()
	if SystemInfo:platform() == Idstring("PS3") then
		Trophies:get_unlockstate(AchievmentManager.unlockstate_result)
	end
end
function AchievmentManager.unlockstate_result(error_str, table)
	if table then
		for i, data in ipairs(table) do
			local psn_id = data.index
			local unlocked = data.unlocked
			if unlocked then
				for id, ach in pairs(managers.achievment.achievments) do
					if ach.id == psn_id then
						ach.awarded = true
					end
				end
			end
		end
	end
	managers.network.account:achievements_fetched()
end
function AchievmentManager.fetch_achievments(error_str)
	print("[AchievmentManager.fetch_achievments]", error_str)
	if error_str == "success" then
		for id, ach in pairs(managers.achievment.achievments) do
			if managers.achievment.handler:has_achievement(ach.id) then
				print("Achievment awarded", ach.id)
				ach.awarded = true
			end
		end
	end
	managers.network.account:achievements_fetched()
end
function AchievmentManager:_parse_achievments(platform)
	local list = PackageManager:script_data(self.FILE_EXTENSION:id(), self.PATH:id())
	self.achievments = {}
	for _, ach in ipairs(list) do
		if ach._meta == "achievment" then
			for _, reward in ipairs(ach) do
				if reward._meta == "reward" and (Application:editor() or platform == reward.platform) then
					self.achievments[ach.id] = {
						id = reward.id,
						name = ach.name,
						exp = self.exp_awards[ach.awards_exp],
						awarded = false
					}
				end
			end
		end
	end
end
function AchievmentManager:get_script_data(id)
	return self.script_data[id]
end
function AchievmentManager:set_script_data(id, data)
	self.script_data[id] = data
end
function AchievmentManager:exists(id)
	return self.achievments[id] ~= nil
end
function AchievmentManager:get_info(id)
	return self.achievments[id]
end
function AchievmentManager:award(id)
	if not self:exists(id) then
		return
	end
	if self:get_info(id).awarded then
		return
	end
	if id == "christmas_present" then
		managers.network.account._masks.santa = true
	elseif id == "golden_boy" then
		managers.network.account._masks.gold = true
	end
	self:do_award(id)
end
function AchievmentManager:_give_reward(id, skip_exp)
	print("[AchievmentManager:_give_reward] ", id)
	local data = self:get_info(id)
	data.awarded = true
end
function AchievmentManager:award_steam(id)
	print("[AchievmentManager:award_steam] Awarded Steam achievment", id)
	if not self.handler:initialized() then
		print("[AchievmentManager:award_steam] Achievments are not initialized. Cannot award achievment:", id)
		return
	end
	self.handler:achievement_store_callback(AchievmentManager.steam_unlock_result)
	self.handler:set_achievement(self:get_info(id).id)
	self.handler:store_data()
end
function AchievmentManager:clear_steam(id)
	print("[AchievmentManager:clear_steam]", id)
	if not self.handler:initialized() then
		print("[AchievmentManager:clear_steam] Achievments are not initialized. Cannot clear achievment:", id)
		return
	end
	self.handler:clear_achievement(self:get_info(id).id)
	self.handler:store_data()
end
function AchievmentManager.steam_unlock_result(achievment)
	print("[AchievmentManager:steam_unlock_result] Awarded Steam achievment", achievment)
	for id, ach in pairs(managers.achievment.achievments) do
		if ach.id == achievment then
			managers.achievment:_give_reward(id)
			return
		end
	end
end
function AchievmentManager:award_psn(id)
	print("[AchievmentManager:award] Awarded PSN achievment", id)
	if not self._trophies_installed then
		print("[AchievmentManager:award] Trophies are not installed. Cannot award trophy:", id)
		return
	end
	local request = Trophies:unlock_id(self:get_info(id).id, AchievmentManager.psn_unlock_result)
	self._requests[request] = id
end
function AchievmentManager.psn_unlock_result(request, error_str)
	print("[AchievmentManager:psn_unlock_result] Awarded PSN achievment", request, error_str)
	local id = managers.achievment._requests[request]
	if error_str == "success" then
		managers.achievment:_give_reward(id)
	end
end
function AchievmentManager:chk_install_trophies()
	if Trophies:is_installed() then
		print("[AchievmentManager:chk_install_trophies] Already installed")
		self._trophies_installed = true
		Trophies:get_unlockstate(self.unlockstate_result)
		self:fetch_trophies()
	elseif managers.dlc:has_full_game() then
		print("[AchievmentManager:chk_install_trophies] Installing")
		Trophies:install(callback(self, self, "clbk_install_trophies"))
	end
end
function AchievmentManager:clbk_install_trophies(result)
	print("[AchievmentManager:clbk_install_trophies]", result)
	if result then
		self._trophies_installed = true
		self:fetch_trophies()
	end
end
