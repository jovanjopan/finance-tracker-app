import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../dashboard/presentation/dashboard_providers.dart';
import '../domain/burn_rate_forecast.dart';

class BurnRatePanel extends ConsumerWidget {
  const BurnRatePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalBalanceAsync = ref.watch(totalBalanceProvider);
    final transactionsAsync = ref.watch(allTransactionsProvider);

    if (totalBalanceAsync.isLoading || transactionsAsync.isLoading) {
      return const SizedBox.shrink();
    }
    if (totalBalanceAsync.hasError || transactionsAsync.hasError) {
      return const SizedBox.shrink();
    }

    final transactions = transactionsAsync.value ?? [];
    if (transactions.isEmpty) {
      return const SizedBox.shrink();
    }

    final currentBalance = totalBalanceAsync.value ?? 0.0;
    final forecast = computeBurnRateForecast(
      transactions: transactions,
      currentBalance: currentBalance,
      referenceDate: DateTime.now(),
    );

    final statusColor = _colorFor(forecast.status);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PREDIKSI PENGELUARAN',
            style: GoogleFonts.pressStart2p(fontSize: 10, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          Text('kecepatan pengeluaran', style: GoogleFonts.vt323(fontSize: 14, color: AppColors.textSecondary)),
          Text(
            '${CurrencyFormatter.format(forecast.dailyBurnRate)}/hari',
            style: GoogleFonts.vt323(fontSize: 17, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(_iconFor(forecast.status), size: 18, color: statusColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _messageFor(forecast),
                  style: GoogleFonts.vt323(fontSize: 15, color: statusColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _colorFor(BurnRateStatus status) {
    switch (status) {
      case BurnRateStatus.atRisk:
        return AppColors.negative;
      case BurnRateStatus.safeThisMonth:
      case BurnRateStatus.safeLongTerm:
      case BurnRateStatus.noRecentSpending:
        return AppColors.positive;
    }
  }

  IconData _iconFor(BurnRateStatus status) {
    switch (status) {
      case BurnRateStatus.atRisk:
        return Icons.warning_amber_rounded;
      case BurnRateStatus.safeThisMonth:
      case BurnRateStatus.safeLongTerm:
      case BurnRateStatus.noRecentSpending:
        return Icons.check_circle_outline;
    }
  }

  String _messageFor(BurnRateForecast forecast) {
    switch (forecast.status) {
      case BurnRateStatus.noRecentSpending:
        return 'belum ada pengeluaran belakangan ini, aman';
      case BurnRateStatus.safeLongTerm:
        return 'dengan kecepatan sekarang, saldo aman untuk jangka panjang';
      case BurnRateStatus.safeThisMonth:
        return 'dengan kecepatan sekarang, saldo diperkirakan bertahan hingga ${DateFormatter.format(forecast.projectedDepletionDate!)}';
      case BurnRateStatus.atRisk:
        return 'waspada, dengan kecepatan sekarang saldo diperkirakan habis pada ${DateFormatter.format(forecast.projectedDepletionDate!)}';
    }
  }
}