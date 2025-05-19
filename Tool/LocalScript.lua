local tool = script.Parent
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DropToolRequest = ReplicatedStorage.DropToolRequest

local rightGrip -- refreshed each time the tool is equipped
local connection
local hasFired = false


tool.Equipped:Connect(function()
	local character = tool.Parent
	local rightHand = character:FindFirstChild("RightHand")
	rightGrip = rightHand and rightHand:FindFirstChild("RightGrip")

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
