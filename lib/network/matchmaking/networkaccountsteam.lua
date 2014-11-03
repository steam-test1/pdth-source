require("lib/network/matchmaking/NetworkAccount")
NetworkAccountSTEAM = NetworkAccountSTEAM or class(NetworkAccount)
NetworkAccountSTEAM.lb_diffs = {
	easy = "Easy",
	normal = "Normal",
	hard = "Hard",
	overkill = "Overkill",
	overkill_145 = "Overkill 145+"
}
NetworkAccountSTEAM.lb_levels = {
	bank = "First World Bank",
	heat_street = "Heat Street",
	bridge = "Green Bridge",
	apartment = "Panic Room",
	slaughter_house = "Slaughterhouse",
	diamond_heist = "Diamond Heist",
	suburbia = "Counterfeit",
	secret_stash = "Undercover",
	hospital = "No Mercy"
}
function NetworkAccountSTEAM:init()
	NetworkAccount.init(self)
	Steam:init()
	Steam:request_listener(NetworkAccountSTEAM._on_join_request, NetworkAccountSTEAM._on_server_request)
	Steam:error_listener(NetworkAccountSTEAM._on_disconnected, NetworkAccountSTEAM._on_ipc_fail, NetworkAccountSTEAM._on_connect_fail)
	Steam:overlay_listener(callback(self, self, "_on_open_overlay"), callback(self, self, "_on_close_overlay"))
	if Steam:overlay_open() then
		self:_on_open_overlay()
	end
	Steam:sa_handler():stats_store_callback(NetworkAccountSTEAM._on_stats_stored)
	Steam:sa_handler():init()
	self._masks = {}
	Steam:http_request("http://steamcommunity.com/gid/103582791433201592/memberslistxml/?xml=1", NetworkAccountSTEAM._on_troll_group_recieved)
	Steam:lb_handler():register_storage_done_callback(NetworkAccountSTEAM._on_leaderboard_stored)
	Steam:lb_handler():register_mappings_done_callback(NetworkAccountSTEAM._on_leaderboard_mapped)
	self:_check_masks()
	self:set_lightfx()
end
function NetworkAccountSTEAM:get_win_ratio(difficulty, level)
	local plays = Steam:sa_handler():get_global_stat(difficulty .. "_" .. level .. "_plays", 30)
	local wins = Steam:sa_handler():get_global_stat(difficulty .. "_" .. level .. "_wins", 30)
	local ratio = {}
	if #plays == 0 or #wins == 0 then
		return
	end
	for i, plays_n in pairs(plays) do
		ratio[i] = wins[i] / (plays_n == 0 and 1 or plays_n)
	end
	table.sort(ratio)
	return ratio[#ratio / 2]
end
function NetworkAccountSTEAM:get_win_ratio_all()
	local level_names = tweak_data.levels._level_index
	local difficulties = {
		"easy",
		"normal",
		"hard",
		"overkill",
		"overkill_145"
	}
	for _, level in ipairs(level_names) do
		for _, difficulty in ipairs(difficulties) do
			local win_ratio = self:get_win_ratio(difficulty, level)
			print(level .. ", " .. difficulty .. ": " .. tostring(win_ratio))
		end
	end
end
function NetworkAccountSTEAM:get_plays_all()
	local level_names = tweak_data.levels._level_index
	local difficulties = {
		"easy",
		"normal",
		"hard",
		"overkill",
		"overkill_145"
	}
	for _, level in ipairs(level_names) do
		for _, difficulty in ipairs(difficulties) do
			local plays = Steam:sa_handler():get_global_stat(difficulty .. "_" .. level .. "_plays", 30)
			table.sort(plays)
			print(level .. ", " .. difficulty .. ": " .. tostring(plays[#plays / 2]))
		end
	end
end
function NetworkAccountSTEAM:get_downs_all()
	local level_names = tweak_data.levels._level_index
	local difficulties = {
		"easy",
		"normal",
		"hard",
		"overkill",
		"overkill_145"
	}
	for _, level in ipairs(level_names) do
		for _, difficulty in ipairs(difficulties) do
			local plays = Steam:sa_handler():get_global_stat(difficulty .. "_" .. level .. "_downs", 30)
			table.sort(plays)
			print(level .. ", " .. difficulty .. ": " .. tostring(plays[#plays / 2]))
		end
	end
end
function NetworkAccountSTEAM:get_kills_all()
	local level_names = tweak_data.levels._level_index
	local difficulties = {
		"easy",
		"normal",
		"hard",
		"overkill",
		"overkill_145"
	}
	for _, level in ipairs(level_names) do
		for _, difficulty in ipairs(difficulties) do
			local plays = Steam:sa_handler():get_global_stat(difficulty .. "_" .. level .. "_kills", 30)
			table.sort(plays)
			print(level .. ", " .. difficulty .. ": " .. tostring(plays[#plays / 2]))
		end
	end
end
function NetworkAccountSTEAM:get_class(class_name)
	local plays = Steam:sa_handler():get_global_stat("current_" .. class_name, 30)
	table.sort(plays)
	print(class_name .. ": " .. tostring(plays[#plays / 2]))
end
function NetworkAccountSTEAM:set_lightfx()
	if managers.user:get_setting("use_lightfx") then
		print("[NetworkAccountSTEAM:init] Initializing LightFX...")
		self._has_alienware = LightFX:initialize() and LightFX:has_lamps()
		if self._has_alienware then
			self._masks.alienware = true
			LightFX:set_lamps(0, 255, 0, 255)
		end
		print("[NetworkAccountSTEAM:init] Initializing LightFX done")
	else
		self._has_alienware = nil
		self._masks.alienware = nil
	end
end
function NetworkAccountSTEAM:has_mask(mask)
	return self._masks[mask]
end
function NetworkAccountSTEAM._on_troll_group_recieved(success, page)
	if success and string.find(page, "<steamID64>" .. Steam:userid() .. "</steamID64>") then
		managers.network.account._masks.troll = true
	end
	Steam:http_request("http://steamcommunity.com/gid/103582791432592205/memberslistxml/?xml=1", NetworkAccountSTEAM._on_com_group_recieved)
end
function NetworkAccountSTEAM._on_com_group_recieved(success, page)
	if success and string.find(page, "<steamID64>" .. Steam:userid() .. "</steamID64>") then
		managers.network.account._masks.hockey_com = true
	end
	Steam:http_request("http://steamcommunity.com/gid/103582791433578383/memberslistxml/?xml=1", NetworkAccountSTEAM._on_vyse_group_recieved)
end
function NetworkAccountSTEAM._on_vyse_group_recieved(success, page)
	if success and string.find(page, "<steamID64>" .. Steam:userid() .. "</steamID64>") then
		managers.network.account._masks.vyse = true
	end
	Steam:http_request("http://steamcommunity.com/gid/103582791433732274/memberslistxml/?xml=1", NetworkAccountSTEAM._on_tester_group_recieved)
end
function NetworkAccountSTEAM._on_tester_group_recieved(success, page)
	if success and string.find(page, "<steamID64>" .. Steam:userid() .. "</steamID64>") then
		managers.network.account._masks.tester_group = true
	end
	Steam:http_request("http://steamcommunity.com/gid/103582791432508229/memberslistxml/?xml=1", NetworkAccountSTEAM._on_dev_group_recieved)
end
function NetworkAccountSTEAM._on_dev_group_recieved(success, page)
	if success and string.find(page, "<steamID64>" .. Steam:userid() .. "</steamID64>") then
		managers.network.account._masks.developer = true
	end
end
function NetworkAccountSTEAM:has_alienware()
	return self._has_alienware
end
function NetworkAccountSTEAM:_on_open_overlay()
	print("[NetworkAccountSTEAM:_on_open_overlay]")
	if self._overlay_opened then
		return
	end
	self._overlay_opened = true
	game_state_machine:_set_controller_enabled(false)
end
function NetworkAccountSTEAM:_on_close_overlay()
	print("[NetworkAccountSTEAM:_on_close_overlay]")
	if not self._overlay_opened then
		return
	end
	self._overlay_opened = false
	game_state_machine:_set_controller_enabled(true)
end
function NetworkAccountSTEAM:_check_masks()
	if managers.achievment:get_info("christmas_present").awarded then
		self._masks.santa = true
	end
	if managers.achievment:get_info("golden_boy").awarded then
		self._masks.gold = true
	end
	if managers.achievment:get_info("president").awarded then
		self._masks.president = true
	end
	if managers.achievment:get_info("tester").awarded then
		self._masks.tester_achievment = true
	end
end
function NetworkAccountSTEAM:achievements_fetched()
	self._achievements_fetched = true
	self:_check_for_unawarded_achievements()
end
function NetworkAccountSTEAM:challenges_loaded()
	self._challenges_loaded = true
	self:_check_for_unawarded_achievements()
end
function NetworkAccountSTEAM:experience_loaded()
	self._experience_loaded = true
	self:_check_for_unawarded_achievements()
end
function NetworkAccountSTEAM:_check_for_unawarded_achievements()
	self:_check_masks()
	if not self._achievements_fetched or not self._challenges_loaded or not self._experience_loaded then
		return
	end
	print("[NetworkAccountSTEAM:_check_for_unawarded_achievements]")
	for _, challenge in ipairs(managers.challenges:get_completed()) do
		local achievement = managers.challenges:get_awarded_achievment(challenge.id)
		if achievement and not managers.achievment:get_info(achievement).awarded then
			print("[NetworkAccountSTEAM:_check_for_unawarded_achievements] Awarded unawarded achievements.")
			managers.achievment:award(achievement)
		end
	end
	if not managers.achievment:get_info("president").awarded and managers.experience:current_level() >= 145 then
		managers.challenges:set_flag("president")
	end
end
function NetworkAccountSTEAM._on_leaderboard_stored(status)
	print("[NetworkAccountSTEAM:_on_leaderboard_stored] Leaderboard stored, ", status, ".")
end
function NetworkAccountSTEAM._on_leaderboard_mapped()
	print("[NetworkAccountSTEAM:_on_leaderboard_stored] Leaderboard mapped.")
	Steam:lb_handler():request_storage()
end
function NetworkAccountSTEAM._on_stats_stored(status)
	print("[NetworkAccountSTEAM:_on_stats_stored] Statistics stored, ", status, ". Publishing leaderboard score to Steam!")
	local leaderboard_to_publish = managers.network.account._leaderboard_to_publish
	if not leaderboard_to_publish then
		return
	end
	local diff_id = leaderboard_to_publish[1]
	local lvl_id = leaderboard_to_publish[2]
	local diff_name = NetworkAccountSTEAM.lb_diffs[diff_id]
	local lvl_name = NetworkAccountSTEAM.lb_levels[lvl_id]
	Steam:lb_handler():register_mappings({
		[lvl_name .. ": " .. diff_name] = diff_id .. "_" .. lvl_id .. "_time"
	})
	managers.network.account._leaderboard_to_publish = nil
end
function NetworkAccountSTEAM:publish_statistics(stats, success)
	if managers.dlc:is_trial() then
		return
	end
	local handler = Steam:sa_handler()
	print("[NetworkAccountSTEAM:publish_statistics] Publishing statistics to Steam!")
	if not handler:initialized() then
		print("[NetworkAccountSTEAM:publish_statistics] Error, SA handler not initialized! Not sending stats.")
		return
	end
	if success and not managers.statistics:is_dropin() then
		self._leaderboard_to_publish = {
			Global.game_settings.difficulty,
			Global.level_data.level_id
		}
	end
	local err = false
	for key, stat in pairs(stats) do
		local res
		if stat.type == "int" then
			local val = handler:get_stat(key)
			if stat.method == "lowest" then
				if val > stat.value then
					res = handler:set_stat(key, stat.value)
				else
					res = true
				end
			elseif stat.method == "highest" then
				if val < stat.value then
					res = handler:set_stat(key, stat.value)
				else
					res = true
				end
			elseif stat.method == "set" then
				res = handler:set_stat(key, stat.value)
			elseif stat.value > 0 then
				local mval = val / 1000 + stat.value / 1000
				if mval >= 2147483 then
					Application:error("[NetworkAccountSTEAM:publish_statistics] Warning, trying to set too high a value on stat " .. key)
					res = handler:set_stat(key, 2147483008)
				else
					res = handler:set_stat(key, val + stat.value)
				end
			else
				res = true
			end
		elseif stat.type == "float" then
			if stat.value > 0 then
				local val = handler:get_stat_float(key)
				res = handler:set_stat_float(key, val + stat.value)
			else
				res = true
			end
		elseif stat.type == "avgrate" then
			res = handler:set_stat_float(key, stat.value, stat.hours)
		end
		if not res then
			Application:error("[NetworkAccountSTEAM:publish_statistics] Error, could not set stat " .. key)
			err = true
		end
	end
	if Application:production_build() then
		self._leaderboard_to_publish = nil
		return
	end
	if not err then
		handler:store_data()
	end
end
function NetworkAccountSTEAM._on_disconnected(lobby_id, friend_id)
	print("[NetworkAccountSTEAM._on_disconnected]", lobby_id, friend_id)
	Application:warn("Disconnected from Steam!! Please wait", 12)
end
function NetworkAccountSTEAM._on_ipc_fail(lobby_id, friend_id)
	print("[NetworkAccountSTEAM._on_ipc_fail]")
end
function NetworkAccountSTEAM._on_join_request(lobby_id, friend_id)
	print("[NetworkAccountSTEAM._on_join_request]")
	if managers.network:session() and (managers.network:session():_local_peer_in_lobby() or managers.network:game()) then
		managers.menu:show_cant_join_from_game_dialog()
	else
		Global.game_settings.single_player = false
		managers.network.matchmake:join_server_with_check(lobby_id)
	end
end
function NetworkAccountSTEAM._on_server_request(ip, pw)
	print("[NetworkAccountSTEAM._on_server_request]")
end
function NetworkAccountSTEAM._on_connect_fail(ip, pw)
	print("[NetworkAccountSTEAM._on_connect_fail]")
end
function NetworkAccountSTEAM:signin_state()
	if self:local_signin_state() == true then
		return "signed in"
	end
	return "not signed in"
end
function NetworkAccountSTEAM:local_signin_state()
	return Steam:logged_on()
end
function NetworkAccountSTEAM:username_id()
	return Steam:username()
end
function NetworkAccountSTEAM:player_id()
	return Steam:userid()
end
function NetworkAccountSTEAM:is_connected()
	return true
end
function NetworkAccountSTEAM:lan_connection()
	return true
end
function NetworkAccountSTEAM.output_global_stats(file)
	local num_days = 100
	local sa = Steam:sa_handler()
	local invalid = sa:get_global_stat("easy_slaughter_house_plays", num_days)
	invalid[1] = 1
	invalid[3] = 1
	invalid[11] = 1
	invalid[12] = 1
	invalid[19] = 1
	invalid[28] = 1
	invalid[51] = 1
	invalid[57] = 1
	local function get_lvl_stat(diff, heist, stat, i)
		if i == 0 then
			local st = NetworkAccountSTEAM.lb_levels[heist] .. ", " .. NetworkAccountSTEAM.lb_diffs[diff] .. " - "
			if type(stat) == "string" then
				return st .. stat
			else
				return st .. stat[1] .. "/" .. stat[2]
			end
		end
		local num
		if type(stat) == "string" then
			num = sa:get_global_stat(diff .. "_" .. heist .. "_" .. stat, num_days)[i] or 0
		else
			local f = sa:get_global_stat(diff .. "_" .. heist .. "_" .. stat[1], num_days)[i] or 0
			local s = sa:get_global_stat(diff .. "_" .. heist .. "_" .. stat[2], num_days)[i] or 1
			num = f / (s == 0 and 1 or s)
		end
		return num
	end
	local function get_weapon_stat(weapon, stat, i)
		if i == 0 then
			local st = weapon .. " - "
			if type(stat) == "string" then
				return st .. stat
			else
				return st .. stat[1] .. "/" .. stat[2]
			end
		end
		local num
		if type(stat) == "string" then
			num = sa:get_global_stat(weapon .. "_" .. stat, num_days)[i] or 0
		else
			local f = sa:get_global_stat(weapon .. "_" .. stat[1], num_days)[i] or 0
			local s = sa:get_global_stat(weapon .. "_" .. stat[2], num_days)[i] or 1
			num = f / (s == 0 and 1 or s)
		end
		return num
	end
	local diffs = {
		"easy",
		"normal",
		"hard",
		"overkill",
		"overkill_145"
	}
	local heists = {
		"bank",
		"heat_street",
		"bridge",
		"apartment",
		"slaughter_house",
		"diamond_heist"
	}
	local weapons = {
		"beretta92",
		"c45",
		"raging_bull",
		"r870_shotgun",
		"mossberg",
		"m4",
		"mp5",
		"mac11",
		"m14",
		"hk21"
	}
	local lvl_stats = {
		"plays",
		{"wins", "plays"},
		{"kills", "plays"}
	}
	local wep_stats = {
		"kills",
		{"kills", "shots"},
		{"headshots", "shots"}
	}
	local lines = {}
	for i = 0, #invalid do
		if i == 0 or invalid[i] == 0 then
			local out = "" .. i
			for _, lvl_stat in ipairs(lvl_stats) do
				for _, diff in ipairs(diffs) do
					for _, heist in ipairs(heists) do
						out = out .. ";" .. get_lvl_stat(diff, heist, lvl_stat, i)
					end
				end
			end
			for _, wep_stat in ipairs(wep_stats) do
				for _, weapon in ipairs(weapons) do
					out = out .. ";" .. get_weapon_stat(weapon, wep_stat, i)
				end
			end
			table.insert(lines, out)
		end
	end
	local file_handle = SystemFS:open(file, "w")
	for i = 1, #lines do
		file_handle:puts(lines[i == 1 and 1 or #lines - i + 2])
	end
end
