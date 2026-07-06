import 'package:flutter_test/flutter_test.dart';
import 'package:myfinancetracker/features/accounts/domain/account_entity.dart';
import 'package:myfinancetracker/features/accounts/domain/account_repository.dart';
import 'package:myfinancetracker/features/transactions/domain/transaction_entity.dart';
import 'package:myfinancetracker/features/transactions/domain/transaction_repository.dart';
import 'package:myfinancetracker/features/transactions/domain/transaction_validation_exception.dart';
import 'package:myfinancetracker/features/transactions/domain/transaction_validator.dart';
import 'package:myfinancetracker/features/transactions/domain/transfer_money_use_case.dart';

void main() {
  group('TransactionValidator', () {
    test('accepts valid income transaction', () {
      final transaction = TransactionEntity(
        id: 'tx-1',
        type: 'income',
        amount: 100.0,
        transactionDate: DateTime(2026, 1, 1),
        accountId: 'acc-1',
        categoryId: 'cat-1',
      );

      expect(() => TransactionValidator.validate(transaction), returnsNormally);
    });

    test('throws for income without categoryId', () {
      final transaction = TransactionEntity(
        id: 'tx-2',
        type: 'income',
        amount: 100.0,
        transactionDate: DateTime(2026, 1, 1),
        accountId: 'acc-1',
      );

      expect(
        () => TransactionValidator.validate(transaction),
        throwsA(isA<TransactionValidationException>()),
      );
    });

    test('throws for income with toAccountId', () {
      final transaction = TransactionEntity(
        id: 'tx-3',
        type: 'income',
        amount: 100.0,
        transactionDate: DateTime(2026, 1, 1),
        accountId: 'acc-1',
        categoryId: 'cat-1',
        toAccountId: 'acc-2',
      );

      expect(
        () => TransactionValidator.validate(transaction),
        throwsA(isA<TransactionValidationException>()),
      );
    });

    test('accepts valid expense transaction', () {
      final transaction = TransactionEntity(
        id: 'tx-4',
        type: 'expense',
        amount: 100.0,
        transactionDate: DateTime(2026, 1, 1),
        accountId: 'acc-1',
        categoryId: 'cat-1',
      );

      expect(() => TransactionValidator.validate(transaction), returnsNormally);
    });

    test('throws for expense without categoryId', () {
      final transaction = TransactionEntity(
        id: 'tx-5',
        type: 'expense',
        amount: 100.0,
        transactionDate: DateTime(2026, 1, 1),
        accountId: 'acc-1',
      );

      expect(
        () => TransactionValidator.validate(transaction),
        throwsA(isA<TransactionValidationException>()),
      );
    });

    test('throws for expense with toAccountId', () {
      final transaction = TransactionEntity(
        id: 'tx-6',
        type: 'expense',
        amount: 100.0,
        transactionDate: DateTime(2026, 1, 1),
        accountId: 'acc-1',
        categoryId: 'cat-1',
        toAccountId: 'acc-2',
      );

      expect(
        () => TransactionValidator.validate(transaction),
        throwsA(isA<TransactionValidationException>()),
      );
    });

    test('accepts valid transfer transaction', () {
      final transaction = TransactionEntity(
        id: 'tx-7',
        type: 'transfer',
        amount: 100.0,
        transactionDate: DateTime(2026, 1, 1),
        accountId: 'acc-1',
        toAccountId: 'acc-2',
      );

      expect(() => TransactionValidator.validate(transaction), returnsNormally);
    });

    test('throws for transfer with categoryId', () {
      final transaction = TransactionEntity(
        id: 'tx-8',
        type: 'transfer',
        amount: 100.0,
        transactionDate: DateTime(2026, 1, 1),
        accountId: 'acc-1',
        toAccountId: 'acc-2',
        categoryId: 'cat-1',
      );

      expect(
        () => TransactionValidator.validate(transaction),
        throwsA(isA<TransactionValidationException>()),
      );
    });

    test('throws for transfer without toAccountId', () {
      final transaction = TransactionEntity(
        id: 'tx-9',
        type: 'transfer',
        amount: 100.0,
        transactionDate: DateTime(2026, 1, 1),
        accountId: 'acc-1',
      );

      expect(
        () => TransactionValidator.validate(transaction),
        throwsA(isA<TransactionValidationException>()),
      );
    });

    test('throws for unknown transaction type', () {
      final transaction = TransactionEntity(
        id: 'tx-10',
        type: 'bonus',
        amount: 100.0,
        transactionDate: DateTime(2026, 1, 1),
        accountId: 'acc-1',
      );

      expect(
        () => TransactionValidator.validate(transaction),
        throwsA(isA<TransactionValidationException>()),
      );
    });
  });

  group('TransferMoneyUseCase', () {
    late FakeAccountRepository accountRepository;
    late FakeTransactionRepository transactionRepository;
    late TransferMoneyUseCase useCase;

    setUp(() {
      accountRepository = FakeAccountRepository();
      transactionRepository = FakeTransactionRepository();
      useCase = TransferMoneyUseCase(
        accountRepository: accountRepository,
        transactionRepository: transactionRepository,
      );
    });

    test('executes successful transfer', () async {
      accountRepository.accounts['source'] = const AccountEntity(
        id: 'source',
        name: 'Source',
        type: 'cash',
        initialBalance: 1000.0,
        isActive: true,
      );
      accountRepository.accounts['destination'] = const AccountEntity(
        id: 'destination',
        name: 'Destination',
        type: 'cash',
        initialBalance: 500.0,
        isActive: true,
      );

      await useCase.execute(
        sourceAccountId: 'source',
        destinationAccountId: 'destination',
        amount: 250.0,
        transactionDate: DateTime(2026, 1, 2),
      );

      expect(transactionRepository.createdTransactions, hasLength(1));
      final created = transactionRepository.createdTransactions.single;
      expect(created.type, 'transfer');
      expect(created.accountId, 'source');
      expect(created.toAccountId, 'destination');
      expect(created.categoryId, isNull);
      expect(created.amount, 250.0);
      expect(created.transactionDate, DateTime(2026, 1, 2));
      expect(created.id, isNotEmpty);
    });

    test('throws when source account is not found', () async {
      accountRepository.accounts['destination'] = const AccountEntity(
        id: 'destination',
        name: 'Destination',
        type: 'cash',
        initialBalance: 500.0,
        isActive: true,
      );

      await expectLater(
        () => useCase.execute(
          sourceAccountId: 'source',
          destinationAccountId: 'destination',
          amount: 250.0,
          transactionDate: DateTime(2026, 1, 2),
        ),
        throwsA(isA<AccountNotFoundException>()),
      );

      expect(transactionRepository.createdTransactions, isEmpty);
    });

    test('throws when destination account is not found', () async {
      accountRepository.accounts['source'] = const AccountEntity(
        id: 'source',
        name: 'Source',
        type: 'cash',
        initialBalance: 1000.0,
        isActive: true,
      );

      await expectLater(
        () => useCase.execute(
          sourceAccountId: 'source',
          destinationAccountId: 'destination',
          amount: 250.0,
          transactionDate: DateTime(2026, 1, 2),
        ),
        throwsA(isA<AccountNotFoundException>()),
      );

      expect(transactionRepository.createdTransactions, isEmpty);
    });

    test('throws when source account is inactive', () async {
      accountRepository.accounts['source'] = const AccountEntity(
        id: 'source',
        name: 'Source',
        type: 'cash',
        initialBalance: 1000.0,
        isActive: false,
      );
      accountRepository.accounts['destination'] = const AccountEntity(
        id: 'destination',
        name: 'Destination',
        type: 'cash',
        initialBalance: 500.0,
        isActive: true,
      );

      await expectLater(
        () => useCase.execute(
          sourceAccountId: 'source',
          destinationAccountId: 'destination',
          amount: 250.0,
          transactionDate: DateTime(2026, 1, 2),
        ),
        throwsA(isA<InactiveAccountException>()),
      );

      expect(transactionRepository.createdTransactions, isEmpty);
    });

    test('throws when destination account is inactive', () async {
      accountRepository.accounts['source'] = const AccountEntity(
        id: 'source',
        name: 'Source',
        type: 'cash',
        initialBalance: 1000.0,
        isActive: true,
      );
      accountRepository.accounts['destination'] = const AccountEntity(
        id: 'destination',
        name: 'Destination',
        type: 'cash',
        initialBalance: 500.0,
        isActive: false,
      );

      await expectLater(
        () => useCase.execute(
          sourceAccountId: 'source',
          destinationAccountId: 'destination',
          amount: 250.0,
          transactionDate: DateTime(2026, 1, 2),
        ),
        throwsA(isA<InactiveAccountException>()),
      );

      expect(transactionRepository.createdTransactions, isEmpty);
    });
  });
}

class FakeAccountRepository implements AccountRepository {
  final Map<String, AccountEntity> accounts = <String, AccountEntity>{};

  @override
  Future<void> createAccount(AccountEntity account) async {
    accounts[account.id] = account;
  }

  @override
  Future<void> deleteAccount(String id) async {
    accounts.remove(id);
  }

  @override
  Future<AccountEntity?> getAccountById(String id) async {
    return accounts[id];
  }

  @override
  Future<void> updateAccount(AccountEntity account) async {
    accounts[account.id] = account;
  }

  @override
  Stream<List<AccountEntity>> watchAllAccounts() {
    return Stream<List<AccountEntity>>.value(accounts.values.toList(growable: false));
  }

  @override
  Stream<double> watchCurrentBalance(String accountId) {
    return Stream<double>.value(0.0);
  }
}

class FakeTransactionRepository implements TransactionRepository {
  final List<TransactionEntity> createdTransactions = <TransactionEntity>[];

  @override
  Future<void> createTransaction(TransactionEntity transaction) async {
    createdTransactions.add(transaction);
  }

  @override
  Future<void> deleteTransaction(String id) async {
    createdTransactions.removeWhere((transaction) => transaction.id == id);
  }

  @override
  Stream<List<TransactionEntity>> watchAllTransactions() {
    return Stream<List<TransactionEntity>>.value(
      createdTransactions.toList(growable: false),
    );
  }

  @override
  Stream<List<TransactionEntity>> watchTransactionsByAccount(String accountId) {
    return Stream<List<TransactionEntity>>.value(
      createdTransactions
          .where(
            (transaction) => transaction.accountId == accountId || transaction.toAccountId == accountId,
          )
          .toList(growable: false),
    );
  }
}