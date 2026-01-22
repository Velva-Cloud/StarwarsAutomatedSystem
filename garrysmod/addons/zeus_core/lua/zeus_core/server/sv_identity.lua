ZEUS = ZEUS or {}
ZEUS.Identity = ZEUS.Identity or {}

local Identity = ZEUS.Identity
local Util = ZEUS.Util

local PLAYER = FindMetaTable("Player")

local function ensureTables()
    if not sql.TableExists("zeus_players") then
        sql.Query([[
            CREATE TABLE IF NOT EXISTS zeus_players (
                steamid TEXT PRIMARY KEY,
                char_id INTEGER UNIQUE,
                regiment TEXT,
                rank TEXT,
                chosen_name TEXT,
                xp INTEGER DEFAULT 0
            );
        ]])
    end

    if not sql.TableExists("zeus_meta") then
        sql.Query([[
            CREATE TABLE IF NOT EXISTS zeus_meta (
                key TEXT PRIMARY KEY,
                value TEXT
            );
        ]])
    end
end

local function getMeta(key)
    local res = sql.QueryRow("SELECT value FROM zeus_meta WHERE key = " .. sql.SQLStr(key))
    if not res then return nil end
    return res.value
end

local function setMeta(key, value)
    sql.Query("REPLACE INTO zeus_meta (key, value) VALUES (" .. sql.SQLStr(key) .. ", " .. sql.SQLStr(tostring(value)) .. ")")
end

local function allocateCharID()
    local nextStr = getMeta("next_char_id")
    local nextID = tonumber(nextStr) or 1
    local assigned = nextID
    setMeta("next_char_id", assigned + 1)
    return assigned
end

function Identity.LoadPlayer(ply)
    ensureTables()
    local sid = Util.SteamID(ply)
    if not sid then return end

    local row = sql.QueryRow("SELECT * FROM zeus_players WHERE steamid = " .. sql.SQLStr(sid))

    if not row then
        -- First time join: create cadet entry
        local newID = allocateCharID()
        local regiment = ZEUS.Config.DefaultCadetTag or "CC"

        sql.Query(string.format([[
            INSERT INTO zeus_players (steamid, char_id, regiment, rank, chosen_name, xp)
            VALUES (%s, %d, %s, %s, %s, %d);
        ]],
            sql.SQLStr(sid),
            newID,
            sql.SQLStr(regiment),
            "NULL",
            sql.SQLStr(""),
            0
        ))

        row = sql.QueryRow("SELECT * FROM zeus_players WHERE steamid = " .. sql.SQLStr(sid))
    end

    ply.zeusData = {
        steamid = row.steamid,
        char_id = tonumber(row.char_id),
        regiment = row.regiment,
        rank = row.rank ~= "NULL" and row.rank or nil,
        chosen_name = row.chosen_name ~= "" and row.chosen_name or nil,
        xp = tonumber(row.xp) or 0,
    }

    Identity.ApplyRPName(ply)
    Identity.SyncToClient(ply)
end

function Identity.SavePlayer(ply)
    if not IsValid(ply) or not ply.zeusData then return end
    local d = ply.zeusData
    ensureTables()

    sql.Query(string.format([[
        REPLACE INTO zeus_players (steamid, char_id, regiment, rank, chosen_name, xp)
        VALUES (%s, %d, %s, %s, %s, %d);
    ]],
        sql.SQLStr(d.steamid),
        d.char_id or 0,
        sql.SQLStr(d.regiment or ZEUS.Config.DefaultCadetTag or "CC"),
        d.rank and sql.SQLStr(d.rank) or "NULL",
        sql.SQLStr(d.chosen_name or ""),
        d.xp or 0
    ))
end

hook.Add("PlayerInitialSpawn", "ZEUS_Identity_Load", function(ply)
    Identity.LoadPlayer(ply)
end)

hook.Add("PlayerDisconnected", "ZEUS_Identity_Save", function(ply)
    Identity.SavePlayer(ply)
end)

hook.Add("ShutDown", "ZEUS_Identity_SaveAll", function()
    for _, ply in ipairs(player.GetAll()) do
        Identity.SavePlayer(ply)
    end
end)

function Identity.FormatNameData(data)
    local id = Util.FormatID(data.char_id)

    if data.regiment == ZEUS.Config.DefaultCadetTag or data.regiment == ZEUS.Config.DefaultTrooperTag then
        return string.format("%s %s %s",
            data.regiment or "CC",
            id,
            data.chosen_name or "Clone"
        )
    end

    return string.format("%s %s %s %s",
        data.regiment or "CT",
        id,
        data.rank or "PVT",
        data.chosen_name or "Clone"
    )
end

function Identity.FormatName(ply)
    if not ply.zeusData then return ply:Nick() end
    return Identity.FormatNameData(ply.zeusData)
end

function PLAYER:ZEUSFormattedName()
    return Identity.FormatName(self)
end

-- DarkRP/StarwarsRP name integration
function Identity.ApplyRPName(ply)
    if not ply.zeusData then return end
    local newName = Identity.FormatName(ply)

    if DarkRP and DarkRP.nickAllowed and DarkRP.nickAllowed(ply, newName) then
        ply:setRPName(newName)
    elseif ply.setDarkRPVar then
        ply:setDarkRPVar("rpname", newName)
    end
end

-- Set chosen name after validation
function Identity.SetChosenName(ply, name)
    if not IsValid(ply) then return false, "Invalid player" end
    local ok, err = Util.ValidateChosenName(name)
    if not ok then return false, err end

    ply.zeusData = ply.zeusData or {}
    ply.zeusData.chosen_name = name

    Identity.ApplyRPName(ply)
    Identity.SyncToClient(ply)
    Identity.SavePlayer(ply)

    return true
end

-- Promotion helpers

local function getRankIndex(rank)
    return ZEUS.RankIndex[rank or ""] or 0
end

-- Map ZEUS regiment tags to DarkRP teams (if they exist)
local function getTeamForRegiment(regiment)
    if not RPExtraTeams then return nil end

    if regiment == ZEUS.Config.DefaultCadetTag then
        return TEAM_CADET
    elseif regiment == ZEUS.Config.DefaultTrooperTag then
        return TEAM_CT
    elseif regiment == "501st" then
        return TEAM_501ST
    elseif regiment == "Shock" then
        return TEAM_SHOCK
    elseif regiment == "212th" then
        return TEAM_212TH
    end

    return nil
end

local function safeChangeTeam(ply, teamID)
    if not teamID or not ply.changeTeam then return end
    ply:changeTeam(teamID, true, true, true)
end

-- Set a player's regiment to a pre-regiment tag (CC/CT) and update job/name
function Identity.SetPreRegiment(staff, target, tag)
    if not IsValid(staff) or not IsValid(target) then return false, "Invalid player" end
    if tag ~= ZEUS.Config.DefaultCadetTag and tag ~= ZEUS.Config.DefaultTrooperTag then
        return false, "Invalid pre-regiment tag."
    end

    local isStaffOverride = ZEUS.Util.IsStaff and ZEUS.Util.IsStaff(staff)

    -- Allow Major+ (and equivalent) to force CC/CT as well as staff.
    local sRank = staff.zeusData and staff.zeusData.rank
    local isHighOfficer = false
    if ZEUS.RankIndex and sRank and ZEUS.RankIndex["Major"] and ZEUS.RankIndex[sRank] then
        isHighOfficer = ZEUS.RankIndex[sRank] >= ZEUS.RankIndex["Major"]
    end

    if not isStaffOverride and not isHighOfficer then
        return false, "Only staff or Major+ can directly set CC/CT."
    end

    target.zeusData = target.zeusData or {}
    target.zeusData.regiment = tag

    -- When going back to CC, clear rank so they behave like a Cadet again
    if tag == ZEUS.Config.DefaultCadetTag then
        target.zeusData.rank = nil
    end

    local teamID = getTeamForRegiment(tag)
    if teamID then
        safeChangeTeam(target, teamID)
    end

    Identity.ApplyRPName(target)
    Identity.SyncToClient(target)
    Identity.SavePlayer(target)

    return true
end

-- Staff tool: reset a player's chosen name and immediately prompt again
function Identity.ResetName(staff, target)
    if not IsValid(target) then return false, "Invalid target player" end

    local isStaffOverride = IsValid(staff) and ZEUS.Util.IsStaff and ZEUS.Util.IsStaff(staff)
    if not isStaffOverride then
        return false, "Only staff can reset names."
    end

    target.zeusData = target.zeusData or {}
    target.zeusData.chosen_name = nil

    Identity.ApplyRPName(target)
    Identity.SyncToClient(target)
    Identity.SavePlayer(target)

    -- Ask client for a new name right away
    net.Start("ZEUS_Identity_RequestName")
    net.Send(target)

    print(string.format("[ZEUS] Reset name for %s (%s)", target:Nick(), target:SteamID()))

    return true
end

function Identity.CanPromoteCCtoCT(staffRank)
    return ZEUS.RankIsAboveSergeant(staffRank)
end

function Identity.CanPromoteOthers(staffRank)
    return ZEUS.RankIsOfficer(staffRank)
end

function Identity.PromoteCCtoCT(staff, target)
    if not IsValid(staff) or not IsValid(target) then return false, "Invalid player" end
    if not target.zeusData then return false, "Target has no identity data" end

    local sRank = staff.zeusData and staff.zeusData.rank
    local isStaffOverride = ZEUS.Util.IsStaff and ZEUS.Util.IsStaff(staff)
    if (not sRank or not Identity.CanPromoteCCtoCT(sRank)) and not isStaffOverride then
        return false, "You are not high enough rank to promote Cadets."
    end

    if target.zeusData.regiment ~= ZEUS.Config.DefaultCadetTag then
        return false, "Target is not a Cadet."
    end

    target.zeusData.regiment = ZEUS.Config.DefaultTrooperTag

    -- Change DarkRP job to Clone Trooper if that team exists
    local teamID = getTeamForRegiment(ZEUS.Config.DefaultTrooperTag)
    if teamID then
        safeChangeTeam(target, teamID)
    end

    Identity.ApplyRPName(target)
    Identity.SyncToClient(target)
    Identity.SavePlayer(target)

    return true
end

function Identity.AssignToRegiment(staff, target, regimentKey, startingRank)
    if not IsValid(staff) or not IsValid(target) then return false, "Invalid player" end
    if not ZEUS.Regiments[regimentKey] or ZEUS.Regiments[regimentKey].isPreRegiment then
        return false, "Invalid regiment."
    end

    -- Officers normally handle regiment assignment, but SAM-admins override.
    local sRank = staff.zeusData and staff.zeusData.rank
    local isStaffOverride = ZEUS.Util.IsStaff and ZEUS.Util.IsStaff(staff)
    if not isStaffOverride and (not sRank or not Identity.CanPromoteOthers(sRank)) then
        return false, "You are not high enough rank to assign regiments."
    end

    target.zeusData = target.zeusData or {}
    target.zeusData.regiment = regimentKey
    target.zeusData.rank = startingRank or "PVT"

    -- Let ZEUS job system handle the exact job based on regiment+rank
    if ZEUS.Jobs and ZEUS.Jobs.ApplyJob then
        ZEUS.Jobs.ApplyJob(target)
    else
        -- Fallback: basic team per regiment
        local teamID = getTeamForRegiment(regimentKey)
        if teamID then
            safeChangeTeam(target, teamID)
        end
    end

    Identity.ApplyRPName(target)
    Identity.SyncToClient(target)
    Identity.SavePlayer(target)

    return true
end

function Identity.SetRank(staff, target, newRank)
    if not IsValid(staff) or not IsValid(target) then return false, "Invalid player" end
    if not ZEUS.RankIndex[newRank] then return false, "Invalid rank." end

    local sRank = staff.zeusData and staff.zeusData.rank
    local isStaffOverride = ZEUS.Util.IsStaff and ZEUS.Util.IsStaff(staff)
    if not isStaffOverride and (not sRank or getRankIndex(sRank) <= getRankIndex(newRank)) then
        return false, "You cannot set rank equal or above your own."
    end

    target.zeusData = target.zeusData or {}
    target.zeusData.rank = newRank

    -- Immediately update job to match new rank/regiment
    if ZEUS.Jobs and ZEUS.Jobs.ApplyJob then
        ZEUS.Jobs.ApplyJob(target)
    end

    Identity.ApplyRPName(target)
    Identity.SyncToClient(target)
    Identity.SavePlayer(target)

    return true
end

-- Networking

util.AddNetworkString("ZEUS_Identity_Full")
util.AddNetworkString("ZEUS_Identity_RequestName")

function Identity.SyncToClient(ply)
    if not IsValid(ply) or not ply.zeusData then return end

    net.Start("ZEUS_Identity_Full")
        net.WriteUInt(ply.zeusData.char_id or 0, 16)
        net.WriteString(ply.zeusData.regiment or "")
        net.WriteString(ply.zeusData.rank or "")
        net.WriteString(ply.zeusData.chosen_name or "")
        net.WriteInt(ply.zeusData.xp or 0, 32)
    net.Send(ply)
end

-- Also send a full identity snapshot when the player actually spawns so
-- the client HUD has data immediately rather than waiting for XP ticks.
hook.Add("PlayerSpawn", "ZEUS_Identity_SyncOnSpawn", function(ply)
    if ZEUS and ZEUS.Identity and ZEUS.Identity.SyncToClient then
        ZEUS.Identity.SyncToClient(ply)
    end
end)

-- On spawn, ensure RP name is enforced and if no chosen_name, ask client for it
hook.Add("PlayerSpawn", "ZEUS_Identity_OnSpawn", function(ply)
    timer.Simple(2, function()
        if not IsValid(ply) or not ply.zeusData then return end

        -- Force the ZEUS-formatted RP name in case other addons changed it
        Identity.ApplyRPName(ply)

        if ply.zeusData.chosen_name and ply.zeusData.chosen_name ~= "" then return end

        net.Start("ZEUS_Identity_RequestName")
        net.Send(ply)
    end)
end)

-- Receive chosen name from client
util.AddNetworkString("ZEUS_Identity_SetName")

net.Receive("ZEUS_Identity_SetName", function(len, ply)
    local name = net.ReadString() or ""
    local ok, err = Identity.SetChosenName(ply, name)
    if not ok and err then
        ply:ChatPrint("[ZEUS] " .. err)
        net.Start("ZEUS_Identity_RequestName")
        net.Send(ply)
    end
end)

-- SAM commands are registered in zeus_core/shared/sh_sam_commands.lua so that
-- both server and client are aware of them for the SAM menu. No SAM-specific
-- code is needed here anymore.