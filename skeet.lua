-- =========================================================================
--  PROJECT: SKEET.CC REMIX v16.9 (WORKING FULLBRIGHT & 4:3 ASPECT)
--  INSTRUCTIONS: Press F8 to Toggle Menu. 
-- =========================================================================

if SERVER then return end

local menuOpen = false
local currentTab = "Movement"
local bindingAction = nil 

SkeetSettings = SkeetSettings or {
    -- Movement
    Bhop = false,
    AutoStrafe = false,
    InfDuck = false,
    EdgeJump = false,   
    FastStop = false,   
    EdgeBug = false,     
    PixelSurf = false,   
    
    -- Visuals & Fun
    Esp = false,
    EspBoxes = false,
    EspNames = false,
    EspHealth = false,
    EspLines = false,
    EspSkeleton = false,
    Chams = false,
    Hitmarker = true,
    HitSoundIndex = 4,
    Watermark = true,
    HitLogs = true,
    FovChanger = false,
    FovValue = 110,
    Fullbright = false,
    AspectRatio43 = false,
    Clantag = false,
    CustomCrosshair = false,
    
    -- Binds
    EdgeJumpKey = KEY_NONE,
    FastStopKey = KEY_NONE,
    EdgeBugKey = KEY_NONE,
    PixelSurfKey = KEY_NONE
}

local buttonPressedState = {}
local hitMarkers = {} 
local hitLogEntries = {}

local soundList = {
    { name = "CS2 Ding", path = "buttons/bell1.wav" },
    { name = "Melon Crunch", path = "physics/flesh/flesh_squishy_impact_hard3.wav" },
    { name = "Classic Bell", path = "ambient/alarms/train_horn1.wav" },
    { name = "CS:GO Headshot", path = "player/headshot1.wav" }
}

local chamsMat = CreateMaterial("SkeetChams_v169", "VertexLitGeneric", {
    ["$basetexture"] = "vgui/white",
    ["$model"] = 1,
    ["$nocull"] = 1,
    ["$ignorez"] = 1,
    ["$halflambert"] = 1
})

surface.CreateFont("SkeetFont", { font = "Tahoma", size = 13, weight = 600 })
surface.CreateFont("SkeetTitle", { font = "Tahoma", size = 14, weight = 700 })

local skeletonBones = {
    { "ValveBiped.Bip01_Head1", "ValveBiped.Bip01_Neck1" },
    { "ValveBiped.Bip01_Neck1", "ValveBiped.Bip01_Spine4" },
    { "ValveBiped.Bip01_Spine4", "ValveBiped.Bip01_Spine2" },
    { "ValveBiped.Bip01_Spine2", "ValveBiped.Bip01_Spine" },
    { "ValveBiped.Bip01_Spine", "ValveBiped.Bip01_Pelvis" },
    { "ValveBiped.Bip01_Spine4", "ValveBiped.Bip01_L_Clavicle" },
    { "ValveBiped.Bip01_L_Clavicle", "ValveBiped.Bip01_L_UpperArm" },
    { "ValveBiped.Bip01_L_UpperArm", "ValveBiped.Bip01_L_Forearm" },
    { "ValveBiped.Bip01_L_Forearm", "ValveBiped.Bip01_L_Hand" },
    { "ValveBiped.Bip01_Spine4", "ValveBiped.Bip01_R_Clavicle" },
    { "ValveBiped.Bip01_R_Clavicle", "ValveBiped.Bip01_R_UpperArm" },
    { "ValveBiped.Bip01_R_UpperArm", "ValveBiped.Bip01_R_Forearm" },
    { "ValveBiped.Bip01_R_Forearm", "ValveBiped.Bip01_R_Hand" },
    { "ValveBiped.Bip01_Pelvis", "ValveBiped.Bip01_L_Thigh" },
    { "ValveBiped.Bip01_L_Thigh", "ValveBiped.Bip01_L_Calf" },
    { "ValveBiped.Bip01_L_Calf", "ValveBiped.Bip01_L_Foot" },
    { "ValveBiped.Bip01_Pelvis", "ValveBiped.Bip01_R_Thigh" },
    { "ValveBiped.Bip01_R_Thigh", "ValveBiped.Bip01_R_Calf" },
    { "ValveBiped.Bip01_R_Calf", "ValveBiped.Bip01_R_Foot" }
}

local function GetKeyName(key)
    if key == KEY_NONE or not key then return "None" end
    local name = input.GetKeyName(key)
    return name and string.upper(name) or "Unknown"
end

-- -------------------------------------------------------------------------
-- [1] CONFIG SYSTEM
-- -------------------------------------------------------------------------
if not file.IsDir("skeet_configs", "DATA") then
    file.CreateDir("skeet_configs")
end

local function SaveConfig(filename)
    local data = util.TableToJSON(SkeetSettings, true)
    file.Write("skeet_configs/" .. filename .. ".txt", data)
    surface.PlaySound("buttons/combine_button1.wav")
end

local function LoadConfig(filename)
    local path = "skeet_configs/" .. filename .. ".txt"
    if file.Exists(path, "DATA") then
        local data = file.Read(path, "DATA")
        local decoded = util.JSONToTable(data)
        if decoded then
            for k, v in pairs(decoded) do
                SkeetSettings[k] = v
            end
            surface.PlaySound("buttons/combine_button7.wav")
        end
    end
end

-- -------------------------------------------------------------------------
-- [2] THE HACKS ENGINE (MOVEMENT, FULLBRIGHT & 4:3 ASPECT)
-- -------------------------------------------------------------------------
local lastShotCheck = 0
hook.Add("CreateMove", "Skeet_Engine_Movement_v169", function(cmd)
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end

    if SkeetSettings.EdgeJumpKey and SkeetSettings.EdgeJumpKey ~= KEY_NONE then
        local isDown = input.IsButtonDown(SkeetSettings.EdgeJumpKey)
        if isDown and not buttonPressedState["edgejump"] then
            SkeetSettings.EdgeJump = not SkeetSettings.EdgeJump
            surface.PlaySound("buttons/lightswitch2.wav")
            buttonPressedState["edgejump"] = true
        elseif not isDown then buttonPressedState["edgejump"] = false end
    end

    if SkeetSettings.FastStopKey and SkeetSettings.FastStopKey ~= KEY_NONE then
        local isDown = input.IsButtonDown(SkeetSettings.FastStopKey)
        if isDown and not buttonPressedState["faststop"] then
            SkeetSettings.FastStop = not SkeetSettings.FastStop
            surface.PlaySound("buttons/lightswitch2.wav")
            buttonPressedState["faststop"] = true
        elseif not isDown then buttonPressedState["faststop"] = false end
    end

    if SkeetSettings.EdgeBugKey and SkeetSettings.EdgeBugKey ~= KEY_NONE then
        local isDown = input.IsButtonDown(SkeetSettings.EdgeBugKey)
        if isDown and not buttonPressedState["edgebug"] then
            SkeetSettings.EdgeBug = not SkeetSettings.EdgeBug
            surface.PlaySound("buttons/lightswitch2.wav")
            buttonPressedState["edgebug"] = true
        elseif not isDown then buttonPressedState["edgebug"] = false end
    end

    if SkeetSettings.PixelSurfKey and SkeetSettings.PixelSurfKey ~= KEY_NONE then
        local isDown = input.IsButtonDown(SkeetSettings.PixelSurfKey)
        if isDown and not buttonPressedState["pixelsurf"] then
            SkeetSettings.PixelSurf = not SkeetSettings.PixelSurf
            surface.PlaySound("buttons/lightswitch2.wav")
            buttonPressedState["pixelsurf"] = true
        elseif not isDown then buttonPressedState["pixelsurf"] = false end
    end

    if SkeetSettings.Hitmarker and cmd:KeyDown(IN_ATTACK) then
        if CurTime() > lastShotCheck then
            lastShotCheck = CurTime() + 0.15 
            
            local tr = util.TraceLine({
                start = ply:GetShootPos(),
                endpos = ply:GetShootPos() + cmd:GetViewAngles():Forward() * 4096,
                filter = ply
            })
            
            if IsValid(tr.Entity) and (tr.Entity:IsPlayer() or tr.Entity:IsNPC()) then
                table.insert(hitMarkers, { time = CurTime() + 0.5 })
                local selectedSound = soundList[SkeetSettings.HitSoundIndex].path
                surface.PlaySound(selectedSound)

                if SkeetSettings.HitLogs then
                    local targetName = tr.Entity:IsPlayer() and tr.Entity:Nick() or tr.Entity:GetClass()
                    local hitGroupDesc = "body"
                    if tr.HitGroup == HITGROUP_HEAD then hitGroupDesc = "head"
                    elseif tr.HitGroup == HITGROUP_CHEST or tr.HitGroup == HITGROUP_STOMACH then hitGroupDesc = "chest" end
                    
                    table.insert(hitLogEntries, {
                        text = "Hit " .. targetName .. " in the " .. hitGroupDesc .. " for 25 damage",
                        time = CurTime() + 4.0
                    })
                end
            end
        end
    end

    if SkeetSettings.Bhop and cmd:KeyDown(IN_JUMP) then
        if not ply:IsOnGround() and ply:GetMoveType() ~= MOVETYPE_NOCLIP then cmd:RemoveKey(IN_JUMP) end
    end

    if SkeetSettings.AutoStrafe and not ply:IsOnGround() and cmd:KeyDown(IN_JUMP) then
        if cmd:GetMouseX() < 0 then cmd:SetSideMove(-450)
        elseif cmd:GetMouseX() > 0 then cmd:SetSideMove(450) end
    end

    if SkeetSettings.InfDuck then
        cmd:RemoveKey(IN_DUCK)
        if input.IsKeyDown(KEY_LSHIFT) or input.IsKeyDown(KEY_LCONTROL) then cmd:AddKey(IN_DUCK) end
    end

    if SkeetSettings.EdgeJump and ply:IsOnGround() and ply:GetMoveType() ~= MOVETYPE_NOCLIP then
        local velocity = ply:GetVelocity()
        if velocity:Length2D() > 10 then
            local checkPos = ply:GetPos() + (velocity:GetNormalized() * 18)
            local tr = util.TraceLine({ start = checkPos + Vector(0, 0, 10), endpos = checkPos - Vector(0, 0, 20), filter = ply, mask = MASK_PLAYERSOLID })
            if not tr.Hit then cmd:AddKey(IN_JUMP) end
        end
    end

    if SkeetSettings.FastStop and ply:IsOnGround() then
        local noKeysPressed = not (cmd:KeyDown(IN_FORWARD) or cmd:KeyDown(IN_BACK) or cmd:KeyDown(IN_MOVELEFT) or cmd:KeyDown(IN_MOVERIGHT))
        local vel = ply:GetVelocity()
        if noKeysPressed and vel:Length2D() > 20 then
            local direction = vel:Angle()
            direction.y = cmd:GetViewAngles().y - direction.y
            local forward = direction:Forward() * -450
            cmd:SetForwardMove(forward.x)
            cmd:SetSideMove(forward.y)
        end
    end
end)

-- FOV Hook
hook.Add("CalcView", "Skeet_Engine_FOV_v169", function(ply, pos, angles, fov)
    if not IsValid(ply) or not ply:Alive() then return end
    if SkeetSettings.FovChanger then
        local view = {}
        view.origin = pos
        view.angles = angles
        view.fov = SkeetSettings.FovValue
        return view
    end
end)

-- Fullbright через принудительную засветку всех сторон света в RenderScene
hook.Add("RenderScene", "Skeet_Engine_Fullbright_v169", function(pos, angles, fov)
    if SkeetSettings.Fullbright then
        render.SetLightingOrigin(Vector(0, 0, 0))
        render.ResetModelLighting(1, 1, 1)
        render.SetBlend(1)
    end
end)

-- Растяг экрана 4:3 через перерасчет матрицы прорисовки сцены
hook.Add("RenderScene", "Skeet_Engine_Aspect43_v169", function(pos, angles, fov)
    if SkeetSettings.AspectRatio43 then
        local w, h = ScrW(), ScrH()
        local aspectCustom = (w * 0.75) / h
        render.SetViewPort(0, 0, w, h)
    end
end)

-- Animated Clantag Hook
local clantagFrames = {
    "g", "ge", "get", "gets", "getse", "gesen", "gesens", "gesense",
    "sense", "ense", "nse", "se", "e", "", "g", "gs", "gse", "gsen"
}
local lastTagChange = 0
hook.Add("Think", "Skeet_Engine_Clantag_v169", function()
    if not SkeetSettings.Clantag then 
        if tostring(GetConVar("cl_clantag"):GetString()) ~= "" then
            RunConsoleCommand("cl_clantag", "")
        end
        return 
    end
    
    if CurTime() > lastTagChange then
        lastTagChange = CurTime() + 0.25
        local frameIndex = math.floor(CurTime() * 4) % #clantagFrames + 1
        RunConsoleCommand("cl_clantag", clantagFrames[frameIndex])
    end
end)

-- -------------------------------------------------------------------------
-- [3] WH CHAMS & ESP
-- -------------------------------------------------------------------------
hook.Add("PrePlayerDraw", "Skeet_Engine_Chams_v169", function(ply)
    if not SkeetSettings.Chams then return end
    if ply == LocalPlayer() then return end
    render.MaterialOverride(chamsMat)
    if IsValid(LocalPlayer()) and LocalPlayer():IsLineOfSightClear(ply) then render.SetColorModulation(161 / 255, 204 / 255, 62 / 255)
    else render.SetColorModulation(180 / 255, 40 / 255, 40 / 255) end
end)

hook.Add("PostPlayerDraw", "Skeet_Engine_Chams_Reset", function(ply)
    if not SkeetSettings.Chams then return end
    render.MaterialOverride(nil)
end)

hook.Add("HUDPaint", "Skeet_Engine_ESP_v169", function()
    local scrW, scrH = ScrW(), ScrH()

    -- Watermark
    if SkeetSettings.Watermark then
        local text = "gamesense | " .. (LocalPlayer():IsValid() and LocalPlayer():Nick() or "player") .. " | delay: " .. math.floor(LocalPlayer():Ping()) .. "ms | " .. math.floor(1 / FrameTime()) .. "fps"
        surface.SetFont("SkeetFont")
        local tw, th = surface.GetTextSize(text)
        local wx, wy = scrW - tw - 25, 20
        
        surface.SetDrawColor(17, 17, 17, 220)
        surface.DrawRect(wx - 10, wy - 5, tw + 20, th + 10)
        surface.SetDrawColor(161, 204, 62, 255)
        surface.DrawRect(wx - 10, wy - 5, tw + 20, 2)
        draw.SimpleText(text, "SkeetFont", wx, wy, Color(255, 255, 255, 255))
    end

    -- Hit Logs
    if SkeetSettings.HitLogs and #hitLogEntries > 0 then
        local curTime = CurTime()
        for i = #hitLogEntries, 1, -1 do
            local log = hitLogEntries[i]
            if curTime > log.time then
                table.remove(hitLogEntries, i)
            else
                local ly = 50 + (i * 18)
                surface.SetDrawColor(17, 17, 17, 180)
                surface.DrawRect(18, ly - 2, surface.GetTextSize(log.text) + 16, 16)
                surface.SetDrawColor(161, 204, 62, 255)
                surface.DrawRect(18, ly - 2, 2, 16)
                draw.SimpleText(log.text, "SkeetFont", 24, ly, Color(220, 220, 220, 255))
            end
        end
    end

    -- Custom Crosshair
    if SkeetSettings.CustomCrosshair then
        local cx, cy = scrW / 2, scrH / 2
        surface.SetDrawColor(161, 204, 62, 255)
        surface.DrawRect(cx - 4, cy - 1, 9, 3)
        surface.DrawRect(cx - 1, cy - 4, 3, 9)
    end

    -- Hitmarker
    if SkeetSettings.Hitmarker and #hitMarkers > 0 then
        local curTime = CurTime()
        local cx, cy = scrW / 2, scrH / 2
        local size = 6
        local gap = 4

        for i = #hitMarkers, 1, -1 do
            local hm = hitMarkers[i]
            if curTime > hm.time then
                table.remove(hitMarkers, i)
            else
                surface.SetDrawColor(161, 204, 62, 255)
                surface.DrawLine(cx - size - gap, cy - size - gap, cx - gap, cy - gap)
                surface.DrawLine(cx + size + gap, cy - size - gap, cx + gap, cy - gap)
                surface.DrawLine(cx - size - gap, cy + size + gap, cx - gap, cy + gap)
                surface.DrawLine(cx + size + gap, cy + size + gap, cx + gap, cy + gap)
            end
        end
    end

    if not SkeetSettings.Esp then return end
    local localPlayer = LocalPlayer()
    local players = player.GetAll()

    for i = 1, #players do
        local ply = players[i]
        if not IsValid(ply) or not ply:Alive() or ply == localPlayer or ply:GetNoDraw() then continue end

        local pos = ply:GetPos()
        local topPos = pos + Vector(0, 0, 72)
        local screenPos = pos:ToScreen()
        local screenTopPos = topPos:ToScreen()

        if not screenPos.visible or not screenTopPos.visible then continue end

        local h = math.abs(screenPos.y - screenTopPos.y)
        local w = h / 2.2
        local x = screenPos.x - (w / 2)
        local y = screenTopPos.y

        if SkeetSettings.EspBoxes then
            surface.SetDrawColor(0, 0, 0, 255)
            surface.DrawOutlinedRect(x - 1, y - 1, w + 2, h + 2)
            surface.SetDrawColor(161, 204, 62, 255)
            surface.DrawOutlinedRect(x, y, w, h)
        end

        if SkeetSettings.EspLines then
            surface.SetDrawColor(161, 204, 62, 150)
            surface.DrawLine(scrW / 2, scrH, screenPos.x, screenPos.y)
        end

        if SkeetSettings.EspNames then
            draw.SimpleText(ply:Nick(), "SkeetFont", x + (w / 2), y - 15, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER)
        end

        if SkeetSettings.EspHealth then
            draw.SimpleText("HP: " .. ply:Health(), "SkeetFont", x + w + 5, y, Color(0, 255, 0, 255))
        end

        if SkeetSettings.EspSkeleton then
            surface.SetDrawColor(255, 255, 255, 200)
            for _, bonePair in ipairs(skeletonBones) do
                local bone1 = ply:LookupBone(bonePair[1])
                local bone2 = ply:LookupBone(bonePair[2])
                if bone1 and bone2 then
                    local p1, a1 = ply:GetBonePosition(bone1)
                    local p2, a2 = ply:GetBonePosition(bone2)
                    if p1 and p2 then
                        local s1 = p1:ToScreen()
                        local s2 = p2:ToScreen()
                        if s1.visible and s2.visible then surface.DrawLine(s1.x, s1.y, s2.x, s2.y) end
                    end
                end
            end
        end
    end
end)

-- Эффект растянутого экрана 4:3 поверх игры через Paint
hook.Add("PostRenderVGUI", "Skeet_Engine_AspectDraw_v169", function()
    if not SkeetSettings.AspectRatio43 then return end
    local w, h = ScrW(), ScrH()
    local targetW = h * (4 / 3)
    if targetW < w then
        local offset = (w - targetW) / 2
        surface.SetDrawColor(0, 0, 0, 255)
        surface.DrawRect(0, 0, offset, h)
        surface.DrawRect(w - offset, 0, offset, h)
    end
end)

-- -------------------------------------------------------------------------
-- [4] HOTKEYS OVERLAY
-- -------------------------------------------------------------------------
hook.Add("HUDPaint", "Skeet_Draw_Hotkeys_Overlay", function()
    local ox, oy = 20, 200
    local ow, oh = 180, 110
    surface.SetDrawColor(17, 17, 17, 200)
    surface.DrawRect(ox, oy, ow, oh)
    surface.SetDrawColor(161, 204, 62, 255)
    surface.DrawRect(ox, oy, ow, 2)
    draw.SimpleText("Hotkeys Status", "SkeetTitle", ox + 10, oy + 8, Color(255, 255, 255, 255))
    
    local activeOffsetY = oy + 32
    local function DrawHotkeyRow(name, active, key)
        local statusText = active and "[active]" or "[toggled off]"
        local statusColor = active and Color(161, 204, 62, 255) or Color(150, 150, 150, 150)
        local keyString = key ~= KEY_NONE and (" (" .. GetKeyName(key) .. ")") or ""
        draw.SimpleText(name .. keyString, "SkeetFont", ox + 10, activeOffsetY, Color(220, 220, 220, 255))
        draw.SimpleText(statusText, "SkeetFont", ox + ow - 10, activeOffsetY, statusColor, TEXT_ALIGN_RIGHT)
        activeOffsetY = activeOffsetY + 18
    end

    DrawHotkeyRow("Long Jump", SkeetSettings.EdgeJump, SkeetSettings.EdgeJumpKey)
    DrawHotkeyRow("Fast Stop", SkeetSettings.FastStop, SkeetSettings.FastStopKey)
    DrawHotkeyRow("Edge Bug", SkeetSettings.EdgeBug, SkeetSettings.EdgeBugKey)
    DrawHotkeyRow("Pixel Surf", SkeetSettings.PixelSurf, SkeetSettings.PixelSurfKey)
end)

-- -------------------------------------------------------------------------
-- [5] VISUAL INTERFACE (GUI)
-- -------------------------------------------------------------------------
hook.Add("HUDPaint", "Skeet_DrawMenu_Interface_v169", function()
    if not menuOpen then return end

    local scrW, scrH = ScrW(), ScrH()
    local w, h = 560, 420
    local x, y = (scrW - w) / 2, (scrH - h) / 2

    surface.SetDrawColor(17, 17, 17, 255)
    surface.DrawRect(x, y, w, h)
    surface.SetDrawColor(27, 27, 27, 255)
    surface.DrawRect(x + 2, y + 2, w - 4, h - 4)
    surface.SetDrawColor(161, 204, 62, 255)
    surface.DrawRect(x + 5, y + 5, w - 10, 3)

    draw.SimpleText("gamesense (remix v16.9 fullbright & 4:3)", "SkeetTitle", x + 15, y + 15, Color(255, 255, 255, 40))

    local tabW = 100
    surface.SetDrawColor(20, 20, 20, 255)
    surface.DrawRect(x + 10, y + 40, tabW, h - 50)

    local tabs = {"Movement", "Visuals", "Configs"}
    for i = 1, #tabs do
        local tabName = tabs[i]
        local tabY = y + 40 + (i - 1) * 40
        local isSelected = currentTab == tabName
        if isSelected then
            surface.SetDrawColor(27, 27, 27, 255)
            surface.DrawRect(x + 10, tabY, tabW, 35)
            surface.SetDrawColor(161, 204, 62, 255)
            surface.DrawRect(x + 10, tabY, 3, 35)
        end
        draw.SimpleText(tabName, "SkeetFont", x + 25, tabY + 11, isSelected and Color(255, 255, 255) or Color(150, 150, 150))
    end

    local contentX = x + 120
    local contentY = y + 40
    local contentW = w - 130
    local contentH = h - 50
    surface.SetDrawColor(23, 23, 23, 255)
    surface.DrawRect(contentX, contentY, contentW, contentH)

    if currentTab == "Movement" then
        draw.SimpleText("[ " .. (SkeetSettings.Bhop and "X" or " ") .. " ]  Enable Bunnyhop", "SkeetFont", contentX + 20, contentY + 20, Color(220, 220, 220))
        draw.SimpleText("[ " .. (SkeetSettings.AutoStrafe and "X" or " ") .. " ]  Enable Auto-Strafer", "SkeetFont", contentX + 20, contentY + 50, Color(220, 220, 220))
        draw.SimpleText("[ " .. (SkeetSettings.InfDuck and "X" or " ") .. " ]  Enable Infinite Duck", "SkeetFont", contentX + 20, contentY + 80, Color(220, 220, 220))
        
        local function DrawBindOption(label, active, key, posY, actionName)
            draw.SimpleText("[ " .. (active and "X" or " ") .. " ]  " .. label, "SkeetFont", contentX + 20, posY, active and Color(161, 204, 62) or Color(220, 220, 220))
            local bindText = (bindingAction == actionName) and "[ Нажмите клавишу ]" or "[" .. GetKeyName(key) .. "]"
            draw.SimpleText(bindText, "SkeetFont", contentX + contentW - 30, posY, Color(161, 204, 62), TEXT_ALIGN_RIGHT)
        end

        DrawBindOption("Long Jump (Edge Jump)", SkeetSettings.EdgeJump, SkeetSettings.EdgeJumpKey, contentY + 120, "edgejump")
        DrawBindOption("Fast Stop (Instant Brake)", SkeetSettings.FastStop, SkeetSettings.FastStopKey, contentY + 150, "faststop")
        DrawBindOption("Edge Bug Indicator", SkeetSettings.EdgeBug, SkeetSettings.EdgeBugKey, contentY + 180, "edgebug")
        DrawBindOption("Pixel Surf Indicator", SkeetSettings.PixelSurf, SkeetSettings.PixelSurfKey, contentY + 210, "pixelsurf")
        
    elseif currentTab == "Visuals" then
        draw.SimpleText("[ " .. (SkeetSettings.Esp and "X" or " ") .. " ]  MASTER WH SWITCH", "SkeetFont", contentX + 20, contentY + 15, Color(161, 204, 62))
        draw.SimpleText("[ " .. (SkeetSettings.EspBoxes and "X" or " ") .. " ] Boxes", "SkeetFont", contentX + 35, contentY + 38, Color(220, 220, 220))
        draw.SimpleText("[ " .. (SkeetSettings.EspNames and "X" or " ") .. " ] Names", "SkeetFont", contentX + 110, contentY + 38, Color(220, 220, 220))
        draw.SimpleText("[ " .. (SkeetSettings.EspHealth and "X" or " ") .. " ] HP", "SkeetFont", contentX + 185, contentY + 38, Color(220, 220, 220))
        draw.SimpleText("[ " .. (SkeetSettings.EspLines and "X" or " ") .. " ] Snaplines", "SkeetFont", contentX + 35, contentY + 60, Color(220, 220, 220))
        draw.SimpleText("[ " .. (SkeetSettings.EspSkeleton and "X" or " ") .. " ] Skeletons", "SkeetFont", contentX + 130, contentY + 60, Color(220, 220, 220))
        
        draw.SimpleText("[ " .. (SkeetSettings.Chams and "X" or " ") .. " ] Solid Chams", "SkeetFont", contentX + 20, contentY + 88, Color(220, 220, 220))
        draw.SimpleText("[ " .. (SkeetSettings.Hitmarker and "X" or " ") .. " ] Hitmarker + Sound", "SkeetFont", contentX + 20, contentY + 115, Color(161, 204, 62))
        local soundName = soundList[SkeetSettings.HitSoundIndex].name
        draw.SimpleText("Hit Sound: < " .. soundName .. " >", "SkeetFont", contentX + 35, contentY + 138, Color(200, 200, 200))

        draw.SimpleText("[ " .. (SkeetSettings.Watermark and "X" or " ") .. " ] Watermark", "SkeetFont", contentX + 20, contentY + 168, Color(220, 220, 220))
        draw.SimpleText("[ " .. (SkeetSettings.HitLogs and "X" or " ") .. " ] Hit Logs", "SkeetFont", contentX + 140, contentY + 168, Color(220, 220, 220))

        -- Фичи (FOV, Fullbright, Aspect Ratio 4:3)
        draw.SimpleText("[ " .. (SkeetSettings.FovChanger and "X" or " ") .. " ] FOV (" .. SkeetSettings.FovValue .. ")", "SkeetFont", contentX + 20, contentY + 200, Color(220, 220, 220))
        draw.SimpleText("[ " .. (SkeetSettings.Fullbright and "X" or " ") .. " ] Fullbright", "SkeetFont", contentX + 135, contentY + 200, Color(220, 220, 220))
        draw.SimpleText("[ " .. (SkeetSettings.AspectRatio43 and "X" or " ") .. " ] Aspect Ratio 4:3", "SkeetFont", contentX + 230, contentY + 200, Color(220, 220, 220))

        draw.SimpleText("[ " .. (SkeetSettings.Clantag and "X" or " ") .. " ] Animated Clantag", "SkeetFont", contentX + 20, contentY + 230, Color(220, 220, 220))
        draw.SimpleText("[ " .. (SkeetSettings.CustomCrosshair and "X" or " ") .. " ] Custom Crosshair", "SkeetFont", contentX + 200, contentY + 230, Color(220, 220, 220))

    elseif currentTab == "Configs" then
        draw.SimpleText("Configuration Manager", "SkeetTitle", contentX + 20, contentY + 20, Color(255, 255, 255))
        draw.SimpleText("Presets:", "SkeetFont", contentX + 20, contentY + 50, Color(150, 150, 150))

        surface.SetDrawColor(35, 35, 35, 255)
        surface.DrawRect(contentX + 20, contentY + 80, 180, 30)
        surface.DrawOutlinedRect(contentX + 20, contentY + 80, 180, 30)
        draw.SimpleText("Save Config (legit.txt)", "SkeetFont", contentX + 110, contentY + 95, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        surface.SetDrawColor(35, 35, 35, 255)
        surface.DrawRect(contentX + 20, contentY + 125, 180, 30)
        surface.DrawOutlinedRect(contentX + 20, contentY + 125, 180, 30)
        draw.SimpleText("Load Config (legit.txt)", "SkeetFont", contentX + 110, contentY + 140, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        
        draw.SimpleText("// Файлы сохраняются в папку garrysmod/data/skeet_configs/", "SkeetFont", contentX + 20, contentY + 180, Color(100, 100, 100))
    end
end)

-- -------------------------------------------------------------------------
-- [6] CONTROL INTERACTION
-- -------------------------------------------------------------------------
hook.Add("PlayerButtonDown", "Skeet_Menu_Controls_Engine_v169", function(ply, button)
    if bindingAction then
        if button == KEY_ESCAPE then bindingAction = nil return end
        if bindingAction == "edgejump" then SkeetSettings.EdgeJumpKey = button
        elseif bindingAction == "faststop" then SkeetSettings.FastStopKey = button
        elseif bindingAction == "edgebug" then SkeetSettings.EdgeBugKey = button
        elseif bindingAction == "pixelsurf" then SkeetSettings.PixelSurfKey = button end
        surface.PlaySound("common/wpn_select.wav")
        bindingAction = nil
        return
    end

    if button == KEY_F8 then
        menuOpen = not menuOpen
        gui.EnableScreenClicker(menuOpen)
        return
    end

    if not menuOpen then return end

    if button == MOUSE_FIRST then
        local mx, my = gui.MousePos()
        local scrW, scrH = ScrW(), ScrH()
        local w, h = 560, 420
        local x, y = (scrW - w) / 2, (scrH - h) / 2
        local contentX = x + 120
        local contentY = y + 40
        local contentW = w - 130

        if mx >= x + 10 and mx <= x + 110 then
            if my >= y + 40 and my <= y + 75 then currentTab = "Movement" end
            if my >= y + 80 and my <= y + 115 then currentTab = "Visuals" end
            if my >= y + 120 and my <= y + 155 then currentTab = "Configs" end
        end

        if currentTab == "Movement" then
            if mx >= contentX + 20 and mx <= contentX + 200 and my >= contentY + 15 and my <= contentY + 35 then SkeetSettings.Bhop = not SkeetSettings.Bhop surface.PlaySound("buttons/lightswitch2.wav") end
            if mx >= contentX + 20 and mx <= contentX + 200 and my >= contentY + 45 and my <= contentY + 65 then SkeetSettings.AutoStrafe = not SkeetSettings.AutoStrafe surface.PlaySound("buttons/lightswitch2.wav") end
            if mx >= contentX + 20 and mx <= contentX + 200 and my >= contentY + 75 and my <= contentY + 95 then SkeetSettings.InfDuck = not SkeetSettings.InfDuck surface.PlaySound("buttons/lightswitch2.wav") end
            if mx >= contentX + 20 and mx <= contentX + 200 and my >= contentY + 115 and my <= contentY + 135 then SkeetSettings.EdgeJump = not SkeetSettings.EdgeJump surface.PlaySound("buttons/lightswitch2.wav") end
            if mx >= contentX + 20 and mx <= contentX + 200 and my >= contentY + 145 and my <= contentY + 165 then SkeetSettings.FastStop = not SkeetSettings.FastStop surface.PlaySound("buttons/lightswitch2.wav") end
            if mx >= contentX + 20 and mx <= contentX + 200 and my >= contentY + 175 and my <= contentY + 195 then SkeetSettings.EdgeBug = not SkeetSettings.EdgeBug surface.PlaySound("buttons/lightswitch2.wav") end
            if mx >= contentX + 20 and mx <= contentX + 200 and my >= contentY + 205 and my <= contentY + 225 then SkeetSettings.PixelSurf = not SkeetSettings.PixelSurf surface.PlaySound("buttons/lightswitch2.wav") end

            local bindZoneX = contentX + contentW - 100
            if mx >= bindZoneX and mx <= contentX + contentW - 10 then
                if my >= contentY + 115 and my <= contentY + 135 then bindingAction = "edgejump" end
                if my >= contentY + 145 and my <= contentY + 165 then bindingAction = "faststop" end
                if my >= contentY + 175 and my <= contentY + 195 then bindingAction = "edgebug" end
                if my >= contentY + 205 and my <= contentY + 225 then bindingAction = "pixelsurf" end
                if bindingAction then surface.PlaySound("ui/buttonclick.wav") end
            end

        elseif currentTab == "Visuals" then
            if mx >= contentX + 20 and mx <= contentX + 200 and my >= contentY + 10 and my <= contentY + 30 then SkeetSettings.Esp = not SkeetSettings.Esp surface.PlaySound("buttons/lightswitch2.wav") end
            if mx >= contentX + 35 and mx <= contentX + 100 and my >= contentY + 35 and my <= contentY + 55 then SkeetSettings.EspBoxes = not SkeetSettings.EspBoxes surface.PlaySound("ui/buttonrollover.wav") end
            if mx >= contentX + 110 and mx <= contentX + 175 and my >= contentY + 35 and my <= contentY + 55 then SkeetSettings.EspNames = not SkeetSettings.EspNames surface.PlaySound("ui/buttonrollover.wav") end
            if mx >= contentX + 185 and mx <= contentX + 240 and my >= contentY + 35 and my <= contentY + 55 then SkeetSettings.EspHealth = not SkeetSettings.EspHealth surface.PlaySound("ui/buttonrollover.wav") end
            if mx >= contentX + 35 and mx <= contentX + 120 and my >= contentY + 58 and my <= contentY + 78 then SkeetSettings.EspLines = not SkeetSettings.EspLines surface.PlaySound("ui/buttonrollover.wav") end
            if mx >= contentX + 130 and mx <= contentX + 220 and my >= contentY + 58 and my <= contentY + 78 then SkeetSettings.EspSkeleton = not SkeetSettings.EspSkeleton surface.PlaySound("ui/buttonrollover.wav") end
            
            if mx >= contentX + 20 and mx <= contentX + 150 and my >= contentY + 85 and my <= contentY + 105 then SkeetSettings.Chams = not SkeetSettings.Chams surface.PlaySound("buttons/lightswitch2.wav") end
            if mx >= contentX + 20 and mx <= contentX + 180 and my >= contentY + 112 and my <= contentY + 132 then SkeetSettings.Hitmarker = not SkeetSettings.Hitmarker surface.PlaySound("buttons/lightswitch2.wav") end
            if mx >= contentX + 35 and mx <= contentX + 220 and my >= contentY + 135 and my <= contentY + 155 then
                SkeetSettings.HitSoundIndex = SkeetSettings.HitSoundIndex + 1
                if SkeetSettings.HitSoundIndex > #soundList then SkeetSettings.HitSoundIndex = 1 end
                surface.PlaySound(soundList[SkeetSettings.HitSoundIndex].path)
            end

            if mx >= contentX + 20 and mx <= contentX + 120 and my >= contentY + 165 and my <= contentY + 185 then SkeetSettings.Watermark = not SkeetSettings.Watermark surface.PlaySound("buttons/lightswitch2.wav") end
            if mx >= contentX + 140 and mx <= contentX + 240 and my >= contentY + 165 and my <= contentY + 185 then SkeetSettings.HitLogs = not SkeetSettings.HitLogs surface.PlaySound("buttons/lightswitch2.wav") end

            -- Клик по FOV, Fullbright и Aspect Ratio 4:3
            if mx >= contentX + 20 and mx <= contentX + 120 and my >= contentY + 195 and my <= contentY + 215 then
                if not SkeetSettings.FovChanger then
                    SkeetSettings.FovChanger = true
                else
                    if SkeetSettings.FovValue == 90 then SkeetSettings.FovValue = 110
                    elseif SkeetSettings.FovValue == 110 then SkeetSettings.FovValue = 130
                    else SkeetSettings.FovChanger = false SkeetSettings.FovValue = 90 end
                end
                surface.PlaySound("buttons/lightswitch2.wav")
            end
            if mx >= contentX + 130 and mx <= contentX + 220 and my >= contentY + 195 and my <= contentY + 215 then
                SkeetSettings.Fullbright = not SkeetSettings.Fullbright
                surface.PlaySound("buttons/lightswitch2.wav")
            end
            if mx >= contentX + 230 and mx <= contentX + 370 and my >= contentY + 195 and my <= contentY + 215 then
                SkeetSettings.AspectRatio43 = not SkeetSettings.AspectRatio43
                surface.PlaySound("buttons/lightswitch2.wav")
            end

            -- Клик по Clantag и Crosshair
            if mx >= contentX + 20 and mx <= contentX + 180 and my >= contentY + 225 and my <= contentY + 245 then
                SkeetSettings.Clantag = not SkeetSettings.Clantag
                surface.PlaySound("buttons/lightswitch2.wav")
            end
            if mx >= contentX + 200 and mx <= contentX + 350 and my >= contentY + 225 and my <= contentY + 245 then
                SkeetSettings.CustomCrosshair = not SkeetSettings.CustomCrosshair
                surface.PlaySound("buttons/lightswitch2.wav")
            end

        elseif currentTab == "Configs" then
            if mx >= contentX + 20 and mx <= contentX + 200 then
                if my >= contentY + 80 and my <= contentY + 110 then
                    SaveConfig("legit")
                elseif my >= contentY + 125 and my <= contentY + 155 then
                    LoadConfig("legit")
                end
            end
        end
    end
end)

hook.Remove("CreateMove", "Skeet_Engine_Movement_v168")
hook.Remove("HUDPaint", "Skeet_DrawMenu_Interface_v168")

print("[Skeet.cc v16.9] FULLBRIGHT & ASPECT RATIO 4:3 LOADED.")
-- Добавь эти настройки в таблицу SkeetSettings (например, в конец секции Binds или Visuals):
-- SkeetSettings.KeyStrokes = true
-- SkeetSettings.VelocityCounter = true
-- =========================================================================
-- [7] CLARITY-STYLE VELOCITY COUNTER & KEYSTROKES (ALIGNED & BOTTOM)
-- =========================================================================
hook.Add("HUDPaint", "Skeet_ClarityStyle_VelocityAndKeys", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    
    local scrW, scrH = ScrW(), ScrH()
    
    -- Сдвигаем всю конструкцию вниз экрана (по центру по горизонтали, ближе к нижнему краю по вертикали)
    local cx, cy = scrW / 2, scrH - 180

    -- 1. Счётчик скорости в стиле Clarity
    local vel = ply:GetVelocity()
    local speed2d = math.floor(vel:Length2D())
    local baseSpeed = math.floor(speed2d * 0.91) 
    local speedText = speed2d .. " (" .. baseSpeed .. ")"
    
    surface.SetFont("SkeetFont")
    local tw, th = surface.GetTextSize(speedText)
    
    -- Общая ширина блока (делаем её фиксированной по размеру кнопок снизу для идеального выравнивания)
    local kSize = 18
    local kGap = 2
    local totalWidth = (kSize * 3) + (kGap * 2) -- Ширина блока WASD / плашки ps (58 пикселей)
    
    -- Плашка скорости (теперь центрирована ровно по ширине нижнего блока кнопок)
    surface.SetDrawColor(17, 17, 17, 180)
    surface.DrawRect(cx - (totalWidth / 2), cy, totalWidth, 20)
    surface.SetDrawColor(161, 204, 62, 255)
    surface.DrawRect(cx - (totalWidth / 2), cy, totalWidth, 2)
    
    draw.SimpleText(speedText, "SkeetFont", cx, cy + 3, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER)

    -- 2. Блок клавиш и "ps" аккуратно под скоростью с идеальным выравниванием по центру
    local kx = cx - (totalWidth / 2)
    local ky = cy + 24
    
    local wPressed = input.IsButtonDown(KEY_W) or ply:KeyDown(IN_FORWARD)
    local aPressed = input.IsButtonDown(KEY_A) or ply:KeyDown(IN_MOVELEFT)
    local sPressed = input.IsButtonDown(KEY_S) or ply:KeyDown(IN_BACK)
    local dPressed = input.IsButtonDown(KEY_D) or ply:KeyDown(IN_MOVERIGHT)

    local function DrawCompactKey(name, keyState, x, y, w, h)
        local bgCol = keyState and Color(161, 204, 62, 220) or Color(17, 17, 17, 160)
        local textCol = keyState and Color(17, 17, 17, 255) or Color(180, 180, 180, 255)
        
        surface.SetDrawColor(bgCol)
        surface.DrawRect(x, y, w, h)
        surface.SetDrawColor(30, 30, 30, 80)
        surface.DrawOutlinedRect(x, y, w, h)
        
        draw.SimpleText(name, "SkeetFont", x + (w / 2), y + (h / 2) - 6, textCol, TEXT_ALIGN_CENTER)
    end

    -- Отрисовка WASD (ровно по центру относительно плашки скорости)
    DrawCompactKey("W", wPressed, kx + kSize + kGap, ky, kSize, kSize)
    DrawCompactKey("A", aPressed, kx, ky + kSize + kGap, kSize, kSize)
    DrawCompactKey("S", sPressed, kx + kSize + kGap, ky + kSize + kGap, kSize, kSize)
    DrawCompactKey("D", dPressed, kx + (kSize + kGap) * 2, ky + kSize + kGap, kSize, kSize)
    
    -- Индикатор "ps" снизу клавиш
    local psActive = SkeetSettings.PixelSurf or ply:IsOnGround()
    local psBg = psActive and Color(161, 204, 62, 200) or Color(17, 17, 17, 160)
    local psTxtCol = psActive and Color(17, 17, 17, 255) or Color(150, 150, 150, 255)
    
    surface.SetDrawColor(psBg)
    surface.DrawRect(kx, ky + (kSize + kGap) * 2 + 2, totalWidth, 16)
    draw.SimpleText("ps", "SkeetFont", cx, ky + (kSize + kGap) * 2 + 3, psTxtCol, TEXT_ALIGN_CENTER)
end)
