lib.callback.register('qbx-businesses:server:withdrawMoney', function(source, businessId, amount)
    if not IsBusinessOwner(source, businessId) then
        return false, Locale('not_owner')
    end

    amount = math.floor(tonumber(amount) or 0)
    if amount < Config.MinWithdraw or amount > Config.MaxWithdraw then
        return false, Locale('withdraw_failed')
    end

    local business = GetCachedBusiness(businessId) or RefreshBusinessCache(businessId)
    if not business or business.balance < amount then
        return false, Locale('insufficient_business_funds')
    end

    local added = exports.qbx_core:AddMoney(source, Config.PurchaseMoneyType, amount, 'business-withdraw')
    if not added then
        return false, Locale('withdraw_failed')
    end

    MySQL.update.await('UPDATE player_businesses SET balance = balance - ? WHERE business_id = ?', { amount, businessId })
    RefreshBusinessCache(businessId)
    LogTransaction(businessId, 'withdraw', amount, 'Owner withdrawal', GetCitizenId(source))
    SyncBusinessToClients(businessId)

    return true, Locale('withdraw_success', amount)
end)

lib.callback.register('qbx-businesses:server:depositMoney', function(source, businessId, amount)
    if not IsBusinessOwner(source, businessId) then
        return false, Locale('not_owner')
    end

    amount = math.floor(tonumber(amount) or 0)
    if amount < Config.MinDeposit or amount > Config.MaxDeposit then
        return false, Locale('deposit_failed')
    end

    local removed = exports.qbx_core:RemoveMoney(source, Config.PurchaseMoneyType, amount, 'business-deposit')
    if not removed then
        return false, Locale('insufficient_funds')
    end

    MySQL.update.await('UPDATE player_businesses SET balance = balance + ? WHERE business_id = ?', { amount, businessId })
    RefreshBusinessCache(businessId)
    LogTransaction(businessId, 'deposit', amount, 'Owner deposit', GetCitizenId(source))
    SyncBusinessToClients(businessId)

    return true, Locale('deposit_success', amount)
end)

lib.callback.register('qbx-businesses:server:setItemPrice', function(source, businessId, item, price)
    if not IsBusinessOwner(source, businessId) then
        return false, Locale('not_owner')
    end

    price = math.floor(tonumber(price) or 0)
    if price < 1 or price > 100000 then
        return false, Locale('price_invalid')
    end

    local business = GetCachedBusiness(businessId) or RefreshBusinessCache(businessId)
    if not business or not business.stock[item] then
        return false, Locale('price_invalid')
    end

    MySQL.update.await(
        'UPDATE business_stock SET price = ? WHERE business_id = ? AND item = ?',
        { price, businessId, item }
    )

    RefreshBusinessCache(businessId)
    SyncBusinessToClients(businessId)

    local businessType = GetBusinessType(business.type)
    local label = GetStockItemLabel(businessType, item)

    return true, Locale('price_updated', label, price)
end)
