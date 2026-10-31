-- ============================================================
-- ModLoader.lua — MINI VERSION
-- ESP + Aimbot + Player Color (لون اللاعب)
-- بدون دوال BRPlayerCharacterBase
-- ============================================================

local packageName = import("KismetSystemLibrary").GetGameBundleId()
local SUPPORTED_PACKAGES = {
    ["com.tencent.ig"]="GL", ["com.pubg.krmobile"]="KR", ["com.rekoo.pubgm"]="TW",
    ["com.vng.pubgmobile"]="VNG", ["com.pubg.imobile"]="BGMI",
    ["com.tencent.tmgp.pubgmhd"]="CN",
}
_G.GTLMOD_PackageName = packageName
_G.GTLMOD_Version = SUPPORTED_PACKAGES[packageName] or "UNKNOWN"

local function Notify(msg)
    local s = "[GTLMOD] " .. tostring(msg)
    pcall(function() if _G.GTLMODNotify then _G.GTLMODNotify(s) end end)
    print(s)
end

local _slua = rawget(_G, "slua")
local function Valid(obj)
    if not obj then return false end
    if _slua and _slua.isValid then
        local ok, v = pcall(_slua.isValid, obj)
        if not ok or not v then return false end
    end
    return true
end

local _cached_ticker = nil
local function GetTicker()
    if not _cached_ticker then
        local ok, t = pcall(require, "common.time_ticker")
        if ok and t then _cached_ticker = t end
    end
    return _cached_ticker
end

local _cached_ui_util = nil
local function GetUIUtil()
    if not _cached_ui_util then
        local ok, u = pcall(require, "client.common.ui_util")
        if ok and u then _cached_ui_util = u end
    end
    return _cached_ui_util
end

-- ==========================================
-- COLORS
-- ==========================================
local C_GREEN  = {R=0,   G=255, B=0,   A=255}
local C_RED    = {R=255, G=0,   B=0,   A=255}
local C_CYAN   = {R=0,   G=255, B=255, A=255}
local C_YELLOW = {R=255, G=255, B=0,   A=255}
local SCALE_COLOR_V2 = {R=3, G=3, B=0, A=0}

-- ==========================================
-- CONFIG — كل شيء ON تلقائي
-- ==========================================
_G.GTLMODConfig = _G.GTLMODConfig or {
    EspVip = true, EspRadar = true, Esp5 = true, Esp6 = false,
    Esp7 = true, EspCounter = true, EspWeapon = true,
    EspName = true, EspAntenna = false,
    AimTouchEnable = true,   -- هيد
    AimTouchChest = false,   -- صدر
    AimTouchIgKnock = true, AimTouchIgBot = true, AimTouchVisCheck = true,
    ColorBodyV2 = true,      -- لون اللاعب ON
}

_G.GTLMODState = _G.GTLMODState or {
    LoopToken = 0, AimbotLoopToken = 0,
    TrackedMarks = {}, EnemyMarks = {},
    CustomTextData = {},
}

_G.ColorConfig = _G.ColorConfig or {
    VisibleColor = 4,    -- أخضر
    InvisibleColor = 1,  -- أحمر
    Brightness = 25,
}

local COLOR_MAP = {
    [1]={R=255,G=0,B=0},   [2]={R=255,G=255,B=255}, [3]={R=255,G=255,B=0},
    [4]={R=0,G=255,B=0},   [5]={R=0,G=255,B=255},   [6]={R=0,G=0,B=255},
    [7]={R=255,G=0,B=255}
}
local function GetAppliedColor(idx, bri)
    local base = COLOR_MAP[idx] or COLOR_MAP[4]
    local b = bri or 25
    return {
        R = math.min(255, (base.R or 0) * b / 25),
        G = math.min(255, (base.G or 0) * b / 25),
        B = math.min(255, (base.B or 0) * b / 25),
        A = 255
    }
end

-- ==========================================
-- BOT DETECTION
-- ==========================================
local function GetSafeEnemyKey(enemy)
    if Valid(enemy) then
        if enemy.PlayerKey then return tostring(enemy.PlayerKey) end
        if type(enemy.GetUniqueID) == "function" then return tostring(enemy:GetUniqueID()) end
    end
    return tostring(enemy)
end

local function CheckIsAI(pawn, markData)
    if markData and markData.AK_IS_BOT ~= nil then return markData.AK_IS_BOT end
    local isAI = false
    pcall(function()
        if pawn.bIsAI == true or pawn.IsAI == true then isAI = true end
        local pState = pawn.PlayerState or (type(pawn.GetPlayerState) == "function" and pawn:GetPlayerState())
        if Valid(pState) then
            if pState.bIsABot == true or pState.bIsBot == true or pState.bIsAI == true then isAI = true end
            if not isAI then
                local uid = pState.Uid or pState.UID or pState.PlayerId
                if uid ~= nil and (uid == 0 or uid == "0") then isAI = true end
            end
        end
    end)
    if markData then markData.AK_IS_BOT = isAI end
    return isAI
end

-- ==========================================
-- MAP MARKS
-- ==========================================
local function SafeAddMark(id, pos, z, str, size, actor)
    local mark = nil
    pcall(function()
        local M = require("GameLua.Mod.BaseMod.Common.InGameMarkTools")
        if M and M.ClientAddMapMark then
            mark = M.ClientAddMapMark(id, pos, z, str, size, actor)
            if mark then _G.GTLMODState.TrackedMarks[mark] = true end
        end
    end)
    return mark
end

local function SafeRemoveMark(mark)
    if not mark then return end
    pcall(function()
        local M = require("GameLua.Mod.BaseMod.Common.InGameMarkTools")
        if M and M.HideMapMark then M.HideMapMark(mark) end
        if M and M.RemoveMapMark then M.RemoveMapMark(mark) end
    end)
    _G.GTLMODState.TrackedMarks[mark] = nil
end

-- ==========================================
-- SKELETAL MESHES CACHE
-- ==========================================
local function GetAllSkeletalMeshes(enemy, markData)
    local curTime = os.clock()
    if markData and markData.CachedMeshes and markData.CachedMeshTime and (curTime - markData.CachedMeshTime) < 3.0 then
        local v = {}
        for _, m in ipairs(markData.CachedMeshes) do if Valid(m) then table.insert(v, m) end end
        markData.CachedMeshes = v
        return v
    end
    local meshes = {}
    if Valid(enemy.Mesh) then table.insert(meshes, enemy.Mesh) end
    pcall(function()
        local SMC = import("SkeletalMeshComponent")
        if SMC and type(enemy.GetComponentsByClass) == "function" then
            local childs = enemy:GetComponentsByClass(SMC)
            if childs then
                local count = type(childs.Num) == "function" and childs:Num() or #childs
                for i = 1, count do
                    local comp = type(childs.Get) == "function" and childs:Get(i-1) or childs[i]
                    if Valid(comp) and comp ~= enemy.Mesh then table.insert(meshes, comp) end
                end
            end
        end
    end)
    if markData then markData.CachedMeshes = meshes; markData.CachedMeshTime = curTime end
    return meshes
end

-- ==========================================
-- VISIBILITY CHECK
-- ==========================================
local function IsEnemyVisibleStrong(enemy, pc, markData)
    if not Valid(enemy) or not Valid(pc) then return false end
    if type(pc.LineOfSightTo) ~= "function" then return false end
    local curTime = os.clock()
    if markData and markData.LastVisCheckTime and (curTime - markData.LastVisCheckTime) <= 0.3 then
        if markData.CachedVisible ~= nil then return markData.CachedVisible end
    end
    local visible = false
    pcall(function() if pc:LineOfSightTo(enemy) then visible = true end end)
    if markData then markData.LastVisCheckTime = curTime; markData.CachedVisible = visible end
    return visible
end

-- ==========================================
-- COLOR BODY V2 (لون اللاعب)
-- ==========================================
local function ApplyColorBodyV2(enemy, pc, markData)
    pcall(function()
        local meshes = GetAllSkeletalMeshes(enemy, markData)
        if #meshes == 0 then return end
        local hidden = not IsEnemyVisibleStrong(enemy, pc, markData)
        local WH_ALPHA = 25
        local function ToWH(c) return {R=(c.R or 0)*150/255, G=(c.G or 0)*150/255, B=(c.B or 0)*150/255, A=WH_ALPHA} end
        local visibleColor   = ToWH(GetAppliedColor(_G.ColorConfig.VisibleColor, _G.ColorConfig.Brightness))
        local invisibleColor = ToWH(GetAppliedColor(_G.ColorConfig.InvisibleColor, _G.ColorConfig.Brightness))
        local finalColor = hidden and invisibleColor or visibleColor
        local colorHash = string.format("%d_%d_%d_%d", finalColor.R, finalColor.G, finalColor.B, finalColor.A)
        local currentMeshCount = #meshes
        local isMeshChanged = (markData.LastMeshCount ~= currentMeshCount)
        if not isMeshChanged and markData.LastHiddenState == hidden and markData.LastColorHash == colorHash then return end
        if isMeshChanged and markData.MIDs then markData.MIDs = {} end
        markData.LastHiddenState = hidden
        markData.LastMeshCount = currentMeshCount
        markData.LastColorHash = colorHash
        markData.ColorApplied = true

        for meshIndex, mesh in ipairs(meshes) do
            if Valid(mesh) then
                pcall(function()
                    mesh.LDMaxDrawDistance = -99999
                    mesh.MaxDrawDistanceOffset = -99999
                    mesh.CachedMaxDrawDistance = -99999
                    mesh.UseScopeDistanceCulling = true
                end)
                for i = 0, 10 do
                    local matInterface = mesh:GetMaterial(i)
                    if not Valid(matInterface) then break end
                    local baseMat = matInterface:GetBaseMaterial()
                    if Valid(baseMat) then
                        local matName = tostring(baseMat)
                        if string.find(matName, "Master_Mask", 1, true) then
                            if not markData.MIDs then markData.MIDs = {} end
                            local meshKey = "Mesh_" .. tostring(meshIndex)
                            if not markData.MIDs[meshKey] then markData.MIDs[meshKey] = {} end
                            local mid = markData.MIDs[meshKey][i]
                            if not Valid(mid) then
                                mid = mesh:CreateAndSetMaterialInstanceDynamic(i)
                                markData.MIDs[meshKey][i] = mid
                            end
                            if Valid(mid) then
                                mid:SetVectorParameterValue("颜色", finalColor)
                                mid:SetVectorParameterValue("Extra Light Color", finalColor)
                                mid:SetVectorParameterValue("Para_Color", finalColor)
                                mid:SetVectorParameterValue("Para_ColorTint", finalColor)
                                mid:SetVectorParameterValue("Para_Color_1", finalColor)
                                mid:SetVectorParameterValue("Tint", finalColor)
                                mid:SetVectorParameterValue("Color", finalColor)
                                mid:SetVectorParameterValue("BaseColor", finalColor)
                                mid:SetVectorParameterValue("BodyColor", finalColor)
                                mid:SetVectorParameterValue("MainColor", finalColor)
                                mid:SetVectorParameterValue("DiffuseColor", finalColor)
                                mid:SetVectorParameterValue("EmissiveColor", finalColor)
                                mid:SetVectorParameterValue("ParaScaleOffset", SCALE_COLOR_V2)
                            end
                        end
                    end
                end
            end
        end
    end)
end

local function UndoColorBodyV2(enemy, markData)
    pcall(function()
        if not markData.ColorApplied then return end
        local meshes = GetAllSkeletalMeshes(enemy, markData)
        for meshIndex, mesh in ipairs(meshes) do
            if Valid(mesh) then
                local meshKey = "Mesh_" .. tostring(meshIndex)
                if markData.MIDs and markData.MIDs[meshKey] then
                    for i, mid in pairs(markData.MIDs[meshKey]) do
                        if Valid(mid) then
                            local defC = {R=1, G=1, B=1, A=1}
                            mid:SetVectorParameterValue("颜色", defC)
                            mid:SetVectorParameterValue("Extra Light Color", defC)
                            mid:SetVectorParameterValue("Para_Color", defC)
                            mid:SetVectorParameterValue("Para_ColorTint", defC)
                            mid:SetVectorParameterValue("Para_Color_1", defC)
                            mid:SetVectorParameterValue("Tint", defC)
                            mid:SetVectorParameterValue("Color", defC)
                            mid:SetVectorParameterValue("BaseColor", defC)
                            mid:SetVectorParameterValue("BodyColor", defC)
                            mid:SetVectorParameterValue("MainColor", defC)
                            mid:SetVectorParameterValue("DiffuseColor", defC)
                            mid:SetVectorParameterValue("EmissiveColor", defC)
                        end
                    end
                end
            end
        end
        markData.ColorApplied = false
        markData.LastColorHash = ""
        markData.LastHiddenState = nil
    end)
end

-- ==========================================
-- AIMBOT
-- ==========================================
local function GetEnemyTargets(radius)
    local result = {}
    local GameplayData = require("GameLua.GameCore.Data.GameplayData")
    local player = GameplayData.GetPlayerCharacter()
    if not slua.isValid(player) then return result end
    local chars = {}
    if GameplayData.GetAllPlayerCharacters then chars = GameplayData.GetAllPlayerCharacters()
    elseif GameplayData.GameCharacters then
        for _, c in pairs(GameplayData.GameCharacters) do table.insert(chars, c) end
    end
    local myTeam = player:GetTeamID()
    for _, actor in pairs(chars) do
        if slua.isValid(actor) and actor ~= player and actor.GetTeamID and actor:IsAlive() then
            if actor:GetTeamID() ~= myTeam then
                local d = player:GetDistanceTo(actor)
                if d <= radius then table.insert(result, actor) end
            end
        end
    end
    return result
end

local function DoAimTouch()
    pcall(function()
        if not (_G.GTLMODConfig.AimTouchEnable or _G.GTLMODConfig.AimTouchChest) then return end
        local GameplayData = require("GameLua.GameCore.Data.GameplayData")
        local player = GameplayData.GetPlayerCharacter()
        if not slua.isValid(player) then return end
        local pc = player:GetPlayerControllerSafety()
        if not slua.isValid(pc) then return end

        local isADS = player.bIsGunADS
        local boneIdx = _G.GTLMODConfig.AimTouchChest and 2 or 1
        local fovVal = 30
        local maxDistMeters = isADS and 300 or 250
        local currentMaxDist = maxDistMeters * 100

        local enemies = GetEnemyTargets(currentMaxDist)
        if not enemies or #enemies == 0 then return end

        local FVector2D = import("Vector2D")
        local UGS = import("GameplayStatics")
        local KML = import("KismetMathLibrary")
        local camManager = UGS.GetPlayerCameraManager(pc, 0)
        if not slua.isValid(camManager) then return end
        local camLoc = camManager:GetCameraLocation()
        if not camLoc then return end
        local ui_util = GetUIUtil()
        if not ui_util then return end
        local vs = ui_util.GetViewportSize()
        if not vs then return end
        local centerX = vs.X * 0.5
        local centerY = vs.Y * 0.5
        local FOV_RADIUS = (fovVal / 100.0) * (vs.X / 2.0)

        local bestTarget, bestScore = nil, 99999999
        local selBoneName = boneIdx == 1 and "head" or (boneIdx == 2 and "spine_03" or "pelvis")

        for _, target in ipairs(enemies) do
            if slua.isValid(target) then
                local skip = false
                if _G.GTLMODConfig.AimTouchIgKnock and target.HealthStatus == 1 then skip = true end
                if not skip and _G.GTLMODConfig.AimTouchIgBot then
                    local tId = type(target.GetUniqueID) == "function" and target:GetUniqueID() or tostring(target)
                    _G.BotStatusCache = _G.BotStatusCache or {}
                    local cachedBot = _G.BotStatusCache[tId]
                    if cachedBot == nil then
                        cachedBot = false
                        pcall(function()
                            if target.bIsAI == true or target.IsAI == true then cachedBot = true end
                            local pState = target.PlayerState
                            if slua.isValid(pState) then
                                if pState.bIsABot or pState.bIsBot or pState.bIsAI then cachedBot = true end
                                if not cachedBot then
                                    local uid = pState.Uid or pState.UID
                                    if uid ~= nil and (uid == 0 or uid == "0") then cachedBot = true end
                                end
                            end
                        end)
                        _G.BotStatusCache[tId] = cachedBot
                    end
                    if cachedBot then skip = true end
                end
                if not skip and _G.GTLMODConfig.AimTouchVisCheck then
                    local isHidden = true
                    pcall(function() if pc:LineOfSightTo(target) then isHidden = false end end)
                    if isHidden then skip = true end
                end
                if not skip then
                    local tPos = target:GetBonePos(selBoneName, {X=0, Y=0, Z=0})
                    if not tPos or (tPos.X == 0 and tPos.Y == 0 and tPos.Z == 0) then
                        if type(target.K2_GetActorLocation) == "function" then
                            tPos = target:K2_GetActorLocation()
                            if tPos then tPos.Z = tPos.Z + (boneIdx == 1 and 70 or 40) end
                        end
                    end
                    if tPos and not (tPos.X == 0 and tPos.Y == 0 and tPos.Z == 0) then
                        local screen = FVector2D()
                        if pc:ProjectWorldLocationToScreen(tPos, screen, false) and screen.X > 0 and screen.Y > 0 then
                            local dx, dy = screen.X - centerX, screen.Y - centerY
                            local d = math.sqrt(dx*dx + dy*dy)
                            if d <= FOV_RADIUS and d < bestScore then
                                bestScore = d
                                bestTarget = target
                            end
                        end
                    end
                end
            end
        end

        if not slua.isValid(bestTarget) then return end
        local fp = bestTarget:GetBonePos(selBoneName, {X=0, Y=0, Z=0})
        if not fp then return end
        local rot = KML.FindLookAtRotation(camLoc, fp)
        if not rot then return end
        local curRot = pc:GetControlRotation()
        if not curRot then return end
        local dYaw = rot.Yaw - curRot.Yaw
        local dPitch = rot.Pitch - curRot.Pitch
        if dYaw > 180 then dYaw = dYaw - 360 end
        if dYaw < -180 then dYaw = dYaw + 360 end
        if dPitch > 180 then dPitch = dPitch - 360 end
        if dPitch < -180 then dPitch = dPitch + 360 end
        local smooth = math.max(0.01, 85 / 100 * 0.3)
        pc:SetControlRotation({
            Pitch = curRot.Pitch + dPitch * smooth,
            Yaw = curRot.Yaw + dYaw * smooth,
            Roll = 0
        }, "AimTouch")
    end)
end

-- ==========================================
-- MAIN ESP LOOP
-- ==========================================
local function MainLoop()
    local GameplayData = require("GameLua.GameCore.Data.GameplayData")
    if not GameplayData then return end
    local pc = GameplayData.GetPlayerController()
    local localPlayer = nil
    if Valid(pc) then localPlayer = pc:GetPlayerCharacterSafety() end
    if not Valid(localPlayer) then
        for markId in pairs(_G.GTLMODState.TrackedMarks) do SafeRemoveMark(markId) end
        _G.GTLMODState.TrackedMarks = {}
        _G.GTLMODState.EnemyMarks = {}
        return
    end

    local Cached_MyHUD = pc and pc.MyHUD or nil

    local allCharacters = {}
    if GameplayData.GetAllPlayerCharacters then allCharacters = GameplayData.GetAllPlayerCharacters()
    elseif GameplayData.GameCharacters then
        for _, c in pairs(GameplayData.GameCharacters) do table.insert(allCharacters, c) end
    end

    -- Cleanup
    local validKeys = {}
    for _, e in pairs(allCharacters) do
        if Valid(e) and e ~= localPlayer then validKeys[GetSafeEnemyKey(e)] = true end
    end
    for key, data in pairs(_G.GTLMODState.EnemyMarks) do
        if not validKeys[key] then
            SafeRemoveMark(data.radarMark)
            SafeRemoveMark(data.hpMark)
            SafeRemoveMark(data.distMark)
            if data.MIDs then
                for _, midTable in pairs(data.MIDs) do for k in pairs(midTable) do midTable[k] = nil end end
                data.MIDs = nil
            end
            _G.GTLMODState.EnemyMarks[key] = nil
        end
    end

    for _, enemy in pairs(allCharacters) do
        if Valid(enemy) and enemy ~= localPlayer and enemy.TeamID ~= localPlayer.TeamID then
            local bDead = false
            pcall(function()
                if type(enemy.IsDead) == "function" then bDead = enemy:IsDead()
                if enemy.HealthStatus ~= nil and enemy.HealthStatus == 2 then bDead = true end
            end)

            local eKey = GetSafeEnemyKey(enemy)
            _G.GTLMODState.EnemyMarks[eKey] = _G.GTLMODState.EnemyMarks[eKey] or { enemy = enemy }
            local markData = _G.GTLMODState.EnemyMarks[eKey]
            markData.enemy = enemy

            if not bDead then
                if markData.lastEnemyActor ~= enemy then
                    if markData.hpMark then SafeRemoveMark(markData.hpMark); markData.hpMark = nil end
                    if markData.distMark then SafeRemoveMark(markData.distMark); markData.distMark = nil end
                    if markData.radarMark then SafeRemoveMark(markData.radarMark); markData.radarMark = nil end
                    markData.lastEnemyActor = enemy
                end

                local distM = 0
                pcall(function() distM = localPlayer:GetDistanceTo(enemy) / 100 end)
                local currentHp, maxHp = 100, 100
                pcall(function()
                    if enemy.Health then currentHp = enemy.Health end
                    if enemy.HealthMax then maxHp = enemy.HealthMax end
                end)
                if maxHp <= 0 then maxHp = 100 end
                local hpRatio = currentHp / maxHp

                -- ========== لون اللاعب ==========
                if _G.GTLMODConfig.ColorBodyV2 then ApplyColorBodyV2(enemy, pc, markData)
                else UndoColorBodyV2(enemy, markData) end

                -- ========== ESP NAME ==========
                if _G.GTLMODConfig.EspName then
                    pcall(function()
                        local hud = Cached_MyHUD
                        if not (Valid(hud) and hud.AddDebugText) then return end
                        if distM > 400 then return end
                        local pName = enemy.PlayerName or "Enemy"
                        if pName == "" then return end
                        local isKnock = (enemy.Health or 100) <= 0 or enemy.HealthStatus == 1
                        local bVis = IsEnemyVisibleStrong(enemy, pc, markData)
                        local visCol = GetAppliedColor(_G.ColorConfig.VisibleColor, _G.ColorConfig.Brightness)
                        local invCol = GetAppliedColor(_G.ColorConfig.InvisibleColor, _G.ColorConfig.Brightness)
                        local col = isKnock and {R=0,G=0,B=255,A=255} or (bVis and visCol or invCol)
                        hud:AddDebugText(pName, enemy, 0.2, {X=0,Y=0,Z=120}, {X=0,Y=0,Z=120}, col, true, false, true, nil, 1.0, true)
                    end)
                end

                -- ========== ESP VIP MARKS ==========
                if _G.GTLMODConfig.EspVip then
                    if markData.hpMark == nil then
                        markData.hpMark = SafeAddMark(1006, FVector(0,0,0), 0, "", 4, enemy)
                    end
                    if markData.distMark == nil then
                        markData.distMark = SafeAddMark(9999, FVector(0,0,0), 0, "", 4, enemy)
                    end
                end

                -- ========== ESP RADAR ==========
                if _G.GTLMODConfig.EspRadar then
                    if not markData.radarMark or markData.radarMark == 0 then
                        markData.radarMark = SafeAddMark(8888, FVector(0,0,0), 0, "", 4, enemy)
                    end
                end

                -- ========== ESP FRAME UI ==========
                if _G.GTLMODConfig.Esp5 or _G.GTLMODConfig.EspVip then
                    pcall(function()
                        if enemy.Replay_IsEnemyFrameUIExisted and not enemy:Replay_IsEnemyFrameUIExisted() then
                            enemy:Replay_CreateEnemyFrameUI(true, true)
                        end
                        if enemy.Replay_SetVisiableOfFrameUI then enemy:Replay_SetVisiableOfFrameUI(true) end
                        if enemy.Replay_UpdateEnemyFrameUI then enemy:Replay_UpdateEnemyFrameUI(hpRatio) end
                    end)
                end

                -- ========== ESP WEAPON ==========
                if _G.GTLMODConfig.EspWeapon then
                    pcall(function()
                        local hud = Cached_MyHUD
                        if not Valid(hud) then return end
                        if distM > 400 then return end
                        local ct = os.clock()
                        if markData.AK_LAST_WEP_TIME == nil or ct > markData.AK_LAST_WEP_TIME + 1.5 then
                            local w = nil
                            if type(enemy.GetCurrentWeapon) == "function" then w = enemy:GetCurrentWeapon() end
                            local wName = "No Weapon"
                            if Valid(w) and type(w.GetWeaponName) == "function" then wName = w:GetWeaponName() end
                            markData.AK_CACHED_WEP = tostring(wName)
                            markData.AK_LAST_WEP_TIME = ct
                        end
                        local txt = markData.AK_CACHED_WEP or "No Weapon"
                        if txt ~= "" then
                            local col = (markData.AK_IS_BOT) and C_CYAN or C_YELLOW
                            local sc = math.max(0.5, 0.8 - (distM / 400))
                            hud:AddDebugText(txt, enemy, 0.5, {X=0,Y=0,Z=100}, {X=0,Y=0,Z=100}, col, true, false, true, nil, sc, true)
                        end
                    end)
                end
            end
        end
    end

    -- ========== ESP COUNTER ==========
    if _G.GTLMODConfig.Esp7 or _G.GTLMODConfig.EspCounter then
        pcall(function()
            local hud = Cached_MyHUD
            if not Valid(hud) then return end
            local myTeam = localPlayer.TeamID or 0
            local myPos = localPlayer:K2_GetActorLocation()
            local maxDist = 35000
            local maxSq = maxDist * maxDist
            local realCount, aiCount = 0, 0
            _G.BotStatusCache = _G.BotStatusCache or {}
            for _, tp in pairs(allCharacters) do
                if slua.isValid(tp) and tp ~= localPlayer and (tp.TeamID or 0) ~= myTeam then
                    local ep = tp:K2_GetActorLocation()
                    if ep then
                        local dx, dy, dz = ep.X - myPos.X, ep.Y - myPos.Y, ep.Z - myPos.Z
                        if (dx*dx + dy*dy + dz*dz) <= maxSq then
                            local pid = tostring(tp)
                            local isAI = _G.BotStatusCache[pid]
                            if isAI == nil then
                                isAI = false
                                pcall(function()
                                    local ps = tp.PlayerState
                                    if slua.isValid(ps) then
                                        if ps.bIsABot or ps.bIsBot or ps.bIsAI then isAI = true end
                                        if not isAI then
                                            local uid = ps.Uid or ps.UID
                                            if uid ~= nil and (uid == 0 or uid == "0") then isAI = true end
                                        end
                                    end
                                end)
                                _G.BotStatusCache[pid] = isAI
                            end
                            if isAI then aiCount = aiCount + 1 else realCount = realCount + 1 end
                        end
                    end
                end
            end
            local total = realCount + aiCount
            if _G.GTLMODConfig.Esp7 then
                local txt = total > 0 and string.format("ENEMY (P:%d | B:%d)", realCount, aiCount) or "( CLEAR )"
                local col = total > 0 and C_RED or C_GREEN
                hud:AddDebugText(txt, localPlayer, 1.2, {X=0,Y=0,Z=150}, {X=0,Y=0,Z=150}, col, true, false, true, nil, 1.0, true)
            end
        end)
    end
end

-- ==========================================
-- LOOPS
-- ==========================================
local function FastTick()
    local ticker = GetTicker()
    pcall(MainLoop)
    if ticker and ticker.AddTimerOnce then ticker.AddTimerOnce(0.4, FastTick) end
end

local function FastAimbotTick()
    local ticker = GetTicker()
    pcall(DoAimTouch)
    if ticker and ticker.AddTimerOnce then ticker.AddTimerOnce(0.016, FastAimbotTick) end
end

-- ==========================================
-- START
-- ==========================================
local ticker = GetTicker()
if ticker and ticker.AddTimerOnce then
    ticker.AddTimerOnce(1.0, function()
        Notify("MINI MOD Loaded — ESP + Aimbot + Color ON")
        FastTick()
        FastAimbotTick()
    end)
else
    Notify("MINI MOD: ticker unavailable")
end