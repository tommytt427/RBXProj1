-- Unit Selection and Grid Interaction Script (LocalScript)
-- Place this in StarterPlayerScripts

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- Get modules
local modulesFolder = ReplicatedStorage:WaitForChild("TacticalGameModules")
local GridSystem = require(modulesFolder:WaitForChild("GridSystem"))

-- Get remotes
local remotes = ReplicatedStorage:WaitForChild("TacticalGameRemotes")
local selectUnitRemote = remotes:WaitForChild("SelectUnit")
local moveUnitRemote = remotes:WaitForChild("MoveUnit")

-- Game state
local gridSystem = GridSystem.new()
local selectedUnit = nil
local hoverPart = nil
local moveRangeHighlighted = false
local validCells = {}

-- Visuals
local selectionBox = Instance.new("SelectionBox")
selectionBox.LineThickness = 0.05
selectionBox.Color3 = Color3.fromRGB(0, 200, 255)
selectionBox.Parent = workspace

-- Wait for the grid to be created
local function waitForGrid()
	local gridFolder = workspace:FindFirstChild("Grid")
	if not gridFolder then
		gridFolder = workspace:WaitForChild("Grid", 10)
	end

	if gridFolder then
		-- Initialize grid system
		gridSystem:ScanGridParts()
		print("Grid system initialized")

		-- Add click detection to grid cells
		for _, cell in pairs(gridSystem.Cells) do
			local clickDetector = cell.Part:FindFirstChild("ClickDetector")
			if not clickDetector then
				clickDetector = Instance.new("ClickDetector")
				clickDetector.MaxActivationDistance = 1000
				clickDetector.Parent = cell.Part
			end

			-- Handle grid clicks
			clickDetector.MouseClick:Connect(function()
				print("Grid cell clicked:", cell.Position)
				if selectedUnit and #validCells > 0 then
					-- Check if clicked cell is in valid movement range
					local isValid = false
					for _, validCell in ipairs(validCells) do
						if validCell.Position == cell.Position then
							isValid = true
							break
						end
					end

					if isValid then
						print("Moving unit to:", cell.Position)
						moveUnitRemote:FireServer(selectedUnit, cell.Position)
					else
						print("Invalid move target")
					end
				end
			end)
		end
	else
		warn("Could not find Grid folder")
	end
end

-- Create hover effect for selectable units
local function createHoverEffect(part)
	if part and (part.Parent:FindFirstChild("Humanoid") or part.Parent.Parent:FindFirstChild("Humanoid")) then
		if hoverPart ~= part then
			if hoverPart then
				-- Clear previous hover
				hoverPart.Transparency = hoverPart:GetAttribute("OriginalTransparency") or hoverPart.Transparency
			end

			-- Store original transparency
			if not part:GetAttribute("OriginalTransparency") then
				part:SetAttribute("OriginalTransparency", part.Transparency)
			end

			-- Add hover effect
			hoverPart = part
			if not part:IsA("MeshPart") then  -- Don't modify mesh transparency as it can look strange
				hoverPart.Transparency = math.min(0.3, hoverPart.Transparency + 0.1)
			end
		end
	elseif hoverPart then
		-- Clear hover effect when not hovering over a unit
		hoverPart.Transparency = hoverPart:GetAttribute("OriginalTransparency") or hoverPart.Transparency
		hoverPart = nil
	end
end

-- Highlight movement range for selected unit
local function highlightMovementRange(unit)
	-- Clear previous highlights
	gridSystem:ClearHighlights()
	validCells = {}

	if unit then
		-- Get unit's current position
		local unitPos = unit:GetPivot().Position
		local gridPos = gridSystem:WorldToGrid(unitPos)

		-- Get valid movement cells (assuming 5 movement range for testing)
		validCells = gridSystem:GetMovementRange(gridPos, 5, true)

		-- Highlight cells
		gridSystem:HighlightMovementRange(validCells, Color3.fromRGB(0, 100, 255))
		moveRangeHighlighted = true
	else
		moveRangeHighlighted = false
	end
end

-- Handle player input
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		-- Check if clicking on a unit
		local target = mouse.Target
		if target then
			-- Find unit model (could be a part of the model)
			local model = target
			while model and not model:FindFirstChildOfClass("Humanoid") do
				model = model.Parent
				if not model or model == workspace then
					model = nil
					break
				end
			end

			if model and model:FindFirstChildOfClass("Humanoid") then
				-- Clicked on a unit
				print("Unit selected:", model.Name)
				selectedUnit = model
				selectionBox.Adornee = model

				-- Notify server about selection
				selectUnitRemote:FireServer(model)

				-- Highlight movement range
				highlightMovementRange(model)
			elseif target.Parent == workspace:FindFirstChild("Grid") then
				-- Clicked on a grid cell
				print("Grid cell clicked directly")
				-- Grid click handling is done in the click detector events
			else
				-- Clicked elsewhere, deselect
				selectedUnit = nil
				selectionBox.Adornee = nil
				gridSystem:ClearHighlights()
			end
		end
	elseif input.KeyCode == Enum.KeyCode.Escape then
		-- Deselect on escape
		selectedUnit = nil
		selectionBox.Adornee = nil
		gridSystem:ClearHighlights()
	end
end)

-- Update hover effect
RunService.RenderStepped:Connect(function()
	if mouse.Target then
		createHoverEffect(mouse.Target)
	else
		if hoverPart then
			hoverPart.Transparency = hoverPart:GetAttribute("OriginalTransparency") or hoverPart.Transparency
			hoverPart = nil
		end
	end
end)

-- Wait for the game to load
waitForGrid()

-- Handle remotes from server
moveUnitRemote.OnClientEvent:Connect(function(unit, newPosition)
	-- Update selection and movement range after unit moves
	if unit == selectedUnit then
		highlightMovementRange(unit)
	end
end)

print("Unit selection handler initialized")