DramaManager = DramaManager or class()
function DramaManager:init()
	self._cues = {}
	self:_load_data()
end
function DramaManager:cue(id)
	return self._cues[id]
end
function DramaManager:_load_data()
	local file_name = "gamedata/dramas/index"
	local data = PackageManager:script_data(Idstring("drama_index"), file_name:id())
	for _, c in ipairs(data) do
		if c.name then
			self:_load_drama(c.name)
		end
	end
end
function DramaManager:_load_drama(name)
	local file_name = "gamedata/dramas/" .. name
	local data = PackageManager:script_data(Idstring("drama"), file_name:id())
	local id
	for _, c in ipairs(data) do
		if c.id then
			id = c.id
			self._cues[id] = {}
			local empty = true
			for _, node in ipairs(c) do
				if node._meta == "string_id" then
					self._cues[id].string_id = node.name
					empty = false
				elseif node._meta == "sound" then
					self._cues[id].sound = node.name
					if node.source then
						self._cues[id].sound_source = Idstring(node.source)
					end
					empty = false
				elseif node._meta == "animation" then
					self._cues[id].animation = node.name
					empty = false
				elseif node._meta == "duration" then
					self._cues[id].duration = self:_process_duration(node.value)
				end
			end
			if empty then
				Application:throw_exception("Error in 'gamedata/dramas/" .. name .. "'! The drama '" .. tostring(id) .. "' is empty!")
			end
			if not self._cues[id].duration then
				if self._cues[id].sound then
					self._cues[id].duration = "sound"
				elseif self._cues[id].string_id then
					self._cues[id].duration = "text"
				else
					self._cues[id].duration = "animation"
				end
			end
			if self._cues[id].duration == "sound" and not self._cues[id].sound then
				Application:throw_exception("Error in 'gamedata/dramas/" .. name .. "'! Duration can't be based on sound because the drama doesn't have one!")
			elseif self._cues[id].duration == "animation" and not self._cues[id].animation then
				Application:throw_exception("Error in 'gamedata/dramas/" .. name .. "'! Duration can't be based on animation because the drama doesn't have one!")
			elseif self._cues[id].duration == "text" and not self._cues[id].string_id then
				Application:throw_exception("Error in 'gamedata/dramas/" .. name .. "'! Duration can't be based on text because the drama doesn't have one!")
			end
			if self._cues[id].duration == "text" then
				local text = managers.localization:text(self._cues[id].string_id)
				self._cues[id].duration = text:len() * tweak_data.dialog.DURATION_PER_CHAR
				if self._cues[id].duration < tweak_data.dialog.MINIMUM_DURATION then
					self._cues[id].duration = tweak_data.dialog.MINIMUM_DURATION
				end
			end
		end
	end
end
function DramaManager:_process_duration(value)
	if not value then
		return nil
	end
	if value == "sound" or value == "animation" or value == "text" then
		return value
	else
		value = tonumber(value)
		if not value then
			Application:throw_exception("Error in 'gamedata/dramas/'! The duration parameter in drama file isn't valid! (Use 'sound', 'animation' or a number as value)")
		end
		return value
	end
end
