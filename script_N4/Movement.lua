local Liquidation = _G.Liquidation

local Movement = {
    Connections = {},
    States = {
        WalkSpeedEnabled = false,
        FlyEnabled = false,
        FreeCameraEnabled = false,
        noclipEnabled = false
    },
    Settings = {
        walkSpeed = 50,
        flySpeed = 50,
        freeCameraSpeed = 50,
        fovValue = 95,
        fovEnabled = false
    },
    Objects = {
        bodyVelocity = nil,
        bodyGyro = nil,
        currentTween = nil
    }
}

-- Use global helper functions from Liquidation
function Movement.GetCharacter()
    return Liquidation.getCharacter()
end

function Movement.GetHumanoid()
    return Liquidation.getHumanoid()
end

function Movement.GetRootPart()
    return Liquidation.getRootPart()
end

-- WALK SPEED --

local WalkSpeed = (function()
    local WALKSPEED_ENABLED = false
    local currentSpeed = 50
    local speedConnection = nil
    
    local function EnableWalkSpeed()
        if WALKSPEED_ENABLED then return end
        
        WALKSPEED_ENABLED = true
        Movement.States.WalkSpeedEnabled = true
        
        speedConnection = Liquidation.Services.RunService.Heartbeat:Connect(function()
            if not WALKSPEED_ENABLED or not Liquidation.Player.Character then
                if speedConnection then
                    speedConnection:Disconnect()
                    speedConnection = nil
                end
                return
            end
            
            local character = Liquidation.Player.Character
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            if not rootPart then return end
            
            local direction = Vector3.new(0, 0, 0)
            local camera = Liquidation.Services.Workspace.CurrentCamera
            
            if Liquidation.Services.UserInputService:IsKeyDown(Enum.KeyCode.W) then
                direction = direction + camera.CFrame.LookVector
            end
            if Liquidation.Services.UserInputService:IsKeyDown(Enum.KeyCode.S) then
                direction = direction - camera.CFrame.LookVector
            end
            if Liquidation.Services.UserInputService:IsKeyDown(Enum.KeyCode.A) then
                direction = direction - camera.CFrame.RightVector
            end
            if Liquidation.Services.UserInputService:IsKeyDown(Enum.KeyCode.D) then
                direction = direction + camera.CFrame.RightVector
            end
            
            if direction.Magnitude > 0 then
                direction = direction.Unit
                local velocity = direction * currentSpeed
                rootPart.Velocity = Vector3.new(velocity.X, rootPart.Velocity.Y, velocity.Z)
            end
        end)
    end
    
    local function DisableWalkSpeed()
        if not WALKSPEED_ENABLED then return end
        
        WALKSPEED_ENABLED = false
        Movement.States.WalkSpeedEnabled = false
        
        if speedConnection then
            Liquidation.safeDisconnect(speedConnection)
            speedConnection = nil
        end
    end
    
    local function SetSpeed(speed)
        currentSpeed = tonumber(speed) or 50
        Movement.Settings.walkSpeed = currentSpeed
    end
    
    return {
        Enable = EnableWalkSpeed,
        Disable = DisableWalkSpeed,
        SetSpeed = SetSpeed,
        IsEnabled = function() return WALKSPEED_ENABLED end,
        GetSpeed = function() return currentSpeed end
    }
end)()

-- NO CLIP --

local NoClip = (function()
    local noclipEnabled = false
    local noclipConnection = nil
    local originalCollisions = {}

    local function saveOriginalCollisions(character)
        if not character then return end
        
        originalCollisions = {}
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then 
                originalCollisions[part] = part.CanCollide
            end
        end
    end

    local function restoreOriginalCollisions(character)
        if not character then return end
        
        for part, canCollide in pairs(originalCollisions) do
            if part and part.Parent then
                pcall(function()
                    part.CanCollide = canCollide
                end)
            end
        end
        originalCollisions = {}
    end

    local function EnableNoClip()
        if noclipEnabled then return end
        noclipEnabled = true
        Movement.States.noclipEnabled = true
        
        local character = Movement.GetCharacter()
        if character then
            saveOriginalCollisions(character)
        end
        
        noclipConnection = Liquidation.Services.RunService.Stepped:Connect(function()
            if not noclipEnabled or not Movement.GetCharacter() then 
                if noclipConnection then
                    noclipConnection:Disconnect()
                    noclipConnection = nil
                end
                return 
            end
            
            local character = Movement.GetCharacter()
            if character then
                for _, part in ipairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then 
                        pcall(function()
                            part.CanCollide = false
                        end)
                    end
                end
            end
        end)
        
        Liquidation.Player.CharacterAdded:Connect(function(newChar)
            if noclipEnabled then
                task.wait(1)
                saveOriginalCollisions(newChar)
            end
        end)
    end

    local function DisableNoClip()
        if not noclipEnabled then return end
        
        noclipEnabled = false
        Movement.States.noclipEnabled = false
        
        if noclipConnection then
            noclipConnection:Disconnect()
            noclipConnection = nil
        end
        
        local character = Movement.GetCharacter()
        if character then
            restoreOriginalCollisions(character)
        end
    end

    return {
        Enable = EnableNoClip,
        Disable = DisableNoClip,
        IsEnabled = function() return noclipEnabled end
    }
end)()

-- FLY --

local function enableFly()
    if Movement.States.FlyEnabled then return end
    Movement.States.FlyEnabled = true
    
    local character, humanoid, rootPart = Movement.GetCharacter(), Movement.GetHumanoid(), Movement.GetRootPart()
    if not character or not humanoid or not rootPart then return end
    
    humanoid.PlatformStand = true
    Movement.Objects.bodyVelocity = Instance.new("BodyVelocity")
    Movement.Objects.bodyGyro = Instance.new("BodyGyro")
    
    Movement.Objects.bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    Movement.Objects.bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    Movement.Objects.bodyVelocity.Parent = rootPart
    
    Movement.Objects.bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    Movement.Objects.bodyGyro.P = 10000
    Movement.Objects.bodyGyro.D = 500
    Movement.Objects.bodyGyro.CFrame = rootPart.CFrame
    Movement.Objects.bodyGyro.Parent = rootPart

    Movement.Connections.flyLoop = Liquidation.Services.RunService.Heartbeat:Connect(function()
        if not Movement.States.FlyEnabled or not Movement.Objects.bodyVelocity or not Movement.Objects.bodyGyro or 
           not character or not humanoid or not rootPart then
            if Movement.Connections.flyLoop then
                Movement.Connections.flyLoop:Disconnect()
                Movement.Connections.flyLoop = nil
            end
            return
        end
        
        local camera = Liquidation.Services.Workspace.CurrentCamera
        local direction = Vector3.new(0, 0, 0)
        
        if Liquidation.Services.UserInputService:IsKeyDown(Enum.KeyCode.W) then 
            direction = direction + camera.CFrame.LookVector 
        end
        if Liquidation.Services.UserInputService:IsKeyDown(Enum.KeyCode.S) then 
            direction = direction - camera.CFrame.LookVector 
        end
        if Liquidation.Services.UserInputService:IsKeyDown(Enum.KeyCode.A) then 
            direction = direction - camera.CFrame.RightVector 
        end
        if Liquidation.Services.UserInputService:IsKeyDown(Enum.KeyCode.D) then 
            direction = direction + camera.CFrame.RightVector 
        end
        if Liquidation.Services.UserInputService:IsKeyDown(Enum.KeyCode.Space) then 
            direction = direction + Vector3.new(0, 1, 0) 
        end
        if Liquidation.Services.UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then 
            direction = direction + Vector3.new(0, -1, 0) 
        end

        if direction.Magnitude > 0 then 
            direction = direction.Unit * Movement.Settings.flySpeed 
        end
        
        Movement.Objects.bodyVelocity.Velocity = direction
        Movement.Objects.bodyGyro.CFrame = CFrame.new(rootPart.Position, rootPart.Position + camera.CFrame.LookVector)
    end)
end

local function disableFly()
    if not Movement.States.FlyEnabled then return end
    Movement.States.FlyEnabled = false
    
    if Movement.Objects.bodyVelocity then 
        Movement.Objects.bodyVelocity:Destroy()
        Movement.Objects.bodyVelocity = nil 
    end
    if Movement.Objects.bodyGyro then 
        Movement.Objects.bodyGyro:Destroy()
        Movement.Objects.bodyGyro = nil 
    end
    
    local humanoid = Movement.GetHumanoid()
    if humanoid then 
        humanoid.PlatformStand = false 
    end
    
    if Movement.Connections.flyLoop then
        Movement.Connections.flyLoop:Disconnect()
        Movement.Connections.flyLoop = nil
    end
end

-- FREE CAMERA --

local function lockMouse()
    if not Movement.States.FreeCameraEnabled then return end
    Movement.Objects.mouseLocked = true
    Liquidation.Services.UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
    Liquidation.Services.UserInputService.MouseIconEnabled = false
end

local function unlockMouse()
    Movement.Objects.mouseLocked = false
    Liquidation.Services.UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    Liquidation.Services.UserInputService.MouseIconEnabled = true
end

local function startFreeCamera()
    if Movement.States.FreeCameraEnabled then return end
    Movement.States.FreeCameraEnabled = true
    
    local camera = Liquidation.Camera
    Movement.Objects.originalCameraType = camera.CameraType
    Movement.Objects.originalCameraSubject = camera.CameraSubject
    camera.CameraType = Enum.CameraType.Scriptable
    
    local cameraPosition = camera.CFrame.Position
    local lookVector = camera.CFrame.LookVector
    local cameraRotation = Vector2.new(math.atan2(lookVector.X, lookVector.Z), math.asin(lookVector.Y))
    
    lockMouse()
    
    if Movement.GetCharacter() then
        local humanoid, rootPart = Movement.GetHumanoid(), Movement.GetRootPart()
        if humanoid then 
            humanoid.PlatformStand = false
            humanoid.AutoRotate = false 
        end
        if rootPart then 
            rootPart.Anchored = true 
        end
    end
    
    Movement.Connections.freeCamera = Liquidation.Services.RunService.RenderStepped:Connect(function(delta)
        if not Movement.States.FreeCameraEnabled then 
            if Movement.Connections.freeCamera then
                Movement.Connections.freeCamera:Disconnect()
                Movement.Connections.freeCamera = nil
            end
            return 
        end
        
        local mouseDelta = Liquidation.Services.UserInputService:GetMouseDelta()
        cameraRotation = cameraRotation + Vector2.new(-mouseDelta.X * 0.003, -mouseDelta.Y * 0.003)
        cameraRotation = Vector2.new(cameraRotation.X, 
            math.clamp(cameraRotation.Y, -math.pi/2 + 0.1, math.pi/2 - 0.1))
        
        local rotationCFrame = CFrame.Angles(0, cameraRotation.X, 0) * CFrame.Angles(cameraRotation.Y, 0, 0)
        local moveDirection = Vector3.new(0, 0, 0)
        
        if Liquidation.Services.UserInputService:IsKeyDown(Enum.KeyCode.W) then 
            moveDirection = moveDirection + rotationCFrame.LookVector 
        end
        if Liquidation.Services.UserInputService:IsKeyDown(Enum.KeyCode.S) then 
            moveDirection = moveDirection - rotationCFrame.LookVector 
        end
        if Liquidation.Services.UserInputService:IsKeyDown(Enum.KeyCode.A) then 
            moveDirection = moveDirection - rotationCFrame.RightVector 
        end
        if Liquidation.Services.UserInputService:IsKeyDown(Enum.KeyCode.D) then 
            moveDirection = moveDirection + rotationCFrame.RightVector 
        end
        if Liquidation.Services.UserInputService:IsKeyDown(Enum.KeyCode.E) or 
           Liquidation.Services.UserInputService:IsKeyDown(Enum.KeyCode.Space) then 
            moveDirection = moveDirection + Vector3.new(0, 1, 0) 
        end
        if Liquidation.Services.UserInputService:IsKeyDown(Enum.KeyCode.Q) then 
            moveDirection = moveDirection + Vector3.new(0, -1, 0) 
        end
        
        if moveDirection.Magnitude > 0 then 
            moveDirection = moveDirection.Unit * Movement.Settings.freeCameraSpeed
            cameraPosition = cameraPosition + moveDirection * delta 
        end
        
        camera.CFrame = CFrame.new(cameraPosition) * rotationCFrame
    end)
end

local function stopFreeCamera()
    if not Movement.States.FreeCameraEnabled then return end
    Movement.States.FreeCameraEnabled = false
    
    unlockMouse()
    
    if Movement.Connections.freeCamera then
        Movement.Connections.freeCamera:Disconnect()
        Movement.Connections.freeCamera = nil
    end
    
    local camera = Liquidation.Camera
    camera.CameraType = Movement.Objects.originalCameraType
    camera.CameraSubject = Movement.Objects.originalCameraSubject
    
    if Movement.GetCharacter() then
        local humanoid, rootPart = Movement.GetHumanoid(), Movement.GetRootPart()
        if humanoid then 
            humanoid.PlatformStand = false
            humanoid.AutoRotate = true 
        end
        if rootPart then 
            rootPart.Anchored = false 
        end
    end
end

-- INFINITE LUNGE --

local InfiniteLunge = (function()
    local isLunging = false
    local lungeSpeed = 50
    local lungeConnection = nil
    
    local function EnableInfiniteLunge()
        if Movement.States.InfiniteLungeEnabled then return end
        Movement.States.InfiniteLungeEnabled = true
    end
    
    local function DisableInfiniteLunge()
        Movement.States.InfiniteLungeEnabled = false
        isLunging = false
        
        if lungeConnection then
            lungeConnection:Disconnect()
            lungeConnection = nil
        end
    end
    
    local function HandleInput(input, gameProcessed)
        if gameProcessed or not Movement.States.InfiniteLungeEnabled then
            return
        end
        
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if input.UserInputState == Enum.UserInputState.Begin then
                isLunging = true
                if Liquidation.Player.Character then
                    if lungeConnection then
                        lungeConnection:Disconnect()
                    end
                    
                    lungeConnection = Liquidation.Services.RunService.Heartbeat:Connect(function()
                        if not Movement.States.InfiniteLungeEnabled or not isLunging or not Liquidation.Player.Character then
                            if lungeConnection then
                                lungeConnection:Disconnect()
                                lungeConnection = nil
                            end
                            return
                        end
                        
                        local rootPart = Liquidation.Player.Character:FindFirstChild("HumanoidRootPart")
                        
                        if rootPart then
                            local lookVector = rootPart.CFrame.LookVector
                            local velocity = lookVector * lungeSpeed
                            rootPart.Velocity = Vector3.new(velocity.X, rootPart.Velocity.Y, velocity.Z)
                        end
                    end)
                end
                
            elseif input.UserInputState == Enum.UserInputState.End then
                isLunging = false
                if lungeConnection then
                    lungeConnection:Disconnect()
                    lungeConnection = nil
                end
            end
        end
    end
    

    local inputBeganConn = Liquidation.Services.UserInputService.InputBegan:Connect(HandleInput)
    local inputEndedConn = Liquidation.Services.UserInputService.InputEnded:Connect(HandleInput)

    Movement.Connections.InfiniteLungeBegan = inputBeganConn
    Movement.Connections.InfiniteLungeEnded = inputEndedConn
    
    return {
        Enable = EnableInfiniteLunge,
        Disable = DisableInfiniteLunge,
        SetSpeed = function(speed) 
            lungeSpeed = speed 
            Movement.Settings.lungeSpeed = speed
        end,
        IsEnabled = function() return Movement.States.InfiniteLungeEnabled end
    }
end)()

-- FOV SYSTEM --

local function ApplyFOV()
    local camera = Liquidation.Camera
    if camera and Movement.Settings.fovEnabled then
        Movement.Settings.fovTargetValue = math.max(1, Movement.Settings.fovValue)
    elseif camera then
        camera.FieldOfView = 70
    end
end

function Movement.Init(nxs)
    Liquidation = nxs
    
    local Tabs = Liquidation.Tabs
    local Options = Liquidation.Options
    
    Liquidation.Services.Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        task.wait(0.1)
        Liquidation.Camera = Liquidation.Services.Workspace.CurrentCamera
        ApplyFOV()
    end)

    pcall(function()
        Liquidation.Services.RunService:UnbindFromRenderStep("NexusFOVUpdater")
    end)
    
    Liquidation.Services.RunService:BindToRenderStep("NexusFOVUpdater", Enum.RenderPriority.Camera.Value + 1, function()
        if Movement.Settings.fovEnabled and Liquidation.Camera then
            local targetFOV = math.max(1, Movement.Settings.fovTargetValue or 70)
            Liquidation.Camera.FieldOfView = targetFOV
        end
    end)

    if Liquidation.IS_DESKTOP then
        local InfiniteLungeToggle = Tabs.Movement:AddToggle("InfiniteLunge", {
            Title = "Infinite Lunge", 
            Description = "Hold LMB to lunge forward", 
            Default = false
        })

        InfiniteLungeToggle:OnChanged(function(v) 
            Liquidation.SafeCallback(function()
                if v then 
                    InfiniteLunge.Enable() 
                else 
                    InfiniteLunge.Disable() 
                end 
            end)
        end)

        local LungeSpeedSlider = Tabs.Movement:AddSlider("LungeSpeed", {
            Title = "Lunge Speed", 
            Description = "", 
            Default = 50, 
            Min = 10, 
            Max = 200, 
            Rounding = 0, 
            Callback = function(value) 
                Liquidation.SafeCallback(function()
                    InfiniteLunge.SetSpeed(value)
                end)
            end
        })
    end
    
    local WalkSpeedToggle = Tabs.Movement:AddToggle("WalkSpeed", {
        Title = "Walk Speed", 
        Description = "", 
        Default = false
    })

    WalkSpeedToggle:OnChanged(function(v) 
        Liquidation.SafeCallback(function()
            if v then 
                WalkSpeed.Enable() 
            else 
                WalkSpeed.Disable() 
            end 
        end)
    end)

    local WalkSpeedSlider = Tabs.Movement:AddSlider("WalkSpeedValue", {
        Title = "Walk Speed Value", 
        Description = "0-200", 
        Default = 16, 
        Min = 0, 
        Max = 200, 
        Rounding = 0, 
        Callback = function(value) 
            Liquidation.SafeCallback(function()
                WalkSpeed.SetSpeed(value)
            end)
        end
    })

    local NoclipToggle = Tabs.Movement:AddToggle("Noclip", {
        Title = "Noclip",
        Description = "",
        Default = false
    })

    NoclipToggle:OnChanged(function(value)
        Liquidation.SafeCallback(function()
            if value then 
                NoClip.Enable() 
            else 
                NoClip.Disable()
            end 
        end)
    end)

    local FOVToggle = Tabs.Movement:AddToggle("FOVChanger", {
        Title = "FOV Changer", 
        Description = "", 
        Default = false
    })

    FOVToggle:OnChanged(function(v)
        Liquidation.SafeCallback(function()
            Movement.Settings.fovEnabled = v
            ApplyFOV()
        end)
    end)

    local FOVSlider = Tabs.Movement:AddSlider("FOVValue", {
        Title = "FOV Value", 
        Description = "0-120",
        Default = 95,
        Min = 0,
        Max = 120,
        Rounding = 0,
        Callback = function(value)
            Liquidation.SafeCallback(function()
                Movement.Settings.fovValue = value
                ApplyFOV()
            end)
        end
    })

    local function GetPlayerNames()
        local names = {"--"}
        for _, player in ipairs(Liquidation.Services.Players:GetPlayers()) do
            if player ~= Liquidation.Player then
                table.insert(names, player.Name)
            end
        end
        return names
    end

    local PlayerDropdown = Tabs.Movement:AddDropdown("TeleportToPlayer", {
        Title = "Teleport to Player",
        Values = GetPlayerNames(),
        Multi = false,
        Default = "--",
    })

    local function UpdatePlayerDropdown()
        if PlayerDropdown and PlayerDropdown.SetValues then
             pcall(function() PlayerDropdown:SetValues(GetPlayerNames()) end)
        end
    end

    table.insert(Movement.Connections, Liquidation.Services.Players.PlayerAdded:Connect(UpdatePlayerDropdown))
    table.insert(Movement.Connections, Liquidation.Services.Players.PlayerRemoving:Connect(UpdatePlayerDropdown))

    PlayerDropdown:OnChanged(function(value)
        if value ~= "--" then
            Liquidation.SafeCallback(function()
                local targetPlayer = Liquidation.Services.Players:FindFirstChild(value)
                if targetPlayer then
                    local targetChar = targetPlayer.Character
                    if targetChar then
                        local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
                        local localRoot = Movement.GetRootPart()
                        
                        if localRoot and targetRoot then
                            localRoot.CFrame = targetRoot.CFrame + Vector3.new(0, 3, 0)
                            Liquidation.Notify("Teleport", "Teleported to " .. value, 3)
                        end
                    end
                end
                
                task.delay(0.1, function()
                     if PlayerDropdown and PlayerDropdown.SetValue then
                        pcall(function() PlayerDropdown:SetValue("--") end)
                     end
                end)
            end)
        end
    end)

    if Liquidation.IS_DESKTOP then
        local FlyToggle = Tabs.Movement:AddToggle("Fly", {
            Title = "Fly", 
            Description = "Allows flying in any direction", 
            Default = false
        })

        FlyToggle:OnChanged(function(value) 
            Liquidation.SafeCallback(function()
                if value then 
                    enableFly() 
                else 
                    disableFly() 
                end 
            end)
        end)

        local FlySpeedSlider = Tabs.Movement:AddSlider("FlySpeed", {
            Title = "Fly Speed", 
            Description = "0-200", 
            Default = 50, 
            Min = 0, 
            Max = 200, 
            Rounding = 0, 
            Callback = function(value) 
                Liquidation.SafeCallback(function()
                    Movement.Settings.flySpeed = value
                end)
            end
        })

        local FreeCameraToggle = Tabs.Movement:AddToggle("FreeCamera", {
            Title = "Free Camera", 
            Description = "", 
            Default = false
        })

        FreeCameraToggle:OnChanged(function(value) 
            Liquidation.SafeCallback(function()
                if value then 
                    startFreeCamera() 
                else 
                    stopFreeCamera() 
                end 
            end)
        end)

        local FreeCameraSpeedSlider = Tabs.Movement:AddSlider("FreeCameraSpeed", {
            Title = "Free Camera Speed", 
            Description = "0-100", 
            Default = 50, 
            Min = 0, 
            Max = 100, 
            Rounding = 0, 
            Callback = function(value) 
                Liquidation.SafeCallback(function()
                    Movement.Settings.freeCameraSpeed = value
                end)
            end
        })
    end
end


function Movement.Cleanup()
    
    InfiniteLunge.Disable()
    WalkSpeed.Disable()
    NoClip.Disable()
    disableFly()
    stopFreeCamera()
    Movement.Settings.fovEnabled = false
    
    pcall(function()
        Liquidation.Services.RunService:UnbindFromRenderStep("NexusFOVUpdater")
    end)
    
    local camera = Liquidation.Camera
    if camera then
        camera.FieldOfView = 70
    end
    
    if Movement.Objects.bodyVelocity then 
        Movement.Objects.bodyVelocity:Destroy()
        Movement.Objects.bodyVelocity = nil 
    end
    if Movement.Objects.bodyGyro then 
        Movement.Objects.bodyGyro:Destroy()
        Movement.Objects.bodyGyro = nil 
    end
    
    for key, connection in pairs(Movement.Connections) do
        Liquidation.safeDisconnect(connection)
    end
    Movement.Connections = {}
    
end

Movement.WalkSpeed = WalkSpeed;
Movement.NoClip = NoClip;
Movement.InfiniteLunge = InfiniteLunge;
Movement.Fly = {
    Enable = enableFly,
    Disable = disableFly,
    IsEnabled = function() return Movement.States.FlyEnabled end,
};
Movement.FreeCamera = {
    Enable = startFreeCamera,
    Disable = stopFreeCamera,
    IsEnabled = function() return Movement.States.FreeCameraEnabled end,
};
Movement.FOV = {
    SetEnabled = function(V) Movement.Settings.fovEnabled = V end,
    SetValue = function(V) Movement.Settings.fovValue = V end,
    IsEnabled = function() return Movement.Settings.fovEnabled end,
};

return Movement