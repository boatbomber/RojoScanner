local RunService = game:GetService("RunService")

local RojoScanner = script:FindFirstAncestor("RojoScanner")
local Plugin = RojoScanner.Plugin
local Packages = RojoScanner.Packages

local Roact = require(Packages.Roact)

local Theme = require(Plugin.App.Theme)
local Assets = require(Plugin.Assets)

local ROTATIONS_PER_SECOND = 1.75

local e = Roact.createElement

local Spinner = Roact.PureComponent:extend("Spinner")

function Spinner:init()
	self.rotation, self.setRotation = Roact.createBinding(0)
end

function Spinner:render()
	return Theme.with(function(theme)
		return e("Frame", {
			Size = UDim2.new(0, 24, 0, 24),
			Position = self.props.position,
			AnchorPoint = self.props.anchorPoint,
			LayoutOrder = self.props.layoutOrder,
			BackgroundTransparency = 1,
		}, {
			Icon = e("ImageLabel", {
				Image = Assets.Images.RadarSpinner,
				ImageColor3 = theme.RadarSpinner.ForegroundColor,
				ImageTransparency = self.props.transparency,
				BackgroundTransparency = 1,

				Size = UDim2.fromScale(1, 1),
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Rotation = self.rotation:map(function(value)
					return value * 360
				end),
			}),
		})
	end)
end

function Spinner:didMount()
	self.stepper = RunService.RenderStepped:Connect(function(deltaTime)
		local rotation = self.rotation:getValue()

		if self.props.enabled then
			rotation = rotation + deltaTime * ROTATIONS_PER_SECOND
			rotation = rotation % 1
		else
			rotation = 0
		end

		self.setRotation(rotation)
	end)
end

function Spinner:willUnmount()
	self.stepper:Disconnect()
end

return Spinner
