--[[
	Persistent plugin settings.
]]

local plugin = plugin or script:FindFirstAncestorWhichIsA("Plugin")
local RojoScanner = script:FindFirstAncestor("RojoScanner")
local Packages = RojoScanner.Packages


local Roact = require(Packages.Roact)

local defaultSettings = {
	addressSlots = {},
	notifyFinds = true,
}

local Settings = {}

Settings._values = table.clone(defaultSettings)
Settings._updateListeners = {}
Settings._bindings = {}

if plugin then
	for name, defaultValue in pairs(Settings._values) do
		local savedValue = plugin:GetSetting("RojoScanner_" .. name)

		if savedValue == nil then
			-- plugin:SetSetting hits disc instead of memory, so it can be slow. Spawn so we don't hang.
			task.spawn(plugin.SetSetting, plugin, "RojoScanner_" .. name, defaultValue)
			Settings._values[name] = defaultValue
		else
			Settings._values[name] = savedValue
		end
	end
end

function Settings:get(name)
	if defaultSettings[name] == nil then
		error("Invalid setings name " .. tostring(name), 2)
	end

	return self._values[name]
end

function Settings:set(name, value)
	self._values[name] = value
	if self._bindings[name] then
		self._bindings[name].set(value)
	end

	if plugin then
		-- plugin:SetSetting hits disc instead of memory, so it can be slow. Spawn so we don't hang.
		task.spawn(plugin.SetSetting, plugin, "RojoScanner_" .. name, value)
	end

	if self._updateListeners[name] then
		for callback in pairs(self._updateListeners[name]) do
			task.spawn(callback, value)
		end
	end
end

function Settings:onChanged(name, callback)
	local listeners = self._updateListeners[name]
	if listeners == nil then
		listeners = {}
		self._updateListeners[name] = listeners
	end
	listeners[callback] = true

	return function()
		listeners[callback] = nil
	end
end

function Settings:getBinding(name)
	local cached = self._bindings[name]
	if cached then
		return cached.bind
	end

	local bind, set = Roact.createBinding(self._values[name])
	self._bindings[name] = {
		bind = bind,
		set = set,
	}

	return bind
end

return Settings
