local function countEmployees(business)
    local total = 0
    for _ in pairs(business.employees) do
        total += 1
    end
    return total
end

lib.callback.register('qbx-businesses:server:hireEmployee', function(source, businessId, targetSource)
    if not IsBusinessOwner(source, businessId) then
        return false, Locale('not_owner')
    end

    local business = GetCachedBusiness(businessId) or RefreshBusinessCache(businessId)
    if not business then
        return false, Locale('employee_already_hired')
    end

    if countEmployees(business) >= Config.MaxEmployees then
        return false, Locale('employee_limit')
    end

    local targetPlayer = GetPlayer(targetSource)
    if not targetPlayer then
        return false, Locale('nearby_no_players')
    end

    local targetCitizenId = targetPlayer.PlayerData.citizenid
    if business.owner == targetCitizenId or business.employees[targetCitizenId] then
        return false, Locale('employee_already_hired')
    end

    MySQL.insert.await(
        'INSERT INTO business_employees (business_id, citizenid, role) VALUES (?, ?, ?)',
        { businessId, targetCitizenId, 'employee' }
    )

    RefreshBusinessCache(businessId)
    SyncBusinessToClients(businessId)

    local targetName = targetPlayer.PlayerData.charinfo.firstname .. ' ' .. targetPlayer.PlayerData.charinfo.lastname
    return true, Locale('employee_hired', targetName)
end)

lib.callback.register('qbx-businesses:server:fireEmployee', function(source, businessId, employeeCitizenId)
    if not IsBusinessOwner(source, businessId) then
        return false, Locale('not_owner')
    end

    local business = GetCachedBusiness(businessId) or RefreshBusinessCache(businessId)
    if not business or not business.employees[employeeCitizenId] then
        return false, Locale('employee_fired')
    end

    MySQL.update.await(
        'DELETE FROM business_employees WHERE business_id = ? AND citizenid = ?',
        { businessId, employeeCitizenId }
    )

    RefreshBusinessCache(businessId)
    SyncBusinessToClients(businessId)

    local employee = GetPlayerByCitizenId(employeeCitizenId)
    local employeeName = employeeCitizenId

    if employee and employee.PlayerData and employee.PlayerData.charinfo then
        employeeName = employee.PlayerData.charinfo.firstname .. ' ' .. employee.PlayerData.charinfo.lastname
    end

    return true, Locale('employee_fired', employeeName)
end)

lib.callback.register('qbx-businesses:server:promoteEmployee', function(source, businessId, employeeCitizenId)
    if not IsBusinessOwner(source, businessId) then
        return false, Locale('not_owner')
    end

    local business = GetCachedBusiness(businessId) or RefreshBusinessCache(businessId)
    if not business or not business.employees[employeeCitizenId] then
        return false, Locale('not_employee')
    end

    local newRole = business.employees[employeeCitizenId].role == 'manager' and 'employee' or 'manager'

    MySQL.update.await(
        'UPDATE business_employees SET role = ? WHERE business_id = ? AND citizenid = ?',
        { newRole, businessId, employeeCitizenId }
    )

    RefreshBusinessCache(businessId)
    SyncBusinessToClients(businessId)

    return true, newRole
end)

lib.callback.register('qbx-businesses:server:toggleClock', function(source, businessId)
    if not IsBusinessEmployee(source, businessId) then
        return false, Locale('not_employee')
    end

    local citizenid = GetCitizenId(source)
    if not citizenid then
        return false, Locale('not_employee')
    end

    local business = GetCachedBusiness(businessId) or RefreshBusinessCache(businessId)
    if not business then
        return false, Locale('not_employee')
    end

    local location = GetBusinessLocation(businessId)
    local isOwner = business.owner == citizenid
    local employee = business.employees[citizenid]
    local currentlyClockedIn = isOwner or (employee and employee.clockedIn)

    if isOwner then
        -- Owners use metadata-style virtual clock state on the business cache
        business.ownerClockedIn = not business.ownerClockedIn
        currentlyClockedIn = business.ownerClockedIn
    else
        if not employee then
            return false, Locale('not_employee')
        end

        local newState = employee.clockedIn and 0 or 1
        MySQL.update.await(
            'UPDATE business_employees SET clocked_in = ? WHERE business_id = ? AND citizenid = ?',
            { newState, businessId, citizenid }
        )

        currentlyClockedIn = newState == 1
    end

    RefreshBusinessCache(businessId)

    if isOwner then
        BusinessCache[businessId].ownerClockedIn = currentlyClockedIn
    end

    SyncBusinessToClients(businessId)

    if currentlyClockedIn then
        return true, Locale('clocked_in', location and location.label or businessId), true
    end

    return true, Locale('clocked_out', location and location.label or businessId), false
end)

lib.callback.register('qbx-businesses:server:isClockedIn', function(source, businessId)
    local citizenid = GetCitizenId(source)
    if not citizenid then return false end

    local business = GetCachedBusiness(businessId) or RefreshBusinessCache(businessId)
    if not business then return false end

    if business.owner == citizenid then
        return business.ownerClockedIn == true
    end

    local employee = business.employees[citizenid]
    return employee and employee.clockedIn or false
end)

if Config.EmployeeWage.enabled then
    CreateThread(function()
        while true do
            Wait(Config.EmployeeWage.interval)

            for businessId, business in pairs(BusinessCache) do
                if business.balance >= Config.EmployeeWage.amount then
                    for citizenid, employee in pairs(business.employees) do
                        if employee.clockedIn then
                            local targetSource = exports.qbx_core:GetSource(citizenid)
                            if targetSource and targetSource > 0 then
                                local paid = exports.qbx_core:AddMoney(
                                    targetSource,
                                    'bank',
                                    Config.EmployeeWage.amount,
                                    'business-wage'
                                )

                                if paid then
                                    MySQL.update.await(
                                        'UPDATE player_businesses SET balance = balance - ? WHERE business_id = ?',
                                        { Config.EmployeeWage.amount, businessId }
                                    )

                                    LogTransaction(
                                        businessId,
                                        'wage',
                                        Config.EmployeeWage.amount,
                                        ('Wage paid to %s'):format(citizenid),
                                        citizenid
                                    )

                                    local location = GetBusinessLocation(businessId)
                                    Notify(
                                        targetSource,
                                        Locale('wage_received', Config.EmployeeWage.amount, location and location.label or businessId),
                                        'success'
                                    )
                                end
                            end
                        end
                    end

                    RefreshBusinessCache(businessId)
                end
            end
        end
    end)
end
