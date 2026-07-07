class BudgetValidationException implements Exception {
  const BudgetValidationException(this.message);

  final String message;

  @override
  String toString() => 'BudgetValidationException: $message';
}