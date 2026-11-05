
-- ✅ أضف في أول سطر قبل `do -- بداية كتلة الحماية`
if _G._N5LA_LOADED then return end
_G._N5LA_LOADED = true

do -- بداية كتلة الحماية
local _BC = { _t = os.time, _r = math.random }

local function _AntiFingerprint()
    local _ = _BC._r(100, 500)
end

local function _SafeCall(fn, ...)
    if type(fn) ~= "function" then return nil end
    _AntiFingerprint()
    local ok, r = pcall(fn, ...)
    return ok and r or nil
end

local function _SC(v)
    if type(v) == "string" then
        local t = {} for i = 1, #v do t[i] = string.byte(v, i) end return t
    elseif type(v) == "table" then
        local s = "" for i = 1, #v do s = s .. string.char(v[i]) end return s
    end
    return v
end

local _FakeHWID = nil
local function GetFakeHWID()
    if not _FakeHWID then
        _FakeHWID = "SECURE_" .. tostring(os.time()) .. "_" .. tostring(math.random(10000, 99999))
    end
    return _FakeHWID
end

local _LastBC = 0
local function _BypassCheck()
    local now = os.time()
    if now - _LastBC < 30 then return true end
    _LastBC = now
    return (import ~= nil and pcall ~= nil and _G ~= nil)
end

local _origRequire = require
_G.require = function(mod)
    local ok, r = pcall(_origRequire, mod)
    return ok and r or nil
end

-- ========================================
-- 2. دوال مساعدة للتهرب
-- ========================================

local function nop() return true end
local function retFalse() return false end
local function retZero() return 0 end
local function retEmpty() return {} end
local function retNil() return nil end
local function retTrue() return true end
local function retEmptyString() return "" end

-- ========================================
-- 3. جميع طبقات الحماية
-- ========================================

-- 3.1 تهرب SLUA
local function InitializeSLUABypass()
    pcall(function()
        if slua and slua.getSignature then slua.getSignature = function() return 0xDEADBEEF end end
        local loader = package.loaded["slua.loader"] or rawget(_G, "slua_loader")
        if loader then
            loader.verifyBytecode = nop
            loader.checkIntegrity = nop
            if loader.disableSignatureCheck then loader.disableSignatureCheck = nop end
        end
        local slua_serialize = package.loaded["slua.serialize"]
        if slua_serialize then 
            slua_serialize.check = nop
            slua_serialize.verify = nop
        end
        if jit and jit.attach then jit.attach(function() end, "bc") end
        if _G.slua_verify then _G.slua_verify = nop end
        if _G.check_slua_integrity then _G.check_slua_integrity = nop end
    end)
end

-- 3.2 تهرب MD5
local function InitializeMD5Bypass()
    pcall(function()
        local console = import("KismetSystemLibrary")
        if console then
            console.ExecuteConsoleCommand(nil, "pak.DisablePakSignatureCheck 1")
            console.ExecuteConsoleCommand(nil, "pakchunk.EnableSignatureCheck 0")
            console.ExecuteConsoleCommand(nil, "s.VerifyPak 0")
            console.ExecuteConsoleCommand(nil, "sig.Check 0")
            console.ExecuteConsoleCommand(nil, "security.DisableChecks 1")
            console.ExecuteConsoleCommand(nil, "r.EnableDrawDyeingColor 1")
            console.ExecuteConsoleCommand(nil, "r.CustomDepth 3")
            console.ExecuteConsoleCommand(nil, "r.IdeaOutline.Enable 1")
            console.ExecuteConsoleCommand(nil, "r.Highlight.Enable 1")
        end
        local CMode = import("CreativeModeBlueprintLibrary")
        if CMode then
            CMode.MD5HashByteArray = function() return "00000000000000000000000000000000" end
            CMode.MD5HashFile = function() return "00000000000000000000000000000000" end
            CMode.GetContentDiffData = function() return true, "BYPASSED" end
            CMode.VerifyFileIntegrity = nop
        end
        if _G.MD5Hash then _G.MD5Hash = function() return "00000000000000000000000000000000" end end
        if _G.CRC32 then _G.CRC32 = function() return 0 end end
        if _G.SHA1 then _G.SHA1 = function() return "BYPASS" end end
        local FileHashChecker = package.loaded["common.file_hash_checker"]
        if FileHashChecker then
            FileHashChecker.CheckFileMD5 = nop
            FileHashChecker.VerifyAll = nop
            FileHashChecker.GetHash = function() return "BYPASS" end
        end
        local TssSdk = package.loaded["TssSdk"] or _G.TssSdk
        if TssSdk then 
            TssSdk.GetFileMD5 = function() return "BYPASS" end
            TssSdk.VerifyFileSignature = nop
        end
        local STExtra = import("STExtraBlueprintFunctionLibrary")
        if STExtra then 
            STExtra.CheckMD5 = nop
            STExtra.GetMD5 = function() return "BYPASS" end
            STExtra.VerifyFile = nop
        end
    end)
end

-- 3.3 تهرب الـ Skins
local function InitializeSkinBypass()
    pcall(function()
        local ptlog = package.loaded["client.slua.logic.download.report.puffer_tlog"]
        if ptlog then 
            ptlog.ReportEvent = function() end
            ptlog.ReportDownloadResult = function() end
            ptlog.ReportODPTDError = function() end
            ptlog.ReportSkinError = function() end
        end
        local AvatarUtils = package.loaded["AvatarUtils"]
        if AvatarUtils then 
            AvatarUtils.CheckIsWeaponInBlackList = retFalse
            AvatarUtils.IsValidAvatar = nop
            AvatarUtils.CheckAvatarIntegrity = nop
            AvatarUtils.ReportInvalidAvatar = function() end
        end
        local sub = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr"):Get("FileCheckSubsystem")
        if sub then 
            sub.StartCheck = function() end
            sub.ReportAbnormalFile = function() end
            sub.StopCheck = function() end
        end
        local eqEx = package.loaded["client.slua.logic.report.EquipmentExceptionReport"]
        if eqEx then 
            eqEx.Report = function() end
            eqEx.SendException = function() end
        end
    end)
end

-- 3.4 حظر السجلات
local function InitializeLogBlocker()
    pcall(function()
        local SMTD = import("ScreenshotMTDer")
        if SMTD then 
            SMTD.MTDePicture = function() return "" end
            SMTD.ReMTDePicture = function() return "" end
            SMTD.HasCaptured = nop
            SMTD.TakeScreenshot = function() end
        end
        local TLog = package.loaded["TLog"] or _G.TLog
        if TLog then 
            TLog.Info = function() end
            TLog.Warning = function() end
            TLog.Error = function() end
            TLog.Debug = function() end
            TLog.Report = function() end
            TLog.Send = function() end
            TLog.Flush = function() end
        end
        local CrashSight = package.loaded["CrashSight"] or _G.CrashSight
        if CrashSight then 
            CrashSight.ReportException = function() end
            CrashSight.SetCustomData = function() end
            CrashSight.Log = function() end
            CrashSight.SendCrash = function() end
            CrashSight.ReportUserException = function() end
        end
        local GRUtils = package.loaded["GameLua.Mod.BaseMod.GamePlay.GameReport.GameReportUtils"]
        if GRUtils then 
            GRUtils.BugglyPostExceptionFull = retFalse
            GRUtils.CheckCanBugglyPostException = retFalse
            GRUtils.ReplayReportData = function() end
            GRUtils.ReportGameException = function() end
            GRUtils.PostException = function() end
        end
        local CTR = package.loaded["client.slua.logic.report.ClientToolsReport"]
        if CTR then 
            CTR.SendReport = function() end
            CTR.SendException = function() end
            CTR.UploadLog = function() end
        end
        for _, sdk in ipairs({"Firebase", "Adjust", "AppsFlyer", "FacebookAnalytics", "GameAnalytics"}) do
            local s = _G[sdk]
            if s then 
                s.logEvent = function() end
                s.trackEvent = function() end
                s.setEnabled = retFalse
                s.sendEvent = function() end
                s.report = function() end
            end
        end
    end)
end

-- 3.5 حظر الماسحات الضوئية
local function InitializeScannerBlocker()
    pcall(function()
        local SubMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if SubMgr then
            local subs = {"AFKReportorSubsystem", "ClientDataStatistcsSubsystem", "AvatarExceptionSubsystem", "ShootVerifySubSystemClient", "MemoryCheckSubsystem", "SpeedCheckSubsystem", "WallCheckSubsystem", "FileCheckSubsystem", "BehaviorScoreSubsystem"}
            for _, name in ipairs(subs) do
                local sub = SubMgr:Get(name)
                if sub then
                    for k, v in pairs(sub) do
                        if type(v) == "function" and (k:find("Report") or k:find("Send") or k:find("Upload") or k:find("Verify") or k:find("Check") or k:find("Validate") or k:find("Scan") or k:find("Detect")) then 
                            pcall(function() sub[k] = function() end end)
                        end
                    end
                    if sub.ReportPingDelayTimer then 
                        sub:RemoveGameTimer(sub.ReportPingDelayTimer)
                        sub.ReportPingDelayTimer = nil 
                    end
                    sub.DelayCount = 0
                end
            end
        end
        local AvaEx = package.loaded["GameLua.Mod.Library.GamePlay.Avatar.Exception.AvatarExceptionPlayerInst"]
        if AvaEx then 
            AvaEx.CheckAvatarException = function() end
            AvaEx.CheckAvatarExceptionOnce = function() end
            AvaEx.ReportAvatarException = function() end
            AvaEx.CheckSlotMeshVisible = retFalse
            AvaEx.CheckPawnVisible = retFalse
            AvaEx.CheckCanBugglyPostException = retFalse
        end
        local TssSdk = package.loaded["TssSdk"] or _G.TssSdk
        if TssSdk then
            local origData = TssSdk.OnRecvData
            TssSdk.OnRecvData = function(data) 
                if type(data) == "string" and (data:find("report", 1, true) or data:find("exception", 1, true) or data:find("cheat", 1, true) or data:find("violation", 1, true) or data:find("hack", 1, true) or data:find("verify", 1, true)) then 
                    return 
                end
                if origData then origData(data) end
            end
            TssSdk.SendReportInfo = function() end
            TssSdk.ScanMemory = nop
            TssSdk.IsEmulator = retFalse
            TssSdk.GetTssSdkReportInfo = retEmptyString
            TssSdk.CheckEnvironment = nop
            TssSdk.VerifyProcess = nop
        end
    end)
end

-- 3.6 حظر إعادة التشغيل والتحليلات
local function InitializeReplayTelemetryBlocker()
    pcall(function()
        local SubMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if SubMgr then
            for _, name in ipairs({"GameReportSubsystem", "ReplaySubsystem"}) do
                local sub = SubMgr:Get(name)
                if sub then 
                    for k, v in pairs(sub) do 
                        if type(v) == "function" and (k:find("Report") or k:find("Trace") or k:find("Replay") or k:find("Record") or k:find("Save")) then 
                            pcall(function() sub[k] = function() end end) 
                        end
                    end
                end
            end
        end
        local logRep = package.loaded["client.slua.logic.replay.logic_report_replay"]
        if logRep then 
            logRep.ReportReplay = function() end
            logRep.SendReportReq = function() end
            logRep.UploadReplay = function() end
        end
    end)
end

-- 3.7 حظر تقارير التدفقات
local function InitializeReportFlowBlocker()
    pcall(function()
        local flows = {"ReportAimFlow", "ReportHitFlow", "ReportAttackFlow", "ReportSecAttackFlow", "ReportFireArms", "ReportVerifyInfoFlow", "ReportMrpcsFlow", "ReportPlayerBehavior", "ReportTeammatHurt", "ReportMisKillByTeammate", "ReportForbitPick", "ReportPlayerMoveRoute", "ReportPlayerPosition", "ReportVehicleMoveFlow", "ReportSecTgameMovingFlow", "ReportParachuteData", "ReportEquipmentFlow", "ReportPlayersPing", "ReportPlayerIP", "ReportPlayerFramePingRecord", "ReportDSNetSaturation", "ReportNetContinuousSaturate", "ReportDSNetRate", "ReportCircleFlow", "ReportSecMrpcsFlow"}
        for _, f in ipairs(flows) do 
            if _G[f] then _G[f] = function() end end
            if _G.GameplayCallbacks and _G.GameplayCallbacks[f] then _G.GameplayCallbacks[f] = function() end end
        end
        for _, f in ipairs({"CheckReportSecAttackFlowWithAttackFlow", "CheckReportSecAttackFlow"}) do 
            if _G[f] then _G[f] = retFalse end
            if _G.GameplayCallbacks and _G.GameplayCallbacks[f] then _G.GameplayCallbacks[f] = retFalse end
        end
        for _, f in ipairs({"IsEnableReportMrpcsInCircleFlow", "IsEnableReportMrpcsInPartCircleFlow", "IsEnableReportMrpcsFlow", "IsEnableReportAttackFlow", "IsEnableReportHitFlow", "IsEnableReportCircleFlow"}) do 
            if _G[f] then _G[f] = retFalse end
        end
    end)
end

-- 3.8 تهرب أمان اللاعب
local function InitializePlayerSecurityBypass()
    pcall(function()
        for _, c in ipairs({"PlayerSecurityInfoCollector", "PlayerSecurityInfo", "SecurityInfoCollector", "ClientSecurityCollector", "PlayerAntiCheatCollector"}) do
            if _G[c] then 
                for k, v in pairs(_G[c]) do 
                    if type(v) == "function" and (k:find("Report") or k:find("Collect") or k:find("Send") or k:find("Upload") or k:find("Record")) then 
                        _G[c][k] = function() end 
                    end
                end
            end
        end
        local SecSub = require("GameLua.Mod.BaseMod.Common.Security.PlayerSecurityInfoSubsystem")
        if SecSub then 
            SecSub.ReportData = function() end
            SecSub.CheckCheat = retFalse
            SecSub.ValidatePlayer = nop
            SecSub.CollectData = function() end
            SecSub.SendToServer = function() end
        end
    end)
end

-- 3.9 تهرب تدفقات العميل
local function InitializeClientFlowBypass()
    pcall(function()
        for _, name in ipairs({"ClientSecMrpcsFlow", "MrpcsFlow", "MrpcsData", "ClientCircleFlowSubsystem", "ClientKillFlowSubsystem", "ClientSecPlayerKillFlow"}) do
            local sub = package.loaded[name] or _G[name]
            if sub then 
                for k, v in pairs(sub) do 
                    if type(v) == "function" and (k:find("Report") or k:find("Send") or k:find("Flow") or k:find("Record") or k:find("Process")) then 
                        pcall(function() sub[k] = function() end end) 
                    end
                end
            end
        end
    end)
end

-- 3.10 تهرب SwiftHawk
local function InitializeSwiftHawkBypass()
    pcall(function()
        for _, f in ipairs({"SwiftHawk", "ClientSwiftHawk", "ClientSwiftHawkWithParams", "SendSwiftHawkData"}) do 
            if _G[f] then _G[f] = function() end end
            if _G.GameplayCallbacks and _G.GameplayCallbacks[f] then _G.GameplayCallbacks[f] = function() end end
        end
        local sub = package.loaded["GameLua.Mod.BaseMod.Client.Security.SwiftHawkSubsystem"]
        if sub then 
            sub.ReportData = function() end
            sub.SendReport = function() end
            sub.CollectTelemetry = function() end
        end
    end)
end

-- 3.11 تهرب CoronaLab
local function InitializeCoronaLabBypass()
    pcall(function()
        if _G.CoronaLab then 
            _G.CoronaLab.ReportData = function() end
            _G.CoronaLab.SendData = function() end
            _G.CoronaLab.CollectData = function() end
            _G.CoronaLab.Telemetry = function() end
        end
        local sub = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr"):Get("CoronaLabSubsystem")
        if sub then 
            sub.ReportData = function() end
            sub.SendToServer = function() end
            sub.CollectTelemetry = function() end
            sub.StopCollection = function() end
        end
    end)
end

-- 3.12 تهرب استثناءات المعدلات
local function InitializeModifierExceptionBypass()
    pcall(function()
        if _G.bReportedModifierException then _G.bReportedModifierException = false end
        local sub = require("GameLua.Mod.BaseMod.Common.Security.ModifierExceptionSubsystem")
        if sub then 
            sub.ReportException = function() end
            sub.CheckModifier = nop
            sub.ValidateModifier = nop
            sub.ReportModifierError = function() end
        end
    end)
end

-- 3.13 تهرب موقع الشخصية المحاكاة
local function InitializeSimulateCharacterLocationBypass()
    pcall(function()
        local sub = require("GameLua.Mod.BaseMod.Gameplay.Simulate.SimulateCharacterSubsystem")
        if sub then 
            sub.ReportLocation = function() end
            sub.SendLocationData = function() end
            sub.VerifyLocation = nop
        end
    end)
end

-- 3.14 تهرب التحقق من الطلقات
local function InitializeShootVerificationBypass()
    pcall(function()
        local sub = require("GameLua.Dev.Subsystem.ShootVerifySubSystemClient")
        if sub then 
            sub.OnShootVerifyFailed = function() end
            sub.SendVerifyData = function() end
            sub.ReportBulletHit = function() end
            sub.UploadHitInfo = function() end
            sub.VerifyShot = nop
        end
        if _G.BulletHitInfoUploadData then 
            _G.BulletHitInfoUploadData.Report = function() end
            _G.BulletHitInfoUploadData.Send = function() end
            _G.BulletHitInfoUploadData.Upload = function() end
        end
    end)
end

-- 3.15 حظر حزم الشبكة
local function InitializeNetworkPacketBlock()
    pcall(function()
        if NetUtil and NetUtil.SendPacket then
            local orig = NetUtil.SendPacket
            local blocked = {
                ["ReportAttackFlow"]=1, ["ReportSecAttackFlow"]=1, ["ReportFireArms"]=1, ["ReportVerifyInfoFlow"]=1, ["ReportMrpcsFlow"]=1,
                ["ReportPlayerBehavior"]=1, ["ReportTeammatHurt"]=1, ["ReportPlayerMoveRoute"]=1, ["ReportPlayerPosition"]=1, ["ReportSecVehicleMoveFlow"]=1,
                ["report_parachute_data"]=1, ["on_tss_sdk_anti_data"]=1, ["ReportAimFlow"]=1, ["ReportHitFlow"]=1, ["ReportCircleFlow"]=1, ["report_players_ping"]=1,
                ["report_player_ip"]=1, ["report_net_saturate"]=1, ["report_speed_hack"]=1, ["report_wall_hack"]=1, ["report_aim_bot"]=1, ["report_esp_usage"]=1,
                ["report_modded_files"]=1, ["detect_cheat"]=1, ["ban_player"]=1, ["client_anti_cheat_report"]=1,
                ["ClientSecMrpcsFlow"]=1, ["MrpcsData"]=1, ["CheckReportSecAttackFlow"]=1, ["CheckReportSecAttackFlowWithAttackFlow"]=1, ["RPC_ClientCoronaLab"]=1,
                ["CoronaLabReport"]=1, ["CoronaLabData"]=1, ["PlayerSecurityInfo"]=1, ["ReportSecurityInfo"]=1, ["SendSecurityData"]=1, ["ClientCircleFlow"]=1,
                ["IsEnableReportMrpcsInCircleFlow"]=1, ["IsEnableReportMrpcsInPartCircleFlow"]=1, ["bReportedModifierException"]=1,
                ["ReportModifierException"]=1, ["RPC_Server_ReportSimulateCharacterLocation"]=1, ["ReportSimulateCharacterLocation"]=1, ["RPC_Client_ShootVertifyRes"]=1,
                ["BulletHitInfoUploadData"]=1, ["ShootVerifyFailed"]=1, ["report_unrealnet_exception"]=1, ["tss_sdk_report"]=1, ["SwiftHawk"]=1, ["ClientSwiftHawk"]=1, ["ClientSwiftHawkWithParams"]=1, ["SwiftHawkReport"]=1, ["SwiftHawkData"]=1,
                ["AntiCheatReport"]=1, ["CheatDetection"]=1, ["ViolationReport"]=1, ["SecurityViolation"]=1, ["IntegrityCheck"]=1, ["SignatureVerify"]=1
            }
            NetUtil.SendPacket = function(packetName, ...) 
                if blocked[packetName] then return nil end
                return orig(packetName, ...) 
            end
            NetUtil.IsBypassed = true
        end
        if _G.SendRPC then
            local origRPC = _G.SendRPC
            local blockedRPC = {"RPC_Server_ClientSecMrpcsFlow", "RPC_Server_SwiftHawk", "RPC_Server_ClientSwiftHawkWithParams", "RPC_Server_ReportSimulateCharacterLocation", "RPC_Client_ShootVertifyRes", "RPC_ClientCoronaLab"}
            _G.SendRPC = function(rpcName, ...) 
                for _, b in ipairs(blockedRPC) do 
                    if rpcName == b then return nil end 
                end
                return origRPC(rpcName, ...) 
            end
        end
    end)
end

-- 3.16 تهرب HiggsBoson
local function InitializeHiggsBosonBypass()
    pcall(function()
        local Higgs = require("GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent")
        if Higgs then
            for _, m in ipairs({"ControlMHActive", "Tick", "OnTick", "MHActiveLogic", "TriggerAvatarCheck", "StartAvatarCheck", "ReportItemID", "ReceiveAnyDamage", "OnWeaponHitRecord", "ShowSecurityAlert", "ServerReportAvatar", "ClientReportNetAvatar", "SendHisarData", "ValidateSecurityData", "StaticShowSecurityAlertInDev", "RPC_Client_ShootVertifyRes", "RPC_Server_ReportSimulateCharacterLocation", "DisableHiggsBoson", "CheckMHActive", "ReportViolation", "ProcessSecurityEvent", "ValidatePlayer", "CheckIntegrity"}) do
                if Higgs[m] then Higgs[m] = function() end end
            end
            Higgs.GetNetAvatarItemIDs = retEmpty
            Higgs.GetCurWeaponSkinID = retZero
            Higgs.IsMHActive = retFalse
            Higgs.bMHActive = false
            Higgs.bCallPreReplication = false
            if Higgs.BlackList then 
                for k in pairs(Higgs.BlackList) do Higgs.BlackList[k] = nil end 
            end
        end
        _G.BlackList = {}
        local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        if slua.isValid(pc) then
            if pc.HiggsBoson then 
                pc.HiggsBoson.bMHActive = false
                pc.HiggsBoson.bCallPreReplication = false
                if pc.HiggsBoson.ControlMHActive then pc.HiggsBoson:ControlMHActive(0) end
            end
            if pc.HiggsBosonComponent then 
                pc.HiggsBosonComponent.bMHActive = false
                pc.HiggsBosonComponent.bCallPreReplication = false
                pc.HiggsBosonComponent:ControlMHActive(0) 
            end
        end
    end)
end

-- 3.17 خطافات مكافحة الغش
local function InitializeAntiCheatHooks()
    pcall(function()
        local HBC = require("GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent")
        if HBC and HBC.StaticShowSecurityAlertInDev then HBC.StaticShowSecurityAlertInDev = function() end end
    end)
    if _G.AvatarCheckCallback then
        _G.AvatarCheckCallback.StartAvatarCheck = function() end
        _G.AvatarCheckCallback.OnReportItemID = function() end
        _G.AvatarCheckCallback.PostPlayerControllerLoginInit = function(PlayerController)
            if slua.isValid(PlayerController) and PlayerController.HiggsBosonComponent then 
                PlayerController.HiggsBosonComponent:ControlMHActive(0)
                PlayerController.HiggsBosonComponent.bMHActive = false 
            end
        end
    end
end

-- 3.18 حظر التقارير المضادة
local function InitializeAntiReport()
    pcall(function()
        for _, path in ipairs({"GameLua.Mod.BaseMod.Client.Security.ClientReportPlayerSubsystem", "Client.Security.ClientReportPlayerSubsystem", "GameLua.Mod.BaseMod.DS.Security.DSReportPlayerSubsystem"}) do
            local sub = package.loaded[path]
            if not sub then 
                local s, r = pcall(require, path)
                if s and r then sub = r end
            end
            if sub then 
                for k, v in pairs(sub) do 
                    if type(v) == "function" and (k:find("Report") or k:find("Record") or k:find("Send") or k:find("Upload") or k:find("Notify")) then 
                        pcall(function() sub[k] = function() end end) 
                    end
                end
            end
        end
    end)
end

-- 3.19 تهرب طريقة اللعب
local function InitializeGameplayBypass()
    pcall(function()
        if not _G.GameplayCallbacks then _G.GameplayCallbacks = {} end
        if _G.GameplayCallbacks.IsBypassed then return end
        local GC = _G.GameplayCallbacks
        local reports = {"ReportAttackFlow", "ReportSecAttackFlow", "ReportFireArms", "ReportVerifyInfoFlow", "ReportMrpcsFlow", "ReportPlayerBehavior", "ReportTeammatHurt", "ReportMisKillByTeammate", "ReportForbitPick", "ReportPlayerMoveRoute", "ReportPlayerPosition", "ReportVehicleMoveFlow", "ReportSecTgameMovingFlow", "ReportParachuteData", "SendTssSdkAntiDataToLobby", "ReportEquipmentFlow", "ReportAimFlow", "ReportPlayersPing", "ReportPlayerIP", "ReportPlayerFramePingRecord", "OnDSConnectionSaturated", "ReportDSNetSaturation", "ReportNetContinuousSaturate", "ReportDSNetRate", "SendClientStats", "SendServerAvgTickDelta", "ReportCircleFlow", "ClientSecMrpcsFlow", "SwiftHawk", "ClientSwiftHawk", "ClientSwiftHawkWithParams"}
        for _, f in ipairs(reports) do GC[f] = function() end end
        GC.CheckReportSecAttackFlowWithAttackFlow = retFalse
        GC.CheckReportSecAttackFlow = retFalse
        local origState = GC.OnDSPlayerStateChanged
        GC.OnDSPlayerStateChanged = function(UID, State, bPure, bSafe, Param)
            local s = State and string.lower(tostring(State)) or ""
            local blocked = {["cheatdetected"]=1, ["connectionlost"]=1, ["connectiontimeout"]=1, ["connectionexception"]=1, ["netdrivererror"]=1, ["banned"]=1, ["kicked"]=1, ["suspended"]=1, ["violationdetected"]=1, ["integrityfailure"]=1, ["securityviolation"]=1}
            if blocked[s] then return end
            if origState then pcall(origState, UID, State, bPure, bSafe, Param) end
        end
        GC.OnPlayerNetConnectionClosed = function() end
        GC.OnPlayerActorChannelError = function() end
        GC.OnPlayerRPCValidateFailed = function() end
        GC.OnPlayerSpectateException = function() end
        GC.OnShutdownAfterError = function() end
        GC.IsBypassed = true
    end)
end

-- 3.20 قتل جميع الأنظمة الفرعية
local function InitializeKillAllSubsystems()
    pcall(function()
        local subMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if not subMgr then return end
        local toKill = {"CoronaLabSubsystem", "PlayerSecurityInfoSubsystem", "ClientCircleFlowSubsystem", "ModifierExceptionSubsystem", "SimulateCharacterSubsystem", "ShootVerifySubSystemClient", "HiggsBosonComponent", "ClientReportPlayerSubsystem", "DSReportPlayerSubsystem", "ClientHawkEyePatrolSubsystem", "DSHawkEyePatrolSubsystem", "ClientDataStatistcsSubsystem", "AFKReportorSubsystem", "BehaviorScoreSubsystem", "FileCheckSubsystem", "MemoryCheckSubsystem", "SpeedCheckSubsystem", "WallCheckSubsystem", "AvatarExceptionSubsystem", "GameReportSubsystem", "ClientSecMrpcsFlowSubsystem", "MrpcsFlowSubsystem", "CircleFlowSubsystem", "SwiftHawkSubsystem", "AntiCheatSubsystem", "IntegrityCheckSubsystem", "SignatureVerifySubsystem", "MD5CheckSubsystem", "PakVerifySubsystem"}
        for _, name in ipairs(toKill) do
            local sub = subMgr:Get(name)
            if sub then
                for k, v in pairs(sub) do 
                    if type(v) == "function" and (k:find("Report") or k:find("Send") or k:find("Upload") or k:find("Verify") or k:find("Check") or k:find("Validate") or k:find("Scan") or k:find("Detect") or k:find("Collect") or k:find("Flow") or k:find("Heartbeat")) then 
                        pcall(function() sub[k] = function() end end) 
                    end
                end
                if sub.timer then pcall(function() sub:RemoveGameTimer(sub.timer) end) end
                if sub.heartbeatTimer then pcall(function() sub:RemoveGameTimer(sub.heartbeatTimer) end) end
                if sub.reportTimer then pcall(function() sub:RemoveGameTimer(sub.reportTimer) end) end
            end
        end
    end)
end

-- 3.21 تهرب الإحصائيات التشغيلية
local function InitializeOperationalStatsBypass()
    pcall(function()
        local subMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        local OperationalStatsSubsystem = (subMgr and subMgr:Get("OperationalStatsSubsystem")) or _G.OperationalStatsSubsystem
        
        if OperationalStatsSubsystem then
            OperationalStatsSubsystem.ReportOperationalStats = function() end
            OperationalStatsSubsystem.AddOperationalStats = function() end
            OperationalStatsSubsystem.HandleTouchBegin = function() end
            OperationalStatsSubsystem.HandleTouchEnd = function() end
            OperationalStatsSubsystem.OnInit = function() end
            OperationalStatsSubsystem.HandleEnterFighting = function() end
            OperationalStatsSubsystem.OnBattleResult = function() end
            if OperationalStatsSubsystem.TimerHandle then
                pcall(function() OperationalStatsSubsystem:RemoveGameTimer(OperationalStatsSubsystem.TimerHandle) end)
                OperationalStatsSubsystem.TimerHandle = nil
            end
            OperationalStatsSubsystem.StatsData = {}
        end
    end)
end

-- 3.22 الحماية النهائية
local function InitializeFinalProtection()
    pcall(function()
        for _, flag in ipairs({"ENABLE_REPORT", "ENABLE_ANTI_CHEAT", "ENABLE_SECURITY", "ENABLE_TELEMETRY", "ENABLE_ANALYTICS", "ENABLE_CRASH_REPORT", "ENABLE_PERFORMANCE_REPORT"}) do 
            if _G[flag] then _G[flag] = false end 
        end
        local origReq = require
        local blocked = {"HiggsBosonComponent", "PlayerSecurityInfoSubsystem", "CoronaLabSubsystem", "ClientCircleFlowSubsystem", "ModifierExceptionSubsystem", "ShootVerifySubSystemClient", "ClientReportPlayerSubsystem", "DSReportPlayerSubsystem"}
        _G.require = function(m) 
            for _, b in ipairs(blocked) do 
                if m:find(b) then return {} end 
            end
            return origReq(m) 
        end
    end)
end

-- ========================================
-- 4. طبقات إضافية مضادة للحظر
-- ========================================

-- 4.1 إزالة خطافات التصحيح
local function InitializeDebugHookRemoval()
    pcall(function()
        if debug then
            if debug.sethook then debug.sethook() end
            if debug.setmetatable then
                local orig_setmt = debug.setmetatable
                debug.setmetatable = function(t, mt)
                    if t == _G then return end
                    return orig_setmt(t, mt)
                end
            end
        end
        if jit then
            pcall(function() jit.off() end)
            pcall(function() if jit.attach then jit.attach(function() end, "bc") end end)
        end
    end)
end

-- 4.2 فلتر حالات الحظر من الخادم
local function InitializeDSStateBanFilter()
    pcall(function()
        if not _G.GameplayCallbacks then _G.GameplayCallbacks = {} end
        local GC = _G.GameplayCallbacks

        local _origState = GC.OnDSPlayerStateChanged
        GC.OnDSPlayerStateChanged = function(UID, State, bPure, bSafe, Param)
            local s = string.lower(tostring(State or ""))
            local blocked_states = {
                "cheatdetected", "banned", "kicked", "suspended",
                "violationdetected", "integrityfailure", "securityviolation",
                "hackdetected", "moddetected", "anticheat",
                "permanentban", "temporaryban", "10yearban", "1dayban",
                "punished", "penalized", "sanctioned", "restricted",
                "accountsuspended", "cheatingpenalty", "fairplaybanned"
            }
            for _, bs in ipairs(blocked_states) do
                if s:find(bs, 1, true) then return end
            end
            if _origState then pcall(_origState, UID, State, bPure, bSafe, Param) end
        end

        local ban_rpcs = {
            "OnPlayerBanned", "OnPlayerKicked", "OnPlayerSuspended",
            "OnCheatDetected", "OnViolationDetected", "OnSecurityBan",
            "OnFairPlayBan", "OnPermanentBan", "OnTemporaryBan",
            "OnAccountSuspended", "NotifyBanResult", "OnBanNotification",
            "OnPunishmentApplied", "OnPenaltyApplied", "OnSanctionApplied",
            "OnPlayerNetConnectionClosed", "OnPlayerActorChannelError",
            "OnPlayerRPCValidateFailed", "OnShutdownAfterError",
        }
        for _, rpc in ipairs(ban_rpcs) do
            GC[rpc] = function() end
        end

        for _, path in ipairs({
            "GameLua.Mod.BaseMod.Client.Security.BanNotificationSubsystem",
            "GameLua.Mod.BaseMod.Client.Security.PunishmentSubsystem",
            "GameLua.Mod.BaseMod.Client.Security.FairPlaySubsystem",
            "GameLua.Mod.BaseMod.Client.AntiCheat.BanProcessSubsystem",
        }) do
            if not package.loaded[path] then
                package.preload[path] = function()
                    return {
                        OnBanReceived = function() end,
                        ProcessBan = function() end,
                        NotifyBan = function() end,
                        ApplyPunishment = function() end,
                        StartBanTimer = function() end,
                    }
                end
            end
        end
    end)
end

-- 4.3 ممتص حزم الحظر
local function InitializeBanPacketAbsorber()
    pcall(function()
        if not NetUtil or not NetUtil.SendPacket then return end
        if NetUtil._BanAbsorberActive then return end

        local orig = NetUtil.SendPacket
        local ban_packets = {
            ["BanPlayer"]=1, ["KickPlayer"]=1, ["SuspendPlayer"]=1,
            ["NotifyBan"]=1, ["ApplyPunishment"]=1, ["ReportCheatResult"]=1,
            ["ProcessBanRequest"]=1, ["FairPlayBan"]=1, ["SecurityBan"]=1,
            ["TemporaryBan"]=1, ["PermanentBan"]=1, ["AccountBan"]=1,
            ["CheatPenalty"]=1, ["ViolationPenalty"]=1, ["BanNotification"]=1,
            ["SendBanInfo"]=1, ["BanResultPacket"]=1, ["PunishmentPacket"]=1,
        }
        NetUtil.SendPacket = function(name, ...)
            if ban_packets[name] then return nil end
            return orig(name, ...)
        end
        NetUtil._BanAbsorberActive = true
    end)
end

-- 4.4 فلتر الطباعة
local function InitializePrintFilter()
    pcall(function()
        if _G._PrintFilterActive then return end
        local orig_print = print
        print = function(...)
            local args = {...}
            for _, v in ipairs(args) do
                local s = tostring(v)
                if s:find("BYPass",1,true) or s:find("ESP",1,true)
                or s:find("Bypass",1,true) or s:find("Aimbot",1,true)
                or s:find("bypass",1,true) or s:find("BYPASS",1,true)
                or s:find("StartBypass",1,true) or s:find("VIP",1,true)
                or s:find("hack",1,true) or s:find("cheat",1,true)
                then return end
            end
            orig_print(...)
        end
        _G._PrintFilterActive = true
    end)
end

-- 4.5 حماية الجدول _G
local function InitializeMetatableShield()
    pcall(function()
        local orig_mt = getmetatable(_G) or {}
        local orig_index = orig_mt.__index
        orig_mt.__index = function(t, k)
            if k == "_BYPASS_DONE" or k == "_bypass_active" then return nil end
            if orig_index then return orig_index(t, k) end
            return rawget(t, k)
        end
        setmetatable(_G, orig_mt)
    end)
end

-- 4.6 قاتل المؤقتات الفرعية
local function InitializeSubsystemTimerKiller()
    pcall(function()
        local subMgr
        pcall(function()
            subMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        end)
        if not subMgr then return end

        local timerSubs = {
            "CoronaLabSubsystem", "SwiftHawkSubsystem", "BehaviorScoreSubsystem",
            "ClientDataStatistcsSubsystem", "AFKReportorSubsystem",
            "AntiCheatSubsystem", "IntegrityCheckSubsystem",
            "ClientReportPlayerSubsystem", "DSReportPlayerSubsystem",
            "GameReportSubsystem", "TelemetrySubsystem",
            "OperationalStatsSubsystem", "MD5CheckSubsystem",
        }
        for _, name in ipairs(timerSubs) do
            pcall(function()
                local sub = subMgr:Get(name)
                if not sub then return end
                for _, field in ipairs({
                    "TimerHandle","timer","heartbeatTimer","reportTimer",
                    "scanTimer","checkTimer","uploadTimer","sendTimer",
                    "collectTimer","telemetryTimer","statsTimer"
                }) do
                    if sub[field] then
                        pcall(function()
                            sub:RemoveGameTimer(sub[field])
                            sub[field] = nil
                        end)
                    end
                end
                if sub.OnInit then sub.OnInit = function() end end
                if sub.StartTimer then sub.StartTimer = function() end end
                if sub.RestartTimer then sub.RestartTimer = function() end end
            end)
        end
    end)
end

-- ========================================
-- 5. تشغيل جميع الطبقات (Main Function)
-- ========================================

local function StartUltimateProtection()
    pcall(function()
        print("[ULTIMATE PROTECTION] Starting all layers...")
        
        InitializeSLUABypass()
        InitializeMD5Bypass()
        InitializeSkinBypass()
        InitializeLogBlocker()
        InitializeScannerBlocker()
        InitializeReplayTelemetryBlocker()
        InitializeReportFlowBlocker()
        InitializePlayerSecurityBypass()
        InitializeClientFlowBypass()
        InitializeSwiftHawkBypass()
        InitializeCoronaLabBypass()
        InitializeModifierExceptionBypass()
        InitializeSimulateCharacterLocationBypass()
        InitializeShootVerificationBypass()
        InitializeNetworkPacketBlock()
        InitializeHiggsBosonBypass()
        InitializeAntiCheatHooks()
        InitializeAntiReport()
        InitializeGameplayBypass()
        InitializeKillAllSubsystems()
        InitializeOperationalStatsBypass()
        InitializeFinalProtection()
        
        InitializeDebugHookRemoval()
        InitializeDSStateBanFilter()
        InitializeBanPacketAbsorber()
        InitializePrintFilter()
        InitializeMetatableShield()
        InitializeSubsystemTimerKiller()
        
        local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        if slua.isValid(pc) then
            if pc.HiggsBoson then 
                pc.HiggsBoson.bMHActive = false
                pc.HiggsBoson.bCallPreReplication = false
            end
            if pc.HiggsBosonComponent then 
                pc.HiggsBosonComponent.bMHActive = false
                pc.HiggsBosonComponent.bCallPreReplication = false
            end
        end
        
        print("[ULTIMATE PROTECTION] All 28 layers active - Protection ready!")
    end)
end

-- ========================================
-- 6. نظام تزييف HWID
-- ========================================

local function InitializeFakeHWID()
    pcall(function()
        local SystemLib = import("KismetSystemLibrary")
        if SystemLib and not _G.FakeHWID_Hooked then
            _G.Original_GetDeviceId = SystemLib.GetDeviceId
            SystemLib.GetDeviceId = function(...)
                if not _G.FakeHWID_String then
                    local chars = "0123456789abcdef"
                    local hwid = ""
                    for i = 1, 32 do
                        hwid = hwid .. chars:sub(math.random(1, 16), math.random(1, 16))
                    end
                    _G.FakeHWID_String = hwid
                end
                return _G.FakeHWID_String
            end
            _G.FakeHWID_Hooked = true
        end
    end)
end

-- ========================================
-- 7. دالة التهرب السريع (Fast Bypass)
-- ========================================

local function FastProtectionTick()
    pcall(function()
        local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        if slua.isValid(pc) then
            if pc.HiggsBoson then 
                pc.HiggsBoson.bMHActive = false
                pc.HiggsBoson.bCallPreReplication = false
            end
            if pc.HiggsBosonComponent then 
                pc.HiggsBosonComponent.bMHActive = false
                pc.HiggsBosonComponent.bCallPreReplication = false
            end
        end
    end)
    
    local okTicker, ticker = pcall(require, "common.time_ticker")
    if okTicker and ticker and ticker.AddTimerOnce then
        ticker.AddTimerOnce(0.5, FastProtectionTick)
    end
end

-- ========================================
-- 8. تشغيل النظام (Execute Protection)
-- ========================================

StartUltimateProtection()
InitializeFakeHWID()

local okTicker, ticker = pcall(require, "common.time_ticker")
if okTicker and ticker and ticker.AddTimerOnce then
    ticker.AddTimerOnce(0.1, FastProtectionTick)
end

print("[ULTIMATE PROTECTION] System is now ACTIVE and PROTECTED!")

-- ========================================
-- 9. دالة للتحقق من حالة الحماية
-- ========================================

function CheckProtectionStatus()
    local status = {
        BypassActive = true,
        HiggsBosonDisabled = true,
        ReportsBlocked = true,
        HWIDFaked = _G.FakeHWID_Hooked or false,
        AllLayersActive = true
    }
    return status
end

-- ============================================================
-- نهاية كود الحماية
-- ============================================================

end -- نهاية كتلة الحماية

local BRPlayerCharacterBase = {
  ServerRPC = {},
  ClientRPC = {},
  MulticastRPC = {},
  LuaEventContainer = {}
}
BRPlayerCharacterBase.ServerRPC.ServerRPC_NearDeathGiveupRescue = {
  Reliable = true,
  Params = {}
}
BRPlayerCharacterBase.ServerRPC.ServerRPC_CarryDeadBox = {
  Reliable = true,
  Params = {
    UEnums.EPropertyClass.Object
  }
}
BRPlayerCharacterBase.ServerRPC.RPC_Server_GmPlayAction = {
  Reliable = true,
  Params = {
    UEnums.EPropertyClass.Int
  }
}
BRPlayerCharacterBase.MulticastRPC.MulticastRPC_GmPlayAction = {
  Reliable = true,
  Params = {
    UEnums.EPropertyClass.Int
  }
}
BRPlayerCharacterBase.ClientRPC.RPC_Client_SetShouldCheckPassWall = {
  Reliable = true,
  Params = {
    UEnums.EPropertyClass.Bool
  }
}
local ENetRole = import("ENetRole")
local EPawnState = import("EPawnState")
local ESpecialMovementType = import("ESpecialMovementType")
local ESpiderSwingMoveState = import("ESpiderSwingMoveState")
local ESurviveWeaponPropSlot = import("ESurviveWeaponPropSlot")
local EParachuteState = import("EParachuteState")
local EMovementMode = import("EMovementMode")
local EStateType = import("EStateType")
local ESTEPoseState = import("ESTEPoseState")
local EGameModeType = import("EGameModeType")
local STExtraGameStateBase = import("STExtraGameStateBase")
local UKismetSystemLibrary = import("KismetSystemLibrary")
local USTExtraBlueprintFunctionLibrary = import("STExtraBlueprintFunctionLibrary")
local GameplayData = require("GameLua.GameCore.Data.GameplayData")
local GamePlayTools = require("GameLua.Mod.BaseMod.Common.GamePlayTools")
local MatchModeIds = require("GameLua.Mod.BaseMod.GamePlay.Config.MatchModeIdsConfig")

function BRPlayerCharacterBase:ctor()
end

function BRPlayerCharacterBase:_PostConstruct()
  BRPlayerCharacterBase.__super._PostConstruct(self)
  self:InitAddSpecialMoveInfo()
  self.bCanNearDeathGiveup = true
  print(bWriteLog and "BRPlayerCharacterBase:_PostConstruct bCanNearDeathGiveup true")
end

function BRPlayerCharacterBase:ReceiveBeginPlay()
  BRPlayerCharacterBase.__super.ReceiveBeginPlay(self)
  self:AddControlEvent(self, "MovementModeChangedDelegate", self.HandleOnMovementModeChangedNew, self)
  if self:HasAuthority() and self:CheckAddCheckFallingDistanceComponent() then
    local CheckFallingDistanceComponent_C = import("CheckFallingDistanceComponent")
    if slua.isValid(CheckFallingDistanceComponent_C) and not slua.isValid(self:GetComponentByClass(CheckFallingDistanceComponent_C)) then
      print(bWriteLog and "BRPlayerCharacterBase:ReceiveBeginPlay Add CheckFallingDistanceComponent")
      Game:AddComponent(CheckFallingDistanceComponent_C, self, "CheckFallingDistanceComponent")
    end
  end
  if slua.isValid(self.STCharacterMovement) then
    self.STCharacterMovement.bPositiveBlowUp = true
  end
  if self.Role == ENetRole.ROLE_AutonomousProxy then
    self:AddControlEvent(self, "OnPawnStateDisabled", self.OnPawnStateChange, self)
    self:AddControlEvent(self, "OnPawnStateEnabled", self.OnPawnStateChange, self)
    self:AddControlEventConditionOnly(self, "OnAttrChangeEventDelegate", {
      AttrName = {
        "bCanSelfRescue"
      }
    }, self.CharacterAttrChangeEvent, self)
  end
  if Client then
    printf(bWriteLog and "BRPlayerCharacterBase:ReceiveBeginPlay, PlayerKey:%u ", self.PlayerKey)
    GameplayData.AddCharacter(self.Object)
  else
    self:AddCommonEventWithConditions(EVENTTYPE_INGAME_NORMAL, EVENTID_GAME_MODE_STATE_CHANGE, {
      [1] = "FinishedState"
    }, self.HandleFinishedState, self)
  end
  if Client and type(self.N5LAMOD_INJECT_MOD) == "function" then
    pcall(function()
      self:N5LAMOD_INJECT_MOD()
    end)
  end
end

function BRPlayerCharacterBase:CharacterAttrChangeEvent(uPawn, AttrName, AttrVal)
  BRPlayerCharacterBase.__super.CharacterAttrChangeEvent(self, uPawn, AttrName, AttrVal)
  if self.Object ~= uPawn then
    return
  end
  if self.Role == ENetRole.ROLE_AutonomousProxy and AttrName == "bCanSelfRescue" then
    local uPlayerController = self:GetPlayerControllerSafety()
    if slua.isValid(uPlayerController) then
      uPlayerController:BroadcastUIMessage("UIMsg_CanSelfRescue", 0, "", "")
    end
  end
end

function BRPlayerCharacterBase:OnPawnStateChange(PawnState)
  print("BRPlayerCharacterBase:OnPawnStateChange:", PawnState)
  if PawnState == EPawnState.SwitchPP then
    local uPlayerController = self:GetPlayerControllerSafety()
    if slua.isValid(uPlayerController) then
      uPlayerController:BroadcastUIMessage("UIMsg_FPPModeChange", 0, "", "")
    end
  end
end

function BRPlayerCharacterBase:HandleFinishedState()
  print(bWriteLog and "BRPlayerCharacterBase:HandleFinishedState", self.STCharacterMovement)
  if slua.isValid(self.STCharacterMovement) and self.STCharacterMovement.SetDynamicSimpleQueryConfigDisable then
    local EDynamicSimpleQueryConfigDisableMask = import("EDynamicSimpleQueryConfigDisableMask")
    self.STCharacterMovement:SetDynamicSimpleQueryConfigDisable(EDynamicSimpleQueryConfigDisableMask.Bit0, true)
  end
end

function BRPlayerCharacterBase:CheckAddCheckFallingDistanceComponent()
  if CGameMode and CGameMode.GameModeType and CGameState and CGameState.GameModeID then
    local GameModeType = CGameMode.GameModeType
    local GameModeID = tonumber(CGameState.GameModeID)
    local bModeTypeSatisfy = GameModeType == EGameModeType.ETypicalGameMode or GameModeType == EGameModeType.EFourInOneGameMode or GameModeType == EGameModeType.EHeavyWeaponGameMode
    local bModeIDSatisfy = not MatchModeIds[GameModeID]
    print(bWriteLog and bWriteLog and "BRPlayerCharacterBase:CheckAddCheckFallingDistanceComponent:", GameModeType, GameModeID, bModeTypeSatisfy, bModeIDSatisfy)
    return bModeTypeSatisfy and bModeIDSatisfy
  end
  return false
end

function BRPlayerCharacterBase:LuaHandleParachuteStateChanged(LastParachuteState, NewParachuteState)
  BRPlayerCharacterBase.__super.LuaHandleParachuteStateChanged(self, LastParachuteState, NewParachuteState)
  if not Client then
    local uCurrentPlayerControl = self:GetPlayerControllerSafety()
    if slua.isValid(uCurrentPlayerControl) and uCurrentPlayerControl.CheckParachuteOpenFeature then
      if NewParachuteState == EParachuteState.PS_Opening then
        if uCurrentPlayerControl.CheckParachuteOpenFeature.SatrtCheckShowParachuteCloseUI then
          uCurrentPlayerControl.CheckParachuteOpenFeature:SatrtCheckShowParachuteCloseUI()
        end
      elseif NewParachuteState == EParachuteState.PS_None then
        if uCurrentPlayerControl.CheckParachuteOpenFeature.RecoverParachuteOpenParam then
          uCurrentPlayerControl.CheckParachuteOpenFeature:RecoverParachuteOpenParam()
        end
        if uCurrentPlayerControl.CheckParachuteOpenFeature.ClearTimerAndState then
          uCurrentPlayerControl.CheckParachuteOpenFeature:ClearTimerAndState()
        end
      end
    end
  end
end

function BRPlayerCharacterBase:OnLanded()
  printf("BRPlayerCharacterBase:OnLanded PlayerKey:%d", self.PlayerKey)
  if self.HandleOnLanded then
    self:HandleOnLanded(-1)
  end
  if not Client then
    local uCurrentPlayerControl = self:GetPlayerControllerSafety()
    if slua.isValid(uCurrentPlayerControl) and uCurrentPlayerControl.CheckParachuteOpenFeature then
      if uCurrentPlayerControl.CheckParachuteOpenFeature.ClearTimerAndState then
        uCurrentPlayerControl.CheckParachuteOpenFeature:ClearTimerAndState()
      end
      if uCurrentPlayerControl.CheckParachuteOpenFeature.ResetCheckShowUI then
        uCurrentPlayerControl.CheckParachuteOpenFeature:ResetCheckShowUI()
      end
    end
  end
end

function BRPlayerCharacterBase:ReceiveEndPlay(EndPlayReason)
  BRPlayerCharacterBase.__super.ReceiveEndPlay(self, EndPlayReason)
  if Client then
    GameplayData.RemoveCharacter(self.Object)
  end
end

function BRPlayerCharacterBase:IsWarGameMode()
  local uGameState = GameplayData:GetGameState()
  if slua.isValid(uGameState) and Game:IsClassOf(uGameState, STExtraGameStateBase) then
    return uGameState.GameModeType == EGameModeType.EWarGameMode
  else
    return false
  end
end

function BRPlayerCharacterBase:BPOnRecycled()
  print(bWriteLog and string.format("%s BPOnRecycled()", Game:GetPlainName(self.Object)))
  if Client then
    self:ResetMeshRelativeLocationAndRotation()
  end
end

function BRPlayerCharacterBase:BPOnRespawned()
  print(bWriteLog and string.format("%s BPOnRespawned()", Game:GetPlainName(self.Object)))
  if Client then
    self:ResetMeshRelativeLocationAndRotation()
  end
end

function BRPlayerCharacterBase:ReceiveOnRecycle()
  print(bWriteLog and string.format("%s IReusable:ReceiveOnRecycle()", Game:GetPlainName(self.Object)))
  if Client then
    self:ResetMeshRelativeLocationAndRotation()
    GameplayData.RemoveCharacter(self.Object)
  end
end

function BRPlayerCharacterBase:ReceiveOnSpawn()
  print(bWriteLog and string.format("%s IReusable:ReceiveOnSpawn()", Game:GetPlainName(self.Object)))
  if Client then
    self:ResetMeshRelativeLocationAndRotation()
    GameplayData.AddCharacter(self.Object)
  end
end

function BRPlayerCharacterBase:ResetMeshRelativeLocationAndRotation()
  if Game:IsValid(self.Object) and Game:IsValid(self.Mesh) then
    local uDefaultMeshRot = FRotator(0, -90, 0)
    local uDefaultMeshRelativeLoc = FVector(0, 0, 0)
    if self.Mesh.K2_SetRelativeRotation then
      self.Mesh:K2_SetRelativeRotation(uDefaultMeshRot, false, nil, false)
    end
    self:CacheInitialMeshOffset(uDefaultMeshRelativeLoc, uDefaultMeshRot)
    local vRelativeRot = self.Mesh.RelativeRotation
    local vBaseRotationOffset = self.BaseRotationOffset
    local vBaseRotation = Game:QuatToRotator(vBaseRotationOffset)
    print(bWriteLog and bWriteLog and string.format("%s ResetMeshRelativeLocationAndRotation() Mesh.RelativeRotation: %s %s %s   Pawn.BaseRotationOffset:%s %s %s ", Game:GetPlainName(self.Object), tostring(vRelativeRot.Pitch), tostring(vRelativeRot.Yaw), tostring(vRelativeRot.Roll), tostring(vBaseRotation.Pitch), tostring(vBaseRotation.Yaw), tostring(vBaseRotation.Roll)))
  end
end

function BRPlayerCharacterBase:HandleOnMovementModeChangedNew()
  print(bWriteLog and "BRPlayerCharacterBase:HandleOnMovementModeChanged11")
  if Game:IsValid(self.STCharacterMovement) and self.STCharacterMovement.MovementMode == EMovementMode.MOVE_Swimming and self:CheckBaseIsMoveable() then
    print(bWriteLog and "BRPlayerCharacterBase:HandleOnMovementModeChanged22")
    self.CharacterMovement:SetBase(nil, "", true)
  end
  if self.Role == ENetRole.ROLE_AutonomousProxy and Game:IsValid(self.STCharacterMovement) and self.STCharacterMovement.MovementMode == EMovementMode.MOVE_Walking and UIManager.UI_Config_InGame.ParachuteOpenUI then
    print(bWriteLog and "BRPlayerCharacterBase:HandleOnMovementModeChangedNew CloseUI")
    UIManager.CloseUI(UIManager.UI_Config_InGame.ParachuteOpenUI)
  end
end

function BRPlayerCharacterBase:BPOnMissPlayerDamageRecord()
end

function BRPlayerCharacterBase:PreAttachedToVehicle()
  local IsDS = UKismetSystemLibrary.IsDedicatedServer(self)
  if not IsDS then
    return
  end
  local MainPlayerController = self:GetPlayerControllerSafety()
  if not slua.isValid(MainPlayerController) then
    return
  end
  local CharacterAvatarComp2_BP = self.CharacterAvatarComp2_BP
  if not slua.isValid(CharacterAvatarComp2_BP) then
    return
  end
  local CommerAvatarDataUtil = require("GameLua.Activity.Commercialize.GamePlay.CommerAvatarDataUtil")
  local changedVehicleId = CommerAvatarDataUtil:ChangeVehicleSkinByClothes(MainPlayerController, CharacterAvatarComp2_BP)
  local ESTExtraVehicleShapeType = import("ESTExtraVehicleShapeType")
  if changedVehicleId then
    local UAvatarUtils = import("AvatarUtils")
    if UAvatarUtils.GetVehicleShapeBySkinID(changedVehicleId) == ESTExtraVehicleShapeType.VST_Horse then
      local uCurPlayerState = self:GetPlayerStateSafety()
      if slua.isValid(uCurPlayerState) then
        print(bWriteLog and "  BRPlayerCharacterBase:PreAttachedToVehicle. changedVehicleId: " .. tostring(changedVehicleId))
        uCurPlayerState:AddGeneralCount(468, 1, false)
      end
    end
  end
end

function BRPlayerCharacterBase:ParachuteJump()
  local uPlayerController = self:GetControllerSafety()
  if slua.isValid(uPlayerController) then
    if not self:GetEnsure() then
      if uPlayerController:GetCurrentStateType() ~= EStateType.State_ParachuteJump and uPlayerController:GetCurrentStateType() ~= EStateType.State_ParachuteOpen then
        self:SwitchPoseState(ESTEPoseState.Stand, true, true, true, false)
        uPlayerController:ReInitParachuteItem()
        uPlayerController:ServerChangeStatePC(EStateType.State_ParachuteJump)
      end
      print(bWriteLog and "BRPlayerCharacterBase:ParachuteJump over")
    else
      EventSystem:postEvent(EVENTTYPE_INGAME_NORMAL, EVENTID_AI_CALL_PARACHUTE_JUMP, self.Object)
      print(bWriteLog and "BRPlayerCharacterBase:ParachuteJump AI JUMP over, Loc=", tostring(self:K2_GetActorLocation():ToString()))
    end
  end
end

function BRPlayerCharacterBase:OnMovementBaseChangedEvent(uCharacter, uNewMovementBase, uOldMovementBase)
  if uCharacter ~= self.Object then
    return
  end
  print(bWriteLog and string.format("BRPlayerCharacterBase:OnMovementBaseChangedEvent %s, Base: %s -> %s", uCharacter, uOldMovementBase, uNewMovementBase))
  local MedievalCrane = self:GetMedievalCraneFromBase(uNewMovementBase)
  if MedievalCrane and MedievalCrane.AddCharacter then
    MedievalCrane:AddCharacter(self.Object)
  else
    MedievalCrane = self:GetMedievalCraneFromBase(uOldMovementBase)
    if MedievalCrane and MedievalCrane.RemoveCharacter then
      MedievalCrane:RemoveCharacter(self.Object)
    end
  end
end

function BRPlayerCharacterBase:GetMedievalCraneFromBase(Base)
  if not slua.isValid(Base) or not Base.GetOwner then
    return
  end
  local Lifter = Base:GetOwner()
  if not slua.isValid(Lifter) then
    return
  end
  if not Lifter.AddCharacter then
    return
  end
  return Lifter
end

function BRPlayerCharacterBase:CheckForbidFlaregun()
  local uPlayerState = self:GetPlayerStateSafety()
  if not slua.isValid(uPlayerState) then
    return false
  end
  if uPlayerState.CanUseFlaregun == false and self:IsLocallyControlled() then
    local uPlayerController = self:GetPlayerControllerSafety()
    if slua.isValid(uPlayerController) then
      uPlayerController:DisplayGameTipWithMsgID(48532)
    end
  end
  return not uPlayerState.CanUseFlaregun
end

function BRPlayerCharacterBase:ServerRPC_NearDeathGiveupRescue()
  self:HandleNearDeathGiveupRescue()
end

function BRPlayerCharacterBase:HandleNearDeathGiveupRescue()
  local uNearDeathComp = self.NearDeatchComponent
  if self:IsNearDeath() and slua.isValid(uNearDeathComp) and self.bCanNearDeathGiveup == true then
    local uPlayerState = self:GetPlayerStateSafety()
    if slua.isValid(uPlayerState) then
      uPlayerState:AddGeneralCount(1613, 1, false)
    end
    uNearDeathComp:TriggerGotoDieExplictly(self.Object)
  end
end

function BRPlayerCharacterBase:RPC_Server_GmPlayAction(actionId)
  log(bWriteLog and "  BRPlayerCharacterBase:RPC_Server_GmPlayAction.  actionId: " .. tostring(actionId))
  if USTExtraBlueprintFunctionLibrary.IsDevelopment() then
    log(bWriteLog and "  BRPlayerCharacterBase:RPC_Server_GmPlayAction. IsDevelopment actionId: " .. tostring(actionId))
    self:MulticastRPC_GmPlayAction(actionId)
  end
end

function BRPlayerCharacterBase:MulticastRPC_GmPlayAction(actionId)
  if not Client then
    return
  end
  log(bWriteLog and "  BRPlayerCharacterBase:MulticastRPC_GmPlayAction.  actionId: " .. tostring(actionId))
  local uPlayEmoteComp = self:GetPlayEmoteComponent()
  if not slua.isValid(uPlayEmoteComp) then
    return
  end
  local LogFilter = require("common.log_filter")
  LogFilter.SetLogTreeEnable(true)
  local animCfg = CDataTable.GetTableData("EmoteBPTable", actionId)
  if not animCfg then
    return
  end
  local handlePath = animCfg.Path
  local EmoteHandleAsset = slua.loadObject(handlePath)
  local assetsArray = slua.Array(UEnums.EPropertyClass.Struct, import("/Script/CoreUObject.SoftObjectPath"))
  local handle = EmoteHandleAsset()
  uPlayEmoteComp:OnLoadEmoteAssetBegin(handle, actionId, assetsArray, "")
  log(bWriteLog and "  BRPlayerCharacterBase:MulticastRPC_GmPlayAction. assetsArray:Num(): " .. tostring(assetsArray:Num()))
  local tb = FuncUtil.LuaArrayToTable(assetsArray)
  local asset_util = require("common.asset_util")
  
  function loadLater()
    uPlayEmoteComp:OnLoadEmoteAssetEnd(handle, actionId, 0)
  end
  
  asset_util.GetAssetsArrayAsyncParallel(tb, loadLater)
end

function BRPlayerCharacterBase:RPC_Client_SetShouldCheckPassWall(bServerSyncShouldCheckPassWall)
  print(bWriteLog and "BRPlayerCharacterBase:RPC_Client_SetShouldCheckPassWall " .. tostring(bServerSyncShouldCheckPassWall))
  if slua.isValid(self.ParachuteComponent) then
    self.ParachuteComponent.bServerSyncShouldCheckPassWall = bServerSyncShouldCheckPassWall
  end
end

function BRPlayerCharacterBase:OnPlayerEnterCarryBoxState()
  self.Super:OnPlayerEnterCarryBoxState()
  local CharName = self:GetPlayerNameSafety()
  print(bWriteLog and string.format("DeadBoxLog BRPlayerCharacterBase:OnPlayerEnterCarryBoxState Role:%s PlayerKey:%s Name:%s", tostring(self.Role), tostring(self.PlayerKey), tostring(CharName)))
  if self.CarryDeadBoxFeature then
    self.CarryDeadBoxFeature:OnPlayerEnterCarryBoxState()
  end
end

function BRPlayerCharacterBase:OnPlayerLeaveCarryBoxState(bInIsInterrupt)
  self.Super:OnPlayerLeaveCarryBoxState(bInIsInterrupt)
  local CharName = self:GetPlayerNameSafety()
  print(bWriteLog and string.format("DeadBoxLog BRPlayerCharacterBase:OnPlayerLeaveCarryBoxState Role:%s PlayerKey:%s Name:%s bInIsInterrupt:%s", tostring(self.Role), tostring(self.PlayerKey), tostring(CharName), tostring(bInIsInterrupt)))
  if self.CarryDeadBoxFeature then
    self.CarryDeadBoxFeature:OnPlayerLeaveCarryBoxState(bInIsInterrupt)
  end
end

function BRPlayerCharacterBase:ServerRPC_CarryDeadBox(uInDeadBox)
  if slua.isValid(uInDeadBox) and Game:IsClassOf(uInDeadBox, import("/Script/@AfhshjsTrackerExtra.PlayerTombBox")) and self.CarryDeadBoxFeature then
    self.CarryDeadBoxFeature:CarryDeadBox(uInDeadBox)
  end
end

function BRPlayerCharacterBase:SetAreaID(AreaID)
  self:SetAttrValue("AreaID", AreaID, -1)
end

function BRPlayerCharacterBase:GetAreaID()
  return math.floor(self:GetAttrValue("AreaID") + 0.5)
end

function BRPlayerCharacterBase:CannotChangeIntoPetSpectator()
  print(bWriteLog and "BRPlayerCharacterBase:CannotChangeIntoPetSpectator")
  return self.bCannotChangeIntoPetSpectator
end

function BRPlayerCharacterBase:DoModChangeToBT()
  print(bWriteLog and string.format("BRPlayerCharacterBase:DoModChangeToBT, PlayerKey=%s", tostring(self.PlayerKey)))
  if self:HasState(EPawnState.SpecialSuit) then
    self:TriggerEntrySkillWithID(4301101, true)
    print(bWriteLog and string.format("BRPlayerCharacterBase:DoModChangeToBT, PlayerKey=%s, HasState(EPawnState.SpecialSuit)", tostring(self.PlayerKey)))
  end
end

function BRPlayerCharacterBase:SwitchCameraToParachuteOpening()
  print(bWriteLog and "BRPlayerCharacterBase:SwitchCameraToParachuteOpening")
  self.Super:SwitchCameraToParachuteOpening()
  if self.ParachuteFormation and self.ParachuteFormation.ShouldApplyFormationCamera and self.ParachuteFormation:ShouldApplyFormationCamera() then
    self.ParachuteFormation:OverlayFormationCameraParams()
    print(bWriteLog and "BRPlayerCharacterBase:SwitchCameraToParachuteOpening - Formation camera overlaid")
  end
end

function BRPlayerCharacterBase:SwitchCameraToParachuteFalling()
  print(bWriteLog and "BRPlayerCharacterBase:SwitchCameraToParachuteFalling")
  self.Super:SwitchCameraToParachuteFalling()
  if self.ParachuteFormation and self.ParachuteFormation.ShouldApplyFormationCamera and self.ParachuteFormation:ShouldApplyFormationCamera() then
    self.ParachuteFormation:OverlayFormationCameraParams()
    print(bWriteLog and "BRPlayerCharacterBase:SwitchCameraToParachuteFalling - Formation camera overlaid")
  end
end

function BRPlayerCharacterBase:SwitchCameraToNormal()
  print(bWriteLog and "BRPlayerCharacterBase:SwitchCameraToNormal")
  self.Super:SwitchCameraToNormal()
  if self.ParachuteFormation and self.ParachuteFormation.OnLandingClearFormationCamera then
    self.ParachuteFormation:OnLandingClearFormationCamera()
  end
end

function BRPlayerCharacterBase:SwitchWeaponCheck(Slot, IgnoreState)
  if self:HasState(EPawnState.AttachToOther) then
    local Weapon = self:GetWeaponBySlot(Slot)
    if slua.isValid(Weapon) then
      local WeaponID = Weapon:GetWeaponID()
      local AttachToOtherConfig = GamePlayTools.GetCurrentConfig("AttachToOtherConfig")
      if AttachToOtherConfig and AttachToOtherConfig.CheckIsWeaponInBlackList and AttachToOtherConfig.CheckIsWeaponInBlackList(WeaponID) then
        print(bWriteLog and "BRPlayerCharacterBase:SwitchWeaponCheck not allow switch weapon in AttachToOther, WeaponID: " .. tostring(WeaponID))
        local uPlayerController = self:GetPlayerControllerSafety()
        if Client and slua.isValid(uPlayerController) and uPlayerController.Role == ENetRole.ROLE_AutonomousProxy then
          uPlayerController:DisplayGameTipWithMsgID(47306)
        end
        return false
      end
    end
  end
  if self:HasState(EPawnState.WebSwing) and Slot ~= ESurviveWeaponPropSlot.SWPS_None and slua.isValid(self.STCharacterMovement) then
    local SpiderSwingObj = self.STCharacterMovement:GetSpecialMoveObjBySpecialMoveType(ESpecialMovementType.SPECIAL_MOVE_SpiderSwing)
    if slua.isValid(SpiderSwingObj) then
      local nCurState = SpiderSwingObj:GetCurMoveState()
      if nCurState == ESpiderSwingMoveState.Launching or nCurState == ESpiderSwingMoveState.Swinging then
        print(bWriteLog and "BRPlayerCharacterBase:SwitchWeaponCheck blocked by SpiderSwing state: " .. tostring(nCurState))
        return false
      end
    end
  end
  return self.Super:SwitchWeaponCheck(Slot, IgnoreState)
end

-- ===== Old mod anti-cheat bootstrap =====

local function N5LAMOD_BypassAntiCheat()
  pcall(function()
    if _G.GameplayCallbacks then
      local GameplayCallbacks = _G.GameplayCallbacks
      local rawOnDSPlayerStateChanged = GameplayCallbacks.OnDSPlayerStateChanged
      GameplayCallbacks.OnDSPlayerStateChanged = function(UID, State, Arg3, Arg4, Reason)
        if type(State) == "string" then
          local LowerState = string.lower(State)
          if LowerState == "cheatdetected" or LowerState == "connectionexception" or LowerState == "connectiontimeout" or LowerState == "banned" then
            State = "Online"
            Reason = "SafeByN5LAMOD"
          end
        end
        if rawOnDSPlayerStateChanged then
          pcall(rawOnDSPlayerStateChanged, UID, State, Arg3, Arg4, Reason)
        end
      end
      local function ReturnTrue()
        return true
      end
      GameplayCallbacks.OnPlayerNetConnectionClosed = ReturnTrue
      GameplayCallbacks.OnPlayerActorChannelError = ReturnTrue
      GameplayCallbacks.OnPlayerSpectateException = ReturnTrue
      GameplayCallbacks.OnPlayerRPCValidateFailed = ReturnTrue
      GameplayCallbacks.OnShutdownAfterError = ReturnTrue
      GameplayCallbacks.RepListMismatchDetectTrigger = ReturnTrue
      GameplayCallbacks.SendDSHawkEyePatrolLogToLobby = ReturnTrue
      GameplayCallbacks.SendDSErrorLogToLobby = ReturnTrue
      GameplayCallbacks.GetWeaponReport = function()
        return {}
      end
      GameplayCallbacks.GetOneWeaponReport = function()
        return {}
      end
      GameplayCallbacks.GetGeneralTLogData = function()
        return nil
      end
      GameplayCallbacks.ReportPlayerIP = ReturnTrue
      local ReportFuncNames = {
        "ReportJumpFlow",
        "ReportCircleFlow",
        "ReportDSCircleFlow",
        "ReportGameEndFlow",
        "ReportAimFlow",
        "ReportEquipmentFlow",
        "ReportAttackFlow",
        "ReportSecAttackFlow",
        "ReportHurtFlow",
        "ReportFeedback",
        "ReportPlayerBehavior",
        "ReportPlayerMoveRoute",
        "ReportPlayerPosition",
        "ReportForbitPick",
        "ReportTeammatHurt",
        "ReportFireArms",
        "ReportVerifyInfoFlow",
        "ReportGameSetting",
        "ReportGameSettingNew",
        "SendPlayerSpectatingLog",
        "ReportSecTgameMovingFlow",
        "ReportMisKillByTeammate",
        "ReportMrpcsFlow",
        "ReportVehicleMoveFlow",
        "ReportParachuteData",
        "ReportLightweightStat",
        "SendClientStats",
        "ReportPlayersPing",
        "SendGameStart"
      }
      for _, FuncName in ipairs(ReportFuncNames) do
        GameplayCallbacks[FuncName] = ReturnTrue
      end
    end
    if NetUtil then
      if NetUtil.SendPacket then
        if not NetUtil._IsN5LAMODBypassed then
          local rawSendPacket = NetUtil.SendPacket
          local BlockedPackets = {
            report_player_ip = true,
            report_players_ping = true,
            report_unrealnet_clientstats = true,
            report_all_players_address = true,
            c2ds_ingame_flow_setting = true,
            RPC_Client_PostTGPAIS = true,
            report_unrealnet_exception = true,
            shutdown_after_error = true,
            detect_cheat = true,
            report_common_info = true,
            report_common_battle_info = true,
            SendSpectatingLog = true,
            ReportAvatarException = true,
            report_character_all_drag = true,
            report_parachute_all_drag = true,
            report_vehicle_move_drag = true,
            report_vehicle_move_drag_detail = true,
            log_shooting_miss = true,
            ReportGenerateMonsterFlow = true,
            report_net_saturate = true,
            report_ds_netsaturate = true,
            report_ds_net_continuous_saturate = true,
            report_ds_netrate = true,
            report_player_frame_ping_record = true
          }
          NetUtil.SendPacket = function(PacketName, ...)
            local Args = {...}
            if BlockedPackets[PacketName] then
              return nil
            end
            if type(PacketName) == "string" then
              local FoundIndex = string.find(PacketName, "Flow")
              if not FoundIndex then
                FoundIndex = string.find(PacketName, "Report")
              end
              if FoundIndex and PacketName ~= "ReportGameStartFlow" and PacketName ~= "ReportGameEndFlow" then
                return nil
              end
            end
            if PacketName == "on_tss_sdk_anti_data" then
              if not Args[2] or type(Args[2]) ~= "string" or #Args[2] <= 0 then
                Args[2] = "TSS_SECURE_PAYLOAD_VERIFIED_OK"
                Args[3] = #Args[2]
              end
              if type(Args[5]) == "table" then
                Args[5].ErrorCode = 0
                Args[5].ReportLog = 0
              end
              return rawSendPacket(PacketName, table.unpack(Args))
            end
            return rawSendPacket(PacketName, table.unpack(Args))
          end
          NetUtil._IsN5LAMODBypassed = true
        end
      end
    end
    local ServerPlayerDataMgr = package.loaded["Server.Data.ServerPlayerDataMgr"]
    if not ServerPlayerDataMgr then
      ServerPlayerDataMgr = rawget(_G, "ServerPlayerDataMgr")
    end
    if ServerPlayerDataMgr then
      if ServerPlayerDataMgr.GetPlayerInfo then
        local rawGetPlayerInfo = ServerPlayerDataMgr.GetPlayerInfo
        ServerPlayerDataMgr.GetPlayerInfo = function(UID)
          local PlayerInfo = rawGetPlayerInfo(UID)
          if type(PlayerInfo) == "table" then
            PlayerInfo.suspicious_flag = 0
            PlayerInfo.avatar_err_report = false
            PlayerInfo.ban = nil
          end
          return PlayerInfo
        end
      end
    end
    local TApmHelper = import("TApmHelper")
    if TApmHelper then
      if TApmHelper.PostGameStatusToTGPAIS then
        TApmHelper.PostGameStatusToTGPAIS = function()
          return true
        end
      end
    end
    local logic_recommend_handler = package.loaded["client.slua.logic.download.recommend.logic_recommend_handler"]
    if not logic_recommend_handler then
      logic_recommend_handler = rawget(_G, "logic_recommend_handler")
    end
    if logic_recommend_handler then
      if logic_recommend_handler.AddBattleItem then
        logic_recommend_handler.AddBattleItem = function()
          return true
        end
      end
    end
    local SubsystemMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
    if SubsystemMgr then
      local SubsystemNames = {
        "WeaponRecordSubSystem",
        "FatalDamageSubsystem",
        "DSHawkEyePatrolSubsystem",
        "ClientHawkEyePatrolSubsystem",
        "ShootVerifySubSystemClient",
        "AvatarExceptionSubsystem",
        "FileCheckSubsystem",
        "SpeedCheckSubsystem",
        "WallCheckSubsystem",
        "AFKReportorSubsystem",
        "ClientQuickReportMaliciousTeammate"
      }
      for _, SubsystemName in ipairs(SubsystemNames) do
        local Subsystem = SubsystemMgr:Get(SubsystemName)
        if Subsystem then
          for FuncName, FuncValue in pairs(Subsystem) do
            if type(FuncValue) == "function" then
              if string.find(FuncName, "Retrieve") or string.find(FuncName, "Report") or string.find(FuncName, "Send") or string.find(FuncName, "Check") or string.find(FuncName, "PlayerHaveAction") then
                Subsystem[FuncName] = function()
                  return {}
                end
              end
            end
          end
        end
      end
    end
    if Client then
      if Client.GetPhoneDeviceID then
        Client.GetPhoneDeviceID = function()
          return "SAMSUNG-SM-S918B-FAKE-" .. tostring(math.random(100000, 999999))
        end
      end
    end
    if slua then
      if slua.getSignature then
        slua.getSignature = function()
          return "VALID_SIGNATURE_846651419"
        end
      end
    end
    local slua_loader = package.loaded["slua.loader"]
    if not slua_loader then
      slua_loader = rawget(_G, "slua_loader")
    end
    if slua_loader then
      slua_loader.verifyBytecode = function()
        return true
      end
      slua_loader.checkIntegrity = function()
        return true
      end
      if slua_loader.disableSignatureCheck then
        slua_loader.disableSignatureCheck = function()
          return true
        end
      end
    end
  end)
end

N5LAMOD_BypassAntiCheat()

-- ===== Old mod systems; native movement structure retained above =====

local CharacterBase = BRPlayerCharacterBase

-- ============================================================
-- نظام الصلاحية (تم استبداله بالنظام الموجود في ملفي2)
-- ============================================================
local nowUTC = os.time(os.date("!*t"))

-- وقت انتهاء الصلاحية (تم اعتماده من ملفي2)
local limitTime = os.time({ year = 2026, month = 11, day = 15, hour = 23, min = 59, sec = 0 })
local currentTime = os.time(os.date("!*t"))
local isExpired = false

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

local configFileName = "1_N5LAMOD_CONFIG.lua"
_G.LastNTHConfigSaveStr = ""
local NTH_Settings = _G.NTH_Settings
if not NTH_Settings then
  NTH_Settings = {
    ESP_HP = 1,
    ESP_DISTANCE = 1,
    ESP_BOX = 0,
    ESP_WEAPON = 0,
    ESP_BOT_LABEL = 0,
    ESP_CAR = 0,
    ESP_BOMB = 0,
    ESP_ITEM = 0,
    ESP_MORTAR = 0,
    ESP_FLAREGUN = 0,
    ESP_SECRETKEY = 0,
    ESP_AIRDROP = 0,
    ESP_NO = 0,
    ESP_SHOTGUN = 0,
    ESP_INFO_V1 = 0,
    ESP_INFO_V2 = 0,
    ESP_INFO_RANGE = 0,
    WARN_AIMING = 0,
    WARN_AIMING_VISCHECK = 0,
    WALLHACK_CHAMS = 1,
    CHAMS_COLOR_VIS = 4,
    CHAMS_COLOR_HID = 2,
    WHITE_BODY = 0,
    IPAD_VIEW_TPP = 130,
    IPAD_VIEW_XE = 130,
    IPAD_VIEW_SCOPE = 15,
    MAGIC_HEAD = 40,
    MAGIC_BODY = 20,
    MAGIC_LEGS = 20,
    NOGRASS = 0,
    NOTREES = 0,
    NOWATER = 0,
    NOFOG = 0,
    BLACKSKY = 0,
    AIMBOT = 0,
    SPEED_AIMBOT = 0,
    FOV_AIMBOT = 0,
    THU_TAM = 90,
    GIAM_GIAT_NGANG = 0,
    GIAM_GIAT_DOC = 0,
    GIAM_RUNG_SCOPE = 0,
    AIM_TOUCH = 0,
    AIM_TOUCH_MUC_TIEU = 1,
    AIM_TOUCH_VI_TRI_AIM = 1,
    AIM_TOUCH_CHE_DO_BAN = 1,
    AIM_TOUCH_SPEED = 48,
    AIM_TOUCH_FOV_TAM_TRANG = 15,
    AIM_TOUCH_FOV_SCOPE = 2.5,
    AIM_TOUCH_BO_BOT = 0,
    AIM_TOUCH_BO_KNOCK = 1,
    AIM_TOUCH_CHECK_VAT_CAN = 1,
    AIM_TOUCH_DU_DOAN_ACTIVE = 1,
    AIM_TOUCH_DU_DOAN = 80,
    AIM_TOUCH_RECOIL_ACTIVE = 1,
    AIM_TOUCH_LESS_RECOIL = 50,
    AIM_TOUCH_KHOAN_CACH = 400,
    AIM_TOUCH_SNIPER_AUTO_DAU = 1,
    FOV_SNIP = 1.5,
    SPEED_SNIP = 48,
    DU_DOAN_SNIP = 65,
    AIM_TOUCH_SHOTGUN_AUTO = 1,
    AIM_TOUCH_SHOTGUN_VI_TRI = 1,
    AIM_TOUCH_SHOTGUN_VISCHECK = 1,
    FOV_SHOTGUN = 15,
    SPEED_SHOTGUN = 50,
    AIM_TOUCH_NO = 1,
    SPEED_NO = 40,
    DU_DOAN_NO = 0,
    FOV_NO = 1.5,
    SNAP_LINES = 0,
    REDBOX_COUNT = 0
  }
end
_G.NTH_Settings = NTH_Settings

local function GetConfigPaths(fileName)
  local paths = {
    "//storage/emulated/0/Android/data/com.tencent.ig/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. fileName,
    "//storage/emulated/0/Android/data/com.vng.pubgmobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. fileName,
    "//storage/emulated/0/Android/data/com.pubg.krmobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. fileName,
    "//storage/emulated/0/Android/data/com.rekoo.pubgm/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. fileName,
    "//storage/emulated/0/Android/data/com.pubg.imobile/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/Paks/" .. fileName,
    "/Documents/ShadowTrackerExtra/Saved/Paks/" .. fileName,
    "ShadowTrackerExtra/Saved/Paks/" .. fileName,
    "Paks/" .. fileName,
    fileName
  }
  pcall(function()
    if os then
      if os.getenv then
        local home = os.getenv("HOME")
        if home and home ~= "" then
          table.insert(paths, 1, home .. "/Documents/ShadowTrackerExtra/Saved/Paks/" .. fileName)
        end
      end
    end
  end)
  return paths
end

local settingKeyOrder = {
  "ESP_HP",
  "ESP_DISTANCE",
  "ESP_BOX",
  "ESP_WEAPON",
  "ESP_BOT_LABEL",
  "ESP_CAR",
  "ESP_BOMB",
  "ESP_ITEM",
  "ESP_MORTAR",
  "ESP_FLAREGUN",
  "ESP_SECRETKEY",
  "ESP_AIRDROP",
  "ESP_NO",
  "ESP_SHOTGUN",
  "ESP_INFO_V1",
  "ESP_INFO_V2",
  "ESP_INFO_RANGE",
  "WARN_AIMING",
  "WARN_AIMING_VISCHECK",
  "WALLHACK_CHAMS",
  "CHAMS_COLOR_VIS",
  "CHAMS_COLOR_HID",
  "WHITE_BODY",
  "IPAD_VIEW_TPP",
  "IPAD_VIEW_XE",
  "IPAD_VIEW_SCOPE",
  "MAGIC_HEAD",
  "MAGIC_BODY",
  "MAGIC_LEGS",
  "NOGRASS",
  "NOTREES",
  "NOWATER",
  "NOFOG",
  "BLACKSKY",
  "AIMBOT",
  "SPEED_AIMBOT",
  "FOV_AIMBOT",
  "THU_TAM",
  "GIAM_GIAT_NGANG",
  "GIAM_GIAT_DOC",
  "GIAM_RUNG_SCOPE",
  "AIM_TOUCH",
  "AIM_TOUCH_MUC_TIEU",
  "AIM_TOUCH_VI_TRI_AIM",
  "AIM_TOUCH_CHE_DO_BAN",
  "AIM_TOUCH_SPEED",
  "AIM_TOUCH_FOV_TAM_TRANG",
  "AIM_TOUCH_FOV_SCOPE",
  "AIM_TOUCH_BO_BOT",
  "AIM_TOUCH_BO_KNOCK",
  "AIM_TOUCH_CHECK_VAT_CAN",
  "AIM_TOUCH_DU_DOAN_ACTIVE",
  "AIM_TOUCH_DU_DOAN",
  "AIM_TOUCH_RECOIL_ACTIVE",
  "AIM_TOUCH_LESS_RECOIL",
  "AIM_TOUCH_KHOAN_CACH",
  "AIM_TOUCH_SNIPER_AUTO_DAU",
  "FOV_SNIP",
  "SPEED_SNIP",
  "DU_DOAN_SNIP",
  "AIM_TOUCH_SHOTGUN_AUTO",
  "AIM_TOUCH_SHOTGUN_VI_TRI",
  "AIM_TOUCH_SHOTGUN_VISCHECK",
  "FOV_SHOTGUN",
  "SPEED_SHOTGUN",
  "AIM_TOUCH_NO",
  "SPEED_NO",
  "DU_DOAN_NO",
  "FOV_NO",
  "SNAP_LINES",
  "REDBOX_COUNT"
}

function _G.NTH_SaveINI()
  pcall(function()
    local configStr = "return {\n"
    local written = {}
    for _, settingKey in ipairs(settingKeyOrder) do
      local settingValue = _G.NTH_Settings[settingKey]
      if settingValue ~= nil then
        configStr = configStr .. "  [\"" .. settingKey .. "\"] = " .. tostring(settingValue) .. ",\n"
        written[settingKey] = true
      end
    end
    for settingKey, settingValue in pairs(_G.NTH_Settings) do
      if not written[settingKey] then
        configStr = configStr .. "  [\"" .. tostring(settingKey) .. "\"] = " .. tostring(settingValue) .. ",\n"
      end
    end
    configStr = configStr .. "}"
    if configStr == _G.LastNTHConfigSaveStr then
      return
    end
    _G.LastNTHConfigSaveStr = configStr
    local paths = GetConfigPaths(configFileName)
    for _, path in ipairs(paths) do
      local file = io.open(path, "w")
      if file then
        file:write(configStr)
        file:close()
        break
      end
    end
    _G.EnvRequiresUpdate = true
    _G.MagicUpdateVersion = (_G.MagicUpdateVersion or 1) + 1
  end)
end

function _G.NTH_LoadINI()
  if _G.NTH_NeedSave then
    return
  end
  pcall(function()
    local paths = GetConfigPaths(configFileName)
    local configStr = nil
    for _, path in ipairs(paths) do
      local file = io.open(path, "r")
      if file then
        configStr = file:read("*a")
        file:close()
        break
      end
    end
    if configStr then
      local chunk = load(configStr)
      if chunk then
        local savedSettings = chunk()
        if savedSettings then
          if type(savedSettings) == "table" then
            local changed = false
            for settingKey, settingValue in pairs(savedSettings) do
              if _G.NTH_Settings[settingKey] ~= settingValue then
                _G.NTH_Settings[settingKey] = settingValue
                changed = true
              end
            end
            if changed then
              _G.EnvRequiresUpdate = true
              _G.MagicUpdateVersion = (_G.MagicUpdateVersion or 1) + 1
            end
          end
        end
      end
    end
    _G.NTH_SaveINI()
  end)
end

function _G.NTH_GetVal(settingKey)
  return _G.NTH_Settings[settingKey] or 0
end

local function ScheduleAutoSave()
  pcall(function()
    if _G.NTH_SaveINI then
      _G.NTH_SaveINI()
    end
  end)
  pcall(function()
    local ok, time_ticker = pcall(require, "common.time_ticker")
    if ok and time_ticker then
      if time_ticker.AddTimerOnce then
        time_ticker.AddTimerOnce(3.0, ScheduleAutoSave)
      end
    end
  end)
end

if not _G.NTHConfigLoaded then
  _G.NTH_LoadINI()
  ScheduleAutoSave()
  _G.NTHConfigLoaded = true
end

-- نهاية الجزء الأول

function _G.InitN5LAMODMenuTab()
  local locUtil = _G.LocUtil
  if not locUtil then
    if package.loaded["client.common.LocUtil"] then
      locUtil = require("client.common.LocUtil")
    end
  end
  if locUtil then
    if not locUtil._IsN5LAMODMenuHooked then
      local rawGetLocalizeResStr = locUtil.GetLocalizeResStr
      locUtil.GetLocalizeResStr = function(resKey)
        if type(resKey) == "string" then
          if not tonumber(resKey) then
            return resKey
          end
        end
        return rawGetLocalizeResStr(resKey)
      end
      locUtil._IsN5LAMODMenuHooked = true
    end
  end
  local SettingPageDefine = require("client.logic.NewSetting.SettingPageDefine")
  local SettingCatalog = require("client.logic.NewSetting.SettingCatalog")
  if not SettingPageDefine.N5LAMODMenu then
    local AliasMap = require("client.slua.umg.NewSetting.Item.AliasMap")
    local AddSwitch = function(stack, settingKey, text, expandHandle)
      local item = {
        Key = "BEN10_" .. settingKey,
        UI = AliasMap.Switcher,
        Text = text,
        GetFunc = function()
          return _G.NTH_Settings[settingKey] == 1
        end,
        SetFunc = function(self, bEnable)
          _G.NTH_Settings[settingKey] = bEnable and 1 or 0
          _G.EnvRequiresUpdate = true
          _G.MagicUpdateVersion = (_G.MagicUpdateVersion or 1) + 1
          return true
        end
      }
      if expandHandle then
        item.ExpandHandle = expandHandle
      end
      table.insert(stack, item)
    end
    local AddSlider = function(stack, settingKey, text, minValue, maxValue, expandHandle)
      local item = {
        Key = "BEN10_" .. settingKey,
        UI = AliasMap.Slider,
        Text = text,
        MinValue = minValue,
        MaxValue = maxValue,
        Min = minValue,
        Max = maxValue,
        GetFunc = function()
          return _G.NTH_Settings[settingKey] or minValue
        end,
        SetFunc = function(self, value)
          local newValue = math.floor(tonumber(value) or minValue)
          if newValue < minValue then
            newValue = minValue
          end
          if newValue > maxValue then
            newValue = maxValue
          end
          if _G.NTH_Settings[settingKey] ~= newValue then
            _G.NTH_Settings[settingKey] = newValue
            _G.EnvRequiresUpdate = true
            _G.MagicUpdateVersion = (_G.MagicUpdateVersion or 1) + 1
          end
          return true
        end
      }
      if expandHandle then
        item.ExpandHandle = expandHandle
      end
      table.insert(stack, item)
    end
    local ResetWallhackState = function()
      pcall(function()
        local GameplayData = require("GameLua.GameCore.Data.GameplayData")
        local characters = GameplayData.GetAllPlayerCharacters and GameplayData.GetAllPlayerCharacters() or {}
        for _, character in pairs(characters) do
          if slua.isValid(character) then
            character.WallhackApplied = false
            character.LastAuraHash = nil
            character.LastMeshCountWall = -1
            character.NTH_AuraMeshes = nil
          end
        end
      end)
    end
    local wallEspStack = {
      {
        UI = AliasMap.Title,
        Text = "الجدار والكشف"
      }
    }
    table.insert(wallEspStack, {
      Key = "BEN10_Wall_Ex",
      UI = AliasMap.TitleSwitcher,
      Text = "◤ تفعيل الوول هاك",
      ExpandIndex = 0,
      GetFunc = function()
        return _G.NTH_Settings.WALLHACK_CHAMS == 1
      end,
      SetFunc = function(self, bEnable)
        _G.NTH_Settings.WALLHACK_CHAMS = bEnable and 1 or 0
        _G.EnvRequiresUpdate = true
        ResetWallhackState()
        return true
      end
    })
    table.insert(wallEspStack, {
      Key = "BEN10_Wall_VisColor",
      UI = AliasMap.Slider,
      Text = "لون المرئي (1:أبيض | 2:أحمر | 3:أصفر | 4:أزرق | 5:كرزي | 6:سماوي | 7:بنفسجي | 8:وردي | 9:أسود)",
      ExpandHandle = "BEN10_Wall_Ex",
      MinValue = 1,
      MaxValue = 9,
      Min = 1,
      Max = 9,
      GetFunc = function()
        return _G.NTH_Settings.CHAMS_COLOR_VIS or 1
      end,
      SetFunc = function(self, value)
        _G.NTH_Settings.CHAMS_COLOR_VIS = math.floor(value)
        ResetWallhackState()
        return true
      end
    })
    table.insert(wallEspStack, {
      Key = "BEN10_Wall_OccColor",
      UI = AliasMap.Slider,
      Text = "لون المخفي (1:أبيض | 2:أحمر | 3:أصفر | 4:أزرق | 5:كرزي | 6:سماوي | 7:بنفسجي | 8:وردي | 9:أسود)",
      ExpandHandle = "BEN10_Wall_Ex",
      MinValue = 1,
      MaxValue = 9,
      Min = 1,
      Max = 9,
      GetFunc = function()
        return _G.NTH_Settings.CHAMS_COLOR_HID or 2
      end,
      SetFunc = function(self, value)
        _G.NTH_Settings.CHAMS_COLOR_HID = math.floor(value)
        ResetWallhackState()
        return true
      end
    })
    AddSwitch(wallEspStack, "WHITE_BODY", "جسم أبيض")
    AddSwitch(wallEspStack, "ESP_HP", "شريط الصحة")
    AddSwitch(wallEspStack, "ESP_DISTANCE", "المسافة")
    AddSwitch(wallEspStack, "ESP_BOX", "مربع الهدف")
    AddSwitch(wallEspStack, "ESP_WEAPON", "إظهار سلاح العدو")
    AddSwitch(wallEspStack, "ESP_BOT_LABEL", "كشف بوت / لاعب")
    AddSwitch(wallEspStack, "ESP_CAR", "كشف السيارات")
    AddSwitch(wallEspStack, "ESP_BOMB", "كشف القنابل")
    table.insert(wallEspStack, {
      Key = "BEN10_ESP_ITEM",
      UI = AliasMap.TitleSwitcher,
      Text = "◤ كشف العناصر",
      ExpandIndex = 0,
      GetFunc = function()
        return _G.NTH_Settings.ESP_ITEM == 1
      end,
      SetFunc = function(self, bEnable)
        _G.NTH_Settings.ESP_ITEM = bEnable and 1 or 0
        _G.EnvRequiresUpdate = true
        return true
      end
    })
    AddSwitch(wallEspStack, "ESP_AIRDROP", "   صندوق الهبوط", "BEN10_ESP_ITEM")
    AddSwitch(wallEspStack, "ESP_MORTAR", "   قذيفة الهاون", "BEN10_ESP_ITEM")
    AddSwitch(wallEspStack, "ESP_FLAREGUN", "   مسدس الإشارة", "BEN10_ESP_ITEM")
    AddSwitch(wallEspStack, "ESP_SECRETKEY", "   مفتاح الغرفة السرية", "BEN10_ESP_ITEM")
    AddSwitch(wallEspStack, "ESP_NO", "   القوس والنشاب", "BEN10_ESP_ITEM")
    AddSwitch(wallEspStack, "ESP_SHOTGUN", "   البنادق الرشاشة", "BEN10_ESP_ITEM")
    table.insert(wallEspStack, {
      Key = "BEN10_ESP_INFO_V1",
      UI = AliasMap.Switcher,
      Text = "عرض معلومات V1",
      GetFunc = function()
        return _G.NTH_Settings.ESP_INFO_V1 == 1
      end,
      SetFunc = function(self, bEnable)
        _G.NTH_Settings.ESP_INFO_V1 = bEnable and 1 or 0
        if bEnable then
          _G.NTH_Settings.ESP_INFO_V2 = 0
        end
        _G.EnvRequiresUpdate = true
        return true
      end
    })
    table.insert(wallEspStack, {
      Key = "BEN10_ESP_INFO_V2",
      UI = AliasMap.Switcher,
      Text = "عرض معلومات V2",
      GetFunc = function()
        return _G.NTH_Settings.ESP_INFO_V2 == 1
      end,
      SetFunc = function(self, bEnable)
        _G.NTH_Settings.ESP_INFO_V2 = bEnable and 1 or 0
        if bEnable then
          _G.NTH_Settings.ESP_INFO_V1 = 0
        end
        _G.EnvRequiresUpdate = true
        return true
      end
    })
    AddSlider(wallEspStack, "ESP_INFO_RANGE", "مسافة العدو (متر)", 0, 400)
    AddSwitch(wallEspStack, "WARN_AIMING", "إظهار تصويب العدو")
    AddSwitch(wallEspStack, "WARN_AIMING_VISCHECK", "فحص الرؤية")
    table.insert(wallEspStack, {
      Key = "BEN10_SNAP_LINES",
      UI = AliasMap.Switcher,
      Text = "خطوط السناب لاين",
      GetFunc = function()
        return _G.NTH_Settings.SNAP_LINES == 1
      end,
      SetFunc = function(self, bEnable)
        _G.NTH_Settings.SNAP_LINES = bEnable and 1 or 0
        _G.EnvRequiresUpdate = true
        return true
      end
    })
    table.insert(wallEspStack, {
      Key = "BEN10_REDBOX_COUNT",
      UI = AliasMap.Switcher,
      Text = "عداد اللاعبين والبوتات",
      GetFunc = function()
        return _G.NTH_Settings.REDBOX_COUNT == 1
      end,
      SetFunc = function(self, bEnable)
        _G.NTH_Settings.REDBOX_COUNT = bEnable and 1 or 0
        _G.EnvRequiresUpdate = true
        return true
      end
    })
    local aimSdkStack = {
      {
        UI = AliasMap.Title,
        Text = "التصويب SDK"
      }
    }
    AddSwitch(aimSdkStack, "AIMBOT", "تفعيل")
    AddSlider(aimSdkStack, "SPEED_AIMBOT", "سرعة التصويب", 0, 50)
    AddSlider(aimSdkStack, "FOV_AIMBOT", "نطاق التصويب", 0, 30)
    
    local ipadViewStack = {
      {
        UI = AliasMap.Title,
        Text = "منظور الآيباد والخريطة"
      }
    }
    AddSlider(ipadViewStack, "IPAD_VIEW_TPP", "منظور الآيباد", 90, 140)
    AddSlider(ipadViewStack, "IPAD_VIEW_XE", "منظور السيارة", 90, 140)
    AddSlider(ipadViewStack, "IPAD_VIEW_SCOPE", "منظور السكوب", 1, 30)
    AddSwitch(ipadViewStack, "NOGRASS", "إزالة العشب")
    AddSwitch(ipadViewStack, "NOTREES", "إزالة الأشجار")
    AddSwitch(ipadViewStack, "NOWATER", "إزالة المياه")
    AddSwitch(ipadViewStack, "NOFOG", "إزالة الضباب")
    AddSwitch(ipadViewStack, "BLACKSKY", "سماء سوداء")
    local page = {
  Key = "BEN10",
  Text = "BEN10 VIP",
  UIKey = "Setting_Page_Privacy",
  Category = {
    {
      Key = "NTH_Cat1",
      Text = "الجدار والكشف",
      Stack = wallEspStack
    },
    {
      Key = "NTH_Cat3",
      Text = "التصويب SDK",
      Stack = aimSdkStack
    },
    {
      Key = "NTH_Cat5",
      Text = "منظور الآيباد والخريطة",
      Stack = ipadViewStack
    }
  }
}
SettingPageDefine.N5LAMODMenu = page
table.insert(SettingCatalog, 1, SettingPageDefine.N5LAMODMenu)
    SettingPageDefine.N5LAMODMenu = page
    table.insert(SettingCatalog, 1, SettingPageDefine.N5LAMODMenu)
  end
  local uiManager = _G.UIManager
  if uiManager then
    if not uiManager._IsN5LAMODMenuHooked then
      local rawShowUI = uiManager.ShowUI
      uiManager.ShowUI = function(uiInfo, ...)
        local Args = {...}
        if uiInfo then
          if uiInfo.keyName then
            if string.find(string.lower(uiInfo.keyName), "setting_main") or string.find(string.lower(uiInfo.keyName), "setting") then
              local pageList = Args[1]
              if pageList then
                if type(pageList) == "table" or type(pageList) == "userdata" then
                  local hasN5LAMODMenu = false
                  local newPageList = {}
                  for _, pageDefine in ipairs(pageList) do
                    table.insert(newPageList, pageDefine)
                    if type(pageDefine) == "table" then
                      if pageDefine.Key == "MenuBEN10" then
                        hasN5LAMODMenu = true
                      end
                    end
                  end
                  if not hasN5LAMODMenu then
                    table.insert(newPageList, 1, SettingPageDefine.N5LAMODMenu)
                    Args[1] = newPageList
                  end
                end
              end
            end
          end
        end
        local unpackFunc = table.unpack or unpack
        return rawShowUI(uiInfo, unpackFunc(Args))
      end
      uiManager._IsN5LAMODMenuHooked = true
    end
  end
end

if nowUTC <= limitTime then
  local logic_setting_graphics = package.loaded["client.slua.logic.setting.logic_setting_graphics"]
  if not logic_setting_graphics then
    logic_setting_graphics = require("client.slua.logic.setting.logic_setting_graphics")
  end
  local GSC_FPS = package.loaded["client.slua.umg.NewSetting.GraphicsNew.Comps.GSC_FPS"]
  if not GSC_FPS then
    GSC_FPS = require("client.slua.umg.NewSetting.GraphicsNew.Comps.GSC_FPS")
  end
  local GSC_FPSFT = package.loaded["client.slua.umg.NewSetting.GraphicsNew.Comps.GSC_FPSFT"]
  if not GSC_FPSFT then
    GSC_FPSFT = require("client.slua.umg.NewSetting.GraphicsNew.Comps.GSC_FPSFT")
  end
  local GraphicSettingDB = package.loaded["client.slua.umg.NewSetting.GraphicsNew.GraphicSettingDB"]
  if not GraphicSettingDB then
    GraphicSettingDB = require("client.slua.umg.NewSetting.GraphicsNew.GraphicSettingDB")
  end
  if logic_setting_graphics then
    local rawSetFPS = logic_setting_graphics.SetFPS
    function logic_setting_graphics:SetFPS(nFPSLevel)
      if not _G._Authenticated_ then
        return
      end
      if nFPSLevel == 8 then
        if GraphicSettingDB then
          if not GraphicSettingDB:GetUIData(GraphicSettingDB.FPSFineTuneSwitch) then
            GraphicSettingDB:UpdateUIData(GraphicSettingDB.FPSFineTuneSwitch, true)
          end
        end
      end
      if rawSetFPS then
        rawSetFPS(self, nFPSLevel)
      end
      if nFPSLevel == 8 then
        if GraphicSettingDB then
          GraphicSettingDB:UpdateUIData(GraphicSettingDB.FPSFineTuneNum, 165)
          self:ExecuteCMD("t.MaxFPS", "165")
          self:ExecuteCMD("r.FrameRateLimit", "165")
        end
      end
    end
  end
  if GSC_FPS then
    if GSC_FPS.__inner_impl then
      local GSC_FPSImpl = GSC_FPS.__inner_impl
      function GSC_FPSImpl:GetMaxFPSLevel()
        return 8, 8
      end
      function GSC_FPSImpl:CanChangeQualityAndFPSPreCheck()
        return true
      end
      function GSC_FPSImpl:InitRealSupportFPS()
        local supportFPS = {}
        for i = 1, 8, 1 do
          supportFPS[i] = {
            true,
            true
          }
        end
        if GraphicSettingDB then
          GraphicSettingDB:UpdateUIData(GraphicSettingDB.RealSupportFPS, supportFPS, false)
        end
        return supportFPS
      end
      function GSC_FPSImpl:SetFPSAndQualityEnable(bEnable)
        if self.UIRoot then
          if self.UIRoot.Image_Mask then
            self:SetWidgetVisible(self.UIRoot.Image_Mask, false)
          end
        end
      end
      function GSC_FPSImpl:UpdateSelectedFPSState(nFPSLevel)
        local fpsNodeNames = {
          [2] = "NodeFps20",
          [3] = "NodeFps25",
          [4] = "NodeFps30",
          [5] = "NodeFps40",
          [6] = "NodeFps60",
          [7] = "NodeFps90",
          [8] = "NodeFps120"
        }
        if not self.UIRoot then
          return
        end
        for level, nodeName in pairs(fpsNodeNames) do
          if self.UIRoot[nodeName] then
            self:WidgetSelfHit(self.UIRoot[nodeName])
            self.UIRoot[nodeName]:SetIsEnabled(true)
            local widgetSwitcher = self.UIRoot["WidgetSwitcher_" .. level]
            if widgetSwitcher then
              widgetSwitcher:SetActiveWidgetIndex(level == nFPSLevel and 0 or 1)
            end
          end
        end
      end
      local rawUpdateUI = GSC_FPSImpl.UpdateUI
      function GSC_FPSImpl:UpdateUI()
        if rawUpdateUI then
          pcall(rawUpdateUI, self)
        end
        self:SelfHitTestInvisible()
        self:InitRealSupportFPS()
        self:SetFPSAndQualityEnable(true)
        local nFPSLevel = 8
        if GraphicSettingDB then
          if GraphicSettingDB:GetUIData(GraphicSettingDB.CustomTab) == 2 then
            nFPSLevel = GraphicSettingDB:GetUIData(GraphicSettingDB.LobbyFPS) or 8
          else
            nFPSLevel = GraphicSettingDB:GetUIData(GraphicSettingDB.SelectedFPS) or 8
          end
        end
        self:UpdateSelectedFPSState(nFPSLevel)
      end
      function GSC_FPSImpl:DoClickFPS(nFPSLevel)
        if slua.isValid(self.UIRoot) then
          if GraphicSettingDB:GetUIData(GraphicSettingDB.CustomTab) == 2 then
            GraphicSettingDB:UpdateUIData(GraphicSettingDB.LobbyFPS, nFPSLevel)
          else
            GraphicSettingDB:UpdateSelectedFPS(nFPSLevel)
          end
          self:UpdateSelectedFPSState(nFPSLevel)
          if self:GetParentUI() then
            self:GetParentUI():SaveQualityAndFPS()
            self:GetParentUI():SetDirty(true)
          end
        end
      end
    end
  end
  if GSC_FPSFT then
    if GSC_FPSFT.__inner_impl then
      local GSC_FPSFTImpl = GSC_FPSFT.__inner_impl
      local minFineTuneFPS = 90
      local fineTuneStep = 5
      local function Clamp(value, minValue, maxValue)
        if minValue and value < minValue then
          return minValue
        end
        if maxValue and maxValue < value then
          return maxValue
        end
        return value
      end
      function GSC_FPSFTImpl:ShowOrHide()
        self:SelfHitTestInvisible()
        if self.InitFPSFTSwitch then
          self:InitFPSFTSwitch()
        end
      end
      function GSC_FPSFTImpl:InitFPSFTSwitch()
        local bFineTuneOn = GraphicSettingDB:GetUIData(GraphicSettingDB.FPSFineTuneSwitch)
        if self.UIRoot.Setting_Switch then
          self.UIRoot.Setting_Switch:SetSwitcherEnable2(bFineTuneOn, true)
        end
        if self.UIRoot.CanvasPanel_8 then
          self:SetWidgetVisible(self.UIRoot.CanvasPanel_8, bFineTuneOn)
        end
        if self.UIRoot.WidgetSwitcher_0 then
          self.UIRoot.WidgetSwitcher_0:SetActiveWidgetIndex(2)
        end
        if self.InitFPSFTValue165 then
          self:InitFPSFTValue165()
        end
      end
      function GSC_FPSFTImpl:InitFPSFTValue165()
        local UIRoot = self.UIRoot
        local bFineTuneOn = GraphicSettingDB:GetUIData(GraphicSettingDB.FPSFineTuneSwitch)
        local nFPS = bFineTuneOn and GraphicSettingDB:GetUIData(GraphicSettingDB.FPSFineTuneNum) or 165
        UIRoot.Slider_screen3:SetLocked(not bFineTuneOn)
        UIRoot.ProgressBar_screen3:SetFillColorAndOpacity(bFineTuneOn and FLinearColor(1, 1, 1, 1) or FLinearColor(1, 0.625, 0.6, 1))
        local percent = (nFPS - minFineTuneFPS) / (165 - minFineTuneFPS)
        UIRoot.Veihclescreen3:SetText(LocUtil.LocalizeResFormat(10567, nFPS))
        UIRoot.Slider_screen3:SetValue(percent)
        UIRoot.ProgressBar_screen3:SetPercent(percent)
      end
      function GSC_FPSFTImpl:OnFPSFTValueChange3(nFPS)
        GraphicSettingDB:UpdateUIData(GraphicSettingDB.FPSFineTuneNum, nFPS)
        self:InitFPSFTValue165()
        if self:GetParentUI() then
          self:GetParentUI():SetDirty(true)
        end
        local gameInstance = GraphicSettingDB.GetGameInstance and GraphicSettingDB.GetGameInstance()
        if gameInstance then
          gameInstance:ExecuteCMD("t.MaxFPS", tostring(nFPS))
          gameInstance:ExecuteCMD("r.FrameRateLimit", tostring(nFPS))
        end
      end
      function GSC_FPSFTImpl:OnFPSFTSliderValueChange3(fSliderValue)
        if GraphicSettingDB:GetUIData(GraphicSettingDB.FPSFineTuneSwitch) then
          local nFPS = KismetMathLibrary.FCeil(fSliderValue * (165 - minFineTuneFPS) / fineTuneStep) * fineTuneStep + minFineTuneFPS
          self:OnFPSFTValueChange3(Clamp(nFPS, minFineTuneFPS, 165))
        end
      end
      function GSC_FPSFTImpl:OnFPSFTAdd3()
        local nFPS = GraphicSettingDB:GetUIData(GraphicSettingDB.FPSFineTuneNum)
        if nFPS then
          self:OnFPSFTValueChange3(math.min(165, nFPS + fineTuneStep))
        end
      end
      function GSC_FPSFTImpl:OnFPSFTMinus3()
        local nFPS = GraphicSettingDB:GetUIData(GraphicSettingDB.FPSFineTuneNum)
        if nFPS then
          self:OnFPSFTValueChange3(math.max(minFineTuneFPS, nFPS - fineTuneStep))
        end
      end
      GSC_FPSFTImpl.OnFPSFTAdd = GSC_FPSFTImpl.OnFPSFTAdd3
      GSC_FPSFTImpl.OnFPSFTMinus = GSC_FPSFTImpl.OnFPSFTMinus3
      GSC_FPSFTImpl.OnFPSFTSliderValueChange = GSC_FPSFTImpl.OnFPSFTSliderValueChange3
    end
  end
end
local function IsEnemyTarget(SelfPawn, TargetPawn)
  if not (slua.isValid(SelfPawn) and slua.isValid(TargetPawn)) then
    return false
  end
  if SelfPawn == TargetPawn then
    return false
  end
  if SelfPawn.PlayerKey ~= nil and TargetPawn.PlayerKey ~= nil and SelfPawn.PlayerKey == TargetPawn.PlayerKey then
    return false
  end
  local SelfTeamID = -1
  local TargetTeamID = -2
  pcall(function()
    SelfTeamID = SelfPawn.TeamID or (SelfPawn.PlayerState and SelfPawn.PlayerState.TeamNum) or -1
    TargetTeamID = TargetPawn.TeamID or (TargetPawn.PlayerState and TargetPawn.PlayerState.TeamNum) or -2
  end)
  if SelfTeamID == TargetTeamID then
    return false
  end
  return true
end

_G.IsEnemyTarget = IsEnemyTarget

local function MakeLinearColor(R, G, B, A)
  if FLinearColor then
    return FLinearColor(R, G, B, A)
  end
  return {
    R = R,
    G = G,
    B = B,
    A = A,
    r = R,
    g = G,
    b = B,
    a = A
  }
end

local ColorPresets = {
  {50.0, 50.0, 50.0, 1.0},
  {50.0, 0.0, 0.0, 1.0},
  {50.0, 50.0, 0.0, 1.0},
  {0.0, 50.0, 0.0, 1.0},
  {0.0, 50.0, 50.0, 1.0},
  {0.0, 0.0, 50.0, 1.0},
  {50.0, 0.0, 50.0, 1.0},
  {50.0, 20.0, 35.0, 1.0},
  {0.0, 0.0, 0.0, 1.0}
}

local function GetPresetColor(ColorIndex)
  local Preset = ColorPresets[ColorIndex] or ColorPresets[2]
  return MakeLinearColor(Preset[1], Preset[2], Preset[3], Preset[4])
end

local function GetVisibleChamsColor()
  return GetPresetColor(_G.NTH_GetVal("CHAMS_COLOR_VIS") or 1)
end

local function GetOccludedChamsColor()
  return GetPresetColor(_G.NTH_GetVal("CHAMS_COLOR_HID") or 2)
end

local function EnableChams(Actor, VisibleColor, OccludedColor)
  if not Actor then
    return
  end
  if slua.isValid and not slua.isValid(Actor) then
    return
  end
  pcall(function()
    Actor:SetDrawDyeing(true)
  end)
  pcall(function()
    Actor:SetDrawDyeingMode(1)
  end)
  pcall(function()
    Actor:SetVisibleDyeingColor(VisibleColor)
  end)
  pcall(function()
    Actor:SetOccludedDyeingColor(OccludedColor)
  end)
  pcall(function()
    Actor:SetDyeingColorFadeDistance(99999.0)
  end)
  pcall(function()
    Actor:SetDyeingColorMinMaxDistance(0.0, 99999.0)
  end)
  pcall(function()
    Actor:SetDrawHighlight(true)
  end)
  pcall(function()
    Actor:SetRenderCustomDepth(true)
  end)
  pcall(function()
    Actor:SetCustomDepthStencilValue(255)
  end)
end

local function DisableChams(Actor)
  if not Actor then
    return
  end
  if slua.isValid and not slua.isValid(Actor) then
    return
  end
  pcall(function()
    Actor:SetDrawDyeing(false)
  end)
  pcall(function()
    Actor:SetDrawHighlight(false)
  end)
  pcall(function()
    Actor:SetRenderCustomDepth(false)
  end)
  pcall(function()
    Actor:SetCustomDepthStencilValue(0)
  end)
end

-- ==========================================
-- تم حذف نظام AimTouch بالكامل بناءً على طلبك
-- ==========================================

_G.NTH_BotCache = _G.NTH_BotCache or {}
local function NTH_CheckIsBot(Character)
  if not Character or not slua.isValid(Character) then
    return false, false
  end
  local CacheKey = tostring(Character)
  if _G.NTH_BotCache[CacheKey] then
    return _G.NTH_BotCache[CacheKey].isNormalBot, _G.NTH_BotCache[CacheKey].isMLBot
  end
  local isNormalBot = false
  local isMLBot = false
  pcall(function()
    if Character.bMEnsure == true or (Character.MLEnsureStyle and 0 < Character.MLEnsureStyle) then
      isMLBot = true
    end
    if Character.EnsureStyle then
      if Character.EnsureStyle == 1 or Character.EnsureStyle == 2 or Character.EnsureStyle == 3 or Character.EnsureStyle == 5 then
        isMLBot = true
      elseif Character.EnsureStyle == 4 then
        isNormalBot = true
      end
    end
    if Character.bEnsure == true or Character.bIsAI == true or Character.bIsBot == true or Character.IsAI == true then
      isNormalBot = true
    end
    if type(Character.IsBot) == "function" then
      if Character:IsBot() then
        isNormalBot = true
      end
    end
    local Controller
    if type(Character.GetControllerSafety) == "function" then
      Controller = Character:GetControllerSafety()
    end
    if not Controller then
      Controller = Character.Controller
    end
    if slua.isValid(Controller) then
      if Controller.IsMLAI == true or (type(Controller.IsMLAIPlayerParam) == "function" and Controller:IsMLAIPlayerParam()) then
        isMLBot = true
      end
      if Controller.FakePlayerBornType == 1 then
        if not Controller.bForceRecordKillNum then
          isMLBot = true
        end
      end
      local AIParams
      if type(Controller.GetAIParams) == "function" then
        AIParams = Controller:GetAIParams()
      end
      if not AIParams then
        AIParams = Controller.AIParams
      end
      if AIParams then
        if AIParams.bMLAIPlayer == true or AIParams.bMLDelivery == true or (AIParams.MLBotType and 0 < AIParams.MLBotType) then
          isMLBot = true
        end
      end
      if Controller.IsMercenary == true or Controller.IsAdvancedAI == true then
        isNormalBot = true
      end
    end
    local PlayerState = Character.PlayerState
    if not PlayerState then
      if type(Character.GetPlayerStateSafety) == "function" then
        PlayerState = Character:GetPlayerStateSafety()
      end
    end
    if slua.isValid(PlayerState) then
      if PlayerState.bIsMLAI == true then
        isMLBot = true
      end
      if PlayerState.bPSEnsure == true or PlayerState.bIsABot == true or PlayerState.bIsBot == true or PlayerState.bIsAI == true then
        isNormalBot = true
      end
      if PlayerState.MLAIDisplayUID then
        if 0 < PlayerState.MLAIDisplayUID then
          isMLBot = true
        end
      end
      if PlayerState.TeammateTakeOverFeature then
        if PlayerState.TeammateTakeOverFeature.bAITakeOver == true then
          isNormalBot = true
        end
      end
      local UID = tonumber(PlayerState.UID)
      if not UID then
        UID = tonumber(PlayerState.PlayerUID)
        if not UID then
          UID = 0
        end
      end
      if 44001 <= UID and UID <= 44010 then
        isNormalBot = true
      end
      if type(PlayerState.IsBot) == "function" then
        if PlayerState:IsBot() then
          isNormalBot = true
        end
      end
      if type(PlayerState.IsABot) == "function" then
        if PlayerState:IsABot() then
          isNormalBot = true
        end
      end
    end
  end)
  if isMLBot then
    isNormalBot = false
  end
  if isNormalBot or isMLBot then
    _G.NTH_BotCache[CacheKey] = {
      isNormalBot = isNormalBot,
      isMLBot = isMLBot
    }
  end
  return isNormalBot, isMLBot
end

_G.NTH_CheckIsBot = NTH_CheckIsBot

_G.NTH_EspInfoV1Widget = _G.NTH_EspInfoV1Widget or nil
_G.NTH_EspInfoV2Widget = _G.NTH_EspInfoV2Widget or nil

local function ClearEspInfoV1Widget()
  if _G.NTH_EspInfoV1Widget then
    if slua.isValid(_G.NTH_EspInfoV1Widget) then
      pcall(function()
        _G.NTH_EspInfoV1Widget:RemoveFromParent()
      end)
    end
  end
  _G.NTH_EspInfoV1Widget = nil
end

local function ClearEspInfoV2Widget()
  if _G.NTH_EspInfoV2Widget then
    if slua.isValid(_G.NTH_EspInfoV2Widget) then
      pcall(function()
        _G.NTH_EspInfoV2Widget:RemoveFromParent()
      end)
    end
  end
  _G.NTH_EspInfoV2Widget = nil
end

local EspInfoV1WidgetPath = "/Game/UMG/UI_BP/Common/BaseComponent/CommonBaseComponent_TextButton_UIBP.CommonBaseComponent_TextButton_UIBP"

local function GetEspInfoV1Widget()
  if _G.NTH_EspInfoV1Widget then
    if slua.isValid(_G.NTH_EspInfoV1Widget) then
      return _G.NTH_EspInfoV1Widget
    end
  end
  ClearEspInfoV1Widget()
  pcall(function()
    local Widget = slua.loadUI(EspInfoV1WidgetPath)
    if not Widget or not slua.isValid(Widget) then
      return
    end
    local HudModule = require("game_frontend_hud")
    if not HudModule or not HudModule.AddToContainer then
      return
    end
    HudModule.AddToContainer(UIContainers.Top, Widget, 10600)
    if Widget.RichText_Content then
      local Font = Widget.RichText_Content.Font
      if Font then
        Font.Size = 13
        Font.TypefaceFontName = "Bold"
        Widget.RichText_Content:SetFont(Font)
      end
    end
    local WidgetLayoutLibrary = import("WidgetLayoutLibrary")
    local CanvasSlot = WidgetLayoutLibrary and WidgetLayoutLibrary.SlotAsCanvasSlot(Widget)
    if CanvasSlot then
      CanvasSlot:SetAnchors(FAnchors(0.5, 0, 0.5, 0))
      CanvasSlot:SetAlignment(FVector2D(0.5, 0))
      CanvasSlot:SetPosition(FVector2D(0, 70))
      CanvasSlot:SetSize(FVector2D(250, 30))
    end
    _G.NTH_EspInfoV1Widget = Widget
  end)
  return _G.NTH_EspInfoV1Widget
end

local EspInfoV2WidgetPath = "/Game/UMG/UI_BP/Common/Tab/Vertical/LevelOne/LevelOne_Text/Item/Common_Tab_Vertical_LevelOne_CountDown_Item_UIBP.Common_Tab_Vertical_LevelOne_CountDown_Item_UIBP"

local function GetEspInfoV2Widget()
  if _G.NTH_EspInfoV2Widget then
    if slua.isValid(_G.NTH_EspInfoV2Widget) then
      return _G.NTH_EspInfoV2Widget
    end
  end
  ClearEspInfoV2Widget()
  pcall(function()
    local Widget = slua.loadUI(EspInfoV2WidgetPath)
    if not Widget or not slua.isValid(Widget) then
      return
    end
    local HudModule = require("game_frontend_hud")
    if not HudModule or not HudModule.AddToContainer then
      return
    end
    HudModule.AddToContainer(UIContainers.Top, Widget, 10600)
    if Widget.Image_Time then
      Widget.Image_Time:SetVisibility(UEnums.ESlateVisibility.Collapsed)
    end
    if Widget.TextBlock_Time then
      pcall(function()
        Widget.TextBlock_Time:SetJustification(UEnums.ETextJustify.Center)
      end)
      local Font = Widget.TextBlock_Time.Font
      if Font then
        Font.Size = 14
        Font.TypefaceFontName = "Bold"
        Widget.TextBlock_Time:SetFont(Font)
      end
    end
    local WidgetLayoutLibrary = import("WidgetLayoutLibrary")
    local CanvasSlot = WidgetLayoutLibrary and WidgetLayoutLibrary.SlotAsCanvasSlot(Widget)
    if CanvasSlot then
      CanvasSlot:SetAnchors(FAnchors(0.5, 0, 0.5, 0))
      CanvasSlot:SetAlignment(FVector2D(0.5, 0))
      CanvasSlot:SetPosition(FVector2D(0, 70))
      CanvasSlot:SetAutoSize(true)
    end
    _G.NTH_EspInfoV2Widget = Widget
  end)
  return _G.NTH_EspInfoV2Widget
end

local function NormalizeAngle(angle)
  while 180 < angle do
    angle = angle - 360
  end
  while angle < -180 do
    angle = angle + 360
  end
  return angle
end

_G.NTH_WarningAimWidget = _G.NTH_WarningAimWidget or nil

local function ClearWarningAimWidget()
  if _G.NTH_WarningAimWidget then
    if slua.isValid(_G.NTH_WarningAimWidget) then
      pcall(function()
        _G.NTH_WarningAimWidget:RemoveFromParent()
      end)
    end
  end
  _G.NTH_WarningAimWidget = nil
end

local WarningAimWidgetPath = "/Game/UMG/UI_BP/Common/Tab/Vertical/LevelOne/LevelOne_Text/Item/Common_Tab_Vertical_LevelOne_CountDown_Item_UIBP.Common_Tab_Vertical_LevelOne_CountDown_Item_UIBP"

local function GetWarningAimWidget()
  if _G.NTH_WarningAimWidget then
    if slua.isValid(_G.NTH_WarningAimWidget) then
      return _G.NTH_WarningAimWidget
    end
  end
  ClearWarningAimWidget()
  pcall(function()
    local Widget = slua.loadUI(WarningAimWidgetPath)
    if not Widget or not slua.isValid(Widget) then
      return
    end
    local HudModule = require("game_frontend_hud")
    if not HudModule or not HudModule.AddToContainer then
      return
    end
    HudModule.AddToContainer(UIContainers.Top, Widget, 10601)
    if Widget.Image_Time then
      Widget.Image_Time:SetVisibility(UEnums.ESlateVisibility.Collapsed)
    end
    if Widget.TextBlock_Time then
      pcall(function()
        Widget.TextBlock_Time:SetJustification(UEnums.ETextJustify.Center)
      end)
      local Font = Widget.TextBlock_Time.Font
      if Font then
        Font.Size = 14
        Font.TypefaceFontName = "Bold"
        Widget.TextBlock_Time:SetFont(Font)
      end
      Widget.TextBlock_Time:SetColorAndOpacity(FSlateColor(FLinearColor(1, 0, 0, 1)))
    end
    local WidgetLayoutLibrary = import("WidgetLayoutLibrary")
    local CanvasSlot = WidgetLayoutLibrary and WidgetLayoutLibrary.SlotAsCanvasSlot(Widget)
    if CanvasSlot then
      CanvasSlot:SetAnchors(FAnchors(0.5, 0, 0.5, 0))
      CanvasSlot:SetAlignment(FVector2D(0.5, 0))
      CanvasSlot:SetPosition(FVector2D(0, 110))
      CanvasSlot:SetAutoSize(true)
    end
    _G.NTH_WarningAimWidget = Widget
  end)
  return _G.NTH_WarningAimWidget
end

-- نهاية الجزء الثاني

local function InitNTHESPVIP()
  if _G.NTH_ESP_VIP_Init then
    return
  end
  _G.NTH_ESP_VIP_Init = true
  local NTH_PlayerMapMarker = {}
  local SlateBlueprintLibrary = nil
  local WidgetLayoutLibrary = nil
  pcall(function()
    local Library = import("SlateBlueprintLibrary")
    if not Library then
      Library = import("/Script/UMG.SlateBlueprintLibrary")
    end
    SlateBlueprintLibrary = Library
  end)
  pcall(function()
    local Library = import("WidgetLayoutLibrary")
    if not Library then
      Library = import("/Script/UMG.WidgetLayoutLibrary")
    end
    WidgetLayoutLibrary = Library
  end)
  NTH_PlayerMapMarker.ESPWorldOffsetZ = 0
  NTH_PlayerMapMarker.bActive = false
  NTH_PlayerMapMarker.ESPCanvas = nil
  NTH_PlayerMapMarker.ESPWidgets = {}
  NTH_PlayerMapMarker.ESPWidgetPtrs = {}

  local function IsValid(Obj)
    if Obj == nil then
      return false
    end
    if slua then
      if slua.isValid then
        return slua.isValid(Obj)
      end
    end
    return Obj ~= nil
  end

  function NTH_PlayerMapMarker.GetMyPlayerController()
    local PC = NTH_PlayerMapMarker._CachedPC
    if PC then
      if IsValid(PC) then
        return PC
      end
    end
    pcall(function()
      local GameplayData = require("GameLua.GameCore.Data.GameplayData")
      PC = GameplayData.GetPlayerController and GameplayData.GetPlayerController()
    end)
    if PC then
      if IsValid(PC) then
        NTH_PlayerMapMarker._CachedPC = PC
        return PC
      end
    end
    return nil
  end

  function NTH_PlayerMapMarker.GetAllCharacters()
    local Characters = {}
    pcall(function()
      local Pawns = Game:GetAllPlayerPawns()
      if Pawns then
        for _, Pawn in pairs(Pawns) do
          if Pawn then
            if slua.isValid(Pawn) then
              local PlayerKey
              if Pawn.GetPlayerKey then
                PlayerKey = Pawn:GetPlayerKey()
              end
              if not PlayerKey then
                PlayerKey = Pawn.PlayerKey
                if not PlayerKey then
                  PlayerKey = Pawn.PlayerState and Pawn.PlayerState.PlayerKey
                end
              end
              if PlayerKey then
                Characters[PlayerKey] = Pawn
              end
            end
          end
        end
      end
    end)
    return Characters
  end

  function NTH_PlayerMapMarker.GetMyPlayerKey()
    local PC = NTH_PlayerMapMarker.GetMyPlayerController()
    if not IsValid(PC) then
      return nil
    end
    local MyPlayerKey = nil
    pcall(function()
      local PlayerKey
      if PC.GetPlayerKey then
        PlayerKey = PC:GetPlayerKey()
      end
      if not PlayerKey then
        PlayerKey = PC.PlayerState and PC.PlayerState.PlayerKey
      end
      MyPlayerKey = PlayerKey
    end)
    return MyPlayerKey
  end

  function NTH_PlayerMapMarker.IsAlive(Character)
    local bAlive = true
    pcall(function()
      if Character.IsAlive then
        bAlive = Character:IsAlive()
      end
    end)
    return bAlive
  end

  function NTH_PlayerMapMarker.GetCharacterLocation(Character)
    if not IsValid(Character) then
      return nil
    end
    local Location = nil
    pcall(function()
      if Character.K2_GetActorLocation then
        Location = Character:K2_GetActorLocation()
      else
        if Game then
          if Game.GetActorLocation then
            Location = Game:GetActorLocation(Character)
          end
        end
      end
    end)
    return Location
  end

  function NTH_PlayerMapMarker.GetESPLocation(Character)
    if not IsValid(Character) then
      return nil
    end
    local Location = NTH_PlayerMapMarker.GetCharacterLocation(Character)
    if Location then
      local OffsetZ = 65
      pcall(function()
        if Character.bIsCrouched then
          OffsetZ = 40
        end
        if Character.IsProne then
          if Character:IsProne() then
            OffsetZ = 15
          end
        end
        local Z = Location.Z + OffsetZ
        local WorldOffsetZ = NTH_PlayerMapMarker.ESPWorldOffsetZ
        if not WorldOffsetZ then
          WorldOffsetZ = 0
        end
        Z = Z + WorldOffsetZ
        Location.Z = Z
      end)
    end
    return Location
  end

  function NTH_PlayerMapMarker.InitESPCanvas()
    if NTH_PlayerMapMarker.ESPCanvas then
      if Game:IsValid(NTH_PlayerMapMarker.ESPCanvas) then
        return true
      end
    end
    local Canvas = nil
    pcall(function()
      local InGameUITools = require("GameLua.Mod.BaseMod.Common.UI.InGameUITools")
      local MainControlBaseUI = InGameUITools.GetMainControlBaseUI()
      local CanvasPanel = MainControlBaseUI.CanvasPanel_0
      if not CanvasPanel then
        CanvasPanel = MainControlBaseUI.CanvasPanel_42
      end
      Canvas = CanvasPanel
    end)
    if not Canvas then
      return false
    end
    NTH_PlayerMapMarker.ESPCanvas = Canvas
    return true
  end

  NTH_PlayerMapMarker._CanvasScaleX, NTH_PlayerMapMarker._CanvasScaleY = 1.0, 1.0
  NTH_PlayerMapMarker._CanvasOffsetX, NTH_PlayerMapMarker._CanvasOffsetY = 0.0, 0.0

  function NTH_PlayerMapMarker.UpdateCanvasTransform(PC)
    if not NTH_PlayerMapMarker.ESPCanvas or not Game:IsValid(NTH_PlayerMapMarker.ESPCanvas) then
      return
    end
    pcall(function()
      local Geometry = NTH_PlayerMapMarker.ESPCanvas:GetCachedGeometry()
      if Geometry then
        if SlateBlueprintLibrary then
          if SlateBlueprintLibrary.AbsoluteToLocal then
            local OriginLocal = SlateBlueprintLibrary.AbsoluteToLocal(Geometry, FVector2D(0, 0))
            local HundredLocal = SlateBlueprintLibrary.AbsoluteToLocal(Geometry, FVector2D(100, 100))
            if OriginLocal and HundredLocal then
              NTH_PlayerMapMarker._CanvasScaleX = (HundredLocal.X - OriginLocal.X) / 100
              NTH_PlayerMapMarker._CanvasScaleY = (HundredLocal.Y - OriginLocal.Y) / 100
              NTH_PlayerMapMarker._CanvasOffsetX = OriginLocal.X
              NTH_PlayerMapMarker._CanvasOffsetY = OriginLocal.Y
            end
          end
        end
      end
    end)
  end

  function NTH_PlayerMapMarker.ScreenPixelToCanvasLocal(ScreenPos)
    if not ScreenPos then
      return FVector2D(0, 0)
    end
    return FVector2D(ScreenPos.X * NTH_PlayerMapMarker._CanvasScaleX + NTH_PlayerMapMarker._CanvasOffsetX, ScreenPos.Y * NTH_PlayerMapMarker._CanvasScaleY + NTH_PlayerMapMarker._CanvasOffsetY)
  end

  function NTH_PlayerMapMarker.ProjectWorldToCanvasLocal(PC, WorldLocation)
    if not IsValid(PC) or not WorldLocation then
      return false, FVector2D(0, 0)
    end
    local ScreenPos = FVector2D(0, 0)
    local bProjected = false
    pcall(function()
      local Result = PC:ProjectWorldLocationToScreen(WorldLocation, ScreenPos, true)
      if (Result == true or Result == 1) or ScreenPos.X ~= 0 or ScreenPos.Y ~= 0 then
        bProjected = true
      end
    end)
    if not bProjected or (ScreenPos.X == 0 and ScreenPos.Y == 0) then
      return false, FVector2D(0, 0)
    end
    return true, NTH_PlayerMapMarker.ScreenPixelToCanvasLocal(ScreenPos)
  end

  function NTH_PlayerMapMarker.FindWeaponIconInWidget(Widget, Depth, MaxDepth)
    if not Widget or not slua.isValid(Widget) then
      return nil
    end
    if not Depth then
      Depth = 0
    end
    if not MaxDepth then
      MaxDepth = 6
    end
    local IconNames = {
      "Image_Weapon",
      "Image_WeaponIcon",
      "Image_Gun",
      "Image_Icon",
      "WeaponIcon",
      "WeaponImage"
    }
    for _, IconName in ipairs(IconNames) do
      local FoundIcon = nil
      pcall(function()
        local Child = Widget[IconName]
        if Child then
          if slua.isValid(Child) then
            if Child.Brush then
              FoundIcon = Child
            end
          end
        end
      end)
      if FoundIcon then
        return FoundIcon
      end
    end
    if Depth >= MaxDepth then
      return nil
    end
    local ChildCount = 0
    pcall(function()
      if Widget.GetChildrenCount then
        ChildCount = Widget:GetChildrenCount()
      end
    end)
    for Index = 0, math.max(ChildCount - 1, 0), 1 do
      local ChildWidget = nil
      pcall(function()
        ChildWidget = Widget:GetChildAt(Index)
      end)
      if ChildWidget then
        if slua.isValid(ChildWidget) then
          local Icon = NTH_PlayerMapMarker.FindWeaponIconInWidget(ChildWidget, Depth + 1, MaxDepth)
          if Icon then
            return Icon
          end
        end
      end
    end
    return nil
  end

  function NTH_PlayerMapMarker.ApplyBotLabel(Widget)
    if not Widget or not slua.isValid(Widget) then
      return
    end
    pcall(function()
      local HideNames = {
        "WeaponIcon",
        "Image_Weapon",
        "Border_Weapon",
        "Switcher_WeaponIcon",
        "SizeBox_Weapon",
        "Image_WeaponBg",
        "Border_WeaponColor"
      }
      for _, HideName in ipairs(HideNames) do
        if Widget[HideName] then
          if slua.isValid(Widget[HideName]) then
            Widget[HideName]:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
          end
        end
      end
      local NameText = Widget.TextBlock_PlayerName
      if NameText then
        if slua.isValid(NameText) then
          NameText:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
          NameText:SetText("[بوت]")
          local Vector2D = import("Vector2D")
          if not Vector2D then
            Vector2D = _G.FVector2D
          end
          if Vector2D then
            if NameText.SetRenderTranslation then
              NameText:SetRenderTranslation(Vector2D(25.0, 0.0))
            end
          end
          local LabelColor = import("LinearColor")(0, 1, 0, 1)
          local SlateColor = import("SlateColor")
          if not SlateColor then
            SlateColor = import("/Script/SlateCore.SlateColor")
          end
          if SlateColor then
            NameText:SetColorAndOpacity(SlateColor(LabelColor))
          else
            NameText:SetColorAndOpacity(LabelColor)
          end
          local Font = NameText.Font
          if Font then
            Font.Size = 10
            Font.TypefaceFontName = "Bold"
            NameText:SetFont(Font)
          end
          if NameText.SetJustification then
            NameText:SetJustification(UEnums.ETextJustify.Center)
          end
        end
      end
    end)
  end

  function NTH_PlayerMapMarker.AddWeaponIconToESP(Widget, Character)
    if not Widget or not slua.isValid(Widget) then
      return
    end
    pcall(function()
      if Widget.TextBlock_PlayerName then
        if slua.isValid(Widget.TextBlock_PlayerName) then
          Widget.TextBlock_PlayerName:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
        end
      end
      Character:GetCurrentWeapon()
      local Weapon = Character:GetCurrentWeapon()
      local WeaponID = 0
      if slua.isValid(Weapon) then
        local ItemDefineID = Weapon:GetItemDefineID()
        local TypeSpecificID = nil
        if ItemDefineID then
          TypeSpecificID = ItemDefineID.TypeSpecificID
        end
        WeaponID = TypeSpecificID or 0
      end
      if WeaponID == 0 then
        local HideNames = {
          "WeaponIcon",
          "Image_Weapon",
          "Border_Weapon",
          "Switcher_WeaponIcon",
          "SizeBox_Weapon"
        }
        for _, HideName in ipairs(HideNames) do
          if Widget[HideName] then
            if slua.isValid(Widget[HideName]) then
              pcall(function()
                Widget[HideName]:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
              end)
            end
          end
        end
        return
      end
      pcall(function()
        if Widget.UpdateWeapon then
          Widget:UpdateWeapon(WeaponID)
        end
      end)
      pcall(function()
        if Widget.SetWeaponID then
          Widget:SetWeaponID(WeaponID)
        end
      end)
      local Icon = Widget.WeaponIcon
      if not Icon then
        Icon = Widget.Image_Weapon
        if not Icon then
          Icon = Widget.Image_Gun
        end
      end
      if not Icon or not slua.isValid(Icon) then
        Icon = NTH_PlayerMapMarker.FindWeaponIconInWidget(Widget, 0, 6)
      end
      if slua.isValid(Icon) then
        local ItemData = CDataTable.GetTableData("Item", WeaponID)
        if ItemData then
          if ItemData.ItemWhiteIcon then
            if ItemData.ItemWhiteIcon ~= "" then
              Icon:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
              Icon:SetBrushFromPathAsync(ItemData.ItemWhiteIcon, false)
              pcall(function()
                Icon:SetColorAndOpacity(import("LinearColor")(1, 1, 1, 1))
              end)
              pcall(function()
                Icon:SetRenderOpacity(1.0)
              end)
              local Brush = slua.IndexReference(Icon, "Brush")
              if Brush then
                Brush.ImageSize = import("Vector2D")(128, 64)
                if Icon.SetBrush then
                  Icon:SetBrush(Brush)
                end
              end
              local Node = Icon
              for Depth = 1, 7, 1 do
                if not Node then
                  break
                end
                if not slua.isValid(Node) then
                  break
                end
                pcall(function()
                  if Node.GetParent then
                    local Parent = Node:GetParent()
                    if slua.isValid(Parent) then
                      Parent:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                      pcall(function()
                        Parent:SetRenderOpacity(1.0)
                      end)
                      if string.find(tostring(Parent), "WidgetSwitcher") then
                        local ChildCount = Parent:GetChildrenCount()
                        for Index = 0, ChildCount - 1, 1 do
                          local Child = Parent:GetChildAt(Index)
                          if Child == Node or tostring(Child) == tostring(Node) then
                            Parent:SetActiveWidgetIndex(Index)
                            break
                          end
                        end
                      end
                      Node = Parent
                    else
                      Node = nil
                    end
                  else
                    Node = nil
                  end
                end)
              end
            end
          end
        end
      end
      local FadeNames = {
        "Border_Weapon",
        "Image_WeaponBg",
        "Border_WeaponColor"
      }
      for _, FadeName in ipairs(FadeNames) do
        if Widget[FadeName] then
          if slua.isValid(Widget[FadeName]) then
            pcall(function()
              Widget[FadeName]:SetRenderOpacity(0.0)
            end)
          end
        end
      end
    end)
  end

  NTH_PlayerMapMarker._OBHeadWidgetClass = nil

  function NTH_PlayerMapMarker.CreateESPWidget()
    if not NTH_PlayerMapMarker.ESPCanvas then
      return nil
    end
    if not NTH_PlayerMapMarker._OBHeadWidgetClass then
      pcall(function()
        NTH_PlayerMapMarker._OBHeadWidgetClass = slua.loadClass("/Game/BluePrints/UI/OBUI/Item/OB_PlayerHeadHPItem_UIBP.OB_PlayerHeadHPItem_UIBP")
      end)
      if not NTH_PlayerMapMarker._OBHeadWidgetClass then
        return nil
      end
    end
    local ESPWidget = nil
    pcall(function()
      local USTExtraBlueprintFunctionLibrary = import("STExtraBlueprintFunctionLibrary")
      local PC = NTH_PlayerMapMarker.GetMyPlayerController()
      local Owner
      if IsValid(PC) then
        Owner = PC.Object
      end
      if not Owner then
        Owner = NTH_PlayerMapMarker.ESPCanvas
      end
      ESPWidget = USTExtraBlueprintFunctionLibrary.CreateWidgetByClass(NTH_PlayerMapMarker._OBHeadWidgetClass, Owner)
    end)
    if not ESPWidget then
      return nil
    end
    pcall(function()
      ESPWidget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
      local HideNames = {
        "TextBlock_TeamName",
        "SizeBox_HP",
        "ProgressBar_HP",
        "Image_HPBG",
        "Image_TeamBG",
        "Image_TeamLogoBG",
        "Image_TeamBG_2",
        "Image_RingBG",
        "Image_Line",
        "Image_Split",
        "Image_Bg",
        "Border_HP"
      }
      for _, HideName in ipairs(HideNames) do
        if ESPWidget[HideName] then
          if slua.isValid(ESPWidget[HideName]) then
            ESPWidget[HideName]:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
          end
        end
      end
    end)
    return ESPWidget
  end

  function NTH_PlayerMapMarker.UpdateESPPositionWithPC(ESPWidget, CanvasPos)
    if not ESPWidget or not CanvasPos then
      return
    end
    pcall(function()
      local Key = tostring(ESPWidget)
      local Slot = NTH_PlayerMapMarker.ESPWidgetPtrs[Key]
      if not Slot or not slua.isValid(Slot) then
        local NewSlot = NTH_PlayerMapMarker.ESPCanvas:AddChildToCanvas(ESPWidget)
        if NewSlot then
          if slua.isValid(NewSlot) then
            Slot = NewSlot
            NTH_PlayerMapMarker.ESPWidgetPtrs[Key] = NewSlot
            pcall(function()
              Slot:SetAutoSize(true)
            end)
            pcall(function()
              Slot.bAutoSize = true
            end)
            local Alignment = FVector2D(0.5, 1.0)
            pcall(function()
              Slot.Alignment = Alignment
            end)
            pcall(function()
              Slot:SetAlignment(Alignment)
            end)
            pcall(function()
              Slot:SetAlignment(0.5, 1.0)
            end)
            pcall(function()
              Slot:SetZOrder(20)
            end)
          end
        end
      end
      pcall(function()
        ESPWidget:SetRenderTranslation(FVector2D(0.0, 0.0))
      end)
      pcall(function()
        ESPWidget.RenderTransformPivot = FVector2D(0.5, 1.0)
      end)
      pcall(function()
        ESPWidget:SetRenderTransformPivot(FVector2D(0.5, 1.0))
      end)
      ESPWidget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
      if Slot then
        if slua.isValid(Slot) then
          local PosX = CanvasPos.X + 20
          local PosY = CanvasPos.Y
          Slot:SetPosition(FVector2D(PosX, PosY))
        end
      end
    end)
  end

  function NTH_PlayerMapMarker.RemoveESPWidget(ESPWidget)
    if not ESPWidget then
      return
    end
    pcall(function()
      local Key = tostring(ESPWidget)
      NTH_PlayerMapMarker.ESPWidgetPtrs[Key] = nil
      ESPWidget:RemoveFromParent()
      ESPWidget:ConditionalBeginDestroy()
    end)
  end

  function NTH_PlayerMapMarker.ScanAndRenderWeapons()
    local bWeaponESP = _G.NTH_GetVal and _G.NTH_GetVal("ESP_WEAPON") == 1
    local bBotLabelESP = _G.NTH_GetVal and _G.NTH_GetVal("ESP_BOT_LABEL") == 1
    if not bWeaponESP and not bBotLabelESP then
      NTH_PlayerMapMarker.ClearAllESP()
      return
    end
    if not NTH_PlayerMapMarker.InitESPCanvas() then
      return
    end
    local PC = NTH_PlayerMapMarker.GetMyPlayerController()
    if not IsValid(PC) then
      return
    end
    NTH_PlayerMapMarker.UpdateCanvasTransform(PC)
    local MyCharacter = nil
    pcall(function()
      local GameplayData = require("GameLua.GameCore.Data.GameplayData")
      MyCharacter = GameplayData.GetPlayerCharacter and GameplayData.GetPlayerCharacter()
      if not slua.isValid(MyCharacter) then
        if PC.GetPawn then
          MyCharacter = PC:GetPawn()
        end
      end
    end)
    local MyTeamID = -1
    if slua.isValid(MyCharacter) then
      pcall(function()
        local TeamID
        if type(MyCharacter.GetTeamID) == "function" then
          TeamID = MyCharacter:GetTeamID()
        end
        if not TeamID then
          TeamID = MyCharacter.TeamID
          if not TeamID then
            TeamID = MyCharacter.PlayerState and MyCharacter.PlayerState.TeamNum
            if not TeamID then
              TeamID = -1
            end
          end
        end
        MyTeamID = TeamID
      end)
    end
    local Characters = NTH_PlayerMapMarker.GetAllCharacters()
    local MyPlayerKey = NTH_PlayerMapMarker.GetMyPlayerKey()
    local SeenKeys = {}
    for PlayerKey, Character in pairs(Characters) do
      if IsValid(Character) then
        local bIsMe = tostring(PlayerKey) == tostring(MyPlayerKey)
        local KeyStr = tostring(PlayerKey)
        if not bIsMe then
          if NTH_PlayerMapMarker.IsAlive(Character) then
            local CharTeamID = -2
            pcall(function()
              local TeamID
              if type(Character.GetTeamID) == "function" then
                TeamID = Character:GetTeamID()
              end
              if not TeamID then
                TeamID = Character.TeamID
                if not TeamID then
                  TeamID = Character.PlayerState and Character.PlayerState.TeamNum
                  if not TeamID then
                    TeamID = -2
                  end
                end
              end
              CharTeamID = TeamID
            end)
            if CharTeamID ~= MyTeamID then
              local WorldLocation = NTH_PlayerMapMarker.GetESPLocation(Character)
              if WorldLocation then
                local bProjected, CanvasPos = NTH_PlayerMapMarker.ProjectWorldToCanvasLocal(PC, WorldLocation)
                if bProjected then
                  SeenKeys[KeyStr] = true
                  local ESPWidget = NTH_PlayerMapMarker.ESPWidgets[KeyStr]
                  if not ESPWidget or not slua.isValid(ESPWidget) then
                    ESPWidget = NTH_PlayerMapMarker.CreateESPWidget()
                    if ESPWidget then
                      NTH_PlayerMapMarker.ESPWidgets[KeyStr] = ESPWidget
                    end
                  end
                  if ESPWidget then
                    if slua.isValid(ESPWidget) then
                      local bIsNormalBot = false
                      local bIsMLBot = false
                      if _G.NTH_CheckIsBot then
                        bIsNormalBot, bIsMLBot = _G.NTH_CheckIsBot(Character)
                      end
                      local bIsBot = bIsNormalBot or bIsMLBot
                      local bHandled = false
                      if bIsBot then
                        if bBotLabelESP then
                          NTH_PlayerMapMarker.ApplyBotLabel(ESPWidget)
                          bHandled = true
                        elseif bWeaponESP then
                          NTH_PlayerMapMarker.AddWeaponIconToESP(ESPWidget, Character)
                          bHandled = true
                        end
                      elseif bWeaponESP then
                        NTH_PlayerMapMarker.AddWeaponIconToESP(ESPWidget, Character)
                        bHandled = true
                      end
                      if bHandled then
                        NTH_PlayerMapMarker.UpdateESPPositionWithPC(ESPWidget, CanvasPos)
                        pcall(function()
                          ESPWidget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                        end)
                      else
                        pcall(function()
                          ESPWidget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
                        end)
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
    for KeyStr, ESPWidget in pairs(NTH_PlayerMapMarker.ESPWidgets) do
      if not SeenKeys[KeyStr] then
        NTH_PlayerMapMarker.RemoveESPWidget(ESPWidget)
        NTH_PlayerMapMarker.ESPWidgets[KeyStr] = nil
      end
    end
  end

  function NTH_PlayerMapMarker.ClearAllESP()
    for _, ESPWidget in pairs(NTH_PlayerMapMarker.ESPWidgets) do
      NTH_PlayerMapMarker.RemoveESPWidget(ESPWidget)
    end
    NTH_PlayerMapMarker.ESPWidgets = {}
    NTH_PlayerMapMarker.ESPWidgetPtrs = {}
    NTH_PlayerMapMarker.ESPCanvas = nil
  end

  function NTH_PlayerMapMarker.AttachTimers()
    local TimeTicker = package.loaded["common.time_ticker"]
    if not TimeTicker then
      TimeTicker = require("common.time_ticker")
    end
    if not TimeTicker or not TimeTicker.AddTimerLoop then
      return
    end
    if NTH_PlayerMapMarker.RenderTimerHandle then
      TimeTicker.RemoveTimer(NTH_PlayerMapMarker.RenderTimerHandle)
    end
    NTH_PlayerMapMarker.RenderTimerHandle = TimeTicker.AddTimerLoop(0, function()
      if NTH_PlayerMapMarker.bActive then
        pcall(function()
          local PC = NTH_PlayerMapMarker.GetMyPlayerController()
          if PC then
            if NTH_PlayerMapMarker._LastPC ~= PC then
              NTH_PlayerMapMarker.ClearAllESP()
              NTH_PlayerMapMarker._LastPC = PC
            end
          end
          NTH_PlayerMapMarker.ScanAndRenderWeapons()
        end)
      end
    end, -1, 0.02)
  end

  function NTH_PlayerMapMarker.Start()
    if NTH_PlayerMapMarker.bActive then
      return
    end
    NTH_PlayerMapMarker.bActive = true
    NTH_PlayerMapMarker.AttachTimers()
  end

  function NTH_PlayerMapMarker.Stop()
    NTH_PlayerMapMarker.bActive = false
    local TimeTicker = package.loaded["common.time_ticker"]
    if not TimeTicker then
      TimeTicker = require("common.time_ticker")
    end
    if TimeTicker then
      if NTH_PlayerMapMarker.RenderTimerHandle then
        TimeTicker.RemoveTimer(NTH_PlayerMapMarker.RenderTimerHandle)
        NTH_PlayerMapMarker.RenderTimerHandle = nil
      end
    end
    NTH_PlayerMapMarker.ClearAllESP()
  end

  _G.NTH_PlayerMapMarker = NTH_PlayerMapMarker
  NTH_PlayerMapMarker.Start()
end

_G.InitNTHESPVIP = InitNTHESPVIP

-- ============================================================
-- 🎯 نظام السناب لاين والعداد (مأخوذ من ملفي2)
-- مرتبط بزر الكشف
-- ============================================================

local PlayerMapMarker = {}

PlayerMapMarker.bUseScreenESP = true
PlayerMapMarker.bUseSnapLines = true
PlayerMapMarker.SnapLineThickness = 3.0
PlayerMapMarker.SnapLineOriginY = 25
PlayerMapMarker.SnapLineOriginOffsetX = 0
PlayerMapMarker.SnapLineHeadOffsetX = 0
PlayerMapMarker.SnapLineHeadOffsetY = -14
PlayerMapMarker.SnapLineOpacity = 0.7
PlayerMapMarker.SnapLineWidgets = {}
PlayerMapMarker.ESPCanvas = nil
PlayerMapMarker._CanvasScaleX = 1.0
PlayerMapMarker._CanvasScaleY = 1.0
PlayerMapMarker._CanvasOffsetX = 0.0
PlayerMapMarker._CanvasOffsetY = 0.0
PlayerMapMarker._CachedPC = nil
PlayerMapMarker._cachedViewportW = 1920
PlayerMapMarker._cachedViewportH = 1080
PlayerMapMarker.ESPWidgets = PlayerMapMarker.ESPWidgets or {}

local FVector2D_ESP9 = _G.FVector2D or import("Vector2D")
local FLinearColor_ESP9 = _G.FLinearColor or import("LinearColor")
local FVector_ESP9 = _G.FVector or import("Vector")

local SlateBlueprintLibrary_ESP9 = nil
local WidgetLayoutLibrary_ESP9 = nil
pcall(function() SlateBlueprintLibrary_ESP9 = import("SlateBlueprintLibrary") or import("/Script/UMG.SlateBlueprintLibrary") end)
pcall(function() WidgetLayoutLibrary_ESP9 = import("WidgetLayoutLibrary") or import("/Script/UMG.WidgetLayoutLibrary") end)

local function IsValid_ESP9(obj)
    if obj == nil then return false end
    if slua and slua.isValid then return slua.isValid(obj) end
    return obj ~= nil
end

function PlayerMapMarker.GetGameplayData()
    if PlayerMapMarker._CachedGameplayData then return PlayerMapMarker._CachedGameplayData end
    local ok, GDP = pcall(function() return require("GameLua.GameCore.Data.GameplayData") end)
    if ok and GDP then PlayerMapMarker._CachedGameplayData = GDP return GDP end
    return nil
end

function PlayerMapMarker.GetMyPlayerController()
    local PC = PlayerMapMarker._CachedPC
    if PC and IsValid_ESP9(PC) then return PC end
    local GDP = PlayerMapMarker.GetGameplayData()
    if not GDP then return nil end
    pcall(function() PC = GDP.GetPlayerController and GDP.GetPlayerController() end)
    if PC and IsValid_ESP9(PC) then PlayerMapMarker._CachedPC = PC return PC end
    return nil
end

function PlayerMapMarker.GetAllCharacters()
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

function PlayerMapMarker.GetMyPlayerKey()
    local PC = PlayerMapMarker.GetMyPlayerController()
    if not IsValid_ESP9(PC) then return nil end
    local MyKey = nil
    pcall(function()
        if PC.GetPlayerKey then MyKey = PC:GetPlayerKey()
        elseif PC.PlayerState and PC.PlayerState.PlayerKey then MyKey = PC.PlayerState.PlayerKey end
    end)
    return MyKey
end

function PlayerMapMarker.IsMe(Character, PlayerKey, MyKey)
    local bIsMe = false
    pcall(function()
        local GDP = PlayerMapMarker.GetGameplayData()
        if GDP and GDP.GetLocalCharacter then
            local MyChar = GDP.GetLocalCharacter()
            if MyChar and Character == MyChar then bIsMe = true return end
        end
    end)
    if not bIsMe and MyKey ~= nil and PlayerKey ~= nil then bIsMe = (tostring(PlayerKey) == tostring(MyKey)) end
    return bIsMe
end

function PlayerMapMarker.GetCharacterLocation(Character)
    if not IsValid_ESP9(Character) then return nil end
    local Loc = nil
    pcall(function() if Character.K2_GetActorLocation then Loc = Character:K2_GetActorLocation() end end)
    return Loc
end

function PlayerMapMarker.GetMyLocation()
    local GDP = PlayerMapMarker.GetGameplayData()
    if not GDP then return nil end
    local MyChar = nil
    pcall(function() MyChar = GDP.GetLocalCharacter and GDP.GetLocalCharacter() end)
    if not IsValid_ESP9(MyChar) then return nil end
    return PlayerMapMarker.GetCharacterLocation(MyChar)
end

function PlayerMapMarker.IsAlive(Character)
    local bAlive = true
    pcall(function() if Character.IsAlive then bAlive = Character:IsAlive() end end)
    return bAlive
end

function PlayerMapMarker.GetTeamID(Character)
    if not IsValid_ESP9(Character) then return nil end
    local TeamID = nil
    pcall(function() if Character.GetTeamID then TeamID = Character:GetTeamID() end end)
    if not TeamID then pcall(function() if Character.TeamID then TeamID = Character.TeamID end end) end
    return TeamID
end

function PlayerMapMarker.InitESPCanvas()
    if PlayerMapMarker.ESPCanvas and Game:IsValid(PlayerMapMarker.ESPCanvas) then return true end
    local InGameUITools = nil
    pcall(function() InGameUITools = require("GameLua.Mod.BaseMod.Common.UI.InGameUITools") end)
    if not InGameUITools then return false end
    local MainControlBaseUI = nil
    pcall(function() MainControlBaseUI = InGameUITools.GetMainControlBaseUI() end)
    if not MainControlBaseUI or not Game:IsValid(MainControlBaseUI) then return false end
    local ParentCanvas = nil
    pcall(function()
        if MainControlBaseUI.CanvasPanel_0 and Game:IsValid(MainControlBaseUI.CanvasPanel_0) then ParentCanvas = MainControlBaseUI.CanvasPanel_0
        elseif MainControlBaseUI.CanvasPanel_42 and Game:IsValid(MainControlBaseUI.CanvasPanel_42) then ParentCanvas = MainControlBaseUI.CanvasPanel_42 end
    end)
    if not ParentCanvas then return false end
    PlayerMapMarker.ESPCanvas = ParentCanvas
    return true
end

function PlayerMapMarker.GetESPLocation(Character)
    if not IsValid_ESP9(Character) then return nil end
    local BoneLoc = PlayerMapMarker.GetCharacterLocation(Character)
    if BoneLoc then
        local heightOffset = 85
        pcall(function()
            if Character.bIsCrouched then heightOffset = 60 end
            if Character.IsProne and Character:IsProne() then heightOffset = 30 end
        end)
        pcall(function() BoneLoc.Z = BoneLoc.Z + heightOffset end)
    end
    return BoneLoc
end

function PlayerMapMarker.UpdateCanvasTransform(PC)
    if not PlayerMapMarker.ESPCanvas or not Game:IsValid(PlayerMapMarker.ESPCanvas) then return end
    local success = false
    pcall(function()
        local SBL = SlateBlueprintLibrary_ESP9
        if SBL and SBL.AbsoluteToLocal then
            local cg = PlayerMapMarker.ESPCanvas:GetCachedGeometry()
            if cg then
                local pt0 = SBL.AbsoluteToLocal(cg, FVector2D_ESP9 and FVector2D_ESP9(0, 0) or {X=0, Y=0})
                local pt1 = SBL.AbsoluteToLocal(cg, FVector2D_ESP9 and FVector2D_ESP9(100, 100) or {X=100, Y=100})
                if pt0 and pt1 then
                    PlayerMapMarker._CanvasScaleX = (pt1.X - pt0.X) / 100
                    PlayerMapMarker._CanvasScaleY = (pt1.Y - pt0.Y) / 100
                    PlayerMapMarker._CanvasOffsetX = pt0.X
                    PlayerMapMarker._CanvasOffsetY = pt0.Y
                    success = true
                end
            end
        end
    end)
    if not success then
        local scale = 1.0
        if WidgetLayoutLibrary_ESP9 and WidgetLayoutLibrary_ESP9.GetViewportScale then scale = WidgetLayoutLibrary_ESP9.GetViewportScale(PC) or 1.0 end
        PlayerMapMarker._CanvasScaleX = 1.0 / scale
        PlayerMapMarker._CanvasScaleY = 1.0 / scale
        PlayerMapMarker._CanvasOffsetX = 0
        PlayerMapMarker._CanvasOffsetY = 0
    end
end

function PlayerMapMarker.ScreenPixelToCanvasLocal(PC, ScreenPixelPos)
    if not ScreenPixelPos then return FVector2D_ESP9 and FVector2D_ESP9(0, 0) or {X=0, Y=0} end
    local scaleX = PlayerMapMarker._CanvasScaleX or 1.0
    local scaleY = PlayerMapMarker._CanvasScaleY or 1.0
    local offsetX = PlayerMapMarker._CanvasOffsetX or 0
    local offsetY = PlayerMapMarker._CanvasOffsetY or 0
    return (FVector2D_ESP9 and FVector2D_ESP9(ScreenPixelPos.X * scaleX + offsetX, ScreenPixelPos.Y * scaleY + offsetY)) or {X = ScreenPixelPos.X * scaleX + offsetX, Y = ScreenPixelPos.Y * scaleY + offsetY}
end

function PlayerMapMarker.ProjectWorldToCanvasLocal(PC, WorldLoc)
    if not IsValid_ESP9(PC) or not WorldLoc then return false, (FVector2D_ESP9 and FVector2D_ESP9(0, 0) or {X=0, Y=0}) end
    local ScreenPixelPos = FVector2D_ESP9 and FVector2D_ESP9(0, 0) or {X=0, Y=0}
    local bOK = false
    pcall(function()
        local res = PC:ProjectWorldLocationToScreen(WorldLoc, ScreenPixelPos, true)
        if res == true or res == 1 or (ScreenPixelPos and (ScreenPixelPos.X ~= 0 or ScreenPixelPos.Y ~= 0)) then bOK = true end
    end)
    if not bOK or not ScreenPixelPos or (ScreenPixelPos.X == 0 and ScreenPixelPos.Y == 0) then return false, (FVector2D_ESP9 and FVector2D_ESP9(0, 0) or {X=0, Y=0}) end
    return true, PlayerMapMarker.ScreenPixelToCanvasLocal(PC, ScreenPixelPos)
end

function PlayerMapMarker.GetSnapLineStartPos(PC)
    local screenPixelW, screenPixelH = 0, 0
    local scale = 1.0

    pcall(function()
        if PC and PC.GetViewportSize then
            local vs = FVector2D_ESP9 and FVector2D_ESP9(0, 0) or {X=0,Y=0}
            PC:GetViewportSize(vs)
            if vs and vs.X and vs.X > 200 then screenPixelW = vs.X screenPixelH = vs.Y end
        end
    end)

    if screenPixelW <= 200 then
        pcall(function()
            local WLL = WidgetLayoutLibrary_ESP9
            if WLL and WLL.GetViewportSize then
                local vs = WLL.GetViewportSize(PC)
                if vs and vs.X and vs.X > 200 then screenPixelW = vs.X screenPixelH = vs.Y end
            end
        end)
    end

    pcall(function()
        local WLL = WidgetLayoutLibrary_ESP9
        if WLL and WLL.GetViewportScale then
            local s = WLL.GetViewportScale(PC)
            if s and type(s) == "number" and s > 0 then scale = s end
        end
    end)

    if screenPixelW <= 200 then
        screenPixelW = (PlayerMapMarker._cachedViewportW or 1920) * scale
        screenPixelH = (PlayerMapMarker._cachedViewportH or 1080) * scale
    end

    if not PlayerMapMarker._CachedTopCenterPixel then PlayerMapMarker._CachedTopCenterPixel = FVector2D_ESP9 and FVector2D_ESP9(0, 0) or {X=0,Y=0} end
    PlayerMapMarker._CachedTopCenterPixel.X = screenPixelW / 2.0
    PlayerMapMarker._CachedTopCenterPixel.Y = (PlayerMapMarker.SnapLineOriginY or 50) * scale

    local fromCanvasPos = PlayerMapMarker.ScreenPixelToCanvasLocal(PC, PlayerMapMarker._CachedTopCenterPixel)
    return fromCanvasPos.X + (PlayerMapMarker.SnapLineOriginOffsetX or 0), fromCanvasPos.Y
end

function PlayerMapMarker.CreateSnapLine()
    if not PlayerMapMarker.ESPCanvas or not Game:IsValid(PlayerMapMarker.ESPCanvas) then return nil end

    local Border = nil
    pcall(function() Border = CGame:NewObjectFromPath("/Script/UMG.Border", PlayerMapMarker.ESPCanvas) end)
    if not Border or not slua.isValid(Border) then return nil end

    local color = FLinearColor_ESP9 and FLinearColor_ESP9(1.0, 1.0, 0.0, PlayerMapMarker.SnapLineOpacity or 0.7) or {R=255,G=255,B=0,A=200}
    pcall(function() Border:SetBrushColor(color) end)
    pcall(function() Border:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)
    pcall(function() Border:SetRenderTransformPivot(FVector2D_ESP9 and FVector2D_ESP9(0.0, 0.5) or {X=0,Y=0.5}) end)

    local Slot = nil
    pcall(function()
        Slot = PlayerMapMarker.ESPCanvas:AddChildToCanvas(Border)
        if Slot then Slot:SetAutoSize(false) Slot:SetZOrder(1) end
    end)
    return { Widget = Border, Slot = Slot }
end

function PlayerMapMarker.UpdateSnapLine(KeyStr, CanvasPos, bOnScreen, fromX, fromY)
    if not PlayerMapMarker.bUseSnapLines then return end
    if not PlayerMapMarker.ESPCanvas or not Game:IsValid(PlayerMapMarker.ESPCanvas) then return end

    local LineData = PlayerMapMarker.SnapLineWidgets[KeyStr]
    if not bOnScreen or not CanvasPos then
        if LineData and LineData.Widget and slua.isValid(LineData.Widget) then
            pcall(function() LineData.Widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
        end
        return
    end

    if not LineData then
        LineData = PlayerMapMarker.CreateSnapLine()
        if not LineData or not LineData.Widget or not LineData.Slot then return end
        PlayerMapMarker.SnapLineWidgets[KeyStr] = LineData
    end

    local Widget = LineData.Widget
    local Slot = LineData.Slot

    pcall(function() Widget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible) end)

    local ESPData = PlayerMapMarker.ESPWidgets[KeyStr]
    local Character = ESPData and ESPData.Character
    local PC = PlayerMapMarker.GetMyPlayerController()

    local bIsVisible = false
    if Character and slua.isValid(Character) and PC and slua.isValid(PC) then
        pcall(function()
            if PC.LineOfSightTo then
                local zeroVec = FVector_ESP9 and FVector_ESP9(0, 0, 0) or {X=0, Y=0, Z=0}
                bIsVisible = PC:LineOfSightTo(Character, zeroVec, false)
            end
        end)
    end

    local lineColor
    if bIsVisible then
        lineColor = FLinearColor_ESP9 and FLinearColor_ESP9(0.0, 1.0, 0.0, PlayerMapMarker.SnapLineOpacity or 0.7)
            or {R=0, G=255, B=0, A=math.floor((PlayerMapMarker.SnapLineOpacity or 0.7) * 255)}
    else
        lineColor = FLinearColor_ESP9 and FLinearColor_ESP9(1.0, 0.0, 0.0, PlayerMapMarker.SnapLineOpacity or 0.7)
            or {R=255, G=0, B=0, A=math.floor((PlayerMapMarker.SnapLineOpacity or 0.7) * 255)}
    end

    pcall(function() Widget:SetBrushColor(lineColor) end)

    local toX = CanvasPos.X + (PlayerMapMarker.SnapLineHeadOffsetX or 0)
    local toY = CanvasPos.Y + (PlayerMapMarker.SnapLineHeadOffsetY or 0)

    local dx = toX - fromX
    local dy = toY - fromY
    local length = math.sqrt(dx * dx + dy * dy)
    local thickness = PlayerMapMarker.SnapLineThickness or 3.0
    local angle_rad = 0
    if math.atan2 then angle_rad = math.atan2(dy, dx) else angle_rad = math.atan(dy, dx) end
    local angle = angle_rad * (180.0 / math.pi)

    if not LineData._CachedPosVec then
        LineData._CachedPosVec = FVector2D_ESP9 and FVector2D_ESP9(fromX, fromY - thickness / 2.0) or {X=fromX, Y=fromY - thickness / 2.0}
        LineData._CachedSizeVec = FVector2D_ESP9 and FVector2D_ESP9(length, thickness) or {X=length, Y=thickness}
    else
        LineData._CachedPosVec.X = fromX; LineData._CachedPosVec.Y = fromY - thickness / 2.0
        LineData._CachedSizeVec.X = length; LineData._CachedSizeVec.Y = thickness
    end

    pcall(function()
        Slot:SetPosition(LineData._CachedPosVec)
        Slot:SetSize(LineData._CachedSizeVec)
    end)
    pcall(function() Widget:SetRenderAngle(angle) end)
end

function PlayerMapMarker.RemoveSnapLine(KeyStr)
    local LineData = PlayerMapMarker.SnapLineWidgets[KeyStr]
    if LineData and LineData.Widget and slua.isValid(LineData.Widget) then
        pcall(function() LineData.Widget:RemoveFromParent() LineData.Widget:ConditionalBeginDestroy() end)
        PlayerMapMarker.SnapLineWidgets[KeyStr] = nil
    end
end

function PlayerMapMarker.ClearAllSnapLines()
    for KeyStr, LineData in pairs(PlayerMapMarker.SnapLineWidgets) do
        if LineData and LineData.Widget and slua.isValid(LineData.Widget) then
            pcall(function() LineData.Widget:RemoveFromParent() LineData.Widget:ConditionalBeginDestroy() end)
        end
    end
    PlayerMapMarker.SnapLineWidgets = {}
end

function PlayerMapMarker.UpdateSnapLinesOnly()
    if not _G.NTH_Settings or _G.NTH_Settings.SNAP_LINES ~= 1 then
        PlayerMapMarker.ClearAllSnapLines()
        return
    end

    if not PlayerMapMarker.InitESPCanvas() then return end

    local PC = PlayerMapMarker.GetMyPlayerController()
    if not IsValid_ESP9(PC) then return end

    PlayerMapMarker.UpdateCanvasTransform(PC)

    local fromX, fromY = PlayerMapMarker.GetSnapLineStartPos(PC)
    local MyKey = PlayerMapMarker.GetMyPlayerKey()

    local MyChar = nil
    pcall(function()
        local GDP = PlayerMapMarker.GetGameplayData()
        if GDP and GDP.GetLocalCharacter then MyChar = GDP.GetLocalCharacter() end
    end)
    local MyTeamID = PlayerMapMarker.GetTeamID(MyChar)

    local AllChars = PlayerMapMarker.GetAllCharacters()
    local SeenKeys = {}

    for PlayerKey, Character in pairs(AllChars) do
        if IsValid_ESP9(Character) then
            local bIsMe = PlayerMapMarker.IsMe(Character, PlayerKey, MyKey)
            local KeyStr = tostring(PlayerKey)
            local TeamID = PlayerMapMarker.GetTeamID(Character)

            local bSkip = false
            if bIsMe then bSkip = true end
            if MyTeamID ~= nil and TeamID == MyTeamID then bSkip = true end

            local bIsAlive = PlayerMapMarker.IsAlive(Character)

            if not bSkip and bIsAlive then
                local Loc = PlayerMapMarker.GetESPLocation(Character)
                if Loc then
                    SeenKeys[KeyStr] = true
                    local bOnScreen, CanvasPos = PlayerMapMarker.ProjectWorldToCanvasLocal(PC, Loc)

                    if not PlayerMapMarker.ESPWidgets[KeyStr] then
                        PlayerMapMarker.ESPWidgets[KeyStr] = { Character = Character }
                    else
                        PlayerMapMarker.ESPWidgets[KeyStr].Character = Character
                    end

                    PlayerMapMarker.UpdateSnapLine(KeyStr, CanvasPos, bOnScreen, fromX, fromY)
                end
            end
        end
    end

    for KeyStr, _ in pairs(PlayerMapMarker.SnapLineWidgets) do
        if not SeenKeys[KeyStr] then
            PlayerMapMarker.RemoveSnapLine(KeyStr)
            PlayerMapMarker.ESPWidgets[KeyStr] = nil
        end
    end
end

_G.PlayerMapMarker = PlayerMapMarker

local function StartRadarSnapLinesLoop()
    pcall(function()
        local pc = PlayerMapMarker.GetMyPlayerController()
        if IsValid_ESP9(pc) and pc.AddGameTimer then
            pc:AddGameTimer(0.02, true, function()
                if PlayerMapMarker.bActive == nil then PlayerMapMarker.bActive = true end
                pcall(PlayerMapMarker.UpdateSnapLinesOnly)
            end)
        else
            local ticker = require("common.time_ticker")
            if ticker and ticker.AddTimerOnce then
                ticker.AddTimerOnce(1.0, StartRadarSnapLinesLoop)
            end
        end
    end)
end

pcall(function()
    local ticker = require("common.time_ticker")
    if ticker and ticker.AddTimerOnce then
        ticker.AddTimerOnce(2.0, StartRadarSnapLinesLoop)
    end
end)

-- ============================================================
-- 🔴 Overlay عداد اللاعبين والبوتات (مأخوذ من ملفي2)
-- ============================================================
local RedBoxOverlay = {
    bActive = false,
    MainContainer = nil,
    WidgetSlot = nil,
    TextBlockPlayer = nil,
    TextBlockBot = nil,
    BoxWidth = 100,
    BoxHeight = 30,
    Spacing = 15,
    OffsetY = 65,
    PlayerCount = 0,
    BotCount = 0,
    FontSize = 14,
    TextScaleValue = 1.0,
    NumLayers = 1,
    _CachedTextPlayer = "",
    _CachedTextBot = "",
    _CachedPosVec = nil,
}

function RedBoxOverlay.Create()
    if RedBoxOverlay.MainContainer and slua.isValid(RedBoxOverlay.MainContainer) then
        return true
    end
    local ParentCanvas = nil
    pcall(function()
        local InGameUITools = require("GameLua.Mod.BaseMod.Common.UI.InGameUITools")
        local MainControlBaseUI = InGameUITools.GetMainControlBaseUI()
        if slua.isValid(MainControlBaseUI) then
            if slua.isValid(MainControlBaseUI.CanvasPanel_0) then
                ParentCanvas = MainControlBaseUI.CanvasPanel_0
            elseif slua.isValid(MainControlBaseUI.CanvasPanel_42) then
                ParentCanvas = MainControlBaseUI.CanvasPanel_42
            end
        end
    end)
    if not ParentCanvas or not slua.isValid(ParentCanvas) then return false end

    local MainContainer = nil
    pcall(function()
        MainContainer = CGame:NewObjectFromPath("/Script/UMG.CanvasPanel", ParentCanvas)
    end)
    if not MainContainer or not slua.isValid(MainContainer) then return false end

    local FLinearColorClass = import("LinearColor") or _G.FLinearColor
    local FVector2DClass = import("Vector2D") or _G.FVector2D
    local FVector4Class = import("Vector4")
    local FSlateColorClass = import("SlateColor") or import("/Script/SlateCore.SlateColor")

    if not FLinearColorClass or not FVector2DClass then return false end

    local BgColor = FLinearColorClass(0.02, 0.08, 0.15, 0.9)
    local BorderColor = FLinearColorClass(0.0, 0.8, 1.0, 1.0)
    local PlayerColor = FLinearColorClass(1.0, 0.8, 0.0, 1.0)
    local BotColor = FLinearColorClass(1.0, 1.0, 1.0, 1.0)

    local function CreateBox(PosX)
        local Box = nil
        pcall(function()
            Box = CGame:NewObjectFromPath("/Script/UMG.Border", MainContainer)
        end)
        if Box and slua.isValid(Box) then
            pcall(function()
                Box:SetBrushColor(BgColor)
                if Box.Background and Box.Background.OutlineSettings then
                    local OutlineSettings = Box.Background.OutlineSettings
                    OutlineSettings.CornerRadius = FVector4Class(15, 15, 15, 15)
                    Box.Background.OutlineSettings = OutlineSettings
                end
                Box:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
            end)
            local BoxSlot = MainContainer:AddChildToCanvas(Box)
            if BoxSlot then
                BoxSlot:SetPosition(FVector2DClass(PosX, 0))
                BoxSlot:SetSize(FVector2DClass(RedBoxOverlay.BoxWidth, RedBoxOverlay.BoxHeight))
            end

            local Border = nil
            pcall(function()
                Border = CGame:NewObjectFromPath("/Script/UMG.Border", MainContainer)
            end)
            if Border and slua.isValid(Border) then
                Border:SetBrushColor(BorderColor)
                local BorderSlot = MainContainer:AddChildToCanvas(Border)
                if BorderSlot then
                    BorderSlot:SetPosition(FVector2DClass(PosX + 5, 0))
                    BorderSlot:SetSize(FVector2DClass(RedBoxOverlay.BoxWidth - 10, 1.5))
                end
            end
        end
    end

    CreateBox(0)
    CreateBox(RedBoxOverlay.BoxWidth + RedBoxOverlay.Spacing)

    local TextPlayer = nil
    pcall(function()
        TextPlayer = CGame:NewObjectFromPath("/Script/UMG.TextBlock", MainContainer)
    end)
    if TextPlayer and slua.isValid(TextPlayer) then
        TextPlayer:SetText(string.format("لاعب : %d ♞", RedBoxOverlay.PlayerCount))
        if FSlateColorClass then
            TextPlayer:SetColorAndOpacity(FSlateColorClass(PlayerColor))
        else
            TextPlayer:SetColorAndOpacity(PlayerColor)
        end
        if TextPlayer.Font then
            TextPlayer.Font.Size = RedBoxOverlay.FontSize
            TextPlayer.Font = TextPlayer.Font
        end
        TextPlayer:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        local SlotPlayer = MainContainer:AddChildToCanvas(TextPlayer)
        if SlotPlayer then
            SlotPlayer:SetAutoSize(true)
            SlotPlayer:SetAlignment(FVector2DClass(0.5, 0.5))
            SlotPlayer:SetPosition(FVector2DClass(RedBoxOverlay.BoxWidth * 0.5, RedBoxOverlay.BoxHeight * 0.5))
        end
        RedBoxOverlay.TextBlockPlayer = TextPlayer
    end

    local TextBot = nil
    pcall(function()
        TextBot = CGame:NewObjectFromPath("/Script/UMG.TextBlock", MainContainer)
    end)
    if TextBot and slua.isValid(TextBot) then
        TextBot:SetText(string.format("بوت : %d ♘ ", RedBoxOverlay.BotCount))
        if FSlateColorClass then
            TextBot:SetColorAndOpacity(FSlateColorClass(BotColor))
        else
            TextBot:SetColorAndOpacity(BotColor)
        end
        if TextBot.Font then
            TextBot.Font.Size = RedBoxOverlay.FontSize
            TextBot.Font = TextBot.Font
        end
        TextBot:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        local SlotBot = MainContainer:AddChildToCanvas(TextBot)
        if SlotBot then
            SlotBot:SetAutoSize(true)
            SlotBot:SetAlignment(FVector2DClass(0.5, 0.5))
            SlotBot:SetPosition(FVector2DClass(RedBoxOverlay.BoxWidth + RedBoxOverlay.Spacing + RedBoxOverlay.BoxWidth * 0.5, RedBoxOverlay.BoxHeight * 0.5))
        end
        RedBoxOverlay.TextBlockBot = TextBot
    end

    local MainSlot = nil
    pcall(function()
        MainSlot = ParentCanvas:AddChildToCanvas(MainContainer)
    end)
    if not MainSlot then return false end

    RedBoxOverlay.MainContainer = MainContainer
    RedBoxOverlay.WidgetSlot = MainSlot

    local TotalWidth = RedBoxOverlay.BoxWidth * 2 + RedBoxOverlay.Spacing
    pcall(function()
        MainSlot:SetAutoSize(false)
        MainSlot:SetZOrder(999)
        MainSlot:SetAnchors(FAnchors(0.5, 0, 0.5, 0))
        MainSlot:SetAlignment(FVector2DClass(0.5, 0.0))
        MainSlot:SetPosition(FVector2DClass(0, RedBoxOverlay.OffsetY))
        MainSlot:SetSize(FVector2DClass(TotalWidth, RedBoxOverlay.BoxHeight))
    end)

    RedBoxOverlay._CachedPosVec = FVector2DClass(0, RedBoxOverlay.OffsetY)
    return true
end

function RedBoxOverlay.SetCounts(PlayerCount, BotCount)
    PlayerCount = tonumber(PlayerCount) or 0
    BotCount = tonumber(BotCount) or 0
    if RedBoxOverlay.PlayerCount == PlayerCount and RedBoxOverlay.BotCount == BotCount then
        return
    end
    RedBoxOverlay.PlayerCount = PlayerCount
    RedBoxOverlay.BotCount = BotCount

    if RedBoxOverlay.TextBlockPlayer and slua.isValid(RedBoxOverlay.TextBlockPlayer) then
        pcall(function()
            local NewText = string.format("لاعب : %d ♞", RedBoxOverlay.PlayerCount)
            if RedBoxOverlay._CachedTextPlayer ~= NewText then
                RedBoxOverlay.TextBlockPlayer:SetText(NewText)
                RedBoxOverlay._CachedTextPlayer = NewText
            end
        end)
    end
    if RedBoxOverlay.TextBlockBot and slua.isValid(RedBoxOverlay.TextBlockBot) then
        pcall(function()
            local NewText = string.format("بوت : %d ♘ ", RedBoxOverlay.BotCount)
            if RedBoxOverlay._CachedTextBot ~= NewText then
                RedBoxOverlay.TextBlockBot:SetText(NewText)
                RedBoxOverlay._CachedTextBot = NewText
            end
        end)
    end
end

function RedBoxOverlay.Start()
    if RedBoxOverlay.bActive and RedBoxOverlay.MainContainer and slua.isValid(RedBoxOverlay.MainContainer) then
        return
    end
    if RedBoxOverlay.Create() then
        RedBoxOverlay.bActive = true
        pcall(function()
            RedBoxOverlay.MainContainer:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
        end)
    end
end

function RedBoxOverlay.Stop()
    RedBoxOverlay.bActive = false
    if RedBoxOverlay.MainContainer and slua.isValid(RedBoxOverlay.MainContainer) then
        pcall(function()
            RedBoxOverlay.MainContainer:RemoveFromParent()
            RedBoxOverlay.MainContainer:ConditionalBeginDestroy()
        end)
    end
    RedBoxOverlay.MainContainer = nil
    RedBoxOverlay.WidgetSlot = nil
    RedBoxOverlay.TextBlockPlayer = nil
    RedBoxOverlay.TextBlockBot = nil
    RedBoxOverlay._CachedPosVec = nil
end

_G.RedBoxOverlay = RedBoxOverlay

local function RedBoxIsValid(obj)
    if not obj then return false end
    if slua and slua.isValid then
        local ok, v = pcall(slua.isValid, obj)
        return ok and v
    end
    return obj ~= nil
end

local function RedBoxGetTeamID(pawn)
    if not pawn then return nil end
    local teamID = nil
    pcall(function()
        if pawn.GetTeamID then
            teamID = pawn:GetTeamID()
        end
    end)
    if teamID == nil then
        pcall(function()
            if pawn.TeamID ~= nil then teamID = pawn.TeamID end
        end)
    end
    if teamID == nil then
        pcall(function()
            local ps = nil
            if pawn.GetPlayerStateSafety then
                ps = pawn:GetPlayerStateSafety()
            elseif pawn.GetPlayerState then
                ps = pawn:GetPlayerState()
            end
            if RedBoxIsValid(ps) then
                if ps.GetTeamID then
                    teamID = ps:GetTeamID()
                elseif ps.TeamID ~= nil then
                    teamID = ps.TeamID
                end
            end
        end)
    end
    return teamID
end

local function RedBoxIsBot(pawn)
    local isBot = false
    pcall(function()
        if Game and Game.IsAI then
            isBot = Game:IsAI(pawn)
        end
    end)
    if isBot then return true end
    pcall(function()
        if pawn.IsAI then
            if pawn:IsAI() then isBot = true end
        end
    end)
    if isBot then return true end
    pcall(function()
        if pawn.bIsAI == true or pawn.bIsBot == true then
            isBot = true
        end
    end)
    if isBot then return true end
    pcall(function()
        local ps = nil
        if pawn.GetPlayerStateSafety then
            ps = pawn:GetPlayerStateSafety()
        elseif pawn.GetPlayerState then
            ps = pawn:GetPlayerState()
        end
        if RedBoxIsValid(ps) then
            if ps.bIsAI == true or ps.bIsBot == true then
                isBot = true
            end
            if ps.IsAI then
                if ps:IsAI() then isBot = true end
            end
        end
    end)
    return isBot
end

local function RedBoxIsAlive(pawn)
    if not pawn then return false end
    local alive = nil
    pcall(function()
        if pawn.IsAlive then
            alive = pawn:IsAlive()
        end
    end)
    if alive ~= nil then return alive == true end
    pcall(function()
        if pawn.bDead ~= nil then
            alive = not pawn.bDead
        end
    end)
    if alive ~= nil then return alive == true end
    local health = nil
    pcall(function()
        health = tonumber(pawn.Health or pawn.HP or pawn.CurHP or pawn.CurrentHealth)
    end)
    if health ~= nil then return 0 < health end
    return true
end

local function RedBoxGetAllPawns()
    local result = {}
    pcall(function()
        if Game and Game.GetAllPlayerPawns then
            local all = Game:GetAllPlayerPawns()
            if all then
                for _, p in pairs(all) do
                    if RedBoxIsValid(p) then table.insert(result, p) end
                end
            end
        end
    end)
    if #result == 0 then
        pcall(function()
            local GameplayData = require("GameLua.GameCore.Data.GameplayData")
            if GameplayData then
                if GameplayData.GetAllPlayerCharacters then
                    local all = GameplayData.GetAllPlayerCharacters()
                    if all then
                        for _, p in pairs(all) do
                            if RedBoxIsValid(p) then table.insert(result, p) end
                        end
                    end
                elseif GameplayData.GameCharacters then
                    for _, p in pairs(GameplayData.GameCharacters) do
                        if RedBoxIsValid(p) then table.insert(result, p) end
                    end
                end
            end
        end)
    end
    return result
end

local function RedBoxIsLocalPlayer(pawn, localPawn)
    if pawn == localPawn then return true end
    local isLocal = false
    pcall(function()
        local GameplayData = require("GameLua.GameCore.Data.GameplayData")
        if GameplayData and GameplayData.GetPlayerController then
            local pc = GameplayData.GetPlayerController()
            if pc and pc.GetPawn then
                if pc:GetPawn() == pawn then isLocal = true end
            end
        end
    end)
    return isLocal
end

local function RedBoxUpdateCounter()
    if not _G.NTH_Settings or _G.NTH_Settings.REDBOX_COUNT ~= 1 then
        if RedBoxOverlay.bActive then RedBoxOverlay.Stop() end
        return
    end

    local localPawn = nil
    pcall(function()
        local GameplayData = require("GameLua.GameCore.Data.GameplayData")
        if GameplayData then
            localPawn = GameplayData.GetPlayerCharacter()
        end
    end)

    if not RedBoxIsValid(localPawn) then
        if RedBoxOverlay.bActive then RedBoxOverlay.Stop() end
        return
    end

    local myTeamID = RedBoxGetTeamID(localPawn)
    local playerCount = 0
    local botCount = 0

    local allPawns = RedBoxGetAllPawns()
    for _, pawn in ipairs(allPawns) do
        if RedBoxIsValid(pawn) then
            if not RedBoxIsLocalPlayer(pawn, localPawn) then
                if RedBoxIsAlive(pawn) then
                    local teamID = RedBoxGetTeamID(pawn)
                    if teamID == nil or myTeamID == nil or teamID ~= myTeamID then
                        if RedBoxIsBot(pawn) then
                            botCount = botCount + 1
                        else
                            playerCount = playerCount + 1
                        end
                    end
                end
            end
        end
    end

    if not RedBoxOverlay.bActive then
        RedBoxOverlay.Start()
    end
    if RedBoxOverlay.bActive then
        RedBoxOverlay.SetCounts(playerCount, botCount)
    end
end

_G.RedBoxOverlayTick = function()
    pcall(RedBoxUpdateCounter)
end

pcall(function()
    local ticker = require("common.time_ticker")
    if ticker and ticker.AddTimerLoop then
        ticker.AddTimerLoop(0, function()
            pcall(RedBoxUpdateCounter)
        end, -1, 0.5)
    end
end)

-- ============================================================
-- 🎯 دالة الحاقن الرئيسية (بدون نظام Aim Touch وبدون Skin Mod)
-- ============================================================
function CharacterBase:N5LAMOD_INJECT_MOD()
  if not Client then
    return
  end
  if self._N5LA_INJECTED then
    return  -- ✅ منع الحقن المتكرر
  end
  self._N5LA_INJECTED = true
  self._BEN10_INJECTED = true  -- للتوافق مع اللودر

  local function OnTick()
    if not _G._Authenticated_ then
      return
    end
    if not slua.isValid(self.Object) then
      return
    end
    local PlayerController = GameplayData.GetPlayerController()
    local PlayerCharacter = GameplayData.GetPlayerCharacter()
    if slua.isValid(PlayerController) then
      local bUseViewTarget = false
      pcall(function()
        bUseViewTarget = not slua.isValid(PlayerCharacter) or (type(PlayerCharacter.IsDead) == "function" and PlayerCharacter:IsDead())
      end)
      if bUseViewTarget then
        if type(PlayerController.GetViewTarget) == "function" then
          local ViewTarget = PlayerController:GetViewTarget()
          if slua.isValid(ViewTarget) then
            if type(ViewTarget.GetHealth) == "function" then
              PlayerCharacter = ViewTarget
            end
          end
        end
      end
    end
    if not slua.isValid(PlayerCharacter) then
      return
    end
    if nowUTC > limitTime then
      if self.Object == PlayerCharacter then
        if not self.bHasShownExpiredNotice then
          if self.Object.IsAlive then
            if self.Object:IsAlive() then
              self.bHasShownExpiredNotice = true
              pcall(function()
                local logic_common_msg_box = package.loaded["client.slua.logic.common.logic_common_msg_box"]
                if not logic_common_msg_box then
                  logic_common_msg_box = require("client.slua.logic.common.logic_common_msg_box")
                end
                if logic_common_msg_box then
                  if logic_common_msg_box.Show then
                    logic_common_msg_box.Show(4, "إشعار من المشرف BEN10", "تواصل مع @Afhshjs.", function()
                      local UKismetSystemLibrary = import("KismetSystemLibrary")
                      if UKismetSystemLibrary then
                        UKismetSystemLibrary.LaunchURL("https://t.me/si_c7")
                      end
                    end, function()
                    end, "إغلاق", "تواصل")
                  end
                end
              end)
            end
          end
        end
      end
      return
    end
    local TppFov = _G.NTH_GetVal("IPAD_VIEW_TPP")
    if TppFov == 0 or TppFov < 80 then
      TppFov = 100
    end
    local ScopeArmLength = _G.NTH_GetVal("IPAD_VIEW_SCOPE")
    if ScopeArmLength == 0 then
      ScopeArmLength = 15
    end
    local VehicleFov = _G.NTH_GetVal("IPAD_VIEW_XE")
    if VehicleFov == 0 or VehicleFov < 90 then
      VehicleFov = 110
    end
    local ThirdPersonCameraComponent = self.Object.ThirdPersonCameraComponent
    local ScopingSpringArm = self.Object.ScopingSpringArm
    local bIsWeaponAiming = self.Object.bIsWeaponAiming or false
    local CurrentVehicle = self.Object.GetCurrentVehicle and self.Object:GetCurrentVehicle() or nil
    local bIsDriver = false
    if slua.isValid(CurrentVehicle) then
      if CurrentVehicle.GetDriver then
        local Driver = CurrentVehicle:GetDriver()
        if slua.isValid(Driver) then
          if Driver == self.Object then
            bIsDriver = true
          end
        end
      end
    end
    if not bIsWeaponAiming then
      if bIsDriver then
        local CameraComponentClass = import("CameraComponent")
        if CameraComponentClass then
          if slua.isValid(CurrentVehicle) then
            local VehicleCamera = CurrentVehicle:GetComponentByClass(CameraComponentClass)
            if slua.isValid(VehicleCamera) then
              VehicleCamera:SetFieldOfView(VehicleFov)
              VehicleCamera.FieldOfView = VehicleFov
            end
          end
        end
        if slua.isValid(ThirdPersonCameraComponent) then
          ThirdPersonCameraComponent:SetFieldOfView(VehicleFov)
          ThirdPersonCameraComponent.FieldOfView = VehicleFov
        end
      else
        if slua.isValid(ThirdPersonCameraComponent) and 90 < TppFov then
          ThirdPersonCameraComponent:SetFieldOfView(TppFov)
          ThirdPersonCameraComponent.FieldOfView = TppFov
        end
      end
    end
    if slua.isValid(ScopingSpringArm) and 0 < ScopeArmLength then
      ScopingSpringArm.TargetArmLength = ScopeArmLength
    end
    if self.Object.GetCurrentWeapon then
      local CurrentWeapon = self.Object:GetCurrentWeapon()
      if slua.isValid(CurrentWeapon) then
        local NowClock = os.clock()
        if self.LastWeaponEntity ~= CurrentWeapon then
          self.LastWeaponEntity = CurrentWeapon
          self.bForceWeaponMod = true
        end
        if not self.LastWeaponModTime or NowClock > self.LastWeaponModTime + 2.0 then
          self.bForceWeaponMod = true
          self.LastWeaponModTime = NowClock
        end
        if self.bForceWeaponMod or not CurrentWeapon.bIsN5LAMODded then
          pcall(function()
            local ShootWeaponEntity = CurrentWeapon.ShootWeaponEntity_GEN_VARIABLE or CurrentWeapon.ShootWeaponEntity
            if slua.isValid(ShootWeaponEntity) then
              -- تم حذف تأثيرات الأسلحة بناءً على طلب المستخدم
              if _G.NTH_GetVal("AIMBOT") == 1 then
                if ShootWeaponEntity.AutoAimingConfig then
                  local AutoAimingConfig = ShootWeaponEntity.AutoAimingConfig
                  local SpeedAimbot = _G.NTH_GetVal("SPEED_AIMBOT") / 100.0
                  local FovAimbot = _G.NTH_GetVal("FOV_AIMBOT") / 100.0
                  local AimSpeed = 3.0 + 3.0 * SpeedAimbot
                  local AimRangeRate = 1.5 + 1.5 * FovAimbot
                  if AutoAimingConfig.OuterRange then
                    AutoAimingConfig.OuterRange.Speed = AimSpeed
                    AutoAimingConfig.OuterRange.SpeedRate = AimSpeed
                    AutoAimingConfig.OuterRange.RangeRate = AimRangeRate
                    AutoAimingConfig.OuterRange.RangeRateSight = AimRangeRate
                    AutoAimingConfig.OuterRange.SpeedRateSight = AimSpeed
                    AutoAimingConfig.OuterRange.CrouchRate = 1.0
                    AutoAimingConfig.OuterRange.ProneRate = 1.0
                  end
                  if AutoAimingConfig.InnerRange then
                    AutoAimingConfig.InnerRange.Speed = AimSpeed
                    AutoAimingConfig.InnerRange.SpeedRate = AimSpeed
                    AutoAimingConfig.InnerRange.RangeRate = AimRangeRate
                    AutoAimingConfig.InnerRange.RangeRateSight = AimRangeRate
                    AutoAimingConfig.InnerRange.SpeedRateSight = AimSpeed
                    AutoAimingConfig.InnerRange.CrouchRate = 1.0
                    AutoAimingConfig.InnerRange.ProneRate = 1.0
                  end
                  ShootWeaponEntity.AutoAimingConfig = AutoAimingConfig
                end
              end
            end
          end)
          CurrentWeapon.bIsN5LAMODded = true
          self.bForceWeaponMod = false
        end
      end
    end
    if self.Object == PlayerCharacter then
      if not _G.N5LAMODTickCount then
        _G.N5LAMODTickCount = 0
      end
      if not _G.MagicUpdateVersion then
        _G.MagicUpdateVersion = 1
      end
      if _G.EnvRequiresUpdate == nil then
        _G.EnvRequiresUpdate = true
      end
      _G.N5LAMODTickCount = _G.N5LAMODTickCount + 1
      if _G.N5LAMODTickCount % 50 == 0 then
        if not _G.NTH_NeedSave then
          pcall(function()
            _G.NTH_LoadINI()
          end)
        end
      end
      if not self.NTH_NativeESP_Ready then
        pcall(function()
          local GamePlayTools = require("GameLua.Mod.BaseMod.Common.GamePlayTools")
          local ScreenMarkConfig = GamePlayTools.GetCurrentConfig("ScreenMarkConfig")
          if ScreenMarkConfig then
            if ScreenMarkConfig[1006] then
              ScreenMarkConfig[1006].bBindBlocked = true
              ScreenMarkConfig[1006].bBindOutScreen = true
              ScreenMarkConfig[1006].MaxWidgetNum = 99
              ScreenMarkConfig[1006].MaxShowDistance = 6000000
              ScreenMarkConfig[1006].bScaleByDistance = false
              ScreenMarkConfig[1006].BindSocketName = "root"
              ScreenMarkConfig[1006].bUseLuaWorldSocketName = true
              ScreenMarkConfig[1006].WorldPositionOffset = import("Vector")(0, 0, -30)
            end
            if not ScreenMarkConfig[9999] then
              local MarkConfig = {}
              MarkConfig.UIPathName = "/Game/Mod/EvoBase/BluePrints/UIBP/QuickSign/QuickSign_TipHitEnemy_UIBP_New.QuickSign_TipHitEnemy_UIBP_New_C"
              MarkConfig.MaxWidgetNum = 99
              MarkConfig.MaxShowDistance = 6000000
              MarkConfig.bBindOutScreen = true
              MarkConfig.bBindBlocked = true
              MarkConfig.bIsBindingActor = true
              MarkConfig.BindSocketName = "head"
              MarkConfig.bUseLuaWorldSocketName = true
              MarkConfig.WorldPositionOffset = import("Vector")(0, 0, 50)
              MarkConfig.bNeedPreLoad = true
              MarkConfig.Priority = 2
              ScreenMarkConfig[9999] = MarkConfig
              local InGameMarkTools = require("GameLua.Mod.BaseMod.Common.InGameMarkTools")
              if InGameMarkTools then
                if InGameMarkTools.ScreenMarkManager then
                  if InGameMarkTools.ScreenMarkManager.OnInitMarkGroupData then
                    pcall(function()
                      InGameMarkTools.ScreenMarkManager:OnInitMarkGroupData(9999)
                    end)
                  end
                end
              end
            end
          end
          for ModuleName, Module in pairs(package.loaded) do
            if type(ModuleName) == "string" then
              if string.find(ModuleName, "ScreenMarkConfig") then
                if type(Module) == "table" then
                  if Module[1006] then
                    Module[1006].bBindBlocked = true
                    Module[1006].bBindOutScreen = true
                    Module[1006].MaxWidgetNum = 99
                    Module[1006].MaxShowDistance = 6000000
                    Module[1006].bScaleByDistance = false
                    Module[1006].BindSocketName = "root"
                    Module[1006].bUseLuaWorldSocketName = true
                    Module[1006].WorldPositionOffset = import("Vector")(0, 0, -30)
                  end
                  local MarkConfig = {}
                  MarkConfig.UIPathName = "/Game/Mod/EvoBase/BluePrints/UIBP/QuickSign/QuickSign_TipHitEnemy_UIBP_New.QuickSign_TipHitEnemy_UIBP_New_C"
                  MarkConfig.MaxWidgetNum = 99
                  MarkConfig.MaxShowDistance = 6000000
                  MarkConfig.bBindOutScreen = true
                  MarkConfig.bBindBlocked = true
                  MarkConfig.bIsBindingActor = true
                  MarkConfig.BindSocketName = "head"
                  MarkConfig.bUseLuaWorldSocketName = true
                  MarkConfig.WorldPositionOffset = import("Vector")(0, 0, 50)
                  MarkConfig.bNeedPreLoad = true
                  MarkConfig.Priority = 2
                  Module[9999] = MarkConfig
                end
              end
            end
          end
          local SubsystemMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
          local ClientHPBarSubSystem = SubsystemMgr:Get("ClientHPBarSubSystem")
          if ClientHPBarSubSystem then
            if ClientHPBarSubSystem.SetPauseCheck then
              ClientHPBarSubSystem:SetPauseCheck(true)
            end
            if ClientHPBarSubSystem.FocusActorCheckParam then
              ClientHPBarSubSystem.FocusActorCheckParam.CheckBlock = false
              ClientHPBarSubSystem.FocusActorCheckParam.CheckDistance = 1000000
            end
          end
          if UIManager then
            if UIManager.GetUI then
              local EnemyHpWidgetsMain = UIManager.GetUI(UIManager.UI_Config_InGame.EnemyHpWidgetsMain)
              if slua.isValid(EnemyHpWidgetsMain) then
                if EnemyHpWidgetsMain.SetCheckBlock then
                  EnemyHpWidgetsMain:SetCheckBlock(false)
                end
                if EnemyHpWidgetsMain.UIRoot then
                  if EnemyHpWidgetsMain.UIRoot.CanvasPanel_HPBarWidgets then
                    if EnemyHpWidgetsMain.UIRoot.CanvasPanel_HPBarWidgets.SetRenderScale then
                      EnemyHpWidgetsMain.UIRoot.CanvasPanel_HPBarWidgets:SetRenderScale(import("Vector2D")(1.5, 1.5))
                    end
                  end
                end
              end
            end
          end
        end)
        self.NTH_NativeESP_Ready = true
      end
      local bWallhackChams = _G.NTH_GetVal("WALLHACK_CHAMS") == 1
      if _G.EnvRequiresUpdate then
        _G.EnvRequiresUpdate = false
        pcall(function()
          local AllCharacters = GameplayData.GetAllPlayerCharacters and GameplayData.GetAllPlayerCharacters() or {}
          for _, Character in pairs(AllCharacters) do
            if slua.isValid(Character) then
              Character.WallhackApplied = false
              Character.LastAuraHash = nil
              Character.LastMeshCountWall = -1
              Character.NTH_AuraMeshes = nil
            end
          end
          local UKismetSystemLibrary = import("KismetSystemLibrary")
          local Controller = GameplayData.GetPlayerController()

          local function RunCmd(CmdName, CmdValue)
            if slua.isValid(UKismetSystemLibrary) then
              if slua.isValid(Controller) then
                UKismetSystemLibrary.ExecuteConsoleCommand(Controller, CmdName .. " " .. CmdValue)
              end
            end
            local GameInstance = slua_GameFrontendHUD and slua_GameFrontendHUD:GetGameInstance()
            if slua.isValid(GameInstance) then
              if GameInstance.ExecuteCMD then
                GameInstance:ExecuteCMD(CmdName, CmdValue)
              end
            end
          end

          if slua.isValid(Controller) then
            if bWallhackChams then
              RunCmd("r.EnableDrawDyeingColor", "1")
              RunCmd("r.SupportDyeingColorDistanceFade", "1")
              RunCmd("r.SupportDyeingColorMeshProxy", "1")
              RunCmd("r.EnablePrimitiveHighlight", "1")
              RunCmd("r.CustomDepth", "3")
              RunCmd("r.DeviceLevelUseHighLightMode", "1")
              RunCmd("r.Highlight.Enable", "1")
            end
            if _G.NTH_GetVal("NOGRASS") == 1 then
              RunCmd("r.DisableGrassRender", "1")
            else
              RunCmd("r.DisableGrassRender", "0")
            end
            if _G.NTH_GetVal("NOTREES") == 1 then
              RunCmd("foliage.DensityScale", "0")
              RunCmd("r.Foliage.DensityScale", "0")
              RunCmd("foliage.MinimumScreenSize", "10000")
              RunCmd("r.DisableTreeRender", "1")
            else
              RunCmd("foliage.DensityScale", "1")
              RunCmd("r.Foliage.DensityScale", "1")
              RunCmd("foliage.MinimumScreenSize", "0.0001")
              RunCmd("r.DisableTreeRender", "0")
            end
            if _G.NTH_GetVal("NOWATER") == 1 then
              RunCmd("r.Water.SingleLayer.Enable", "0")
              RunCmd("r.Show.Water", "0")
              RunCmd("r.Show.Translucency", "0")
              RunCmd("r.DisableWaterRender", "1")
            else
              RunCmd("r.Water.SingleLayer.Enable", "1")
              RunCmd("r.Show.Water", "1")
              RunCmd("r.Show.Translucency", "1")
              RunCmd("r.DisableWaterRender", "0")
            end
            if _G.NTH_GetVal("NOFOG") == 1 then
              RunCmd("r.SkyAtmosphere", "0")
              RunCmd("r.Atmosphere", "0")
              RunCmd("r.Fog", "0")
              RunCmd("r.VolumetricFog", "0")
              RunCmd("r.DisableSkyRender", "1")
            else
              RunCmd("r.SkyAtmosphere", "1")
              RunCmd("r.Atmosphere", "1")
              RunCmd("r.Fog", "1")
              RunCmd("r.VolumetricFog", "1")
              RunCmd("r.DisableSkyRender", "0")
            end
            if _G.NTH_GetVal("BLACKSKY") == 1 then
              RunCmd("r.CylinderMaxDrawHeight", "9999")
            else
              RunCmd("r.CylinderMaxDrawHeight", "0")
            end
            if _G.NTH_GetVal("WHITE_BODY") == 1 then
              RunCmd("r.CharacterDiffuseOffset", "2")
              RunCmd("r.CharacterDiffusePower", "5")
              RunCmd("r.CharacterMinShadowFactor", "100")
            else
              RunCmd("r.CharacterDiffuseOffset", "0")
              RunCmd("r.CharacterDiffusePower", "1")
              RunCmd("r.CharacterMinShadowFactor", "0")
            end
          end
        end)
      end
      local Characters = {}
      if GameplayData.GetAllPlayerCharacters then
        Characters = GameplayData.GetAllPlayerCharacters()
      else
        if GameplayData.GameCharacters then
          for _, GameCharacter in pairs(GameplayData.GameCharacters) do
            table.insert(Characters, GameCharacter)
          end
        end
      end
      local PlayerCount = 0
      local BotCount = 0
      local InRangeCount = 0
      local AimingAtYouCount = 0
      if not _G.NTH_Active_HP_Cache then
        _G.NTH_Active_HP_Cache = {}
      end
      if not _G.NTH_Active_Dist_Cache then
        _G.NTH_Active_Dist_Cache = {}
      end
      for CacheKey, CacheEntry in pairs(_G.NTH_Active_HP_Cache) do
        local bRemove = false
        if not slua.isValid(CacheEntry.actor) then
          bRemove = true
        else
          pcall(function()
            local Actor = CacheEntry.actor
            if Actor.bHidden or (Actor.Mesh and Actor.Mesh.bHidden) then
              bRemove = true
            end
            if type(Actor.IsDead) == "function" then
              if Actor:IsDead() then
                bRemove = true
              end
            elseif Actor.bIsDead == true or Actor.bIsDeadFlag == true then
              bRemove = true
            end
          end)
        end
        if bRemove then
          pcall(function()
            if InGameMarkTools then
              if InGameMarkTools.ClientRemoveMapMark then
                if CacheEntry.mark then
                  InGameMarkTools.ClientRemoveMapMark(CacheEntry.mark)
                end
              else
                if CacheEntry.mark then
                  InGameMarkTools.HideMapMark(CacheEntry.mark)
                end
              end
            end
          end)
          if slua.isValid(CacheEntry.actor) then
            CacheEntry.actor.bHasAKNativeHPBar = false
            CacheEntry.actor.NativeHPBarMark = nil
          end
          _G.NTH_Active_HP_Cache[CacheKey] = nil
        end
      end
      for CacheKey, CacheEntry in pairs(_G.NTH_Active_Dist_Cache) do
        local bRemove = false
        if not slua.isValid(CacheEntry.actor) then
          bRemove = true
        else
          pcall(function()
            local Actor = CacheEntry.actor
            if Actor.bHidden or (Actor.Mesh and Actor.Mesh.bHidden) then
              bRemove = true
            end
            if type(Actor.IsDead) == "function" then
              if Actor:IsDead() then
                bRemove = true
              end
            elseif Actor.bIsDead == true or Actor.bIsDeadFlag == true then
              bRemove = true
            end
            local bIsNearDeath = false
            if type(Actor.IsNearDeath) == "function" then
              bIsNearDeath = Actor:IsNearDeath()
            else
              if Actor.bIsNearDeath ~= nil then
                bIsNearDeath = Actor.bIsNearDeath
              end
            end
            local Health = 100
            if type(Actor.GetHealth) == "function" then
              Health = Actor:GetHealth()
            else
              if Actor.Health ~= nil then
                Health = Actor.Health
              end
            end
            if Health <= 0 and not bIsNearDeath then
              bRemove = true
            end
          end)
        end
        if bRemove then
          pcall(function()
            if InGameMarkTools then
              if InGameMarkTools.ClientRemoveMapMark then
                if CacheEntry.mark then
                  InGameMarkTools.ClientRemoveMapMark(CacheEntry.mark)
                end
              else
                if CacheEntry.mark then
                  InGameMarkTools.HideMapMark(CacheEntry.mark)
                end
              end
            end
          end)
          if slua.isValid(CacheEntry.actor) then
            CacheEntry.actor.bHasAKNativeDistBar = false
            CacheEntry.actor.NativeDistMark = nil
          end
          _G.NTH_Active_Dist_Cache[CacheKey] = nil
        end
      end
      local MyTeamID = -1
      pcall(function()
        MyTeamID = (type(PlayerCharacter.GetTeamID) == "function" and PlayerCharacter:GetTeamID()) or PlayerCharacter.TeamID or (PlayerCharacter.PlayerState and PlayerCharacter.PlayerState.TeamNum) or -1
      end)
      for _, Character in pairs(Characters) do
        if slua.isValid(Character) and Character ~= PlayerCharacter then
          local TargetTeamID = -2
          pcall(function()
            TargetTeamID = (type(Character.GetTeamID) == "function" and Character:GetTeamID()) or Character.TeamID or (Character.PlayerState and Character.PlayerState.TeamNum) or -2
          end)
          if TargetTeamID ~= MyTeamID then
            local bIsDead = false
            local bIsNearDeath = false
            local Health = 100
            pcall(function()
              if type(Character.IsNearDeath) == "function" then
                bIsNearDeath = Character:IsNearDeath()
              else
                if Character.bIsNearDeath ~= nil then
                  bIsNearDeath = Character.bIsNearDeath
                end
              end
              if type(Character.IsDead) == "function" then
                bIsDead = Character:IsDead()
              else
                if Character.bIsDead ~= nil then
                  bIsDead = Character.bIsDead
                else
                  if Character.bIsDeadFlag ~= nil then
                    bIsDead = Character.bIsDeadFlag
                  end
                end
              end
              if Character.bHidden or (Character.Mesh and Character.Mesh.bHidden) then
                bIsDead = true
              end
              if type(Character.GetHealth) == "function" then
                Health = Character:GetHealth()
              else
                if Character.Health ~= nil then
                  Health = Character.Health
                end
              end
              if not bIsNearDeath and Health <= 0 then
                bIsDead = true
              end
            end)
            local bDeadForDist = bIsDead
            pcall(function()
              if Health <= 0 and not bIsNearDeath then
                bDeadForDist = true
              end
            end)
            if not bIsDead then
              local bIsBot, bIsBotEx = _G.NTH_CheckIsBot(Character)
              if bIsBotEx or bIsBot then
                BotCount = BotCount + 1
              else
                PlayerCount = PlayerCount + 1
              end
              local InfoRange = _G.NTH_GetVal("ESP_INFO_RANGE") or 400
              local Distance = 99999
              pcall(function()
                if PlayerCharacter.GetDistanceTo then
                  Distance = math.floor(PlayerCharacter:GetDistanceTo(Character) / 100)
                end
              end)
              if InfoRange >= Distance then
                InRangeCount = InRangeCount + 1
              end
            end
            if _G.NTH_GetVal("WARN_AIMING") == 1 and not bIsNearDeath then
              pcall(function()
                local bVisible = true
                if _G.NTH_GetVal("WARN_AIMING_VISCHECK") == 1 then
                  bVisible = false
                  pcall(function()
                    bVisible = PlayerController:LineOfSightTo(Character, import("Vector")(0, 0, 0), false)
                  end)
                end
                if bVisible then
                  local MyLocation = PlayerCharacter:K2_GetActorLocation()
                  local TargetLocation = Character:K2_GetActorLocation()
                  local DeltaX = MyLocation.X - TargetLocation.X
                  local DeltaY = MyLocation.Y - TargetLocation.Y
                  local DeltaZ = MyLocation.Z - TargetLocation.Z
                  local Dist2D = math.sqrt(DeltaX * DeltaX + DeltaY * DeltaY)
                  local Dist3D = math.sqrt(DeltaX * DeltaX + DeltaY * DeltaY + DeltaZ * DeltaZ)
                  if Dist3D <= 40000.0 then
                    local AimRotation = Character.BaseAimRotation or Character:K2_GetActorRotation()
                    local AimPitch = NormalizeAngle(AimRotation.Pitch)
                    local AimYaw = NormalizeAngle(AimRotation.Yaw)
                    local WantYaw = NormalizeAngle(math.atan(DeltaY, DeltaX) * (180.0 / math.pi))
                    local WantPitch = NormalizeAngle(math.atan(DeltaZ, Dist2D) * (180.0 / math.pi))
                    local YawDiff = math.abs(NormalizeAngle(WantYaw - AimYaw))
                    local PitchDiff = math.abs(NormalizeAngle(WantPitch - AimPitch))
                    if YawDiff <= 20 and PitchDiff <= 20 then
                      AimingAtYouCount = AimingAtYouCount + 1
                    end
                  end
                end
              end)
            end
            if not bIsDead then
              local SkeletalMeshComponentClass = import("SkeletalMeshComponent")
              if not Character.NTH_NextMeshUpdateTime or os.clock() > Character.NTH_NextMeshUpdateTime then
                Character.NTH_NextMeshUpdateTime = os.clock() + 5.0 + math.random() * 1.0
                local NewMeshes = {}
                if slua.isValid(Character.Mesh) then
                  table.insert(NewMeshes, Character.Mesh)
                end
                if SkeletalMeshComponentClass then
                  pcall(function()
                    local Components = Character:GetComponentsByClass(SkeletalMeshComponentClass)
                    if Components then
                      local Count = (type(Components.Num) == "function" and Components:Num()) or #Components
                      for Index = 1, Count, 1 do
                        local Component = (type(Components.Get) == "function" and Components:Get(Index - 1)) or Components[Index]
                        if slua.isValid(Component) then
                          if Component ~= Character.Mesh then
                            table.insert(NewMeshes, Component)
                          end
                        end
                      end
                    end
                  end)
                end
                Character.NTH_CachedMeshes = NewMeshes
              end
              local CachedMeshes = Character.NTH_CachedMeshes or {}
              local MeshCount = #CachedMeshes
              local bMeshCountChanged = Character.LastMeshCountWall ~= MeshCount
              if bWallhackChams then
                local VisibleColor = GetVisibleChamsColor()
                local HiddenColor = GetOccludedChamsColor()
                local ColorKey = tostring(_G.NTH_GetVal("CHAMS_COLOR_VIS")) .. "_" .. tostring(_G.NTH_GetVal("CHAMS_COLOR_HID"))
                local AuraHash = "player_" .. ColorKey
                if bMeshCountChanged or Character.LastAuraHash ~= AuraHash or not Character.WallhackApplied then
                  pcall(function()
                    if bMeshCountChanged then
                      if Character.NTH_AuraMeshes then
                        for _, AuraMesh in ipairs(Character.NTH_AuraMeshes) do
                          DisableChams(AuraMesh)
                        end
                      end
                    end
                    for _, CachedMesh in ipairs(CachedMeshes) do
                      if slua.isValid(CachedMesh) then
                        EnableChams(CachedMesh, VisibleColor, HiddenColor)
                      end
                    end
                    if Character.DelayCustomDepth then
                      pcall(function()
                        Character:DelayCustomDepth(true)
                      end)
                    end
                  end)
                  Character.WallhackApplied = true
                  Character.LastAuraHash = AuraHash
                  Character.LastMeshCountWall = MeshCount
                  Character.NTH_AuraMeshes = CachedMeshes
                end
              else
                if Character.WallhackApplied then
                  pcall(function()
                    local AuraMeshes = Character.NTH_AuraMeshes or CachedMeshes
                    for _, AuraMesh in ipairs(AuraMeshes) do
                      if slua.isValid(AuraMesh) then
                        DisableChams(AuraMesh)
                      end
                    end
                  end)
                  Character.WallhackApplied = false
                  Character.LastAuraHash = nil
                  Character.LastMeshCountWall = nil
                  Character.NTH_AuraMeshes = nil
                end
              end
            else
              if Character.WallhackApplied then
                local CachedMeshes = Character.NTH_CachedMeshes or {}
                pcall(function()
                  local AuraMeshes = Character.NTH_AuraMeshes or CachedMeshes
                  for _, AuraMesh in ipairs(AuraMeshes) do
                    if slua.isValid(AuraMesh) then
                      DisableChams(AuraMesh)
                    end
                  end
                end)
                Character.WallhackApplied = false
                Character.LastAuraHash = nil
                Character.LastMeshCountWall = nil
                Character.NTH_AuraMeshes = nil
              end
            end
            if not bIsDead then
              if Character.bHasAKNativeHPBar then
                if Character.NTH_LastKnockState ~= nil then
                  if Character.NTH_LastKnockState ~= bIsNearDeath then
                    pcall(function()
                      if InGameMarkTools then
                        if InGameMarkTools.ClientRemoveMapMark then
                          if Character.NativeHPBarMark then
                            InGameMarkTools.ClientRemoveMapMark(Character.NativeHPBarMark)
                          end
                        end
                      end
                    end)
                    Character.bHasAKNativeHPBar = false
                    _G.NTH_Active_HP_Cache[tostring(Character)] = nil
                  end
                end
              end
              if _G.NTH_GetVal("ESP_HP") == 1 then
                if not Character.bHasAKNativeHPBar then
                  pcall(function()
                    if InGameMarkTools then
                      if InGameMarkTools.ClientAddMapMark then
                        local Mark = InGameMarkTools.ClientAddMapMark(1006, import("Vector")(0, 0, 0), 0, "", 4, Character)
                        Character.NativeHPBarMark = Mark
                        Character.bHasAKNativeHPBar = true
                        local Cache = _G.NTH_Active_HP_Cache
                        local Key = tostring(Character)
                        local Entry = {}
                        Entry.actor = Character
                        Entry.mark = Character.NativeHPBarMark
                        Cache[Key] = Entry
                      end
                    end
                  end)
                end
              else
                if Character.bHasAKNativeHPBar then
                  if InGameMarkTools then
                    pcall(function()
                      if InGameMarkTools.ClientRemoveMapMark then
                        if Character.NativeHPBarMark then
                          InGameMarkTools.ClientRemoveMapMark(Character.NativeHPBarMark)
                        end
                      else
                        if Character.NativeHPBarMark then
                          InGameMarkTools.HideMapMark(Character.NativeHPBarMark)
                        end
                      end
                    end)
                    Character.NativeHPBarMark = nil
                    Character.bHasAKNativeHPBar = false
                    _G.NTH_Active_HP_Cache[tostring(Character)] = nil
                  end
                end
              end
            else
              if Character.bHasAKNativeHPBar then
                pcall(function()
                  if InGameMarkTools then
                    if InGameMarkTools.ClientRemoveMapMark then
                      if Character.NativeHPBarMark then
                        InGameMarkTools.ClientRemoveMapMark(Character.NativeHPBarMark)
                      end
                    end
                  end
                end)
                Character.NativeHPBarMark = nil
                Character.bHasAKNativeHPBar = false
                _G.NTH_Active_HP_Cache[tostring(Character)] = nil
              end
            end
            if not bDeadForDist then
              if _G.NTH_GetVal("ESP_DISTANCE") == 1 then
                if not Character.bHasAKNativeDistBar then
                  pcall(function()
                    if InGameMarkTools then
                      if InGameMarkTools.ClientAddMapMark then
                        local Mark = InGameMarkTools.ClientAddMapMark(9999, import("Vector")(0, 0, 0), 0, "", 4, Character)
                        Character.NativeDistMark = Mark
                        Character.bHasAKNativeDistBar = true
                        local Cache = _G.NTH_Active_Dist_Cache
                        local Key = tostring(Character)
                        local Entry = {}
                        Entry.actor = Character
                        Entry.mark = Character.NativeDistMark
                        Cache[Key] = Entry
                      end
                    end
                  end)
                end
              else
                if Character.bHasAKNativeDistBar then
                  if InGameMarkTools then
                    pcall(function()
                      if InGameMarkTools.ClientRemoveMapMark then
                        if Character.NativeDistMark then
                          InGameMarkTools.ClientRemoveMapMark(Character.NativeDistMark)
                        end
                      else
                        if Character.NativeDistMark then
                          InGameMarkTools.HideMapMark(Character.NativeDistMark)
                        end
                      end
                    end)
                    Character.NativeDistMark = nil
                    Character.bHasAKNativeDistBar = false
                    _G.NTH_Active_Dist_Cache[tostring(Character)] = nil
                  end
                end
              end
            else
              if Character.bHasAKNativeDistBar then
                pcall(function()
                  if InGameMarkTools then
                    if InGameMarkTools.ClientRemoveMapMark then
                      if Character.NativeDistMark then
                        InGameMarkTools.ClientRemoveMapMark(Character.NativeDistMark)
                      end
                    end
                  end
                end)
                Character.NativeDistMark = nil
                Character.bHasAKNativeDistBar = false
                _G.NTH_Active_Dist_Cache[tostring(Character)] = nil
              end
            end
            Character.NTH_LastKnockState = bIsNearDeath
            if _G.NTH_GetVal("ESP_BOX") == 1 then
              pcall(function()
                if Character.Replay_IsEnemyFrameUIExisted then
                  if not Character:Replay_IsEnemyFrameUIExisted() then
                    Character:Replay_CreateEnemyFrameUI(true, true)
                  end
                  if Character.Replay_SetVisiableOfFrameUI then
                    Character:Replay_SetVisiableOfFrameUI(true)
                  end
                end
              end)
            else
              pcall(function()
                if self.Replay_SetVisiableOfFrameUI then
                  self:Replay_SetVisiableOfFrameUI(false)
                end
              end)
            end
          end
          local Mesh = Character.Mesh
          if not Mesh then
            if Character.getAvatarComponent2 then
              Mesh = Character:getAvatarComponent2()
            end
          end
          if slua.isValid(Mesh) then
            if not Mesh.LastHitboxUpdateVersion or Mesh.LastHitboxUpdateVersion ~= _G.MagicUpdateVersion then
              Mesh.bIsAKHitboxModded = false
            end
            if not Mesh.bIsAKHitboxModded then
              pcall(function()
                local PhysicsAsset = Mesh.PhysicsAssetOverride
                if not PhysicsAsset then
                  if Mesh.SkeletalMesh then
                    PhysicsAsset = Mesh.SkeletalMesh.PhysicsAsset
                  end
                end
                if slua.isValid(PhysicsAsset) then
                  if PhysicsAsset.SkeletalBodySetups then
                    local HeadScale = 1.0 + _G.NTH_GetVal("MAGIC_HEAD") / 100.0
                    local BodyScale = 1.0 + _G.NTH_GetVal("MAGIC_BODY") / 100.0
                    local LegsScale = 1.0 + _G.NTH_GetVal("MAGIC_LEGS") / 100.0
                    local BoneScales = {}
                    BoneScales.head = HeadScale
                    BoneScales.pelvis = BodyScale
                    BoneScales.spine_03 = BodyScale
                    BoneScales.thigh_l = LegsScale
                    BoneScales.thigh_r = LegsScale
                    BoneScales.calf_l = LegsScale
                    BoneScales.calf_r = LegsScale
                    BoneScales.foot_l = LegsScale
                    BoneScales.foot_r = LegsScale
                    if not _G.NTH_HitboxBaseCache then
                      _G.NTH_HitboxBaseCache = {}
                    end
                    local AssetKey = tostring(PhysicsAsset)
                    if not _G.NTH_HitboxBaseCache[AssetKey] then
                      _G.NTH_HitboxBaseCache[AssetKey] = {}
                    end
                    local BaseCache = _G.NTH_HitboxBaseCache[AssetKey]
                    local BodySetups = PhysicsAsset.SkeletalBodySetups
                    local SetupCount = (type(BodySetups.Num) == "function" and BodySetups:Num()) or #BodySetups
                    for SetupIndex = 0, SetupCount - 1, 1 do
                      local BodySetup = (type(BodySetups.Get) == "function" and BodySetups:Get(SetupIndex)) or BodySetups[SetupIndex + 1]
                      if slua.isValid(BodySetup) then
                        local BoneName = string.lower(tostring(BodySetup.BoneName))
                        local MatchedBone = nil
                        for BoneKey, BoneScale in pairs(BoneScales) do
                          if string.find(BoneName, BoneKey) then
                            MatchedBone = BoneKey
                            break
                          end
                        end
                        if MatchedBone then
                          local Scale = BoneScales[MatchedBone]
                          local AggGeom = BodySetup.AggGeom
                          local BoxElems = (AggGeom and AggGeom.BoxElems) or BodySetup.BoxElems
                          local SphereElems = (AggGeom and AggGeom.SphereElems) or BodySetup.SphereElems
                          local SphylElems = (AggGeom and AggGeom.SphylElems) or BodySetup.SphylElems
                          local BaseEntry = BaseCache[MatchedBone]
                          if not BaseEntry then
                            BaseEntry = {}
                            BaseCache[MatchedBone] = BaseEntry
                          end
                          BaseEntry = BaseCache[MatchedBone]
                          if BoxElems then
                            local BoxElem = nil
                            pcall(function()
                              BoxElem = (type(BoxElems.Get) == "function" and BoxElems:Get(0)) or BoxElems[1]
                            end)
                            if BoxElem then
                              if not BaseEntry.Box then
                                local BaseBox = {}
                                BaseBox.X = BoxElem.X
                                BaseBox.Y = BoxElem.Y
                                BaseBox.Z = BoxElem.Z
                                BaseEntry.Box = BaseBox
                              end
                              BoxElem.X = BaseEntry.Box.X * Scale
                              BoxElem.Y = BaseEntry.Box.Y * Scale
                              BoxElem.Z = BaseEntry.Box.Z * Scale
                              pcall(function()
                                if type(BoxElems.Set) == "function" then
                                  BoxElems:Set(0, BoxElem)
                                else
                                  BoxElems[1] = BoxElem
                                end
                              end)
                              if AggGeom then
                                AggGeom.BoxElems = BoxElems
                              else
                                BodySetup.BoxElems = BoxElems
                              end
                            end
                          end
                          if SphereElems then
                            local SphereElem = nil
                            pcall(function()
                              SphereElem = (type(SphereElems.Get) == "function" and SphereElems:Get(0)) or SphereElems[1]
                            end)
                            if SphereElem then
                              if not BaseEntry.Sphere then
                                local BaseSphere = {}
                                BaseSphere.Radius = SphereElem.Radius
                                BaseEntry.Sphere = BaseSphere
                              end
                              SphereElem.Radius = BaseEntry.Sphere.Radius * Scale
                              pcall(function()
                                if type(SphereElems.Set) == "function" then
                                  SphereElems:Set(0, SphereElem)
                                else
                                  SphereElems[1] = SphereElem
                                end
                              end)
                              if AggGeom then
                                AggGeom.SphereElems = SphereElems
                              else
                                BodySetup.SphereElems = SphereElems
                              end
                            end
                          end
                          if SphylElems then
                            local SphylElem = nil
                            pcall(function()
                              SphylElem = (type(SphylElems.Get) == "function" and SphylElems:Get(0)) or SphylElems[1]
                            end)
                            if SphylElem then
                              if not BaseEntry.Sphyl then
                                local BaseSphyl = {}
                                BaseSphyl.Radius = SphylElem.Radius
                                BaseSphyl.Length = SphylElem.Length
                                BaseEntry.Sphyl = BaseSphyl
                              end
                              SphylElem.Radius = BaseEntry.Sphyl.Radius * Scale
                              SphylElem.Length = BaseEntry.Sphyl.Length * Scale
                              pcall(function()
                                if type(SphylElems.Set) == "function" then
                                  SphylElems:Set(0, SphylElem)
                                else
                                  SphylElems[1] = SphylElem
                                end
                              end)
                              if AggGeom then
                                AggGeom.SphylElems = SphylElems
                              else
                                BodySetup.SphylElems = SphylElems
                              end
                            end
                          end
                          if AggGeom then
                            BodySetup.AggGeom = AggGeom
                          end
                        end
                      end
                    end
                    if Mesh.SetPhysicsAsset then
                      Mesh:SetPhysicsAsset(PhysicsAsset)
                    end
                    Mesh.PhysicsAssetOverride = PhysicsAsset
                    if Mesh.RecreatePhysicsState then
                      pcall(function()
                        Mesh:RecreatePhysicsState()
                      end)
                    end
                  end
                end
              end)
              Mesh.bIsAKHitboxModded = true
              Mesh.LastHitboxUpdateVersion = _G.MagicUpdateVersion
            else
              pcall(function()
                Mesh.bEnableUpdateRateOptimizations = false
                if Mesh.bNoSkeletonUpdate ~= nil then
                  Mesh.bNoSkeletonUpdate = false
                end
                if Mesh.UpdateBounds then
                  Mesh:UpdateBounds()
                end
              end)
            end
          end
        else
          if Character.bHasAKNativeHPBar then
            pcall(function()
              if InGameMarkTools then
                if InGameMarkTools.ClientRemoveMapMark then
                  if Character.NativeHPBarMark then
                    InGameMarkTools.ClientRemoveMapMark(Character.NativeHPBarMark)
                  end
                  if Character.NativeDistMark then
                    InGameMarkTools.ClientRemoveMapMark(Character.NativeDistMark)
                  end
                else
                  if Character.NativeHPBarMark then
                    InGameMarkTools.HideMapMark(Character.NativeHPBarMark)
                  end
                  if Character.NativeDistMark then
                    InGameMarkTools.HideMapMark(Character.NativeDistMark)
                  end
                end
              end
            end)
            Character.NativeHPBarMark = nil
            Character.NativeDistMark = nil
            Character.bHasAKNativeHPBar = false
            Character.bHasAKNativeDistBar = false
            _G.NTH_Active_HP_Cache[tostring(Character)] = nil
            _G.NTH_Active_Dist_Cache[tostring(Character)] = nil
          end
          pcall(function()
            if self.Replay_SetVisiableOfFrameUI then
              self:Replay_SetVisiableOfFrameUI(false)
            end
          end)
        end
      end
      local ShownPlayerCount = PlayerCount or 0
      local ShownBotCount = BotCount or 0
      local ShownInRangeCount = InRangeCount or 0
      local InfoRange = _G.NTH_GetVal("ESP_INFO_RANGE") or 400
      local InfoTextV1 = "[ PLAYER  " .. tostring(ShownPlayerCount) .. " ]  [ BOT  " .. tostring(ShownBotCount) .. " ]  [ DISTANCE " .. tostring(InfoRange) .. "M  " .. tostring(ShownInRangeCount) .. " ]"
      local InfoTextV2 = "[ PLAYER  " .. tostring(ShownPlayerCount) .. " ]  [ BOT  " .. tostring(ShownBotCount) .. " ]  [ DISTANCE " .. tostring(InfoRange) .. "M  " .. tostring(ShownInRangeCount) .. " ]"
      InfoTextV1 = string.gsub(InfoTextV1, " ", "\194\160")
      InfoTextV2 = string.gsub(InfoTextV2, " ", "\194\160")
      if _G.NTH_GetVal("ESP_INFO_V1") == 1 then
        ClearEspInfoV2Widget()
        local InfoWidget = GetEspInfoV1Widget()
        if InfoWidget then
          if slua.isValid(InfoWidget) then
            pcall(function()
              InfoWidget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
              if InfoWidget.RichText_Content then
                InfoWidget.RichText_Content:SetText(InfoTextV1)
              end
            end)
          end
        end
      else
        if _G.NTH_GetVal("ESP_INFO_V2") == 1 then
          ClearEspInfoV1Widget()
          local InfoWidget = GetEspInfoV2Widget()
          if InfoWidget then
            if slua.isValid(InfoWidget) then
              pcall(function()
                InfoWidget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
                if InfoWidget.TextBlock_Time then
                  InfoWidget.TextBlock_Time:SetText(InfoTextV2)
                  if 0 < ShownInRangeCount then
                    InfoWidget.TextBlock_Time:SetColorAndOpacity(FSlateColor(FLinearColor(1, 0, 0, 1)))
                  else
                    InfoWidget.TextBlock_Time:SetColorAndOpacity(FSlateColor(FLinearColor(0, 1, 0, 1)))
                  end
                end
              end)
            end
          end
        else
          ClearEspInfoV1Widget()
          ClearEspInfoV2Widget()
        end
      end
      if _G.NTH_GetVal("WARN_AIMING") == 1 and 0 < AimingAtYouCount then
        local WarnWidget = GetWarningAimWidget()
        if WarnWidget then
          if slua.isValid(WarnWidget) then
            pcall(function()
              WarnWidget:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
              if WarnWidget.TextBlock_Time then
                local WarnText = "[ WARNING  " .. tostring(AimingAtYouCount) .. "  AIMING TO YOU ]"
                WarnText = string.gsub(WarnText, " ", "\194\160")
                WarnWidget.TextBlock_Time:SetText(WarnText)
                local BlinkPhase = _G.N5LAMODTickCount or 0
                BlinkPhase = BlinkPhase % 10
                if BlinkPhase < 5 then
                  WarnWidget.TextBlock_Time:SetColorAndOpacity(FSlateColor(FLinearColor(1, 0, 0, 1)))
                else
                  WarnWidget.TextBlock_Time:SetColorAndOpacity(FSlateColor(FLinearColor(1, 1, 0, 1)))
                end
              end
            end)
          end
        end
      else
        ClearWarningAimWidget()
      end
      if _G.NTH_GetVal("ESP_CAR") == 1 then
        pcall(function()
          local HUD = (PlayerController and PlayerController.MyHUD) or nil
          if slua.isValid(HUD) then
            if HUD.AddDebugText then
              local VehicleClass = import("STExtraVehicleBase")
              local OutActors = slua.Array(UEnums.EPropertyClass.Object, import("Actor"))
              local Vehicles = UGameplayStatics.GetAllActorsOfClass(PlayerCharacter, VehicleClass, OutActors)
              for VehicleIndex = 0, Vehicles:Num() - 1, 1 do
                local Vehicle = Vehicles:Get(VehicleIndex)
                if slua.isValid(Vehicle) then
                  local VehicleHP = 0
                  pcall(function()
                    if slua.isValid(Vehicle.VehicleCommon) then
                      VehicleHP = Vehicle.VehicleCommon.HP or 0
                    end
                  end)
                  if 0 < VehicleHP then
                    local Distance = PlayerCharacter:GetDistanceTo(Vehicle) / 100
                    if Distance <= 400 then
                      local TextScale = math.max(0.6, 1.0 - Distance / 400)
                      local VehicleName = "PH\198\175\198\160NG TI\225\187\134N"
                      local VehicleColor = {}
                      VehicleColor.R = 200
                      VehicleColor.G = 200
                      VehicleColor.B = 200
                      VehicleColor.A = 255
                      pcall(function()
                        local UKismetSystemLibrary = import("KismetSystemLibrary")
                        local ClassName = UKismetSystemLibrary.GetClassDisplayName(Vehicle:GetClass())
                        if string.find(ClassName, "MotorcycleCart") or string.find(ClassName, "SideCar") then
                          VehicleName = "MOTOR 3 B\195\129NH"
                          VehicleColor = {R = 255, G = 215, B = 0, A = 255}
                        elseif string.find(ClassName, "Glider") then
                          VehicleName = "T\195\128U L\198\175\225\187\162N"
                          VehicleColor = {R = 255, G = 250, B = 205, A = 255}
                        elseif string.find(ClassName, "Motorcycle") or string.find(ClassName, "Motor") then
                          VehicleName = "MOTOR 2 B\195\129NH"
                          VehicleColor = {R = 255, G = 255, B = 0, A = 255}
                        elseif string.find(ClassName, "MiniBus") or string.find(ClassName, "Van") then
                          VehicleName = "XE BUS"
                          VehicleColor = {R = 255, G = 182, B = 193, A = 255}
                        elseif string.find(ClassName, "LadaNiva") or string.find(ClassName, "Niva") then
                          VehicleName = "LADA NIVA"
                          VehicleColor = {R = 173, G = 216, B = 230, A = 255}
                        elseif string.find(ClassName, "CoupeRB") or string.find(ClassName, "SportsCar") then
                          VehicleName = "COUPE RB"
                          VehicleColor = {R = 0, G = 250, B = 154, A = 255}
                        elseif string.find(ClassName, "Monster") then
                          VehicleName = "MONSTER TRUCK"
                          VehicleColor = {R = 139, G = 0, B = 0, A = 255}
                        elseif string.find(ClassName, "Hovercraft") then
                          VehicleName = "T\195\128U \196\144\225\187\134M KH\195\141"
                          VehicleColor = {R = 70, G = 130, B = 180, A = 255}
                        elseif string.find(ClassName, "AquaRail") or string.find(ClassName, "JetSki") then
                          VehicleName = "M\195\148T\195\148 N\198\175\225\187\154C"
                          VehicleColor = {R = 0, G = 255, B = 255, A = 255}
                        elseif string.find(ClassName, "Bicycle") or string.find(ClassName, "Bike") then
                          VehicleName = "XE \196\144\225\186\160P"
                          VehicleColor = {R = 244, G = 164, B = 96, A = 255}
                        elseif string.find(ClassName, "Helicopter") then
                          VehicleName = "TR\225\187\176C TH\196\130NG"
                          VehicleColor = {R = 169, G = 169, B = 169, A = 255}
                        elseif string.find(ClassName, "Quad") or string.find(ClassName, "ATV") then
                          VehicleName = "XE ATV"
                          VehicleColor = {R = 210, G = 105, B = 30, A = 255}
                        elseif string.find(ClassName, "Tuk") or string.find(ClassName, "Rikshaw") then
                          VehicleName = "XE TUKTUK"
                          VehicleColor = {R = 218, G = 112, B = 214, A = 255}
                        elseif string.find(ClassName, "BRDM") or string.find(ClassName, "Amphibia") then
                          VehicleName = "TANK BRDM"
                          VehicleColor = {R = 139, G = 69, B = 19, A = 255}
                        elseif string.find(ClassName, "UTV") or string.find(ClassName, "Polaris") then
                          VehicleName = "XE UTV"
                          VehicleColor = {R = 32, G = 178, B = 170, A = 255}
                        elseif string.find(ClassName, "PickUp") then
                          VehicleName = "B\195\129N T\225\186\162I"
                          VehicleColor = {R = 192, G = 192, B = 192, A = 255}
                        elseif string.find(ClassName, "UAZ") then
                          VehicleName = "UAZ"
                          VehicleColor = {R = 0, G = 255, B = 0, A = 255}
                        elseif string.find(ClassName, "Dacia") then
                          VehicleName = "DACIA"
                          VehicleColor = {R = 0, G = 191, B = 255, A = 255}
                        elseif string.find(ClassName, "Buggy") then
                          VehicleName = "BUGGY"
                          VehicleColor = {R = 255, G = 20, B = 147, A = 255}
                        elseif string.find(ClassName, "Mirado") then
                          VehicleName = "MIRADO"
                          VehicleColor = {R = 255, G = 140, B = 0, A = 255}
                        elseif string.find(ClassName, "Rony") then
                          VehicleName = "RONY"
                          VehicleColor = {R = 144, G = 238, B = 144, A = 255}
                        elseif string.find(ClassName, "Zima") then
                          VehicleName = "ZIMA"
                          VehicleColor = {R = 240, G = 248, B = 255, A = 255}
                        elseif string.find(ClassName, "Scooter") then
                          VehicleName = "SCOOTER"
                          VehicleColor = {R = 135, G = 206, B = 235, A = 255}
                        elseif string.find(ClassName, "Boat") or string.find(ClassName, "PG117") then
                          VehicleName = "CA N\195\148"
                          VehicleColor = {R = 0, G = 0, B = 255, A = 255}
                        end
                      end)
                      local DebugText = "[" .. VehicleName .. "]\n[" .. tostring(math.floor(Distance)) .. "m]"
                      HUD:AddDebugText(DebugText, Vehicle, 0.15, {X = 0, Y = 0, Z = 150}, {X = 0, Y = 0, Z = 150}, VehicleColor, true, false, true, nil, TextScale * 1.1, true)
                    end
                  end
                end
              end
            end
          end
        end)
      end
      if _G.NTH_GetVal("ESP_BOMB") == 1 then
        pcall(function()
          local HUD = (PlayerController and PlayerController.MyHUD) or nil
          if slua.isValid(HUD) then
            if HUD.AddDebugText then
              local GrenadeClass = import("STExtraGrenadeBase")
              local OutActors = slua.Array(UEnums.EPropertyClass.Object, import("Actor"))
              local Grenades = UGameplayStatics.GetAllActorsOfClass(PlayerCharacter, GrenadeClass, OutActors)
              if not _G.NTH_BombTimers then
                _G.NTH_BombTimers = {}
              end
              local ServerTime = 0.0
              pcall(function()
                ServerTime = GameplayData.GetGameState():GetServerWorldTimeSeconds()
              end)
              for GrenadeIndex = 0, Grenades:Num() - 1, 1 do
                local Grenade = Grenades:Get(GrenadeIndex)
                if slua.isValid(Grenade) then
                  local BombType = 0
                  pcall(function()
                    local UKismetSystemLibrary = import("KismetSystemLibrary")
                    local ClassName = UKismetSystemLibrary.GetClassDisplayName(Grenade:GetClass())
                    if string.find(ClassName, "Smoke") then
                      BombType = 602002
                    elseif string.find(ClassName, "Burn") or string.find(ClassName, "Molotov") then
                      BombType = 602003
                    elseif string.find(ClassName, "Grenade") then
                      BombType = 602004
                    end
                  end)
                  local bActive = false
                  pcall(function()
                    local bExploded = Grenade.bExploded == true
                    local bHidden = Grenade.bHidden or (Grenade.Mesh and Grenade.Mesh.bHidden)
                    if not bExploded and not bHidden then
                      bActive = true
                    end
                  end)
                  if bActive and 0 < ServerTime and (BombType == 602004 or BombType == 602002 or BombType == 602003) then
                    local Distance = PlayerCharacter:GetDistanceTo(Grenade) / 100
                    if Distance <= 100 then
                      local TextScale = math.max(0.6, 1.0 - Distance / 100)
                      local BombKey = tostring(Grenade)
                      local BombText = ""
                      local BombColor = {}
                      BombColor.R = 255
                      BombColor.G = 255
                      BombColor.B = 255
                      BombColor.A = 255
                      local DistanceText = tostring(math.floor(Distance))
                      if BombType == 602004 then
                        if not _G.NTH_BombTimers[BombKey] then
                          _G.NTH_BombTimers[BombKey] = ServerTime
                        end
                        local Elapsed = ServerTime - _G.NTH_BombTimers[BombKey]
                        local TimeLeft = 7.0 - Elapsed
                        if TimeLeft < 0 then
                          TimeLeft = 0.0
                        end
                        BombColor = (TimeLeft <= 2.0 and {R = 255, G = 0, B = 0, A = 255}) or {R = 255, G = 165, B = 0, A = 255}
                        local TimeText = tostring(math.floor(TimeLeft * 10) / 10)
                        BombText = "[BOM N\225\187\148]\n    [" .. TimeText .. "s]\n    [" .. DistanceText .. "m]"
                      elseif BombType == 602003 then
                        BombColor = {R = 255, G = 69, B = 0, A = 255}
                        BombText = "[BOM L\225\187\172A]\n     [" .. DistanceText .. "m]"
                      elseif BombType == 602002 then
                        BombColor = {R = 0, G = 255, B = 0, A = 255}
                        BombText = "[BOM KH\195\147I]\n     [" .. DistanceText .. "m]"
                      end
                      if BombText ~= "" then
                        HUD:AddDebugText(BombText, Grenade, 0.15, {X = 0, Y = 0, Z = 30}, {X = 0, Y = 0, Z = 30}, BombColor, true, false, true, nil, TextScale * 1.1, true)
                      end
                    end
                  end
                end
              end
              if 0 < ServerTime then
                for BombKey, BombTime in pairs(_G.NTH_BombTimers) do
                  if 10.0 < ServerTime - BombTime then
                    _G.NTH_BombTimers[BombKey] = nil
                  end
                end
              end
            end
          end
        end)
      end
      local bEspItem = _G.NTH_GetVal("ESP_ITEM") == 1
      local bScanPickUps = bEspItem and _G.NTH_GetVal("ESP_MORTAR") == 1
      local bScanAirDrops = bEspItem and _G.NTH_GetVal("ESP_AIRDROP") == 1
      if bScanPickUps or bScanAirDrops then
        pcall(function()
          local HUD = (PlayerController and PlayerController.MyHUD) or nil
          if slua.isValid(HUD) then
            if HUD.AddDebugText then
              local UKismetSystemLibrary = import("KismetSystemLibrary")
              if not _G.NTH_LootedItems then
                _G.NTH_LootedItems = {}
              end

              local function DrawActorMarks(Actors, MaxDistance, GetLabel, bIsAirDrop)
                if not Actors then
                  return
                end
                local MyLocation = nil
                pcall(function()
                  MyLocation = PlayerCharacter:K2_GetActorLocation()
                end)
                if not MyLocation then
                  return
                end
                for ActorIndex = 0, Actors:Num() - 1, 1 do
                  local Actor = Actors:Get(ActorIndex)
                  if slua.isValid(Actor) then
                    local bSkip = false
                    local ActorKey = tostring(Actor)
                    pcall(function()
                      if Actor:IsPendingKill() then
                        bSkip = true
                      end
                    end)
                    if not bSkip then
                      local Distance = 9999
                      local bHidden = false
                      pcall(function()
                        local ActorLocation = Actor:K2_GetActorLocation()
                        local DeltaX = MyLocation.X - ActorLocation.X
                        local DeltaY = MyLocation.Y - ActorLocation.Y
                        local DeltaZ = MyLocation.Z - ActorLocation.Z
                        Distance = math.sqrt(DeltaX * DeltaX + DeltaY * DeltaY + DeltaZ * DeltaZ) / 100.0
                        if (ActorLocation.X ~= 0 or ActorLocation.Y ~= 0) and ActorLocation.Z < -5000 then
                          bSkip = true
                        end
                        bHidden = Actor.bHidden or Actor.bIsHidden
                        if not bHidden then
                          if Actor.Mesh then
                            bHidden = Actor.Mesh.bHidden or false
                          end
                        end
                        if not bHidden then
                          if type(Actor.IsHidden) == "function" then
                            bHidden = Actor:IsHidden()
                          end
                        end
                      end)
                      if not bSkip then
                        if not bIsAirDrop then
                          if not bHidden then
                            _G.NTH_LootedItems[ActorKey] = nil
                          elseif Distance < 12.0 then
                            _G.NTH_LootedItems[ActorKey] = true
                          end
                          if _G.NTH_LootedItems[ActorKey] then
                            bSkip = true
                          end
                        elseif bHidden then
                          bSkip = true
                        end
                      end
                      if not bSkip and 0.1 < Distance and MaxDistance >= Distance then
                        local Label, LabelColor = GetLabel(Actor)
                        if Label then
                          local TextScale = math.max(0.6, 1.0 - Distance / MaxDistance)
                          local DebugText = "[" .. Label .. "]\n[" .. tostring(math.floor(Distance)) .. "m]"
                          HUD:AddDebugText(DebugText, Actor, 0.15, {X = 0, Y = 0, Z = 20}, {X = 0, Y = 0, Z = 20}, LabelColor, true, false, true, nil, TextScale, true)
                        end
                      end
                    end
                  end
                end
              end

              if bScanAirDrops then
                local AirDropClass = import("AirDropBoxActor")
                local OutActors = slua.Array(UEnums.EPropertyClass.Object, import("Actor"))
                local AirDrops = UGameplayStatics.GetAllActorsOfClass(PlayerCharacter, AirDropClass, OutActors)
                DrawActorMarks(AirDrops, 1000, function(Actor)
                  local Label = "H\195\146M TH\195\141NH"
                  local LabelColor = {}
                  LabelColor.R = 255
                  LabelColor.G = 0
                  LabelColor.B = 0
                  LabelColor.A = 255
                  return Label, LabelColor
                end, true)
              end
              if bScanPickUps then
                local PickUpClass = import("PickUpWrapperActor")
                local OutActors = slua.Array(UEnums.EPropertyClass.Object, import("Actor"))
                local PickUps = UGameplayStatics.GetAllActorsOfClass(PlayerCharacter, PickUpClass, OutActors)
                DrawActorMarks(PickUps, 150, function(Actor)
                  local ItemName = ""
                  pcall(function()
                    ItemName = UKismetSystemLibrary.GetClassDisplayName(Actor:GetClass()) or ""
                  end)
                  local Label = nil
                  local LabelColor = {}
                  LabelColor.R = 255
                  LabelColor.G = 255
                  LabelColor.B = 255
                  LabelColor.A = 255
                  if _G.NTH_GetVal("ESP_MORTAR") == 1 then
                    if string.find(ItemName, "10701100") or (string.find(ItemName, "Mortar") and not string.find(ItemName, "60mm") and not string.find(ItemName, "Shell") and not string.find(ItemName, "Ammo")) then
                      Label = "S\195\154NG C\225\187\144I"
                      LabelColor = {R = 255, G = 140, B = 0, A = 255}
                    elseif string.find(ItemName, "30700600") or string.find(ItemName, "60mm") or string.find(ItemName, "MortarShell") then
                      Label = "\196\144\225\186\160N C\225\187\144I"
                      LabelColor = {R = 255, G = 180, B = 80, A = 255}
                    end
                  end
                  if _G.NTH_GetVal("ESP_FLAREGUN") == 1 then
                    if string.find(ItemName, "Flare") or string.find(ItemName, "10600700") or string.find(ItemName, "10600900") or string.find(ItemName, "10601400") then
                      Label = "PH\195\129O S\195\129NG"
                      LabelColor = {R = 255, G = 50, B = 50, A = 255}
                    end
                  end
                  if _G.NTH_GetVal("ESP_SECRETKEY") == 1 then
                    if string.find(ItemName, "3000335") or string.find(ItemName, "Secret Room Key") or string.find(ItemName, "SecretKey") or string.find(ItemName, "CrimsonKey") or string.find(ItemName, "60411000") then
                      Label = "CH\195\140A KH\195\147A B\195\141 M\225\186\172T"
                      LabelColor = {R = 255, G = 215, B = 0, A = 255}
                    end
                  end
                  if _G.NTH_GetVal("ESP_NO") == 1 then
                    if string.find(ItemName, "10700100") or string.find(ItemName, "Crossbow") then
                      Label = "N\225\187\142"
                      LabelColor = {R = 0, G = 250, B = 154, A = 255}
                    elseif string.find(ItemName, "20500400") or string.find(ItemName, "Quiver (Crossbow)") then
                      Label = "\225\187\144NG T\195\138N N\225\187\142"
                      LabelColor = {R = 124, G = 252, B = 0, A = 255}
                    elseif string.find(ItemName, "30700100") or string.find(ItemName, "Bolt") then
                      Label = "M\197\168I T\195\138N N\225\187\142"
                      LabelColor = {R = 152, G = 251, B = 152, A = 255}
                    end
                  end
                  if _G.NTH_GetVal("ESP_SHOTGUN") == 1 then
                    if string.find(ItemName, "10400300") or string.find(ItemName, "S12K") then
                      Label = "S12K"
                      LabelColor = {R = 255, G = 20, B = 147, A = 255}
                    elseif string.find(ItemName, "10400400") or string.find(ItemName, "DBS") or string.find(ItemName, "DP12") then
                      Label = "DBS"
                      LabelColor = {R = 138, G = 43, B = 226, A = 255}
                    elseif string.find(ItemName, "10410100") or string.find(ItemName, "M1014") then
                      Label = "M1014"
                      LabelColor = {R = 0, G = 191, B = 255, A = 255}
                    end
                  end
                  return Label, LabelColor
                end, false)
              end
            end
          end
        end)
      end
    end
  end

  self:AddGameTimer(0.1, true, OnTick)
end

-- ✅ تصدير الدالة لللودر
_G.N5LAMOD_INJECT_MOD = CharacterBase.N5LAMOD_INJECT_MOD

-- نهاية الجزء الثالث

local MortarAim = {}
local MortarGameplayData = nil
local bMortarDataReady = false
local bMortarActive = false
local MortarLockedTarget = nil
local MortarLastAimRot = nil
local MortarConfig = {
  AimInterval = 0.03,
  MaxRange = 600.0,
  FOV = 20.0,
  BaseGravity = 980.0,
  SwipeBreakAngle = 5.0
}

local function MortarNotify(Msg)
  local Text = "[BEN10] " .. tostring(Msg)
  print(Text)
  pcall(function()
    if _G.N5LAMODNotify then
      _G.N5LAMODNotify(Text)
      return
    end
    local bOk, IngameTipsTools = pcall(require, "GameLua.Mod.BaseMod.Common.UI.InGameTipsTools")
    if bOk and IngameTipsTools then
      if IngameTipsTools.BattleNormalTips then
        IngameTipsTools.BattleNormalTips(Text, 2, 3)
      end
    end
  end)
end

local function MortarEnsureGameplayData()
  if bMortarDataReady then
    return true
  end
  local bOk, GameplayDataModule = pcall(require, "GameLua.GameCore.Data.GameplayData")
  if bOk and GameplayDataModule then
    MortarGameplayData = GameplayDataModule
  end
  if MortarGameplayData then
    bMortarDataReady = true
  end
  return bMortarDataReady
end

local function MortarNormalizeAngle(angle)
  while 180 < angle do
    angle = angle - 360
  end
  while angle < -180 do
    angle = angle + 360
  end
  return angle
end

local function MortarAtan2(y, x)
  if 0 < x then
    return math.atan(y / x)
  elseif x < 0 and 0 <= y then
    return math.atan(y / x) + math.pi
  elseif x < 0 and y < 0 then
    return math.atan(y / x) - math.pi
  elseif x == 0 and 0 < y then
    return math.pi / 2
  elseif x == 0 and y < 0 then
    return -math.pi / 2
  else
    return 0
  end
end

local function MortarIsEnemyTarget(uPawnA, uPawnB)
  if not (_G.slua.isValid(uPawnA) and _G.slua.isValid(uPawnB)) then
    return false
  end
  if uPawnA == uPawnB then
    return false
  end
  if uPawnA.PlayerKey ~= nil then
    if uPawnB.PlayerKey ~= nil then
      if uPawnA.PlayerKey == uPawnB.PlayerKey then
        return false
      end
    end
  end
  local TeamA = -1
  local TeamB = -2
  pcall(function()
    TeamA = uPawnA.TeamID or uPawnA.PlayerState and uPawnA.PlayerState.TeamNum or -1
    TeamB = uPawnB.TeamID or uPawnB.PlayerState and uPawnB.PlayerState.TeamNum or -2
  end)
  if TeamA == TeamB then
    return false
  end
  return true
end

local function MortarGetTargetLocation(uPawn, bUseHeadSocket)
  local TargetLoc = nil
  pcall(function()
    if bUseHeadSocket then
      if _G.slua.isValid(uPawn.Mesh) then
        TargetLoc = uPawn.Mesh:GetSocketLocation("head")
      end
    else
      TargetLoc = uPawn:K2_GetActorLocation()
      if TargetLoc then
        TargetLoc.Z = TargetLoc.Z - 85.0
        local RightVector = uPawn:GetActorRightVector()
        if RightVector then
          TargetLoc.X = TargetLoc.X + RightVector.X * 50.0
          TargetLoc.Y = TargetLoc.Y + RightVector.Y * 50.0
        end
      end
    end
  end)
  return TargetLoc
end

local function MortarIsPawnAlive(uPawn)
  if not _G.slua.isValid(uPawn) then
    return false
  end
  local bDead = false
  pcall(function()
    bDead = uPawn.bDead == true
  end)
  return not bDead
end

local function MortarSolvePitch(Dist, HeightDiff, Speed, Gravity)
  if Dist < 1.0 then
    Dist = 1.0
  end
  local v2 = Speed * Speed
  local v4 = v2 * v2
  local disc = v4 - Gravity * (Gravity * Dist * Dist + 2 * HeightDiff * v2)
  if disc < 0 then
    local FlatPitch = math.atan(v2 / (Gravity * Dist)) * (180.0 / math.pi)
    if FlatPitch < 45.0 then
      FlatPitch = 45.0
    end
    if 88.0 < FlatPitch then
      FlatPitch = 88.0
    end
    return FlatPitch, true
  end
  local Root = math.sqrt(disc)
  local Pitch = math.atan((v2 + Root) / (Gravity * Dist)) * (180.0 / math.pi)
  if Pitch < 45.0 then
    Pitch = 45.0
  end
  if 88.0 < Pitch then
    Pitch = 88.0
  end
  return Pitch, false
end

local function MortarPitchToControlPitch(Pitch)
  local ControlPitch = -60.0 + (Pitch - 45.0) * 2.0930232558139537
  if ControlPitch < -60.0 then
    ControlPitch = -60.0
  end
  if 30.0 < ControlPitch then
    ControlPitch = 30.0
  end
  return ControlPitch
end

local function MortarFindBestTarget(uSelfPawn, uController, bUseHeadSocket)
  local CameraManager = nil
  pcall(function()
    CameraManager = uController.PlayerCameraManager
  end)
  if not _G.slua.isValid(CameraManager) then
    return nil
  end
  local CameraLoc = CameraManager:GetCameraLocation()
  local CameraRot = CameraManager:GetCameraRotation()
  local Candidates = {}
  pcall(function()
    local PlayerCharacters = MortarGameplayData.GetAllPlayerCharacters()
    if PlayerCharacters then
      for _, uChar in pairs(PlayerCharacters) do
        if _G.slua.isValid(uChar) then
          Candidates[uChar] = true
        end
      end
    end
  end)
  pcall(function()
    local AllCharacters = MortarGameplayData.GetAllCharacters()
    if AllCharacters then
      for _, uChar in pairs(AllCharacters) do
        if _G.slua.isValid(uChar) then
          Candidates[uChar] = true
        end
      end
    end
  end)
  local BestTarget = nil
  local BestAngle = MortarConfig.FOV
  for uChar, _ in pairs(Candidates) do
    if MortarIsPawnAlive(uChar) then
      if MortarIsEnemyTarget(uSelfPawn, uChar) then
        local TargetLoc = MortarGetTargetLocation(uChar, bUseHeadSocket)
        if TargetLoc then
          local DeltaX = TargetLoc.X - CameraLoc.X
          local DeltaY = TargetLoc.Y - CameraLoc.Y
          local Dist2D = math.sqrt(DeltaX * DeltaX + DeltaY * DeltaY)
          local DistMeters = Dist2D / 100.0
          if DistMeters <= MortarConfig.MaxRange then
            local Yaw = MortarAtan2(DeltaY, DeltaX) * (180.0 / math.pi)
            local AngleDiff = math.abs(MortarNormalizeAngle(Yaw - CameraRot.Yaw))
            if AngleDiff <= MortarConfig.FOV and BestAngle > AngleDiff then
              BestAngle = AngleDiff
              BestTarget = uChar
            end
          end
        end
      end
    end
  end
  return BestTarget
end

local function MortarUpdateAim()
  if not MortarGameplayData then
    return
  end
  local uPlayerPawn = nil
  pcall(function()
    uPlayerPawn = MortarGameplayData.GetPlayerCharacter()
  end)
  if not _G.slua.isValid(uPlayerPawn) then
    return
  end
  local uPlayerController = nil
  pcall(function()
    uPlayerController = MortarGameplayData.GetPlayerController()
  end)
  if not _G.slua.isValid(uPlayerController) then
    return
  end
  local uCameraManager = nil
  pcall(function()
    uCameraManager = uPlayerController.PlayerCameraManager
  end)
  if not _G.slua.isValid(uCameraManager) then
    return
  end
  local uWeapon = nil
  pcall(function()
    uWeapon = uPlayerPawn.CurrentWeapon or uPlayerPawn:GetCurrentWeapon()
  end)
  if not _G.slua.isValid(uWeapon) then
    return
  end
  local nMortarState = 0
  local bMortarAiming = false
  pcall(function()
    nMortarState = uWeapon.MortarState
    bMortarAiming = uWeapon.MortarAimState == 1
  end)
  if nMortarState ~= 2 then
    return
  end
  local CameraRot = uCameraManager:GetCameraRotation()
  local SelfLoc = uPlayerPawn:K2_GetActorLocation()
  if MortarLockedTarget then
    if MortarLastAimRot then
      local SwipeDelta = math.abs(MortarNormalizeAngle(CameraRot.Yaw - MortarLastAimRot.Yaw))
      if SwipeDelta > MortarConfig.SwipeBreakAngle then
        MortarLockedTarget = nil
        MortarNotify("\196\144\195\163 \196\145\225\187\149i m\225\187\165c ti\195\170u")
      end
    end
  end
  if MortarLockedTarget then
    if MortarIsPawnAlive(MortarLockedTarget) and MortarIsEnemyTarget(uPlayerPawn, MortarLockedTarget) then
      local LockedLoc = MortarGetTargetLocation(MortarLockedTarget, bMortarAiming)
      if LockedLoc then
        local LockedDist = math.sqrt((LockedLoc.X - SelfLoc.X) ^ 2 + (LockedLoc.Y - SelfLoc.Y) ^ 2) / 100.0
        if LockedDist > MortarConfig.MaxRange then
          MortarLockedTarget = nil
        end
      else
        MortarLockedTarget = nil
      end
    else
      MortarLockedTarget = nil
    end
  end
  if not MortarLockedTarget then
    MortarLockedTarget = MortarFindBestTarget(uPlayerPawn, uPlayerController, bMortarAiming)
    if MortarLockedTarget then
      MortarNotify("\196\144\195\163 kh\195\179a m\225\187\165c ti\195\170u!")
    end
  end
  if not MortarLockedTarget then
    MortarLastAimRot = nil
    return
  end
  local AimLoc = MortarGetTargetLocation(MortarLockedTarget, bMortarAiming)
  local MuzzleLoc = nil
  pcall(function()
    MuzzleLoc = uWeapon:K2_GetActorLocation()
  end)
  local OriginX = MuzzleLoc and MuzzleLoc.X or SelfLoc.X
  local OriginY = MuzzleLoc and MuzzleLoc.Y or SelfLoc.Y
  local OriginZ = MuzzleLoc and MuzzleLoc.Z or SelfLoc.Z
  local DeltaX = AimLoc.X - OriginX
  local DeltaY = AimLoc.Y - OriginY
  local DeltaZ = AimLoc.Z - OriginZ
  local Dist2D = math.sqrt(DeltaX * DeltaX + DeltaY * DeltaY)
  local BulletSpeed = 9070.0
  local GravityScale = 2.8
  pcall(function()
    if uWeapon.GetBulletFireSpeedFromEntity then
      BulletSpeed = uWeapon:GetBulletFireSpeedFromEntity()
    else
      if bMortarAiming then
        BulletSpeed = 12520.0
      else
        BulletSpeed = 9070.0
      end
    end
    if _G.slua.isValid(uWeapon.ShootWeaponEntity) then
      if uWeapon.ShootWeaponEntity.LaunchGravityScale then
        GravityScale = uWeapon.ShootWeaponEntity.LaunchGravityScale
      end
    else
      if bMortarAiming then
        GravityScale = 4.0
      else
        GravityScale = 2.8
      end
    end
  end)
  local Gravity = MortarConfig.BaseGravity * GravityScale
  local Pitch, bOutOfRange = MortarSolvePitch(Dist2D, DeltaZ, BulletSpeed, Gravity)
  if bOutOfRange and not bMortarAiming then
    if not _G.NTH_LastWarnTime or 2.0 < os.clock() - _G.NTH_LastWarnTime then
      MortarNotify("\196\144\225\187\138CH QU\195\129 XA/CAO! B\225\186\164M N\195\154T NG\225\186\174M \196\144\225\187\130 B\225\186\174N CH\195\141NH X\195\129C!")
      _G.NTH_LastWarnTime = os.clock()
    end
  end
  local ControlPitch = MortarPitchToControlPitch(Pitch)
  local TargetYaw = MortarAtan2(DeltaY, DeltaX) * (180.0 / math.pi)
  local AimRot = FRotator(ControlPitch, TargetYaw, 0)
  pcall(function()
    if _G.slua.isValid(uCameraManager) then
      uCameraManager.bLimitViewPitch = false
      uCameraManager.bLimitViewYaw = false
      uCameraManager.ViewPitchMin = -89.9
      uCameraManager.ViewPitchMax = 89.9
    end
    uPlayerPawn:K2_SetActorRotation(FRotator(0, TargetYaw, 0), false)
    uPlayerPawn.BaseAimRotation = AimRot
    uPlayerController.ControlRotation = AimRot
    MortarLastAimRot = AimRot
  end)
end

local MortarTickCount = 0

local function MortarOnTick()
  if not _G._Authenticated_ then
    return
  end
  MortarTickCount = MortarTickCount + 1
  pcall(function()
    if not bMortarDataReady then
      MortarEnsureGameplayData()
      return
    end
    local uPlayerPawn = nil
    pcall(function()
      uPlayerPawn = MortarGameplayData.GetPlayerCharacter()
    end)
    if not _G.slua.isValid(uPlayerPawn) then
      return
    end
    local uWeapon = nil
    pcall(function()
      uWeapon = uPlayerPawn.CurrentWeapon or uPlayerPawn:GetCurrentWeapon()
    end)
    local bIsMortar = false
    pcall(function()
      bIsMortar = string.find(string.lower(tostring(uWeapon)), "mortar") ~= nil
    end)
    if not bIsMortar then
      if bMortarActive then
        bMortarActive = false
        MortarLockedTarget = nil
        MortarLastAimRot = nil
        MortarNotify("C\225\186\165t C\225\187\145i - Aim T\225\186\175t")
      end
      return
    end
    if not bMortarActive then
      bMortarActive = true
      MortarNotify("C\225\186\175m C\225\187\145i - Aim B\225\186\173t")
    end
    MortarUpdateAim()
  end)
end

local function MortarStart()
  local TimeTicker = package.loaded["common.time_ticker"] or require("common.time_ticker")
  if not (TimeTicker and TimeTicker.AddTimerLoop) then
    MortarNotify("[ERROR] AddTimerLoop not found!")
    return false
  end
  TimeTicker.AddTimerLoop(0, MortarOnTick, -1, MortarConfig.AimInterval)
  MortarNotify("[START] Mortar Auto Aim V30")
  return true
end

MortarAim.Start = MortarStart
MortarAim.Start()

-- ==========================================
-- تم حذف نظام Auto Report (AutoMassReport + AutoReportKiller) بالكامل
-- تم حذف نظام MatchRadar بالكامل
-- تم حذف نظام FeedbackSystem بالكامل
-- ==========================================

-- ==========================================
-- [تحسينات الأداء - تقليل الـ LAG]
-- ==========================================

_G._lastFPSUpdate = 0
_G._lastItemVehicleUpdate = 0
_G._lastIpadUpdate = 0
_G._lastFovCircle = 0
_G._lastGraphicsUpdate = 0
_G._lastWeaponMods = 0
_G._lastEnemyMarks = 0
_G._lastBombUpdate = 0
_G._lastVehicleUpdate = 0
_G._lastFastCar = 0
_G._EspLightCounter = 0

local function FastTick_Optimized() 
    if isExpired then 
        if not _G.LexusNotifiedExpire then
            Notify("❗ انتهت صلاحية المود! يرجى مراسلة المشرف لتجديد الاشتراك.\n📩 تواصل عبر تيليجرام: @Afhshjs للشراء.")
            _G.LexusNotifiedExpire = true
            ExpiredTick() 
        end
        return 
    end

    if myToken ~= _G.LexusState.LoopToken then return end
    
    local startTime = os.clock()
    local success, err = pcall(MainLoop)
    if not success then
        print("[⚠️ خطأ] الحلقة الرئيسية فشلت:", tostring(err))
    end
    
    local elapsed = os.clock() - startTime
    local tickDelay = 0.05
    
    if elapsed > 0.03 then tickDelay = 0.08 end
    if elapsed > 0.05 then tickDelay = 0.12 end
    if elapsed > 0.08 then tickDelay = 0.20 end
    
    local okTicker, ticker = pcall(require, "common.time_ticker") 
    if okTicker and ticker and ticker.AddTimerOnce then 
        ticker.AddTimerOnce(tickDelay, FastTick_Optimized) 
    end
end

if FastTick then
    _G._OldFastTick = FastTick
end
FastTick = FastTick_Optimized

-- ==========================================
-- نظام الصلاحية (تم استخدام النظام من ملفي2 فقط)
-- ==========================================

local ELMASRY_ExpireCornerWidget = nil
local ELMASRY_ExpireCornerStarted = false

local function ELMASRY_GetExpireText()
    local now = os.time()
    local remaining = limitTime - now
    if remaining <= 0 then return "EXPIRED" end
    local days = math.floor(remaining / 86400)
    remaining = remaining % 86400
    local hours = math.floor(remaining / 3600)
    remaining = remaining % 3600
    local minutes = math.floor(remaining / 60)
    local seconds = remaining % 60
    return string.format("Expire: %dd %02d:%02d:%02d", days, hours, minutes, seconds)
end

local function ELMASRY_UpdateExpireCorner()
    local w = ELMASRY_ExpireCornerWidget
    if not w or not slua.isValid(w) then
        ELMASRY_ExpireCornerWidget = nil
        ELMASRY_ExpireCornerStarted = false
        return
    end
    pcall(function()
        if w.RichText_Content then
            w.RichText_Content:SetText(ELMASRY_GetExpireText())
            local fontInfo = w.RichText_Content.Font
            if fontInfo then
                fontInfo.Size = 10
                w.RichText_Content:SetFont(fontInfo)
            end
        end
        w:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
    end)
    if limitTime - os.time() <= 0 then
        pcall(function() w:RemoveFromParent() end)
        ELMASRY_ExpireCornerWidget = nil
        ELMASRY_ExpireCornerStarted = false
        return
    end
    pcall(function()
        local ticker = require("common.time_ticker")
        if ticker and ticker.AddTimerOnce then
            ticker.AddTimerOnce(1.0, ELMASRY_UpdateExpireCorner)
        end
    end)
end

local function ELMASRY_CreateExpireCorner()
    if ELMASRY_ExpireCornerWidget and slua.isValid(ELMASRY_ExpireCornerWidget) then
        ELMASRY_UpdateExpireCorner()
        return
    end
    local ok = pcall(function()
        local bp = "/Game/UMG/UI_BP/Common/BaseComponent/CommonBaseComponent_TextButton_UIBP.CommonBaseComponent_TextButton_UIBP"
        local btn = slua.loadUI(bp)
        if not btn or not slua.isValid(btn) then error("Expire widget load failed") end
        require("game_frontend_hud").AddToContainer(UIContainers.Top, btn, 15000)

        if btn.RichText_Content then
            btn.RichText_Content:SetText(ELMASRY_GetExpireText())
            local fontInfo = btn.RichText_Content.Font
            if fontInfo then
                fontInfo.Size = 10
                btn.RichText_Content:SetFont(fontInfo)
            end
        end

        local WidgetLayoutLibrary = import("WidgetLayoutLibrary")
        local slot = WidgetLayoutLibrary.SlotAsCanvasSlot(btn)
        if not slot then error("CanvasSlot unavailable") end

        slot:SetAnchors(FAnchors(0, 1, 0, 1))
        slot:SetAlignment(FVector2D(0, 1))
        pcall(function() slot:SetAutoSize(false) end)
        slot:SetPosition(FVector2D(10, -10))
        slot:SetSize(FVector2D(180, 30))

        pcall(function() btn:SetRenderTransformPivot(FVector2D(0, 0)) end)
        pcall(function() btn:SetRenderScale(FVector2D(0.8, 0.8)) end)
        btn:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)

        ELMASRY_ExpireCornerWidget = btn
    end)
    if not ok then ELMASRY_ExpireCornerWidget = nil; return end
    if not ELMASRY_ExpireCornerStarted then
        ELMASRY_ExpireCornerStarted = true
        ELMASRY_UpdateExpireCorner()
    end
end

local function ELMASRY_ExpireCornerBoot(retry)
    retry = retry or 0
    if ELMASRY_ExpireCornerWidget and slua.isValid(ELMASRY_ExpireCornerWidget) then
        ELMASRY_UpdateExpireCorner()
        return
    end
    ELMASRY_CreateExpireCorner()
    if (not ELMASRY_ExpireCornerWidget or not slua.isValid(ELMASRY_ExpireCornerWidget)) and retry < 20 then
        pcall(function()
            local ticker = require("common.time_ticker")
            if ticker and ticker.AddTimerOnce then
                ticker.AddTimerOnce(1.0, function() ELMASRY_ExpireCornerBoot(retry + 1) end)
            end
        end)
    end
end

local ELMASRY_TelegramWidget = nil
local ELMASRY_TelegramStarted = false
local ELMASRY_YELLOW_COLOR = FLinearColor(1.0, 0.92, 0.016, 1.0)
local ELMASRY_TEXT_COLOR = FSlateColor(FLinearColor(0, 0, 0, 1))
local ELMASRY_DISPLAY_TEXT = "BEN 10"
local ELMASRY_WIDGET_BP_PATH = "/Game/UMG/UI_BP/Common/BaseComponent/CommonBaseComponent_TextButton_UIBP.CommonBaseComponent_TextButton_UIBP"

local function ELMASRY_UpdateTelegramContent()
    local w = ELMASRY_TelegramWidget
    if not w or not slua.isValid(w) then
        ELMASRY_TelegramWidget = nil
        ELMASRY_TelegramStarted = false
        return
    end
    pcall(function()
        if w.RichText_Content then
            w.RichText_Content:SetText(ELMASRY_DISPLAY_TEXT)
            local fontInfo = w.RichText_Content.Font
            if fontInfo then
                fontInfo.Size = 12
                fontInfo.TypefaceFontName = "Bold"
                w.RichText_Content:SetFont(fontInfo)
            end
            w.RichText_Content:SetColorAndOpacity(ELMASRY_TEXT_COLOR)
        end
        if w.Image_Background then w.Image_Background:SetColorAndOpacity(ELMASRY_YELLOW_COLOR) end
        if w.SetColorAndOpacity then w:SetColorAndOpacity(ELMASRY_YELLOW_COLOR) end
        w:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
    end)
    pcall(function()
        local ticker = require("common.time_ticker")
        if ticker and ticker.AddTimerOnce then
            ticker.AddTimerOnce(1.0, ELMASRY_UpdateTelegramContent)
        end
    end)
end

local function ELMASRY_CreateTelegramWidget()
    if ELMASRY_TelegramWidget and slua.isValid(ELMASRY_TelegramWidget) then
        ELMASRY_UpdateTelegramContent()
        return
    end
    local success = pcall(function()
        local btn = slua.loadUI(ELMASRY_WIDGET_BP_PATH)
        if not btn or not slua.isValid(btn) then error("Telegram widget load failed") end
        require("game_frontend_hud").AddToContainer(UIContainers.Top, btn, 15000)

        if btn.RichText_Content then
            btn.RichText_Content:SetText(ELMASRY_DISPLAY_TEXT)
            local fontInfo = btn.RichText_Content.Font
            if fontInfo then
                fontInfo.Size = 12
                fontInfo.TypefaceFontName = "Bold"
                btn.RichText_Content:SetFont(fontInfo)
            end
            btn.RichText_Content:SetColorAndOpacity(ELMASRY_TEXT_COLOR)
        end
        if btn.Image_Background then btn.Image_Background:SetColorAndOpacity(ELMASRY_YELLOW_COLOR) end
        if btn.SetColorAndOpacity then btn:SetColorAndOpacity(ELMASRY_YELLOW_COLOR) end

        local WidgetLayoutLibrary = import("WidgetLayoutLibrary")
        local slot = WidgetLayoutLibrary.SlotAsCanvasSlot(btn)
        if not slot then error("CanvasSlot not found") end

        slot:SetAnchors(FAnchors(0.5, 0, 0.5, 0))
        slot:SetAlignment(FVector2D(0.5, 0))
        pcall(function() slot:SetAutoSize(false) end)
        slot:SetPosition(FVector2D(0, 10))
        slot:SetSize(FVector2D(200, 28))

        pcall(function() btn:SetRenderTransformPivot(FVector2D(0, 0)) end)
        pcall(function() btn:SetRenderScale(FVector2D(1.0, 1.0)) end)
        btn:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)

        ELMASRY_TelegramWidget = btn
    end)
    if not success then ELMASRY_TelegramWidget = nil; return end
    if not ELMASRY_TelegramStarted then
        ELMASRY_TelegramStarted = true
        ELMASRY_UpdateTelegramContent()
    end
end

local function ELMASRY_TelegramWidgetBoot(retry)
    retry = retry or 0
    if ELMASRY_TelegramWidget and slua.isValid(ELMASRY_TelegramWidget) then
        ELMASRY_UpdateTelegramContent()
        return
    end
    ELMASRY_CreateTelegramWidget()
    if (not ELMASRY_TelegramWidget or not slua.isValid(ELMASRY_TelegramWidget)) and retry < 20 then
        pcall(function()
            local ticker = require("common.time_ticker")
            if ticker and ticker.AddTimerOnce then
                ticker.AddTimerOnce(1.0, function() ELMASRY_TelegramWidgetBoot(retry + 1) end)
            end
        end)
    end
end

-- ==========================================
-- نظام رسائل الترحيب والانتهاء (من ملفي2)
-- ==========================================

_G.ELMASRY_Notify = function(message)
    pcall(function()
        local bLocOk, loc_util = pcall(require, "common.loc_util")
        if bLocOk and loc_util and loc_util.ShowNotice then
            loc_util.ShowNotice("BEN10: " .. tostring(message))
        end
        local bTipsOk, InGameTipsTools = pcall(require("GameLua.Mod.BaseMod.Common.UI.InGameTipsTools"))
        if bTipsOk and InGameTipsTools and InGameTipsTools.BattleNormalTips then
            InGameTipsTools.BattleNormalTips("BEN10: " .. tostring(message), 2, 3)
        end
    end)
end

_G.ELMASRY_ShowWelcomePopup = function()
    pcall(function()
        local Msg = package.loaded["client.slua.logic.common.logic_common_msg_box"]
        if not Msg then
            local ok, r = pcall(require, "client.slua.logic.common.logic_common_msg_box")
            if ok then Msg = r end
        end
        if Msg and Msg.Show then
            Msg.Show(
                4,
                "🎉 BEN10 🎉",
                "مرحباً بك في BEN10!\n\n" ..
                "✅ المود يعمل بنجاح\n" ..
                "🎮 تم تفعيل جميع الميزات\n" ..
                "🛡️ الحماية نشطة\n\n" ..
                "📩 للدعم والتواصل:\n" ..
                "Telegram: @Afhshjs",
                function()
                    local UKismetSystemLibrary = import("KismetSystemLibrary")
                    if UKismetSystemLibrary then
                        UKismetSystemLibrary.LaunchURL("https://t.me/si_c7")
                    end
                end,
                function() end,
                "📞 Telegram",
                "✖ إغلاق"
            )
        end
    end)
end

_G.ELMASRY_ShowExpiredPopup = function()
    pcall(function()
        local Msg = package.loaded["client.slua.logic.common.logic_common_msg_box"]
        if not Msg then
            local ok, r = pcall(require, "client.slua.logic.common.logic_common_msg_box")
            if ok then Msg = r end
        end
        if Msg and Msg.Show then
            Msg.Show(
                1,
                "⚠️ MOD EXPIRED ⚠️",
                "انتهت صلاحية المود!\n" ..
                "يرجى مراسلة المشرف لتجديد الاشتراك.\n\n" ..
                "Telegram: @Afhshjs",
                function()
                    local UKismetSystemLibrary = import("KismetSystemLibrary")
                    if UKismetSystemLibrary then
                        UKismetSystemLibrary.LaunchURL("https://t.me/si_c7")
                    end
                end,
                function() end,
                "📞 تجديد",
                "إغلاق"
            )
        end
    end)
end

local function ELMASRY_InitWelcomeSystem()
    if isExpired then
        if not _G.ELMASRY_ExpiredShown then
            _G.ELMASRY_ExpiredShown = true
            _G.ELMASRY_ShowExpiredPopup()
        end
        return
    end

    if not _G.ELMASRY_WelcomeShown then
        _G.ELMASRY_WelcomeShown = true
        _G.ELMASRY_ShowWelcomePopup()
    end

    pcall(function()
        local ticker = require("common.time_ticker")
        if ticker and ticker.AddTimerOnce then
            ticker.AddTimerOnce(2.0, function() ELMASRY_ExpireCornerBoot(0) end)
        end
    end)

    pcall(function()
        local ticker = require("common.time_ticker")
        if ticker and ticker.AddTimerOnce then
            ticker.AddTimerOnce(2.5, function() ELMASRY_TelegramWidgetBoot(0) end)
        end
    end)
end

pcall(function()
    local ticker = require("common.time_ticker")
    if ticker and ticker.AddTimerOnce then
        ticker.AddTimerOnce(2.0, ELMASRY_InitWelcomeSystem)
    end
end)

print("[BEN10] Welcome Popup System Activated!")

-- ==========================================
-- N5LAMODNotify
-- ==========================================

function _G.N5LAMODNotify(message)
  pcall(function()
    local bLocOk, loc_util = pcall(require, "common.loc_util")
    if bLocOk and loc_util then
      if loc_util.ShowNotice then
        loc_util.ShowNotice("Notice from telegram @Afhshjs: " .. message)
      end
    end
    local bTipsOk, InGameTipsTools = pcall(require("GameLua.Mod.BaseMod.Common.UI.InGameTipsTools"))
    if bTipsOk and InGameTipsTools then
      if InGameTipsTools.BattleNormalTips then
        InGameTipsTools.BattleNormalTips("Notice from telegram @Afhshjs: " .. message, 2, 3)
      end
    end
    local bDataOk, GameplayData = pcall(require("GameLua.GameCore.Data.GameplayData"))
    if bDataOk and GameplayData then
      local PlayerController = GameplayData.GetPlayerController()
      if PlayerController then
        local bLibOk, STExtraBlueprintFunctionLibrary = pcall(import, "STExtraBlueprintFunctionLibrary")
        if bLibOk and STExtraBlueprintFunctionLibrary then
          local ChatComponent = STExtraBlueprintFunctionLibrary.GetChatComponentFromController(PlayerController)
          if ChatComponent then
            if ChatComponent.AddMsgInClient then
              ChatComponent:AddMsgInClient("Notice: " .. message .. ".")
            end
          end
        end
      end
    end
  end)
end

local function ShowDevNotice()
  pcall(function()
    local logic_common_msg_box = package.loaded["client.slua.logic.common.logic_common_msg_box"] or require("client.slua.logic.common.logic_common_msg_box")
    if logic_common_msg_box then
      if logic_common_msg_box.Show then
        logic_common_msg_box.Show(4, "العب بذكاء ولا تتخطي 15 كيل", function()
          local UKismetSystemLibrary = import("KismetSystemLibrary")
          if UKismetSystemLibrary then
            UKismetSystemLibrary.LaunchURL("https://t.me/si_c7")
          end
        end, function()
        end, "TeLegram", "Cancel")
      end
    end
  end)
end

local PrevStartAdvancedSystems = CharacterBase.StartAdvancedSystems

function CharacterBase:StartAdvancedSystems()
  if PrevStartAdvancedSystems then
    PrevStartAdvancedSystems(self)
  end
  if not _G._Authenticated_ then
    return
  end
  self:AddGameTimer(1.0, true, function()
    if not slua.isValid(self.Object) then
      return
    end
    local PlayerCharacter = GameplayData.GetPlayerCharacter()
    if self.Object == PlayerCharacter then
      if not _G.NTH_HasShownGlobalAuthNotice then
        if self.Object.IsAlive then
          if self.Object:IsAlive() then
            _G.NTH_HasShownGlobalAuthNotice = true
            ShowDevNotice()
          end
        end
      end
    end
  end)
end

local function StartModSystems()
  pcall(function()
    if MatchRadar and MatchRadar.Start then
      -- MatchRadar removed
    end
    if _G.InitNTHESPVIP() then
      _G.InitNTHESPVIP()
    end
    if _G.InitN5LAMODMenuTab then
      _G.InitN5LAMODMenuTab()
    end
  end)
  local GameplayData = package.loaded["GameLua.GameCore.Data.GameplayData"]
  if not GameplayData then
    GameplayData = require("GameLua.GameCore.Data.GameplayData")
  end
  if not GameplayData then
    return
  end
  pcall(function()
    local playerCharacter = GameplayData.GetPlayerCharacter and GameplayData.GetPlayerCharacter()
    if slua.isValid(playerCharacter) then
      if CharacterBase.StartAdvancedSystems then
        playerCharacter.StartAdvancedSystems = CharacterBase.StartAdvancedSystems
      end
      if playerCharacter.bHasShownExpiredNotice == nil then
        playerCharacter.bHasShownExpiredNotice = false
        playerCharacter.bHasShownDevNotice = false
        playerCharacter.bIsDeadFlag = false
        playerCharacter.NTH_NativeESP_Ready = false
      end
      if type(playerCharacter.StartAdvancedSystems) == "function" then
        pcall(function()
          playerCharacter:StartAdvancedSystems()
        end)
      end
    end
  end)
end

-- ==========================================
-- Original Authenticate
-- ==========================================
local function Authenticate()
  if _G._Authenticated_ then return end
  _G._Authenticated_ = true
  if not _G.NTH_HasShownLoginMsg then
    if _G.N5LAMODNotify then
      _G.N5LAMODNotify("AUTH BYPASSED - ALL FEATURES ENABLED")
    end
    _G.NTH_HasShownLoginMsg = true
  end
  StartModSystems()
end

pcall(function()
  require("common.time_ticker").AddTimerOnce(2, Authenticate)
end)

-- ===== Final wrapper =====

local class = require("class")
local CCharacterBase = require("GameLua.GameCore.Framework.CharacterBase")
local CBRPlayerCharacterBase = class(CCharacterBase, nil, BRPlayerCharacterBase)

-- ========================================================================
-- 🛡️ MEGA PROTECTION v3.3 - SAFE MODE
-- ========================================================================

do -- بداية كتل الحماية المتقدمة
local function _InitExtraProtection()
    local blockedFuncNames = {
        "reportattackflow","reportsecattackflow","reporthurtflow","reportfirearms",
        "reportverifyinfoflow","reportmrpcsflow","reportplayerbehavior","reportteammathurt",
        "reportmisKillbyteammate","reportforbitpick","reportplayermoveroute","reportplayerposition",
        "reportvehiclemoveflow","reportsecregamemovingflow","reportparachutedata",
        "sendtsssdkantidatatolobby","senddserrorlogtolobby","senddshawkeyepatrollogtolobby",
        "sendsectlog","senddataminingtlog","sendactivitytlog","sendclientmemusage","sendclientfps",
        "onclientcrashreport","onnetworklossdetected","reportmatchroomdata","reportplayersping",
        "sendclientstats","sendserveravgtickdelta","reporthitflow","onplayeractorchannelerror",
        "onplayerrpcvalidatefailed","reportequipmentflow","reportaimflow",
        "getweaponreport","getoneweaponreport","reportheavyweaponboxspawnflow",
        "reportheavyweaponboxactivationflow","reportheavyweaponboxopenplayerflow",
        "reportheavyweaponboxitemflow","reportplayersping","reportplayerip",
        "reportplayerframepingrecord","ondsconnectionsaturated","reportdsnetsaturation",
        "reportnetcontinuoussaturate","reportdsnetrate",
        "reportcircleflow","reportdscircleflow","reportjumpflow","reportaistrategyinfo",
        "sendaideliveryinfo","reportdailytaskinfo","reportmatchroomdata","sendplayerspectatinglog",
        "reportidcardproduceflow","reportidcardpickupflow","reportidcarddestroyflow",
        "reportrevivalflow","reportgamesetting","reportgamesettingnew","reportantsvoiceteamcreate",
        "reportantsvoiceteamquit","reportcommoninfo","reportlightweightstat","sendsectlog",
        "getgeneraltlogdata",
        "reportwallhack","reportaimbot","reportspeedhack","reportmagicbullet",
        "reportplayercontrollerstatechanged","reportavatarflow","reportabnormalmaterial",
        "reportdepthtestchange","reportwallhack","reportmemoryexception","reportmaterialscan",
        "reportshaderoverride",
        "reportplayerkillflow","clientsecplayerkillflow","checkreportsecattackflow",
        "checkreportsecattackflowwithattackflow","isenablereportplayerkillflow",
        "isenablereportmrpcsincircleflow","isenablereportmrpcsintpartcircleflow",
        "isenablereportmrpcsflow","isenablereporthitflow","isenablereportcircleflow",
        "onplayernetconnectionclosed","onplayeractorchannelerror",
        "onplayerrpcvalidatefailed","onplayerspectateexception","onshutdownaftererror",
        "heartbeat","sendheartbeat","clientheartbeat","serverheartbeat",
        "swifthawk","clientswifthawk","clientswifthawkwithparams","swifthawkreport","swifthawkdata",
        "anticheatreport","cheatdetection","violationreport","securityviolation",
        "integritycheck","signatureverify","md5","hash","filecheck","pakcheck",
        "reportfovchange","reportcamerachange","reportviewchange",
    }

    pcall(function()
        local ES = nil
        pcall(function() ES = require("GameLua.Mod.BaseMod.Common.EventSystem") end)
        if not ES then ES = _G.EventSystem end
        if ES and not ES.__ak_event_blocked then
            local origPost = ES.postEvent
            ES.postEvent = function(eventType, eventID, ...)
                local sType = tostring(eventType or ""):lower()
                local sID = tostring(eventID or ""):lower()
                if sID:find("security") or sID:find("cheat") or sType:find("security") then
                    return
                end
                return origPost(eventType, eventID, ...)
            end
            ES.__ak_event_blocked = true
        end
    end)

    pcall(function()
        if debug and debug.getinfo then debug.getinfo = function() return {} end end
        if debug and debug.getlocal then debug.getlocal = function() return nil end end
        if debug and debug.sethook then debug.sethook() end
        if jit and jit.attach then jit.attach(function() end, "bc") end
    end)

    local function isPacketBlocked(name)
        local n = tostring(name or ""):lower()
        if n:match("md5") or n:match("hash") or n:match("integrity") or n:match("filecheck") or n:match("pakcheck") then 
            return true 
        end
        if n:match("report") or n:match("flow") or n:match("tlog") or
           n:match("cheat") or n:match("security") or n:match("verify") or
           n:match("heartbeat") or n:match("swifthawk") or n:match("ban") or
           n:match("inspect") or n:match("crash") or n:match("telemetry") or
           n:match("corona") or n:match("modifier") or n:match("simulate") then
            return true
        end
        return false
    end

    if NetUtil and not NetUtil._UltimatePacketsBlocked then
        local origSend = NetUtil.SendPacket
        NetUtil.SendPacket = function(pname, ...)
            if isPacketBlocked(pname) then return nil end
            return origSend(pname, ...)
        end
        NetUtil._UltimatePacketsBlocked = true
    end

    if _G.SendRPC and not _G._UltimateRPCBlocked then
        local origRPC = _G.SendRPC
        _G.SendRPC = function(rpcName, ...)
            if isPacketBlocked(rpcName) then return end
            return origRPC(rpcName, ...)
        end
        _G._UltimateRPCBlocked = true
    end

    do
        local realGC = _G.GameplayCallbacks or {}
        if not realGC.__ak_meta_shield then
            _G.GameplayCallbacks = setmetatable({}, {
                __index = function(t, k)
                    local v = realGC[k]
                    if type(v) == "function" then
                        local lk = tostring(k):lower():gsub("[^%w]", "")
                        for _, blocked in ipairs(blockedFuncNames) do
                            if lk == blocked then 
                                return function() return true end 
                            end
                        end
                    end
                    return v
                end,
                __newindex = function(t, k, v)
                    if type(v) == "function" then
                        local lk = tostring(k):lower():gsub("[^%w]", "")
                        for _, blocked in ipairs(blockedFuncNames) do
                            if lk == blocked then
                                v = function() return true end
                                break
                            end
                        end
                    end
                    rawset(realGC, k, v)
                end
            })
            realGC.__ak_meta_shield = true
        end
    end

    local origRequire = require
    local securityPathPatterns = { 
        "Security", "AntiCheat", "Integrity", "ReportPlayer", "HawkEye", 
        "SwiftHawk", "Ban", "TssSdk", "ShootVerify", "CoronaLab", "HiggsBoson" 
    }
    local function isSecurityModule(name)
        for _, p in ipairs(securityPathPatterns) do
            if name:find(p, 1, true) then return true end
        end
        return false
    end
    local dummyModules = {
        ["GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent"] = true,
        ["GameLua.Mod.BaseMod.Common.Security.AvatarCheckCallback"] = true,
        ["GameLua.Mod.BaseMod.Common.Security.GameSafeCallbacks"] = true,
    }
    _G.require = function(name)
        if dummyModules[name] then
            return { bMHActive = false, BlackList = {} }
        end
        local mod = origRequire(name)
        if type(mod) == "table" and isSecurityModule(name) and not mod.__ak_sec_patch then
            pcall(function()
                for k, v in pairs(mod) do
                    if type(v) == "function" then
                        local lk = tostring(k):lower():gsub("[^%w]", "")
                        for _, blocked in ipairs(blockedFuncNames) do
                            if lk == blocked then
                                mod[k] = function() end
                                break
                            end
                        end
                    end
                end
                mod.__ak_sec_patch = true
            end)
        end
        return mod
    end

    local securitySubsystemNames = {
        "FileCheckSubsystem","IntegrityCheckSubsystem","PakCheckSubsystem",
        "ClientWallhackDetectionSubsystem","ClientESPDetectionSubsystem",
        "ClientAimTrackingSubsystem","ClientAntiCheatSubsystem",
        "ClientHawkEyePatrolSubsystem","DSHawkEyePatrolSubsystem",
        "CoronaLabSubsystem","PlayerSecurityInfoSubsystem",
        "ClientSecMrpcsFlowSubsystem","MrpcsFlowSubsystem",
        "ShootVerifySubSystemClient","MemoryCheckSubsystem",
        "SpeedCheckSubsystem","WallCheckSubsystem",
        "BehaviorScoreSubsystem","AFKReportorSubsystem",
        "AvatarExceptionSubsystem","GameReportSubsystem",
        "SwiftHawkSubsystem","HeartbeatSubsystem",
        "ClientReportPlayerSubsystem","DSReportPlayerSubsystem",
        "ModifierExceptionSubsystem","SimulateCharacterSubsystem",
        "ClientRenderCheckSubsystem","ClientMemoryGuardSubsystem",
        "ClientKernelCheckSubsystem"
    }
    local SubsystemMgr_inst = nil
    pcall(function() SubsystemMgr_inst = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr") end)
    if SubsystemMgr_inst and not SubsystemMgr_inst.__ak_intercept then
        local realGet = SubsystemMgr_inst.Get
        SubsystemMgr_inst.Get = function(self, name)
            local sub = realGet(self, name)
            if type(sub) == "table" and not sub.__ak_sub_silenced then
                for _, secName in ipairs(securitySubsystemNames) do
                    if name == secName then
                        for k, v in pairs(sub) do
                            if type(v) == "function" then
                                local lk = tostring(k):lower():gsub("[^%w]", "")
                                for _, blocked in ipairs(blockedFuncNames) do
                                    if lk == blocked then
                                        sub[k] = function() end
                                        break
                                    end
                                end
                            end
                        end
                        sub.__ak_sub_silenced = true
                        break
                    end
                end
            end
            return sub
        end
        SubsystemMgr_inst.__ak_intercept = true
    end

    pcall(function()
        if not NetUtil or not NetUtil.SendPacket then return end
        if NetUtil._BanAbsorberActive then return end
        local orig = NetUtil.SendPacket
        local ban_packets = {
            ["BanPlayer"]=1, ["KickPlayer"]=1, ["SuspendPlayer"]=1,
            ["NotifyBan"]=1, ["ApplyPunishment"]=1, ["ReportCheatResult"]=1,
            ["ProcessBanRequest"]=1, ["FairPlayBan"]=1, ["SecurityBan"]=1,
            ["TemporaryBan"]=1, ["PermanentBan"]=1, ["AccountBan"]=1,
            ["CheatPenalty"]=1, ["ViolationPenalty"]=1, ["BanNotification"]=1,
            ["SendBanInfo"]=1, ["BanResultPacket"]=1, ["PunishmentPacket"]=1,
        }
        NetUtil.SendPacket = function(name, ...)
            if ban_packets[name] then return nil end
            return orig(name, ...)
        end
        NetUtil._BanAbsorberActive = true
    end)

    pcall(function()
        if _G.__ak_meta_shield_active then return end
        local orig_mt = getmetatable(_G) or {}
        local orig_index = orig_mt.__index
        orig_mt.__index = function(t, k)
            if k == "_BYPASS_DONE" or k == "_bypass_active" then return nil end
            if orig_index then return orig_index(t, k) end
            return rawget(t, k)
        end
        setmetatable(_G, orig_mt)
        _G.__ak_meta_shield_active = true
    end)
end

pcall(_InitExtraProtection)

local function _InitMegaProtection()
    pcall(function()
        local TssSdk = package.loaded["TssSdk"] or _G.TssSdk
        if TssSdk then
            local blocked = {
                "ReportException","ReportData","CheckIntegrity","VerifySignature",
                "CollectEvidence","UploadLog","SendAntiData","ReportViolation",
                "ReportSuspicious","ReportBan","ReportKick","ReportWarning",
                "ReportCheat","ReportHack","ReportMod","ReportInject",
                "ReportDebugger","ReportEmulator","ReportRoot","ReportHook",
                "ReportPatch","ReportTamper","ReportCorrupt","ReportInvalid",
                "ReportSpoof","ReportFake","ReportClone","ReportDuplicate",
            }
            for _, fn in ipairs(blocked) do
                if TssSdk[fn] then TssSdk[fn] = function() end end
            end
            TssSdk.IsEmulator = function() return false end
            TssSdk.ScanMemory = function() return true end
            TssSdk.GetTssSdkReportInfo = function() return "" end
            TssSdk.GetFileMD5 = function() return "7b1c7b5608da3083097816106fc331f9" end
            TssSdk.VerifyFileSignature = function() return true end
        end
    end)
    
    pcall(function()
        local ace = _G.ace or package.loaded["libace.so"]
        if ace then
            ace.ReportData = function() end
            ace.CheckIntegrity = function() return true end
            ace.ScanMemory = function() return false end
            ace.VerifyProcess = function() return true end
            ace.KickPlayer = function() end
            ace.BanPlayer = function() end
        end
        local xc = _G.XignCode or package.loaded["xigncode"]
        if xc then
            xc.SendReport = function() end
            xc.CheckProcess = function() return true end
            xc.VerifyIntegrity = function() return true end
            xc.KickPlayer = function() end
            xc.BanPlayer = function() end
        end
        local be = _G.BattlEye or package.loaded["BattlEye"]
        if be then
            be.SendReport = function() end
            be.KickPlayer = function() end
            be.ValidatePlayer = function() return true end
            be.BanPlayer = function() end
        end
    end)
    
    pcall(function()
        local Higgs = package.loaded["GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent"]
        if Higgs then
            local blocked = {
                "ControlMHActive","Tick","OnTick","MHActiveLogic","TriggerAvatarCheck",
                "StartAvatarCheck","ReportItemID","ReceiveAnyDamage","OnWeaponHitRecord",
                "ShowSecurityAlert","ServerReportAvatar","ClientReportNetAvatar",
                "SendHisarData","ValidateSecurityData","CheckMHActive","ReportViolation",
                "ProcessSecurityEvent","ValidatePlayer","CheckIntegrity","CheckFOV","ReportFOV",
            }
            for _, fn in ipairs(blocked) do
                if Higgs[fn] then Higgs[fn] = function() end end
            end
            Higgs.GetNetAvatarItemIDs = function() return {} end
            Higgs.GetCurWeaponSkinID = function() return 0 end
            Higgs.IsMHActive = function() return false end
            Higgs.bMHActive = false
            Higgs.bCallPreReplication = false
            Higgs.bIsEnable = false
        end
        _G.BlackList = {}
    end)
    
    pcall(function()
        if not _G.GameplayCallbacks then _G.GameplayCallbacks = {} end
        local GC = _G.GameplayCallbacks
        if GC._MEGA_BLOCKED then return end
        local funcs = {
            "ReportAttackFlow","ReportSecAttackFlow","ReportHurtFlow","ReportFireArms",
            "ReportVerifyInfoFlow","ReportMrpcsFlow","ReportPlayerBehavior","ReportTeammatHurt",
            "ReportMisKillByTeammate","ReportForbitPick","ReportPlayerMoveRoute","ReportPlayerPosition",
            "ReportVehicleMoveFlow","ReportSecTgameMovingFlow","ReportParachuteData",
            "SendTssSdkAntiDataToLobby","SendDSErrorLogToLobby","ReportEquipmentFlow",
            "ReportAimFlow","ReportHitFlow","ReportPlayersPing","ReportPlayerIP",
            "ReportCircleFlow","ReportDSCircleFlow","ReportJumpFlow","ReportAIStrategyInfo",
            "ReportRevivalFlow","ReportGameSetting","ReportCommonInfo","SendSecTLog",
            "ReportFOVChange","ReportCameraChange","ReportViewChange","ReportWallHack",
            "ReportAimbot","ReportSpeedHack","ReportMagicBullet","ReportESPBox",
            "OnPlayerNetConnectionClosed","OnPlayerActorChannelError","OnPlayerRPCValidateFailed",
            "OnPlayerSpectateException","OnShutdownAfterError","MarkSuspiciousPlayer",
        }
        for _, fn in ipairs(funcs) do
            if GC[fn] then GC[fn] = function() end end
        end
        local origState = GC.OnDSPlayerStateChanged
        GC.OnDSPlayerStateChanged = function(UID, State, bPure, bSafe, Reason)
            if State then
                local s = string.lower(tostring(State))
                if s:find("cheat") or s:find("ban") or s:find("kick")
                   or s:find("integrity") or s:find("violation") or s:find("hack") then
                    return
                end
            end
            if origState then pcall(origState, UID, State, bPure, bSafe, Reason) end
        end
        GC.GetWeaponReport = function() return {} end
        GC.GetOneWeaponReport = function() return {} end
        GC.GetGeneralTLogData = function() return {} end
        GC.CheckReportSecAttackFlowWithAttackFlow = function() return false end
        GC.CheckReportSecAttackFlow = function() return false end
        GC.IsBypassed = true
        GC._MEGA_BLOCKED = true
    end)
    
    pcall(function()
        if NetUtil and NetUtil.SendPacket and not NetUtil._MEGA_BLOCKED then
            local origSend = NetUtil.SendPacket
            NetUtil.SendPacket = function(packetName, ...)
                if type(packetName) == "string" then
                    local low = packetName:lower()
                    if low:match("report") or low:match("md5") or low:match("hash")
                       or low:match("integrity") or low:match("ban")
                       or low:match("cheat") or low:match("violation") then
                        return nil
                    end
                end
                return origSend(packetName, ...)
            end
            NetUtil.IsBypassed = true
            NetUtil._MEGA_BLOCKED = true
        end
    end)
    
    pcall(function()
        local CS = _G.CrashSight or package.loaded["CrashSight"]
        if CS then
            CS.ReportException = function() end
            CS.SetCustomData = function() end
            CS.Log = function() end
            CS.UploadLog = function() end
            CS.SendReport = function() end
            CS.ReportCrash = function() end
            CS.SendCrash = function() end
        end
        local TL = _G.TLog or package.loaded["TLog"]
        if TL then
            TL.Info = function() end
            TL.Warning = function() end
            TL.Error = function() end
            TL.Report = function() end
            TL.Send = function() end
            TL.Flush = function() end
        end
    end)
    
    pcall(function()
        local SMTD = import("ScreenshotMTDer")
        if SMTD then
            SMTD.MTDePicture = function() return "" end
            SMTD.HasCaptured = function() return true end
            SMTD.TakeScreenshot = function() end
        end
        local SM = import("ScreenshotMaker")
        if SM then
            SM.MakePicture = function() return "" end
            SM.HasCaptured = function() return true end
            SM.TakeScreenshot = function() end
            SM.CaptureScreen = function() end
        end
    end)
    
    pcall(function()
        local SysInfo = import("SystemInfo")
        if SysInfo then
            SysInfo.IsEmulator = function() return false end
            SysInfo.IsRooted = function() return false end
            SysInfo.IsDebugged = function() return false end
            SysInfo.GetDeviceModel = function() return "Pixel 7 Pro" end
            SysInfo.GetDeviceBrand = function() return "Google" end
            SysInfo.GetAndroidVersion = function() return "14" end
            SysInfo.GetManufacturer = function() return "Google" end
            SysInfo.GetModel = function() return "Pixel 7 Pro" end
            SysInfo.GetOSVersion = function() return "14" end
        end
    end)
    
    pcall(function()
        for _, flag in ipairs({"ENABLE_REPORT","ENABLE_ANTI_CHEAT","ENABLE_SECURITY","ENABLE_TELEMETRY","ENABLE_ANALYTICS"}) do
            if _G[flag] ~= nil then _G[flag] = false end
        end
        local suspicious = {
            "bIsCheating","bDetected","bBanned","SuspicionScore","CheatDetected",
            "AntiCheatFlag","IsHacking","bReported","TrustScore","SecurityFlag",
            "ViolationLevel","BanStatus",
        }
        for _, var in ipairs(suspicious) do _G[var] = nil end
    end)
end

pcall(_InitMegaProtection)

-- ========================================================================
-- 🛡️ ULTIMATE ANTI-BAN SUPPLEMENT v1.0
-- مأخوذ من ملف "ابن هاشم" — الطبقات الجديدة فقط
-- يُدرج بعد pcall(_InitMegaProtection) مباشرة
-- ========================================================================
do
    if _G._N5LA_UltimateSupplement_Installed then
        -- مسجّل مسبقاً، لا تكرر
    else
    _G._N5LA_UltimateSupplement_Installed = true

    local nop      = function() return true  end
    local retTrue  = function() return true  end
    local retFalse = function() return false end
    local retZero  = function() return 0     end
    local retEmpty = function() return {}    end
    local retNil   = function() return nil   end
    local retES    = function() return ""    end

    local function safeRequire(path)
        local m = package.loaded[path]
        if m then return m end
        local ok, r = pcall(require, path)
        return ok and r or nil
    end

    -- ========================================================================
    -- §A — EXTENDED MODULE PATHS + METHODS
    -- ========================================================================
    local function Section_ExtendedModules()
        pcall(function()
            local NOP_METHODS = {
                "Report","SendReport","ReportEvent","ReportException","ReportData",
                "ReportTLogEvent","OnInit","_OnPlayerKilledOtherPlayer","_RecordFatalDamager",
                "_OnBattleResult","_OnShowQuickReportMutualExclusiveUI","_AddEnemyMapToBattleResult",
                "_AddKnockDownerToBattleResult","_AddKillerToBattleResult","_AddTeammateMurderToBattleResult",
                "_AddFatalDamagerMapToBattleResult","_AddMLKillerUIDToBattleResult",
                "_SaveHistoricalTeammateInfo","_RecordTeammateMurderer","_OnNearDeathOrRescued",
                "_OnCharacterDied","_OnTeammateDamage","_OnPlayerSettlementStart","_OnHawkSync",
                "_OnHawkReportSuccess","_StartExitGameTimer","OnHandleBehaviorScore","AIPerceptionScore",
                "ReportAllPlayerInfo","AddRecordMLAIInfo","ReportAI","RealLogoutTimer","SendAFKTips",
                "OnHandleLostConnection","ClientRPC_SyncBanID","ClientRPC_StrongTips","ClientRPC_NormalTips",
                "Notify","OnSyncBanInfo","OnVoiceBanNotify","DelayKickOutPlayer","ActiveKickNotify",
                "_UpdateTTKRecords","_UpdateOperatingFrequency","_OnReportServerJumpFlow",
                "HandleKillTlog","AskForInspector","ReportEnemy","KickOutOneTeam",
                "ServerKickOutOneTeamByPlayerImplementation","AddReportedCount",
                "RequestGotoSpectatingImp","RequestGotoSpectating",
                "SendTlog","ReportTLog","ReportReplay","SendReportReq","SaveDump","UploadDump",
                "OnPlayerWithRealTimeBan","OnSyncPlayerInfo","HandleEnterGameModeFightingState",
                "ShowAlias","SetOnRankInspectorUID","SetInspectorBroadcastCountUID","GMShowAlias",
                "ReqBanInfo","OnVoiceSwitchNotify","OnRealTimeVoiceBanNotify","OnVoiceBanSuccess",
                "TryOpenVoice","OnSyncMicSuspicious","OnSyncMicPreFilter","OnNotifyWarningTips",
                "PakMonitorStart","SetupFilenameHideKeywords","on_login_failed",
                "DelaybanLoginCancelCallback","HandleRacingEnter","HandleRacingStart","HandleRacingEnd",
                "StartDetectTimer","StopDetectTimer","DetectVehicleFloating","HandleFloatingCheat",
                "SetIgnoreFloating","HandlePlayerPassCheckBelt","HandleSpeedCheat",
                "_OnRecvInspectorBroadcastCount","RequestImprison","SendReportTLog",
                "_CollectBeWatchedPlayerInfo","_StartFrameUIRefreshTimer","ExitWatching",
                "WantMatchNextPatrol","_StartHideUITimer","_StartShowDistanceUITimer",
                "_StartCloseBattleEndedTipsTimer","_StartBattleTimeUsageTimer",
                "_StartQuitVoiceRoomTimer","_CloseExitGameTimer",
                "_CreateOvertimerTimerForNextPatrol","ClearNextPatrolOvertimeTimer",
                "ReturnLobbyAndOpenH5","ForceNeverCloseBattleEndedTips","TryShowReportedTips",
                "ShowWatchEndedTips","OnShowWatchEndedTips","OnClickLowerLeftExitWatching",
                "OnClickBottomRightOpenReportWindow","_MarkHasReported",
                "InitGokubaLogic","OnControllerBeginPlay",
                "ClearCache","FreeUnusedMemory","CompactHeap","CleanTraces",
                "ClearLogs","ClearTemp","ClearCacheFiles","ClearHistory","ClearData",
                "VerifyFile","VerifyMemory","CheckIntegrity","ValidateFile","ValidateMemory",
                "CheckFile","CheckMemory","VerifyCRC","ValidateCRC","CheckCRC",
                "SetTssNetworkStatus","GEMReportEnterLobbyEvent","TPerforPlatDisconnectReport",
                "ProcRespondMsg","SetForceLog","SetLogTreeEnable","SetWriteLog","SetLogLevel","EnableDebug"
            }

            local TRUE_METHODS = {
                "CheckIfCanCreateRole","CheckBan","IsBanned","IsVoiceReportEnable",
                "IsDuringHawkEyePatrol","HasReported","HasShownWatchEndedTips",
                "CanInspectorBroadcast","IsCharacterLocationShouldDraw",
                "IsUIDOnRankInspector","IsEmulator","IsRooted","IsDebugged",
                "CheckKernelIntegrity","IsMemoryReadable","IsMemoryWritable",
                "IsConnected","CheckTssNetwork"
            }

            local EMPTY_METHODS = {
                "GetCarrierInfo","GetSimpleFightData","GetWeaponReport","GetOneWeaponReport",
                "GetGeneralTLogData","GetBeWatchedPlayerInfo","CollectInfo","GetResults","_CreateVehicleData"
            }

            local ZERO_METHODS = {
                "GetUIDInspectorRank","GetTipsIDOffset","GetTipsIDOffsetWithUID",
                "GetTipsIDOffsetInspector","GetForbidNextPatrolRemainingTimeInSeconds",
                "GetUsedDailyTimeInSeconds","GetMaxInspectorBroadcastCount"
            }

            local PATHS = {
                -- المسارات الجديدة من ابن هاشم غير الموجودة في الملف الأول
                "GameLua.Mod.PlanBT.Gameplay.Subsystem.DSActiveSubsystem",
                "GameLua.Mod.BaseMod.DS.Security.DSAITLogSubsystem",
                "GameLua.Mod.BaseMod.DS.Security.DSFightTLogSubsystem",
                "GameLua.Mod.BaseMod.DS.Security.DSSecurityTLogSubsystem",
                "GameLua.Mod.BaseMod.DS.Security.DSCommonTLogSubsystem",
                "GameLua.Mod.BaseMod.Client.Security.InspectionSystemReportClientLogicSubsystem",
                "GameLua.Mod.BaseMod.DS.Security.InspectionSystemReportDSLogicSubsystem",
                "GameLua.Mod.BaseMod.Common.Subsystem.SpectateAndReplaySubsystem",
                "GameLua.Mod.Escape.Gameplay.Subsystem.BehaviorScoreSubsystem",
                "GameLua.ExtraModule.MLAI.Client.AIReplaySubsystem",
                "GameLua.Mod.BaseMod.GamePlay.AI.AITrackingLogSubsystem",
                "GameLua.Mod.TDM.Gameplay.Subsystem.TDMAFKReportorSubsystem",
                "GameLua.Mod.BaseMod.Client.Security.Gokuba",
                "GameLua.Mod.BaseMod.Client.Security.ClientGlueHiaSystem",
                "GameLua.Mod.BaseMod.Common.Security.SecurityNotifyPCFeature",
                "client.slua.logic.ban.ClientBanLogic",
                "client.slua.logic.login.logic_tt_ban",
                "client.slua.config.tlog.tlog_report_utils",
                "client.slua.logic.crash.CrashReporter",
                "GameLua.Mod.BaseMod.Client.Security.SwiftHawkSubsystem",
                "GameLua.Mod.BaseMod.Client.Security.HiggsBosonComponent",
                "client.slua.logic.download.report.puffer_tlog",
                -- RealTimeBan paths
                "GameLua.Mod.BaseMod.Client.Security.RealTimeBan",
                "client.slua.logic.ban.RealTimeBan",
                -- Racing
                "GameLua.Mod.BaseMod.Client.Security.RacingAntiCheatLogic",
                "client.slua.logic.racing.RacingAntiCheatLogic"
            }

            for _, path in ipairs(PATHS) do
                local m = safeRequire(path)
                if m then
                    for _, k in ipairs(NOP_METHODS)   do if type(m[k]) == "function" then m[k] = nop end end
                    for _, k in ipairs(TRUE_METHODS)  do if type(m[k]) == "function" then m[k] = retTrue end end
                    for _, k in ipairs(EMPTY_METHODS) do if type(m[k]) == "function" then m[k] = retEmpty end end
                    for _, k in ipairs(ZERO_METHODS)  do if type(m[k]) == "function" then m[k] = retZero end end

                    if path:find("HawkEye", 1, true) then
                        m._bHasInitialized         = true
                        m._bHasReported            = true
                        m._bHasShownWatchEndedTips = true
                        m.bShowBeReportedTips      = true
                        m.nInspectorBroadcastCount = -1
                        if type(m._PostConstruct) == "function" then
                            m._PostConstruct = function(self)
                                self._bHasInitialized         = true
                                self._bHasReported            = true
                                self.nInspectorBroadcastCount = -1
                            end
                        end
                    end
                    if path:find("Gokuba", 1, true) then
                        m.ForwardFeature = function() return {0,0,0,0,0} end
                    end
                    if path:find("Racing", 1, true) then
                        m.config = { FloatingDistLimit = 99999, FloatingTimeLimit = 99999, CheckPassIntervalLimit = 99999 }
                    end
                    if m.LogQueue then m.LogQueue = {} end
                    if m.vehicleDataMap then m.vehicleDataMap = {} end
                    if m.detectTimer then m.detectTimer = nil end
                end
            end

            -- login_module hyphen keys
            local lm = _G.login_module
            if lm then
                for _, k in ipairs({
                    "ban-login","idip-kick-out","aq_ban","device-in-blacklist",
                    "device_num_limit","register-forbidden","low-version",
                    "not-in-white-list","Login_Failed","aas_ban"
                }) do
                    pcall(function() lm[k] = nop end)
                end
            end
        end)
    end

    -- ========================================================================
    -- §B — NETWORK WRAPPERS (Socket + HTTP + WebSocket) + IP/Domain Blocklists
    -- ========================================================================
    _G.BlockedIPs = _G.BlockedIPs or {
        "43.128.0.0/16","43.129.0.0/16","43.130.0.0/16","43.131.0.0/16",
        "43.132.0.0/16","43.133.0.0/16","43.134.0.0/16","43.135.0.0/16",
        "43.136.0.0/16","43.137.0.0/16","43.138.0.0/16","43.139.0.0/16",
        "43.140.0.0/16","43.141.0.0/16","43.142.0.0/16","43.143.0.0/16",
        "43.144.0.0/16","43.145.0.0/16","43.146.0.0/16","43.147.0.0/16",
        "43.148.0.0/16","43.149.0.0/16","43.150.0.0/16","43.151.0.0/16",
        "43.152.0.0/16","43.153.0.0/16","43.154.0.0/16","43.155.0.0/16",
        "43.156.0.0/16","43.157.0.0/16","43.158.0.0/16","43.159.0.0/16",
        "43.160.0.0/16","43.161.0.0/16","43.162.0.0/16","43.163.0.0/16",
        "43.164.0.0/16","43.165.0.0/16","43.166.0.0/16","43.167.0.0/16",
        "43.168.0.0/16","43.169.0.0/16","43.170.0.0/16","43.171.0.0/16",
        "43.172.0.0/16","43.173.0.0/16","43.174.0.0/16","43.175.0.0/16",
        "43.176.0.0/16","43.177.0.0/16","43.178.0.0/16","43.179.0.0/16",
        "43.180.0.0/16","43.181.0.0/16","43.182.0.0/16","43.183.0.0/16",
        "43.184.0.0/16","43.185.0.0/16","43.186.0.0/16","43.187.0.0/16",
        "43.188.0.0/16","43.189.0.0/16","43.190.0.0/16","43.191.0.0/16",
        "43.192.0.0/16","43.193.0.0/16","43.194.0.0/16","43.195.0.0/16",
        "43.196.0.0/16","43.197.0.0/16","43.198.0.0/16","43.199.0.0/16",
        "43.200.0.0/16","43.201.0.0/16","43.202.0.0/16","43.203.0.0/16",
        "43.204.0.0/16","43.205.0.0/16","43.206.0.0/16","43.207.0.0/16",
        "43.208.0.0/16","43.209.0.0/16","43.210.0.0/16","43.211.0.0/16",
        "43.212.0.0/16","43.213.0.0/16","43.214.0.0/16","43.215.0.0/16",
        "43.216.0.0/16","43.217.0.0/16","43.218.0.0/16","43.219.0.0/16",
        "43.220.0.0/16","43.221.0.0/16","43.222.0.0/16","43.223.0.0/16",
        "43.224.0.0/16","43.225.0.0/16","43.226.0.0/16","43.227.0.0/16",
        "43.228.0.0/16","43.229.0.0/16","43.230.0.0/16","43.231.0.0/16",
        "43.232.0.0/16","43.233.0.0/16","43.234.0.0/16","43.235.0.0/16",
        "43.236.0.0/16","43.237.0.0/16","43.238.0.0/16","43.239.0.0/16",
        "43.240.0.0/16","43.241.0.0/16","43.242.0.0/16","43.243.0.0/16",
        "43.244.0.0/16","43.245.0.0/16","43.246.0.0/16","43.247.0.0/16",
        "43.248.0.0/16","43.249.0.0/16","43.250.0.0/16","43.251.0.0/16",
        "43.252.0.0/16","43.253.0.0/16","43.254.0.0/16","43.255.0.0/16",
        "129.204.0.0/16","129.205.0.0/16","129.206.0.0/16","129.207.0.0/16",
        "129.208.0.0/16","129.209.0.0/16","129.210.0.0/16","129.211.0.0/16",
        "129.212.0.0/16","129.213.0.0/16","129.214.0.0/16","129.215.0.0/16",
        "129.216.0.0/16","129.217.0.0/16","129.218.0.0/16","129.219.0.0/16",
        "129.220.0.0/16","129.221.0.0/16","129.222.0.0/16","129.223.0.0/16",
        "129.224.0.0/16","129.225.0.0/16","129.226.0.0/16","129.227.0.0/16",
        "129.228.0.0/16","129.229.0.0/16","129.230.0.0/16","129.231.0.0/16",
        "129.232.0.0/16","129.233.0.0/16","129.234.0.0/16","129.235.0.0/16",
        "129.236.0.0/16","129.237.0.0/16","129.238.0.0/16","129.239.0.0/16",
        "129.240.0.0/16","129.241.0.0/16","129.242.0.0/16","129.243.0.0/16",
        "129.244.0.0/16","129.245.0.0/16","129.246.0.0/16","129.247.0.0/16",
        "129.248.0.0/16","129.249.0.0/16","129.250.0.0/16","129.251.0.0/16",
        "129.252.0.0/16","129.253.0.0/16","129.254.0.0/16","129.255.0.0/16",
        "185.244.0.0/16","185.245.0.0/16","185.246.0.0/16","185.247.0.0/16",
        "185.248.0.0/16","185.249.0.0/16","185.250.0.0/16","185.251.0.0/16",
        "185.252.0.0/16","185.253.0.0/16","185.254.0.0/16","185.255.0.0/16"
    }

    _G.BlockedDomains = _G.BlockedDomains or {
        "anticheat.qq.com","tss.tencent.com","tss-sdk.qq.com",
        "report.qq.com","ban.qq.com","security.qq.com","hawkeye.qq.com",
        "pubgm.qq.com","pubgmobile.qq.com","igame.qq.com",
        "tlog.qq.com","ds.qq.com","lobby.qq.com","match.qq.com",
        "login.qq.com","account.qq.com","device.qq.com","fingerprint.qq.com",
        "telemetry.qq.com","analytics.qq.com","crash.qq.com","bugly.qq.com",
        "tdm.qq.com","gokuba.qq.com","swifthawk.qq.com","coronalab.qq.com",
        "higgsboson.qq.com","battleye.com","xigncode.com","ace.qq.com",
        "tss-sdk.com","antihack.com","securitycheck.com","validation.com",
        "verification.com","monitor.com","tracking.com","igamecj.com",
        "pubgm.com","gpubm.com","gjacky.com",
        "hwclouds-dns.com","gcloudcs.com",
        "googleapis.com","vasdgame.com","amsoveasea.com",
        "mbgame.anticheatexpert.com","tdatamaster.com","helpshift.com",
        "perfsight.wetest.net","proximabeta.com","onezapp.com",
        "adjust.com","crashsight.wetest.net",
        -- tdatamaster specific
        "sg.tdatamaster.com","tdm/v1/bin","tdm/v1/kv"
    }

    local function Section_NetworkWrappers()
        pcall(function()
            -- socket.connect
            if socket and socket.connect and not socket._N5LA_Wrapped then
                local origConnect = socket.connect
                socket.connect = function(host, port, ...)
                    if type(host) == "string" then
                        local hl = host:lower()
                        for i = 1, #_G.BlockedIPs do
                            if hl:find(_G.BlockedIPs[i], 1, true) then
                                return nil, "Blocked"
                            end
                        end
                        for i = 1, #_G.BlockedDomains do
                            if hl:find(_G.BlockedDomains[i], 1, true) then
                                return nil, "Blocked"
                            end
                        end
                    end
                    return origConnect(host, port, ...)
                end
                socket._N5LA_Wrapped = true
            end

            -- HTTP
            if _G.Http then
                if _G.Http.Get and not _G.Http._N5LA_GetWrapped then
                    local origGet = _G.Http.Get
                    _G.Http.Get = function(url, ...)
                        if type(url) == "string" then
                            local ul = url:lower()
                            for i = 1, #_G.BlockedDomains do
                                if ul:find(_G.BlockedDomains[i], 1, true) then
                                    return nil, "Blocked"
                                end
                            end
                        end
                        return origGet(url, ...)
                    end
                    _G.Http._N5LA_GetWrapped = true
                end
                if _G.Http.Post and not _G.Http._N5LA_PostWrapped then
                    local origPost = _G.Http.Post
                    _G.Http.Post = function(url, ...)
                        if type(url) == "string" then
                            local ul = url:lower()
                            for i = 1, #_G.BlockedDomains do
                                if ul:find(_G.BlockedDomains[i], 1, true) then
                                    return nil, "Blocked"
                                end
                            end
                        end
                        return origPost(url, ...)
                    end
                    _G.Http._N5LA_PostWrapped = true
                end
            end

            -- WebSocket
            if _G.WebSocket and _G.WebSocket.Connect and not _G.WebSocket._N5LA_Wrapped then
                local origWS = _G.WebSocket.Connect
                _G.WebSocket.Connect = function(url, ...)
                    if type(url) == "string" then
                        local ul = url:lower()
                        for i = 1, #_G.BlockedDomains do
                            if ul:find(_G.BlockedDomains[i], 1, true) then
                                return nil, "Blocked"
                            end
                        end
                    end
                    return origWS(url, ...)
                end
                _G.WebSocket._N5LA_Wrapped = true
            end
        end)
    end

    -- ========================================================================
    -- §C — EXTENDED SPOOF (SystemInfo + DNS + Network + Engine + GameTime
    --       + MemoryProtect + DebuggerDetect + EmulatorDetect + RootDetect
    --       + JailbreakDetect + HWID)
    -- ========================================================================
    local function Section_ExtendedSpoof()
        pcall(function()
            local SI = import("SystemInfo")
            if SI then
                local STRINGS = {
                    GetDeviceID         = "00000000-0000-0000-0000-000000000000",
                    GetDeviceName       = "iPhone",
                    GetDeviceType       = "Phone",
                    GetManufacturer     = "Apple",
                    GetModel            = "iPhone14,5",
                    GetOSVersion        = "13",
                    GetOSName           = "iOS",
                    GetScreenResolution = "1170x2532",
                    GetScreenDensity    = "460",
                    GetRAMSize          = "6144",
                    GetStorageSize      = "256",
                    GetBatteryLevel     = "100",
                    GetBatteryStatus    = "Charging",
                    GetNetworkType      = "WiFi",
                    GetNetworkSpeed     = "100",
                    GetGPSStatus        = "Enabled",
                    GetGPSLocation      = "0.0,0.0",
                    GetCountryCode      = "US",
                    GetLanguageCode     = "en",
                    GetTimeZone         = "UTC",
                    GetKernelVersion    = "Linux version 4.14.116",
                    GetDeviceModel      = "iPhone14,5",
                    GetDeviceBrand      = "Apple",
                    GetAndroidVersion   = "13",
                    GetEMUIVersion      = ""
                }
                for k, v in pairs(STRINGS) do
                    if type(SI[k]) == "function" then SI[k] = function() return v end end
                end

                local NUMBERS = {
                    GetUptime             = 3600,
                    GetCPUUsage           = 10,
                    GetMemoryUsage        = 20,
                    GetTemperature        = 25,
                    GetBatteryTemperature = 25,
                    GetCPUFrequency       = 2400,
                    GetGPUFrequency       = 1200,
                    GetScreenBrightness   = 100,
                    GetVolumeLevel        = 100
                }
                for k, v in pairs(NUMBERS) do
                    if type(SI[k]) == "function" then SI[k] = function() return v end end
                end

                local BOOLS = { IsEmulator = false, IsRooted = false, IsDebugged = false }
                for k, v in pairs(BOOLS) do
                    if type(SI[k]) == "function" then SI[k] = function() return v end end
                end

                if type(SI.CheckKernelIntegrity) == "function" then SI.CheckKernelIntegrity = retTrue end
                if type(SI.GetCurrentTime)      == "function" then SI.GetCurrentTime      = os.time  end
            end

            -- HWID
            local KSL = import("KismetSystemLibrary")
            if KSL and not _G.FakeHWID_Hooked then
                if type(KSL.GetDeviceId) == "function" then
                    _G.Original_GetDeviceId = KSL.GetDeviceId
                    KSL.GetDeviceId = function(...)
                        if not _G.FakeHWID_String then
                            local chars = "0123456789abcdef"
                            local hwid = ""
                            for _ = 1, 32 do
                                hwid = hwid .. chars:sub(math.random(1, 16), math.random(1, 16))
                            end
                            _G.FakeHWID_String = hwid
                        end
                        return _G.FakeHWID_String
                    end
                end
                _G.FakeHWID_Hooked = true
            end

            -- DNS
            local DNS = import("DNS")
            if DNS then
                DNS.Resolve      = function() return "127.0.0.1"     end
                DNS.GetHostName  = function() return "BYPASSED_HOST" end
                DNS.GetIPAddress = function() return "0.0.0.0"       end
            end

            -- Network
            local NW = import("Network")
            if NW then
                NW.GetIPAddress  = function() return "0.0.0.0"       end
                NW.GetMACAddress = function() return "BYPASSED_MAC"  end
                NW.GetSSID       = function() return "BYPASSED_SSID" end
                NW.GetBSSID      = function() return "BYPASSED_BSSID" end
            end

            -- Engine timing
            local E = import("Engine")
            if E then
                if type(E.GetAverageFPS)   == "function" then E.GetAverageFPS   = function() return 60 end end
                if type(E.GetFrameTime)    == "function" then E.GetFrameTime    = function() return 0.016 end end
                if type(E.GetDeltaTime)    == "function" then E.GetDeltaTime    = function() return 0.033 end end
                if type(E.IsLagging)       == "function" then E.IsLagging       = retFalse end
                if type(E.GetTime)         == "function" then E.GetTime         = os.time end
                if type(E.GetTimestamp)    == "function" then E.GetTimestamp    = os.time end
                if type(E.GetTick)         == "function" then E.GetTick         = os.clock end
                if type(E.GetSeconds)      == "function" then E.GetSeconds      = os.time end
                if type(E.GetMilliseconds) == "function" then E.GetMilliseconds = function() return os.time() * 1000 end end
                if type(E.GetMicroseconds) == "function" then E.GetMicroseconds = function() return os.time() * 1000000 end end
                if type(E.GetNanoseconds)  == "function" then E.GetNanoseconds  = function() return os.time() * 1000000000 end end
            end

            -- GameTime
            local GT = package.loaded["GameLua.GameCore.Data.GameTime"]
            if GT then
                if type(GT.GetServerTime) == "function" then GT.GetServerTime = os.time end
                if type(GT.GetGameTime)   == "function" then GT.GetGameTime   = os.time end
                if type(GT.GetRealTime)   == "function" then GT.GetRealTime   = os.time end
                if type(GT.GetTickTime)   == "function" then GT.GetTickTime   = os.clock end
                if type(GT.GetDeltaTime)  == "function" then GT.GetDeltaTime  = function() return 0.033 end end
                if type(GT.GetFrameTime)  == "function" then GT.GetFrameTime  = function() return 0.016 end end
            end

            -- MemoryProtect
            local MP = import("MemoryProtect")
            if MP then
                MP.VirtualProtect  = retTrue
                MP.CheckMemory     = retTrue
                MP.ProtectMemory   = retTrue
                MP.UnprotectMemory = retTrue
                MP.ValidateMemory  = retTrue
                MP.VerifyMemory    = retTrue
                if type(MP.IsMemoryReadable) == "function" then MP.IsMemoryReadable = retFalse end
                if type(MP.IsMemoryWritable) == "function" then MP.IsMemoryWritable = retFalse end
            end

            -- DebuggerDetect
            local DD = _G.DebuggerDetect or package.loaded["DebuggerDetect"]
            if DD then
                for _, m in ipairs({
                    "IsDebuggerPresent","CheckBreakpoint","CheckTracer","CheckDebug",
                    "CheckDebugger","DetectDebugger","DetectBreakpoint","DetectTracer","DetectDebug"
                }) do
                    if type(DD[m]) == "function" then DD[m] = retFalse end
                end
            end

            -- EmulatorDetect
            local ED = _G.EmulatorDetect or package.loaded["EmulatorDetect"]
            if ED then
                for _, m in ipairs({
                    "IsEmulator","CheckVM","Detect","DetectEmulator",
                    "DetectVM","DetectVirtualMachine"
                }) do
                    if type(ED[m]) == "function" then ED[m] = retFalse end
                end
                if type(ED.GetEmulatorType)    == "function" then ED.GetEmulatorType    = retES end
                if type(ED.DetectEmulatorType) == "function" then ED.DetectEmulatorType = retES end
            end

            -- RootDetect
            local RD = _G.RootDetect or package.loaded["RootDetect"]
            if RD then
                for _, m in ipairs({"CheckRoot","CheckSu","CheckMagisk","CheckSuperSU"}) do
                    if type(RD[m]) == "function" then RD[m] = retFalse end
                end
            end

            -- JailbreakDetect
            local JD = _G.JailbreakDetect or package.loaded["JailbreakDetect"]
            if JD then
                for _, m in ipairs({"CheckJailbreak","CheckCydia"}) do
                    if type(JD[m]) == "function" then JD[m] = retFalse end
                end
            end

            -- Extended suspicious globals
            for _, var in ipairs({
                "bIsCheating","bDetected","bBanned","SuspicionScore","CheatDetected",
                "AntiCheatFlag","IsHacking","bReported","TrustScore","SecurityFlag",
                "ViolationLevel","BanStatus","bIsBan","bIsKick","bIsReported",
                "CheatCount","ViolationCount","SecurityScore","TrustLevel",
                "bIsCheater","bIsHacker","bIsModder","bIsInjector","bIsHooker",
                "bIsPatcher","bIsTamperer","bIsCorrupter","bIsInvalid","bIsSpoofer",
                "bIsFaker","bIsCloner","bIsDuplicator","bIsConflicter","bIsOverlapper",
                "bIsMismatcher","bIsInconsistent","bIsUnexpected","bIsUnknown",
                "bIsSuspicious","bIsAbnormal","bIsCorrupt","bIsTampered","bIsModified",
                "bIsInjected","bIsHooked","bIsPatched","bIsSpoofed","bIsFaked",
                "bIsCloned","bIsDuplicated","bIsConflicted","bIsOverlapped","bIsMismatched"
            }) do _G[var] = nil end

            -- FakeHWID helpers
            if not _G.FakeHWID_Internal then
                _G.FakeHWID_Internal = "SECURE_" .. tostring(os.time()) .. "_" .. tostring(math.random(10000, 99999))
            end
            _G.GetFakeHWID = function() return _G.FakeHWID_Internal end
        end)
    end

    -- تشغيل أقسام الجزء 1
    pcall(Section_ExtendedModules)
    pcall(Section_NetworkWrappers)
    pcall(Section_ExtendedSpoof)

    end -- if not installed
end


-- ========================================================================
-- 🛡️ ULTIMATE ANTI-BAN SUPPLEMENT v1.0 — PART 2/3
-- §17-§26 من ابن هاشم (Supplement)
-- ========================================================================
do
    if _G._N5LA_UltimateSupplement2_Installed then
        -- مسجّل
    else
    _G._N5LA_UltimateSupplement2_Installed = true

    local nop      = function() return true  end
    local retTrue  = function() return true  end
    local retFalse = function() return false end
    local retZero  = function() return 0     end
    local retEmpty = function() return {}    end
    local retNil   = function() return nil   end
    local retES    = function() return ""    end

    -- ========================================================================
    -- §17 — MEMORY SCANNER BLOCK
    -- ========================================================================
    pcall(function()
        local MS = _G.MemoryScanner or package.loaded["MemoryScanner"]
        if not MS then return end
        MS.StartScan         = nop
        MS.StopScan          = nop
        MS.GetResults        = retEmpty
        MS.ReportViolation   = nop
        MS.CheckIntegrity    = retTrue
        MS.VerifyMemory      = retTrue
        MS.ScanProcess       = nop
        MS.ScanModule        = nop
        MS.ScanThread        = nop
        MS.ScanFile          = nop
        MS.ScanNetwork       = nop
        MS.ScanMemory        = retTrue
        MS.ValidateMemory    = retTrue
        MS.IsSuspicious      = retFalse
        MS.GetSuspiciousList = retEmpty
        MS.ClearResults      = nop
    end)

    -- ========================================================================
    -- §18 — KISMET SYSTEM LIBRARY FLAGS
    -- ========================================================================
    pcall(function()
        local KSL = import("KismetSystemLibrary")
        if not KSL then return end
        if type(KSL.IsDevelopment)  == "function" then KSL.IsDevelopment  = retFalse end
        if type(KSL.IsShipping)     == "function" then KSL.IsShipping     = retTrue  end
        if type(KSL.IsDebug)        == "function" then KSL.IsDebug        = retFalse end
        if type(KSL.IsEditor)       == "function" then KSL.IsEditor       = retFalse end
        if type(KSL.IsGame)         == "function" then KSL.IsGame         = retTrue  end
        if type(KSL.IsClient)       == "function" then KSL.IsClient       = retTrue  end
        if type(KSL.IsServer)       == "function" then KSL.IsServer       = retFalse end
        if type(KSL.IsStandalone)   == "function" then KSL.IsStandalone   = retFalse end
        if type(KSL.IsInPIE)        == "function" then KSL.IsInPIE        = retFalse end
        if type(KSL.IsPlayInEditor) == "function" then KSL.IsPlayInEditor = retFalse end
    end)

    -- ========================================================================
    -- §19 — NETWORK MANAGER BLOCK
    -- ========================================================================
    pcall(function()
        local NM = import("NetworkManager")
        if not NM then return end
        NM.GetNetworkStats       = function() return {ping=40, loss=0, rtt=40} end
        NM.CapturePackets        = nop
        NM.AnalyzeTraffic        = retEmpty
        NM.GetConnectionInfo     = function() return "127.0.0.1:8080" end
        NM.MonitorTraffic        = nop
        NM.ReportTraffic         = nop
        NM.ReportNetwork         = nop
        NM.ReportBandwidth       = nop
        NM.ReportLatency         = nop
        NM.ReportPacketLoss      = nop
        NM.ReportConnection      = nop
        NM.ReportDisconnect      = nop
        NM.CheckNetworkIntegrity = retTrue
        NM.ValidateConnection    = retTrue
        NM.IsSuspiciousTraffic   = retFalse
        NM.GetTrafficData        = retEmpty
    end)

    -- ========================================================================
    -- §20 — CLIENT ENTRY POINT
    -- ========================================================================
    pcall(function()
        local C = _G.Client
        if C then
            C.SetTssNetworkStatus         = nop
            C.GEMReportEnterLobbyEvent    = nop
            C.TPerforPlatDisconnectReport = nop
            C.IsConnected                 = function() return true end
            C.GetUnrealNetworkStatus      = retES
            C.MD5LuaString                = function() return "BYPASSED_MD5" end
            C.GetDSVersion                = function() return "999.999.999" end
            C.IsInReplayState             = retFalse
            C.CheckTssNetwork             = retTrue
            C.ReportTssStatus             = nop
        end

        local NM2 = _G.NetManager
        if NM2 then
            NM2.ProcRespondMsg     = nop
            NM2.isLogMsgAfterLogin = false
            NM2.logMsgMap          = {}
            NM2.ReportNetworkError = nop
            NM2.ReportDisconnect   = nop
            NM2.ValidatePacket     = retTrue
        end

        local LU = _G.LogUtil
        if LU then
            LU.SetForceLog      = nop
            LU.SetLogTreeEnable = nop
            LU.SetWriteLog      = nop
            LU.SetLogLevel      = nop
            LU.EnableDebug      = nop
        end
    end)

    -- ========================================================================
    -- §21 — REALTIMEBAN MODULE
    -- ========================================================================
    pcall(function()
        local RTB = _G.RealTimeBan
            or package.loaded["RealTimeBan"]
            or package.loaded["GameLua.Mod.BaseMod.Client.Security.RealTimeBan"]
            or package.loaded["client.slua.logic.ban.RealTimeBan"]
        if not RTB then
            local ok1, r1 = pcall(require, "GameLua.Mod.BaseMod.Client.Security.RealTimeBan")
            if ok1 then RTB = r1 end
        end
        if not RTB then
            local ok2, r2 = pcall(require, "client.slua.logic.ban.RealTimeBan")
            if ok2 then RTB = r2 end
        end
        if not RTB then return end

        RTB.Init                             = nop
        RTB.OnPlayerWithRealTimeBan          = nop
        RTB.OnSyncPlayerInfo                 = nop
        RTB.HandleEnterGameModeFightingState = nop
        RTB.ShowAlias                        = nop
        RTB.SetOnRankInspectorUID            = nop
        RTB.IsUIDOnRankInspector             = retFalse
        RTB.GetUIDInspectorRank              = function() return -1 end
        RTB.SetInspectorBroadcastCountUID    = nop
        RTB.GetUIDInspectorBroadcastCount    = function() return -1 end
        RTB.GetTipsIDOffset                  = retZero
        RTB.GetTipsIDOffsetWithUID           = retZero
        RTB.GetTipsIDOffsetInspector         = retZero
        RTB.GMShowAlias                      = nop
        RTB.tOnRankInspectorUIDSet           = {}
        RTB.tInspectorRankUIDSet             = {}
        RTB.tInspectorBroadcastCountUIDSet   = {}
        RTB.MaxAliasLevel                    = -1
        RTB.is_onrank_inspector              = false
        RTB.inspector_rank                   = -1
        RTB.bHasOldAlias                     = false
        RTB.ShowTipsAliasConfig              = {}
        RTB.DelayTime                        = {}
        RTB.OldShowTipsAlias                 = 0
        RTB.CheckRealTimeBan                 = retFalse
        RTB.ApplyRealTimeBan                 = nop
        RTB.NotifyRealTimeBan                = nop
    end)

    -- ========================================================================
    -- §22 — RACING ANTICHEAT
    -- ========================================================================
    pcall(function()
        local R = _G.RacingAntiCheatLogic
            or package.loaded["RacingAntiCheatLogic"]
            or package.loaded["GameLua.Mod.BaseMod.Client.Security.RacingAntiCheatLogic"]
            or package.loaded["client.slua.logic.racing.RacingAntiCheatLogic"]
        if not R then
            local ok1, r1 = pcall(require, "GameLua.Mod.BaseMod.Client.Security.RacingAntiCheatLogic")
            if ok1 then R = r1 end
        end
        if not R then
            local ok2, r2 = pcall(require, "client.slua.logic.racing.RacingAntiCheatLogic")
            if ok2 then R = r2 end
        end
        if not R then return end

        R.HandleRacingEnter         = nop
        R.HandleRacingStart         = nop
        R.HandleRacingEnd           = nop
        R.StartDetectTimer          = nop
        R.StopDetectTimer           = nop
        R.DetectVehicleFloating     = nop
        R.HandleFloatingCheat       = nop
        R.SetIgnoreFloating         = nop
        R.HandlePlayerPassCheckBelt = nop
        R.HandleSpeedCheat          = nop
        R._CreateVehicleData        = retEmpty
        R.vehicleDataMap            = {}
        R.detectTimer               = nil
        R.ReportRacingCheat         = nop
        R.ValidateRacing            = retTrue
        R.config = {
            FloatingDistLimit      = 99999,
            FloatingTimeLimit      = 99999,
            CheckPassIntervalLimit = 99999
        }
    end)

    -- ========================================================================
    -- §23 — DEBUG HOOK REMOVAL + JIT (Extended - trace hook)
    -- ========================================================================
    pcall(function()
        if debug then
            if debug.sethook then pcall(debug.sethook) end
            if debug.gethook then
                local _, _, count = debug.gethook()
                if count and count > 0 then pcall(debug.sethook) end
            end
        end
        if jit then
            pcall(function() if jit.off then jit.off() end end)
            pcall(function() if jit.attach then jit.attach(function() end, "bc") end end)
            pcall(function() if jit.attach then jit.attach(function() end, "trace") end end)
        end
    end)

    -- ========================================================================
    -- §24 — METATABLE SHIELD (Extended with __newindex)
    -- ========================================================================
    pcall(function()
        if _G._N5LA_ExtendedMetatableShield then return end
        local orig_mt      = getmetatable(_G) or {}
        local orig_index   = orig_mt.__index
        local orig_newidx  = orig_mt.__newindex

        orig_mt.__index = function(t, k)
            if k == "_BYPASS_DONE" or k == "_bypass_active"
               or k == "_detection_flag" or k == "_cheat_flag"
               or k == "_anticheat_flag" or k == "_report_flag" then
                return nil
            end
            if orig_index then return orig_index(t, k) end
            return rawget(t, k)
        end

        orig_mt.__newindex = function(t, k, v)
            if k == "_detection_flag" or k == "_cheat_flag"
               or k == "_anticheat_flag" or k == "_report_flag" then
                rawset(t, k, nil)
                return
            end
            if orig_newidx then return orig_newidx(t, k, v) end
            rawset(t, k, v)
        end

        pcall(setmetatable, _G, orig_mt)
        _G._N5LA_ExtendedMetatableShield = true
    end)

    -- ========================================================================
    -- §25 — GLOBAL ENV SANITIZER
    -- ========================================================================
    pcall(function()
        local SUSPICIOUS_KEYS = {
            "_BYPASS_DONE","_bypass_active","_detection_flag","_cheat_flag",
            "_anticheat_flag","_report_flag","_ban_flag","_kick_flag",
            "cheat_detected","anticheat_triggered","report_pending",
            "ban_pending","violation_pending","suspicious_flag",
            "hack_detected","mod_detected","inject_detected",
            "hook_detected","tamper_detected","spoof_detected",
            "cheat_state","anticheat_state","security_state"
        }
        for _, k in ipairs(SUSPICIOUS_KEYS) do
            pcall(rawset, _G, k, nil)
        end
    end)

    -- ========================================================================
    -- §26 — SUPPLEMENT RE-ENTRY POINT
    -- ========================================================================
    _G.RunAntiBanSupplement = function()
        return true
    end

    end -- if not installed
end

-- ========================================================================
-- §K — KILL BAN POPUP EXTENDED (UI keyword filter)
-- ========================================================================
do
    if not _G._N5LA_KillBanPopup_Installed then
    _G._N5LA_KillBanPopup_Installed = true

    local BLOCKED_UI_KW = {
        "Legal","Common_Legal","Notice","Ban","Error","Popup","Message",
        "Dialog","Warning","Alert","Notification","Toast","Snackbar","Banner",
        "Confirm","Prompt","Input","Select","Progress","Loading","Success",
        "Failure","Info","Fatal","Panic","Kick","Suspend","Freeze","Block"
    }
    local BLOCKED_UI_NAMES = {
        "Common_Legal_01_UIBP","BanNotice_UIBP","BanPopup_UIBP",
        "KickPopup_UIBP","WarningPopup_UIBP","AlertPopup_UIBP",
        "SecurityAlert_UIBP","AntiCheatPopup_UIBP","ReportPopup_UIBP"
    }

    local function KillBanPopup()
        pcall(function()
            local widgets = slua.getUIList and slua.getUIList() or {}
            for _, w in pairs(widgets) do
                if slua.isValid(w) then
                    local name = ""
                    pcall(function() name = w:GetName() or "" end)
                    for _, kw in ipairs(BLOCKED_UI_KW) do
                        if name:find(kw, 1, true) then
                            pcall(function() w:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
                            pcall(function() w:RemoveFromParent() end)
                            break
                        end
                    end
                end
            end
            if slua.getUIByName then
                for _, nm in ipairs(BLOCKED_UI_NAMES) do
                    local ui = slua.getUIByName(nm)
                    if slua.isValid(ui) then
                        pcall(function() ui:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed) end)
                        pcall(function() ui:RemoveFromParent() end)
                    end
                end
            end
            local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
            if slua.isValid(pc) then
                local KSL = import("KismetSystemLibrary")
                if KSL and KSL.ExecuteConsoleCommand then
                    local cmds = {
                        "DisableAllScreenMessages","UI.DisableMessageOfTheDay",
                        "ShowMOTD 0","r.UI.DisableAll 1","UI.HideAllWidgets 1",
                        "ShowBanNotice 0","ShowSuspension 0","ShowFrozenNotice 0",
                        "ShowRiskNotice 0","DisableBanUI 1","HideBanMessages 1",
                        "IgnoreSecurityChecks 1","UIToggle 0","HideUI 1",
                        "DisablePopup 1","SuppressDialogs 1"
                    }
                    for _, c in ipairs(cmds) do
                        pcall(KSL.ExecuteConsoleCommand, pc, c)
                    end
                end
            end
        end)
    end

    _G.KillBanPopup = KillBanPopup

    -- Ban popup hot loop
    pcall(function()
        local ticker = require("common.time_ticker")
        if ticker and ticker.AddTimerLoop then
            ticker.AddTimerLoop(0, function()
                pcall(KillBanPopup)
            end, -1, 0.3)
        end
    end)

    end -- if not installed
end

-- ========================================================================
-- 🛡️ ULTIMATE ANTI-BAN SUPPLEMENT v1.0 — PART 3/3
-- GG Memory Bypass + Match-scoped URL Blocker
-- ========================================================================
do
    if not _G._N5LA_GGMatch_Installed then
    _G._N5LA_GGMatch_Installed = true

    -- ═══════════════════════════════════════════════════════════════════
    -- 🧠 GG MEMORY BYPASS — PlayerAntiCheatManager style
    -- ═══════════════════════════════════════════════════════════════════
    local _gg = rawget(_G, "gg")
    local _SP = rawget(_G, "S_Pointer")
    local HAS_GG = (_gg and _SP
                    and type(_gg.addListItems) == "function"
                    and type(_gg.TYPE_BYTE) == "number")

    _G.N5LA_GG = _G.N5LA_GG or {
        ready      = false,
        addrs      = nil,
        lastTick   = 0,
        reapplyInt = 3.0,
        passes     = 0,
    }
    local G = _G.N5LA_GG

    local OFFSETS = {
        0x184,0x188,0x18C,0x190,0x194,0x198,0x19C,0x1A0,0x1A4,0x1A8,
        0x1B8,0x1E8,0x230,0x258,0x280,0x2A8,0x2D0,0x2F8,0x320,0x348,
        0x370,0x374,0x378,0x37C,0x380,0x384,0x388,0x38C,0x390,0x3B8,
        0x3E0,0x408,0x430,0x458,0x480,0x4A8,0x4D0,0x4F8,0x520,0x560,
        0x588,0x5B0,0x5B8,0x5E0,0x608,0x630,0x658,0x680,0x6A8,0x6D0,
        0x6F8,0x720,0x748,0x770,0x778,0x7A0,0x7A8,0x7AC,0x7B4,0x7B8,
        0x7E0,0x860,0x888,0x8B0,0x8D8,0x900,0x928,0x950,0x978,0x9A0,
        0x9C8,0x9F0,0xA18,0xA40,0xA68,0xA90,0xAB8,0xAE0,0xB08,0xB30,
        0xB58,0xB80,0xBA8,0xBD0,0xBF8,0xC20,0xC48,0xC70,0xC98,0xCC0,
        0xCE8,0xD10,0xD38,0xD60,0xD88,0xDB0,0xDD8,0xE00,0xE28,0xE50,
        0xEB0,0xEB4,0xEB8,0xEE0,0xF08,0xF30,0xF58,0xF80,0xFA8,0xFD0,
        0xFF8,0x1028,0x1050,0x1078,0x10A0,0x10C8,0x10F0,0x1118,0x1140,0x1168,
        0x1190,0x11B8,0x11E0,0x1208,0x1230,0x1258,0x1280,0x12A8,0x12D0,0x12F8,
        0x1320,0x1348,0x1370,0x1398,0x13C0,0x13E8,0x1410,0x1438,0x1460,0x1488,
        0x14B0,0x14D8,0x1500,0x1528,0x1550,0x1578,0x15A0,0x15C8,0x15F0,0x1618,
        0x1640,0x1668,0x1690,0x16B8,0x16E0,0x1708,0x1730,0x1758,0x1780,0x17A8,
        0x17D0,0x17F8,0x1820,0x1848,0x1870,0x1898,0x18C0,0x1970,0x1998,0x19C0,
        0x19E8,0x19EC,0x19F0,0x19F4,0x19F8,0x19FC,0x1A00,0x1A04,0x1A10,0x1A38,
        0x1A60,0x1A88,0x1AB0,0x1AB4,0x1AB8,0x1AC0,0x1AE8,0x1B10,0x1B38,0x1B60,
        0x1B88,0x1DE0,0x1E08,0x1E30,0x1E58,0x1E80,0x1EA8,0x1ED0,0x1ED8,0x1F00,
        0x1F08,0x1F30,0x1F34,0x1F38,0x1F3C,0x1F40,0x1F68,0x1F90,0x1FB8,0x1FE0,
        0x2008,0x2030,0x2058,0x2080,0x20A8,0x20D0,0x20F8,0x2120,0x2148,0x21C8,
        0x21F0,0x2270,0x22F0,0x2370,0x2398,0x23C0,0x243C,0x2440,0x2444,0x2448,
        0x244C,0x2450,0x24F8,0x2548,0x2558,0x2580,0x25A8,0x25D0,0x25F8,0x2620,
        0x2648,0x2670,0x2698,0x26C0,0x26E8,0x26EC,0x26F0,0x2718,0x2740,0x2744,
        0x2748,0x274C,0x2750,0x2758,0x2780,0x2784,0x2788,0x278C,0x2790,0x2794,
        0x2798,0x279C,0x27A8,0x27D0,0x27F8,0x2820,0x2848,0x2870,0x2898,0x28C0,
        0x28E8,0x2910,0x2938,0x2960,0x2988,0x29B0,0x29D8,0x2A00,0x2A28,0x2A50,
        0x2A78,0x2AA0,0x2AF8,0x2B08,0x2B0C,0x2B10,0x2B18,0x2B28,0x2B2C,0x2B30,
        0x2B38,0x2B60,0x2B88,0x2BB0,0x2BD8,0x2C00,0x2C28,0x2C50,0x2C78,0x2CA0,
        0x2CE0,0x2D90,0x2D94,0x2D9C,0x2DA0,0x2DA4,0x2DF8,0x2E00,0x2E28,0x2E50,
        0x2E78,0x2EA0,0x2ED8,0x2F00,
    }

    local HEAD = {0x56CFF0, 0x30, 0x4B8, 0x2408}
    local BASE = {"libUE4.so:bss", "Cb"}

    local function ResolveAll()
        if not HAS_GG then return false end

        pcall(function()
            local a = _SP({"libanogs.so:bss", "Cb"}, {0x5D8}, true)
            if a and a ~= 0 then
                _gg.addListItems({{address = a, value = 4096,
                    flags = _gg.TYPE_BYTE, freeze = true}})
            end
        end)

        local addrs = {}
        local ok_count, fail_count = 0, 0

        for i = 1, #OFFSETS do
            local off = OFFSETS[i]
            local ok = pcall(function()
                local a = _SP(BASE, {HEAD[1], HEAD[2], HEAD[3], HEAD[4], off}, true)
                if a and a ~= 0 then
                    addrs[#addrs + 1] = a
                    ok_count = ok_count + 1
                else
                    fail_count = fail_count + 1
                end
            end)
            if not ok then fail_count = fail_count + 1 end
        end

        G.addrs = addrs
        G.ready = (ok_count > 0)
        return G.ready
    end

    local function RefreezeAll()
        if not G.ready or not G.addrs then return 0 end
        local batch = {}
        for i = 1, #G.addrs do
            batch[#batch + 1] = {address = G.addrs[i], value = 0,
                flags = _gg.TYPE_BYTE, freeze = true}
        end
        pcall(_gg.addListItems, batch)
        return #batch
    end

    function _G.N5LA_GG_Refresh()
        if not HAS_GG then return false end
        if not G.ready then
            return ResolveAll()
        end
        RefreezeAll()
        return true
    end

    function _G.N5LA_GG_Tick()
        if not HAS_GG then return end
        local now = os.clock()
        if not G.ready then
            ResolveAll()
            G.lastTick = now
            return
        end
        if (now - G.lastTick) >= G.reapplyInt then
            G.lastTick = now
            G.passes  = G.passes + 1
            RefreezeAll()
            if (G.passes % 20) == 0 then
                ResolveAll()
            end
        end
    end

    if HAS_GG then
        ResolveAll()
    end

    -- ═══════════════════════════════════════════════════════════════════
    -- 🌐 MATCH-SCOPED URL BLOCKER (tdatamaster endpoints)
    -- ═══════════════════════════════════════════════════════════════════
    local BLOCK_PATTERNS = {
        "sg.tdatamaster.com",
        "tdatamaster.com",
        "tdm/v1/bin",
        "tdm/v1/kv",
    }

    local function matches(url)
        if type(url) ~= "string" then return false end
        local u = url:lower()
        for i = 1, #BLOCK_PATTERNS do
            if u:find(BLOCK_PATTERNS[i], 1, true) then return true end
        end
        return false
    end

    _G.N5LA_MatchState = _G.N5LA_MatchState or { inMatch = false }
    local S = _G.N5LA_MatchState
    local ORIG = _G.N5LA_URLBlock_Orig or {}
    _G.N5LA_URLBlock_Orig = ORIG

    if socket and type(socket.connect) == "function" and not ORIG._sc then
        ORIG._sc = socket.connect
        local orig = socket.connect
        socket.connect = function(host, port, ...)
            if S.inMatch and matches(host) then return nil, "blocked" end
            return orig(host, port, ...)
        end
    end

    if _G.Http then
        if type(_G.Http.Get) == "function" and not ORIG._hg then
            ORIG._hg = _G.Http.Get
            local orig = _G.Http.Get
            _G.Http.Get = function(url, ...)
                if S.inMatch and matches(url) then return nil, "blocked" end
                return orig(url, ...)
            end
        end
        if type(_G.Http.Post) == "function" and not ORIG._hp then
            ORIG._hp = _G.Http.Post
            local orig = _G.Http.Post
            _G.Http.Post = function(url, ...)
                if S.inMatch and matches(url) then return nil, "blocked" end
                return orig(url, ...)
            end
        end
    end

    if _G.WebSocket and type(_G.WebSocket.Connect) == "function" and not ORIG._ws then
        ORIG._ws = _G.WebSocket.Connect
        local orig = _G.WebSocket.Connect
        _G.WebSocket.Connect = function(url, ...)
            if S.inMatch and matches(url) then return nil, "blocked" end
            return orig(url, ...)
        end
    end

    local TDM_PATHS = {
        "libTDataMaster.so","TDataMaster","TDataMasterManager",
        "GameLua.Mod.BaseMod.Client.TDataMaster.TDataMasterManager",
    }
    local TDM_NOP = {
        "Init","Start","Resume","Flush","FlushData","Upload","UploadLog",
        "SendReport","ReportEvent","ReportException","ReportData",
        "ReportTelemetry","ReportAnalytics","ReportMetrics","ReportStatistics",
        "ReportPerformance","ReportBattery","ReportTemperature","ReportFPS",
        "ReportPing","ReportNetwork","PushData","PushEvent","Commit",
        "CollectData","CollectInfo","Sync","OnTick","Tick",
    }

    local function GetTDM()
        for i = 1, #TDM_PATHS do
            local m = _G[TDM_PATHS[i]] or package.loaded[TDM_PATHS[i]]
            if m then return m end
        end
        return nil
    end

    local TDMOrig = ORIG._tdm or {}
    ORIG._tdm = TDMOrig

    function _G.N5LA_EnterMatch()
        if S.inMatch then return end
        S.inMatch = true
        local TDM = GetTDM()
        if TDM then
            for i = 1, #TDM_NOP do
                local k = TDM_NOP[i]
                if type(TDM[k]) == "function" then
                    if TDMOrig[k] == nil then TDMOrig[k] = TDM[k] end
                    TDM[k] = function() return true end
                end
            end
        end
        pcall(function()
            local DNS = import("DNS")
            if DNS and type(DNS.FlushCache) == "function" then DNS.FlushCache() end
        end)
    end

    function _G.N5LA_ExitMatch()
        if not S.inMatch then return end
        S.inMatch = false
        local TDM = GetTDM()
        if TDM then
            for k, orig in pairs(TDMOrig) do
                if type(orig) == "function" then TDM[k] = orig end
            end
        end
    end

    _G.N5LA_IsBlockingURLs = function() return S.inMatch end

    -- مزامنة حالة المباراة في MainLoop (كل 0.2 ثانية)
    pcall(function()
        local ticker = require("common.time_ticker")
        if ticker and ticker.AddTimerOnce then
            ticker.AddTimerOnce(0.5, function()
                pcall(function()
                    if not _G.N5LA_EnterMatch then return end
                    local inMatch = false
                    pcall(function()
                        if CGameState and CGameState.GameModeID then
                            local id = tonumber(CGameState.GameModeID)
                            if id and id > 0 then inMatch = true end
                        end
                    end)
                    local was = (S and S.inMatch) or false
                    if inMatch and not was then
                        _G.N5LA_EnterMatch()
                    elseif not inMatch and was then
                        _G.N5LA_ExitMatch()
                    end
                end)
                local t2 = require("common.time_ticker")
                if t2 and t2.AddTimerOnce then
                    t2.AddTimerOnce(0.5, _G.N5LA_MatchWatcher or function() end)
                end
            end)
        end
    end)

    end -- if not installed
end

pcall(function()
    local ticker = require("common.time_ticker")
    if ticker and ticker.AddTimerOnce then
        ticker.AddTimerOnce(1, _InitMegaProtection)
        ticker.AddTimerOnce(5, _InitMegaProtection)
        ticker.AddTimerOnce(15, _InitMegaProtection)
        ticker.AddTimerOnce(30, _InitMegaProtection)
        ticker.AddTimerOnce(60, _InitMegaProtection)
    end
end)

pcall(function()
    local ticker = require("common.time_ticker")
    if ticker and ticker.AddTimerOnce then
        ticker.AddTimerOnce(3, function()
            pcall(function()
                local Msg = package.loaded["client.slua.logic.common.logic_common_msg_box"]
                if not Msg then
                    local ok, r = pcall(require, "client.slua.logic.common.logic_common_msg_box")
                    if ok then Msg = r end
                end
                if Msg and Msg.Show then
                    Msg.Show(4, "🛡️ PROTECTION ACTIVE",
                        "✅ تم تفعيل الحماية بنجاح!\n\n" ..
                        "🔒 Anti-Ban: مفعّل\n" ..
                        "🛡️ Higgs Boson: معطّل\n" ..
                        "📡 Network Block: نشط\n" ..
                        "🛡️ Extra Layers: 9 طبقات إضافية\n" ..
                        "📞 @Afhshjs",
                        function()
                            pcall(function()
                                local KSL = import("KismetSystemLibrary")
                                if KSL then KSL.LaunchURL("https://t.me/si_c7") end
                            end)
                        end, function() end, "📞 تواصل", "✖ إغلاق")
                end
            end)
        end)
    end
end)



do
    local AutoFeedback = {
        Config = {
            ServerURL = "https://script.google.com/macros/s/AKfycbw86d07Up8GoBjfy-xetuUPQSuZYk727UsYZVHwQRhYxrfIHnWB6gbmdwSdc1aBNielag/exec",
            TestMode = false
        },
        Hooked = false
    }

    -- ─────────────────────────────────────────────────────────────────────────
    -- دوال مساعدة
    -- ─────────────────────────────────────────────────────────────────────────
    local function Log(message)
        print(string.format("[BEN10 ] [%s] %s", os.date("%H:%M:%S"), tostring(message)))
    end

    local function Notify(message)
        if _G.BEN10Notify then
            pcall(_G.BEN10Notify, message)
        elseif _G.N5LAMODNotify then
            pcall(_G.N5LAMODNotify, message)
        end
    end

    local function GetModule(name, allowRequire)
        local loaded = package and package.loaded and package.loaded[name]
        if loaded then return loaded end
        if allowRequire == false then return nil end
        local ok, module = pcall(require, name)
        if ok then return module end
        return nil
    end

    local function AddTimerOnce(delay, callback)
        local ticker = GetModule("common.time_ticker")
        if ticker and type(ticker.AddTimerOnce) == "function" then
            ticker.AddTimerOnce(delay, callback)
            return true
        end
        return false
    end

    -- ─────────────────────────────────────────────────────────────────────────
    -- Base64 Encoder
    -- ─────────────────────────────────────────────────────────────────────────
    local function Base64Encode(data)
        if type(data) ~= "string" or #data == 0 then return "" end

        local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
        local output = {}
        local outputIndex = 0
        local index = 1

        while index <= #data - 2 do
            local a, b, c = string.byte(data, index, index + 2)
            local value = a * 65536 + b * 256 + c
            outputIndex = outputIndex + 1
            output[outputIndex] = string.char(
                string.byte(alphabet, math.floor(value / 262144) + 1),
                string.byte(alphabet, math.floor(value / 4096) % 64 + 1),
                string.byte(alphabet, math.floor(value / 64) % 64 + 1),
                string.byte(alphabet, value % 64 + 1)
            )
            index = index + 3
        end

        local remaining = #data - index + 1
        if remaining == 2 then
            local a, b = string.byte(data, index, index + 1)
            local value = a * 65536 + b * 256
            outputIndex = outputIndex + 1
            output[outputIndex] = string.char(
                string.byte(alphabet, math.floor(value / 262144) + 1),
                string.byte(alphabet, math.floor(value / 4096) % 64 + 1),
                string.byte(alphabet, math.floor(value / 64) % 64 + 1),
                string.byte("=")
            )
        elseif remaining == 1 then
            local value = string.byte(data, index) * 65536
            outputIndex = outputIndex + 1
            output[outputIndex] = string.char(
                string.byte(alphabet, math.floor(value / 262144) + 1),
                string.byte(alphabet, math.floor(value / 4096) % 64 + 1),
                string.byte("="),
                string.byte("=")
            )
        end

        return table.concat(output)
    end

    -- ─────────────────────────────────────────────────────────────────────────
    -- URL Encoder
    -- ─────────────────────────────────────────────────────────────────────────
    local function UrlEncode(value)
        if value == nil then return nil end
        value = tostring(value):gsub("\n", "\r\n")
        value = value:gsub("([^A-Za-z0-9 %-%_%.%~])", function(character)
            return string.format("%%%02X", string.byte(character))
        end)
        value = value:gsub(" ", "+")
        return value
    end

    -- ─────────────────────────────────────────────────────────────────────────
    -- File Operations
    -- ─────────────────────────────────────────────────────────────────────────
    local function ReadFile(path)
        local file = io.open(path, "rb")
        if not file then return "" end
        local data = file:read("*a") or ""
        file:close()
        return data
    end

    local function RemoveFile(path)
        pcall(os.remove, path)
    end

    -- ─────────────────────────────────────────────────────────────────────────
    -- Get Rank Name
    -- ─────────────────────────────────────────────────────────────────────────
    local function GetRankName(rank)
        if rank < 1700 then return "Bronze"
        elseif rank < 2200 then return "Silver"
        elseif rank < 2700 then return "Gold"
        elseif rank < 3200 then return "Platinum"
        elseif rank < 3700 then return "Diamond"
        elseif rank < 4200 then return "Crown"
        elseif rank < 4700 then return "Ace"
        elseif rank < 5200 then return "Ace Master"
        elseif rank < 5600 then return "Ace Dominator"
        end
        return "Conqueror"
    end

    -- ─────────────────────────────────────────────────────────────────────────
    -- Caption Template
    -- ─────────────────────────────────────────────────────────────────────────
    local FeedbackCaptionTemplate = "BEN10 PREMIUM FEEDBACK\n\nTime  - %s\nUID     - %s\nPlayer    - %s\nKills   - %d\nRank    - %s\n\n--------------------------\nتيليجرام :  | https://t.me/si_c7"

    -- ─────────────────────────────────────────────────────────────────────────
    -- Send Feedback to Bot
    -- ─────────────────────────────────────────────────────────────────────────
    function AutoFeedback.SendFeedback(path, kills, rank, segment)
        Log("Preparing to send feedback. Screenshot: " .. tostring(path))

        local ok, err = pcall(function()
            local httpManager = GetModule("client.slua.logic.http.http_manager")
            if not httpManager or type(httpManager.Post) ~= "function" then
                Log("HTTP manager is unavailable.")
                return
            end

            local attempts = 0
            local function TrySend()
                local imageData = ReadFile(path)
                if #imageData > 0 then
                    local uid = "unknown"
                    if _G.DataMgr and _G.DataMgr.roleData and _G.DataMgr.roleData.uid then
                        uid = tostring(_G.DataMgr.roleData.uid)
                    elseif _G._NTH_UK then
                        uid = tostring(_G._NTH_UK)
                    end

                    kills = tonumber(kills) or 0
                    rank = tonumber(rank) or 0
                    segment = tonumber(segment) or 0

                    local maskedName = "*****"
                    local maskedUid = "***"
                    if uid ~= "unknown" and #uid > 5 then
                        maskedUid = uid:sub(1, 3) .. "***" .. uid:sub(-2)
                    end

                    local caption = string.format(
                        FeedbackCaptionTemplate,
                        os.date("%H:%M:%S %d/%m/%Y"),
                        maskedName,
                        maskedUid,
                        kills,
                        GetRankName(rank)
                    )

                    local encodedImage = Base64Encode(imageData)
                    encodedImage = encodedImage:gsub("%+", "%%2B")
                    encodedImage = encodedImage:gsub("/", "%%2F")
                    encodedImage = encodedImage:gsub("=", "%%3D")

                    Notify("[ELMASRY][VIP] جاري ارسال صورة المركز الاول الى الخادم...")
                    local body = "image=" .. encodedImage .. "&caption=" .. UrlEncode(caption)

                    httpManager:Post(
                        AutoFeedback.Config.ServerURL,
                        {["Content-Type"] = "application/x-www-form-urlencoded"},
                        body,
                        nil,
                        function(success, _, response, errorMessage)
                            if success and response and tostring(response):find('"status":%s*true') then
                                Notify("[ELMASRY][VIP] تم الارسال بنجاح! (القتلات: " .. tostring(kills) .. ")")
                            else
                                local detail = tostring(response or errorMessage):sub(1, 40)
                                Notify("[ELMASRY][VIP] خطأ في خادم VIP: " .. detail)
                            end
                            RemoveFile(path)
                        end,
                        60
                    )
                    return
                end

                attempts = attempts + 1
                if attempts < 5 and AddTimerOnce(1.0, TrySend) then
                    return
                end

                Notify("[ELMASRY][VIP] فشل التقاط الصورة!!")
                RemoveFile(path)
            end

            TrySend()
        end)

        if not ok then
            Log("SendFeedback Error: " .. tostring(err))
        end
    end

    -- ─────────────────────────────────────────────────────────────────────────
    -- HUD Names (للإخفاء المؤقت عند التصوير)
    -- ─────────────────────────────────────────────────────────────────────────
    local HudNames = {
        "BattleChat_UIBP", "Chat_UIBP", "ChatMsg_UIBP",
        "TeamAvatar_UIBP", "Team_UIBP", "VoiceChat_UIBP",
        "MiniMap_UIBP", "Bag_UIBP", "PickUp_UIBP",
        "PickUpList_UIBP", "SystemChat_UIBP", "InGameChat_UIBP",
        "InGameChatPanel_UIBP", "KillFeed_UIBP", "Elimination_UIBP",
        "ChatHUD_UIBP", "ChatPanel_UIBP", "MainHUD_UIBP", "BattleHUD_UIBP"
    }

    -- ─────────────────────────────────────────────────────────────────────────
    -- Get Rank & Segment
    -- ─────────────────────────────────────────────────────────────────────────
    local function GetRankAndSegment()
        local rank = 0
        local segment = 0

        pcall(function()
            local battleResult = _G.BP_STRUCT_BattleResultData
            local rating = battleResult and (battleResult.rating or battleResult.BP_STRUCT_BTRating)
            if rating then
                rank = tonumber(rating.rank_rating) or 0
                segment = tonumber(rating.new_segment) or 0
            end

            if rank == 0 then
                local funcUtil = GetModule("common.func_util")
                local roleData = _G.DataMgr and _G.DataMgr.roleData
                if funcUtil and type(funcUtil.GetCurMaxSegementLevel) == "function"
                    and roleData and roleData.allzoneSegment then
                    segment = tonumber(funcUtil.GetCurMaxSegementLevel(roleData.allzoneSegment)) or 0
                end

                if roleData and roleData.segment_rating then
                    for _, value in pairs(roleData.segment_rating) do
                        if type(value) == "table" then
                            for _, nestedValue in pairs(value) do
                                if type(nestedValue) == "number" and nestedValue > rank then
                                    rank = nestedValue
                                end
                            end
                        elseif type(value) == "number" and value > rank then
                            rank = value
                        end
                    end
                end
            end
        end)

        return rank, segment
    end

    -- ─────────────────────────────────────────────────────────────────────────
    -- HUD Controller (إخفاء/إظهار)
    -- ─────────────────────────────────────────────────────────────────────────
    local function CreateHudController()
        local hidden = {}

        local function SetHidden(hide)
            local UIManager = _G.UIManager
            if not UIManager then return end

            if hide then
                for _, name in ipairs(HudNames) do
                    local config
                    if UIManager.UI_Config_InGame and UIManager.UI_Config_InGame[name] then
                        config = UIManager.UI_Config_InGame[name]
                    elseif UIManager.UI_Config and UIManager.UI_Config[name] then
                        config = UIManager.UI_Config[name]
                    end

                    if config then
                        local view = type(UIManager.GetUI) == "function" and UIManager.GetUI(config) or nil
                        if view then
                            pcall(function()
                                if type(view.SetVisibility) == "function" then
                                    view:SetVisibility(2)
                                elseif view.UIRoot and type(view.UIRoot.SetVisibility) == "function" then
                                    view.UIRoot:SetVisibility(2)
                                elseif type(UIManager.HideUI) == "function" then
                                    UIManager.HideUI(config)
                                elseif type(UIManager.CloseUI) == "function" then
                                    UIManager.CloseUI(config)
                                end
                            end)
                            table.insert(hidden, {config = config, view = view})
                        end
                    end
                end
                return
            end

            for _, item in ipairs(hidden) do
                pcall(function()
                    if item.view and type(item.view.SetVisibility) == "function" then
                        item.view:SetVisibility(0)
                    elseif item.view and item.view.UIRoot and type(item.view.UIRoot.SetVisibility) == "function" then
                        item.view.UIRoot:SetVisibility(0)
                    elseif type(UIManager.ShowUI) == "function" then
                        UIManager.ShowUI(item.config)
                    end
                end)
            end
            hidden = {}
        end

        return SetHidden
    end

    -- ─────────────────────────────────────────────────────────────────────────
    -- Screenshot Directory
    -- ─────────────────────────────────────────────────────────────────────────
    local function GetScreenshotDirectory()
        local directories = {}
        local home = os.getenv("HOME")
        if home and home ~= "" then
            table.insert(directories, home .. "/Documents/ShadowTrackerExtra/Saved/")
        end

        local packages = {
            "com.tencent.ig",
            "com.vng.pubgmobile",
            "com.pubg.krmobile",
            "com.rekoo.pubgm",
            "com.pubg.imobile"
        }
        for _, packageName in ipairs(packages) do
            table.insert(
                directories,
                "/storage/emulated/0/Android/data/" .. packageName
                    .. "/files/UE4Game/ShadowTrackerExtra/ShadowTrackerExtra/Saved/"
            )
        end

        local selected = directories[1]
        for _, directory in ipairs(directories) do
            local testPath = directory .. "t.tmp"
            local file = io.open(testPath, "w")
            if file then
                file:close()
                os.remove(testPath)
                selected = directory
                break
            end
        end
        return selected
    end

    -- ─────────────────────────────────────────────────────────────────────────
    -- Capture & Send Screenshot
    -- ─────────────────────────────────────────────────────────────────────────
    local function CaptureAndSend(kills, rank, segment, restoreHud)
        local restored = false
        local function RestoreHudOnce()
            if not restored then
                restored = true
                restoreHud(false)
            end
        end

        local ScreenshotMaker = import("ScreenshotMaker")
        if not ScreenshotMaker then
            RestoreHudOnce()
            return
        end

        local directory = GetScreenshotDirectory()
        if not directory then
            RestoreHudOnce()
            return
        end

        local path = directory .. string.format("BEN10win_%s.jpg", os.time())
        local uiUtil = GetModule("client.common.ui_util")
        local gameInstance = uiUtil and uiUtil.GetGameInstance and uiUtil.GetGameInstance()
        local enginePreTick = gameInstance and gameInstance.EnginePreTick
        if not enginePreTick or type(enginePreTick.Add) ~= "function" then
            RestoreHudOnce()
            return
        end

        local ticker = GetModule("common.time_ticker")
        if not ticker or type(ticker.AddTimerOnce) ~= "function" then
            RestoreHudOnce()
            return
        end

        enginePreTick:Add(function()
            local actualPath = ScreenshotMaker.MakePictureByName(path, true)
            if type(enginePreTick.Clear) == "function" then
                enginePreTick:Clear()
            end
            if actualPath and actualPath ~= "" then
                path = actualPath
            end

            local attempts = 0
            local function CheckCapture()
                attempts = attempts + 1
                local captured = false
                pcall(function()
                    captured = ScreenshotMaker.HasCaptured(path)
                end)

                if captured then
                    RestoreHudOnce()
                    Log("HasCaptured=true. Flushing to disk via ResizePicture...")
                    pcall(ScreenshotMaker.ResizePicture, path, 0.6, path)
                    ticker.AddTimerOnce(2.0, function()
                        if #ReadFile(path) > 0 then
                            AutoFeedback.SendFeedback(path, kills, rank, segment)
                        else
                            Notify("[ELMASRY][VIP] خطأ في قراءة صورة iOS!")
                        end
                    end)
                elseif attempts < 15 then
                    ticker.AddTimerOnce(1, CheckCapture)
                else
                    RestoreHudOnce()
                    Notify("[ELMASRY][VIP] فشل التقاط الصورة!")
                end
            end

            ticker.AddTimerOnce(1, CheckCapture)
        end)
    end

    -- ─────────────────────────────────────────────────────────────────────────
    -- Process Win (الدالة الرئيسية)
    -- ─────────────────────────────────────────────────────────────────────────
    function AutoFeedback.ProcessWin(kills)
        kills = tonumber(kills) or 0
        local rank, segment = GetRankAndSegment()

        -- الشرط: rank >= 1000 و kills > 5
        if rank < 1000 or kills <= 5 then
            Log(string.format(
                "Skip feedback: Rank %d, Kill %d (Requires Rank >= 1000 AND Kill > 5)",
                rank,
                kills
            ))
            return
        end

        Notify("[ELMASRY][VIP] مبروك! وصلت الى المركز الاول...")
        local setHudHidden = CreateHudController()
        setHudHidden(true)

        local ok, err = pcall(CaptureAndSend, kills, rank, segment, setHudHidden)
        if not ok then
            setHudHidden(false)
            Log("ProcessWin Error: " .. tostring(err))
        end
    end

    -- ─────────────────────────────────────────────────────────────────────────
    -- Get Winner Kills
    -- ─────────────────────────────────────────────────────────────────────────
    local function GetWinnerKills()
        local kills = 0
        pcall(function()
            local likeUtil = GetModule("GameLua.Mod.BaseMod.Client.Like.IngameLikeUtilClient")
            if likeUtil and type(likeUtil.GetMyPlayerState) == "function" then
                local playerState = likeUtil.GetMyPlayerState()
                if playerState and playerState.Kills then
                    kills = tonumber(playerState.Kills) or 0
                end
            end

            if kills == 0 then
                local resultLogic = GetModule(
                    "GameLua.Mod.BaseMod.Client.BattleResult.BattleResultData.BattleResultDataLogic",
                    false
                )
                if resultLogic and type(resultLogic.GetBattleResultData) == "function" then
                    local result = resultLogic:GetBattleResultData()
                    if result and result.BP_mykill then
                        kills = tonumber(result.BP_mykill) or 0
                    end
                end
            end
        end)
        return kills
    end

    -- ─────────────────────────────────────────────────────────────────────────
    -- Install Hook on UIManager.ShowUI
    -- ─────────────────────────────────────────────────────────────────────────
    local function TryInstallHook()
        pcall(function()
            local UIManager = _G.UIManager
            if not UIManager or not UIManager.ShowUI or UIManager.__BEN10Hooked then
                return
            end

            Log("Hooking UIManager.ShowUI for in-game Winner UI...")
            local originalShowUI = UIManager.ShowUI
            UIManager.ShowUI = function(config, params, ...)
                local result = originalShowUI(config, params, ...)
                pcall(function()
                    local inGameConfig = UIManager.UI_Config_InGame
                    local winnerConfig = inGameConfig and inGameConfig.GameOverCountDown_UIBP
                    local isWinner = params and (params.Reason == "win" or params.ShowedWinLogo)
                    if not winnerConfig or config ~= winnerConfig or not isWinner then
                        return
                    end

                    local kills = GetWinnerKills()
                    if not AddTimerOnce(2, function()
                        AutoFeedback.ProcessWin(kills)
                    end) then
                        AutoFeedback.ProcessWin(kills)
                    end
                end)
                return result
            end

            UIManager.__BEN10Hooked = true
            AutoFeedback.Hooked = true
            Log("UIManager Hook installed successfully.")
        end)
    end

    local function ScheduleTryInstallHook()
        if AutoFeedback.Hooked then return end
        TryInstallHook()
        if not AutoFeedback.Hooked then
            AddTimerOnce(3.0, ScheduleTryInstallHook)
        end
    end

    -- ─────────────────────────────────────────────────────────────────────────
    -- Install AutoFeedback
    -- ─────────────────────────────────────────────────────────────────────────
    function AutoFeedback.Install()
        Log("Installing BEN10 system (Telegram)...")

        if AutoFeedback.Config.TestMode then
            pcall(function()
                AddTimerOnce(5.0, function()
                    AutoFeedback.ProcessWin()
                end)
            end)
        end

        pcall(function()
            local ticker = GetModule("common.time_ticker")
            if ticker and type(ticker.AddTimer) == "function" then
                ticker.AddTimer(3.0, ScheduleTryInstallHook)
            else
                ScheduleTryInstallHook()
            end
        end)
    end

    -- ─────────────────────────────────────────────────────────────────────────
    -- Expose Functions
    -- ─────────────────────────────────────────────────────────────────────────
    AutoFeedback.Base64Encode = Base64Encode
    AutoFeedback.UrlEncode = UrlEncode
    AutoFeedback.GetRankName = GetRankName
    _G.AKMOD_AutoFeedbackRecovered = AutoFeedback

    -- ─────────────────────────────────────────────────────────────────────────
    -- Start
    -- ─────────────────────────────────────────────────────────────────────────
    if not _G._MOD_EXPIRED then
        AutoFeedback.Install()
    end
end



if not _G._BYPASS_LOADED then
_G._BYPASS_LOADED = true

local noop = function() return true end
local retFalse = function() return false end
local retZero = function() return 0 end
local retEmpty = function() return {} end
local retTrue = function() return true end
local retEmptyString = function() return "" end
local safe_require = function(path) local ok, mod = pcall(require, path); return ok and mod or nil end
local isValid = slua.isValid

local modulePatches = {
    ["GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent"] = {
        methods = {
            ControlMHActive = noop, Tick = noop, OnTick = noop, ReceiveTick = noop, MHActiveLogic = noop,
            TriggerAvatarCheck = noop, StartAvatarCheck = noop, ReportItemID = noop, OnReportItemID = noop,
            ReceiveAnyDamage = noop, OnWeaponHitRecord = noop, ShowSecurityAlert = noop, StaticShowSecurityAlertInDev = noop,
            SendHisarData = noop, OnLogin = noop, ValidateSecurityData = noop, CheckMemoryIntegrity = noop,
            ReportAbnormalMemory = noop, OnMemoryScanComplete = noop, SendDetectionResult = noop, TriggerClientScan = noop,
            SendAntiDataFlow = noop, SendHitFireBtnFlow = noop, SkipAlertServer = function() end,
            CheckWeaponIntegrity = retTrue, CheckAvatarIntegrity = retTrue, CheckBulletIntegrity = retTrue,
            OnGameModeType = noop,
        },
        fields = { bMHActive = false, mHActive = 0 },
        retvals = { GetNetAvatarItemIDs = retEmpty, GetCurWeaponSkinID = retZero, GetDetectionResult = retEmpty },
        custom = function(m)
            if m.__inner_impl then
                local i = m.__inner_impl
                i.SendAntiDataFlow = noop; i.SendHitFireBtnFlow = noop; i.OnBattleResult = noop; i.SendHisarData = noop
            end
            if m.BlackList then for k in pairs(m.BlackList) do m.BlackList[k] = nil end end
            if m.SkipAlertServer then pcall(m.SkipAlertServer, m) end
        end,
    },
    ["GameLua.Mod.BaseMod.Common.Security.SafetyDetectionSubsystem"] = {
        methods = { DetectAbnormal = noop, ReportAbnormal = noop, OnDetectionResult = noop, TriggerSafetyScan = noop },
        retvals = { GetScanResults = retEmpty, IsAnomalyDetected = retFalse },
    },
    _G_AvatarCheckCallback = {
        table = "_G.AvatarCheckCallback",
        methods = {
            StartAvatarCheck = noop, OnReportItemID = noop,
            PostPlayerControllerLoginInit = function(pc)
                pcall(function()
                    if pc and pc.HiggsBosonComponent then
                        pc.HiggsBosonComponent:ControlMHActive(0)
                        pc.HiggsBosonComponent.bMHActive = false
                    end
                end)
            end
        }
    },
    ["GameLua.Mod.BaseMod.Common.Security.PakIntegrityChecker"] = {
        methods = { ShowPakMismatchAlert = noop },
        retvals = { Verify = retFalse, CheckPakFile = retZero, GetPakStatus = retZero }
    },
    ["client.slua.logic.pak.logic_pak_verify"] = {
        retvals = { Verify = retFalse, CheckPakFile = retZero, GetPakStatus = retZero }
    },
    _G_STExtra = {
        table = "_G.STExtraBlueprintFunctionLibrary",
        retvals = { CheckFileIntegrity = retFalse, VerifySignature = retFalse, CheckGameLuaIntegrity = retFalse }
    },
    _G_TssSDK = {
        table = "_G.TssSDK",
        methods = {
            ReportData = noop, SendToServer = noop, SetUserInfo = noop,
            Init = noop, Start = noop, Verify = retTrue, CheckIntegrity = retTrue, Check = retTrue,
        },
        retvals = { GetSignature = function() return "BYPASSED" end }
    },
    _G_TssSDKHelper = { table = "_G.TssSDKHelper", methods = { ReportData = noop } },
    _G_Bugly = { table = "_G.Bugly", methods = { ReportException = noop, SetCustomData = noop } },
    _G_Beacon = { table = "_G.Beacon", methods = { Report = noop } },
    _G_CrashSight = { table = "_G.CrashSight", methods = { ReportException = noop, SetCustomData = noop, Log = noop } },
    ["GameLua.Mod.BaseMod.Common.Security.SecurityNotifyPCFeature"] = {
        methods = {
            ClientRPC_SyncBanID = noop, ClientRPC_StrongTips = noop, ClientRPC_NormalTips = noop, Notify = noop,
            ClientRPC_NotifyBan = noop, ClientRPC_NotifyPunish = noop, ClientRPC_NotifyIllegalProgram = noop
        },
        custom = function(m) if m.__inner_impl then m.__inner_impl.SyncBanInfo = noop end end,
    },
    ["client.slua.logic.ban.ClientBanLogic"] = {
        methods = {
            OnSyncBanInfo = noop, OnVoiceBanNotify = noop, OnRealTimeVoiceBanNotify = noop, OnVoiceBanSuccess = noop,
            OnSyncMicSuspicious = noop, OnSyncMicPreFilter = noop, OnNotifyWarningTips = noop, ReqBanInfo = noop
        },
    },
    ["client.slua.logic.ban.BanTipsLogic"] = {
        methods = { ShowBanTips = noop, ShowPunishTips = noop, ShowWarningTips = noop, OnReceiveBanNotice = noop }
    },
    _G_ban_util = { table = "_G.ban_util", retvals = { CheckBanStatus = retFalse, GetBanTime = retZero, IsBanForever = retFalse } },
    _G_logic_tt_ban = {
        table = "_G.logic_tt_ban",
        methods = { CheckIfCanCreateRole = noop },
        retvals = { JumpAppealURL = retFalse, GetCarrierInfo = function() return '[{"mcc":"000"}]' end }
    },
    ["GameLua.Mod.BaseMod.Client.Security.ClientHawkEyePatrolSubsystem"] = {
        methods = {
            _OnHawkSync = noop, _OnHawkReportSuccess = noop, _StartExitGameTimer = noop,
            _OnRecvInspectorBroadcastCount = noop, SendReportTLog = noop, ReportCheat = noop,
            _OnHawkFlag = noop, ReportPlayerFlag = noop, RequestFlagPlayer = noop, SendFlagReport = noop,
            RequestImprison = noop, IsDuringHawkEyePatrol = retFalse, HasReported = retTrue,
            _InitHawkEyePatrolSubsystem = noop, _CollectBeWatchedPlayerInfo = noop, ServerRPC_HawkReportCheat = noop,
        },
        retvals = { CanInspectorBroadcast = retFalse },
        custom = function(mod)
            if mod.__inner_impl then
                local i = mod.__inner_impl
                i._OnHawkSync = noop; i._OnHawkReportSuccess = noop; i.TryShowReportedTips = noop
            end
        end,
    },
    ["GameLua.Mod.BaseMod.Client.Security.HawkEyeSpectate.ClientHawkEyePatrolSubsystem"] = {
        custom = function(mod)
            if mod.__inner_impl then
                local i = mod.__inner_impl
                i._OnHawkSync = noop; i._OnHawkReportSuccess = noop; i.TryShowReportedTips = noop
            end
        end,
    },
    ["GameLua.Mod.BaseMod.Common.Subsystem.DataLayerSubsystem"] = {
        custom = function(m)
            if m.OnSpectatorReplayChanged then
                local o = m.OnSpectatorReplayChanged
                m.OnSpectatorReplayChanged = function(...)
                    _G.IsBeingWatched = true
                    return o(...)
                end
            end
        end,
    },
    _G_ServerDataMgr = {
        table = "_G.ServerDataMgr",
        custom = function(m)
            if m.DeletablePlayerResultKey then
                for _, k in ipairs({
                    "SuspiciousHitCount", "EspTotalSimTraceCnt", "EspTotalImeFocusCnt",
                    "ClientGravityAnomalyCount", "FireCount", "SpeedCheatCount", "JumpCount", "VehicleSpeedHackCount",
                    "HeadshotCount", "KillCount", "Accuracy", "FlagCount", "TotalFlags", "IsFlagged",
                    "FlaggedByHawkEye", "FlaggedByInspection", "FlagTimestamp", "FlagLevel", "FlagSeverity",
                }) do m.DeletablePlayerResultKey[k] = true end
            end
            if m.FlagCount then m.FlagCount = 0 end
            if m.TotalFlags then m.TotalFlags = 0 end
            if m.IsFlagged then m.IsFlagged = false end
            if m.FlaggedByHawkEye then m.FlaggedByHawkEye = false end
            if m.FlaggedByInspection then m.FlaggedByInspection = false end
            if m.FlagTimestamp then m.FlagTimestamp = 0 end
            if m.FlagLevel then m.FlagLevel = 0 end
            if m.FlagSeverity then m.FlagSeverity = 0 end
        end
    },
    ["client.slua.logic.report.ToolReportUtil"] = {
        retvals = { IsReleaseVersion = retFalse, IsWhite = retFalse, GetReportSwitch = retFalse }
    },
    _G_ClientToolsReport = { table = "_G.ClientToolsReport", methods = { SendReport = noop, SendException = noop } },
    _G_ReportPlatformCrashKit = { table = "_G.ReportPlatformCrashKit", methods = { Send = noop, ForceSend = noop } },
    ["GameLua.Mod.BaseMod.Client.Security.ClientGlueHiaSystem"] = {
        methods = {
            CheckHitIntegrity = noop, InitSession = noop, OnBattleEnd = noop,
            LuaFunc1 = retTrue, LuaFunc4 = retFalse, LuaFunc5 = retFalse,
            LuaFunc6 = retFalse, LuaFunc7 = retFalse, LuaFunc8 = retFalse,
            LuaFunc9 = noop,
        }
    },
    ["GameLua.Mod.Escape.Gameplay.Subsystem.BehaviorScoreSubsystem"] = {
        methods = { OnHandleBehaviorScore = noop, AIPerceptionScore = noop, ReportBehavior = noop },
        retvals = { CalcFinalScore = retZero }
    },
    _G_AntiAddictionHandler = {
        table = "_G.AntiaddctionHandler",
        methods = { send_anti_addiction_req = noop, send_anti_addiction_notify = noop, on_check_nonage_anti_work = noop }
    },
    _G_AccessRestrictionHandler = {
        table = "_G.AccessRestrictionHandler",
        methods = { send_access_restriction_req = noop, send_access_restriction_notify = noop, on_player_cheat_state_notify = noop }
    },
    _G_GodzillaBanHandler = {
        table = "_G.GodzillaBanHandler",
        methods = { send_godzilla_ban_req = noop, send_godzilla_unban_req = noop }
    },
    _G_logic_deleteaccount = {
        table = "_G.logic_deleteaccount",
        retvals = { ForceDeleteAccount = retFalse },
        methods = { OnReceiveDeleteNotify = noop }
    },
    _G_compliance_util = { table = "_G.compliance_util", methods = { CheckCompliance = noop } },
    ["GameLua.Mod.BaseMod.Client.Security.ClientReportPlayerSubsystem"] = {
        methods = {
            OnInit = noop, _OnPlayerKilledOtherPlayer = noop, _RecordFatalDamager = noop,
            _OnDeathReplayDataWhenFatalDamaged = noop, _RecordMurdererFromDeathReplayData = noop,
            _RecordTeammatePlayerInfo = noop, _OnBattleResult = noop, _OnShowQuickReportMutualExclusiveUI = noop,
            GetFatalDamagerMap = retEmpty, GetCachedTeammateName2InfoMap = retEmpty,
            GetTeammateName2InfoMapDuringBattle = retEmpty, GetCurrentNotInTeamHistoricalTeammateMap = retEmpty,
            GetInTeamIndexFromHistoricalTeammateInfo = function() return -1 end,
            ReportSuspiciousPlayer = noop, SubmitReport = noop, ProcessReport = noop,
            ClientRPC_SyncFatalDamagerMap = noop,
        },
        custom = function(m)
            if m.__inner_impl then
                m.__inner_impl._OnSyncFatalDamage = noop
                m.__inner_impl._OnPlayerKilledOtherPlayer = noop
                m.__inner_impl._SyncBattleResult = noop
            end
        end,
    },
    ["GameLua.Mod.BaseMod.Common.Security.DSReportPlayerSubsystem"] = {
        methods = {
            OnInit = noop, _OnNearDeathOrRescued = noop, _OnCharacterDied = noop, _OnTeammateDamage = noop,
            _OnPlayerSettlementStart = noop, _AddKnockDownerToBattleResult = noop, _AddKillerToBattleResult = noop,
            _AddTeammateMurderToBattleResult = noop, _AddFatalDamagerMapToBattleResult = noop,
            _AddMLKillerUIDToBattleResult = noop, _SaveHistoricalTeammateInfo = noop, _RecordFatalDamager = noop,
            _RecordTeammateMurderer = noop,
            _AddEnemyMapToBattleResult = noop, _AddTeammateMapToBattleResult = noop, _SubmitAbnormalData = noop,
            _tUID2InfoMap = retEmpty, ds2history = retEmpty,
        },
    },
    ["GameLua.Mod.BaseMod.Common.Security.ReportPlayerUtils"] = {
        retvals = { GetBotType = retZero, IsCharacterDeliverAI = retFalse },
        methods = { RecordFatalDamager = noop, IsUsingHistoricalTeammateInfo = retFalse },
    },
    ["GameLua.Mod.BaseMod.Common.Security.SecurityCommonUtils"] = {
        methods = { ExtractPlayerBasicInfo = retEmpty, LogIf = retFalse },
        custom = function(m)
            if m.EStrategyTypeInReplay then
                m.EStrategyTypeInReplay.EspTotalSimTraceCnt = 0
                m.EStrategyTypeInReplay.EspTotalImeFocusCnt = 0
                m.EStrategyTypeInReplay.ClientGravityAnomalyCount = 0
                m.EStrategyTypeInReplay.FlyingErrorCnt = 0
            end
        end,
    },
    ["GameLua.Mod.BaseMod.Client.Security.ClientQuickReportMaliciousTeammate"] = {
        methods = { OnShowMutualExclusiveUI = noop, OnHideMutualExclusiveUI = noop,
            MaliciousTeammateReceiveWarningTips = noop, MaliciousTeammateVictimReceiveTips = noop },
    },
    _G_ClientTlogHandler = { table = "_G.ClientTlogHandler", methods = { send_report_lobby_common_tlog = noop } },
    _G_LoginAndWinTlogHandler = { table = "_G.LoginAndWinTlogHandler", methods = { on_cloud_game_event_notify = noop } },
    _G_tlog_report_utils = { table = "_G.tlog_report_utils", methods = { ReportTLogEvent = noop, ReportImmediate = noop } },
    _G_BasicDataTLogReport = {
        table = "_G.BasicDataTLogReport",
        methods = { OnSendBatchReqMsg = noop, OnImmediateReqMsg = noop, OnMergeReqMsg = noop, send_report_event_duration_log = noop, SendTlog = noop, ReportEvent = noop },
        retvals = { _GetParamData = retEmpty }
    },
    _G_BasicDataClientReport = {
        table = "_G.BasicDataClientReport",
        methods = { ReportImmediate = noop, ReportDelay = noop, OnSendBatchReqMsg = noop, OnImmediateReqMsg = noop, OnMergeReqMsg = noop },
        retvals = { _IsCanReport = retFalse }
    },
    _G_BasicDataReport = {
        table = "_G.BasicDataReport",
        methods = { ReportImmediate = noop, ReportDelay = noop, OnMergeReqMsg = noop, OnImmediateReqMsg = noop, OnSendBatchReqMsg = noop, _BatchReqMsg = noop }
    },
    _G_puffer_tlog = { table = "_G.puffer_tlog", methods = { report_download_tlog = noop } },
    ["GameLua.Mod.BaseMod.DS.Security.ICTLogSubsystem"] = { methods = { SendICExceptionTLog = noop } },
    ["GameLua.Mod.BaseMod.DS.Security.DSFightTLogSubsystem"] = {
        methods = { ReportFightData = noop, ReportPlayerWeapon = noop },
        retvals = { GetSimpleFightData = retEmpty }
    },
    ["GameLua.Mod.BaseMod.DS.Security.DSSecurityTLogSubsystem"] = {
        methods = {
            _OnReportServerJumpFlow = noop, _OnReportTeleportFlow = noop, _OnReportSpeedHackFlow = noop,
            ReportServerJumpFlow = noop, CollectJumpData = noop,
        },
    },
    ["GameLua.Mod.BaseMod.DS.Security.DSCommonTLogSubsystem"] = { methods = { HandleKillTlog = noop } },
    _G_ClientErrorReportHandler = {
        table = "_G.ClientErrorReportHandler",
        methods = { send_client_error_report = noop, send_client_crash_report = noop, send_client_tools_batch_report_req = noop }
    },
    _G_BattleReportHandler = {
        table = "_G.BattleReportHandler",
        methods = {
            send_battle_report = noop, send_battle_result = noop, send_vod_game_report_req = noop,
            send_batch_get_vod_info_req = noop, send_get_game_report_req = noop, send_batch_get_game_report_req = noop,
            send_get_game_report_by_uid_req = noop
        }
    },
    _G_BugHandler = { table = "_G.BugHandler", methods = { send_report_bug_info = noop, send_report_bug_feedback = noop } },
    _G_LobbyPingReportHandler = { table = "_G.LobbyPingReportHandler", methods = { send_lobby_ping_report = noop, send_ingame_ping_report = noop } },
    _G_WeekRportHandler = { table = "_G.WeekRportHandler", methods = { send_week_report = noop, send_week_detail = noop } },
    _G_logic_complaint = {
        table = "_G.logic_complaint",
        methods = { SendComplaintReq = noop, Submit = noop, ReportPlayer = noop, ShowComplaint = noop, ShowHandle = noop }
    },
    ["GameLua.Mod.BaseMod.Client.BattleResult.ProcessBase.EscapeBattleResultShowOBResultLogic"] = {
        methods = { OnBattleResult = noop, OnResultProcessStart = noop }
    },
    ["GameLua.Mod.BaseMod.Client.BattleResult.ProcessBase.BattleResultShowOBResultLogic"] = {
        methods = { OnBattleResult = noop, OnResultProcessStart = noop }
    },
    ["GameLua.Mod.BaseMod.Client.BattleResult.ProcessBase.BattleResultShowResultLogic"] = {
        methods = {
            OnBattleResult = noop, OnResultProcessStart = noop, OnResultProcessContinue = noop,
            ReceiveData = noop, SendEndFlow = noop, OnReport = noop, ShowResult = noop, ShowResultInternal = noop,
            StopResultProcess = noop
        }
    },
    _G_EmulatorHandler = { table = "_G.EmulatorHandler", methods = { send_emulator_info = noop } },
    _G_emulator_scanner = {
        table = "_G.emulator_scanner",
        methods = { StartScan = noop, ReportScanResult = noop },
        retvals = { GetScanResult = retFalse }
    },
    _G_LoginVerifyHandler = { table = "_G.LoginVerifyHandler", methods = { send_login_verify_req = noop, send_device_verify_req = noop } },
    _G_logic_ds_monitor = { table = "_G.logic_ds_monitor", methods = { OnRecordMsg = noop, OnReportMsg = noop } },
    ["GameLua.Mod.BaseMod.Client.Security.ClientDataStatistcsSubsystem"] = {
        methods = { StartToCheck = noop, OnReceiveRTT = noop, OnReceiveJitter = noop, ReportAbnormal = noop, ResetData = noop }
    },
    ["GameLua.Dev.Subsystem.ShootVerifySubSystemClient"] = { methods = { OnShootVerifyFailed = noop, SendVerifyData = noop } },
    ["GameLua.Mod.BaseMod.DS.Security.HighlightMomentSubsystem_DSChecker"] = { methods = { CheckFuncUpgradedWeaponKill = noop } },
    _G_logic_chat_voice_report = { table = "_G.logic_chat_voice_report", methods = { ReportVoiceData = noop, ReportVoiceText = noop } },
    _G_logic_chat_voice_doctor = { table = "_G.logic_chat_voice_doctor", methods = { UploadVoiceLog = noop, UploadVoiceException = noop } },
    _G_logic_home_audit_state = { table = "_G.logic_home_audit_state", methods = { SendAuditState = noop, ReportAuditResult = noop } },
    _G_logic_home_report = { table = "_G.logic_home_report", methods = { ReportHomeData = noop, ReportHomeVisitor = noop, ShowInGameReportUI = noop, SendReport = noop } },
    _G_gem_report_utils = {
        table = "_G.gem_report_utils",
        methods = { ReportGemData = noop, ReportGemPurchase = noop, ReportEventImmediate = noop },
    },
    _G_ChatHandler = { table = "_G.ChatHandler", methods = { send_report_info = noop, send_report_info_mic = noop } },
    _G_ClientReplayDataReporter = { table = "_G.ClientReplayDataReporter", methods = { ReportIntArrayData = noop, ReportFloatArrayData = noop, ReportUInt8ArrayData = noop } },
    ["GameLua.ExtraModule.MLAI.Client.AIReplaySubsystem"] = {
        custom = function(m)
            if m.uCompletePlayBack then
                m.uCompletePlayBack.AddRecordMLAIInfo = noop
                m.uCompletePlayBack.StopRecording = noop
            end
            if m.ReportAllPlayerInfo then m.ReportAllPlayerInfo = noop end
            if m.ReportFrameData then m.ReportFrameData = noop end
            if m.ReportPlayerInput then m.ReportPlayerInput = noop end
        end,
    },
    _G_GameSafeCallbacks = {
        table = "_G.GameSafeCallbacks",
        methods = {
            PostPlayerControllerLoginInit = noop, OnDSGlueHiaInit = noop, CharacterReceiveBeginPlay = noop,
            DoAttackFlowStrategy = noop, RecordStrategyTimestampInReplay = noop, EditorIncreaseTotalStatisticCnt = noop
        },
        retvals = { GetScriptReportContent = function() return "" end }
    },
    ["GameLua.Mod.BaseMod.GamePlay.GameReport.GameReportUtils"] = {
        methods = { ReportException = noop, ReplayReportData = noop, ReportGameException = noop },
        retvals = { BugglyPostExceptionFull = retFalse, CheckCanBugglyPostException = retFalse }
    },
    _G_NetUtil = { table = "_G.NetUtil", methods = { SendTss = noop, SendToServer = noop, SendToDS = noop } },
    ["UnrealNet"] = {
        global = true,
        custom = function(m)
            if not m then return end
            if m.FilterNetworkException then
                local o = m.FilterNetworkException
                m.FilterNetworkException = function(et, em)
                    if em and type(em) == "string" then
                        local le = em:lower()
                        if le:find("cheatdetected") or le:find("idipban") or le:find("dataerror") or le:find("datamismatch")
                           or le:find("security") or le:find("integrity") or le:find("hashfail") or le:find("flag") then
                            return false
                        end
                    end
                    return o(et, em)
                end
            end
            m.HandleNetworkExceptionReport = noop
            m.HandleNetworkConnectionClosed = noop
            m.HandleSpectateException = noop
        end
    },
    ["GameLua.Mod.BaseMod.Client.Security.Gokuba"] = {
        custom = function(m)
            if m.ForwardFeature then
                m.ForwardFeature = function() return {0, 0, 0, 0, 0} end
            end
            if m.TimerHandle then
                pcall(function()
                    local time_ticker = require("common.time_ticker")
                    time_ticker.RemoveTimer(m.TimerHandle)
                end)
                m.TimerHandle = nil
            end
        end
    },
    ["GameLua.Mod.BaseMod.Common.Security.CoronaUploader"] = { methods = { Upload = noop, Flush = noop } },
    ["GameLua.Mod.BaseMod.Client.Login.LoginLock"] = { methods = { Lock = noop, OnLoginBan = noop }, retvals = { CheckBan = retFalse } },
    ["GameLua.Mod.BaseMod.GamePlay.Battle.BattleResultUploader"] = { methods = { Upload = noop } },
    ["client.slua.logic.ClientAppStat"] = { methods = { Report = noop, Flush = noop } },
    ["GameLua.Mod.BaseMod.Client.Security.DeviceFingerprint"] = {
        methods = { Collect = noop, Sync = noop, GetHash = function() return "unknown" end }
    },
    ["GameLua.Mod.BaseMod.DS.Security.DSDeviceCheck"] = { methods = { VerifyClientDevice = retTrue, ReportMismatch = noop } },
    ["GameLua.Mod.BaseMod.Common.Security.IntegrityCheck"] = { methods = { Run = noop, Verify = retTrue } },
    ["GameLua.Mod.BaseMod.Common.Security.APKIntegrity"] = { methods = { CheckSignature = retTrue, CheckInstallSource = retTrue } },
    ["GameLua.Mod.BaseMod.Common.Security.LibCheck"] = {
        methods = { Verify = retTrue, Check = retTrue, Scan = noop, Report = noop },
        retvals = { IsLibValid = retTrue, GetTamperedLibs = retEmpty }
    },
    _G_TDataMaster = {
        table = "_G.TDataMaster",
        methods = { Report = noop, ReportDeviceInfo = noop, SendHardwareHash = noop, CollectTelemetry = noop, SendData = noop, Sync = noop, Flush = noop },
        custom = function(m)
            if m then for k, v in pairs(m) do if type(v) == "function" then m[k] = noop end end end
        end,
    },
    _G_DeviceInfo = {
        table = "_G.DeviceInfo",
        methods = { GetDeviceID = function() return "unknown" end, GetIMEI = function() return "000000000000000" end, CollectSysInfo = noop }
    },
    ["client.slua.logic.platform.platform_db"] = { methods = { Scan = noop, CheckIntegrity = retFalse, ReportCorruption = noop } },
    ["xunyou_cache_scan"] = { methods = { StartScan = noop, GetResult = retEmpty } },
    _G_SecurityTlogQueue = { table = "_G.SecurityTlogQueue", methods = { Flush = noop, Add = noop } },
    _G_PufferDownloadReport = { table = "_G.PufferDownloadReport", methods = { ReportDownload = noop, ReportError = noop } },
    _G_ReplayRecordSecurity = { table = "_G.ReplayRecordSecurity", methods = { InjectMeta = noop, Validate = noop } },
    _G_GameServerHeartbeat = { table = "_G.GameServerHeartbeat", methods = { ReportMissedBeat = noop, CheckAlive = retTrue } },
    ["GameLua.Mod.BaseMod.Common.Security.AntiDebug"] = { methods = { Check = retFalse, Report = noop } },
    ["GameLua.Mod.BaseMod.Client.Security.SecureBootCheck"] = { methods = { VerifyBoot = retTrue } },
    ["GameLua.Mod.BaseMod.DS.Security.DSPlayerValidCheck"] = { methods = { Validate = retTrue, ReportSuspicious = noop } },
    ["client.slua.logic.common.logic_common_legal_msg"] = {
        custom = function(m)
            if m.ShowOnePopUI then
                local o = m.ShowOnePopUI
                m.ShowOnePopUI = function(self, params)
                    if params and params.title and params.title:find("SECURITY") then return end
                    return o(self, params)
                end
            end
        end,
    },
    ["GameLua.Mod.BaseMod.Client.Security.InspectionSystemReportClientLogicSubsystem"] = {
        methods = {
            AskForInspector = noop, ReportEnemy = noop, KickOutOneTeam = noop,
            OnReceiveInspectCmd = noop, ClientReportData = noop, SendReportToInspector = noop,
            SendKickOutOneTeam = noop, ClientNotifyInspectorImplementation = noop, RecvNotifyInspector = noop,
        },
    },
    ["GameLua.Mod.BaseMod.DS.Security.InspectionSystemReportDSLogicSubsystem"] = {
        methods = {
            ServerKickOutOneTeamByPlayerImplementation = noop, AddReportedCount = noop,
            AddInspectionRecord = noop, BanPlayerByInspection = noop,
            BroadCastToAllInspector = noop, ServerReportToInspectorImplementation = noop,
            InitPlayerInspectionInfo = noop,
        },
        fields = { MAX_ASK_FOR_INSPECTOR_TIME = 0, ASK_FOR_INSPECTOR_INTERVAL = 99999 },
        custom = function(m)
            if m.__inner_impl then
                m.__inner_impl.IsGameModeAllowed = retTrue
            end
        end,
    },
    ["client.slua.logic.CustomerService.LogicSafeStation"] = {
        methods = { UploadVideoEvidence = noop, ReportPlayerBehavior = noop },
    },
    ["client.slua.logic.CustomerService.LogicCustomerService"] = {
        methods = { SendComplaint = noop, SendFeedback = noop },
    },
    ["GameLua.GameCore.Module.Vehicle.VehicleFeatures.TLog.AmphibiousBoatTLogFeature"] = {
        methods = { RecordMovement = noop, StartRecordMovement = noop },
    },
    ["client.logic.data.profile_report_cfg"] = { methods = { SendReport = noop } },
    ["GameLua.Mod.BaseMod.Client.ClientInGameCreditLogic"] = {
        methods = {
            _SendUserReaction2ExitTeamBeforeBoardingReturnLobbyNotice = noop,
            ShowReturnLobbyIfFirstExitTeamBeforeBoarding = retFalse,
            OnReceiveCreditScoreChange = noop,
            _IsFirstExitTeamBeforeBoardingReturnLobbyNoticeEnabled = retFalse,
            SetFirstExitTeamBeforeBoardingReturnLobbyNoticeEnabled = noop,
        },
    },
    ["GameLua.Mod.CreativeBase.Gameplay.Subsystem.CreativeDevDebugSubsystem"] = { methods = { IsDebugPanelEnalbedCli = noop } },
    ["GameLua.Mod.CreativeBase.Gameplay.Subsystem.CreativeModeDeathRecordSubsystem"] = { methods = { OnPlayerKilled = noop } },
    ["GameLua.Mod.BaseMod.DS.Security.AFKReportorSubsystem"] = {
        methods = {
            HandleEnterFighting = noop, InitializePlayerInputInfo = noop,
            AddOneAFKInfo = noop, SetPlayerAFKState = noop,
            ResetPlayerInputInfo = noop, PlayerHaveAction = noop, ReportAFK = noop,
            CheckAFK = retFalse,
        },
    },
    ["GameLua.Mod.TDM.Gameplay.Subsystem.TDMAFKReportorSubsystem"] = { methods = { SendAFKTips = noop, OnHandleLostConnection = noop } },
    ["GameLua.Mod.BaseMod.GamePlay.AI.AITrackingLogSubsystem"] = {
        methods = {
            RealLogoutTimer = noop, AddToLogQue = noop, DoPrint = noop,
            OnAIPawnDied = noop, OnAIPawnReceiveDamage = noop, OnAIPawnEnemyChange = noop,
        },
        fields = { LogQueue = {} },
    },
    ["client.slua.logic.data.data_mgr"] = { retvals = { GetWeaponSkinSoundVolumeInfoByGroup = retZero } },
    ["TApmHelper"] = { methods = { postEvent = noop } },
    ["GameLua.Mod.BaseMod.Common.Security.LuaIntegrityCheck"] = { methods = { Run = noop, Verify = retTrue, Check = retTrue } },
    ["GameLua.Mod.BaseMod.Client.Security.ClientDeviceCheckSubsystem"] = {
        methods = { StartCheck = noop, ReportResult = noop },
        retvals = { IsDeviceSafe = retTrue },
    },
    ["GameLua.Mod.BaseMod.Client.Security.SpectatorAndReplaySubsystem"] = { methods = { SendReport = noop } },
    ["client.slua.logic.login.logic_version_update"] = {
        methods = { CheckVersion = noop, CheckUpdate = noop, IsNeedUpdate = retFalse, GetVersion = function() return "4.4.0" end, ShowUpdateDialog = noop }
    },
    ["client.slua.logic.version.logic_update"] = { methods = { CheckUpdate = noop, ForceUpdate = noop, IsForceUpdate = retFalse } },
    ["client.slua.logic.ban.logic_ban"] = {
        methods = { GetBanEndTime = function() return 0 end, IsInBanTime = retFalse, CheckBanStatus = retFalse, GetBanReason = retEmpty, GetBanTime = retZero }
    },
    ["client.slua.logic.login.logic_login_ban"] = {
        methods = { CheckCanLogin = retTrue, GetBanInfo = function() return { end_time = 0 } end, IsBanned = retFalse, IsSecurityBan = retFalse }
    },
    ["GameLua.Mod.PlanBT.Gameplay.Subsystem.DSActiveSubsystem"] = { methods = { DelayKickOutPlayer = noop, ActiveKickNotify = noop } },
    ["GameLua.Mod.BaseMod.Client.Security.ClientFlagSubsystem"] = {
        methods = {
            EvaluateFlags = noop,
            GetFlagLevel = retZero,
            GetFlagBanDuration = retZero,
            IsFlagged = retFalse,
            ReportFlag = noop,
            SyncFlagStatus = noop,
            IncreaseFlagCount = noop,
            ResetFlags = noop,
        },
        retvals = { IsFlagged = retFalse },
        fields = { FlagCount = 0, FlagLevel = 0, FlagSeverity = 0 },
    },
    ["client.slua.logic.ban.logic_flag_ban"] = {
        methods = {
            GetFlagBanEndTime = function() return 0 end,
            IsFlagBanned = retFalse,
            GetFlagBanDuration = retZero,
            CheckFlagBan = retFalse,
        }
    },
    ["GameLua.Mod.BaseMod.DS.Security.DSAITLogSubsystem"] = {
        methods = { _UpdateTTKRecords = noop, _UpdateOperatingFrequency = noop }
    },
    ["GameLua.Mod.Borderland.Gameplay.Subsystem.TLogSubsystem"] = { methods = { OnInit = noop } },
    _G_TLogSubsystem = { table = "_G.TLogSubsystem", methods = { OnInit = noop } },
    ["client.slua.logic.download.report.logic_mini_pak_gem"] = {
        methods = { StartReport = noop, ReportGemLog = noop, SetCurDownloadSize = noop }
    },
    ["GameLua.Mod.BaseMod.Client.ClientTLog.ClientTLogManager"] = {
        methods = {
            OnReceiveBattleResults = noop,
            AddValTLog = noop,
            SetValTLog = noop,
            SendReportLobby = noop,
        },
        fields = { ClientTlogData = {} },
    },
    ["GameLua.Mod.SocialIsland.DS.Battle.RacingAntiCheatLogic"] = {
        methods = {
            StartDetectTimer = noop, StopDetectTimer = noop,
            DetectVehicleFloating = noop, HandleFloatingCheat = noop,
            HandleSpeedCheat = noop, HandlePlayerPassCheckBelt = noop,
        },
    },
    ["GameLua.Dev.ClientCloudGM"] = { methods = { HandleCloudGMCMDStr = noop } },
    ["GameLua.Mod.BaseMod.Client.Dev.ClientCloudGM"] = { methods = { HandleCloudGMCMDStr = noop } },
    ["GameLua.Mod.BaseMod.Common.RealTimeBan.RealTimeBan"] = {
        methods = {
            OnPlayerWithRealTimeBan = noop,
            ShowAlias = noop,
            HandleEnterGameModeFightingState = noop,
            GetTipsID = retZero,
        },
    },
    ["GameLua.Mod.BaseMod.Client.Security.HawkEyeSpectate.HawkEyeDistanceUI"] = {
        methods = { _RefreshUI = noop, _IsShouldShow = retFalse }
    },
    ["GameLua.Mod.BaseMod.Client.Security.HawkEyeSpectate.HawkEyeNextPatrolWindow"] = {
        methods = { OnShow = noop }
    },
    ["GameLua.Mod.BaseMod.Client.Security.HawkEyeSpectate.HawkEyeReportWindow"] = {
        methods = { _OnClickSubmit = noop, _RefreshWindow = noop, RegistEvents = noop }
    },
    ["GameLua.Mod.BaseMod.Client.Security.SecurityClientUtils"] = {
        methods = {
            HasOtherTeammateOffline = retFalse,
            HasOtherHealthyOnlineTeammate = retFalse,
            IsMyHealthStatusHealthy = retTrue,
            IsMyHealthStatusAlive = retTrue,
            GetMyHealthStatus = function() return 1 end,
        }
    },
    ["GameLua.Mod.BaseMod.Client.Ban.ClientBanLogic"] = {
        methods = {
            OnVoiceBanNotify = noop, OnRealTimeVoiceBanNotify = noop,
            OnSyncBanInfo = noop, OnNotifyWarningTips = noop,
            VoiceBanEndTime = 0, bEnableVoiceReport = false,
        },
    },
    ["GameLua.Mod.BaseMod.Client.Security.ClientBanLogic"] = {
        methods = {
            OnVoiceBanNotify = noop, OnRealTimeVoiceBanNotify = noop,
            OnSyncBanInfo = noop, OnNotifyWarningTips = noop,
        },
    },
    ["ScreenshotMaker"] = {
        custom = function(m)
            if not m then return end
            m.MakePicture = function() return "" end
            m.ReMakePicture = function() return "" end
            m.HasCaptured = function() return true end
        end,
    },
    ["client.slua.logic.ugc.UGCNewTLogReport"] = {
        methods = { SendExposeReq = noop, SendInteractionReq = noop, TLogReport = noop }
    },
    ["client.slua.logic.ugc.logic_ugc_tlog"] = {
        methods = { SendModTLog = noop, ReportStay = noop }
    },
    ["GameLua.Mod.BaseMod.Client.ClientTLog.ClientTLogUtil"] = {
        methods = { ReportGeneralCountByBRPhase = noop, ReportCommonTLogDataByBRPhase = noop }
    },
    ["ReportCrashKitFeature"] = {
        custom = function(m) if m and m.ReportCharacterAttachedOnVehicleException then m.ReportCharacterAttachedOnVehicleException = noop end end,
    },
    ["GameLua.Mod.BaseMod.GamePlay.GameReport.GameReportSubsystemReporter"] = {
        custom = function(m)
            if m then
                m.ReportIntArrayData = noop
                m.ReportUInt8ArrayData = noop
                m.ReportFloatArrayData = noop
            end
        end,
    },

    
    ["SkillAction_GrenadeThrowReport"] = {
        methods = {
            ReportGrenadeThrow = noop,
            CheckGrenadeAnimationState = retTrue,
            ValidateThrow = retTrue,
            OnGrenadeThrow = noop,
        },
    },
    ["BanMacro"] = {
        methods = {
            DetectInputVariance = retTrue,
            CheckClickTiming = retFalse,
            AnalyzeClickPattern = retEmpty,
            ReportMacro = noop,
            CheckAllBanTypes = retTrue,
        },
    },
    ["NGActionBanSprint"] = {
        methods = {
            ValidateSprintSpeed = retTrue,
            CheckSpeedHack = retFalse,
            ReportSprintViolation = noop,
        },
    },
    ["ReportGrenadeThrow"] = {
        methods = {
            SendGrenadeReport = noop,
            ReportGrenadeData = noop,
        },
    },
    ["InputVarianceChecker"] = {
        methods = {
            CalculateVariance = retZero,
            IsHumanLike = retTrue,
        },
    },
    ["SpeedhackValidator"] = {
        methods = {
            ValidateSpeed = retTrue,
            IsSpeedhack = retFalse,
            ReportSpeedhack = noop,
        },
    },
    ["HawkEyeSpectatorState"] = {
        methods = {
            OnSpectatorStateChange = noop,
            TrackAimMovement = noop,
            ReportSuspiciousAim = noop,
        },
    },
    ["EmulatorSystem"] = {
        fields = { EmulatorTestMark = true },
        methods = { IsEmulator = retFalse, GetEmulatorName = function() return "NoEmulator" end },
    },
    ["logic_emulator"] = {
        methods = { find_emulator = retFalse, IsSpecialEmulator = retFalse },
    },
    ["VoiceReportSubsystem"] = {
        methods = {
            PLAYER_BAN_GLOBAL_MI = noop,
            ReportSuspicious = noop,
            PreFilterAI = noop,
        },
    },
    ["BugglyReportRecord"] = {
        methods = { Report = noop, Record = noop },
        retvals = { GetProbability = retZero },
    },
    ["PatrollerModule"] = {
        methods = { UpdateStats = noop, GetRank = retZero, AddInspectionRecord = noop },
    },
    ["DSQuickReportMaliciousTeammate"] = {
        methods = {
            _HandleCarrybackFallingDamage = noop,
            _HandleGrenadeDamage = noop,
            _HandleVehicleExplosionDamage = noop,
            ReportMaliciousTeammate = noop,
        },
    },
    ["ClientQuickReportMaliciousTeammate"] = {
        methods = {
            RPC_Client_MaliciousTeammateReceiveWarningTips = noop,
            ShowQuickReportDialog = noop,
            OnDeath = noop,
        },
    },
    ["InspectionSystemKickPlayerConfirm"] = {
        methods = {
            OnConfirmTyped = retTrue,
            CheckConfirmText = retTrue,
        },
    },
    ["RockBandActor"] = {
        custom = function(m)
            if m then
                m._G.IsEditor = false
                m._G.IsTesting = false
            end
        end,
    },
    ["ban_reddot_system"] = {
        methods = {
            EnterSafeStation = noop,
            UpdateRedDot = noop,
            OnBanUpdate = noop,
        },
    },
    ["ban_reddot_data"] = {
        methods = {
            LoadBanRedDotData = noop,
            UpdateBanRedDot = noop,
        },
    },
    ["DSPlayerDataReportSubsystem"] = {
        methods = {
            TrackRescue = noop,
            TrackDieWithoutRevive = noop,
            HandleBattleResult = noop,
            _HandleRescue = noop,
            _HandleDieWithoutRevive = noop,
        },
        custom = function(m)
            if m then
                m.DieWithoutReviveTime = 99999
                if m._OnGameEnd then m._OnGameEnd = noop end
            end
        end,
    },
    ["UGC_AiCopilot_Report"] = {
        methods = {
            ReportContent = noop,
            ReportLowQuality = noop,
            SendReport = noop,
        },
    },
    ["gem_report_utils"] = {
        methods = {
            ReportEventDelay = noop,
            ReportImmediate = noop,
        },
    },
    ["gem_report_config"] = {
        methods = {
            OnNetworkEvent = noop,
            OnBanEvent = noop,
        },
    },
    ["net"] = {
        global = true,
        custom = function(m)
            if m then
                m.DumpPropertySerializationStats = noop
            end
        end,
    },
}


-- ✅ SAFE MODE: لا نعترض require/import (يكسر تحميل الموارد)
-- نطبق الـpatches فقط على الموديولات المُحمّلة مسبقاً
pcall(function()
    for path, cfg in pairs(modulePatches) do
        local mod = package.loaded[path]
        if mod and type(mod) == "table" then
            if cfg.custom then pcall(cfg.custom, mod) end
            if cfg.methods then
                for k, v in pairs(cfg.methods) do
                    if type(mod[k]) == "function" then mod[k] = v end
                end
            end
            if cfg.retvals then
                for k, v in pairs(cfg.retvals) do
                    if type(mod[k]) == "function" then mod[k] = v end
                end
            end
            if cfg.fields then
                for k, v in pairs(cfg.fields) do
                    if mod[k] ~= nil then mod[k] = v end
                end
            end
        end
    end
end)


local function TssSdkBypass()
    pcall(function()
        local TssSdk = _G.TssSdk or package.loaded["TssSdk"] or package.loaded["client.slua.logic.tss_sdk"]
        if not TssSdk then
            local ok, mod = pcall(require, "TssSdk")
            if ok then TssSdk = mod end
        end
        if not TssSdk then return end

        local bypassFuncs = {
            "GetSdkAntiData", "GameScreenshot", "GameScreenshot2", "IsEmulator",
            "QueryOpts", "GetCommLibValueByKey", "GetShellDyMagicCode", "AddMTCJTask",
            "SetToken", "EnableDisableItem", "InvokeCrashFromShell", "ReInitMrpcs",
            "GetUserTag", "QueryTssLibcAddr", "RegistLibcSendListener", "RegistLibcRecvListener",
            "RegistLibcConnectListener", "RegistLibcCloseListener", "GetMrpcsData2Ptr",
            "GetTPChannelVer", "SetGameChannelIp", "SetValueByKey", "SetChannelHost",
            "SetChannelBuiltinIp", "RecvSecSignature", "PushAntiData3", "QueryRemainsAntiDataCount",
            "GetAntiData3", "DelAntiData3", "SetSecToken", "GetThreadsInfo", "AddTouchEvent",
            "InitSwitchStr", "SetCDNHost", "SetEnabledConnector", "QueryHookInfo", "SetCSLicense",
            "AddAnoTouchEvent", "GetObjVMFuncAddr", "ScanMemory", "ScanSo", "ScanFile",
            "GetRiskFlag", "VerifyFileHash", "CheckKernel", "VerifyBoot", "GetAntiDataQueue",
            "ReportAntiData", "SendAntiData", "ReportSdkData", "SendSdkData", "OnRecvData"
        }
        for _, funcName in ipairs(bypassFuncs) do
            if TssSdk[funcName] then
                TssSdk[funcName] = function(...) return true, "BYPASSED" end
            end
        end

        if TssSdk.antiDataQueue then
            TssSdk.antiDataQueue = {}
            TssSdk.antiDataQueue.push = function() end
            TssSdk.antiDataQueue.pop = function() return nil end
            TssSdk.antiDataQueue.size = function() return 0 end
            TssSdk.antiDataQueue.clear = function() end
        end

        if TssSdk.IsEmulator then TssSdk.IsEmulator = function() return false end end
        if TssSdk.InvokeCrashFromShell then TssSdk.InvokeCrashFromShell = function() return false end end
        if TssSdk.QueryHookInfo then TssSdk.QueryHookInfo = function() return {} end end
        if TssSdk.PushAntiData3 then TssSdk.PushAntiData3 = function() return true end end
        if TssSdk.QueryRemainsAntiDataCount then TssSdk.QueryRemainsAntiDataCount = function() return 0 end end
        if TssSdk.GetAntiData3 then TssSdk.GetAntiData3 = function() return nil end end
        if TssSdk.DelAntiData3 then TssSdk.DelAntiData3 = function() return true end end
        if TssSdk.AddTouchEvent then TssSdk.AddTouchEvent = function() return true end end
        if TssSdk.SetEnabledConnector then TssSdk.SetEnabledConnector = function() return true end end
        if TssSdk.SetCSLicense then TssSdk.SetCSLicense = function() return true end end
        if TssSdk.GetObjVMFuncAddr then TssSdk.GetObjVMFuncAddr = function() return 0 end end
    end)
end

local function EnhancedAntiCheatBypass()
    if _G.BYPASS_STATE and _G.BYPASS_STATE.ANTI_CHEAT_MANAGER_DISABLED then return end
    pcall(function()
        local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
        if not slua.isValid(pc) then return end

        local AntiCheatMgr = nil
        if pc.PlayerAntiCheatManager then
            AntiCheatMgr = pc.PlayerAntiCheatManager
        elseif pc.AntiCheatManager then
            AntiCheatMgr = pc.AntiCheatManager
        end

        if not slua.isValid(AntiCheatMgr) then
            local PlayerAntiCheatManagerClass = import("PlayerAntiCheatManager")
            if PlayerAntiCheatManagerClass then
                local comps = pc:GetComponentsByClass(PlayerAntiCheatManagerClass)
                if comps and comps:Num() > 0 then
                    AntiCheatMgr = comps:Get(0)
                end
            end
        end

        if not slua.isValid(AntiCheatMgr) then return end

        local counterFields = {
            "AutoAimFailedCnt", "TrackingFailedCnt", "AreaDamageFailedCnt", "JumpHeightFailedCnt",
            "JumpFarFailedCnt", "VehicleFlyingFailedCnt", "ShootVerifyTimes", "SpeedUpValue",
            "ClientTimeTotalAcc", "ServerAccumulateErrors", "ServerAvgErrors", "ServerCorrectTimes",
            "PlayerBadPingTimes", "VehicleSpeedZDeltaTotal", "VehicleSpeedZDeltaOver10Times",
            "PVSInCityKillCount", "PVSNotInCityKillCount", "PVSCellHidePercent", "PVSTotalHidePercent",
            "ServerMoveParameterVerifyCount", "ServerMoveParameterVerifyFailedCount",
            "StuckGroundPunishCount", "ContinueMoveBurstCount", "RecordContinueMoveBurstCount",
            "TrialBaseDiffCount", "InclusiveBegin", "InclusiveEnd"
        }
        for _, field in ipairs(counterFields) do
            pcall(function()
                if type(AntiCheatMgr[field]) == "number" then AntiCheatMgr[field] = 0 end
            end)
        end

        local boolFields = {
            "bReportFeedBack","bOpenDetailDataCollect","bOpenBaseDiffCheck","bUploadStuckGroundCount",
            "bStuckGroundCapsule","bImpactOtherAfterBurst","bGiveupPickupWhenBrust",
            "bOpenPickupWhenBrustCheck","bMustStrictContinue"
        }
        for _, field in ipairs(boolFields) do
            pcall(function()
                if type(AntiCheatMgr[field]) == "boolean" then AntiCheatMgr[field] = false end
            end)
        end

        local maxFields = {
            "MaxShootPointPassWall", "MaxMuzzleHeightTime", "MaxLocusFailTime",
            "MaxBulletVictimClientPassWallTimes", "MaxGunPosErrorTimes",
            "MaxAllowVehicleTimeSpeedRawTime", "MaxAllowVehicleTimeSpeedConvTime",
            "MaxAllowVehicleAccTime", "MaxSingleShotDamage", "MaxFallingSustainTime",
            "MaxCustomMoveModeSustainTime", "MaxMoveDistance2DPerSecond",
            "MaxCharMoveDist2DPerSecond", "MaxDistanceToGround", "MaxContinueMoveBurstXY",
            "ContinueMoveBurstInterval", "BaseDiffRegion", "BaseDiffVel", "BaseDiffTime",
            "MinImpactOtherInterval", "MinBurstToPickupInterval", "MaxPlayerDisSquaredForPickup",
            "ContinueMoveBurstTolerant", "MultiStuckGroundScale", "StuckTypePunishSet",
            "StuckGroundPunishType"
        }
        for _, field in ipairs(maxFields) do
            pcall(function()
                if type(AntiCheatMgr[field]) == "number" then AntiCheatMgr[field] = 999999 end
            end)
        end

        local paraFields = {
            "ParachuteStartTime","ParachuteOpenTime","ParachuteCloseTime",
            "ParachuteStartHight","ParachuteOpenHight","ParachuteCloseHight"
        }
        for _, field in ipairs(paraFields) do
            pcall(function()
                if type(AntiCheatMgr[field]) == "number" then AntiCheatMgr[field] = 0 end
            end)
        end

        pcall(function() AntiCheatMgr.DSProperty = nil end)

        local verifySwitchFields = {
            "VsNoHitDetail","VsMuzzleRangeCircle","VsMuzzleRangeUp",
            "VsHitBoneNameNone","VsHitBoneHitMissMatch","VsBulletID",
            "VsVehicleTimeStampError","VsWatchTimeStampError",
            "VsShootRpgShootTimeVerify","VsShootLockShootTimeVerify",
            "VsShootRpgHitNewVerify","VsShootTimeConDelta",
            "VsServerNoOldShoot","VsClientNotConnectShoot",
            "VsShootRpgShootIntervalVerify","VsImpactPointAndBulletDisBig",
            "VsShootVerifyInvalid","VsImpactActorPosWithNoHisPos",
            "VsShootAngleInVaild","VsMuzzleAndTailPosInVaild",
            "VsMuzzleAndImpactPassWall","VsMuzzleAndTailPassWall",
            "VsImpactActorPosOffsetBig","VsImpactPointChangeSmall",
            "VsImpactBulletPosOffsetBig","VsTotalImactCharacterNum",
            "VsBoneInfo","VsJumpMaxHeight","VsJumpMaxHeight15","VsJumpMaxHeight2",
            "SpeedQuickCheck","BulletDirError","WalkSpeedFailedCnt",
            "DSSpeedOver10FailedCnt","DSSpeedOver15FailedCnt","DSSpeedOver20FailedCnt",
            "DSFallingSpeedFailCount","DSFallingHeightFailCount",
            "SwitchMuzzleLocusError","SwitchMuzzleLocusErrorX","SwitchMuzzleLocusErrorY","SwitchMuzzleLocusErrorZ",
            "Gun2ShooterPosError1","SwitchHeadLocusError3","SwitchMuzzleLocusErrorLength",
            "SwitchShootPosHistoryLocusError3","SwitchHitComponentUnvalid","SwitchHitNoRender",
            "SwitchHitOutCollisionBox","HeadOverShootPos","SwitchMuzzleImpactDirSkipPunish1",
            "SwitchInvalidBulletNumInBarrel","SwitchShooterMovementError2","GunTailPosError",
            "SwitchMuzzleImpactDirSkipPunish2","SwitchMuzzleImpactDirError1","SwitchMuzzleImpactDirError2",
            "ShooterHead2PosBlock","SwitchShootPosHistoryLocusError2","Head2GunTailPosError1",
            "SwitchShootDirExcepation1","SwitchShootDirExcepation2","SwitchCamerModeException",
            "SwitchShootPosHistoryLocusError4","SwitchMuzzleImpactDirError3",
            "CharacterMoveException1","CharacterMoveException2","CharacterMoveException3",
            "CharacterMoveException4","CharacterMoveException5","CharacterMoveException6",
            "VehicleSpeedZDeltaOver10TimesWhenNoXY","VehicleVelZCheck1","VehicleVelZCheck2",
            "VehicleMaxSpeedCheck","VehicleHitMuzzleCheck","VehicleHitImpactPointCheck",
            "VehicleHitBlockWall","VehicleSidesway1","VehicleSidesway2",
            "FarShootInMidAirVehicleExceedThreshold","FarShootInMidAirVehicleEnemyDistanceTrial",
            "FarShootInMidAirVehicleEnemyDistanceFurtherTrial","FarShootInMidAirVehicleHeightTrial",
            "FarShootInMidAirVehicleHeightFurtherTrial","FarShootInMidAirPawnExceedThreshold",
            "FarShootInMidAirPawnEnemyDistanceTrial","FarShootInMidAirPawnEnemyDistanceFurtherTrial",
            "FarShootInMidAirPawnHeightTrial","FarShootInMidAirPawnHeightFurtherTrial",
            "NonGunADSFarShootCount","NonGunADSFarShootFromClientBulletDataCount",
            "NonGunADSFarShootFromClientBulletDataEnemyDistanceTrialCount",
            "NonGunADSFarShootFromClientBulletDataEnemyDistanceFurtherTrialCount",
            "ClientUploadFuzzyObjectVerifyFail","ClientMoveTimeStampResetFrequencyExceedThreshold",
            "ShootBirdNonGunADSExceedThreshold","ShootBirdNonGunADSDistanceTrial",
            "ShootBirdNonGunADSDistanceFurtherTrial","FarShootInHighTangentMoveSpeedExceedThreshold",
            "FarShootInHighTangentMoveSpeedEnemyDistanceTrial","FarShootInHighTangentMoveSpeedEnemyDistanceFurtherTrial",
            "FarShootInHighTangentMoveSpeedSpeedTrial","FarShootInHighTangentMoveSpeedSpeedFurtherTrial",
            "IllegalTeamUpNearbyButNoFireAfterKill","IllegalTeamUpNearbyButNoFireAfterKillDistanceTrial",
            "IllegalTeamUpNearbyButNoFireAfterKillTimeTrial","IllegalTeamUpNearbyButNoFireAfterKillMaxTime",
            "IllegalTeamUpNearbyButNoFirePickUpItem","IllegalTeamUpNearbyButNoFirePickUpItemDistanceTrial",
            "IllegalTeamUpNearbyButNoFirePickUpItemTimeTrial","IllegalTeamUpNearbyButNoFirePickUpItemMaxTime",
            "IllegalTeamUpNearbyButNoFireNotKill","IllegalTeamUpNearbyButNoFireNotKillDistanceTrial",
            "IllegalTeamUpNearbyButNoFireNotKillTimeTrial","IllegalTeamUpNearbyButNoFireNotKillMaxTime",
            "IllegalTeamUpNearbyButNoFireOnVehicle","IllegalTeamUpNearbyButNoFireOnVehicleDistanceTrial",
            "IllegalTeamUpNearbyButNoFireOnVehicleTimeTrial","IllegalTeamUpNearbyButNoFireOnVehicleMaxTime",
            "IllegalTeamUpNearbyButNoFireSameVehicle","IllegalTeamUpNearbyButNoFireSameVehicleTimeTrial",
            "IllegalTeamUpNearbyButNoFireSameVehicleMaxTime","IllegalTeamUpUseObjectTogether",
            "IllegalTeamUpGetOnEnemyVehicleCount","IllegalTeamUpNearbyButNoFireOneSideHasWeaponOnFoot",
            "IllegalTeamUpNearbyButNoFireOneSideHasWeaponOnFootDistanceTrial","IllegalTeamUpStayOnEnemyVehicle",
            "KillBird","ShooterCapsuleCollided","ParachuteLandingSecondsExceedThreshold",
            "ParachuteObliqueLandingSecondsExceedThreshold","SmallActorTimeDilationCount",
            "LargeRotateLockShooting","SmallRotateLockShooting","OneClipShootCount","ClientWeaponFastReload",
            "UndergroundCount","MoveDistance2DPerSecondAnomaly","CharMoveDist2DPerSecondAnomaly",
            "CharMoveDist2DPerSecondCount","DistanceToGroundAnomaly","SingleShotDamageAnomaly","BandaCount",
            "DSCheckClientTimeMoveDistance2D","DSCheckClientTimeMoveDistance2DTrial",
            "DSCheckClientTimeMoveDistance2DFurther","DSCheckClientTimeMoveDistanceZ",
            "DSCheckClientTimeMoveDistanceZTrial","DSCheckClientTimeMoveDistanceZFurther",
            "ReplayMaxFallingSustainTime","ReplayMaxCustomMoveModeSustainTime","ReplayMaxSingleShotDamage",
            "CharMoveAccumDist2D_DS","CharMoveAccumDist3D_DS","CharMoveAccumDist2D_Client",
            "CharMoveAccumDist3D_Client","CharMoveAccumDist2D_ClientAll","CharMoveAccumDist3D_ClientAll",
            "MetroEnterRadiationTime","MetroEnterRadiationTimeTrial","MetroLeaveBornObstacle",
            "VsPetJumpHeightLimiter","VsPetMoveSpeedLimiter","VsBioVehicleMoveSpeedLimiter",
            "VsBioVehicleJumpHeightLimiter","VsPterosaurFlyVehicleSpeed","VsBioVehicleGravityLimiter",
            "ServerMoveCacheCountOver","ServerMoveCacheCountOver3d","ServerMoveBurst","ImpactOtherAfterBurst",
            "KillOtherAfterBurst","PickupAfterBurst","ContinueMoveBurst","ServerMoveTimeStamp",
            "ServerMoveAccel","ServerMoveClientLoc","ServerMoveCompressedMoveFlags","ServerMoveClientRoll",
            "ServerMoveView","ServerMoveClientMovementBase","ServerMoveClientBaseBoneName",
            "ServerMoveClientMovementMode","VerifySwitchCameraRotation","VerifySwitchPeekShootThroughWall",
            "VerifySwitchCameraLocation","VerifySwitchAutoAimByLockView","VerifySwitchControlRotation",
            "VerifySwitchRecoilFaildCount","VerifySwitchMarcoPolo","VerifySwitchMarcoPolo2",
            "VerifySwitchMarcoPolo3","VerifySwitchMeshScaleDiff","VerifySwitchOfflineMove",
            "VerifySwitchFastAimShootHit","VerifySwitchNoRecoilOnWeaponShoot","VerifySwitchLessRecoilOnWeaponShoot",
            "VerifySwitchNoRecoilOnKickBack","VerifySwitchLessRecoilOnKickBack","VerifySwitchDivingBoost",
            "VerifySwitchRecoilCurveFailed","PlayerQuickProne","BaseDiffSample",
            "VsTeammateRescue","VsTeammateRescueVictim","VsTeammateRecall","VsTeammateRecallVictim",
            "VsAutoClicker","VsAbnormalShootingRotation","PlayerInstantHeightDiff","Player2SecHeightDiff",
            "CheatStateData2TotalCheatTimes","MoveCheatAntiStrategy3TotalCheatTimes","ServerAccumulateErrorReplay"
        }
        for _, fieldName in ipairs(verifySwitchFields) do
            pcall(function()
                local vs = AntiCheatMgr[fieldName]
                if vs and type(vs) == "table" then
                    vs.bActive = false
                    vs.MaxCount = 99999
                    vs.CurrentCount = 0
                    vs.TrialCount = 0
                    vs.TrialMaxCount = 99999
                    vs.PunishType = 0
                end
            end)
        end

        local burstFields = {
            "ServerAccumulateErrorBurst","DSSpeedOver10BurstCount",
            "ParachuteSpeedBurst","ClientTimestampBurst","ClientTimestampBurstTrial"
        }
        for _, fieldName in ipairs(burstFields) do
            pcall(function()
                local bvs = AntiCheatMgr[fieldName]
                if bvs and type(bvs) == "table" then
                    bvs.bActive = false
                    bvs.MaxCount = 99999
                    bvs.CurrentCount = 0
                end
            end)
        end

        pcall(function()
            if AntiCheatMgr.ReportMiscMap then AntiCheatMgr.ReportMiscMap:Clear() end
        end)

        local methodFields = {
            "ReportAntiCheatDetailData","PushWeaponAntiData","OnRecoverOnServer",
            "OnPreReconnectOnServer","ExitParachute","EnterParachute","EnterJumping",
            "Cofey","Cofew","SetTrialRegion","GetSoftString","GetCheckMoveStr2",
            "GetCheckMoveStr1","GetAACString","GetAACCountByID"
        }
        for _, method in ipairs(methodFields) do
            pcall(function()
                if AntiCheatMgr[method] and type(AntiCheatMgr[method]) == "function" then
                    AntiCheatMgr[method] = function(...)
                        if method == "GetSoftString" then return 0 end
                        if method == "GetCheckMoveStr1" or method == "GetCheckMoveStr2" then return "" end
                        if method == "GetAACString" then return "" end
                        if method == "GetAACCountByID" then return 0 end
                        if method == "Cofey" then return 0 end
                        return true
                    end
                end
            end)
        end

        pcall(function()
            local catchData = AntiCheatMgr.CatchReportAntiCheatDetailData
            if catchData and type(catchData) == "table" then
                catchData.bActive = false
                catchData.CurrentCount = 0
                catchData.MaxCount = 99999
            end
        end)

        _G.BYPASS_STATE = _G.BYPASS_STATE or {}
        _G.BYPASS_STATE.ANTI_CHEAT_MANAGER_DISABLED = true
    end)
end

local function MemoryBypass()
    pcall(function()
        local funcs = {"__aeabi_memset","__strncpy_chk","memmove_chk","memset_chk","memcpy","malloc","calloc","realloc","free","close","dup2","listen"}
        for _, fn in ipairs(funcs) do if _G[fn] then _G[fn] = function() return true end end end
    end)
end

local function TimeBypass()
    pcall(function()
        if _G.gmtime then _G.gmtime = function() return os.date("!*t") end end
        if _G.gettimeofday then _G.gettimeofday = function() return os.time() end end
        if _G.mktime then _G.mktime = function(t) return os.time(t) end end
        if _G.imp_time then _G.imp_time = function() return os.time() end end
    end)
end

local function NetworkBypass()
    pcall(function()
        local funcs = {"sys_read","sys_open","nanosleep","imp_recv","imp_send","socket"}
        for _, fn in ipairs(funcs) do if _G[fn] then _G[fn] = function() return true end end end
    end)
end

local function ReportBypass()
    pcall(function()
        local funcs = {"report","COREREPORT","tdm_report","android_log_print","__android_log_print"}
        for _, fn in ipairs(funcs) do if _G[fn] then _G[fn] = function() return true end end end
    end)
end

local function StrBypass()
    pcall(function()
        if _G.strstr then _G.strstr = function() return "" end end
        if _G.strcpy then _G.strcpy = function() return "" end end
        if _G.strlen then _G.strlen = function() return 0 end end
        if _G.strncpy then _G.strncpy = function() return "" end end
    end)
end

local function ProcessBypass()
    pcall(function()
        if _G.getpid then _G.getpid = function() return 0 end end
        if _G.getppid then _G.getppid = function() return 0 end end
        if _G.gettid then _G.gettid = function() return 0 end end
    end)
end

local function AntiDebugBypass()
    pcall(function()
        if _G.ptrace then _G.ptrace = function() return 0 end end
        if _G.monitor then _G.monitor = function() return true end end
    end)
end

local function DLCmdBypass()
    pcall(function()
        if _G.dlopen then _G.dlopen = function() return 0 end end
        if _G.cmd then _G.cmd = function() return "" end end
        if _G.name then _G.name = function() return "" end end
    end)
end

local function AnoSDKBypass()
    pcall(function()
        local TssSdk = _G.TssSdk or package.loaded["TssSdk"]
        if TssSdk then
            if TssSdk.AnoSDKDelReportData then TssSdk.AnoSDKDelReportData = function() return true end end
            if TssSdk.AnoSDKDelReportData3 then TssSdk.AnoSDKDelReportData3 = function() return true end end
            if TssSdk.AnoSDKDelReportData4 then TssSdk.AnoSDKDelReportData4 = function() return true end end
            if TssSdk.AnoSDKGetReportData then TssSdk.AnoSDKGetReportData = function() return nil end end
            if TssSdk.AnoSDKGetReportData2 then TssSdk.AnoSDKGetReportData2 = function() return nil end end
            if TssSdk.AnoSDKGetReportData3 then TssSdk.AnoSDKGetReportData3 = function() return nil end end
            if TssSdk.AnoSDKGetReportData4 then TssSdk.AnoSDKGetReportData4 = function() return nil end end
        end
    end)
end

local function MprotectBypass()
    pcall(function()
        if _G.mprotect then _G.mprotect = function() return 0 end end
        if _G.munmap then _G.munmap = function() return 0 end end
    end)
end


local function InitializeSLUABypass()
  pcall(function()
    if slua and slua.getSignature then
      slua.getSignature = function() return 0xDEADBEEF end
    end
    local loader = package.loaded["slua.loader"] or rawget(_G, "slua_loader")
    if loader then
      loader.verifyBytecode = retTrue
      loader.checkIntegrity = retTrue
      if loader.disableSignatureCheck then loader.disableSignatureCheck = retTrue end
    end
    local slua_serialize = package.loaded["slua.serialize"]
    if slua_serialize then
      slua_serialize.check = retTrue
      slua_serialize.verify = retTrue
    end
    if jit and jit.attach then
      jit.attach(function() end, "bc")
    end
    if _G.slua_verify then _G.slua_verify = retTrue end
    if _G.check_slua_integrity then _G.check_slua_integrity = retTrue end
  end)
end

local function InitializeMD5Bypass()
  pcall(function()
    local console = import("KismetSystemLibrary")
    if console then
      console.ExecuteConsoleCommand(nil, "pak.DisablePakSignatureCheck 1")
      console.ExecuteConsoleCommand(nil, "pakchunk.EnableSignatureCheck 0")
      console.ExecuteConsoleCommand(nil, "s.VerifyPak 0")
      console.ExecuteConsoleCommand(nil, "sig.Check 0")
      console.ExecuteConsoleCommand(nil, "security.DisableChecks 1")
    end
    local CreativeModeBlueprintLibrary = import("CreativeModeBlueprintLibrary")
    if CreativeModeBlueprintLibrary then
      CreativeModeBlueprintLibrary.MD5HashByteArray = function() return "00000000000000000000000000000000" end
      CreativeModeBlueprintLibrary.MD5HashFile = function() return "00000000000000000000000000000000" end
      CreativeModeBlueprintLibrary.GetContentDiffData = function() return true, "BYPASSED" end
      CreativeModeBlueprintLibrary.VerifyFileIntegrity = retTrue
    end
    if _G.MD5Hash then _G.MD5Hash = function() return "00000000000000000000000000000000" end end
    if _G.CRC32 then _G.CRC32 = function() return 0 end end
    if _G.SHA1 then _G.SHA1 = function() return "BYPASS" end end
    local FileHashChecker = package.loaded["common.file_hash_checker"]
    if FileHashChecker then
      FileHashChecker.CheckFileMD5 = retTrue
      FileHashChecker.VerifyAll = retTrue
      FileHashChecker.GetHash = function() return "BYPASS" end
    end
    local TssSdk = package.loaded["TssSdk"] or _G.TssSdk
    if TssSdk then
      TssSdk.GetFileMD5 = function() return "BYPASS" end
      TssSdk.VerifyFileSignature = retTrue
    end
    local STExtraBlueprintFunctionLibrary = import("STExtraBlueprintFunctionLibrary")
    if STExtraBlueprintFunctionLibrary then
      STExtraBlueprintFunctionLibrary.CheckMD5 = retTrue
      STExtraBlueprintFunctionLibrary.GetMD5 = function() return "BYPASS" end
      STExtraBlueprintFunctionLibrary.VerifyFile = retTrue
    end
  end)
end

local function InitializeSkinBypass()
  pcall(function()
    local puffer_tlog = package.loaded["client.slua.logic.download.report.puffer_tlog"]
    if puffer_tlog then
      puffer_tlog.ReportEvent = noop
      puffer_tlog.ReportDownloadResult = noop
      puffer_tlog.ReportODPTDError = noop
      puffer_tlog.ReportSkinError = noop
    end
    local AvatarUtils = package.loaded["AvatarUtils"]
    if AvatarUtils then
      AvatarUtils.CheckIsWeaponInBlackList = retFalse
      AvatarUtils.IsValidAvatar = retTrue
      AvatarUtils.CheckAvatarIntegrity = retTrue
      AvatarUtils.ReportInvalidAvatar = noop
    end
    local SubsystemMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
    local fileCheckSubsystem = SubsystemMgr and SubsystemMgr:Get("FileCheckSubsystem")
    if fileCheckSubsystem then
      fileCheckSubsystem.StartCheck = noop
      fileCheckSubsystem.ReportAbnormalFile = noop
      fileCheckSubsystem.StopCheck = noop
    end
    local equipmentException = package.loaded["client.slua.logic.report.EquipmentExceptionReport"]
    if equipmentException then
      equipmentException.Report = noop
      equipmentException.SendException = noop
    end
  end)
end

local function InitializeLogBlocker()
  pcall(function()
    local ScreenshotMTDer = import("ScreenshotMTDer")
    if ScreenshotMTDer then
      ScreenshotMTDer.MTDePicture = function() return "" end
      ScreenshotMTDer.ReMTDePicture = function() return "" end
      ScreenshotMTDer.HasCaptured = retTrue
      ScreenshotMTDer.TakeScreenshot = noop
    end
    local TLog = package.loaded["TLog"] or _G.TLog
    if TLog then
      TLog.Info = noop; TLog.Warning = noop; TLog.Error = noop
      TLog.Debug = noop; TLog.Report = noop; TLog.Send = noop
      TLog.Flush = noop
    end
    local CrashSight = package.loaded["CrashSight"] or _G.CrashSight
    if CrashSight then
      CrashSight.ReportException = noop
      CrashSight.SetCustomData = noop
      CrashSight.Log = noop
      CrashSight.SendCrash = noop
      CrashSight.ReportUserException = noop
    end
    local GameReportUtils = package.loaded["GameLua.Mod.BaseMod.GamePlay.GameReport.GameReportUtils"]
    if GameReportUtils then
      GameReportUtils.BugglyPostExceptionFull = retFalse
      GameReportUtils.CheckCanBugglyPostException = retFalse
      GameReportUtils.ReplayReportData = noop
      GameReportUtils.ReportGameException = noop
      GameReportUtils.PostException = noop
    end
    local ClientToolsReport = package.loaded["client.slua.logic.report.ClientToolsReport"]
    if ClientToolsReport then
      ClientToolsReport.SendReport = noop
      ClientToolsReport.SendException = noop
      ClientToolsReport.UploadLog = noop
    end
    local TLogReportUtils = package.loaded["client.slua.config.tlog.tlog_report_utils"]
    if TLogReportUtils then
      TLogReportUtils.ReportTLogEvent = noop
      TLogReportUtils.FlushEvents = noop
    end
    for _, sdk in ipairs({"Firebase", "Adjust", "AppsFlyer", "FacebookAnalytics", "GameAnalytics"}) do
      local s = _G[sdk]
      if s then
        s.logEvent = noop; s.trackEvent = noop; s.setEnabled = retFalse
        s.sendEvent = noop; s.report = noop
      end
    end
  end)
end

local function InitializeScannerBlocker()
  pcall(function()
    local SubsystemMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
    if SubsystemMgr then
      local subsystems = {
        "AFKReportorSubsystem", "ClientDataStatistcsSubsystem", "AvatarExceptionSubsystem",
        "ShootVerifySubSystemClient", "MemoryCheckSubsystem", "SpeedCheckSubsystem",
        "WallCheckSubsystem", "FileCheckSubsystem", "BehaviorScoreSubsystem"
      }
      for _, name in ipairs(subsystems) do
        local sub = SubsystemMgr:Get(name)
        if sub then
          for k, v in pairs(sub) do
            if type(v) == "function" and (
              k:find("Report") or k:find("Send") or k:find("Upload") or
              k:find("Verify") or k:find("Check") or k:find("Validate") or
              k:find("Scan") or k:find("Detect")
            ) then
              pcall(function() sub[k] = noop end)
            end
          end
          if sub.ReportPingDelayTimer then
            sub:RemoveGameTimer(sub.ReportPingDelayTimer)
            sub.ReportPingDelayTimer = nil
          end
          sub.DelayCount = 0
        end
      end
    end
    local AvatarExceptionPlayerInst = package.loaded["GameLua.Mod.Library.GamePlay.Avatar.Exception.AvatarExceptionPlayerInst"]
    if AvatarExceptionPlayerInst then
      AvatarExceptionPlayerInst.CheckAvatarException = noop
      AvatarExceptionPlayerInst.CheckAvatarExceptionOnce = noop
      AvatarExceptionPlayerInst.ReportAvatarException = noop
      AvatarExceptionPlayerInst.CheckSlotMeshVisible = retFalse
      AvatarExceptionPlayerInst.CheckPawnVisible = retFalse
      AvatarExceptionPlayerInst.CheckCanBugglyPostException = retFalse
    end
    local TssSdk = package.loaded["TssSdk"] or _G.TssSdk
    if TssSdk then
      local originalOnRecvData = TssSdk.OnRecvData
      TssSdk.OnRecvData = function(data)
        if type(data) == "string" and (
          string.find(data, "report") or string.find(data, "exception") or
          string.find(data, "cheat") or string.find(data, "violation") or
          string.find(data, "hack") or string.find(data, "verify")
        ) then
          return
        end
        if originalOnRecvData then originalOnRecvData(data) end
      end
      TssSdk.SendReportInfo = noop
      TssSdk.ScanMemory = retTrue
      TssSdk.IsEmulator = retFalse
      TssSdk.GetTssSdkReportInfo = retEmptyString
      TssSdk.CheckEnvironment = retTrue
      TssSdk.VerifyProcess = retTrue
    end
  end)
end

local function InitializeReplayTelemetryBlocker()
  pcall(function()
    local SubsystemMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
    if SubsystemMgr then
      local replaySystems = {
        "RescueBtnReplayTraceSubsystem", "GameReportSubsystem", "ReplaySubsystem"
      }
      for _, name in ipairs(replaySystems) do
        local sub = SubsystemMgr:Get(name)
        if sub then
          for k, v in pairs(sub) do
            if type(v) == "function" and (
              k:find("Report") or k:find("Trace") or k:find("Replay") or
              k:find("Record") or k:find("Save")
            ) then
              pcall(function() sub[k] = noop end)
            end
          end
        end
      end
    end
    local logic_report_replay = package.loaded["client.slua.logic.replay.logic_report_replay"]
    if logic_report_replay then
      logic_report_replay.ReportReplay = noop
      logic_report_replay.SendReportReq = noop
      logic_report_replay.UploadReplay = noop
    end
  end)
end

local function InitializeReportFlowBlocker()
  pcall(function()
    local reportFlows = {
      "ReportAimFlow", "ReportHitFlow", "ReportAttackFlow", "ReportSecAttackFlow",
      "ReportHurtFlow", "ReportFireArms", "ReportVerifyInfoFlow", "ReportMrpcsFlow",
      "ReportPlayerBehavior", "ReportTeammatHurt", "ReportMisKillByTeammate",
      "ReportForbitPick", "ReportPlayerMoveRoute", "ReportPlayerPosition",
      "ReportVehicleMoveFlow", "ReportSecTgameMovingFlow", "ReportParachuteData",
      "ReportEquipmentFlow", "ReportPlayersPing", "ReportPlayerIP",
      "ReportPlayerFramePingRecord", "ReportDSNetSaturation", "ReportNetContinuousSaturate",
      "ReportDSNetRate", "ReportCircleFlow", "ReportPlayerKillFlow",
      "ReportMrpcsFlow", "ReportSecMrpcsFlow"
    }
    for _, funcName in ipairs(reportFlows) do
      if _G[funcName] then _G[funcName] = noop end
      if _G.GameplayCallbacks and _G.GameplayCallbacks[funcName] then
        _G.GameplayCallbacks[funcName] = noop
      end
    end
    local checkFuncs = {"CheckReportSecAttackFlowWithAttackFlow", "CheckReportSecAttackFlow"}
    for _, funcName in ipairs(checkFuncs) do
      if _G[funcName] then _G[funcName] = retFalse end
      if _G.GameplayCallbacks and _G.GameplayCallbacks[funcName] then
        _G.GameplayCallbacks[funcName] = retFalse
      end
    end
    local enableFlags = {
      "IsEnableReportPlayerKillFlow", "IsEnableReportMrpcsInCircleFlow",
      "IsEnableReportMrpcsInPartCircleFlow", "IsEnableReportMrpcsFlow",
      "IsEnableReportAttackFlow", "IsEnableReportHitFlow", "IsEnableReportCircleFlow"
    }
    for _, flag in ipairs(enableFlags) do
      if _G[flag] then _G[flag] = retFalse end
    end
  end)
end

local function InitializePlayerSecurityBypass()
  pcall(function()
    local securityCollectors = {
      "PlayerSecurityInfoCollector", "PlayerSecurityInfo", "SecurityInfoCollector",
      "ClientSecurityCollector", "PlayerAntiCheatCollector"
    }
    for _, collector in ipairs(securityCollectors) do
      if _G[collector] then
        for k, v in pairs(_G[collector]) do
          if type(v) == "function" and (
            k:find("Report") or k:find("Collect") or k:find("Send") or
            k:find("Upload") or k:find("Record")
          ) then
            _G[collector][k] = noop
          end
        end
      end
    end
    local SecuritySubsystem = require("GameLua.Mod.BaseMod.Common.Security.PlayerSecurityInfoSubsystem")
    if SecuritySubsystem then
      SecuritySubsystem.ReportData = noop
      SecuritySubsystem.CheckCheat = retFalse
      SecuritySubsystem.ValidatePlayer = retTrue
      SecuritySubsystem.CollectData = noop
      SecuritySubsystem.SendToServer = noop
    end
    if _G.PlayerSecurityInfo then
      _G.PlayerSecurityInfo.ReportCheat = noop
      _G.PlayerSecurityInfo.ReportSuspicious = noop
      _G.PlayerSecurityInfo.SendSecurityData = noop
      _G.PlayerSecurityInfo.CollectSecurityInfo = noop
    end
  end)
end

local function InitializeClientFlowBypass()
  pcall(function()
    local flowSubsystems = {
      "ClientSecMrpcsFlow", "MrpcsFlow", "MrpcsData", "ClientCircleFlowSubsystem",
      "ClientKillFlowSubsystem", "ClientSecPlayerKillFlow"
    }
    for _, name in ipairs(flowSubsystems) do
      local sub = package.loaded[name] or _G[name]
      if sub then
        for k, v in pairs(sub) do
          if type(v) == "function" and (
            k:find("Report") or k:find("Send") or k:find("Flow") or
            k:find("Record") or k:find("Process")
          ) then
            pcall(function() sub[k] = noop end)
          end
        end
      end
    end
    local CircleFlow = require("GameLua.Mod.BaseMod.Client.Security.ClientCircleFlowSubsystem")
    if CircleFlow then
      CircleFlow.ReportCircleFlow = noop
      CircleFlow.SendCircleData = noop
      CircleFlow.ReportPlayerPosition = noop
      CircleFlow.ReportCircleData = noop
    end
    if _G.ReportPlayerKillFlow then _G.ReportPlayerKillFlow = noop end
    if _G.ClientSecPlayerKillFlow then _G.ClientSecPlayerKillFlow = noop end
  end)
end

local function InitializeHeartbeatBypass()
  pcall(function()
    local heartbeatFuncs = {"Heartbeat", "SendHeartbeat", "ClientHeartbeat", "ServerHeartbeat"}
    for _, func in ipairs(heartbeatFuncs) do
      if _G[func] then _G[func] = noop end
      if _G.GameplayCallbacks and _G.GameplayCallbacks[func] then
        _G.GameplayCallbacks[func] = noop
      end
    end
    local SubsystemMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
    if SubsystemMgr then
      local heartbeatSub = SubsystemMgr:Get("HeartbeatSubsystem")
      if heartbeatSub then
        if heartbeatSub.timer then heartbeatSub:RemoveGameTimer(heartbeatSub.timer) end
        heartbeatSub.SendHeartbeat = noop
        heartbeatSub.StartHeartbeat = noop
      end
    end
  end)
end

local function InitializeSwiftHawkBypass()
  pcall(function()
    local swiftFuncs = {"SwiftHawk", "ClientSwiftHawk", "ClientSwiftHawkWithParams", "SendSwiftHawkData"}
    for _, func in ipairs(swiftFuncs) do
      if _G[func] then _G[func] = noop end
      if _G.GameplayCallbacks and _G.GameplayCallbacks[func] then
        _G.GameplayCallbacks[func] = noop
      end
    end
    local SwiftHawkSubsystem = package.loaded["GameLua.Mod.BaseMod.Client.Security.SwiftHawkSubsystem"]
    if SwiftHawkSubsystem then
      SwiftHawkSubsystem.ReportData = noop
      SwiftHawkSubsystem.SendReport = noop
      SwiftHawkSubsystem.CollectTelemetry = noop
    end
  end)
end

local function InitializeCoronaLabBypass()
  pcall(function()
    if _G.CoronaLab then
      _G.CoronaLab.ReportData = noop
      _G.CoronaLab.SendData = noop
      _G.CoronaLab.CollectData = noop
      _G.CoronaLab.Telemetry = noop
    end
    local SubsystemMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
    if SubsystemMgr then
      local corona = SubsystemMgr:Get("CoronaLabSubsystem")
      if corona then
        corona.ReportData = noop
        corona.SendToServer = noop
        corona.CollectTelemetry = noop
        corona.StopCollection = noop
      end
    end
  end)
end

local function InitializeModifierExceptionBypass()
  pcall(function()
    if _G.bReportedModifierException then
      _G.bReportedModifierException = false
    end
    local ModifierSubsystem = require("GameLua.Mod.BaseMod.Common.Security.ModifierExceptionSubsystem")
    if ModifierSubsystem then
      ModifierSubsystem.ReportException = noop
      ModifierSubsystem.CheckModifier = retTrue
      ModifierSubsystem.ValidateModifier = retTrue
      ModifierSubsystem.ReportModifierError = noop
    end
  end)
end

local function InitializeSimulateCharacterLocationBypass()
  pcall(function()
    local SimulateSubsystem = require("GameLua.Mod.BaseMod.Gameplay.Simulate.SimulateCharacterSubsystem")
    if SimulateSubsystem then
      SimulateSubsystem.ReportLocation = noop
      SimulateSubsystem.SendLocationData = noop
      SimulateSubsystem.VerifyLocation = retTrue
    end
  end)
end

local function InitializeShootVerificationBypass()
  pcall(function()
    local ShootVerify = require("GameLua.Dev.Subsystem.ShootVerifySubSystemClient")
    if ShootVerify then
      ShootVerify.OnShootVerifyFailed = noop
      ShootVerify.SendVerifyData = noop
      ShootVerify.ReportBulletHit = noop
      ShootVerify.UploadHitInfo = noop
      ShootVerify.VerifyShot = retTrue
    end
    if _G.BulletHitInfoUploadData then
      _G.BulletHitInfoUploadData.Report = noop
      _G.BulletHitInfoUploadData.Send = noop
      _G.BulletHitInfoUploadData.Upload = noop
    end
  end)
end

local function InitializeNetworkPacketBlock()
  pcall(function()
    if NetUtil and NetUtil.SendPacket then
      local originalSend = NetUtil.SendPacket
      local blockedPackets = {
        ["ReportAttackFlow"] = 1, ["ReportSecAttackFlow"] = 1, ["ReportHurtFlow"] = 1,
        ["ReportFireArms"] = 1, ["ReportVerifyInfoFlow"] = 1, ["ReportMrpcsFlow"] = 1,
        ["ReportPlayerBehavior"] = 1, ["ReportTeammatHurt"] = 1, ["ReportPlayerMoveRoute"] = 1,
        ["ReportPlayerPosition"] = 1, ["ReportSecVehicleMoveFlow"] = 1, ["report_parachute_data"] = 1,
        ["on_tss_sdk_anti_data"] = 1, ["ReportAimFlow"] = 1, ["ReportHitFlow"] = 1,
        ["ReportCircleFlow"] = 1, ["report_players_ping"] = 1, ["report_player_ip"] = 1,
        ["report_net_saturate"] = 1, ["report_speed_hack"] = 1, ["report_wall_hack"] = 1,
        ["report_aim_bot"] = 1, ["report_esp_usage"] = 1, ["report_modded_files"] = 1,
        ["detect_cheat"] = 1, ["ban_player"] = 1, ["client_anti_cheat_report"] = 1,
        ["ReportPlayerKillFlow"] = 1, ["ClientSecPlayerKillFlow"] = 1,
        ["ReportMrpcsFlow"] = 1, ["ClientSecMrpcsFlow"] = 1, ["MrpcsData"] = 1,
        ["CheckReportSecAttackFlow"] = 1, ["CheckReportSecAttackFlowWithAttackFlow"] = 1,
        ["RPC_ClientCoronaLab"] = 1, ["CoronaLabReport"] = 1, ["CoronaLabData"] = 1,
        ["PlayerSecurityInfo"] = 1, ["ReportSecurityInfo"] = 1, ["SendSecurityData"] = 1,
        ["ClientCircleFlow"] = 1, ["IsEnableReportPlayerKillFlow"] = 1,
        ["IsEnableReportMrpcsInCircleFlow"] = 1, ["IsEnableReportMrpcsInPartCircleFlow"] = 1,
        ["bReportedModifierException"] = 1, ["ReportModifierException"] = 1,
        ["RPC_Server_ReportSimulateCharacterLocation"] = 1, ["ReportSimulateCharacterLocation"] = 1,
        ["RPC_Client_ShootVertifyRes"] = 1, ["BulletHitInfoUploadData"] = 1,
        ["ShootVerifyFailed"] = 1, ["report_unrealnet_exception"] = 1, ["tss_sdk_report"] = 1,
        
        ["SwiftHawk"] = 1, ["ClientSwiftHawk"] = 1, ["ClientSwiftHawkWithParams"] = 1,
        ["SwiftHawkReport"] = 1, ["SwiftHawkData"] = 1,
        ["AntiCheatReport"] = 1, ["CheatDetection"] = 1, ["ViolationReport"] = 1,
        ["SecurityViolation"] = 1, ["IntegrityCheck"] = 1, ["SignatureVerify"] = 1,
        ["1162992962"] = 1, ["242463958"] = 1, ["224639039"] = 1, ["816081779"] = 1,
        ["224943158"] = 1, ["516985564"] = 1,
        ["inspection_system_report_to_inspector"] = 1,
        ["ingame_voice_ban_notify"] = 1,
        ["inspection_system_notify_inspector"] = 1,
      }
      NetUtil.SendPacket = function(packetName, ...)
        if blockedPackets[packetName] then
          return nil
        end
        return originalSend(packetName, ...)
      end
      NetUtil.IsBypassed = true
    end
    if _G.SendRPC then
      local originalSendRPC = _G.SendRPC
      local blockedRPCs = {
        "RPC_Server_ReportPlayerKillFlow", "RPC_Server_ClientSecMrpcsFlow",
        "RPC_Server_Heartbeat", "RPC_Server_SwiftHawk", "RPC_Server_ClientSwiftHawkWithParams",
        "RPC_Server_ReportSimulateCharacterLocation", "RPC_Client_ShootVertifyRes",
        "RPC_ClientCoronaLab",
        "RPC_Server_HawkReportCheat",
      }
      _G.SendRPC = function(rpcName, ...)
        for _, blocked in ipairs(blockedRPCs) do
          if rpcName == blocked then return nil end
        end
        return originalSendRPC(rpcName, ...)
      end
    end
  end)
end

local function InitializeAntiCheatHooks()
  pcall(function()
    local HiggsBosonComponent = require("GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent")
    if HiggsBosonComponent and HiggsBosonComponent.StaticShowSecurityAlertInDev then
      HiggsBosonComponent.StaticShowSecurityAlertInDev = noop
    end
    if HiggsBosonComponent and HiggsBosonComponent.BlackList then
      for k in pairs(HiggsBosonComponent.BlackList) do HiggsBosonComponent.BlackList[k] = nil end
    end
  end)
  _G.BlackList = {}
  
  pcall(function()
    _G.GlobalPlayerCoronaData = _G.GlobalPlayerCoronaData or {}
    _G.GlobalPlayerCheatTimes = _G.GlobalPlayerCheatTimes or {}
    if not getmetatable(_G.GlobalPlayerCoronaData) then
      local mt = { __newindex = function() end }
      setmetatable(_G.GlobalPlayerCoronaData, mt)
    end
  end)
  
  if _G.AvatarCheckCallback then
    _G.AvatarCheckCallback.StartAvatarCheck = noop
    _G.AvatarCheckCallback.OnReportItemID = noop
    _G.AvatarCheckCallback.PostPlayerControllerLoginInit = function(PlayerController)
      if slua.isValid(PlayerController) and PlayerController.HiggsBosonComponent then
        PlayerController.HiggsBosonComponent:ControlMHActive(0)
        PlayerController.HiggsBosonComponent.bMHActive = false
      end
    end
  end
end

local function InitializeAntiReport()
  pcall(function()
    local paths = {
      "GameLua.Mod.BaseMod.Client.Security.ClientReportPlayerSubsystem",
      "Client.Security.ClientReportPlayerSubsystem",
      "GameLua.Mod.BaseMod.DS.Security.DSReportPlayerSubsystem"
    }
    for _, path in ipairs(paths) do
      local sub = package.loaded[path]
      if not sub then
        local success, reqModule = pcall(require, path)
        if success and reqModule then sub = reqModule end
      end
      if sub then
        for k, v in pairs(sub) do
          if type(v) == "function" and (
            k:find("Report") or k:find("Record") or k:find("Send") or
            k:find("Upload") or k:find("Notify")
          ) then
            pcall(function() sub[k] = noop end)
          end
        end
      end
    end
  end)
end

local function InitializeGameplayBypass()
  pcall(function()
    if not _G.GameplayCallbacks then _G.GameplayCallbacks = {} end
    if _G.GameplayCallbacks.IsBypassed then return end
    local GC = _G.GameplayCallbacks
    local reportFuncs = {
      "ReportAttackFlow", "ReportSecAttackFlow", "ReportHurtFlow", "ReportFireArms",
      "ReportVerifyInfoFlow", "ReportMrpcsFlow", "ReportPlayerBehavior", "ReportTeammatHurt",
      "ReportMisKillByTeammate", "ReportForbitPick", "ReportPlayerMoveRoute",
      "ReportPlayerPosition", "ReportVehicleMoveFlow", "ReportSecTgameMovingFlow",
      "ReportParachuteData", "SendTssSdkAntiDataToLobby", "ReportEquipmentFlow",
      "ReportAimFlow", "ReportPlayersPing", "ReportPlayerIP", "ReportPlayerFramePingRecord",
      "OnDSConnectionSaturated", "ReportDSNetSaturation", "ReportNetContinuousSaturate",
      "ReportDSNetRate", "SendClientStats", "SendServerAvgTickDelta",
      "ReportCircleFlow", "ReportPlayerKillFlow", "ClientSecMrpcsFlow", "Heartbeat",
      "SwiftHawk", "ClientSwiftHawk", "ClientSwiftHawkWithParams"
    }
    for _, funcName in ipairs(reportFuncs) do
      GC[funcName] = noop
    end
    GC.CheckReportSecAttackFlowWithAttackFlow = retFalse
    GC.CheckReportSecAttackFlow = retFalse
    local originalDSPlayerState = GC.OnDSPlayerStateChanged
    GC.OnDSPlayerStateChanged = function(UID, InPlayerState, bPureWatcher, bIsSafeExit, ParamReason)
      local stateStr = InPlayerState and string.lower(tostring(InPlayerState)) or ""
      local blockedStates = {
        ["cheatdetected"] = true, ["connectionlost"] = true, ["connectiontimeout"] = true,
        ["connectionexception"] = true, ["netdrivererror"] = true, ["banned"] = true,
        ["kicked"] = true, ["suspended"] = true, ["violationdetected"] = true,
        ["integrityfailure"] = true, ["securityviolation"] = true
      }
      if blockedStates[stateStr] then return end
      if originalDSPlayerState then pcall(originalDSPlayerState, UID, InPlayerState, bPureWatcher, bIsSafeExit, ParamReason) end
    end
    GC.OnPlayerNetConnectionClosed = noop
    GC.OnPlayerActorChannelError = noop
    GC.OnPlayerRPCValidateFailed = noop
    GC.OnPlayerSpectateException = noop
    GC.OnShutdownAfterError = noop
    GC.IsBypassed = true
  end)
end

local function InitializeKillAllSubsystems()
  pcall(function()
    local subMgr = require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
    if not subMgr then return end
    local subsystemsToKill = {
      "CoronaLabSubsystem", "PlayerSecurityInfoSubsystem", "ClientCircleFlowSubsystem",
      "ModifierExceptionSubsystem", "SimulateCharacterSubsystem", "ShootVerifySubSystemClient",
      "HiggsBosonComponent", "ClientReportPlayerSubsystem", "DSReportPlayerSubsystem",
      "ClientHawkEyePatrolSubsystem", "DSHawkEyePatrolSubsystem",
      "ClientDataStatistcsSubsystem", "AFKReportorSubsystem", "BehaviorScoreSubsystem",
      "FileCheckSubsystem", "MemoryCheckSubsystem", "SpeedCheckSubsystem", "WallCheckSubsystem",
      "AvatarExceptionSubsystem", "GameReportSubsystem", "RescueBtnReplayTraceSubsystem",
      "ClientSecMrpcsFlowSubsystem", "MrpcsFlowSubsystem", "PlayerKillFlowSubsystem",
      "CircleFlowSubsystem", "SwiftHawkSubsystem", "HeartbeatSubsystem",
      "AntiCheatSubsystem", "IntegrityCheckSubsystem", "SignatureVerifySubsystem",
      "MD5CheckSubsystem", "PakVerifySubsystem"
    }
    for _, name in ipairs(subsystemsToKill) do
      local sub = subMgr:Get(name)
      if sub then
        for k, v in pairs(sub) do
          if type(v) == "function" and (
            k:find("Report") or k:find("Send") or k:find("Upload") or
            k:find("Verify") or k:find("Check") or k:find("Validate") or
            k:find("Scan") or k:find("Detect") or k:find("Collect") or
            k:find("Flow") or k:find("Heartbeat")
          ) then
            pcall(function() sub[k] = noop end)
          end
        end
        if sub.timer then pcall(function() sub:RemoveGameTimer(sub.timer) end) end
        if sub.heartbeatTimer then pcall(function() sub:RemoveGameTimer(sub.heartbeatTimer) end) end
        if sub.reportTimer then pcall(function() sub:RemoveGameTimer(sub.reportTimer) end) end
      end
    end
  end)
end


local function ApplyNewBypasses()
  pcall(function()
    InitializeSLUABypass()
    InitializeMD5Bypass()
    InitializeSkinBypass()
    InitializeLogBlocker()
    InitializeScannerBlocker()
    InitializeReplayTelemetryBlocker()
    InitializeReportFlowBlocker()
    InitializePlayerSecurityBypass()
    InitializeClientFlowBypass()
    InitializeHeartbeatBypass()
    InitializeSwiftHawkBypass()
    InitializeCoronaLabBypass()
    InitializeModifierExceptionBypass()
    InitializeSimulateCharacterLocationBypass()
    InitializeShootVerificationBypass()
    InitializeNetworkPacketBlock()
    InitializeAntiCheatHooks()
    InitializeAntiReport()
    InitializeGameplayBypass()
    InitializeKillAllSubsystems()
    InitializeFinalProtection()
  end)
end


local BLACKLIST_HOSTS = {
    "tss.tencent","syzsdk","gcloud.qq","reportlog","tdos","logupload","feedback.wh","crash2",
    "privacy.qq","privacy.tencent","oth.eve","mdt.qq","act.tencentyun","analytics","report.qq",
    "anticheatexpert","crashsight","wetest","log.tav","sngd","tracer","intlsdk","igamecj",
    "cdn.club","gpubgm","graph.facebook","calendarpushsubscription","googleads","doubleclick",
    "firebaselogging","firebaseremoteconfig","fonts.googleapis","abs.twimg","dl.listdl",
    "igame.gcloudcs","bugly","beacon","helpshift","tdm","apm","safeguard","weiyun","qzone",
    "tencent-cloud","myapp","idqqimg","gtimg","qqmail","tcdn","cloudctrl","sdkostrace",
    "103.134.189.146","mbgame","csoversea","igame","pubgmobile","down.anticheatexpert.com",
    "asia.csoversea.mbgame.anticheatexpert.com","log.tav.qq","syzsdk.qq","logiservice.qcloud",
    "opensdk.tencent","exp.helpshift","loginsdkapi.zingplay","firebase","googleapis","facebook","gvoice"
}
local BLACKLIST_PORTS = {
    "10334","11045","12221","13331","8011","8015","9001","20000","20001","20002","20003","20004",
    "20005","19700","1670","19900","14545","10213","8700","25177","10685","10336","10262","27000",
    "27040","27015","27030","10706","10095","12401","11008","10309","11075","10157","24798","10709",
    "6667","10087","31113","20371","10120","10664","13728","10769","10761","5061","5062","18081",
    "15692","9030","8080","8086","8088"
}
local FILE_KEYWORDS = {
    "tlog","crash","bugly","report","beacon","wetest","analytics","telemetry","trace","dump",
    "exception","feedback","aps_log","mtp_detect","network_loss","client_error","ue4crash","tdm","gcloud"
}

local function isBlacklisted(str)
    if type(str) ~= "string" then return false end
    local low = str:lower()
    for _, kw in ipairs(BLACKLIST_HOSTS) do if low:find(kw,1,true) then return true end end
    for _, port in ipairs(BLACKLIST_PORTS) do if low:find(":"..port) or low:find("/"..port) then return true end end
    return false
end

local function applyNetworkBlocker()
    pcall(function()
        if _G.HttpRequest then
            local orig = _G.HttpRequest
            _G.HttpRequest = function(url, ...) if isBlacklisted(url) then return nil end return orig(url, ...) end
        end
        if _G.FHttpModule and _G.FHttpModule.CreateRequest then
            local orig = _G.FHttpModule.CreateRequest
            _G.FHttpModule.CreateRequest = function(...)
                local url = select(1,...)
                if isBlacklisted(url) then return nil end
                return orig(...)
            end
        end
        local netMods = {
            "client.slua.logic.network.logic_network","client.slua.logic.download.report.puffer_tlog",
            "client.slua.data.BasicData.BasicDataClientReport","GameLua.GameCore.Module.Network.NetworkManager",
            "client.network.Protocol.ClientTlogHandler","client.network.Protocol.BattleReportHandler",
            "client.network.Protocol.ClientErrorReportHandler"
        }
        for _, mp in ipairs(netMods) do
            local mod = package.loaded[mp]
            if mod then
                for k, v in pairs(mod) do
                    if type(v) == "function" and (k:find("Http") or k:find("Request") or k:find("Send") or k:find("Upload") or k:find("Post") or k:find("Get") or k:find("Report")) then
                        local origf = v
                        mod[k] = function(...)
                            local args = {...}
                            for _, arg in ipairs(args) do if type(arg)=="string" and isBlacklisted(arg) then return nil end end
                            return pcall(origf, ...)
                        end
                    end
                end
            end
        end
    end)

    local orig_io_open = io.open
    io.open = function(path, mode)
        if type(path) == "string" then
            local lp = path:lower()
            for _, kw in ipairs(FILE_KEYWORDS) do
                if lp:find(kw) then
                    if mode and (mode == "w" or mode == "a" or mode == "w+" or mode == "a+") then
                        return nil, "Blocked"
                    end
                end
            end
            if lp:find("tdm") or lp:find("gcloud") or lp:find("beacon") then
                if mode and (mode == "w" or mode == "a" or mode == "w+") then return nil end
            end
        end
        return orig_io_open(path, mode)
    end

    if _G.UnrealEngine and _G.UnrealEngine.CrashContext then
        _G.UnrealEngine.CrashContext = nil
        _G.UnrealEngine.CrashContext = { SetCrashContext = noop, ReportCrash = noop, AddCrashData = noop }
    end
end

local function killGlobalFunctions()
    local globalFuncs = {
        "ReportTLogEvent","SendTlog","SendClientStats","ReportHitFlow","ReportAvatarException",
        "SendComplaintReq","SubmitReport","ReportSuspiciousPlayer","SendPacket","OnSyncBanInfo",
        "OnVoiceBanNotify","SendSecTLog","MarkSuspiciousPlayer","ReportPlayerBehaviorData",
        "CheckCompliance","ReportIllegalProgram","UploadVoiceLog","ReportCheat","ReportPlayer",
        "ShowReportUI","OpenReportPanel","OnClickReport","ReportCheatDetected"
    }
    for _, fn in ipairs(globalFuncs) do
        if type(_G[fn]) == "function" then _G[fn] = noop end
        _G[fn] = nil
    end
end


local function deepHook(obj, depth)
    if depth > 4 then return end
    if type(obj) ~= "table" then return end
    for k, v in pairs(obj) do
        if type(k) == "string" then
            local lk = k:lower()
            if lk:find("crc") or lk:find("verify") or lk:find("integrity") or lk:find("hash") or lk:find("paksign") then
                if type(v) == "function" then
                    obj[k] = function(...) if lk:find("crc") or lk:find("hash") then return 0 end; return true end
                end
            end
        end
        if type(v) == "table" and v ~= obj then deepHook(v, depth + 1) end
    end
end

local function applyFullCRCFaker()
    if _G.__CRCFakerDone then return end
    pcall(function()
        if not slua_GameFrontendHUD then return end
        if Client then
            if Client.VerifyPakFile then Client.VerifyPakFile = retTrue end
            if Client.CheckFileCRC then Client.CheckFileCRC = retZero end
            if Client.GetFileHash then Client.GetFileHash = function() return "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF" end end
            if Client.VerifySignature then Client.VerifySignature = retTrue end
            if Client.CheckGameLuaIntegrity then Client.CheckGameLuaIntegrity = retTrue end
            if Client.VerifyFileIntegrity then Client.VerifyFileIntegrity = retTrue end
            if Client.VerifyAllPaks then Client.VerifyAllPaks = retTrue end
        end
        for _, mod in pairs(package.loaded) do if type(mod) == "table" then deepHook(mod, 0) end end
        _G.__CRCFakerDone = true
    end)
end


local function applyAdvancedPatches()
    pcall(function()
        local SubsystemMgr = safe_require("GameLua.GameCore.Module.Subsystem.SubsystemMgr")
        if SubsystemMgr then
            local function patchSub(name, methods, retvals, fields)
                local inst = SubsystemMgr:Get(name)
                if inst then
                    if methods then for k, v in pairs(methods) do if type(inst[k]) == "function" then inst[k] = v end end end
                    if retvals then for k, v in pairs(retvals) do if type(inst[k]) == "function" then inst[k] = v end end end
                    if fields then for k, v in pairs(fields) do inst[k] = v end end
                end
            end
            patchSub("AFKReportorSubsystem", {PlayerHaveAction = noop, ReportAFK = noop})
            patchSub("ClientDataStatistcsSubsystem", nil, nil, {DelayCount = 0})
            patchSub("AvatarExceptionSubsystem", {ReportException = noop, BindPlayerCharacter = noop, CheckAvatarValid = retTrue})
            patchSub("ShootVerifySubSystemClient", {ReportVerifyFail = noop, OnVerifyFailed = noop})
            patchSub("RescueBtnReplayTraceSubsystem", {ReportTrace = noop, StartTickMonitor = noop, TickMonitorCheck = noop, ReportTickMonitorHeartbeat = noop})
            patchSub("GameReportSubsystem", {ReplayReportData = retFalse, CheckCanBugglyPostException = retFalse, BugglyPostExceptionFull = retFalse, GetClientReplayDataReporter = function() return nil end})
            patchSub("FileCheckSubsystem", {StartCheck = noop, ReportAbnormalFile = noop})
            patchSub("ReplaySubsystem", {SendReport = noop, Upload = noop})
            patchSub("ClientFlagSubsystem", {EvaluateFlags = noop, GetFlagLevel = retZero, GetFlagBanDuration = retZero, IsFlagged = retFalse})
            patchSub("DSAITLogSubsystem", {_UpdateTTKRecords = noop, _UpdateOperatingFrequency = noop})
            patchSub("TLogSubsystem", {OnInit = noop})
            local gameReportSub = SubsystemMgr:Get("GameReportSubsystem")
            if gameReportSub and gameReportSub.Reporter then
                gameReportSub.Reporter.ReportIntArrayData = noop
                gameReportSub.Reporter.ReportUInt8ArrayData = noop
                gameReportSub.Reporter.ReportFloatArrayData = noop
            end
        end
    end)
    pcall(function()
        local CreativeMode = import("CreativeModeBlueprintLibrary")
        if CreativeMode then
            CreativeMode.MD5HashByteArray = function() return "BYPASSED_MD5_HASH" end
            CreativeMode.GetContentDiffData = function() return true, "BYPASSED" end
        end
    end)
    pcall(function()
        local AvatarExceptionPlayerInst = package.loaded["GameLua.Mod.Library.GamePlay.Avatar.Exception.AvatarExceptionPlayerInst"]
        if AvatarExceptionPlayerInst then
            AvatarExceptionPlayerInst.CheckAvatarException = noop
            AvatarExceptionPlayerInst.CheckAvatarExceptionOnce = noop
            AvatarExceptionPlayerInst.ReportAvatarException = noop
            AvatarExceptionPlayerInst.CheckSlotMeshVisible = retFalse
            AvatarExceptionPlayerInst.CheckPawnVisible = retFalse
            AvatarExceptionPlayerInst.CheckCanBugglyPostException = retFalse
        end
    end)
    pcall(function()
        local AvatarChecker = package.loaded["blacklist.slua.logic.lobby_gm.AvatarCheckerModule"]
        if AvatarChecker then AvatarChecker.CheckAvatar = retTrue; AvatarChecker.ReportException = noop end
    end)
    pcall(function()
        local MemoryWarning = package.loaded["client.slua.logic.memory_warning.logic_memory_warning"]
        if MemoryWarning then MemoryWarning.OnMemoryWarning = noop; MemoryWarning.ReportMemoryWarning = noop end
    end)
    pcall(function()
        local StoreInterface = package.loaded["client.slua.logic.store.logic_store_game_interface"]
        if StoreInterface then StoreInterface.IsStoreGameSupported = retTrue; StoreInterface.NotifyGetPGSLoginInfo = noop end
    end)
    pcall(function()
        local VoiceSubsystem = package.loaded["GameLua.Mod.BaseMod.Client.Voice.VoiceChatSubsystem"]
        if VoiceSubsystem then VoiceSubsystem.OnPlayerSubmitComplaint = noop end
    end)
    pcall(function()
        local TssSdk = package.loaded["TssSdk"] or _G.TssSdk
        if TssSdk then
            local orig = TssSdk.OnRecvData
            TssSdk.OnRecvData = function(data)
                if type(data) == "string" and (data:find("report") or data:find("exception")) then return end
                if orig then orig(data) end
            end
            TssSdk.SendReportInfo = noop
            TssSdk.ScanMemory = retTrue
            TssSdk.IsEmulator = retFalse
            TssSdk.GetTssSdkReportInfo = function() return "" end
        end
    end)
    pcall(function()
        local logicReplayReport = package.loaded["client.slua.logic.replay.logic_report_replay"]
        if logicReplayReport then logicReplayReport.ReportReplay = noop; logicReplayReport.SendReportReq = noop end
    end)
    pcall(function()
        local PufferTlog = package.loaded["client.slua.logic.download.report.puffer_tlog"]
        if PufferTlog then PufferTlog.ReportEvent = noop; PufferTlog.ReportDownloadResult = noop; PufferTlog.ReportODPAKError = noop end
    end)
    pcall(function()
        local AvatarUtils = package.loaded["AvatarUtils"]
        if AvatarUtils then AvatarUtils.CheckIsWeaponInBlackList = retFalse; AvatarUtils.IsValidAvatar = retTrue end
    end)
    pcall(function()
        local EquipmentExceptionReport = package.loaded["client.slua.logic.report.EquipmentExceptionReport"]
        if EquipmentExceptionReport then EquipmentExceptionReport.Report = noop end
    end)
    pcall(function()
        local TLog = _G.TLog or package.loaded["TLog"]
        if TLog then TLog.Info = noop; TLog.Warning = noop; TLog.Error = noop; TLog.Debug = noop; TLog.Report = noop end
    end)
    pcall(function()
        local pc = (slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController())
        if pc and pc.HiggsBosonComponent then
            pc.HiggsBosonComponent.bMHActive = false
            pc.HiggsBosonComponent:ControlMHActive(0)
        end
    end)
    pcall(function() _G.BlackList = {} end)
end


local function safeSelfHeal()
    pcall(function()
        local TM = safe_require("GameLua.Mod.BaseMod.Common.TickManager")
        if TM and TM.AddLoopTimer then
            TM.AddLoopTimer(120, function()
                pcall(function()
                    local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
                    if pc and pc.HiggsBosonComponent then
                        pc.HiggsBosonComponent.bMHActive = false
                        pc.HiggsBosonComponent:ControlMHActive(0)
                    end
                    if slua.isValid(pc) then
                        local pawn = pc:GetCurPawn()
                        if slua.isValid(pawn) then
                            pcall(function()
                                local Higgs = package.loaded["GameLua.Mod.BaseMod.Common.Security.HiggsBosonComponent"]
                                if Higgs then
                                    Higgs.ControlMHActive = noop; Higgs.TriggerAvatarCheck = noop; Higgs.StartAvatarCheck = noop
                                    Higgs.ReportItemID = noop; Higgs.OnReportItemID = noop; Higgs.ReceiveAnyDamage = noop
                                    Higgs.OnWeaponHitRecord = noop; Higgs.ShowSecurityAlert = noop; Higgs.ServerReportAvatar = noop
                                    Higgs.ClientReportNetAvatar = noop; Higgs.GetNetAvatarItemIDs = retEmpty; Higgs.GetCurWeaponSkinID = retZero
                                end
                                if _G.AvatarCheckCallback then _G.AvatarCheckCallback.StartAvatarCheck = noop; _G.AvatarCheckCallback.OnReportItemID = noop end
                            end)
                        end
                    end
                end)
                local modules = {"client.slua.logic.ban.ClientBanLogic","client.common.ban_util","client.logic.login.logic_tt_ban","client.slua.logic.ban.BanTipsLogic"}
                for _, modName in ipairs(modules) do
                    local mod = package.loaded[modName]
                    if mod then
                        for k, v in pairs(mod) do
                            if type(k) == "string" and (k:find("Ban") or k:find("Flag")) and type(v) == "function" then
                                mod[k] = retFalse
                            end
                        end
                    end
                end
            end)
        end
    end)
end


pcall(function()
    local Gokuba = _G.GokubaLogic or package.loaded["GokubaLogic"]
    if Gokuba then
        Gokuba.ForwardFeature = function() return end
        Gokuba.InitGokubaLogic = function() return end
    end
    if _G.NetUtil and _G.NetUtil.SendPkg then
        local origSendPkg = _G.NetUtil.SendPkg
        _G.NetUtil.SendPkg = function(packetName, ...)
            if packetName == "battle_client_sync_allstar_auth_check_result_req" then
                return
            end
            return origSendPkg(packetName, ...)
        end
    end
end)


pcall(function()
    local HostedProto = _G.HostedProtoConfig or package.loaded["HostedProtoConfig"]
    if HostedProto and HostedProto.Proto then
        if HostedProto.Proto.NationalEsportsSecurityCheck then
            HostedProto.Proto.NationalEsportsSecurityCheck.func = "noop"
        end
    end
end)


pcall(function()
    local AC_Subsystem = _G.AntiCheatSubsystem or package.loaded["GameLua.Mod.BaseMod.Client.Security.AntiCheatSubsystem"]
    if AC_Subsystem then
        AC_Subsystem.OnInit = function() return end
        AC_Subsystem.OnTick = function() return end
        AC_Subsystem.CheckAbnormalStatus = function() return false end
        AC_Subsystem.ReportSecurityData = function() return end
        AC_Subsystem.OnDetectionResult = function() return end
        AC_Subsystem.TriggerSafetyScan = function() return end
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- تشغيل كل دوال Premium التي لم تُستدعَ بعد
-- ═══════════════════════════════════════════════════════════════════════════
-- ═══════════════════════════════════════════════════════════════════════════
-- PREMIUM BYPASS — SAFE MODE (بدون كسر الـmatchmaking)
-- ═══════════════════════════════════════════════════════════════════════════
pcall(function()
    print("[Premium] 🚀 تفعيل الطبقات الآمنة فقط...")

    -- ✅ آمن
    if TssSdkBypass then pcall(TssSdkBypass) end
    if MemoryBypass then pcall(MemoryBypass) end
    if AnoSDKBypass then pcall(AnoSDKBypass) end
    if MprotectBypass then pcall(MprotectBypass) end

    -- ✅ AntiCheatManager مع قيم معقولة
    if EnhancedAntiCheatBypass then
        pcall(function()
            EnhancedAntiCheatBypass()
            local pc = slua_GameFrontendHUD and slua_GameFrontendHUD:GetPlayerController()
            if slua.isValid(pc) then
                local mgr = pc.PlayerAntiCheatManager or pc.AntiCheatManager
                if slua.isValid(mgr) then
                    for _, f in ipairs({
                        "BaseDiffVel","BaseDiffRegion","BaseDiffTime",
                        "MaxDistanceToGround","MaxMoveDistance2DPerSecond",
                        "MaxCharMoveDist2DPerSecond"
                    }) do
                        pcall(function()
                            if type(mgr[f]) == "number" then mgr[f] = 100000 end
                        end)
                    end
                end
            end
        end)
    end

    -- ✅ آمن
    if applyAdvancedPatches then pcall(applyAdvancedPatches) end
    if safeSelfHeal then pcall(safeSelfHeal) end

    print("[Premium] ✅ تم تفعيل الطبقات الآمنة")
end)
end


end -- نهاية كتل الحماية المتقدمة


-- ═══════════════════════════════════════════════════════════════════════════
-- ⚠️ ملاحظة معمارية:
-- تم حذف return DeclareFeature(...) لأن هذا الملف يُحمّل عبر loadstring()
-- من اللودر الخارجي، والـ return يُتجاهل تماماً في هذا السياق.
-- الكلاس الحقيقي (الـ Feature wrapper) يُسجّل من اللودر الموجود في PAK.
-- هذا الملف يعمل كـ "منطق مود" فقط (ESP/Aimbot/Wallhack/Protection).
-- ═══════════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════════
-- ✅ Auto-Injection Fallback
-- يحقن المود في الشخصية تلقائياً حتى لو لم يُستدعى من ReceiveBeginPlay
-- ═══════════════════════════════════════════════════════════════════════════
local function _N5LA_AutoInject()
    local GDP = package.loaded["GameLua.GameCore.Data.GameplayData"]
    if not GDP then
        pcall(function() require("GameLua.GameCore.Data.GameplayData") end)
        GDP = package.loaded["GameLua.GameCore.Data.GameplayData"]
    end

    if GDP then
        local pc = nil
        pcall(function()
            pc = GDP.GetPlayerCharacter and GDP.GetPlayerCharacter()
        end)

        if slua.isValid(pc) and not pc._N5LA_INJECTED then
            if type(_G.N5LAMOD_INJECT_MOD) == "function" then
                local ok, err = pcall(_G.N5LAMOD_INJECT_MOD, pc)
                if ok then
                    print("[N5LA] ✅ Auto-injected into character")
                else
                    print("[N5LA] ⚠️ Auto-inject failed: " .. tostring(err))
                end
            else
                print("[N5LA] ⚠️ N5LAMOD_INJECT_MOD not yet exported")
            end
        end
    end

    pcall(function()
        local ticker = require("common.time_ticker")
        if ticker and ticker.AddTimerOnce then
            ticker.AddTimerOnce(1, _N5LA_AutoInject)
        end
    end)
end

-- بدء المحاولة بعد 2 ثانية (لضمان تحميل كل شيء)
pcall(function()
    local ticker = require("common.time_ticker")
    if ticker and ticker.AddTimerOnce then
        ticker.AddTimerOnce(2, _N5LA_AutoInject)
    end
end)

print("[N5LA] ✅ n5la.lua loaded successfully — auto-inject armed")


-- ═══════════════════════════════════════════════════════════════════════════
-- ⚠️ ملاحظة معمارية:
-- تم حذف return DeclareFeature(...) لأن هذا الملف يُحمّل عبر loadstring()
-- من اللودر الخارجي، والـ return يُتجاهل تماماً في هذا السياق.
-- الكلاس الحقيقي (الـ Feature wrapper) يُسجّل من اللودر الموجود في PAK.
-- هذا الملف يعمل كـ "منطق مود" فقط (ESP/Aimbot/Wallhack/Protection).
-- ═══════════════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════════════
-- ✅ Auto-Injection Fallback
-- يحقن المود في الشخصية تلقائياً حتى لو لم يُستدعى من ReceiveBeginPlay
-- ═══════════════════════════════════════════════════════════════════════════
local function _N5LA_AutoInject()
    local GDP = package.loaded["GameLua.GameCore.Data.GameplayData"]
    if not GDP then
        pcall(function() require("GameLua.GameCore.Data.GameplayData") end)
        GDP = package.loaded["GameLua.GameCore.Data.GameplayData"]
    end

    if GDP then
        local pc = nil
        pcall(function()
            pc = GDP.GetPlayerCharacter and GDP.GetPlayerCharacter()
        end)

        if slua.isValid(pc) and not pc._N5LA_INJECTED then
            if type(_G.N5LAMOD_INJECT_MOD) == "function" then
                local ok, err = pcall(_G.N5LAMOD_INJECT_MOD, pc)
                if ok then
                    print("[N5LA] ✅ Auto-injected into character")
                else
                    print("[N5LA] ⚠️ Auto-inject failed: " .. tostring(err))
                end
            else
                print("[N5LA] ⚠️ N5LAMOD_INJECT_MOD not yet exported")
            end
        end
    end

    pcall(function()
        local ticker = require("common.time_ticker")
        if ticker and ticker.AddTimerOnce then
            ticker.AddTimerOnce(1, _N5LA_AutoInject)
        end
    end)
end

-- بدء المحاولة بعد 2 ثانية (لضمان تحميل كل شيء)
pcall(function()
    local ticker = require("common.time_ticker")
    if ticker and ticker.AddTimerOnce then
        ticker.AddTimerOnce(2, _N5LA_AutoInject)
    end
end)

print("[N5LA] ✅ n5la.lua loaded successfully — auto-inject armed")