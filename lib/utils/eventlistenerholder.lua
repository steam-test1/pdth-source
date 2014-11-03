EventListenerHolder = EventListenerHolder or class()
function EventListenerHolder:add(key, event_types, clbk)
	if self._calling then
		self:_set_new(key, event_types, clbk)
	else
		self:_add(key, event_types, clbk)
	end
end
function EventListenerHolder:remove(key)
	if self._calling then
		self:_set_trash(key)
	else
		self:_remove(key)
	end
end
function EventListenerHolder:call(event, ...)
	if self._listeners then
		local event_listeners = self._listeners[event]
		if event_listeners then
			self._calling = true
			for key, clbk in pairs(event_listeners) do
				if self:_not_trash(key) then
					clbk(...)
				end
			end
			self._calling = nil
			self:_append_new_additions()
			self:_dispose_trash()
		end
	end
end
function EventListenerHolder:_remove(key)
	local listeners = self._listeners
	for _, event in pairs(self._listener_keys[key]) do
		listeners[event][key] = nil
		if not next(listeners[event]) then
			listeners[event] = nil
		end
	end
	if next(listeners) then
		self._listener_keys[key] = nil
	else
		self._listeners = nil
		self._listener_keys = nil
	end
end
function EventListenerHolder:_add(key, event_types, clbk)
	local listeners = self._listeners
	if not listeners then
		self._listeners = {}
		self._listener_keys = {}
		listeners = self._listeners
	end
	for _, event in pairs(event_types) do
		listeners[event] = listeners[event] or {}
		listeners[event][key] = clbk
	end
	self._listener_keys[key] = event_types
end
function EventListenerHolder:_set_trash(key)
	self._trash = self._trash or {}
	self._trash[key] = true
	if self._additions then
		self._additions[key] = nil
	end
end
function EventListenerHolder:_set_new(key, event_types, clbk)
	self._additions = self._additions or {}
	self._additions[key] = {clbk, event_types}
	if self._trash then
		self._trash[key] = nil
	end
end
function EventListenerHolder:_append_new_additions()
	if self._additions then
		local listeners = self._listeners
		if not listeners then
			self._listeners = {}
			self._listener_keys = {}
			listeners = self._listeners
		end
		for key, new_entry in pairs(self._additions) do
			for _, event in ipairs(new_entry[2]) do
				listeners[event] = listeners[event] or {}
				listeners[event][key] = new_entry[1]
			end
			self._listener_keys[key] = new_entry[2]
		end
		self._additions = nil
	end
end
function EventListenerHolder:_dispose_trash()
	if self._trash then
		for key, _ in pairs(self._trash) do
			self:_remove(key)
		end
		self._trash = nil
	end
end
function EventListenerHolder:_not_trash(key)
	return not self._trash or not self._trash[key]
end
