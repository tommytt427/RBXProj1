-- Server-side Game Interaction Handler
-- Place this script in ServerScriptService

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Get modules
local modulesFolder = ReplicatedStorage:WaitForChild("TacticalGameModules")
local GridSystem = require(modulesFolder:WaitForChild("GridSystem"))
local UnitController = require(modulesFolder:WaitForChild("UnitController"))

-- Get remotes
local remotes = ReplicatedStorage:WaitForChild("TacticalGameRemotes")
local selectUnitRemote = remotes:WaitForChild("SelectUnit")
local moveUnitRemote = remotes:WaitForChild("MoveUnit")
local attackTargetRemote = remotes:WaitForChild("AttackTarget")
local endTurnRemote = remotes:WaitForChild("EndTurn")

-- Game state
local gridSystem = GridSystem.new()
local playerUnits = {}
local enemyUnits = {}
local unitControllers = {}
local selectedUnits = {}  -- Player -> Unit

-- Initialize unit controllers for all units
local function initializeUnits()
	-- Get player units
	local playerUnitsFolder = workspace:FindFirstChild("PlayerUnits")
	if playerUnitsFolder then
		for _, unit in ipairs(playerUnitsFolder:GetChildren()) do
			if unit:IsA("Model") and unit:FindFirstChildOfClass("Humanoid") then
				local unitController = UnitController.new(unit, gridSystem)
				unitControllers[unit] = unitController
				table.insert(playerUnits, unit)
				print("Added player unit controller for:", unit.Name)
			end
		end
	else
		print("Warning: PlayerUnits folder not found")
	end

	-- Get enemy units
	local enemyUnitsFolder = workspace:FindFirstChild("EnemyUnits")
	if enemyUnitsFolder then
		for _, unit in ipairs(enemyUnitsFolder:GetChildren()) do
			if unit:IsA("Model") and unit:FindFirstChildOfClass("Humanoid") then
				local unitController = UnitController.new(unit, gridSystem)
				unitControllers[unit] = unitController
				table.insert(enemyUnits, unit)
				print("Added enemy unit controller for:", unit.Name)
			end
		end
	else
		print("Warning: EnemyUnits folder not found")
	end

	print("Initialized unit controllers:", #playerUnits + #enemyUnits)
end

-- Initialize gameplay systems
local function initializeGame()
	-- Wait for grid to be ready
	local gridFolder = workspace:FindFirstChild("Grid")
	if not gridFolder then
		gridFolder = workspace:WaitForChild("Grid", 10)
	end

	if gridFolder then
		-- Initialize grid system
		gridSystem:ScanGridParts()
		print("Server grid system initialized")

		-- Initialize units after grid is ready
		task.wait(0.1) -- Small delay to ensure grid is ready
		initializeUnits()
	else
		warn("Could not find Grid folder on server")
	end
end

-- Handle unit selection
selectUnitRemote.OnServerEvent:Connect(function(player, unit)
	-- Validate unit
	if not unit or not unit:IsA("Model") or not unit:FindFirstChildOfClass("Humanoid") then
		warn("Invalid unit selection from player:", player.Name)
		return
	end

	-- Update selected unit for this player
	selectedUnits[player] = unit
	print("Player", player.Name, "selected unit:", unit.Name)

	-- Get unit controller
	local unitController = unitControllers[unit]
	if unitController then
		-- Show movement range (handled by client)
		print("Unit has controller")
	else
		-- Create controller if it doesn't exist
		unitController = UnitController.new(unit, gridSystem)
		unitControllers[unit] = unitController
		print("Created new controller for unit:", unit.Name)
	end
end)

-- Handle unit movement
moveUnitRemote.OnServerEvent:Connect(function(player, unit, targetPosition)
	-- Validate unit and player selection
	if not unit or selectedUnits[player] ~= unit then
		warn("Player tried to move unselected unit")
		return
	end

	-- Get unit controller
	local unitController = unitControllers[unit]
	if not unitController then
		unitController = UnitController.new(unit, gridSystem)
		unitControllers[unit] = unitController
	end

	-- Try to move unit
	print("Attempting to move unit to:", targetPosition)
	local success = unitController:MoveToWorldPosition(targetPosition)

	if success then
		print("Unit movement successful")
		-- Update clients about movement
		moveUnitRemote:FireAllClients(unit, targetPosition)
	else
		print("Unit movement failed")
	end
end)

-- Handle attack
attackTargetRemote.OnServerEvent:Connect(function(player, attackingUnit, targetUnit)
	-- Validate attacking unit
	if not attackingUnit or selectedUnits[player] ~= attackingUnit then
		warn("Player tried to attack with unselected unit")
		return
	end

	-- Get unit controller
	local unitController = unitControllers[attackingUnit]
	if not unitController then return end

	-- Try to attack
	local success = unitController:AttackTarget(targetUnit)

	if success then
		print("Attack successful")
	else
		print("Attack failed")
	end
end)

-- Handle end turn
endTurnRemote.OnServerEvent:Connect(function(player)
	print("Player", player.Name, "ended turn")
	-- Additional turn management would go here
end)

-- Initialize when server starts
task.spawn(function()
	task.wait(2) -- Give time for map to load
	initializeGame()
end)

Players.PlayerAdded:Connect(function(player)
	print("Player joined:", player.Name)
	-- Could initialize player-specific state here
end)

print("Game interaction handler initialized")