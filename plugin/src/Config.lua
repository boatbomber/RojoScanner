local strict = require(script.Parent.strict)

local isDevBuild = script.Parent.Parent:FindFirstChild("ROJO_DEV_BUILD") ~= nil

return strict("Config", {
	isDevBuild = isDevBuild,
	codename = "Epiphany",
	version = {0, 1, 0},
	expectedServerVersionString = "0.1 or newer",
	protocolVersion = 1,
	defaultHost = "localhost",
	defaultPort = "34872",
})
