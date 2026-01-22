if SERVER then
    AddCSLuaFile()
end

SWEP.PrintName = "ZEUS Command Tablet"
SWEP.Author = "ZEUS"
SWEP.Instructions = "Primary: Open ZEUS tablet"
SWEP.Spawnable = true
SWEP.AdminSpawnable = true
SWEP.Category = "ZEUS"

SWEP.ViewModel = "models/weapons/c_arms.mdl"
SWEP.WorldModel = "models/nirrti/tablet/tab_02.mdl"

SWEP.UseHands = true
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = false

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"

SWEP.Secondary = SWEP.Primary

function SWEP:Initialize()
    self:SetHoldType("normal")
end

local function canUseTablet(ply)
    if not IsValid(ply) then return false, "Invalid player." end

    -- Staff (SAM group) always allowed
    if ZEUS.Util.IsStaff and ZEUS.Util.IsStaff(ply) then
        return true
    end

    -- ZEUS officer+ allowed
    if ply.zeusData and ply.zeusData.rank and ZEUS.RankIsOfficer then
        if ZEUS.RankIsOfficer(ply.zeusData.rank) then
            return true
        end
    end

    return false, "You must be an officer or staff to use the ZEUS tablet."
end

if CLIENT then
    ZEUS = ZEUS or {}
    ZEUS.Tablet = ZEUS.Tablet or {}

    net.Receive("ZEUS_Tablet_IncidentData", function()
        local count = net.ReadUInt(8)
        local incidents = {}
        for i = 1, count do
            incidents[i] = {
                id = net.ReadUInt(16),
                name = net.ReadString(),
                started_at = net.ReadInt(32),
                ended_at = net.ReadInt(32),
            }
        end

        local participantCount = net.ReadUInt(10)
        local participants = {}
        for i = 1, participantCount do
            participants[i] = {
                steamid = net.ReadString(),
                name = net.ReadString(),
                regiment = net.ReadString(),
                rank = net.ReadString(),
                time_present = net.ReadInt(32),
                kills = net.ReadInt(16),
                deaths = net.ReadInt(16),
                notes = net.ReadString(),
            }
        end

        print(string.format("[ZEUS Tablet] Received %d incidents and %d participants", count, participantCount))

        ZEUS.Tablet.Incidents = incidents
        ZEUS.Tablet.Participants = participants

        -- Open / refresh tablet UI
        if ZEUS.Tablet.OpenUI then
            local ok, err = pcall(ZEUS.Tablet.OpenUI)
            if not ok then
                print("[ZEUS Tablet] Error opening UI: " .. tostring(err))
            end
        end
    end)

    function ZEUS.Tablet.OpenUI()
        local incidents = ZEUS.Tablet.Incidents or {}
        local participants = ZEUS.Tablet.Participants or {}

        if IsValid(ZEUS.Tablet.Frame) then
            ZEUS.Tablet.Frame:Remove()
        end

        local frame = vgui.Create("DFrame")
        frame:SetTitle("ZEUS Incident Tablet")
        frame:SetSize(900, 500)
        frame:Center()
        frame:MakePopup()
        ZEUS.Tablet.Frame = frame

        local left = vgui.Create("DPanel", frame)
        left:Dock(LEFT)
        left:SetWide(250)
        left:DockMargin(5, 5, 5, 5)

        local incidentList = vgui.Create("DListView", left)
        incidentList:Dock(FILL)
        incidentList:AddColumn("ID")
        incidentList:AddColumn("Incident")
        incidentList:AddColumn("Duration")

        for _, inc in ipairs(incidents) do
            local dur = 0
            if inc.started_at and inc.ended_at and inc.ended_at > inc.started_at then
                dur = inc.ended_at - inc.started_at
            end
            local mins = math.floor(dur / 60)
            incidentList:AddLine(inc.id, inc.name, mins .. " min")
        end

        local right = vgui.Create("DPanel", frame)
        right:Dock(FILL)
        right:DockMargin(5, 5, 5, 5)

        local participantList = vgui.Create("DListView", right)
        participantList:Dock(LEFT)
        participantList:SetWide(350)
        participantList:AddColumn("Name")
        participantList:AddColumn("Reg")
        participantList:AddColumn("Time")
        participantList:AddColumn("K/D")

        local detail = vgui.Create("DPanel", right)
        detail:Dock(FILL)
        detail:DockMargin(5, 0, 0, 0)

        local detailLabel = vgui.Create("DLabel", detail)
        detailLabel:Dock(TOP)
        detailLabel:SetTall(20)
        detailLabel:SetText("Select a participant to view details")
        detailLabel:DockMargin(5, 5, 5, 5)

        local notesBox = vgui.Create("DTextEntry", detail)
        notesBox:Dock(FILL)
        notesBox:SetMultiline(true)
        notesBox:SetEditable(false)
        notesBox:DockMargin(5, 0, 5, 5)

        local function populateParticipantsForIncident(incidentId)
            participantList:Clear()

            for _, p in ipairs(participants) do
                if p.incident_id and p.incident_id ~= incidentId then
                    continue
                end

                local mins = math.floor((p.time_present or 0) / 60)
                local kd = (p.kills or 0) .. "/" .. (p.deaths or 0)
                participantList:AddLine(p.name or p.steamid, p.regiment or "", mins .. "m", kd).ParticipantData = p
            end
        end

        incidentList.OnRowSelected = function(_, _, line)
            local id = tonumber(line:GetColumnText(1)) or 0
            populateParticipantsForIncident(id)
        end

        participantList.OnRowSelected = function(_, _, line)
            local p = line.ParticipantData
            if not p then return end

            detailLabel:SetText(string.format("%s [%s %s]", p.name or p.steamid, p.regiment or "?", p.rank or "?"))
            local mins = math.floor((p.time_present or 0) / 60)
            local text = string.format("Time present: %d min\nKills: %d\nDeaths: %d\n\nNotes:\n%s",
                mins,
                p.kills or 0,
                p.deaths or 0,
                p.notes ~= "" and p.notes or "None recorded."
            )
            notesBox:SetValue(text)
        end
    end
end

if SERVER then
    util.AddNetworkString("ZEUS_Tablet_IncidentData")

    local function sendIncidentData(ply, incidentId)
        if not ZEUS.Incidents or not sql then return end

        -- Determine which incidents to send (last 10)
        local incidents = sql.Query("SELECT id, name, started_at, ended_at FROM zeus_incidents ORDER BY id DESC LIMIT 10") or {}

        net.Start("ZEUS_Tablet_IncidentData")
            net.WriteUInt(#incidents, 8)
            for _, inc in ipairs(incidents) do
                net.WriteUInt(tonumber(inc.id) or 0, 16)
                net.WriteString(inc.name or "")
                net.WriteInt(tonumber(inc.started_at) or 0, 32)
                net.WriteInt(tonumber(inc.ended_at) or 0, 32)
            end

            -- Participants for latest incident by default
            local participants = {}
            local targetIncidentId = incidentId

            if not targetIncidentId and incidents[1] then
                targetIncidentId = tonumber(incidents[1].id)
            end

            if targetIncidentId then
                participants = sql.Query(string.format([[
                    SELECT incident_id, steamid, regiment, rank, time_present, kills, deaths, notes
                    FROM zeus_incident_participants
                    WHERE incident_id = %d
                ]], targetIncidentId)) or {}
            end

            net.WriteUInt(#participants, 10)
            for _, p in ipairs(participants) do
                net.WriteString(p.steamid or "")
                local name = p.steamid
                local plyObj = player.GetBySteamID(p.steamid or "")
                if IsValid(plyObj) then
                    name = plyObj:Nick()
                end
                net.WriteString(name or (p.steamid or ""))

                net.WriteString(p.regiment or "")
                net.WriteString(p.rank or "")
                net.WriteInt(tonumber(p.time_present) or 0, 32)
                net.WriteInt(tonumber(p.kills) or 0, 16)
                net.WriteInt(tonumber(p.deaths) or 0, 16)
                net.WriteString(p.notes or "")
            end
        net.Send(ply)
    end

    util.AddNetworkString("ZEUS_Tablet_RequestData")

    net.Receive("ZEUS_Tablet_RequestData", function(_, ply)
        local incidentId = net.ReadUInt(16)
        if incidentId == 0 then
            incidentId = nil
        end

        local ok, err = canUseTablet(ply)
        if not ok then
            ply:ChatPrint("[ZEUS] " .. (err or "You are not allowed to use the tablet."))
            return
        end

        sendIncidentData(ply, incidentId)
    end)
end

-- Primary/Secondary attacks must be defined on both realms so SWEP prediction works,
-- but the network request itself only runs on the server.
function SWEP:PrimaryAttack()
    if CLIENT then return end

    local owner = self:GetOwner()
    if not IsValid(owner) or not owner:IsPlayer() then return end

    local ok, err = canUseTablet(owner)
    if not ok then
        owner:ChatPrint("[ZEUS] " .. (err or "You are not allowed to use the tablet."))
        return
    end

    net.Start("ZEUS_Tablet_RequestData")
        net.WriteUInt(0, 16) -- no specific incident id, use latest
    net.Send(owner)
end

function SWEP:SecondaryAttack()
    self:PrimaryAttack()
end