-- AltTracker.lua for WoW 1.12.1 compatibility

-- Declare the SavedVariables table
MainAltDB = MainAltDB or {} -- Ensures that the table exists even if not loaded

local syncChannelName = "MainAltSync"
local syncChannelIndex
local syncInterval = 300 -- Sync every 5 minutes
local isMainSet = false  -- Flag to track if main character is set
local playerName = UnitName("player")

-- Helper functions for serialization and deserialization
local function SerializeMainAltData()
    local serialized = ""
    for main, alts in pairs(MainAltDB) do
        serialized = serialized .. main .. ":"
        for _, alt in ipairs(alts) do
            serialized = serialized .. alt .. ","
        end
        serialized = serialized:sub(1, -2) .. ";"
    end
    return serialized
end

local function DeserializeMainAltData(data)
    local deserialized = {}
    local blocks = {strsplit(";", data)}
    for _, block in ipairs(blocks) do
        local main, alts = strsplit(":", block)
        if main and alts then
            deserialized[main] = {}
            local altNames = {strsplit(",", alts)}
            for _, alt in ipairs(altNames) do
                table.insert(deserialized[main], alt)
            end
        end
    end
    return deserialized
end

local function MergeMainAltData(receivedDB)
    for main, alts in pairs(receivedDB) do
        if not MainAltDB[main] then
            MainAltDB[main] = alts
        else
            for _, alt in ipairs(alts) do
                if not tContains(MainAltDB[main], alt) then
                    table.insert(MainAltDB[main], alt)
                end
            end
        end
    end
    MainAltDB = MainAltDB  -- Save updated DB to saved variables
    DEFAULT_CHAT_FRAME:AddMessage("Synced data successfully.")
end

local function JoinSyncChannel()
    if not syncChannelName then return end
    JoinChannelByName(syncChannelName)
    syncChannelIndex = GetChannelName(syncChannelName)
    if syncChannelIndex then
        DEFAULT_CHAT_FRAME:AddMessage("Joined sync channel: " .. syncChannelName)
        SyncData()
    else
        DEFAULT_CHAT_FRAME:AddMessage("Failed to join sync channel.")
    end
end

local function SyncData()
    if not syncChannelIndex then
        DEFAULT_CHAT_FRAME:AddMessage("Sync channel not available.")
        return
    end
    local message = "SYNC:" .. SerializeMainAltData()
    SendAddonMessage("MainAltTracker", message, "CHANNEL", syncChannelIndex)
    DEFAULT_CHAT_FRAME:AddMessage("Syncing data with all addon users.")
end

local function OnAddonMessageReceived(prefix, message, channel, sender)
    if prefix ~= "MainAltTracker" or sender == UnitName("player") then
        return
    end

    if channel == "CHANNEL" and message:find("^SYNC:") then
        local data = message:sub(6)
        local receivedDB = DeserializeMainAltData(data)
        if receivedDB then
            MergeMainAltData(receivedDB)
        end
    end
end

-- Sync Trigger
local function SchedulePeriodicSync()
    local frame = CreateFrame("Frame")
    frame:SetScript("OnUpdate", function(self, elapsed)
        if not self.timer then
            self.timer = 0
        end
        self.timer = self.timer + elapsed
        if self.timer >= syncInterval then
            SyncData()
            self.timer = 0
        end
    end)
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("CHAT_MSG_ADDON")

frame:SetScript("OnEvent", function(self, event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8)
    if event == "PLAYER_ENTERING_WORLD" then
        JoinSyncChannel()
        SchedulePeriodicSync()

        -- Automatically add this character as an alt to the main if one is set
        if isMainSet then
            -- Ensure the main character exists in the database
            if not MainAltDB[playerName] then
                MainAltDB[playerName] = {}
            end

            -- Add the current player as an alt if not already listed
            if not tContains(MainAltDB[playerName], playerName) then
                table.insert(MainAltDB[playerName], playerName)
                DEFAULT_CHAT_FRAME:AddMessage(playerName .. " has been added as an alt to " .. playerName)
            end
        else
            DEFAULT_CHAT_FRAME:AddMessage("No main character set. Use /alt main to set this character as your main.")
        end
    elseif event == "CHAT_MSG_ADDON" then
        local prefix = arg1
        local message = arg2
        local channel = arg3
        local sender = arg4
        OnAddonMessageReceived(prefix, message, channel, sender)
    end
end)

local function getAltsCount(mainCharacter)
    local alts = MainAltDB[mainCharacter]
    if type(alts) == "table" then
        local count = 0
        for _ in pairs(alts) do
            count = count + 1
        end
        return count
    end
    return 0
end

-- Handle slash commands
SLASH_ALT1 = "/alt"
SlashCmdList["ALT"] = function(msg)
    if not msg or msg == "" then
        DEFAULT_CHAT_FRAME:AddMessage("Usage of /alt command:")
        DEFAULT_CHAT_FRAME:AddMessage("  /alt main - Sets your main character.")
        DEFAULT_CHAT_FRAME:AddMessage("  /alt whois <charname> - Shows the main and other alts of the specified character.")
        return
    end

    -- Parse the command and arguments manually
    local firstSpace = string.find(msg, " ")
    local command, rest
    if firstSpace then
        command = string.sub(msg, 1, firstSpace - 1)
        rest = string.sub(msg, firstSpace + 1)
    else
        command = msg
        rest = ""
    end

    if command == "main" then
        if isMainSet then
            DEFAULT_CHAT_FRAME:AddMessage("This character is already set as your main.")
            return
        end

        MainAltDB[playerName] = MainAltDB[playerName] or {}
        isMainSet = true
        DEFAULT_CHAT_FRAME:AddMessage("Main character set to " .. playerName)

    elseif command == "whois" then
        if not rest or rest == "" then
            DEFAULT_CHAT_FRAME:AddMessage("Usage: /alt whois <charname>")
            return
        end

        local targetName = rest
        if MainAltDB[targetName] then
            local alts = MainAltDB[targetName]
            local count = 0
            for _ in pairs(alts) do
                count = count + 1
            end

            if count > 0 then
                local altList = {}
                for _, alt in pairs(alts) do
                    table.insert(altList, alt)
                end
                DEFAULT_CHAT_FRAME:AddMessage(targetName .. "'s alts: " .. table.concat(altList, ", "))
            else
                DEFAULT_CHAT_FRAME:AddMessage(targetName .. " has no alts.")
            end
        else
            -- Search if the target is an alt of any main
            local foundMain = nil
            for main, alts in pairs(MainAltDB) do
                for _, alt in pairs(alts) do
                    if alt == targetName then
                        foundMain = main
                        break
                    end
                end
                if foundMain then break end
            end

            if foundMain then
                DEFAULT_CHAT_FRAME:AddMessage(targetName .. " is an alt of " .. foundMain)
            else
                DEFAULT_CHAT_FRAME:AddMessage("No information found for " .. targetName)
            end
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("Invalid usage. Type /alt help for options.")
    end
end
