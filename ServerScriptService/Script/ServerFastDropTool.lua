local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DropToolRequest = ReplicatedStorage:WaitForChild("DropToolRequest")

DropToolRequest.OnServerEvent:Connect(function(player, tool, rightGrip)
	if not tool or not player then return end


	rightGrip:Destroy()
	tool.Parent = workspace

	local handle = tool.Handle
	
	if handle then
		handle.CanCollide = true
		handle.Anchored = false
		--handle.CFrame = handle.CFrame * CFrame.new(0, -5, 0)

		-- Step 1: Give player temp network ownership
		handle:SetNetworkOwner(player)

		-- Step 2: After short delay, return control to server only if it's still in workspace
		task.delay(1, function()
			if handle:IsDescendantOf(workspace) and tool.Parent == workspace then
				handle:SetNetworkOwner(nil)
			end
		end)
	end
end)
