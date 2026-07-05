# Instruksi Wajib untuk Copilot

Proyek ini pakai Flutter + Riverpod + Drift, arsitektur Feature-First 
(lihat ARCHITECTURE.md untuk detail lengkap).

ATURAN KERAS — jangan pernah dilanggar:
1. Layer `domain` TIDAK BOLEH import package Drift atau Riverpod. Domain 
   murni Dart (entity, enum, use case, repository interface).
2. Layer `/core` TIDAK BOLEH berisi business rule apa pun. Kalau kode 
   menyebut "transfer", "kategori", atau "budget", itu HARUS di /features.
3. Saldo akun TIDAK disimpan sebagai field statis — selalu dihitung dari 
   initialBalance + agregat transaksi (lihat ARCHITECTURE.md section 4A).
4. Validasi lintas-fitur (contoh: transfer) ditangani oleh Use Case di 
   dalam domain fitur pemilik operasi, bukan shared validator di /core 
   (lihat section 4C).
5. Setiap fitur baru WAJIB punya 3 folder: data, domain, presentation.

Sebelum generate kode apa pun, cek dulu apakah ada bagian relevan di 
ARCHITECTURE.md dan ikuti persis.