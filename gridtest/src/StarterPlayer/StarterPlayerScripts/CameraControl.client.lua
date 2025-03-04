-- Camera control script for tactical game
-- This should be placed in StarterPlayerScripts

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local camera = workspace.CurrentCamera

-- Camera settings
local cameraSettings = {
	ZoomSpeed = 5,
	RotateSpeed = 1,
	PanSpeed = 1,
	MaxZoom = 100,
	MinZoom = 10,
	CurrentZoom = 40,
	TargetPosition = Vector3.new(0, 0, 0)
}

-- Wait for character to load
local player = game.Players.LocalPlayer
player.CharacterAdded:Connect(function(character)
	-- Set initial camera position
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = CFrame.new(Vector3.new(0, 40, 40), Vector3.new(0, 0, 0))
end)

-- Update camera position each frame
RunService.RenderStepped:Connect(function(deltaTime)
	local targetCFrame = CFrame.new(
		cameraSettings.TargetPosition + Vector3.new(0, cameraSettings.CurrentZoom, cameraSettings.CurrentZoom),
		cameraSettings.TargetPosition
	)

	-- Smoothly interpolate to target position
	camera.CFrame = camera.CFrame:Lerp(targetCFrame, 0.1)
end)

-- Handle mouse wheel for zoom
UserInputService.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseWheel then
		cameraSettings.CurrentZoom = math.clamp(
			cameraSettings.CurrentZoom - (input.Position.Z * cameraSettings.ZoomSpeed),
			cameraSettings.MinZoom,
			cameraSettings.MaxZoom
		)
	end
end)

-- Handle keyboard input for panning
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.W then
		cameraSettings.TargetPosition = cameraSettings.TargetPosition + Vector3.new(0, 0, -5)
	elseif input.KeyCode == Enum.KeyCode.S then
		cameraSettings.TargetPosition = cameraSettings.TargetPosition + Vector3.new(0, 0, 5)
	elseif input.KeyCode == Enum.KeyCode.A then
		cameraSettings.TargetPosition = cameraSettings.TargetPosition + Vector3.new(-5, 0, 0)
	elseif input.KeyCode == Enum.KeyCode.D then
		cameraSettings.TargetPosition = cameraSettings.TargetPosition + Vector3.new(5, 0, 0)
	end
end)

print("Camera control script loaded")