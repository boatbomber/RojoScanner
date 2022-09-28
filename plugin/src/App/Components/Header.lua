local RojoScanner = script:FindFirstAncestor("RojoScanner")
local Plugin = RojoScanner.Plugin
local Packages = RojoScanner.Packages

local Roact = require(Packages.Roact)

local Theme = require(Plugin.App.Theme)
local Assets = require(Plugin.Assets)
local Config = require(Plugin.Config)
local Version = require(Plugin.Version)

local RadarSpinner = require(Plugin.App.Components.RadarSpinner)

local e = Roact.createElement

local function Header(props)
	return Theme.with(function(theme)
		return e("Frame", {
			Size = UDim2.new(1, 0, 0, 32),
			LayoutOrder = props.layoutOrder,
			BackgroundTransparency = 1,
		}, {
			Logo = e("ImageLabel", {
				Image = Assets.Images.Logo,
				ImageColor3 = theme.Header.LogoColor,
				ImageTransparency = props.transparency,

				Size = UDim2.new(0, 60, 0, 27),

				LayoutOrder = 1,
				BackgroundTransparency = 1,
			}),

			Icon = e(RadarSpinner, {
				transparency = props.transparency,
				enabled = props.scanning,
				layoutOrder = 2,
			}),

			Version = e("TextLabel", {
				Text = Version.display(Config.version),
				Font = Enum.Font.Gotham,
				TextSize = 14,
				TextColor3 = theme.Header.VersionColor,
				TextXAlignment = Enum.TextXAlignment.Right,
				TextTransparency = props.transparency,

				Size = UDim2.new(0, 40, 0, 14),

				LayoutOrder = 3,
				BackgroundTransparency = 1,
			}),

			Layout = e("UIListLayout", {
				VerticalAlignment = Enum.VerticalAlignment.Center,
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 5),
			}),
		})
	end)
end

return Header
