local CoverSystem = {}

-- Services
local RunService = game:GetService("RunService")

-- Constants
local COVER_TYPES = {
	NONE = "None",
	HALF = "Half",
	FULL = "Full"
}

local COVER_MODIFIERS = {
	[COVER_TYPES.NONE] = 0,        -- No cover bonus
	[COVER_TYPES.HALF] = 40,       -- 40% chance reduction to be hit
	[COVER_TYPES.FULL] = 70        -- 70% chance reduction to be hit
}

-- Cover visualization properties
local COVER_COLORS = {
	[COVER_TYPES.NONE] = Color3.new(1, 0.2, 0.2),     -- Red
	[COVER_TYPES.HALF] = Color3.new(1, 0.8, 0.2),     -- Yellow
	[COVER_TYPES.FULL] = Color3.new(0.2, 1, 0.2)      -- Green
}

-- Find cover status for a position relative to a threat position
function CoverSystem:GetCoverStatus(position, threatPosition, gridSystem)
	-- Get the normalized direction from position to threat
	local direction = (threatPosition - position).Unit

	-- Get cell at position
	local cell = gridSystem:GetCellAtWorld(position)
	if not cell then
		return COVER_TYPES.NONE
	end

	-- Check if this cell provides cover
	local cellCover = cell.Cover or COVER_TYPES.NONE

	-- If cell has no cover, check adjacent cells for cover in the threat direction
	if cellCover == COVER_TYPES.NONE then
		-- Calculate which adjacent cell to check based on threat direction
		local gridPos = gridSystem:WorldToGrid(position)

		-- Determine which direction the threat is coming from
		local dirX = 0
		local dirZ = 0

		if math.abs(direction.X) > math.abs(direction.Z) then
			-- Threat is coming more from X direction
			dirX = direction.X > 0 and 1 or -1
		else
			-- Threat is coming more from Z direction
			dirZ = direction.Z > 0 and 1 or -1
		end

		-- Check the cell in that direction for cover
		local adjacentGridPos = Vector3.new(gridPos.X + dirX, gridPos.Y, gridPos.Z + dirZ)
		local adjacentCell = gridSystem:GetCellAtGrid(adjacentGridPos)

		if adjacentCell and adjacentCell.Cover then
			-- Check if the cover is facing the right way to protect from the threat
			local coverDirection = (adjacentGridPos - gridPos).Unit
			local dotProduct = coverDirection:Dot(direction)

			-- If the dot product is positive, the cover is facing toward the threat
			if dotProduct > 0 then
				return adjacentCell.Cover
			end
		end
	end

	return cellCover
end

-- Calculate hit chance modifier based on cover
function CoverSystem:GetHitChanceModifier(coverType)
	return COVER_TYPES[coverType] or 0
end

-- Visual representation of cover status for a unit
function CoverSystem:VisualizeCover(unit, coverType)
	-- Remove existing visualization
	local existingCover = unit.Character:FindFirstChild("CoverVisualization")
	if existingCover then
		existingCover:Destroy()
	end

	if coverType == COVER_TYPES.NONE then
		return -- Don't visualize no cover
	end

	-- Create cover visualization
	local visualization = Instance.new("Part")
	visualization.Name = "CoverVisualization"
	visualization.Anchored = true
	visualization.CanCollide = false
	visualization.Material = Enum.Material.Neon
	visualization.Transparency = 0.5
	visualization.Color = COVER_COLORS[coverType]

	-- Size and shape based on cover type
	if coverType == COVER_TYPES.FULL then
		visualization.Size = Vector3.new(3, 3, 0.2)
	else -- Half cover
		visualization.Size = Vector3.new(3, 1.5, 0.2)
	end

	visualization.Parent = unit.Character

	-- Position the visualization based on where the threat is
	if unit.LastThreatDirection then
		-- Position in front of the character, facing the threat
		local rootPart = unit.Character:FindFirstChild("HumanoidRootPart")
		if rootPart then
			local position = rootPart.Position
			visualization.CFrame = CFrame.new(
				position,
				position + unit.LastThreatDirection
			) * CFrame.new(0, visualization.Size.Y/2, -1)
		end
	end

	return visualization
end

-- Update cover visualization when threat positions change
function CoverSystem:UpdateCoverVisualization(unit, threatUnits, gridSystem)
	-- Find the nearest threat
	local nearestThreat = nil
	local nearestDistance = math.huge

	local rootPart = unit.Character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	local position = rootPart.Position

	for _, threatUnit in ipairs(threatUnits) do
		local threatRootPart = threatUnit.Character:FindFirstChild("HumanoidRootPart")
		if threatRootPart then
			local threatPosition = threatRootPart.Position
			local distance = (position - threatPosition).Magnitude

			if distance < nearestDistance then
				nearestDistance = distance
				nearestThreat = threatUnit
			end
		end
	end

	if nearestThreat then
		local threatRootPart = nearestThreat.Character:FindFirstChild("HumanoidRootPart")
		local threatPosition = threatRootPart.Position

		-- Store threat direction for visualization
		unit.LastThreatDirection = (threatPosition - position).Unit

		-- Get cover status
		local coverType = self:GetCoverStatus(position, threatPosition, gridSystem)

		-- Update unit's cover status
		unit.CoverType = coverType

		-- Visualize cover
		self:VisualizeCover(unit, coverType)
	end
end

-- Check if a position provides flanking against a target's cover
function CoverSystem:IsFlanking(attackerPos, targetPos, targetCoverType, gridSystem)
	if targetCoverType == COVER_TYPES.NONE then
		return false -- Can't flank if there's no cover
	end

	-- Get the unit's cover direction (opposite of threat direction)
	local targetUnit = gridSystem:GetUnitAtPosition(targetPos)
	if not targetUnit or not targetUnit.LastThreatDirection then
		return false -- No unit or threat direction
	end

	-- Calculate attack angle
	local attackDirection = (targetPos - attackerPos).Unit
	local coverDirection = -targetUnit.LastThreatDirection

	-- Calculate dot product to determine if flanking
	local dotProduct = attackDirection:Dot(coverDirection)

	-- If the dot product is negative, we're attacking from behind cover
	return dotProduct < -0.5 -- 60 degree angle or greater
end

-- Calculate hit chance taking cover into account
function CoverSystem:CalculateHitChance(baseHitChance, coverType, isFlanking)
	local coverModifier = COVER_MODIFIERS[coverType] or 0

	-- If flanking, ignore cover
	if isFlanking then
		coverModifier = 0
	end

	return math.clamp(baseHitChance - coverModifier, 10, 95) -- Min 10%, max 95% hit chance
end

return CoverSystem