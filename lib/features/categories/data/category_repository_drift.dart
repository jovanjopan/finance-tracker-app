import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/category_entity.dart';
import '../domain/category_repository.dart';

class CategoryRepositoryDrift implements CategoryRepository {
  CategoryRepositoryDrift(this._database);

  final AppDatabase _database;

  @override
  Stream<List<CategoryEntity>> watchAllCategories() {
    return _database.select(_database.categories).watch().map(
          (rows) => rows.map(_toEntity).toList(growable: false),
        );
  }

  @override
  Future<CategoryEntity?> getCategoryById(String id) async {
    final row = await (_database.select(_database.categories)
          ..where((table) => table.id.equals(id)))
        .getSingleOrNull();

    if (row == null) {
      return null;
    }

    return _toEntity(row);
  }

  @override
  Future<void> createCategory(CategoryEntity category) {
    return _database.into(_database.categories).insert(_toCompanion(category));
  }

  @override
  Future<void> updateCategory(CategoryEntity category) {
    return (_database.update(_database.categories)
          ..where((table) => table.id.equals(category.id)))
        .write(_toCompanion(category));
  }

  @override
  Future<void> deleteCategory(String id) {
    return (_database.delete(_database.categories)..where((table) => table.id.equals(id))).go();
  }

  CategoryEntity _toEntity(Category row) {
    return CategoryEntity(
      id: row.id,
      name: row.name,
      transactionType: row.transactionType,
      expenseClassification: row.expenseClassification,
    );
  }

  CategoriesCompanion _toCompanion(CategoryEntity category) {
    return CategoriesCompanion(
      id: Value(category.id),
      name: Value(category.name),
      transactionType: Value(category.transactionType),
      expenseClassification: category.expenseClassification == null
          ? const Value.absent()
          : Value<String?>(category.expenseClassification),
    );
  }
}