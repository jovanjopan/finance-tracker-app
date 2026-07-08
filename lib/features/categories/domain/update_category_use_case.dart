import 'category_entity.dart';
import 'category_repository.dart';
import 'category_validation_exception.dart';
import 'category_validator.dart';

class UpdateCategoryUseCase {
  UpdateCategoryUseCase({required CategoryRepository categoryRepository})
      : _categoryRepository = categoryRepository;

  final CategoryRepository _categoryRepository;

  Future<void> execute(CategoryEntity category) async {
    if (category.name.trim().isEmpty) {
      throw const CategoryValidationException('nama kategori wajib diisi');
    }
    CategoryValidator.validate(category);
    await _categoryRepository.updateCategory(category);
  }
}