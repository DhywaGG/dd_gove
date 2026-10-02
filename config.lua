Config = {}

Config.GovernmentJobs = {
    government = true,
    goverment = true,
}

Config.MinimumGovernment = 1
Config.CountOnDutyOnly = true

Config.GovernmentStashId = 'government'

Config.Banking = 'renewed-banking'
Config.SocietyAccount = 'government'

Config.CashItem = 'money'
Config.CashLabel = 'Uang Tunai'

Config.GovernmentLocations = {
    duty = vec3(-550.83, -190.64, 38.14),
    management = vec3(-550.83, -190.64, 38.14),
}
Config.LocationSize = vec3(1.5, 1.5, 2.0)
Config.LocationRotation = 30.0
Config.LocationDistance = 2.0

Config.MaxManagementAmount = 10000000

Config.InteractionDistance = 2.0
Config.ServerDistance = 5.0
Config.TransactionCooldownMs = 1500
Config.MaxQuantityPerSale = 100

Config.Items = {
    plastic = { label = 'Plastik', price = 25 },
    glass = { label = 'Kaca', price = 30 },
    metalscrap = { label = 'Besi Bekas', price = 45 },
    copper = { label = 'Tembaga', price = 60 },
}

Config.NPCs = {
    {
        model = 'a_m_m_business_01',
        coords = vec4(-517.05, -211.34, 39.02, 115.47),
        scenario = 'WORLD_HUMAN_CLIPBOARD',
    },
}

Config.Text = {
    target = 'Jual Barang ',
    title = 'Pembelian Otomatis Pemerintah',
}
