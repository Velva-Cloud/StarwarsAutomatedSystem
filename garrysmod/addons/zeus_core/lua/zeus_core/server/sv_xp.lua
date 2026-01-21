ZEUS = ZEUS or {}
ZEUS.XP = ZEUS.XP or {}

local XP = ZEUS.XP

local function giveXP(ply, amount)
    if not IsValid(ply) or not ply.zeusData then return end
    amount = tonumber(amount) or 0
    if amount == 0 then return end

    ply.zeusData.xp = (ply.zeusData.xp or 0) + amount

    if ZEUS.Identity and ZEUS.Identity.SyncToClient then
        ZEUS.Identity.SyncToClient(ply)
    end
end

function XP.Give(ply, amount)
    giveXP(ply, amount)
end

-- Time-based XP
local interval = 60

timer.Create("ZEUS_XP_Time", interval, 0, function()
    for _, ply in ipairs(player.GetAll()) do
        giveXP(ply, ZEUS.Config.XPPerMinute or 0)
    end
end)

-- Kill-based XP
hook.Add("PlayerDeath", "ZEUS_XP_Kills", function(victim, inflictor, attacker)
    if not IsValid(attacker) or not attacker:IsPlayer() then return end
    if attacker == victim then return end

    giveXP(attacker, ZEUS.Config.XPPerKill or 0)
end)

-- Simple chat command to show XP
hook.Add("PlayerSay", "ZEUS_XP_Chat", function(ply, text)
    text = string.lower(text or "")
    if text == "!xp" or text == "/xp" then
        local xp = (ply.zeusData and ply.zeusData.xp) or 0
        ply:ChatPrint("[ZEUS] Your XP: " .. xp)
        return ""
    end
end)