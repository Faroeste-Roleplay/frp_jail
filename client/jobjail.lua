local rockCoords = {
    vec3(3123.338, -681.642, 42.741),
    vec3(3116.889, -681.559, 43.231),
    vec3(3125.446, -669.0154, 43.40479),
    vec3(3109.678, -664.35, 43.1964),    
    vec3(3106.772, -679.391, 43.072),    
    vec3(3121.406, -692.4548, 42.61),
}

local spawnedRocks = 0
Rocks = {}
local InArea = false
local entity
local HasRareGems = false

working = false

RegisterNetEvent("JAIL:startRockJob", function()

    local playerCoords = GetEntityCoords(PlayerPedId())

    TriggerEvent("texas:notify:native", i18n.translate("info.work"), 6000)

    StartGpsMultiRoute(76603059, true, true)
    AddPointToGpsMultiRoute(3115.858, -662.972, 43.279)    
    SetGpsMultiRouteRender(true)

    while #(playerCoords - vec3(3115.858, -662.972, 43.279)) >= 25 do
        Citizen.Wait(100)
        playerCoords = GetEntityCoords(PlayerPedId())
    end

    if not working then
		ClearGpsMultiRoute()
        SpawnRocks()
        working = true
    end
end)

---check distance from spawned rock
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(5)
        if working then

            local ped = PlayerPedId()
            local pos = GetEntityCoords(ped)
            local nearbyObject, nearbyID

            for i = 1, #Rocks, 1 do

                local EntCoords = GetEntityCoords(Rocks[i])

                if #(pos - EntCoords) < 15 then

                    nearbyObject, nearbyID = Rocks[i], i

                    if nearbyObject then

                        DrawText3D(EntCoords.x, EntCoords.y, EntCoords.z, i18n.translate("prompt.press_to_work"))

                        
                        if #(pos - EntCoords) < 2 then

                            if whenKeyJustPressed("E") then
                                local W = math.random(20000, 30000)

                                MineAndAttach()

                                Wait(100)

                                FreezeEntityPosition(ped, true)

                                exports.progressbar:DisplayProgressBar(W, i18n.translate("info.working"))

                                SetCurrentPedWeapon(PlayerPedId(), GetHashKey("WEAPON_UNARMED"), true)

                                SpawnRocks()

                                DeleteObject(nearbyObject)

                                ClearPedTasks(ped)
                                FreezeEntityPosition(ped, false)

                                DeleteObject(entity)

                                table.remove(Rocks, nearbyID)

                                TriggerEvent("JAIL:JobReward")                            
                                spawnedRocks = spawnedRocks - 1
                            end

                        end
                    end
                end
            end
        end
    end
end)


function SpawnRocks()
    for i = 1, math.random(1, 3) do
        local RockCoords = GenerateRockCoords()

        local obj = CreateObject(GetHashKey("BGV_ROCK_SCREE_SIM_02"), RockCoords.x, RockCoords.y, RockCoords.z, false, false, false)
        
        Citizen.InvokeNative(0x543DFE14BE720027, PlayerId(), obj, 1) -- _REGISTER_EAGLE_EYE_FOR_ENTITY -- glow

        PlaceObjectOnGroundProperly(obj)
        FreezeEntityPosition(obj, true)
        table.insert(Rocks, obj)
        spawnedRocks = spawnedRocks + 1
    end
end


function GenerateRockCoords()
    return rockCoords[math.random(1, #rockCoords)]
end


function MineAndAttach()
    
    if not IsPedMale(Ped()) then
        local waiting = 0
        local dict = "amb_work@world_human_pickaxe@wall@male_d@base"
        RequestAnimDict(dict)
        while not HasAnimDictLoaded(dict) do
            waiting = waiting + 100
            Citizen.Wait(100)
            if waiting > 5000 then
                break
            end
        end

        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local boneIndex = GetEntityBoneIndexByName(ped, "SKEL_R_HAND")
        local modelHash = GetHashKey("P_PICKAXE01X")
        LoadModel(modelHash)
        entity = CreateObject(modelHash, coords.x, coords.y, coords.z, true, false, false)
        SetEntityVisible(entity, true)
        SetEntityAlpha(entity, 255, false)
        Citizen.InvokeNative(0x283978A15512B2FE, entity, true)
        SetModelAsNoLongerNeeded(modelHash)
        AttachEntityToEntity(entity, ped, boneIndex, -0.030, -0.300, -0.010, 0.0, 100.0, 68.0, false, false, false, true, 2, true) ---6th rotates axe point
        TaskPlayAnim(ped, dict, "base", 1.0, 8.0, -1, 1, 0, false, false, false)
    else
        TaskStartScenarioInPlace(Ped(), GetHashKey("WORLD_HUMAN_PICKAXE_WALL"), 60000, true, false, false, false)
    end
end

RegisterNetEvent("JAIL:JobReward", function()
    if Config.JobReward == "time" then
        JailTime = JailTime - math.random(15, 30)
        TriggerServerEvent("JAIL:updateRemaining", JailTime)
    elseif Config.JobReward == "money" then
        TriggerServerEvent("JAIL:JobReawardMoney")
    end
end)

AddEventHandler("onResourceStop", function(resource)
    if resource == GetCurrentResourceName() then
        for k, v in pairs(Rocks) do
            DeleteObject(v)
        end
    end
end)
