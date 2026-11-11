# Cara Memasukkan Semua Model Kursi ke Roblox Studio

Semua aset kursi sudah diekspor dan siap dimasukkan ke dalam game Roblox kamu. Tersedia 3 metode impor yang fleksibel dan instan:

---

## 📁 Lokasi File Export
Semua file berada di folder:
`D:\BAF\models\roblox_models\`

### Daftar File:
1. **Roblox XML Models (`.rbxmx`)** (Langsung drag-and-drop ke Studio):
   - `CrimsonFlameChair.rbxmx` — Kursi kayu merah chunky dengan api membara & diamond ruby gem
   - `CyberCoreChair.rbxmx` — Kursi cyber metal gelap dengan neon sirkuit cyan/magenta & energy core berputar
   - `FrostbiteIceThrone.rbxmx` — Tahta es kristal biru bercahaya dengan mahkota 11 kristal & icicles
   - `RoyalFootballThrone.rbxmx` — Tahta emas kartun dengan bantal capitone merah, bola sepak & mahkota raja
   - `AllChairsShowcase.rbxmx` — Berisi keempat kursi sekaligus, berjajar rapi berdampingan!

2. **Standalone Luau Script (`SpawnAllChairsInStudio.luau`)**:
   - Skrip mandiri tanpa ketergantungan untuk spawn ke-4 kursi secara otomatis di Workspace.

3. **High-Poly 3D Mesh (`.fbx`)**:
   - `CrimsonFlameChair.fbx`
   - `CyberCoreChair.fbx`
   - `FrostbiteIceThrone.fbx`
   - `RoyalFootballThrone.fbx`

---

## 🚀 Metode 1: 1-Klik Lewat Command Bar Studio (Paling Cepat & Anti-Gagal)
1. Buka project game kamu di **Roblox Studio**.
2. Buka menu **View** > centang **Command Bar** (atau tekan `Ctrl + Shift + X`).
3. Buka file `SpawnAllChairsInStudio.luau`, copy seluruh kodenya.
4. Paste ke dalam **Command Bar** di bagian bawah Roblox Studio, lalu tekan **Enter**.
5. Keempat kursi akan langsung muncul di `Workspace.ExportedChairs_Showcase` lengkap dengan:
   - Kursi (`Seat`) yang bisa langsung diduduki karakter pemain.
   - Efek partikel api, percikan digital, kabut es kristal, dan kilau emas.
   - Titik cahaya (`PointLight`) dan neon glow.
   - Skrip animasi mandiri (animasi putaran energy core, denyut ruby gem).

---

## 🖱️ Metode 2: Drag & Drop File `.rbxmx`
1. Buka **Roblox Studio** dan window **Explorer**.
2. Buka folder `D:\BAF\models\roblox_models\` di Windows Explorer.
3. Tarik (drag) file `AllChairsShowcase.rbxmx` (atau kursi individual mana pun) langsung ke dalam viewport 3D atau ke dalam folder `Workspace` di panel Explorer.
4. Model langsung masuk ke game dengan hirarki part lengkap dan properti Anchored aktif.

---

## 🎨 Metode 3: Impor sebagai Mesh 3D dari Blender (`.fbx`)
Jika ingin mengimpor hasil sculpting / geometri mesh Blender mentah:
1. Di Roblox Studio, buka tab **Home** / **View** > **Asset Manager**.
2. Klik tombol **Bulk Import** (ikon folder dengan panah).
3. Pilih file `.fbx` dari `D:\BAF\models\roblox_models\`.
4. Roblox akan mengunggah mesh tersebut ke game inventory kamu sebagai `MeshPart`.
5. Drag `MeshPart` dari Asset Manager ke Workspace.

---

## 💻 Integrasi Kode Game (`ChairModelBuilder.luau`)
Di dalam script game kamu (`ReplicatedStorage/Prefabs/ChairModelBuilder.luau`), fungsi pembuat kursi sudah otomatis ditambahkan:

```luau
local ChairModelBuilder = require(game:GetService("ReplicatedStorage").Prefabs.ChairModelBuilder)

-- Panggil berdasarkan ID skin atau nama:
local crimsonChair = ChairModelBuilder.buildChair("crimson")
local cyberChair   = ChairModelBuilder.buildChair("cyber")
local frostThrone  = ChairModelBuilder.buildChair("frostbite")
local royalThrone  = ChairModelBuilder.buildChair("golden")

-- Atau panggil fungsi spesifik:
-- ChairModelBuilder.buildCrimsonFlameChair(cfOffset)
-- ChairModelBuilder.buildCyberCoreChair(cfOffset)
-- ChairModelBuilder.buildFrostbiteThrone(cfOffset)
-- ChairModelBuilder.buildRoyalFootballThrone(cfOffset)
```
Semua model otomatis memiliki `PrimaryPart` yang diset ke `Seat`, semua part sudah `Anchored = true`, dan CanCollide sudah diatur optimal.
