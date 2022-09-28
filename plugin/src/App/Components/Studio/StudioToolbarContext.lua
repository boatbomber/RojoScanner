local RojoScanner = script:FindFirstAncestor("RojoScanner")
local Packages = RojoScanner.Packages

local Roact = require(Packages.Roact)

local StudioToolbarContext = Roact.createContext(nil)

return StudioToolbarContext
