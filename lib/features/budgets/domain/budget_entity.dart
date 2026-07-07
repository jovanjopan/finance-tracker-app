class BudgetEntity {
  const BudgetEntity({
    required this.id,
    this.categoryId,
    this.classification,
    required this.targetAmount,
    required this.startDate,
    required this.endDate,
  });

  final String id;
  final String? categoryId;
  final String? classification;
  final double targetAmount;
  final DateTime startDate;
  final DateTime endDate;
}