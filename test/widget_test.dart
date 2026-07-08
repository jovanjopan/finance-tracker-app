import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:myfinancetracker/core/providers/database_providers.dart';
import 'package:myfinancetracker/features/accounts/domain/account_entity.dart';
import 'package:myfinancetracker/features/accounts/domain/account_repository.dart';
import 'package:myfinancetracker/features/budgets/domain/budget_entity.dart';
import 'package:myfinancetracker/features/budgets/domain/budget_repository.dart';
import 'package:myfinancetracker/features/categories/domain/category_entity.dart';
import 'package:myfinancetracker/features/categories/domain/category_repository.dart';
import 'package:myfinancetracker/features/transactions/domain/transaction_entity.dart';
import 'package:myfinancetracker/features/transactions/domain/transaction_repository.dart';
import 'package:myfinancetracker/main.dart';

void main() {
  testWidgets('Splash navigates to onboarding when no accounts exist', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountRepositoryProvider.overrideWithValue(_FakeAccountRepository()),
          transactionRepositoryProvider.overrideWithValue(const _FakeTransactionRepository()),
          categoryRepositoryProvider.overrideWithValue(const _FakeCategoryRepository()),
          budgetRepositoryProvider.overrideWithValue(const _FakeBudgetRepository()),
        ],
        child: const MyApp(),
      ),
    );

    expect(find.text('koinku'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();

    expect(find.text('buat akun pertama'), findsOneWidget);
  });

  testWidgets('Splash navigates directly to dashboard when an account exists', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountRepositoryProvider.overrideWithValue(
            const _FakeAccountRepository([
              AccountEntity(
                id: 'acc-1',
                name: 'Cash',
                type: 'cash',
                initialBalance: 0.0,
                isActive: true,
              ),
            ]),
          ),
          transactionRepositoryProvider.overrideWithValue(const _FakeTransactionRepository()),
          categoryRepositoryProvider.overrideWithValue(const _FakeCategoryRepository()),
          budgetRepositoryProvider.overrideWithValue(const _FakeBudgetRepository()),
        ],
        child: const MyApp(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();

    expect(find.text('total saldo'), findsOneWidget);
    expect(find.text('buat akun pertama'), findsNothing);
  });
}

class _FakeAccountRepository implements AccountRepository {
  const _FakeAccountRepository([this._accounts = const <AccountEntity>[]]);

  final List<AccountEntity> _accounts;

  @override
  Future<void> createAccount(AccountEntity account) async {}

  @override
  Future<void> deleteAccount(String id) async {}

  @override
  Future<AccountEntity?> getAccountById(String id) async => null;

  @override
  Future<void> updateAccount(AccountEntity account) async {}

  @override
  Stream<List<AccountEntity>> watchAllAccounts() {
    return Stream<List<AccountEntity>>.value(_accounts);
  }

  @override
  Stream<double> watchCurrentBalance(String accountId) {
    return Stream<double>.value(0.0);
  }
}

class _FakeTransactionRepository implements TransactionRepository {
  const _FakeTransactionRepository([this._transactions = const <TransactionEntity>[]]);

  final List<TransactionEntity> _transactions;

  @override
  Future<TransactionEntity?> getTransactionById(String id) async => null;

  @override
  Future<void> updateTransaction(TransactionEntity transaction) async {}

  @override
  Future<void> createTransaction(TransactionEntity transaction) async {}

  @override
  Future<void> deleteTransaction(String id) async {}

  @override
  Stream<List<TransactionEntity>> watchAllTransactions() {
    return Stream<List<TransactionEntity>>.value(_transactions);
  }

  @override
  Stream<List<TransactionEntity>> watchTransactionsByAccount(String accountId) {
    return Stream<List<TransactionEntity>>.value(_transactions);
  }
}

class _FakeCategoryRepository implements CategoryRepository {
  const _FakeCategoryRepository([this._categories = const <CategoryEntity>[]]);

  final List<CategoryEntity> _categories;

  @override
  Future<void> createCategory(CategoryEntity category) async {}

  @override
  Future<void> deleteCategory(String id) async {}

  @override
  Future<CategoryEntity?> getCategoryById(String id) async => null;

  @override
  Future<void> updateCategory(CategoryEntity category) async {}

  @override
  Stream<List<CategoryEntity>> watchAllCategories() {
    return Stream<List<CategoryEntity>>.value(_categories);
  }
}

class _FakeBudgetRepository implements BudgetRepository {
  const _FakeBudgetRepository();

  @override
  Future<void> createBudget(BudgetEntity budget) async {}

  @override
  Future<void> deleteBudget(String id) async {}

  @override
  Future<BudgetEntity?> getBudgetById(String id) async => null;

  @override
  Future<void> updateBudget(BudgetEntity budget) async {}

  @override
  Stream<List<BudgetEntity>> watchAllBudgets() {
    return Stream<List<BudgetEntity>>.value(const <BudgetEntity>[]);
  }

  @override
  Future<BudgetEntity?> getClassificationBudgetForDate(
    String classification,
    DateTime date,
  ) async => null;
}