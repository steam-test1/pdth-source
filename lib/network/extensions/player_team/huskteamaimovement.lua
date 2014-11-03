HuskTeamAIMovement = HuskTeamAIMovement or class(TeamAIMovement)
function HuskTeamAIMovement:init(unit)
	TeamAIMovement.init(self, unit)
	self._queued_actions = {}
	self._m_host_stop_pos = mvector3.copy(self._m_pos)
end
function HuskTeamAIMovement:_post_init()
	self:play_redirect("idle")
end
function HuskTeamAIMovement:sync_arrested()
	self._unit:interaction():set_tweak_data("free")
	self._unit:interaction():set_active(true, false)
	managers.hud:set_mugshot_cuffed(self._unit:unit_data().mugshot_id)
	self._unit:base():set_slot(self._unit, 24)
end
function HuskTeamAIMovement:_upd_actions(t)
	TeamAIMovement._upd_actions(self, t)
	HuskCopMovement._chk_start_queued_action(self)
end
function HuskTeamAIMovement:action_request(action_desc)
	return HuskCopMovement.action_request(self, action_desc)
end
function HuskTeamAIMovement:chk_action_forbidden(action_desc)
	return HuskCopMovement.chk_action_forbidden(self, action_desc)
end
