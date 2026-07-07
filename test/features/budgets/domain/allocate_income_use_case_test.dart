import 'package:flutter_test/flutter_test.dart';
import 'package:myfinancetracker/features/budgets/domain/allocate_income_use_case.dart';
import 'package:myfinancetracker/features/budgets/domain/budget_entity.dart';
import 'package:myfinancetracker/features/budgets/domain/budget_repository.dart';

void main() {
  group('AllocateIncomeUseCase', () {
    test('automatic allocation splits amount into needs/wants/savings correctly', () async {
      final fakeRepository = _FakeBudgetRepository();
      final useCase = AllocateIncomeUseCase(budgetRepository: fakeRepository);

      await useCase.allocateAutomatically(
        amount: 200.0,
        transactionDate: DateTime(2026, 7, 5),
      );

      expect(fakeRepository.createdBudgets, hasLength(3));

      final needs = fakeRepository.createdBudgets.firstWhere((b) => b.classification == 'needs');
      final wants = fakeRepository.createdBudgets.firstWhere((b) => b.classification == 'wants');
      final savings = fakeRepository.createdBudgets.firstWhere((b) => b.classification == 'savings');

      expect(needs.targetAmount, 100.0);
      expect(wants.targetAmount, 60.0);
      expect(savings.targetAmount, 40.0);
    });

    test('incremental allocation across multiple installments sums correctly', () async {
      final fakeRepository = _FakeBudgetRepository();
      final useCase = AllocateIncomeUseCase(budgetRepository: fakeRepository);

      await useCase.allocateAutomatically(
        amount: 200.0,
        transactionDate: DateTime(2026, 7, 5),
      );
      await useCase.allocateAutomatically(
        amount: 400.0,
        transactionDate: DateTime(2026, 7, 20),
      );
      await useCase.allocateAutomatically(
        amount: 400.0,
        transactionDate: DateTime(2026, 7, 27),
      );

      final needsBudget = await fakeRepository.getClassificationBudgetForDate(
        'needs',
        DateTime(2026, 7, 27),
      );

      expect(needsBudget, isNotNull);
      expect(needsBudget!.targetAmount, 500.0);
    });

    test('manual allocation targets only the chosen classification', () async {
      final fakeRepository = _FakeBudgetRepository();
      final useCase = AllocateIncomeUseCase(budgetRepository: fakeRepository);

      await useCase.allocateManually(
        classification: 'savings',
        amount: 150.0,
        transactionDate: DateTime(2026, 7, 10),
      );

      expect(fakeRepository.createdBudgets, hasLength(1));
      expect(fakeRepository.createdBudgets.single.classification, 'savings');
      expect(fakeRepository.createdBudgets.single.targetAmount, 150.0);
    });
  });
}

class _FakeBudgetRepository implements BudgetRepository {
  final List<BudgetEntity> createdBudgets = <BudgetEntity>[];

  @override
  Future<void> createBudget(BudgetEntity budget) async {
    createdBudgets.add(budget);
  }

  @override
  Future<void> updateBudget(BudgetEntity budget) async {
    final index = createdBudgets.indexWhere((b) => b.id == budget.id);
    if (index != -1) {
      createdBudgets[index] = budget;
    }
  }

  @override
  Future<void> deleteBudget(String id) async {
    createdBudgets.removeWhere((b) => b.id == id);
  }

  @override
  Future<BudgetEntity?> getBudgetById(String id) async {
    try {
      return createdBudgets.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<List<BudgetEntity>> watchAllBudgets() {
    return Stream.value(createdBudgets);
  }

  @override
  Future<BudgetEntity?> getClassificationBudgetForDate(
    String classification,
    DateTime date,
  ) async {
    for (final budget in createdBudgets) {
      if (budget.classification == classification &&
          !date.isBefore(budget.startDate) &&
          !date.isAfter(budget.endDate)) {
        return budget;
      }
    }
    return null;
  }
}