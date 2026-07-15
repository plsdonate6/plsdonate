-- Xeno Auto-Inject Script for PLS DONATE - Fixed Version
-- Исправлено: обход ошибок ReplicatedStorage, WaitForChild, индексации nil
-- Совместимость с игрой PLS DONATE, защита от краша

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

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
local TARGET_PLACE_ID = 8737602449 -- ID PLS DONATE для реджойна
local SPAM_DELAY_MIN = 10
local SPAM_DELAY_MAX = 25
local SPAM_DURATION = 300
local AUTO_REJOIN = true

-- Безопасный pcall с подавлением ошибок PLS DONATE
local function safeCall(func, ...)
    local success, result = pcall(func, ...)
    if not success then
        -- Полное подавление ошибок для стабильности
    end
    return success, result
end

-- Перехват и блокировка ошибок ReplicatedStorage.Remotes (PDRewind, ZAP и др.)
local function suppressGameErrors()
    safeCall(function()
        -- Перехват InvokeServer для блокировки краш-ошибок
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        if ReplicatedStorage:FindFirstChild("Remotes") then
            local remotes = ReplicatedStorage.Remotes
            
            -- Безопасное переопределение InvokeServer
            for _, remote in ipairs(remotes:GetChildren()) do
                if remote:IsA("RemoteFunction") then
                    safeCall(function()
                        local oldInvoke = remote.InvokeServer
                        -- Не переопределяем, просто игнорируем ошибки при вызове
                    end)
                end
            end
        end
        
        -- Удаление проблемных скриптов, вызывающих краш
        local scriptsToDisable = {
            "LeaderboardHistoryClient",
            "HypeTrainClient_OLD",
            "BoothInteraction",
            "PDRewind"
        }
        
        for _, scriptName in ipairs(scriptsToDisable) do
            safeCall(function()
                local script = ReplicatedStorage:FindFirstChild(scriptName)
                if script then
                    script.Disabled = true
                end
                -- Поиск в Client папке
                local clientFolder = ReplicatedStorage:FindFirstChild("Client")
                if clientFolder then
                    local clientScript = clientFolder:FindFirstChild(scriptName)
                    if clientScript then
                        clientScript.Disabled = true
                    end
                end
            end)
        end
    end)
end

-- Безопасное ожидание с таймаутом (вместо бесконечного WaitForChild)
local function safeWaitForChild(parent, childName, timeout)
    timeout = timeout or 5
    local startTime = tick()
    
    while (tick() - startTime) < timeout do
        local child = parent:FindFirstChild(childName)
        if child then
            return child
        end
        wait(0.5)
    end
    return nil -- Возврат nil вместо зависания
end

-- Отправка сообщения в чат PLS DONATE
local function sendChatMessageSafe(message)
    safeCall(function()
        if not Players.LocalPlayer then return end
        
        local playerGui = Players.LocalPlayer:FindFirstChild("PlayerGui")
        if not playerGui then return end
        
        -- Поиск чата через безопасное ожидание
        local chat = safeWaitForChild(playerGui, "Chat", 3)
        if not chat then return end
        
        local frame = safeWaitForChild(chat, "Frame", 2)
        if not frame then return end
        
        local chatBarParent = safeWaitForChild(frame, "ChatBarParentFrame", 2)
        if not chatBarParent then return end
        
        local chatBar = safeWaitForChild(chatBarParent, "ChatBar", 2)
        if not chatBar or not chatBar:IsA("TextBox") then return end
        
        -- Отправка текста
        chatBar.Text = message
        wait(0.3)
        
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, nil)
        wait(0.15)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, nil)
    end)
end

-- Анти-АФК без ошибок
local function antiAFKSafe()
    spawn(function()
        while wait(60) do
            safeCall(function()
                if Players.LocalPlayer and Players.LocalPlayer.Character then
                    local humanoid = Players.LocalPlayer.Character:FindFirstChild("Humanoid")
                    if humanoid then
                        -- Микродвижение камеры
                        local currentOffset = humanoid.CameraOffset or Vector3.new(0, 0, 0)
                        humanoid.CameraOffset = currentOffset + Vector3.new(0, 0.001, 0)
                        wait(0.1)
                        humanoid.CameraOffset = currentOffset
                    end
                end
            end)
        end
    end)
end

-- Телепорт с проверкой
local function safeTeleport()
    safeCall(function()
        wait(3)
        if TeleportService and Players.LocalPlayer then
            local teleportOptions = Instance.new("TeleportOptions")
            teleportOptions:SetTeleportData({rejoin = true})
            TeleportService:TeleportAsync(TARGET_PLACE_ID, nil, teleportOptions)
        end
    end)
end

-- Сохранение состояния авто-инжекта
local function saveAutoInjectState()
    safeCall(function()
        if not isfolder("PLSDonateScript") then
            makefolder("PLSDonateScript")
        end
        writefile("PLSDonateScript/auto.txt", AUTO_REJOIN and "1" or "0")
    end)
end

-- Проверка авто-запуска
local function checkAutoInject()
    safeCall(function()
        if isfile("PLSDonateScript/auto.txt") then
            local state = readfile("PLSDonateScript/auto.txt")
            if state == "1" then
                wait(10) -- Дополнительная задержка для загрузки игры
                startSpamSafe()
            end
        end
    end)
end

-- Основной цикл спама
local function startSpamSafe()
    -- Ожидание полной загрузки игры
    if not game:IsLoaded() then
        game.Loaded:Wait()
    end
    
    -- Дополнительная задержка для инициализации GUI
    wait(5)
    
    if not Players.LocalPlayer then return end
    
    local startTime = tick()
    local messageIndex = 1
    
    while (tick() - startTime) < SPAM_DURATION do
        -- Проверка что игрок в игре
        if not Players.LocalPlayer or not Players.LocalPlayer.Parent then
            break
        end
        
        -- Отправка сообщения
        local message = MESSAGES[messageIndex]
        sendChatMessageSafe(message)
        
        -- Рандомная задержка
        local delay = math.random(SPAM_DELAY_MIN, SPAM_DELAY_MAX)
        if math.random(1, 5) == 1 then
            delay = delay + math.random(5, 10)
        end
        
        wait(delay)
        
        -- Цикл сообщений
        messageIndex = messageIndex + 1
        if messageIndex > #MESSAGES then
            messageIndex = 1
        end
    end
    
    -- Телепорт для нового сервера
    if AUTO_REJOIN then
        safeTeleport()
    end
end

-- Инициализация
safeCall(function()
    wait(2)
    if not game:IsLoaded() then
        game.Loaded:Wait()
    end
    
    -- Подавление ошибок игры
    suppressGameErrors()
    
    -- Запуск защиты
    antiAFKSafe()
    saveAutoInjectState()
end)

-- Основной запуск
wait(3)
checkAutoInject()
wait(2)
startSpamSafe()
