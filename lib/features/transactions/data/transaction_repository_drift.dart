import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/transaction_entity.dart';
import '../domain/transaction_repository.dart';

class TransactionRepositoryDrift implements TransactionRepository {
  TransactionRepositoryDrift(this._database);

  final AppDatabase _database;

  @override
  Stream<List<TransactionEntity>> watchAllTransactions() {
    return (_database.select(_database.transactions)
          ..orderBy([
            (table) => OrderingTerm(
                  expression: table.transactionDate,
                  mode: OrderingMode.desc,
                ),
          ]))
        .watch()
        .map((rows) => rows.map(_toEntity).toList(growable: false));
  }

  @override
  Stream<List<TransactionEntity>> watchTransactionsByAccount(String accountId) {
    return (_database.select(_database.transactions)
          ..where(
            (table) =>
                table.accountId.equals(accountId) |
                table.toAccountId.equals(accountId),
          ))
        .watch()
        .map((rows) => rows.map(_toEntity).toList(growable: false));
  }

  @override
  Future<TransactionEntity?> getTransactionById(String id) async {
    final row = await (_database.select(_database.transactions)
          ..where((table) => table.id.equals(id)))
        .getSingleOrNull();

    return row == null ? null : _toEntity(row);
  }

  @override
  Future<void> createTransaction(TransactionEntity transaction) {
    return _database.into(_database.transactions).insert(
          _toCompanion(transaction),
        );
  }

  @override
  Future<void> updateTransaction(TransactionEntity transaction) {
    return (_database.update(_database.transactions)
          ..where((table) => table.id.equals(transaction.id)))
        .write(_toCompanion(transaction));
  }

  @override
  Future<void> deleteTransaction(String id) {
    return (_database.delete(_database.transactions)
          ..where((table) => table.id.equals(id)))
        .go();
  }

  TransactionEntity _toEntity(Transaction row) {
    return TransactionEntity(
      id: row.id,
      type: row.type,
      amount: row.amount,
      transactionDate: row.transactionDate,
      accountId: row.accountId,
      toAccountId: row.toAccountId,
      categoryId: row.categoryId,
      note: row.note,
      allocationType: row.allocationType,
    );
  }

  TransactionsCompanion _toCompanion(TransactionEntity transaction) {
    return TransactionsCompanion.insert(
      id: transaction.id,
      type: transaction.type,
      amount: transaction.amount,
      transactionDate: transaction.transactionDate,
      accountId: transaction.accountId,
      toAccountId: transaction.toAccountId == null
          ? const Value.absent()
          : Value<String?>(transaction.toAccountId),
      categoryId: transaction.categoryId == null
          ? const Value.absent()
          : Value<String?>(transaction.categoryId),
      note: transaction.note == null
          ? const Value.absent()
          : Value<String?>(transaction.note),
      allocationType: transaction.allocationType == null
          ? const Value.absent()
          : Value<String?>(transaction.allocationType),
    );
  }
}