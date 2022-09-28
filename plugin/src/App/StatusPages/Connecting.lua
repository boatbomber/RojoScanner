local RojoScanner = script:FindFirstAncestor("RojoScanner")
local Plugin = RojoScanner.Plugin
local Packages = RojoScanner.Packages

local Roact = require(Packages.Roact)

local RadarSpinner = require(Plugin.App.Components.RadarSpinner)

local e = Roact.createElement

local ConnectingPage = Roact.Component:extend("ConnectingPage")

function ConnectingPage:render()
	return e(RadarSpinner, {
		position = UDim2.new(0.5, 0, 0.5, 0),
		anchorPoint = Vector2.new(0.5, 0.5),
		transparency = self.props.transparency,
	})
end

return ConnectingPage
