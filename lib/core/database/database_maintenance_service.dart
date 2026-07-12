import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Operasi file-system murni untuk backup/restore/reset database.
/// Tidak menyentuh Riverpod atau instance AppDatabase yang sedang aktif —
/// pemanggil WAJIB memastikan koneksi database sudah ditutup dulu sebelum
/// memanggil method-method di sini, supaya file tidak sedang dipakai.
class DatabaseMaintenanceService {
  DatabaseMaintenanceService._();

  static const String _dbFileName = 'app_database.sqlite';

  static Future<String> get databaseFilePath async {
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, _dbFileName);
  }

  static Future<Directory> get _backupsDirectory async {
    final dir = await getApplicationDocumentsDirectory();
    final backupsDir = Directory(p.join(dir.path, 'backups'));
    if (!await backupsDir.exists()) {
      await backupsDir.create(recursive: true);
    }
    return backupsDir;
  }

  static String _timestampSuffix(DateTime time) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${time.year}${two(time.month)}${two(time.day)}_${two(time.hour)}${two(time.minute)}${two(time.second)}';
  }

  /// Menyalin database aktif ke direktori temporary, siap dibagikan lewat
  /// share sheet OS. Mengembalikan path file salinannya.
  static Future<String> createShareableBackup() async {
    final dbPath = await databaseFilePath;
    final dbFile = File(dbPath);
    if (!await dbFile.exists()) {
      throw StateError('file database tidak ditemukan');
    }

    final tempDir = await getTemporaryDirectory();
    final backupName = 'koinku_backup_${_timestampSuffix(DateTime.now())}.sqlite';
    final backupPath = p.join(tempDir.path, backupName);

    await dbFile.copy(backupPath);
    return backupPath;
  }

  /// Menyalin database aktif ke folder cadangan INTERNAL aplikasi (bukan
  /// untuk dibagikan) sebagai jaring pengaman sebelum operasi merusak.
  static Future<void> createInternalSafetyBackup(String label) async {
    final dbPath = await databaseFilePath;
    final dbFile = File(dbPath);
    if (!await dbFile.exists()) {
      return;
    }

    final backupsDir = await _backupsDirectory;
    final backupName = '${label}_${_timestampSuffix(DateTime.now())}.sqlite';
    await dbFile.copy(p.join(backupsDir.path, backupName));
  }

  /// Menimpa database aktif dengan isi [sourceFile]. Menghapus file
  /// jurnal WAL/SHM/journal yang tersisa supaya tidak ada jurnal basi
  /// yang bentrok dengan data baru.
  static Future<void> overwriteWithFile(File sourceFile) async {
    final dbPath = await databaseFilePath;
    await _deleteJournalSiblings(dbPath);
    await sourceFile.copy(dbPath);
  }

  /// Menghapus total database aktif beserta jurnalnya. Saat AppDatabase
  /// dibuka ulang, onCreate akan membangun schema kosong dari awal.
  static Future<void> deleteActiveDatabase() async {
    final dbPath = await databaseFilePath;
    await _deleteJournalSiblings(dbPath);
    final dbFile = File(dbPath);
    if (await dbFile.exists()) {
      await dbFile.delete();
    }
  }

  static Future<void> _deleteJournalSiblings(String dbPath) async {
    for (final suffix in ['-wal', '-shm', '-journal']) {
      final file = File('$dbPath$suffix');
      if (await file.exists()) {
        await file.delete();
      }
    }
  }
}