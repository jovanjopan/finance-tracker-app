import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/providers/navigation_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../categories/presentation/category_providers.dart';
import '../../transactions/presentation/transaction_providers.dart';
import 'budget_providers.dart';
import 'classification_summary.dart';

class HealthPointSummaryStrip extends ConsumerWidget {
  const HealthPointSummaryStrip({super.key});

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

    return InkWell(
      onTap: () => ref.read(selectedTabIndexProvider.notifier).state = 2,
      child: Container(
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('STATUS ALOKASI', style: GoogleFonts.pressStart2p(fontSize: 10, color: AppColors.textPrimary)),
                const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: summaries.map((summary) {
                final color = summary.classification == 'savings'
                    ? AppColors.positive
                    : summary.percentageUsed >= 0.9
                        ? AppColors.negative
                        : summary.percentageUsed >= 0.7
                            ? AppColors.accentGamify
                            : AppColors.positive;
                final label = switch (summary.classification) {
                  'needs' => 'kebutuhan',
                  'wants' => 'keinginan',
                  _ => 'tabungan',
                };
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      children: [
                        Container(height: 8, color: color),
                        const SizedBox(height: 4),
                        Text(label, style: GoogleFonts.vt323(fontSize: 12, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}