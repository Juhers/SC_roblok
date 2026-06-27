local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local function notify(title, text, duration)
    duration = duration or 5
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title = title; Text = text; Duration = duration})
    end)
end

local function copyToClipboard(text)
    pcall(function()
        setclipboard(text)
    end)
end

-- ================== DETAILED CHECK FOR TANDA SERU ==================
local function checkBloaterExclamation()
    if not mouse.Target then
        notify("❌ No Target", "Arahkan mouse ke Bloater", 3)
        return
    end

    local target = mouse.Target
    local model = target:FindFirstAncestorWhichIsA("Model") or target.Parent

    local result = "=== BLOATER EXCLAMATION CHECK ===\n"
    result = result .. "Model: " .. model.Name .. "\nTime: " .. os.date("%H:%M:%S") .. "\n\n"

    local foundExclamation = false
    local guiLocations = {}

    -- Cek semua descendant secara detail
    for _, obj in ipairs(model:GetDescendants()) do
        if obj:IsA("BillboardGui") or obj:IsA("SurfaceGui") then
            table.insert(guiLocations, obj)
            result = result .. "🎯 GUI Found: " .. obj.Name .. " (Parent: " .. obj.Parent.Name .. ")\n"
            
            for _, child in ipairs(obj:GetChildren()) do
                if child:IsA("TextLabel") or child:IsA("ImageLabel") then
                    local txt = child.Text or ""
                    result = result .. "   → " .. child.Name .. " | Text: '" .. txt .. "' | Visible: " .. tostring(child.Visible) .. "\n"
                    
                    if txt == "!" or txt == "！" or child.Name:lower():find("excl") then
                        foundExclamation = true
                        result = result .. "   💥 === TANDA SERU DITEMUKAN DI SINI ===\n"
                    end
                end
            end
        end
    end

    if #guiLocations == 0 then
        result = result .. "❌ Tidak ada BillboardGui / SurfaceGui di model ini\n"
    end

    -- Cek Head dan Torso khusus (karena tanda seru biasanya di atas badan)
    local head = model:FindFirstChild("Head")
    if head then
        result = result .. "\nHead Children:\n"
        for _, c in ipairs(head:GetChildren()) do
            result = result .. "   • " .. c.Name .. " (" .. c.ClassName .. ")\n"
        end
    end

    result = result .. "\nStatus: " .. (foundExclamation and "TANDA SERU TERDETEKSI" or "Tidak ditemukan tanda seru") .. "\n"

    -- Output
    print(result)
    copyToClipboard(result)
    
    if foundExclamation then
        notify("💥 SUCCESS!", "Tanda Seru terdeteksi!", 6)
    else
        notify("⚠️ No Exclamation", "Tanda seru belum terdeteksi\nHasil sudah dicopy", 5)
    end
end

-- Hotkey
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.B then
        checkBloaterExclamation()
    end
end)

notify("🔍 Detailed Exclamation Checker", "Arahkan mouse ke Bloater → Tekan **B**", 10)