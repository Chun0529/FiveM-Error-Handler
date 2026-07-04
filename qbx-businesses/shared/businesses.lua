---@class BusinessStockItem
---@field item string ox_inventory item name
---@field label string display label
---@field defaultPrice number
---@field maxStock number
---@field deliveryCost number cost deducted from business per restock unit

---@class BusinessType
---@field label string
---@field description string
---@field defaultPurchasePrice number
---@field stock BusinessStockItem[]
---@field deliveryPickup vector4 warehouse pickup location

BusinessTypes = {
    ['convenience_store'] = {
        label = 'Convenience Store',
        description = 'A neighborhood shop selling snacks and drinks.',
        defaultPurchasePrice = 75000,
        deliveryPickup = vector4(849.41, -902.53, 25.25, 90.0),
        stock = {
            { item = 'water_bottle', label = 'Water', defaultPrice = 3, maxStock = 100, deliveryCost = 1 },
            { item = 'sandwich', label = 'Sandwich', defaultPrice = 8, maxStock = 50, deliveryCost = 3 },
            { item = 'twerks_candy', label = 'Candy Bar', defaultPrice = 4, maxStock = 80, deliveryCost = 1 },
            { item = 'kurkakola', label = 'Cola', defaultPrice = 5, maxStock = 80, deliveryCost = 2 },
        },
    },
    ['liquor_store'] = {
        label = 'Liquor Store',
        description = 'Sells alcoholic beverages and mixers.',
        defaultPurchasePrice = 95000,
        deliveryPickup = vector4(-43.02, -1748.64, 29.42, 50.0),
        stock = {
            { item = 'beer', label = 'Beer', defaultPrice = 7, maxStock = 100, deliveryCost = 2 },
            { item = 'whiskey', label = 'Whiskey', defaultPrice = 15, maxStock = 60, deliveryCost = 5 },
            { item = 'vodka', label = 'Vodka', defaultPrice = 14, maxStock = 60, deliveryCost = 5 },
            { item = 'wine', label = 'Wine', defaultPrice = 12, maxStock = 50, deliveryCost = 4 },
        },
    },
    ['hardware_store'] = {
        label = 'Hardware Store',
        description = 'Tools and supplies for handy players.',
        defaultPurchasePrice = 120000,
        deliveryPickup = vector4(2747.71, 3472.79, 55.67, 250.0),
        stock = {
            { item = 'lockpick', label = 'Lockpick', defaultPrice = 25, maxStock = 30, deliveryCost = 10 },
            { item = 'screwdriverset', label = 'Screwdriver Set', defaultPrice = 45, maxStock = 20, deliveryCost = 18 },
            { item = 'repairkit', label = 'Repair Kit', defaultPrice = 75, maxStock = 15, deliveryCost = 30 },
            { item = 'phone', label = 'Phone', defaultPrice = 150, maxStock = 10, deliveryCost = 60 },
        },
    },
}

---@class BusinessLocation
---@field id string unique identifier
---@field type string key in BusinessTypes
---@field label string display name override
---@field purchasePrice number? overrides type default
---@field shop vector3 customer purchase zone
---@field management vector3 boss terminal
---@field clockIn vector3 employee clock-in point
---@field deliverySpawn vector4 vehicle spawn for deliveries
---@field blip vector3 map blip position

BusinessLocations = {
    {
        id = '247_senora',
        type = 'convenience_store',
        label = '24/7 Senora Freeway',
        shop = vector3(2678.29, 3280.64, 55.24),
        management = vector3(2673.68, 3286.74, 55.24),
        clockIn = vector3(2675.91, 3282.59, 55.24),
        deliverySpawn = vector4(2682.45, 3295.12, 55.24, 240.0),
        blip = vector3(2678.29, 3280.64, 55.24),
    },
    {
        id = '247_innocence',
        type = 'convenience_store',
        label = '24/7 Innocence Blvd',
        purchasePrice = 85000,
        shop = vector3(25.74, -1347.32, 29.50),
        management = vector3(29.47, -1339.62, 29.50),
        clockIn = vector3(28.21, -1345.58, 29.50),
        deliverySpawn = vector4(15.82, -1342.88, 29.32, 180.0),
        blip = vector3(25.74, -1347.32, 29.50),
    },
    {
        id = 'liquor_vinewood',
        type = 'liquor_store',
        label = 'Rob\'s Liquor - Vinewood',
        shop = vector3(-1222.03, -908.32, 12.33),
        management = vector3(-1219.38, -915.87, 11.33),
        clockIn = vector3(-1220.85, -910.52, 12.33),
        deliverySpawn = vector4(-1234.56, -902.11, 12.04, 35.0),
        blip = vector3(-1222.03, -908.32, 12.33),
    },
    {
        id = 'hardware_paleto',
        type = 'hardware_store',
        label = 'You Tool - Paleto',
        shop = vector3(2747.71, 3472.79, 55.67),
        management = vector3(2744.22, 3467.81, 55.67),
        clockIn = vector3(2746.15, 3470.42, 55.67),
        deliverySpawn = vector4(2755.88, 3461.33, 55.67, 340.0),
        blip = vector3(2747.71, 3472.79, 55.67),
    },
}

---@param businessId string
---@return BusinessLocation?
function GetBusinessLocation(businessId)
    for i = 1, #BusinessLocations do
        if BusinessLocations[i].id == businessId then
            return BusinessLocations[i]
        end
    end
end

---@param businessType string
---@return BusinessType?
function GetBusinessType(businessType)
    return BusinessTypes[businessType]
end

---@param location BusinessLocation
---@return number
function GetBusinessPurchasePrice(location)
    if location.purchasePrice then
        return location.purchasePrice
    end

    local businessType = GetBusinessType(location.type)
    return businessType and businessType.defaultPurchasePrice or 100000
end
