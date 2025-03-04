-- Improved Grid Test Script
-- Place this in ServerScriptService

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Load the GridSystem module
local modulesFolder = ReplicatedStorage:WaitForChild("TacticalGameModules")
local GridSystem = require(modulesFolder:WaitForChild("GridSystem"))

-- Helper function to convert grid position to world position if method unavailable
local function gridToWorld(gridPos)
	-- Default grid size is 8x8
	return Vector3.new(
		gridPos.X * 8,
		gridPos.Y,
		gridPos.Z * 8
	)
end

-- Create a test environment
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

			-- Add ClickDetector to each cell
			local clickDetector = Instance.new("ClickDetector")
			clickDetector.MaxActivationDistance = 1000 -- Allow clicking from far away
			clickDetector.Parent = cell

			cell.Parent = gridFolder
		end
	end

	print("Test grid created with click detectors")
end

-- Test grid movement with a dummy character
local function TestGridMovement()
	-- Create a grid system
	local gridSystem = GridSystem.new()

	-- Make sure grid folder exists
	local gridFolder = workspace:FindFirstChild("Grid")
	if not gridFolder then
		print("Error: Grid folder not found")
		return
	end

	gridSystem:ScanGridParts()
	print("Grid system scanned parts")

	-- Current grid position of the dummy
	local currentGridPos = Vector3.new(0, 0, 0)

	-- Create a dummy character if it doesn't exist
	local dummyCharacter = workspace:FindFirstChild("GridTestDummy")
	if not dummyCharacter then
		dummyCharacter = Instance.new("Model")
		dummyCharacter.Name = "GridTestDummy"

		local humanoidRootPart = Instance.new("Part")
		humanoidRootPart.Name = "HumanoidRootPart"
		humanoidRootPart.Size = Vector3.new(2, 2, 1)
		humanoidRootPart.Position = Vector3.new(0, 5, 0)
		humanoidRootPart.Anchored = true
		humanoidRootPart.CanCollide = false
		humanoidRootPart.Color = Color3.fromRGB(0, 100, 200)
		humanoidRootPart.Transparency = 0.3
		humanoidRootPart.Parent = dummyCharacter

		local humanoid = Instance.new("Humanoid")
		humanoid.Parent = dummyCharacter

		-- Add a head for visibility and selection
		local head = Instance.new("Part")
		head.Name = "Head"
		head.Size = Vector3.new(1, 1, 1)
		head.Position = Vector3.new(0, 6.5, 0)
		head.Anchored = true
		head.CanCollide = false
		head.Color = Color3.fromRGB(0, 100, 200)
		head.Parent = dummyCharacter

		dummyCharacter.PrimaryPart = humanoidRootPart
		dummyCharacter.Parent = workspace
	end

	-- Set the dummy's position to the grid position
	-- Try using the module's method if available, otherwise use our helper
	local worldPos
	if gridSystem.GridToWorld then
		worldPos = gridSystem:GridToWorld(currentGridPos)
	else
		worldPos = gridToWorld(currentGridPos)
	end
	print("Initial world position:", worldPos)

	dummyCharacter.PrimaryPart.Position = Vector3.new(worldPos.X, worldPos.Y + 3, worldPos.Z)
	dummyCharacter.Head.Position = Vector3.new(worldPos.X, worldPos.Y + 4.5, worldPos.Z)

	-- Try to set cell occupied
	if gridSystem.SetCellOccupied then
		gridSystem:SetCellOccupied(currentGridPos, true)
	else
		print("Warning: SetCellOccupied method not available")
	end

	-- Add click detection to grid cells with clear logging
	if gridFolder then
		for _, cell in ipairs(gridFolder:GetChildren()) do
			if cell:IsA("Part") then
				local clickDetector = cell:FindFirstChild("ClickDetector")
				if clickDetector then
					-- Add new connection
					clickDetector.MouseClick:Connect(function(player)
						print("Grid cell clicked at position:", cell.Position)

						-- Get the grid position of the clicked cell
						local clickedGridPos
						if gridSystem.WorldToGrid then
							clickedGridPos = gridSystem:WorldToGrid(cell.Position)
						else
							-- Simple conversion for testing
							clickedGridPos = Vector3.new(
								math.floor(cell.Position.X / 8 + 0.5),
								math.floor(cell.Position.Y + 0.5),
								math.floor(cell.Position.Z / 8 + 0.5)
							)
						end
						print("Grid coordinates:", clickedGridPos.X, clickedGridPos.Y, clickedGridPos.Z)

						-- Check if movement is valid
						local isValidMove = true
						if gridSystem.IsValidMove then
							isValidMove = gridSystem:IsValidMove(currentGridPos, clickedGridPos, true)
						end

						if isValidMove then
							print("Moving dummy to grid position:", clickedGridPos.X, clickedGridPos.Y, clickedGridPos.Z)

							-- Mark current cell as unoccupied
							if gridSystem.SetCellOccupied then
								gridSystem:SetCellOccupied(currentGridPos, false)
							end

							-- Update current position
							currentGridPos = clickedGridPos

							-- Mark new cell as occupied
							if gridSystem.SetCellOccupied then
								gridSystem:SetCellOccupied(currentGridPos, true)
							end

							-- Move the dummy
							local newWorldPos
							if gridSystem.GridToWorld then
								newWorldPos = gridSystem:GridToWorld(currentGridPos)
							else
								newWorldPos = gridToWorld(currentGridPos)
							end
							dummyCharacter.PrimaryPart.Position = Vector3.new(newWorldPos.X, newWorldPos.Y + 3, newWorldPos.Z)
							dummyCharacter.Head.Position = Vector3.new(newWorldPos.X, newWorldPos.Y + 4.5, newWorldPos.Z)

							-- Show movement range from new position
							if gridSystem.GetMovementRange and gridSystem.HighlightMovementRange then
								local movementRange = gridSystem:GetMovementRange(currentGridPos, 2, true)
								gridSystem:ClearHighlights() -- Clear previous highlights
								gridSystem:HighlightMovementRange(movementRange, Color3.fromRGB(0, 100, 200))
							end
						else
							print("Invalid move to grid position:", clickedGridPos.X, clickedGridPos.Y, clickedGridPos.Z)
						end
					end)
				else
					print("Warning: ClickDetector not found on grid cell:", cell.Position)
				end
			end
		end
	end

	-- Show initial movement range
	if gridSystem.GetMovementRange and gridSystem.HighlightMovementRange then
		local initialMovementRange = gridSystem:GetMovementRange(currentGridPos, 2, true)
		gridSystem:HighlightMovementRange(initialMovementRange, Color3.fromRGB(0, 100, 200))
	end

	-- Create instructions billboard
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 200, 0, 50)
	billboard.StudsOffset = Vector3.new(0, 5, 0)
	billboard.Adornee = dummyCharacter.PrimaryPart
	billboard.AlwaysOnTop = true

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 0.5
	textLabel.BackgroundColor3 = Color3.new(0, 0, 0)
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.Text = "Click on grid cells to move"
	textLabel.Font = Enum.Font.SourceSansBold
	textLabel.TextSize = 16
	textLabel.TextWrapped = true
	textLabel.Parent = billboard

	billboard.Parent = dummyCharacter

	print("Grid movement test ready. Click on grid cells to move the dummy.")
end

-- Run the test setup
print("Starting grid test setup...")
CreateTestGrid()
print("Grid created, setting up movement test...")
TestGridMovement()
print("Grid test initialization complete.")