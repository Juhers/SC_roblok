-- =============================================
-- [ Delta Executor ] Game Event Detector
-- Standalone - FIXED & Stabil
-- =============================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local detectorEnabled = false
local connections = {}

local function notify(title, message, emoji)
    print(string.format("%s %s | %s", emoji or "🔍", title, message))
end

local function safeConnect(func)
    local success, err = pcall(func)
    if not success then
        warn("[Event Detector] Error: " .. tostring(err))
    end
end

local function startGameEventDetector()
    if detectorEnabled then return end
    detectorEnabled = true
    connections = {}

    print("🎮 GAME EVENT DETECTOR AKTIF (Versi Stabil)")

    -- Tunggu character & humanoid siap
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid", 5)

    if humanoid then
        -- Deteksi Damage & Health
        connections[#connections+1] = humanoid.HealthChanged:Connect(function(health)
            if health <= 0 then return end
            local maxHealth = humanoid.MaxHealth
            local percent = math.floor((health / maxHealth) * 100)
            
            if percent <= 30 then
                notify("DARAH KRITIS", string.format("%d/%d (%d%%)", health, maxHealth, percent), "🩸")
            elseif percent <= 60 then
                notify("Darah Rendah", string.format("%d/%d (%d%%)", health, maxHealth, percent), "🩸")
            end
        end)

        connections[#connections+1] = humanoid.Died:Connect(function()
            notify("KARAKTER MATI", "Player telah mati", "☠️")
        end)
    end

    -- Deteksi Objek Baru (dengan proteksi)
    connections[#connections+1] = workspace.DescendantAdded:Connect(function(desc)
        if not desc or not desc.Parent then return end
        
        task.spawn(function()
            task.wait(0.1) -- Hindari error parent nil
            
            -- Farm Plot
            if desc.Name == "Mesh" and desc.Parent.Name == "Farm Plot" then
                notify("FARM PLOT", desc.Parent:GetFullName(), "🌱")
            end
            
            -- Generator
            if desc.Name == "MainPart" and desc.Parent.Name == "Generator" then
                notify("GENERATOR", desc.Parent:GetFullName(), "⚡")
            end
            
            -- Resource Detection
            local nameLower = desc.Name:lower()
            if desc:IsA("Part") or desc:IsA("MeshPart") then
                if nameLower:find("coin") or nameLower:find("money") or nameLower:find("harvest") 
                   or nameLower:find("crop") or nameLower:find("drop") then
                    notify("RESOURCE", desc.Name, "💰")
                end
            end
        end)
    end)

    -- Deteksi struktur baru di folder Structures
    if workspace:FindFirstChild("Structures") then
        connections[#connections+1] = workspace.Structures.ChildAdded:Connect(function(child)
            notify("STRUKTUR BARU", child.Name, "🏗️")
        end)
    end

    print("✅ Detector berjalan dengan stabil. Tekan K untuk ON/OFF")
end

local function stopGameEventDetector()
    if not detectorEnabled then return end
    
    for _, conn in ipairs(connections) do
        pcall(function() conn:Disconnect() end)
    end
    
    connections = {}
    detectorEnabled = false
    print("⛔ GAME EVENT DETECTOR DIMATIKAN")
end

-- Toggle dengan K
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.K then
        if detectorEnabled then
            stopGameEventDetector()
        else
            startGameEventDetector()
        end
    end
end)

-- Reset otomatis saat respawn
player.CharacterAdded:Connect(function()
    if detectorEnabled then
        stopGameEventDetector()
        task.wait(1.5)
        startGameEventDetector()
    end
end)

print("🚀 Game Event Detector FIXED Loaded!")
print("Tekan tombol K untuk mengaktifkan")