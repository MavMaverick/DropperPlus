local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DropperPlus = ReplicatedStorage:WaitForChild("DropperPlus")

script.Parent.Touched:Connect(function(hit)
	local player = game.Players:GetPlayerFromCharacter(hit.Parent)
	if not player then return end

	local toolContainer = script.Parent.Parent
	local tools = toolContainer:GetChildren()

	for _, tool in ipairs(tools) do
		if tool:IsA("Tool") then
			local clone = tool:Clone()
			
			if DropperPlus and DropperPlus:IsA("LocalScript") then
				local scriptClone = DropperPlus:Clone()
				scriptClone.Parent = clone
			end
			
			-- Give the tool to the player
			clone.Parent = player.Backpack
		end
	end
end)
