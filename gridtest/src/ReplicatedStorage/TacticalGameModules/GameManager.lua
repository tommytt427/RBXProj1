local GameManager = {}

-- Required modules
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local modulesFolder = ReplicatedStorage:WaitForChild("TacticalGameModules")
local GridSystem = require(modulesFolder:WaitForChild("GridSystem"))

-- Create a simple test map with grid cells
function GameManager:CreateTestMap()
	-- Create a grid folder if it doesn't exist
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

	-- Create player units folder
	local playerUnitsFolder = workspace:FindFirstChild("PlayerUnits")
	if not playerUnitsFolder then
		playerUnitsFolder = Instance.new("Folder")
		playerUnitsFolder.Name = "PlayerUnits"
		playerUnitsFolder.Parent = workspace
	end

	-- Create enemy units folder
	local enemyUnitsFolder = workspace:FindFirstChild("EnemyUnits")
	if not enemyUnitsFolder then
		enemyUnitsFolder = Instance.new("Folder")
		enemyUnitsFolder.Name = "EnemyUnits"
		enemyUnitsFolder.Parent = workspace
	end

	-- Create a test unit
	self:CreateBasicUnit("PlayerUnit", Vector3.new(0, 5, 0), Color3.fromRGB(0, 100, 200), playerUnitsFolder)

	-- Create a test enemy
	self:CreateBasicUnit("EnemyUnit", Vector3.new(16, 5, 16), Color3.fromRGB(200, 0, 50), enemyUnitsFolder)

	print("Test map created")
end

-- Create a basic unit model
function GameManager:CreateBasicUnit(name, position, color, parent)
	local model = Instance.new("Model")
	model.Name = name

	local humanoidRootPart = Instance.new("Part")
	humanoidRootPart.Name = "HumanoidRootPart"
	humanoidRootPart.Size = Vector3.new(2, 2, 1)
	humanoidRootPart.Position = position
	humanoidRootPart.Anchored = true
	humanoidRootPart.CanCollide = true
	humanoidRootPart.Color = color
	humanoidRootPart.Parent = model

	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = 100
	humanoid.Health = 100
	humanoid.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(1, 1, 1)
	head.Position = position + Vector3.new(0, 1.5, 0)
	head.Anchored = true
	head.CanCollide = false
	head.Color = color
	head.Parent = model

	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = Vector3.new(2, 2, 1)
	torso.Position = position
	torso.Anchored = true
	torso.CanCollide = false
	torso.Color = color
	torso.Parent = model

	local animator = Instance.new("Animator")
	animator.Parent = humanoid

	model.PrimaryPart = humanoidRootPart
	model.Parent = parent

	return model
end

-- Initialize the game
function GameManager:Initialize()
	-- Create GridSystem
	self.GridSystem = GridSystem.new()
	self.GridSystem:ScanGridParts()

	print("Game initialized!")
	print("Click on grid cells to test movement")
	print("Press space to end turn")

	-- Show initial grid cells
	local startPos = Vector3.new(0, 0, 0)
	local movementRange = self.GridSystem:GetMovementRange(startPos, 5, true)
	self.GridSystem:HighlightMovementRange(movementRange)
end

return GameManager