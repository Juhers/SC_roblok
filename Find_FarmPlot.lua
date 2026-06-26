-- [ Delta Executor ] Deep Underground + Adaptive Crawl Farm Plot + Looping
-- Toggle Loop: Alt + G

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
local PermanentNoclipEnabled = true

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

-- ================== ADAPTIVE CRAWL TO + STRONG NOCLIP ==================
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
    notify("🛡️ Noclip", "Noclip AKTIF - Crawling...", 2)

    local finalTarget = targetPos + Vector3.new(0, 3, 0)
    local BURST_SPEED = 180
    local SLOW_SPEED = 5
    local CLEARANCE_COOLDOWN = 0.8  
    local SLOW_ZONE_DURATION = 0.35

    local lastWallDetectedTime = 0
    local lockedYHeight = root.Position.Y

    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {player.Character}

    while true do
        local currentRoot = getRoot()
        if not currentRoot or not currentRoot.Parent then break end

        local deltaTime = RunService.Heartbeat:Wait()
        local currentPos = currentRoot.Position
        local flatTarget = Vector3.new(finalTarget.X, lockedYHeight, finalTarget.Z)
        local remainingVector = flatTarget - currentPos
        local totalDistance = remainingVector.Magnitude

        if totalDistance <= 2.0 then
            currentRoot.CFrame = CFrame.new(finalTarget)
            currentRoot.AssemblyLinearVelocity = Vector3.new(0, -5, 0)
            currentRoot.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            break
        end

        if totalDistance < 0.1 then break end

        local direction = remainingVector.Unit
        local rayResult = workspace:Raycast(currentPos, direction * 5, raycastParams)

        if rayResult and rayResult.Instance and rayResult.Instance.CanCollide then
            lastWallDetectedTime = os.clock()
        end

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
        local flatPos = Vector3.new(nextPos.X, lockedYHeight, nextPos.Z)

        currentRoot.CFrame = CFrame.new(flatPos)
    end

    task.wait(0.8)
    StopCrawlNoclip()
end

-- ================== FULL SEQUENCE ==================
local function performFullSequence()
    if isRunning then return end
    isRunning = true

    enableDeepUnderground()
    task.wait(10)

    disableDeepUnderground()
    task.wait(5)

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
        local backOffset = genPos + Vector3.new(0, 5, 12)
        notify("🏠 Kembali", "Kembali ke belakang Generator...", 3)
        adaptiveCrawlTo(backOffset)
    end

    disableDeepUnderground()
    isRunning = false
    notify("✅ Cycle Selesai", "Satu cycle farm selesai", 4)
end

local function toggleLoop()
    isLooping = not isLooping
    
    if isLooping then
        notify("🔄 LOOP AKTIF", "Auto Farm akan berulang terus...", 5)
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
        notify("⛔ LOOP DIMATIKAN", "Auto Farm Loop telah dimatikan", 5)
    end
end

-- ================== HOTKEY ==================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    -- Alt + G = Toggle Loop
    if input.KeyCode == Enum.KeyCode.G and (UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt) or UserInputService:IsKeyDown(Enum.KeyCode.RightAlt)) then
        toggleLoop()
    end
end)

-- ================== INIT ==================
notify("🚀 Script Loaded", "Deep Underground + Auto Farm Loop\nTekan **Alt + G** untuk toggle looping", 8)

-- Optional: Jalankan sekali di awal
-- performFullSequence()