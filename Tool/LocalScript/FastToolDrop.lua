local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DropToolRequest = ReplicatedStorage.DropToolRequest

local tool = script.Parent
local connection
local hasFired = false
local mobileButton
local screenGui


local function dropTool(tool, rightGrip, scriptStartTime)
	-- Debounce
	if hasFired then return end
	
	local player = game.Players.LocalPlayer
	local character = player and player.Character
	local humanoid = character and character:FindFirstChild("Humanoid")

	local isDead = humanoid and humanoid.Health <= 0
	-- Prevent tool dropping when dead
	if isDead then
		print("Dead man")
		return
	end
	-- Prevent double-dropping from dropping too quickly, this is optional
	if time() - scriptStartTime < .1 then
		warn("Too soon to drop tool.")
		return
	end

	if rightGrip then
		local player = game.Players.LocalPlayer
		local ping = player:GetNetworkPing()*2000 -- * 1000 to convert to miliseconds, * 2 to represent round trip
		if ping > 120 then
			print("Lag", ping)
			-- Laggy, so we parent to make characte "lower" their tool, showing it is dropping until server acts
			tool.Parent = workspace
			DropToolRequest:FireServer(tool, rightGrip)
			hasFired = true
		else
			print("nonlag", tool.Name, ping)
			-- Not much lag, no parenting needed to offset visual delay of dropping tool
			DropToolRequest:FireServer(tool, rightGrip)
			hasFired = true
		end
	end
end


tool.Equipped:Connect(function()
	local scriptStartTime = time() -- Track when script starts
	print("Equipped", tool.Name)

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

	-- destroy desynced copies of tools (local only, server can't see them) that are welded to players hand but not in their inventory
	-- Exact cause unknown
	if rightHand then
		local children = rightHand:GetChildren()
		for i = 1, #children do
			local weld = children[i]
			if weld.Name == "RightGrip" then
				local part = weld.Part1
				if part.Parent ~= tool then
					warn("destroyed local copy of desync welded tool")
					weld:Destroy()
					break
				end
			end
		end
	end

	-- Storing the connection lets you disconnect it later (e.g., when the tool is unequipped)
	-- Keyboard (PC) support
	connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		-- “If the player pressed the Backspace key, and the game didn’t already use that input for something else,
		-- then run the code inside.”
		if not gameProcessed and input.KeyCode == Enum.KeyCode.Backspace then
			if screenGui then -- If the GUI is already present if mobile detected but using keyboard, destroy it
				screenGui:Destroy()
				mobileButton = nil
			end
			dropTool(tool, rightGrip, scriptStartTime)

			-- Gamepad support (Console/Controller)
		elseif input.UserInputType == Enum.UserInputType.Gamepad1 and input.KeyCode == Enum.KeyCode.ButtonB then
			if screenGui then
				screenGui:Destroy()
				mobileButton = nil
			end
			dropTool(tool, rightGrip, scriptStartTime)
		end


	end)

	-- Mobile support: add a screen button if on touch
	if UserInputService.TouchEnabled and not mobileButton then
		local player = game.Players.LocalPlayer
		local playerGui = player:WaitForChild("PlayerGui")

		screenGui = Instance.new("ScreenGui")
		screenGui.Name = "DropToolGui"
		screenGui.ResetOnSpawn = false
		screenGui.Parent = playerGui

		mobileButton = Instance.new("TextButton")
		mobileButton.Size = UDim2.new(0, 50, 0, 50)
		--[[
		UDim2.new(XScale, XOffset, YScale, YOffset)
		
		XScale (1): 100% of the parent’s width (right edge)
		XOffset (-60): Move left 60 pixels
		YScale (1): 100% of the parent’s height (bottom edge)
		YOffset (-140): Move up 140 pixels
		
		]]
		local configuration = script.Configuration
		local camera = workspace.CurrentCamera
		local isPortrait = camera.ViewportSize.Y > camera.ViewportSize.X
		-- Choose position based on orientation
		if isPortrait then  -- UDim2.new(XScale, XOffset, YScale, YOffset)
			local xVal = configuration.PortraitButtonOffsetX.Value
			local yVal = configuration.PortraitButtonOffsetY.Value
			mobileButton.Position = UDim2.new(1, xVal, 1, yVal) -- raised to avoid toolbar

		else
			local xVal = configuration.LandscapeButtonOffsetX.Value
			local yVal = configuration.LandscapeButtonOffsetY.Value
			mobileButton.Position = UDim2.new(1, xVal, 1, yVal) -- normal bottom right
		end
		mobileButton.AnchorPoint = Vector2.new(0, 0)
		mobileButton.Text = "Drop Tool"
		mobileButton.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
		mobileButton.TextColor3 = Color3.new(1, 1, 1)
		mobileButton.Parent = screenGui

		-- Add rounded corners
		local uiCorner = Instance.new("UICorner")
		uiCorner.CornerRadius = UDim.new(0, 12) -- adjust as desired
		uiCorner.Parent = mobileButton

		local tapCount = 0

		mobileButton.MouseButton1Click:Connect(function()
			tapCount += 1

			if tapCount >= 3 then
				if screenGui then
					screenGui:Destroy()
					mobileButton = nil
				end
				dropTool(tool, rightGrip, scriptStartTime)
				tapCount = 0 -- reset for next time
			else
				mobileButton.Text = "Tap " .. (3 - tapCount) .. " more"

				-- Set background color based on tap count
				if tapCount == 1 then
					mobileButton.BackgroundColor3 = Color3.fromRGB(191, 127, 0) -- green
				elseif tapCount == 2 then
					mobileButton.BackgroundColor3 = Color3.fromRGB(163, 0, 0) -- yellow
				end
			end
		end)

	end

	-- Cleanup on player death, this ensures Gui button removal on death/reset
	local character = tool.Parent
	local humanoid = character.Humanoid

	if humanoid then
		humanoid.Died:Connect(function()
			if screenGui then
				screenGui:Destroy()
				screenGui = nil
				mobileButton = nil
			end
		end)
	end

end)

tool.Unequipped:Connect(function()
	if screenGui then
		screenGui:Destroy()
		mobileButton = nil
	end
	if connection then
		connection:Disconnect()
		connection = nil
	end
end)