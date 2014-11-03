TipsTweakData = TipsTweakData or class()
function TipsTweakData:init()
	table.insert(self, {
		string_id = "tip_tactical_reload"
	})
	table.insert(self, {
		string_id = "tip_help_arrested"
	})
	table.insert(self, {
		string_id = "tip_weapon_effecienty"
	})
	table.insert(self, {
		string_id = "tip_switch_to_sidearm"
	})
	table.insert(self, {
		string_id = "tip_doctor_bag"
	})
	table.insert(self, {
		string_id = "tip_ammo_bag"
	})
	table.insert(self, {
		string_id = "tip_head_shot"
	})
	table.insert(self, {
		string_id = "tip_secret_assignmnet"
	})
	table.insert(self, {
		string_id = "tip_help_bleed_out"
	})
	table.insert(self, {
		string_id = "tip_dont_shoot_civilians"
	})
	table.insert(self, {
		string_id = "tip_trading_hostage"
	})
	table.insert(self, {
		string_id = "tip_shoot_at_civilians"
	})
	table.insert(self, {
		string_id = "tip_police_free_hostage"
	})
	table.insert(self, {
		string_id = "tip_steelsight"
	})
	table.insert(self, {
		string_id = "tip_melee_attack"
	})
	table.insert(self, {
		string_id = "tip_law_enforcers_as_hostages"
	})
	table.insert(self, {
		string_id = "tip_mask_off"
	})
	table.insert(self, {string_id = "tip_xp"})
	table.insert(self, {string_id = "tip_xp_bar"})
	table.insert(self, {
		string_id = "tip_objectives"
	})
	table.insert(self, {
		string_id = "tip_select_reward"
	})
	table.insert(self, {
		string_id = "tip_shoot_in_bleed_out"
	})
end
function TipsTweakData:get_a_tip()
	local lvl = managers.experience:current_level()
	local ids = {}
	for _, tip in ipairs(self) do
		if not tip.unlock_lvl or lvl > tip.unlock_lvl then
			table.insert(ids, tip.string_id)
		end
	end
	return ids[math.random(#ids)]
end
