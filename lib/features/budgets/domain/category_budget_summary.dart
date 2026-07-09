import '../../transactions/domain/transaction_entity.dart';
import 'budget_entity.dart';

class CategoryBudgetSummary {
  const CategoryBudgetSummary({
    required this.budget,
    required this.spent,
  });

  final BudgetEntity budget;
  final double spent;

  double get remaining => budget.targetAmount - spent;

  double get percentageUsed {
    if (budget.targetAmount <= 0) {
      return 0.0;
    }
    final ratio = spent / budget.targetAmount;
    return ratio.clamp(0.0, 1.0);
  }

  bool get isOverBudget => spent > budget.targetAmount;
}

/// Menghitung progress untuk setiap budget yang terikat ke kategori
/// spesifik (budget.categoryId != null), berdasarkan expense yang jatuh
/// dalam rentang startDate-endDate budget tersebut.
List<CategoryBudgetSummary> computeCategoryBudgetSummaries({
  required List<BudgetEntity> budgets,
  required List<TransactionEntity> transactions,
}) {
  final categoryBudgets = budgets.where((b) => b.categoryId != null).toList();

  return categoryBudgets.map((budget) {
    final spent = transactions
        .where((t) =>
            t.type == 'expense' &&
            t.categoryId == budget.categoryId &&
            !t.transactionDate.isBefore(budget.startDate) &&
            !t.transactionDate.isAfter(budget.endDate))
        .fold<double>(0.0, (sum, t) => sum + t.amount);

    return CategoryBudgetSummary(budget: budget, spent: spent);
  }).toList();
}