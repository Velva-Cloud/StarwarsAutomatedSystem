ZEUS = ZEUS or {}
ZEUS.ClientIdentity = ZEUS.ClientIdentity or {}
ZEUS.ZeusPresenceClient = ZEUS.ZeusPresenceClient or {}

local ClientIdentity = ZEUS.ClientIdentity
local Presence = ZEUS.ZeusPresenceClient

net.Receive("ZEUS_Presence_Status", function()
    Presence.active = net.ReadBool()
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

    -- Player identity and XP (bottom left)
    local name = LocalPlayer().ZEUSFormattedName and LocalPlayer():ZEUSFormattedName() or ""
    local xp = ClientIdentity.xp or 0

    if name ~= "" then
        local text = name .. " | XP: " .. xp
        surface.SetFont("Trebuchet18")
        local w, h = surface.GetTextSize(text)

        local x = 20
        local y = scrH - h - 20

        surface.SetDrawColor(0, 0, 0, 180)
        surface.DrawRect(x - 8, y - 4, w + 16, h + 8)

        surface.SetTextColor(255, 255, 255, 255)
        surface.SetTextPos(x, y)
        surface.DrawText(text)
    end
end)