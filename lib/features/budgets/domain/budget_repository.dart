import 'budget_entity.dart';

abstract class BudgetRepository {
  Stream<List<BudgetEntity>> watchAllBudgets();

  Future<BudgetEntity?> getBudgetById(String id);

  Future<void> createBudget(BudgetEntity budget);

  Future<void> updateBudget(BudgetEntity budget);

  Future<void> deleteBudget(String id);
}