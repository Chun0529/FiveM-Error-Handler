local locale = lib.locale()

---@type table<string, table>
BusinessCache = {}

---@type table<string, number>
DeliveryCooldowns = {}

---@type table<number, { businessId: string, stage: string }>
ActiveDeliveries = {}

local function debugPrint(...)
    if Config.Debug then
        print('[qbx-businesses]', ...)
    end
end

function DebugPrint(...)
    debugPrint(...)
end

function Notify(source, message, notifyType)
    exports.qbx_core:Notify(source, message, notifyType or 'inform')
end

function Locale(key, ...)
    return locale(key, ...)
end

---@param citizenid string
---@return Player?
function GetPlayerByCitizenId(citizenid)
    return exports.qbx_core:GetPlayerByCitizenId(citizenid) or exports.qbx_core:GetOfflinePlayer(citizenid)
end

---@param source number
---@return Player?
function GetPlayer(source)
    return exports.qbx_core:GetPlayer(source)
end

---@param source number
---@return string?
function GetCitizenId(source)
    local player = GetPlayer(source)
    return player and player.PlayerData.citizenid
end

---@param businessId string
---@return table?
function GetCachedBusiness(businessId)
    return BusinessCache[businessId]
end

---@param row table
---@return table
local function buildBusinessFromRow(row)
    return {
        id = row.business_id,
        type = row.business_type,
        owner = row.owner_citizenid,
        balance = row.balance,
        purchasedAt = row.purchased_at,
        stock = {},
        employees = {},
    }
end

function LoadBusinessStock(businessId)
    local stockRows = MySQL.query.await('SELECT item, quantity, price FROM business_stock WHERE business_id = ?', { businessId }) or {}
    local stock = {}

    for i = 1, #stockRows do
        local row = stockRows[i]
        stock[row.item] = {
            quantity = row.quantity,
            price = row.price,
        }
    end

    return stock
end

function LoadBusinessEmployees(businessId)
    local employeeRows = MySQL.query.await(
        'SELECT citizenid, role, clocked_in FROM business_employees WHERE business_id = ?',
        { businessId }
    ) or {}

    local employees = {}

    for i = 1, #employeeRows do
        local row = employeeRows[i]
        employees[row.citizenid] = {
            role = row.role,
            clockedIn = row.clocked_in == 1,
        }
    end

    return employees
end

function RefreshBusinessCache(businessId)
    local row = MySQL.single.await('SELECT * FROM player_businesses WHERE business_id = ?', { businessId })
    if not row then return end

    local business = buildBusinessFromRow(row)
    business.stock = LoadBusinessStock(businessId)
    business.employees = LoadBusinessEmployees(businessId)
    BusinessCache[businessId] = business

    return business
end

function EnsureBusinessRecord(location)
    local existing = MySQL.single.await('SELECT business_id FROM player_businesses WHERE business_id = ?', { location.id })
    if existing then
        return RefreshBusinessCache(location.id)
    end

    MySQL.insert.await('INSERT INTO player_businesses (business_id, business_type) VALUES (?, ?)', {
        location.id,
        location.type,
    })

    local businessType = GetBusinessType(location.type)
    if businessType then
        for i = 1, #businessType.stock do
            local stockItem = businessType.stock[i]
            MySQL.insert.await(
                'INSERT INTO business_stock (business_id, item, quantity, price) VALUES (?, ?, ?, ?)',
                { location.id, stockItem.item, 0, stockItem.defaultPrice }
            )
        end
    end

    return RefreshBusinessCache(location.id)
end

function InitializeBusinessStock(businessId, businessType)
    for i = 1, #businessType.stock do
        local stockItem = businessType.stock[i]
        local startingQuantity = math.floor(stockItem.maxStock * Config.InitialStockMultiplier)

        MySQL.update.await(
            'UPDATE business_stock SET quantity = ?, price = ? WHERE business_id = ? AND item = ?',
            { startingQuantity, stockItem.defaultPrice, businessId, stockItem.item }
        )
    end

    RefreshBusinessCache(businessId)
end

function LogTransaction(businessId, txType, amount, description, citizenid)
    MySQL.insert.await(
        'INSERT INTO business_transactions (business_id, type, amount, description, citizenid) VALUES (?, ?, ?, ?, ?)',
        { businessId, txType, amount, description, citizenid }
    )
end

function GetBusinessSummary(businessId)
    local business = GetCachedBusiness(businessId) or RefreshBusinessCache(businessId)
    if not business then return end

    local location = GetBusinessLocation(businessId)
    local businessType = GetBusinessType(business.type)

    return {
        id = business.id,
        type = business.type,
        label = location and location.label or businessId,
        owner = business.owner,
        balance = business.balance,
        forSale = business.owner == nil,
        purchasePrice = location and GetBusinessPurchasePrice(location) or 0,
        stock = business.stock,
        employees = business.employees,
        typeLabel = businessType and businessType.label or business.type,
    }
end

function SyncBusinessToClients(businessId)
    local summary = GetBusinessSummary(businessId)
    if summary then
        TriggerClientEvent('qbx-businesses:client:syncBusiness', -1, summary)
    end
end

function SyncAllBusinessesToPlayer(source)
    local summaries = {}

    for i = 1, #BusinessLocations do
        local summary = GetBusinessSummary(BusinessLocations[i].id)
        if summary then
            summaries[#summaries + 1] = summary
        end
    end

    TriggerClientEvent('qbx-businesses:client:syncAllBusinesses', source, summaries)
end

function IsBusinessOwner(source, businessId)
    local citizenid = GetCitizenId(source)
    if not citizenid then return false end

    local business = GetCachedBusiness(businessId) or RefreshBusinessCache(businessId)
    return business and business.owner == citizenid
end

function IsBusinessEmployee(source, businessId)
    local citizenid = GetCitizenId(source)
    if not citizenid then return false end

    if IsBusinessOwner(source, businessId) then
        return true
    end

    local business = GetCachedBusiness(businessId) or RefreshBusinessCache(businessId)
    return business and business.employees[citizenid] ~= nil
end

function IsBusinessManager(source, businessId)
    local citizenid = GetCitizenId(source)
    if not citizenid then return false end

    if IsBusinessOwner(source, businessId) then
        return true
    end

    local business = GetCachedBusiness(businessId) or RefreshBusinessCache(businessId)
    local employee = business and business.employees[citizenid]
    return employee and employee.role == 'manager'
end

function GetStockItemLabel(businessType, itemName)
    if not businessType then return itemName end

    for i = 1, #businessType.stock do
        if businessType.stock[i].item == itemName then
            return businessType.stock[i].label
        end
    end

    return itemName
end

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    for i = 1, #BusinessLocations do
        EnsureBusinessRecord(BusinessLocations[i])
    end

    debugPrint('Loaded', #BusinessLocations, 'business locations')
end)

lib.callback.register('qbx-businesses:server:getBusinessSummary', function(source, businessId)
    return GetBusinessSummary(businessId)
end)

lib.callback.register('qbx-businesses:server:getAllBusinesses', function(source)
    local summaries = {}

    for i = 1, #BusinessLocations do
        summaries[#summaries + 1] = GetBusinessSummary(BusinessLocations[i].id)
    end

    return summaries
end)

RegisterNetEvent('qbx-businesses:server:requestSync', function()
    SyncAllBusinessesToPlayer(source)
end)

AddEventHandler('QBCore:Server:PlayerLoaded', function(player)
    SyncAllBusinessesToPlayer(player.PlayerData.source)
end)

AddEventHandler('qbx_core:server:playerLoaded', function(player)
    SyncAllBusinessesToPlayer(player.PlayerData.source)
end)
