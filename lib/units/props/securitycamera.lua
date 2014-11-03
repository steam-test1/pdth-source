SecurityCamera = SecurityCamera or class()
function SecurityCamera:generate_cooldown(amount)
	managers.hint:show_hint("destroyed_security_camera")
	managers.statistics:camera_destroyed()
end
