CivilianBase = CivilianBase or class(CopBase)
function CivilianBase:post_init()
	self._ext_movement = self._unit:movement()
	local spawn_state = self._spawn_state or "civilian/spawn/loop"
	self._ext_movement:play_state(spawn_state)
	self._unit:anim_data().idle_full_blend = true
	self._ext_movement:post_init()
	self._unit:brain():post_init()
	managers.enemy:register_civilian(self._unit)
end
function CivilianBase:default_weapon_name()
end
