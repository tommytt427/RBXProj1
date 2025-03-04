local UnitController = {}
UnitController.__index = UnitController

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Constants
local ANIMATION_SPEED = 1.5
local ACTION_POINTS_PER_TURN = 2

-- Required modules
local GridSystem = require(script.Parent.GridSystem)

-- Creates a new Unit Controller
function UnitController.new(character, gridSystem)
	local self = setmetatable({}, UnitController)

	self.Character = character
	self.GridSystem = gridSystem or GridSystem.new()
	self.IsMoving = false
	self.CurrentPath = nil
	self.MovementRange = 5 -- Default movement range in grid cells
	self.ActionPoints = ACTION_POINTS_PER_TURN
	self.IsPlayerTurn = true -- For turn-based system
	self.InCover = false
	self.CoverType = "None" -- "None", "Half", "Full"

	-- Track current grid position
	local worldPos = character:GetPivot().Position
	self.CurrentGridPos = self.GridSystem:WorldToGrid(worldPos)

	-- Mark initial position as occupied
	self.GridSystem:SetCellOccupied(self.CurrentGridPos, true)

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

	-- Calculate path (in a real implementation, use proper pathfinding)
	self.CurrentPath = {targetCell}

	-- Visualize the path
	self.GridSystem:VisualizePathBetween(currentCell, targetCell)

	-- Start movement
	self:ExecuteMove()

	return true
end

-- Execute the movement along the current path
function UnitController:ExecuteMove()
	if not self.CurrentPath or #self.CurrentPath == 0 then
		return
	end

	self.IsMoving = true

	-- Update grid occupation
	self.GridSystem:SetCellOccupied(self.CurrentGridPos, false)

	-- Get target position
	local targetCell = self.CurrentPath[1]
	local targetWorldPos = targetCell.Position

	-- Play movement animation
	self:PlayMoveAnimation()

	-- Move character (would be smoother with tweening in a real implementation)
	local character = self.Character
	local humanoid = character:FindFirstChildOfClass("Humanoid")

	if humanoid then
		humanoid:MoveTo(targetWorldPos)

		-- Wait for movement to complete
		local connection
		connection = RunService.Heartbeat:Connect(function()
			local distance = (character:GetPivot().Position - targetWorldPos).Magnitude
			if distance < 1 then
				connection:Disconnect()

				-- Update current position
				self.CurrentGridPos = self.GridSystem:WorldToGrid(targetWorldPos)
				self.GridSystem:SetCellOccupied(self.CurrentGridPos, true)

				-- Remove from path
				table.remove(self.CurrentPath, 1)

				-- Check for more steps in path
				if #self.CurrentPath > 0 then
					self:ExecuteMove()
				else
					self.IsMoving = false
					self.ActionPoints = self.ActionPoints - 1

					-- Check cover state
					self:UpdateCoverState()

					-- Clear path visuals
					self.GridSystem:ClearPathVisuals()

					-- Update movement range display
					self:ShowMovementRange()
				end
			end
		end)
	end
end

-- Play movement animation
function UnitController:PlayMoveAnimation()
	local humanoid = self.Character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Animator then
		local runAnim = humanoid.Animator:LoadAnimation(script.RunAnimation)
		runAnim:Play()
		runAnim:AdjustSpeed(ANIMATION_SPEED)
	end
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

	-- Check line of sight (simplified - would use raycasting in full implementation)
	local distance = (targetPos - myPos).Magnitude

	-- Check if target is within attack range (simplified)
	local maxAttackRange = 20 -- Example value
	if distance > maxAttackRange then
		return false
	end

	-- Check if there's cover between attacker and target
	local targetGridPos = self.GridSystem:WorldToGrid(targetPos)
	local targetCell = self.GridSystem:GetCellAtGrid(targetGridPos)

	if targetCell and targetCell.Cover then
		-- Target is in cover, would need to check if the cover protects from this angle
		local coverEffectiveness = self.GridSystem:HasCoverFrom(targetPos, myPos)

		-- Simplified hit chance calculation
		if coverEffectiveness == "Full" then
			-- Harder to hit
			self.HitChance = 0.4 -- 40% chance
		elseif coverEffectiveness == "Half" then
			-- Somewhat harder to hit
			self.HitChance = 0.7 -- 70% chance
		else
			-- No cover
			self.HitChance = 0.9 -- 90% chance
		end
	else
		-- No cover
		self.HitChance = 0.9 -- 90% chance
	end

	return true
end

-- Perform attack on target
function UnitController:AttackTarget(targetCharacter)
	if not self:CanAttackTarget(targetCharacter) then
		return false
	end

	-- Play attack animation
	self:PlayAttackAnimation()

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
	local humanoid = self.Character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Animator then
		local attackAnim = humanoid.Animator:LoadAnimation(script.AttackAnimation)
		attackAnim:Play()
	end
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