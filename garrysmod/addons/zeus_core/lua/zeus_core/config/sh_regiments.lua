ZEUS = ZEUS or {}

ZEUS.Regiments = ZEUS.Regiments or {}

-- Special pre-regiment tags
ZEUS.Regiments["CC"] = {
    name = "Cadet",
    isPreRegiment = true,
}

ZEUS.Regiments["CT"] = {
    name = "Clone Trooper",
    isPreRegiment = true,
}

-- Initial regiments
ZEUS.Regiments["501st"] = {
    name = "501st Legion",
}

ZEUS.Regiments["Shock"] = {
    name = "Shock Troopers",
}

ZEUS.Regiments["212th"] = {
    name = "212th Attack Battalion",
}

-- Default rank ladder for regiments
ZEUS.RankLadder = {
    "PVT",
    "PFC",
    "LCPL",
    "CPL",
    "SGT",
    "SSG",
    "MSG",
    "SGM",
    "2nd LT",
    "1st LT",
    "CPT",
    "Major",
    "Executive Officer",
    "Commander",
}

ZEUS.RankIndex = ZEUS.RankIndex or {}
for i, rank in ipairs(ZEUS.RankLadder) do
    ZEUS.RankIndex[rank] = i
end

-- Helper: is rank strictly above SGT?
function ZEUS.RankIsAboveSergeant(rank)
    local idx = ZEUS.RankIndex[rank]
    local sgtIdx = ZEUS.RankIndex["SGT"]
    if not idx or not sgtIdx then return false end
    return idx > sgtIdx
end

-- Helper: is rank at least 2nd LT?
function ZEUS.RankIsOfficer(rank)
    local idx = ZEUS.RankIndex[rank]
    local baseIdx = ZEUS.RankIndex["2nd LT"]
    if not idx or not baseIdx then return false end
    return idx >= baseIdx
end

-- Helper: is rank Major or above?
function ZEUS.RankIsMajorPlus(rank)
    local idx = ZEUS.RankIndex[rank]
    local baseIdx = ZEUS.RankIndex["Major"]
    if not idx or not baseIdx then return false end
    return idx >= baseIdx
end