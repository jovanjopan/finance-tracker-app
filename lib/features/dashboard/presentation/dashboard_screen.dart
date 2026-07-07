import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../transactions/domain/transaction_entity.dart';
import 'dashboard_providers.dart';

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
              'koinku',
              style: GoogleFonts.pressStart2p(
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
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
                  Text(
                    'total saldo',
                    style: GoogleFonts.vt323(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  totalBalanceAsync.when(
                    data: (value) => Text(
                      CurrencyFormatter.format(value),
                      style: GoogleFonts.pressStart2p(
                        fontSize: 18,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    loading: () => Text(
                      '...',
                      style: GoogleFonts.pressStart2p(
                        fontSize: 18,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    error: (error, stackTrace) => Text(
                      'gagal memuat saldo',
                      style: GoogleFonts.vt323(
                        fontSize: 16,
                        color: AppColors.negative,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  accountsAsync.when(
                    data: (accounts) => Text(
                      '${accounts.length} akun',
                      style: GoogleFonts.vt323(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (error, stackTrace) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'transaksi terakhir',
              style: GoogleFonts.vt323(
                fontSize: 18,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            transactionsAsync.when(
              data: (transactions) {
                if (transactions.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'belum ada transaksi',
                      style: GoogleFonts.vt323(
                        fontSize: 16,
                        color: AppColors.textMuted,
                      ),
                    ),
                  );
                }
                final recent = transactions.take(5).toList();
                return Column(
                  children: recent
                      .map((transaction) => _TransactionTile(transaction: transaction))
                      .toList(),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
              error: (error, stackTrace) => Text(
                'gagal memuat transaksi',
                style: GoogleFonts.vt323(
                  fontSize: 16,
                  color: AppColors.negative,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction});

  final TransactionEntity transaction;

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == 'income';
    final isExpense = transaction.type == 'expense';

    final Color amountColor = isIncome
        ? AppColors.positive
        : isExpense
            ? AppColors.negative
            : AppColors.textPrimary;

    final String sign = isIncome ? '+' : (isExpense ? '-' : '');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      color: AppColors.surface,
      child: Row(
        children: [
          Expanded(
            child: Text(
              transaction.type,
              style: GoogleFonts.vt323(fontSize: 15, color: AppColors.textPrimary),
            ),
          ),
          Text(
            '$sign${CurrencyFormatter.format(transaction.amount)}',
            style: GoogleFonts.vt323(fontSize: 16, color: amountColor),
          ),
        ],
      ),
    );
  }
}