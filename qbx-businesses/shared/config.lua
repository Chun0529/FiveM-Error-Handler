Config = {}

Config.Debug = false

-- Money account used when players buy a business or shop items
Config.PurchaseMoneyType = 'bank' -- 'cash' | 'bank'

-- How customers pay at the register
Config.ShopMoneyType = 'cash' -- 'cash' | 'bank'

-- Percentage of each sale kept as business profit (rest covers supply cost simulation)
Config.ProfitMargin = 0.65

-- Boss can withdraw/deposit business funds at the management terminal
Config.MinWithdraw = 1
Config.MaxWithdraw = 50000
Config.MinDeposit = 1
Config.MaxDeposit = 50000

-- Employee wages paid from the business balance every interval while clocked in
Config.EmployeeWage = {
    enabled = true,
    amount = 75,
    interval = 15 * 60 * 1000, -- 15 minutes
}

-- Stock delivery missions
Config.Delivery = {
    enabled = true,
    stockPerDelivery = 25,
    payoutFromBusiness = 150, -- deducted from business balance, paid to employee
    vehicleModel = 'speedo',
    pickupBlip = { sprite = 478, color = 5, scale = 0.8 },
    dropoffBlip = { sprite = 52, color = 2, scale = 0.8 },
    cooldown = 5 * 60, -- seconds between deliveries per business
}

-- Interaction settings
Config.UseOxTarget = true
Config.InteractionDistance = 2.0

-- Map blips for businesses
Config.ShowBlips = true
Config.ForSaleBlip = { sprite = 475, color = 5, scale = 0.7 }
Config.OwnedBlip = { sprite = 475, color = 2, scale = 0.7 }

-- Commands (set enabled = false to disable)
Config.Commands = {
    business = { enabled = true, name = 'business' },
}

-- Maximum employees per business
Config.MaxEmployees = 8

-- Default stock initialization when a business is purchased
Config.InitialStockMultiplier = 0.5 -- 50% of max stock on purchase
