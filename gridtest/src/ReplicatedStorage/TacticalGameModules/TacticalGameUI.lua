local TacticalGameUI = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Variables
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("TacticalGameRemotes")

-- UI elements
local mainGui = nil
local actionPanel = nil
local unitInfoPanel = nil
local hitChanceIndicator = nil
local turnIndicator = nil
local actionButtons = {}

-- UI Configuration
local UI_COLORS = {
	Background = Color3.fromRGB(40, 40, 40),
	Panel = Color3.fromRGB(60, 60, 60),
	Button = Color3.fromRGB(80, 100, 120),
	ButtonHover = Color3.fromRGB(100, 120, 140),
	ButtonDisabled = Color3.fromRGB(80, 80, 80),
	Text = Color3.fromRGB(240, 240, 240),
	Highlight = Color3.fromRGB(100, 200, 255),
	Warning = Color3.fromRGB(255, 200, 80),
	Error = Color3.fromRGB(255, 100, 100),
	Success = Color3.fromRGB(100, 255, 100)
}

-- Create the main UI
function TacticalGameUI:Create()
	-- Create main ScreenGui
	mainGui = Instance.new("ScreenGui")
	mainGui.Name = "TacticalGameUI"
	mainGui.ResetOnSpawn = false
	mainGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	mainGui.Parent = playerGui

	-- Create action panel
	self:CreateActionPanel()

	-- Create unit info panel
	self:CreateUnitInfoPanel()

	-- Create hit chance indicator
	self:CreateHitChanceIndicator()

	-- Create turn indicator
	self:CreateTurnIndicator()

	-- Connect events
	self:ConnectEvents()

	return mainGui
end

-- Create the action panel with buttons
function TacticalGameUI:CreateActionPanel()
	actionPanel = Instance.new("Frame")
	actionPanel.Name = "ActionPanel"
	actionPanel.AnchorPoint = Vector2.new(1, 1)
	actionPanel.Position = UDim2.new(1, -20, 1, -20)
	actionPanel.Size = UDim2.new(0, 200, 0, 180)
	actionPanel.BackgroundColor3 = UI_COLORS.Panel
	actionPanel.BorderSizePixel = 0

	-- Add corner radius
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = actionPanel

	-- Add panel title
	local panelTitle = Instance.new("TextLabel")
	panelTitle.Name = "Title"
	panelTitle.Position = UDim2.new(0, 0, 0, 0)
	panelTitle.Size = UDim2.new(1, 0, 0, 30)
	panelTitle.BackgroundTransparency = 1
	panelTitle.TextColor3 = UI_COLORS.Highlight
	panelTitle.Font = Enum.Font.GothamBold
	panelTitle.TextSize = 18
	panelTitle.Text = "ACTIONS"
	panelTitle.Parent = actionPanel

	-- Create action buttons
	local buttonData = {
		{name = "MoveButton", text = "MOVE", position = UDim2.new(0, 0, 0, 40)},
		{name = "AttackButton", text = "ATTACK", position = UDim2.new(0, 0, 0, 80)},
		{name = "OverwatchButton", text = "OVERWATCH", position = UDim2.new(0, 0, 0, 120)},
		{name = "EndTurnButton", text = "END TURN", position = UDim2.new(0, 0, 0, 160)}
	}

	for _, data in ipairs(buttonData) do
		local button = self:CreateActionButton(data.name, data.text, data.position)
		button.Parent = actionPanel
		actionButtons[data.name] = button
	end

	-- Disable buttons by default
	self:SetButtonsEnabled(false)

	actionPanel.Parent = mainGui
end

-- Create an action button
function TacticalGameUI:CreateActionButton(name, text, position)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Position = position
	button.Size = UDim2.new(1, -20, 0, 30)
	button.AnchorPoint = Vector2.new(0, 0)
	button.BackgroundColor3 = UI_COLORS.Button
	button.BorderSizePixel = 0
	button.AutoButtonColor = false
	button.TextColor3 = UI_COLORS.Text
	button.Font = Enum.Font.GothamSemibold
	button.TextSize = 14
	button.Text = text

	-- Add corner radius
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = button

	-- Add hover effect
	button.MouseEnter:Connect(function()
		if button.BackgroundColor3 ~= UI_COLORS.ButtonDisabled then
			TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = UI_COLORS.ButtonHover}):Play()
		end
	end)

	button.MouseLeave:Connect(function()
		if button.BackgroundColor3 ~= UI_COLORS.ButtonDisabled then
			TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = UI_COLORS.Button}):Play()
		end
	end)

	return button
end

-- Create unit info panel
function TacticalGameUI:CreateUnitInfoPanel()
	unitInfoPanel = Instance.new("Frame")
	unitInfoPanel.Name = "UnitInfoPanel"
	unitInfoPanel.AnchorPoint = Vector2.new(0, 1)
	unitInfoPanel.Position = UDim2.new(0, 20, 1, -20)
	unitInfoPanel.Size = UDim2.new(0, 240, 0, 180)
	unitInfoPanel.BackgroundColor3 = UI_COLORS.Panel
	unitInfoPanel.BorderSizePixel = 0
	unitInfoPanel.Visible = false

	-- Add corner radius
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = unitInfoPanel

	-- Unit name
	local unitName = Instance.new("TextLabel")
	unitName.Name = "UnitName"
	unitName.Position = UDim2.new(0, 10, 0, 10)
	unitName.Size = UDim2.new(1, -20, 0, 24)
	unitName.BackgroundTransparency = 1
	unitName.TextColor3 = UI_COLORS.Highlight
	unitName.Font = Enum.Font.GothamBold
	unitName.TextSize = 16
	unitName.TextXAlignment = Enum.TextXAlignment.Left
	unitName.Text = "Unit Name"
	unitName.Parent = unitInfoPanel

	-- Health background
	local healthBg = Instance.new("Frame")
	healthBg.Name = "HealthBackground"
	healthBg.Position = UDim2.new(0, 10, 0, 40)
	healthBg.Size = UDim2.new(1, -20, 0, 16)
	healthBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	healthBg.BorderSizePixel = 0
	healthBg.Parent = unitInfoPanel

	-- Health bar
	local healthBar = Instance.new("Frame")
	healthBar.Name = "HealthBar"
	healthBar.Position = UDim2.new(0, 0, 0, 0)
	healthBar.Size = UDim2.new(1, 0, 1, 0)
	healthBar.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
	healthBar.BorderSizePixel = 0
	healthBar.Parent = healthBg

	-- Health text
	local healthText = Instance.new("TextLabel")
	healthText.Name = "HealthText"
	healthText.Position = UDim2.new(0, 0, 0, 0)
	healthText.Size = UDim2.new(1, 0, 1, 0)
	healthText.BackgroundTransparency = 1
	healthText.TextColor3 = UI_COLORS.Text
	healthText.Font = Enum.Font.GothamBold
	healthText.TextSize = 12
	healthText.Text = "100/100"
	healthText.Parent = healthBg

	-- Stats section
	local statsFrame = Instance.new("Frame")
	statsFrame.Name = "Stats"
	statsFrame.Position = UDim2.new(0, 10, 0, 65)
	statsFrame.Size = UDim2.new(1, -20, 0, 100)
	statsFrame.BackgroundTransparency = 1
	statsFrame.Parent = unitInfoPanel

	-- Create stat labels
	local statLabels = {
		{name = "ActionPoints", text = "AP: 2/2"},
		{name = "Accuracy", text = "Accuracy: 75%"},
		{name = "Cover", text = "Cover: None"},
		{name = "Mobility", text = "Mobility: 5"}
	}

	for i, data in ipairs(statLabels) do
		local label = Instance.new("TextLabel")
		label.Name = data.name
		label.Position = UDim2.new(0, 0, 0, (i-1) * 22)
		label.Size = UDim2.new(1, 0, 0, 20)
		label.BackgroundTransparency = 1
		label.TextColor3 = UI_COLORS.Text
		label.Font = Enum.Font.Gotham
		label.TextSize = 14
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Text = data.text
		label.Parent = statsFrame
	end

	unitInfoPanel.Parent = mainGui
end

-- Create hit chance indicator
function TacticalGameUI:CreateHitChanceIndicator()
	hitChanceIndicator = Instance.new("Frame")
	hitChanceIndicator.Name = "HitChanceIndicator"
	hitChanceIndicator.Size = UDim2.new(0, 100, 0, 40)
	hitChanceIndicator.Position = UDim2.new(0.5, -50, 0.5, -20)
	hitChanceIndicator.BackgroundColor3 = UI_COLORS.Background
	hitChanceIndicator.BorderSizePixel = 0
	hitChanceIndicator.Visible = false

	-- Add corner radius
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = hitChanceIndicator

	-- Hit chance text
	local hitChanceText = Instance.new("TextLabel")
	hitChanceText.Name = "Text"
	hitChanceText.Position = UDim2.new(0, 0, 0, 0)
	hitChanceText.Size = UDim2.new(1, 0, 1, 0)
	hitChanceText.BackgroundTransparency = 1
	hitChanceText.TextColor3 = UI_COLORS.Text
	hitChanceText.Font = Enum.Font.GothamBold
	hitChanceText.TextSize = 18
	hitChanceText.Text = "75%"
	hitChanceText.Parent = hitChanceIndicator

	hitChanceIndicator.Parent = mainGui
end

-- Create turn indicator
function TacticalGameUI:CreateTurnIndicator()
	turnIndicator = Instance.new("Frame")
	turnIndicator.Name = "TurnIndicator"
	turnIndicator.AnchorPoint = Vector2.new(0.5, 0)
	turnIndicator.Position = UDim2.new(0.5, 0, 0, 20)
	turnIndicator.Size = UDim2.new(0, 200, 0, 40)
	turnIndicator.BackgroundColor3 = UI_COLORS.Panel
	turnIndicator.BorderSizePixel = 0

	-- Add corner radius
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = turnIndicator

	-- Turn text
	local turnText = Instance.new("TextLabel")
	turnText.Name = "Text"
	turnText.Position = UDim2.new(0, 0, 0, 0)
	turnText.Size = UDim2.new(1, 0, 1, 0)
	turnText.BackgroundTransparency = 1
	turnText.TextColor3 = UI_COLORS.Highlight
	turnText.Font = Enum.Font.GothamBold
	turnText.TextSize = 18
	turnText.Text = "Player Turn"
	turnText.Parent = turnIndicator

	turnIndicator.Parent = mainGui
end

-- Connect remote events
function TacticalGameUI:ConnectEvents()
	-- Connect button events
	if actionButtons.MoveButton then
		actionButtons.MoveButton.MouseButton1Click:Connect(function()
			if actionButtons.MoveButton.BackgroundColor3 ~= UI_COLORS.ButtonDisabled then
				remotes:FindFirstChild("MoveUnit"):FireServer()
			end
		end)
	end

	if actionButtons.AttackButton then
		actionButtons.AttackButton.MouseButton1Click:Connect(function()
			if actionButtons.AttackButton.BackgroundColor3 ~= UI_COLORS.ButtonDisabled then
				remotes:FindFirstChild("AttackTarget"):FireServer()
			end
		end)
	end

	if actionButtons.OverwatchButton then
		actionButtons.OverwatchButton.MouseButton1Click:Connect(function()
			if actionButtons.OverwatchButton.BackgroundColor3 ~= UI_COLORS.ButtonDisabled then
				-- Overwatch functionality would be implemented here
			end
		end)
	end

	if actionButtons.EndTurnButton then
		actionButtons.EndTurnButton.MouseButton1Click:Connect(function()
			remotes:FindFirstChild("EndTurn"):FireServer()
		end)
	end

	-- Update game state event
	local updateEvent = remotes:FindFirstChild("UpdateGameState")
	if updateEvent then
		updateEvent.OnClientEvent:Connect(function(gameState)
			self:UpdateUI(gameState)
		end)
	end
end

-- Enable or disable action buttons
function TacticalGameUI:SetButtonsEnabled(enabled)
	for name, button in pairs(actionButtons) do
		if name ~= "EndTurnButton" then -- End Turn is always enabled
			if enabled then
				button.BackgroundColor3 = UI_COLORS.Button
			else
				button.BackgroundColor3 = UI_COLORS.ButtonDisabled
			end
		end
	end
end

-- Update unit info panel
function TacticalGameUI:UpdateUnitInfo(unit)
	if not unit then
		unitInfoPanel.Visible = false
		return
	end

	unitInfoPanel.Visible = true

	-- Update unit name
	unitInfoPanel.UnitName.Text = unit.Name or "Unit"

	-- Update health
	local healthBar = unitInfoPanel.HealthBackground.HealthBar
	local healthText = unitInfoPanel.HealthBackground.HealthText

	local health = unit.Health or 100
	local maxHealth = unit.MaxHealth or 100
	local healthPercent = health / maxHealth

	healthBar.Size = UDim2.new(healthPercent, 0, 1, 0)
	healthText.Text = math.floor(health) .. "/" .. math.floor(maxHealth)

	-- Update color based on health percentage
	if healthPercent > 0.6 then
		healthBar.BackgroundColor3 = Color3.fromRGB(100, 200, 100) -- Green
	elseif healthPercent > 0.3 then
		healthBar.BackgroundColor3 = Color3.fromRGB(200, 200, 100) -- Yellow
	else
		healthBar.BackgroundColor3 = Color3.fromRGB(200, 100, 100) -- Red
	end

	-- Update stats
	local stats = unitInfoPanel.Stats

	stats.ActionPoints.Text = "AP: " .. (unit.ActionPoints or 0) .. "/" .. (unit.MaxActionPoints or 2)
	stats.Accuracy.Text = "Accuracy: " .. (unit.Accuracy or 75) .. "%"
	stats.Cover.Text = "Cover: " .. (unit.CoverType or "None")
	stats.Mobility.Text = "Mobility: " .. (unit.Mobility or 5)
end

-- Show hit chance
function TacticalGameUI:ShowHitChance(chance)
	if not hitChanceIndicator then return end

	hitChanceIndicator.Visible = true
	hitChanceIndicator.Text.Text = math.floor(chance) .. "%"

	-- Color based on hit chance
	if chance >= 75 then
		hitChanceIndicator.Text.TextColor3 = UI_COLORS.Success
	elseif chance >= 50 then
		hitChanceIndicator.Text.TextColor3 = UI_COLORS.Highlight
	elseif chance >= 25 then
		hitChanceIndicator.Text.TextColor3 = UI_COLORS.Warning
	else
		hitChanceIndicator.Text.TextColor3 = UI_COLORS.Error
	end

	-- Animate appearance
	hitChanceIndicator.Size = UDim2.new(0, 90, 0, 35)
	hitChanceIndicator.BackgroundTransparency = 0.2

	TweenService:Create(hitChanceIndicator, TweenInfo.new(0.2), {
		Size = UDim2.new(0, 100, 0, 40),
		BackgroundTransparency = 0
	}):Play()

	-- Hide after a delay
	spawn(function()
		wait(2)
		TweenService:Create(hitChanceIndicator, TweenInfo.new(0.5), {
			BackgroundTransparency = 1,
			TextTransparency = 1
		}):Play()
		wait(0.5)
		hitChanceIndicator.Visible = false
		hitChanceIndicator.BackgroundTransparency = 0
		hitChanceIndicator.TextTransparency = 0
	end)
end

-- Update turn indicator
function TacticalGameUI:UpdateTurnIndicator(turnInfo)
	if not turnIndicator then return end

	turnIndicator.Text.Text = turnInfo.CurrentTurn .. " Turn - " .. turnInfo.TurnNumber

	-- Animate turn change
	turnIndicator.Size = UDim2.new(0, 190, 0, 35)
	turnIndicator.Position = UDim2.new(0.5, 0, 0, 15)

	TweenService:Create(turnIndicator, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 200, 0, 40),
		Position = UDim2.new(0.5, 0, 0, 20)
	}):Play()

	-- Change color based on whose turn it is
	if turnInfo.CurrentTurn == "Player" then
		turnIndicator.Text.TextColor3 = UI_COLORS.Highlight
	else
		turnIndicator.Text.TextColor3 = UI_COLORS.Warning
	end
end

-- Update the entire UI based on game state
function TacticalGameUI:UpdateUI(gameState)
	-- Update turn indicator
	if gameState.TurnInfo then
		self:UpdateTurnIndicator(gameState.TurnInfo)
	end

	-- Update selected unit info
	if gameState.SelectedUnit then
		self:UpdateUnitInfo(gameState.SelectedUnit)

		-- Enable/disable action buttons based on action points
		local hasActionPoints = (gameState.SelectedUnit.ActionPoints or 0) > 0
		self:SetButtonsEnabled(hasActionPoints)
	else
		self:UpdateUnitInfo(nil)
		self:SetButtonsEnabled(false)
	end

	-- Show hit chance if applicable
	if gameState.TargetInfo and gameState.TargetInfo.HitChance then
		self:ShowHitChance(gameState.TargetInfo.HitChance)
	end
end


-- Show a notification message
function TacticalGameUI:ShowNotification(message, color, duration)
	color = color or UI_COLORS.Highlight
	duration = duration or 3

	local notification = Instance.new("Frame")
	notification.Name = "Notification"
	notification.AnchorPoint = Vector2.new(0.5, 0)
	notification.Position = UDim2.new(0.5, 0, 0, -50)
	notification.Size = UDim2.new(0, 300, 0, 50)
	notification.BackgroundColor3 = UI_COLORS.Panel
	notification.BorderSizePixel = 0

	-- Add corner radius
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = notification

	-- Notification text
	local text = Instance.new("TextLabel")
	text.Position = UDim2.new(0, 0, 0, 0)
	text.Size = UDim2.new(1, 0, 1, 0)
	text.BackgroundTransparency = 1
	text.TextColor3 = color
	text.Font = Enum.Font.GothamSemibold
	text.TextSize = 16
	text.Text = message
	text.Parent = notification

	notification.Parent = mainGui

	-- Animation
	TweenService:Create(notification, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0, 70)
	}):Play()

	-- Auto-hide
	spawn(function()
		wait(duration)
		TweenService:Create(notification, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
			Position = UDim2.new(0.5, 0, 0, -50)
		}):Play()
		wait(0.5)
		notification:Destroy()
	end)
end

return TacticalGameUI