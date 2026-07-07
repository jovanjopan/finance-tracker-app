import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:myfinancetracker/core/providers/database_providers.dart';
import 'package:myfinancetracker/features/accounts/domain/account_entity.dart';
import 'package:myfinancetracker/features/accounts/domain/account_repository.dart';
import 'package:myfinancetracker/features/onboarding/presentation/onboarding_screen.dart';
import 'package:myfinancetracker/features/transactions/domain/transaction_entity.dart';
import 'package:myfinancetracker/features/transactions/domain/transaction_repository.dart';

void main() {
  group('OnboardingScreen', () {
    testWidgets('submit with empty name shows error and does not call createAccount', (WidgetTester tester) async {
      final fakeRepository = _FakeAccountRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            accountRepositoryProvider.overrideWithValue(fakeRepository),
            transactionRepositoryProvider.overrideWithValue(const _FakeTransactionRepository()),
          ],
          child: const MaterialApp(home: OnboardingScreen()),
        ),
      );

      await tester.enterText(find.byType(TextFormField).at(0), '   ');
      await tester.tap(find.text('mulai'));
      await tester.pump();

      expect(find.text('nama akun wajib diisi'), findsOneWidget);
      expect(fakeRepository.createdAccounts, isEmpty);
    });

    testWidgets('submit with valid name and empty balance creates account and navigates', (WidgetTester tester) async {
      final fakeRepository = _FakeAccountRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            accountRepositoryProvider.overrideWithValue(fakeRepository),
            transactionRepositoryProvider.overrideWithValue(const _FakeTransactionRepository()),
          ],
          child: const MaterialApp(home: OnboardingScreen()),
        ),
      );

      await tester.enterText(find.byType(TextFormField).at(0), 'Dompet Tunai');
      await tester.enterText(find.byType(TextFormField).at(1), '');
      await tester.tap(find.text('mulai'));
      await tester.pumpAndSettle();

      expect(fakeRepository.createdAccounts, hasLength(1));
      expect(fakeRepository.createdAccounts.single.name, 'Dompet Tunai');
      expect(fakeRepository.createdAccounts.single.initialBalance, 0.0);
      expect(find.text('total saldo'), findsOneWidget);
    });

    testWidgets('non digit characters are filtered while typing balance', (WidgetTester tester) async {
      final fakeRepository = _FakeAccountRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            accountRepositoryProvider.overrideWithValue(fakeRepository),
            transactionRepositoryProvider.overrideWithValue(const _FakeTransactionRepository()),
          ],
          child: const MaterialApp(home: OnboardingScreen()),
        ),
      );

      await tester.enterText(find.byType(TextFormField).at(0), 'Dompet Tunai');
      await tester.enterText(find.byType(TextFormField).at(1), 'abc250000xyz');
      await tester.tap(find.text('mulai'));
      await tester.pumpAndSettle();

      expect(fakeRepository.createdAccounts, hasLength(1));
      expect(fakeRepository.createdAccounts.single.initialBalance, 250000.0);
    });

    testWidgets('formats balance input with thousand separators', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            accountRepositoryProvider.overrideWithValue(_FakeAccountRepository()),
            transactionRepositoryProvider.overrideWithValue(const _FakeTransactionRepository()),
          ],
          child: const MaterialApp(home: OnboardingScreen()),
        ),
      );

      await tester.enterText(find.byType(TextFormField).at(1), '250000');
      await tester.pump();

      expect(find.text('250.000'), findsOneWidget);
    });
  });
}

class _FakeAccountRepository implements AccountRepository {
  final List<AccountEntity> createdAccounts = <AccountEntity>[];

  @override
  Future<void> createAccount(AccountEntity account) async {
    createdAccounts.add(account);
  }

  @override
  Future<void> deleteAccount(String id) async {}

  @override
  Future<AccountEntity?> getAccountById(String id) async => null;

  @override
  Future<void> updateAccount(AccountEntity account) async {}

  @override
  Stream<List<AccountEntity>> watchAllAccounts() {
    return Stream<List<AccountEntity>>.value(const <AccountEntity>[]);
  }

  @override
  Stream<double> watchCurrentBalance(String accountId) {
    return Stream<double>.value(0.0);
  }
}

class _FakeTransactionRepository implements TransactionRepository {
  const _FakeTransactionRepository();

  @override
  Future<void> createTransaction(TransactionEntity transaction) async {}

  @override
  Future<void> deleteTransaction(String id) async {}

  @override
  Stream<List<TransactionEntity>> watchAllTransactions() {
    return Stream<List<TransactionEntity>>.value(const <TransactionEntity>[]);
  }

  @override
  Stream<List<TransactionEntity>> watchTransactionsByAccount(String accountId) {
    return Stream<List<TransactionEntity>>.value(const <TransactionEntity>[]);
  }
}