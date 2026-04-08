--!strict

------------------------------------------------------------------------------ 
-- == Facial Unification ==
-- Module which replaces all the dynamic heads with their classic 2D counterparts.
-- This script works without HTTP requests and it's updated manually by its creator.
-- "MY MODULE IS THE MODULE THAT CREATES THE HEAVENS!" - @Dogutsune, 2026
------------------------------------------------------------------------------ 
-- Big thanks to:
-- * @Conikku - The original ConvertFromHumanoidDescription pull request.
-- * @Xekran_n - HeadShapes assist.
-- * Roblox Staff - Allowing me to put this module back on sale despite everything!
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
		AppearanceLoad(player.Character)
	end
end)
]]

------------------------------------------------------------------------------

local EXCLUDED_ACCESSORIES = {
	Enum.AccessoryType.Eyebrow;
	Enum.AccessoryType.Eyelash;
}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ToHatModule : ModuleScript = script:WaitForChild("ToHat")
local TO_HAT = require(ToHatModule)
local ToFaceModule : ModuleScript = script:WaitForChild("ToFace")
local TO_FACE = require(ToFaceModule)
local HeadShapesModule : ModuleScript = script:WaitForChild("HeadShapes")
local HEAD_SHAPES = require(HeadShapesModule) :: {[string]: number}

------------------------------------------------------------------------------ 

-- This thing will allow us to insert hats as MeshParts when they are enabled.
local Desc : HumanoidDescription = Instance.new("HumanoidDescription")
Desc.HeadScale = 1
Desc.WidthScale = 1
Desc.DepthScale = 1
Desc.HeightScale = 1
Desc.BodyTypeScale = 0
Desc.ProportionScale = 0

------------------------------------------------------------------------------ 

--- Create a retexture from an existing Roblox hat, while preserving it's SpecialMesh or MeshPart properties.
--- It's done by inserting an existing hat and altering its texture.
--- @param name string -- The name of the retexture we are creating.
--- @param hatId number -- Roblox Asset ID for the Accessory.
--- @param texture number -- Roblox Asset ID for the retexture.
--- @return Accoutrement? -- Modified hat accessory, nil otherwise.
local function CreateRetexture(name : string, hatId : number, texture : number) : Accoutrement?
	local textureID = `rbxassetid://{texture}`
	
	local DescHolder = Desc:Clone()
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
			end
		end
	end

	return hat
end

--- Retrieves a head for the corresponding head shape.
--- @param headShape string -- The head shape name.
--- @return number -- Head ID.
local function ReturnHeadFromShape(headShape: string): number
	assert(headShape, "Expected HeadShape string but got nil instead!")
	local id = HEAD_SHAPES[headShape]
	return id or 0
end

------------------------------------------------------------------------------ 

local FacialU = {}

-- Gets the head shape's internal name
--- @param humanoidDescription HumanoidDescription -- The HumanoidDescription used.
--- @return string -- Head shape name.
function FacialU:GetHeadShape(humanoidDescription : HumanoidDescription) : string
	assert(humanoidDescription, "Expected HumanoidDescription but got nil instead, please provide a humanoid description!")
	local shape = ""
	
	for _, bodyPart in pairs(humanoidDescription:GetChildren()) do
		if bodyPart and bodyPart:IsA("BodyPartDescription") and bodyPart.HeadShape ~= "" then
			shape = bodyPart.HeadShape
			break
		end
	end
	
	return shape
end

--- Convert a HumanoidDescription to use classic faces instead of animated heads.
--- Modifies the provided HumanoidDescription in-place by replacing dynamic head assets with classic 2D faces.
--- Removes eyebrows and eyelashes, and converts heads to either classic face decals or retextured hat accessories.
--- @param humanoidDescription HumanoidDescription -- The HumanoidDescription to modify in-place.
--- @param useDefaultHead boolean -- Use the default Roblox head (Head = 0) instead of the classic head mesh.
--- @return boolean -- True if a conversion was performed, false otherwise.
--- @return Accoutrement? -- Created hat accessory if the head was converted to a hat, nil otherwise.
function FacialU:ConvertFromHumanoidDescription(humanoidDescription : HumanoidDescription, useDefaultHead : boolean?): (boolean, Accoutrement?)
	assert(humanoidDescription, "Expected HumanoidDescription but got nil instead, please provide a humanoid description!")

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

		-- For the specific case of the character not having a loaded appearance (LoadCharacterAppearance = false),
		-- therefore no HumanoidDescription. maybe a bit hacky lol
		if ID == 0 then 
			local Medium_stone_grey = Color3.new(0.639216, 0.635294, 0.647059)
			humanoidDescription.HeadColor = Medium_stone_grey
			humanoidDescription.TorsoColor = Medium_stone_grey
			humanoidDescription.LeftArmColor = Medium_stone_grey
			humanoidDescription.LeftLegColor = Medium_stone_grey
			humanoidDescription.RightArmColor = Medium_stone_grey
			humanoidDescription.RightLegColor = Medium_stone_grey
		end

		removeFaceStuff = true

		if useDefaultHead then
			humanoidDescription.Head = 0
		else
			local name = self:GetHeadShape(humanoidDescription)
			humanoidDescription.Head = (name and name ~= "") and ReturnHeadFromShape(name) or TO_FACE[ID].Head or 0
		end
	end

	-- We remove Eyelashes and Eyebrows.
	if removeFaceStuff then
		local getAccessories = humanoidDescription:GetAccessories(true)
		local setAccessories = {}
		for i, v in pairs(getAccessories) do
			local accType = v.AccessoryType or Enum.AccessoryType.Unknown
			local isInTable = table.find(EXCLUDED_ACCESSORIES, accType) ~= nil
			if not isInTable then
				table.insert(setAccessories, v)
			end
		end

		humanoidDescription:SetAccessories(setAccessories, true)

		if hatToCopy and hatToCopy:IsA("Accoutrement") then
			local newHat = Instance.new("AccessoryDescription")
			newHat.AccessoryType = hatToCopy:IsA("Accessory") and hatToCopy.AccessoryType or Enum.AccessoryType.Hat
			newHat.Instance = hatToCopy
			newHat.Parent = humanoidDescription
		end
	end

	return removeFaceStuff, hatToCopy
end

--- Convert animated faces to classic variants.
--- @param humanoid Humanoid -- The humanoid instance to modify.
--- @param useDefaultHead boolean -- Use the default Roblox head (Head = 0) instead of the classic head mesh.
--- @return boolean -- True if a conversion was performed, false otherwise.
function FacialU:ConvertAnimatedHead(humanoid : Humanoid, useDefaultHead : boolean?) : boolean
	assert(humanoid, "Expected Humanoid but got nil instead!")
	useDefaultHead = useDefaultHead or false

	humanoid:WaitForChild("HumanoidDescription", 1) -- THIS IS A STUPID HACK, OKAY?

	local desc = humanoid:GetAppliedDescription() :: HumanoidDescription
	if desc then
		local wasConverted = self:ConvertFromHumanoidDescription(desc, useDefaultHead)
		if wasConverted then
			humanoid:ApplyDescriptionResetAsync(desc)
			-- TODO: Fix the updating.
			return true
		end
	end

	return false
end

------------------------------------------------------------------------------ 

-- Prints attribution and update notifications in the console.
local Attribution : ModuleScript = script:FindFirstChild("Attribution")
if Attribution and Attribution:IsA("ModuleScript") then 
	require(Attribution) 
end

return FacialU
