local RojoScanner = script:FindFirstAncestor("RojoScanner")
local Plugin = RojoScanner.Plugin
local Packages = RojoScanner.Packages

local Roact = require(Packages.Roact)

local Settings = require(Plugin.Settings)
local Assets = require(Plugin.Assets)
local Version = require(Plugin.Version)
local Config = require(Plugin.Config)
local strict = require(Plugin.strict)
local Dictionary = require(Plugin.Dictionary)
local preloadAssets = require(Plugin.preloadAssets)
local Theme = require(script.Theme)

local Page = require(script.Page)
local StudioToolbar = require(script.Components.Studio.StudioToolbar)
local StudioToggleButton = require(script.Components.Studio.StudioToggleButton)
local StudioPluginGui = require(script.Components.Studio.StudioPluginGui)
local StudioPluginContext = require(script.Components.Studio.StudioPluginContext)
local StatusPages = require(script.StatusPages)

local plugin = plugin or script:FindFirstAncestorWhichIsA("Plugin")

local Rojo = require(game:WaitForChild("Rojo", math.huge))

Rojo.API:RequestAccess(plugin, {
	-- Properties
	"Connected", "Address", "ProjectName",
	-- Events
	"Changed",
	-- Methods
	"ConnectAsync", "DisconnectAsync", "GetHostAndPort", "CreateApiContext", "Notify",
})

local AppStatus = strict("AppStatus", {
	NotConnected = "NotConnected",
	Settings = "Settings",
	Connecting = "Connecting",
	Connected = "Connected",
	Error = "Error",
})

local e = Roact.createElement

local App = Roact.Component:extend("App")

function App:init()
	preloadAssets()

	self.pluginName = "Rojo Scanner " .. Version.display(Config.version)

	local addressSlots = table.clone(Settings:get("addressSlots") or {})
	for stamp, data in addressSlots do
		data.project = "[Unknown]"
		data.scanning = false
		data.found = false
	end

	self:setState({
		appStatus = Rojo.API.Connected and AppStatus.Connected or AppStatus.NotConnected,
		connection = {
			address = Rojo.API.Address,
			project = Rojo.API.ProjectName,
		},

		guiEnabled = false,
		toolbarIcon = Assets.Images.PluginButton,

		addressSlots = addressSlots,
	})

	Rojo.API.Changed:Connect(function(prop, value)
		if prop == "Connected" then
			self:setState({
				appStatus = value and AppStatus.Connected or AppStatus.NotConnected,
			})
		elseif prop == "Address" then
			self:setState({
				connection = {
					address = value,
					project = Rojo.API.ProjectName,
				},
			})
		elseif prop == "ProjectName" then
			self:setState({
				connection = {
					address = Rojo.API.Address,
					project = value,
				},
			})
		end
	end)

	self.scanThread = task.spawn(function()
		while true do
			if self.state.guiEnabled and not Rojo.API.Connected then
				self:scanSlots()
			end
			task.wait(10)
		end
	end)
end

function App:willUnmount()
	task.cancel(self.scanThread)
end

function App:addSlot(address: string)
	local addressSlots = self.state.addressSlots
	local newAddressSlots = Dictionary.merge(addressSlots, {
		[tostring(DateTime.now().UnixTimestampMillis)] = {
			host = string.match(address, "^(.-):"),
			port = string.match(address, ":(%d+)$"),
			project = "[Unknown]",
			scanning = false,
			found = false,
		},
	})

	Settings:set("addressSlots", newAddressSlots)
	self:setState({
		addressSlots = newAddressSlots,
	})

	task.defer(self.scanSlots, self)
end

function App:removeSlot(stamp)
	local addressSlots = self.state.addressSlots
	local newAddressSlots = table.clone(addressSlots)
	newAddressSlots[stamp] = nil

	Settings:set("addressSlots", newAddressSlots)
	self:setState({
		addressSlots = newAddressSlots,
	})
end

function App:editSlot(stamp, newData)
	local addressSlots = self.state.addressSlots
	if addressSlots[stamp] == nil then return end

	local newAddressSlots = table.clone(addressSlots)
	newAddressSlots[stamp] = Dictionary.merge(newAddressSlots[stamp], newData)

	Settings:set("addressSlots", newAddressSlots)
	self:setState({
		addressSlots = newAddressSlots,
	})
end

function App:startSession(host: string?, port: string?)
	Rojo.API:ConnectAsync(host, port)
end

function App:endSession()
	Rojo.API:DisconnectAsync()
end

function App:findServedProject(host: string?, port: string?)
	if host == nil or port == nil then
		host, port = Rojo.API:GetHostAndPort()
	end

	local baseUrl = string.format("http://%s:%s", host :: string, port :: string)
	local apiContext = Rojo.API:CreateApiContext(baseUrl)

	local _, found, value = apiContext:connect()
		:andThen(function(serverInfo)
			apiContext:disconnect()
			return true, serverInfo.projectName
		end)
		:catch(function(err)
			return false, err
		end):await()

	return found, value
end

function App:scanSlots()
	if self.state.scanning then return end

	self:setState({
		scanning = true
	})

	local expected, completed = 0, 0
	for stamp, data in self.state.addressSlots do
		expected += 1
		self:editSlot(stamp, {
			scanning = true,
		})
		task.spawn(function()
			local found, value = self:findServedProject(data.host, data.port)
			completed += 1

			if found and Settings:get("notifyFinds") and self.state.addressSlots[stamp] and self.state.addressSlots[stamp].found == false then
				Rojo.API:Notify(string.format("Found project '%s' at %s:%s", value, data.host, data.port), 10)
			end

			self:editSlot(stamp, {
				project = found and value or "[Empty]",
				scanning = false,
				found = found,
			})
		end)
	end

	task.spawn(function()
		while completed < expected do
			task.wait(1/5)
		end
		self:setState({
			scanning = false
		})
	end)
end

function App:render()

	local function createPageElement(appStatus, additionalProps)
		additionalProps = additionalProps or {}

		local props = Dictionary.merge(additionalProps, {
			component = StatusPages[appStatus],
			active = self.state.appStatus == appStatus,
		})

		return e(Page, props)
	end

	return e(StudioPluginContext.Provider, {
		value = self.props.plugin,
	}, {
		e(Theme.StudioProvider, nil, {
			gui = e(StudioPluginGui, {
				id = self.pluginName,
				title = self.pluginName,
				active = self.state.guiEnabled,

				initDockState = Enum.InitialDockState.Right,
				initEnabled = false,
				overridePreviousState = false,
				floatingSize = Vector2.new(380, 200),
				minimumSize = Vector2.new(360, 150),

				zIndexBehavior = Enum.ZIndexBehavior.Sibling,

				onInitialState = function(initialState)
					self:setState({
						guiEnabled = initialState,
					})
				end,

				onClose = function()
					self:setState({
						guiEnabled = false,
					})
				end,
			}, {
				NotConnectedPage = createPageElement(AppStatus.NotConnected, {
					addressSlots = self.state.addressSlots,
					scanning = self.state.scanning,
					selectedSlot = self.state.selectedSlot,

					onSelectSlot = function(stamp)
						self:setState({
							selectedSlot = stamp,
						})
					end,

					onAddSlot = function()
						local host, port = Rojo.API:GetHostAndPort()
						self:addSlot(host .. ":" .. port)
					end,

					onRemoveSlot = function(stamp)
						self:removeSlot(stamp)
					end,

					onHostChanged = function(stamp, host)
						self:editSlot(stamp, {
							host = host,
							found = false,
							project = "[Unknown]",
						})
						self:scanSlots()
					end,

					onPortChanged = function(stamp, port)
						self:editSlot(stamp, {
							port = port,
							found = false,
							project = "[Unknown]",
						})
						self:scanSlots()
					end,

					onConnect = function(host: string?, port: string?)
						self:startSession(host, port)
					end,

					onScan = function()
						self:scanSlots()
					end,

					onNavigateSettings = function()
						self:setState({
							appStatus = AppStatus.Settings,
						})
					end,
				}),

				Connecting = createPageElement(AppStatus.Connecting),

				Connected = createPageElement(AppStatus.Connected, {
					projectName = self.state.connection.project,
					address = self.state.connection.address,

					onDisconnect = function()
						self:endSession()
					end,
				}),

				Settings = createPageElement(AppStatus.Settings, {
					onBack = function()
						self:setState({
							appStatus = AppStatus.NotConnected,
						})
					end,
				}),

				Error = createPageElement(AppStatus.Error, {
					errorMessage = self.state.errorMessage,

					onClose = function()
						self:setState({
							appStatus = AppStatus.NotConnected,
							toolbarIcon = Assets.Images.PluginButton,
						})
					end,
				}),

				Background = Theme.with(function(theme)
					return e("Frame", {
						Size = UDim2.new(1, 0, 1, 0),
						BackgroundColor3 = theme.BackgroundColor,
						ZIndex = 0,
						BorderSizePixel = 0,
					})
				end),
			}),

			toolbar = e(StudioToolbar, {
				name = self.pluginName,
			}, {
				button = e(StudioToggleButton, {
					name = "Rojo Scanner",
					tooltip = "Show or hide the Rojo Scanner panel",
					icon = self.state.toolbarIcon,
					active = self.state.guiEnabled,
					enabled = true,
					onClick = function()
						self:setState(function(state)
							return {
								guiEnabled = not state.guiEnabled,
							}
						end)
						if self.state.guiEnabled then
							self:scanSlots()
						end
					end,
				})
			}),
		}),
	})
end

return App
