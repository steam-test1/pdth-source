core:module("CoreTable")
core:import("CoreClass")
core:import("CoreDebug")
function clone(o)
	local res = {}
	for k, v in pairs(o) do
		res[k] = v
	end
	setmetatable(res, getmetatable(o))
	return res
end
function deep_clone(o)
	if type(o) == "userdata" then
		return o
	end
	local res = {}
	setmetatable(res, getmetatable(o))
	for k, v in pairs(o) do
		if type(v) == "table" then
			res[k] = deep_clone(v)
		else
			res[k] = v
		end
	end
	return res
end
function dpairs(vector_table)
	if type(table) ~= "table" then
		error("Expected table got", type(vector_table))
	end
	local t = vector_table
	local i = 0
	local last_size = #t
	return function()
		if last_size == #t then
			i = i + 1
		end
		local v = t[i]
		if v then
			last_size = #t
			return i, v
		end
	end
end
function table.tuple_iterator(v, n)
	local index = 1 - n
	local count = #v
	return function()
		index = index + n
		if index <= count then
			return unpack(v, index, index + n - 1)
		end
	end
end
function table.sorted_map_iterator(map, key_comparator_func)
	local sorted_keys = table.map_keys(map)
	local index = 0
	local count = #sorted_keys
	table.sort(sorted_keys, key_comparator_func)
	return function()
		index = index + 1
		if index <= count then
			local key = sorted_keys[index]
			return key, map[key]
		end
	end
end
function table.map_copy(map)
	local copy = {}
	for k, v in pairs(map) do
		copy[k] = v
	end
	return copy
end
function table.list_copy(list)
	local copy = {}
	for k, v in ipairs(list) do
		copy[k] = v
	end
	return copy
end
function table.get_vector_index(v, e)
	for index, value in ipairs(v) do
		if value == e then
			return index
		end
	end
end
function table.delete(v, e)
	local index = table.get_vector_index(v, e)
	if index then
		table.remove(v, index)
	end
end
function table.exclude(t, e)
	local filtered = {}
	for _, v in ipairs(t) do
		if v ~= e then
			table.insert(filtered, v)
		end
	end
	return filtered
end
function table.equals(a, b, value_compare_func)
	value_compare_func = value_compare_func or function(va, vb)
		return va == vb
	end
	local size_a = 0
	for k, v in pairs(a) do
		size_a = size_a + 1
		if value_compare_func(v, b[k]) == false then
			return false
		end
	end
	return size_a == table.size(b)
end
function table.contains(v, e)
	for _, value in pairs(v) do
		if value == e then
			return true
		end
	end
	return false
end
function table.index_of(v, e)
	for index, value in ipairs(v) do
		if value == e then
			return index
		end
	end
	return -1
end
function table.get_key(map, wanted_key_value)
	for key, value in pairs(map) do
		if value == wanted_key_value then
			return key
		end
	end
	return nil
end
function table.has(v, k)
	for key, _ in pairs(v) do
		if key == k then
			return true
		end
	end
	return false
end
function table.size(v)
	local i = 0
	for _, _ in pairs(v) do
		i = i + 1
	end
	return i
end
function table.empty(v)
	return not next(v)
end
function table.concat_map(map, concat_values, none_string, wrap, sep, last_sep)
	local count = 0
	local function func()
		return none_string
	end
	wrap = wrap or "\""
	sep = sep or ", "
	last_sep = last_sep or " and "
	for key, value in pairs(map) do
		do
			local last_func = func
			local append_string
			if concat_values then
				append_string = tostring(value)
			else
				append_string = tostring(key)
			end
			function func(count, first)
				if count == 1 then
					return wrap .. append_string .. wrap
				elseif first then
					return last_func(count - 1, false) .. last_sep .. wrap .. append_string .. wrap
				else
					return last_func(count - 1, false) .. sep .. wrap .. append_string .. wrap
				end
			end
			count = count + 1
		end
	end
	return func(count, true)
end
function table.ordering(prioritized_order_list)
	return function(a, b)
		local a_index = table.get_vector_index(prioritized_order_list, a)
		local b_index = table.get_vector_index(prioritized_order_list, b)
		if a_index == nil and b_index == nil then
			return a < b
		elseif a_index or b_index then
			return b_index == nil
		else
			return a_index < b_index
		end
	end
end
function table.sorted_copy(t, predicate)
	local sorted_copy = {}
	for _, value in ipairs(t) do
		table.insert(sorted_copy, value)
	end
	table.sort(sorted_copy, predicate)
	return sorted_copy
end
function table.find_value(t, func)
	for _, value in ipairs(t) do
		if func(value) then
			return value
		end
	end
end
function table.find_all_values(t, func)
	local matches = {}
	for _, value in ipairs(t) do
		if func(value) then
			table.insert(matches, value)
		end
	end
	return matches
end
function table.true_for_all(t, predicate)
	for key, value in pairs(t) do
		if not predicate(value, key) then
			return false
		end
	end
	return true
end
function table.collect(t, func)
	local result = {}
	for key, value in pairs(t) do
		result[key] = func(value)
	end
	return result
end
function table.inject(t, initial, func)
	local result = initial
	for _, value in ipairs(t) do
		result = func(result, value)
	end
	return result
end
function table.insert_sorted(t, item, comparator_func)
	if item == nil then
		return
	end
	comparator_func = comparator_func or function(a, b)
		return a < b
	end
	local index = 1
	local examined_item = t[index]
	while examined_item and comparator_func(examined_item, item) do
		index = index + 1
		examined_item = t[index]
	end
	table.insert(t, index, item)
end
function table.for_each_value(t, func)
	for _, value in ipairs(t) do
		func(value)
	end
end
function table.range(s, e)
	local range = {}
	for i = s, e do
		table.insert(range, i)
	end
	return range
end
function table.unpack_sparse(sparse_list)
	table.__unpack_sparse_implementations = table.__unpack_sparse_implementations or {}
	local count = 0
	for index, _ in pairs(sparse_list) do
		count = math.max(count, index)
	end
	local func = table.__unpack_sparse_implementations[count]
	if func == nil then
		local return_values = table.collect(table.range(1, count), function(i)
			return "__list__[" .. i .. "]"
		end)
		local return_value_string = table.concat(return_values, ", ")
		local code = "return function( __list__ ) return " .. return_value_string .. " end"
		func = assert(loadstring(code))()
		table.__unpack_sparse_implementations[count] = func
	end
	return func(sparse_list)
end
function table.unpack_map(map)
	return unpack(table.map_to_list(map))
end
function table.map_to_list(map)
	local list = {}
	for k, v in pairs(map) do
		table.insert(list, k)
		table.insert(list, v)
	end
	return list
end
function table.map_keys(map, sort_func)
	local keys = {}
	for key, _ in pairs(map) do
		table.insert(keys, key)
	end
	table.sort(keys, sort_func)
	return keys
end
function table.map_values(map, sort_func)
	local values = {}
	for _, value in pairs(map) do
		table.insert(values, value)
	end
	if sort_func ~= nil then
		table.sort(values, sort_func)
	end
	return values
end
function table.remap(map, remap_func)
	local result = {}
	for k, v in pairs(map) do
		result_k, result_v = remap_func(k, v)
		result[result_k] = result_v
	end
	return result
end
function table.list_add(...)
	local result = {}
	for _, list_table in ipairs({
		...
	}) do
		for _, value in ipairs(list_table) do
			table.insert(result, value)
		end
	end
	return result
end
function table.list_union(...)
	local unique = {}
	for _, list_table in ipairs({
		...
	}) do
		for _, value in ipairs(list_table) do
			unique[value] = true
		end
	end
	local result = {}
	for key, _ in pairs(unique) do
		table.insert(result, key)
	end
	return result
end
function table.print_data(data, t)
	if type(data) == "table" then
		t = t or ""
		for k, v in pairs(data) do
			if type(v) ~= "userdata" then
				CoreDebug.cat_debug("debug", t .. tostring(k) .. "=" .. tostring(v))
			else
				CoreDebug.cat_debug("debug", t .. tostring(k) .. "=" .. CoreClass.type_name(v))
			end
			if type(v) == "table" then
				table.print_data(v, t .. "\t")
			end
		end
	else
		CoreDebug.cat_debug("debug", CoreClass.type_name(data), tostring(data))
	end
end
if Application:ews_enabled() then
	do
		local __lua_representation, __write_lua_representation_to_file
		function __lua_representation(value)
			local t = type(value)
			if t == "string" then
				return string.format("%q", value)
			elseif t == "number" or t == "boolean" then
				return tostring(value)
			else
				error("Unable to generate Lua representation of type \"" .. t .. "\".")
			end
		end
		function __write_lua_representation_to_file(value, file, indentation)
			indentation = indentation or 1
			local t = type(value)
			if t == "table" then
				local indent = string.rep("\t", indentation)
				file:write("{\n")
				for key, value in pairs(value) do
					assert(type(key) ~= "table", "Using a table for a key is unsupported.")
					file:write(indent .. "[" .. __lua_representation(key) .. "] = ")
					__write_lua_representation_to_file(value, file, indentation + 1)
					file:write(";\n")
				end
				file:write(string.rep("\t", indentation - 1) .. "}")
			elseif t == "string" or t == "number" or t == "boolean" then
				file:write(__lua_representation(value))
			else
				error("Unable to generate Lua representation of type \"" .. t .. "\".")
			end
		end
		function write_lua_representation_to_path(value, path)
			assert(type(path) == "string", "Invalid path argument. Expected string.")
			local file = io.open(path, "w")
			file:write("return ")
			__write_lua_representation_to_file(value, file)
			file:close()
		end
		function read_lua_representation_from_path(path)
			assert(type(path) == "string", "Invalid path argument. Expected string.")
			local file = io.open(path, "r")
			local script = file and file:read("*a")
			file:close()
			return script and loadstring(script)() or {}
		end
	end
end
