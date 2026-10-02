# Instalasi job government di Qbox

Nama job utama yang dipakai resource adalah `government`.

Tambahkan bagian berikut ke tabel jobs pada `qbx_core/shared/jobs.lua` (jangan
menimpa job lain yang sudah ada):

```lua
government = {
    label = 'Government',
    type = 'government',
    defaultDuty = true,
    offDutyPay = false,
    grades = {
        [0] = { name = 'Staff', payment = 100 },
        [1] = { name = 'Senior Staff', payment = 150 },
        [2] = { name = 'Secretary', payment = 200 },
        [3] = { name = 'Minister', payment = 300 },
        [4] = { name = 'Governor', isboss = true, payment = 400 },
    },
},
```

Setelah itu:

1. Restart server agar shared job terbaca.
2. Berikan job dengan command admin server kamu, contoh:
   `setjob [id] government 0`.
3. Buat dynamic stash memakai `/stashadmin`:
   - ID: `government`
   - Job: `government:0`
   - Label: `Gudang Government`
4. Pastikan nama rekening society di banking adalah `government`.

Uang milik pemain sepenuhnya memakai item inventory `money`; saldo cash/bank
bawaan Qbox tidak dipakai oleh resource ini. Ubah `Config.CashItem` jika nama
item uang tunai di server berbeda.

Resource menghitung pegawai dengan job `government` yang sedang on-duty. Jika
minimal satu orang on-duty, menu penjualan NPC otomatis ditolak. Perilaku ini
bisa diubah melalui `Config.MinimumGovernment` dan `Config.CountOnDutyOnly`.

Lokasi bawaan:

- Duty: `vec3(-545.52, -204.02, 38.22)`
- Kelola kas: `vec3(-536.72, -194.10, 38.22)`

Ganti keduanya di `Config.GovernmentLocations` sesuai lokasi kantor server.

Jika job server kamu terlanjur bernama `goverment`, alias itu sudah aktif di
`Config.GovernmentJobs`; samakan juga `Config.SocietyAccount` dan akses job stash.
