-- [ Delta Executor ] Deep Underground + Adaptive Crawl Farm Plot + Permanent Noclip
-- Update: Deteksi via Full Path + Generator Position

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

-- ================== PERMANENT NOCLIP ==================
local noclipConnection = nil
local function StartPermanentNoclip()
    local function ConnectNoclip()
        if noclipConnection then noclipConnection:Disconnect() end
        noclipConnection = RunService.Stepped:Connect(function()
            if not PermanentNoclipEnabled then return end
            if character and character.Parent then
                for _, child in ipairs(character:GetDescendants()) do
                    if child:IsA("BasePart") and child.CanCollide then
                        child.CanCollide = false
                    end
                end
                local hrp = character:FindFirstChild("HumanoidRootPart")
                if hrp then hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0) end
            end
        end)
    end
    ConnectNoclip()

    player.CharacterAdded:Connect(function(newChar)
        task.wait(0.1)
        character = newChar
        ConnectNoclip()
    end)
end
StartPermanentNoclip()

-- ================== DETEKSI FARM PLOT VIA FULL PATH ==================
local function findAllFarmPlots()
    local plots = {}
    
    local Structures = workspace:FindFirstChild("Structures")
    if Structures then
        -- Deteksi Farm Plot berdasarkan Full Path
        for _, obj in ipairs(Structures:GetChildren()) do
            if obj.Name == "Farm Plot" or obj.Name == "FarmPlot" then
                -- Ambil Mesh atau BasePart utama
                local mesh = obj:FindFirstChild("Mesh") or obj:FindFirstChildWhichIsA("BasePart")
                if mesh then
                    table.insert(plots, mesh:GetPivot().Position)
                else
                    table.insert(plots, obj:GetPivot().Position)
                end
            end
        end
    end

    -- Fallback jika tidak ditemukan di Structures
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

    print("✅ Ditemukan " .. #plots .. " Farm Plot di Structures")
    return plots
end

-- ================== GET GENERATOR POSITION (Posisi Utama) ==================
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

    -- Fallback
    local gen = workspace:FindFirstChild("Generator", true)
    if gen then
        cachedGeneratorPos = gen:GetPivot().Position
        return cachedGeneratorPos
    end

    return nil
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

local function enableDeepUnderground()
    local root = getRoot()
    if not root then return end

    undergroundHomeCFrame = root.CFrame
    originalHip = humanoid.HipHeight
    humanoid.HipHeight = -320
    humanoid.PlatformStand = true

    undergroundConnection = RunService.Heartbeat:Connect(function()
        local currentRoot = getRoot()
        if not currentRoot then return end
        local currentY = currentRoot.Position.Y
        currentRoot.CFrame = CFrame.new(undergroundHomeCFrame.X, currentY - 6, undergroundHomeCFrame.Z)
        currentRoot.AssemblyLinearVelocity = Vector3.new(0, -280, 0)
    end)

    notify("🌍 Underground", "SUPER DEEP UNDERGROUND AKTIF + NOCLIP", 5)
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
        root.CFrame = root.CFrame * CFrame.new(0, 80, 0)
    end

    for _, v in pairs(character:GetDescendants()) do
        if v:IsA("BasePart") then
            v.CanCollide = true
            v.Massless = false
        end
    end
    notify("⬆️ Naik", "Kembali ke permukaan...", 4)
    task.wait(5)
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
    PermanentNoclipEnabled = true
    notify("🔄 SEQUENCE", "MEMULAI FULL AUTO FARM...", 5)

    enableDeepUnderground()
    task.wait(10)

    disableDeepUnderground()

    teleportToAllFarmPlots()

    -- Kembali ke Generator Position
    local genPos = getGeneratorPosition()
    if genPos then
        notify("🏠 Kembali", "Kembali ke Generator Position...", 3)
        adaptiveCrawlTo(genPos)
    elseif undergroundHomeCFrame then
        adaptiveCrawlTo(undergroundHomeCFrame.Position)
    end

    disableDeepUnderground()

    isRunning = false
    notify("🎉 SELESAI", "Full Sequence telah selesai!", 6)
end

startFullSequence()

player.CharacterAdded:Connect(function(newChar)
    task.wait(0.5)
    character = newChar
    root = newChar:WaitForChild("HumanoidRootPart")
    humanoid = newChar:WaitForChild("Humanoid")
    originalHip = humanoid.HipHeight
    undergroundHomeCFrame = nil
    notify("🔄 Respawn", "Character baru terdeteksi", 3)
end)

notify("🚀 Script Loaded", "Deep Underground + Farm Plot (Structures Path) + Generator Return", 6)