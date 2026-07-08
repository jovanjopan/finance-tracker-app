import 'transaction_entity.dart';

abstract class TransactionRepository {
  Stream<List<TransactionEntity>> watchAllTransactions();

  Stream<List<TransactionEntity>> watchTransactionsByAccount(String accountId);

  Future<TransactionEntity?> getTransactionById(String id);

  Future<void> createTransaction(TransactionEntity transaction);

  Future<void> updateTransaction(TransactionEntity transaction);

  Future<void> deleteTransaction(String id);
}