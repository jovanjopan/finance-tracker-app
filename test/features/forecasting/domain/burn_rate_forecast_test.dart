import 'package:flutter_test/flutter_test.dart';
import 'package:myfinancetracker/features/forecasting/domain/burn_rate_forecast.dart';
import 'package:myfinancetracker/features/transactions/domain/transaction_entity.dart';

void main() {
  group('computeBurnRateForecast', () {
    test('calculates daily burn rate and projects survival when spending is low', () {
      final referenceDate = DateTime(2026, 7, 10); // hari ke-10 dari 31 hari

      final transactions = [
        TransactionEntity(
          id: 'tx1',
          type: 'expense',
          amount: 100000,
          transactionDate: DateTime(2026, 7, 5),
          accountId: 'acc-1',
          categoryId: 'cat-food',
        ),
      ];

      final forecast = computeBurnRateForecast(
        transactions: transactions,
        currentBalance: 1000000,
        referenceDate: referenceDate,
      );

      expect(forecast.daysPassed, 10);
      expect(forecast.dailyBurnRate, 10000); // 100.000 / 10 hari
      expect(forecast.daysRemainingInMonth, 21); // 31 - 10
      expect(forecast.projectedRemainingSpend, 210000); // 10.000 * 21
      expect(forecast.projectedEndOfMonthBalance, 790000); // 1.000.000 - 210.000
      expect(forecast.willSurvive, isTrue);
    });

    test('projects non-survival when spending rate is too high', () {
      final referenceDate = DateTime(2026, 7, 10);

      final transactions = [
        TransactionEntity(
          id: 'tx1',
          type: 'expense',
          amount: 900000,
          transactionDate: DateTime(2026, 7, 3),
          accountId: 'acc-1',
          categoryId: 'cat-food',
        ),
      ];

      final forecast = computeBurnRateForecast(
        transactions: transactions,
        currentBalance: 500000,
        referenceDate: referenceDate,
      );

      expect(forecast.dailyBurnRate, 90000); // 900.000 / 10
      expect(forecast.willSurvive, isFalse);
    });

    test('excludes transactions from other months', () {
      final referenceDate = DateTime(2026, 7, 15);

      final transactions = [
        TransactionEntity(
          id: 'tx-old',
          type: 'expense',
          amount: 5000000,
          transactionDate: DateTime(2026, 6, 20),
          accountId: 'acc-1',
          categoryId: 'cat-food',
        ),
      ];

      final forecast = computeBurnRateForecast(
        transactions: transactions,
        currentBalance: 1000000,
        referenceDate: referenceDate,
      );

      expect(forecast.dailyBurnRate, 0.0);
      expect(forecast.projectedEndOfMonthBalance, 1000000);
    });

    test('excludes income and transfer transactions from burn rate calculation', () {
      final referenceDate = DateTime(2026, 7, 10);

      final transactions = [
        TransactionEntity(
          id: 'tx-income',
          type: 'income',
          amount: 5000000,
          transactionDate: DateTime(2026, 7, 5),
          accountId: 'acc-1',
          categoryId: 'cat-income',
        ),
        TransactionEntity(
          id: 'tx-transfer',
          type: 'transfer',
          amount: 200000,
          transactionDate: DateTime(2026, 7, 6),
          accountId: 'acc-1',
          toAccountId: 'acc-2',
        ),
      ];

      final forecast = computeBurnRateForecast(
        transactions: transactions,
        currentBalance: 1000000,
        referenceDate: referenceDate,
      );

      expect(forecast.dailyBurnRate, 0.0);
    });

    test('handles first day of month without division by zero', () {
      final referenceDate = DateTime(2026, 7, 1);

      final forecast = computeBurnRateForecast(
        transactions: const [],
        currentBalance: 500000,
        referenceDate: referenceDate,
      );

      expect(forecast.daysPassed, 1);
      expect(forecast.dailyBurnRate, 0.0);
    });
  });
}