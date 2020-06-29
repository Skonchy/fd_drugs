RegisterServerEvent("fd_drugs:buyDrugs")
AddEventHandler("fd_drugs:buyDrugs", function(drug,table)
    local src = source
    local drugCost = 0
    local drugLabel = ""
    exports["externalsql"]:AsyncQueryCallback({
        query = "SELECT * FROM drugs WHERE id = :index",
        data = {
            index = table
        }
    }, function(results)
            if results.data == nil then
                print("Drug table with index "..table.." not found")
            else
                print(dump(results))
                if results.data[1].supply < 5 or nil then
                    TriggerClientEvent("DRP_Core:Error",src,"Drugs",tostring("This table is currently out of stock. Check back later!"),4500,false,"leftCenter")
                else
                    print("About to add the item")
                    if drug == "b_weed" then
                        drugCost = 7 --buy 7 sell 10
                        drugLabel = "Marijauna"
                    elseif drug == "b_coke" then
                        drugCost = 25 -- buy 25 sell 32
                        drugLabel = "Cocaine"
                    end
                    TriggerEvent("DRP_Inventory:addInventoryItem",drug,5,src)
                    TriggerClientEvent("DRP_Core:Info",src,"Drugs",tostring("You bought 5 baggies of "..drugLabel),4500,false,"leftCenter")
                    TriggerEvent("DRP_Bank:RemoveCashMoney",exports["drp_id"]:GetCharacterData(src),5*drugCost)
                    exports["externalsql"]:AsyncQueryCallback({
                        query = "UPDATE drugs SET supply = supply - 5 WHERE id = :index",
                        data = {
                            index = table
                        }
                    }, function(cunt) end)
                end
            end
        end)
end)

RegisterServerEvent("fd_drugs:gather")
AddEventHandler("fd_drugs:gather", function(item)
    local src = source
    if item == "weed" then
        TriggerEvent("DRP_Inventory:addInventoryItem","u_weed",1,src)
    elseif item == "coke" then
        TriggerEvent("DRP_Inventory:addInventoryItem","u_coke",1,src)
    end
end)

RegisterServerEvent("fd_drugs:process")
AddEventHandler("fd_drugs:process", function(item)
    local src = source
    local character = exports["drp_id"]:GetCharacterData(src)
    if item == "weed" then
        local itemCheck = exports["drp_inventory"]:GetItem(character,"u_weed")
        if itemCheck == nil then
            TriggerClientEvent("DRP_Core:Error",src,"Drugs",tostring("You don't have any unprocessed weed."),4500,false,"leftCenter")
        elseif itemCheck >= 100 then
            TriggerEvent("DRP_Inventory:removeInventoryItem","u_weed",100,src)
            TriggerClientEvent("fd_drugs:showProcessBar",src,"weed")
            TriggerClientEvent("fd_drugs:toggleBusy",src,true)
            Citizen.Wait(10000)
            TriggerEvent("DRP_Inventory:addInventoryItem","k_weed",1,src)
            TriggerClientEvent("fd_drugs:toggleBusy",src,false)
        end
    elseif item == "coke" then
        local itemCheck = exports["drp_inventory"]:GetItem(character,"u_coke")
        if itemCheck == nil then
            TriggerClientEvent("DRP_Core:Error",src,"Drugs",tostring("You don't have any unprocessed cocaine."),4500,false,"leftCenter")
        elseif itemCheck >= 100 then
            TriggerEvent("DRP_Inventory:removeInventoryItem","u_coke",100,src)
            TriggerClientEvent("fd_drugs:showProcessBar",src,"coke")
            Citizen.Wait(10000)
            TriggerEvent("DRP_Inventory:addInventoryItem","k_coke",1,src)
        end
    end
end)

RegisterServerEvent("fd_drugs:stockTable")
AddEventHandler("fd_drugs:stockTable", function(drug, table)
    local src = source
    local drugCost = 0
    local drugLabel = ""
    local character = exports["drp_id"]:GetCharacterData(src)
    
    exports["externalsql"]:AsyncQueryCallback({
        query = "SELECT * FROM drugs WHERE id = :index",
        data = {
            index = table
        }
    }, function(results)
            if results.data == nil then
                print("Drug table with index "..table.." not found")
            else
                print(dump(results))
                if results.data[1].supply > 400 or nil then
                    TriggerClientEvent("DRP_Core:Error",src,"Drugs",tostring("This table is currently fully stocked. Check back later!"),4500,false,"leftCenter")
                else
                    if drug == "k_weed" then
                        drugCost = 1200 --sell 1200
                        drugLabel = "Marijauna"
                    elseif drug == "k_coke" then
                        drugCost = 3500 -- sell 3500
                        drugLabel = "Cocaine"
                    end
                    local itemCheck = exports["drp_inventory"]:GetItem(character,drug)
                    if itemCheck == nil then
                        TriggerClientEvent("DRP_Core:Error",src,"Drugs",tostring("You don't have any drugs to add to the stock."),4500,false,"leftCenter")
                    else
                        if itemCheck >= 1 then
                            TriggerEvent("DRP_Inventory:removeInventoryItem",drug,1,src)
                            TriggerClientEvent("DRP_Core:Info",src,"Drugs",tostring("You sold one kilogram of "..drugLabel.." and added it to the stock"),4500,false,"leftCenter")
                            TriggerEvent("DRP_Bank:AddCashMoney",exports["drp_id"]:GetCharacterData(src),drugCost)
                            exports["externalsql"]:AsyncQueryCallback({
                                query = "UPDATE drugs SET supply = supply + 100 WHERE id = :index",
                                data = {
                                    index = table
                                }
                            }, function(cunt) end)
                        end
                    end
                end
            end
        end)
end)

RegisterServerEvent("fd_drugs:checkInv")
AddEventHandler("fd_drugs:checkInv",function()
    local src = source
    local character = exports["drp_id"]:GetCharacterData(src)
    local itemCheck = exports["drp_inventory"]:GetItem(character,"b_weed")
    if itemCheck == nil then
        TriggerClientEvent("fd_drugs:updateBoolean",src,false)
        itemCheck = exports["drp_inventory"]:GetItem(character,"b_coke")
        if itemCheck == nil then
            TriggerClientEvent("fd_drugs:updateBoolean",src,false)
        elseif itemCheck >=1 then
            TriggerClientEvent("fd_drugs:updateBoolean",src,true)
        end
    elseif itemCheck >= 1 then
        TriggerClientEvent("fd_drugs:updateBoolean",src,true)
    end
end)

RegisterServerEvent("fd_drugs:sellNPC")
AddEventHandler("fd_drugs:sellNPC", function()
    local src = source
    local character = exports["drp_id"]:GetCharacterData(src)
    local srcPos = GetEntityCoords(GetPlayerPed(src))
    local weedCheck = exports["drp_inventory"]:GetItem(character,"b_weed")
    local cokePrice = math.random(26,34)
    local weedPrice = math.random(8,12)
    local chance = math.random()
    local success

    if chance > 0.5 then
        success = true
    else
        success = false
    end

    if weedCheck == nil then
        print("No weed, checking next")
        local cokeCheck = exports["drp_inventory"]:GetItem(character,"b_coke")
        if cokeCheck == nil then
            print("No coke, checking next")
        else
            if success then
                if cokeCheck == 1 then
                    TriggerEvent("DRP_Inventory:removeInventoryItem","b_coke",1,src)
                    TriggerClientEvent("DRP_Core:Info",src,"Drugs",tostring("You sold one baggie of Cocaine"),4500,false,"leftCenter")
                    TriggerEvent("DRP_Bank:AddCashMoney",character,cokePrice)
                else
                    local amount = math.random(1,cokeCheck)%14
                    if amount == 0 then
                        amount = 1
                    end
                    TriggerEvent("DRP_Inventory:removeInventoryItem","b_coke",amount,src)
                    TriggerClientEvent("DRP_Core:Info",src,"Drugs",tostring("You sold "..amount.." baggies of Cocaine"),4500,false,"leftCenter")
                    TriggerEvent("DRP_Bank:AddCashMoney",character,amount*cokePrice)
                end
            else
                TriggerEvent("fd_drugs:callCops",srcPos)
            end
        end
    else
        if success then
            if weedCheck == 1 then
                TriggerEvent("DRP_Inventory:removeInventoryItem","b_weed",1,src)
                TriggerClientEvent("DRP_Core:Info",src,"Drugs",tostring("You sold one baggie of Weed"),4500,false,"leftCenter")
                TriggerEvent("DRP_Bank:AddCashMoney",character,weedPrice)
            else
                local amount = math.random(1,weedCheck)%14
                if amount == 0 then
                    amount = 1
                end
                TriggerEvent("DRP_Inventory:removeInventoryItem","b_weed",amount,src)
                TriggerClientEvent("DRP_Core:Info",src,"Drugs",tostring("You sold "..amount.." baggies of Weed"),4500,false,"leftCenter")
                TriggerEvent("DRP_Bank:AddCashMoney",character,amount*weedPrice)
            end
        else
            TriggerEvent("fd_drugs:callCops",srcPos)
        end
    end
    
end)

RegisterServerEvent("fd_drugs:callCops")
AddEventHandler("fd_drugs:callCops", function(coords)
    local chance = math.random()
    local callInformation = "a local. A suspicious person just asked me if I wanted to buy any drugs"
    if chance <= 0.50 then
        TriggerEvent("DRP_Police:CallHandler", {x = coords.x, y = coords.y , z = coords.z}, callInformation)
        print("Cops Called")
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