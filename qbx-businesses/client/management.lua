local function openFinancesMenu(businessId, summary)
    lib.registerContext({
        id = 'qbx_businesses_finances_' .. businessId,
        title = locale('manage_finances'),
        menu = 'qbx_businesses_manage_' .. businessId,
        options = {
            {
                title = locale('business_balance', summary.balance),
                icon = 'wallet',
                readOnly = true,
            },
            {
                title = locale('withdraw_money'),
                icon = 'money-bill-transfer',
                onSelect = function()
                    local input = lib.inputDialog(locale('withdraw_money'), {
                        {
                            type = 'number',
                            label = 'Amount',
                            min = Config.MinWithdraw,
                            max = Config.MaxWithdraw,
                        },
                    })

                    if not input then return end

                    local success, message = lib.callback.await(
                        'qbx-businesses:server:withdrawMoney',
                        false,
                        businessId,
                        input[1]
                    )

                    lib.notify({ description = message, type = success and 'success' or 'error' })

                    if success then
                        OpenBusinessManagement(businessId)
                    end
                end,
            },
            {
                title = locale('deposit_money'),
                icon = 'piggy-bank',
                onSelect = function()
                    local input = lib.inputDialog(locale('deposit_money'), {
                        {
                            type = 'number',
                            label = 'Amount',
                            min = Config.MinDeposit,
                            max = Config.MaxDeposit,
                        },
                    })

                    if not input then return end

                    local success, message = lib.callback.await(
                        'qbx-businesses:server:depositMoney',
                        false,
                        businessId,
                        input[1]
                    )

                    lib.notify({ description = message, type = success and 'success' or 'error' })

                    if success then
                        OpenBusinessManagement(businessId)
                    end
                end,
            },
            {
                title = locale('view_transactions'),
                icon = 'receipt',
                onSelect = function()
                    local transactions = lib.callback.await('qbx-businesses:server:getTransactions', false, businessId, 15)
                    local txOptions = {}

                    if #transactions == 0 then
                        txOptions[1] = {
                            title = locale('no_transactions'),
                            readOnly = true,
                        }
                    else
                        for i = 1, #transactions do
                            local tx = transactions[i]
                            txOptions[#txOptions + 1] = {
                                title = ('%s - $%s'):format(tx.type, tx.amount),
                                description = tx.description or '',
                                readOnly = true,
                            }
                        end
                    end

                    lib.registerContext({
                        id = 'qbx_businesses_transactions_' .. businessId,
                        title = locale('view_transactions'),
                        menu = 'qbx_businesses_finances_' .. businessId,
                        options = txOptions,
                    })

                    lib.showContext('qbx_businesses_transactions_' .. businessId)
                end,
            },
        },
    })

    lib.showContext('qbx_businesses_finances_' .. businessId)
end

local function openStockMenu(businessId, summary)
    local businessType = GetBusinessType(summary.type)
    local options = {}

    for itemName, stockEntry in pairs(summary.stock) do
        local label = itemName
        if businessType then
            for i = 1, #businessType.stock do
                if businessType.stock[i].item == itemName then
                    label = businessType.stock[i].label
                    break
                end
            end
        end

        options[#options + 1] = {
            title = locale('stock_quantity', label, stockEntry.quantity, stockEntry.price),
            icon = 'box',
            onSelect = function()
                local input = lib.inputDialog(locale('set_price', label), {
                    {
                        type = 'number',
                        label = 'Price',
                        default = stockEntry.price,
                        min = 1,
                        max = 100000,
                    },
                })

                if not input then return end

                local success, message = lib.callback.await(
                    'qbx-businesses:server:setItemPrice',
                    false,
                    businessId,
                    itemName,
                    input[1]
                )

                lib.notify({ description = message, type = success and 'success' or 'error' })

                if success then
                    OpenBusinessManagement(businessId)
                end
            end,
        }
    end

    lib.registerContext({
        id = 'qbx_businesses_stock_' .. businessId,
        title = locale('manage_stock'),
        menu = 'qbx_businesses_manage_' .. businessId,
        options = options,
    })

    lib.showContext('qbx_businesses_stock_' .. businessId)
end

local function openEmployeesMenu(businessId, summary)
    local options = {
        {
            title = locale('hire_employee'),
            icon = 'user-plus',
            onSelect = function()
                local nearbyPlayers = lib.getNearbyPlayers(GetEntityCoords(cache.ped), 5.0, true)
                local hireOptions = {}

                for i = 1, #nearbyPlayers do
                    local player = nearbyPlayers[i]
                    if player.id ~= cache.serverId then
                        hireOptions[#hireOptions + 1] = {
                            title = ('Player %s'):format(player.id),
                            onSelect = function()
                                local success, message = lib.callback.await(
                                    'qbx-businesses:server:hireEmployee',
                                    false,
                                    businessId,
                                    player.id
                                )

                                lib.notify({ description = message, type = success and 'success' or 'error' })

                                if success then
                                    OpenBusinessManagement(businessId)
                                end
                            end,
                        }
                    end
                end

                if #hireOptions == 0 then
                    lib.notify({ description = locale('nearby_no_players'), type = 'error' })
                    return
                end

                lib.registerContext({
                    id = 'qbx_businesses_hire_' .. businessId,
                    title = locale('hire_employee'),
                    menu = 'qbx_businesses_employees_' .. businessId,
                    options = hireOptions,
                })

                lib.showContext('qbx_businesses_hire_' .. businessId)
            end,
        },
    }

    for citizenid, employee in pairs(summary.employees) do
        local status = employee.clockedIn and locale('status_clocked_in') or locale('status_clocked_out')
        local role = employee.role == 'manager' and locale('role_manager') or locale('role_employee')

        options[#options + 1] = {
            title = locale('employee_row', citizenid, role, status),
            icon = 'user',
            onSelect = function()
                lib.registerContext({
                    id = 'qbx_businesses_employee_actions_' .. citizenid,
                    title = citizenid,
                    menu = 'qbx_businesses_employees_' .. businessId,
                    options = {
                        {
                            title = 'Promote / Demote',
                            icon = 'user-gear',
                            onSelect = function()
                                lib.callback.await('qbx-businesses:server:promoteEmployee', false, businessId, citizenid)
                                OpenBusinessManagement(businessId)
                            end,
                        },
                        {
                            title = locale('fire_employee'),
                            icon = 'user-minus',
                            onSelect = function()
                                local success, message = lib.callback.await(
                                    'qbx-businesses:server:fireEmployee',
                                    false,
                                    businessId,
                                    citizenid
                                )

                                lib.notify({ description = message, type = success and 'success' or 'error' })

                                if success then
                                    OpenBusinessManagement(businessId)
                                end
                            end,
                        },
                    },
                })

                lib.showContext('qbx_businesses_employee_actions_' .. citizenid)
            end,
        }
    end

    lib.registerContext({
        id = 'qbx_businesses_employees_' .. businessId,
        title = locale('manage_employees'),
        menu = 'qbx_businesses_manage_' .. businessId,
        options = options,
    })

    lib.showContext('qbx_businesses_employees_' .. businessId)
end

function OpenBusinessManagement(businessId)
    local summary = lib.callback.await('qbx-businesses:server:getBusinessSummary', false, businessId)
    if not summary or summary.forSale then
        lib.notify({ description = locale('not_owner'), type = 'error' })
        return
    end

    lib.registerContext({
        id = 'qbx_businesses_manage_' .. businessId,
        title = summary.label,
        options = {
            {
                title = locale('manage_finances'),
                description = locale('business_balance', summary.balance),
                icon = 'wallet',
                onSelect = function()
                    openFinancesMenu(businessId, summary)
                end,
            },
            {
                title = locale('manage_stock'),
                icon = 'boxes-stacked',
                onSelect = function()
                    openStockMenu(businessId, summary)
                end,
            },
            {
                title = locale('manage_employees'),
                icon = 'users',
                onSelect = function()
                    openEmployeesMenu(businessId, summary)
                end,
            },
            {
                title = locale('manage_delivery'),
                description = locale('start_delivery_desc'),
                icon = 'truck',
                disabled = not Config.Delivery.enabled,
                onSelect = function()
                    StartBusinessDelivery(businessId)
                end,
            },
        },
    })

    lib.showContext('qbx_businesses_manage_' .. businessId)
end
