core:import("CoreMissionScriptElement")
ElementSpawnCivilian = ElementSpawnCivilian or class(CoreMissionScriptElement.MissionScriptElement)
function ElementSpawnCivilian:init(...)
	ElementSpawnCivilian.super.init(self, ...)
	self._enemy_name = self._values.enemy and Idstring(self._values.enemy) or Idstring("units/characters/civilians/dummy_civilian_1/dummy_civilian_1")
	self._units = {}
	self._events = {}
end
function ElementSpawnCivilian:enemy_name()
	return self._enemy_name
end
function ElementSpawnCivilian:units()
	return self._units
end
function ElementSpawnCivilian:produce()
	local unit = safe_spawn_unit(self._enemy_name, self._values.position, self._values.rotation)
	unit:unit_data().mission_element = self
	table.insert(self._units, unit)
	if self._values.state ~= "none" then
		if unit:brain() then
			local action_data = {
				type = "act",
				variant = self._values.state,
				body_part = 1,
				align_sync = true
			}
			local spawn_ai = {
				init_state = "idle",
				objective = {
					type = "act",
					action = action_data,
					interrupt_on = "contact"
				}
			}
			unit:brain():set_spawn_ai(spawn_ai)
		else
			unit:base():play_state(self._values.state)
		end
	end
	if self._values.force_pickup and self._values.force_pickup ~= "none" then
		unit:character_damage():set_pickup(self._values.force_pickup)
	end
	if unit:unit_data().secret_assignment_id then
		managers.secret_assignment:register_unit(unit)
	else
		managers.secret_assignment:register_civilian(unit)
	end
	self:event("spawn", unit)
	return unit
end
function ElementSpawnCivilian:event(name, unit)
	if self._events[name] then
		for _, callback in ipairs(self._events[name]) do
			callback(unit)
		end
	end
end
function ElementSpawnCivilian:add_event_callback(name, callback)
	self._events[name] = self._events[name] or {}
	table.insert(self._events[name], callback)
end
function ElementSpawnCivilian:on_executed(instigator)
	if not self._values.enabled then
		return
	end
	if not managers.groupai:state():is_AI_enabled() and not Application:editor() then
		return
	end
	local unit = self:produce()
	ElementSpawnCivilian.super.on_executed(self, unit)
end
function ElementSpawnCivilian:unspawn_all_units()
	ElementSpawnEnemyDummy.unspawn_all_units(self)
end
function ElementSpawnCivilian:execute_on_all_units(func)
	ElementSpawnEnemyDummy.execute_on_all_units(self, func)
end
