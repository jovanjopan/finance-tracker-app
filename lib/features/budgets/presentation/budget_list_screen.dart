import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../categories/presentation/category_providers.dart';
import '../../transactions/presentation/transaction_providers.dart';
import '../domain/category_budget_summary.dart';
import 'budget_form_screen.dart';
import 'budget_providers.dart';

class BudgetListScreen extends ConsumerWidget {
  const BudgetListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetsListProvider);
    final transactionsAsync = ref.watch(allTransactionsProvider);
    final categoriesAsync = ref.watch(categoriesListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accentGamify,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const BudgetFormScreen()),
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
                    'budget kategori',
                    style: GoogleFonts.pressStart2p(fontSize: 12, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
            Expanded(
              child: budgetsAsync.when(
                data: (budgets) {
                  return transactionsAsync.when(
                    data: (transactions) {
                      return categoriesAsync.when(
                        data: (categories) {
                          final summaries = computeCategoryBudgetSummaries(
                            budgets: budgets,
                            transactions: transactions,
                          );

                          if (summaries.isEmpty) {
                            return Center(
                              child: Text(
                                'belum ada budget kategori.\ntekan + untuk membuat.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.vt323(fontSize: 16, color: AppColors.textMuted),
                              ),
                            );
                          }

                          final categoryNameById = {
                            for (final category in categories) category.id: category.name,
                          };

                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: summaries.length,
                            itemBuilder: (context, index) {
                              final summary = summaries[index];
                              final categoryName =
                                  categoryNameById[summary.budget.categoryId] ?? 'kategori tidak dikenal';
                              return _BudgetTile(summary: summary, categoryName: categoryName);
                            },
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                        error: (error, stackTrace) => const SizedBox.shrink(),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                    error: (error, stackTrace) => const SizedBox.shrink(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                error: (error, stackTrace) => Center(
                  child: Text(
                    'gagal memuat budget',
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

class _BudgetTile extends StatelessWidget {
  const _BudgetTile({required this.summary, required this.categoryName});

  final CategoryBudgetSummary summary;
  final String categoryName;

  Color get _barColor {
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
    const segmentCount = 16;
    final remainingRatio = (1 - summary.percentageUsed).clamp(0.0, 1.0);
    final filledSegments = (remainingRatio * segmentCount).round();
    final barColor = _barColor;

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => BudgetFormScreen(existingBudget: summary.budget),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(categoryName, style: GoogleFonts.vt323(fontSize: 17, color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            Row(
              children: List.generate(segmentCount, (index) {
                final isFilled = index < filledSegments;
                return Expanded(
                  child: Container(
                    height: 12,
                    margin: const EdgeInsets.only(right: 1),
                    color: isFilled ? barColor : AppColors.background,
                  ),
                );
              }),
            ),
            const SizedBox(height: 4),
            Text(
              'terpakai: ${CurrencyFormatter.format(summary.spent)} / ${CurrencyFormatter.format(summary.budget.targetAmount)}',
              style: GoogleFonts.vt323(
                fontSize: 14,
                color: summary.percentageUsed >= 0.7 ? barColor : AppColors.textMuted,
              ),
            ),
            if (summary.isOverBudget)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '⚠ melebihi ${CurrencyFormatter.format(summary.spent - summary.budget.targetAmount)}',
                  style: GoogleFonts.vt323(fontSize: 14, color: AppColors.negative),
                ),
              ),
          ],
        ),
      ),
    );
  }
}