local Liquidation = _G.Liquidation

local Killer = {
    Connections = {},
    States = {},
    Objects = {},
    HitboxCache = {}
}

local function isKillerTeam()
    local player = Liquidation.Player
    if not player then return false end
    
    local team = player.Team
    if not team then return false end
    
    local teamName = team.Name:lower()
    return teamName:find("killer") or teamName == "Killer" or teamName == "Killers"
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

-- FAKE SAW --

local UseFakeSaw = (function()
    local enabled = false
    local teamListeners = {}
    local connection = nil
    
    local function getMaskedAlexAttackRemote()
        local success, result = pcall(function()
            return Liquidation.Services.ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Killers"):WaitForChild("Masked"):WaitForChild("alexattack")
        end)
        return success and result or nil
    end
    
    local function executeFakeSaw()
        if not enabled then return end
        
        local Event = getMaskedAlexAttackRemote()
        if not Event then
            return
        end
        
        local success = pcall(function()
            Event:FireServer()
        end)
    end
    
    local function updateFakeSawState()
        if enabled and isKillerTeam() then
            if connection then
                connection:Disconnect()
            end
            
            connection = Liquidation.Services.RunService.Heartbeat:Connect(function()
                if enabled and isKillerTeam() then
                    executeFakeSaw()
                    task.wait(35)
                end
            end)
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
        end
    end
    
    local function Enable()
        if enabled then return end
        enabled = true
        Liquidation.States.UseFakeSawEnabled = true
        
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
        
        table.insert(teamListeners, setupTeamListener(updateFakeSawState))
        
        updateFakeSawState()
    end
    
    local function Disable()
        if not enabled then return end
        enabled = false
        Liquidation.States.UseFakeSawEnabled = false
        
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
    
    return {
        Enable = Enable,
        Disable = Disable,
        IsEnabled = function() return enabled end,
        ActivateOnce = function()
            if enabled and isKillerTeam() then
                executeFakeSaw()
            end
        end
    }
end)()

-- SPEAR CROSSHAIR - -

local SpearCrosshair = (function()
    local enabled = false
    local crosshairFrame, crosshairX, crosshairY
    local teamListeners = {}
    local attributeListener = nil
    local renderConnection = nil
    
    local function createCrosshair()
        if crosshairFrame then return end
        
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "SpearCrosshair"
        screenGui.ResetOnSpawn = false
        screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        screenGui.Parent = Liquidation.Player:WaitForChild("PlayerGui")

        crosshairFrame = Instance.new("Frame")
        crosshairFrame.Name = "CrosshairFrame"
        crosshairFrame.BackgroundTransparency = 1
        crosshairFrame.Size = UDim2.new(0, 40, 0, 40)
        crosshairFrame.Position = UDim2.new(0.5, -20, 0.5, -20)
        crosshairFrame.Visible = false
        crosshairFrame.Parent = screenGui
        
        crosshairX = Instance.new("Frame")
        crosshairX.Name = "CrosshairX"
        crosshairX.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        crosshairX.BorderSizePixel = 0
        crosshairX.Size = UDim2.new(1, 0, 0, 2)
        crosshairX.Position = UDim2.new(0, 0, 0.5, -1)
        crosshairX.Parent = crosshairFrame
        
        crosshairY = Instance.new("Frame")
        crosshairY.Name = "CrosshairY"
        crosshairY.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        crosshairY.BorderSizePixel = 0
        crosshairY.Size = UDim2.new(0, 2, 1, 0)
        crosshairY.Position = UDim2.new(0.5, -1, 0, 0)
        crosshairY.Parent = crosshairFrame
    end
    
    local function destroyCrosshair()
        if crosshairFrame and crosshairFrame.Parent then
            crosshairFrame.Parent:Destroy()
        end
        crosshairFrame = nil
        crosshairX = nil
        crosshairY = nil
    end
    
    local function updateCrosshairVisibility()
        if not crosshairFrame then return end
        
        local character = Liquidation.Player.Character
        local shouldShow = false
        
        if enabled and isKillerTeam() and character then
            local spearMode = character:GetAttribute("spearmode")
            shouldShow = spearMode == "spearing"
        end
        
        crosshairFrame.Visible = shouldShow
    end
    
    local function setupAttributeListener()
        if attributeListener then
            attributeListener:Disconnect()
            attributeListener = nil
        end
        
        if enabled and isKillerTeam() then
            local character = Liquidation.Player.Character
            if character then
                attributeListener = character:GetAttributeChangedSignal("spearmode"):Connect(function()
                    updateCrosshairVisibility()
                end)
                updateCrosshairVisibility()
            end
        end
    end
    
    local function onCharacterAdded(character)
        task.wait(0.5) 
        setupAttributeListener()
    end
    
    local function updateSpearCrosshairState()
        if enabled and isKillerTeam() then
            createCrosshair()
            
            setupAttributeListener()
            
            local charAddedConn = Liquidation.Player.CharacterAdded:Connect(onCharacterAdded)
            table.insert(teamListeners, charAddedConn)
            
            if renderConnection then
                renderConnection:Disconnect()
            end
            renderConnection = Liquidation.Services.RunService.RenderStepped:Connect(function()
                if crosshairFrame then
                            
                    crosshairFrame.Position = UDim2.new(0.5, -20, 0.5, -20)
                end
            end)
            
            Killer.Connections.SpearCrosshairRender = renderConnection
            
            updateCrosshairVisibility()
            
        elseif enabled then
            destroyCrosshair()
            if attributeListener then
                attributeListener:Disconnect()
                attributeListener = nil
            end
            if Killer.Connections.SpearCrosshairRender then
                Killer.Connections.SpearCrosshairRender:Disconnect()
                Killer.Connections.SpearCrosshairRender = nil
            end
        else
            destroyCrosshair()
            if attributeListener then
                attributeListener:Disconnect()
                attributeListener = nil
            end
            if Killer.Connections.SpearCrosshairRender then
                Killer.Connections.SpearCrosshairRender:Disconnect()
                Killer.Connections.SpearCrosshairRender = nil
            end
        end
    end
    
    local function Enable()
        if enabled then return end
        enabled = true
        Liquidation.States.SpearCrosshairEnabled = true
        
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
        
        table.insert(teamListeners, setupTeamListener(updateSpearCrosshairState))
        
        updateSpearCrosshairState()
    end
    
    local function Disable()
        if not enabled then return end
        enabled = false
        Liquidation.States.SpearCrosshairEnabled = false
        
        destroyCrosshair()
        
        if attributeListener then
            attributeListener:Disconnect()
            attributeListener = nil
        end
        
        if Killer.Connections.SpearCrosshairRender then
            Killer.Connections.SpearCrosshairRender:Disconnect()
            Killer.Connections.SpearCrosshairRender = nil
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

--  DOUBLE TAP --

local DoubleTap = (function()
    local enabled = false
    local hooked = false
    local originalNamecall = nil
    local mt = nil
    local teamListeners = {}
    
    local function GetBasicAttackRemote()
        local success, result = pcall(function()
            return Liquidation.Services.ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Attacks"):WaitForChild("BasicAttack")
        end)
        return success and result or nil
    end
    
    local function setupHook()
        if hooked then return end
        
        local basicAttack = GetBasicAttackRemote()
        if not basicAttack then
            return false
        end
        
        mt = getrawmetatable(basicAttack)
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
            
            if self == basicAttack and method == "FireServer" and enabled and isKillerTeam() then
                local args = {...}
                
                originalNamecall(self, unpack(args))
                
                task.wait(0.03)
                originalNamecall(self, unpack(args))
                
                return
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
    
    local function updateDoubleTap()
        if enabled and isKillerTeam() then
            if not setupHook() then
                task.spawn(function()
                    task.wait(2)
                    if enabled and isKillerTeam() then
                        setupHook()
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
        Liquidation.States.DoubleTapEnabled = true
        
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
        
        table.insert(teamListeners, setupTeamListener(updateDoubleTap))
        
        updateDoubleTap()
    end
    
    local function Disable()
        if not enabled then return end
        enabled = false
        Liquidation.States.DoubleTapEnabled = false
        
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

-- DESTROY PALLETS --

local DestroyPallets = (function()
    local enabled = false
    local destroyed = false
    local teamListeners = {}
    local connection = nil
    local mapCheckConnection = nil
    
    local function destroyAllPallets()
        if destroyed then
            return
        end
        
        local DestroyGlobal = Liquidation.Services.ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Pallet"):WaitForChild("Jason"):WaitForChild("Destroy-Global")
        
        local character = Liquidation.getCharacter()
        local savedPosition = nil
        
        if character and character:FindFirstChild("HumanoidRootPart") then
            savedPosition = character.HumanoidRootPart.CFrame
        end
        
        destroyed = true
        
        local palletsFound = 0
        for _, obj in ipairs(Liquidation.Services.Workspace:GetDescendants()) do
            if obj.Name:find("PalletPoint") then
                palletsFound = palletsFound + 1
                DestroyGlobal:FireServer(obj)
            end
        end
        
        task.delay(3.2, function()
            if savedPosition and character and character:FindFirstChild("HumanoidRootPart") then
                character.HumanoidRootPart.CFrame = savedPosition
            end
        end)
    end
    
    local function resetPalletsState()
        destroyed = false
    end
    
    local function checkForNewMap()
        resetPalletsState()
    end
    
    local function updateDestroyPallets()
        if enabled then
            resetPalletsState()
            
            if connection then
                connection:Disconnect()
            end
            
            if mapCheckConnection then
                mapCheckConnection:Disconnect()
            end
            
            mapCheckConnection = Liquidation.Services.Workspace.DescendantAdded:Connect(function(obj)
                if obj.Name:find("PalletPoint") then
                    task.wait(0.1)
                    resetPalletsState()
                end
            end)
            
            connection = Liquidation.Services.RunService.Heartbeat:Connect(function()
                if enabled then
                    destroyAllPallets()
                end
            end)
        else
            if connection then
                connection:Disconnect()
                connection = nil
            end
            if mapCheckConnection then
                mapCheckConnection:Disconnect()
                mapCheckConnection = nil
            end
            resetPalletsState()
        end
    end
    
    local function Enable()
        if enabled then return end
        enabled = true
        Liquidation.States.DestroyPalletsEnabled = true
        
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
        
        updateDestroyPallets()
    end
    
    local function Disable()
        if not enabled then return end
        enabled = false
        Liquidation.States.DestroyPalletsEnabled = false
        
        if connection then
            connection:Disconnect()
            connection = nil
        end
        
        if mapCheckConnection then
            mapCheckConnection:Disconnect()
            mapCheckConnection = nil
        end
        
        resetPalletsState()
        
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

--  NO SLOWDOWN --

local NoSlowdown = (function()
    local enabled = false
    local slowdownConnection = nil
    local originalSpeed = nil
    local speedLocked = false
    local teamListeners = {}

    local function saveOriginalSpeed()
        local humanoid = Liquidation.getHumanoid()
        if humanoid then
            originalSpeed = humanoid.WalkSpeed
            speedLocked = false
        end
    end
    
    local function restoreOriginalSpeed()
        local humanoid = Liquidation.getHumanoid()
        if humanoid and originalSpeed then
            humanoid.WalkSpeed = originalSpeed
        end
        speedLocked = false
    end
    
    local function updateNoSlowdown()
        if slowdownConnection then
            slowdownConnection:Disconnect()
            slowdownConnection = nil
        end
        
        if enabled and isKillerTeam() then
            saveOriginalSpeed()
            
            slowdownConnection = Liquidation.Services.RunService.Heartbeat:Connect(function()
                if not enabled or not isKillerTeam() then return end
                
                local char = Liquidation.getCharacter()
                if not char then return end
                
                local hum = Liquidation.getHumanoid()
                if not hum then return end
                
                if hum.WalkSpeed < 16 then
                    if originalSpeed and originalSpeed >= 16 then
                        hum.WalkSpeed = originalSpeed
                    else
                        hum.WalkSpeed = 16
                    end
                    speedLocked = true
                elseif not speedLocked and hum.WalkSpeed > (originalSpeed or 16) then
                    originalSpeed = hum.WalkSpeed
                end
            end)
            
            local charAddedConnection
            charAddedConnection = Liquidation.Player.CharacterAdded:Connect(function(newChar)
                if enabled and isKillerTeam() then
                    if slowdownConnection then
                        slowdownConnection:Disconnect()
                        slowdownConnection = nil
                    end
                    
                    task.wait(1)
                    
                    saveOriginalSpeed()
                    
                    if enabled and isKillerTeam() then
                        updateNoSlowdown()
                    end
                    
                    if charAddedConnection then
                        charAddedConnection:Disconnect()
                    end
                end
            end)
        elseif enabled then
            restoreOriginalSpeed()
        else
            restoreOriginalSpeed()
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
        
        table.insert(teamListeners, setupTeamListener(updateNoSlowdown))
        
        updateNoSlowdown()
    end
    
    local function Disable()
        if not enabled then return end
        enabled = false
        Liquidation.States.NoSlowdownEnabled = false
        
        if slowdownConnection then
            Liquidation.safeDisconnect(slowdownConnection)
            slowdownConnection = nil
        end
        
        restoreOriginalSpeed()
        
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

-- HITBOX --

local Hitbox = (function()
    local enabled = false
    local size = 20
    local originalSizes = {}
    local teamListeners = {}

    local function GetHealthPercent(hum)
        if not hum or hum.MaxHealth <= 0 then return 0 end
        return hum.Health / hum.MaxHealth
    end

    local function IsPlayerAlive(hum)
        local pct = GetHealthPercent(hum)
        return pct > 0.25
    end

    local function UpdateHitboxes()
        if not enabled or not isKillerTeam() then
            for player, originalSize in pairs(originalSizes) do
                if player and player.Character then
                    local root = player.Character:FindFirstChild("HumanoidRootPart")
                    if root then
                        root.Size = originalSize
                        root.Transparency = 1
                        root.CanCollide = true
                    end
                end
            end
            originalSizes = {}
            return
        end
        
        for _, player in ipairs(Liquidation.Services.Players:GetPlayers()) do
            if player ~= Liquidation.Player then
                local char = player.Character
                if char then
                    local root = char:FindFirstChild("HumanoidRootPart")
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    
                    if root and hum and hum.Health > 0 then
                        if not originalSizes[player] then
                            originalSizes[player] = root.Size
                        end
                        
                        root.Size = Vector3.new(size, size, size)
                        root.CanCollide = false
                        root.Transparency = 0.7
                    elseif root then
                        if originalSizes[player] then
                            root.Size = originalSizes[player]
                            root.Transparency = 1
                            root.CanCollide = true
                            originalSizes[player] = nil
                        end
                    end
                end
            end
        end
    end

    local function updateHitboxState()
        if enabled and isKillerTeam() then
            if not Killer.Connections.Hitbox then
                Killer.Connections.Hitbox = Liquidation.Services.RunService.Heartbeat:Connect(UpdateHitboxes)
            end
        elseif enabled then
            UpdateHitboxes()
            if Killer.Connections.Hitbox then
                Killer.Connections.Hitbox:Disconnect()
                Killer.Connections.Hitbox = nil
            end
        else
            UpdateHitboxes()
            if Killer.Connections.Hitbox then
                Killer.Connections.Hitbox:Disconnect()
                Killer.Connections.Hitbox = nil
            end
        end
    end

    local function Enable()
        if enabled then return end
        enabled = true
        Liquidation.States.HitboxEnabled = true
        
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
        
        table.insert(teamListeners, setupTeamListener(updateHitboxState))
        
        updateHitboxState()
    end

    local function Disable()
        if not enabled then return end
        enabled = false
        Liquidation.States.HitboxEnabled = false
        
        if Killer.Connections.Hitbox then
            Killer.Connections.Hitbox:Disconnect()
            Killer.Connections.Hitbox = nil
        end
        
        UpdateHitboxes()
        
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

    local function SetSize(newSize)
        size = math.clamp(newSize, 20, 500)
        if enabled and isKillerTeam() then
            UpdateHitboxes()
        end
    end

    local function GetSize()
        return size
    end

    return {
        Enable = Enable,
        Disable = Disable,
        SetSize = SetSize,
        GetSize = GetSize,
        IsEnabled = function() return enabled end
    }
end)()

-- BREAK GENERATOR --

local BreakGenerator = (function()
    local enabled = false
    local spamInProgress = false
    local maxSpamCount = 1000
    local teamListeners = {}
    
    local function getGeneratorProgress(gen)
        local progress = 0
        if gen:GetAttribute("Progress") then
            progress = gen:GetAttribute("Progress")
        elseif gen:GetAttribute("RepairProgress") then
            progress = gen:GetAttribute("RepairProgress")
        else
            for _, child in ipairs(gen:GetDescendants()) do
                if child:IsA("NumberValue") or child:IsA("IntValue") then
                    local n = child.Name:lower()
                    if n:find("progress") or n:find("repair") or n:find("percent") then
                        progress = child.Value
                        break
                    end
                end
            end
        end
        progress = (progress > 1) and progress / 100 or progress
        return math.clamp(progress, 0, 1)
    end

    local function FindNearestGenerator(maxDistance)
        local character = Liquidation.getCharacter()
        if not character then return nil end
        
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then return nil end
        
        local playerPosition = humanoidRootPart.Position
        local nearestGenerator = nil
        local nearestDistance = math.huge
        
        for _, obj in ipairs(Liquidation.Services.Workspace:GetDescendants()) do
            if obj.Name == "Generator" then
                local hitBox = obj:FindFirstChild("HitBox")
                if hitBox then
                    local distance = (hitBox.Position - playerPosition).Magnitude
                    if distance < nearestDistance and distance <= maxDistance then
                        nearestDistance = distance
                        nearestGenerator = obj
                    end
                end
            end
        end
        
        return nearestGenerator, nearestDistance
    end

    local function FullGeneratorBreak()
        if not isKillerTeam() then return false end
        
        local nearestGenerator, distance = FindNearestGenerator(10)
        if not nearestGenerator then return false end
        
        local progress = getGeneratorProgress(nearestGenerator)
        if progress <= 0 then return false end
        
        local BreakGenEvent = Liquidation.Services.ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Generator"):WaitForChild("BreakGenEvent")
        local hitBox = nearestGenerator:FindFirstChild("HitBox")
        
        if hitBox then
            BreakGenEvent:FireServer(hitBox, 0, true)
            return true
        end
        
        return false
    end

    local function SpamGeneratorBreak()
        if spamInProgress then return end
        
        if not isKillerTeam() then return end
        if not Liquidation.Player.Character then return end
        
        local nearestGenerator = FindNearestGenerator(10)
        if not nearestGenerator then return end
        
        spamInProgress = true
        local spamCount = 0
        
        local connection
        connection = Liquidation.Services.RunService.Heartbeat:Connect(function()
            if not spamInProgress then
                if connection then connection:Disconnect() end
                return
            end
            
            if not isKillerTeam() or not Liquidation.Player.Character then
                spamInProgress = false
                if connection then connection:Disconnect() end
                return
            end
            
            local currentGenerator = FindNearestGenerator(10)
            if not currentGenerator then
                spamInProgress = false
                if connection then connection:Disconnect() end
                return
            end
            
            local progress = getGeneratorProgress(currentGenerator)
            if progress <= 0 then
                spamInProgress = false
                if connection then connection:Disconnect() end
                return
            end
            
            local hitBox = currentGenerator:FindFirstChild("HitBox")
            if hitBox then
                local BreakGenEvent = Liquidation.Services.ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Generator"):WaitForChild("BreakGenEvent")
                BreakGenEvent:FireServer(hitBox, 0, true)
                spamCount = spamCount + 1
                
                if spamCount >= maxSpamCount then
                    spamInProgress = false
                    if connection then connection:Disconnect() end
                    return
                end
            else
                spamInProgress = false
                if connection then connection:Disconnect() end
                return
            end
        end)
        
        local stopConnection
        stopConnection = Liquidation.Services.UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if not gameProcessed and input.KeyCode == Enum.KeyCode.Space then
                if spamInProgress then
                    spamInProgress = false
                    if connection then connection:Disconnect() end
                    if stopConnection then stopConnection:Disconnect() end
                end
            end
        end)
    end
    
    local function updateBreakGenerator()
    end
    
    local function Enable()
        if enabled then return end
        enabled = true
        Liquidation.States.BreakGeneratorEnabled = true
        
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
        
        table.insert(teamListeners, setupTeamListener(updateBreakGenerator))
        
        updateBreakGenerator()
    end
    
    local function Disable()
        if not enabled then return end
        enabled = false
        Liquidation.States.BreakGeneratorEnabled = false
        
        spamInProgress = false
        
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
        FullGeneratorBreak = FullGeneratorBreak,
        SpamGeneratorBreak = SpamGeneratorBreak
    }
end)()

-- THIRD PERSON --

local ThirdPerson = (function()
    local enabled = false
    local originalCameraType = nil
    local thirdPersonWasActive = false
    local offset = Vector3.new(2, 1, 8)
    local teamListeners = {}

    local function UpdateThirdPerson()
        local cam = Liquidation.Services.Workspace.CurrentCamera
        if not cam then return end
        local shouldBeActive = enabled and isKillerTeam()
        
        if shouldBeActive then
            if not thirdPersonWasActive then
                originalCameraType = cam.CameraType
            end
            cam.CameraType = Enum.CameraType.Custom
            local char = Liquidation.getCharacter()
            if char then
                local hum = Liquidation.getHumanoid()
                if hum then hum.CameraOffset = offset end
            end
            thirdPersonWasActive = true
        elseif thirdPersonWasActive then
            if originalCameraType then
                cam.CameraType = originalCameraType
                originalCameraType = nil
            end
            local char = Liquidation.getCharacter()
            if char then
                local hum = Liquidation.getHumanoid()
                if hum then hum.CameraOffset = Vector3.new(0, 0, 0) end
            end
            thirdPersonWasActive = false
        end
    end

    local function updateThirdPersonState()
        if enabled and isKillerTeam() then
            if not Killer.Connections.ThirdPerson then
                Killer.Connections.ThirdPerson = Liquidation.Services.RunService.Heartbeat:Connect(UpdateThirdPerson)
            end
        elseif enabled then
            if Killer.Connections.ThirdPerson then
                Killer.Connections.ThirdPerson:Disconnect()
                Killer.Connections.ThirdPerson = nil
            end
            
            task.wait(0.1)
            local cam = Liquidation.Services.Workspace.CurrentCamera
            if cam and originalCameraType then
                cam.CameraType = originalCameraType
                originalCameraType = nil
            end
            
            local char = Liquidation.getCharacter()
            if char then
                local hum = Liquidation.getHumanoid()
                if hum then 
                    hum.CameraOffset = Vector3.new(0, 0, 0)
                end
            end
            thirdPersonWasActive = false
        else
            if Killer.Connections.ThirdPerson then
                Killer.Connections.ThirdPerson:Disconnect()
                Killer.Connections.ThirdPerson = nil
            end
            
            task.wait(0.1)
            local cam = Liquidation.Services.Workspace.CurrentCamera
            if cam and originalCameraType then
                cam.CameraType = originalCameraType
                originalCameraType = nil
            end
            
            local char = Liquidation.getCharacter()
            if char then
                local hum = Liquidation.getHumanoid()
                if hum then 
                    hum.CameraOffset = Vector3.new(0, 0, 0)
                end
            end
            thirdPersonWasActive = false
        end
    end

    local function Enable()
        if enabled then return end
        enabled = true
        Liquidation.States.ThirdPersonEnabled = true
        
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
        
        table.insert(teamListeners, setupTeamListener(updateThirdPersonState))
        
        updateThirdPersonState()
    end

    local function Disable()
        if not enabled then return end
        enabled = false
        Liquidation.States.ThirdPersonEnabled = false
        
        if Killer.Connections.ThirdPerson then
            Killer.Connections.ThirdPerson:Disconnect()
            Killer.Connections.ThirdPerson = nil
        end
        
        task.wait(0.1)
        
        local cam = Liquidation.Services.Workspace.CurrentCamera
        if cam and originalCameraType then
            cam.CameraType = originalCameraType
            originalCameraType = nil
        end
        
        local char = Liquidation.getCharacter()
        if char then
            local hum = Liquidation.getHumanoid()
            if hum then 
                hum.CameraOffset = Vector3.new(0, 0, 0)
            end
        end
        thirdPersonWasActive = false
        
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
        SetOffset = function(x, y, z)
            offset = Vector3.new(x or 2, y or 1, z or 8)
            if enabled and isKillerTeam() then
                UpdateThirdPerson()
            end
        end
    }
end)()

-- =BEAT GAME (KILLER) --

local BeatGameKiller = (function()
    local enabled = false
    local targetPlayer = nil
    local teamListeners = {}

    local function GetHealthPercent(hum)
        if not hum or hum.MaxHealth <= 0 then return 0 end
        return hum.Health / hum.MaxHealth
    end

    local function IsPlayerAlive(hum)
        local pct = GetHealthPercent(hum)
        return pct > 0.25
    end

    local function IsSurvivor(player)
        if not player or not player.Team then return false end
        local teamName = player.Team.Name:lower()
        return teamName:find("survivor") or teamName == "survivors" or teamName == "survivor"
    end

    local function IsPlayerOnHook(player)
        if not player or not player.Character then return false end
        
        local character = player.Character
        
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            for _, track in ipairs(humanoid:GetPlayingAnimationTracks()) do
                if track.Animation then
                    local animId = track.Animation.AnimationId:lower()
                    if animId:find("hook") or animId:find("trap") or animId:find("hanging") then
                        return true
                    end
                end
            end
        end
        
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                local nameLower = part.Name:lower()
                if nameLower:find("hook") or nameLower:find("trap") then
                    return true
                end
            end
        end
        
        if character:GetAttribute("IsOnHook") or character:GetAttribute("IsTrapped") then
            return true
        end
        
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            for _, obj in ipairs(rootPart:GetChildren()) do
                if obj.Name:lower():find("hook") or obj.Name:lower():find("trap") then
                    return true
                end
            end
        end
        
        return false
    end

    local function UpdateBeatGame()
        if not enabled or not isKillerTeam() then 
            targetPlayer = nil
            return 
        end
        
        local root = Liquidation.getRootPart()
        if not root then return end
        
        local needNewTarget = true
        
        if targetPlayer and targetPlayer.Character then
            local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
            local targetHum = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
            
            if targetRoot and targetHum and IsPlayerAlive(targetHum) and IsSurvivor(targetPlayer) then
                if not IsPlayerOnHook(targetPlayer) then
                    needNewTarget = false
                else
                    targetPlayer = nil
                end
            else
                targetPlayer = nil
            end
        end
        
        if needNewTarget then
            local survivors = {}
            
            for _, player in ipairs(Liquidation.Services.Players:GetPlayers()) do
                if player ~= Liquidation.Player and IsSurvivor(player) and player.Character then
                    local pRoot = player.Character:FindFirstChild("HumanoidRootPart")
                    local pHum = player.Character:FindFirstChildOfClass("Humanoid")
                    
                    if pRoot and pHum and IsPlayerAlive(pHum) then
                        if not IsPlayerOnHook(player) then
                            table.insert(survivors, player)
                        end
                    end
                end
            end
            
            if #survivors > 0 then
                local closestDist = math.huge
                local closest = nil
                
                for _, player in ipairs(survivors) do
                    local pRoot = player.Character:FindFirstChild("HumanoidRootPart")
                    local dist = (pRoot.Position - root.Position).Magnitude
                    if dist < closestDist then
                        closestDist = dist
                        closest = player
                    end
                end
                
                targetPlayer = closest
            else
                targetPlayer = nil
                return
            end
        end
        
        if not targetPlayer or not targetPlayer.Character then return end
        
        local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
        local targetHum = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
        if not targetRoot or not targetHum then 
            targetPlayer = nil
            return 
        end
        
        if not IsPlayerAlive(targetHum) or IsPlayerOnHook(targetPlayer) then
            targetPlayer = nil
            return
        end
        
        local char = Liquidation.getCharacter()
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end
        
        local targetPos = targetRoot.Position
        local direction = (root.Position - targetPos).Unit
        if direction.Magnitude ~= direction.Magnitude then 
            direction = Vector3.new(1, 0, 0)
        end
        local offsetPos = targetPos + direction * 3 + Vector3.new(0, 1, 0)
        
        root.CFrame = CFrame.new(offsetPos, targetPos)
        
        pcall(function()
            local remotes = Liquidation.Services.ReplicatedStorage:FindFirstChild("Remotes")
            if remotes then
                local attacks = remotes:FindFirstChild("Attacks")
                if attacks then
                    local basicAttack = attacks:FindFirstChild("BasicAttack")
                    if basicAttack then
                        basicAttack:FireServer(false)
                    end
                end
            end
        end)
    end

    local function updateBeatGameState()
        if enabled and isKillerTeam() then
            if not Killer.Connections.BeatGame then
                Killer.Connections.BeatGame = Liquidation.Services.RunService.Heartbeat:Connect(UpdateBeatGame)
            end
        elseif enabled then
            if Killer.Connections.BeatGame then
                Killer.Connections.BeatGame:Disconnect()
                Killer.Connections.BeatGame = nil
            end
            targetPlayer = nil
        else
            if Killer.Connections.BeatGame then
                Killer.Connections.BeatGame:Disconnect()
                Killer.Connections.BeatGame = nil
            end
            targetPlayer = nil
        end
    end

    local function Enable()
        if enabled then return end
        enabled = true
        Liquidation.States.BeatGameKillerEnabled = true
        
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
        
        table.insert(teamListeners, setupTeamListener(updateBeatGameState))
        
        updateBeatGameState()
    end

    local function Disable()
        if not enabled then return end
        enabled = false
        Liquidation.States.BeatGameKillerEnabled = false
        
        if Killer.Connections.BeatGame then
            Killer.Connections.BeatGame:Disconnect()
            Killer.Connections.BeatGame = nil
        end
        
        targetPlayer = nil
        
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
        GetCurrentTarget = function() return targetPlayer end
    }
end)()

-- ABYSSWALKER NO CD --

local AbysswalkerCorrupt = (function()
    local enabled = false
    local keybindEnabled = false
    local teamListeners = {}
    local inputConnection = nil
    
    local function canActivate()
        return enabled and keybindEnabled and isKillerTeam()
    end
    
    local function fireCorruptEvent()
        if not canActivate() then
            return
        end
        
        local success = pcall(function()
            local CorruptRemote = Liquidation.Services.ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Killers"):WaitForChild("Abysswalker"):WaitForChild("corrupt")
            CorruptRemote:FireServer()
        end)
    end
    
    local function setupKeybind()
        if inputConnection then
            inputConnection:Disconnect()
            inputConnection = nil
        end
        
        if enabled then
            inputConnection = Liquidation.Services.UserInputService.InputBegan:Connect(function(input, gameProcessed)
                if gameProcessed or not canActivate() then return end
                
                if input.KeyCode == Enum.KeyCode.Q then
                    fireCorruptEvent()
                end
            end)
        end
    end
    
    local function updateAbysswalkerState()
        if enabled and isKillerTeam() then
            keybindEnabled = true
            setupKeybind()
        elseif enabled then
            keybindEnabled = false
            if inputConnection then
                inputConnection:Disconnect()
                inputConnection = nil
            end
        else
            keybindEnabled = false
            if inputConnection then
                inputConnection:Disconnect()
                inputConnection = nil
            end
        end
    end
    
    local function Enable()
        if enabled then return end
        enabled = true
        Liquidation.States.AbysswalkerCorruptEnabled = true
        
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
        
        table.insert(teamListeners, setupTeamListener(updateAbysswalkerState))
        
        updateAbysswalkerState()
    end
    
    local function Disable()
        if not enabled then return end
        enabled = false
        keybindEnabled = false
        Liquidation.States.AbysswalkerCorruptEnabled = false
        
        if inputConnection then
            inputConnection:Disconnect()
            inputConnection = nil
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
    
    local function ForceActivate()
        if enabled and isKillerTeam() then
            fireCorruptEvent()
        end
    end
    
    return {
        Enable = Enable,
        Disable = Disable,
        IsEnabled = function() return enabled end,
        IsKeybindReady = function() return keybindEnabled end,
        Activate = ForceActivate
    }
end)()

--  ANTI BLIND --

local AntiBlind = (function()
    local enabled = false
    local isAntiBlindEnabled = false
    local hooked = false
    local originalNamecall = nil
    local mt = nil
    local teamListeners = {}
    
    local function findBlindRemotes()
        local remotes = {}
        local ReplicatedStorage = Liquidation.Services.ReplicatedStorage
        
        local function searchInFolder(folder)
            if not folder then return end
            for _, child in ipairs(folder:GetDescendants()) do
                if child:IsA("RemoteEvent") then
                    local nameLower = child.Name:lower()
                    if nameLower:find("blind") or nameLower:find("flash") or 
                       nameLower:find("gotblinded") or nameLower:find("blinded") then
                        table.insert(remotes, child)
                    end
                end
            end
        end
        
        searchInFolder(ReplicatedStorage:FindFirstChild("Remotes"))
        searchInFolder(ReplicatedStorage:FindFirstChild("Events"))
        
        for _, child in ipairs(ReplicatedStorage:GetDescendants()) do
            if child:IsA("RemoteEvent") then
                local nameLower = child.Name:lower()
                if nameLower:find("blind") or nameLower:find("flash") then
                    table.insert(remotes, child)
                end
            end
        end
        
        return remotes
    end
    
    local function setupHook()
        if hooked then return true end
        
        local blindRemotes = findBlindRemotes()
        if #blindRemotes == 0 then
            return false
        end
        
        mt = getrawmetatable(game)
        if not mt then return false end
        
        originalNamecall = mt.__namecall
        
        local wasReadonly = isreadonly and isreadonly(mt)
        if setreadonly then
            setreadonly(mt, false)
        end
        
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            
            if method == "FireServer" and isAntiBlindEnabled and isKillerTeam() then
                local remoteName = tostring(self)
                local remoteNameLower = remoteName:lower()
                
                for _, blindRemote in ipairs(blindRemotes) do
                    if self == blindRemote then
                        return nil -- block 
                    end
                end
                
                if remoteNameLower:find("blind") or 
                   remoteNameLower:find("flash") or 
                   remoteNameLower:find("gotblinded") or
                   remoteNameLower:find("blinded") then
                    return nil 
                end
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
    
    local function updateAntiBlind()
        if enabled and isKillerTeam() then
            isAntiBlindEnabled = true
            Liquidation.States.KillerAntiBlindEnabled = true
            
            if not setupHook() then
                task.spawn(function()
                    for i = 1, 5 do
                        task.wait(1)
                        if enabled and isKillerTeam() and not hooked then
                            if setupHook() then break end
                        end
                    end
                end)
            end
            
        elseif enabled then
            isAntiBlindEnabled = false
            Liquidation.States.KillerAntiBlindEnabled = false
            removeHook()
            
        else
            isAntiBlindEnabled = false
            Liquidation.States.KillerAntiBlindEnabled = false
            removeHook()
        end
    end
    
    local function Enable()
        if enabled then return end
        enabled = true
        
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
        
        table.insert(teamListeners, setupTeamListener(updateAntiBlind))
        
        updateAntiBlind()
    end
    
    local function Disable()
        if not enabled then return end
        enabled = false
        
        isAntiBlindEnabled = false
        Liquidation.States.KillerAntiBlindEnabled = false
        
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

-- NO PALLET STUN --

local NoPalletStun = (function()
    local enabled = false
    local hooked = false
    local originalNamecall = nil
    local mt = nil
    local teamListeners = {}
    local stunRemote, stunOverRemote
    
    local function getRemotes()
        if stunRemote and stunOverRemote then
            return stunRemote, stunOverRemote
        end
        
        local success1, result1 = pcall(function()
            return Liquidation.Services.ReplicatedStorage:WaitForChild("Remotes", 5)
                :WaitForChild("Pallet", 5)
                :WaitForChild("Jason", 5)
                :WaitForChild("Stun", 5)
        end)
        
        local success2, result2 = pcall(function()
            return Liquidation.Services.ReplicatedStorage:WaitForChild("Remotes", 5)
                :WaitForChild("Pallet", 5)
                :WaitForChild("Jason", 5)
                :WaitForChild("Stunover", 5)
        end)
        
        if success1 then stunRemote = result1 end
        if success2 then stunOverRemote = result2 end
        
        return stunRemote, stunOverRemote
    end
    
    local function callStunOver()
        if not stunOverRemote then
            getRemotes()
        end
        
        if stunOverRemote then
            pcall(function()
                stunOverRemote:FireServer()
            end)
        end
    end
    
    local function setupHook()
        if hooked then return true end
        
        local stunRemoteFound, stunOverRemoteFound = getRemotes()
        if not stunRemoteFound then
            return false
        end
        
        mt = getrawmetatable(stunRemoteFound)
        if not mt then return false end
        
        originalNamecall = mt.__namecall
        
        local wasReadonly = isreadonly and isreadonly(mt)
        if setreadonly then
            setreadonly(mt, false)
        end
        
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            
            if self == stunRemoteFound and method == "FireServer" and enabled and isKillerTeam() then
                local result = originalNamecall(self, ...)
                
                task.spawn(function()
                    callStunOver()
                end)
                
                return result
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
        stunRemote = nil
        stunOverRemote = nil
    end
    
    local function updateNoPalletStun()
        if enabled and isKillerTeam() then
            if not setupHook() then
                task.spawn(function()
                    for i = 1, 5 do
                        task.wait(1)
                        if enabled and isKillerTeam() and not hooked then
                            if setupHook() then 
                                break 
                            end
                        end
                    end
                end)
            end
        else
            removeHook()
        end
    end
    
    local function Enable()
        if enabled then return end
        enabled = true
        Liquidation.States.NoPalletStunEnabled = true
        
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
        
        table.insert(teamListeners, setupTeamListener(updateNoPalletStun))
        
        updateNoPalletStun()
    end
    
    local function Disable()
        if not enabled then return end
        enabled = false
        Liquidation.States.NoPalletStunEnabled = false
        
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
        IsEnabled = function() return enabled end,
        GetStatus = function() 
            return {
                hooked = hooked,
                stunRemoteFound = stunRemote ~= nil,
                stunOverRemoteFound = stunOverRemote ~= nil
            }
        end
    }
end)()

-- SPEAR AIMBOT --

local SpearAimBot = (function()
    local enabled = false
    local active = true
    local isFiring = false
    local oldNamecall = nil
    local remote = nil
    local teamListeners = {}
    
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
    
    local function getSpearRemote()
        local success, result = pcall(function()
            return Liquidation.Services.ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Killers"):WaitForChild("Veil"):WaitForChild("Spearthrow")
        end)
        return success and result or nil
    end
    
    local function setupHook()
        if oldNamecall then return end
        
        remote = getSpearRemote()
        if not remote then return false end
        
        oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local method = getnamecallmethod()
            
            if method == "FireServer" and self == remote and enabled and active and not isFiring then
                local direction, num = ...
                
                if direction and typeof(direction) == "Vector3" and num then
                    local target = GetClosestPlayer()
                    if target and target.Character then
                        local targetPart = target.Character:FindFirstChild("HumanoidRootPart")
                        if targetPart then
                            local cameraPos = workspace.CurrentCamera.CFrame.Position
                            local newDirection = (targetPart.Position - cameraPos).Unit
                            isFiring = true
                            remote:FireServer(newDirection, num)
                            isFiring = false
                            return nil
                        end
                    end
                end
            end
            
            return oldNamecall(self, ...)
        end))
        
        return true
    end
    
    local function removeHook()
        if oldNamecall then
            oldNamecall = nil
        end
    end
    
    local function updateSpearAimbotState()
        if enabled and isKillerTeam() then
            if not oldNamecall then
                setupHook()
            end
        else
            removeHook()
        end
    end
    
    local function Enable()
        if enabled then return end
        enabled = true
        Liquidation.States.SpearAimbotEnabled = true
        
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
        
        table.insert(teamListeners, setupTeamListener(updateSpearAimbotState))
        
        updateSpearAimbotState()
    end
    
    local function Disable()
        if not enabled then return end
        enabled = false
        Liquidation.States.SpearAimbotEnabled = false
        
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
        IsEnabled = function() return enabled end,
        Toggle = function()
            active = not active
            return active
        end
    }
end)()

-- MASK POWERS --

local function activateMaskPower(maskName)
    local success, result = pcall(function()
        if not isKillerTeam() then
            return false
        end
        
        local remotes = Liquidation.Services.ReplicatedStorage:WaitForChild("Remotes")
        local killers = remotes:WaitForChild("Killers")
        local masked = killers:WaitForChild("Masked")
        local activatePower = masked:WaitForChild("Activatepower")
        
        activatePower:FireServer(maskName)
        return true
    end)
    
    return success and result
end

-- TOGGLE FUNCTIONS --

function Killer.Init(nxs)
    Liquidation = nxs
    
    local Tabs = Liquidation.Tabs
    local Options = Liquidation.Options
    
    local SpearCrosshairToggle = Tabs.Killer:AddToggle("SpearCrosshair", {
        Title = "Spear Crosshair (Veil)", 
        Description = "Shows the scope in Veil spear mode", 
        Default = false
    })

    SpearCrosshairToggle:OnChanged(function(v)
        Liquidation.SafeCallback(function()
            if v then 
                SpearCrosshair.Enable() 
            else 
                SpearCrosshair.Disable() 
            end
        end)
    end)

    local DestroyPalletsToggle = Tabs.Killer:AddToggle("DestroyPallets", {
        Title = "Destroy All Pallets [He also works for the survivor]", 
        Description = "Smash all the pallets on the map", 
        Default = false
    })

    DestroyPalletsToggle:OnChanged(function(v)
        Liquidation.SafeCallback(function()
            if v then 
                DestroyPallets.Enable() 
            else 
                DestroyPallets.Disable() 
            end
        end)
    end)

    local NoSlowdownToggle = Tabs.Killer:AddToggle("NoSlowdown", {
        Title = "No Slowdown", 
        Description = "Prevents slowdown when attacking", 
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

    local HitboxToggle = Tabs.Killer:AddToggle("Hitbox", {
        Title = "Hitbox Expand", 
        Description = "Expand survivor hitboxes for easier hits", 
        Default = false
    })

    HitboxToggle:OnChanged(function(v)
        Liquidation.SafeCallback(function()
            if v then 
                Hitbox.Enable() 
            else 
                Hitbox.Disable() 
            end
        end)
    end)

    local HitboxSlider = Tabs.Killer:AddSlider("HitboxSize", {
        Title = "Hitbox Size",
        Description = "Adjust hitbox size",
        Default = 20,
        Min = 20,
        Max = 500,
        Rounding = 1,
        Callback = function(value)
            Liquidation.SafeCallback(function()
                Hitbox.SetSize(value)
            end)
        end
    })

    local BreakGeneratorToggle = Tabs.Killer:AddToggle("BreakGenerator", {
        Title = "FullGeneratorBreak", 
        Description = "Complete generator failure", 
        Default = false
    })

    BreakGeneratorToggle:OnChanged(function(v)
        Liquidation.SafeCallback(function()
            if v then 
                BreakGenerator.Enable() 
            else 
                BreakGenerator.Disable() 
            end
        end)
    end)

    local ThirdPersonToggle = Tabs.Killer:AddToggle("ThirdPerson", {
        Title = "Third Person", 
        Description = "Toggle third person view", 
        Default = false
    })

    ThirdPersonToggle:OnChanged(function(v)
        Liquidation.SafeCallback(function()
            if v then 
                ThirdPerson.Enable() 
            else 
                ThirdPerson.Disable() 
            end
        end)
    end)

    local NoPalletStunToggle = Tabs.Killer:AddToggle("NoPalletStun", {
        Title = "No Pallet Stun", 
        Description = "Protection against pallet stunning", 
        Default = false
    })

    NoPalletStunToggle:OnChanged(function(v)
        Liquidation.SafeCallback(function()
            if v then 
                NoPalletStun.Enable() 
            else 
                NoPalletStun.Disable() 
            end
        end)
    end)

    local DoubleTapToggle = Tabs.Killer:AddToggle("DoubleTap", {
        Title = "Double Tap", 
        Description = "Attacks twice with one attack", 
        Default = false
    })

    DoubleTapToggle:OnChanged(function(v)
        Liquidation.SafeCallback(function()
            if v then 
                DoubleTap.Enable() 
            else 
                DoubleTap.Disable() 
            end
        end)
    end)
    
    local BeatGameToggle = Tabs.Killer:AddToggle("BeatGame", {
        Title = "Beat Game (Killer)", 
        Description = "Automatically hunt and kill all survivors", 
        Default = false
    })

    BeatGameToggle:OnChanged(function(v)
        Liquidation.SafeCallback(function()
            if v then 
                BeatGameKiller.Enable() 
            else 
                BeatGameKiller.Disable() 
            end
        end)
    end)

    local UseFakeSawToggle = Tabs.Killer:AddToggle("UseFakeSaw", {
        Title = "Use Fake Saw [ONLY MASKED]", 
        Description = "Continuously activates Alex's chainsaw attack (kills from 1 time)", 
        Default = false
    })

    UseFakeSawToggle:OnChanged(function(v)
        Liquidation.SafeCallback(function()
            if v then 
                UseFakeSaw.Enable() 
            else 
                UseFakeSaw.Disable() 
            end
        end)
    end)
    
    local AbysswalkerCorruptToggle = Tabs.Killer:AddToggle("AbysswalkerCorrupt", {
        Title = "Abysswalker Corrupt NO CD",
        Description = "no cooldown",
        Default = false
    })

    AbysswalkerCorruptToggle:OnChanged(function(v)
        Liquidation.SafeCallback(function()
            if v then 
                AbysswalkerCorrupt.Enable() 
            else 
                AbysswalkerCorrupt.Disable() 
            end
        end)
    end)

    local AntiBlindToggle = Tabs.Killer:AddToggle("AntiBlind", {
        Title = "Anti Blind", 
        Description = "prevents you from being blinded by a flashlight", 
        Default = false
    })

    AntiBlindToggle:OnChanged(function(v)
        Liquidation.SafeCallback(function()
            if v then 
                AntiBlind.Enable() 
            else 
                AntiBlind.Disable() 
            end
        end)
    end)

    local SpearAimbotToggle = Tabs.Killer:AddToggle("SpearAimbot", {
        Title = "Spear AimBot (Veil)",
        Description = "automatically aims a spear at the nearest Survivor when thrown",
        Default = false
    })

    SpearAimbotToggle:OnChanged(function(v)
        Liquidation.SafeCallback(function()
            if v then
                SpearAimBot.Enable()
            else
                SpearAimBot.Disable()
            end
        end)
    end)

    local MaskPowers = Tabs.Killer:AddDropdown("MaskPowers", {
        Title = "Mask Powers",
        Description = "Select mask power to activate immediately",
        Values = {"Alex", "Tony", "Brandon", "Jake", "Richter", "Graham", "Richard"},
        Multi = false,
        Default = ""
    })

    MaskPowers:OnChanged(function(value)
        Liquidation.SafeCallback(function()
            if value and value ~= "" then
                activateMaskPower(value)
            end
        end)
    end)

    Tabs.Killer:AddParagraph({
        Title = "Mask Powers Information",
        Content = "Alex - Chainsaw\nTony - Fists\nBrandon - Speed\nJake - Long lunge\nRichter - Stealth\nGraham - Faster vaults\nRichard - Default mask"
    })

    Liquidation.Services.UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == Enum.KeyCode.Space then
            if Liquidation.States.BreakGeneratorEnabled then
                BreakGenerator.SpamGeneratorBreak()
            end
        end
    end)
end

function Killer.Cleanup()
    
    SpearCrosshair.Disable()
    DestroyPallets.Disable()
    NoSlowdown.Disable()
    Hitbox.Disable()
    BreakGenerator.Disable()
    ThirdPerson.Disable()
    NoPalletStun.Disable()
    DoubleTap.Disable()      
    BeatGameKiller.Disable()
    AbysswalkerCorrupt.Disable()
    UseFakeSaw.Disable() 
    AntiBlind.Disable()
    SpearAimBot.Disable()
    
    for key, connection in pairs(Killer.Connections) do
        Liquidation.safeDisconnect(connection)
    end
    Killer.Connections = {}
    
    Killer.HitboxCache = {}
end

Killer.SpearCrosshair = SpearCrosshair;
Killer.DestroyPallets = DestroyPallets;
Killer.NoSlowdown = NoSlowdown;
Killer.Hitbox = Hitbox;
Killer.BreakGenerator = BreakGenerator;
Killer.ThirdPerson = ThirdPerson;
Killer.NoPalletStun = NoPalletStun;
Killer.DoubleTap = DoubleTap;
Killer.BeatGameKiller = BeatGameKiller;
Killer.AbysswalkerCorrupt = AbysswalkerCorrupt;
Killer.UseFakeSaw = UseFakeSaw;
Killer.AntiBlind = AntiBlind;
Killer.SpearAimBot = SpearAimBot;
Killer.ActivateMaskPower = activateMaskPower;

return Killer