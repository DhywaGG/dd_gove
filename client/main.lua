local spawnedPeds = {}

local function notify(description, notifyType)
    lib.notify({
        title = Config.Text.title,
        description = description,
        type = notifyType or 'inform'
    })
end

local function itemOptions()
    local options = {}
    for name, item in pairs(Config.Items) do
        options[#options + 1] = {
            value = name,
            label = ('%s - $%s/buah'):format(item.label, item.price)
        }
    end
    table.sort(options, function(a, b) return a.label < b.label end)
    return options
end

local function openSellMenu(npcIndex)
    local available, reason = lib.callback.await('pk_govmarket:canUse', false, npcIndex)
    if not available then return notify(reason or 'NPC sedang tidak tersedia.', 'error') end

    local input = lib.inputDialog(Config.Text.title, {
        {
            type = 'select',
            label = 'Barang',
            options = itemOptions(),
            required = true,
            searchable = true,
        },
        {
            type = 'number',
            label = 'Jumlah',
            required = true,
            min = 1,
            max = Config.MaxQuantityPerSale,
            default = 1,
        }
    })
    if not input then return end

    local success, message = lib.callback.await('pk_govmarket:sell', false, npcIndex, input[1], input[2])
    notify(message or (success and 'Barang berhasil dijual.' or 'Transaksi gagal.'), success and 'success' or 'error')
end

local function toggleDuty()
    local success, message = lib.callback.await('pk_govmarket:toggleDuty', false)
    notify(message or 'Gagal mengubah status duty.', success and 'success' or 'error')
end

local function manageGovernmentMoney()
    local allowed, balanceOrMessage = lib.callback.await('pk_govmarket:getManagement', false)
    if not allowed then return notify(balanceOrMessage or 'Tidak memiliki akses.', 'error') end

    local input = lib.inputDialog(('Kas Government: $%s'):format(balanceOrMessage), {
        {
            type = 'select',
            label = 'Transaksi',
            required = true,
            options = {
                { value = 'deposit', label = 'Deposit ke kas' },
                { value = 'withdraw', label = 'Withdraw dari kas' },
            }
        },
        {
            type = 'number',
            label = 'Jumlah',
            required = true,
            min = 1,
            max = Config.MaxManagementAmount,
        }
    })
    if not input then return end

    local success, message = lib.callback.await('pk_govmarket:manageMoney', false, input[1], input[2])
    notify(message or 'Transaksi kas gagal.', success and 'success' or 'error')
end

CreateThread(function()
    exports.ox_target:addBoxZone({
        name = 'pk_govmarket_duty',
        coords = Config.GovernmentLocations.duty,
        size = Config.LocationSize,
        rotation = Config.LocationRotation,
        options = {
            {
                name = 'pk_govmarket_toggle_duty',
                icon = 'fa-solid fa-user-clock',
                label = 'On/Off Duty Government',
                distance = Config.LocationDistance,
                onSelect = toggleDuty,
            }
        }
    })

    exports.ox_target:addBoxZone({
        name = 'pk_govmarket_management',
        coords = Config.GovernmentLocations.management,
        size = Config.LocationSize,
        rotation = Config.LocationRotation,
        options = {
            {
                name = 'pk_govmarket_manage_money',
                icon = 'fa-solid fa-building-columns',
                label = 'Kelola Kas Government',
                distance = Config.LocationDistance,
                onSelect = manageGovernmentMoney,
            }
        }
    })

    for index, data in ipairs(Config.NPCs) do
        local model = joaat(data.model)
        lib.requestModel(model)

        local ped = CreatePed(0, model, data.coords.x, data.coords.y, data.coords.z - 1.0, data.coords.w, false, false)
        SetEntityInvincible(ped, true)
        FreezeEntityPosition(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        if data.scenario then TaskStartScenarioInPlace(ped, data.scenario, 0, true) end

        exports.ox_target:addLocalEntity(ped, {
            {
                name = ('pk_govmarket_%s'):format(index),
                icon = 'fa-solid fa-scale-balanced',
                label = Config.Text.target,
                distance = Config.InteractionDistance,
                onSelect = function() openSellMenu(index) end,
            }
        })

        spawnedPeds[#spawnedPeds + 1] = ped
        SetModelAsNoLongerNeeded(model)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for _, ped in ipairs(spawnedPeds) do
        if DoesEntityExist(ped) then DeleteEntity(ped) end
    end
end)
