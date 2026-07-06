import 'package:uuid/uuid.dart';

import '../../accounts/domain/account_repository.dart';
import '../../accounts/domain/account_entity.dart';
import 'transaction_entity.dart';
import 'transaction_repository.dart';
import 'transaction_validator.dart';

class AccountNotFoundException implements Exception {
  const AccountNotFoundException(this.accountId);

  final String accountId;

  @override
  String toString() => 'AccountNotFoundException: $accountId';
}

class InactiveAccountException implements Exception {
  const InactiveAccountException(this.accountId);

  final String accountId;

  @override
  String toString() => 'InactiveAccountException: $accountId';
}

class TransferMoneyUseCase {
  static const Uuid _uuid = Uuid();

  TransferMoneyUseCase({
    required AccountRepository accountRepository,
    required TransactionRepository transactionRepository,
  })  : _accountRepository = accountRepository,
        _transactionRepository = transactionRepository;

  final AccountRepository _accountRepository;
  final TransactionRepository _transactionRepository;

  Future<void> execute({
    required String sourceAccountId,
    required String destinationAccountId,
    required double amount,
    required DateTime transactionDate,
  }) async {
    final sourceAccount = await _accountRepository.getAccountById(sourceAccountId);
    if (sourceAccount == null) {
      throw AccountNotFoundException(sourceAccountId);
    }

    final destinationAccount = await _accountRepository.getAccountById(destinationAccountId);
    if (destinationAccount == null) {
      throw AccountNotFoundException(destinationAccountId);
    }

    _validateActiveAccount(sourceAccount);
    _validateActiveAccount(destinationAccount);

    final transaction = TransactionEntity(
      id: _uuid.v4(),
      type: 'transfer',
      amount: amount,
      transactionDate: transactionDate,
      accountId: sourceAccountId,
      toAccountId: destinationAccountId,
      categoryId: null,
    );

    TransactionValidator.validate(transaction);

    await _transactionRepository.createTransaction(transaction);
  }

  void _validateActiveAccount(AccountEntity account) {
    if (!account.isActive) {
      throw InactiveAccountException(account.id);
    }
  }
}