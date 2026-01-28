local ESX = exports["es_extended"]:getSharedObject()

--- Helper function to calculate forward vector on server-side
--- @param heading number The entity heading
--- @return vector3 The forward direction
local function getForwardVector(heading)
    local rad = math.rad(heading)
    return vector3(-math.sin(rad), math.cos(rad), 0.0)
end

RegisterNetEvent("esx_injury:server:logDeath", function()
    local src = source
    print(("[INJURY] Player %s has succumbed to their wounds."):format(GetPlayerName(src)))
end)

if Config.TestCommand.Enabled then
    RegisterNetEvent("esx_injury:server:spawnAttacker", function(model, weapon)
        local src = source
        local xPlayer = ESX.GetPlayerFromId(src)
        
        -- Permission check
        if Config.TestCommand.Restricted and xPlayer.getGroup() ~= Config.TestCommand.Restricted then
            return
        end

        local playerPed = GetPlayerPed(src)
        local coords = GetEntityCoords(playerPed)
        local heading = GetEntityHeading(playerPed)
        
        -- Spawn 6 meters in front
        local forward = getForwardVector(heading)
        local spawnCoords = coords + (forward * 6.0)

        -- Create the NPC
        local npc = CreatePed(4, GetHashKey(model), spawnCoords.x, spawnCoords.y, spawnCoords.z, heading + 180.0, true, true)
        
        local timeout = 0
        while not DoesEntityExist(npc) and timeout < 100 do 
            Wait(10) 
            timeout = timeout + 1
        end

        if DoesEntityExist(npc) then
            local netId = NetworkGetNetworkIdFromEntity(npc)
            local weaponHash = GetHashKey(weapon)
            
            -- Server side weapon assignment
            GiveWeaponToPed(npc, weaponHash, 999, false, true)
            SetCurrentPedWeapon(npc, weaponHash, true)
            
            -- Trigger client tasking for leg targeting
            TriggerClientEvent("esx_injury:client:setupAttackerTask", src, netId, weaponHash)
            
            -- Clean up NPC after 15 seconds
            SetTimeout(15000, function()
                if DoesEntityExist(npc) then
                    DeleteEntity(npc)
                end
            end)
        end
    end)
end