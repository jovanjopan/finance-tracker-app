import '../../../core/utils/date_formatter.dart';
import 'transaction_entity.dart';

class TransactionDateGroup {
  const TransactionDateGroup({
    required this.label,
    required this.date,
    required this.transactions,
  });

  final String label;
  final DateTime date;
  final List<TransactionEntity> transactions;
}

/// Mengelompokkan transaksi per tanggal (hari), diurutkan dari yang
/// terbaru. Label "hari ini"/"kemarin" dipakai relatif terhadap
/// [referenceDate], selain itu pakai format tanggal biasa.
List<TransactionDateGroup> groupTransactionsByDate(
  List<TransactionEntity> transactions, {
  required DateTime referenceDate,
}) {
  final today = DateTime(referenceDate.year, referenceDate.month, referenceDate.day);
  final yesterday = today.subtract(const Duration(days: 1));

  final Map<DateTime, List<TransactionEntity>> buckets = {};
  for (final transaction in transactions) {
    final day = DateTime(
      transaction.transactionDate.year,
      transaction.transactionDate.month,
      transaction.transactionDate.day,
    );
    buckets.putIfAbsent(day, () => []).add(transaction);
  }

  final sortedDays = buckets.keys.toList()..sort((a, b) => b.compareTo(a));

  return sortedDays.map((day) {
    final String label;
    if (day == today) {
      label = 'hari ini · ${DateFormatter.format(day)}';
    } else if (day == yesterday) {
      label = 'kemarin · ${DateFormatter.format(day)}';
    } else {
      label = DateFormatter.format(day);
    }
    return TransactionDateGroup(label: label, date: day, transactions: buckets[day]!);
  }).toList();
}