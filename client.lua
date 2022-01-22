local owned = {}
local Sync = {}
local blips = {}
local marker = {}
local signs = {}
local businessStore = {}
local displayBlips = true

if GetResourceKvpFloat('PFPropertyBlips') == nil then
    SetResourceKvpFloat('PFPropertyBlips', 1.0)
else
    if GetResourceKvpFloat('PFPropertyBlips') == 1.0 then
        displayBlips = true
    else
        displayBlips = false
    end
end

RegisterCommand('properties', function(source, args, RawCommand)
    if displayBlips then
        SetResourceKvpFloat('PFPropertyBlips', 0.0)
        status = 'Disabled'
    else
        SetResourceKvpFloat('PFPropertyBlips', 1.0)
        status = 'Enabled'
    end
    TriggerServerEvent('PFProperty:message', GetPlayerServerId(PlayerId()), ('Property blips have been %s'):format(status))
    displayBlips = not displayBlips
end)

exports['chat']:addSuggestion('/sell', 'Sell a property you own.', {{ name = "Confirm", help = "use confirm if you're sure you want to sell."}})
exports['chat']:addSuggestion('/buy', 'Buy a property.')
exports['chat']:addSuggestion('/properties', 'Disable or Enable the property blips.')

RegisterNetEvent('PFProperty:businessStore')
AddEventHandler('PFProperty:businessStore', function(tab)
    businessStore = tab
end)

RegisterNetEvent('PFProperty:Sync')
AddEventHandler('PFProperty:Sync', function(tab)
    owned = tab
    Sync = {}
    for k,v in pairs(tab) do
        table.insert(Sync, v.Name)
    end
end)

CreateThread(function()
    while true do
        Wait(1000)
        for k,v in pairs(businessStore) do
            if blips[k] and displayBlips then
                if not has_val(Sync,k) then
                    setBlip(k, v.blip.forsale)
                else
                    setBlip(k, v.blip.sold)
                end
            end
            if not has_val(Sync,k) then
                sign('add', k)
            else
                sign('delete', k)
            end
        end
        for k,v in pairs(Config.Agency) do
            setBlip(k)
        end
        createBlips()
    end
end)

CreateThread(function()
    while true do
        Wait(0)
        close = false
        for k,v in pairs(Config.Agency) do
            if #(v.loc - GetEntityCoords(PlayerPedId())) < 10 then
                close = true
                DrawMarker(29, v.loc, 0, 0, 0, 0, 0, 0, 1.0 ,1.0 ,1.0 ,11 ,102 ,35 ,100 ,false ,false ,false ,true )
            end
        end
        if not close then Wait(1000) end
    end
end)

function has_val(tab, val)
    for _, i in pairs(tab) do
        if i == val then
            return true
        end
    end
    return false
end

function sign(type, name)
    if type == 'delete' then
        if signs[name] then
            DeleteEntity(signs[name])
            signs[name] = nil
        end
    else
        if not signs[name] then
            loc = split(businessStore[name].sign.loc, ",")
            signs[name] = CreateObject("prop_forsale_sign_05", vec3(tonumber(loc[1]), tonumber(loc[2]), tonumber(loc[3])), true, true, false)
            Wait(1)
            SetEntityHeading(signs[name], tonumber(businessStore[name].sign.heading))
            SetEntityInvincible(signs[name])
            FreezeEntityPosition(signs[name], true)
            PlaceObjectOnGroundProperly(signs[name])
        end
    end
end

function createBlips()
    if displayBlips then
        for k,v in pairs(businessStore) do
            if not blips[k] then
                loc = split(businessStore[k].blip.loc, ",")
                local blip = AddBlipForCoord(vec3(tonumber(loc[1]), tonumber(loc[2]), tonumber(loc[3])))
                SetBlipSprite(blip, v.blip.forsale)
                SetBlipCategory(blip, 10)
                SetBlipAsShortRange(blip, true)
                blips[k] = blip
            end
        end
        for k,v in pairs(Config.Agency) do
            if not blips[k] then
                local blip = AddBlipForCoord(v.loc)
                SetBlipSprite(blip, 442)
                SetBlipCategory(blip, 10)
                SetBlipAsShortRange(blip, true)
                blips[k] = blip
            end
        end
    else
        for k,v in pairs(blips) do
           RemoveBlip(v)
           blips[k] = nil
        end
    end
end

function setBlip(k, v)
    if businessStore[k] then
        SetBlipSprite(blips[k], v)
        AddTextEntry('MYBLIP'..k, businessStore[k].displayName)
        BeginTextCommandSetBlipName('MYBLIP'..k)
        AddTextComponentSubstringPlayerName('me')
        EndTextCommandSetBlipName(blips[k])
    else
        AddTextEntry('MYBLIP'..k, Config.Agency[k].name)
        BeginTextCommandSetBlipName('MYBLIP'..k)
        AddTextComponentSubstringPlayerName('me')
        EndTextCommandSetBlipName(blips[k])
    end
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

saves = {}
temp = {}
local hasPerms = false

RegisterNetEvent('PFProperty:sendPerms')
AddEventHandler('PFProperty:sendPerms', function(state)
    hasPerms = state
end)

RegisterCommand('property:create', function(source, args, RawCommand)
    TriggerServerEvent('PFProperty:checkPerms')
    Wait(50)
    if not hasPerms then
        return TriggerServerEvent('PFProperty:message', GetPlayerServerId(PlayerId()), 'You don\'t have permission to use this command.')
    end
    local playerPed = PlayerPedId()
    if not args[1] then
    return TriggerServerEvent('PFProperty:message', GetPlayerServerId(PlayerId()), '/property:create [house/store/airfield] [name]')
    end
    if saves['marker'] ~= nil then
        local type = args[1]
        if args[1] == 'house' then
            blipSale = 350
        elseif args[1] == 'store' then
            blipSale = 375
        elseif args[1] == 'airfield' then
            blipSale = 372
        else
            return TriggerServerEvent('PFProperty:message', GetPlayerServerId(PlayerId()), '/property:create [house/store/airfield] [name]')
        end
        table.remove(args, 1)
        local name = table.concat(args, " ")
        local bname = table.concat(args, ""):lower()
        local ploc = GetEntityCoords(temp)
        local heading = GetEntityHeading(temp)
        local args = {
            name = bname,
            displayName = name,
            markerPos = saves['marker'],
            blipSale = blipSale,
            blipSold = 374,
            signPos = ploc,
            signHeading = heading,
            range = 2
        }

        TriggerServerEvent('PFProperty:AddToDataBase', args)
        saves['marker'] = nil
        TriggerServerEvent('PFProperty:message', GetPlayerServerId(PlayerId()), 'Saved in file.')
        DeleteEntity(temp)
    else
        if args[1] ~= 'house' and args[1] ~= 'store' and args[1] ~= 'airfield' then
            return TriggerServerEvent('PFProperty:message', GetPlayerServerId(PlayerId()), '/property:create [house/store/airfield] [name]')
        end
        saves['marker'] = GetEntityCoords(playerPed)
        local pPos = GetEntityCoords(playerPed)
        temp = CreateObject("prop_forsale_sign_05", pPos.x, pPos.y, pPos.z, true, true, false)
        SetEntityHeading(temp, GetEntityHeading(playerPed))
        AttachEntityToEntity(temp, playerPed, 24818, 0 - 0.12, 1.0, 0 - 1.0, 0, 0, 0, 0, 0, 0, 0, 1, 1)
        SetEntityAlpha(temp, 200, 1)
        TriggerServerEvent('PFProperty:message', GetPlayerServerId(PlayerId()), 'Map marker saved. Run the command again to save the sign location.')
    end
end, true)