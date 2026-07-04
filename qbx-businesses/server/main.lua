lib.callback.register('qbx-businesses:server:getOwnedBusinesses', function(source)
    local citizenid = GetCitizenId(source)
    if not citizenid then return {} end

    local owned = {}

    for i = 1, #BusinessLocations do
        local business = GetCachedBusiness(BusinessLocations[i].id) or RefreshBusinessCache(BusinessLocations[i].id)
        if business and business.owner == citizenid then
            owned[#owned + 1] = GetBusinessSummary(BusinessLocations[i].id)
        end
    end

    return owned
end)

lib.callback.register('qbx-businesses:server:getTransactions', function(source, businessId, limit)
    if not IsBusinessManager(source, businessId) then
        return {}
    end

    return MySQL.query.await(
        'SELECT type, amount, description, citizenid, created_at FROM business_transactions WHERE business_id = ? ORDER BY id DESC LIMIT ?',
        { businessId, limit or 15 }
    ) or {}
end)
