lib.callback.register('qbx-businesses:server:purchaseItem', function(source, businessId, item, quantity)
    quantity = math.floor(tonumber(quantity) or 1)
    if quantity < 1 then
        return false, Locale('purchase_item_failed')
    end

    local business = GetCachedBusiness(businessId) or RefreshBusinessCache(businessId)
    if not business or not business.stock[item] then
        return false, Locale('purchase_item_failed')
    end

    local stockEntry = business.stock[item]
    if stockEntry.quantity < quantity then
        return false, Locale('out_of_stock')
    end

    local totalPrice = stockEntry.price * quantity
    local removed = exports.qbx_core:RemoveMoney(source, Config.ShopMoneyType, totalPrice, 'business-shop')
    if not removed then
        return false, Locale('insufficient_funds')
    end

    if GetResourceState('ox_inventory') == 'started' then
        if not exports.ox_inventory:CanCarryItem(source, item, quantity) then
            exports.qbx_core:AddMoney(source, Config.ShopMoneyType, totalPrice, 'business-shop-refund')
            return false, Locale('inventory_full')
        end

        local added = exports.ox_inventory:AddItem(source, item, quantity)
        if not added then
            exports.qbx_core:AddMoney(source, Config.ShopMoneyType, totalPrice, 'business-shop-refund')
            return false, Locale('inventory_full')
        end
    end

    local businessIncome = math.floor(totalPrice * Config.ProfitMargin)

    MySQL.update.await(
        'UPDATE business_stock SET quantity = quantity - ? WHERE business_id = ? AND item = ?',
        { quantity, businessId, item }
    )

    MySQL.update.await(
        'UPDATE player_businesses SET balance = balance + ? WHERE business_id = ?',
        { businessIncome, businessId }
    )

    local citizenid = GetCitizenId(source)
    LogTransaction(
        businessId,
        'sale',
        businessIncome,
        ('Sold %sx %s'):format(quantity, item),
        citizenid
    )

    RefreshBusinessCache(businessId)
    SyncBusinessToClients(businessId)

    local businessType = GetBusinessType(business.type)
    local label = GetStockItemLabel(businessType, item)

    return true, Locale('purchase_item_success', quantity, label, totalPrice)
end)

lib.callback.register('qbx-businesses:server:getShopItems', function(source, businessId)
    local business = GetCachedBusiness(businessId) or RefreshBusinessCache(businessId)
    if not business then return {} end

    local businessType = GetBusinessType(business.type)
    local items = {}

    for itemName, stockEntry in pairs(business.stock) do
        items[#items + 1] = {
            item = itemName,
            label = GetStockItemLabel(businessType, itemName),
            quantity = stockEntry.quantity,
            price = stockEntry.price,
        }
    end

    table.sort(items, function(a, b)
        return a.label < b.label
    end)

    return items
end)
