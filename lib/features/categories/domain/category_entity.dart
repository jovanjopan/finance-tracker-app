class CategoryEntity {
  const CategoryEntity({
    required this.id,
    required this.name,
    required this.transactionType,
    this.expenseClassification,
  });

  final String id;
  final String name;
  final String transactionType;
  final String? expenseClassification;
}