import 'budget_entity.dart';
import 'budget_validation_exception.dart';

class BudgetValidator {
  const BudgetValidator();

  static const Set<String> _validClassifications = {'needs', 'wants', 'savings'};

  static void validate(BudgetEntity budget) {
    final hasCategory = budget.categoryId != null;
    final hasClassification = budget.classification != null;

    if (hasCategory == hasClassification) {
      throw const BudgetValidationException(
        'Budget must have exactly one of categoryId or classification, not both or neither.',
      );
    }

    if (hasClassification && !_validClassifications.contains(budget.classification)) {
      throw const BudgetValidationException(
        'classification must be one of: needs, wants, savings.',
      );
    }
  }

  void call(BudgetEntity budget) => validate(budget);
}