import 'package:flutter_test/flutter_test.dart';
import 'package:myfinancetracker/features/budgets/domain/budget_entity.dart';
import 'package:myfinancetracker/features/budgets/domain/category_budget_summary.dart';
import 'package:myfinancetracker/features/transactions/domain/transaction_entity.dart';

void main() {
  group('computeCategoryBudgetSummaries', () {
    test('calculates spent only from matching category within date range', () {
      final budgets = [
        BudgetEntity(
          id: 'b1',
          categoryId: 'cat-food',
          targetAmount: 500000,
          startDate: DateTime(2026, 7, 1),
          endDate: DateTime(2026, 7, 31),
        ),
      ];

      final transactions = [
        TransactionEntity(
          id: 'tx1',
          type: 'expense',
          amount: 50000,
          transactionDate: DateTime(2026, 7, 10),
          accountId: 'acc-1',
          categoryId: 'cat-food',
        ),
        TransactionEntity(
          id: 'tx2',
          type: 'expense',
          amount: 30000,
          transactionDate: DateTime(2026, 7, 15),
          accountId: 'acc-1',
          categoryId: 'cat-other',
        ),
        TransactionEntity(
          id: 'tx3',
          type: 'expense',
          amount: 20000,
          transactionDate: DateTime(2026, 6, 15),
          accountId: 'acc-1',
          categoryId: 'cat-food',
        ),
      ];

      final summaries = computeCategoryBudgetSummaries(budgets: budgets, transactions: transactions);

      expect(summaries, hasLength(1));
      expect(summaries.first.spent, 50000);
      expect(summaries.first.remaining, 450000);
    });

    test('ignores budgets without categoryId (classification-based)', () {
      final budgets = [
        BudgetEntity(
          id: 'b1',
          classification: 'needs',
          targetAmount: 500000,
          startDate: DateTime(2026, 7, 1),
          endDate: DateTime(2026, 7, 31),
        ),
      ];

      final summaries = computeCategoryBudgetSummaries(budgets: budgets, transactions: const []);

      expect(summaries, isEmpty);
    });

    test('isOverBudget is true when spent exceeds target', () {
      final budgets = [
        BudgetEntity(
          id: 'b1',
          categoryId: 'cat-food',
          targetAmount: 100000,
          startDate: DateTime(2026, 7, 1),
          endDate: DateTime(2026, 7, 31),
        ),
      ];

      final transactions = [
        TransactionEntity(
          id: 'tx1',
          type: 'expense',
          amount: 150000,
          transactionDate: DateTime(2026, 7, 5),
          accountId: 'acc-1',
          categoryId: 'cat-food',
        ),
      ];

      final summaries = computeCategoryBudgetSummaries(budgets: budgets, transactions: transactions);

      expect(summaries.first.isOverBudget, isTrue);
      expect(summaries.first.percentageUsed, 1.0);
    });
  });
}