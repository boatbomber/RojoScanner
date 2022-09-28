local RojoScanner = script:FindFirstAncestor("RojoScanner")
local Plugin = RojoScanner.Plugin
local Packages = RojoScanner.Packages

local Roact = require(Packages.Roact)
local Flipper = require(Packages.Flipper)

local Theme = require(Plugin.App.Theme)
local Assets = require(Plugin.Assets)
local bindingUtil = require(Plugin.App.bindingUtil)

local SlicedImage = require(script.Parent.SlicedImage)
local TouchRipple = require(script.Parent.TouchRipple)

local SPRING_PROPS = {
	frequency = 5,
	dampingRatio = 1,
}

local e = Roact.createElement

local ImageButton = Roact.Component:extend("ImageButton")

function ImageButton:init()
	self.motor = Flipper.GroupMotor.new({
		hover = 0,
		enabled = self.props.enabled and 1 or 0,
	})
	self.binding = bindingUtil.fromMotor(self.motor)
end

function ImageButton:didUpdate(lastProps)
	if lastProps.enabled ~= self.props.enabled then
		self.motor:setGoal({
			enabled = Flipper.Spring.new(self.props.enabled and 1 or 0),
		})
	end
end

function ImageButton:render()
	return Theme.with(function(theme)
		local style = self.props.style

		theme = theme.Button[style]

		local bindingHover = bindingUtil.deriveProperty(self.binding, "hover")
		local bindingEnabled = bindingUtil.deriveProperty(self.binding, "enabled")

		return e("ImageButton", {
			Size = UDim2.new(0, 34, 0, 34),
			Position = self.props.position,
			AnchorPoint = self.props.anchorPoint,

			LayoutOrder = self.props.layoutOrder,
			BackgroundTransparency = 1,

			[Roact.Event.Activated] = self.props.onClick,

			[Roact.Event.MouseEnter] = function()
				self.motor:setGoal({
					hover = Flipper.Spring.new(1, SPRING_PROPS),
				})
			end,

			[Roact.Event.MouseLeave] = function()
				self.motor:setGoal({
					hover = Flipper.Spring.new(0, SPRING_PROPS),
				})
			end,
		}, {
			TouchRipple = e(TouchRipple, {
				color = theme.ActionFillColor,
				transparency = self.props.transparency:map(function(value)
					return bindingUtil.blendAlpha({ theme.ActionFillTransparency, value })
				end),
				zIndex = 2,
			}),

			Image = e("ImageLabel", {
				Image = self.props.image,
				ImageColor3 = bindingUtil.mapLerp(bindingEnabled, theme.Enabled.TextColor, theme.Disabled.TextColor),
				ImageTransparency = self.props.transparency,
				BackgroundTransparency = 1,
				ScaleType = Enum.ScaleType.Fit,
				Size = UDim2.new(0.7, 0, 0.7, 0),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				AnchorPoint = Vector2.new(0.5, 0.5),
			}),

			Border = style == "Bordered" and e(SlicedImage, {
				slice = Assets.Slices.RoundedBorder,
				color = bindingUtil.mapLerp(bindingEnabled, theme.Enabled.BorderColor, theme.Disabled.BorderColor),
				transparency = self.props.transparency,

				size = UDim2.new(1, 0, 1, 0),

				zIndex = 0,
			}),

			HoverOverlay = e(SlicedImage, {
				slice = Assets.Slices.RoundedBackground,
				color = theme.ActionFillColor,
				transparency = Roact.joinBindings({
					hover = bindingHover:map(function(value)
						return 1 - value
					end),
					transparency = self.props.transparency,
				}):map(function(values)
					return bindingUtil.blendAlpha({ theme.ActionFillTransparency, values.hover, values.transparency })
				end),

				size = UDim2.new(1, 0, 1, 0),

				zIndex = -1,
			}),

			Background = style == "Solid" and e(SlicedImage, {
				slice = Assets.Slices.RoundedBackground,
				color = bindingUtil.mapLerp(bindingEnabled, theme.Enabled.BackgroundColor, theme.Disabled.BackgroundColor),
				transparency = self.props.transparency,

				size = UDim2.new(1, 0, 1, 0),

				zIndex = -2,
			}),
		})
	end)
end

return ImageButton
