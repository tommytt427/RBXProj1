local GameManager = {}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local modulesFolder = ReplicatedStorage:WaitForChild("TacticalGameModules")
local GridSystem = require(modulesFolder:WaitForChild("GridSystem"))
local UnitController = require(modulesFolder:WaitForChild("HumanoidUnitController"))


function GameManager:SpawnUnitFromModel(modelName, position, isEnemy)
	-- Get the model
	local modelsFolder = ReplicatedStorage:WaitForChild("UnitModels")
	print("UnitModels folder found:", modelsFolder.Name)

	local modelFolder = isEnemy and modelsFolder:WaitForChild("EnemyUnits") or modelsFolder:WaitForChild("PlayerUnits")
	print("Model subfolder found:", modelFolder.Name)

	local model = modelFolder:FindFirstChild(modelName)
	print("Looking for model:", modelName, "Found:", model and model.Name or "nil")

	-- Rest of function...
end

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

			-- Add ClickDetector
			local clickDetector = Instance.new("ClickDetector")
			clickDetector.MaxActivationDistance = 1000
			clickDetector.Parent = cell

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

	-- Replace them with:
	self:SpawnUnitFromModel("Soldier", Vector3.new(0, 5, 0), false) -- Player unit
	self:SpawnUnitFromModel("Enemy", Vector3.new(16, 5, 16), true) -- Enemy unit

	print("Test map created")
end



-- Create a basic unit model
function GameManager:CreateBasicUnit(name, position, color, parent)
	local model = Instance.new("Model")
	model.Name = name

	-- Create humanoid root part
	local humanoidRootPart = Instance.new("Part")
	humanoidRootPart.Name = "HumanoidRootPart"
	humanoidRootPart.Size = Vector3.new(2, 2, 1)
	humanoidRootPart.Position = position
	humanoidRootPart.Anchored = false -- Important: not anchored for movement
	humanoidRootPart.CanCollide = true
	humanoidRootPart.Color = color

	-- Create humanoid
	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = 100
	humanoid.Health = 100

	-- Create animator
	local animator = Instance.new("Animator")
	animator.Parent = humanoid

	-- Create head
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(1, 1, 1)
	head.Position = position + Vector3.new(0, 1.5, 0)
	head.Anchored = false
	head.CanCollide = false
	head.Color = color

	-- Create torso
	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = Vector3.new(2, 2, 1)
	torso.Position = position
	torso.Anchored = false
	torso.CanCollide = false
	torso.Color = color

	-- Add welds
	local headWeld = Instance.new("WeldConstraint")
	headWeld.Part0 = humanoidRootPart
	headWeld.Part1 = head
	headWeld.Parent = humanoidRootPart

	local torsoWeld = Instance.new("WeldConstraint")
	torsoWeld.Part0 = humanoidRootPart
	torsoWeld.Part1 = torso
	torsoWeld.Parent = humanoidRootPart

	-- Add billboard with unit name
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 100, 0, 30)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.Adornee = head
	billboard.AlwaysOnTop = true

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 1, 0)
	nameLabel.BackgroundTransparency = 0.5
	nameLabel.BackgroundColor3 = Color3.new(0, 0, 0)
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.Text = name
	nameLabel.FontSize = Enum.FontSize.Size14
	nameLabel.Parent = billboard

	humanoidRootPart.Parent = model
	humanoid.Parent = model
	head.Parent = model
	torso.Parent = model
	billboard.Parent = model

	-- Set primary part
	model.PrimaryPart = humanoidRootPart

	-- Make sure it's not sinking into the ground
	model:SetPrimaryPartCFrame(CFrame.new(position))

	-- Apply ground physics
	humanoidRootPart.CustomPhysicalProperties = PhysicalProperties.new(1, 0, 0.5, 1, 1)

	model.Parent = parent
	return model
end

-- Initialize the game
function GameManager:Initialize()
	-- Create GridSystem
	self.GridSystem = GridSystem.new()
	self.GridSystem:ScanGridParts()

	-- Create unit controllers for all units
	self.UnitControllers = {}
	self.PlayerUnits = {}
	self.EnemyUnits = {}

	-- Initialize player units
	local playerUnitsFolder = workspace:FindFirstChild("PlayerUnits")
	if playerUnitsFolder then
		for _, unit in ipairs(playerUnitsFolder:GetChildren()) do
			if unit:IsA("Model") and unit:FindFirstChildOfClass("Humanoid") then
				local controller = UnitController.new(unit, self.GridSystem)
				self.UnitControllers[unit] = controller
				table.insert(self.PlayerUnits, unit)
			end
		end
	end

	-- Initialize enemy units
	local enemyUnitsFolder = workspace:FindFirstChild("EnemyUnits")
	if enemyUnitsFolder then
		for _, unit in ipairs(enemyUnitsFolder:GetChildren()) do
			if unit:IsA("Model") and unit:FindFirstChildOfClass("Humanoid") then
				local controller = UnitController.new(unit, self.GridSystem)
				self.UnitControllers[unit] = controller
				table.insert(self.EnemyUnits, unit)
			end
		end
	end

	-- Start player turn
	self:StartPlayerTurn()

	print("Game initialized!")
	print("Click on grid cells to test movement")
	print("Press space to end turn")
end

-- Start player turn
function GameManager:StartPlayerTurn()
	for _, unit in ipairs(self.PlayerUnits) do
		local controller = self.UnitControllers[unit]
		if controller then
			controller:StartTurn()
		end
	end

	-- Show initial movement range for first unit
	if #self.PlayerUnits > 0 then
		local firstUnit = self.PlayerUnits[1]
		local controller = self.UnitControllers[firstUnit]
		if controller then
			controller:ShowMovementRange()
		end
	end
end

-- End player turn and start AI turn
function GameManager:EndPlayerTurn()
	-- End turn for all player units
	for _, unit in ipairs(self.PlayerUnits) do
		local controller = self.UnitControllers[unit]
		if controller then
			controller:EndTurn()
		end
	end

	-- Start AI turn
	self:StartAITurn()
end

-- AI turn logic
function GameManager:StartAITurn()
	print("AI turn starting...")

	-- Reset all enemy units
	for _, unit in ipairs(self.EnemyUnits) do
		local controller = self.UnitControllers[unit]
		if controller then
			controller:StartTurn()
		end
	end

	-- Simple AI for each enemy unit
	task.spawn(function()
		for _, enemyUnit in ipairs(self.EnemyUnits) do
			local controller = self.UnitControllers[enemyUnit]
			if not controller then continue end

			-- Find closest player unit
			local closestUnit = nil
			local closestDistance = math.huge

			for _, playerUnit in ipairs(self.PlayerUnits) do
				local distance = (enemyUnit:GetPivot().Position - playerUnit:GetPivot().Position).Magnitude
				if distance < closestDistance then
					closestDistance = distance
					closestUnit = playerUnit
				end
			end

			-- If found a player unit, move toward it or attack
			if closestUnit then
				if controller:CanAttackTarget(closestUnit) then
					task.wait(0.5) -- Delay for effect
					controller:AttackTarget(closestUnit)
				else
					-- Get player unit position
					local playerPos = closestUnit:GetPivot().Position
					local enemyPos = enemyUnit:GetPivot().Position
					local direction = (playerPos - enemyPos).Unit

					-- Find cell in direction of player
					local targetPos = enemyPos + direction * 8

					controller:MoveToWorldPosition(targetPos)
					task.wait(2) -- Wait for move to complete
				end
			end

			task.wait(0.5) -- Delay between enemy actions
		end

		task.wait(1) -- Delay at end of enemy turn

		-- End AI turn and start player turn again
		self:EndAITurn()
	end)
end

-- End AI turn and start player turn
function GameManager:EndAITurn()
	-- End turn for all AI units
	for _, unit in ipairs(self.EnemyUnits) do
		local controller = self.UnitControllers[unit]
		if controller then
			controller:EndTurn()
		end
	end

	-- Start player turn again
	self:StartPlayerTurn()
end


function GameManager:SpawnUnitFromModel(modelName, position, isEnemy)
	-- Get the model
	local modelsFolder = ReplicatedStorage:WaitForChild("UnitModels")
	local modelFolder = isEnemy and modelsFolder:WaitForChild("EnemyUnits") or modelsFolder:WaitForChild("PlayerUnits")
	local model = modelFolder:FindFirstChild(modelName)

	if not model then
		warn("Model not found:", modelName)
		return nil
	end

	-- Clone the model
	local unitModel = model:Clone()

	-- Position the model
	unitModel:SetPrimaryPartCFrame(CFrame.new(position))

	-- Make sure the humanoid is properly set up
	local humanoid = unitModel:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		humanoid = Instance.new("Humanoid")
		humanoid.Parent = unitModel
	end

	-- Make sure animation controller exists
	if not humanoid:FindFirstChildOfClass("Animator") then
		local animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	-- Add unit name label
	local head = unitModel:FindFirstChild("Head")
	if head then
		local billboard = Instance.new("BillboardGui")
		billboard.Size = UDim2.new(0, 100, 0, 30)
		billboard.StudsOffset = Vector3.new(0, 2, 0)
		billboard.Adornee = head
		billboard.AlwaysOnTop = true

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, 0, 1, 0)
		nameLabel.BackgroundTransparency = 0.5
		nameLabel.BackgroundColor3 = Color3.new(0, 0, 0)
		nameLabel.TextColor3 = Color3.new(1, 1, 1)
		nameLabel.Text = unitModel.Name
		nameLabel.TextSize = 14
		nameLabel.Parent = billboard

		billboard.Parent = unitModel
	end

	-- Set parent folder
	local parentFolder = isEnemy and workspace:FindFirstChild("EnemyUnits") or workspace:FindFirstChild("PlayerUnits")
	unitModel.Parent = parentFolder

	-- Create controller for the unit
	local controller = UnitController.new(unitModel, self.GridSystem)

	-- Add to appropriate unit list
	if isEnemy then
		table.insert(self.EnemyUnits, unitModel)
	else
		table.insert(self.PlayerUnits, unitModel)
	end

	self.UnitControllers[unitModel] = controller

	return unitModel
end

return GameManager