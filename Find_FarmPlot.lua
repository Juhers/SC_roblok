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
local playerGui = player:WaitForChild("PlayerGui", 10)

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

-- ================== ADAPTIVE CRAWL TO (DENGAN SPEED CONTROL) ==================
local positionLockConnection = nil
local function adaptiveCrawlTo(targetPos, speedMultiplier)
    local root = getRoot()
    if not root then return end

    if positionLockConnection then
        positionLockConnection:Disconnect()
        positionLockConnection = nil
    end

    speedMultiplier = speedMultiplier or 1.0

    StartCrawlNoclip()
    notify("🛡️ Noclip", "Noclip AKTIF - Sedang Crawling...", 2)

    local finalTarget = targetPos + Vector3.new(0, -5, 0)
    
    local BURST_SPEED = 160 * speedMultiplier
    local SLOW_SPEED  = 8 * speedMultiplier
    local CLEARANCE_COOLDOWN = 0.7  
    local SLOW_ZONE_DURATION = 0.4

    local lastWallDetectedTime = 0
    local isFinished = false

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

        if totalDistance <= 3.0 then
            currentRoot.CFrame = CFrame.new(finalTarget)
            isFinished = true
            break
        end

        if totalDistance < 0.5 then 
            isFinished = true
            break 
        end

        local direction = remainingVector.Unit

        local rayResult = workspace:Raycast(currentPos, direction * 6, raycastParams)
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

        currentRoot.CFrame = CFrame.new(nextPos)
        
        -- Penting: Update ke server agar terlihat di akun lain
        currentRoot.Velocity = Vector3.new(0,0,0)
    end

    task.wait(0.4)

    local finalRoot = getRoot()
    if finalRoot and isFinished then
        finalRoot.CFrame = CFrame.new(finalTarget)
        finalRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        finalRoot.AssemblyAngularVelocity = Vector3.new(0, 0, 0)

        -- Lock permanen
        positionLockConnection = RunService.Heartbeat:Connect(function()
            local r = getRoot()
            if r and r.Parent then
                r.CFrame = CFrame.new(finalTarget)
                r.AssemblyLinearVelocity = Vector3.new(0, -8, 0)
                r.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                
                -- Update ke server setiap frame
                r.Velocity = Vector3.new(0,0,0)
            end
        end)
    end

    StopCrawlNoclip()
    notify("🛡️ Noclip", "Noclip DIMATIKAN - Posisi TERKUNCI", 3)
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

-- ================== FUNGSI DETEKSI ==================
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local function isZombiesRemainingVisible()
    -- Cek PlayerGui
    if playerGui then
        for _, gui in ipairs(playerGui:GetDescendants()) do
            if gui:IsA("TextLabel") or gui:IsA("TextButton") or gui:IsA("TextBox") then
                local text = gui.Text
                if text and (text:find("Zombies Remaining") or text:find("Enemies Remaining")) then
                    
                    local numberStr = text:match(":%s*(%d+)")
                    local zombieCount = tonumber(numberStr) or 0
                    
                    print("✅ Ditemukan: " .. text .. " | Jumlah: " .. zombieCount)
                    print("   Parent: " .. gui.Parent.Name .. " | Object: " .. gui.Name)
                    
                    if zombieCount > 0 then
                        return true, gui, zombieCount
                    else
                        print("   (Zombies = 0, dianggap wave selesai)")
                        return false, gui, 0
                    end
                end
            end
        end
    end

    -- Cek CoreGui
    local coreGui = game:GetService("CoreGui")
    for _, gui in ipairs(coreGui:GetDescendants()) do
        if gui:IsA("TextLabel") or gui:IsA("TextButton") or gui:IsA("TextBox") then
            local text = gui.Text
            if text and (text:find("Zombies Remaining") or text:find("Enemies Remaining")) then
                
                local numberStr = text:match(":%s*(%d+)")
                local zombieCount = tonumber(numberStr) or 0
                
                print("✅ Ditemukan di CoreGui: " .. text .. " | Jumlah: " .. zombieCount)
                
                if zombieCount > 0 then
                    return true, gui, zombieCount
                else
                    print("   (Zombies = 0, dianggap wave selesai)")
                    return false, gui, 0
                end
            end
        end
    end

    print("❌ Tidak ditemukan teks 'Zombies Remaining'")
    return false, nil, 0
end

local UserInputService = game:GetService("UserInputService")
local stopLoop = false
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.H then
        stopLoop = true
        print("Loop dihentikan.")
    end
end)

-- ================== FULL SEQUENCE ==================
local function performFullSequence()
    if isRunning then return end
    isRunning = true

    task.wait(2)
    -- Tekan T Kedua
    simulateKeyPress(Enum.KeyCode.T)

    --enableDeepUnderground()
    local targetPos = getGeneratorPosition()
    if targetPos then
        local backOffset = targetPos + Vector3.new(0, -6, 0)
        adaptiveCrawlTo(backOffset, 1)
    end
    
    -- ================== HITUNG MUNDUR 10 MENIT ==================
    notify("⏳ UNDERGROUND", "Menunggu 10 menit untuk stabilisasi...", 5)
    
    local totalSeconds = 600  -- 10 menit
    for i = totalSeconds, 1, -1 do
        local minutes = math.floor(i / 60)
        local seconds = i % 60
        if i % 30 == 0 or i <= 60 then  -- Update setiap 30 detik atau di menit akhir
            if stopLoop then
                break
            end
            notify("⏳ Hitung Mundur", 
                string.format("Kembali ke permukaan dalam: %d menit %d detik", minutes, seconds), 
                4)
        end
        task.wait(1)
    end

    -- Deteksi apakah masih ada Zombie
    local found, guiObject, count = isZombiesRemainingVisible()
    if found then
        notify("⚠️ Zombie Terdeteksi", 
            string.format("Masih ada %d Zombie Remaining! Menunggu...", count), 5)
        while found do
            task.wait(1)
            found, guiObject, count = isZombiesRemainingVisible()
            if stopLoop then
                break
            end
        end
    end

    task.wait(3)

    -- Tekan T Pertama
    simulateKeyPress(Enum.KeyCode.T)
    stopLoop = false

    local plots = findAllFarmPlots()
    for i, plotPos in ipairs(plots) do
        local offset = plotPos + Vector3.new(0, -6, 0)
        adaptiveCrawlTo(offset, 2)
        task.wait(0.1)
    end

    isRunning = false
    notify("✅ Cycle Selesai", "Satu cycle farm selesai", 4)
end

local function toggleLoop()
    isLooping = not isLooping
    
    if isLooping then
        notify("🔄 LOOP AKTIF", "Auto Farm Loop ON\nTekan J untuk matikan", 6)
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
    if input.KeyCode == Enum.KeyCode.G then
        toggleLoop()
    end
end)

-- ================== INIT ==================
notify("🚀 Script Loaded", "Deep Underground + Auto Farm Loop\nTekan **J** untuk toggle looping", 8)