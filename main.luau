--// Jujutsu Shenanigans
--// Main.luau
--// Player ESP only

local BaseUrl = "https://raw.githubusercontent.com/D4rkRoblox/Jujutsu-Shenanigans-Script/main/"

local function LoadComponent(Path)
    local Source = game:HttpGet(BaseUrl .. Path)
    local Chunk, Error = loadstring(Source)

    if not Chunk then
        error(("Failed to compile %s: %s"):format(Path, tostring(Error)))
    end

    local Success, Result = pcall(Chunk)

    if not Success then
        error(("Failed to load %s: %s"):format(Path, tostring(Result)))
    end

    return Result
end

--// Components
local Interface = LoadComponent("Components/Interface.luau")
local ESP = LoadComponent("Components/ESP.luau")

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

--// Obsidian
local Library = Interface

local Window = Library:CreateWindow({
    Title = "Jujutsu Shenanigans",
    Footer = "Player ESP",
    Center = true,
    AutoShow = true,
    Resizable = true,
    ShowCustomCursor = true,
    NotifySide = "Right",
})

local Tabs = {
    Main = Window:AddTab("Main", "user"),
    ESP = Window:AddTab("ESP", "eye"),
}

--// ESP state
local PlayerESPEnabled = false
local PlayerESPObjects = {}

local ESPColor = Color3.fromRGB(255, 255, 255)

local function GetCharacter(Player)
    local Character = Player.Character

    if Character and Character.Parent then
        return Character
    end

    return nil
end

local function AddPlayerESP(Player)
    if Player == LocalPlayer then
        return
    end

    local Character = GetCharacter(Player)

    if not Character then
        return
    end

    if PlayerESPObjects[Player] == Character then
        return
    end

    if PlayerESPObjects[Player] then
        pcall(function()
            ESP:RemoveESP(PlayerESPObjects[Player])
        end)

        PlayerESPObjects[Player] = nil
    end

    ESP:AddESP({
        Object = Character,
        Text = Player.DisplayName,
        Color = ESPColor,
    })

    PlayerESPObjects[Player] = Character
end

local function RemovePlayerESP(Player)
    local Character = PlayerESPObjects[Player]

    if not Character then
        return
    end

    pcall(function()
        ESP:RemoveESP(Character)
    end)

    PlayerESPObjects[Player] = nil
end

local function RefreshPlayerESP()
    for _, Player in ipairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer then
            if PlayerESPEnabled then
                AddPlayerESP(Player)
            else
                RemovePlayerESP(Player)
            end
        end
    end
end

local function SetPlayerESP(Value)
    PlayerESPEnabled = Value

    if Value then
        RefreshPlayerESP()
    else
        for Player in pairs(PlayerESPObjects) do
            RemovePlayerESP(Player)
        end
    end
end

--// Main tab
local MainBox = Tabs.Main:AddLeftGroupbox({
    Name = "Jujutsu Shenanigans",
    IconName = "gamepad-2",
})

MainBox:AddLabel("Jujutsu Shenanigans Script")
MainBox:AddLabel("Player ESP is available in the ESP tab.", true)

--// ESP tab
local PlayerBox = Tabs.ESP:AddLeftGroupbox({
    Name = "Player ESP",
    IconName = "users",
})

PlayerBox:AddToggle("PlayerESP", {
    Text = "Player ESP",
    Default = false,
    Tooltip = "Highlights other players.",
})

PlayerBox:AddLabel("ESP Color"):AddColorPicker("ESPColor", {
    Default = ESPColor,
    Title = "Player ESP Color",
})

local SettingsBox = Tabs.ESP:AddRightGroupbox({
    Name = "ESP Settings",
    IconName = "settings",
})

SettingsBox:AddToggle("ShowDistance", {
    Text = "Distance",
    Default = false,
    Tooltip = "Shows the distance to each player.",
})

SettingsBox:AddToggle("ShowTracers", {
    Text = "Tracers",
    Default = false,
    Tooltip = "Draws a line from the bottom of the screen to players.",
})

SettingsBox:AddToggle("ShowArrows", {
    Text = "Offscreen Arrows",
    Default = false,
    Tooltip = "Shows an arrow when a player is outside the screen.",
})

SettingsBox:AddToggle("RainbowESP", {
    Text = "Rainbow",
    Default = false,
    Tooltip = "Cycles the ESP color.",
})

--// UI callbacks
Library.Toggles.PlayerESP:OnChanged(function()
    SetPlayerESP(Library.Toggles.PlayerESP.Value)
end)

Library.Options.ESPColor:OnChanged(function()
    ESPColor = Library.Options.ESPColor.Value

    for _, Character in pairs(PlayerESPObjects) do
        ESP:UpdateObjectColor(Character, ESPColor)
    end
end)

Library.Toggles.ShowDistance:OnChanged(function()
    ESP:SetShowDistance(Library.Toggles.ShowDistance.Value)
end)

Library.Toggles.ShowTracers:OnChanged(function()
    ESP:SetTracers(Library.Toggles.ShowTracers.Value)
end)

Library.Toggles.ShowArrows:OnChanged(function()
    ESP:SetArrows(Library.Toggles.ShowArrows.Value)
end)

Library.Toggles.RainbowESP:OnChanged(function()
    ESP:SetRainbow(Library.Toggles.RainbowESP.Value)
end)

--// Player connections
local CharacterConnections = {}

local function WatchPlayer(Player)
    if Player == LocalPlayer then
        return
    end

    if CharacterConnections[Player] then
        CharacterConnections[Player]:Disconnect()
    end

    CharacterConnections[Player] = Player.CharacterAdded:Connect(function()
        task.wait(0.5)

        if PlayerESPEnabled then
            RemovePlayerESP(Player)
            AddPlayerESP(Player)
        end
    end)

    if PlayerESPEnabled and Player.Character then
        task.defer(AddPlayerESP, Player)
    end
end

for _, Player in ipairs(Players:GetPlayers()) do
    WatchPlayer(Player)
end

Players.PlayerAdded:Connect(function(Player)
    WatchPlayer(Player)
end)

Players.PlayerRemoving:Connect(function(Player)
    RemovePlayerESP(Player)

    if CharacterConnections[Player] then
        CharacterConnections[Player]:Disconnect()
        CharacterConnections[Player] = nil
    end
end)

--// Cleanup when Obsidian unloads
Library:OnUnload(function()
    PlayerESPEnabled = false

    for Player in pairs(PlayerESPObjects) do
        RemovePlayerESP(Player)
    end

    for Player, Connection in pairs(CharacterConnections) do
        Connection:Disconnect()
        CharacterConnections[Player] = nil
    end

    pcall(function()
        ESP:Unload()
    end)
end)

return Window
