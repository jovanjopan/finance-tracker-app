import '../../transactions/domain/transaction_entity.dart';

class BurnRateForecast {
  const BurnRateForecast({
    required this.dailyBurnRate,
    required this.daysPassed,
    required this.daysRemainingInMonth,
    required this.projectedRemainingSpend,
    required this.projectedEndOfMonthBalance,
  });

  final double dailyBurnRate;
  final int daysPassed;
  final int daysRemainingInMonth;
  final double projectedRemainingSpend;
  final double projectedEndOfMonthBalance;

  bool get willSurvive => projectedEndOfMonthBalance >= 0;
}

/// Menghitung burn rate (kecepatan pengeluaran harian) berdasarkan total
/// expense bulan berjalan dari tanggal 1 sampai [referenceDate], lalu
/// memproyeksikan apakah [currentBalance] akan cukup sampai akhir bulan
/// dengan asumsi kecepatan pengeluaran tetap sama.
BurnRateForecast computeBurnRateForecast({
  required List<TransactionEntity> transactions,
  required double currentBalance,
  required DateTime referenceDate,
}) {
  final totalSpentThisMonth = transactions
      .where((transaction) =>
          transaction.type == 'expense' &&
          transaction.transactionDate.year == referenceDate.year &&
          transaction.transactionDate.month == referenceDate.month)
      .fold<double>(0.0, (sum, transaction) => sum + transaction.amount);

  // Minimal 1 hari untuk menghindari pembagian oleh nol di tanggal 1.
  final daysPassed = referenceDate.day < 1 ? 1 : referenceDate.day;
  final dailyBurnRate = totalSpentThisMonth / daysPassed;

  final daysInMonth = DateTime(referenceDate.year, referenceDate.month + 1, 0).day;
  final daysRemainingInMonth = (daysInMonth - daysPassed).clamp(0, daysInMonth);

  final projectedRemainingSpend = dailyBurnRate * daysRemainingInMonth;
  final projectedEndOfMonthBalance = currentBalance - projectedRemainingSpend;

  return BurnRateForecast(
    dailyBurnRate: dailyBurnRate,
    daysPassed: daysPassed,
    daysRemainingInMonth: daysRemainingInMonth,
    projectedRemainingSpend: projectedRemainingSpend,
    projectedEndOfMonthBalance: projectedEndOfMonthBalance,
  );
}