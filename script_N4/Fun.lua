local Wisper = _G.Wisper

local Fun = {
    CurrentEmoteTrack = nil,
    CurrentSound = nil,
    CurrentAnimation = nil,
    AvailableEmotes = {},
    EmotesFolder = nil,
    JerkTool = {
        active = false,
        tool = nil,
        track = nil
    },
    SpinConnection = nil,
    FlingConnection = nil
}

function Fun.Init(nxs)
    Wisper = nxs
    local Tabs = Wisper.Tabs
    
    local emotesInitialized = Fun.InitializeEmotesSystem()
    
    if emotesInitialized then
        Tabs.Fun:AddParagraph({
            Title = "Emotes System",
            Content = "Select an emote to play"
        })
        
        local emotesList = {}
        for _, emote in ipairs(Fun.AvailableEmotes) do
            table.insert(emotesList, emote)
        end
        table.insert(emotesList, "Jerk")
        table.insert(emotesList, 1, "--")
        
        local SelectedEmote = Tabs.Fun:AddDropdown("SelectedEmote", {
            Title = "Select Emote", 
            Description = "Choose an emote to play", 
            Values = emotesList, 
            Multi = false, 
            Default = "--"
        })
        
        SelectedEmote:OnChanged(function(value) 
            if value and value ~= "--" then 
                if value == "Jerk" then
                    Fun.StartJerk()
                else
                    Fun.PlayEmote(value) 
                end
                task.wait(0.1)
                SelectedEmote:SetValue("--")
            end 
        end)

        Tabs.Fun:AddButton({
            Title = "Stop Current Emote", 
            Description = "Stops the currently playing emote", 
            Callback = function()
                Fun.StopEmote()
            end
        })
    else
        Tabs.Fun:AddButton({
            Title = "Jerk Tool", 
            Description = "Adds Jerk Off tool to your backpack", 
            Callback = function()
                Fun.StartJerk()
            end
        })
    end
    
    Tabs.Fun:AddSection("Game Utilities")
    
    Tabs.Fun:AddButton({
        Title = "Reset Character", 
        Description = "Kills your character to respawn", 
        Callback = function()
            Fun.ResetCharacter()
        end
    })
    
    Tabs.Fun:AddButton({
        Title = "Rejoin Game", 
        Description = "Rejoins the current game server", 
        Callback = function()
            Fun.RejoinGame()
        end
    })
    
    Tabs.Fun:AddButton({
        Title = "Server Hop", 
        Description = "Joins a new random server", 
        Callback = function()
            Fun.ServerHop()
        end
    })
    
    Tabs.Fun:AddSection("Quick Actions")
    
    Tabs.Fun:AddButton({
        Title = "Suicide", 
        Description = "Instantly kills your character", 
        Callback = function()
            Fun.Suicide()
        end
    })
    
    Tabs.Fun:AddSection("Miscellaneous")

    Tabs.Fun:AddButton({
        Title = "Fling Nearest Player",
        Description = "Launches the closest player into the air",
        Callback = function()
            Fun.FlingNearest()
        end
    })

    local AutoFlingToggle = Tabs.Fun:AddToggle("AutoFling", {
        Title = "Auto Fling",
        Description = "Continuously flings the nearest player",
        Default = false
    })
    AutoFlingToggle:OnChanged(function(v)
        if v then Fun.StartAutoFling() else Fun.StopAutoFling() end
    end)

    local SpinToggle = Tabs.Fun:AddToggle("SpinCharacter", {
        Title = "Spin Character", 
        Description = "Makes your character spin continuously", 
        Default = false
    })
    
    SpinToggle:OnChanged(function(v)
        Fun.ToggleSpin(v)
    end)
end

function Fun.InitializeEmotesSystem()
    if not Wisper.Services.ReplicatedStorage:FindFirstChild("Emotes") then 
        return false 
    end
    
    Fun.EmotesFolder = Wisper.Services.ReplicatedStorage:WaitForChild("Emotes")
    Fun.AvailableEmotes = {}
    
    for _, folder in pairs(Fun.EmotesFolder:GetChildren()) do
        if folder:IsA("Folder") then 
            table.insert(Fun.AvailableEmotes, folder.Name) 
        end
    end
    
    table.sort(Fun.AvailableEmotes)
    return #Fun.AvailableEmotes > 0
end

function Fun.PlayEmote(emoteName)
    Fun.StopEmote()
    
    local emoteFolder = Fun.EmotesFolder:FindFirstChild(emoteName)
    if not emoteFolder then return end
    
    local animationId = emoteFolder:GetAttribute("animationid")
    local soundId = emoteFolder:GetAttribute("Song")
    if not animationId then return end
    
    local character = Wisper.getCharacter()
    local humanoid = Wisper.getHumanoid()
    if not character or not humanoid then return end
    
    local animation = Instance.new("Animation")
    animation.AnimationId = animationId
    Fun.CurrentAnimation = animation
    
    local animationTrack = humanoid:LoadAnimation(animation)
    animationTrack:Play(0.1, 1, 1)
    Fun.CurrentEmoteTrack = animationTrack
    
    if soundId and soundId ~= "" then
        local head = character:FindFirstChild("Head")
        if head then
            local sound = Instance.new("Sound")
            sound.SoundId = soundId
            sound.Parent = head
            sound:Play()
            Fun.CurrentSound = sound
            
            sound.Ended:Connect(function()
                if sound == Fun.CurrentSound then 
                    sound:Destroy()
                    Fun.CurrentSound = nil 
                end
            end)
        end
    end
    
    humanoid.Died:Connect(function()
        Fun.StopEmote()
    end)
end

function Fun.StopEmote()
    if Fun.CurrentEmoteTrack then 
        Fun.CurrentEmoteTrack:Stop()
        Fun.CurrentEmoteTrack = nil 
    end
    
    if Fun.CurrentSound then 
        Fun.CurrentSound:Stop()
        Fun.CurrentSound:Destroy()
        Fun.CurrentSound = nil 
    end
    
    Fun.CurrentAnimation = nil
end

function Fun.StartJerk()
    local humanoid = Wisper.getHumanoid()
    local backpack = Wisper.Player:FindFirstChildWhichIsA("Backpack")
    if not humanoid or not backpack then return end
    
    if Fun.JerkTool.tool and Fun.JerkTool.tool.Parent then
        Fun.StopJerk()
        return
    end
    
    local tool = Instance.new("Tool")
    tool.Name = "Jerk Off"
    tool.RequiresHandle = false
    tool.Parent = backpack
    
    Fun.JerkTool.tool = tool
    
    local function playAnimation()
        local currentHumanoid = Wisper.getHumanoid()
        if not currentHumanoid or currentHumanoid.Health <= 0 then return end
        
        local isR15 = currentHumanoid.RigType == Enum.HumanoidRigType.R15
        
        if Fun.JerkTool.track then
            Fun.JerkTool.track:Stop()
        end
        
        local animation = Instance.new("Animation")
        animation.AnimationId = isR15 and "rbxassetid://698251653" or "rbxassetid://72042024"
        
        local track = currentHumanoid:LoadAnimation(animation)
        Fun.JerkTool.track = track
        track.Looped = true
        track:Play()
        track:AdjustSpeed(isR15 and 0.7 or 0.65)
    end
    
    tool.Equipped:Connect(playAnimation)
    tool.Unequipped:Connect(function()
        if Fun.JerkTool.track then
            Fun.JerkTool.track:Stop()
        end
    end)
    
    humanoid.Died:Connect(function()
        if Fun.JerkTool.tool then
            Fun.StopJerk()
        end
    end)
    
    tool.AncestryChanged:Connect(function(_, parent)
        if not parent and Fun.JerkTool.tool == tool then
            if Fun.JerkTool.track then
                Fun.JerkTool.track:Stop()
            end
            Fun.JerkTool.tool = nil
        end
    end)
    
    playAnimation()
end

function Fun.StopJerk()
    if Fun.JerkTool.track then
        Fun.JerkTool.track:Stop()
        Fun.JerkTool.track = nil
    end
    
    if Fun.JerkTool.tool then
        Fun.JerkTool.tool:Destroy()
        Fun.JerkTool.tool = nil
    end
end

function Fun.ResetCharacter()
    local humanoid = Wisper.getHumanoid()
    if humanoid then
        humanoid.Health = 0
    end
end

function Fun.RejoinGame()
    local TeleportService = game:GetService("TeleportService")
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Wisper.Player)
end

function Fun.ServerHop()
    local TeleportService = game:GetService("TeleportService")
    TeleportService:Teleport(game.PlaceId, Wisper.Player)
end

function Fun.Suicide()
    local humanoid = Wisper.getHumanoid()
    if humanoid then
        humanoid.Health = 0
    end
end

function Fun.ToggleSpin(enabled)
    if enabled then
        Fun.StartSpin()
    else
        Fun.StopSpin()
    end
end

function Fun.GetNearestPlayer(maxRange)
    local myRoot = Wisper.getRootPart()
    if not myRoot then return nil end
    local closest = nil
    local closestDist = maxRange or math.huge
    for _, player in ipairs(Wisper.Services.Players:GetPlayers()) do
        if player ~= Wisper.Player and player.Character then
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            if root and hum and hum.Health > 0 then
                local dist = (root.Position - myRoot.Position).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closest = player
                end
            end
        end
    end
    return closest
end

function Fun.FlingNearest()
    local myRoot = Wisper.getRootPart()
    if not myRoot then return end

    local target = Fun.GetNearestPlayer(20)
    if not target or not target.Character then return end
    local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
    if not targetRoot then return end

    local origin = myRoot.CFrame
    task.spawn(function()
        local targetCF = targetRoot.CFrame
        for i = 1, 20 do
            pcall(function()
                myRoot.CFrame = targetCF
                targetRoot.AssemblyLinearVelocity = Vector3.new(
                    math.random(-2000, 2000),
                    math.random(1500, 3000),
                    math.random(-2000, 2000)
                )
            end)
            task.wait()
        end
        pcall(function() myRoot.CFrame = origin end)
    end)
end

function Fun.StartAutoFling()
    if Fun.FlingConnection then return end
    local returning = false
    Fun.FlingConnection = Wisper.Services.RunService.Heartbeat:Connect(function()
        if returning then return end
        local myRoot = Wisper.getRootPart()
        if not myRoot then return end

        local target = Fun.GetNearestPlayer(20)
        if not target or not target.Character then return end
        local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
        if not targetRoot then return end

        local origin = myRoot.CFrame
        returning = true
        pcall(function()
            myRoot.CFrame = targetRoot.CFrame
            targetRoot.AssemblyLinearVelocity = Vector3.new(
                math.random(-2000, 2000),
                math.random(1500, 3000),
                math.random(-2000, 2000)
            )
        end)
        task.wait()
        pcall(function() myRoot.CFrame = origin end)
        returning = false
    end)
end

function Fun.StopAutoFling()
    if Fun.FlingConnection then
        Fun.FlingConnection:Disconnect()
        Fun.FlingConnection = nil
    end
end

function Fun.StartSpin()
    local character = Wisper.getCharacter()
    if not character then return end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    if Fun.SpinConnection then
        Fun.SpinConnection:Disconnect()
    end
    
    Fun.SpinConnection = Wisper.Services.RunService.Heartbeat:Connect(function()
        if rootPart and rootPart.Parent then
            rootPart.CFrame = rootPart.CFrame * CFrame.Angles(0, math.rad(10), 0)
        else
            Fun.StopSpin()
        end
    end)
end

function Fun.StopSpin()
    if Fun.SpinConnection then
        Fun.SpinConnection:Disconnect()
        Fun.SpinConnection = nil
    end
end

function Fun.Cleanup()
    Fun.StopEmote()
    Fun.StopJerk()
    Fun.StopSpin()
    Fun.StopAutoFling()
    
    if Fun.SpinConnection then
        Fun.SpinConnection:Disconnect()
        Fun.SpinConnection = nil
    end
    
    if Fun.JerkTool.tool then
        Fun.StopJerk()
    end
end

Fun.Emotes = {
    Play = Fun.PlayEmote,
    Stop = Fun.StopEmote,
    StartJerk = Fun.StartJerk,
    StopJerk = Fun.StopJerk,
};
Fun.Spin = {
    Enable = Fun.StartSpin,
    Disable = Fun.StopSpin,
};
Fun.Fling = {
    Once = Fun.FlingNearest,
    StartAuto = Fun.StartAutoFling,
    StopAuto = Fun.StopAutoFling,
};
Fun.Utils = {
    Reset = Fun.ResetCharacter,
    Suicide = Fun.Suicide,
    Rejoin = Fun.RejoinGame,
    ServerHop = Fun.ServerHop,
};

return Fun