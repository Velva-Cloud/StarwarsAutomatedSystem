ZEUS = ZEUS or {}
ZEUS.Config = ZEUS.Config or {}

-- Staff groups for ZEUS presence and permissions (SAM group names)
ZEUS.Config.StaffGroups = {
    superadmin = true,
    admin = true,
    moderator = true,
    trialmod = true,
}

-- Number of staff required for ZEUS to be considered "watching"
ZEUS.Config.ZeusStaffThreshold = 2

-- Default starting tags
ZEUS.Config.DefaultCadetTag = "CC"
ZEUS.Config.DefaultTrooperTag = "CT"

-- Name validation
ZEUS.Config.NameMinLength = 3
ZEUS.Config.NameMaxLength = 16
-- Only a single word, letters only (no spaces, numbers, underscores)
ZEUS.Config.NamePattern = "^[A-Za-z]+$"

-- Simple rude-word blacklist, extend as needed
ZEUS.Config.BannedNames = {
    ["fuck"] = true,
    ["shit"] = true,
    ["bitch"] = true,
    ["cunt"] = true,
    ["nigger"] = true,
    ["nigga"] = true,
    ["retard"] = true,
}

-- XP config
ZEUS.Config.XPPerMinute = 10
ZEUS.Config.XPPerKill = 5

-- High command ranks (can see all regiments in incident tools, award COG, approve high-level actions)
ZEUS.Config.HighCommandRanks = {
    ["Executive Officer"] = true,
    ["Commander"] = true,
}

-- Global medals configuration (placeholders, used by backend + UI)
ZEUS.Medals = {
    MOD = { code = "MOD", name = "Medal of Honour" },
    COG = { code = "COG", name = "Cross of Glory", highCommandOnly = true },
    MOS = { code = "MOS", name = "Medallion of Service" },
}

-- Scoreboard settings
ZEUS.Config.ScoreboardTitle = "ZEUS Operations"