import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../accounts/presentation/account_list_screen.dart';
import '../../categories/presentation/category_list_screen.dart';

class LainnyaTabScreen extends StatelessWidget {
  const LainnyaTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('lainnya', style: GoogleFonts.pressStart2p(fontSize: 14, color: AppColors.textPrimary)),
              const SizedBox(height: 20),
              _MenuTile(
                icon: Icons.account_balance_wallet_outlined,
                label: 'kelola akun',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const AccountListScreen()),
                  );
                },
              ),
              _MenuTile(
                icon: Icons.label_outline,
                label: 'kelola kategori',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const CategoryListScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(color: AppColors.surface, border: Border.all(color: AppColors.border, width: 2)),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textPrimary),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: GoogleFonts.vt323(fontSize: 17, color: AppColors.textPrimary))),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}