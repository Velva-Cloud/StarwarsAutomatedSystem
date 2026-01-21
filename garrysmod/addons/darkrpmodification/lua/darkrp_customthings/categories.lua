--[[-----------------------------------------------------------------------
Categories
---------------------------------------------------------------------------
The categories of the default F4 menu.

Please read this page for more information:
https://darkrp.miraheze.org/wiki/DarkRP:Categories

In case that page can't be reached, here's an example with explanation:

DarkRP.createCategory{
    name = "Clones",
    categorises = "jobs",
    startExpanded = true,
    color = Color(70, 130, 255, 255),
    canSee = function(ply) return true end,
    sortOrder = 10,
}

DarkRP.createCategory{
    name = "501st",
    categorises = "jobs",
    startExpanded = true,
    color = Color(50, 100, 255, 255),
    canSee = function(ply) return true end,
    sortOrder = 20,
}

DarkRP.createCategory{
    name = "Shock",
    categorises = "jobs",
    startExpanded = true,
    color = Color(200, 50, 50, 255),
    canSee = function(ply) return true end,
    sortOrder = 30,
}

DarkRP.createCategory{
    name = "212th",
    categorises = "jobs",
    startExpanded = true,
    color = Color(255, 180, 50, 255),
    canSee = function(ply) return true end,
    sortOrder = 40,
}


Add new categories under the next line!
---------------------------------------------------------------------------]]

