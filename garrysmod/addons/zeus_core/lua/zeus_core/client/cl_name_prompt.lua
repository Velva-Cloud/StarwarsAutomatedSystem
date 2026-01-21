ZEUS = ZEUS or {}
ZEUS.ClientIdentity = ZEUS.ClientIdentity or {}

local ClientIdentity = ZEUS.ClientIdentity

net.Receive("ZEUS_Identity_Full", function()
    local char_id = net.ReadUInt(16)
    local regiment = net.ReadString()
    local rank = net.ReadString()
    local chosen_name = net.ReadString()
    local xp = net.ReadInt(32)

    ClientIdentity.char_id = char_id
    ClientIdentity.regiment = regiment
    ClientIdentity.rank = rank
    ClientIdentity.chosen_name = chosen_name
    ClientIdentity.xp = xp
end)

local function openNamePrompt()
    if IsValid(ClientIdentity.Frame) then
        ClientIdentity.Frame:Remove()
    end

    local frame = vgui.Create("DFrame")
    frame:SetTitle("Choose Your Name")
    frame:SetSize(400, 150)
    frame:Center()
    frame:MakePopup()

    local label = vgui.Create("DLabel", frame)
    label:SetText("Enter a single-word name (letters only):")
    label:Dock(TOP)
    label:DockMargin(10, 30, 10, 5)

    local entry = vgui.Create("DTextEntry", frame)
    entry:Dock(TOP)
    entry:DockMargin(10, 0, 10, 5)
    entry:SetUpdateOnType(false)

    local errorLabel = vgui.Create("DLabel", frame)
    errorLabel:SetText("")
    errorLabel:SetTextColor(Color(200, 50, 50))
    errorLabel:Dock(TOP)
    errorLabel:DockMargin(10, 0, 10, 5)

    local btn = vgui.Create("DButton", frame)
    btn:Dock(BOTTOM)
    btn:DockMargin(10, 10, 10, 10)
    btn:SetText("Confirm")

    btn.DoClick = function()
        local name = entry:GetValue() or ""

        if #name < (ZEUS.Config and ZEUS.Config.NameMinLength or 3) then
            errorLabel:SetText("Name is too short.")
            return
        end

        if #name > (ZEUS.Config and ZEUS.Config.NameMaxLength or 16) then
            errorLabel:SetText("Name is too long.")
            return
        end

        if not string.match(name, ZEUS.Config and ZEUS.Config.NamePattern or "^[A-Za-z]+$") then
            errorLabel:SetText("Name must be letters only, no spaces.")
            return
        end

        net.Start("ZEUS_Identity_SetName")
            net.WriteString(name)
        net.SendToServer()

        frame:Close()
    end

    ClientIdentity.Frame = frame
end

net.Receive("ZEUS_Identity_RequestName", function()
    -- Debug feedback so we know the client received the prompt request
    if chat and chat.AddText then
        chat.AddText(Color(120, 180, 255), "[ZEUS] ", color_white, "Name prompt requested. Opening name menu...")
    end

    timer.Simple(0.5, openNamePrompt)
end)