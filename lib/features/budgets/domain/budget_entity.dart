class BudgetEntity {
  const BudgetEntity({
    required this.id,
    required this.categoryId,
    required this.targetAmount,
    required this.startDate,
    required this.endDate,
  });

  final String id;
  final String categoryId;
  final double targetAmount;
  final DateTime startDate;
  final DateTime endDate;
}