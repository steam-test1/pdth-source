core:module("CoreEvent")
core:import("CoreDebug")
function callback(o, base_callback_class, base_callback_func_name, base_callback_param)
	if base_callback_class and base_callback_func_name and base_callback_class[base_callback_func_name] then
		if base_callback_param ~= nil then
			if o then
				return function(...)
					return base_callback_class[base_callback_func_name](o, base_callback_param, ...)
				end
			else
				return function(...)
					return base_callback_class[base_callback_func_name](base_callback_param, ...)
				end
			end
		elseif o then
			return function(...)
				return base_callback_class[base_callback_func_name](o, ...)
			end
		else
			return function(...)
				return base_callback_class[base_callback_func_name](...)
			end
		end
	elseif base_callback_class then
		local class_name = base_callback_class and CoreDebug.class_name(getmetatable(base_callback_class) or base_callback_class)
		error("Callback on class \"" .. tostring(class_name) .. "\" refers to a non-existing function \"" .. tostring(base_callback_func_name) .. "\".")
	elseif base_callback_func_name then
		error("Callback to function \"" .. tostring(base_callback_func_name) .. "\" is on a nil class.")
	else
		error("Callback class and function was nil.")
	end
end
local tc = 0
function get_ticket(delay)
	return {
		delay,
		math.random(delay - 1)
	}
end
function valid_ticket(ticket)
	return tc % ticket[1] == ticket[2]
end
function update_tickets()
	tc = tc + 1
	if tc > 30 then
		tc = 0
	end
end
BasicEventHandling = {}
function BasicEventHandling:connect(event_name, callback_func, data)
	self._event_callbacks = self._event_callbacks or {}
	self._event_callbacks[event_name] = self._event_callbacks[event_name] or {}
	local function wrapped_func(...)
		callback_func(data, ...)
	end
	table.insert(self._event_callbacks[event_name], wrapped_func)
	return wrapped_func
end
function BasicEventHandling:disconnect(event_name, wrapped_func)
	if self._event_callbacks and self._event_callbacks[event_name] then
		table.delete(self._event_callbacks[event_name], wrapped_func)
		if table.empty(self._event_callbacks[event_name]) then
			self._event_callbacks[event_name] = nil
			if table.empty(self._event_callbacks) then
				self._event_callbacks = nil
			end
		end
	end
end
function BasicEventHandling:_has_callbacks_for_event(event_name)
	return self._event_callbacks ~= nil and self._event_callbacks[event_name] ~= nil
end
function BasicEventHandling:_send_event(event_name, ...)
	if self._event_callbacks then
		for _, wrapped_func in ipairs(self._event_callbacks[event_name] or {}) do
			wrapped_func(...)
		end
	end
end
CallbackHandler = CallbackHandler or class()
function CallbackHandler:init()
	self:clear()
end
function CallbackHandler:clear()
	self._t = 0
	self._sorted = {}
end
function CallbackHandler:__insert_sorted(cb)
	local i = 1
	while self._sorted[i] and (self._sorted[i].next == nil or cb.next > self._sorted[i].next) do
		i = i + 1
	end
	table.insert(self._sorted, i, cb)
end
function CallbackHandler:add(f, interval, times)
	times = times or -1
	local cb = {
		f = f,
		interval = interval,
		times = times,
		next = self._t + interval
	}
	self:__insert_sorted(cb)
	return cb
end
function CallbackHandler:remove(cb)
	if cb then
		cb.next = nil
	end
end
function CallbackHandler:update(dt)
	self._t = self._t + dt
	while true do
		local cb = self._sorted[1]
		if cb == nil then
			return
		elseif cb.next == nil then
			table.remove(self._sorted, 1)
		elseif cb.next > self._t then
			return
		else
			table.remove(self._sorted, 1)
			cb.f(cb, self._t)
			if cb.times >= 0 then
				cb.times = cb.times - 1
				if cb.times <= 0 then
					cb.next = nil
				end
			end
			if cb.next then
				cb.next = cb.next + cb.interval
				self:__insert_sorted(cb)
			end
		end
	end
end
CallbackEventHandler = CallbackEventHandler or class()
function CallbackEventHandler:init()
end
function CallbackEventHandler:add(func)
	self._callback_map = self._callback_map or {}
	self._callback_map[func] = true
end
function CallbackEventHandler:remove(func)
	if not self._callback_map or not self._callback_map[func] then
		return
	end
	if self._next_callback == func then
		self._next_callback = next(self._callback_map, self._next_callback)
	end
	self._callback_map[func] = nil
	if not next(self._callback_map) then
		self._callback_map = nil
	end
end
function CallbackEventHandler:dispatch(...)
	if self._callback_map then
		self._next_callback = next(self._callback_map)
		self._next_callback(...)
		while self._next_callback do
			self._next_callback = next(self._callback_map, self._next_callback)
			if self._next_callback then
				self._next_callback(...)
			end
		end
	end
end
function over(seconds, f)
	local t = 0
	while true do
		t = t + coroutine.yield()
		if seconds <= t then
			break
		end
		f(t / seconds, t)
	end
	f(1, seconds)
end
function seconds(s, t)
	if not t then
		return seconds, s, 0
	end
	if s and s <= t then
		return nil
	end
	local dt = coroutine.yield()
	t = t + dt
	if s and s < t then
		t = s
	end
	if s then
		return t, t / s, dt
	else
		return t, t, dt
	end
end
function wait(seconds)
	local t = 0
	while seconds > t do
		t = t + coroutine.yield()
	end
end
