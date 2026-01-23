ZEUS = ZEUS or {}

local utilTbl = {}

function utilTbl.SteamID(ply)
    if not IsValid(ply) then return nil end
    return ply:SteamID()
end

function utilTbl.Trim(str)
    if not str then return "" end
    return string.Trim(str)
end

function utilTbl.ToLower(str)
    if not str then return "" end
    return string.lower(str)
end

function utilTbl.IsBannedName(name)
    if not ZEUS.Config or not ZEUS.Config.BannedNames then return false end
    local lower = utilTbl.ToLower(name)
    return ZEUS.Config.BannedNames[lower] == true
end

function utilTbl.ValidateChosenName(name)
    if not ZEUS.Config then return false, "Configuration missing" end

    name = utilTbl.Trim(name or "")
    if #name < ZEUS.Config.NameMinLength then
        return false, "Name is too short."
    end

    if #name > ZEUS.Config.NameMaxLength then
        return false, "Name is too long."
    end

    if not string.match(name, ZEUS.Config.NamePattern) then
        return false, "Name must be a single word with letters only."
    end

    if utilTbl.IsBannedName(name) then
        return false, "That name is not allowed."
    end

    return true
end

function utilTbl.FormatID(id)
    if not id then return "0000" end
    return string.format("%04d", tonumber(id) or 0)
end

-- SAM helpers (safe)
function utilTbl.GetSAMGroup(ply)
    if not IsValid(ply) then return nil end
    if sam and sam.player and sam.player.get_bantime then
        -- SAM uses ply:GetUserGroup() as well, but we keep this wrapper
    end
    if ply.GetUserGroup then
        return ply:GetUserGroup()
    end
    return nil
end

function utilTbl.IsStaff(ply)
    if not ZEUS.Config or not ZEUS.Config.StaffGroups then return false end
    local group = utilTbl.GetSAMGroup(ply)
    if not group then return false end
    return ZEUS.Config.StaffGroups[group] == true
end

ZEUS.Util = utilTbl