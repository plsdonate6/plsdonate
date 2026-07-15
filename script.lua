-- Xeno Auto-Inject Script for PLS DONATE - Final Fixed Version
-- Полностью исправлены ошибки nil value, addLog, safeCall
-- Стабильная работа без крашей

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

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

-- Переменные
local isSpamming = false
local ScreenGui = nil

-- Простая функция безопасного вызова (без вложенных addLog)
local function tryCall(func, ...)
    local ok, err = pcall(func, ...)
    if not ok then
        -- Вывод ошибки в консоль без вызова других функций
        warn("Script error: " .. tostring(err))
    end
    return ok, err
end

-- Создание простого UI
local function createUI()
    tryCall(function()
        -- Удаление старого UI если есть
        local oldGui = CoreGui:FindFirstChild("PLSDonateGUI")
        if oldGui then
            oldGui:Destroy()
        end
        
        -- Создание ScreenGui
        ScreenGui = Instance.new("ScreenGui")
        ScreenGui.Name = "PLSDonateGUI"
        ScreenGui.Parent = CoreGui
        ScreenGui.ResetOnSpawn = false
        
        -- Главный фрейм
        local Frame = Instance.new("Frame")
        Frame.Name = "Frame"
        Frame.Parent = ScreenGui
        Frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        Frame.BorderSizePixel = 0
        Frame.Position = UDim2.new(0.5, -200, 0.5, -150)
        Frame.Size = UDim2.new(0, 400, 0, 300)
        Frame.Active = true
        Frame.Draggable = true
        
        -- Скругление углов
        local Corner = Instance.new("UICorner")
        Corner.CornerRadius = UDim.new(0, 8)
        Corner.Parent = Frame
        
        -- Заголовок
        local Title = Instance.new("TextLabel")
        Title.Parent = Frame
        Title.BackgroundTransparency = 1
        Title.Position = UDim2.new(0, 15, 0, 10)
        Title.Size = UDim2.new(1, -30, 0, 30)
        Title.Font = Enum.Font.GothamBold
        Title.Text = "PLS DONATE Spammer"
        Title.TextColor3 = Color3.fromRGB(255, 255, 255)
        Title.TextSize = 18
        
        -- Кнопка закрытия
        local CloseBtn = Instance.new("TextButton")
        CloseBtn.Parent = Frame
        CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
        CloseBtn.BorderSizePixel = 0
        CloseBtn.Position = UDim2.new(1, -35, 0, 10)
        CloseBtn.Size = UDim2.new(0, 24, 0, 24)
        CloseBtn.Font = Enum.Font.GothamBold
        CloseBtn.Text = "X"
        CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        CloseBtn.TextSize = 14
        
        local CloseCorner = Instance.new("UICorner")
        CloseCorner.CornerRadius = UDim.new(0, 12)
        CloseCorner.Parent = CloseBtn
        
        CloseBtn.MouseButton1Click:Connect(function()
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
        
        -- Информация
        local Info = Instance.new("TextLabel")
        Info.Parent = Frame
        Info.BackgroundTransparency = 1
        Info.Position = UDim2.new(0, 20, 0, 85)
        Info.Size = UDim2.new(1, -40, 0, 50)
        Info.Font = Enum.Font.Gotham
        Info.Text = "Delay: 10-25 sec\nDuration: 300 sec\nAuto Rejoin: ON"
        Info.TextColor3 = Color3.fromRGB(180, 180, 180)
        Info.TextSize = 12
        Info.TextXAlignment = Enum.TextXAlignment.Left
        Info.TextYAlignment = Enum.TextYAlignment.Top
        
        -- Кнопка Старт
        local StartBtn = Instance.new("TextButton")
        StartBtn.Parent = Frame
        StartBtn.BackgroundColor3 = Color3.fromRGB(0, 140, 255)
        StartBtn.BorderSizePixel = 0
        StartBtn.Position = UDim2.new(0, 20, 0, 155)
        StartBtn.Size = UDim2.new(1, -40, 0, 50)
        StartBtn.Font = Enum.Font.GothamBold
        StartBtn.Text = "START SPAM"
        StartBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        StartBtn.TextSize = 16
        
        local StartCorner = Instance.new("UICorner")
        StartCorner.CornerRadius = UDim.new(0, 6)
        StartCorner.Parent = StartBtn
        
        -- Кнопка Стоп
        local StopBtn = Instance.new("TextButton")
        StopBtn.Parent = Frame
        StopBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        StopBtn.BorderSizePixel = 0
        StopBtn.Position = UDim2.new(0, 20, 0, 215)
        StopBtn.Size = UDim2.new(1, -40, 0, 50)
        StopBtn.Font = Enum.Font.GothamBold
        StopBtn.Text = "STOP SPAM"
        StopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        StopBtn.TextSize = 16
        
        local StopCorner = Instance.new("UICorner")
        StopCorner.CornerRadius = UDim.new(0, 6)
        StopCorner.Parent = StopBtn
        
        -- Обработчик Старт
        StartBtn.MouseButton1Click:Connect(function()
            if not isSpamming then
                isSpamming = true
                Status.Text = "Status: Running..."
                Status.TextColor3 = Color3.fromRGB(0, 255, 100)
                
                -- Запуск в отдельном потоке
                coroutine.wrap(function()
                    startSpam()
                end)()
            end
        end)
        
        -- Обработчик Стоп
        StopBtn.MouseButton1Click:Connect(function()
            isSpamming = false
            Status.Text = "Status: Stopped"
            Status.TextColor3 = Color3.fromRGB(255, 100, 100)
        end)
        
        -- Подпись
        local Credit = Instance.new("TextLabel")
        Credit.Parent = Frame
        Credit.BackgroundTransparency = 1
        Credit.Position = UDim2.new(0, 20, 0, 278)
        Credit.Size = UDim2.new(1, -40, 0, 15)
        Credit.Font = Enum.Font.Gotham
        Credit.Text = "made by aveh"
        Credit.TextColor3 = Color3.fromRGB(100, 100, 100)
        Credit.TextSize = 10
        Credit.TextXAlignment = Enum.TextXAlignment.Center
    end)
end

-- Отправка сообщения
local function sendMessage(msg)
    tryCall(function()
        local player = Players.LocalPlayer
        if not player then return end
        
        local playerGui = player:FindFirstChild("PlayerGui")
        if not playerGui then return end
        
        local chat = playerGui:FindFirstChild("Chat")
        if not chat then return end
        
        local frame = chat:FindFirstChild("Frame")
        if not frame then return end
        
        local barParent = frame:FindFirstChild("ChatBarParentFrame")
        if not barParent then return end
        
        local chatBar = barParent:FindFirstChild("ChatBar")
        if not chatBar or not chatBar:IsA("TextBox") then return end
        
        -- Установка текста
        chatBar.Text = msg
        wait(0.2)
        
        -- Отправка через Enter
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, nil)
        wait(0.1)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, nil)
    end)
end

-- Телепорт на новый сервер
local function teleportToNewServer()
    tryCall(function()
        wait(2)
        TeleportService:Teleport(TARGET_PLACE_ID)
    end)
end

-- Основная функция спама
function startSpam()
    -- Ожидание загрузки игры
    if not game:IsLoaded() then
        game.Loaded:Wait()
    end
    
    wait(3)
    
    -- Проверка игрока
    if not Players.LocalPlayer then return end
    
    local startTime = tick()
    local msgIndex = 1
    
    -- Цикл спама
    while isSpamming and (tick() - startTime) < SPAM_DURATION do
        -- Проверка что игрок в игре
        if not Players.LocalPlayer or not Players.LocalPlayer.Parent then
            break
        end
        
        -- Отправка сообщения
        sendMessage(MESSAGES[msgIndex])
        
        -- Рандомная задержка
        local delay = math.random(SPAM_DELAY_MIN, SPAM_DELAY_MAX)
        local waitStart = tick()
        
        -- Разбивка ожидания для возможности остановки
        while isSpamming and (tick() - waitStart) < delay do
            wait(1)
        end
        
        -- Переход к следующему сообщению
        msgIndex = msgIndex + 1
        if msgIndex > #MESSAGES then
            msgIndex = 1
        end
    end
    
    -- Обновление статуса в UI
    tryCall(function()
        if ScreenGui and ScreenGui:FindFirstChild("Frame") then
            local statusLabel = ScreenGui.Frame:FindFirstChild("Status")
            if statusLabel then
                statusLabel.Text = "Status: Finished"
                statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
            end
        end
    end)
    
    isSpamming = false
    
    -- Авто-реджойн
    if AUTO_REJOIN then
        teleportToNewServer()
    end
end

-- Анти-АФК система
coroutine.wrap(function()
    while wait(45) do
        tryCall(function()
            local player = Players.LocalPlayer
            if player and player.Character then
                local humanoid = player.Character:FindFirstChild("Humanoid")
                if humanoid then
                    humanoid.CameraOffset = Vector3.new(0, 0.001, 0)
                    wait(0.1)
                    humanoid.CameraOffset = Vector3.new(0, 0, 0)
                end
            end
        end)
    end
end)()

-- Инициализация
tryCall(function()
    wait(2)
    
    -- Ожидание загрузки игры
    if not game:IsLoaded() then
        game.Loaded:Wait()
    end
    
    -- Отключение проблемных скриптов PLS DONATE для предотвращения ошибок
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local scriptsToDisable = {
        "LeaderboardHistoryClient", 
        "HypeTrainClient_OLD", 
        "BoothInteraction", 
        "PDRewind"
    }
    
    for _, scriptName in ipairs(scriptsToDisable) do
        tryCall(function()
            local targetScript = ReplicatedStorage:FindFirstChild(scriptName)
            if targetScript then 
                targetScript.Disabled = true 
            end
            -- Проверка во вложенных папках
            local clientFolder = ReplicatedStorage:FindFirstChild("Client")
            if clientFolder then
                local clientScript = clientFolder:FindFirstChild(scriptName)
                if clientScript then
                    clientScript.Disabled = true
                end
            end
        end)
    end
    
    -- Запуск UI
    createUI()
    
    print("PLS DONATE Spammer loaded. Made by aveh.")
end)()
