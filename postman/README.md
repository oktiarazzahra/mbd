# Postman Testing Documentation

## 📥 Import ke Postman

1. Buka Postman
2. Click **Import** → Pilih kedua file:
   - `MBD-API.postman_collection.json`
   - `MBD-Environment.postman_environment.json`
3. Pilih environment **MBD Environment** di kanan atas

## 👤 Akun Testing dari Database

### Admin
```
Username: admin
Password: admin123
```

### Mahasiswa (5 akun)
| Nama | Email | Password | ID |
|------|-------|----------|-----|
| Rina Susanti | rina.susanti@student.univ.ac.id | pw1 | 1 |
| Joko Santoso | joko.santoso@student.univ.ac.id | pw2 | 2 |
| Fitri Wahyuni | fitri.wahyuni@student.univ.ac.id | pw3 | 3 |
| Agung Prasetyo | agung.prasetyo@student.univ.ac.id | pw4 | 4 |
| Dewi Kartika | dewi.kartika@student.univ.ac.id | pw5 | 5 |

### Dosen (5 akun)
| Nama | Email | Password | ID |
|------|-------|----------|-----|
| Dr. Andi Wijaya, M.Kom | andi.wijaya@univ.ac.id | pass1 | 1 |
| Prof. Siti Nurhaliza, M.T | siti.nurhaliza@univ.ac.id | pass2 | 2 |
| Dr. Budi Santoso, M.Sc | budi.santoso@univ.ac.id | pass3 | 3 |
| Maya Sari, S.Kom, M.Kom | maya.sari@univ.ac.id | pass4 | 4 |
| Dr. Ahmad Rizki, M.Eng | ahmad.rizki@univ.ac.id | pass5 | 5 |

### Proposal yang Sudah Ada (5 proposal)
| ID | Judul | Mahasiswa | Status |
|----|-------|-----------|--------|
| 1 | Sistem Informasi Manajemen Perpustakaan | Rina (ID: 1) | Diajukan |
| 2 | Analisis Sentimen Media Sosial | Joko (ID: 2) | Diajukan |
| 3 | Sistem IoT untuk Smart Home | Fitri (ID: 3) | Diajukan |
| 4 | Aplikasi E-Learning Mobile | Agung (ID: 4) | Diajukan |
| 5 | Sistem Deteksi Wajah Real-time | Dewi (ID: 5) | Diajukan |

## 🚀 Urutan Testing yang Benar

### Step 1: Authentication (Login dulu!)
Jalankan endpoint ini **PERTAMA** untuk mendapatkan token:

1. **Login Admin** → Simpan admin_token
2. **Login Mahasiswa (Rina)** → Simpan mahasiswa_token + mahasiswa_id
3. **Login Dosen (Dr. Andi)** → Simpan dosen_token + dosen_id

> **PENTING:** Token akan otomatis tersimpan ke environment variables!

### Step 2: Mahasiswa Operations
Login sebagai Rina dulu, lalu test:

4. **Get My Proposals** → Lihat proposal milik Rina (ID: 1)
5. **Get My Profile** → Data profil Rina
6. **Update Profile** → Edit profil
7. **Change Password** → Ganti password (hati-hati! password Rina akan berubah dari `pw1` ke `newpassword123`)

### Step 3: Proposal Operations
Login sebagai Rina, test CRUD proposal:

8. **Submit New Proposal** → Buat proposal baru (ID disimpan otomatis)
9. **Get Proposal Detail (ID: 1)** → Detail proposal perpustakaan
10. **Edit Proposal (ID: 1)** → Update judul/abstrak
11. **Delete Proposal** → Hapus proposal yang baru dibuat di step 8

### Step 4: Dosen Operations
Login sebagai Dr. Andi:

12. **Get Statistics** → Statistik pembimbingan
13. **Update Profile** → Edit profil dosen

### Step 5: Pembimbing Operations
Login sebagai Dr. Andi (dia pembimbing proposal ID 1):

14. **Get My Supervised Proposals** → Proposal yang dibimbing
15. **Give Feedback** → Kasih feedback untuk proposal ID 1
16. **Get Proposal History (ID: 1)** → Lihat semua feedback yang pernah diberikan

### Step 6: Admin Operations
Login sebagai admin:

17. **Get All Mahasiswa** → List 5 mahasiswa
18. **Get All Dosen** → List 5 dosen
19. **Get All Proposals** → List 5 proposals
20. **Add Dosen** → Tambah dosen baru (ID disimpan otomatis)
21. **Assign Pembimbing** → Assign Prof. Siti (ID: 2) ke proposal ID 3
22. **Remove Pembimbing** → Hapus pembimbing dari proposal
23. **Dashboard Statistics** → Statistik keseluruhan
24. **Search Proposals** → Cari proposal dengan status "Diajukan"

### Step 7: Register Testing
25. **Register Mahasiswa Baru** → Daftar mahasiswa baru (no token needed!)

## ⚙️ Cara Menggunakan

### Manual Testing (Satu-satu)
1. Pilih request
2. Klik **Send**
3. Lihat response di bawah
4. Token otomatis tersimpan untuk request berikutnya!

### Automated Testing (Collection Runner)
1. Klik kanan pada collection **MBD API Collection**
2. Pilih **Run collection**
3. Atur delay: **500ms** (untuk avoid race conditions)
4. Klik **Run MBD API Collection**
5. Tunggu semua request selesai
6. Lihat hasil: harus 24/24 passed ✅

## 🔍 Troubleshooting

### ❌ 401 Unauthorized
**Penyebab:** Token belum ada atau expired

**Solusi:**
1. Jalankan login endpoint dulu (Admin/Mahasiswa/Dosen)
2. Cek environment variables, pastikan token terisi
3. Token JWT valid 24 jam

### ❌ 403 Forbidden
**Penyebab:** Role tidak sesuai

**Solusi:** Gunakan token yang benar:
- Admin endpoints → gunakan `{{admin_token}}`
- Mahasiswa endpoints → gunakan `{{mahasiswa_token}}`
- Dosen endpoints → gunakan `{{dosen_token}}`

### ❌ 404 Not Found
**Penyebab:** ID tidak ada di database

**Solusi:**
- Gunakan ID yang ada: proposal (1-5), mahasiswa (1-5), dosen (1-5)
- Atau gunakan ID yang disimpan di environment: `{{new_proposal_id}}`, `{{new_mahasiswa_id}}`, dll

### ❌ 500 Internal Server Error
**Penyebab:** Database issue atau constraint violation

**Solusi:**
1. Cek console server untuk error detail
2. Pastikan foreign key valid (proposal_id, dosen_id ada di DB)
3. Cek unique constraint (email, NIM, NIP tidak boleh duplikat)

### ❌ Connection Refused (ECONNREFUSED)
**Penyebab:** Server belum running

**Solusi:**
```bash
# Jalankan server dulu!
npm start

# Server harus running di http://localhost:3000
```

## 📝 Tips & Best Practices

### 1. Gunakan Environment Variables
Semua token & ID tersimpan otomatis. Jangan hardcode!

```
✅ BENAR: {{mahasiswa_token}}
❌ SALAH: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### 2. Urutan Itu Penting!
Login dulu sebelum operasi lain:
```
Login → Get Data → Create → Update → Delete
```

### 3. Perhatikan Role
- Admin: semua operasi management
- Mahasiswa: hanya data sendiri
- Dosen: hanya proposal bimbingannya

### 4. Test dengan Data Real
Gunakan ID yang ada di database:
- Rina (mahasiswa_id: 1) punya proposal_id: 1
- Dr. Andi (dosen_id: 1) jadi pembimbing proposal_id: 1

### 5. Backup Data Sebelum Testing
```bash
mysqldump -u root -p mbd > backup_before_testing.sql
```

## 🎯 Expected Results

### Login Success
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "mahasiswa_id": 1,
    "nama": "Rina Susanti",
    "email": "rina.susanti@student.univ.ac.id",
    "role": "mahasiswa"
  }
}
```

### Get Proposals Success
```json
[
  {
    "proposal_id": 1,
    "judul": "Sistem Informasi Manajemen Perpustakaan",
    "abstrak": "Penelitian tentang pembangunan sistem...",
    "status": "Diajukan",
    "mahasiswa_nama": "Rina Susanti",
    "pembimbing": "Dr. Andi Wijaya, M.Kom"
  }
]
```

### Submit Proposal Success
```json
{
  "proposal_id": 6,
  "message": "Proposal berhasil diajukan"
}
```

## 📊 Testing Coverage

Collection ini mencover **27 endpoints**:
- ✅ 4 Authentication endpoints
- ✅ 4 Mahasiswa operations
- ✅ 4 Proposal CRUD
- ✅ 2 Dosen operations
- ✅ 3 Pembimbing operations
- ✅ 8 Admin operations

**Total: 27 requests** yang bisa dijalankan otomatis atau manual!

## 🔐 Security Notes

1. **Jangan commit token ke Git!** Environment file sudah include token kosong
2. **Ganti password default** sebelum production
3. **JWT_SECRET** di `.env` harus strong (min 32 karakter random)
4. **Database credentials** jangan expose di kode

## 📞 Need Help?

Jika masih error:
1. Cek log server di terminal
2. Cek database connection
3. Pastikan semua dependencies installed: `npm install`
4. Restart server: `npm start`
5. Re-import database: `mysql -u root -p mbd < mbd.sql`

Happy Testing! 🚀
