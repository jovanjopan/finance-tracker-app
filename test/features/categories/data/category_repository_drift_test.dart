import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myfinancetracker/core/database/app_database.dart';
import 'package:myfinancetracker/features/categories/data/category_repository_drift.dart';
import 'package:myfinancetracker/features/categories/domain/category_entity.dart';

void main() {
  group('CategoryRepositoryDrift', () {
    late AppDatabase database;
    late CategoryRepositoryDrift repository;

    setUp(() {
      database = AppDatabase.forTesting(NativeDatabase.memory());
      repository = CategoryRepositoryDrift(database);
    });

    tearDown(() async {
      await database.close();
    });

    test('create, read, update, delete, and watchAllCategories reactively', () async {
      final category = CategoryEntity(
        id: 'cat-1',
        name: 'Salary',
        transactionType: 'income',
      );

      await repository.createCategory(category);

      final created = await repository.getCategoryById('cat-1');
      expect(created, isNotNull);
      expect(created!.id, 'cat-1');
      expect(created.name, 'Salary');
      expect(created.transactionType, 'income');
      expect(created.expenseClassification, isNull);

      final watchExpectation = expectLater(
        repository.watchAllCategories(),
        emitsInOrder([
          predicate<List<CategoryEntity>>((categories) =>
              categories.length == 1 &&
              categories.single.id == 'cat-1' &&
              categories.single.name == 'Salary' &&
              categories.single.transactionType == 'income' &&
              categories.single.expenseClassification == null),
          predicate<List<CategoryEntity>>((categories) =>
              categories.length == 1 &&
              categories.single.id == 'cat-1' &&
              categories.single.name == 'Main Salary'),
          isEmpty,
        ]),
      );

      await repository.updateCategory(
        const CategoryEntity(
          id: 'cat-1',
          name: 'Main Salary',
          transactionType: 'income',
        ),
      );

      final updated = await repository.getCategoryById('cat-1');
      expect(updated, isNotNull);
      expect(updated!.name, 'Main Salary');

      await repository.deleteCategory('cat-1');

      expect(await repository.getCategoryById('cat-1'), isNull);

      await watchExpectation;
    });

    test('preserves nullable expenseClassification on expense category', () async {
      await repository.createCategory(
        const CategoryEntity(
          id: 'cat-2',
          name: 'Groceries',
          transactionType: 'expense',
          expenseClassification: 'needs',
        ),
      );

      final created = await repository.getCategoryById('cat-2');
      expect(created, isNotNull);
      expect(created!.expenseClassification, 'needs');

      final rows = await database.select(database.categories).get();
      expect(rows, hasLength(1));
      expect(rows.single.expenseClassification, 'needs');
    });
  });
}