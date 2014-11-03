SecretAssignmentTweakData = SecretAssignmentTweakData or class()
function SecretAssignmentTweakData:init()
	self.bank_manager = {}
	self.bank_manager.type = "kill"
	self.bank_manager.title_id = "sa_bank_manager_hl"
	self.bank_manager.description_id = "sa_bank_manager"
	self.civilian_escape = {}
	self.civilian_escape.type = "civilian_escape"
	self.civilian_escape.title_id = "sa_civilian_escape_hl"
	self.civilian_escape.description_id = "sa_civilian_escape"
	self.civilian_escape.time_limit = 300
	self.civilian_escape.time_limit_success = true
	self.civilian_escape.level_filter = {
		include = {"bank"}
	}
end
