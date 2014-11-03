CoreMusicManager = CoreMusicManager or class()
function CoreMusicManager:init()
	if not Global.music_manager then
		Global.music_manager = {}
		Global.music_manager.source = SoundDevice:create_source("music")
	end
	self._path_list = {}
	self._path_map = {}
	self._event_map = {}
	local temp_list = {}
	local events = Application:editor() and PackageManager:has(Idstring("bnk"), Idstring("soundbanks/music")) and SoundDevice:events("soundbanks/music")
	if events then
		for k, v in pairs(events) do
			if not temp_list[v.path] then
				temp_list[v.path] = 1
				table.insert(self._path_list, v.path)
			end
			self._path_map[k] = v.path
			if not self._event_map[v.path] then
				self._event_map[v.path] = {}
			end
			table.insert(self._event_map[v.path], k)
		end
	end
	table.sort(self._path_list)
	for k, v in pairs(self._event_map) do
		table.sort(v)
	end
end
function CoreMusicManager:post_event(name)
	if Global.music_manager.current_event ~= name then
		Global.music_manager.source:post_event(name)
		Global.music_manager.current_event = name
	end
end
function CoreMusicManager:stop()
	Global.music_manager.source:stop()
	Global.music_manager.current_event = nil
end
function CoreMusicManager:music_paths()
	return self._path_list
end
function CoreMusicManager:music_events(path)
	return self._event_map[path]
end
function CoreMusicManager:music_path(event)
	return self._path_map[event]
end
function CoreMusicManager:save(data)
	local state = {
		event = Global.music_manager.current_event
	}
	data.CoreMusicManager = state
end
function CoreMusicManager:load(data)
	local state = data.CoreMusicManager
	if state.event then
		self:post_event(state.event)
	end
end
