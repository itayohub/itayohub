-- itayoHub v2.0 — Delta Executor Compatible
-- By Hermes Agent for itayohub
-- Repository: https://github.com/itayohub/itayohub

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local lp = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- ===== COLOR PALETTE =====
local C = {
    bg        = Color3.fromRGB(18, 18, 22),
    surface   = Color3.fromRGB(26, 26, 32),
    border    = Color3.fromRGB(38, 38, 46),
    text      = Color3.fromRGB(230, 230, 240),
    textDim   = Color3.fromRGB(140, 140, 155),
    accent    = Color3.fromRGB(0, 200, 180),
    accentDim = Color3.fromRGB(0, 160, 145),
    success   = Color3.fromRGB(0, 200, 150),
    danger    = Color3.fromRGB(230, 80, 80),
    warn      = Color3.fromRGB(255, 190, 50),
    card      = Color3.fromRGB(32, 32, 40),
    cream     = Color3.fromRGB(235, 231, 226),
    espRed    = Color3.fromRGB(255, 80, 80),
    espOrange = Color3.fromRGB(255, 200, 60),
    espGreen  = Color3.fromRGB(60, 230, 120),
    espCyan   = Color3.fromRGB(60, 200, 255),
    espPurple = Color3.fromRGB(180, 100, 255),
}

-- ===== STATE =====
local state = {
    pos    = Vector2.new(50, 50),
    size   = Vector2.new(400, 500),
    tab    = "Player",
    drag   = { active = false, offset = Vector2.new(0, 0) },
    visible = true,
    toggles = {},
    sliders = { WalkSpeed = 50, JumpPower = 50, Smoothness = 0.5 },
    colorIdx = 1,
}

local tabs = {"Player", "Visuals", "Settings"}

-- ===== ESP COLOR =====
local ESP_COLORS = {C.espRed, C.espOrange, C.espGreen, C.espCyan, C.espPurple}

-- ===== DRAW POOL =====
local pool = {}
local esp_objects = {}

local function alloc(...)
    for _, o in ipairs({...}) do
        table.insert(pool, o)
    end
end

local function flush()
    for _, o in ipairs(pool) do
        pcall(function() o:Remove() end)
    end
    pool = {}
end

local function flush_esp()
    for _, tbl in pairs(esp_objects) do
        for _, o in pairs(tbl) do
            pcall(function() o:Remove() end)
        end
    end
    esp_objects = {}
end

local function flush_all()
    flush()
    flush_esp()
end

-- ===== DRAWING HELPERS =====
local function r(pos, size, color, alpha, thickness)
    local sq = Drawing.new("Square")
    sq.Position = Vector2.new(pos.X, pos.Y)
    sq.Size = Vector2.new(size.X, size.Y)
    sq.Color = color or C.bg
    sq.Transparency = alpha or 1
    sq.Filled = thickness == nil
    if thickness then sq.Thickness = thickness; sq.Filled = false end
    return sq
end

local function t(pos, text, size, color, center)
    local tx = Drawing.new("Text")
    tx.Position = Vector2.new(pos.X, pos.Y)
    tx.Text = text
    tx.Size = size or 14
    tx.Color = color or C.text
    tx.Center = center or false
    tx.Outline = false
    return tx
end

local function l(from, to, color, thickness)
    local ln = Drawing.new("Line")
    ln.From = Vector2.new(from.X, from.Y)
    ln.To = Vector2.new(to.X, to.Y)
    ln.Color = color or C.border
    ln.Thickness = thickness or 1
    return ln
end

-- ===== LOGO =====
local LOGO = {
    "itayoHub", "Modern Executor", "Roblox"
}

-- ===== UI: WINDOW =====
local function drawWindow()
    local p, s = state.pos, state.size
    alloc(r(p + Vector2.new(4,4), s, Color3.new(0,0,0), 0.25))
    alloc(r(p, s, C.surface, 0.95))
    alloc(r(p, Vector2.new(s.X, 2), C.accent, 1))
    alloc(r(p + Vector2.new(0, 2), Vector2.new(s.X, 48), C.bg, 0.6))
    alloc(t(p + Vector2.new(14, 16), "itayoHub v2.0", 13, C.accent))
    alloc(t(p + Vector2.new(14, 32), "Delta Compatible", 9, C.textDim))
    alloc(t(p + Vector2.new(s.X - 20, 16), "X", 14, C.textDim, true))
    alloc(l(p + Vector2.new(0, 50), p + Vector2.new(s.X, 50), C.border))
end

-- ===== UI: TABS =====
local function drawTabs()
    local p, s = state.pos, state.size
    local tabY = p.Y + 52
    local tabW = math.floor((s.X - 20) / #tabs)
    for i = 1, #tabs do
        local name = tabs[i]
        local x = p.X + 10 + (i-1) * tabW
        local act = name == state.tab
        if act then alloc(r(Vector2.new(x+4, tabY+26), Vector2.new(tabW-8, 2), C.accent, 1)) end
        alloc(t(Vector2.new(x + tabW/2, tabY + 7), name, 13, act and C.accent or C.textDim, true))
    end
    alloc(l(p + Vector2.new(10, tabY+28), p + Vector2.new(s.X-10, tabY+28), C.border))
end

-- ===== UI: TOGGLE =====
local function drawToggle(idx, label, default)
    local p = state.pos
    local x = p.X + 16
    local y = p.Y + 96 + (idx-1) * 34
    local on = state.toggles[label]
    if on == nil then on = default; state.toggles[label] = default end
    local tw, th = 34, 18
    alloc(r(Vector2.new(x, y+2), Vector2.new(tw, th), on and C.accent or C.border, 0.8))
    local kx = on and (x + tw - th + 2) or (x + 2)
    alloc(r(Vector2.new(kx, y+4), Vector2.new(th-4, th-4), Color3.new(1,1,1), 1))
    alloc(t(Vector2.new(x + tw + 12, y+1), label, 13, on and C.text or C.textDim))
end

-- ===== UI: SLIDER =====
local function drawSlider(idx, label, val, minv, maxv)
    local p = state.pos
    local x = p.X + 16
    local y = p.Y + 96 + (idx-1) * 34 + 140
    local pct = (val - minv) / (maxv - minv)
    local disp = label == "Smoothness" and string.format("%.2f", val) or tostring(math.floor(val))
    alloc(t(Vector2.new(x, y), label, 12, C.text))
    alloc(t(Vector2.new(x + 240, y), disp, 12, C.accent))
    alloc(r(Vector2.new(x, y+18), Vector2.new(280, 4), C.border, 0.6))
    local fw = math.max(pct * 280, 0)
    if fw > 0 then alloc(r(Vector2.new(x, y+18), Vector2.new(fw, 4), C.accent, 0.8)) end
    alloc(r(Vector2.new(x + fw - 5, y+14), Vector2.new(10, 12), C.accent, 1))
end

-- ===== UI: COLOR STRIP =====
local function drawColorStrip(y)
    local p = state.pos
    local x = p.X + 16
    alloc(t(Vector2.new(x, y), "ESP Color", 12, C.text))
    local sw = math.floor(280 / 5)
    local rainbow = {C.espRed, C.espOrange, C.espGreen, C.espCyan, C.espPurple}
    for i = 1, 5 do
        local col = rainbow[i]
        alloc(r(Vector2.new(x+(i-1)*sw, y+16), Vector2.new(sw+1, 16), col, 0.9))
        if i == state.colorIdx then
            alloc(r(Vector2.new(x+(i-1)*sw-1, y+15), Vector2.new(sw+3, 18), Color3.new(1,1,1), 1, 2))
        end
    end
end

-- ===== UI: SECTION =====
local function drawSection(y, title)
    local p = state.pos
    alloc(t(Vector2.new(p.X+16, y), title, 11, C.accentDim))
    alloc(l(p + Vector2.new(16, y+16), p + Vector2.new(state.size.X-16, y+16), C.border))
end

-- ===== UI: PROFILE CARD =====
local function drawProfileCard(y)
    local p, s = state.pos, state.size
    alloc(r(Vector2.new(p.X+16, y), Vector2.new(s.X-32, 72), C.card, 0.8))
    alloc(r(Vector2.new(p.X+28, y+10), Vector2.new(50, 50), C.accent, 0.9))
    local uname = lp.Name
    alloc(t(Vector2.new(p.X+53, y+28), uname:sub(1,1):upper(), 22, Color3.new(1,1,1), true))
    alloc(t(Vector2.new(p.X+90, y+14), uname, 16, C.text))
    local dname = lp.DisplayName
    if dname ~= uname then alloc(t(Vector2.new(p.X+90, y+34), dname, 11, C.textDim)) end
    alloc(t(Vector2.new(p.X+90, y+50), "ID: " .. lp.UserId, 10, C.textDim))
end

-- ====================================================================
-- CHEAT FUNCTIONS
-- ====================================================================

local cheats = {
    connections = {},
}

-- ---- SPEED ----
local function speedLoop()
    local humanoid = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = state.toggles["Speed"] and state.sliders.WalkSpeed or 16
    end
end

-- ---- FLY ----
local flyBodyVelocity = nil
local flyBodyGyro = nil

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
        if flyBodyVelocity then
            flyBodyVelocity:Destroy()
            flyBodyVelocity = nil
        end
        if flyBodyGyro then
            flyBodyGyro:Destroy()
            flyBodyGyro = nil
        end
    end
end

local function updateFly()
    if not state.toggles["Fly"] then return end
    if not flyBodyVelocity then toggleFly(true) end
    local root = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local moveDir = Vector3.new(0, 0, 0)
    if UIS:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + camera.CFrame.LookVector end
    if UIS:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - camera.CFrame.LookVector end
    if UIS:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - camera.CFrame.RightVector end
    if UIS:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + camera.CFrame.RightVector end
    if UIS:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
    if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3.new(0, 1, 0) end

    if moveDir.Magnitude > 0 then
        moveDir = moveDir.Unit * 50
        flyBodyVelocity.Velocity = moveDir
    else
        flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
    end
    flyBodyGyro.CFrame = camera.CFrame
end

-- ---- INFINITE JUMP ----
local infiniteJumpHook = nil

local function toggleInfiniteJump(on)
    if on then
        infiniteJumpHook = UIS.JumpRequest:Connect(function()
            local char = lp.Character
            if char then
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
        end)
    else
        if infiniteJumpHook then
            infiniteJumpHook:Disconnect()
            infiniteJumpHook = nil
        end
    end
end

-- ---- NOCLIP ----
local function noclipLoop()
    local char = lp.Character
    if not char then return end
    for _, part in ipairs(char:GetChildren()) do
        if part:IsA("BasePart") then
            part.CanCollide = not state.toggles["Noclip"]
        end
    end
end

-- ---- CROSSHAIR ----
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
        local cx = camera.ViewSizeX / 2
        local cy = camera.ViewSizeY / 2
        crosshairObjs = {
            l(Vector2.new(cx - 10, cy), Vector2.new(cx + 10, cy), Color3.new(1,1,1), 1.5),
            l(Vector2.new(cx, cy - 10), Vector2.new(cx, cy + 10), Color3.new(1,1,1), 1.5),
        }
    end
    local cx, cy = camera.ViewSizeX / 2, camera.ViewSizeY / 2
    crosshairObjs[1].From = Vector2.new(cx - 10, cy)
    crosshairObjs[1].To = Vector2.new(cx + 10, cy)
    crosshairObjs[2].From = Vector2.new(cx, cy - 10)
    crosshairObjs[2].To = Vector2.new(cx, cy + 10)
end

-- ---- ESP ----
local function worldToScreen(pos)
    local vec, onScreen = camera:WorldToScreenPoint(pos)
    return Vector2.new(vec.X, vec.Y), onScreen
end

local function getPlayerColor()
    return ESP_COLORS[state.colorIdx] or C.espCyan
end

local function updateESP()
    local espOn = state.toggles["Box ESP"]
        or state.toggles["Tracers"]
        or state.toggles["Health Bar"]
        or state.toggles["Name Tag"]
        or state.toggles["Chams"]

    if not espOn then
        flush_esp()
        return
    end

    local espColor = getPlayerColor()
    local showBox = state.toggles["Box ESP"]
    local showTracers = state.toggles["Tracers"]
    local showHealth = state.toggles["Health Bar"]
    local showName = state.toggles["Name Tag"]
    local showChams = state.toggles["Chams"]

    -- Clean up esp objects for players who left
    for pid, tbl in pairs(esp_objects) do
        if not Players[pid] then
            for _, o in pairs(tbl) do
                pcall(function() o:Remove() end)
            end
            esp_objects[pid] = nil
        end
    end

    local playerList = Players:GetPlayers()
    for i = 1, #playerList do
        local player = playerList[i]
        if player == lp then
            -- skip self — no continue keyword for delta compat
        else
            local char = player.Character
            if char then
                local root = char:FindFirstChild("HumanoidRootPart")
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if root and humanoid then
                    local head = char:FindFirstChild("Head") or root
                    local pos, onScreen = worldToScreen(root.Position)
                    local headPos, _ = worldToScreen(head.Position + Vector3.new(0, 2, 0))
                    if onScreen then
                        -- Calculate box dimensions
                        local scale = (root.Position - camera.CFrame.Position).Magnitude
                        local boxH = math.clamp(18000 / scale, 20, 200)
                        local boxW = boxH * 0.6
                        local boxPos = Vector2.new(pos.X - boxW / 2, headPos.Y - boxH)
                        local boxSize = Vector2.new(boxW, boxH + (pos.Y - headPos.Y))

                        -- Create or get ESP objects for this player
                        if not esp_objects[player] then
                            esp_objects[player] = {
                                box = r(Vector2.new(0,0), Vector2.new(0,0), espColor, 1, 1.5),
                                boxFill = r(Vector2.new(0,0), Vector2.new(0,0), espColor, 0.1),
                                tracer = l(Vector2.new(0,0), Vector2.new(0,0), espColor, 1.5),
                                healthBg = r(Vector2.new(0,0), Vector2.new(0,0), Color3.new(0,0,0), 0.8),
                                healthBar = r(Vector2.new(0,0), Vector2.new(0,0), C.espGreen, 1),
                                nameTag = t(Vector2.new(0,0), "", 13, Color3.new(1,1,1), true),
                            }
                        end

                        local objs = esp_objects[player]
                        local hp = humanoid.Health / humanoid.MaxHealth

                        -- Box
                        if showBox then
                            objs.box.Position = boxPos
                            objs.box.Size = boxSize
                            objs.box.Color = espColor
                            objs.box.Visible = true
                            objs.boxFill.Position = boxPos
                            objs.boxFill.Size = boxSize
                            objs.boxFill.Color = espColor
                            objs.boxFill.Visible = true
                            objs.boxFill.Transparency = 0.08
                        else
                            objs.box.Visible = false
                            objs.boxFill.Visible = false
                        end

                        -- Tracer
                        if showTracers then
                            local cx, cy = camera.ViewSizeX / 2, camera.ViewSizeY
                            objs.tracer.From = Vector2.new(cx, cy)
                            objs.tracer.To = pos
                            objs.tracer.Color = espColor
                            objs.tracer.Visible = true
                        else
                            objs.tracer.Visible = false
                        end

                        -- Health Bar
                        if showHealth then
                            local hbW = 4
                            local hbH = boxSize.Y
                            local hbX = boxPos.X - hbW - 3
                            local hbY = boxPos.Y
                            objs.healthBg.Position = Vector2.new(hbX, hbY)
                            objs.healthBg.Size = Vector2.new(hbW, hbH)
                            objs.healthBg.Visible = true
                            objs.healthBar.Position = Vector2.new(hbX, hbY + hbH * (1 - hp))
                            objs.healthBar.Size = Vector2.new(hbW, hbH * hp)
                            objs.healthBar.Color = Color3.new(1 - hp, hp, 0)
                            objs.healthBar.Visible = true
                        else
                            objs.healthBg.Visible = false
                            objs.healthBar.Visible = false
                        end

                        -- Name Tag
                        if showName then
                            objs.nameTag.Position = Vector2.new(boxPos.X + boxSize.X / 2, boxPos.Y - 16)
                            objs.nameTag.Text = player.Name
                            objs.nameTag.Color = espColor
                            objs.nameTag.Visible = true
                        else
                            objs.nameTag.Visible = false
                        end

                        -- Chams via Highlight
                        if showChams then
                            if not objs.highlight then
                                local h = Instance.new("Highlight")
                                h.FillColor = espColor
                                h.OutlineColor = Color3.new(1,1,1)
                                h.FillTransparency = 0.5
                                h.OutlineTransparency = 0
                                h.Parent = char
                                objs.highlight = h
                            end
                            objs.highlight.Enabled = true
                        else
                            if objs.highlight then
                                objs.highlight.Enabled = false
                            end
                        end
                    else
                        -- Offscreen: hide ESP
                        if esp_objects[player] then
                            for _, o in pairs(esp_objects[player]) do
                                pcall(function() o.Visible = false end)
                            end
                        end
                    end
                end
            end
        end
    end
end

-- ====================================================================
-- CHEAT CONTROLLER
-- ====================================================================

local function runCheats()
    speedLoop()
    if state.toggles["Fly"] then
        updateFly()
    elseif flyBodyVelocity then
        toggleFly(false)
    end
    noclipLoop()
    if state.toggles["Infinite Jump"] and not infiniteJumpHook then
        toggleInfiniteJump(true)
    elseif not state.toggles["Infinite Jump"] and infiniteJumpHook then
        toggleInfiniteJump(false)
    end
    updateCrosshair()
    updateESP()
end

-- ====================================================================
-- INTERACTION
-- ====================================================================

local function isInside(pos, size, point)
    return point.X >= pos.X and point.X <= pos.X + size.X
        and point.Y >= pos.Y and point.Y <= pos.Y + size.Y
end

local function handleClick(input)
    if input.UserInputType ~= Enum.UserInputType.MouseButton1
        and input.UserInputType ~= Enum.UserInputType.Touch then
        return
    end

    local p, s = state.pos, state.size
    local pos = input.Position

    -- Close button
    if pos.X >= p.X + s.X - 30 and pos.X <= p.X + s.X
        and pos.Y >= p.Y + 6 and pos.Y <= p.Y + 36 then
        state.visible = false
        flush_all()
        return
    end

    -- Drag header
    if pos.Y >= p.Y and pos.Y <= p.Y + 50
        and pos.X >= p.X and pos.X <= p.X + s.X then
        state.drag.active = true
        state.drag.offset = Vector2.new(pos.X - p.X, pos.Y - p.Y)
        return
    end

    -- Tabs
    local tabY = p.Y + 52
    local tabW = math.floor((s.X - 20) / #tabs)
    for i = 1, #tabs do
        local name = tabs[i]
        local tx = p.X + 10 + (i-1) * tabW
        if isInside(Vector2.new(tx, tabY), Vector2.new(tabW, 28), pos) then
            state.tab = name
            return
        end
    end

    -- Toggles
    local toggleData
    if state.tab == "Player" then
        toggleData = {{"Speed",false},{"Fly",false},{"Infinite Jump",false},{"Noclip",false}}
    elseif state.tab == "Visuals" then
        toggleData = {{"Box ESP",true},{"Tracers",false},{"Health Bar",true},{"Name Tag",true},{"Chams",false},{"Crosshair",true}}
    elseif state.tab == "Settings" then
        toggleData = {{"Show Watermark",true},{"Show FPS",false},{"Auto-Execute",false}}
    end
    if toggleData then
        for i = 1, #toggleData do
            local item = toggleData[i]
            local ty = p.Y + 96 + (i-1) * 34
            if isInside(Vector2.new(p.X + 16, ty), Vector2.new(34, 22), pos) then
                local cur = state.toggles[item[1]]
                state.toggles[item[1]] = not (cur ~= nil and cur)
                return
            end
        end
    end

    -- Color strip
    if state.tab == "Visuals" then
        local csy = p.Y + 86 + 5*34 + 8 + 4*34 + 24
        local sw = math.floor(280 / 5)
        for i = 1, 5 do
            local sx = p.X + 16 + (i-1) * sw
            if isInside(Vector2.new(sx, csy + 16), Vector2.new(sw, 16), pos) then
                state.colorIdx = i
                return
            end
        end
    end

    -- Reset button
    if state.tab == "Settings" then
        local ry = p.Y + 346 + 3*34 + 12
        if isInside(Vector2.new(p.X+16, ry), Vector2.new(120, 28), pos) then
            state.toggles = {}
            state.sliders = { WalkSpeed = 50, JumpPower = 50, Smoothness = 0.5 }
            state.colorIdx = 1
            return
        end
    end
end

UIS.InputBegan:Connect(handleClick)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        state.drag.active = false
    end
end)

UIS.InputChanged:Connect(function(input)
    if (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch)
        and state.drag.active then
        local newPos = Vector2.new(
            math.max(0, math.min(input.Position.X - state.drag.offset.X, camera.ViewSizeX - state.size.X)),
            math.max(0, math.min(input.Position.Y - state.drag.offset.Y, camera.ViewSizeY - 40))
        )
        state.pos = newPos
    end
end)

-- ====================================================================
-- MAIN RENDER LOOP
-- ====================================================================

local function render()
    if not state.visible then return end
    flush()

    local p, s = state.pos, state.size
    drawWindow()
    drawTabs()

    if state.tab == "Player" then
        drawSection(p.Y+86, "MOVEMENT")
        local pd = {{"Speed",false},{"Fly",false},{"Infinite Jump",false},{"Noclip",false}}
        for i = 1, #pd do drawToggle(i, pd[i][1], pd[i][2]) end
        drawSection(p.Y + 86 + 4*34 + 8, "CHARACTER")
        drawSlider(1, "WalkSpeed", state.sliders.WalkSpeed or 50, 16, 200)
        drawSlider(2, "JumpPower", state.sliders.JumpPower or 50, 50, 350)

    elseif state.tab == "Visuals" then
        drawSection(p.Y+86, "ESP")
        local vd = {{"Box ESP",true},{"Tracers",false},{"Health Bar",true},{"Name Tag",true},{"Chams",false}}
        for i = 1, #vd do drawToggle(i, vd[i][1], vd[i][2]) end
        drawSection(p.Y + 86 + 5*34 + 8, "MISC")
        drawToggle(6, "Crosshair", true)
        drawSlider(1, "Smoothness", state.sliders.Smoothness or 0.5, 0, 1)
        drawColorStrip(p.Y + 86 + 5*34 + 8 + 4*34 + 24)

    elseif state.tab == "Settings" then
        drawSection(p.Y+86, "PROFILE")
        drawProfileCard(p.Y+104)
        drawSection(p.Y+186, "ABOUT")
        local cx = p.X + s.X/2
        alloc(t(Vector2.new(cx, p.Y+200), "itayoHub v2.0", 16, C.accent, true))
        alloc(t(Vector2.new(cx, p.Y+222), "Delta Executor Compatible", 12, C.textDim, true))
        alloc(t(Vector2.new(cx, p.Y+244), "Built with Lua by Hermes Agent", 10, C.textDim, true))
        drawSection(p.Y+346, "UI")
        drawToggle(1, "Show Watermark", true)
        drawToggle(2, "Show FPS", false)
        drawToggle(3, "Auto-Execute", false)
        local ry = p.Y + 346 + 3*34 + 12
        alloc(r(Vector2.new(p.X+16, ry), Vector2.new(120, 28), C.danger, 0.6))
        alloc(t(Vector2.new(p.X+76, ry+6), "Reset Config", 12, Color3.new(1,1,1), true))
    end

    runCheats()
end

local renderConnection = RunService.RenderStepped:Connect(render)

-- Cleanup on teleport
lp.OnTeleport:Connect(function()
    flush_all()
    if flyBodyVelocity then pcall(function() flyBodyVelocity:Destroy() end); flyBodyVelocity = nil end
    if flyBodyGyro then pcall(function() flyBodyGyro:Destroy() end); flyBodyGyro = nil end
    if infiniteJumpHook then infiniteJumpHook:Disconnect(); infiniteJumpHook = nil end
end)

print("itayoHub v2.0 loaded — Tabs: Player | Visuals | Settings")
print("Cheats: Speed, Fly, Infinite Jump, Noclip, ESP, Crosshair")
