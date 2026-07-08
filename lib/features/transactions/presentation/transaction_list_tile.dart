import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../categories/presentation/category_providers.dart';
import '../domain/transaction_entity.dart';
import 'add_transaction_screen.dart';

class TransactionListTile extends ConsumerWidget {
  const TransactionListTile({super.key, required this.transaction});

  final TransactionEntity transaction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesListProvider);

    final isIncome = transaction.type == 'income';
    final isExpense = transaction.type == 'expense';

    final Color amountColor = isIncome
        ? AppColors.positive
        : isExpense
            ? AppColors.negative
            : AppColors.textPrimary;

    final String sign = isIncome ? '+' : (isExpense ? '-' : '');

    final String categoryLabel = categoriesAsync.maybeWhen(
      data: (categories) {
        if (transaction.categoryId == null) {
          return _fallbackTypeLabel(transaction.type);
        }
        final match = categories.where((c) => c.id == transaction.categoryId);
        return match.isEmpty ? _fallbackTypeLabel(transaction.type) : match.first.name;
      },
      orElse: () => _fallbackTypeLabel(transaction.type),
    );

    final String? noteLabel = transaction.note?.trim().isNotEmpty == true
        ? transaction.note!.trim()
        : null;

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => AddTransactionScreen(existingTransaction: transaction),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        color: AppColors.surface,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    categoryLabel,
                    style: GoogleFonts.vt323(fontSize: 15, color: AppColors.textPrimary),
                  ),
                  if (noteLabel != null)
                    Text(
                      noteLabel,
                      style: GoogleFonts.vt323(fontSize: 13, color: AppColors.textMuted),
                    ),
                ],
              ),
            ),
            Text(
              '$sign${CurrencyFormatter.format(transaction.amount)}',
              style: GoogleFonts.vt323(fontSize: 16, color: amountColor),
            ),
          ],
        ),
      ),
    );
  }

  String _fallbackTypeLabel(String type) {
    switch (type) {
      case 'income':
        return 'pemasukan';
      case 'expense':
        return 'pengeluaran';
      case 'transfer':
        return 'transfer';
      default:
        return type;
    }
  }
}