-- [ Delta Executor ] Deep Underground + Adaptive Crawl Farm Plot + Looping
-- Toggle Loop: Tekan F

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local root = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

local isRunning = false
local isLooping = false
local loopConnection = nil
local undergroundConnection = nil
local originalHip = humanoid.HipHeight
local undergroundHomeCFrame = nil

-- ================== NOTIFIKASI ==================
local function notify(title, text, duration)
    duration = duration or 4
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title = title; Text = text; Duration = duration;})
    end)
end

local function getRoot()
    local char = player.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

-- ================== DETEKSI FARM PLOT & GENERATOR ==================
local function findAllFarmPlots()
    local plots = {}
    local Structures = workspace:FindFirstChild("Structures")
    if Structures then
        for _, obj in ipairs(Structures:GetChildren()) do
            if obj.Name == "Farm Plot" or obj.Name == "FarmPlot" then
                local mesh = obj:FindFirstChild("Mesh") or obj:FindFirstChildWhichIsA("BasePart")
                if mesh then
                    table.insert(plots, mesh:GetPivot().Position)
                else
                    table.insert(plots, obj:GetPivot().Position)
                end
            end
        end
    end

    if #plots == 0 then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj.Name == "Farm Plot" or (obj.Parent and obj.Parent.Name == "Farm Plot") then
                local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
                if part then
                    table.insert(plots, part:GetPivot().Position)
                end
            end
        end
    end
    return plots
end

local cachedGeneratorPos = nil
local function getGeneratorPosition()
    if cachedGeneratorPos then return cachedGeneratorPos end
    local Structures = workspace:FindFirstChild("Structures")
    if Structures then
        for _, obj in ipairs(Structures:GetChildren()) do
            if obj.Name == "Generator" then
                local mainPart = obj:FindFirstChild("MainPart") or obj:FindFirstChildWhichIsA("BasePart")
                if mainPart then
                    cachedGeneratorPos = mainPart:GetPivot().Position
                    return cachedGeneratorPos
                end
            end
        end
    end
    local gen = workspace:FindFirstChild("Generator", true)
    if gen then
        cachedGeneratorPos = gen:GetPivot().Position
        return cachedGeneratorPos
    end
    return nil
end

-- ================== UNDERGROUND FUNCTIONS ==================
local function enableDeepUnderground()
    local root = getRoot()
    if not root then return end

    undergroundHomeCFrame = root.CFrame
    originalHip = humanoid.HipHeight
    humanoid.HipHeight = -320
    humanoid.PlatformStand = true

    if undergroundConnection then undergroundConnection:Disconnect() end
    
    undergroundConnection = RunService.Heartbeat:Connect(function()
        local currentRoot = getRoot()
        if not currentRoot then return end
        local currentY = currentRoot.Position.Y
        currentRoot.CFrame = CFrame.new(undergroundHomeCFrame.X, currentY - 6, undergroundHomeCFrame.Z)
        currentRoot.AssemblyLinearVelocity = Vector3.new(0, -280, 0)
    end)

    notify("🌍 Underground", "SUPER DEEP UNDERGROUND AKTIF", 5)
end

local function disableDeepUnderground()
    if undergroundConnection then
        undergroundConnection:Disconnect()
        undergroundConnection = nil
    end

    humanoid.HipHeight = originalHip
    humanoid.PlatformStand = false

    local root = getRoot()
    if root then
        root.AssemblyLinearVelocity = Vector3.new(0,0,0)
        root.AssemblyAngularVelocity = Vector3.new(0,0,0)
        root.CFrame = root.CFrame * CFrame.new(0, 100, 0)
    end

    for _, v in pairs(character:GetDescendants()) do
        if v:IsA("BasePart") then
            v.CanCollide = true
            v.Massless = false
        end
    end
    notify("⬆️ Naik", "Kembali ke permukaan...", 4)
end

-- ================== ADAPTIVE CRAWL TO (FIXED - Anti Tenggelam) ==================
local crawlNoclipConnection = nil

local function StartCrawlNoclip()
    if crawlNoclipConnection then return end
    crawlNoclipConnection = RunService.Stepped:Connect(function()
        local char = player.Character
        if not char then return end
        for _, child in ipairs(char:GetDescendants()) do
            if child:IsA("BasePart") then
                child.CanCollide = false
                child.Massless = true
            end
        end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        end
    end)
end

local function StopCrawlNoclip()
    if crawlNoclipConnection then
        crawlNoclipConnection:Disconnect()
        crawlNoclipConnection = nil
    end
end

local function adaptiveCrawlTo(targetPos)
    local root = getRoot()
    if not root then return end

    StartCrawlNoclip()
    notify("🛡️ Noclip", "Noclip AKTIF - Sedang Crawling...", 2)

    local finalTarget = targetPos + Vector3.new(0, 5, 0)  -- Naik 5 studs di atas target
    local BURST_SPEED = 160
    local SLOW_SPEED = 8
    local CLEARANCE_COOLDOWN = 0.7  
    local SLOW_ZONE_DURATION = 0.4

    local lastWallDetectedTime = 0

    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {player.Character}

    while true do
        local currentRoot = getRoot()
        if not currentRoot or not currentRoot.Parent then break end

        local deltaTime = RunService.Heartbeat:Wait()
        local currentPos = currentRoot.Position
        local remainingVector = finalTarget - currentPos
        local totalDistance = remainingVector.Magnitude

        -- Finish condition
        if totalDistance <= 3.0 then
            currentRoot.CFrame = CFrame.new(finalTarget)
            currentRoot.AssemblyLinearVelocity = Vector3.new(0, -10, 0)
            currentRoot.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            break
        end

        if totalDistance < 0.5 then break end

        local direction = remainingVector.Unit

        -- Raycast untuk deteksi obstacle
        local rayResult = workspace:Raycast(currentPos, direction * 6, raycastParams)
        if rayResult and rayResult.Instance and rayResult.Instance.CanCollide then
            lastWallDetectedTime = os.clock()
        end

        -- Kecepatan
        local currentAllowedSpeed = SLOW_SPEED
        if os.clock() - lastWallDetectedTime >= CLEARANCE_COOLDOWN then
            local serverTime = workspace:GetServerTimeNow()
            local fraction = serverTime % 1.0
            if fraction < (1.0 - SLOW_ZONE_DURATION) then
                currentAllowedSpeed = BURST_SPEED
            end
        end

        local frameTravel = math.min(currentAllowedSpeed * deltaTime, totalDistance)
        local nextPos = currentPos + (direction * frameTravel)

        -- Terapkan pergerakan
        currentRoot.CFrame = CFrame.new(nextPos)
    end

    -- Final positioning & cleanup
    task.wait(0.6)
    local finalRoot = getRoot()
    if finalRoot then
        finalRoot.CFrame = CFrame.new(finalTarget)
        finalRoot.AssemblyLinearVelocity = Vector3.new(0, -15, 0)
    end

    StopCrawlNoclip()
    notify("🛡️ Noclip", "Noclip DIMATIKAN", 2)
end

-- ================== FUNGSI SIMULASI TEKAN TOMBOL ==================
local function simulateKeyPress(keyCode)
    local VirtualInputManager = game:GetService("VirtualInputManager")
    
    -- Tekan tombol
    VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
    task.wait(0.1)
    -- Lepas tombol
    VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
    
    notify("⌨️ Simulate", "Tombol T ditekan", 2)
end

-- ================== FULL SEQUENCE ==================
local function performFullSequence()
    if isRunning then return end
    isRunning = true

    enableDeepUnderground()

    -- ================== HITUNG MUNDUR 10 MENIT ==================
    notify("⏳ UNDERGROUND", "Menunggu 10 menit untuk stabilisasi...", 5)
    
    local totalSeconds = 600  -- 10 menit
    for i = totalSeconds, 1, -1 do
        local minutes = math.floor(i / 60)
        local seconds = i % 60
        
        if i % 30 == 0 or i <= 60 then  -- Update setiap 30 detik atau di menit akhir
            notify("⏳ Hitung Mundur", 
                string.format("Kembali ke permukaan dalam: %d menit %d detik", minutes, seconds), 
                4)
        end
        
        task.wait(1)
    end

    disableDeepUnderground()
    task.wait(5)

    -- Tekan T Pertama
    simulateKeyPress(Enum.KeyCode.T)

    local plots = findAllFarmPlots()
    if #plots > 0 then
        notify("🚀 Mulai Crawl", "Menuju " .. #plots .. " Farm Plot...", 4)
        for i, plotPos in ipairs(plots) do
            adaptiveCrawlTo(plotPos)
            task.wait(1)
        end
    end

    local genPos = getGeneratorPosition()
    if genPos then
        local backOffset = genPos + Vector3.new(0, 10, 0)
        notify("🏠 Kembali", "Kembali ke belakang Generator...", 3)
        adaptiveCrawlTo(backOffset)
    end

    -- Tekan T Kedua
    simulateKeyPress(Enum.KeyCode.T)

    task.wait(5)

    -- Keyboard Menekan T

    isRunning = false
    notify("✅ Cycle Selesai", "Satu cycle farm selesai", 4)
end

local function toggleLoop()
    isLooping = not isLooping
    
    if isLooping then
        notify("🔄 LOOP AKTIF", "Auto Farm Loop ON\nTekan F untuk matikan", 6)
        loopConnection = RunService.Heartbeat:Connect(function()
            if not isLooping then 
                loopConnection:Disconnect()
                return 
            end
            if not isRunning then
                performFullSequence()
            end
        end)
    else
        if loopConnection then
            loopConnection:Disconnect()
            loopConnection = nil
        end
        notify("⛔ LOOP DIMATIKAN", "Auto Farm Loop OFF", 5)
    end
end

-- ================== HOTKEY ==================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.L then
        toggleLoop()
    end
end)

-- ================== INIT ==================
notify("🚀 Script Loaded", "Deep Underground + Auto Farm Loop\nTekan **Q** untuk toggle looping", 8)