local DEV = false
local VERSION = "v1.5b"

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

--- Version comparison method inspired by @ForeverHD's TopbarPlus!
--- @return boolean -- True if module is up to date, false otherwise.
local function UpToDate()
	local asset = 85110005799468 -- Official Roblox model
	
	local name = ""
	repeat
		local success, info = pcall(function()
			return MarketplaceService:GetProductInfoAsync(asset)
		end)
		if success and info then
			name = info.Name
			break
		end
		task.wait(1)
	until name ~= ""
	
	local latestVersion = VERSION
	latestVersion = string.match(name, "^Facial Unification (.*)$")
	return latestVersion ~= nil and latestVersion == VERSION
end

if DEV or not RunService:IsStudio() then
	local creator = Players:GetNameFromUserIdAsync(1371995) -- Dogutsune
	print(`🙂 Running Facial Unification ({VERSION}) by @{creator}`)
end

if not UpToDate() then
	warn("⚠️ Facial Unification is not the same version as the model! You can check the official DevForum post at: https://devforum.roblox.com/t/4312162")
end

return {}
