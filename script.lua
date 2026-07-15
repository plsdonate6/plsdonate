-- Xeno Auto-Inject Script for PLS DONATE - Crash Fix Version
-- Исправлен краш из-за ошибок PLS DONATE, оптимизирована совместимость

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")

-- Конфигурация
local MESSAGES = {
    "плиз донате робуксы мне надо срочно",
    "пожалуйста подарите робуксы буду благодарен",
    "дайте робуксов плиз очень нужно",
    "робуксы в донат плиз помогите",
    "киньте робуксов кто сколько может плиз",
    "срочно нужны робуксы помогите кто чем может",
    "ребят скиньтесь робуксами пожалуйста",
    "плиз донать робуксы а то не хватает",
    "будьте добры подарите робуксов",
    "робуксы плиз в донат очень прошу"
}
local TARGET_PLACE_ID = 8737602449
local SPAM_DELAY_MIN = 10
local SPAM_DELAY_MAX = 25
local SPAM_DURATION = 300
local AUTO_REJOIN = true

-- Переменные состояния
local isSpamming = false
local ScreenGui = nil

-- Безопасный вызов без ошибок
local function safeCall(func, ...)
    local success, result = pcall(func, ...)
    return success, result
end

-- Создание UI
local function createUI()
    safeCall(function()
        if CoreGui:FindFirstChild("PLSDonateGUI") then
            CoreGui.PLSDonateGUI:Destroy()
        end
        
        ScreenGui = Instance.new("ScreenGui")
        ScreenGui.Name = "PLSDonateGUI"
        ScreenGui.Parent = CoreGui
        ScreenGui.ResetOnSpawn = false
        
        local Frame = Instance.new("Frame")
        Frame.Name = "Frame"
        Frame.Parent = ScreenGui
        Frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        Frame.BorderSizePixel = 0
        Frame.Position = UDim2.new(0.5, -200, 0.5, -150)
        Frame.Size = UDim2.new(0, 400, 0, 300)
        Frame.Active = true
        Frame.Draggable = true
        
        local UICorner = Instance.new("UICorner")
        UICorner.CornerRadius = UDim.new(0, 8)
        UICorner.Parent = Frame
        
        -- Заголовок
        local Title = Instance.new("TextLabel")
        Title.Name = "Title"
        Title.Parent = Frame
        Title.BackgroundTransparency = 1
        Title.Position = UDim2.new(0, 15, 0, 10)
        Title.Size = UDim2.new(1, -30, 0, 30)
        Title.Font = Enum.Font.GothamBold
        Title.Text = "PLS DONATE Spammer"
        Title.TextColor3 = Color3.fromRGB(255, 255, 255)
        Title.TextSize = 18
        
        -- Кнопка закрытия
        local Close = Instance.new("TextButton")
        Close.Name = "Close"
        Close.Parent = Frame
        Close.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
        Close.BorderSizePixel = 0
        Close.Position = UDim2.new(1, -35, 0, 10)
        Close.Size = UDim2.new(0, 24, 0, 24)
        Close.Font = Enum.Font.GothamBold
        Close.Text = "X"
        Close.TextColor3 = Color3.fromRGB(255, 255, 255)
        Close.TextSize = 14
        
        local CloseCorner = Instance.new("UICorner")
        CloseCorner.CornerRadius = UDim.new(0, 12)
        CloseCorner.Parent = Close
        
        Close.MouseButton1Click:Connect(function()
            ScreenGui:Destroy()
            isSpamming = false
        end)
        
        -- Статус
        local Status = Instance.new("TextLabel")
        Status.Name = "Status"
        Status.Parent = Frame
        Status.BackgroundTransparency = 1
        Status.Position = UDim2.new(0, 20, 0, 55)
        Status.Size = UDim2.new(1, -40, 0, 20)
        Status.Font = Enum.Font.Gotham
        Status.Text = "Status: Ready"
        Status.TextColor3 = Color3.fromRGB(0, 255, 100)
        Status.TextSize = 13
        Status.TextXAlignment = Enum.TextXAlignment.Left
        
        -- Настройки
        local DelayLabel = Instance.new("TextLabel")
        DelayLabel.Name = "DelayLabel"
        DelayLabel.Parent = Frame
        DelayLabel.BackgroundTransparency = 1
        DelayLabel.Position = UDim2.new(0, 20, 0, 90)
        DelayLabel.Size = UDim2.new(1, -40, 0, 20)
        DelayLabel.Font = Enum.Font.Gotham
        DelayLabel.Text = "Delay: 10-25 seconds"
        DelayLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
        DelayLabel.TextSize = 12
        DelayLabel.TextXAlignment = Enum.TextXAlignment.Left
        
        local DurationLabel = Instance.new("TextLabel")
        DurationLabel.Name = "DurationLabel"
        DurationLabel.Parent = Frame
        DurationLabel.BackgroundTransparency = 1
        DurationLabel.Position = UDim2.new(0, 20, 0, 115)
        DurationLabel.Size = UDim2.new(1, -40, 0, 20)
        DurationLabel.Font = Enum.Font.Gotham
        DurationLabel.Text = "Duration: 300 seconds"
        DurationLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
        DurationLabel.TextSize = 12
        DurationLabel.TextXAlignment = Enum.TextXAlignment.Left
        
        -- Кнопка Старт
        local StartBtn = Instance.new("TextButton")
        StartBtn.Name = "StartBtn"
        StartBtn.Parent = Frame
        StartBtn.BackgroundColor3 = Color3.fromRGB(0, 140, 255)
        StartBtn.BorderSizePixel = 0
        StartBtn.Position = UDim2.new(0, 20, 0, 160)
        StartBtn.Size = UDim2.new(1, -40, 0, 45)
        StartBtn.Font = Enum.Font.GothamBold
        StartBtn.Text = "START SPAM"
        StartBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        StartBtn.TextSize = 16
        
        local StartCorner = Instance.new("UICorner")
        StartCorner.CornerRadius = UDim.new(0, 6)
        StartCorner.Parent = StartBtn
        
        -- Кнопка Стоп
        local StopBtn = Instance.new("TextButton")
        StopBtn.Name = "StopBtn"
        StopBtn.Parent = Frame
        StopBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        StopBtn.BorderSizePixel = 0
        StopBtn.Position = UDim2.new(0, 20, 0, 215)
        StopBtn.Size = UDim2.new(1, -40, 0, 45)
        StopBtn.Font = Enum.Font.GothamBold
        StopBtn.Text = "STOP SPAM"
        StopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        StopBtn.TextSize = 16
        
        local StopCorner = Instance.new("UICorner")
        StopCorner.CornerRadius = UDim.new(0, 6)
        StopCorner.Parent = StopBtn
        
        -- Обработчики кнопок
        StartBtn.MouseButton1Click:Connect(function()
            if not isSpamming then
                isSpamming = true
                Status.Text = "Status: Running..."
                Status.TextColor3 = Color3.fromRGB(0, 255, 100)
                spawn(function()
                    startSpam()
                end)
            end
        end)
        
        StopBtn.MouseButton1Click:Connect(function()
            isSpamming = false
            Status.Text = "Status: Stopped"
            Status.TextColor3 = Color3.fromRGB(255, 100, 100)
        end)
        
        -- Подпись
        local Credit = Instance.new("TextLabel")
        Credit.Name = "Credit"
        Credit.Parent = Frame
        Credit.BackgroundTransparency = 1
        Credit.Position = UDim2.new(0, 20, 0, 275)
        Credit.Size = UDim2.new(1, -40, 0, 15)
        Credit.Font = Enum.Font.Gotham
        Credit.Text = "made by aveh"
        Credit.TextColor3 = Color3.fromRGB(100, 100, 100)
        Credit.TextSize = 10
        Credit.TextXAlignment = Enum.TextXAlignment.Center
    end)
end

-- Отправка сообщения в чат
local function sendMessage(msg)
    safeCall(function()
        local player = Players.LocalPlayer
        if not player then return end
        
        local playerGui = player:FindFirstChild("PlayerGui")
        if not playerGui then return end
        
        -- Поиск чата
        local chat = playerGui:FindFirstChild("Chat")
        if not chat then return end
        
        local frame = chat:FindFirstChild("Frame")
        if not frame then return end
        
        local barParent = frame:FindFirstChild("ChatBarParentFrame")
        if not barParent then return end
        
        local chatBar = barParent:FindFirstChild("ChatBar")
        if not chatBar or not chatBar:IsA("TextBox") then return end
        
        -- Отправка
        chatBar.Text = msg
        wait(0.2)
        
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, nil)
        wait(0.1)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, nil)
    end)
end

-- Телепорт
local function teleportToNewServer()
    safeCall(function()
        wait(2)
        TeleportService:Teleport(TARGET_PLACE_ID)
    end)
end

-- Основной цикл спама
function startSpam()
    if not game:IsLoaded() then
        game.Loaded:Wait()
    end
    
    wait(2)
    
    if not Players.LocalPlayer then return end
    
    local startTime = tick()
    local msgIndex = 1
    
    while isSpamming and (tick() - startTime) < SPAM_DURATION do
        if not Players.LocalPlayer or not Players.LocalPlayer.Parent then
            break
        end
        
        -- Отправка сообщения
        sendMessage(MESSAGES[msgIndex])
        
        -- Задержка
        local delay = math.random(SPAM_DELAY_MIN, SPAM_DELAY_MAX)
        local waitStart = tick()
        while isSpamming and (tick() - waitStart) < delay do
            wait(1)
        end
        
        -- Следующее сообщение
        msgIndex = msgIndex + 1
        if msgIndex > #MESSAGES then
            msgIndex = 1
        end
    end
    
    -- Обновление статуса
    safeCall(function()
        if ScreenGui and ScreenGui:FindFirstChild("Frame") then
            local status = ScreenGui.Frame:FindFirstChild("Status")
            if status then
                status.Text = "Status: Finished"
                status.TextColor3 = Color3.fromRGB(200, 200, 200)
            end
        end
    end)
    
    isSpamming = false
    
    -- Телепорт
    if AUTO_REJOIN then
        teleportToNewServer()
    end
end

-- Анти-АФК
spawn(function()
    while wait(60) do
        safeCall(function()
            if Players.LocalPlayer and Players.LocalPlayer.Character then
                local humanoid = Players.LocalPlayer.Character:FindFirstChild("Humanoid")
                if humanoid then
                    humanoid.CameraOffset = Vector3.new(0, 0.001, 0)
                    wait(0.1)
                    humanoid.CameraOffset = Vector3.new(0, 0, 0)
                end
            end
        end)
    end
end)

-- Запуск
safeCall(function()
    wait(3)
    if not game:IsLoaded() then
        game.Loaded:Wait()
    end
    
    -- Отключение проблемных скриптов PLS DONATE
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local problemScripts = {"LeaderboardHistoryClient", "HypeTrainClient_OLD", "BoothInteraction", "PDRewind"}
    for _, name in ipairs(problemScripts) do
        safeCall(function()
            local script = ReplicatedStorage:FindFirstChild(name)
            if script then script.Disabled = true end
        end)
    end
    
    -- Создание UI
    createUI()
end)
