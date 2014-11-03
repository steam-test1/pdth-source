StatisticsTweakData = StatisticsTweakData or class()
function StatisticsTweakData:init()
	self.session = {}
	self.killed = {
		civilian = {
			total = {count = 0, type = "normal"},
			head_shots = {count = 0, type = "normal"},
			session = {count = 0, type = "session"}
		},
		civilian = {count = 0, head_shots = 0},
		security = {count = 0, head_shots = 0},
		cop = {count = 0, head_shots = 0},
		swat = {count = 0, head_shots = 0},
		total = {count = 0, head_shots = 0}
	}
end
