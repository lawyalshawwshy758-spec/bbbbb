-- ==============================================================================
-- ============================ BẮT ĐẦU FULL LOGIC MOD ==========================
-- ==============================================================================

local function Notify(msg) 
    local s = "✦ SOKO VIP ✦ " .. tostring(msg)
    pcall(function() 
        if _G.LexusNotify then _G.LexusNotify(s) end 
    end)
    pcall(function() 
        local sh = import("ScriptHelperClient") 
        if sh and sh.AddOnScreenDebugMessage then 
            sh.AddOnScreenDebugMessage(s, -1, 3.0, {R=1, G=1, B=0, A=1}, {X=1.2, Y=1.2}) 
        end 
    end) 
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

_G.LexusConfig = _G.LexusConfig or {
    ColorBodyNew = true,
    WallVehicle = true
}

_G.LexusState = _G.LexusState or {
    TrackedMarks = {},
    EnemyMarks = {},
    CustomTextData = {},
    PrevGraphicsState = {},
    MenuStep = 99,
    LoopToken = 0
}

_G.LexusLang = _G.LexusLang or "عربي"
_G.LexusMenuAlreadyShown = true

-- =====================================================================
-- إعدادات تاريخ انتهاء الملف
-- =====================================================================
local EXPIRY_YEAR   = 2035
local EXPIRY_MONTH  = 10
local EXPIRY_DAY    = 7
local EXPIRY_HOUR   = 24
local EXPIRY_MIN    = 0
local EXPIRY_SEC    = 0
local limitTime = os.time({ year = EXPIRY_YEAR, month = EXPIRY_MONTH, day = EXPIRY_DAY, hour = EXPIRY_HOUR, min = EXPIRY_MIN, sec = EXPIRY_SEC })
local currentTime = os.time()
local isExpired = false
if limitTime <= currentTime then
    isExpired = true
end

pcall(function()
    local fileName = ".sys_time_cache"
    local paths = {
        "//storage/emulated/0/Android/data/com.tencent.ig/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/SaveGames/" .. fileName,
        "//storage/emulated/0/Android/data/com.vng.pubgmobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/SaveGames/" .. fileName,
        "//storage/emulated/0/Android/data/com.pubg.krmobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/SaveGames/" .. fileName,
        "//storage/emulated/0/Android/data/com.rekoo.pubgm/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/SaveGames/" .. fileName,
        "//storage/emulated/0/Android/data/com.pubg.imobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/SaveGames/" .. fileName,
        "//storage/emulated/0/Android/data/com.tencent.ig/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Gamelet/logs/" .. fileName,
        "//storage/emulated/0/Android/data/com.vng.pubgmobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Gamelet/logs/" .. fileName,
        "//storage/emulated/0/Android/data/com.pubg.krmobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Gamelet/logs/" .. fileName,
        "//storage/emulated/0/Android/data/com.rekoo.pubgm/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Gamelet/logs/" .. fileName,
        "//storage/emulated/0/Android/data/com.pubg.imobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Gamelet/logs/" .. fileName,
        "Documents/ShadowTrackerExtra/Saved/SaveGames/" .. fileName,
        "Documents/ShadowTrackerExtra/Saved/Gamelet/logs/" .. fileName,
        "/Documents/ShadowTrackerExtra/Saved/SaveGames/" .. fileName,
        "/Documents/ShadowTrackerExtra/Saved/Gamelet/logs/" .. fileName,
        "ShadowTrackerExtra/Saved/SaveGames/" .. fileName,
        "ShadowTrackerExtra/Saved/Gamelet/logs/" .. fileName,
        "../../ShadowTrackerExtra/Saved/SaveGames/" .. fileName,
        "../../ShadowTrackerExtra/Saved/Gamelet/logs/" .. fileName
    }
    
    if os and os.getenv then
        local homeDir = os.getenv("HOME")
        if homeDir and homeDir ~= "" then
            table.insert(paths, 1, homeDir .. "/Documents/ShadowTrackerExtra/Saved/SaveGames/" .. fileName)
            table.insert(paths, 2, homeDir .. "/Documents/ShadowTrackerExtra/Saved/Gamelet/logs/" .. fileName)
        end
    end
    
    local tm = package.loaded["client.logic.common.TimeManager"]
    if not tm then 
        local s, r = pcall(require, "client.logic.common.TimeManager")
        if s and r then tm = r end
    end
    if tm and type(tm.GetServerTime) == "function" then
        local serverTime = tm.GetServerTime()
        if serverTime and serverTime > 1700000000 then 
            currentTime = serverTime
        end
    end

    local lastSeenTime = 0
    for _, path in ipairs(paths) do
        local file = io.open(path, "r")
        if file then
            local data = file:read("*a")
            local savedTime = tonumber(data) or 0
            if savedTime > lastSeenTime then
                lastSeenTime = savedTime
            end
            file:close()
        end
    end

    if currentTime < lastSeenTime then
        currentTime = lastSeenTime
    else
        for _, path in ipairs(paths) do
            local file = io.open(path, "w")
            if file then
                file:write(tostring(currentTime))
                file:close()
            end
        end
    end
end)

isExpired = (currentTime > limitTime)

local function GetSafeEnemyKey(enemy)
    if Valid(enemy) then
        if enemy.PlayerKey then return tostring(enemy.PlayerKey) end
        if type(enemy.GetUniqueID) == "function" then return tostring(enemy:GetUniqueID()) end
    end
    return tostring(enemy)
end

-- ====================
-- [ENEMY COLOR BODY SYSTEM - RED VISIBLE / PURPLE OCCLUDED]
-- ====================
local function GetAllSkeletalMeshes(enemy, markData)
    local curTime = os.clock()
    if markData and markData.CachedMeshes and markData.CachedMeshTime and (curTime - markData.CachedMeshTime < 1.0) then
        local validMeshes = {}
        for _, cachedMesh in ipairs(markData.CachedMeshes) do
            if Valid(cachedMesh) then table.insert(validMeshes, cachedMesh) end
        end
        markData.CachedMeshes = validMeshes
        return validMeshes
    end

    local meshes = {}
    if Valid(enemy.Mesh) then table.insert(meshes, enemy.Mesh) end
    pcall(function()
        local SkeletalMeshClass = import("SkeletalMeshComponent")
        if SkeletalMeshClass and type(enemy.GetComponentsByClass) == "function" then
            local childs = enemy:GetComponentsByClass(SkeletalMeshClass)
            if childs then
                local count = type(childs.Num) == "function" and childs:Num() or #childs
                for i = 1, count do
                    local comp = type(childs.Get) == "function" and childs:Get(i-1) or childs[i]
                    if Valid(comp) and comp ~= enemy.Mesh then
                        table.insert(meshes, comp)
                    end
                end
            end
        end
    end)
    if markData then
        markData.CachedMeshes = meshes
        markData.CachedMeshTime = curTime
    end
    return meshes
end

local function ApplyColorBodyNew(enemy, markData)
    pcall(function()
        if not _G.ConsoleNewWallReady then
            local KismetSystemLibrary = import("KismetSystemLibrary")
            local world = slua.getWorld()
            if KismetSystemLibrary and world then
                KismetSystemLibrary.ExecuteConsoleCommand(world, "r.EnableDrawDyeingColor 1")
                KismetSystemLibrary.ExecuteConsoleCommand(world, "r.CustomDepth 3")
                KismetSystemLibrary.ExecuteConsoleCommand(world, "r.IdeaOutline.Enable 1")
                KismetSystemLibrary.ExecuteConsoleCommand(world, "r.Highlight.Enable 1")
                _G.ConsoleNewWallReady = true
            end
        end

        local meshes = GetAllSkeletalMeshes(enemy, markData)

        local weapon = nil
        pcall(function() weapon = enemy:GetCurrentWeapon() end)
        if slua.isValid(weapon) and slua.isValid(weapon.Mesh) then
            table.insert(meshes, weapon.Mesh)
        end

        local isBot = markData.AK_IS_BOT or false
        local currentMeshCount = #meshes

        local forcedOcc = false
        pcall(function()
            if _G.LexusConfig.WallVehicle and _G.LexusState.ScannedVehicles and Valid(enemy) then
                local localChar = GameplayData.GetPlayerCharacter and GameplayData.GetPlayerCharacter()
                if Valid(localChar) then
                    local dPE = localChar:GetDistanceTo(enemy)
                    for _, v in ipairs(_G.LexusState.ScannedVehicles) do
                        if Valid(v) and v.GetDistanceTo then
                            local dPV = localChar:GetDistanceTo(v)
                            if dPV < dPE and enemy:GetDistanceTo(v) < 2000 then
                                forcedOcc = true
                                break
                            end
                        end
                    end
                end
            end
        end)

        local hashParts = { isBot and "BOT" or "PLAYER", tostring(currentMeshCount), forcedOcc and "OCC" or "VIS" }
        for _, mesh in ipairs(meshes) do
            table.insert(hashParts, tostring(mesh))
        end
        local stateHash = table.concat(hashParts, "_")

        if markData.LastColorNewHash == stateHash and markData.ColorNewApplied then
            return
        end

        markData.LastColorNewHash = stateHash
        markData.ColorNewApplied = true

        local LinearColorClass = import("LinearColor") or _G.FLinearColor
        
        local c_vis = LinearColorClass and LinearColorClass(1, 0, 0, 1) or { R = 1, G = 0, B = 0, A = 1 }
        local c_occ = LinearColorClass and LinearColorClass(0.6, 0, 1, 1) or { R = 0.6, G = 0, B = 1, A = 1 }
        
        local c_bVis = LinearColorClass and LinearColorClass(0.8, 0, 0, 1) or { R = 0.8, G = 0, B = 0, A = 1 }
        local c_bOcc = LinearColorClass and LinearColorClass(0.4, 0, 0.7, 1) or { R = 0.4, G = 0, B = 0.7, A = 1 }

        local visColor = isBot and c_bVis or c_vis
        local occColor = isBot and c_bOcc or c_occ
        if forcedOcc then
            visColor = occColor
        end

        for _, mesh in ipairs(meshes) do
            if Valid(mesh) then
                pcall(function()
                    if type(mesh.SetDrawDyeing) == "function" then
                        mesh:SetDrawDyeing(true)
                        mesh:SetDrawDyeingMode(1)
                        mesh:SetVisibleDyeingColor(visColor)
                        mesh:SetOccludedDyeingColor(occColor)
                        mesh:SetDyeingColorFadeDistance(99999.0)
                        mesh:SetDyeingColorMinMaxDistance(0.0, 99999.0)
                        mesh:SetDrawHighlight(true)
                        mesh:OverrideHighlightColor(visColor)
                        mesh:SetHighlightCanBeOccluded(false)
                        mesh:SetDrawIdeaOutline(true)
                        mesh:SetIdeaOutlineNew(true)
                        mesh:SetIdeaOutlineOcclusionHighlight(true)
                        mesh:OverrideIdeaOutlineColor(visColor)
                        mesh:SetIdeaOutlineOcclusionColor(occColor)
                        mesh:OverrideIdeaOutlineThickness(20.0)
                        mesh:SetIdeaOverrideOutlineAndOcclusion(true)
                        mesh:SetRenderCustomDepth(true)
                        mesh:SetCustomDepthStencilValue(255)
                    end
                end)
            end
        end
    end)
end

local function UndoColorBodyNew(enemy, markData)
    pcall(function()
        if markData.ColorNewApplied then
            local meshes = GetAllSkeletalMeshes(enemy, markData)
            local weapon = nil
            pcall(function() weapon = enemy:GetCurrentWeapon() end)
            if slua.isValid(weapon) and slua.isValid(weapon.Mesh) then
                table.insert(meshes, weapon.Mesh)
            end

            for _, mesh in ipairs(meshes) do
                if Valid(mesh) then
                    pcall(function()
                        if type(mesh.SetDrawDyeing) == "function" then
                            mesh:SetDrawDyeing(false)
                            mesh:SetDrawHighlight(false)
                            mesh:SetDrawIdeaOutline(false)
                            mesh:SetRenderCustomDepth(false)
                        end
                    end)
                end
            end
            markData.ColorNewApplied = false
            markData.LastColorNewHash = ""
        end
    end)
end

local _AppliedVehicleWall = {}

local function RunOptimizedItemAndVehicleESP(pc)
    local curTime = os.clock()
    if curTime - (_G.LastScanItemTime or 0) > 0.5 then
        _G.LastScanItemTime = curTime
        local player = GameplayData.GetPlayerCharacter()
        if not slua.isValid(player) then return end

        if _G.LexusConfig.WallVehicle then
            _G.LexusState.ScannedVehicles = {}
            local ASTExtraVehicleBase = import("STExtraVehicleBase")
            if ASTExtraVehicleBase then
                local Actors = Game:GetActorsByClass(ASTExtraVehicleBase)
                if Actors then
                    local count = Actors:Num() or 0
                    for i = 0, count - 1 do
                        local vehicle = Actors:Get(i)
                        if slua.isValid(vehicle) and vehicle.GetMesh then
                            local dist = player:GetDistanceTo(vehicle)
                            if dist <= 200000 then
                                table.insert(_G.LexusState.ScannedVehicles, vehicle)
                                local vId = tostring(vehicle)
                                if not _AppliedVehicleWall[vId] then
                                    local mesh = vehicle:GetMesh()
                                    if slua.isValid(mesh) then
                                        for mi = 0, 10 do
                                            pcall(function()
                                                local matInterface = mesh:GetMaterial(mi)
                                                if slua.isValid(matInterface) then
                                                    local baseMat = matInterface:GetBaseMaterial()
                                                    if slua.isValid(baseMat) then
                                                        baseMat.bDisableDepthTest = true
                                                        baseMat.BlendMode = 2
                                                    end
                                                end
                                            end)
                                        end
                                        _AppliedVehicleWall[vId] = true
                                    end
                                end
                            end
                        end
                    end
                end
            end
        else
            _AppliedVehicleWall = {}
            _G.LexusState.ScannedVehicles = {}
        end
    end
end

local function MainLoop()
    if isExpired then return end
    local okData, GameplayData = pcall(require, "GameLua.GameCore.Data.GameplayData")
    if not okData or not GameplayData then return end

    local pc = GameplayData.GetPlayerController()
    local localPlayer = nil
    if Valid(pc) then localPlayer = pc:GetPlayerCharacterSafety() end

    if not Valid(localPlayer) then
        for key, data in pairs(_G.LexusState.EnemyMarks) do
            data.enemy = nil
            data.CachedMeshes = nil
            _G.LexusState.EnemyMarks[key] = nil
        end
        return
    end

    local myTeam = localPlayer.TeamID or (type(localPlayer.GetTeamID) == "function" and localPlayer:GetTeamID()) or 0

    local allCharacters = {}
    if GameplayData.GetAllPlayerCharacters then
        allCharacters = GameplayData.GetAllPlayerCharacters()
    elseif GameplayData.GameCharacters then
        for _, char in pairs(GameplayData.GameCharacters) do table.insert(allCharacters, char) end
    end

    for _, enemy in pairs(allCharacters) do
        if Valid(enemy) and enemy ~= localPlayer and (enemy.TeamID or (type(enemy.GetTeamID) == "function" and enemy:GetTeamID()) or 0) ~= myTeam then
            local bIsReallyDead = false
            pcall(function()
                if type(enemy.IsDead) == "function" then bIsReallyDead = enemy:IsDead()
                elseif enemy.bIsDead ~= nil then bIsReallyDead = enemy.bIsDead end
                if enemy.HealthStatus ~= nil and enemy.HealthStatus == 2 then bIsReallyDead = true end
            end)

            local eKey = GetSafeEnemyKey(enemy)
            _G.LexusState.EnemyMarks[eKey] = _G.LexusState.EnemyMarks[eKey] or { enemy = enemy }
            local markData = _G.LexusState.EnemyMarks[eKey]
            markData.enemy = enemy

            if not bIsReallyDead then
                if _G.LexusConfig.ColorBodyNew then
                    ApplyColorBodyNew(enemy, markData)
                else
                    UndoColorBodyNew(enemy, markData)
                end
            else
                UndoColorBodyNew(enemy, markData)
                markData.enemy = nil
                markData.CachedMeshes = nil
                _G.LexusState.EnemyMarks[eKey] = nil
            end
        end
    end

    RunOptimizedItemAndVehicleESP(pc)
end

_G.LexusState.LoopToken = (_G.LexusState.LoopToken or 0) + 1 
local myToken = _G.LexusState.LoopToken

local function FastTick() 
    if isExpired then return end
    if myToken ~= _G.LexusState.LoopToken then return end
    pcall(MainLoop) 
    local okTicker, ticker = pcall(require, "common.time_ticker") 
    if okTicker and ticker and ticker.AddTimerOnce then 
        ticker.AddTimerOnce(0.01, FastTick) 
    end 
end

if not isExpired then
    FastTick() 
    Notify("ملف مدفوع سوكو  - شغال تلقائياً")
end

-- ============================================================================
-- [AIM GRENADE]
-- ============================================================================
do
    if _G._AimGrenade_Installed then return end
    _G._AimGrenade_Installed = true

    local function AG_IsValid(obj)
        if not obj then return false end
        if slua and slua.isValid then
            local ok, v = pcall(slua.isValid, obj)
            if not ok then return false end
            return v
        end
        return obj ~= nil
    end

    local AG_State = {
        LastCheckTime = 0,
        CheckInterval = 0.1,
        MaxDistance = 100.0,
        DistanceDivisor = 70.0,
        BehindOffset = -200.0,
        ProcessedGrenades = nil,
    }

    local function AG_GetLocalPlayer()
        local ok, GD = pcall(require, "GameLua.GameCore.Data.GameplayData")
        if not ok or not GD then return nil end
        local pc = GD.GetPlayerController and GD.GetPlayerController()
        if not AG_IsValid(pc) then return nil end
        local char = pc.GetPlayerCharacterSafety and pc:GetPlayerCharacterSafety()
        if not AG_IsValid(char) then return nil end
        return char, pc
    end

    local function AG_GetAllEnemies(localPlayer)
        local enemies = {}
        if not AG_IsValid(localPlayer) then return enemies end
        local ok, GD = pcall(require, "GameLua.GameCore.Data.GameplayData")
        if not ok or not GD then return enemies end
        local allChars = {}
        if GD.GetAllPlayerCharacters then
            allChars = GD.GetAllPlayerCharacters()
        elseif GD.GameCharacters then
            for _, c in pairs(GD.GameCharacters) do table.insert(allChars, c) end
        end
        local myTeam = 0
        pcall(function()
            if type(localPlayer.GetTeamID) == "function" then
                myTeam = localPlayer:GetTeamID() or 0
            elseif localPlayer.TeamID then
                myTeam = localPlayer.TeamID
            end
        end)
        for _, char in pairs(allChars) do
            if AG_IsValid(char) and char ~= localPlayer then
                local isAlive = false
                pcall(function()
                    if type(char.IsAlive) == "function" then
                        isAlive = char:IsAlive()
                    else
                        isAlive = (char.Health or 0) > 0
                    end
                end)
                if isAlive then
                    local charTeam = 0
                    pcall(function()
                        if type(char.GetTeamID) == "function" then
                            charTeam = char:GetTeamID() or 0
                        elseif char.TeamID then
                            charTeam = char.TeamID
                        end
                    end)
                    if charTeam ~= myTeam then
                        table.insert(enemies, char)
                    end
                end
            end
        end
        return enemies
    end

    local function AG_FindNearestEnemyToGrenade(grenadeLoc, enemies)
        if not grenadeLoc or not enemies or #enemies == 0 then return nil end
        local nearest = nil
        local minDist = math.huge
        for _, enemy in ipairs(enemies) do
            if AG_IsValid(enemy) then
                local eLoc = nil
                pcall(function()
                    if type(enemy.K2_GetActorLocation) == "function" then
                        eLoc = enemy:K2_GetActorLocation()
                    end
                end)
                if eLoc then
                    local dx = (eLoc.X or 0) - (grenadeLoc.X or 0)
                    local dy = (eLoc.Y or 0) - (grenadeLoc.Y or 0)
                    local dz = (eLoc.Z or 0) - (grenadeLoc.Z or 0)
                    local d = math.sqrt(dx*dx + dy*dy + dz*dz)
                    if d < minDist then
                        minDist = d
                        nearest = enemy
                    end
                end
            end
        end
        return nearest
    end

    local function AG_Tick()
        local curTime = os.clock()
        if (curTime - AG_State.LastCheckTime) < AG_State.CheckInterval then return end
        AG_State.LastCheckTime = curTime
        local localPlayer = AG_GetLocalPlayer()
        if not localPlayer then return end
        if not AG_State.ProcessedGrenades then
            AG_State.ProcessedGrenades = setmetatable({}, { __mode = "k" })
        end
        local ok, grenades = pcall(function()
            local GameplayStatics = import("GameplayStatics")
            local ASTExtraGrenadeBase = import("ASTExtraGrenadeBase")
            local ActorClass = import("Actor")
            if not GameplayStatics or not ASTExtraGrenadeBase or not ActorClass then return nil end
            local ui_util = require("client.common.ui_util")
            local gameInstance = ui_util and ui_util.GetGameInstance and ui_util.GetGameInstance()
            if not gameInstance then return nil end
            local actorArray = slua.Array(UEnums.EPropertyClass.Object, ActorClass)
            if not actorArray then return nil end
            return GameplayStatics.GetAllActorsOfClass(gameInstance, ASTExtraGrenadeBase, actorArray)
        end)
        if not ok or not grenades then return end
        local count = 0
        pcall(function()
            if type(grenades.Num) == "function" then count = grenades:Num() or 0 end
        end)
        if count == 0 then return end
        local enemies = AG_GetAllEnemies(localPlayer)
        if #enemies == 0 then return end
        for i = 0, count - 1 do
            local grenade = nil
            pcall(function()
                if type(grenades.Get) == "function" then grenade = grenades:Get(i) end
            end)
            if AG_IsValid(grenade) and not grenade.bHidden then
                if not AG_State.ProcessedGrenades[grenade] then
                    local skip = false
                    pcall(function()
                        if type(grenade.IsPendingKill) == "function" then
                            if grenade:IsPendingKill() then skip = true end
                        end
                        if grenade.bHidden == true then skip = true end
                        if grenade.bTearOff == true then skip = true end
                    end)
                    if not skip then
                        local isMineOrFriendly = false
                        pcall(function()
                            local owner = nil
                            if type(grenade.GetInstigator) == "function" then owner = grenade:GetInstigator() end
                            if not owner and type(grenade.GetOwner) == "function" then owner = grenade:GetOwner() end
                            if AG_IsValid(owner) then
                                if owner == localPlayer then
                                    isMineOrFriendly = true
                                else
                                    local myTeam, ownerTeam = 0, 0
                                    pcall(function()
                                        if type(localPlayer.GetTeamID) == "function" then myTeam = localPlayer:GetTeamID() or 0 end
                                        if type(owner.GetTeamID) == "function" then ownerTeam = owner:GetTeamID() or 0 end
                                    end)
                                    if myTeam ~= 0 and ownerTeam == myTeam then isMineOrFriendly = true end
                                end
                            end
                        end)
                        if not isMineOrFriendly then
                            local dist = 99999
                            pcall(function()
                                dist = localPlayer:GetDistanceTo(grenade) / AG_State.DistanceDivisor
                            end)
                            if dist < AG_State.MaxDistance then
                                local grenadeLoc = nil
                                pcall(function()
                                    if type(grenade.K2_GetActorLocation) == "function" then
                                        grenadeLoc = grenade:K2_GetActorLocation()
                                    end
                                end)
                                if grenadeLoc then
                                    local nearestEnemy = AG_FindNearestEnemyToGrenade(grenadeLoc, enemies)
                                    if AG_IsValid(nearestEnemy) then
                                        local enemyLoc, enemyFwd = nil, nil
                                        pcall(function()
                                            if type(nearestEnemy.K2_GetActorLocation) == "function" then
                                                enemyLoc = nearestEnemy:K2_GetActorLocation()
                                            end
                                            if type(nearestEnemy.GetActorForwardVector) == "function" then
                                                enemyFwd = nearestEnemy:GetActorForwardVector()
                                            end
                                        end)
                                        if enemyLoc and enemyFwd then
                                            local targetLoc = {
                                                X = (enemyLoc.X or 0) + ((enemyFwd.X or 0) * AG_State.BehindOffset),
                                                Y = (enemyLoc.Y or 0) + ((enemyFwd.Y or 0) * AG_State.BehindOffset),
                                                Z = (enemyLoc.Z or 0) + ((enemyFwd.Z or 0) * AG_State.BehindOffset)
                                            }
                                            pcall(function()
                                                grenade:K2_SetActorLocation(targetLoc, false, nil, true)
                                            end)
                                            AG_State.ProcessedGrenades[grenade] = true
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    local function AG_StartLoop()
        pcall(function()
            local ticker = require("common.time_ticker")
            if not ticker or not ticker.AddTimerLoop then
                local timer = require("timer")
                if timer and timer.SetGameTimer then
                    timer.SetGameTimer(1.0, false, AG_StartLoop)
                end
                return
            end
            ticker.AddTimerLoop(0, function()
                pcall(AG_Tick)
            end, -1, 0.05)
        end)
    end

    pcall(AG_StartLoop)
    pcall(function()
        local ticker = require("common.time_ticker")
        if ticker and ticker.AddTimerOnce then
            ticker.AddTimerOnce(3.0, AG_StartLoop)
        end
    end)
end

-- ============================================================================
-- [SNAPLINE ESP v2]
-- ============================================================================
local SecurityCommonUtils = require("GameLua.Mod.BaseMod.Common.Security.SecurityCommonUtils")
local FVector2D = _G.FVector2D or import("Vector2D")
local FLinearColor = _G.FLinearColor or import("LinearColor")
local FVector = import("Vector")

local IsValid2 = function(obj) 
    return obj ~= nil and slua ~= nil and slua.isValid ~= nil and slua.isValid(obj) 
end

local WL = nil
pcall(function() WL = import("WidgetLayoutLibrary") end)

_G.PlayerMapMarker = {}
local PM = _G.PlayerMapMarker

PM.SnapLineWidgets = {}
PM.bActive = true
PM._EnemyCache = {}
PM._CircleLines = {}

PM.SnapLineThickness = 1.8
PM.SnapLineColor = FLinearColor and FLinearColor(1.0, 1.0, 0.0, 1.0) or {R=1.0, G=1.0, B=0.0, A=1.0}

PM.FOVCircleRadius = 105.0
PM.FOVCircleSegments = 48
PM.FOVCircleThickness = 2.0
PM.FOVCircleColor = FLinearColor and FLinearColor(0.0, 0.0, 0.0, 1.0) or {R=0.0, G=0.0, B=0.0, A=1.0}

function PM.CreateLineWidget(color)
    local Border = nil
    pcall(function()
        Border = CGame:NewObjectFromPath("/Script/UMG.Border", nil)
    end)
    if not Border or not slua.isValid(Border) then return nil end
    
    pcall(function() Border:SetBrushColor(color or PM.SnapLineColor) end)
    pcall(function() Border:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
    pcall(function() Border:SetRenderTransformPivot(FVector2D(0.0, 0.5)) end)
    pcall(function() Border:AddToViewport(14600) end)
    
    return Border
end

function PM.GetGameplayData()
    if PM._CachedGD then return PM._CachedGD end
    local ok, GDP = pcall(function() return require("GameLua.GameCore.Data.GameplayData") end)
    if ok and GDP then PM._CachedGD = GDP; return GDP end
    return nil
end

function PM.GetMyPlayerController()
    if PM._CachedPC and IsValid2(PM._CachedPC) then return PM._CachedPC end
    local PC = nil
    local GDP = PM.GetGameplayData()
    if GDP then pcall(function() PC = GDP.GetPlayerController and GDP.GetPlayerController() end) end
    if not (PC and IsValid2(PC)) then
        pcall(function() if slua_GameFrontendHUD then PC = slua_GameFrontendHUD:GetPlayerController() end end)
    end
    if PC and IsValid2(PC) then PM._CachedPC = PC end
    return PC
end

function PM.GetAllCharacters()
    local AllChars = {}
    pcall(function()
        local Pawns = Game:GetAllPlayerPawns()
        if Pawns then
            for _, Pawn in pairs(Pawns) do
                if Pawn and slua.isValid(Pawn) then
                    local pKey = nil
                    if Pawn.GetPlayerKey then pKey = Pawn:GetPlayerKey() end
                    if not pKey and Pawn.PlayerKey then pKey = Pawn.PlayerKey end
                    if not pKey and Pawn.PlayerState and Pawn.PlayerState.PlayerKey then pKey = Pawn.PlayerState.PlayerKey end
                    if pKey then AllChars[pKey] = Pawn end
                end
            end
        end
    end)
    return AllChars
end

function PM.GetMyPlayerKey()
    local PC = PM.GetMyPlayerController()
    if not IsValid2(PC) then return nil end
    local key = nil
    pcall(function()
        if PC.GetPlayerKey then key = PC:GetPlayerKey()
        elseif PC.PlayerState and PC.PlayerState.PlayerKey then key = PC.PlayerState.PlayerKey end
    end)
    return key
end

function PM.IsMe(Character, PlayerKey, MyKey)
    local bIsMe = false
    pcall(function()
        local GDP = PM.GetGameplayData()
        if GDP and GDP.GetLocalCharacter then
            local MyChar = GDP.GetLocalCharacter()
            if MyChar and Character == MyChar then bIsMe = true; return end
        end
    end)
    if not bIsMe and MyKey ~= nil and PlayerKey ~= nil then
        bIsMe = (tostring(PlayerKey) == tostring(MyKey))
    end
    return bIsMe
end

function PM.IsAlive(Character)
    local bAlive = true
    pcall(function()
        if Character.HealthStatus then bAlive = SecurityCommonUtils.IsHealthStatusAlive(Character.HealthStatus)
        elseif Character.IsAlive then bAlive = Character:IsAlive()
        elseif Character.Health ~= nil then bAlive = Character.Health > 0 end
    end)
    return bAlive
end

function PM.GetTeamID(Character)
    if not IsValid2(Character) then return nil end
    local TeamID = nil
    pcall(function() if Character.GetTeamID then TeamID = Character:GetTeamID() end end)
    if not TeamID then pcall(function() if Character.TeamID then TeamID = Character.TeamID end end) end
    return TeamID
end

function PM.GetHeadLocation(Character)
    if not IsValid2(Character) then return nil end
    local Loc = nil
    pcall(function()
        if Character.K2_GetActorLocation then Loc = Character:K2_GetActorLocation() end
    end)
    if Loc then
        pcall(function()
            if Character.Mesh and slua.isValid(Character.Mesh) then
                if Character.Mesh.DoesSocketExist then
                    if Character.Mesh:DoesSocketExist("head") then
                        local headLoc = Character.Mesh:GetSocketLocation("head")
                        if headLoc then Loc.Z = headLoc.Z + 10 return end
                    elseif Character.Mesh:DoesSocketExist("Head") then
                        local headLoc = Character.Mesh:GetSocketLocation("Head")
                        if headLoc then Loc.Z = headLoc.Z + 10 return end
                    end
                end
            end
            Loc.Z = Loc.Z + 85
        end)
    end
    return Loc
end

function PM.GetViewportSize(PC)
    local w, h = 1920, 1080
    local scale = 1.0
    pcall(function()
        if PC and PC.GetViewportSize then
            local vs = FVector2D(0, 0)
            PC:GetViewportSize(vs)
            if vs and vs.X and vs.X > 200 then w, h = vs.X, vs.Y end
        end
    end)
    if w <= 200 then
        pcall(function()
            if WL and WL.GetViewportSize then
                local vs = WL.GetViewportSize(PC)
                if vs and vs.X and vs.X > 200 then w, h = vs.X, vs.Y end
            end
        end)
    end
    pcall(function()
        if WL and WL.GetViewportScale then
            local s = WL.GetViewportScale(PC)
            if s and type(s) == "number" and s > 0 then scale = s end
        end
    end)
    return w / scale, h / scale
end

function PM.UpdateSnapLine(KeyStr, screenX, screenY, fromX, fromY)
    local lineWidget = PM.SnapLineWidgets[KeyStr]
    if not lineWidget then
        lineWidget = PM.CreateLineWidget(PM.SnapLineColor)
        if not lineWidget then return end
        PM.SnapLineWidgets[KeyStr] = lineWidget
    end
    local dx = screenX - fromX
    local dy = screenY - fromY
    local len = math.sqrt(dx * dx + dy * dy)
    local thickness = PM.SnapLineThickness
    local angle = math.deg(math.atan(dy, dx))
    pcall(function()
        lineWidget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        lineWidget:SetPositionInViewport(FVector2D(fromX, fromY - thickness / 2.0), false)
        lineWidget:SetDesiredSizeInViewport(FVector2D(len, thickness))
        lineWidget:SetRenderAngle(angle)
    end)
end

function PM.HideSnapLine(KeyStr)
    local w = PM.SnapLineWidgets[KeyStr]
    if w and slua.isValid(w) then
        pcall(function() w:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
    end
end

function PM.RemoveSnapLine(KeyStr)
    local w = PM.SnapLineWidgets[KeyStr]
    if w and slua.isValid(w) then
        pcall(function()
            w:RemoveFromViewport()
            w:ConditionalBeginDestroy()
        end)
    end
    PM.SnapLineWidgets[KeyStr] = nil
end

function PM.UpdateCircle(PC)
    local w, h = PM.GetViewportSize(PC)
    local cx, cy = w / 2.0, h / 2.0
    local radius = PM.FOVCircleRadius
    local segments = PM.FOVCircleSegments
    local thickness = PM.FOVCircleThickness
    
    if not PM._CircleLines then PM._CircleLines = {} end
    
    for i = 1, segments do
        local a1 = ((i - 1) / segments) * (2 * math.pi)
        local a2 = (i / segments) * (2 * math.pi)
        local x1 = cx + math.cos(a1) * radius
        local y1 = cy + math.sin(a1) * radius
        local x2 = cx + math.cos(a2) * radius
        local y2 = cy + math.sin(a2) * radius
        local dx = x2 - x1
        local dy = y2 - y1
        local len = math.sqrt(dx * dx + dy * dy)
        local angle = math.deg(math.atan(dy, dx))
        
        local lineWidget = PM._CircleLines[i]
        if not lineWidget or not slua.isValid(lineWidget) then
            lineWidget = PM.CreateLineWidget(PM.FOVCircleColor)
            if lineWidget then
                PM._CircleLines[i] = lineWidget
            end
        end
        
        if lineWidget and slua.isValid(lineWidget) then
            pcall(function()
                lineWidget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                lineWidget:SetPositionInViewport(FVector2D(x1, y1 - thickness / 2.0), false)
                lineWidget:SetDesiredSizeInViewport(FVector2D(len + 0.5, thickness))
                lineWidget:SetRenderAngle(angle)
            end)
        end
    end
end

function PM.ScanEnemies()
    if not PM.bActive then return end
    local PC = PM.GetMyPlayerController()
    if not IsValid2(PC) then return end
    local AllChars = PM.GetAllCharacters()
    if not AllChars then return end
    local MyKey = PM.GetMyPlayerKey()
    local MyChar = nil
    pcall(function()
        local GDP = PM.GetGameplayData()
        if GDP and GDP.GetLocalCharacter then MyChar = GDP.GetLocalCharacter() end
    end)
    local MyTeamID = PM.GetTeamID(MyChar)
    
    local seen = {}
    for PlayerKey, Character in pairs(AllChars) do
        if IsValid2(Character) then
            local bIsMe = PM.IsMe(Character, PlayerKey, MyKey)
            local KeyStr = tostring(PlayerKey)
            local bAlive = PM.IsAlive(Character)
            local TeamID = PM.GetTeamID(Character)
            
            local bSkip = bIsMe
            if MyTeamID ~= nil and TeamID == MyTeamID and not bIsMe then bSkip = true end
            if not bAlive then bSkip = true end
            
            if not bSkip then
                seen[KeyStr] = true
                PM._EnemyCache[KeyStr] = Character
            end
        end
    end
    
    for KeyStr in pairs(PM._EnemyCache) do
        if not seen[KeyStr] then
            PM._EnemyCache[KeyStr] = nil
            PM.RemoveSnapLine(KeyStr)
        end
    end
end

function PM.Update()
    if not PM.bActive then return end
    local PC = PM.GetMyPlayerController()
    if not IsValid2(PC) then return end
    local w, h = PM.GetViewportSize(PC)
    local fromX = w / 2.0
    local fromY = h / 2.0
    
    PM.UpdateCircle(PC)
    
    for KeyStr, Character in pairs(PM._EnemyCache) do
        if IsValid2(Character) and PM.IsAlive(Character) then
            local Loc = PM.GetHeadLocation(Character)
            if Loc then
                local screenPos = FVector2D(0, 0)
                local bOK = false
                pcall(function()
                    local res = PC:ProjectWorldLocationToScreen(Loc, screenPos, true)
                    if res and screenPos and screenPos.X > 0 and screenPos.Y > 0 then
                        bOK = true
                    end
                end)
                if bOK then
                    PM.UpdateSnapLine(KeyStr, screenPos.X, screenPos.Y, fromX, fromY)
                else
                    PM.HideSnapLine(KeyStr)
                end
            else
                PM.HideSnapLine(KeyStr)
            end
        else
            PM.RemoveSnapLine(KeyStr)
            PM._EnemyCache[KeyStr] = nil
        end
    end
end

function PM.Start()
    if PM._Started then return end
    PM._Started = true
    PM.bActive = true
    pcall(function()
        local pc = PM.GetMyPlayerController()
        if pc and pc.AddGameTimer then
            pc:AddGameTimer(0.3, true, function()
                if PM.bActive then pcall(PM.ScanEnemies) end
            end)
            pc:AddGameTimer(0.008, true, function()
                if PM.bActive then pcall(PM.Update) end
            end)
        else
            PM._Started = false
            pcall(function()
                require("timer").SetGameTimer(1.0, false, PM.Start)
            end)
        end
    end)
end

pcall(function()
    local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
    if IsValid2(pc) then
        PM.Start()
    else
        pcall(function()
            require("timer").SetGameTimer(1.0, false, function()
                local pc2 = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
                if IsValid2(pc2) then
                    PM.Start()
                else
                    pcall(function()
                        require("timer").SetGameTimer(2.0, false, PM.Start)
                    end)
                end
            end)
        end)
    end
end)
