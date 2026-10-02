# dd_gov

Pasar NPC otomatis untuk Qbox. NPC hanya membeli barang warga ketika tidak ada
pegawai government yang aktif. Nilai pembelian dipotong dari kas government,
uang tunai diberikan sebagai item inventory, dan barang dipindahkan ke dynamic
stash government. Saldo bank karakter tidak digunakan.

## Dependency

- `qbx_core`
- `ox_lib`
- `ox_inventory`
- `ox_target`
- `dd_stash` versi di dalam paket ini
- Default: `Renewed-Banking` (bisa diganti ke `qb-banking`/adapter custom)

## Lokasi job

`Config.GovernmentLocations.duty` adalah titik on/off duty. Titik
`management` digunakan pimpinan government untuk melihat saldo, deposit, dan
withdraw kas society. Koordinat bawaan hanya contoh dan dapat diganti.

Deposit mengambil item uang fisik dari inventory dan withdraw memasukkan item
uang fisik ke inventory. Nama item ditentukan oleh `Config.CashItem` (bawaan:
`money`). Hanya grade dengan `isboss = true` yang dapat membuka pengelolaan kas.

Tambahkan item berikut ke daftar item `ox_inventory` jika server belum memilikinya:

```lua
['money'] = {
    label = 'Uang Tunai',
    weight = 0,
    stack = true,
    close = false,
},
```

## Instalasi

1. Ganti resource stash lama dengan folder `dd_stash` dari paket ini.
2. Masukkan folder `dd_gove` ke resources server.
3. Pasang job `government` mengikuti `INSTALL_GOVERNMENT_JOB.md`.
4. Jalankan `/stashadmin`, lalu buat stash dengan ID `government`.
5. Isi akses job stash dengan `government:0` (atau `goverment:0` sesuai job server).
6. Sesuaikan `config.lua`: job, rekening society, item/harga, dan koordinat NPC.
7. Urutan `server.cfg`:

```cfg
ensure Renewed-Banking
ensure dd_stash
ensure dd_gove
```

## Alur transaksi

Server memvalidasi jarak, status pegawai, daftar barang, jumlah, kepemilikan item,
kapasitas stash, dan saldo kas. Harga tidak pernah dipercaya dari client. Jika
salah satu tahap transaksi gagal, resource mencoba mengembalikan saldo dan item
ke kondisi sebelum transaksi.

## Banking custom

Set `Config.Banking = 'custom'`, lalu sediakan tiga fungsi server sebelum transaksi:

```lua
CustomBanking = {
    GetBalance = function(account) return 0 end,
    RemoveMoney = function(account, amount) return false end,
    AddMoney = function(account, amount) return false end,
}
```
