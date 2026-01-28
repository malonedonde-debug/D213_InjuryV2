local ESX = exports["es_extended"]:getSharedObject()
local isInjured = false
local lastBleedTick = 0
local lastStumbleTick = 0

--- Helper function to handle notifications
local function sendNotification(message, type)
    if Config.NotificationType == "ox_lib" then
        lib.notify({
            title = "Injury System",
            description = message,
            type = type,
            position = "top"
        })
    elseif Config.NotificationType == "vms_notify" then
        exports["vms_notify"]:Notification("INJURY", message, 5000, "#cf3030", "fa-solid fa-house-medical")
    else
        ESX.ShowNotification(message)
    end
end

--- Apply or remove the injured state effects
local function setInjuredState(state)
    local ped = PlayerPedId()
    
    if state then
        RequestAnimSet(Config.WalkStyle)
        while not HasAnimSetLoaded(Config.WalkStyle) do
            Wait(0)
        end
        SetPedMovementClipset(ped, Config.WalkStyle, 1.0)
        
        if not AnimpostfxIsRunning(Config.ScreenEffect) then
            AnimpostfxPlay(Config.ScreenEffect, 0, true)
        end
        if Config.Debug then print("Injured state activated") end
    else
        ResetPedMovementClipset(ped, 1.0)
        SetPedMoveRateOverride(ped, 1.0)
        if AnimpostfxIsRunning(Config.ScreenEffect) then
            AnimpostfxStop(Config.ScreenEffect)
        end
        if Config.Debug then print("Injured state deactivated") end
    end
    
    isInjured = state
end

--- Precision shooting task handler targeting legs
RegisterNetEvent("esx_injury:client:setupAttackerTask", function(netId, weaponHash)
    local timeout = 0
    while not NetworkDoesEntityExistWithNetworkId(netId) and timeout < 100 do
        Wait(10)
        timeout = timeout + 1
    end

    local npc = NetworkGetEntityFromNetworkId(netId)
    local playerPed = PlayerPedId()

    if DoesEntityExist(npc) then
        -- Ensure weapon assets are loaded
        RequestWeaponAsset(weaponHash, 31, 0)
        while not HasWeaponAssetLoaded(weaponHash) do Wait(0) end

        -- Force weapon into hand and set combat attributes
        GiveWeaponToPed(npc, weaponHash, 999, false, true)
        SetCurrentPedWeapon(npc, weaponHash, true)
        SetPedCanSwitchWeapon(npc, false)
        
        SetPedAccuracy(npc, 100)
        SetPedCombatAttributes(npc, 46, true) -- Always fight
        SetPedCombatAttributes(npc, 142, true) -- Use pro aim
        SetPedCombatRange(npc, 2)
        
        CreateThread(function()
            local startTime = GetGameTimer()
            
            -- Initial "Wake up"
            TaskAimGunAtEntity(npc, playerPed, 500, false)
            Wait(500)

            while DoesEntityExist(npc) and (GetGameTimer() - startTime < 15000) do
                if IsEntityDead(npc) or IsEntityDead(playerPed) then break end
                
                -- Target Left Leg (58271) or Right Leg (36864)
                local targetBone = 58271 
                local targetCoords = GetPedBoneCoords(playerPed, targetBone, 0.0, 0.0, 0.0)
                
                -- Force the task to shoot at the leg coordinates
                TaskShootAtCoord(npc, targetCoords.x, targetCoords.y, targetCoords.z, 3000, `FIRING_PATTERN_FULL_AUTO`)
                
                Wait(1000)
            end
        end)
    end
end)

--- Main Loop
CreateThread(function()
    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        
        if DoesEntityExist(ped) then
            local health = GetEntityHealth(ped)
            local isDead = IsEntityDead(ped) or health <= 0

            -- 1. Injury Threshold Logic
            if not isDead and health <= Config.InjuryThreshold then
                if not isInjured then
                    setInjuredState(true)
                    lastBleedTick = GetGameTimer()
                    lastStumbleTick = GetGameTimer()
                    sendNotification("You are critically injured!", "error")
                end
                
                sleep = 0 
                
                -- Force Walkstyle
                if GetPedMovementClipset(ped) ~= GetHashKey(Config.WalkStyle) then
                    SetPedMovementClipset(ped, Config.WalkStyle, 1.0)
                end
                
                -- Force Movement Speed
                SetPedMoveRateOverride(ped, Config.MoveSpeedMultiplier)

                local currentTime = GetGameTimer()

                -- Bleeding logic
                if (currentTime - lastBleedTick) >= Config.BleedInterval then
                    local newHealth = health - Config.BleedDamage
                    if newHealth < 100 then newHealth = 0 end 
                    SetEntityHealth(ped, newHealth)
                    lastBleedTick = currentTime
                    sendNotification("You are losing blood...", "error")
                    if newHealth <= 0 then TriggerServerEvent("esx_injury:server:logDeath") end
                end

                -- Stumbling logic
                if (currentTime - lastStumbleTick) >= Config.StumbleInterval then
                    local velocity = GetEntityVelocity(ped)
                    local speed = #(velocity)
                    if IsPedOnFoot(ped) and not IsPedRagdoll(ped) and speed > 1.0 and not IsPedSwimming(ped) then
                        SetPedToRagdoll(ped, Config.StumbleDuration, Config.StumbleDuration, 0, false, false, false)
                        lastStumbleTick = currentTime
                    end
                end
            else
                if isInjured then 
                    setInjuredState(false) 
                end
            end

            -- 2. Leg Shot Detection
            if HasEntityBeenDamagedByAnyPed(ped) then
                local found, bone = GetPedLastDamageBone(ped)
                if found and Config.LegBones[bone] then
                    if not IsPedRagdoll(ped) and IsPedOnFoot(ped) then
                        sendNotification("You were shot in the leg!", "error")
                        SetPedToRagdoll(ped, Config.LegShotStumbleDuration, Config.LegShotStumbleDuration, 0, false, false, false)
                    end
                end
                ClearEntityLastDamageEntity(ped)
            end
        end
        Wait(sleep)
    end
end)

-- Simplified Test Command (Aims at legs only)
if Config.TestCommand.Enabled then
    RegisterCommand(Config.TestCommand.CommandName, function()
        local options = {}

        for _, pedData in ipairs(Config.TestCommand.Peds) do
            table.insert(options, {
                title = "Spawn " .. pedData.label,
                description = "Will spawn and attempt to shoot your legs",
                onSelect = function()
                    local weaponOptions = {}
                    for _, weap in ipairs(Config.TestCommand.Weapons) do
                        table.insert(weaponOptions, {
                            title = weap.label,
                            onSelect = function()
                                TriggerServerEvent("esx_injury:server:spawnAttacker", pedData.model, weap.hash)
                            end
                        })
                    end
                    lib.registerContext({
                        id = "injury_weapon_menu",
                        title = "Select Weapon",
                        options = weaponOptions
                    })
                    lib.showContext("injury_weapon_menu")
                end
            })
        end

        lib.registerContext({
            id = "injury_test_menu",
            title = "Injury System Test (Leg Targeting)",
            options = options
        })
        lib.showContext("injury_test_menu")
    end, false)
end

AddEventHandler("esx:onPlayerSpawn", function()
    setInjuredState(false)
    lastBleedTick = GetGameTimer()
    lastStumbleTick = GetGameTimer()
end)