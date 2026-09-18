--[[ Menu: Auto Steal + Auto Return + ESP + Auto Dodge
     Versão corrigida e otimizada ]]

-- ===== SERVIÇOS =====
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer

-- ===== PARENT GUI (compatível com executores modernos) =====
local function getGuiParent()
    if gethui then
        local ok, hui = pcall(gethui)
        if ok and hui then return hui end
    end
    if protect_gui then
        local ok, pg = pcall(protect_gui)
        if ok and pg then return pg end
    end
    local ok, cg = pcall(function() return game:GetService("CoreGui") end)
    if ok and cg then return cg end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local gui = Instance.new("ScreenGui")
gui.Name = "BasicMenu_" .. tostring(math.random(1000, 9999))
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = getGuiParent()

-- ===== FRAME PRINCIPAL =====
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 280, 0, 470)
frame.Position = UDim2.new(0.5, -140, 0.5, -235)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
title.BorderSizePixel = 0
title.Text = "Steal an Egg - Menu"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 15
title.Font = Enum.Font.GothamBold
title.Parent = frame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 8)
titleCorner.Parent = title

local close = Instance.new("TextButton")
close.Size = UDim2.new(0, 28, 0, 28)
close.Position = UDim2.new(1, -32, 0, 1)
close.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
close.BorderSizePixel = 0
close.Text = "X"
close.TextColor3 = Color3.fromRGB(255, 255, 255)
close.TextSize = 14
close.Font = Enum.Font.GothamBold
close.Parent = frame
close.MouseButton1Click:Connect(function()
    gui:Destroy()
    getgenv().AutoSteal = false
    getgenv().AutoReturn = false
    getgenv().ESP = false
    getgenv().AutoDodge = false
end)

local list = Instance.new("UIListLayout")
list.Padding = UDim.new(0, 4)
list.SortOrder = Enum.SortOrder.LayoutOrder
list.Parent = frame

local pad = Instance.new("UIPadding")
pad.PaddingTop = UDim.new(0, 36)
pad.PaddingLeft = UDim.new(0, 6)
pad.PaddingRight = UDim.new(0, 6)
pad.PaddingBottom = UDim.new(0, 6)
pad.Parent = frame

-- ===== ESTADO =====
getgenv().AutoSteal    = false
getgenv().AutoReturn   = false
getgenv().ESP          = false
getgenv().AutoDodge    = false
getgenv().DodgeDistance = 25
getgenv().BasePosition  = Vector3.new(0, 5, 0)

-- ===== HELPERS =====
local function getChar()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChildOfClass("Humanoid") then
        return char
    end
    return nil
end

local function matchesEgg(str)
    str = string.lower(str)
    return string.find(str, "egg", 1, true)
        or string.find(str, "steal", 1, true)
        or string.find(str, "ovo", 1, true)
end

-- Cache de prompts de ovos
local eggPrompts = {}

local function refreshEggPrompts()
    local novo = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and obj.Enabled then
            local parent = obj.Parent
            if parent and parent:IsA("BasePart") then
                local texto = parent.Name .. " " .. (obj.ObjectText or "") .. " " .. (obj.ActionText or "")
                if matchesEgg(texto) then
                    table.insert(novo, { prompt = obj, part = parent })
                end
            end
        end
    end
    eggPrompts = novo
    return novo
end

local function findClosestEgg(maxDist)
    maxDist = maxDist or math.huge
    local char = getChar()
    if not char then return nil end
    local hrp = char.HumanoidRootPart
    local best, bestDist = nil, maxDist

    for _, entry in ipairs(eggPrompts) do
        if entry.prompt.Enabled and entry.part.Parent then
            local d = (hrp.Position - entry.part.Position).Magnitude
            if d < bestDist then
                best, bestDist = entry, d
            end
        end
    end
    return best, bestDist
end

-- ===== STEAL =====
local function roubarOvo()
    local entry, dist = findClosestEgg(15)
    if not entry then return false end
    local prompt = entry.prompt

    local ok = pcall(function()
        prompt:InputHoldBegin()
        task.wait(math.max(prompt.HoldDuration, 0.05) + 0.05)
        prompt:InputHoldEnd()
    end)

    if not ok then
        -- Fallback via keypress
        local tecla = prompt.KeyboardKeyCode
        if tecla and tecla ~= Enum.KeyCode.Unknown then
            pcall(function()
                VirtualInputManager:SendKeyEvent(true, tecla, false, game)
                task.wait(0.1)
                VirtualInputManager:SendKeyEvent(false, tecla, false, game)
            end)
            return true
        end
        return false
    end
    return true
end

local function moverParaOvo()
    local entry = findClosestEgg()
    if not entry then return false end
    local char = getChar()
    if not char then return false end
    char.HumanoidRootPart.CFrame = CFrame.new(entry.part.Position + Vector3.new(0, 3, 0))
    return true
end

local function voltarParaBase()
    local char = getChar()
    if not char then return false end
    char.HumanoidRootPart.CFrame = CFrame.new(getgenv().BasePosition)
    return true
end

-- ===== AUTO DODGE =====
-- Detecta qualquer Humanoid que NÃO seja do jogador, dentro de um raio
local function encontrarPerseguidor(raio)
    raio = raio or getgenv().DodgeDistance
    local char = getChar()
    if not char then return nil end
    local hrp = char.HumanoidRootPart
    local best, bestDist = nil, raio

    for _, model in ipairs(workspace:GetChildren()) do
        if model ~= char and model:IsA("Model") then
            local hum = model:FindFirstChildOfClass("Humanoid")
            local root = model:FindFirstChild("HumanoidRootPart")
            if hum and root and hum.Health > 0 then
                -- Verifica se é um NPC (não é um jogador)
                local plr = Players:GetPlayerFromCharacter(model)
                if not plr then
                    local d = (hrp.Position - root.Position).Magnitude
                    if d < bestDist then
                        best, bestDist = model, d
                    end
                end
            end
        end
    end
    return best, bestDist
end

local function fugirDoPerseguidor()
    local inimigo, dist = encontrarPerseguidor(getgenv().DodgeDistance)
    if not inimigo then return false end

    local char = getChar()
    if not char then return false end
    local hrp = char.HumanoidRootPart
    local inimigoPos = inimigo.HumanoidRootPart.Position

    -- Direção oposta ao inimigo
    local delta = hrp.Position - inimigoPos
    delta = Vector3.new(delta.X, 0, delta.Z)
    local direcao
    if delta.Magnitude < 0.1 then
        direcao = Vector3.new(1, 0, 0)
    else
        direcao = delta.Unit
    end

    -- Procura destino seguro com raycast (evita cair do mapa)
    local destino
    for _, offset in ipairs({30, 20, 15, 10}) do
        local alvo = hrp.Position + direcao * offset
        local rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
        rayParams.FilterDescendantsInstances = { char }
        local ray = workspace:Raycast(alvo + Vector3.new(0, 50, 0), Vector3.new(0, -200, 0), rayParams)
        if ray and ray.Position then
            destino = ray.Position + Vector3.new(0, 3, 0)
            break
        end
    end

    if not destino then
        destino = hrp.Position + direcao * 20
    end

    hrp.CFrame = CFrame.new(destino)
    return true
end

-- ===== ESP =====
local espFolder = Instance.new("Folder")
espFolder.Name = "EggESP"
espFolder.Parent = gui

local espCache = {}

local function criarESP(part, nome, cor)
    if espCache[part] and espCache[part].highlight and espCache[part].highlight.Parent then
        return
    end
    local highlight = Instance.new("Highlight")
    highlight.FillColor = cor or Color3.fromRGB(255, 215, 0)
    highlight.OutlineColor = Color3.fromRGB(255, 100, 0)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Adornee = part
    highlight.Parent = espFolder

    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 120, 0, 28)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Adornee = part
    billboard.Parent = espFolder

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = nome or "Ovo"
    label.TextColor3 = cor or Color3.fromRGB(255, 255, 0)
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Parent = billboard

    espCache[part] = { highlight = highlight, billboard = billboard }
end

local function limparESP()
    for _, objs in pairs(espCache) do
        if objs.highlight then objs.highlight:Destroy() end
        if objs.billboard then objs.billboard:Destroy() end
    end
    espCache = {}
end

-- Loop ESP (usa cache de prompts, sem GetDescendants a cada frame)
task.spawn(function()
    while task.wait(0.5) do
        if not gui.Parent then break end
        if getgenv().ESP then
            refreshEggPrompts()
            local vistos = {}
            for _, entry in ipairs(eggPrompts) do
                vistos[entry.part] = true
                criarESP(entry.part, entry.part.Name, Color3.fromRGB(255, 215, 0))
