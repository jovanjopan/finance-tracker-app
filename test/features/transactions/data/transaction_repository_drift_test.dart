import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myfinancetracker/core/database/app_database.dart';
import 'package:myfinancetracker/features/accounts/domain/account_entity.dart';
import 'package:myfinancetracker/features/transactions/data/transaction_repository_drift.dart';
import 'package:myfinancetracker/features/transactions/domain/transaction_entity.dart';

void main() {
  group('TransactionRepositoryDrift', () {
    late AppDatabase database;
    late TransactionRepositoryDrift repository;

    setUp(() {
      database = AppDatabase.forTesting(NativeDatabase.memory());
      repository = TransactionRepositoryDrift(database);
    });

    tearDown(() async {
      await database.close();
    });

    test('createTransaction inserts a row and watchAllTransactions emits it', () async {
      await _insertAccount(
        database,
        const AccountEntity(
          id: 'acc-1',
          name: 'Cash',
          type: 'cash',
          initialBalance: 0.0,
          isActive: true,
        ),
      );

      final watchExpectation = expectLater(
        repository.watchAllTransactions(),
        emitsInOrder([
          isEmpty,
          predicate<List<TransactionEntity>>((transactions) {
            return transactions.length == 1 &&
                transactions.single.id == 'tx-1' &&
                transactions.single.type == 'income' &&
                transactions.single.categoryId == 'cat-1' &&
                transactions.single.toAccountId == null;
          }),
        ]),
      );

      await repository.createTransaction(
        TransactionEntity(
          id: 'tx-1',
          type: 'income',
          amount: 150.0,
          transactionDate: DateTime(2026, 1, 1),
          accountId: 'acc-1',
          categoryId: 'cat-1',
        ),
      );

      final rows = await database.select(database.transactions).get();
      expect(rows, hasLength(1));
      expect(rows.single.id, 'tx-1');
      expect(rows.single.categoryId, 'cat-1');
      expect(rows.single.toAccountId, isNull);

      await watchExpectation;
    });

    test('watchTransactionsByAccount includes transfer for both source and destination accounts', () async {
      await _insertAccount(
        database,
        const AccountEntity(
          id: 'source',
          name: 'Source',
          type: 'cash',
          initialBalance: 0.0,
          isActive: true,
        ),
      );
      await _insertAccount(
        database,
        const AccountEntity(
          id: 'destination',
          name: 'Destination',
          type: 'cash',
          initialBalance: 0.0,
          isActive: true,
        ),
      );

      final sourceExpectation = expectLater(
        repository.watchTransactionsByAccount('source'),
        emitsInOrder([
          isEmpty,
          predicate<List<TransactionEntity>>((transactions) {
            return transactions.length == 1 &&
                transactions.single.id == 'tx-transfer-1' &&
                transactions.single.accountId == 'source' &&
                transactions.single.toAccountId == 'destination';
          }),
        ]),
      );

      final destinationExpectation = expectLater(
        repository.watchTransactionsByAccount('destination'),
        emitsInOrder([
          isEmpty,
          predicate<List<TransactionEntity>>((transactions) {
            return transactions.length == 1 &&
                transactions.single.id == 'tx-transfer-1' &&
                transactions.single.accountId == 'source' &&
                transactions.single.toAccountId == 'destination';
          }),
        ]),
      );

      await repository.createTransaction(
        TransactionEntity(
          id: 'tx-transfer-1',
          type: 'transfer',
          amount: 75.0,
          transactionDate: DateTime(2026, 1, 2),
          accountId: 'source',
          toAccountId: 'destination',
        ),
      );

      await Future.wait([sourceExpectation, destinationExpectation]);
    });

    test('deleteTransaction removes the row and watchAllTransactions updates reactively', () async {
      await _insertAccount(
        database,
        const AccountEntity(
          id: 'acc-1',
          name: 'Cash',
          type: 'cash',
          initialBalance: 0.0,
          isActive: true,
        ),
      );

      await repository.createTransaction(
        TransactionEntity(
          id: 'tx-delete-1',
          type: 'expense',
          amount: 25.0,
          transactionDate: DateTime(2026, 1, 3),
          accountId: 'acc-1',
          categoryId: 'cat-1',
        ),
      );

      final watchExpectation = expectLater(
        repository.watchAllTransactions(),
        emitsInOrder([
          predicate<List<TransactionEntity>>((transactions) =>
              transactions.length == 1 && transactions.single.id == 'tx-delete-1'),
          isEmpty,
        ]),
      );

      await repository.deleteTransaction('tx-delete-1');

      expect(await database.select(database.transactions).get(), isEmpty);

      await watchExpectation;
    });
  });
}

Future<void> _insertAccount(AppDatabase database, AccountEntity account) {
  return database.into(database.accounts).insert(
        AccountsCompanion.insert(
          id: account.id,
          name: account.name,
          type: account.type,
          initialBalance: account.initialBalance,
          isActive: Value<bool>(account.isActive),
        ),
      );
}