import 'account_entity.dart';
import 'account_repository.dart';

class AccountValidationException implements Exception {
  const AccountValidationException(this.message);

  final String message;

  @override
  String toString() => 'AccountValidationException: $message';
}

class UpdateAccountUseCase {
  UpdateAccountUseCase({required AccountRepository accountRepository})
      : _accountRepository = accountRepository;

  final AccountRepository _accountRepository;

  Future<void> execute(AccountEntity account) async {
    if (account.name.trim().isEmpty) {
      throw const AccountValidationException('nama akun wajib diisi');
    }
    if (account.initialBalance < 0) {
      throw const AccountValidationException('saldo awal tidak boleh negatif');
    }
    await _accountRepository.updateAccount(account);
  }
}