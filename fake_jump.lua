-- [ Delta Executor ] Deep Underground + Adaptive Crawl Farm Plot + Looping

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")   -- ← PASTIKAN INI ADA
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer

local function spamJumpSimple()
    local character = player.Character
    if not character then return end
    local humanoid = character:FindFirstChild("Humanoid")
    if humanoid then
        pcall(function()
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end)
    end
end

RunService.Heartbeat:Connect(spamJumpSimple)