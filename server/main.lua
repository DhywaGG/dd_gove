local cooldowns = {}
local transactionLocked = false
local managementLocked = false

local function notifyErrorText(code)
    local errors = {
        invalid_item = 'Barang tidak terdaftar.',
        invalid_inventory = 'Stash pemerintah belum tersedia.',
        inventory_full = 'Stash pemerintah penuh.',
        not_enough_items = 'Barang yang kamu miliki tidak cukup.',
    }
    return errors[code] or 'Transaksi inventory gagal.'
end

local function governmentCount()
    local count = 0
    for _, source in ipairs(GetPlayers()) do
        local player = exports.qbx_core:GetPlayer(tonumber(source))
        local job = player and player.PlayerData and player.PlayerData.job
        if job and Config.GovernmentJobs[job.name] and (not Config.CountOnDutyOnly or job.onduty) then
            count = count + 1
        end
    end
    return count
end

local function npcIsNear(source, npcIndex)
    local npc = Config.NPCs[tonumber(npcIndex)]
    local ped = GetPlayerPed(source)
    if not npc or ped == 0 then return false end
    return #(GetEntityCoords(ped) - vector3(npc.coords.x, npc.coords.y, npc.coords.z)) <= Config.ServerDistance
end

local function locationIsNear(source, location)
    local coords = Config.GovernmentLocations[location]
    local ped = GetPlayerPed(source)
    if not coords or ped == 0 then return false end
    return #(GetEntityCoords(ped) - coords) <= Config.LocationDistance + 2.0
end

local function governmentPlayer(source, bossRequired)
    local player = exports.qbx_core:GetPlayer(source)
    local job = player and player.PlayerData and player.PlayerData.job
    if not job or not Config.GovernmentJobs[job.name] then return nil, 'Kamu bukan pegawai government.' end
    if bossRequired and not exports.qbx_core:IsGradeBoss(job.name, job.grade.level) then
        return nil, 'Hanya pimpinan government yang dapat mengelola kas.'
    end
    return player, job
end

local function stashStorageId()
    return exports.dd_stash:GetStorageId(Config.GovernmentStashId)
end

local function societyBalance()
    if Config.Banking == 'renewed-banking' then
        return exports['Renewed-Banking']:getAccountMoney(Config.SocietyAccount)
    elseif Config.Banking == 'qb-banking' then
        return exports['qb-banking']:GetAccountBalance(Config.SocietyAccount)
    elseif Config.Banking == 'custom' then
        return CustomBanking.GetBalance(Config.SocietyAccount)
    end
end

local function removeSocietyMoney(amount)
    if Config.Banking == 'renewed-banking' then
        return exports['Renewed-Banking']:removeAccountMoney(Config.SocietyAccount, amount)
    elseif Config.Banking == 'qb-banking' then
        return exports['qb-banking']:RemoveMoney(Config.SocietyAccount, amount, 'NPC membeli barang warga')
    elseif Config.Banking == 'custom' then
        return CustomBanking.RemoveMoney(Config.SocietyAccount, amount)
    end
    return false
end

local function addSocietyMoney(amount)
    if Config.Banking == 'renewed-banking' then
        return exports['Renewed-Banking']:addAccountMoney(Config.SocietyAccount, amount)
    elseif Config.Banking == 'qb-banking' then
        return exports['qb-banking']:AddMoney(Config.SocietyAccount, amount, 'Rollback pembelian NPC')
    elseif Config.Banking == 'custom' then
        return CustomBanking.AddMoney(Config.SocietyAccount, amount)
    end
    return false
end

local function canUse(source, npcIndex)
    if not npcIsNear(source, npcIndex) then return false, 'Kamu terlalu jauh dari NPC.' end
    if governmentCount() >= Config.MinimumGovernment then
        return false, 'Government sedang aktif. Jual barang langsung kepada petugas government.'
    end
    if not stashStorageId() then
        return false, ('Stash dengan ID "%s" belum dibuat.'):format(Config.GovernmentStashId)
    end
    return true
end

lib.callback.register('pk_govmarket:canUse', function(source, npcIndex)
    return canUse(source, npcIndex)
end)

lib.callback.register('pk_govmarket:toggleDuty', function(source)
    if not locationIsNear(source, 'duty') then return false, 'Kamu terlalu jauh dari lokasi duty.' end
    local player, jobOrMessage = governmentPlayer(source, false)
    if not player then return false, jobOrMessage end

    local newStatus = not jobOrMessage.onduty
    exports.qbx_core:SetJobDuty(source, newStatus)
    return true, newStatus and 'Kamu sekarang on-duty.' or 'Kamu sekarang off-duty.'
end)

lib.callback.register('pk_govmarket:getManagement', function(source)
    if not locationIsNear(source, 'management') then return false, 'Kamu terlalu jauh dari lokasi kas.' end
    local player, message = governmentPlayer(source, true)
    if not player then return false, message end
    local balance = tonumber(societyBalance())
    if not balance then return false, 'Rekening society government tidak ditemukan.' end
    return true, balance
end)

lib.callback.register('pk_govmarket:manageMoney', function(source, action, requestedAmount)
    if managementLocked then return false, 'Kas sedang memproses transaksi lain.' end
    if not locationIsNear(source, 'management') then return false, 'Kamu terlalu jauh dari lokasi kas.' end
    local player, message = governmentPlayer(source, true)
    if not player then return false, message end

    local amount = math.floor(tonumber(requestedAmount) or 0)
    if amount < 1 or amount > Config.MaxManagementAmount then return false, 'Jumlah tidak valid.' end
    if action ~= 'deposit' and action ~= 'withdraw' then return false, 'Jenis transaksi tidak valid.' end

    managementLocked = true
    if action == 'deposit' then
        local cashCount = exports.ox_inventory:GetItem(source, Config.CashItem, nil, true) or 0
        if cashCount < amount then
            managementLocked = false
            return false, ('Uang tunai tidak cukup. Kamu hanya memiliki $%s.'):format(cashCount)
        end

        local removed = exports.ox_inventory:RemoveItem(source, Config.CashItem, amount)
        if not removed then
            managementLocked = false
            return false, 'Gagal mengambil uang tunai dari inventory.'
        end
        if addSocietyMoney(amount) == false then
            exports.ox_inventory:AddItem(source, Config.CashItem, amount)
            managementLocked = false
            return false, 'Gagal menambahkan uang ke kas; uang tunai dikembalikan.'
        end
        managementLocked = false
        print(('[pk_govmarket] %s deposit $%s ke kas government'):format(player.PlayerData.citizenid, amount))
        return true, ('$%s berhasil dimasukkan ke kas government.'):format(amount)
    end

    local balance = tonumber(societyBalance()) or 0
    if balance < amount then
        managementLocked = false
        return false, 'Saldo kas government tidak cukup.'
    end
    if not exports.ox_inventory:CanCarryItem(source, Config.CashItem, amount) then
        managementLocked = false
        return false, 'Inventory kamu tidak cukup ruang untuk uang tunai.'
    end
    if removeSocietyMoney(amount) == false then
        managementLocked = false
        return false, 'Gagal memotong kas government.'
    end
    local cashAdded = exports.ox_inventory:AddItem(source, Config.CashItem, amount)
    if not cashAdded then
        addSocietyMoney(amount)
        managementLocked = false
        return false, 'Gagal memberi uang tunai; saldo kas dikembalikan.'
    end
    managementLocked = false
    print(('[pk_govmarket] %s withdraw $%s dari kas government'):format(player.PlayerData.citizenid, amount))
    return true, ('$%s berhasil ditarik dari kas government.'):format(amount)
end)

lib.callback.register('pk_govmarket:sell', function(source, npcIndex, itemName, requestedQuantity)
    if transactionLocked then return false, 'NPC sedang memproses transaksi lain. Coba lagi.' end

    local allowed, reason = canUse(source, npcIndex)
    if not allowed then return false, reason end

    local now = GetGameTimer()
    if cooldowns[source] and now - cooldowns[source] < Config.TransactionCooldownMs then
        return false, 'Tunggu sebentar sebelum transaksi berikutnya.'
    end
    cooldowns[source] = now

    local item = Config.Items[tostring(itemName)]
    local quantity = math.floor(tonumber(requestedQuantity) or 0)
    if not item or quantity < 1 or quantity > Config.MaxQuantityPerSale then
        return false, 'Barang atau jumlah tidak valid.'
    end

    local player = exports.qbx_core:GetPlayer(source)
    if not player then return false, 'Data karakter tidak ditemukan.' end

    local owned = exports.ox_inventory:GetItem(source, itemName, nil, true) or 0
    if owned < quantity then return false, ('Kamu hanya memiliki %s %s.'):format(owned, item.label) end

    local stashId = stashStorageId()
    local stash = exports.ox_inventory:GetInventory(stashId)
    if not stash then return false, 'Stash pemerintah belum termuat. Buka stash sekali atau restart resource.' end
    if not exports.ox_inventory:CanCarryItem(stashId, itemName, quantity) then
        return false, 'Stash pemerintah tidak cukup ruang.'
    end

    local total = math.floor(item.price * quantity)
    local balance = tonumber(societyBalance())
    if not balance or balance < total then
        return false, ('Kas government tidak cukup. Dibutuhkan $%s.'):format(total)
    end
    if not exports.ox_inventory:CanCarryItem(source, Config.CashItem, total) then
        return false, 'Inventory kamu tidak cukup ruang untuk menerima uang tunai.'
    end

    transactionLocked = true

    local debited = removeSocietyMoney(total)
    if debited == false then
        transactionLocked = false
        return false, 'Gagal memotong kas government.'
    end

    local removed, removeError = exports.ox_inventory:RemoveItem(source, itemName, quantity)
    if not removed then
        addSocietyMoney(total)
        transactionLocked = false
        return false, notifyErrorText(removeError)
    end

    local stored, storeError = exports.ox_inventory:AddItem(stashId, itemName, quantity)
    if not stored then
        exports.ox_inventory:AddItem(source, itemName, quantity)
        addSocietyMoney(total)
        transactionLocked = false
        return false, notifyErrorText(storeError)
    end

    local paid = exports.ox_inventory:AddItem(source, Config.CashItem, total)
    if not paid then
        exports.ox_inventory:RemoveItem(stashId, itemName, quantity)
        exports.ox_inventory:AddItem(source, itemName, quantity)
        addSocietyMoney(total)
        transactionLocked = false
        return false, 'Gagal membayar warga; transaksi dibatalkan.'
    end

    transactionLocked = false
    print(('[pk_govmarket] %s menjual %sx %s senilai $%s ke government'):format(player.PlayerData.citizenid, quantity, itemName, total))
    return true, ('Berhasil menjual %sx %s dan menerima $%s uang tunai.'):format(quantity, item.label, total)
end)

AddEventHandler('playerDropped', function()
    cooldowns[source] = nil
end)

RegisterCommand('cid', function(source)
    if source == 0 then
        print('Command /cid hanya bisa digunakan di dalam game.')
        return
    end

    local player = exports.qbx_core:GetPlayer(source)
    if not player then return end

    local citizenId = player.PlayerData.citizenid
    if not citizenId then return end

    TriggerClientEvent('ox_lib:notify', source, {
        title = 'Citizen ID',
        description = 'Citizen ID kamu: ' .. citizenId,
        type = 'inform',
        duration = 10000
    })
end, false)