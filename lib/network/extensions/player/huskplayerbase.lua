require("lib/units/enemies/cop/CopBase")
HuskPlayerBase = HuskPlayerBase or class(PlayerBase)
HuskPlayerBase.set_anim_lod = CopBase.set_anim_lod
HuskPlayerBase.set_visibility_state = CopBase.set_visibility_state
HuskPlayerBase._anim_lods = CopBase._anim_lods
function HuskPlayerBase:init(unit)
	UnitBase.init(self, unit, false)
	self._unit = unit
end
function HuskPlayerBase:post_init()
	self._unit:movement():post_init()
	managers.groupai:state():register_criminal(self._unit)
	managers.game_play_central:add_contour_unit(self._unit, "character")
	managers.occlusion:remove_occlusion(self._unit)
	self:set_anim_lod(1)
	self._lod_stage = 1
	self._allow_invisible = true
	local spawn_state = self._spawn_state or "std/stand/still/idle/look"
	self._unit:movement():play_state(spawn_state)
end
function HuskPlayerBase:pre_destroy(unit)
	managers.game_play_central:remove_contour_unit(unit)
	self._unit:movement():pre_destroy(unit)
	managers.groupai:state():unregister_criminal(self._unit)
	if managers.network:game() then
		local member = managers.network:game():member_from_unit(self._unit)
		if member then
			member:set_unit(nil)
		end
	end
	UnitBase.pre_destroy(self, unit)
end
function HuskPlayerBase:on_disarmed()
	self._unit:base():set_slot(self._unit, 5)
end
function HuskPlayerBase:nick_name()
	local member = managers.network:game():member_from_unit(self._unit)
	return member and member:peer():name() or ""
end
function HuskPlayerBase:on_death_exit()
end
function HuskPlayerBase:chk_freeze_anims()
end
