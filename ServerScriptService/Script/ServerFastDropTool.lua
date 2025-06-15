local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DropToolRequest = ReplicatedStorage:WaitForChild("DropToolRequest")

-- Spam protection per player
local callTracker = {}
local timeWindow = 1 -- seconds
local maxCallsPerWindow = 8 -- Max requests allowed in time window

DropToolRequest.OnServerEvent:Connect(function(player, tool, rightGrip)
	if not tool or not player then return end

	local now = time()
	local userId = player.UserId

	-- Set up tracking table for the player if needed
	if not callTracker[userId] then
		callTracker[userId] = {
			count = 0,
			windowStart = now
		}
	end

	local tracker = callTracker[userId]

	-- Reset count if the time window has passed
	if now - tracker.windowStart > timeWindow then
		tracker.count = 0
		tracker.windowStart = now
	end

	-- Increment call count
	tracker.count += 1

	-- Enforce rate limit
	if tracker.count > maxCallsPerWindow then
		player:Kick("You have been removed for spamming tools.")
		return
	end

	-- == NORMAL TOOL DROP LOGIC BELOW == --

	--local currentPivot = tool:GetPivot() -- We want then direction of the tool to use later
	if rightGrip then
		rightGrip:Destroy() -- Remove tool weld to player, normally done by Roblox
		print("Weld destroyed")
		tool.Parent = workspace -- Tool no longer a child of character
		local handle = tool.Handle
		local character = player.Character
		if not character then return end
		local currentPivot = character:GetPivot() -- Use character orientation, not tool's

		if handle then
			-- Roblox disables CanCollide while using tool, we want it on so no fall through floor
			handle.CanCollide = true
			handle.Anchored = false
			local dropLocationOffsetZ = tool.FastToolDrop.Configuration.DropLocationOffsetZ.Value
			local dropLocationOffsetY = tool.FastToolDrop.Configuration.DropLocationOffsetY.Value
			local dropLocationOffsetX = tool.FastToolDrop.Configuration.DropLocationOffsetX.Value
			
			-- Offset in character's local space (e.g., forward from player, not tool)
			local dropOffset = CFrame.new(dropLocationOffsetX, dropLocationOffsetY, dropLocationOffsetZ)
			local dropCFrame = currentPivot * dropOffset

			tool:PivotTo(dropCFrame)

			-- Step 1: Give player temp network ownership, this allows smooth dropping for player
			handle:SetNetworkOwner(player)

			-- Step 2: After short delay, return control to server only if it's still in workspacen (prevents slow movement)
			task.delay(1, function()
				if handle:IsDescendantOf(workspace) and tool.Parent == workspace then
					handle:SetNetworkOwner(nil)
				end
			end)
		end
	else
		-- I'm not ENTIRELY sure why this happens, but spamming tool drop and picking up does this
		warn("rightGrip was nil — likely due to rapid equip/drop")
		-- I had parent.workspace here, but it would cause tools to be welded to player but not in their tools
	end

	
end)
