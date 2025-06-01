local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DropToolRequest = ReplicatedStorage:WaitForChild("DropToolRequest")

DropToolRequest.OnServerEvent:Connect(function(player, tool, rightGrip)
	if not tool or not player then return end

	local currentPivot = tool:GetPivot() -- We want then direction of the tool to use later
	if rightGrip then
		rightGrip:Destroy() -- Remove tool weld to player, normally done by Roblox
	else
		warn("rightGrip was nil — likely due to rapid equip/drop")
	end

	tool.Parent = workspace -- Tool no longer a child of character

	local handle = tool.Handle
	
	if handle then
		-- Roblox disables CanCollide while using tool, we want it on so no fall through floor
		handle.CanCollide = true
		handle.Anchored = false
		local dropLocationOffsetZ = tool.FastToolDrop.Configuration.DropLocationOffsetZ.Value
		local dropLocationOffsetY = tool.FastToolDrop.Configuration.DropLocationOffsetY.Value
		local dropLocationOffsetX = tool.FastToolDrop.Configuration.DropLocationOffsetX.Value

		
		local forwardCFrame = currentPivot * CFrame.new(0, dropLocationOffsetY, dropLocationOffsetZ) --(-2 Z Axis) move 2 studs forward relative to tool's facing (any less not recommended)
		tool:PivotTo(forwardCFrame)

		-- Step 1: Give player temp network ownership, this allows smooth dropping for player
		handle:SetNetworkOwner(player)

		-- Step 2: After short delay, return control to server only if it's still in workspacen (prevents slow movement)
		task.delay(1, function()
			if handle:IsDescendantOf(workspace) and tool.Parent == workspace then
				handle:SetNetworkOwner(nil)
			end
		end)
		
	end
end)
