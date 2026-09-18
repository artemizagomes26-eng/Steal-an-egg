-- Menu completo: Auto Steal + Auto Return + ESP + Auto Dodge
local gui = Instance.new("ScreenGui")
gui.Name = "BasicMenu"
gui.ResetOnSpawn = false
gui.Parent = game:GetService("CoreGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 260, 0, 470)
frame.Position = UDim2.new(0.5, -130, 0.5, -235)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 28)
title.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
title.BorderSizePixel = 0
title.Text = "Steal an Egg - Menu"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 15
title.Font = Enum.Font.GothamBold
title.Parent = frame

local close = Instance.new("TextButton")
close.Size = UDim2.new(0, 28, 0, 28)
close.Position = UDim2.new(1, -28, 0, 0)
close.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
close.BorderSizePixel = 0
close.Text = "X"
close.TextColor3 = Color3.fromRGB(255, 255, 255)
close.TextSize = 14
close.Font = Enum.Font.GothamBold
close.Parent = frame
close.MouseButton1Click:Connect(function() gui:Destroy() end)

local list = Instance.new("UIListLayout")
list.Padding = UDim.new(0, 4)
list.Parent = frame

local pad = Instance.new("UIPadding")
pad.PaddingTop = UDim.new(0, 34)
pad.PaddingLeft = UDim.new(0, 5)
pad.PaddingRight = UDim.new(0, 5)
pad.Parent = frame

-- ===== CONFIGURAÇÕES =====
getgenv().AutoSteal = false
getgenv().AutoReturn = false
getgenv().ESP = false
getgenv().AutoDodge = false
getgenv().DodgeDistance = 25    -- distância mínima pra fugir
getgenv().BasePosition = Vector3.new(0, 5, 0)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

-- ===== FUNÇÕES BASE =====
local function encontrarPrompt()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
    local hrp = char.HumanoidRootPart
    local melhor, dist = nil, math.huge
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and obj.Enabled then
            local nome = string.lower(obj.Parent.Name .. " " .. obj.ObjectText .. " " .. obj.ActionText)
            if string.find(nome, "egg") or string.find(nome, "steal") or string.find(nome, "ovo") then
                local part = obj.Parent
                if part:IsA("BasePart") then
                    local d = (hrp.Position - part.Position).Magnitude
                    if d < dist then dist = d; melhor = obj end
                end
            end
        end
    end
    return melhor, dist
end

local function roubarOvo()
    local prompt, dist = encontrarPrompt()
    if prompt and dist < 15 then
        local tecla = prompt.KeyboardKeyCode
        if tecla then
            VirtualInputManager:SendKeyEvent(true, tecla, false, game)
            task.wait(0.1)
            VirtualInputManager:SendKeyEvent(false, tecla, false, game)
        else
            pcall(function()
                prompt:InputHoldBegin()
                task.wait(prompt.HoldDuration + 0.05)
                prompt:InputHoldEnd()
            end)
        end
        return true
    end
    return false
end

local function moverParaOvo()
    local prompt = encontrarPrompt()
    if not prompt then return false end
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return false end
    local part = prompt.Parent
    if part:IsA("BasePart") then
        char.HumanoidRootPart.CFrame = CFrame.new(part.Position + Vector3.new(0, 3, 0))
        return true
    end
    return false
end

local function voltarParaBase()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = CFrame.new(getgenv().BasePosition)
        return true
    end
    return false
end

-- ===== DETECÇÃO DO PERSEGUIDOR =====
-- Procura NPCs/inimigos próximos (protetores, guardas, etc.)
local function encontrarPerseguidor()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
    local hrp = char.HumanoidRootPart
    local melhor, dist = nil, math.huge

    for _, obj in pairs(workspace:GetDescendants()) do
        -- Procura por Humanoids que NÃO são do jogador
        if obj:IsA("Humanoid") and obj.Parent ~= char then
            local parent = obj.Parent
            -- Verifica se tem HumanoidRootPart (é um NPC/personagem)
            if parent and parent:FindFirstChild("HumanoidRootPart") then
                local nome = string.lower(parent.Name)
                -- Filtra por nomes comuns de protetores/perseguidores
                if string.find(nome, "protector") or string.find(nome, "guard")
                   or string.find(nome, "chaser") or string.find(nome, "hunter")
                   or string.find(nome, "enemy") or string.find(nome, "npc")
                   or string.find(nome, "monster") or string.find(nome, "boss") then
                    local d = (hrp.Position - parent.HumanoidRootPart.Position).Magnitude
                    if d < dist then
                        dist = d
                        melhor = parent
                    end
                end
            end
        end
    end
    return melhor, dist
end

-- Calcula a direção oposta ao perseguidor e foge
local function fugirDoPerseguidor()
    local perseguidor, dist = encontrarPerseguidor()
    if not perseguidor or not dist then return false end

    -- Só foge se estiver dentro do raio de perigo
    if dist > getgenv().DodgeDistance then return false end

    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return false end

    local hrp = char.HumanoidRootPart
    local inimigoPos = perseguidor.HumanoidRootPart.Position

    -- Direção: oposta ao inimigo
    local direcao = (hrp.Position - inimigoPos).Unit
    -- Se estiver em cima, escolhe uma direção qualquer
    if direcao.Magnitude < 0.1 then
        direcao = Vector3.new(1, 0, 0)
    end

    -- Novo destino: 30 studs na direção oposta
    local destino = hrp.Position + direcao * 30
    -- Mantém o Y do chão (evita voar ou cair)
    destino = Vector3.new(destino.X, hrp.Position.Y, destino.Z)

    hrp.CFrame = CFrame.new(destino)
    return true
end

-- ===== ESP =====
local espFolder = Instance.new("Folder")
espFolder.Name = "EggESP"
espFolder.Parent = gui

local espCache = {}

local function criarESP(part, nome, cor)
    if espCache[part] then return end
    local highlight = Instance.new("Highlight")
    highlight.FillColor = cor or Color3.fromRGB(255, 215, 0)
    highlight.OutlineColor = Color3.fromRGB(255, 100, 0)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Adornee = part
    highlight.Parent = espFolder

    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 120, 0, 30)
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

    espCache[part] = {highlight, billboard}
end

local function limparESP()
    for _, objs in pairs(espCache) do
        for _, obj in ipairs(objs) do
            if obj and obj.Parent then obj:Destroy() end
        end
    end
    espCache = {}
    for _, child in ipairs(espFolder:GetChildren()) do
        child:Destroy()
    end
end

task.spawn(function()
    while task.wait(0.5) do
        if not getgenv().ESP then
            if next(espCache) then limparESP() end
        else
            for _, obj in pairs(workspace:GetDescendants()) do
                if obj:IsA("ProximityPrompt") and obj.Enabled then
                    local nome = string.lower(obj.Parent.Name .. " " .. obj.ObjectText .. " " .. obj.ActionText)
                    if string.find(nome, "egg") or string.find(nome, "steal") or string.find(nome, "ovo") then
                        local part = obj.Parent
                        if part:IsA("BasePart") then
                            criarESP(part, part.Name, Color3.fromRGB(255, 215, 0))
                        end
                    end
                end
            end
        end
    end
end)

-- ===== BOTÕES =====
local function criarToggle(nome, chave, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 32)
    btn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    btn.BorderSizePixel = 0
    btn.Text = nome .. ": OFF"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 13
    btn.Font = Enum.Font.Gotham
    btn.Parent = frame
    btn.MouseButton1Click:Connect(function()
        getgenv()[chave] = not getgenv()[chave]
        btn.Text = nome .. ": " .. (getgenv()[chave] and "ON" or "OFF")
        btn.BackgroundColor3 = getgenv()[chave] and Color3.fromRGB(0, 130, 0) or Color3.fromRGB(45, 45, 45)
        if callback then callback(getgenv()[chave]) end
    end)
    return btn
end

local function criarBotao(nome, acao)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 32)
    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    btn.BorderSizePixel = 0
    btn.Text = nome
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 13
    btn.Font = Enum.Font.Gotham
    btn.Parent = frame
    btn.MouseButton1Click:Connect(function() if acao then acao() end end)
    return btn
end

criarToggle("Auto Steal", "AutoSteal", function(ligado)
    if ligado then
        task.spawn(function()
            while getgenv().AutoSteal do
                local roubou = roubarOvo()
                if roubou then
                    task.wait(0.5)
                    if getgenv().AutoReturn then
                        voltarParaBase()
                        task.wait(1)
                    end
                else
                    moverParaOvo()
                    task.wait(0.3)
                end
                task.wait(0.1)
            end
        end)
    end
end)

criarToggle("Auto Return to Base", "AutoReturn")
criarToggle("ESP Ovos", "ESP")

-- AUTO DODGE
criarToggle("Auto Dodge", "AutoDodge", function(ligado)
    if ligado then
        task.spawn(function()
            while getgenv().AutoDodge do
                fugirDoPerseguidor()
                task.wait(0.15)
            end
        end)
    end
end)

criarBotao("Salvar Posição Atual como Base", function()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        getgenv().BasePosition = char.HumanoidRootPart.Position
        print("[Menu] Base salva em:", getgenv().BasePosition)
    end
end)

criarBotao("Voltar para Base", function()
    voltarParaBase()
end)

print("[Menu] Carregado: Auto Steal, Auto Return, ESP e Auto Dodge!")
