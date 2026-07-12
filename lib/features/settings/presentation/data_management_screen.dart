import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/providers/database_maintenance_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/pixel_button.dart';
import '../../../core/widgets/pixel_loading_indicator.dart';
import '../../../core/widgets/pixel_page_route.dart';
import '../../splash/presentation/splash_screen.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

class DataManagementScreen extends ConsumerStatefulWidget {
  const DataManagementScreen({super.key});

  @override
  ConsumerState<DataManagementScreen> createState() => _DataManagementScreenState();
}

class _DataManagementScreenState extends ConsumerState<DataManagementScreen> {
  bool _isProcessing = false;

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(title, style: GoogleFonts.vt323(fontSize: 20, color: AppColors.textPrimary)),
        content: Text(message, style: GoogleFonts.vt323(fontSize: 16, color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('batal', style: GoogleFonts.vt323(fontSize: 16, color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmLabel, style: GoogleFonts.vt323(fontSize: 16, color: confirmColor)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _handleBackup() async {
    setState(() => _isProcessing = true);
    try {
      await ref.read(databaseMaintenanceControllerProvider).backupAndShare();
      if (mounted) {
        _showMessage('cadangan siap dibagikan');
      }
    } catch (_) {
      if (mounted) {
        _showMessage('gagal membuat cadangan, coba lagi');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handleRestore() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result == null || result.files.single.path == null) {
      return;
    }

    final pickedPath = result.files.single.path!;
    if (!pickedPath.toLowerCase().endsWith('.sqlite')) {
      _showMessage('file harus berformat .sqlite');
      return;
    }

    if (!mounted) {
      return;
    }

    final confirmed = await _confirm(
      title: 'pulihkan data?',
      message: 'semua data saat ini akan DITIMPA dengan isi file cadangan ini. tindakan ini tidak bisa dibatalkan.',
      confirmLabel: 'pulihkan',
      confirmColor: AppColors.negative,
    );
    if (!confirmed || !mounted) {
      return;
    }

    setState(() => _isProcessing = true);
    try {
      await ref.read(databaseMaintenanceControllerProvider).restoreFromFile(File(pickedPath));
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushAndRemoveUntil(
        PixelPageRoute(builder: (_) => const SplashScreen()),
        (route) => false,
      );
    } catch (_) {
      if (mounted) {
        _showMessage('gagal memulihkan data, coba lagi');
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handleReset() async {
    final confirmed = await _confirm(
      title: 'reset semua data?',
      message: 'SEMUA akun, transaksi, kategori, dan budget akan dihapus permanen. apakah anda yakin?',
      confirmLabel: 'ya, hapus semua',
      confirmColor: AppColors.negative,
    );
    if (!confirmed || !mounted) {
      return;
    }

    setState(() => _isProcessing = true);
    try {
      await ref.read(databaseMaintenanceControllerProvider).resetAllData();
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushAndRemoveUntil(
        PixelPageRoute(builder: (_) => const SplashScreen()),
        (route) => false,
      );
    } catch (_) {
      if (mounted) {
        _showMessage('gagal mereset data, coba lagi');
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'kelola data',
                        style: GoogleFonts.pressStart2p(fontSize: 12, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'cadangkan data',
                    style: GoogleFonts.vt323(fontSize: 18, color: AppColors.textPrimary),
                  ),
                  Text(
                    'simpan salinan seluruh data ke Google Drive, email, atau penyimpanan lain lewat menu bagikan.',
                    style: GoogleFonts.vt323(fontSize: 14, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 10),
                  PixelButton(
                    onPressed: _isProcessing ? null : _handleBackup,
                    color: AppColors.positive,
                    child: Text('bagikan cadangan', style: GoogleFonts.vt323(fontSize: 18, color: AppColors.background)),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'pulihkan data',
                    style: GoogleFonts.vt323(fontSize: 18, color: AppColors.textPrimary),
                  ),
                  Text(
                    'timpa data saat ini dengan file cadangan .sqlite yang pernah dibuat sebelumnya.',
                    style: GoogleFonts.vt323(fontSize: 14, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 10),
                  PixelButton(
                    onPressed: _isProcessing ? null : _handleRestore,
                    color: AppColors.primary,
                    child: Text('pilih file cadangan', style: GoogleFonts.vt323(fontSize: 18, color: AppColors.background)),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.negative, width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'zona bahaya',
                          style: GoogleFonts.vt323(fontSize: 18, color: AppColors.negative),
                        ),
                        Text(
                          'menghapus SEMUA data secara permanen. gunakan untuk membersihkan data hasil testing.',
                          style: GoogleFonts.vt323(fontSize: 14, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 10),
                        PixelButton(
                          onPressed: _isProcessing ? null : _handleReset,
                          color: AppColors.negative,
                          child: Text('reset semua data', style: GoogleFonts.vt323(fontSize: 18, color: AppColors.background)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_isProcessing)
              Container(
                color: AppColors.background.withValues(alpha: 0.85),
                child: const Center(child: PixelLoadingIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}