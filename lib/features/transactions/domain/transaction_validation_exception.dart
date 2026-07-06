class TransactionValidationException implements Exception {
  const TransactionValidationException(this.message);

  final String message;

  @override
  String toString() => 'TransactionValidationException: $message';
}