class TransactionEntity {
  const TransactionEntity({
    required this.id,
    required this.type,
    required this.amount,
    required this.transactionDate,
    required this.accountId,
    this.toAccountId,
    this.categoryId,
    this.note,
  });

  final String id;
  final String type;
  final double amount;
  final DateTime transactionDate;
  final String accountId;
  final String? toAccountId;
  final String? categoryId;
  final String? note;
}