import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../categories/presentation/category_providers.dart';
import '../../transactions/presentation/transaction_providers.dart';
import 'budget_providers.dart';
import 'classification_summary.dart';

class HealthPointPanel extends ConsumerWidget {
  const HealthPointPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetsListProvider);
    final categoriesAsync = ref.watch(categoriesListProvider);
    final transactionsAsync = ref.watch(allTransactionsProvider);

    if (budgetsAsync.isLoading || categoriesAsync.isLoading || transactionsAsync.isLoading) {
      return const SizedBox.shrink();
    }

    if (budgetsAsync.hasError || categoriesAsync.hasError || transactionsAsync.hasError) {
      return const SizedBox.shrink();
    }

    final budgets = budgetsAsync.value ?? [];
    final categories = categoriesAsync.value ?? [];
    final transactions = transactionsAsync.value ?? [];

    final hasAnyClassificationBudget = budgets.any((b) => b.classification != null);
    if (!hasAnyClassificationBudget) {
      return const SizedBox.shrink();
    }

    final summaries = computeClassificationSummaries(
      budgets: budgets,
      categories: categories,
      transactions: transactions,
      referenceDate: DateTime.now(),
    );

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.accentGamify, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'STATUS ALOKASI BULAN INI',
            style: GoogleFonts.pressStart2p(fontSize: 10, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 14),
          for (final summary in summaries) ...[
            _ClassificationBar(summary: summary),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _ClassificationBar extends StatelessWidget {
  const _ClassificationBar({required this.summary});

  final ClassificationSummary summary;

  static const Map<String, String> _labels = {
    'needs': 'KEBUTUHAN (50%)',
    'wants': 'KEINGINAN (30%)',
    'savings': 'TABUNGAN (20%)',
  };

  bool get _isSavings => summary.classification == 'savings';

  Color get _severityColor {
    final percentage = summary.percentageUsed;
    if (percentage >= 0.9) {
      return AppColors.negative;
    }
    if (percentage >= 0.7) {
      return AppColors.accentGamify;
    }
    return AppColors.positive;
  }

  @override
  Widget build(BuildContext context) {
    const segmentCount = 20;

    final int filledSegments;
    final Color barColor;
    final Color textColor;

    if (_isSavings) {
      // Gaya "mengisi": penuh = berhasil disisihkan, kosong = belum ada alokasi.
      filledSegments = summary.target > 0 ? segmentCount : 0;
      barColor = AppColors.positive;
      textColor = summary.target > 0 ? AppColors.positive : AppColors.textMuted;
    } else {
      // Gaya "HP": penuh = aman, berkurang seiring pemakaian, habis = jebol.
      final remainingRatio = (1 - summary.percentageUsed).clamp(0.0, 1.0);
      filledSegments = (remainingRatio * segmentCount).round();
      barColor = _severityColor;
      textColor = summary.percentageUsed >= 0.7 ? _severityColor : AppColors.textMuted;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _labels[summary.classification] ?? summary.classification,
          style: GoogleFonts.vt323(fontSize: 15, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
Row(
          children: List.generate(segmentCount, (index) {
            final isFilled = index < filledSegments;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 14,
                margin: const EdgeInsets.only(right: 1),
                color: isFilled ? barColor : AppColors.background,
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        Text(
          _isSavings
              ? 'tersisihkan: ${CurrencyFormatter.format(summary.target)}'
              : 'terpakai: ${CurrencyFormatter.format(summary.spent)} / ${CurrencyFormatter.format(summary.target)}',
          style: GoogleFonts.vt323(fontSize: 14, color: textColor),
        ),
        if (!_isSavings && summary.isOverBudget)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              '⚠ melebihi ${CurrencyFormatter.format(summary.spent - summary.target)}',
              style: GoogleFonts.vt323(fontSize: 14, color: AppColors.negative),
            ),
          ),
      ],
    );
  }
}