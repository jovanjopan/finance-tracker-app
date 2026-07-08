import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:myfinancetracker/core/providers/database_providers.dart';
import 'package:myfinancetracker/features/budgets/domain/budget_entity.dart';

final budgetsListProvider = StreamProvider<List<BudgetEntity>>((ref) {
  return ref.watch(budgetRepositoryProvider).watchAllBudgets();
});