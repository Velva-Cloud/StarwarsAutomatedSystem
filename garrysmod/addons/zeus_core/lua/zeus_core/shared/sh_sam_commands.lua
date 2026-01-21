if SAM_LOADED then return end

ZEUS = ZEUS or {}
ZEUS.Identity = ZEUS.Identity or {}

local function registerSAMCommands()
    if not sam or not sam.command or not sam.command.new then return end

    sam.print("ZEUS: registering SAM commands (shared)")

    local command = sam.command
    command.set_category("ZEUS")

    command.new("zeus_cc_to_ct")
        :SetPermission("zeus_cc_to_ct", "admin")
        :AddArg("player", {single_target = true})
        :Help("Promote a Cadet (CC) to Clone Trooper (CT).")
        :OnExecute(function(ply, targets)
            if not ZEUS.Identity or not ZEUS.Identity.PromoteCCtoCT then return end
            local target = targets[1]
            local ok, err = ZEUS.Identity.PromoteCCtoCT(ply, target)
            if not ok then
                ply:ChatPrint("[ZEUS] " .. (err or "Failed to promote."))
            else
                ply:ChatPrint("[ZEUS] Promoted Cadet to CT.")
            end
        end)
    :End()

    command.new("zeus_assign_regiment")
        :SetPermission("zeus_assign_regiment", "admin")
        :AddArg("player", {single_target = true})
        :AddArg("text", {hint = "regiment key"})
        :AddArg("text", {hint = "starting rank", optional = true})
        :Help("Assign a trooper to a regiment and optionally set starting rank.")
        :OnExecute(function(ply, targets, regimentKey, startingRank)
            if not ZEUS.Identity or not ZEUS.Identity.AssignToRegiment then return end
            local target = targets[1]
            local ok, err = ZEUS.Identity.AssignToRegiment(ply, target, regimentKey, startingRank ~= "" and startingRank or nil)
            if not ok then
                ply:ChatPrint("[ZEUS] " .. (err or "Failed to assign regiment."))
            else
                ply:ChatPrint("[ZEUS] Assigned to regiment " .. regimentKey .. ".")
            end
        end)
    :End()

    command.new("zeus_set_rank")
        :SetPermission("zeus_set_rank", "admin")
        :AddArg("player", {single_target = true})
        :AddArg("text", {hint = "rank"})
        :Help("Set a trooper's rank (must be below your own unless staff).")
        :OnExecute(function(ply, targets, newRank)
            if not ZEUS.Identity or not ZEUS.Identity.SetRank then return end
            local target = targets[1]
            local ok, err = ZEUS.Identity.SetRank(ply, target, newRank)
            if not ok then
                ply:ChatPrint("[ZEUS] " .. (err or "Failed to set rank."))
            else
                ply:ChatPrint("[ZEUS] Rank set to " .. newRank .. ".")
            end
        end)
    :End()

    command.new("zeus_set_cc")
        :SetPermission("zeus_set_cc", "admin")
        :AddArg("player", {single_target = true})
        :Help("Force a player back to CC (Cadet). Staff-only override.")
        :OnExecute(function(ply, targets)
            if not ZEUS.Identity or not ZEUS.Identity.SetPreRegiment then return end
            local target = targets[1]
            local ok, err = ZEUS.Identity.SetPreRegiment(ply, target, ZEUS.Config and ZEUS.Config.DefaultCadetTag or "CC")
            if not ok then
                ply:ChatPrint("[ZEUS] " .. (err or "Failed to set CC."))
            else
                ply:ChatPrint("[ZEUS] Set player to CC.")
            end
        end)
    :End()

    command.new("zeus_set_ct")
        :SetPermission("zeus_set_ct", "admin")
        :AddArg("player", {single_target = true})
        :Help("Force a player to CT (Clone Trooper). Staff-only override.")
        :OnExecute(function(ply, targets)
            if not ZEUS.Identity or not ZEUS.Identity.SetPreRegiment then return end
            local target = targets[1]
            local ok, err = ZEUS.Identity.SetPreRegiment(ply, target, ZEUS.Config and ZEUS.Config.DefaultTrooperTag or "CT")
            if not ok then
                ply:ChatPrint("[ZEUS] " .. (err or "Failed to set CT."))
            else
                ply:ChatPrint("[ZEUS] Set player to CT.")
            end
        end)
    :End()

    command.new("zeus_reset_name")
        :SetPermission("zeus_reset_name", "admin")
        :AddArg("player", {single_target = true})
        :Help("Reset a player's ZEUS name and prompt them to choose again.")
        :OnExecute(function(ply, targets)
            if not ZEUS.Identity or not ZEUS.Identity.ResetName then return end
            local target = targets[1]
            local ok, err = ZEUS.Identity.ResetName(ply, target)
            if not ok then
                if IsValid(ply) and ply.ChatPrint then
                    ply:ChatPrint("[ZEUS] " .. (err or "Failed to reset name."))
                else
                    print("[ZEUS] " .. (err or "Failed to reset name."))
                end
            else
                if IsValid(ply) and ply.ChatPrint then
                    ply:ChatPrint("[ZEUS] Reset player's name; they will be prompted to choose a new one.")
                else
                    print("[ZEUS] Reset player's name; they will be prompted to choose a new one.")
                end
            end
        end)
    :End()
end

hook.Add("SAM.LoadedConfig", "ZEUS_RegisterSAMCommandsShared", registerSAMCommands)