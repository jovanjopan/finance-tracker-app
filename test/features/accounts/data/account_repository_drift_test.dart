import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myfinancetracker/core/database/app_database.dart';
import 'package:myfinancetracker/features/accounts/data/account_repository_drift.dart';
import 'package:myfinancetracker/features/accounts/domain/account_entity.dart';

void main() {
  group('AccountRepositoryDrift', () {
    late AppDatabase database;
    late AccountRepositoryDrift repository;

    setUp(() {
      database = AppDatabase.forTesting(NativeDatabase.memory());
      repository = AccountRepositoryDrift(database);
    });

    tearDown(() async {
      await database.close();
    });

    test('create, read, update, delete, and watchAllAccounts reactively', () async {
      final account = AccountEntity(
        id: 'acc-1',
        name: 'Cash Wallet',
        type: 'cash',
        initialBalance: 1000.0,
        isActive: true,
      );

      await repository.createAccount(account);

      final created = await repository.getAccountById(account.id);
      expect(created, isNotNull);
      expect(created!.id, account.id);
      expect(created.name, account.name);
      expect(created.type, account.type);
      expect(created.initialBalance, account.initialBalance);
      expect(created.isActive, isTrue);

      final watchExpectation = expectLater(
        repository.watchAllAccounts(),
        emitsInOrder([
          predicate<List<AccountEntity>>((accounts) =>
              accounts.length == 1 &&
              accounts.single.id == account.id &&
              accounts.single.name == account.name),
          predicate<List<AccountEntity>>((accounts) =>
              accounts.length == 1 &&
              accounts.single.id == account.id &&
              accounts.single.name == 'Main Cash'),
          isEmpty,
        ]),
      );

      await repository.updateAccount(
        const AccountEntity(
          id: 'acc-1',
          name: 'Main Cash',
          type: 'cash',
          initialBalance: 1500.0,
          isActive: false,
        ),
      );

      final updated = await repository.getAccountById(account.id);
      expect(updated, isNotNull);
      expect(updated!.name, 'Main Cash');
      expect(updated.initialBalance, 1500);
      expect(updated.isActive, isFalse);

      await repository.deleteAccount(account.id);

      expect(await repository.getAccountById(account.id), isNull);

      await watchExpectation;
    });

    test('watchCurrentBalance calculates initial balance plus incoming minus outgoing transactions', () async {
      const accountId = 'acc-balance';

      await database.into(database.accounts).insert(
            AccountsCompanion.insert(
              id: accountId,
              name: 'Main Cash',
              type: 'cash',
              initialBalance: 1000.0,
            ),
          );

      await database.into(database.accounts).insert(
            AccountsCompanion.insert(
              id: 'acc-source',
              name: 'Source',
              type: 'cash',
              initialBalance: 0.0,
            ),
          );

      final balanceExpectation = expectLater(
        repository.watchCurrentBalance(accountId),
        emitsInOrder([
          1000.0,
          1200.0,
          1100.0,
        ]),
      );

      await database.into(database.transactions).insert(
            TransactionsCompanion.insert(
              id: 'tx-in-1',
              type: 'income',
              amount: 200.0,
              transactionDate: DateTime(2026, 1, 1),
              accountId: accountId,
            ),
          );

      await database.into(database.transactions).insert(
            TransactionsCompanion.insert(
              id: 'tx-out-1',
              type: 'expense',
              amount: 100.0,
              transactionDate: DateTime(2026, 1, 2),
              accountId: accountId,
            ),
          );

      await balanceExpectation;
    });

    test('watchCurrentBalance reflects transfer out for source and transfer in for destination', () async {
      const sourceAccountId = 'acc-transfer-source';
      const destinationAccountId = 'acc-transfer-destination';

      await database.into(database.accounts).insert(
            AccountsCompanion.insert(
              id: sourceAccountId,
              name: 'Source',
              type: 'cash',
              initialBalance: 1000.0,
            ),
          );

      await database.into(database.accounts).insert(
            AccountsCompanion.insert(
              id: destinationAccountId,
              name: 'Destination',
              type: 'cash',
              initialBalance: 300.0,
            ),
          );

      final sourceBalanceExpectation = expectLater(
        repository.watchCurrentBalance(sourceAccountId),
        emitsInOrder([
          1000.0,
          700.0,
        ]),
      );

      final destinationBalanceExpectation = expectLater(
        repository.watchCurrentBalance(destinationAccountId),
        emitsInOrder([
          300.0,
          600.0,
        ]),
      );

      await database.into(database.transactions).insert(
            TransactionsCompanion.insert(
              id: 'tx-transfer-1',
              type: 'transfer',
              amount: 300.0,
              transactionDate: DateTime(2026, 1, 3),
              accountId: sourceAccountId,
              toAccountId: Value(destinationAccountId),
            ),
          );

      await Future.wait([
        sourceBalanceExpectation,
        destinationBalanceExpectation,
      ]);
    });
  });
}