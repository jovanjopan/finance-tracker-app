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
    await _allocateToClassification('needs', amount * needsPercentage, transactionDate);
    await _allocateToClassification('wants', amount * wantsPercentage, transactionDate);
    await _allocateToClassification('savings', amount * savingsPercentage, transactionDate);
  }

  Future<void> allocateManually({
    required String classification,
    required double amount,
    required DateTime transactionDate,
  }) async {
    await _allocateToClassification(classification, amount, transactionDate);
  }

  Future<void> _allocateToClassification(
    String classification,
    double amount,
    DateTime date,
  ) async {
    final existing = await _budgetRepository.getClassificationBudgetForDate(
      classification,
      date,
    );

    if (existing != null) {
      final updated = BudgetEntity(
        id: existing.id,
        classification: classification,
        targetAmount: existing.targetAmount + amount,
        startDate: existing.startDate,
        endDate: existing.endDate,
      );
      BudgetValidator.validate(updated);
      await _budgetRepository.updateBudget(updated);
      return;
    }

    final period = _monthPeriodFor(date);
    final created = BudgetEntity(
      id: const Uuid().v4(),
      classification: classification,
      targetAmount: amount,
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