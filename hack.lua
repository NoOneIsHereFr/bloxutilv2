local FlyGUI = {}

--// Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")

--// Player / Basic Vars
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local screenGui = Instance.new("ScreenGui")
local mainFrame, bodyVelocity, heartbeatConnection
local flying = false
local flyModeActive = false
local aimbotEnabled = false
local espEnabled = false

local DEFAULT_SPEED = 50
local DEFAULT_SIZE = 1

--// GUI elements (declared in outer scope for access)
local flyToggleBtn, noClipToggleBtn, aimbotToggleBtn, espToggleBtn
local collapseBtn
local flySettingsBtn, flySettingsFrame
local noClipSettingsBtn, noClipSettingsFrame
local aimbotSettingsBtn, aimbotSettingsFrame
local espSettingsBtn, espSettingsFrame
local teleportMenuBtn, teleportMenuFrame
local playerMenuBtn, playerMenuFrame
local unloadBtn

-- Add keybinds at the top
local KEYBIN_FLY_TOGGLE = Enum.KeyCode.F
local KEYBIN_NOCLIP_TOGGLE = Enum.KeyCode.N
local KEYBIN_AIMBOT_TOGGLE = Enum.KeyCode.Q
local KEYBIN_ESP_TOGGLE = Enum.KeyCode.E

function createSettingsFrame(titleText)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 180, 0, 80)
    frame.Position = UDim2.new(0.5, 20, 0.5, -40)
    frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    frame.Visible = false
    frame.Active = true
    frame.Draggable = true

    local title = Instance.new("TextLabel")
    title.Text = titleText
    title.Size = UDim2.new(1, 0, 0, 20)
    title.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Parent = frame

    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "Close" -- <--- ADD THIS LINE
    closeBtn.Text = "Close"
    closeBtn.Size = UDim2.new(0, 50, 0, 20)
    closeBtn.Position = UDim2.new(1, -55, 0, 0)
    closeBtn.BackgroundColor3 = Color3.fromRGB(120, 120, 120)
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Parent = frame

    closeBtn.MouseButton1Click:Connect(function()
        frame.Visible = false
    end)

    return frame
end

--================================================--
--                  ESP SYSTEM
--================================================--
-- Note: This uses the Drawing API (commonly available in exploit environments)
local tracers = {}
local espConnection

local function enableESP()
    if espEnabled then return end
    espEnabled = true

    -- Create a line for each existing player
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then
            local line = Drawing.new("Line")
            line.Color = Color3.new(1,1,1)
            line.Thickness = 1
            line.Visible = false
            tracers[p] = line
        end
    end

    espConnection = RunService.RenderStepped:Connect(function()
        for p, line in pairs(tracers) do
            local char = p.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local hrp = char.HumanoidRootPart
                local vector, onScreen = camera:WorldToViewportPoint(hrp.Position)
                if onScreen then
                    line.From = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y) -- bottom-center of screen
                    line.To = Vector2.new(vector.X, vector.Y)
                    line.Visible = true
                else
                    line.Visible = false
                end
            else
                line.Visible = false
            end
        end
    end)
end

local function disableESP()
    if not espEnabled then return end
    espEnabled = false

    if espConnection then
        espConnection:Disconnect()
        espConnection = nil
    end

    for p, line in pairs(tracers) do
        line:Remove()
        tracers[p] = nil
    end
end

Players.PlayerAdded:Connect(function(newPlayer)
    if espEnabled and newPlayer ~= player then
        local line = Drawing.new("Line")
        line.Color = Color3.new(1,1,1)
        line.Thickness = 1
        line.Visible = false
        tracers[newPlayer] = line
    end
end)

Players.PlayerRemoving:Connect(function(remPlayer)
    if tracers[remPlayer] then
        tracers[remPlayer]:Remove()
        tracers[remPlayer] = nil
    end
end)

--================================================--
--                    GUI SETUP
--================================================--
function FlyGUI.CreateGUI()
    print("[FlyGUI] Creating GUI...")

    screenGui.Name = "BloxUtilGui"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = player:WaitForChild("PlayerGui")

    mainWindow = Instance.new("Frame")
    mainWindow.Size = UDim2.new(0, 200, 0, 340)
    mainWindow.Position = UDim2.new(0.5, -100, 0.5, -170)
    mainWindow.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    mainWindow.Active = true
    mainWindow.Draggable = true
    mainWindow.Parent = screenGui

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Text = "BloxUtil v2"
    titleLabel.Size = UDim2.new(1, 0, 0, 15)
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    titleLabel.Parent = mainWindow

    -- Flight Toggle Button
    flyToggleBtn = Instance.new("TextButton")
    flyToggleBtn.Text = "Fly: OFF"
    flyToggleBtn.Size = UDim2.new(0.7, 0, 0, 30)
    flyToggleBtn.Position = UDim2.new(0, 0, 0, 40)
    flyToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    flyToggleBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    flyToggleBtn.Parent = mainWindow

    flySettingsBtn = Instance.new("TextButton")
    flySettingsBtn.Text = "⚙"
    flySettingsBtn.Size = UDim2.new(0.3, 0, 0, 30)
    flySettingsBtn.Position = UDim2.new(0.7, 0, 0, 40)
    flySettingsBtn.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
    flySettingsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    flySettingsBtn.Parent = mainWindow

    flySettingsFrame = createSettingsFrame("Fly Settings")
    flySettingsFrame.Parent = screenGui

    speedInput = Instance.new("TextBox")
    speedInput.PlaceholderText = "Speed (Default: 50)"
    speedInput.Size = UDim2.new(1, -10, 0, 20)
    speedInput.Position = UDim2.new(0, 5, 0, 30)
    speedInput.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    speedInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    speedInput.Text = tostring(DEFAULT_SPEED)
    speedInput.Parent = flySettingsFrame

    -- No Clip Toggle Button
    noClipToggleBtn = Instance.new("TextButton")
    noClipToggleBtn.Text = "No Clip: OFF"
    noClipToggleBtn.Size = UDim2.new(0.7, 0, 0, 30)
    noClipToggleBtn.Position = UDim2.new(0, 0, 0, 80)
    noClipToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    noClipToggleBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    noClipToggleBtn.Parent = mainWindow

    -- Aimbot Toggle Button
    aimbotToggleBtn = Instance.new("TextButton")
    aimbotToggleBtn.Text = "Aimbot: OFF"
    aimbotToggleBtn.Size = UDim2.new(0.7, 0, 0, 30)
    aimbotToggleBtn.Position = UDim2.new(0, 0, 0, 120)
    aimbotToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    aimbotToggleBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    aimbotToggleBtn.Parent = mainWindow

    -- ESP Toggle Button
    espToggleBtn = Instance.new("TextButton")
    espToggleBtn.Text = "ESP: OFF"
    espToggleBtn.Size = UDim2.new(0.7, 0, 0, 30)
    espToggleBtn.Position = UDim2.new(0, 0, 0, 160)
    espToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    espToggleBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    espToggleBtn.Parent = mainWindow

    espSettingsBtn = Instance.new("TextButton")
    espSettingsBtn.Text = "⚙"
    espSettingsBtn.Size = UDim2.new(0.3, 0, 0, 30)
    espSettingsBtn.Position = UDim2.new(0.7, 0, 0, 160)
    espSettingsBtn.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
    espSettingsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    espSettingsBtn.Parent = mainWindow

    espSettingsFrame = createSettingsFrame("ESP Settings")
    espSettingsFrame.Parent = screenGui

    -- Teleport Menu Button
    teleportMenuBtn = Instance.new("TextButton")
    teleportMenuBtn.Text = "Teleport Menu"
    teleportMenuBtn.Size = UDim2.new(1, 0, 0, 30)
    teleportMenuBtn.Position = UDim2.new(0, 0, 0, 200)
    teleportMenuBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 120)
    teleportMenuBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    teleportMenuBtn.Parent = mainWindow

    teleportMenuFrame = createSettingsFrame("Teleport to Player")
    teleportMenuFrame.Parent = screenGui
    teleportMenuFrame.Active = true
    teleportMenuFrame.Draggable = true

    teleportMenuBtn.MouseButton1Click:Connect(function()
        updateTeleportMenu()
        teleportMenuFrame.Visible = true
    end)

    -- Player Menu Button
    playerMenuBtn = Instance.new("TextButton")
    playerMenuBtn.Text = "Player Menu"
    playerMenuBtn.Size = UDim2.new(1, 0, 0, 30)
    playerMenuBtn.Position = UDim2.new(0, 0, 0, 240)
    playerMenuBtn.BackgroundColor3 = Color3.fromRGB(80, 120, 80)
    playerMenuBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    playerMenuBtn.Parent = mainWindow

    playerMenuFrame = createSettingsFrame("Player Settings")
    playerMenuFrame.Size = UDim2.new(0, 200, 0, 230)
    playerMenuFrame.Parent = screenGui
    playerMenuFrame.Visible = false

    playerMenuBtn.MouseButton1Click:Connect(function()
        playerMenuFrame.Visible = true
    end)

    -- Collapse Button
    collapseBtn = Instance.new("TextButton")
    collapseBtn.Text = "-"
    collapseBtn.Size = UDim2.new(0, 20, 0, 15)
    collapseBtn.Position = UDim2.new(1, -20, 0, 0)
    collapseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    collapseBtn.BackgroundColor3 = Color3.fromRGB(120, 120, 120)
    collapseBtn.Parent = mainWindow

    collapseBtn.MouseButton1Click:Connect(function()
        local collapsed = mainWindow.Size.Y.Offset == 15
        if collapsed then
            mainWindow.Size = UDim2.new(0, 200, 0, 340)
        else
            mainWindow.Size = UDim2.new(0, 200, 0, 15)
        end
        for _, child in pairs(mainWindow:GetChildren()) do
            if child:IsA("GuiObject") and child ~= titleLabel and child ~= collapseBtn then
                child.Visible = collapsed
            end
        end
    end)

    -- Settings button handlers
    flySettingsBtn.MouseButton1Click:Connect(function()
        flySettingsFrame.Visible = true
    end)
    espSettingsBtn.MouseButton1Click:Connect(function()
        espSettingsFrame.Visible = true
    end)

    -- Unload Button
    unloadBtn = Instance.new("TextButton")
    unloadBtn.Text = "Unload"
    unloadBtn.Size = UDim2.new(1, 0, 0, 20)
    unloadBtn.Position = UDim2.new(0, 0, 1, -20)
    unloadBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
    unloadBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    unloadBtn.Parent = mainWindow

    unloadBtn.MouseButton1Click:Connect(function()
        FlyGUI.Unload()
    end)

    -- =========================
    -- Player Menu Content
    -- =========================
    local wsBox = Instance.new("TextBox")
    wsBox.PlaceholderText = "WalkSpeed"
    wsBox.Size = UDim2.new(1, -10, 0, 25)
    wsBox.Position = UDim2.new(0, 5, 0, 30)
    wsBox.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    wsBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    wsBox.Text = ""
    wsBox.Parent = playerMenuFrame

    local jpBox = Instance.new("TextBox")
    jpBox.PlaceholderText = "JumpPower"
    jpBox.Size = UDim2.new(1, -10, 0, 25)
    jpBox.Position = UDim2.new(0, 5, 0, 60)
    jpBox.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    jpBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    jpBox.Text = ""
    jpBox.Parent = playerMenuFrame

    local szBox = Instance.new("TextBox")
    szBox.PlaceholderText = "Size"
    szBox.Size = UDim2.new(1, -10, 0, 25)
    szBox.Position = UDim2.new(0, 5, 0, 90)
    szBox.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    szBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    szBox.Text = ""
    szBox.Parent = playerMenuFrame

    local applyBtn = Instance.new("TextButton")
    applyBtn.Text = "Apply"
    applyBtn.Size = UDim2.new(1, -10, 0, 25)
    applyBtn.Position = UDim2.new(0, 5, 0, 120)
    applyBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    applyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    applyBtn.Parent = playerMenuFrame

    applyBtn.MouseButton1Click:Connect(function()
        local char = player.Character
        if char and char:FindFirstChild("Humanoid") then
            local hum = char.Humanoid
            if tonumber(wsBox.Text) then hum.WalkSpeed = tonumber(wsBox.Text) end
            if tonumber(jpBox.Text) then hum.JumpPower = tonumber(jpBox.Text) end
            if tonumber(szBox.Text) then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.Size = Vector3.new(2,2,1) * tonumber(szBox.Text)
                    end
                end
            end
        end
    end)

    -- Voice Chat Bypass Button
    local vcBypassBtn = Instance.new("TextButton")
    vcBypassBtn.Text = "Bypass Voice Chat"
    vcBypassBtn.Size = UDim2.new(1, -10, 0, 25)
    vcBypassBtn.Position = UDim2.new(0, 5, 0, 155)
    vcBypassBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 120)
    vcBypassBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    vcBypassBtn.Parent = playerMenuFrame

    vcBypassBtn.MouseButton1Click:Connect(function()
        local success = false
        pcall(function()
            local VoiceChatService = game:GetService("VoiceChatService")
            if VoiceChatService then
                if getgenv then
                    getgenv().VoiceChatBypass = true
                end
                if hookfunction then
                    local old; old = hookfunction(VoiceChatService.IsVoiceEnabledForUserId, function(self, ...)
                        return true
                    end)
                    success = true
                end
            end
        end)
        if success then
            vcBypassBtn.Text = "Bypass Voice Chat (ON)"
        else
            vcBypassBtn.Text = "Bypass Voice Chat (FAILED)"
        end
        wait(2)
        vcBypassBtn.Text = "Bypass Voice Chat"
    end)

    -- Unsuspend VC Button
    local unsuspendBtn = Instance.new("TextButton")
    unsuspendBtn.Text = "Unsuspend VC"
    unsuspendBtn.Size = UDim2.new(1, -10, 0, 25)
    unsuspendBtn.Position = UDim2.new(0, 5, 0, 185)
    unsuspendBtn.BackgroundColor3 = Color3.fromRGB(120, 80, 80)
    unsuspendBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    unsuspendBtn.Parent = playerMenuFrame

    unsuspendBtn.MouseButton1Click:Connect(function()
        local success = false
        pcall(function()
            local VoiceChatService = game:GetService("VoiceChatService")
            if VoiceChatService then
                if hookfunction then
                    local old; old = hookfunction(VoiceChatService.IsVoiceSuspended, function(self, ...)
                        return false
                    end)
                    success = true
                end
            end
        end)
        if success then
            unsuspendBtn.Text = "Unsuspend VC (ON)"
        else
            unsuspendBtn.Text = "Unsuspend VC (FAILED)"
        end
        wait(2)
        unsuspendBtn.Text = "Unsuspend VC"
    end)

    -- Text Chat Bypass Button
    local chatBypassBtn = Instance.new("TextButton")
    chatBypassBtn.Text = "Bypass Text Chat"
    chatBypassBtn.Size = UDim2.new(1, -10, 0, 25)
    chatBypassBtn.Position = UDim2.new(0, 5, 0, 155)
    chatBypassBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 120)
    chatBypassBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    chatBypassBtn.Parent = playerMenuFrame

    chatBypassBtn.MouseButton1Click:Connect(function()
        local success = false
        pcall(function()
            -- Attempt to hook FilterStringAsync and FilterStringForBroadcast
            local ChatService = game:GetService("TextChatService") or game:GetService("Chat")
            if hookfunction and ChatService then
                if ChatService.FilterStringAsync then
                    local old; old = hookfunction(ChatService.FilterStringAsync, function(self, ...)
                        return ...
                    end)
                    success = true
                end
                if ChatService.FilterStringForBroadcast then
                    local old; old = hookfunction(ChatService.FilterStringForBroadcast, function(self, ...)
                        return ...
                    end)
                    success = true
                end
            end
        end)
        if success then
            chatBypassBtn.Text = "Bypass Text Chat (ON)"
        else
            chatBypassBtn.Text = "Bypass Text Chat (FAILED)"
        end
        wait(2)
        chatBypassBtn.Text = "Bypass Text Chat"
    end)
end

-- Teleport menu logic
function updateTeleportMenu()
    for _, child in ipairs(teleportMenuFrame:GetChildren()) do
        if child:IsA("TextButton") and child.Name ~= "Close" then
            child:Destroy()
        end
    end
    local players = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            table.insert(players, p)
        end
    end
    local btnHeight = 28
    local baseHeight = 30
    local totalHeight = baseHeight + #players * btnHeight
    teleportMenuFrame.Size = UDim2.new(0, 200, 0, math.max(80, totalHeight))

    local y = 30
    for _, p in ipairs(players) do
        local btn = Instance.new("TextButton")
        btn.Text = p.Name
        btn.Size = UDim2.new(1, -10, 0, 25)
        btn.Position = UDim2.new(0, 5, 0, y)
        btn.BackgroundColor3 = Color3.fromRGB(60, 60, 90)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Parent = teleportMenuFrame
        btn.MouseButton1Click:Connect(function()
            local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
            if hrp and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                player.Character.HumanoidRootPart.CFrame = hrp.CFrame + Vector3.new(0, 3, 0)
            end
        end)
        y = y + btnHeight
    end
end

-- Player menu logic
do
    local wsBox = Instance.new("TextBox")
    wsBox.PlaceholderText = "WalkSpeed"
    wsBox.Size = UDim2.new(1, -10, 0, 25)
    wsBox.Position = UDim2.new(0, 5, 0, 30)
    wsBox.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    wsBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    wsBox.Text = ""
    wsBox.Parent = playerMenuFrame

    local jpBox = Instance.new("TextBox")
    jpBox.PlaceholderText = "JumpPower"
    jpBox.Size = UDim2.new(1, -10, 0, 25)
    jpBox.Position = UDim2.new(0, 5, 0, 60)
    jpBox.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    jpBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    jpBox.Text = ""
    jpBox.Parent = playerMenuFrame

    local szBox = Instance.new("TextBox")
    szBox.PlaceholderText = "Size"
    szBox.Size = UDim2.new(1, -10, 0, 25)
    szBox.Position = UDim2.new(0, 5, 0, 90)
    szBox.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    szBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    szBox.Text = ""
    szBox.Parent = playerMenuFrame

    local applyBtn = Instance.new("TextButton")
    applyBtn.Text = "Apply"
    applyBtn.Size = UDim2.new(1, -10, 0, 25)
    applyBtn.Position = UDim2.new(0, 5, 0, 120)
    applyBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    applyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    applyBtn.Parent = playerMenuFrame

    applyBtn.MouseButton1Click:Connect(function()
        local char = player.Character
        if char and char:FindFirstChild("Humanoid") then
            local hum = char.Humanoid
            if tonumber(wsBox.Text) then hum.WalkSpeed = tonumber(wsBox.Text) end
            if tonumber(jpBox.Text) then hum.JumpPower = tonumber(jpBox.Text) end
            if tonumber(szBox.Text) then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.Size = Vector3.new(2,2,1) * tonumber(szBox.Text)
                    end
                end
            end
        end
    end)

    -- Voice Chat Bypass Button
    local vcBypassBtn = Instance.new("TextButton")
    vcBypassBtn.Text = "Bypass Voice Chat"
    vcBypassBtn.Size = UDim2.new(1, -10, 0, 25)
    vcBypassBtn.Position = UDim2.new(0, 5, 0, 155)
    vcBypassBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 120)
    vcBypassBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    vcBypassBtn.Parent = playerMenuFrame

    vcBypassBtn.MouseButton1Click:Connect(function()
        local success = false
        pcall(function()
            local VoiceChatService = game:GetService("VoiceChatService")
            if VoiceChatService then
                if getgenv then
                    getgenv().VoiceChatBypass = true
                end
                if hookfunction then
                    local old; old = hookfunction(VoiceChatService.IsVoiceEnabledForUserId, function(self, ...)
                        return true
                    end)
                    success = true
                end
            end
        end)
        if success then
            vcBypassBtn.Text = "Bypass Voice Chat (ON)"
        else
            vcBypassBtn.Text = "Bypass Voice Chat (FAILED)"
        end
        wait(2)
        vcBypassBtn.Text = "Bypass Voice Chat"
    end)

    -- Unsuspend VC Button
    local unsuspendBtn = Instance.new("TextButton")
    unsuspendBtn.Text = "Unsuspend VC"
    unsuspendBtn.Size = UDim2.new(1, -10, 0, 25)
    unsuspendBtn.Position = UDim2.new(0, 5, 0, 185)
    unsuspendBtn.BackgroundColor3 = Color3.fromRGB(120, 80, 80)
    unsuspendBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    unsuspendBtn.Parent = playerMenuFrame

    unsuspendBtn.MouseButton1Click:Connect(function()
        local success = false
        pcall(function()
            local VoiceChatService = game:GetService("VoiceChatService")
            if VoiceChatService then
                if hookfunction then
                    local old; old = hookfunction(VoiceChatService.IsVoiceSuspended, function(self, ...)
                        return false
                    end)
                    success = true
                end
            end
        end)
        if success then
            unsuspendBtn.Text = "Unsuspend VC (ON)"
        else
            unsuspendBtn.Text = "Unsuspend VC (FAILED)"
        end
        wait(2)
        unsuspendBtn.Text = "Unsuspend VC"
    end)

    -- Text Chat Bypass Button
    local chatBypassBtn = Instance.new("TextButton")
    chatBypassBtn.Text = "Bypass Text Chat"
    chatBypassBtn.Size = UDim2.new(1, -10, 0, 25)
    chatBypassBtn.Position = UDim2.new(0, 5, 0, 155)
    chatBypassBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 120)
    chatBypassBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    chatBypassBtn.Parent = playerMenuFrame

    chatBypassBtn.MouseButton1Click:Connect(function()
        local success = false
        pcall(function()
            -- Attempt to hook FilterStringAsync and FilterStringForBroadcast
            local ChatService = game:GetService("TextChatService") or game:GetService("Chat")
            if hookfunction and ChatService then
                if ChatService.FilterStringAsync then
                    local old; old = hookfunction(ChatService.FilterStringAsync, function(self, ...)
                        return ...
                    end)
                    success = true
                end
                if ChatService.FilterStringForBroadcast then
                    local old; old = hookfunction(ChatService.FilterStringForBroadcast, function(self, ...)
                        return ...
                    end)
                    success = true
                end
            end
        end)
        if success then
            chatBypassBtn.Text = "Bypass Text Chat (ON)"
        else
            chatBypassBtn.Text = "Bypass Text Chat (FAILED)"
        end
        wait(2)
        chatBypassBtn.Text = "Bypass Text Chat"
    end)
end

--================================================--
--                 FLIGHT SYSTEM
--================================================--
function FlyGUI.StartFlying()
    print("[FlyGUI] Starting flight...")
    local character = player.Character
    if not character then return end
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end

    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bodyVelocity.Parent = humanoidRootPart

    flyModeActive = true
    heartbeatConnection = RunService.Heartbeat:Connect(function()
        if not flyModeActive or not bodyVelocity then return end

        local moveDirection = Vector3.new()
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            moveDirection = moveDirection + camera.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            moveDirection = moveDirection - camera.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            moveDirection = moveDirection - camera.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            moveDirection = moveDirection + camera.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            moveDirection = moveDirection + Vector3.new(0, 1, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            moveDirection = moveDirection - Vector3.new(0, 1, 0)
        end

        local speed = tonumber(speedInput.Text) or DEFAULT_SPEED
        if moveDirection.Magnitude > 0 then
            bodyVelocity.Velocity = moveDirection.Unit * speed
        else
            bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        end
    end)
end

function FlyGUI.StopFlying()
    print("[FlyGUI] Stopping flight...")
    flyModeActive = false
    if bodyVelocity then
        bodyVelocity:Destroy()
        bodyVelocity = nil
    end
    if heartbeatConnection then
        heartbeatConnection:Disconnect()
        heartbeatConnection = nil
    end
end

--================================================--
--                  AIMBOT SYSTEM
--================================================--
local function findNearestPlayer()
    local nearest = nil
    local minDist = math.huge
    local myPos = player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character.HumanoidRootPart.Position
    if not myPos then return nil end

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            local root = p.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local dist = (myPos - root.Position).Magnitude
                if dist < minDist then
                    minDist = dist
                    nearest = p
                end
            end
        end
    end
    return nearest
end

local function aimAtNearest()
    local target = findNearestPlayer()
    if target and target.Character then
        local root = target.Character:FindFirstChild("HumanoidRootPart")
        if root then
            camera.CFrame = CFrame.lookAt(camera.CFrame.Position, root.Position)
        end
    end
end

local aimbotConnection
local function startAimbot()
    if aimbotConnection then return end
    aimbotConnection = RunService.RenderStepped:Connect(function()
        if aimbotEnabled then
            aimAtNearest()
        end
    end)
end

local function stopAimbot()
    if aimbotConnection then
        aimbotConnection:Disconnect()
        aimbotConnection = nil
    end
end

local function setNoClip(state)
    if state then
        noClipConnection = RunService.Stepped:Connect(function()
            local char = player.Character
            if not char then return end
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end)
    else
        if noClipConnection then
            noClipConnection:Disconnect()
            noClipConnection = nil
        end
        -- Reset collisions if desired (optional)
        local char = player.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end
    noClipEnabled = state
end


--================================================--
--                WEAPON SYSTEM
--================================================--
function giveWeapon(weaponName)
    print("[FlyGUI] Granting weapon: " .. weaponName)
    if game.PlaceId == 1224212277 then -- Example: Mad City
        local backpack = player:FindFirstChild("Backpack")
        local replicated = game:GetService("ReplicatedStorage")
        local weapon = replicated:FindFirstChild(weaponName)
        if backpack and weapon then
            local clone = weapon:Clone()
            clone.Parent = backpack
        end
    end
end

--================================================--
--              INPUT HANDLING & KEYBINDS
--================================================--
local function onInputBegan(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == KEYBIN_FLY_TOGGLE then
        flying = not flying
        flyToggleBtn.Text = flying and "Fly: ON" or "Fly: OFF"
        if flying then
            FlyGUI.StartFlying()
        else
            FlyGUI.StopFlying()
        end

    elseif input.KeyCode == KEYBIN_NOCLIP_TOGGLE then
        local newState = not noClipEnabled
        setNoClip(newState)
        noClipToggleBtn.Text = newState and "No Clip: ON" or "No Clip: OFF"

    elseif input.KeyCode == KEYBIN_AIMBOT_TOGGLE then
        aimbotEnabled = not aimbotEnabled
        aimbotToggleBtn.Text = aimbotEnabled and "Aimbot: ON" or "Aimbot: OFF"
        if aimbotEnabled then
            startAimbot()
        else
            stopAimbot()
        end

    elseif input.KeyCode == KEYBIN_ESP_TOGGLE then
        if espEnabled then
            disableESP()
            espToggleBtn.Text = "ESP: OFF"
        else
            enableESP()
            espToggleBtn.Text = "ESP: ON"
        end
    end
end

UserInputService.InputBegan:Connect(onInputBegan)

--================================================--
--                   BUTTON HANDLERS
--================================================--
function FlyGUI.Init()
    print("[FlyGUI] Initializing...")
    FlyGUI.CreateGUI()

    flyToggleBtn.MouseButton1Click:Connect(function()
        flying = not flying
        flyToggleBtn.Text = flying and "Fly: ON" or "Fly: OFF"
        if flying then
            FlyGUI.StartFlying()
        else
            FlyGUI.StopFlying()
        end
    end)
    
    noClipToggleBtn.MouseButton1Click:Connect(function()
        local newState = not noClipEnabled
        setNoClip(newState)
        noClipToggleBtn.Text = newState and "No Clip: ON" or "No Clip: OFF"
    end)

    aimbotToggleBtn.MouseButton1Click:Connect(function()
        aimbotEnabled = not aimbotEnabled
        aimbotToggleBtn.Text = aimbotEnabled and "Aimbot: ON" or "Aimbot: OFF"
        if aimbotEnabled then
            startAimbot()
        else
            stopAimbot()
        end
    end)

    espToggleBtn.MouseButton1Click:Connect(function()
        if espEnabled then
            disableESP()
            espToggleBtn.Text = "ESP: OFF"
        else
            enableESP()
            espToggleBtn.Text = "ESP: ON"
        end
    end)

    unloadBtn.MouseButton1Click:Connect(function()
        FlyGUI.Unload()
    end)
end

--================================================--
--                  CLEANUP
--================================================--
local function cleanUp()
    print("[FlyGUI] Cleaning up...")
    if bodyVelocity then
        bodyVelocity:Destroy()
    end
    if heartbeatConnection then
        heartbeatConnection:Disconnect()
    end
    stopAimbot()
    ContextActionService:UnbindAction("Aimbot")
    disableESP()
end

player.CharacterRemoving:Connect(cleanUp)

--================================================--
--                SCRIPT START
--================================================--
if not game:IsLoaded() then
    game.Loaded:Wait()
end
if not player.Character or not player.Character.Parent then
    player.CharacterAdded:Wait()
end

print("[FlyGUI] Calling FlyGUI.Init()...")
FlyGUI.Init()

return FlyGUI
