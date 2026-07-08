import 'package:uuid/uuid.dart';

import 'budget_entity.dart';
import 'budget_repository.dart';
import 'budget_validator.dart';

class AllocateIncomeUseCase {
  AllocateIncomeUseCase({required BudgetRepository budgetRepository})
      : _budgetRepository = budgetRepository;

  final BudgetRepository _budgetRepository;

  static const double needsPercentage = 0.5;
  static const double wantsPercentage = 0.3;
  static const double savingsPercentage = 0.2;

  Future<void> allocateAutomatically({
    required double amount,
    required DateTime transactionDate,
  }) async {
    await _applyDelta('needs', amount * needsPercentage, transactionDate);
    await _applyDelta('wants', amount * wantsPercentage, transactionDate);
    await _applyDelta('savings', amount * savingsPercentage, transactionDate);
  }

  Future<void> allocateManually({
    required String classification,
    required double amount,
    required DateTime transactionDate,
  }) async {
    await _applyDelta(classification, amount, transactionDate);
  }

  /// Membalik alokasi otomatis yang pernah diterapkan (dipanggil saat
  /// transaksi income dengan allocationType == 'auto' diedit/dihapus).
  Future<void> reverseAutomaticAllocation({
    required double amount,
    required DateTime transactionDate,
  }) async {
    await _applyDelta('needs', -(amount * needsPercentage), transactionDate);
    await _applyDelta('wants', -(amount * wantsPercentage), transactionDate);
    await _applyDelta('savings', -(amount * savingsPercentage), transactionDate);
  }

  /// Membalik alokasi manual yang pernah diterapkan (dipanggil saat
  /// transaksi income dengan allocationType == 'needs'/'wants'/'savings'
  /// diedit/dihapus).
  Future<void> reverseManualAllocation({
    required String classification,
    required double amount,
    required DateTime transactionDate,
  }) async {
    await _applyDelta(classification, -amount, transactionDate);
  }

  Future<void> _applyDelta(
    String classification,
    double delta,
    DateTime date,
  ) async {
    final existing = await _budgetRepository.getClassificationBudgetForDate(
      classification,
      date,
    );

    if (existing != null) {
      final newTarget = existing.targetAmount + delta;
      final updated = BudgetEntity(
        id: existing.id,
        classification: classification,
        // Dijaga tidak negatif untuk berjaga-jaga terhadap
        // inkonsistensi data (misal reversal ganda akibat bug lain).
        targetAmount: newTarget < 0 ? 0 : newTarget,
        startDate: existing.startDate,
        endDate: existing.endDate,
      );
      BudgetValidator.validate(updated);
      await _budgetRepository.updateBudget(updated);
      return;
    }

    if (delta <= 0) {
      // Tidak ada baris untuk dibalik dan delta bukan penambahan baru.
      return;
    }

    final period = _monthPeriodFor(date);
    final created = BudgetEntity(
      id: const Uuid().v4(),
      classification: classification,
      targetAmount: delta,
      startDate: period.start,
      endDate: period.end,
    );
    BudgetValidator.validate(created);
    await _budgetRepository.createBudget(created);
  }

  ({DateTime start, DateTime end}) _monthPeriodFor(DateTime date) {
    final start = DateTime(date.year, date.month, 1);
    final end = DateTime(date.year, date.month + 1, 0);
    return (start: start, end: end);
  }
}