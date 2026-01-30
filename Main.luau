--!strict

------------------------------------------------------------------------------ 
-- == Facial Unification ==
-- Module which replaces all the dynamic heads with their classic 2D counterparts.
-- This script works without HTTP requests and it's updated manually by its creator.
-- "MY MODULE IS THE MODULE THAT CREATES THE HEAVENS!" - @Dogutsune, 2026
------------------------------------------------------------------------------ 

-- Sample script! Feel free to make alternative implementations.
--[[
local DEFAULT_HEAD = true
local FacialUnification = require(script:WaitForChild("FacialUnification")) 

game:GetService("Players").PlayerAdded:Connect(function(player)
	-- Reload Appearance!
	local function AppearanceLoad(character)
		if not character then
			return
		end
		local humanoid = character:WaitForChild("Humanoid", 1)
		if humanoid then
			FacialUnification:ConvertAnimatedHead(humanoid, DEFAULT_HEAD)
			humanoid.ApplyDescriptionFinished:Once(function()
				FacialUnification:ConvertAnimatedHead(humanoid, DEFAULT_HEAD)
			end)
		end
	end

	-- Character gets added? Good.
	player.CharacterAdded:Connect(AppearanceLoad)
	if player.Character then
		AppearanceLoad(player.Character, false)
	end
end)
]]

------------------------------------------------------------------------------

local EXCLUDED_ACCESSORIES = {"Eyebrow", "Eyelash"}

local Players = game:GetService("Players")
local ToHatModule : ModuleScript = script:WaitForChild("ToHat")
local TO_HAT = require(ToHatModule)
local ToFaceModule : ModuleScript = script:WaitForChild("ToFace")
local TO_FACE = require(ToFaceModule)

------------------------------------------------------------------------------ 

-- This thing will allow us to insert hats as MeshParts when they are enabled.
local DescHolder = Instance.new("HumanoidDescription")
DescHolder.HeadScale = 1
DescHolder.WidthScale = 1
DescHolder.DepthScale = 1
DescHolder.HeightScale = 1
DescHolder.BodyTypeScale = 0
DescHolder.ProportionScale = 0

------------------------------------------------------------------------------ 

--- Create a retexture from an existing Roblox hat, while preserving it's SpecialMesh or MeshPart properties.
--- @param name string -- The name of the retexture.
--- @param hatId number -- Roblox Asset ID for the Accessory.
--- @param texture number -- Roblox Asset ID for the retexture.
--- @return Accoutrement? -- Created hat, if any.
local function CreateRetexture(name : string, hatId : number, texture : number) : Accoutrement?
	local textureID = `rbxassetid://{texture}`
	DescHolder.HatAccessory = tostring(hatId)

	local R15 = Players:CreateHumanoidModelFromDescriptionAsync(DescHolder, Enum.HumanoidRigType.R15)
	local hat = R15:FindFirstChildWhichIsA("Accoutrement")
	if hat then
		hat.Name = name
		local handle = hat:FindFirstChild("Handle")
		if handle and handle:IsA("MeshPart") then
			handle.TextureID = textureID
		elseif handle and handle:IsA("BasePart") then
			local mesh = handle:FindFirstChildWhichIsA("SpecialMesh")
			if mesh and mesh:IsA("SpecialMesh") then
				mesh.TextureId = textureID
				return hat
			end
		end
	end

	return hat
end

------------------------------------------------------------------------------ 

local FacialU = {}

--- Convert a HumanoidDescription to use classic faces instead of animated heads.
--- Modifies the provided HumanoidDescription in-place by replacing dynamic head assets with classic 2D faces.
--- Removes eyebrows and eyelashes, and converts heads to either classic face decals or retextured hat accessories.
--- @param humanoidDescription HumanoidDescription -- The HumanoidDescription to modify in-place.
--- @param useDefaultHead boolean -- Use the default Roblox head (Head = 0) instead of the classic head mesh.
--- @return boolean -- True if a conversion was performed, false otherwise.
--- @return Accoutrement? -- Created hat accessory if the head was converted to a hat, nil otherwise.
function FacialU:ConvertFromHumanoidDescription(humanoidDescription : HumanoidDescription, useDefaultHead : boolean?): (boolean, Accoutrement?)
	assert(humanoidDescription, "Expected HumanoidDescription but got nil instead, please provide a humanoid description")

	useDefaultHead = useDefaultHead or false

	local ID = humanoidDescription.Head
	local removeFaceStuff = false
	local hatToCopy : Accoutrement?

	if TO_HAT[ID] then
		hatToCopy = CreateRetexture(TO_HAT[ID].Name, TO_HAT[ID].OriginalHat, TO_HAT[ID].Texture)

		humanoidDescription.Head = 0
		removeFaceStuff = true
	elseif TO_FACE[ID] then
		humanoidDescription.Face = TO_FACE[ID].Face
		humanoidDescription.Head = useDefaultHead and 0 or TO_FACE[ID].Head
		removeFaceStuff = true
	end

	-- We remove Eyelashes and Eyebrows.
	if removeFaceStuff then
		local getAccessories = humanoidDescription:GetAccessories(true)
		local setAccessories = {}
		for i, v in pairs(getAccessories) do
			local isInTable = table.find(EXCLUDED_ACCESSORIES, v.AccessoryType.Name or "Unknown") ~= nil
			if not isInTable then
				table.insert(setAccessories, v)
			end
		end

		humanoidDescription:SetAccessories(setAccessories, true)

		if hatToCopy and hatToCopy:IsA("Accoutrement") then
			local newHat = Instance.new("AccessoryDescription")
			newHat.AccessoryType = Enum.AccessoryType.Hat
			newHat.Instance = hatToCopy
			newHat.Parent = humanoidDescription
		end
	end

	return removeFaceStuff, hatToCopy
end

--- Convert animated faces to classic variants.
--- @param humanoid Humanoid -- The humanoid to modify.
--- @param useDefaultHead boolean -- Use the default Roblox head.
--- @return boolean -- Conversion state
function FacialU:ConvertAnimatedHead(humanoid : Humanoid, useDefaultHead : boolean?) : boolean
	if not humanoid then
		return false
	end
	useDefaultHead = useDefaultHead or false

	humanoid:WaitForChild("HumanoidDescription", 1) -- THIS IS A STUPID HACK, OKAY?
	local desc = humanoid:GetAppliedDescription() :: HumanoidDescription
	if desc then
		local wasConverted = self:ConvertFromHumanoidDescription(desc, useDefaultHead)

		if wasConverted then
			humanoid:ApplyDescriptionAsync(desc)
			humanoid.ApplyDescriptionFinished:Wait()
			return true
		end
	end

	return false
end

------------------------------------------------------------------------------ 

-- Prints attribution in the console.
local Attribution : ModuleScript = script:FindFirstChild("Attribution")
if Attribution and Attribution:IsA("ModuleScript") then 
	require(Attribution) 
end

return FacialU
