ZEUS = ZEUS or {}
ZEUS.Medal = ZEUS.Medal or {}

local Medal = ZEUS.Medal
local Util = ZEUS.Util

local function ensureTable()
    if not sql.TableExists("zeus_medals") then
        sql.Query([[
            CREATE TABLE IF NOT EXISTS zeus_medals (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                steamid TEXT,
                code TEXT,
                awarded_by_steamid TEXT,
                awarded_at INTEGER,
                reason TEXT,
                active INTEGER DEFAULT 0
            );
        ]])
    end
end

ensureTable()

-- Award a medal to a player with permissions:
-- MOD/MOS: Major+ in same regiment or staff.
-- COG: HighCommand (Commander/XO) in same regiment or staff.
local function isStaff(ply)
    return ZEUS.Util.IsStaff and ZEUS.Util.IsStaff(ply)
end

local function rankIndex(rank)
    return ZEUS.RankIndex and ZEUS.RankIndex[rank or ""] or 0
end

local function isMajorPlus(ply)
    ply.zeusData = ply.zeusData or {}
    local r = ply.zeusData.rank
    if not r or not ZEUS.RankIndex or not ZEUS.RankIndex["Major"] then return false end
    return rankIndex(r) >= ZEUS.RankIndex["Major"]
end

local function isHighCommand(ply)
    ply.zeusData = ply.zeusData or {}
    local r = ply.zeusData.rank
    if not r then return false end
    return ZEUS.Config and ZEUS.Config.HighCommandRanks and ZEUS.Config.HighCommandRanks[r] or false
end

local function sameRegiment(a, b)
    a = string.Trim(string.lower(a or ""))
    b = string.Trim(string.lower(b or ""))
    return a ~= "" and a == b
end

function Medal.Award(staff, target, code, reason)
    ensureTable()
    if not IsValid(staff) or not IsValid(target) then
        return false, "Invalid player."
    end

    code = string.upper(code or "")
    local def = ZEUS.Medals and ZEUS.Medals[code]
    if not def then
        return false, "Unknown medal code."
    end

    target.zeusData = target.zeusData or {}
    staff.zeusData = staff.zeusData or {}

    -- Only SGT+ can receive medals
    local tRank = target.zeusData.rank or ""
    if ZEUS.RankIndex and ZEUS.RankIndex["SGT"] and rankIndex(tRank) < ZEUS.RankIndex["SGT"] then
        return false, "Target must be SGT or higher to receive medals."
    end

    local staffReg = staff.zeusData.regiment or ""
    local targetReg = target.zeusData.regiment or ""
    local staffIsStaff = isStaff(staff)

    if not staffIsStaff then
        -- Regiment must match
        if not sameRegiment(staffReg, targetReg) then
            return false, "You can only award medals within your own regiment."
        end

        if def.highCommandOnly then
            -- COG: High Command only
            if not isHighCommand(staff) then
                return false, "Only High Command can award this medal."
            end
        else
            -- MOD/MOS: Major+ or above
            if not isMajorPlus(staff) then
                return false, "You must be Major+ to award this medal."
            end
        end
    end

    local sid = Util.SteamID(target)
    local staffSid = Util.SteamID(staff)
    if not sid then return false, "Target has no SteamID." end

    reason = string.Trim(reason or "")
    local now = os.time()

    sql.Query(string.format([[
        INSERT INTO zeus_medals (steamid, code, awarded_by_steamid, awarded_at, reason, active)
        VALUES (%s, %s, %s, %d, %s, 0);
    ]],
        sql.SQLStr(sid),
        sql.SQLStr(code),
        sql.SQLStr(staffSid or ""),
        now,
        sql.SQLStr(reason)
    ))

    return true
end

function Medal.GetAll(steamid)
    ensureTable()
    if not steamid or steamid == "" then return {} end

    local rows = sql.Query(string.format([[
        SELECT id, steamid, code, awarded_by_steamid, awarded_at, reason, active
        FROM zeus_medals
        WHERE steamid = %s
        ORDER BY awarded_at DESC;
    ]], sql.SQLStr(steamid))) or {}

    return rows
end

function Medal.GetActiveTags(steamid)
    ensureTable()
    if not steamid or steamid == "" then return {} end

    local rows = sql.Query(string.format([[
        SELECT code
        FROM zeus_medals
        WHERE steamid = %s AND active = 1
        ORDER BY awarded_at ASC
        LIMIT 3;
    ]], sql.SQLStr(steamid))) or {}

    local tags = {}
    for _, r in ipairs(rows) do
        table.insert(tags, r.code or "")
    end
    return tags
end

-- codes is a table of medal codes (MOD/COG/MOS) to set active, max 3.
function Medal.SetActive(caller, steamid, codes)
    ensureTable()
    if not IsValid(caller) then return false, "Invalid caller." end
    if not steamid or steamid == "" then return false, "Invalid target." end

    local target = player.GetBySteamID(steamid)
    local isSelf = IsValid(target) and caller == target
    local callerIsStaff = isStaff(caller)
    caller.zeusData = caller.zeusData or {}

    -- Load target regiment/rank from live data if available
    local targetReg, targetRank
    if IsValid(target) and target.zeusData then
        targetReg = target.zeusData.regiment or ""
        targetRank = target.zeusData.rank or ""
    end

    -- If self: must be SGT+
    if isSelf and not callerIsStaff then
        if ZEUS.RankIndex and ZEUS.RankIndex["SGT"] and rankIndex(caller.zeusData.rank or "") < ZEUS.RankIndex["SGT"] then
            return false, "You must be SGT or higher to configure your medals."
        end
    end

    -- If configuring someone else: must be staff or Major+ in same regiment
    if (not isSelf) and not callerIsStaff then
        if not targetReg then
            return false, "Target has no regiment data."
        end
        if not sameRegiment(caller.zeusData.regiment or "", targetReg) then
            return false, "You can only configure medals within your own regiment."
        end
        if not isMajorPlus(caller) then
            return false, "You must be Major+ to configure others' medals."
        end
    end

    -- Normalise codes -> set of up to 3 unique medal codes
    local wanted = {}
    local count = 0
    for _, code in ipairs(codes or {}) do
        code = string.upper(string.Trim(code or ""))
        if ZEUS.Medals and ZEUS.Medals[code] and not wanted[code] then
            count = count + 1
            wanted[code] = true
            if count >= 3 then break end
        end
    end

    -- Clear all actives
    sql.Query(string.format([[
        UPDATE zeus_medals
        SET active = 0
        WHERE steamid = %s;
    ]], sql.SQLStr(steamid)))

    if count == 0 then
        return true
    end

    -- Activate those codes in order of award
    for code, _ in pairs(wanted) do
        sql.Query(string.format([[
            UPDATE zeus_medals
            SET active = 1
            WHERE steamid = %s AND code = %s;
        ]],
            sql.SQLStr(steamid),
            sql.SQLStr(code)
        ))
    end

    return true
end