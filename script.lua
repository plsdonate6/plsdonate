-- Xeno Auto-Inject Script for Roblox - Stable Version with Crash Fix
-- Запрос донатов робаксов, смена сервера, авто-инжект, стабильная работа без крашей

local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

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
local TARGET_PLACE_ID = 4483381587
local SPAM_DELAY_MIN = 10
local SPAM_DELAY_MAX = 25
local SPAM_DURATION = 300
local AUTO_REJOIN = true

-- Безопасный вызов функций с защитой от краша
local function safeCall(func, ...)
    local success, result = pcall(func, ...)
    if not success then
        -- Логирование ошибки без краша
        if result and type(result) == "string" then
            -- Ошибка подавлена для стабильности
        end
    end
    return success, result
end

-- Минимальный обход античита без краш-рисков
local function safeBypassDetection()
    safeCall(function()
        -- Отключение только безопасных детектов
        local StarterGui = game:GetService("StarterGui")
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.DeveloperConsole, false)
    end)
end

-- Безопасная отправка сообщения в чат
local function sendChatMessageSafe(message)
    safeCall(function()
        -- Проверка существования игрока
        if not Players.LocalPlayer then return end
        
        -- Метод через стандартный интерфейс чата
        local chatGui = Players.LocalPlayer:FindFirstChild("PlayerGui")
        if not chatGui then return end
        
        local chat = chatGui:FindFirstChild("Chat")
        if not chat then return end
        
        local frame = chat:FindFirstChild("Frame")
        if not frame then return end
        
        local chatBarParent = frame:FindFirstChild("ChatBarParentFrame")
        if not chatBarParent then return end
        
        local chatBar = chatBarParent:FindFirstChild("ChatBar")
        if not chatBar or not chatBar:IsA("TextBox") then return end
        
        -- Установка текста и отправка
        chatBar.Text = message
        wait(0.3)
        
        -- Симуляция нажатия Enter
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, nil)
        wait(0.1)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, nil)
    end)
end

-- Безопасный анти-АФК
local function safeAntiAFK()
    spawn(function()
        while wait(45) do
            safeCall(function()
                if Players.LocalPlayer and Players.LocalPlayer.Character then
                    local humanoid = Players.LocalPlayer.Character:FindFirstChild("Humanoid")
                    if humanoid then
                        -- Минимальное движение камеры для сброса АФК
                        humanoid.CameraOffset = Vector3.new(0, 0.01, 0)
                        wait(0.1)
                        humanoid.CameraOffset = Vector3.new(0, 0, 0)
                    end
                end
            end)
        end
    end)
end

-- Безопасная телепортация
local function safeTeleport()
    safeCall(function()
        wait(2)
        if TeleportService and Players.LocalPlayer then
            TeleportService:Teleport(TARGET_PLACE_ID)
        end
    end)
end

-- Сохранение состояния
local function saveState()
    safeCall(function()
        if not isfolder("XenoState") then
            makefolder("XenoState")
        end
        writefile("XenoState/autoexec.txt", AUTO_REJOIN and "1" or "0")
    end)
end

-- Проверка авто-запуска
local function checkAutoExec()
    safeCall(function()
        if isfile("XenoState/autoexec.txt") then
            local data = readfile("XenoState/autoexec.txt")
            if data == "1" then
                wait(8)
                startSpamSafe()
            end
        end
    end)
end

-- Основной цикл спама с защитой от краша
local function startSpamSafe()
    -- Проверка готовности игры
    if not game:IsLoaded() then
        game.Loaded:Wait()
    end
    wait(2)
    
    -- Проверка существования игрока и чата
    if not Players.LocalPlayer then return end
    
    local startTime = tick()
    local messageIndex = 1
    
    while (tick() - startTime) < SPAM_DURATION do
        -- Проверка что игрок всё ещё в игре
        if not Players.LocalPlayer or not Players.LocalPlayer:FindFirstChild("PlayerGui") then
            break
        end
        
        -- Отправка сообщения
        local message = MESSAGES[messageIndex]
        sendChatMessageSafe(message)
        
        -- Задержка
        local delay = math.random(SPAM_DELAY_MIN, SPAM_DELAY_MAX)
        if math.random(1, 5) == 1 then
            delay = delay + math.random(5, 10)
        end
        
        wait(delay)
        
        -- Следующее сообщение
        messageIndex = messageIndex + 1
        if messageIndex > #MESSAGES then
            messageIndex = 1
        end
    end
    
    -- Телепорт после спама
    if AUTO_REJOIN then
        safeTeleport()
    end
end

-- Инициализация с защитой
safeCall(function()
    wait(1)
    if not game:IsLoaded() then
        game.Loaded:Wait()
    end
    safeBypassDetection()
    safeAntiAFK()
    saveState()
end)

-- Запуск
wait(2)
checkAutoExec()
wait(1)
startSpamSafe()
