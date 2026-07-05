import 'account_entity.dart';

abstract class AccountRepository {
  Stream<List<AccountEntity>> watchAllAccounts();

  Future<AccountEntity?> getAccountById(String id);

  Future<void> createAccount(AccountEntity account);

  Future<void> updateAccount(AccountEntity account);

  Future<void> deleteAccount(String id);

  Stream<double> watchCurrentBalance(String accountId);
}