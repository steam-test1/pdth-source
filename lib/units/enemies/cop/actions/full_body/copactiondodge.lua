CopActionDodge = CopActionDodge or class()
function CopActionDodge:init(action_desc, common_data)
	self._common_data = common_data
	self._ext_base = common_data.ext_base
	self._ext_movement = common_data.ext_movement
	self._ext_anim = common_data.ext_anim
	self._body_part = action_desc.body_part
	self._unit = common_data.unit
	self._expired = false
	self._machine = common_data.machine
	if action_desc.rotation then
		self._ext_movement:set_rotation(Rotation(action_desc.rotation))
	end
	local redir_name = action_desc.variation == 1 and "dodge_stand" or "dodge_crouch"
	local redir_res = self._ext_movement:play_redirect(redir_name)
	if redir_res then
		local action_data = {}
		self._body_part = action_desc.body_part
		self._descriptor = action_desc
		self._last_vel_z = 0
		self._ext_movement:set_root_blend(false)
		self._machine:set_parameter(redir_res, "var" .. action_desc.variation, 1)
		if action_desc.direction == 0 then
			self._machine:set_parameter(redir_res, "fwd", 1)
		elseif action_desc.direction == 1 then
			self._machine:set_parameter(redir_res, "bwd", 1)
		elseif action_desc.direction == 2 then
			self._machine:set_parameter(redir_res, "l", 1)
		elseif action_desc.direction == 3 then
			self._machine:set_parameter(redir_res, "r", 1)
		end
		if Network:is_server() then
			common_data.ext_network:send("action_dodge_start", action_desc.variation, action_desc.direction, common_data.rot:yaw())
		end
		self._ext_movement:enable_update()
		return true
	else
		print("[CopActionDodge:init] redirect", redir_name, "failed in", self._machine:segment_state(Idstring("base")), common_data.unit)
		return
	end
end
local prios = {
	{
		2,
		3,
		1,
		0
	},
	{
		3,
		2,
		1,
		0
	},
	{
		1,
		2,
		3,
		0
	},
	{
		1,
		3,
		2,
		0
	}
}
local tmp_v = Vector3()
function CopActionDodge.try_dodge(unit, var)
	local pos = unit:position()
	local ray_params = {
		tracker_from = unit:movement():nav_tracker(),
		pos_to = tmp_v
	}
	local lut = prios[math.random(1, 4)]
	for i = 1, 4 do
		local d = lut[i]
		if d == 0 then
			mvector3.set(tmp_v, unit:rotation():y())
		elseif d == 1 then
			mvector3.set(tmp_v, -unit:rotation():y())
		elseif d == 2 then
			mvector3.set(tmp_v, -unit:rotation():x())
		else
			mvector3.set(tmp_v, unit:rotation():x())
		end
		mvector3.multiply(tmp_v, 200)
		mvector3.add(tmp_v, pos)
		if not managers.navigation:raycast(ray_params) then
			local action_data = {
				type = "dodge",
				body_part = 1,
				variation = var,
				direction = d
			}
			return action_data
		end
	end
	return nil
end
function CopActionDodge:on_exit()
	if Network:is_client() then
		self._ext_movement:set_m_host_stop_pos(self._ext_movement:m_pos())
	elseif not self._expired then
		self._common_data.ext_network:send("action_dodge_end")
	end
end
function CopActionDodge:update(t)
	if self._ext_anim.dodge then
		local dt = TimerManager:game():delta_time()
		self._last_pos = CopActionHurt._get_pos_clamped_to_graph(self)
		CopActionWalk._set_new_pos(self, dt)
		local new_rot = self._unit:get_animation_delta_rotation()
		new_rot = self._common_data.rot * new_rot
		mrotation.set_yaw_pitch_roll(new_rot, new_rot:yaw(), 0, 0)
		self._ext_movement:set_rotation(new_rot)
	else
		self._expired = true
	end
end
function CopActionDodge:type()
	return "dodge"
end
function CopActionDodge:expired()
	return self._expired
end
function CopActionDodge:save(save_data)
end
function CopActionDodge:need_upd()
	return true
end
function CopActionDodge:chk_block(action_type, t)
	if action_type == "death" or action_type == "bleedout" or action_type == "fatal" then
		return false
	end
	return true
end
CopActionDodge._apply_freefall = CopActionWalk._apply_freefall
