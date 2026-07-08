import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../domain/account_entity.dart';
import 'account_form_screen.dart';
import 'account_providers.dart';
import '../../../core/providers/database_providers.dart';

class AccountListScreen extends ConsumerWidget {
  const AccountListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accentGamify,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const AccountFormScreen(),
            ),
          );
        },
        child: const Icon(Icons.add, color: AppColors.background),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'kelola akun',
                    style: GoogleFonts.pressStart2p(fontSize: 12, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
            Expanded(
              child: accountsAsync.when(
                data: (accounts) {
                  if (accounts.isEmpty) {
                    return Center(
                      child: Text(
                        'belum ada akun',
                        style: GoogleFonts.vt323(fontSize: 16, color: AppColors.textMuted),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: accounts.length,
                    itemBuilder: (context, index) {
                      return _AccountTile(account: accounts[index]);
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (error, stackTrace) => Center(
                  child: Text(
                    'gagal memuat akun',
                    style: GoogleFonts.vt323(fontSize: 16, color: AppColors.negative),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountTile extends ConsumerWidget {
  const _AccountTile({required this.account});

  final AccountEntity account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(accountRepositoryProvider).watchCurrentBalance(account.id);

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => AccountFormScreen(existingAccount: account),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(
            color: account.isActive ? AppColors.border : AppColors.textMuted,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        account.name,
                        style: GoogleFonts.vt323(
                          fontSize: 17,
                          color: account.isActive ? AppColors.textPrimary : AppColors.textMuted,
                        ),
                      ),
                      if (!account.isActive) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          color: AppColors.background,
                          child: Text(
                            'nonaktif',
                            style: GoogleFonts.vt323(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  StreamBuilder<double>(
                    stream: balanceAsync,
                    builder: (context, snapshot) {
                      final balance = snapshot.data ?? account.initialBalance;
                      return Text(
                        CurrencyFormatter.format(balance),
                        style: GoogleFonts.vt323(fontSize: 15, color: AppColors.textSecondary),
                      );
                    },
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}