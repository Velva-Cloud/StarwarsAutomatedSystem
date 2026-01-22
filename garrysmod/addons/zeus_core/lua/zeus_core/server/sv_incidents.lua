ZEUS = ZEUS or {}
ZEUS.Incidents = ZEUS.Incidents or {}

local Incidents = ZEUS.Incidents
local Util = ZEUS.Util

util.AddNetworkString("ZEUS_Incident_Status")

-- SQLite helpers ------------------------------------------------------------

local function ensureTables()
    if not sql.TableExists("zeus_incidents") then
        sql.Query([[
            CREATE TABLE IF NOT EXISTS zeus_incidents (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT,
                started_at INTEGER,
                ended_at INTEGER,
                created_by_steamid TEXT
            );
        ]])
    end

    if not sql.TableExists("zeus_incident_participants") then
        sql.Query([[
            CREATE TABLE IF NOT EXISTS zeus_incident_participants (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                incident_id INTEGER,
                steamid TEXT,
                regiment TEXT,
                rank TEXT,
                time_present INTEGER,
                kills INTEGER,
                deaths INTEGER,
                notes TEXT
            );
        ]])
    end
end

ensureTables()

-- Runtime state -------------------------------------------------------------

Incidents.ActiveIncident = Incidents.ActiveIncident or nil
Incidents.Participants = Incidents.Participants or {} -- steamid -> data

local function broadcastIncidentStatus()
    if Incidents.ActiveIncident then
        net.Start("ZEUS_Incident_Status")
            net.WriteBool(true)
            net.WriteString(Incidents.ActiveIncident.name or "")
        net.Broadcast()
    else
        net.Start("ZEUS_Incident_Status")
            net.WriteBool(false)
            net.WriteString("")
        net.Broadcast()
    end
end

local function addOrUpdateParticipant(ply)
    if not Incidents.ActiveIncident then return end
    if not IsValid(ply) or not ply.zeusData then return end

    local sid = Util.SteamID(ply)
    if not sid then return end

    local p = Incidents.Participants[sid]
    if not p then
        p = {
            steamid = sid,
            regiment = ply.zeusData.regiment or "",
            rank = ply.zeusData.rank or "",
            joined_at = os.time(),
            time_present = 0,
            kills = 0,
            deaths = 0,
            notes = "",
        }
        Incidents.Participants[sid] = p
    else
        -- Update regiment/rank in case they changed mid-incident
        p.regiment = ply.zeusData.regiment or p.regiment
        p.rank = ply.zeusData.rank or p.rank
    end
end

local function finalizeParticipant(p, ended_at)
    if not p.joined_at then return end
    local now = ended_at or os.time()
    local delta = math.max(0, now - (p.joined_at or now))
    p.time_present = (p.time_present or 0) + delta
    p.joined_at = now
end

-- Public API ----------------------------------------------------------------

function Incidents.StartIncident(staff, name)
    if not IsValid(staff) then return false, "Invalid staff." end
    name = string.Trim(name or "")
    if name == "" then return false, "Incident name required." end

    if Incidents.ActiveIncident then
        return false, "There is already an active incident."
    end

    ensureTables()

    local sid = Util.SteamID(staff) or "CONSOLE"
    local now = os.time()

    sql.Query(string.format([[
        INSERT INTO zeus_incidents (name, started_at, ended_at, created_by_steamid)
        VALUES (%s, %d, NULL, %s);
    ]],
        sql.SQLStr(name),
        now,
        sql.SQLStr(sid)
    ))

    local row = sql.QueryRow("SELECT last_insert_rowid() AS id;")
    local id = row and tonumber(row.id) or nil
    if not id then
        return false, "Failed to create incident in database."
    end

    Incidents.ActiveIncident = {
        id = id,
        name = name,
        started_at = now,
    }

    table.Empty(Incidents.Participants)
    for _, ply in ipairs(player.GetAll()) do
        addOrUpdateParticipant(ply)
    end

    broadcastIncidentStatus()

    return true
end

function Incidents.EndIncident(staff)
    if not Incidents.ActiveIncident then
        return false, "There is no active incident."
    end

    ensureTables()

    local active = Incidents.ActiveIncident
    local now = os.time()

    -- Finalize all participants and write them to DB
    for sid, p in pairs(Incidents.Participants) do
        finalizeParticipant(p, now)

        sql.Query(string.format([[
            INSERT INTO zeus_incident_participants
                (incident_id, steamid, regiment, rank, time_present, kills, deaths, notes)
            VALUES (%d, %s, %s, %s, %d, %d, %d, %s);
        ]],
            active.id,
            sql.SQLStr(p.steamid or sid),
            sql.SQLStr(p.regiment or ""),
            sql.SQLStr(p.rank or ""),
            p.time_present or 0,
            p.kills or 0,
            p.deaths or 0,
            sql.SQLStr(p.notes or "")
        ))
    end

    -- Update incident end time
    sql.Query(string.format([[
        UPDATE zeus_incidents
        SET ended_at = %d
        WHERE id = %d;
    ]],
        now,
        active.id
    ))

    Incidents.ActiveIncident = nil
    table.Empty(Incidents.Participants)

    broadcastIncidentStatus()

    return true
end

function Incidents.AddNote(staff, target, note)
    if not Incidents.ActiveIncident then
        return false, "There is no active incident."
    end

    if not IsValid(staff) or not IsValid(target) then
        return false, "Invalid player."
    end

    note = string.Trim(note or "")
    if note == "" then
        return false, "Note cannot be empty."
    end

    local sid = Util.SteamID(target)
    if not sid then return false, "Target has no SteamID." end

    addOrUpdateParticipant(target)

    local p = Incidents.Participants[sid]
    if not p then return false, "Participant not tracked." end

    if p.notes == "" then
        p.notes = note
    else
        p.notes = p.notes .. " | " .. note
    end

    return true
end

-- Hooks to keep participants updated ---------------------------------------

hook.Add("PlayerInitialSpawn", "ZEUS_Incidents_OnJoin", function(ply)
    if Incidents.ActiveIncident then
        addOrUpdateParticipant(ply)
    end
end)

hook.Add("PlayerDisconnected", "ZEUS_Incidents_OnLeave", function(ply)
    if not Incidents.ActiveIncident then return end
    if not IsValid(ply) or not ply.zeusData then return end

    local sid = Util.SteamID(ply)
    if not sid then return end

    local p = Incidents.Participants[sid]
    if not p then return end

    finalizeParticipant(p, os.time())
end)

-- Track kills/deaths during incident

hook.Add("PlayerDeath", "ZEUS_Incidents_Deaths", function(victim, inflictor, attacker)
    if not Incidents.ActiveIncident then return end

    if IsValid(victim) and victim:IsPlayer() then
        local sid = Util.SteamID(victim)
        if sid then
            addOrUpdateParticipant(victim)
            local p = Incidents.Participants[sid]
            if p then
                p.deaths = (p.deaths or 0) + 1
            end
        end
    end

    if IsValid(attacker) and attacker:IsPlayer() and attacker ~= victim then
        local sid = Util.SteamID(attacker)
        if sid then
            addOrUpdateParticipant(attacker)
            local p = Incidents.Participants[sid]
            if p then
                p.kills = (p.kills or 0) + 1
            end
        end
    end
end)

-- Periodic presence update (time_present)

timer.Create("ZEUS_Incidents_Tick", 30, 0, function()
    if not Incidents.ActiveIncident then return end

    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply.zeusData then
            local sid = Util.SteamID(ply)
            if sid then
                addOrUpdateParticipant(ply)
                local p = Incidents.Participants[sid]
                if p then
                    p.time_present = (p.time_present or 0) + 30
                end
            end
        end
    end
end)