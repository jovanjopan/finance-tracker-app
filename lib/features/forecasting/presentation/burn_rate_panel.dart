import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
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

    final statusColor = forecast.willSurvive ? AppColors.positive : AppColors.negative;

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
          _InfoRow(
            label: 'kecepatan pengeluaran',
            value: '${CurrencyFormatter.format(forecast.dailyBurnRate)}/hari',
            valueColor: AppColors.textPrimary,
          ),
          const SizedBox(height: 10),
          _InfoRow(
            label: 'proyeksi saldo akhir bulan',
            value: CurrencyFormatter.format(forecast.projectedEndOfMonthBalance),
            valueColor: statusColor,
          ),
          const SizedBox(height: 10),
Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                forecast.willSurvive ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                size: 18,
                color: statusColor,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  forecast.willSurvive
                      ? 'aman, saldo diperkirakan cukup sampai akhir bulan'
                      : 'waspada, saldo diperkirakan tidak cukup sampai akhir bulan',
                  style: GoogleFonts.vt323(fontSize: 15, color: statusColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.vt323(fontSize: 14, color: AppColors.textSecondary)),
        Text(value, style: GoogleFonts.vt323(fontSize: 17, color: valueColor)),
      ],
    );
  }
}
