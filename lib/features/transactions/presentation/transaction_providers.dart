import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/database_providers.dart';
import '../domain/transaction_entity.dart';

final allTransactionsProvider = StreamProvider<List<TransactionEntity>>((ref) {
  return ref.watch(transactionRepositoryProvider).watchAllTransactions();
});
