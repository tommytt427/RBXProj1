local UnitController = {}
UnitController.__index = UnitController

-- Services
local RunService = game:GetService("RunService")

-- Constants
local ACTION_POINTS_PER_TURN = 2

-- Creates a new Unit Controller
function UnitController.new(character, gridSystem)
	local self = setmetatable({}, UnitController)

	self.Character = character
	self.GridSystem = gridSystem
	self.IsMoving = false
	self.MovementRange = 5 -- Grid cells
	self.ActionPoints = ACTION_POINTS_PER_TURN
	self.IsPlayerTurn = true
	self.InCover = false
	self.CoverType = "None" -- "None", "Half", "Full"

	-- Make sure humanoid exists
	self.Humanoid = character:FindFirstChildOfClass("Humanoid")
	if not self.Humanoid then
		self.Humanoid = Instance.new("Humanoid")
		self.Humanoid.Parent = character
	end

	-- Make sure character isn't anchored
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if rootPart and rootPart:IsA("BasePart") then
		rootPart.Anchored = false
	end

	-- Track current grid position
	local worldPos = character:GetPivot().Position
	self.CurrentGridPos = self.GridSystem:WorldToGrid(worldPos)

	-- Mark initial position as occupied
	self.GridSystem:SetCellOccupied(self.CurrentGridPos, true)

	-- Initialize movement complete connection
	self.MoveConnection = nil

	return self
end

-- Reset action points for a new turn
function UnitController:StartTurn()
	self.ActionPoints = ACTION_POINTS_PER_TURN
	self.IsPlayerTurn = true

	-- Display movement range
	self:ShowMovementRange()
end

-- End the current turn
function UnitController:EndTurn()
	self.IsPlayerTurn = false
	self.GridSystem:ClearHighlights()
	self.GridSystem:ClearPathVisuals()
end

-- Show valid movement range
function UnitController:ShowMovementRange()
	if not self.IsPlayerTurn or self.ActionPoints <= 0 then
		return
	end

	-- Get all valid cells within movement range
	local validCells = self.GridSystem:GetMovementRange(
		self.CurrentGridPos,
		self.MovementRange,
		true -- Allow diagonal movement
	)

	-- Highlight these cells
	self.GridSystem:HighlightMovementRange(validCells)

	return validCells
end

-- Move character to a world position
function UnitController:MoveToWorldPosition(worldPos)
	if self.IsMoving or not self.IsPlayerTurn or self.ActionPoints <= 0 then
		return false
	end

	-- Convert to grid position
	local targetGridPos = self.GridSystem:WorldToGrid(worldPos)

	-- Get cells
	local currentCell = self.GridSystem:GetCellAtGrid(self.CurrentGridPos)
	local targetCell = self.GridSystem:GetCellAtGrid(targetGridPos)

	if not targetCell then
		return false
	end

	-- Check if target is within movement range
	local validCells = self.GridSystem:GetMovementRange(
		self.CurrentGridPos,
		self.MovementRange,
		true -- Allow diagonal movement
	)

	local isValidTarget = false
	for _, cell in ipairs(validCells) do
		if cell == targetCell then
			isValidTarget = true
			break
		end
	end

	if not isValidTarget or targetCell.Occupied then
		return false
	end

	-- Update grid occupation
	self.GridSystem:SetCellOccupied(self.CurrentGridPos, false)

	-- Visualize the path
	self.GridSystem:VisualizePathBetween(currentCell, targetCell)

	-- Start movement
	self.IsMoving = true

	-- Use humanoid pathfinding to move to the position
	local targetPos = Vector3.new(targetCell.Position.X, targetCell.Position.Y + 3, targetCell.Position.Z)
	self.Humanoid:MoveTo(targetPos)

	-- Clean up any existing connection
	if self.MoveConnection then
		self.MoveConnection:Disconnect()
		self.MoveConnection = nil
	end

	-- Create a connection to track when movement is complete
	self.MoveConnection = self.Humanoid.MoveToFinished:Connect(function(reached)
		self.MoveConnection:Disconnect()
		self.MoveConnection = nil

		if reached then
			-- Update current position
			self.CurrentGridPos = targetGridPos
			self.GridSystem:SetCellOccupied(self.CurrentGridPos, true)

			-- Use an action point
			self.ActionPoints = self.ActionPoints - 1

			-- Check cover state
			self:UpdateCoverState()

			-- Clear path visuals
			self.GridSystem:ClearPathVisuals()

			-- Update movement range display
			self:ShowMovementRange()
		end

		self.IsMoving = false
	end)

	return true
end

-- Update the unit's cover state based on surroundings
function UnitController:UpdateCoverState()
	local currentCell = self.GridSystem:GetCellAtGrid(self.CurrentGridPos)

	if currentCell and currentCell.Cover then
		self.InCover = true
		self.CoverType = currentCell.Cover
	else
		self.InCover = false
		self.CoverType = "None"
	end

	-- Visual feedback for cover state
	self:ShowCoverState()
end

-- Visual indicator for cover state
function UnitController:ShowCoverState()
	-- Remove any existing indicator
	local existingIndicator = self.Character:FindFirstChild("CoverIndicator")
	if existingIndicator then
		existingIndicator:Destroy()
	end

	if not self.InCover then
		return
	end

	-- Create cover indicator
	local indicator = Instance.new("Part")
	indicator.Name = "CoverIndicator"
	indicator.Size = Vector3.new(0.5, 0.5, 0.5)
	indicator.Position = self.Character:GetPivot().Position + Vector3.new(0, 2, 0)
	indicator.Anchored = true
	indicator.CanCollide = false

	-- Set color based on cover type
	if self.CoverType == "Full" then
		indicator.Color = Color3.new(0, 1, 0) -- Green for full cover
	else
		indicator.Color = Color3.new(1, 1, 0) -- Yellow for half cover
	end

	indicator.Material = Enum.Material.Neon
	indicator.Transparency = 0.3
	indicator.Shape = Enum.PartType.Ball
	indicator.Parent = self.Character
end

-- Check if unit can attack from current position
function UnitController:CanAttackTarget(targetCharacter)
	if not self.IsPlayerTurn or self.ActionPoints <= 0 then
		return false
	end

	-- Get positions
	local myPos = self.Character:GetPivot().Position
	local targetPos = targetCharacter:GetPivot().Position

	-- Check distance
	local distance = (targetPos - myPos).Magnitude

	-- Check if target is within attack range (simplified)
	local maxAttackRange = 20 -- Example value
	if distance > maxAttackRange then
		return false
	end

	-- Calculate hit chance based on cover
	local targetGridPos = self.GridSystem:WorldToGrid(targetPos)
	local targetCell = self.GridSystem:GetCellAtGrid(targetGridPos)

	if targetCell and targetCell.Cover then
		-- Target is in cover, calculate cover effectiveness
		if targetCell.Cover == "Full" then
			self.HitChance = 0.4 -- 40% chance
		elseif targetCell.Cover == "Half" then
			self.HitChance = 0.7 -- 70% chance
		else
			self.HitChance = 0.9 -- 90% chance
		end
	else
		self.HitChance = 0.9 -- 90% chance
	end

	return true
end

-- Perform attack on target
function UnitController:AttackTarget(targetCharacter)
	if not self:CanAttackTarget(targetCharacter) then
		return false
	end

	-- Turn character to face target
	local myPos = self.Character:GetPivot().Position
	local targetPos = targetCharacter:GetPivot().Position
	local direction = (targetPos - myPos).Unit
	self.Character:SetPrimaryPartCFrame(CFrame.lookAt(myPos, myPos + Vector3.new(direction.X, 0, direction.Z)))

	-- Play attack animation
	local animTrack = self:PlayAttackAnimation()

	-- Wait for animation to complete
	if animTrack then
		animTrack.Stopped:Wait()
	else
		wait(0.5) -- Default attack duration
	end

	-- Calculate hit
	local hitRoll = math.random()
	local hit = hitRoll <= self.HitChance

	if hit then
		-- Deal damage
		local targetHumanoid = targetCharacter:FindFirstChildOfClass("Humanoid")
		if targetHumanoid then
			targetHumanoid:TakeDamage(25) -- Example damage value
		end

		-- Visual effect for hit
		self:ShowHitEffect(targetCharacter)
	else
		-- Visual effect for miss
		self:ShowMissEffect(targetCharacter)
	end

	-- Use an action point
	self.ActionPoints = self.ActionPoints - 1

	-- Update UI after action
	self:ShowMovementRange()

	return true
end

-- Play attack animation
function UnitController:PlayAttackAnimation()
	if self.Humanoid and self.Humanoid:FindFirstChild("Animator") then
		local animator = self.Humanoid:FindFirstChild("Animator")
		local animTrack = animator:LoadAnimation(script.Parent:FindFirstChild("AttackAnimation"))
		if animTrack then
			animTrack:Play()
			return animTrack
		end
	end
	return nil
end

-- Show hit effect
function UnitController:ShowHitEffect(targetCharacter)
	local hitEffect = Instance.new("Part")
	hitEffect.Size = Vector3.new(1, 1, 1)
	hitEffect.Position = targetCharacter:GetPivot().Position
	hitEffect.Anchored = true
	hitEffect.CanCollide = false
	hitEffect.Material = Enum.Material.Neon
	hitEffect.Color = Color3.new(1, 0, 0) -- Red for hit
	hitEffect.Transparency = 0.5
	hitEffect.Shape = Enum.PartType.Ball
	hitEffect.Parent = workspace

	-- Remove after a short time
	game:GetService("Debris"):AddItem(hitEffect, 0.5)
end

-- Show miss effect
function UnitController:ShowMissEffect(targetCharacter)
	local missEffect = Instance.new("Part")
	missEffect.Size = Vector3.new(0.5, 0.5, 0.5)
	missEffect.Position = targetCharacter:GetPivot().Position + Vector3.new(0, 1, 0)
	missEffect.Anchored = true
	missEffect.CanCollide = false
	missEffect.Material = Enum.Material.Neon
	missEffect.Color = Color3.new(0.7, 0.7, 0.7) -- Grey for miss
	missEffect.Transparency = 0.7
	missEffect.Shape = Enum.PartType.Ball
	missEffect.Parent = workspace

	-- Add "MISS" text label
	local missLabel = Instance.new("BillboardGui")
	missLabel.Size = UDim2.new(0, 100, 0, 40)
	missLabel.Adornee = missEffect
	missLabel.Parent = missEffect

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	textLabel.TextStrokeTransparency = 0
	textLabel.Text = "MISS"
	textLabel.FontSize = Enum.FontSize.Size24
	textLabel.Parent = missLabel

	-- Remove after a short time
	game:GetService("Debris"):AddItem(missEffect, 1)
end

return UnitController