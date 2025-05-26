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

local mobileButton

tool.Equipped:Connect(function()
		
		-- Storing the connection lets you disconnect it later (e.g., when the tool is unequipped)
		-- Keyboard (PC) support
	connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		-- “If the player pressed the Backspace key, and the game didn’t already use that input for something else,
		-- then run the code inside.”
		if not gameProcessed and input.KeyCode == Enum.KeyCode.Backspace then
			if screenGui then -- If the GUI is already present if mobile detected but using keyboard, destroy it
				screenGui:Destroy()
			end
			dropTool()
		end
	end)
	
	-- Mobile support: add a screen button if on touch
	if UserInputService.TouchEnabled and not mobileButton then
		print("Tool equippd")
		local player = game.Players.LocalPlayer
		local playerGui = player:WaitForChild("PlayerGui")

		screenGui = Instance.new("ScreenGui")
		screenGui.Name = "DropToolGui"
		screenGui.ResetOnSpawn = false
		screenGui.Parent = playerGui

		mobileButton = Instance.new("TextButton")
		mobileButton.Size = UDim2.new(0, 50, 0, 50)
		mobileButton.Position = UDim2.new(1, -200, 1, -60) -- bottom right
		mobileButton.AnchorPoint = Vector2.new(0, 0)
		mobileButton.Text = "Drop Tool"
		mobileButton.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
		mobileButton.TextColor3 = Color3.new(1, 1, 1)
		mobileButton.Parent = screenGui

		mobileButton.MouseButton1Click:Connect(function()
			if screenGui then
				screenGui:Destroy()
				end
			dropTool()
		end)
	end
end)

tool.Unequipped:Connect(function()
	if screenGui then
		screenGui:Destroy()
		end
	if connection then
		connection:Disconnect()
		connection = nil
	end
end)
