require("core/lib/compilers/CoreCompilerSystem")
CoreLuaPreprocessor = CoreLuaPreprocessor or class()
CoreLuaPreprocessor.preprocessors = {}
CoreLuaPreprocessor.ENABLED = false
CoreLuaPreprocessor.DEBUG = false
function CoreLuaPreprocessor:preprocess(path, code)
	if not self.ENABLED or string.find(path, "CoreLuaPreprocessor") then
		return code
	end
	cat_print("spam", "[CoreLuaPreprocessor] Preprocessing: " .. path)
	local out, nr = self:multiline(self:singleline(code, 0))
	out, nr = self:regx(out, nr, path)
	cat_print("spam", "[CoreLuaPreprocessor] " .. tostring(nr) .. " macros found.")
	if self.DEBUG and nr > 0 then
		cat_print("spam", out)
	end
	return out
end
function CoreLuaPreprocessor:regx(str, nr, path)
	local output = str
	for _, exp in ipairs(self.preprocessors) do
		local skip_file = false
		for _, skip in ipairs(exp.skip) do
			if string.find(path, skip) then
				skip_file = true
			else
			end
		end
		if not skip_file then
			local rep = 0
			output, rep = string.gsub(output, exp.regx, exp.sub)
			nr = nr + rep
		end
	end
	return output, nr
end
function CoreLuaPreprocessor:adjust_size(macro, args)
	local org = args[1] .. args[2] .. args[3]
	macro = string.gsub(macro, "\n", " ")
	local addlines = 0
	for s in string.gmatch(org, "\n") do
		addlines = addlines + 1
	end
	return macro .. string.rep("\n", addlines)
end
function CoreLuaPreprocessor:multiline(str, innr)
	local ret, nr = string.gsub(str, "(%-%-%[%[@)([^@%]%]]+)(@%]%])", function(...)
		local args = {
			...
		}
		if #args == 3 then
			local func, err = loadstring(args[2])
			if func then
				return self:adjust_size(tostring(func() or ""), args)
			else
				error("[CoreLuaPreprocessor] Invalid macro: " .. err)
			end
		end
	end)
	if nr > 0 then
		return self:multiline(ret, nr + innr)
	else
		return ret, innr
	end
end
function CoreLuaPreprocessor:singleline(str, innr)
	local ret, nr = string.gsub(str, [[
(%-%-@)([^
]+)]], function(...)
		local args = {
			...
		}
		if #args == 2 then
			local func, err = loadstring("return " .. args[2])
			if func then
				return tostring(func() or "")
			else
				error("[CoreLuaPreprocessor] Invalid macro: " .. err)
			end
		end
	end)
	if nr > 0 then
		return self:singleline(ret, nr + innr)
	else
		return ret, innr
	end
end
