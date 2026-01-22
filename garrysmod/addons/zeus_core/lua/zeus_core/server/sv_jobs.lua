ZEUS = ZEUS or {}
ZEUS.Jobs = ZEUS.Jobs or {}

local Jobs = ZEUS.Jobs
local Util = ZEUS.Util

-- Helper: classify ranks into tiers so we can map them to jobs ----------------

local function normalizeRank(rank)
    rank = string.Trim(rank or "")
    return string.upper(rank)
end

local function isCommanderRank(rank)
    rank = normalizeRank(rank)
    return rank == "COMMANDER"
end

local function isXORank(rank)
    rank = normalizeRank(rank)
    return rank == "EXECUTIVE OFFICER" or rank == "XO"
end

local function isMajorRank(rank)
    rank = normalizeRank(rank)
    return string.find(rank, "MAJ", 1, true) ~= nil
end

local function isOfficerRank(rank)
    rank = normalizeRank(rank)
    if isCommanderRank(rank) or isXORank(rank) or isMajorRank(rank) then return true end

    local officerKeywords = {
        "LT",   -- 2nd LT, 1st LT, etc
        "CPT",
        "LTC",
        "COL",
    }

    for _, kw in ipairs(officerKeywords) do
        if string.find(rank, kw, 1, true) then
            return true
        end
    end

    return false
end

local function isNCORank(rank)
    rank = normalizeRank(rank)
    local ncoKeywords = {
        "SGT", "SSG", "SGM",
        "CPL", "LCPL",
    }

    for _, kw in ipairs(ncoKeywords) do
        if string.find(rank, kw, 1, true) then
            return true
        end
    end

    return false
end

-- Resolve DarkRP team for a given ZEUS regiment+rank -------------------------

function Jobs.GetTeamForIdentity(ply)
    if not IsValid(ply) or not ply.zeusData then return nil end

    local regiment = ply.zeusData.regiment or ""
    local rank = ply.zeusData.rank or ""

    -- Pre-regiments
    if regiment == ZEUS.Config.DefaultCadetTag then
        return TEAM_CADET
    end

    if regiment == ZEUS.Config.DefaultTrooperTag then
        return TEAM_CT
    end

    -- 501st
    if regiment == "501st" then
        if isCommanderRank(rank) and TEAM_501_CMD then return TEAM_501_CMD end
        if isXORank(rank) and TEAM_501_XO then return TEAM_501_XO end
        if isMajorRank(rank) and TEAM_501_MAJOR then return TEAM_501_MAJOR end
        if isOfficerRank(rank) and TEAM_501_OFFICER then return TEAM_501_OFFICER end
        if isNCORank(rank) and TEAM_501_NCO then return TEAM_501_NCO end
        if TEAM_501ST then return TEAM_501ST end
    end

    -- 212th
    if regiment == "212th" then
        if isCommanderRank(rank) and TEAM_212_CMD then return TEAM_212_CMD end
        if isXORank(rank) and TEAM_212_XO then return TEAM_212_XO end
        if isMajorRank(rank) and TEAM_212_MAJOR then return TEAM_212_MAJOR end
        if isOfficerRank(rank) and TEAM_212_OFFICER then return TEAM_212_OFFICER end
        if isNCORank(rank) and TEAM_212_NCO then return TEAM_212_NCO end
        if TEAM_212TH then return TEAM_212TH end
    end

    -- Shock
    if regiment == "Shock" then
        if isCommanderRank(rank) and TEAM_SHOCK_CMD then return TEAM_SHOCK_CMD end
        if isXORank(rank) and TEAM_SHOCK_XO then return TEAM_SHOCK_XO end
        if isMajorRank(rank) and TEAM_SHOCK_MAJOR then return TEAM_SHOCK_MAJOR end
        if isOfficerRank(rank) and TEAM_SHOCK_OFFICER then return TEAM_SHOCK_OFFICER end
        if isNCORank(rank) and TEAM_SHOCK_NCO then return TEAM_SHOCK_NCO end
        if TEAM_SHOCK then return TEAM_SHOCK end
    end

    -- Fallback: keep current team
    return nil
end

function Jobs.ApplyJob(ply)
    if not IsValid(ply) or not ply.zeusData then return end

    local desiredTeam = Jobs.GetTeamForIdentity(ply)
    if not desiredTeam or ply:Team() == desiredTeam then return end
    if not ply.changeTeam then return end

    ply:changeTeam(desiredTeam, true, true, true)
end

-- Hook: auto-apply job on spawn so F4 isn't needed ---------------------------

hook.Add("PlayerSpawn", "ZEUS_Jobs_ApplyOnSpawn", function(ply)
    timer.Simple(0.1, function()
        if not IsValid(ply) then return end
        Jobs.ApplyJob(ply)
    end)
end)

-- Hook: block F4 job changes; ZEUS/SAM handle roles -------------------------

hook.Add("playerCanChangeTeam", "ZEUS_Jobs_BlockF4", function(ply, teamID, force)
    -- Allow forced changes (demotions, Lua), and allow staff to override.
    if force then return end
    if Util.IsStaff and Util.IsStaff(ply) then return end

    -- Block manual job switching from F4/menu.
    ply:ChatPrint("[ZEUS] Jobs are assigned automatically. Speak to your CO or staff for changes.")
    return false
end)