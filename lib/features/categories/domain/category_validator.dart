import 'category_entity.dart';
import 'category_validation_exception.dart';

class CategoryValidator {
  const CategoryValidator();

  static void validate(CategoryEntity category) {
    if (category.transactionType == 'income' &&
        category.expenseClassification != null) {
      throw const CategoryValidationException(
        'expenseClassification must be null for income categories.',
      );
    }
  }

  void call(CategoryEntity category) {
    validate(category);
  }
}