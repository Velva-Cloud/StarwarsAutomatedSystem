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

    local function sendTabletAction(action, steamid, payload)
        net.Start("ZEUS_Tablet_Action")
            net.WriteString(action or "")
            net.WriteString(steamid or "")
            net.WriteString(payload or "")
        net.SendToServer()
    end

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

        -- Regiment players
        local regCount = net.ReadUInt(8)
        local regimentPlayers = {}
        for i = 1, regCount do
            regimentPlayers[i] = {
                steamid = net.ReadString(),
                name = net.ReadString(),
                regiment = net.ReadString(),
                rank = net.ReadString(),
                rankIndex = net.ReadUInt(16),
            }
        end

        -- Cadets (CC)
        local cadetCount = net.ReadUInt(8)
        local cadets = {}
        for i = 1, cadetCount do
            cadets[i] = {
                steamid = net.ReadString(),
                name = net.ReadString(),
            }
        end

        print(string.format("[ZEUS Tablet] Received %d incidents, %d participants, %d regiment players, %d cadets",
            count, participantCount, regCount, cadetCount))

        ZEUS.Tablet.Incidents = incidents
        ZEUS.Tablet.Participants = participants
        ZEUS.Tablet.RegimentPlayers = regimentPlayers
        ZEUS.Tablet.Cadets = cadets
        ZEUS.Tablet.SendAction = sendTabletAction

        -- Open / refresh tablet UI
        if ZEUS.Tablet.OpenUI then
            local ok, err = pcall(ZEUS.Tablet.OpenUI)
            if not ok then
                print("[ZEUS Tablet] Error opening UI: " .. tostring(err))
            end
        end
    end)

    local function buildIncidentPanel(parent, incidents, participants)
        local panel = vgui.Create("DPanel", parent)
        panel:Dock(FILL)
        panel:DockMargin(5, 5, 5, 5)

        local left = vgui.Create("DPanel", panel)
        left:Dock(LEFT)
        left:SetWide(250)
        left:DockMargin(0, 0, 5, 0)

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

        local right = vgui.Create("DPanel", panel)
        right:Dock(FILL)

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

        return panel
    end

    local function buildRegimentPanel(parent, regimentPlayers)
        local panel = vgui.Create("DPanel", parent)
        panel:Dock(FILL)
        panel:DockMargin(5, 5, 5, 5)

        local list = vgui.Create("DListView", panel)
        list:Dock(FILL)
        list:AddColumn("Name")
        list:AddColumn("Regiment")
        list:AddColumn("Rank")

        -- sort by rankIndex descending (highest rank first)
        table.SortByMember(regimentPlayers, "rankIndex", true)

        for _, p in ipairs(regimentPlayers) do
            local line = list:AddLine(p.name or p.steamid, p.regiment or "", p.rank or "")
            line.PlayerData = p
        end

        local buttonBar = vgui.Create("DPanel", panel)
        buttonBar:Dock(BOTTOM)
        buttonBar:SetTall(40)
        buttonBar:DockMargin(0, 5, 0, 0)

        local promoteBtn = vgui.Create("DButton", buttonBar)
        promoteBtn:Dock(LEFT)
        promoteBtn:SetWide(80)
        promoteBtn:SetText("Promote")

        local demoteBtn = vgui.Create("DButton", buttonBar)
        demoteBtn:Dock(LEFT)
        demoteBtn:SetWide(80)
        demoteBtn:SetText("Demote")

        local setRankBtn = vgui.Create("DButton", buttonBar)
        setRankBtn:Dock(LEFT)
        setRankBtn:SetWide(120)
        setRankBtn:SetText("Set Rank")

        local removeBtn = vgui.Create("DButton", buttonBar)
        removeBtn:Dock(LEFT)
        removeBtn:SetWide(160)
        removeBtn:SetText("Remove from Regiment")

        local function getSelectedPlayerData()
            local line = list:GetSelectedLine() and list:GetLine(list:GetSelectedLine())
            return line and line.PlayerData or nil
        end

        promoteBtn.DoClick = function()
            local p = getSelectedPlayerData()
            if not p or not ZEUS.Tablet.SendAction then return end
            ZEUS.Tablet.SendAction("promote_step", p.steamid, "")
        end

        demoteBtn.DoClick = function()
            local p = getSelectedPlayerData()
            if not p or not ZEUS.Tablet.SendAction then return end
            ZEUS.Tablet.SendAction("demote_step", p.steamid, "")
        end

        setRankBtn.DoClick = function()
            local p = getSelectedPlayerData()
            if not p then return end

            local ranks = {}
            if ZEUS.RankIndex then
                for r, idx in pairs(ZEUS.RankIndex) do
                    table.insert(ranks, {name = r, idx = idx})
                end
                table.SortByMember(ranks, "idx", false)
            end

            local w = vgui.Create("DFrame")
            w:SetTitle("Set Rank for " .. (p.name or p.steamid))
            w:SetSize(300, 120)
            w:Center()
            w:MakePopup()

            local combo = vgui.Create("DComboBox", w)
            combo:Dock(TOP)
            combo:DockMargin(10, 30, 10, 5)
            combo:SetValue("Select rank")

            for _, r in ipairs(ranks) do
                combo:AddChoice(r.name)
            end

            local okBtn = vgui.Create("DButton", w)
            okBtn:Dock(BOTTOM)
            okBtn:DockMargin(10, 0, 10, 10)
            okBtn:SetTall(25)
            okBtn:SetText("Apply")

            okBtn.DoClick = function()
                -- DComboBox:GetValue() returns the current text; safer than relying on GetSelected()
                local newRank = combo:GetValue()
                if not newRank or newRank == "" or newRank == "Select rank" then return end
                if ZEUS.Tablet.SendAction then
                    ZEUS.Tablet.SendAction("set_rank", p.steamid, newRank)
                end
                w:Close()
            end
        end

        removeBtn.DoClick = function()
            local p = getSelectedPlayerData()
            if not p then return end

            Derma_Query(
                "Remove " .. (p.name or p.steamid) .. " from regiment (set to CT)?",
                "Confirm Removal",
                "Yes", function()
                    if ZEUS.Tablet.SendAction then
                        ZEUS.Tablet.SendAction("remove_regiment", p.steamid, "")
                    end
                end,
                "No"
            )
        end

        return panel
    end

    local function buildBasicTrainingPanel(parent, cadets)
        local panel = vgui.Create("DPanel", parent)
        panel:Dock(FILL)
        panel:DockMargin(5, 5, 5, 5)

        local list = vgui.Create("DListView", panel)
        list:Dock(FILL)
        list:AddColumn("Name")
        list:AddColumn("SteamID")

        for _, c in ipairs(cadets) do
            local line = list:AddLine(c.name or c.steamid, c.steamid or "")
            line.CadetData = c
        end

        local buttonBar = vgui.Create("DPanel", panel)
        buttonBar:Dock(BOTTOM)
        buttonBar:SetTall(40)
        buttonBar:DockMargin(0, 5, 0, 0)

        local promoteBtn = vgui.Create("DButton", buttonBar)
        promoteBtn:Dock(LEFT)
        promoteBtn:SetWide(200)
        promoteBtn:SetText("Approve & Promote to CT")

        local function getSelectedCadet()
            local line = list:GetSelectedLine() and list:GetLine(list:GetSelectedLine())
            return line and line.CadetData or nil
        end

        promoteBtn.DoClick = function()
            local c = getSelectedCadet()
            if not c then return end

            if ZEUS.Tablet.SendAction then
                ZEUS.Tablet.SendAction("promote_cc_to_ct", c.steamid, "")
            end
        end

        return panel
    end

    function ZEUS.Tablet.OpenUI()
        local incidents       = ZEUS.Tablet.Incidents or {}
        local participants    = ZEUS.Tablet.Participants or {}
        local regimentPlayers = ZEUS.Tablet.RegimentPlayers or {}
        local cadets          = ZEUS.Tablet.Cadets or {}

        if IsValid(ZEUS.Tablet.Frame) then
            ZEUS.Tablet.Frame:Remove()
        end

        local frame = vgui.Create("DFrame")
        frame:SetTitle("ZEUS Command Tablet")
        frame:SetSize(1000, 550)
        frame:Center()
        frame:MakePopup()
        ZEUS.Tablet.Frame = frame

        local sheet = vgui.Create("DPropertySheet", frame)
        sheet:Dock(FILL)
        sheet:DockMargin(5, 5, 5, 5)

        -- Incident Reports tab
        local incidentPanel = buildIncidentPanel(sheet, incidents, participants)
        sheet:AddSheet("Incident Reports", incidentPanel, "icon16/report.png")

        -- Regiment tab (read-only for now)
        local regPanel = buildRegimentPanel(sheet, regimentPlayers)
        sheet:AddSheet("Regiment", regPanel, "icon16/group.png")

        -- Basic Training tab (read-only list of cadets for now)
        local basicPanel = buildBasicTrainingPanel(sheet, cadets)
        sheet:AddSheet("Basic Training", basicPanel, "icon16/user_add.png")
    end
end

if SERVER then
    util.AddNetworkString("ZEUS_Tablet_IncidentData")
    util.AddNetworkString("ZEUS_Tablet_Action")

    local function getRankByIndex(idx)
        if not ZEUS or not ZEUS.RankIndex then return nil end
        for name, i in pairs(ZEUS.RankIndex) do
            if i == idx then
                return name
            end
        end
        return nil
    end

    local function sendIncidentData(ply, incidentId)
        if not ZEUS.Incidents or not sql then
            print("[ZEUS Tablet] sendIncidentData: ZEUS.Incidents or sql not available")
            return
        end

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

            -- Regiment players: filtered by caller's regiment / permissions
            local regimentPlayers = {}
            for _, rp in ipairs(player.GetAll()) do
                if not rp.zeusData then
                    -- Skip players without ZEUS data
                    continue
                end

                local rd = rp.zeusData
                local reg = rd.regiment or ""
                local rank = rd.rank or ""

                -- Staff and high command can see all; others only their own regiment
                local canSeeAll = ZEUS.Util.IsStaff and ZEUS.Util.IsStaff(ply)
                if ZEUS.Config and ZEUS.Config.HighCommandRanks and rd.rank and ZEUS.Config.HighCommandRanks[rd.rank] then
                    canSeeAll = true
                end

                local sameReg = (ply.zeusData and ply.zeusData.regiment == reg)

                if canSeeAll or sameReg then
                    table.insert(regimentPlayers, {
                        steamid = rp:SteamID(),
                        name = rp:Nick(),
                        regiment = reg,
                        rank = rank,
                        rankIndex = (ZEUS.RankIndex and ZEUS.RankIndex[rank]) or 0,
                    })
                end
            end

            net.WriteUInt(#regimentPlayers, 8)
            for _, rp in ipairs(regimentPlayers) do
                net.WriteString(rp.steamid or "")
                net.WriteString(rp.name or "")
                net.WriteString(rp.regiment or "")
                net.WriteString(rp.rank or "")
                net.WriteUInt(rp.rankIndex or 0, 16)
            end

            -- Cadets (CC) for Basic Training view
            local cadets = {}
            local cadetTag = ZEUS.Config and ZEUS.Config.DefaultCadetTag or "CC"

            for _, cp in ipairs(player.GetAll()) do
                if cp.zeusData and cp.zeusData.regiment == cadetTag then
                    table.insert(cadets, {
                        steamid = cp:SteamID(),
                        name = cp:Nick(),
                    })
                end
            end

            net.WriteUInt(#cadets, 8)
            for _, c in ipairs(cadets) do
                net.WriteString(c.steamid or "")
                net.WriteString(c.name or "")
            end
        net.Send(ply)
    end

    net.Receive("ZEUS_Tablet_Action", function(_, ply)
        if not ZEUS or not ZEUS.Identity then return end
        local action = net.ReadString() or ""
        local steamid = net.ReadString() or ""
        local payload = net.ReadString() or ""

        local target = player.GetBySteamID(steamid)
        if not IsValid(target) then return end

        if not canUseTablet(ply) then
            return
        end

        -- Prevent players from changing their own rank or regiment via the tablet
        -- unless they are staff (SAM override). Self-management should go through
        -- proper staff tools, not the field tablet.
        local isStaffOverride = ZEUS.Util.IsStaff and ZEUS.Util.IsStaff(ply)
        local isSelfTarget = (ply == target)

        if isSelfTarget and not isStaffOverride and (action == "set_rank" or action == "promote_step" or action == "demote_step" or action == "remove_regiment") then
            ply:ChatPrint("[ZEUS] You cannot change your own rank or regiment via the tablet.")
            return
        end

        local function applyRankChange(newRank, fromAction)
            if newRank == "" or not ZEUS.Identity.SetRank then return end
            local ok, err = ZEUS.Identity.SetRank(ply, target, newRank)
            if not ok then
                ply:ChatPrint("[ZEUS] " .. (err or "Failed to set rank."))
                return
            end

            -- 2nd LT–CPT promoting above SGT should be logged for approval
            local pRank = ply.zeusData and ply.zeusData.rank or ""
            local tRank = target.zeusData and target.zeusData.rank or newRank

            local upperP = string.upper(pRank or "")
            local upperT = string.upper(tRank or "")

            local isMidOfficer = upperP == "2ND LT" or upperP == "1ST LT" or upperP == "CPT"
            local aboveSGT = upperT ~= "SGT" and upperT ~= "SSG" and upperT ~= "MSG" and upperT ~= "SGM"
            local isStaffOverride = ZEUS.Util.IsStaff and ZEUS.Util.IsStaff(ply)

            if isMidOfficer and aboveSGT and not isStaffOverride then
                print(string.format("[ZEUS] Promotion above SGT by %s (%s) via %s: set %s to %s (requires Major+ review)",
                    pRank, ply:Nick(), fromAction or "tablet", target:Nick(), newRank))
            end
        end

        if action == "set_rank" then
            local newRank = payload
            applyRankChange(newRank, "set_rank")
        elseif action == "promote_step" or action == "demote_step" then
            if not ZEUS.RankIndex then return end
            local currentRank = target.zeusData and target.zeusData.rank or ""
            local idx = ZEUS.RankIndex[currentRank]
            if not idx then
                ply:ChatPrint("[ZEUS] Target has no valid rank to step from.")
                return
            end

            local newIndex = idx
            if action == "promote_step" then
                newIndex = idx + 1
            else
                newIndex = idx - 1
            end

            if newIndex <= 0 then
                ply:ChatPrint("[ZEUS] Cannot demote below lowest rank.")
                return
            end

            local newRank = getRankByIndex(newIndex)
            if not newRank then
                ply:ChatPrint("[ZEUS] No rank defined at that level.")
                return
            end

            applyRankChange(newRank, action)
        elseif action == "remove_regiment" then
            if ZEUS.Identity.SetPreRegiment and ZEUS.Config and ZEUS.Config.DefaultTrooperTag then
                local ok, err = ZEUS.Identity.SetPreRegiment(ply, target, ZEUS.Config.DefaultTrooperTag)
                if not ok then
                    ply:ChatPrint("[ZEUS] " .. (err or "Failed to remove from regiment."))
                end
            end
        elseif action == "promote_cc_to_ct" then
            if ZEUS.Identity.PromoteCCtoCT then
                local ok, err = ZEUS.Identity.PromoteCCtoCT(ply, target)
                if not ok then
                    ply:ChatPrint("[ZEUS] " .. (err or "Failed to promote Cadet to CT."))
                end
            end
        end
    end)

    -- Primary/Secondary attacks must be defined on both realms so SWEP prediction works,
    -- but the incident data is sent directly from the server here.
    function SWEP:PrimaryAttack()
        if CLIENT then return end

        local owner = self:GetOwner()
        if not IsValid(owner) or not owner:IsPlayer() then return end

        print("[ZEUS Tablet] PrimaryAttack by " .. tostring(owner))

        local ok, err = canUseTablet(owner)
        if not ok then
            owner:ChatPrint("[ZEUS] " .. (err or "You are not allowed to use the tablet."))
            print("[ZEUS Tablet] canUseTablet failed for " .. tostring(owner) .. ": " .. tostring(err))
            return
        end

        -- Send latest incident and roster data directly to the owner
        sendIncidentData(owner, nil)
    end
end

function SWEP:SecondaryAttack()
    self:PrimaryAttack()
end