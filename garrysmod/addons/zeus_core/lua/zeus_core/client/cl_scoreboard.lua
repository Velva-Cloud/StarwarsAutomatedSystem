ZEUS = ZEUS or {}
ZEUS.ClientIdentity = ZEUS.ClientIdentity or {}

local scoreboard

local function createScoreboard()
    if IsValid(scoreboard) then
        scoreboard:Remove()
    end

    local scrW, scrH = ScrW(), ScrH()

    local frame = vgui.Create("DFrame")
    frame:SetSize(scrW * 0.6, scrH * 0.7)
    frame:Center()
    frame:SetTitle(ZEUS.Config and ZEUS.Config.ScoreboardTitle or "ZEUS Operations")
    frame:SetDraggable(false)
    frame:ShowCloseButton(false)
    frame:SetVisible(false)

    local list = vgui.Create("DListView", frame)
    list:Dock(FILL)
    list:AddColumn("Name")
    list:AddColumn("Regiment")
    list:AddColumn("Rank")
    list:AddColumn("XP")
    list:AddColumn("Ping")

    frame.PlayerList = list

    function frame:RefreshPlayers()
        list:Clear()

        for _, ply in ipairs(player.GetAll()) do
            local idData = ply.zeusDataClient or {}
            local name = ply.ZEUSFormattedName and ply:ZEUSFormattedName() or ply:Nick()
            local regiment = idData.regiment or ""
            local rank = idData.rank or ""
            local xp = idData.xp or 0

            local line = list:AddLine(name, regiment, rank, xp, ply:Ping())
            line.ply = ply
        end
    end

    scoreboard = frame
end

hook.Add("ScoreboardShow", "ZEUS_Scoreboard_Show", function()
    if not IsValid(scoreboard) then
        createScoreboard()
    end

    scoreboard:RefreshPlayers()
    scoreboard:SetVisible(true)
    scoreboard:MakePopup()
    scoreboard:SetKeyBoardInputEnabled(false)

    return true
end)

hook.Add("ScoreboardHide", "ZEUS_Scoreboard_Hide", function()
    if IsValid(scoreboard) then
        scoreboard:SetVisible(false)
    end
    return true
end)

-- Receive identity for local and others (for scoreboard display)
net.Receive("ZEUS_Identity_Full", function()
    local char_id = net.ReadUInt(16)
    local regiment = net.ReadString()
    local rank = net.ReadString()
    local chosen_name = net.ReadString()
    local xp = net.ReadInt(32)

    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    ply.zeusDataClient = {
        char_id = char_id,
        regiment = regiment,
        rank = rank,
        chosen_name = chosen_name,
        xp = xp,
    }

    ZEUS.ClientIdentity.char_id = char_id
    ZEUS.ClientIdentity.regiment = regiment
    ZEUS.ClientIdentity.rank = rank
    ZEUS.ClientIdentity.chosen_name = chosen_name
    ZEUS.ClientIdentity.xp = xp
end)