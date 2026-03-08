# 🛡️ Developer Guidelines & Research Notes

Repositori ini berisi kumpulan pembelajaran, bypass, dan remote spy script untuk penelitian keamanan di Roblox.

## 1. Analisis Vulnerability: Angka Tak Terhingga (`"inf"`)
**Fenomena:**
Pada beberapa game, mengirim argumen `"inf"` ke RemoteEvent yang mengharapkan angka (seperti jumlah Damage, atau Reward XP) dapat menyebabkan kenaikan *stats* secara masif.

**Penyebab Teknis:**
- Saat fungsi `tonumber("inf")` dieksekusi oleh mesin Lua, hasilnya bukan error (ter-evaluasi menjadi `nil`), melainkan direpresentasikan sebagai `math.huge` (Angka tak terhingga positif).
- Jika *Server Script* Developer tidak mengamankan variabel ini (misalnya dengan mengecek `value == math.huge` atau membuat batasan limit maksimal / `math.clamp`), maka database server akan memperbarui akun pemain dengan angka tak terhingga tersebut.
- Hal ini sangat berbahaya jika argumen remote tersebut bertindak sebagai pengali (**multiplier**). Misalnya, remote `RE_ApplyOnceTrain` menerima nilai pengali *train speed* seperti `1.1` atau `1.5`. Jika dikirim `"inf"`, script server (yang lupa melakukan *sanity check*) mengalkulasi `Penambahan_Kekuatan = Base_Latihan * multiplier`. Karena *multiplier*-nya `math.huge`, jadinya penambahan kekuatan seketika menjadi tidak bernilai/mentok di angka maksimal.
- Walaupun angkanya "tak terhingga", sistem penyimpanan profil pemain (DataStoreService) Roblox tidak menoleransi `math.huge`. Akibatnya, angka tersebut terpotong menjadi integer maksimal yang dapat dikalkulasikan (misalnya `999,999,999`).

**Pelajaran Penting (Bagi Developer Game):**
Selalu gunakan pemeriksaan validasi untuk setiap nilai angka yang masuk dari client:
```lua
remote.OnServerEvent:Connect(function(player, value)
    if typeof(value) ~= "number" then return end
    if value == math.huge or value ~= value then return end -- Cek Infinity dan NaN
    if value < 0 or value > 100 then return end -- Cek Threshold/Limit
    
    -- Lakukan logika yang aman dari sini
end)
```

## 2. Remote Spy & Ekstraksi Logika (CobaltSpy vs XenoRSpy)
Memantau lalu lintas remote adalah metode paling efisien dibandingkan membedah client script yang diobfuscasi.

- **XenoRSpy:** Digunakan untuk memonitor trafik remote event simpel. Strukturnya ringan dan tidak memiliki fitur logging file berlebih. Cocok untuk game mini.
- **CobaltSpy:** Digunakan untuk ekosistem yang rumit. Terdiri dari *bundling* sistem canggih, meliputi auto-detect versi anti-cheat, file logger, generator format tabel lanjutan (`CodeGen`), dan bypassing proteksi. Sulit dimodifikasi, tapi hasilnya langsung dapat dijalankan (*ready-to-use*).

## 3. Struktur Penggunaan Callbacks (Spying ke Implementation)
Saat Anda menggunakan opsi klik kanan CobaltSpy, ada empat hal yang didapatkan:

1. **Copy Calling Code:**
   *Paling sering digunakan.* Jika Anda bertindak melakukan sebuah aksi di game (misal: "Heal"), ambil *Calling Code* ini dan letakkan di dalam fungsi tombol Script UI Anda (contoh: Rayfield `Callback = function() ... end`). Kode ini mereplikasi 100% bentuk asli pesan ke server.

2. **Copy Intercept Code:**
   *Digunakan untuk modifikasi nilai (In-Flight).* Kode ini akan mencegat dan memanipulasi remote tersebut **sebelum sampai ke server**. Berguna jika Anda ingin terus-terusan menyerang dengan hitungan *damage* abnormal walau *server* belum ter-trigger, atau mendeteksi kedatangan *packet/remote* dari *server* ke *client* (OnClientEvent/OnClientInvoke).

3. **Copy Remote Path & Copy Script Path:**
   Digunakan murni untuk keperluan *reverse-engineering*. Jika remote dienkripsi menggunakan parameter dinamis, mengetahui letak pasti *LocalScript* pengaksesnya (Script Path) memungkinkan kita untuk mendekompilasinya dan menembus sistem enkripsi (membuat formula dekripsi sendiri) menggunakan tool injektor.

## 4. Standarisasi SkenaUI HUB (Pembuatan Script UI Baru)
Saat Anda meminta AI untuk membuatkan script atau Hub baru untuk game Roblox tertentu, **JANGAN MENGGUNAKAN LIBRARY PIHAK KETIGA SEPERTI RAYFIELD ATAU FLUENT UNTUK INISIALISASI UI.**

Seluruh script buatan kita *selalu* harus diintegrasikan langsung ke dalam ekosistem `SkenaUI_Library.lua` yang sudah kita kembangkan agar sinkron dengan Skena Admin, *Toggle Key* global, dan tema visualnya.

**Contoh Template Standar (Seperti SurviveTheCold.lua / SawahIndo.lua):**
```lua
local SkenaUI_LibURL = "https://raw.githubusercontent.com/kndrckm/kndrckm.github.io/refs/heads/main/key/SkenaUI_Library.lua"
local SkenaUI = loadstring(game:HttpGet(SkenaUI_LibURL .. "?t=" .. tostring(os.time()), true))()

-- 1. Buat Window
local Window = SkenaUI.CreateWindow("SkenaHub", "Judul Game Anda!", false)

-- 2. Buat Tab Utama dan Utility (Gunakan Lucide icons seperti "zap", "eye", "settings")
local TabMain = Window:CreateTab("Main", "zap", false)
local TabSettings = Window:CreateTab("Settings", "settings", true)

-- 3. Load Fitur
TabMain:CreateToggleRow({
    Name = "Contoh Fitur",
    OnToggle = function(state)
        -- Logika Toggle
    end
})

-- 4. Wajib Panggil Modul SkenaAdmin di Akhir!
task.spawn(function()
    local succ, SkenaAdmin = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/kndrckm/kndrckm.github.io/refs/heads/main/key/SkenaUI_Admin.lua?t=" .. tostring(os.time())))()
    end)
    if succ and SkenaAdmin then
        SkenaAdmin.Attach(Window, {})
    end
end)
```
Selalu pastikan setiap tab diatur menggunakan fungsi `CreateTab` dari SkenaUI dan menyertakan injeksi `SkenaUI_Admin.lua` secara diam-diam di bagian paling akhir file!
