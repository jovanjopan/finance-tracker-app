import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/account_entity.dart';
import '../domain/account_repository.dart';

class AccountRepositoryDrift implements AccountRepository {
  AccountRepositoryDrift(this._database);

  final AppDatabase _database;

  @override
  Stream<List<AccountEntity>> watchAllAccounts() {
    return _database.select(_database.accounts).watch().map(
          (rows) => rows.map(_toEntity).toList(growable: false),
        );
  }

  @override
  Future<AccountEntity?> getAccountById(String id) async {
    final row = await (_database.select(_database.accounts)
          ..where((table) => table.id.equals(id)))
        .getSingleOrNull();

    if (row == null) {
      return null;
    }

    return _toEntity(row);
  }

  @override
  Future<void> createAccount(AccountEntity account) {
    return _database.into(_database.accounts).insert(_toCompanion(account));
  }

  @override
  Future<void> updateAccount(AccountEntity account) {
    return (_database.update(_database.accounts)
          ..where((table) => table.id.equals(account.id)))
        .write(_toCompanion(account));
  }

  @override
  Future<void> deleteAccount(String id) {
    return (_database.delete(_database.accounts)..where((table) => table.id.equals(id))).go();
  }

  @override
  Stream<double> watchCurrentBalance(String accountId) {
    final query = _database.customSelect(
      '''
      SELECT
        COALESCE(a.initial_balance, 0)
        + COALESCE(
            (SELECT SUM(t.amount)
             FROM "TRANSACTION" t
             WHERE t.type = ? AND t.account_id = ?),
            0
          )
        + COALESCE(
            (SELECT SUM(t.amount)
             FROM "TRANSACTION" t
             WHERE t.type = ? AND t.to_account_id = ?),
            0
          )
        - COALESCE(
            (SELECT SUM(t.amount)
             FROM "TRANSACTION" t
             WHERE t.type = ? AND t.account_id = ?),
            0
          )
        - COALESCE(
            (SELECT SUM(t.amount)
             FROM "TRANSACTION" t
             WHERE t.type = ? AND t.account_id = ?),
            0
          ) AS balance
      FROM "ACCOUNT" a
      WHERE a.id = ?
      ''',
      variables: [
        const Variable<String>('income'),
        Variable<String>(accountId),
        const Variable<String>('transfer'),
        Variable<String>(accountId),
        const Variable<String>('expense'),
        Variable<String>(accountId),
        const Variable<String>('transfer'),
        Variable<String>(accountId),
        Variable<String>(accountId),
      ],
      readsFrom: {
        _database.accounts,
        _database.transactions,
      },
    );

    return query.watch().map(
          (rows) => rows.isEmpty ? 0.0 : rows.first.read<double>('balance'),
        );
  }

  AccountEntity _toEntity(Account row) {
    return AccountEntity(
      id: row.id,
      name: row.name,
      type: row.type,
      initialBalance: row.initialBalance,
      isActive: row.isActive,
    );
  }

  AccountsCompanion _toCompanion(AccountEntity account) {
    return AccountsCompanion(
      id: Value(account.id),
      name: Value(account.name),
      type: Value(account.type),
      initialBalance: Value(account.initialBalance),
      isActive: Value(account.isActive),
    );
  }
}