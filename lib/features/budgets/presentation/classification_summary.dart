import 'package:myfinancetracker/features/budgets/domain/budget_entity.dart';
import 'package:myfinancetracker/features/categories/domain/category_entity.dart';
import 'package:myfinancetracker/features/transactions/domain/transaction_entity.dart';

class ClassificationSummary {
  const ClassificationSummary({
    required this.classification,
    required this.target,
    required this.spent,
  });

  final String classification;
  final double target;
  final double spent;

  double get remaining => target - spent;

  double get percentageUsed {
    if (target <= 0) {
      return 0.0;
    }
    final ratio = spent / target;
    return ratio.clamp(0.0, 1.0);
  }

  bool get isOverBudget => spent > target;
}

const List<String> classificationOrder = ['needs', 'wants', 'savings'];

List<ClassificationSummary> computeClassificationSummaries({
  required List<BudgetEntity> budgets,
  required List<CategoryEntity> categories,
  required List<TransactionEntity> transactions,
  required DateTime referenceDate,
}) {
  final categoryClassificationById = <String, String?>{
    for (final category in categories) category.id: category.expenseClassification,
  };

  return classificationOrder.map((classification) {
    final matchingBudget = budgets.where((budget) {
      return budget.classification == classification &&
          !referenceDate.isBefore(budget.startDate) &&
          !referenceDate.isAfter(budget.endDate);
    });

    final target = matchingBudget.isEmpty ? 0.0 : matchingBudget.first.targetAmount;

    double spent = 0.0;
    if (classification != 'savings') {
      for (final transaction in transactions) {
        if (transaction.type != 'expense') {
          continue;
        }
        if (transaction.transactionDate.year != referenceDate.year ||
            transaction.transactionDate.month != referenceDate.month) {
          continue;
        }
        final categoryClassification = categoryClassificationById[transaction.categoryId];
        if (categoryClassification == classification) {
          spent += transaction.amount;
        }
      }
    }

    return ClassificationSummary(
      classification: classification,
      target: target,
      spent: spent,
    );
  }).toList();
}