import 'budget_entity.dart';

abstract class BudgetRepository {
  Stream<List<BudgetEntity>> watchAllBudgets();

  Future<BudgetEntity?> getBudgetById(String id);

  Future<void> createBudget(BudgetEntity budget);

  Future<void> updateBudget(BudgetEntity budget);

  Future<void> deleteBudget(String id);

  /// Mencari BUDGET dengan classification tertentu yang periodenya
  /// (startDate–endDate) mencakup [date]. Dipakai oleh
  /// AllocateIncomeUseCase untuk logic "cari atau buat, lalu tambahkan".
  Future<BudgetEntity?> getClassificationBudgetForDate(
    String classification,
    DateTime date,
  );
}