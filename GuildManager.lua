local rankThresholds = {
    {min = 1, max = 19, rankIndex = 9},
    {min = 20, max = 29, rankIndex = 8}, 
    {min = 30, max = 39, rankIndex = 7},
    {min = 40, max = 49, rankIndex = 6},
    {min = 50, max = 59, rankIndex = 5}, 
    {min = 60, max = 60, rankIndex = 4}  
}

local excludedRanks = {
    [0] = true,
    [1] = true, 
    [2] = true  
}

local fixedRanks = {
    ["Minaelfkica"] = 1,
    ["Fubar"] = 8
}

local dungeonLevelRanges = {
    {name = "rfc", min = 14, max = 20},
    {name = "dm", min = 18, max = 25},
    {name = "wc", min = 18, max = 25},
    {name = "sfk", min = 23, max = 30},
    {name = "bfd", min = 25, max = 31},
    {name = "stoc", min = 26, max = 32},
    {name = "rfk", min = 30, max = 36},
    {name = "gnome", min = 31, max = 37},
    {name = "smgy", min = 31, max = 36},
    {name = "smlib", min = 34, max = 40},
    {name = "smarm", min = 37, max = 43},
    {name = "rfd", min = 38, max = 44},
    {name = "smcat", min = 39, max = 45},
    {name = "ulda", min = 44, max = 50},
    {name = "zf", min = 43, max = 49},
    {name = "mara", min = 48, max = 54},
    {name = "st", min = 52, max = 58},
    {name = "dme", min = 60, max = 60},
    {name = "brd", min = 58, max = 60},
    {name = "strathlive", min = 60, max = 60},
    {name = "lbrs", min = 60, max = 60},
    {name = "dmn", min = 60, max = 60},
    {name = "strathundead", min = 60, max = 60},
    {name = "ubrs", min = 60, max = 60},
    {name = "scholo", min = 60, max = 60},
}

local dungeonNameMapping = {
    rfc = "Ragefire Chasm",
    dm = "Deadmines",
    wc = "Wailing Caverns",
    sfk = "Shadowfang Keep",
    bfd = "Blackfathom Deeps",
    stoc = "Stockades",
    rfk = "Razorfen Kraul",
    gnome = "Gnomeregan",
    smgy = "SM: Graveyard",
    smlib = "SM: Library",
    smarm = "SM: Armory",
    rfd = "Razorfen Downs",
    smcat = "SM: Cathedral",
    ulda = "Uldaman",
    zf = "Zul'Farrak",
    mara = "Maraudon",
    st = "Sunken Temple",
    dme = "Dire Maul East",
    brd = "Blackrock Depths",
    strathlive = "Stratholme Live",
    lbrs = "Lower Blackrock Spire",
    dmn = "Dire Maul North",
    strathundead = "Stratholme Undead",
    ubrs = "Upper Blackrock Spire",
    scholo = "Scholomance",
}

local function DetermineRankIndex(level, name)
    if not name or type(name) ~= "string" then
        return nil
    end

    if fixedRanks[name] then
        return fixedRanks[name]
    end

    if string.find(name, "bank", 1, true) or string.find(name, "Bank", 1, true) then
        return 3
    end
    for _, threshold in ipairs(rankThresholds) do
        if level >= threshold.min and level <= threshold.max then
            return threshold.rankIndex
        end
    end
    return nil
end

local function UpdateRanks()
    local numMembers = GetNumGuildMembers()
    for i = 1, numMembers do
        local name, _, rankIndex, level, _, _, _, _, online = GetGuildRosterInfo(i)
        if excludedRanks[rankIndex] then
        else
            local desiredRankIndex = DetermineRankIndex(level, name)
            while desiredRankIndex and desiredRankIndex ~= rankIndex do
                if desiredRankIndex < rankIndex then
                    GuildPromoteByName(name)
                    rankIndex = rankIndex - 1
                elseif desiredRankIndex > rankIndex then
                    GuildDemoteByName(name)
                    rankIndex = rankIndex + 1
                end
            end
        end
    end
end

local InactiveMembersList

local function PreviewInactiveMembers()
    local numMembers = GetNumGuildMembers()
    local inactiveMembers = {}
    
    for i = 1, numMembers do
        local name, _, rankIndex, _, _, _, _, _, _, _, _, _, _, _ = GetGuildRosterInfo(i)
        local yearsOffline, monthsOffline, daysOffline = GetGuildRosterLastOnline(i)
        local totalDaysOffline = (yearsOffline or 0) * 365 + (monthsOffline or 0) * 30 + (daysOffline or 0)
        if totalDaysOffline > 30 and not excludedRanks[rankIndex] and rankIndex ~= 3 then
            table.insert(inactiveMembers, {name = name, daysOffline = totalDaysOffline, rankIndex = rankIndex})
        end
    end
    local count = 0
    for _ in pairs(inactiveMembers) do
        count = count + 1
    end
    if count > 0 then
        DEFAULT_CHAT_FRAME:AddMessage("The following " .. count .. " members are inactive for more than 30 days:")
        for _, member in ipairs(inactiveMembers) do
            DEFAULT_CHAT_FRAME:AddMessage("- " .. member.name .. " (" .. member.daysOffline .. " days offline)")
        end
        DEFAULT_CHAT_FRAME:AddMessage("Use '/confirmkick' to remove these members.")
    else
        DEFAULT_CHAT_FRAME:AddMessage("No inactive members found who meet the criteria.")
    end
    InactiveMembersList = inactiveMembers
end

local function ConfirmKickInactiveMembers()
    if not InactiveMembersList then
        DEFAULT_CHAT_FRAME:AddMessage("No inactive members to kick. Use '/previewinactive' first.")
        return
    end
    local count = 0
    for _ in pairs(InactiveMembersList) do
        count = count + 1
    end
    if count == 0 then
        DEFAULT_CHAT_FRAME:AddMessage("No inactive members to kick. Use '/previewinactive' first.")
        return
    end
    for _, member in ipairs(InactiveMembersList) do
        if not excludedRanks[member.rankIndex] and rankIndex ~= 3 then 
            GuildUninviteByName(member.name)
            DEFAULT_CHAT_FRAME:AddMessage(member.name .. " has been kicked for being offline for " .. member.daysOffline .. " days.")
        else
            DEFAULT_CHAT_FRAME:AddMessage(member.name .. " cannot be kicked because they are an officer.")
        end
    end
    InactiveMembersList = nil
end

--LFG
local function WhisperForDungeon(dungeonName)
    local dungeon = nil
    for _, d in ipairs(dungeonLevelRanges) do
        if string.lower(d.name) == string.lower(dungeonName) then
            dungeon = d
            break
        end
    end

    if not dungeon then
        DEFAULT_CHAT_FRAME:AddMessage("Dungeon not found: " .. dungeonName)
        return
    end

    local numMembers = GetNumGuildMembers()
    local hasWhispered = false
    for i = 1, numMembers do
        local name, _, _, level, _, _, _, _, online = GetGuildRosterInfo(i)
        if online and level >= dungeon.min and level <= dungeon.max then
            local friendlyName = dungeonNameMapping[dungeon.name] or dungeon.name
            SendChatMessage("Wanna do " .. friendlyName .. "?", "WHISPER", nil, name)
            hasWhispered = true
        end
    end

    if not hasWhispered then
        DEFAULT_CHAT_FRAME:AddMessage("No eligible players online for " .. (dungeonNameMapping[dungeon.name] or dungeon.name) .. ".")
    end
end

-- Button and commands
if GuildManagerButton then
    GuildManagerButton:SetScript("OnClick", function()
        UpdateRanks()
    end)

end

SLASH_GMUPDATEGUILDRANKS1 = "/gmupdateranks"
SlashCmdList["GMUPDATERANKS"] = function()
    UpdateRanks()
end

SLASH_LFG1 = "/lfg"
SlashCmdList["LFG"] = function(msg)
    local dungeonName = string.gsub(msg or "", "^%s*(.-)%s*$", "%1")
    local level = UnitLevel("player")

    if dungeonName == "" then
        DEFAULT_CHAT_FRAME:AddMessage("Available dungeons for your level (" .. level .. "):")
        local foundDungeon = false

        for _, dungeon in ipairs(dungeonLevelRanges) do
            if level >= dungeon.min then
                local friendlyName = dungeonNameMapping[dungeon.name] or dungeon.name
                DEFAULT_CHAT_FRAME:AddMessage(string.format("- %s (%d-%d)", friendlyName, dungeon.min, dungeon.max))
                foundDungeon = true
            end
        end

        if not foundDungeon then
            DEFAULT_CHAT_FRAME:AddMessage("No dungeons available for your level.")
        end
    else
        WhisperForDungeon(dungeonName)
    end
end

SLASH_PREVIEWINACTIVE1 = "/previewinactive"
SlashCmdList["PREVIEWINACTIVE"] = function()
    PreviewInactiveMembers()
end

SLASH_CONFIRMKICK1 = "/confirmkick"
SlashCmdList["CONFIRMKICK"] = function()
    ConfirmKickInactiveMembers()
end