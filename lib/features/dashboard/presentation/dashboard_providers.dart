import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../accounts/domain/account_entity.dart';
import '../../accounts/presentation/account_providers.dart';
import '../../transactions/domain/transaction_entity.dart';
import '../../transactions/presentation/transaction_providers.dart';

export '../../accounts/presentation/account_providers.dart';
export '../../transactions/presentation/transaction_providers.dart';

final totalBalanceProvider = Provider<AsyncValue<double>>((ref) {
  final accountsAsync = ref.watch(accountsListProvider);
  final transactionsAsync = ref.watch(allTransactionsProvider);

  if (accountsAsync.isLoading || transactionsAsync.isLoading) {
    return const AsyncValue.loading();
  }

  if (accountsAsync.hasError) {
    return AsyncValue.error(
      accountsAsync.error!,
      accountsAsync.stackTrace ?? StackTrace.current,
    );
  }

  if (transactionsAsync.hasError) {
    return AsyncValue.error(
      transactionsAsync.error!,
      transactionsAsync.stackTrace ?? StackTrace.current,
    );
  }

  final accounts = accountsAsync.value ?? const <AccountEntity>[];
  final transactions = transactionsAsync.value ?? const <TransactionEntity>[];

  final activeAccountIds = accounts
      .where((account) => account.isActive)
      .map((account) => account.id)
      .toSet();

  var total = accounts
      .where((account) => account.isActive)
      .fold<double>(0.0, (sum, account) => sum + account.initialBalance);

  for (final transaction in transactions) {
    if (!activeAccountIds.contains(transaction.accountId)) {
      continue;
    }
    if (transaction.type == 'income') {
      total += transaction.amount;
    } else if (transaction.type == 'expense') {
      total -= transaction.amount;
    }
  }

  return AsyncValue.data(total);
});