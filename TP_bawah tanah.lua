local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

local undergroundConnection = nil
local originalHip = humanoid.HipHeight
local targetPosition = nil
local isMoving = false
local phase = "vertical"
local isLocked = false

local cachedGeneratorPos = nil

local function getRoot()
    return character and character:FindFirstChild("HumanoidRootPart") or nil
end

-- ================== AMBIL POSISI GENERATOR ==================
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

-- ================== FIND PATH (LAMBAT + KUNCI POSISI) ==================
local function findPath(PosX, PosY, PosZ)
    local root = getRoot()
    if not root or not humanoid then return end

    if not originalHip then
        originalHip = humanoid.HipHeight
    end

    targetPosition = Vector3.new(PosX, PosY, PosZ)
    isMoving = true
    phase = "vertical"
    isLocked = false

    humanoid.HipHeight = -300
    humanoid.PlatformStand = true
    humanoid.AutoRotate = false

    if undergroundConnection then
        undergroundConnection:Disconnect()
    end

    undergroundConnection = RunService.Heartbeat:Connect(function(dt)
        local root = getRoot()
        if not root or not targetPosition or not isMoving then return end

        local currentPos = root.Position
        local newPos = currentPos

        if phase == "vertical" then
            -- Tahap 1: Gerak vertikal sangat lambat
            newPos = Vector3.new(currentPos.X, currentPos.Y, currentPos.Z):Lerp(
                Vector3.new(currentPos.X, targetPosition.Y, currentPos.Z), 
                2.8 * dt   -- sangat lambat
            )

            if math.abs(newPos.Y - targetPosition.Y) < 1 then
                phase = "horizontal"
                print("✅ Y stabil, mulai gerak horizontal...")
            end

        elseif phase == "horizontal" then
            -- Tahap 2: Gerak horizontal sangat lambat
            newPos = currentPos:Lerp(targetPosition, 2.5 * dt)
        end

        -- Terapkan posisi
        root.CFrame = CFrame.new(newPos.X, newPos.Y, newPos.Z) * 
                     CFrame.Angles(0, root.CFrame.Rotation.Y, 0)

        root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)

        -- Gerakan horizontal player
        local moveDir = humanoid.MoveDirection
        if moveDir.Magnitude > 0.1 then
            local horizontalVel = moveDir * 38
            root.AssemblyLinearVelocity = Vector3.new(horizontalVel.X, root.AssemblyLinearVelocity.Y, horizontalVel.Z)
        end

        -- ================== CEK SAMPAI & KUNCI POSISI ==================
        if phase == "horizontal" and (newPos - targetPosition).Magnitude < 1.5 then
            undergroundConnection:Disconnect()
            undergroundConnection = nil
            isMoving = false
            isLocked = true

            -- Kunci posisi agar tidak tenggelam
            root.CFrame = CFrame.new(targetPosition.X, targetPosition.Y, targetPosition.Z) * 
                         CFrame.Angles(0, root.CFrame.Rotation.Y, 0)
            
            root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)

            humanoid.HipHeight = originalHip or 2
            humanoid.PlatformStand = false
            humanoid.AutoRotate = true

            print("✅ Sampai di tujuan & posisi dikunci!")
        end
    end)

    print("🚀 Menuju ke:", targetPosition, "| Mode: Lambat")
end

-- 1. Langsung ke Generator (paling recommended)
local genPos = getGeneratorPosition()
if genPos then
    findPath(genPos.X + 200, genPos.Y - 50, genPos.Z + 500)   -- turun 5 studs di bawah Generator
end