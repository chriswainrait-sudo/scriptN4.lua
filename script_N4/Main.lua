local loadModule = ...
--[[
    ──◦ rwque ◦──
]]



--// Services //--
local Players = game:GetService("Players");
local RunService = game:GetService("RunService");
local UserInputService = game:GetService("UserInputService");
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local VirtualInputManager = game:GetService("VirtualInputManager");

--// Constants //--
local Player = Players.LocalPlayer;
local Camera = workspace.CurrentCamera;
local IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled;

--// Liquidation Setup (replicado do Main.lua original) //--
_G.Liquidation = {
    Player = Player,
    Camera = Camera,
    IS_MOBILE = IsMobile,
    IS_DESKTOP = not IsMobile,
    Services = {
        Players = Players,
        RunService = RunService,
        UserInputService = UserInputService,
        ReplicatedStorage = ReplicatedStorage,
        VirtualInputManager = VirtualInputManager,
        Workspace = workspace,
        Lighting = game:GetService("Lighting"),
        TweenService = game:GetService("TweenService"),
    },
    States = {
        NoSlowdownEnabled = false,
        AutoParryEnabled = false,
        AutoParryV2Enabled = false,
        NoFallEnabled = false,
        NoHitboxEnabled = false,
        CrosshairEnabled = false,
        RainbowCrosshairEnabled = false,
        TwistSilentAimEnabled = false,
        FastVaultEnabled = false,
        GateToolEnabled = false,
        FakeParryEnabled = false,
        AutoVictoryEnabled = false,
        AutoVictoryV2Enabled = false,
        InstantHealRunning = false,
        SilentHealRunning = false,
        autoHealEnabled = false,
        autoSkillEnabled = false,
        SpeedVaultEnabled = false,
        SpeedHackAttrEnabled = false,
        VaultDistanceEnabled = false,
        HealBoostEnabled = false,
        RepairBoostEnabled = false,
        BleedBoostEnabled = false,
        ParryCircleEnabled = false,
    },
    Connections = {},
    Modules = {},
};

_G.Liquidation.getCharacter = function()
    return Player.Character;
end;

_G.Liquidation.getHumanoid = function()
    local Char = Player.Character;
    return Char and Char:FindFirstChildOfClass("Humanoid");
end;

_G.Liquidation.getRootPart = function()
    local Char = Player.Character;
    return Char and Char:FindFirstChild("HumanoidRootPart");
end;

_G.Liquidation.SafeCallback = function(Callback, ...)
    if type(Callback) == "function" then
        local Ok, Err = pcall(Callback, ...);
        if not Ok then warn("[Liquidation] Callback error:", Err) end;
        return Ok;
    end;
    return false;
end;

_G.Liquidation.safeDisconnect = function(Conn)
    if Conn and typeof(Conn) == "RBXScriptConnection" then
        pcall(function() Conn:Disconnect() end);
    elseif type(Conn) == "thread" then
        pcall(function() task.cancel(Conn) end);
    end;
end;

local Liquidation = _G.Liquidation;

--// Action Keybinds //--
local ActionKeybinds = {};

Liquidation.Connections.ActionKeybinds = UserInputService.InputBegan:Connect(function(Input, GameProcessed)
    if GameProcessed then return end;
    if Input.UserInputType ~= Enum.UserInputType.Keyboard then return end;
    for _, Entry in ipairs(ActionKeybinds) do
        if Entry.Key and Input.KeyCode == Entry.Key then
            Entry.Action();
        end;
    end;
end);

local function RegisterActionKeybind(Action)
    local Entry = {Key = nil, Action = Action};
    table.insert(ActionKeybinds, Entry);
    return function(Key) Entry.Key = Key; end;
end;

--// LiquidationLib //--
local LiquidationLib = loadModule("UI");

local Window = LiquidationLib:CreateWindow({
    Title = `Liquidation`,
    Subtitle = `Survivor`,
    KeyBind = Enum.KeyCode.RightControl,
});

--// Survivor Module //--
local SurvivorModule = loadModule("Survivor");

--// Killer Module //--
local KillerModule = loadModule("Killer");

--// Movement Module //--
local MovementModule = loadModule("Movement");

--// Fun Module //--
local FunModule = loadModule("Fun");

--// Visual Module //--
local VisualModule = loadModule("Visual");

--// ═══════════════════════════════ //--
--//        SURVIVOR TAB            //--
--// ═══════════════════════════════ //--

local SurvivorTab = Window:CreateTab({
    Name = `Survivor`,
    Icon = `user`,
});

--// ── Combat ── //--
local CombatGroup = SurvivorTab:CreateGroup({
    Name = `Combat`,
    Icon = `crosshair`,
    Column = `Left`,
});

CombatGroup:CreateSeparator({Text = `Auto Parry`});

CombatGroup:CreateToggle({
    Name = `Auto Parry`,
    Default = false,
    Callback = function(Value)
        if Value then SurvivorModule.AutoParry.Enable() else SurvivorModule.AutoParry.Disable() end;
    end,
});

CombatGroup:CreateSlider({
    Name = `Parry Range`,
    Min = 0,
    Max = 20,
    Default = 10,
    Suffix = ` st`,
    Callback = function(Value)
        SurvivorModule.AutoParry.SetRange(Value);
    end,
});

CombatGroup:CreateToggle({
    Name = `Visual Parry Range`,
    Default = false,
    Callback = function(Value)
        if Value then SurvivorModule.ParryCircleVisual.Enable() else SurvivorModule.ParryCircleVisual.Disable() end;
    end,
});

CombatGroup:CreateSeparator({Text = `Auto Parry V2`});

CombatGroup:CreateToggle({
    Name = `Auto Parry V2`,
    Default = false,
    Callback = function(Value)
        if Value then SurvivorModule.AutoParryV2.Enable() else SurvivorModule.AutoParryV2.Disable() end;
    end,
});

CombatGroup:CreateSlider({
    Name = `Parry V2 Range`,
    Min = 0,
    Max = 30,
    Default = 20,
    Suffix = ` st`,
    Callback = function(Value)
        SurvivorModule.AutoParryV2.SetRadius(Value);
    end,
});

CombatGroup:CreateSeparator({Text = `Other`});

CombatGroup:CreateToggle({
    Name = `Fake Parry`,
    Default = false,
    Callback = function(Value)
        if Value then SurvivorModule.FakeParry.Enable() else SurvivorModule.FakeParry.Disable() end;
    end,
});

CombatGroup:CreateToggle({
    Name = `Twist Silent Aim`,
    Default = false,
    Callback = function(Value)
        if Value then SurvivorModule.TwistSilentAim.Enable() else SurvivorModule.TwistSilentAim.Disable() end;
    end,
});

--// ── Movement ── //--
local MovementGroup = SurvivorTab:CreateGroup({
    Name = `Movement`,
    Icon = `move`,
    Column = `Left`,
});

MovementGroup:CreateToggle({
    Name = `No Slowdown`,
    Default = false,
    Callback = function(Value)
        if Value then SurvivorModule.NoSlowdown.Enable() else SurvivorModule.NoSlowdown.Disable() end;
    end,
});

MovementGroup:CreateToggle({
    Name = `Fast Vault`,
    Default = false,
    Callback = function(Value)
        if Value then SurvivorModule.FastVault.Enable() else SurvivorModule.FastVault.Disable() end;
    end,
});

MovementGroup:CreateToggle({
    Name = `No Fall`,
    Default = false,
    Callback = function(Value)
        if Value then SurvivorModule.NoFall.Enable() else SurvivorModule.NoFall.Disable() end;
    end,
});

MovementGroup:CreateToggle({
    Name = `No Hitbox`,
    Default = false,
    Callback = function(Value)
        Liquidation.States.NoHitboxEnabled = Value;
        if Value then SurvivorModule.NoHitbox.Enable() else SurvivorModule.NoHitbox.Disable() end;
    end,
});

--// ── Visual ── //--
local VisualGroup = SurvivorTab:CreateGroup({
    Name = `Visual`,
    Icon = `eye`,
    Column = `Left`,
});

VisualGroup:CreateToggle({
    Name = `Crosshair`,
    Default = false,
    Callback = function(Value)
        if Value then SurvivorModule.Crosshair.Enable() else SurvivorModule.Crosshair.Disable() end;
    end,
});

VisualGroup:CreateCombobox({
    Name = `Crosshair Type`,
    Options = {`crosshair`, `dot`, `circle`},
    Default = {`crosshair`},
    SingleSelect = true,
    Callback = function(Value)
        if Value then SurvivorModule.Crosshair.SetType(Value) end;
    end,
});

VisualGroup:CreateToggle({
    Name = `Rainbow Crosshair`,
    Default = false,
    Callback = function(Value)
        SurvivorModule.Crosshair.ToggleRainbow(Value);
    end,
});

--// ── Victory ── //--
local VictoryGroup = SurvivorTab:CreateGroup({
    Name = `Victory`,
    Icon = `trophy`,
    Column = `Right`,
});

VictoryGroup:CreateToggle({
    Name = `Auto Victory`,
    Default = false,
    Callback = function(Value)
        if Value then SurvivorModule.AutoVictory.Enable() else SurvivorModule.AutoVictory.Disable() end;
    end,
});

VictoryGroup:CreateToggle({
    Name = `Auto Victory V2`,
    Default = false,
    Callback = function(Value)
        if Value then SurvivorModule.AutoVictoryV2.Enable() else SurvivorModule.AutoVictoryV2.Disable() end;
    end,
});

VictoryGroup:CreateToggle({
    Name = `Gate Tool`,
    Default = false,
    Callback = function(Value)
        if Value then SurvivorModule.GateTool.Enable() else SurvivorModule.GateTool.Disable() end;
    end,
});

--// ── Healing ── //--
local HealingGroup = SurvivorTab:CreateGroup({
    Name = `Healing`,
    Icon = `heart`,
    Column = `Right`,
});

HealingGroup:CreateToggle({
    Name = `God Mode`,
    Default = false,
    Callback = function(Value)
        if Value then SurvivorModule.Gamemode.Enable() else SurvivorModule.Gamemode.Disable() end;
    end,
});

HealingGroup:CreateToggle({
    Name = `Instant Heal`,
    Default = false,
    Callback = function(Value)
        if Value then SurvivorModule.StartInstantHeal() else SurvivorModule.StopInstantHeal() end;
    end,
});

HealingGroup:CreateToggle({
    Name = `Silent Heal`,
    Default = false,
    Callback = function(Value)
        if Value then SurvivorModule.StartSilentHeal() else SurvivorModule.StopSilentHeal() end;
    end,
});

--// ── Generators ── //--
local GeneratorGroup = SurvivorTab:CreateGroup({
    Name = `Generators`,
    Icon = `cpu`,
    Column = `Right`,
});

GeneratorGroup:CreateToggle({
    Name = `Auto Perfect Skill`,
    Default = false,
    Callback = function(Value)
        if Value then SurvivorModule.AutoPerfectSkill.Enable() else SurvivorModule.AutoPerfectSkill.Disable() end;
    end,
});

--// ── Attributes ── //--
local AttrGroup = SurvivorTab:CreateGroup({
    Name = `Attributes`,
    Icon = `sliders`,
    Column = `Right`,
});

AttrGroup:CreateSeparator({Text = `Speed`});

AttrGroup:CreateToggle({
    Name = `Speed Vault`,
    Default = false,
    Callback = function(Value)
        if Value then SurvivorModule.SpeedVault.Enable() else SurvivorModule.SpeedVault.Disable() end;
    end,
});

AttrGroup:CreateSlider({
    Name = `Vault Speed`,
    Min = 1,
    Max = 10,
    Default = 1,
    Rounding = 1,
    Suffix = `x`,
    Callback = function(Value)
        SurvivorModule.SpeedVault.SetValue(Value);
    end,
});

AttrGroup:CreateToggle({
    Name = `Speed Hack`,
    Default = false,
    Callback = function(Value)
        if Value then SurvivorModule.SpeedHackAttr.Enable() else SurvivorModule.SpeedHackAttr.Disable() end;
    end,
});

AttrGroup:CreateSlider({
    Name = `Speed Boost`,
    Min = 1,
    Max = 3,
    Default = 1,
    Rounding = 1,
    Suffix = `x`,
    Callback = function(Value)
        SurvivorModule.SpeedHackAttr.SetValue(Value);
    end,
});

AttrGroup:CreateSeparator({Text = `Vault`});

AttrGroup:CreateToggle({
    Name = `Vault Distance`,
    Default = false,
    Callback = function(Value)
        if Value then SurvivorModule.VaultDistance.Enable() else SurvivorModule.VaultDistance.Disable() end;
    end,
});

AttrGroup:CreateSlider({
    Name = `Vault Fire Count`,
    Min = 5,
    Max = 30,
    Default = 5,
    Suffix = ``,
    Callback = function(Value)
        SurvivorModule.VaultDistance.SetValue(Value);
    end,
});

AttrGroup:CreateSeparator({Text = `Healing`});

AttrGroup:CreateToggle({
    Name = `Heal Boost`,
    Default = false,
    Callback = function(Value)
        if Value then SurvivorModule.HealBoost.Enable() else SurvivorModule.HealBoost.Disable() end;
    end,
});

AttrGroup:CreateSlider({
    Name = `Heal Boost Value`,
    Min = 1,
    Max = 10,
    Default = 1,
    Rounding = 1,
    Suffix = `x`,
    Callback = function(Value)
        SurvivorModule.HealBoost.SetValue(Value);
    end,
});

AttrGroup:CreateToggle({
    Name = `Repair Boost`,
    Default = false,
    Callback = function(Value)
        if Value then SurvivorModule.RepairBoost.Enable() else SurvivorModule.RepairBoost.Disable() end;
    end,
});

AttrGroup:CreateSlider({
    Name = `Repair Boost Value`,
    Min = 0,
    Max = 10,
    Default = 0,
    Rounding = 1,
    Suffix = `x`,
    Callback = function(Value)
        SurvivorModule.RepairBoost.SetValue(Value);
    end,
});

AttrGroup:CreateSeparator({Text = `Bleed`});

AttrGroup:CreateToggle({
    Name = `Bleed Boost`,
    Default = false,
    Callback = function(Value)
        if Value then SurvivorModule.BleedBoost.Enable() else SurvivorModule.BleedBoost.Disable() end;
    end,
});

AttrGroup:CreateSlider({
    Name = `Bleed Boost Value`,
    Min = 0,
    Max = 1,
    Default = 0,
    Rounding = 2,
    Suffix = ``,
    Callback = function(Value)
        SurvivorModule.BleedBoost.SetValue(Value);
    end,
});

--// ═══════════════════════════════ //--
--//         KILLER TAB             //--
--// ═══════════════════════════════ //--

local KillerTab = Window:CreateTab({
    Name = `Killer`,
    Icon = `skull`,
});

--// Combat //--
local KillerCombatGroup = KillerTab:CreateGroup({
    Name = `Combat`,
    Icon = `sword`,
    Column = `Left`,
});

KillerCombatGroup:CreateToggle({
    Name = `Double Tap`,
    Default = false,
    Callback = function(Value)
        if Value then KillerModule.DoubleTap.Enable() else KillerModule.DoubleTap.Disable() end;
    end,
});

KillerCombatGroup:CreateToggle({
    Name = `Hitbox Expand`,
    Default = false,
    Callback = function(Value)
        if Value then KillerModule.Hitbox.Enable() else KillerModule.Hitbox.Disable() end;
    end,
});

KillerCombatGroup:CreateSlider({
    Name = `Hitbox Size`,
    Min = 20,
    Max = 500,
    Default = 20,
    Callback = function(Value)
        KillerModule.Hitbox.SetSize(Value);
    end,
});

KillerCombatGroup:CreateToggle({
    Name = `No Pallet Stun`,
    Default = false,
    Callback = function(Value)
        if Value then KillerModule.NoPalletStun.Enable() else KillerModule.NoPalletStun.Disable() end;
    end,
});

KillerCombatGroup:CreateToggle({
    Name = `Anti Blind`,
    Default = false,
    Callback = function(Value)
        if Value then KillerModule.AntiBlind.Enable() else KillerModule.AntiBlind.Disable() end;
    end,
});

--// Movement //--
local KillerMovementGroup = KillerTab:CreateGroup({
    Name = `Movement`,
    Icon = `move`,
    Column = `Left`,
});

KillerMovementGroup:CreateToggle({
    Name = `No Slowdown`,
    Default = false,
    Callback = function(Value)
        if Value then KillerModule.NoSlowdown.Enable() else KillerModule.NoSlowdown.Disable() end;
    end,
});

KillerMovementGroup:CreateToggle({
    Name = `Third Person`,
    Default = false,
    Callback = function(Value)
        if Value then KillerModule.ThirdPerson.Enable() else KillerModule.ThirdPerson.Disable() end;
    end,
});

--// Veil (Spear) //--
local KillerVeilGroup = KillerTab:CreateGroup({
    Name = `Veil`,
    Icon = `crosshair`,
    Column = `Left`,
});

KillerVeilGroup:CreateToggle({
    Name = `Spear Crosshair`,
    Default = false,
    Callback = function(Value)
        if Value then KillerModule.SpearCrosshair.Enable() else KillerModule.SpearCrosshair.Disable() end;
    end,
});

KillerVeilGroup:CreateToggle({
    Name = `Spear AimBot`,
    Default = false,
    Callback = function(Value)
        if Value then KillerModule.SpearAimBot.Enable() else KillerModule.SpearAimBot.Disable() end;
    end,
});

--// Victory //--
local KillerVictoryGroup = KillerTab:CreateGroup({
    Name = `Victory`,
    Icon = `trophy`,
    Column = `Right`,
});

KillerVictoryGroup:CreateToggle({
    Name = `Beat Game (Killer)`,
    Default = false,
    Callback = function(Value)
        if Value then KillerModule.BeatGameKiller.Enable() else KillerModule.BeatGameKiller.Disable() end;
    end,
});

--// Map //--
local KillerMapGroup = KillerTab:CreateGroup({
    Name = `Map`,
    Icon = `map`,
    Column = `Right`,
});

KillerMapGroup:CreateToggle({
    Name = `Destroy All Pallets`,
    Default = false,
    Callback = function(Value)
        if Value then KillerModule.DestroyPallets.Enable() else KillerModule.DestroyPallets.Disable() end;
    end,
});

KillerMapGroup:CreateToggle({
    Name = `Break Generator`,
    Default = false,
    Callback = function(Value)
        if Value then KillerModule.BreakGenerator.Enable() else KillerModule.BreakGenerator.Disable() end;
    end,
});

--// Masked //--
local KillerMaskedGroup = KillerTab:CreateGroup({
    Name = `Masked`,
    Icon = `layers`,
    Column = `Right`,
});

KillerMaskedGroup:CreateToggle({
    Name = `Use Fake Saw`,
    Default = false,
    Callback = function(Value)
        if Value then KillerModule.UseFakeSaw.Enable() else KillerModule.UseFakeSaw.Disable() end;
    end,
});

KillerMaskedGroup:CreateToggle({
    Name = `Abysswalker Corrupt`,
    Default = false,
    Callback = function(Value)
        if Value then KillerModule.AbysswalkerCorrupt.Enable() else KillerModule.AbysswalkerCorrupt.Disable() end;
    end,
});

--// Mask Powers //--
local MaskPowersGroup = KillerTab:CreateGroup({
    Name = `Mask Powers`,
    Icon = `cpu`,
    Column = `Right`,
});

MaskPowersGroup:CreateLabel({
    Text = "Alex = Chainsaw\nTony = Fists\nBrandon = Speed\nJake = Long lunge\nRichter = Stealth\nGraham = Faster vaults\nRichard = Default mask",
});

local MaskPowersCombobox
MaskPowersCombobox = MaskPowersGroup:CreateCombobox({
    Name = `Activate Power`,
    Options = {`Alex`, `Tony`, `Brandon`, `Jake`, `Richter`, `Graham`, `Richard`},
    Default = {},
    SingleSelect = true,
    Callback = function(Value)
        if not Value then return end;
        KillerModule.ActivateMaskPower(Value);
        task.delay(0.1, function()
            MaskPowersCombobox:Set({});
        end);
    end,
});

--// ═══════════════════════════════ //--
--//        MOVEMENT TAB            //--
--// ═══════════════════════════════ //--

local MovementTab = Window:CreateTab({
    Name = `Movement`,
    Icon = `move`,
});

--// Speed //--
local SpeedGroup = MovementTab:CreateGroup({
    Name = `Speed`,
    Icon = `zap`,
    Column = `Left`,
});

SpeedGroup:CreateToggle({
    Name = `Walk Speed`,
    Default = false,
    Callback = function(Value)
        if Value then MovementModule.WalkSpeed.Enable() else MovementModule.WalkSpeed.Disable() end;
    end,
});

SpeedGroup:CreateSlider({
    Name = `Walk Speed Value`,
    Min = 16,
    Max = 500,
    Default = 50,
    Callback = function(Value)
        MovementModule.WalkSpeed.SetSpeed(Value);
    end,
});

--// Fly //--
local FlyGroup = MovementTab:CreateGroup({
    Name = `Fly`,
    Icon = `plane`,
    Column = `Left`,
});

FlyGroup:CreateToggle({
    Name = `Fly`,
    Default = false,
    Callback = function(Value)
        if Value then MovementModule.Fly.Enable() else MovementModule.Fly.Disable() end;
    end,
});

FlyGroup:CreateSlider({
    Name = `Fly Speed`,
    Min = 0,
    Max = 200,
    Default = 50,
    Callback = function(Value)
        MovementModule.Settings = MovementModule.Settings or {};
        MovementModule.Settings.flySpeed = Value;
    end,
});

--// Misc //--
local MovementMiscGroup = MovementTab:CreateGroup({
    Name = `Misc`,
    Icon = `settings`,
    Column = `Left`,
});

MovementMiscGroup:CreateToggle({
    Name = `No Clip`,
    Default = false,
    Callback = function(Value)
        if Value then MovementModule.NoClip.Enable() else MovementModule.NoClip.Disable() end;
    end,
});

MovementMiscGroup:CreateToggle({
    Name = `Infinite Lunge`,
    Default = false,
    Callback = function(Value)
        if Value then MovementModule.InfiniteLunge.Enable() else MovementModule.InfiniteLunge.Disable() end;
    end,
});

MovementMiscGroup:CreateSlider({
    Name = `Lunge Speed`,
    Min = 10,
    Max = 200,
    Default = 50,
    Callback = function(Value)
        MovementModule.InfiniteLunge.SetSpeed(Value);
    end,
});

--// Teleport //--
local TeleportGroup = MovementTab:CreateGroup({
    Name = `Teleport`,
    Icon = `navigation`,
    Column = `Right`,
});

local function GetPlayerNames()
    local Names = {};
    for _, P in ipairs(game:GetService(`Players`):GetPlayers()) do
        if P ~= game:GetService(`Players`).LocalPlayer then
            table.insert(Names, P.Name);
        end;
    end;
    return Names;
end;

local TeleportCombobox
TeleportCombobox = TeleportGroup:CreateCombobox({
    Name = `Teleport to Player`,
    Options = GetPlayerNames(),
    Default = {},
    SingleSelect = true,
    Callback = function(Value)
        if not Value then return end;
        local TargetPlayer = game:GetService(`Players`):FindFirstChild(Value);
        if TargetPlayer and TargetPlayer.Character then
            local TargetRoot = TargetPlayer.Character:FindFirstChild(`HumanoidRootPart`);
            local LocalRoot = MovementModule.GetRootPart();
            if LocalRoot and TargetRoot then
                LocalRoot.CFrame = TargetRoot.CFrame + Vector3.new(0, 3, 0);
            end;
        end;
        task.delay(0.1, function() TeleportCombobox:Set({}) end);
    end,
});

TeleportGroup:CreateButton({
    Name = `Refresh Players`,
    Callback = function()
        TeleportCombobox:Refresh(GetPlayerNames());
    end,
});

--// Camera //--
local CameraGroup = MovementTab:CreateGroup({
    Name = `Camera`,
    Icon = `camera`,
    Column = `Right`,
});

CameraGroup:CreateToggle({
    Name = `Free Camera`,
    Default = false,
    Callback = function(Value)
        if Value then MovementModule.FreeCamera.Enable() else MovementModule.FreeCamera.Disable() end;
    end,
});

CameraGroup:CreateSlider({
    Name = `Free Camera Speed`,
    Min = 0,
    Max = 100,
    Default = 50,
    Callback = function(Value)
        MovementModule.Settings = MovementModule.Settings or {};
        MovementModule.Settings.freeCameraSpeed = Value;
    end,
});

CameraGroup:CreateToggle({
    Name = `Custom FOV`,
    Default = false,
    Callback = function(Value)
        MovementModule.FOV.SetEnabled(Value);
    end,
});

CameraGroup:CreateSlider({
    Name = `FOV Value`,
    Min = 30,
    Max = 120,
    Default = 95,
    Callback = function(Value)
        MovementModule.FOV.SetValue(Value);
    end,
});

--// ═══════════════════════════════ //--
--//           FUN TAB              //--
--// ═══════════════════════════════ //--

local FunTab = Window:CreateTab({
    Name = `Fun`,
    Icon = `smile`,
});

--// Emotes //--
local EmotesGroup = FunTab:CreateGroup({
    Name = `Emotes`,
    Icon = `music`,
    Column = `Left`,
});

local EmotesList = {};
local EmotesInitialized = FunModule.InitializeEmotesSystem();
if EmotesInitialized then
    for _, EmoteName in ipairs(FunModule.AvailableEmotes) do
        table.insert(EmotesList, EmoteName);
    end;
end;
table.insert(EmotesList, `Jerk`);

local EmoteCombobox;
EmoteCombobox = EmotesGroup:CreateCombobox({
    Name = `Select Emote`,
    Options = EmotesList,
    Default = {},
    SingleSelect = true,
    Callback = function(Value)
        if not Value then return end;
        if Value == `Jerk` then
            FunModule.Emotes.StartJerk();
        else
            FunModule.Emotes.Play(Value);
        end;
        task.delay(0.1, function()
            EmoteCombobox:Set({});
        end);
    end,
});

EmotesGroup:CreateButton({
    Name = `Stop Emote`,
    Callback = function()
        FunModule.Emotes.Stop();
        FunModule.Emotes.StopJerk();
    end,
});

EmotesGroup:CreateKeybind({
    Name = `Stop Emote`,
    Default = nil,
    Callback = RegisterActionKeybind(function()
        FunModule.Emotes.Stop();
        FunModule.Emotes.StopJerk();
    end),
});

--// Character //--
local CharGroup = FunTab:CreateGroup({
    Name = `Character`,
    Icon = `user`,
    Column = `Left`,
});

CharGroup:CreateToggle({
    Name = `Spin`,
    Default = false,
    Callback = function(Value)
        if Value then FunModule.Spin.Enable() else FunModule.Spin.Disable() end;
    end,
});

--// Fling //--
local FlingGroup = FunTab:CreateGroup({
    Name = `Fling`,
    Icon = `zap`,
    Column = `Right`,
});

FlingGroup:CreateButton({
    Name = `Fling Nearest`,
    Callback = function()
        FunModule.Fling.Once();
    end,
});

FlingGroup:CreateKeybind({
    Name = `Fling Nearest`,
    Default = nil,
    Callback = RegisterActionKeybind(function()
        FunModule.Fling.Once();
    end),
});

FlingGroup:CreateToggle({
    Name = `Auto Fling`,
    Default = false,
    Callback = function(Value)
        if Value then FunModule.Fling.StartAuto() else FunModule.Fling.StopAuto() end;
    end,
});

--// Utilities //--
local UtilsGroup = FunTab:CreateGroup({
    Name = `Utilities`,
    Icon = `settings`,
    Column = `Right`,
});

UtilsGroup:CreateButton({
    Name = `Reset Character`,
    Callback = function()
        FunModule.Utils.Reset();
    end,
});

UtilsGroup:CreateKeybind({
    Name = `Reset Character`,
    Default = nil,
    Callback = RegisterActionKeybind(function()
        FunModule.Utils.Reset();
    end),
});

UtilsGroup:CreateButton({
    Name = `Rejoin Game`,
    Callback = function()
        FunModule.Utils.Rejoin();
    end,
});

UtilsGroup:CreateButton({
    Name = `Server Hop`,
    Callback = function()
        FunModule.Utils.ServerHop();
    end,
});

--// ═══════════════════════════════ //--
--//          VISUAL TAB            //--
--// ═══════════════════════════════ //--

local VisualTab = Window:CreateTab({
    Name = `Visual`,
    Icon = `eye`,
});

--// Effects //--
local EffectsGroup = VisualTab:CreateGroup({
    Name = `Effects`,
    Icon = `sun`,
    Column = `Left`,
});

EffectsGroup:CreateToggle({
    Name = `No Shadow`,
    Default = false,
    Callback = function(Value)
        VisualModule.ToggleNoShadow(Value);
    end,
});

EffectsGroup:CreateToggle({
    Name = `No Fog`,
    Default = false,
    Callback = function(Value)
        VisualModule.ToggleNoFog(Value);
    end,
});

EffectsGroup:CreateToggle({
    Name = `Fullbright`,
    Default = false,
    Callback = function(Value)
        VisualModule.ToggleFullBright(Value);
    end,
});

EffectsGroup:CreateSeparator({Text = `Time`});

EffectsGroup:CreateToggle({
    Name = `Time Changer`,
    Default = false,
    Callback = function(Value)
        VisualModule.ToggleTimeChanger(Value);
    end,
});

EffectsGroup:CreateSlider({
    Name = `Time of Day`,
    Min = 0,
    Max = 24,
    Default = 14,
    Rounding = 1,
    Suffix = `h`,
    Callback = function(Value)
        VisualModule.SetTime(Value);
    end,
});

--// Basic ESP //--
local BasicESPGroup = VisualTab:CreateGroup({
    Name = `Basic ESP`,
    Icon = `activity`,
    Column = `Left`,
});

BasicESPGroup:CreateToggle({
    Name = `Show Generator %`,
    Default = true,
    Callback = function(Value)
        VisualModule.ESP.showGeneratorPercent = Value;
        VisualModule.UpdateESPDisplay();
    end,
});

BasicESPGroup:CreateSeparator({Text = `Players`});

BasicESPGroup:CreateToggle({
    Name = `Survivors ESP`,
    Default = false,
    Color = VisualModule.ESP.settings.Survivors.Color,
    Callback = function(Value)
        VisualModule.ToggleESPSetting(`Survivors`, Value);
    end,
    ColorCallback = function(Color)
        VisualModule.SetESPColor(`Survivors`, Color);
    end,
});

BasicESPGroup:CreateToggle({
    Name = `Killers ESP`,
    Default = false,
    Color = VisualModule.ESP.settings.Killers.Color,
    Callback = function(Value)
        VisualModule.ToggleESPSetting(`Killers`, Value);
    end,
    ColorCallback = function(Color)
        VisualModule.SetESPColor(`Killers`, Color);
    end,
});

BasicESPGroup:CreateSeparator({Text = `Map`});

BasicESPGroup:CreateToggle({
    Name = `Generators ESP`,
    Default = false,
    Color = VisualModule.ESP.settings.Generators.Color,
    Callback = function(Value)
        VisualModule.ToggleESPSetting(`Generators`, Value);
    end,
    ColorCallback = function(Color)
        VisualModule.SetESPColor(`Generators`, Color);
    end,
});

BasicESPGroup:CreateToggle({
    Name = `Hooks ESP`,
    Default = false,
    Color = VisualModule.ESP.settings.Hooks.Color,
    Callback = function(Value)
        VisualModule.ToggleESPSetting(`Hooks`, Value);
    end,
    ColorCallback = function(Color)
        VisualModule.SetESPColor(`Hooks`, Color);
    end,
});

BasicESPGroup:CreateToggle({
    Name = `Pallets ESP`,
    Default = false,
    Color = VisualModule.ESP.settings.Pallets.Color,
    Callback = function(Value)
        VisualModule.ToggleESPSetting(`Pallets`, Value);
    end,
    ColorCallback = function(Color)
        VisualModule.SetESPColor(`Pallets`, Color);
    end,
});

BasicESPGroup:CreateToggle({
    Name = `Exit Gates ESP`,
    Default = false,
    Color = VisualModule.ESP.settings.ExitGates.Color,
    Callback = function(Value)
        VisualModule.ToggleESPSetting(`ExitGates`, Value);
    end,
    ColorCallback = function(Color)
        VisualModule.SetESPColor(`ExitGates`, Color);
    end,
});

BasicESPGroup:CreateToggle({
    Name = `Windows ESP`,
    Default = false,
    Color = VisualModule.ESP.settings.Windows.Color,
    Callback = function(Value)
        VisualModule.ToggleESPSetting(`Windows`, Value);
    end,
    ColorCallback = function(Color)
        VisualModule.SetESPColor(`Windows`, Color);
    end,
});

BasicESPGroup:CreateToggle({
    Name = `Gifts ESP`,
    Default = false,
    Color = VisualModule.ESP.settings.Gifts.Color,
    Callback = function(Value)
        VisualModule.ToggleESPSetting(`Gifts`, Value);
    end,
    ColorCallback = function(Color)
        VisualModule.SetESPColor(`Gifts`, Color);
    end,
});

--// Advanced ESP //--
local AdvancedESPGroup = VisualTab:CreateGroup({
    Name = `Advanced ESP`,
    Icon = `layers`,
    Column = `Right`,
});

AdvancedESPGroup:CreateToggle({
    Name = `Enable Advanced ESP`,
    Default = false,
    Callback = function(Value)
        VisualModule.ToggleAdvancedESP(Value);
    end,
});

AdvancedESPGroup:CreateSeparator({Text = `Options`});

AdvancedESPGroup:CreateToggle({
    Name = `Player Boxes`,
    Default = true,
    Callback = function(Value)
        VisualModule.AdvancedESP.settings.box = Value;
    end,
});

AdvancedESPGroup:CreateToggle({
    Name = `Filled Box`,
    Default = true,
    Callback = function(Value)
        VisualModule.AdvancedESP.settings.boxFill = Value;
    end,
});

AdvancedESPGroup:CreateToggle({
    Name = `Player Names`,
    Default = true,
    Callback = function(Value)
        VisualModule.AdvancedESP.settings.name = Value;
    end,
});

AdvancedESPGroup:CreateToggle({
    Name = `Health Bar`,
    Default = true,
    Callback = function(Value)
        VisualModule.AdvancedESP.settings.healthbar = Value;
    end,
});

AdvancedESPGroup:CreateToggle({
    Name = `Distance`,
    Default = true,
    Callback = function(Value)
        VisualModule.AdvancedESP.settings.distance = Value;
    end,
});

AdvancedESPGroup:CreateToggle({
    Name = `Tracers`,
    Default = true,
    Callback = function(Value)
        VisualModule.AdvancedESP.settings.tracers = Value;
    end,
});

AdvancedESPGroup:CreateToggle({
    Name = `Bones`,
    Default = true,
    Callback = function(Value)
        VisualModule.AdvancedESP.settings.bones = Value;
    end,
});

Liquidation.Window = Window
Liquidation.Library = LiquidationLib
Liquidation.Modules = {Survivor = SurvivorModule, Killer = KillerModule, Movement = MovementModule, Fun = FunModule, Visual = VisualModule}
LiquidationLib:RegisterUnloadCallback(function()
    for _, module in pairs(Liquidation.Modules) do
        if type(module.Cleanup) == "function" then pcall(module.Cleanup) end
    end
    if type(VisualModule.StopESP) == "function" then pcall(VisualModule.StopESP) end
    if type(VisualModule.StopAdvancedESP) == "function" then pcall(VisualModule.StopAdvancedESP) end
    for _, connection in pairs(Liquidation.Connections) do Liquidation.safeDisconnect(connection) end
end)
return Liquidation
