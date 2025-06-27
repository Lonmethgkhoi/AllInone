--[[
    All-In-One GUI by LScriptZ
    Features: Movement, Combat, UI, No Key, Music
]]

-- SERVICES
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")

local lp = Players.LocalPlayer
local hrp = nil
local humanoid = nil

-- RAYFIELD UI
local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Rayfield/main/source.lua"))()
local Window = Rayfield:CreateWindow({
    Name = "LScriptZ | All-In-One GUI",
    LoadingTitle = "LScriptZ Hub",
    LoadingSubtitle = "All Features Loaded",
    ConfigurationSaving = { Enabled = false },
    Discord = { Enabled = false },
    KeySystem = false,
})

local movementTab = Window:CreateTab("🚀 Movement")
local combatTab = Window:CreateTab("🎯 Combat")

-- Auto Update Character
local function refreshCharacter()
    lp.CharacterAdded:Connect(function(char)
        wait(1)
        humanoid = char:WaitForChild("Humanoid")
        hrp = char:WaitForChild("HumanoidRootPart")
    end)
    if lp.Character then
        humanoid = lp.Character:FindFirstChild("Humanoid")
        hrp = lp.Character:FindFirstChild("HumanoidRootPart")
    end
end
refreshCharacter()

-- MOVEMENT FEATURES

-- WalkSpeed
movementTab:CreateSlider({
    Name = "WalkSpeed",
    Range = {0, 200},
    Increment = 1,
    Suffix = "Speed",
    CurrentValue = 16,
    Callback = function(Value)
        if humanoid then humanoid.WalkSpeed = Value end
    end,
})

-- JumpPower
movementTab:CreateSlider({
    Name = "JumpPower",
    Range = {0, 300},
    Increment = 1,
    Suffix = "Power",
    CurrentValue = 50,
    Callback = function(Value)
        if humanoid then
            humanoid.UseJumpPower = true
            humanoid.JumpPower = Value
        end
    end,
})

-- Fly
local flyTog = false
local flySpeed = 2
movementTab:CreateSlider({
    Name = "Fly Speed",
    Range = {1, 10},
    Increment = 1,
    CurrentValue = 2,
    Callback = function(val) flySpeed = val end,
})

movementTab:CreateToggle({
    Name = "Toggle Fly (WASD)",
    CurrentValue = false,
    Callback = function(state)
        flyTog = state
        if not hrp then return end

        local bg = Instance.new("BodyGyro", hrp)
        local bv = Instance.new("BodyVelocity", hrp)
        bg.P = 9e4
        bg.maxTorque = Vector3.new(9e9,9e9,9e9)
        bv.maxForce = Vector3.new(9e9,9e9,9e9)

        local keys = {w=false,a=false,s=false,d=false}
        local con1 = UIS.InputBegan:Connect(function(i)
            if keys[i.KeyCode.Name:lower()] ~= nil then keys[i.KeyCode.Name:lower()] = true end
        end)
        local con2 = UIS.InputEnded:Connect(function(i)
            if keys[i.KeyCode.Name:lower()] ~= nil then keys[i.KeyCode.Name:lower()] = false end
        end)

        local flyLoop
        flyLoop = RS.RenderStepped:Connect(function()
            if not flyTog then
                flyLoop:Disconnect()
                con1:Disconnect()
                con2:Disconnect()
                bg:Destroy()
                bv:Destroy()
                return
            end
            local cam = workspace.CurrentCamera
            local move = Vector3.zero
            if keys.w then move += cam.CFrame.LookVector end
            if keys.s then move -= cam.CFrame.LookVector end
            if keys.a then move -= cam.CFrame.RightVector end
            if keys.d then move += cam.CFrame.RightVector end
            bv.Velocity = move.Unit * (flySpeed * 10)
            bg.CFrame = cam.CFrame
        end)
    end,
})

-- Infinite Jump
local ijOn = false
movementTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Callback = function(on)
        ijOn = on
    end
})
UIS.JumpRequest:Connect(function()
    if ijOn and humanoid then humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
end)

-- Noclip
local noclip = false
movementTab:CreateToggle({
    Name = "Noclip (walk through walls)",
    CurrentValue = false,
    Callback = function(on)
        noclip = on
    end
})
RS.Stepped:Connect(function()
    if noclip and lp.Character then
        for _,v in pairs(lp.Character:GetDescendants()) do
            if v:IsA("BasePart") and v.CanCollide == true then
                v.CanCollide = false
            end
        end
    end
end)

-- Anti-Ragdoll
movementTab:CreateButton({
    Name = "Remove Ragdoll States",
    Callback = function()
        if humanoid then
            humanoid.PlatformStand = false
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
        end
    end
})

-- COMBAT FEATURES

-- Hitbox Expander
combatTab:CreateToggle({
    Name = "Hitbox Expander (Players)",
    CurrentValue = false,
    Callback = function(state)
        for _,p in pairs(Players:GetPlayers()) do
            if p ~= lp and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = p.Character.HumanoidRootPart
                hrp.Size = state and Vector3.new(10,10,10) or Vector3.new(2,2,1)
                hrp.Transparency = state and 0.5 or 1
                hrp.Material = state and Enum.Material.Neon or Enum.Material.Plastic
            end
        end
    end
})

-- ESP (basic box ESP)
combatTab:CreateButton({
    Name = "Enable ESP (basic box)",
    Callback = function()
        loadstring(game:HttpGet("https://kiriot22.com/releases/ESP.lua"))().Toggle(true)
    end
})

-- Aimbot (softlock to head)
combatTab:CreateToggle({
    Name = "Aimbot (softlock to closest)",
    CurrentValue = false,
    Callback = function(enabled)
        getgenv().Aimbot = enabled
        local cam = workspace.CurrentCamera
        local function getClosest()
            local closest, dist = nil, math.huge
            for _,plr in pairs(Players:GetPlayers()) do
                if plr ~= lp and plr.Character and plr.Character:FindFirstChild("Head") then
                    local pos, vis = cam:WorldToViewportPoint(plr.Character.Head.Position)
                    local mag = (Vector2.new(pos.X, pos.Y) - UIS:GetMouseLocation()).Magnitude
                    if vis and mag < dist then
                        closest, dist = plr, mag
                    end
                end
            end
            return closest
        end

        RS.RenderStepped:Connect(function()
            if getgenv().Aimbot then
                local target = getClosest()
                if target and target.Character:FindFirstChild("Head") then
                    cam.CFrame = CFrame.new(cam.CFrame.Position, target.Character.Head.Position)
                end
            end
        end)
    end
})

-- TriggerBot
combatTab:CreateToggle({
    Name = "TriggerBot (auto click on target)",
    CurrentValue = false,
    Callback = function(on)
        getgenv().TriggerBot = on
        local mouse = lp:GetMouse()
        RS.RenderStepped:Connect(function()
            if getgenv().TriggerBot and mouse.Target and mouse.Target.Parent:FindFirstChild("Humanoid") then
                mouse1click()
            end
        end)
    end
})

-- Music
local sound = Instance.new("Sound", workspace)
sound.SoundId = "rbxassetid://1843524013"
sound.Volume = 1
sound.Looped = true
sound:Play()
