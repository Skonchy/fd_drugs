local spawnedDrugTables = {}
local onDrug = false

local hasDrugs = false

function spawnSellTables()
    local cokeModel = "bkr_prop_coke_table01a"
    local weedModel = "bkr_prop_weed_table_01a"
    local i=1
    for k,v in ipairs(Drugs.Locations.Weed.Sell) do
        local hash = GetHashKey(weedModel)
        local x,y,z = table.unpack(Drugs.Locations.Weed.Sell[k])
        RequestModel(hash)
        while not HasModelLoaded(hash) do
            RequestModel(hash)
            Citizen.Wait(0)
        end
        print(hash,x,y,z,weedModel,i)
        spawnedDrugTables[i] = CreateObject(hash,x,y,z-1,true,true,true)
        i = i+1
        --FreezeEntityPosition(drugSpot,true)
    end
    for k,v in ipairs(Drugs.Locations.Cocaine.Sell) do
        local hash = GetHashKey(cokeModel)
        local x,y,z = table.unpack(Drugs.Locations.Cocaine.Sell[k])
        RequestModel(hash)
        while not HasModelLoaded(hash) do
            RequestModel(hash)
            Citizen.Wait(0)
        end
        print(hash,x,y,z,cokeModel,i)
        spawnedDrugTables[i] = CreateObject(hash,x,y,z-1,true,true,true)
        i = i+1
        --FreezeEntityPosition(drugSpot,true)
    end
end

function deleteSpawnedTables()
    for i=1, #spawnedDrugTables do
        DeleteObject(spawnedDrugTables[i])
    end
end

AddEventHandler("UseItem", function(item, slot)
    if (item == "b_weed") then
        --regen health and consume item
        TriggerServerEvent("DRP_Inventory:removeInventoryItem", item, 1)
        local playerPed = GetPlayerPed(-1)
        local Playerhealth = GetEntityHealth(playerPed)
        if not onDrug then
            onDrug = true
            if Playerhealth >= 100 and Playerhealth <= 190 then
                --heal
                SetEntityHealth(playerPed, Playerhealth + 10)
            end
            RequestAnimSet("move_m@hipster@a")
            while not HasAnimSetLoaded("move_m@hipster@a") do
                Citizen.Wait(0)
            end
            TaskStartScenarioInPlace(playerPed, "WORLD_HUMAN_SMOKING_POT", 0, 1)
            Citizen.Wait(3000)
            ClearPedTasksImmediately(playerPed)
            SetTimecycleModifier("spectator5")
            SetPedMotionBlur(playerPed, true)
            SetPedMovementClipset(playerPed, "move_m@hipster@a", true)
            local player = PlayerId()
            Wait(65000)
            ClearTimecycleModifier()
            onDrug = false
        end
    elseif (item == "b_coke") then
        --increase running speed and consume item
        TriggerServerEvent("DRP_Inventory:removeInventoryItem", item, 1)
        local playerPed = GetPlayerPed(-1)
        if not onDrug then
            onDrug = true
            RequestAnimSet("move_m@hipster@a")
            while not HasAnimSetLoaded("move_m@hipster@a") do
                Citizen.Wait(0)
            end
            TaskStartScenarioInPlace(playerPed, "WORLD_HUMAN_SMOKING_POT", 0, 1)
            Citizen.Wait(3000)
            ClearPedTasksImmediately(playerPed)
            SetTimecycleModifier("spectator5")
            SetPedMotionBlur(playerPed, true)
            SetPedMovementClipset(playerPed, "move_m@hipster@a", true)
            local player = PlayerId()
            SetRunSprintMultiplierForPlayer(player,1.3)
            Wait(65000)
            ClearTimecycleModifier()
            SetRunSprintMultiplierForPlayer(player,1.0)
            onDrug = false
        end
    end
end)

RegisterNetEvent("fd_drugs:showProcessBar")
AddEventHandler("fd_drugs:showProcessBar", function(drug)
    if drug == "weed" then
        exports["drp_progressBars"]:startUI(10000,"Processing Weed")
    elseif drug == "coke" then 
        exports["drp_progressBars"]:startUI(10000,"Processing Coke")
    end
end)

RegisterNetEvent('animation')
AddEventHandler('animation', function()
  local pid = PlayerPedId()
  RequestAnimDict("amb@prop_human_bum_bin@idle_b")
  while (not HasAnimDictLoaded("amb@prop_human_bum_bin@idle_b")) do Citizen.Wait(0) end
    TaskPlayAnim(pid,"amb@prop_human_bum_bin@idle_b","idle_d",100.0, 200.0, 0.3, 120, 0.2, 0, 0, 0)
    Wait(750)
    StopAnimTask(pid, "amb@prop_human_bum_bin@idle_b","idle_d", 1.0)
end)

RegisterNetEvent("fd_drugs:updateBoolean")
AddEventHandler("fd_drugs:updateBoolean", function(bool)
    hasDrugs = bool
end)

Citizen.CreateThread(function()
    print("Invoking deleteSpawnedTables")
    deleteSpawnedTables()
    print("Invoking spawnSellTables")
    spawnSellTables()

    while true do
        local sleep = 1000
        local ped = GetPlayerPed(-1)
        local playerPos = GetEntityCoords(ped)
        local drug = "b_weed"
        local pdrug = "k_weed"
        for i=1, #spawnedDrugTables do
            local tablePos = GetEntityCoords(spawnedDrugTables[i])
            local distance = Vdist(playerPos.x,playerPos.y,playerPos.z,tablePos.x,tablePos.y,tablePos.z)
            --print(tablePos,playerPos,distance)
            if distance <= 5.0 then
                --print(tablePos, i)
                if i > 3 then
                    drug = "b_coke"
                    pdrug = "k_coke"
                end
                sleep = 5
                exports["drp_core"]:DrawText3Ds(tablePos.x,tablePos.y,tablePos.z+1,tostring("Press ~b~[E]~w~ to buy baggies or ~r~[X]~w~ to add to the supply"))
                if IsControlJustPressed(1,86) then
                    --Sell 5 bags per click
                    print(drug,i)
                    TriggerServerEvent("fd_drugs:buyDrugs",drug,i) -- pass the drug being bought and the table index to the server
                elseif IsControlJustPressed(1, 73) then
                    --Add kilos to table from inventory max 25kg
                    TriggerServerEvent("fd_drugs:stockTable",pdrug,i) -- pass the drug being delivered and the table index to the server
                end
            end
        end
        Citizen.Wait(sleep)
    end
end)

Citizen.CreateThread(function()
    local sleep = 1000
    while true do
        local ped = GetPlayerPed(-1)
        local playerPos = GetEntityCoords(ped)
        local wPos = Drugs.Locations.Weed.Pickup
        local cPos = Drugs.Locations.Cocaine.Pickup
        local wDist = Vdist(playerPos.x,playerPos.y,playerPos.z,wPos.x,wPos.y,wPos.z)
        local cDist = Vdist(playerPos.x,playerPos.y,playerPos.z,cPos.x,cPos.y,cPos.z)

        if wDist <= 5.0 then
            sleep = 5
            exports["drp_core"]:DrawText3Ds(wPos.x,wPos.y,wPos.z,tostring("Press ~b~[E]~w~ to pick some weed"))
            if IsControlJustPressed(1,86) then
                exports["drp_progressBars"]:startUI(5000,"Gathering Weed") -- Display a progress bar
                Citizen.Wait(5000)
                TriggerServerEvent("fd_drugs:gather","weed")
            end
        elseif cDist <= 5.0 then
            sleep = 5
            exports["drp_core"]:DrawText3Ds(cPos.x,cPos.y,cPos.z,tostring("Press ~b~[E]~w~ to pick some coca leaves"))
            if IsControlJustPressed(1,86) then
                exports["drp_progressBars"]:startUI(5000,"Gathering Coca Leaves")-- Display a progress bar
                Citizen.Wait(5000)
                TriggerServerEvent("fd_drugs:gather","coke")
            end
        end
        Citizen.Wait(sleep)
    end
end)

Citizen.CreateThread(function()
    local sleep = 1000
    while true do
        local ped = GetPlayerPed(-1)
        local playerPos = GetEntityCoords(ped)
        local wPos = Drugs.Locations.Weed.Process
        local cPos = Drugs.Locations.Cocaine.Process
        local wDist = Vdist(playerPos.x,playerPos.y,playerPos.z,wPos.x,wPos.y,wPos.z)
        local cDist = Vdist(playerPos.x,playerPos.y,playerPos.z,cPos.x,cPos.y,cPos.z)
        if wDist <= 5.0 then
            sleep = 5
            exports["drp_core"]:DrawText3Ds(wPos.x,wPos.y,wPos.z,tostring("Press ~b~[E]~w~ to process weed"))
            if IsControlJustPressed(1,86) then
                TriggerServerEvent("fd_drugs:process","weed")
            end
        elseif cDist <= 5.0 then
            sleep = 5
            exports["drp_core"]:DrawText3Ds(cPos.x,cPos.y,cPos.z,tostring("Press ~b~[E]~w~ to process coke"))
            if IsControlJustPressed(1,86) then
                TriggerServerEvent("fd_drugs:process","coke")
            end
        end
        Citizen.Wait(sleep)
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local player = GetPlayerPed(-1)
        local playerloc = GetEntityCoords(player)
        local handle, ped = FindFirstPed()
        repeat
          success, ped = FindNextPed(handle)
          local pos = GetEntityCoords(ped)
          local distance = GetDistanceBetweenCoords(pos.x, pos.y, pos.z, playerloc.x, playerloc.y, playerloc.z, true)
          if IsPedInAnyVehicle(GetPlayerPed(-1)) == false then
            if DoesEntityExist(ped)then
              if IsPedDeadOrDying(ped) == false then
                if IsPedInAnyVehicle(ped) == false then
                  local pedType = GetPedType(ped)
                  if pedType ~= 28 and IsPedAPlayer(ped) == false then
                    currentped = pos
                    if distance <= 2 and ped  ~= GetPlayerPed(-1) and ped ~= oldped then
                        TriggerServerEvent("fd_drugs:checkInv")
                      if hasDrugs == true then
                        drawTxt(0.90, 1.40, 1.0,1.0,0.4, "Press ~b~E ~w~to attempt a drug deal...", 255, 255, 255, 255)
                        if IsControlJustPressed(1, 86) then
                            oldped = ped
                            SetEntityAsMissionEntity(ped)
                            TaskStandStill(ped, 9.0)
                            pos1 = GetEntityCoords(ped)
                            exports["drp_progressBars"]:startUI(2850,"Making the sale")
                            Citizen.Wait(2850)
                            TriggerServerEvent('fd_drugs:sellNPC')
                            SetPedAsNoLongerNeeded(oldped)
                        end
                      end
                    end
                  end
                end
              end
            end
          end
        until not success
        EndFindPed(handle)
      end
end)

function dump(o)
    if type(o) == 'table' then
       local s = '{ '
       for k,v in pairs(o) do
          if type(k) ~= 'number' then k = '"'..k..'"' end
          s = s .. '['..k..'] = ' .. dump(v) .. ','
       end
       return s .. '} '
    else
       return tostring(o)
    end
 end

 function tableLength(array)
    local length = 0 
    if type(array) == 'table' then
        for k,v in pairs(array) do
            length = length + 1
        end
        return length
    else
        return -1
    end
 end
 
function drawTxt(x,y,width,height,scale,text,r,g,b,a,outline)
    SetTextFont(0)
    SetTextProportional(0)
    SetTextScale(scale, scale)
    SetTextColour(r, g, b, a)
    SetTextDropShadow(0, 0, 0, 0,255)
    SetTextEdge(1, 0, 0, 0, 255)
    SetTextDropShadow()
    if(outline)then
      SetTextOutline()
    end
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x - width/2, y - height/2 + 0.005)
end