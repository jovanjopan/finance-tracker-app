class CategoryValidationException implements Exception {
  const CategoryValidationException(this.message);

  final String message;

  @override
  String toString() => 'CategoryValidationException: $message';
}