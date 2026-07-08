import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../accounts/presentation/account_providers.dart';
import '../domain/transaction_entity.dart';
import 'transaction_list_tile.dart';
import 'transaction_providers.dart';

class TransactionListScreen extends ConsumerStatefulWidget {
  const TransactionListScreen({super.key});

  @override
  ConsumerState<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends ConsumerState<TransactionListScreen> {
  String _typeFilter = 'all'; // all, income, expense, transfer
  String? _accountFilter; // null = semua akun

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(allTransactionsProvider);
    final accountsAsync = ref.watch(accountsListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
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
                    'semua transaksi',
                    style: GoogleFonts.pressStart2p(fontSize: 12, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'semua',
                      isActive: _typeFilter == 'all',
                      onTap: () => setState(() => _typeFilter = 'all'),
                    ),
                    _FilterChip(
                      label: 'masuk',
                      isActive: _typeFilter == 'income',
                      onTap: () => setState(() => _typeFilter = 'income'),
                    ),
                    _FilterChip(
                      label: 'keluar',
                      isActive: _typeFilter == 'expense',
                      onTap: () => setState(() => _typeFilter = 'expense'),
                    ),
                    _FilterChip(
                      label: 'transfer',
                      isActive: _typeFilter == 'transfer',
                      onTap: () => setState(() => _typeFilter = 'transfer'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: accountsAsync.when(
                data: (accounts) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.border, width: 2),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: _accountFilter,
                        isExpanded: true,
                        hint: Text('semua akun', style: GoogleFonts.vt323(fontSize: 16, color: AppColors.textMuted)),
                        dropdownColor: AppColors.surface,
                        style: GoogleFonts.vt323(fontSize: 16, color: AppColors.textPrimary),
                        icon: const Icon(Icons.arrow_drop_down, color: AppColors.textMuted),
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text('semua akun', style: GoogleFonts.vt323(fontSize: 16, color: AppColors.textPrimary)),
                          ),
                          ...accounts.map(
                            (a) => DropdownMenuItem<String?>(
                              value: a.id,
                              child: Text(a.name),
                            ),
                          ),
                        ],
                        onChanged: (value) => setState(() => _accountFilter = value),
                      ),
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (error, stackTrace) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: transactionsAsync.when(
                data: (transactions) {
                  final filtered = _applyFilters(transactions);

                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        'tidak ada transaksi yang cocok',
                        style: GoogleFonts.vt323(fontSize: 16, color: AppColors.textMuted),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return TransactionListTile(transaction: filtered[index]);
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (error, stackTrace) => Center(
                  child: Text(
                    'gagal memuat transaksi',
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

  List<TransactionEntity> _applyFilters(List<TransactionEntity> transactions) {
    return transactions.where((transaction) {
      final matchesType = _typeFilter == 'all' || transaction.type == _typeFilter;
      final matchesAccount = _accountFilter == null ||
          transaction.accountId == _accountFilter ||
          transaction.toAccountId == _accountFilter;
      return matchesType && matchesAccount;
    }).toList();
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? AppColors.accentGamify : AppColors.surface,
            border: Border.all(color: AppColors.border, width: 2),
          ),
          child: Text(
            label,
            style: GoogleFonts.vt323(
              fontSize: 15,
              color: isActive ? AppColors.background : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}