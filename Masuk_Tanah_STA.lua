-- [ Delta Executor ] Super Deep Underground - Anti Drift Total

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local root = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

local underground = false
local connection = nil
local originalHip = humanoid.HipHeight
local startX = 0
local startZ = 0

local function enableDeepUnderground()
    underground = true
    print("✅ SUPER DEEP UNDERGROUND AKTIF - Anti Drift Total")

    -- Simpan posisi X dan Z awal
    startX = root.Position.X
    startZ = root.Position.Z

    humanoid.HipHeight = -320
    humanoid.PlatformStand = true
    root.Anchored = false

    -- Matikan collision
    for _, v in pairs(character:GetDescendants()) do
        if v:IsA("BasePart") then
            v.CanCollide = false
            v.Massless = true
        end
    end

    -- Loop turun + koreksi posisi X dan Z
    connection = RunService.Heartbeat:Connect(function()
        if underground and root and root.Parent then
            local currentY = root.Position.Y
            
            -- Reposisi ke X dan Z awal + turun di Y
            root.CFrame = CFrame.new(startX, currentY - 6, startZ)
            
            -- Reset semua velocity horizontal
            root.AssemblyLinearVelocity = Vector3.new(0, -280, 0)
            root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        end
    end)
end

local function disableDeepUnderground()
    underground = false
    print("❌ Underground DIMATIKAN")

    if connection then 
        connection:Disconnect() 
        connection = nil 
    end

    humanoid.HipHeight = originalHip
    humanoid.PlatformStand = false
    root.AssemblyLinearVelocity = Vector3.new(0,0,0)
    root.AssemblyAngularVelocity = Vector3.new(0,0,0)

    -- Kembalikan collision
    for _, v in pairs(character:GetDescendants()) do
        if v:IsA("BasePart") then
            v.CanCollide = true
            v.Massless = false
        end
    end

    root.CFrame = root.CFrame * CFrame.new(0, 150, 0)
end

-- Toggle F
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.L then
        if underground then
            disableDeepUnderground()
        else
            enableDeepUnderground()
        end
    end
end)

-- Reset saat respawn
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    root = newChar:WaitForChild("HumanoidRootPart")
    humanoid = newChar:WaitForChild("Humanoid")
    originalHip = humanoid.HipHeight
    underground = false
end)

print("🚀 Super Deep Underground - Anti Drift Total Loaded!")
print("Tekan F untuk masuk sangat dalam (tanpa geser)")


-- loadstring(game:HttpGet("https://raw.githubusercontent.com/Juhers/SC_roblok/refs/heads/main/TP_bawah tanah.lua"))()

-- Full Path  Farm Plot : Workspace.Structures.Farm Plot.Mesh
-- Full Path  Farm Plot : Workspace.Structures.Generator.MainPart