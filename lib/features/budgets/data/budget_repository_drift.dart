import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/budget_entity.dart';
import '../domain/budget_repository.dart';

class BudgetRepositoryDrift implements BudgetRepository {
  BudgetRepositoryDrift(this._database);

  final AppDatabase _database;

  @override
  Stream<List<BudgetEntity>> watchAllBudgets() {
    return _database.select(_database.budgets).watch().map(
          (rows) => rows.map(_toEntity).toList(growable: false),
        );
  }

  @override
  Future<BudgetEntity?> getBudgetById(String id) async {
    final row = await (_database.select(_database.budgets)
          ..where((table) => table.id.equals(id)))
        .getSingleOrNull();

    if (row == null) {
      return null;
    }

    return _toEntity(row);
  }

  @override
  Future<void> createBudget(BudgetEntity budget) {
    return _database.into(_database.budgets).insert(_toCompanion(budget));
  }

  @override
  Future<void> updateBudget(BudgetEntity budget) {
    return (_database.update(_database.budgets)
          ..where((table) => table.id.equals(budget.id)))
        .write(_toCompanion(budget));
  }

  @override
  Future<void> deleteBudget(String id) {
    return (_database.delete(_database.budgets)..where((table) => table.id.equals(id))).go();
  }

  @override
  Future<BudgetEntity?> getClassificationBudgetForDate(
    String classification,
    DateTime date,
  ) async {
    final row = await (_database.select(_database.budgets)
          ..where(
            (table) =>
                table.classification.equals(classification) &
                table.startDate.isSmallerOrEqualValue(date) &
                table.endDate.isBiggerOrEqualValue(date),
          ))
        .getSingleOrNull();

    return row == null ? null : _toEntity(row);
  }

  BudgetEntity _toEntity(Budget row) {
    return BudgetEntity(
      id: row.id,
      categoryId: row.categoryId,
      classification: row.classification,
      targetAmount: row.targetAmount,
      startDate: row.startDate,
      endDate: row.endDate,
    );
  }

  BudgetsCompanion _toCompanion(BudgetEntity budget) {
    return BudgetsCompanion(
      id: Value(budget.id),
      categoryId: budget.categoryId == null
          ? const Value.absent()
          : Value<String?>(budget.categoryId),
      classification: budget.classification == null
          ? const Value.absent()
          : Value<String?>(budget.classification),
      targetAmount: Value(budget.targetAmount),
      startDate: Value(budget.startDate),
      endDate: Value(budget.endDate),
    );
  }
}