# ARCHITECTURE.md: Finance Tracker App

## 1. Ringkasan Proyek
Aplikasi pelacak keuangan (*cashflow* dan *budgeting*) dengan arsitektur **Offline-First**. Semua transaksi diproses dan disimpan secara lokal dengan kecepatan instan, dengan struktur data yang dirancang untuk mendukung sinkronisasi *cloud* di masa depan tanpa merombak skema dasar.

## 2. Tech Stack Core
- **Framework:** Flutter
- **State Management:** Riverpod (`flutter_riverpod`)
- **Local Database:** Drift (SQLite relasional dengan *type-safety*)
- **ID Generation:** UUID v4 (Krusial untuk arsitektur Offline-First)

## 3. Aturan Arsitektur Makro (System Design)

### A. Pola Direktori (Feature-First Architecture)
Kode diorganisasikan berdasarkan fitur/domain bisnis, bukan berdasarkan tipe file (layer). Ini menjaga skalabilitas saat aplikasi semakin membesar.

```text
/lib
 ├── /core                      # Kode generik, TIDAK BOLEH berisi business rule apa pun
 │    ├── /database
 │    │    ├── app_database.dart      # Instance Drift utama
 │    │    ├── /tables                # Definisi tabel (Account, Category, Transaction, Budget)
 │    │    └── /migrations            # Strategi migrasi schema (lihat section 5)
 │    ├── /utils                # Format mata uang, tanggal, dll
 │    └── /theme                # Warna, Typography
 ├── /features                  # Modul berdasarkan fitur bisnis
 │    ├── /transactions
 │    │    ├── /data            # Repository (implementasi ke Drift)
 │    │    ├── /domain          # Entities, Enums, Use Cases, Business Rules/Validasi
 │    │    └── /presentation    # UI (Screens, Widgets) & Riverpod Providers
 │    ├── /accounts
 │    │    ├── /data
 │    │    ├── /domain          # Termasuk logic kalkulasi balance (derived)
 │    │    └── /presentation
 │    └── /budgets
 │         ├── /data
 │         ├── /domain          # Logic perhitungan progress vs targetAmount
 │         └── /presentation
 └── main.dart
```

Setiap fitur (`transactions`, `accounts`, `budgets`) konsisten memakai struktur tiga folder yang sama: `data` → `domain` → `presentation`. Tidak ada fitur yang "lebih tipis" strukturnya dari yang lain.

### B. Alur Dependensi (Dependency Rule)
- `domain` tidak boleh tahu apa-apa soal Drift atau Riverpod. Ia murni berisi entity, enum, use case, dan business rule dalam Dart biasa.
- `data` mengimplementasikan interface repository yang didefinisikan di `domain`, lalu menerjemahkannya ke query Drift.
- `presentation` hanya bicara dengan `domain` (lewat repository interface & providers), tidak pernah mengakses Drift secara langsung.
- `/core` **murni generik** — tidak boleh berisi satu pun aturan bisnis. Kalau ada kode yang butuh tahu soal "transfer", "kategori", atau "budget", kode itu tidak boleh tinggal di `/core`.

## 4. Business Rules Kunci

### A. Kalkulasi Saldo Akun
Saldo berjalan **tidak disimpan sebagai field statis** di tabel `ACCOUNT`. Pendekatan v1:
- Dihitung lewat query agregat Drift (`SUM`) dengan **index wajib** di `TRANSACTION.accountId`, `TRANSACTION.toAccountId`, dan `TRANSACTION.transactionDate`.
- Untuk skala personal finance tracker (single-user, offline SQLite), volume transaksi realistis per tahun tidak akan mencapai titik di mana agregat langsung jadi bottleneck; SQLite modern dengan index yang tepat menangani puluhan ribu baris dalam hitungan milidetik.
- Hasil agregat di-*cache* di level provider Riverpod dan diinvalidasi otomatis setiap ada insert/update/delete transaksi yang menyentuh akun terkait — bukan dihitung ulang dari nol setiap render UI.
- Logic ini tinggal di `/features/accounts/domain`.

**Catatan future-optimization (bukan kewajiban v1):** Jika benchmark di device nyata (khususnya low-end) menunjukkan query agregat mulai terasa lambat setelah data bertambah besar, pertimbangkan pola **Monthly Snapshot** (`ACCOUNT_MONTHLY_SNAPSHOT`: saldo akhir per bulan disimpan statis, saldo berjalan = snapshot bulan lalu + agregat bulan berjalan). Jika opsi ini diaktifkan, wajib disertai mekanisme invalidasi snapshot yang jelas — setiap insert/update/delete transaksi dengan `transactionDate` di masa lalu harus memicu rekalkulasi snapshot bulan-bulan setelahnya. Jangan adopsi pola ini tanpa mendesain invalidasi-nya terlebih dahulu, karena snapshot yang tidak sinkron dengan data aktual adalah kelas bug yang lebih sulit dilacak daripada query yang lambat.

### B. Validasi Kondisional pada Transaction
`TRANSACTION.type` menentukan field mana yang wajib/harus null. Aturan ini di-enforce di `/features/transactions/domain` sebelum data dikirim ke repository:

| type | categoryId | toAccountId |
|---|---|---|
| `income` / `expense` | wajib diisi | harus null |
| `transfer` | harus null | wajib diisi |

Selain itu, `CATEGORY.expenseClassification` hanya relevan jika `CATEGORY.transactionType = 'expense'`; validator menolak pengisian field ini untuk kategori bertipe income.

### C. Validasi & Orkestrasi Lintas-Fitur
Beberapa operasi butuh baca-tulis lintas domain — contoh paling jelas: **transfer antar akun**, yang butuh membaca status (`isActive`) dari Domain Akun sekaligus menulis ke Domain Transaksi.

Kasus ini **tidak** ditangani oleh shared validator generik di `/core` (itu akan membocorkan business logic ke layer yang seharusnya netral). Sebagai gantinya, ditangani oleh **Use Case / Domain Service** yang tinggal di dalam fitur yang menjadi pemilik utama operasi tersebut — dalam kasus transfer, itu `/features/transactions/domain`.

Alur contoh untuk transfer:
1. `TransferMoneyUseCase` (di `/features/transactions/domain`) dipanggil dari presentation layer.
2. Use case ini memanggil `AccountRepository` (interface milik domain akun) untuk memvalidasi `isActive` di akun sumber & tujuan.
3. Jika valid, use case memanggil `TransactionRepository` untuk mengeksekusi pencatatan transaksi transfer.
4. Tidak ada logic ini yang bocor ke `/core` — `/core` tetap murni infrastruktur generik (database instance, utils, tema).

Pola ini berlaku untuk semua kasus validasi lintas-fitur berikutnya: use case tinggal di fitur yang paling bertanggung jawab atas operasi tersebut, dan berkomunikasi dengan fitur lain murni lewat repository interface, bukan lewat implementasi konkret.

## 5. Strategi Migrasi Schema (Drift)
- Setiap perubahan schema menaikkan `schemaVersion` di `app_database.dart`.
- Migrasi ditulis eksplisit per versi menggunakan `MigrationStrategy` bawaan Drift (`onUpgrade`), disimpan satu file per versi di `/core/database/migrations` (contoh: `migration_v1_to_v2.dart`).
- Karena aplikasi ini Offline-First, migrasi harus aman dijalankan tanpa koneksi internet dan tidak boleh menghapus data pengguna secara diam-diam — kolom baru selalu punya default value atau nullable.

## 6. Pola State Management (Riverpod)
- **`AsyncNotifier`** untuk state yang sumbernya asynchronous dan butuh reload (daftar transaksi, daftar akun dengan balance ter-agregasi).
- **`Notifier`** untuk state UI murni yang synchronous (filter aktif di layar transaksi, tab yang sedang dipilih).
- Setiap fitur punya providers sendiri di `/features/<fitur>/presentation/providers`, diekspos ke luar hanya lewat repository interface — tidak ada global provider "dewa" di `/core`.
- Provider yang bergantung pada fitur lain melakukan `ref.watch` ke provider fitur lain tersebut, bukan duplikasi logic.

## 7. Testing Strategy
- **Unit test** difokuskan di layer `domain`: business rules (section 4) dan use case orkestrasi (section 4C) wajib punya coverage tinggi karena ini logic paling kritis di aplikasi.
- **Repository test** di layer `data` menggunakan in-memory Drift database (`NativeDatabase.memory()`).
- **Widget test** di layer `presentation` opsional di tahap awal, diprioritaskan untuk flow kritis (input transaksi, transfer antar akun).

## 8. Pertimbangan Masa Depan (Cloud Sync)
Skema saat ini sudah kompatibel dengan sync karena:
- UUID v4 sebagai primary key menghindari konflik ID antar device.
- Tidak ada auto-increment integer di manapun dalam skema.
- Struktur `data/domain/presentation` memudahkan penambahan `RemoteDataSource` di layer `data` nanti tanpa mengubah `domain` maupun `presentation` — repository tinggal digabung jadi `LocalFirstRepository` yang membaca dari Drift dan menulis ke Drift + antrian sync.