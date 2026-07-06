import 'transaction_entity.dart';
import 'transaction_validation_exception.dart';

class TransactionValidator {
  const TransactionValidator();

  static void validate(TransactionEntity transaction) {
    final type = transaction.type;

    if (type == 'income' || type == 'expense') {
      if (transaction.categoryId == null) {
        throw const TransactionValidationException(
          'categoryId is required for income and expense transactions.',
        );
      }

      if (transaction.toAccountId != null) {
        throw const TransactionValidationException(
          'toAccountId must be null for income and expense transactions.',
        );
      }

      return;
    }

    if (type == 'transfer') {
      if (transaction.categoryId != null) {
        throw const TransactionValidationException(
          'categoryId must be null for transfer transactions.',
        );
      }

      if (transaction.toAccountId == null) {
        throw const TransactionValidationException(
          'toAccountId is required for transfer transactions.',
        );
      }

      return;
    }

    throw const TransactionValidationException(
      'type must be one of income, expense, or transfer.',
    );
  }

  void call(TransactionEntity transaction) {
    validate(transaction);
  }
}