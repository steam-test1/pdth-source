core:module("CoreGTextureManager")
GTextureManager = GTextureManager or class()
function GTextureManager:init()
	self._preloaded = {}
	self._global_texture = nil
	self._texture_name = nil
	self._texture_type = nil
	self._texture = nil
	self._delay = nil
end
function GTextureManager:set_texture(texture_name, texture_type, delay)
	self._delay = SystemInfo:platform() ~= Idstring("PS3") and delay
	self._texture_name = texture_name
	self._texture_type = texture_type
	if delay then
		TextureCache:request(texture_name, texture_type, function()
		end)
	else
		self:_retrieve()
	end
end
function GTextureManager:preload(textures, texture_type)
	if type(textures) == "string" then
		if not self._preloaded[textures] then
			self._preloaded[textures] = TextureCache:retrieve(textures, texture_type)
		end
	else
		for _, v in ipairs(textures) do
			if not self._preloaded[v.name] then
				self._preloaded[v.name] = TextureCache:retrieve(v.name, v.type)
			end
		end
	end
end
function GTextureManager:current_texture_name()
	return self._texture_name
end
function GTextureManager:prepare_full_load(new)
	self:_unretrieve()
	new._preloaded = self._preloaded
end
function GTextureManager:is_streaming()
	return self._delay ~= nil
end
function GTextureManager:reload()
	if self._texture then
		self:_retrieve()
	end
end
function GTextureManager:update(t, dt)
	if self._delay then
		self._delay = self._delay - dt
		if self._delay <= 0 then
			self:_retrieve()
			self._delay = nil
		end
	end
end
function GTextureManager:paused_update(t, dt)
	self:update(t, dt)
end
function GTextureManager:destroy()
	self:_unretrieve()
	self:_unref_preloaded()
end
function GTextureManager:_unref_preloaded()
	for _, v in pairs(self._preloaded) do
		TextureCache:unretrieve(v)
	end
end
function GTextureManager:_unretrieve()
	if self._texture then
		GlobalTextureManager:set_texture("current_global_texture", nil)
		TextureCache:unretrieve(self._texture)
		self._texture = nil
	end
end
function GTextureManager:_retrieve()
	self:_unretrieve()
	self._texture = TextureCache:retrieve(self._texture_name, self._texture_type)
	GlobalTextureManager:set_texture("current_global_texture", self._texture)
end
