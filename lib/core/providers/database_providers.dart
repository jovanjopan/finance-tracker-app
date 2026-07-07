import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../../features/accounts/data/account_repository_drift.dart';
import '../../features/accounts/domain/account_repository.dart';
import '../../features/transactions/data/transaction_repository_drift.dart';
import '../../features/transactions/domain/transaction_repository.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return AccountRepositoryDrift(database);
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return TransactionRepositoryDrift(database);
});