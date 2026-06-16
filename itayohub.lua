-- itayoHub v2.1 — Delta Executor Compatible (ScreenGui-based)
-- By Hermes Agent for itayohub
-- https://github.com/itayohub/itayohub

-- Error wrapper — kalo ada error, output ke console biar keliatan
local function safe(fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then
        warn("itayoHub ERROR: " .. tostring(err))
    end
    return ok, err
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local lp = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- ===== STATE =====
local state = {
    open = false,
    toggles = {},
    sliders = { WalkSpeed = 50, JumpPower = 50 },
}

-- ===== CHEAT VARIABLES =====
local flyBodyVelocity = nil
local flyBodyGyro = nil
local infiniteJumpHook = nil
local noclipConnection = nil
local espLoopConnection = nil

-- ====================================================================
-- UI BUILDER — ScreenGui + Frame (gak pake Drawing, universal)
-- ====================================================================

local gui = Instance.new("ScreenGui")
gui.Name = "itayoHub"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local function make(class, props)
    local obj = Instance.new(class)
    for k, v in pairs(props) do
        obj[k] = v
    end
    return obj
end

-- === MAIN FRAME ===
local main = make("Frame", {
    Name = "Main",
    Parent = gui,
    Position = UDim2.new(0.02, 0, 0.2, 0),
    Size = UDim2.new(0, 320, 0, 420),
    BackgroundColor3 = Color3.fromRGB(18, 18, 22),
    BorderSizePixel = 0,
    Active = true,
    Draggable = true,
})

-- Shadow
make("Frame", {
    Parent = main,
    Position = UDim2.new(0, 4, 0, 4),
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundColor3 = Color3.fromRGB(0, 0, 0),
    BackgroundTransparency = 0.75,
    BorderSizePixel = 0,
    ZIndex = 0,
})

-- Accent bar top
make("Frame", {
    Parent = main,
    Size = UDim2.new(1, 0, 0, 2),
    BackgroundColor3 = Color3.fromRGB(0, 200, 180),
    BorderSizePixel = 0,
})

-- Header
local header = make("Frame", {
    Parent = main,
    Position = UDim2.new(0, 0, 0, 2),
    Size = UDim2.new(1, 0, 0, 42),
    BackgroundColor3 = Color3.fromRGB(12, 12, 16),
    BorderSizePixel = 0,
})

make("TextLabel", {
    Parent = header,
    Position = UDim2.new(0, 12, 0, 6),
    Size = UDim2.new(0, 200, 0, 20),
    BackgroundTransparency = 1,
    Text = "itayoHub v2.1",
    TextColor3 = Color3.fromRGB(0, 200, 180),
    TextXAlignment = Enum.TextXAlignment.Left,
    Font = Enum.Font.GothamBold,
    TextSize = 15,
})

make("TextLabel", {
    Parent = header,
    Position = UDim2.new(0, 12, 0, 26),
    Size = UDim2.new(0, 200, 0, 14),
    BackgroundTransparency = 1,
    Text = "Delta Executor",
    TextColor3 = Color3.fromRGB(140, 140, 155),
    TextXAlignment = Enum.TextXAlignment.Left,
    Font = Enum.Font.Gotham,
    TextSize = 10,
})

-- Close button
local closeBtn = make("TextButton", {
    Parent = header,
    Position = UDim2.new(1, -36, 0, 6),
    Size = UDim2.new(0, 30, 0, 30),
    BackgroundTransparency = 1,
    Text = "X",
    TextColor3 = Color3.fromRGB(200, 80, 80),
    TextSize = 16,
    Font = Enum.Font.GothamBold,
    BorderSizePixel = 0,
})

-- Tabs
local tabBar = make("Frame", {
    Parent = main,
    Position = UDim2.new(0, 0, 0, 44),
    Size = UDim2.new(1, 0, 0, 32),
    BackgroundColor3 = Color3.fromRGB(18, 18, 22),
    BorderSizePixel = 0,
})

make("Frame", {
    Parent = tabBar,
    Position = UDim2.new(0, 10, 1, 0),
    Size = UDim2.new(1, -20, 0, 1),
    BackgroundColor3 = Color3.fromRGB(38, 38, 46),
    BorderSizePixel = 0,
})

local tabs = {"Player", "Visuals", "Settings"}
local tabButtons = {}
local tabIndicator = make("Frame", {
    Parent = tabBar,
    Size = UDim2.new(0, 80, 0, 2),
    Position = UDim2.new(0, 10, 1, -2),
    BackgroundColor3 = Color3.fromRGB(0, 200, 180),
    BorderSizePixel = 0,
})

-- Content container
local content = make("Frame", {
    Parent = main,
    Position = UDim2.new(0, 0, 0, 76),
    Size = UDim2.new(1, 0, 1, -76),
    BackgroundColor3 = Color3.fromRGB(18, 18, 22),
    BorderSizePixel = 0,
})

-- ===== SCROLLING FRAME (biar muat banyak toggle) =====
local scrollingFrame = make("ScrollingFrame", {
    Parent = content,
    Position = UDim2.new(0, 10, 0, 6),
    Size = UDim2.new(1, -20, 1, -10),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = Color3.fromRGB(38, 38, 46),
    CanvasSize = UDim2.new(0, 0, 0, 0),
})

-- ===== UI HELPERS =====
local function makeSection(title, y)
    local label = make("TextLabel", {
        Parent = scrollingFrame,
        Position = UDim2.new(0, 0, 0, y),
        Size = UDim2.new(1, 0, 0, 14),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = Color3.fromRGB(0, 160, 145),
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.GothamBold,
        TextSize = 11,
    })
    make("Frame", {
        Parent = scrollingFrame,
        Position = UDim2.new(0, 0, 0, y + 16),
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = Color3.fromRGB(38, 38, 46),
        BorderSizePixel = 0,
    })
    return y + 24
end

local function makeToggle(label, default, y)
    local bg = make("Frame", {
        Parent = scrollingFrame,
        Position = UDim2.new(0, 0, 0, y),
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = Color3.fromRGB(26, 26, 32),
        BorderSizePixel = 0,
    })
    -- Pilihan keluar
    local labelWidget = make("TextLabel", {
        Parent = bg,
        Position = UDim2.new(0, 10, 0, 6),
        Size = UDim2.new(1, -56, 1, -12),
        BackgroundTransparency = 1,
        Text = label,
        TextColor3 = Color3.fromRGB(200, 200, 210),
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.Gotham,
        TextSize = 13,
    })
    -- Toggle track
    local trackW, trackH = 36, 18
    local track = make("Frame", {
        Parent = bg,
        Position = UDim2.new(1, -46, 0, 6),
        Size = UDim2.new(0, trackW, 0, trackH),
        BackgroundColor3 = Color3.fromRGB(60, 60, 68),
        BorderSizePixel = 0,
    })
    local knobSize = trackH - 4
    local knob = make("Frame", {
        Parent = bg,
        Position = UDim2.new(1, -46 + 2, 0, 8),
        Size = UDim2.new(0, knobSize, 0, knobSize),
        BackgroundColor3 = Color3.fromRGB(200, 200, 200),
        BorderSizePixel = 0,
    })
    -- Init state
    if state.toggles[label] == nil then
        state.toggles[label] = default
    end
    local function updateToggle()
        local on = state.toggles[label]
        track.BackgroundColor3 = on and Color3.fromRGB(0, 200, 180) or Color3.fromRGB(60, 60, 68)
        knob.Position = on and UDim2.new(1, -46 + trackW - knobSize - 2, 0, 8) or UDim2.new(1, -46 + 2, 0, 8)
    end
    updateToggle()
    local btn = make("TextButton", {
        Parent = bg,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        BorderSizePixel = 0,
    })
    btn.MouseButton1Click:Connect(function()
        state.toggles[label] = not state.toggles[label]
        updateToggle()
    end)
    return y + 32
end

local function makeSlider(label, minv, maxv, default, y)
    local bg = make("Frame", {
        Parent = scrollingFrame,
        Position = UDim2.new(0, 0, 0, y),
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundColor3 = Color3.fromRGB(26, 26, 32),
        BorderSizePixel = 0,
    })
    make("TextLabel", {
        Parent = bg,
        Position = UDim2.new(0, 10, 0, 4),
        Size = UDim2.new(0, 200, 0, 14),
        BackgroundTransparency = 1,
        Text = label,
        TextColor3 = Color3.fromRGB(200, 200, 210),
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.Gotham,
        TextSize = 12,
    })
    local valLabel = make("TextLabel", {
        Parent = bg,
        Position = UDim2.new(1, -50, 0, 4),
        Size = UDim2.new(0, 40, 0, 14),
        BackgroundTransparency = 1,
        Text = tostring(default),
        TextColor3 = Color3.fromRGB(0, 200, 180),
        TextXAlignment = Enum.TextXAlignment.Right,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
    })
    local barBg = make("Frame", {
        Parent = bg,
        Position = UDim2.new(0, 10, 0, 24),
        Size = UDim2.new(1, -46, 0, 4),
        BackgroundColor3 = Color3.fromRGB(60, 60, 68),
        BorderSizePixel = 0,
    })
    local barFill = make("Frame", {
        Parent = bg,
        Position = UDim2.new(0, 10, 0, 24),
        Size = UDim2.new(0, 0, 0, 4),
        BackgroundColor3 = Color3.fromRGB(0, 200, 180),
        BorderSizePixel = 0,
    })
    state.sliders[label] = default
    
    local function updateSlider(val)
        val = math.clamp(val, minv, maxv)
        state.sliders[label] = val
        local pct = (val - minv) / (maxv - minv)
        barFill.Size = UDim2.new(pct, 0, 0, 4)
        local d = math.floor(val * 10) / 10
        valLabel.Text = tostring(d)
    end
    updateSlider(default)
    
    -- Draggable slider
    local dragBtn = make("TextButton", {
        Parent = bg,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        BorderSizePixel = 0,
    })
    local dragging = false
    dragBtn.MouseButton1Down:Connect(function()
        dragging = true
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    RunService.RenderStepped:Connect(function()
        if dragging then
            local mousePos = UserInputService:GetMouseLocation()
            local absX = barBg.AbsolutePosition.X
            local absW = barBg.AbsoluteSize.X
            local relX = math.clamp(mousePos.X - absX, 0, absW)
            local val = minv + (relX / absW) * (maxv - minv)
            updateSlider(val)
        end
    end)
    return y + 40
end

-- ===== BUILD TABS ====
local function rebuildUI()
    -- Hapus isi scrollingFrame
    for _, child in ipairs(scrollingFrame:GetChildren()) do
        child:Destroy()
    end

    local y = 4

    if state.currentTab == "Player" then
        y = makeSection("MOVEMENT", y)
        y = makeToggle("Speed", false, y)
        y = makeToggle("Fly", false, y)
        y = makeToggle("Infinite Jump", false, y)
        y = makeToggle("Noclip", false, y)
        y = makeSection("CHARACTER", y + 4)
        y = makeSlider("WalkSpeed", 16, 200, 50, y)
        y = makeSlider("JumpPower", 50, 350, 50, y)
    elseif state.currentTab == "Visuals" then
        y = makeSection("ESP", y)
        y = makeToggle("Box ESP", true, y)
        y = makeToggle("Tracers", false, y)
        y = makeToggle("Health Bar", true, y)
        y = makeToggle("Name Tag", true, y)
        y = makeToggle("Chams", false, y)
        y = makeSection("MISC", y + 4)
        y = makeToggle("Crosshair", true, y)
    elseif state.currentTab == "Settings" then
        y = makeSection("ABOUT", y)
        local about = make("TextLabel", {
            Parent = scrollingFrame,
            Position = UDim2.new(0, 6, 0, y),
            Size = UDim2.new(1, -12, 0, 60),
            BackgroundTransparency = 1,
            Text = "itayoHub v2.1\nDelta Executor Compatible\nBuilt with Lua by Hermes Agent",
            TextColor3 = Color3.fromRGB(140, 140, 155),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            LineHeight = 1.6,
        })
        y = y + 68
        y = makeSection("TOGGLES", y)
        y = makeToggle("Auto Execute", false, y)
        y = makeToggle("Show FPS", false, y)
    end

    -- Update canvas size
    scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, y + 10)
end

-- Tab switching
local function switchTab(name)
    state.currentTab = name
    for i, tab in ipairs(tabs) do
        local btn = tabButtons[i]
        if tab == name then
            btn.TextColor3 = Color3.fromRGB(0, 200, 180)
            tabIndicator:TweenPosition(UDim2.new(0, 10 + (i-1) * 100, 1, -2), "Out", "Quad", 0.15, true)
        else
            btn.TextColor3 = Color3.fromRGB(140, 140, 155)
        end
    end
    rebuildUI()
end

-- Build tab buttons
for i, name in ipairs(tabs) do
    local btn = make("TextButton", {
        Parent = tabBar,
        Position = UDim2.new(0, 10 + (i-1) * 100, 0, 4),
        Size = UDim2.new(0, 90, 0, 26),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = Color3.fromRGB(140, 140, 155),
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        BorderSizePixel = 0,
    })
    btn.MouseButton1Click:Connect(function() switchTab(name) end)
    tabButtons[i] = btn
end

-- Close handler
closeBtn.MouseButton1Click:Connect(function()
    state.open = false
    gui:Destroy()
end)

-- Init first tab
state.currentTab = "Player"
switchTab("Player")

-- ====================================================================
-- CHEAT FUNCTIONS
-- ====================================================================

local function speedLoop()
    local humanoid = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = state.toggles["Speed"] and state.sliders.WalkSpeed or 16
    end
end

-- Fly
local function toggleFly(on)
    local char = lp.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    if on then
        if not flyBodyVelocity then
            flyBodyVelocity = Instance.new("BodyVelocity")
            flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
            flyBodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
            flyBodyVelocity.P = 2000
            flyBodyVelocity.Parent = root
            flyBodyGyro = Instance.new("BodyGyro")
            flyBodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
            flyBodyGyro.P = 2000
            flyBodyGyro.D = 500
            flyBodyGyro.Parent = root
        end
    else
        if flyBodyVelocity then flyBodyVelocity:Destroy(); flyBodyVelocity = nil end
        if flyBodyGyro then flyBodyGyro:Destroy(); flyBodyGyro = nil end
    end
end

local function updateFly()
    if not state.toggles["Fly"] then return end
    if not flyBodyVelocity then toggleFly(true) end
    local root = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local moveDir = Vector3.new(0, 0, 0)
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + camera.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - camera.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - camera.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + camera.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3.new(0, 1, 0) end
    if moveDir.Magnitude > 0 then
        flyBodyVelocity.Velocity = moveDir.Unit * 50
    else
        flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
    end
    flyBodyGyro.CFrame = camera.CFrame
end

-- Infinite Jump
local function toggleInfiniteJump(on)
    if on then
        infiniteJumpHook = UserInputService.JumpRequest:Connect(function()
            local char = lp.Character
            if char then
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if humanoid then humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
            end
        end)
    else
        if infiniteJumpHook then infiniteJumpHook:Disconnect(); infiniteJumpHook = nil end
    end
end

-- Noclip
local function noclipLoop()
    local char = lp.Character
    if not char then return end
    for _, part in ipairs(char:GetChildren()) do
        if part:IsA("BasePart") then
            part.CanCollide = not state.toggles["Noclip"]
        end
    end
end

-- Crosshair (Drawing fallback — minimal)
local crosshairObjs = {}
local function updateCrosshair()
    if not state.toggles["Crosshair"] then
        for _, o in pairs(crosshairObjs) do
            pcall(function() o:Remove() end)
        end
        crosshairObjs = {}
        return
    end
    if #crosshairObjs == 0 then
        local ok, d1 = pcall(Drawing.new, "Line")
        local ok2, d2 = pcall(Drawing.new, "Line")
        if ok and ok2 then
            d1.Thickness = 1.5; d1.Color = Color3.new(1,1,1)
            d2.Thickness = 1.5; d2.Color = Color3.new(1,1,1)
            crosshairObjs = {d1, d2}
        else
            return -- Drawing gak available
        end
    end
    local cx, cy = camera.ViewSizeX / 2, camera.ViewSizeY / 2
    crosshairObjs[1].From = Vector2.new(cx - 10, cy)
    crosshairObjs[1].To = Vector2.new(cx + 10, cy)
    crosshairObjs[2].From = Vector2.new(cx, cy - 10)
    crosshairObjs[2].To = Vector2.new(cx, cy + 10)
end

-- ESP
local function worldToScreen(pos)
    local vec, onScreen = camera:WorldToScreenPoint(pos)
    return Vector2.new(vec.X, vec.Y), onScreen
end

local function updateESP()
    if not (state.toggles["Box ESP"] or state.toggles["Tracers"] or state.toggles["Health Bar"] or state.toggles["Name Tag"]) then
        return
    end
    local espColor = Color3.fromRGB(0, 200, 255)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= lp then
            local char = player.Character
            if char then
                local root = char:FindFirstChild("HumanoidRootPart")
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if root and humanoid then
                    local head = char:FindFirstChild("Head") or root
                    local pos, onScreen = worldToScreen(root.Position)
                    local headPos, _ = worldToScreen(head.Position + Vector3.new(0, 2, 0))
                    if onScreen then
                        local scale = (root.Position - camera.CFrame.Position).Magnitude
                        local boxH = math.clamp(18000 / scale, 20, 150)
                        local boxW = boxH * 0.6
                    end
                end
            end
        end
    end
end

-- ====================================================================
-- MAIN LOOP
-- ====================================================================

RunService.RenderStepped:Connect(function()
    safe(function()
        -- Speed
        speedLoop()
        -- Fly
        if state.toggles["Fly"] then
            updateFly()
        elseif flyBodyVelocity then
            toggleFly(false)
        end
        -- Noclip
        noclipLoop()
        -- Infinite Jump
        if state.toggles["Infinite Jump"] and not infiniteJumpHook then
            toggleInfiniteJump(true)
        elseif not state.toggles["Infinite Jump"] and infiniteJumpHook then
            toggleInfiniteJump(false)
        end
        -- Crosshair
        updateCrosshair()
    end)
end)

-- Cleanup on teleport
lp.OnTeleport:Connect(function()
    if gui then gui:Destroy() end
    toggleFly(false)
    toggleInfiniteJump(false)
    for _, o in pairs(crosshairObjs) do pcall(function() o:Remove() end); end
end)

print("itayoHub v2.1 loaded — Delta Compatible")
print("Tabs: Player | Visuals | Settings")
