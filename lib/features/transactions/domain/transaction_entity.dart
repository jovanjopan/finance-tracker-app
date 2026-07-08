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
    this.allocationType,
  });

  final String id;
  final String type;
  final double amount;
  final DateTime transactionDate;
  final String accountId;
  final String? toAccountId;
  final String? categoryId;
  final String? note;

  /// null, 'auto', 'needs', 'wants', atau 'savings'. Hanya relevan untuk
  /// transaksi type == 'income' yang dialokasikan ke Budget 50/30/20.
  /// Disimpan supaya alokasi bisa dibalik dengan tepat saat transaksi
  /// ini diedit atau dihapus.
  final String? allocationType;
}