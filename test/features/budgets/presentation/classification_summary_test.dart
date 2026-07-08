import 'package:flutter_test/flutter_test.dart';
import 'package:myfinancetracker/features/budgets/domain/budget_entity.dart';
import 'package:myfinancetracker/features/budgets/presentation/classification_summary.dart';
import 'package:myfinancetracker/features/categories/domain/category_entity.dart';
import 'package:myfinancetracker/features/transactions/domain/transaction_entity.dart';

void main() {
  group('computeClassificationSummaries', () {
    test('computes spent correctly for needs based on matching category classification', () {
      final budgets = [
        BudgetEntity(
          id: 'b1',
          classification: 'needs',
          targetAmount: 500000,
          startDate: DateTime(2026, 7, 1),
          endDate: DateTime(2026, 7, 31),
        ),
      ];

      final categories = [
        const CategoryEntity(
          id: 'cat-food',
          name: 'makan & minum',
          transactionType: 'expense',
          expenseClassification: 'needs',
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
          categoryId: 'cat-food',
        ),
      ];

      final summaries = computeClassificationSummaries(
        budgets: budgets,
        categories: categories,
        transactions: transactions,
        referenceDate: DateTime(2026, 7, 20),
      );

      final needsSummary = summaries.firstWhere((s) => s.classification == 'needs');
      expect(needsSummary.target, 500000);
      expect(needsSummary.spent, 80000);
      expect(needsSummary.remaining, 420000);
    });

    test('excludes transactions from a different month', () {
      final budgets = [
        BudgetEntity(
          id: 'b1',
          classification: 'needs',
          targetAmount: 500000,
          startDate: DateTime(2026, 7, 1),
          endDate: DateTime(2026, 7, 31),
        ),
      ];

      final categories = [
        const CategoryEntity(
          id: 'cat-food',
          name: 'makan & minum',
          transactionType: 'expense',
          expenseClassification: 'needs',
        ),
      ];

      final transactions = [
        TransactionEntity(
          id: 'tx-old',
          type: 'expense',
          amount: 999999,
          transactionDate: DateTime(2026, 6, 15),
          accountId: 'acc-1',
          categoryId: 'cat-food',
        ),
      ];

      final summaries = computeClassificationSummaries(
        budgets: budgets,
        categories: categories,
        transactions: transactions,
        referenceDate: DateTime(2026, 7, 20),
      );

      final needsSummary = summaries.firstWhere((s) => s.classification == 'needs');
      expect(needsSummary.spent, 0.0);
    });

    test('savings always has zero spent regardless of transactions', () {
      final budgets = [
        BudgetEntity(
          id: 'b1',
          classification: 'savings',
          targetAmount: 200000,
          startDate: DateTime(2026, 7, 1),
          endDate: DateTime(2026, 7, 31),
        ),
      ];

      final summaries = computeClassificationSummaries(
        budgets: budgets,
        categories: const [],
        transactions: const [],
        referenceDate: DateTime(2026, 7, 20),
      );

      final savingsSummary = summaries.firstWhere((s) => s.classification == 'savings');
      expect(savingsSummary.target, 200000);
      expect(savingsSummary.spent, 0.0);
    });

    test('percentageUsed is clamped at 1.0 when overspent', () {
      final budgets = [
        BudgetEntity(
          id: 'b1',
          classification: 'wants',
          targetAmount: 100000,
          startDate: DateTime(2026, 7, 1),
          endDate: DateTime(2026, 7, 31),
        ),
      ];

      final categories = [
        const CategoryEntity(
          id: 'cat-fun',
          name: 'hiburan',
          transactionType: 'expense',
          expenseClassification: 'wants',
        ),
      ];

      final transactions = [
        TransactionEntity(
          id: 'tx1',
          type: 'expense',
          amount: 150000,
          transactionDate: DateTime(2026, 7, 5),
          accountId: 'acc-1',
          categoryId: 'cat-fun',
        ),
      ];

      final summaries = computeClassificationSummaries(
        budgets: budgets,
        categories: categories,
        transactions: transactions,
        referenceDate: DateTime(2026, 7, 20),
      );

      final wantsSummary = summaries.firstWhere((s) => s.classification == 'wants');
      expect(wantsSummary.isOverBudget, isTrue);
      expect(wantsSummary.percentageUsed, 1.0);
    });
  });
}