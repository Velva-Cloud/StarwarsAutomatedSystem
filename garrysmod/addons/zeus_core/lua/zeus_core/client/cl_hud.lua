ZEUS = ZEUS or {}
ZEUS.ClientIdentity = ZEUS.ClientIdentity or {}
ZEUS.ZeusPresenceClient = ZEUS.ZeusPresenceClient or {}
ZEUS.IncidentClient = ZEUS.IncidentClient or {}

local ClientIdentity = ZEUS.ClientIdentity
local Presence = ZEUS.ZeusPresenceClient
local Incident = ZEUS.IncidentClient

net.Receive("ZEUS_Presence_Status", function()
    Presence.active = net.ReadBool()
end)

net.Receive("ZEUS_Incident_Status", function()
    Incident.active = net.ReadBool()
    Incident.name = net.ReadString()
end)

hook.Add("HUDPaint", "ZEUS_Identity_HUD", function()
    local scrW, scrH = ScrW(), ScrH()

    -- ZEUS presence banner (top center)
    if Presence.active then
        local text = "The server is being watched by ZEUS"
        surface.SetFont("Trebuchet24")
        local w, h = surface.GetTextSize(text)

        local x = scrW / 2 - w / 2
        local y = 10

        surface.SetDrawColor(10, 10, 10, 220)
        surface.DrawRect(x - 8, y - 4, w + 16, h + 8)

        surface.SetTextColor(200, 200, 255, 255)
        surface.SetTextPos(x, y)
        surface.DrawText(text)
    end

    -- Player identity, XP, and incident (bottom left)
    local name = LocalPlayer().ZEUSFormattedName and LocalPlayer():ZEUSFormattedName() or ""
    local xp = ClientIdentity.xp or 0

    if name ~= "" then
        local mainText = name .. " | XP: " .. xp
        local incidentText = nil
        if Incident.active and Incident.name and Incident.name ~= "" then
            incidentText = "Incident: " .. Incident.name
        end

        surface.SetFont("Trebuchet18")
        local w, h = surface.GetTextSize(mainText)
        local totalHeight = h
        if incidentText then
            local _, h2 = surface.GetTextSize(incidentText)
            totalHeight = totalHeight + h2 + 2
        end

        local x = 20
        local y = scrH - totalHeight - 20

        surface.SetDrawColor(0, 0, 0, 180)
        surface.DrawRect(x - 8, y - 4, w + 16, totalHeight + 8)

        surface.SetTextColor(255, 255, 255, 255)
        surface.SetTextPos(x, y)
        surface.DrawText(mainText)

        if incidentText then
            surface.SetTextColor(180, 220, 255, 255)
            surface.SetTextPos(x, y + h + 2)
            surface.DrawText(incidentText)
        end
    end
end