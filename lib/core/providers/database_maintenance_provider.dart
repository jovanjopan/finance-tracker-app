import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../database/database_maintenance_service.dart';
import 'database_providers.dart';

class DatabaseMaintenanceController {
  DatabaseMaintenanceController(this._ref);

  final Ref _ref;

  Future<void> _closeActiveDatabase() async {
    final database = _ref.read(appDatabaseProvider);
    await database.close();
  }

  void _forceReopenDatabase() {
    _ref.invalidate(appDatabaseProvider);
  }

  /// Membuat salinan database untuk dibagikan lewat share sheet OS.
  /// Database aktif tidak berubah, cuma "dilepas sebentar" saat proses
  /// penyalinan supaya hasil salinannya konsisten (bukan setengah tulis).
  Future<void> backupAndShare() async {
    await _closeActiveDatabase();
    final backupPath = await DatabaseMaintenanceService.createShareableBackup();
    _forceReopenDatabase();

    await Share.shareXFiles([XFile(backupPath)], text: 'cadangan data koinku');
  }

  /// Menimpa database aktif dengan file [sourceFile]. Membuat cadangan
  /// pengaman internal dari kondisi SEBELUM restore terlebih dahulu.
  Future<void> restoreFromFile(File sourceFile) async {
    await _closeActiveDatabase();
    await DatabaseMaintenanceService.createInternalSafetyBackup('before_restore');
    await DatabaseMaintenanceService.overwriteWithFile(sourceFile);
    _forceReopenDatabase();
  }

  /// Menghapus seluruh data dan membangun database kosong dari awal.
  /// Membuat cadangan pengaman internal dari kondisi SEBELUM reset
  /// terlebih dahulu.
  Future<void> resetAllData() async {
    await _closeActiveDatabase();
    await DatabaseMaintenanceService.createInternalSafetyBackup('before_reset');
    await DatabaseMaintenanceService.deleteActiveDatabase();
    _forceReopenDatabase();
  }
}

final databaseMaintenanceControllerProvider = Provider<DatabaseMaintenanceController>((ref) {
  return DatabaseMaintenanceController(ref);
});