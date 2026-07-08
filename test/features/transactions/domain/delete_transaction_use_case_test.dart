import 'package:flutter_test/flutter_test.dart';
import 'package:myfinancetracker/features/budgets/domain/allocate_income_use_case.dart';
import 'package:myfinancetracker/features/budgets/domain/budget_entity.dart';
import 'package:myfinancetracker/features/budgets/domain/budget_repository.dart';
import 'package:myfinancetracker/features/transactions/domain/delete_transaction_use_case.dart';
import 'package:myfinancetracker/features/transactions/domain/transaction_entity.dart';
import 'package:myfinancetracker/features/transactions/domain/transaction_repository.dart';

void main() {
  group('DeleteTransactionUseCase', () {
    test('deleting auto-allocated income reverses all three classifications', () async {
      final transactionRepository = _FakeTransactionRepository();
      final budgetRepository = _FakeBudgetRepository();
      final allocateUseCase = AllocateIncomeUseCase(budgetRepository: budgetRepository);
      final useCase = DeleteTransactionUseCase(
        transactionRepository: transactionRepository,
        allocateIncomeUseCase: allocateUseCase,
      );

      final date = DateTime(2026, 7, 5);

      transactionRepository.seed(
        TransactionEntity(
          id: 'tx1',
          type: 'income',
          amount: 200000,
          transactionDate: date,
          accountId: 'acc-1',
          allocationType: 'auto',
        ),
      );
      await allocateUseCase.allocateAutomatically(amount: 200000, transactionDate: date);

      await useCase.execute('tx1');

      final needs = await budgetRepository.getClassificationBudgetForDate('needs', date);
      final wants = await budgetRepository.getClassificationBudgetForDate('wants', date);
      final savings = await budgetRepository.getClassificationBudgetForDate('savings', date);

      expect(needs!.targetAmount, 0);
      expect(wants!.targetAmount, 0);
      expect(savings!.targetAmount, 0);
      expect(await transactionRepository.getTransactionById('tx1'), isNull);
    });

    test('deleting manually-allocated income reverses only the chosen classification', () async {
      final transactionRepository = _FakeTransactionRepository();
      final budgetRepository = _FakeBudgetRepository();
      final allocateUseCase = AllocateIncomeUseCase(budgetRepository: budgetRepository);
      final useCase = DeleteTransactionUseCase(
        transactionRepository: transactionRepository,
        allocateIncomeUseCase: allocateUseCase,
      );

      final date = DateTime(2026, 7, 8);

      transactionRepository.seed(
        TransactionEntity(
          id: 'tx2',
          type: 'income',
          amount: 300000,
          transactionDate: date,
          accountId: 'acc-1',
          allocationType: 'savings',
        ),
      );
      await allocateUseCase.allocateManually(
        classification: 'savings',
        amount: 300000,
        transactionDate: date,
      );

      await useCase.execute('tx2');

      final savings = await budgetRepository.getClassificationBudgetForDate('savings', date);
      expect(savings!.targetAmount, 0);
    });

    test('deleting income without allocationType does not touch budget', () async {
      final transactionRepository = _FakeTransactionRepository();
      final budgetRepository = _FakeBudgetRepository();
      final allocateUseCase = AllocateIncomeUseCase(budgetRepository: budgetRepository);
      final useCase = DeleteTransactionUseCase(
        transactionRepository: transactionRepository,
        allocateIncomeUseCase: allocateUseCase,
      );

      transactionRepository.seed(
        TransactionEntity(
          id: 'tx3',
          type: 'income',
          amount: 100000,
          transactionDate: DateTime(2026, 7, 1),
          accountId: 'acc-1',
        ),
      );

      await useCase.execute('tx3');

      expect(budgetRepository.allBudgets, isEmpty);
      expect(await transactionRepository.getTransactionById('tx3'), isNull);
    });

    test('deleting expense transaction does not touch budget', () async {
      final transactionRepository = _FakeTransactionRepository();
      final budgetRepository = _FakeBudgetRepository();
      final allocateUseCase = AllocateIncomeUseCase(budgetRepository: budgetRepository);
      final useCase = DeleteTransactionUseCase(
        transactionRepository: transactionRepository,
        allocateIncomeUseCase: allocateUseCase,
      );

      transactionRepository.seed(
        TransactionEntity(
          id: 'tx4',
          type: 'expense',
          amount: 25000,
          transactionDate: DateTime(2026, 7, 2),
          accountId: 'acc-1',
          categoryId: 'cat-food',
        ),
      );

      await useCase.execute('tx4');

      expect(budgetRepository.allBudgets, isEmpty);
      expect(await transactionRepository.getTransactionById('tx4'), isNull);
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