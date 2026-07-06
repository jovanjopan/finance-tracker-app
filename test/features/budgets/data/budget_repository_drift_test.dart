import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myfinancetracker/core/database/app_database.dart';
import 'package:myfinancetracker/features/budgets/data/budget_repository_drift.dart';
import 'package:myfinancetracker/features/budgets/domain/budget_entity.dart';

void main() {
  group('BudgetRepositoryDrift', () {
    late AppDatabase database;
    late BudgetRepositoryDrift repository;

    setUp(() {
      database = AppDatabase.forTesting(NativeDatabase.memory());
      repository = BudgetRepositoryDrift(database);
    });

    tearDown(() async {
      await database.close();
    });

    test('create, read, update, delete, and watchAllBudgets reactively', () async {
      final budget = BudgetEntity(
        id: 'budget-1',
        categoryId: 'cat-1',
        targetAmount: 500000.0,
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 1, 31),
      );

      await repository.createBudget(budget);

      final created = await repository.getBudgetById('budget-1');
      expect(created, isNotNull);
      expect(created!.id, 'budget-1');
      expect(created.categoryId, 'cat-1');
      expect(created.targetAmount, 500000.0);
      expect(created.startDate, DateTime(2026, 1, 1));
      expect(created.endDate, DateTime(2026, 1, 31));

      final watchExpectation = expectLater(
        repository.watchAllBudgets(),
        emitsInOrder([
          predicate<List<BudgetEntity>>((budgets) =>
              budgets.length == 1 &&
              budgets.single.id == 'budget-1' &&
              budgets.single.targetAmount == 500000.0),
          predicate<List<BudgetEntity>>((budgets) =>
              budgets.length == 1 &&
              budgets.single.id == 'budget-1' &&
              budgets.single.targetAmount == 750000.0),
          isEmpty,
        ]),
      );

      await repository.updateBudget(
        BudgetEntity(
          id: 'budget-1',
          categoryId: 'cat-1',
          targetAmount: 750000.0,
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 1, 31),
        ),
      );

      final updated = await repository.getBudgetById('budget-1');
      expect(updated, isNotNull);
      expect(updated!.targetAmount, 750000.0);

      await repository.deleteBudget('budget-1');

      expect(await repository.getBudgetById('budget-1'), isNull);

      await watchExpectation;
    });
  });
}