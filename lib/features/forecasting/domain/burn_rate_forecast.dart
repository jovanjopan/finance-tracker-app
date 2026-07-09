import '../../transactions/domain/transaction_entity.dart';

enum BurnRateStatus {
  /// Tidak ada pengeluaran belakangan ini, tidak ada burn rate untuk diproyeksikan.
  noRecentSpending,

  /// Burn rate ada, tapi proyeksi habisnya lebih dari 180 hari ke depan —
  /// terlalu jauh untuk ditampilkan sebagai tanggal presisi.
  safeLongTerm,

  /// Proyeksi tanggal habis jatuh SETELAH akhir bulan ini (aman untuk bulan ini).
  safeThisMonth,

  /// Proyeksi tanggal habis jatuh SEBELUM atau PAS akhir bulan ini (waspada).
  atRisk,
}

class BurnRateForecast {
  const BurnRateForecast({
    required this.dailyBurnRate,
    required this.daysPassed,
    required this.status,
    this.projectedDepletionDate,
  });

  final double dailyBurnRate;
  final int daysPassed;
  final BurnRateStatus status;

  /// Null jika status == noRecentSpending atau safeLongTerm (tidak relevan
  /// ditampilkan sebagai tanggal presisi untuk dua kasus itu).
  final DateTime? projectedDepletionDate;
}

const int _longTermHorizonDays = 180;
const int _rollingWindowDays = 7;

/// Menghitung burn rate dengan pendekatan kombinasi (blended):
/// - Jika sudah lewat >= 7 hari sejak awal bulan, pakai rata-rata
///   pengeluaran 7 hari kalender terakhir (termasuk hari ini) — lebih
///   responsif terhadap kebiasaan terkini, tidak terlalu terpengaruh
///   kejadian besar yang sudah lama berlalu.
/// - Jika belum sampai 7 hari (awal bulan), fallback ke rata-rata
///   pengeluaran dari tanggal 1 sampai hari ini, karena data 7 hari
///   terakhir belum cukup untuk dipakai sendiri.
///
/// Lalu memproyeksikan tanggal saldo diperkirakan habis berdasarkan
/// [currentBalance] dan burn rate tersebut, dibatasi maksimal 180 hari
/// ke depan (lebih dari itu dianggap "aman jangka panjang").
BurnRateForecast computeBurnRateForecast({
  required List<TransactionEntity> transactions,
  required double currentBalance,
  required DateTime referenceDate,
}) {
  final daysPassed = referenceDate.day;
  final dailyBurnRate = daysPassed >= _rollingWindowDays
      ? _rollingWindowBurnRate(transactions, referenceDate)
      : _monthToDateBurnRate(transactions, referenceDate, daysPassed);

  if (dailyBurnRate <= 0) {
    return BurnRateForecast(
      dailyBurnRate: dailyBurnRate,
      daysPassed: daysPassed,
      status: BurnRateStatus.noRecentSpending,
    );
  }

  final rawDaysUntilDepletion = currentBalance / dailyBurnRate;
  final daysUntilDepletion = rawDaysUntilDepletion < 0 ? 0 : rawDaysUntilDepletion.round();

  if (daysUntilDepletion > _longTermHorizonDays) {
    return BurnRateForecast(
      dailyBurnRate: dailyBurnRate,
      daysPassed: daysPassed,
      status: BurnRateStatus.safeLongTerm,
    );
  }

  final today = DateTime(referenceDate.year, referenceDate.month, referenceDate.day);
  final candidateDate = today.add(Duration(days: daysUntilDepletion));
  final endOfMonth = DateTime(referenceDate.year, referenceDate.month + 1, 0);

  final status = candidateDate.isAfter(endOfMonth) ? BurnRateStatus.safeThisMonth : BurnRateStatus.atRisk;

  return BurnRateForecast(
    dailyBurnRate: dailyBurnRate,
    daysPassed: daysPassed,
    status: status,
    projectedDepletionDate: candidateDate,
  );
}

double _rollingWindowBurnRate(List<TransactionEntity> transactions, DateTime referenceDate) {
  final today = DateTime(referenceDate.year, referenceDate.month, referenceDate.day);
  final windowStart = today.subtract(const Duration(days: _rollingWindowDays - 1));
  final windowEnd = DateTime(today.year, today.month, today.day, 23, 59, 59);

  final total = transactions
      .where((t) =>
          t.type == 'expense' &&
          !t.transactionDate.isBefore(windowStart) &&
          !t.transactionDate.isAfter(windowEnd))
      .fold<double>(0.0, (sum, t) => sum + t.amount);

  return total / _rollingWindowDays;
}

double _monthToDateBurnRate(List<TransactionEntity> transactions, DateTime referenceDate, int daysPassed) {
  final total = transactions
      .where((t) =>
          t.type == 'expense' &&
          t.transactionDate.year == referenceDate.year &&
          t.transactionDate.month == referenceDate.month &&
          !t.transactionDate.isAfter(referenceDate))
      .fold<double>(0.0, (sum, t) => sum + t.amount);

  return total / daysPassed;
}