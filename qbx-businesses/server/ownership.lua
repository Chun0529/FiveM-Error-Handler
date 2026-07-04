lib.callback.register('qbx-businesses:server:purchaseBusiness', function(source, businessId)
    local location = GetBusinessLocation(businessId)
    if not location then
        return false, Locale('purchase_failed')
    end

    local business = GetCachedBusiness(businessId) or RefreshBusinessCache(businessId)
    if not business then
        return false, Locale('purchase_failed')
    end

    if business.owner then
        return false, Locale('already_owned')
    end

    local citizenid = GetCitizenId(source)
    if not citizenid then
        return false, Locale('purchase_failed')
    end

    local price = GetBusinessPurchasePrice(location)
    local removed = exports.qbx_core:RemoveMoney(source, Config.PurchaseMoneyType, price, 'business-purchase')
    if not removed then
        return false, Locale('insufficient_funds')
    end

    MySQL.update.await(
        'UPDATE player_businesses SET owner_citizenid = ?, balance = ?, purchased_at = NOW() WHERE business_id = ?',
        { citizenid, math.floor(price * 0.1), businessId }
    )

    local businessType = GetBusinessType(location.type)
    if businessType then
        InitializeBusinessStock(businessId, businessType)
    else
        RefreshBusinessCache(businessId)
    end

    LogTransaction(businessId, 'purchase', price, ('Business purchased by %s'):format(citizenid), citizenid)
    SyncBusinessToClients(businessId)

    return true, Locale('purchase_success', location.label, price)
end)
