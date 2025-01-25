GuildManagerButton = CreateFrame("Button", "GuildManagerMinimapButton", Minimap)
GuildManagerButton:SetWidth(20)
GuildManagerButton:SetHeight(20)
GuildManagerButton:SetFrameStrata("MEDIUM")

local icon = GuildManagerButton:CreateTexture(nil, "BACKGROUND")
icon:SetTexture("Interface\\AddOns\\HSAK\\Textures\\icon")
icon:SetWidth(20)
icon:SetHeight(20)
icon:SetPoint("CENTER", GuildManagerButton, "CENTER", 0, 0)

local border = GuildManagerButton:CreateTexture(nil, "OVERLAY")
border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
border:SetWidth(54)
border:SetHeight(54)
border:SetPoint("CENTER", GuildManagerButton, "CENTER", 10, -10)

if GuildManagerSettings and GuildManagerSettings.minimapX and GuildManagerSettings.minimapY then
    GuildManagerButton:SetPoint("CENTER", Minimap, "CENTER", GuildManagerSettings.minimapX, GuildManagerSettings.minimapY)
else
    GuildManagerButton:SetPoint("CENTER", Minimap, "CENTER", 39, 70)
end

local function UpdatePosition()
    local cursorX, cursorY = GetCursorPosition()
    local minimapX, minimapY = Minimap:GetCenter()
    local scale = Minimap:GetEffectiveScale()
    cursorX, cursorY = cursorX / scale, cursorY / scale

    local dx, dy = cursorX - minimapX, cursorY - minimapY
    local angle = math.atan2(dy, dx)

    local radius = 80
    local posX, posY = math.cos(angle) * radius, math.sin(angle) * radius

    GuildManagerButton:SetPoint("CENTER", Minimap, "CENTER", posX, posY)
end

GuildManagerButton:RegisterForDrag("LeftButton")
GuildManagerButton:SetMovable(true)
GuildManagerButton:EnableMouse(true)
GuildManagerButton:SetClampedToScreen(true)

GuildManagerButton:SetScript("OnDragStart", function()
    if IsShiftKeyDown() then
        GuildManagerButton:StartMoving()
        GuildManagerButton:SetScript("OnUpdate", UpdatePosition)
    end
end)

GuildManagerButton:SetScript("OnDragStop", function()
    GuildManagerButton:StopMovingOrSizing()
    GuildManagerButton:SetScript("OnUpdate", nil)

    local point, relativeTo, relativePoint, xOffset, yOffset = GuildManagerButton:GetPoint()
    GuildManagerSettings = GuildManagerSettings or {}
    GuildManagerSettings.minimapX = xOffset
    GuildManagerSettings.minimapY = yOffset
end)

GuildManagerButton:SetScript("OnEnter", function()
    if CanEditGuildInfo() then
        GameTooltip:SetOwner(GuildManagerButton, "ANCHOR_BOTTOMRIGHT")
        GameTooltip:AddLine("Guild Manager", 1, 1, 1)
        GameTooltip:AddLine("Left Click: Open Manager", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("Drag: Move", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    else
        GameTooltip:Hide()
    end
end)

GuildManagerButton:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

local function UpdateButtonVisibility()
    if IsInGuild() and CanEditGuildInfo() then
        GuildManagerButton:Show()
    else
        GuildManagerButton:Hide()
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("GUILD_ROSTER_UPDATE")
frame:SetScript("OnEvent", UpdateButtonVisibility)
