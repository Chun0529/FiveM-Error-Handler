local activeDelivery

local function cleanupDelivery()
    if activeDelivery and activeDelivery.vehicle and DoesEntityExist(activeDelivery.vehicle) then
        DeleteEntity(activeDelivery.vehicle)
    end

    if activeDelivery and activeDelivery.pickupBlip and DoesBlipExist(activeDelivery.pickupBlip) then
        RemoveBlip(activeDelivery.pickupBlip)
    end

    if activeDelivery and activeDelivery.dropoffBlip and DoesBlipExist(activeDelivery.dropoffBlip) then
        RemoveBlip(activeDelivery.dropoffBlip)
    end

    activeDelivery = nil
end

local function createRouteBlip(coords, blipConfig, label)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, blipConfig.sprite)
    SetBlipColour(blip, blipConfig.color)
    SetBlipScale(blip, blipConfig.scale)
    SetBlipRoute(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(label)
    EndTextCommandSetBlipName(blip)
    return blip
end

function StartBusinessDelivery(businessId)
    if activeDelivery then
        lib.notify({ description = locale('delivery_in_progress'), type = 'error' })
        return
    end

    local success, message, data = lib.callback.await('qbx-businesses:server:startDelivery', false, businessId)
    if not success or not data then
        lib.notify({ description = message, type = 'error' })
        return
    end

    lib.notify({ description = message, type = 'inform' })

    local model = joaat(data.vehicleModel)
    lib.requestModel(model)

    local spawn = data.dropoff
    local vehicle = CreateVehicle(model, spawn.x, spawn.y, spawn.z, spawn.w, true, false)
    SetEntityAsMissionEntity(vehicle, true, true)
    SetVehicleOnGroundProperly(vehicle)
    SetModelAsNoLongerNeeded(model)

    TaskWarpPedIntoVehicle(cache.ped, vehicle, -1)

    activeDelivery = {
        businessId = businessId,
        vehicle = vehicle,
        stage = 'pickup',
        pickup = data.pickup,
        dropoff = data.dropoff,
        pickupBlip = createRouteBlip(data.pickup, Config.Delivery.pickupBlip, 'Warehouse Pickup'),
    }

    CreateThread(function()
        while activeDelivery and activeDelivery.stage == 'pickup' do
            local pickupCoords = vec3(activeDelivery.pickup.x, activeDelivery.pickup.y, activeDelivery.pickup.z)
            local distance = #(GetEntityCoords(cache.ped) - pickupCoords)

            if distance <= 8.0 and IsPedInVehicle(cache.ped, activeDelivery.vehicle, false) then
                lib.showTextUI(locale('delivery_pickup'))

                if IsControlJustReleased(0, 38) then
                    lib.hideTextUI()

                    if lib.progressBar({
                        duration = 5000,
                        label = locale('delivery_pickup'),
                        useWhileDead = false,
                        canCancel = true,
                        disable = { car = true, move = true, combat = true },
                    }) then
                        local pickupSuccess, pickupMessage = lib.callback.await(
                            'qbx-businesses:server:completeDeliveryPickup',
                            false
                        )

                        if pickupSuccess then
                            RemoveBlip(activeDelivery.pickupBlip)
                            activeDelivery.pickupBlip = nil
                            activeDelivery.stage = 'return'
                            activeDelivery.dropoffBlip = createRouteBlip(
                                vec3(activeDelivery.dropoff.x, activeDelivery.dropoff.y, activeDelivery.dropoff.z),
                                Config.Delivery.dropoffBlip,
                                'Business Dropoff'
                            )

                            lib.notify({ description = pickupMessage, type = 'success' })
                        else
                            lib.notify({ description = pickupMessage, type = 'error' })
                            TriggerServerEvent('qbx-businesses:server:cancelDelivery')
                            cleanupDelivery()
                        end
                    end
                end
            else
                lib.hideTextUI()
            end

            Wait(0)
        end
    end)

    CreateThread(function()
        while activeDelivery and activeDelivery.stage == 'return' do
            local dropoffCoords = vec3(activeDelivery.dropoff.x, activeDelivery.dropoff.y, activeDelivery.dropoff.z)
            local distance = #(GetEntityCoords(cache.ped) - dropoffCoords)

            if distance <= 8.0 and IsPedInVehicle(cache.ped, activeDelivery.vehicle, false) then
                lib.showTextUI(locale('delivery_return'))

                if IsControlJustReleased(0, 38) then
                    lib.hideTextUI()

                    if lib.progressBar({
                        duration = 5000,
                        label = locale('delivery_return'),
                        useWhileDead = false,
                        canCancel = true,
                        disable = { car = true, move = true, combat = true },
                    }) then
                        local completeSuccess, completeMessage = lib.callback.await(
                            'qbx-businesses:server:completeDelivery',
                            false
                        )

                        lib.notify({
                            description = completeMessage,
                            type = completeSuccess and 'success' or 'error',
                        })

                        cleanupDelivery()
                    end
                end
            else
                lib.hideTextUI()
            end

            Wait(0)
        end
    end)
end

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    cleanupDelivery()
end)
