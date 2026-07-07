import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/database_providers.dart';
import '../domain/account_entity.dart';

final accountsListProvider = StreamProvider<List<AccountEntity>>((ref) {
  return ref.watch(accountRepositoryProvider).watchAllAccounts();
});