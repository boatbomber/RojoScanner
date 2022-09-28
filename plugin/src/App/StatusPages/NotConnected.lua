local RojoScanner = script:FindFirstAncestor("RojoScanner")
local Plugin = RojoScanner.Plugin
local Packages = RojoScanner.Packages

local Roact = require(Packages.Roact)

local Assets = require(Plugin.Assets)

local Theme = require(Plugin.App.Theme)
local BorderedContainer = require(Plugin.App.Components.BorderedContainer)
local ScrollingFrame = require(Plugin.App.Components.ScrollingFrame)
local TextButton = require(Plugin.App.Components.TextButton)
local ImageButton = require(Plugin.App.Components.ImageButton)
local IconButton = require(Plugin.App.Components.IconButton)
local Header = require(Plugin.App.Components.Header)

local e = Roact.createElement

local Address = Roact.Component:extend("Address")

function Address:render()
	return Theme.with(function(theme)
		return e(BorderedContainer, {
			transparency = self.props.transparency,
			size = UDim2.new(1, 0, 0, 36),
			layoutOrder = self.props.layoutOrder,
			borderColor = if self.props.selected then theme.Header.LogoColor else nil,
		}, {
			Project = e("TextButton", {
				Size = UDim2.new(1, -230, 1, 0),
				Position = UDim2.new(0, 0, 0, 0),
				BackgroundTransparency = 1,
				Text = if self.props.scanning then "Scanning..." else self.props.project,
				TextColor3 = theme.ConnectionDetails.ProjectNameColor,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTransparency = self.props.transparency,
				TextSize = 17,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Font = Enum.Font.GothamMedium,

				[Roact.Event.Activated] = function()
					self.props.onSelectSlot(if self.props.selected then "none" else self.props.stamp)
				end,
			}),

			HostEntry = e("TextBox", {
				Size = UDim2.new(0, 140, 1, 0),
				Position = UDim2.new(1, -85, 0, 0),
				AnchorPoint = Vector2.new(1, 0),
				BackgroundTransparency = 1,
				Text = self.props.host,
				TextColor3 = theme.ConnectionDetails.AddressColor,
				TextXAlignment = Enum.TextXAlignment.Right,
				TextTransparency = self.props.transparency,
				TextSize = 18,
				ClearTextOnFocus = false,
				Font = Enum.Font.Code,

				[Roact.Event.FocusLost] = function(rbx)
					self.props.onHostChanged(self.props.stamp, rbx.Text)
				end,
			}),

			Divider = e("TextLabel", {
				Size = UDim2.new(0, 5, 1, 0),
				Position = UDim2.new(1, -80, 0, 0),
				AnchorPoint = Vector2.new(1, 0),
				BackgroundTransparency = 1,
				Text = ":",
				TextColor3 = theme.ConnectionDetails.AddressColor,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextTransparency = self.props.transparency,
				TextSize = 18,
				Font = Enum.Font.Code,
			}),

			PortEntry = e("TextBox", {
				Size = UDim2.new(0, 50, 1, 0),
				Position = UDim2.new(1, -30, 0, 0),
				AnchorPoint = Vector2.new(1, 0),
				BackgroundTransparency = 1,
				Text = self.props.port,
				TextColor3 = theme.ConnectionDetails.AddressColor,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTransparency = self.props.transparency,
				TextSize = 18,
				ClearTextOnFocus = false,
				Font = Enum.Font.Code,

				[Roact.Event.FocusLost] = function(rbx)
					self.props.onPortChanged(self.props.stamp, rbx.Text)
				end,
			}),

			Delete = e(IconButton, {
				iconSize = 18,
				icon = Assets.Images.Icons.Trash,
				color = theme.ConnectionDetails.DisconnectColor,
				position = UDim2.new(1, 0, 0.5 ,0),
				anchorPoint = Vector2.new(1, 0.5),
				transparency = self.props.transparency,

				onClick = function()
					self.props.onRemoveSlot(self.props.stamp)
				end,
			}),

			Padding = e("UIPadding", {
				PaddingLeft = UDim.new(0, 8),
				PaddingRight = UDim.new(0, 8),
			}),
		})
	end)
end

local NotConnectedPage = Roact.Component:extend("NotConnectedPage")

function NotConnectedPage:init()
	self.slotsSize, self.setSlotsSize = Roact.createBinding(Vector2.new(0, 0))
end

function NotConnectedPage:render()
	local slots = {}

	for stamp, data in self.props.addressSlots do
		slots[stamp] = e(Address, {
			stamp = stamp,
			host = data.host,
			port = data.port,
			project = data.project or "[Unknown]",
			scanning = data.scanning,
			transparency = self.props.transparency,
			layoutOrder = stamp,

			selected = self.props.selectedSlot == stamp,

			onHostChanged = self.props.onHostChanged,
			onPortChanged = self.props.onPortChanged,
			onRemoveSlot = self.props.onRemoveSlot,
			onSelectSlot = self.props.onSelectSlot,
		})
	end

	return Roact.createFragment({
		Header = e(Header, {
			transparency = self.props.transparency,
			layoutOrder = 1,
			scanning = self.props.scanning,
		}),

		ScrollFrame = e(ScrollingFrame, {
			transparency = self.props.transparency,
			size = UDim2.new(1, 0, 1, -105),
			layoutOrder = 2,
			contentSize = self.slotsSize,
		}, {
			Roact.createFragment(slots),

			Add = e(TextButton, {
				text = "Add",
				style = "Bordered",
				transparency = self.props.transparency,
				layoutOrder = 100000000,
				onClick = function()
					self.props.onAddSlot()
				end,
			}),

			Layout = e("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				Padding = UDim.new(0, 8),
				[Roact.Change.AbsoluteContentSize] = function(object)
					self.setSlotsSize(object.AbsoluteContentSize + Vector2.new(0, 6))
				end,
			}),

			Padding = e("UIPadding", {
				PaddingTop = UDim.new(0, 3),
				PaddingBottom = UDim.new(0, 3),
			}),
		}),

		Buttons = e("Frame", {
			Size = UDim2.new(1, 0, 0, 34),
			LayoutOrder = 3,
			BackgroundTransparency = 1,
		}, {
			Scan = e(ImageButton, {
				image = Assets.Images.ScanDish,
				style = "Bordered",
				transparency = self.props.transparency,
				layoutOrder = 0,
				onClick = self.props.onScan,
			}),

			Settings = e(TextButton, {
				text = "Settings",
				style = "Bordered",
				transparency = self.props.transparency,
				layoutOrder = 1,
				onClick = self.props.onNavigateSettings,
			}),

			Connect = e(TextButton, {
				text = "Connect",
				style = "Solid",
				enabled = self.props.addressSlots[self.props.selectedSlot] ~= nil,
				transparency = self.props.transparency,
				layoutOrder = 2,
				onClick = function()
					local slot = self.props.addressSlots[self.props.selectedSlot]
					if slot == nil then return end
					self.props.onConnect(slot.host, slot.port)
				end,
			}),

			Layout = e("UIListLayout", {
				HorizontalAlignment = Enum.HorizontalAlignment.Right,
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 10),
			}),
		}),

		Layout = e("UIListLayout", {
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 10),
		}),

		Padding = e("UIPadding", {
			PaddingLeft = UDim.new(0, 20),
			PaddingRight = UDim.new(0, 20),
		}),
	})
end

return NotConnectedPage
