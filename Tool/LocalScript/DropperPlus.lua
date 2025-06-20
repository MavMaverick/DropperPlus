local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DropToolRequest = ReplicatedStorage.DropToolRequest

local tool = script.Parent
local connection
local hasFired = false
local mobileButton
local screenGui

local DEBUG = true

-- Define the debugLog function
local debugLog = DEBUG and function(logFn, ...)
	logFn("[DEBUG]", ...)
end or function() end
	
local function dropTool(tool, rightGrip, scriptStartTime)
	-- Debounce
	if hasFired then return end
	
	local player = game.Players.LocalPlayer
	local character = player and player.Character
	local humanoid = character and character:FindFirstChild("Humanoid")

	local isDead = humanoid and humanoid.Health <= 0
	-- Prevent tool dropping when dead
	if isDead then
		debugLog(print, player.Name, "attempted tool drop while 0 health")
		return
	end
	-- Prevent double-dropping from dropping too quickly, this is optional
	--if time() - scriptStartTime < .01 then
	--	warn("Too soon to drop tool.")
	--	return
	--end

	if rightGrip then
		local player = game.Players.LocalPlayer
		local ping = player:GetNetworkPing()*2000 -- * 1000 to convert to miliseconds, * 2 to represent round trip
		local pingLimit = 120
		if ping > pingLimit then
			debugLog(print, player.Name, "ping >", pingLimit, "LAG, locally parenting tool to workspace")
			-- Laggy, so we parent to make characte "lower" their tool, showing it is dropping until server acts
			tool.Parent = workspace
			DropToolRequest:FireServer(tool, rightGrip)
			hasFired = true
		else
			debugLog(print, player.Name, "ping <", pingLimit, "NO LAG, firing remote only")
			-- Not much lag, no parenting needed to offset visual delay of dropping tool
			DropToolRequest:FireServer(tool, rightGrip)
			hasFired = true
		end
	end
end


tool.Equipped:Connect(function()
	local scriptStartTime = time() -- Track when script starts
	local character = tool.Parent
	debugLog(print, character.Name, "Equipped", tool.Name)
	local rightHand
	local rightGrip

	-- Check for R15 first (RightHand exists)
	if character:FindFirstChild("RightHand") then
		rightHand = character.RightHand
		rightGrip = rightHand.RightGrip
	elseif character:FindFirstChild("Right Arm") then
		-- Fallback to R6 (Right Arm)
		rightHand = character["Right Arm"]
		rightGrip = rightHand.RightGrip
	else
		debugLog(warn, character.Name, "No Hand or arm detected")
		return
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
					weld:Destroy()
					debugLog(warn, "Destroyed duplicate unequipped tool weld of", tool.Name, " welded to", character.Name)
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
		local configuration = script.Configuration
		
		local buttonSize = configuration.MobileFolder.ButtonSize.Value

		mobileButton.Size = UDim2.new(0, buttonSize, 0, buttonSize)

		--mobileButton.Size = UDim2.new(0, 50, 0, 50)
		--[[
		UDim2.new(XScale, XOffset, YScale, YOffset)
		
		XScale (1): 100% of the parent’s width (right edge)
		XOffset (-60): Move left 60 pixels
		YScale (1): 100% of the parent’s height (bottom edge)
		YOffset (-140): Move up 140 pixels
		
		]]

		local camera = workspace.CurrentCamera
		local isPortrait = camera.ViewportSize.Y > camera.ViewportSize.X
		-- Choose position based on orientation
		if isPortrait then  -- UDim2.new(XScale, XOffset, YScale, YOffset)
			local xVal = configuration.MobileFolder.PortraitButtonOffsetX.Value
			local yVal = configuration.MobileFolder.PortraitButtonOffsetY.Value
			mobileButton.Position = UDim2.new(1, xVal, 1, yVal) -- raised to avoid toolbar

		else
			local xVal = configuration.MobileFolder.LandscapeButtonOffsetX.Value
			local yVal = configuration.MobileFolder.LandscapeButtonOffsetY.Value
			mobileButton.Position = UDim2.new(1, xVal, 1, yVal) -- normal bottom right
		end
		mobileButton.AnchorPoint = Vector2.new(0, 0)
		mobileButton.Text = "Drop Tool"
		mobileButton.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
		mobileButton.BackgroundTransparency = 0.25 -- semi-transparent
		mobileButton.TextColor3 = Color3.new(1, 1, 1)
		mobileButton.Parent = screenGui

		-- Add rounded corners
		local uiCorner = Instance.new("UICorner")
		uiCorner.CornerRadius = UDim.new(1, 0) -- adjust as desired
		uiCorner.Parent = mobileButton
		
		-- Create the inner white ring effect
		local ring = Instance.new("Frame")
		ring.Size = UDim2.new(0.9, 0, 0.9, 0) -- Slightly inset
		ring.Position = UDim2.new(0.05, 0, 0.05, 0)
		ring.BackgroundTransparency = 1
		ring.Parent = mobileButton
		
		local ringStroke = Instance.new("UIStroke")
		ringStroke.Thickness = 2
		ringStroke.Color = Color3.fromRGB(255, 255, 255)
		ringStroke.Transparency = 0.6 -- Subtle
		ringStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		ringStroke.Parent = ring

		local ringCorner = Instance.new("UICorner")
		ringCorner.CornerRadius = UDim.new(1, 0)
		ringCorner.Parent = ring
		
		
		local tapCount = 0

		mobileButton.MouseButton1Click:Connect(function()
			local configuration = script.Configuration
			if configuration.MobileFolder.MultiTapEnabled.Value == true then
				debugLog(warn, "[MOBILE] Multi Tap Drop in configure.MobileFolder is enabled")
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
						mobileButton.BackgroundColor3 = Color3.fromRGB(191, 127, 0) -- Orange
					elseif tapCount == 2 then
						mobileButton.BackgroundColor3 = Color3.fromRGB(163, 0, 0) -- Red
					end
				end
			else
				debugLog(warn, "[MOBILE] Multi Tap Drop is disabled")
				if screenGui then
					screenGui:Destroy()
					mobileButton = nil
				end
				dropTool(tool, rightGrip, scriptStartTime)
			end
		end)
	end

	-- Cleanup on player death, this ensures Gui button removal on death/reset
	local character = tool.Parent
	local humanoid = character.Humanoid

	if humanoid then
		humanoid.Died:Connect(function()
			debugLog(print, game.Players.LocalPlayer.Name, "Died and previously equipped", tool.Name)
			if screenGui then
				screenGui:Destroy()
				screenGui = nil
				mobileButton = nil
			end
		end)
	end

end)

tool.Unequipped:Connect(function()
	debugLog(print, game.Players.LocalPlayer.Name, "Unequipped", tool.Name)
	if screenGui then
		screenGui:Destroy()
		mobileButton = nil
	end
	if connection then
		connection:Disconnect()
		connection = nil
	end
end)