local tool = script.Parent
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DropToolRequest = ReplicatedStorage.DropToolRequest

local connection
local hasFired = false


tool.Equipped:Connect(function()
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

	connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if not gameProcessed and input.KeyCode == Enum.KeyCode.Backspace and rightGrip then
			print("hello world")
			DropToolRequest:FireServer(tool, rightGrip)
		end
	end)
end)

tool.Unequipped:Connect(function()
	if connection then
		connection:Disconnect()
		connection = nil
	end
end)
 