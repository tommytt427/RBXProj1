-- Main Script for XCOM-style Tactical Game
-- This script should be placed in ServerScriptService

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

-- Load required modules
local modulesFolder = ReplicatedStorage:WaitForChild("TacticalGameModules")
local GridSystem = require(modulesFolder:WaitForChild("GridSystem"))
local UnitController = require(modulesFolder:WaitForChild("UnitController"))
local GameManager = require(modulesFolder:WaitForChild("GameManager"))

-- Create animation instances for the modules
local function CreateAnimations()
	-- Create animations folder
	local animationsFolder = ReplicatedStorage:FindFirstChild("TacticalGameAnimations")
	if not animationsFolder then
		animationsFolder = Instance.new("Folder")
		animationsFolder.Name = "TacticalGameAnimations"
		animationsFolder.Parent = ReplicatedStorage
	end

	-- Create run animation
	local runAnimation = animationsFolder:FindFirstChild("RunAnimation")
	if not runAnimation then
		runAnimation = Instance.new("Animation")
		runAnimation.Name = "RunAnimation"
		runAnimation.AnimationId = "rbxassetid://507777826" -- Simple run animation
		runAnimation.Parent = animationsFolder
	end

	-- Create attack animation
	local attackAnimation = animationsFolder:FindFirstChild("AttackAnimation")
	if not attackAnimation then
		attackAnimation = Instance.new("Animation")
		attackAnimation.Name = "AttackAnimation"
		attackAnimation.AnimationId = "rbxassetid://522635514" -- Simple punch animation
		attackAnimation.Parent = animationsFolder
	end

	-- Create cover animation
	local coverAnimation = animationsFolder:FindFirstChild("CoverAnimation")
	if not coverAnimation then
		coverAnimation = Instance.new("Animation")
		coverAnimation.Name = "CoverAnimation"
		coverAnimation.AnimationId = "rbxassetid://507766388" -- Crouch animation
		coverAnimation.Parent = animationsFolder
	end

	return {
		RunAnimation = runAnimation,
		AttackAnimation = attackAnimation,
		CoverAnimation = coverAnimation
	}
end

-- Copy animations to unit controller script
local function SetupAnimations(animations)
	-- Copy animations to UnitController script
	local unitControllerScript = modulesFolder:FindFirstChild("UnitController")
	if unitControllerScript then
		local runAnimation = unitControllerScript:FindFirstChild("RunAnimation")
		if not runAnimation then
			local anim = animations.RunAnimation:Clone()
			anim.Parent = unitControllerScript
		end

		local attackAnimation = unitControllerScript:FindFirstChild("AttackAnimation")
		if not attackAnimation then
			local anim = animations.AttackAnimation:Clone()
			anim.Parent = unitControllerScript
		end

		local coverAnimation = unitControllerScript:FindFirstChild("CoverAnimation")
		if not coverAnimation then
			local anim = animations.CoverAnimation:Clone()
			anim.Parent = unitControllerScript
		end
	end
end

-- Setup remote events and functions
local function SetupRemotes()
	local remoteFolder = ReplicatedStorage:FindFirstChild("TacticalGameRemotes")
	if not remoteFolder then
		remoteFolder = Instance.new("Folder")
		remoteFolder.Name = "TacticalGameRemotes"
		remoteFolder.Parent = ReplicatedStorage
	end

	-- Create remotes for game actions
	local remotes = {
		"MoveUnit",
		"AttackTarget",
		"EndTurn",
		"SelectUnit",
		"UpdateGameState"
	}

	for _, remoteName in ipairs(remotes) do
		if not remoteFolder:FindFirstChild(remoteName) then
			local remoteEvent = Instance.new("RemoteEvent")
			remoteEvent.Name = remoteName
			remoteEvent.Parent = remoteFolder
		end
	end

	return remoteFolder
end

-- Start the game
local function StartGame()
	-- Create a test map
	if GameManager.CreateTestMap then
		GameManager:CreateTestMap()
	else
		print("Warning: GameManager.CreateTestMap function not found.")
	end

	-- Initialize the game manager
	GameManager:Initialize()

	print("Tactical game initialized")
end

-- Main initialization
local function Initialize()
	local animations = CreateAnimations()
	SetupAnimations(animations)
	SetupRemotes()

	-- Wait for players and start the game
	if #Players:GetPlayers() > 0 then
		StartGame()
	else
		Players.PlayerAdded:Once(function()
			StartGame()
		end)
	end
end

-- Run initialization
Initialize()