local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer

local function notify(title, text, duration)
    duration = duration or 5
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title = title; Text = text; Duration = duration})
    end)
end

local function getRoot()
    if not player.Character then return nil end
    return player.Character:FindFirstChild("HumanoidRootPart")
end

-- ================== DETEKSI TANDA SERU BLOATER (VERSI AGRESIF) ==================
local function isBloaterAboutToExplode()
    local closestBloater = nil
    local closestDist = math.huge
    local hasWarning = false

    -- 1. Cari semua BillboardGui di workspace
    for _, gui in ipairs(Workspace:GetDescendants()) do
        if gui:IsA("BillboardGui") or gui:IsA("SurfaceGui") then
            for _, child in ipairs(gui:GetChildren()) do
                if (child:IsA("TextLabel") or child:IsA("ImageLabel")) and 
                   (child.Text == "!" or child.Text == "！" or child.Name:lower():find("excl") or child.Name:lower():find("alert")) then
                    
                    -- Cari parent terdekat yang mirip Bloater
                    local parentModel = gui.Parent
                    while parentModel and not parentModel:FindFirstChild("MobAI") and not parentModel.Name:lower():find("bloater") do
                        parentModel = parentModel.Parent
                    end
                    
                    if parentModel then
                        local root = parentModel:FindFirstChild("HumanoidRootPart") or parentModel:FindFirstChild("Torso")
                        if root then
                            local playerRoot = getRoot()
                            if playerRoot then
                                local dist = (root.Position - playerRoot.Position).Magnitude
                                
                                if dist < closestDist then
                                    closestDist = dist
                                    closestBloater = parentModel
                                    hasWarning = true
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    -- Fallback: Cari Bloater biasa
    if not hasWarning then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            local nl = obj.Name:lower()
            if nl:find("bloater") or (obj:FindFirstChild("MobAI") and obj:FindFirstChild("BaseStats")) then
                local root = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Torso")
                if root then
                    local dist = (root.Position - (getRoot() or Vector3.new()).Position).Magnitude
                    if dist < closestDist then
                        closestDist = dist
                        closestBloater = obj
                    end
                end
            end
        end
    end

    if closestBloater then
        print(string.format("🧟 Bloater terdeteksi | Jarak: %.1f | Warning: %s", closestDist, hasWarning and "✅" or "❌"))
        return true, {Distance = closestDist, HasExclamation = hasWarning, Object = closestBloater}, closestDist
    end

    return false, nil, 0
end

-- ================== HOTKEY ==================
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.B then
        local danger, info, dist = isBloaterAboutToExplode()
        if danger and info.HasExclamation then
            notify("💥 BLOATER ALERT!", "Tanda Seru terdeteksi!\nJarak: " .. math.floor(dist), 6)
        elseif danger then
            notify("🧟 Bloater Ditemukan", "Jarak: " .. math.floor(dist) .. " studs (tanpa tanda seru)", 4)
        else
            notify("❌ Tidak Ditemukan", "Tidak ada Bloater aktif", 3)
        end
    end
end)

notify("🔍 Bloater Detector", "Tekan **B** saat Bloater mau meledak", 8)