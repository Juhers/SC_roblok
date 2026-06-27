local function isBloaterAboutToExplode()

    local DETECT_RADIUS = 80

    local player = game:GetService("Players").LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local myRoot = character:FindFirstChild("HumanoidRootPart")

    if not myRoot then
        warn("Player HumanoidRootPart tidak ditemukan")
        return false
    end

    local characters = workspace:FindFirstChild("Characters")

    if not characters then
        warn("Workspace.Characters tidak ditemukan")
        return false
    end

    for _, npc in ipairs(characters:GetChildren()) do

        if npc ~= character then

            local root = npc:FindFirstChild("HumanoidRootPart")

            if root then

                local distance = (root.Position - myRoot.Position).Magnitude

                if distance <= DETECT_RADIUS then

                    local fuse = root:FindFirstChild("Fuse")

                    if not fuse then
                        local passive = npc:FindFirstChild("Passive")
                        if passive then
                            fuse = passive:FindFirstChild("Fuse")
                        end
                    end

                    local exploding
                    local center = root:FindFirstChild("CenterParticle")

                    if center then
                        exploding = center:FindFirstChild("Exploding")
                    end

                    if fuse then
                        if fuse:IsA("Sound") and fuse.IsPlaying then
                            warn("🔥 Fuse aktif :", npc.Name)
                            return true
                        end
                    end

                    --[[
                    if exploding then
                        print(("Exploding ditemukan pada %s | Enabled = %s"):format(
                            npc.Name,
                            tostring(exploding.Enabled)
                        ))

                        if exploding:IsA("ParticleEmitter") and exploding.Enabled then
                            warn("💥 Particle aktif :", npc.Name)
                            return true
                        end
                    end
                    ]]--

                end
            end
        end
    end

    return false
end

while true do
    print(isBloaterAboutToExplode() and "💥 BLOATER AKAN MELEDAK!" or "✅ Tidak ada bloater yang meledak")
    task.wait(1)
end