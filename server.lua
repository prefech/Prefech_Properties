local owned = {}
local temp = {}
local businessUnpacked = {}

RegisterCommand('buy', function(source, args, RawCommand)
    local id = ExtractIdentifiers(source)
    for k,v in pairs(businessUnpacked) do
        signPos = split(v.sign.loc, ",")
        if #(vec3(tonumber(signPos[1]), tonumber(signPos[2]), tonumber(signPos[3])) - GetEntityCoords(GetPlayerPed(source))) <= v.range then
            if checkOwned(k) then
                if owned[id] then
                    return TriggerEvent('PFProperty:message', source, 'You can only have one property at a time.')
                end
                return buyProperty(source, args, RawCommand, k, id)
            end
        end
    end

    for k,v in pairs(Config.Agency) do
        if #(v.loc - GetEntityCoords(GetPlayerPed(source))) <= v.range then
            if args[1] then
                local k = table.concat(args, ""):lower()
                if businessUnpacked[k] then
                    if checkOwned(k) then
                        if owned[id] then
                            return TriggerEvent('PFProperty:message', source, 'You can only have one property at a time.')
                        end
                        return buyProperty(source, args, RawCommand, k, id)
                    end
                else
                    return TriggerEvent('PFProperty:message', source, ('It doesn\t look like^1 %s ^0is a property you can buy. ^1Please check your spelling.^0'):format(table.concat(args, "")))
                end
            else
                return TriggerEvent('PFProperty:message', source, 'Please use: /buy [Property Name].')
            end
        end
    end
end)

RegisterCommand('sell', function(source, args, RawCommand)
    local id = ExtractIdentifiers(source)
    if not owned[id] then
        return TriggerEvent('PFProperty:message', source, 'You don\'t own any properties you can sell.')
    end
    if args[1] ~= 'confirm' then
        return TriggerEvent('PFProperty:message', source, ('Please use ^1/sell confirm^0 if you want to sell the %s'):format(businessUnpacked[owned[id].Name].displayName))
    end
    TriggerEvent('PFProperty:message', -1, ('%s has sold the %s'):format(GetPlayerName(source), businessUnpacked[owned[id].Name].displayName))
    if Config.Keep then
        local result = MySQL.query.await('UPDATE prefech_properties SET isOwned = 0 WHERE name = ?', {owned[id].Name})
    end
    owned[id] = nil
    TriggerClientEvent('PFProperty:Sync', -1, owned)
end)

RegisterNetEvent('PFProperty:checkPerms')
AddEventHandler('PFProperty:checkPerms', function()
    if IsPlayerAceAllowed(source, Config.AcePerm) then
        return TriggerClientEvent('PFProperty:sendPerms', source, true)
    end
    return TriggerClientEvent('PFProperty:sendPerms', source, false)
end)

AddEventHandler("playerJoining", function(source, oldID)
    TriggerClientEvent('PFProperty:businessStore', source, businessUnpacked)
    Wait(500)
    TriggerClientEvent('PFProperty:Sync', source, owned)
end)

function buyProperty(source, args, RawCommand, k, id)
    if Config.Keep then
        MySQL.query.await('UPDATE prefech_properties SET isOwned = ? WHERE name = ?', {id, k})
    end
    owned[id] = {
        ['Name'] = k
    }
    TriggerClientEvent('PFProperty:Sync', -1, owned)
    TriggerEvent('PFProperty:message', -1, ('%s has bought the %s'):format(GetPlayerName(source), businessUnpacked[k].displayName))
end

function ExtractIdentifiers(src)
    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local id = GetPlayerIdentifier(src, i)
        if string.find(id, "license:") then
            return id
        end
    end
    return
end

function checkOwned(x)
    for k,v in pairs(owned) do table.insert(temp, v.Name) end
    if not has_val(temp, x) then
        temp = {}
        return true
    end
    temp = {}
    return false
end

function has_val(tab, val)
    for _, i in pairs(tab) do
        if i == val then
            return true
        end
    end
    return false
end

RegisterNetEvent('PFProperty:message')
AddEventHandler('PFProperty:message', function(target, msg)
    exports['chat']:addMessage(target, msg) --[[ Replace this with your notifcation resource :) ]]
end)

function message(target, msg)
    exports['chat']:addMessage(target, msg) --[[ Replace this with your notifcation resource :) ]]
end

RegisterNetEvent('PFProperty:AddToDataBase')
AddEventHandler('PFProperty:AddToDataBase', function(args)
    local markerPos = ("%s,%s,%s"):format(decimal(args.markerPos.x), decimal(args.markerPos.y), decimal(args.markerPos.z))
    local signPos = ("%s,%s,%s"):format(decimal(args.signPos.x), decimal(args.signPos.y), decimal(args.signPos.z))
    MySQL.query.await('INSERT INTO prefech_properties (id, name, display_name, marker_pos, forsale_blip, sold_blip, sign_pos, sign_heading, inrange, isOwned) VALUES (NULL, ?, ?, ?, ?, ?, ?, ?, ?, 0);', {args.name, args.displayName, markerPos, args.blipSale, args.blipSold, signPos, decimal(args.signHeading), args.range})
    Wait(500)
    propertySync()
end)

function propertySync()
    local result = MySQL.query.await('SELECT * FROM prefech_properties', {})
    businessUnpacked = {}
    for k,v in pairs(result) do
        businessUnpacked[v.name] = {
            displayName = v.display_name,
            blip = {
                loc = v.marker_pos,
                forsale = v.forsale_blip,
                sold = v.sold_blip
            },
            sign = {
                loc = v.sign_pos,
                heading = v.sign_heading
            },
            range = v.inrange
        }
        if v.isOwned ~= '0' then
            owned[v.isOwned] = {
                ['Name'] = v.name
            }
        end
    end
    TriggerClientEvent('PFProperty:businessStore', -1, businessUnpacked)
    Wait(500)
    TriggerClientEvent('PFProperty:Sync', -1, owned)
end

AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() == resourceName) then
        TriggerClientEvent('PFProperty:businessStore', -1, businessUnpacked)
        Wait(500)
        TriggerClientEvent('PFProperty:Sync', -1, owned)
    end
end)

CreateThread(function()
    Wait(500)
    propertySync()
end)

function decimal(i)
    return math.floor(i * 100) / 100
end

function split(inputstr, sep)
    if sep == nil then
            sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
            table.insert(t, str)
    end
    return t
end