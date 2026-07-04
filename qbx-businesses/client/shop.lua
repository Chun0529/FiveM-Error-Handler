function OpenBusinessShop(businessId)
    local items = lib.callback.await('qbx-businesses:server:getShopItems', false, businessId)

    if not items or #items == 0 then
        lib.notify({ description = locale('shop_empty'), type = 'error' })
        return
    end

    local summary = GetLocalBusiness(businessId)
    local options = {}

    for i = 1, #items do
        local item = items[i]
        options[#options + 1] = {
            title = item.label,
            description = locale('stock_quantity', item.label, item.quantity, item.price),
            disabled = item.quantity <= 0,
            onSelect = function()
                local input = lib.inputDialog(item.label, {
                    {
                        type = 'number',
                        label = 'Quantity',
                        default = 1,
                        min = 1,
                        max = math.max(item.quantity, 1),
                    },
                })

                if not input then return end

                local quantity = math.floor(input[1] or 1)
                local success, message = lib.callback.await(
                    'qbx-businesses:server:purchaseItem',
                    false,
                    businessId,
                    item.item,
                    quantity
                )

                lib.notify({
                    description = message,
                    type = success and 'success' or 'error',
                })

                if success then
                    OpenBusinessShop(businessId)
                end
            end,
        }
    end

    lib.registerContext({
        id = 'qbx_businesses_shop_' .. businessId,
        title = summary and summary.label or 'Shop',
        options = options,
    })

    lib.showContext('qbx_businesses_shop_' .. businessId)
end
