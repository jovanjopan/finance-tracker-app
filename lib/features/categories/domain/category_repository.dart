import 'category_entity.dart';

abstract class CategoryRepository {
  Stream<List<CategoryEntity>> watchAllCategories();

  Future<CategoryEntity?> getCategoryById(String id);

  Future<void> createCategory(CategoryEntity category);

  Future<void> updateCategory(CategoryEntity category);

  Future<void> deleteCategory(String id);
}