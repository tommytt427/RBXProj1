local function CreateTestGrid()
	-- Create grid folder if it doesn't exist
	local gridFolder = workspace:FindFirstChild("Grid")
	if not gridFolder then
		gridFolder = Instance.new("Folder")
		gridFolder.Name = "Grid"
		gridFolder.Parent = workspace
	else
		-- Clear existing grid
		for _, child in pairs(gridFolder:GetChildren()) do
			child:Destroy()
		end
	end

	-- Create a 5x5 grid
	for x = -2, 2 do
		for z = -2, 2 do
			local cell = Instance.new("Part")
			cell.Size = Vector3.new(8, 1, 8)
			cell.Position = Vector3.new(x * 8, 0, z * 8)
			cell.Anchored = true
			cell.CanCollide = true
			cell.Material = Enum.Material.SmoothPlastic

			-- Checkerboard pattern
			if (x + z) % 2 == 0 then
				cell.Color = Color3.fromRGB(200, 200, 200)
			else
				cell.Color = Color3.fromRGB(150, 150, 150)
			end

			-- Add some elevation to test height differences
			if (x == 1 and z == 1) or (x == -1 and z == -1) then
				cell.Position = Vector3.new(x * 8, 2, z * 8)
			end

			-- Add cover to some cells
			if (x == 0 and z == 1) then
				cell:SetAttribute("Cover", "Full")

				local coverBlock = Instance.new("Part")
				coverBlock.Size = Vector3.new(2, 3, 2)
				coverBlock.Position = Vector3.new(x * 8, 2, z * 8)
				coverBlock.Anchored = true
				coverBlock.CanCollide = true
				coverBlock.Material = Enum.Material.Concrete
				coverBlock.Color = Color3.fromRGB(80, 80, 80)
				coverBlock.Parent = gridFolder
			elseif (x == -1 and z == 0) then
				cell:SetAttribute("Cover", "Half")

				local coverBlock = Instance.new("Part")
				coverBlock.Size = Vector3.new(4, 1.5, 4)
				coverBlock.Position = Vector3.new(x * 8, 1.25, z * 8)
				coverBlock.Anchored = true
				coverBlock.CanCollide = true
				coverBlock.Material = Enum.Material.Concrete
				coverBlock.Color = Color3.fromRGB(120, 120, 120)
				coverBlock.Parent = gridFolder
			end

			cell.Parent = gridFolder
		end
	end

	print("Test grid created")
end