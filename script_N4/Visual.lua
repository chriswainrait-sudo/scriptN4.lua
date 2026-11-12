--[[
    ──◦ rwque ◦──
]]

local Liquidation = _G.Liquidation

local Visual = {
    Connections = {},
    ESP = {
        lastUpdate = 0,
        UPDATE_INTERVAL = 0.2,
        settings = {
            Survivors  = {Enabled=false, Color=Color3.fromRGB(100,255,100), Colorpicker = nil},
            Killers    = {Enabled=false, Color=Color3.fromRGB(255,100,100), Colorpicker = nil},
            Generators = {Enabled=false, Color=Color3.fromRGB(100,170,255), Colorpicker = nil},
            Pallets    = {Enabled=false, Color=Color3.fromRGB(120,80,40), Colorpicker = nil},
            ExitGates  = {Enabled=false, Color=Color3.fromRGB(200,200,100), Colorpicker = nil},
            Windows    = {Enabled=false, Color=Color3.fromRGB(100,200,200), Colorpicker = nil},
            Hooks      = {Enabled=false, Color=Color3.fromRGB(100, 50, 150), Colorpicker = nil},
            Gifts      = {Enabled=false, Color=Color3.fromRGB(255, 182, 193), Colorpicker = nil}  -- Добавлен Gift ESP
        },
        trackedObjects = {},
        espConnections = {},
        espLoopRunning = false,
        showGeneratorPercent = true,
        autoFarmGiftEnabled = false,  
        autoFarmRunning = false,
        currentGiftIndex = 1
    },
    AdvancedESP = {
        settings = {
            enabled = false,
            name = true,
            distance = true,
            healthbar = true,
            box = true,
            boxType = "full",
            bones = true,
            boneColorName = "White",
            tracers = true,
            tracerColorName = "White",
            scale = 1.5,
            healthBarTopColorName = "DarkGreen",
            healthBarMidColorName = "DarkOrange",
            healthBarBottomColorName = "DarkRed",
            stateColorName = "Orange",
            boxOutline = true,
            boxOutlineColorName = "Black",
            boxOutlineThickness = 0.4,
            boxColorName = "White",
            boxFill = true,
            boxFillColorName = "White",
            boxFillTransparency = 0.9,
            healthBarLeftOffset = 10
        },
        colorMap = {
            Red = Color3.fromRGB(255,0,0),
            DarkRed = Color3.fromRGB(100,0,0),
            Green = Color3.fromRGB(0,255,0),
            DarkGreen = Color3.fromRGB(0,80,0),
            Blue = Color3.fromRGB(0,0,255),
            LightBlue = Color3.fromRGB(200,200,255),
            Yellow = Color3.fromRGB(255,255,0),
            Orange = Color3.fromRGB(255,165,0),
            DarkOrange = Color3.fromRGB(140,70,0),
            Purple = Color3.fromRGB(128,0,128),
            White = Color3.fromRGB(255,255,255),
            Black = Color3.fromRGB(0,0,0)
        },
        connections = {},
        espObjects = {},
        playerConnections = {}
    },
    Effects = {
        noShadowEnabled = false,
        noFogEnabled = false,
        fullbrightEnabled = false,
        timeChangerEnabled = false,
        originalFogEnd = nil,
        originalFogStart = nil,
        originalFogColor = nil,
        fogCache = nil,
        originalClockTime = nil        
    }
}

function Visual.GetGeneratorProgress(gen)
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

function Visual.EnsureHighlight(model, color, isObject)
    if not model then return end
    local hl = model:FindFirstChild("VD_HL")
    if not hl then
        hl = Instance.new("Highlight")
        hl.Name = "VD_HL"
        hl.Adornee = model
        hl.FillColor = color
        hl.FillTransparency = 0.8
        hl.OutlineColor = Color3.fromRGB(0,0,0)
        hl.OutlineTransparency = 0.1
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = model
    else
        hl.FillColor = color
        if isObject then
            hl.OutlineColor = Color3.fromRGB(0,0,0)
            hl.FillTransparency = 0.7
            hl.OutlineTransparency = 0.1
        else
            hl.OutlineColor = Color3.fromRGB(0,0,0)
            hl.FillTransparency = 0.7
            hl.OutlineTransparency = 0.1
        end
    end
end

function Visual.ClearHighlight(model)
    if model and model:FindFirstChild("VD_HL") then
        pcall(function() model.VD_HL:Destroy() end)
    end
end

function Visual.EnsureLabel(model, text, isGenerator, textColor)
    if not model then return end
    local lbl = model:FindFirstChild("VD_Label")
    if not lbl then
        lbl = Instance.new("BillboardGui")
        lbl.Name = "VD_Label"
        if isGenerator then
            lbl.Size = UDim2.new(0,100,0,25)
            lbl.StudsOffset = Vector3.new(0,2.5,0)
        else
            lbl.Size = UDim2.new(0,120,0,20)
            lbl.StudsOffset = Vector3.new(0,3,0)
        end
        lbl.AlwaysOnTop = true
        lbl.MaxDistance = 1000
        lbl.Parent = model
        
        local textLabel = Instance.new("TextLabel")
        textLabel.Name = "TextLabel"
        textLabel.Size = UDim2.new(1,0,1,0)
        textLabel.BackgroundTransparency = 1
        textLabel.TextScaled = false
        if isGenerator then
            textLabel.TextSize = 10
        else
            textLabel.TextSize = 10
        end
        textLabel.Font = Enum.Font.SourceSansBold
        textLabel.RichText = true
        textLabel.TextStrokeTransparency = 0.1
        textLabel.TextStrokeColor3 = Color3.fromRGB(0,0,0)
        textLabel.TextColor3 = textColor or Color3.fromRGB(255,255,255)
        textLabel.Text = text
        textLabel.Parent = lbl
    else
        local textLabel = lbl:FindFirstChild("TextLabel")
        if textLabel then
            textLabel.RichText = true
            textLabel.Text = text
            if isGenerator then
                textLabel.TextSize = 10
                lbl.StudsOffset = Vector3.new(0,2.5,0)
            else
                textLabel.TextSize = 10
                lbl.StudsOffset = Vector3.new(0,3,0)
            end
            textLabel.TextStrokeTransparency = 0.1
            textLabel.TextColor3 = textColor or Color3.fromRGB(255,255,255)
        end
    end
end

function Visual.ClearLabel(model)
    if model and model:FindFirstChild("VD_Label") then
        pcall(function() model.VD_Label:Destroy() end)
    end
end

function Visual.EnsureGeneratorESP(generator, progress, color)
    if not generator then return end
    
    local function getGeneratorColor(percent)
        if percent >= 0.999 then
            return Color3.fromRGB(100, 255, 100)
        elseif percent >= 0.5 then
            local factor = (percent - 0.5) * 2
            return Color3.fromRGB(255, 200 + 55 * factor, 100 - 100 * factor)
        else
            local factor = percent * 2
            return Color3.fromRGB(255 - 155 * factor, 100 - 100 * factor, 100 - 100 * factor)
        end
    end
    
    color = color or getGeneratorColor(progress)
    local percentText = Visual.ESP.showGeneratorPercent and string.format("%d%%", math.floor(progress * 100)) or ""
    
    local hl = generator:FindFirstChild("VD_HL")
    if not hl then
        hl = Instance.new("Highlight")
        hl.Name = "VD_HL"
        hl.Adornee = generator
        hl.FillColor = color
        hl.FillTransparency = 0.7
        hl.OutlineColor = Color3.fromRGB(0,0,0)
        hl.OutlineTransparency = 0.1
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = generator
    else
        hl.FillColor = color
        hl.OutlineColor = Color3.fromRGB(0,0,0)
        hl.FillTransparency = 0.7
        hl.OutlineTransparency = 0.1
    end
    
    if Visual.ESP.showGeneratorPercent then
        Visual.EnsureLabel(generator, percentText, true, color)
    else
        Visual.ClearLabel(generator)
    end
end

function Visual.GetRole(targetPlayer)
    if targetPlayer.Team and targetPlayer.Team.Name then
        local n = targetPlayer.Team.Name:lower()
        if n:find("killer") then return "Killer" end
        if n:find("survivor") then return "Survivor" end
    end
    return "Survivor"
end

--  GIFT ESP --

function Visual.IsValidGift(obj)
    if obj.Name:lower():find("gift") then
        for _, child in ipairs(obj:GetDescendants()) do
            if child:IsA("SurfaceAppearance") then
                return true
            end
        end
    end
    return false
end

function Visual.GetAllGifts()
    local gifts = {}
    for obj, typeName in pairs(Visual.ESP.trackedObjects) do
        if obj and obj.Parent and typeName == "Gifts" and Visual.IsValidGift(obj) then
            table.insert(gifts, obj)
        end
    end
    return gifts
end

function Visual.FindChristmasTree()
    local map = Liquidation.Services.Workspace:FindFirstChild("Map")
    if not map then return nil end
    
    local christmasTree = map:FindFirstChild("chris")
    if christmasTree then
        christmasTree = christmasTree:FindFirstChild("chrismta tute")
        if christmasTree then
            christmasTree = christmasTree:FindFirstChild("Model")
            if christmasTree then
                christmasTree = christmasTree:FindFirstChild("ChristmasTree")
                if christmasTree then
                    local treePine = christmasTree:FindFirstChild("TreePine")
                    if treePine then
                        return treePine
                    end
                end
            end
        end
    end
    
    for _, obj in ipairs(Liquidation.Services.Workspace:GetDescendants()) do
        if obj.Name == "TreePine" then
            return obj
        end
    end
    
    return nil
end

function Visual.TeleportToObject(obj)
    local localPlayer = Liquidation.Player
    if not localPlayer or not localPlayer.Character then
        return false
    end
    
    local humanoid = localPlayer.Character:FindFirstChild("Humanoid")
    local rootPart = localPlayer.Character:FindFirstChild("HumanoidRootPart")
    
    if not humanoid or not rootPart then
        return false
    end
    
    if obj then
        local targetPosition
        if obj:IsA("BasePart") then
            targetPosition = obj.Position + Vector3.new(0, 3, 0)
        elseif obj:IsA("Model") and obj.PrimaryPart then
            targetPosition = obj.PrimaryPart.Position + Vector3.new(0, 3, 0)
        else
            targetPosition = obj.Position + Vector3.new(0, 3, 0)
        end
        
        local success = pcall(function()
            rootPart.CFrame = CFrame.new(targetPosition)
        end)
        
        return success
    end
    
    return false
end

function Visual.SimulateMouseClick()
    local virtualInputManager = game:GetService("VirtualInputManager")
    if virtualInputManager then
        pcall(function()
            virtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
            task.wait(0.1)
            virtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
        end)
    end
end

function Visual.AutoFarmGiftLoop()
    if Visual.ESP.autoFarmRunning then
        return
    end
    
    Visual.ESP.autoFarmRunning = true
    Visual.ESP.currentGiftIndex = 1
    
    task.spawn(function()
        while Visual.ESP.autoFarmGiftEnabled do
            local gifts = Visual.GetAllGifts()
            
            if #gifts > 0 then
                if Visual.ESP.currentGiftIndex > #gifts then
                    Visual.ESP.currentGiftIndex = 1
                end
                
                local currentGift = gifts[Visual.ESP.currentGiftIndex]
                
                if currentGift and currentGift.Parent and Visual.IsValidGift(currentGift) then
                    Visual.TeleportToObject(currentGift)
                    task.wait(0.5)
                    
                    Visual.SimulateMouseClick()
                    task.wait(3)
                    
                    local christmasTree = Visual.FindChristmasTree()
                    if christmasTree then
                        Visual.TeleportToObject(christmasTree)
                        task.wait(3)
                    else
                        task.wait(3)
                    end
                    
                    Visual.ESP.currentGiftIndex = Visual.ESP.currentGiftIndex + 1
                else
                    Visual.ESP.currentGiftIndex = Visual.ESP.currentGiftIndex + 1
                end
            else
                task.wait(2)
            end
            
            task.wait(0.5)
        end
        
        Visual.ESP.autoFarmRunning = false
    end)
end

function Visual.ToggleAutoFarmGift(enabled)
    Visual.ESP.autoFarmGiftEnabled = enabled
    
    if enabled then
        Visual.AutoFarmGiftLoop()
    else
        Visual.ESP.autoFarmRunning = false
    end
end

function Visual.AddObjectToTrack(obj)
    local nameLower = obj.Name:lower()
    
    if nameLower:find("generator") then 
        Visual.ESP.trackedObjects[obj] = "Generators"
    elseif nameLower:find("pallet") then
        
        if Visual.IsValidPallet(obj) then
            Visual.ESP.trackedObjects[obj] = "Pallets"
        end
    elseif nameLower:find("gate") then 
        Visual.ESP.trackedObjects[obj] = "ExitGates"
    elseif nameLower:find("window") then 
        Visual.ESP.trackedObjects[obj] = "Windows"
    elseif nameLower:find("hook") then 
        Visual.ESP.trackedObjects[obj] = "Hooks"
    elseif nameLower:find("gift") then
        if Visual.IsValidGift(obj) then
            Visual.ESP.trackedObjects[obj] = "Gifts"
        end
    end
end

function Visual.IsValidPallet(obj)
    if obj.Name:lower():find("palletpoint") then
        return true
    end
    
    for _, child in ipairs(obj:GetChildren()) do
        if child.Name:lower():find("palletpoint") then
            return true
        end
    end
    
    if obj:IsA("Model") and obj.PrimaryPart then
        local primaryName = obj.PrimaryPart.Name:lower()
        if primaryName:find("palletpoint") or primaryName:find("pallet") then
            return true
        end
    end
    
    return false
end

function Visual.TrackObjects()
    Visual.ESP.trackedObjects = {}
    
    for _, obj in ipairs(Liquidation.Services.Workspace:GetDescendants()) do
        if obj:IsA("Model") then
            Visual.AddObjectToTrack(obj)
        end
    end
    
    Visual.ESP.espConnections.descendantAdded = Liquidation.Services.Workspace.DescendantAdded:Connect(function(obj)
        if obj:IsA("Model") then
            Visual.AddObjectToTrack(obj)
        end
    end)
end

function Visual.UpdateESP(force)
    local currentTime = tick()
    if not force and currentTime - Visual.ESP.lastUpdate < Visual.ESP.UPDATE_INTERVAL then return end
    Visual.ESP.lastUpdate = currentTime
    
    -- Update players
    for _, targetPlayer in ipairs(Liquidation.Services.Players:GetPlayers()) do
        if targetPlayer ~= Liquidation.Player and targetPlayer.Character then
            local hrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local role = Visual.GetRole(targetPlayer)
                local setting = (role == "Killer") and Visual.ESP.settings.Killers or Visual.ESP.settings.Survivors
                
                if setting and setting.Enabled then
                    Visual.EnsureHighlight(targetPlayer.Character, setting.Color, false)
                else
                    Visual.ClearHighlight(targetPlayer.Character)
                    Visual.ClearLabel(targetPlayer.Character)
                end
            end
        end
    end
    
    -- Update objects
    for obj, typeName in pairs(Visual.ESP.trackedObjects) do
        if obj and obj.Parent then
            local setting = Visual.ESP.settings[typeName]
            if setting and setting.Enabled then
                if typeName == "Generators" then
                    local progress = Visual.GetGeneratorProgress(obj)
                    Visual.EnsureGeneratorESP(obj, progress, setting.Color)
                else
                    Visual.EnsureHighlight(obj, setting.Color, true)
                    Visual.ClearLabel(obj)
                end
            else
                Visual.ClearHighlight(obj)
                Visual.ClearLabel(obj)
            end
        end
    end
end

function Visual.StartESPLoop()
    Visual.ESP.espConnections.mainLoop = task.spawn(function()
        while Visual.ESP.espLoopRunning do
            Visual.UpdateESP()
            task.wait(Visual.ESP.UPDATE_INTERVAL)
        end
    end)
end

function Visual.StartESP()
    if Visual.ESP.espLoopRunning then return end
    Visual.ESP.espLoopRunning = true
    
    Visual.TrackObjects()
    Visual.StartESPLoop()
end

function Visual.StopESP()
    Visual.ESP.espLoopRunning = false
    
    Visual.ClearAllESP()
    
    for _, connection in pairs(Visual.ESP.espConnections) do
        Liquidation.safeDisconnect(connection)
    end
    Visual.ESP.espConnections = {}
end

function Visual.ClearAllESP()
    for _, targetPlayer in ipairs(Liquidation.Services.Players:GetPlayers()) do
        if targetPlayer.Character then
            Visual.ClearHighlight(targetPlayer.Character)
            Visual.ClearLabel(targetPlayer.Character)
        end
    end
    
    for obj, _ in pairs(Visual.ESP.trackedObjects) do
        if obj and obj.Parent then
            Visual.ClearHighlight(obj)
            Visual.ClearLabel(obj)
        end
    end
end

function Visual.ToggleESPSetting(settingName, enabled)
    if Visual.ESP.settings[settingName] then
        Visual.ESP.settings[settingName].Enabled = enabled
        
        local anyEnabled = false
        for _, setting in pairs(Visual.ESP.settings) do
            if setting.Enabled then
                anyEnabled = true
                break
            end
        end
        
        if anyEnabled and not Visual.ESP.espLoopRunning then
            Visual.StartESP()
        elseif not anyEnabled and Visual.ESP.espLoopRunning then
            Visual.StopESP()
        end
    end
end

function Visual.SetESPColor(settingName, color)
    local setting = Visual.ESP.settings[settingName]
    if setting and typeof(color) == "Color3" then
        setting.Color = color
        Visual.UpdateESPColors()
    end
end

function Visual.UpdateESPColors()
    if Visual.ESP.espLoopRunning then
        Visual.UpdateESP(true)
    end
end

function Visual.UpdateESPDisplay()
    if Visual.ESP.espLoopRunning then
        Visual.UpdateESP(true)
    end
end

function Visual.ToggleAdvancedESP(enabled)
    Visual.AdvancedESP.settings.enabled = enabled
    
    if enabled then
        Visual.StartAdvancedESP()
    else
        Visual.StopAdvancedESP()
    end
end

function Visual.HideAdvancedESP(plr)
    local d = Visual.AdvancedESP.espObjects[plr]
    if d then
        
        local drawingObjects = {
            d.BoxFill, d.Name, d.Distance, d.Tracer, d.HealthBg, 
            d.HealthBar, d.HealthMask, d.HealthText, d.Box, d.BoxOutline
        }
        
        for _, obj in ipairs(drawingObjects) do
            if obj then
                pcall(function() 
                    obj.Visible = false 
                end)
            end
        end
        
        for i = 1, 24 do
            if d["HealthStripe"..i] then
                pcall(function() 
                    d["HealthStripe"..i].Visible = false 
                end)
            end
        end
        
        if d.Bones then
            for _, bone in ipairs(d.Bones) do
                if bone then
                    pcall(function() 
                        bone.Visible = false 
                    end)
                end
            end
        end
    end
end

function Visual.CreateAdvancedESP(plr)
    if Visual.AdvancedESP.espObjects[plr] then
        Visual.HideAdvancedESP(plr)
        return Visual.AdvancedESP.espObjects[plr]
    end
    
    local settings = Visual.AdvancedESP.settings
    local colorMap = Visual.AdvancedESP.colorMap
    
    local boneColor = colorMap[settings.boneColorName] or colorMap.White
    local tracerColor = colorMap[settings.tracerColorName] or colorMap.White
    local boxColor = colorMap[settings.boxColorName] or colorMap.White
    local boxOutlineColor = colorMap[settings.boxOutlineColorName] or colorMap.Black
    local boxFillColor = colorMap[settings.boxFillColorName] or colorMap.White
    
    local function create(tp, props)
        local o = Drawing.new(tp)
        for i,v in pairs(props) do o[i]=v end
        return o
    end
    
    local d = {
        Bones = {},
        BoxFill = nil,
        Name = nil,
        Distance = nil,
        Tracer = nil,
        HealthBg = nil,
        HealthBar = nil,
        HealthMask = nil,
        HealthText = nil,
        Box = nil,
        BoxOutline = nil
    }
    
    d.BoxFill = create("Square",{
        Thickness = 0,
        Color = boxFillColor,
        Visible = false,
        Filled = true,
        Transparency = 1 - (settings.boxFillTransparency or 0.9)
    })
    
    d.Name = create("Text",{
        Size = 10,
        Center = true,
        Outline = true,
        Color = Color3.new(1,1,1),
        Visible = false
    })
    
    d.Distance = create("Text",{
        Size = 10,
        Center = true,
        Outline = true,
        Color = Color3.new(0.8,0.8,0.8),
        Visible = false
    })
    
    d.Tracer = create("Line",{
        Thickness = 1.5,
        Color = tracerColor,
        Visible = false
    })
    
    d.HealthBg = Drawing.new("Square")
    d.HealthBg.Visible = false
    d.HealthBg.Filled = true
    d.HealthBg.Color = Color3.new(0,0,0)
    d.HealthBg.Transparency = 1
    
    d.HealthBar = Drawing.new("Square")
    d.HealthBar.Visible = false
    d.HealthBar.Filled = true
    d.HealthBar.Transparency = 1
    
    d.HealthMask = Drawing.new("Square")
    d.HealthMask.Visible = false
    d.HealthMask.Filled = true
    d.HealthMask.Color = Color3.new(0,0,0)
    d.HealthMask.Transparency = 0.3
    
    d.HealthText = create("Text",{
        Size = 9,
        Center = true,
        Outline = true,
        Color = Color3.new(1,1,1),
        Visible = false
    })
    
    d.Box = create("Square", {
        Thickness = 1.7,
        Color = boxColor,
        Visible = false,
        Filled = false
    })
    
    d.BoxOutline = create("Square", {
        Thickness = 1.7 + (settings.boxOutlineThickness or 0.4) * 2,
        Color = boxOutlineColor,
        Visible = false,
        Filled = false
    })
    
    for i = 1, 14 do
        d.Bones[i] = create("Line", {
            Thickness = 1.5,
            Color = boneColor,
            Visible = false
        })
    end
    
    for i = 1, 24 do
        d["HealthStripe"..i] = Drawing.new("Square")
        d["HealthStripe"..i].Visible = false
        d["HealthStripe"..i].Filled = true
        d["HealthStripe"..i].Transparency = 1
    end
    
    Visual.AdvancedESP.espObjects[plr] = d
    
    if not Visual.AdvancedESP.playerConnections[plr] then
        Visual.AdvancedESP.playerConnections[plr] = {}
    end
    
    return d
end

function Visual.SetupPlayerAdvancedESP(plr)
    if plr == Liquidation.Player then return end
    
    Visual.CreateAdvancedESP(plr)
    
    local function handleCharacterChanged()
     
        Visual.HideAdvancedESP(plr)
    end
    
    local charAddedConnection = plr.CharacterAdded:Connect(handleCharacterChanged)
    
    local charRemovingConnection = plr.CharacterRemoving:Connect(function()
        Visual.HideAdvancedESP(plr)
    end)
    
    local ancestryChangedConnection = plr.AncestryChanged:Connect(function(_, parent)
        if not parent then
            Visual.HideAdvancedESP(plr)
            if Visual.AdvancedESP.playerConnections[plr] then
                for _, conn in pairs(Visual.AdvancedESP.playerConnections[plr]) do
                    pcall(function() conn:Disconnect() end)
                end
                Visual.AdvancedESP.playerConnections[plr] = nil
            end
        end
    end)
    
    Visual.AdvancedESP.playerConnections[plr] = {
        charAdded = charAddedConnection,
        charRemoving = charRemovingConnection,
        ancestryChanged = ancestryChangedConnection
    }
    
    if plr.Character then
        task.spawn(function()
            wait(0.5)
            if not Visual.AdvancedESP.espObjects[plr] then
                Visual.CreateAdvancedESP(plr)
            end
        end)
    end
end

function Visual.GetHealthGradientColor(y, h)
    local settings = Visual.AdvancedESP.settings
    local colorMap = Visual.AdvancedESP.colorMap
    
    local t = 1 - (y / math.max(h, 1))
    if t >= 0.5 then
        local s = (t - 0.5) * 2
        local midColor = colorMap[settings.healthBarMidColorName] or colorMap.DarkOrange
        local topColor = colorMap[settings.healthBarTopColorName] or colorMap.DarkGreen
        return midColor:Lerp(topColor, s)
    else
        local s = t * 2
        local bottomColor = colorMap[settings.healthBarBottomColorName] or colorMap.DarkRed
        local midColor = colorMap[settings.healthBarMidColorName] or colorMap.DarkOrange
        return bottomColor:Lerp(midColor, s)
    end
end

function Visual.IsR6(char)
    return char:FindFirstChild("Torso") and not char:FindFirstChild("UpperTorso")
end

function Visual.UpdateAdvancedESP()
    local settings = Visual.AdvancedESP.settings
    if not settings.enabled then return end
    
    local Camera = Liquidation.Camera
    local camPos = Camera.CFrame.Position
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
    
    for plr, d in pairs(Visual.AdvancedESP.espObjects) do
        if not plr or not plr.Parent then
            Visual.HideAdvancedESP(plr)
            continue
        end
        
        local char = plr.Character
        if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Head") and char:FindFirstChildOfClass("Humanoid") then
            local hum = char:FindFirstChildOfClass("Humanoid")
            
            if hum and hum.Health <= 0 then
             
                Visual.HideAdvancedESP(plr)
                continue
            end
            
            local root = char.HumanoidRootPart
            local head = char.Head

            local function screenPosOrNil(part)
                if part then
                    local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
                    if onScreen and pos.Z > 0 then 
                        return Vector2.new(pos.X, pos.Y) 
                    end
                end
                return nil
            end

            local headPos, onScreen = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
            local footPos = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 2.5, 0))

            if onScreen then
                local rawHeight = footPos.Y - headPos.Y
                local height = rawHeight * settings.scale
                local width = (height / 2) * settings.scale
                local x = headPos.X - width / 2
                local y = headPos.Y - (height - rawHeight) / 2

                if d.BoxFill then
                    d.BoxFill.Position = Vector2.new(x, y)
                    d.BoxFill.Size = Vector2.new(width, height)
                    d.BoxFill.Color = Visual.AdvancedESP.colorMap[settings.boxFillColorName] or Visual.AdvancedESP.colorMap.White
                    d.BoxFill.Filled = true
                    d.BoxFill.Transparency = 1 - (settings.boxFillTransparency or 0.9)
                    d.BoxFill.Visible = settings.boxFill and settings.enabled
                end

                if d.Box then
                    d.Box.Position = Vector2.new(x, y)
                    d.Box.Size = Vector2.new(width, height)
                    d.Box.Color = Visual.AdvancedESP.colorMap[settings.boxColorName] or Visual.AdvancedESP.colorMap.White
                    d.Box.Thickness = 1.7
                    d.Box.Visible = settings.box and settings.enabled
                end
                
                if d.BoxOutline then
                    local thickness = settings.boxOutlineThickness or 0.4
                    d.BoxOutline.Position = Vector2.new(x - thickness, y - thickness)
                    d.BoxOutline.Size = Vector2.new(width + thickness * 2, height + thickness * 2)
                    d.BoxOutline.Color = Visual.AdvancedESP.colorMap[settings.boxOutlineColorName] or Visual.AdvancedESP.colorMap.Black
                    d.BoxOutline.Thickness = thickness
                    d.BoxOutline.Visible = settings.box and settings.boxOutline and settings.enabled
                end

                if d.Name then
                    d.Name.Text = plr.Name
                    d.Name.Size = 9.5
                    d.Name.Position = Vector2.new(headPos.X, y - 22)
                    d.Name.Visible = settings.name and settings.enabled
                end

                if d.Distance then
                    local dist = math.floor((root.Position - camPos).Magnitude)
                    d.Distance.Text = dist .. "m"
                    d.Distance.Size = 9.5
                    d.Distance.Position = Vector2.new(headPos.X, y + height + 6)
                    d.Distance.Visible = settings.distance and settings.enabled
                end

                if d.HealthBg and d.HealthBar and d.HealthText then
                    local barX = x - (settings.healthBarLeftOffset or 10)
                    local barY = y
                    local barWidth = 6
                    local barHeight = height
                    
                    d.HealthBg.Position = Vector2.new(barX, barY)
                    d.HealthBg.Size = Vector2.new(barWidth, barHeight)
                    d.HealthBg.Visible = settings.healthbar and settings.enabled
                    
                    if settings.healthbar and settings.enabled then
                        local HEALTH_STRIPES = 24
                        local hpPerc = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                        
                        for i = 1, HEALTH_STRIPES do
                            local stripe = d["HealthStripe"..i]
                            if stripe then
                                local stripeY = barY + barHeight * (i - 1) / HEALTH_STRIPES
                                local stripeH = barHeight / HEALTH_STRIPES
                                local stripeColor = Visual.GetHealthGradientColor(stripeY - barY, barHeight)
                                
                                stripe.Color = stripeColor
                                stripe.Position = Vector2.new(barX, stripeY)
                                stripe.Size = Vector2.new(barWidth, stripeH)
                                stripe.Visible = (i - 1) / HEALTH_STRIPES < hpPerc
                            end
                        end
                        
                        d.HealthText.Text = tostring(math.floor(hum.Health))
                        d.HealthText.Size = 14
                        d.HealthText.Position = Vector2.new(x - (settings.healthBarLeftOffset or 10) - 14, y + height / 2)
                        d.HealthText.Visible = true
                    else
                        for i = 1, 24 do
                            if d["HealthStripe"..i] then
                                d["HealthStripe"..i].Visible = false
                            end
                        end
                        d.HealthText.Visible = false
                    end
                end

                if d.Bones then
                    local bonesVisible = settings.bones and settings.enabled
                    local bones
                    
                    if Visual.IsR6(char) then
                        bones = {
                            {char:FindFirstChild("Head"), char:FindFirstChild("Torso")},
                            {char:FindFirstChild("Torso"), char:FindFirstChild("Left Arm")},
                            {char:FindFirstChild("Left Arm"), char:FindFirstChild("Left Leg")},
                            {char:FindFirstChild("Torso"), char:FindFirstChild("Right Arm")},
                            {char:FindFirstChild("Right Arm"), char:FindFirstChild("Right Leg")},
                            {char:FindFirstChild("Torso"), char:FindFirstChild("Left Leg")},
                            {char:FindFirstChild("Torso"), char:FindFirstChild("Right Leg")}
                        }
                    else
                        bones = {
                            {char:FindFirstChild("Head"), char:FindFirstChild("Neck")},
                            {char:FindFirstChild("Neck"), char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")},
                            {char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso"), char:FindFirstChild("LeftUpperArm") or char:FindFirstChild("Left Arm")},
                            {char:FindFirstChild("LeftUpperArm") or char:FindFirstChild("Left Arm"), char:FindFirstChild("LeftLowerArm") or char:FindFirstChild("Left Forearm")},
                            {char:FindFirstChild("LeftLowerArm") or char:FindFirstChild("Left Forearm"), char:FindFirstChild("LeftHand") or char:FindFirstChild("Left hand")},
                            {char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso"), char:FindFirstChild("RightUpperArm") or char:FindFirstChild("Right Arm")},
                            {char:FindFirstChild("RightUpperArm") or char:FindFirstChild("Right Arm"), char:FindFirstChild("RightLowerArm") or char:FindFirstChild("Right Forearm")},
                            {char:FindFirstChild("RightLowerArm") or char:FindFirstChild("Right Forearm"), char:FindFirstChild("RightHand") or char:FindFirstChild("Right hand")},
                            {char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso"), char:FindFirstChild("LeftUpperLeg") or char:FindFirstChild("Left Leg")},
                            {char:FindFirstChild("LeftUpperLeg") or char:FindFirstChild("Left Leg"), char:FindFirstChild("LeftLowerLeg") or char:FindFirstChild("Left Shin")},
                            {char:FindFirstChild("LeftLowerLeg") or char:FindFirstChild("Left Shin"), char:FindFirstChild("LeftFoot") or char:FindFirstChild("Left foot")},
                            {char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso"), char:FindFirstChild("RightUpperLeg") or char:FindFirstChild("Right Leg")},
                            {char:FindFirstChild("RightUpperLeg") or char:FindFirstChild("Right Leg"), char:FindFirstChild("RightLowerLeg") or char:FindFirstChild("Right Shin")},
                            {char:FindFirstChild("RightLowerLeg") or char:FindFirstChild("Right Shin"), char:FindFirstChild("RightFoot") or char:FindFirstChild("Right foot")}
                        }
                    end
                    
                    for i = 1, 14 do
                        local line = d.Bones[i]
                        if line and bones[i] and bones[i][1] and bones[i][2] then
                            local p1 = screenPosOrNil(bones[i][1])
                            local p2 = screenPosOrNil(bones[i][2])
                            if p1 and p2 then
                                line.From = p1
                                line.To = p2
                                line.Color = Visual.AdvancedESP.colorMap[settings.boneColorName] or Visual.AdvancedESP.colorMap.White
                                line.Visible = bonesVisible
                            else
                                line.Visible = false
                            end
                        elseif line then
                            line.Visible = false
                        end
                    end
                end

                if d.Tracer then
                    local rootPos2D = Vector2.new(headPos.X, headPos.Y)
                    d.Tracer.From = screenCenter
                    d.Tracer.To = rootPos2D
                    d.Tracer.Color = Visual.AdvancedESP.colorMap[settings.tracerColorName] or Visual.AdvancedESP.colorMap.White
                    d.Tracer.Visible = settings.tracers and settings.enabled
                end
            else
                Visual.HideAdvancedESP(plr)
            end
        else
            Visual.HideAdvancedESP(plr)
        end
    end
end

function Visual.StartAdvancedESP()
    if Visual.AdvancedESP.connections.renderStepped then
        Visual.AdvancedESP.connections.renderStepped:Disconnect()
        Visual.AdvancedESP.connections.renderStepped = nil
    end
    
    Visual.AdvancedESP.connections.playerAdded = Liquidation.Services.Players.PlayerAdded:Connect(function(plr)
        if plr ~= Liquidation.Player then
            Visual.SetupPlayerAdvancedESP(plr)
        end
    end)
    
    Visual.AdvancedESP.connections.playerRemoving = Liquidation.Services.Players.PlayerRemoving:Connect(function(plr)
        Visual.HideAdvancedESP(plr)
        if Visual.AdvancedESP.playerConnections[plr] then
            for _, conn in pairs(Visual.AdvancedESP.playerConnections[plr]) do
                pcall(function() conn:Disconnect() end)
            end
            Visual.AdvancedESP.playerConnections[plr] = nil
        end
    end)
    
    for _, plr in pairs(Liquidation.Services.Players:GetPlayers()) do
        if plr ~= Liquidation.Player then
            Visual.SetupPlayerAdvancedESP(plr)
        end
    end
    
    Visual.AdvancedESP.connections.renderStepped = Liquidation.Services.RunService.RenderStepped:Connect(function()
        Visual.UpdateAdvancedESP()
    end)
end

function Visual.StopAdvancedESP()
    for _, connection in pairs(Visual.AdvancedESP.connections) do
        pcall(function() connection:Disconnect() end)
    end
    Visual.AdvancedESP.connections = {}
    
    for plr, _ in pairs(Visual.AdvancedESP.espObjects) do
        Visual.HideAdvancedESP(plr)
    end
    
    for plr, connections in pairs(Visual.AdvancedESP.playerConnections) do
        for _, conn in pairs(connections) do
            pcall(function() conn:Disconnect() end)
        end
    end
    Visual.AdvancedESP.playerConnections = {}
end

function Visual.ToggleNoShadow(enabled)
    Visual.Effects.noShadowEnabled = enabled
    if enabled then
        for _, light in ipairs(Liquidation.Services.Lighting:GetDescendants()) do 
            if light:IsA("Light") then 
                light.Shadows = false 
            end 
        end
        Liquidation.Services.Lighting.GlobalShadows = false
    else
        for _, light in ipairs(Liquidation.Services.Lighting:GetDescendants()) do 
            if light:IsA("Light") then 
                light.Shadows = true 
            end 
        end
        Liquidation.Services.Lighting.GlobalShadows = true
    end
end

function Visual.ToggleNoFog(enabled)
    Visual.Effects.noFogEnabled = enabled
    
    if enabled then
        pcall(function()
            local lighting = Liquidation.Services.Lighting
            
            for _, effect in ipairs(lighting:GetChildren()) do
                if effect:IsA("Atmosphere") or 
                   effect.Name:lower():find("fog") or 
                   effect.Name:lower():find("bloom") or
                   effect.Name:lower():find("blur") or
                   effect.Name:lower():find("color") then
                    effect:Destroy()
                end
            end
            
            local map = Liquidation.Services.Workspace:FindFirstChild("Map")
            if map then
                for _, obj in ipairs(map:GetDescendants()) do
                    if obj:IsA("Atmosphere") or 
                       obj:IsA("BloomEffect") or 
                       obj:IsA("BlurEffect") or 
                       obj:IsA("ColorCorrectionEffect") or
                       obj.Name:lower():find("fog") then
                        obj:Destroy()
                    end
                end
            end
            
            lighting.FogEnd = 10000000
            lighting.FogStart = 0
            lighting.FogDensity = 0
            lighting.GlobalShadows = true
            
            if Visual.ESP.espConnections.noFog then
                Visual.ESP.espConnections.noFog:Disconnect()
            end
            
            Visual.ESP.espConnections.noFog = Liquidation.Services.RunService.Heartbeat:Connect(function()
                if Visual.Effects.noFogEnabled then
                    lighting.FogEnd = 10000000
                    lighting.FogStart = 0
                    lighting.FogDensity = 0
                end
            end)
        end)
    else
        if Visual.ESP.espConnections.noFog then
            Visual.ESP.espConnections.noFog:Disconnect()
            Visual.ESP.espConnections.noFog = nil
        end
    end
end

function Visual.ToggleFullBright(enabled)
    Visual.Effects.fullbrightEnabled = enabled
    Liquidation.States.fullbrightEnabled = enabled
    
    if enabled then
        Liquidation.Services.Lighting.GlobalShadows = false
        Liquidation.Services.Lighting.FogEnd = 100000
        Liquidation.Services.Lighting.Brightness = 2
        Liquidation.Services.Lighting.ClockTime = 14
    else
        Liquidation.Services.Lighting.GlobalShadows = true
        Liquidation.Services.Lighting.FogEnd = 1000
        Liquidation.Services.Lighting.Brightness = 1
    end
end

function Visual.ToggleTimeChanger(enabled)
    Visual.Effects.timeChangerEnabled = enabled

    if enabled then
        if not Visual.Effects.originalClockTime then
            Visual.Effects.originalClockTime = Liquidation.Services.Lighting.ClockTime;
        end;
        Liquidation.Services.Lighting.ClockTime = Visual.Effects.currentTimeValue or 14;
    else
        if Visual.Effects.originalClockTime then
            Liquidation.Services.Lighting.ClockTime = Visual.Effects.originalClockTime;
        end;
    end;
end;

function Visual.SetTime(TimeVal)
    Visual.Effects.currentTimeValue = TimeVal;
    if Visual.Effects.timeChangerEnabled then
        Liquidation.Services.Lighting.ClockTime = TimeVal;
    end;
end;

--// Exports //--
Visual.Effects.currentTimeValue = 14;

return Visual;
