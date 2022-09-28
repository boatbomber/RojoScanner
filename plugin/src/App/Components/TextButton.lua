local TextService = game:GetService("TextService")

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

local TextButton = Roact.Component:extend("TextButton")

function TextButton:init()
	local enabled = if self.props.enabled == nil then true else self.props.enabled
	self.motor = Flipper.GroupMotor.new({
		hover = 0,
		enabled = enabled and 1 or 0,
	})
	self.binding = bindingUtil.fromMotor(self.motor)
end

function TextButton:didUpdate(lastProps)
	if lastProps.enabled ~= self.props.enabled then
		local enabled = if self.props.enabled == nil then true else self.props.enabled
		self.motor:setGoal({
			enabled = Flipper.Spring.new(enabled and 1 or 0),
		})
	end
end

function TextButton:render()
	return Theme.with(function(theme)
		local textSize = TextService:GetTextSize(
			self.props.text, 18, Enum.Font.GothamMedium,
			Vector2.new(math.huge, math.huge)
		)

		local style = self.props.style

		theme = theme.Button[style]

		local bindingHover = bindingUtil.deriveProperty(self.binding, "hover")
		local bindingEnabled = bindingUtil.deriveProperty(self.binding, "enabled")

		return e("ImageButton", {
			Size = UDim2.new(0, 15 + textSize.X + 15, 0, 34),
			Position = self.props.position,
			AnchorPoint = self.props.anchorPoint,

			LayoutOrder = self.props.layoutOrder,
			BackgroundTransparency = 1,

			[Roact.Event.Activated] = function()
				if self.props.enabled == nil or self.props.enabled then
					self.props.onClick()
				end
			end,

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

			Text = e("TextLabel", {
				Text = self.props.text,
				Font = Enum.Font.GothamMedium,
				TextSize = 18,
				TextColor3 = bindingUtil.mapLerp(bindingEnabled, theme.Disabled.TextColor, theme.Enabled.TextColor),
				TextTransparency = self.props.transparency,

				Size = UDim2.new(1, 0, 1, 0),

				BackgroundTransparency = 1,
			}),

			Border = style == "Bordered" and e(SlicedImage, {
				slice = Assets.Slices.RoundedBorder,
				color = bindingUtil.mapLerp(bindingEnabled, theme.Disabled.BorderColor, theme.Enabled.BorderColor),
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
				color = bindingUtil.mapLerp(bindingEnabled, theme.Disabled.BackgroundColor, theme.Enabled.BackgroundColor),
				transparency = self.props.transparency,

				size = UDim2.new(1, 0, 1, 0),

				zIndex = -2,
			}),
		})
	end)
end

return TextButton
