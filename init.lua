
-- \\ Services // --

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- \\ Variables // --

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Modules = {
    AchievementUnlock = require(
        PlayerGui:FindFirstChild("AchievementUnlock", true) :: ModuleScript
    ),
}

local DefaultAchievement = {
    Identifier = "TestAchievement",
    Title = "Title",
    Desc = "Description",
    Reason = "Reason",
    Image = "rbxassetid://12309073114"
}

local DefaultOptions = {
    CheckOwned = false,
    Remember = true
}

local Module = {}

type AchievementConfig = {
    Identifier: string?,
    Title: string?,
    Desc: string?,
    Reason: string?,
    Image: string?
}

type Achievement = {
    Title: string,
    Desc: string,
    Reason: string,
    Image: string,
    [string]: any
}

type Options = {
    CheckOwned: boolean,
    Remember: boolean
}

type OwnedAchievements = { string }

-- \\ Functions // --

local function WriteConfig(data: OwnedAchievements): (boolean, string?)
    return pcall(function()
        writefile(
            "DOORS_Custom_Achievements.json",
            HttpService:JSONEncode(data)
        )
    end)
end

local function DecodeConfig(): OwnedAchievements
    local success, result = pcall(function()
        return HttpService:JSONDecode(
            readfile("DOORS_Custom_Achievements.json")
        )
    end)

    return success and result or {}
end

-- \\ Load Custom Asset Helper // --

local function GetLoadCustomAsset()
    if typeof(LoadCustomAsset) == "function" then
        return LoadCustomAsset
    end

    local success, result = pcall(function()
        return loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/RegularVynixu/Utilities/main/Functions.lua"
        ))()
    end)

    if typeof(LoadCustomAsset) == "function" then
        return LoadCustomAsset
    end

    if success and typeof(result) == "function" then
        return result
    end

    warn("[Custom Achievements] Could not load LoadCustomAsset.")
    return nil
end

local LoadAsset = GetLoadCustomAsset()

-- \\ Main // --

Module.CheckOwned = function(self, identifier: string): boolean
    return table.find(DecodeConfig(), identifier) ~= nil
end

Module.Revoke = function(self, identifier: string)
    local config = DecodeConfig()

    for i = #config, 1, -1 do
        if config[i] == identifier then
            table.remove(config, i)
        end
    end

    WriteConfig(config)
end

Module.Grant = function(
    self,
    achievementConfig: AchievementConfig,
    options: Options?
)
    options = typeof(options) == "table" and options or DefaultOptions

    -- Validate achievement configuration
    if not achievementConfig.Identifier then
        warn("[Custom Achievements] Missing achievement Identifier.")
        return
    end

    -- Check if player already owns the achievement
    local config = DecodeConfig()

    if options.CheckOwned
        and table.find(config, achievementConfig.Identifier)
    then
        return
    end

    -- Copy config so the original stays unchanged
    local displayConfig = table.clone(achievementConfig)

    -- Load external image
    local imageUrl = displayConfig.Image

    if imageUrl
        and not imageUrl:match("^rbxassetid://")
        and not imageUrl:match("^rbxasset://")
    then
        -- Convert GitHub blob URLs into direct raw URLs
        imageUrl = imageUrl:gsub(
            "^https://github%.com/([^/]+)/([^/]+)/blob/([^/]+)/",
            "https://raw.githubusercontent.com/%1/%2/%3/"
        )

        -- Remove GitHub's raw query parameter
        imageUrl = imageUrl:gsub("%?raw=true$", "")

        if LoadAsset then
            local success, result = pcall(LoadAsset, imageUrl)

            if success and result then
                displayConfig.Image = result
            else
                warn(
                    "[Custom Achievements] Image loading failed:",
                    result
                )
            end
        else
            warn(
                "[Custom Achievements] No asset loader available:",
                imageUrl
            )
        end
    end

    -- Display achievement
    task.defer(
        Modules.AchievementUnlock,
        Modules,
        displayConfig
    )

    -- Remember achievement
    if options.Remember
        and not self:CheckOwned(achievementConfig.Identifier)
    then
        config[#config + 1] = achievementConfig.Identifier
        WriteConfig(config)
    end
end

return Module