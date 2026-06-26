-- [ Delta Executor ] Deep Underground + Adaptive Crawl Farm Plot
-- Update: Naik ke Permukaan Dulu Sebelum ke Farm Plot

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local root = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

local isRunning = false
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

local function findAllFarmPlots()
    local plots = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name == "Farm Plot" or (obj.Parent and obj.Parent.Name == "Farm Plot") then
            local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
            if part and part.Position then
                table.insert(plots, part.Position)
            end
        end
    end
    return plots
end

-- ================== ADAPTIVE CRAWL TO ==================
local function adaptiveCrawlTo(targetPos)
    local root = getRoot()
    if not root then return end

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
end

-- ================== NEW: RISE TO SURFACE ==================
local function riseToSurface()
    local root = getRoot()
    if not root then return end

    notify("⬆️ Naik", "Sedang naik ke permukaan...", 4)

    -- Matikan underground connection sementara
    if undergroundConnection then
        undergroundConnection:Disconnect()
        undergroundConnection = nil
    end

    local surfaceY = root.Position.Y + 400  -- Naik cukup tinggi
    local startPos = root.Position

    -- Gunakan adaptive style untuk naik
    local targetSurface = Vector3.new(startPos.X, surfaceY, startPos.Z)

    local BURST_SPEED = 120
    local distance = (targetSurface - startPos).Magnitude

    while distance > 5 do
        local currentRoot = getRoot()
        if not currentRoot then break end

        local currentPos = currentRoot.Position
        local direction = (targetSurface - currentPos).Unit
        local move = direction * (BURST_SPEED * 0.016)

        currentRoot.CFrame = CFrame.new(currentPos + move)
        distance = (targetSurface - currentRoot.Position).Magnitude

        RunService.Heartbeat:Wait()
    end

    -- Final adjustment
    root.CFrame = CFrame.new(targetSurface)
    notify("⬆️ Naik Selesai", "Sudah di permukaan", 3)
    task.wait(0.8)
end

local function enableDeepUnderground()
    local root = getRoot()
    if not root then return end

    undergroundHomeCFrame = root.CFrame
    originalHip = humanoid.HipHeight
    humanoid.HipHeight = -320
    humanoid.PlatformStand = true

    for _, v in pairs(character:GetDescendants()) do
        if v:IsA("BasePart") then
            v.CanCollide = false
            v.Massless = true
        end
    end

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
    end

    for _, v in pairs(character:GetDescendants()) do
        if v:IsA("BasePart") then
            v.CanCollide = true
            v.Massless = false
        end
    end
    notify("🌍 Underground", "Underground DIMATIKAN", 3)
end

local function teleportToAllFarmPlots()
    local plots = findAllFarmPlots()
    if #plots == 0 then
        notify("❌ Error", "Tidak ada Farm Plot ditemukan!", 5)
        return
    end

    notify("🚀 Mulai Crawl", "Menuju " .. #plots .. " Farm Plot...", 4)

    for i, plotPos in ipairs(plots) do
        adaptiveCrawlTo(plotPos)
        notify("📍 Crawl Selesai", "Farm Plot " .. i .. "/" .. #plots, 1.5)
        task.wait(1)
    end

    notify("✅ Selesai", "Telah mengunjungi semua Farm Plot", 5)
end

local function startFullSequence()
    if isRunning then 
        notify("⏳ Info", "Sequence sedang berjalan...", 3)
        return 
    end
    
    isRunning = true
    notify("🔄 SEQUENCE", "MEMULAI FULL AUTO FARM...", 5)

    -- Step 1: Masuk bawah tanah
    enableDeepUnderground()
    task.wait(10)

    -- Step 2: Naik ke permukaan
    riseToSurface()

    -- Step 3: Crawl ke semua Farm Plot
    teleportToAllFarmPlots()

    -- Step 4: Kembali ke posisi underground
    if undergroundHomeCFrame then
        notify("🏠 Kembali", "Kembali ke dalam tanah...", 3)
        adaptiveCrawlTo(undergroundHomeCFrame.Position)
    end

    disableDeepUnderground()

    isRunning = false
    notify("🎉 SELESAI", "Full Sequence telah selesai!", 6)
end

player.CharacterAdded:Connect(function(newChar)
    task.wait(0.5)
    character = newChar
    root = newChar:WaitForChild("HumanoidRootPart")
    humanoid = newChar:WaitForChild("Humanoid")
    originalHip = humanoid.HipHeight
    undergroundHomeCFrame = nil
    isRunning = false
    notify("🔄 Respawn", "Character baru terdeteksi", 3)
end)

notify("🚀 Script Loaded", "Deep Underground + Adaptive Crawl\nTekan F untuk memulai", 6)

-- Auto start (hapus baris ini kalau tidak ingin otomatis jalan)
startFullSequence()