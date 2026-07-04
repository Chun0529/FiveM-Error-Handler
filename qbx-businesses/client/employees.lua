function ToggleClockIn(businessId)
    local success, message = lib.callback.await('qbx-businesses:server:toggleClock', false, businessId)
    lib.notify({
        description = message,
        type = success and 'success' or 'error',
    })
end
