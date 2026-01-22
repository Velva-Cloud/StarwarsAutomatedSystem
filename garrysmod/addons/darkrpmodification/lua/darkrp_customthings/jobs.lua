--[[---------------------------------------------------------------------------
DarkRP custom jobs
---------------------------------------------------------------------------
This file contains your custom jobs.
This file should also contain jobs from DarkRP that you edited.

Note: If you want to edit a default DarkRP job, first disable it in darkrp_config/disabled_defaults.lua
      Once you've done that, copy and paste the job to this file and edit it.

The default jobs can be found here:
https://github.com/FPtje/DarkRP/blob/master/gamemode/config/jobrelated.lua

For examples and explanation please visit this wiki page:
https://darkrp.miraheze.org/wiki/DarkRP:CustomJobFields

Add your custom jobs under the following line:
---------------------------------------------------------------------------]]



--[[---------------------------------------------------------------------------
High Command
---------------------------------------------------------------------------]]

TEAM_SUPREMEMARSHAL = DarkRP.createJob("Supreme Marshal", {
    color = Color(120, 20, 120, 255),
    model = {
        "models/nada/purgetroopercommander.mdl",
        "models/nada/purgetrooperelectrobaton.mdl",
        "models/nada/purgetrooperelectrohammer.mdl",
        "models/nada/purgetrooperelectrostaff.mdl",
    },
    description = [[Out-of-character highest staff position. Only the owner/superadmin may hold this job.]],
    weapons = {}, -- default weapons only
    command = "suprememarshal",
    max = 1,
    salary = 0,
    admin = 2, -- superadmin only
    vote = false,
    hasLicense = false,
    category = "High Command",
    maxHealth = 1500,
    maxArmor = 500,
})

TEAM_MARSHAL = DarkRP.createJob("Marshal", {
    color = Color(150, 40, 150, 255),
    model = {
        "models/nada/purgetroopercommander.mdl",
        "models/nada/purgetrooperelectrobaton.mdl",
        "models/nada/purgetrooperelectrohammer.mdl",
        "models/nada/purgetrooperelectrostaff.mdl",
    },
    description = [[High staff leadership role for other superadmins.]],
    weapons = {}, -- default weapons only
    command = "marshal",
    max = 3,
    salary = 0,
    admin = 2, -- superadmin only
    vote = false,
    hasLicense = false,
    category = "High Command",
    maxHealth = 1200,
    maxArmor = 500,
})

--[[---------------------------------------------------------------------------
Clones (CT / Cadet)
---------------------------------------------------------------------------]]

-- Cadet (default spawn)
TEAM_CADET = DarkRP.createJob("Cadet", {
    color = Color(150, 150, 255, 255),
    model = {
        "models/player/clone cadet/clonecadet.mdl",
    },
    description = [[New recruits undergoing basic training.]],
    weapons = {}, -- default weapons only
    command = "cadet",
    max = 0,
    salary = 0,
    admin = 0,
    vote = false,
    hasLicense = false,
    category = "Clones",
    maxHealth = 150,
    maxArmor = 0,
})

-- Clone Trooper (unassigned CT)
TEAM_CT = DarkRP.createJob("Clone Trooper", {
    color = Color(120, 120, 255, 255),
    model = {
        "models/aussiwozzi/cgi/base/unassigned_trp.mdl",
    },
    description = [[Fully trained clone trooper without assigned regiment.]],
    weapons = {}, -- default weapons only
    command = "ct",
    max = 0,
    salary = 0,
    admin = 0,
    vote = false,
    hasLicense = false,
    category = "Clones",
    maxHealth = 300,
    maxArmor = 0,
})

--[[---------------------------------------------------------------------------
501st Legion
---------------------------------------------------------------------------]]

TEAM_501_CMD = DarkRP.createJob("501st Commander", {
    color = Color(50, 100, 255, 255),
    model = {
        "models/aussiwozzi/cgi/base/501st_officer.mdl",
        "models/aussiwozzi/cgi/base/501st_rex.mdl",
        "models/aussiwozzi/cgi/base/501st_sarge.mdl",
        "models/aussiwozzi/cgi/base/501st_torrent_officer.mdl",
        "models/aussiwozzi/cgi/base/501st_trooper.mdl",
        "models/aussiwozzi/cgi/base/501st_vaughn.mdl",
    },
    description = [[Commanding officer of the 501st Legion.]],
    weapons = {}, -- default weapons only
    command = "501cmd",
    max = 1,
    salary = 0,
    admin = 0,
    vote = false,
    hasLicense = false,
    category = "501st",
    maxHealth = 800,
    maxArmor = 200,
})

TEAM_501_XO = DarkRP.createJob("501st Executive Officer", {
    color = Color(60, 110, 255, 255),
    model = {
        "models/aussiwozzi/cgi/base/501st_officer.mdl",
        "models/aussiwozzi/cgi/base/501st_rex.mdl",
        "models/aussiwozzi/cgi/base/501st_sarge.mdl",
        "models/aussiwozzi/cgi/base/501st_torrent_officer.mdl",
        "models/aussiwozzi/cgi/base/501st_trooper.mdl",
        "models/aussiwozzi/cgi/base/501st_vaughn.mdl",
    },
    description = [[Executive officer of the 501st Legion.]],
    weapons = {}, -- default weapons only
    command = "501xo",
    max = 1,
    salary = 0,
    admin = 0,
    vote = false,
    hasLicense = false,
    category = "501st",
    maxHealth = 750,
    maxArmor = 175,
})

TEAM_501_MAJOR = DarkRP.createJob("501st Major", {
    color = Color(70, 120, 255, 255),
    model = {
        "models/aussiwozzi/cgi/base/501st_officer.mdl",
        "models/aussiwozzi/cgi/base/501st_rex.mdl",
        "models/aussiwozzi/cgi/base/501st_sarge.mdl",
        "models/aussiwozzi/cgi/base/501st_torrent_officer.mdl",
        "models/aussiwozzi/cgi/base/501st_trooper.mdl",
        "models/aussiwozzi/cgi/base/501st_vaughn.mdl",
    },
    description = [[Field officer of the 501st Legion.]],
    weapons = {}, -- default weapons only
    command = "501major",
    max = 2,
    salary = 0,
    admin = 0,
    vote = false,
    hasLicense = false,
    category = "501st",
    maxHealth = 700,
    maxArmor = 150,
})

TEAM_501_OFFICER = DarkRP.createJob("501st Officer", {
    color = Color(80, 130, 255, 255),
    model = {
        "models/aussiwozzi/cgi/base/501st_officer.mdl",
        "models/aussiwozzi/cgi/base/501st_rex.mdl",
        "models/aussiwozzi/cgi/base/501st_sarge.mdl",
        "models/aussiwozzi/cgi/base/501st_torrent_officer.mdl",
        "models/aussiwozzi/cgi/base/501st_trooper.mdl",
    },
    description = [[Officer of the 501st Legion.]],
    weapons = {}, -- default weapons only
    command = "501officer",
    max = 4,
    salary = 0,
    admin = 0,
    vote = false,
    hasLicense = false,
    category = "501st",
    maxHealth = 600,
    maxArmor = 100,
})

TEAM_501_NCO = DarkRP.createJob("501st NCO", {
    color = Color(90, 140, 255, 255),
    model = {
        "models/aussiwozzi/cgi/base/501st_trooper.mdl",
    },
    description = [[Non-commissioned officer of the 501st Legion.]],
    weapons = {}, -- default weapons only
    command = "501nco",
    max = 0,
    salary = 0,
    admin = 0,
    vote = false,
    hasLicense = false,
    category = "501st",
    maxHealth = 500,
    maxArmor = 0,
})

TEAM_501ST = DarkRP.createJob("501st Trooper", {
    color = Color(50, 100, 255, 255),
    model = {
        "models/aussiwozzi/cgi/base/501st_trooper.mdl",
    },
    description = [[501st line trooper.]],
    weapons = {}, -- default weapons only
    command = "501st",
    max = 0,
    salary = 0,
    admin = 0,
    vote = false,
    hasLicense = false,
    category = "501st",
    maxHealth = 450,
    maxArmor = 0,
})

--[[---------------------------------------------------------------------------
212th Attack Battalion
---------------------------------------------------------------------------]]

TEAM_212_CMD = DarkRP.createJob("212th Commander", {
    color = Color(255, 180, 50, 255),
    model = {
        "models/aussiwozzi/cgi/base/212th_cody.mdl",
        "models/aussiwozzi/cgi/base/212th_officer.mdl",
        "models/aussiwozzi/cgi/base/212th_trooper.mdl",
        "models/aussiwozzi/cgi/base/212th_ghost_officer.mdl",
    },
    description = [[Commanding officer of the 212th Attack Battalion.]],
    weapons = {}, -- default weapons only
    command = "212cmd",
    max = 1,
    salary = 0,
    admin = 0,
    vote = false,
    hasLicense = false,
    category = "212th",
    maxHealth = 800,
    maxArmor = 200,
})

TEAM_212_XO = DarkRP.createJob("212th Executive Officer", {
    color = Color(255, 190, 60, 255),
    model = {
        "models/aussiwozzi/cgi/base/212th_cody.mdl",
        "models/aussiwozzi/cgi/base/212th_officer.mdl",
        "models/aussiwozzi/cgi/base/212th_trooper.mdl",
        "models/aussiwozzi/cgi/base/212th_ghost_officer.mdl",
    },
    description = [[Executive officer of the 212th Attack Battalion.]],
    weapons = {}, -- default weapons only
    command = "212xo",
    max = 1,
    salary = 0,
    admin = 0,
    vote = false,
    hasLicense = false,
    category = "212th",
    maxHealth = 750,
    maxArmor = 175,
})

TEAM_212_MAJOR = DarkRP.createJob("212th Major", {
    color = Color(255, 200, 70, 255),
    model = {
        "models/aussiwozzi/cgi/base/212th_cody.mdl",
        "models/aussiwozzi/cgi/base/212th_officer.mdl",
        "models/aussiwozzi/cgi/base/212th_trooper.mdl",
        "models/aussiwozzi/cgi/base/212th_ghost_officer.mdl",
    },
    description = [[Field officer of the 212th Attack Battalion.]],
    weapons = {}, -- default weapons only
    command = "212major",
    max = 2,
    salary = 0,
    admin = 0,
    vote = false,
    hasLicense = false,
    category = "212th",
    maxHealth = 700,
    maxArmor = 150,
})

TEAM_212_OFFICER = DarkRP.createJob("212th Officer", {
    color = Color(255, 210, 80, 255),
    model = {
        "models/aussiwozzi/cgi/base/212th_officer.mdl",
        "models/aussiwozzi/cgi/base/212th_trooper.mdl",
        "models/aussiwozzi/cgi/base/212th_ghost_officer.mdl",
    },
    description = [[Officer of the 212th Attack Battalion.]],
    weapons = {}, -- default weapons only
    command = "212officer",
    max = 4,
    salary = 0,
    admin = 0,
    vote = false,
    hasLicense = false,
    category = "212th",
    maxHealth = 600,
    maxArmor = 100,
})

TEAM_212_NCO = DarkRP.createJob("212th NCO", {
    color = Color(255, 220, 90, 255),
    model = {
        "models/aussiwozzi/cgi/base/212th_trooper.mdl",
    },
    description = [[Non-commissioned officer of the 212th Attack Battalion.]],
    weapons = {}, -- default weapons only
    command = "212nco",
    max = 0,
    salary = 0,
    admin = 0,
    vote = false,
    hasLicense = false,
    category = "212th",
    maxHealth = 500,
    maxArmor = 0,
})

TEAM_212TH = DarkRP.createJob("212th Trooper", {
    color = Color(255, 180, 50, 255),
    model = {
        "models/aussiwozzi/cgi/base/212th_trooper.mdl",
    },
    description = [[212th line trooper.]],
    weapons = {}, -- default weapons only
    command = "212th",
    max = 0,
    salary = 0,
    admin = 0,
    vote = false,
    hasLicense = false,
    category = "212th",
    maxHealth = 450,
    maxArmor = 0,
})

--[[---------------------------------------------------------------------------
Shock / Coruscant Guard
---------------------------------------------------------------------------]]

TEAM_SHOCK_CMD = DarkRP.createJob("Shock Commander", {
    color = Color(200, 50, 50, 255),
    model = {
        "models/aussiwozzi/cgi/base/cg_thorn.mdl",
        "models/aussiwozzi/cgi/base/cg_officer.mdl",
        "models/aussiwozzi/cgi/base/cg_riot_officer.mdl",
        "models/aussiwozzi/cgi/base/cg_trooper.mdl",
    },
    description = [[Commanding officer of the Coruscant Guard / Shock.]],
    weapons = {}, -- default weapons only (no police weapons)
    command = "shockcmd",
    max = 1,
    salary = 0,
    admin = 0,
    vote = false,
    hasLicense = false,
    category = "Shock",
    maxHealth = 800,
    maxArmor = 200,
})

TEAM_SHOCK_XO = DarkRP.createJob("Shock Executive Officer", {
    color = Color(210, 60, 60, 255),
    model = {
        "models/aussiwozzi/cgi/base/cg_thorn.mdl",
        "models/aussiwozzi/cgi/base/cg_officer.mdl",
        "models/aussiwozzi/cgi/base/cg_riot_officer.mdl",
        "models/aussiwozzi/cgi/base/cg_trooper.mdl",
    },
    description = [[Executive officer of the Coruscant Guard / Shock.]],
    weapons = {}, -- default weapons only
    command = "shockxo",
    max = 1,
    salary = 0,
    admin = 0,
    vote = false,
    hasLicense = false,
    category = "Shock",
    maxHealth = 750,
    maxArmor = 175,
})

TEAM_SHOCK_MAJOR = DarkRP.createJob("Shock Major", {
    color = Color(220, 70, 70, 255),
    model = {
        "models/aussiwozzi/cgi/base/cg_thorn.mdl",
        "models/aussiwozzi/cgi/base/cg_officer.mdl",
        "models/aussiwozzi/cgi/base/cg_riot_officer.mdl",
        "models/aussiwozzi/cgi/base/cg_trooper.mdl",
    },
    description = [[Field officer of the Coruscant Guard / Shock.]],
    weapons = {}, -- default weapons only
    command = "shockmajor",
    max = 2,
    salary = 0,
    admin = 0,
    vote = false,
    hasLicense = false,
    category = "Shock",
    maxHealth = 700,
    maxArmor = 150,
})

TEAM_SHOCK_OFFICER = DarkRP.createJob("Shock Officer", {
    color = Color(230, 80, 80, 255),
    model = {
        "models/aussiwozzi/cgi/base/cg_officer.mdl",
        "models/aussiwozzi/cgi/base/cg_riot_officer.mdl",
        "models/aussiwozzi/cgi/base/cg_trooper.mdl",
    },
    description = [[Officer of the Coruscant Guard / Shock.]],
    weapons = {}, -- default weapons only
    command = "shockofficer",
    max = 4,
    salary = 0,
    admin = 0,
    vote = false,
    hasLicense = false,
    category = "Shock",
    maxHealth = 600,
    maxArmor = 100,
})

TEAM_SHOCK_NCO = DarkRP.createJob("Shock NCO", {
    color = Color(240, 90, 90, 255),
    model = {
        "models/aussiwozzi/cgi/base/cg_trooper.mdl",
    },
    description = [[Non-commissioned officer of the Coruscant Guard / Shock.]],
    weapons = {}, -- default weapons only
    command = "shocknco",
    max = 0,
    salary = 0,
    admin = 0,
    vote = false,
    hasLicense = false,
    category = "Shock",
    maxHealth = 500,
    maxArmor = 0,
})

TEAM_SHOCK = DarkRP.createJob("Shock Trooper", {
    color = Color(200, 50, 50, 255),
    model = {
        "models/aussiwozzi/cgi/base/cg_trooper.mdl",
    },
    description = [[Shock line trooper.]],
    weapons = {}, -- default weapons only (no arrest/unarrest/stunstick)
    command = "shock",
    max = 0,
    salary = 0,
    admin = 0,
    vote = false,
    hasLicense = false,
    category = "Shock",
    maxHealth = 450,
    maxArmor = 0,
})

--[[---------------------------------------------------------------------------
Define which team joining players spawn into and what team you change to if demoted
---------------------------------------------------------------------------]]
GAMEMODE.DefaultTeam = TEAM_CADET

--[[---------------------------------------------------------------------------
Define which teams belong to civil protection
---------------------------------------------------------------------------]]
GAMEMODE.CivilProtection = {
    -- Intentionally empty for now; arrest system will be handled separately.
}

--[[---------------------------------------------------------------------------
Jobs that are hitmen (enables the hitman menu)
---------------------------------------------------------------------------]]
-- No hitmen in this StarWarsRP schema for now
-- DarkRP.addHitmanTeam(TEAM_MOB)
