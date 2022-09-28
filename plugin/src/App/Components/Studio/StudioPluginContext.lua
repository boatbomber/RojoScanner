local RojoScanner = script:FindFirstAncestor("RojoScanner")
local Packages = RojoScanner.Packages

local Roact = require(Packages.Roact)

local StudioPluginContext = Roact.createContext(nil)

return StudioPluginContext
