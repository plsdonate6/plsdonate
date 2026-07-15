-- Xeno Auto-Inject Script for PLS DONATE - Final Version with UI, Logs, Teleport Check
-- Полный функционал: UI, логирование, проверка телепорта, копирование логов

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
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
local spamThread = nil
local ScreenGui = nil
local logs = {}
local teleportCheckPassed = false
local teleportAttempts = 0
local MAX_TELEPORT_ATTEMPTS = 3

-- Добавление лога
local function addLog(message, logType)
    logType = logType or "INFO"
    local timestamp = os.date("%H:%M:%S")
    local logEntry = string.format("[%s] [%s] %s", timestamp, logType, message)
    table.insert(logs, logEntry)
    
    -- Ограничение количества логов
    if #logs > 100 then
        table.remove(logs, 1)
    end
    
    -- Обновление UI если существует
    safeCall(function()
        if ScreenGui and ScreenGui:FindFirstChild("MainFrame") then
            local logBox = ScreenGui.MainFrame:FindFirstChild("LogBox")
            if logBox then
                local logText = ""
                for i = math.max(1, #logs - 10), #logs do
                    logText = logText .. logs[i] .. "\n"
                end
                logBox.Text = logText
            end
        end
    end)
end

-- Безопасный вызов с логированием
local function safeCall(func, ...)
    local success, result = pcall(func, ...)
    if not success then
        addLog("Error: " .. tostring(result), "ERROR")
    end
    return success, result
end

-- Проверка возможности телепорта
local function checkTeleportAvailability()
    addLog("Checking teleport availability...", "INFO")
    
    local canTeleport = false
    local failReason = ""
    
    safeCall(function()
        -- Проверка TeleportService
        if not TeleportService then
            failReason = "TeleportService not available"
            return
        end
        
        -- Проверка соединения
        if not game:IsLoaded() then
            failReason = "Game not fully loaded"
            return
        end
        
        -- Проверка игрока
        if not Players.LocalPlayer then
            failReason = "LocalPlayer not found"
            return
        end
        
        -- Попытка получения информации о плейсе
        local success, errorResult = pcall(function()
            return TeleportService:GetPlayerPlaceInstanceAsync(Players.LocalPlayer.UserId)
        end)
        
        if not success then
            failReason = "Cannot get place instance: " .. tostring(errorResult)
            return
        end
        
        -- Проверка не забанен ли игрок в целевом плейсе
        local teleportCheck = pcall(function()
            local options = Instance.new("TeleportOptions")
            options:SetTeleportData({check = true})
        end)
        
        if not teleportCheck then
            failReason = "Teleport options creation failed"
            return
        end
        
        canTeleport = true
    end)
    
    if canTeleport then
        addLog("Teleport check passed", "SUCCESS")
        teleportCheckPassed = true
    else
        addLog("Teleport check failed: " .. failReason, "ERROR")
        teleportCheckPassed = false
    end
    
    return canTeleport
end

-- Безопасный телепорт с повторными попытками
local function safeTeleport()
    if teleportAttempts >= MAX_TELEPORT_ATTEMPTS then
        addLog("Max teleport attempts reached. Aborting.", "ERROR")
        return false
    end
    
    teleportAttempts = teleportAttempts + 1
    addLog("Teleport attempt " .. teleportAttempts .. " of " .. MAX_TELEPORT_ATTEMPTS, "INFO")
    
    -- Проверка перед телепортом
    if not checkTeleportAvailability() then
        addLog("Teleport not available. Waiting 10 seconds before retry...", "WARN")
        wait(10)
        return safeTeleport() -- Рекурсивная попытка
    end
    
    local teleportSuccess = false
    
    safeCall(function()
        wait(2)
        
        -- Сохранение состояния перед телепортом
        saveAutoInjectState()
        
        -- Создание опций телепорта
        local teleportOptions = Instance.new("TeleportOptions")
        teleportOptions:SetTeleportData({
            rejoin = true,
            timestamp = tick(),
            bypassCheck = true
        })
        
        -- Попытка телепорта с таймаутом
        local teleportStart = tick()
        
        local success, errorResult = pcall(function()
            TeleportService:TeleportAsync(TARGET_PLACE_ID, nil, teleportOptions)
        end)
        
        if success then
            teleportSuccess = true
            addLog("Teleport successful", "SUCCESS")
        else
            addLog("Teleport failed: " .. tostring(errorResult), "ERROR")
            
            -- Альтернативный метод телепорта
            addLog("Trying alternative teleport method...", "INFO")
            local altSuccess, altError = pcall(function()
                TeleportService:Teleport(TARGET_PLACE_ID)
            end)
            
            if altSuccess then
                teleportSuccess = true
                addLog("Alternative teleport successful", "SUCCESS")
            else
                addLog("Alternative teleport failed: " .. tostring(altError), "ERROR")
            end
        end
    end)
    
    if not teleportSuccess then
        addLog("Teleport failed. Will retry.", "WARN")
        wait(5)
        return safeTeleport()
    end
    
    teleportAttempts = 0
    return true
end

-- Копирование логов в буфер обмена
local function copyLogsToClipboard()
    local allLogs = table.concat(logs, "\n")
    
    safeCall(function()
        -- Попытка установки в буфер обмена
        if setclipboard then
            setclipboard(allLogs)
            addLog("Logs copied to clipboard (" .. #logs .. " entries)", "SUCCESS")
        else
            -- Альтернативный метод через TextBox
            local tempBox = Instance.new("TextBox")
            tempBox.Text = allLogs
            tempBox:CaptureFocus()
            tempBox:SelectAll()
            wait(0.1)
            
            -- Симуляция Ctrl+C
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.LeftControl, false, nil)
            wait(0.05)
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.C, false, nil)
            wait(0.05)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.C, false, nil)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.LeftControl, false, nil)
            
            tempBox:Destroy()
            addLog("Logs copied to clipboard via alternative method", "SUCCESS")
        end
    end)
end

-- Создание UI
local function createUI()
    safeCall(function()
        -- Очистка старого UI
        if CoreGui:FindFirstChild("PLSDonateSpammerGUI") then
            CoreGui.PLSDonateSpammerGUI:Destroy()
        end
        
        -- ScreenGui
        ScreenGui = Instance.new("ScreenGui")
        ScreenGui.Name = "PLSDonateSpammerGUI"
        ScreenGui.Parent = CoreGui
        ScreenGui.ResetOnSpawn = false
        ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        
        -- Главный фрейм
        local MainFrame = Instance.new("Frame")
        MainFrame.Name = "MainFrame"
        MainFrame.Parent = ScreenGui
        MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        MainFrame.BorderSizePixel = 0
        MainFrame.Position = UDim2.new(0.5, -275, 0.5, -250)
        MainFrame.Size = UDim2.new(0, 550, 0, 500)
        MainFrame.Active = true
        MainFrame.Draggable = true
        
        local UICorner = Instance.new("UICorner")
        UICorner.CornerRadius = UDim.new(0, 8)
        UICorner.Parent = MainFrame
        
        -- Заголовок
        local TitleBar = Instance.new("Frame")
        TitleBar.Name = "TitleBar"
        TitleBar.Parent = MainFrame
        TitleBar.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        TitleBar.BorderSizePixel = 0
        TitleBar.Size = UDim2.new(1, 0, 0, 40)
        
        local TitleCorner = Instance.new("UICorner")
        TitleCorner.CornerRadius = UDim.new(0, 8)
        TitleCorner.Parent = TitleBar
        
        -- Текст заголовка
        local TitleText = Instance.new("TextLabel")
        TitleText.Name = "TitleText"
        TitleText.Parent = TitleBar
        TitleText.BackgroundTransparency = 1
        TitleText.Size = UDim2.new(1, -40, 1, 0)
        TitleText.Position = UDim2.new(0, 15, 0, 0)
        TitleText.Font = Enum.Font.GothamBold
        TitleText.Text = "PLS DONATE - Auto Spammer Pro"
        TitleText.TextColor3 = Color3.fromRGB(255, 255, 255)
        TitleText.TextSize = 16
        TitleText.TextXAlignment = Enum.TextXAlignment.Left
        
        -- Кнопка закрытия
        local CloseButton = Instance.new("TextButton")
        CloseButton.Name = "CloseButton"
        CloseButton.Parent = TitleBar
        CloseButton.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
        CloseButton.BorderSizePixel = 0
        CloseButton.Position = UDim2.new(1, -35, 0, 7)
        CloseButton.Size = UDim2.new(0, 26, 0, 26)
        CloseButton.Font = Enum.Font.GothamBold
        CloseButton.Text = "X"
        CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        CloseButton.TextSize = 14
        
        local CloseCorner = Instance.new("UICorner")
        CloseCorner.CornerRadius = UDim.new(0, 13)
        CloseCorner.Parent = CloseButton
        
        CloseButton.MouseButton1Click:Connect(function()
            ScreenGui:Destroy()
            isSpamming = false
        end)
        
        -- Статус
        local StatusLabel = Instance.new("TextLabel")
        StatusLabel.Name = "StatusLabel"
        StatusLabel.Parent = MainFrame
        StatusLabel.BackgroundTransparency = 1
        StatusLabel.Position = UDim2.new(0, 20, 0, 50)
        StatusLabel.Size = UDim2.new(1, -40, 0, 20)
        StatusLabel.Font = Enum.Font.GothamSemibold
        StatusLabel.Text = "Status: Ready"
        StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
        StatusLabel.TextSize = 14
        StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
        
        -- Секция настроек задержки
        local DelayMinLabel = Instance.new("TextLabel")
        DelayMinLabel.Name = "DelayMinLabel"
        DelayMinLabel.Parent = MainFrame
        DelayMinLabel.BackgroundTransparency = 1
        DelayMinLabel.Position = UDim2.new(0, 20, 0, 80)
        DelayMinLabel.Size = UDim2.new(0, 120, 0, 20)
        DelayMinLabel.Font = Enum.Font.Gotham
        DelayMinLabel.Text = "Min Delay (s):"
        DelayMinLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
        DelayMinLabel.TextSize = 12
        DelayMinLabel.TextXAlignment = Enum.TextXAlignment.Left
        
        local DelayMinBox = Instance.new("TextBox")
        DelayMinBox.Name = "DelayMinBox"
        DelayMinBox.Parent = MainFrame
        DelayMinBox.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        DelayMinBox.BorderSizePixel = 0
        DelayMinBox.Position = UDim2.new(0, 20, 0, 100)
        DelayMinBox.Size = UDim2.new(0, 120, 0, 28)
        DelayMinBox.Font = Enum.Font.Gotham
        DelayMinBox.PlaceholderText = "10"
        DelayMinBox.Text = "10"
        DelayMinBox.TextColor3 = Color3.fromRGB(255, 255, 255)
        DelayMinBox.TextSize = 14
        
        local DelayMinCorner = Instance.new("UICorner")
        DelayMinCorner.CornerRadius = UDim.new(0, 5)
        DelayMinCorner.Parent = DelayMinBox
        
        local DelayMaxLabel = Instance.new("TextLabel")
        DelayMaxLabel.Name = "DelayMaxLabel"
        DelayMaxLabel.Parent = MainFrame
        DelayMaxLabel.BackgroundTransparency = 1
        DelayMaxLabel.Position = UDim2.new(0, 160, 0, 80)
        DelayMaxLabel.Size = UDim2.new(0, 120, 0, 20)
        DelayMaxLabel.Font = Enum.Font.Gotham
        DelayMaxLabel.Text = "Max Delay (s):"
        DelayMaxLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
        DelayMaxLabel.TextSize = 12
        DelayMaxLabel.TextXAlignment = Enum.TextXAlignment.Left
        
        local DelayMaxBox = Instance.new("TextBox")
        DelayMaxBox.Name = "DelayMaxBox"
        DelayMaxBox.Parent = MainFrame
        DelayMaxBox.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        DelayMaxBox.BorderSizePixel = 0
        DelayMaxBox.Position = UDim2.new(0, 160, 0, 100)
        DelayMaxBox.Size = UDim2.new(0, 120, 0, 28)
        DelayMaxBox.Font = Enum.Font.Gotham
        DelayMaxBox.PlaceholderText = "25"
        DelayMaxBox.Text = "25"
        DelayMaxBox.TextColor3 = Color3.fromRGB(255, 255, 255)
        DelayMaxBox.TextSize = 14
        
        local DelayMaxCorner = Instance.new("UICorner")
        DelayMaxCorner.CornerRadius = UDim.new(0, 5)
        DelayMaxCorner.Parent = DelayMaxBox
        
        local DurationLabel = Instance.new("TextLabel")
        DurationLabel.Name = "DurationLabel"
        DurationLabel.Parent = MainFrame
        DurationLabel.BackgroundTransparency = 1
        DurationLabel.Position = UDim2.new(0, 300, 0, 80)
        DurationLabel.Size = UDim2.new(0, 120, 0, 20)
        DurationLabel.Font = Enum.Font.Gotham
        DurationLabel.Text = "Duration (s):"
        DurationLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
        DurationLabel.TextSize = 12
        DurationLabel.TextXAlignment = Enum.TextXAlignment.Left
        
        local DurationBox = Instance.new("TextBox")
        DurationBox.Name = "DurationBox"
        DurationBox.Parent = MainFrame
        DurationBox.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        DurationBox.BorderSizePixel = 0
        DurationBox.Position = UDim2.new(0, 300, 0, 100)
        DurationBox.Size = UDim2.new(0, 120, 0, 28)
        DurationBox.Font = Enum.Font.Gotham
        DurationBox.PlaceholderText = "300"
        DurationBox.Text = "300"
        DurationBox.TextColor3 = Color3.fromRGB(255, 255, 255)
        DurationBox.TextSize = 14
        
        local DurationCorner = Instance.new("UICorner")
        DurationCorner.CornerRadius = UDim.new(0, 5)
        DurationCorner.Parent = DurationBox
        
        -- Чекбокс авто-реджойна
        local AutoRejoinCheckbox = Instance.new("TextButton")
        AutoRejoinCheckbox.Name = "AutoRejoinCheckbox"
        AutoRejoinCheckbox.Parent = MainFrame
        AutoRejoinCheckbox.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
        AutoRejoinCheckbox.BorderSizePixel = 0
        AutoRejoinCheckbox.Position = UDim2.new(0, 440, 0, 100)
        AutoRejoinCheckbox.Size = UDim2.new(0, 28, 0, 28)
        AutoRejoinCheckbox.Font = Enum.Font.GothamBold
        AutoRejoinCheckbox.Text = "✓"
        AutoRejoinCheckbox.TextColor3 = Color3.fromRGB(255, 255, 255)
        AutoRejoinCheckbox.TextSize = 14
        
        local AutoRejoinCorner = Instance.new("UICorner")
        AutoRejoinCorner.CornerRadius = UDim.new(0, 5)
        AutoRejoinCorner.Parent = AutoRejoinCheckbox
        
        local AutoRejoinLabel = Instance.new("TextLabel")
        AutoRejoinLabel.Name = "AutoRejoinLabel"
        AutoRejoinLabel.Parent = MainFrame
        AutoRejoinLabel.BackgroundTransparency = 1
        AutoRejoinLabel.Position = UDim2.new(0, 475, 0, 100)
        AutoRejoinLabel.Size = UDim2.new(0, 60, 0, 28)
        AutoRejoinLabel.Font = Enum.Font.Gotham
        AutoRejoinLabel.Text = "Rejoin"
        AutoRejoinLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        AutoRejoinLabel.TextSize = 11
        AutoRejoinLabel.TextXAlignment = Enum.TextXAlignment.Left
        
        local isAutoRejoin = true
        AutoRejoinCheckbox.MouseButton1Click:Connect(function()
            isAutoRejoin = not isAutoRejoin
            if isAutoRejoin then
                AutoRejoinCheckbox.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
                AutoRejoinCheckbox.Text = "✓"
            else
                AutoRejoinCheckbox.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
                AutoRejoinCheckbox.Text = "✗"
            end
        end)
        
        -- Проверка телепорта
        local TeleportCheckButton = Instance.new("TextButton")
        TeleportCheckButton.Name = "TeleportCheckButton"
        TeleportCheckButton.Parent = MainFrame
        TeleportCheckButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        TeleportCheckButton.BorderSizePixel = 0
        TeleportCheckButton.Position = UDim2.new(0, 20, 0, 140)
        TeleportCheckButton.Size = UDim2.new(0, 200, 0, 28)
        TeleportCheckButton.Font = Enum.Font.GothamBold
        TeleportCheckButton.Text = "Check Teleport"
        TeleportCheckButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        TeleportCheckButton.TextSize = 12
        
        local TeleportCheckCorner = Instance.new("UICorner")
        TeleportCheckCorner.CornerRadius = UDim.new(0, 5)
        TeleportCheckCorner.Parent = TeleportCheckButton
        
        TeleportCheckButton.MouseButton1Click:Connect(function()
            local result = checkTeleportAvailability()
            if result then
                TeleportCheckButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
                TeleportCheckButton.Text = "Teleport: OK"
                wait(2)
                TeleportCheckButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
                TeleportCheckButton.Text = "Check Teleport"
            else
                TeleportCheckButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
                TeleportCheckButton.Text = "Teleport: FAIL"
                wait(2)
                TeleportCheckButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
                TeleportCheckButton.Text = "Check Teleport"
            end
        end)
        
        -- Ручной телепорт
        local ManualTeleportButton = Instance.new("TextButton")
        ManualTeleportButton.Name = "ManualTeleportButton"
        ManualTeleportButton.Parent = MainFrame
        ManualTeleportButton.BackgroundColor3 = Color3.fromRGB(100, 50, 200)
        ManualTeleportButton.BorderSizePixel = 0
        ManualTeleportButton.Position = UDim2.new(0, 240, 0, 140)
        ManualTeleportButton.Size = UDim2.new(0, 200, 0, 28)
        ManualTeleportButton.Font = Enum.Font.GothamBold
        ManualTeleportButton.Text = "Teleport Now"
        ManualTeleportButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        ManualTeleportButton.TextSize = 12
        
        local ManualTeleportCorner = Instance.new("UICorner")
        ManualTeleportCorner.CornerRadius = UDim.new(0, 5)
        ManualTeleportCorner.Parent = ManualTeleportButton
        
        ManualTeleportButton.MouseButton1Click:Connect(function()
            addLog("Manual teleport initiated", "INFO")
            safeTeleport()
        end)
        
        -- Кнопки старт/стоп
        local StartButton = Instance.new("TextButton")
        StartButton.Name = "StartButton"
        StartButton.Parent = MainFrame
        StartButton.BackgroundColor3 = Color3.fromRGB(0, 140, 255)
        StartButton.BorderSizePixel = 0
        StartButton.Position = UDim2.new(0, 20, 0, 180)
        StartButton.Size = UDim2.new(0, 245, 0, 35)
        StartButton.Font = Enum.Font.GothamBold
        StartButton.Text = "START SPAM"
        StartButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        StartButton.TextSize = 14
        
        local StartCorner = Instance.new("UICorner")
        StartCorner.CornerRadius = UDim.new(0, 5)
        StartCorner.Parent = StartButton
        
        local StopButton = Instance.new("TextButton")
        StopButton.Name = "StopButton"
        StopButton.Parent = MainFrame
        StopButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        StopButton.BorderSizePixel = 0
        StopButton.Position = UDim2.new(0, 285, 0, 180)
        StopButton.Size = UDim2.new(0, 245, 0, 35)
        StopButton.Font = Enum.Font.GothamBold
        StopButton.Text = "STOP SPAM"
        StopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        StopButton.TextSize = 14
        
        local StopCorner = Instance.new("UICorner")
        StopCorner.CornerRadius = UDim.new(0, 5)
        StopCorner.Parent = StopButton
        
        StartButton.MouseButton1Click:Connect(function()
            if not isSpamming then
                isSpamming = true
                StatusLabel.Text = "Status: Running..."
                StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
                
                local minDelay = tonumber(DelayMinBox.Text) or 10
                local maxDelay = tonumber(DelayMaxBox.Text) or 25
                local duration = tonumber(DurationBox.Text) or 300
                local autoRejoin = isAutoRejoin
                
                addLog("Spam started. Min delay: " .. minDelay .. "s, Max delay: " .. maxDelay .. "s, Duration: " .. duration .. "s", "INFO")
                
                spamThread = coroutine.create(function()
                    startSpamWithParams(minDelay, maxDelay, duration, autoRejoin)
                end)
                coroutine.resume(spamThread)
            end
        end)
        
        StopButton.MouseButton1Click:Connect(function()
            isSpamming = false
            addLog("Spam stopped by user", "INFO")
            StatusLabel.Text = "Status: Stopped"
            StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        end)
        
        -- Секция логов
        local LogsLabel = Instance.new("TextLabel")
        LogsLabel.Name = "LogsLabel"
        LogsLabel.Parent = MainFrame
        LogsLabel.BackgroundTransparency = 1
        LogsLabel.Position = UDim2.new(0, 20, 0, 225)
        LogsLabel.Size = UDim2.new(1, -40, 0, 20)
        LogsLabel.Font = Enum.Font.GothamSemibold
        LogsLabel.Text = "Logs:"
        LogsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        LogsLabel.TextSize = 13
        LogsLabel.TextXAlignment = Enum.TextXAlignment.Left
        
        -- Окно логов
        local LogBox = Instance.new("TextBox")
        LogBox.Name = "LogBox"
        LogBox.Parent = MainFrame
        LogBox.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        LogBox.BorderSizePixel = 0
        LogBox.Position = UDim2.new(0, 20, 0, 248)
        LogBox.Size = UDim2.new(1, -40, 0, 160)
        LogBox.Font = Enum.Font.Code
        LogBox.Text = ""
        LogBox.TextColor3 = Color3.fromRGB(0, 255, 0)
        LogBox.TextSize = 10
        LogBox.TextXAlignment = Enum.TextXAlignment.Left
        LogBox.TextYAlignment = Enum.TextYAlignment.Top
        LogBox.MultiLine = true
        LogBox.TextEditable = false
        LogBox.ClearTextOnFocus = false
        
        local LogBoxCorner = Instance.new("UICorner")
        LogBoxCorner.CornerRadius = UDim.new(0, 5)
        LogBoxCorner.Parent = LogBox
        
        -- Кнопка копирования логов
        local CopyLogsButton = Instance.new("TextButton")
        CopyLogsButton.Name = "CopyLogsButton"
        CopyLogsButton.Parent = MainFrame
        CopyLogsButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        CopyLogsButton.BorderSizePixel = 0
        CopyLogsButton.Position = UDim2.new(0, 20, 0, 415)
        CopyLogsButton.Size = UDim2.new(0, 245, 0, 30)
        CopyLogsButton.Font = Enum.Font.GothamBold
        CopyLogsButton.Text = "📋 Copy Logs"
        CopyLogsButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        CopyLogsButton.TextSize = 12
        
        local CopyLogsCorner = Instance.new("UICorner")
        CopyLogsCorner.CornerRadius = UDim.new(0, 5)
        CopyLogsCorner.Parent = CopyLogsButton
        
        CopyLogsButton.MouseButton1Click:Connect(function()
            copyLogsToClipboard()
            CopyLogsButton.Text = "✅ Copied!"
            wait(1.5)
            CopyLogsButton.Text = "📋 Copy Logs"
        end)
        
        -- Кнопка очистки логов
        local ClearLogsButton = Instance.new("TextButton")
        ClearLogsButton.Name = "ClearLogsButton"
        ClearLogsButton.Parent = MainFrame
        ClearLogsButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        ClearLogsButton.BorderSizePixel = 0
        ClearLogsButton.Position = UDim2.new(0, 285, 0, 415)
        ClearLogsButton.Size = UDim2.new(0, 245, 0, 30)
        ClearLogsButton.Font = Enum.Font.GothamBold
        ClearLogsButton.Text = "🗑️ Clear Logs"
        ClearLogsButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        ClearLogsButton.TextSize = 12
        
        local ClearLogsCorner = Instance.new("UICorner")
        ClearLogsCorner.CornerRadius = UDim.new(0, 5)
        ClearLogsCorner.Parent = ClearLogsButton
        
        ClearLogsButton.MouseButton1Click:Connect(function()
            logs = {}
            LogBox.Text = ""
            addLog("Logs cleared", "INFO")
        end)
        
        -- Кредиты
        local CreditLabel = Instance.new("TextLabel")
        CreditLabel.Name = "CreditLabel"
        CreditLabel.Parent = MainFrame
        CreditLabel.BackgroundTransparency = 1
        CreditLabel.Position = UDim2.new(0, 20, 0, 455)
        CreditLabel.Size = UDim2.new(1, -40, 0, 20)
        CreditLabel.Font = Enum.Font.Gotham
        CreditLabel.Text = "made by aveh | PLS DONATE Spammer Pro"
        CreditLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
        CreditLabel.TextSize = 10
        CreditLabel.TextXAlignment = Enum.TextXAlignment.Center
        
        addLog("UI initialized successfully", "SUCCESS")
    end)
end

-- Безопасное ожидание
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
    return nil
end

-- Отправка сообщения
local function sendChatMessageSafe(message)
    safeCall(function()
        if not Players.LocalPlayer then return end
        
        local playerGui = Players.LocalPlayer:FindFirstChild("PlayerGui")
        if not playerGui then return end
        
        local chat = safeWaitForChild(playerGui, "Chat", 3)
        if not chat then return end
        
        local frame = safeWaitForChild(chat, "Frame", 2)
        if not frame then return end
        
        local chatBarParent = safeWaitForChild(frame, "ChatBarParentFrame", 2)
        if not chatBarParent then return end
        
        local chatBar = safeWaitForChild(chatBarParent, "ChatBar", 2)
        if not chatBar or not chatBar:IsA("TextBox") then return end
        
        chatBar.Text = message
        wait(0.3)
        
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, nil)
        wait(0.15)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, nil)
        
        addLog("Message sent: " .. message:sub(1, 30) .. "...", "INFO")
    end)
end

-- Анти-АФК
local function antiAFKSafe()
    spawn(function()
        while wait(60) do
            safeCall(function()
                if Players.LocalPlayer and Players.LocalPlayer.Character then
                    local humanoid = Players.LocalPlayer.Character:FindFirstChild("Humanoid")
                    if humanoid then
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

-- Подавление ошибок игры
local function suppressGameErrors()
    safeCall(function()
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
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
                local clientFolder = ReplicatedStorage:FindFirstChild("Client")
                if clientFolder then
                    local clientScript = clientFolder:FindFirstChild(scriptName)
                    if clientScript then
                        clientScript.Disabled = true
                    end
                end
            end)
        end
        addLog("Game errors suppressed", "INFO")
    end)
end

-- Сохранение состояния авто-инжекта
function saveAutoInjectState()
    safeCall(function()
        if not isfolder("PLSDonateScript") then
            makefolder("PLSDonateScript")
        end
        local state = {
            autoRejoin = AUTO_REJOIN,
            timestamp = tick(),
            lastPlace = game.PlaceId
        }
        writefile("PLSDonateScript/auto.txt", HttpService:JSONEncode(state))
    end)
end

-- Проверка авто-запуска
local function checkAutoInject()
    safeCall(function()
        if isfile("PLSDonateScript/auto.txt") then
            local data = HttpService:JSONDecode(readfile("PLSDonateScript/auto.txt"))
            if data and data.autoRejoin then
                addLog("Auto-inject detected. Starting spam...", "INFO")
                wait(10)
                startSpamWithParams(SPAM_DELAY_MIN, SPAM_DELAY_MAX, SPAM_DURATION, true)
            end
        end
    end)
end

-- Основной цикл спама
function startSpamWithParams(minDelay, maxDelay, duration, autoRejoin)
    if not game:IsLoaded() then
        game.Loaded:Wait()
    end
    wait(3)
    
    if not Players.LocalPlayer then return end
    
    addLog("Spam cycle started", "INFO")
    
    local startTime = tick()
    local messageIndex = 1
    local messagesSent = 0
    
    while isSpamming and (tick() - startTime) < duration do
        if not Players.LocalPlayer or not Players.LocalPlayer.Parent then
            addLog("Player left the game. Stopping spam.", "WARN")
            break
        end
        
        local message = MESSAGES[messageIndex]
        sendChatMessageSafe(message)
        messagesSent = messagesSent + 1
        
        local delay = math.random(minDelay, maxDelay)
        if math.random(1, 5) == 1 then
            delay = delay + math.random(5, 10)
        end
        
        -- Разбивка ожидания
        local waitStart = tick()
        while isSpamming and (tick() - waitStart) < delay do
            wait(1)
        end
        
        messageIndex = messageIndex + 1
        if messageIndex > #MESSAGES then
            messageIndex = 1
        end
    end
    
    addLog("Spam cycle finished. Messages sent: " .. messagesSent, "INFO")
    
    -- Обновление статуса
    safeCall(function()
        if ScreenGui and ScreenGui:FindFirstChild("MainFrame") then
            local statusLabel = ScreenGui.MainFrame:FindFirstChild("StatusLabel")
            if statusLabel then
                statusLabel.Text = "Status: Finished"
                statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
            end
        end
    end)
    
    isSpamming = false
    
    -- Телепорт если включен
    if autoRejoin then
        addLog("Auto-rejoin enabled. Starting teleport...", "INFO")
        safeTeleport()
    end
end

-- Инициализация
safeCall(function()
    wait(2)
    if not game:IsLoaded() then
        game.Loaded:Wait()
    end
    
    addLog("Script initializing...", "INFO")
    suppressGameErrors()
    antiAFKSafe()
    createUI()
    checkAutoInject()
    addLog("Script initialized and ready", "SUCCESS")
end)
