-- LBAim - LacksterBo Edition
-- For your own Roblox game
-- Place in StarterPlayer > StarterPlayerScripts

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local aimEnabled = false
local highlightEnabled = false
local teamCheckEnabled = false

local strength = 50
local fovRadius = 140

local MIN_FOV = 50
local MAX_FOV = 400
local MAX_DISTANCE = 500

local BLACK = Color3.fromRGB(0, 0, 0)
local GREEN = Color3.fromRGB(0, 255, 0)
local RED = Color3.fromRGB(255, 0, 0)
local WHITE = Color3.fromRGB(255, 255, 255)

-- Main UI
local gui = Instance.new("ScreenGui")
gui.Name = "LBAim"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.fromOffset(250, 300)
main.Position = UDim2.new(0.5, -125, 0.5, -150)
main.BackgroundColor3 = BLACK
main.BackgroundTransparency = 0.05
main.Parent = gui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 14)
mainCorner.Parent = main

-- Color-changing outline
local stroke = Instance.new("UIStroke")
stroke.Thickness = 2
stroke.Transparency = 0.05
stroke.Parent = main

local outlineHue = 0
RunService.RenderStepped:Connect(function(dt)
	outlineHue = (outlineHue + dt * 0.12) % 1
	stroke.Color = Color3.fromHSV(outlineHue, 1, 1)
end)

-- LacksterBo top-left branding
local brand = Instance.new("TextLabel")
brand.Name = "Brand"
brand.Size = UDim2.fromOffset(105, 25)
brand.Position = UDim2.fromOffset(10, 7)
brand.BackgroundTransparency = 1
brand.Text = "LacksterBo"
brand.TextScaled = true
brand.Font = Enum.Font.GothamBold
brand.TextXAlignment = Enum.TextXAlignment.Left
brand.Parent = main

local brandGradient = Instance.new("UIGradient")
brandGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 170, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 255, 120))
})
brandGradient.Parent = brand

-- Title / drag area
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundTransparency = 1
title.Text = "LBAim"
title.TextColor3 = WHITE
title.TextScaled = true
title.Parent = main

-- FOV circle
local circle = Instance.new("Frame")
circle.Name = "FOVCircle"
circle.AnchorPoint = Vector2.new(0.5, 0.5)
circle.Position = UDim2.fromScale(0.5, 0.5)
circle.Size = UDim2.fromOffset(fovRadius * 2, fovRadius * 2)
circle.BackgroundTransparency = 1
circle.BorderSizePixel = 0
circle.Visible = false
circle.Parent = gui

local circleCorner = Instance.new("UICorner")
circleCorner.CornerRadius = UDim.new(1, 0)
circleCorner.Parent = circle

local circleStroke = Instance.new("UIStroke")
circleStroke.Thickness = 2
circleStroke.Transparency = 0.1
circleStroke.Color = WHITE
circleStroke.Parent = circle

-- Button creator
local function createButton(name, text, position)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Text = text
	button.TextScaled = true
	button.TextColor3 = WHITE
	button.BackgroundColor3 = RED
	button.Size = UDim2.fromOffset(105, 42)
	button.Position = position
	button.Parent = main

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = button

	return button
end

local aimToggle = createButton("AimToggle", "AIM: OFF", UDim2.fromOffset(15, 50))
local espToggle = createButton("ESP_Toggle", "ESP: OFF", UDim2.fromOffset(130, 50))
local teamToggle = createButton("TeamCheckToggle", "TEAM: OFF", UDim2.fromOffset(72, 98))

-- Slider creator
local function createSlider(name, y, text)
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Size = UDim2.new(1, -30, 0, 55)
	frame.Position = UDim2.fromOffset(15, y)
	frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	frame.BackgroundTransparency = 0.05
	frame.Parent = main

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = frame

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = WHITE
	label.TextScaled = true
	label.Parent = frame

	return frame, label
end

local strengthSlider, strengthLabel = createSlider("StrengthSlider", 150, "Strength: 50%")
local fovSlider, fovLabel = createSlider("FOVSlider", 215, "FOV: 140")

local function getSliderValue(frame, input)
	local x = (input.Position.X - frame.AbsolutePosition.X) / frame.AbsoluteSize.X
	return math.clamp(x, 0, 1)
end

local function connectSlider(frame, callback)
	local dragging = false

	frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch
			or input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			callback(getSliderValue(frame, input))
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if not dragging then return end

		if input.UserInputType == Enum.UserInputType.Touch
			or input.UserInputType == Enum.UserInputType.MouseMovement then
			callback(getSliderValue(frame, input))
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch
			or input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)
end

connectSlider(strengthSlider, function(value)
	strength = math.clamp(math.floor(value * 100), 1, 100)
	strengthLabel.Text = "Strength: " .. strength .. "%"
end)

local function updateFOV()
	circle.Size = UDim2.fromOffset(fovRadius * 2, fovRadius * 2)
	fovLabel.Text = "FOV: " .. fovRadius
end

connectSlider(fovSlider, function(value)
	fovRadius = math.floor(MIN_FOV + ((MAX_FOV - MIN_FOV) * value))
	updateFOV()
end)

-- Make the whole panel draggable
local draggingPanel = false
local dragStart
local startPosition

title.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch
		or input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingPanel = true
		dragStart = input.Position
		startPosition = main.Position
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if not draggingPanel then return end

	if input.UserInputType == Enum.UserInputType.Touch
		or input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Position - dragStart

		main.Position = UDim2.new(
			startPosition.X.Scale,
			startPosition.X.Offset + delta.X,
			startPosition.Y.Scale,
			startPosition.Y.Offset + delta.Y
		)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch
		or input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingPanel = false
	end
end)

local function updateToggle(button, enabled, onText, offText)
	button.Text = enabled and onText or offText
	button.BackgroundColor3 = enabled and GREEN or RED
end

-- Aim toggle
aimToggle.Activated:Connect(function()
	aimEnabled = not aimEnabled
	updateToggle(aimToggle, aimEnabled, "AIM: ON", "AIM: OFF")
	circle.Visible = aimEnabled
end)

-- Team Check toggle
teamToggle.Activated:Connect(function()
	teamCheckEnabled = not teamCheckEnabled
	updateToggle(teamToggle, teamCheckEnabled, "TEAM: ON", "TEAM: OFF")
end)

-- Find closest visible target
local function getTarget()
	local bestTarget = nil
	local bestDistance = math.huge

	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= player then

			if teamCheckEnabled
				and player.Team ~= nil
				and otherPlayer.Team ~= nil
				and player.Team == otherPlayer.Team then
				continue
			end

			local character = otherPlayer.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local head = character and character:FindFirstChild("Head")

			if humanoid and humanoid.Health > 0 and root and head then
				local distance = (root.Position - camera.CFrame.Position).Magnitude

				if distance <= MAX_DISTANCE then
					local screenPosition, onScreen =
						camera:WorldToViewportPoint(head.Position)

					if onScreen then
						local center = Vector2.new(
							camera.ViewportSize.X / 2,
							camera.ViewportSize.Y / 2
						)

						local screenDistance =
							(Vector2.new(screenPosition.X, screenPosition.Y) - center).Magnitude

						if screenDistance <= fovRadius
							and screenDistance < bestDistance then

							local origin = camera.CFrame.Position
							local direction = head.Position - origin

							local params = RaycastParams.new()
							params.FilterType = Enum.RaycastFilterType.Exclude
							params.FilterDescendantsInstances = {player.Character}

							local result = workspace:Raycast(
								origin,
								direction,
								params
							)

							if result
								and result.Instance
								and result.Instance:IsDescendantOf(character) then
								bestTarget = head
								bestDistance = screenDistance
							end
						end
					end
				end
			end
		end
	end

	return bestTarget
end

-- Aim assist
RunService.RenderStepped:Connect(function()
	if not aimEnabled then return end

	local target = getTarget()

	if target then
		local cameraPosition = camera.CFrame.Position
		local targetCFrame = CFrame.lookAt(cameraPosition, target.Position)
		local alpha = strength / 100

		camera.CFrame = camera.CFrame:Lerp(targetCFrame, alpha)
	end
end)

-- Player highlights
local highlights = {}

local function addHighlight(otherPlayer)
	if otherPlayer == player then return end

	local character = otherPlayer.Character

	if not character or highlights[otherPlayer] then return end

	local highlight = Instance.new("Highlight")
	highlight.Name = "PlayerHighlight"
	highlight.Adornee = character
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.FillTransparency = 0.55
	highlight.OutlineTransparency = 0
	highlight.Parent = character

	highlights[otherPlayer] = highlight
end

local function removeHighlight(otherPlayer)
	local highlight = highlights[otherPlayer]

	if highlight then
		highlight:Destroy()
		highlights[otherPlayer] = nil
	end
end

local function updateHighlights()
	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= player then
			if highlightEnabled then
				addHighlight(otherPlayer)
			else
				removeHighlight(otherPlayer)
			end
		end
	end
end

-- ESP toggle
espToggle.Activated:Connect(function()
	highlightEnabled = not highlightEnabled

	updateToggle(
		espToggle,
		highlightEnabled,
		"ESP: ON",
		"ESP: OFF"
	)

	updateHighlights()
end)

Players.PlayerAdded:Connect(function(otherPlayer)
	if otherPlayer == player then return end

	otherPlayer.CharacterAdded:Connect(function()
		task.wait(0.2)

		if highlightEnabled then
			addHighlight(otherPlayer)
		end
	end)
end)

for _, otherPlayer in ipairs(Players:GetPlayers()) do
	if otherPlayer ~= player then
		otherPlayer.CharacterAdded:Connect(function()
			task.wait(0.2)

			if highlightEnabled then
				addHighlight(otherPlayer)
			end
		end)
	end
end

Players.PlayerRemoving:Connect(function(otherPlayer)
	removeHighlight(otherPlayer)
end)

updateFOV()
