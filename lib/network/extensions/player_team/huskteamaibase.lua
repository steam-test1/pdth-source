HuskTeamAIBase = HuskTeamAIBase or class(HuskCopBase)
function HuskTeamAIBase:default_weapon_name()
	return TeamAIBase.default_weapon_name(self)
end
function HuskTeamAIBase:post_init()
	self._unit:movement():post_init()
	self:set_anim_lod(1)
	self._lod_stage = 1
	self._allow_invisible = true
	TeamAIBase._register(self)
	managers.game_play_central:add_contour_unit(self._unit, "character")
	managers.occlusion:remove_occlusion(self._unit)
end
function HuskTeamAIBase:nick_name()
	return TeamAIBase.nick_name(self)
end
function HuskTeamAIBase:on_death_exit()
	HuskTeamAIBase.super.on_death_exit(self)
	TeamAIBase.unregister(self)
	self:set_slot(self._unit, 0)
end
function HuskTeamAIBase:pre_destroy(unit)
	managers.game_play_central:remove_contour_unit(unit)
	unit:movement():pre_destroy()
	TeamAIBase.unregister(self)
	UnitBase.pre_destroy(self, unit)
end
function HuskTeamAIBase:load(data)
	local character_name = self._tweak_table
	if character_name then
		local old_unit = managers.criminals:character_unit_by_name(character_name)
		if old_unit then
			local member = managers.network:game():member_from_unit(old_unit)
			if member then
				managers.network:session():on_peer_lost(member:peer(), member:peer():id())
			end
		end
		managers.criminals:add_character(character_name, self._unit, nil, true)
		self._unit:movement():set_character_anim_variables()
	end
end
function HuskTeamAIBase:chk_freeze_anims()
end
function HuskTeamAIBase:unregister()
	TeamAIBase.unregister(self)
end
