import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/providers/navigation_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../budgets/presentation/health_point_summary_strip.dart';
import '../../forecasting/presentation/burn_rate_panel.dart';
import '../../transactions/presentation/transaction_list_tile.dart';
import 'dashboard_providers.dart';
import '../../../core/widgets/animated_currency_text.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/pixel_loading_indicator.dart';



class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalBalanceAsync = ref.watch(totalBalanceProvider);
    final accountsAsync = ref.watch(accountsListProvider);
    final transactionsAsync = ref.watch(allTransactionsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'MyDuit',
              style: GoogleFonts.pressStart2p(fontSize: 16, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.border, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('total saldo', style: GoogleFonts.vt323(fontSize: 15, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
totalBalanceAsync.when(
                    data: (value) => AnimatedCurrencyText(
                      value: value,
                      style: GoogleFonts.pressStart2p(fontSize: 18, color: AppColors.textPrimary),
                    ),
                    loading: () => Text('...', style: GoogleFonts.pressStart2p(fontSize: 18, color: AppColors.textPrimary)),
                    error: (error, stackTrace) => Text(
                      'gagal memuat saldo',
                      style: GoogleFonts.vt323(fontSize: 16, color: AppColors.negative),
                    ),
                  ),
                  const SizedBox(height: 10),
                  accountsAsync.when(
                    data: (accounts) => Text(
                      '${accounts.length} akun',
                      style: GoogleFonts.vt323(fontSize: 15, color: AppColors.textSecondary),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (error, stackTrace) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const HealthPointSummaryStrip(),
            const BurnRatePanel(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('transaksi terakhir', style: GoogleFonts.vt323(fontSize: 18, color: AppColors.textPrimary)),
                InkWell(
                  onTap: () => ref.read(selectedTabIndexProvider.notifier).changeIndex(1),
                  child: Text('lihat semua', style: GoogleFonts.vt323(fontSize: 15, color: AppColors.primary)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            transactionsAsync.when(
              data: (transactions) {
if (transactions.isEmpty) {
                  return const EmptyState(
                    icon: Icons.receipt_long_outlined,
                    message: 'belum ada transaksi',
                  );
                }
                final recent = transactions.take(5).toList();
                return Column(
                  children: recent.map((t) => TransactionListTile(transaction: t)).toList(),
                );
              },
loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: PixelLoadingIndicator()),
              ),
              error: (error, stackTrace) => Text(
                'gagal memuat transaksi',
                style: GoogleFonts.vt323(fontSize: 16, color: AppColors.negative),
              ),
            ),
          ],
        ),
      ),
    );
  }
}