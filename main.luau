local Players = game:GetService("Players")

local Interface = require(script.Parent.Components.Interface)
local ESP = require(script.Parent.Components.ESP)

local LocalPlayer = Players.LocalPlayer

--// Window
local Window = Interface:CreateWindow({
    Title = "Jujutsu Shenanigans",
    Footer = "Player ESP",
    Center = true,
    AutoShow = true,
    Resizable = true,
    ShowCustomCursor = true,
    NotifySide = "Right",
    TabPadding = 8,
    MenuFadeTime = 0.2,
})

--// Player ESP Tab
local ESPTab = Window:AddTab("Player ESP", "eye")

local PlayerESPEnabled = false
local PlayerESPObjects = {}

local function getCharacterRoot(character)
    if not character then
        return nil
    end

    return character:FindFirstChild("HumanoidRootPart")
        or character:FindFirstChild("UpperTorso")
        or character:FindFirstChild("Torso")
end

local function addPlayerESP(player)
    if player == LocalPlayer or PlayerESPObjects[player] then
        return
    end

    local character = player.Character
    local root = getCharacterRoot(character)

    if not character or not root then
        return
    end

    local success = pcall(function()
        ESP:AddESP({
            Object = character,
            Text = player.DisplayName,
            Color = Color3.fromRGB(255, 255, 255),
        })
    end)

    if success then
        PlayerESPObjects[player] = character
    end
end

local function removePlayerESP(player)
    local character = PlayerESPObjects[player]

    if character then
        pcall(function()
            ESP:RemoveESP(character)
        end)

        PlayerESPObjects[player] = nil
    end
end

local function refreshPlayerESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if PlayerESPEnabled then
                addPlayerESP(player)
            else
                removePlayerESP(player)
            end
        end
    end
end

local function enablePlayerESP()
    PlayerESPEnabled = true

    ESP:SetShowDistance(true)
    ESP:SetTracers(false)
    ESP:SetArrows(false)
    ESP:SetMatchColors(true)
    ESP:SetFillTransparency(0.75)
    ESP:SetOutlineTransparency(0)
    ESP:SetTextTransparency(0)
    ESP:SetTextOutlineTransparency(0)
    ESP:SetTextSize(20)

    refreshPlayerESP()
end

local function disablePlayerESP()
    PlayerESPEnabled = false

    for player in pairs(PlayerESPObjects) do
        removePlayerESP(player)
    end
end

--// Toggle
ESPTab:AddToggle("PlayerESP", {
    Text = "Player ESP",
    Default = false,
    Tooltip = "Shows ESP on other players",
}):OnChanged(function(value)
    if value then
        enablePlayerESP()
    else
        disablePlayerESP()
    end
end)

--// Settings
local SettingsBox = ESPTab:AddLeftGroupbox("ESP Settings")

SettingsBox:AddToggle("ESPDistance", {
    Text = "Distance",
    Default = true,
    Tooltip = "Shows the distance to players",
}):OnChanged(function(value)
    ESP:SetShowDistance(value)
end)

SettingsBox:AddToggle("ESPTracers", {
    Text = "Tracers",
    Default = false,
    Tooltip = "Draws lines from the bottom of the screen to players",
}):OnChanged(function(value)
    ESP:SetTracers(value)
end)

SettingsBox:AddToggle("ESPArrows", {
    Text = "Offscreen Arrows",
    Default = false,
    Tooltip = "Shows arrows for players outside the screen",
}):OnChanged(function(value)
    ESP:SetArrows(value)
end)

--// Player handling
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.5)

        if PlayerESPEnabled then
            addPlayerESP(player)
        end
    end)

    if player.Character and PlayerESPEnabled then
        task.defer(addPlayerESP, player)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    removePlayerESP(player)
end)

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        player.CharacterAdded:Connect(function()
            task.wait(0.5)

            if PlayerESPEnabled then
                removePlayerESP(player)
                addPlayerESP(player)
            end
        end)
    end
end

--// Initial setup
ESP:SetShowDistance(true)
ESP:SetTracers(false)
ESP:SetArrows(false)
ESP:SetRenderLimit(240)

return Window
