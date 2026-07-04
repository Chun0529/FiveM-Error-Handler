local function calculateDeliveryCost(businessId)
    local business = GetCachedBusiness(businessId) or RefreshBusinessCache(businessId)
    if not business then return 0 end

    local businessType = GetBusinessType(business.type)
    if not businessType then return Config.Delivery.payoutFromBusiness end

    local totalCost = 0

    for i = 1, #businessType.stock do
        local stockItem = businessType.stock[i]
        totalCost += stockItem.deliveryCost * Config.Delivery.stockPerDelivery
    end

    return math.max(totalCost, Config.Delivery.payoutFromBusiness)
end

lib.callback.register('qbx-businesses:server:startDelivery', function(source, businessId)
    if not Config.Delivery.enabled then
        return false, Locale('delivery_failed')
    end

    if ActiveDeliveries[source] then
        return false, Locale('delivery_in_progress')
    end

    if not IsBusinessEmployee(source, businessId) then
        return false, Locale('not_employee')
    end

    local business = GetCachedBusiness(businessId) or RefreshBusinessCache(businessId)
    local citizenid = GetCitizenId(source)
    local clockedIn = false

    if business and business.owner == citizenid then
        clockedIn = business.ownerClockedIn == true
    elseif business and citizenid then
        local employee = business.employees[citizenid]
        clockedIn = employee and employee.clockedIn or false
    end

    if not clockedIn then
        return false, Locale('not_clocked_in')
    end

    local lastDelivery = DeliveryCooldowns[businessId]
    if lastDelivery and (os.time() - lastDelivery) < Config.Delivery.cooldown then
        return false, Locale('delivery_cooldown')
    end

    local deliveryCost = calculateDeliveryCost(businessId)
    if not business or business.balance < deliveryCost then
        return false, Locale('delivery_no_funds')
    end

    local location = GetBusinessLocation(businessId)
    local businessType = location and GetBusinessType(location.type)
    if not location or not businessType then
        return false, Locale('delivery_failed')
    end

    ActiveDeliveries[source] = {
        businessId = businessId,
        stage = 'pickup',
        deliveryCost = deliveryCost,
    }

    return true, Locale('delivery_started'), {
        pickup = businessType.deliveryPickup,
        dropoff = location.deliverySpawn,
        vehicleModel = Config.Delivery.vehicleModel,
        businessId = businessId,
    }
end)

lib.callback.register('qbx-businesses:server:completeDeliveryPickup', function(source)
    local delivery = ActiveDeliveries[source]
    if not delivery or delivery.stage ~= 'pickup' then
        return false, Locale('delivery_failed')
    end

    delivery.stage = 'return'
    return true, Locale('delivery_return')
end)

lib.callback.register('qbx-businesses:server:completeDelivery', function(source)
    local delivery = ActiveDeliveries[source]
    if not delivery or delivery.stage ~= 'return' then
        return false, Locale('delivery_failed')
    end

    local businessId = delivery.businessId
    local business = GetCachedBusiness(businessId) or RefreshBusinessCache(businessId)
    local businessType = business and GetBusinessType(business.type)

    if not business or not businessType then
        ActiveDeliveries[source] = nil
        return false, Locale('delivery_failed')
    end

    local deliveryCost = delivery.deliveryCost or Config.Delivery.payoutFromBusiness

    MySQL.update.await(
        'UPDATE player_businesses SET balance = balance - ? WHERE business_id = ? AND balance >= ?',
        { deliveryCost, businessId, deliveryCost }
    )

    for i = 1, #businessType.stock do
        local stockItem = businessType.stock[i]
        local addAmount = Config.Delivery.stockPerDelivery

        MySQL.update.await(
            [[
                UPDATE business_stock
                SET quantity = LEAST(quantity + ?, ?)
                WHERE business_id = ? AND item = ?
            ]],
            { addAmount, stockItem.maxStock, businessId, stockItem.item }
        )
    end

    local payout = math.floor(deliveryCost * 0.5)
    exports.qbx_core:AddMoney(source, 'bank', payout, 'business-delivery')

    LogTransaction(
        businessId,
        'delivery',
        deliveryCost,
        ('Stock delivery completed by %s'):format(GetCitizenId(source) or 'unknown'),
        GetCitizenId(source)
    )

    DeliveryCooldowns[businessId] = os.time()
    ActiveDeliveries[source] = nil
    RefreshBusinessCache(businessId)
    SyncBusinessToClients(businessId)

    return true, Locale('delivery_complete')
end)

RegisterNetEvent('qbx-businesses:server:cancelDelivery', function()
    ActiveDeliveries[source] = nil
end)

AddEventHandler('playerDropped', function()
    ActiveDeliveries[source] = nil
end)
