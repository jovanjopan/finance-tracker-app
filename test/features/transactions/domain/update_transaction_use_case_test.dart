import 'package:flutter_test/flutter_test.dart';
import 'package:myfinancetracker/features/budgets/domain/allocate_income_use_case.dart';
import 'package:myfinancetracker/features/budgets/domain/budget_entity.dart';
import 'package:myfinancetracker/features/budgets/domain/budget_repository.dart';
import 'package:myfinancetracker/features/transactions/domain/transaction_entity.dart';
import 'package:myfinancetracker/features/transactions/domain/transaction_repository.dart';
import 'package:myfinancetracker/features/transactions/domain/update_transaction_use_case.dart';

void main() {
  group('UpdateTransactionUseCase', () {
    test('changing amount on auto-allocated income reverses old and applies new allocation', () async {
      final transactionRepository = _FakeTransactionRepository();
      final budgetRepository = _FakeBudgetRepository();
      final allocateUseCase = AllocateIncomeUseCase(budgetRepository: budgetRepository);
      final useCase = UpdateTransactionUseCase(
        transactionRepository: transactionRepository,
        allocateIncomeUseCase: allocateUseCase,
      );

      final originalDate = DateTime(2026, 7, 5);

      transactionRepository.seed(
        TransactionEntity(
          id: 'tx1',
          type: 'income',
          amount: 200000,
          transactionDate: originalDate,
          accountId: 'acc-1',
          categoryId: 'cat-income',
          allocationType: 'auto',
        ),
      );
      await allocateUseCase.allocateAutomatically(amount: 200000, transactionDate: originalDate);

      final updated = TransactionEntity(
        id: 'tx1',
        type: 'income',
        amount: 400000,
        transactionDate: originalDate,
        accountId: 'acc-1',
        categoryId: 'cat-income',
        allocationType: 'auto',
      );

      await useCase.execute(updated);

      final needs = await budgetRepository.getClassificationBudgetForDate('needs', originalDate);
      final wants = await budgetRepository.getClassificationBudgetForDate('wants', originalDate);
      final savings = await budgetRepository.getClassificationBudgetForDate('savings', originalDate);

      expect(needs!.targetAmount, 200000);
      expect(wants!.targetAmount, 120000);
      expect(savings!.targetAmount, 80000);

      final storedTransaction = await transactionRepository.getTransactionById('tx1');
      expect(storedTransaction!.amount, 400000);
    });

    test('changing allocation from auto to manual reverses all three and applies only chosen one', () async {
      final transactionRepository = _FakeTransactionRepository();
      final budgetRepository = _FakeBudgetRepository();
      final allocateUseCase = AllocateIncomeUseCase(budgetRepository: budgetRepository);
      final useCase = UpdateTransactionUseCase(
        transactionRepository: transactionRepository,
        allocateIncomeUseCase: allocateUseCase,
      );

      final date = DateTime(2026, 7, 10);

      transactionRepository.seed(
        TransactionEntity(
          id: 'tx2',
          type: 'income',
          amount: 200000,
          transactionDate: date,
          accountId: 'acc-1',
          categoryId: 'cat-income',
          allocationType: 'auto',
        ),
      );
      await allocateUseCase.allocateAutomatically(amount: 200000, transactionDate: date);

      final updated = TransactionEntity(
        id: 'tx2',
        type: 'income',
        amount: 500000,
        transactionDate: date,
        accountId: 'acc-1',
        categoryId: 'cat-income',
        allocationType: 'needs',
      );

      await useCase.execute(updated);

      final needs = await budgetRepository.getClassificationBudgetForDate('needs', date);
      final wants = await budgetRepository.getClassificationBudgetForDate('wants', date);
      final savings = await budgetRepository.getClassificationBudgetForDate('savings', date);

      expect(needs!.targetAmount, 500000);
      expect(wants!.targetAmount, 0);
      expect(savings!.targetAmount, 0);
    });

    test('editing expense transaction does not touch any budget', () async {
      final transactionRepository = _FakeTransactionRepository();
      final budgetRepository = _FakeBudgetRepository();
      final allocateUseCase = AllocateIncomeUseCase(budgetRepository: budgetRepository);
      final useCase = UpdateTransactionUseCase(
        transactionRepository: transactionRepository,
        allocateIncomeUseCase: allocateUseCase,
      );

      transactionRepository.seed(
        TransactionEntity(
          id: 'tx3',
          type: 'expense',
          amount: 50000,
          transactionDate: DateTime(2026, 7, 3),
          accountId: 'acc-1',
          categoryId: 'cat-food',
        ),
      );

      final updated = TransactionEntity(
        id: 'tx3',
        type: 'expense',
        amount: 75000,
        transactionDate: DateTime(2026, 7, 3),
        accountId: 'acc-1',
        categoryId: 'cat-food',
      );

      await useCase.execute(updated);

      expect(budgetRepository.allBudgets, isEmpty);
    });

    test('editing income transaction with no allocationType does not touch budget', () async {
      final transactionRepository = _FakeTransactionRepository();
      final budgetRepository = _FakeBudgetRepository();
      final allocateUseCase = AllocateIncomeUseCase(budgetRepository: budgetRepository);
      final useCase = UpdateTransactionUseCase(
        transactionRepository: transactionRepository,
        allocateIncomeUseCase: allocateUseCase,
      );

      transactionRepository.seed(
        TransactionEntity(
          id: 'tx4',
          type: 'income',
          amount: 100000,
          transactionDate: DateTime(2026, 7, 3),
          accountId: 'acc-1',
          categoryId: 'cat-income',
        ),
      );

      final updated = TransactionEntity(
        id: 'tx4',
        type: 'income',
        amount: 150000,
        transactionDate: DateTime(2026, 7, 3),
        accountId: 'acc-1',
        categoryId: 'cat-income',
      );

      await useCase.execute(updated);

      expect(budgetRepository.allBudgets, isEmpty);
    });
  });
}

class _FakeTransactionRepository implements TransactionRepository {
  final Map<String, TransactionEntity> _store = {};

  void seed(TransactionEntity transaction) {
    _store[transaction.id] = transaction;
  }

  @override
  Future<void> createTransaction(TransactionEntity transaction) async {
    _store[transaction.id] = transaction;
  }

  @override
  Future<void> updateTransaction(TransactionEntity transaction) async {
    _store[transaction.id] = transaction;
  }

  @override
  Future<void> deleteTransaction(String id) async {
    _store.remove(id);
  }

  @override
  Future<TransactionEntity?> getTransactionById(String id) async => _store[id];

  @override
  Stream<List<TransactionEntity>> watchAllTransactions() {
    return Stream.value(_store.values.toList());
  }

  @override
  Stream<List<TransactionEntity>> watchTransactionsByAccount(String accountId) {
    return Stream.value(_store.values.where((t) => t.accountId == accountId).toList());
  }
}

class _FakeBudgetRepository implements BudgetRepository {
  final List<BudgetEntity> allBudgets = <BudgetEntity>[];

  @override
  Future<void> createBudget(BudgetEntity budget) async {
    allBudgets.add(budget);
  }

  @override
  Future<void> updateBudget(BudgetEntity budget) async {
    final index = allBudgets.indexWhere((b) => b.id == budget.id);
    if (index != -1) {
      allBudgets[index] = budget;
    }
  }

  @override
  Future<void> deleteBudget(String id) async {
    allBudgets.removeWhere((b) => b.id == id);
  }

  @override
  Future<BudgetEntity?> getBudgetById(String id) async {
    try {
      return allBudgets.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<List<BudgetEntity>> watchAllBudgets() => Stream.value(allBudgets);

  @override
  Future<BudgetEntity?> getClassificationBudgetForDate(
    String classification,
    DateTime date,
  ) async {
    for (final budget in allBudgets) {
      if (budget.classification == classification &&
          !date.isBefore(budget.startDate) &&
          !date.isAfter(budget.endDate)) {
        return budget;
      }
    }
    return null;
  }
}