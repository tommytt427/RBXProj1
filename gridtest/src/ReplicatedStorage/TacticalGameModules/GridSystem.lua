local GridSystem = {}
GridSystem.__index = GridSystem

-- Constants
local GRID_CELL_SIZE = 8 -- Size of each grid cell
local GRID_HEIGHT_THRESHOLD = 4 -- Maximum height difference for valid movement

-- Creates a new GridSystem
function GridSystem.new()
	local self = setmetatable({}, GridSystem)

	self.Cells = {} -- Will store all grid cells: { Position = Vector3, Part = Instance, Occupied = boolean, Cover = string/nil }
	self.HighlightParts = {} -- Will store highlight parts for movement range
	self.PathParts = {} -- Will store path visualization parts

	return self
end

-- Scans the workspace for grid parts and builds the grid
function GridSystem:ScanGridParts()
	self.Cells = {}

	-- Find all parts with "GridCell" tag or in a folder named "Grid"
	local gridParts = {}
	local gridFolder = workspace:FindFirstChild("Grid")

	if gridFolder then
		for _, part in ipairs(gridFolder:GetChildren()) do
			if part:IsA("BasePart") then
				table.insert(gridParts, part)
			end
		end
	end

	-- Convert parts to grid cells
	for _, part in ipairs(gridParts) do
		local cell = {
			Position = part.Position,
			Part = part,
			Occupied = false,
			Cover = part:GetAttribute("Cover") -- Can be "Full", "Half", or nil
		}

		-- Store in cells table using grid coordinates as key
		local gridPos = self:WorldToGrid(part.Position)
		local key = gridPos.X .. "," .. gridPos.Z
		self.Cells[key] = cell
	end

	return self.Cells
end

-- Convert world position to grid coordinates
function GridSystem:WorldToGrid(worldPos)
	return Vector3.new(
		math.floor(worldPos.X / GRID_CELL_SIZE + 0.5),
		math.floor(worldPos.Y + 0.5),
		math.floor(worldPos.Z / GRID_CELL_SIZE + 0.5)
	)
end

-- Convert grid coordinates to world position
function GridSystem:GridToWorld(gridPos)
	return Vector3.new(
		gridPos.X * GRID_CELL_SIZE,
		gridPos.Y,
		gridPos.Z * GRID_CELL_SIZE
	)
end

-- Get cell at grid position
function GridSystem:GetCellAtGrid(gridPos)
	local key = gridPos.X .. "," .. gridPos.Z
	return self.Cells[key]
end

-- Get cell at world position
function GridSystem:GetCellAtWorld(worldPos)
	local gridPos = self:WorldToGrid(worldPos)
	return self:GetCellAtGrid(gridPos)
end

-- Check if a move from one cell to another is valid
function GridSystem:IsValidMove(fromGridPos, toGridPos, allowDiagonal)
	-- Check if cells exist
	local fromCell = self:GetCellAtGrid(fromGridPos)
	local toCell = self:GetCellAtGrid(toGridPos)

	if not fromCell or not toCell then
		return false
	end

	-- Check if destination is occupied
	if toCell.Occupied then
		return false
	end

	-- Check if height difference is within threshold
	local heightDiff = math.abs(toCell.Position.Y - fromCell.Position.Y)
	if heightDiff > GRID_HEIGHT_THRESHOLD then
		return false
	end

	-- Check if move is orthogonal or diagonal
	local xDiff = math.abs(toGridPos.X - fromGridPos.X)
	local zDiff = math.abs(toGridPos.Z - fromGridPos.Z)

	if xDiff > 1 or zDiff > 1 then
		return false -- Too far
	end

	if xDiff == 1 and zDiff == 1 and not allowDiagonal then
		return false -- Diagonal movement not allowed
	end

	return true
end

-- Find all valid movements within a certain range
function GridSystem:GetMovementRange(startGridPos, movementPoints, allowDiagonal)
	local validCells = {}
	local visited = {}
	local queue = {}

	-- Add starting position to queue
	table.insert(queue, {Pos = startGridPos, MP = movementPoints})
	visited[startGridPos.X .. "," .. startGridPos.Z] = true

	while #queue > 0 do
		local current = table.remove(queue, 1)
		local currentPos = current.Pos
		local currentMP = current.MP

		-- Add current cell to valid cells
		local cell = self:GetCellAtGrid(currentPos)
		if cell then
			table.insert(validCells, cell)
		end

		-- If no more movement points, skip neighbors
		if currentMP <= 0 then
			continue
		end

		-- Check all neighbors
		local directions = {
			Vector3.new(1, 0, 0),
			Vector3.new(-1, 0, 0),
			Vector3.new(0, 0, 1),
			Vector3.new(0, 0, -1)
		}

		-- Add diagonal directions if allowed
		if allowDiagonal then
			table.insert(directions, Vector3.new(1, 0, 1))
			table.insert(directions, Vector3.new(1, 0, -1))
			table.insert(directions, Vector3.new(-1, 0, 1))
			table.insert(directions, Vector3.new(-1, 0, -1))
		end

		for _, dir in ipairs(directions) do
			local neighborPos = Vector3.new(
				currentPos.X + dir.X,
				currentPos.Y,
				currentPos.Z + dir.Z
			)

			local key = neighborPos.X .. "," .. neighborPos.Z

			-- Skip if already visited
			if visited[key] then
				continue
			end

			-- Check if movement is valid
			if self:IsValidMove(currentPos, neighborPos, allowDiagonal) then
				-- Calculate movement cost (1 for orthogonal, 1.4 for diagonal)
				local moveCost = 1
				if math.abs(dir.X) == 1 and math.abs(dir.Z) == 1 then
					moveCost = 1.4
				end

				-- Add to queue if we have enough movement points
				if currentMP >= moveCost then
					table.insert(queue, {Pos = neighborPos, MP = currentMP - moveCost})
					visited[key] = true
				end
			end
		end
	end

	return validCells
end

-- Create visual highlights for movement range
function GridSystem:HighlightMovementRange(cells, color)
	self:ClearHighlights()

	color = color or Color3.new(0, 0.5, 1) -- Default to blue

	for _, cell in ipairs(cells) do
		local highlight = Instance.new("Part")
		highlight.Size = Vector3.new(GRID_CELL_SIZE - 0.2, 0.1, GRID_CELL_SIZE - 0.2)
		highlight.Position = Vector3.new(cell.Position.X, cell.Position.Y + 0.1, cell.Position.Z)
		highlight.Anchored = true
		highlight.CanCollide = false
		highlight.Material = Enum.Material.Neon
		highlight.Transparency = 0.5
		highlight.Color = color
		highlight.Parent = workspace

		table.insert(self.HighlightParts, highlight)
	end
end

-- Clear movement range highlights
function GridSystem:ClearHighlights()
	for _, part in ipairs(self.HighlightParts) do
		part:Destroy()
	end
	self.HighlightParts = {}
end

-- Visualize path
function GridSystem:VisualizePathBetween(startCell, endCell, color)
	self:ClearPathVisuals()

	color = color or Color3.new(1, 1, 0) -- Default to yellow

	-- Find path using A* (simplification for now - direct line)
	local startGridPos = self:WorldToGrid(startCell.Position)
	local endGridPos = self:WorldToGrid(endCell.Position)

	-- Create path visual
	local pathPart = Instance.new("Part")
	pathPart.Size = Vector3.new(0.5, 0.15, 0.5)
	pathPart.Position = Vector3.new(endCell.Position.X, endCell.Position.Y + 0.2, endCell.Position.Z)
	pathPart.Anchored = true
	pathPart.CanCollide = false
	pathPart.Material = Enum.Material.Neon
	pathPart.Color = color
	pathPart.Parent = workspace

	table.insert(self.PathParts, pathPart)
end

-- Clear path visualization
function GridSystem:ClearPathVisuals()
	for _, part in ipairs(self.PathParts) do
		part:Destroy()
	end
	self.PathParts = {}
end

-- Mark a cell as occupied
function GridSystem:SetCellOccupied(gridPos, occupied)
	local cell = self:GetCellAtGrid(gridPos)
	if cell then
		cell.Occupied = occupied
	end
end

-- Check if a position has cover from a specific direction
function GridSystem:HasCoverFrom(position, threatPosition)
	local cell = self:GetCellAtWorld(position)
	if not cell or not cell.Cover then
		return "None" -- No cover
	end

	-- Calculate direction from threat to position
	local direction = (position - threatPosition).Unit

	-- Check if cover blocks this direction (simplified for prototype)
	-- Would need to be expanded for actual cover system
	return cell.Cover -- Return cover type
end

return GridSystem