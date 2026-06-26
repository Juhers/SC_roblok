-- [ Delta Executor ] Auto Crawl to Farm Plot (Using AdaptiveCrawlTo)

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local root = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

local autoCrawl = false

print("🚀 Auto Crawl to Farm Plot Loaded!")
print("Tekan F untuk mulai crawl ke Farm Plot terdekat")

-- === FUNCTION adaptiveCrawlTo (dari kamu) ===
local function adaptiveCrawlTo(targetPos, humanoidRootPart, character)
    local finalTarget = targetPos + Vector3.new(0, 3, 0)
 
    local BURST_SPEED = 180
    local SLOW_SPEED = 5
    local CLEARANCE_COOLDOWN = 0.8  
    local SLOW_ZONE_DURATION = 0.35
 
    local lastWallDetectedTime = 0
    local lockedYHeight = humanoidRootPart.Position.Y
 
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {character} 
 
    local RunService = game:GetService("RunService")
    local heartbeatEvent = RunService.Heartbeat
 
    while true do
        if not humanoidRootPart or not humanoidRootPart.Parent then break end
 
        local deltaTime = heartbeatEvent:Wait()
 
        local currentPos = humanoidRootPart.Position
        local flatTarget = Vector3.new(finalTarget.X, lockedYHeight, finalTarget.Z)
        local remainingVector = flatTarget - currentPos
        local totalDistance = remainingVector.Magnitude
 
        if totalDistance <= 2.0 then
            humanoidRootPart.CFrame = CFrame.new(finalTarget)
            humanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, -5, 0) 
            humanoidRootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            humanoidRootPart.Anchored = true
            task.wait(0.05)
            humanoidRootPart.Anchored = false 
            break
        end
 
        local direction = remainingVector.Unit
        local lookAheadDistance = 5
        local rayResult = workspace:Raycast(currentPos, direction * lookAheadDistance, raycastParams)
 
        if rayResult and rayResult.Instance and rayResult.Instance.CanCollide then
            lastWallDetectedTime = os.clock()
        end
 
        local currentAllowedSpeed = SLOW_SPEED
 
        if os.clock() - lastWallDetectedTime >= CLEARANCE_COOLDOWN then
            local serverTime = workspace:GetServerTimeNow()
            local currentSecondFraction = serverTime % 1.0
 
            if currentSecondFraction < (1.0 - SLOW_ZONE_DURATION) then
                currentAllowedSpeed = BURST_SPEED
            end
        end
 
        local frameTravelDistance = currentAllowedSpeed * deltaTime
 
        if frameTravelDistance > totalDistance then
            frameTravelDistance = totalDistance
        end
 
        local nextPosition = currentPos + (direction * frameTravelDistance)
        local flattenedPosition = Vector3.new(nextPosition.X, lockedYHeight, nextPosition.Z)
 
        humanoidRootPart.CFrame = CFrame.new(flattenedPosition)
    end
end

-- === Fungsi Mencari Farm Plot ===
local function findNearestFarmPlot()
    local plots = {}
    
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj.Name == "Farm Plot" or (obj.Parent and obj.Parent.Name == "Farm Plot") then
            local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
            if part then
                table.insert(plots, part)
            end
        end
    end
    
    if #plots == 0 then return nil end

    local rootPos = root.Position
    local nearest = nil
    local shortest = math.huge

    for _, plot in pairs(plots) do
        local dist = (rootPos - plot.Position).Magnitude
        if dist < shortest then
            shortest = dist
            nearest = plot.Position
        end
    end

    return nearest
end

-- === Toggle Auto Crawl ===
local function toggleAutoCrawl()
    autoCrawl = not autoCrawl
    
    if autoCrawl then
        print("✅ Auto Crawl ke Farm Plot AKTIF")
        local targetPos = findNearestFarmPlot()
        if targetPos then
            adaptiveCrawlTo(targetPos, root, character)
            print("🏁 Telah sampai di Farm Plot")
        else
            print("❌ Farm Plot tidak ditemukan!")
        end
        autoCrawl = false
    else
        print("❌ Auto Crawl DIMATIKAN")
    end
end

-- Hotkey F
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.F then
        toggleAutoCrawl()
    end
end)

player.CharacterAdded:Connect(function(newChar)
    character = newChar
    root = newChar:WaitForChild("HumanoidRootPart")
end)

print("Script siap! Tekan F untuk mulai crawl ke Farm Plot")