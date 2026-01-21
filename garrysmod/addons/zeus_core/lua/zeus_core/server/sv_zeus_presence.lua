ZEUS = ZEUS or {}
ZEUS.ZeusPresence = ZEUS.ZeusPresence or {}

local Presence = ZEUS.ZeusPresence
local Util = ZEUS.Util

util.AddNetworkString("ZEUS_Presence_Status")

function Presence.GetStaffCount()
    local c = 0
    for _, ply in ipairs(player.GetAll()) do
        if Util.IsStaff(ply) then
            c = c + 1
        end
    end
    return c
end

function Presence.IsActive()
    -- Show banner only when staff presence is LOW.
    -- Example: with threshold = 2 (default), show the banner when staff_count &lt; 2.
    local threshold = ZEUS.Config.ZeusStaffThreshold or 2
    return Presence.GetStaffCount() &lt; threshold
end

local function broadcastStatus()
    local active = Presence.IsActive()
    net.Start("ZEUS_Presence_Status")
        net.WriteBool(active)
    net.Broadcast()
end

hook.Add("PlayerInitialSpawn", "ZEUS_Presence_SendOnJoin", function(ply)
    timer.Simple(2, function()
        if not IsValid(ply) then return end
        net.Start("ZEUS_Presence_Status")
            net.WriteBool(Presence.IsActive())
        net.Send(ply)
    end)
end)

hook.Add("PlayerDisconnected", "ZEUS_Presence_Update", function()
    timer.Simple(1, broadcastStatus)
end)

hook.Add("PlayerAuthed", "ZEUS_Presence_UpdateAuthed", function()
    timer.Simple(1, broadcastStatus)
end)

timer.Create("ZEUS_Presence_Ping", 30, 0, broadcastStatus)