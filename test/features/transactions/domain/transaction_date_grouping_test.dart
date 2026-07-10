import 'package:flutter_test/flutter_test.dart';
import 'package:myfinancetracker/features/transactions/domain/transaction_date_grouping.dart';
import 'package:myfinancetracker/features/transactions/domain/transaction_entity.dart';

void main() {
  group('groupTransactionsByDate', () {
    test('labels today and yesterday correctly, others use formatted date', () {
      final referenceDate = DateTime(2026, 7, 10);

      final transactions = [
        TransactionEntity(
          id: 'tx1',
          type: 'expense',
          amount: 10000,
          transactionDate: DateTime(2026, 7, 10),
          accountId: 'acc-1',
          categoryId: 'cat-1',
        ),
        TransactionEntity(
          id: 'tx2',
          type: 'expense',
          amount: 20000,
          transactionDate: DateTime(2026, 7, 9),
          accountId: 'acc-1',
          categoryId: 'cat-1',
        ),
        TransactionEntity(
          id: 'tx3',
          type: 'expense',
          amount: 30000,
          transactionDate: DateTime(2026, 7, 5),
          accountId: 'acc-1',
          categoryId: 'cat-1',
        ),
      ];

      final groups = groupTransactionsByDate(transactions, referenceDate: referenceDate);

      expect(groups, hasLength(3));
      expect(groups[0].label, startsWith('hari ini'));
      expect(groups[1].label, startsWith('kemarin'));
      expect(groups[2].label, '5 juli 2026');
    });

    test('groups descending by date, most recent first', () {
      final referenceDate = DateTime(2026, 7, 10);

      final transactions = [
        TransactionEntity(
          id: 'tx1',
          type: 'expense',
          amount: 10000,
          transactionDate: DateTime(2026, 7, 3),
          accountId: 'acc-1',
          categoryId: 'cat-1',
        ),
        TransactionEntity(
          id: 'tx2',
          type: 'expense',
          amount: 20000,
          transactionDate: DateTime(2026, 7, 8),
          accountId: 'acc-1',
          categoryId: 'cat-1',
        ),
      ];

      final groups = groupTransactionsByDate(transactions, referenceDate: referenceDate);

      expect(groups[0].date, DateTime(2026, 7, 8));
      expect(groups[1].date, DateTime(2026, 7, 3));
    });

    test('multiple transactions on the same day are grouped together', () {
      final referenceDate = DateTime(2026, 7, 10);

      final transactions = [
        TransactionEntity(
          id: 'tx1',
          type: 'expense',
          amount: 10000,
          transactionDate: DateTime(2026, 7, 10, 8),
          accountId: 'acc-1',
          categoryId: 'cat-1',
        ),
        TransactionEntity(
          id: 'tx2',
          type: 'expense',
          amount: 20000,
          transactionDate: DateTime(2026, 7, 10, 20),
          accountId: 'acc-1',
          categoryId: 'cat-1',
        ),
      ];

      final groups = groupTransactionsByDate(transactions, referenceDate: referenceDate);

      expect(groups, hasLength(1));
      expect(groups.first.transactions, hasLength(2));
    });

    test('returns empty list for empty input', () {
      final groups = groupTransactionsByDate(const [], referenceDate: DateTime(2026, 7, 10));
      expect(groups, isEmpty);
    });
  });
}