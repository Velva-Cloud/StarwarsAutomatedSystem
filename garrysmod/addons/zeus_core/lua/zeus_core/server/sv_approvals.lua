ZEUS = ZEUS or {}
ZEUS.Approvals = ZEUS.Approvals or {}

local Approvals = ZEUS.Approvals
local Util = ZEUS.Util

local function ensureTable()
    if not sql.TableExists("zeus_approvals") then
        sql.Query([[
            CREATE TABLE IF NOT EXISTS zeus_approvals (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                type TEXT,
                target_steamid TEXT,
                from_regiment TEXT,
                to_regiment TEXT,
                old_rank TEXT,
                new_rank TEXT,
                requested_by_steamid TEXT,
                status TEXT,
                created_at INTEGER,
                resolved_by_steamid TEXT,
                resolved_at INTEGER,
                notes TEXT
            );
        ]])
    end
end

ensureTable()

local function rankIndex(rank)
    return ZEUS.RankIndex and ZEUS.RankIndex[rank or ""] or 0
end

local function isHighOfficer(ply)
    if not ply.zeusData or not ZEUS.RankIndex or not ZEUS.RankIndex["Major"] then return false end
    local r = ply.zeusData.rank
    if not r then return false end
    return rankIndex(r) >= ZEUS.RankIndex["Major"]
end

function Approvals.CreateTransfer(staff, target, toRegiment, newRank)
    ensureTable()
    if not IsValid(staff) or not IsValid(target) then
        return false, "Invalid player."
    end

    target.zeusData = target.zeusData or {}
    staff.zeusData = staff.zeusData or {}

    local sid = Util.SteamID(target)
    local staffSid = Util.SteamID(staff)
    local fromReg = target.zeusData.regiment or ""
    local toReg = toRegiment
    local oldRank = target.zeusData.rank or ""
    local desiredRank = newRank ~= "" and newRank or oldRank

    local now = os.time()

    sql.Query(string.format([[
        INSERT INTO zeus_approvals
            (type, target_steamid, from_regiment, to_regiment, old_rank, new_rank,
             requested_by_steamid, status, created_at, notes)
        VALUES (%s, %s, %s, %s, %s, %s, %s, 'pending', %d, %s);
    ]],
        sql.SQLStr("transfer"),
        sql.SQLStr(sid or ""),
        sql.SQLStr(fromReg or ""),
        sql.SQLStr(toReg or ""),
        sql.SQLStr(oldRank or ""),
        sql.SQLStr(desiredRank or ""),
        sql.SQLStr(staffSid or ""),
        now,
        sql.SQLStr("")
    ))

    return true
end

function Approvals.CreatePromotion(staff, target, newRank)
    ensureTable()
    if not IsValid(staff) or not IsValid(target) then
        return false, "Invalid player."
    end

    target.zeusData = target.zeusData or {}
    staff.zeusData = staff.zeusData or {}

    local sid = Util.SteamID(target)
    local staffSid = Util.SteamID(staff)
    local fromReg = target.zeusData.regiment or ""
    local oldRank = target.zeusData.rank or ""

    if newRank == "" or not newRank then
        return false, "Invalid new rank."
    end

    local now = os.time()

    sql.Query(string.format([[
        INSERT INTO zeus_approvals
            (type, target_steamid, from_regiment, to_regiment, old_rank, new_rank,
             requested_by_steamid, status, created_at, notes)
        VALUES (%s, %s, %s, %s, %s, %s, %s, 'pending', %d, %s);
    ]],
        sql.SQLStr("promotion"),
        sql.SQLStr(sid or ""),
        sql.SQLStr(fromReg or ""),
        sql.SQLStr(fromReg or ""),
        sql.SQLStr(oldRank or ""),
        sql.SQLStr(newRank or ""),
        sql.SQLStr(staffSid or ""),
        now,
        sql.SQLStr("")
    ))

    return true
end

function Approvals.GetPending()
    ensureTable()
    local rows = sql.Query("SELECT * FROM zeus_approvals WHERE status = 'pending' ORDER BY created_at DESC LIMIT 50") or {}
    return rows
end

function Approvals.CanResolve(ply, row)
    if not IsValid(ply) or not row then return false end

    -- Staff can always resolve
    if ZEUS.Util.IsStaff and ZEUS.Util.IsStaff(ply) then
        return true
    end

    ply.zeusData = ply.zeusData or {}
    local plyReg = ply.zeusData.regiment or ""

    if row.type == "transfer" then
        -- Require Major+ in the FROM regiment to approve/deny transfers
        if plyReg == row.from_regiment and isHighOfficer(ply) then
            return true
        end
    elseif row.type == "promotion" then
        -- Allow any Major+ (high officer) to approve promotions across regiments
        if isHighOfficer(ply) then
            return true
        end
    end

    return false
end

function Approvals.Resolve(ply, id, accept)
    ensureTable()
    id = tonumber(id)
    if not id then return false, "Invalid approval id." end

    local rows = sql.Query("SELECT * FROM zeus_approvals WHERE id = " .. id .. " LIMIT 1")
    if not rows or not rows[1] then
        return false, "Approval not found."
    end

    local row = rows[1]
    if row.status ~= "pending" then
        return false, "Approval already resolved."
    end

    if not Approvals.CanResolve(ply, row) then
        return false, "You are not authorised to resolve this approval."
    end

    local now = os.time()
    local sid = Util.SteamID(ply)

    if accept and row.type == "transfer" then
        local target = player.GetBySteamID(row.target_steamid or "")
        if IsValid(target) and ZEUS.Identity and ZEUS.Identity.AssignToRegiment then
            target.zeusData = target.zeusData or {}
            local desiredRank = row.new_rank ~= "" and row.new_rank or (target.zeusData.rank or "PVT")
            local ok, err = ZEUS.Identity.AssignToRegiment(ply, target, row.to_regiment, desiredRank)
            if not ok then
                return false, err or "Failed to complete transfer."
            end
        end
    elseif accept and row.type == "promotion" then
        local target = player.GetBySteamID(row.target_steamid or "")
        if IsValid(target) and ZEUS.Identity and ZEUS.Identity.SetRank then
            local ok, err = ZEUS.Identity.SetRank(ply, target, row.new_rank)
            if not ok then
                return false, err or "Failed to apply promotion."
            end
        end
    end

    sql.Query(string.format([[
        UPDATE zeus_approvals
        SET status = %s,
            resolved_by_steamid = %s,
            resolved_at = %d
        WHERE id = %d;
    ]],
        sql.SQLStr(accept and "approved" or "denied"),
        sql.SQLStr(sid or ""),
        now,
        id
    ))

    return true
end