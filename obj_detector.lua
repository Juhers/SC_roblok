-- [ Delta Executor ] Click Object + Smart Child Detector
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local detecting = true

local function notify(title, text, duration)
    duration = duration or 5
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title = title; Text = text; Duration = duration;})
    end)
end

-- ================== SMART CHILD DETECTOR (Mirip Generator) ==================
local function analyzeObject(obj)
    if not obj then return end

    print("🔍 OBJECT DIKLIK: " .. obj.Name)
    print("ClassName     : " .. obj.ClassName)
    print("Full Path     : " .. obj:GetFullName())
    print("==================================================")

    local childrenInfo = {}
    
    -- Scan Children Langsung
    for _, child in ipairs(obj:GetChildren()) do
        table.insert(childrenInfo, {
            Name = child.Name,
            Class = child.ClassName,
            HasBasePart = child:FindFirstChildWhichIsA("BasePart") ~= nil
        })
    end

    -- Scan Descendants (lebih dalam)
    local descendants = obj:GetDescendants()
    print("Children      : " .. #obj:GetChildren())
    print("Descendants   : " .. #descendants)

    -- Tampilkan Children
    if #childrenInfo > 0 then
        print("--- CHILDREN ---")
        for i, c in ipairs(childrenInfo) do
            print(string.format("%d. %s  [%s]%s", i, c.Name, c.Class, c.HasBasePart and " (Has Part)" or ""))
        end
    end

    -- Cari object penting di dalamnya (seperti Farm Plot, Generator, dll)
    local specialFound = {}
    for _, desc in ipairs(descendants) do
        if desc.Name == "Farm Plot" or desc.Name == "FarmPlot" or 
           desc.Name == "Generator" or desc.Name == "Plot" then
            table.insert(specialFound, desc.Name .. " (" .. desc.ClassName .. ")")
        end
    end

    if #specialFound > 0 then
        print("🔍 Special Objects Ditemukan:")
        for _, sp in ipairs(specialFound) do
            print("   • " .. sp)
        end
    end

    -- Highlight object yang diklik
    if obj:IsA("BasePart") then
        local originalColor = obj.Color
        obj.Color = Color3.new(1, 0, 1) -- Magenta
        task.delay(2, function()
            if obj and obj.Parent then obj.Color = originalColor end
        end)
    end

    notify("✅ Object Diketahui", 
        "Nama: " .. obj.Name .. "\n" ..
        "Children: " .. #obj:GetChildren() .. "\n" ..
        "Descendants: " .. #descendants, 6)
end

-- ================== CLICK DETECTION ==================
mouse.Button1Down:Connect(function()
    if not detecting then return end

    local target = mouse.Target
    if not target then
        notify("❌ Kosong", "Tidak ada object yang diklik", 2)
        return
    end

    -- Analisa object yang diklik + semua child-nya
    analyzeObject(target)
end)

-- ================== KONTROL ==================
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.T then
        detecting = not detecting
        notify("🔄 Detector", detecting and "AKTIF - Klik kiri untuk scan" or "DIMATIKAN", 3)
    end
end)

-- Klik Kanan = Teleport + Scan
mouse.Button2Down:Connect(function()
    if not detecting then return end
    local target = mouse.Target
    if target then
        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if root then
            root.CFrame = target.CFrame * CFrame.new(0, 6, 0)
            task.wait(0.2)
            analyzeObject(target) -- Scan setelah teleport
        end
    end
end)

notify("🚀 Smart Click Detector Loaded", 
    "Klik Kiri  = Scan Object + Children\n" ..
    "Klik Kanan = Teleport + Scan\n" ..
    "Tekan T    = Toggle On/Off", 8)

print("Smart Object Detector siap!")
print("Klik object apa saja untuk melihat child dan descendants-nya")