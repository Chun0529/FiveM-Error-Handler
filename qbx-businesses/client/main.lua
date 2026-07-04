lib.locale()

local businesses = {}
local blips = {}
local playerCitizenId

local function notify(message, notifyType)
    lib.notify({
        description = message,
        type = notifyType or 'inform',
    })
end

local function getBusiness(businessId)
    return businesses[businessId]
end

local function getLocation(businessId)
    return GetBusinessLocation(businessId)
end

function GetLocalBusiness(businessId)
    return getBusiness(businessId)
end

local function removeBlip(businessId)
    if blips[businessId] and DoesBlipExist(blips[businessId]) then
        RemoveBlip(blips[businessId])
    end

    blips[businessId] = nil
end

local function createBlip(businessId, summary)
    removeBlip(businessId)

    if not Config.ShowBlips then return end

    local location = getLocation(businessId)
    if not location then return end

    local blipConfig = summary.forSale and Config.ForSaleBlip or Config.OwnedBlip
    local blip = AddBlipForCoord(location.blip.x, location.blip.y, location.blip.z)

    SetBlipSprite(blip, blipConfig.sprite)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, blipConfig.scale)
    SetBlipColour(blip, blipConfig.color)
    SetBlipAsShortRange(blip, true)

    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(summary.forSale and (summary.label .. ' - For Sale') or summary.label)
    EndTextCommandSetBlipName(blip)

    blips[businessId] = blip
end

local function refreshBlips()
    for businessId in pairs(blips) do
        removeBlip(businessId)
    end

    for businessId, summary in pairs(businesses) do
        createBlip(businessId, summary)
    end
end

local function upsertBusiness(summary)
    businesses[summary.id] = summary
    createBlip(summary.id, summary)
end

RegisterNetEvent('qbx-businesses:client:syncBusiness', function(summary)
    upsertBusiness(summary)
end)

RegisterNetEvent('qbx-businesses:client:syncAllBusinesses', function(summaries)
    businesses = {}

    for i = 1, #summaries do
        upsertBusiness(summaries[i])
    end
end)

local function createInteractionPoint(name, coords, options)
    if Config.UseOxTarget and GetResourceState('ox_target') == 'started' then
        exports.ox_target:addSphereZone({
            name = name,
            coords = coords,
            radius = Config.InteractionDistance,
            debug = Config.Debug,
            options = options,
        })
        return
    end

    lib.points.new({
        coords = coords,
        distance = Config.InteractionDistance + 1.0,
        nearby = function(point)
            if point.currentDistance <= Config.InteractionDistance then
                local hints = {}
                for i = 1, #options do
                    hints[#hints + 1] = ('[E] %s'):format(options[i].label)
                end
                lib.showTextUI(table.concat(hints, '  '))

                if IsControlJustReleased(0, 38) and options[1] then
                    if options[1].canInteract and not options[1].canInteract() then
                        notify(options[1].disabledMessage or 'Unavailable', 'error')
                    else
                        options[1].onSelect()
                    end
                end
            else
                lib.hideTextUI()
            end
        end,
        onExit = function()
            lib.hideTextUI()
        end,
    })
end

local function setupBusinessInteractions(location)
    local businessId = location.id

    createInteractionPoint(('qbx_business_shop_%s'):format(businessId), location.shop, {
        {
            name = 'qbx_business_shop',
            label = locale('browse_shop'),
            icon = 'fas fa-shopping-basket',
            canInteract = function()
                local summary = getBusiness(businessId)
                return summary and not summary.forSale
            end,
            onSelect = function()
                OpenBusinessShop(businessId)
            end,
        },
        {
            name = 'qbx_business_buy',
            label = locale('buy_business'),
            icon = 'fas fa-store',
            canInteract = function()
                local summary = getBusiness(businessId)
                return summary and summary.forSale
            end,
            onSelect = function()
                PurchaseBusiness(businessId)
            end,
        },
    })

    createInteractionPoint(('qbx_business_manage_%s'):format(businessId), location.management, {
        {
            name = 'qbx_business_manage',
            label = locale('manage_business'),
            icon = 'fas fa-briefcase',
            canInteract = function()
                local summary = getBusiness(businessId)
                if not summary or summary.forSale or not playerCitizenId then return false end
                return summary.owner == playerCitizenId
            end,
            onSelect = function()
                OpenBusinessManagement(businessId)
            end,
        },
    })

    createInteractionPoint(('qbx_business_clock_%s'):format(businessId), location.clockIn, {
        {
            name = 'qbx_business_clock',
            label = locale('clock_in'),
            icon = 'fas fa-user-clock',
            canInteract = function()
                local summary = getBusiness(businessId)
                return summary and not summary.forSale
            end,
            onSelect = function()
                ToggleClockIn(businessId)
            end,
        },
        {
            name = 'qbx_business_delivery',
            label = locale('start_delivery'),
            icon = 'fas fa-truck',
            canInteract = function()
                local summary = getBusiness(businessId)
                return summary and not summary.forSale and Config.Delivery.enabled
            end,
            onSelect = function()
                StartBusinessDelivery(businessId)
            end,
        },
    })
end

function PurchaseBusiness(businessId)
    local summary = getBusiness(businessId) or lib.callback.await('qbx-businesses:server:getBusinessSummary', false, businessId)
    if not summary or not summary.forSale then
        notify(locale('not_for_sale'), 'error')
        return
    end

    local alert = lib.alertDialog({
        header = locale('buy_business'),
        content = locale('buy_business_desc', summary.purchasePrice),
        centered = true,
        cancel = true,
    })

    if alert ~= 'confirm' then return end

    local success, message = lib.callback.await('qbx-businesses:server:purchaseBusiness', false, businessId)
    notify(message, success and 'success' or 'error')
end

CreateThread(function()
    while not QBX or not QBX.PlayerData or not QBX.PlayerData.citizenid do
        Wait(500)
    end

    playerCitizenId = QBX.PlayerData.citizenid
    TriggerServerEvent('qbx-businesses:server:requestSync')

    for i = 1, #BusinessLocations do
        setupBusinessInteractions(BusinessLocations[i])
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    playerCitizenId = QBX.PlayerData.citizenid
    TriggerServerEvent('qbx-businesses:server:requestSync')
end)

RegisterNetEvent('qbx_core:client:playerLoaded', function()
    playerCitizenId = QBX.PlayerData.citizenid
    TriggerServerEvent('qbx-businesses:server:requestSync')
end)

if Config.Commands.business.enabled then
    RegisterCommand(Config.Commands.business.name, function()
        local owned = lib.callback.await('qbx-businesses:server:getOwnedBusinesses', false)
        if #owned == 0 then
            notify(locale('not_owner'), 'error')
            return
        end

        local options = {}
        for i = 1, #owned do
            local business = owned[i]
            options[#options + 1] = {
                title = business.label,
                description = locale('business_balance', business.balance),
                onSelect = function()
                    OpenBusinessManagement(business.id)
                end,
            }
        end

        lib.registerContext({
            id = 'qbx_businesses_owned_menu',
            title = locale('business_owned'),
            options = options,
        })

        lib.showContext('qbx_businesses_owned_menu')
    end, false)

    TriggerEvent('chat:addSuggestion', '/' .. Config.Commands.business.name, locale('command_help'))
end

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    for businessId in pairs(blips) do
        removeBlip(businessId)
    end
end)
