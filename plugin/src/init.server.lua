if not plugin then
	return
end

local RojoScanner = script:FindFirstAncestor("RojoScanner")
local Packages = RojoScanner.Packages

local Roact = require(Packages.Roact)

local App = require(script.App)

local app = Roact.createElement(App, {
	plugin = plugin
})
local tree = Roact.mount(app, game:GetService("CoreGui"), "Rojo Scanner UI")

plugin.Unloading:Connect(function()
	Roact.unmount(tree)
end)
