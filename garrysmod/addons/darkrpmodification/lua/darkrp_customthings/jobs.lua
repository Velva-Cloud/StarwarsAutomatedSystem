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
Clone Wars / StarWarsRP jobs
---------------------------------------------------------------------------]]

-- Cadet (default spawn)
TEAM_CADET = DarkRP.createJob("Cadet", {
    color = Color(150, 150, 255, 255),
    model = {
        "models/player/Group03/male_01.mdl",
        "models/player/Group03/male_02.mdl",
        "models/player/Group03/male_03.mdl",
        "models/player/Group03/male_04.mdl",
    },
    description = [[New recruits undergoing basic training.]],
    weapons = {"weapon_pistol"},
    command = "cadet",
    max = 0,
    salary = 0,
    admin = 0,
    vote = false,
    hasLicense = false,
    category = "Clones",
})

-- Clone Trooper (unassigned CT)
TEAM_CT = DarkRP.createJob("Clone Trooper", {
    color = Color(120, 120, 255, 255),
    model = {
        "models/player/Group03/male_05.mdl",
        "models/player/Group03/male_06.mdl",
        "models/player/Group03/male_07.mdl",
    },
    description = [[Fully trained clone trooper without assigned regiment.]],
    weapons = {"weapon_pistol", "weapon_smg1"},
    command = "ct",
    max = 0,
    salary = 0,
    admin = 0,
    vote = false,
    hasLicense = false,
    category = "Clones",
})

-- 501st Trooper
TEAM_501ST = DarkRP.createJob("501st Trooper", {
    color = Color(50, 100, 255, 255),
    model = {
        "models/player/Group03/male_08.mdl",
        "models/player/Group03/female_01.mdl",
    },
    description = [[Member of the elite 501st Legion.]],
    weapons = {"weapon_pistol", "weapon_ar2"},
    command = "501st",
    max = 0,
    salary = 0,
    admin = 0,
    vote = false,
    hasLicense = false,
    category = "501st",
})

-- Shock Trooper
TEAM_SHOCK = DarkRP.createJob("Shock Trooper", {
    color = Color(200, 50, 50, 255),
    model = {
        "models/player/Group03/male_09.mdl",
        "models/player/Group03/female_02.mdl",
    },
    description = [[Coruscant Guard / Shock Trooper responsible for security and law enforcement.]],
    weapons = {"weapon_pistol", "weapon_smg1", "stunstick"},
    command = "shock",
    max = 0,
    salary = 0,
    admin = 0,
    vote = false,
    hasLicense = false,
    category = "Shock",
})

-- 212th Trooper
TEAM_212TH = DarkRP.createJob("212th Trooper", {
    color = Color(255, 180, 50, 255),
    model = {
        "models/player/Group03/male_01.mdl",
        "models/player/Group03/male_02.mdl",
    },
    description = [[Trooper of the 212th Attack Battalion.]],
    weapons = {"weapon_pistol", "weapon_ar2"},
    command = "212th",
    max = 0,
    salary = 0,
    admin = 0,
    vote = false,
    hasLicense = false,
    category = "212th",
})

--[[---------------------------------------------------------------------------
Define which team joining players spawn into and what team you change to if demoted
---------------------------------------------------------------------------]]
GAMEMODE.DefaultTeam = TEAM_CADET

--[[---------------------------------------------------------------------------
Define which teams belong to civil protection
---------------------------------------------------------------------------]]
GAMEMODE.CivilProtection = {
    -- You can add Shock or specific officer jobs here later, e.g.:
    -- [TEAM_SHOCK] = true,
}

--[[---------------------------------------------------------------------------
Jobs that are hitmen (enables the hitman menu)
---------------------------------------------------------------------------]]
-- No hitmen in this StarWarsRP schema for now
-- DarkRP.addHitmanTeam(TEAM_MOB)
