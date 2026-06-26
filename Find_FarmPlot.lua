-- [ Delta Executor ] Deep Underground + Auto Farm Plot Teleport
-- Log menggunakan Notifikasi di Layar

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

-- ================== NOTIFIKASI FUNCTION ==================
local function notify(title, text, duration)
    duration = duration or 4
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title;
            Text = text;
            Duration = duration;
            Icon = ""; 
        })
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

local function enableDeepUnderground()
    local root = getRoot()
    if not root then return end

    originalHip = humanoid.HipHeight

    humanoid.HipHeight = -320
    humanoid.PlatformStand = true

    for _, v in pairs(character:GetDescendants()) do
        if v:IsA("BasePart") then
            v.CanCollide = false
            v.Massless = true
        end
    end

    undergroundHomeCFrame = root.CFrame

    undergroundConnection = RunService.Heartbeat:Connect(function()
        local currentRoot = getRoot()
        if not currentRoot then return end
        
        local currentY = currentRoot.Position.Y
        currentRoot.CFrame = CFrame.new(undergroundHomeCFrame.X, currentY - 6, undergroundHomeCFrame.Z)
        currentRoot.AssemblyLinearVelocity = Vector3.new(0, -280, 0)
        currentRoot.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
    end)

    notify("🌍 Underground", "SUPER DEEP UNDERGROUND AKTIF\nPosisi Home tersimpan", 5)
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
        
        for _, v in pairs(character:GetDescendants()) do
            if v:IsA("BasePart") then
                v.CanCollide = true
                v.Massless = false
            end
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

    notify("🚀 Mulai Farming", "Teleport ke " .. #plots .. " Farm Plot...", 4)

    for i, plotPos in ipairs(plots) do
        local root = getRoot()
        if root then
            root.CFrame = CFrame.new(plotPos + Vector3.new(0, 5, 0))
            notify("📍 Teleport", "Farm Plot " .. i .. "/" .. #plots, 1.5)
        end
        task.wait(1)
    end

    notify("✅ Selesai", "Teleport ke semua Farm Plot selesai!", 5)
end

local function startFullSequence()
    if isRunning then 
        notify("⏳ Info", "Sequence sedang berjalan...", 3)
        return 
    end
    
    isRunning = true
    notify("🔄 SEQUENCE", "MEMULAI FULL AUTO FARM...", 4)

    local root = getRoot()
    if not root then 
        isRunning = false
        return 
    end

    -- Step 1: Masuk Deep Underground
    enableDeepUnderground()
    task.wait(10)

    -- Step 2: Teleport ke semua Farm Plot
    teleportToAllFarmPlots()

    -- Step 3: Kembali ke posisi underground
    local finalRoot = getRoot()
    if finalRoot and undergroundHomeCFrame then
        finalRoot.CFrame = undergroundHomeCFrame
        notify("🏠 Kembali", "Kembali ke posisi dalam tanah", 4)
    end

    disableDeepUnderground()

    isRunning = false
    notify("🎉 SELESAI", "Full Sequence telah selesai!", 6)
end

-- ================== HOTKEY ==================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F then
        startFullSequence()
    end
end)

-- Reset saat respawn
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

notify("🚀 Script Loaded", "Deep Underground + Auto Farm Plot\nTekan F untuk memulai", 6)