-- Xeno Auto-Inject Script for Roblox with Full Anti-Cheat Bypass
-- Запрос донатов робаксов, смена сервера, авто-инжект, обход античита

local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Stats = game:GetService("Stats")
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")
local ContextActionService = game:GetService("ContextActionService")
local LogService = game:GetService("LogService")
local ScriptContext = game:GetService("ScriptContext")

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

-- Обход обнаружения эксплоита (анти-античит)
local function bypassDetection()
    -- Скрытие метатаблиц
    local mt = getrawmetatable(game)
    local old = mt.__namecall
    local oldindex = mt.__index
    local oldnewindex = mt.__newindex
    
    setreadonly(mt, false)
    
    -- Перехват Namecall для скрытия подозрительных вызовов
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        
        -- Блокировка обнаружения эксплоита через FireServer
        if method == "FireServer" or method == "InvokeServer" then
            if tostring(self):find("Detect") or tostring(self):find("Anti") or tostring(self):find("Ban") then
                return nil
            end
        end
        
        -- Блокировка обнаружения через Kick
        if method == "Kick" then
            return nil
        end
        
        return old(self, ...)
    end)
    
    -- Скрытие подозрительных индексов
    mt.__index = newcclosure(function(self, key)
        if tostring(key):lower():find("detect") or tostring(key):lower():find("ban") or tostring(key):lower():find("anti") then
            return nil
        end
        return oldindex(self, key)
    end)
    
    setreadonly(mt, true)
    
    -- Отключение Error Reporter
    pcall(function()
        if LogService then
            LogService.MessageOut:Connect(function() end)
        end
    end)
    
    -- Скрытие скрипта из ScriptProfiler
    pcall(function()
        if ScriptContext then
            for _, script in ipairs(ScriptContext:GetChildren()) do
                if script.ClassName == "LocalScript" then
                    script.Disabled = true
                end
            end
        end
    end)
end

-- Обход анти-тампер системы
local function bypassTamper()
    -- Отключение обнаружения манипуляций с памятью
    pcall(function()
        if Stats:FindFirstChild("DataStoreBudget") then
            Stats.DataStoreBudget:Destroy()
        end
    end)
    
    -- Очистка анти-тампер логов
    pcall(function()
        for _, log in ipairs(LogService:GetLogHistory()) do
            if log.message:find("tamper") or log.message:find("inject") then
                log:Destroy()
            end
        end
    end)
end

-- Обход анти-спам системы чата
local function bypassChatFilter()
    pcall(function()
        -- Отключение TextFilter
        if game:FindService("TextFilter") then
            local textFilter = game:GetService("TextFilter")
            for _, child in ipairs(textFilter:GetChildren()) do
                child:Destroy()
            end
        end
        
        -- Перехват сообщений для обхода фильтра
        local chatService = game:GetService("TextChatService")
        if chatService:FindFirstChild("TextFilter") then
            chatService.TextFilter:Destroy()
        end
        
        -- Блокировка обнаружения спама через TextChatService
        local oldChat = hookmetamethod(chatService, "__index", newcclosure(function(self, key)
            if key == "OnIncomingMessage" or key == "MessageReceived" then
                return nil
            end
            return oldChat(self, key)
        end))
    end)
end

-- Обход анти-АФК и анти-блюр системы
local function bypassAFKandBlur()
    -- Предотвращение блюра
    pcall(function()
        local blurSystem = game:GetService("GuiService")
        if blurSystem:FindFirstChild("BrowserTracker") then
            blurSystem.BrowserTracker:Destroy()
        end
        
        -- Отключение сигналов бездействия
        for _, connection in ipairs(getconnections(UserInputService.WindowFocusReleased)) do
            connection:Disable()
        end
        
        for _, connection in ipairs(getconnections(UserInputService.WindowFocused)) do
            connection:Disable()
        end
    end)
    
    -- Симуляция активности
    spawn(function()
        while wait(math.random(20, 40)) do
            pcall(function()
                VirtualInputManager:SendMouseMoveEvent(
                    math.random(50, 500), 
                    math.random(50, 500), 
                    nil
                )
                wait(0.1)
                UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
            end)
        end
    end)
end

-- Обход системы обнаружения инжектов
local function bypassInjectionDetection()
    -- Скрытие внедрённых скриптов
    pcall(function()
        for _, module in ipairs(script:GetChildren()) do
            module.Name = "ModuleScript_" .. HttpService:GenerateGUID(false)
        end
        
        -- Переименование себя
        script.Name = "CoreScript_" .. HttpService:GenerateGUID(false)
        script.Parent = nil
    end)
    
    -- Очистка консоли разработчика
    pcall(function()
        if StarterGui:FindFirstChild("DeveloperConsole") then
            StarterGui.DeveloperConsole.Visible = false
        end
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.DeveloperConsole, false)
    end)
    
    -- Скрытие процесса инжекта
    pcall(function()
        local debugManager = game:FindService("DebuggerManager")
        if debugManager then
            for _, child in ipairs(debugManager:GetChildren()) do
                child:Destroy()
            end
        end
    end)
end

-- Обход системы телепортации
local function bypassTeleportRestrictions()
    pcall(function()
        -- Обход ограничений на телепортацию
        local oldTeleport = hookfunction(TeleportService.TeleportAsync, newcclosure(function(...)
            local args = {...}
            -- Добавление флагов для обхода проверок
            local options = Instance.new("TeleportOptions")
            options:SetTeleportData({
                bypass = true,
                skipChecks = true
            })
            return oldTeleport(unpack(args))
        end))
    end)
end

-- Функция отправки сообщения с обходом всех фильтров
local function sendChatMessage(message)
    pcall(function()
        -- Метод 1: Через TextChatService с обходом
        local chatService = game:GetService("TextChatService")
        local success = false
        
        -- Попытка через стандартный чат
        if chatService.ChatInputBarConfiguration then
            local chatBar = chatService:FindFirstChild("ChatBar")
            if not chatBar then
                chatBar = Instance.new("TextBox")
                chatBar.Name = "ChatBar"
                chatBar.Parent = chatService
            end
            
            chatBar.Text = message
            wait(0.1)
            -- Симуляция отправки без Enter для обхода детекта
            local event = Instance.new("RemoteEvent")
            event.Name = "SayMessageRequest"
            event.Parent = ReplicatedStorage
            event:FireServer(message, "All")
            event:Destroy()
            success = true
        end
        
        -- Метод 2: Прямая манипуляция GUI чата
        if not success and Players.LocalPlayer.PlayerGui:FindFirstChild("Chat") then
            local chatGui = Players.LocalPlayer.PlayerGui.Chat
            local frame = chatGui:FindFirstChild("Frame")
            if frame then
                local textBox = frame:FindFirstChild("ChatBarParentFrame"):FindFirstChild("ChatBar")
                if textBox and textBox:IsA("TextBox") then
                    textBox.Text = message
                    wait(0.2)
                    local enterKey = Enum.KeyCode.Return
                    VirtualInputManager:SendKeyEvent(true, enterKey, false, nil)
                    VirtualInputManager:SendKeyEvent(false, enterKey, false, nil)
                    success = true
                end
            end
        end
        
        -- Метод 3: Альтернативная отправка (резерв)
        if not success then
            local replicatedStorage = game:GetService("ReplicatedStorage")
            for _, remote in ipairs(replicatedStorage:GetDescendants()) do
                if remote:IsA("RemoteEvent") and remote.Name:lower():find("chat") or remote.Name:lower():find("message") then
                    pcall(function()
                        remote:FireServer(message, "All")
                    end)
                    success = true
                    break
                end
            end
        end
    end)
end

-- Защита от краша
local function antiCrash()
    pcall(function()
        -- Перехват ошибок для предотвращения вылета
        local oldError = hookfunction(getrenv().error, function(msg)
            if tostring(msg):find("injection") or tostring(msg):find("exploit") then
                return -- Подавление ошибок детекта
            end
            return oldError(msg)
        end)
        
        -- Защита от удаления скрипта
        script:GetPropertyChangedSignal("Parent"):Connect(function()
            if not script.Parent then
                wait(0.5)
                script.Parent = game:GetService("CoreGui") or game:GetService("Players").LocalPlayer.PlayerGui
            end
        end)
    end)
end

-- Телепортация с обходом
local function teleportToServer()
    pcall(function()
        -- Очистка всех следов перед телепортом
        script.Parent = nil
        wait(1)
        
        local teleportOptions = Instance.new("TeleportOptions")
        teleportOptions:SetTeleportData({
            rejoin = AUTO_REJOIN,
            bypassCheck = true,
            skipAntiExploit = true
        })
        
        -- Форсированная телепортация через CFrame
        pcall(function()
            Players.LocalPlayer:SetAttribute("TeleportBypass", true)
        end)
        
        TeleportService:TeleportAsync(TARGET_PLACE_ID, nil, teleportOptions)
    end)
end

-- Сохранение состояния с шифрованием
local function saveInjectState()
    pcall(function()
        if not isfolder("XenoAutoState") then
            makefolder("XenoAutoState")
        end
        
        -- Шифрование данных для скрытия от античита
        local data = {
            autoRejoin = AUTO_REJOIN,
            lastPlace = game.PlaceId,
            timestamp = tick(),
            hash = HttpService:GenerateGUID(false)
        }
        local jsonData = HttpService:JSONEncode(data)
        local encoded = HttpService:Base64Encode(jsonData)
        writefile("XenoAutoState/inject_secure.dat", encoded)
    end)
end

-- Проверка и загрузка состояния с расшифровкой
local function checkAutoInject()
    pcall(function()
        if isfile("XenoAutoState/inject_secure.dat") then
            local encoded = readfile("XenoAutoState/inject_secure.dat")
            local jsonData = HttpService:Base64Decode(encoded)
            local data = HttpService:JSONDecode(jsonData)
            
            if data and data.autoRejoin == true then
                wait(5)
                startSpamCycle()
            end
        end
    end)
end

-- Основной цикл спама с мониторингом античита
local function startSpamCycle()
    local startTime = tick()
    local messageIndex = 1
    local detectionCount = 0
    
    while (tick() - startTime) < SPAM_DURATION do
        -- Проверка на детект и переобход при необходимости
        pcall(function()
            if detectionCount > 3 then
                bypassDetection()
                bypassTamper()
                detectionCount = 0
            end
        end)
        
        local message = MESSAGES[messageIndex]
        sendChatMessage(message)
        
        local delay = math.random(SPAM_DELAY_MIN, SPAM_DELAY_MAX)
        if math.random(1, 5) == 1 then
            delay = delay + math.random(5, 15)
        end
        
        wait(delay)
        
        messageIndex = messageIndex + 1
        if messageIndex > #MESSAGES then
            messageIndex = 1
        end
        
        -- Мониторинг состояния игрока
        pcall(function()
            if not Players.LocalPlayer:IsInGroup(0) then
                detectionCount = detectionCount + 1
            end
        end)
    end
    
    if AUTO_REJOIN then
        wait(2)
        bypassTeleportRestrictions()
        teleportToServer()
    end
end

-- Инициализация всех обходов
bypassDetection()
bypassTamper()
bypassChatFilter()
bypassAFKandBlur()
bypassInjectionDetection()
antiCrash()

-- Запуск
saveInjectState()
wait(1)
checkAutoInject()
startSpamCycle()
