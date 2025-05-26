local tool = script.Parent
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DropToolRequest = ReplicatedStorage.DropToolRequest

local connection
local hasFired = false

local function dropTool()
	if hasFired then return end
	hasFired = true
	local character = tool.Parent
	local rightHand
	local rightGrip

	-- Check for R15 first (RightHand exists)
	if character:FindFirstChild("RightHand") then
		rightHand = character.RightHand
		rightGrip = rightHand.RightGrip
	else
		-- Fallback to R6 (Right Arm)
		rightHand = character["Right Arm"]
		rightGrip = rightHand.RightGrip
	end
	--print("Tool dropped")
	if rightGrip then
		DropToolRequest:FireServer(tool, rightGrip)
	end
end

tool.Equipped:Connect(function()
		
		-- Storing the connection lets you disconnect it later (e.g., when the tool is unequipped)
		-- Keyboard (PC) support
	connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		-- “If the player pressed the Backspace key, and the game didn’t already use that input for something else,
		-- then run the code inside.”
		if not gameProcessed and input.KeyCode == Enum.KeyCode.Backspace then
			dropTool()
		end
	end)
end)

tool.Unequipped:Connect(function()
	if connection then
		connection:Disconnect()
		connection = nil
	end
end)
