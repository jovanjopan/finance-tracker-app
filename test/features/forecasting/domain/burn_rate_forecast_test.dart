import 'package:flutter_test/flutter_test.dart';
import 'package:myfinancetracker/features/forecasting/domain/burn_rate_forecast.dart';
import 'package:myfinancetracker/features/transactions/domain/transaction_entity.dart';

void main() {
  group('computeBurnRateForecast', () {
    test('uses month-to-date average when fewer than 7 days have passed', () {
      final referenceDate = DateTime(2026, 7, 5); // hari ke-5

      final transactions = [
        TransactionEntity(
          id: 'tx1',
          type: 'expense',
          amount: 100000,
          transactionDate: DateTime(2026, 7, 2),
          accountId: 'acc-1',
          categoryId: 'cat-food',
        ),
      ];

      final forecast = computeBurnRateForecast(
        transactions: transactions,
        currentBalance: 1000000,
        referenceDate: referenceDate,
      );

      expect(forecast.daysPassed, 5);
      expect(forecast.dailyBurnRate, 20000); // 100.000 / 5
    });

    test('uses 7-day rolling average once 7+ days have passed, ignoring older large expense', () {
      final referenceDate = DateTime(2026, 7, 20);

      final transactions = [
        // Pengeluaran besar di awal bulan, sudah lebih dari 7 hari lalu.
        TransactionEntity(
          id: 'tx-old',
          type: 'expense',
          amount: 2000000,
          transactionDate: DateTime(2026, 7, 2),
          accountId: 'acc-1',
          categoryId: 'cat-food',
        ),
        // Pengeluaran dalam 7 hari terakhir (14-20 Juli).
        TransactionEntity(
          id: 'tx-recent',
          type: 'expense',
          amount: 140000,
          transactionDate: DateTime(2026, 7, 18),
          accountId: 'acc-1',
          categoryId: 'cat-food',
        ),
      ];

      final forecast = computeBurnRateForecast(
        transactions: transactions,
        currentBalance: 1000000,
        referenceDate: referenceDate,
      );

      // Hanya tx-recent yang masuk window 7 hari terakhir: 140.000 / 7 = 20.000
      expect(forecast.dailyBurnRate, 20000);
    });

    test('status is noRecentSpending when there is no expense in the relevant window', () {
      final forecast = computeBurnRateForecast(
        transactions: const [],
        currentBalance: 500000,
        referenceDate: DateTime(2026, 7, 20),
      );

      expect(forecast.status, BurnRateStatus.noRecentSpending);
      expect(forecast.projectedDepletionDate, isNull);
    });

    test('status is atRisk with a concrete date when depletion falls within this month', () {
      final referenceDate = DateTime(2026, 7, 20);

      final transactions = [
        TransactionEntity(
          id: 'tx1',
          type: 'expense',
          amount: 700000, // 100.000/hari selama 7 hari terakhir
          transactionDate: DateTime(2026, 7, 18),
          accountId: 'acc-1',
          categoryId: 'cat-food',
        ),
      ];

      final forecast = computeBurnRateForecast(
        transactions: transactions,
        currentBalance: 500000, // 500.000 / 100.000 per hari = 5 hari lagi -> 25 Juli
        referenceDate: referenceDate,
      );

      expect(forecast.status, BurnRateStatus.atRisk);
      expect(forecast.projectedDepletionDate, DateTime(2026, 7, 25));
    });

    test('status is safeThisMonth when depletion falls after end of this month', () {
      final referenceDate = DateTime(2026, 7, 20);

      final transactions = [
        TransactionEntity(
          id: 'tx1',
          type: 'expense',
          amount: 70000, // 10.000/hari
          transactionDate: DateTime(2026, 7, 18),
          accountId: 'acc-1',
          categoryId: 'cat-food',
        ),
      ];

      final forecast = computeBurnRateForecast(
        transactions: transactions,
        currentBalance: 1000000, // 100 hari lagi, jauh melewati akhir Juli
        referenceDate: referenceDate,
      );

      expect(forecast.status, BurnRateStatus.safeThisMonth);
      expect(forecast.projectedDepletionDate, isNotNull);
    });

    test('status is safeLongTerm when projected depletion exceeds 180 days', () {
      final referenceDate = DateTime(2026, 7, 20);

      final transactions = [
        TransactionEntity(
          id: 'tx1',
          type: 'expense',
          amount: 7000, // 1.000/hari, sangat kecil
          transactionDate: DateTime(2026, 7, 18),
          accountId: 'acc-1',
          categoryId: 'cat-food',
        ),
      ];

      final forecast = computeBurnRateForecast(
        transactions: transactions,
        currentBalance: 10000000, // 10.000 hari lagi, jauh di atas 180
        referenceDate: referenceDate,
      );

      expect(forecast.status, BurnRateStatus.safeLongTerm);
      expect(forecast.projectedDepletionDate, isNull);
    });

    test('excludes income and transfer transactions from burn rate calculation', () {
      final referenceDate = DateTime(2026, 7, 20);

      final transactions = [
        TransactionEntity(
          id: 'tx-income',
          type: 'income',
          amount: 5000000,
          transactionDate: DateTime(2026, 7, 18),
          accountId: 'acc-1',
          categoryId: 'cat-income',
        ),
        TransactionEntity(
          id: 'tx-transfer',
          type: 'transfer',
          amount: 200000,
          transactionDate: DateTime(2026, 7, 18),
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
      expect(forecast.status, BurnRateStatus.noRecentSpending);
    });

    test('handles already-negative balance by projecting depletion as today', () {
      final referenceDate = DateTime(2026, 7, 20);

      final transactions = [
        TransactionEntity(
          id: 'tx1',
          type: 'expense',
          amount: 70000,
          transactionDate: DateTime(2026, 7, 18),
          accountId: 'acc-1',
          categoryId: 'cat-food',
        ),
      ];

      final forecast = computeBurnRateForecast(
        transactions: transactions,
        currentBalance: -50000,
        referenceDate: referenceDate,
      );

      expect(forecast.status, BurnRateStatus.atRisk);
      expect(forecast.projectedDepletionDate, DateTime(2026, 7, 20));
    });
  });
}