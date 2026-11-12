local Liquidation = _G.Liquidation

local Survivor = {
    Connections = {},
    States = {}
}

local function isSurvivorTeam()
    local player = Liquidation.Player
    if not player then return false end
    
    local team = player.Team
    if not team then return false end
    
    return team.Name:lower():find("survivor") or team.Name == "Survivors" or team.Name == "Survivor"
end

local function setupTeamListener(callback)

    local teamChangedConn = Liquidation.Player:GetPropertyChangedSignal("Team"):Connect(callback)
    
    local function onCharacterAdded(character)
        task.wait(0.5) 
        callback()
    end
    
    local charAddedConn = Liquidation.Player.CharacterAdded:Connect(onCharacterAdded)
    
    task.spawn(callback)
    
    return {teamChangedConn, charAddedConn}
end


local Crosshair = (function()
    local enabled = false
    local rainbowEnabled = false
    local currentType = "crosshair"
    local screenGui = nil
    local frame = nil
    local rainbowConnection = nil
    local teamListeners = {}
    
    local crosshairTypes = {
        crosshair = {
            create = function(parent)
                local container = Instance.new("Frame")
                container.Name = "Crosshair"
                container.BackgroundTransparency = 1
                container.Size = UDim2.new(0, 20, 0, 20)
                container.Position = UDim2.new(0.5, -10, 0.5, -10)
                container.ZIndex = 999

                local line1 = Instance.new("Frame")
                line1.Name = "Line1"
                line1.BackgroundColor3 = Color3.new(1, 1, 1)
                line1.BorderSizePixel = 0
                line1.Size = UDim2.new(0, 2, 0, 12)
                line1.Position = UDim2.new(0.5, -1, 0.5, -6)
                line1.Parent = container
                
                local line2 = Instance.new("Frame")
                line2.Name = "Line2"
                line2.BackgroundColor3 = Color3.new(1, 1, 1)
                line2.BorderSizePixel = 0
                line2.Size = UDim2.new(0, 12, 0, 2)
                line2.Position = UDim2.new(0.5, -6, 0.5, -1)
                line2.Parent = container
                
                return container
            end
        },
        
        dot = {
            create = function(parent)
                local container = Instance.new("Frame")
                container.Name = "Crosshair"
                container.BackgroundTransparency = 1
                container.Size = UDim2.new(0, 10, 0, 10)
                container.Position = UDim2.new(0.5, -5, 0.5, -5)
                container.ZIndex = 999
                
                local dot = Instance.new("Frame")
                dot.Name = "Dot"
                dot.BackgroundColor3 = Color3.new(1, 1, 1)
                dot.BorderSizePixel = 0
                dot.Size = UDim2.new(1, 0, 1, 0)
                dot.Position = UDim2.new(0, 0, 0, 0)
                dot.Parent = container
                
                local corner = Instance.new("UICorner")
                corner.CornerRadius = UDim.new(1, 0)
                corner.Parent = dot
                
                return container
            end
        },
        
        circle = {
            create = function(parent)
                local container = Instance.new("Frame")
                container.Name = "Crosshair"
                container.BackgroundTransparency = 1
                container.Size = UDim2.new(0, 16, 0, 16)
                container.Position = UDim2.new(0.5, -8, 0.5, -8)
                container.ZIndex = 999
                
                local outerCircle = Instance.new("Frame")
                outerCircle.Name = "OuterCircle"
                outerCircle.BackgroundColor3 = Color3.new(1, 1, 1)
                outerCircle.BackgroundTransparency = 0.5
                outerCircle.BorderSizePixel = 0
                outerCircle.Size = UDim2.new(1, 0, 1, 0)
                outerCircle.Position = UDim2.new(0, 0, 0, 0)
                outerCircle.Parent = container
                
                local outerCorner = Instance.new("UICorner")
                outerCorner.CornerRadius = UDim.new(1, 0)
                outerCorner.Parent = outerCircle
                
                local innerCircle = Instance.new("Frame")
                innerCircle.Name = "InnerCircle"
                innerCircle.BackgroundColor3 = Color3.new(0, 0, 0)
                innerCircle.BorderSizePixel = 0
                innerCircle.Size = UDim2.new(0, 6, 0, 6)
                innerCircle.Position = UDim2.new(0.5, -3, 0.5, -3)
                innerCircle.Parent = container
                
                local innerCorner = Instance.new("UICorner")
                innerCorner.CornerRadius = UDim.new(1, 0)
                innerCorner.Parent = innerCircle
                
                return container
            end
        }
    }
    
    local function destroyCrosshair()
        if frame then
            frame:Destroy()
            frame = nil
        end
        
        if rainbowConnection then
            rainbowConnection:Disconnect()
            rainbowConnection = nil
        end
    end
    
    local function createCrosshair()
        destroyCrosshair()
        
        if not enabled then return end
        
        if not screenGui or not screenGui.Parent then
            screenGui = Instance.new("ScreenGui")
            screenGui.Name = "NexusCrosshair"
            screenGui.DisplayOrder = 999
            screenGui.ResetOnSpawn = false
            screenGui.IgnoreGuiInset = true
            screenGui.Parent = Liquidation.Player:WaitForChild("PlayerGui")
        end
        
        local crosshairConfig = crosshairTypes[currentType]
        if crosshairConfig then
            frame = crosshairConfig.create(screenGui)
            frame.Parent = screenGui
        end
    end
    
    local function updateRainbowEffect()
        if not rainbowEnabled or not frame then
            if rainbowConnection then
                rainbowConnection:Disconnect()
                rainbowConnection = nil
            end
            return
        end
        
        if rainbowConnection then
            rainbowConnection:Disconnect()
        end
        
        rainbowConnection = Liquidation.Services.RunService.RenderStepped:Connect(function()
            if not frame or not rainbowEnabled then return end
            
            local time = tick()
            local hue = (time % 5) / 5  
            local color = Color3.fromHSV(hue, 1, 1)
            
            if currentType == "crosshair" then
                local line1 = frame:FindFirstChild("Line1")
                local line2 = frame:FindFirstChild("Line2")
                if line1 then line1.BackgroundColor3 = color end
                if line2 then line2.BackgroundColor3 = color end
            elseif currentType == "dot" then
                local dot = frame:FindFirstChild("Dot")
                if dot then dot.BackgroundColor3 = color end
            elseif currentType == "circle" then
                local outerCircle = frame:FindFirstChild("OuterCircle")
                if outerCircle then outerCircle.BackgroundColor3 = color end
            end
        end)
    end
    
    local function updateCrosshairState()
        if enabled then
            createCrosshair()
            updateRainbowEffect()
        else
            destroyCrosshair()
        end
    end
    
    local function Enable()
        if enabled then return end
        enabled = true
        Liquidation.States.CrosshairEnabled = true
        
        for _, listener in ipairs(teamListeners) do
            if type(listener) == "table" then
                for _, conn in ipairs(listener) do
                    Liquidation.safeDisconnect(conn)
                end
            else
                Liquidation.safeDisconnect(listener)
            end
        end
        
        teamListeners = {}
    
        table.insert(teamListeners, setupTeamListener(updateCrosshairState))
        
        updateCrosshairState()
    end
    
    local function Disable()
        if not enabled then return end
        enabled = false
        Liquidation.States.CrosshairEnabled = false
        Liquidation.States.RainbowCrosshairEnabled = false
        
        if rainbowConnection then
            rainbowConnection:Disconnect()
            rainbowConnection = nil
        end
        
        if frame then
            if currentType == "crosshair" then
                local line1 = frame:FindFirstChild("Line1")
                local line2 = frame:FindFirstChild("Line2")
                if line1 then line1.BackgroundColor3 = Color3.new(1, 1, 1) end
                if line2 then line2.BackgroundColor3 = Color3.new(1, 1, 1) end
            elseif currentType == "dot" then
                local dot = frame:FindFirstChild("Dot")
                if dot then dot.BackgroundColor3 = Color3.new(1, 1, 1) end
            elseif currentType == "circle" then
                local outerCircle = frame:FindFirstChild("OuterCircle")
                if outerCircle then outerCircle.BackgroundColor3 = Color3.new(1, 1, 1) end
            end
        end
        
        destroyCrosshair()
        
        if screenGui then
            screenGui:Destroy()
            screenGui = nil
        end
        
        for _, listener in ipairs(teamListeners) do
            if type(listener) == "table" then
                for _, conn in ipairs(listener) do
                    Liquidation.safeDisconnect(conn)
                end
            else
                Liquidation.safeDisconnect(listener)
            end
        end
        teamListeners = {}
    end
    
    local function setType(typeName)
        if not crosshairTypes[typeName] then
            typeName = "crosshair"
        end
        
        currentType = typeName
        
        if enabled then
            updateCrosshairState()
        end
    end
    
    local function toggleRainbow(value)
        rainbowEnabled = value
        Liquidation.States.RainbowCrosshairEnabled = value
        
        if not value and frame then
            if currentType == "crosshair" then
                local line1 = frame:FindFirstChild("Line1")
                local line2 = frame:FindFirstChild("Line2")
                if line1 then line1.BackgroundColor3 = Color3.new(1, 1, 1) end
                if line2 then line2.BackgroundColor3 = Color3.new(1, 1, 1) end
            elseif currentType == "dot" then
                local dot = frame:FindFirstChild("Dot")
                if dot then dot.BackgroundColor3 = Color3.new(1, 1, 1) end
            elseif currentType == "circle" then
                local outerCircle = frame:FindFirstChild("OuterCircle")
                if outerCircle then outerCircle.BackgroundColor3 = Color3.new(1, 1, 1) end
            end
        end
        
        if enabled then
            updateRainbowEffect()
        end
    end
    
    return {
        Enable = Enable,
        Disable = Disable,
        IsEnabled = function() return enabled end,
        SetType = setType,
        GetCurrentType = function() return currentType end,
        ToggleRainbow = toggleRainbow,
        IsRainbowEnabled = function() return rainbowEnabled end
    }
end)()

local TwistSilentAim = (function()
    local enabled = false
    local hooked = false
    local originalNamecall = nil
    local teamListeners = {}
    local isFiring = false
    local remote = nil
    
    local function getRemote()
        local success = pcall(function()
            remote = Liquidation.Services.ReplicatedStorage:WaitForChild("Remotes", 5)
                :WaitForChild("Items", 5)
                :WaitForChild("Twist of Fate", 5)
                :WaitForChild("Fire", 5)
        end)
        return remote ~= nil
    end
    
    local function GetClosestPlayer()
        local closestPlayer = nil
        local closestDistance = math.huge
        local myPos = workspace.CurrentCamera.CFrame.Position
        
        for _, player in pairs(Liquidation.Services.Players:GetPlayers()) do
            if player ~= Liquidation.Player and player.Character then
                local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
                local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
                if humanoid and humanoid.Health > 0 and rootPart then
                    local distance = (rootPart.Position - myPos).Magnitude
                    if distance < closestDistance then
                        closestDistance = distance
                        closestPlayer = player
                    end
                end
            end
        end
        return closestPlayer
    end
    
    local function setupHook()
        if hooked then return true end
        if not getRemote() then return false end
        
        originalNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local method = getnamecallmethod()
            
            if method == "FireServer" and self == remote and enabled and not isFiring then
                local gunPart, direction = ...
                
                if gunPart and typeof(gunPart) == "Instance" and direction and typeof(direction) == "Vector3" then
                    local target = GetClosestPlayer()
                    if target and target.Character then
                        local targetPart = target.Character:FindFirstChild("HumanoidRootPart")
                        if targetPart then
                            local cameraPos = workspace.CurrentCamera.CFrame.Position
                            local newDirection = (targetPart.Position - cameraPos).Unit
                            print("[Twist Silent Aim] " .. target.Name)
                            isFiring = true
                            remote:FireServer(gunPart, newDirection)
                            isFiring = false
                            return nil
                        end
                    end
                end
            end
            
            return originalNamecall(self, ...)
        end))
        
        hooked = true
        return true
    end
    
    local function updateTwistSilentAim()
        if enabled and isSurvivorTeam() then
            if not setupHook() then
                task.spawn(function()
                    for i = 1, 5 do
                        task.wait(1)
                        if enabled and isSurvivorTeam() and not hooked then
                            if setupHook() then break end
                        end
                    end
                end)
            end
        end
    end
    
    local function Enable()
        if enabled then return end
        enabled = true
        Liquidation.States.TwistSilentAimEnabled = true
        
        for _, listener in ipairs(teamListeners) do
            if type(listener) == "table" then
                for _, conn in ipairs(listener) do
                    Liquidation.safeDisconnect(conn)
                end
            else
                Liquidation.safeDisconnect(listener)
            end
        end
        
        teamListeners = {}
        
        table.insert(teamListeners, setupTeamListener(updateTwistSilentAim))
        
        updateTwistSilentAim()
    end
    
    local function Disable()
        if not enabled then return end
        enabled = false
        Liquidation.States.TwistSilentAimEnabled = false
        
        for _, listener in ipairs(teamListeners) do
            if type(listener) == "table" then
                for _, conn in ipairs(listener) do
                    Liquidation.safeDisconnect(conn)
                end
            else
                Liquidation.safeDisconnect(listener)
            end
        end
        teamListeners = {}
    end
    
    return {
        Enable = Enable,
        Disable = Disable,
        IsEnabled = function() return enabled end
    }
end)()

-- FAST VAULT --

local FastVault = (function()
    local enabled = false
    local hookInstalled = false
    local processing = false
    local originalNamecall = nil
    
    local VaultEvent = nil
    local VaultCompleteEvent = nil
    local PalletSlideEvent = nil
    local FastVaultRemote = nil
    
    local function setFlowstate()
        local character = Liquidation.Player.Character
        if character then
            pcall(character.SetAttribute, character, "Flowstate", true)
        end
    end
    
    local function setupHook()
        if hookInstalled then return true end
        
        local success = pcall(function()
            local Remotes = Liquidation.Services.ReplicatedStorage:WaitForChild("Remotes")
            VaultEvent = Remotes.Window:WaitForChild("VaultEvent")
            VaultCompleteEvent = Remotes.Window:WaitForChild("VaultCompleteEvent")
            PalletSlideEvent = Remotes.Pallet:WaitForChild("PalletSlideEvent")
            FastVaultRemote = Remotes.Window:FindFirstChild("fastvault")
        end)
        
        if not success or not VaultEvent then return false end
        
        originalNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            if not enabled or processing then return originalNamecall(self, ...) end
            local method = getnamecallmethod()
            if method ~= "FireServer" then return originalNamecall(self, ...) end
            
            local args = {...}
            
            if self == VaultEvent and args[1] then
                setFlowstate()
                processing = true
                if FastVaultRemote then
                    FastVaultRemote:FireServer(Liquidation.Player)
                end
                VaultEvent:FireServer(args[1], true)
                processing = false
                return
            end
            
            if self == VaultCompleteEvent and args[1] then
                processing = true
                VaultCompleteEvent:FireServer(args[1], true)
                processing = false
                return
            end
            
            if self == PalletSlideEvent and args[1] then
                setFlowstate()
                processing = true
                if FastVaultRemote then
                    FastVaultRemote:FireServer(Liquidation.Player)
                end
                PalletSlideEvent:FireServer(args[1], true)
                processing = false
                return
            end
            
            return originalNamecall(self, ...)
        end))
        
        hookInstalled = true
        return true
    end
    
    local function Enable()
        if enabled then return end
        enabled = true
        Liquidation.States.FastVaultEnabled = true
        
        if not hookInstalled then
            setupHook()
        end
    end
    
    local function Disable()
        if not enabled then return end
        enabled = false
        Liquidation.States.FastVaultEnabled = false
    end
    
    return {
        Enable = Enable,
        Disable = Disable,
        IsEnabled = function() return enabled end
    }
end)()

------ AUTO VICTORY (SURVIVOR) -----

local AutoVictory = (function()
    local enabled = false
    local lastFinishPos = nil
    local beatSurvivorDone = false
    local connection = nil
    local teamListeners = {}
    
    local function findExitPosition()
        local map = Liquidation.Services.Workspace:FindFirstChild("Map")
        if not map then return nil end
        
        local exitPos = nil
        
        if map:FindFirstChild("RooftopHitbox") or map:FindFirstChild("Rooftop") then
            exitPos = Vector3.new(3098.16, 454.04, -4918.74)
            return exitPos
        end
        
        if map:FindFirstChild("HooksMeat") then
            exitPos = Vector3.new(1546.12, 152.21, -796.72)
            return exitPos
        end
        
        if map:FindFirstChild("churchbell") then
            exitPos = Vector3.new(760.98, -20.14, -78.48)
            return exitPos
        end
        
        local finish = map:FindFirstChild("Finishline") or map:FindFirstChild("FinishLine") or map:FindFirstChild("Fininshline")
        if finish then
            if finish:IsA("BasePart") then
                exitPos = finish.Position
            elseif finish:IsA("Model") then
                local part = finish:FindFirstChildWhichIsA("BasePart")
                if part then exitPos = part.Position end
            end
            return exitPos
        end
        
        for _, obj in ipairs(map:GetDescendants()) do
            if obj.Name:lower():find("finish") then
                if obj:IsA("BasePart") then
                    exitPos = obj.Position
                    break
                elseif obj:IsA("Model") then
                    local part = obj:FindFirstChildWhichIsA("BasePart")
                    if part then 
                        exitPos = part.Position
                        break
                    end
                end
            end
        end
        
        if not exitPos then
            for _, obj in ipairs(map:GetDescendants()) do
                if obj:IsA("MeshPart") and obj.Material == Enum.Material.Limestone then
                    exitPos = Vector3.new(-947.90, 152.12, -7579.52)
                    break
                end
            end
        end
        
        if not exitPos then
            for _, obj in ipairs(map:GetDescendants()) do
                if obj:IsA("MeshPart") and obj.Material == Enum.Material.Leather then
                    exitPos = Vector3.new(1546.12, 152.21, -796.72)
                    break
                end
            end
        end
        
        return exitPos
    end
    
    local function teleportToExit()
        if not enabled then return end
        
        if not isSurvivorTeam() then 
            beatSurvivorDone = false
            lastFinishPos = nil
            return 
        end
        
        local character = Liquidation.getCharacter()
        if not character then return end
        
        local root = character:FindFirstChild("HumanoidRootPart")
        if not root then return end
        
        local exitPos = findExitPosition()
        if not exitPos then 
            return 
        end
        
        if lastFinishPos then
            local dist = (exitPos - lastFinishPos).Magnitude
            if dist > 50 then
                beatSurvivorDone = false
            end
        end
        
        if beatSurvivorDone then return end
        
        root.CFrame = CFrame.new(exitPos + Vector3.new(0, 3, 0))
        
        beatSurvivorDone = true
        lastFinishPos = exitPos
        
    end
    
    local function updateAutoVictory()
        if connection then
            connection:Disconnect()
            connection = nil
        end
        
        if enabled and isSurvivorTeam() then
            connection = Liquidation.Services.RunService.Heartbeat:Connect(function()
                if enabled and isSurvivorTeam() then
                    teleportToExit()
                end
            end)
        elseif enabled then
        end
    end
    
    local function Enable()
        if enabled then return end
        enabled = true
        Liquidation.States.AutoVictoryEnabled = true
        
        for _, listener in ipairs(teamListeners) do
            if type(listener) == "table" then
                for _, conn in ipairs(listener) do
                    Liquidation.safeDisconnect(conn)
                end
            else
                Liquidation.safeDisconnect(listener)
            end
        end
        
        teamListeners = {}
        
        beatSurvivorDone = false
        lastFinishPos = nil
        
        table.insert(teamListeners, setupTeamListener(updateAutoVictory))
        
        updateAutoVictory()
    end
    
    local function Disable()
        if not enabled then return end
        enabled = false
        Liquidation.States.AutoVictoryEnabled = false
        
        if connection then
            connection:Disconnect()
            connection = nil
        end
        
        beatSurvivorDone = false
        lastFinishPos = nil
        
        for _, listener in ipairs(teamListeners) do
            if type(listener) == "table" then
                for _, conn in ipairs(listener) do
                    Liquidation.safeDisconnect(conn)
                end
            else
                Liquidation.safeDisconnect(listener)
            end
        end
        teamListeners = {}
    end
    
    return {
        Enable = Enable,
        Disable = Disable,
        IsEnabled = function() return enabled end,
        ResetState = function()
            beatSurvivorDone = false
            lastFinishPos = nil
        end
    }
end)()

-- AUTO VICTORY V2 (SURVIVOR) --

local AutoVictoryV2 = (function()
    local enabled = false
    local eventFired = false
    local teamListeners = {}
    
    local function getShowResultsEvent()
        local success, event = pcall(function()
            return Liquidation.Services.ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Game"):WaitForChild("showresults")
        end)
        return success and event or nil
    end
    
    local function fireEventOnce()
        if eventFired then return end
        
        local Event = getShowResultsEvent()
        if Event then
            pcall(function()
                firesignal(Event.OnClientEvent)
                eventFired = true
            end)
        else
        end
    end
    
    local function resetEventState()
        eventFired = false
    end
    
    local function updateAutoVictoryV2State()
        if enabled and isSurvivorTeam() then
            resetEventState()
            fireEventOnce()
        else
            resetEventState()
        end
    end
    
    local function Enable()
        if enabled then return end
        enabled = true
        Liquidation.States.AutoVictoryV2Enabled = true
        
        for _, listener in ipairs(teamListeners) do
            if type(listener) == "table" then
                for _, conn in ipairs(listener) do
                    Liquidation.safeDisconnect(conn)
                end
            else
                Liquidation.safeDisconnect(listener)
            end
        end
        
        teamListeners = {}
        
        table.insert(teamListeners, setupTeamListener(updateAutoVictoryV2State))
        
        updateAutoVictoryV2State()
    end
    
    local function Disable()
        if not enabled then return end
        enabled = false
        Liquidation.States.AutoVictoryV2Enabled = false
        
        resetEventState()
        
        for _, listener in ipairs(teamListeners) do
            if type(listener) == "table" then
                for _, conn in ipairs(listener) do
                    Liquidation.safeDisconnect(conn)
                end
            else
                Liquidation.safeDisconnect(listener)
            end
        end
        teamListeners = {}
    end
    
    return {
        Enable = Enable,
        Disable = Disable,
        IsEnabled = function() return enabled end
    }
end)()

-- NO SLOWDOWN --

local NoSlowdown = (function()
    local enabled = false
    local connection = nil
    local teamListeners = {}

    local function setupNoSlowdownForCharacter(character)
        if not enabled or not isSurvivorTeam() then return end
        
        task.wait(0.5) 
        
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid:SetAttribute("NoSlowdown", true)
            humanoid.WalkSpeed = 16
            
            if connection then
                connection:Disconnect()
            end
            
            connection = humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
                if enabled and isSurvivorTeam() and humanoid and humanoid.WalkSpeed ~= 16 then
                    humanoid.WalkSpeed = 16
                end
            end)
            
            humanoid.Died:Connect(function()
                if enabled then
                    task.wait(2) 
                    local newChar = Liquidation.getCharacter()
                    if newChar then
                        setupNoSlowdownForCharacter(newChar)
                    end
                end
            end)
        end
    end
    
    local function updateNoSlowdownState()
        if enabled and isSurvivorTeam() then
            local character = Liquidation.getCharacter()
            if character then
                setupNoSlowdownForCharacter(character)
            end
        elseif enabled then
            if connection then
                connection:Disconnect()
                connection = nil
            end
        else
            if connection then
                connection:Disconnect()
                connection = nil
            end
            
            local character = Liquidation.getCharacter()
            if character then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid:SetAttribute("NoSlowdown", nil)
                end
            end
        end
    end
    
    local function Enable()
        if enabled then return end
        enabled = true
        Liquidation.States.NoSlowdownEnabled = true
        
        for _, listener in ipairs(teamListeners) do
            if type(listener) == "table" then
                for _, conn in ipairs(listener) do
                    Liquidation.safeDisconnect(conn)
                end
            else
                Liquidation.safeDisconnect(listener)
            end
        end
        
        teamListeners = {}
        
        table.insert(teamListeners, setupTeamListener(updateNoSlowdownState))
        
        table.insert(teamListeners, setupCharacterListener(function(character)
            if enabled and isSurvivorTeam() then
                setupNoSlowdownForCharacter(character)
            end
        end))
        
        updateNoSlowdownState()
    end
    
    local function Disable()
        if not enabled then return end
        enabled = false
        Liquidation.States.NoSlowdownEnabled = false
        
        if connection then
            connection:Disconnect()
            connection = nil
        end
        
        local character = Liquidation.getCharacter()
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid:SetAttribute("NoSlowdown", nil)
            end
        end
        
            for _, listener in ipairs(teamListeners) do
            if type(listener) == "table" then
                for _, conn in ipairs(listener) do
                    Liquidation.safeDisconnect(conn)
                end
            else
                Liquidation.safeDisconnect(listener)
            end
        end
        teamListeners = {}
    end
    
    return {
        Enable = Enable,
        Disable = Disable,
        IsEnabled = function() return enabled end
    }
end)()

-- AUTO PARRY 

local AutoParry = (function()
    local spamActive = false
    local RANGE = 10
    local teamListeners = {}
    local animConnections = {}
    local playerAddedConn = nil
    local playerRemovingConn = nil

    local AttackAnimations = {
         "rbxassetid://110355011987939",
         "rbxassetid://139369275981139",
         "rbxassetid://117042998468241",
         "rbxassetid://133963973694098",
         "rbxassetid://113255068724446",
         "rbxassetid://74968262036854",
         "rbxassetid://118907603246885",
         "rbxassetid://78432063483146",
         "rbxassetid://129784271201071",
         "rbxassetid://122812055447896",
         "rbxassetid://138720291317243",
         "rbxassetid://106871536134254", 
         "rbxassetid://109402730355822", 
         "rbxassetid://111920872708571",
         "rbxassetid://105374834496520",
         "rbxassetid://137795837089724",
         "rbxassetid://121216847022485"
    }

    local AttackAnimationsLookup = {}
    for _, animId in ipairs(AttackAnimations) do
        AttackAnimationsLookup[animId] = true
    end

    local function PerformParry()
        if spamActive then return end
        spamActive = true
        Liquidation.Services.VirtualInputManager:SendMouseButtonEvent(0, 0, 1, true, game, 0)
        task.spawn(function()
            task.wait()
            Liquidation.Services.VirtualInputManager:SendMouseButtonEvent(0, 0, 1, false, game, 0)
            spamActive = false
        end)
    end

    local function isInRange(targetCharacter)
        local myChar = Liquidation.Player.Character
        if not myChar then return false end
        local myRoot = myChar:FindFirstChild("HumanoidRootPart")
        local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")
        if not myRoot or not targetRoot then return false end
        return (myRoot.Position - targetRoot.Position).Magnitude <= RANGE
    end

    local function disconnectPlayer(player)
        if animConnections[player] then
            for _, conn in ipairs(animConnections[player]) do
                pcall(function() conn:Disconnect() end)
            end
            animConnections[player] = nil
        end
    end

    local function connectCharacter(player, character)
        disconnectPlayer(player)
        if player == Liquidation.Player then return end

        animConnections[player] = {}

        local function onAnimPlayed(animTrack)
            if not Liquidation.States.AutoParryEnabled then return end
            if not isSurvivorTeam() then return end

            local animId = animTrack.Animation and animTrack.Animation.AnimationId
            if animId and AttackAnimationsLookup[animId] then
                if isInRange(character) then
                    PerformParry()
                end
            end
        end

        local function tryConnect()
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if not humanoid then return end

            local animator = humanoid:FindFirstChildOfClass("Animator")
            if not animator then
                local waitConn
                waitConn = humanoid.ChildAdded:Connect(function(child)
                    if child:IsA("Animator") then
                        waitConn:Disconnect()
                        local animPlayedConn = child.AnimationPlayed:Connect(onAnimPlayed)
                        table.insert(animConnections[player], animPlayedConn)
                    end
                end)
                table.insert(animConnections[player], waitConn)
                return
            end

            local animPlayedConn = animator.AnimationPlayed:Connect(onAnimPlayed)
            table.insert(animConnections[player], animPlayedConn)
        end

        tryConnect()

        local charAddedConn = player.CharacterAdded:Connect(function(newChar)
            task.wait(0.1)
            if Liquidation.States.AutoParryEnabled then
                connectCharacter(player, newChar)
            end
        end)
        table.insert(animConnections[player], charAddedConn)
    end

    local function connectAllPlayers()
        for _, player in ipairs(Liquidation.Services.Players:GetPlayers()) do
            if player ~= Liquidation.Player and player.Character then
                connectCharacter(player, player.Character)
            elseif player ~= Liquidation.Player then
                animConnections[player] = {}
                local charConn = player.CharacterAdded:Connect(function(char)
                    task.wait(0.1)
                    connectCharacter(player, char)
                end)
                table.insert(animConnections[player], charConn)
            end
        end

        playerAddedConn = Liquidation.Services.Players.PlayerAdded:Connect(function(player)
            animConnections[player] = {}
            local conn = player.CharacterAdded:Connect(function(char)
                task.wait(0.1)
                connectCharacter(player, char)
            end)
            table.insert(animConnections[player], conn)
        end)

        playerRemovingConn = Liquidation.Services.Players.PlayerRemoving:Connect(function(player)
            disconnectPlayer(player)
        end)
    end

    local function disconnectAll()
        for player, _ in pairs(animConnections) do
            disconnectPlayer(player)
        end
        animConnections = {}
        if playerAddedConn then playerAddedConn:Disconnect(); playerAddedConn = nil end
        if playerRemovingConn then playerRemovingConn:Disconnect(); playerRemovingConn = nil end
    end

    local function setupAutoParry()
        disconnectAll()
        if Liquidation.States.AutoParryEnabled and isSurvivorTeam() then
            connectAllPlayers()
        end
    end

    local function Enable()
        if Liquidation.States.AutoParryEnabled then return end
        Liquidation.States.AutoParryEnabled = true

        for _, listener in ipairs(teamListeners) do
            if type(listener) == "table" then
                for _, conn in ipairs(listener) do
                    Liquidation.safeDisconnect(conn)
                end
            else
                Liquidation.safeDisconnect(listener)
            end
        end
        teamListeners = {}

        table.insert(teamListeners, setupTeamListener(setupAutoParry))
        setupAutoParry()
    end

    local function Disable()
        Liquidation.States.AutoParryEnabled = false
        if spamActive then
            spamActive = false
            Liquidation.Services.VirtualInputManager:SendMouseButtonEvent(0, 0, 1, false, game, 0)
        end
        disconnectAll()

        for _, listener in ipairs(teamListeners) do
            if type(listener) == "table" then
                for _, conn in ipairs(listener) do
                    Liquidation.safeDisconnect(conn)
                end
            else
                Liquidation.safeDisconnect(listener)
            end
        end
        teamListeners = {}
    end

    return {
        Enable = Enable,
        Disable = Disable,
        IsEnabled = function() return Liquidation.States.AutoParryEnabled end,
        SetRange = function(value) 
            RANGE = tonumber(value) or 10
        end,
        GetRange = function() return RANGE end
    }
end)()

-- AUTOPARRY V2 --

local AutoParryV2 = (function()
    local enabled = false
local DETECT_RADIUS = 20      -- Радиус обнаружения игроков (studs)
local SWING_THRESHOLD = 0.01  -- Минимальная скорость движения руки за тик для срабатывания (studs/tick)
local ACCEL_THRESHOLD = 0.3   -- Минимальное ускорение (резкость замаха) для срабатывания
local CLICK_HOLD = 0.1       -- Сколько секунд удерживать ПКМ
local COOLDOWN = 0.5           -- Пауза между нажатиями (секунды)
local CHECK_RATE = 0.05 
local VIEW_ANGLE_THRESHOLD = 90 -- Максимальный угол (градусы) для проверки направления взгляда Killer'а
    local teamListeners = {}
    local connection = nil
    local lastArmPos = nil
    local lastDelta = 0
    local lastCheckTime = 0
    local onCooldown = false

    local function isKillerTeam(player)
        local team = player.Team
        if not team then return false end
        local name = team.Name:lower()
        return name == "killer" or name == "killers" or name == "Killer Team" or name == "Killer"
    end

    local function getTarget()
        local localChar = Liquidation.Player.Character
        local localRoot = localChar and localChar:FindFirstChild("HumanoidRootPart")
        if not localRoot then return nil end

        local nearest, nearestDist = nil, math.huge
        for _, player in ipairs(Liquidation.Services.Players:GetPlayers()) do
            if player ~= Liquidation.Player and player.Character and isKillerTeam(player) then
                local root = player.Character:FindFirstChild("HumanoidRootPart")
                if root then
                    local dist = (root.Position - localRoot.Position).Magnitude
                    if dist < nearestDist then
                        nearestDist = dist
                        nearest = player
                    end
                end
            end
        end
        return nearest
    end

    local function getRightArm(character)
        if not character then return nil end
        return character:FindFirstChild("RightUpperArm") or character:FindFirstChild("Right Arm")
    end

    local function clickRMB()
        local x = workspace.CurrentCamera.ViewportSize.X / 2
        local y = workspace.CurrentCamera.ViewportSize.Y / 2
        Liquidation.Services.VirtualInputManager:SendMouseButtonEvent(x, y, 1, true, game, 1)
        task.delay(CLICK_HOLD, function()
            Liquidation.Services.VirtualInputManager:SendMouseButtonEvent(x, y, 1, false, game, 1)
        end)
    end

    local function updateLoop()
        if not enabled or not isSurvivorTeam() then return end

        local now = tick()
        if now - lastCheckTime < CHECK_RATE then return end
        lastCheckTime = now

        local target = getTarget()
        if not target or not target.Character then
            lastArmPos = nil
            return
        end

        local localChar = Liquidation.Player.Character
        local localRoot = localChar and localChar:FindFirstChild("HumanoidRootPart")
        local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
        if not localRoot or not targetRoot then
            lastArmPos = nil
            return
        end
        if (targetRoot.Position - localRoot.Position).Magnitude > DETECT_RADIUS then
            lastArmPos = nil
            return
        end

        -- Проверка направления взгляда Killer'а
        local directionToSurvivor = (localRoot.Position - targetRoot.Position).Unit
        local lookVector = targetRoot.CFrame.LookVector
        local dotProduct = lookVector:Dot(directionToSurvivor)
        local angle = math.acos(math.clamp(dotProduct, -1, 1)) * 180 / math.pi
        if angle > VIEW_ANGLE_THRESHOLD then
            lastArmPos = nil
            return
        end

        local arm = getRightArm(target.Character)
        if not arm then
            lastArmPos = nil
            return
        end

        local currentPos = arm.Position

        if lastArmPos then
            local delta = (currentPos - lastArmPos).Magnitude
            local accel = delta - lastDelta
            if delta > SWING_THRESHOLD and accel > ACCEL_THRESHOLD and not onCooldown then
                onCooldown = true
                clickRMB()
                task.delay(COOLDOWN, function()
                    onCooldown = false
                end)
            end
            lastDelta = delta
        else
            lastDelta = 0
        end

        lastArmPos = currentPos
    end

    local function Enable()
        if enabled then return end
        enabled = true
        Liquidation.States.AutoParryV2Enabled = true

        for _, listener in ipairs(teamListeners) do
            Liquidation.safeDisconnect(listener)
        end
        teamListeners = {}

        table.insert(teamListeners, setupTeamListener(function()
            if enabled and isSurvivorTeam() then
                connection = Liquidation.Services.RunService.Heartbeat:Connect(updateLoop)
            else
                if connection then
                    connection:Disconnect()
                    connection = nil
                end
            end
        end))

        if isSurvivorTeam() then
            connection = Liquidation.Services.RunService.Heartbeat:Connect(updateLoop)
        end
    end

    local function Disable()
        enabled = false
        Liquidation.States.AutoParryV2Enabled = false
        if connection then
            connection:Disconnect()
            connection = nil
        end
        for _, listener in ipairs(teamListeners) do
            Liquidation.safeDisconnect(listener)
        end
        teamListeners = {}
        lastArmPos = nil
    end

    local function SetRadius(value)
        DETECT_RADIUS = tonumber(value) or 20
    end

    return {
        Enable = Enable,
        Disable = Disable,
        SetRadius = SetRadius
    }
end)()

--  FAKE PARRY --

local FakeParry = (function()
    local enabled = false
    local animationId = "rbxassetid://127096285501517"
    local animationTrack = nil
    local characterConnection = nil
    local teamListeners = {}
    
    local function stopAnimation()
        if animationTrack then
            animationTrack:Stop()
            animationTrack = nil
        end
    end
    
    local function startAnimation()
        if not isSurvivorTeam() then return false end
        
        local character = Liquidation.getCharacter()
        if not character then return false end
        
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return false end
        
        local animation = Instance.new("Animation")
        animation.AnimationId = animationId
        
        animationTrack = humanoid:LoadAnimation(animation)
        if animationTrack then
            animationTrack:Play()
            
            animationTrack.Stopped:Connect(function()
                animationTrack = nil
            end)
            
            return true
        end
        
        return false
    end
    
    local function setupCharacterListeners()
        if characterConnection then
            characterConnection:Disconnect()
            characterConnection = nil
        end
        
        if not isSurvivorTeam() then return end
        
        local character = Liquidation.getCharacter()
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.Died:Connect(stopAnimation)
            end
        end
        
        characterConnection = Liquidation.Player.CharacterAdded:Connect(function(newCharacter)
            if enabled and isSurvivorTeam() then
                task.wait(1) 
                
                local humanoid = newCharacter:WaitForChild("Humanoid", 5)
                if humanoid then
                            
                    humanoid.Died:Connect(stopAnimation)
                    
                    task.wait(0.5)
                            
                    startAnimation()
                end
            end
        end)
    end
    
    local function updateFakeParry()
        if not isSurvivorTeam() then
            stopAnimation()
            return
        end
        
        if enabled then
            setupCharacterListeners()
            if not startAnimation() then
            end
        else
            stopAnimation()
        end
    end
    
    local function Enable()
        if enabled then return end
        enabled = true
        Liquidation.States.FakeParryEnabled = true
        
        for _, listener in ipairs(teamListeners) do
            if type(listener) == "table" then
                for _, conn in ipairs(listener) do
                    Liquidation.safeDisconnect(conn)
                end
            else
                Liquidation.safeDisconnect(listener)
            end
        end
        
        teamListeners = {}
        
        table.insert(teamListeners, setupTeamListener(updateFakeParry))
        
        updateFakeParry()
    end
    
    local function Disable()
        if not enabled then return end
        enabled = false
        Liquidation.States.FakeParryEnabled = false
        
        stopAnimation()
        
        if characterConnection then
            characterConnection:Disconnect()
            characterConnection = nil
        end
        
        for _, listener in ipairs(teamListeners) do
            if type(listener) == "table" then
                for _, conn in ipairs(listener) do
                    Liquidation.safeDisconnect(conn)
                end
            else
                Liquidation.safeDisconnect(listener)
            end
        end
        teamListeners = {}
    end
    
    return {
        Enable = Enable,
        Disable = Disable,
        IsEnabled = function() return enabled end,
        RestartAnimation = function()
            if enabled and isSurvivorTeam() then
                stopAnimation()
                task.wait(0.1)
                startAnimation()
            end
        end
    }
end)()

-- HEALING -- (instant heal and silent heal) 

local healingStates = {
    silentHealRunning = false,
    instantHealRunning = false,
    lastHealTime = 0,
    healCooldown = 0.2
}

local function StartInstantHeal()
    Liquidation.States.InstantHealRunning = true
    healingStates.instantHealRunning = true
    
    Survivor.Connections.instantHeal = task.spawn(function()
        while healingStates.instantHealRunning do
            local char = Liquidation.getCharacter()
            local myRoot = char and char:FindFirstChild("HumanoidRootPart")
            
            if char and myRoot then
                local myPosition = myRoot.Position
                
                for _, target in ipairs(Liquidation.Services.Players:GetPlayers()) do
                    if target == Liquidation.Player then continue end
                    
                    if target.Character then
                        local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
                        if targetRoot then
                            local shouldHeal = true
                            
                            if not healingStates.silentHealRunning then
                                local distance = (myPosition - targetRoot.Position).Magnitude
                                shouldHeal = distance <= 15
                            end
                            
                            if shouldHeal then
                                local humanoid = target.Character:FindFirstChild("Humanoid")
                                if humanoid and humanoid.Health < humanoid.MaxHealth then
                                    pcall(function() 
                                        if Liquidation.Services.ReplicatedStorage.Remotes and 
                                           Liquidation.Services.ReplicatedStorage.Remotes.Healing then
                                            Liquidation.Services.ReplicatedStorage.Remotes.Healing.SkillCheckResultEvent:FireServer("success", 1, target.Character)
                                        end
                                    end)
                                end
                            end
                        end
                    end
                end
            end
            task.wait() 
        end
    end)
end

local function StopInstantHeal()
    healingStates.instantHealRunning = false
    Liquidation.States.InstantHealRunning = false
    Liquidation.safeDisconnect(Survivor.Connections.instantHeal)
end

local function SendStopHealEvent()
    pcall(function()
        if Liquidation.Services.ReplicatedStorage.Remotes and 
           Liquidation.Services.ReplicatedStorage.Remotes.Healing then
            local healEvent = Liquidation.Services.ReplicatedStorage.Remotes.Healing:FindFirstChild("HealEvent")
            if healEvent then
                healEvent:FireServer(false, false)
            end
        end
    end)
end

local function StartSilentHeal()
    if healingStates.silentHealRunning then return end
    
    healingStates.silentHealRunning = true
    Liquidation.States.SilentHealRunning = true
    local currentValue = true
    
    Survivor.Connections.silentHeal = task.spawn(function()
        while healingStates.silentHealRunning do
            local character = Liquidation.getCharacter()
            if not character or not Liquidation.getRootPart() then
                task.wait(0.4)
                continue
            end
            
            local humanoid = Liquidation.getHumanoid()
            if not humanoid or humanoid.Health <= 0 then
                task.wait(0.4)
                continue
            end
            
            local currentTime = tick()
            if currentTime - healingStates.lastHealTime < healingStates.healCooldown then
                task.wait(healingStates.healCooldown)
                continue
            end
            
            local needsHealing = false
            local playersHealed = 0
            
            for _, targetPlayer in ipairs(Liquidation.Services.Players:GetPlayers()) do
                if targetPlayer == Liquidation.Player then continue end
                
                if targetPlayer and targetPlayer.Character then
                    local targetHumanoid = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
                    local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
                    
                    if targetHumanoid and targetRoot and targetHumanoid.Health < targetHumanoid.MaxHealth then
                        needsHealing = true
                        playersHealed = playersHealed + 1
                        
                        if playersHealed <= 3 then
                            local args = {targetRoot, currentValue}
                            pcall(function() 
                                if Liquidation.Services.ReplicatedStorage.Remotes and 
                                   Liquidation.Services.ReplicatedStorage.Remotes.Healing then
                                    Liquidation.Services.ReplicatedStorage.Remotes.Healing.HealEvent:FireServer(unpack(args))
                                    healingStates.lastHealTime = tick()
                                    
                                    local healAnimRemote = Liquidation.Services.ReplicatedStorage.Remotes.Healing:FindFirstChild("HealAnim")
                                    if healAnimRemote then
                                        healAnimRemote:FireServer(false)
                                    end
                                end
                            end)
                        end
                    else
                        local args = {targetRoot, false}
                        pcall(function() 
                            if Liquidation.Services.ReplicatedStorage.Remotes and 
                               Liquidation.Services.ReplicatedStorage.Remotes.Healing then
                                Liquidation.Services.ReplicatedStorage.Remotes.Healing.HealEvent:FireServer(unpack(args))
                            end
                        end)
                    end
                end
            end
            
            if not needsHealing then 
                pcall(SendStopHealEvent)
            else 
                currentValue = not currentValue 
            end
            
            task.wait(0.1)
        end
        
        pcall(SendStopHealEvent)
    end)
end

local function StopSilentHeal()
    if not healingStates.silentHealRunning then return end
    
    healingStates.silentHealRunning = false
    Liquidation.States.SilentHealRunning = false
    
    task.wait(0.1)
    
    if Survivor.Connections.silentHeal then
        Liquidation.safeDisconnect(Survivor.Connections.silentHeal)
        Survivor.Connections.silentHeal = nil
    end
    
    pcall(function()
        if Liquidation.Services.ReplicatedStorage.Remotes and Liquidation.Services.ReplicatedStorage.Remotes.Healing then
            local healAnimRemote = Liquidation.Services.ReplicatedStorage.Remotes.Healing:FindFirstChild("HealAnim")
            if healAnimRemote then
                healAnimRemote:FireServer(false)
                healAnimRemote:FireServer(false)
            end
        end
    end)
    
    for i = 1, 2 do
        pcall(SendStopHealEvent)
        task.wait(0.05)
    end
    
    pcall(function()
        local character = Liquidation.getCharacter()
        if character then
            local humanoid = Liquidation.getHumanoid()
            if humanoid then
                humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
            end
        end
    end)
end

-- NO FALL -- 

local NoFall = (function()
    local enabled = false
    local hooked = false
    local originalNamecall = nil
    local mt = nil
    local teamListeners = {}
    
    local function getFallRemote()
        local success, remote = pcall(function()
            return Liquidation.Services.ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Mechanics"):WaitForChild("Fall")
        end)
        return success and remote or nil
    end
    
    local function setupHook()
        if hooked then return end
        
        local fallRemote = getFallRemote()
        if not fallRemote then
            return false
        end
        
        mt = getrawmetatable(fallRemote)
        if not mt then
            return false
        end
        
        originalNamecall = mt.__namecall
        
        local wasReadonly = isreadonly and isreadonly(mt)
        if setreadonly then
            setreadonly(mt, false)
        end
        
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            
            if self == fallRemote and method == "FireServer" and enabled and isSurvivorTeam() then
                return nil 
            end
            
            return originalNamecall(self, ...)
        end)
        
        if setreadonly and wasReadonly then
            setreadonly(mt, true)
        end
        
        hooked = true
        return true
    end
    
    local function removeHook()
        if not hooked or not mt or not originalNamecall then return end
        
        local wasReadonly = isreadonly and isreadonly(mt)
        if setreadonly then
            setreadonly(mt, false)
        end
        
        mt.__namecall = originalNamecall
        
        if setreadonly and wasReadonly then
            setreadonly(mt, true)
        end
        
        hooked = false
        originalNamecall = nil
        mt = nil
    end
    
    local function updateNoFall()
        if enabled and isSurvivorTeam() then
            if not setupHook() then
                task.spawn(function()
                    for i = 1, 5 do
                        task.wait(1)
                        if enabled and isSurvivorTeam() and not hooked then
                            if setupHook() then break end
                        end
                    end
                end)
            end
        elseif enabled then
            removeHook()
        else
            removeHook()
        end
    end
    
    local function Enable()
        if enabled then return end
        enabled = true
        Liquidation.States.NoFallEnabled = true
        
        for _, listener in ipairs(teamListeners) do
            if type(listener) == "table" then
                for _, conn in ipairs(listener) do
                    Liquidation.safeDisconnect(conn)
                end
            else
                Liquidation.safeDisconnect(listener)
            end
        end
        
        teamListeners = {}
        
        table.insert(teamListeners, setupTeamListener(updateNoFall))
        
        updateNoFall()
    end
    
    local function Disable()
        if not enabled then return end
        enabled = false
        Liquidation.States.NoFallEnabled = false
        
        removeHook()
        
        for _, listener in ipairs(teamListeners) do
            if type(listener) == "table" then
                for _, conn in ipairs(listener) do
                    Liquidation.safeDisconnect(conn)
                end
            else
                Liquidation.safeDisconnect(listener)
            end
        end
        teamListeners = {}
    end
    
    return {
        Enable = Enable,
        Disable = Disable,
        IsEnabled = function() return enabled end
    }
end)()

-- GATE TOOL --

local GateTool = (function()
    local toolInstance = nil
    local toolConnection = nil
    local teamListeners = {}

    local function CreateTool()
        if not Liquidation.Player:FindFirstChild("Backpack") then return nil end
        
        local existing = Liquidation.Player.Backpack:FindFirstChild("Gate")
        if existing then 
            pcall(function() 
                if toolConnection then
                    toolConnection:Disconnect()
                    toolConnection = nil
                end
                existing:Destroy() 
            end) 
        end
        
        local tool = Instance.new("Tool")
        tool.Name = "Gate"
        tool.RequiresHandle = false
        tool.CanBeDropped = false
        tool.ToolTip = "Gate Tool - Use to interact with gates"
        tool.Parent = Liquidation.Player.Backpack
        
        tool.ManualActivationOnly = true
        
        return tool
    end

    local function UseGate()
        if not isSurvivorTeam() then return false end
        
        local success = pcall(function()
            local remotes = Liquidation.Services.ReplicatedStorage:FindFirstChild("Remotes")
            if remotes then
                local items = remotes:FindFirstChild("Items")
                if items then
                    local gate = items:FindFirstChild("Gate")
                    if gate then
                        local gateEvent = gate:FindFirstChild("gate")
                        if gateEvent and gateEvent:IsA("RemoteEvent") then
                            gateEvent:FireServer()
                            return true
                        end
                    end
                end
                
                for _, remote in ipairs(remotes:GetDescendants()) do
                    if remote:IsA("RemoteEvent") and (remote.Name:lower() == "gate" or remote.Name:find("gate")) then
                        remote:FireServer()
                        return true
                    end
                end
            end
        end)
        
        if not success then
        end
        
        return success
    end

    local function updateGateTool()
        if Liquidation.States.GateToolEnabled and isSurvivorTeam() then
            toolInstance = CreateTool()
            if toolInstance then 
                toolConnection = toolInstance.Activated:Connect(function()
                    UseGate()
                end)
            end
        elseif Liquidation.States.GateToolEnabled then            
            if toolInstance then 
                pcall(function() 
                    if toolConnection then
                        toolConnection:Disconnect()
                        toolConnection = nil
                    end
                    toolInstance:Destroy() 
                end) 
                toolInstance = nil
            end
        else
            if toolInstance then 
                pcall(function() 
                    if toolConnection then
                        toolConnection:Disconnect()
                        toolConnection = nil
                    end
                    toolInstance:Destroy() 
                end) 
                toolInstance = nil
            end
        end
    end

    local function Enable()
        if Liquidation.States.GateToolEnabled then return end
        Liquidation.States.GateToolEnabled = true
        
            for _, listener in ipairs(teamListeners) do
            if type(listener) == "table" then
                for _, conn in ipairs(listener) do
                    Liquidation.safeDisconnect(conn)
                end
            else
                Liquidation.safeDisconnect(listener)
            end
        end
        
        teamListeners = {}
        
        table.insert(teamListeners, setupTeamListener(updateGateTool))
        
        updateGateTool()
        
        local charAddedConn = Liquidation.Player.CharacterAdded:Connect(function() 
            if Liquidation.States.GateToolEnabled then 
                task.wait(2)
                updateGateTool()
            end 
        end)
        
        table.insert(teamListeners, charAddedConn)
    end

    local function Disable()
        Liquidation.States.GateToolEnabled = false
        
        if toolConnection then
            Liquidation.safeDisconnect(toolConnection)
            toolConnection = nil
        end
        if toolInstance then 
            pcall(function() 
                toolInstance:Destroy() 
            end) 
            toolInstance = nil
        end
        
        local backpack = Liquidation.Player:FindFirstChild("Backpack")
        if backpack then
            local tool = backpack:FindFirstChild("Gate")
            if tool then 
                pcall(function() tool:Destroy() end) 
            end
        end
        
        for _, listener in ipairs(teamListeners) do
            if type(listener) == "table" then
                for _, conn in ipairs(listener) do
                    Liquidation.safeDisconnect(conn)
                end
            else
                Liquidation.safeDisconnect(listener)
            end
        end
        teamListeners = {}
    end

    return {Enable=Enable, Disable=Disable}
end)()

-- ========== AUTO PERFECT SKILL ==========

local AutoPerfectSkill = (function()
    local connection = nil
    local teamListeners = {}

    local function FindSkillCheckGUI()
        local PlayerGui = Liquidation.Player:WaitForChild("PlayerGui")
        local skillCheckGui = PlayerGui:FindFirstChild("SkillCheckPromptGui")
        if skillCheckGui then
            local checkPart = skillCheckGui:FindFirstChild("Check")
            if checkPart then
                local goalPart = checkPart:WaitForChild("Goal")
                local linePart = checkPart:WaitForChild("Line")
                return skillCheckGui, checkPart, goalPart, linePart
            end
        end
        return nil
    end

    local function DisableGeneratorFail()
        local char = Liquidation.getCharacter()
        if char then
            local skillCheckGen = char:FindFirstChild("Skillcheck-gen")
            if skillCheckGen then skillCheckGen.Enabled = false end
        end
    end

    local function PerformPerfectSkillCheck()
        if not Liquidation.States.autoSkillEnabled or not isSurvivorTeam() then return end
        local skillCheckGui, checkPart, goalPart, linePart = FindSkillCheckGUI()
        if not skillCheckGui or not checkPart or not checkPart.Visible then return end
        
        local lineRot, goalRot = linePart.Rotation, goalPart.Rotation
        local minRot, maxRot = (104 + goalRot) % 360, (114 + goalRot) % 360
        if (minRot > maxRot and (lineRot >= minRot or lineRot <= maxRot)) or (lineRot >= minRot and lineRot <= maxRot) then
            Liquidation.Services.VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
            task.wait(0.01)
            Liquidation.Services.VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
            return true
        end
        return false
    end

    local function updateAutoSkill()
        if connection then
            connection:Disconnect()
            connection = nil
        end
        
        if Liquidation.States.autoSkillEnabled and isSurvivorTeam() then
            connection = Liquidation.Services.RunService.Heartbeat:Connect(PerformPerfectSkillCheck)
            DisableGeneratorFail()
        end
    end

    local function Enable()
        if Liquidation.States.autoSkillEnabled then return end
        Liquidation.States.autoSkillEnabled = true
        
        for _, listener in ipairs(teamListeners) do
            if type(listener) == "table" then
                for _, conn in ipairs(listener) do
                    Liquidation.safeDisconnect(conn)
                end
            else
                Liquidation.safeDisconnect(listener)
            end
        end
        
        teamListeners = {}
        
        table.insert(teamListeners, setupTeamListener(updateAutoSkill))
        
        updateAutoSkill()
    end

    local function Disable()
        Liquidation.States.autoSkillEnabled = false
        
        if connection then
            connection:Disconnect()
            connection = nil
        end
        
        for _, listener in ipairs(teamListeners) do
            if type(listener) == "table" then
                for _, conn in ipairs(listener) do
                    Liquidation.safeDisconnect(conn)
                end
            else
                Liquidation.safeDisconnect(listener)
            end
        end
        teamListeners = {}
    end

    return {Enable = Enable, Disable = Disable}
end)()

-- GAMEMODE (HEAL) --

local Gamemode = (function()
    local connection = nil
    local teamListeners = {}

    local function updateGamemode()
        if connection then
            connection:Disconnect()
            connection = nil
        end
        
        if Liquidation.States.autoHealEnabled and isSurvivorTeam() then
            connection = Liquidation.Services.RunService.Heartbeat:Connect(function()
                if not Liquidation.States.autoHealEnabled or not isSurvivorTeam() or not Liquidation.Player.Character then 
                    return 
                end
                local hum = Liquidation.Player.Character:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health < hum.MaxHealth then hum.Health = hum.MaxHealth end
            end)
            elseif Liquidation.States.autoHealEnabled then
        end
    end

    local function Enable()
        if Liquidation.States.autoHealEnabled then return end
        Liquidation.States.autoHealEnabled = true
        
        for _, listener in ipairs(teamListeners) do
            if type(listener) == "table" then
                for _, conn in ipairs(listener) do
                    Liquidation.safeDisconnect(conn)
                end
            else
                Liquidation.safeDisconnect(listener)
            end
        end
        
        teamListeners = {}
        
        table.insert(teamListeners, setupTeamListener(updateGamemode))
        
        updateGamemode()
    end

    local function Disable()
        Liquidation.States.autoHealEnabled = false
        
        if connection then
            connection:Disconnect()
            connection = nil
        end
        
        for _, listener in ipairs(teamListeners) do
            if type(listener) == "table" then
                for _, conn in ipairs(listener) do
                    Liquidation.safeDisconnect(conn)
                end
            else
                Liquidation.safeDisconnect(listener)
            end
        end
        teamListeners = {}
    end

    return {Enable = Enable, Disable = Disable}
end)()

-- NO HITBOX --

local NoHitbox = (function()
    local teamListeners = {}

    local function updateNoHitbox(value)
        if not isSurvivorTeam() then 
            return 
        end
        
        local char = Liquidation.getCharacter()
        if not char then return end
        
        for _, part in ipairs(char:GetDescendants()) do 
            if part:IsA("BasePart") then 
                part.CanTouch = not value 
            end 
        end
        
        if value then
            Liquidation.Player.CharacterAdded:Connect(function(newChar)
                task.wait(1)
                if isSurvivorTeam() then
                    for _, part in ipairs(newChar:GetDescendants()) do 
                        if part:IsA("BasePart") then 
                            part.CanTouch = false 
                        end 
                    end
                end
            end)
        end
    end

    local function Enable()
        for _, listener in ipairs(teamListeners) do
            if type(listener) == "table" then
                for _, conn in ipairs(listener) do
                    Liquidation.safeDisconnect(conn)
                end
            else
                Liquidation.safeDisconnect(listener)
            end
        end
        
        teamListeners = {}
        
        table.insert(teamListeners, setupTeamListener(function()
            if Liquidation.States.NoHitboxEnabled then
                updateNoHitbox(true)
            end
        end))
        
        if isSurvivorTeam() and Liquidation.States.NoHitboxEnabled then
            updateNoHitbox(true)
        elseif Liquidation.States.NoHitboxEnabled then
        end
    end

    local function Disable()
        if isSurvivorTeam() then
            updateNoHitbox(false)
        end
        
            for _, listener in ipairs(teamListeners) do
            if type(listener) == "table" then
                for _, conn in ipairs(listener) do
                    Liquidation.safeDisconnect(conn)
                end
            else
                Liquidation.safeDisconnect(listener)
            end
        end
        teamListeners = {}
    end

    return {Enable = Enable, Disable = Disable}
end)()

-- SPEED VAULT --

local SpeedVault = (function()
    local enabled = false
    local currentValue = 1.0
    local connection = nil
    local teamListeners = {}

    local function applyAttribute()
        if not enabled or not isSurvivorTeam() then return end
        local char = Liquidation.getCharacter()
        if not char then return end
        pcall(function() char:SetAttribute("vaultspeed", currentValue) end)
    end

    local function updateState()
        if connection then connection:Disconnect(); connection = nil end
        if enabled and isSurvivorTeam() then
            connection = Liquidation.Services.RunService.Heartbeat:Connect(applyAttribute)
        else
            local char = Liquidation.getCharacter()
            if char then pcall(function() char:SetAttribute("vaultspeed", nil) end) end
        end
    end

    local function Enable()
        if enabled then return end
        enabled = true
        Liquidation.States.SpeedVaultEnabled = true
        for _, listener in ipairs(teamListeners) do
            if type(listener) == "table" then
                for _, conn in ipairs(listener) do Liquidation.safeDisconnect(conn) end
            else Liquidation.safeDisconnect(listener) end
        end
        teamListeners = {}
        table.insert(teamListeners, setupTeamListener(updateState))
        updateState()
    end

    local function Disable()
        if not enabled then return end
        enabled = false
        Liquidation.States.SpeedVaultEnabled = false
        if connection then connection:Disconnect(); connection = nil end
        local char = Liquidation.getCharacter()
        if char then pcall(function() char:SetAttribute("vaultspeed", nil) end) end
        for _, listener in ipairs(teamListeners) do
            if type(listener) == "table" then
                for _, conn in ipairs(listener) do Liquidation.safeDisconnect(conn) end
            else Liquidation.safeDisconnect(listener) end
        end
        teamListeners = {}
    end

    return {
        Enable = Enable,
        Disable = Disable,
        IsEnabled = function() return enabled end,
        SetValue = function(v) currentValue = v; if enabled then applyAttribute() end end
    }
end)()

-- SPEED HACK [ATTRIBUTE] --

local SpeedHackAttr = (function()
    local enabled = false
    local currentValue = 1.0
    local connection = nil
    local teamListeners = {}

    local function applyAttribute()
        if not enabled or not isSurvivorTeam() then return end
        local char = Liquidation.getCharacter()
        if not char then return end
        pcall(function() char:SetAttribute("speedboost", currentValue) end)
    end

    local function updateState()
        if connection then connection:Disconnect(); connection = nil end
        if enabled and isSurvivorTeam() then
            connection = Liquidation.Services.RunService.Heartbeat:Connect(applyAttribute)
        else
            local char = Liquidation.getCharacter()
            if char then pcall(function() char:SetAttribute("speedboost", nil) end) end
        end
    end

    local function Enable()
        if enabled then return end
        enabled = true
        Liquidation.States.SpeedHackAttrEnabled = true
        for _, listener in ipairs(teamListeners) do
            if type(listener) == "table" then
                for _, conn in ipairs(listener) do Liquidation.safeDisconnect(conn) end
            else Liquidation.safeDisconnect(listener) end
        end
        teamListeners = {}
        table.insert(teamListeners, setupTeamListener(updateState))
        updateState()
    end

    local function Disable()
        if not enabled then return end
        enabled = false
        Liquidation.States.SpeedHackAttrEnabled = false
        if connection then connection:Disconnect(); connection = nil end
        local char = Liquidation.getCharacter()
        if char then pcall(function() char:SetAttribute("speedboost", nil) end) end
        for _, listener in ipairs(teamListeners) do
            if type(listener) == "table" then
                for _, conn in ipairs(listener) do Liquidation.safeDisconnect(conn) end
            else Liquidation.safeDisconnect(listener) end
        end
        teamListeners = {}
    end

    return {
        Enable = Enable,
        Disable = Disable,
        IsEnabled = function() return enabled end,
        SetValue = function(v) currentValue = v; if enabled then applyAttribute() end end
    }
end)()

-- VAULT DISTANCE --

local VaultDistance = (function()
    local enabled = false
    local currentValue = 5
    local connection = nil
    local teamListeners = {}

    local function applyAttribute()
        if not enabled or not isSurvivorTeam() then return end
        local char = Liquidation.getCharacter()
        if not char then return end
        pcall(function() char:SetAttribute("__VaultFireCount", currentValue) end)
    end

    local function updateState()
        if connection then connection:Disconnect(); connection = nil end
        if enabled and isSurvivorTeam() then
            connection = Liquidation.Services.RunService.Heartbeat:Connect(applyAttribute)
        else
            local char = Liquidation.getCharacter()
            if char then pcall(function() char:SetAttribute("__VaultFireCount", nil) end) end
        end
    end

    local function Enable()
        if enabled then return end
        enabled = true
        Liquidation.States.VaultDistanceEnabled = true
        for _, listener in ipairs(teamListeners) do
            if type(listener) == "table" then
                for _, conn in ipairs(listener) do Liquidation.safeDisconnect(conn) end
            else Liquidation.safeDisconnect(listener) end
        end
        teamListeners = {}
        table.insert(teamListeners, setupTeamListener(updateState))
        updateState()
    end

    local function Disable()
        if not enabled then return end
        enabled = false
        Liquidation.States.VaultDistanceEnabled = false
        if connection then connection:Disconnect(); connection = nil end
        local char = Liquidation.getCharacter()
        if char then pcall(function() char:SetAttribute("__VaultFireCount", nil) end) end
        for _, listener in ipairs(teamListeners) do
            if type(listener) == "table" then
                for _, conn in ipairs(listener) do Liquidation.safeDisconnect(conn) end
            else Liquidation.safeDisconnect(listener) end
        end
        teamListeners = {}
    end

    return {
        Enable = Enable,
        Disable = Disable,
        IsEnabled = function() return enabled end,
        SetValue = function(v) currentValue = v; if enabled then applyAttribute() end end
    }
end)()

-- HEAL BOOST --

local HealBoost = (function()
    local enabled = false
    local currentValue = 1.0
    local connection = nil
    local teamListeners = {}

    local function applyAttribute()
        if not enabled or not isSurvivorTeam() then return end
        local char = Liquidation.getCharacter()
        if not char then return end
        pcall(function() char:SetAttribute("healboost", currentValue) end)
    end

    local function updateState()
        if connection then connection:Disconnect(); connection = nil end
        if enabled and isSurvivorTeam() then
            connection = Liquidation.Services.RunService.Heartbeat:Connect(applyAttribute)
        else
            local char = Liquidation.getCharacter()
            if char then pcall(function() char:SetAttribute("healboost", nil) end) end
        end
    end

    local function Enable()
        if enabled then return end
        enabled = true
        Liquidation.States.HealBoostEnabled = true
        for _, listener in ipairs(teamListeners) do
            if type(listener) == "table" then
                for _, conn in ipairs(listener) do Liquidation.safeDisconnect(conn) end
            else Liquidation.safeDisconnect(listener) end
        end
        teamListeners = {}
        table.insert(teamListeners, setupTeamListener(updateState))
        updateState()
    end

    local function Disable()
        if not enabled then return end
        enabled = false
        Liquidation.States.HealBoostEnabled = false
        if connection then connection:Disconnect(); connection = nil end
        local char = Liquidation.getCharacter()
        if char then pcall(function() char:SetAttribute("healboost", nil) end) end
        for _, listener in ipairs(teamListeners) do
            if type(listener) == "table" then
                for _, conn in ipairs(listener) do Liquidation.safeDisconnect(conn) end
            else Liquidation.safeDisconnect(listener) end
        end
        teamListeners = {}
    end

    return {
        Enable = Enable,
        Disable = Disable,
        IsEnabled = function() return enabled end,
        SetValue = function(v) currentValue = v; if enabled then applyAttribute() end end
    }
end)()

-- REPAIR BOOST --

local RepairBoost = (function()
    local enabled = false
    local currentValue = 0
    local connection = nil
    local teamListeners = {}

    local function applyAttribute()
        if not enabled or not isSurvivorTeam() then return end
        local char = Liquidation.getCharacter()
        if not char then return end
        pcall(function() char:SetAttribute("repairboost", currentValue) end)
    end

    local function updateState()
        if connection then connection:Disconnect(); connection = nil end
        if enabled and isSurvivorTeam() then
            connection = Liquidation.Services.RunService.Heartbeat:Connect(applyAttribute)
        else
            local char = Liquidation.getCharacter()
            if char then pcall(function() char:SetAttribute("repairboost", nil) end) end
        end
    end

    local function Enable()
        if enabled then return end
        enabled = true
        Liquidation.States.RepairBoostEnabled = true
        for _, listener in ipairs(teamListeners) do
            if type(listener) == "table" then
                for _, conn in ipairs(listener) do Liquidation.safeDisconnect(conn) end
            else Liquidation.safeDisconnect(listener) end
        end
        teamListeners = {}
        table.insert(teamListeners, setupTeamListener(updateState))
        updateState()
    end

    local function Disable()
        if not enabled then return end
        enabled = false
        Liquidation.States.RepairBoostEnabled = false
        if connection then connection:Disconnect(); connection = nil end
        local char = Liquidation.getCharacter()
        if char then pcall(function() char:SetAttribute("repairboost", nil) end) end
        for _, listener in ipairs(teamListeners) do
            if type(listener) == "table" then
                for _, conn in ipairs(listener) do Liquidation.safeDisconnect(conn) end
            else Liquidation.safeDisconnect(listener) end
        end
        teamListeners = {}
    end

    return {
        Enable = Enable,
        Disable = Disable,
        IsEnabled = function() return enabled end,
        SetValue = function(v) currentValue = v; if enabled then applyAttribute() end end
    }
end)()

-- BLEED BOOST --

local BleedBoost = (function()
    local enabled = false
    local currentValue = 0.0
    local connection = nil
    local teamListeners = {}

    local function applyAttribute()
        if not enabled or not isSurvivorTeam() then return end
        local char = Liquidation.getCharacter()
        if not char then return end
        pcall(function() char:SetAttribute("bleedboost", currentValue) end)
    end

    local function updateState()
        if connection then connection:Disconnect(); connection = nil end
        if enabled and isSurvivorTeam() then
            connection = Liquidation.Services.RunService.Heartbeat:Connect(applyAttribute)
        else
            local char = Liquidation.getCharacter()
            if char then pcall(function() char:SetAttribute("bleedboost", nil) end) end
        end
    end

    local function Enable()
        if enabled then return end
        enabled = true
        Liquidation.States.BleedBoostEnabled = true
        for _, listener in ipairs(teamListeners) do
            if type(listener) == "table" then
                for _, conn in ipairs(listener) do Liquidation.safeDisconnect(conn) end
            else Liquidation.safeDisconnect(listener) end
        end
        teamListeners = {}
        table.insert(teamListeners, setupTeamListener(updateState))
        updateState()
    end

    local function Disable()
        if not enabled then return end
        enabled = false
        Liquidation.States.BleedBoostEnabled = false
        if connection then connection:Disconnect(); connection = nil end
        local char = Liquidation.getCharacter()
        if char then pcall(function() char:SetAttribute("bleedboost", nil) end) end
        for _, listener in ipairs(teamListeners) do
            if type(listener) == "table" then
                for _, conn in ipairs(listener) do Liquidation.safeDisconnect(conn) end
            else Liquidation.safeDisconnect(listener) end
        end
        teamListeners = {}
    end

    return {
        Enable = Enable,
        Disable = Disable,
        IsEnabled = function() return enabled end,
        SetValue = function(v) currentValue = v; if enabled then applyAttribute() end end
    }
end)()

-- VISUAL PARRY DISTANCE --

local ParryCircleVisual = (function()
    local enabled = false
    local circleObj = nil
    local connection = nil
    local teamListeners = {}
    local billboardGui = nil
    local textLabel = nil

    local function destroyCircle()
        if circleObj then
            pcall(function() circleObj:Destroy() end)
            circleObj = nil
        end
        billboardGui = nil
        textLabel = nil
    end

    local function getDistanceToNearestKiller()
        local character = Liquidation.getCharacter()
        if not character then return math.huge end
        
        local root = character:FindFirstChild("HumanoidRootPart")
        if not root then return math.huge end
        
        local myPos = root.Position
        local closestDist = math.huge
        
        for _, player in ipairs(Liquidation.Services.Players:GetPlayers()) do
            if player ~= Liquidation.Player and player.Character then
                local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")
                local targetHum = player.Character:FindFirstChildOfClass("Humanoid")
                
                if targetRoot and targetHum and targetHum.Health > 0 then
                    -- Проверяем, что игрок в команде Killer
                    local isKiller = false
                    if player.Team then
                        local teamName = player.Team.Name:lower()
                        isKiller = teamName:find("killer") ~= nil
                    end
                    
                    if isKiller then
                        local dist = (targetRoot.Position - myPos).Magnitude
                        if dist < closestDist then
                            closestDist = dist
                        end
                    end
                end
            end
        end
        
        return closestDist
    end

    local function createCircle()
        destroyCircle()
        
        -- Создаём цилиндр
        local dome = Instance.new("Part")
        dome.Name = "NexusParryCircle"
        dome.Anchored = true
        dome.CanCollide = false
        dome.CastShadow = false
        dome.Material = Enum.Material.Neon
        dome.Color = Color3.fromRGB(0, 255, 80)  -- зелёный
        dome.Transparency = 0.58  -- полупрозрачный
        dome.Shape = Enum.PartType.Cylinder  -- форма цилиндра
        dome.Parent = workspace
        
        -- Создаём BillboardGui для текста
        local bb = Instance.new("BillboardGui")
        bb.Size = UDim2.new(0, 200, 0, 32)
        bb.StudsOffset = Vector3.new(0, 4, 0)
        bb.AlwaysOnTop = true
        bb.Parent = dome
        
        local lbl = Instance.new("TextLabel", bb)
        lbl.Size = UDim2.new(1, 0, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.TextColor3 = Color3.fromRGB(0, 255, 80)
        lbl.TextStrokeTransparency = 0
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 14
        lbl.Text = "Parry Distance"
        
        circleObj = dome
        billboardGui = bb
        textLabel = lbl
        
        return dome
    end

    local function updateVisual()
        if not enabled or not isSurvivorTeam() then
            destroyCircle()
            return
        end
        
        local character = Liquidation.getCharacter()
        if not character then return end
        
        local root = character:FindFirstChild("HumanoidRootPart")
        if not root then return end
        
        -- Создаём круг, если его нет
        if not circleObj or not circleObj.Parent then
            circleObj = createCircle()
        end
        
        if not circleObj or not circleObj.Parent then return end
        
        -- Получаем радиус из AutoParry
        local maxDist = 10  -- стандартный радиус
        if AutoParry and AutoParry.GetRange then
            maxDist = AutoParry.GetRange()
        end
        
        -- Получаем дистанцию до ближайшего киллера
        local killerDist = getDistanceToNearestKiller()
        
        -- Размер цилиндра (диаметр = радиус * 2)
        local diam = maxDist * 2
        
        -- Позиционируем под ногами игрока (на 3 юнита ниже)
        local floorY = root.Position.Y - 2.9
        circleObj.CFrame = CFrame.new(root.Position.X, floorY, root.Position.Z) * CFrame.Angles(0, 0, math.pi / 2)
        circleObj.Size = Vector3.new(0.2, diam, diam)
        
        -- Меняем цвет в зависимости от дистанции до киллера
        if killerDist <= maxDist then
            circleObj.Color = Color3.fromRGB(255, 50, 50)  -- красный если киллер в радиусе
        else
            circleObj.Color = Color3.fromRGB(0, 255, 80)  -- зелёный если киллер далеко
        end
        
        -- Обновляем текст
        if textLabel then
            local distStr = (killerDist == math.huge) and "---" or string.format("%.1f", killerDist)
            textLabel.Text = string.format("r: %.1f  |  killer: %s", maxDist, distStr)
            
            if killerDist <= maxDist then
                textLabel.TextColor3 = Color3.fromRGB(255, 80, 80)  -- красный текст
            else
                textLabel.TextColor3 = Color3.fromRGB(0, 255, 80)  -- зелёный текст
            end
        end
    end

    local function startLoop()
        if connection then connection:Disconnect(); connection = nil end
        if enabled and isSurvivorTeam() then
            connection = Liquidation.Services.RunService.Heartbeat:Connect(updateVisual)
        end
    end

    local function Enable()
        if enabled then return end
        enabled = true
        Liquidation.States.ParryCircleEnabled = true
        
        for _, listener in ipairs(teamListeners) do
            if type(listener) == "table" then
                for _, conn in ipairs(listener) do Liquidation.safeDisconnect(conn) end
            else Liquidation.safeDisconnect(listener) end
        end
        teamListeners = {}
        
        table.insert(teamListeners, setupTeamListener(function()
            if connection then connection:Disconnect(); connection = nil end
            destroyCircle()
            startLoop()
        end))
        
        startLoop()
    end

    local function Disable()
        if not enabled then return end
        enabled = false
        Liquidation.States.ParryCircleEnabled = false
        
        if connection then connection:Disconnect(); connection = nil end
        destroyCircle()
        
        for _, listener in ipairs(teamListeners) do
            if type(listener) == "table" then
                for _, conn in ipairs(listener) do Liquidation.safeDisconnect(conn) end
            else Liquidation.safeDisconnect(listener) end
        end
        teamListeners = {}
    end

    return {
        Enable = Enable,
        Disable = Disable,
        IsEnabled = function() return enabled end
    }
end)()

local function ResetAllHealing()
    healingStates.silentHealRunning = false
    healingStates.instantHealRunning = false
    Liquidation.States.SilentHealRunning = false
    Liquidation.States.InstantHealRunning = false
    Liquidation.States.autoHealEnabled = false
    
    if Survivor.Connections.silentHeal then
        Liquidation.safeDisconnect(Survivor.Connections.silentHeal)
        Survivor.Connections.silentHeal = nil
    end
    if Survivor.Connections.instantHeal then
        Liquidation.safeDisconnect(Survivor.Connections.instantHeal)
        Survivor.Connections.instantHeal = nil
    end
end


function Survivor.Init(nxs)
    Liquidation = nxs
    
    local Tabs = Liquidation.Tabs
    local Options = Liquidation.Options
    
    Tabs.Main:AddParagraph({
        Title = "Hello, " .. Liquidation.Player.Name .. "!",
        Content = "Enjoy using the script"
    })

    local CrosshairToggle = Tabs.Main:AddToggle("Crosshair", {
        Title = "Crosshair Flashlight & Gun", 
        Description = "", 
        Default = false
    })

    CrosshairToggle:OnChanged(function(v) 
        Liquidation.SafeCallback(function()
            if v then 
                Crosshair.Enable() 
            else 
                Crosshair.Disable() 
            end 
        end)
    end)

    local CrosshairTypeDropdown = Tabs.Main:AddDropdown("CrosshairType", {
        Title = "Crosshair Type",
        Description = "Select crosshair type",
        Values = {"crosshair", "dot", "circle"},
        Default = "crosshair",
        Callback = function(value)
            Liquidation.SafeCallback(function()
                Crosshair.SetType(value)
            end)
        end
    })

    local RainbowCrosshairToggle = Tabs.Main:AddToggle("RainbowCrosshair", {
        Title = "Rainbow Crosshair", 
        Description = "Enable rainbow color effect on crosshair", 
        Default = false
    })

    RainbowCrosshairToggle:OnChanged(function(v) 
        Liquidation.SafeCallback(function()
            Crosshair.ToggleRainbow(v)
        end)
    end)

    local AutoVictoryToggle = Tabs.Main:AddToggle("AutoVictory", {
        Title = "Auto Victory (Survivor)", 
        Description = "Automatically teleports to exit for victory", 
        Default = false
    })

    AutoVictoryToggle:OnChanged(function(v) 
        Liquidation.SafeCallback(function()
            if v then 
                AutoVictory.Enable() 
            else 
                AutoVictory.Disable() 
            end 
        end)
    end)

    local AutoVictoryV2Toggle = Tabs.Main:AddToggle("AutoVictoryV2", {
        Title = "Auto Victory V2", 
        Description = "You can win even if you are hung on a Hook", 
        Default = false
    })

    AutoVictoryV2Toggle:OnChanged(function(v) 
        Liquidation.SafeCallback(function()
            if v then 
                AutoVictoryV2.Enable() 
            else 
                AutoVictoryV2.Disable() 
            end 
        end)
    end)

    local NoSlowdownToggle = Tabs.Main:AddToggle("NoSlowdown", {
        Title = "No Slowdown&NoStun + FastDropPallet", 
        Description = "Prevents all slowdown effects", 
        Default = false
    })

    NoSlowdownToggle:OnChanged(function(v) 
        Liquidation.SafeCallback(function()
            if v then 
                NoSlowdown.Enable() 
            else 
                NoSlowdown.Disable() 
            end 
        end)
    end)

    local AutoParryToggle = Tabs.Main:AddToggle("AutoParry", {
        Title = "AutoParry", 
        Description = "automatic parry of attacks", 
        Default = false
    })

    AutoParryToggle:OnChanged(function(v) 
        Liquidation.SafeCallback(function()
            if v then 
                AutoParry.Enable() 
            else 
                AutoParry.Disable() 
            end 
        end)
    end)

    local AutoParryRangeSlider = Tabs.Main:AddSlider("AutoParryRange", {
        Title = "parry distance",
        Description = "",
        Default = 10,
        Min = 0,
        Max = 20,
        Rounding = 2,
        Callback = function(value)
            Liquidation.SafeCallback(function()
                AutoParry.SetRange(value)
            end)
        end
    })

    local AutoParryV2Toggle = Tabs.Main:AddToggle("AutoParryV2", {
        Title = "AutoParry V2", 
        Description = "Arm detection based parry", 
        Default = false
    })

    AutoParryV2Toggle:OnChanged(function(v) 
        Liquidation.SafeCallback(function()
            if v then 
                AutoParryV2.Enable() 
            else 
                AutoParryV2.Disable() 
            end 
        end)
    end)

    local AutoParryV2RangeSlider = Tabs.Main:AddSlider("AutoParryV2Range", {
        Title = "AutoParry V2 Distance",
        Description = "",
        Default = 20,
        Min = 0,
        Max = 30,
        Rounding = 1,
        Callback = function(value)
            Liquidation.SafeCallback(function()
                AutoParryV2.SetRadius(value)
            end)
        end
    })

    local ParryCircleToggle = Tabs.Main:AddToggle("ParryCircleVisual", {
        Title = "Visual Parry Distance",
        Description = "Shows parry range circle: green = safe, red = killer in range",
        Default = false
    })
    ParryCircleToggle:OnChanged(function(v)
        Liquidation.SafeCallback(function()
            if v then ParryCircleVisual.Enable() else ParryCircleVisual.Disable() end
        end)
    end)

local FastVaultToggle = Tabs.Main:AddToggle("FastVault", {
        Title = "Fast Vault", 
        Description = "Instant vault through windows and pallets", 
        Default = false
    })

    FastVaultToggle:OnChanged(function(v) 
        Liquidation.SafeCallback(function()
            if v then 
                FastVault.Enable() 
            else 
                FastVault.Disable() 
            end 
        end)
    end)

    local TwistSilentAimToggle = Tabs.Main:AddToggle("TwistSilentAim", {
        Title = "Twist of Fate Silent Aim", 
        Description = "Auto silent aim", 
        Default = false
    })

    TwistSilentAimToggle:OnChanged(function(v) 
        Liquidation.SafeCallback(function()
            if v then 
                TwistSilentAim.Enable() 
            else 
                TwistSilentAim.Disable() 
            end 
        end)
    end)

    local FakeParryToggle = Tabs.Main:AddToggle("FakeParry", {
        Title = "Fake Parry", 
        Description = "Plays parry animation continuously", 
        Default = false
    })

    FakeParryToggle:OnChanged(function(v) 
        Liquidation.SafeCallback(function()
            if v then 
                FakeParry.Enable() 
            else 
                FakeParry.Disable() 
            end 
        end)
    end)

    local NoFallToggle = Tabs.Main:AddToggle("NoFall", {
        Title = "No Fall [temporarily no work]", 
        Description = "Disables the penalty when falling", 
        Default = false
    })

    NoFallToggle:OnChanged(function(v)
        Liquidation.SafeCallback(function()
            if v then 
                NoFall.Enable() 
            else 
                NoFall.Disable() 
            end
        end)
    end)

    local HealToggle = Tabs.Main:AddToggle("Heal", {
        Title = "GodMode", 
        Description = "Automatic health regeneration", 
        Default = false
    })

    HealToggle:OnChanged(function(v)
        Liquidation.SafeCallback(function()
            if v then 
                Gamemode.Enable()
            else 
                Gamemode.Disable()
            end
        end)
    end)

    local InstantHealToggle = Tabs.Main:AddToggle("InstantHeal", {
        Title = "Instant Heal", 
        Description = "instant treatment", 
        Default = false
    })

    InstantHealToggle:OnChanged(function(v) 
        Liquidation.SafeCallback(function()
            if v then 
                StartInstantHeal() 
            else 
                StopInstantHeal() 
            end 
        end)
    end)

    local SilentHealToggle = Tabs.Main:AddToggle("SilentHeal", {
        Title = "Silent Heal", 
        Description = "Heals all players anywhere on the map", 
        Default = false
    })

    SilentHealToggle:OnChanged(function(v) 
        Liquidation.SafeCallback(function()
            if v then 
                StartSilentHeal() 
            else 
                StopSilentHeal() 
            end 
        end)
    end)

    local GateToolToggle = Tabs.Main:AddToggle("GateTool", {
        Title = "Fast use [Gate Tool]", 
        Description = "Quick usage of the Gate Tool", 
        Default = false
    })

    GateToolToggle:OnChanged(function(v) 
        Liquidation.SafeCallback(function()
            if v then 
                GateTool.Enable() 
            else 
                GateTool.Disable() 
            end 
        end)
    end)

    local NoHitboxToggle = Tabs.Main:AddToggle("NoHitbox", {
        Title = "No Hitbox", 
        Description = "Disables collision with other players", 
        Default = false
    })

    NoHitboxToggle:OnChanged(function(v)
        Liquidation.SafeCallback(function()
            Liquidation.States.NoHitboxEnabled = v
            if v then 
                NoHitbox.Enable() 
            else 
                NoHitbox.Disable() 
            end
        end)
    end)

    Tabs.Main:AddSection("Generators")
    
    local AutoSkillToggle = Tabs.Main:AddToggle("AutoPerfectSkill", {
        Title = "Auto Perfect Skill Check", 
        Description = "automatically clicks in the perfect location", 
        Default = false
    })

    AutoSkillToggle:OnChanged(function(v)
        Liquidation.SafeCallback(function()
            if v then 
                AutoPerfectSkill.Enable()
            else 
                AutoPerfectSkill.Disable()
            end
        end)
    end)

    Tabs.Main:AddSection("Attributes")

    local SpeedVaultToggle = Tabs.Main:AddToggle("SpeedVault", {
        Title = "Speed Vault",
        Description = "Increases vault speed via vaultspeed attribute",
        Default = false
    })
    SpeedVaultToggle:OnChanged(function(v)
        Liquidation.SafeCallback(function()
            if v then SpeedVault.Enable() else SpeedVault.Disable() end
        end)
    end)
    Tabs.Main:AddSlider("SpeedVaultValue", {
        Title = "Vault Speed Value",
        Description = "Set vaultspeed attribute (1 - 50)",
        Default = 1,
        Min = 1,
        Max = 50,
        Rounding = 2,
        Callback = function(value)
            Liquidation.SafeCallback(function() SpeedVault.SetValue(value) end)
        end
    })

    local SpeedHackAttrToggle = Tabs.Main:AddToggle("SpeedHackAttr", {
        Title = "Speed Hack [Attribute]",
        Description = "Increases movement speed via speedboost attribute",
        Default = false
    })
    SpeedHackAttrToggle:OnChanged(function(v)
        Liquidation.SafeCallback(function()
            if v then SpeedHackAttr.Enable() else SpeedHackAttr.Disable() end
        end)
    end)
    Tabs.Main:AddSlider("SpeedHackAttrValue", {
        Title = "Speed Boost Value",
        Description = "Set speedboost attribute (1 - 100)",
        Default = 1,
        Min = 1,
        Max = 100,
        Rounding = 2,
        Callback = function(value)
            Liquidation.SafeCallback(function() SpeedHackAttr.SetValue(value) end)
        end
    })

    local VaultDistanceToggle = Tabs.Main:AddToggle("VaultDistance", {
        Title = "Vault Distance",
        Description = "Increases vault distance via __VaultFireCount attribute",
        Default = false
    })
    VaultDistanceToggle:OnChanged(function(v)
        Liquidation.SafeCallback(function()
            if v then VaultDistance.Enable() else VaultDistance.Disable() end
        end)
    end)
    Tabs.Main:AddSlider("VaultDistanceValue", {
        Title = "Vault Fire Count",
        Description = "Set __VaultFireCount attribute (5 - 30)",
        Default = 5,
        Min = 5,
        Max = 30,
        Rounding = 1,
        Callback = function(value)
            Liquidation.SafeCallback(function() VaultDistance.SetValue(value) end)
        end
    })

    local HealBoostToggle = Tabs.Main:AddToggle("HealBoost", {
        Title = "Heal Boost",
        Description = "Increases healing speed via healboost attribute",
        Default = false
    })
    HealBoostToggle:OnChanged(function(v)
        Liquidation.SafeCallback(function()
            if v then HealBoost.Enable() else HealBoost.Disable() end
        end)
    end)
    Tabs.Main:AddSlider("HealBoostValue", {
        Title = "Heal Boost Value",
        Description = "Set healboost attribute (1 - 100)",
        Default = 1,
        Min = 1,
        Max = 100,
        Rounding = 2,
        Callback = function(value)
            Liquidation.SafeCallback(function() HealBoost.SetValue(value) end)
        end
    })

    local RepairBoostToggle = Tabs.Main:AddToggle("RepairBoost", {
        Title = "Repair Boost",
        Description = "Increases repair speed via repairboost attribute",
        Default = false
    })
    RepairBoostToggle:OnChanged(function(v)
        Liquidation.SafeCallback(function()
            if v then RepairBoost.Enable() else RepairBoost.Disable() end
        end)
    end)
    Tabs.Main:AddSlider("RepairBoostValue", {
        Title = "Repair Boost Value",
        Description = "Set repairboost attribute (0 - 100)",
        Default = 0,
        Min = 0,
        Max = 100,
        Rounding = 2,
        Callback = function(value)
            Liquidation.SafeCallback(function() RepairBoost.SetValue(value) end)
        end
    })

    local BleedBoostToggle = Tabs.Main:AddToggle("BleedBoost", {
        Title = "Bleed Boost",
        Description = "Reduces bleed via bleedboost attribute (0 = min bleed)",
        Default = false
    })
    BleedBoostToggle:OnChanged(function(v)
        Liquidation.SafeCallback(function()
            if v then BleedBoost.Enable() else BleedBoost.Disable() end
        end)
    end)
    Tabs.Main:AddSlider("BleedBoostValue", {
        Title = "Bleed Boost Value",
        Description = "Set bleedboost attribute (0 = min, 1 = max)",
        Default = 0,
        Min = 0,
        Max = 1,
        Rounding = 2,
        Callback = function(value)
            Liquidation.SafeCallback(function() BleedBoost.SetValue(value) end)
        end
    })
    
end

function Survivor.Cleanup()

    Crosshair.Disable()
    AutoVictory.Disable()
    AutoVictoryV2.Disable()
    NoSlowdown.Disable()
    AutoParry.Disable()
    AutoParryV2.Disable()
    FakeParry.Disable()
    NoFall.Disable()  
    Gamemode.Disable()
    ResetAllHealing()
    GateTool.Disable()
    FastVault.Disable()
    TwistSilentAim.Disable()
    NoHitbox.Disable()
    AutoPerfectSkill.Disable()
    SpeedVault.Disable()
    SpeedHackAttr.Disable()
    VaultDistance.Disable()
    HealBoost.Disable()
    RepairBoost.Disable()
    BleedBoost.Disable()
    ParryCircleVisual.Disable()
    
    for key, connection in pairs(Survivor.Connections) do
        Liquidation.safeDisconnect(connection)
    end
    Survivor.Connections = {}
end

--// Exports //--
Survivor.Crosshair = Crosshair;
Survivor.AutoVictory = AutoVictory;
Survivor.AutoVictoryV2 = AutoVictoryV2;
Survivor.NoSlowdown = NoSlowdown;
Survivor.AutoParry = AutoParry;
Survivor.AutoParryV2 = AutoParryV2;
Survivor.FakeParry = FakeParry;
Survivor.NoFall = NoFall;
Survivor.Gamemode = Gamemode;
Survivor.GateTool = GateTool;
Survivor.FastVault = FastVault;
Survivor.TwistSilentAim = TwistSilentAim;
Survivor.NoHitbox = NoHitbox;
Survivor.AutoPerfectSkill = AutoPerfectSkill;
Survivor.SpeedVault = SpeedVault;
Survivor.SpeedHackAttr = SpeedHackAttr;
Survivor.VaultDistance = VaultDistance;
Survivor.HealBoost = HealBoost;
Survivor.RepairBoost = RepairBoost;
Survivor.BleedBoost = BleedBoost;
Survivor.ParryCircleVisual = ParryCircleVisual;
Survivor.StartInstantHeal = StartInstantHeal;
Survivor.StopInstantHeal = StopInstantHeal;
Survivor.StartSilentHeal = StartSilentHeal;
Survivor.StopSilentHeal = StopSilentHeal;

return Survivor
